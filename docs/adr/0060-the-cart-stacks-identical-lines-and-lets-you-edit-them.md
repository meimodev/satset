# ADR-0060 — The cart stacks identical lines, and lets you edit them

## Status

Accepted. Covers the in-progress cart (`cartProvider`) only — the review
screen, the tablet cart pane, and the modifier sheet that feeds them. Sent
tickets are frozen and untouched.

## Context

`CartViewModel.add` appended unconditionally. A waiter taking "tiga nasi
goreng pedas" tapped the same dish three times and got three rows reading
identically, each `×1`. Nothing in the cart could tell them apart, because
nothing about them was different.

Neither cart surface offered any edit at all. `_ReviewCourseBlock` and
`_TabletCartPane` each rendered a line with exactly one verb: Hapus. Wrong
spice level, wrong quantity, wrong course — all of them meant delete and walk
back through the menu. The most common correction in the job (make it three
instead of two) cost the most taps.

## Decision

**Stacking happens in `add`, not at render time.** The cart holds one merged
`CartItem`; it does not hold three and fold them for display. Every surface
inherits it — the footer count, the tablet pane, the review list, and the
ticket the kitchen receives, which now says `×3` on one line instead of
printing the same dish three times. Grouping at render would have duplicated
the predicate in two widgets and left the wire format unchanged.

**Two lines are the same line when `itemId`, `variantId`, `course`, trimmed
`note` and the *set* of `(groupId, optionId)` all match.**

- The set, not the list: a waiter who taps "pedas" then "tanpa es" means the
  same thing as one who taps them in the other order. Comparing ordered lists
  would produce two rows that read identically and never stack — the exact bug
  being fixed.
- `note` counts. Two otherwise identical dishes with different special
  instructions are different instructions to the kitchen. Trimmed, because
  trailing whitespace is not a distinction anyone typed on purpose.
- `course` counts. The same dish held for mains and the same dish fired now
  are different timings. Merging them would silently move one.
- `id`, `qty`, `unitPrice` and `allergens` are out: a fresh uuid per add, the
  thing being summed, and two values fully derived from the fields above.

The predicate lives on the model (`CartItem.sameLineAs`) rather than in the
view model, because it is a statement about what a cart line *is*.

**A stacked line caps at 99; a single trip through the sheet still caps at
20.** Adds are never rejected — 15 plus 10 gives 25, not a tap that does
nothing. A tap producing no visible change is the failure mode the design
principles call out, so the cap is a ceiling on the total, not a gate on the
add. (The sheet's own stepper was passing the default `max: 99` while its
callbacks clamped at 20, so its last twenty `+` taps did nothing; it now
passes `max: 20` and disables honestly.)

**Editing reopens the same modifier sheet, prefilled.** `showModifierSheet`
takes an optional `editing: CartItem`; the body seeds `_variantId`,
`_selections`, `_special`, `_course` and `_qty` from it and the foot button
reads "Simpan". One surface owns modifier rendering, price math and
required-group validation — a second edit-only sheet would have been a second
place to fix the next modifier bug.

**An edit that recreates an existing line merges into it.** `replace` runs the
same identity check as `add`. Editing the `×1` biasa to pedas when a `×2`
pedas already exists yields one `×3` at the older line's position. Without
this, the invariant "the cart cannot hold two rows that read the same" would
hold on the way in and break in three taps.

**Merges keep the older line's id.** The surviving row is the one the stepper
is already bound to, so its identity does not change under the waiter's
finger mid-edit.

**`CartLineActions` is one widget used by both surfaces.** Stepper, Ubah,
Hapus. It lives in `lib/ui/features/menu/` (next to the cart provider it
drives) and is imported by the review screen — the same direction that screen
already imports `cartProvider`. Not promoted to `ui/core/widgets/`: it is
bound to `cartProvider` and to two screens, which is a feature widget, not
shared vocabulary.

## Consequences

- The `×N` prefix is gone from both cart lines — the stepper is the quantity
  readout now, and printing it twice invites the two to disagree.
- Line price moved up onto the name row. The stepper plus two labelled actions
  plus a price did not fit the 380-wide tablet pane on one row.
- The tablet pane now renders the note, which it never did. It has to: the
  note is part of the identity key, so two lines can differ by nothing else,
  and a cart that hides the only difference between two rows is worse than one
  that merges them wrongly.
- **Ubah is hidden, not disabled, when the dish no longer resolves in the menu
  snapshot** (86'd or deleted while the line sat in the cart). There are no
  modifier groups to prefill the sheet with. The line stays removable. The
  sheet also falls back to the first variant if the line's variant was
  retired, rather than throwing on a `firstWhere` that finds nothing.
- **Decrementing at 1 does not delete.** The stepper floors at 1 and Hapus
  stays the only way out, so an overshoot cannot silently drop a line from a
  cart that has no undo.
- Notes are compared case-sensitively. "Tanpa bawang" and "tanpa bawang" stay
  separate lines. Case-folding Indonesian free text to decide whether two
  kitchen instructions are the same is a bigger claim than this needs to make.
- `CartItem` gains `copyWith`, `modifierKeys` and `sameLineAs`. It is plain
  Dart, not freezed, so `copyWith` is hand-written and must be extended
  alongside any new field.
