import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/server/audit_log.dart';
import 'package:satset/server/debts.dart';
import 'package:satset/server/members.dart';
import 'package:satset/server/routes/tables_routes.dart'
    show snapshotVisitAndDelete;
import 'package:satset/server/routes/tickets_routes.dart' show submitOrder;
import 'package:satset/server/shift.dart';
import 'package:satset/server/stock.dart';
import 'package:satset/server/stock_counts.dart';
import 'package:satset/server/ws_hub.dart';

import 'database.dart';
import 'seed_data.dart' as seed;
import 'seed_history_mix.dart';
import 'package:satset/core/time/sat_clock.dart';

/// Every row the fabricated month writes carries this id prefix. ADR-0073
/// keeps ADR-0052 §4's rule — clearing deletes by tag and never truncates a
/// table — and an id prefix is that tag, at no schema cost.
///
/// A real order taken on a seeded venue afterwards carries no prefix, so it
/// survives the clear that removes everything around it.
const samplePrefix = 'contoh-';

/// A stand-in proof photo for seeded non-cash payments (ADR-0086).
///
/// A 1×1 JPEG, on purpose. Its only job is to be *real bytes on a real route*
/// so the venue log's camera glyph, its fetch and its lightbox can be tried on
/// a freshly seeded venue. It is not pretending to be a bank slip, and shipping
/// a convincing fake into an integrity log would be the wrong kind of helpful.
final Uint8List placeholderProofJpeg = base64Decode(
  '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRof'
  'Hh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAAB'
  'AAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==',
);

/// Fixed so the dataset is byte-identical run to run: screenshots compare,
/// a bug found in a demo is reproducible, goldens stay possible (ADR-0052 §7).
const _rngSeed = 20260727;

const historyDays = 30;

/// Seeded RNG for the whole sample dataset.
Random sampleRng() => Random(_rngSeed);

class SampleSeedRefused implements Exception {
  final String reason;
  const SampleSeedRefused(this.reason);
  @override
  String toString() => reason;
}

/// Whether the fabricated month may be written. ADR-0052 §3, carried into
/// ADR-0073 unchanged: the predicate is **any live ticket row or any archived
/// session**.
///
/// Both halves are load-bearing. Closing a bill hard-deletes its tickets into
/// `TableSessions` (ADR-0024), so a venue with a month of genuine trading and
/// no open orders holds zero ticket rows — a ticket-only guard would wave it
/// straight through. Deliberately not "any stock movement": the reference half
/// writes one opening `receive` per bahan (ADR-0042 §1), so that predicate
/// would refuse on exactly the freshly-seeded venue this targets.
Future<bool> canSeedSample(AppDatabase db) async {
  final t = await (db.select(db.tickets)..limit(1)).get();
  if (t.isNotEmpty) return false;
  final s = await (db.select(db.tableSessions)..limit(1)).get();
  return s.isEmpty;
}

/// Whether the venue currently holds a fabricated month — drives the clear
/// action.
Future<bool> hasSampleData(AppDatabase db) async {
  final s =
      await (db.select(db.tableSessions)
            ..where((x) => x.id.like('$samplePrefix%'))
            ..limit(1))
          .get();
  return s.isNotEmpty;
}

/// Remove every fabricated transactional row, leaving the reference half —
/// zones, tables, menu, staff, bahan — standing (ADR-0073).
///
/// An owner who loaded the sample data wants the menu and loses the invented
/// sales; a zone or an item they do not want, they delete by hand. Deletes
/// strictly by tag, never by truncating a table, so a real order taken on a
/// seeded venue survives.
Future<void> clearSampleData(AppDatabase db, {WsHub? hub}) async {
  await db.transaction(() async {
    final sessions = await (db.select(
      db.tableSessions,
    )..where((s) => s.id.like('$samplePrefix%'))).get();
    final ids = sessions.map((s) => s.id).toList();
    if (ids.isNotEmpty) {
      await (db.delete(
        db.tableSessionTickets,
      )..where((x) => x.sessionId.isIn(ids))).go();
      await (db.delete(
        db.tableSessionCourses,
      )..where((x) => x.sessionId.isIn(ids))).go();
      await (db.delete(
        db.tableSessionReceipts,
      )..where((x) => x.sessionId.isIn(ids))).go();
      await (db.delete(
        db.tableSessionDiscounts,
      )..where((x) => x.sessionId.isIn(ids))).go();
      await (db.delete(
        db.tableSessionPayments,
      )..where((x) => x.sessionId.isIn(ids))).go();
      await (db.delete(db.tableSessions)..where((x) => x.id.isIn(ids))).go();
    }
    await (db.delete(
      db.stockMovements,
    )..where((m) => m.id.like('$samplePrefix%'))).go();
    await (db.delete(
      db.auditEntries,
    )..where((a) => a.id.like('$samplePrefix%'))).go();
    // The fabricated month's attendance goes with the month. A real shift
    // opened since carries no prefix and is left standing.
    await (db.delete(
      db.shifts,
    )..where((s) => s.id.like('$samplePrefix%'))).go();
    await (db.delete(
      db.receipts,
    )..where((r) => r.id.like('$samplePrefix%'))).go();
    await (db.delete(
      db.tickets,
    )..where((t) => t.id.like('$samplePrefix%'))).go();
    await (db.delete(
      db.visits,
    )..where((v) => v.id.like('$samplePrefix%'))).go();
    // Lines before headers, same reason as the points ledger: a session whose
    // lines outlived it is a document with a variance and nothing to justify
    // it. The `adjust` movements they closed out of went with the movements
    // above.
    // Matched on the *session* id, not the line's: a line is generated by the
    // writer and carries a bare uuid, and a line's only claim to being sample
    // data is the document it belongs to.
    await (db.delete(
      db.stockCountLines,
    )..where((l) => l.countId.like('$samplePrefix%'))).go();
    await (db.delete(
      db.stockCounts,
    )..where((c) => c.id.like('$samplePrefix%'))).go();
    // The directory is invented too, so it goes with the month it belongs to.
    // Ledger first: a member row with orphaned points would leave a balance
    // nobody can explain, which is the one thing the ledger must never do.
    await (db.delete(
      db.memberPoints,
    )..where((p) => p.id.like('$samplePrefix%'))).go();
    await (db.delete(
      db.members,
    )..where((m) => m.id.like('$samplePrefix%'))).go();
  });
  await recomputeBalances(db);
  _broadcastRefetch(hub);
}

