import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/shell_inset.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/core/widgets/sat_icon_button.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/stock_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/ingredient.dart';
import 'package:satset/domain/models/stock_count.dart';
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/admin/_common.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/core/localization/labels.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';

enum _StockFilter { all, low, negative, produced }

/// "Stok" — Heritage Hospitality Pantry & Stock Ledger Management.
///
/// Handles ingredient lists, receiving inventory, batch production, opname audits,
/// and append-only stock movement history (ADR-0040, ADR-0041).
class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  /// Local echo of the lines already sent, so a row can render its own badge
  /// without a round trip. The server holds the truth.
  final _counts = <String, int>{};

  /// What the shelf claimed when each line was **entered** — read back from the
  /// line the server froze, never from today's `stockOnHand`. Sales keep
  /// deducting while the pantry is walked (ADR-0096).
  final _expected = <String, int>{};

  /// One count field per bahan, kept so a resumed walk shows its own numbers.
  final _countCtrls = <String, TextEditingController>{};
  final _searchCtrl = TextEditingController();

  /// Ingredient ids whose recipe chips the user unclipped past the 2-line cap.
  final _expandedLinks = <String>{};

  /// The open opname, or null when nobody is counting. Server-backed, so a
  /// forty-minute walk survives the tablet sleeping.
  StockCount? _session;
  bool get _opname => _session != null;

  _StockFilter _activeFilter = _StockFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Resume a walk somebody left open — the whole point of the session being
    // a row rather than a screen mode.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumeOpname());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _countCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _resumeOpname() async {
    try {
      final open = (await ref.read(stockApiProvider).counts()).open;
      if (open == null || !mounted) return;
      setState(() => _adoptSession(open));
    } catch (_) {
      // A stock screen that cannot reach the server has bigger problems than a
      // missing resume, and the ingredient list will already be saying so.
    }
  }

  void _adoptSession(StockCount s) {
    _session = s;
    _counts
      ..clear()
      ..addEntries(s.lines.map((l) => MapEntry(l.ingredientId, l.countedQty)));
    _expected
      ..clear()
      ..addEntries(s.lines.map((l) => MapEntry(l.ingredientId, l.expectedQty)));
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    // Two authorities open this screen (ADR-0132) and each half renders for
    // whoever holds it, the `/kas` shape. The ledger — receive, waste,
    // produce, opname — is `adjustStock` and is why the route admitted us.
    // Authoring a bahan is `manageIngredients`, a separate grant, so those
    // affordances come off rather than 403 on tap.
    final canEditCatalogue = ref.watch(
      authStateProvider.select((a) => a.has(Capability.manageIngredients)),
    );
    final async = ref.watch(ingredientsProvider);
    final compact = !context.layout.useTabletShell;

    return Column(
      children: [
        AdminEmbeddedStrip(
          title: context.l10n.stkTitle,
          sub: _opname ? context.l10n.stkSubOpname : context.l10n.stkSub,
          // A phone strip carries glyphs, not labelled buttons: "Batal" beside
          // "Simpan (12)" beside a title leaves nothing for the title. The
          // labels survive as tooltips, and the count they carried is already
          // on the opname banner a line below.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_opname && canEditCatalogue) ...[
                SatIconButton.primary(
                  icon: Icons.add,
                  tooltip: context.l10n.stkAddIngredient,
                  onTap: () => _editIngredient(null),
                ),
                const SizedBox(width: Sp.s2),
              ],
              if (_opname)
                compact
                    ? SatIconButton.danger(
                        icon: Icons.close,
                        tooltip: context.l10n.cancel,
                        onTap: _discardOpname,
                      )
                    : PressScale(
                        child: SatButton.danger(
                          label: context.l10n.cancel,
                          icon: Icons.close,
                          onTap: _discardOpname,
                        ),
                      )
              else
                compact
                    ? SatIconButton.outline(
                        icon: Icons.inventory_2_outlined,
                        tooltip: context.l10n.stkOpname,
                        onTap: _startOpname,
                      )
                    : PressScale(
                        child: SatButton.outline(
                          label: context.l10n.stkOpname,
                          icon: Icons.inventory_2_outlined,
                          onTap: _startOpname,
                        ),
                      ),
              if (_opname) ...[
                const SizedBox(width: Sp.s2),
                if (compact)
                  SatIconButton.primary(
                    icon: Icons.check_circle_outline,
                    tooltip: context.l10n.stkSaveCount(_counts.length),
                    onTap: _counts.isEmpty ? null : _closeOpname,
                  )
                else
                  PressScale(
                    child: SatButton.primary(
                      label: context.l10n.stkSaveCount(_counts.length),
                      icon: Icons.check_circle_outline,
                      onTap: _counts.isEmpty ? null : _closeOpname,
                    ),
                  ),
              ],
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () =>
                const Center(child: SatSpinner(size: SatSpinnerSize.md)),
            error: (e, _) => _Message(
              context.l10n.stkLoadFailed('$e'),
              color: sc.urgent,
              icon: Icons.error_outline,
            ),
            data: (list) {
              if (list.isEmpty) {
                return _EmptyState(
                  title: context.l10n.stkEmptyTitle,
                  message: context.l10n.stkEmptyBody,
                  onAction: canEditCatalogue
                      ? () => _editIngredient(null)
                      : null,
                );
              }

              // Apply Search & Filter
              final q = _searchQuery.toLowerCase();
              final filtered = list.where((i) {
                // Recipe names match too, so "nasi goreng" lists everything
                // that dish consumes.
                final matchesSearch =
                    q.isEmpty ||
                    i.name.toLowerCase().contains(q) ||
                    i.usedBy.any((n) => n.toLowerCase().contains(q)) ||
                    i.madeFrom.any((n) => n.toLowerCase().contains(q));
                final matchesFilter = switch (_activeFilter) {
                  _StockFilter.all => true,
                  _StockFilter.low => i.isLow || i.stockOnHand < 0,
                  _StockFilter.negative => i.stockOnHand < 0,
                  _StockFilter.produced => i.isProduced,
                };
                return matchesSearch && matchesFilter;
              }).toList();

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(ingredientsProvider),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? Sp.s4 : 20,
                    16,
                    compact ? Sp.s4 : 20,
                    Sp.s8 + context.shellInset,
                  ),
                  children: [
                    // The KPI cards say what the filter chips two rows below
                    // already say, with the same counts and the same taps. On a
                    // tablet that redundancy buys a glanceable header; on a
                    // phone it costs a third of the fold, so the phone starts
                    // at the search field and the chips carry the counts.
                    if (compact)
                      AnimatedSize(
                        duration: satMotion(context, 240),
                        curve: satEaseOut,
                        child: _opname
                            ? _opnameBanner(sc)
                            : const SizedBox(width: double.infinity),
                      )
                    else
                      // Smooth Animated CrossFade between KPI Summary and Opname Banner
                      AnimatedCrossFade(
                        firstChild: _summaryGrid(sc, list),
                        secondChild: _opnameBanner(sc),
                        crossFadeState: _opname
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: satMotion(context, 240),
                        firstCurve: satEaseOut,
                        secondCurve: satEaseOut,
                      ),
                    if (!_opname) _belanjaCard(sc, list),
                    const SizedBox(height: Sp.s4),
                    _searchAndFilterBar(sc, list),
                    const SizedBox(height: Sp.s4),
                    if (filtered.isEmpty)
                      _Message(context.l10n.stkNoMatch, icon: Icons.search_off)
                    else
                      for (int idx = 0; idx < filtered.length; idx++)
                        Reveal(index: idx, child: _row(sc, filtered[idx])),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- Belanja
  //
  // The shopping list: everything sitting under its par, and how much to buy
  // to get back to it. Read-only and derived — a par is a target, not an order,
  // so nothing here writes and nothing is remembered between builds.
  Widget _belanjaCard(SatColors sc, List<Ingredient> list) {
    final short = [
      for (final i in list)
        if (i.shortfall > 0) i,
    ]..sort((a, b) => a.name.compareTo(b.name));
    if (short.isEmpty) return const SizedBox.shrink();

    var total = 0;
    for (final i in short) {
      total += valueOf(i.shortfall, i.costMicro);
    }

    return Padding(
      padding: const EdgeInsets.only(top: Sp.s4),
      child: Container(
        padding: const EdgeInsets.all(Sp.s3),
        decoration: SatBox.d(
          color: sc.bg2,
          borderRadius: SatR.a(14),
          border: SatB.all(color: sc.info),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_basket_outlined, size: 16, color: sc.info),
                const SizedBox(width: Sp.s2),
                Expanded(
                  child: Text(
                    context.l10n.stkBelanja,
                    style: SatType.labelM(color: sc.textHi),
                  ),
                ),
                Text(
                  context.l10n.stkCountIngredients(short.length),
                  style: SatType.monoS(color: sc.textLo),
                ),
              ],
            ),
            const SizedBox(height: Sp.s2),
            for (final i in short)
              Padding(
                padding: const EdgeInsets.only(bottom: Sp.s1),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        i.name,
                        style: SatType.bodyS(color: sc.textHi),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Sp.s2),
                    Text(
                      formatQty(i.shortfall, i.unit),
                      style: SatType.monoS(color: sc.info),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: Sp.s1),
            Text(
              context.l10n.stkBelanjaEstimate(formatIDR(total)),
              style: SatType.caption(color: sc.textLo),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- KPI Summary
  Widget _summaryGrid(SatColors sc, List<Ingredient> list) {
    final low = list.where((i) => i.isLow).length;
    final negative = list.where((i) => i.stockOnHand < 0).length;
    final produced = list.where((i) => i.isProduced).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 550;
        final cards = [
          _statCard(
            sc,
            index: 0,
            label: context.l10n.stkKpiLow,
            value: context.l10n.stkCountIngredients(low),
            sub: low > 0
                ? context.l10n.stkNeedReorder
                : context.l10n.stkStockOk,
            icon: Icons.warning_amber_rounded,
            color: low > 0 ? sc.warn : sc.textLo,
            bg: low > 0 ? sc.warnSoft : sc.bg2,
            borderColor: low > 0 ? sc.warn : null,
            active: _activeFilter == _StockFilter.low,
            onTap: () => setState(() {
              _activeFilter = _activeFilter == _StockFilter.low
                  ? _StockFilter.all
                  : _StockFilter.low;
            }),
          ),
          if (negative > 0)
            _statCard(
              sc,
              index: 1,
              label: context.l10n.stkKpiNegative,
              value: context.l10n.stkCountIngredients(negative),
              sub: context.l10n.stkNeedOpname,
              icon: Icons.remove_circle_outline,
              color: sc.urgent,
              bg: sc.urgentSoft,
              borderColor: sc.urgent,
              active: _activeFilter == _StockFilter.negative,
              onTap: () => setState(() {
                _activeFilter = _activeFilter == _StockFilter.negative
                    ? _StockFilter.all
                    : _StockFilter.negative;
              }),
            ),
          _statCard(
            sc,
            index: 2,
            label: context.l10n.stkKpiProduced,
            value: context.l10n.stkCountIngredients(produced),
            sub: context.l10n.stkOfRegistered(list.length),
            icon: Icons.blender_outlined,
            color: sc.info,
            bg: sc.bg2,
            active: _activeFilter == _StockFilter.produced,
            onTap: () => setState(() {
              _activeFilter = _activeFilter == _StockFilter.produced
                  ? _StockFilter.all
                  : _StockFilter.produced;
            }),
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: Sp.s2h),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in cards)
              SizedBox(width: (constraints.maxWidth - 10) / 2, child: card),
          ],
        );
      },
    );
  }

  Widget _statCard(
    SatColors sc, {
    required int index,
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    required Color bg,
    Color? borderColor,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return Reveal(
      index: index,
      child: PressScale(
        child: InkWell(
          onTap: onTap,
          borderRadius: SatR.a(14),
          child: AnimatedContainer(
            duration: satMotion(context, 180),
            curve: satEaseOut,
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.s3h,
              vertical: Sp.s3,
            ),
            decoration: SatBox.d(
              color: active ? sc.bg3 : bg,
              borderRadius: SatR.a(14),
              border: SatB.all(
                color: active ? color : (borderColor ?? sc.border1),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: SatType.caption(color: sc.textLo),
                      ),
                    ),
                    Icon(icon, size: 16, color: color),
                  ],
                ),
                const SizedBox(height: Sp.s1h),
                Text(value, style: SatType.labelL(color: color)),
                const SizedBox(height: Sp.sHair),
                Text(sub, style: SatType.bodyS(color: sc.textLo)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Opname Banner
  Widget _opnameBanner(SatColors sc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s4, vertical: Sp.s3),
      decoration: SatBox.d(
        color: sc.accentSoft,
        borderRadius: SatR.a(14),
        border: SatB.all(color: sc.accentBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Sp.s2),
            decoration: SatBox.d(
              color: sc.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_note_rounded,
              size: 20,
              color: sc.accentText,
            ),
          ),
          const SizedBox(width: Sp.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.stkOpnameMode,
                  style: SatType.caption(color: sc.accentText),
                ),
                const SizedBox(height: Sp.sHair),
                Text(
                  context.l10n.stkOpnameHint,
                  style: SatType.bodyS(color: sc.textMd),
                ),
              ],
            ),
          ),
          if (_counts.isNotEmpty) ...[
            const SizedBox(width: Sp.s2),
            AnimatedSwitcher(
              duration: satMotion(context, 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Container(
                key: ValueKey(_counts.length),
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.s2h,
                  vertical: Sp.s1,
                ),
                decoration: SatBox.d(
                  color: sc.accent,
                  borderRadius: SatR.a(999),
                ),
                child: Text(
                  context.l10n.stkFilled(_counts.length),
                  style: SatType.caption(color: sc.accentInk),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Search & Filter
  Widget _searchAndFilterBar(SatColors sc, List<Ingredient> list) {
    final lowCount = list.where((i) => i.isLow || i.stockOnHand < 0).length;
    final negCount = list.where((i) => i.stockOnHand < 0).length;
    final prodCount = list.where((i) => i.isProduced).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SatField.search(
                controller: _searchCtrl,
                hint: context.l10n.stkSearchHint,
                suffix: _searchQuery.isEmpty
                    ? null
                    : SatIconButton.plain(
                        icon: Icons.clear,
                        tooltip: context.l10n.a11yClear,
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.s2h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(
                sc,
                _StockFilter.all,
                context.l10n.stkFilterAll(list.length),
              ),
              const SizedBox(width: Sp.s1h),
              _filterChip(
                sc,
                _StockFilter.low,
                context.l10n.stkFilterLow(lowCount),
                highlightColor: lowCount > 0 ? sc.warn : null,
              ),
              if (negCount > 0) ...[
                const SizedBox(width: Sp.s1h),
                _filterChip(
                  sc,
                  _StockFilter.negative,
                  context.l10n.stkFilterNegative(negCount),
                  highlightColor: sc.urgent,
                ),
              ],
              const SizedBox(width: Sp.s1h),
              _filterChip(
                sc,
                _StockFilter.produced,
                context.l10n.stkFilterProduced(prodCount),
                highlightColor: sc.info,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(
    SatColors sc,
    _StockFilter filter,
    String label, {
    Color? highlightColor,
  }) {
    final active = _activeFilter == filter;
    final color = active ? (highlightColor ?? sc.accentText) : sc.textMd;

    return PressScale(
      child: InkWell(
        onTap: () => setState(() => _activeFilter = filter),
        borderRadius: SatR.a(999),
        child: AnimatedContainer(
          duration: satMotion(context, 150),
          curve: satEaseOut,
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s3,
            vertical: Sp.s1h,
          ),
          decoration: SatBox.d(
            color: active
                ? (highlightColor?.withValues(alpha: 0.15) ?? sc.accentSoft)
                : sc.bg2,
            border: SatB.all(color: active ? color : sc.border1),
            borderRadius: SatR.a(999),
          ),
          child: Text(
            label,
            style: (active
                ? SatType.labelS(color: color)
                : SatType.bodyS(color: color)),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Ingredient Row Card
  // ---------------------------------------------------------------- Ingredient Row Card
  //
  // Two shapes, one body. A tablet reads this card the way it reads a ledger —
  // three metrics abreast, the acts sitting on the right where a pointer
  // already is. A phone is held one-handed in a storeroom, so the same facts
  // stack: the on-hand figure becomes the hero, the two supporting numbers
  // drop under it, and the acts collapse into a sheet reached from a 40dp
  // target instead of an 18dp kebab (ADR-0134 put `/stock` on the phone bar).
  Widget _row(SatColors sc, Ingredient i) {
    // Read here rather than threaded down from `build`: this row is the
    // other half of the catalogue/ledger split (ADR-0132) and the popup it
    // renders is the only place that half is spent.
    final canEditCatalogue = ref.watch(
      authStateProvider.select((a) => a.has(Capability.manageIngredients)),
    );
    final compact = !context.layout.useTabletShell;
    final negative = i.stockOnHand < 0;
    final statusColor = negative
        ? sc.urgent
        : i.isLow
        ? sc.warn
        : sc.success;

    // Physical count entered in opname mode
    final physicalCount = _counts[i.id];

    // Header line: name + badges. A Wrap rather than a Row so a long bahan
    // name and two badges reflow instead of overflowing — the same construct
    // serves both form factors.
    final heading = Wrap(
          spacing: Sp.s1h,
          runSpacing: Sp.s1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(i.name, style: SatType.labelL(color: sc.textHi)),
            if (i.isProduced)
              _badge(
                sc,
                label: context.l10n.stkBadgeProduced,
                color: sc.info,
                icon: Icons.blender_outlined,
              ),
            // The low / negative badges are the on-hand figure in another
            // costume — they stay hidden for the length of a blind walk too.
            if (i.isLow && !negative && !_blindWalk)
              _badge(
                sc,
                label: context.l10n.stkBadgeLow,
                color: sc.warn,
                icon: Icons.warning_amber_rounded,
              ),
            if (negative && !_blindWalk)
              _badge(
                sc,
                label: context.l10n.stkBadgeNegative,
                color: sc.urgent,
                icon: Icons.remove_circle_outline,
              ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact)
          // The acts sit on the *name's* line, not the figure's. Hung off the
          // on-hand row they floated mid-card against nothing, and the gap
          // above the supporting numbers became whatever a 40dp button is
          // tall rather than a step on the spacing scale.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              if (!_opname) ...[
                const SizedBox(width: Sp.s2),
                // Primary, not outline: this is the affirmative act on the
                // card, and an outline glyph on `bg2` inside a `bg2` card
                // reads as disabled on a bright handset.
                SatIconButton.primary(
                  icon: Icons.add_shopping_cart,
                  tooltip: context.l10n.stkReceive,
                  onTap: () => _receive(i),
                ),
                const SizedBox(width: Sp.s1),
                SatIconButton.plain(
                  icon: Icons.more_vert,
                  tooltip: context.l10n.a11yStockActions,
                  onTap: () => _actions(i, canEditCatalogue: canEditCatalogue),
                ),
              ],
            ],
          )
        else
          heading,
        const SizedBox(height: Sp.s2),

        if (compact) ...[
          // The on-hand figure is what somebody standing at a shelf came for,
          // so on a phone it is the hero rather than the first of three.
          _metric(
            sc,
            label: context.l10n.stkColOnHand,
            value: _blindWalk ? '••••' : i.onHandLabel,
            color: _blindWalk ? sc.textLo : statusColor,
            big: true,
          ),
          const SizedBox(height: Sp.s2),
          Row(
            children: [
              Expanded(child: _pricePerMetric(sc, i)),
              Expanded(child: _lastReceivedMetric(sc, i)),
            ],
          ),
        ] else
          // Metrics Grid
          Row(
            children: [
              Expanded(
                child: _metric(
                  sc,
                  label: context.l10n.stkColOnHand,
                  // Hidden for the length of a blind walk: a count shown the
                  // answer tends to agree with it, and the variance is then
                  // worth nothing (ADR-0096). Revealed the moment it closes.
                  value: _blindWalk ? '••••' : i.onHandLabel,
                  color: _blindWalk ? sc.textLo : statusColor,
                ),
              ),
              Expanded(child: _pricePerMetric(sc, i)),
              Expanded(child: _lastReceivedMetric(sc, i)),
            ],
          ),

        // Low stock threshold progress line — a picture of the on-hand figure,
        // so blind hides it with the number.
        if (i.lowStockAt != null && i.lowStockAt! > 0 && !_blindWalk) ...[
          const SizedBox(height: Sp.s2),
          _stockLevelMeter(sc, i),
        ],

        // Recipe links — counting doesn't need them, and the row already grows
        // a count field in opname mode.
        if (!_opname) ...[
          const SizedBox(height: Sp.s2),
          _RecipeLinkChips(
            sc: sc,
            madeFrom: i.madeFrom,
            usedBy: i.usedBy,
            expanded: _expandedLinks.contains(i.id),
            onExpand: () => setState(() => _expandedLinks.add(i.id)),
          ),
        ],

        // On a phone the count field is the width of the card rather than a
        // 120dp column: the walk is the reason this screen is on the handset
        // at all, and a thumb aiming between shelves deserves the whole row.
        if (compact && _opname) ...[
          const SizedBox(height: Sp.s2h),
          Row(
            children: [
              Expanded(child: _countField(i)),
              if (physicalCount != null) ...[
                const SizedBox(width: Sp.s3),
                _countEcho(sc, i, physicalCount),
              ],
            ],
          ),
        ],
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: Sp.s2h),
      decoration: SatBox.d(
        color: sc.bg2,
        borderRadius: SatR.a(14),
        border: SatB.all(color: physicalCount != null ? sc.accent : sc.border1),
      ),
      child: ClipRRect(
        borderRadius: SatR.a(14),
        // Stack, not IntrinsicHeight: the strip only needs to stretch to the
        // row's height, and an intrinsic pass would ask the chip LayoutBuilder
        // below for a width it cannot answer.
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              // Health status accent strip on left
              child: AnimatedContainer(
                duration: satMotion(context, 200),
                width: 4,
                color: statusColor,
              ),
            ),
            Row(
              children: [
                const SizedBox(width: Sp.s1),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 12, compact ? 12 : 14, 12),
                    child: body,
                  ),
                ),

                // Right Actions / Opname Input — tablet only. The phone folds
                // both into the card body above.
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.only(right: Sp.s3),
                    child: _opname
                        ? SizedBox(
                            width: 120,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _countField(i),
                                if (physicalCount != null) ...[
                                  const SizedBox(height: Sp.s1),
                                  _countEcho(sc, i, physicalCount),
                                ],
                              ],
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PressScale(
                                child: SatButton.outline(
                                  label: context.l10n.stkReceive,
                                  icon: Icons.add_shopping_cart,
                                  onTap: () => _receive(i),
                                ),
                              ),
                              SatIconButton.plain(
                                icon: Icons.more_vert,
                                tooltip: context.l10n.a11yStockActions,
                                onTap: () => _actions(
                                  i,
                                  canEditCatalogue: canEditCatalogue,
                                ),
                              ),
                            ],
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// One labelled figure. [big] promotes it to the phone card's hero.
  Widget _metric(
    SatColors sc, {
    required String label,
    required String value,
    required Color color,
    bool big = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SatType.monoS(color: sc.textLo)),
        const SizedBox(height: Sp.sHair),
        Text(
          value,
          style: big
              ? SatType.monoL(color: color)
              : SatType.monoM(color: color),
        ),
      ],
    );
  }

  Widget _pricePerMetric(SatColors sc, Ingredient i) => _metric(
    sc,
    label: context.l10n.stkColPricePer(i.unit.label.toUpperCase()),
    value: i.costMicro > 0
        ? formatIDR(unitPriceFromCostMicro(i.costMicro, i.unit))
        : '—',
    color: sc.textMd,
  );

  /// Freshness, not valuation.
  Widget _lastReceivedMetric(SatColors sc, Ingredient i) => _metric(
    sc,
    label: context.l10n.stkColLastReceived,
    value: i.lastReceivedAt == null
        ? '—'
        : formatElapsed(
            context.l10n,
            SatClock.now().difference(i.lastReceivedAt!),
          ),
    color: sc.textMd,
  );

  /// The opname entry field. Committed on blur as well as on submit: a counter
  /// walking a shelf taps the next row, they do not press enter. The commit is
  /// what freezes the expectation, so it must not wait for a gesture nobody
  /// makes.
  Widget _countField(Ingredient i) => Focus(
    onFocusChange: (has) {
      if (!has) _commitLine(i);
    },
    child: SatField.decimal(
      hint: i.unit.label,
      textAlign: TextAlign.right,
      controller: _countCtrl(i),
      onSubmitted: (_) => _commitLine(i),
    ),
  );

  /// What the line says back. The variance is the expected figure by
  /// arithmetic, so a blind walk withholds it until close and shows only that
  /// the line landed.
  Widget _countEcho(SatColors sc, Ingredient i, int physicalCount) => _blindWalk
      ? Text(context.l10n.stkCounted, style: SatType.caption(color: sc.textLo))
      : _varianceDeltaBadge(sc, i, physicalCount);

  /// Everything the row can do, on one sheet. Replaces the popup menu on both
  /// form factors: the phone has no room for an 18dp kebab's menu, and the
  /// tablet gains nothing by keeping a second vocabulary for the same six acts.
  Future<void> _actions(
    Ingredient i, {
    required bool canEditCatalogue,
  }) => showSatSheet<void>(
    context,
    bare: true,
    builder: (ctx) => _ActionSheet(
      title: i.name,
      actions: [
        (
          Icons.add_shopping_cart,
          ctx.l10n.stkMenuReceive,
          null,
          () => _receive(i),
        ),
        if (i.isProduced)
          (
            Icons.blender_outlined,
            ctx.l10n.stkMenuProduce,
            null,
            () => _produce(i),
          ),
        (Icons.delete_outline, ctx.l10n.stkMenuWaste, null, () => _waste(i)),
        (Icons.history, ctx.l10n.stkMenuLedger, null, () => _ledger(i)),
        // Catalogue, not ledger: renaming a bahan or archiving it is
        // `manageIngredients`.
        if (canEditCatalogue) ...[
          (
            Icons.edit_outlined,
            ctx.l10n.stkMenuEdit,
            null,
            () => _editIngredient(i),
          ),
          (
            Icons.archive_outlined,
            ctx.l10n.stkMenuArchive,
            ctx.sat.urgent,
            () => _archive(i),
          ),
        ],
      ],
    ),
  );


  Widget _badge(
    SatColors sc, {
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sp.s1h,
        vertical: Sp.sHair,
      ),
      decoration: SatBox.d(
        color: color.withValues(alpha: 0.12),
        borderRadius: SatR.a(6),
        border: SatB.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: Sp.s1),
          ],
          Text(label, style: SatType.caption(color: color)),
        ],
      ),
    );
  }

  Widget _stockLevelMeter(SatColors sc, Ingredient i) {
    final threshold = i.lowStockAt!;
    final ratio = (i.stockOnHand / threshold).clamp(0.0, 1.5);
    final color = i.stockOnHand <= 0
        ? sc.urgent
        : i.isLow
        ? sc.warn
        : sc.success;

    // 3:2, not meter-plus-natural-width-label: the label is generated from a
    // venue's own unit and a large system type scale, so a Row that lets it
    // take whatever it wants overflows on a narrow card. The meter keeps at
    // least 60% and the label ellipsises rather than pushing.
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: SatR.a(2),
            child: LinearProgressIndicator(
              value: (ratio / 1.5).clamp(0.0, 1.0),
              backgroundColor: sc.bg3,
              color: color,
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(width: Sp.s2),
        Flexible(
          flex: 2,
          child: Text(
            context.l10n.stkMinThreshold(formatQty(threshold, i.unit)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: SatType.monoS(color: sc.textLo),
          ),
        ),
      ],
    );
  }

  Widget _varianceDeltaBadge(SatColors sc, Ingredient i, int physicalCount) {
    // Against the expectation frozen when the line was entered, not against
    // what the shelf says now — the kitchen has been selling all along.
    final delta = physicalCount - (_expected[i.id] ?? i.stockOnHand);
    final positive = delta > 0;
    final color = delta == 0
        ? sc.success
        : positive
        ? sc.success
        : sc.warn;
    final sign = positive ? '+' : '';
    final text = delta == 0
        ? context.l10n.stkVarianceExact
        : '$sign${formatQty(delta, i.unit)}';

    return AnimatedSwitcher(
      duration: satMotion(context, 180),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Text(
        text,
        key: ValueKey(text),
        style: SatType.caption(color: color),
      ),
    );
  }

  // ---------------------------------------------------------------- Actions

  /// True while a session that hid its numbers is still open. Everything the
  /// on-hand figure can be read off — the badge, the meter, the variance — is
  /// gated on this.
  bool get _blindWalk => _session?.blind ?? false;

  /// One controller per bahan, so a resumed walk shows what was already
  /// entered rather than an empty field over a line that exists.
  TextEditingController _countCtrl(Ingredient i) =>
      _countCtrls.putIfAbsent(i.id, () {
        final counted = _counts[i.id];
        return TextEditingController(
          text: counted == null ? '' : _trim(i.unit.fromBase(counted)),
        );
      });

  void _clearCountCtrls() {
    for (final c in _countCtrls.values) {
      c.dispose();
    }
    _countCtrls.clear();
  }

  /// A yes/no on a sheet, because this screen has no dialog vocabulary and one
  /// more widget for two questions is not worth the file.
  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) async {
    final ok = await showSatSheet<bool>(
      context,
      bare: true,
      builder: (ctx) => _Sheet(
        title: title,
        subtitle: message,
        confirmLabel: confirmLabel,
        danger: danger,
        children: const [],
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    return ok == true;
  }

  /// Send one line. This is the moment the server freezes the expectation, so
  /// it happens per bahan as the walk goes — not in a lump at the end.
  Future<void> _commitLine(Ingredient i) async {
    final session = _session;
    if (session == null) return;
    final text = _countCtrls[i.id]?.text ?? '';
    final v = double.tryParse(text.replaceAll(',', '.'));
    final api = ref.read(stockApiProvider);

    if (v == null) {
      if (!_counts.containsKey(i.id)) return;
      await api.removeCountLine(session.id, i.id);
      if (!mounted) return;
      setState(() {
        _counts.remove(i.id);
        _expected.remove(i.id);
      });
      return;
    }

    final counted = i.unit.toBase(v);
    if (_counts[i.id] == counted) return;
    try {
      final line = await api.countLine(
        session.id,
        ingredientId: i.id,
        counted: counted,
      );
      if (!mounted) return;
      setState(() {
        _counts[i.id] = line.countedQty;
        _expected[i.id] = line.expectedQty;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.stkSaveFailed('$e'))));
    }
  }

  /// Ask what kind of count this is before opening it. Both answers are
  /// recorded on the session, because a variance that cannot say how it was
  /// produced cannot be argued with (ADR-0096).
  Future<void> _startOpname() async {
    var scope = StockCountScopeKind.full;
    var blind = true;

    final ok = await showSatSheet<bool>(
      context,
      bare: true,
      builder: (ctx) => _Sheet(
        title: ctx.l10n.stkOpnameStartTitle,
        subtitle: ctx.l10n.stkOpnameStartSub,
        confirmLabel: ctx.l10n.stkOpnameStart,
        onConfirm: () => Navigator.pop(ctx, true),
        children: [
          StatefulBuilder(
            builder: (ctx, setSheet) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SatDropdown<StockCountScopeKind>(
                  label: ctx.l10n.stkOpnameScope,
                  value: scope,
                  options: [
                    for (final s in StockCountScopeKind.values)
                      SatOption(s, stockCountScopeLabel(ctx.l10n, s)),
                  ],
                  onChanged: (v) => setSheet(() => scope = v ?? scope),
                ),
                const SizedBox(height: Sp.s3),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctx.l10n.stkOpnameBlind,
                            style: SatType.bodyM(color: ctx.sat.textHi),
                          ),
                          const SizedBox(height: Sp.sHair),
                          Text(
                            ctx.l10n.stkOpnameBlindHint,
                            style: SatType.bodyS(color: ctx.sat.textLo),
                          ),
                        ],
                      ),
                    ),
                    SatToggle(
                      value: blind,
                      semanticLabel: ctx.l10n.stkOpnameBlind,
                      onChanged: (v) => setSheet(() => blind = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      final session = await ref
          .read(stockApiProvider)
          .openCount(scope: scope, blind: blind);
      if (!mounted) return;
      setState(() {
        _clearCountCtrls();
        _adoptSession(session);
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.stkSaveFailed('$e'))));
    }
  }

  /// Abandon the walk. Confirmed, because the lines already entered go with it
  /// — a count that was never finished is not evidence of anything.
  Future<void> _discardOpname() async {
    final session = _session;
    if (session == null) return;
    if (_counts.isNotEmpty) {
      final ok = await _confirm(
        title: context.l10n.stkOpnameDiscardTitle,
        message: context.l10n.stkOpnameDiscardBody(_counts.length),
        confirmLabel: context.l10n.stkOpnameDiscard,
        danger: true,
      );
      if (!ok) return;
    }
    try {
      await ref.read(stockApiProvider).discardCount(session.id);
    } finally {
      if (mounted) {
        setState(() {
          _session = null;
          _counts.clear();
          _expected.clear();
          _clearCountCtrls();
        });
      }
    }
  }

  /// Close the walk: the server writes the movements, stamps the header and
  /// posts the single audit row.
  Future<void> _closeOpname() async {
    final session = _session;
    if (session == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    // A session that claims to have seen everything says so out loud when it
    // has not. The claim is the whole value of `full`, so it is worth one
    // confirmation rather than a silent lie.
    if (session.scope == StockCountScopeKind.full) {
      final total = ref.read(ingredientsProvider).valueOrNull?.length ?? 0;
      final missed = total - _counts.length;
      if (missed > 0) {
        final ok = await _confirm(
          title: l10n.stkOpnameIncompleteTitle,
          message: l10n.stkOpnameIncompleteBody(missed),
          confirmLabel: l10n.stkOpnameCloseAnyway,
        );
        if (!ok) return;
      }
    }

    try {
      final closed = await ref.read(stockApiProvider).closeCount(session.id);
      final changed = closed.lines.where((l) => l.variance != 0).length;
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            changed == 0
                ? l10n.stkOpnameDoneNoVariance
                : l10n.stkOpnameDone(changed),
          ),
        ),
      );
      setState(() {
        _session = null;
        _counts.clear();
        _expected.clear();
        _clearCountCtrls();
      });
      ref.invalidate(ingredientsProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.stkSaveFailed('$e'))));
    }
  }

  Future<void> _receive(Ingredient i) async {
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
      text: i.costMicro > 0
          ? unitPriceFromCostMicro(i.costMicro, i.unit).toString()
          : '',
    );
    final supplierCtrl = TextEditingController();
    var unit = i.unit;

    final ok = await showSatSheet<bool>(
      context,
      bare: true,
      builder: (ctx) => _Sheet(
        title: context.l10n.stkReceiveTitle(i.name),
        subtitle: context.l10n.stkReceiveSub,
        children: [
          StatefulBuilder(
            builder: (_, setSheet) => Row(
              children: [
                Expanded(
                  child: SatField.decimal(
                    controller: qtyCtrl,
                    label: context.l10n.quantity,
                    hint: '',
                    autofocus: true,
                    prefixIcon: Icons.numbers_outlined,
                  ),
                ),
                const SizedBox(width: Sp.s2h),
                SizedBox(
                  width: 110,
                  child: SatDropdown<StockUnit>(
                    value: unit,
                    options: [
                      for (final u in entryUnitsFor(i.unit))
                        SatOption(u, u.label),
                    ],
                    onChanged: (u) => setSheet(() => unit = u ?? unit),
                  ),
                ),
              ],
            ),
          ),
          SatField.number(
            controller: priceCtrl,
            label: context.l10n.stkPricePer(i.unit.label),
            hint: '',
            helperText: context.l10n.stkPriceHelper,
            prefixIcon: Icons.payments_outlined,
          ),
          SatField.text(
            controller: supplierCtrl,
            label: context.l10n.stkSupplier,
            hint: '',
            prefixIcon: Icons.storefront_outlined,
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
    final l10n = context.l10n;
    try {
      await ref
          .read(stockApiProvider)
          .receive(
            ingredientId: i.id,
            qty: unit.toBase(amount),
            unitPrice: int.tryParse(priceCtrl.text),
            supplier: supplierCtrl.text.trim().isEmpty
                ? null
                : supplierCtrl.text.trim(),
          );
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.stkReceiveOk)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.stkFailed('$e'))));
    }
  }

  /// "Buang" — bin a bahan. The note is required: a waste row without a reason
  /// is a number nobody can act on, and this is the one stock act with no
  /// counterparty to explain it.
  Future<void> _waste(Ingredient i) async {
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var unit = i.unit;

    final ok = await showSatSheet<bool>(
      context,
      bare: true,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheet) => _Sheet(
          title: context.l10n.stkWasteTitle(i.name),
          subtitle: context.l10n.stkWasteSub,
          children: [
            Row(
              children: [
                Expanded(
                  child: SatField.decimal(
                    controller: qtyCtrl,
                    label: context.l10n.quantity,
                    hint: '',
                    autofocus: true,
                    prefixIcon: Icons.numbers_outlined,
                  ),
                ),
                const SizedBox(width: Sp.s2h),
                SizedBox(
                  width: 110,
                  child: SatDropdown<StockUnit>(
                    value: unit,
                    options: [
                      for (final u in entryUnitsFor(i.unit))
                        SatOption(u, u.label),
                    ],
                    onChanged: (u) => setSheet(() => unit = u ?? unit),
                  ),
                ),
              ],
            ),
            SatField.text(
              controller: noteCtrl,
              label: context.l10n.stkWasteNote,
              hint: '',
              helperText: context.l10n.stkWasteNoteHelper,
              prefixIcon: Icons.notes_outlined,
            ),
          ],
          // Refuse *inside* the sheet, so a rejected save keeps what was typed:
          // popping first and validating after threw the quantity away and left
          // the reason to be retyped from an empty form.
          onConfirm: () {
            final entered = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));
            final messenger = ScaffoldMessenger.of(ctx);
            if (entered == null || entered <= 0) {
              messenger.showSnackBar(
                SnackBar(content: Text(ctx.l10n.stkWasteQtyRequired)),
              );
              return;
            }
            if (noteCtrl.text.trim().isEmpty) {
              messenger.showSnackBar(
                SnackBar(content: Text(ctx.l10n.stkWasteNoteRequired)),
              );
              return;
            }
            Navigator.of(ctx).pop(true);
          },
        ),
      ),
    );
    if (ok != true) return;
    final amount = double.parse(qtyCtrl.text.replaceAll(',', '.'));
    final note = noteCtrl.text.trim();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      final value = await ref
          .read(stockApiProvider)
          .waste(ingredientId: i.id, qty: unit.toBase(amount), note: note);
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.stkWasteOk(formatIDR(value)))),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.stkFailed('$e'))));
    }
  }

  Future<void> _produce(Ingredient i) async {
    final ctrl = TextEditingController(text: '1');
    final ok = await showSatSheet<bool>(
      context,
      bare: true,
      builder: (ctx) => _Sheet(
        title: context.l10n.stkProduceTitle(i.name),
        subtitle: i.batchYield == null
            ? null
            : context.l10n.stkProduceSub(formatQty(i.batchYield!, i.unit)),
        children: [
          SatField.number(
            controller: ctrl,
            label: context.l10n.stkBatchCount,
            hint: '',
            autofocus: true,
            prefixIcon: Icons.blender_outlined,
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
    final l10n = context.l10n;
    try {
      await ref.read(stockApiProvider).produce(i.id, n);
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.stkProduceOk)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.stkFailed('$e'))));
    }
  }

  Future<void> _ledger(Ingredient i) async {
    await showSatSheet<void>(
      context,
      bare: true,
      builder: (_) => _LedgerSheet(ingredient: i),
    );
  }

  Future<void> _archive(Ingredient i) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref.read(stockApiProvider).archive(i.id);
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.stkArchived(i.name))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.stkFailed('$e'))));
    }
  }

  Future<void> _editIngredient(Ingredient? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final openingCtrl = TextEditingController();
    final lowCtrl = TextEditingController(
      text: existing?.lowStockAt == null
          ? ''
          : _trim(existing!.unit.fromBase(existing.lowStockAt!)),
    );
    final parCtrl = TextEditingController(
      text: existing?.parLevel == null
          ? ''
          : _trim(existing!.unit.fromBase(existing.parLevel!)),
    );
    final yieldCtrl = TextEditingController(
      text: existing?.batchYield == null
          ? ''
          : _trim(existing!.unit.fromBase(existing.batchYield!)),
    );
    var unit = existing?.unit ?? StockUnit.pcs;

    final ok = await showSatSheet<bool>(
      context,
      bare: true,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheet) => _Sheet(
          title: existing == null
              ? context.l10n.stkNewIngredient
              : context.l10n.stkEditIngredient(existing.name),
          subtitle: context.l10n.stkEditorSub,
          children: [
            SatField.text(
              controller: nameCtrl,
              label: context.l10n.stkName,
              hint: '',
              autofocus: existing == null,
              prefixIcon: Icons.inventory_outlined,
            ),
            SatDropdown<StockUnit>(
              value: unit,
              label: context.l10n.stkUnit,
              prefixIcon: Icons.straighten_outlined,
              options: [
                for (final u in StockUnit.values)
                  SatOption(
                    u,
                    context.l10n.stkUnitOption(
                      u.label,
                      stockDimensionLabel(context.l10n, u.dimension),
                    ),
                  ),
              ],
              onChanged: (u) => setSheet(() => unit = u ?? unit),
            ),
            if (existing == null)
              SatField.decimal(
                controller: openingCtrl,
                label: context.l10n.stkOpening(unit.label),
                hint: '',
                helperText: context.l10n.stkOpeningHelper,
                prefixIcon: Icons.assessment_outlined,
              ),
            SatField.decimal(
              controller: lowCtrl,
              label: context.l10n.stkLowAt(unit.label),
              hint: '',
              helperText: context.l10n.stkLowAtHelper,
              prefixIcon: Icons.warning_amber_rounded,
            ),
            SatField.decimal(
              controller: parCtrl,
              label: context.l10n.stkParAt(unit.label),
              hint: '',
              helperText: context.l10n.stkParAtHelper,
              prefixIcon: Icons.shopping_basket_outlined,
            ),
            SatField.decimal(
              controller: yieldCtrl,
              label: context.l10n.stkBatchYield(unit.label),
              hint: '',
              helperText: context.l10n.stkBatchYieldHelper,
              prefixIcon: Icons.blender_outlined,
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
    final par = parse(parCtrl);
    final batch = parse(yieldCtrl);
    final opening = parse(openingCtrl);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref
          .read(stockApiProvider)
          .save(
            Ingredient(
              id: existing?.id ?? const Uuid().v4(),
              name: name,
              unit: unit,
              lowStockAt: low == null ? null : unit.toBase(low),
              parLevel: par == null ? null : unit.toBase(par),
              batchYield: batch == null ? null : unit.toBase(batch),
            ),
            openingStock: existing == null && opening != null
                ? unit.toBase(opening)
                : 0,
          );
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.stkSaveOk)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.stkFailed('$e'))));
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

