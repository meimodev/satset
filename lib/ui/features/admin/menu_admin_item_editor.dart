import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:satset/ui/core/widgets/menu_photo.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/menu_tag.dart';
import 'package:satset/domain/models/modifier_group.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
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

  /// Picked photo bytes not yet committed (preview from memory). Null = no
  /// pending change. [_pendingPhotoClear] is set when the user removes an
  /// existing photo. Both are applied on Save, after the item row exists.
  Uint8List? _pendingPhoto;
  bool _pendingPhotoClear = false;

  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _basePrice = TextEditingController();
  final _cost = TextEditingController();
  final _prep = TextEditingController();
  final _stock = TextEditingController();

  /// Persistent controllers for dynamic sub-rows (variants, modifier groups,
  /// options), keyed by a stable id so edits commit to the draft on every
  /// keystroke without recreating controllers (which would jump the cursor)
  /// or losing typed text on save.
  final _subCtrls = <String, TextEditingController>{};

  TextEditingController _ctrl(String key, String initial) {
    final existing = _subCtrls[key];
    if (existing != null) return existing;
    return _subCtrls[key] = TextEditingController(text: initial);
  }

  @override
  void initState() {
    super.initState();
    // Android may destroy the host activity while the camera is open (memory
    // pressure), in which case pickImage returns null and the capture is
    // delivered here instead. Recover it so the photo isn't silently lost.
    _recoverLostPhoto();
  }

  Future<void> _recoverLostPhoto() async {
    try {
      final lost = await ImagePicker().retrieveLostData();
      final file = lost.file;
      if (lost.isEmpty || file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pendingPhoto = bytes;
        _pendingPhotoClear = false;
      });
      await _commitPhotoIfExisting();
    } catch (_) {
      // Nothing recoverable; ignore.
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _basePrice.dispose();
    _cost.dispose();
    _prep.dispose();
    _stock.dispose();
    for (final c in _subCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadDraftIfNeeded() {
    final id = widget.itemId;
    if (id == _lastLoadedFor && _initialized) return;
    _lastLoadedFor = id;
    _pendingPhoto = null;
    _pendingPhotoClear = false;
    if (id == null) {
      _draft = _blankItem();
    } else {
      final found = ref.read(menuItemsProvider).where((i) => i.id == id).firstOrNull;
      _draft = found ?? _blankItem();
    }
    _name.text = _draft.name;
    _desc.text = _draft.description;
    _basePrice.text = groupRupiah(_draft.basePrice);
    _cost.text = groupRupiah(_draft.cost);
    _prep.text = _draft.prepTime.toString();
    _stock.text = (_draft.stockCount ?? 0).toString();
    _initialized = true;
  }

  MenuItem _blankItem() {
    final id = const Uuid().v4().substring(0, 8);
    final cats = ref.read(menuRealCategoriesProvider);
    return MenuItem(
      id: id,
      name: '',
      categoryId: cats.isNotEmpty ? cats.first.id : '',
      description: '',
      basePrice: 0,
      variants: [Variant(id: 'reg', name: '', price: 0)],
    );
  }

  bool get _isNew => widget.itemId == null;

  void _patch(MenuItem next) => setState(() => _draft = next);

  Future<void> _save() async {
    final priceCents = int.tryParse(_basePrice.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final costCents = int.tryParse(_cost.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
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
      cost: costCents,
      prepTime: prep,
      variants: variants,
      stockCount: stockN,
    );
    final repo = ref.read(menuRepositoryProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final wasNew = _isNew;
    try {
      // Item row first, then the photo side-call (PUT/DELETE need an
      // existing row). See ADR-0014.
      await repo.upsertItem(saved);
      if (_pendingPhoto != null) {
        await repo.uploadPhoto(saved.id, _pendingPhoto!);
      } else if (_pendingPhotoClear) {
        await repo.deletePhoto(saved.id);
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      return;
    }
    if (wasNew) {
      ref.read(menuAdminSelectedItemIdProvider.notifier).state = saved.id;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(wasNew ? 'Item ditambahkan' : 'Perubahan tersimpan')),
    );
    widget.onClose?.call();
  }

  void _delete() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
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
            _Header(
              title: _isNew ? 'Item baru' : _draft.name,
              sub: readOnly ? 'Hanya admin yang bisa edit' : 'Edit lengkap',
              onClose: widget.onClose,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, section) in [
                      _identitySection(sc, cats, readOnly),
                      _pricingSection(sc, readOnly),
                      _modifiersSection(sc, readOnly),
                      _inventorySection(sc, readOnly),
                      _tagsSection(sc, readOnly),
                      _availabilitySection(sc),
                    ].indexed) ...[
                      if (i > 0) const SizedBox(height: 18),
                      // Cascade sections in on load; animKey carries the draft
                      // id so the stagger replays when a new item is selected.
                      Reveal(
                        index: i,
                        animKey: '${_draft.id}:sec:$i',
                        child: section,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!readOnly)
              _Footer(onSave: _save, onDelete: _isNew ? null : _delete),
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

  /// Whether a photo would show after the current pending edits.
  bool get _hasPhotoNow =>
      _pendingPhoto != null || (!_pendingPhotoClear && _draft.hasPhoto);

  Widget _photoSlot(SatColors sc, bool readOnly) {
    final radius = BorderRadius.circular(14);
    Widget preview;
    String sig;
    if (_pendingPhoto != null) {
      sig = 'pending:${_pendingPhoto!.length}';
      preview = ClipRRect(
        borderRadius: radius,
        child: Image.memory(_pendingPhoto!,
            fit: BoxFit.cover, width: 92, height: 92, gaplessPlayback: true),
      );
    } else {
      sig = 'rev:${_pendingPhotoClear ? 0 : _draft.photoRev}';
      preview = MenuPhoto(
        itemId: _draft.id,
        name: _draft.name,
        photoRev: _pendingPhotoClear ? 0 : _draft.photoRev,
        borderRadius: radius,
      );
    }
    // Crossfade when the photo changes (pick / clear / revision bump).
    preview = AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: kSatEase,
      switchOutCurve: kSatEase,
      child: KeyedSubtree(key: ValueKey(sig), child: preview),
    );
    return GestureDetector(
      onTap: readOnly ? null : _showPhotoSheet,
      child: Stack(
        children: [
          Container(
            width: 92, height: 92,
            decoration: BoxDecoration(
              border: Border.all(color: sc.border1),
              borderRadius: radius,
            ),
            child: preview,
          ),
          if (!readOnly)
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomRight: Radius.circular(13),
                  ),
                ),
                child: Text(_hasPhotoNow ? 'UBAH' : 'FOTO',
                    style: SatType.mono(
                      size: 8, weight: FontWeight.w600,
                      letterSpacing: 1.0, color: Colors.white,
                    )),
              ),
            ),
        ],
      ),
    );
  }

  void _showPhotoSheet() {
    final sc = context.sat;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: sc.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: sc.border1, borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: sc.textMd),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: sc.textMd),
              title: const Text('Ambil foto'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (_hasPhotoNow)
              ListTile(
                leading: Icon(Icons.delete_outline, color: sc.urgent),
                title: Text('Hapus foto',
                    style: SatType.sans(color: sc.urgent)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _pendingPhoto = null;
                    _pendingPhotoClear = true;
                  });
                  _commitPhotoIfExisting();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pendingPhoto = bytes;
        _pendingPhotoClear = false;
      });
      await _commitPhotoIfExisting();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat foto: $e')));
    }
  }

  /// On an **existing** item, photo edits apply immediately (ADR-0014): the
  /// picked bytes are PUT — or a clear is DELETE'd — the moment the action
  /// completes, not on Save. On failure the optimistic memory preview is
  /// reverted to the prior photo and a snackbar shown; on success the pending
  /// state is cleared and the draft's `photoRev` adopted from the merged server
  /// item, so the explicit Save never re-sends the photo. New items have no row
  /// yet, so their pending state rides the first Save instead.
  Future<void> _commitPhotoIfExisting() async {
    if (_isNew) return;
    final repo = ref.read(menuRepositoryProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_pendingPhoto != null) {
        await repo.uploadPhoto(_draft.id, _pendingPhoto!);
      } else if (_pendingPhotoClear) {
        await repo.deletePhoto(_draft.id);
      } else {
        return;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pendingPhoto = null;
        _pendingPhotoClear = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan foto')),
      );
      return;
    }
    if (!mounted) return;
    MenuItem? merged;
    for (final i in ref.read(menuRepositoryProvider).items) {
      if (i.id == _draft.id) {
        merged = i;
        break;
      }
    }
    setState(() {
      _pendingPhoto = null;
      _pendingPhotoClear = false;
      if (merged != null) _draft = _draft.copyWith(photoRev: merged.photoRev);
    });
  }

  Widget _pricingSection(SatColors sc, bool readOnly) {
    return _Section(
      title: 'Harga',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _input(_basePrice, 'Harga dasar (Rp)', keyboard: TextInputType.number, amount: true, readOnly: readOnly, onChanged: (_) => setState(() {}))),
              const SizedBox(width: 12),
              Expanded(child: _input(_prep, 'Prep (menit)', keyboard: TextInputType.number, readOnly: readOnly)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _input(_cost, 'HPP (Rp)', keyboard: TextInputType.number, amount: true, readOnly: readOnly, onChanged: (_) => setState(() {}))),
              const SizedBox(width: 12),
              Expanded(child: _marginPreview(sc)),
            ],
          ),
          const SizedBox(height: 14),
          _subhead('Varian ukuran', trailing: readOnly ? null : _ghostButton('+ Varian', onTap: _addVariant)),
          const SizedBox(height: 6),
          ExpandFade(
            child: _draft.variants.where((v) => v.name.isNotEmpty).isEmpty
                ? Text('Belum ada varian. Hanya pakai harga dasar.',
                    key: const ValueKey('var-empty'),
                    style: SatType.sans(size: 12, color: sc.textLo))
                : AnimatedReflow(
                    key: const ValueKey('var-list'),
                    child: Column(
                      children: [
                        for (var i = 0; i < _draft.variants.length; i++)
                          if (_draft.variants[i].name.isNotEmpty)
                            KeyedSubtree(
                              key: ValueKey('v:${_draft.variants[i].id}'),
                              child: _variantRow(sc, i, readOnly),
                            ),
                      ],
                    ),
                  ),
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
          ExpandFade(
            child: _draft.happyHour != null
                ? Padding(
                    key: const ValueKey('hh-on'),
                    padding: const EdgeInsets.only(top: 8),
                    child: _happyHourEditor(sc, readOnly),
                  )
                : const SizedBox(width: double.infinity, key: ValueKey('hh-off')),
          ),
        ],
      ),
    );
  }

  Widget _variantRow(SatColors sc, int idx, bool readOnly) {
    final v = _draft.variants[idx];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl('v:${v.id}:name', v.name),
              readOnly: readOnly,
              decoration: _fieldDeco('Nama (mis. Besar)'),
              onChanged: (t) {
                final next = List<Variant>.of(_draft.variants);
                next[idx] = next[idx].copyWith(name: t);
                _draft = _draft.copyWith(variants: next);
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: TextField(
              controller: _ctrl('v:${v.id}:price', groupRupiah(v.price)),
              readOnly: readOnly,
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
              decoration: _fieldDeco('Harga'),
              onChanged: (t) {
                final n = int.tryParse(t.replaceAll(RegExp(r'\D'), '')) ?? 0;
                final next = List<Variant>.of(_draft.variants);
                next[idx] = next[idx].copyWith(price: n);
                _draft = _draft.copyWith(variants: next);
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
    final id = 'v${const Uuid().v4().substring(0, 6)}';
    final next = List<Variant>.of(_draft.variants)
      ..add(Variant(id: id, name: 'Baru', price: _draft.basePrice));
    _patch(_draft.copyWith(variants: next));
  }

  Widget _happyHourEditor(SatColors sc, bool readOnly) {
    final hh = _draft.happyHour!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl('hh:start', _hhmm(hh.startMinute)),
                readOnly: readOnly,
                decoration: _fieldDeco('Mulai (HH:MM)'),
                onChanged: (t) {
                  final m = _parseHHMM(t);
                  if (m == null) return;
                  _draft = _draft.copyWith(
                      happyHour: _draft.happyHour!.copyWith(startMinute: m));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _ctrl('hh:end', _hhmm(hh.endMinute)),
                readOnly: readOnly,
                decoration: _fieldDeco('Selesai (HH:MM)'),
                onChanged: (t) {
                  final m = _parseHHMM(t);
                  if (m == null) return;
                  _draft = _draft.copyWith(
                      happyHour: _draft.happyHour!.copyWith(endMinute: m));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _ctrl('hh:price', groupRupiah(hh.price)),
                readOnly: readOnly,
                keyboardType: TextInputType.number,
                inputFormatters: const [RupiahInputFormatter()],
                decoration: _fieldDeco('Harga (Rp)'),
                onChanged: (t) => _draft = _draft.copyWith(
                  happyHour: _draft.happyHour!.copyWith(
                      price: int.tryParse(t.replaceAll(RegExp(r'\D'), '')) ?? 0),
                ),
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
      child: ExpandFade(
        child: _draft.modifierGroups.isEmpty
            ? Text('Belum ada grup modifier (mis. tingkat pedas, pilih protein).',
                key: const ValueKey('mod-empty'),
                style: SatType.sans(size: 12, color: sc.textLo))
            : AnimatedReflow(
                key: const ValueKey('mod-list'),
                child: Column(
                  children: [
                    for (var i = 0; i < _draft.modifierGroups.length; i++)
                      KeyedSubtree(
                        key: ValueKey('g:${_draft.modifierGroups[i].id}'),
                        child: _modifierGroupCard(sc, i, readOnly),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  void _addModifierGroup() {
    final id = 'g${const Uuid().v4().substring(0, 6)}';
    final oid = 'o${const Uuid().v4().substring(0, 6)}';
    final next = List<ModifierGroup>.of(_draft.modifierGroups)
      ..add(ModifierGroup(
        id: id,
        name: 'Grup baru',
        options: [ModifierOption(id: oid, name: 'Opsi 1')],
      ));
    _patch(_draft.copyWith(modifierGroups: next));
  }

  Widget _modifierGroupCard(SatColors sc, int gi, bool readOnly) {
    final g = _draft.modifierGroups[gi];
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
                  controller: _ctrl('g:${g.id}:name', g.name),
                  readOnly: readOnly,
                  style: SatType.sans(size: 14, weight: FontWeight.w600, color: sc.textHi),
                  decoration: _fieldDeco('Nama grup').copyWith(isDense: true),
                  onChanged: (t) {
                    final next = List<ModifierGroup>.of(_draft.modifierGroups);
                    next[gi] = next[gi].copyWith(name: t);
                    _draft = _draft.copyWith(modifierGroups: next);
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
          AnimatedReflow(
            child: Column(
              children: [
                for (var oi = 0; oi < g.options.length; oi++)
                  KeyedSubtree(
                    key: ValueKey('o:${g.options[oi].id}'),
                    child: _optionRow(sc, gi, oi, readOnly),
                  ),
              ],
            ),
          ),
          if (!readOnly)
            Align(
              alignment: Alignment.centerLeft,
              child: _ghostButton('+ Opsi', onTap: () {
                final opts = List<ModifierOption>.of(g.options)
                  ..add(ModifierOption(
                      id: 'o${const Uuid().v4().substring(0, 6)}',
                      name: 'Opsi baru'));
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl('o:${g.id}:${o.id}:name', o.name),
              readOnly: readOnly,
              decoration: _fieldDeco('Nama opsi').copyWith(isDense: true),
              onChanged: (t) {
                final opts = List<ModifierOption>.of(g.options);
                opts[oi] = opts[oi].copyWith(name: t);
                final next = List<ModifierGroup>.of(_draft.modifierGroups);
                next[gi] = next[gi].copyWith(options: opts);
                _draft = _draft.copyWith(modifierGroups: next);
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _ctrl('o:${g.id}:${o.id}:price',
                  o.priceDelta < 0
                      ? '-${groupRupiah(-o.priceDelta)}'
                      : groupRupiah(o.priceDelta)),
              readOnly: readOnly,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              inputFormatters: const [RupiahInputFormatter(allowNegative: true)],
              decoration: _fieldDeco('+/- Rp').copyWith(isDense: true),
              onChanged: (t) {
                final neg = t.trimLeft().startsWith('-');
                final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
                final n = (int.tryParse(digits) ?? 0) * (neg ? -1 : 1);
                final opts = List<ModifierOption>.of(g.options);
                opts[oi] = opts[oi].copyWith(priceDelta: n);
                final next = List<ModifierGroup>.of(_draft.modifierGroups);
                next[gi] = next[gi].copyWith(options: opts);
                _draft = _draft.copyWith(modifierGroups: next);
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

  Widget _inventorySection(SatColors sc, bool readOnly) {
    final tracked = _draft.stockCount != null;
    return _Section(
      title: 'Inventaris',
      trailing: _toggleChip(
        label: tracked ? 'Lacak stok' : 'Tanpa stok',
        on: tracked,
        onTap: readOnly ? null : () => _patch(_draft.copyWith(
          stockCount: tracked ? null : 0,
          autoSoldOutAtZero: tracked ? false : _draft.autoSoldOutAtZero,
        )),
      ),
      child: ExpandFade(
        child: tracked
            ? Column(
                key: const ValueKey('inv-on'),
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
                        child: Text('Tandai habis otomatis saat stok = 0',
                            style: SatType.sans(size: 13, color: sc.textMd)),
                      ),
                      adminToggle(context, on: _draft.autoSoldOutAtZero),
                      const SizedBox(width: 6),
                      if (!readOnly)
                        TextButton(
                          onPressed: () => _patch(_draft.copyWith(
                              autoSoldOutAtZero: !_draft.autoSoldOutAtZero)),
                          child: Text(_draft.autoSoldOutAtZero ? 'Off' : 'On'),
                        ),
                    ],
                  ),
                ],
              )
            : Text('Stok tidak dilacak. Status habis diatur manual.',
                key: const ValueKey('inv-off'),
                style: SatType.sans(size: 12, color: sc.textLo)),
      ),
    );
  }

  Widget _tagsSection(SatColors sc, bool readOnly) {
    final allTags = ref.watch(menuTagsProvider);
    final allergens = menuTagsOfKind(allTags, MenuTagKind.allergen);
    final diets = menuTagsOfKind(allTags, MenuTagKind.diet);
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
              for (final t in allergens)
                _toggleChip(
                  label: t.name,
                  on: _draft.allergens.contains(t.id),
                  onTap: readOnly ? null : () {
                    final set = List<String>.of(_draft.allergens);
                    set.contains(t.id) ? set.remove(t.id) : set.add(t.id);
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
              for (final t in diets)
                _toggleChip(
                  label: t.name,
                  on: _draft.dietary.contains(t.id),
                  onTap: readOnly ? null : () {
                    final set = List<String>.of(_draft.dietary);
                    set.contains(t.id) ? set.remove(t.id) : set.add(t.id);
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
    final auto = _draft.isAutoSoldOut;
    return _Section(
      title: 'Ketersediaan',
      child: Row(
        children: [
          Expanded(
            child: Text(
              auto
                  ? 'Otomatis ditandai habis (stok 0)'
                  : (_draft.unavailable ? 'Ditandai habis manual' : 'Aktif untuk dijual'),
              style: SatType.sans(
                size: 14,
                weight: FontWeight.w600,
                color: _draft.isSoldOut ? sc.urgent : sc.success,
              ),
            ),
          ),
          adminToggle(context, on: !_draft.isSoldOut),
          const SizedBox(width: 6),
          TextButton(
            onPressed: auto
                ? null
                : () => _patch(_draft.copyWith(unavailable: !_draft.unavailable)),
            child: Text(_draft.unavailable ? 'Aktifkan' : 'Habis'),
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
    bool amount = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboard,
      onChanged: onChanged,
      style: SatType.sans(size: 14, color: context.sat.textHi),
      decoration: _fieldDeco(hint),
      inputFormatters: amount
          ? const [RupiahInputFormatter()]
          : keyboard == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
    );
  }

  Widget _marginPreview(SatColors sc) {
    final price = int.tryParse(_basePrice.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final cost = int.tryParse(_cost.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final hasData = price > 0;
    final marginPct = hasData ? ((price - cost) / price * 100) : 0;
    final marginRp = price - cost;
    Color tone;
    String hint;
    if (!hasData) {
      tone = sc.textLo;
      hint = 'Isi harga dasar dulu';
    } else if (marginPct >= 40) {
      tone = sc.success;
      hint = 'Margin sehat';
    } else if (marginPct >= 15) {
      tone = sc.warn;
      hint = 'Margin tipis';
    } else {
      tone = sc.urgent;
      hint = 'Margin kritis';
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: kSatEase,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MARGIN',
              style: SatType.mono(
                size: 9, weight: FontWeight.w600,
                letterSpacing: 1.0, color: sc.textLo,
              )),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 240),
            style: SatType.sans(size: 18, weight: FontWeight.w600, color: tone),
            child: hasData
                ? AnimatedCount(
                    value: marginPct.round(),
                    duration: const Duration(milliseconds: 360),
                    builder: (_, v) => Text('$v%'),
                  )
                : const Text('—'),
          ),
          const SizedBox(height: 2),
          Text(hasData ? 'Rp $marginRp · $hint' : hint,
              style: SatType.sans(size: 11, color: sc.textMd)),
        ],
      ),
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
    return PressScale(
      pressedScale: onTap == null ? 1.0 : 0.95,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: kSatEase,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? sc.accentSoft : sc.bg2,
            border: Border.all(color: selected ? sc.accentBorder : sc.border1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: SatType.sans(
              size: 12,
              weight: FontWeight.w500,
              color: selected ? sc.accent : sc.textMd,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _toggleChip({required String label, required bool on, VoidCallback? onTap}) {
    final sc = context.sat;
    return PressScale(
      pressedScale: onTap == null ? 1.0 : 0.95,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: kSatEase,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: on ? sc.successSoft : sc.bg2,
            border: Border.all(color: on ? sc.success : sc.border1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: kSatEase,
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: on ? sc.success : sc.textLo,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: SatType.sans(size: 11, weight: FontWeight.w500, color: on ? sc.success : sc.textMd),
                child: Text(label),
              ),
            ],
          ),
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

class _Footer extends StatefulWidget {
  final Future<void> Function() onSave;
  final VoidCallback? onDelete;
  const _Footer({required this.onSave, this.onDelete});

  @override
  State<_Footer> createState() => _FooterState();
}

enum _SaveState { idle, saving, done }

class _FooterState extends State<_Footer> {
  _SaveState _state = _SaveState.idle;

  Future<void> _run() async {
    if (_state != _SaveState.idle) return;
    setState(() => _state = _SaveState.saving);
    try {
      await widget.onSave();
    } catch (_) {
      // Errors surface via snackbar in onSave; just reset the button.
    }
    if (!mounted) return;
    // Brief success tick before the pane closes / resets.
    setState(() => _state = _SaveState.done);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _state = _SaveState.idle);
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final saving = _state == _SaveState.saving;
    final done = _state == _SaveState.done;

    Widget label;
    if (saving) {
      label = SizedBox(
        key: const ValueKey('saving'),
        width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: sc.accentInk),
      );
    } else if (done) {
      label = Icon(Icons.check_rounded,
          key: const ValueKey('done'), size: 18, color: sc.accentInk);
    } else {
      label = Text('Simpan',
          key: const ValueKey('idle'),
          style: SatType.sans(
              size: 13, weight: FontWeight.w600, color: sc.accentInk));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: sc.bg1,
        border: Border(top: BorderSide(color: sc.border0)),
      ),
      child: Row(
        children: [
          if (widget.onDelete != null)
            PressScale(
              pressedScale: 0.96,
              child: TextButton.icon(
                onPressed: widget.onDelete,
                icon: Icon(Icons.delete_outline, color: sc.urgent, size: 18),
                label: Text('Hapus', style: SatType.sans(size: 13, weight: FontWeight.w600, color: sc.urgent)),
              ),
            ),
          const Spacer(),
          PressScale(
            pressedScale: 0.96,
            child: ElevatedButton(
              onPressed: _state == _SaveState.idle ? _run : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: done ? sc.success : sc.accent,
                foregroundColor: sc.accentInk,
                disabledBackgroundColor: done ? sc.success : sc.accent,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: kSatEase,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(anim), child: child)),
                child: label,
              ),
            ),
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
