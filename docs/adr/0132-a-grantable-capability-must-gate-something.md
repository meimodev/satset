# ADR-0132 — A grantable capability must gate something

Status: accepted
Date: 2026-09-04

## Context

`Capability` has twenty-three values. The role sheet renders every one of them
as a toggle, each with its own label and its own sentence of ARB copy saying
what it lets a person do, and `_ensureAdminRole` reconciles the admin role to
`Capability.values` on every boot so a new one reaches existing venues. The
whole design says: an owner reads the sentence, ticks the switch, and a person
can now do the thing.

Two of them could not. Nothing anywhere asked for them.

**`manageRoles`** was never checked by a route. `POST`, `PATCH` and
`DELETE /roles` have gated `manageStaff` since they were written, so the
capability whose copy reads "Create roles and set the permissions they carry"
carried nothing. Its one observable effect was a side door:
`_roleFromCapabilities` in `auth_repository.dart` derives the legacy `UserRole`
bucket from `manageStaff || manageRoles || editSettings`, and three screens
gated on that bucket rather than on a capability. Ticking "Kelola peran"
therefore granted zone editing and the full menu editor — two things it does
not name.

**`adjustStock`** was superseded and left standing. v36 moved inventory onto
ingredients and recipes ([ADR-0040](0040-ingredient-level-inventory-replaces-item-stock-counts.md),
[ADR-0041](0041-stock-deducts-at-send-ledger-and-balance.md)) and its backfill
granted `manageIngredients` to every `adjustStock` holder. Every stock route
then gated `manageIngredients`, and `adjustStock` was referenced by nothing but
the seed. The seeded **Manager** role is the proof: it holds `adjustStock` and
not `manageIngredients`, so a manager has been bounced to `/forbidden` from the
stock screen for as long as the screen has existed, holding a switch named
after the thing they could not do.

Both are the same failure, and it is quiet in a specific way. A capability that
gates nothing does not error. It renders, it persists, it audits its own grant
through `AuditKind.roleCapabilityChanged` — and the owner walks away believing
they configured something.

Two further gates were wrong in the same direction. `markSoldOut` **is**
enforced, on `POST /menu/items/<id>/availability`, but the only client that
calls it sits behind `/menuadm`, gated on `editMenu` — so the seeded Kitchen
role, whose entire inventory authority is `markSoldOut`, could not reach it;
and the toggle itself never checked the capability, so an `editMenu` holder
without it got a button that answered 403. `modifyOrder` gates
`PATCH /tickets/<id>` server-side with no client gate at all.

## Decision

**A capability that appears in the role sheet gates a write.** Concretely:

### 1. Stock is cut between the catalogue and the ledger

- `manageIngredients` — define what a bahan *is*: create, archive, and the batch
  recipe saying what one costs to make.
- `adjustStock` — move the numbers it carries: receive, waste, produce, and the
  opname session from open to close.

Neither implies the other. This is [ADR-0042](0042-generic-seed-covers-inventory-and-recipes.md)'s
rule stated as a gate — the people who physically receive and count stock are
the ones who record it, and they are not always the ones who author the
catalogue. The opname session stays wholly on the ledger side: it is one act
from `openCount` to `closeCount` ([ADR-0096](0096-an-opname-is-a-document-not-a-burst-of-adjustments.md)),
and splitting it across two authorities would strand a half-walked count.

Reads take either capability, plus `viewReports` on the archive and the report
and `editMenu` on the ingredient list, which the item editor picks from. You
cannot count what you cannot list.

`/stock` becomes a two-authority route, the `/kas` shape: either capability
opens it and each half renders for whoever holds it. The add-ingredient button
and the row's edit/archive actions come off without `manageIngredients`; the
receive card and the opname banner stay.

### 2. Rewriting a role's permission set costs `manageRoles`

