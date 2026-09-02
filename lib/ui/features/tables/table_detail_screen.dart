import 'dart:async';
import 'package:satset/core/localization/labels.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_stepper.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/shell_inset.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/ui/core/design/course_visuals.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/features/printing/printer_picker.dart';
import 'package:satset/domain/models/zone.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/services/send_queue_service.dart';
import 'package:satset/domain/use_cases/advance_ticket_status_use_case.dart';
import 'package:satset/ui/core/widgets/ready_banner.dart';
import 'package:satset/ui/core/widgets/order_line_card.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/widgets/sat_icon_button.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart';
import 'package:satset/ui/core/widgets/note_line.dart';
import '../void_flow/line_item_action_sheet.dart';
import 'package:satset/ui/features/tables/widgets/move_table_sheet.dart';
import 'package:satset/ui/features/tables/widgets/pending_orders_block.dart';
import 'package:satset/ui/features/cashier/cashier_bill_screen.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/motion.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';

/// Height the floating action stack covers, plus the gap above it. Stacks on
/// `shellInset`, which clears the tab bar when there is one.
const double _actionStackClearance = 80;

// Motion tuning. Refined, calm — easeOutQuart per design tokens, no bounce.
// Mirrors the constants in tables_screen.dart so the grid → detail transition
// feels like one continuous surface.
const Duration _kChipMorph = Duration(milliseconds: 220);
const Duration _kPressIn = Duration(milliseconds: 90);

bool _animationsDisabled(BuildContext c) =>
    MediaQuery.maybeOf(c)?.disableAnimations ?? false;

/// The three-state answer ADR-0116 replaced a single `readOnly` boolean with.
///
/// * `readOnly` — no ordinary edit: fire, serve, close, cover count.
/// * `canQueueWrite` — take an order, void a line. The two acts the
///   [[Antrean kirim]] can honour, and the only two this screen produces.
///
/// They differ in exactly one state: terputus with nobody else holding the
/// lease. A handset that cannot reach the host cannot acquire the lease either,
/// so folding that into `readOnly` padlocked the screen in the one condition
/// the queue exists for — an order behind a table seated offline (ADR-0090) and
/// a void captured when the guest changes their mind (ADR-0114).
({bool readOnly, bool canQueueWrite}) tableAccess({
  required bool lockedByOther,
  required bool hasLease,
  required bool offline,
}) {
  // Someone else holds it, or we are online and simply have not got it.
  final lockedOut = lockedByOther || (!hasLease && !offline);
  return (readOnly: lockedOut || !hasLease, canQueueWrite: !lockedOut);
}

class TableDetailScreen extends ConsumerStatefulWidget {
  final String tableId;
  const TableDetailScreen({super.key, required this.tableId});

