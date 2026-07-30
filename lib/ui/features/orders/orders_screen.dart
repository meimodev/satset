import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_tabs.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/staff_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/repositories/takeaway_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/use_cases/advance_ticket_status_use_case.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/ui/core/widgets/staff_avatar.dart';
import 'package:satset/ui/core/widgets/elapsed_pill.dart';
import 'package:satset/ui/core/widgets/status_chip.dart';
import 'package:satset/ui/features/orders/view_models/orders_scope.dart';
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
    final zones = ref.watch(zonesProvider);
    final venueName = ref.watch(
      venueSettingsProvider.select((s) => s.displayName),
    );

    // Rows are scoped to the signed-in user (ADR-0056): the section you handle,
    // plus lines you authored, plus anything nobody owns. Each card still shows
    // the line's own orderer (ticket.createdBy) — frozen to whoever sent it, not
    // the table's current handler. Null on legacy / offline lines.
    final meId = ref.watch(authStateProvider.select((s) => s.user?.id));
    final showAll = ref.watch(ordersShowAllProvider);

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
      // Resolved to a name here rather than carried as an id: the board is the
      // one place a waiter reads lines from tables that are not theirs, and
      // "Teras" is what tells them where to walk. Takeaway has no zone.
      final zoneName = table == null
          ? ''
          : (zones.where((z) => z.id == table.zoneId).firstOrNull?.name ?? '');
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
            zoneName: zoneName,
            pax: pax,
            orderer: orderer,
            isTakeaway: takeaway != null,
            mine: ownsOrderRow(
              meId: meId,
              createdBy: t.createdBy,
              tableActorId: table?.lastActorId,
            ),
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

    // Siap is deliberately venue-wide whatever the scope says: the "Pesanan
    // siap" cue already sounds on every waiter's handset, and food dying under
    // the lamp is everyone's problem. Scoping applies to Aktif and Selesai.
    // ADR-0056.
    final ready = all
        .where((r) => r.ticket.status == TicketStatus.ready)
        .toList();
    final scoped = showAll ? all : all.where((r) => r.mine).toList();
    final active = scoped
        .where(
          (r) =>
              r.ticket.status == TicketStatus.sent ||
              r.ticket.status == TicketStatus.prep ||
              r.ticket.status == TicketStatus.cooked ||
              r.ticket.status == TicketStatus.held,
        )
        .toList();
    final done = scoped
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

    // Scoped-and-empty is a different fact from venue-empty: say which, so a
    // waiter never reads "nothing is cooking" when the kitchen is slammed.
    final emptyMsg = _seg == 'ready'
        ? 'Belum ada yang siap di pass.'
        : _seg == 'active'
        ? (showAll
              ? 'Tidak ada item yang sedang disiapkan.'
              : 'Tidak ada item Anda yang sedang disiapkan.\nPilih Semua untuk melihat seluruh venue.')
        : (showAll
              ? 'Belum ada item yang selesai pada sesi ini.'
              : 'Belum ada item Anda yang selesai pada sesi ini.\nPilih Semua untuk melihat seluruh venue.');

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
              style: SatType.bodyM(color: sc.textLo),
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
                        style: SatType.h1(color: sc.textHi),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.s1h),
                Text(
                  '${active.length} BERJALAN · ${ready.length} SIAP DIAMBIL',
                  style: SatType.monoS(color: sc.textLo),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
            child: Row(
              children: [
                SatChip.select(
                  label: 'Siap diambil',
                  count: ready.length,
                  selected: _seg == 'ready',
                  onTap: () => setState(() => _seg = 'ready'),
                ),
                const SizedBox(width: Sp.s2),
                SatChip.select(
                  label: 'Disiapkan',
                  count: active.length,
                  selected: _seg == 'active',
                  onTap: () => setState(() => _seg = 'active'),
                ),
                const SizedBox(width: Sp.s2),
                SatChip.select(
                  label: 'Selesai',
                  count: done.length,
                  selected: _seg == 'done',
                  onTap: () => setState(() => _seg = 'done'),
                ),
                const Spacer(),
                if (_seg != 'ready')
                  _ScopeToggle(
                    showAll: showAll,
                    onChange: (v) =>
                        ref.read(ordersShowAllProvider.notifier).set(v),
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
          // Not `l.topInset` — that token clears a status bar for screens with
          // no chrome above them, and this one always renders under SatAppBar.
          padding: const EdgeInsets.fromLTRB(20, Sp.s6, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      venueName.isEmpty ? 'Pesanan' : 'Pesanan $venueName',
                      style: SatType.h1(color: sc.textHi),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.s1),
              Text(
                '${active.length} aktif · ${ready.length} siap diambil',
                style: SatType.monoS(color: sc.textLo),
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
        if (_seg != 'ready')
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.s4, Sp.s2, Sp.s4, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _ScopeToggle(
                showAll: showAll,
                onChange: (v) =>
                    ref.read(ordersShowAllProvider.notifier).set(v),
              ),
            ),
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
  final String zoneName;
  final int pax;
  final AppUser? orderer;
  final bool isTakeaway;

  /// Belongs to the signed-in user — see [ownsOrderRow]. Filters Aktif and
  /// Selesai; the Siap bucket ignores it. ADR-0056.
  final bool mine;
  _Row({
    required this.ticket,
    required this.tableId,
    required this.tableName,
    required this.zoneName,
    required this.pax,
    this.orderer,
    this.isTakeaway = false,
    this.mine = true,
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
          Text(title.toUpperCase(), style: SatType.caption(color: sc.textMd)),
          const SizedBox(width: Sp.s2),
          Text('$count', style: SatType.monoS(color: sc.textLo)),
        ],
      ),
    );
  }
}

/// The three order buckets. A chip row rather than a tab strip: all three fit
/// on a phone, and each carries a live count that a tab indicator cannot.
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
      height: Sp.s10,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Sp.s4),
        children: [
          for (final (key, label, count) in [
            ('ready', 'Siap', ready),
            ('active', 'Disiapkan', active),
            ('done', 'Selesai', done),
          ]) ...[
            SatChip.select(
              label: label,
              count: count,
              selected: seg == key,
              onTap: () => onChange(key),
            ),
            const SizedBox(width: Sp.s1h),
          ],
        ],
      ),
    );
  }
}

