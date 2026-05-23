// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CartLineDtoImpl _$$CartLineDtoImplFromJson(Map<String, dynamic> json) =>
    _$CartLineDtoImpl(
      itemId: json['itemId'] as String,
      variantId: json['variantId'] as String,
      modifierOptionIds: (json['modifierOptionIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      specialInstructions: json['specialInstructions'] as String?,
      course: json['course'] as String,
      qty: (json['qty'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toInt(),
    );

Map<String, dynamic> _$$CartLineDtoImplToJson(_$CartLineDtoImpl instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'variantId': instance.variantId,
      'modifierOptionIds': instance.modifierOptionIds,
      'specialInstructions': instance.specialInstructions,
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
);

Map<String, dynamic> _$$SubmitOrderRequestDtoImplToJson(
  _$SubmitOrderRequestDtoImpl instance,
) => <String, dynamic>{
  'tableId': instance.tableId,
  'idempotencyKey': instance.idempotencyKey,
  'lines': instance.lines,
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
