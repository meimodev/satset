import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:satset/l10n/app_localizations.dart';

// ── Money: pinned to id_ID in every locale. ADR-0084. ────────────────────────
//
// This file is deliberately *half*-pinned, and that asymmetry is the thing to
// not tidy away. Amounts never localise: the cashier is counting physical
// rupiah against the screen, and every other artefact in the room — the printed
// receipt, the bank slip, the notes in the drawer — groups thousands with `.`.
// Rendering `Rp 14,500` next to a stack of cash invites a decimal misread on a
// live till, and `Rp` is not a translation of anything.
//
// Dates below it *do* localise: `Sabtu 27 Jul` inside an English shell just
// reads as an unfinished job, and no money is at risk.

final _idr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp. ',
  decimalDigits: 0,
);

String formatIDR(num value) => _idr.format(value);

/// Weekday + day + short month for a service-day header: "Sabtu 27 Jul",
/// "Saturday 27 Jul".
///
/// The booking book leads on this because a drawer that just says "12 booking"
/// is ambiguous the moment service runs past midnight.
///
/// Built per call rather than held in a top-level `final`: a cached
/// [DateFormat] freezes whichever locale happened to be active when the field
/// was first touched, which for a lazily-initialised top-level is "whenever
/// some unrelated screen ran first". The construction is cheap; a date stuck in
/// the previous language is not.
String formatBookingDayId(DateTime d) => DateFormat('EEEE d MMM').format(d);

/// The wall clock in the tablet top bar: "18:14 · Sab", "18:14 · Sat".
///
/// Minute precision on purpose — the seconds a waiter needs are the shift
/// elapsed sitting next to it, and a second-ticking wall clock next to a
/// second-ticking timer reads as two things racing.
///
/// This used to index a hand-rolled `_idShortDays` array to dodge
/// `LocaleDataException`, because the bar builds on the first frame and a
/// widget test mounting it directly never runs `main()`. Localising dates
/// killed that shortcut — a second English array would have been the same bug
/// twice, and the Indonesian one printed `Sab` inside an English shell. The
/// symbols are now loaded for tests in `test/flutter_test_config.dart`.
String formatBarClockId(DateTime d) => DateFormat('HH:mm · EEE').format(d);

/// When a stale figure was last true: "12 Agu 09:41". Date **and** clock,
/// because a [[Salinan pelanggan]] read at the till is usually hours old rather
/// than days, and "12 Agu" alone would read as fresh at 23:00 (ADR-0129).
String formatStampShort(DateTime d) => DateFormat('d MMM HH:mm').format(d);

/// A calendar date with no time: "12 Agu 2026", "12 Aug 2026". For dates that
/// are a *fact* rather than a moment in service — a billing period's end, a
/// paid-until.
String formatShortDateId(DateTime d) => DateFormat('d MMM yyyy').format(d);

/// Money at a glance, for a report tile or a dense table: "Rp 15,1jt",
/// "Rp 15.1M".
///
/// The one part of a rupiah amount that is *not* exempt from translation
/// (ADR-0084): `jt` and `rb` abbreviate juta and ribu, which are Indonesian
/// words an English reader cannot expand. The digits and the `Rp` stay put.
String formatCompactIDR(AppL10n l10n, int v) {
  if (v >= 1000000) {
    return l10n.moneyCompactJt((v / 1000000).toStringAsFixed(1));
  }
  if (v >= 1000) return l10n.moneyCompactRb('${(v / 1000).round()}');
  return l10n.moneyCompactPlain('$v');
}

/// A bare ISO weekday (1 = Monday) as a short name: "Sen", "Mon". The report
/// trend chart labels its bars with this — the server sends the number.
///
/// 1 Jan 2024 was a Monday, so the day-of-month doubles as the weekday.
String formatWeekdayShort(int dow) =>
    DateFormat.E().format(DateTime(2024, 1, dow));

final _grouping = NumberFormat.decimalPattern('id_ID');

/// Group an integer amount for seeding a rupiah text field: `14500` → `14.500`.
String groupRupiah(int value) => _grouping.format(value);

/// Live thousands-grouping for rupiah text inputs: `14500` → `14.500`.
/// Allows a single leading `-` (modifier price deltas can be negative).
/// Strip non-digits on save — callers already parse with `replaceAll(\D)`.
class RupiahInputFormatter extends TextInputFormatter {
  final bool allowNegative;
  const RupiahInputFormatter({this.allowNegative = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final neg = allowNegative && raw.trimLeft().startsWith('-');
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return TextEditingValue(
        text: neg ? '-' : '',
        selection: TextSelection.collapsed(offset: neg ? 1 : 0),
      );
    }
    final grouped = _grouping.format(int.parse(digits));
    final out = neg ? '-$grouped' : grouped;
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

/// ISO8601 timestamp → 24h clock "17:42". Falls back to the raw string when
/// unparseable (e.g. a legacy "17:30" value already in clock form).
String formatClockId(String iso) {
  final dt = DateTime.tryParse(iso);
  return dt == null ? iso : DateFormat.Hm().format(dt.toLocal());
}

/// Station-clock readout for a count-up duration — "8:42", "12:05", "1:04:18".
/// Deliberately not [formatElapsedId]: on a kitchen ticket the number is read
/// at a glance from 1–2 m and compared against the ticket beside it, so it wants
/// a fixed shape and tabular digits, not the prose form ("8m 42d") the table
/// and shift counters use. Zero-pads everything but the leading unit.
String formatStationTimer(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

/// Relative label for a count-up duration (table seated, shift, etc).
/// <1m: "20d" · <1h: "12m 20d" · <1d: "1j 12m 20d" · 24-48h: "kemarin" · 2d+: "N hari lalu".
///
/// Was `formatElapsedId` and Indonesian-only; the unit letters are copy, and
/// they collide across languages (Indonesian `d` is *detik*, English `d` is
/// *day*), so a shared string would have been wrong in one of them.
String formatElapsed(AppL10n l10n, Duration d) {
  if (d.isNegative) d = Duration.zero;
  final days = d.inDays;
  if (days == 1) return l10n.elapsedYesterday;
  if (days >= 2) return l10n.elapsedDaysAgo(days);
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return l10n.durHms(h, m, s);
  if (m > 0) return l10n.durMs(m, s);
  return l10n.durSecs(s);
}
