// **[[Tanpa antrian persiapan]]** (ADR-0115) — the venue with no prep queue.
//
// Two halves, and the first is the one a later edit will break. `bypassKds` is
// a **mode** key: it rides the same `addOns` array as a sellable [[Modul]] and
// is read by the opposite rule, and — unlike the six `counterConfig` switches
// — it is **not** ANDed with `counterService`. Folding it under counter mode is
// the tempting simplification and the wrong one: a counter shop may still run a
// cook line, and a small restaurant may have no queue.
//
// The second half is the branch itself. `submitOrder` writing `ready` instead
// of `sent` is the one place a mode reaches into a writer, which is exactly why
// it is pinned here rather than trusted to a comment.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/ticket_transitions.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/modules.dart';
import 'package:satset/server/routes/tickets_routes.dart';

void main() {
  group('the key itself', () {
    test('is a mode, not a sellable module', () {
      expect(venueModeKeys, contains(modeBypassKds));
      expect(
        venueModuleKeys,
        isNot(contains(modeBypassKds)),
        reason: 'a venue does not buy its own shape — the trial grant and the '
            'fail-open resolver both key off this split',
      );
      expect(venueEntitlementKeys, contains(modeBypassKds));
    });

    test('fails closed on a never-mirrored row, like every mode', () {
      const settings = VenueSettingsDto();
      expect(settings.modules, isNull);
      expect(
        settings.hasModule(moduleMembers),
        isTrue,
        reason: 'a sellable module fails open',
      );
      expect(
        settings.bypassKds,
        isFalse,
        reason: 'the same null, the opposite answer — fail-open here would '
            'boot every unmirrored restaurant with its KDS removed',
      );
      expect(
        settings.copyWith(modules: const []).bypassKds,
        isFalse,
        reason: 'empty is a real answer and it is still "no"',
      );
    });

    test('is independent of counter mode, in both directions', () {
      const base = VenueSettingsDto();
      final counterOnly = base.copyWith(
        modules: const [modeCounterService],
        counterConfig: counterSwitchKeys,
      );
      expect(counterOnly.counterMode, isTrue);
      expect(
        counterOnly.bypassKds,
        isFalse,
        reason: 'a counter shop may still run a cook line',
      );

      final bypassOnly = base.copyWith(modules: const [modeBypassKds]);
      expect(bypassOnly.bypassKds, isTrue);
      expect(
        bypassOnly.counterMode,
        isFalse,
        reason: 'a restaurant with one cook is not a counter shop',
      );
      for (final k in counterSwitchKeys) {
        expect(
          bypassOnly.counterOn(k),
          isFalse,
          reason: '$k still needs its own mode — this key does not stand in',
        );
      }
    });

    test('reads fail-closed on the server too, by the mode resolver', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      // No row at all — nothing is seeded yet.
      expect(
        venueHasModule(null, moduleMembers),
        isTrue,
        reason: 'an unknown row reads as entitled for a purchase',
      );
      expect(
        venueHasMode(null, modeBypassKds),
        isFalse,
        reason: 'and as unshaped for a mode',
      );

      await db
          .into(db.venueSettings)
          .insertOnConflictUpdate(
            VenueSettingsCompanion.insert(
              id: 'default',
              modules: const Value(modeBypassKds),
            ),
          );
      final row = await db.select(db.venueSettings).getSingle();
      expect(venueHasMode(row, modeBypassKds), isTrue);
      expect(
        venueHasModule(row, moduleMembers),
        isFalse,
        reason: 'a mirrored CSV is a real answer, and it does not list members',
      );
    });
  });

  // The born status is `ready` and not `served` because of this table: a
  // mis-key in a one-person shop must stay the waiter's own correction.
  group('the born status', () {
    test('leaves a void as a waiter act, which `served` would not', () {
      expect(
        capabilityForTransition(TicketStatus.ready, TicketStatus.voided),
        Capability.voidItem,
      );
      expect(
        capabilityForTransition(TicketStatus.served, TicketStatus.voided),
        Capability.compItem,
      );
      expect(
        capabilityForTransition(TicketStatus.ready, TicketStatus.served),
        Capability.takeOrder,
        reason: 'the handover tap already exists on the Pesanan board',
      );
      expect(
        canTransition(TicketStatus.sent, TicketStatus.served),
        isFalse,
        reason: 'the reason hiding the KDS alone is not an option: without the '
            'writer branch a `sent` line has no waiter-reachable way out',
      );
    });
  });

  group('submitOrder', () {
    late AppDatabase db;

    Future<void> seed({required bool bypass}) async {
      await db
          .into(db.venueSettings)
          .insertOnConflictUpdate(
            VenueSettingsCompanion.insert(
              id: 'default',
              modules: Value(bypass ? modeBypassKds : ''),
            ),
          );
      await db
          .into(db.venueTables)
          .insertOnConflictUpdate(
            VenueTablesCompanion.insert(
              id: 't1',
              zoneId: 'z1',
              label: const Value('T1'),
            ),
          );
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
      },
    ];

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('writes `sent` with the mode off, as it always has', () async {
      await seed(bypass: false);
      await submitOrder(db, tableId: 't1', idem: 'i1', lines: lines);
      final t = await db.select(db.tickets).getSingle();
      expect(t.status, 'sent');
      expect(t.readyAt, isNull);
    });

    test('writes `ready` with the mode on, stamped at send', () async {
      await seed(bypass: true);
      await submitOrder(db, tableId: 't1', idem: 'i1', lines: lines);
      final t = await db.select(db.tickets).getSingle();
      expect(t.status, 'ready');
      expect(
        t.readyAt,
        t.sentAt,
        reason: 'a line nobody queued has a prep clock of zero, not of '
            'unknown — a null readyAt ticks an elapsed pill forever',
      );
    });

    // `readyCount` and the `ready` table status are otherwise maintained only
    // by the transition route, which a born-`ready` line never enters.
    test('flips the table to ready, not pending', () async {
      await seed(bypass: true);
      await submitOrder(db, tableId: 't1', idem: 'i1', lines: lines);
      final t = await db.select(db.venueTables).getSingle();
      expect(t.status, 'ready');
      expect(
        t.readyCount,
        1,
        reason: 'the later `ready -> served` decrements this, and a count the '
            'submit never bumped strands the table on pending until settle',
      );
    });

    test('leaves the table pending with the mode off', () async {
      await seed(bypass: false);
      await submitOrder(db, tableId: 't1', idem: 'i1', lines: lines);
      final t = await db.select(db.venueTables).getSingle();
      expect(t.status, 'pending');
      expect(t.readyCount, 0);
    });

    test('the branch is the venue row, never the caller', () async {
      await seed(bypass: true);
      // A caller naming a status is the hole this shape exists to close: the
      // guest plane takes no bearer, so anything it could assert about a
      // ticket's status would be asserted by a stranger's phone.
      await submitOrder(
        db,
        tableId: 't1',
        idem: 'i1',
        lines: [
          {...lines.first, 'status': 'sent'},
        ],
      );
      final t = await db.select(db.tickets).getSingle();
      expect(t.status, 'ready');
    });
  });
}
