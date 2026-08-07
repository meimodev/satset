# ADR-0083 — The language is a device choice that never follows the system

Status: accepted
Date: 2026-08-07

## Context

SatSet has shipped Indonesian-only since the first commit. The copy lives in
`lib/core/localization/app_strings.dart` — 314 static strings and 27
interpolating functions, referenced from 53 files — with roughly 138 further
literals still hardcoded in widgets despite the standing rule against it.

English is now needed. The question is not whether, but *what a locale is
attached to*. Three things could own one, and they answer differently when a
phone changes hands mid-shift:

| owner | who it follows | what a shared phone does at handover |
| --- | --- | --- |
| the device | whoever last set it | keeps the last waiter's language |
| the staff account | the person | reverts at PIN sign-in |
| the venue | the owner, server-side | ignores both |

There is a fourth candidate that costs nothing to implement — follow the
Android system locale — and it is the one that fails hardest here. The cheap
tablets a small Indonesian venue actually buys ship with system locale `en_US`
and are never changed, because nothing on them depends on it. An app that
followed the system would boot an Indonesian warung's till into English on
first run. That is a worse first five minutes than any setting could be.

A second boundary needed drawing: what "the app's language" covers. Staff-facing
chrome obviously. But the venue's own content — menu item names, category names,
zone names, guest notes, the seeded `Tidak pedas` modifier option — is text the
owner typed, in the language they chose, for a menu their guests read. Nothing
translates that, and offering to would mean a second name column on four
entities and an admin editor that asks for everything twice.

## Decision

**One locale, owned by the device, defaulting to Indonesian without consulting
the system.**

- The locale is a single `prefs` key, sitting beside `setThemeKey`
  (`prefs_service.dart`) and behaving exactly like it: per-device, survives
  sign-out, unaffected by which staff member is on shift.
- The default is a hard `Locale('id')`. No `localeResolutionCallback`, no
  platform sniffing. A fresh install is Indonesian in Jakarta and Indonesian in
  Berlin.
- It is switched from `/me`, in a sheet modelled on `theme_sheet.dart`. `/me` is
  a shell tab open to every role, so a waiter can change their own phone without
  the `editSettings` capability that gates `/settings`.
- Everything printed or exported from a device uses that device's locale. There
  is no separate receipt locale and no venue-wide override.

**Scope is the app and what it generates, not what the venue authored.** In:
all UI copy, ESC/POS receipts and kitchen tickets (`lib/core/printing/`), and
the four CSV exporters in `lib/core/export/`. Out: menu items, categories,
modifier options, zone and table labels, guest and item notes, seed content.

Storage is `flutter_localizations` with `l10n.yaml` and gen-l10n over
`app_id.arb` / `app_en.arb`. ARB keys keep the existing `AppStrings` identifier
names verbatim, so the migration is a mechanical `AppStrings.foo` → `l10n.foo`
and deleting `app_strings.dart` turns the analyzer into the completeness check.
Code with no `BuildContext` — the exporters, `auth_error.dart`, `format.dart` —
reaches the strings through a Riverpod provider wrapping
`lookupAppLocalizations(locale)`.

The English wording of any domain term is owned by `CONTEXT.md`, not by whoever
writes the ARB entry. See its `## Terms` section, where each entry now carries
both sides.

## Consequences

- A shared phone keeps the previous waiter's language until someone changes it.
  This is precisely how `themeKey` already behaves and has never been raised as
  a problem; matching it costs no new concept. A staff member who wants their
  own language on someone else's phone is not a case this handles.
- Adding `flutter_localizations` fixes a bug that predates this work: Material's
  own widgets — date pickers, the text-selection `Cut/Copy/Paste` menu — have
  been rendering in English inside an Indonesian app because no delegate was
  ever registered.
- No Drift migration and no server field for the setting itself. The locale
  never crosses the wire.
- The 66 golden PNGs in `test/control_golden_test.dart` use zero `AppStrings` —
  every label is a literal stub inside the test — so nothing regenerates, and
  no golden is added for English. The overflow safety net is instead a locale
  toggle in the widget book (`lib/ui/features/_book/`, ADR-0054), beside the
  existing theme, text-scale, reduced-motion and phone/tablet toggles.
- Two tests hold the line. An ARB key-set parity test, because gen-l10n only
  *warns* when a key is missing from one file, and that warning is how a
  half-translated release ships. And a literal ban in `lib/ui`, written in the
  `design_tokens_test.dart` mould — all bans, no baselines — with a small
  explicit allowlist for the `Text('$count')` cases that are data, not copy.
  The 138 existing strays are the evidence that the rule in `CLAUDE.md` was
  never enough on its own.
- Money is deliberately exempt from all of this. See ADR-0084.
