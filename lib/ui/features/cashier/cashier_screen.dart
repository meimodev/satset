import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/zone.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/tablet_chrome.dart';
import 'package:satset/ui/features/cashier/cashier_bill_screen.dart';
import 'package:satset/ui/features/cashier/widgets/bill_card.dart';

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
    final closed = history.valueOrNull ?? const <PastBillSummary>[];

    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(settlementProvider.notifier).refresh();
            ref.invalidate(venueHistoryProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        running: unpaid.length,
                        takeaway: open.where((b) => b.isTakeaway).length,
                        settled: closed.length,
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
                      const SizedBox(height: Sp.s4),
                      _SegmentRow(
                        selected: _seg,
                        perluDitagih: unpaid.length,
                        lunas: closed.length,
                        semua: open.length + closed.length,
                        onSelected: (s) => setState(() {
                          _seg = s;
                          if (s != _Segment.perluDitagih) _detachedOnly = false;
                        }),
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
              ..._body(open, unpaid, _inRange(closed), zones, history),
            ],
          ),
        ),
      ),
    );
  }

  List<PastBillSummary> _inRange(List<PastBillSummary> rows) {
    if (_range == _Range.tujuhHari) return rows;
    final now = DateTime.now();
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
    AsyncValue<List<PastBillSummary>> history,
  ) {
    final status = ref.watch(settlementStatusProvider);
    if (status.isLoading && open.isEmpty && _seg == _Segment.perluDitagih) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (status.hasError && open.isEmpty && _seg == _Segment.perluDitagih) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: SatEmpty(
            icon: Icons.cloud_off_rounded,
            title: 'Gagal memuat tagihan',
            body: 'Tarik untuk coba lagi.',
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
              _Segment.perluDitagih => _detachedOnly
                  ? 'Tidak ada meja tertutup yang belum lunas'
                  : 'Tidak ada tagihan terbuka',
              _Segment.lunas => _range == _Range.hariIni
                  ? 'Belum ada tagihan lunas hari ini'
                  : 'Belum ada tagihan lunas 7 hari terakhir',
              _Segment.semua => 'Belum ada tagihan',
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
          zone: zones[b.zoneId],
          onTap: () => openCashierBill(context, visitId: b.visitId),
        ),
      for (final p in sortedPast)
        BillCard.fromPastBill(
          p,
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
      if (history.isLoading && past.isEmpty && _seg != _Segment.perluDitagih)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: Sp.s6),
            child: Center(child: CircularProgressIndicator()),
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
              Text('Kasir', style: SatType.h2(color: sc.textHi)),
              const SizedBox(height: Sp.s1),
              Text(
                '$running tagihan berjalan · $takeaway tanpa meja · '
                '$settled lunas',
                style: SatType.bodyS(color: sc.textLo),
              ),
            ],
          ),
        ),
        const SizedBox(width: Sp.s3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Belum tertagih', style: SatType.labelS(color: sc.textLo)),
            const SizedBox(height: Sp.s1),
            Text(formatIDR(outstanding), style: SatType.monoL(color: sc.textHi)),
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
        label: 'Belum bayar',
        valueColor: sc.urgent,
      ),
      TabletStatTile(
        value: '$sebagian',
        label: 'Sebagian',
        valueColor: sc.info,
      ),
      TabletStatTile(
        value: formatIDR(diterima),
        label: 'Sudah diterima',
        valueColor: sc.success,
      ),
      TabletStatTile(
        value: '$ditutup',
        label: 'Meja ditutup',
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
  const _SegmentRow({
    required this.selected,
    required this.perluDitagih,
    required this.lunas,
    required this.semua,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Sp.s2,
    runSpacing: Sp.s2,
    children: [
      SatChip.select(
        label: 'Perlu ditagih',
        count: perluDitagih,
        selected: selected == _Segment.perluDitagih,
        onTap: () => onSelected(_Segment.perluDitagih),
      ),
      SatChip.select(
        label: 'Lunas',
        count: lunas,
        selected: selected == _Segment.lunas,
        onTap: () => onSelected(_Segment.lunas),
      ),
      SatChip.select(
        label: 'Semua',
        count: semua,
        selected: selected == _Segment.semua,
        onTap: () => onSelected(_Segment.semua),
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
        label: 'Hari ini',
        selected: selected == _Range.hariIni,
        onTap: () => onSelected(_Range.hariIni),
      ),
      SatChip.select(
        label: '7 hari',
        selected: selected == _Range.tujuhHari,
        onTap: () => onSelected(_Range.tujuhHari),
      ),
    ],
  );
}

/// Whether the signed-in account can open the cashier surface.
bool canSettle(WidgetRef ref) =>
    ref.watch(authStateProvider).has(Capability.settleBill);
