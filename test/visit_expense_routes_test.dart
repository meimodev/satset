// The [[Pengeluaran kunjungan]] routes (ADR-0130).
//
// Every route factory takes a non-null `ServerAuth` (ADR-0102), so this signs in
// like a client does. What is pinned here is the shape of the gate and the
// split of authority:
//
//   - the gate is **two facts** — the owner's switch and the fail-closed mode
//     key — and either one missing answers **404**, not 403: a client must not
//     be able to tell an unentitled venue from an old server;
//   - **recording** is `recordTableExpense` and nothing else — not `manageCash`,
//     which opens a box this feature never touches;
//   - **reading** is open to whoever settles, records or reports, because the
//     cashier has to see what the visit cost before closing it;
//   - the **photo** is a `viewReports` read, where the other proofs live;
//   - the cap's numbers ride the refusal, so a sheet can say what is left;
//   - a repeated POST under one id writes one row — the router is wrapped in
//     `idempotent()` where it is mounted, and the id is the key.
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/visit_expense_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late WsHub hub;
  final photo64 = base64Encode(Uint8List.fromList([1, 2, 3]));

  /// The venue holds the key *and* the owner said yes. Either half missing is
  /// its own test below.
  Future<void> settings({bool owner = true, bool entitled = true}) => db
      .into(db.venueSettings)
      .insertOnConflictUpdate(
        VenueSettingsCompanion.insert(
          id: 'default',
          tableExpenseEnabled: Value(owner),
          modules: Value(entitled ? modeTableExpense : ''),
        ),
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    hub = WsHub();
    await settings();
    await db
        .into(db.visits)
        .insert(
          VisitsCompanion.insert(
            id: 'v1',
            tableId: 't1',
            tableLabel: const Value('Meja 7'),
            createdAt: DateTime.now(),
          ),
        );
    await db
        .into(db.tickets)
        .insert(
          TicketsCompanion.insert(
            id: 'tk1',
            tableId: 't1',
            visitId: const Value('v1'),
            itemId: 'i1',
            name: 'Nasi goreng',
            course: 'mains',
            price: 50000,
            status: 'served',
            sentAt: DateTime.now(),
          ),
        );
  });
  tearDown(() => db.close());

  Future<Response> call(
    TestCaller? caller,
    String method,
    String path, {
    Object? body,
  }) {
    final router = visitExpenseRoutes(
      db,
      hub,
      caller?.auth ?? ServerAuth(db, secret: 'test-secret'),
    );
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

  Object expenseBody({
    String id = 'e1',
    int amount = 20000,
    String category = 'vexc-other',
    Object? photo,
  }) => {
    'id': id,
    'amount': amount,
    'categoryId': category,
    'photoBase64': photo ?? photo64,
  };

  group('the gate', () {
    test('an unsigned caller gets 401', () async {
      final res = await call(null, 'GET', '/visits/v1/expenses');
      expect(res.statusCode, 401);
    });

    test('the owner switch off answers 404, not 403', () async {
      await settings(owner: false);
      final caller = await signInForTest(db);
      for (final (m, p) in [
        ('GET', '/visits/v1/expenses'),
        ('GET', '/expense-categories'),
        ('POST', '/visits/v1/expenses'),
      ]) {
        final res = await call(caller, m, p, body: expenseBody());
        expect(res.statusCode, 404, reason: '$m $p');
      }
    });

    test('the mode key is fail-closed: unmirrored is off', () async {
      // Not "entitled to nothing" — never mirrored at all, which a *sellable*
      // module would read as entitled. A mode must not.
      await db
          .into(db.venueSettings)
          .insertOnConflictUpdate(
            VenueSettingsCompanion.insert(
              id: 'default',
              tableExpenseEnabled: const Value(true),
              // Explicitly null, not absent: `insertOnConflictUpdate` leaves an
              // absent column alone, which would keep setUp's entitlement and
              // quietly test nothing.
              modules: const Value<String?>(null),
            ),
          );
      final caller = await signInForTest(db);
      final res = await call(caller, 'GET', '/visits/v1/expenses');
      expect(res.statusCode, 404);
    });

    test('holding some other module does not open it', () async {
      await db
          .into(db.venueSettings)
          .insertOnConflictUpdate(
            VenueSettingsCompanion.insert(
              id: 'default',
              tableExpenseEnabled: const Value(true),
              modules: const Value(moduleMembers),
            ),
          );
      final caller = await signInForTest(db);
      expect(
        (await call(caller, 'GET', '/visits/v1/expenses')).statusCode,
        404,
      );
    });
  });

  group('authority', () {
    test('recording needs its own capability, not manageCash', () async {
      final cash = await signInForTest(
        db,
        caps: {Capability.manageCash, Capability.takeOrder},
        userId: 'u-cash',
      );
      final res = await call(
        cash,
        'POST',
        '/visits/v1/expenses',
        body: expenseBody(),
      );
      expect(res.statusCode, 403);
      expect(
        jsonDecode(await res.readAsString())['capability'],
        Capability.recordTableExpense.name,
      );
    });

    test('the floor capability records', () async {
      final waiter = await signInForTest(
        db,
        caps: {Capability.recordTableExpense},
        userId: 'u-waiter',
      );
      final res = await call(
        waiter,
        'POST',
        '/visits/v1/expenses',
        body: expenseBody(),
      );
      expect(res.statusCode, 200);
      final body = jsonDecode(await res.readAsString());
      expect(body['total'], 20000);
      expect(body['cap'], 50000);
      // A list response never carries the bytes.
      expect(body['expense']['hasPhoto'], isTrue);
      expect(body['expense'], isNot(contains('photo')));
    });

    test('reading opens to any of the three', () async {
      for (final (i, caps) in [
        {Capability.recordTableExpense},
        {Capability.settleBill},
        {Capability.viewReports},
      ].indexed) {
        final c = await signInForTest(db, caps: caps, userId: 'u-read-$i');
        expect(
          (await call(c, 'GET', '/visits/v1/expenses')).statusCode,
          200,
          reason: '$caps',
        );
      }
    });

    test('the photo is a viewReports read', () async {
      final waiter = await signInForTest(
        db,
        caps: {Capability.recordTableExpense},
        userId: 'u-w2',
      );
      await call(waiter, 'POST', '/visits/v1/expenses', body: expenseBody());
      expect((await call(waiter, 'GET', '/expenses/e1/photo')).statusCode, 403);

      final reader = await signInForTest(
        db,
        caps: {Capability.viewReports},
        userId: 'u-r2',
      );
      final res = await call(reader, 'GET', '/expenses/e1/photo');
      expect(res.statusCode, 200);
      expect(res.headers['content-type'], 'image/jpeg');
    });
  });

  group('refusals', () {
    test('the cap refusal carries what is left', () async {
      final caller = await signInForTest(db);
      final res = await call(
        caller,
        'POST',
        '/visits/v1/expenses',
        body: expenseBody(amount: 50001),
      );
      expect(res.statusCode, 400);
      final body = jsonDecode(await res.readAsString());
      expect(body['code'], 'exceeds_bill');
      expect(body['cap'], 50000);
      expect(body['spent'], 0);
    });

    test('a missing photo field reads the same as an empty one', () async {
      final caller = await signInForTest(db);
      for (final p in [null, '']) {
        final res = await call(caller, 'POST', '/visits/v1/expenses', body: {
          'id': 'e1',
          'amount': 1000,
          'categoryId': 'vexc-other',
          'photoBase64': ?p,
        });
        expect(res.statusCode, 400);
        expect(jsonDecode(await res.readAsString())['code'], 'photo_required');
      }
    });

    test('an unknown visit or category is a 404', () async {
      final caller = await signInForTest(db);
      expect(
        (await call(
          caller,
          'POST',
          '/visits/nope/expenses',
          body: expenseBody(),
        )).statusCode,
        404,
      );
      expect(
        (await call(
          caller,
          'POST',
          '/visits/v1/expenses',
          body: expenseBody(category: 'nope'),
        )).statusCode,
        404,
      );
    });
  });

  group('the category catalogue', () {
    test('authoring is the owner authority, not the floor', () async {
      final waiter = await signInForTest(
        db,
        caps: {Capability.recordTableExpense},
        userId: 'u-w3',
      );
      expect(
        (await call(
          waiter,
          'POST',
          '/expense-categories',
          body: {'name': 'Parkir'},
        )).statusCode,
        403,
      );
    });

    test('a parked category still names the rows filed under it', () async {
      final owner = await signInForTest(
        db,
        caps: {Capability.editSettings, Capability.recordTableExpense},
        userId: 'u-owner',
      );
      final made = jsonDecode(
        await (await call(
          owner,
          'POST',
          '/expense-categories',
          body: {'name': 'Parkir'},
        )).readAsString(),
      );
      await call(
        owner,
        'POST',
        '/visits/v1/expenses',
        body: expenseBody(category: made['id'] as String),
      );

      // Parked, never deleted — there is no delete route, and this is why: the
      // expense above must keep rendering the word it was filed under.
      await call(
        owner,
        'PATCH',
        '/expense-categories/${made['id']}',
        body: {'active': false},
      );

      final list = jsonDecode(
        await (await call(owner, 'GET', '/expense-categories')).readAsString(),
      );
      expect(
        (list['categories'] as List).map((c) => c['id']),
        isNot(contains(made['id'])),
        reason: 'a parked category is not offered to a picker',
      );

      final expenses = jsonDecode(
        await (await call(
          owner,
          'GET',
          '/visits/v1/expenses',
        )).readAsString(),
      );
      expect(
        (expenses['expenses'] as List).single['categoryName'],
        'Parkir',
        reason: 'the row still says what it was filed under',
      );
    });
  });

  test('the categories route lists the venue vocabulary', () async {
    final caller = await signInForTest(db, caps: {Capability.takeOrder});
    final res = await call(caller, 'GET', '/expense-categories');
    expect(res.statusCode, 200);
    final cats =
        (jsonDecode(await res.readAsString())['categories'] as List)
            .cast<Map<String, dynamic>>();
    expect(cats.map((c) => c['id']), contains('vexc-other'));
  });
}
