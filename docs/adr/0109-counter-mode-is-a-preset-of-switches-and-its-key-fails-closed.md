# Counter mode is a preset of switches, and its key fails closed

**Status:** Accepted — 2026-08-20 — **amends** [0107](0107-a-module-is-an-entitlement-beside-the-plan.md).

ADR-0107's decision stands: `addOns` is the entitlement set, a module is not a
preference, and the two compose as AND at one writer. What this ADR adds is a
**second kind of key** that answers a different question, and therefore reads its
absence the other way round.

## Context

SatSet's design center is a full-service restaurant with **role separation** — a
waiter at a table, a kitchen on a KDS, a cashier at a till, an owner on reports.
Four people, four devices. Nearly every term in `CONTEXT.md` assumes it:
[[Table lock]], [[Waiter]] against [[Orderer (line author)|Orderer]], the
[[Pesanan board]] scoped by handler, [[Course fire]], stations.

A small cafe collapses all four into **one person at one counter**, and often has
no floor at all. The guest orders at the counter, pays, and waits for a number.
The gap is not missing domain — the money model already settles on its own axis
(ADR-0024, ADR-0069), the running takeaway number already exists and already
resets on `businessDayStartHour` — it is that the shipped flow routes through
hand-offs a cafe does not have.

So the request was not "build cafe features" but "let an operator turn a venue
into a counter shop", with the switches on the fleet console rather than in the
owner's Pengaturan: the owner never asked to be a cafe, the operator decided it
during onboarding.

That lands the switches on the cloud half of ADR-0107's split, and two things
there are actively hostile to a **mode**:

- **`venueHasModule` fails open.** `modules == null` — never mirrored — reads as
  entitled, and that is deliberate: a LAN venue that has not phoned home must not
  lose what it paid for. Applied to a mode key it means every existing restaurant
  that has not yet mirrored boots counter-only, floor hidden, KDS flattened.
- **A trial holds every module.** `addOns: plan === "trial" ? [...MODULES] : []`.
  Add a cafe key to `MODULES` and every new trial demos as a counter shop.

Both are correct for a thing you *bought* and wrong for a thing that *reshapes the
app*. "Did they pay for this" and "did someone deliberately make this venue a
cafe" are different questions, and one function cannot answer both.

## Decision

**1. One module key, `counterService`, not one per switch.** Seven persisted keys
would be seven names nobody can ever rename (ADR-0107's rule), seven entries to
keep in step with `MODULES` in `functions/index.js`, and — worse — it would make
modules *be* preferences, which is the exact distinction ADR-0107 exists to hold.
There is one thing being sold here: this venue is a counter shop.

**2. A mode key fails closed.** `venueHasModule` keeps its fail-open reading for
sellable modules (`members`, `selfOrder`). A mode key goes through a **separate
resolver** that reads absent, null and unmirrored all as **off**. Two questions,
two functions, no shared default. The fail-open that protects a paid feature is
the same behaviour that would silently reshape a restaurant, so the two must not
share a code path.

**3. The switches live in `venues/{vid}.counterConfig`, mirrored down beside
`modules`.** Six booleans, on the path `name` / `address` / `modules` already use:

| key | effect |
| --- | --- |
| `menuHome` | the menu is the home tab; the [[Floor]] is hidden |
| `anonTakeaway` | `guestName` optional — the visit rides its `Bawa pulang #N` label |
| `settleAfterSend` | commit opens the settle pane instead of returning to the floor |
| `simpleKds` | one queue: no station split, no course fire |
| `counterQr` | the venue-level [[Kode kedai]] QR |
| `ringkasReport` | the [[Ringkas]] one-page report |

These names are **persisted strings** under the same rule as everything else in
this family. They are config, not entitlement: `addOns` stays a pure answer to
"what may this venue have", and the map answers "how is it set up". An eighth
switch later costs a map entry, not an unrenameable key.

**4. The preset is a write, never a read.** Ticking `counterService` writes all six
switches on; the operator then unticks what that venue does not want. Nothing
anywhere computes "is this venue in the preset" — there is no preset state, only
the switches. This is what keeps "cafe with a small floor" expressible instead of
being a rung between two tiers.

**5. The trial's implicit grant excludes mode keys.** `MODULES` splits: a trial
receives the sellable set, and `counterService` is outside it. A trial demos the
restaurant product; the operator ticks counter mode for a venue that is one.

**6. Hide, do not refuse.** Every route counter mode hides stays legal server-side
and every row stays written — tables, zones, [[Reservation]]s, locks. A cafe that
adds four seats next month unticks `menuHome` and finds everything where it was.
This is [[Modul]]'s freeze-never-delete rule applied one level down. Refusing the
routes would buy nothing and break re-entitlement.

**7. No owner-side preference beside it.** `members` and `selfOrder` AND against
`membersEnabled` / `guestOrderingEnabled` because the owner has a real opinion
about running those programs. Counter mode is not a program the owner opts into —
it is the shape of their shop, settled at onboarding. One switch, on the console.

**8. A mode switch is not a capability.** These change defaults and layout, never
permission. `_capabilityFor` is untouched and no server route consults
`counterConfig` to decide whether a caller may act — the one exception being
`counterQr`, which gates whether a socket route *exists*, exactly as
`guestOrderingEnabled` already does.

## Consequences

- The mirror carries a map now, not only a CSV. `_mirrorVenueCloudFields` gains a
  third field and the same "only patch when it differs" guard.
- A venue that has never mirrored is a restaurant. That is the point.
- A fleet toggle does not reach the floor until the venue's next admin sign-in,
  and `counterQr` — being a socket route — needs a server **restart**, same as
  `guestOrderingEnabled`. Neither is new; both are now load-bearing on a switch an
  operator flips remotely, so the console must say so.
- `MODULES` in `functions/index.js` gains a key and a split. The validator that
  refuses an unknown `addOns` entry must accept `counterService` while the trial
  seed must not hand it out.
- Six switches is six code paths that only a subset of venues exercise. Every one
  of them is a *default*, never a branch in a writer — a switch that changed what
  `submitOrder` writes would be a review finding.

## Alternatives

**Seven module keys plus a "Kedai" button** (rejected). Closest to the literal
request, and it puts every switch on the console with no new cloud field.
Rejected because it dissolves ADR-0107: modules would become preferences, the
console would own seven names that can never be renamed, and `MODULES` would grow
a maintenance burden proportional to UI polish.

**Local `venue_settings` columns edited by the owner** (rejected). Cheapest —
there is already a settings route and a settings screen. Rejected because the
operator, not the owner, decides the shape of the shop at onboarding, and an
owner who unticks `menuHome` by accident has broken their own till with no way to
tell they did.

**One `venueKind` enum, `restaurant | cafe`** (rejected). Tidier than six
booleans and impossible to get into a nonsense state. Rejected because it cannot
be half-ticked, and half-ticked is the common case: a cafe with six seats wants
`anonTakeaway` and `simpleKds` but keeps its floor. An enum forces that venue onto
whichever rung is less wrong.

**Fail open, like every other module** (rejected). One resolver, one rule, no
second concept. Rejected because the first venue to exercise it would be an
existing restaurant that had not mirrored since the release, and the failure mode
is the whole app changing shape under a working shift.
