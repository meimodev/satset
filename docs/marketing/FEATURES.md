# SatSet — Complete Feature & Capability Inventory

Derived from source code (`lib/`, `functions/`, `firestore.rules`, `codemagic.yaml`, `android/`) as of 2026-07-25, branch `main`, app version `1.0.1+2`. This document supersedes anything in `docs/` — it was written by reading the code, not the docs.

---

## 0. What SatSet Is

A **single Android APK** (package `id.activid.satset`, Flutter, minSdk 29) that runs a whole restaurant on a local Wi-Fi network with **no internet dependency for daily operations**.

One device runs in **Server mode** — it hosts an embedded HTTPS + WebSocket server, the SQLite (Drift) database, and an mDNS advertiser. Every other staff device runs in **Client mode** and pairs to it over LAN via mDNS discovery + TLS certificate pinning.

Cloud (Firebase) is used only for three things that are *not* on the critical path of taking orders: admin identity, a fleet/licensing control plane, and a periodic read-only report snapshot for absentee owners.

**UI language: Indonesian** (fixed; no language switcher).

---

## 1. Deployment Topology & Roles

| Actor | Session type | Server? | Pairing? | Lands on |
|---|---|---|---|---|
| **Host / Main Device** | Firebase admin (email+password) | Boots embedded server | — | `/venue` |
| **Staff (waiter/kitchen/cashier)** | 6-digit PIN → JWT | No | mDNS auto-claim | `/tables` |
| **Fleet super admin** | Firebase, `role=super` | No | Bypasses pair gate | `/fleet` |
| **Owner (read-only)** | Firebase, `role=owner` | No | Bypasses pair gate | `/owner` |

**Main Device guard (ADR-0017, narrowed by ADR-0077):** a venue has one active admin account running on one device. On admin sign-in the app does a 3-second mDNS scan for an existing host advertising the same `venueId`. Not found → boot the embedded server and become host. Found → sign-in is refused and the device shows which host it found, so there is never a second server for a venue by accident.

**Ports:** `7443` (TLS staff API + WebSocket).

---

## 2. Onboarding, Pairing & Network Trust

### Mode selection
`/onboarding` → Server or Client. Persisted in `SharedPreferences` (`AppMode.server|client|unset`).

### mDNS
- Service type `_satset._tcp`. TXT records: `fp` (SHA-256 TLS fingerprint), `label`, `ver` (app version), `vid` (cloud venue id).
- Client browser is ref-counted, filters own-host entries, dedups by `host:port` preferring entries with an explicit label.

### Pairing (ADR-0080)
One path: **LAN auto-claim**. The client picks a server surfaced live over mDNS and `POST /pair/auto-claim` over an HTTPS client pinned to the mDNS-advertised fingerprint; the server-returned fingerprint must match or the claim is refused. The server upserts the `Devices` row directly — there are no pair tokens and no QR scan. Reaching the endpoint over a pinned connection *is* the proof of LAN presence; staff still must enter their PIN, which is what gates anything useful.

### TLS
- Self-signed RSA-2048, CN `satset.local`, **5-year validity**, generated once and persisted to app-support dir (`satset.cert.pem` / `satset.key.pem`).
- `SecurityContext(withTrustedRoots: false)` — **certificate pinning is the only trust mechanism**. Clients compare SHA-256 of the DER cert against the pinned fingerprint; loopback escape hatch for the host's own calls.

### Re-homing
If the paired server reappears at a different `host:port` (DHCP move) with the **same fingerprint**, the client silently re-persists the new address. Server identity is the cert fingerprint, not the IP.

### Device registry
- `GET /devices` — each device joined with its most recent session (`lastSessionAt`, `lastSessionUserId`, `sessionActive`).
- `POST /devices/<id>/revoke` (cap `manageStaff`) — sets `revoked`, deletes every session for that device, broadcasts `device.revoked`.

---

## 3. Authentication & Authorization

### PIN login (staff)
- `POST /auth/login {pin, deviceId}`. PIN hashed `sha256("satset.v1::" + pin)`. Firebase-admin rows have an empty `pinHash` and are structurally excluded from PIN login.
- Issues an **HS256 JWT** — claims `{sub, role, deviceId, iat, exp}`, **12-hour TTL** — plus a `Sessions` row keyed by token. Signing secret is a per-install UUID persisted to `satset.jwt.secret`.
- Bearer resolution requires *both* a valid signature *and* a live session row → revocation is instant.
- A 10-second server ticker sweeps expired sessions and broadcasts `session.expired`.

### Firebase admin login
- `POST /auth/admin {idToken, deviceId}` — only accepted when the host is venue-scoped.
- Token verified **fully offline**: Google's x509 certs fetched and cached per `Cache-Control: max-age` (stale cache used when offline), `kid` matched, RS256 signature verified, `aud` / `iss` / `exp` checked against Firebase project `satset-3a795`.
- Requires custom claims `role ∈ {admin, super}` and `venueId` matching the host's, else `403 wrong_venue`.
- On success a local user row is upserted keyed by `firebaseUid` and a normal session is minted — the rest of the app sees no difference from a PIN session.
- The host's own admin sign-in skips HTTP entirely and calls `ServerAuth` in-process.

### Capability model
17 capabilities in 5 groups (`lib/domain/models/capability.dart`):

| Group | Capabilities |
|---|---|
| **orders** | `takeOrder`, `modifyOrder`, `voidItem`, `compItem` |
| **kitchen** | `viewKds` |
| **money** | `openDrawer`, `applyDiscount`, `settleBill`, `refund`, `closeShift` |
| **inventory** | `editMenu`, `markSoldOut`, `adjustStock` |
| **admin** | `manageStaff`, `manageRoles`, `viewReports`, `editSettings` |

Roles are user-defined sets of these, stored as JSON on the role row.

**Enforcement is double-sided:**
- **Server** — every mutating route calls `_requireCap(...)`: bearer → user → role → capability list. `401` if no user, `403 {code:'forbidden', message:'missing capability X'}` if lacking.
- **Client** — `_capabilityFor(location)` in the router maps route prefixes to capabilities and **fails closed** to `/forbidden`.

### Route guard order (`lib/router/app_router.dart`)
1. Super admin → forced to `/fleet`, bypasses everything.
2. Owner → forced to `/owner`, bypasses everything.
3. Non-super on `/fleet` or non-owner on `/owner` → `/pin`.
4. **Hard pair gate**: `apiConfig == null` → `/pin` (no data screen may render against an empty cache).
5. Not authenticated → `/pin`.
6. Authenticated on `/pin` → `/venue` (server mode) or `/tables` (client mode).
7. Capability check on destination → `/forbidden` on failure.

