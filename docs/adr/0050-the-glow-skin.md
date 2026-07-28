# ADR-0050 — The Glow skin

## Status

Accepted. Extends ADR-0047 (skins carry shape alongside the palette) with a
third skin, and amends ADR-0045's theme roster. **Amended by ADR-0057** — the
consequence below that "`SatTheme.fallback` stays `amberGelap`" no longer holds;
it is now `neonTerang`.

## Context

ADR-0047 established that a palette picks its shape language and that the two
travel as one choice. It shipped two: `lembut` (the original soft look) and
`brutal` (neo-brutalist). Its own closing consequence set the price of a third:
*"Adding a skin means one enum value plus branches in `SatR`/`SatB`/`SatBox` and
`SatType`."*

The SatSet design project then landed **Glow** — a skin whose reference sheet
states its own grammar in six rules, of which three are structural:

1. **Slab stacking.** A screen is a stack of full-bleed colour slabs (bone base
   → lime block → obsidian block), no gutters between them.
2. **Big soft radii.** 12 / 16 / 20 / 26 / 32 / pill.
3. **No rules.** Separation comes from slab colour and air, never a border. Only
   floating things carry a soft ambient shadow.

Plus sentence case throughout, Archivo grotesk for *everything* including
numerals, and lime `#E1FF0F` as the one action colour, always on obsidian ink.

It ships two palettes — `glow` on a bone ground, `glowNoir` on obsidian — which
is the same light/dark pairing the amber themes already have.

Three things about it did not fit the existing machinery.

1. **"No borders" is not expressible at `SatB`.** Glow zeroes card borders but
   keeps hairlines on chrome. `SatB.all`/`SatB.side` see a colour and a width;
   they cannot tell a card from a topbar, and there are 268 call sites.
2. **Obsidian slabs have no home in the ramp.** In `glowNoir`, obsidian is just
   `bg0`. In `glow` it is off-ramp entirely — the ramp runs `#EEEFE0` → white —
   yet KDS ticket heads, the ready toast, the sent overlay, the active category
   tab and the brand mark are all obsidian blocks on a light screen. Worse, the
   CSS re-declares every semantic hue *inside* those blocks with one scoped
   rule, because `glow`'s hues are tuned as ink on white and go muddy on dark.
   Flutter has no cascade.
3. **`SatShape.brutal` is a bool.** 76 call sites ask a yes/no question that now
   has three answers.

## Decision

### `SatSkin.glow`, named after its source

Two themes join the picker; one of them is a rename.

| enum         | label       | brightness | palette             | skin   |
| ------------ | ----------- | ---------- | ------------------- | ------ |
| `neonGelap`  | Neon Gelap  | dark       | `SatColors.glowNoir` | `glow` |
| `neonTerang` | Neon Terang | light      | `SatColors.glow`     | `glow` |

`neonHijau` **becomes** `neonGelap`: same slot in the picker, retuned to the
design's obsidian/lime values and moved onto the glow skin. Neon Light and Neon
Dark are one design in two brightnesses, which is what the naming pair claims
and what the design file actually ships. The old pure-black/`#B6FF3D` palette is
deleted rather than kept as a seventh theme — nobody asked for two neon greens.

The skin identifier is `glow`, not an Indonesian word matching `lembut`. It ends
up in ~76 `switch` arms, and matching `data-skin="glow"` / `glow.css` exactly
means tracing a Flutter branch back to its source rule is one grep. The labels
stay Indonesian (`Gelap`/`Terang`), matching `Amber Gelap`/`Amber Terang` — the
picker is UI, the enum is not.

**The rename ships without a migration alias.** A device that had picked
`neonHijau` finds no matching key and lands on `SatTheme.fallback` once. The
palette underneath the name changed too, so there is no old choice left to
honour, and the setting is device-local and cosmetic.

### Borders are carried by the palette, not by `SatB`

Glow's own border ramp is already near-invisible — α 0.05 / 0.09 / 0.14 — and
its `--hair` chrome rule is α 0.07, i.e. *the same range*. The design's
`border: 0` on cards is always paired with `box-shadow: var(--lift)`.

So `SatB` stays a pass-through under `glow` and the palette does the work. A
card renders as an α0.09 hairline under a soft ambient shadow, which is the
borderless-slab read; chrome hairlines land at exactly the alpha the design
specifies. **Zero edits across 268 call sites**, and no new indirection to
distinguish card borders from chrome rules — a distinction the choke point could
not make anyway.

This is the same move ADR-0047 made for `brutal`, where "every rule is solid
ink" was carried by the neo palettes defining `border0/1/2` as opaque black.
The mechanism generalises: *border colour is a palette decision, border width is
a skin decision.*

### Radii map through a step function, not a multiplier

`SatR.a`/`SatR.c` gain a total, monotone step map under `glow`:

| incoming | out    |
| -------- | ------ |
| `999`    | pill   |
| `≥ 28`   | 32     |
| `20–27`  | 26     |
| `14–19`  | 20     |
| `8–13`   | 16     |
| `< 8`    | unchanged |

One function body covers all 445 call sites. Every output lands on a real Glow
token, which a flat multiplier does not (14 × 1.4 = 19.6). The `< 8` passthrough
is load-bearing: those 60-odd sites are status pips, check marks and meter bars,
not corners — inflating them would round away the shapes they exist to draw.

