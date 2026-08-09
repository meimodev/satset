# ADR-0092 — A member is a phone number

Status: accepted
Date: 2026-08-09

## Context

A **[[Pelanggan (member)]]** needs an identity the cashier can produce in a few
seconds, at a till, while a guest waits. The candidates were a printed member
code, a QR card, a name search, and the phone number.

Names do not identify anyone — an Indonesian venue's directory fills with
Budi, Budi and Budi, and a cashier picking the wrong one silently moves points
between strangers. Cards and QR codes identify perfectly and cost the venue a
supply chain: stock to print, a scanner or a camera flow to read them, and a
replacement policy for the ones that get lost, which is all of them. A member
code the guest memorises is a card with extra steps.

The phone number is already the thing venues ask for. It is already in the
schema — `Reservations.phone` has carried it since bookings shipped — it is
unique in practice, the guest carries it whether or not they remember they are
a member, and a numeric keypad with prefix search is the fastest input the
cashier has.

The pressure against it is that phone numbers are personal data, they change,
and typos create duplicates. Those are real and they are answerable; the
alternatives' problems are not.

## Decision

**The phone number is the member's identity.** It is unique venue-wide.
Enrolling on a number that already exists **attaches to that member** rather
than creating a second one. There is **no anonymous member**: a guest who will
not give a number is not enrolled, and no placeholder identity is minted for
them.

A short **member code** is derived for display — it prints on the receipt and
reads back over the counter — but it is never the key and never the input.

A number that changes is an edit to the record, audited. Duplicates created
before the uniqueness rule could catch them (two spellings of the same person,
a household sharing a handset) are resolved by an admin **merge**: points sum,
punch progress takes the max, both audited under `memberMerged`.

**Deleting a member anonymises; it never erases money.** The member row and
their points ledger go. Every settled [[Bill (tab)|bill]] keeps its `memberId`
and renders as "Pelanggan dihapus". There is no data-export feature, and the
absence is deliberate rather than pending.

## Consequences

Enrolment is two fields — number and name — which is short enough to do at the
till without the queue noticing, and that is what decides whether the feature
gets used at all.

The directory accumulates real personal data on the venue's own hardware. That
is the smallest surface available given [ADR-0091](0091-membership-lives-in-the-venue-not-the-cloud.md),
and deletion genuinely removes the person while leaving the venue's accounts
provably unchanged — the same posture [ADR-0037](0037-cashier-stage-catalog-discounts.md)
took by snapshotting a discount off its preset, for the same reason: settled
history must stand alone.

An anonymised bill still counts in the member-versus-non-member sales split,
because the visit *was* a member visit when it happened. Reports read history,
not the current directory.

Household sharing (one number, two people) is not modelled. They are one
member, they pool points, and no venue has ever complained about that.
