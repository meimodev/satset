# ADR-0085 — An audit event is structured, not a sentence

Status: accepted
Date: 2026-08-07

## Context

`writeAudit` (`lib/server/audit_log.dart`) takes a `title` and stores it. Every
call site composes that title as finished Indonesian prose at the moment the
event happens:

```dart
title: 'Pindah meja $srcLabel → $tgtLabel'
title: 'Diskon 10% di Meja ${table.id}'
title: '${t.name} dibatalkan di Meja ${table.id}'
```

The venue audit log (ADR-0072) is the venue's integrity record — voids, comps,
discounts, refunds, order edits — and the screen an owner opens when the numbers
disagree with the drawer. Under ADR-0083 an English-reading owner would find
that every other screen respects their language and this one, the one that
matters most, does not. Worse, the language is frozen per row: the sentence was
built at write time, so no later setting can retranslate history. Ship it as-is
and the log is bilingual from the day it changes, split down the middle by
install date.

The prose column is a problem in its own right, independently of language. A
stored sentence cannot be filtered, grouped or counted. The audit screen already
wants "show me every comp this week" and can only get there by matching
substrings against text a developer wrote by hand in nine places.

`settlement_routes.dart` has the same shape in miniature, storing
`'Bagian ${i}/${n}'` as a split-bill part label.

## Decision

**An audit row stores what happened, not a sentence about it.** Rows gain a
`kind` discriminator and a params JSON blob; the sentence is composed at read
time from the ARB templates, in the reader's locale.

The existing `title` column stays and becomes a fallback. Rows written before
this change have no `kind` and no params, and they render exactly as they always
did — in Indonesian, permanently, because that is genuinely what was recorded.
No backfill, no invented history, no lost rows.

Split-bill part labels get the same treatment for the same reason.

## Consequences

- One Drift migration and roughly nine `writeAudit` call sites, each losing its
  string interpolation and gaining a `kind` plus named params. `writeAudit`
  remains the single writer (`CLAUDE.md` already insists on this, and the reason
  it does — a new column reaching three call sites out of four — applies here
  exactly).
- Around fifteen new ARB templates with ICU placeholders. These are the entries
  most exposed to the glossary rule in ADR-0083: `void`, `comp`, `discount` and
  `move table` must read the same here as on the screens that produce them.
- The audit screen and its export can now filter and group by `kind` rather than
  by substring. That capability is the reason this is worth doing even for a
  venue that never switches to English.
- The log is split by install date: rows before the migration render from
  `title`, rows after from templates. An owner who switches to English sees
  their older history stay Indonesian. This is a deliberate trade against a
  backfill that would have to guess at the structure of sentences already
  written.

## Addendum — the rule generalised

The audit log was the first case, not the only one. The same shape turned up
everywhere a string was composed on one side of a boundary and read on the
other, so the decision now reads: **a code crosses a layer, a sentence never
does.** Applied to:

- **Report payloads.** `reports_routes.dart` composed its KPI tiles, void
  reasons, modifier-group names and station labels as Indonesian on the *host
  tablet* — so a waiter's phone set to English received the kitchen tablet's
  language. Tiles now ship `key` + `args`, void reasons ship `voidReasonCode`,
  and `core/localization/report_copy.dart` renders them for the screen, the PDF
  and the CSV alike. Four hand-copied `reasonLabels` maps collapsed into one.
- **Domain enums.** `Capability`, `TicketStatus`, `ReservationStatus`,
  `UserRole`, `StockReason` and `AlertSoundPreset` each carried a display label
  next to their persisted name. The label is gone; `core/localization/
  labels.dart` resolves the name. The enum name is the join to the ARB entry,
  which makes renaming one exactly as dangerous as renaming an `AuditKind`.
- **Client-thrown errors.** `StaffException` carried a finished sentence, half
  of them in English. It carries a `code` and an optional `arg` now.
- **Server error bodies.** These stay Indonesian on purpose: nothing renders
  them. `ApiException` exposes `statusCode` and `code`, repositories switch on
  the code, and the `message` field is a diagnostic for whoever is reading the
  response by hand.

What is *not* a sentence stays put: station codes on a query string, receipt
label prefixes (`Bagian `), export filename slugs and venue-authored names are
data, and translating them would break a join or rename a venue's own words.
