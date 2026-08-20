# A stempel count is the only member fact that crosses the guest plane

**Status:** Accepted — 2026-08-20.

## Context

[[Kartu stempel]] is the cafe's loyalty primitive — buy nine, the tenth is free.
It ships today, and it is till-driven: the count moves at settlement and the guest
learns it only if a cashier reads it out. A punch card whose holder does not know
their count does not change behaviour, which is the entire point of a punch card.
Closing that loop means the guest can see their own count.

The only surface a guest touches is the **guest plane** — a second `shelf_io.serve`
on :8080, **cleartext**, no `securityContext`, and a router that takes no
`ServerAuth` by construction (ADR-0105). That was a deliberate boundary: the way
to keep a stranger out of the staff API is a router that never heard of it.

Every member fact today sits on the other side of that boundary. A member is
identified by phone number (ADR-0092) and their record carries a name, a spend
history, a visit count, a points balance and possibly a [[Piutang]] debt. Putting
a lookup on :8080 makes phone numbers an **enumeration key** against all of it,
over plaintext HTTP, on a shared restaurant Wi-Fi.

So the question is not whether to expose the count — it is how little can cross
and still close the loop.

## Decision

**1. Two integers cross, and nothing else.** The stempel count and the reward
threshold. No name, no phone echoed back, no spend, no visit count, no points
balance, no debt, no enrolment date, no member id. The guest asked "how many more
coffees", and that is a number.

**2. The caller must hold an active guest session, and is rate-limited within it.**
The lookup is reachable only to someone who scanned the venue's QR, and only a
small number of times per session. A punch-card check is a once-per-visit act;
anything shaped like a sweep is not the feature.

**3. An unknown phone answers in the same shape as a known one.** The endpoint
never confirms enrolment — no 404-for-absent, no "not a member" copy. Otherwise
the response *is* the enumeration oracle regardless of how little it carries.

**4. Read-only. Nothing on the guest plane writes to a member.** No enrolment, no
adjustment, and above all no redemption: [[Tukar poin]] and the stempel reward
stay at the till, through the existing `redeem` [[Sumber diskon]] slot. The guest
plane may inform; it may not spend.

**5. It is not a member route.** It lives in `guest_routes.dart`, takes no
`ServerAuth` like everything else there, and reads through `members.dart` rather
than reaching into the tables — the writer stays the one door, same as
`self_order.dart` uses `submitOrder`. It answers **404** when the `members` module
is unheld or `membersEnabled` is off, identically to every authenticated member
route (ADR-0091), so a guest cannot tell an unlicensed venue from an old server.

## Consequences

- Enumerating phone numbers against this endpoint yields an integer about a phone
  the caller already possessed, with no confirmation the number belongs to anyone.
  That is the accepted floor, and it is only acceptable *because* of decisions 1
  and 3 — weakening either turns the endpoint into a directory.
- The guest page grows its first member-aware copy, and that page is outside the
  ARB pipeline (ADR-0105): the strings and any new error code live in its own map
  or they render as bare codes.
- This is the first member fact to leave the authenticated plane. The next one
  proposed should be argued against this ADR, not against convenience — the list
  is deliberately closed at two integers.

## Alternatives

**Return the member's name, to greet them** (rejected). Warmer, and trivially
available. Rejected because it hands an unauthenticated caller a name for any
phone number they care to type, which is a materially different product from a
loyalty counter.

**Require an OTP or a PIN** (rejected). Removes the enumeration surface entirely.
Rejected because an SMS gateway is absurd overhead for a punch card, and the venue
is offline-first by design — the one thing the guest plane can never depend on is
the internet.

**Leave it at the till** (rejected). Zero new surface, zero risk. Rejected because
it is the status quo, and the status quo is why the loyalty loop does not close.
