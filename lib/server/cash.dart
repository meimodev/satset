/// The petty cash box (§Kas kecil) — every write to `cash_entries` goes through
/// here, for the reason `writeAudit` exists: a rule enforced in one route reaches
/// three call sites out of four.
///
/// Three invariants live in this file and nowhere else:
///
/// - **The balance is derived.** `SUM(delta)`, every time. Nothing stores it.
/// - **The balance is per box** (ADR-0131). A venue holds several named tins
///   and each one answers for itself: a full Kas Utama must not silently clear
///   the guard on an empty Kas Dapur, because the notes are in another room.
/// - **A box cannot go negative** (ADR-0088), with the two exemptions the ADR
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
// `CashBoxes` needs no such treatment: its row class is named `CashBoxRow` at
// the table.
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

/// What is in one box right now, or in every box together when [boxId] is null.
/// Optionally as of [before], which is what the Kas report section's opening
/// balance is.
///
/// The venue-wide arm exists for the report's totals only. **No guard may use
/// it**: ADR-0131 binds the negative check to one tin.
Future<int> cashBalance(
  AppDatabase db, {
  String? boxId,
  DateTime? before,
}) async {
  final sum = db.cashEntries.delta.sum();
  final q = db.selectOnly(db.cashEntries)..addColumns([sum]);
  if (boxId != null) q.where(db.cashEntries.boxId.equals(boxId));
  if (before != null) q.where(db.cashEntries.at.isSmallerThanValue(before));
  final row = await q.getSingleOrNull();
  return row?.read(sum) ?? 0;
}

/// The venue's boxes with their balances, ordered the way the picker shows
/// them. Inactive boxes are included by default: a retired tin still appears in
/// the ledger's history and the client needs its name.
Future<List<CashBox>> cashBoxList(
  AppDatabase db, {
  bool activeOnly = false,
}) async {
  final t = db.cashBoxes;
  final q = db.select(t)
    ..orderBy([(b) => OrderingTerm.asc(b.sortOrder), (b) => OrderingTerm.asc(b.name)]);
  if (activeOnly) q.where((b) => b.active.equals(true));
  final rows = await q.get();
  // One grouped scan rather than a balance query per box: the ledger is small,
  // and N+1 round trips on the screen's first paint is the wrong trade even so.
  final sum = db.cashEntries.delta.sum();
  final totals = await (db.selectOnly(db.cashEntries)
        ..addColumns([db.cashEntries.boxId, sum])
        ..groupBy([db.cashEntries.boxId]))
      .get();
  final byBox = {
    for (final r in totals)
      r.read(db.cashEntries.boxId)!: r.read(sum) ?? 0,
  };
  return [
    for (final b in rows)
      CashBox(
        id: b.id,
        name: b.name,
        active: b.active,
        sortOrder: b.sortOrder,
        balance: byBox[b.id] ?? 0,
      ),
  ];
}

/// The box's name as it stands, for an audit line. Throws
/// `CashException('box_not_found')` rather than writing a movement against a
/// tin nobody can name.
Future<String> _boxName(AppDatabase db, String boxId) async {
  final row = await (db.select(
    db.cashBoxes,
  )..where((b) => b.id.equals(boxId))).getSingleOrNull();
  if (row == null) throw const CashException('box_not_found');
  return row.name;
}

/// A box's [[Kategori kas (cash category)|categories]] in picker order
/// (ADR-0135).
///
/// Inactive rows are included by default, for the reason [cashBoxList] includes
/// retired boxes: a movement already filed under a retired word still has to
/// render it.
Future<List<CashCategory>> cashCategoryList(
  AppDatabase db, {
  String? boxId,
  bool activeOnly = false,
}) async {
  final t = db.cashCategories;
  final q = db.select(t)
    ..orderBy([
      (c) => OrderingTerm.asc(c.sortOrder),
      (c) => OrderingTerm.asc(c.name),
    ]);
  if (boxId != null) q.where((c) => c.boxId.equals(boxId));
  if (activeOnly) q.where((c) => c.active.equals(true));
  return [
    for (final r in await q.get())
      CashCategory(
        boxId: r.boxId,
        id: r.id,
        name: r.name,
        active: r.active,
        sortOrder: r.sortOrder,
      ),
  ];
}

