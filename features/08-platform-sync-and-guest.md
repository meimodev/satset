# 08 · Platform, sync, guest self-order & the shell

This document covers the plumbing every other feature stands on: choosing Server or Client mode, mDNS pairing over self-signed TLS, PIN and admin (Firebase) authentication and the admission outcome ladder, the WebSocket hub and reconnect-resync, the offline send queue (**Antrean kirim**), the guest self-order plane (a second cleartext socket with its own SPA), the app shell (phone vs tablet), theming/skins, ID/EN localisation, the `/me` screen, and the debug widget book. It does not cover the offline settlement journal (**Antrean setelmen**, ADR-0123) or ticket/order domain logic — those belong to other feature docs.

## Feature index

| Feature | Route | Capability | Server |
|---|---|---|---|
| Mode select (Server/Client) | `/onboarding` | none (pre-auth) | boots `ServerRuntime` locally |
| Staff PIN sign-in | `/pin` | none (pre-auth) | `POST /auth/login` |
| Admin (Firebase) sign-in | `/pin` (admin panel) | none (pre-auth, Firebase) | in-process, no HTTP |
| mDNS discovery + auto-claim pairing | `/pin` | none (pre-auth) | `POST /pair/auto-claim` |
| Session restore | app boot | — | `GET /auth/me` (or cached) |
| Fleet console (super admin) | `/fleet` | `isSuperAdmin` | cloud only, no local server |
| Owner report viewer | `/owner` | `isOwner` | cloud only, no local server |
| WebSocket hub + resync | — | — | `GET /ws` |
| Antrean kirim (send queue) | shown on `/me`, dialog from shell | `takeOrder`/etc per intent | ordinary routes, replayed |
| Guest queue (Tamu) | `/selforder` | `takeOrder`, `editSettings` | `GET/POST /selforder/...` |
| Guest self-order config | `/selforder-admin` | `editSettings` | `PATCH /selforder/...` |
| Guest self-order plane (guest phone) | `http://<lan-ip>:8080/t/<code>` | none (no bearer) | second cleartext listener |
| App shell (phone/tablet) | every shell route | — | — |
| Theme picker | `/me` sheet | none | device-local |
| Language picker | `/me` sheet | none | device-local |
| `/me` — shift snapshot & sign-out | `/me` | none | `GET /auth/me`-derived state |
| Debug widget book | `/book` (debug builds only) | none | — |

---

## Server / Client mode select (Mode server / Mode klien)

**What** The first decision an unpaired device makes: host the venue's embedded server (Server mode) or connect to one already running on the LAN (Client mode).

**Who** Whoever sets up a device — an owner turning a tablet into the till, or a waiter pairing a phone.

**Where** `/onboarding` (`ModeSelectScreen`, `lib/ui/features/onboarding/views/mode_select_screen.dart`).

**How to use**
1. On first launch, the app lands on `/pin`, but an unpaired device without a chosen mode reaches `/onboarding` via the PIN screen's inline flow.
2. Tap **Server** (`onbModeServer`) to host the venue on this device, or **Client** (`onbModeClient`) to join one already running.
3. Choosing Server persists `AppMode.server` and, on Android, boots `ServerRuntime.boot()` in-process if nothing is running yet; the local `apiConfigProvider` is then published pointing at `https://127.0.0.1:<port>`.
4. Choosing Client persists `AppMode.client` and returns to `/pin`, where mDNS discovery and auto-claim pairing take over.

**Under the hood**
- `ModeSelectViewModel.choose()` (`lib/ui/features/onboarding/view_models/mode_select_view_model.dart:38`) writes `AppMode` via `PrefsService.setAppMode`, and for Server mode calls `ServerRuntime.boot(venueId:, version:)` (`lib/server/server.dart:153`).
- `ServerRuntime.boot` opens the Drift DB (`AppDatabase.open()`), runs `seedInfra`, loads/creates TLS material (`ServerTls.loadOrCreate()`), constructs `WsHub`, mints the `ServerAuth` secret, starts the shelf listener on port **7443** (`ServerRuntime.defaultPort`) with the middleware pipeline (latency/logging → CORS → auth), starts mDNS advertising (`SatSetAdvertiser`), syncs the guest plane, and starts the status ticker and printer heartbeat.
- `domain/models/app_mode.dart` defines `AppMode { unset, server, client }`.
- The staff PIN sign-in also carries an inline mode-select+pairing UX baked into `PinScreen` itself (`SignInMode.admin | staff`, `StaffStage.pickingServer | connected | enteringPin` — see `lib/ui/features/auth/view_models/pin_view_model.dart:39`), so `/onboarding` is the fallback entry, not the only one.

**Offline behaviour** Choosing Server mode requires no network — the embedded server is entirely local. Choosing Client mode requires the LAN (for mDNS) but no WAN.

**ADRs** ADR-0002 (embedded shelf server in-app), ADR-0017 (main-device host guard, narrowed by ADR-0077), ADR-0098 (admission staged gauntlet).

**Gotchas** `modeSelectViewModelProvider` is deliberately **not** `autoDispose` — `PinViewModel` reads it without watching and awaits the long-running `ServerRuntime.boot()`; an autoDispose provider risks being torn down mid-boot and losing its error state.

---

## mDNS discovery + auto-claim pairing

**What** LAN-trusted device pairing with no out-of-band secret: a client device browses mDNS for a SatSet server, verifies its TLS certificate fingerprint, and the server writes a `devices` row directly. QR/token pairing (`/pair/claim`) was removed entirely — see ADR-0080.

**Who** Anyone setting up a new client device (waiter phone, second tablet).

**Where** `PinScreen` (`lib/ui/features/auth/views/pin_screen.dart`), `_ServerList` / `_ManualAddressDialog` widgets on it.

**How to use**
1. On the PIN screen in `SignInMode.staff` at `StaffStage.pickingServer`, the app shows discovered servers from `MdnsBrowserService` (`_satset._tcp` service type).
2. Tap a discovered server (`_ServerRow`) to auto-claim it, or open **Hubungkan Manual** (`pinManualEntryTitle`) to type an IP:port when mDNS multicast is blocked.
3. On success the device is paired: the server's cert fingerprint is stored and every future request is pinned to it.
4. **Ubah server** (`pinChangeServer`, an edit icon) reopens the picker; **Lupakan server ini** (`pinResetPairing`, ADR-0098) clears the pairing behind a confirm.

