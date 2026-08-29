// A bill is payable while the guest is still eating.
//
// The cashier must be able to take money from a table that has not finished
// service — the guest asks for the bill at the table, and "close the table
// first" is not a step anyone performs before paying. `/settlement/payable`
// therefore keys on the visit (open bill, ≥1 sent line), never on the table
// being freed. This test exists because that is invisible in the route: the
// handler reads `billClosedAt` and nothing about occupancy, so a well-meaning
// filter on `tableFreedAt` would look like a tidy-up and silently hide every
// live bill from the till.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/settlement_routes.dart';
import 'package:satset/server/routes/tickets_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late TestCaller caller;
  final hub = WsHub();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    caller = await signInForTest(db);
  });
  tearDown(() => db.close());

  test('an occupied table with a sent line is payable', () async {
    final router = settlementRoutes(db, hub, caller.auth);

    await db
        .into(db.venueTables)
        .insert(
          VenueTablesCompanion.insert(
            id: 't1',
            label: const Value('T1'),
            zoneId: 'z1',
          ),
        );
    await db
        .into(db.menuItems)
        .insert(
          MenuItemsCompanion.insert(
            id: 'm1',
            categoryId: 'c1',
            name: 'Nasi',
            basePrice: 25000,
          ),
        );

    await submitOrder(
      db,
      tableId: 't1',
      idem: 'idem-1',
      actorId: caller.userId,
      lines: [
        {
          'itemId': 'm1',
          'name': 'Nasi',
          'course': 'mains',
          'qty': 1,
          'unitPrice': 25000,
        },
      ],
    );

    final res = await router(
      Request(
        'GET',
        Uri.parse('http://x/settlement/payable'),
        headers: caller.headers,
      ),
    );
    final rows = (jsonDecode(await res.readAsString()) as List)
        .cast<Map<String, dynamic>>();

    expect(rows, hasLength(1));
    // Still seated, nothing paid, and the till can see the whole amount.
    expect(rows.single['status'], 'occupied');
    expect(rows.single['detached'], false);
    expect(rows.single['lineCount'], 1);
    expect(rows.single['outstanding'], 25000);
  });
}
