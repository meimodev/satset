// The **staff** half of [[Pesan mandiri]] (ADR-0105): the routes a tablet on
// the floor calls to work the queue.
//
// Every route factory takes a non-null `ServerAuth` (ADR-0102), so this signs
// in like a client does. What is pinned here is the split of authority the
// screen leans on:
//
//   - reading the queue is open to either capability, because the waiter who
//     accepts and the owner who curates both live on this screen;
//   - **deciding** an order is `takeOrder` — it is an order, not a setting;
//   - the [[Menu tamu]] write and the code rotation are `editSettings` — what a
//     stranger's phone may see is not the same authority as what is on the menu;
//   - accept-all reports per order, because one failing its stock check must
//     not refuse the other four.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/self_order_routes.dart';
import 'package:satset/server/self_order.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late WsHub hub;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    hub = WsHub();
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            guestOrderingEnabled: const Value(true),
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
          ),
        );
  });

  tearDown(() => db.close());

  Future<GuestOrder> pending() async {
    final session = await openGuestSession(db, tableId: 't1', ttlHours: 4);
    final table = (await tableForGuestCode(db, 'CODE0001'))!;
    return submitGuestOrder(
      db,
      session: session,
      tableId: table.id,
      lines: [
        {'itemId': 'nasgor', 'qty': 1},
      ],
    );
  }

  Future<Response> call(
    TestCaller? caller,
    String method,
    String path, {
    Object? body,
  }) {
    final router = selfOrderRoutes(db, hub, caller?.auth ?? ServerAuth(db, secret: 'test-secret'));
    return router.call(
      Request(
        method,
        Uri.parse('http://x$path'),
        headers: {
          if (caller != null) ...caller.headers,
          'content-type': 'application/json',
        },
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  test('an unsigned caller gets 401, never a queue', () async {
    final res = await call(null, 'GET', '/selforder');
    expect(res.statusCode, 401);
  });

  test('either capability opens the screen', () async {
    for (final caps in [
      {Capability.takeOrder},
      {Capability.editSettings},
    ]) {
      final caller = await signInForTest(
        db,
        caps: caps,
        userId: 'u-${caps.first.name}',
        pin: '${1000 + caps.first.index}',
      );
      final res = await call(caller, 'GET', '/selforder');
      expect(res.statusCode, 200);
      final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
      expect(body.keys, containsAll(['orders', 'stats', 'menu', 'tables']));
      expect((body['tables'] as List).single['code'], 'CODE0001');
    }
  });

  test('the QR host comes from the server, never the caller', () async {
    // The tablet's own client half is paired over loopback, so a URL built
    // client-side prints 127.0.0.1 onto every laminated card. The snapshot
    // carries the address the *server* can be reached on instead.
    final caller = await signInForTest(
      db,
      caps: {Capability.editSettings},
      userId: 'u-host',
      pin: '4321',
    );
    final r = await call(caller, 'GET', '/selforder');
    final body = jsonDecode(await r.readAsString()) as Map<String, dynamic>;
    expect(body.containsKey('host'), isTrue);
    expect(body['guestPort'], 8080);
    expect(body['host'], isNot('127.0.0.1'));
  });

  test('deciding is takeOrder, and editSettings alone will not do', () async {
    final o = await pending();
    final owner = await signInForTest(
      db,
      caps: {Capability.editSettings},
      userId: 'owner',
      pin: '1111',
    );
    final res = await call(owner, 'POST', '/selforder/orders/${o.id}/accept');
    expect(res.statusCode, 403);
    expect(await db.select(db.tickets).get(), isEmpty);

    final waiter = await signInForTest(
      db,
      caps: {Capability.takeOrder},
      userId: 'waiter',
      pin: '2222',
    );
    final ok = await call(waiter, 'POST', '/selforder/orders/${o.id}/accept');
    expect(ok.statusCode, 200);
    expect(await db.select(db.tickets).get(), hasLength(1));
  });

  test('a second accept is a 409, not a second ticket', () async {
    final o = await pending();
    final waiter = await signInForTest(
      db,
      caps: {Capability.takeOrder},
      userId: 'waiter',
      pin: '2222',
    );
    await call(waiter, 'POST', '/selforder/orders/${o.id}/accept');
    final again = await call(
      waiter,
      'POST',
      '/selforder/orders/${o.id}/accept',
    );
    expect(again.statusCode, 409);
    expect(
      jsonDecode(await again.readAsString())['code'],
      'already_decided',
    );
    expect(await db.select(db.tickets).get(), hasLength(1));
  });

  test('reject stores the code it was given', () async {
    final o = await pending();
    final waiter = await signInForTest(
      db,
      caps: {Capability.takeOrder},
      userId: 'waiter',
      pin: '2222',
    );
    final res = await call(
      waiter,
      'POST',
      '/selforder/orders/${o.id}/reject',
      body: {'reasonCode': 'out_of_stock'},
    );
    expect(res.statusCode, 200);
    final row = await (db.select(
      db.guestOrders,
    )..where((x) => x.id.equals(o.id))).getSingle();
    expect(row.status, 'rejected');
    expect(row.rejectReasonCode, 'out_of_stock');
  });

  test('accept-all reports per order', () async {
    await pending();
    await pending();
    final waiter = await signInForTest(
      db,
      caps: {Capability.takeOrder},
      userId: 'waiter',
      pin: '2222',
    );
    final res = await call(waiter, 'POST', '/selforder/orders/accept-all');
    final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
    expect(body['accepted'], 2);
    expect(body['failed'], isEmpty);
  });

  test('menu tamu and code rotation are editSettings', () async {
    final waiter = await signInForTest(
      db,
      caps: {Capability.takeOrder},
      userId: 'waiter',
      pin: '2222',
    );
    expect(
      (await call(
        waiter,
        'PATCH',
        '/selforder/items/nasgor',
        body: {'guestVisible': false},
      )).statusCode,
      403,
    );
    expect(
      (await call(waiter, 'POST', '/selforder/codes/rotate')).statusCode,
      403,
    );

    final owner = await signInForTest(
      db,
      caps: {Capability.editSettings},
      userId: 'owner',
      pin: '1111',
    );
    expect(
      (await call(
        owner,
        'PATCH',
        '/selforder/items/nasgor',
        body: {'guestVisible': false, 'guestStockOverride': 'forceOut'},
      )).statusCode,
      200,
    );
    final item = await (db.select(
      db.menuItems,
    )..where((i) => i.id.equals('nasgor'))).getSingle();
    expect(item.guestVisible, isFalse);
    expect(item.guestStockOverride, 'forceOut');
    // Stamped, so the read side can expire it at the day rollover.
    expect(item.guestOverrideAt, isNotNull);

    final rotated = await call(owner, 'POST', '/selforder/codes/rotate');
    expect(jsonDecode(await rotated.readAsString())['rotated'], 1);
    final t = await (db.select(
      db.venueTables,
    )..where((x) => x.id.equals('t1'))).getSingle();
    expect(t.guestCode, isNot('CODE0001'));
  });

  test('a bogus stock override falls back to auto rather than storing', () async {
    final owner = await signInForTest(
      db,
      caps: {Capability.editSettings},
      userId: 'owner',
      pin: '1111',
    );
    await call(
      owner,
      'PATCH',
      '/selforder/items/nasgor',
      body: {'guestStockOverride': 'whatever'},
    );
    final item = await (db.select(
      db.menuItems,
    )..where((i) => i.id.equals('nasgor'))).getSingle();
    expect(item.guestStockOverride, 'auto');
  });

  // The Menu tamu tab draws a three-way control straight from this field, so
  // what it holds must be the answer the guest page is actually giving — not
  // the answer somebody typed yesterday.
  test('the menu payload carries the EFFECTIVE override, not the stored one', () async {
    final owner = await signInForTest(
      db,
      caps: {Capability.editSettings},
      userId: 'owner',
      pin: '1111',
    );
    await call(
      owner,
      'PATCH',
      '/selforder/items/nasgor',
      body: {'guestStockOverride': 'forceOut'},
    );
    Future<Map<String, dynamic>> row() async {
      final res = await call(owner, 'GET', '/selforder');
      final menu = jsonDecode(await res.readAsString())['menu'] as Map;
      return ((menu['items'] as List).single as Map).cast<String, dynamic>();
    }

    var item = await row();
    expect(item['stockOverride'], 'forceOut');
    expect(item['soldOut'], isTrue);

    // Backdate the stamp past the business-day rollover: a manual "habis"
    // call must not outlive the shift that made it.
    await (db.update(db.menuItems)..where((i) => i.id.equals('nasgor'))).write(
      MenuItemsCompanion(
        guestOverrideAt: Value(DateTime.now().subtract(const Duration(days: 3))),
      ),
    );
    item = await row();
    expect(item['stockOverride'], 'auto');
    expect(item['soldOut'], isFalse);
  });

  test('alcohol is written here and rides the menu payload', () async {
    final owner = await signInForTest(
      db,
      caps: {Capability.editSettings},
      userId: 'owner',
      pin: '1111',
    );
    expect(
      (await call(
        owner,
        'PATCH',
        '/selforder/items/nasgor',
        body: {'alcohol': true},
      )).statusCode,
      200,
    );
    final res = await call(owner, 'GET', '/selforder');
    final menu = jsonDecode(await res.readAsString())['menu'] as Map;
    expect(((menu['items'] as List).single as Map)['alcohol'], isTrue);
  });

  // The queue names whoever decided an order; the guest page must not. Same
  // builder, one flag — so the flag is what gets pinned.
  test('decidedBy is a staff-view field only', () async {
    final o = await pending();
    final waiter = await signInForTest(
      db,
      caps: {Capability.takeOrder},
      userId: 'w1',
      pin: '2222',
    );
    await call(waiter, 'POST', '/selforder/orders/${o.id}/reject', body: {
      'reasonCode': 'closed',
    });
    final saved = await (db.select(
      db.guestOrders,
    )..where((x) => x.id.equals(o.id))).getSingle();

    final staff = await guestOrderJson(db, saved, staffView: true);
    expect(staff['decidedBy'], isNotNull);
    expect(staff['tableLabel'], 'T1');

    final guest = await guestOrderJson(db, saved);
    expect(guest['decidedBy'], isNull);
    expect(guest['tableLabel'], isNull);
    // The guest is still told what happened to their own order.
    expect(guest['status'], 'rejected');
    expect(guest['rejectReasonCode'], 'closed');
  });

  test('per-table opt-in is a write, and an unknown table is a 404', () async {
    final owner = await signInForTest(
      db,
      caps: {Capability.editSettings},
      userId: 'owner',
      pin: '1111',
    );
    expect(
      (await call(
        owner,
        'PATCH',
        '/selforder/tables/t1',
        body: {'enabled': false},
      )).statusCode,
      200,
    );
    expect(await tableForGuestCode(db, 'CODE0001'), isNull);
    expect(
      (await call(
        owner,
        'PATCH',
        '/selforder/tables/nope',
        body: {'enabled': false},
      )).statusCode,
      404,
    );
  });
}
