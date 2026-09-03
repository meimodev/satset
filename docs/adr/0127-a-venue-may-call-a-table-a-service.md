# ADR-0127 — A venue may call a table a service, and the word is a locale

Status: accepted
Date: 2026-09-03

## Context

SatSet's floor vocabulary is a restaurant's: `Meja` · `Table`, ~120 strings of
it, from the nav tab through the audit log to the printed struk. A venue that
sells *service* rather than seats — a salon, a barbershop, a klinik, a spa —
has the same physical grid of numbered spots and the same jobs on it (seat,
order, move, release, settle), but calls it something else. Every one of them
would today read "Meja 7" on a chair.

The concept is not different. Zones, capacity, the [[Table lock]], `Pindah
meja`, the [[Visit]] and the [[Bill (tab)]] all mean exactly what they mean at
a restaurant. What differs is one noun.

Three ways to say a different noun were open:

1. **A placeholder** — parameterise the noun in the ARB and pass it at every
   call site. 120+ call sites, and the grammar still breaks the moment the noun
   is venue-authored ("Ruang Perawatan Lantai 2").
2. **Duplicate keys** — a `…Svc` twin per string plus a resolver at each call
   site. Same 120 branches, and a screen that forgets one silently renders the
   restaurant word.
3. **Runtime substitution** at the `context.l10n` boundary. Not possible:
   `noSuchMethod` cannot forward a getter to a concrete delegate and
   `dart:mirrors` does not exist under AOT.

## Decision

**A fourth [[Modul|mode key]], `serviceTerm`, and the word is resolved the way
every other word already is — by picking a locale.**

`Locale('id', 'SV')` and `Locale('en', 'SV')` resolve to `app_id_SV.arb` and
`app_en_SV.arb`, which **override only the ~120 strings that name a table** and
inherit the other ~3900. `flutter gen-l10n` emits `AppL10nIdSv extends
AppL10nId` for free; there is no second generator and no branch at a call site.

- **`SV` is not a country.** It borrows the region slot as a variant marker.
  This is safe here precisely because SatSet never resolves a locale from the
  platform (ADR-0083): the language half is chosen on `/me`, and this half is
  chosen by the venue.
- **Read in exactly one place.** `SatLocaleNotifier` folds the key into the
  locale; `MaterialApp.locale`, the process-wide `satL10n`, the ESC/POS
  renderers and the CSV/PDF exporters all follow with no code of their own. A
  screen that asks about `serviceTerm` for itself is a review finding — that is
  a copy branch, and copy lives in the ARB.
- **A mode key, so it fails closed** (`venueHasMode`, ADR-0109). The fail-open
  that protects a paid [[Modul]] would rename the floor at every restaurant
  that has not mirrored yet. A salon waiting one sign-in for its vocabulary is
  a smaller harm than a cafe waking up as a salon.
- **Independent of [[Kedai (counter mode)|Kedai]] mode**, for the reason
  ADR-0115 gives for `bypassKds`: a salon is not a counter shop, and a kedai
  still has meja.
- **It gates nothing and branches no writer.** The floor, zones, capacity,
  locks and moves stay exactly as they were, still written, still legal — this
  is ADR-0109 §6's "hides, never refuses" taken one step further: it does not
  even hide. Unticking the key finds the venue as it left it, because nothing
  about the data ever changed.

**The service *charge* is renamed unconditionally.** `Layanan` / `Service` was
already the 10% charge — on the settle row, the tax settings and the printed
struk. Leaving it would put `Layanan 7 · … · Layanan 10%` on one receipt. It
becomes **`Biaya layanan` · `Service charge`** for *every* venue, in both
modes: better copy anyway, one pass, and one meaning per word on a money
document regardless of which mode a venue is in.

**The guest page picks its own noun**, from a `serviceTerm` flag on
`/guest/venue` — the same shape the counter branch beside it already uses. Its
other three table mentions were reworded to name a *code* rather than a table,
which is more accurate anyway and needs no flag: they render before `venue` has
loaded, or because it failed to.

## Consequences

- **Inheritance means silent drift.** A new "Meja" string added to the template
  and forgotten in the variant renders the restaurant word at a salon, and
  nothing at runtime says so. `test/arb_parity_test.dart` fails instead: every
  template value matching `\bmeja\b` (ICU spans masked, so the placeholder named
  `table` is never read as the word) must have an override, no override may
  invent a key or keep the base word, and placeholders and plural shape must
  match the base.
- **A locale is now two decisions.** The picker on `/me` compares
  `languageCode`, never the whole `Locale` — an exact comparison silently
  stopped highlighting the active row.
- **~15 strings are rewritten, not substituted.** "Mulai layani meja" is not
  "Mulai layani layanan", and EN "NO TABLE" is not "NO SERVICE" (which reads as
  *service unavailable*) — it is "UNASSIGNED".
- **A fleet toggle lands when the settings mirror does**, not on the next cold
  boot: `satLocaleProvider` watches `venueSettingsProvider`, and because
  `VenueSettingsRepository` paints its cached shape before its fetch (ADR-0115),
  a handset booting away from its host still opens in the right words.
- **Venue-authored data is untouched.** Zone names and table labels are the
  owner's rows and stay theirs to rename.
