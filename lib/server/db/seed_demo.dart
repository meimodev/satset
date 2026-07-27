import 'dart:math';
import 'package:satset/server/demo_clock.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'dart:async';
import 'seed_demo_mix.dart';
import 'package:satset/server/routes/tickets_routes.dart' show submitOrder;

import 'package:drift/drift.dart';

import 'package:satset/domain/models/ingredient.dart' show StockReason;
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/server/routes/tables_routes.dart'
    show snapshotVisitAndDelete;
import 'package:satset/server/stock.dart';
import 'package:satset/server/ws_hub.dart';

import 'database.dart';
import 'seed.dart';
import 'seed_data.dart' as seed;

/// Every row the demo seed writes carries this id prefix. ADR-0052 §4 requires
/// demo rows be **tagged** so reset deletes by tag and never truncates a table;
/// an id prefix is that tag, and costs no schema migration.
const demoPrefix = 'demo-';

/// Historical rows (the fabricated month) vs live rows (the mid-service
/// snapshot). ADR-0052 §5: the two halves age differently, so reset regenerates
/// the live half alone by default.
const _histPrefix = '${demoPrefix}h-';
const _livePrefix = '${demoPrefix}l-';

/// Fixed so the dataset is byte-identical run to run — screenshots compare,
/// demo bugs reproduce, goldens stay possible (ADR-0052 §7).
const _rngSeed = 20260727;

const _historyDays = 30;

/// The demo's own zone. Live table states are staged on demo-owned tables so
/// reset deletes them outright and the generically-seeded tables are never
/// mutated. ADR-0052 §8 needs seven table states; eight tables leaves room.
const _demoZoneId = '${demoPrefix}z-teras';

class DemoSeedRefused implements Exception {
  final String reason;
  const DemoSeedRefused(this.reason);
  @override
  String toString() => reason;
}

/// Whether a demo seed may run. ADR-0052 §3: the guard is **any live ticket
/// row or any archived session**.
///
/// Both halves are load-bearing. Closing a bill hard-deletes its tickets into
/// `TableSessions` (ADR-0024), so a venue with a month of genuine trading and
/// no open orders holds zero ticket rows — a ticket-only guard would wave it
/// straight through. Deliberately not "any stock movement": the generic seed
/// already writes one opening `receive` per bahan (ADR-0042 §1), so that
/// predicate would refuse on exactly the freshly-seeded venue this targets.
Future<bool> canSeedDemo(AppDatabase db) async {
  final t = await (db.select(db.tickets)..limit(1)).get();
  if (t.isNotEmpty) return false;
  final s = await (db.select(db.tableSessions)..limit(1)).get();
  return s.isEmpty;
}

/// Whether the venue currently holds demo data (drives the Venue Hub action).
Future<bool> hasDemoData(AppDatabase db) async {
  final s =
      await (db.select(db.tableSessions)
            ..where((x) => x.id.like('$demoPrefix%'))
            ..limit(1))
          .get();
  if (s.isNotEmpty) return true;
  final v =
      await (db.select(db.visits)
            ..where((x) => x.id.like('$demoPrefix%'))
            ..limit(1))
          .get();
  return v.isNotEmpty;
}

