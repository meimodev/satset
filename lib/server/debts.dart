/// The [[Piutang]] ledger (ADR-0098) — every write to `member_debts` goes
/// through here, fifth of the family `writeAudit`, `cash.dart`, `members.dart`
/// and `stock_counts.dart` belong to, and for the same reason: a rule enforced
/// in one route reaches three call sites out of four.
///
/// Four invariants live in this file and nowhere else:
///
/// - **The balance is derived.** `SUM(delta)`, every time. Nothing stores it.
/// - **It cannot go negative.** You cannot collect more than is owed; a
///   would-be credit balance is a deposit, which is a different product. A
///   `writeOff`, `reversal` and `adjust` are exempt, for the reason ADR-0088
///   exempts a cash reversal — refusing them makes an error permanent.
/// - **A charge cannot exceed the member's credit limit.** Per member, falling
///   back to the venue default, both shipping at 0 — "no tab" until an owner
///   deliberately trusts a named person.
/// - **Nothing is ever edited.** A reopened receipt writes a `reversal`, a bad
///   debt a `writeOff`, a typo an `adjust`. The ledger corrects forwards.
///
/// A charge is written **with the payment that discharged the receipt**, not at
/// bill close: a bill can go part-cash part-tab, so the tab is one payment
/// among several rather than a property of the close.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/server/audit_log.dart';
// Hidden for the reason `cash.dart` hides `CashEntry`: Drift generates its own
// `MemberDebt` for the row, and the row and what a reader sees are different
// things. Prefixed a second time so the row type stays nameable, exactly as
// `members.dart` does with `Member`.
import 'package:satset/server/db/database.dart' hide MemberDebt;
import 'package:satset/server/db/database.dart' as rows show MemberDebt;
// Cyclic with this file, and deliberately: the delete guard lives over there
// and the balance lives here. Dart resolves it; splitting a third file to
// avoid it would put the two halves of one rule in three places.
import 'package:satset/server/members.dart' show getMember, memberJson;
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

/// Methods a collection may arrive by. `piutang` is deliberately absent —
/// paying a tab with the tab is circular.
const debtPaymentMethods = {'tunai', 'kartu', 'qris', 'transfer', 'lainnya'};

/// Thrown for a refusal a person needs to act on. The [code] crosses the wire
/// and the words are composed client-side (ADR-0085).
class DebtException implements Exception {
  final String code;

  /// Present on `debt_limit_exceeded` and `overpayment` so the till can say
  /// *how much* rather than making the cashier go and look — the same courtesy
  /// `CashException.balance` exists for.
  final int? balance;
  final int? limit;

  const DebtException(this.code, {this.balance, this.limit});

  @override
  String toString() => 'DebtException($code)';
}

/// The [[Piutang]] half of `venue_settings`, read once per request.
class DebtConfig {
  final bool enabled;
  final int venueLimit;
  final int overdueDays;

  const DebtConfig({
    this.enabled = false,
    this.venueLimit = 0,
    this.overdueDays = 30,
  });
}

Future<DebtConfig> debtConfig(AppDatabase db) async {
  final s = await (db.select(
    db.venueSettings,
  )..where((t) => t.id.equals('default'))).getSingleOrNull();
  if (s == null) return const DebtConfig();
  return DebtConfig(
    // Nested under the membership master switch: a venue that never opted into
    // a guest directory cannot have tabs against guests it does not keep.
    enabled: s.membersEnabled && s.memberDebtEnabled,
    venueLimit: s.memberDebtLimit,
    overdueDays: s.memberDebtOverdueDays,
  );
}

/// What this member owes right now. Optionally as of [before], which is what
/// the Piutang report section's opening balance is.
Future<int> memberDebt(
  AppDatabase db,
  String memberId, {
  DateTime? before,
}) async {
  final sum = db.memberDebts.delta.sum();
  final q = db.selectOnly(db.memberDebts)
    ..addColumns([sum])
    ..where(db.memberDebts.memberId.equals(memberId));
  if (before != null) q.where(db.memberDebts.at.isSmallerThanValue(before));
  final row = await q.getSingleOrNull();
  return row?.read(sum) ?? 0;
}

