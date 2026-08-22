// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TicketModifierDto _$TicketModifierDtoFromJson(Map<String, dynamic> json) =>
    _TicketModifierDto(
      groupId: json['groupId'] as String? ?? '',
      optionId: json['optionId'] as String? ?? '',
      label: json['label'] as String? ?? '',
      priceDelta: (json['priceDelta'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TicketModifierDtoToJson(_TicketModifierDto instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'optionId': instance.optionId,
      'label': instance.label,
      'priceDelta': instance.priceDelta,
    };

_TicketDto _$TicketDtoFromJson(Map<String, dynamic> json) => _TicketDto(
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
          ?.map((e) => TicketModifierDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <TicketModifierDto>[],
  note: json['note'] as String?,
  price: (json['price'] as num).toInt(),
  status: json['status'] as String,
  sentAt: DateTime.parse(json['sentAt'] as String),
  capturedAt: json['capturedAt'] == null
      ? null
      : DateTime.parse(json['capturedAt'] as String),
  replayedByUserId: json['replayedByUserId'] as String?,
  firedAt: json['firedAt'] == null
      ? null
      : DateTime.parse(json['firedAt'] as String),
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

Map<String, dynamic> _$TicketDtoToJson(_TicketDto instance) =>
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
      'capturedAt': instance.capturedAt?.toIso8601String(),
      'replayedByUserId': instance.replayedByUserId,
      'firedAt': instance.firedAt?.toIso8601String(),
      'readyAt': instance.readyAt?.toIso8601String(),
      'servedAt': instance.servedAt?.toIso8601String(),
      'voidReason': instance.voidReason,
      'voidReasonCode': instance.voidReasonCode,
      'voidApprovedBy': instance.voidApprovedBy,
      'createdByUserId': instance.createdByUserId,
      'voidedByUserId': instance.voidedByUserId,
    };

_TicketTransitionRequestDto _$TicketTransitionRequestDtoFromJson(
  Map<String, dynamic> json,
) => _TicketTransitionRequestDto(
  status: json['status'] as String,
  voidReason: json['voidReason'] as String?,
  voidReasonCode: json['voidReasonCode'] as String?,
);

Map<String, dynamic> _$TicketTransitionRequestDtoToJson(
  _TicketTransitionRequestDto instance,
) => <String, dynamic>{
  'status': instance.status,
  'voidReason': instance.voidReason,
  'voidReasonCode': instance.voidReasonCode,
};
