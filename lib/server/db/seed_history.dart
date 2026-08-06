import 'dart:math';

import 'package:drift/drift.dart';

import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/server/audit_log.dart';
import 'package:satset/server/routes/tables_routes.dart'
    show snapshotVisitAndDelete;
import 'package:satset/server/routes/tickets_routes.dart' show submitOrder;
import 'package:satset/server/stock.dart';
import 'package:satset/server/ws_hub.dart';

import 'database.dart';
import 'seed_data.dart' as seed;
import 'seed_history_mix.dart';

/// Every row the fabricated month writes carries this id prefix. ADR-0073
/// keeps ADR-0052 §4's rule — clearing deletes by tag and never truncates a
/// table — and an id prefix is that tag, at no schema cost.
///
/// A real order taken on a seeded venue afterwards carries no prefix, so it
/// survives the clear that removes everything around it.
const samplePrefix = 'contoh-';

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
    await (db.delete(
      db.receipts,
    )..where((r) => r.id.like('$samplePrefix%'))).go();
    await (db.delete(
      db.tickets,
    )..where((t) => t.id.like('$samplePrefix%'))).go();
    await (db.delete(db.visits)..where((v) => v.id.like('$samplePrefix%'))).go();
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

  final today = DateTime.now();
  var seq = 0;
  String nextId(String kind) => '$samplePrefix$kind-${seq++}';

  final balance = {for (final i in ingredients) i.id: i.stockOnHand};
  final lowAt = {for (final i in ingredients) i.id: i.lowStockAt ?? 0};
  final costs = {for (final i in ingredients) i.id: i.costMicro};

  var planned = 0;
  var landed = 0;

  for (var d = historyDays; d >= 1; d--) {
    final day = today.subtract(Duration(days: d));
    // Weekday load shapes the week; the arrival curve shapes the day. A flat
    // curve is the single most obvious tell in a fabricated report.
    final load = weekdayLoad[day.weekday] ?? 1.0;
    final bills = ((34 + rng.nextInt(14)) * load).round();

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
      final closedAt = o.openedAt.add(Duration(minutes: 45 + rng.nextInt(60)));
      final actor = actors.isEmpty ? null : actors[rng.nextInt(actors.length)];

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
        title:
            'Course ${_courseLabel(o.lines.first.course)} dibakar untuk '
            'Meja ${table.id}',
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
            title: '${t.name} dibatalkan di Meja ${table.id}',
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
          title: '${t.name} diubah di Meja ${table.id}',
          tableId: table.id,
          actorUserId: actor,
          reason: 'Permintaan tamu',
          at: t.sentAt.add(const Duration(minutes: 4)),
          idPrefix: samplePrefix,
        );
      }

      await (db.update(db.visits)..where((v) => v.id.equals(visitId))).write(
        VisitsCompanion(openedAt: Value(o.openedAt), pax: Value(o.pax)),
      );

      final subtotal = res.createdRows.fold<int>(
        0,
        (a, t) => a + t.price * t.qty,
      );
      final cfg = await _config(db);
      final breakdown = computeBreakdown(subtotal, cfg);
      final walkout = rng.nextDouble() < walkoutRate;
      final receiptId = nextId('rc');
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              id: receiptId,
              tableId: table.id,
              visitId: Value(visitId),
              subtotal: Value(subtotal),
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
          title: 'Diskon 10% di Meja ${table.id}',
          tableId: table.id,
          actorUserId: actor,
          approvedBy: approver,
          amountCents: (breakdown.total * 0.10).round(),
          at: closedAt.subtract(const Duration(minutes: 3)),
          idPrefix: samplePrefix,
        );
      }

      if (!walkout) {
        final method = const ['cash', 'qris', 'card'][rng.nextInt(3)];
        await db
            .into(db.payments)
            .insert(
              PaymentsCompanion.insert(
                id: nextId('pm'),
                receiptId: receiptId,
                method: method,
                amount: breakdown.total,
                cashierUserId: Value(actor),
                at: closedAt,
              ),
            );
        await writeAudit(
          db,
          type: AuditType.paymentRecorded,
          title: 'Pembayaran ${_methodLabel(method)} Meja ${table.id}',
          tableId: table.id,
          actorUserId: actor,
          amountCents: breakdown.total,
          at: closedAt,
          idPrefix: samplePrefix,
        );
      }

      await writeAudit(
        db,
        type: AuditType.billClosed,
        title: walkout
            ? 'Tagihan Meja ${table.id} ditutup tak tertagih'
            : 'Tagihan Meja ${table.id} ditutup lunas',
        tableId: table.id,
        actorUserId: actor,
        reason: walkout ? 'Tamu pergi tanpa bayar' : null,
        amountCents: breakdown.total,
        at: closedAt.add(const Duration(seconds: 30)),
        idPrefix: samplePrefix,
      );

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
    onDay?.call(historyDays - d + 1, historyDays);
  }

  // Under-buying makes the production path reject lines, which would shrink
  // the dataset silently. Fail loudly instead (ADR-0053 consequences).
  if (landed < planned * 0.98) {
    throw StateError(
      'sample seed lost lines to stock rejection: $landed of $planned',
    );
  }
}

