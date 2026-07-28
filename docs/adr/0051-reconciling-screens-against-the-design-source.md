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

## Amendment — `SatChip.select` fills with the accent, not the slab

"Selected states become fills" above says zone tabs, category tabs and course
chips fill "with the accent (or the slab)". The parenthesis was doing too much
work. `SatChip.select` read it as *the slab*, and shipped every selected chip in
the app on obsidian.

The source design is not ambiguous. `glow.css` groups the segment and zone
controls together on the accent:

```css
[data-skin="glow"] .zone-tab.active,
[data-skin="glow"] .tab-zone-btn.active,
[data-skin="glow"] .tab-seg.active { background: var(--lime); color: var(--obsidian); }
```

and reserves the obsidian slab for one control only:

```css
[data-skin="glow"] .cat-tab.active { background: var(--obsidian); color: #FFFFFF; }
```

The symptom was two controls the design styles identically rendering
differently: the Meja zone row hand-rolls its chip and painted `sc.accent`,
while the reservation filters went through `SatChip.select` and came out
obsidian.

**So: `SatChip.select` fills with `sc.accent` and takes `sc.accentInk` when
selected under Glow.** The border collapses into the fill — Glow draws no rules,
and the fill is already carrying the state. The obsidian slab stays where the
design put it: the active menu category tab, which does not go through
`SatChip`.

This changes every filter row in the app — the KDS completed filter, the admin
filters, the reservation filters — which is the point. They were the drift.

### `SatTabs` too

The first cut of this amendment named the Pesanan segments as one of the rows it
fixed. That was wrong: the Pesanan scope switch is a `SatTabs`, not a
`SatChip.select`, so it kept its obsidian fill and became the new odd one out —
sitting on the same screen as a lime zone strip and a lime filter row, marking
the same kind of state a different colour. Verified on device: Meja's zone strip
and the reservation filters rendered lime while `Siap diambil` rendered black.

`.tab-seg` in the rule above *is* the segmented strip. It was quoted as evidence
here and then not applied. So `SatTabs` takes the same treatment: under Glow a
selected tab fills `sc.accent` and inks `sc.accentInk`. The badge follows the
label onto the fill rather than staying on `textLo`, which would leave a mid-grey
number on lime.

The black pill actually on screen turned out not to be either widget. Pesanan's
tablet bucket strip was `_TabletSeg`, a private lookalike of `SatChip.select`
that hardcoded `sc.textHi` as its fill and knew nothing about skins — so it
stayed obsidian no matter what the shared controls did. It is deleted; the strip
is a `SatChip.select` row like its phone counterpart.

Worth flagging: `design_tokens_test.dart`'s "no private lookalikes of a shared
control" ban did not catch `_TabletSeg`, and it was never allow-listed. The ban
misses a lookalike that reaches for the neutral ramp instead of a semantic token.

Non-Glow skins are untouched on both widgets — `bg3`/`bg4` and `textHi` as
before.

`sc.slab` keeps its other five readers from the table above, so the field still
earns its place.

## Amendment — the KDS ticket card

§Scope above left "admin, KDS, cashier and the void flow" on the fall-through
and said the reconciliation was "worth doing as its own pass". This is that
pass, for the one card on that list that matters most: the kitchen ticket.

### Composition lands on every skin; only the paint is Glow's

The earlier amendments were entirely skin-conditional, which is what let them
ship without a visual regression suite. This one is not, and deliberately. The
source's head carries things the app's head simply did not have — the course,
a TELAT tag, the arrival clock — and those are facts a cook needs under an
amber palette exactly as much as under a lime one. Withholding them from five
palettes to keep the diff conditional would be conditional formatting standing
in for a decision.

So: **composition everywhere, paint gated.** The head is a `bg3` band with a
hairline under the neutral skins and an obsidian `sc.slab` under Glow — which
is the source's own split, `rgba(0,0,0,0.25)` in the base CSS and
`background: var(--obsidian)` in `glow.css`.

Worth recording, because it was the stated reason for choosing this over the
conditional route and it did not hold: the golden matrix did **not** move. It
covers `core/widgets` in the two amber themes, and the kitchen screen is not in
it. This work is still invisible to CI. Device verification remains the only
check that sees it.

