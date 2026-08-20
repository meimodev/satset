// **[[Kedai]] mode** (ADR-0109) — the one key that reshapes the app, and the
// six switches it is made of.
//
// A mode key rides the same `addOns` array and the same mirrored CSV as a
// sellable [[Modul]], but it is read by the opposite rule, and *that* asymmetry
// is what this pins: `hasModule` fails **open** on a never-mirrored row so a
// cold boot cannot take a paid feature away, while `counterMode` fails
// **closed** on the very same row — because the fail-open that protects a
// purchase would silently turn every unmirrored restaurant into a counter shop.
// One null, two opposite answers, on purpose.
//
// The rest is one rule stated twice, once per reader: a switch is on only with
// **both halves**, so unticking the mode cannot leave half a shape standing,
// and the switches survive that unticking rather than being cleared — a mode
// ticked back on restores the operator's own choices (ADR-0107 §"freezes,
// never deletes").
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/domain/models/venue_module.dart';

void main() {
  // The floor's reader: what a screen on the device asks.
  group('the mirrored settings row', () {
    const settings = VenueSettingsDto();

    test('a never-mirrored row is a restaurant, not a counter shop', () {
      expect(settings.modules, isNull);
      expect(
        settings.hasModule(moduleMembers),
        isTrue,
        reason: 'a sellable module fails open — nothing may take it away',
      );
      expect(
        settings.counterMode,
        isFalse,
        reason: 'a mode fails closed — the same null, the opposite answer',
      );
      for (final k in counterSwitchKeys) {
        expect(settings.counterOn(k), isFalse, reason: k);
      }
    });

    test('a switch without the mode is half a shape, and stays off', () {
      final orphaned = settings.copyWith(
        modules: const [moduleMembers],
        counterConfig: counterSwitchKeys,
      );
      for (final k in counterSwitchKeys) {
        expect(orphaned.counterOn(k), isFalse, reason: k);
      }
    });

    test('the mode without a switch reshapes nothing', () {
      final bare = settings.copyWith(modules: const [modeCounterService]);
      expect(bare.counterMode, isTrue);
      for (final k in counterSwitchKeys) {
        expect(bare.counterOn(k), isFalse, reason: k);
      }
      expect(
        bare.copyWith(counterConfig: const []).counterOn(counterMenuHome),
        isFalse,
        reason: 'null and empty mean the same thing for a mode switch',
      );
    });

    test('both halves, one switch at a time', () {
      final on = settings.copyWith(
        modules: const [modeCounterService],
        counterConfig: const [counterSimpleKds],
      );
      expect(on.counterOn(counterSimpleKds), isTrue);
      for (final k in counterSwitchKeys.where((k) => k != counterSimpleKds)) {
        expect(on.counterOn(k), isFalse, reason: k);
      }
    });

    test('unticking the mode freezes the switches, it does not clear them', () {
      final on = settings.copyWith(
        modules: const [modeCounterService],
        counterConfig: const [counterQr, counterRingkasReport],
      );
      final off = on.copyWith(modules: const []);
      expect(off.counterOn(counterQr), isFalse);
      expect(
        off.counterConfig,
        on.counterConfig,
        reason: 'the stored choice must survive to come back',
      );
      expect(off.copyWith(modules: on.modules).counterOn(counterQr), isTrue);
    });
  });

  // The console's reader: what an operator's screen asks. Same rule, different
  // shape — a set of `addOns` rather than a mirrored CSV.
  group('the fleet console venue', () {
    Venue venue({
      Set<String> addOns = const {},
      Set<String> counterConfig = const {},
      String plan = venuePlanPartner,
    }) => Venue(
      id: 'v1',
      status: AdminStatus.active,
      name: 'Kedai',
      address: '',
      plan: plan,
      addOns: addOns,
      counterConfig: counterConfig,
      trialStartAt: null,
      paidUntil: null,
      priceMonthly: null,
      billingCycle: venueCycleMonthly,
      lastSeenAt: null,
      fromCache: false,
    );

    test('a switch set without the mode is off', () {
      final v = venue(counterConfig: counterSwitchKeys.toSet());
      for (final k in counterSwitchKeys) {
        expect(v.counterOn(k), isFalse, reason: k);
      }
    });

    test('the mode alone turns nothing on — there is no preset state', () {
      final v = venue(addOns: const {modeCounterService});
      expect(v.hasModule(modeCounterService), isTrue);
      for (final k in counterSwitchKeys) {
        expect(v.counterOn(k), isFalse, reason: k);
      }
    });

    test('both halves, and the plan never enters the answer', () {
      for (final plan in [venuePlanTrial, venuePlanPartner]) {
        final v = venue(
          plan: plan,
          addOns: const {modeCounterService},
          counterConfig: const {counterAnonTakeaway},
        );
        expect(v.counterOn(counterAnonTakeaway), isTrue, reason: plan);
        expect(v.counterOn(counterMenuHome), isFalse, reason: plan);
      }
    });

    test('a sellable module never opens a mode switch', () {
      final v = venue(
        addOns: const {moduleMembers, moduleSelfOrder},
        counterConfig: counterSwitchKeys.toSet(),
      );
      expect(v.hasModule(moduleMembers), isTrue);
      for (final k in counterSwitchKeys) {
        expect(v.counterOn(k), isFalse, reason: k);
      }
    });
  });
}
