# ADR-0045 — Device-local theme selection

## Status

Accepted.

## Context

The app shipped one palette family (`SatColors.dark` / `SatColors.light`) behind a
binary `ThemeMode` toggle in the Me screen. Two problems:

1. The choice was never persisted. `themeModeProvider` defaulted to
   `ThemeMode.dark` and restart discarded whatever the user picked.
2. `ThemeMode.system` was reachable in the type but never produced — the toggle
   only ever wrote `dark` or `light`. OS-follow was a slot, not a feature.

We want more than one look, and venues run rooms with very different light:
a dim dining floor, a bright hot line, a daylight terrace.

## Decision

### Themes are a flat list, not palette × brightness

A theme is a whole look. `enum SatTheme` enumerates four of them, each carrying
its own id, label, `Brightness`, and `SatColors`:

| enum            | label         | brightness | palette                          |
| --------------- | ------------- | ---------- | -------------------------------- |
| `amberGelap`    | Amber Gelap   | dark       | existing `SatColors.dark`        |
| `amberTerang`   | Amber Terang  | light      | existing `SatColors.light`       |
| `neonHijau`     | Neon Hijau    | dark       | new — black + light neon green   |
| `indigoTerang`  | Indigo Terang | light      | new — cool paper + indigo        |

`amberGelap` is the default, so existing devices keep exactly the look they had.

The rejected alternative was orthogonal axes — pick a palette, then pick
light/dark independently. It forces every palette to have both a light and a
dark variant, and "black + neon green" has no honest light variant. Six palettes
to author and audit instead of four, for a feature whose point is "pick a look".

### `ThemeMode` is removed

`app.dart` sets `theme:` only. No `darkTheme`, no `themeMode`, no OS-follow.
Brightness is a property of the selected `SatTheme`. Nothing is lost: OS-follow
was never reachable. Staff pick by room lighting on venue-owned shared hardware,
not by the phone's system setting.

There is no migration. The previous choice was never written to disk.

### Identity lives on the enum, not on `SatColors`

`SatColors` stays a pure token bag. It does not gain `label` or `brightness`
fields — `Brightness` does not interpolate, so putting it on a `ThemeExtension`
forces a `t < 0.5` snap inside `lerp` and makes the extension's contract lie.
The enum is needed anyway: prefs needs a stable serialisable id, and the picker
needs a list of *choices*, not a list of palettes.

### Selection is device-local

Stored in `PrefsService` under `satset.theme`, alongside the other device-local
preferences (audio alert, muted cues, printers).

Not per-user: shared hardware would re-theme on every shift change, which is the
opposite of the muscle memory the app is built for. Not per-venue: the hot line
tablet and the terrace phone genuinely want different palettes at the same
moment. Both alternatives also cost a schema migration and a route for a
cosmetic preference.

The picker is a bottom sheet from the existing Me-screen affordance — *not* a
row in `/settings`, which is gated on `editSettings`. Every waiter must be able
to set this on their own handset.

### Semantic tokens are retuned per palette, narrowly

Colour is signal (see `CLAUDE.md` § Design Principles). An accent is a seventh
hue in a room that already has six meaningful ones, and two of the four themes
collide:

- `neonHijau`: neon-green accent vs `success` (green).
- `indigoTerang`: indigo accent vs `info` (blue).

Only the colliding token moves, and only in the palette where it collides —
`neonHijau.success` darkens to a deep emerald so neon owns "bright green";
`indigoTerang.info` shifts to cyan. Every other semantic hue is byte-identical
across all four themes, so the learned vocabulary survives a theme change.

The alternatives were to let the collision stand and lean on design principle 3
(state always paired with icon/text) — but two greens at 1–2 m on a KDS is
exactly where that principle is most likely to fail — or to alias the colliding
semantic onto the accent, which is the same cost without the benefit.

### Hardcoded colours are routed through tokens

Twelve sites outside `lib/ui/core/design/` baked colours in, and `SatColors`
grows by two fields (31 → 33) to absorb them:

- **`successInk`.** Six sites wrote `Color(0xFF0A0A0A)` as ink on a filled
  surface. All six sit on `success`, not on `accent` — so `accentInk` would have
  been wrong (it is white in `indigoTerang`). Every shipped palette's `success`
  still takes near-black ink, but the token forces a future palette with a dark
  `success` to declare white rather than silently ship unreadable badges.
- **`scrim`.** Four translucent-overlay values picked a surface by branching on
  `Theme.of(context).brightness`, which no longer distinguishes the two dark or
  the two light themes. The token names the surface an overlay tints from; call
  sites keep applying their own alpha, so existing opacities are unchanged.

`ready_toast`'s fixed green gradient is now blended from the palette's own
`success`, since a baked-in emerald fights the accent under `neonHijau`.

The scrims were already wrong under both existing palettes — just invisibly so
while there was only one palette family.

`receipt_preview` and `pdf_theme.dart` stay theme-independent on purpose — they
simulate thermal paper and render the Heritage export palette (ADR-0030). The
guest SPA (`guest_app_html.dart`, ADR-0029) likewise keeps its own Heritage
CSS: it is server-rendered to a stranger's browser and has no access to, or
business with, a staff device's local preference.

## Consequences

- Adding a fifth theme is one enum member, one `SatColors` literal, one label.
- `flutter analyze` catches every missed `themeMode` reference at compile time.
- A contrast test asserts `textHi`/`bg0`, `textMd`/`bg1`, `accentInk`/`accent`
  and `successInk`/`success` clear WCAG 4.5:1 in all four themes, so an
  illegible palette fails loudly.
- `PrefsService` stores an opaque key string, not a `SatTheme` — `data/` must
  not import `ui/`, and resolving the key is the UI layer's job.
- The selection seeds from `SharedPreferences`, which resolves asynchronously.
  A device that has chosen a non-default theme can show one frame of
  `amberGelap` on cold start.
- **Known debt, deliberately not fixed here:** the semantic hues were tuned for a
  charcoal background and are reused verbatim in both light themes, where they
  are decorative rather than accessible — `success #4DD487` on light `bg0` is
  ~1.6:1. The contrast test therefore asserts text-bearing pairs only. Fixing
  light-mode semantic contrast means retuning shipped colours across 46 call
  sites and belongs in its own change.
- The Q4 retunes are hue-separation, not contrast, so the test does not cover
  them. They are verified by eye on device.
