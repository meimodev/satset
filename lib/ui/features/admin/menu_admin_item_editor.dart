import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/modifier_group.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/admin/_common.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/ui/features/admin/menu_admin_view_model.dart';
import 'package:uuid/uuid.dart';

/// Full sectioned editor for one menu item.
/// Used in tablet right pane and phone full-screen route.
class MenuAdminItemEditor extends ConsumerStatefulWidget {
  final String? itemId;
  final VoidCallback? onClose;
  final VoidCallback? onDeleted;
  const MenuAdminItemEditor({
    super.key,
    required this.itemId,
    this.onClose,
    this.onDeleted,
  });

  @override
  ConsumerState<MenuAdminItemEditor> createState() => _MenuAdminItemEditorState();
}

class _MenuAdminItemEditorState extends ConsumerState<MenuAdminItemEditor> {
  late MenuItem _draft;
  bool _initialized = false;
  String? _lastLoadedFor;

  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _basePrice = TextEditingController();
  final _prep = TextEditingController();
  final _stock = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _basePrice.dispose();
    _prep.dispose();
    _stock.dispose();
    super.dispose();
  }

  void _loadDraftIfNeeded() {
    final id = widget.itemId;
    if (id == _lastLoadedFor && _initialized) return;
    _lastLoadedFor = id;
    if (id == null) {
      _draft = _blankItem();
    } else {
      final found = ref.read(menuItemsProvider).where((i) => i.id == id).firstOrNull;
      _draft = found ?? _blankItem();
    }
    _name.text = _draft.name;
    _desc.text = _draft.description;
    _basePrice.text = _draft.basePrice.toString();
    _prep.text = _draft.prepTime.toString();
    _stock.text = (_draft.stockCount ?? 0).toString();
    _initialized = true;
  }

  MenuItem _blankItem() {
    final id = const Uuid().v4().substring(0, 8);
    return MenuItem(
      id: id,
      name: '',
      categoryId: 'starters',
      station: Station.kitchen,
      description: '',
      basePrice: 0,
      variants: [Variant(id: 'reg', name: '', price: 0)],
    );
  }

  bool get _isNew => widget.itemId == null;

  void _patch(MenuItem next) => setState(() => _draft = next);

  void _save() {
    final priceCents = int.tryParse(_basePrice.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final prep = int.tryParse(_prep.text) ?? _draft.prepTime;
    final stockTracked = _draft.stockCount != null;
    final stockN = stockTracked ? (int.tryParse(_stock.text) ?? 0) : null;
    final variants = _draft.variants.isEmpty
        ? [Variant(id: 'reg', name: '', price: priceCents)]
        : [
            for (final v in _draft.variants)
              v.id == 'reg' && v.name.isEmpty ? v.copyWith(price: priceCents) : v,
          ];
    final saved = _draft.copyWith(
      name: _name.text.trim().isEmpty ? '(tanpa nama)' : _name.text.trim(),
      description: _desc.text.trim(),
      basePrice: priceCents,
      prepTime: prep,
      variants: variants,
      stockCount: stockN,
    );
    ref.read(menuRepositoryProvider.notifier).upsertItem(saved);
    if (_isNew) {
      ref.read(menuAdminSelectedItemIdProvider.notifier).state = saved.id;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isNew ? 'Item ditambahkan' : 'Perubahan tersimpan')),
    );
    widget.onClose?.call();
  }

  void _delete() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.sat.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final sc = ctx.sat;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sc.border1,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Hapus item?',
                    style: SatType.sans(
                        size: 16,
                        weight: FontWeight.w600,
                        color: sc.textHi)),
                const SizedBox(height: 8),
                Text('Item "${_draft.name}" akan dihapus dari menu.',
                    style: SatType.sans(
                        size: 13, color: sc.textMd, height: 1.4)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: sc.urgent),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true) return;
    if (!_isNew) {
      ref.read(menuRepositoryProvider.notifier).removeItem(_draft.id);
    }
    widget.onDeleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    _loadDraftIfNeeded();
    final sc = context.sat;
    final perm = ref.watch(menuPermissionProvider);
    final readOnly = perm == MenuPermission.staff;
    final cats = ref.watch(menuRealCategoriesProvider);

    return Container(
      color: sc.bg1,
      // ClipRect absorbs sub-pixel overflow when the IME animates in and the
      // pane height briefly drops below header+footer+scroll min height.
      child: ClipRect(
        child: Column(
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: _Header(
                title: _isNew ? 'Item baru' : _draft.name,
                sub: readOnly ? 'Hanya admin yang bisa edit' : 'Edit lengkap',
                onClose: widget.onClose,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _identitySection(sc, cats, readOnly),
                    const SizedBox(height: 18),
                    _pricingSection(sc, readOnly),
                    const SizedBox(height: 18),
                    _modifiersSection(sc, readOnly),
                    const SizedBox(height: 18),
                    _kitchenSection(sc, readOnly),
                    const SizedBox(height: 18),
                    _inventorySection(sc, readOnly),
                    const SizedBox(height: 18),
                    _tagsSection(sc, readOnly),
                    const SizedBox(height: 18),
                    _availabilitySection(sc),
                  ],
                ),
              ),
            ),
            if (!readOnly)
              Flexible(
                fit: FlexFit.loose,
                child: _Footer(onSave: _save, onDelete: _isNew ? null : _delete),
              ),
          ],
        ),
      ),
    );
  }

  // ---- sections ---------------------------------------------------------

  Widget _identitySection(SatColors sc, List<MenuCategory> cats, bool readOnly) {
    return _Section(
      title: 'Identitas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _photoSlot(sc, readOnly),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _input(_name, 'Nama item', readOnly: readOnly),
                    const SizedBox(height: 10),
                    _input(_desc, 'Deskripsi singkat', maxLines: 3, readOnly: readOnly),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label('Kategori'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              for (final c in cats)
                _chipChoice(
                  label: c.name,
                  selected: _draft.categoryId == c.id,
                  onTap: readOnly ? null : () => _patch(_draft.copyWith(categoryId: c.id)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoSlot(SatColors sc, bool readOnly) {
    final initials = _draft.name.isEmpty
        ? '?'
        : _draft.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();
    return GestureDetector(
      onTap: readOnly
          ? null
          : () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upload foto belum tersedia (placeholder)')),
              ),
      child: Container(
        width: 92, height: 92,
        decoration: BoxDecoration(
          color: sc.bg2,
          border: Border.all(color: sc.border1, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(initials,
                style: SatType.sans(
                  size: 22, weight: FontWeight.w600,
                  letterSpacing: -0.4, color: sc.textMd,
                )),
            const SizedBox(height: 4),
            Text('FOTO',
                style: SatType.mono(
                  size: 9, weight: FontWeight.w600,
                  letterSpacing: 1.2, color: sc.textLo,
                )),
          ],
        ),
      ),
    );
  }

  Widget _pricingSection(SatColors sc, bool readOnly) {
    return _Section(
      title: 'Harga',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _input(_basePrice, 'Harga dasar (Rp)', keyboard: TextInputType.number, readOnly: readOnly)),
              const SizedBox(width: 12),
              Expanded(child: _input(_prep, 'Prep (menit)', keyboard: TextInputType.number, readOnly: readOnly)),
            ],
          ),
          const SizedBox(height: 14),
          _subhead('Varian ukuran', trailing: readOnly ? null : _ghostButton('+ Varian', onTap: _addVariant)),
          const SizedBox(height: 6),
          if (_draft.variants.where((v) => v.name.isNotEmpty).isEmpty)
            Text('Belum ada varian. Hanya pakai harga dasar.',
                style: SatType.sans(size: 12, color: sc.textLo))
          else
            Column(
              children: [
                for (var i = 0; i < _draft.variants.length; i++)
                  if (_draft.variants[i].name.isNotEmpty)
                    _variantRow(sc, i, readOnly),
              ],
            ),
          const SizedBox(height: 18),
          _subhead(
            'Happy hour',
            trailing: readOnly ? null : _ghostButton(
              _draft.happyHour == null ? '+ Aktifkan' : 'Matikan',
              onTap: () => _patch(_draft.copyWith(
                happyHour: _draft.happyHour == null
                    ? const HappyHourRule(startMinute: 17 * 60, endMinute: 19 * 60, price: 0)
                    : null,
              )),
            ),
          ),
          if (_draft.happyHour != null) ...[
            const SizedBox(height: 8),
            _happyHourEditor(sc, readOnly),
          ],
        ],
      ),
    );
  }

  Widget _variantRow(SatColors sc, int idx, bool readOnly) {
    final v = _draft.variants[idx];
    final nameCtrl = TextEditingController(text: v.name);
    final priceCtrl = TextEditingController(text: v.price.toString());
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: nameCtrl,
              readOnly: readOnly,
              decoration: _fieldDeco('Nama (mis. Besar)'),
              onSubmitted: (t) {
                final next = List<Variant>.of(_draft.variants);
                next[idx] = next[idx].copyWith(name: t);
                _patch(_draft.copyWith(variants: next));
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: TextField(
              controller: priceCtrl,
              readOnly: readOnly,
              keyboardType: TextInputType.number,
              decoration: _fieldDeco('Harga'),
              onSubmitted: (t) {
                final n = int.tryParse(t.replaceAll(RegExp(r'\D'), '')) ?? 0;
                final next = List<Variant>.of(_draft.variants);
                next[idx] = next[idx].copyWith(price: n);
                _patch(_draft.copyWith(variants: next));
              },
            ),
          ),
          if (!readOnly)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: sc.textLo),
              onPressed: () {
                final next = List<Variant>.of(_draft.variants)..removeAt(idx);
                _patch(_draft.copyWith(variants: next));
              },
            ),
        ],
      ),
    );
  }

  void _addVariant() {
    final id = 'v${_draft.variants.length}';
    final next = List<Variant>.of(_draft.variants)
      ..add(Variant(id: id, name: 'Baru', price: _draft.basePrice));
    _patch(_draft.copyWith(variants: next));
  }

  Widget _happyHourEditor(SatColors sc, bool readOnly) {
    final hh = _draft.happyHour!;
    final startCtrl = TextEditingController(text: _hhmm(hh.startMinute));
    final endCtrl = TextEditingController(text: _hhmm(hh.endMinute));
    final priceCtrl = TextEditingController(text: hh.price.toString());
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: startCtrl,
                readOnly: readOnly,
                decoration: _fieldDeco('Mulai (HH:MM)'),
                onSubmitted: (t) => _patch(_draft.copyWith(
                  happyHour: hh.copyWith(startMinute: _parseHHMM(t) ?? hh.startMinute),
                )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: endCtrl,
                readOnly: readOnly,
                decoration: _fieldDeco('Selesai (HH:MM)'),
                onSubmitted: (t) => _patch(_draft.copyWith(
                  happyHour: hh.copyWith(endMinute: _parseHHMM(t) ?? hh.endMinute),
                )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: priceCtrl,
                readOnly: readOnly,
                keyboardType: TextInputType.number,
                decoration: _fieldDeco('Harga (Rp)'),
                onSubmitted: (t) => _patch(_draft.copyWith(
                  happyHour: hh.copyWith(price: int.tryParse(t.replaceAll(RegExp(r'\D'), '')) ?? 0),
                )),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Berlaku ${hh.formatWindow()} · ${formatIDR(hh.price)}',
              style: SatType.mono(size: 11, color: sc.textLo, letterSpacing: 0.4)),
        ),
      ],
    );
  }

  Widget _modifiersSection(SatColors sc, bool readOnly) {
    return _Section(
      title: 'Grup modifier',
      trailing: readOnly ? null : _ghostButton('+ Grup', onTap: _addModifierGroup),
      child: _draft.modifierGroups.isEmpty
          ? Text('Belum ada grup modifier (mis. tingkat pedas, pilih protein).',
              style: SatType.sans(size: 12, color: sc.textLo))
          : Column(
              children: [
                for (var i = 0; i < _draft.modifierGroups.length; i++)
                  _modifierGroupCard(sc, i, readOnly),
              ],
            ),
    );
  }

  void _addModifierGroup() {
    final id = 'g${_draft.modifierGroups.length}';
    final next = List<ModifierGroup>.of(_draft.modifierGroups)
      ..add(ModifierGroup(
        id: id,
        name: 'Grup baru',
        options: const [ModifierOption(id: 'o0', name: 'Opsi 1')],
      ));
    _patch(_draft.copyWith(modifierGroups: next));
  }

  Widget _modifierGroupCard(SatColors sc, int gi, bool readOnly) {
    final g = _draft.modifierGroups[gi];
    final nameCtrl = TextEditingController(text: g.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: sc.border1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameCtrl,
                  readOnly: readOnly,
                  style: SatType.sans(size: 14, weight: FontWeight.w600, color: sc.textHi),
                  decoration: _fieldDeco('Nama grup').copyWith(isDense: true),
                  onSubmitted: (t) {
                    final next = List<ModifierGroup>.of(_draft.modifierGroups);
                    next[gi] = next[gi].copyWith(name: t);
                    _patch(_draft.copyWith(modifierGroups: next));
                  },
                ),
              ),
              if (!readOnly)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: sc.textLo),
                  onPressed: () {
                    final next = List<ModifierGroup>.of(_draft.modifierGroups)..removeAt(gi);
                    _patch(_draft.copyWith(modifierGroups: next));
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _toggleChip(
                label: 'Wajib',
                on: g.required,
                onTap: readOnly ? null : () {
                  final next = List<ModifierGroup>.of(_draft.modifierGroups);
                  next[gi] = next[gi].copyWith(required: !g.required);
                  _patch(_draft.copyWith(modifierGroups: next));
                },
              ),
              const SizedBox(width: 8),
              _toggleChip(
                label: 'Pilih banyak',
                on: g.multi,
                onTap: readOnly ? null : () {
                  final next = List<ModifierGroup>.of(_draft.modifierGroups);
                  next[gi] = next[gi].copyWith(multi: !g.multi);
                  _patch(_draft.copyWith(modifierGroups: next));
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var oi = 0; oi < g.options.length; oi++)
            _optionRow(sc, gi, oi, readOnly),
          if (!readOnly)
            Align(
              alignment: Alignment.centerLeft,
              child: _ghostButton('+ Opsi', onTap: () {
                final opts = List<ModifierOption>.of(g.options)
                  ..add(ModifierOption(id: 'o${g.options.length}', name: 'Opsi baru'));
                final next = List<ModifierGroup>.of(_draft.modifierGroups);
                next[gi] = next[gi].copyWith(options: opts);
                _patch(_draft.copyWith(modifierGroups: next));
              }),
            ),
        ],
      ),
    );
  }

  Widget _optionRow(SatColors sc, int gi, int oi, bool readOnly) {
    final g = _draft.modifierGroups[gi];
    final o = g.options[oi];
    final nameCtrl = TextEditingController(text: o.name);
    final priceCtrl = TextEditingController(text: o.priceDelta.toString());
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: nameCtrl,
              readOnly: readOnly,
              decoration: _fieldDeco('Nama opsi').copyWith(isDense: true),
              onSubmitted: (t) {
                final opts = List<ModifierOption>.of(g.options);
                opts[oi] = opts[oi].copyWith(name: t);
                final next = List<ModifierGroup>.of(_draft.modifierGroups);
                next[gi] = next[gi].copyWith(options: opts);
                _patch(_draft.copyWith(modifierGroups: next));
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: TextField(
              controller: priceCtrl,
              readOnly: readOnly,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: _fieldDeco('+/- Rp').copyWith(isDense: true),
              onSubmitted: (t) {
                final n = int.tryParse(t) ?? 0;
                final opts = List<ModifierOption>.of(g.options);
                opts[oi] = opts[oi].copyWith(priceDelta: n);
                final next = List<ModifierGroup>.of(_draft.modifierGroups);
                next[gi] = next[gi].copyWith(options: opts);
                _patch(_draft.copyWith(modifierGroups: next));
              },
            ),
          ),
          if (!readOnly)
            IconButton(
              icon: Icon(Icons.close, size: 16, color: sc.textLo),
              onPressed: () {
                final opts = List<ModifierOption>.of(g.options)..removeAt(oi);
                final next = List<ModifierGroup>.of(_draft.modifierGroups);
                next[gi] = next[gi].copyWith(options: opts);
                _patch(_draft.copyWith(modifierGroups: next));
              },
            ),
        ],
      ),
    );
  }

  Widget _kitchenSection(SatColors sc, bool readOnly) {
    return _Section(
      title: 'Dapur',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Stasiun'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _chipChoice(
                      label: 'Dapur',
                      selected: _draft.station == Station.kitchen,
                      onTap: readOnly ? null : () => _patch(_draft.copyWith(station: Station.kitchen)),
                    ),
                    const SizedBox(width: 6),
                    _chipChoice(
                      label: 'Bar',
                      selected: _draft.station == Station.bar,
                      onTap: readOnly ? null : () => _patch(_draft.copyWith(station: Station.bar)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inventorySection(SatColors sc, bool readOnly) {
    final tracked = _draft.stockCount != null;
    return _Section(
      title: 'Inventaris',
      trailing: _toggleChip(
        label: tracked ? 'Lacak stok' : 'Tanpa stok',
        on: tracked,
        onTap: readOnly ? null : () => _patch(_draft.copyWith(
          stockCount: tracked ? null : 0,
          autoEightySixAtZero: tracked ? false : _draft.autoEightySixAtZero,
        )),
      ),
      child: tracked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _input(_stock, 'Sisa stok', keyboard: TextInputType.number, readOnly: readOnly)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text('Auto 86 saat stok = 0',
                          style: SatType.sans(size: 13, color: sc.textMd)),
                    ),
                    adminToggle(context, on: _draft.autoEightySixAtZero),
                    const SizedBox(width: 6),
                    if (!readOnly)
                      TextButton(
                        onPressed: () => _patch(_draft.copyWith(
                            autoEightySixAtZero: !_draft.autoEightySixAtZero)),
                        child: Text(_draft.autoEightySixAtZero ? 'Off' : 'On'),
                      ),
                  ],
                ),
              ],
            )
          : Text('Stok tidak dilacak. 86 dikelola manual.',
              style: SatType.sans(size: 12, color: sc.textLo)),
    );
  }

  Widget _tagsSection(SatColors sc, bool readOnly) {
    return _Section(
      title: 'Tag',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Alergen'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              for (final a in Allergen.values)
                _toggleChip(
                  label: allergenNames[a] ?? a.name,
                  on: _draft.allergens.contains(a),
                  onTap: readOnly ? null : () {
                    final set = List<Allergen>.of(_draft.allergens);
                    set.contains(a) ? set.remove(a) : set.add(a);
                    _patch(_draft.copyWith(allergens: set));
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          _label('Diet'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              for (final d in DietaryTag.values)
                _toggleChip(
                  label: dietaryNames[d] ?? d.name,
                  on: _draft.dietary.contains(d),
                  onTap: readOnly ? null : () {
                    final set = List<DietaryTag>.of(_draft.dietary);
                    set.contains(d) ? set.remove(d) : set.add(d);
                    _patch(_draft.copyWith(dietary: set));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _availabilitySection(SatColors sc) {
    final auto = _draft.autoEightySixed;
    return _Section(
      title: 'Ketersediaan',
      child: Row(
        children: [
          Expanded(
            child: Text(
              auto
                  ? 'Auto 86 karena stok habis'
                  : (_draft.unavailable ? '86\'d manual' : 'Aktif untuk dijual'),
              style: SatType.sans(
                size: 14,
                weight: FontWeight.w600,
                color: _draft.isEightySixed ? sc.urgent : sc.success,
              ),
            ),
          ),
          adminToggle(context, on: !_draft.isEightySixed),
          const SizedBox(width: 6),
          TextButton(
            onPressed: auto
                ? null
                : () {
                    final newVal = !_draft.unavailable;
                    final updated = _draft.copyWith(unavailable: newVal);
                    _patch(updated);
                    if (!_isNew) {
                      ref.read(menuRepositoryProvider.notifier).upsertItem(updated);
                    }
                  },
            child: Text(_draft.unavailable ? 'Aktifkan' : '86'),
          ),
        ],
      ),
    );
  }

  // ---- shared field bits -----------------------------------------------

  InputDecoration _fieldDeco(String hint) {
    final sc = context.sat;
    return InputDecoration(
      hintText: hint,
      hintStyle: SatType.sans(size: 13, color: sc.textLo),
      filled: true,
      fillColor: sc.bg2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: sc.border1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: sc.border1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: sc.accent, width: 1.5),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboard,
    bool readOnly = false,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboard,
      style: SatType.sans(size: 14, color: context.sat.textHi),
      decoration: _fieldDeco(hint),
      inputFormatters: keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
    );
  }

  Widget _label(String t) {
    final sc = context.sat;
    return Text(t.toUpperCase(),
        style: SatType.mono(
          size: 10, weight: FontWeight.w600,
          letterSpacing: 1.0, color: sc.textLo,
        ));
  }

  Widget _subhead(String t, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(child: _label(t)),
        ?trailing,
      ],
    );
  }

  Widget _chipChoice({required String label, required bool selected, VoidCallback? onTap}) {
    final sc = context.sat;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? sc.accentSoft : sc.bg2,
          border: Border.all(color: selected ? sc.accentBorder : sc.border1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: SatType.sans(
              size: 12,
              weight: FontWeight.w500,
              color: selected ? sc.accent : sc.textMd,
            )),
      ),
    );
  }

  Widget _toggleChip({required String label, required bool on, VoidCallback? onTap}) {
    final sc = context.sat;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: on ? sc.successSoft : sc.bg2,
          border: Border.all(color: on ? sc.success : sc.border1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: on ? sc.success : sc.textLo,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: SatType.sans(size: 11, weight: FontWeight.w500, color: on ? sc.success : sc.textMd)),
          ],
        ),
      ),
    );
  }

  Widget _ghostButton(String t, {required VoidCallback onTap}) {
    final sc = context.sat;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        foregroundColor: sc.accent,
      ),
      child: Text(t, style: SatType.sans(size: 12, weight: FontWeight.w600, color: sc.accent)),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title.toUpperCase(),
                    style: SatType.mono(
                      size: 10, weight: FontWeight.w600,
                      letterSpacing: 1.2, color: sc.textLo,
                    )),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String sub;
  final VoidCallback? onClose;
  const _Header({required this.title, required this.sub, this.onClose});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 16, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: sc.border0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: SatType.sans(
                      size: 22, weight: FontWeight.w600,
                      letterSpacing: -0.3, color: sc.textHi,
                    )),
                const SizedBox(height: 4),
                Text(sub.toUpperCase(),
                    style: SatType.mono(
                      size: 11, color: sc.textLo, letterSpacing: 0.66,
                    )),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(Icons.close, color: sc.textMd),
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  const _Footer({required this.onSave, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: sc.bg1,
        border: Border(top: BorderSide(color: sc.border0)),
      ),
      child: Row(
        children: [
          if (onDelete != null)
            TextButton.icon(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: sc.urgent, size: 18),
              label: Text('Hapus', style: SatType.sans(size: 13, weight: FontWeight.w600, color: sc.urgent)),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: sc.accent,
              foregroundColor: sc.accentInk,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Simpan',
                style: SatType.sans(size: 13, weight: FontWeight.w600, color: sc.accentInk)),
          ),
        ],
      ),
    );
  }
}

String _hhmm(int m) {
  final h = (m ~/ 60).toString().padLeft(2, '0');
  final mm = (m % 60).toString().padLeft(2, '0');
  return '$h:$mm';
}

int? _parseHHMM(String t) {
  final parts = t.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}
