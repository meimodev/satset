# ADR-0102 — A route that cannot identify its caller refuses it

Status: accepted
Date: 2026-08-18

## Context

Every route factory took its auth helper as an *optional* positional
parameter — `Router ticketsRoutes(AppDatabase db, WsHub hub, [ServerAuth?
auth])` — and every capability gate behind it opened with the same line:

```dart
if (auth == null) return null;   // null = "not denied"
```

Twenty-four of those existed across sixteen route files. Three were worse than
the rest: `cashRoutes` and `membersRoutes` handed a null caller
`Capability.values` — literally every capability in the app — and `stockRoutes`
did the same. `referenceRoutes` used it to *un-hide* the admin rows of the venue
audit log.

The comments all said the same thing: "no auth helper configured (server-mode
boot before the secret loads)". That window does not exist.
`SatSetServer.auth` is a non-nullable field, assigned before `_buildRouter()`
is ever called, so in a shipped build the parameter is never null and every one
of those branches is dead.

What kept them alive was the test suite. Eighteen route tests built a router
with the argument omitted, precisely so their requests would sail past the
capability check and let the test get at the behaviour underneath. The dead
production branch was a live test affordance — which is the worst version of
this, because the thing making the code look necessary is the thing that would
never have exercised it.

The risk is not today's binary. It is the next route file, copied from a
neighbour, carrying `[ServerAuth? auth]` and its fail-open first line into a
context where somebody eventually forgets to pass the helper. A default of
"unauthenticated means allowed" is a defect waiting for a caller.

## Decision

**`ServerAuth` is a required, non-nullable argument to every route factory.**
The optional-positional form is gone, and with it every `if (auth == null)`
branch. A route that cannot identify its caller cannot be constructed, so
"unauthenticated" no longer has an allow path to fall into.

**Tests sign in like clients do.** `test/support/route_auth.dart` seeds a role,
a user and a session and hands back a `ServerAuth` plus a bearer token; a route
test passes the helper to the factory and the token on the request. The default
caller holds every capability, so a test whose subject is not permissions pays
one line for the change.

**A test that cares about a capability names it.** `signInForTest(db, caps:
{...})` narrows the grant. The stock tests already need this: their subject is
the stock guard, and a caller holding `overrideStock` is never blocked by it.
Making the caller explicit turned an implicit "no auth, so no override" into a
stated "this caller may not override", which is what the test always meant.

## Considered options

**Flip the null branches to deny, keep the parameter optional.** Half the fix
and none of the guarantee: the parameter can still be omitted, and the next
person to omit it gets a router where every request 401s for reasons that take
an afternoon to find. Failing closed at runtime is worse than not compiling.

**Keep the affordance behind an explicit flag** — `allowUnauthenticated: true`.
Rejected: it is the same hole with a nicer name, and a flag that exists for
tests is a flag production can set.

**Leave it; the branch is unreachable.** Rejected. It is unreachable *today*,
by one field's nullability in one file, and nothing states or checks that
relationship. The invariant is worth having in the type system rather than in
the reader's head.

## Consequences

Sixteen route factories changed signature. Nothing calls them but
`SatSetServer._buildRouter` and the tests, both updated.

Route tests are now more honest and slightly louder: a request without a token
gets a 401, which is what a real client would get. Two stock tests changed
meaning in the process — see the `caps:` note above — and that change is a
correction, not a workaround.

The `_hasCap` helper in `tickets_routes.dart` loses its "a bypass that silently
switches itself on is the wrong default" comment, because the situation it
guarded against can no longer arise. The reasoning survives here.
