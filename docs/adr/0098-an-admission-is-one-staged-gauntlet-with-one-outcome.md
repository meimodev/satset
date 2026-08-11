# ADR-0098 — An admission is one staged gauntlet with one outcome

Status: accepted
Date: 2026-08-11

## Context

Signing in as an admin is not one call. It is Firebase auth, then the admin
profile, then the eligibility verdict, then the venue's verdict, then the host
decision, then — in Server mode — booting the embedded server, then a local PIN
session against that server. Six network-shaped steps, four of which can say no
for four different reasons, on hardware standing in a restaurant whose Wi-Fi
router is a domestic box under the till.

The flow that grew around that shape leaked in two directions.

**It could stop and never resume.** Four places waited on a future with no
deadline and no way out. `ServerRuntime.boot` ran *before* `runApp`, so a held
port or a stalled TLS keygen produced no frame, no log on screen and no button
— only a force-kill. `restoring` gated a full-screen spinner and was set before
the one call that could throw ahead of the `try`, so a secure-storage failure
wedged the sign-in screen for the life of the process. Firebase's own calls had
no timeout, so a captive-portal Wi-Fi — associated, no route — spun until the
platform gave up minutes later. And the temporary-password path recursed:
`changeOwnPassword` clears `mustChangePassword` server-side, but the cache-first
Firestore read still reported the old value, so the change screen pushed itself
again, without limit.

**Its verdict arrived through four channels.** An outcome could be a `bool`
return, a string written into `AuthState.error`, a `hostOccupied` flag, or an
exception. Adding a reason meant picking a channel, and the screen had to read
all four to know what happened. The strings were composed in the repository,
against [ADR-0085](0085-an-audit-event-is-structured-not-a-sentence.md), which the
rest of the app had already moved off.

Two coupled state problems sat on top. The staff half tracked "where are we" in
three booleans that could disagree, and the sign-in mode toggle did not reach
`_rebuildServers`, so a staff member on a device that had once hosted the venue
got a PIN pad with no server behind it.

## Decision

**An admission is a single named operation returning a single sealed type.**
`AdmissionOutcome` (`domain/models/admission.dart`) has fifteen subclasses and
that set is closed: three admitted, one continuation, ten refusals, one cancel.
The exhaustive `switch` in `admission_text.dart` is where every one of them must
be named, so a new outcome does not compile until someone has decided what it
says. Nothing else returns a verdict — no flag, no error string, no exception
escaping as control flow.

**An outcome carries a code and its params, never a sentence.** Firebase's own
error code rides inside `AdmissionCredentialsRejected`; a block reason is an
`AdmissionBlock` enum. Wording is composed at read time in
`lib/core/localization/`, and every resolver falls through to the raw code so an
older row or a newer server never renders blank. This is
[ADR-0085](0085-an-audit-event-is-structured-not-a-sentence.md) applied to the one
flow that had not caught up.

**`AdmissionBlock` is declared in the domain, not imported from the data
layer.** `AdminStatus` lives beside the Firebase service, and a domain model
that imports it would invert the layering the whole app is built on. The
repository maps one to the other in one function.

**Every stage has a deadline, and the whole gauntlet has a second one.** Eight
seconds per network stage, twenty-five for the wall clock. The budget is not
the sum of the stages on purpose: it is the answer to *this is taking too long*,
which is a different question from *this call is hung*. A stage timeout becomes
`AdmissionUnreachable(stage)`; the stage name is logged, never shown, because
whichever call died the operator's next move is the same.

**Cancel is an attempt token, not a flag.** Firebase's future cannot be
cancelled. `_admissionAttempt` is bumped on submit and on cancel; a result
whose token is stale is dropped rather than written, and `signOut()` fires on
the way out. Without the token, cancel would be a lie — the gauntlet would run
to completion and mutate state under a screen that had moved on.

**The password change re-enters the admission once, and reads the profile
`serverOnly` on that pass.** Re-entering rather than resuming is deliberate:
eligibility, the venue kill switch and the host decision still have to happen in
one specific order, and exactly one function knows that order. The bound is
what is new, and the `serverOnly` read is what makes the second pass see the
flag the first pass cleared. A second `AdmissionNeedsNewPassword` is reported,
not looped on.

**Boot is bounded and its overrun is abandoned, not orphaned.** `main` gives
`ServerRuntime.boot` fifteen seconds and falls through to a `bootfailed` block
code the sign-in screen can render. A boot that lands after the deadline still
holds the port the next attempt needs, so it is shut down if it ever arrives.

**The staff half has one stage, and the toggle outranks the persisted mode.**
`StaffStage` (`pickingServer` | `connected` | `enteringPin`) replaces three
booleans; the screen never writes stage state of its own. `setMode` re-enters
`_rebuildServers` so the flip republishes the paired server's `ApiConfig` — the
person holding the device knows what it is now, and that must outrank what it
was last time.

**Pairing has a way back.** `resetPairing`, behind a confirm, clears the
session, the fingerprint and the paired host so a device pointed at a server
that no longer exists is recoverable without a reinstall.

## Considered options

**A result class with a nullable reason string.** Smaller diff. Rejected: it is
the fourth channel again with a nicer name, and nothing forces a new reason to
be given words.

**An exception per refusal.** Idiomatic in some codebases. Rejected: a refusal
is an expected answer, not an error, and `catch` is not exhaustive — the compiler
cannot tell you that a new one is unhandled.

**One global timeout instead of per-stage.** Simpler. Rejected: it cannot
distinguish a hung call from a slow one, so the log says nothing about where a
venue's network actually fails, which is the one thing worth knowing when the
same venue reports it weekly.

**Cancel by disposing the repository.** Rejected: it takes the auth state with
it, and the screen needs the state that was there before the attempt.

**Retry the password change unboundedly with a `serverOnly` read.** Rejected:
"unbounded, but it will terminate now" is how the recursion got there in the
first place. Two passes and then say so.

## Consequences

Every path out of a sign-in now terminates: it admits, refuses with a named
reason, or times out with a line and a button. The full-screen spinner has no
state left that can strand it.

Fifteen outcomes is more than a boolean, and the `switch` in `admission_text`
must name every one. That is the cost and also the mechanism — the set is
closed and the compiler holds the line.

Firebase remains a hard dependency of an admin sign-in; there is no offline
path to it, and the deadlines make that fact visible rather than fixing it. See
[ADR-0099](0099-an-admin-sign-in-has-no-offline-path.md).

The staff half is untouched in shape: PIN against the local server, no cloud,
no deadline needed. The separation between the two halves is what the whole
screen is organised around, and it survives intact — this changes who owns the
outcome, not whether the two flows are different.
