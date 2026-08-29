import 'dart:async';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/time/sat_clock.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/order_dto.dart';
import 'package:satset/data/models/ticket_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/error_bus_service.dart';
import 'package:satset/data/services/send_queue_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/ticket_modifier.dart';

/// Surfaces bootstrap progress for the per-table ticket list.
final ticketsStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

class TicketsRepository extends StateNotifier<Map<String, List<Ticket>>> {
  TicketsRepository({required this.ref})
    : super(const <String, List<Ticket>>{}) {
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;
  bool _resyncing = false;
  bool _resyncAgain = false;

  /// Group key for the live-ticket map: the visitId for every group. A tableId
  /// is reused across visits, so keying by it let a reseat re-absorb the prior
  /// visit's lines; the visit is the stable bill key (ADR-0024). Dine-in screens
  /// resolve their lines through the table's currentVisitId via
  /// [ticketsForTableProvider]. Falls back to tableId only for legacy pre-v29
  /// rows with a null visitId. See ADR-0034.
  static String _groupKey(TicketDto d) =>
      (d.visitId != null && d.visitId!.isNotEmpty) ? d.visitId! : d.tableId;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(ticketsStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
      return;
    }
    state = const <String, List<Ticket>>{};
    ref.read(ticketsStatusProvider.notifier).state = const AsyncValue.loading();
    try {
      await _refetch();
      ref.read(ticketsStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
    } catch (e, st) {
      SatLog.repo('tickets.bootstrap fail $e');
      ref.read(ticketsStatusProvider.notifier).state = AsyncValue.error(e, st);
    }
    // `connected` recovers a bootstrap that raced the auth token (the first
    // GET can 401 on host sign-in) and re-pulls lines that mutated while the
    // socket was down — incremental ticket events are lossy. Mirrors
    // TablesRepository. See ADR-0021.
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type == WsEventTypes.connected) {
        unawaited(_resync());
      } else if (ev.type == WsEventTypes.ticketCreated ||
          ev.type == WsEventTypes.ticketUpdated) {
        final dto = TicketDto.fromJson(ev.payload);
        SatLog.repo(
          'tickets.ws ${ev.type} id=${dto.id.substring(0, dto.id.length.clamp(0, 6))} status=${dto.status}',
        );
        final key = _groupKey(dto);
        final next = Map<String, List<Ticket>>.from(state);
        final list = List<Ticket>.from(next[key] ?? const []);
        final idx = list.indexWhere((t) => t.id == dto.id);
        if (idx == -1) {
          list.add(_toDomain(dto));
        } else {
          list[idx] = _toDomain(dto);
        }
        next[key] = list;
        state = next;
      } else if (ev.type == WsEventTypes.tableSessionClosed) {
        // Every group is keyed by visitId now (dine-in and takeaway alike), so
        // dropping the just-snapshotted visit frees its lines for both. A
        // reseat starts a fresh visit under a new key, untouched. No tableId
        // purge is needed: a stale visit's group is simply never resolved as
        // the table's currentVisitId. See ADR-0034 / ADR-0024.
        final vid = ev.payload['visitId'] as String?;
        if (vid == null || !state.containsKey(vid)) return;
        SatLog.repo('tickets.ws visit $vid closed — purging local tickets');
        final next = Map<String, List<Ticket>>.from(state)..remove(vid);
        state = next;
      }
    });
  }

  /// Pull the authoritative live-ticket list and replace state. Shared by the
  /// initial [_bootstrap] and the WS-reconnect [_resync].
  Future<void> _refetch() async {
    final api = ref.read(apiClientProvider);
    final raw = await api.getJson('/tickets') as List;
    final grouped = <String, List<Ticket>>{};
    for (final e in raw) {
      final dto = TicketDto.fromJson((e as Map).cast<String, dynamic>());
      grouped.putIfAbsent(_groupKey(dto), () => []).add(_toDomain(dto));
    }
    state = grouped;
    SatLog.repo(
      'tickets.loaded tables=${grouped.length} tickets=${grouped.values.fold<int>(0, (s, l) => s + l.length)}',
    );
  }

  /// Re-pull after something outside this repository changed the server's
  /// tickets — today, a drained send queue (ADR-0090).
  Future<void> resyncNow() => _resync();

  /// Guarded so overlapping connects don't stampede; never throws — a
  /// transient failure simply waits for the next connect.
  ///
  /// The guard **coalesces, it does not drop**. A resync asked for while one is
  /// in flight cannot be answered by that one: the in-flight GET left before
  /// the caller's write landed. Dropping it is how a drained [[Antrean kirim]]
  /// lost its own re-pull — the reconnect's GET and the drain fire off the same
  /// `connected` event, so the drain's `resyncNow()` always arrives mid-flight,
  /// and the pre-drain response then clobbered the WS deltas the void and the
  /// new ticket had already applied (ADR-0090, found on device).
  Future<void> _resync() async {
    if (_resyncing) {
      _resyncAgain = true;
      return;
    }
    _resyncing = true;
    try {
      do {
        _resyncAgain = false;
        try {
          await _refetch();
          ref.read(ticketsStatusProvider.notifier).state =
              const AsyncValue.data(null);
          SatLog.repo('tickets.resync ok');
        } catch (e) {
          // Caught per pass, not around the loop: a pass that failed must
          // still honour a re-run someone queued behind it.
          SatLog.repo('tickets.resync fail $e');
        }
      } while (_resyncAgain);
    } finally {
      _resyncing = false;
      _resyncAgain = false;
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Ticket _toDomain(TicketDto d) {
    return Ticket(
      id: d.id,
      visitId: d.visitId,
      tableId: d.tableId,
      itemId: d.itemId,
      name: d.name,
      variantName: d.variantName,
      course: _courseFromKey(d.course),
      qty: d.qty,
      modifiers: [
        for (final m in d.modifiers)
          TicketModifier(
            groupId: m.groupId,
            optionId: m.optionId,
            label: m.label,
            priceDelta: m.priceDelta,
          ),
      ],
      note: d.note,
      price: d.price,
      status: ticketStatusFromKey(d.status),
      // Domain stores sentAt as `HH:mm` local; the KDS age computation
      // and seed data both rely on that format.
      sentAt: _nowStamp(d.sentAt.toLocal()),
      // Full-precision twin of sentAt — drives the live KDS age counter
      // (sentAt's HH:mm has no seconds). See ADR-0008.
      sentAtTime: d.sentAt.toLocal(),
      firedAtTime: d.firedAt?.toLocal(),
      readyAtTime: d.readyAt?.toLocal(),
      servedAtTime: d.servedAt?.toLocal(),
      voidReason: d.voidReason,
      voidReasonCode: d.voidReasonCode,
      voidApprovedBy: d.voidApprovedBy,
      createdBy: d.createdByUserId,
      voidedBy: d.voidedByUserId,
    );
  }

  CourseId _courseFromKey(String k) => switch (k) {
    'drinks-now' || 'drinksNow' => CourseId.drinksNow,
    'starters' => CourseId.starters,
    'mains' => CourseId.mains,
    'sides' => CourseId.sides,
    'desserts' => CourseId.desserts,
    'fire-now' || 'fireNow' => CourseId.fireNow,
    _ => CourseId.fireNow,
  };

  /// The map key a dine-in [tableId] resolves to: the table's current visit
  /// (groups are keyed by visitId, ADR-0034). Falls back to the tableId for the
  /// pre-pair dummy path and legacy null-visit rows, which key by table.
  String _keyForTable(String tableId) {
    final t = ref
        .read(tablesProvider)
        .where((t) => t.id == tableId)
        .firstOrNull;
    final vid = t?.currentVisitId;
    return (vid != null && vid.isNotEmpty) ? vid : tableId;
  }

  /// The group key whose list currently holds [ticketId], or null if unknown.
  /// Lets ticket-centric mutations find their group without trusting the
  /// caller's tableId, which no longer matches the (visit-keyed) map. ADR-0034.
  String? _keyOfTicket(String ticketId) {
    for (final e in state.entries) {
      if (e.value.any((t) => t.id == ticketId)) return e.key;
    }
    return null;
  }

  Ticket? findTicket(String tableId, String ticketId) {
    for (final list in state.values) {
      for (final t in list) {
        if (t.id == ticketId) return t;
      }
    }
    return null;
  }

  /// LAN-aware order submit. Uses [ApiClient] when configured; otherwise
  /// falls back to the in-memory dummy path so the UI keeps working pre-pair.
  Future<List<String>> submitOrder({
    required String tableId,
    required String idempotencyKey,
    required List<CartLineDto> lines,
    String? actorId,
  }) async {
    SatLog.repo(
      'tickets.submit table=${tableId.substring(0, tableId.length.clamp(0, 6))} lines=${lines.length}',
    );
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      final cart = [
        for (final l in lines)
          CartItem(
            id: l.itemId,
            itemId: l.itemId,
            name: l.name,
            variantId: l.variantId,
            variantName: l.variantName,
            course: _courseFromKey(l.course),
            qty: l.qty,
            unitPrice: l.unitPrice,
            selectedModifiers: [
              for (final m in l.modifiers)
                TicketModifier(
                  groupId: m.groupId,
                  optionId: m.optionId,
                  label: m.label,
                  priceDelta: m.priceDelta,
                ),
            ],
          ),
      ];
      return sendOrder(
        tableId,
        cart,
        actorId: actorId,
      ).map((t) => t.id).toList();
    }
    // Terputus: capture the order instead of attempting it (ADR-0090). The
    // socket being closed is checked *before* the POST rather than after it
    // fails, because the failure costs 8s of `requestTimeout` and a waiter
    // mid-rush pays that on every tap.
    if (ref.read(wsConnStateProvider) != WsConnState.open) {
      await _enqueueOrder(
        tableId: tableId,
        lines: lines,
        actorId: actorId,
        idempotencyKey: idempotencyKey,
      );
      return const [];
    }
    final api = ref.read(apiClientProvider);
    final Object raw;
    try {
      raw = await api.postJson(
        '/orders',
        SubmitOrderRequestDto(
          tableId: tableId,
          idempotencyKey: idempotencyKey,
          lines: lines,
          actorId: actorId,
        ).toJson(),
      );
    } on ApiException {
      // The host answered. Whatever it said — out of stock, no capability, a
      // closed bill — is a real answer the caller must surface, not a gap to
      // queue over.
      rethrow;
    } catch (_) {
      // The socket said open and the request still did not land. This is the
      // gap between the two signals, and it is the reason there is no global
      // offline flag to disagree with.
      await _enqueueOrder(
        tableId: tableId,
        lines: lines,
        actorId: actorId,
        idempotencyKey: idempotencyKey,
      );
      return const [];
    }
    final res = SubmitOrderResponseDto.fromJson(
      (raw as Map).cast<String, dynamic>(),
    );
    // Seed the table's currentVisitId so the just-sent lines resolve on this
    // device before the tableUpdated echo arrives (ADR-0034).
    ref.read(tablesProvider.notifier).seedCurrentVisit(tableId, res.visitId);
    _reportRejected(res.rejected);
    return res.ticketIds;
  }

  /// Park an order on the device's [SendQueue] as a **pesanan tertunda**.
  ///
  /// Carries the table's current visit when this device knows one, so the host
  /// can refuse rather than attach if the table has changed guests by the time
  /// the queue drains (ADR-0090). A full queue is surfaced, never swallowed —
  /// the waiter must know the handset stopped accepting orders.
  Future<void> _enqueueOrder({
    required String tableId,
    required List<CartLineDto> lines,
    required String idempotencyKey,
    String? actorId,
  }) async {
    final visitId = ref
        .read(tablesProvider)
        .where((t) => t.id == tableId)
        .firstOrNull
        ?.currentVisitId;
    try {
      await ref
          .read(sendQueueProvider.notifier)
          .enqueue(
            // The key the timed-out POST already carried. If that request did
            // land, the replay reads the host's stored answer instead of
            // ordering the food twice.
            id: idempotencyKey,
            kind: SendIntentKind.submitOrder,
            tableId: tableId,
            actorId: actorId ?? '',
            expectedVisitId: (visitId != null && visitId.isNotEmpty)
                ? visitId
                : null,
            payload: {'lines': [for (final l in lines) l.toJson()]},
          );
    } on SendQueueFull {
      final l = ref.read(l10nProvider);
      ref
          .read(errorBusServiceProvider)
          .push(
            l.sendQueueFull,
            level: AppErrorLevel.error,
            code: 'send_queue_full',
          );
      rethrow;
    }
  }

  /// Tell the waiter which lines the kitchen has no ingredients for.
  ///
  /// Rejection is per line, so the rest of the order went through — without
  /// this the dropped lines would just be missing from the table, which reads
  /// as a bug rather than as "we're out of ayam" (ADR-0041).
  void _reportRejected(List<RejectedLineDto> rejected) {
    if (rejected.isEmpty) return;
    final bus = ref.read(errorBusServiceProvider);
    final l = ref.read(l10nProvider);
    for (final r in rejected) {
      final what = [
        r.name,
        if (r.variantName.isNotEmpty) r.variantName,
      ].join(' ');
      final why = r.ingredients.isEmpty
          ? l.tktOutOfStock
          : l.tktOutOfStockNamed(r.ingredients.join(', '));
      bus.push(
        l.tktNotSent(what, why),
        level: AppErrorLevel.warning,
        code: 'out_of_stock',
      );
    }
  }

  /// Submit a table-less takeaway (Bawa pulang) order. With no [existingVisitId]
  /// the server mints a fresh `kind==takeaway` visit and returns its id; pass
  /// [existingVisitId] to append items to an open takeaway. Offline mints a
  /// local visit id. See ADR-0026.
  Future<({List<String> ticketIds, String visitId})> submitTakeawayOrder({
    required String idempotencyKey,
    required List<CartLineDto> lines,
    String guestName = '',
    String channel = 'bungkus',
    bool prepaid = false,
    String? existingVisitId,
    String? actorId,
  }) async {
    SatLog.repo(
      'tickets.submitTakeaway lines=${lines.length} append=${existingVisitId != null}',
    );
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      final vid =
          existingVisitId ?? 'T${SatClock.now().millisecondsSinceEpoch}';
      final cart = [
        for (final l in lines)
          CartItem(
            id: l.itemId,
            itemId: l.itemId,
            name: l.name,
            variantId: l.variantId,
            variantName: l.variantName,
            course: _courseFromKey(l.course),
            qty: l.qty,
            unitPrice: l.unitPrice,
            selectedModifiers: [
              for (final m in l.modifiers)
                TicketModifier(
                  groupId: m.groupId,
                  optionId: m.optionId,
                  label: m.label,
                  priceDelta: m.priceDelta,
                ),
            ],
          ),
      ];
      final created = sendOrder(vid, cart, actorId: actorId);
      return (ticketIds: [for (final t in created) t.id], visitId: vid);
    }
    final api = ref.read(apiClientProvider);
    final raw = await api.postJson('/orders', {
      'takeaway': true,
      'guestName': guestName,
      // Only read when the server mints a fresh visit; appending to an open
      // takeaway leaves the channel it was created with alone. ADR-0066.
      'channel': channel,
      'prepaid': prepaid,
      'visitId': ?existingVisitId,
      'idempotencyKey': idempotencyKey,
      'lines': [for (final l in lines) l.toJson()],
      'actorId': ?actorId,
    });
    final map = (raw as Map).cast<String, dynamic>();
    _reportRejected([
      for (final r in (map['rejected'] as List? ?? const []))
        RejectedLineDto.fromJson((r as Map).cast<String, dynamic>()),
    ]);
    return (
      ticketIds: (map['ticketIds'] as List).cast<String>(),
      visitId: (map['visitId'] as String?) ?? existingVisitId ?? '',
    );
  }

  /// Posts a status change to the server when paired and applies the same
  /// change optimistically. Optional `voidReason` / `voidApprovedBy` ride
  /// along on void transitions.
  ///
  /// Returns **true when the move was captured on the [SendQueue] instead of
  /// delivered** — only a void can be, and only while the handset is terputus
  /// (ADR-0090). The caller has to know, because a queued void means the
  /// kitchen has not heard it and may still plate the dish.
  Future<bool> transition(
    String tableId,
    String ticketId,
    TicketStatus to, {
    String? voidReason,
    String? voidReasonCode,
    String? voidApprovedBy,
    String? actorId,
  }) async {
    SatLog.repo(
      'tickets.transition id=${ticketId.substring(0, ticketId.length.clamp(0, 6))} → ${to.name}',
    );
    final cfg = ref.read(apiConfigProvider);
    // Only a void is offline-capable. Every other move on this graph is a
    // kitchen fact — a queued `prep` would replay minutes after the dish left
    // the pass, telling the room something that stopped being true.
    final canQueue = to == TicketStatus.voided;
    var queued = false;
    if (cfg != null) {
      final body = <String, dynamic>{
        'status': ticketStatusKey(to),
        'voidReason': ?voidReason,
        'voidReasonCode': ?voidReasonCode,
        'voidApprovedBy': ?voidApprovedBy,
      };
      // Terputus: capture instead of attempting, the same pre-check the order
      // path makes and for the same reason — the failure costs 8s of
      // `requestTimeout` and a waiter mid-rush pays it on every tap.
      if (canQueue && ref.read(wsConnStateProvider) != WsConnState.open) {
        await _enqueueVoid(
          tableId: tableId,
          ticketId: ticketId,
          voidReason: voidReason,
          voidReasonCode: voidReasonCode,
          actorId: actorId,
        );
        queued = true;
      } else {
        try {
          await ref
              .read(apiClientProvider)
              .postJson('/tickets/$ticketId/transition', body);
        } on ApiException {
          // The host answered. Whatever it said — no capability, the line
          // already moved — is a real answer the caller must surface, not a
          // gap to queue over.
          rethrow;
        } catch (_) {
          // The socket said open and the request still did not land. This is
          // the gap between the two signals.
          if (!canQueue) rethrow;
          await _enqueueVoid(
            tableId: tableId,
            ticketId: ticketId,
            voidReason: voidReason,
            voidReasonCode: voidReasonCode,
            actorId: actorId,
          );
          queued = true;
        }
      }
    }
    final key = _keyOfTicket(ticketId);
    if (key == null) return queued;
    final next = Map<String, List<Ticket>>.from(state);
    final list = next[key];
    if (list == null) return queued;
    next[key] = [
      for (final t in list)
        if (t.id == ticketId)
          t.copyWith(
            status: to,
            voidReason: voidReason ?? t.voidReason,
            voidReasonCode: voidReasonCode ?? t.voidReasonCode,
            voidApprovedBy: voidApprovedBy ?? t.voidApprovedBy,
          )
        else
          t,
    ];
    state = next;
    return queued;
  }

  /// Park a void on the device's [SendQueue] (ADR-0090).
  ///
  /// Keyed `void-<ticketId>`, which makes the dedupe free: [SendQueue.enqueue]
  /// treats a repeated id as a no-op, so tapping Batalkan four times on a dead
  /// socket leaves one intent and the drain reports one answer.
  ///
  /// Carries the line's name and qty because the host is about to be told the
  /// ticket is gone — by the time a refusal comes back there is nothing left
  /// to look the words up from, and a report that cannot name the line is a
  /// report nobody can act on.
  Future<void> _enqueueVoid({
    required String tableId,
    required String ticketId,
    required String? voidReason,
    required String? voidReasonCode,
    String? actorId,
  }) async {
    final t = findTicket(tableId, ticketId);
    try {
      await ref
          .read(sendQueueProvider.notifier)
          .enqueue(
            id: 'void-$ticketId',
            kind: SendIntentKind.voidTicket,
            tableId: tableId,
            actorId: actorId ?? '',
            payload: {
              'ticketId': ticketId,
              'voidReasonCode': ?voidReasonCode,
              'voidReason': ?voidReason,
              'name': t?.name ?? '',
              'qty': t?.qty ?? 0,
            },
          );
    } on SendQueueFull {
      final l = ref.read(l10nProvider);
      ref
          .read(errorBusServiceProvider)
          .push(
            l.sendQueueFull,
            level: AppErrorLevel.error,
            code: 'send_queue_full',
          );
      rethrow;
    }
  }

  /// Edit a line the kitchen does not yet own — qty, note and modifiers on a
  /// `held` row (ADR-0071). The server rejects anything past `held` with a 409,
  /// so this is a request, not a local mutation with a sync afterwards: the
  /// optimistic write lands only once the server has agreed.
  Future<void> modifyLine(
    String tableId,
    String ticketId, {
    required int qty,
    required String? note,
    required List<TicketModifier> modifiers,
    required int unitPrice,
  }) async {
    SatLog.repo(
      'tickets.modify id=${ticketId.substring(0, ticketId.length.clamp(0, 6))} '
      'qty=$qty',
    );
    final cfg = ref.read(apiConfigProvider);
    if (cfg != null) {
      await ref.read(apiClientProvider).patchJson('/tickets/$ticketId', {
        'qty': qty,
        'note': note,
        'unitPrice': unitPrice,
        'modifiers': [
          for (final m in modifiers)
            {
              'groupId': m.groupId,
              'optionId': m.optionId,
              'label': m.label,
              'priceDelta': m.priceDelta,
            },
        ],
      });
    }
    final key = _keyOfTicket(ticketId);
    if (key == null) return;
    final next = Map<String, List<Ticket>>.from(state);
    final list = next[key];
    if (list == null) return;
    next[key] = [
      for (final t in list)
        if (t.id == ticketId)
          t.copyWith(
            qty: qty,
            note: note,
            modifiers: modifiers,
            price: unitPrice,
          )
        else
          t,
    ];
    state = next;
  }

  String _nowStamp(DateTime d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(d.hour)}:${pad(d.minute)}';
  }

  List<Ticket> sendOrder(
    String tableId,
    List<CartItem> cart, {
    String? actorId,
  }) {
    final now = SatClock.now();
    final stamp = _nowStamp(now);
    // Mirror what the host will write (ADR-0115). This row is the optimistic
    // stand-in for a line the server has not seen yet; minting it `held` in a
    // venue with no prep queue would offer a fire-course action for a course
    // nothing will ever fire, then silently swap under the waiter on reconnect.
    final bypassKds = ref.read(venueSettingsProvider).bypassKds;
    final newTickets = [
      for (var i = 0; i < cart.length; i++)
        Ticket(
          id: 'N${SatClock.now().millisecondsSinceEpoch}-$i',
          itemId: cart[i].itemId,
          name: cart[i].name,
          variantName: cart[i].variantName,
          course: cart[i].course,
          qty: cart[i].qty,
          modifiers: cart[i].selectedModifiers,
          note: cart[i].note.isEmpty ? null : cart[i].note,
          price: cart[i].unitPrice,
          status: bypassKds
              ? TicketStatus.ready
              : ((cart[i].course == CourseId.fireNow ||
                        cart[i].course == CourseId.drinksNow)
                    ? TicketStatus.sent
                    : TicketStatus.held),
          sentAt: stamp,
          sentAtTime: now,
          readyAtTime: bypassKds ? now : null,
          createdBy: actorId,
        ),
    ];
    final next = Map<String, List<Ticket>>.from(state);
    next[tableId] = [...(next[tableId] ?? const []), ...newTickets];
    state = next;
    return newTickets;
  }

  Future<void> fireCourse(String tableId, CourseId courseId) async {
    SatLog.repo(
      'tickets.fireCourse table=${tableId.substring(0, tableId.length.clamp(0, 6))} course=${courseId.name}',
    );
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      _fireCourseLocal(tableId, courseId);
      return;
    }
    final key = switch (courseId) {
      CourseId.drinksNow => 'drinks-now',
      CourseId.starters => 'starters',
      CourseId.mains => 'mains',
      CourseId.sides => 'sides',
      CourseId.desserts => 'desserts',
      CourseId.fireNow => 'fire-now',
    };
    // Server is authoritative: post the table-scoped fire and let the WS
    // merge (or the returned ticket rows below) update local state. Errors
    // propagate so callers can surface them.
    final raw = await ref
        .read(apiClientProvider)
        .postJson('/tables/$tableId/course/$key/fire', const {});
    final map = (raw as Map).cast<String, dynamic>();
    final ticketsJson = (map['tickets'] as List? ?? const [])
        .cast<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList();
    if (ticketsJson.isEmpty) return;
    final groupKey = _keyForTable(tableId);
    final next = Map<String, List<Ticket>>.from(state);
    final list = List<Ticket>.from(next[groupKey] ?? const []);
    for (final j in ticketsJson) {
      final dto = TicketDto.fromJson(j);
      final idx = list.indexWhere((t) => t.id == dto.id);
      if (idx == -1) {
        list.add(_toDomain(dto));
      } else {
        list[idx] = _toDomain(dto);
      }
    }
    next[groupKey] = list;
    state = next;
  }

  void _fireCourseLocal(String tableId, CourseId courseId) {
    final next = Map<String, List<Ticket>>.from(state);
    final list = next[tableId];
    if (list == null) return;
    next[tableId] = [
      for (final t in list)
        if (t.course == courseId && t.status == TicketStatus.held)
          t.copyWith(status: TicketStatus.sent)
        else
          t,
    ];
    state = next;
  }

  Future<void> markServed(String tableId, String ticketId) {
    return transition(tableId, ticketId, TicketStatus.served);
  }

  /// Toggles a single kitchen line item between active (`sent`/`prep`) and
  /// `cooked`. Each step is posted to the server so all clients converge.
  ///
  /// A kitchen "order card" is the set of kitchen-station tickets sharing
  /// the same `sentAt` stamp; once every item in that batch is `cooked`, the
  /// whole batch is promoted to `ready` (cooked → ready per the transition
  /// graph) so it leaves the kitchen queue and surfaces to the waiter via
  /// the existing ready alerts.
  Future<void> toggleCooked(String tableId, String ticketId) async {
    final target = findTicket(tableId, ticketId);
    if (target == null) return;
    final nowCooked = target.status != TicketStatus.cooked;
    if (nowCooked) {
      if (target.status == TicketStatus.sent) {
        await transition(tableId, ticketId, TicketStatus.prep);
      }
      if (findTicket(tableId, ticketId)?.status != TicketStatus.cooked) {
        await transition(tableId, ticketId, TicketStatus.cooked);
      }
    } else {
      // cooked is a terminal-ish kitchen state per the canonical graph
      // (cooked → ready/voided only). No legal "uncook" path, so this
      // direction is a no-op rather than a server-divergent local rewind.
      return;
    }

    final batchKey = _keyOfTicket(ticketId);
    final list =
        (batchKey == null ? null : state[batchKey]) ?? const <Ticket>[];
    bool inBatch(Ticket t) => t.sentAt == target.sentAt;
    bool active(Ticket t) =>
        t.status == TicketStatus.sent ||
        t.status == TicketStatus.prep ||
        t.status == TicketStatus.cooked;
    final batch = list.where((t) => inBatch(t) && active(t)).toList();
    if (batch.isNotEmpty &&
        batch.every((t) => t.status == TicketStatus.cooked)) {
      for (final t in batch) {
        await transition(tableId, t.id, TicketStatus.ready);
      }
    }
  }

  /// Walks served back to ready. Posts to the server; relies on the server
  /// allowing `served → ready` (see [_allowedTransitions] in tickets_routes).
  Future<void> unserve(String tableId, String ticketId) {
    return transition(tableId, ticketId, TicketStatus.ready);
  }

  Future<bool> voidTicket(
    String tableId,
    String ticketId,
    String reason,
    String reasonCode, {
    String? actorId,
  }) {
    return transition(
      tableId,
      ticketId,
      TicketStatus.voided,
      voidReason: reason,
      voidReasonCode: reasonCode,
      actorId: actorId,
    );
  }
}

