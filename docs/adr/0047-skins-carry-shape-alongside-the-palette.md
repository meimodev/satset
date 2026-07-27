# ADR-0047 — Skins carry shape alongside the palette

## Status

Accepted. **Amended by ADR-0048** — the last consequence below ("Layout is
untouched") held only for this change and is no longer true of the floor screen.

## Context

ADR-0045 made a theme a whole look — id, label, `Brightness`, `SatColors` — and
put four of them behind one device-local picker. Every one of those four shares
a single shape language: 8–28px corners, hairline translucent rules, no drop
shadows. A theme could change *what colour* a card was, never *what a card is*.

The SatSet v2 design project then landed a neo-brutalist skin: square corners,
3px solid-ink rules, hard un-blurred offset shadows, Archivo Black display type,
and semantic hues used as full-saturation fills rather than 14% tints. Colour
alone does not carry it. Siren yellow on cream with 14px corners and hairline
borders is not the design — it is the old design wearing a wig.

Two things stood in the way:

1. **`SatColors` cannot hold shape.** It is a `ThemeExtension`, so every field
   must interpolate through `lerp`. A corner radius could, but the shape
   language is a *mode*, not a magnitude — halfway between round and square for
   200ms during a theme swap is a glitch, not a transition. Same reason
   `Brightness` lives on `SatTheme` and not in the token bag.

2. **Shape is not read where a theme is read.** Colour is consumed as
   `context.sat.bg2` — a `BuildContext` is always in hand. Radii and borders are
   consumed as ~800 `BorderRadius` / `Border` / `BoxDecoration` literals, a large
   share of them in static widget helpers and default parameter values with no
   context in scope. Threading a context into all of them buys nothing this app
   uses.

## Decision

### A palette picks its shape language; they are one choice

`enum SatSkin { lembut, brutal }` is a field on `SatTheme`, defaulted to
`lembut`, alongside `Brightness` and for the same reason. Two new themes join
the existing four in the same picker:

| enum          | label             | brightness | skin     |
| ------------- | ----------------- | ---------- | -------- |
| `neoKertas`   | Neo Kertas        | light      | `brutal` |
| `neoMidnight` | Neo Tengah Malam  | dark       | `brutal` |

No second setting, no skin × palette matrix. The neo colours only read correctly
with square corners and fat rules, and the reverse holds too — offering the
crossings would ship six broken combinations to explain away.

### Shape tokens are statics, published once per theme build

`SatShape` holds the live skin and its ink colour as plain statics.
`SatTheme.adopt()` writes them; `satTheme()` calls it before building the
`ThemeData`, and `satTheme()` runs inside `SatSetApp.build` — so the skin is in
place before any descendant builds a decoration. One writer, no race, and the
type ramp in `SatType.buildTextTheme` can branch on it too.

The ceiling: two skins cannot render side by side (a theme-preview grid showing
real widgets). If that is ever wanted, `SatShape` becomes an `InheritedWidget`
and the helpers below take a context.

### Three helpers absorb the migration

Call sites moved mechanically, with no behaviour change under `lembut`:

| was                        | now              |
| -------------------------- | ---------------- |
| `BorderRadius.circular(n)` | `SatR.a(n)`      |
| `Radius.circular(n)`       | `SatR.c(n)`      |
| `Border.all(…)`            | `SatB.all(…)`    |
| `BorderSide(…)`            | `SatB.side(…)`   |
| `BoxDecoration(…)`         | `SatBox.d(…)`    |

Under `brutal`: every radius collapses to 0, every rule snaps to 3px. Border
*colour* needs no indirection — the neo palettes define `border0/1/2` as the
same fully opaque ink, so the existing tokens already carry it.

`SatBox.d` adds the hard shadow on a heuristic rather than per widget: a
decoration that draws a border **and** a corner radius on a rectangle is a card,
and cards are what the skin lifts. Full-bleed chrome (rule, no radius) keeps its
rule flat; round status dots stay flat — which is what the source design does
explicitly. A call site passing its own `boxShadow` is left alone.

`lib/core/export/` is excluded. Those build printed PDFs, not screens.

### Floating chrome drops the frosted glass

The phone tab bar and the menu cart footer float over scrolling content on a
translucent, blurred surface. The brutal skin has no frosted glass: the surface
goes fully opaque via `SatShape.veil`, the `BackdropFilter` is skipped entirely
(a `saveLayer` saved with it), and the soft drop shadow becomes a hard one.
Skipping the blur also matters because the hard shadow has to fall *outside*
the clip that the blur requires.

### The accent splits into a fill and a foreground

Siren yellow is 1.3:1 on white. It is the right colour to *fill* with — paired
with `accentInk` it is the skin's primary button — and unusable as text. The
codebase did not distinguish: `sc.accent` was both the button's surface and the
selected tab's label, in 152 places.

`accentText` is now the foreground role, declared per palette like `successInk`
before it. 84 call sites moved (selected labels, active icons, spinners,
`foregroundColor`, `cursorColor`); fills, borders, chart series and heatmap
lerps kept `accent`.

This exposed a defect predating the skin: `light`'s amber is 2.2:1 on its own
paper. Its `accentText` burns down to `#A34B00`. Dark themes are unaffected —
their accent was always mid-luminance on charcoal — so five of six palettes set
`accentText == accent` and render identically to before.

`sat_theme_contrast_test` now asserts `accentText` against `bg0`/`bg1`/`bg2` for
every theme. The gap that let both defects ship was that the suite only checked
ink-on-fill pairs (`accentInk`/`accent`), never the accent drawn *as* ink.

### Bare Material widgets are skinned in `ThemeData`, not by the helpers

`SatR`/`SatB`/`SatBox` only reach decorations the app writes. A `showDialog` +
`AlertDialog` writes none — its shape, its surface, and its buttons come from
`ThemeData`. Under `brutal` that shipped a round white blob with stadium-pill
buttons sitting inside a square-corner app. So `_build` now also sets:

- `dialogTheme` — `SatR.a(28)` plus a `brutalBorder` ink side.
- `filledButtonTheme` / `elevatedButtonTheme` / `textButtonTheme` /
  `outlinedButtonTheme` — square under `brutal`, Flutter's default under
  `lembut` so the existing look is untouched.
- `textButtonTheme` / `outlinedButtonTheme` foreground — `accentText`. M3 spends
  `colorScheme.primary` on both the filled button's surface and the text
  button's label; the palette splits those roles and the scheme cannot.

### The tablet rail inverts across the two neo palettes

`SatShape` also publishes the adopted `Brightness`, because one piece of chrome
genuinely differs between the two brutal palettes rather than just re-reading
the ramp (neo.css §7 vs. its `[data-neo="midnight"]` block):

|              | rail        | logo block   | active tab       |
| ------------ | ----------- | ------------ | ---------------- |
| Neo Kertas   | `accent`    | ink on siren | `bg1`, lifted    |
| Neo Midnight | `bg1`       | siren on ink | `accent`, lifted |

`SatShape.brutalPaper` names that case. The rail's rule is 4px where cards get
3 — the source deliberately makes structural chrome heavier — and the active
tab is a bordered, hard-shadowed block cut out of the rail rather than the soft
skin's tinted fill. Nav labels go uppercase at w700 and take the rail's own ink,
since on paper both states sit on a bright ground.

The rail avatar is squared, against the "circles stay circles" rule below: at
42px it reads as a nameplate, not a status pip, and the source squares it
explicitly. Rail badges take a 2px rule, not 3 — a 16px pip at the full width
would be all border and no count.

### Where fidelity was traded

- **`successInk` on Neo Kertas is near-black, not the source's `#fff`.** White on
  `#00B84A` is 2.6:1 and fails AA; `sat_theme_contrast_test` catches it. A
  "ready" badge is exactly what a waiter reads at a glance.
- **Neo Tengah Malam retunes the course hues** to its own semantics. The paper
  palette's blues and greens are far too dark to survive on `bg0`.
- **`cFire` borrows `urgent`, not `accent`.** Siren yellow is the skin's default
  surface colour, so it can no longer carry "fire this now" on its own.
- **Circles stay circles.** The source skin squares avatars and status pips
  along with everything else. Flutter reaches those through `BoxShape.circle`,
  not a radius token, so no shape helper can catch them — and a round pip reads
  better than a square one on a KDS at 1–2 m. Deliberate deviation.
- **Uppercase is applied to app-bar titles and crumbs only**, via
  `SatShape.caps`. Flutter has no global text transform, and shouting 146
  button labels would cost more than the look is worth. The heavy weight and
  +0.14em label tracking carry the voice.

## Consequences

- Adding a skin means one enum value plus branches in `SatR`/`SatB`/`SatBox` and
  `SatType`. Adding a *palette* is still just a `SatColors` const.
- New UI must use the helpers. A raw `BorderRadius.circular` compiles fine and
  silently ignores the skin — the failure is visual, not a build break.
- Layout is untouched **by this ADR**. Every token here is paint-level: no size,
  spacing, breakpoint, or composition changed.

  Superseded in scope by ADR-0048: the floor screen's composition, grid and card
  anatomy did subsequently change, for every palette rather than just the brutal
  ones. The rule that still holds is the narrower one — *a skin* changes paint
  only. A skin cannot move a widget, and nothing here lets it.
