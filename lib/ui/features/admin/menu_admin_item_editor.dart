import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:satset/ui/core/widgets/menu_photo.dart';
import 'package:satset/data/repositories/stock_repository.dart';
import 'package:satset/domain/models/ingredient.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/menu_tag.dart';
import 'package:satset/domain/models/modifier_group.dart';
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/features/admin/_common.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/ui/features/admin/menu_admin_view_model.dart';
import 'package:uuid/uuid.dart';
import 'package:satset/ui/core/design/spacing.dart';

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
  ConsumerState<MenuAdminItemEditor> createState() =>
      _MenuAdminItemEditorState();
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

  /// Staged recipe edits. Follows the form's staged-until-Save semantics (the
  /// photo is the deliberate exception — see ADR-0014); on a brand-new item the
  /// recipe lands right after the row is created, since lines need an owner.
  ItemRecipes _recipes = const ItemRecipes();
  bool _recipesLoaded = false;

  /// Which recipe scope the editor is showing: `''` = the item's base recipe,
  /// `v:<variantId>` = that variant's replacing recipe, `o:<optionId>` = that
  /// modifier option's additive recipe.
  String _recipeScope = '';

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
      final found = ref
          .read(menuItemsProvider)
          .where((i) => i.id == id)
          .firstOrNull;
      _draft = found ?? _blankItem();
    }
    _name.text = _draft.name;
    _desc.text = _draft.description;
    // Zero seeds a blank, not a literal "0" — an untouched field must show its
    // hint, not a value the admin has to select-all-delete before typing.
    _basePrice.text = _draft.basePrice == 0
        ? ''
        : groupRupiah(_draft.basePrice);
    _cost.text = _draft.cost == 0 ? '' : groupRupiah(_draft.cost);
    _showErrors = false;
    // Empty = "ikut target venue" (ADR-0043). The hint carries the number it
    // would inherit, so the field always communicates a value.
    _prep.text = _draft.prepTime?.toString() ?? '';
    _initialized = true;
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final id = widget.itemId;
    if (id == null) {
      setState(() => _recipesLoaded = true);
      return;
    }
    try {
      final r = await ref.read(stockApiProvider).recipes(id);
      if (!mounted) return;
      setState(() {
        _recipes = r;
        _recipesLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _recipesLoaded = true);
    }
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

  /// The implicit single variant [_blankItem] and [_save] create for items that
  /// have no real variants. Identified by id+empty-name rather than by "name is
  /// blank", so a user-added variant stays visible before it's named.
  static bool _isSentinelVariant(Variant v) => v.id == 'reg' && v.name.isEmpty;

  /// Set once a save is blocked, so fields only turn red after the admin has
  /// actually tried to save — not while they're still filling the form in.
  bool _showErrors = false;

  List<Variant> get _realVariants =>
      _draft.variants.where((v) => !_isSentinelVariant(v)).toList();

  /// Every name that must be filled before the item can be saved. A blank name
  /// is unusable downstream: it can't be shown on a chip, a ticket, or the KDS.
  bool get _hasBlankNames =>
      _name.text.trim().isEmpty ||
      _realVariants.any((v) => v.name.trim().isEmpty) ||
      _draft.modifierGroups.any(
        (g) =>
            g.name.trim().isEmpty ||
            g.options.any((o) => o.name.trim().isEmpty),
      );

  /// Returns false when the save did not land, so the footer skips its success
  /// tick instead of flashing a green check over a failure.
  Future<bool> _save() async {
    if (_hasBlankNames) {
      setState(() => _showErrors = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi nama yang masih kosong')),
      );
      return false;
    }
    final priceCents =
        int.tryParse(_basePrice.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final costCents =
        int.tryParse(_cost.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    // Blank (or unparseable) clears the override back to inherit.
    final prep = int.tryParse(_prep.text.trim());
    final variants = _draft.variants.isEmpty
        ? [Variant(id: 'reg', name: '', price: priceCents)]
        : [
            for (final v in _draft.variants)
              v.id == 'reg' && v.name.isEmpty
                  ? v.copyWith(price: priceCents)
                  : v,
          ];
    final saved = _draft.copyWith(
      name: _name.text.trim(),
      description: _desc.text.trim(),
      basePrice: priceCents,
      cost: costCents,
      prepTime: prep,
      clearPrepTime: prep == null,
      variants: variants,
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
      // Recipe lines need an existing owner row, so they follow the item.
      if (_recipesLoaded) {
        await ref.read(stockApiProvider).saveRecipes(saved.id, _recipes);
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      return false;
    }
    if (wasNew) {
      ref.read(menuAdminSelectedItemIdProvider.notifier).state = saved.id;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(wasNew ? 'Item ditambahkan' : 'Perubahan tersimpan'),
      ),
    );
    widget.onClose?.call();
    return true;
  }

  void _delete() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.sat.bg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: SatR.c(24)),
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
                    decoration: SatBox.d(
                      color: sc.border1,
                      borderRadius: SatR.a(2),
                    ),
                  ),
                ),
                const SizedBox(height: Sp.s4h),
                Text(
                  'Hapus item?',
                  style: SatType.sans(
                    size: 16,
                    weight: FontWeight.w600,
                    color: sc.textHi,
                  ),
                ),
                const SizedBox(height: Sp.s2),
                Text(
                  'Item "${_draft.name}" akan dihapus dari menu.',
                  style: SatType.sans(size: 13, color: sc.textMd, height: 1.4),
                ),
                const SizedBox(height: Sp.s4h),
                Row(
                  children: [
                    Expanded(
                      child: SatButton.outline(
                        label: AppStrings.cancel,
                        onTap: () => Navigator.pop(ctx, false),
                      ),
                    ),
                    const SizedBox(width: Sp.s2h),
                    Expanded(
                      child: SatButton.danger(
                        label: AppStrings.delete,
                        onTap: () => Navigator.pop(ctx, true),
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
              // 'Edit lengkap' carried no information; the availability badge
              // takes its place. Staff keep the sub line, since it's the only
              // thing explaining why every field is inert (ADR-0046).
              sub: readOnly ? 'Hanya admin yang bisa edit' : null,
              badge: _availabilityBadge(sc),
              onClose: widget.onClose,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, section) in [
                      _availabilitySection(sc),
                      _identitySection(sc, cats, readOnly),
                      _pricingSection(sc, readOnly),
                      _modifiersSection(sc, readOnly),
                      _recipeSection(sc, readOnly),
                      _tagsSection(sc, readOnly),
                    ].indexed) ...[
                      if (i > 0) const SizedBox(height: Sp.s4h),
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

  Widget _identitySection(
    SatColors sc,
    List<MenuCategory> cats,
    bool readOnly,
  ) {
    return _Section(
      title: 'Identitas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _photoSlot(sc, readOnly),
              const SizedBox(width: Sp.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _input(
                      _name,
                      'Nama item',
                      readOnly: readOnly,
                      error: _errorIfBlank(_name.text),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: Sp.s2h),
                    _input(
                      _desc,
                      'Deskripsi singkat',
                      maxLines: 3,
                      readOnly: readOnly,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s3),
          _label('Kategori'),
          const SizedBox(height: Sp.s1h),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in cats)
                _chipChoice(
                  label: c.name,
                  selected: _draft.categoryId == c.id,
                  onTap: readOnly
                      ? null
                      : () => _patch(_draft.copyWith(categoryId: c.id)),
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
    final radius = SatR.a(14);
    Widget preview;
    String sig;
    if (_pendingPhoto != null) {
      sig = 'pending:${_pendingPhoto!.length}';
      preview = ClipRRect(
        borderRadius: radius,
        child: Image.memory(
          _pendingPhoto!,
          fit: BoxFit.cover,
          width: 92,
          height: 92,
          gaplessPlayback: true,
        ),
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
      duration: satMotion(context, 240),
      switchInCurve: satEaseOut,
      switchOutCurve: satEaseOut,
      child: KeyedSubtree(key: ValueKey(sig), child: preview),
    );
    return GestureDetector(
      onTap: readOnly ? null : _showPhotoSheet,
      child: Stack(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: SatBox.d(
              border: SatB.all(color: sc.border1),
              borderRadius: radius,
            ),
            child: preview,
          ),
          if (!readOnly)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.s1h,
                  vertical: Sp.sHair,
                ),
                decoration: SatBox.d(
                  color: satMediaScrim,
                  borderRadius: BorderRadius.only(
                    topLeft: SatR.c(8),
                    bottomRight: SatR.c(13),
                  ),
                ),
                child: Text(
                  _hasPhotoNow ? 'UBAH' : 'FOTO',
                  style: SatType.mono(
                    size: 8,
                    weight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: onFill(satMediaScrim),
                  ),
                ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: SatR.c(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Sp.s3),
            Container(
              width: 40,
              height: 4,
              decoration: SatBox.d(color: sc.border1, borderRadius: SatR.a(2)),
            ),
            const SizedBox(height: Sp.s2),
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
                title: Text(
                  'Hapus foto',
                  style: SatType.sans(color: sc.urgent),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _pendingPhoto = null;
                    _pendingPhotoClear = true;
                  });
                  _commitPhotoIfExisting();
                },
              ),
            const SizedBox(height: Sp.s2),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat foto: $e')));
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
              Expanded(
                child: _input(
                  _basePrice,
                  'Harga dasar',
                  keyboard: TextInputType.number,
                  amount: true,
                  readOnly: readOnly,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: Sp.s3),
              Expanded(
                child: _input(
                  _prep,
                  // Empty field reads as what it inherits, so a blank is never
                  // mistaken for "no target" (ADR-0043).
                  'Ikut venue '
                  '(${ref.watch(venueSettingsProvider).prepTargetMins}m)',
                  label: 'Waktu siap (menit)',
                  keyboard: TextInputType.number,
                  readOnly: readOnly,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s2h),
          Row(
            children: [
              Expanded(
                child: _input(
                  _cost,
                  'HPP',
                  keyboard: TextInputType.number,
                  amount: true,
                  readOnly: readOnly,
                  // Recipe-derived cost sits *below* the field, not in the
                  // hint, so it stays readable next to the number it's meant
                  // to be checked against (ADR-0040).
                  helper: _derivedCostHelper(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: Sp.s3),
              Expanded(child: _marginPreview(sc)),
            ],
          ),
          const SizedBox(height: Sp.s3h),
          _subhead(
            'Varian ukuran',
            trailing: readOnly
                ? null
                : _ghostButton('+ Varian', onTap: _addVariant),
          ),
          const SizedBox(height: Sp.s1h),
          ExpandFade(
            child: _realVariants.isEmpty
                ? Text(
                    'Belum ada varian. Hanya pakai harga dasar.',
                    key: const ValueKey('var-empty'),
                    style: SatType.sans(size: 12, color: sc.textLo),
                  )
                : AnimatedReflow(
                    key: const ValueKey('var-list'),
                    child: Column(
                      children: [
                        for (var i = 0; i < _draft.variants.length; i++)
                          if (!_isSentinelVariant(_draft.variants[i]))
                            KeyedSubtree(
                              key: ValueKey('v:${_draft.variants[i].id}'),
                              child: _variantRow(sc, i, readOnly),
                            ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _variantRow(SatColors sc, int idx, bool readOnly) {
    final v = _draft.variants[idx];
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s2),
      child: Row(
        children: [
          Expanded(
            child: SatField.text(
              controller: _ctrl('v:${v.id}:name', v.name),
              hint: 'Nama (mis. Besar)',
              readOnly: readOnly,
              errorText: _errorIfBlank(v.name),
              // setState, not a bare assign: the recipe scope chips are built
              // from these names and must repaint as they're typed.
              onChanged: (t) => setState(() {
                final next = List<Variant>.of(_draft.variants);
                next[idx] = next[idx].copyWith(name: t);
                _draft = _draft.copyWith(variants: next);
              }),
            ),
          ),
          const SizedBox(width: Sp.s2h),
          SizedBox(
            width: 140,
            child: SatField.money(
              controller: _ctrl(
                'v:${v.id}:price',
                v.price == 0 ? '' : groupRupiah(v.price),
              ),
              hint: 'Harga',
              readOnly: readOnly,
              onChanged: (t) => setState(() {
                final n = int.tryParse(t.replaceAll(RegExp(r'\D'), '')) ?? 0;
                final next = List<Variant>.of(_draft.variants);
                next[idx] = next[idx].copyWith(price: n);
                _draft = _draft.copyWith(variants: next);
              }),
            ),
          ),
          if (!readOnly)
            IconButton(
              tooltip: AppStrings.delete,
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
    // No seeded name or price — the row renders regardless (it isn't the
    // sentinel), so the admin sees the hints before filling anything in.
    final next = List<Variant>.of(_draft.variants)
      ..add(Variant(id: id, name: '', price: 0));
    _patch(_draft.copyWith(variants: next));
  }

  Widget _modifiersSection(SatColors sc, bool readOnly) {
    return _Section(
      title: 'Grup modifier',
      trailing: readOnly
          ? null
          : _ghostButton('+ Grup', onTap: _addModifierGroup),
      child: ExpandFade(
        child: _draft.modifierGroups.isEmpty
            ? Text(
                'Belum ada grup modifier (mis. tingkat pedas, pilih protein).',
                key: const ValueKey('mod-empty'),
                style: SatType.sans(size: 12, color: sc.textLo),
              )
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
      ..add(
        ModifierGroup(
          id: id,
          name: '',
          options: [ModifierOption(id: oid, name: '')],
        ),
      );
    _patch(_draft.copyWith(modifierGroups: next));
  }

  Widget _modifierGroupCard(SatColors sc, int gi, bool readOnly) {
    final g = _draft.modifierGroups[gi];
    return Container(
      margin: const EdgeInsets.only(bottom: Sp.s3),
      decoration: SatBox.d(
        border: SatB.all(color: sc.border1),
        borderRadius: SatR.a(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SatField.text(
                  controller: _ctrl('g:${g.id}:name', g.name),
                  hint: 'Nama grup',
                  readOnly: readOnly,
                  errorText: _errorIfBlank(g.name),
                  onChanged: (t) => setState(() {
                    final next = List<ModifierGroup>.of(_draft.modifierGroups);
                    next[gi] = next[gi].copyWith(name: t);
                    _draft = _draft.copyWith(modifierGroups: next);
                  }),
                ),
              ),
              if (!readOnly)
                IconButton(
                  tooltip: AppStrings.delete,
                  icon: Icon(Icons.delete_outline, size: 18, color: sc.textLo),
                  onPressed: () {
                    final next = List<ModifierGroup>.of(_draft.modifierGroups)
                      ..removeAt(gi);
                    _patch(_draft.copyWith(modifierGroups: next));
                  },
                ),
            ],
          ),
          const SizedBox(height: Sp.s1h),
          Row(
            children: [
              _toggleChip(
                label: 'Wajib',
                on: g.required,
                onTap: readOnly
                    ? null
                    : () {
                        final next = List<ModifierGroup>.of(
                          _draft.modifierGroups,
                        );
                        next[gi] = next[gi].copyWith(required: !g.required);
                        _patch(_draft.copyWith(modifierGroups: next));
                      },
              ),
              const SizedBox(width: Sp.s2),
              _toggleChip(
                label: 'Pilih banyak',
                on: g.multi,
                onTap: readOnly
                    ? null
                    : () {
                        final next = List<ModifierGroup>.of(
                          _draft.modifierGroups,
                        );
                        next[gi] = next[gi].copyWith(multi: !g.multi);
                        _patch(_draft.copyWith(modifierGroups: next));
                      },
              ),
            ],
          ),
          const SizedBox(height: Sp.s2h),
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
              child: _ghostButton(
                '+ Opsi',
                onTap: () {
                  final opts = List<ModifierOption>.of(g.options)
                    ..add(
                      ModifierOption(
                        id: 'o${const Uuid().v4().substring(0, 6)}',
                        name: '',
                      ),
                    );
                  final next = List<ModifierGroup>.of(_draft.modifierGroups);
                  next[gi] = next[gi].copyWith(options: opts);
                  _patch(_draft.copyWith(modifierGroups: next));
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _optionRow(SatColors sc, int gi, int oi, bool readOnly) {
    final g = _draft.modifierGroups[gi];
    final o = g.options[oi];
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s1h),
      child: Row(
        children: [
          Expanded(
            child: SatField.text(
              controller: _ctrl('o:${g.id}:${o.id}:name', o.name),
              hint: 'Nama opsi',
              readOnly: readOnly,
              errorText: _errorIfBlank(o.name),
              onChanged: (t) => setState(() {
                final opts = List<ModifierOption>.of(g.options);
                opts[oi] = opts[oi].copyWith(name: t);
                final next = List<ModifierGroup>.of(_draft.modifierGroups);
                next[gi] = next[gi].copyWith(options: opts);
                _draft = _draft.copyWith(modifierGroups: next);
              }),
            ),
          ),
          const SizedBox(width: Sp.s2),
          SizedBox(
            // Wide enough for the 'Rp ' prefix plus a signed five-digit delta.
            width: 140,
            child: SatField.money(
              controller: _ctrl(
                'o:${g.id}:${o.id}:price',
                o.priceDelta == 0
                    ? ''
                    : o.priceDelta < 0
                    ? '-${groupRupiah(-o.priceDelta)}'
                    : groupRupiah(o.priceDelta),
              ),
              hint: '+/-',
              signed: true,
              readOnly: readOnly,
              onChanged: (t) => setState(() {
                final neg = t.trimLeft().startsWith('-');
                final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
                final n = (int.tryParse(digits) ?? 0) * (neg ? -1 : 1);
                final opts = List<ModifierOption>.of(g.options);
                opts[oi] = opts[oi].copyWith(priceDelta: n);
                final next = List<ModifierGroup>.of(_draft.modifierGroups);
                next[gi] = next[gi].copyWith(options: opts);
                _draft = _draft.copyWith(modifierGroups: next);
              }),
            ),
          ),
          if (!readOnly)
            IconButton(
              tooltip: AppStrings.delete,
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

  // ------------------------------------------------------------ resep

  List<RecipeLine> _linesFor(String scope) {
    if (scope.startsWith('v:')) {
      return _recipes.byVariant[scope.substring(2)] ?? const [];
    }
    if (scope.startsWith('o:')) {
      return _recipes.byOption[scope.substring(2)] ?? const [];
    }
    return _recipes.base;
  }

  void _setLines(String scope, List<RecipeLine> lines) {
    setState(() {
      if (scope.startsWith('v:')) {
        final next = Map<String, List<RecipeLine>>.of(_recipes.byVariant);
        if (lines.isEmpty) {
          next.remove(scope.substring(2));
        } else {
          next[scope.substring(2)] = lines;
        }
        _recipes = ItemRecipes(
          base: _recipes.base,
          byVariant: next,
          byOption: _recipes.byOption,
        );
      } else if (scope.startsWith('o:')) {
        final next = Map<String, List<RecipeLine>>.of(_recipes.byOption);
        if (lines.isEmpty) {
          next.remove(scope.substring(2));
        } else {
          next[scope.substring(2)] = lines;
        }
        _recipes = ItemRecipes(
          base: _recipes.base,
          byVariant: _recipes.byVariant,
          byOption: next,
        );
      } else {
        _recipes = ItemRecipes(
          base: lines,
          byVariant: _recipes.byVariant,
          byOption: _recipes.byOption,
        );
      }
    });
  }

  /// Σ(qty × moving-average cost) for the base configuration. Shown *beside*
  /// the manual `cost` field, never replacing it — a partially authored recipe
  /// understates cost and would silently overstate margin (ADR-0040).
  int _derivedCost(List<Ingredient> pantry) {
    final by = {for (final i in pantry) i.id: i};
    var total = 0;
    for (final l in _recipes.base) {
      final ing = by[l.ingredientId];
      if (ing != null) total += valueOf(l.qty, ing.costMicro);
    }
    return total;
  }

  Widget _recipeSection(SatColors sc, bool readOnly) {
    final pantry = ref.watch(ingredientsProvider);
    return _Section(
      title: 'Resep',
      child: pantry.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: Sp.s3),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => Text(
          'Gagal memuat bahan: $e',
          style: SatType.sans(size: 12, color: sc.urgent),
        ),
        data: (list) => list.isEmpty
            ? Text(
                'Belum ada bahan. Tambahkan di menu Stok sebelum menyusun resep.',
                style: SatType.sans(size: 12, color: sc.textLo),
              )
            : _recipeBody(sc, readOnly, list),
      ),
    );
  }

  Widget _recipeBody(SatColors sc, bool readOnly, List<Ingredient> pantry) {
    final byId = {for (final i in pantry) i.id: i};
    final scopes = <(String, String)>[
      ('', 'Dasar'),
      for (final v in _draft.variants)
        if (v.name.isNotEmpty) ('v:${v.id}', v.name),
      for (final g in _draft.modifierGroups)
        if (g.name.isNotEmpty)
          for (final o in g.options)
            // Both halves required, or a half-typed group yields a chip
            // reading ': Pedas'. The chip appears on the first keystroke.
            if (o.name.isNotEmpty) ('o:${o.id}', '${g.name}: ${o.name}'),
    ];
    if (!scopes.any((s) => s.$1 == _recipeScope)) _recipeScope = '';
    final lines = _linesFor(_recipeScope);
    final isVariant = _recipeScope.startsWith('v:');
    final isOption = _recipeScope.startsWith('o:');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in scopes)
              _toggleChip(
                label: _linesFor(s.$1).isEmpty ? s.$2 : '${s.$2} ·',
                on: _recipeScope == s.$1,
                onTap: () => setState(() => _recipeScope = s.$1),
              ),
          ],
        ),
        const SizedBox(height: Sp.s2),
        Text(
          isVariant
              ? 'Resep varian menggantikan resep dasar sepenuhnya. Kosong = ikut resep dasar.'
              : isOption
              ? 'Resep modifier ditambahkan di atas resep yang berlaku.'
              : 'Dipakai saat item tidak punya varian, atau varian belum punya resep sendiri.',
          style: SatType.sans(size: 11, color: sc.textLo),
        ),
        const SizedBox(height: Sp.s2h),
        if (lines.isEmpty)
          Text(
            'Belum ada bahan pada resep ini.',
            style: SatType.sans(size: 12, color: sc.textLo),
          ),
        for (var i = 0; i < lines.length; i++)
          _recipeLineRow(sc, readOnly, pantry, byId, lines, i),
        if (!readOnly) ...[
          const SizedBox(height: Sp.s1h),
          Align(
            alignment: Alignment.centerLeft,
            child: SatButton.ghost(
              label: 'Tambah bahan',
              icon: Icons.add,
              onTap: () => _setLines(_recipeScope, [
                ...lines,
                RecipeLine(
                  id: '',
                  ingredientId: pantry.first.id,
                  qty: pantry.first.unit.perUnit,
                ),
              ]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _recipeLineRow(
    SatColors sc,
    bool readOnly,
    List<Ingredient> pantry,
    Map<String, Ingredient> byId,
    List<RecipeLine> lines,
    int i,
  ) {
    final line = lines[i];
    final ing = byId[line.ingredientId] ?? pantry.first;
    final ctrlKey = 'recipe-$_recipeScope-$i';
    final ctrl = _ctrl(ctrlKey, _trimNum(ing.unit.fromBase(line.qty)));
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SatDropdown<String>(
              value: ing.id,
              hint: 'Bahan',
              options: [
                for (final p in pantry)
                  SatOption(p.id, '${p.name} (${p.unit.label})'),
              ],
              onChanged: readOnly
                  ? null
                  : (v) {
                      if (v == null) return;
                      final next = List<RecipeLine>.of(lines);
                      final target = byId[v]!;
                      // Units are per-ingredient, so re-read the typed amount
                      // against the new one rather than carrying milli-base
                      // across dimensions.
                      final typed =
                          double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 1;
                      next[i] = RecipeLine(
                        id: line.id,
                        ingredientId: v,
                        qty: target.unit.toBase(typed),
                      );
                      _setLines(_recipeScope, next);
                    },
            ),
          ),
          const SizedBox(width: Sp.s2),
          Expanded(
            flex: 2,
            // Unit as a suffix, not a hint: a hint vanishes the moment a
            // number is typed, which is exactly when "g or kg?" matters.
            child: SatField.decimal(
              controller: ctrl,
              hint: 'Jumlah',
              suffixText: ing.unit.label,
              readOnly: readOnly,
              onChanged: (t) {
                final v = double.tryParse(t.replaceAll(',', '.'));
                if (v == null) return;
                final next = List<RecipeLine>.of(lines);
                next[i] = RecipeLine(
                  id: line.id,
                  ingredientId: line.ingredientId,
                  qty: ing.unit.toBase(v),
                );
                _setLines(_recipeScope, next);
              },
            ),
          ),
          if (!readOnly)
            IconButton(
              tooltip: 'Hapus',
              icon: Icon(Icons.close, size: 18, color: sc.textLo),
              onPressed: () {
                _subCtrls.remove(ctrlKey)?.dispose();
                _setLines(
                  _recipeScope,
                  List<RecipeLine>.of(lines)..removeAt(i),
                );
              },
            ),
        ],
      ),
    );
  }

  static String _trimNum(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
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
          const SizedBox(height: Sp.s1h),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in allergens)
                _toggleChip(
                  label: t.name,
                  on: _draft.allergens.contains(t.id),
                  onTap: readOnly
                      ? null
                      : () {
                          final set = List<String>.of(_draft.allergens);
                          set.contains(t.id) ? set.remove(t.id) : set.add(t.id);
                          _patch(_draft.copyWith(allergens: set));
                        },
                ),
            ],
          ),
          const SizedBox(height: Sp.s3),
          _label('Diet'),
          const SizedBox(height: Sp.s1h),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in diets)
                _toggleChip(
                  label: t.name,
                  on: _draft.dietary.contains(t.id),
                  onTap: readOnly
                      ? null
                      : () {
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
              // One word for "cannot be sold", cause in the parenthetical —
              // ADR-0046.
              auto
                  ? 'Tidak tersedia (stok 0)'
                  : (_draft.unavailable
                        ? 'Tidak tersedia (manual)'
                        : 'Aktif untuk dijual'),
              style: SatType.sans(
                size: 14,
                weight: FontWeight.w600,
                color: _draft.isSoldOut ? sc.urgent : sc.success,
              ),
            ),
          ),
          adminToggle(context, on: !_draft.isSoldOut),
          const SizedBox(width: Sp.s1h),
          SatButton.ghost(
            label: _draft.unavailable ? 'Aktifkan' : 'Tandai tidak tersedia',
            onTap: auto
                ? null
                : () =>
                      _patch(_draft.copyWith(unavailable: !_draft.unavailable)),
          ),
        ],
      ),
    );
  }

  /// Read-only status pill for the header. The control itself lives in the
  /// Ketersediaan section — this only reports, so there's nothing to mistrust.
  Widget _availabilityBadge(SatColors sc) {
    final out = _draft.isSoldOut;
    final tone = out ? sc.urgent : sc.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s2, vertical: 3),
      decoration: SatBox.d(
        color: tone.withValues(alpha: 0.14),
        borderRadius: SatR.a(6),
      ),
      child: Text(
        out ? 'Tidak tersedia' : 'Aktif',
        style: SatType.sans(size: 11, weight: FontWeight.w600, color: tone),
      ),
    );
  }

  /// `≈ Rp 12.400 dari resep dasar`, or null when there is no base recipe.
  /// Sits under the HPP field rather than replacing it: a partially authored
  /// recipe understates cost and would silently overstate margin (ADR-0040).
  String? _derivedCostHelper() {
    if (_recipes.base.isEmpty) return null;
    final pantry = ref.watch(ingredientsProvider).valueOrNull;
    if (pantry == null) return null;
    return '≈ ${formatIDR(_derivedCost(pantry))} dari resep dasar';
  }

  // ---- shared field bits -----------------------------------------------

  String? _errorIfBlank(String value) =>
      _showErrors && value.trim().isEmpty ? 'Wajib diisi' : null;

  /// The editor's fields, in the app's one input skin. Kept as a local helper
  /// only because every one of them shares `readOnly` and the blank-check.
  Widget _input(
    TextEditingController c,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboard,
    bool readOnly = false,
    bool amount = false,
    ValueChanged<String>? onChanged,
    String? label,
    String? error,
    String? helper,
  }) {
    if (amount) {
      return SatField.money(
        controller: c,
        hint: hint,
        label: label,
        readOnly: readOnly,
        errorText: error,
        helperText: helper,
        onChanged: onChanged,
      );
    }
    if (keyboard == TextInputType.number) {
      return SatField.number(
        controller: c,
        hint: hint,
        label: label,
        readOnly: readOnly,
        errorText: error,
        helperText: helper,
        onChanged: onChanged,
      );
    }
    return SatField.text(
      controller: c,
      hint: hint,
      label: label,
      maxLines: maxLines,
      readOnly: readOnly,
      errorText: error,
      helperText: helper,
      onChanged: onChanged,
    );
  }

  Widget _marginPreview(SatColors sc) {
    final price =
        int.tryParse(_basePrice.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
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
      duration: satMotion(context, 240),
      curve: satEaseOut,
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2h),
      decoration: SatBox.d(
        color: tone.withValues(alpha: 0.08),
        border: SatB.all(color: tone.withValues(alpha: 0.3)),
        borderRadius: SatR.a(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MARGIN',
            style: SatType.mono(
              size: 9,
              weight: FontWeight.w600,
              letterSpacing: 1.0,
              color: sc.textLo,
            ),
          ),
          const SizedBox(height: Sp.s1),
          AnimatedDefaultTextStyle(
            duration: satMotion(context, 240),
            style: SatType.sans(size: 18, weight: FontWeight.w600, color: tone),
            child: hasData
                ? AnimatedCount(
                    value: marginPct.round(),
                    duration: const Duration(milliseconds: 360),
                    builder: (_, v) => Text('$v%'),
                  )
                : const Text('—'),
          ),
          const SizedBox(height: Sp.sHair),
          Text(
            hasData ? 'Rp $marginRp · $hint' : hint,
            style: SatType.sans(size: 11, color: sc.textMd),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) {
    final sc = context.sat;
    return Text(
      t.toUpperCase(),
      style: SatType.mono(
        size: 10,
        weight: FontWeight.w600,
        letterSpacing: 1.0,
        color: sc.textLo,
      ),
    );
  }

  Widget _subhead(String t, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(child: _label(t)),
        ?trailing,
      ],
    );
  }

  Widget _chipChoice({
    required String label,
    required bool selected,
    VoidCallback? onTap,
  }) {
    final sc = context.sat;
    return PressScale(
      pressedScale: onTap == null ? 1.0 : 0.95,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: satMotion(context, 200),
          curve: satEaseOut,
          padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: 7),
          decoration: SatBox.d(
            color: selected ? sc.accentSoft : sc.bg2,
            border: SatB.all(color: selected ? sc.accentBorder : sc.border1),
            borderRadius: SatR.a(999),
          ),
          child: AnimatedDefaultTextStyle(
            duration: satMotion(context, 200),
            style: SatType.sans(
              size: 12,
              weight: FontWeight.w500,
              color: selected ? sc.accentText : sc.textMd,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool on,
    VoidCallback? onTap,
  }) {
    final sc = context.sat;
    return PressScale(
      pressedScale: onTap == null ? 1.0 : 0.95,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: satMotion(context, 200),
          curve: satEaseOut,
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s2h,
            vertical: Sp.s1h,
          ),
          decoration: SatBox.d(
            color: on ? sc.successSoft : sc.bg2,
            border: SatB.all(color: on ? sc.success : sc.border1),
            borderRadius: SatR.a(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: satMotion(context, 200),
                curve: satEaseOut,
                width: 6,
                height: 6,
                decoration: SatBox.d(
                  color: on ? sc.success : sc.textLo,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Sp.s1h),
              AnimatedDefaultTextStyle(
                duration: satMotion(context, 200),
                style: SatType.sans(
                  size: 11,
                  weight: FontWeight.w500,
                  color: on ? sc.success : sc.textMd,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ghostButton(String t, {required VoidCallback onTap}) {
    return SatButton.ghost(label: t, onTap: onTap);
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
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(14),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: SatType.mono(
                    size: 10,
                    weight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: sc.textLo,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: Sp.s3),
          child,
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;

  /// Null for admins — the availability badge takes the line instead. Staff
  /// keep it, since it explains why the form is inert (ADR-0046).
  final String? sub;
  final Widget? badge;
  final VoidCallback? onClose;
  const _Header({required this.title, this.sub, this.badge, this.onClose});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 16, 14),
      decoration: SatBox.d(
        border: Border(bottom: SatB.side(color: sc.border0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SatType.sans(
                    size: 22,
                    weight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: sc.textHi,
                  ),
                ),
                const SizedBox(height: Sp.s1),
                Row(
                  children: [
                    ?badge,
                    if (badge != null && sub != null)
                      const SizedBox(width: Sp.s2),
                    if (sub != null)
                      Flexible(
                        child: Text(
                          sub!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SatType.mono(
                            size: 11,
                            color: sc.textLo,
                            letterSpacing: 0.66,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              tooltip: AppStrings.close,
              icon: Icon(Icons.close, color: sc.textMd),
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatefulWidget {
  final Future<bool> Function() onSave;
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
    var ok = false;
    try {
      ok = await widget.onSave();
    } catch (_) {
      // Errors surface via snackbar in onSave; just reset the button.
    }
    if (!mounted) return;
    // A blocked or failed save must not flash a green check.
    if (!ok) {
      setState(() => _state = _SaveState.idle);
      return;
    }
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

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: SatBox.d(
        color: sc.bg1,
        border: Border(top: SatB.side(color: sc.border0)),
      ),
      child: Row(
        children: [
          if (widget.onDelete != null)
            PressScale(
              pressedScale: 0.96,
              child: SatButton.ghost(
                label: AppStrings.delete,
                icon: Icons.delete_outline,
                onTap: widget.onDelete,
              ),
            ),
          const Spacer(),
          PressScale(
            pressedScale: 0.96,
            // Done flips the variant rather than swapping a tick glyph in:
            // the whole control turning green is the confirmation, and it
            // survives a glance from arm's length that a 18px check does not.
            child: done
                ? SatButton.success(
                    label: AppStrings.saved,
                    icon: Icons.check_rounded,
                    onTap: null,
                  )
                : SatButton.primary(
                    label: AppStrings.save,
                    busy: saving,
                    onTap: _state == _SaveState.idle ? _run : null,
                  ),
          ),
        ],
      ),
    );
  }
}