The app's most common corner is 14, which moves a full step to 20. That is the
intended change, not drift: Glow's ramp genuinely starts higher.

### Shadows come from three places, none of them a call site

- `SatBox.d` reuses the card heuristic ADR-0047 already defined (fill **and**
  border **and** radius on a rectangle) and attaches Glow's soft `lift`. The
  heuristic needs no change — it selects exactly the set `glow.css` lifts.
- `SatShape.hardShadow()` returns the soft lift under `glow`. Ten call sites
  bypass `SatBox.d` and call it directly; without this they would render flat,
  and under a skin whose only separator *is* the shadow, flat means invisible.
- `theme.dart` gives `dialogTheme` and `bottomSheetTheme` the larger `liftLg`
  via `elevation` + `shadowColor`, for the same reason ADR-0047 skinned them
  there: `SatBox.d` never sees a dialog.

### The type ramp is a third one, not `brutal`'s

Glow and brutal both set Archivo, which makes the existing
`brutal ? Archivo : IBMPlex` branch look reusable. It is not: `_brutal` is an
uppercase ramp built on Archivo Black with tracking tuned for caps. Glow is
sentence case, 700 titles at `-0.02em`, 800 numerals at `-0.04em`.

`SatShape.caps` already returns its argument unchanged for non-brutal skins, so
sentence case costs nothing.

**The mono ramp becomes Archivo with `FontFeature.tabularFigures()` forced on.**
The design sets everything in the grotesk and relies on `tabular-nums`. Prices,
KDS timers and table numbers all read through this ramp, so the font feature is
not cosmetic — without it a proportional grotesk makes a running timer jitter
per digit. Forcing the feature explicitly, rather than trusting a default, is
what makes dropping a true monospace safe.

### `SatColors` gains `onHue` and `slab`

Two fields, both nullable, both with a getter that makes the null case
invisible to call sites.

**`onHue`** — fixed ink for text on *any* solid semantic fill in this palette.
Null means "compute it from the fill's luminance", which is what `onFill()` does
and what every palette shipped before Glow. Read through `sc.inkOn(fill)`.

Glow declares it because its hues are deliberately uniform — all dark on the
light palette, all bright on the dark one — and two of `glowNoir`'s (`urgent`
`#FF7A68`, `info` `#8E86FF`) sit just under `onFill`'s luminance cut and would
take white ink where the design asks for obsidian. The Neo palettes cannot
declare it: their hues span both ends, which is precisely the case `onFill`
exists for. Keeping it nullable means six palettes need no change.

**`slab`** — the palette that content on an obsidian block is drawn with.
`glow` points at `glowNoir`; every dark palette returns itself, so call sites
read `sc.slab` unconditionally and never branch on brightness. This is the
scoped CSS rule, named. It works as a `const` because `glowNoir` is declared
first in the file — a deliberate ordering, noted at the site.

Neither interpolates in `lerp`: `onHue` is a binary choice of ink and a
half-blended grey is unreadable at both ends, and `slab` is a whole palette.
Both snap at the midpoint, for the same reason `SatTheme` keeps `Brightness`
out of the token bag (ADR-0047 §Context).

### The 76 skin tests become an exhaustive `switch`

`SatShape.brutal` stays for what it says, but the call sites that branch on the
skin move from `if (brutal)` to `switch (SatShape.skin)`. Exhaustiveness is the
point: with a bool, a fourth skin silently inherits `lembut` at all 76 sites and
the failure is visual. With a switch it is a build break.

`SatShape.brutalPaper` (`brutal && light`) gets a mirror, because Glow inverts
across its two palettes in the same places the Neo pair does:

|            | brand mark      | rail            | active category tab |
| ---------- | --------------- | --------------- | ------------------- |
| Neon Terang | obsidian on lime | `bg1` + hairline | obsidian fill       |
| Neon Gelap  | lime on obsidian | `bg1` + hairline | lime fill           |

### Press feedback becomes a real widget

Glow specifies `:active { transform: scale(0.97) }` on buttons, zone tabs and
segments. That is a new primitive — `SatPressScale` in `core/widgets/`, taking
its duration from `satMotion` so reduced motion collapses it to the final state
per ADR-0044's rule. It carries a CATALOG.md row and a widget-book entry, as
ADR-0054 requires of any shared widget.

The hover lift (`translateY(-2px)`) is **not** ported. These are touch tablets
and phones; there is no hover.

## Consequences

- ADR-0047's estimate held: one enum value, branches in `SatR`/`SatBox`/`SatType`
  and `theme.dart`. What it did not anticipate is that a skin might need *palette
  fields* — `onHue` and `slab` are both shape-driven, and both had to live in
  `SatColors` because that is where a `BuildContext` reaches.
- The roster grows 6 → 7. `SatTheme.fallback` stays `amberGelap`.
- `design_skin_test` now asserts the full theme→skin map exhaustively rather than
  "everything not neo is lembut". A new theme that forgets to pick a side fails
  there instead of silently inheriting.
- **`SatB` now means different things under different skins**: it sets width
  under `brutal`, and is a pure passthrough under `lembut` and `glow`. Anyone
  reading it expecting a single job will be briefly confused; the alternative was
  268 edits to express something three palette constants already say.
- Devices on Neon Hijau reset to Amber Gelap once, on first launch after upgrade.
