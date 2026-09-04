/// The **[[Pengeluaran kunjungan]]** ledger (ADR-0130) — every write to
/// `visit_expenses` goes through here, for the reason `writeAudit`, `cash.dart`,
/// `members.dart`, `stock_counts.dart` and `self_order.dart` exist: a rule
/// enforced in one route reaches three call sites out of four.
///
/// Two invariants live in this file and nowhere else:
///
/// - **The cap.** A visit's expenses may not exceed what that visit rang up —
///   you cannot take more out of a table than the table produced. Derived, so
///   no `CHECK` can hold it, which is why it is re-read inside the transaction
///   (ADR-0100).
/// - **Append-only.** There is no update path and no delete path. Not "not
///   yet": the cash already left.
///
/// What is deliberately **not** here: anything that touches a [[Bill (tab)]].
/// The bill total, its receipts and its outstanding never learn an expense
/// happened, and `recomputeBill` is untouched by this feature — that is what
/// keeps an expense (a cost the venue absorbed) distinguishable from a
/// [[Diskon (discount)]] (a give-back to the guest).
library;


import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/visit_expense.dart';
import 'package:satset/server/audit_log.dart';
// Hidden for `cash.dart`'s reason: drift generates its own row classes for both
// tables, and a row is not what a reader sees.
import 'package:satset/server/db/database.dart'
    hide VisitExpense, VisitExpenseCategory;
import 'package:satset/server/modules.dart';
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

/// Thrown for a refusal a person needs to act on. The [code] crosses the wire
/// and the words are composed client-side (ADR-0085).
class VisitExpenseException implements Exception {
  final String code;

  /// Present on `exceeds_bill`, so the sheet can say how much is left rather
  /// than making the waiter go and look — `CashException.balance`'s reason.
  final int? cap;
  final int? spent;

  const VisitExpenseException(this.code, {this.cap, this.spent});

  @override
  String toString() => 'VisitExpenseException($code)';
}

/// Whether this venue records expenses against a visit at all.
///
/// Two facts ANDed, and composed **here** rather than at a route — the rule
/// `modules.dart` states and `memberConfig` follows: the owner's own switch,
/// and the `tableExpense` [[Modul|mode key]] on top. A mode fails **closed**,
/// which is the direction that matters most for this one: fail-open would hand
/// a revenue-reducing write to the floor of every venue that has never phoned
/// home.
Future<bool> visitExpenseEnabled(AppDatabase db) async {
  final s = await (db.select(
    db.venueSettings,
  )..where((v) => v.id.equals('default'))).getSingleOrNull();
  return (s?.tableExpenseEnabled ?? false) &&
      venueHasMode(s, modeTableExpense);
}

/// What this visit rang up: the subtotal of its sent, non-voided lines, before
/// tax, service and any discount.
///
/// The line set is exactly the bill's — `status` neither `voided` nor `draft`,
/// the test `settlement_routes.dart` already applies — because a cap measured
/// over a different set of lines than the guest is being charged for is a cap
/// nobody can explain.
///
/// Pre-tax and pre-discount on purpose: it is the honest measure of what the
/// party is worth to the venue, and it does not move when a cashier applies a
/// promo after the waiter has already spent the money.
Future<int> visitSubtotal(AppDatabase db, String visitId) async {
  final rows =
      await (db.select(db.tickets)..where(
            (t) =>
                t.visitId.equals(visitId) &
                t.status.equals('voided').not() &
                t.status.equals('draft').not(),
          ))
          .get();
  var total = 0;
  for (final t in rows) {
    total += t.price * t.qty;
  }
  return total;
}

/// What has already been spent against this visit.
Future<int> visitExpenseTotal(AppDatabase db, String visitId) async {
  final sum = db.visitExpenses.amount.sum();
  final q = db.selectOnly(db.visitExpenses)
    ..addColumns([sum])
    ..where(db.visitExpenses.visitId.equals(visitId));
  final row = await q.getSingleOrNull();
  return row?.read(sum) ?? 0;
}