/// Seed **a venue mid-service** (ADR-0052): a month of settled history plus a
/// live snapshot staging every state in ADR-0052 §8.
///
/// Runs the generic seed first — the demo builds on that reference data rather
/// than duplicating it. Refuses outright on a venue that has traded.
Future<void> seedDemoVenue(AppDatabase db, {WsHub? hub}) async {
  if (!await canSeedDemo(db)) {
    throw const DemoSeedRefused(
      'Venue sudah punya riwayat pesanan. Demo tidak dimuat.',
    );
  }
  await seedGenericRestaurant(db);

  final rng = Random(_rngSeed);
  final menu = await _loadMenu(db);
  if (menu.isEmpty) return;

  // The anchor is the instant the snapshot is authored to be read at. It is
  // recorded BEFORE generating: an interrupted job must leave a marked,
  // incomplete venue rather than a plausible one (ADR-0053 §9).
  final anchor = DateTime.now();
  await DemoClock.begin(db, anchor: anchor, daysTotal: _historyDays);

  await _seedDemoFloor(db);
  // A detached hub when none is attached (tests, headless seeding): the close
  // path broadcasts per visit, and a month of backdated sessions has no live
  // listener worth notifying anyway.
  await _seedHistory(
    db,
    hub ?? WsHub(),
    rng,
    menu,
    onDay: (done, total) {
      unawaited(DemoClock.progress(db, done));
      hub?.broadcast(WsEventTypes.demoProgress, {
        'daysDone': done,
        'daysTotal': total,
      });
    },
  );
  await seedDemoLive(db, hub: hub, alreadyGuarded: true);

  // Only now is the venue a complete demo. markComplete re-anchors the clock,
  // so every seeded state reads at the age it was authored for.
  await DemoClock.markComplete(db);
  hub?.broadcast(WsEventTypes.demoClock, {
    'offsetSeconds': DemoClock.offsetSeconds(),
  });
}

/// Regenerate the **live half** only (ADR-0052 §5). The month of history is
/// untouched: a twelve-day-old bill is still twelve days old tomorrow, while
/// every live state is computed from `now - timestamp` and reads stale within
/// minutes of seeding.
Future<void> seedDemoLive(
  AppDatabase db, {
  WsHub? hub,
  bool alreadyGuarded = false,
}) async {
  if (!alreadyGuarded) {
    final foreign =
        await (db.select(db.tickets)
              ..where((t) => t.id.like('$demoPrefix%').not())
              ..limit(1))
            .get();
    if (foreign.isNotEmpty) {
      throw const DemoSeedRefused(
        'Ada pesanan sungguhan. Demo tidak dimuat ulang.',
      );
    }
  }
  await _clearLive(db);
  await _seedDemoFloor(db);
  final rng = Random(_rngSeed);
  final menu = await _loadMenu(db);
  if (menu.isNotEmpty) await _seedLive(db, hub, rng, menu);
  await _recomputeBalances(db);
  _broadcastRefetch(hub);
}

/// Remove **every** demo row and return the venue to its generically-seeded
/// state. Deletes strictly by the demo tag — never by truncating a table.
Future<void> resetDemoVenue(AppDatabase db, {WsHub? hub}) async {
  await _clearLive(db);
  await db.transaction(() async {
    final sessions = await (db.select(
      db.tableSessions,
    )..where((s) => s.id.like('$demoPrefix%'))).get();
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
    )..where((m) => m.id.like('$demoPrefix%'))).go();
    await (db.delete(
      db.auditEntries,
    )..where((a) => a.id.like('$demoPrefix%'))).go();
    await (db.delete(
      db.venueTables,
    )..where((t) => t.id.like('$demoPrefix%'))).go();
    await (db.delete(db.zones)..where((z) => z.id.like('$demoPrefix%'))).go();
    // Restore menu availability to what the generic seed authored, rather
    // than blanket-clearing it: some items ship unavailable on purpose, and
    // reset must not quietly make them orderable again.
    for (final it in seed.DummyData.items) {
      await (db.update(db.menuItems)..where((i) => i.id.equals(it.id))).write(
        MenuItemsCompanion(unavailable: Value(it.unavailable)),
      );
    }
  });
  await _recomputeBalances(db);
  stockFlags.invalidate();
  // The clock is bound to the data: no demo data, no demo time (ADR-0053 §4).
  await DemoClock.clear(db);
  hub?.broadcast(WsEventTypes.demoClock, const {'offsetSeconds': 0});
  _broadcastRefetch(hub);
}

// ---------------------------------------------------------------- live rows