### Offline admin grace (ADR-0015)
- Cold boot as admin requires a **server-confirmed** Firestore read of `admins/{uid}` and `venues/{vid}` (8s timeout), both `active`. Success stamps `adminConfirmedAt` in secure storage.
- Offline boot is allowed for **up to 7 days** from the last confirmation, then blocked (`AdminBootGate.staleOffline`).
- After 3 minutes offline an in-app countdown banner appears; it turns critical under 24h remaining.
- A live session is **never** killed by staleness — only the next cold boot is gated.

### Kill switch (ADR-0015/0016)
Two live Firestore listeners run for the whole admin session:
- `admins/{uid}.status` — per-operator ban.
- `venues/{vid}.status` — per-venue kill.

Either leaving `active` immediately: cancels watchers → Firebase signOut → `ServerRuntime.shutdown()` (both listeners closed, mDNS stopped, WS hub disposed, DB closed) → clears `apiConfig` and stored session. Every paired staff client simply stops being able to reconnect.

A 60-second heartbeat stamps `venues/{vid}.lastSeenAt` (the only field Firestore rules let a venue write) and refreshes `adminConfirmedAt`.

### Logout semantics
- Super/owner → Firebase signOut only.
- Server-mode admin → full kill (server down, all staff disconnected).
- Client-mode staff → `POST /auth/logout`, clears the local session, **keeps the pairing**.

### Unauthenticated endpoints
`/healthz`, `/auth/login`, `/auth/admin`, `/pair/claim`, `/pair/auto-claim`. `/ws` authenticates via `?token=` query param. Everything else requires `Authorization: Bearer`.

---

## 4. Floor & Table Management

### Table model
`id, zoneId, label, pax, capacity(2), active, status, openAmount, readyCount, lastActorId, lockedBy/lockedByName/lockedAt/lockExpiresAt, openedAt, guestName, guestNotes, reservationId, currentVisitId, billClosedAt, moneyState`.

### Table statuses
`available` (Kosong) → `occupied` (Terisi) → `pending` (Pesanan masuk) → `ready` (Siap ×N).

| Transition | Trigger |
|---|---|
| `available → occupied` | `POST /tables/:id/seat` — 409 `already_seated` if not available. Sets `openedAt` (once), `pax` clamped to `[0, capacity]`, guest name/notes/reservation link, optional lock. |
| `occupied → pending` | First order submit or `POST /tables/:id/pending`. |
| `→ ready` | A ticket enters `ready` and `readyCount` goes 0→1 (transactional). |
| `ready → occupied` | `readyCount` returns to 0, or manual `POST /tables/:id/ready/decrement`. |
| `→ available` | `POST /tables/:id/close` (all tickets terminal) or `POST /tables/:id/release` (zero tickets). |

### Visit vs Table (ADR-0024)
A **Visit** is the bill/session identity, decoupled from the reusable `tableId`. Tickets are grouped client-side by `visitId`, so reseating a table never re-absorbs the previous party's lines. Two independent closure axes:

- **Table close** (waiter, "Selesaikan Layanan") — requires ≥1 ticket and **every** ticket `served|voided` (`409 tickets_not_terminal`); wipes the table row and stamps `visit.tableFreedAt`.
- **Table release** (waiter, "Lepaskan Meja") — for a seated table with **zero** tickets (`409 has_tickets`); drops the empty visit, no history row.
- **Bill close** (cashier) — see §7.

When **both** axes are complete, `snapshotVisitAndDelete` fires: rows are copied to the immutable history tables (`TableSessions`, `TableSessionTickets`, `TableSessionReceipts`, `TableSessionPayments`, `TableSessionCourses`) and the live `visits`/`tickets`/`receipts`/`payments` rows are hard-deleted. Broadcast: `tableSession.closed`.

### Table locking (soft editing lease)
- `POST /tables/:id/lock` `{userId, userName, ttlSeconds}` — default **7s TTL**. `409 table_locked` if held by another unexpired holder (payload includes the current row so the UI can name the holder).
- `POST /tables/:id/lock/heartbeat` — `409 lock_lost` if the caller is no longer the holder. Client heartbeats every **3s**.
- `DELETE /tables/:id/lock` — idempotent; a non-holder gets a harmless 200.
- No explicit steal — the lock simply expires. The detail screen auto-acquires after a **1.5s grace delay** once it observes the lock free, so quick navigation doesn't rip the lock from the previous holder.
- `available` tables are never locked.

### Move table (ADR-0019)
`POST /tables/:id/move {targetId, actorId, actorName}` (cap `takeOrder`).
- Validations: target required and different (`same_table`), source not `available` (`source_not_occupied`), source lock not held by someone else (`table_locked`), target `available` **and** `active` (`target_unavailable`).
- One transaction re-points every ticket, the visit, and all receipts to the target; copies session fields; hands the lock to the mover; wipes the source; writes an audit row (`tableMoved`) and broadcasts both table rows.
- UI warns when `source.pax > target.capacity`, confirms, then `pushReplacement`s to the new table detail keeping the lock.

### Other floor operations
- **Pax editing** — `PATCH /tables/:id/pax`, clamped server-side; long-press a table card for a standalone waiter-only stepper.
- **Handler reassignment** — `PATCH /tables/:id/handler {userId}`; drives the waiter avatar on the table card.
- **Elapsed heat** — table cards tick every 1s; colour interpolates neutral→warn over 0–30 min, warn→urgent over 30–60 min, clamped red past 1 hour.

### Reservations
- Model: `id, name, phone, partySize, expectedAt, status, zoneId, tableId, notes`. Statuses `pending | seated | noShow | cancelled`.
- `GET /reservations?from=&to=`, `POST` / `PATCH` / `DELETE` (all cap `takeOrder`). Delete blocked while `seated` (`409 conflict` — cancel first, preserving the audit trail).
- Client bootstraps a **yesterday → +14 days** window and lives on `reservation.created|updated|deleted` events.
- UI: a chip strip above the zone tabs showing today's live reservations with a pending-count badge. Tapping a pending chip opens a seat picker (zone → tables with `capacity ≥ partySize`) which seats the table, links the reservation, and flips it to `seated` in one flow. No-show / cancel / delete also offered.

### Takeaway (Bawa pulang, ADR-0026)
- A visit with `kind = 'takeaway'`, no table row, `pax = 0`.
- **Daily numbering** from a `DailyCounters.takeawayNext` row keyed to the **business day** (rolls at `businessDayStartHour`, default 04:00, not midnight). Label `"Bawa pulang #N"`.
- `GET /takeaway/visits` lists active ones; a floor strip appears only when ≥1 exists.
- **Handover** (`POST /visits/:id/handover`) is the takeaway analogue of table close: requires ≥1 ticket, all terminal; idempotent; triggers the snapshot when the bill is also closed.

---

## 5. Order Taking

