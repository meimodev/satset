// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReservationDto _$ReservationDtoFromJson(Map<String, dynamic> json) =>
    _ReservationDto(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      partySize: (json['partySize'] as num?)?.toInt() ?? 1,
      expectedAt: DateTime.parse(json['expectedAt'] as String),
      status: json['status'] as String? ?? 'pending',
      zoneId: json['zoneId'] as String?,
      tableId: json['tableId'] as String?,
      notes: json['notes'] as String?,
      memberId: json['memberId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ReservationDtoToJson(_ReservationDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'partySize': instance.partySize,
      'expectedAt': instance.expectedAt.toIso8601String(),
      'status': instance.status,
      'zoneId': instance.zoneId,
      'tableId': instance.tableId,
      'notes': instance.notes,
      'memberId': instance.memberId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_CreateReservationDto _$CreateReservationDtoFromJson(
  Map<String, dynamic> json,
) => _CreateReservationDto(
  name: json['name'] as String,
  phone: json['phone'] as String?,
  partySize: (json['partySize'] as num?)?.toInt() ?? 1,
  expectedAt: DateTime.parse(json['expectedAt'] as String),
  zoneId: json['zoneId'] as String?,
  tableId: json['tableId'] as String?,
  notes: json['notes'] as String?,
  memberId: json['memberId'] as String?,
);

Map<String, dynamic> _$CreateReservationDtoToJson(
  _CreateReservationDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'phone': instance.phone,
  'partySize': instance.partySize,
  'expectedAt': instance.expectedAt.toIso8601String(),
  'zoneId': instance.zoneId,
  'tableId': instance.tableId,
  'notes': instance.notes,
  'memberId': instance.memberId,
};

_PatchReservationDto _$PatchReservationDtoFromJson(Map<String, dynamic> json) =>
    _PatchReservationDto(
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      partySize: (json['partySize'] as num?)?.toInt(),
      expectedAt: json['expectedAt'] == null
          ? null
          : DateTime.parse(json['expectedAt'] as String),
      status: json['status'] as String?,
      zoneId: json['zoneId'] as String?,
      tableId: json['tableId'] as String?,
      notes: json['notes'] as String?,
      memberId: json['memberId'] as String?,
    );

Map<String, dynamic> _$PatchReservationDtoToJson(
  _PatchReservationDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'phone': instance.phone,
  'partySize': instance.partySize,
  'expectedAt': instance.expectedAt?.toIso8601String(),
  'status': instance.status,
  'zoneId': instance.zoneId,
  'tableId': instance.tableId,
  'notes': instance.notes,
  'memberId': instance.memberId,
};
