// `GET /members/lookup?ids=` — resolving a known set of member ids rather than
// searching for one. The floor names the [[Pemilik tiket]] on a line it has
// already sent, and this is the only route open to `takeOrder` that can answer.
//
// Two things are pinned here that the client-side unit test cannot reach:
//
// 1. `ids` beats `q`, and answers *only* the ids asked for. An id with no row
//    is a member since deleted (ADR-0092) and is simply absent — the caller
//    records the miss and renders the placeholder.
// 2. The gate is unchanged: `takeOrder` reads minimal identity here, and the
//    phone stays masked. A new key into a route must not be a new way in.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:drift/drift.dart' show Value;
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/members.dart';
import 'package:satset/server/routes/members_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late TestCaller caller;
  late Future<Response> Function(Request) router;

  Future<List<Map>> lookup(String query, {TestCaller? as}) async {
    final res = await router(
      Request(
        'GET',
        Uri.parse('http://x/members/lookup?$query'),
        headers: (as ?? caller).headers,
      ),
    );
    final body = await res.readAsString();
    expect(res.statusCode, 200, reason: body);
    return (jsonDecode(body) as List).cast<Map>();
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    caller = await signInForTest(db, caps: {Capability.takeOrder});
    router = membersRoutes(db, WsHub(), caller.auth).call;
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            membersEnabled: const Value(true),
          ),
        );
  });
  tearDown(() => db.close());

  test('names only the ids asked for, phone masked', () async {
    final ani = await createMember(db, name: 'Ani', phone: '081100000011');
    await createMember(db, name: 'Budi', phone: '081100000022');

    final got = await lookup('ids=${ani.id}');
    expect(got.length, 1);
    expect(got.single['id'], ani.id);
    expect(got.single['name'], 'Ani');
    // Minimal identity: the floor learns a name, never a reachable number.
    expect(got.single['phone'], '•••• 0011');
  });

  test('an id with no member is absent, not an error', () async {
    final ani = await createMember(db, name: 'Ani', phone: '081100000011');

    final got = await lookup('ids=${ani.id},gone-1');
    expect(got.map((m) => m['id']), [ani.id]);
  });

  test('ids beats q — the two keys are not combined', () async {
    final ani = await createMember(db, name: 'Ani', phone: '081100000011');
    await createMember(db, name: 'Budi', phone: '081100000022');

    // A caller asking by id gets exactly that, even alongside a search that
    // would have matched somebody else.
    final got = await lookup('ids=${ani.id}&q=Budi');
    expect(got.map((m) => m['name']), ['Ani']);
  });

  test('the gate is unchanged — no capability, no names', () async {
    final ani = await createMember(db, name: 'Ani', phone: '081100000011');
    final stranger = await signInForTest(
      db,
      caps: {Capability.viewKds},
      userId: 'kds-user',
    );

    final res = await router(
      Request(
        'GET',
        Uri.parse('http://x/members/lookup?ids=${ani.id}'),
        headers: stranger.headers,
      ),
    );
    expect(res.statusCode, 403);
  });
}
