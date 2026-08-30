import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/shell_inset.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/zone.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/tablet_chrome.dart';
import 'package:satset/ui/features/cashier/cashier_bill_screen.dart';
import 'package:satset/ui/features/cashier/debt_collect_sheet.dart';
import 'package:satset/ui/features/cashier/widgets/bill_card.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';

/// Which slice of the venue's money the cashier is looking at.
///
/// There is no separate Riwayat tab any more. Since ADR-0069 a bill closes
/// itself the instant it settles, so "already paid" and "history" name the same
/// set — [_Segment.lunas] reads the snapshot rows, and [_Segment.semua] shows
/// both sources in one grid.
enum _Segment { perluDitagih, lunas, semua }

/// How far back the Lunas segment reaches. Today is what a cashier means on
/// shift; the 7-day window is the old Riwayat, folded in rather than tabbed.
enum _Range { hariIni, tujuhHari }

/// Venue-wide cashier surface (`/kasir`). Gated by `Capability.settleBill`.
/// See ADR-0066 for the card grid and ADR-0069 for why Lunas reads history.
class CashierScreen extends ConsumerStatefulWidget {
  const CashierScreen({super.key});

  @override
  ConsumerState<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends ConsumerState<CashierScreen> {
  _Segment _seg = _Segment.perluDitagih;
  _Range _range = _Range.hariIni;

  /// Set by tapping the Meja ditutup stat — the one count on this screen that
  /// means "go chase someone", so it doubles as a filter.
  bool _detachedOnly = false;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final bills = ref.watch(settlementProvider);
    final history = ref.watch(venueHistoryProvider);
    final zones = {for (final z in ref.watch(zonesProvider)) z.id: z};

    final open = [
      for (final b in bills)
        // A seated table that has ordered nothing has no bill to take. It stays
        // reachable under Semua; it is not work.
        if (b.lineCount > 0) b,
    ];
    final unpaid = [
      for (final b in open)
        if (!b.fullySettled) b,
    ];
    // `valueOrNull` survives a refetch: growing the limit re-runs the provider
    // with the old page still attached, so the grid never blinks to empty.
    final page = history.valueOrNull ?? PastBillPage.empty;
    final closed = page.rows;
    final debtOn = ref.watch(
      venueSettingsProvider.select((v) => v.membersOn && v.memberDebtEnabled),
    );
    final piutangOnly = ref.watch(historyOnAccountProvider);

    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(settlementProvider.notifier).refresh();
            ref.invalidate(venueHistoryProvider);
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              _maybeGrow(n, page, history.isLoading);
              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Every settled count below reads `page.total`, never
                        // `closed.length` — the rows on screen are one page of
                        // the window, the count is the whole of it (ADR-0079).
                        _Header(
                          running: unpaid.length,
                          takeaway: open.where((b) => b.isTakeaway).length,
                          settled: page.total,
                          outstanding: unpaid.fold<int>(
                            0,
                            (a, b) => a + b.outstanding,
                          ),
                        ),
                        const SizedBox(height: Sp.s4),
                        _StatRow(
                          bills: open,
                          detachedOnly: _detachedOnly,
                          onDetachedTap: () => setState(() {
                            _detachedOnly = !_detachedOnly;
                            if (_detachedOnly) _seg = _Segment.perluDitagih;
                          }),
                        ),
                        // A member may walk in only to settle a tab, with
                        // nothing seated and no bill open — so the way in
                        // cannot hang off a card (ADR-0098).
                        if (debtOn) ...[
                          const SizedBox(height: Sp.s3),
                          SatButton.outline(
                            label: context.l10n.cshDebtCollect,
                            icon: Icons.account_balance_wallet_outlined,
                            onTap: () => showDebtCollectSheet(context),
                          ),
                        ],
                        const SizedBox(height: Sp.s4),
                        _SegmentRow(
                          selected: _seg,
                          perluDitagih: unpaid.length,
                          lunas: page.total,
                          semua: open.length + page.total,
                          piutangTotal: debtOn ? page.piutangTotal : null,
                          piutangOnly: piutangOnly,
                          onPiutangTap: () {
                            final on = !piutangOnly;
                            ref
                                    .read(historyOnAccountProvider.notifier)
                                    .state =
                                on;
                            // Turning it on walks the cashier to where the
                            // rows are, exactly as the Meja ditutup tile walks
                            // them the other way — a tab-paid bill is always
                            // closed, so the filter is meaningless on Perlu
                            // ditagih. The range goes with it: chasing a debt
                            // is not a today job, and the chip counts the whole
                            // window, so leaving it on Hari ini promises rows
                            // the grid then clips away.
                            if (on) {
                              setState(() {
                                if (_seg == _Segment.perluDitagih) {
                                  _seg = _Segment.lunas;
                                }
                                _range = _Range.tujuhHari;
                              });
                            }
                          },
                          onSelected: (s) {
                            if (s == _Segment.perluDitagih &&
                                ref.read(historyOnAccountProvider)) {
                              // No closed bill renders here, so a lit filter
                              // would claim to be narrowing a list it cannot
                              // touch. Mirrors _detachedOnly below.
                              ref
                                  .read(historyOnAccountProvider.notifier)
                                  .state = false;
                            }
                            setState(() {
                              _seg = s;
                              if (s != _Segment.perluDitagih) {
                                _detachedOnly = false;
                              }
                            });
                          },
                        ),
                        if (_seg != _Segment.perluDitagih) ...[
                          const SizedBox(height: Sp.s2h),
                          _RangeRow(
                            selected: _range,
                            onSelected: (r) => setState(() => _range = r),
                          ),
                        ],
                        const SizedBox(height: Sp.s3h),
                      ],
                    ),
                  ),
                ),
                ..._body(open, unpaid, _inRange(closed), zones, history, page),
                SliverToBoxAdapter(child: SizedBox(height: context.shellInset)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Raise the history limit a page when the scroll gets within two viewports
  /// of the end. Two viewports rather than one so the fetch lands before the
  /// thumb does; the grid keeps its current rows while it flies (ADR-0079).
  void _maybeGrow(ScrollNotification n, PastBillPage page, bool loading) {
    if (_seg == _Segment.perluDitagih) return; // no history rendered here
    if (loading || !page.hasMore) return;
    final limit = ref.read(historyLimitProvider);
    if (limit >= historyPageCeiling) return;
    final m = n.metrics;
    if (!m.hasContentDimensions) return;
    if (m.pixels < m.maxScrollExtent - m.viewportDimension * 2) return;
    ref.read(historyLimitProvider.notifier).state = (limit + historyPageSize)
        .clamp(historyPageSize, historyPageCeiling);
  }

  List<PastBillSummary> _inRange(List<PastBillSummary> rows) {
    if (_range == _Range.tujuhHari) return rows;
    final now = SatClock.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return [
      for (final r in rows)
        if (!r.closedAt.isBefore(startOfDay)) r,
    ];
  }

  List<Widget> _body(
    List<BillSummary> open,
    List<BillSummary> unpaid,
    List<PastBillSummary> closed,
    Map<String, Zone> zones,
    AsyncValue<PastBillPage> history,
    PastBillPage page,
  ) {
    final status = ref.watch(settlementStatusProvider);
    if (status.isLoading && open.isEmpty && _seg == _Segment.perluDitagih) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: SatSpinner(size: SatSpinnerSize.md)),
        ),
      ];
    }
    if (status.hasError && open.isEmpty && _seg == _Segment.perluDitagih) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: SatEmpty(
            icon: Icons.cloud_off_rounded,
            title: context.l10n.cshLoadFailedTitle,
            body: context.l10n.cshPullToRetry,
          ),
        ),
      ];
    }

    final live = switch (_seg) {
      _Segment.perluDitagih => [
        for (final b in unpaid)
          if (!_detachedOnly || b.detached) b,
      ],
      _Segment.lunas => const <BillSummary>[],
      _Segment.semua => open,
    };
    final past = _seg == _Segment.perluDitagih
        ? const <PastBillSummary>[]
        : closed;

    if (live.isEmpty && past.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: SatEmpty(
            icon: Icons.receipt_long_outlined,
            title: switch (_seg) {
              _Segment.perluDitagih =>
                _detachedOnly
                    ? context.l10n.cshEmptyDetached
                    : context.l10n.cshEmptyOpen,
              _Segment.lunas =>
                ref.watch(historyOnAccountProvider)
                    ? context.l10n.cshEmptyPiutang
                    : _range == _Range.hariIni
                    ? context.l10n.cshEmptySettledToday
                    : context.l10n.cshEmptySettled7d,
              _Segment.semua => ref.watch(historyOnAccountProvider)
                  ? context.l10n.cshEmptyPiutang
                  : context.l10n.cshEmptyAll,
            },
          ),
        ),
      ];
    }

    // Sorted before the two sources are interleaved so Semua reads as one list:
    // the work first (biggest outstanding), then what is already done.
    final sortedLive = [...live]
      ..sort((a, b) {
        if (a.detached != b.detached) return a.detached ? -1 : 1;
        return b.outstanding.compareTo(a.outstanding);
      });
    final sortedPast = [...past]
      ..sort((a, b) => b.closedAt.compareTo(a.closedAt));

    final cards = <Widget>[
      for (final b in sortedLive)
        BillCard.fromSummary(
          b,
          l10n: context.l10n,
          zone: zones[b.zoneId],
          onTap: () => openCashierBill(context, visitId: b.visitId),
        ),
      for (final p in sortedPast)
        BillCard.fromPastBill(
          p,
          l10n: context.l10n,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PastBillDetailScreen(
                sessionId: p.sessionId,
                tableLabel: p.tableLabel,
              ),
            ),
          ),
        ),
    ];

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverToBoxAdapter(
          child: _Masonry(
            cards: cards,
            // One column on a phone falls out of this: at 360dp the card is
            // wider than the extent, so it gets the full row.
            maxColumnWidth: context.layout.useTabletShell ? 340 : 640,
          ),
        ),
      ),
      // Foot spinner, not a replacement for the grid: this fires both on the
      // first load (nothing to show yet) and on every page after it (rows
      // already up, more coming). ADR-0079.
      if (history.isLoading && _seg != _Segment.perluDitagih)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: Sp.s6),
            child: Center(child: SatSpinner(size: SatSpinnerSize.md)),
          ),
        ),
      // Scrolled to the ceiling with older bills still behind it. Says where
      // they are rather than leaving the list looking finished.
      if (!history.isLoading &&
          _seg != _Segment.perluDitagih &&
          page.hasMore &&
          ref.watch(historyLimitProvider) >= historyPageCeiling)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, Sp.s6),
            child: Text(
              context.l10n.kasirRiwayatBatas,
              textAlign: TextAlign.center,
              style: SatType.bodyS(color: context.sat.textDim),
            ),
          ),
        ),
    ];
  }
}