/// "Milik saya / Semua" scope switch. Only rendered over Aktif and Selesai —
/// showing it above the venue-wide Siap bucket would be a lie. ADR-0056.
///
/// A tab strip rather than a chip row: these two are mutually exclusive views
/// of the same list, which is what [SatTabs] means, whereas the bucket chips
/// above carry counts and read as filters.
class _ScopeToggle extends StatelessWidget {
  final bool showAll;
  final ValueChanged<bool> onChange;
  const _ScopeToggle({required this.showAll, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return SatTabs(
      tabs: const [SatTab(label: 'Milik saya'), SatTab(label: 'Semua')],
      selected: showAll ? 1 : 0,
      onSelected: (i) => onChange(i == 1),
    );
  }
}

class _OrderRow extends ConsumerWidget {
  final _Row row;
  final VoidCallback onTap;
  final VoidCallback onServe;
  const _OrderRow({
    required this.row,
    required this.onTap,
    required this.onServe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                            style: SatType.monoM(
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
                                  style: SatType.monoM(color: sc.textMd),
                                ),
                              TextSpan(
                                text: t.name,
                                style: SatType.bodyM(color: sc.textHi),
                              ),
                              if (t.variantName.isNotEmpty)
                                TextSpan(
                                  text: ' · ${t.variantName}',
                                  style: SatType.bodyM(color: sc.textMd),
                                ),
                            ],
                          ),
                        ),
                        if (t.modifiers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: Sp.s1),
                            child: Text(
                              t.modifiers
                                      .take(2)
                                      .map((m) => m.display)
                                      .join(' · ') +
                                  (t.modifiers.length > 2 ? ' · …' : ''),
                              style: SatType.bodyS(color: sc.textMd),
                            ),
                          ),
                        const SizedBox(height: Sp.s2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (row.zoneName.isNotEmpty)
                              Text(
                                row.zoneName,
                                style: SatType.monoS(color: sc.textLo),
                              ),
                            StatusChip(status: t.status),
                            ElapsedPill(
                              clockStart: t.kitchenClockStart,
                              sentAtClock: t.sentAt,
                              terminal:
                                  isVoided || t.status == TicketStatus.served,
                              targetMins: lineTargetMins(ref, t.itemId),
                            ),
                            if (row.orderer != null)
                              StaffAvatar(actor: row.orderer!, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isReady)
                    SatButton.success(
                      label: 'Sajikan',
                      icon: Icons.check_rounded,
                      size: SatButtonSize.sm,
                      onTap: onServe,
                    )
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