/// `(boxId, categoryId) -> name` for a whole page of ledger rows, so rendering
/// a category costs one read instead of one per row.
Future<Map<(String, String?), String>> _categoryNames(AppDatabase db) async {
  final rows = await db.select(db.cashCategories).get();
  return {for (final r in rows) (r.boxId, r.id): r.name};
}

/// The category as it stands, refused unless it is **active and belongs to this
/// box** (ADR-0135). A word from another tin is `unknown_category`, never
/// silently accepted: per-box catalogues would mean nothing if any id worked.
Future<CashCategory> _activeCategory(
  AppDatabase db, {
  required String boxId,
  required String id,
}) async {
  final row =
      await (db.select(db.cashCategories)
            ..where((c) => c.boxId.equals(boxId) & c.id.equals(id)))
          .getSingleOrNull();
  if (row == null || !row.active) {
    throw const CashException('unknown_category');
  }
  return CashCategory(
    boxId: row.boxId,
    id: row.id,
    name: row.name,
    active: row.active,
    sortOrder: row.sortOrder,
  );
}

/// Author a category on one box. `editSettings` — the authority that names a
/// tin names what comes out of it.
///
/// **No audit row** (ADR-0135): a box audits because it holds a balance, and a
/// category is vocabulary. Every movement already carries both.
Future<CashCategory> createCashCategory(
  AppDatabase db, {
  required String boxId,
  required String name,
}) async {
  final clean = name.trim();
  if (clean.isEmpty) throw const CashException('name_required');
  await _boxName(db, boxId);
  final id = 'cat-${_uuid.v4()}';
  final maxOrder = db.cashCategories.sortOrder.max();
  final row =
      await (db.selectOnly(db.cashCategories)
            ..addColumns([maxOrder])
            ..where(db.cashCategories.boxId.equals(boxId)))
          .getSingleOrNull();
  final order = (row?.read(maxOrder) ?? 0) + 1;
  await db
      .into(db.cashCategories)
      .insert(
        CashCategoriesCompanion.insert(
          boxId: boxId,
          id: id,
          name: clean,
          sortOrder: Value(order),
        ),
      );
  return CashCategory(boxId: boxId, id: id, name: clean, sortOrder: order);
}

/// Rename a category, or retire it. `editSettings`.
///
/// A rename is **retroactive** — the entry stores the id and the word is
/// resolved on read — so last month's report re-reads under the new one while
/// the audit trail keeps what it wrote at the time.
///
/// There is **no delete**, and no guard against retiring the last active one: a
/// box whose catalogue is empty shows an empty state and the write path still
/// refuses. Guarding it would block retiring the five stock words before
/// authoring your own.
Future<CashCategory> updateCashCategory(
  AppDatabase db, {
  required String boxId,
  required String id,
  String? name,
  bool? active,
}) async {
  final row =
      await (db.select(db.cashCategories)
            ..where((c) => c.boxId.equals(boxId) & c.id.equals(id)))
          .getSingleOrNull();
  if (row == null) throw const CashException('unknown_category');
  final clean = name?.trim();
  if (clean != null && clean.isEmpty) {
    throw const CashException('name_required');
  }
  await (db.update(db.cashCategories)
        ..where((c) => c.boxId.equals(boxId) & c.id.equals(id)))
      .write(
        CashCategoriesCompanion(
          name: clean == null ? const Value.absent() : Value(clean),
          active: active == null ? const Value.absent() : Value(active),
        ),
      );
  return CashCategory(
    boxId: boxId,
    id: id,
    name: clean ?? row.name,
    active: active ?? row.active,
    sortOrder: row.sortOrder,
  );
}