### What the head became

`[table] [course ×n] [TELAT] → [timer / masuk hh:mm]`

- The table id is a numeral at `h3`, not a `bg3` chip. It is the first thing
  read and the source sets it at 22px/800.
- One course pill per distinct course in the group, flat `accent`, filled. The
  source's ticket *is* a course, so its pill always has one honest value; the
  app groups by send, and a waiter who fires drinks and mains together makes a
  card that carries both. Naming them is information the cook did not get.
  Never the per-course hue — those are tuned as ink on the page, and five of
  them stacked on obsidian is the same muddiness the course dot hit above.
- `_AgePill` is deleted. The timer is bare stacked numerals, `masuk 18:05`
  beneath, and its ink runs **neutral → warn → urgent** rather than
  **success → warn → urgent**. Glow paints the calm case `accent`, because
  `textMd` on an obsidian slab is a mutter — that is the one place the source's
  lime survives. Losing green-for-fine is the point: a ticket two minutes old is
  not news, and spending a colour on the good case is how `urgent` stops being
  read.
- `PulseDot` gives way to a 1.4s opacity pulse on the numerals themselves, per
  the source. Reduced motion collapses to full opacity, still red — the colour
  is the signal, the pulse only makes it findable.

### Tiers, and where the thresholds came from

The warn tier moves from 5 to **7 minutes**, which is the source's
`LATE_MIN × 0.7`. Late stays at 10. Under Glow each tier is a hard ring —
`BoxShadow(spreadRadius: n, blurRadius: 0)` over `SatShape.lift`, the shape
`TableCard` already gives a crit table — because Glow draws no rules and a
fatter border is not available to it. The other skins get border colour and
width, as before.

Late also tints the whole card `urgentSoft`. The source has a dedicated
`lateTint`; `urgentSoft` is the app's existing token for the same job and the
reservation late row already made that substitution.

The source's `is-done` card state and its SELESAI tag are **not** ported. Done
cards sit behind a filter and are not what the screen is for.

### The item row, and two shared controls

Rows take the source's 3px left bar (`accent` while it is work, `success` once
it is not), a 26px tick moved to the left, and the qty inline as `×2` before
the name rather than as a chip. Row height stays at **60**, not the source's
44: this screen is wall-mounted and read at 1–2 m, and 44 is a phone number.

Two shared controls gained an axis rather than being forked — the `_TabletSeg`
lesson from the amendment above:

- **`SatChip.tag(filled: true)`** fills the hue and inks via `inkOn`. The source
  separates a chosen option (`bg3`, muted) from a paid add-on (solid lime): one
  changes how the dish is made, the other puts something extra on the plate. The
  first cut of this ADR argued the accent *tint* was close enough. It is not —
  at the same volume as the option beside it, the extra is the one that gets
  forgotten. `neutral` ignores the flag; its tint is already flat `bg3`.
- **`NoteLine(alert: true)`** renders the note as a filled `urgentSoft` block
  with `textHi` ink. This contradicts that widget's own doc comment — "reference
  text the staff jotted down, **not** an alert" — and the comment now carries
  the exception and its reason. The same string is two things: at the table
  "Alergi kacang" is a jotting, at the pass it decides whether the plate goes
  out or into the bin. The note also stays at full opacity when the item is
  ticked off, per the source, because it is still true afterwards.

### Where fidelity was traded

- **The progress bar stays.** The source has only a footed `3 / 4 siap` line at
  11px. Both ship: the words for the cook standing at the card, the bar for
  anyone reading it from across the room, where 11px is not a size.
- **Tap does not toggle.** The source's item is a tap-to-toggle button. The app
  keeps tap-hints-and-long-press-commits — an accidental brush must not advance
  a ticket on a line — so the tick is an indicator, not a control, and only its
  position was taken.
- **`formatStationTimer` is new** rather than reusing `formatElapsedId`. A
  ticket timer is compared against the ticket beside it, so it wants `8:42` and
  a fixed shape, not the prose `8m 42d` the table and shift counters use.
