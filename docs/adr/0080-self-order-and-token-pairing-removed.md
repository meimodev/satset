# Guest QR self-ordering and token pairing are removed

**Status:** §1 superseded by [0105](0105-guest-self-order-returns-as-an-intent-not-a-ticket.md) — self-ordering is rebuilt as an intent, not a ticket. §2 (token pairing removed) stands. Accepted — 2026-08-05 — supersedes [0027](0027-cleartext-guest-plane-for-self-order.md) (cleartext guest plane), [0028](0028-guest-orders-pending-review-not-auto-fire.md) (guest orders rest in review), [0029](0029-guest-web-app-hand-rolled-spa-not-flutter-web.md) (hand-rolled guest SPA), [0064](0064-a-guest-order-gets-its-own-cue.md) (guest-order cue); amends [0003](0003-pairing-mdns-qr-self-signed-tls.md) (pairing) and [0048](0048-floor-screen-parity-and-derived-staleness.md) (the unreviewed-order `crit` rule)

## Context

Two separate things carried a QR in this app, and only one of them was ever built as designed.

**Self-ordering** shipped whole: a cleartext listener on 8080, a hand-rolled SPA, a table-scoped guest JWT, a per-table QR poster, a venue master switch plus per-table opt-in, a `pendingReview` ticket state invisible to the KDS, a staff review queue behind its own shell tab, and an arrival cue with its own sound preset. It is a second ordering path, a second auth scope, a second network plane and a second product surface — all sitting beside the waiter flow the app exists to make fast.

**Pairing** did not. ADR-0003 describes a QR token claim: the server shows a `PairQrPayload`, the client scans it, posts to `/pair/claim`. No scanner was ever wired. `mobile_scanner` sat in `pubspec.yaml` with zero usages in `lib/`. What actually shipped is `/pair/auto-claim` — the client picks an mDNS entry whose TLS fingerprint it has already pinned end-to-end, and the server writes the device row. The typed-entry fallback on `/pair` and `PinViewModel.claimQr` / `claimManual` had no callers at all. The documented flow and the running code had drifted apart, and the docs were the ones telling the story.

## Decision

**1. Guest self-ordering is removed in full.** The cleartext plane, `guest_app_html.dart`, `guest_routes.dart`, the guest JWT scope, `GuestOrdersRepository`, the review screen and its `/guestorders` route and shell tab, `TicketStatus.pendingReview`, `AlertEvent.guestPending`, `WsEventTypes.guestOrderSubmitted`, the per-table QR poster, and both ordering switches. Ordering is waiter-taken, one path.

**2. Token pairing is removed; auto-claim is the only path.** `POST /pair/claim`, `PairingService`, the `PairTokens` table, `PairQrPayloadDto`, `PairClaimRequestDto`, `PairScreen`, `PairViewModel` and the `/pair` route all go. `/pair/auto-claim` writes the `Devices` row directly instead of issuing a one-shot token to consume a line later. mDNS discovery and TLS fingerprint pinning are untouched — they were always the real trust anchor (ADR-0003 §4). `mobile_scanner` leaves `pubspec.yaml`; CAMERA stays for the payment-proof photo (ADR-0025), which uses `image_picker`.

**3. Schema v45 deletes rather than remaps.** `venue_tables.guest_ordering_enabled`, `venue_settings.guest_ordering_enabled`, `venue_settings.sound_guest_pending` and `venue_settings.pending_review_mins` are dropped; `pair_tokens` is dropped. Rows with `status = 'pendingReview'` are **deleted** from both `tickets` and `table_session_tickets`.

Deletion is the only truthful reading. Those rows are guest orders no waiter approved: never fired, never billed — the bill filter excluded them by that exact status string, and that filter is one of the lines being removed. With the enum value gone, `ticketStatusFromKey` falls through to `_ => TicketStatus.sent`, which would put an unapproved order on a paying guest's bill, silently. Nothing references tickets by id (`audit_entries` keys on `table_id`), so no row is orphaned and the stored `TableSessions` totals never counted them.

**4. The stale-table floor alert goes with the threshold.** `floor_signals.dart` fired a crit on `TableStatus.pending` past `pendingReviewMins`, labelled "Belum ditinjau". Its threshold and copy were guest-review's, even though `TableStatus.pending` is set by any waiter send. Rather than repoint it at another threshold and keep a signal under a name that never described it, the branch is removed.

## Consequences

- One ordering path, one auth scope, one listener. The server no longer binds 8080 and no longer serves HTML.
- **A client device on the venue Wi-Fi can pair with no out-of-band secret.** This was already the shipping behaviour — the stricter token path was the one nothing called. PIN auth (ADR-0004) still gates everything useful; pairing proves LAN presence, not authority.
- A venue whose Wi-Fi blocks mDNS multicast now has **no** pairing path. The typed host/port/fingerprint fallback that covered it is gone. If such a venue appears, the fix is to restore a claim endpoint, not to weaken pinning.
- v45 is one-way. A downgraded APK will not read an upgraded DB.
- Floor cards lose the "Belum ditinjau" crit. Kitchen overdue alerts (ADR-0043) and the ungreeted escalation (ADR-0044) are unaffected.
- `qr_flutter` stays — the receipt footer QR (ADR-0033) still uses it.

## Alternatives considered

- **Leave the schema columns in place, remove only the Dart.** Rejected: four unread columns that every future reader has to be told to ignore, and "completely removed" would not be true.
- **Remap `pendingReview` rows to `voided` instead of deleting.** Defensible, and it preserves the evidence a guest once ordered. Rejected as more machinery than the case earns: these rows never touched money or the kitchen, and there is no report that reads them.
- **Keep `/pair/claim` as the multicast-blocked fallback.** Rejected: nothing in the UI called it, so it was untested code standing in for a venue we have not met. Reintroducing it is cheap if one turns up.
- **Keep the floor alert on `prepTargetMins`.** Rejected: it would preserve a signal whose name and copy were both about guest review, inviting the same confusion under a new threshold.

## Amendment — 2026-08-22

The fingerprint is the server's **identity**, not merely the pairing handshake's
trust anchor. That distinction was implicit and it is what a paired handset
needs in order to survive its host changing address.

A venue tablet gets its LAN address from a router that hands out leases, so the
host moves — a reboot, a lease expiry, a switch to the other access point — and
the stored `apiConfig` points at nothing. The device is still paired: the
operator did prove LAN presence once, the server has the `Devices` row, and the
certificate has not changed. Only the *address* is stale. Making a human re-run
discovery for that is asking them to re-prove something nothing has cast doubt
on.

So: when the client's requests to the stored host fail repeatedly, it re-browses
mDNS (`mdns_browser_service`, the same code pairing uses) and adopts a candidate
**only if the candidate's fingerprint equals the stored one**. A different
fingerprint is a different server and is refused, which is the whole reason this
is safe to do without a person — the check is the same pin ADR-0080 already
relies on, asked again.

This does not restore a pairing path for a venue whose Wi-Fi blocks multicast.
Discovery still has to work for re-discovery to work; the consequence recorded
above stands unchanged. It also does not widen what pairing proves: a stranger
who can answer on the LAN still cannot be adopted, because they cannot present
the pinned certificate.