  @override
  ConsumerState<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends ConsumerState<TableDetailScreen> {
  // Heartbeat well under the server TTL so a single missed beat never
  // leaks the lock to another waiter.
  static const _heartbeatInterval = Duration(seconds: 3);
  static const _lockTtlSeconds = 7;

  Timer? _heartbeat;

  /// Auto-acquire timer: fires when the table becomes unlocked while this
  /// screen is open in read-only mode. Short grace window so the original
  /// holder can re-take the lock on a brief navigation.
  Timer? _autoAcquireTimer;
  static const _autoAcquireDelay = Duration(milliseconds: 1500);

  /// Cached so [dispose] can release the lock without touching `ref` — the
  /// underlying ConsumerStatefulElement rejects ref reads after unmount.
  TablesRepository? _tablesRepo;

  /// True once the server confirmed this session owns the lock. Cleared on a
  /// 409 heartbeat (someone else took over) or on dispose.
  bool _ownsLock = false;

  /// Set to true while the initial acquire attempt is in flight so the UI
  /// renders a spinner instead of flashing a "locked" banner on first frame.
  bool _acquiring = true;

  String get _tableId => widget.tableId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialAcquire());
  }

  /// Decide whether to acquire the lock on first frame. Kosong tables (status
  /// = available) carry no editable state — locking them serves no purpose
  /// and just blocks other waiters from viewing. The status listener in
  /// build() takes over once the row transitions to non-available.
  Future<void> _initialAcquire() async {
    final tables = ref.read(tablesProvider);
    final t = tables
        .where((x) => x.id == _tableId)
        .cast<VenueTable?>()
        .firstOrNull;
    if (t != null && t.status == TableStatus.available) {
      if (mounted) setState(() => _acquiring = false);
      return;
    }
    await _acquireLock();
  }

  Future<void> _acquireLock() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) {
      if (mounted) setState(() => _acquiring = false);
      return;
    }
    final repo = ref.read(tablesProvider.notifier);
    _tablesRepo = repo;
    try {
      final r = await repo.acquireLock(
        _tableId,
        userId: user.id,
        userName: user.name,
        ttlSeconds: _lockTtlSeconds,
      );
      if (!mounted) return;
      setState(() {
        _ownsLock = r.isAcquired;
        _acquiring = false;
      });
      if (r.isAcquired) _startHeartbeat();
    } catch (_) {
      // Server unreachable or capability denied — leave the UI read-only
      // (the table.lockedBy field, if any, still drives the banner).
      if (mounted) setState(() => _acquiring = false);
    }
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) async {
      if (!mounted) return;
      final user = ref.read(authStateProvider).user;
      final repo = _tablesRepo;
      if (user == null || repo == null) return;
      final ok = await repo.heartbeatLock(
        _tableId,
        userId: user.id,
        ttlSeconds: _lockTtlSeconds,
      );
      if (!ok && mounted) {
        setState(() => _ownsLock = false);
        _heartbeat?.cancel();
      }
    });
  }

  /// Schedule a short-delay auto-acquire when the table transitions to
  /// unlocked while this screen is open and we don't own it. The delay lets
  /// the previous holder re-acquire on a quick back/forward without us
  /// snatching the lock mid-blink.
  void _scheduleAutoAcquire() {
    _autoAcquireTimer?.cancel();
    _autoAcquireTimer = Timer(_autoAcquireDelay, _tryAutoAcquire);
  }

  Future<void> _tryAutoAcquire() async {
    if (!mounted || _ownsLock || _acquiring) return;
    final user = ref.read(authStateProvider).user;
    if (user == null) return;
    final repo = ref.read(tablesProvider.notifier);
    _tablesRepo = repo;
    setState(() => _acquiring = true);
    try {
      final r = await repo.acquireLock(
        _tableId,
        userId: user.id,
        userName: user.name,
        ttlSeconds: _lockTtlSeconds,
      );
      if (!mounted) return;
      setState(() {
        _ownsLock = r.isAcquired;
        _acquiring = false;
      });
      if (r.isAcquired) {
        _startHeartbeat();
      } else if (r.conflict != null) {
        final holder = r.conflict!.lockedByName ?? context.l10n.tblOtherUser;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.tblTakenBy(holder))),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _acquiring = false);
    }
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _autoAcquireTimer?.cancel();
    if (_ownsLock) {
      // Best-effort release via the cached repo reference — ref access here
      // would throw because the ConsumerStatefulElement has been disposed.
      _tablesRepo?.releaseLock(_tableId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    final tables = ref.watch(tablesProvider);
    final tickets = ref.watch(ticketsForTableProvider(_tableId));
    final table = tables.firstWhere(
      (t) => t.id == _tableId,
      orElse: () => VenueTable(id: _tableId, zoneId: ''),
    );
    final zones = ref.watch(zonesProvider);
    final zone = zones.firstWhere(
      (z) => z.id == table.zoneId,
      orElse: () => const Zone(id: '', name: '', short: ''),
    );
    final auth = ref.watch(
      authStateProvider.select(
        (s) => (
          id: s.user?.id,
          name: s.user?.name,
          canTakeOrder: s.has(Capability.takeOrder),
          canSettleBill: s.has(Capability.settleBill),
        ),
      ),
    );
    final actorId = auth.id;

    // Lock state: derived from server-pushed table row, so a WS update from
    // any client flips this screen between editable / read-only without
    // requiring a local poll.
    final lockedByOther = table.isLockedByOther(actorId);

    // Terputus with no lease is a *third* state, not a read-only table
    // (ADR-0116). A handset that cannot reach the host cannot acquire the
    // lease either, so `readOnly` used to swallow the outage and padlock the
    // screen — which made two documented offline paths unreachable at the one
    // place they were written for: an order queued behind a table seated
    // offline (ADR-0090) and a void captured when the guest changes their mind
    // (ADR-0114). Both have queue backing; nothing else on this screen does,
    // so the split unlocks exactly those two and leaves the rest disabled.
    //
    // The signal is `wsConnStateProvider`, the same one `submitOrder` and the
    // void path read to decide they must enqueue — so the button is offered
    // exactly when the queue will accept what it produces. Deliberately *not*
    // `_acquireLock`'s catch, which swallows a capability denial into the same
    // branch as a dead socket and would offer the FAB to a refused waiter.
    final access = tableAccess(
      lockedByOther: lockedByOther,
      hasLease: _ownsLock || _acquiring,
      offline: ref.watch(wsConnStateProvider) != WsConnState.open,
    );
    final readOnly = access.readOnly;
    final canQueueWrite = access.canQueueWrite;
    final offlineNoLease = readOnly && canQueueWrite;

    // Watch for two related transitions: (a) the current lock holder
    // releases while we're sitting read-only, or (b) the row flips from
    // `available` to a non-`available` status (a walk-in seat from another
    // waiter on the same kosong screen, or a server-side mutation). In both
    // cases we want to try to claim the lock — but only when the table is
    // actually in a lockable state. Kosong tables are intentionally
    // lock-free, so we skip auto-acquire on them.
    // (c) The socket returns. A lease cannot be asked for while terputus
    // (ADR-0116), so the screen would otherwise sit lease-less — and now
    // *looking* locked out — until the waiter backs out and comes in again.
    ref.listen<WsConnState>(wsConnStateProvider, (prev, next) {
      if (next != WsConnState.open || _ownsLock || actorId == null) return;
      final t = ref
          .read(tablesProvider)
          .where((x) => x.id == _tableId)
          .firstOrNull;
      if (t == null ||
          t.status == TableStatus.available ||
          t.isLockedByOther(actorId)) {
        return;
      }
      _scheduleAutoAcquire();
    });

    ref.listen<List<VenueTable>>(tablesProvider, (prev, next) {
      if (_ownsLock || actorId == null) return;
      final t = next.firstWhere(
        (x) => x.id == _tableId,
        orElse: () => VenueTable(id: _tableId, zoneId: ''),
      );
      if (t.status == TableStatus.available) {
        _autoAcquireTimer?.cancel();
        return;
      }
      final stillLocked = t.isLockedByOther(actorId);
      if (stillLocked) {
        _autoAcquireTimer?.cancel();
      } else {
        _scheduleAutoAcquire();
      }
    });
    final isKosong = table.status == TableStatus.available;
    final hasPending = ref
        .watch(pendingOrdersForTableProvider(table.id))
        .isNotEmpty;
    final canSeat = isKosong && auth.canTakeOrder && !lockedByOther;
    // Gate by capability, not role enum: admins also have takeOrder and need
    // to be able to correct guest counts during testing/coverage.
    final canEditGuests = auth.canTakeOrder && !readOnly;

    Future<void> onSeat() async {
      if (!canSeat || actorId == null) return;
      try {
        await ref
            .read(tablesProvider.notifier)
            .seat(_tableId, pax: 1, userId: actorId, userName: auth.name);
        // The status flip from `available` → `occupied` triggers the
        // tablesProvider listener above, which schedules the auto-acquire.
        // No explicit lock call here.
      } on ApiException catch (e) {
        if (!context.mounted) return;
        final holder = table.lockedByName ?? context.l10n.tblOtherUser;
        final msg = e.code == 'already_seated'
            ? context.l10n.tblAlreadySeated(holder)
            : context.l10n.tblSeatFailed('${e.code ?? e.statusCode}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.tblSeatFailed('$e'))),
        );
      }
    }

    void onMinus() {
      if (readOnly) return;
      ref.read(tablesProvider.notifier).decrementPax(_tableId);
    }

    void onPlus() {
      if (readOnly) return;
      ref.read(tablesProvider.notifier).incrementPax(_tableId);
    }

    final grouped = <CourseId, List<Ticket>>{};
    for (final t in tickets) {
      grouped.putIfAbsent(t.course, () => []).add(t);
    }
    final readyAny = tickets.any((t) => t.status == TicketStatus.ready);
    final liveStatuses = {
      TicketStatus.draft,
      TicketStatus.acknowledged,
      TicketStatus.held,
      TicketStatus.sent,
      TicketStatus.prep,
      TicketStatus.cooked,
      TicketStatus.ready,
    };
    final hasLive = tickets.any((t) => liveStatuses.contains(t.status));
    // Allow closing a seated table that never got an order (guest leaves
    // before ordering) as well as one whose tickets are all done. The only
    // block is an in-flight ticket.
    final canClose = !readOnly && !hasLive;
    final isEmptyClose = tickets.isEmpty;
    final closeLabel = isEmptyClose
        ? context.l10n.tblReleaseTable
        : context.l10n.tblFinishService;

    final menuItems = ref.watch(menuItemsProvider);
    final ctxAllergens = <String>{};
    for (final t in tickets) {
      final it = menuItems.where((i) => i.id == t.itemId).firstOrNull;
      if (it != null) ctxAllergens.addAll(it.allergens);
    }
    // Notes are reference text, not alerts — only allergens drive the header
    // attention badge. See CONTEXT.md "Guest note / Item note".
    final ctxAlertCount = ctxAllergens.length;

    void showContextSheet() {
      showSatSheet(
        context,
        bare: true,
        builder: (_) =>
            _ContextSheet(table: table, tickets: tickets, menu: menuItems),
      );
    }

    // The context pane reads menu metadata (allergens) — surface load state
    // explicitly rather than rendering against an empty cache.
    // ...but a cache that loaded once is worth more than a spinner or a dead
    // end. Offline is this app's ordinary state, and the table's own tickets
    // come from a different provider: only an *empty* cache leaves nothing to
    // draw. See design principle 6.
    final menuStatus = ref.watch(menuStatusProvider);
    if (menuStatus.isLoading && menuItems.isEmpty) {
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
    if (menuStatus.hasError && menuItems.isEmpty) {
      return Scaffold(
        backgroundColor: sc.bg0,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Sp.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 36, color: sc.urgent),
                const SizedBox(height: Sp.s2h),
                Text(
                  context.l10n.tblMenuLoadFailed,
                  style: SatType.labelL(color: sc.textHi),
                ),
                const SizedBox(height: Sp.s3),
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

    Future<void> markServed(String id) async {
      if (readOnly) return;
      // Server maintains table.readyCount + status transactionally on the
      // ticket transition and broadcasts table.updated; the client must not
      // perform a second, non-atomic decrement here.
      await ref
          .read(advanceTicketStatusUseCaseProvider)
          .call(_tableId, id, TicketStatus.served);
    }

    Future<void> fireCourse(CourseId cid) async {
      if (readOnly) return;
      await ref.read(ticketsProvider.notifier).fireCourse(_tableId, cid);
    }

    void openAction(Ticket t) {
      // A void is capturable while terputus (ADR-0114) and this is the only
      // dine-in door to the sheet, so it opens on `canQueueWrite`, not on the
      // lease. Takeaway never had the problem — it holds no lock (ADR-0026).
      if (!canQueueWrite) return;
      showLineItemActionSheet(context: context, tableId: _tableId, ticket: t);
    }

    void onAdd() {
      // Composing an order is legal without a lease the handset could not have
      // got (ADR-0116); `submitOrder` enqueues it and the host arbitrates.
      if (!canQueueWrite) return;
      context.push('/table/$_tableId/menu');
    }

    Future<void> onClose() async {
      if (!canClose) return;
      final choice = await showSatDialog<String>(
        context,
        builder: (ctx) => AlertDialog(
          title: Text(
            isEmptyClose
                ? context.l10n.tblReleaseTableQ
                : context.l10n.tblFinishServiceQ,
          ),
          content: Text(
            // A settled table gets told so. The unpaid copy sends the waiter to
            // chase a bill the guest already paid — and `'partial'` keeps that
            // copy, because part-paid still owes something at the till.
            isEmptyClose
                ? context.l10n.tblReleaseBody(table.displayName)
                : (table.billClosed || table.moneyState == 'paid')
                ? context.l10n.tblFinishBodyPaid(table.displayName)
                : context.l10n.tblFinishBody(table.displayName),
          ),
          actions: [
            SatButton.ghost(
              label: context.l10n.cancel,
              onTap: () => Navigator.of(ctx).pop('cancel'),
            ),
            if (!isEmptyClose)
              SatButton.ghost(
                label: context.l10n.cshPrintReceipt,
                onTap: () => Navigator.of(ctx).pop('print'),
              ),
            SatButton.primary(
              label: closeLabel,
              onTap: () => Navigator.of(ctx).pop('close'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      // "Cetak struk" is a step before settling, not a substitute — print, then
      // leave the table live so the waiter can re-confirm before closing.
      if (choice == 'print') {
        await printTableStruk(
          context: context,
          ref: ref,
          table: table,
          tickets: tickets,
        );
        return;
      }
      if (choice != 'close') return;
      try {
        final notifier = ref.read(tablesProvider.notifier);
        if (isEmptyClose) {
          await notifier.releaseTable(_tableId, actorId: actorId);
        } else {
          await notifier.closeTable(_tableId, actorId: actorId);
        }
        if (context.mounted) safePop(context);
      } on ApiException catch (e) {
        // The one refusal a waiter can actually act on, and the one they hit
        // after voiding a line on a terputus handset: the host still sees that
        // line live, because the void is on the queue. Raw `$e` here rendered
        // the JSON body at them.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.code == 'tickets_not_terminal'
                    ? context.l10n.tblCloseNotTerminal
                    : context.l10n.tblCloseFailed('${e.code ?? e.statusCode}'),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.tblCloseFailed('$e'))),
          );
        }
      }
    }

    final lockBanner = lockedByOther
        ? _LockedBanner(
            holderName: table.lockedByName ?? context.l10n.tblOtherUser,
            since: table.lockedAt,
          )
        : null;

    if (tables.isNotEmpty && !tables.any((t) => t.id == _tableId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) safePop(context);
      });
    }

    final appBar = SatAppBar(
      onBack: () => safePop(context),
      // No bare `Meja` segment ahead of the table's own name: `Meja › Meja 12`
      // is an echo, and a table name identifies itself.
      crumbs: [table.displayName, if (zone.name.isNotEmpty) zone.name],
      trailingPills: [
        if (auth.canSettleBill && table.currentVisitId != null)
          SatIconButton.plain(
            icon: Icons.receipt_long_rounded,
            tooltip: context.l10n.cshCrumbBill,
            onTap: () =>
                openCashierBill(context, visitId: table.currentVisitId!),
          ),
      ],
    );

    if (l.useTabletShell) {
      return _TabletSplit(
        menu: ref.watch(menuItemsProvider),
        appBar: appBar,
        table: table,
        zone: zone,
        tickets: tickets,
        grouped: grouped,
        readyAny: readyAny,
        canEditGuests: canEditGuests,
        readOnly: readOnly,
        canQueueWrite: canQueueWrite,
        canClose: canClose,
        closeLabel: closeLabel,
        isKosong: isKosong,
        canSeat: canSeat,
        hasPending: hasPending,
        lockBanner: lockBanner,
        onMinusPax: onMinus,
        onPlusPax: onPlus,
        onMarkServed: markServed,
        onFireCourse: fireCourse,
        onTicketTap: openAction,
        onAdd: onAdd,
        onSeat: onSeat,
        onClose: onClose,
        onBack: () => safePop(context),
      );
    }

    return Scaffold(
      backgroundColor: sc.bg0,
      body: Stack(
        children: [
          Column(
            children: [
              appBar,
              _TableDetailHeader(
                table: table,
                zoneName: zone.name,
                canEditGuests: canEditGuests,
                onMinusPax: onMinus,
                onPlusPax: onPlus,
                alertCount: ctxAlertCount,
                onShowContext: showContextSheet,
              ),
              ?lockBanner,
              // In flow with the other banners rather than in the floating
              // action column: the list is often shorter than the viewport, so
              // a floating note has nothing to be pushed clear of and lands on
              // the last card.
              if (offlineNoLease)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Sp.s4,
                    vertical: Sp.s1h,
                  ),
                  child: _OfflineNoLeaseNote(),
                ),
              if (readyAny) const ReadyBanner(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
                    child: isKosong
                        ? _KosongSeatCard(
                            tableName: table.displayName,
                            enabled: canSeat,
                            onTap: onSeat,
                          )
                        : ListView(
                            padding: EdgeInsets.fromLTRB(
                              0,
                              0,
                              0,
                              context.shellInset + _actionStackClearance,
                            ),
                            children: [
                              PendingOrdersBlock(tableId: table.id),
                              for (final (i, cid)
                                  in Courses.all.map((c) => c.id).indexed)
                                if (grouped[cid] != null &&
                                    grouped[cid]!.isNotEmpty)
                                  Reveal(
                                    index: i,
                                    child: _DetailCourseBlock(
                                      course: Courses.byId(cid),
                                      items: grouped[cid]!,
                                      readOnly: readOnly,
                                      canQueueWrite: canQueueWrite,
                                      onMarkServed: markServed,
                                      onFireCourse: () => fireCourse(cid),
                                      onTicketTap: openAction,
                                    ),
                                  ),
                              if (tickets.isEmpty && !hasPending)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    32,
                                    24,
                                    32,
                                  ),
                                  child: Text(
                                    context.l10n.tblEmptyPhone,
                                    textAlign: TextAlign.center,
                                    style: SatType.bodyM(color: sc.textLo),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (!isKosong)
            Positioned(
              left: 16 + l.padding.left,
              right: 16 + l.padding.right,
              bottom: Sp.s4 + context.shellInset + l.padding.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canClose)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Sp.s2h),
                      child: _CloseTableButton(
                        label: closeLabel,
                        onTap: onClose,
                      ),
                    ),
                  _PrimaryIconButton(
                    // The padlock means "someone else has this table", never
                    // "the network is down" — offline still adds (ADR-0116).
                    icon: canQueueWrite ? Icons.add : Icons.lock_outline,
                    enabled: canQueueWrite,
                    onTap: onAdd,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Per-second tick used by the live elapsed pill in [_TableDetailHeader]. autoDispose so
/// the stream stops while no table_detail screen is mounted.
final _detailElapsedTickerProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => SatClock.now(),
  ),
);

class _TableDetailHeader extends ConsumerWidget {
  final VenueTable table;
  final String zoneName;
  final bool canEditGuests;
  final VoidCallback onMinusPax;
  final VoidCallback onPlusPax;
  final int alertCount;
  final VoidCallback onShowContext;
  const _TableDetailHeader({
    required this.table,
    required this.zoneName,
    required this.canEditGuests,
    required this.onMinusPax,
    required this.onPlusPax,
    required this.alertCount,
    required this.onShowContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    // Watch the ticker so the elapsed pill rebuilds every second when
    // `openedAt` is set. Read-only watchers don't penalize render cost.
    ref.watch(_detailElapsedTickerProvider);
    final elapsedStr = table.openedAt == null
        ? null
        : formatElapsed(
            context.l10n,
            SatClock.now().difference(table.openedAt!),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                table.displayName,
                maxLines: 1,
                style: SatType.monoDisplay54(color: sc.textHi),
              ),
            ),
          ),
          const SizedBox(width: Sp.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zoneName, style: SatType.bodyM(color: sc.textMd)),
                const SizedBox(height: Sp.s2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SatStepper.pill(
                      value: table.pax,
                      max: table.capacity,
                      enabled: canEditGuests,
                      icon: Icons.person_outline,
                      showMax: true,
                      size: SatStepperSize.sm,
                      semanticLabel: context.l10n.tableGuests,
                      onChanged: (v) =>
                          v > table.pax ? onPlusPax() : onMinusPax(),
                    ),
                    const SizedBox(width: Sp.s2),
                    _ContextTriggerBtn(
                      alertCount: alertCount,
                      onTap: onShowContext,
                    ),
                    if (elapsedStr != null) ...[
                      const SizedBox(width: Sp.s2),
                      // Flexible, because this label grows all shift: the chip
                      // ellipsizes once the row runs out, instead of painting
                      // the overflow stripe over the header.
                      Flexible(
                        child: SatChip.tag(
                          icon: Icons.access_time,
                          label: elapsedStr,
                          size: SatChipSize.sm,
                        ),
                      ),
                    ],
                  ],
                ),
                if ((table.guestName != null &&
                        table.guestName!.trim().isNotEmpty) ||
                    (table.guestNotes != null &&
                        table.guestNotes!.trim().isNotEmpty)) ...[
                  const SizedBox(height: Sp.s1h),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (table.guestName != null &&
                          table.guestName!.trim().isNotEmpty)
                        SatChip.tag(
                          icon: Icons.person_outline,
                          label: table.guestName!,
                          size: SatChipSize.sm,
                        ),
                      if (table.guestNotes != null &&
                          table.guestNotes!.trim().isNotEmpty)
                        NoteLine(text: table.guestNotes!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How long the table has been seated, ticking. The chip itself is a plain
/// [SatChip.tag] — what earns a widget here is the per-second rebuild, which
/// a const chip cannot do.
class _LiveSeatedChip extends ConsumerWidget {
  final DateTime openedAt;
  const _LiveSeatedChip({required this.openedAt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_detailElapsedTickerProvider);
    return SatChip.tag(
      icon: Icons.access_time,
      label: formatElapsed(context.l10n, SatClock.now().difference(openedAt)),
      size: SatChipSize.sm,
    );
  }
}

class _ContextTriggerBtn extends StatelessWidget {
  final int alertCount;
  final VoidCallback onTap;
  const _ContextTriggerBtn({required this.alertCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Material(
      color: sc.bg2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: Sp.s8,
          height: 32,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: SatBox.d(
                  shape: BoxShape.circle,
                  border: SatB.all(color: sc.border0),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.info_outline, size: 16, color: sc.textMd),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: AnimatedSwitcher(
                  duration: _animationsDisabled(context)
                      ? Duration.zero
                      : _kChipMorph,
                  switchInCurve: satEaseOut,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: alertCount == 0
                      ? const SizedBox.shrink()
                      : Container(
                          key: ValueKey(alertCount),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Sp.s1,
                          ),
                          decoration: SatBox.d(
                            color: sc.urgent,
                            shape: alertCount < 10
                                ? BoxShape.circle
                                : BoxShape.rectangle,
                            borderRadius: alertCount < 10 ? null : SatR.a(8),
                            border: SatB.all(color: sc.bg0, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$alertCount',
                            style: SatType.caption(color: onFill(sc.urgent)),
                          ),
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

class _ContextSheet extends StatelessWidget {
  final VenueTable table;
  final List<Ticket> tickets;
  final List<MenuItem> menu;
  const _ContextSheet({
    required this.table,
    required this.tickets,
    required this.menu,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: SatBox.d(
          color: sc.bg1,
          borderRadius: BorderRadius.vertical(top: SatR.c(22)),
          border: SatB.all(color: sc.border0),
        ),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.zero,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: Sp.s2h),
                width: 36,
                height: 4,
                decoration: SatBox.d(
                  color: sc.border1,
                  borderRadius: SatR.a(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.tblContextTitle,
                    style: SatType.h2(color: sc.textHi),
                  ),
                  const SizedBox(height: Sp.s1),
                  Text(
                    context.l10n.tblSeatedFor(
                      formatElapsed(
                        context.l10n,
                        SatClock.now().difference(
                          table.openedAt ?? SatClock.now(),
                        ),
                      ),
                      table.pax,
                    ),
                    style: SatType.monoS(color: sc.textLo),
                  ),
                ],
              ),
            ),
            _ContextPane(
              table: table,
              tickets: tickets,
              menu: menu,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCourseBlock extends StatelessWidget {
  final Course course;
  final List<Ticket> items;
  final void Function(String) onMarkServed;
  final VoidCallback onFireCourse;
  final void Function(Ticket) onTicketTap;
  final bool readOnly;

  /// Whether the line may still be *tapped* — the void sheet behind that tap
  /// has a queue, so it survives an outage the serve and fire buttons do not
  /// (ADR-0116). Defaults to `!readOnly`, which is the online case.
  final bool? canQueueWrite;

  const _DetailCourseBlock({
    required this.course,
    required this.items,
    required this.onMarkServed,
    required this.onFireCourse,
    required this.onTicketTap,
    this.readOnly = false,
    this.canQueueWrite,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final allHeld = items.every((it) => it.status == TicketStatus.held);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: SatBox.d(
                    shape: BoxShape.circle,
                    color: course.color(sc),
                  ),
                ),
                const SizedBox(width: Sp.s2h),
                Text(
                  courseLabel(context.l10n, course.serialId).toUpperCase(),
                  style: SatType.caption(color: sc.textMd),
                ),
                const Spacer(),
                Text(
                  allHeld
                      ? context.l10n.tblItemCountHeld(items.length)
                      : context.l10n.tblItemCount(items.length),
                  style: SatType.monoS(color: sc.textLo),
                ),
              ],
            ),
          ),
          for (final it in items)
            OrderLineCard(
              ticket: it,
              onTap: () => onTicketTap(it),
              onMarkServed: onMarkServed,
              readOnly: readOnly,
              tappableWhenReadOnly: canQueueWrite,
            ),
          if (allHeld && !readOnly)
            Padding(
              padding: const EdgeInsets.only(top: Sp.s1h),
              child: _FireButton(
                label: context.l10n.tblFireCourse(
                  courseLabel(context.l10n, course.serialId),
                ),
                onTap: onFireCourse,
              ),
            ),
        ],
      ),
    );
  }
}

class _FireButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FireButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SatButton.outline(
        label: label.toUpperCase(),
        icon: Icons.local_fire_department,
        onTap: onTap,
      ),
    );
  }
}

class _KosongSeatCard extends StatefulWidget {
  final String tableName;
  final bool enabled;
  final VoidCallback onTap;
  const _KosongSeatCard({
    required this.tableName,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_KosongSeatCard> createState() => _KosongSeatCardState();
}

class _KosongSeatCardState extends State<_KosongSeatCard>
    with SingleTickerProviderStateMixin {
  // Slow breathing on the CTA — a calm "ready when you are" invitation, not a
  // nag. Pauses entirely when disabled or reduced-motion is on.
  late final AnimationController _breathe;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.enabled) _breathe.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _KosongSeatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_breathe.isAnimating) {
      _breathe.repeat(reverse: true);
    } else if (!widget.enabled && _breathe.isAnimating) {
      _breathe.stop();
      _breathe.value = 0;
    }
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final enabled = widget.enabled;
    final reduced = _animationsDisabled(context);
    final bg = enabled ? sc.accent : sc.bg3;
    final fg = enabled ? sc.accentInk : sc.textLo;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.s7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: SatBox.d(color: sc.bg2, borderRadius: SatR.a(36)),
              child: Icon(
                Icons.event_seat_outlined,
                size: 36,
                color: sc.textMd,
              ),
            ),
            const SizedBox(height: Sp.s4h),
            Text(
              context.l10n.tblKosong(widget.tableName),
              style: SatType.labelL(color: sc.textHi),
            ),
            const SizedBox(height: Sp.s1h),
            Text(
              context.l10n.tblKosongHint,
              style: SatType.bodyM(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s6),
            Opacity(
              opacity: enabled ? 1 : 0.5,
              child: AnimatedBuilder(
                animation: _breathe,
                builder: (context, child) {
                  final breath = (enabled && !reduced)
                      ? 1 + 0.025 * _breathe.value
                      : 1.0;
                  final scale = _pressed ? 0.96 : breath;
                  final glow = (enabled && !reduced) ? _breathe.value : 0.0;
                  return Transform.scale(
                    scale: scale,
                    child: DecoratedBox(
                      decoration: SatBox.d(
                        borderRadius: SatR.a(16),
                        boxShadow: glow > 0
                            ? [
                                BoxShadow(
                                  color: sc.accent.withValues(
                                    alpha: 0.18 + 0.16 * glow,
                                  ),
                                  blurRadius: 12 + 10 * glow,
                                  spreadRadius: glow,
                                ),
                              ]
                            : null,
                      ),
                      child: child,
                    ),
                  );
                },
                child: Material(
                  color: bg,
                  borderRadius: SatR.a(16),
                  child: InkWell(
                    onTap: enabled ? widget.onTap : null,
                    onHighlightChanged: (h) {
                      if (enabled) setState(() => _pressed = h);
                    },
                    borderRadius: SatR.a(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sp.s7,
                        vertical: Sp.s4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_fill, size: 22, color: fg),
                          const SizedBox(width: Sp.s2h),
                          Text(
                            context.l10n.tblStartService,
                            style: SatType.labelL(color: fg),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _PrimaryIconButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<_PrimaryIconButton> createState() => _PrimaryIconButtonState();
}

class _PrimaryIconButtonState extends State<_PrimaryIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final enabled = widget.enabled;
    final reduced = _animationsDisabled(context);
    final fg = enabled ? sc.accentInk : sc.textLo;
    final bg = enabled ? sc.accent : sc.bg3;
    return Semantics(
      button: true,
      enabled: enabled,
      // Disabled here means the table is locked by someone else, which is the
      // reason the waiter cannot add — say that rather than let the glyph swap
      // silently.
      label: enabled ? context.l10n.a11yAddItem : context.l10n.a11yTableLocked,
      child: Center(
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: reduced ? Duration.zero : _kPressIn,
          curve: satEaseOut,
          child: AnimatedContainer(
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: satStatusXfadeMs),
            curve: satEaseOut,
            decoration: SatBox.d(color: bg, shape: BoxShape.circle),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                onTap: enabled ? widget.onTap : null,
                onHighlightChanged: (h) {
                  if (enabled) setState(() => _pressed = h);
                },
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Icon(widget.icon, size: 28, color: fg),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseTableButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _CloseTableButton({required this.label, required this.onTap});

  @override
  State<_CloseTableButton> createState() => _CloseTableButtonState();
}

class _CloseTableButtonState extends State<_CloseTableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final reduced = _animationsDisabled(context);
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: reduced ? Duration.zero : _kPressIn,
      curve: satEaseOut,
      child: SizedBox(
        height: 52,
        child: Material(
          color: sc.success,
          borderRadius: SatR.a(18),
          elevation: 0,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (h) => setState(() => _pressed = h),
            borderRadius: SatR.a(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.s6),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20, color: sc.successInk),
                  const SizedBox(width: Sp.s2h),
                  Text(
                    widget.label,
                    style: SatType.labelL(color: sc.successInk),
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

class _LockedBanner extends StatelessWidget {
  final String holderName;
  final DateTime? since;
  const _LockedBanner({required this.holderName, required this.since});

  String _hhmm(DateTime d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    final local = d.toLocal();
    return '${pad(local.hour)}:${pad(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final sinceLabel = since == null
        ? ''
        : context.l10n.tblLockedSince(_hhmm(since!));
    return Reveal(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(
          horizontal: Sp.s3h,
          vertical: Sp.s2h,
        ),
        decoration: SatBox.d(
          color: sc.warnSoft,
          border: SatB.all(color: sc.warn.withValues(alpha: 0.35)),
          borderRadius: SatR.a(12),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, size: 16, color: sc.warn),
            const SizedBox(width: Sp.s2h),
            Expanded(
              child: Text(
                context.l10n.tblLockedBy(holderName, sinceLabel),
                style: SatType.bodyM(color: sc.warn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Says which half of the screen is still live while the handset is terputus
/// and holds no lease (ADR-0116) — without it the enabled "Tambah pesanan"
/// button next to a dead socket reads as a bug rather than as the queue doing
/// its job. Deliberately not urgent: nothing has failed.
class _OfflineNoLeaseNote extends StatelessWidget {
  const _OfflineNoLeaseNote();

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3h, vertical: Sp.s2h),
      decoration: SatBox.d(
        color: sc.warnSoft,
        border: SatB.all(color: sc.warn.withValues(alpha: 0.35)),
        borderRadius: SatR.a(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 16, color: sc.warn),
          const SizedBox(width: Sp.s2h),
          Expanded(
            child: Text(
              context.l10n.tblOfflineQueueNote,
              style: SatType.bodyS(color: sc.warn),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletSplit extends StatelessWidget {
  final List<MenuItem> menu;
  final Widget appBar;
  final VenueTable table;
  final Zone zone;
  final List<Ticket> tickets;
  final Map<CourseId, List<Ticket>> grouped;
  final bool readyAny;
  final bool canEditGuests;
  final bool readOnly;

  /// Order and void survive an outage the rest of this pane does not; see
  /// ADR-0116. Distinct from `!readOnly` only while terputus.
  final bool canQueueWrite;
  final bool canClose;
  final String closeLabel;
  final bool isKosong;
  final bool canSeat;

  /// Whether the send queue is holding lines for this table. Passed in rather
  /// than watched here so the "no lines yet" copy and the pending block can
  /// never both be on screen.
  final bool hasPending;
  final Widget? lockBanner;
  final VoidCallback onMinusPax;
  final VoidCallback onPlusPax;
  final void Function(String) onMarkServed;
  final void Function(CourseId) onFireCourse;
  final void Function(Ticket) onTicketTap;
  final VoidCallback onAdd;
  final VoidCallback onSeat;
  final VoidCallback onClose;
  final VoidCallback onBack;

  const _TabletSplit({
    required this.menu,
    required this.appBar,
    required this.table,
    required this.zone,
    required this.tickets,
    required this.grouped,
    required this.readyAny,
    required this.canEditGuests,
    required this.readOnly,
    required this.canQueueWrite,
    required this.canClose,
    required this.closeLabel,
    required this.isKosong,
    required this.canSeat,
    required this.hasPending,
    required this.lockBanner,
    required this.onMinusPax,
    required this.onPlusPax,
    required this.onMarkServed,
    required this.onFireCourse,
    required this.onTicketTap,
    required this.onAdd,
    required this.onSeat,
    required this.onClose,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final readyN = tickets.where((t) => t.status == TicketStatus.ready).length;
    return Scaffold(
      backgroundColor: sc.bg0,
      body: Column(
        children: [
          appBar,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 560,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(28, 22, 28, 16),
                        decoration: SatBox.d(
                          border: Border(bottom: SatB.side(color: sc.border0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      table.displayName,
                                      maxLines: 1,
                                      style: SatType.monoDisplay54(
                                        color: sc.textHi,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Sp.s3h),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: Sp.s2),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        zone.name,
                                        style: SatType.bodyL(color: sc.textMd),
                                      ),
                                      const SizedBox(height: Sp.s1h),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SatStepper.pill(
                                            value: table.pax,
                                            max: table.capacity,
                                            enabled: canEditGuests,
                                            icon: Icons.person_outline,
                                            showMax: true,
                                            semanticLabel:
                                                context.l10n.tableGuests,
                                            onChanged: (v) => v > table.pax
                                                ? onPlusPax()
                                                : onMinusPax(),
                                          ),
                                          if (table.openedAt != null) ...[
                                            const SizedBox(width: Sp.s2h),
                                            _LiveSeatedChip(
                                              openedAt: table.openedAt!,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (readyN > 0 ||
                                (table.guestName != null &&
                                    table.guestName!.trim().isNotEmpty) ||
                                (table.guestNotes != null &&
                                    table.guestNotes!.trim().isNotEmpty)) ...[
                              const SizedBox(height: Sp.s3h),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (readyN > 0)
                                    _pill(
                                      context,
                                      sc,
                                      context.l10n.tblReadyToCollect(readyN),
                                      tone: 'success',
                                    ),
                                  if (table.guestName != null &&
                                      table.guestName!.trim().isNotEmpty)
                                    _pill(
                                      context,
                                      sc,
                                      '👤 ${table.guestName!}',
                                    ),
                                  if (table.guestNotes != null &&
                                      table.guestNotes!.trim().isNotEmpty)
                                    NoteLine(text: table.guestNotes!),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      ?lockBanner,
                      Expanded(
                        child: isKosong
                            ? _KosongSeatCard(
                                tableName: table.displayName,
                                enabled: canSeat,
                                onTap: onSeat,
                              )
                            : tickets.isEmpty && !hasPending
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(Sp.s7),
                                  child: Text(
                                    context.l10n.tblDetailEmptyLines,
                                    textAlign: TextAlign.center,
                                    style: SatType.bodyM(color: sc.textLo),
                                  ),
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  16,
                                  24,
                                  16,
                                ),
                                children: [
                                  PendingOrdersBlock(tableId: table.id),
                                  for (final (i, cid)
                                      in Courses.all.map((c) => c.id).indexed)
                                    if (grouped[cid] != null &&
                                        grouped[cid]!.isNotEmpty)
                                      Reveal(
                                        index: i,
                                        child: _DetailCourseBlock(
                                          course: Courses.byId(cid),
                                          items: grouped[cid]!,
                                          readOnly: readOnly,
                                          canQueueWrite: canQueueWrite,
                                          onMarkServed: onMarkServed,
                                          onFireCourse: () => onFireCourse(cid),
                                          onTicketTap: onTicketTap,
                                        ),
                                      ),
                                ],
                              ),
                      ),
                      if (!isKosong)
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                          decoration: SatBox.d(
                            border: Border(top: SatB.side(color: sc.border0)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Read-only *and* still writable is exactly the
                              // terputus-without-lease state (ADR-0116) — the
                              // phone derives it the same way from its own
                              // flags, so no third field crosses the ctor.
                              if (readOnly && canQueueWrite) ...[
                                const _OfflineNoLeaseNote(),
                                const SizedBox(height: Sp.s2h),
                              ],
                              Row(
                                children: [
                                  if (canClose) ...[
                                    Expanded(
                                      child: _CloseTableButton(
                                        label: closeLabel,
                                        onTap: onClose,
                                      ),
                                    ),
                                    const SizedBox(width: Sp.s2h),
                                  ],
                                  Expanded(
                                    flex: canClose ? 1 : 1,
                                    child: Opacity(
                                      opacity: canQueueWrite ? 1 : 0.5,
                                      child: Material(
                                        color: sc.accent,
                                        borderRadius: SatR.a(14),
                                        child: InkWell(
                                          onTap: canQueueWrite ? onAdd : null,
                                          borderRadius: SatR.a(14),
                                          child: Container(
                                            height: 52,
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  // The padlock means "someone else
                                                  // has this table", never "the
                                                  // network is down" (ADR-0116).
                                                  canQueueWrite
                                                      ? Icons.add
                                                      : Icons.lock_outline,
                                                  size: 18,
                                                  color: sc.accentInk,
                                                ),
                                                const SizedBox(width: Sp.s2),
                                                Text(
                                                  !canQueueWrite
                                                      ? context.l10n.tblViewOnly
                                                      : (tickets.isEmpty
                                                            ? context
                                                                  .l10n
                                                                  .tblCreateOrder
                                                            : context
                                                                  .l10n
                                                                  .tblAddOrder),
                                                  style: SatType.labelL(
                                                    color: sc.accentInk,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(width: 1, color: sc.border0),
                Expanded(
                  child: _ContextPane(
                    table: table,
                    tickets: tickets,
                    menu: menu,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(
    BuildContext context,
    SatColors sc,
    String text, {
    String tone = 'normal',
  }) {
    Color bg = sc.bg3;
    Color fg = sc.textMd;
    Color border = sc.border1;
    if (tone == 'success') {
      bg = sc.successSoft;
      fg = sc.success;
      border = sc.success.withValues(alpha: 0.3);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s2h, vertical: Sp.s1h),
      decoration: SatBox.d(
        color: bg,
        border: SatB.all(color: border),
        borderRadius: SatR.a(999),
      ),
      child: Text(text, style: SatType.bodyS(color: fg)),
    );
  }
}

class _ContextPane extends ConsumerWidget {
  final VenueTable table;
  final List<Ticket> tickets;
  final List<MenuItem> menu;
  final bool compact;
  const _ContextPane({
    required this.table,
    required this.tickets,
    required this.menu,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final auth = ref.watch(
      authStateProvider.select(
        (s) => (id: s.user?.id, canTakeOrder: s.has(Capability.takeOrder)),
      ),
    );
    final actorId = auth.id;
    // Move is offered only on a live table the caller may operate and that
    // isn't actively held by someone else. Server re-checks the lock anyway.
    final canMove =
        table.status != TableStatus.available &&
        auth.canTakeOrder &&
        !table.isLockedByOther(actorId);
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    Future<void> onMove() async {
      final targetId = await showMoveTableSheet(
        context: context,
        sourceId: table.id,
      );
      if (targetId == null) return;
      // Phone shows this pane inside the modal context sheet — close it first;
      // the tablet pane is inline so there's nothing to pop. Then land the
      // waiter on the moved session (it already holds the lock, see ADR-0019).
      if (compact && navigator.canPop()) navigator.pop();
      router.pushReplacement('/table/$targetId');
    }

    final sent = tickets
        .where(
          (t) =>
              t.status != TicketStatus.voided &&
              t.status != TicketStatus.served,
        )
        .length;
    final served = tickets.where((t) => t.status == TicketStatus.served).length;
    final allergens = <String>{};
    for (final t in tickets) {
      final it = menu.where((i) => i.id == t.itemId).firstOrNull;
      if (it != null) allergens.addAll(it.allergens);
    }
    final guestNotes = <String>{
      for (final t in tickets)
        if (t.note != null && t.note!.trim().isNotEmpty) t.note!.trim(),
    }.toList();

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _stat(
                context,
                sc,
                tickets.length.toString(),
                context.l10n.tblStatTotal,
              ),
            ),
            const SizedBox(width: Sp.s2),
            Expanded(
              child: _stat(
                context,
                sc,
                sent.toString(),
                context.l10n.tblStatInProgress,
              ),
            ),
            const SizedBox(width: Sp.s2),
            Expanded(
              child: _stat(
                context,
                sc,
                served.toString(),
                context.l10n.tblStatServed,
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.s4),
        _card(
          context,
          sc,
          context.l10n.tblGuestNotes,
          guestNotes.isEmpty
              ? Text(
                  context.l10n.tblNoGuestNotes,
                  style: SatType.bodyM(color: sc.textLo),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final note in guestNotes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Sp.s1h),
                        child: Container(
                          padding: const EdgeInsets.all(Sp.s3),
                          decoration: SatBox.d(
                            color: sc.bg2,
                            border: SatB.all(color: sc.border0),
                            borderRadius: SatR.a(12),
                          ),
                          child: NoteLine(
                            label: context.l10n.tblSpecialInstruction,
                            text: note,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: Sp.s3h),
        _card(
          context,
          sc,
          context.l10n.tblAllergensInOrder,
          allergens.isEmpty
              ? Text(
                  context.l10n.tblNoAllergens,
                  style: SatType.bodyM(color: sc.textLo),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in allergens)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Sp.s2h,
                          vertical: Sp.s1h,
                        ),
                        decoration: SatBox.d(
                          color: sc.urgentSoft,
                          border: SatB.all(
                            color: sc.urgent.withValues(alpha: 0.35),
                          ),
                          borderRadius: SatR.a(999),
                        ),
                        child: Text(a, style: SatType.bodyS(color: sc.urgent)),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: Sp.s3h),
        _card(
          context,
          sc,
          context.l10n.tblQuickActions,
          Column(
            children: [
              _quickAction(
                context,
                sc,
                Icons.receipt_long_rounded,
                context.l10n.tblPrintTableReceipt,
                accent: true,
                onTap: () => printTableStruk(
                  context: context,
                  ref: ref,
                  table: table,
                  tickets: tickets,
                ),
              ),
              if (canMove) ...[
                const SizedBox(height: Sp.s1h),
                _quickAction(
                  context,
                  sc,
                  Icons.swap_horiz_rounded,
                  context.l10n.tblMoveTable,
                  onTap: onMove,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: body,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.tblContextTitle,
                style: SatType.h2(color: sc.textHi),
              ),
              const SizedBox(height: Sp.s1),
              Text(
                context.l10n.tblSeatedFor(
                  formatElapsed(
                    context.l10n,
                    SatClock.now().difference(table.openedAt ?? SatClock.now()),
                  ),
                  table.pax,
                ),
                style: SatType.monoS(color: sc.textLo),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
            child: body,
          ),
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, SatColors sc, String v, String l) {
    return Container(
      padding: const EdgeInsets.all(Sp.s3h),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v, style: SatType.monoL(color: sc.textHi)),
          const SizedBox(height: Sp.s2),
          Text(l.toUpperCase(), style: SatType.monoS(color: sc.textLo)),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, SatColors sc, String head, Widget child) {
    return SatCard.section(
      header: head,
      padding: const EdgeInsets.all(Sp.s4h),
      child: child,
    );
  }

  Widget _quickAction(
    BuildContext context,
    SatColors sc,
    IconData icon,
    String label, {
    bool accent = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: accent ? sc.accentSoft : sc.bg3,
      borderRadius: SatR.a(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: SatR.a(10),
        child: Container(
          height: 38,
          decoration: SatBox.d(
            border: SatB.all(color: accent ? sc.accentBorder : sc.border1),
            borderRadius: SatR.a(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: accent ? sc.accentText : sc.textMd),
              const SizedBox(width: Sp.s2),
              Text(
                label.toUpperCase(),
                style: SatType.labelS(
                  color: accent ? sc.accentText : sc.textMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
