import 'course.dart';
import 'menu_item.dart';

enum TicketStatus { sent, prep, cooked, ready, served, held, voided }

String ticketStatusLabel(TicketStatus s) => switch (s) {
      TicketStatus.sent => 'Terkirim',
      TicketStatus.prep => 'Disiapkan',
      TicketStatus.cooked => 'Selesai dimasak',
      TicketStatus.ready => 'Siap diambil',
      TicketStatus.served => 'Disajikan',
      TicketStatus.held => 'Ditahan',
      TicketStatus.voided => 'Dibatalkan',
    };

class Ticket {
  final String id;
  final String itemId;
  final String name;
  final String variantName;
  final CourseId course;
  final Station station;
  final int qty;
  final List<String> modifiers;
  final String? specialInstructions;
  final int price;
  final TicketStatus status;
  final String sentAt;
  final String? voidReason;
  final String? voidApprovedBy;

  const Ticket({
    required this.id,
    required this.itemId,
    required this.name,
    this.variantName = '',
    required this.course,
    required this.station,
    this.qty = 1,
    this.modifiers = const [],
    this.specialInstructions,
    required this.price,
    required this.status,
    required this.sentAt,
    this.voidReason,
    this.voidApprovedBy,
  });

  Ticket copyWith({
    TicketStatus? status,
    String? voidReason,
    String? voidApprovedBy,
  }) {
    return Ticket(
      id: id,
      itemId: itemId,
      name: name,
      variantName: variantName,
      course: course,
      station: station,
      qty: qty,
      modifiers: modifiers,
      specialInstructions: specialInstructions,
      price: price,
      status: status ?? this.status,
      sentAt: sentAt,
      voidReason: voidReason ?? this.voidReason,
      voidApprovedBy: voidApprovedBy ?? this.voidApprovedBy,
    );
  }
}
