# ADR-0004 — Staff auth is a 4-digit PIN issuing a JWT carrying capability claims; the router fails closed on missing capabilities

**Status:** Accepted — 2026-05-28

## Context

Restaurant floor devices are shared. A tablet stays parked by the POS; whoever picks it up takes the next order. The auth model has to handle:

- **Shift changes mid-service.** A waiter signs in, takes orders for an hour, hands the tablet to the next shift. Sign-in must be <2s with one hand while holding a tray.
- **Role variation.** The same APK runs the manager view, the waiter view, the kitchen display, and the admin screens. Routes shown must match what the signed-in user is allowed to do.
- **Token revocation.** Firing a staff member or losing a device has to invalidate their session immediately, not "whenever the JWT expires."
- **No email/SMS infrastructure.** Most target venues don't run an email server, and SMS OTP costs money per shift change.
- **Admin escape hatch.** A single owner/manager account needs a stronger credential than a 4-digit PIN — they manage staff, edit menu, see reports.

## Decision

**1. Staff sign in with a 4-digit PIN; admin signs in with email + password.**

`ServerAuth.signInWithPin` (`lib/server/auth.dart`) hashes the PIN as `sha256("satset.v1::<pin>")` and looks up the user row by `pinHash` (excluding disabled users and the dedicated admin whose `pinHash` is empty). On match, issues an HS256 JWT and persists a `Session` row keyed by token.

`ServerAuth.signInWithEmailPassword` mirrors that for the admin path with a separate `satset.v1.pw::<password>` prefix. Admin is rejected from `/auth/login` even on a hypothetical PIN collision — admin must use `/auth/admin/login`. PIN collisions across staff are not prevented by the hash but are caught at staff-creation time in the admin UI (PIN uniqueness check).

JWT TTL: **12 hours.** Long enough for a full service without re-signing in; short enough that a forgotten tablet at end of day expires overnight.

JWT claims: `sub` (userId), `role` (roleId), `deviceId`, `iat`, `exp`. The role is carried for trace/debug; **authorization decisions do not read the JWT role** — they read the user's current capability set from the DB on every check, so a role change takes effect on the next request.

**2. Sessions are persisted server-side; the JWT is a key, not the authority.**

`ServerAuth.resolveBearer` verifies the JWT signature, then loads the matching `Session` row, then loads the `User`. Three layered gates:

- JWT signature invalid → reject (defense in depth; mainly catches mangled tokens).
- Session row missing (revoked) → reject.
- Session expired → reject.

Revocation is therefore a single DB row delete (`ServerAuth.revoke`). No need to wait for the JWT to expire; no need to maintain a denylist. The DB lookup adds latency but on SQLite-local-process it's sub-millisecond.

A 10-second ticker in `ServerRuntime._startStatusTicker` sweeps expired sessions and broadcasts `WsEventTypes.sessionExpired` per row so clients can flush device-online state without a refetch.

**3. Authorization is capability-based, not role-based, in the UI layer.**

Roles aggregate capabilities; the UI never asks "is this user a 'waiter'?" It asks "does this user have `Capability.takeOrder`?" Capabilities are an enum (`lib/domain/models/capability.dart`) grouped by domain:

- **orders**: `takeOrder`, `modifyOrder`, `voidItem`, `compItem`
- **kitchen**: `viewKds`
- **money**: `openDrawer`, `applyDiscount`, `refund`, `closeShift`
- **inventory**: `editMenu`, `toggle86`, `adjustStock`
- **admin**: `manageStaff`, `manageRoles`, `viewReports`, `editSettings`

A role is "a name + a Set<Capability>". The admin UI edits role↔capability mappings; staff get a role; the JWT-decoded user carries the *resolved* capability set via `AuthState`.

**4. The router fail-closes on missing capabilities.**

`_capabilityFor(loc)` in `lib/router/app_router.dart` is the single mapping from URL prefix to required `Capability`:

```dart
if (loc.startsWith('/kitchen')) return Capability.viewKds;
if (loc.startsWith('/table/') || loc.startsWith('/orders')) return Capability.takeOrder;
if (loc.startsWith('/venue-identity')) return Capability.editSettings;
if (loc.startsWith('/reports')) return Capability.viewReports;
if (loc.startsWith('/menuadm') || loc.startsWith('/staff') ||
    loc.startsWith('/system') || loc.startsWith('/floor') ||
    loc.startsWith('/venue')) return Capability.manageStaff;
return null;
```