/// Record one expense against [visitId]. The only write path.
///
/// [id] is client-minted and doubles as the idempotency key, so the
/// [[Antrean kirim]] replays under it.
Future<VisitExpense> recordVisitExpense(
  AppDatabase db, {
  required String id,
  required String visitId,
  required String categoryId,
  required int amount,
  required Uint8List photo,
  String? note,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
}) async {
  if (amount <= 0) throw const VisitExpenseException('invalid_amount');
  // Enforced here and not only in the sheet: a photo the server does not
  // require is an optional photo, whatever the client renders.
  if (photo.isEmpty) throw const VisitExpenseException('photo_required');

  return db.transaction(() async {
    // The id is client-minted and doubles as the idempotency key (ADR-0130), so
    // a replay after a lost reply must read back what the first attempt wrote —
    // not insert the same primary key again.
    //
    // This lives here rather than resting on `idempotent()`, which keys on the
    // `x-idempotency-key` **header**: a caller that omits the header would
    // otherwise get a constraint violation as a 500. The guarantee belongs to
    // the writer, where no transport can forget it. Found on a device: the
    // drain replays under the id and the header was never sent.
    final already = await _expenseById(db, id);
    if (already != null) return already;

    final visit = await (db.select(
      db.visits,
    )..where((v) => v.id.equals(visitId))).getSingleOrNull();
    if (visit == null) throw const VisitExpenseException('visit_not_found');
    // After bill close the snapshot is immutable. The way back is **reopen**,
    // which the cashier already has — deliberately not a grace window, which
    // would be a second lifecycle nobody can reason about.
    if (visit.billClosedAt != null) {
      throw const VisitExpenseException('bill_closed');
    }

    final category = await (db.select(
      db.visitExpenseCategories,
    )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
    if (category == null) {
      throw const VisitExpenseException('category_not_found');
    }

    // Check and write are one atomic step (ADR-0100): the cap is derived, so
    // two handsets capturing at once must not both clear a guard neither still
    // meets. The read is why `idx_visit_expenses_visit` exists.
    final cap = await visitSubtotal(db, visitId);
    final spent = await visitExpenseTotal(db, visitId);
    if (spent + amount > cap) {
      throw VisitExpenseException('exceeds_bill', cap: cap, spent: spent);
    }

    final actor = await resolveActor(db, actorUserId);
    final when = at ?? SatClock.now();
    await db
        .into(db.visitExpenses)
        .insert(
          VisitExpensesCompanion.insert(
            id: id.isEmpty ? _uuid.v4() : id,
            visitId: visitId,
            categoryId: categoryId,
            amount: amount,
            photo: photo,
            at: when,
            note: Value(note ?? ''),
            actorUserId: Value(actorUserId),
          ),
        );

    await writeAudit(
      db,
      type: AuditType.cashMovement,
      kind: AuditKind.tableExpenseRecorded,
      params: {
        'amount': auditRupiah(amount),
        // The venue's own word, not a key: this vocabulary is venue-authored
        // and ARB-exempt, unlike `cashSpent`'s closed set. Frozen at write time
        // for the reason every audit param is — a later rename must not rewrite
        // what the log says happened.
        'category': category.name,
        'table': visit.tableLabel ?? '',
      },
      tableId: visit.tableId,
      actorUserId: actorUserId,
      reason: note,
      amountCents: amount,
      hub: hub,
      at: at,
    );

    hub?.broadcast(WsEventTypes.visitExpenseRecorded, {
      'visitId': visitId,
      'total': spent + amount,
    });

    return VisitExpense(
      id: id,
      visitId: visitId,
      categoryId: categoryId,
      categoryName: category.name,
      amount: amount,
      note: note ?? '',
      at: when,
      actorUserId: actorUserId,
      actorName: actor?.name,
    );
  });
}

/// One expense by id, with its category word and author resolved. Null when
/// this id has never been written.
Future<VisitExpense?> _expenseById(AppDatabase db, String id) async {
  final e = db.visitExpenses;
  final c = db.visitExpenseCategories;
  final u = db.users;
  final r =
      await (db.select(e).join([
            leftOuterJoin(c, c.id.equalsExp(e.categoryId)),
            leftOuterJoin(u, u.id.equalsExp(e.actorUserId)),
          ])..where(e.id.equals(id)))
          .getSingleOrNull();
  if (r == null) return null;
  return VisitExpense(
    id: r.read(e.id)!,
    visitId: r.read(e.visitId)!,
    categoryId: r.read(e.categoryId)!,
    categoryName: r.read(c.name) ?? r.read(e.categoryId)!,
    amount: r.read(e.amount)!,
    note: r.read(e.note) ?? '',
    at: r.read(e.at)!,
    actorUserId: r.read(e.actorUserId),
    actorName: r.read(u.name),
  );
}

/// This visit's expenses, newest first. **Never selects `photo`** — the blob is
/// reached only by its own route, so a bill overlay stays a few KB no matter
/// how many receipts were shot (`cashLedger`'s rule).
Future<List<VisitExpense>> visitExpenses(AppDatabase db, String visitId) async {
  final e = db.visitExpenses;
  final c = db.visitExpenseCategories;
  final u = db.users;
  final q =
      db.select(e).join([
          leftOuterJoin(c, c.id.equalsExp(e.categoryId)),
          leftOuterJoin(u, u.id.equalsExp(e.actorUserId)),
        ])
        ..where(e.visitId.equals(visitId))
        ..orderBy([OrderingTerm.desc(e.at)]);
  final rows = await q.get();
  return [
    for (final r in rows)
      VisitExpense(
        id: r.read(e.id)!,
        visitId: visitId,
        categoryId: r.read(e.categoryId)!,
        // Falls through to the raw id if the category is somehow gone. It never
        // should be — categories are soft-deleted — but a report that renders
        // an id beats one that throws.
        categoryName: r.read(c.name) ?? r.read(e.categoryId)!,
        amount: r.read(e.amount)!,
        note: r.read(e.note) ?? '',
        at: r.read(e.at)!,
        actorUserId: r.read(e.actorUserId),
        actorName: r.read(u.name),
      ),
  ];
}

/// The categories a picker may offer. Active only, in the owner's order.
Future<List<VisitExpenseCategory>> activeExpenseCategories(
  AppDatabase db,
) async {
  final rows =
      await (db.select(db.visitExpenseCategories)
            ..where((c) => c.active.equals(true))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();
  return [
    for (final r in rows)
      VisitExpenseCategory(
        id: r.id,
        name: r.name,
        active: r.active,
        sortOrder: r.sortOrder,
      ),
  ];
}

/// The Pengeluaran report section (ADR-0130).
///
/// Its own top-level section, like Kas and Keanggotaan, and for a reason that
/// is the mirror of Kas's: petty cash is **not** revenue (ADR-0089) and this
/// **is** — it comes out of what a visit rang up. What it must never do is move
/// `net`: `settledTotal` keeps ADR-0039's frozen formula, and the subtraction
/// happens once, here, as a figure of its own.
///
/// Reads the **snapshot**, not the live ledger, so a closed month keeps saying
/// what it said. [from] already carries the caller's `businessDayStartHour`
/// rollover, so a 02:00 expense buckets with the sales it sat beside.
Future<Map<String, dynamic>> visitExpenseReportSection(
  AppDatabase db, {
  required DateTime from,
  required DateTime to,
}) async {
  final t = db.tableSessions;
  final sessions =
      await (db.select(t)..where(
            (s) =>
                s.closedAt.isBiggerOrEqualValue(from) &
                s.closedAt.isSmallerThanValue(to) &
                s.expenseAmount.isBiggerThanValue(0),
          ))
          .get();

  // The live rows are the section: they carry the category, the author **and**
  // the total. The snapshots are read only for the per-visit list below.
  //
  // One axis, deliberately. A snapshot enters the window on `closedAt` and an
  // expense on `at`, and a card that mixes the two contradicts itself the
  // moment a visit is still open — found on a device reading "4 expenses ·
  // Rp 70.000 by category · total Rp 0". `at` is the axis that wins because it
  // is the one ADR-0130 names: an expense belongs to the moment the cash left
  // the drawer, whenever the bill it was spent against happens to close. So
  // the breakdown always sums to the headline, and `netAfterExpense` subtracts
  // that same number (`reports_routes.dart`).
  final rows = await visitExpensesBetween(db, from: from, to: to);
  final byCategory = <String, int>{};
  final byActor = <String, int>{};
  for (final e in rows) {
    byCategory[e.categoryName] = (byCategory[e.categoryName] ?? 0) + e.amount;
    final who = e.actorName ?? '';
    if (who.isNotEmpty) byActor[who] = (byActor[who] ?? 0) + e.amount;
  }

  return {
    'total': rows.fold<int>(0, (a, e) => a + e.amount),
    'count': rows.length,
    'byCategory': byCategory,
    'byStaff': byActor,
    // Which visits cost something, so a manager can see where the money went
    // rather than only how much of it did.
    'visits': [
      for (final s in sessions)
        {
          'sessionId': s.id,
          'tableLabel': s.tableLabel ?? '—',
          'closedAt': s.closedAt.toIso8601String(),
          'settledTotal': s.settledTotal,
          'expenseAmount': s.expenseAmount,
        },
    ],
    // Counted off the same rows as the headline, not off `sessions`: an
    // expense on a visit that has not closed yet still cost the venue money,
    // and "Rp 70.000 across 0 visits" is the same two-axis contradiction the
    // total had. The `visits` list above stays the *closed*-visit detail,
    // because a table label and a settled figure only exist on a snapshot.
    'visitCount': {for (final e in rows) e.visitId}.length,
  };
}

/// Every expense written in the window, decorated with its category name and
/// its author. Reads `at`, not the visit's close, because an expense belongs to
/// the moment the cash left.
Future<List<VisitExpense>> visitExpensesBetween(
  AppDatabase db, {
  required DateTime from,
  required DateTime to,
}) async {
  final e = db.visitExpenses;
  final c = db.visitExpenseCategories;
  final u = db.users;
  final rows =
      await (db.select(e).join([
            leftOuterJoin(c, c.id.equalsExp(e.categoryId)),
            leftOuterJoin(u, u.id.equalsExp(e.actorUserId)),
          ])..where(
            e.at.isBiggerOrEqualValue(from) & e.at.isSmallerThanValue(to),
          ))
          .get();
  return [
    for (final r in rows)
      VisitExpense(
        id: r.read(e.id)!,
        visitId: r.read(e.visitId)!,
        categoryId: r.read(e.categoryId)!,
        categoryName: r.read(c.name) ?? r.read(e.categoryId)!,
        amount: r.read(e.amount)!,
        note: r.read(e.note) ?? '',
        at: r.read(e.at)!,
        actorUserId: r.read(e.actorUserId),
        actorName: r.read(u.name),
      ),
  ];
}

/// Create or edit one category. The one write path for the venue's vocabulary.
///
/// **There is no delete.** [active] parks a category the venue has stopped
/// using while every expense already filed under it keeps rendering its name —
/// the same posture the [[Preset diskon]] catalogue takes toward a seasonal
/// promo, arrived at here for a stronger reason: a preset's name is snapshotted
/// onto the discount it applied, and a category's is not.
Future<VisitExpenseCategory> upsertExpenseCategory(
  AppDatabase db, {
  String? id,
  required String name,
  bool? active,
  int? sortOrder,
}) async {
  final rowId = (id == null || id.isEmpty) ? _uuid.v4() : id;
  await db
      .into(db.visitExpenseCategories)
      .insertOnConflictUpdate(
        VisitExpenseCategoriesCompanion.insert(
          id: rowId,
          name: name,
          active: Value(active ?? true),
          sortOrder: Value(sortOrder ?? 0),
        ),
      );
  final row = await (db.select(
    db.visitExpenseCategories,
  )..where((c) => c.id.equals(rowId))).getSingle();
  return VisitExpenseCategory(
    id: row.id,
    name: row.name,
    active: row.active,
    sortOrder: row.sortOrder,
  );
}

/// Wire shape for one row. The photo is a flag, never bytes.
Map<String, dynamic> visitExpenseJson(VisitExpense e) => {
  'id': e.id,
  'visitId': e.visitId,
  'categoryId': e.categoryId,
  'categoryName': e.categoryName,
  'amount': e.amount,
  'note': e.note,
  'hasPhoto': e.hasPhoto,
  'actorUserId': e.actorUserId,
  'actorName': e.actorName,
  'at': e.at.toIso8601String(),
};

Map<String, dynamic> visitExpenseCategoryJson(VisitExpenseCategory c) => {
  'id': c.id,
  'name': c.name,
  'active': c.active,
  'sortOrder': c.sortOrder,
};