### Entry points
1. **Table-first** — `/table/:id` → `menu` → `review` → `sent`.
2. **Menu-first / table-less** (ADR-0026) — `/order/new` mints a transient draft cart id; the table is chosen at commit time via a sheet listing available tables by zone (with pax stepper and optional guest name), or the order is committed as takeaway with a required guest name.
3. **Takeaway add-items** — `/takeaway/:visitId/menu`.

### Menu browsing
Category tabs, item grid with photo, price (`+` suffix when multiple variants), allergen/diet badges, in-cart quantity badge, and a "HABIS" overlay that disables tapping sold-out items. Tablet layout is a split view with a live cart pane (380 px). *(A search field is rendered on the ordering menu screen but is not wired to a filter.)*

### Item configuration sheet
- **Variant** picker (single-select, marked WAJIB, defaults to first) when >1 variant exists.
- **Modifier groups** — each labelled WAJIB (required), BEBAS PILIH (multi, optional) or OPSIONAL. Required groups must have ≥1 selection before the Add button enables. Multi-select is unbounded; single-select is inherently max-1.
- **Course** picker — `fireNow, drinksNow, starters, mains, desserts` (plus `sides` in the enum); the default is derived from the item's category.
- **Note** — free text, max 80 chars, printed on the kitchen chit.
- **Quantity** — clamped 1–20.
- Unit price = variant price + Σ selected option `priceDelta`. Selected modifiers are **snapshotted** onto the line (ADR-0011) so later menu edits never rewrite history.

### Review & submit
- Cart grouped by course; live totals via the shared bill-math (subtotal + optional service + optional tax).
- Each course block is labelled auto-fire (`fireNow`/`drinksNow`) vs held for pacing.
- Submit generates a UUID **idempotency key**; the server claims it transactionally in the `Idempotency` table and replays the stored `{ticketIds, visitId}` response on any retry.
- Every cart line becomes one `Tickets` row created directly as `sent` — "Kirim ke dapur" is an explicit fire action. (The offline/no-server fallback path creates non-immediate courses as `held`.)

---

## 6. Ticket Lifecycle & Kitchen

### Statuses
`draft, acknowledged, sent, prep, cooked, ready, served, held, voided`.

### Transition graph (enforced identically client-side and server-side; server is authoritative)
```
draft        → sent, voided
acknowledged → prep, voided
sent         → prep, cooked, held, voided
held         → sent, voided
prep         → cooked, voided
cooked       → ready, voided
ready        → served, voided
served       → ready, voided        (explicit un-serve undo)
voided       → (terminal)
```
Illegal transition → `409 illegal_transition`.

### Per-transition capability gates
| Transition | Capability |
|---|---|
| `* → voided` (source ≠ `served`) | `voidItem` |
| `served → voided` (comp / post-serve) | `compItem` |
| `ready → served`, `served → ready`, `held → sent` | `takeOrder` |
| `sent → prep`, `prep → cooked`, `cooked → ready` | `viewKds` |

### Course firing
`POST /tables/:tableId/course/:course/fire` (cap `takeOrder`) flips **only** `held` rows for that exact `(tableId, course)` pair to `sent`. Also reachable per-item ("Bakar sekarang").

### Timestamps (ADR-0013)
- `sentAt` — set at creation, re-stamped on fire.
- `readyAt` — **set-once** (`if null`), so a served→ready undo never inflates measured prep time.
- `servedAt` — last-write.

These feed the real speed-of-service metrics: prep = `readyAt − sentAt`, pickup = `servedAt − readyAt`.

### Void flow (ADR-0006 — self-served, per-waiter accountability)
- **Reason codes**: `wrongOrder` (Terkirim salah), `customerChange` (Tamu berubah pikiran), `outOfStock` (Stok habis), `kitchenError` (Komplain / kualitas dapur), `other` (free text, min 3 chars).
- Server **requires** both `voidReason` and `voidReasonCode` on every `→ voided` transition (`400 reason_required`) — UI-only enforcement was deemed insufficient.
- **No manager PIN gate.** Accountability is capability-based: pre-serve voids need `voidItem`; post-serve comps need the higher `compItem`.
- `voidedByUserId` is resolved from the **bearer token**, never client-supplied. `createdByUserId` is frozen at creation and does not follow later handler changes.
- Every void writes an audit row and broadcasts `audit.created`.

### Kitchen Display (KDS)
- `GET /kds/stations` — one unified `kitchen` station (no multi-station routing exists in the schema) with `pendingTickets` and `staffOnline` counts. `GET /queue/depth` for the System screen tile.
- Cards = **fire batches**, grouped by `(table-or-visit, sentAt)`, sorted oldest-first; unfinished items rise within a card.
- Filter: "Tampilkan order selesai" toggle; fully-done batches drop out of the default view.
- **Age colouring** ticks every 1s: green <5 min, amber 5–9 min, red ≥10 min with a thicker card border and a pulsing dot.
- **Long-press to commit** (with haptic), never single-tap — a deliberate anti-fat-finger decision; a tap only shows a hint. One long-press walks `sent → prep → cooked`; once every active item in a batch is `cooked`, the whole batch is promoted to `ready` together.

### Orders board
- Three segments: **Siap** (`ready`), **Disiapkan** (`sent, prep, cooked, held`), **Selesai** (`served, voided`).
- Each segment sub-groups into Bawa pulang / Makan di tempat, sorted by send time.
- Rows show table token, qty × name + variant, up to 2 modifier labels, a status chip, an elapsed pill, and the ordering waiter's avatar. `ready` rows get an inline "Sajikan" button; others tap through to the table/takeaway detail.
- The elapsed pill ticks every 30s and marks overdue against the venue-configured `prepTargetMins`; terminal tickets freeze to a static clock string.

---

## 7. Cashier, Bills & Settlement

### Two-phase settlement (ADR-0023/0024)
Money (cashier) and floor (waiter) are independent axes; either may complete first. The visit is snapshotted to history only when both are done.

### Bill structure
- **Bill** (per visit): `mode (itemized|even)`, `subtotal, serviceAmount, taxAmount, total, paidAmount, outstanding`, `fullyAssigned`, `fullySettled`, `status (occupied|detached)`, `lines[]`, `receipts[]`.
- **Line**: `ticketId, name, variantName, qty, unitPrice, lineTotal, assignedUnits, modifiers[], status, sentAt`.
- **Receipt**: `id, mode, label, subtotal/service/tax/total, status (unpaid|paid), paidNet, lines[{ticketId, qtyUnits}], payments[]`.
- A receipt is `paid` iff `total > 0 && paidNet >= total`. The bill is `fullyAssigned` when every line's units are assigned, `fullySettled` when that holds *and* all receipts are paid.