/// Ledger rows, newest first, paged by growing limit (ADR-0079).
///
/// Never selects `photo`: the blob is reached only by its own route, so a ledger
/// page stays a few KB no matter how many receipts were shot.
Future<List<CashEntry>> cashLedger(
  AppDatabase db, {
  String? boxId,
  int limit = 50,
}) async {
  final t = db.cashEntries;
  final q = db.selectOnly(t)
    ..addColumns([
      t.id,
      t.boxId,
      t.kind,
      t.delta,
      t.category,
      t.note,
      t.reversesId,
      t.reversedById,
      t.transferPeerId,
      t.countedAmount,
      t.photo.isNotNull(),
      t.actorUserId,
      t.actorName,
      t.at,
    ])
    ..orderBy([OrderingTerm.desc(t.at), OrderingTerm.desc(t.id)])
    ..limit(limit);
  // Null is the "Semua" arm — every box in one list, each row naming its own.
  if (boxId != null) q.where(t.boxId.equals(boxId));
  final rows = await q.get();
  // One catalogue read for the page rather than a lookup per row. Inactive
  // categories are included on purpose: a retired word still has to render on
  // the movements already filed under it.
  final names = await _categoryNames(db);
  return [
    for (final r in rows)
      CashEntry(
        id: r.read(t.id)!,
        boxId: r.read(t.boxId)!,
        kind: cashEntryKindFromName(r.read(t.kind)) ?? CashEntryKind.expense,
        delta: r.read(t.delta)!,
        categoryId: r.read(t.category),
        categoryName: names[(r.read(t.boxId)!, r.read(t.category))],
        note: r.read(t.note),
        reversesId: r.read(t.reversesId),
        reversedById: r.read(t.reversedById),
        transferPeerId: r.read(t.transferPeerId),
        countedAmount: r.read(t.countedAmount),
        hasPhoto: r.read(t.photo.isNotNull()) ?? false,
        actorUserId: r.read(t.actorUserId),
        actorName: r.read(t.actorName),
        at: r.read(t.at)!,
      ),
  ];
}

