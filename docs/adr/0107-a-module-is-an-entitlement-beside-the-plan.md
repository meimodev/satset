# A module is an entitlement beside the plan, not a plan

**Status:** Accepted — 2026-08-19 — **amends** [0076](0076-two-plans-and-a-subscription-that-cuts-off.md).

ADR-0076's decision stands untouched: `plan` is still exactly `{trial, partner}`,
still carries a term and a price, and still **gates no feature**. What this ADR
retires is one sentence of its record — *"there is no entitlement model"* — by
putting the entitlement somewhere `plan` is not.

## Context

The partner rate is the entry price, and it is the price of the whole app. A
warung that wants a floor, a kitchen screen and a till is quoted a product in
which [[Pelanggan (member)|Keanggotaan]], [[Pesan mandiri (Self-order)|Pesan mandiri]] and the inventory half are most of the
surface area it is paying for and none of the surface area it will open. The way
to lower the floor is to sell less of the app, which means the app has to be able
to be less.

ADR-0074 and ADR-0076 deleted `{free, basic, pro, enterprise}` on the grounds
that they *"gated nothing, carried no price, and meant nothing to anyone but the
operator who typed them."* That is not an argument against entitlement. It is an
argument against an entitlement that isn't one — four strings pretending. Anything
reintroduced here has to actually refuse something and actually be paid for, or it
is the same hole with newer names.

Three things make this cheap rather than speculative.

**Two gate seams already exist, in production, built for another reason.**
`membersEnabled` 404s *every* member route (`members.dart:89`), and
`MembersRepository` reads that 404 as `enabled: false` rather than as an error —
so a venue without membership is a shape the client has always handled. The same
for `guestOrderingEnabled`, whose cleartext socket is simply never bound
(ADR-0105). Both were written as owner preferences and are already load-bearing.

**The venue doc already arrives and is already mirrored.** The eligibility
listener holds a live `venues/{vid}` snapshot, publishes it to
`venueCloudDocProvider`, and calls `_mirrorVenueIdentity` to write cloud-owned
name and address down into local `VenueSettings` (ADR-0018). A second mirrored
field costs one column and no new read.

**Non-payment already has an enforcement path, and it is loud.** [[Subscription
cutoff]] suspends the venue on a dated, twice-warned schedule. Entitlement must
therefore never be a second, quieter way to take something away for money — that
job is taken.

## Decision

**1. Modules are à-la-carte, and they live in a set beside `plan`.**
`venues/{vid}.addOns: string[]` — e.g. `['members', 'selfOrder']`. Not a tier
ladder: a venue that wants membership and no self-order is an ordinary venue, not
a venue between two rungs, and an ordered ladder prices it at the higher rung for
the one thing it wanted. The names are **persisted strings**, under the same rule
as `AuditKind` and `guest_orders.status` — renaming one silently un-entitles every
venue holding it.

The **base package** — what a venue buying no modules gets — is floor, kitchen and
till: seat, order, KDS, settle, receipt, shift, reports. A restaurant that cannot
take money is not a product, so settlement is never a module.

**2. `plan` does not change, and a trial holds every module.** `{trial, partner}`,
its fields and its cutoff rules are exactly as ADR-0076 left them. A trial is the
demonstration of the whole app, so it is entitled to everything implicitly rather
than by a populated `addOns` — the buying decision at trial end is *which of these
do I keep*, and a trial that has to be provisioned module by module answers that
question for the venue by accident.

**3. Entitlement and preference are two different facts and stay two fields.**
`addOns` says what the venue may have; `membersEnabled` and its siblings say what
the venue wants. Collapsing them — letting a downgrade write the local boolean off
— destroys the owner's stated choice and makes *"they said no"* indistinguishable
from *"they can't"*. That is the failure ADR-0076 deleted `billingStatus` for,
re-run at feature scale.

They compose as **AND, at the gate that already exists**: `members.dart` and
`self_order.dart` are the single writers that already compute `enabled:`, and the
module check goes there and nowhere else. A route that reads `modules` itself is a
review finding, for the same reason a hand-rolled audit insert is.

The client repeats that AND once, in one place: `VenueSettingsModules` on the
settings DTO (`membersOn`, `guestOrderingOn`). Every floor surface reads those
rather than the bare preference — the till's piutang entry, the bill's member
panel, the [[Tamu]] rail slot. A screen that gates on `membersEnabled` alone
leaves an unentitled venue a button whose only outcome is the 404 §3 promised
nobody would see, which is how the first device run of this ADR shipped.

**4. Modules mirror down the path identity already uses.** `_mirrorVenueIdentity`
gains the set; `VenueSettings` gains a read-only `modules` column, cloud-owned in
the ADR-0018 sense — the local server never writes it and no venue screen edits it.

**Offline therefore fails open by construction**, not by policy. Firestore's cache
serves the last known doc, and the mirrored column survives a device that never
reconnects. There is deliberately **no staleness cutoff**: a module going dark
because the venue's Wi-Fi did is ADR-0074's mis-typed-date nightmare wearing a new
hat, and the venue-suspend sweep is the thing that enforces payment.