### Splitting
- **Bayar penuh** — one itemized receipt with `assignAll: true`.
- **Split per item** — multiple itemized receipts; per-line quantity assignment via a stepper sheet, capped by unassigned units (`409 over_assign` server-side).
- **Split rata** — `POST /settlement/visits/:id/split-even {n}` (1–50) replaces all receipts with an even split; blocked if any receipt is already paid.
- **Reset billing method** — deletes all receipts; only offered while `paidAmount == 0`.
- Receipt deletion allowed only while unpaid (`409 receipt_paid`).

### Bill math (`lib/domain/use_cases/bill_math.dart`)
Service-then-tax stacking (Indonesian PB1 convention), integer rupiah throughout:
```
service = serviceOverride
        ?? (!serviceEnabled            → 0
          : serviceMode == 'fixed'     → serviceFixedAmount
          : (subtotal * serviceRateBps) ~/ 10000)

tax     = !taxEnabled ? 0
        : ((subtotal + service) * taxRateBps) ~/ 10000

total   = subtotal + service + tax
```
- Defaults: tax **1100 bps (11%)**, service **500 bps (5%)** percent-mode.
- **Voided and draft lines are excluded** from every subtotal before any computation.
- **Fixed-mode service across split receipts** is distributed proportionally to subtotal share (evenly if all subtotals are 0); the integer remainder lands on the **largest-subtotal** receipt so parts sum exactly.
- **Itemized split** with a known bill target pushes the rounding diff onto the largest receipt's tax so receipts sum exactly to the bill total.
- **Even split** gives every share `billTotal ~/ n` and adds the remainder to the **first** share.

### Payment
- Methods: `tunai`, `kartu`, `qris`, `transfer`, `lainnya` (unknown → `400 bad_method`).
- **Cash**: optional `tendered` field with live change ("Kembalian", green) / shortfall ("Kurang", amber) readout.
- **Non-cash requires a photo proof** (ADR-0025) — `400 photo_required` if absent; camera capture at 1080×1080 / quality 80; submit disabled until captured. Cash payments never store a photo.
- **Refund** — separate `refund` capability; stored as a negative-amount payment row with `isRefund: true`; no photo required.
- Every payment/refund records `cashierUserId` (from the token) and writes an audit row.
- **Photo bytes never travel in bill JSON** — payloads carry only `hasPhoto`. Fetched on demand from `GET /settlement/payments/:id/photo` (live) or `/settlement/history/payments/:id/photo` (snapshotted), opened in a fullscreen zoomable viewer.

### Closing & reopening
- `POST /settlement/visits/:id/bill-close` (cap `settleBill`) — requires `outstanding == 0 && fullyAssigned`, else `409 not_settled`.
- **Write-off (tak tertagih)** — requires the `refund` capability *and* a non-empty reason; sets `lossAmount = outstanding`.
- Any receipt/line/payment mutation on a bill-closed visit returns `409 bill_locked`.
- `POST /settlement/visits/:id/reopen` clears the closure and its loss amount (audited `billReopened`).
- `POST /settlement/receipts/:id/reopen` clears that receipt's payments only — the money stays in the audit log.

### Cashier UI
- **Aktif** tab — live payable list sorted detached-unpaid first, then by outstanding descending. Badges: Lunas / Sebagian / Belum bayar. Detached bills (table already freed) are visually flagged.
- **Riwayat** tab — last 7 days of closed bills, day-grouped, filterable by table chip, showing "tak tertagih" write-off tags.
- **Bill screen** — animated totals card, whole-bill print, write-off action, mode chooser (while no receipts exist), unassigned-lines banner, order-batch-grouped line list matching the KDS batches, per-receipt cards with Bayar / Buka ulang / Refund / Cetak / Hapus chips, and a "Tutup tagihan" bottom bar that mounts only when fully settled.
- Read-only past-bill detail screens with payment proof thumbnails.

### Bill printing
- `POST /settlement/visits/:id/bill/print` and `POST /settlement/receipts/:id/print`, both `{printerId}`, rendered server-side. `502 print_failed` on socket failure.
- The document title flips from **TAGIHAN** to **STRUK PEMBAYARAN** once payments exist — same renderer, two states.

---

## 8. Reports & Exports

### Snapshot endpoint
`GET /reports/snapshot` (cap `viewReports`), params `range ∈ {today, yesterday, d7, d30, month, custom}`, plus `from`/`to`, and optional `server` / `zone` / `category` filters.

**Windowing is business-day-based**, not midnight: `businessDayStartHour` (default 4) anchors every range. Custom ranges are inclusive calendar dates, auto-swapped if reversed, and **capped at 92 days** (enforced on both client and server).

Takeaway sessions count toward sales/menu/payments but are excluded from per-cover, turn-time and occupancy metrics.

### Sections
- **Sales** — Net (Σ session net), Gross (Σ subtotal), a Tax+Service tile (the settled `taxAmount` + `serviceAmount` the venue actually collected), Void amount + voided-line count; weekday cover trend this-week vs last-week; hourly revenue histogram (11:00–22:00); takeaway vs dine-in split.
- **Staff** — per-waiter covers, items, average ticket, void %, net, session count, sorted by net; upsell rate = % of sessions containing both a starter and a main.
- **Menu** — top 5 / slowest 5 by revenue with margin %; modifier attach rates; category mix this-week vs last-week; a **menu-engineering quadrant matrix** (star / plowhorse / puzzle / dog by popularity × margin); top-10 **basket pairs** (co-occurring items within a session).
- **Ops** — average turn time (dine-in only), median prep and median pickup minutes, reservation funnel; **speed section** with `prepMedianMin`, `pickupMedianMin`, `slaPct` against `prepTargetMins`, sample size, and the 5 slowest items; a 7×12 weekday×hour session heatmap; void reasons with lost rupiah; **void-by-staff** as a separate axis from session ownership.
- **Payments** (ADR-0025) — every non-cash, non-refund payment with method, amount, time, table, cashier and a `hasPhoto` flag; non-cash total and per-method totals.
- **Filter options** — full unfiltered lists of servers, zones and categories so dropdowns never truncate themselves.

### Accounting report (ADR-0032)
`GET /reports/accounting` — bookkeeping figures from the **real settled session columns**, the same ones the sales screen reports:
- Revenue block: gross, void, service, tax, net, collected, refunded, session count.
- Per-method: charged / refunded / net with counts.
- Voids per reason with lost rupiah.
- Daily breakdown by closed-at date.

### Order history feed (ADR-0030/0031)
`GET /orders/history` — per closed visit: header (table, kind, pax, closed at, waiter, subtotal/void/net), every line (time, item, variant, modifiers, course, qty, price, status, void reason, ready/served stamps), and every receipt with its payments. Orphan payments whose receipt snapshot is missing are gathered under a synthetic `'—'` receipt so no tender is ever lost.

### Staff report feed
`GET /reports/staff` — union of everyone who ran a session **or** voided a line (so a void-only manager still appears): sessions, covers, items, net, avg ticket, upsell rate, void count/%, lost rupiah, top reason, plus totals.

