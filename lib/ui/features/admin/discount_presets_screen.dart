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
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/discount_dto.dart';
import 'package:satset/data/repositories/discount_presets_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';

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
        label: const Text('Preset baru'),
      ),
      body: Column(
        children: [
          const SatAppBar(title: 'Diskon'),
          Expanded(
            child: presets.isEmpty
          ? _Empty(sc: sc)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                Text(
                  'Kasir memilih dari daftar ini — mereka tidak bisa mengetik '
                  'angka diskon sendiri.',
                  style: SatType.sans(size: 12, color: sc.textLo),
                ),
                const SizedBox(height: 16),
                if (order.isNotEmpty) ...[
                  _SectionLabel('Seluruh pesanan', sc: sc),
                  for (final p in order)
                    _PresetTile(preset: p, repo: repo, sc: sc),
                  const SizedBox(height: 20),
                ],
                if (line.isNotEmpty) ...[
                  _SectionLabel('Per item', sc: sc),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  final SatColors sc;
  const _SectionLabel(this.text, {required this.sc});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: SatType.mono(
              size: 9,
              weight: FontWeight.w600,
              letterSpacing: 1.4,
              color: sc.textLo),
        ),
      );
}

class _Empty extends StatelessWidget {
  final SatColors sc;
  const _Empty({required this.sc});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sell_outlined, size: 40, color: sc.textLo),
              const SizedBox(height: 12),
              Text('Belum ada preset diskon',
                  style: SatType.sans(
                      size: 15, weight: FontWeight.w600, color: sc.textHi)),
              const SizedBox(height: 6),
              Text(
                'Buat preset agar kasir bisa memberi diskon tanpa mengetik '
                'angka sendiri.',
                textAlign: TextAlign.center,
                style: SatType.sans(size: 12.5, color: sc.textLo),
              ),
            ],
          ),
        ),
      );
}

class _PresetTile extends StatelessWidget {
  final DiscountPresetDto preset;
  final DiscountPresetsRepository repo;
  final SatColors sc;
  const _PresetTile(
      {required this.preset, required this.repo, required this.sc});

  @override
  Widget build(BuildContext context) {
    final p = preset;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: SatR.a(12),
        border: SatB.all(color: sc.border0),
      ),
      child: ListTile(
        title: Row(
          children: [
            Flexible(
              child: Text(p.name,
                  style: SatType.sans(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: p.active ? sc.textHi : sc.textLo)),
            ),
            if (!p.active) ...[
              const SizedBox(width: 8),
              Text('nonaktif',
                  style: SatType.sans(size: 10.5, color: sc.textLo)),
            ],
          ],
        ),
        subtitle: Text(
          p.isPercent
              ? '${(p.value / 100).toStringAsFixed(0)}%'
              : formatIDR(p.value),
          style: SatType.sans(size: 12, color: sc.textLo),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: sc.urgent),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Hapus preset'),
                content: Text(
                  'Hapus "${p.name}"? Diskon yang sudah dipakai di tagihan '
                  'lama tidak berubah — nilainya sudah tersimpan di sana.',
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Hapus')),
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

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) {
      final sc = c.sat;
      return StatefulBuilder(
        builder: (c, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, MediaQuery.of(c).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'Preset baru' : 'Ubah preset',
                  style: SatType.sans(
                      size: 15, weight: FontWeight.w700, color: sc.textHi)),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama (tampil di struk)',
                  hintText: 'Diskon Member',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Scope is what stops a fixed whole-bill amount landing on one
              // cheap line — the cashier's picker filters on it.
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'order', label: Text('Seluruh pesanan')),
                  ButtonSegment(value: 'line', label: Text('Per item')),
                ],
                selected: {scope},
                onSelectionChanged: (v) => setState(() => scope = v.first),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'percent', label: Text('Persen')),
                  ButtonSegment(value: 'fixed', label: Text('Nominal')),
                ],
                selected: {kind},
                onSelectionChanged: (v) => setState(() => kind = v.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: kind == 'percent' ? 'Persen (%)' : 'Nominal (Rp)',
                  border: const OutlineInputBorder(),
                  errorText: error,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Aktif',
                    style: SatType.sans(size: 13, color: sc.textHi)),
                subtitle: Text('Nonaktif menyembunyikan preset dari kasir',
                    style: SatType.sans(size: 11.5, color: sc.textLo)),
                value: active,
                onChanged: (v) => setState(() => active = v),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final raw = int.tryParse(valueCtrl.text.trim()) ?? 0;
                    // Percent is authored in whole %, stored in bps.
                    final value = kind == 'percent' ? raw * 100 : raw;
                    if (name.isEmpty) {
                      setState(() => error = 'Nama wajib diisi');
                      return;
                    }
                    if (value <= 0) {
                      setState(() => error = 'Nilai harus lebih dari 0');
                      return;
                    }
                    if (kind == 'percent' && value > 10000) {
                      setState(() => error = 'Maksimal 100%');
                      return;
                    }
                    if (existing == null) {
                      await r.create(
                          name: name,
                          scope: scope,
                          kind: kind,
                          value: value,
                          active: active);
                    } else {
                      await r.update(existing.id,
                          name: name,
                          scope: scope,
                          kind: kind,
                          value: value,
                          active: active);
                    }
                    if (c.mounted) Navigator.pop(c);
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