// ------------------------------------------------------------ history rows

/// Pick by weight from `weights`, defaulting anything unlisted.
String _weightedPick(
  Random rng,
  List<String> ids,
  Map<String, double> weights,
) {
  var total = 0.0;
  for (final id in ids) {
    total += weights[id] ?? defaultWeight;
  }
  var roll = rng.nextDouble() * total;
  for (final id in ids) {
    roll -= weights[id] ?? defaultWeight;
    if (roll <= 0) return id;
  }
  return ids.last;
}

int _weightedInt(Random rng, Map<int, double> weights) {
  final total = weights.values.fold<double>(0, (a, b) => a + b);
  var roll = rng.nextDouble() * total;
  for (final e in weights.entries) {
    roll -= e.value;
    if (roll <= 0) return e.key;
  }
  return weights.keys.last;
}

/// A month of settled service, generated from the hand-authored mix
/// (ADR-0053 §6) and written through the **production order path**
/// (ADR-0053 §5) — the same `submitOrder` a waiter's phone calls.
///
/// Every timestamp is passed explicitly rather than by moving the process
/// clock: seeding runs while the app is live, and dragging `SatClock` through
/// the month would swing the running UI's clock and fire time-based alerts
/// against nonsense times (ADR-0073).
Future<void> seedHistory(
  AppDatabase db,
  WsHub hub,
  Random rng,
  List<MenuEntry> menu, {
  void Function(int day, int total)? onDay,
}) async {
  final floor = await db.select(db.venueTables).get();
  if (floor.isEmpty) return;
  final staff = await db.select(db.users).get();
  // Orders are taken by waiters, not by whoever happens to hold a user row —
  // picking across all of them credits the month's bills to the kitchen and
  // to the Firebase admin, and the reports' Pelayan column is then fiction.
  final waiters = staff
      .where((u) => u.roleId == seed.DummyData.roleWaiterId)
      .map((u) => u.id)
      .toList();
  final actors = waiters.isEmpty ? staff.map((u) => u.id).toList() : waiters;
  // Attendance covers everyone, not only the people the month attributes bills
  // to: a cook clocks in exactly like a waiter, and a Jam kerja block that
  // quietly omitted the kitchen would teach the owner it does not cover them.
  // The Firebase admin row is excluded — it is provisioned on first sign-in and
  // never worked a shift.
  final shiftStaff = staff
      .where((u) => u.firebaseUid == null)
      .map((u) => u.id)
      .toList();
  // Discounts are approved by someone other than the waiter asking for one
  // (ADR-0037) — the admin row, or the first staff row on a venue without.
  final approver = staff.isEmpty ? null : staff.first.id;
  final recipes = await loadRecipes(db);
  final ingredients = await db.select(db.ingredients).get();

  final byCourse = <String, List<MenuEntry>>{};
  for (final m in menu) {
    (byCourse[m.course] ??= []).add(m);
  }
  final priceOf = {for (final m in menu) m.id: m.price};
  final nameOf = {for (final m in menu) m.id: m.name};

  final today = SatClock.now();
  var seq = 0;
  String nextId(String kind) => '$samplePrefix$kind-${seq++}';

  /// How many seeded non-cash payments still get a proof photo (ADR-0086).
  ///
  /// A handful, not all ~600: the point is that the venue log's camera glyph
  /// and its lightbox can be exercised on a freshly seeded venue without
  /// anyone having to take a real card payment first. Spending a JPEG on every
  /// tender would prove nothing extra and put the bytes on a tablet.
  ///
  /// Only spent inside the last week, so the rows land in the ranges anyone
  /// actually opens — `today` and `7d`.
  var proofBudget = 20;

  final balance = {for (final i in ingredients) i.id: i.stockOnHand};
  final lowAt = {for (final i in ingredients) i.id: i.lowStockAt ?? 0};
  final costs = {for (final i in ingredients) i.id: i.costMicro};

  // Enrol the roster before the month starts, spread across the year before it
  // so `joinedAt` is not a wall of identical timestamps — the Keanggotaan
  // report counts sign-ups per window, and forty on one day is a chart nobody
  // learns anything from. A few join *during* the month, which is what makes
  // that count non-zero on a `7d` range.
  final memberIds = <String>[];
  final cfg0 = await memberConfig(db);
  final debtCfg = await debtConfig(db);
  if (cfg0.enabled) {
    for (var i = 0; i < sampleMembers.length; i++) {
      final (name, phone) = sampleMembers[i];
      // The last five sign up inside the fabricated month.
      final joined = i < sampleMembers.length - 5
          ? today.subtract(Duration(days: historyDays + 1 + rng.nextInt(300)))
          : today.subtract(Duration(days: 1 + rng.nextInt(historyDays)));
      try {
        final m = await createMember(
          db,
          name: name,
          phone: phone,
          // A quarter carry a birthday, which is all the birthday filter needs
          // to have something to find.
          birthday: rng.nextDouble() < 0.25
              ? DateTime(
                  1985 + rng.nextInt(20),
                  1 + rng.nextInt(12),
                  1 + rng.nextInt(28),
                )
              : null,
          at: joined,
          idPrefix: samplePrefix,
        );
        memberIds.add(m.id);
      } on MemberException {
        // A venue that already enrolled this number keeps its own member; the
        // seed is additive and never overwrites a real one.
      }
    }
  }

  /// Pick a member with a long tail — the first names in the roster are the
  /// regulars, the last ones came once. Weight `1/(i+1)` is the cheapest shape
  /// that gives a punch card somewhere to fill.
  String? pickMember() {
    if (memberIds.isEmpty) return null;
    if (rng.nextDouble() > memberAttachRate) return null;
    var total = 0.0;
    for (var i = 0; i < memberIds.length; i++) {
      total += 1 / (i + 1);
    }
    var roll = rng.nextDouble() * total;
    for (var i = 0; i < memberIds.length; i++) {
      roll -= 1 / (i + 1);
      if (roll <= 0) return memberIds[i];
    }
    return memberIds.last;
  }

  var planned = 0;
  var landed = 0;

  for (var d = historyDays; d >= 1; d--) {
    // One transaction per seeded day.
    //
    // Every insert below was its own implicit transaction, which on SQLite is
    // its own fsync — roughly 40 bills a day, several rows each, times thirty
    // days. The seed is a blocking first-run dialog, so that cost is paid
    // while an owner watches a spinner on the Venue hub.
    //
    // Per **day** rather than per month: a day is the unit the progress
    // callback already reports, so a batch boundary lines up with something
    // the reader can see, and one transaction holding the whole fabricated
    // month is a lock nothing else in the process can get past. Drift's nested
    // transactions are savepoints, so the writers called inside — submitOrder,
    // the ledger writers, writeAudit — keep wrapping themselves as they do in
    // production, and nothing here changes what they write.
    await db.transaction(() async {
      final day = today.subtract(Duration(days: d));
      // Weekday load shapes the week; the arrival curve shapes the day. A flat
      // curve is the single most obvious tell in a fabricated report.
      final load = weekdayLoad[day.weekday] ?? 1.0;
      final bills = ((34 + rng.nextInt(14)) * load).round();

      // Who is in today, decided before a single order is planned. An absent
      // waiter must take no bills — deriving the shift from orders they should
      // never have taken would put a contradiction in the seeded month.
      final present = {
        for (final id in shiftStaff)
          if (rng.nextDouble() >= _attendanceOf(id).absentRate) id,
      };
      final dayActors = [
        for (final id in actors)
          if (present.contains(id)) id,
      ];
      final todayActors = dayActors.isEmpty ? actors : dayActors;
      // First and last order per person, which is what each shift is bracketed
      // around — a clock-out at 18:00 with a bill at 21:00 is the kind of thing
      // an owner notices the moment they cross-read two sections.
      final firstBy = <String, DateTime>{};
      final lastBy = <String, DateTime>{};

      // Plan the day first so consumption is known before any stock moves —
      // restocks are sized from the sales they cover (ADR-0052 §6), and the
      // production path *rejects* uncovered lines, so under-buying silently
      // shrinks the dataset rather than failing.
      final orders = <_PlannedOrder>[];
      final consumption = <String, int>{};
      for (var b = 0; b < bills; b++) {
        final pax = _weightedInt(rng, partySizeWeights);
        final lines = <_PlannedLine>[];
        for (final entry in courseAttachRate.entries) {
          final pool = byCourse[entry.key];
          if (pool == null || pool.isEmpty) continue;
          // Each cover decides independently, so a four-top orders roughly four
          // mains and a couple of starters rather than a fixed basket size.
          for (var c = 0; c < pax; c++) {
            if (rng.nextDouble() > entry.value) continue;
            final id = _weightedPick(rng, [
              for (final m in pool) m.id,
            ], itemWeights);
            final qty = rng.nextDouble() < multiQtyRate ? 2 : 1;
            lines.add(_PlannedLine(id, entry.key, qty));
            final per = recipes[id]?.resolve() ?? const <String, int>{};
            for (final e in per.entries) {
              consumption[e.key] = (consumption[e.key] ?? 0) + e.value * qty;
            }
          }
        }
        if (lines.isEmpty) continue;
        final hour = _weightedInt(rng, {
          for (final e in arrivalCurve.entries) e.key: e.value,
        });
        orders.add(
          _PlannedOrder(
            pax: pax,
            lines: lines,
            openedAt: DateTime(
              day.year,
              day.month,
              day.day,
              hour,
              rng.nextInt(60),
            ),
          ),
        );
      }

      // Deliveries land before service, sized to cover the day and keep every
      // bahan above its low-stock threshold — balances must never go negative,
      // because `overrideStock` is ungranted by design (ADR-0042 §7).
      for (final e in consumption.entries) {
        final have = balance[e.key] ?? 0;
        final floorQty = lowAt[e.key] ?? 0;
        if (have - e.value >= floorQty) continue;
        final qty = floorQty + e.value * 4 - have;
        await receiveStock(
          db,
          ingredientId: e.key,
          qty: qty,
          unitCostMicro: costs[e.key],
          sourceLabel: 'Pembelian',
          at: DateTime(day.year, day.month, day.day, 8),
          id: nextId('mv'),
        );
        balance[e.key] = have + qty;
      }

      orders.sort((a, b) => a.openedAt.compareTo(b.openedAt));
      for (final o in orders) {
        final table = floor[rng.nextInt(floor.length)];
        final closedAt = o.openedAt.add(
          Duration(minutes: 45 + rng.nextInt(60)),
        );
        final actor = todayActors.isEmpty
            ? null
            : todayActors[rng.nextInt(todayActors.length)];
        if (actor != null) {
          final f = firstBy[actor];
          if (f == null || o.openedAt.isBefore(f)) firstBy[actor] = o.openedAt;
          final l = lastBy[actor];
          if (l == null || closedAt.isAfter(l)) lastBy[actor] = closedAt;
        }

        planned += o.lines.length;
        final res = await submitOrder(
          db,
          tableId: table.id,
          idem: nextId('idem'),
          actorId: actor,
          idPrefix: samplePrefix,
          // The instant this order happened. Passed explicitly rather than by
          // moving the process clock: seeding runs while the app is live, and
          // dragging SatClock through the month would swing the running UI's
          // clock and fire time-based alerts against nonsense times.
          at: o.openedAt,
          lines: [
            for (final l in o.lines)
              {
                'itemId': l.itemId,
                'name': nameOf[l.itemId] ?? l.itemId,
                'course': l.course,
                'qty': l.qty,
                'unitPrice': priceOf[l.itemId] ?? 0,
                'modifiers': const [],
              },
          ],
        );
        landed += res.createdIds.length;
        final visitId = res.visitId;
        if (visitId == null || res.createdIds.isEmpty) continue;

        for (final e in consumptionOf(res.createdRows, recipes).entries) {
          balance[e.key] = (balance[e.key] ?? 0) - e.value;
        }

        // The seed calls `submitOrder` and inserts the settlement directly, so
        // it bypasses every route handler — and every `writeAudit` call site
        // lives in a route handler. None of the trail comes free; the rows a
        // manager would actually go looking for are written here by hand
        // (ADR-0073).
        await writeAudit(
          db,
          type: AuditType.fire,
          kind: AuditKind.fire,
          params: {'course': o.lines.first.course, 'table': table.id},
          tableId: table.id,
          actorUserId: actor,
          at: o.openedAt.add(const Duration(minutes: 2)),
          idPrefix: samplePrefix,
        );

        // The production path leaves lines `sent`; history is served, with a
        // small share voided so the report's void column is never empty.
        for (final t in res.createdRows) {
          final voided = rng.nextDouble() < voidRate;
          await (db.update(db.tickets)..where((x) => x.id.equals(t.id))).write(
            TicketsCompanion(
              status: Value(voided ? 'voided' : 'served'),
              firedAt: Value(t.sentAt),
              readyAt: Value(t.sentAt.add(const Duration(minutes: 12))),
              servedAt: Value(t.sentAt.add(const Duration(minutes: 14))),
              voidReason: Value(voided ? 'Salah input' : null),
            ),
          );
          if (voided) {
            await writeAudit(
              db,
              type: AuditType.voidItem,
              kind: AuditKind.voidItemAtTable,
              params: {'name': t.name, 'table': table.id},
              tableId: table.id,
              actorUserId: actor,
              reason: 'Salah input',
              amountCents: t.price * t.qty,
              at: t.sentAt.add(const Duration(minutes: 6)),
              idPrefix: samplePrefix,
            );
          }
        }

        // A modify on a minority of bills — the row that proves a line changed
        // after it was sent.
        if (rng.nextDouble() < _modifyRate) {
          final t = res.createdRows[rng.nextInt(res.createdRows.length)];
          await writeAudit(
            db,
            type: AuditType.modify,
            kind: AuditKind.modifyAtTable,
            params: {'name': t.name, 'table': table.id},
            tableId: table.id,
            actorUserId: actor,
            reason: 'Permintaan tamu',
            at: t.sentAt.add(const Duration(minutes: 4)),
            idPrefix: samplePrefix,
          );
        }

        final memberId = pickMember();
        await (db.update(db.visits)..where((v) => v.id.equals(visitId))).write(
          VisitsCompanion(
            openedAt: Value(o.openedAt),
            pax: Value(o.pax),
            memberId: Value(memberId),
          ),
        );

        final subtotal = res.createdRows.fold<int>(
          0,
          (a, t) => a + t.price * t.qty,
        );
        final cfg = await _config(db);
        final walkout = rng.nextDouble() < walkoutRate;

        // A redemption on a few member bills. Written the way the till writes
        // one: a ledger row and a bill-scope discount in the `redeem` slot, so
        // the money and the points agree in history exactly as they would live.
        var redeemAmount = 0;
        if (memberId != null &&
            !walkout &&
            rng.nextDouble() < memberRedeemRate) {
          final balance = await memberPoints(db, memberId);
          // Never more than a third of the bill: a redemption that swallows the
          // whole check leaves a zero-rupiah bill in the reports.
          final ceiling = subtotal ~/ 3;
          var points = balance - (balance % cfg0.redeemMin);
          if (cfg0.pointValue > 0 && points * cfg0.pointValue > ceiling) {
            points =
                (ceiling ~/ cfg0.pointValue) -
                ((ceiling ~/ cfg0.pointValue) % cfg0.redeemMin);
          }
          if (points >= cfg0.redeemMin) {
            redeemAmount = await spendPoints(
              db,
              memberId: memberId,
              visitId: visitId,
              points: points,
              actorUserId: actor,
              at: closedAt.subtract(const Duration(minutes: 2)),
              idPrefix: samplePrefix,
            );
            await db
                .into(db.discounts)
                .insert(
                  DiscountsCompanion.insert(
                    id: nextId('dc'),
                    visitId: Value(visitId),
                    name: 'Tukar poin',
                    kind: 'fixed', // rupiah off — anything else reads as bps

                    value: Value(redeemAmount),
                    amount: Value(redeemAmount),
                    source: const Value('redeem'),
                    byUserId: Value(actor),
                    at: closedAt.subtract(const Duration(minutes: 2)),
                  ),
                );
          }
        }

        final breakdown = computeBreakdown(
          subtotal,
          cfg,
          discount: redeemAmount,
        );
        final receiptId = nextId('rc');
        await db
            .into(db.receipts)
            .insert(
              ReceiptsCompanion.insert(
                id: receiptId,
                tableId: table.id,
                visitId: Value(visitId),
                subtotal: Value(subtotal),
                discountAmount: Value(redeemAmount),
                serviceAmount: Value(breakdown.serviceAmount),
                taxAmount: Value(breakdown.taxAmount),
                total: Value(breakdown.total),
                status: Value(walkout ? 'unpaid' : 'paid'),
                createdAt: closedAt,
              ),
            );

        // A discount on a minority of bills, so the discount column and the
        // manager-approval trail are both non-empty.
        if (!walkout && rng.nextDouble() < _discountRate) {
          await writeAudit(
            db,
            type: AuditType.discountApplied,
            kind: AuditKind.discountAtTable,
            params: {'percent': '10', 'table': table.id},
            tableId: table.id,
            actorUserId: actor,
            approvedBy: approver,
            amountCents: (breakdown.total * 0.10).round(),
            at: closedAt.subtract(const Duration(minutes: 3)),
            idPrefix: samplePrefix,
          );
        }

        // A few member bills leave on the tab instead of being paid (ADR-0098).
        // Written through the production writer, so the ledger, the audit row
        // and the payment agree exactly as they would live.
        final onTab =
            memberId != null &&
            !walkout &&
            debtCfg.enabled &&
            rng.nextDouble() < memberTabRate &&
            await memberDebt(db, memberId) + breakdown.total <=
                debtCfg.venueLimit;

        if (!walkout) {
          final method = onTab
              ? 'piutang'
              : const ['cash', 'qris', 'card'][rng.nextInt(3)];
          final paymentId = nextId('pm');
          // A stand-in slip on a few recent non-cash tenders, so the venue log
          // has something to open out of the box. Cash never carries one.
          final withProof =
              method != 'cash' &&
              method != 'piutang' &&
              d <= 7 &&
              proofBudget > 0;
          if (withProof) proofBudget--;
          await db
              .into(db.payments)
              .insert(
                PaymentsCompanion.insert(
                  id: paymentId,
                  receiptId: receiptId,
                  method: method,
                  amount: breakdown.total,
                  cashierUserId: Value(actor),
                  at: closedAt,
                  photo: Value(withProof ? placeholderProofJpeg : null),
                ),
              );
          if (onTab) {
            await chargeDebt(
              db,
              memberId: memberId,
              amount: breakdown.total,
              paymentId: paymentId,
              visitId: visitId,
              billLabel: table.id,
              config: debtCfg,
              actorUserId: actor,
              at: closedAt,
              idPrefix: samplePrefix,
            );
          }
          await writeAudit(
            db,
            type: AuditType.paymentRecorded,
            kind: AuditKind.paymentAtTable,
            params: {'method': method, 'table': table.id},
            tableId: table.id,
            actorUserId: actor,
            amountCents: breakdown.total,
            at: closedAt,
            idPrefix: samplePrefix,
            // Same contract as the live route: set only when there is genuinely
            // an image behind it (ADR-0086).
            paymentId: withProof ? paymentId : null,
          );
        }

        await writeAudit(
          db,
          type: AuditType.billClosed,
          kind: walkout ? AuditKind.billWrittenOff : AuditKind.billClosed,
          params: {
            'table': table.id,
            if (walkout) 'amount': auditRupiah(breakdown.total),
          },
          tableId: table.id,
          actorUserId: actor,
          reason: walkout ? 'Tamu pergi tanpa bayar' : null,
          amountCents: breakdown.total,
          at: closedAt.add(const Duration(seconds: 30)),
          idPrefix: samplePrefix,
        );

        if (memberId != null && !walkout) {
          await earnPointsForVisit(
            db,
            memberId: memberId,
            visitId: visitId,
            base: subtotal - redeemAmount,
            actorUserId: actor,
            at: closedAt.add(const Duration(seconds: 45)),
            idPrefix: samplePrefix,
          );
        }

        final visit = await (db.select(
          db.visits,
        )..where((v) => v.id.equals(visitId))).getSingle();
        await snapshotVisitAndDelete(
          db,
          hub,
          visit,
          closedAt: closedAt,
          sessionId: nextId('s'),
          lossAmount: walkout ? breakdown.total : 0,
        );
        // The table was flipped to `pending` by the production path; the visit
        // is archived, so free it for the next bill.
        await (db.update(
          db.venueTables,
        )..where((t) => t.id.equals(table.id))).write(
          const VenueTablesCompanion(
            status: Value('available'),
            currentVisitId: Value(null),
            openedAt: Value(null),
            openAmount: Value(0),
            moneyState: Value(null),
          ),
        );
      }

      // A weekly stok opname, written as a real session through the same writer
      // the Stok screen uses (ADR-0096). Sunday night, after service: the walk
      // finds a little shrinkage on most shelves and nothing at all on some,
      // which is what makes the document worth reading — a seeded archive where
      // every line is off teaches the reader the wrong reflex.
      if (day.weekday == DateTime.sunday && ingredients.isNotEmpty) {
        final at = DateTime(day.year, day.month, day.day, 22, 30);
        final countId = await openCount(
          db,
          userId: approver,
          // Mostly a shelf or two; every fourth walk is the whole pantry.
          scope: rng.nextInt(4) == 0
              ? StockCountScope.full
              : StockCountScope.partial,
          blind: rng.nextBool(),
          at: at,
          idPrefix: samplePrefix,
        );
        final walk = [...ingredients]..shuffle(rng);
        for (final ing in walk.take(6 + rng.nextInt(6))) {
          final have = balance[ing.id] ?? 0;
          if (have <= 0) continue;
          // Shrinkage runs one way. A surplus happens — a delivery booked short
          // — but it is the rarer finding, and a 50/50 walk reads as noise
          // rather than as a pantry.
          final drift = rng.nextDouble() < 0.45
              ? 0
              : (have * (0.005 + rng.nextDouble() * 0.025)).round() *
                    (rng.nextDouble() < 0.15 ? 1 : -1);
          await recordCountLine(
            db,
            countId: countId,
            ingredientId: ing.id,
            counted: (have + drift).clamp(0, have + drift.abs()),
            at: at,
          );
        }
        final closed = await closeCount(
          db,
          countId: countId,
          closedBy: approver,
          at: at.add(const Duration(minutes: 20)),
          idPrefix: samplePrefix,
        );
        // The session moved stock; the planner's running balance has to follow
        // it, or the next day's delivery is sized against a quantity that no
        // longer exists and the production path rejects lines for want of it.
        for (final e
            in closed?.deltas.entries ?? const <MapEntry<String, int>>[]) {
          balance[e.key] = (balance[e.key] ?? 0) + e.value;
        }
      }
      // Shifts last, once the day's audit rows exist — the opname above writes
      // some of them: `endShift` reads the last auditable thing a shift did, and
      // on a forgotten sign-out that timestamp is the only honest answer to
      // "when did they actually stop".
      await _seedShifts(
        db,
        rng,
        day: day,
        present: present,
        firstBy: firstBy,
        lastBy: lastBy,
        orders: orders,
      );
    });
    onDay?.call(historyDays - d + 1, historyDays);
  }

  // ── settle most of the tabs (ADR-0098) ──
  //
  // Runs after the month rather than inside it: a collection has to land after
  // the charge it pays down, and the day loop walks *backwards*. Most tabs are
  // collected, a few are still owing on the last day, and exactly one is
  // written off — a Piutang section where every state is zero teaches nothing.
  if (debtCfg.enabled && memberIds.isNotEmpty) {
    final owing = await listDebtors(db);
    var wroteOff = false;
    for (final d in owing) {
      if (rng.nextDouble() < tabStillOwingRate) continue;
      // A collection lands somewhere between the oldest charge and today, so
      // the ageing walk has spread rather than one settlement day.
      final from =
          d.oldestUnpaidAt ?? today.subtract(Duration(days: historyDays));
      final span = today.difference(from).inDays;
      final at = from.add(Duration(days: span <= 1 ? 0 : rng.nextInt(span)));
      if (!wroteOff && rng.nextDouble() < 0.25) {
        wroteOff = true;
        await writeOffDebt(
          db,
          memberId: d.memberId,
          amount: d.balance,
          note: 'Nomor tidak aktif',
          actorUserId: approver,
          at: at,
          idPrefix: samplePrefix,
        );
        continue;
      }
      // Part payments on some, so the ledger shows a tab being worked down
      // rather than only ever clearing in one go.
      final amount = rng.nextDouble() < 0.3
          ? (d.balance * 0.5).round().clamp(1, d.balance)
          : d.balance;
      final method = const [
        'tunai',
        'tunai',
        'qris',
        'transfer',
      ][rng.nextInt(4)];
      await payDebt(
        db,
        memberId: d.memberId,
        amount: amount,
        method: method,
        // The photo rule is the live one (ADR-0025), so a seeded non-cash
        // collection has to carry a slip or the writer refuses it.
        photo: method == 'tunai' ? null : placeholderProofJpeg,
        actorUserId: approver,
        at: at,
        idPrefix: samplePrefix,
      );
    }
  }

  // Under-buying makes the production path reject lines, which would shrink
  // the dataset silently. Fail loudly instead (ADR-0053 consequences).
  if (landed < planned * 0.98) {
    throw StateError(
      'sample seed lost lines to stock rejection: $landed of $planned',
    );
  }
}

