import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/repositories/venue_subscription.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/venue_billing.dart';

/// What the venue's own shell banner says about its subscription, pinned.
///
/// The console and the venue read the same predicates on purpose, so the
/// interesting cases here are the boundaries where a *tier* is chosen — silence
/// vs warn vs alarm — plus the cutoff date the banner now quotes, which is the
/// only thing standing between a venue and finding out it is dark mid-service.
void main() {
  Venue venue({
    String plan = venuePlanPartner,
    DateTime? paidUntil,
    AdminStatus status = AdminStatus.active,
  }) => Venue(
    id: 'v1',
    status: status,
    name: 'Warung',
    address: '',
    plan: plan,
    addOns: const {},
    trialStartAt: null,
    paidUntil: paidUntil,
    priceMonthly: null,
    billingCycle: venueCycleMonthly,
    lastSeenAt: null,
    fromCache: false,
  );

  VenueBillingNotice? noticeFor(Venue? v) {
    final c = ProviderContainer(
      overrides: [venueCloudDocProvider.overrideWith((_) => v)],
    );
    addTearDown(c.dispose);
    return c.read(venueBillingNoticeProvider);
  }

  test('no venue doc yet — nothing to say', () {
    expect(noticeFor(null), isNull);
  });

  test('a healthy venue banners nothing', () {
    final v = venue(paidUntil: DateTime.now().add(const Duration(days: 90)));
    expect(noticeFor(v), isNull);
  });

  test('a venue with no end date is left alone', () {
    // The overwhelmingly common state for a new venue, and one that never
    // lapses. Bannering it would warn every trial customer on day one about
    // something that is not going to happen.
    expect(noticeFor(venue(plan: venuePlanTrial)), isNull);
  });

  test('inside the renewal window warns, and carries the remainder', () {
    final v = venue(paidUntil: DateTime.now().add(const Duration(days: 6)));
    final n = noticeFor(v)!;
    expect(n.tier, VenueBillingTier.ending);
    expect(n.remaining!.inDays, 5); // 6 days minus a few microseconds
  });

  test('a date already gone alarms', () {
    final v = venue(
      paidUntil: DateTime.now().subtract(const Duration(days: 2)),
    );
    expect(noticeFor(v)!.tier, VenueBillingTier.lapsed);
  });

  test('the notice quotes the day the venue stops, per plan', () {
    // The whole point of ADR-0076's banner change: a partner is told about the
    // grace window it actually gets, not about the date its term ended.
    final until = DateTime.now().subtract(const Duration(days: 2));
    expect(
      noticeFor(venue(paidUntil: until))!.cutoffAt,
      until.add(fleetGraceAfterLapse),
    );
    expect(
      noticeFor(venue(plan: venuePlanTrial, paidUntil: until))!.cutoffAt,
      until,
    );
  });

  test('lapsed outranks ending — never both at once', () {
    // One banner per subscription, and it is the louder one. Two notices about
    // one subscription is the drift the shared predicates exist to prevent.
    final v = venue(
      paidUntil: DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(noticeFor(v)!.tier, VenueBillingTier.lapsed);
    expect(noticeFor(v)!.remaining, isNull);
  });
}