/// Share of bills carrying a `modify` / a `discountApplied` row. Low on
/// purpose: an audit log where every bill was discounted is not an audit log.
const _modifyRate = 0.06;
const _discountRate = 0.04;

String _courseLabel(String course) => switch (course) {
  'drinks-now' => 'Minuman',
  'starters' => 'Pembuka',
  'sides' => 'Pendamping',
  'desserts' => 'Penutup',
  _ => 'Utama',
};

String _methodLabel(String method) => switch (method) {
  'cash' => 'tunai',
  'qris' => 'QRIS',
  _ => 'kartu',
};

/// The admin half of the audit log, which no amount of simulated service will
/// ever produce: staff and role changes, and the manual habis toggle.
///
/// ADR-0072 hides these behind `manageStaff`, and a gate with nothing behind
/// it cannot be seen to work. Scattered across the month at plausible instants
/// so the venue-wide log reads like a venue somebody actually ran.
Future<void> seedAdminAudit(AppDatabase db, Random rng) async {
  final today = DateTime.now();
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

  const events = <(int, int, AuditType, String, bool, String?)>[
    (28, 9, AuditType.staffCreated, 'Pelayan 1 ditambahkan', true, null),
    (28, 9, AuditType.staffPinSet, 'PIN Pelayan 1 diatur', true, null),
    (27, 10, AuditType.staffCreated, 'Dapur 1 ditambahkan', true, null),
    (27, 10, AuditType.staffPinSet, 'PIN Dapur 1 diatur', true, null),
    (26, 9, AuditType.staffCreated, 'Pelayan 2 ditambahkan', true, null),
    (26, 9, AuditType.staffPinSet, 'PIN Pelayan 2 diatur', true, null),
    (25, 16, AuditType.staffCreated, 'Dapur 2 ditambahkan', true, null),
    (25, 16, AuditType.staffPinSet, 'PIN Dapur 2 diatur', true, null),
    (
      24,
      11,
      AuditType.roleCapabilityChanged,
      'Waiter: izin Batalkan item diberikan',
      true,
      'Pelayan perlu batalkan sendiri saat jam sibuk',
    ),
    (21, 15, AuditType.menuKilled, 'Rendang distop jual', false, 'Bahan habis'),
    (21, 20, AuditType.menuRestored, 'Rendang dijual lagi', false, null),
    (18, 8, AuditType.roleRenamed, 'Peran Kitchen jadi Dapur', true, null),
    (
      16,
      14,
      AuditType.staffPinReset,
      'PIN Pelayan 1 direset',
      true,
      'Staf lupa PIN',
    ),
    (
      13,
      16,
      AuditType.menuKilled,
      'Bebek Goreng Crispy distop jual',
      false,
      'Stok bebek belum datang',
    ),
    (
      13,
      19,
      AuditType.menuRestored,
      'Bebek Goreng Crispy dijual lagi',
      false,
      null,
    ),
    (
      11,
      9,
      AuditType.roleColorChanged,
      'Warna peran Waiter diubah',
      true,
      null,
    ),
    (
      9,
      17,
      AuditType.staffDisabled,
      'Akun Pelayan 1 dinonaktifkan',
      true,
      'Cuti dua minggu',
    ),
    (
      7,
      10,
      AuditType.staffEnabled,
      'Akun Pelayan 1 diaktifkan lagi',
      true,
      null,
    ),
    (
      5,
      12,
      AuditType.staffRoleChanged,
      'Peran Pelayan 1 diubah ke Kasir',
      true,
      'Pindah ke kasir sore',
    ),
    (
      4,
      15,
      AuditType.menuKilled,
      'Ikan Bakar Jimbaran distop jual',
      false,
      'Ikan tidak segar',
    ),
    (
      4,
      21,
      AuditType.menuRestored,
      'Ikan Bakar Jimbaran dijual lagi',
      false,
      null,
    ),
    (2, 11, AuditType.roleCreated, 'Peran Kasir dibuat', true, null),
  ];

  for (final (daysAgo, hour, type, title, byAdmin, reason) in events) {
    final d = today.subtract(Duration(days: daysAgo));
    await writeAudit(
      db,
      type: type,
      title: title,
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