/// The bill grid. Columns of self-sizing cards rather than a [SliverGrid],
/// because a bill card's height is its content: three rows of pills on one
/// bill, none on the next. Every tile in a `SliverGrid` gets the same extent,
/// so that screen had to carry a fixed height budgeted for the fattest card —
/// which both overflowed when a card grew past it and left dead space under
/// every card that did not.
///
/// ponytail: builds every card up front rather than lazily, and packs
/// round-robin rather than balancing column heights. A venue's open bills are
/// tens, not thousands, and round-robin is what keeps reading order matching
/// the sort — the biggest outstanding first, left to right. If either stops
/// holding, this wants `flutter_staggered_grid_view`'s `SliverMasonryGrid`.
class _Masonry extends StatelessWidget {
  final List<Widget> cards;
  final double maxColumnWidth;

  const _Masonry({required this.cards, required this.maxColumnWidth});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      // The same rule SliverGridDelegateWithMaxCrossAxisExtent applied.
      final cols = (c.maxWidth / maxColumnWidth).ceil().clamp(1, 8);
      final columns = List.generate(cols, (_) => <Widget>[]);
      for (var i = 0; i < cards.length; i++) {
        columns[i % cols].add(Reveal(index: i, child: cards[i]));
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cols; i++) ...[
            if (i > 0) const SizedBox(width: Sp.s2h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns[i].length; j++) ...[
                    if (j > 0) const SizedBox(height: Sp.s2h),
                    columns[i][j],
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

/// Title, what the shift looks like in one line, and the number the owner asks
/// about — how much money is still out there.
class _Header extends StatelessWidget {
  final int running;
  final int takeaway;
  final int settled;
  final int outstanding;
  const _Header({
    required this.running,
    required this.takeaway,
    required this.settled,
    required this.outstanding,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.cshTitle, style: SatType.h2(color: sc.textHi)),
              const SizedBox(height: Sp.s1),
              Text(
                context.l10n.cshSummary(running, takeaway, settled),
                style: SatType.bodyS(color: sc.textLo),
              ),
            ],
          ),
        ),
        const SizedBox(width: Sp.s3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              context.l10n.cshUnbilled,
              style: SatType.labelS(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s1),
            Text(
              formatIDR(outstanding),
              style: SatType.monoL(color: sc.textHi),
            ),
          ],
        ),
      ],
    );
  }
}

