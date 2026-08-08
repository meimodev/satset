/// The petty cash box (§Kas kecil) — every write to `cash_entries` goes through
/// here, for the reason `writeAudit` exists: a rule enforced in one route reaches
/// three call sites out of four.
///
/// Two invariants live in this file and nowhere else:
///
/// - **The balance is derived.** `SUM(delta)`, every time. Nothing stores it.
/// - **The box cannot go negative** (ADR-0088), with the two exemptions the ADR
///   names — a reversal and a count may both land below zero, because refusing
///   them would make an error permanently uncorrectable.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/cash_entry.dart';
import 'package:satset/server/audit_log.dart';
// Hidden: Drift generates its own `CashEntry` for the row, and the two are
// different things — one is the table, one is what a reader sees. Nothing here
// names the row type, so hiding it is cheaper than prefixing every use of the
// domain model. Same collision `audit_log.dart` resolves the other way round.
import 'package:satset/server/db/database.dart' hide CashEntry;
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

/// Thrown for a refusal a person needs to act on. The [code] crosses the wire
/// and the words are composed client-side (ADR-0085).
class CashException implements Exception {
  final String code;

  /// Present on `insufficient_cash` so the till can say *how much* is there
  /// rather than making the supervisor go and look.
  final int? balance;

  const CashException(this.code, {this.balance});

  @override
  String toString() => 'CashException($code)';
}

/// What is in the box right now. Optionally as of [before], which is what the
/// Kas report section's opening balance is.
Future<int> cashBalance(AppDatabase db, {DateTime? before}) async {
  final sum = db.cashEntries.delta.sum();
  final q = db.selectOnly(db.cashEntries)..addColumns([sum]);
  if (before != null) q.where(db.cashEntries.at.isSmallerThanValue(before));
  final row = await q.getSingleOrNull();
  return row?.read(sum) ?? 0;
}

/// Ledger rows, newest first, paged by growing limit (ADR-0079).
///
/// Never selects `photo`: the blob is reached only by its own route, so a ledger
/// page stays a few KB no matter how many receipts were shot.
Future<List<CashEntry>> cashLedger(AppDatabase db, {int limit = 50}) async {
  final t = db.cashEntries;
  final q = db.selectOnly(t)
    ..addColumns([
      t.id,
      t.kind,
      t.delta,
      t.category,
      t.note,
      t.reversesId,
      t.reversedById,
      t.countedAmount,
      t.photo.isNotNull(),
      t.actorUserId,
      t.actorName,
      t.at,
    ])
    ..orderBy([OrderingTerm.desc(t.at), OrderingTerm.desc(t.id)])
    ..limit(limit);
  final rows = await q.get();
  return [
    for (final r in rows)
      CashEntry(
        id: r.read(t.id)!,
        kind: cashEntryKindFromName(r.read(t.kind)) ?? CashEntryKind.expense,
        delta: r.read(t.delta)!,
        category: cashCategoryFromName(r.read(t.category)),
        note: r.read(t.note),
        reversesId: r.read(t.reversesId),
        reversedById: r.read(t.reversedById),
        countedAmount: r.read(t.countedAmount),
        hasPhoto: r.read(t.photo.isNotNull()) ?? false,
        actorUserId: r.read(t.actorUserId),
        actorName: r.read(t.actorName),
        at: r.read(t.at)!,
      ),
  ];
}

