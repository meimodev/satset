import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/settlement_event.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/ticket_modifier.dart';

/// The floor's view of host tickets plus locally captured acts. Never fed to
/// the kitchen: a captured line is visible and billable before it is delivered.
Map<String, List<Ticket>> projectCapturedTickets(
  Map<String, List<Ticket>> host,
  List<SettlementEvent> events,
) {
  if (events.isEmpty) return host;
  final groups = {
    for (final e in host.entries) e.key: [...e.value],
  };
  final ordered = [...events]..sort((a, b) => a.seq.compareTo(b.seq));
  for (final event in ordered) {
    if (event.kind == SettlementEventKind.submitOrder) {
      final tickets = groups.putIfAbsent(event.visitId, () => []);
      for (final raw in event.payload['lines'] as List? ?? const []) {
        final line = (raw as Map).cast<String, dynamic>();
        final id = line['ticketId'] as String?;
        if (id == null || tickets.any((t) => t.id == id)) continue;
        final course = Courses.all
            .where((c) => c.serialId == line['course'])
            .firstOrNull;
        tickets.add(
          Ticket(
            id: id,
            visitId: event.visitId,
            tableId: event.tableId ?? '',
            itemId: line['itemId'] as String? ?? '',
            name: line['name'] as String? ?? '',
            variantName: line['variantName'] as String? ?? '',
            memberId: line['memberId'] as String?,
            course: course?.id ?? CourseId.fireNow,
            qty: (line['qty'] as num?)?.toInt() ?? 1,
            price: (line['unitPrice'] as num?)?.toInt() ?? 0,
            note: line['note'] as String?,
            createdBy: event.actorId,
            status: TicketStatus.sent,
            sentAt: event.capturedAt.toIso8601String(),
            sentAtTime: event.capturedAt,
            modifiers: [
              for (final m in line['modifiers'] as List? ?? const [])
                TicketModifier(
                  groupId: m['groupId'] as String? ?? '',
                  optionId: m['optionId'] as String? ?? '',
                  label: m['label'] as String? ?? '',
                  priceDelta: (m['priceDelta'] as num?)?.toInt() ?? 0,
                ),
            ],
          ),
        );
      }
    } else if (event.kind == SettlementEventKind.voidTicket &&
        !event.isParked) {
      final tickets = groups[event.visitId];
      if (tickets == null) continue;
      groups[event.visitId] = [
        for (final t in tickets)
          if (t.id == event.arg<String>('ticketId'))
            t.copyWith(
              status: TicketStatus.voided,
              voidReason: event.arg<String>('voidReason'),
              voidReasonCode: event.arg<String>('voidReasonCode'),
            )
          else
            t,
      ];
    }
  }
  return groups;
}
