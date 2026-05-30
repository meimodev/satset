import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/admin/_common.dart';
import 'package:satset/ui/features/admin/menu_admin_item_editor.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/ui/features/admin/menu_admin_view_model.dart';

/// Two-tier menu admin screen.
/// - Tablet: master-detail (item list left, editor right).
/// - Phone: list only; tap pushes /menuadm/:id editor.
/// Staff sees read-only list with availability toggle; admin sees full edit.
class MenuAdminScreen extends ConsumerWidget {
  const MenuAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTab = context.layout.useTabletShell;
    return isTab ? const _TabletLayout() : const _PhoneLayout();
  }
}

// ============================================================
//  TABLET — master/detail
// ============================================================

class _TabletLayout extends ConsumerWidget {
  const _TabletLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final counts = ref.watch(menuAdminCountsProvider);
    final perm = ref.watch(menuPermissionProvider);
    final selectedId = ref.watch(menuAdminSelectedItemIdProvider);
    final tab = ref.watch(menuAdminTabProvider);
    final onCats = perm == MenuPermission.admin && tab == MenuAdminTab.categories;

    return Column(
      children: [
        AdminEmbeddedStrip(
          title: 'Menu',
          sub: '${counts.total} item · ${counts.categories} kategori · ${counts.eightySixed} habis',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (perm == MenuPermission.admin) ...[
                const _TabSwitcher(),
                const SizedBox(width: 10),
              ],
              _RoleBadge(perm: perm),
              if (perm == MenuPermission.admin && !onCats) ...[
                const SizedBox(width: 10),
                _PrimaryButton(
                  label: '+ Tambah item',
                  onTap: () => ref.read(menuAdminSelectedItemIdProvider.notifier).state = null,
                ),
              ],
            ],
          ),
        ),
        if (onCats)
          const Expanded(child: _CategoriesPanel())
        else
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: sc.border0)),
                    ),
                    child: const _ListPane(),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: selectedId == null && perm == MenuPermission.staff
                      ? const _EmptyDetail(staff: true)
                      : MenuAdminItemEditor(
                          key: ValueKey(selectedId ?? '__new__'),
                          itemId: selectedId,
                          onClose: () => ref
                              .read(menuAdminSelectedItemIdProvider.notifier)
                              .state = null,
                          onDeleted: () => ref
                              .read(menuAdminSelectedItemIdProvider.notifier)
                              .state = null,
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ListPane extends ConsumerWidget {
  const _ListPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _Toolbar(),
        _CategoryRail(),
        Expanded(child: _ItemList(compact: false)),
      ],
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  final bool staff;
  const _EmptyDetail({required this.staff});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      color: sc.bg1,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: sc.textLo),
          const SizedBox(height: 12),
          Text(
            staff ? 'Pilih item untuk lihat detail' : 'Pilih item atau tambah baru',
            style: SatType.sans(size: 14, color: sc.textMd),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            staff
                ? 'Mode staf: hanya tandai habis. Edit penuh hanya admin.'
                : 'Kelola harga, modifier, stok, dan ketersediaan.',
            style: SatType.sans(size: 12, color: sc.textLo),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  PHONE — list only
// ============================================================

class _PhoneLayout extends ConsumerWidget {
  const _PhoneLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final counts = ref.watch(menuAdminCountsProvider);
    final perm = ref.watch(menuPermissionProvider);
    final tab = ref.watch(menuAdminTabProvider);
    final onCats = perm == MenuPermission.admin && tab == MenuAdminTab.categories;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Menu',
                          style: SatType.sans(
                            size: 26, weight: FontWeight.w600,
                            letterSpacing: -0.5, color: sc.textHi,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        '${counts.total} item · ${counts.eightySixed} habis',
                        style: SatType.mono(
                          size: 11, color: sc.textLo, letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _RoleBadge(perm: perm),
              ],
            ),
          ),
          if (perm == MenuPermission.admin)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TabSwitcher(),
              ),
            ),
          if (onCats)
            const Expanded(child: _CategoriesPanel())
          else ...[
            const _Toolbar(),
            const _CategoryRail(),
            const Expanded(child: _ItemList(compact: true)),
          ],
        ],
      ),
    );
  }
}

// ============================================================
//  Shared bits
// ============================================================

class _Toolbar extends ConsumerStatefulWidget {
  const _Toolbar();

