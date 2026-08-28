// [[Menu populer]] — the rank the order-flow grid sorts by (ADR-0113).
//
// What is pinned: the window is rollover-aligned rather than `now - 30d`, a
// voided line does not count, and an item nobody sold is simply absent from the
// map (the client reads absent as "bottom, alphabetically").
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/menu_routes.dart';
import 'package:satset/server/shift.dart' show businessDayStart;

void main() {
  late AppDatabase db;

  Future<void> line(
    String itemId, {
    required DateTime at,
    int qty = 1,
    String status = 'served',
  }) => db
      .into(db.tickets)
      .insert(
        TicketsCompanion.insert(
          id: '$itemId-${at.microsecondsSinceEpoch}-$status',
          tableId: 't1',
          itemId: itemId,
          name: itemId,
          course: 'mains',
          price: 20000,
          status: status,
          sentAt: at,
          qty: Value(qty),
        ),
      );

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('sums qty per item, voided excluded', () async {
    final now = DateTime.now();
    await line('nasi', at: now.subtract(const Duration(days: 1)), qty: 3);
    await line('nasi', at: now.subtract(const Duration(days: 2)), qty: 4);
    await line('mie', at: now.subtract(const Duration(days: 1)), qty: 9);
    await line(
      'mie',
      at: now.subtract(const Duration(days: 1)),
      qty: 100,
      status: 'voided',
    );
    expect(await menuPopularity(db), {'nasi': 7, 'mie': 9});
  });

  test('an item with no line in the window is absent, not zero', () async {
    await line('nasi', at: DateTime.now().subtract(const Duration(days: 40)));
    expect(await menuPopularity(db), isEmpty);
  });

  // The window starts at the business day's rollover (04:00 by default), not
  // at this instant: a line sent one second before that edge is out, and the
  // edge itself is in. Computed rather than guessed, so the assertion does not
  // depend on what time of day the suite runs.
  test('the window edge is the rollover, not the wall clock', () async {
    final edge = businessDayStart(
      DateTime.now(),
      4,
    ).subtract(const Duration(days: 30));
    await line('masuk', at: edge);
    await line('keluar', at: edge.subtract(const Duration(seconds: 1)));
    expect(await menuPopularity(db), {'masuk': 1});
  });
}
