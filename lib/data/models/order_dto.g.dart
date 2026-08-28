// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CartModifierDto _$CartModifierDtoFromJson(Map<String, dynamic> json) =>
    _CartModifierDto(
      groupId: json['groupId'] as String,
      optionId: json['optionId'] as String,
      label: json['label'] as String,
      priceDelta: (json['priceDelta'] as num).toInt(),
    );

Map<String, dynamic> _$CartModifierDtoToJson(_CartModifierDto instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'optionId': instance.optionId,
      'label': instance.label,
      'priceDelta': instance.priceDelta,
    };

_CartLineDto _$CartLineDtoFromJson(Map<String, dynamic> json) => _CartLineDto(
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

Map<String, dynamic> _$CartLineDtoToJson(_CartLineDto instance) =>
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

_SubmitOrderRequestDto _$SubmitOrderRequestDtoFromJson(
  Map<String, dynamic> json,
) => _SubmitOrderRequestDto(
  tableId: json['tableId'] as String,
  idempotencyKey: json['idempotencyKey'] as String,
  lines: (json['lines'] as List<dynamic>)
      .map((e) => CartLineDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  actorId: json['actorId'] as String?,
);

Map<String, dynamic> _$SubmitOrderRequestDtoToJson(
  _SubmitOrderRequestDto instance,
) => <String, dynamic>{
  'tableId': instance.tableId,
  'idempotencyKey': instance.idempotencyKey,
  'lines': instance.lines,
  'actorId': instance.actorId,
};

_SubmitOrderResponseDto _$SubmitOrderResponseDtoFromJson(
  Map<String, dynamic> json,
) => _SubmitOrderResponseDto(
  ticketIds: (json['ticketIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  visitId: json['visitId'] as String?,
  rejected:
      (json['rejected'] as List<dynamic>?)
          ?.map((e) => RejectedLineDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <RejectedLineDto>[],
);

Map<String, dynamic> _$SubmitOrderResponseDtoToJson(
  _SubmitOrderResponseDto instance,
) => <String, dynamic>{
  'ticketIds': instance.ticketIds,
  'visitId': instance.visitId,
  'rejected': instance.rejected,
};

_RejectedLineDto _$RejectedLineDtoFromJson(Map<String, dynamic> json) =>
    _RejectedLineDto(
      itemId: json['itemId'] as String,
      name: json['name'] as String? ?? '',
      variantName: json['variantName'] as String? ?? '',
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$RejectedLineDtoToJson(_RejectedLineDto instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'name': instance.name,
      'variantName': instance.variantName,
      'ingredients': instance.ingredients,
    };
