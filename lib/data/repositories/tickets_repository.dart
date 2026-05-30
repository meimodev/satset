import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/order_dto.dart';
import 'package:satset/data/models/ticket_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/ticket_modifier.dart';

/// Surfaces bootstrap progress for the per-table ticket list.
final ticketsStatusProvider =
    StateProvider<AsyncValue<void>>((_) => const AsyncValue.data(null));

class TicketsRepository extends StateNotifier<Map<String, List<Ticket>>> {
  TicketsRepository({required this.ref})
      : super(const <String, List<Ticket>>{}) {
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(ticketsStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    state = const <String, List<Ticket>>{};
    ref.read(ticketsStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      final raw = await api.getJson('/tickets') as List;
      final grouped = <String, List<Ticket>>{};
      for (final e in raw) {
        final dto = TicketDto.fromJson((e as Map).cast<String, dynamic>());
        grouped.putIfAbsent(dto.tableId, () => []).add(_toDomain(dto));
      }
      state = grouped;
      SatLog.repo('tickets.loaded tables=${grouped.length} tickets=${grouped.values.fold<int>(0, (s, l) => s + l.length)}');
      ref.read(ticketsStatusProvider.notifier).state =
          const AsyncValue.data(null);
    } catch (e, st) {
      SatLog.repo('tickets.bootstrap fail $e');
      ref.read(ticketsStatusProvider.notifier).state =
          AsyncValue.error(e, st);
    }
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type == WsEventTypes.ticketCreated ||
          ev.type == WsEventTypes.ticketUpdated) {
        final dto = TicketDto.fromJson(ev.payload);
        SatLog.repo('tickets.ws ${ev.type} id=${dto.id.substring(0, dto.id.length.clamp(0, 6))} status=${dto.status}');
        final next = Map<String, List<Ticket>>.from(state);
        final list = List<Ticket>.from(next[dto.tableId] ?? const []);
        final idx = list.indexWhere((t) => t.id == dto.id);
        if (idx == -1) {
          list.add(_toDomain(dto));
        } else {
          list[idx] = _toDomain(dto);
        }
        next[dto.tableId] = list;
        state = next;
      } else if (ev.type == WsEventTypes.tableSessionClosed) {
        final tableId = ev.payload['tableId'] as String?;
        if (tableId == null) return;
        SatLog.repo('tickets.ws tableSession.closed table=${tableId.substring(0, tableId.length.clamp(0, 6))} — purging local tickets');
        final next = Map<String, List<Ticket>>.from(state);
        next.remove(tableId);
        state = next;
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Ticket _toDomain(TicketDto d) {
    return Ticket(
      id: d.id,
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

  Ticket? findTicket(String tableId, String ticketId) {
    final list = state[tableId];
    if (list == null) return null;
    for (final t in list) {
      if (t.id == ticketId) return t;
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
    SatLog.repo('tickets.submit table=${tableId.substring(0, tableId.length.clamp(0, 6))} lines=${lines.length}');
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
      return sendOrder(tableId, cart, actorId: actorId)
          .map((t) => t.id)
          .toList();
    }
    final api = ref.read(apiClientProvider);
    final raw = await api.postJson(
      '/orders',
      SubmitOrderRequestDto(
        tableId: tableId,
        idempotencyKey: idempotencyKey,
        lines: lines,
        actorId: actorId,
      ).toJson(),
    );
    final res = SubmitOrderResponseDto.fromJson(
        (raw as Map).cast<String, dynamic>());
    return res.ticketIds;
  }

  /// Posts a status change to the server when paired and applies the same
  /// change optimistically. Optional `voidReason` / `voidApprovedBy` ride
  /// along on void transitions.
  Future<void> transition(
    String tableId,
    String ticketId,
    TicketStatus to, {
    String? voidReason,
    String? voidReasonCode,
    String? voidApprovedBy,
  }) async {
    SatLog.repo('tickets.transition id=${ticketId.substring(0, ticketId.length.clamp(0, 6))} → ${to.name}');
    final cfg = ref.read(apiConfigProvider);
    if (cfg != null) {
      final body = <String, dynamic>{
        'status': ticketStatusKey(to),
        'voidReason': ?voidReason,
        'voidReasonCode': ?voidReasonCode,
        'voidApprovedBy': ?voidApprovedBy,
      };
      await ref.read(apiClientProvider).postJson(
            '/tickets/$ticketId/transition',
            body,
          );
    }
    final next = Map<String, List<Ticket>>.from(state);
    final list = next[tableId];
    if (list == null) return;
    next[tableId] = [
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
  }

  String _nowStamp(DateTime d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(d.hour)}:${pad(d.minute)}';
  }

  List<Ticket> sendOrder(String tableId, List<CartItem> cart, {String? actorId}) {
    final now = DateTime.now();
    final stamp = _nowStamp(now);
    final newTickets = [
      for (var i = 0; i < cart.length; i++)
        Ticket(
          id: 'N${DateTime.now().millisecondsSinceEpoch}-$i',
          itemId: cart[i].itemId,
          name: cart[i].name,
          variantName: cart[i].variantName,
          course: cart[i].course,
          qty: cart[i].qty,
          modifiers: cart[i].selectedModifiers,
          note: cart[i].note.isEmpty ? null : cart[i].note,
          price: cart[i].unitPrice,
          status: (cart[i].course == CourseId.fireNow || cart[i].course == CourseId.drinksNow)
              ? TicketStatus.sent
              : TicketStatus.held,
          sentAt: stamp,
          sentAtTime: now,
          createdBy: actorId,
        ),
    ];
    final next = Map<String, List<Ticket>>.from(state);
    next[tableId] = [...(next[tableId] ?? const []), ...newTickets];
    state = next;
    return newTickets;
  }

  Future<void> fireCourse(String tableId, CourseId courseId) async {
    SatLog.repo('tickets.fireCourse table=${tableId.substring(0, tableId.length.clamp(0, 6))} course=${courseId.name}');
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
    final next = Map<String, List<Ticket>>.from(state);
    final list = List<Ticket>.from(next[tableId] ?? const []);
    for (final j in ticketsJson) {
      final dto = TicketDto.fromJson(j);
      final idx = list.indexWhere((t) => t.id == dto.id);
      if (idx == -1) {
        list.add(_toDomain(dto));
      } else {
        list[idx] = _toDomain(dto);
      }
    }
    next[tableId] = list;
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
      if (state[tableId]
              ?.firstWhere((t) => t.id == ticketId, orElse: () => target)
              .status !=
          TicketStatus.cooked) {
        await transition(tableId, ticketId, TicketStatus.cooked);
      }
    } else {
      // cooked is a terminal-ish kitchen state per the canonical graph
      // (cooked → ready/voided only). No legal "uncook" path, so this
      // direction is a no-op rather than a server-divergent local rewind.
      return;
    }

    final list = state[tableId] ?? const <Ticket>[];
    bool inBatch(Ticket t) =>
        t.sentAt == target.sentAt;
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

  Future<void> voidTicket(
    String tableId,
    String ticketId,
    String reason,
    String reasonCode,
  ) {
    return transition(
      tableId,
      ticketId,
      TicketStatus.voided,
      voidReason: reason,
      voidReasonCode: reasonCode,
    );
  }
}

final ticketsProvider =
    StateNotifierProvider<TicketsRepository, Map<String, List<Ticket>>>((ref) {
  ref.watch(apiConfigProvider);
  return TicketsRepository(ref: ref);
});