final ticketsProvider =
    StateNotifierProvider<TicketsRepository, Map<String, List<Ticket>>>((ref) {
      ref.watch(apiConfigProvider);
      return TicketsRepository(ref: ref);
    });

/// Live lines for one visit — the stable bill key (ADR-0024), and the way any
/// widget showing a single visit's lines should read them.
///
/// [ticketsProvider] holds every visit's lines in one map, replaced wholesale
/// on each `ticketCreated` / `ticketUpdated` event. A widget that reads the map
/// directly therefore rebuilds when a line is sent at *any other table*. This
/// provider re-emits only when the identity of its own list changes: the
/// repository rebuilds the map but reuses the untouched groups' List instances,
/// so Riverpod's `!=` check stops the propagation here.
///
/// Returns `const []` for an unknown visit — and `const` matters: two calls
/// return the identical instance, so an empty group cannot cause a rebuild
/// either.
final ticketsForVisitProvider = Provider.family<List<Ticket>, String>(
  (ref, visitId) => ref.watch(ticketsProvider)[visitId] ?? const <Ticket>[],
);

/// Live dine-in lines for a table, resolved through the table's current visit.
/// Groups are keyed by visitId (ADR-0034), and a tableId is reused across
/// visits, so a dine-in screen must look up by the table's currentVisitId — not
/// the tableId — to avoid re-absorbing a prior, settled visit's lines on a
/// reseat. Returns `const []` when the table holds no live visit.
///
/// Prefer [ticketsForVisitProvider] where a visitId is already in hand: this
/// one additionally watches the whole table list to resolve one, so it
/// re-executes on every table update, and it scans that list to do so.
final ticketsForTableProvider = Provider.family<List<Ticket>, String>((
  ref,
  tableId,
) {
  final table = ref
      .watch(tablesProvider)
      .where((t) => t.id == tableId)
      .firstOrNull;
  final vid = table?.currentVisitId;
  if (vid != null && vid.isNotEmpty) {
    return ref.watch(ticketsForVisitProvider(vid));
  }
  // Legacy pre-v29 rows (null visitId) key by tableId; honour that fallback.
  return ref.watch(ticketsForVisitProvider(tableId));
});