/// Money into the box. `editSettings` — the owner funds it.
Future<CashEntry> topUpCash(
  AppDatabase db, {
  required int amount,
  String? note,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  if (amount <= 0) throw const CashException('invalid_amount');
  return _post(
    db,
    kind: CashEntryKind.topUp,
    delta: amount,
    note: note,
    actorUserId: actorUserId,
    hub: hub,
    at: at,
    idPrefix: idPrefix,
    auditKind: AuditKind.cashToppedUp,
    auditParams: {'amount': auditRupiah(amount)},
    amountCents: amount,
  );
}

/// Money out of the box. `manageCash` — a supervisor spends from it.
///
/// This is the one path the negative check applies to, and it is where ADR-0088
/// is actually enforced.
Future<CashEntry> spendCash(
  AppDatabase db, {
  required int amount,
  required CashCategory category,
  String? note,
  Uint8List? photo,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  if (amount <= 0) throw const CashException('invalid_amount');
  final balance = await cashBalance(db);
  if (amount > balance) {
    // Physical notes cannot be fewer than zero, so a would-be negative is always
    // a row nobody wrote down — usually a top-up handed over in person. Refusing
    // is what produces that conversation (ADR-0088).
    throw CashException('insufficient_cash', balance: balance);
  }
  return _post(
    db,
    kind: CashEntryKind.expense,
    delta: -amount,
    category: category,
    note: note,
    photo: photo,
    actorUserId: actorUserId,
    hub: hub,
    at: at,
    idPrefix: idPrefix,
    auditKind: AuditKind.cashSpent,
    auditParams: {'amount': auditRupiah(amount), 'category': category.name},
    amountCents: amount,
  );
}

/// Opname kas: the counter reports the **absolute** cash found and the server
/// writes the difference, exactly as `recordCount` does for stock. The delta on
/// the row *is* the variance.
///
/// A count matching the ledger writes a **zero-delta row** rather than nothing:
/// "someone checked and it was right" is the most reassuring fact the box can
/// carry, and dropping it would make a verified box look unvisited.
Future<CashEntry> countCash(
  AppDatabase db, {
  required int counted,
  String? note,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  if (counted < 0) throw const CashException('invalid_amount');
  final balance = await cashBalance(db);
  final variance = counted - balance;
  return _post(
    db,
    kind: CashEntryKind.count,
    delta: variance,
    countedAmount: counted,
    note: note,
    actorUserId: actorUserId,
    hub: hub,
    at: at,
    idPrefix: idPrefix,
    auditKind: AuditKind.cashCounted,
    auditParams: {
      'counted': auditRupiah(counted),
      // Signed on purpose: "-Rp. 20.000" is the finding, and a magnitude would
      // hide which way the box was wrong.
      'variance': '${variance > 0 ? '+' : ''}${auditRupiah(variance)}',
    },
    amountCents: variance.abs(),
  );
}

/// Undo one earlier row with a counter-entry. At most one per row, no time
/// limit, mandatory note (§Kas kecil).
///
/// Exempt from the negative check: reversing a top-up whose money has since been
/// spent must stay possible, or an erroneous top-up is permanent (ADR-0088).
Future<CashEntry> reverseCash(
  AppDatabase db, {
  required String entryId,
  required String note,
  String? actorUserId,
  WsHub? hub,
}) async {
  if (note.trim().isEmpty) throw const CashException('note_required');
  final target = await (db.select(
    db.cashEntries,
  )..where((c) => c.id.equals(entryId))).getSingleOrNull();
  if (target == null) throw const CashException('not_found');
  if (target.reversedById != null) {
    throw const CashException('already_reversed');
  }
  if (target.kind == CashEntryKind.reversal.name) {
    // A reversal of a reversal is a chain nobody can read back.
    throw const CashException('not_reversible');
  }
  final entry = await _post(
    db,
    kind: CashEntryKind.reversal,
    delta: -target.delta,
    note: note.trim(),
    reversesId: target.id,
    actorUserId: actorUserId,
    hub: hub,
    auditKind: AuditKind.cashReversed,
    auditParams: {'amount': auditRupiah(target.delta.abs())},
    amountCents: target.delta.abs(),
  );
  // The one field a row ever gains after the fact — a link, not an edit. What
  // happened is untouched.
  await (db.update(db.cashEntries)..where((c) => c.id.equals(target.id))).write(
    CashEntriesCompanion(reversedById: Value(entry.id)),
  );
  return entry;
}

Future<CashEntry> _post(
  AppDatabase db, {
  required CashEntryKind kind,
  required int delta,
  required AuditKind auditKind,
  required Map<String, String> auditParams,
  required int amountCents,
  CashCategory? category,
  String? note,
  String? reversesId,
  int? countedAmount,
  Uint8List? photo,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  final id = '${idPrefix ?? ''}${_uuid.v4()}';
  final actor = await resolveActor(db, actorUserId);
  final when = at ?? SatClock.now();
  await db.into(db.cashEntries).insert(
    CashEntriesCompanion.insert(
      id: id,
      kind: kind.name,
      delta: delta,
      at: when,
      category: Value(category?.name),
      note: Value(note),
      reversesId: Value(reversesId),
      countedAmount: Value(countedAmount),
      photo: Value(photo),
      actorUserId: Value(actorUserId),
      actorName: Value(actor?.name),
    ),
  );
  await writeAudit(
    db,
    type: AuditType.cashMovement,
    kind: auditKind,
    params: auditParams,
    actorUserId: actorUserId,
    reason: note,
    amountCents: amountCents,
    hub: hub,
    at: at,
    idPrefix: idPrefix,
  );
  return CashEntry(
    id: id,
    kind: kind,
    delta: delta,
    at: when,
    category: category,
    note: note,
    reversesId: reversesId,
    countedAmount: countedAmount,
    hasPhoto: photo != null,
    actorUserId: actorUserId,
    actorName: actor?.name,
  );
}

/// Wire shape for one ledger row. The photo is a flag, never bytes.
Map<String, dynamic> cashEntryJson(CashEntry e) => {
  'id': e.id,
  'kind': e.kind.name,
  'delta': e.delta,
  'category': e.category?.name,
  'note': e.note,
  'reversesId': e.reversesId,
  'reversedById': e.reversedById,
  'countedAmount': e.countedAmount,
  'hasPhoto': e.hasPhoto,
  'actorUserId': e.actorUserId,
  'actorName': e.actorName,
  'at': e.at.toIso8601String(),
};

/// The Kas report section (ADR-0089) — isolated from every sales figure by
/// construction, because it reads `cash_entries` and nothing else.
///
/// [from] is expected to already carry the `businessDayStartHour` rollover the
/// caller applies to its sales buckets, so a 02:00 expense lands with the night
/// it belongs to.
Future<Map<String, dynamic>> cashReportSection(
  AppDatabase db, {
  required DateTime from,
  required DateTime to,
}) async {
  final opening = await cashBalance(db, before: from);
  final t = db.cashEntries;
  final rows =
      await (db.selectOnly(t)
            ..addColumns([t.kind, t.delta, t.category])
            ..where(
              t.at.isBiggerOrEqualValue(from) & t.at.isSmallerThanValue(to),
            ))
          .get();
  var inflow = 0;
  var outflow = 0;
  var variance = 0;
  final byCategory = <String, int>{};
  for (final r in rows) {
    final delta = r.read(t.delta) ?? 0;
    final kind = cashEntryKindFromName(r.read(t.kind));
    if (kind == CashEntryKind.count) {
      // A count's delta is a *finding*, not money moving. Folding it into
      // inflow/outflow would report a cash shortfall as a purchase.
      variance += delta;
      continue;
    }
    if (delta >= 0) {
      inflow += delta;
    } else {
      outflow += -delta;
      final cat = r.read(t.category);
      if (cat != null) byCategory[cat] = (byCategory[cat] ?? 0) + -delta;
    }
  }
  return {
    'opening': opening,
    // Spelled out, not `in`/`out`: `in` is a Dart keyword, so a DTO field could
    // never carry that name without a rename annotation on the wire side.
    'inflow': inflow,
    'outflow': outflow,
    'variance': variance,
    'closing': opening + inflow - outflow + variance,
    'byCategory': byCategory,
    'count': rows.length,
  };
}
