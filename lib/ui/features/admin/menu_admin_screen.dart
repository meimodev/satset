import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/menu_tag.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/widgets/menu_photo.dart';
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
    final admin = perm == MenuPermission.admin;
    final onCats = admin && tab == MenuAdminTab.categories;
    final onTags = admin && tab == MenuAdminTab.tags;

    return Column(
      children: [
        AdminEmbeddedStrip(
          title: 'Menu',
          sub:
              '${counts.total} item · ${counts.categories} kategori · ${counts.soldOut} tidak tersedia',
          // Add sits leftmost so the tabs and badge hold position when it
          // disappears on the Kategori / Tag tabs (ADR-0046 UI pass).
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (admin && !onCats && !onTags) ...[
                _PrimaryButton(
                  label: '+ Tambah item',
                  onTap: () =>
                      ref.read(menuAdminSelectedItemIdProvider.notifier).state =
                          null,
                ),
                const SizedBox(width: 10),
              ],
              if (admin) ...[const _TabSwitcher(), const SizedBox(width: 10)],
              _RoleBadge(perm: perm),
            ],
          ),
        ),
        Expanded(
          child: _TabFade(
            tabKey: onCats ? 'cats' : (onTags ? 'tags' : 'items'),
            child: onCats
                ? const _CategoriesPanel()
                : onTags
                ? const _TagsPanel()
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: sc.border0),
                            ),
                          ),
                          child: const _ListPane(),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        // Crossfade + soft slide when the selected item
                        // changes, so the detail pane swaps instead of
                        // hard-cutting between items.
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: kSatEase,
                          switchOutCurve: kSatEase,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0.012, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topCenter,
                            children: [...previous, ?current],
                          ),
                          child:
                              selectedId == null && perm == MenuPermission.staff
                              ? const _EmptyDetail(
                                  key: ValueKey('__empty__'),
                                  staff: true,
                                )
                              : MenuAdminItemEditor(
                                  key: ValueKey(selectedId ?? '__new__'),
                                  itemId: selectedId,
                                  onClose: () =>
                                      ref
                                              .read(
                                                menuAdminSelectedItemIdProvider
                                                    .notifier,
                                              )
                                              .state =
                                          null,
                                  onDeleted: () =>
                                      ref
                                              .read(
                                                menuAdminSelectedItemIdProvider
                                                    .notifier,
                                              )
                                              .state =
                                          null,
                                ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Crossfade + soft vertical slide between the Item / Kategori / Tag panels.
/// [tabKey] identifies the active panel; changing it triggers the transition.
class _TabFade extends StatelessWidget {
  final String tabKey;
  final Widget child;
  const _TabFade({required this.tabKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: kSatEase,
      switchOutCurve: kSatEase,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.015),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(tabKey), child: child),
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
  const _EmptyDetail({super.key, required this.staff});

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
            staff
                ? 'Pilih item untuk lihat detail'
                : 'Pilih item atau tambah baru',
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
    final admin = perm == MenuPermission.admin;
    final onCats = admin && tab == MenuAdminTab.categories;
    final onTags = admin && tab == MenuAdminTab.tags;

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
                      Text(
                        'Menu',
                        style: SatType.sans(
                          size: 26,
                          weight: FontWeight.w600,
                          letterSpacing: -0.5,
                          color: sc.textHi,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${counts.total} item · ${counts.soldOut} tidak tersedia',
                        style: SatType.mono(
                          size: 11,
                          color: sc.textLo,
                          letterSpacing: 0.5,
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
          Expanded(
            child: _TabFade(
              tabKey: onCats ? 'cats' : (onTags ? 'tags' : 'items'),
              child: onCats
                  ? const _CategoriesPanel()
                  : onTags
                  ? const _TagsPanel()
                  : const Column(
                      children: [
                        _Toolbar(),
                        _CategoryRail(),
                        Expanded(child: _ItemList(compact: true)),
                      ],
                    ),
            ),
          ),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
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

    int count(String catId) => catId == 'all'
        ? items.length
        : items.where((i) => i.categoryId == catId).length;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: sc.border0)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _catChip(
            context,
            ref,
            'all',
            'Semua',
            count('all'),
            selected == 'all',
          ),
          for (final c in cats) ...[
            _catChip(context, ref, c.id, c.name, count(c.id), selected == c.id),
          ],
        ],
      ),
    );
  }

  Widget _catChip(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
    int n,
    bool on,
  ) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: PressScale(
        pressedScale: 0.93,
        child: GestureDetector(
          onTap: () =>
              ref.read(menuAdminCategoryFilterProvider.notifier).state = id,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: kSatEase,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: on ? sc.accentSoft : sc.bg2,
              border: Border.all(color: on ? sc.accentBorder : sc.border1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: SatType.sans(
                    size: 12,
                    weight: FontWeight.w500,
                    color: on ? sc.accent : sc.textMd,
                  ),
                  child: Text(name),
                ),
                const SizedBox(width: 6),
                AnimatedCount(
                  value: n,
                  builder: (_, v) => Text(
                    '$v',
                    style: SatType.mono(
                      size: 10,
                      weight: FontWeight.w600,
                      color: on ? sc.accent : sc.textLo,
                    ),
                  ),
                ),
              ],
            ),
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
    final cat = ref.watch(menuAdminCategoryFilterProvider);
    final search = ref.watch(menuAdminSearchProvider);
    final sc = context.sat;

    final Widget body = items.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                'Tidak ada item cocok.',
                style: SatType.sans(size: 13, color: sc.textLo),
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: items.length,
            itemBuilder: (_, i) => Reveal(
              index: i.clamp(0, 11),
              animKey: items[i].id,
              child: _ItemRow(item: items[i], compact: compact),
            ),
          );

    // Crossfade the whole list when the active filter changes; rows that have
    // already entered won't re-cascade (Reveal keys on item id).
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: kSatEase,
      switchOutCurve: kSatEase,
      child: KeyedSubtree(key: ValueKey('$cat|$search'), child: body),
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

    final disabled = item.isSoldOut;
    final tagsById = ref.watch(menuTagsByIdProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: PressScale(
        pressedScale: 0.985,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (compact) {
                context.push('/menuadm/${item.id}');
              } else {
                ref.read(menuAdminSelectedItemIdProvider.notifier).state =
                    item.id;
              }
            },
            onLongPress: perm == MenuPermission.admin
                ? () => ref
                      .read(menuRepositoryProvider.notifier)
                      .toggleAvailability(item.id)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: kSatEase,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              SatType.sans(
                                size: 14,
                                weight: FontWeight.w600,
                                color: disabled ? sc.textLo : sc.textHi,
                                letterSpacing: -0.14,
                              ).copyWith(
                                decoration: disabled
                                    ? TextDecoration.lineThrough
                                    : null,
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
                            // Auto-habis is derived from ingredient stock, so
                            // the card shows the verdict, not a count (ADR-0040).
                            if (item.autoSoldOut) ...[
                              Text(
                                ' · ',
                                style: SatType.mono(
                                  size: 10,
                                  color: sc.textDim,
                                ),
                              ),
                              Text(
                                'Bahan habis',
                                style: SatType.mono(
                                  size: 10,
                                  color: sc.urgent,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ] else if (item.soldOutVariantIds.isNotEmpty) ...[
                              Text(
                                ' · ',
                                style: SatType.mono(
                                    size: 10, color: sc.textDim),
                              ),
                              Text(
                                '${item.soldOutVariantIds.length} varian habis',
                                style: SatType.mono(
                                  size: 10,
                                  color: sc.warn,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!compact &&
                            (item.allergens.isNotEmpty ||
                                item.dietary.isNotEmpty)) ...[
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 3,
                            runSpacing: 3,
                            children: [
                              for (final a in item.allergens)
                                _miniBadge(
                                  sc,
                                  tagsById[a]?.code ?? '',
                                  sc.warnSoft,
                                  sc.warn,
                                ),
                              for (final d in item.dietary)
                                _miniBadge(
                                  sc,
                                  tagsById[d]?.code ?? '',
                                  sc.infoSoft,
                                  sc.info,
                                ),
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
      ),
    );
  }

  Widget _thumb(SatColors sc) {
    final radius = BorderRadius.circular(8);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: sc.bg3,
        border: Border.all(color: sc.border1),
        borderRadius: radius,
      ),
      child: MenuPhoto(
        itemId: item.id,
        name: item.name,
        photoRev: item.photoRev,
        borderRadius: radius,
        initialsSize: 16,
      ),
    );
  }

  Widget _miniBadge(SatColors sc, String t, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        t,
        style: SatType.mono(
          size: 9,
          weight: FontWeight.w600,
          letterSpacing: 0.4,
          color: fg,
        ),
      ),
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
    final auto = item.isAutoSoldOut;
    final canToggle = !auto;
    final out = item.isSoldOut;
    final fg = out ? sc.urgent : sc.success;
    final label = auto ? 'AUTO HABIS' : (item.unavailable ? 'HABIS' : 'AKTIF');
    return PressScale(
      pressedScale: canToggle ? 0.94 : 1.0,
      child: GestureDetector(
        onTap: canToggle
            ? () => ref
                  .read(menuRepositoryProvider.notifier)
                  .toggleAvailability(item.id)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: kSatEase,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: out ? sc.urgentSoft : sc.successSoft,
            border: Border.all(color: fg),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: kSatEase,
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: kSatEase,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: SatType.mono(
                    size: 10,
                    weight: FontWeight.w600,
                    letterSpacing: 0.8,
                    height: 1.0,
                    color: fg,
                  ).copyWith(leadingDistribution: TextLeadingDistribution.even),
                ),
              ),
            ],
          ),
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
    return PressScale(
      pressedScale: 0.95,
      child: Material(
        color: sc.accent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              label,
              style: SatType.sans(
                size: 12,
                weight: FontWeight.w600,
                color: sc.accentInk,
              ),
            ),
          ),
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
      return PressScale(
        pressedScale: 0.95,
        child: GestureDetector(
          onTap: () => ref.read(menuAdminTabProvider.notifier).state = value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: kSatEase,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: on ? sc.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: SatType.sans(
                size: 12,
                weight: FontWeight.w600,
                color: on ? sc.accentInk : sc.textMd,
              ),
              child: Text(label),
            ),
          ),
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
          seg('Tag', MenuAdminTab.tags),
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
                child: Reveal(
                  index: i.clamp(0, 11),
                  animKey: 'cat:${c.id}',
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
                          child: Icon(
                            Icons.drag_handle,
                            size: 20,
                            color: sc.textLo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.name,
                            style: SatType.sans(
                              size: 14,
                              weight: FontWeight.w600,
                              color: sc.textHi,
                            ),
                          ),
                        ),
                        Text(
                          '$n item',
                          style: SatType.mono(
                            size: 11,
                            color: sc.textLo,
                            letterSpacing: 0.4,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: sc.textMd,
                          ),
                          onPressed: () => _rename(context, ref, c.id, c.name),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: n > 0 ? sc.textDim : sc.urgent,
                          ),
                          onPressed: () =>
                              _delete(context, ref, c.id, c.name, n),
                        ),
                      ],
                    ),
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
    final name = await _nameDialog(
      context,
      title: 'Kategori baru',
      initial: '',
    );
    if (name == null || name.trim().isEmpty) return;
    await ref.read(menuRepositoryProvider.notifier).createCategory(name.trim());
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    String id,
    String current,
  ) async {
    final name = await _nameDialog(
      context,
      title: 'Ubah nama kategori',
      initial: current,
    );
    if (name == null || name.trim().isEmpty || name.trim() == current) return;
    await ref
        .read(menuRepositoryProvider.notifier)
        .renameCategory(id, name.trim());
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
    int count,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (count > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Pindahkan $count item dulu sebelum hapus "$name"'),
        ),
      );
      return;
    }
    try {
      await ref.read(menuRepositoryProvider.notifier).deleteCategory(id);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal hapus kategori — masih dipakai item'),
        ),
      );
    }
  }

  Future<String?> _nameDialog(
    BuildContext context, {
    required String title,
    required String initial,
  }) {
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _TagsPanel extends ConsumerWidget {
  const _TagsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(menuTagsProvider);
    final allergens = menuTagsOfKind(all, MenuTagKind.allergen);
    final diets = menuTagsOfKind(all, MenuTagKind.diet);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _group(context, ref, 'Alergen', MenuTagKind.allergen, allergens),
        const SizedBox(height: 20),
        _group(context, ref, 'Diet', MenuTagKind.diet, diets),
      ],
    );
  }

  Widget _group(
    BuildContext context,
    WidgetRef ref,
    String title,
    MenuTagKind kind,
    List<MenuTag> tags,
  ) {
    final sc = context.sat;
    final tint = kind == MenuTagKind.allergen ? sc.warn : sc.info;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: SatType.sans(
              size: 13,
              weight: FontWeight.w600,
              color: sc.textMd,
            ),
          ),
        ),
        for (final (i, t) in tags.indexed)
          Padding(
            key: ValueKey(t.id),
            padding: const EdgeInsets.only(bottom: 8),
            child: Reveal(
              index: i.clamp(0, 11),
              animKey: 'tag:${t.id}',
              child: Container(
                decoration: BoxDecoration(
                  color: sc.bg2,
                  border: Border.all(color: sc.border0),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t.code,
                        style: SatType.mono(
                          size: 10,
                          weight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: tint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.name,
                        style: SatType.sans(
                          size: 14,
                          weight: FontWeight.w600,
                          color: sc.textHi,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: sc.textMd,
                      ),
                      onPressed: () => _edit(context, ref, t),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: sc.urgent,
                      ),
                      onPressed: () => _delete(context, ref, t),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: _PrimaryButton(
            label: '+ Tambah ${title.toLowerCase()}',
            onTap: () => _edit(context, ref, null, kind: kind),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    MenuTag? tag, {
    MenuTagKind? kind,
  }) async {
    final result = await _tagDialog(context, tag);
    if (result == null) return;
    final notifier = ref.read(menuRepositoryProvider.notifier);
    if (tag == null) {
      await notifier.createTag(kind!, result.$1, result.$2);
    } else {
      await notifier.updateTag(tag.id, name: result.$1, code: result.$2);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, MenuTag tag) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.sat.bg1,
        title: Text(
          'Hapus "${tag.name}"?',
          style: SatType.sans(size: 16, color: context.sat.textHi),
        ),
        content: Text(
          'Tag ini akan dilepas dari semua item yang memakainya.',
          style: SatType.sans(size: 13, color: context.sat.textMd),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(menuRepositoryProvider.notifier).deleteTag(tag.id);
    messenger.showSnackBar(SnackBar(content: Text('"${tag.name}" dihapus')));
  }

  /// Returns (name, code) or null if cancelled.
  Future<(String, String)?> _tagDialog(BuildContext context, MenuTag? tag) {
    final nameCtrl = TextEditingController(text: tag?.name ?? '');
    final codeCtrl = TextEditingController(text: tag?.code ?? '');
    final sc = context.sat;
    return showDialog<(String, String)>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: sc.bg1,
        title: Text(
          tag == null ? 'Tag baru' : 'Ubah tag',
          style: SatType.sans(size: 16, color: sc.textHi),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: SatType.sans(size: 14, color: sc.textHi),
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeCtrl,
                maxLength: 3,
                textCapitalization: TextCapitalization.characters,
                style: SatType.sans(size: 14, color: sc.textHi),
                decoration: const InputDecoration(
                  labelText: 'Kode badge',
                  hintText: 'GL',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final n = nameCtrl.text.trim();
              if (n.isEmpty) return;
              Navigator.pop(ctx, (n, codeCtrl.text.trim().toUpperCase()));
            },
            child: const Text('Simpan'),
          ),
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
          size: 10,
          weight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isAdmin ? sc.accent : sc.textMd,
        ),
      ),
    );
  }
}