`manageStaff` remains the door to the staff screen and owns hiring, firing,
naming and recolouring. The capability half of `PATCH /roles/<id>` costs
`manageRoles` on top — checked inside the handler rather than at the route,
because name, colour and capabilities share one PATCH and gating the whole
route would take renaming away from `manageStaff`.

`POST /roles` also costs `manageRoles` **when the body carries a non-empty
capability set**. Leaving creation open would make the PATCH gate decorative:
create the role holding what you wanted, assign a person, done. An empty role
is a label with no power, so `manageStaff` alone may still mint one and fill it
in through the gated PATCH.

Client-side the toggles render as state rather than as controls without
`manageRoles` — the shape [ADR-0077](0077-one-admin-one-device.md) already gives
the locked admin role. Reading a role's permissions stays open; the screen's
purpose is to show them.

### 3. Screens gate on capabilities, never on the legacy `UserRole` bucket

`zone_admin_screen` now reads `editSettings` (what `POST`/`PATCH`/`DELETE
/zones` actually demand) and `menuPermissionProvider` reads `editMenu`.
CONTEXT.md has always said the bucket is a seed-and-reporting classification
and never a permission; these two were reading it as one.

`MenuPermission` grows a third arm — `full` / `soldOutOnly` / `readOnly` — so a
`markSoldOut`-only holder gets the list and the toggle and nothing else.
`/menuadm` becomes `[editMenu, markSoldOut]`. The **toggle itself** asks
`markSoldOut` directly rather than reading the tier, because the two
capabilities are orthogonal: an owner may hold the catalogue and not the
toggle, and deriving it from the tier would reproduce the same 403 one enum
further along.

### 4. Both new gates are backfilled once, in a migration branch

v73 grants `adjustStock` from `manageIngredients` and `manageRoles` from
`manageStaff`. Enforcing without this would **revoke rather than restrict**:
every role receiving stock under `manageIngredients` would lose the ledger, and
every role editing permissions under `manageStaff` would lose the role sheet.

Note the mirror — v36 granted `manageIngredients` *to* `adjustStock` holders and
this grants it back — so the two populations come out equal and only a role
authored **after** the migration can hold one without the other. That is the
point of splitting them.

A migration branch and deliberately **not** a boot-time reconcile like
`_ensureAdminRole`: this repairs an upgrade once. Reconciling every boot would
re-grant what an owner had just chosen to revoke. (`_ensureWaiterCanVoid` has
exactly that bug today and is left alone here.)

## Consequences

- The seeded Manager can run stock, which they never could. They still cannot
  author a bahan — that changes what every recipe costs and stays the owner's,
  one tap away in the role sheet.
- A venue that wants the old merged authority ticks both switches. Nothing is
  removed from any existing role.
- `adjustStock` and `manageRoles` are now unremovable in the ordinary way: their
  names are persisted in `roles.capabilities_json` and renaming one orphans
  every row that holds it, the `AuditKind` rule.
- A capability added from here needs a gate in the same commit. A grantable
  toggle that enforces nothing is a review finding, not a placeholder — this
  ADR exists because two of them survived for years by being plausible.

## Alternatives considered

**Delete `adjustStock`.** The first proposal: v36 superseded it on purpose, so
resurrecting it re-splits an authority a migration deliberately merged. Rejected
because the merge is what locked the seeded Manager out — the venue role that
most obviously needs to receive a delivery and least obviously needs to author
the pantry. The split is the fix, not the regression.

**Split receive/produce from waste/opname**, on the grounds that variance is a
manager's answer. Rejected: it cuts the opname session in half, and
`stock_counts.dart` treats open-walk-close as one act.

**Gate the whole of `PATCH /roles/<id>` on `manageRoles`.** Simpler, and wrong:
it takes renaming and recolouring away from `manageStaff`, which owns them.

**A boot-time reconcile instead of a migration.** Cheaper — no `schemaVersion`
bump, no schema dump — but it re-grants forever, so a revocation an owner meant
would not survive the next restart.
