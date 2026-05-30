import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

String formatIDR(num value) => _idr.format(value);

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
      TextEditingValue oldValue, TextEditingValue newValue) {
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
