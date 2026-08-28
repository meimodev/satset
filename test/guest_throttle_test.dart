// The guest plane is a cleartext socket with no credential but the code
// printed on a card (ADR-0105), so "who is calling" is answerable only by what
// the socket can see. That makes two things cheap that should not be:
//
//   - a [[Stempel]] lookup is a question about a phone number the caller typed,
//     and the per-session cap that guarded it is worthless because a session
//     costs one unauthenticated POST — so the sweep just mints a new one;
//   - a guest order writes rows and fans out to every KDS in the venue, and
//     nothing capped it at all.
//
// What is pinned here is that the two buckets are keyed on different things on
// purpose: the tight one on the *number being asked about*, the loose one on
// the *caller*, because neither one can see the abuse the other is for.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/server/db/database.dart';
import 'package:satset/server/guest/guest_routes.dart';
import 'package:satset/server/self_order.dart';
import 'package:satset/server/ws_hub.dart';

void main() {
  group('GuestWindow', () {
    test('counts to the limit, then trips', () {
      final w = GuestWindow(limit: 3, span: const Duration(minutes: 5));
      expect(w.trip('a'), isFalse);
      expect(w.trip('a'), isFalse);
      expect(w.trip('a'), isFalse);
      expect(w.trip('a'), isTrue, reason: 'the fourth is over three');
      expect(w.trip('a'), isTrue, reason: 'and it stays over');
    });

    test('one key is not another key', () {
      final w = GuestWindow(limit: 1, span: const Duration(minutes: 5));
      expect(w.trip('a'), isFalse);
      expect(w.trip('a'), isTrue);
      expect(w.trip('b'), isFalse, reason: 'b has spent nothing');
    });

    test('an empty key is never tripped', () {
      // Nothing to key on. Inventing a shared bucket for "unknown" would let
      // the first anonymous caller lock out every other one.
      final w = GuestWindow(limit: 1, span: const Duration(minutes: 5));
      for (var i = 0; i < 10; i++) {
        expect(w.trip(''), isFalse);
      }
    });

    test('the window ends', () async {
      final w = GuestWindow(limit: 1, span: const Duration(milliseconds: 40));
      expect(w.trip('a'), isFalse);
      expect(w.trip('a'), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(w.trip('a'), isFalse, reason: 'a fresh window, a fresh allowance');
    });
  });

  group('on the wire', () {
    late AppDatabase db;
    late WsHub hub;
    late Router router;

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
              label: const Value('T1'),
              zoneId: 'z1',
              capacity: const Value(4),
              guestCode: const Value('CODE0001'),
            ),
          );
      // Built once, like the socket builds it at boot — the buckets live in
      // the router, so a per-call router would forget every count.
      router = guestRoutes(db, hub);
    });
    tearDown(() => db.close());

    Future<Response> punch(String phone, String sessionId, {String? ip}) =>
        router.call(
          Request(
            'POST',
            Uri.parse('http://x/guest/punch'),
            headers: {
              'content-type': 'application/json',
              'x-guest-session': sessionId,
            },
            body: '{"phone":"$phone"}',
            context: {'guest.ip': ?ip},
          ),
        );

    /// A session costs one unauthenticated POST, which is the whole reason the
    /// per-session cap does not hold anything.
    Future<String> freshSession() async =>
        (await openGuestSession(db, tableId: 't1', ttlHours: 4)).id;

    test('a number can only be asked about so often, session or no', () async {
      // A different session every time, so nothing here is the per-session cap
      // doing the work.
      final codes = <int>[];
      for (var i = 0; i < 6; i++) {
        codes.add(
          (await punch('08123456789', await freshSession())).statusCode,
        );
      }
      expect(
        codes.take(5),
        everyElement(404),
        reason: 'the program is off here, so a real lookup is a 404',
      );
      expect(codes.last, 429, reason: 'the sixth ask about that number is not');
    });

    test('a missing number does not cost a real one its allowance', () async {
      final s = await freshSession();
      for (var i = 0; i < 3; i++) {
        expect((await punch('', s)).statusCode, 400);
      }
      // Still five left for the number that was never named.
      expect(
        (await punch('08123456789', await freshSession())).statusCode,
        404,
      );
    });

    test('another number still answers', () async {
      for (var i = 0; i < 6; i++) {
        await punch('08123456789', await freshSession());
      }
      expect(
        (await punch('08999999999', await freshSession())).statusCode,
        404,
        reason: 'the bucket is the number, not the feature',
      );
    });

    test('a sweep runs out of caller, not out of number', () async {
      // Each number is asked about once, so the phone bucket never sees this.
      // The address does.
      var refused = 0;
      var sessionId = '';
      for (var i = 0; i < 45; i++) {
        // A fresh session every fifth call, to step around the per-session cap
        // exactly as a sweep would.
        if (i % 5 == 0) sessionId = await freshSession();
        final res = await punch('0812$i', sessionId, ip: '192.168.1.66');
        if (res.statusCode == 429) refused++;
      }
      expect(refused, greaterThan(0), reason: 'the caller ran out');
    });

    test('an order from a spent caller is refused too', () async {
      var sessionId = '';
      for (var i = 0; i < 45; i++) {
        if (i % 5 == 0) sessionId = await freshSession();
        await punch('0812$i', sessionId, ip: '192.168.1.66');
      }
      final res = await router.call(
        Request(
          'POST',
          Uri.parse('http://x/guest/orders'),
          headers: {
            'content-type': 'application/json',
            'x-guest-session': await freshSession(),
          },
          body: '{"code":"CODE0001","lines":[]}',
          context: const {'guest.ip': '192.168.1.66'},
        ),
      );
      expect(
        res.statusCode,
        429,
        reason: 'one bucket per caller, not one per route',
      );
    });

    test('a different caller is untouched by the spent one', () async {
      var sessionId = '';
      for (var i = 0; i < 45; i++) {
        if (i % 5 == 0) sessionId = await freshSession();
        await punch('0812$i', sessionId, ip: '192.168.1.66');
      }
      expect(
        (await punch(
          '08777777777',
          await freshSession(),
          ip: '192.168.1.99',
        )).statusCode,
        404,
        reason: 'the table next to the sweep is still allowed to eat',
      );
    });
  });
}
