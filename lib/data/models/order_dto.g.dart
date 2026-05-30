// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CartModifierDtoImpl _$$CartModifierDtoImplFromJson(
  Map<String, dynamic> json,
) => _$CartModifierDtoImpl(
  groupId: json['groupId'] as String,
  optionId: json['optionId'] as String,
  label: json['label'] as String,
  priceDelta: (json['priceDelta'] as num).toInt(),
);

Map<String, dynamic> _$$CartModifierDtoImplToJson(
  _$CartModifierDtoImpl instance,
) => <String, dynamic>{
  'groupId': instance.groupId,
  'optionId': instance.optionId,
  'label': instance.label,
  'priceDelta': instance.priceDelta,
};

_$CartLineDtoImpl _$$CartLineDtoImplFromJson(Map<String, dynamic> json) =>
    _$CartLineDtoImpl(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      variantId: json['variantId'] as String,
      variantName: json['variantName'] as String,
      modifiers: (json['modifiers'] as List<dynamic>)
          .map((e) => CartModifierDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String?,
      course: json['course'] as String,
      qty: (json['qty'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toInt(),
    );

Map<String, dynamic> _$$CartLineDtoImplToJson(_$CartLineDtoImpl instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'name': instance.name,
      'variantId': instance.variantId,
      'variantName': instance.variantName,
      'modifiers': instance.modifiers,
      'note': instance.note,
      'course': instance.course,
      'qty': instance.qty,
      'unitPrice': instance.unitPrice,
    };

_$SubmitOrderRequestDtoImpl _$$SubmitOrderRequestDtoImplFromJson(
  Map<String, dynamic> json,
) => _$SubmitOrderRequestDtoImpl(
  tableId: json['tableId'] as String,
  idempotencyKey: json['idempotencyKey'] as String,
  lines: (json['lines'] as List<dynamic>)
      .map((e) => CartLineDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  actorId: json['actorId'] as String?,
);

Map<String, dynamic> _$$SubmitOrderRequestDtoImplToJson(
  _$SubmitOrderRequestDtoImpl instance,
) => <String, dynamic>{
  'tableId': instance.tableId,
  'idempotencyKey': instance.idempotencyKey,
  'lines': instance.lines,
  'actorId': instance.actorId,
};

_$SubmitOrderResponseDtoImpl _$$SubmitOrderResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$SubmitOrderResponseDtoImpl(
  ticketIds: (json['ticketIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$$SubmitOrderResponseDtoImplToJson(
  _$SubmitOrderResponseDtoImpl instance,
) => <String, dynamic>{'ticketIds': instance.ticketIds};
