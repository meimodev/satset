import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/ui/features/fleet/_fleet_widgets.dart';

/// The fleet console's sort order and its billing verdicts, pinned. All money
/// paths: the sort decides which venue the super admin sees first, the verdict
/// decides whether a venue that stopped paying still looks fine, and since
/// ADR-0076 the cutoff decides when one actually stops trading.
void main() {
  final now = DateTime(2026, 7, 31, 12);

  Venue venue({
    String name = 'Warung',
    AdminStatus status = AdminStatus.active,
    String plan = venuePlanPartner,
    DateTime? trialStartAt,
    DateTime? paidUntil,
    int? priceMonthly,
    String billingCycle = venueCycleMonthly,
    DateTime? lastSeenAt,
  }) => Venue(
    id: name,
    status: status,
    name: name,
    address: '',
    plan: plan,
    trialStartAt: trialStartAt,
    paidUntil: paidUntil,
    priceMonthly: priceMonthly,
    billingCycle: billingCycle,
    lastSeenAt: lastSeenAt,
    fromCache: false,
  );

  group('lockout risk', () {
    test('a venue that never checked in has no risk to report', () {
      expect(fleetLockoutRisk(venue(), now), isNull);
    });

    test('stays quiet outside the warning window', () {
      // Seen an hour ago: six days of grace left, nothing to say.
      expect(
        fleetLockoutRisk(
          venue(lastSeenAt: now.subtract(const Duration(hours: 1))),
          now,
        ),
        isNull,
      );
    });

    test('reports the remainder once inside the window', () {
      final last = now.subtract(
        FirebaseAdminService.staleAfter - const Duration(hours: 10),
      );
      expect(
        fleetLockoutRisk(venue(lastSeenAt: last), now),
        const Duration(hours: 10),
      );
    });

    test('goes negative past the limit rather than clamping', () {
      final last = now.subtract(
        FirebaseAdminService.staleAfter + const Duration(hours: 5),
      );
      expect(
        fleetLockoutRisk(venue(lastSeenAt: last), now),
        lessThan(Duration.zero),
      );
    });
  });

  group('billing trouble', () {
    test('a future date is not trouble', () {
      expect(
        fleetBillingTrouble(
          venue(paidUntil: now.add(const Duration(days: 30))),
          now,
        ),
        isFalse,
      );
    });

    test('a date already gone is trouble', () {
      expect(
        fleetBillingTrouble(
          venue(paidUntil: now.subtract(const Duration(days: 3))),
          now,
        ),
        isTrue,
      );
    });

    test('no date at all is left alone', () {
      // The overwhelmingly common state for a venue nobody has termed yet.
      expect(fleetBillingTrouble(venue(), now), isFalse);
    });
  });

  group('cutoff', () {
    test('a trial is cut off on its end date, with no grace', () {
      final v = venue(
        plan: venuePlanTrial,
        paidUntil: now.subtract(const Duration(hours: 1)),
      );
      expect(venueCutoffAt(v), v.paidUntil);
      expect(fleetCutoffDue(v, now), isTrue);
    });

    test('a partner keeps trading through the grace window', () {
      final v = venue(paidUntil: now.subtract(const Duration(days: 3)));
      // Lapsed, and the operator should be chasing it — but not dark yet.
      expect(fleetBillingTrouble(v, now), isTrue);
      expect(fleetCutoffDue(v, now), isFalse);
    });

    test('a partner is cut off once the grace window closes', () {
      final v = venue(
        paidUntil: now.subtract(fleetGraceAfterLapse + const Duration(days: 1)),
      );
      expect(fleetCutoffDue(v, now), isTrue);
    });

    test('a term-less venue never lapses and is never cut off', () {
      // Otherwise a venue created before anyone set a term goes dark on the
      // sweep's first pass after it was made.
      expect(venueCutoffAt(venue()), isNull);
      expect(fleetCutoffDue(venue(), now), isFalse);
    });
  });

  group('price', () {
    test('a yearly partner is charged ten months, not twelve', () {
      final v = venue(priceMonthly: 250000, billingCycle: venueCycleYearly);
      expect(venuePriceTotal(v), 2500000);
    });

    test('a monthly partner is charged its rate', () {
      expect(venuePriceTotal(venue(priceMonthly: 250000)), 250000);
    });

    test('an unpriced venue has no total, which is not the same as zero', () {
      expect(venuePriceTotal(venue()), isNull);
    });
  });

  group('subscription ending', () {
    test('a venue with no paid-through date has nothing to renew', () {
      expect(fleetSubscriptionEnding(venue(), now), isNull);
    });

    test('stays quiet while the term is comfortably ahead', () {
      expect(
        fleetSubscriptionEnding(
          venue(paidUntil: now.add(const Duration(days: 45))),
          now,
        ),
        isNull,
      );
    });

    test('reports the remainder once inside the renewal window', () {
      expect(
        fleetSubscriptionEnding(
          venue(paidUntil: now.add(const Duration(days: 5))),
          now,
        ),
        const Duration(days: 5),
      );
    });

    test('a date already gone is billing trouble, not a renewal notice', () {
      // Both would otherwise fire, putting a warn pill and an urgent pill on
      // the same row saying the same thing.
      final lapsed = venue(paidUntil: now.subtract(const Duration(days: 2)));
      expect(fleetSubscriptionEnding(lapsed, now), isNull);
      expect(fleetBillingTrouble(lapsed, now), isTrue);
    });
  });

  group('add months', () {
    test('does not let the day of month run into the next one', () {
      expect(fleetAddMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    });

    test('keeps the day when the target month is long enough', () {
      expect(fleetAddMonths(DateTime(2026, 1, 15), 3), DateTime(2026, 4, 15));
    });

    test('rolls the year over', () {
      expect(fleetAddMonths(DateTime(2026, 7, 31), 12), DateTime(2027, 7, 31));
    });
  });

  group('urgency rank', () {
    Venue lockedOut() => venue(
      name: 'lockedOut',
      lastSeenAt: now.subtract(
        FirebaseAdminService.staleAfter + const Duration(hours: 1),
      ),
    );
    Venue nearingLockout() => venue(
      name: 'nearing',
      lastSeenAt: now.subtract(
        FirebaseAdminService.staleAfter - const Duration(hours: 6),
      ),
    );
    Venue unpaid() =>
        venue(name: 'unpaid', paidUntil: now.subtract(const Duration(days: 2)));
    Venue expiring() =>
        venue(name: 'expiring', paidUntil: now.add(const Duration(days: 5)));
    Venue killed() => venue(name: 'killed', status: AdminStatus.suspended);
    Venue healthy() => venue(name: 'healthy');

    test('orders the kinds of trouble', () {
      expect(
        [
          fleetUrgencyRank(lockedOut(), now),
          fleetUrgencyRank(nearingLockout(), now),
          fleetUrgencyRank(unpaid(), now),
          fleetUrgencyRank(expiring(), now),
          fleetUrgencyRank(killed(), now),
          fleetUrgencyRank(healthy(), now),
        ],
        [0, 1, 2, 3, 4, 5],
      );
    });

    test('an unsent invoice outranks a suspension nobody owes anything on', () {
      expect(
        fleetUrgencyRank(expiring(), now),
        lessThan(fleetUrgencyRank(killed(), now)),
      );
    });

    test('an unpaid venue outranks a healthy one whatever its name', () {
      final rows = [healthy(), unpaid()]
        ..sort((a, b) {
          final r = fleetUrgencyRank(
            a,
            now,
          ).compareTo(fleetUrgencyRank(b, now));
          return r != 0 ? r : a.name.compareTo(b.name);
        });
      // 'healthy' sorts before 'unpaid' alphabetically — rank has to win.
      expect(rows.first.name, 'unpaid');
    });

    test('a lockout beats unpaid even when the venue is also unpaid', () {
      final both = venue(
        name: 'both',
        paidUntil: now.subtract(const Duration(days: 2)),
        lastSeenAt: now.subtract(
          FirebaseAdminService.staleAfter + const Duration(hours: 1),
        ),
      );
      expect(fleetUrgencyRank(both, now), 0);
    });
  });

  group('one active admin per venue (ADR-0077)', () {
    AdminProfile principal({
      required String uid,
      AdminRole role = AdminRole.admin,
      AdminStatus status = AdminStatus.active,
    }) => AdminProfile(
      uid: uid,
      status: status,
      role: role,
      name: uid,
      venueId: 'v1',
      avatarColorHex: null,
      fromCache: false,
    );

    test('an empty venue leaves the seat open', () {
      expect(fleetActiveAdmins(const <AdminProfile>[]), 0);
    });

    test('one active admin fills the seat', () {
      expect(fleetActiveAdmins([principal(uid: 'a')]), 1);
    });

    test('a suspended admin frees the seat, so handover needs no delete', () {
      final rows = [principal(uid: 'a', status: AdminStatus.suspended)];
      expect(fleetActiveAdmins(rows), 0);
    });

    test('owners never occupy the seat, however many there are', () {
      final rows = [
        principal(uid: 'o1', role: AdminRole.owner),
        principal(uid: 'o2', role: AdminRole.owner),
      ];
      expect(fleetActiveAdmins(rows), 0);
    });

    test('an owner alongside the admin still leaves exactly one', () {
      final rows = [
        principal(uid: 'a'),
        principal(uid: 'o1', role: AdminRole.owner),
      ];
      expect(fleetActiveAdmins(rows), 1);
    });

    test('a venue predating the cap reads as over it, not as one', () {
      final rows = [principal(uid: 'a'), principal(uid: 'b')];
      // Two is what raises the warning; nothing is auto-suspended.
      expect(fleetActiveAdmins(rows), 2);
    });

    test('an unknown status does not sneak into the count', () {
      // `status: banned` from a pre-ADR-0076 doc parses to unknown and fails
      // isActive everywhere else — it must not hold the seat either.
      final rows = [principal(uid: 'a', status: AdminStatus.unknown)];
      expect(fleetActiveAdmins(rows), 0);
    });
  });
}
