// [[Pesan mandiri]] end to end at the writer level (ADR-0105), against an
// in-memory database and the real `lib/server/self_order.dart`.
//
// What is actually being pinned:
//
//   - the guest is untrusted, so the **server** prices the order — a phone that
//     posts its own `unitPrice` is ignored, and a variant/option it did not pay
//     for is added by the menu, not by the payload;
//   - a code is the whole credential, and a table opted out of self-order has a
//     code that resolves to nothing (so does an unknown one — indistinguishably);
//   - a session is bound to a *sitting*, not to a table: reopening the table or
//     closing its bill makes an old phone's session stale without a column;
//   - a decision is once — a second Terima on a second tablet cannot fire the
//     food twice;
//   - accept goes through the ordinary `submitOrder`, so the lines land on the
//     ordinary ticket and the intent keeps the ids.
//
// See docs/adr/0105-guest-self-order-returns-as-an-intent-not-a-ticket.md.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/self_order.dart';
import 'package:satset/server/ws_hub.dart';

/// Records what the room was told. `submitOrder` only writes, so an accept that
/// forgets to fan out leaves a ticket in the DB and nothing on the KDS.
class _RecordingHub extends WsHub {
  final types = <String>[];
  @override
  void broadcast(String type, Map<String, dynamic> payload) =>
      types.add(type);
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            guestOrderingEnabled: const Value(true),
            guestMaxItems: const Value(3),
            guestSessionHours: const Value(4),
          ),
        );
    await db
        .into(db.venueTables)
        .insertOnConflictUpdate(
          VenueTablesCompanion.insert(
            id: 't1',
            zoneId: 'z1',
            label: const Value('T1'),
            guestCode: const Value('CODE0001'),
          ),
        );
    await db
        .into(db.menuItems)
        .insertOnConflictUpdate(
          MenuItemsCompanion.insert(
            id: 'nasgor',
            name: 'Nasi Goreng',
            categoryId: 'mains',
            basePrice: 25000,
            variantsJson: Value(
              jsonEncode([
                {'id': 'v-s', 'name': 'Sedang', 'price': 25000},
                {'id': 'v-l', 'name': 'Besar', 'price': 32000},
              ]),
            ),
            modifierGroupsJson: Value(
              jsonEncode([
                {
                  'id': 'g-telur',
                  'name': 'Telur',
                  'required': false,
                  'multi': false,
                  'options': [
                    {'id': 'o-mata', 'name': 'Mata sapi', 'priceDelta': 5000},
                    {'id': 'o-dadar', 'name': 'Dadar', 'priceDelta': 5000},
                  ],
                },
              ]),
            ),
          ),
        );
  });

  tearDown(() async {
    SatClock.clear();
    await db.close();
  });

  Future<GuestSession> open() async =>
      openGuestSession(db, tableId: 't1', ttlHours: 4);

  Future<VenueTable> tbl() async =>
      (await tableForGuestCode(db, 'CODE0001'))!;

  // -------------------------------------------------------------------------
  // codes
  // -------------------------------------------------------------------------

  test('an unknown code and an opted-out table are the same 404', () async {
    expect(await tableForGuestCode(db, 'NOPE'), isNull);
    expect(await tableForGuestCode(db, ''), isNull);
    await (db.update(db.venueTables)..where((t) => t.id.equals('t1'))).write(
      const VenueTablesCompanion(guestOrderingEnabled: Value(false)),
    );
    expect(await tableForGuestCode(db, 'CODE0001'), isNull);
  });

  test('minting fills blanks only — a printed QR survives a re-seed', () async {
    await db
        .into(db.venueTables)
        .insert(VenueTablesCompanion.insert(id: 't2', zoneId: 'z1'));
    await mintMissingGuestCodes(db);
    final rows = await db.select(db.venueTables).get();
    final t1 = rows.firstWhere((t) => t.id == 't1');
    final t2 = rows.firstWhere((t) => t.id == 't2');
    expect(t1.guestCode, 'CODE0001', reason: 'an existing code is untouched');
    expect(t2.guestCode, hasLength(8));

    // Rotation is the deliberate act that kills every printed QR.
    await rotateGuestCodes(db);
    final after = await (db.select(
      db.venueTables,
    )..where((t) => t.id.equals('t1'))).getSingle();
    expect(after.guestCode, isNot('CODE0001'));
  });

  // -------------------------------------------------------------------------
  // service hours
  // -------------------------------------------------------------------------

  test('a window that wraps midnight is a window', () async {
    const noWindow = (
      enabled: true,
      noteEnabled: true,
      hoursStartMin: 0,
      hoursEndMin: 0,
      maxItems: 20,
      sessionHours: 4,
      dayStartHour: 4,
    );
    expect(withinServiceHours(noWindow, DateTime(2026, 1, 1, 3)), isTrue);

    // 22:00 → 02:00
    const night = (
      enabled: true,
      noteEnabled: true,
      hoursStartMin: 22 * 60,
      hoursEndMin: 2 * 60,
      maxItems: 20,
      sessionHours: 4,
      dayStartHour: 4,
    );
    expect(withinServiceHours(night, DateTime(2026, 1, 1, 23)), isTrue);
    expect(withinServiceHours(night, DateTime(2026, 1, 1, 1)), isTrue);
    expect(withinServiceHours(night, DateTime(2026, 1, 1, 12)), isFalse);
  });

  // -------------------------------------------------------------------------
  // sessions
  // -------------------------------------------------------------------------

  test('a session dies with the sitting, not with the table', () async {
    final s = await open();
    expect(await liveGuestSession(db, s.id), isNotNull);

    // The table is freed and reused: the phone on the windowsill loses.
    await (db.update(db.venueTables)..where((t) => t.id.equals('t1'))).write(
      VenueTablesCompanion(openedAt: Value(s.startedAt.add(const Duration(minutes: 1)))),
    );
    expect(await liveGuestSession(db, s.id), isNull);
  });

  test('a closed bill is frozen, so the phone cannot add to it', () async {
    final s = await open();
    await (db.update(db.venueTables)..where((t) => t.id.equals('t1'))).write(
      VenueTablesCompanion(
        billClosedAt: Value(s.startedAt.add(const Duration(minutes: 1))),
      ),
    );
    expect(await liveGuestSession(db, s.id), isNull);
  });

  test('an expired session is not live', () async {
    final s = await open();
    SatClock.adopt(const Duration(hours: 5));
    expect(await liveGuestSession(db, s.id), isNull);
  });

  // -------------------------------------------------------------------------
  // pricing — the trust boundary
  // -------------------------------------------------------------------------

  test('the server prices the order; the phone is not asked', () async {
    final order = await submitGuestOrder(
      db,
      session: await open(),
      tableId: (await tbl()).id,
      lines: [
        {
          'itemId': 'nasgor',
          'variantId': 'v-l',
          'optionIds': ['o-mata'],
          'qty': 2,
          // The lie. Ignored: nothing reads a price off the wire.
          'unitPrice': 1,
          'subtotal': 2,
        },
      ],
    );
    final lines = await (db.select(
      db.guestOrderLines,
    )..where((l) => l.orderId.equals(order.id))).get();
    expect(lines, hasLength(1));
    // 32000 (variant is absolute) + 5000 (option adds).
    expect(lines.single.unitPrice, 37000);
    expect(lines.single.variantName, 'Besar');
    expect(order.subtotal, 74000);
  });

  test('an unknown option is simply not applied', () async {
    final order = await submitGuestOrder(
      db,
      session: await open(),
      tableId: (await tbl()).id,
      lines: [
        {
          'itemId': 'nasgor',
          'optionIds': ['o-does-not-exist'],
          'qty': 1,
        },
      ],
    );
    final line = await (db.select(
      db.guestOrderLines,
    )..where((l) => l.orderId.equals(order.id))).getSingle();
    expect(line.unitPrice, 25000);
    expect(jsonDecode(line.modifiersJson), isEmpty);
  });

  test('an item hidden from the guest menu cannot be ordered', () async {
    await (db.update(db.menuItems)..where((i) => i.id.equals('nasgor'))).write(
      const MenuItemsCompanion(guestVisible: Value(false)),
    );
    final s = await open();
    final t = await tbl();
    expect(
      () => submitGuestOrder(
        db,
        session: s,
        tableId: t.id,
        lines: [
          {'itemId': 'nasgor', 'qty': 1},
        ],
      ),
      throwsA(
        isA<SelfOrderException>().having((e) => e.code, 'code', 'item_unavailable'),
      ),
    );
  });

  test('the rules refuse an empty, oversized or out-of-hours order', () async {
    final s = await open();
    final t = await tbl();
    Future<void> submit(List<Map<String, dynamic>> lines) =>
        submitGuestOrder(db, session: s, tableId: t.id, lines: lines);

    expect(
      () => submit(const []),
      throwsA(isA<SelfOrderException>().having((e) => e.code, 'code', 'empty_order')),
    );
    expect(
      () => submit([
        for (var i = 0; i < 4; i++) {'itemId': 'nasgor', 'qty': 1},
      ]),
      throwsA(
        isA<SelfOrderException>().having((e) => e.code, 'code', 'too_many_items'),
      ),
    );

    await (db.update(db.venueSettings)..where((x) => x.id.equals('default')))
        .write(const VenueSettingsCompanion(guestOrderingEnabled: Value(false)));
    expect(
      () => submit([
        {'itemId': 'nasgor', 'qty': 1},
      ]),
      throwsA(
        isA<SelfOrderException>().having((e) => e.code, 'code', 'self_order_off'),
      ),
    );
  });

  test('a required modifier group is required', () async {
    await (db.update(db.menuItems)..where((i) => i.id.equals('nasgor'))).write(
      MenuItemsCompanion(
        modifierGroupsJson: Value(
          jsonEncode([
            {
              'id': 'g-pedas',
              'name': 'Level pedas',
              'required': true,
              'multi': false,
              'options': [
                {'id': 'o-1', 'name': '1', 'priceDelta': 0},
              ],
            },
          ]),
        ),
      ),
    );
    final s = await open();
    final t = await tbl();
    expect(
      () => submitGuestOrder(
        db,
        session: s,
        tableId: t.id,
        lines: [
          {'itemId': 'nasgor', 'qty': 1},
        ],
      ),
      throwsA(
        isA<SelfOrderException>().having((e) => e.code, 'code', 'modifier_required'),
      ),
    );
  });

  // -------------------------------------------------------------------------
  // deciding
  // -------------------------------------------------------------------------

  Future<GuestOrder> pending() async => submitGuestOrder(
    db,
    session: await open(),
    tableId: (await tbl()).id,
    lines: [
      {'itemId': 'nasgor', 'qty': 1},
    ],
  );

  test('a hidden item stays visible to staff, or it can never come back',
      () async {
    await (db.update(db.menuItems)..where((i) => i.id.equals('nasgor'))).write(
      const MenuItemsCompanion(guestVisible: Value(false)),
    );
    final guest = await guestMenuJson(db);
    expect(
      [for (final i in guest['items'] as List) (i as Map)['id']],
      isNot(contains('nasgor')),
    );
    final staff = await guestMenuJson(db, includeHidden: true);
    final row = (staff['items'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((i) => i['id'] == 'nasgor');
    expect(row['visible'], isFalse);
  });

  test('the chip row lists only categories that hold something', () async {
    // `all` is the staff menu's all-items tab, filed under by nothing. Emitted
    // to the guest it drew a second "Semua" beside the page's own chip and
    // filtered the menu to empty.
    for (final c in const [
      ('all', 'Semua'),
      ('mains', 'Utama'),
      ('desserts', 'Penutup'),
    ]) {
      await db
          .into(db.menuCategories)
          .insertOnConflictUpdate(
            MenuCategoriesCompanion.insert(id: c.$1, name: c.$2),
          );
    }
    final cats = [
      for (final c in (await guestMenuJson(db))['categories'] as List)
        (c as Map)['id'],
    ];
    expect(cats, ['mains']);
  });

  test('accept goes through the ordinary order path', () async {
    final o = await pending();
    final res = await acceptGuestOrder(db, orderId: o.id, actorId: 'u1');
    expect(res.order.status, 'accepted');
    expect(res.order.decidedByUserId, 'u1');
    expect(jsonDecode(res.order.ticketIdsJson), isNotEmpty);

    // Ordinary tickets, on the ordinary table, with the ordinary visit.
    final tickets = await db.select(db.tickets).get();
    expect(tickets, hasLength(1));
    expect(tickets.single.tableId, 't1');
    expect(res.order.visitId, isNotNull);

    // And an audit row, of the one new type.
    final audit = await db.select(db.auditEntries).get();
    expect(audit.map((a) => a.kind), contains('guestOrderAccepted'));
  });

  test('a guest who seats the table keeps their own session', () async {
    // The whole of the ordinary case: an empty table, a scan, an order, and an
    // accept that opens the sitting. The session must survive the opening it
    // caused, or "Pesanan saya" 401s the second staff press Terima.
    final o = await pending();
    await acceptGuestOrder(db, orderId: o.id, actorId: 'u1');
    final seated = await (db.select(
      db.venueTables,
    )..where((t) => t.id.equals('t1'))).getSingle();
    expect(seated.openedAt, isNotNull);
    expect(seated.currentVisitId, isNotNull);
    expect(await liveGuestSession(db, o.sessionId), isNotNull);

    // A different party on the same table is still fatal: the reuse test asks
    // the visit, so a fresh one with no accepted order of this session's ends it.
    final sess = await (db.select(
      db.guestSessions,
    )..where((x) => x.id.equals(o.sessionId))).getSingle();
    await (db.update(db.venueTables)..where((t) => t.id.equals('t1'))).write(
      VenueTablesCompanion(
        openedAt: Value(sess.startedAt.add(const Duration(minutes: 1))),
        currentVisitId: const Value('another-party'),
      ),
    );
    expect(await liveGuestSession(db, o.sessionId), isNull);
  });

  test('accept tells the room, not just the queue', () async {
    final o = await pending();
    final hub = _RecordingHub();
    await acceptGuestOrder(db, orderId: o.id, actorId: 'u1', hub: hub);
    // The KDS, the floor and the queue each have to hear; a `guestOrderDecided`
    // on its own is a ticket nobody can see.
    expect(hub.types, contains('ticket.created'));
    expect(hub.types, contains('table.updated'));
    expect(hub.types, contains('guestOrder.decided'));
  });

  test('a decision is once — the second tablet loses', () async {
    final o = await pending();
    await acceptGuestOrder(db, orderId: o.id, actorId: 'u1');
    expect(
      () => acceptGuestOrder(db, orderId: o.id, actorId: 'u2'),
      throwsA(isA<SelfOrderException>().having((e) => e.code, 'code', 'already_decided')),
    );
    expect(await db.select(db.tickets).get(), hasLength(1));
  });

  test('reject carries a code, never a sentence', () async {
    final o = await pending();
    final r = await rejectGuestOrder(
      db,
      orderId: o.id,
      actorId: 'u1',
      reasonCode: 'out_of_stock',
    );
    expect(r.status, 'rejected');
    expect(r.rejectReasonCode, 'out_of_stock');
    expect(await db.select(db.tickets).get(), isEmpty);
  });

  test('a guest may cancel while pending, and not after', () async {
    final o = await pending();
    final c = await cancelGuestOrder(db, orderId: o.id, sessionId: o.sessionId);
    expect(c.status, 'cancelled');
    expect(
      () => acceptGuestOrder(db, orderId: o.id, actorId: 'u1'),
      throwsA(isA<SelfOrderException>().having((e) => e.code, 'code', 'already_decided')),
    );
  });
}
