import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/shell_inset.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:uuid/uuid.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/ui/features/menu/view_models/cart_view_model.dart';
import 'package:satset/ui/features/menu/view_models/menu_view_model.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/widgets/menu_photo.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_icon_button.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart';
import 'package:satset/ui/core/widgets/tag_badge_row.dart';
import 'cart_line_actions.dart';
import 'modifier_sheet.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';

/// Height the floating cart footer covers, plus the gap above it. A scroll
/// view stacks this on `shellInset`: that one clears the tab bar, this one
/// clears the footer.
const double _cartFooterClearance = 80;

const _uuid = Uuid();

class MenuScreen extends ConsumerStatefulWidget {
  final String tableId;

  /// When true this is a table-less draft ([tableId] is a draft id / visit id,
  /// not a real table). The table is chosen at review/commit time (menu-first)
  /// or there is none (takeaway).
  final bool tableless;

  /// Set when adding items to an existing takeaway (Bawa pulang) visit:
  /// [tableId] is the takeaway visit id and submit appends to it. See ADR-0026.
  final String? takeawayVisitId;

  /// Set when this screen *is* a shell tab (the [[Kedai]] home, ADR-0109)
  /// rather than a page pushed on top of one. The shell already draws the top
  /// bar, and there is nothing above a home tab to go back to, so the phone
  /// layout's own bar would be a second bar with a dead arrow.
  final bool inShell;
  const MenuScreen({
    super.key,
    required this.tableId,
    this.tableless = false,
    this.takeawayVisitId,
    this.inShell = false,
  });

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  // 'all', not a category id: a venue whose menu has no category by that name
  // — or items filed under none — used to open on an empty grid.
  String _cat = 'all';
  final _search = TextEditingController();

  /// [[Menu populer]] rank, frozen at the first menu this screen sees
  /// (ADR-0113).
  ///
  /// Captured once, never re-read: `menuUpdated` fires on a stock flip, and a
  /// grid that re-sorts itself between the look and the tap is worse than a
  /// grid whose order is a minute stale. An item that arrives after that first
  /// snapshot is absent here and lands at the bottom, which is where an
  /// untraded item belongs.
  ///
  /// Not `initState`: the screen can mount while the menu is still loading, and
  /// freezing an empty map there would leave the grid alphabetical for the life
  /// of the order.
  Map<String, int>? _rank;