/// Money into one box. `editSettings` — the owner funds it.
Future<CashEntry> topUpCash(
  AppDatabase db, {
  required String boxId,
  required int amount,
  String? note,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  if (amount <= 0) throw const CashException('invalid_amount');
  final box = await _boxName(db, boxId);
  return _post(
    db,
    boxId: boxId,
    kind: CashEntryKind.topUp,
    delta: amount,
    note: note,
    actorUserId: actorUserId,
    hub: hub,
    at: at,
    idPrefix: idPrefix,
    auditKind: AuditKind.cashToppedUp,
    auditParams: {'amount': auditRupiah(amount), 'box': box},
    amountCents: amount,
  );
}

/// Money out of one box. `manageCash` — a supervisor spends from it.
///
/// This is the one path the negative check applies to, and it is where ADR-0088
/// is actually enforced — **against this box alone** (ADR-0131). A full Kas
/// Utama does not make an empty Kas Dapur spendable.
Future<CashEntry> spendCash(
  AppDatabase db, {
  required String boxId,
  required int amount,
  required String categoryId,
  String? note,
  Uint8List? photo,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  if (amount <= 0) throw const CashException('invalid_amount');
  final box = await _boxName(db, boxId);
  // Check and write are one atomic step (ADR-0100): two supervisors
  // spending at once must not both clear a guard neither still meets.
  return db.transaction(() async {
    // Both checks read inside the transaction (ADR-0100): a category retired
    // between the read and the write must not slip through, for the same
    // reason two supervisors must not both clear a balance guard.
    final category = await _activeCategory(db, boxId: boxId, id: categoryId);
    final balance = await cashBalance(db, boxId: boxId);
    if (amount > balance) {
      // Physical notes cannot be fewer than zero, so a would-be negative is always
      // a row nobody wrote down — usually a top-up handed over in person. Refusing
      // is what produces that conversation (ADR-0088).
      throw CashException('insufficient_cash', balance: balance);
    }
    return _post(
      db,
      boxId: boxId,
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
      auditParams: {
        'amount': auditRupiah(amount),
        // The word, not the id: an audit line is frozen prose, so a later
        // rename leaves the trail saying what was chosen at the time
        // (ADR-0135). The report, which resolves at read time, will not.
        'category': category.name,
        'box': box,
      },
      amountCents: amount,
    );
  });
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
  required String boxId,
  required int counted,
  String? note,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  if (counted < 0) throw const CashException('invalid_amount');
  final box = await _boxName(db, boxId);
  // Check and write are one atomic step (ADR-0100): a variance computed
  // against a balance that moved before the insert records the wrong
  // finding, which is the one number an opname exists to get right.
  return db.transaction(() async {
    final balance = await cashBalance(db, boxId: boxId);
    final variance = counted - balance;
    return _post(
      db,
      boxId: boxId,
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
        'box': box,
      },
      amountCents: variance.abs(),
    );
  });
}

/// Undo one earlier row with a counter-entry. At most one per row, no time
/// limit, mandatory note (§Kas kecil).
///
/// **A transfer is undone whole** (ADR-0131). Reversing one leg alone would
/// leave money standing in the destination tin that never left the source, and
/// the venue total — the one number no single-box bug could ever corrupt —
/// would start to lie. Both legs are reversed in the same transaction, and the
/// call is refused if either has already been.
///
/// Exempt from the negative check: reversing a top-up whose money has since been
/// spent must stay possible, or an erroneous top-up is permanent (ADR-0088). The
/// exemption covers a transfer's destination leg for the same reason.
///
/// Returns the reversal of the row that was asked for; a transfer's second
/// reversal is written but not returned, and reaches clients over the socket.
Future<List<CashEntry>> reverseCash(
  AppDatabase db, {
  required String entryId,
  required String note,
  String? actorUserId,
  WsHub? hub,
}) async {
  // Check and write are one atomic step (ADR-0100): two concurrent
  // reversals of the same row must not both pass the `already_reversed`
  // guard and post two counter-entries.
  return db.transaction(() async {
    if (note.trim().isEmpty) throw const CashException('note_required');
    final target = await (db.select(
      db.cashEntries,
    )..where((c) => c.id.equals(entryId))).getSingleOrNull();
    if (target == null) throw const CashException('not_found');
    if (target.kind == CashEntryKind.reversal.name) {
      // A reversal of a reversal is a chain nobody can read back.
      throw const CashException('not_reversible');
    }
    final peerId = target.transferPeerId;
    final peer = peerId == null
        ? null
        : await (db.select(
            db.cashEntries,
          )..where((c) => c.id.equals(peerId))).getSingleOrNull();
    // Either leg already undone means the pair is already undone. Checking both
    // is what stops a half-reversed transfer from being reversed the rest of the
    // way into a net loss.
    if (target.reversedById != null || peer?.reversedById != null) {
      throw const CashException('already_reversed');
    }
    final out = <CashEntry>[];
    for (final row in [target, ?peer]) {
      final box = await _boxName(db, row.boxId);
      final entry = await _post(
        db,
        boxId: row.boxId,
        kind: CashEntryKind.reversal,
        delta: -row.delta,
        note: note.trim(),
        reversesId: row.id,
        actorUserId: actorUserId,
        hub: hub,
        auditKind: AuditKind.cashReversed,
        auditParams: {'amount': auditRupiah(row.delta.abs()), 'box': box},
        amountCents: row.delta.abs(),
      );
      // The one field a row ever gains after the fact — a link, not an edit.
      // What happened is untouched.
      await (db.update(db.cashEntries)..where((c) => c.id.equals(row.id)))
          .write(CashEntriesCompanion(reversedById: Value(entry.id)));
      out.add(entry);
    }
    return out;
  });
}

/// Move money from one box to another (ADR-0131). `editSettings` — a transfer
/// funds a tin, and the supervisor who may empty one must not be able to
/// quietly refill it from the owner's float.
///
/// Two ordinary rows, not a fifth [CashEntryKind]: an `expense` out of [fromId]
/// and a `topUp` into [toId], linked by `transferPeerId` and written in one
/// transaction. Every reader that already sums a box therefore needs no new
/// arm, and the venue total nets to zero for free.
///
/// Neither leg carries a [CashCategory]: nothing was bought, so `byCategory`
/// must never see it.
Future<List<CashEntry>> transferCash(
  AppDatabase db, {
  required String fromId,
  required String toId,
  required int amount,
  String? note,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  if (amount <= 0) throw const CashException('invalid_amount');
  if (fromId == toId) throw const CashException('same_box');
  final fromName = await _boxName(db, fromId);
  final toName = await _boxName(db, toId);
  return db.transaction(() async {
    final balance = await cashBalance(db, boxId: fromId);
    if (amount > balance) {
      throw CashException('insufficient_cash', balance: balance);
    }
    // Ids are minted up front so each leg can name the other: the link has to be
    // written with the rows, not patched in afterwards, or a crash between the
    // two inserts leaves a leg nothing can pair.
    final outId = '${idPrefix ?? ''}${_uuid.v4()}';
    final inId = '${idPrefix ?? ''}${_uuid.v4()}';
    final params = {
      'amount': auditRupiah(amount),
      'from': fromName,
      'to': toName,
    };
    final out = await _post(
      db,
      id: outId,
      boxId: fromId,
      kind: CashEntryKind.expense,
      delta: -amount,
      note: note,
      transferPeerId: inId,
      actorUserId: actorUserId,
      hub: hub,
      at: at,
      auditKind: AuditKind.cashTransferred,
      auditParams: params,
      amountCents: amount,
    );
    final into = await _post(
      db,
      id: inId,
      boxId: toId,
      kind: CashEntryKind.topUp,
      delta: amount,
      note: note,
      transferPeerId: outId,
      actorUserId: actorUserId,
      hub: hub,
      at: at,
      // One movement, one audit line: the second leg is the same act seen from
      // the other tin, and two rows saying it would read as two transfers.
      auditKind: null,
      auditParams: params,
      amountCents: amount,
    );
    return [out, into];
  });
}

/// Create a box. `editSettings`.
Future<CashBox> createCashBox(
  AppDatabase db, {
  required String name,
  String? actorUserId,
  WsHub? hub,
}) async {
  final clean = name.trim();
  if (clean.isEmpty) throw const CashException('name_required');
  final id = 'box-${_uuid.v4()}';
  final maxOrder = db.cashBoxes.sortOrder.max();
  final row = await (db.selectOnly(db.cashBoxes)..addColumns([maxOrder]))
      .getSingleOrNull();
  await db.into(db.cashBoxes).insert(
    CashBoxesCompanion.insert(
      id: id,
      name: clean,
      sortOrder: Value((row?.read(maxOrder) ?? 0) + 1),
    ),
  );
  // A tin nobody can file an expense against is a dead end (ADR-0135), so a
  // new box starts with the same five stock words every other box has.
  await db.seedCashCategories(boxId: id);
  await writeAudit(
    db,
    type: AuditType.cashMovement,
    kind: AuditKind.cashBoxCreated,
    params: {'box': clean},
    actorUserId: actorUserId,
    hub: hub,
  );
  return CashBox(id: id, name: clean, balance: 0);
}

/// Rename a box, or retire it. `editSettings`.
///
/// **Retiring is refused while the box still holds money**, the same posture the
/// console takes to removing the `members` module with debt outstanding: hiding
/// a tin from the picker must never hide rupiah with it. Zero it — spend it or
/// transfer it out — and the box retires.
///
/// There is no delete. A closed month's rows must be able to name where the
/// money came from, so `active` is the whole lifecycle.
Future<CashBox> updateCashBox(
  AppDatabase db, {
  required String id,
  String? name,
  bool? active,
  String? actorUserId,
  WsHub? hub,
}) async {
  return db.transaction(() async {
    final row = await (db.select(
      db.cashBoxes,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
    if (row == null) throw const CashException('box_not_found');
    final clean = name?.trim();
    if (clean != null && clean.isEmpty) {
      throw const CashException('name_required');
    }
    final balance = await cashBalance(db, boxId: id);
    if (active == false && row.active && balance != 0) {
      throw CashException('box_not_empty', balance: balance);
    }
    await (db.update(db.cashBoxes)..where((b) => b.id.equals(id))).write(
      CashBoxesCompanion(
        name: clean == null ? const Value.absent() : Value(clean),
        active: active == null ? const Value.absent() : Value(active),
      ),
    );
    final finalName = clean ?? row.name;
    if (clean != null && clean != row.name) {
      await writeAudit(
        db,
        type: AuditType.cashMovement,
        kind: AuditKind.cashBoxRenamed,
        params: {'from': row.name, 'to': clean},
        actorUserId: actorUserId,
        hub: hub,
      );
    }
    if (active != null && active != row.active) {
      await writeAudit(
        db,
        type: AuditType.cashMovement,
        kind: active
            ? AuditKind.cashBoxReopened
            : AuditKind.cashBoxRetired,
        params: {'box': finalName},
        actorUserId: actorUserId,
        hub: hub,
      );
    }
    return CashBox(
      id: id,
      name: finalName,
      active: active ?? row.active,
      sortOrder: row.sortOrder,
      balance: balance,
    );
  });
}

/// The one insert. [auditKind] is nullable for exactly one caller: a transfer's
/// second leg is the same act as its first, and two audit rows would read as
/// two transfers.
Future<CashEntry> _post(
  AppDatabase db, {
  required String boxId,
  required CashEntryKind kind,
  required int delta,
  required AuditKind? auditKind,
  required Map<String, String> auditParams,
  required int amountCents,
  String? id,
  CashCategory? category,

  String? note,
  String? reversesId,
  String? transferPeerId,
  int? countedAmount,
  Uint8List? photo,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  id ??= '${idPrefix ?? ''}${_uuid.v4()}';
  final actor = await resolveActor(db, actorUserId);
  final when = at ?? SatClock.now();
  await db
      .into(db.cashEntries)
      .insert(
        CashEntriesCompanion.insert(
          id: id,
          boxId: Value(boxId),
          kind: kind.name,
          delta: delta,
          at: when,
          category: Value(category?.id),
          note: Value(note),
          reversesId: Value(reversesId),
          transferPeerId: Value(transferPeerId),
          countedAmount: Value(countedAmount),
          photo: Value(photo),
          actorUserId: Value(actorUserId),
          actorName: Value(actor?.name),
        ),
      );
  if (auditKind != null) {
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
  }
  return CashEntry(
    id: id,
    boxId: boxId,
    kind: kind,
    delta: delta,
    at: when,
    categoryId: category?.id,
    categoryName: category?.name,
    note: note,
    reversesId: reversesId,
    transferPeerId: transferPeerId,
    countedAmount: countedAmount,
    hasPhoto: photo != null,
    actorUserId: actorUserId,
    actorName: actor?.name,
  );
}

/// Wire shape for one box.
Map<String, dynamic> cashBoxJson(CashBox b) => {
  'id': b.id,
  'name': b.name,
  'active': b.active,
  'sortOrder': b.sortOrder,
  'balance': b.balance,
};

/// Wire shape for one category.
Map<String, dynamic> cashCategoryJson(CashCategory c) => {
  'boxId': c.boxId,
  'id': c.id,
  'name': c.name,
  'active': c.active,
  'sortOrder': c.sortOrder,
};

/// Wire shape for one ledger row. The photo is a flag, never bytes.
Map<String, dynamic> cashEntryJson(CashEntry e) => {
  'id': e.id,
  'boxId': e.boxId,
  'kind': e.kind.name,
  'delta': e.delta,
  'category': e.categoryId,
  'categoryName': e.categoryName,
  'note': e.note,
  'reversesId': e.reversesId,
  'reversedById': e.reversedById,
  'transferPeerId': e.transferPeerId,
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
///
/// **Every venue-level figure is the sum of the boxes** (ADR-0131), which is
/// what makes a transfer disappear from the totals without a rule to exclude
/// it: the out-leg and the in-leg are equal and opposite, so they cancel. Per
/// box they are counted, because a transfer *is* real movement for that tin.
Future<Map<String, dynamic>> cashReportSection(
  AppDatabase db, {
  required DateTime from,
  required DateTime to,
}) async {
  final boxes = await cashBoxList(db);
  final t = db.cashEntries;
  final rows =
      await (db.selectOnly(t)
            ..addColumns([t.boxId, t.kind, t.delta, t.category])
            ..where(
              t.at.isBiggerOrEqualValue(from) & t.at.isSmallerThanValue(to),
            ))
          .get();

  final inflowBy = <String, int>{};
  final outflowBy = <String, int>{};
  final varianceBy = <String, int>{};
  final byCategory = <String, int>{};
  final byCategoryBox = <String, Map<String, int>>{};
  final names = await _categoryNames(db);
  for (final r in rows) {
    final boxId = r.read(t.boxId) ?? 'box-main';
    final delta = r.read(t.delta) ?? 0;
    final kind = cashEntryKindFromName(r.read(t.kind));
    if (kind == CashEntryKind.count) {
      // A count's delta is a *finding*, not money moving. Folding it into
      // inflow/outflow would report a cash shortfall as a purchase.
      varianceBy[boxId] = (varianceBy[boxId] ?? 0) + delta;
      continue;
    }
    if (delta >= 0) {
      inflowBy[boxId] = (inflowBy[boxId] ?? 0) + delta;
    } else {
      outflowBy[boxId] = (outflowBy[boxId] ?? 0) + -delta;
      final cat = r.read(t.category);
      // A transfer leg has no category and never lands here.
      if (cat == null) continue;
      // Per box, keyed by id — the grain the catalogue is actually authored at.
      (byCategoryBox[boxId] ??= <String, int>{})[cat] =
          (byCategoryBox[boxId]?[cat] ?? 0) + -delta;
      // Venue-wide, keyed by the venue's **own word** (ADR-0135): per-box ids
      // cannot merge, and an owner asking what the venue spent on vegetables is
      // asking about the word, not about which tin paid.
      final word = names[(boxId, cat)] ?? cat;
      byCategory[word] = (byCategory[word] ?? 0) + -delta;
    }
  }

  final byBox = <Map<String, dynamic>>[];
  var opening = 0;
  var inflow = 0;
  var outflow = 0;
  var variance = 0;
  for (final b in boxes) {
    final boxOpening = await cashBalance(db, boxId: b.id, before: from);
    final boxIn = inflowBy[b.id] ?? 0;
    final boxOut = outflowBy[b.id] ?? 0;
    final boxVar = varianceBy[b.id] ?? 0;
    opening += boxOpening;
    inflow += boxIn;
    outflow += boxOut;
    variance += boxVar;
    byBox.add({
      'id': b.id,
      'name': b.name,
      'active': b.active,
      'opening': boxOpening,
      'inflow': boxIn,
      'outflow': boxOut,
      'variance': boxVar,
      'closing': boxOpening + boxIn - boxOut + boxVar,
      'byCategory': {
        for (final e in (byCategoryBox[b.id] ?? const <String, int>{}).entries)
          (names[(b.id, e.key)] ?? e.key): e.value,
      },
    });
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
    'byBox': byBox,
    'count': rows.length,
  };
}
