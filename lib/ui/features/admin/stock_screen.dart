import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/data/repositories/stock_repository.dart';
import 'package:satset/domain/models/ingredient.dart';
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/admin/_common.dart';

/// "Stok" — the bahan list, receiving, opname, produksi, and the movement
/// ledger. Procurement work, deliberately kept out of the menu editor: recipes
/// are authored once beside the variants they depend on, while stock is run
/// daily by whoever counts the walk-in (ADR-0040).
class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  /// Absolute counts typed during an opname pass, keyed by ingredient id. The
  /// counter enters what is physically there; the server writes the difference,
  /// and that difference is the variance (ADR-0041).
  final _counts = <String, int>{};
  bool _opname = false;
  bool _lowOnly = false;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final async = ref.watch(ingredientsProvider);
    return Column(
      children: [
        AdminEmbeddedStrip(
          title: 'Stok',
          sub: _opname ? 'Stok opname' : 'Bahan & mutasi',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_opname)
                IconButton(
                  tooltip: 'Tambah bahan',
                  icon: Icon(Icons.add, color: sc.textMd),
                  onPressed: () => _editIngredient(null),
                ),
              TextButton(
                onPressed: () => setState(() {
                  _opname = !_opname;
                  _counts.clear();
                }),
                child: Text(_opname ? 'Batal' : 'Opname'),
              ),
              if (_opname)
                TextButton(
                  onPressed: _counts.isEmpty ? null : _submitOpname,
                  child: const Text('Simpan'),
                ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Message('Gagal memuat stok: $e', color: sc.urgent),
            data: (list) {
              final shown = _lowOnly
                  ? list.where((i) => i.isLow || i.stockOnHand < 0).toList()
                  : list;
              if (list.isEmpty) {
                return const _Message(
                    'Belum ada bahan. Tambahkan bahan, lalu susun resepnya di '
                    'editor menu agar stok berkurang otomatis saat pesanan '
                    'dikirim.');
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(ingredientsProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    _summary(sc, list),
                    const SizedBox(height: 12),
                    for (final i in shown) _row(sc, i),
                    if (shown.isEmpty)
                      const _Message('Tidak ada bahan yang menipis.'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _summary(SatColors sc, List<Ingredient> list) {
    final value = list.fold<int>(0, (a, i) => a + i.stockValue);
    final low = list.where((i) => i.isLow).length;
    final negative = list.where((i) => i.stockOnHand < 0).length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _pill(sc, 'Nilai stok', formatIDR(value), sc.textHi),
        _pill(sc, 'Menipis', '$low bahan', low > 0 ? sc.warn : sc.textLo,
            onTap: () => setState(() => _lowOnly = !_lowOnly), on: _lowOnly),
        // A negative balance is a real state, never clamped: it means an
        // override sale outran the counts (ADR-0041).
        if (negative > 0)
          _pill(sc, 'Minus', '$negative bahan', sc.urgent),
      ],
    );
  }

  Widget _pill(SatColors sc, String label, String value, Color color,
      {VoidCallback? onTap, bool on = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? sc.bg3 : sc.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? color : sc.border1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: SatType.mono(
                    size: 9, color: sc.textLo, letterSpacing: 0.6)),
            const SizedBox(height: 2),
            Text(value,
                style: SatType.sans(
                    size: 14, weight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _row(SatColors sc, Ingredient i) {
    final negative = i.stockOnHand < 0;
    final color = negative
        ? sc.urgent
        : i.isLow
            ? sc.warn
            : sc.textHi;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: sc.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sc.border1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(i.name,
                          style: SatType.sans(
                              size: 14,
                              weight: FontWeight.w600,
                              color: sc.textHi)),
                    ),
                    if (i.isProduced) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.blender_outlined, size: 14, color: sc.info),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${i.onHandLabel}'
                  '${i.costMicro > 0 ? ' · ${formatIDR(i.stockValue)}' : ''}'
                  '${i.isLow ? ' · menipis' : ''}'
                  '${negative ? ' · perlu opname' : ''}',
                  style: SatType.mono(size: 11, color: color),
                ),
              ],
            ),
          ),
          if (_opname)
            SizedBox(
              width: 110,
              child: TextField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: SatType.sans(size: 14, color: sc.textHi),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: i.unit.label,
                  hintStyle: SatType.sans(size: 12, color: sc.textLo),
                ),
                onChanged: (t) {
                  final v = double.tryParse(t.replaceAll(',', '.'));
                  setState(() {
                    if (v == null) {
                      _counts.remove(i.id);
                    } else {
                      _counts[i.id] = i.unit.toBase(v);
                    }
                  });
                },
              ),
            )
          else
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: sc.textLo),
              onSelected: (v) => switch (v) {
                'receive' => _receive(i),
                'produce' => _produce(i),
                'ledger' => _ledger(i),
                'edit' => _editIngredient(i),
                'archive' => _archive(i),
                _ => null,
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'receive', child: Text('Terima barang')),
                if (i.isProduced)
                  const PopupMenuItem(value: 'produce', child: Text('Produksi')),
                const PopupMenuItem(value: 'ledger', child: Text('Riwayat mutasi')),
                const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                const PopupMenuItem(value: 'archive', child: Text('Arsipkan')),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- actions

  Future<void> _submitOpname() async {
    final api = ref.read(stockApiProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final deltas = await api.recordCounts(Map.of(_counts));
      final changed = deltas.values.where((d) => d != 0).length;
      messenger.showSnackBar(SnackBar(
          content: Text(changed == 0
              ? 'Opname selesai — tidak ada selisih'
              : 'Opname selesai — $changed bahan disesuaikan')));
      setState(() {
        _opname = false;
        _counts.clear();
      });
      ref.invalidate(ingredientsProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  Future<void> _receive(Ingredient i) async {
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
        text: i.costMicro > 0
            ? unitPriceFromCostMicro(i.costMicro, i.unit).toString()
            : '');
    final supplierCtrl = TextEditingController();
    var unit = i.unit;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => _Sheet(
        title: 'Terima ${i.name}',
        children: [
          StatefulBuilder(
            builder: (_, setSheet) => Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Jumlah'),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<StockUnit>(
                  value: unit,
                  items: [
                    for (final u in entryUnitsFor(i.unit))
                      DropdownMenuItem(value: u, child: Text(u.label)),
                  ],
                  onChanged: (u) => setSheet(() => unit = u ?? unit),
                ),
              ],
            ),
          ),
          TextField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Harga per ${i.unit.label} (opsional)',
              helperText: 'Kosongkan untuk tidak mengubah harga rata-rata',
            ),
          ),
          TextField(
            controller: supplierCtrl,
            decoration: const InputDecoration(labelText: 'Pemasok (opsional)'),
          ),
        ],
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(stockApiProvider).receive(
            ingredientId: i.id,
            qty: unit.toBase(amount),
            unitPrice: int.tryParse(priceCtrl.text),
            supplier: supplierCtrl.text.trim().isEmpty
                ? null
                : supplierCtrl.text.trim(),
          );
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Stok ditambahkan')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _produce(Ingredient i) async {
    final ctrl = TextEditingController(text: '1');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => _Sheet(
        title: 'Produksi ${i.name}',
        subtitle: i.batchYield == null
            ? null
            : '1 batch = ${formatQty(i.batchYield!, i.unit)}. '
                'Bahan bakunya berkurang otomatis.',
        children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Jumlah batch'),
          ),
        ],
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
    if (ok != true) return;
    final n = int.tryParse(ctrl.text) ?? 0;
    if (n <= 0) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(stockApiProvider).produce(i.id, n);
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Produksi dicatat')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _ledger(Ingredient i) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _LedgerSheet(ingredient: i),
    );
  }

  Future<void> _archive(Ingredient i) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(stockApiProvider).archive(i.id);
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(SnackBar(content: Text('${i.name} diarsipkan')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _editIngredient(Ingredient? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final openingCtrl = TextEditingController();
    final lowCtrl = TextEditingController(
        text: existing?.lowStockAt == null
            ? ''
            : _trim(existing!.unit.fromBase(existing.lowStockAt!)));
    final yieldCtrl = TextEditingController(
        text: existing?.batchYield == null
            ? ''
            : _trim(existing!.unit.fromBase(existing.batchYield!)));
    var unit = existing?.unit ?? StockUnit.pcs;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheet) => _Sheet(
          title: existing == null ? 'Bahan baru' : 'Ubah ${existing.name}',
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: existing == null,
              decoration: const InputDecoration(labelText: 'Nama bahan'),
            ),
            DropdownButtonFormField<StockUnit>(
              initialValue: unit,
              decoration: const InputDecoration(labelText: 'Satuan'),
              items: [
                for (final u in StockUnit.values)
                  DropdownMenuItem(
                    value: u,
                    child: Text(
                        '${u.label} · ${stockDimensionLabel(u.dimension)}'),
                  ),
              ],
              onChanged: (u) => setSheet(() => unit = u ?? unit),
            ),
            if (existing == null)
              TextField(
                controller: openingCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Stok awal (${unit.label})',
                  helperText: 'Dicatat sebagai mutasi, bukan angka telanjang',
                ),
              ),
            TextField(
              controller: lowCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Batas menipis (${unit.label}, opsional)',
              ),
            ),
            TextField(
              controller: yieldCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Hasil 1 batch (${unit.label}, opsional)',
                helperText:
                    'Isi bila bahan ini dibuat sendiri, lalu susun resepnya',
              ),
            ),
          ],
          onConfirm: () => Navigator.of(ctx).pop(true),
        ),
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    double? parse(TextEditingController c) =>
        double.tryParse(c.text.replaceAll(',', '.'));
    final low = parse(lowCtrl);
    final batch = parse(yieldCtrl);
    final opening = parse(openingCtrl);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(stockApiProvider).save(
            Ingredient(
              id: existing?.id ?? const Uuid().v4(),
              name: name,
              unit: unit,
              lowStockAt: low == null ? null : unit.toBase(low),
              batchYield: batch == null ? null : unit.toBase(batch),
            ),
            openingStock:
                existing == null && opening != null ? unit.toBase(opening) : 0,
          );
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Bahan disimpan')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  static String _trim(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }
}

