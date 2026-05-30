import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

String formatIDR(num value) => _idr.format(value);

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
