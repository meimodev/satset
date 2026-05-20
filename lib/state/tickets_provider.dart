import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/course.dart';
import '../models/dummy_data.dart';
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