**Under the hood**
- `MdnsBrowserService` (`lib/data/services/mdns_browser_service.dart:50`) wraps `BonsoirDiscovery` for service type `_satset._tcp`, filters entries missing `fp`/`label` TXT attributes or resolving to the device's own interfaces, and emits the current set on every change. `findFingerprintHost` / `findVenueHost` do a bounded one-shot scan (default 3s window) — used both for pairing and for post-pairing relocation.
- `SatSetAdvertiser` (`lib/server/mdns.dart:15`) broadcasts TXT attributes `fp` (SHA-256 cert fingerprint), `label`, `ver` (app version), `vid` (cloud venue id, ADR-0017 — a second device entering Server mode for the same `vid` joins as a client instead of starting a rival).
- `PinViewModel.selectDiscovered()` (`lib/ui/features/auth/view_models/pin_view_model.dart:496`) POSTs to `/pair/auto-claim` over a TLS-pinned `IOClient` (`ApiClient.buildPinnedHttpClient`), body `{deviceId, deviceLabel: 'satset-client', publicKey: ''}`. On success it refuses to trust a returned fingerprint that doesn't match the one it pinned (`fingerprint mismatch — refuse to trust server`), stores the fingerprint + `res.serverPublicKey` in secure storage, and persists the paired host/port.
- `connectManualAddress()` (same file, line 562) probes `https://<host>:<port>/healthz` with a `badCertificateCallback` that captures the presented cert's SHA-256 fingerprint (TOFU), then calls `selectDiscovered` with that fingerprint.
- Server side: `POST /pair/auto-claim` (`lib/server/server.dart:370`) is in the auth middleware's skip set alongside `/healthz` and `/auth/login` (`lib/server/server.dart:532`). It reads `deviceId`/`deviceLabel`/`publicKey`, refuses (`403 device_revoked`) if the device row exists and is already `revoked`, then `insertOnConflictUpdate`s the `devices` row and broadcasts `WsEventTypes.devicePaired`. Reaching this handler at all *is* the proof of LAN presence — there is no separate out-of-band token (ADR-0080).
- **Fingerprint-based relocation** (`lib/data/services/server_relocator.dart`, ADR-0080 amendment): when `WsClient` hits `WsClient.relocateAfter` (5) consecutive failed connects, it re-browses mDNS and adopts a new host **only if the candidate's fingerprint equals the stored one** — a different fingerprint is refused as a different server.

**Offline behaviour** Pairing itself requires the LAN (mDNS + a reachable server) but no WAN. Once paired, the fingerprint pin persists in secure storage and survives restarts; a moved host is auto-relocated as long as the certificate matches.

**ADRs** ADR-0003 (pairing/mDNS/QR/TLS, superseded in part), ADR-0080 (self-order & token pairing removed — auto-claim is the only path; amendment adds fingerprint-based relocation), ADR-0017 (main-device host guard).

**Gotchas** A venue whose Wi-Fi blocks mDNS multicast has no pairing path beyond the manual IP:port fallback — there is deliberately no restored `/pair/claim` token flow. The server fingerprint is the server's **identity**, not merely a handshake artifact — losing sight of that is how the relocation logic would be built wrong.

---

## Self-signed TLS

**What** Every embedded server generates its own 5-year self-signed RSA-2048 certificate on first boot and pins it as the sole trust anchor clients use (no CA, no OS trust store).

**Where** `lib/server/tls.dart` (`ServerTls`).

**Under the hood**
- `ServerTls.loadOrCreate()` (`lib/server/tls.dart:37`) looks for `satset.cert.pem` / `satset.key.pem` under `getApplicationSupportDirectory()`; if absent, generates an RSA-2048 keypair (`CryptoUtils.generateRSAKeyPair`), a CSR (`CN: satset.local`), and a self-signed cert valid for `365 * 5` days via `X509Utils`. The `SecurityContext(withTrustedRoots: false)` refuses OS-trusted CAs entirely.
- The fingerprint is `sha256(DER bytes)`, exposed as `ServerTls.fingerprint` — this is the value advertised over mDNS (`fp` TXT attribute) and pinned by every client.
- `ApiClient.buildPinnedHttpClient(fingerprint, isLoopback:)` is the client-side counterpart that refuses any TLS handshake whose presented cert doesn't match — used for both the REST client and the WebSocket's `IOWebSocketChannel.customClient`.

**Offline behaviour** Entirely local; no CA round-trip ever occurs.

**ADRs** ADR-0002, ADR-0003.

**Gotchas** Certificate rotation is out of scope for the in-app `restart()` — a restart rebinds the listener on the same port with the same TLS context; rotating the cert would require a fresh boot.

---

## Staff PIN authentication

**What** PIN-against-local-server sign-in for waiters, kitchen, cashiers. Server-side hashing is salted PBKDF2 with a no-lockout, clock-based throttle (ADR-0112).

**Where** `lib/server/auth.dart` (`ServerAuth`), `lib/server/pin.dart` (hashing), `PinScreen` staff half.

**How to use**
1. On `/pin` in `SignInMode.staff`, once `StaffStage.connected` (a server is paired and reachable), enter a numeric PIN.
2. `POST /auth/login` with `{pin, deviceId}` returns a session; `GET /auth/me` follows immediately to fetch capabilities.
3. A wrong PIN is met with an increasing but never-locking delay (see below); a right PIN clears it.

**Under the hood**
- `hashPin` (`lib/server/pin.dart:46`) is `pbkdf2-sha256$<iterations>$<base64 salt>$<base64 hash>`, 10,000 iterations by default (`pinIterations`). `verifyPin` also recognises the pre-ADR-0112 bare-hex legacy scheme (`isLegacyPinHash`) so an old venue's rows keep working, and re-hashes a legacy row to the new scheme the moment its owner signs in (inside `usersForPin`, on its own isolate).
- `usersForPin`/`userForPin` (`lib/server/pin.dart:127`, `:166`) **scan** every enabled user's hash rather than doing a keyed lookup — a salted hash cannot be looked up by value. Ambiguity (two users sharing a PIN) is refused rather than guessed, returning `null` from `userForPin`.
- **No lockout, deliberately** (ADR-0112, `lib/server/auth.dart:44`): `ServerAuth.pinThrottle(deviceId)` computes a per-*device*, in-memory backoff — 2 free attempts (`pinFreeAttempts`), then doubling delay capped at 60s (`pinMaxBackoff`). A restart (a physical act by whoever holds the tablet) clears it. A hard lockout on shared floor hardware would be a denial-of-service any colleague could inflict.
- `ServerAuth.signInWithPin({pin, deviceId})` mints an HS256 JWT (`sub`, `role`, `deviceId`, `iat`, `exp`), TTL **12 hours** (`ServerAuth.tokenTtl`), and persists a `sessions` row.
- `ServerAuth.resolveBearer(token)` (`lib/server/auth.dart:251`) verifies the JWT signature, checks the stored session hasn't expired, and — per the ADR-0102 amendment — re-reads the user's live `disabled` flag on **every** request rather than trusting the token's claim, so a disabled user's live token stops working immediately rather than up to 12 hours later.

**Offline behaviour** Staff PIN sign-in is entirely LAN-local; no WAN dependency at all.

**ADRs** ADR-0004 (auth/PIN/JWT/capabilities), ADR-0112 (PIN hashed with salt, throttled by clock, no lockout), ADR-0102 (live-read authorization amendment).

**Gotchas** Never assume `resolveBearer` is a pure JWT-signature check — it joins live DB state. `ServerAuth.hashPassword` (a distinct sha256-based scheme) exists only for a legacy password path, not PIN.

---

## Admin (Firebase) authentication & the admission ladder

**What** The venue owner/admin signs in with email+password against Firebase, not a local PIN. Six network-shaped steps (sign-in → fetch admin profile → fetch venue → main-device guard → boot server → mint local session) collapse into one sealed `AdmissionOutcome` with 15 subclasses (ADR-0098).

