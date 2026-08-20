# A trial is shaped like any other venue

**Status:** Accepted — 2026-08-20 — **supersedes §2 of** [0107](0107-a-module-is-an-entitlement-beside-the-plan.md).

ADR-0107 stands in every other respect: a [[Modul]] is still à la carte, still
cloud-owned, still mirrored down as a CSV, still read through one method, still
frozen-never-deleted on removal, still invisible on the floor and locked on the
hub when unheld. What this ADR retires is §2 alone — *"a trial holds every
module implicitly"* — and the `isTrial ||` that sentence put inside the read
rule.

## Context

§2's argument was that a trial is the demonstration of the whole app, and the
decision it exists to produce is *which of these do I keep*. Sound, until you
watch a sales call. The operator does not hand a warung the whole app and ask it
to subtract; they quote a configuration — floor, kitchen, till, and the two
modules or neither — and then want the trial to *be* that configuration, so the
thing the venue trains its staff on for two weeks is the thing it will be
running on the third. Under §2 the operator could not do that. The console
rendered the module toggles on and inert on a trial, with the copy "A trial
includes every module" underneath, and `_modulesValue` returned null so nothing
a trial staged was ever saved. The one plan where shaping the product matters
most was the one plan where the control was decorative.

Worse, the branch lived in the read rule:

```dart
bool hasModule(String key) => isTrial || addOns.contains(key);
```

ADR-0107 §3 had just finished insisting that a route reading `modules` directly
is a review finding, precisely so entitlement has one answer in one place. The
`isTrial ||` made that one place plan-aware, which meant every reader that
correctly asked `hasModule` got an answer that silently depended on billing
state. Nothing in the test suite pinned it. That is how it survived.

## Decision

**1. The plan does not enter `hasModule`.**

```dart
bool hasModule(String key) => addOns.contains(key);
```

A trial holds exactly what its `addOns` says, same as a partner. `venue_module_entitlement_test.dart`
pins it — including the case that plan never changes the answer for any set —
because the previous rule went unnoticed for want of exactly that assert.

**2. Provisioning branches on the plan; reading never does.** `createVenue`
seeds a trial with the full `MODULES` set and a partner with none. These are
different acts and conflating them is how `isTrial` got into the read rule in
the first place: the default is a value written once, at creation, that an
operator can then change; the rule is a function evaluated on every screen that
nobody can see. A trial that started empty would demo missing half the app; a
partner that started full would be given features nobody quoted it.

**3. The console card is identical on every plan.** No inert render, no
trial-specific hint (`fltModulesTrial` is deleted from both locales), and
`_modulesValue` no longer returns null on a trial — so a plan switched
mid-session carries the entitlement across rather than dropping it. The removal
confirmation and its freeze-not-delete copy (ADR-0107 §7) are unchanged.

**4. Existing trials are backfilled, not migrated lazily.** Every `plan ==
"trial"` venue is written the full `MODULES` set by
`functions/backfill_trial_modules.local.js` — unconditionally, not only where
`addOns` is empty. The backfill's job is to record the entitlement a trial
*actually holds today*, which is all of them; a partial set sitting on a trial
document was never chosen by anyone, because the control that would have chosen
it was inert, and preserving it would take a module away silently. Partners are
untouched: `isTrial` was the only implicit, so their stored `addOns` was already
honest.

**The backfill runs against prod before the APK ships.** An old APK still
computes the implicit rule and is unharmed by the write. A new APK on an
un-backfilled trial mirrors `modules: ''` down and the floor loses both modules
mid-service.

**5. The members-debt guard is plan-blind.** `updateVenue`'s refusal to remove
`members` while the venue is owed money by its own members (ADR-0107 §7) was
unreachable on a trial and now is not. It stays as written, with no trial
exemption: a trial venue's members owe a real restaurant real money, and a demo
venue with fabricated debt has a fabricated amount to write off, which is cheap.
An exemption would be a plan branch in the one file this ADR exists to remove
plan branches from.

**6. An untick reaches the floor at the next mirror, and on an old APK not at
all.** `hasModule` lives in the APK, so a venue still on a pre-ADR-0108 build
keeps computing the implicit rule and keeps both modules regardless of what the
operator unticked; and even on a current build, `venue_settings.modules` is
served from the last mirror, so the change lands on the venue server's next
cloud reconnect. Both accepted. Entitlement was deliberately made the quiet path
(ADR-0107 §1) — [[Pemutusan layanan (Service cutoff)|pemutusan layanan]] is the loud one and has its own
sweep — and the alternative is a cloud-resolved `entitledModules` field, a
second place storing the same truth, which is the thing ADR-0107 §3 refused.

## Rejected alternatives

**Default-on with an explicit override.** Keep the trial holding everything
unless the operator turns something off. `addOns` cannot express this — empty
already means "nothing" — so it needs a `disabledModules` array or a
`modulesExplicit` flag beside it, two fields encoding one truth and a precedence
rule every reader has to know. It also keeps the plan branch, just further down.
Rejected for the same reason ADR-0107 §3 gave: entitlement has one answer, in
one place, from one field.

**Leave §2 alone and let the operator use the owner's switches.** The venue's
own `membersEnabled` / `guestOrderingEnabled` preferences already hide these
features, so an operator could ask the owner to turn them off for the trial.
Rejected: those are the venue's switches, freely flipped back, and asking a
restaurant to keep a feature switched off during its trial is not the same as
not selling it the feature. The AND of entitlement and preference (ADR-0107 §3)
only means something if both halves have an owner.

**Amend ADR-0107 §2 in place.** Rejected. §2's rationale is the record that this
argument was had once and settled the other way; editing it out invites someone
to re-propose implicit-trial in six months with no trace of why it was tried.