### Exports
One export sheet, four report kinds × two formats:

| Kind | Source |
|---|---|
| **Umum** (`laporan`) | the in-memory reports snapshot (disabled if none loaded) |
| **Pesanan** (`riwayat-pesanan`) | `GET /orders/history` |
| **Staf** (`laporan-staf`) | `GET /reports/staff` |
| **Akuntansi** (`akuntansi`) | `GET /reports/accounting` |

- **CSV** — UTF-8 **with BOM** (so Excel renders Indonesian text and Rupiah), CRLF rows, RFC-4180 escaping.
- **PDF** — branded letterhead (logo, venue name, address, phone) pulled from venue settings, degrading cleanly to text-only if the logo fails.
- Exports always inherit the Reports screen's active range (shown read-only as a pill) — client-side range scoping, no second picker.
- Filename: `satset-<kind>-<range>-<yyyyMMdd-HHmm>.<ext>`.
- Delivery via the Android share sheet (`Share.shareXFiles`) — the only egress path.
- The **order-history PDF embeds payment proof photos inline** next to their payment row (fetched with bounded concurrency of 4, kept atomic so pagination never splits image from row; an amber "Bukti tidak termuat" placeholder appears if bytes are missing). CSV never carries photos.
- The staff PDF renders landscape because the column set doesn't fit portrait.

---

## 9. Menu Management

### Categories
Create / rename / delete / reorder (`POST /menu/categories/reorder {ids}` sets sort order by index). Delete is blocked with `409 category_not_empty` and a count while items reference it.

### Items
- Fields: `name, categoryId, description, basePrice, cost, prepTime (default 5), variants[], modifierGroups[], allergens[], dietary[], unavailable, stockCount, autoSoldOutAtZero, photoRev`.
- **Variants** — `{id, name, price}` with absolute prices.
- **Modifier groups are embedded per item** (ADR-0009), not a shared library: `{id, name, required, multi, options[{id, name, priceDelta}]}`.
- **Availability** toggle is a separate endpoint under the lighter `markSoldOut` capability, so floor staff can mark items out without full `editMenu`.
- **Stock** — `POST /menu/items/:id/stock` with `{delta}` or `{stockCount}` under `adjustStock`. `isSoldOut = unavailable || (autoSoldOutAtZero && stockCount <= 0)`.
- **Margin preview** in the editor: green ≥40% ("Margin sehat"), amber ≥15% ("Margin tipis"), red below ("Margin kritis").

### Photos (ADR-0014)
Bytes are kept **out** of the menu JSON; only a `photoRev` counter travels. `GET/PUT/DELETE /menu/items/:id/photo` (GET ungated, mutations need `editMenu`); every mutation bumps `photoRev`, which is the client cache key. Upload resizes to 1000×1000 at quality 80, with Android lost-data recovery for the camera picker. Missing photos fall back to an initials avatar.

### Tags (allergens & diets, ADR-0010/0012)
Fully customizable `MenuTag{kind: allergen|diet, name, code, sortOrder}` with CRUD and per-kind reorder. **Delete cascades**: the tag id is stripped from every item's arrays. Allergens are resolved live rather than snapshotted onto tickets (ADR-0012), so correcting an allergen record fixes history too.

### Admin UI
Tablet master-detail (list + editor) with a three-way Item / Kategori / Tag tab; phone pushes a full-screen editor. Client-side search over name and description, plus a category rail filter. Non-admin staff see a read-only view with long-press availability toggle only.

---

## 10. Staff, Roles & Audit

### Staff
- `AppUser{id, name, initials, roleId, zoneAssigned, pin (masked from server), disabled, avatarColorHex, shiftStartedAt}`.
- PIN must match `^\d{6}$`, is unique venue-wide (`409 pin_in_use`), and is stored hashed. Clients generate a unique PIN locally (64 retries).
- PIN reset is flagged so the audit log distinguishes `staffPinReset` from `staffPinSet`.
- Avatar colours from a fixed 12-swatch palette; the client warns on collision but the server permits duplicates.
- Deleting staff nulls their `lastActorId` references and deletes all their sessions (killing live tokens). The `admin` id is undeletable (`409 admin_locked`).

### Roles
Full CRUD with a capability matrix UI (role × capability, grouped by capability group). Delete blocked while members exist (`409 role_in_use`).

### Two hard invariants
1. **Admin is Firebase-only (ADR-0017):** a PIN staff row can never be created into, or reassigned to, a role holding `manageStaff` (`403 admin_role_forbidden`). New roles cannot be created holding `manageStaff`, and an existing role that lacks it cannot be granted it.
2. **Last-admin guard:** any mutation that would leave zero enabled users holding `manageStaff` — disabling, deleting, role reassignment, capability strip, role delete — is rejected with `409 last_admin`.

### Audit log
`AuditEntry{id, type, title, tableId, at, approvedBy, reason, actorUserId}` with types covering voids, table moves, bill close/reopen, payments, refunds, and every role/staff mutation. `GET /audit` (desc), `POST /audit` (any authenticated actor). The server auto-emits entries for its own mutations and broadcasts `audit.created`. The client inserts optimistically with WS-echo dedup and reverts on failure.

---

## 11. Zones & Floor Layout

- `Zone{id, name, short, colorHex, iconKey, sortOrder}` with 8 preset colours and **12 preset icons** (tableRestaurant, deck, park, localBar, weekend, balcony, roofing, eventSeat, window, umbrella, celebration, storefront).
- `short` is auto-derived from the name when not supplied and recomputed on rename.
- Delete blocked with `409 zone_in_use` while tables reference the zone.
- Table CRUD: label, capacity (1–20 stepper; shrinking capacity drags `pax` down), zone, active flag, per-zone reorder.
- Management affordances are admin-only; other roles see a locked pill.

---

## 12. Venue Settings

Singleton row, `GET /venue/settings` (public, self-seeding) / `PATCH` (cap `editSettings`, partial).

| Group | Fields |
|---|---|
| **Identity** | `displayName` (cloud-managed, read-only), `legalName`, `address` (cloud-managed), `phone` |
| **Receipt (ADR-0033)** | `receiptHeader`, `receiptFooter`, `receiptTagline`, `receiptSocial`, `receiptThankYou`, `receiptQrUrl`, `receiptQrCaption`, logo (+`logoRev`) |
| **Tax & service** | `taxEnabled`, `taxRateBps` (0–5000, step 25), `serviceEnabled`, `serviceMode` (`percent`/`fixed`), `serviceRateBps` (step 50), `serviceFixedAmount` (step 1000, cap 1,000,000) |
| **Operations** | `businessDayStartHour` (0–23), `prepTargetMins` (1–120; drives overdue alerts and the report SLA) |
| **Alerts (ADR-0035)** | `soundNewOrder`, `soundReady`, `soundVoid`, `soundOverdue` |