`redirect` runs four ordered gates:

1. Hard pair gate: `apiConfigProvider == null` → `/pin` (no data screens render against an empty repo cache).
2. Not authenticated → `/pin`.
3. Authenticated on `/pin` → `/venue` (server mode) or `/tables` (client mode) per `prefs.appMode()`.
4. Authenticated elsewhere → `_capabilityFor(loc)`; missing capability → `/forbidden`.

`null` from `_capabilityFor` means "no capability required" — read carefully when adding routes. **Forgetting to add a mapping is a fail-open.** This is checked at code review time; there is no compile-time linkage between routes and capability mappings yet.

The router does **not** rebuild on auth/prefs change; a `_RouterRefresh` `ChangeNotifier` triggers `redirect` re-eval, preserving `Navigator` state through sign-in.

**5. Server-side route guards are the actual security boundary.**

The router redirect is UX — it stops a user from staring at a blank screen on a route they cannot use. The shelf `_authMiddleware` is the security check: every route except `/healthz`, `/auth/login`, `/auth/admin/login`, `/pair/claim`, `/pair/auto-claim` requires a valid bearer. `/ws` is special — auth via `?token=` query param. Capability checks per-route are enforced inside the route handlers when they need finer-grained gating than "any authenticated user."

## Consequences

**Positive:**
- PIN sign-in fits the physical context: one hand, two seconds, no keyboard.
- Capability-based UI removes the "I added a role but now I have to update five `if (role == 'manager')` checks" failure mode. Adding a new role = pick capabilities in admin UI; no code change.
- Session-row revocation gives immediate kick-out for fired staff or lost devices, without a JWT denylist.
- Two distinct hash prefixes (`satset.v1::` vs `satset.v1.pw::`) prevent cross-path token confusion if a PIN ever matches a password's leading digits.
- Server `_authMiddleware` is the security floor; the router redirect is purely UX. The two layers can drift without compromising safety.
- Persisting sessions keyed by token enables the periodic sweep + WS broadcast pattern, which keeps client-side "who is online" state correct without polling.

**Negative:**
- **10,000 possible PINs.** Brute force over the LAN is not implausible. There is currently **no rate limit on `/auth/login`**. This is a known gap; mitigation will be per-device exponential backoff. Until then: trust the LAN perimeter and the pair-gate.
- **Forgetting a mapping in `_capabilityFor` is silent fail-open.** A route added without a capability check renders to anyone authenticated. The route-to-capability table is a code-review smell, not a compile-time invariant. A future enhancement would attach the required capability to the `GoRoute` declaration directly.
- HS256 with a per-server-install secret (`ServerAuth.loadOrCreateSecret`) means the JWT is only meaningful to the server that issued it. Migrating sessions across servers (e.g. promoting a client to server) requires re-login.
- Capability resolution loads the user row on every API call. Adds DB hops; acceptable on local SQLite, would need caching on a heavier backend.
- The admin email/password path is the only place a non-PIN credential exists; if the admin loses it, recovery is "edit the SQLite file" (no email reset, by design).
- JWT carries `role` for trace but the field is advisory — confusing for anyone reading the token who assumes it's load-bearing. Documented here.

## Alternatives considered

- **Email + password for all staff.** Rejected: too slow at shift change, requires email infrastructure, and staff turnover is high enough that managing per-user passwords is a tax.
- **Magic-link / SMS OTP.** Rejected: requires connectivity and per-message cost. Violates the offline-during-service constraint.
- **Long-lived device tokens with no per-user login (kiosk model).** Rejected: needed to track who took an order for audit and report attribution. Per-user sign-in is non-negotiable.
- **Role-based authz directly in routes.** Rejected: doesn't compose. A "head waiter" wants `takeOrder + applyDiscount + closeShift` but not `editMenu`; capability sets express this without inventing one role per combination.
- **Stateless JWT (no session row, revocation via short TTL + refresh).** Rejected: refresh token dance is overkill on a LAN, and immediate revocation is more important than the DB hop savings.
- **Per-route `requiredCapability` attached to `GoRoute`.** Considered, deferred. Would make the route-to-capability table impossible to forget. `go_router`'s `GoRoute` does not expose a typed extension slot we want to use yet; revisit when we have more than ~10 capability-gated routes.