StaffAttendance _attendanceOf(String id) =>
    staffAttendance[id] ?? defaultAttendance;

/// Write one seeded day's [[Shift]] rows, through `openShift` / `endShift` — the
/// same writer the live path uses, for the same reason the orders above go
/// through `submitOrder`.
///
/// A forgotten sign-out is seeded by simply **not** calling `endShift`. The row
/// stays open, and the next day's `openShift` retires it at its own rollover
/// with `endedBy: rollover`, which is exactly what happens to a handset somebody
/// put down and walked away from. Nothing here fabricates that state directly.
Future<void> _seedShifts(
  AppDatabase db,
  Random rng, {
  required DateTime day,
  required Set<String> present,
  required Map<String, DateTime> firstBy,
  required Map<String, DateTime> lastBy,
  required List<_PlannedOrder> orders,
}) async {
  if (orders.isEmpty) return;
  // The service window, for staff the month attributes no bills to — the
  // kitchen works the same hours without ever appearing as an actor.
  final serviceOpen = orders.first.openedAt;
  final serviceClose = orders.last.openedAt.add(const Duration(minutes: 75));

  int between(int lo, int hi) => lo + rng.nextInt(hi - lo + 1);

  for (final id in present) {
    final a = _attendanceOf(id);
    final firstOrder = firstBy[id] ?? serviceOpen;
    final lastOrder = lastBy[id] ?? serviceClose;
    final start = firstOrder.subtract(
      Duration(minutes: between(a.earlyMin, a.earlyMax)),
    );
    final end = lastOrder.add(
      Duration(minutes: between(closingDownMin, closingDownMax)),
    );
    if (!end.isAfter(start)) continue;

    final forgot = rng.nextDouble() < a.forgetRate;
    final split =
        !forgot &&
        rng.nextDouble() < a.splitRate &&
        end.difference(start).inMinutes > 240;

    if (split) {
      // A handover: the handset changes hands mid-service and comes back. Two
      // rows, one day — which is the whole reason "hari" and "shift" are
      // different columns.
      final total = end.difference(start).inMinutes;
      final gapStart = start.add(
        Duration(minutes: between(total ~/ 3, total ~/ 2)),
      );
      final gap = between(35, 70);
      await openShift(db, id, at: start, idPrefix: samplePrefix);
      await endShift(db, id, at: gapStart);
      await openShift(
        db,
        id,
        at: gapStart.add(Duration(minutes: gap)),
        idPrefix: samplePrefix,
      );
      await endShift(db, id, at: end);
      continue;
    }

    await openShift(db, id, at: start, idPrefix: samplePrefix);
    if (!forgot) await endShift(db, id, at: end);
  }
}

