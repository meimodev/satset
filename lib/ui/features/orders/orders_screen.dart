import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/data/repositories/staff_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/repositories/takeaway_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/use_cases/advance_ticket_status_use_case.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/ui/core/widgets/staff_avatar.dart';
import 'package:satset/ui/core/widgets/elapsed_pill.dart';
import 'package:satset/ui/core/widgets/status_chip.dart';
import 'package:satset/ui/core/design/spacing.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _seg = 'ready';

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    final tickets = ref.watch(ticketsProvider);
    final tables = ref.watch(tablesProvider);
    final takeaways = {
      for (final v in ref.watch(takeawayVisitsProvider)) v.id: v,
    };
    final staff = ref.watch(staffRepositoryProvider);
    final venueName = ref.watch(
      venueSettingsProvider.select((s) => s.displayName),
    );

    // Venue-wide board: every table's tickets, no per-waiter filter. Each card
    // shows the line's own orderer (ticket.createdBy) — frozen to whoever sent
    // it, not the table's current waiter. Null on legacy / offline lines.
    final all = <_Row>[];
    tickets.forEach((key, list) {
      if (list.isEmpty) return;
      // Map is keyed by visitId (ADR-0034). A dine-in line carries its real
      // tableId; a table-less (takeaway) line resolves via the visit key so it
      // isn't silently dropped from the board. See ADR-0026.
      final tableId = list.first.tableId;
      final table = tableId.isNotEmpty
          ? tables.where((t) => t.id == tableId).firstOrNull
          : null;
      final takeaway = table == null ? takeaways[key] : null;
      if (table == null && takeaway == null) return;
      final name = table?.displayName ?? takeaway!.label;
      final zoneId = table?.zoneId ?? '';
      final pax = table?.pax ?? 0;
      for (final t in list) {
        final orderer = t.createdBy == null
            ? null
            : staff.where((u) => u.id == t.createdBy).firstOrNull;
        all.add(
          _Row(
            ticket: t,
            tableId: table?.id ?? key,
            tableName: name,
            zoneId: zoneId,
            pax: pax,
            orderer: orderer,
            isTakeaway: takeaway != null,
          ),
        );
      }
    });
    all.sort((a, b) => a.ticket.sentAtTime.compareTo(b.ticket.sentAtTime));

    Future<void> markServed(String tableId, String ticketId) async {
      try {
        await ref
            .read(advanceTicketStatusUseCaseProvider)
            .call(tableId, ticketId, TicketStatus.served);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text('Gagal sajikan: $e')));
      }
    }

    final ready = all
        .where((r) => r.ticket.status == TicketStatus.ready)
        .toList();
    final active = all
        .where(
          (r) =>
              r.ticket.status == TicketStatus.sent ||
              r.ticket.status == TicketStatus.prep ||
              r.ticket.status == TicketStatus.cooked ||
              r.ticket.status == TicketStatus.held,
        )
        .toList();
    final done = all
        .where(
          (r) =>
              r.ticket.status == TicketStatus.served ||
              r.ticket.status == TicketStatus.voided,
        )
        .toList();

    final list = _seg == 'ready' ? ready : (_seg == 'active' ? active : done);

    // Split each segment into a Bawa pulang section then a Makan di tempat
    // (dine-in) section. Rows keep their sentAt order within each. Headers hide
    // when their group is empty. See ADR-0026.
    final taRows = list.where((r) => r.isTakeaway).toList();
    final dineRows = list.where((r) => !r.isTakeaway).toList();

    final emptyMsg = _seg == 'ready'
        ? 'Belum ada yang siap di pass.'
        : _seg == 'active'
        ? 'Tidak ada item yang sedang disiapkan.'
        : 'Belum ada item yang selesai pada sesi ini.';

    Widget orderRow(_Row r) => _OrderRow(
      row: r,
      onTap: () => context.push(
        r.isTakeaway ? '/takeaway/${r.tableId}' : '/table/${r.tableId}',
      ),
      onServe: () => markServed(r.tableId, r.ticket.id),
    );

    Widget buildBoard({required bool grid}) {
      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(grid ? 60 : 24),
            child: Text(
              emptyMsg,
              textAlign: TextAlign.center,
              style: SatType.sans(size: 13, color: sc.textLo),
            ),
          ),
        );
      }
      final hpad = grid ? 32.0 : 16.0;
      final slivers = <Widget>[];
      void section(String title, List<_Row> rows) {
        if (rows.isEmpty) return;
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              hpad,
              slivers.isEmpty ? (grid ? 8 : 6) : 18,
              hpad,
              8,
            ),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(title: title, count: rows.length),
            ),
          ),
        );
        final pad = EdgeInsets.fromLTRB(hpad, 0, hpad, 0);
        if (grid) {
          slivers.add(
            SliverPadding(
              padding: pad,
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 120,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => orderRow(rows[i]),
                  childCount: rows.length,
                ),
              ),
            ),
          );
        } else {
          slivers.add(
            SliverPadding(
              padding: pad,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => orderRow(rows[i]),
                  childCount: rows.length,
                ),
              ),
            ),
          );
        }
      }

      section('Bawa pulang', taRows);
      section('Makan di tempat', dineRows);
      slivers.add(
        SliverToBoxAdapter(child: SizedBox(height: grid ? 32 : l.bottomInset)),
      );
      return CustomScrollView(slivers: slivers);
    }

    if (l.useTabletShell) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 18, 32, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        venueName.isEmpty ? 'Pesanan' : 'Pesanan $venueName',
                        style: SatType.sans(
                          size: 32,
                          weight: FontWeight.w600,
                          letterSpacing: -0.8,
                          height: 1.05,
                          color: sc.textHi,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.s1h),
                Text(
                  '${active.length} BERJALAN · ${ready.length} SIAP DIAMBIL',
                  style: SatType.mono(
                    size: 11,
                    color: sc.textLo,
                    letterSpacing: 0.66,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
            child: Row(
              children: [
                _TabletSeg(
                  label: 'Siap diambil',
                  count: ready.length,
                  active: _seg == 'ready',
                  onTap: () => setState(() => _seg = 'ready'),
                ),
                const SizedBox(width: Sp.s2),
                _TabletSeg(
                  label: 'Disiapkan',
                  count: active.length,
                  active: _seg == 'active',
                  onTap: () => setState(() => _seg = 'active'),
                ),
                const SizedBox(width: Sp.s2),
                _TabletSeg(
                  label: 'Selesai',
                  count: done.length,
                  active: _seg == 'done',
                  onTap: () => setState(() => _seg = 'done'),
                ),
              ],
            ),
          ),
          Expanded(child: buildBoard(grid: true)),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, l.topInset, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      venueName.isEmpty ? 'Pesanan' : 'Pesanan $venueName',
                      style: SatType.sans(
                        size: 30,
                        weight: FontWeight.w600,
                        letterSpacing: -0.6,
                        color: sc.textHi,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.s1),
              Text(
                '${active.length} aktif · ${ready.length} siap diambil',
                style: SatType.mono(
                  size: 11,
                  color: sc.textLo,
                  letterSpacing: 0.44,
                ),
              ),
            ],
          ),
        ),
        _Segments(
          seg: _seg,
          ready: ready.length,
          active: active.length,
          done: done.length,
          onChange: (v) => setState(() => _seg = v),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
              child: buildBoard(grid: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _Row {
  final Ticket ticket;
  final String tableId;
  final String tableName;
  final String zoneId;
  final int pax;
  final AppUser? orderer;
  final bool isTakeaway;
  _Row({
    required this.ticket,
    required this.tableId,
    required this.tableName,
    required this.zoneId,
    required this.pax,
    this.orderer,
    this.isTakeaway = false,
  });

  /// Compact label for the card's leading tile. Takeaway shows just its running
  /// number ("#7") — the section header already says "Bawa pulang", so the full
  /// label would only overflow the tile on a phone. Dine-in shows the table name.
  String get token {
    if (!isTakeaway) return tableName;
    final i = tableName.indexOf('#');
    return i >= 0 ? tableName.substring(i) : tableName;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.only(left: Sp.sHair, bottom: Sp.sHair),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: SatType.mono(
              size: 11,
              weight: FontWeight.w600,
              letterSpacing: 1.0,
              color: sc.textMd,
            ),
          ),
          const SizedBox(width: Sp.s2),
          Text(
            '$count',
            style: SatType.mono(size: 11, color: sc.textLo, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  final String seg;
  final int ready;
  final int active;
  final int done;
  final ValueChanged<String> onChange;
  const _Segments({
    required this.seg,
    required this.ready,
    required this.active,
    required this.done,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Sp.s4),
        children: [
          _SegBtn(
            label: 'Siap',
            count: ready,
            active: seg == 'ready',
            onTap: () => onChange('ready'),
          ),
          const SizedBox(width: Sp.s1h),
          _SegBtn(
            label: 'Disiapkan',
            count: active,
            active: seg == 'active',
            onTap: () => onChange('active'),
          ),
          const SizedBox(width: Sp.s1h),
          _SegBtn(
            label: 'Selesai',
            count: done,
            active: seg == 'done',
            onTap: () => onChange('done'),
          ),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _SegBtn({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Sp.s3h, vertical: 9),
        decoration: SatBox.d(
          color: active ? sc.textHi : sc.bg2,
          borderRadius: SatR.a(999),
          border: SatB.all(color: active ? sc.textHi : sc.border0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: SatType.sans(
                size: 13,
                weight: FontWeight.w500,
                color: active ? sc.bg0 : sc.textMd,
              ),
            ),
            const SizedBox(width: Sp.s2),
            Text(
              '$count',
              style: SatType.mono(
                size: 11,
                color: active ? sc.bg0.withValues(alpha: 0.6) : sc.textLo,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final _Row row;
  final VoidCallback onTap;
  final VoidCallback onServe;
  const _OrderRow({
    required this.row,
    required this.onTap,
    required this.onServe,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final t = row.ticket;
    final isReady = t.status == TicketStatus.ready;
    final isVoided = t.status == TicketStatus.voided;
    final bg = isReady ? sc.successSoft : sc.bg2;
    final border = isReady ? sc.success.withValues(alpha: 0.3) : sc.border0;

    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s1h),
      child: Opacity(
        opacity: isVoided ? 0.55 : 1,
        child: Material(
          color: bg,
          borderRadius: SatR.a(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: SatR.a(16),
            child: Container(
              padding: const EdgeInsets.all(Sp.s3h),
              decoration: SatBox.d(
                borderRadius: SatR.a(16),
                border: SatB.all(color: border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 42,
                      maxWidth: 88,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sp.s2h,
                      vertical: Sp.s2,
                    ),
                    decoration: SatBox.d(
                      color: isReady
                          ? sc.success.withValues(alpha: 0.2)
                          : sc.bg3,
                      borderRadius: SatR.a(10),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (row.isTakeaway) ...[
                          Icon(
                            Icons.shopping_bag_rounded,
                            size: 13,
                            color: isReady ? sc.success : sc.textMd,
                          ),
                          const SizedBox(width: Sp.s1),
                        ],
                        Flexible(
                          child: Text(
                            row.token,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: SatType.mono(
                              size: 16,
                              weight: FontWeight.w600,
                              letterSpacing: -0.16,
                              color: isReady ? sc.success : sc.textHi,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Sp.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              if (t.qty > 1)
                                TextSpan(
                                  text: '×${t.qty} ',
                                  style: SatType.mono(
                                    size: 12,
                                    color: sc.textMd,
                                    letterSpacing: 0,
                                  ),
                                ),
                              TextSpan(
                                text: t.name,
                                style: SatType.sans(
                                  size: 14,
                                  weight: FontWeight.w500,
                                  color: sc.textHi,
                                ),
                              ),
                              if (t.variantName.isNotEmpty)
                                TextSpan(
                                  text: ' · ${t.variantName}',
                                  style: SatType.sans(
                                    size: 14,
                                    color: sc.textMd,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (t.modifiers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              t.modifiers
                                      .take(2)
                                      .map((m) => m.display)
                                      .join(' · ') +
                                  (t.modifiers.length > 2 ? ' · …' : ''),
                              style: SatType.sans(
                                size: 11,
                                color: sc.textMd,
                                height: 1.3,
                              ),
                            ),
                          ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusChip(status: t.status),
                            ElapsedPill(
                              sentAtTime: t.sentAtTime,
                              sentAtClock: t.sentAt,
                              terminal:
                                  isVoided || t.status == TicketStatus.served,
                            ),
                            if (row.orderer != null)
                              StaffAvatar(actor: row.orderer!, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isReady)
                    _ServeButton(onTap: onServe)
                  else
                    Icon(Icons.chevron_right, size: 16, color: sc.textLo),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ServeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Material(
      color: sc.success,
      borderRadius: SatR.a(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: SatR.a(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s3,
            vertical: Sp.s2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 14, color: sc.accentInk),
              const SizedBox(width: Sp.s1h),
              Text(
                'Sajikan',
                style: SatType.sans(
                  size: 12,
                  weight: FontWeight.w600,
                  color: sc.accentInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabletSeg extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _TabletSeg({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Sp.s4,
          vertical: Sp.s2h,
        ),
        decoration: SatBox.d(
          color: active ? sc.textHi : sc.bg2,
          border: SatB.all(color: active ? sc.textHi : sc.border0),
          borderRadius: SatR.a(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: SatType.sans(
                size: 13,
                weight: FontWeight.w500,
                color: active ? sc.bg0 : sc.textMd,
              ),
            ),
            const SizedBox(width: Sp.s2h),
            Text(
              '$count',
              style: SatType.mono(
                size: 11,
                color: active ? sc.bg0.withValues(alpha: 0.6) : sc.textLo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
