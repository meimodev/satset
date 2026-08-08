# ADR-0087 — Permissions are edited one role at a time

Status: accepted
Date: 2026-08-08

Refines the presentation half of [ADR-0077](0077-one-admin-one-device.md); its
locking rules are unchanged.

## Context

Admin → Staf & akun carried three tabs: **Orang**, **Peran**, **Izin**. The Izin
tab held a role × capability grid — roles down the side, all nineteen
capabilities across, a horizontally scrolling row of 110dp cells each drawn as a
`✓` or a `—`.

The grid did one thing well: it answered "which roles can refund?" without
navigating. Everything else about it was working against the screen.

**110dp buys a label and nothing else.** Nineteen capabilities is not a list a
venue owner has memorised, and three of them are mutually indistinguishable from
their labels alone: `adjustStock` (Sesuaikan stok), `manageIngredients` (Kelola
bahan) and `overrideStock` (Jual saat stok habis) all read as "something to do
with stock". Getting those three wrong is how a waiter ends up able to sell past
empty. The cell had no room to say which was which, and no room to grow one.

**The grouping was structure nobody could see.** `Capability` has carried a
`CapabilityGroup` since it was written — orders, money, inventory, admin,
kitchen. The grid iterated in group order and drew no headers, so the five
groups existed in the type and nowhere on screen.

**Two tabs were already the same list.** Peran listed every role with its
capability count and member count. Izin listed every role with a row of cells.
An admin who wanted to change one role's permissions had to hold "which row is
Kasir" across a tab switch.

**The locks were three different shapes.** ADR-0077 locks the admin role, and
argued the right way to say so: *not a disabled tap that toasts — the cells
simply aren't controls*. That reasoning was applied to the admin row and never
revisited for the one cell beside it. `manageStaff` on a non-admin role stayed a
live-looking cell that refused with a snackbar on tap — the exact shape the same
ADR had rejected one function above.

## Decision

**The Izin tab is deleted. A role's permissions are edited in that role's own
sheet, and nowhere else.**

Staf & akun goes to two tabs. A Peran row becomes scan-only — colour dot, name,
`n/19 izin`, `n anggota`, chevron — and opens a sheet, mirroring how a person
opens from Orang.

The sheet holds one role: header with its name and member count, then rename /
colour / delete, then **five cards, one per `CapabilityGroup`**, each headed with
the group's name and an `on/total` count. Every capability is a row carrying its
label, **a one-line description of what it actually permits**, and a `SatToggle`.
That description is the payload the change exists to deliver — nineteen new
strings in both locales.

Rename, colour and delete move off the row and into the sheet. Delete stays
guarded by member count.

**Both locks render as state, never as a refused tap.** A locked row draws its
value as text (`aktif` / `nonaktif`) with no gesture target and one `Semantics`
label, so TalkBack reads the state without offering an action:

- the **admin role**'s sheet is read-only throughout — no rename, no colour, no
  delete, all nineteen rows locked, one banner in place of nineteen dead cells;
- **`manageStaff`** is locked on every other role too, its description replaced
  by the reason. The snackbar is gone. The guards in the repository and at the
  server are untouched.

**Cross-role comparison is not a job this screen does.** This is the real cost
and it is accepted deliberately, not overlooked. Answering "which roles can
refund?" now means opening roles one at a time. A venue runs a handful of roles
and changes them rarely; understanding one role correctly beats comparing four
badly.

## Consequences

- `_permissionsTab` and `_capCell` are gone, with `staffTabPermissions`,
  `staffMatrixTitle` and `staffMatrixHint`.
- `capabilityDescription` and `capabilityGroupLabel` join `capabilityLabel` in
  `lib/core/localization/labels.dart`. Adding a `Capability` now costs **two**
  ARB entries per locale plus a group, and all three `switch`es are exhaustive —
  the analyzer will name what is missing.
- `CapabilityGroup` renders for the first time. It was previously type-only
  structure; its five names are now user-facing copy and cannot be reordered
  without reordering the sheet.
- The phone still cannot reach Peran at all — `_phoneLayout` is a people list
  and predates this change. The sheet shape is the first version that *would*
  work one-handed, so closing that gap is now cheap. Not done here.
- ADR-0077's wording ("its permission-matrix cells are rendered as
  non-controls") describes a widget that no longer exists. Its rules hold
  unchanged; `CONTEXT.md` carries the current mechanism.

## Alternatives considered

**Keep the grid, add a detail sheet on top.** Comparison survives, but the two
surfaces disagree about which is the place to edit, and the grid keeps its 110dp
ceiling — descriptions still have nowhere to live.

**One card per capability group instead of per role**, each listing roles as
chips. Answers "who can refund" directly. Rejected: an admin's unit of work is
the role — it is the thing created, renamed, assigned and deleted — and the
admin lock would have had to repeat itself inside all five cards instead of
resolving once at the top of one sheet.

**Inline accordion on the Peran row** rather than a sheet. Keeps a weak form of
comparison (expand two, scroll between). Rejected for asymmetry: a person opens
in a sheet from the tab beside it, and a screen where one list expands and the
other opens is a screen with two navigation rules.

**A bulk "grant all" toggle per group card.** Rejected: money holds five
capabilities, and one tap granting refund, open drawer, discount, settle and
close shift is a footgun on the one surface where deliberation is the feature.
