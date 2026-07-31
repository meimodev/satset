import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp. ',
  decimalDigits: 0,
);

String formatIDR(num value) => _idr.format(value);

/// Weekday + day + short month for a service-day header: "Sabtu 27 Jul".
///
/// The booking book leads on this because a drawer that just says "12 booking"
/// is ambiguous the moment service runs past midnight.
final _bookingDay = DateFormat('EEEE d MMM', 'id_ID');

String formatBookingDayId(DateTime d) => _bookingDay.format(d);

/// The wall clock in the tablet top bar: "18:14 · Sab".
///
/// Minute precision on purpose — the seconds a waiter needs are the shift
/// elapsed sitting next to it, and a second-ticking wall clock next to a
/// second-ticking timer reads as two things racing.
/// Hand-rolled rather than `DateFormat('HH:mm · EEE', 'id_ID')`: the bar builds
/// on first frame, and locale data is only loaded once `main` has run. A widget
/// test mounting the bar directly would throw `LocaleDataException`, and seven
/// strings are not worth an init dependency.
const _idShortDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String formatBarClockId(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '$hh:$mm · ${_idShortDays[d.weekday - 1]}';
}

/// A calendar date with no time: "12 Agu 2026". For dates that are a *fact*
/// rather than a moment in service — a billing period's end, a paid-until.
final _shortDate = DateFormat('d MMM yyyy', 'id_ID');

String formatShortDateId(DateTime d) => _shortDate.format(d);

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

/// Indonesian relative label for a count-up duration (table seated, shift, etc).
/// <1m: "20d" · <1h: "12m 20d" · <1d: "1j 12m 20d" · 24-48h: "kemarin" · 2d+: "N hari lalu".
String formatElapsedId(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final days = d.inDays;
  if (days == 1) return 'kemarin';
  if (days >= 2) return '$days hari lalu';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '${h}j ${m}m ${s}d';
  if (m > 0) return '${m}m ${s}d';
  return '${s}d';
}
