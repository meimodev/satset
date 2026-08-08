/// The owner's [[Preset diskon]] catalogue editor (ADR-0037). Reached from
/// Venue Settings › Diskon and gated by `editSettings`.
///
/// This is the ONLY place discount values are authored — the [[Cashier]] picks
/// from what is defined here and can never type a rate. Presets are
/// hard-deleted rather than archived: every applied discount snapshots its own
/// name/kind/value, so deleting one cannot corrupt settled history. `active`
/// parks a seasonal promo without deleting it.
library;

import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/discount_dto.dart';
import 'package:satset/data/repositories/discount_presets_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';

class DiscountPresetsScreen extends ConsumerWidget {
  const DiscountPresetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final presets = ref.watch(discountPresetsRepositoryProvider);
    final repo = ref.read(discountPresetsRepositoryProvider.notifier);
    final order = presets.where((p) => p.scope == 'order').toList();
    final line = presets.where((p) => p.scope == 'line').toList();

    return Scaffold(
      backgroundColor: sc.bg0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null, repo: repo),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.dscNewPreset),
      ),
      body: Column(
        children: [
          // Pushed from Venue Settings, so the hub stays in the trail.
          SatAppBar(crumbs: [context.l10n.tabVenue, context.l10n.crumbDiskon]),
          Expanded(
            child: presets.isEmpty
                ? SatEmpty(
                    icon: Icons.sell_outlined,
                    title: context.l10n.dscEmptyTitle,
                    body: context.l10n.dscEmptyBody,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      Text(
                        context.l10n.dscIntro,
                        style: SatType.bodyS(color: sc.textLo),
                      ),
                      const SizedBox(height: Sp.s4),
                      if (order.isNotEmpty) ...[
                        SatSectionLabel(context.l10n.dscScopeOrder),
                        for (final p in order)
                          _PresetTile(preset: p, repo: repo, sc: sc),
                        const SizedBox(height: Sp.s5),
                      ],
                      if (line.isNotEmpty) ...[
                        SatSectionLabel(context.l10n.dscScopeLine),
                        for (final p in line)
                          _PresetTile(preset: p, repo: repo, sc: sc),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final DiscountPresetDto preset;
  final DiscountPresetsRepository repo;
  final SatColors sc;
  const _PresetTile({
    required this.preset,
    required this.repo,
    required this.sc,
  });

  @override
  Widget build(BuildContext context) {
    final p = preset;
    return Container(
      margin: const EdgeInsets.only(bottom: Sp.s2),
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: SatR.a(12),
        border: SatB.all(color: sc.border0),
      ),
      child: ListTile(
        title: Row(
          children: [
            Flexible(
              child: Text(
                p.name,
                style: SatType.labelM(color: p.active ? sc.textHi : sc.textLo),
              ),
            ),
            if (!p.active) ...[
              const SizedBox(width: Sp.s2),
              Text(
                context.l10n.dscInactive,
                style: SatType.bodyS(color: sc.textLo),
              ),
            ],
          ],
        ),
        subtitle: Text(
          p.isPercent
              ? '${(p.value / 100).toStringAsFixed(0)}%'
              : formatIDR(p.value),
          style: SatType.bodyS(color: sc.textLo),
        ),
        trailing: IconButton(
          tooltip: context.l10n.delete,
          icon: Icon(Icons.delete_outline, color: sc.urgent),
          onPressed: () async {
            final ok = await showSatDialog<bool>(
              context,
              builder: (c) => AlertDialog(
                title: Text(context.l10n.dscDeleteTitle),
                content: Text(context.l10n.dscDeleteBody(p.name)),
                actions: [
                  SatButton.ghost(
                    label: context.l10n.cancel,
                    onTap: () => Navigator.pop(c, false),
                  ),
                  SatButton.danger(
                    label: context.l10n.delete,
                    onTap: () => Navigator.pop(c, true),
                  ),
                ],
              ),
            );
            if (ok == true) await repo.remove(p.id);
          },
        ),
        onTap: () => _edit(context, p, repo: repo),
      ),
    );
  }
}

Future<void> _edit(
  BuildContext context,
  DiscountPresetDto? existing, {
  required DiscountPresetsRepository repo,
}) async {
  final r = repo;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final valueCtrl = TextEditingController(
    text: existing == null
        ? ''
        : (existing.isPercent
              ? (existing.value / 100).toStringAsFixed(0)
              : '${existing.value}'),
  );
  var scope = existing?.scope ?? 'order';
  var kind = existing?.kind ?? 'percent';
  var active = existing?.active ?? true;
  String? error;

  await showSatSheet<void>(
    context,
    dragHandle: true,
    builder: (c) {
      final sc = c.sat;
      return StatefulBuilder(
        builder: (c, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.of(c).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? c.l10n.dscNewPreset : c.l10n.dscEditPreset,
                style: SatType.labelL(color: sc.textHi),
              ),
              const SizedBox(height: Sp.s3),
              SatField.text(
                controller: nameCtrl,
                label: c.l10n.dscNameLabel,
                hint: c.l10n.dscNameHint,
              ),
              const SizedBox(height: Sp.s3),
              // Scope is what stops a fixed whole-bill amount landing on one
              // cheap line — the cashier's picker filters on it.
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'order',
                    label: Text(c.l10n.dscScopeOrder),
                  ),
                  ButtonSegment(
                    value: 'line',
                    label: Text(c.l10n.dscScopeLine),
                  ),
                ],
                selected: {scope},
                onSelectionChanged: (v) => setState(() => scope = v.first),
              ),
              const SizedBox(height: Sp.s2h),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'percent',
                    label: Text(c.l10n.dscKindPercent),
                  ),
                  ButtonSegment(
                    value: 'fixed',
                    label: Text(c.l10n.dscKindFixed),
                  ),
                ],
                selected: {kind},
                onSelectionChanged: (v) => setState(() => kind = v.first),
              ),
              const SizedBox(height: Sp.s3),
              SatField.number(
                controller: valueCtrl,
                label: kind == 'percent'
                    ? c.l10n.dscValuePercent
                    : c.l10n.dscValueFixed,
                hint: '',
                errorText: error,
              ),
              const SizedBox(height: Sp.s2),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.l10n.dscActive,
                          style: SatType.bodyM(color: sc.textHi),
                        ),
                        Text(
                          c.l10n.dscActiveHint,
                          style: SatType.bodyS(color: sc.textLo),
                        ),
                      ],
                    ),
                  ),
                  SatToggle(
                    value: active,
                    semanticLabel: c.l10n.dscActive,
                    onChanged: (v) => setState(() => active = v),
                  ),
                ],
              ),
              const SizedBox(height: Sp.s2),
              SizedBox(
                width: double.infinity,
                child: SatButton.primary(
                  label: c.l10n.save,
                  onTap: () async {
                    final name = nameCtrl.text.trim();
                    final raw = int.tryParse(valueCtrl.text.trim()) ?? 0;
                    // Percent is authored in whole %, stored in bps.
                    final value = kind == 'percent' ? raw * 100 : raw;
                    if (name.isEmpty) {
                      setState(() => error = c.l10n.dscErrName);
                      return;
                    }
                    if (value <= 0) {
                      setState(() => error = c.l10n.dscErrValue);
                      return;
                    }
                    if (kind == 'percent' && value > 10000) {
                      setState(() => error = c.l10n.dscErrMax);
                      return;
                    }
                    if (existing == null) {
                      await r.create(
                        name: name,
                        scope: scope,
                        kind: kind,
                        value: value,
                        active: active,
                      );
                    } else {
                      await r.update(
                        existing.id,
                        name: name,
                        scope: scope,
                        kind: kind,
                        value: value,
                        active: active,
                      );
                    }
                    if (c.mounted) Navigator.pop(c);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
