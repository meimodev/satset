import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/course.dart';
import '../models/dummy_data.dart';
import '../models/menu_item.dart';
import '../models/ticket.dart';

class TicketsNotifier extends StateNotifier<Map<String, List<Ticket>>> {
  TicketsNotifier() : super(DummyData.initialTicketsByTable());

  String _nowStamp(DateTime d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(d.hour)}:${pad(d.minute)}';
  }

  List<Ticket> sendOrder(String tableId, List<CartItem> cart) {
    final stamp = _nowStamp(DateTime.now());
    final newTickets = [
      for (var i = 0; i < cart.length; i++)
        Ticket(
          id: 'N${DateTime.now().millisecondsSinceEpoch}-$i',
          itemId: cart[i].itemId,
          name: cart[i].name,
          variantName: cart[i].variantName,
          course: cart[i].course,
          station: cart[i].station,
          qty: cart[i].qty,
          modifiers: cart[i].modifiers,
          specialInstructions: cart[i].special.isEmpty ? null : cart[i].special,
          price: cart[i].unitPrice,
          status: (cart[i].course == CourseId.fireNow || cart[i].course == CourseId.drinksNow)
              ? TicketStatus.sent
              : TicketStatus.held,
          sentAt: stamp,
        ),
    ];
    final next = Map<String, List<Ticket>>.from(state);
    next[tableId] = [...(next[tableId] ?? const []), ...newTickets];
    state = next;
    return newTickets;
  }

  void fireCourse(String tableId, CourseId courseId) {
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

  void markServed(String tableId, String ticketId) {
    final next = Map<String, List<Ticket>>.from(state);
    final list = next[tableId];
    if (list == null) return;
    next[tableId] = [
      for (final t in list)
        if (t.id == ticketId) t.copyWith(status: TicketStatus.served) else t,
    ];
    state = next;
  }

  /// Toggles a single kitchen line item between active (`sent`) and `cooked`.
  /// A kitchen "order card" is the set of kitchen-station tickets sharing the
  /// same `sentAt` stamp; once every item in that batch is cooked, the whole
  /// batch is promoted to `ready` so it leaves the kitchen queue and surfaces
  /// to the waiter via the existing ready alerts.
  void toggleCooked(String tableId, String ticketId) {
    final next = Map<String, List<Ticket>>.from(state);
    final list = next[tableId];
    if (list == null) return;
    final target = list.where((t) => t.id == ticketId).firstOrNull;
    if (target == null) return;

    final nowCooked = target.status != TicketStatus.cooked;
    var updated = [
      for (final t in list)
        if (t.id == ticketId)
          t.copyWith(
              status: nowCooked ? TicketStatus.cooked : TicketStatus.sent)
        else
          t,
    ];

    bool inBatch(Ticket t) =>
        t.station == Station.kitchen && t.sentAt == target.sentAt;
    bool active(Ticket t) =>
        t.status == TicketStatus.sent ||
        t.status == TicketStatus.prep ||
        t.status == TicketStatus.cooked;

    final batch = updated.where((t) => inBatch(t) && active(t));
    if (batch.isNotEmpty &&
        batch.every((t) => t.status == TicketStatus.cooked)) {
      updated = [
        for (final t in updated)
          if (inBatch(t) && t.status == TicketStatus.cooked)
            t.copyWith(status: TicketStatus.ready)
          else
            t,
      ];
    }

    next[tableId] = updated;
    state = next;
  }

  void unserve(String tableId, String ticketId) {
    final next = Map<String, List<Ticket>>.from(state);
    final list = next[tableId];
    if (list == null) return;
    next[tableId] = [
      for (final t in list)
        if (t.id == ticketId) t.copyWith(status: TicketStatus.ready) else t,
    ];
    state = next;
  }

  void voidTicket(String tableId, String ticketId, String reason, String approver) {
    final next = Map<String, List<Ticket>>.from(state);
    final list = next[tableId];
    if (list == null) return;
    next[tableId] = [
      for (final t in list)
        if (t.id == ticketId)
          t.copyWith(
            status: TicketStatus.voided,
            voidReason: reason,
            voidApprovedBy: approver,
          )
        else
          t,
    ];
    state = next;
  }
}

final ticketsProvider =
    StateNotifierProvider<TicketsNotifier, Map<String, List<Ticket>>>(
        (ref) => TicketsNotifier());
