import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/domain/models/venue_module.dart';

/// `Venue.hasModule` is the single read rule for [[Modul]] entitlement, and
/// since ADR-0108 **the plan does not enter it**.
///
/// This exists because nothing pinned the rule before, which is how
/// `isTrial ||` lived inside it long enough to make the console's trial toggles
/// decorative. The asserts are three lines; a plan branch reappearing in
/// `hasModule` fails here rather than on a sales call.
void main() {
  Venue venue({required String plan, Set<String> addOns = const {}}) => Venue(
    id: 'v1',
    status: AdminStatus.active,
    name: 'Warung',
    address: '',
    plan: plan,
    addOns: addOns,
    trialStartAt: plan == venuePlanTrial ? DateTime(2026, 8) : null,
    paidUntil: null,
    priceMonthly: null,
    billingCycle: venueCycleMonthly,
    lastSeenAt: null,
    fromCache: false,
  );

  test('a trial holding nothing holds nothing', () {
    final v = venue(plan: venuePlanTrial);
    expect(v.isTrial, isTrue);
    for (final k in venueModuleKeys) {
      expect(v.hasModule(k), isFalse, reason: k);
    }
  });

  test('a trial holds exactly what it was given', () {
    final v = venue(plan: venuePlanTrial, addOns: const {moduleMembers});
    expect(v.hasModule(moduleMembers), isTrue);
    expect(v.hasModule(moduleSelfOrder), isFalse);
  });

  test('the plan never changes the answer', () {
    for (final addOns in [
      const <String>{},
      const {moduleMembers},
      const {moduleMembers, moduleSelfOrder},
    ]) {
      for (final k in venueModuleKeys) {
        expect(
          venue(plan: venuePlanTrial, addOns: addOns).hasModule(k),
          venue(plan: venuePlanPartner, addOns: addOns).hasModule(k),
          reason: 'plan disagreed on $k for $addOns',
        );
      }
    }
  });

  test('an unknown key is not held, whatever the plan', () {
    expect(
      venue(plan: venuePlanTrial, addOns: const {moduleMembers})
          .hasModule('reservations'),
      isFalse,
    );
  });
}
