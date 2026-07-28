# ADR-0055 — One control vocabulary, enforced as bans

## Status

Accepted. Supersedes the "ratchet" half of `test/design_tokens_test.dart`:
every rule in that file is now a ban with a count of zero, and there are no
baselines left to lower.

Serves `lib/ui/core/widgets/CATALOG.md`, which lists the vocabulary, and
ADR-0054, which renders it.

## Context

The policy already existed. `CATALOG.md` opened with "check this file before
writing a new widget", the guard test had been metering the drift since
ADR-0047, and its own comments named the fingerprint: three `_StatusChip`s, two
`_EntranceFade`s, two parallel motion systems. This was never a design problem.
It was an enforcement gap.

What the gap had produced, counted:

- ~139 raw Material buttons across the feature screens, in four classes, with
  `styleFrom` blocks that mostly restated a default.
- 64 raw `TextField`s in 21 files, each picking its own padding, radius, hint
  colour and border. The menu item editor had built a private field system —
  `_fieldDeco` + `_input` — that was this same system, for one screen.
- 30 private chip/pill/badge classes, including two files that each declared a
  `_FilterChip`.
- Three switches: a Material `Switch` on four rows, a hand-drawn `adminToggle`
  on twenty more, and a private `_Switch` in the zone admin.
- Four quantity steppers.
- 752 `SatType.sans/mono/display(size: …)` call sites spanning **104 distinct
  (family, size, weight) triples** — for a design source that publishes eleven
  type roles.
- 170 off-scale spacing literals, almost none of which were on-grid values that
  had merely missed their token: they were 3, 5, 7, 9, 22, 30 — sub-grid nudges
  accumulated one chip at a time.

## Decision

**One primitive per job, named for the job, and the raw alternative banned.**

Thirteen widgets in `core/widgets/`, listed in `CATALOG.md`. Each takes named
constructors that carry *intent* — `SatButton.danger`, `SatField.money`,
`SatChip.select` — rather than open styling parameters. A call site chooses
what a control **means**; it cannot choose what it looks like.

Three principles decided the shape of every one of them:

**Variants are closed; only colour and content are open.** `SatType`'s roles
take `color` and nothing else. `SatChip.tag` takes one of seven hues. A chip
that needs an eighth hue means something new, and that is a conversation, not a
parameter. The counter-example is in the numbers above: an open `weight:`
parameter is how five weights across 827 sites happened.

**A widget owns the rules that were leaking into screens.** Glow's pill-shaped
controls, slab-on-selected (ADR-0051), disabled-reads-from-the-neutral-ramp, and
the accessibility role of a tap target all moved out of call sites and into the
widgets. `SatIconButton` requires a `tooltip` because that is the only way an
icon-only target gets a name.

**Bans, not baselines.** A ratchet was right while the debt was too large to
clear in one pass. Once a family is fully converted, a baseline is worse than a
ban: it permits a regression as long as something else improves. Each family
became a ban in the same commit that finished it.

## Consequences

### Two roles the design source does not publish

The type sheet's eleven roles did not survive contact:

- **`labelL/M/S`** — the sheet specs buttons and chips at w600 on the body
  sizes, which `bodyL/M/S` (w500/w500/w400) cannot express.
- **`monoS`** (11 · 400) — ~100 sites set small mono at a regular weight.
  Folding them into the w600 `caption` would have shouted every timestamp in
  the app.
- **`monoDisplay54`** — the table number on its own detail page, the tabular
  twin of `display54`. Both call sites sit in a `FittedBox(scaleDown)`, so it
  is a ceiling rather than a chosen size; capping them at `monoDisplay`'s 36
  would have shrunk a read-at-distance numeral on the tablet.

`lib/ui/core/design/` is the canon (ADR-0051's finding, applied). Both design
artifacts are downstream mirrors of it.

### Distinctions the closed set cannot express

Three sites lost one, each commented where it happened. The bill's grand total
is now marked by ink rather than weight — the money ramp has no weight step —
and the table card's two responsive numerals take the poster role at both sizes,
letting the `FittedBox` do the rest.

That is the cost of a closed set, and it is the right side of the trade: 104
triples collapsing to 15 roles is worth three totals that read slightly quieter.

### Named exemptions, for the medium rather than the design

Two files are exempt from the type rule, both because their sizes are not the
design system's to choose. `receipt_preview.dart` mocks a 58mm thermal receipt.
`tablet_chrome.dart`'s rail label is tuned per skin to fit a 56px tile, where
`caption`'s tracking wrapped "MANDIRI" to two lines and overflowed the column.

Both are named by file, not exempted by shape, so any *other* literal in them
still trips.

### A ceiling on the spacing scale

`Sp` gained `s7` (28) and `s9` (36), both always on the 4px grid, and an
explicit ceiling of 48. A number above that is a dimension — a 560px panel, a
110px thumbnail — not spacing, and the guard no longer counts it. Without that
line the rule could never have reached zero: it was mixing two categories, and
the 29 it could not clear were all panel widths.

### Colours that must ignore the palette still get names

The last `Colors.white`/`Colors.black` uses were real design decisions wearing
a literal: the QR quiet zone, which stops scanning at charcoal and is read by a
guest's own camera, and the payment-proof lightbox, whose black chrome keeps the
room's lighting and the app's accent off a photo a cashier is reading an amount
from. Both became tokens (`satQrQuiet`, `satMediaChrome`/`satMediaInk`) rather
than file exemptions.

### Duplicate names are a ban, and most were renames

Five were genuine copies and merged. The other eight were generic names over
unrelated widgets — `_Header` three times, `_Footer`, `_Section`, `_ItemRow`.
Merging those would have produced one widget with the union of both APIs and the
shape of neither, so they are renamed for what they actually are. The rule
outlives the cleanup: a name colliding again is still the fingerprint of "rebuilt
it because I couldn't see the existing one".

### What this costs

Adding a shared widget now costs three edits in one commit: the widget, its
`CATALOG.md` row, and its `book_entries.dart` entry. That is the price of the
gallery being trustworthy, and it is the same price ADR-0054 already set.

A screen that genuinely needs something the vocabulary cannot express has to
either extend a primitive or argue for a new one. That friction is the feature.
