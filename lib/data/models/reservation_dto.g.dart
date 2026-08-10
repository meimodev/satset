// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReservationDtoImpl _$$ReservationDtoImplFromJson(Map<String, dynamic> json) =>
    _$ReservationDtoImpl(
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

Map<String, dynamic> _$$ReservationDtoImplToJson(
  _$ReservationDtoImpl instance,
) => <String, dynamic>{
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

_$CreateReservationDtoImpl _$$CreateReservationDtoImplFromJson(
  Map<String, dynamic> json,
) => _$CreateReservationDtoImpl(
  name: json['name'] as String,
  phone: json['phone'] as String?,
  partySize: (json['partySize'] as num?)?.toInt() ?? 1,
  expectedAt: DateTime.parse(json['expectedAt'] as String),
  zoneId: json['zoneId'] as String?,
  tableId: json['tableId'] as String?,
  notes: json['notes'] as String?,
  memberId: json['memberId'] as String?,
);

Map<String, dynamic> _$$CreateReservationDtoImplToJson(
  _$CreateReservationDtoImpl instance,
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

_$PatchReservationDtoImpl _$$PatchReservationDtoImplFromJson(
  Map<String, dynamic> json,
) => _$PatchReservationDtoImpl(
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

Map<String, dynamic> _$$PatchReservationDtoImplToJson(
  _$PatchReservationDtoImpl instance,
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