  @override
  ConsumerState<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends ConsumerState<_Toolbar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final perm = ref.watch(menuPermissionProvider);
    final isTab = context.layout.useTabletShell;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: sc.border0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: (t) =>
                  ref.read(menuAdminSearchProvider.notifier).state = t,
              style: SatType.sans(size: 13, color: sc.textHi),
              decoration: InputDecoration(
                hintText: 'Cari item, deskripsi…',
                hintStyle: SatType.sans(size: 13, color: sc.textLo),
                prefixIcon: Icon(Icons.search, size: 18, color: sc.textLo),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                filled: true,
                fillColor: sc.bg2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: sc.border1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: sc.border1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: sc.accent),
                ),
              ),
            ),
          ),
          if (!isTab && perm == MenuPermission.admin) ...[
            const SizedBox(width: 8),
            _PrimaryButton(
              label: '+ Item',
              onTap: () => context.push('/menuadm/new'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRail extends ConsumerWidget {
  const _CategoryRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final cats = ref.watch(menuRealCategoriesProvider);
    final selected = ref.watch(menuAdminCategoryFilterProvider);
    final items = ref.watch(menuItemsProvider);

    int count(String catId) =>
        catId == 'all' ? items.length : items.where((i) => i.categoryId == catId).length;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: sc.border0)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _catChip(context, ref, 'all', 'Semua', count('all'), selected == 'all'),
          for (final c in cats) ...[
            _catChip(context, ref, c.id, c.name, count(c.id), selected == c.id),
          ],
        ],
      ),
    );
  }

  Widget _catChip(BuildContext context, WidgetRef ref, String id, String name, int n, bool on) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: GestureDetector(
        onTap: () => ref.read(menuAdminCategoryFilterProvider.notifier).state = id,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on ? sc.accentSoft : sc.bg2,
            border: Border.all(color: on ? sc.accentBorder : sc.border1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  style: SatType.sans(
                    size: 12,
                    weight: FontWeight.w500,
                    color: on ? sc.accent : sc.textMd,
                  )),
              const SizedBox(width: 6),
              Text('$n',
                  style: SatType.mono(
                    size: 10,
                    weight: FontWeight.w600,
                    color: on ? sc.accent : sc.textLo,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemList extends ConsumerWidget {
  /// Compact mode is used in the phone layout (single-column with chevron).
  final bool compact;
  const _ItemList({required this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(menuAdminFilteredItemsProvider);
    final sc = context.sat;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'Tidak ada item cocok.',
            style: SatType.sans(size: 13, color: sc.textLo),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => _ItemRow(item: items[i], compact: compact),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  final MenuItem item;
  final bool compact;
  const _ItemRow({required this.item, required this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final perm = ref.watch(menuPermissionProvider);
    final selectedId = ref.watch(menuAdminSelectedItemIdProvider);
    final isSelected = selectedId == item.id && !compact;

    final disabled = item.isEightySixed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (compact) {
              context.push('/menuadm/${item.id}');
            } else {
              ref.read(menuAdminSelectedItemIdProvider.notifier).state = item.id;
            }
          },
          onLongPress: perm == MenuPermission.admin
              ? () => ref
                  .read(menuRepositoryProvider.notifier)
                  .toggleAvailability(item.id)
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? sc.accentSoft : sc.bg2,
              border: Border.all(
                color: isSelected ? sc.accentBorder : sc.border0,
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(
              children: [
                _thumb(sc),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: SatType.sans(
                          size: 14,
                          weight: FontWeight.w600,
                          color: disabled ? sc.textLo : sc.textHi,
                          letterSpacing: -0.14,
                        ).copyWith(
                          decoration:
                              disabled ? TextDecoration.lineThrough : null,
                          decorationColor: sc.textLo,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            formatIDR(item.basePrice),
                            style: SatType.mono(
                              size: 11,
                              weight: FontWeight.w600,
                              color: sc.textMd,
                            ),
                          ),
                          if (item.stockCount != null) ...[
                            Text(' · ',
                                style: SatType.mono(size: 10, color: sc.textDim)),
                            Text('Stok ${item.stockCount}',
                                style: SatType.mono(
                                  size: 10,
                                  color: item.stockCount! == 0
                                      ? sc.urgent
                                      : sc.textLo,
                                  letterSpacing: 0.4,
                                )),
                          ],
                        ],
                      ),
                      if (!compact && (item.allergens.isNotEmpty || item.dietary.isNotEmpty)) ...[
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 3, runSpacing: 3,
                          children: [
                            for (final a in item.allergens)
                              _miniBadge(sc, allergenCodes[a] ?? '', sc.warnSoft, sc.warn),
                            for (final d in item.dietary)
                              _miniBadge(sc, dietaryCodes[d] ?? '', sc.infoSoft, sc.info),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusToggle(item: item, perm: perm),
                if (compact)
                  Icon(Icons.chevron_right, color: sc.textLo, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumb(SatColors sc) {
    final letter = item.name.isEmpty ? '?' : item.name.substring(0, 1);
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: sc.bg3,
        border: Border.all(color: sc.border1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(letter.toUpperCase(),
          style: SatType.sans(
            size: 16,
            weight: FontWeight.w600,
            color: sc.textMd,
          )),
    );
  }

  Widget _miniBadge(SatColors sc, String t, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(t,
          style: SatType.mono(
            size: 9, weight: FontWeight.w600,
            letterSpacing: 0.4, color: fg,
          )),
    );
  }
}

class _StatusToggle extends ConsumerWidget {
  final MenuItem item;
  final MenuPermission perm;
  const _StatusToggle({required this.item, required this.perm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final auto = item.autoEightySixed;
    final canToggle = !auto;
    return GestureDetector(
      onTap: canToggle
          ? () => ref
              .read(menuRepositoryProvider.notifier)
              .toggleAvailability(item.id)
          : null,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: item.isEightySixed ? sc.urgentSoft : sc.successSoft,
          border: Border.all(color: item.isEightySixed ? sc.urgent : sc.success),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: item.isEightySixed ? sc.urgent : sc.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              auto ? 'AUTO 86' : (item.unavailable ? '86\'D' : 'AKTIF'),
              style: SatType.mono(
                size: 10,
                weight: FontWeight.w600,
                letterSpacing: 0.8,
                color: item.isEightySixed ? sc.urgent : sc.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Material(
      color: sc.accent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(label,
              style: SatType.sans(
                size: 12, weight: FontWeight.w600,
                color: sc.accentInk,
              )),
        ),
      ),
    );
  }
}

class _TabSwitcher extends ConsumerWidget {
  const _TabSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final tab = ref.watch(menuAdminTabProvider);
    Widget seg(String label, MenuAdminTab value) {
      final on = tab == value;
      return GestureDetector(
        onTap: () => ref.read(menuAdminTabProvider.notifier).state = value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: on ? sc.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: SatType.sans(
                size: 12,
                weight: FontWeight.w600,
                color: on ? sc.accentInk : sc.textMd,
              )),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: sc.bg3,
        border: Border.all(color: sc.border1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('Item', MenuAdminTab.items),
          seg('Kategori', MenuAdminTab.categories),
        ],
      ),
    );
  }
}

class _CategoriesPanel extends ConsumerWidget {
  const _CategoriesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final cats = ref.watch(menuRealCategoriesProvider);
    final counts = ref.watch(menuCategoryItemCountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: cats.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final ids = [for (final c in cats) c.id];
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              ref.read(menuRepositoryProvider.notifier).reorderCategories(ids);
            },
            itemBuilder: (ctx, i) {
              final c = cats[i];
              final n = counts[c.id] ?? 0;
              return Padding(
                key: ValueKey(c.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: sc.bg2,
                    border: Border.all(color: sc.border0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: i,
                        child: Icon(Icons.drag_handle, size: 20, color: sc.textLo),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(c.name,
                            style: SatType.sans(
                              size: 14, weight: FontWeight.w600, color: sc.textHi,
                            )),
                      ),
                      Text('$n item',
                          style: SatType.mono(
                            size: 11, color: sc.textLo, letterSpacing: 0.4,
                          )),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 18, color: sc.textMd),
                        onPressed: () => _rename(context, ref, c.id, c.name),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18,
                            color: n > 0 ? sc.textDim : sc.urgent),
                        onPressed: () => _delete(context, ref, c.id, c.name, n),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _PrimaryButton(
              label: '+ Tambah kategori',
              onTap: () => _add(context, ref),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final name = await _nameDialog(context, title: 'Kategori baru', initial: '');
    if (name == null || name.trim().isEmpty) return;
    await ref.read(menuRepositoryProvider.notifier).createCategory(name.trim());
  }

  Future<void> _rename(
      BuildContext context, WidgetRef ref, String id, String current) async {
    final name =
        await _nameDialog(context, title: 'Ubah nama kategori', initial: current);
    if (name == null || name.trim().isEmpty || name.trim() == current) return;
    await ref
        .read(menuRepositoryProvider.notifier)
        .renameCategory(id, name.trim());
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id,
      String name, int count) async {
    final messenger = ScaffoldMessenger.of(context);
    if (count > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text('Pindahkan $count item dulu sebelum hapus "$name"')),
      );
      return;
    }
    try {
      await ref.read(menuRepositoryProvider.notifier).deleteCategory(id);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal hapus kategori — masih dipakai item')),
      );
    }
  }

  Future<String?> _nameDialog(BuildContext context,
      {required String title, required String initial}) {
    final ctrl = TextEditingController(text: initial);
    final sc = context.sat;
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: sc.bg1,
        title: Text(title, style: SatType.sans(size: 16, color: sc.textHi)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: SatType.sans(size: 14, color: sc.textHi),
          decoration: const InputDecoration(hintText: 'Nama kategori'),
          onSubmitted: (t) => Navigator.pop(ctx, t),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Simpan')),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final MenuPermission perm;
  const _RoleBadge({required this.perm});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final isAdmin = perm == MenuPermission.admin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAdmin ? sc.accentSoft : sc.bg3,
        border: Border.all(color: isAdmin ? sc.accentBorder : sc.border1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAdmin ? 'ADMIN' : 'STAF · TANDAI HABIS',
        style: SatType.mono(
          size: 10, weight: FontWeight.w600,
          letterSpacing: 0.8, color: isAdmin ? sc.accent : sc.textMd,
        ),
      ),
    );
  }
}
