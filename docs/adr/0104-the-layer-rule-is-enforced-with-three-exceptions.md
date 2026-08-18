# ADR-0104 — The layer rule is enforced, with three exceptions named

Status: accepted
Date: 2026-08-18

## Context

`CLAUDE.md` opened its architecture section with "Strict three-layer split:
`ui/` ← `domain/` ← `data/`", and described `lib/domain/` as "business logic,
no Flutter imports".

Neither sentence was true. Three use cases —
`advance_ticket_status_use_case`, `fire_course_use_case`,
`submit_order_use_case` — import `flutter_riverpod` (they expose providers) and
import `lib/data/repositories/...` (they orchestrate repositories). One service
goes the other way: `alert_sound_service` in `data/` imports a view model from
`ui/core/state/`.

Four files is not a crisis. A false claim in the document a new contributor
reads first *is* one, because the next person who needs a repository from a
use case reads "strict", assumes the four existing cases are something they
misread, and either contorts around the rule or quietly adds a fifth.

The rule was never checked, which is why it drifted without anyone noticing.

## Decision

**State the rule accurately and enforce it in a test.**
`test/layering_test.dart` bans each cross-layer import and carries an
allowlist of the files that already break it. The lists are frozen: an entry
comes off when the import goes away, and nothing goes on. A new violation
fails CI with the file named.

**`lib/domain/models/**` is pure, with no exceptions.** No Flutter, no `data/`,
no `ui/`, no `server/`. This is the part of the layer rule that carries real
weight — the models are what the server, the client and the tests all agree on
— and it is currently clean, so it is enforced with an empty allowlist.

**The three use cases are tolerated, not endorsed.** A use case is the place
where business logic meets the repositories it needs; the alternative is
injecting four repository interfaces through a constructor to satisfy a
diagram. The honest description is "`domain/` holds models that depend on
nothing, and use cases that orchestrate `data/`", so that is what `CLAUDE.md`
now says.

**`data/` importing `ui/` is the one that should go.** It is on the allowlist
so the ratchet can be set today, not because it is fine.
`alert_sound_service` reads `ready_alert_view_model` to decide what to play;
the fix is to move the shape it needs down into `domain/`, and that is a
change with its own testing story, not a drive-by.

## Considered options

**Fix the four violations, keep "strict".** The tidy answer, and the right one
for `alert_sound_service`. Rejected for the use cases: the dependency is real,
and the abstraction that would hide it — repository interfaces in `domain/`,
implementations in `data/` — buys nothing in an app where there is exactly one
implementation of each and no plan for a second.

**Delete the claim and say nothing.** Rejected: the direction *is* real and
worth stating, and unwritten conventions decay faster than wrong ones.

**A lint rule rather than a test.** `import_lint` and friends would express
this natively. Rejected for now: the project runs `flutter_lints` with no
custom rules, and a 100-line test that reads plainly beats a new dev-dependency
and a config file for five assertions.

## Consequences

`CLAUDE.md`'s architecture section is now checkable, and the check runs with
`flutter test`.

Removing an allowlist entry is a small, satisfying commit that cannot regress.
Adding one requires editing a file whose comment says not to — which is the
conversation the ratchet exists to force.
