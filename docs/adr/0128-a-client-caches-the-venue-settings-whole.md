# A client caches the venue's settings whole

**Status:** Accepted — 2026-09-03 — **amends** [0115](0115-a-venue-may-have-no-prep-queue.md).

ADR-0115 taught a client to remember the venue's **shape** — `modules` +
`counterConfig` — across a cold boot, on the grounds that a mode key fails
closed and a handset booting away from its host would otherwise draw a
restaurant at a counter shop. That reasoning was right and too narrow. This ADR
widens the cache to the whole settings payload and adds the [[Preset diskon]]
catalogue beside it.

## Context

`VenueSettingsDto` is a freezed class of some sixty fields, every one of them
carrying a default. The defaults are conservative, which is another way of
saying they are **off**: `membersEnabled` is `false`, `guestOrderingEnabled` is
`false`, `memberEarnPerThousand` is the factory `1`, `memberDebtLimit` is `0`.

`VenueSettingsRepository._bootstrap` restored two of those sixty from prefs and
fetched the rest. So a device that cold-booted without a host — a handset out of
Wi-Fi range, a till whose server tablet had not come up yet, a client restarted
after a dead battery — painted a venue with the right *shape* and every
*program* switched off.

The symptom that found it: `MemberPanel` opens with

```dart
if (!cfg.membersOn) return const SizedBox.shrink();
```

and `membersOn` is `membersEnabled && hasModule(moduleMembers)`. Offline, the
module half reads entitled (fail-open, from the cached shape) and the preference
half reads `false` (fail-closed, from the freezed default). The panel vanishes.
Not empty, not disabled, not an error — **gone**, along with points, stempel and
the [[Piutang]] limit, on a screen where money is being taken.

Two things make this worse than an ordinary stale-cache bug:

- **It is invisible.** A missing panel looks like a venue that never opted in.
  There is nothing for the cashier to retry and nothing to report.
- **It is not the membership feature's bug.** The same two-line shape holds for
  `guestOrderingEnabled`, `taxEnabled`, `serviceEnabled` and every alert
  threshold. Fixing membership alone re-arms the identical failure behind the
  next flag someone gates a surface on.

The [[Preset diskon]] catalogue fails a related way for a different reason. Its
repository is a lazy provider with no cache at all, so the first thing to
*watch* it constructs it — and the first watch was the cashier opening the
discount sheet. Open that sheet first on a dark handset and `refresh()` throws,
the list stays empty, and `showDiscountSheet` tells the cashier the owner
authored no presets.

## Decision

**1. The client caches `VenueSettingsDto` whole**, as the wire JSON, under
`satset.venue_settings`. Written on every payload the repository adopts —
bootstrap fetch, WS update, and the response to the venue's own `PATCH` — and
painted into `state` before the fetch on the next boot.

**2. One adoption path.** `_adopt(dto)` sets state and writes the cache; a site
that assigns `state` directly leaves the cache a version behind, which is how
three of the four writers were already inconsistent about the *shape*.

**3. The pre-0128 shape key is read once, never written.** A device that
upgrades and cold-boots before it next reaches its host would otherwise find the
new key empty and re-acquire the exact flicker 0115 removed.

**4. The cache dies with the certificate, not the address.** ADR-0080 already
settles this: *the fingerprint is the identity; the address is only where that
identity answered last time.* Keying the cache on host:port — which this ADR
first said, and which was wrong — meant `relocateServer` destroyed a venue's own
settings every time a DHCP lease turned over, at the exact moment the device
could not reach its host and the cache was the only thing it had.

So the cache is stamped with the fingerprint it was mirrored from
(`satset.venue_cache_fp`) and dropped only when a config names a *different*
one. The check runs when a config arrives rather than at read time, because the
constructor paints before any fingerprint is knowable — the trusted one rides on
`ApiConfig`, and the stored fingerprint itself lives in secure storage, which is
async. That is sound because **a device cannot re-pair while offline**: pairing
costs a round trip, so a cache painted with no host can never have come from a
server this device has not met. Dropping clears prefs *and* resets `state`, since
the constructor has already painted the foreign venue by then. A cache with no
stamp is "mirrored before the label existed", read as unknown rather than
foreign — an upgrade must not discard a cache it merely cannot vouch for.

**5. The fetch waits for a host, and resyncs when the socket returns.** Two
holes the device rig found, both older than this ADR and both fatal to it.
`_bootstrap` read `apiConfigProvider` once and gave up if it was null — and this
repository is constructed at app root (the locale notifier reads `serviceTerm`,
ADR-0127), *before* the paired address has been read off prefs, so on the rig
`GET /venue/settings` was never issued at all and the device had been running on
a shape cached weeks earlier. It now waits for the address. Separately, the WS
listener handled only `venueSettingsUpdated`, which is an *edit* broadcast, not
a resync: a client that cold-booted away from its host stayed on the cache even
after the socket came back. It now refetches on `connected`, like every other
collection (ADR-0021).

**6. Discount presets cache in prefs**, painted in the repository's constructor
before the fetch, and the repository is **warmed on `AppShell`** beside the send
queue drain — so the first watch happens while the venue still has a host,
rather than mid-transaction.

**7. The member directory is *not* cached.** ADR-0123 stands: the phone is the
identity (ADR-0092), so there is no mirrored copy to search. Instead the lookup
sheet says so — offline, loading and empty are three visibly different states,
and enrolment is withdrawn rather than offered and failed.

## Consequences

**Stale beats absent.** A flag an owner flips while a device is dark stays wrong
on that device until it reconnects. Before, it was wrong on *every* offline boot
and silently so; a bounded staleness window is a strict improvement over an
unbounded lie. The `connected` refetch of §5 closes the window the moment the
socket returns, and a `venueSettingsUpdated` broadcast closes it sooner.

**No new offline money risk.** `recomputeBill` (ADR-0123) reads no venue
settings — tax and service ride the bill payload — so a stale cached rate cannot
reprice an offline settlement.

**A device that has never been online still hides membership.** No cache, no
knowledge. That is correct and is not fixable without a wire read.

**The prefs blob grows.** Sixty fields of JSON per venue, written on every
settings update. Immaterial next to the send queue that already lives there.

## Alternatives considered

**Extend the shape cache with the `member*` block.** Fixes the reported symptom
and leaves the identical fuse under `guestOrderingEnabled` and the alert
thresholds. It is the same bug with a longer wick, and the field list is a
second place to forget something the DTO already knows.

**Cache everything except a named refetch-only list.** Buys precision nobody
asked for and adds a list to maintain. The fields worth excluding are the ones
that could misprice money offline, and the check above found none.

**Mirror the member directory** so lookup works offline. A real feature, and a
different one: it needs a sync protocol, a Drift table and an amendment to
ADR-0123's identity rule. Worse, a partial mirror is the trap — enough cache for
a cashier to trust, not enough to be right, with no way to tell "not a member"
from "not cached".

**A Drift table for the presets** instead of a prefs blob. The list is fetched
and replaced whole; neither querying nor partial writes is used, so the schema
bump and migration buy nothing.
