# ADR-0134 — A hub is a catalogue, not an authority

Status: accepted
Date: 2026-09-05

## Context

The Venue hub is a grid of sixteen tiles. Every tile behind it carries its own
gate, and several of those gates were written precisely because the screen
belongs to somebody who is not an admin: `/kas` opens to `manageCash` *or*
`editSettings`, `/opname` and `/member-report` each name two authorities for the
same reason, and [ADR-0132](0132-a-grantable-capability-must-gate-something.md)
had just cut `/stock` into `manageIngredients` (author a bahan) and `adjustStock`
(move its numbers) so the seeded Manager could finally open it.

The hub itself cost `manageStaff`.

So the door in front of all of them asked a question none of them asked. The
seeded Manager, whose whole point is receiving deliveries and walking counts,
held `adjustStock`, was granted `/stock` by 0132 — and still could not reach it,
because the only link to `/stock` in the entire app was a tile inside a room
they were not allowed into. The route gate was correct and unreachable, which is
the same outcome as no gate at all and considerably harder to see.

Three further facts made it worse:

- **The rail offered the room anyway.** `TabletSideRail` rendered the Venue slot
  unconditionally, so a waiter's tap on it landed on `/forbidden` — a nav
  destination whose only function was to refuse.
- **A phone had no hub at all.** The floating tab bar has no Venue slot. The one
  navigation to `/venue` on a handset is the server-mode sign-in landing, which
  means a phone could enter the hub exactly once per session and never again —
  and a person holding nothing on the hub landed there anyway, so a successful
  sign-in ended on `/forbidden`.
- **Tiles were not filtered.** Whoever got in saw all sixteen, including the ones
  their role could never open.

The shape of the fix is not new. [ADR-0106](0106-the-guest-queue-is-a-destination-its-settings-are-not.md)
found the identical failure one screen over: the guest queue was a hub child, the
hub was `manageStaff`, and the queue's own authority was `takeOrder` — so the
destination was unreachable by the exact role it was built for. That ADR promoted
one screen. This one fixes the door.

## Decision

### 1. The hub opens to whoever can open something inside it

`capabilitiesFor('/venue')` returns `venueHubCapabilities` — the union of the
capabilities of every hub child — instead of `[manageStaff]`. `/staff` and
`/system` keep their own `manageStaff` arms; `/venue-settings`, `/venue-day`,
`/venue/diskon` and `/venue/pengeluaran` keep theirs. What changes is only the
bare hub, which is a **catalogue of destinations** and was never an authority in
its own right.

The union is *derived*, never written down twice: `venueHubRoutes` comes off the
hub's own tile list, so adding a tile widens the hub's gate in the same edit.

### 2. Tiles filter to what the viewer can open

The hub renders `_sections.where((s) => canOpenRoute(auth, s.route))`, and
`canOpenRoute` is the redirect's own test — the same table, the same
`needed.any(auth.has)`, the same reading of `null` as ungated. One predicate, so
a visible tile can never land on `/forbidden` and a hidden tile can never be the
only door to a screen its holder is entitled to.

A capability **hides** a tile; a missing [[Modul]] only **greys** one. That
order is CONTEXT.md §Modul already: unentitled is invisible to staff and locked
for the buyer. Reversed, the hub would pitch an add-on to a cook whose role could
not open it either way.

The hub's **subtitle is derived from the same visible list** rather than
written down. The fixed line named Konfigurasi, Zona, Sistem and Staf to
everybody, which the moment tiles filter becomes a subtitle listing rooms the
reader cannot enter; `hubSectionLine` takes the first five of what is actually
drawn. Five because it is a sample, not an index — an admin holds fifteen tiles
and the line has one row to live in.

**Fail open on `null`, and let a test be the guard.** An unmatched route reads as
ungated here exactly as it does in `redirect`; a route the router lets you *open*
but the hub refuses to *show* would be a screen reachable only by deep link.
`test/venue_hub_gate_test.dart` asserts every hub route resolves to a non-null
gate, so the fail-open case cannot arise quietly.