- **Logo**: `GET` ungated, `PUT`/`DELETE` gated, each bumping `logoRev`; uploads downsized to ≤1024 px wide at quality 85.
- **Live receipt preview** — a 300 px monospace "paper" mock bound to the settings as you type: logo, venue name, tagline, address/phone/social, header, sample lines, subtotal/PPN/TOTAL, footer, thank-you, and the QR with caption.

---

## 13. Printing

### Two scopes (ADR-0020)
- **Venue printers** — server-owned DB rows shared by all staff; network ESC/POS only; printing goes through the server.
- **Device printers** — per-phone, stored in local `SharedPreferences`; Wi-Fi or Bluetooth transport; rendered and sent client-side.

Both are merged into one picker sheet along with freshly discovered mDNS printers and OS-paired Bluetooth devices, deduped by address and sectioned Online / Offline.

### Endpoints
`GET /printers` (public), `POST /printers` (any authenticated staff may add), `PATCH`/`DELETE` (cap `editSettings`), `POST /printers/:id/test` (any authenticated staff; `502 print_failed` on failure, stamps `lastSeenAt`, broadcasts `printer.updated`).

### Discovery & liveness
- **mDNS** browse of `_pdl-datastream._tcp` and `_printer._tcp` (4s window), streaming results as they resolve, deduped by `host:port`.
- **Server heartbeat**: a 15-second ticker connect-probes every enabled printer in parallel and stamps `lastSeenAt`; clients treat a printer as online within a 30-second freshness window.
- The picker sheet additionally probes every 10s while open — TCP connect-and-drop (2s timeout) for network printers, connect-and-disconnect for Bluetooth.

### Bluetooth (ADR-0022)
OS-paired classic-SPP devices only — the app never air-scans (so no BLE scan or location permission). Requests `BLUETOOTH_CONNECT` on Android 12+; surfaces contextual "Izinkan Bluetooth" / "Nyalakan Bluetooth" affordances. Send = connect → write → disconnect.

### Documents (58 mm, `esc_pos_utils_plus`)
1. **Struk pesanan** — the guest order confirmation slip, deliberately **priceless**: logo, venue block, table/pax/time, guest name and note, per-line `qty × name (variant)` with indented modifiers and notes, "Verifikasi pesanan Anda", footer, thank-you.
2. **Tagihan / Struk pembayaran** — the money document. Three kinds: whole bill, itemized receipt, even-split receipt. Shows a two-column item/price body, totals block (Subtotal / Layanan / Pajak / TOTAL), a payment block once payments exist (per-payment method, cash tendered + change, then SISA or a bold centered LUNAS), footer, and the money-only footer QR with caption.

Both are built from a shared builder that produces identical bytes whether called from the client (typed `Bill`) or the server (raw settlement map).

### Rendering details
- **Logo rasterization** downscales to ≤384 px width rounded to a multiple of 8 and emits via **ESC \*** rather than GS v 0 — many cheap print heads don't support GS v0 and would desync the entire receipt. Any decode failure returns zero bytes rather than blocking the print.
- Currency formatting is hand-rolled (dot-grouped, `Rp` prefix, no `intl`) so server and client render byte-identically.
- Transport is raw TCP JetDirect port 9100 with a 5s connect timeout and a 120 ms drain delay before close.

---

## 14. Cloud Control Plane

### Cloud Functions (`functions/index.js`, Node 22, all gated by `assertSuper()`)
| Function | Purpose |
|---|---|
| `createAdmin` | Creates a Firebase Auth user with custom claims `{role, venueId}` + an `admins/{uid}` doc. `role ∈ {admin, owner}`. |
| `backfillAdminClaims` | Idempotent one-time claim backfill for pre-claims admins. |
| `setAdminStatus` | Sets `admins/{uid}.status`, mirrored to the Auth `disabled` flag. |
| `deleteAdmin` | Deletes the Auth user and its doc. |
| `resetAdminPassword` | Generates a password-reset link. |
| `createVenue` | Creates `venues/{id}` with `status: active`, plan, `billingStatus: trial`. |
| `updateVenue` | Patches name/address. |
| `setVenueStatus` | **The kill switch** — active / suspended / banned. |
| `setVenueBilling` | Plan, billing status, paid-until. |
| `deleteVenue` | Blocked while any admin is still attached. |

### Firestore rules
Default-deny. `admins/{uid}` readable by self or super, **never client-writable**. `venues/{vid}` readable by super or that venue's own admin; **updatable only for the single `lastSeenAt` field** — status and billing are function-only. `reports/{vid}` readable by the venue's admin or its owner, writable only by that venue's own host. `report_requests/{vid}` lets the owner write only `requestedAt`.

### Fleet console (`/fleet`, super only)
Live venue list from a Firestore stream, **sorted by lockout risk** (venues approaching the 7-day offline staleness limit within a 48h warning window) then alphabetically. Per-venue: status pill, plan, billing status, online/offline duration derived from `lastSeenAt`, lockout-risk pill, and quick actions activate / suspend / ban. Venue editor covers identity, billing, the attached admin and owner lists (add / activate / suspend / ban / reset password / delete), and a danger-zone venue delete gated on zero attached accounts.

### Venue identity mirror (ADR-0018)
Cloud is the source of truth for venue name and address: every `venues/{vid}` snapshot is diffed against local venue settings and patched down if changed, so receipts and in-app branding track the fleet console.

### Owner report snapshot (ADR-0036)
The **host** publishes to `reports/{vid}` every **30 minutes** (plus once on boot), covering the `today` and `d7` ranges, pulled from its own local `/reports/snapshot`. It also watches `report_requests/{vid}` for an owner-triggered manual refresh (debounced, stale requests ignored).

The **owner** app streams that doc into the exact same report widget tree the on-site admin sees, minus proof photos (`showProofPhotos: false` — photo bytes are LAN-only and never leave the venue). Freshness is shown as "Diperbarui X lalu"; the manual refresh button has a 30-second cooldown.

---

## 15. Realtime & Resilience

### WebSocket hub
In-memory fan-out; every event is a `WsEventDto{v: 1, type, payload, ts}`. Authenticated via `?token=` on upgrade. Per-socket send errors are swallowed so one dead client can't stall a broadcast.

**Event types:**
`table.created/updated/deleted`, `ticket.created/updated`, `tableSession.closed`, `bill.updated`, `menu.updated`, `zone.created/updated/deleted`, `staff.created/updated/deleted`, `roles.updated`, `reservation.created/updated/deleted`, `printer.created/updated/deleted`, `device.paired`, `device.revoked`, `session.expired`, `venueSettings.updated`, `audit.created`, `server.restarting`.

