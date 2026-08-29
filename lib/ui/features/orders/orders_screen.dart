import 'package:flutter/material.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_tabs.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/shell_inset.dart';
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
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/widgets/staff_avatar.dart';
import 'package:satset/ui/core/widgets/elapsed_pill.dart';
import 'package:satset/ui/core/widgets/status_chip.dart';
import 'package:satset/ui/features/orders/view_models/orders_scope.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/state/tickers.dart';

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
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(context.l10n.ordServeFailed('$e'))),
        );
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
        ? context.l10n.ordEmptyPass
        : _seg == 'active'
        ? (showAll
              ? context.l10n.ordEmptyPreparingAll
              : context.l10n.ordEmptyPreparingMine)
        : (showAll
              ? context.l10n.ordEmptyDoneAll
              : context.l10n.ordEmptyDoneMine);

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
          // Column-major masonry rather than a SliverGrid: cards are
          // variable-height (a modifier line, a wrapped item name) and a grid
          // would pin every cell to the tallest case. Dealt alternately so the
          // oldest line is still top-left and reading stays left→right per
          // pair. Not lazily built — a segment is dozens of rows, not
          // thousands.
          Widget column(int start) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = start; i < rows.length; i += 2) orderRow(rows[i]),
            ],
          );
          slivers.add(
            SliverPadding(
              padding: pad,
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: column(0)),
                    const SizedBox(width: Sp.s2),
                    Expanded(child: column(1)),
                  ],
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
        SliverToBoxAdapter(child: SizedBox(height: grid ? 32 : context.shellInset)),
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
                        venueName.isEmpty
                            ? context.l10n.tabPesanan
                            : context.l10n.ordTitleVenue(venueName),
                        style: SatType.h1(color: sc.textHi),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.s1h),
                Text(
                  context.l10n.ordSummary(active.length, ready.length),
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
                  label: context.l10n.ordReadyForPickup,
                  count: ready.length,
                  selected: _seg == 'ready',
                  onTap: () => setState(() => _seg = 'ready'),
                ),
                const SizedBox(width: Sp.s2),
                SatChip.select(
                  label: context.l10n.ordPreparing,
                  count: active.length,
                  selected: _seg == 'active',
                  onTap: () => setState(() => _seg = 'active'),
                ),
                const SizedBox(width: Sp.s2),
                SatChip.select(
                  label: context.l10n.ordDone,
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
                      venueName.isEmpty
                          ? context.l10n.tabPesanan
                          : context.l10n.ordTitleVenue(venueName),
                      style: SatType.h1(color: sc.textHi),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.s1),
              Text(
                context.l10n.ordSummary(active.length, ready.length),
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
            ('ready', context.l10n.ordTabReady, ready),
            ('active', context.l10n.ordPreparing, active),
            ('done', context.l10n.ordDone, done),
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
      tabs: [
        SatTab(label: context.l10n.ordTabMine),
        SatTab(label: context.l10n.mnaAll),
      ],
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
    final terminal = isVoided || t.status == TicketStatus.served;
    final target = lineTargetMins(ref, t.itemId);

    // Past its own resolved target (ADR-0043/0064) — never the prototype's flat
    // 20 minutes, which would have the board disagree with the KDS and the
    // audible cue about when a line is late. Terminal lines can't be late.
    ref.watch(minuteTickerProvider);
    final slow =
        !terminal &&
        SatClock.now().difference(t.kitchenClockStart).inMinutes >= target;

    final bg = isReady ? sc.successSoft : sc.bg2;
    final border = slow
        ? sc.urgent
        : (isReady ? sc.success.withValues(alpha: 0.3) : sc.border0);

    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s2),
      child: Opacity(
        opacity: isVoided ? 0.55 : 1,
        child: Material(
          color: bg,
          borderRadius: SatR.a(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: SatR.a(16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.s4,
                vertical: Sp.s3h,
              ),
              decoration: SatBox.d(
                borderRadius: SatR.a(16),
                border: SatB.all(color: border, width: slow ? 2 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Head — who and where, then how long it has been waiting.
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (row.isTakeaway) ...[
                              // Takeaway rows carry no zone, so without the bag
                              // they read as a table with a missing one.
                              Icon(
                                Icons.shopping_bag_rounded,
                                size: 14,
                                color: isReady ? sc.success : sc.textMd,
                              ),
                              const SizedBox(width: Sp.s1h),
                            ],
                            Flexible(
                              child: Text(
                                row.token,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SatType.monoM(
                                  color: isReady ? sc.success : sc.textHi,
                                ),
                              ),
                            ),
                            if (row.zoneName.isNotEmpty) ...[
                              const SizedBox(width: Sp.s2),
                              Flexible(
                                child: SatChip.tag(
                                  label: row.zoneName,
                                  size: SatChipSize.sm,
                                ),
                              ),
                            ],
                            if (row.orderer != null) ...[
                              const SizedBox(width: Sp.s2),
                              StaffAvatar(actor: row.orderer!, size: 20),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: Sp.s2),
                      _ElapsedStack(
                        clockStart: t.kitchenClockStart,
                        sentAtClock: t.sentAt,
                        terminal: terminal,
                        late: slow,
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.s2h),
                  // Body — what was ordered.
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
                        t.modifiers.take(2).map((m) => m.display).join(' · ') +
                            (t.modifiers.length > 2 ? ' · …' : ''),
                        style: SatType.bodyS(color: sc.textMd),
                      ),
                    ),
                  const SizedBox(height: Sp.s2h),
                  // Foot — state, then the actions. The chevron stays on every
                  // row so the card's own tap target is never ambiguous.
                  Row(
                    children: [
                      StatusChip(status: t.status),
                      const Spacer(),
                      if (isReady) ...[
                        SatButton.success(
                          label: context.l10n.ordServe,
                          icon: Icons.check_rounded,
                          size: SatButtonSize.sm,
                          onTap: onServe,
                        ),
                        const SizedBox(width: Sp.s2),
                      ],
                      Icon(Icons.chevron_right, size: 16, color: sc.textLo),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The head's elapsed readout: "14m" over "sejak 18:02". Both facts at once —
/// how long the kitchen has owned the line, and the clock a waiter quotes to a
/// guest. Colour follows [_OrderRow]'s late test, so ring and number always
/// agree. Terminal lines freeze to the sent clock, like [ElapsedPill].
class _ElapsedStack extends ConsumerWidget {
  final DateTime clockStart;
  final String sentAtClock;
  final bool terminal;
  final bool late;
  const _ElapsedStack({
    required this.clockStart,
    required this.sentAtClock,
    required this.terminal,
    required this.late,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    if (terminal) {
      return Text(sentAtClock, style: SatType.caption(color: sc.textLo));
    }
    ref.watch(minuteTickerProvider);
    final d = SatClock.now().difference(clockStart);
    final mins = d.inMinutes;
    final label = mins < 1
        ? context.l10n.ordUnderMin
        : (d.inHours > 0
              ? context.l10n.durHm(d.inHours, mins.remainder(60))
              : context.l10n.durMins(mins));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: SatType.monoM(color: late ? sc.urgent : sc.textHi)),
        Text(
          context.l10n.ordSince(sentAtClock),
          style: SatType.caption(color: sc.textMd),
        ),
      ],
    );
  }
}
