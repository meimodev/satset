import 'dart:async';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
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
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/use_cases/advance_ticket_status_use_case.dart';
import 'package:satset/ui/core/widgets/ready_banner.dart';
import 'package:satset/ui/core/widgets/order_line_card.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart';
import 'package:satset/ui/core/widgets/note_line.dart';
import '../void_flow/line_item_action_sheet.dart';
import 'package:satset/ui/features/tables/widgets/guest_stepper.dart';
import 'package:satset/ui/features/tables/widgets/move_table_sheet.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/design/spacing.dart';

// Motion tuning. Refined, calm — easeOutQuart per design tokens, no bounce.
// Mirrors the constants in tables_screen.dart so the grid → detail transition
// feels like one continuous surface.
const Curve _kEase = Curves.easeOutQuart;
const Duration _kStatusXfade = Duration(milliseconds: 280);
const Duration _kChipMorph = Duration(milliseconds: 220);
const Duration _kPressIn = Duration(milliseconds: 90);

bool _animationsDisabled(BuildContext c) =>
    MediaQuery.maybeOf(c)?.disableAnimations ?? false;

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
        final holder = r.conflict!.lockedByName ?? 'pengguna lain';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Meja diambil oleh $holder')));
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
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    final actorId = user?.id;

    // Lock state: derived from server-pushed table row, so a WS update from
    // any client flips this screen between editable / read-only without
    // requiring a local poll.
    final lockedByOther = table.isLockedByOther(actorId);
    final readOnly = lockedByOther || (!_ownsLock && !_acquiring);

    // Watch for two related transitions: (a) the current lock holder
    // releases while we're sitting read-only, or (b) the row flips from
    // `available` to a non-`available` status (a walk-in seat from another
    // waiter on the same kosong screen, or a server-side mutation). In both
    // cases we want to try to claim the lock — but only when the table is
    // actually in a lockable state. Kosong tables are intentionally
    // lock-free, so we skip auto-acquire on them.
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
    final canSeat =
        isKosong && auth.has(Capability.takeOrder) && !lockedByOther;
    // Gate by capability, not role enum: admins also have takeOrder and need
    // to be able to correct guest counts during testing/coverage.
    final canEditGuests = auth.has(Capability.takeOrder) && !readOnly;

    Future<void> onSeat() async {
      if (!canSeat || actorId == null) return;
      try {
        await ref
            .read(tablesProvider.notifier)
            .seat(_tableId, pax: 1, userId: actorId, userName: user?.name);
        // The status flip from `available` → `occupied` triggers the
        // tablesProvider listener above, which schedules the auto-acquire.
        // No explicit lock call here.
      } on ApiException catch (e) {
        if (!context.mounted) return;
        final holder = table.lockedByName ?? 'pengguna lain';
        final msg = e.code == 'already_seated'
            ? 'Meja sudah diisi oleh $holder'
            : 'Gagal mulai layani: ${e.code ?? e.statusCode}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mulai layani: $e')));
      }
    }

    void onMinus() {
      if (readOnly) return;
      ref.read(tablesProvider.notifier).decrementPax(_tableId, userId: actorId);
    }

    void onPlus() {
      if (readOnly) return;
      ref.read(tablesProvider.notifier).incrementPax(_tableId, userId: actorId);
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
    final closeLabel = isEmptyClose ? 'Lepaskan Meja' : 'Selesaikan Layanan';

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
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            _ContextSheet(table: table, tickets: tickets, menu: menuItems),
      );
    }

    // The context pane reads menu metadata (allergens) — surface load state
    // explicitly rather than rendering against an empty cache.
    final menuStatus = ref.watch(menuStatusProvider);
    if (menuStatus.isLoading) {
      return Scaffold(
        backgroundColor: sc.bg0,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: Sp.s3),
              Text(
                'Memuat menu…',
                style: SatType.sans(size: 13, color: sc.textMd),
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
                const SizedBox(height: Sp.s2h),
                Text(
                  'Gagal memuat menu meja',
                  style: SatType.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: sc.textHi,
                  ),
                ),
                const SizedBox(height: Sp.s3),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(menuRepositoryProvider.notifier).refresh(),
                  child: const Text('Coba lagi'),
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
      if (readOnly) return;
      showLineItemActionSheet(context: context, tableId: _tableId, ticket: t);
    }

    void onAdd() {
      if (readOnly) return;
      context.push('/table/$_tableId/menu');
    }

    Future<void> onClose() async {
      if (!canClose) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isEmptyClose ? 'Lepaskan Meja?' : 'Selesaikan Layanan?'),
          content: Text(
            isEmptyClose
                ? 'Belum ada pesanan. Kosongkan meja ${table.displayName}?'
                : 'Semua tiket telah selesai. Kosongkan meja ${table.displayName} untuk tamu berikutnya? Tagihan tetap di kasir sampai dibayar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: const Text('Batal'),
            ),
            if (!isEmptyClose)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('print'),
                child: const Text('Cetak struk'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('close'),
              child: Text(closeLabel),
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
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menutup meja: $e')));
        }
      }
    }

    final lockBanner = lockedByOther
        ? _LockedBanner(
            holderName: table.lockedByName ?? 'pengguna lain',
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
      crumbs: ['Meja', table.displayName, if (zone.name.isNotEmpty) zone.name],
      title: 'Meja ${table.displayName}',
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
        canClose: canClose,
        closeLabel: closeLabel,
        isKosong: isKosong,
        canSeat: canSeat,
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
              _Header(
                table: table,
                zoneName: zone.name,
                canEditGuests: canEditGuests,
                onMinusPax: onMinus,
                onPlusPax: onPlus,
                alertCount: ctxAlertCount,
                onShowContext: showContextSheet,
              ),
              ?lockBanner,
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
                              l.bottomInset + 80,
                            ),
                            children: [
                              for (final (i, cid)
                                  in Courses.stationOrder
                                      .map((c) => c.id)
                                      .indexed)
                                if (grouped[cid] != null &&
                                    grouped[cid]!.isNotEmpty)
                                  Reveal(
                                    index: i,
                                    child: _CourseBlock(
                                      course: Courses.byId(cid),
                                      items: grouped[cid]!,
                                      readOnly: readOnly,
                                      onMarkServed: markServed,
                                      onFireCourse: () => fireCourse(cid),
                                      onTicketTap: openAction,
                                    ),
                                  ),
                              if (tickets.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    32,
                                    24,
                                    32,
                                  ),
                                  child: Text(
                                    'Belum ada item — ketuk "Tambah ke pesanan" untuk mulai.',
                                    textAlign: TextAlign.center,
                                    style: SatType.sans(
                                      size: 13,
                                      color: sc.textLo,
                                    ),
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
              bottom: l.useSideRail
                  ? 16 + l.padding.bottom
                  : 92 + l.padding.bottom,
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
                    icon: readOnly ? Icons.lock_outline : Icons.add,
                    enabled: !readOnly,
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

/// Per-second tick used by the live elapsed pill in [_Header]. autoDispose so
/// the stream stops while no table_detail screen is mounted.
final _detailElapsedTickerProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  ),
);

