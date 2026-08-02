# ADR-0078 — Every rung of the redirect ladder is loop-safe, and unmatched locations are caught

## Status

Accepted.

## Context

A Server-mode admin signing out from `/me` ("Akhiri shift & keluar") got
go_router's built-in **"Page Not Found"** screen for about two seconds before
landing on the admin sign-in form. Bare English error chrome, in a Bahasa
Indonesia app, on the one action that takes a whole venue offline.

The captured trace named it exactly:

```
[NAV] redirect /me → /pin
[NAV] redirect /pin → /venue
[NAV] redirect /venue → /pin
[NAV] route not found: /venue
      err=GoException: redirect loop detected /me => /pin => /pin => /venue => /venue => /pin
```

Not an unmatched location — `/venue` is a declared route. A **redirect loop**.

`_killAdminSession()` tears the admin session down in two provider writes with
an `await storage.clearSession()` between them:

1. `apiConfigProvider` → `null`
2. `authState` → `const AuthState()`

Each bumps the router's refresh listener, so the guard ladder runs against the
intermediate state — **logged in but unpaired** — which no rung was written
for:

- `/pin` matched `loggedIn && loc == '/pin'` and answered `/venue`.
- `/venue` matched the pair gate `!paired && !onboardingRoutes.contains(loc)`
  and answered `/pin`.

Neither rung is wrong on its own. Together they have no fixed point, and
go_router's redirect limit converts that into an error match list, which with
no `errorBuilder` configured is the default English error screen.

The state is not exotic. Any teardown or restore that touches pairing and
authentication in separate writes passes through it, and both do: sign-out,
the ADR-0015 eligibility kill switch, and boot-time session restore.

## Decision

**A rung that sends the user *away* from an onboarding route must require every
condition the gates above it enforce.**

Concretely, the post-sign-in rung is now `loggedIn && paired && loc == '/pin'`.
`paired` is not defensive padding — it is the condition the pair gate one rung
up would immediately re-assert, and asserting it here is what gives the ladder
a fixed point. Logged in but unpaired now *rests* on `/pin`, which is the
truthful destination: `/pin` carries the inline pair flow.

**And an unmatched location never reaches the user.** `GoRouter` gains an
`errorBuilder` that logs the failing location and `state.error` via
`SatLog.nav`, then bounces to `/pin`. Reaching it is by definition a bug; the
log line is what makes that bug nameable after the fact — it is the only reason
this one was diagnosable at all. `/pin` is safe for every session kind: the
redirect immediately re-routes a fleet super admin to `/fleet` (ADR-0016) and a
report owner to `/owner` (ADR-0036).

Separately, the two `context.go('/pin')` calls in `me_screen.dart` are deleted.
They were never load-bearing — the trace shows `redirect /me → /pin` firing
from `signOut()` alone — and a screen asserting a second opinion about where
the user belongs is the class of thing this ADR is about. `me_screen.dart` no
longer imports `go_router` at all.

### Not in scope

`pin_screen.dart`'s `context.go('/venue')` after a successful admin sign-in is
the same redundancy, and the loop-safe rung now covers the case it was
compensating for. It is left standing: admin sign-in boots the embedded server,
mDNS and TLS on the way through, and removing its explicit navigation wants its
own reproduction rather than a change made on the way past.

Routes in the bypass set (`/pin`, `/onboarding`, `/pair`, `/forbidden`,
`/book`) get no redirect decision by construction, so navigation *between* them
stays explicit — `mode_select_screen.dart` and `pair_screen.dart` keep their
`context.go('/pin')`.

## Consequences

- Admin sign-out is one redirect, `/me → /pin`, and lands immediately.
- The intermediate teardown state is now expressible: "logged in but unpaired"
  means "sit on `/pin`", which is also what a client that loses its pairing
  should do.
- `_killAdminSession()`'s two-step teardown is left as it is. Making it atomic
  would hide this class of bug rather than fix it — the ladder has to be
  correct for intermediate states regardless, because provider writes will
  always be observed between awaits.
- An unmatched location costs one blank frame and one log line instead of an
  English error screen.
- Trade-off accepted: a screen can no longer guarantee its own exit. If the
  ladder stops covering a case, the symptom is a screen that sits still rather
  than one that flickers — quieter, but less obvious. The `errorBuilder` log is
  the compensating signal, and it is the reason this ADR exists.
