import 'package:satset/data/services/firebase_admin_service.dart';

/// The venue subscription verdicts, shared by the fleet console (which shows
/// them to the super admin) and the venue's own shell banner (which shows them
/// to the admin paying the bill).
///
/// They live here, beside [Venue], rather than in the fleet UI where they were
/// born, for one reason: the two surfaces must never disagree about what
/// "ending" means. A console warning at fourteen days over a venue banner that
/// starts at seven is worse than either alone — it makes the operator's warning
/// and the customer's warning two different facts about one subscription. Same
/// argument the offline-grace countdown makes for reusing a single `staleAfter`.
///
/// Pure and `now`-taking so a test can pin them: these are the places on the
/// fleet surface where a wrong answer costs someone money.

/// How far ahead of a paid-through date both surfaces start saying so. Two weeks
/// is an invoice's worth of notice — the console exists to bill a venue *before*
/// it lapses, and a warning that only fires on the lapse has already lost the
/// month it was meant to protect.
const fleetRenewWarn = Duration(days: 14);

/// True once the paid-through date is behind us, whatever the flag says.
bool fleetPaidUntilPassed(Venue v, DateTime now) {
  final until = v.paidUntil;
  return until != null && until.isBefore(now);
}

/// Overdue, or "paid" with a `paidUntil` that has already passed — the second is
/// the one nobody notices, because the flag still says paid.
bool fleetBillingTrouble(Venue v, DateTime now) =>
    v.billingStatus == 'overdue' || fleetPaidUntilPassed(v, now);

/// Time left on the subscription, once inside [fleetRenewWarn] and still ahead
/// of us. Null when there is no date, when it is further out than the window,
/// or when it has already passed — a lapsed date belongs to
/// [fleetBillingTrouble], and reporting it here as well would put a warning and
/// an alarm on the same row saying the same thing.
Duration? fleetSubscriptionEnding(Venue v, DateTime now) {
  final until = v.paidUntil;
  if (until == null) return null;
  final left = until.difference(now);
  return left > Duration.zero && left <= fleetRenewWarn ? left : null;
}
