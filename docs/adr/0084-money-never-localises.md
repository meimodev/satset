# ADR-0084 — Money never localises

Status: accepted
Date: 2026-08-07

## Context

`lib/ui/core/design/format.dart` pins every number and date it formats to
`id_ID`:

```dart
final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
final _grouping = NumberFormat.decimalPattern('id_ID');
final _bookingDay = DateFormat('EEEE d MMM', 'id_ID');
final _shortDate = DateFormat('d MMM yyyy', 'id_ID');
```

Until ADR-0083 that was not a choice, because there was one locale. With English
in the app it becomes one, and the obvious move — thread the active locale
through — is wrong for exactly one of these.

Indonesian groups thousands with `.`; English with `,`. A bill of 14 500 rupiah
is `Rp 14.500` in one and `Rp 14,500` in the other. The cashier reading that
number is holding the physical notes and counting them against the screen. Every
other artefact within reach of the till — the printed receipt, the bank transfer
slip photographed as proof (ADR-0025), the denominations in the drawer — uses
the Indonesian convention, because they were produced by Indonesian banks and
Indonesian printers, not by SatSet. An English UI that renders `Rp 14,500` puts
a comma where the room puts a period, on the one screen where a misread costs
real money.

The currency is not locale-dependent in the first place. The venue trades in
rupiah whatever language its owner reads. `Rp` is not a translation of anything.

Dates carry no such risk. `Sabtu 27 Jul` inside an otherwise English shell just
reads as an unfinished job.

## Decision

**Amounts stay `id_ID` in both locales; dates and weekdays follow the active
locale.**

Pinned forever, in English and Indonesian alike:

- `formatIDR` — the `Rp. ` currency format
- `groupRupiah` and the live thousands-grouping input mask
- the amount columns of the ESC/POS receipt renderers and the CSV exporters

Localised:

- `formatBookingDayId`, `formatShortDateId` and the weekday/month names behind
  them
- date columns in exports and on receipts

`format.dart` is therefore *deliberately half-pinned*. That asymmetry is the
whole point of this record: it looks like an oversight, it is not one, and this
ADR exists so the next reader does not tidy it away.

## Consequences

- The rupiah `TextInputFormatter` needs no locale branch, which keeps the one
  piece of formatting code that runs on every keystroke free of a lookup.
- Because dates now localise, the hand-rolled `_idShortDays` and
  `_idShortMonths` arrays can no longer stand. They exist to dodge
  `LocaleDataException` — `formatBarClockId` and the shell banners build on the
  first frame, before `main` has loaded locale data, and a widget test mounting
  one directly would throw. Swapping in a second pair of English arrays would
  reproduce the hack twice over and still print `Sab` in an English shell. The
  load-order problem has to be solved properly: locale data initialised before
  the first frame, and the safe variants retired.
- An English-reading owner sees `Rp 14.500` and a date they can read. That
  mixture is intended and should not be reported as a bug.
- Adding a third locale later changes nothing here. Amounts are already outside
  the locale system.
