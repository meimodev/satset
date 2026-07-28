# ADR-0057 — Neon Terang is the shipped default

## Status

Accepted. Amends ADR-0045 (which made `amberGelap` the default so that upgrades
were a visual no-op) and ADR-0050 (whose consequences state "`SatTheme.fallback`
stays `amberGelap`"). The device-local, cosmetic, `.name`-keyed nature of the
setting is unchanged; only which theme sits behind it, and who gets moved.

## Context

ADR-0045 chose `amberGelap` for a reason that has expired. It was the palette
the app already shipped, so making it the fallback meant nobody's screen changed
under them. That argument is about continuity, not about which look is right.

Seven themes now ship across three skins. Glow (ADR-0050) landed as a complete
design with its own shape language, type ramp and press feedback — it is the
most recently authored look in the repo and the one the design source actually
specifies. `neonTerang` is its light half.

Two things made it the candidate rather than `neonGelap`:

- Its semantic hues are authored as ink on white — `success #146B33`,
  `warn #8A5A00`, `urgent #A31D0C`, `info #4F46E5`. Every other light palette in
  the roster reuses hues tuned for a charcoal ground, which is the known debt
  ADR-0045 recorded and did not fix. Neon Terang does not carry it.
- Glow's own grammar is bone-first: obsidian is the *slab*, the accent block, not
  the ground.

Against it stands this file's own §Aesthetic Direction — "restaurants run dim,
so dark is the real default and light is the exception."

## Decision

### `SatTheme.fallback` becomes `neonTerang`

One constant. `CLAUDE.md` §Aesthetic Direction is amended in the same change
rather than left contradicting the code: neither brightness is now "the
exception", and a dark theme remains one tap away in the picker for the dim
floor and the hot line. The doctrine was a claim about defaults, and the default
moved.

**§Brand Personality is deliberately left alone.** "Amber `#FF9233` on charcoal
is the whole thesis" is a statement about brand identity, and a default is not a
thesis. Seven themes ship, staff re-theme per room, and no single palette is
what a guest ever sees. Glow becoming the boot look does not settle whether it
became the design language; that is a separate decision with a separate cost.

### The prefs key is bumped, so the swap reaches existing devices

`satset.theme` → `satset.theme.v2`. A device carrying the old key finds nothing
under the new one, and `fromKey(null)` already means "take the fallback" — so
the one-time reset is free: no boot-time write, no migration flag to keep alive,
and no race against the async `SharedPreferences` load that `SatThemeNotifier`
seeds from.

This is the point where ADR-0045's promise is knowingly withdrawn. A fallback
change alone would only reach fresh installs; every device that had ever opened
the theme sheet — which is every device in service — would keep amber, and the
change would ship as a no-op on exactly the hardware it is meant for. A forced
one-time re-theme is the cost of the decision, not an accident of it.

A migration flag was the alternative. It buys the ability to know whether a
given device was migrated, which nothing needs for a cosmetic device-local
preference, and costs a boot write plus a flag that lives forever. A future
forced re-theme is another key bump, which reads as its own audit trail.

### Goldens swap to one theme per skin

`control_golden_test` moves from `[amberGelap, amberTerang]` to
`[neonTerang, amberGelap]`. Same 56 files. The old pair locked `lembut` twice
and nothing else, which was defensible when `lembut` was the only skin and is
not now that shape — radii, borders, shadows, type — is a skin property
(ADR-0047, ADR-0050). `brutal` stays uncovered, as before.

The contrast test's fallback assertions now name `neonTerang` instead of
`SatTheme.fallback`, which could not fail against itself.

## Consequences

- **Every device in service re-themes once, to a light palette, on first launch
  after upgrade.** Rooms that need dark re-pick `Neon Gelap` and it sticks.
  Staff on shift will notice; this is the intended, visible effect.
- The old `satset.theme` value stays orphaned in `SharedPreferences`. It is not
  read again and is not cleaned up — a string per device, against the cost of
  owning migration code.
- The 56 golden PNGs are regenerated. They remain font-renderer specific and
  pinned to whichever machine produced them, unchanged from before.
- `SatTheme.fallback`'s docstring no longer promises a visually silent upgrade.
  Anything relying on that promise elsewhere would have to say so.
- Picker order is untouched: the default sits fourth in its own list, behind the
  amber pair and `Neon Gelap`. Grouping by palette pair was judged worth more
  than pole position for the default.
