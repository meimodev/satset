import 'package:freezed_annotation/freezed_annotation.dart';

import 'course.dart';
import 'menu_item.dart';

part 'ticket.freezed.dart';

/// Ticket lifecycle.
///
/// `draft` and `acknowledged` exist for the LAN backend: a cart staged
/// before submit is `draft`; `acknowledged` is reserved for the case where
/// the server wants a held queue before it dispatches to KDS. The active
/// kitchen lifecycle today is `sent → prep → cooked → ready → served`,
/// with `held` for course-pacing and `voided` as the terminal failure
/// state.
enum TicketStatus {
  draft,
  acknowledged,
  sent,
  prep,
  cooked,
  ready,
  served,
  held,
  voided,
}

String ticketStatusLabel(TicketStatus s) => switch (s) {
      TicketStatus.draft => 'Draf',
      TicketStatus.acknowledged => 'Diterima',
      TicketStatus.sent => 'Terkirim',
      TicketStatus.prep => 'Disiapkan',
      TicketStatus.cooked => 'Selesai dimasak',
      TicketStatus.ready => 'Siap diambil',
      TicketStatus.served => 'Disajikan',
      TicketStatus.held => 'Ditahan',
      TicketStatus.voided => 'Dibatalkan',
    };

String ticketStatusKey(TicketStatus s) => switch (s) {
      TicketStatus.draft => 'draft',
      TicketStatus.acknowledged => 'acknowledged',
      TicketStatus.sent => 'sent',
      TicketStatus.prep => 'prep',
      TicketStatus.cooked => 'cooked',
      TicketStatus.ready => 'ready',
      TicketStatus.served => 'served',
      TicketStatus.held => 'held',
      TicketStatus.voided => 'voided',
    };

TicketStatus ticketStatusFromKey(String? raw) => switch (raw) {
      'draft' => TicketStatus.draft,
      'acknowledged' => TicketStatus.acknowledged,
      'sent' => TicketStatus.sent,
      'prep' => TicketStatus.prep,
      'cooked' => TicketStatus.cooked,
      'ready' => TicketStatus.ready,
      'served' => TicketStatus.served,
      'held' => TicketStatus.held,
      'voided' => TicketStatus.voided,
      _ => TicketStatus.sent,
    };

/// Immutable ticket aggregate. `copyWith`, equality, and `hashCode` come
/// from Freezed.
@freezed
class Ticket with _$Ticket {
  const factory Ticket({
    required String id,
    required String itemId,
    required String name,
    @Default('') String variantName,
    required CourseId course,
    required Station station,
    @Default(1) int qty,
    @Default(<String>[]) List<String> modifiers,
    String? specialInstructions,
    required int price,
    required TicketStatus status,
    required String sentAt,
    String? voidReason,
    String? voidReasonCode,
    String? voidApprovedBy,
    String? createdBy,
    String? voidedBy,
  }) = _Ticket;
}