**Who** The single active admin of a venue (ADR-0077 — exactly one admin, one device; a second admin candidate is refused, not admitted).

**Where** `lib/domain/models/admission.dart` (the sealed type), `lib/data/repositories/auth_repository.dart` (`signInAsAdmin`, `_admit`), `lib/core/localization/admission_text.dart` (the exhaustive copy resolver), `PinScreen._AdminAuthForm`.

**How to use**
1. On `/pin`, switch to `SignInMode.admin` via `_ModeSwitcher`.
2. Enter email + password in `_AdminAuthForm` and submit.
3. On success as the venue's host admin, the embedded server boots (if not already) and the app lands on `/venue`. On success as a fleet super admin, the app routes to `/fleet` (bypassing the pair gate entirely, ADR-0016). On success as a report owner, it routes to `/owner` (ADR-0036).
4. A refusal shows the outcome's composed copy (never a raw error) with a **Coba lagi** retry where applicable; **Batal** cancels the in-flight attempt cleanly via an attempt-token (`cancelAdmission()`), which also signs the Firebase session back out.

**Under the hood**
- `AdmissionOutcome` (`lib/domain/models/admission.dart:30`) is sealed with 3 admitted subclasses (`AdmittedAsHost`, `AdmittedAsSuper`, `AdmittedAsOwner`), 1 continuation (`AdmissionNeedsNewPassword` — a dictated temporary password, ADR-0075), and refusals: `AdmissionCredentialsRejected(code)`, `AdmissionTempPasswordExpired`, `AdmissionNotRegistered`, `AdmissionAccountBlocked(AdmissionBlock reason)`, `AdmissionNoVenue`, `AdmissionVenueBlocked(reason)`, `AdmissionHostOccupied(hostLabel)`, `AdmissionServerBootFailed`, `AdmissionLocalSessionFailed`, `AdmissionUnreachable(stage)`, plus `AdmissionCancelled`. `AdmissionBlock` is `{suspended, inactive, notFound}`.
- `AuthRepository.signInAsAdmin()` (`lib/data/repositories/auth_repository.dart:250`) wraps the whole gauntlet in a 25s budget (`_admissionBudget`); `_admit()` gives each network stage its own 8s timeout (`_stageTimeout`) — a stage timeout returns `AdmissionUnreachable(stage)`, where `stage` is logged but never shown (the copy is the same regardless of which call died: "cannot reach the identity server").
- The stage order inside `_admit` (`:286`): Firebase `signIn` → `fetchAdmin` (cache-first unless `freshProfile`) → temp-password check → super/owner diversion → active-account check → venue lookup → venue kill-switch check → **main-device guard** (`mdnsBrowserServiceProvider.findVenueHost(venueId)`, ADR-0017/0077 — if another device already advertises this `venueId`, refuse with `AdmissionHostOccupied` **without signing the Firebase session out**, because the condition self-clears) → `bootServer(venueId)` → `_establishAdminSession` (in-process, no HTTP round-trip) → start the live eligibility watch.
- **Cancel is an attempt token, not a flag** (`_admissionAttempt`, bumped on submit and cancel): a result whose token is stale is dropped rather than written, and `signOut()` fires on the way out — Firebase futures cannot be cancelled, so this is what makes cancel not a lie.
- `admission_text.dart` has one exhaustive `switch` over all 15 subclasses; adding a 16th outcome fails to compile until it is named there — this is deliberately how the ADR-0085 "code crosses the layer, not a sentence" rule is enforced for this flow.

**Offline behaviour** **No offline path exists for admin sign-in** (ADR-0099) — it requires 4 WAN round trips before any local machinery runs, and there is no cached-credential grace, no local admin password, no "trust the last verdict". This is a deliberate asymmetry: a **boot** (a device already admitted before, restoring from a stored token) is offline-tolerant via `restoreFromStoredToken` / cached `/auth/me`; a fresh **sign-in** is not. The venue's own eligibility kill switch (`admins/{uid}.status`, `venues/{vid}.status`) stays two-sided and online-authoritative on purpose — a kill switch that can be outrun by pulling a network cable isn't one.

**ADRs** ADR-0098 (one staged gauntlet, one outcome), ADR-0099 (admin sign-in has no offline path), ADR-0077 (one admin, one device), ADR-0075 (dictated temporary password), ADR-0016 (fleet superadmin), ADR-0036 (owner cloud report), ADR-0015 (Firebase admin auth & kill switch, referenced).

**Gotchas** `AdmissionBlock` is declared in the domain layer, not imported from the data layer's `AdminStatus` — the repository maps one to the other in one function, to avoid inverting the layer rule. `provisionAdminUser`/`mintSession` in `ServerAuth` open a shift as a side effect (a shift *is* a signed-in session, ADR-0097) — skipping `mintSession` for an in-process admin login would make the host's own attendance invisible to reports.

---

## Session restore vs admin sign-in

**What** A device that has already been admitted restores its session from a stored JWT (and, if the host is unreachable, from a cached `/auth/me` payload) without ever touching Firebase again. This is deliberately more forgiving than a fresh sign-in.

**Where** `AuthRepository.restoreFromStoredToken()` (`lib/data/repositories/auth_repository.dart:783`).

**Under the hood**
- Reads the stored token (`SecureStorageService.readToken`) — a keystore failure here is treated as "nothing to restore", not a verdict, landing cleanly on the sign-in screen rather than throwing out of an unawaited call.
- If a token exists, calls `GET /auth/me`. On success, caches the raw payload (`storage.writeMe`) and applies it (`_applyMe`) — this is also where a re-armed admin re-establishes the two-sided eligibility kill switch + heartbeat.
- On a `401`/`403` from the host, the session is treated as genuinely invalid and cleared (`storage.clearSession()`).
- On any other failure (host unreachable, timeout, 5xx), falls back to `_restoreFromCachedMe()` (`:847`) — replays the last cached `/auth/me` blob. **No cache** means staying signed out (a first-ever sign-in genuinely needs the host). A cache that fails to parse (older wire shape) is dropped rather than wedging every boot on it.
- `_applyMe` deliberately does **not** resurrect a retired shift: `_shiftStartedAt` reads `me.shiftTracked` to distinguish "the host answered with no open shift" from "a legacy host that cannot answer at all", so an overnight token restore never fills a gap the host already closed.

**Offline behaviour** This *is* the offline path — the entire reason it exists is a terputus handset restarting mid-shift. See ADR-0090's broader offline-intent design for the philosophy this session-restore mechanism supports.