/// The append-only ledger for one bahan — the answer to "why does the app say
/// 2 kg when the cook says 5?".
class _LedgerSheet extends ConsumerWidget {
  const _LedgerSheet({required this.ingredient});
  final Ingredient ingredient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final async = ref.watch(stockMovementsProvider(ingredient.id));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mutasi ${ingredient.name}',
                style: SatType.sans(
                    size: 16, weight: FontWeight.w600, color: sc.textHi)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _Message('Gagal memuat: $e', color: sc.urgent),
                data: (rows) => rows.isEmpty
                    ? const _Message('Belum ada mutasi.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: rows.length,
                        itemBuilder: (_, i) {
                          final m = rows[i];
                          final positive = m.delta > 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(m.reason.label,
                                          style: SatType.sans(
                                              size: 13, color: sc.textHi)),
                                      Text(
                                        [
                                          if (m.sourceLabel.isNotEmpty)
                                            m.sourceLabel,
                                          _stamp(m.at),
                                          if (m.note != null) m.note!,
                                        ].join(' · '),
                                        style: SatType.mono(
                                            size: 10, color: sc.textLo),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${positive ? '+' : ''}'
                                  '${formatQty(m.delta, ingredient.unit)}',
                                  style: SatType.mono(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: positive ? sc.success : sc.textMd,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _stamp(DateTime at) {
  final l = at.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)} ${two(l.hour)}:${two(l.minute)}';
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.children,
    required this.onConfirm,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: SatType.sans(
                    size: 16, weight: FontWeight.w600, color: sc.textHi)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: SatType.sans(size: 12, color: sc.textLo)),
            ],
            const SizedBox(height: 12),
            for (final c in children)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: c,
              ),
            const SizedBox(height: 6),
            FilledButton(onPressed: onConfirm, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text,
          textAlign: TextAlign.center,
          style: SatType.sans(size: 13, color: color ?? sc.textLo)),
    );
  }
}
