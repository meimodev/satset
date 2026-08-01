import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/core/time/sat_clock.dart';

import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/venue_billing.dart';

/// The venue's own cloud document, as last delivered by the live
/// `venues/{vid}` listener the auth repository already holds (see
/// `_startEligibilityWatch`). Null on a Client device, on a super admin, and
/// before the first snapshot lands.
///
/// Written by that listener rather than by a second `snapshots()` call of its
/// own: the billing fields were always arriving at the device and being thrown
/// away. Publishing what already comes down costs no extra read, and Firestore's
/// cache keeps serving it offline exactly as it does the kill switch.
///
/// It also re-fires on its own: the host's 60s heartbeat rewrites `lastSeenAt`,
/// which re-emits this snapshot, so anything derived from it re-evaluates
/// against the clock every minute without a timer. See the note beside
/// `_venueSub` in `auth_repository.dart`.
final venueCloudDocProvider = StateProvider<Venue?>((_) => null);

/// How loudly the venue should be told about its subscription.
enum VenueBillingTier {
  /// Inside [fleetRenewWarn] and still ahead of us. Warn, not alarm: nothing is
  /// broken yet and service is unaffected.
  ending,

  /// The term has run out. Since ADR-0076 this is a countdown rather than a
  /// state — the venue keeps trading until [VenueBillingNotice.cutoffAt], and
  /// then it does not.
  lapsed,
}

/// What the venue's shell banner should say, or null for "say nothing".
///
/// Null is the overwhelmingly common case, and deliberately so: a venue in good
/// standing, a trial with no end date, and a subscription more than a fortnight
/// out all render nothing at all.
class VenueBillingNotice {
  final VenueBillingTier tier;
  final DateTime? paidUntil;

  /// Time left, on [VenueBillingTier.ending] only.
  final Duration? remaining;

  /// The day the venue stops serving if nobody renews — the trial's end date,
  /// or a partner's term plus [fleetGraceAfterLapse].
  ///
  /// Carried on the notice because the banner now **names** it. ADR-0074 forbade
  /// that as a threat the code could not carry out; ADR-0076 made it true, and a
  /// venue cut off without ever being told the date would be ADR-0074's own
  /// failure case arriving from the other direction.
  final DateTime? cutoffAt;

  const VenueBillingNotice({
    required this.tier,
    required this.paidUntil,
    required this.remaining,
    required this.cutoffAt,
  });
}

/// Derives the notice from the live venue doc.
///
/// **Reads the same predicates the fleet console ranks on**, so the warning the
/// super admin sees and the warning the venue sees can never be about different
/// things. Since ADR-0076 that includes the cutoff: the console quotes the day
/// the sweep will act, and so does this. See CONTEXT.md "Subscription cutoff".
final venueBillingNoticeProvider = Provider<VenueBillingNotice?>((ref) {
  final v = ref.watch(venueCloudDocProvider);
  if (v == null) return null;
  final now = SatClock.now();

  if (fleetBillingTrouble(v, now)) {
    return VenueBillingNotice(
      tier: VenueBillingTier.lapsed,
      paidUntil: v.paidUntil,
      remaining: null,
      cutoffAt: venueCutoffAt(v),
    );
  }
  if (fleetSubscriptionEnding(v, now) case final left?) {
    return VenueBillingNotice(
      tier: VenueBillingTier.ending,
      paidUntil: v.paidUntil,
      remaining: left,
      cutoffAt: venueCutoffAt(v),
    );
  }
  return null;
});