### 3. Stok is a nav destination

`/stock` joins `_railRoutes` as its own slot — tablet rail and phone tab bar,
visible on either stock authority (`showStock`), last before the divider and
before `me`. Receiving a delivery is shift work, not configuration; the slot sits
with the working destinations, not below the rule with Venue.

It keeps its hub tile, unlike ADR-0106's queue. The queue left the hub because it
is *never* an owner's job; stock genuinely belongs to the back-of-house catalogue
an owner walks. Two doors to a daily screen is cheap.

It is **not** hidden from a `manageStaff` holder who has the hub tile as well —
hiding a destination *because* someone holds more authority is the same inversion
this ADR removes.

**No badge.** Every badge on the nav today means work arrived and clears when it
is handled; a low-stock count sits for days. A badge that never clears teaches
people to stop reading badges, and `urgent` is a scarce resource.

Consequences of joining `_railRoutes`: `/stock` lights its own slot, its crumb is
`[Stok]` rather than `[Venue › Stok]` — including when you arrive from the hub
tile, since crumbs are a pure function of the path — and its `venueHubCrumb`
entry is gone.

### 4. The phone gets a hub door, and the sign-in landing asks first

A row on `/me` pushes `/venue`, rendered on the same predicate as the rail slot.
And the server-mode landing falls through to `/counter` or `/tables` when the hub
opens to nothing for that person — the gate is computable now, so "signed in
successfully → forbidden" no longer happens. That decision is `landingFor`, pure
and outside `redirect`: it is the one branch here that cannot be exercised by
hand (a staff PIN cannot sign in while the admin session owns the server), so it
is the one that most needs a test it can be exercised by.

### 5. `/opname` takes either stock capability

Found while writing the test for §2. The archive gated `viewReports` or
`manageIngredients`, but ADR-0132 §1 put the count itself wholly on the ledger
side — so the person who *walks* the count could not open the archive of their
own closed sessions. It now takes `viewReports`, `manageIngredients` or
`adjustStock`, which is what 0132's "reads take either capability" already said.

## Consequences

- The seeded Manager reaches stock from the nav on both form factors, which was
  the whole point of splitting the capability in 0132.
- The rail's Venue slot disappears for a waiter instead of refusing them. Nothing
  is revoked — the route is unchanged for anyone who holds a hub capability.
- Adding a hub tile now widens the hub's own gate automatically. Adding one whose
  route has no gate fails a test rather than shipping a tile visible to everyone.
- A screen that wants to be reachable by its own authority still has to be
  *offered* somewhere. This ADR makes the hub honest; it does not make every
  screen a destination, and a new screen whose holders never hold `manageStaff`
  should still ask whether it wants a slot (0106's question).
- `activeTabFor` still defaults unmatched shell paths to `venue`, so `/order/new`
  now highlights nothing for a waiter instead of highlighting a slot that was
  wrong anyway. Left alone deliberately: fixing it means making the function
  depend on `counterHome`, and it is a const table on purpose.

## Alternatives considered

**Promote `/stock` and stop there.** The narrowest fix, and it leaves `/kas`,
`/opname`, `/reports` and `/member-report` stranded behind the same admin door
for the same reason — a list of screens that will each arrive as its own bug
report.

**Keep `manageStaff` on the hub and filter tiles only.** Filtering a room nobody
but an admin may enter changes nothing for the person the tiles are for.

**A second table mapping tile → capability.** Rejected on 0132's own evidence:
two tables answering one question drift, and the drift is silent until somebody
is locked out of a screen they hold.

**Give the phone a Venue tab.** Seven tabs on a 360dp bar. `/me` already has a
slot and is where a person goes to look at their own situation.

**Badge the Stok slot with the low-ingredient count.** See §3.