/// Four counts, three of them a state of the money and one an instruction.
///
/// The design source's fourth card counts takeaways; that pointed at a Tanpa
/// meja segment which is not shipping, so the slot went to the detached count —
/// the aggregate that actually asks the cashier to do something, and the one
/// L1-5 demoted from a card tint to a pill.
class _StatRow extends StatelessWidget {
  final List<BillSummary> bills;
  final bool detachedOnly;
  final VoidCallback onDetachedTap;
  const _StatRow({
    required this.bills,
    required this.detachedOnly,
    required this.onDetachedTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final unpaid = bills.where((b) => !b.fullySettled).toList();
    final belumBayar = unpaid.where((b) => b.paidAmount == 0).length;
    final sebagian = unpaid.where((b) => b.paidAmount > 0).length;
    final diterima = bills.fold<int>(0, (a, b) => a + b.paidAmount);
    final ditutup = unpaid.where((b) => b.detached).length;

    final tiles = <Widget>[
      TabletStatTile(
        value: '$belumBayar',
        label: context.l10n.cshStatUnpaid,
        valueColor: sc.urgent,
      ),
      TabletStatTile(
        value: '$sebagian',
        label: context.l10n.cshStatPartial,
        valueColor: sc.info,
      ),
      TabletStatTile(
        value: formatIDR(diterima),
        label: context.l10n.cshStatReceived,
        valueColor: sc.success,
      ),
      TabletStatTile(
        value: '$ditutup',
        label: context.l10n.cshStatClosed,
        valueColor: sc.warn,
        selected: detachedOnly,
        onTap: ditutup == 0 && !detachedOnly ? null : onDetachedTap,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: Sp.s2h),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final _Segment selected;
  final int perluDitagih;
  final int lunas;
  final int semua;
  final ValueChanged<_Segment> onSelected;

  /// The window's tab total, or null where the venue does not do tabs. Shown
  /// on the chip itself so the number an owner wants is legible without
  /// turning the filter on — and it is the *window's*, unaffected by the
  /// filter, so tapping it never changes what it says.
  final int? piutangTotal;
  final bool piutangOnly;
  final VoidCallback onPiutangTap;

  const _SegmentRow({
    required this.selected,
    required this.perluDitagih,
    required this.lunas,
    required this.semua,
    required this.onSelected,
    required this.piutangTotal,
    required this.piutangOnly,
    required this.onPiutangTap,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Sp.s2,
    runSpacing: Sp.s2,
    children: [
      SatChip.select(
        label: context.l10n.cshSegNeedCharge,
        count: perluDitagih,
        selected: selected == _Segment.perluDitagih,
        onTap: () => onSelected(_Segment.perluDitagih),
      ),
      SatChip.select(
        label: context.l10n.cshSegSettled,
        count: lunas,
        selected: selected == _Segment.lunas,
        onTap: () => onSelected(_Segment.lunas),
      ),
      SatChip.select(
        label: context.l10n.cshSegAll,
        count: semua,
        selected: selected == _Segment.semua,
        onTap: () => onSelected(_Segment.semua),
      ),
      // A filter, not a fourth segment: a tab-paid bill is Lunas like every
      // other, so this narrows the settled list rather than naming a state of
      // its own (ADR-0098). It sits with the segments rather than in the range
      // row so it is visible from Perlu ditagih, where the cashier starts.
      if (piutangTotal != null)
        SatChip.select(
          label: context.l10n.cshSegPiutang(formatIDR(piutangTotal!)),
          selected: piutangOnly,
          onTap: piutangTotal == 0 && !piutangOnly ? null : onPiutangTap,
        ),
    ],
  );
}

class _RangeRow extends StatelessWidget {
  final _Range selected;
  final ValueChanged<_Range> onSelected;
  const _RangeRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Sp.s2,
    children: [
      SatChip.select(
        label: context.l10n.cshRangeToday,
        selected: selected == _Range.hariIni,
        onTap: () => onSelected(_Range.hariIni),
      ),
      SatChip.select(
        label: context.l10n.cshRange7d,
        selected: selected == _Range.tujuhHari,
        onTap: () => onSelected(_Range.tujuhHari),
      ),
    ],
  );
}

/// Whether the signed-in account can open the cashier surface.
bool canSettle(WidgetRef ref) =>
    ref.watch(authStateProvider).has(Capability.settleBill);
