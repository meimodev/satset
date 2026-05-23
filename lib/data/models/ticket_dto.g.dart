// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TicketDtoImpl _$$TicketDtoImplFromJson(Map<String, dynamic> json) =>
    _$TicketDtoImpl(
      id: json['id'] as String,
      tableId: json['tableId'] as String,
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      variantName: json['variantName'] as String? ?? '',
      course: json['course'] as String,
      station: json['station'] as String,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      modifiers:
          (json['modifiers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      specialInstructions: json['specialInstructions'] as String?,
      price: (json['price'] as num).toInt(),
      status: json['status'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      voidReason: json['voidReason'] as String?,
      voidApprovedBy: json['voidApprovedBy'] as String?,
    );

Map<String, dynamic> _$$TicketDtoImplToJson(_$TicketDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tableId': instance.tableId,
      'itemId': instance.itemId,
      'name': instance.name,
      'variantName': instance.variantName,
      'course': instance.course,
      'station': instance.station,
      'qty': instance.qty,
      'modifiers': instance.modifiers,
      'specialInstructions': instance.specialInstructions,
      'price': instance.price,
      'status': instance.status,
      'sentAt': instance.sentAt.toIso8601String(),
      'voidReason': instance.voidReason,
      'voidApprovedBy': instance.voidApprovedBy,
    };

_$TicketTransitionRequestDtoImpl _$$TicketTransitionRequestDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TicketTransitionRequestDtoImpl(
  status: json['status'] as String,
  voidReason: json['voidReason'] as String?,
);

Map<String, dynamic> _$$TicketTransitionRequestDtoImplToJson(
  _$TicketTransitionRequestDtoImpl instance,
) => <String, dynamic>{
  'status': instance.status,
  'voidReason': instance.voidReason,
};
