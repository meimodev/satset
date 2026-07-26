import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:satset/data/repositories/reports_repository.dart'
    show kCustomRangeMaxDays;
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

/// Hand-rolled bottom sheet for the Reports "Custom" timeline chip. Picks an
/// inclusive start/end **calendar date** (date-only; the server snaps each to
/// the business-day boundary). Commits only on "Terapkan" and returns the
/// `(from, to)` pair; a dismiss returns null and leaves the active range as-is.
///
/// The sheet shell is bespoke (matching the Reports design language) but the
/// per-field calendar delegates to the framework `showDatePicker`.
Future<(DateTime, DateTime)?> showCustomRangeSheet(
  BuildContext context, {
  DateTime? initialFrom,
  DateTime? initialTo,
}) {
  final sc = context.sat;
  return showModalBottomSheet<(DateTime, DateTime)>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: sc.bg1,
    builder: (_) => _CustomRangeSheet(
      initialFrom: initialFrom,
      initialTo: initialTo,
    ),
  );
}

class _CustomRangeSheet extends StatefulWidget {
  const _CustomRangeSheet({this.initialFrom, this.initialTo});

  final DateTime? initialFrom;
  final DateTime? initialTo;

  @override
  State<_CustomRangeSheet> createState() => _CustomRangeSheetState();
}

class _CustomRangeSheetState extends State<_CustomRangeSheet> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom == null ? null : _dateOnly(widget.initialFrom!);
    _to = widget.initialTo == null ? null : _dateOnly(widget.initialTo!);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Inclusive span in days between two date-only values.
  int get _spanDays =>
      _from == null || _to == null ? 0 : _to!.difference(_from!).inDays + 1;

  bool get _orderOk => _from != null && _to != null && !_to!.isBefore(_from!);
  bool get _spanOk => _spanDays <= kCustomRangeMaxDays;
  bool get _valid => _from != null && _to != null && _orderOk && _spanOk;

  String? get _error {
    if (_from == null || _to == null) return null;
    if (!_orderOk) return 'Tanggal mulai harus sebelum tanggal selesai.';
    if (!_spanOk) return 'Rentang maksimal $kCustomRangeMaxDays hari.';
    return null;
  }

  Future<void> _pick(bool isStart) async {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final first = DateTime(now.year - 3);
    final initial = (isStart ? _from : _to) ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: first,
      lastDate: today,
      helpText: isStart ? 'Tanggal mulai' : 'Tanggal selesai',
    );
    if (picked == null) return;
    setState(() {
      final d = _dateOnly(picked);
      if (isStart) {
        _from = d;
        // Keep order sane: an end before the new start is cleared.
        if (_to != null && _to!.isBefore(d)) _to = null;
      } else {
        _to = d;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final err = _error;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RENTANG KHUSUS',
              style: SatType.mono(
                size: 11,
                weight: FontWeight.w600,
                letterSpacing: 1.0,
                color: sc.textLo,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _field(context, 'Mulai', _from, () => _pick(true))),
                const SizedBox(width: 12),
                Expanded(child: _field(context, 'Selesai', _to, () => _pick(false))),
              ],
            ),
            if (err != null) ...[
              const SizedBox(height: 12),
              Text(err, style: SatType.sans(size: 12, color: sc.urgent)),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: _applyButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
      BuildContext context, String label, DateTime? value, VoidCallback onTap) {
    final sc = context.sat;
    final set = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: SatBox.d(
          color: set ? sc.accentSoft : sc.bg2,
          border: SatB.all(color: set ? sc.accentBorder : sc.border0),
          borderRadius: SatR.a(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: SatType.mono(
                  size: 9,
                  weight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: sc.textLo,
                )),
            const SizedBox(height: 2),
            Text(set ? _fmt(value) : 'Pilih',
                style: SatType.sans(
                  size: 14,
                  weight: FontWeight.w500,
                  color: set ? sc.accentText : sc.textLo,
                )),
          ],
        ),
      ),
    );
  }

  Widget _applyButton(BuildContext context) {
    final sc = context.sat;
    return GestureDetector(
      onTap: _valid ? () => Navigator.of(context).pop((_from!, _to!)) : null,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: SatBox.d(
          color: _valid ? sc.accent : sc.bg3,
          borderRadius: SatR.a(14),
        ),
        child: Text('Terapkan',
            style: SatType.sans(
              size: 15,
              weight: FontWeight.w700,
              color: _valid ? sc.accentInk : sc.textLo,
            )),
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
}
