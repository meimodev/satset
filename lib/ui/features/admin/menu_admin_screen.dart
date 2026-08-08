import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_tabs.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
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
import 'package:satset/ui/features/admin/widgets/kill_reason_sheet.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/ui/features/admin/menu_admin_view_model.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';

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
          title: context.l10n.mnaTitle,
          sub: context.l10n.mnaHeaderSub(
            counts.total,
            counts.categories,
            counts.soldOut,
          ),
          // Add sits leftmost so the tabs and badge hold position when it
          // disappears on the Kategori / Tag tabs (ADR-0046 UI pass).
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (admin && !onCats && !onTags) ...[
                SatButton.primary(
                  size: SatButtonSize.sm,
                  label: context.l10n.mnaAddItem,
                  onTap: () =>
                      ref.read(menuAdminSelectedItemIdProvider.notifier).state =
                          null,
                ),
                const SizedBox(width: Sp.s2h),
              ],
              if (admin) ...[
                const _TabSwitcher(),
                const SizedBox(width: Sp.s2h),
              ],
              _MenuRoleChip(perm: perm),
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
                          decoration: SatBox.d(
                            border: Border(right: SatB.side(color: sc.border0)),
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
                          duration: satMotion(context, 240),
                          switchInCurve: satEaseOut,
                          switchOutCurve: satEaseOut,
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
      duration: satMotion(context, 240),
      switchInCurve: satEaseOut,
      switchOutCurve: satEaseOut,
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
      padding: const EdgeInsets.all(Sp.s8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: sc.textLo),
          const SizedBox(height: Sp.s3),
          Text(
            staff ? context.l10n.mnaPickStaff : context.l10n.mnaPickAdmin,
            style: SatType.bodyM(color: sc.textMd),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Sp.s1h),
          Text(
            staff ? context.l10n.mnaPickStaffSub : context.l10n.mnaPickAdminSub,
            style: SatType.bodyS(color: sc.textLo),
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
                        context.l10n.mnaTitle,
                        style: SatType.h2(color: sc.textHi),
                      ),
                      const SizedBox(height: Sp.sHair),
                      Text(
                        context.l10n.mnaPhoneSub(counts.total, counts.soldOut),
                        style: SatType.monoS(color: sc.textLo),
                      ),
                    ],
                  ),
                ),
                _MenuRoleChip(perm: perm),
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
      decoration: SatBox.d(
        border: Border(bottom: SatB.side(color: sc.border0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SatField.search(
              controller: _ctrl,
              hint: context.l10n.mnaSearchHint,
              onChanged: (t) =>
                  ref.read(menuAdminSearchProvider.notifier).state = t,
            ),
          ),
          if (!isTab && perm == MenuPermission.admin) ...[
            const SizedBox(width: Sp.s2),
            SatButton.primary(
              size: SatButtonSize.sm,
              label: context.l10n.mnaAddItemShort,
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
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3),
      decoration: SatBox.d(
        border: Border(bottom: SatB.side(color: sc.border0)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _catChip(
            context,
            ref,
            'all',
            context.l10n.mnaAll,
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
      padding: const EdgeInsets.symmetric(horizontal: Sp.s1, vertical: Sp.s2h),
      child: PressScale(
        pressedScale: 0.93,
        child: GestureDetector(
          onTap: () =>
              ref.read(menuAdminCategoryFilterProvider.notifier).state = id,
          child: AnimatedContainer(
            duration: satMotion(context, 200),
            curve: satEaseOut,
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.s3,
              vertical: Sp.s1h,
            ),
            decoration: SatBox.d(
              color: on ? sc.accentSoft : sc.bg2,
              border: SatB.all(color: on ? sc.accentBorder : sc.border1),
              borderRadius: SatR.a(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: satMotion(context, 200),
                  style: SatType.bodyS(color: on ? sc.accentText : sc.textMd),
                  child: Text(name),
                ),
                const SizedBox(width: Sp.s1h),
                AnimatedCount(
                  value: n,
                  builder: (_, v) => Text(
                    '$v',
                    style: SatType.caption(
                      color: on ? sc.accentText : sc.textLo,
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
              padding: const EdgeInsets.all(Sp.s7),
              child: Text(
                context.l10n.mnaNoMatch,
                style: SatType.bodyM(color: sc.textLo),
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: items.length,
            itemBuilder: (_, i) => Reveal(
              index: i.clamp(0, 11),
              animKey: items[i].id,
              child: _MenuItemRow(item: items[i], compact: compact),
            ),
          );

    // Crossfade the whole list when the active filter changes; rows that have
    // already entered won't re-cascade (Reveal keys on item id).
    return AnimatedSwitcher(
      duration: satMotion(context, 220),
      switchInCurve: satEaseOut,
      switchOutCurve: satEaseOut,
      child: KeyedSubtree(key: ValueKey('$cat|$search'), child: body),
    );
  }
}

class _MenuItemRow extends ConsumerWidget {
  final MenuItem item;
  final bool compact;
  const _MenuItemRow({required this.item, required this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final perm = ref.watch(menuPermissionProvider);
    final selectedId = ref.watch(menuAdminSelectedItemIdProvider);
    final isSelected = selectedId == item.id && !compact;

    final disabled = item.isSoldOut;
    final tagsById = ref.watch(menuTagsByIdProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Sp.s1,
        horizontal: Sp.sHair,
      ),
      child: PressScale(
        pressedScale: 0.985,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: SatR.a(12),
            onTap: () {
              if (compact) {
                context.push('/menuadm/${item.id}');
              } else {
                ref.read(menuAdminSelectedItemIdProvider.notifier).state =
                    item.id;
              }
            },
            onLongPress: perm == MenuPermission.admin
                ? () => _toggleAvailability(context, ref, item)
                : null,
            child: AnimatedContainer(
              duration: satMotion(context, 200),
              curve: satEaseOut,
              decoration: SatBox.d(
                color: isSelected ? sc.accentSoft : sc.bg2,
                border: SatB.all(
                  color: isSelected ? sc.accentBorder : sc.border0,
                  width: isSelected ? 1.5 : 1,
                ),
                borderRadius: SatR.a(12),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  _thumb(sc),
                  const SizedBox(width: Sp.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              SatType.labelM(
                                color: disabled ? sc.textLo : sc.textHi,
                              ).copyWith(
                                decoration: disabled
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: sc.textLo,
                              ),
                        ),
                        const SizedBox(height: Sp.s1),
                        Row(
                          children: [
                            Text(
                              formatIDR(item.basePrice),
                              style: SatType.caption(color: sc.textMd),
                            ),
                            // Auto-habis is derived from ingredient stock, so
                            // the card shows the verdict, not a count (ADR-0040).
                            if (item.autoSoldOut) ...[
                              Text(
                                ' · ',
                                style: SatType.monoS(color: sc.textDim),
                              ),
                              Text(
                                context.l10n.mnaIngredientsOut,
                                style: SatType.monoS(color: sc.urgent),
                              ),
                            ] else if (item.soldOutVariantIds.isNotEmpty) ...[
                              Text(
                                ' · ',
                                style: SatType.monoS(color: sc.textDim),
                              ),
                              Text(
                                context.l10n.mnaVariantsOut(
                                  item.soldOutVariantIds.length,
                                ),
                                style: SatType.monoS(color: sc.warn),
                              ),
                            ],
                          ],
                        ),
                        if (!compact &&
                            (item.allergens.isNotEmpty ||
                                item.dietary.isNotEmpty)) ...[
                          const SizedBox(height: Sp.s1h),
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
                  const SizedBox(width: Sp.s2),
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
    final radius = SatR.a(8);
    return Container(
      width: 42,
      height: 42,
      decoration: SatBox.d(
        color: sc.bg3,
        border: SatB.all(color: sc.border1),
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
      padding: const EdgeInsets.symmetric(
        horizontal: Sp.s1h,
        vertical: Sp.sHair,
      ),
      decoration: SatBox.d(color: bg, borderRadius: SatR.a(4)),
      child: Text(t, style: SatType.caption(color: fg)),
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
    final label = auto
        ? context.l10n.mnaAutoOut
        : (item.unavailable ? context.l10n.mnaOut : context.l10n.mnaOn);
    return PressScale(
      pressedScale: canToggle ? 0.94 : 1.0,
      child: GestureDetector(
        onTap: canToggle ? () => _toggleAvailability(context, ref, item) : null,
        child: AnimatedContainer(
          duration: satMotion(context, 220),
          curve: satEaseOut,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: Sp.s2h),
          alignment: Alignment.center,
          decoration: SatBox.d(
            color: out ? sc.urgentSoft : sc.successSoft,
            border: SatB.all(color: fg),
            borderRadius: SatR.a(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: satMotion(context, 220),
                curve: satEaseOut,
                width: 6,
                height: 6,
                decoration: SatBox.d(color: fg, shape: BoxShape.circle),
              ),
              const SizedBox(width: Sp.s1h),
              AnimatedSwitcher(
                duration: satMotion(context, 200),
                switchInCurve: satEaseOut,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: SatType.caption(
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

/// The menu admin's three panes. A [SatTabs] strip bound to the tab provider.
class _TabSwitcher extends ConsumerWidget {
  const _TabSwitcher();

  static const _order = [
    MenuAdminTab.items,
    MenuAdminTab.categories,
    MenuAdminTab.tags,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(menuAdminTabProvider);
    return SatTabs(
      tabs: [
        SatTab(label: context.l10n.mnaTabItems),
        SatTab(label: context.l10n.mnaTabCategories),
        SatTab(label: context.l10n.mnaTabTags),
      ],
      selected: _order.indexOf(tab),
      onSelected: (i) =>
          ref.read(menuAdminTabProvider.notifier).state = _order[i],
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
                padding: const EdgeInsets.only(bottom: Sp.s2),
                child: Reveal(
                  index: i.clamp(0, 11),
                  animKey: 'cat:${c.id}',
                  child: Container(
                    decoration: SatBox.d(
                      color: sc.bg2,
                      border: SatB.all(color: sc.border0),
                      borderRadius: SatR.a(12),
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
                        const SizedBox(width: Sp.s2h),
                        Expanded(
                          child: Text(
                            c.name,
                            style: SatType.labelM(color: sc.textHi),
                          ),
                        ),
                        Text(
                          context.l10n.mnaItemCount(n),
                          style: SatType.monoS(color: sc.textLo),
                        ),
                        IconButton(
                          tooltip: context.l10n.a11yRename,
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: sc.textMd,
                          ),
                          onPressed: () => _rename(context, ref, c.id, c.name),
                        ),
                        IconButton(
                          tooltip: context.l10n.delete,
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
            child: SatButton.primary(
              size: SatButtonSize.sm,
              label: context.l10n.mnaAddCategory,
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
      title: context.l10n.mnaNewCategory,
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
      title: context.l10n.mnaRenameCategory,
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
    final l10n = context.l10n;
    if (count > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.mnaMoveItemsFirst(count, name))),
      );
      return;
    }
    try {
      await ref.read(menuRepositoryProvider.notifier).deleteCategory(id);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.mnaCategoryInUse)));
    }
  }

  Future<String?> _nameDialog(
    BuildContext context, {
    required String title,
    required String initial,
  }) {
    final ctrl = TextEditingController(text: initial);
    final sc = context.sat;
    return showSatDialog<String>(
      context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sc.bg1,
        title: Text(title, style: SatType.bodyL(color: sc.textHi)),
        content: SatField.text(
          controller: ctrl,
          hint: context.l10n.mnaCategoryNameHint,
          autofocus: true,
          onSubmitted: (t) => Navigator.pop(ctx, t),
        ),
        actions: [
          SatButton.ghost(
            label: context.l10n.cancel,
            onTap: () => Navigator.pop(ctx),
          ),
          SatButton.primary(
            label: context.l10n.save,
            onTap: () => Navigator.pop(ctx, ctrl.text),
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
        _group(
          context,
          ref,
          context.l10n.mieAllergens,
          MenuTagKind.allergen,
          allergens,
        ),
        const SizedBox(height: Sp.s5),
        _group(context, ref, context.l10n.mieDiet, MenuTagKind.diet, diets),
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
          padding: const EdgeInsets.only(left: Sp.s1, bottom: Sp.s2),
          child: Text(title, style: SatType.labelM(color: sc.textMd)),
        ),
        for (final (i, t) in tags.indexed)
          Padding(
            key: ValueKey(t.id),
            padding: const EdgeInsets.only(bottom: Sp.s2),
            child: Reveal(
              index: i.clamp(0, 11),
              animKey: 'tag:${t.id}',
              child: Container(
                decoration: SatBox.d(
                  color: sc.bg2,
                  border: SatB.all(color: sc.border0),
                  borderRadius: SatR.a(12),
                ),
                padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sp.s1h,
                        vertical: Sp.sHair,
                      ),
                      decoration: SatBox.d(
                        color: tint.withValues(alpha: 0.12),
                        borderRadius: SatR.a(4),
                      ),
                      child: Text(t.code, style: SatType.caption(color: tint)),
                    ),
                    const SizedBox(width: Sp.s2h),
                    Expanded(
                      child: Text(
                        t.name,
                        style: SatType.labelM(color: sc.textHi),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.a11yEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: sc.textMd,
                      ),
                      onPressed: () => _edit(context, ref, t),
                    ),
                    IconButton(
                      tooltip: context.l10n.delete,
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
          child: SatButton.primary(
            size: SatButtonSize.sm,
            label: context.l10n.mnaAddThing(title.toLowerCase()),
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
    final l10n = context.l10n;
    final ok = await showSatDialog<bool>(
      context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.sat.bg1,
        title: Text(
          context.l10n.mnaDeleteTagTitle(tag.name),
          style: SatType.bodyL(color: context.sat.textHi),
        ),
        content: Text(
          context.l10n.mnaDeleteTagBody,
          style: SatType.bodyM(color: context.sat.textMd),
        ),
        actions: [
          SatButton.ghost(
            label: context.l10n.cancel,
            onTap: () => Navigator.pop(ctx, false),
          ),
          SatButton.primary(
            label: context.l10n.delete,
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(menuRepositoryProvider.notifier).deleteTag(tag.id);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.mnaTagDeleted(tag.name))),
    );
  }

  /// Returns (name, code) or null if cancelled.
  Future<(String, String)?> _tagDialog(BuildContext context, MenuTag? tag) {
    final nameCtrl = TextEditingController(text: tag?.name ?? '');
    final codeCtrl = TextEditingController(text: tag?.code ?? '');
    final sc = context.sat;
    return showSatDialog<(String, String)>(
      context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sc.bg1,
        title: Text(
          tag == null ? context.l10n.mnaNewTag : context.l10n.mnaEditTag,
          style: SatType.bodyL(color: sc.textHi),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SatField.text(
                controller: nameCtrl,
                label: context.l10n.mnaTagName,
                hint: '',
                autofocus: true,
              ),
              const SizedBox(height: Sp.s2),
              SatField.text(
                controller: codeCtrl,
                label: context.l10n.mnaTagCode,
                hint: 'GL',
                maxLength: 3,
                capitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        actions: [
          SatButton.ghost(
            label: context.l10n.cancel,
            onTap: () => Navigator.pop(ctx),
          ),
          SatButton.primary(
            label: context.l10n.save,
            onTap: () {
              final n = nameCtrl.text.trim();
              if (n.isEmpty) return;
              Navigator.pop(ctx, (n, codeCtrl.text.trim().toUpperCase()));
            },
          ),
        ],
      ),
    );
  }
}

/// Which of the two menu permissions the signed-in staffer holds. A hue choice
/// over [SatChip], not a chip of its own.
class _MenuRoleChip extends StatelessWidget {
  final MenuPermission perm;
  const _MenuRoleChip({required this.perm});

  @override
  Widget build(BuildContext context) {
    final isAdmin = perm == MenuPermission.admin;
    return SatChip.tag(
      label: isAdmin ? context.l10n.mnaRoleAdmin : context.l10n.mnaRoleStaff,
      hue: isAdmin ? SatChipHue.accent : SatChipHue.neutral,
      size: SatChipSize.sm,
    );
  }
}

/// Flip an item's sold-out state, asking why on the way *off* the menu.
///
/// Only the kill direction prompts: putting a dish back needs no
/// justification, and a second sheet there would be friction for its own sake.
/// The reason lands on the audit row (ADR-0072) — a manager reading "Burger
/// Wagyu stop jual" later wants the "out of brioche" beside it.
Future<void> _toggleAvailability(
  BuildContext context,
  WidgetRef ref,
  MenuItem item,
) async {
  final repo = ref.read(menuRepositoryProvider.notifier);
  if (item.unavailable) {
    await repo.toggleAvailability(item.id);
    return;
  }
  final reason = await showKillReasonSheet(context, itemName: item.name);
  // Null is a dismissal, '' is "no reason given" — only the former aborts.
  if (reason == null) return;
  await repo.toggleAvailability(
    item.id,
    reason: reason.isEmpty ? null : reason,
  );
}
