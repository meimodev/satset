// A seat replayed off the offline queue must not read as somebody else's
// table.
//
// `POST /tables/<id>/seat` had no idempotency key. The drain (ADR-0090)
// replays an intent whenever it has no proof the host answered — and a reply
// lost on a flaky LAN is exactly that case. The second attempt found the table
// `occupied`, got a 409 `already_seated`, and the drain treats a refusal as a
// stop: every order the waiter captured behind that seat is refused too. One
// dropped reply, a whole backlog dead.
//
// The submit path already claims a key in `Idempotency`. This is the same
// table, the same claim, and the key is the intent id on both.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/tables_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late TestCaller caller;
  late WsHub hub;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    hub = WsHub();
    await db
        .into(db.venueTables)
        .insert(
          VenueTablesCompanion.insert(
            id: 't1',
            label: const Value('D1'),
            zoneId: 'z1',
            capacity: const Value(4),
            status: const Value('available'),
          ),
        );
    caller = await signInForTest(db);
  });
  tearDown(() => db.close());

  Future<Response> seat(Map<String, dynamic> body) =>
      tablesRoutes(db, hub, caller.auth).call(
        Request(
          'POST',
          Uri.parse('http://x/tables/t1/seat'),
          body: jsonEncode(body),
          headers: caller.headers,
        ),
      );

  test('a replayed seat answers like the first one, not 409', () async {
    final first = await seat({'pax': 2, 'idempotencyKey': 'intent-1'});
    expect(first.statusCode, 200);
    final firstBody = await first.readAsString();

    final replay = await seat({'pax': 2, 'idempotencyKey': 'intent-1'});
    expect(
      replay.statusCode,
      200,
      reason: 'a retry of a seat that landed is not a conflict',
    );
    expect(
      jsonDecode(await replay.readAsString()),
      jsonDecode(firstBody),
      reason: 'the stored answer, verbatim',
    );
  });

  test('a replay changes nothing', () async {
    await seat({'pax': 2, 'guestName': 'Budi', 'idempotencyKey': 'intent-2'});
    final after = await (db.select(
      db.visits,
    )..where((v) => v.tableId.equals('t1'))).get();

    await seat({'pax': 4, 'guestName': 'Sri', 'idempotencyKey': 'intent-2'});

    final row = await (db.select(
      db.venueTables,
    )..where((t) => t.id.equals('t1'))).getSingle();
    expect(row.pax, 2, reason: 'the replay is not a second, different seat');
    expect(row.guestName, 'Budi');
    expect(
      await (db.select(db.visits)..where((v) => v.tableId.equals('t1'))).get(),
      hasLength(after.length),
      reason: 'and it does not open a second visit',
    );
  });

  test('a different key on a taken table is still a conflict', () async {
    await seat({'pax': 2, 'idempotencyKey': 'intent-3'});
    final other = await seat({'pax': 2, 'idempotencyKey': 'intent-4'});
    expect(other.statusCode, 409);
    expect(
      (jsonDecode(await other.readAsString()) as Map)['code'],
      'already_seated',
      reason: 'the guard is on the table, not on the key',
    );
  });

  test('a seat without a key behaves exactly as it always did', () async {
    expect((await seat({'pax': 2})).statusCode, 200);
    expect((await seat({'pax': 2})).statusCode, 409);
    expect(
      await db.select(db.idempotency).get(),
      isEmpty,
      reason: 'no key sent, nothing claimed',
    );
  });
}