/// Share of bills carrying a `modify` / a `discountApplied` row. Low on
/// purpose: an audit log where every bill was discounted is not an audit log.
const _modifyRate = 0.06;
const _discountRate = 0.04;

/// The admin half of the audit log, which no amount of simulated service will
/// ever produce: staff and role changes, and the manual habis toggle.
///
/// ADR-0072 hides these behind `manageStaff`, and a gate with nothing behind
/// it cannot be seen to work. Scattered across the month at plausible instants
/// so the venue-wide log reads like a venue somebody actually ran.
Future<void> seedAdminAudit(AppDatabase db, Random rng) async {
  final today = SatClock.now();
  final staff = await db.select(db.users).get();
  if (staff.isEmpty) return;
  // By role, not by position: on a venue with no Firebase admin row yet the
  // first two users are the seeded waiter and kitchen, and every "admin did
  // this" line lands on the waiter.
  String? firstWithRole(String roleId) {
    for (final u in staff) {
      if (u.roleId == roleId) return u.id;
    }
    return null;
  }

  final admin = firstWithRole(seed.DummyData.roleAdminId) ?? staff.first.id;
  final waiter = firstWithRole(seed.DummyData.roleWaiterId) ?? admin;

  // (daysAgo, hour, type, kind, params, byAdmin, reason). Structured like every
  // other audit row (ADR-0085) — the seeded month renders in whatever language
  // the reader has set, exactly as a real month would.
  const events =
      <(int, int, AuditType, AuditKind, Map<String, String>, bool, String?)>[
        (
          28,
          9,
          AuditType.staffCreated,
          AuditKind.staffCreated,
          {'name': 'Pelayan 1'},
          true,
          null,
        ),
        (
          28,
          9,
          AuditType.staffPinSet,
          AuditKind.staffPinSet,
          {'name': 'Pelayan 1'},
          true,
          null,
        ),
        (
          27,
          10,
          AuditType.staffCreated,
          AuditKind.staffCreated,
          {'name': 'Dapur 1'},
          true,
          null,
        ),
        (
          27,
          10,
          AuditType.staffPinSet,
          AuditKind.staffPinSet,
          {'name': 'Dapur 1'},
          true,
          null,
        ),
        (
          26,
          9,
          AuditType.staffCreated,
          AuditKind.staffCreated,
          {'name': 'Pelayan 2'},
          true,
          null,
        ),
        (
          26,
          9,
          AuditType.staffPinSet,
          AuditKind.staffPinSet,
          {'name': 'Pelayan 2'},
          true,
          null,
        ),
        (
          25,
          16,
          AuditType.staffCreated,
          AuditKind.staffCreated,
          {'name': 'Dapur 2'},
          true,
          null,
        ),
        (
          25,
          16,
          AuditType.staffPinSet,
          AuditKind.staffPinSet,
          {'name': 'Dapur 2'},
          true,
          null,
        ),
        (
          24,
          11,
          AuditType.roleCapabilityChanged,
          AuditKind.roleCapabilityChanged,
          {'name': 'Waiter', 'changes': '+voidItem'},
          true,
          'Pelayan perlu batalkan sendiri saat jam sibuk',
        ),
        (
          21,
          15,
          AuditType.menuKilled,
          AuditKind.menuKilled,
          {'name': 'Rendang'},
          false,
          'Bahan habis',
        ),
        (
          21,
          20,
          AuditType.menuRestored,
          AuditKind.menuRestored,
          {'name': 'Rendang'},
          false,
          null,
        ),
        (
          18,
          8,
          AuditType.roleRenamed,
          AuditKind.roleRenamed,
          {'from': 'Kitchen', 'to': 'Dapur'},
          true,
          null,
        ),
        (
          16,
          14,
          AuditType.staffPinReset,
          AuditKind.staffPinReset,
          {'name': 'Pelayan 1'},
          true,
          'Staf lupa PIN',
        ),
        (
          13,
          16,
          AuditType.menuKilled,
          AuditKind.menuKilled,
          {'name': 'Bebek Goreng Crispy'},
          false,
          'Stok bebek belum datang',
        ),
        (
          13,
          19,
          AuditType.menuRestored,
          AuditKind.menuRestored,
          {'name': 'Bebek Goreng Crispy'},
          false,
          null,
        ),
        (
          11,
          9,
          AuditType.roleColorChanged,
          AuditKind.roleColorChanged,
          {'name': 'Waiter'},
          true,
          null,
        ),
        (
          9,
          17,
          AuditType.staffDisabled,
          AuditKind.staffDisabled,
          {'name': 'Pelayan 1'},
          true,
          'Cuti dua minggu',
        ),
        (
          7,
          10,
          AuditType.staffEnabled,
          AuditKind.staffEnabled,
          {'name': 'Pelayan 1'},
          true,
          null,
        ),
        (
          5,
          12,
          AuditType.staffRoleChanged,
          AuditKind.staffRoleChanged,
          {'name': 'Pelayan 1', 'from': 'Waiter', 'to': 'Kasir'},
          true,
          'Pindah ke kasir sore',
        ),
        (
          4,
          15,
          AuditType.menuKilled,
          AuditKind.menuKilled,
          {'name': 'Ikan Bakar Jimbaran'},
          false,
          'Ikan tidak segar',
        ),
        (
          4,
          21,
          AuditType.menuRestored,
          AuditKind.menuRestored,
          {'name': 'Ikan Bakar Jimbaran'},
          false,
          null,
        ),
        (
          2,
          11,
          AuditType.roleCreated,
          AuditKind.roleCreated,
          {'name': 'Kasir'},
          true,
          null,
        ),
      ];

  for (final (daysAgo, hour, type, kind, params, byAdmin, reason) in events) {
    final d = today.subtract(Duration(days: daysAgo));
    await writeAudit(
      db,
      type: type,
      kind: kind,
      params: params,
      actorUserId: byAdmin ? admin : waiter,
      reason: reason,
      at: DateTime(d.year, d.month, d.day, hour, rng.nextInt(60)),
      idPrefix: samplePrefix,
    );
  }
}

