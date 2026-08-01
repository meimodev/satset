import 'package:satset/data/services/firebase_admin_service.dart';

/// The venue subscription verdicts, shared by the fleet console (which shows
/// them to the super admin), the venue's own shell banner (which shows them to
/// the admin paying the bill), and the cutoff sweep (which acts on them).
///
/// They live here, beside [Venue], rather than in the fleet UI where they were
/// born, for one reason: the surfaces must never disagree about what "ending"
/// means. A console warning at fourteen days over a venue banner that starts at
/// seven is worse than either alone — it makes the operator's warning and the
/// customer's warning two different facts about one subscription. Same argument
/// the offline-grace countdown makes for reusing a single `staleAfter`.
///
/// Pure and `now`-taking so a test can pin them: these are the places on the
/// fleet surface where a wrong answer costs someone money, and since ADR-0076 a
/// wrong answer also takes a restaurant offline.

/// How far ahead of a paid-through date both surfaces start saying so. Two weeks
/// is an invoice's worth of notice — the console exists to bill a venue *before*
/// it lapses, and a warning that only fires on the lapse has already lost the
/// month it was meant to protect.
const fleetRenewWarn = Duration(days: 14);

/// How long a **partner** keeps trading past its term before the cutoff sweep
/// suspends it. Half [fleetRenewWarn], deliberately asymmetric: fourteen days of
/// banner before the date and seven after is three weeks of visible notice, and
/// a bank transfer that clears late in the week still lands in time.
///
/// A **trial** gets none of this. Going dark on the stated date is what a trial
/// is *for*, and a grace window would make the end date not the end date.
const fleetGraceAfterLapse = Duration(days: 7);

/// The moment a venue stops trading if nobody extends it — the date the console
/// and the venue banner both quote. Null when there is no term, which is why a
/// venue created before anyone set one sits idle rather than being cut off.
DateTime? venueCutoffAt(Venue v) {
  final until = v.paidUntil;
  if (until == null) return null;
  return v.isTrial ? until : until.add(fleetGraceAfterLapse);
}

/// True once the term is behind us, whatever the plan. Drives the *warning*
/// surfaces; the cutoff itself is [fleetCutoffDue].
bool fleetPaidUntilPassed(Venue v, DateTime now) {
  final until = v.paidUntil;
  return until != null && until.isBefore(now);
}

/// The subscription is in trouble: its term has run out. Since ADR-0076 deleted
/// `billingStatus` this is purely a date comparison, so the state that used to
/// hide here — `paid` with a `paidUntil` three weeks gone — cannot be expressed.
bool fleetBillingTrouble(Venue v, DateTime now) => fleetPaidUntilPassed(v, now);

/// The venue is past its cutoff and should not be trading. The sweep acts on
/// this; the venue editor disables `Aktifkan` on it, so an unpaid venue cannot
/// be turned back on without first being given a future date.
bool fleetCutoffDue(Venue v, DateTime now) {
  final at = venueCutoffAt(v);
  return at != null && at.isBefore(now);
}

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

/// Months actually charged on a yearly cycle. The discount *is* the reason the
/// yearly option exists, so it lives beside the predicates rather than being
/// re-derived on whichever surface happens to render a total.
const venueYearlyMonthsCharged = 10;

/// What the venue pays per billing cycle — one month's rate, or ten months' for
/// a year. Null when there is no agreed rate (a trial, or a partner nobody has
/// priced yet).
int? venuePriceTotal(Venue v) {
  final m = v.priceMonthly;
  if (m == null) return null;
  return v.isYearly ? m * venueYearlyMonthsCharged : m;
}