### Reconnect & resync (ADR-0021)
Client reconnect uses exponential backoff (`200ms × 2^n`, capped at 10s) and waits for `channel.ready` before reporting `open` (no flicker on a failed handshake). On every (re)connect a **synthetic local `connected` event** is injected, which repositories treat as "you missed events — resync":
- `TablesRepository` — guarded, never-throwing full `GET /tables` refetch.
- `TakeawayRepository` — full refetch (also on `bill.updated`, ticket events, session close).
- `TicketsRepository` — relies on the visit-keyed map; drops a visit's group on `tableSession.closed`.
- `ReservationsRepository` — 15-day bootstrap window is self-healing.
- `DevicesRepository` — refetches on pair/revoke/session-expiry.

### Other resilience mechanisms
- **Idempotency table** backs staff order submission.
- **Server restart** (`POST /server/restart`, cap `manageStaff`, additionally gated behind a **PIN re-entry dialog** even for an already-authenticated admin) broadcasts `server.restarting` *before* replying 202, then rebinds both listeners on the same port and TLS context without touching the DB. Clients return within about a second via backoff.
- **Latency instrumentation** — a rolling 100-sample window yields p50/p95 per request, surfaced in `GET /server/status`.
- **8-second client request timeout** so a dead paired server surfaces an error instead of hanging on the OS connect timeout.
- **Error bus** — a single app-wide broadcast stream of `AppError{level: info|warning|error}` that repositories push to and the UI renders.

---

## 16. System & Diagnostics Screen

- **Hero**: "Server LAN OK" vs "Mode degraded", with ping ms, active sessions, paired devices, WS state, and a 6-segment health meter (WS open, reachable, sessions >0, devices paired, status present, p95 <500 ms).
- **Stat tiles**: KDS online, paired tablets, queue depth.
- **Server LAN card**: listen address, uptime, **TLS certificate expiry**, LAN ping p50/last, p95 latency, request count, and a copyable truncated cert fingerprint.
- **Printer & KDS card**: venue printers with host:port, kind, test button and an online pill; KDS stations with staff-online and pending counts. Actions: mDNS "Cari" discovery dialog and manual "+ Printer".
- **Devices card**: label, last session time, revoke button with confirmation, Aktif / Idle / Revoked pill.
- **Operasional card**: master audio-alert toggle and the PIN-gated server restart.
- **Seed data**: `GET /seed/state` reports whether the venue is still empty; a blocking, non-dismissible first-run dialog on the Venue Hub offers `POST /seed/generic` — an idempotent sample load (4 zones × 20 tables, a generic menu, bahan + resep with opening stock, and 4 staff: 2 waiters + 2 kitchen) followed by a fabricated month of ~1500 settled bills written through the production order path, progress streaming over `seed.progress`. `POST /seed/skip` records the answer instead; `POST /seed/clear` deletes the tagged transactional rows and leaves the menu standing. Emits the appropriate created events and an audit entry.
- `GET /healthz` — unauthenticated liveness probe.

---

## 17. Alerts, Design System & Cross-Cutting UI

### Alert sounds (ADR-0035)
Four events — `newOrder`, `orderReady`, `voided`, `overdue` — each independently mapped to one of **21 bundled presets** (Senyap/silent, alarm, alert, beep, bell, chime, click, critical alarm, ding, doorbell, facility alarm, game alarm, happy bell, harp, marimba, pop, remove, reward, short alarm, start, ting). Defaults: newOrder `alert`, ready `chime`, void `alert`, overdue `alert`; an unknown stored id degrades gracefully back to the default.

**Routing is mode-aware** — the server device hears new-order and kitchen-recall voids; client devices hear ready and targeted voids. Each preset is preloaded into its own player for instant replay, a 500 ms leading-edge debounce collapses bursts, client plays fire a medium haptic, and a 20-second server-side scan raises `overdue` when a ticket's age exceeds `prepTargetMins`.

### Notification surfaces
- **ReadyToast** — top slide-in (ease-out-expo, 400 ms in / 260 ms out, 3 s dwell) with an "Ambil" action routing to the table or takeaway.
- **ReadyBanner** — inline success banner.
- **AdminGraceBanner** — offline-grace countdown with warn and critical tiers.
- **SeedDataBanner** — empty-venue nudge.

### Design system (`lib/ui/core/design/`)
- `SatColors` as a `ThemeExtension` with dark and light palettes: `bg0–4`, `border0–2`, `textHi/Md/Lo/Dim`, an orange accent family, semantic `success / warn / urgent / info / violet` each with a soft alpha variant, plus five fixed course colour slots.
- Material 3 theme built per brightness; 28 px bottom-sheet radius; zero splash and elevation throughout.
- Theme mode is a provider defaulting to dark.

### Responsive shells
`AppShell` picks a tablet or phone layout from `context.layout.useTabletShell`. Hardware decides and there is no override: `MainActivity` pins orientation at launch from `smallestScreenWidthDp` — tablets landscape, phones portrait — and holds the screen awake for the whole session (ADR-0049). The tablet shell is a 76 px icon side rail (Meja, Pesanan, Antrian, Kasir when permitted, Venue) with badge counts and a bottom user-avatar button; the phone shell uses a top bar plus a floating tab bar. Nearly every admin screen branches explicitly between `_tablet()` and `_phone()`.

Order-taking, takeaway and menu-editor routes deliberately live **outside** the shell so root-navigator pushes give full-page transitions.

### Micro-interactions & formatting
Shimmer skeletons that collapse to static blocks under `MediaQuery.disableAnimations`; staggered `Reveal`, `PressScale`, `AnimatedReflow`, `AnimatedCount` and `ExpandFade` primitives; a shared 240 ms ease curve. Formatting helpers cover Indonesian rupiah, a live thousands-grouping text input formatter (with signed support for modifier deltas), clock strings, and Indonesian relative durations ("20d", "1j 12m 20d", "kemarin", "N hari lalu").

---

## 18. Data Model Summary

**Live/operational tables:** `Users`, `Roles`, `Zones`, `VenueTables`, `Visits`, `DailyCounters`, `MenuCategories`, `MenuItems`, `MenuTags`, `Tickets`, `Sessions`, `Devices`, `Idempotency`, `VenueSettings`, `Printers`, `AuditEntries`, `Receipts`, `ReceiptLines`, `Payments`, `Reservations`.

**Immutable history tables** (written by `snapshotVisitAndDelete`, the source of truth for all reporting): `TableSessions`, `TableSessionTickets`, `TableSessionReceipts`, `TableSessionPayments`, `TableSessionCourses`.

Schema version 34 at time of writing. All money is stored as integer rupiah — there are no floating-point amounts anywhere in the money path.

---

## 19. Build, Release & Testing