/// What a batch of created tickets consumed, for the running balance mirror.
Map<String, int> consumptionOf(
  List<Ticket> rows,
  Map<String, ResolvedRecipes> recipes,
) {
  final out = <String, int>{};
  for (final t in rows) {
    final per = recipes[t.itemId]?.resolve() ?? const <String, int>{};
    for (final e in per.entries) {
      out[e.key] = (out[e.key] ?? 0) + e.value * t.qty;
    }
  }
  return out;
}

class _PlannedLine {
  final String itemId;
  final String course;
  final int qty;
  const _PlannedLine(this.itemId, this.course, this.qty);
}

class _PlannedOrder {
  final int pax;
  final List<_PlannedLine> lines;
  final DateTime openedAt;
  const _PlannedOrder({
    required this.pax,
    required this.lines,
    required this.openedAt,
  });
}

// -------------------------------------------------------------- plumbing

/// Repair `stockOnHand` from the ledger. Clearing deletes movement rows, and a
/// balance that no longer equals the sum of its movements is exactly the
/// breakage ADR-0041 exists to prevent — so the balance is always recomputed,
/// never patched.
Future<void> recomputeBalances(AppDatabase db) async {
  final ingredients = await db.select(db.ingredients).get();
  for (final i in ingredients) {
    final rows = await (db.select(
      db.stockMovements,
    )..where((m) => m.ingredientId.equals(i.id))).get();
    final sum = rows.fold<int>(0, (a, m) => a + m.delta);
    if (sum == i.stockOnHand) continue;
    await (db.update(db.ingredients)..where((x) => x.id.equals(i.id))).write(
      IngredientsCompanion(stockOnHand: Value(sum)),
    );
  }
  stockFlags.invalidate();
}

