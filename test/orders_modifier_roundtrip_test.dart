// Deterministic proof of the live order pipeline: POST /orders -> Drift ->
// GET /tickets, through the *real* shelf routes and an in-memory database.
// Asserts a single-select add-on and the variant survive the round trip and
// come back as structured objects. This is the path the patrol tests fake
// (they seed the repository directly). See
// docs/adr/0011-ticket-modifier-snapshot.md.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/tickets_routes.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:shelf/shelf.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late Handler router;
  late TestCaller caller;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Route gates want a real caller now (ADR-0102); WsHub broadcast no-ops.
    caller = await signInForTest(db);
    router = ticketsRoutes(db, WsHub(), caller.auth).call;
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'single-select add-on and variant survive /orders -> /tickets',
    () async {
      final orderBody = jsonEncode({
        'tableId': 't-test',
        'idempotencyKey': 'idem-1',
        'actorId': null,
        'lines': [
          {
            'itemId': 'i1',
            'name': 'Nasi Goreng',
            'variantId': 'v1',
            'variantName': 'Besar',
            'course': 'mains',
            'qty': 1,
            'unitPrice': 25000,
            'specialInstructions': null,
            'modifiers': [
              {
                'groupId': 'spice',
                'optionId': 'hot',
                'label': 'Pedas',
                'priceDelta': 0,
              },
              {
                'groupId': 'extras',
                'optionId': 'krupuk',
                'label': 'Kerupuk',
                'priceDelta': 3000,
              },
            ],
          },
        ],
      });

      final postRes = await router(
        Request(
          'POST',
          Uri.parse('http://localhost/orders'),
          body: orderBody,
          headers: {'content-type': 'application/json', ...caller.headers},
        ),
      );
      expect(postRes.statusCode, 200, reason: await postRes.readAsString());

      final getRes = await router(
        Request(
          'GET',
          Uri.parse('http://localhost/tickets'),
          headers: caller.headers,
        ),
      );
      expect(getRes.statusCode, 200);
      final tickets = jsonDecode(await getRes.readAsString()) as List;

      final t = tickets.firstWhere((e) => e['itemId'] == 'i1') as Map;
      expect(t['variantName'], 'Besar', reason: 'variant must round-trip');

      final mods = (t['modifiers'] as List).cast<Map>();
      expect(mods.length, 2, reason: 'both add-ons must persist');

      final spice = mods.firstWhere((m) => m['groupId'] == 'spice');
      expect(
        spice['label'],
        'Pedas',
        reason: 'single-select add-on must survive (the original bug)',
      );
      expect(spice['optionId'], 'hot');

      final extras = mods.firstWhere((m) => m['groupId'] == 'extras');
      expect(extras['label'], 'Kerupuk');
      expect(extras['priceDelta'], 3000);
    },
  );
}
