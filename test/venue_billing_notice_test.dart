import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/repositories/venue_subscription.dart';
import 'package:satset/data/services/firebase_admin_service.dart';

/// What the venue's own shell banner says about its subscription, pinned.
///
/// The console and the venue read the same two predicates on purpose, so the
/// interesting cases here are the boundaries where a *tier* is chosen: silence
/// vs warn vs alarm, and the one state the console exists to catch — `paid` with
/// a date already gone, which looks healthy everywhere the flag is trusted.
void main() {
  Venue venue({
    String billingStatus = 'paid',
    DateTime? paidUntil,
    AdminStatus status = AdminStatus.active,
  }) => Venue(
    id: 'v1',
    status: status,
    name: 'Warung',
    address: '',
    plan: 'pro',
    billingStatus: billingStatus,
    paidUntil: paidUntil,
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

  test('a trial with no end date is left alone', () {
    // The overwhelmingly common state for a new venue. Bannering it would put a
    // warning in front of every trial customer on day one.
    expect(noticeFor(venue(billingStatus: 'trial')), isNull);
  });

  test('inside the renewal window warns, and carries the remainder', () {
    final v = venue(paidUntil: DateTime.now().add(const Duration(days: 6)));
    final n = noticeFor(v)!;
    expect(n.tier, VenueBillingTier.ending);
    expect(n.remaining!.inDays, 5); // 6 days minus a few microseconds
  });

  test('an overdue flag alarms even with no date at all', () {
    final n = noticeFor(venue(billingStatus: 'overdue'))!;
    expect(n.tier, VenueBillingTier.lapsed);
    expect(n.remaining, isNull);
  });

  test('paid with a date already gone alarms — the silent case', () {
    // The flag still reads `paid`, so every surface that trusts it shows a
    // healthy venue. This is the one the banner exists for.
    final v = venue(paidUntil: DateTime.now().subtract(const Duration(days: 2)));
    final n = noticeFor(v)!;
    expect(n.tier, VenueBillingTier.lapsed);
  });

  test('lapsed outranks ending — never both at once', () {
    // A date inside the window AND an overdue flag: one banner, and it is the
    // louder one. Two notices about one subscription is the drift the shared
    // predicates exist to prevent.
    final v = venue(
      billingStatus: 'overdue',
      paidUntil: DateTime.now().add(const Duration(days: 3)),
    );
    expect(noticeFor(v)!.tier, VenueBillingTier.lapsed);
  });
}
