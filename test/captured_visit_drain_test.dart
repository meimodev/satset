// The host half of a **[[Kunjungan tertangkap]]** (ADR-0139).
//
// A device that could not reach here mints its own visit and ticket ids,
// settles the bill against them, and prints a struk naming them. So the drain
// is not "replay some writes" — it is the host adopting ids it did not choose.
// Get that wrong and the money events queued behind the seat all address a
// visit that does not exist, every one of them 404s, and the chain parks with
// the cash already in a drawer. That is the failure these pin.
//
// The switch throughout is a **past-dated `capturedAt`**, never the mere
// presence of a client field: a live caller naming a primary key, or skipping a
// stock check, is ignored rather than obeyed.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/tables_routes.dart';
import 'package:satset/server/routes/tickets_routes.dart';

void main() {
  late AppDatabase db;

  Future<void> seed() async {
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(id: 'default', modules: const Value('')),
        );
    for (final id in ['t1', 't2']) {
      await db
          .into(db.venueTables)
          .insertOnConflictUpdate(
            VenueTablesCompanion.insert(
              id: id,
              zoneId: 'z1',
              label: Value(id.toUpperCase()),
            ),
          );
    }
    await db
        .into(db.menuItems)
        .insertOnConflictUpdate(
          MenuItemsCompanion.insert(
            id: 'nasgor',
            name: 'Nasi Goreng',
            categoryId: 'mains',
            basePrice: 25000,
          ),
        );
  }

  const lines = <Map<String, dynamic>>[
    {
      'itemId': 'nasgor',
      'name': 'Nasi Goreng',
      'course': 'mains',
      'qty': 1,
      'unitPrice': 25000,
      'ticketId': 'client-ticket-1',
    },
  ];

  DateTime longAgo() => DateTime.now().toUtc().subtract(const Duration(hours: 2));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await seed();
  });
  tearDown(() => db.close());

  group('the visit id the device minted', () {
    test('is adopted, not replaced', () async {
      final id = await ensureVisit(
        db,
        't1',
        visitId: 'captured-v1',
        at: longAgo(),
      );
      expect(id, 'captured-v1');
      final v = await db.select(db.visits).getSingle();
      expect(v.id, 'captured-v1');
      final t = await db.select(db.venueTables).get();
      expect(t.firstWhere((x) => x.id == 't1').currentVisitId, 'captured-v1');
    });

    test('replaying the same seat writes nothing new', () async {
      await ensureVisit(db, 't1', visitId: 'captured-v1', at: longAgo());
      final again = await ensureVisit(
        db,
        't1',
        visitId: 'captured-v1',
        at: longAgo(),
      );
      expect(again, 'captured-v1');
      expect(await db.select(db.visits).get(), hasLength(1));
    });

    test('a live seat still mints its own, as it always has', () async {
      final id = await ensureVisit(db, 't1');
      expect(id, isNotEmpty);
      expect(id, isNot('captured-v1'));
    });

    test('yields the table to a live visit, and still lands', () async {
      // Q23: the table was cleared and re-seated online while the handset was
      // dark. Both visits are real; only one can hold the slot, and it must be
      // the one with guests at it. The loser lands table-less rather than
      // vanishing — a swallowed visit is money gone.
      final live = await ensureVisit(db, 't1');
      final captured = await ensureVisit(
        db,
        't1',
        visitId: 'captured-v1',
        at: longAgo(),
      );
      expect(captured, 'captured-v1');
      expect(await db.select(db.visits).get(), hasLength(2));
      final t = await db.select(db.venueTables).get();
      expect(
        t.firstWhere((x) => x.id == 't1').currentVisitId,
        live,
        reason: 'a live visit must never lose its table to a replay',
      );
    });
  });

  group('the ticket ids the device minted', () {
    test('are adopted on a replay', () async {
      await submitOrder(
        db,
        tableId: 't1',
        idem: 'i1',
        lines: lines,
        capturedVisitId: 'captured-v1',
        capturedAt: longAgo(),
      );
      final t = await db.select(db.tickets).getSingle();
      expect(t.id, 'client-ticket-1');
      expect(t.visitId, 'captured-v1');
    });

    test('are ignored on a live submit', () async {
      // Otherwise any caller could name a primary key.
      await submitOrder(db, tableId: 't1', idem: 'i1', lines: lines);
      final t = await db.select(db.tickets).getSingle();
      expect(t.id, isNot('client-ticket-1'));
    });

    test('a second replay of the same line does not cook it twice', () async {
      await submitOrder(
        db,
        tableId: 't1',
        idem: 'i1',
        lines: lines,
        capturedVisitId: 'captured-v1',
        capturedAt: longAgo(),
      );
      await submitOrder(
        db,
        tableId: 't1',
        idem: 'i2',
        lines: lines,
        capturedVisitId: 'captured-v1',
        capturedAt: longAgo(),
      );
      expect(await db.select(db.tickets).get(), hasLength(1));
    });
  });

  group('a captured line is not refused for stock', () {
    Future<void> withRecipe() async {
      await db
          .into(db.ingredients)
          .insertOnConflictUpdate(
            IngredientsCompanion.insert(
              id: 'beras',
              name: 'Beras',
              unit: 'g',
              stockOnHand: const Value(0),
            ),
          );
      await db
          .into(db.recipeLines)
          .insertOnConflictUpdate(
            RecipeLinesCompanion.insert(
              id: 'r1',
              ownerKind: 'item',
              ownerId: 'nasgor',
              ingredientId: 'beras',
              qty: 100,
            ),
          );
    }

    test('a live order out of stock is still rejected', () async {
      await withRecipe();
      final res = await submitOrder(
        db,
        tableId: 't1',
        idem: 'i1',
        lines: lines,
      );
      expect(res.rejected, hasLength(1));
      expect(await db.select(db.tickets).get(), isEmpty);
    });

    test('a replay lands and drives stock negative', () async {
      await withRecipe();
      final res = await submitOrder(
        db,
        tableId: 't1',
        idem: 'i1',
        lines: lines,
        capturedVisitId: 'captured-v1',
        capturedAt: longAgo(),
      );
      expect(
        res.rejected,
        isEmpty,
        reason: 'the guest ate it and paid for it — refusing now leaves money '
            'collected against a line in no ledger',
      );
      expect(await db.select(db.tickets).get(), hasLength(1));
      final beras = await db.select(db.ingredients).getSingle();
      expect(beras.stockOnHand, lessThan(0));
    });

    test('and says so in the audit, for opname to close', () async {
      await withRecipe();
      await submitOrder(
        db,
        tableId: 't1',
        idem: 'i1',
        lines: lines,
        capturedVisitId: 'captured-v1',
        capturedAt: longAgo(),
      );
      final rows = await db.select(db.auditEntries).get();
      final dark = rows.where((r) => r.kind == AuditKind.stockSoldDark.name);
      expect(
        dark,
        hasLength(1),
        reason: 'negative stock with no explanation is a bug report; naming '
            'the item and the moment makes it a reconciliation',
      );
    });
  });

  group('the replay floor', () {
    test('a present-dated capturedAt gets ordinary enforcement', () async {
      // A wrong clock is a real failure mode on cheap Android hardware. Hanging
      // a venue-wide control on the mere presence of a client field means it
      // switches off with nobody seeing an error.
      await db
          .into(db.ingredients)
          .insertOnConflictUpdate(
            IngredientsCompanion.insert(
              id: 'beras',
              name: 'Beras',
              unit: 'g',
              stockOnHand: const Value(0),
            ),
          );
      await db
          .into(db.recipeLines)
          .insertOnConflictUpdate(
            RecipeLinesCompanion.insert(
              id: 'r1',
              ownerKind: 'item',
              ownerId: 'nasgor',
              ingredientId: 'beras',
              qty: 100,
            ),
          );
      final res = await submitOrder(
        db,
        tableId: 't1',
        idem: 'i1',
        lines: lines,
        capturedVisitId: 'captured-v1',
        capturedAt: DateTime.now().toUtc(),
      );
      expect(res.rejected, hasLength(1));
      final t = await db.select(db.tickets).get();
      expect(t, isEmpty);
    });

    test('and cannot name its own visit either', () async {
      await submitOrder(
        db,
        tableId: 't1',
        idem: 'i1',
        lines: lines,
        capturedVisitId: 'captured-v1',
        capturedAt: DateTime.now().toUtc(),
      );
      final v = await db.select(db.visits).getSingle();
      expect(v.id, isNot('captured-v1'));
    });
  });

  group('a line whose bill was already settled', () {
    test('is born ready, never sent — the kitchen must not cook it', () async {
      await ensureVisit(db, 't1', visitId: 'captured-v1', at: longAgo());
      await (db.update(db.visits)..where((v) => v.id.equals('captured-v1')))
          .write(VisitsCompanion(billClosedAt: Value(longAgo())));
      await submitOrder(
        db,
        tableId: 't1',
        idem: 'i1',
        lines: lines,
        capturedVisitId: 'captured-v1',
        capturedAt: longAgo(),
      );
      final t = await db.select(db.tickets).getSingle();
      expect(t.status, 'ready');
      expect(
        t.readyAt,
        isNotNull,
        reason: 'a null readyAt ticks an elapsed pill forever',
      );
    });

    test('but an open captured visit still reaches the KDS', () async {
      // The food genuinely still needs cooking. The bill's own state is the
      // discriminator, not the fact of being a replay.
      await ensureVisit(db, 't1', visitId: 'captured-v1', at: longAgo());
      await submitOrder(
        db,
        tableId: 't1',
        idem: 'i1',
        lines: lines,
        capturedVisitId: 'captured-v1',
        capturedAt: longAgo(),
      );
      final t = await db.select(db.tickets).getSingle();
      expect(t.status, 'sent');
    });
  });
}