**ADRs** ADR-0099 (contrasts this restore path against admin sign-in's hard WAN requirement).

---

## The WebSocket hub & repository resync-on-reconnect

**What** Server-side fan-out of every domain event to connected clients, and a client-side rule that every list repository does a full re-`GET` on every (re)connect — not just applies incremental deltas — so a missed event or a lossy bootstrap self-heals.

**Where** `lib/server/ws_hub.dart` (`WsHub`), `lib/data/services/ws_client.dart` (`WsClient`).

**Under the hood**
- **Server**: `WsHub.register(channel, userId, deviceId)` (`lib/server/ws_hub.dart:22`) tracks connections in a list; `broadcast(type, payload)` wraps them in a `WsEventDto {v: 1, type, payload, ts}` and pushes the JSON frame to every live connection, silently swallowing per-connection send failures. `GET /ws` is upgraded via `webSocketHandler`; auth is enforced in `_authMiddleware` (`lib/server/server.dart:531`) via a `?token=` query param (the one place a bearer rides the URL rather than a header) resolved through the same `ServerAuth.resolveBearer`.
- **Client**: `WsClient` (`lib/data/services/ws_client.dart:25`) connects with exponential backoff — base `200ms * 2^attempt` capped at 10s, with **subtractive** jitter (0.5×–1.0× of the base, so a retry can only come sooner, never later) to avoid a thundering-herd reconnect storm across every handset in a venue when the host itself reboots. A 5s WS ping (`_keepAlive`) exists because a dead Wi-Fi doesn't close a TCP socket — the interface just vanishes with no FIN/RST, so without an active keepalive a handset that walked out of range would keep reporting `open` indefinitely, which is exactly the signal `submitOrder` and the offline queue read to decide whether to queue.
- After `relocateAfter` (5) consecutive failed connects, `WsClient.shouldRelocate()` triggers `onProbablyMoved` (wired to `relocateServer(ref)` in `server_relocator.dart`) — the fingerprint-pinned mDNS re-discovery described above.
- On every successful handshake (`channel.ready` resolves), `WsClient` pushes a **client-internal synthetic event** `WsEventTypes.connected` (`= 'local.connected'`, never sent by the server) onto its own `events` stream. Every list-owning repository (`tables`, `zones`, `menu`, etc.) listens for this and does a full re-`GET`/replace of its state — this is the resync-on-reconnect pattern (ADR-0021). It exists because incremental-only WS handlers can only *accrete*: a bootstrap `GET` that raced a 401 (before the admin token was written) or an empty seed produced a stuck-empty list with no recovery path short of a full app restart.
- `wsConnStateProvider` deliberately returns `closed` before pairing **and** before login — without a valid bearer the server 403s every upgrade, and without this guard the exponential-backoff cycle would flicker the top-bar indicator between `open`/`closed`.
- `sendQueueDrainProvider` (`lib/data/services/send_queue_drain.dart:23`) also hangs off the same `connected` event to trigger a send-queue replay — see below.

**Offline behaviour** This *is* the offline-recovery machinery — see ADR-0021 and ADR-0090.

**ADRs** ADR-0021 (repository resync on reconnect), ADR-0080 amendment (fingerprint relocation), ADR-0090 (offline order is an intent).

**Gotchas** `wsClientProvider` throws (`StateError('ApiConfig not initialised.')`) if read with no `apiConfigProvider` — `sendQueueDrainProvider` explicitly `ref.watch`es `apiConfigProvider` first and bails early to avoid this surfacing as a red frame in `AppShell.build` during logout.

---

## Antrean kirim — the offline send queue

**What** A device-local FIFO of order/seat/void intents captured while a handset can't reach the host, replayed through the *ordinary* HTTP routes (never a bulk endpoint) the moment the socket reconnects (ADR-0090).

**Who** A waiter whose handset loses the LAN mid-shift.

**Where** `lib/data/services/send_queue_service.dart` (`SendQueue`, `SendIntent`), `lib/data/services/send_queue_drain.dart` (`sendQueueDrainProvider`).

**How to use**
1. Nothing explicit — `submitOrder` and `seat` fall back to `sendQueueProvider.enqueue(...)` automatically when `wsConnStateProvider != open` (or a request times out).
2. The waiter keeps ordering normally; queued lines render from the queue itself (`pendingOrdersForTableProvider`), never faked into the ticket map.
3. On reconnect, the queue drains automatically; a **clean** drain stays silent. A drain with a refusal, a stock rejection, or an interruption pops a blocking result dialog (`showSendResultDialog`, wired in `AppShell`).
4. `/me` shows a **Tertunda** card (`_MyPendingCard`) listing every intent this device still holds, device-wide (not per-user — a handset handover, ADR-0065, must not hide a backlog from whoever is now holding it).
5. Signing out with a non-empty queue is blocked by a confirm dialog offering **Buang** (discard all) — a shift cannot close over undelivered orders silently.

**Under the hood**
- `SendIntentKind` has exactly three arms: `seatTable`, `submitOrder`, `voidTicket` (`lib/data/services/send_queue_service.dart:22`). Editing/voiding a line that hasn't been delivered yet never becomes its own intent — it **rewrites the queued `submitOrder` in place** via `SendQueue.rewriteLines()`, dropping the intent entirely if the rewrite empties it (`discard`).
- `SendIntent.id` doubles as the **idempotency key** — stable across retries, so a POST that timed out but actually landed on the host is replayed harmlessly (the host reads back the stored response instead of double-ordering).
- Persistence: JSON array under a `prefs` key (`PrefsService.sendQueueJson`), capped at `SendQueue.maxIntents = 200` (throws `SendQueueFull`, which callers must surface, never swallow). A backlog that fails to parse (corrupt JSON) is **quarantined** verbatim under its own key rather than deleted (`setSendQueueQuarantineJson`) and the error bus is told (`sendQueueCorrupt`), so a corrupt queue is recoverable off the device by support rather than silently lost.
- `SendQueue.drain()` (`:367`) replays **strictly sequentially, oldest first** — parallel drain would file two orders on one table out of the guest's own order. A **business refusal** (4xx other than 401/403) is recorded as `SendOutcomeKind.refused` and the drain **continues**; a transport failure, a `500+`, or a `401`/`403` (except a `voidTicket`'s 403, which is a business refusal about one capability, not a broken bearer) **stops** the drain, leaving the rest queued. An order captured against a seat the host itself refused (`seatRefused` tracking) is refused locally with `visit_changed` rather than sent blind against whoever now holds that table.
- Expiry: any intent captured before the current business-day start (`businessDayStart`, using the venue's `businessDayStartHour`, default 4) is reported `SendOutcomeKind.expired` and discarded without ever being sent — a day that has closed its books cannot absorb it.
- `apiIntentSender(ApiClient)` (`:472`) is the arm-by-arm replay mapping:
  - `submitOrder` → `POST /orders` with `idempotencyKey: intent.id` and `expectedVisitId` (only when the handset actually knew one at capture time — never a local key crossing the wire).
  - `voidTicket` → `POST /tickets/<id>/transition {status: 'voided', voidReasonCode, voidReason, actorId}` — **no idempotency key**; `voided` is terminal with no outgoing transition, so a replay of one the host already processed comes back `409 illegal_transition`, which *is* the idempotency.
  - `seatTable` → `POST /tables/<id>/seat` with `idempotencyKey: intent.id`.
- `sendQueueDrainProvider` (`send_queue_drain.dart:23`) is watched only by `AppShell` (a provider nobody holds never subscribes) and fires `_drainOrders` then `_drainSettlement` on every `WsEventTypes.connected` — **orders before money, always**, because a payment replayed ahead of the order it pays for would land against a bill that doesn't yet hold the lines. After an order drain, both `ticketsProvider` and `tablesProvider` are force-resynced (`resyncNow()`) rather than patched — a single drain can touch several visits, and the authoritative list is one GET away.

**Offline behaviour** This entire feature *is* the offline behaviour for orders/seating/voids. It does not cover settlement/payment offline capture — that's the separate **Antrean setelmen** (ADR-0123), which lives in `lib/data/services/settlement_journal.dart` / `settlement_sync.dart` and is documented elsewhere.

**ADRs** ADR-0090 (an offline order is an intent, not a row), ADR-0114 (a void's reason is a code, and void is the one intent whose 403 must not stall the drain), ADR-0116 (a lease you cannot renew still lets you queue — referenced by ADR-0123 for the settlement side).

**Gotchas** `sendQueueProvider` is constructed from `ref.read(prefsServiceProvider.future)` (the *future*, not the value) specifically so the notifier is never rebuilt — and disposed — the moment prefs resolve a few frames into boot, which would otherwise drop any order captured in that window.

---

## Guest self-order — the [[Pesan mandiri]] plane

**What** A second, fully separate HTTP+SPA surface a stranger's phone talks to directly: cleartext, no bearer, no credential beyond a code printed on a table card. A guest order is always an **intent** the staff must accept before it becomes a real ticket (ADR-0105) — never a second path that writes tickets directly (that model, `TicketStatus.pendingReview`, was tried and removed in ADR-0080).

**Who** A dining guest (ordering plane) and a waiter/owner deciding the queue (staff plane, inside the ordinary app).

**Where**
- Guest plane: `lib/server/guest/guest_plane.dart` (`GuestPlane`, the second listener), `lib/server/guest/guest_routes.dart` (the router with no `ServerAuth`), `lib/server/guest/guest_code.dart` (code minting), `lib/server/self_order.dart` (the single writer for `guest_sessions`/`guest_orders`/`guest_order_lines`), `assets/guest_web/index.html` (the hand-rolled SPA).
- Staff plane: `lib/server/routes/self_order_routes.dart`, `/selforder` (queue, `SelfOrderScreen`), `/selforder-admin` (config, `SelfOrderAdminScreen`).

**How to use — guest side**
1. Guest scans a table's QR (or the venue's own **[[Kode kedai]]** counter QR for a [[Kedai]] with no floor plan, ADR-0109) pointing at `http://<lan-ip>:8080/t/<code>`.
2. The SPA (`assets/guest_web/index.html`) opens a session (`POST /guest/session`), browses the menu (`GET /guest/menu`), adds items, and submits (`POST /guest/orders`).
3. The guest polls **"Pesanan saya"** (`GET /guest/orders`, session-scoped) rather than any WebSocket — a handful of phones polling a LAN server is cheaper to keep correct than a second fan-out plane.
4. A guest can withdraw their own order while it's still `pending` (`DELETE /guest/orders/<id>`) — once accepted it's a ticket, and only staff void a ticket.
5. If the venue's [[Stempel]] program is running, the guest can check progress by phone number (`POST /guest/punch`) — the *only* member fact ever exposed on this plane (ADR-0110).

**How to use — staff side**
1. `/selforder` (rail id `tamu`, badged with the pending count) shows the queue: pending, then accepted/rejected. **Terima** (accept) or **Tolak** (reject with a reason code) each order, or **Terima semua** to accept everything waiting (partial success is normal — reports per-order, never refuses the whole batch).
2. `/selforder-admin` (`editSettings` only) has three tabs: **QR & meja** (per-table opt-in + the counter code), **Menu tamu** (which items/categories a guest sees, alcohol badge, sold-out override), **Aturan** (service hours, note toggle, max items, session TTL, and the master on/off switch).
3. **Rotate codes** on the QR tab (`rotateGuestCodes`) reprints every table's code — and the counter's — killing every laminated card in the venue at once; it is audited (`AuditKind.guestCodesRotated`).

**Under the hood**
- **The plane itself binds only while `venue_settings.guest_ordering_enabled` is on** — off means the socket doesn't exist at all, not that it exists and answers 403 (`GuestPlane`, `lib/server/guest/guest_plane.dart:28`). Toggling the flag requires the ordinary server **restart**, because the shelf router is built once at boot (`ServerRuntime._syncGuestPlane`, called from both `boot()` and `restart()`).
- **Separate cleartext socket, different port**: `guestPlanePort = 8080` (vs. the staff API's `7443`), plain `shelf_io.serve` with **no `securityContext`** — a phone that has never met this venue can't be taught to trust a self-signed cert, and an interstitial browser warning in front of a menu is a feature nobody uses.
- **A router that has never heard of `ServerAuth`**: `guestRoutes(db, hub)` (`lib/server/guest/guest_routes.dart:71`) takes no auth helper at all — this is the deliberate way ADR-0102's "every route factory takes a non-null `ServerAuth`" rule (a rule about the *staff* API) is honoured without applying it here: the credential is the code in the URL plus an opaque session id.
- **`staffView` must never cross the guest plane**: `guestOrderJson(db, o, {staffView})` (`lib/server/self_order.dart:740`) adds `tableLabel` and `decidedBy` only when `staffView: true` — every guest-plane call omits it; only `selfOrderRoutes` (the staff plane) ever passes it.
- **The server prices the order, never the phone**: `submitGuestOrder()` (`lib/server/self_order.dart:421`) recomputes `unitPrice` from `menu_items`/variant/modifier data server-side; whatever a phone sends about money is discarded. The reserved `openItemId` (an [[Item bebas]]) can never reach a guest order.
- **A guest decision is once**: `_claim()` (`:718`) reads-then-writes `status: pending → {to}` inside `db.transaction()`, so two waiters tapping Terima on two tablets fire one order, not two. `acceptGuestOrder()` (`:549`) wraps the claim **and** the call into the ordinary `submitOrder()` in one transaction (ADR-0100's rule applied to a state machine) — if `submitOrder` throws or rejects every line for stock, the whole transaction rolls back and the intent lands back on the queue rather than stranding at `accepted` with no ticket behind it.
- **Guest codes**: `mintGuestCode()` (`lib/server/guest/guest_code.dart`) draws 8 chars from a 30-symbol Crockford-ish alphabet (no `I L O U 0 1`, so a card can't be mistyped into a different table's) — ≈39 bits. `mintMissingGuestCodes` fills blanks only (safe to run repeatedly, used by seed/table-create); `rotateGuestCodes` is the deliberate, audited act that kills every printed QR. **Codes are minted, never silently regenerated** by anything that runs twice.
- **The [[Kedai]] counter code** (`counterGuestCode`, ADR-0109): a venue-level code (not per-table) for a shop with no floor plan — carried as an **empty `tableId`** throughout, the same convention `Bawa pulang` visits already use for "no table". Each counter order becomes its own takeaway bill (`acceptGuestOrder` passes `takeaway: claimed.tableId.isEmpty`), because a shared table code would merge two strangers' orders onto one bill.
- **Rate limiting is in-memory, per-socket-lifetime** (`GuestWindow`, `guest_routes.dart:24`): a fixed-window counter (not sliding — the boundary-doubling cost is negligible at this scale). Guest order submission is capped by caller IP (40/hr); the stempel lookup has *two* buckets — 5/hr per phone number asked about (protects the number, however many sessions ask) and 40/hr per caller IP (catches a sweep across many numbers), plus a per-session try cap of 5. A rate limit "nobody ever reads back" is deliberately not a DB column — a restart forgives everyone, which is the right trade for a server that's a tablet someone unplugs at closing.
- **The guest note cap** is 120 chars (`_noteMax`).
- **The guest page's own error-code map**, hand-authored in `assets/guest_web/index.html:199-213` — e.g. `self_order_off: 'Pesan mandiri sedang dimatikan.'`, `session_expired: 'Sesi habis. Pindai ulang QR di meja.'`, `too_many: 'Terlalu sering. Coba lagi nanti.'` — is **outside the ARB/`flutter gen-l10n` pipeline entirely**; it's the only user-facing surface in the app that generator never sees. A new server error code the page can receive needs a manual entry here or it renders the bare code.
- **Alcohol badge** (`menu_items.alcohol`): a prompt to whoever holds the accept button, not an access control — it never hides the item or blocks the order. Written **only** by `PATCH /selforder/items/<id>` from the Menu tamu tab; deliberately not backfilled by category on schema upgrade (guessing which categories mean alcohol is how a soft drink acquires an age check).
- **`guest_stock_override` arrives pre-expired**: `guestMenuJson` emits the *effective* value — an override whose `guest_override_at` predates the current business day (per `businessDayStartHour`) renders `auto` regardless of what's stored. The [[Jam tayang]] category window (`guestFromMin`/`guestToMin`) similarly renders items outside their window as sold-out (not hidden), so a guest reads *why* rather than seeing the item vanish.
- **Staff-side endpoints** (`lib/server/routes/self_order_routes.dart`): `GET /selforder` (queue + stats + tables + menu in one call — a busy tablet shouldn't pay three round trips for one tab switch), `POST /selforder/orders/<id>/accept|reject`, `POST /selforder/orders/accept-all`, `PATCH /selforder/items/<id>` (guest visibility/featured/alcohol/stock override — `editSettings`, not `editMenu`, because curating what a stranger's phone may see is a different authority from curating the menu itself), `PATCH /selforder/categories/<id>` (Jam tayang window), `POST /selforder/codes/rotate`, `PATCH /selforder/tables/<id>` (per-table opt-in). Deciding an order needs `takeOrder`; rotating codes and every config write needs `editSettings`.
- **Statistics** (`guestOrderStats`, `lib/server/self_order.dart:814`): derived on read for the current business day — total/pending/accepted/rejected counts, accepted value, median wait in seconds. Nothing stores a running total.

**Offline behaviour** The guest plane has no offline story of its own — a guest with no LAN signal simply can't reach it. On the staff side, deciding a guest order is an ordinary authenticated write and is **not** one of the `SendIntentKind` arms — there is no offline capture for accept/reject.

**ADRs** ADR-0105 (guest self-order returns as an intent, not a ticket — supersedes the removed pendingReview design), ADR-0106 (the guest queue is a destination, its settings are not — `/selforder` is top-level nav, `/selforder-admin` is a hub tile), ADR-0109 (counter mode's [[Kode kedai]]; `counterQr` gating the socket route's *existence*, needing a restart), ADR-0110 (stempel is the only member fact crossing the guest plane), ADR-0080 §1 (superseded — removed the original QR-ordering design this was rebuilt from), ADR-0102 (why the guest router deliberately has no `ServerAuth`), ADR-0027/0028/0029 (superseded historical guest-plane ADRs, cited for lineage only).

**Gotchas** `guestRules().enabled` is an AND of the venue's own preference (`guest_ordering_enabled`) **and** module entitlement (`venueHasModule(s, moduleSelfOrder)`) — off on either side means the plane doesn't exist, matching the module-entitlement pattern used elsewhere (see CLAUDE.md §ADR-0107). `withinServiceHours` handles a window that wraps midnight (`22:00–02:00` is legal) — it is not a plain `>=`/`<` comparison. `liveGuestSession` has a deliberately narrow exception to its "stale if the table reopened after the session started" rule: a guest who scans at an *empty* table opens the sitting themselves the moment staff accept, so the session checks whether its own accepted order attached to the current visit rather than only the clock.

---

## The app shell (phone vs. tablet)

**What** One shared chrome — `AppShell` — that renders either `TabletShell` (side rail) or a phone `Scaffold` with a floating tab bar, decided purely by hardware form factor with no runtime override.

**Where** `lib/ui/features/shell/app_shell.dart`, `lib/ui/core/design/shell_inset.dart`, `lib/ui/core/widgets/tablet_chrome.dart`.

**Under the hood**
- The split is `context.layout.useTabletShell` — **hardware decides**; ADR-0049 removed the old `forcePhoneViewProvider` runtime toggle, and `MainActivity.onCreate` pins Android orientation from `smallestScreenWidthDp >= 600` (tablet landscape, phone portrait) at the Kotlin layer — unreachable from Dart.
- `AppShell.build()` is also **the app's one subscriber** to two cross-cutting streams: it watches `sendQueueDrainProvider` (so a drain trigger nobody else holds actually subscribes — the shell outlives every tab, which is the lifetime a backlog needs) and listens to `appErrorProvider` (the error bus, ADR-0103 — repositories push from anywhere; only the shell renders it, because it's the only widget guaranteed to outlive whichever screen raised the error) and `sendReportProvider` (pops `showSendResultDialog` on a non-clean drain).
- **Rail/tab membership** is a `const` lookup table, `_railRoutes` (`app_shell.dart:52`): `/counter`, `/tables`, `/orders`, `/kitchen`, `/kasir`, `/selforder`→`tamu`, `/me`. Anything **not** listed defaults to the Venue hub (ADR-0058) — a new *top-level* destination must be added here explicitly or it silently reads as "Venue".
- Three route-matched first-segment lookups drive the crumb trail and destination visibility without duplicating logic: `railLabel()`, `venueHubCrumb()` (hub-child tail segments), `crumbsFor()`.
- Conditional rail/tab slots, each gated by a named predicate function (kept pure so tests and `redirect` can call them with no `BuildContext`):
  - `showGuestQueue({guestOrderingEnabled, canTakeOrder})` — the Tamu slot (ADR-0106).
  - `showCounterHome({menuHomeEnabled, canTakeOrder})` — swaps the home slot from Meja to Menu for a [[Kedai]] with `counterMenuHome` on (ADR-0109) — **hides, never refuses**: `/tables` stays a legal route reachable by deep link.
  - `showKdsSlot({bypassKds, queueLive, kdsOnlyUser})` — removes the KDS rail slot under [[Tanpa antrian persiapan]] (ADR-0115) with two deliberate survivals: a line still cooking (`queueLive`) or a `viewKds`-only user (hiding it from them would be indistinguishable from locking the device).
- **`ShellInset`** (`lib/ui/core/design/shell_inset.dart`) is an `InheritedWidget` publishing how much bottom clearance the shell's own floating chrome eats — **0** on the tablet shell (side rail, no bottom bar) and on every root-navigator push; `_tabBarGap + _tabBarHeight` (12 + 64) on the phone shell, which floats its tab bar *over* the page in a `Stack` rather than a `bottomNavigationBar`. This replaced a `MediaQuery`-derived `SatLayout.bottomInset` because two screens (`MenuScreen`, `ReviewScreen`) mount **both** inside the shell (`/counter`) and pushed outside it (`/table/:id/menu`) at the same width — no size-derived signal can tell those two mounts apart, but the widget that actually draws the bar can.

**ADRs** ADR-0049 (hardware decides presentation, screen stays awake), ADR-0058 (the app bar carries the crumb trail), ADR-0103 (a transport error surfaces through the shell), ADR-0106, ADR-0109, ADR-0115 (referenced), ADR-0117 (the shell publishes its own bottom chrome).

**Gotchas** `test/shell_inset_test.dart` holds an explicit list of files mounted inside `ShellRoute` and fails any listed file whose vertical scroll view doesn't account for `shellInset` — a new shell route must be added to that list, or opt out with a `// no-shell-inset:` comment when its only scroll views live in sheets.

---

## Theming, skins, and localisation

**What** Six device-local, non-localised theme names spanning three "skins" (shape languages), plus a hard ID-default two-locale (ID/EN) localisation system that never follows the OS locale.

**Where** `lib/ui/core/design/sat_theme.dart` (`SatTheme` enum), `lib/ui/core/design/skin.dart` (`SatShape`, `SatSkin`), `lib/ui/core/state/theme_view_model.dart`, `lib/core/localization/locale_view_model.dart`, `lib/ui/features/me/widgets/theme_sheet.dart` / `locale_sheet.dart`.

**How to use**
1. On `/me`, tap the theme button (`a11yPickTheme`) or the language button (`a11yPickLocale`, showing the two-letter tag `ID`/`EN`) to open a bottom sheet.
2. Pick one of six themes: **Amber Gelap**, **Amber Terang**, **Neon Gelap**, **Neon Terang** (the shipped default, ADR-0057), **Neo Kertas**, **Neo Tengah Malam**.
3. Pick **Indonesia** or **English** — the choice is per-device and persists.

**Under the hood**
- `SatTheme` (`lib/ui/core/design/sat_theme.dart:22`) bundles brightness + palette (`SatColors`) + shape (`SatSkin`) as one atomic choice — there's no separate light/dark toggle and no OS-follow. `lembut` (soft — rounded corners, hairline rules, no shadows) is the original look; `brutal` (neo-brutalist — square corners, fat solid-ink rules, hard offset shadows) backs the two Neo themes; `glow` (generous radii, no rules, soft ambient lift, obsidian-vs-bone slabs) backs the two Neon themes (ADR-0050). `SatTheme.adopt()` publishes shape tokens to the static `SatShape` class every build (`SatSetApp.build`), because ~800 call sites reach `SatR`/`SatB`/`SatBox` from static contexts with no `BuildContext` in scope.
- `SatTheme.fallback = SatTheme.neonTerang` (ADR-0057 moved this from the original `amberGelap` — a deliberate non-visual-no-op upgrade). `fromKey()` falls back rather than throwing on an unknown/absent stored key (a preference read must never block app start); a renamed theme (`neonHijau`→`neonGelap`, ADR-0050) has no alias, so a device that had picked the old name lands on the fallback once.
- Theme names are **literals, never ARB entries** (ADR-0083, ADR-0045) — a waiter reaches for "the dark one" by product name, and a name that changed with the language setting would break exactly the muscle memory the app depends on.
- `SatThemeNotifier` / `SatLocaleNotifier` share one pattern: seed synchronously from `PrefsService` if already resolved, render the fallback for the handful of frames before it is, then write-through on every change — never watch prefs again after seeding (a rebuild here would dispose and lose in-flight state, the same reasoning as `SendQueue`).
- `satDefaultLocale = Locale('id')` is **hard-coded**, never resolved from the platform (ADR-0083) — the tablets a small Indonesian venue actually buys ship with system locale `en_US` untouched, and following it would boot a warung's till into English on first run.
- `satL10n` (module-level, `locale_view_model.dart:43`) is the escape hatch for code with **neither** a `BuildContext` nor a `Ref` — the ESC/POS printer renderers and CSV/PDF exporters run inside the embedded server (constructed from a Drift DB + `WsHub`, never Riverpod) and read "the language of this device holding the printer" through this global, kept in sync by `SatLocaleNotifier._sync()` alongside `Intl.defaultLocale`.
- **Money never localises** (ADR-0084): `formatIDR`/`groupRupiah` and the rupiah input mask always use `id_ID` in both languages — `format.dart` is deliberately half-pinned (dates *do* follow the locale).
- **A code crosses a layer, never a sentence** (ADR-0085): enums carry keys, the server sends `kind`/`key`/`code` + params, and resolvers in `lib/core/localization/` (`labels.dart`, `report_copy.dart`, `audit_text.dart`, `admission_text.dart`) compose the words at read time — every resolver falls through to the raw code so an older row or a newer server never renders blank.
- Hardcoded user-facing text is banned at zero-tolerance by `design_tokens_test.dart`: copy in a bare `Text()`, copy in a named param (`label:`, `title:`, `hint:`), and any Indonesian word in a Dart literal under `lib/ui`/`lib/domain`. `arb_parity_test.dart` fails on a key/placeholder/plural present in one locale ARB and not the other.

**ADRs** ADR-0045 (device-local theme selection), ADR-0047 (skins carry shape alongside palette), ADR-0050 (the Glow skin), ADR-0057 (Neon Terang is the shipped default), ADR-0083 (language is a device choice, never follows the system), ADR-0084 (money never localises), ADR-0085 (an audit event is structured, not a sentence).

**Gotchas** The guest self-order SPA (`assets/guest_web/index.html`) is the **one** exception to the whole ARB pipeline — it's Indonesian-only, hand-rolled, with its own error-code map (see the Guest self-order section above); `flutter gen-l10n` never sees it.

---

## `/me` — the shift snapshot and sign-out

**What** A **live snapshot** of what the signed-in user is holding right now (outstanding lines, seated covers, open tables, this shift's voids) — not a cumulative shift total. It is also the one exit from a session: signing out **always** ends the shift (ADR-0097 — there is no shift-preserving handset handover anymore).

**Where** `lib/ui/features/me/me_screen.dart`.

**How to use**
1. `/me` shows identity (avatar, name, role · zone), a shift-progress ring (elapsed / 8h target), an end-shift button (**Keluar**, `meSignOut`), a **Tertunda** card if the device holds any queued send intents, a 4-box KPI grid (open tickets, covers, voids this shift, active tables), a pacing line (outstanding lines broken down by kitchen status), and a recent-activity feed (own audit rows only, unless the user holds `manageStaff`).
2. Tapping **Keluar** first checks the send queue — a non-empty queue blocks the exit behind a confirm offering **Buang** (discard everything, logged locally since the audit writer lives on the host which is exactly what's unreachable).
3. For a Server-mode admin, ending the session is phrased as **Akhiri sesi admin?** (`meEndAdminTitle`) with a stronger confirm (**Keluar & matikan**, `meEndAndShutdown`) — because it takes the venue's whole server down with it, unlike a staff sign-out.
4. Theme and locale pickers live in the top bar (phone) or the tablet header row.

**Under the hood**
- Metrics are computed client-side from already-fetched state (`_computeMetrics`, `me_screen.dart:100`): "my tables" are scoped by `lastActorId == meId` (server-authoritative, ADR-0056) — not an optimistic `VenueTable.mine` flag, which used to silently empty this screen on every WS update. Lines are resolved by the table's *current* `visitId` (ADR-0034), not the table's own reused id.
- The counts are deliberately **not** a cumulative shift total — closing a table correctly makes them go *down*. Getting cumulative totals (sales, tickets/hour) would need closed `TableSessions`, which clients never receive (ADR-0065).
- The activity feed arrives pre-scoped to this user+shift server-side; a client-side `manageStaff` filter additionally hides admin-only audit rows (`isAdminAuditType`) even from the user they're filed against, unless that user can manage staff.
- `_EndShiftButton`'s `endShift()` closure (`:283`) is the one exit: check the send queue → (if Server-mode admin) confirm the shutdown → `ref.read(authStateProvider.notifier).signOut()`. No explicit `context.go` follows — `signOut()` clears auth state (and, for an admin, `apiConfigProvider`), each of which bumps the router's refresh listener, and the redirect ladder sends `/me` → `/pin` on its own (ADR-0078 — an explicit `go` here used to race the two async redirects).

**Offline behaviour** Fully local — every number on this screen is derived from state the device already holds.

**ADRs** ADR-0097 (referenced — one exit, sign-out ends the shift), ADR-0056 (referenced — table ownership is server-authoritative, never backfilled), ADR-0034 (lines keyed by visit, not table id), ADR-0065 (referenced — why cumulative totals aren't fetched), ADR-0078 (loop-safe redirect ladder — why no explicit navigation follows sign-out), ADR-0081 (referenced — the seconds ticker is isolated to `_ShiftLine` so the whole screen doesn't rebuild once a second).

---

## Debug widget book

**What** A searchable gallery of every shared widget in `lib/ui/core/widgets/`, rendered in each of its documented states, reachable only in debug builds.

**Where** `/book`, `lib/ui/features/_book/book_screen.dart`, `book_entries.dart`, `book_stubs.dart`.

**How to use**
1. Reachable via a debug button on `PinScreen` (pre-pairing) or a **Book** item at the foot of `TabletSideRail` (pushed, not `go`ne — back returns to the current tab).
2. Search filters entries by name; tapping one opens `_BookStage` to see every rendered state.

**Under the hood**
- `/book` exists only `if (kDebugMode)` in the router (`app_router.dart:297`) and rides in the redirect ladder's `onboardingRoutes` bypass set — it renders on a device that has **never been paired**, which is most of the time it's actually wanted.
- It deliberately obeys `design_tokens_test.dart` like any real screen — a gallery documenting the token system while ignoring the token rules would be lying about what it documents.
- Fake auth/data for the gallery comes from stub classes (`_BookAuth extends AuthRepository`, `FakeMdnsBrowserService extends MdnsBrowserService`) in `book_entries.dart`/`book_stubs.dart`.

**ADRs** ADR-0054 (debug-only widget book) — add an entry there in the same commit as any new shared `core/widgets/` component.

---

## Redirect guard ladder (`lib/router/app_router.dart`)

The `redirect` callback (`app_router.dart:195`) runs in this exact order on every navigation:

1. **Super admin bypass** (`auth.isSuperAdmin`): forced to `/fleet` unconditionally, bypassing every gate below including the pair gate (ADR-0016).
2. **Report owner bypass** (`auth.isOwner`): forced to `/owner` unconditionally, same bypass shape (ADR-0036).
3. **Cross-bypass guard**: a non-super on `/fleet`, or a non-owner on `/owner`, is bounced to `/pin`.
4. **Hard pair gate**: `apiConfigProvider == null` and the location isn't in `onboardingRoutes` (`{'/pin', '/onboarding', '/forbidden', if (kDebugMode) '/book'}`) → `/pin`. No data screen may render against an empty repository cache.
5. **Auth gate**: not `loggedIn` and not an onboarding route → `/pin`.
6. **Landing decision**: `loggedIn && paired && loc == '/pin'` → routes by `prefs.appMode()`: `server` → `/venue`; otherwise `/counter` if `counterHome(ref, auth)` (a [[Kedai]] with `menuHome` on and `takeOrder`), else `/tables`. (`paired` is checked explicitly here, not just implied by gate 4, because admin sign-out clears `apiConfigProvider` and auth state in two separate steps — ADR-0078.)
7. **Capability gate** (only when `loggedIn`): if on `/tables` but `counterHome` is true, redirect to `/counter` (a counter shop has no floor tab to land on stale deep links against). Then `_capabilityFor(loc)` (`app_router.dart:57`) returns the list of capabilities that open this location — **any one** held by the user is enough — and a location whose required list none of the user's capabilities intersects redirects to `/forbidden` (fail-closed: an unmatched location with no listed capability is open to any authenticated user).
8. Any location that still falls through unmatched logs and lands on `_RouteFallback`, which bounces to `/pin` on the next frame (ADR-0078 — safe for every session kind, since bypasses 1–2 already redirected a super/owner elsewhere).

`_capabilityFor` highlights (not exhaustive — see the file for the full list): `/kitchen`→`viewKds`; `/kasir`→`settleBill`; `/table/`, `/orders`, `/order/`, `/counter`, `/takeaway`→`takeOrder`; `/venue-day`→`openDrawer` **or** `closeShift` (matched before `/venue`, of which it's a prefix); `/kas`→`manageCash` **or** `editSettings`; `/selforder-admin`→`editSettings` (matched before `/selforder`, of which it's a prefix); `/selforder`→`takeOrder` **or** `editSettings`; `/member-report`→`viewReports` **or** `manageMembers`; `/members`→`manageMembers`; `/opname`→`viewReports` **or** `manageIngredients`; `/menuadm`→`editMenu`; `/staff`, `/system`, `/venue`→`manageStaff`.

**ADRs** ADR-0078 (loop-safe redirect ladder), ADR-0016, ADR-0036, ADR-0109 (counter home).

---

## Domain vocabulary quick reference

- **[[Antrean kirim]]** — the offline send queue (`SendQueue`), device-local, orders/seats/voids only.
- **[[Antrean setelmen]]** — the offline settlement journal (ADR-0123), a separate feature outside this doc's scope.
- **[[Pesan mandiri]]** — guest self-order as a whole (ADR-0105).
- **[[Kode kedai]]** — the venue-level counter QR code for a [[Kedai]] with no floor plan (ADR-0109).
- **[[Tamu]]** — the guest-order review queue (`/selforder`, ADR-0106).
- **[[Menu tamu]]** — the guest-visible menu configuration tab on `/selforder-admin`.
- **[[Jam tayang]]** — a menu category's guest-visible time window (`guestFromMin`/`guestToMin`).
- **[[Item bebas]]** — the reserved open/freeform item id, explicitly refused on the guest plane.
- **[[Stempel]]** — the member punch-card program; its progress lookup is the one member fact the guest plane exposes (ADR-0110).
- **[[Bawa pulang]]** — takeaway; a counter guest order becomes its own Bawa pulang bill.