Future<TaxServiceConfig> _config(AppDatabase db) async {
  final s = await (db.select(
    db.venueSettings,
  )..where((t) => t.id.equals('default'))).getSingleOrNull();
  return TaxServiceConfig(
    taxEnabled: s?.taxEnabled ?? false,
    taxRateBps: s?.taxRateBps ?? 1100,
    serviceEnabled: s?.serviceEnabled ?? false,
    serviceMode: s?.serviceMode ?? 'percent',
    serviceRateBps: s?.serviceRateBps ?? 500,
    serviceFixedAmount: s?.serviceFixedAmount ?? 0,
    taxAfterDiscount: s?.taxAfterDiscount ?? true,
  );
}

void _broadcastRefetch(WsHub? hub) {
  if (hub == null) return;
  hub.broadcast('menu.updated', {'seeded': true});
  hub.broadcast('roles.updated', {'seeded': true});
}

class MenuEntry {
  final String id;
  final String name;
  final int price;
  final String course;
  final bool hasRecipe;
  const MenuEntry(this.id, this.name, this.price, this.course, this.hasRecipe);
}

/// Menu rows reduced to what generation needs, with each item mapped onto the
/// course its category implies.
Future<List<MenuEntry>> loadSampleMenu(AppDatabase db) async {
  final items = await (db.select(
    db.menuItems,
  )..where((i) => i.unavailable.equals(false))).get();
  final recipes = await loadRecipes(db);
  return [
    for (final i in items)
      MenuEntry(
        i.id,
        i.name,
        i.basePrice,
        _courseFor(i.categoryId),
        !(recipes[i.id]?.isEmpty ?? true),
      ),
  ];
}

String _courseFor(String categoryId) => switch (categoryId) {
  'cocktails' || 'wine' || 'beer' || 'soft' => 'drinks-now',
  'starters' => 'starters',
  'sides' => 'sides',
  'desserts' => 'desserts',
  _ => 'mains',
};