// ---------------------------------------------------------------- Sheet Container
class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.children,
    required this.onConfirm,
    this.subtitle,
    this.confirmLabel,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback onConfirm;

  /// Defaults to "Simpan". Named when the act is not a save — starting a walk,
  /// throwing one away.
  final String? confirmLabel;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: BorderRadius.vertical(top: SatR.c(20)),
        border: SatB.all(color: sc.border1),
      ),
      padding: EdgeInsets.only(
        left: Sp.s6,
        right: Sp.s6,
        top: Sp.s3,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle pill
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: SatBox.d(
                  color: sc.border1,
                  borderRadius: SatR.a(2),
                ),
              ),
            ),
            const SizedBox(height: Sp.s4),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: SatType.h3(color: sc.textHi)),
                      if (subtitle != null) ...[
                        const SizedBox(height: Sp.sHair),
                        Text(subtitle!, style: SatType.bodyS(color: sc.textLo)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.close,
                  icon: Icon(Icons.close, size: 20, color: sc.textLo),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: Sp.s4),

            // Children
            for (final c in children)
              Padding(
                padding: const EdgeInsets.only(bottom: Sp.s3),
                child: c,
              ),
            const SizedBox(height: Sp.s2),

            // Primary Action Button
            PressScale(
              child: danger
                  ? SatButton.danger(
                      label: confirmLabel ?? context.l10n.save,
                      onTap: onConfirm,
                    )
                  : SatButton.primary(
                      label: confirmLabel ?? context.l10n.save,
                      onTap: onConfirm,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Action Sheet
//
// The six things a bahan can have done to it. Rows, not a popup menu: a phone
// has nowhere to hang one, and a full-width 48dp row is the target a
// storeroom thumb can hit where an 18dp glyph's menu item is not.
class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.title, required this.actions});

  final String title;

  /// icon, label, optional colour (danger), what it does.
  final List<(IconData, String, Color?, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: BorderRadius.vertical(top: SatR.c(20)),
        border: SatB.all(color: sc.border1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: Sp.s3),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: SatBox.d(
                  color: sc.border1,
                  borderRadius: SatR.a(2),
                ),
              ),
            ),
            const SizedBox(height: Sp.s4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.s6),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SatType.h3(color: sc.textHi),
              ),
            ),
            const SizedBox(height: Sp.s3),
            for (final (icon, label, color, run) in actions)
              InkWell(
                // Pop first: every one of these opens a sheet of its own, and
                // two stacked sheets leave the second one's dismiss returning
                // to a menu the user has already answered.
                onTap: () {
                  Navigator.of(context).pop();
                  run();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sp.s6,
                    vertical: Sp.s3h,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: color ?? sc.textMd),
                      const SizedBox(width: Sp.s4),
                      Expanded(
                        child: Text(
                          label,
                          style: SatType.bodyM(color: color ?? sc.textHi),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: Sp.s4),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Ledger Sheet
class _LedgerSheet extends ConsumerWidget {
  const _LedgerSheet({required this.ingredient});
  final Ingredient ingredient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final async = ref.watch(stockMovementsProvider(ingredient.id));

    return Container(
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: BorderRadius.vertical(top: SatR.c(20)),
        border: SatB.all(color: sc.border1),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: SatBox.d(
                    color: sc.border1,
                    borderRadius: SatR.a(2),
                  ),
                ),
              ),
              const SizedBox(height: Sp.s4),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.stkLedgerTitle,
                        style: SatType.h3(color: sc.textHi),
                      ),
                      Text(
                        ingredient.name.toUpperCase(),
                        style: SatType.monoS(color: sc.accentText),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: context.l10n.close,
                    icon: Icon(Icons.close, size: 20, color: sc.textLo),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: Sp.s3h),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: async.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(Sp.s6),
                    child: Center(child: SatSpinner(size: SatSpinnerSize.md)),
                  ),
                  error: (e, _) => _Message(
                    context.l10n.stkLedgerLoadFailed('$e'),
                    color: sc.urgent,
                  ),
                  data: (rows) => rows.isEmpty
                      ? _Message(context.l10n.stkLedgerEmpty)
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: rows.length,
                          separatorBuilder: (context, index) =>
                              Divider(color: sc.border0, height: 1),
                          itemBuilder: (_, i) {
                            final m = rows[i];
                            final positive = m.delta > 0;
                            return Reveal(
                              index: i,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: Sp.s2h,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(Sp.s2),
                                      decoration: SatBox.d(
                                        color: positive
                                            ? sc.success.withValues(alpha: 0.1)
                                            : sc.bg3,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        positive
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 16,
                                        color: positive
                                            ? sc.success
                                            : sc.textLo,
                                      ),
                                    ),
                                    const SizedBox(width: Sp.s3),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stockReasonLabel(
                                              context.l10n,
                                              m.reason,
                                            ),
                                            style: SatType.labelM(
                                              color: sc.textHi,
                                            ),
                                          ),
                                          const SizedBox(height: Sp.sHair),
                                          Text(
                                            [
                                              if (m.sourceLabel.isNotEmpty)
                                                m.sourceLabel,
                                              _stamp(m.at),
                                              if (m.note != null) m.note!,
                                            ].join(' · '),
                                            style: SatType.monoS(
                                              color: sc.textLo,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${positive ? '+' : ''}'
                                      '${formatQty(m.delta, ingredient.unit)}',
                                      style: SatType.monoM(
                                        color: positive
                                            ? sc.success
                                            : sc.textMd,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.onAction,
  });

  final String title;
  final String message;
  /// Null when this session holds the ledger but not the catalogue: an empty
  /// bahan list is then a fact to report, not a call to action it can answer.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.s8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(Sp.s5),
              decoration: SatBox.d(
                color: sc.bg2,
                shape: BoxShape.circle,
                border: SatB.all(color: sc.border1),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: sc.textLo,
              ),
            ),
            const SizedBox(height: Sp.s4),
            Text(title, style: SatType.h3(color: sc.textHi)),
            const SizedBox(height: Sp.s2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: SatType.bodyM(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s5),
            if (onAction != null)
              PressScale(
                child: SatButton.primary(
                  label: context.l10n.stkAddFirst,
                  icon: Icons.add,
                  onTap: onAction,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.color, this.icon});
  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.all(Sp.s8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 28, color: color ?? sc.textLo),
              const SizedBox(height: Sp.s2h),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: SatType.bodyM(color: color ?? sc.textLo),
            ),
          ],
        ),
      ),
    );
  }
}