/// Delete the live half. Stock balances are repaired by [_recomputeBalances]
/// afterwards rather than by reversing each movement: deleting a `sale` row and
/// leaving `stockOnHand` where it was would break the ADR-0041 invariant that
/// the ledger sums to the balance.
Future<void> _clearLive(AppDatabase db) async {
  await db.transaction(() async {
    final visits = await (db.select(
      db.visits,
    )..where((v) => v.id.like('$demoPrefix%'))).get();
    final vids = visits.map((v) => v.id).toList();
    final receipts = vids.isEmpty
        ? <Receipt>[]
        : await (db.select(
            db.receipts,
          )..where((r) => r.visitId.isIn(vids))).get();
    final rids = receipts.map((r) => r.id).toList();
    if (rids.isNotEmpty) {
      await (db.delete(db.payments)..where((p) => p.receiptId.isIn(rids))).go();
      await (db.delete(
        db.receiptLines,
      )..where((l) => l.receiptId.isIn(rids))).go();
      await (db.delete(
        db.discounts,
      )..where((d) => d.receiptId.isIn(rids))).go();
      await (db.delete(db.receipts)..where((r) => r.id.isIn(rids))).go();
    }
    await (db.delete(db.tickets)..where((t) => t.id.like('$demoPrefix%'))).go();
    if (vids.isNotEmpty) {
      await (db.delete(db.visits)..where((v) => v.id.isIn(vids))).go();
    }
    await (db.delete(
      db.reservations,
    )..where((r) => r.id.like('$demoPrefix%'))).go();
    await (db.delete(
      db.stockMovements,
    )..where((m) => m.id.like('$_livePrefix%'))).go();
    await (db.delete(
      db.venueTables,
    )..where((t) => t.id.like('$demoPrefix%'))).go();
  });
}

/// The demo's own zone + eight tables, one per live state in ADR-0052 §8.
Future<void> _seedDemoFloor(AppDatabase db) async {
  await db
      .into(db.zones)
      .insertOnConflictUpdate(
        ZonesCompanion.insert(
          id: _demoZoneId,
          name: 'Teras',
          short: 'T',
          colorHex: const Value('#5AC8FA'),
          sortOrder: const Value(9),
        ),
      );
  for (var i = 1; i <= 8; i++) {
    await db
        .into(db.venueTables)
        .insertOnConflictUpdate(
          VenueTablesCompanion.insert(
            id: '${demoPrefix}t-$i',
            zoneId: _demoZoneId,
            label: Value('T$i'),
            pax: Value(2 + (i % 3) * 2),
            capacity: Value(4 + (i % 3) * 2),
            status: const Value('available'),
          ),
        );
  }
}

