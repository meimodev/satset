// The **counter QR** (ADR-0109, switch `counterQr`): one code for the whole
// shop, taped to the till rather than to a table.
//
// What is pinned here is the reason it is not "point the QR at table 1":
//
//   - a counter order carries an **empty** `tableId` — the same convention a
//     Bawa pulang visit has always used for "no table" — so nothing invents a
//     sentinel table row that would then live on the floor plan forever;
//   - accepting one goes through the ordinary `submitOrder` as a **takeaway**,
//     so two strangers in the same queue get two bills rather than sharing one;
//   - the code exists only while the switch is on, and is never minted by a
//     read that merely wondered — a minted code is a live QR.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/self_order.dart';

void main() {
  late AppDatabase db;

  /// The counter QR rides the ordinary guest plane, so a venue needs the
  /// `selfOrder` module for it as much as for a table's code — the switch adds
  /// a second place to scan, never a second way in.
  Future<void> settings({String? modules, String? switches}) => db
      .into(db.venueSettings)
      .insertOnConflictUpdate(
        VenueSettingsCompanion.insert(
          id: 'default',
          guestOrderingEnabled: const Value(true),
          modules: Value(modules),
          counterConfig: Value(switches),
        ),
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.menuItems)
        .insertOnConflictUpdate(
          MenuItemsCompanion.insert(
            id: 'kopi',
            name: 'Kopi Susu',
            categoryId: 'drinks',
            basePrice: 22000,
          ),
        );
  });
  tearDown(() => db.close());

  test('no mode, no switch, no code — and no mint', () async {
    await settings();
    expect(await counterGuestCode(db, mint: true), isNull);
    expect(await isCounterGuestCode(db, 'anything'), isFalse);
  });

  test('the mode alone is not the switch', () async {
    await settings(modules: '$modeCounterService,$moduleSelfOrder');
    expect(await counterGuestCode(db, mint: true), isNull);
  });

  test('minting is blank-fill and idempotent', () async {
    await settings(
      modules: '$modeCounterService,$moduleSelfOrder',
      switches: counterQr,
    );
    // A read that does not ask to mint does not mint: the QR tab asks, and
    // nothing else should be able to publish a code by looking.
    expect(await counterGuestCode(db), isNull);
    final first = await counterGuestCode(db, mint: true);
    expect(first, isNotNull);
    expect(await counterGuestCode(db, mint: true), first);
    expect(await counterGuestCode(db), first);
    expect(await isCounterGuestCode(db, first!), isTrue);
    expect(await isCounterGuestCode(db, ''), isFalse);
  });

  test('a rotate kills the counter card too', () async {
    await settings(
      modules: '$modeCounterService,$moduleSelfOrder',
      switches: counterQr,
    );
    final before = await counterGuestCode(db, mint: true);
    await rotateGuestCodes(db);
    final after = await counterGuestCode(db);
    expect(after, isNotNull);
    expect(after, isNot(before));
  });

  test('a counter session has no sitting to go stale against', () async {
    await settings(
      modules: '$modeCounterService,$moduleSelfOrder',
      switches: counterQr,
    );
    final s = await openGuestSession(db, tableId: '', ttlHours: 4);
    // A table-bound session with a missing table row is dead; a counter one is
    // alive, because its life is the TTL and nothing else.
    expect(await liveGuestSession(db, s.id), isNotNull);
    final ghost = await openGuestSession(db, tableId: 'gone', ttlHours: 4);
    expect(await liveGuestSession(db, ghost.id), isNull);
  });

  test('a counter order is an intent with no table, and says so', () async {
    await settings(
      modules: '$modeCounterService,$moduleSelfOrder',
      switches: counterQr,
    );
    final s = await openGuestSession(db, tableId: '', ttlHours: 4);
    final o = await submitGuestOrder(
      db,
      session: s,
      tableId: '',
      lines: [
        {'itemId': 'kopi', 'qty': 2},
      ],
    );
    expect(o.tableId, '');
    expect(o.subtotal, 44000);
    final json = await guestOrderJson(db, o);
    expect(json['counter'], isTrue);
    expect(json['tableId'], '');
  });

  test(
    'accepting one mints its own takeaway bill, not a shared table',
    () async {
      await settings(
        modules: '$modeCounterService,$moduleSelfOrder',
        switches: counterQr,
      );
      final orders = <String>[];
      for (var i = 0; i < 2; i++) {
        final s = await openGuestSession(db, tableId: '', ttlHours: 4);
        final o = await submitGuestOrder(
          db,
          session: s,
          tableId: '',
          lines: [
            {'itemId': 'kopi', 'qty': 1},
          ],
        );
        orders.add(o.id);
      }
      final visits = <String?>[];
      for (final id in orders) {
        final r = await acceptGuestOrder(db, orderId: id, actorId: 'u1');
        visits.add(r.order.visitId);
      }
      expect(visits[0], isNotNull);
      expect(visits[1], isNotNull);
      // The whole point: two guests at one counter are two bills.
      expect(visits[0], isNot(visits[1]));
      for (final v in visits) {
        final row = await (db.select(
          db.visits,
        )..where((x) => x.id.equals(v!))).getSingle();
        expect(row.tableId, '');
        expect(row.tableLabel, startsWith('Bawa pulang'));
      }
    },
  );
}
