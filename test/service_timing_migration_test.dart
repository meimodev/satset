// The v37 migration rebuilds `menu_items` to relax `prep_time` to nullable
// (SQLite has no ALTER COLUMN), and reinterprets the old column default as
// "never touched". Both are one-way against shipped data, so the transform is
// exercised directly here.
// See docs/adr/0043-per-item-ready-target-and-course-lateness.md.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/server/db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<int?> prepOf(String id) async {
    final r = await (db.select(db.menuItems)..where((t) => t.id.equals(id)))
        .getSingle();
    return r.prepTime;
  }

  test('prep_time relaxes to nullable and keeps deliberate overrides',
      () async {
    // Stand up the pre-v37 shape: every row carries a value, because the
    // column was NOT NULL DEFAULT 5.
    await db.into(db.menuItems).insert(MenuItemsCompanion.insert(
          id: 'steak',
          name: 'Steak',
          categoryId: 'mains',
          basePrice: 250000,
          prepTime: const Value(25),
        ));
    await db.into(db.menuItems).insert(MenuItemsCompanion.insert(
          id: 'teh',
          name: 'Es Teh',
          categoryId: 'soft',
          basePrice: 15000,
          prepTime: const Value(2),
        ));
    // A row still sitting at the old column default — nobody ever set this.
    await db.into(db.menuItems).insert(MenuItemsCompanion.insert(
          id: 'untouched',
          name: 'Nasi Putih',
          categoryId: 'sides',
          basePrice: 10000,
          prepTime: const Value(5),
        ));

    await db.customStatement(
      'UPDATE menu_items SET prep_time = NULL WHERE prep_time = 5',
    );

    // Deliberate values survive as per-item overrides.
    expect(await prepOf('steak'), 25);
    expect(await prepOf('teh'), 2);
    // The untouched default becomes "inherit the venue default", so moving
    // the venue target moves this item too.
    expect(await prepOf('untouched'), isNull);
  });

  test('a null prep_time is writable and readable end to end', () async {
    await db.into(db.menuItems).insert(MenuItemsCompanion.insert(
          id: 'inherit',
          name: 'Gado-Gado',
          categoryId: 'starters',
          basePrice: 65000,
        ));
    // Absent on insert ⇒ null ⇒ inherits, which is the default for any item
    // created after v37.
    expect(await prepOf('inherit'), isNull);

    await (db.update(db.menuItems)..where((t) => t.id.equals('inherit')))
        .write(const MenuItemsCompanion(prepTime: Value(12)));
    expect(await prepOf('inherit'), 12);

    // Clearing the override returns the item to inherit.
    await (db.update(db.menuItems)..where((t) => t.id.equals('inherit')))
        .write(const MenuItemsCompanion(prepTime: Value(null)));
    expect(await prepOf('inherit'), isNull);
  });

  test('firedAt defaults to null and survives a round trip', () async {
    final now = DateTime.now();
    await db.into(db.tickets).insert(TicketsCompanion.insert(
          id: 't1',
          tableId: 'tbl-1',
          itemId: 'steak',
          name: 'Steak',
          course: 'mains',
          price: 250000,
          status: 'held',
          sentAt: now,
        ));
    var row = await (db.select(db.tickets)..where((t) => t.id.equals('t1')))
        .getSingle();
    // A normal send has no fire stamp — the clock starts at sentAt.
    expect(row.firedAt, isNull);

    final firedAt = now.add(const Duration(minutes: 40));
    await (db.update(db.tickets)..where((t) => t.id.equals('t1')))
        .write(TicketsCompanion(
      status: const Value('sent'),
      firedAt: Value(firedAt),
    ));
    row = await (db.select(db.tickets)..where((t) => t.id.equals('t1')))
        .getSingle();
    expect(row.firedAt, isNotNull);
    // The held course is 0 minutes old to the kitchen, not 40.
    expect(row.firedAt!.difference(row.sentAt), const Duration(minutes: 40));
  });

  test('venue timing defaults land on a fresh database', () async {
    final s = await db.select(db.venueSettings).getSingle();
    expect(s.prepTargetMins, 15);
    expect(s.pickupTargetMins, 4);
    expect(s.ungreetedMins, 7);
    expect(s.ungreetedEscalateMins, 5);
    expect(s.longStayMins, 90);
    expect(s.idleTableMins, 20);
    expect(s.reservationGraceMins, 15);
    // Both audible cues ship on — the upgrade posture chosen in ADR-0044.
    expect(s.ungreetedAlertEnabled, isTrue);
    expect(s.pickupAlertEnabled, isTrue);
  });
}
