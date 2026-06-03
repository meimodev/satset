// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TicketModifierDtoImpl _$$TicketModifierDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TicketModifierDtoImpl(
  groupId: json['groupId'] as String? ?? '',
  optionId: json['optionId'] as String? ?? '',
  label: json['label'] as String? ?? '',
  priceDelta: (json['priceDelta'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$TicketModifierDtoImplToJson(
  _$TicketModifierDtoImpl instance,
) => <String, dynamic>{
  'groupId': instance.groupId,
  'optionId': instance.optionId,
  'label': instance.label,
  'priceDelta': instance.priceDelta,
};

_$TicketDtoImpl _$$TicketDtoImplFromJson(Map<String, dynamic> json) =>
    _$TicketDtoImpl(
      id: json['id'] as String,
      tableId: json['tableId'] as String,
      visitId: json['visitId'] as String?,
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      variantName: json['variantName'] as String? ?? '',
      course: json['course'] as String,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      modifiers:
          (json['modifiers'] as List<dynamic>?)
              ?.map(
                (e) => TicketModifierDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <TicketModifierDto>[],
      note: json['note'] as String?,
      price: (json['price'] as num).toInt(),
      status: json['status'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      readyAt: json['readyAt'] == null
          ? null
          : DateTime.parse(json['readyAt'] as String),
      servedAt: json['servedAt'] == null
          ? null
          : DateTime.parse(json['servedAt'] as String),
      voidReason: json['voidReason'] as String?,
      voidReasonCode: json['voidReasonCode'] as String?,
      voidApprovedBy: json['voidApprovedBy'] as String?,
      createdByUserId: json['createdByUserId'] as String?,
      voidedByUserId: json['voidedByUserId'] as String?,
    );

Map<String, dynamic> _$$TicketDtoImplToJson(_$TicketDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tableId': instance.tableId,
      'visitId': instance.visitId,
      'itemId': instance.itemId,
      'name': instance.name,
      'variantName': instance.variantName,
      'course': instance.course,
      'qty': instance.qty,
      'modifiers': instance.modifiers,
      'note': instance.note,
      'price': instance.price,
      'status': instance.status,
      'sentAt': instance.sentAt.toIso8601String(),
      'readyAt': instance.readyAt?.toIso8601String(),
      'servedAt': instance.servedAt?.toIso8601String(),
      'voidReason': instance.voidReason,
      'voidReasonCode': instance.voidReasonCode,
      'voidApprovedBy': instance.voidApprovedBy,
      'createdByUserId': instance.createdByUserId,
      'voidedByUserId': instance.voidedByUserId,
    };

_$TicketTransitionRequestDtoImpl _$$TicketTransitionRequestDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TicketTransitionRequestDtoImpl(
  status: json['status'] as String,
  voidReason: json['voidReason'] as String?,
  voidReasonCode: json['voidReasonCode'] as String?,
);

Map<String, dynamic> _$$TicketTransitionRequestDtoImplToJson(
  _$TicketTransitionRequestDtoImpl instance,
) => <String, dynamic>{
  'status': instance.status,
  'voidReason': instance.voidReason,
  'voidReasonCode': instance.voidReasonCode,
};
