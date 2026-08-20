// **[[Modul]]** — the à-la-carte entitlement set (ADR-0107).
//
// What is actually being pinned:
//
//   - unknown fails **open**: a settings row that has never been mirrored (null
//     `modules`) holds every module, so a schema migration or a cold boot cannot
//     take a paid-for feature off a venue;
//   - `''` is a *different* answer from null — mirrored, and holds nothing;
//   - entitlement and preference are two facts composed with AND, so the four
//     combinations of `membersEnabled` × module are four distinct outcomes and
//     turning the module back on restores the owner's own choice;
//   - the guest plane's `enabled` obeys the module too, which is what keeps the
//     cleartext socket from binding for a venue that never bought it;
//   - and the member routes 404 on an unentitled venue exactly as they do on one
//     that switched membership off — not 403, because a venue that did not buy
//     the feature must be indistinguishable from a server that never had it.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/server/db/database.dart';
import 'package:satset/server/members.dart';
import 'package:satset/server/modules.dart';
import 'package:satset/server/self_order.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:satset/server/routes/members_routes.dart';
import 'package:shelf/shelf.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Seeds the row both features read. [modules] is deliberately a `Value` so a
  /// test can express "never mirrored" (absent) apart from "holds nothing" ('').
  Future<void> settings({
    bool members = true,
    bool guest = true,
    Value<String?> modules = const Value.absent(),
  }) => db
      .into(db.venueSettings)
      .insertOnConflictUpdate(
        VenueSettingsCompanion.insert(
          id: 'default',
          membersEnabled: Value(members),
          guestOrderingEnabled: Value(guest),
          modules: modules,
        ),
      );

  Future<VenueSetting?> row() => (db.select(
    db.venueSettings,
  )..where((v) => v.id.equals('default'))).getSingleOrNull();

  group('splitModules / joinModules', () {
    test('null, empty and whitespace all mean no modules', () {
      expect(splitModules(null), isEmpty);
      expect(splitModules(''), isEmpty);
      expect(splitModules('  ,  ,'), isEmpty);
    });

    test('round-trips, trimming and de-duplicating', () {
      expect(splitModules(' members , selfOrder ,members'), {
        moduleMembers,
        moduleSelfOrder,
      });
      expect(
        joinModules([' selfOrder', 'members', 'members']),
        'members,selfOrder',
      );
    });

    test('joins sorted, so a re-order never reads as a change', () {
      expect(
        joinModules([moduleSelfOrder, moduleMembers]),
        joinModules([moduleMembers, moduleSelfOrder]),
      );
    });
  });

  group('venueHasModule', () {
    test('no settings row at all reads as entitled', () {
      expect(venueHasModule(null, moduleMembers), isTrue);
    });

    test(
      'never mirrored (null) reads as entitled — the upgrade case',
      () async {
        await settings();
        expect(
          await row().then((r) => venueHasModule(r, moduleMembers)),
          isTrue,
        );
        expect(
          await row().then((r) => venueHasModule(r, moduleSelfOrder)),
          isTrue,
        );
      },
    );

    test('mirrored-and-empty is a real answer: holds nothing', () async {
      await settings(modules: const Value(''));
      expect(
        await row().then((r) => venueHasModule(r, moduleMembers)),
        isFalse,
      );
    });

    test('holds exactly what was mirrored', () async {
      await settings(modules: const Value(moduleMembers));
      final r = await row();
      expect(venueHasModule(r, moduleMembers), isTrue);
      expect(venueHasModule(r, moduleSelfOrder), isFalse);
    });
  });

  group('entitlement AND preference', () {
    test('members: four combinations, four outcomes', () async {
      await settings(members: true, modules: const Value(moduleMembers));
      expect((await memberConfig(db)).enabled, isTrue);

      await settings(members: false, modules: const Value(moduleMembers));
      expect(
        (await memberConfig(db)).enabled,
        isFalse,
        reason: 'owner said no',
      );

      await settings(members: true, modules: const Value(''));
      expect((await memberConfig(db)).enabled, isFalse, reason: 'not entitled');

      await settings(members: false, modules: const Value(''));
      expect((await memberConfig(db)).enabled, isFalse);
    });

    test(
      're-entitling restores the owner choice rather than a default',
      () async {
        // The venue wants membership and loses the module, then gets it back.
        await settings(members: true, modules: const Value(moduleMembers));
        await settings(members: true, modules: const Value(''));
        expect((await memberConfig(db)).enabled, isFalse);
        await settings(members: true, modules: const Value(moduleMembers));
        expect(
          (await memberConfig(db)).enabled,
          isTrue,
          reason: 'the preference was never written off',
        );
      },
    );

    test('self-order: the module gates the plane', () async {
      await settings(guest: true, modules: const Value(moduleSelfOrder));
      expect((await guestRules(db)).enabled, isTrue);

      await settings(guest: true, modules: const Value(moduleMembers));
      expect(
        (await guestRules(db)).enabled,
        isFalse,
        reason: 'holding one module does not hold the other',
      );
    });
  });

  group('the member routes', () {
    Future<int> getMembers() async {
      final caller = await signInForTest(db);
      final router = membersRoutes(db, WsHub(), caller.auth);
      final res = await router.call(
        Request('GET', Uri.parse('http://x/members'), headers: caller.headers),
      );
      return res.statusCode;
    }

    test('answer on an entitled venue that wants membership', () async {
      await settings(members: true, modules: const Value(moduleMembers));
      expect(await getMembers(), 200);
    });

    test('404 when the venue holds no module', () async {
      await settings(members: true, modules: const Value(''));
      expect(
        await getMembers(),
        404,
        reason: 'not 403 — an unlicensed venue looks like an old server',
      );
    });

    test('404 when the owner switched membership off', () async {
      await settings(members: false, modules: const Value(moduleMembers));
      expect(await getMembers(), 404);
    });
  });

  // The floor half of the same rule (ADR-0107 §6): a till affordance reads the
  // owner's switch AND the entitlement, or an unentitled venue keeps a button
  // that 404s.
  group('the client-side gate', () {
    test('needs both halves, and fails open before the first mirror', () {
      const on = VenueSettingsDto(
        membersEnabled: true,
        guestOrderingEnabled: true,
      );
      expect(on.membersOn, isTrue, reason: 'modules null = never mirrored');
      expect(on.copyWith(modules: const []).membersOn, isFalse);
      expect(on.copyWith(modules: const ['members']).membersOn, isTrue);
      expect(on.copyWith(modules: const ['members']).guestOrderingOn, isFalse);
      expect(
        on
            .copyWith(membersEnabled: false, modules: const ['members'])
            .membersOn,
        isFalse,
        reason: 'entitled but switched off is still off',
      );
    });
  });
}