class _Header extends ConsumerWidget {
  final VenueTable table;
  final String zoneName;
  final bool canEditGuests;
  final VoidCallback onMinusPax;
  final VoidCallback onPlusPax;
  final int alertCount;
  final VoidCallback onShowContext;
  const _Header({
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
        : formatElapsedId(DateTime.now().difference(table.openedAt!));
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
                style: SatType.mono(
                  size: 44,
                  weight: FontWeight.w500,
                  letterSpacing: -1.32,
                  height: 1.0,
                  color: sc.textHi,
                ),
              ),
            ),
          ),
          const SizedBox(width: Sp.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zoneName,
                  style: SatType.sans(
                    size: 13,
                    weight: FontWeight.w500,
                    color: sc.textMd,
                  ),
                ),
                const SizedBox(height: Sp.s2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GuestStepper(
                      pax: table.pax,
                      max: table.capacity,
                      enabled: canEditGuests,
                      onMinus: onMinusPax,
                      onPlus: onPlusPax,
                      size: 32,
                    ),
                    const SizedBox(width: Sp.s2),
                    _ContextTriggerBtn(
                      alertCount: alertCount,
                      onTap: onShowContext,
                    ),
                    if (elapsedStr != null) ...[
                      const SizedBox(width: Sp.s2),
                      _SeatedDurationChip(label: elapsedStr),
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
                        _HPill(
                          icon: Icons.person_outline,
                          label: table.guestName!,
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

class _LiveSeatedChip extends ConsumerWidget {
  final DateTime openedAt;
  final double height;
  const _LiveSeatedChip({required this.openedAt, this.height = 32});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    ref.watch(_detailElapsedTickerProvider);
    final label = formatElapsedId(DateTime.now().difference(openedAt));
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3h),
      decoration: SatBox.d(
        color: sc.bg3,
        borderRadius: SatR.a(height / 2),
        border: SatB.all(color: sc.border0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: height * 0.42, color: sc.textMd),
          const SizedBox(width: Sp.s1h),
          Text(
            label,
            style: SatType.mono(
              size: height * 0.36,
              weight: FontWeight.w600,
              color: sc.textMd,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatedDurationChip extends StatelessWidget {
  final String label;
  const _SeatedDurationChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: Sp.s2h),
      decoration: SatBox.d(
        color: sc.bg3,
        borderRadius: SatR.a(16),
        border: SatB.all(color: sc.border0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 13, color: sc.textMd),
          const SizedBox(width: Sp.s1),
          Text(
            label,
            style: SatType.mono(
              size: 12,
              weight: FontWeight.w600,
              color: sc.textMd,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HPill extends StatelessWidget {
  final IconData? icon;
  final String label;
  const _HPill({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s2h, vertical: Sp.s1),
      decoration: SatBox.d(color: sc.bg3, borderRadius: SatR.a(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: sc.textMd),
            const SizedBox(width: Sp.s1h),
          ],
          Text(
            label,
            style: SatType.sans(
              size: 11,
              weight: FontWeight.w500,
              color: sc.textMd,
            ),
          ),
        ],
      ),
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
                  switchInCurve: _kEase,
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
                          padding: const EdgeInsets.symmetric(horizontal: Sp.s1),
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
                            style: SatType.mono(
                              size: 9,
                              weight: FontWeight.w700,
                              color: onFill(sc.urgent),
                            ),
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
                    'Konteks meja',
                    style: SatType.sans(
                      size: 20,
                      weight: FontWeight.w600,
                      letterSpacing: -0.4,
                      color: sc.textHi,
                    ),
                  ),
                  const SizedBox(height: Sp.s1),
                  Text(
                    'DUDUK ${table.openedAt == null ? '0d' : formatElapsedId(DateTime.now().difference(table.openedAt!))} · ${table.pax} TAMU',
                    style: SatType.mono(
                      size: 11,
                      color: sc.textLo,
                      letterSpacing: 0.44,
                    ),
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

class _CourseBlock extends StatelessWidget {
  final Course course;
  final List<Ticket> items;
  final void Function(String) onMarkServed;
  final VoidCallback onFireCourse;
  final void Function(Ticket) onTicketTap;
  final bool readOnly;

  const _CourseBlock({
    required this.course,
    required this.items,
    required this.onMarkServed,
    required this.onFireCourse,
    required this.onTicketTap,
    this.readOnly = false,
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
                  course.name.toUpperCase(),
                  style: SatType.mono(
                    size: 11,
                    weight: FontWeight.w600,
                    letterSpacing: 1.32,
                    color: sc.textMd,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length} item${allHeld ? ' · ditahan' : ''}',
                  style: SatType.mono(
                    size: 11,
                    color: sc.textLo,
                    letterSpacing: 0,
                  ),
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
            ),
          if (allHeld && !readOnly)
            Padding(
              padding: const EdgeInsets.only(top: Sp.s1h),
              child: _FireButton(
                label: 'Bakar ${course.name}',
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
    final sc = context.sat;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: sc.accentSoft,
          foregroundColor: sc.accentText,
          side: SatB.side(color: sc.accentBorder, style: BorderStyle.solid),
          padding: const EdgeInsets.symmetric(vertical: Sp.s2),
          shape: RoundedRectangleBorder(borderRadius: SatR.a(10)),
        ),
        icon: Icon(Icons.local_fire_department, size: 14, color: sc.accentText),
        label: Text(
          label.toUpperCase(),
          style: SatType.sans(
            size: 12,
            weight: FontWeight.w600,
            letterSpacing: 0.48,
            color: sc.accentText,
          ),
        ),
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
        padding: const EdgeInsets.all(Sp.s6),
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
              'Meja ${widget.tableName} kosong',
              style: SatType.sans(
                size: 16,
                weight: FontWeight.w600,
                color: sc.textHi,
              ),
            ),
            const SizedBox(height: Sp.s1h),
            Text(
              'Tap untuk mulai melayani tamu',
              style: SatType.sans(size: 13, color: sc.textLo),
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
                        horizontal: Sp.s6,
                        vertical: Sp.s4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_fill, size: 22, color: fg),
                          const SizedBox(width: Sp.s2h),
                          Text(
                            'Mulai layani meja',
                            style: SatType.sans(
                              size: 15,
                              weight: FontWeight.w700,
                              color: fg,
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
      label: enabled ? AppStrings.a11yAddItem : AppStrings.a11yTableLocked,
      child: Center(
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: reduced ? Duration.zero : _kPressIn,
          curve: _kEase,
          child: AnimatedContainer(
            duration: reduced ? Duration.zero : _kStatusXfade,
            curve: _kEase,
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
                  width: Sp.s12,
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
      curve: _kEase,
      child: SizedBox(
        height: Sp.s12,
        child: Material(
          color: sc.success,
          borderRadius: SatR.a(18),
          elevation: 0,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (h) => setState(() => _pressed = h),
            borderRadius: SatR.a(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.s5),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20, color: sc.successInk),
                  const SizedBox(width: Sp.s2h),
                  Text(
                    widget.label,
                    style: SatType.sans(
                      size: 15,
                      weight: FontWeight.w700,
                      letterSpacing: -0.15,
                      color: sc.successInk,
                    ),
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
    final sinceLabel = since == null ? '' : ' · sejak ${_hhmm(since!)}';
    return Reveal(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: Sp.s3h, vertical: Sp.s2h),
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
                'Terkunci oleh $holderName$sinceLabel · hanya lihat',
                style: SatType.sans(
                  size: 13,
                  weight: FontWeight.w500,
                  color: sc.warn,
                ),
              ),
            ),
          ],
        ),
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
  final bool canClose;
  final String closeLabel;
  final bool isKosong;
  final bool canSeat;
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
    required this.canClose,
    required this.closeLabel,
    required this.isKosong,
    required this.canSeat,
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
                  width: Sp.s12,
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
                                      style: SatType.mono(
                                        size: 56,
                                        weight: FontWeight.w500,
                                        letterSpacing: -1.68,
                                        height: 1,
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
                                        style: SatType.sans(
                                          size: 15,
                                          color: sc.textMd,
                                        ),
                                      ),
                                      const SizedBox(height: Sp.s1h),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GuestStepper(
                                            pax: table.pax,
                                            max: table.capacity,
                                            enabled: canEditGuests,
                                            onMinus: onMinusPax,
                                            onPlus: onPlusPax,
                                            size: 36,
                                          ),
                                          if (table.openedAt != null) ...[
                                            const SizedBox(width: Sp.s2h),
                                            _LiveSeatedChip(
                                              openedAt: table.openedAt!,
                                              height: 36,
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
                                      '$readyN siap diambil',
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
                            : tickets.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(Sp.s6),
                                  child: Text(
                                    'Belum ada item — ketuk Tambah pesanan di kanan untuk mulai.',
                                    textAlign: TextAlign.center,
                                    style: SatType.sans(
                                      size: 14,
                                      color: sc.textLo,
                                      height: 1.5,
                                    ),
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
                                  for (final (i, cid)
                                      in Courses.stationOrder
                                          .map((c) => c.id)
                                          .indexed)
                                    if (grouped[cid] != null &&
                                        grouped[cid]!.isNotEmpty)
                                      Reveal(
                                        index: i,
                                        child: _CourseBlock(
                                          course: Courses.byId(cid),
                                          items: grouped[cid]!,
                                          readOnly: readOnly,
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
                          child: Row(
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
                                  opacity: readOnly ? 0.5 : 1,
                                  child: Material(
                                    color: sc.accent,
                                    borderRadius: SatR.a(14),
                                    child: InkWell(
                                      onTap: readOnly ? null : onAdd,
                                      borderRadius: SatR.a(14),
                                      child: Container(
                                        height: 52,
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              readOnly
                                                  ? Icons.lock_outline
                                                  : Icons.add,
                                              size: 18,
                                              color: sc.accentInk,
                                            ),
                                            const SizedBox(width: Sp.s2),
                                            Text(
                                              readOnly
                                                  ? 'Hanya lihat'
                                                  : (tickets.isEmpty
                                                        ? 'Buat pesanan'
                                                        : 'Tambah pesanan'),
                                              style: SatType.sans(
                                                size: 15,
                                                weight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: Sp.s2h, vertical: Sp.s1),
      decoration: SatBox.d(
        color: bg,
        border: SatB.all(color: border),
        borderRadius: SatR.a(999),
      ),
      child: Text(
        text,
        style: SatType.sans(
          size: 11,
          weight: FontWeight.w500,
          letterSpacing: 0.2,
          color: fg,
        ),
      ),
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
    final auth = ref.watch(authStateProvider);
    final actorId = auth.user?.id;
    // Move is offered only on a live table the caller may operate and that
    // isn't actively held by someone else. Server re-checks the lock anyway.
    final canMove =
        table.status != TableStatus.available &&
        auth.has(Capability.takeOrder) &&
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
                'Total item',
              ),
            ),
            const SizedBox(width: Sp.s2),
            Expanded(
              child: _stat(context, sc, sent.toString(), 'Dalam proses'),
            ),
            const SizedBox(width: Sp.s2),
            Expanded(child: _stat(context, sc, served.toString(), 'Disajikan')),
          ],
        ),
        const SizedBox(height: Sp.s4),
        _card(
          context,
          sc,
          'CATATAN TAMU',
          guestNotes.isEmpty
              ? Text(
                  'Belum ada catatan khusus.',
                  style: SatType.sans(size: 13, color: sc.textLo),
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
                            label: 'Instruksi khusus',
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
          'ALERGEN DI PESANAN',
          allergens.isEmpty
              ? Text(
                  'Tidak ada.',
                  style: SatType.sans(size: 13, color: sc.textLo),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in allergens)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Sp.s2h,
                          vertical: Sp.s1,
                        ),
                        decoration: SatBox.d(
                          color: sc.urgentSoft,
                          border: SatB.all(
                            color: sc.urgent.withValues(alpha: 0.35),
                          ),
                          borderRadius: SatR.a(999),
                        ),
                        child: Text(
                          a,
                          style: SatType.sans(
                            size: 12,
                            weight: FontWeight.w500,
                            color: sc.urgent,
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
          'AKSI CEPAT',
          Column(
            children: [
              _quickAction(
                context,
                sc,
                Icons.receipt_long_rounded,
                'Cetak struk meja',
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
                  'Pindahkan meja',
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
                'Konteks meja',
                style: SatType.sans(
                  size: 22,
                  weight: FontWeight.w600,
                  letterSpacing: -0.44,
                  color: sc.textHi,
                ),
              ),
              const SizedBox(height: Sp.s1),
              Text(
                'DUDUK ${table.openedAt == null ? '0d' : formatElapsedId(DateTime.now().difference(table.openedAt!))} · ${table.pax} TAMU',
                style: SatType.mono(
                  size: 11,
                  color: sc.textLo,
                  letterSpacing: 0.44,
                ),
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
          Text(
            v,
            style: SatType.mono(
              size: 22,
              weight: FontWeight.w600,
              letterSpacing: -0.44,
              height: 1,
              color: sc.textHi,
            ),
          ),
          const SizedBox(height: Sp.s2),
          Text(
            l.toUpperCase(),
            style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, SatColors sc, String head, Widget child) {
    return Container(
      padding: const EdgeInsets.all(Sp.s4h),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            head,
            style: SatType.mono(
              size: 10,
              weight: FontWeight.w600,
              letterSpacing: 1.2,
              color: sc.textLo,
            ),
          ),
          const SizedBox(height: Sp.s3),
          child,
        ],
      ),
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
                style: SatType.sans(
                  size: 12,
                  weight: FontWeight.w600,
                  letterSpacing: 0.48,
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
