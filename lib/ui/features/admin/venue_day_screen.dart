import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/cash_repository.dart';
import 'package:satset/data/repositories/venue_day_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import '_common.dart';

/// **Buka kedai / Tutup kedai** — the day as a guided ritual (ADR-0111).
///
/// A screen that *sequences* writers, and owns none. Opening posts a
/// [[Kas kecil]] top-up and an audit row; closing posts a count and an audit
/// row. Every guard those two carry stays where it already is, inside the one
/// transaction that can hold it (ADR-0100) — a second copy of the balance rule
/// living up here would be the review finding.
///
/// **Closing records; it does not enforce.** Open bills do not block it. A cafe
/// with one unpaid tab still has to go home, and a close that refused would be
/// routed around by not using this screen — which loses the record that was the
/// entire point.
class VenueDayScreen extends ConsumerStatefulWidget {
  const VenueDayScreen({super.key});

  @override
  ConsumerState<VenueDayScreen> createState() => _VenueDayScreenState();
}

class _VenueDayScreenState extends ConsumerState<VenueDayScreen> {
  final _float = TextEditingController();
  final _counted = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _float.dispose();
    _counted.dispose();
    _note.dispose();
    super.dispose();
  }

  int _rupiah(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Future<void> _run(Future<void> Function() body) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await body();
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Which [[Kas (cash box)]] the day's ritual funds and counts.
  ///
  /// The venue's **first active box** — `box-main` unless somebody reordered
  /// the picker. A venue that keeps several tins still opens and closes on one,
  /// which is exactly what the ritual did before ADR-0131; the others are
  /// counted on `/kas` when their holder counts them. A box picker belongs here
  /// the day a venue asks to close two tins at once, not before.
  String _ritualBoxId() {
    final boxes = ref.read(cashProvider).boxes;
    for (final b in boxes) {
      if (b.active) return b.id;
    }
    return 'box-main';
  }

  /// Float first, then the mark. Ordered so a failing top-up leaves no audit
  /// row claiming the shop opened — the reverse order would record an opening
  /// whose float never went in, which is exactly the discrepancy the ritual
  /// exists to make visible.
  Future<void> _open() => _run(() async {
    final amount = _rupiah(_float);
    if (amount > 0) {
      await ref
          .read(cashProvider.notifier)
          .topUp(
            boxId: _ritualBoxId(),
            amount: amount,
            note: context.l10n.vdayFloatNote,
          );
    }
    await ref.read(venueDayProvider).open(note: _note.text.trim());
  });

  /// Count first, then the mark, for the mirror of the same reason.
  Future<void> _close() => _run(() async {
    if (_counted.text.trim().isNotEmpty) {
      await ref
          .read(cashProvider.notifier)
          .count(
            boxId: _ritualBoxId(),
            counted: _rupiah(_counted),
            note: context.l10n.vdayCountNote,
          );
    }
    await ref.read(venueDayProvider).close(note: _note.text.trim());
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sc = context.sat;
    final auth = ref.watch(authStateProvider);
    final canOpen = auth.has(Capability.openDrawer);
    final canClose = auth.has(Capability.closeShift);
    final balance = ref.watch(cashProvider).balance;

    return AdminPage(
      title: l10n.vdayTitle,
      sub: l10n.vdaySub,
      children: [
        if (_error != null) ...[
          Text(l10n.vdayFailed, style: SatType.bodyS(color: sc.urgent)),
          const SizedBox(height: Sp.s3),
        ],
        if (canOpen) ...[
          SatCard.titled(
            title: l10n.vdayOpenTitle,
            tag: l10n.vdayTagDay,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.vdayOpenBody,
                  style: SatType.bodyS(color: sc.textLo),
                ),
                const SizedBox(height: Sp.s3),
                SatField.money(
                  controller: _float,
                  label: l10n.vdayFloatLabel,
                  hint: '',
                  helperText: l10n.vdayLedgerSays(formatIDR(balance)),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Sp.s3),
                SatButton.primary(
                  label: l10n.vdayOpenAction,
                  icon: Icons.wb_sunny_outlined,
                  onTap: _busy ? null : _open,
                ),
              ],
            ),
          ),
          const SizedBox(height: Sp.s4),
        ],
        if (canClose) ...[
          SatCard.titled(
            title: l10n.vdayCloseTitle,
            tag: l10n.vdayTagDay,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.vdayCloseBody,
                  style: SatType.bodyS(color: sc.textLo),
                ),
                const SizedBox(height: Sp.s3),
                SatField.money(
                  controller: _counted,
                  label: l10n.vdayCountedLabel,
                  hint: '',
                  helperText: l10n.vdayLedgerSays(formatIDR(balance)),
                  onChanged: (_) => setState(() {}),
                ),
                // The variance, live. Shown before the button rather than in a
                // result afterwards: a counter who is about to record a
                // 40k shortfall should see the number while the notes are
                // still in their hand and a recount is free.
                if (_counted.text.trim().isNotEmpty) ...[
                  const SizedBox(height: Sp.s2),
                  Builder(
                    builder: (_) {
                      final diff = _rupiah(_counted) - balance;
                      return Text(
                        diff == 0
                            ? l10n.vdayVarianceNone
                            : l10n.vdayVariance(formatIDR(diff)),
                        style: SatType.bodyS(
                          color: diff == 0 ? sc.success : sc.warn,
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: Sp.s3),
                SatField.text(
                  controller: _note,
                  label: l10n.vdayNoteLabel,
                  hint: '',
                ),
                const SizedBox(height: Sp.s3),
                Row(
                  children: [
                    Expanded(
                      child: SatButton.outline(
                        label: l10n.vdayReadReport,
                        icon: Icons.insert_chart_outlined,
                        onTap: () => context.go('/reports'),
                      ),
                    ),
                    const SizedBox(width: Sp.s3),
                    Expanded(
                      child: SatButton.primary(
                        label: l10n.vdayCloseAction,
                        icon: Icons.nightlight_outlined,
                        onTap: _busy ? null : _close,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