/// The recipe links on a stock card: what this ingredient is made from, then
/// what consumes it. Direction is carried by icon + color rather than group
/// labels, so both sets flow through one wrap.
///
/// Capped at two lines so one onion used in a dozen dishes can't make its card
/// five times taller than its neighbours; the overflow chip unclips it.
class _RecipeLinkChips extends StatelessWidget {
  const _RecipeLinkChips({
    required this.sc,
    required this.madeFrom,
    required this.usedBy,
    required this.expanded,
    required this.onExpand,
  });

  final SatColors sc;
  final List<String> madeFrom;
  final List<String> usedBy;
  final bool expanded;
  final VoidCallback onExpand;

  static const _maxLines = 2;
  static const _gap = 6.0;
  static const _padH = 6.0;
  static const _iconSize = 11.0;
  static const _iconGap = 3.0;
  static const _border = 1.0;

  @override
  Widget build(BuildContext context) {
    if (madeFrom.isEmpty && usedBy.isEmpty) {
      return _chip(context, context.l10n.stkUnused, null, sc.textLo);
    }

    // Made-from first: it is the rarer, more explanatory direction, and
    // ordering it first keeps it visible when the cap bites.
    final chips = <(String, IconData, Color)>[
      for (final n in madeFrom) (n, Icons.blender_outlined, sc.info),
      for (final n in usedBy) (n, Icons.restaurant_outlined, sc.textMd),
    ];

    if (expanded) {
      return Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [for (final c in chips) _chip(context, c.$1, c.$2, c.$3)],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final widths = [for (final c in chips) _chipWidth(c.$1, scaler)];
        // Upper-bound the overflow chip: "+N" can only shrink as N drops, so
        // reserving the worst case never overflows the line.
        final overflowWidth = _chipWidth('+${chips.length}', scaler);

        final shown = fitChipCount(
          widths,
          maxWidth: constraints.maxWidth,
          overflowWidth: overflowWidth,
          gap: _gap,
          maxLines: _maxLines,
        );
        final hidden = chips.length - shown;

        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final c in chips.take(shown)) _chip(context, c.$1, c.$2, c.$3),
            if (hidden > 0)
              Semantics(
                button: true,
                label: '+$hidden',
                child: GestureDetector(
                  onTap: onExpand,
                  child: _chip(context, '+$hidden', null, sc.textLo),
                ),
              ),
          ],
        );
      },
    );
  }

  double _chipWidth(String label, TextScaler scaler) {
    final tp = TextPainter(
      text: TextSpan(text: label, style: SatType.bodyS()),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    return tp.width + _padH * 2 + _border * 2 + _iconSize + _iconGap;
  }

  Widget _chip(
    BuildContext context,
    String label,
    IconData? icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: Sp.s1),
      decoration: SatBox.d(
        color: sc.bg3,
        borderRadius: SatR.a(6),
        border: SatB.all(color: sc.border1, width: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kept even when iconless so measured and rendered widths agree.
          SizedBox(
            width: _iconSize,
            child: icon == null
                ? null
                : Icon(icon, size: _iconSize, color: color),
          ),
          const SizedBox(width: _iconGap),
          // A chip wider than the card gets its own line rather than
          // vanishing (see [fitChipCount]) — but "its own line" is still only
          // as wide as the card, so a long dish name must clamp here or the
          // chip's own Row overflows on a phone.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SatType.bodyS(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// How many chips of the given [widths] fit within [maxLines] rows of
/// [maxWidth], laid out the way `Wrap` does (greedy, [gap] between chips).
///
/// Returns `widths.length` when everything fits — only then is no overflow
/// chip needed, so [overflowWidth] is reserved on the last line otherwise, and
/// the result is capped below `widths.length` so a "+N" always has an N.
@visibleForTesting
int fitChipCount(
  List<double> widths, {
  required double maxWidth,
  required double overflowWidth,
  required double gap,
  required int maxLines,
}) {
  int pack(double reserve) {
    var line = 1;
    var used = 0.0;
    for (var i = 0; i < widths.length; i++) {
      // The last line must leave room for the overflow chip.
      final limit = line == maxLines ? maxWidth - reserve - gap : maxWidth;
      final w = widths[i];
      final needed = used == 0 ? w : used + gap + w;
      // An over-wide chip still gets its own line rather than vanishing.
      if (needed <= limit || used == 0) {
        used = needed;
        continue;
      }
      if (line == maxLines) return i;
      line++;
      used = w;
    }
    return widths.length;
  }

  if (pack(0) == widths.length) return widths.length;
  return pack(overflowWidth).clamp(0, widths.length - 1);
}
