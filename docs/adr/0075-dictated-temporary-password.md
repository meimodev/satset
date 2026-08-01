# ADR-0075 — Password reset is a dictated temporary password

**Status:** Accepted
**Date:** 2026-08-01
**Amends:** [ADR-0016](0016-fleet-superadmin-cloud-control-plane.md) (fleet console)

## Context

The fleet console's "Reset password" action called
`auth.generatePasswordResetLink(email)` and returned the link to the client.

That link went nowhere. `generatePasswordResetLink` **mints** a URL; it does not
send anything. This project has no mail extension, no SMTP credentials and two
dependencies in `functions/package.json`. The link arrived at the app, was
dropped on the floor by a caller typed `Future<void>`, and the operator got a
toast reading *"Link reset dibuat"*.

So the one non-destructive account-recovery path in the product was a no-op end
to end. An admin who forgot their password had exactly one route back in: the
super admin deleted the account and made a new one.

Meanwhile `pin_screen.dart`'s own "Lupa password?" already tells the truth about
how this business runs — it opens WhatsApp to the developer. Recovery here has
always been a phone call. The code just did not admit it.

## Decision

**Reset mints an eight-digit temporary password for the operator to dictate, and
the app forces it to be replaced on first use.**

1. `resetAdminPassword` takes a `uid` (not an email — a mutable string is one
   typo away from resetting the wrong venue's admin), sets a random 8-digit
   password via `crypto.randomInt`, and stamps
   `{mustChangePassword: true, passwordResetAt: serverTimestamp()}`. It returns
   the digits **once**. The audit row records the email and the fact, never the
   code.
2. The console shows it in a dialog sized to be read aloud, with copy and a
   WhatsApp share, and says plainly that it will not be shown again.
3. `signInAsAdmin` checks `mustChangePassword` **before every divert and before
   `bootServer`** — ahead of the super/owner branches, the eligibility read, the
   venue kill switch and the mDNS host lookup. A credential that travelled by
   voice buys exactly one thing: the right to replace itself.
4. `changeOwnPassword` sets the new password and clears the flag in one
   callable, guarded on *authenticated and owns the account* rather than
   `assertSuper` — here the caller is the subject, not the operator. The app then
   re-runs `signInAsAdmin` with the new password so the whole gauntlet fires
   normally.
5. `sweepExpiredTempPasswords` runs hourly and re-randomizes any code older than
   24 hours, so it is dead at Firebase and not merely refused by this client. The
   app compares the same timestamp during sign-in, which closes the gap between
   a code expiring and the sweep next waking.

## Consequences

**The action does something.** An admin who forgets their password now gets back
in without their account being deleted and rebuilt, which is what the reset
button always claimed to offer.

**Two enforcement points, deliberately not one.** The sweep is the real
expiry — it removes the credential. The app-side comparison exists because the
sweep runs on a schedule, and an hour of grace on a spoken password is an hour
too many. `FirebaseAdminService.otpTtl` and `OTP_TTL_MS` must stay equal; a test
pins the Dart half and names the JS constant.

**A temporary password never starts a restaurant.** Because the gate precedes
`bootServer`, and because `evaluateForBoot` refuses the same state at cold start,
there is no path where a dictated code ends with an embedded server running and a
local admin JWT minted.

**The Firebase session survives the gate.** Every other rejection in the gauntlet
signs out; this one does not, because `changeOwnPassword` is authorized by the
token that sign-in just minted. What that session can reach is bounded by
`firestore.rules` to the admin's own doc and one heartbeat field — no local
session, no server, no fleet reads.

**The operator holds a live credential for as long as the call takes.** That is
the accepted cost of having no mail sender. It is bounded by the 24-hour term, by
being useless without the email, and by the forced change that invalidates it the
moment it is used.

**A super admin cannot be reset through this.** The callable refuses
`role == 'super'`: a fleet operator resetting another fleet operator locks the
console for whoever is not holding the phone. Seeded by hand, recovered by hand.

**`createAdmin` is untouched.** A newly created account also carries a password
the operator dictates, and arguably deserves the same forced change. It writes
`mustChangePassword: false` explicitly for now (the sweep queries the field, and
a document missing it is invisible to that query), leaving the flip as a
one-line change if wanted.

## Alternatives rejected

**Send a real reset email** via the Trigger Email extension or nodemailer.
Correct in the abstract, and the only option where the operator never touches the
credential. Rejected for now: SMTP credentials in function config, deliverability
to Indonesian consumer inboxes, and a second deploy surface — for a fleet that
today has a handful of venues and an operator already on the phone with each one.

**Show the reset link instead of a code.** Half the work, keeps Firebase's own
expiry. Rejected because a URL cannot be read down a phone line, which is the
actual delivery channel.

**Drop the action entirely** and rely on delete-and-recreate. Honest and the
smallest diff, but it makes a forgotten password destroy an account.

**No expiry.** Simplest, and kinder to a venue admin who is next on shift
Thursday. Rejected: a credential that was spoken aloud and never dies is not
temporary, and the operator would have no way to revoke it short of resetting
again.

**App-side expiry only**, no scheduled sweep. Avoids Cloud Scheduler. Rejected
because the refusal would be this client's alone — the password would still
authenticate against Firebase for any other caller.

**Force the change after the server boots**, so a venue reset mid-service keeps
trading. Rejected: the temporary password would have already booted a server and
minted a local admin JWT before it was ever proven to be in the right hands.
