import 'package:freezed_annotation/freezed_annotation.dart';

part 'ws_event_dto.freezed.dart';
part 'ws_event_dto.g.dart';

/// WS envelope. `v` is the schema version; bump when payload shape changes.
@freezed
class WsEventDto with _$WsEventDto {
  const factory WsEventDto({
    @Default(1) int v,
    required String type,
    @Default(<String, dynamic>{}) Map<String, dynamic> payload,
    required DateTime ts,
  }) = _WsEventDto;

  factory WsEventDto.fromJson(Map<String, dynamic> json) =>
      _$WsEventDtoFromJson(json);
}

class WsEventTypes {
  WsEventTypes._();

  /// Client-internal: emitted by [WsClient] onto its own event stream every
  /// time the socket reaches `open` (first connect AND every reconnect). The
  /// server never sends this. Repositories listen for it to **full-resync**
  /// their list against the server, recovering from a lossy gap — an empty or
  /// 401 bootstrap, or events missed while the socket was down. See
  /// docs/adr/0021-repository-resync-on-ws-reconnect.md.
  static const connected = 'local.connected';

  static const ticketCreated = 'ticket.created';
  static const ticketUpdated = 'ticket.updated';
  static const tableCreated = 'table.created';
  static const tableUpdated = 'table.updated';
  static const tableDeleted = 'table.deleted';
  static const zoneCreated = 'zone.created';
  static const zoneUpdated = 'zone.updated';
  static const zoneDeleted = 'zone.deleted';
  static const menuUpdated = 'menu.updated';
  static const presenceChanged = 'presence.changed';
  static const staffCreated = 'staff.created';
  static const staffUpdated = 'staff.updated';
  static const staffDeleted = 'staff.deleted';
  static const auditCreated = 'audit.created';
  static const rolesUpdated = 'roles.updated';
  static const venueSettingsUpdated = 'venueSettings.updated';
  static const systemStatus = 'system.status';
  static const devicePaired = 'device.paired';
  static const deviceRevoked = 'device.revoked';
  static const sessionExpired = 'session.expired';
  static const printerCreated = 'printer.created';
  static const printerUpdated = 'printer.updated';
  static const printerDeleted = 'printer.deleted';
  static const serverRestarting = 'server.restarting';
  static const tableSessionClosed = 'tableSession.closed';

  /// A table's [[Bill]] changed — receipt created/removed, line (re)assigned,
  /// payment/refund recorded, or a receipt reopened. Carries the tableId so the
  /// cashier list + any open bill detail re-fetch. See ADR-0023.
  static const billUpdated = 'bill.updated';
  static const reservationCreated = 'reservation.created';
  static const reservationUpdated = 'reservation.updated';
  static const reservationDeleted = 'reservation.deleted';
}