- **CI**: Codemagic workflow `android-release-distribute` on a mac_mini_m2, triggered by pushing a `v*` git tag. Injects the release keystore, runs `flutter pub get` + `flutter build apk --release`, and uploads to **Firebase App Distribution** (group `testers`) via a service account.
- **Firebase project** `satset-3a795`; Cloud Functions on the nodejs22 runtime.
- **Android permissions**: `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE` (mDNS), `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_DATA_SYNC` + `WAKE_LOCK` (server-mode foreground service), `POST_NOTIFICATIONS`, `CAMERA`, `BLUETOOTH_CONNECT` plus legacy Bluetooth permissions capped at SDK 30. **No location permission** — a deliberate consequence of not air-scanning for Bluetooth.
- **Key dependencies**: `flutter_riverpod`, `go_router`, `drift` + `sqlite3_flutter_libs`, `shelf`/`shelf_router`/`shelf_web_socket`/`web_socket_channel`, `flutter_secure_storage`, `bonsoir` (mDNS), `basic_utils` + `dart_jsonwebtoken` + `crypto` (TLS/JWT), `firebase_core`/`auth`/`firestore`/`functions`, `qr_flutter`, `print_bluetooth_thermal` + `esc_pos_utils_plus`, `pdf` + `printing` + `share_plus`.
- **Testing**: `patrol` native integration tests in `patrol_test/` (app boot, menu categories, modifier sheet, modifier snapshot) plus unit/widget tests in `test/`.
- **Codegen** (`freezed`, `json_serializable`, `drift_dev`) is scoped to `lib/data/models/**`, `lib/domain/models/**` and `lib/server/db/**` only; all UI, repositories, services, routes and use cases are hand-written.

---

## Appendix A — Complete HTTP API Surface

### Auth & pairing
```
POST   /auth/login                 POST   /auth/admin
POST   /auth/logout                GET    /auth/me
POST   /pair/claim                 POST   /pair/auto-claim
GET    /healthz
```

### Floor & tables
```
GET    /tables                     POST   /tables
PATCH  /tables/<id>                DELETE /tables/<id>
PATCH  /tables/<id>/pax            PATCH  /tables/<id>/handler
POST   /tables/<id>/seat           POST   /tables/<id>/pending
POST   /tables/<id>/release        POST   /tables/<id>/close
POST   /tables/<id>/move           POST   /tables/<id>/print
POST   /tables/<id>/lock           POST   /tables/<id>/lock/heartbeat
DELETE /tables/<id>/lock           POST   /tables/<id>/ready/decrement
POST   /tables/<tableId>/course/<course>/fire
GET    /takeaway/visits            POST   /visits/<id>/handover
```

### Orders & tickets
```
GET    /tickets                    POST   /orders
POST   /tickets/<id>/transition
GET    /kds/stations               GET    /queue/depth
```

### Menu
```
GET    /menu
POST   /menu/categories            PATCH  /menu/categories/<id>
DELETE /menu/categories/<id>       POST   /menu/categories/reorder
POST   /menu/items                 PATCH  /menu/items/<id>
DELETE /menu/items/<id>
POST   /menu/items/<id>/availability
POST   /menu/items/<id>/stock
GET    /menu/items/<id>/photo      PUT    /menu/items/<id>/photo
DELETE /menu/items/<id>/photo
POST   /menu/tags                  PATCH  /menu/tags/<id>
DELETE /menu/tags/<id>             POST   /menu/tags/reorder
```

### Settlement
```
GET    /settlement/payable
GET    /settlement/history
GET    /settlement/visits/<visitId>/bill
POST   /settlement/visits/<visitId>/receipts
POST   /settlement/visits/<visitId>/split-even
POST   /settlement/visits/<visitId>/bill-close
POST   /settlement/visits/<visitId>/reopen
POST   /settlement/visits/<visitId>/bill/print
DELETE /settlement/receipts/<receiptId>
POST   /settlement/receipts/<receiptId>/lines
POST   /settlement/receipts/<receiptId>/payments
POST   /settlement/receipts/<receiptId>/refund
POST   /settlement/receipts/<receiptId>/reopen
POST   /settlement/receipts/<receiptId>/print
GET    /settlement/payments/<id>/photo
GET    /settlement/sessions/<sessionId>/bill
GET    /settlement/history/payments/<id>/photo
```

### Reports
```
GET    /reports/snapshot           GET    /reports/accounting
GET    /reports/staff              GET    /orders/history
```

### Reference & admin
```
GET    /zones                      POST   /zones
PATCH  /zones/<id>                 DELETE /zones/<id>
GET    /staff                      POST   /staff
PATCH  /staff/<id>                 DELETE /staff/<id>
GET    /roles                      POST   /roles
PATCH  /roles/<id>                 DELETE /roles/<id>
GET    /reservations               POST   /reservations
PATCH  /reservations/<id>          DELETE /reservations/<id>
GET    /audit                      POST   /audit
GET    /venue/settings             PATCH  /venue/settings
GET    /venue/logo                 PUT    /venue/logo
DELETE /venue/logo
GET    /printers                   POST   /printers
PATCH  /printers/<id>              DELETE /printers/<id>
POST   /printers/<id>/test
GET    /devices                    POST   /devices/<id>/revoke
GET    /server/status              POST   /server/restart
GET    /seed/state                 POST   /seed/generic
```


## Appendix B — Screen / Route Map

| Route | Screen | Gate |
|---|---|---|
| `/pin` | PIN entry + inline mode select + pairing | — |
| `/onboarding` | Server vs Client mode | — |
| `/pair` | mDNS browse + QR scan + manual entry | — |
| `/forbidden` | Capability-denied landing | — |
| `/fleet` | Fleet console | super admin |
| `/owner` | Owner report snapshot | owner |
| `/tables` | Floor grid (+ reservations & takeaway strips) | — |
| `/orders` | Orders board | `takeOrder` |
| `/kitchen` | KDS | `viewKds` |
| `/kasir` | Cashier (Aktif / Riwayat) | `settleBill` |
| `/venue` | Venue hub | `manageStaff` |
| `/venue-settings` | Venue settings + receipt preview | `editSettings` |
| `/zone-admin` | Zones & tables | `manageStaff` |
| `/menuadm`, `/menuadm/:id` | Menu admin + item editor | `manageStaff` |
| `/reports` | Reports + export sheet | `viewReports` |
| `/system` | Server / printers / devices diagnostics | `manageStaff` |
| `/staff` | Staff, roles, permission matrix | `manageStaff` |
| `/me` | Own profile / sign out | — |
| `/table/:id` (+ `/menu`, `/review`, `/sent`) | Table-first ordering flow | `takeOrder` |
| `/order/new` (+ `/review`) | Menu-first / table-less draft | `takeOrder` |
| `/takeaway/:visitId` (+ `/menu`, `/review`) | Takeaway detail & add items | `takeOrder` |
