import 'package:flutter/material.dart';

import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';

/// Indonesian notes, largest first. Rp 1.000 is the floor — below that the
/// cashier is handling coins, and coins are not counted onto a pad.
const _notes = [100000, 50000, 20000, 10000, 5000, 2000, 1000];
const _noteLabels = {
  100000: '100rb',
  50000: '50rb',
  20000: '20rb',
  10000: '10rb',
  5000: '5rb',
  2000: '2rb',
  1000: '1rb',
};

/// What the guest is likely to actually hand over: the exact amount, then
/// note-friendly round-ups. Capped at four — a row of options the cashier has
/// to read is slower than the pad it was meant to shortcut.
List<int> quickTenders(int due) {
  if (due <= 0) return const [];
  final out = <int>{due};
  for (final step in [1000, 5000, 10000, 50000, 100000]) {
    final v = ((due + step - 1) ~/ step) * step;
    if (v != due) out.add(v);
  }
  out.add(((due + 99999) ~/ 100000) * 100000 + 100000);
  final sorted = out.toList()..sort();
  return sorted.take(4).toList();
}

/// Greedy note fold — what the drawer will actually look like for [amount].
/// Shown for change, so the cashier counts out notes instead of doing the
/// arithmetic twice.
List<(int, int)> noteFold(int amount) {
  var rest = amount;
  final out = <(int, int)>[];
  for (final n in _notes) {
    final c = rest ~/ n;
    if (c > 0) {
      out.add((n, c));
      rest -= c * n;
    }
  }
  return out;
}

/// Counting cash onto the screen: tap a note to add one, `Kosongkan` to start
/// over (ADR-0066).
///
/// The design source decrements on right-click, which an Android tablet does
/// not have. Rather than hide the inverse behind a long-press, there is none:
/// a mis-counted fold is rare and re-counting is cheap, and a hidden gesture on
/// the money path is not. The running total is the point of the widget, so it
/// stays on screen beside the pad rather than under it.
class CashPad extends StatefulWidget {
  /// What is owed. Drives the quick tenders and the short/change readout.
  final int amount;
  final int tender;
  final ValueChanged<int> onTender;

  const CashPad({
    super.key,
    required this.amount,
    required this.tender,
    required this.onTender,
  });

  @override
  State<CashPad> createState() => _CashPadState();
}

class _CashPadState extends State<CashPad> {
  final _counts = <int, int>{};

  @override
  void didUpdateWidget(CashPad old) {
    super.didUpdateWidget(old);
    // The parent cleared the tender (mode or method changed, or the payment
    // landed) — the pad must not keep showing notes that are no longer counted.
    if (widget.tender == 0 && _counts.isNotEmpty) _counts.clear();
    if (widget.amount != old.amount) _counts.clear();
  }

  void _add(int note) {
    setState(() => _counts[note] = (_counts[note] ?? 0) + 1);
    widget.onTender(
      _notes.fold<int>(0, (a, n) => a + n * (_counts[n] ?? 0)),
    );
  }

  void _setExact(int value) {
    setState(() {
      _counts
        ..clear()
        ..addEntries(noteFold(value).map((f) => MapEntry(f.$1, f.$2)));
    });
    widget.onTender(value);
  }

  void _clear() {
    setState(_counts.clear);
    widget.onTender(0);
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final change = widget.tender - widget.amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Uang tamu · ketuk pecahan',
          style: SatType.labelS(color: sc.textLo),
        ),
        const SizedBox(height: Sp.s2),
        Wrap(
          spacing: Sp.s2,
          runSpacing: Sp.s2,
          children: [
            for (final n in _notes)
              _NoteButton(
                label: _noteLabels[n]!,
                count: _counts[n] ?? 0,
                onTap: () => _add(n),
              ),
          ],
        ),
        const SizedBox(height: Sp.s3),
        Wrap(
          spacing: Sp.s2,
          runSpacing: Sp.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final v in quickTenders(widget.amount))
              SatChip.select(
                label: v == widget.amount
                    ? 'Pas'
                    : formatIDR(v).replaceFirst('Rp ', ''),
                selected: widget.tender == v,
                onTap: () => _setExact(v),
              ),
            if (widget.tender > 0)
              SatButton.ghost(
                label: 'Kosongkan',
                size: SatButtonSize.sm,
                icon: Icons.close_rounded,
                onTap: _clear,
              ),
          ],
        ),
        const SizedBox(height: Sp.s3),
        _Summary(
          tender: widget.tender,
          amount: widget.amount,
          change: change,
        ),
      ],
    );
  }
}

class _NoteButton extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;
  const _NoteButton({
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final on = count > 0;
    return Semantics(
      button: true,
      label: on ? '$label, $count lembar' : label,
      child: Material(
        color: on ? sc.accentSoft : sc.bg2,
        borderRadius: SatR.a(10),
        child: InkWell(
          borderRadius: SatR.a(10),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.s3,
              vertical: Sp.s2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: SatType.monoM(
                    color: on ? sc.accentText : sc.textHi,
                  ),
                ),
                if (on)
                  Text(
                    '×$count',
                    style: SatType.labelS(color: sc.accentText),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Received / still-short / change, plus the fold. Three states, only one of
/// which is ever true, so the block never grows past two lines plus the fold.
class _Summary extends StatelessWidget {
  final int tender;
  final int amount;
  final int change;
  const _Summary({
    required this.tender,
    required this.amount,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    Widget row(String label, String value, Color tone) => Padding(
      padding: const EdgeInsets.only(bottom: Sp.s1),
      child: Row(
        children: [
          Expanded(child: Text(label, style: SatType.bodyS(color: sc.textLo))),
          Text(value, style: SatType.monoM(color: tone)),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(Sp.s3),
      decoration: SatBox.d(color: sc.bg2, borderRadius: SatR.a(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(
            'Diterima',
            tender == 0 ? '—' : formatIDR(tender),
            tender == 0 ? sc.textLo : sc.textHi,
          ),
          if (tender > 0 && change < 0)
            row('Masih kurang', formatIDR(-change), sc.warn),
          if (change >= 0 && tender > 0) ...[
            row('Kembalian', formatIDR(change), sc.success),
            if (change > 0)
              Wrap(
                spacing: Sp.s1,
                runSpacing: Sp.s1,
                children: [
                  for (final f in noteFold(change))
                    SatChip.tag(
                      label: '${f.$2}× ${_noteLabels[f.$1]}',
                      size: SatChipSize.sm,
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
