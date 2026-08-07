import 'package:flutter/material.dart';

import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/l10n/app_localizations.dart';

/// Common reasons a dish comes off mid-service. Offered as taps because the
/// person doing this is standing at a pass, not typing — but the field stays
/// open, since the real reason is often none of these.
List<String> _presets(AppL10n l) => [
  l.killReasonOutOfStock,
  l.killReasonQuality,
  l.killReasonBrokenEquipment,
  l.killReasonTooSlow,
];

/// Ask why an item is coming off the menu.
///
/// Returns the reason, `''` when the user confirmed without giving one, and
/// null when they backed out. The empty string matters: skipping is allowed —
/// a rush is a bad time to force a form — but it must be distinguishable from
/// cancelling, or a dismissed sheet would silently 86 the dish.
Future<String?> showKillReasonSheet(
  BuildContext context, {
  required String itemName,
}) => showSatSheet<String>(
  context,
  builder: (ctx) => _KillReasonSheet(itemName: itemName),
);

class _KillReasonSheet extends StatefulWidget {
  final String itemName;
  const _KillReasonSheet({required this.itemName});

  @override
  State<_KillReasonSheet> createState() => _KillReasonSheetState();
}

class _KillReasonSheetState extends State<_KillReasonSheet> {
  final _controller = TextEditingController();
  String? _picked;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _reason => _controller.text.trim().isNotEmpty
      ? _controller.text.trim()
      : (_picked ?? '');

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.s5, 0, Sp.s5, Sp.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SatSheetHeader(
              padding: const EdgeInsets.fromLTRB(0, Sp.s3, 0, Sp.s2),
              onClose: () => Navigator.of(context).pop(),
              child: Text(
                context.l10n.killReasonTitle,
                style: SatType.h3(color: sc.textHi),
              ),
            ),
            Text(
              context.l10n.killReasonBody(widget.itemName),
              style: SatType.bodyS(color: sc.textMd),
            ),
            const SizedBox(height: Sp.s4),
            Wrap(
              spacing: Sp.s2,
              runSpacing: Sp.s2,
              children: [
                for (final p in _presets(context.l10n))
                  SatChip.select(
                    label: p,
                    selected: _picked == p && _controller.text.trim().isEmpty,
                    onTap: () => setState(() {
                      _picked = _picked == p ? null : p;
                      _controller.clear();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: Sp.s3),
            SatField.text(
              controller: _controller,
              hint: context.l10n.killReasonHint,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Sp.s4),
            Row(
              children: [
                Expanded(
                  child: SatButton.ghost(
                    label: context.l10n.killReasonSkip,
                    onTap: () => Navigator.of(context).pop(''),
                  ),
                ),
                const SizedBox(width: Sp.s2),
                Expanded(
                  child: SatButton.danger(
                    label: context.l10n.killReasonConfirm,
                    onTap: () => Navigator.of(context).pop(_reason),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