/// The mid-service snapshot. Every timestamp is authored relative to `now`
/// (ADR-0052 §5), so the states read correctly at the moment of seeding.
Future<void> _seedLive(
  AppDatabase db,
  WsHub? hub,
  Random rng,
  List<_MenuEntry> menu,
) async {
  final now = DateTime.now().toUtc();
  final staff = await db.select(db.users).get();
  final waiter = staff.where((u) => u.roleId.contains('waiter')).firstOrNull;
  final waiterId = waiter?.id ?? staff.firstOrNull?.id;
  final recipes = await loadRecipes(db);
  final ingredients = await db.select(db.ingredients).get();
  final names = {for (final i in ingredients) i.id: i.name};
  final running = {for (final i in ingredients) i.id: i.stockOnHand};
  var seq = 0;
  String nextId(String kind) => '$_livePrefix$kind-${seq++}';

  Future<String> openVisit(
    String tableId, {
    required Duration ago,
    int pax = 2,
    String? guestName,
  }) async {
    final openedAt = now.subtract(ago);
    final id = '${_livePrefix}v-$tableId';
    final t = await (db.select(
      db.venueTables,
    )..where((x) => x.id.equals(tableId))).getSingleOrNull();
    await db
        .into(db.visits)
        .insert(
          VisitsCompanion.insert(
            id: id,
            tableId: tableId,
            tableLabel: Value(t?.label),
            zoneId: Value(t?.zoneId ?? _demoZoneId),
            pax: Value(pax),
            openedAt: Value(openedAt),
            guestName: Value(guestName),
            lastActorId: Value(waiterId),
            createdAt: openedAt,
          ),
        );
    await (db.update(db.venueTables)..where((x) => x.id.equals(tableId))).write(
      VenueTablesCompanion(
        status: const Value('occupied'),
        currentVisitId: Value(id),
        openedAt: Value(openedAt),
        pax: Value(pax),
        guestName: Value(guestName),
        lastActorId: Value(waiterId),
      ),
    );
    return id;
  }

  /// One sent line, consumed through the production stock path so the live
  /// half moves balances exactly as a real send would (ADR-0041).
  Future<Ticket> line(
    String visitId,
    String tableId,
    _MenuEntry item, {
    required String status,
    required Duration sentAgo,
    Duration? firedAgo,
    Duration? readyAgo,
    Duration? servedAgo,
    String course = 'mains',
    int qty = 1,
    String? note,
    String? voidReason,
  }) async {
    final id = nextId('tk');
    final sentAt = now.subtract(sentAgo);
    await db
        .into(db.tickets)
        .insert(
          TicketsCompanion.insert(
            id: id,
            tableId: tableId,
            visitId: Value(visitId),
            itemId: item.id,
            name: item.name,
            course: course,
            qty: Value(qty),
            price: item.price,
            status: status,
            sentAt: sentAt,
            note: Value(note),
            firedAt: Value(firedAgo == null ? null : now.subtract(firedAgo)),
            readyAt: Value(readyAgo == null ? null : now.subtract(readyAgo)),
            servedAt: Value(servedAgo == null ? null : now.subtract(servedAgo)),
            voidReason: Value(voidReason),
            createdByUserId: Value(waiterId),
          ),
        );
    if (status != 'voided') {
      final need = await needForLine(
        db,
        itemId: item.id,
        variantName: '',
        optionIds: const [],
        qty: qty,
        recipes: recipes,
        running: running,
        ingredientNames: names,
      );
      for (final e in need.need.entries) {
        await writeMovement(
          db,
          ingredientId: e.key,
          delta: -e.value,
          reason: StockReason.sale,
          ticketId: id,
          sourceLabel: 'Terjual',
          at: sentAt,
          id: nextId('mv'),
        );
      }
    }
    return (await (db.select(
      db.tickets,
    )..where((t) => t.id.equals(id))).getSingle());
  }

  _MenuEntry pick(String course) {
    final pool = menu.where((m) => m.course == course).toList();
    return (pool.isEmpty ? menu : pool)[rng.nextInt(
      (pool.isEmpty ? menu : pool).length,
    )];
  }

  // T1 — kosong. Left untouched by design: the empty state is a state.

  // T2 — terisi, mid-service, one course served and one in prep (KDS: prep).
  final v2 = await openVisit(
    '${demoPrefix}t-2',
    ago: const Duration(minutes: 34),
    pax: 4,
    guestName: 'Pak Andi',
  );
  await line(
    v2,
    '${demoPrefix}t-2',
    pick('drinks-now'),
    status: 'served',
    sentAgo: const Duration(minutes: 32),
    readyAgo: const Duration(minutes: 29),
    servedAgo: const Duration(minutes: 28),
    course: 'drinks-now',
    qty: 2,
  );
  await line(
    v2,
    '${demoPrefix}t-2',
    pick('mains'),
    status: 'prep',
    sentAgo: const Duration(minutes: 9),
    firedAgo: const Duration(minutes: 8),
    qty: 2,
  );

  // T3 — basi / meja lama: open far past longStayMins, nothing moving.
  final v3 = await openVisit(
    '${demoPrefix}t-3',
    ago: const Duration(minutes: 145),
    pax: 2,
  );
  await line(
    v3,
    '${demoPrefix}t-3',
    pick('mains'),
    status: 'served',
    sentAgo: const Duration(minutes: 130),
    readyAgo: const Duration(minutes: 120),
    servedAgo: const Duration(minutes: 118),
  );

  // T4 — belum dilayani (ungreeted): seated, no order past the threshold.
  await openVisit('${demoPrefix}t-4', ago: const Duration(minutes: 16), pax: 3);

  // T5 — menunggu diantar (pickup lag): ready long ago, never served.
  final v5 = await openVisit(
    '${demoPrefix}t-5',
    ago: const Duration(minutes: 41),
    pax: 2,
  );
  await line(
    v5,
    '${demoPrefix}t-5',
    pick('mains'),
    status: 'ready',
    sentAgo: const Duration(minutes: 26),
    firedAgo: const Duration(minutes: 25),
    readyAgo: const Duration(minutes: 11),
  );
  // Overdue in the kitchen — sent well past prepTargetMins, still not ready.
  await line(
    v5,
    '${demoPrefix}t-5',
    pick('starters'),
    status: 'prep',
    sentAgo: const Duration(minutes: 38),
    firedAgo: const Duration(minutes: 37),
    course: 'starters',
  );

  // T6 — locked by another waiter, and carrying a voided line.
  final v6 = await openVisit(
    '${demoPrefix}t-6',
    ago: const Duration(minutes: 22),
    pax: 5,
    guestName: 'Bu Sri',
  );
  await line(
    v6,
    '${demoPrefix}t-6',
    pick('mains'),
    status: 'sent',
    sentAgo: const Duration(minutes: 4),
    qty: 3,
  );
  await line(
    v6,
    '${demoPrefix}t-6',
    pick('sides'),
    status: 'voided',
    sentAgo: const Duration(minutes: 12),
    course: 'sides',
    voidReason: 'Salah input',
  );
  final other = staff.where((u) => u.id != waiterId).firstOrNull;
  await (db.update(
    db.venueTables,
  )..where((t) => t.id.equals('${demoPrefix}t-6'))).write(
    VenueTablesCompanion(
      lockedBy: Value(other?.id ?? 'demo-user'),
      lockedByName: Value(other?.name ?? 'Rina'),
      lockedAt: Value(now.subtract(const Duration(minutes: 2))),
      // Outlives the rest of the live half deliberately: a real lock
      // expires in minutes, but one that dies before the snapshot around
      // it means the locked state is gone the first time anyone looks.
      lockExpiresAt: Value(now.add(const Duration(minutes: 45))),
    ),
  );

  // T7 — dipesan (held for a booking) + reservasi berikutnya on T8.
  final resSoon = '${_livePrefix}res-1';
  await db
      .into(db.reservations)
      .insert(
        ReservationsCompanion.insert(
          id: resSoon,
          name: 'Keluarga Wijaya',
          phone: const Value('0812-1111-2222'),
          partySize: const Value(6),
          expectedAt: now.add(const Duration(minutes: 25)),
          status: const Value('pending'),
          zoneId: const Value(_demoZoneId),
          tableId: Value('${demoPrefix}t-7'),
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
      );
  await (db.update(
    db.venueTables,
  )..where((t) => t.id.equals('${demoPrefix}t-7'))).write(
    VenueTablesCompanion(
      status: const Value('reserved'),
      reservationId: Value(resSoon),
    ),
  );

  // Terlambat — a booking past its grace window, still unseated.
  await db
      .into(db.reservations)
      .insert(
        ReservationsCompanion.insert(
          id: '${_livePrefix}res-2',
          name: 'Pak Hendra',
          phone: const Value('0813-3333-4444'),
          partySize: const Value(2),
          expectedAt: now.subtract(const Duration(minutes: 35)),
          status: const Value('pending'),
          zoneId: const Value(_demoZoneId),
          tableId: Value('${demoPrefix}t-8'),
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
      );
  // …and a later booking so T8 also shows "reservasi berikutnya".
  await db
      .into(db.reservations)
      .insert(
        ReservationsCompanion.insert(
          id: '${_livePrefix}res-3',
          name: 'Ibu Maya',
          partySize: const Value(4),
          expectedAt: now.add(const Duration(hours: 2)),
          status: const Value('pending'),
          zoneId: const Value(_demoZoneId),
          tableId: Value('${demoPrefix}t-8'),
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
      );

  // T1 — a settled-but-still-seated bill (money paid, table not yet freed),
  // plus a split: two receipts against one visit.
  final v1 = await openVisit(
    '${demoPrefix}t-1',
    ago: const Duration(minutes: 72),
    pax: 4,
  );
  final paidLines = <Ticket>[
    await line(
      v1,
      '${demoPrefix}t-1',
      pick('mains'),
      status: 'served',
      sentAgo: const Duration(minutes: 62),
      readyAgo: const Duration(minutes: 50),
      servedAgo: const Duration(minutes: 48),
      qty: 2,
    ),
    await line(
      v1,
      '${demoPrefix}t-1',
      pick('drinks-now'),
      status: 'served',
      sentAgo: const Duration(minutes: 60),
      readyAgo: const Duration(minutes: 57),
      servedAgo: const Duration(minutes: 56),
      course: 'drinks-now',
      qty: 2,
    ),
  ];
  final cfg = await _config(db);
  var half = 0;
  for (final t in paidLines) {
    final rid = nextId('rc');
    final sub = t.price * t.qty;
    final b = computeBreakdown(sub, cfg);
    await db
        .into(db.receipts)
        .insert(
          ReceiptsCompanion.insert(
            id: rid,
            tableId: '${demoPrefix}t-1',
            visitId: Value(v1),
            mode: const Value('split'),
            label: Value('Tamu ${++half}'),
            subtotal: Value(sub),
            serviceAmount: Value(b.serviceAmount),
            taxAmount: Value(b.taxAmount),
            total: Value(b.total),
            status: const Value('paid'),
            createdAt: now.subtract(const Duration(minutes: 6)),
          ),
        );
    await db
        .into(db.receiptLines)
        .insert(
          ReceiptLinesCompanion.insert(
            id: nextId('rl'),
            receiptId: rid,
            ticketId: t.id,
            qtyUnits: Value(t.qty),
          ),
        );
    await db
        .into(db.payments)
        .insert(
          PaymentsCompanion.insert(
            id: nextId('pm'),
            receiptId: rid,
            method: half == 1 ? 'cash' : 'qris',
            amount: b.total,
            cashierUserId: Value(waiterId),
            at: now.subtract(const Duration(minutes: 5)),
          ),
        );
  }
  await (db.update(db.venueTables)
        ..where((t) => t.id.equals('${demoPrefix}t-1')))
      .write(const VenueTablesCompanion(moneyState: Value('paid')));

  // Menu states: one hand-marked unavailable, and one driven habis by stock.
  final flagged = menu.firstWhere((m) => m.hasRecipe, orElse: () => menu.first);
  final manual = menu.firstWhere(
    (m) => m.id != flagged.id,
    orElse: () => menu.first,
  );
  await (db.update(db.menuItems)..where((i) => i.id.equals(manual.id))).write(
    const MenuItemsCompanion(unavailable: Value(true)),
  );
  final drained = recipes[flagged.id]?.resolve().keys.firstOrNull;
  if (drained != null) {
    final ing = await (db.select(
      db.ingredients,
    )..where((i) => i.id.equals(drained))).getSingleOrNull();
    if (ing != null && ing.stockOnHand > 0) {
      await writeMovement(
        db,
        ingredientId: drained,
        delta: -ing.stockOnHand,
        reason: StockReason.waste,
        sourceLabel: 'Terbuang',
        note: 'Rusak saat penyimpanan',
        at: now.subtract(const Duration(hours: 2)),
        id: nextId('mv'),
      );
    }
  }
  stockFlags.invalidate();
}

// ------------------------------------------------------------ history rows

/// A month of settled service, archived through the production close path
/// ([snapshotVisitAndDelete]) so the money arithmetic is never duplicated here.
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
/// The clock is walked backwards through the month while generating: rather
/// than special-casing every timestamp, the seed adopts each bill's instant as
/// the app clock, so the production code stamps `sentAt`, movement `at` and
/// everything else correctly without knowing it is being replayed.
Future<void> _seedHistory(
  AppDatabase db,
  WsHub hub,
  Random rng,
  List<_MenuEntry> menu, {
  void Function(int day, int total)? onDay,
}) async {
  final tables = await db.select(db.venueTables).get();
  final floor = tables.where((t) => !t.id.startsWith(demoPrefix)).toList();
  if (floor.isEmpty) return;
  final staff = await db.select(db.users).get();
  final cashiers = staff.map((u) => u.id).toList();
  final recipes = await loadRecipes(db);
  final ingredients = await db.select(db.ingredients).get();

  final byCourse = <String, List<_MenuEntry>>{};
  for (final m in menu) {
    (byCourse[m.course] ??= []).add(m);
  }
  final priceOf = {for (final m in menu) m.id: m.price};
  final nameOf = {for (final m in menu) m.id: m.name};

  final today = DateTime.now();
  var seq = 0;
  String nextId(String kind) => '$_histPrefix$kind-${seq++}';

  final balance = {for (final i in ingredients) i.id: i.stockOnHand};
  final lowAt = {for (final i in ingredients) i.id: i.lowStockAt ?? 0};
  final costs = {for (final i in ingredients) i.id: i.costMicro};

  var planned = 0;
  var landed = 0;

  for (var d = _historyDays; d >= 1; d--) {
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
      final actor = cashiers.isEmpty
          ? null
          : cashiers[rng.nextInt(cashiers.length)];

      planned += o.lines.length;
      final res = await submitOrder(
        db,
        tableId: table.id,
        idem: nextId('idem'),
        actorId: actor,
        idPrefix: _histPrefix,
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
      if (!walkout) {
        await db
            .into(db.payments)
            .insert(
              PaymentsCompanion.insert(
                id: nextId('pm'),
                receiptId: receiptId,
                method: const ['cash', 'qris', 'card'][rng.nextInt(3)],
                amount: breakdown.total,
                cashierUserId: Value(actor),
                at: closedAt,
              ),
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
    onDay?.call(_historyDays - d + 1, _historyDays);
  }

  // Under-buying makes the production path reject lines, which would shrink
  // the dataset silently. Fail loudly instead (ADR-0053 consequences).
  if (landed < planned * 0.98) {
    throw StateError(
      'demo seed lost lines to stock rejection: $landed of $planned',
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

/// Repair `stockOnHand` from the ledger. Reset deletes movement rows, and a
/// balance that no longer equals the sum of its movements is exactly the
/// breakage ADR-0041 exists to prevent — so the balance is always recomputed,
/// never patched.
Future<void> _recomputeBalances(AppDatabase db) async {
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
  hub.broadcast('menu.updated', {'demo': true});
  hub.broadcast('roles.updated', {'demo': true});
}

class _MenuEntry {
  final String id;
  final String name;
  final int price;
  final String course;
  final bool hasRecipe;
  const _MenuEntry(this.id, this.name, this.price, this.course, this.hasRecipe);
}

/// Menu rows reduced to what generation needs, with each item mapped onto the
/// course its category implies.
Future<List<_MenuEntry>> _loadMenu(AppDatabase db) async {
  final items = await (db.select(
    db.menuItems,
  )..where((i) => i.unavailable.equals(false))).get();
  final recipes = await loadRecipes(db);
  return [
    for (final i in items)
      _MenuEntry(
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