/// Venue-wide outstanding. The report's opening and closing figures.
Future<int> totalDebt(AppDatabase db, {DateTime? before}) async {
  final sum = db.memberDebts.delta.sum();
  final q = db.selectOnly(db.memberDebts)..addColumns([sum]);
  if (before != null) q.where(db.memberDebts.at.isSmallerThanValue(before));
  final row = await q.getSingleOrNull();
  return row?.read(sum) ?? 0;
}

/// This member's limit: their own if they have one, otherwise the venue
/// default. **Null on the member means "inherit", never "unlimited"** — there
/// is no way to express an unbounded tab, on purpose.
int creditLimitFor(int? ownLimit, DebtConfig cfg) => ownLimit ?? cfg.venueLimit;

/// Everything the till and the directory need about one member's standing.
Future<MemberDebt> debtFor(
  AppDatabase db,
  String memberId, {
  DebtConfig? config,
  int ledgerLimit = 50,
}) async {
  final cfg = config ?? await debtConfig(db);
  final m = await (db.select(
    db.members,
  )..where((x) => x.id.equals(memberId))).getSingleOrNull();
  return MemberDebt(
    balance: await memberDebt(db, memberId),
    limit: creditLimitFor(m?.debtLimit, cfg),
    ownLimit: m?.debtLimit,
    entries: await debtLedger(db, memberId, limit: ledgerLimit),
  );
}

/// Ledger rows, newest first, paged by growing limit (ADR-0079).
///
/// Never selects `photo`: the blob is reached only by its own route, so a page
/// stays a few KB no matter how many transfer slips were shot.
Future<List<MemberDebtEntry>> debtLedger(
  AppDatabase db,
  String memberId, {
  int limit = 50,
}) async {
  final t = db.memberDebts;
  final q = db.selectOnly(t)
    ..addColumns([
      t.id,
      t.memberId,
      t.kind,
      t.delta,
      t.paymentId,
      t.billLabel,
      t.method,
      t.note,
      t.photo.isNotNull(),
      t.actorName,
      t.at,
    ])
    ..where(t.memberId.equals(memberId))
    ..orderBy([OrderingTerm.desc(t.at), OrderingTerm.desc(t.id)])
    ..limit(limit);
  return [
    for (final r in await q.get())
      MemberDebtEntry(
        id: r.read(t.id)!,
        memberId: r.read(t.memberId)!,
        kind: memberDebtKindFromName(r.read(t.kind)) ?? MemberDebtKind.adjust,
        delta: r.read(t.delta)!,
        paymentId: r.read(t.paymentId),
        billLabel: r.read(t.billLabel) ?? '',
        method: r.read(t.method),
        note: r.read(t.note),
        hasPhoto: r.read(t.photo.isNotNull()) ?? false,
        actorName: r.read(t.actorName),
        at: r.read(t.at)!,
      ),
  ];
}