  @override
  void initState() {
    super.initState();
    // The provider is autoDispose, so this is normally ''. Seeding keeps the
    // field and the query in step if the provider outlived the last mount.
    _search.text = ref.read(menuSearchProvider);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Picking a category clears the query — a live query ignores the category
  /// entirely, so leaving it set would make the tap look like it did nothing.
  void _selectCategory(String id) {
    _clearSearch();
    setState(() => _cat = id);
  }

  void _clearSearch() {
    _search.clear();
    ref.read(menuSearchProvider.notifier).state = '';
  }

  /// Shared by both layouts — the phone strip and the tablet header slot. The
  /// [[Item bebas]] action rides here rather than in the grid: it is not a menu
  /// item and putting a tile among the tiles is how one gets tapped by mistake.
  Widget _searchField(String query) {
    final field = _searchBox(query);
    if (!ref.watch(authStateProvider).has(Capability.sellOpenItem)) {
      return field;
    }
    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: Sp.s2),
        SatIconButton.outline(
          icon: Icons.edit_note_outlined,
          tooltip: context.l10n.mnuOpenItem,
          onTap: _addOpenItem,
        ),
      ],
    );
  }

  Widget _searchBox(String query) => SatField.search(
    controller: _search,
    hint: context.l10n.mnaSearchHint,
    suffix: query.isEmpty
        ? null
        : SatIconButton.plain(
            icon: Icons.close,
            tooltip: context.l10n.hapusPencarian,
            onTap: _clearSearch,
            size: 32,
          ),
    onChanged: (t) => ref.read(menuSearchProvider.notifier).state = t,
  );

  /// Shown in place of the grid when a query matches nothing. An empty grid
  /// alone is indistinguishable from a failed menu load, which this screen
  /// already renders separately.
  ///
  /// Scrollable because this state only ever appears with the keyboard up —
  /// which leaves the slot the grid had roughly 90dp tall, less than the
  /// column needs. The grid itself scrolls for the same reason.
  Widget _noMatches(String query) => SingleChildScrollView(
    child: SatEmpty(
      icon: Icons.search_off,
      title: context.l10n.takAdaItemCocok,
      body: '“$query”',
      action: SatButton.outline(
        label: context.l10n.hapusPencarian,
        onTap: _clearSearch,
      ),
    ),
  );

  bool get _isTakeaway => widget.takeawayVisitId != null;
  String get _backFallback => _isTakeaway
      ? '/takeaway/${widget.takeawayVisitId}'
      : widget.tableless
      ? '/tables'
      : '/table/${widget.tableId}';
  String get _reviewLoc => _isTakeaway
      ? '/takeaway/${widget.takeawayVisitId}/review'
      : widget.tableless
      ? '/order/new/review'
      : '/table/${widget.tableId}/review';

  /// Leave the order flow, discarding whatever is in the cart.
  ///
  /// An unsent cart is invisible once you are off this screen — only the menu
  /// and review screens render it — so backing out strands items nobody can
  /// see or send. Leaving *is* the discard; confirm it when there is something
  /// to lose and pop straight through when there is not. See ADR-0061.
  Future<void> _handleBack() async {
    final cart = ref.read(cartProvider(widget.tableId));
    if (cart.isNotEmpty) {
      final ok = await _confirmDiscard(
        context,
        cart.fold<int>(0, (s, c) => s + c.qty),
      );
      if (ok != true) return;
      ref.read(cartProvider(widget.tableId).notifier).clear();
    }
    if (mounted) safePop(context, fallback: _backFallback);
  }

  @override
  Widget build(BuildContext context) {
    // canPop: false so the Android gesture / nav-bar back lands in the same
    // handler as the app-bar button — a waiter on gesture nav would otherwise
    // skip the guard entirely, which is the path that loses carts today.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    final cols = l.gridCount(minTileWidth: 170);
    final cart = ref.watch(cartProvider(widget.tableId));
    final tables = ref.watch(tablesProvider);
    final table = widget.tableless
        ? null
        : tables.firstWhere(
            (t) => t.id == widget.tableId,
            orElse: () => tables.isEmpty
                ? VenueTable(id: widget.tableId, zoneId: '')
                : tables.first,
          );

    final menuStatus = ref.watch(menuStatusProvider);
    final allItems = ref.watch(menuItemsProvider);
    final query = ref.watch(menuSearchProvider);
    if (_rank == null && allItems.isNotEmpty) {
      _rank = {
        for (final i in allItems)
          if (i.popQty > 0) i.id: i.popQty,
      };
    }
    final items = filterMenuItems(
      allItems,
      categoryId: _cat,
      query: query,
      rank: _rank,
    );
    // A live query ignores the category entirely, so the chip row is hidden
    // while searching rather than left showing a filter that is not applied.
    final searching = query.trim().isNotEmpty;
    final noMatches = items.isEmpty && searching;

    if (menuStatus.isLoading) {
      return Scaffold(
        backgroundColor: sc.bg0,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SatSpinner(),
              const SizedBox(height: Sp.s3),
              Text(
                context.l10n.tblLoadingMenu,
                style: SatType.bodyM(color: sc.textMd),
              ),
            ],
          ),
        ),
      );
    }
    if (menuStatus.hasError) {
      return Scaffold(
        backgroundColor: sc.bg0,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Sp.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 36, color: sc.urgent),
                const SizedBox(height: Sp.s3),
                Text(
                  context.l10n.mnuLoadFailed,
                  style: SatType.labelL(color: sc.textHi),
                ),
                const SizedBox(height: Sp.s1h),
                Text(
                  '${menuStatus.error}',
                  textAlign: TextAlign.center,
                  style: SatType.bodyS(color: sc.textLo),
                ),
                const SizedBox(height: Sp.s3h),
                SatButton.outline(
                  label: context.l10n.retry,
                  onTap: () =>
                      ref.read(menuRepositoryProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final cartCount = cart.fold<int>(0, (s, c) => s + c.qty);
    final cartTotal = cart.fold<int>(0, (s, c) => s + c.unitPrice * c.qty);
    final inCartQty = <String, int>{};
    for (final c in cart) {
      inCartQty[c.itemId] = (inCartQty[c.itemId] ?? 0) + c.qty;
    }

    if (l.useTabletShell) {
      return Scaffold(
        backgroundColor: sc.bg0,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
                    decoration: SatBox.d(
                      border: Border(bottom: SatB.side(color: sc.border0)),
                    ),
                    child: Row(
                      children: [
                        Semantics(
                          button: true,
                          label: context.l10n.back,
                          child: GestureDetector(
                            onTap: _handleBack,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: SatBox.d(
                                color: sc.bg2,
                                border: SatB.all(color: sc.border0),
                                borderRadius: SatR.a(10),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.arrow_back,
                                size: 18,
                                color: sc.textMd,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Sp.s3h),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.tableless
                                    ? (_isTakeaway
                                          ? context.l10n.mnuAddToTakeaway
                                          : context.l10n.mnuNewOrder)
                                    : context.l10n.mnuAddToTable(
                                        table!.displayName,
                                      ),
                                style: SatType.h3(color: sc.textHi),
                              ),
                              // No subtitle: zone and pax are already on the
                              // table screen this was pushed from, and the line
                              // was the only thing making this header two rows
                              // tall.
                            ],
                          ),
                        ),
                        SizedBox(width: 280, child: _searchField(query)),
                      ],
                    ),
                  ),
                  if (!searching)
                    Container(
                      padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
                      decoration: SatBox.d(
                        border: Border(bottom: SatB.side(color: sc.border0)),
                      ),
                      child: _CatTabs(active: _cat, onChange: _selectCategory),
                    ),
                  Expanded(
                    // The grid gets its own ground so a white card has an edge
                    // to sit against — see `satCardGround`, which only steps
                    // down on a light palette.
                    child: ColoredBox(
                      color: satCardGround(sc),
                      child: noMatches
                        ? _noMatches(query)
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final dynamicCols = l.responsiveColumns(
                                constraints.maxWidth,
                                minTileWidth: 175,
                              );
                              // .builder, not .count: `children:` builds every
                              // card in the category up front, and a real venue
                              // menu is not the seed's 42 items. Off-screen
                              // cards cost nothing here.
                              return GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: dynamicCols,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 0.70,
                                    ),
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  14,
                                  28,
                                  28,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, i) {
                                  final it = items[i];
                                  return _ItemCard(
                                    item: it,
                                    inCart: inCartQty[it.id] ?? 0,
                                    onTap: () => _openItem(it),
                                  );
                                },
                              );
                            },
                          ),
                    ),
                  ),
                ],
              ),
            ),
            _TabletCartPane(
              tableId: widget.tableId,
              tableless: widget.tableless,
              takeaway: _isTakeaway,
              onReview: () => context.push(_reviewLoc),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: sc.bg0,
      body: Stack(
        children: [
          Column(
            children: [
              if (!widget.inShell)
                SatAppBar(
                  onBack: _handleBack,
                  crumbs: widget.tableless
                      ? (_isTakeaway
                            ? [
                                context.l10n.crumbBawaPulang,
                                context.l10n.crumbTambahItem,
                              ]
                            : [
                                context.l10n.crumbPesananBaru,
                                context.l10n.crumbTambahItem,
                              ])
                      : [table!.displayName, context.l10n.crumbTambahItem],
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.mnuAddItem,
                      style: SatType.h1(color: sc.textHi),
                    ),
                    const SizedBox(height: Sp.s1),
                    Text(
                      context.l10n.mnuAddItemHint,
                      style: SatType.monoS(color: sc.textLo),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _searchField(query),
              ),
              if (!searching) ...[
                _CatTabs(active: _cat, onChange: _selectCategory),
                const SizedBox(height: Sp.s2),
              ],
              Expanded(
                child: ColoredBox(
                  color: satCardGround(sc),
                  child: noMatches
                    ? _noMatches(query)
                    : Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: l.contentMaxWidth,
                          ),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.74,
                                ),
                            padding: EdgeInsets.fromLTRB(
                              16,
                              4,
                              16,
                              context.shellInset + _cartFooterClearance,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final it = items[i];
                              return _ItemCard(
                                item: it,
                                inCart: inCartQty[it.id] ?? 0,
                                onTap: () => _openItem(it),
                              );
                            },
                          ),
                        ),
                      ),
                ),
              ),
            ],
          ),
          if (cartCount > 0)
            Positioned(
              left: 8 + l.padding.left,
              right: 8 + l.padding.right,
              bottom: Sp.s4 + context.shellInset + l.padding.bottom,
              child: _CartFooter(
                count: cartCount,
                total: cartTotal,
                onReview: () => context.push(_reviewLoc),
              ),
            ),
        ],
      ),
    );
  }

  /// [[Item bebas]] — a line typed at the till. The note is mandatory client
  /// side *and* server side: the route refuses a blank one, so hiding the
  /// button is convenience and the 400 is the rule.
  Future<void> _addOpenItem() async {
    final line = await showOpenItemSheet(context);
    if (line == null || !mounted) return;
    ref.read(cartProvider(widget.tableId).notifier).add(line);
  }

  void _openItem(MenuItem item) {
    if (item.unavailable) return;
    showModifierSheet(
      context: context,
      item: item,
      onAdd: (cartItem) {
        ref.read(cartProvider(widget.tableId).notifier).add(cartItem);
      },
    );
  }
}

