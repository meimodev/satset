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
}