/// Put an amount on a member's tab. Called from the settlement route in the
/// same transaction as the `piutang` payment that discharged the receipt.
///
/// This is where the credit limit is actually enforced.
Future<void> chargeDebt(
  AppDatabase db, {
  required String memberId,
  required int amount,
  required String paymentId,
  String? visitId,
  String billLabel = '',
  DebtConfig? config,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  if (amount <= 0) throw const DebtException('invalid_amount');
  final cfg = config ?? await debtConfig(db);
  if (!cfg.enabled) throw const DebtException('debt_disabled');
  final m = await (db.select(
    db.members,
  )..where((x) => x.id.equals(memberId))).getSingleOrNull();
  if (m == null) throw const DebtException('not_found');
  final limit = creditLimitFor(m.debtLimit, cfg);
  final balance = await memberDebt(db, memberId);
  if (balance + amount > limit) {
    // Carries both numbers so the till can say "Rp 120.000 of Rp 500.000 used"
    // instead of a bare refusal the cashier has to go and interpret.
    throw DebtException('debt_limit_exceeded', balance: balance, limit: limit);
  }
  await _post(
    db,
    memberId: memberId,
    kind: MemberDebtKind.charge,
    delta: amount,
    paymentId: paymentId,
    visitId: visitId,
    billLabel: billLabel,
    actorUserId: actorUserId,
    hub: hub,
    at: at,
    idPrefix: idPrefix,
    auditKind: AuditKind.debtCharged,
    auditParams: {
      'member': m.name,
      'amount': auditRupiah(amount),
      'bill': billLabel,
    },
    amountCents: amount,
  );
}

/// A collection at the till. `settleBill` — the cashier takes the money.
///
/// This is the one path the non-negative check applies to, and it is where the
/// second invariant is actually enforced.
Future<void> payDebt(
  AppDatabase db, {
  required String memberId,
  required int amount,
  required String method,
  Uint8List? photo,
  String? note,
  DebtConfig? config,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  if (amount <= 0) throw const DebtException('invalid_amount');
  if (!debtPaymentMethods.contains(method)) {
    throw const DebtException('bad_method');
  }
  // Same rule ADR-0025 puts on a non-cash bill payment, and for the same
  // reason: cash is witnessed over the counter, a transfer is not.
  if (method != 'tunai' && (photo == null || photo.isEmpty)) {
    throw const DebtException('photo_required');
  }
  final cfg = config ?? await debtConfig(db);
  if (!cfg.enabled) throw const DebtException('debt_disabled');
  final m = await (db.select(
    db.members,
  )..where((x) => x.id.equals(memberId))).getSingleOrNull();
  if (m == null) throw const DebtException('not_found');
  final balance = await memberDebt(db, memberId);
  if (amount > balance) {
    // A payment beyond the balance is always a typo or a mis-selected member —
    // the guest cannot owe less than nothing. Refusing is what surfaces which.
    throw DebtException('overpayment', balance: balance);
  }
  await _post(
    db,
    memberId: memberId,
    kind: MemberDebtKind.payment,
    delta: -amount,
    method: method,
    photo: photo,
    note: note,
    actorUserId: actorUserId,
    hub: hub,
    at: at,
    idPrefix: idPrefix,
    auditKind: AuditKind.debtPaid,
    auditParams: {
      'member': m.name,
      'amount': auditRupiah(amount),
      'method': method,
    },
    amountCents: amount,
  );
}

/// Give up collecting. `refund` — the capability that already means *a manager
/// is accepting that money is gone*.
///
/// Exempt from the non-negative check for the reason ADR-0088 exempts a cash
/// reversal: a write-off that cannot be recorded is a loss that stays on the
/// books forever.
Future<void> writeOffDebt(
  AppDatabase db, {
  required String memberId,
  required int amount,
  required String note,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  if (amount <= 0) throw const DebtException('invalid_amount');
  if (note.trim().isEmpty) throw const DebtException('note_required');
  final m = await (db.select(
    db.members,
  )..where((x) => x.id.equals(memberId))).getSingleOrNull();
  if (m == null) throw const DebtException('not_found');
  await _post(
    db,
    memberId: memberId,
    kind: MemberDebtKind.writeOff,
    delta: -amount,
    note: note.trim(),
    actorUserId: actorUserId,
    hub: hub,
    at: at,
    idPrefix: idPrefix,
    auditKind: AuditKind.debtWrittenOff,
    auditParams: {'member': m.name, 'amount': auditRupiah(amount)},
    amountCents: amount,
  );
}

/// A hand correction, signed, with a mandatory reason. `refund`.
///
/// Exists because once `snapshotVisitAndDelete` has run there is no visit and
/// no receipt, so [reverseChargeForPayment] is unreachable — and without this a
/// mistyped amount could only be fixed by a [writeOffDebt], which would make
/// the bad-debt figure a mix of real losses and typos. Same reason
/// `adjustPoints` exists beside the points reversal.
Future<void> adjustDebt(
  AppDatabase db, {
  required String memberId,
  required int delta,
  required String note,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  if (delta == 0) throw const DebtException('invalid_amount');
  if (note.trim().isEmpty) throw const DebtException('note_required');
  final m = await (db.select(
    db.members,
  )..where((x) => x.id.equals(memberId))).getSingleOrNull();
  if (m == null) throw const DebtException('not_found');
  await _post(
    db,
    memberId: memberId,
    kind: MemberDebtKind.adjust,
    delta: delta,
    note: note.trim(),
    actorUserId: actorUserId,
    hub: hub,
    at: at,
    idPrefix: idPrefix,
    auditKind: AuditKind.debtAdjusted,
    auditParams: {
      'member': m.name,
      // Signed on purpose: which way the correction went is the finding, and a
      // magnitude would hide it — the same call `countCash` makes on variance.
      'amount': '${delta > 0 ? '+' : '-'}${auditRupiah(delta.abs())}',
    },
    amountCents: delta.abs(),
  );
}

/// Undo the charge a payment raised, because that payment is being deleted.
///
/// Reachable only while the visit still exists — a reopened receipt hard-deletes
/// its payments, and this runs over them first. **Idempotent**: reopening twice,
/// or a retry after a half-failed request, must not reverse twice.
Future<void> reverseChargeForPayment(
  AppDatabase db, {
  required String paymentId,
  String? actorUserId,
  WsHub? hub,
}) async {
  final t = db.memberDebts;
  final rows = await (db.select(t)..where((x) => x.paymentId.equals(paymentId)))
      .get();
  final charge = rows
      .where((r) => r.kind == MemberDebtKind.charge.name)
      .firstOrNull;
  if (charge == null) return;
  // The reversal carries the same paymentId, so its presence is the idempotency
  // key — no separate "reversed" flag to keep in step with reality.
  final already = rows.any((r) => r.kind == MemberDebtKind.reversal.name);
  if (already) return;
  await _post(
    db,
    memberId: charge.memberId,
    kind: MemberDebtKind.reversal,
    delta: -charge.delta,
    paymentId: paymentId,
    visitId: charge.visitId,
    billLabel: charge.billLabel,
    actorUserId: actorUserId,
    hub: hub,
    auditKind: AuditKind.debtReversed,
    auditParams: {
      'member': await _nameOf(db, charge.memberId),
      'amount': auditRupiah(charge.delta.abs()),
      'bill': charge.billLabel,
    },
    amountCents: charge.delta.abs(),
  );
}

Future<String> _nameOf(AppDatabase db, String memberId) async {
  final m = await (db.select(
    db.members,
  )..where((x) => x.id.equals(memberId))).getSingleOrNull();
  return m?.name ?? '';
}

Future<void> _post(
  AppDatabase db, {
  required String memberId,
  required MemberDebtKind kind,
  required int delta,
  required AuditKind auditKind,
  required Map<String, String> auditParams,
  required int amountCents,
  String? paymentId,
  String? visitId,
  String billLabel = '',
  String? method,
  String? note,
  Uint8List? photo,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  final id = '${idPrefix ?? ''}${_uuid.v4()}';
  final actor = await resolveActor(db, actorUserId);
  final when = at ?? SatClock.now();
  await db.into(db.memberDebts).insert(
    MemberDebtsCompanion.insert(
      id: id,
      memberId: memberId,
      kind: kind.name,
      delta: delta,
      at: when,
      paymentId: Value(paymentId),
      visitId: Value(visitId),
      billLabel: Value(billLabel),
      method: Value(method),
      note: Value(note),
      photo: Value(photo),
      actorUserId: Value(actorUserId),
      actorName: Value(actor?.name),
    ),
  );
  await writeAudit(
    db,
    type: AuditType.debtMovement,
    kind: auditKind,
    params: auditParams,
    actorUserId: actorUserId,
    reason: note,
    amountCents: amountCents,
    hub: hub,
    at: at,
    idPrefix: idPrefix,
  );
  // The directory row and the till panel both render the balance, so every
  // movement re-broadcasts the member rather than inventing a second event.
  await broadcastMemberDebt(db, memberId, hub);
}

/// Re-emit the whole member so every client's balance and headroom catch up.
///
/// The whole record rather than a debt-shaped patch, for the reason
/// `member.updated` carries one already: a client cannot recompute `SUM(delta)`
/// from the page it happens to hold, and one event beats two that can arrive
/// out of order.
Future<void> broadcastMemberDebt(
  AppDatabase db,
  String memberId,
  WsHub? hub,
) async {
  if (hub == null) return;
  final m = await getMember(db, memberId);
  if (m != null) hub.broadcast(WsEventTypes.memberUpdated, memberJson(m));
}

/// Wire shape for one ledger row. The photo is a flag, never bytes.
Map<String, dynamic> debtEntryJson(MemberDebtEntry e) => {
  'id': e.id,
  'memberId': e.memberId,
  'kind': e.kind.name,
  'delta': e.delta,
  'paymentId': e.paymentId,
  'billLabel': e.billLabel,
  'method': e.method,
  'note': e.note,
  'hasPhoto': e.hasPhoto,
  'actorName': e.actorName,
  'at': e.at.toIso8601String(),
};

Map<String, dynamic> debtJson(MemberDebt d) => {
  'balance': d.balance,
  'limit': d.limit,
  'ownLimit': d.ownLimit,
  'headroom': d.headroom,
  'entries': [for (final e in d.entries) debtEntryJson(e)],
};

/// Everyone who owes something, largest first.
///
/// Ageing is **derived at read time** by applying every negative movement to
/// the outstanding charges oldest-first. That is what buys per-charge ageing
/// with no due-date column and no invoice-allocation table — the ledger already
/// knows, it just has to be walked in order.
Future<List<Debtor>> listDebtors(AppDatabase db) async {
  final t = db.memberDebts;
  final ledger = await (db.select(t)
        ..orderBy([(x) => OrderingTerm.asc(x.at), (x) => OrderingTerm.asc(x.id)]))
      .get();
  final byMember = <String, List<rows.MemberDebt>>{};
  for (final r in ledger) {
    byMember.putIfAbsent(r.memberId, () => []).add(r);
  }
  if (byMember.isEmpty) return const [];
  final members = await (db.select(
    db.members,
  )..where((m) => m.id.isIn(byMember.keys))).get();
  final nameOf = {for (final m in members) m.id: m};

  final out = <Debtor>[];
  for (final entry in byMember.entries) {
    final walk = _walk(entry.value);
    if (walk.balance <= 0) continue;
    final m = nameOf[entry.key];
    out.add(
      Debtor(
        memberId: entry.key,
        // A deleted member cannot owe anything (the delete refuses while a
        // balance stands), so a missing row here means a merge raced a read.
        name: m?.name ?? '',
        phone: m?.phone ?? '',
        balance: walk.balance,
        oldestUnpaidAt: walk.oldestUnpaidAt,
        lastPaymentAt: walk.lastPaymentAt,
      ),
    );
  }
  out.sort((a, b) => b.balance.compareTo(a.balance));
  return out;
}

typedef _Walk = ({int balance, DateTime? oldestUnpaidAt, DateTime? lastPaymentAt});

/// Apply every negative movement to the outstanding charges oldest-first.
///
/// [ledger] must already be ordered oldest-first.
_Walk _walk(List<rows.MemberDebt> ledger) {
  // Each open charge as (amount still outstanding, when it was raised).
  final open = <({int amount, DateTime at})>[];
  DateTime? lastPaymentAt;
  // Charges first, reductions after — never interleaved. Two rows can share a
  // timestamp (a charge and its reversal, a seeded day), and `id` is a uuid, so
  // reading them in row order would let a payment arrive before the charge it
  // pays and leave the whole balance looking open.
  var reduced = 0;
  for (final r in ledger) {
    if (r.delta > 0) {
      open.add((amount: r.delta, at: r.at));
      continue;
    }
    if (r.kind == MemberDebtKind.payment.name) lastPaymentAt = r.at;
    reduced += -r.delta;
  }
  while (reduced > 0 && open.isNotEmpty) {
    final head = open.first;
    if (head.amount > reduced) {
      open[0] = (amount: head.amount - reduced, at: head.at);
      reduced = 0;
    } else {
      reduced -= head.amount;
      open.removeAt(0);
    }
  }
  final balance = open.fold<int>(0, (a, o) => a + o.amount);
  return (
    balance: balance,
    oldestUnpaidAt: open.isEmpty ? null : open.first.at,
    lastPaymentAt: lastPaymentAt,
  );
}

/// The Piutang report section (ADR-0098).
///
/// [from] is expected to already carry the `businessDayStartHour` rollover the
/// caller applies to its sales buckets, so a 02:00 collection lands with the
/// night it belongs to — the same contract `cashReportSection` keeps.
///
/// `opening` and `closing` are venue-wide outstanding, not window sums: a
/// receivable does not reset at midnight.
Future<Map<String, dynamic>> debtReportSection(
  AppDatabase db, {
  required DateTime from,
  required DateTime to,
}) async {
  final cfg = await debtConfig(db);
  final opening = await totalDebt(db, before: from);
  final t = db.memberDebts;
  final window =
      await (db.selectOnly(t)
            ..addColumns([t.kind, t.delta, t.method])
            ..where(
              t.at.isBiggerOrEqualValue(from) & t.at.isSmallerThanValue(to),
            ))
          .get();
  var charged = 0;
  var collected = 0;
  var writtenOff = 0;
  var adjusted = 0;
  final byMethod = <String, int>{};
  for (final r in window) {
    final delta = r.read(t.delta) ?? 0;
    switch (memberDebtKindFromName(r.read(t.kind))) {
      case MemberDebtKind.charge:
        charged += delta;
      case MemberDebtKind.payment:
        collected += -delta;
        final m = r.read(t.method);
        if (m != null) byMethod[m] = (byMethod[m] ?? 0) + -delta;
      case MemberDebtKind.writeOff:
        writtenOff += -delta;
      // A reversal undoes a charge that was itself counted above, so it nets
      // against `charged` rather than reading as a collection — otherwise a
      // reopened bill would look like money arriving.
      case MemberDebtKind.reversal:
        charged += delta;
      case MemberDebtKind.adjust:
        adjusted += -delta;
      case null:
        break;
    }
  }
  final debtors = await listDebtors(db);
  final cutoff = to.subtract(Duration(days: cfg.overdueDays));
  var overdueTotal = 0;
  for (final d in debtors) {
    final oldest = d.oldestUnpaidAt;
    if (oldest != null && oldest.isBefore(cutoff)) overdueTotal += d.balance;
  }
  return {
    'enabled': cfg.enabled,
    'opening': opening,
    'charged': charged,
    'collected': collected,
    'writtenOff': writtenOff,
    'adjusted': adjusted,
    'closing': opening + charged - collected - writtenOff - adjusted,
    'byMethod': byMethod,
    'overdueDays': cfg.overdueDays,
    'overdueTotal': overdueTotal,
    'debtorCount': debtors.length,
    // Capped like the members section's top-spender table: a report is read on
    // a tablet, and the full list lives on /members behind a filter chip.
    'debtors': [for (final d in debtors.take(20)) d.toJson()],
    'debtorsTruncated': debtors.length > 20,
  };
}