**5. One price. `addOns` carries no money.** `priceMonthly` stays a single
negotiated rupiah figure covering base plus whatever the venue holds, because the
[[Subscription notice]] names one number to a venue that pays one number. Per-module
prices on the doc would let the sum and the total disagree, which is precisely
ADR-0076's grievance at module scale. Price stays a negotiation, `addOns` stays an
entitlement, and they meet only in the operator's head.

**6. Unentitled is invisible on the floor and locked on the hub.** A module the
venue does not hold renders exactly like today's `enabled: false` everywhere a
waiter or a cashier can reach. On `/venue` — the admin hub, `manageStaff`, seen
only by the buyer — the tile renders greyed with *"Hubungi pengelola untuk
mengaktifkan"*. The split is **by surface, not by feature**: the owner is the
person the upsell is addressed to, and a locked door in front of a waiter mid-rush
is advertising inside a tool.

**7. A module that goes away freezes; it never deletes.** ADR-0095's rule for the
points ledger, generalised: balances, history and rows stay, the surfaces hide,
and re-entitling restores what was there. Removing a module is not a data event.

**One asymmetry, and it gets an invariant.** [[Piutang]] nests under Keanggotaan,
so removing that module hides the collection sheet for a venue that is still owed
money. The fleet console therefore **refuses to remove `members` while outstanding
member debt is greater than zero** — the same shape as `Aktifkan` being disabled
while a venue is lapsed past grace: an invariant instead of a bookkeeping field. A
venue that stops paying the operator must not thereby stop being able to collect
from its own customers.

**8. Two modules ship, and only two.** `members` and `selfOrder` — the two with a
finished seam, and the two a small venue genuinely does not want. Inventory
(`stock` + `opname`) is the next candidate and needs a seam built. **Reports and
multi-device are explicitly not candidates**: one is how the owner sees the value
they are paying for, and the other is how a venue grows into paying more.

**9. The console control is its own card, staged, and confirms only removal.**
Modules get a `SatCard.titled` in the venue editor **between Access and
Subscription** — what the venue *has*, then what it *pays*, which is the order the
sales conversation happens in. Not inside the subscription card: that is the
visual claim §5 spends a paragraph denying.

It is **staged behind Save** like every other field on that screen, and it rides
`updateVenue` rather than `setVenueBilling` — `setVenueBilling` exists to write the
fields that can disagree with *each other* atomically, and a module set cannot
disagree with a date. Putting it there would re-couple entitlement to money one
section after separating them.

**On a trial the checkboxes render all-on and disabled**, and the screen stages
`null` rather than their state — the literal `_priceValue` pattern already in that
file, for the identical reason: a plan that never renders the control must not save
what the control happened to be showing when the plan changed mid-session.

**A confirm dialog guards removal and nothing else.** Adding a module is what the
operator is paid to do; removing one takes a feature off a venue that may be
mid-service. The dialog names the venue rather than the module and states the
freeze rule where it lands — *"Data tersimpan, tampilan hilang"* — so no operator
ever believes they have just deleted a member directory.

§7's refusal is enforced **twice, on purpose**: the callable rejects (it is the
invariant, and the console is not its only caller), and the console additionally
renders the `members` checkbox disabled with the outstanding figure once
`openDebt` is published. The editor's own `_dirty` comment already argues that
"nothing to save" belongs before the tap rather than after it; this is that
argument applied to "cannot save".

## Consequences

- The entry price can fall to a base package without giving anything away to the
  venues already paying the full rate.
- `plan` and `addOns` are orthogonal, so the console can express *partner on base*
  and *trial with everything* without either field learning about the other.
- The first two modules are close to free: the 404 seam, the unbound socket and the
  identity mirror all exist. The cost is a Drift column, a `_mirrorVenueIdentity`
  line, two `&&`s, a console control and a hub tile state.
- `addOns` entries join the persisted-string family. Add one and it needs an ARB
  entry in both locales; rename one and every venue holding it loses the feature.
- The fleet console gains a per-venue read it did not need before: outstanding
  member debt, to enforce §7's refusal and to disable §9's checkbox. Cheap, and
  only on the removal path — and until it exists the console simply lets the
  callable refuse, so modules ship without waiting on it.
- A venue offline for a month keeps every module it had. This is intended and is
  not a leak: the suspend sweep, not entitlement, is what stops an unpaid venue.

## Alternatives

- **Tiers (`Dasar` / `Lengkap`)** — one dropdown, trivial to sell and to render.
  Rejected because the ladder charges for the rungs a venue skipped, and the whole
  point of the exercise is that a venue is paying for surface it will not open.
- **Metered on tables or devices** — no feature gating at all; a warung with eight
  tables pays less with the full app intact. Genuinely the cleanest model and
  rejected only on product grounds: it prices growth rather than value, and it
  makes the cheap venue the one that must not grow.
- **A per-module term (`{module: paidUntil}`)** — correct billing. Rejected: with
  no payment gateway every date is hand-typed in the console, so N venues × M
  modules of manual date-chasing, and a second set of dates that can disagree with
  the venue's own.
- **Entitlement writes the local toggle** — one field instead of two. Rejected in
  §3; it eats the owner's preference and cannot be undone by re-entitling.
- **A cloud price book** — modules priced globally, `priceMonthly` derived.
  Rejected as a product that does not exist yet: one operator, negotiated rates,
  hand-typed terms.
