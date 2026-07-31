import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/ui/features/fleet/_fleet_widgets.dart';

/// The fleet console's sort order and its billing verdict, pinned. Both are
/// money paths: the sort decides which venue the super admin sees first, and
/// the verdict decides whether a venue that stopped paying still looks fine.
void main() {
  final now = DateTime(2026, 7, 31, 12);

  Venue venue({
    String name = 'Warung',
    AdminStatus status = AdminStatus.active,
    String billingStatus = 'paid',
    DateTime? paidUntil,
    DateTime? lastSeenAt,
  }) => Venue(
    id: name,
    status: status,
    name: name,
    address: '',
    plan: 'free',
    billingStatus: billingStatus,
    paidUntil: paidUntil,
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
      expect(fleetLockoutRisk(venue(lastSeenAt: last), now),
          const Duration(hours: 10));
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
    test('an overdue flag is trouble', () {
      expect(fleetBillingTrouble(venue(billingStatus: 'overdue'), now), isTrue);
    });

    test('paid with a future date is not', () {
      expect(
        fleetBillingTrouble(
          venue(paidUntil: now.add(const Duration(days: 30))),
          now,
        ),
        isFalse,
      );
    });

    test('paid with a date already gone is trouble — the silent case', () {
      expect(
        fleetBillingTrouble(
          venue(paidUntil: now.subtract(const Duration(days: 3))),
          now,
        ),
        isTrue,
      );
    });

    test('trial with no date is left alone', () {
      expect(fleetBillingTrouble(venue(billingStatus: 'trial'), now), isFalse);
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
      expect(
        fleetAddMonths(DateTime(2026, 1, 31), 1),
        DateTime(2026, 2, 28),
      );
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
    Venue unpaid() => venue(name: 'unpaid', billingStatus: 'overdue');
    Venue expiring() =>
        venue(name: 'expiring', paidUntil: now.add(const Duration(days: 5)));
    Venue killed() =>
        venue(name: 'killed', status: AdminStatus.suspended);
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
          final r = fleetUrgencyRank(a, now).compareTo(fleetUrgencyRank(b, now));
          return r != 0 ? r : a.name.compareTo(b.name);
        });
      // 'healthy' sorts before 'unpaid' alphabetically — rank has to win.
      expect(rows.first.name, 'unpaid');
    });

    test('a lockout beats unpaid even when the venue is also unpaid', () {
      final both = venue(
        name: 'both',
        billingStatus: 'overdue',
        lastSeenAt: now.subtract(
          FirebaseAdminService.staleAfter + const Duration(hours: 1),
        ),
      );
      expect(fleetUrgencyRank(both, now), 0);
    });
  });
}
