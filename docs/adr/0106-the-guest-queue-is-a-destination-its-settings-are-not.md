# The guest queue is a nav destination; its settings are not

**Status:** Accepted — 2026-08-19 — supersedes the UI half of [0105](0105-guest-self-order-returns-as-an-intent-not-a-ticket.md) ("one screen, four tabs, the queue renders on phone too"). Everything ADR-0105 decides about the data — the intent, the server-side pricing, the once-only decision, the cleartext plane — stands untouched.

## Context

ADR-0105 shipped [[Pesan mandiri]] as one screen with four tabs, reached from
the Venue hub, gated `takeOrder` **or** `editSettings`, with the queue tab
rendering on a phone so a phone-only waiter shift could accept.

The Venue hub is `manageStaff`.

So on a tablet — the hardware a busy venue actually puts on the pass — the only
door to the guest queue was behind a capability no waiter holds. A tablet
waiter could not reach the queue at all. The phone case worked only because
`tables_screen` carried a separate floor action, added precisely because "a
phone has no Venue hub"; that workaround was the tell, and it covered one form
factor out of two.

The route gate was right and the door was wrong. `_capabilityFor('/selforder')`
correctly said `takeOrder` opens this — and nothing a `takeOrder` user could see
ever linked there.

Underneath that is a shape problem the tabs made easy to miss: the four tabs are
two jobs. Tab one is a shift-long watch job for whoever is on the floor. The
other three are an owner curating a guest-facing product — codes to print, what
a guest may see, when the venue takes orders — read against each other, on a
tablet, while seated. One screen serving both meant one door, one gate, and the
gate had to be the union of two unrelated authorities.

## Decision

**1. The queue is a top-level nav destination, on both form factors.** `/selforder`,
gated `takeOrder`, in `_railRoutes` as `tamu` with a slot in the tablet rail and
the phone tab bar. Not a hub child: the person who accepts a guest order is a
waiter, and a waiter's screens are on the rail.

The slot appears only when `guestOrderingEnabled && has(takeOrder)`
(`showGuestQueue`), the same conditional shape `showKasir` already uses. The
feature off means the guest socket is not bound at all (ADR-0105), so the
destination does not exist either — a tab that renders "this is off" costs a tap
to learn nothing. The badge is the pending count in accent, not the alert green
`/orders` uses for ready lines: a waiting guest is a job to pick up, not a plate
to run.

The phone bar therefore reaches five slots at its widest (Meja, Pesanan, Kasir,
Tamu, Saya). The floor action on `/tables` is **deleted** — its own comment said
it existed only because a phone has no hub, and this is that door, on both
sizes.

**2. Configuration is a separate screen behind one capability.**
`/selforder-admin` — QR & meja, Menu tamu, Aturan — gated `editSettings`, tablet
only, reached from the Venue hub tile where it always was. The hub badge stops
counting pending orders and says on/off instead: the backlog now has a
destination of its own, and pointing an owner at the hub for it would send them
to the wrong screen.

`/selforder-admin` is tested **before** `/selforder` in `_capabilityFor`, because
one is a prefix of the other.

**3. The master switch moves to Aturan.** ADR-0105 put it on the queue on the
argument that "stop taking guest orders" is decided while staring at the
backlog. That argument loses to the one this ADR is about: it is an
`editSettings` write, and a lone admin control on a waiter's screen is exactly
the coupling being removed. An owner flipping it mid-service pays two taps.

**4. `/selforder` keeps both capabilities.** `takeOrder` **or** `editSettings`,
unchanged, because the server hands an owner the queue read and narrowing the
client would lock them out of a screen they are allowed to see. An
`editSettings`-without-`takeOrder` role therefore gets no rail slot and reaches
the queue only by walking the hub. Accepted: admin carries every capability, so
the gap is theoretical.

## Consequences

- A waiter on either form factor has the queue one tap away, badged, for the
  first time. This is the whole point.
- Two files (`self_order_screen.dart`, `self_order_admin_screen.dart`), two
  routes, two capabilities — each route now demands exactly what its writes
  demand server-side, which is the rule `_capabilityFor` is supposed to hold.
- The phone tab bar is at five slots and has no room for a sixth. The next
  top-level destination that wants a phone slot has to displace one.
- A venue that has never switched self-order on sees no change: no rail slot, no
  phone slot, and the hub tile reading "Mati" is still how the feature is found.
- `soPhoneOnly` is gone from both ARBs, replaced by `soTabletOnly` — the string
  described a split that no longer exists.
