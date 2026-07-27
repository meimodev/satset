# ADR-0051 — Reconciling screens against the design source

## Status

Accepted. Follows ADR-0050, which added the Glow skin's tokens and shape
language. This one covers what the tokens could not reach.

## Context

ADR-0050 shipped Glow as paint: palettes, a radius map, a lift shadow, a type
ramp, and an exhaustive skin switch at the chrome call sites. Adopting the theme
after that produced a screen that was recognisably Glow-coloured and entirely
wrong in three specific ways.

All three come from the same root: **`SatColors` and `SatShape` can change what
a widget is painted with, never what it is.** Glow's first grammar rule is slab
stacking — a screen is a stack of full-bleed colour blocks — and a slab is a
composition decision, not a token. ADR-0047 already drew this line and ADR-0048
already crossed it once, for the floor screen.

The three:

1. **`sc.slab` had no readers.** ADR-0050 added the field and the accessor, and
   nothing called them. Every surface the design puts on obsidian — the stale
   banner, the ready toast, the sent overlay, the active category tab, the
   selected course chip — was still painted from the page palette, so on the
   light theme they came out as pale tinted cards on a bone ground.
2. **Selected states were tints where the design uses fills.** The pattern
   `isActive ? sc.accentSoft : transparent` reads correctly under a palette
   whose accent is mid-luminance. Glow's is fluorescent lime, so a 34% wash of
   it on white reads as a highlighter smear rather than a state.
3. **Cards that paint their own surface never lifted.** `SatBox.d`'s heuristic
   requires a fill before it adds a shadow (ADR-0047 — a hard shadow under a
   borrowed surface would paint the content out). The menu item grid puts its
   colour on a `Material` for the ink ripple, so under a skin whose *only*
   separator is the shadow, every item card sat flat on the page.

## Decision

### Scope: chrome, tables, and the order flow

`tablet_chrome`, `sat_app_bar`, `app_shell`, `tables_screen`, `table_card`,
`reservations_surface`, `ready_toast`, `menu_screen`, `modifier_sheet`,
`sent_screen`. That is the app's core job — get an order from a guest's mouth
into the kitchen — plus the chrome wrapping it.

Admin, KDS, cashier and the void flow are **deliberately left on the
fall-through**. They inherit Glow's palette, radii, lift and type ramp and look
coherent; what they do not get is slab composition. Those surfaces are lower
frequency and higher complexity, and the reconciliation is worth doing as its
own pass rather than smuggled into this one.

### Slab surfaces read `sc.slab`, not a colour

Each of these takes the whole inverted palette and paints from it — background,
text ramp, and semantic hues together:

| surface | Glow renders it as |
| --- | --- |
| `_StaleBanner` (non-crit) | obsidian slab, slab text. `urgent` stays for crit only |
| `ReadyToast` | obsidian slab, lime disc, lime action pill |
| `SentScreen` | full-bleed **lime** slab, obsidian ink |
| active category tab | obsidian slab (lime on `glowNoir`) |
| selected course chip | obsidian slab, and the course dot re-read from `slab` |

The course dot is the case that justifies `slab` being a palette rather than a
colour: the course hues are tuned as ink on the page, and on obsidian they go
muddy. Reading `course.color(sc.slab)` fixes all five at once.

The stale banner is a deliberate departure from the other skins rather than a
translation of them. Brutal and lembut put the warn tier on amber; Glow puts it
on the slab and keeps `urgent` for crit alone. A whole card foot in amber is the
"if everything is urgent, nothing is" failure one step early, and Glow has a
separator — the slab — that the other skins do not.

### Selected states become fills

Zone tabs, category tabs and course chips fill with the accent (or the slab) and
take `accentInk`, rather than stepping up the neutral ramp or tinting. The two
call sites that already read `SatShape.brutal ? accent : textHi` flipped to
`SatShape.lembut ? textHi : accent` — both poster skins want the fill, and
phrasing it as "not lembut" is what stops the next skin inheriting the wrong
default.

### Cards that own their surface lift via `Material`

`elevation` + `shadowColor` on the `Material`, using the same
`SatShape.lift` colour. `SatBox.d`'s fill check stays exactly as ADR-0047 wrote
it — the check is right, this is simply a card the check cannot see.

### Press feedback: coverage, not a new widget

Glow specifies `transform: scale(0.97)` on press. `PressScale` in `anim.dart`
already did precisely that, defaulting to 0.97, already collapsing under reduced
motion. `TableCard` already scaled to 0.97 on press for non-brutal skins.

So no widget was written. The category tab and the course chip — the two
highest-traffic controls in the order flow that had no press feedback at all —
were wrapped. The rest already have either an `InkWell` ripple or an
active-state `AnimatedScale`, and stacking a second scale on those would be
worse than leaving them.

Hover (`translateY(-2px)`) is not ported. These are touch devices.

## Where fidelity was traded

- **The rail avatar keeps the user's colour.** The design fills it with obsidian
  and sets the initials in lime, dropping the per-user hue. The swatch that
  identifies a person has to match wherever else they appear, and the rail is
  where you look to check who is signed in.
- **Modifier check pips keep their shape distinction.** Glow rounds every check
  to a circle. The app draws a rounded square for multi-select and a circle for
  single-select, and that shape is the only thing telling a waiter whether
  picking a second option replaces the first. Same call ADR-0047 made in the
  other direction for status pips.
- **Dialog and sheet shadows are approximate.** Material spreads one `elevation`
  number over three shadow layers, so `0 20px 50px` cannot be expressed exactly.
  The colour is Glow's; the falloff is Material's.
- **Uppercase copy is unchanged.** `SatShape.caps` already returns its argument
  for non-brutal skins, so Glow's sentence case came free — but strings that are
  uppercase *in the source* (`'LAN P50 …MS'`, station names on the sent screen)
  stay that way. They are machine readouts, not prose.

## Consequences

- `sc.slab` now has readers, so the field earns its place. A new obsidian
  surface is `final on = SatShape.glow ? sc.slab : sc;` and then painting from
  `on` throughout — one line, and the dark palettes are a no-op.
- Admin, KDS, cashier and void flow are visibly less finished under Glow than
  the order flow. That is a known, bounded gap, not drift.
- Every change here is skin-conditional. The other five themes render byte for
  byte as before, which is what let this land without a visual regression suite.