class _CatTabs extends ConsumerWidget {
  final String active;
  final ValueChanged<String> onChange;
  const _CatTabs({required this.active, required this.onChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final cats = ref.watch(menuCategoriesProvider);
    // The first chip is the way back to the whole menu, and the way orphan
    // items (filed under no category) stay reachable at all.
    final ids = ['all', for (final c in cats) c.id];
    final names = [context.l10n.mnaAll, for (final c in cats) c.name];
    return SizedBox(
      height: Sp.s9,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Sp.s4),
        itemCount: ids.length,
        separatorBuilder: (_, _) => const SizedBox(width: Sp.s1h),
        itemBuilder: (_, i) {
          final isActive = active == ids[i];
          // The selected category is the accent, flat, in every skin — every
          // palette pairs its own `accentInk` with it, so this stays legible
          // from lembut's amber through Glow's lime.
          final activeFill = sc.accent;
          final activeInk = sc.accentInk;
          // Glow keeps its tighter label face on the chip; the colour above is
          // skin-independent, this is not.
          final glow = SatShape.glow;
          return PressScale(
            child: GestureDetector(
              onTap: () => onChange(ids[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.s3h,
                  vertical: Sp.s2,
                ),
                decoration: SatBox.d(
                  color: isActive ? activeFill : Colors.transparent,
                  borderRadius: SatR.a(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  names[i],
                  style: (glow
                      ? SatType.labelM(color: isActive ? activeInk : sc.textMd)
                      : SatType.bodyM(color: isActive ? activeInk : sc.textMd)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  final MenuItem item;
  final int inCart;
  final VoidCallback onTap;
  const _ItemCard({
    required this.item,
    required this.inCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final tagsById = ref.watch(menuTagsByIdProvider);
    final disabled = item.unavailable;
    final card = Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        // Glow tints a card that already has something in the cart with the
        // accent itself rather than stepping up the neutral ramp — on a bone
        // ground a `bg3` step is nearly invisible, and "is this already
        // ordered" is the question a waiter scans this grid for.
        color: inCart > 0 ? (SatShape.glow ? sc.accentSoft : sc.bg3) : sc.bg2,
        borderRadius: SatR.a(22),
        // The card paints its surface here, not in `SatBox.d` below, so the
        // lift heuristic cannot see a fill and leaves it flat (ADR-0047 — a
        // hard shadow under a borrowed surface would paint it out). Glow's
        // shadow is blurred and has no such problem, so it comes off Material.
        elevation: SatShape.glow ? 3 : 0,
        shadowColor: SatShape.glow ? SatShape.lift.first.color : null,
        // Clipped: the cart-count badge sits in the photo Stack, and without a
        // clip it paints across the rounded corner and reads as a chip lying
        // beside the card rather than on it. The elevation shadow is painted by
        // [Material] outside this clip, so it survives.
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: SatR.a(22),
          child: Container(
            decoration: SatBox.d(
              borderRadius: SatR.a(22),
              border: SatB.all(
                color: inCart > 0 ? sc.accentBorder : sc.border0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MenuPhoto(
                          itemId: item.id,
                          name: item.name,
                          photoRev: item.photoRev,
                          borderRadius: BorderRadius.vertical(top: SatR.c(21)),
                          initialsSize: 30,
                        ),
                      ),
                      if (inCart > 0)
                        Positioned(
                          // Clear of the 22dp corner arc — at 8 the pill
                          // straddles the curve.
                          right: Sp.s3,
                          top: Sp.s3,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: Sp.s2,
                            ),
                            decoration: SatBox.d(
                              color: sc.accent,
                              borderRadius: SatR.a(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '×$inCart',
                              style: SatType.monoM(color: sc.accentInk),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: SatType.bodyM(color: sc.textHi),
                        ),
                        const SizedBox(height: Sp.s1h),
                        Text(
                          '${formatIDR(item.basePrice)}${item.variants.length > 1 ? '+' : ''}',
                          style: SatType.monoM(color: sc.textMd),
                        ),
                        if (item.allergens.isNotEmpty) ...[
                          const SizedBox(height: Sp.s1),
                          TagBadgeRow(
                            ids: item.allergens,
                            tagsById: tagsById,
                            fg: sc.urgent,
                            bg: sc.urgentSoft,
                          ),
                        ],
                        if (item.dietary.isNotEmpty) ...[
                          const SizedBox(height: Sp.s1),
                          TagBadgeRow(
                            ids: item.dietary,
                            tagsById: tagsById,
                            fg: sc.info,
                            bg: sc.infoSoft,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!disabled) return card;
    // The badge that says *why* the card is dimmed sits outside the `Opacity`.
    // At 0.4 the one element carrying the state was the faintest thing on the
    // card, and dark-red-on-scrim was already the weakest pairing in the grid.
    return Stack(
      children: [
        card,
        Positioned(
          // Same inset as the cart badge opposite it: the corner arc is what
          // both have to clear, and this one cannot be clipped — it is outside
          // the `Opacity`, so it is outside the card's clip too.
          left: Sp.s3,
          top: Sp.s3,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.s2,
              vertical: Sp.s1,
            ),
            decoration: SatBox.d(
              color: sc.urgent,
              borderRadius: SatR.a(999),
            ),
            child: Text(
              "HABIS",
              style: SatType.monoS(color: onFill(sc.urgent)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CartFooter extends StatelessWidget {
  final int count;
  final int total;
  final VoidCallback onReview;
  const _CartFooter({
    required this.count,
    required this.total,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
      decoration: SatBox.d(
        color: SatShape.veil(sc.scrim, 0.94),
        borderRadius: SatR.a(22),
        border: SatB.all(color: sc.border1),
        boxShadow: switch (SatShape.skin) {
          SatSkin.brutal => SatShape.hardShadow(5),
          SatSkin.glow => SatShape.liftLg,
          SatSkin.lembut => [
            BoxShadow(
              color: satShadowInk.withValues(alpha: 0.4),
              blurRadius: 32,
            ),
          ],
        },
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.mnuPending(count),
                style: SatType.bodyM(color: sc.textHi),
              ),
              Text(formatIDR(total), style: SatType.monoS(color: sc.textMd)),
            ],
          ),
          const Spacer(),
          SatButton.primary(label: context.l10n.crumbTinjau, onTap: onReview),
        ],
      ),
    );
  }
}

class _TabletCartPane extends ConsumerWidget {
  final String tableId;
  final bool tableless;
  final bool takeaway;
  final VoidCallback onReview;
  const _TabletCartPane({
    required this.tableId,
    required this.onReview,
    this.tableless = false,
    this.takeaway = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final cart = ref.watch(cartProvider(tableId));
    final count = cart.fold<int>(0, (s, c) => s + c.qty);
    final subtotal = cart.fold<int>(0, (s, c) => s + c.unitPrice * c.qty);
    final kit = count;
    final bar = 0;
    final venue = ref.watch(venueSettingsProvider);
    final breakdown = computeBreakdown(subtotal, venue.toTaxServiceConfig());
    final serviceLabel = venue.serviceMode == 'fixed'
        ? context.l10n.cshService
        : context.l10n.mnuServicePct(_fmtPct(venue.serviceRateBps));
    final taxLabel = context.l10n.mnuTaxPct(_fmtPct(venue.taxRateBps));
    final est = breakdown.total;

    return Container(
      width: 380,
      decoration: SatBox.d(
        color: sc.bg1,
        border: Border(left: SatB.side(color: sc.border0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
            decoration: SatBox.d(
              border: Border(bottom: SatB.side(color: sc.border0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  takeaway
                      ? context.l10n.mnuHeadTakeaway
                      : tableless
                      ? context.l10n.mnuHeadTableless
                      : context.l10n.mnuHeadTable(tableId),
                  style: SatType.caption(color: sc.textLo),
                ),
                const SizedBox(height: Sp.s1h),
                Text(
                  count == 0
                      ? context.l10n.mnuCartEmpty
                      : context.l10n.mnuCartReady(count),
                  style: SatType.h3(color: sc.textHi),
                ),
              ],
            ),
          ),
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Sp.s7),
                      child: Text(
                        context.l10n.mnuCartEmptyHint,
                        textAlign: TextAlign.center,
                        style: SatType.bodyM(color: sc.textLo),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                    itemCount: cart.length,
                    itemBuilder: (context, i) => Container(
                      margin: const EdgeInsets.only(bottom: Sp.s1h),
                      padding: const EdgeInsets.all(Sp.s3),
                      decoration: SatBox.d(
                        color: sc.bg2,
                        border: SatB.all(color: sc.border0),
                        borderRadius: SatR.a(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  cart[i].variantName.isEmpty
                                      ? cart[i].name
                                      : '${cart[i].name} · ${cart[i].variantName}',
                                  style: SatType.bodyM(color: sc.textHi),
                                ),
                              ),
                              const SizedBox(width: Sp.s2),
                              Text(
                                formatIDR(
                                  cart[i].unitPrice * cart[i].qty,
                                ),
                                style: SatType.monoM(color: sc.textMd),
                              ),
                            ],
                          ),
                          if (cart[i].modifiers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: Sp.s1),
                              child: Text(
                                cart[i].modifiers.join(' · '),
                                style: SatType.bodyS(color: sc.textMd),
                              ),
                            ),
                          if (cart[i].note.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: Sp.s1),
                              child: Text(
                                cart[i].note,
                                style: SatType.bodyS(color: sc.textLo),
                              ),
                            ),
                          const SizedBox(height: Sp.s2),
                          CartLineActions(
                            tableId: tableId,
                            line: cart[i],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
              decoration: SatBox.d(
                border: Border(top: SatB.side(color: sc.border0)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.s3),
                    child: Column(
                      children: [
                        _totalRow(
                          context,
                          sc,
                          context.l10n.cshSubtotal,
                          formatIDR(subtotal),
                        ),
                        if (venue.serviceEnabled)
                          _totalRow(
                            context,
                            sc,
                            serviceLabel,
                            formatIDR(breakdown.serviceAmount),
                          ),
                        if (venue.taxEnabled)
                          _totalRow(
                            context,
                            sc,
                            taxLabel,
                            formatIDR(breakdown.taxAmount),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: Sp.s2),
                          child: Container(
                            padding: const EdgeInsets.only(top: Sp.s2),
                            decoration: SatBox.d(
                              border: Border(top: SatB.side(color: sc.border0)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  context.l10n.mnuEstimate,
                                  style: SatType.labelM(color: sc.textHi),
                                ),
                                const Spacer(),
                                Text(
                                  formatIDR(est),
                                  style: SatType.monoM(color: sc.textHi),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: sc.accent,
                      borderRadius: SatR.a(16),
                      child: InkWell(
                        onTap: onReview,
                        borderRadius: SatR.a(16),
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          child: Text(
                            context.l10n.mnuReviewSendTo(
                              kit > 0 && bar > 0
                                  ? context.l10n.mnuTargetKitchenBar
                                  : kit > 0
                                  ? context.l10n.mnuTargetKitchen
                                  : context.l10n.mnuTargetBar,
                            ),
                            style: SatType.labelL(color: sc.accentInk),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    SatColors sc,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.s1),
      child: Row(
        children: [
          Text(label, style: SatType.monoM(color: sc.textMd)),
          const Spacer(),
          Text(value, style: SatType.monoM(color: sc.textMd)),
        ],
      ),
    );
  }
}

String _fmtPct(int bps) {
  final v = bps / 100.0;
  return '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}%';
}

/// "Batalkan pesanan ini?" — asked on the way out of the menu with [items] in
/// the cart. Returns true to discard. See ADR-0061.
///
/// ponytail: a fourth private copy of the confirm-sheet shape (staff_screen,
/// zone_admin_screen, cashier_bill_screen hold the others). Promoting one
/// `showSatConfirm` into core/widgets is the right fix and is worth its own
/// change; doing it here would drag three unrelated screens plus the CATALOG
/// and /book entries into a cart commit.
Future<bool?> _confirmDiscard(BuildContext context, int items) {
  return showSatSheet<bool>(
    context,
    builder: (ctx) {
      final sc = ctx.sat;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Sp.s5, Sp.s3, Sp.s5, Sp.s5),
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
                context.l10n.discardCartTitle,
                style: SatType.labelL(color: sc.textHi),
              ),
              const SizedBox(height: Sp.s2),
              Text(
                context.l10n.discardCartBody(items),
                style: SatType.bodyM(color: sc.textMd),
              ),
              const SizedBox(height: Sp.s4h),
              Row(
                children: [
                  Expanded(
                    child: SatButton.outline(
                      label: context.l10n.cancel,
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: Sp.s2h),
                  Expanded(
                    child: SatButton.danger(
                      label: context.l10n.discardCartConfirm,
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
}

/// The [[Item bebas]] composer. Returns the line to add, or null on dismiss.
///
/// Three required fields and no more: what it is, what it costs, and why it is
/// not on the menu. Qty is deliberately absent — an off-menu line is one thing
/// sold once, and the cart stepper covers the rest.
Future<CartItem?> showOpenItemSheet(BuildContext context) {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  return showSatSheet<CartItem>(
    context,
    builder: (ctx) {
      final sc = ctx.sat;
      var showErrors = false;
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final name = nameCtrl.text.trim();
          final price =
              int.tryParse(priceCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
          final note = noteCtrl.text.trim();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Sp.s5,
                Sp.s3,
                Sp.s5,
                Sp.s5 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      ctx.l10n.mnuOpenItem,
                      style: SatType.labelL(color: sc.textHi),
                    ),
                    const SizedBox(height: Sp.s1),
                    Text(
                      ctx.l10n.mnuOpenItemSub,
                      style: SatType.bodyS(color: sc.textLo),
                    ),
                    const SizedBox(height: Sp.s4),
                    SatField.text(
                      controller: nameCtrl,
                      hint: ctx.l10n.mnuOpenItemName,
                      autofocus: true,
                      hasError: showErrors && name.isEmpty,
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: Sp.s2h),
                    SatField.money(
                      controller: priceCtrl,
                      hint: ctx.l10n.mnuOpenItemPrice,
                      hasError: showErrors && price <= 0,
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: Sp.s2h),
                    SatField.text(
                      controller: noteCtrl,
                      hint: ctx.l10n.mnuOpenItemNote,
                      helperText: ctx.l10n.mnuOpenItemNoteHelper,
                      hasError: showErrors && note.isEmpty,
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: Sp.s4h),
                    SatButton.primary(
                      label: ctx.l10n.mnuOpenItemAdd,
                      onTap: () {
                        if (name.isEmpty || price <= 0 || note.isEmpty) {
                          setSheetState(() => showErrors = true);
                          return;
                        }
                        Navigator.pop(
                          ctx,
                          CartItem(
                            id: 'C${_uuid.v4()}',
                            itemId: openItemId,
                            name: name,
                            variantId: '',
                            variantName: '',
                            note: note,
                            // The one course that means "make it now": an
                            // off-menu line has no station and no sequence.
                            course: CourseId.fireNow,
                            unitPrice: price,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
