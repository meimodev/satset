// A category's [[Jam tayang]] on the guest menu — B5's availability half.
//
// The pricing half of B5 was rejected; this is the part that stayed, because a
// guest self-ordering at 21:00 could otherwise order a breakfast set nobody
// intends to make.
//
// What is pinned: the window closes an item rather than hiding it, a wrapping
// window is a real late-night menu rather than a bug, and a same-day `forceIn`
// still beats the clock.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/self_order.dart';

void main() {
  late AppDatabase db;

  Future<void> category({int? from, int? to}) => db
      .into(db.menuCategories)
      .insertOnConflictUpdate(
        MenuCategoriesCompanion.insert(
          id: 'sarapan',
          name: 'Sarapan',
          guestFromMin: Value(from),
          guestToMin: Value(to),
        ),
      );

  /// The one item's `soldOut`, read the way the guest page reads it.
  Future<bool> soldOut() async {
    final menu = await guestMenuJson(db);
    final items = menu['items'] as List;
    return (items.single as Map)['soldOut'] as bool;
  }

  // SatClock is an offset from the real clock, not a settable instant, so a
  // wall-clock hour is expressed as the offset that lands on it.
  void at(int hour, int minute) => SatClock.adopt(
    DateTime(2026, 8, 20, hour, minute).difference(SatClock.realNow()),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            guestOrderingEnabled: const Value(true),
          ),
        );
    await db
        .into(db.menuItems)
        .insertOnConflictUpdate(
          MenuItemsCompanion.insert(
            id: 'bubur',
            name: 'Bubur Ayam',
            categoryId: 'sarapan',
            basePrice: 20000,
            guestVisible: const Value(true),
          ),
        );
  });

  tearDown(() async {
    SatClock.clear();
    await db.close();
  });

  test('no window is always on', () async {
    await category();
    at(3, 0);
    expect(await soldOut(), isFalse);
    at(23, 30);
    expect(await soldOut(), isFalse);
  });

  test('an ordinary window opens and shuts', () async {
    // 06:00–11:00.
    await category(from: 360, to: 660);
    at(5, 59);
    expect(await soldOut(), isTrue);
    at(6, 0); // inclusive start
    expect(await soldOut(), isFalse);
    at(10, 59);
    expect(await soldOut(), isFalse);
    at(11, 0); // exclusive end
    expect(await soldOut(), isTrue);
    at(21, 0); // the case this feature exists for
    expect(await soldOut(), isTrue);
  });

  test('a window that wraps midnight is a late-night menu', () async {
    // 22:00–02:00.
    await category(from: 1320, to: 120);
    at(21, 59);
    expect(await soldOut(), isTrue);
    at(22, 0);
    expect(await soldOut(), isFalse);
    at(1, 0); // still last night's service
    expect(await soldOut(), isFalse);
    at(2, 0);
    expect(await soldOut(), isTrue);
  });

  test('the item is shut, never hidden', () async {
    await category(from: 360, to: 660);
    at(21, 0);
    final menu = await guestMenuJson(db);
    // Still on the menu, and its category still has a chip — a guest who
    // cannot find breakfast at all assumes it was discontinued.
    expect((menu['items'] as List), hasLength(1));
    expect((menu['categories'] as List), hasLength(1));
    expect((menu['categories'] as List).single, containsPair('fromMin', 360));
  });

  test('a same-day forceIn beats the window', () async {
    await category(from: 360, to: 660);
    at(21, 0);
    expect(await soldOut(), isTrue);
    await (db.update(db.menuItems)..where((i) => i.id.equals('bubur'))).write(
      MenuItemsCompanion(
        guestStockOverride: const Value('forceIn'),
        guestOverrideAt: Value(SatClock.now()),
      ),
    );
    expect(await soldOut(), isFalse);
  });
}
