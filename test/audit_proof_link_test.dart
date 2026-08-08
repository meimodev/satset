// An audit row's proof photo is still reachable after the bill closes.
//
// This is the whole load-bearing claim of ADR-0086, and it is exactly the part
// that used to be impossible: closing a bill copies `payments` into
// `table_session_payments`, and that copy used to mint a fresh uuid, so any
// reference stamped at payment time dangled the moment anyone settled up.
//
// The seed replays a month through the production close path, so if the id is
// regenerated anywhere the seeded rows are where it shows.
//
// See docs/adr/0086-proof-lives-on-the-audit-trail.md.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/db/seed.dart';

void main() {
  late AppDatabase db;

  setUp(() async => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('every audit row naming a payment can still reach its photo', () async {
    await seedGenericRestaurant(db);
    await seedSampleVenue(db);

    final withProof = await (db.select(
      db.auditEntries,
    )..where((a) => a.paymentId.isNotNull())).get();

    // The seed spends a budget of stand-in slips; if that budget ever drops to
    // zero this test would pass by testing nothing.
    expect(
      withProof,
      isNotEmpty,
      reason: 'the seed should stamp paymentId on its proofed payments',
    );

    for (final row in withProof) {
      final id = row.paymentId!;
      // The route looks in both tables for exactly this reason — a seeded month
      // is entirely closed bills, so these all resolve on the history side.
      final live = await (db.select(
        db.payments,
      )..where((p) => p.id.equals(id))).getSingleOrNull();
      final history = await (db.select(
        db.tableSessionPayments,
      )..where((p) => p.id.equals(id))).getSingleOrNull();

      final photo = live?.photo ?? history?.photo;
      expect(
        photo,
        isNotNull,
        reason:
            'audit ${row.id} names payment $id, but no payment row in either '
            'table carries a photo — the id did not survive the close',
      );
    }
  });

  test('a payment with no photo never names one', () async {
    await seedGenericRestaurant(db);
    await seedSampleVenue(db);

    // paymentId doubles as the has-photo flag, so the log never offers a tap
    // that leads to a 404. Cash is the common case that must stay null.
    final payments = await db.select(db.tableSessionPayments).get();
    final photoless = {
      for (final p in payments)
        if (p.photo == null) p.id,
    };
    final named = await (db.select(
      db.auditEntries,
    )..where((a) => a.paymentId.isNotNull())).get();

    for (final row in named) {
      expect(
        photoless.contains(row.paymentId),
        isFalse,
        reason: 'audit ${row.id} points at a payment with no photo',
      );
    }
  });
}
