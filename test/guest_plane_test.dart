// The second listener (ADR-0105): **cleartext HTTP, guest routes only**.
//
// The whole safety argument for a plane with no bearer on it is that the staff
// API is not reachable there — not "reachable and refused", *not there*. That
// is a claim about a router, so this test asks the socket rather than reading
// the code:
//
//   - a guest route answers on :8080 with no credential of any kind;
//   - a staff route does not exist on it at all;
//   - an unknown code, a deactivated table and a table opted out of self-order
//     are one indistinguishable 404, so the QR cannot enumerate the floor;
//   - with the venue flag off the page is not served, and the same holds when
//     the venue is not entitled to the [[Modul]] at all (ADR-0107) — an
//     unentitled venue is indistinguishable from one that never opted in.
//
// The flag also decides whether the socket binds at all, which lives in
// `ServerRuntime._syncGuestPlane` — that half is exercised by booting the
// runtime, not here.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:satset/server/db/database.dart';
import 'package:satset/server/guest/guest_plane.dart';
import 'package:satset/server/ws_hub.dart';

void main() {
  late AppDatabase db;
  late GuestPlane plane;

  // Not 8080: a developer's own server may well be up while the suite runs.
  const port = 18080;
  const base = 'http://127.0.0.1:$port';

  Future<void> setFlag(bool on) => (db.update(
    db.venueSettings,
  )..where((x) => x.id.equals('default'))).write(
    VenueSettingsCompanion(guestOrderingEnabled: Value(on)),
  );

  /// Null `modules` (the setUp default) means "never mirrored", which reads as
  /// entitled — so a test that wants the unentitled case has to say so.
  Future<void> setModules(String csv) => (db.update(
    db.venueSettings,
  )..where((x) => x.id.equals('default'))).write(
    VenueSettingsCompanion(modules: Value(csv)),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            displayName: const Value('Warung Sebelah'),
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
    plane = GuestPlane(db: db, hub: WsHub(), port: port);
    await plane.start();
  });

  tearDown(() async {
    await plane.stop();
    await db.close();
  });

  test('a guest route answers with no credential at all', () async {
    final res = await http.get(Uri.parse('$base/guest/venue?code=CODE0001'));
    expect(res.statusCode, 200);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    expect(body['venue'], 'Warung Sebelah');
    expect(body['tableLabel'], 'T1');
    expect(body['tableId'], 't1');
  });

  test('the staff API is not on this plane', () async {
    // Not 401, not 403 — 404. There is no route here to refuse.
    for (final path in [
      '/tables',
      '/tickets',
      '/menu/items',
      '/selforder',
      '/auth/pin',
    ]) {
      final res = await http.get(Uri.parse('$base$path'));
      expect(res.statusCode, 404, reason: '$path must not exist on the guest plane');
    }
  });

  test('an unknown code is the same 404 as an opted-out table', () async {
    final unknown = await http.get(Uri.parse('$base/guest/venue?code=NOPE'));
    expect(unknown.statusCode, 404);

    await (db.update(db.venueTables)..where((t) => t.id.equals('t1'))).write(
      const VenueTablesCompanion(guestOrderingEnabled: Value(false)),
    );
    final optedOut = await http.get(
      Uri.parse('$base/guest/venue?code=CODE0001'),
    );
    expect(optedOut.statusCode, 404);
    expect(optedOut.body, unknown.body);
  });

  test('a session id from nowhere buys nothing', () async {
    final res = await http.post(
      Uri.parse('$base/guest/orders'),
      headers: {
        'content-type': 'application/json',
        'x-guest-session': 'made-up',
      },
      body: jsonEncode({
        'code': 'CODE0001',
        'lines': [
          {'itemId': 'nasgor', 'qty': 1},
        ],
      }),
    );
    expect(res.statusCode, anyOf(401, 404));
    expect(await db.select(db.guestOrders).get(), isEmpty);
  });

  test('with the flag off the page is not served', () async {
    await setFlag(false);
    final res = await http.get(Uri.parse('$base/t/CODE0001'));
    expect(res.statusCode, 404);
  });

  test('an unentitled venue is served nothing either', () async {
    // The venue *wants* self-order — self-order is the module it does not hold.
    // Same 404 as never having opted in, because a guest must not be able to
    // tell a venue that did not buy the feature from one that did not want it.
    //
    // In production the socket does not bind at all for either case, since
    // `_syncGuestPlane` reads the same `guestRules().enabled` this asserts on;
    // this test starts the plane by hand, so it asks the page instead.
    await setModules('');
    expect((await http.get(Uri.parse('$base/t/CODE0001'))).statusCode, 404);
  });

  test('the URL a printed QR carries is the plane\'s own', () {
    expect(plane.running, isTrue);
    expect(plane.urlFor('CODE0001', '192.168.1.9'),
        'http://192.168.1.9:$port/t/CODE0001');
  });
}
