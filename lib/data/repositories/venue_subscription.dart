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

  /// Overdue, or paid-through with a date already behind us. The second is the
  /// one nobody notices, because the flag still says paid.
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

  const VenueBillingNotice({
    required this.tier,
    required this.paidUntil,
    required this.remaining,
  });
}

/// Derives the notice from the live venue doc.
///
/// **Reads the same two predicates the fleet console ranks on**, so the warning
/// the super admin sees and the warning the venue sees can never be about
/// different things. Enforcement is deliberately absent: billing is independent
/// of the kill switch, and only an explicit `setVenueStatus` stops a venue
/// trading. See CONTEXT.md "Venue billing" and ADR-0074.
final venueBillingNoticeProvider = Provider<VenueBillingNotice?>((ref) {
  final v = ref.watch(venueCloudDocProvider);
  if (v == null) return null;
  final now = SatClock.now();

  if (fleetBillingTrouble(v, now)) {
    return VenueBillingNotice(
      tier: VenueBillingTier.lapsed,
      paidUntil: v.paidUntil,
      remaining: null,
    );
  }
  if (fleetSubscriptionEnding(v, now) case final left?) {
    return VenueBillingNotice(
      tier: VenueBillingTier.ending,
      paidUntil: v.paidUntil,
      remaining: left,
    );
  }
  return null;
});
