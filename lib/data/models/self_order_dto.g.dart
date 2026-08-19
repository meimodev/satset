// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'self_order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GuestLineModDtoImpl _$$GuestLineModDtoImplFromJson(
  Map<String, dynamic> json,
) => _$GuestLineModDtoImpl(label: json['label'] as String? ?? '');

Map<String, dynamic> _$$GuestLineModDtoImplToJson(
  _$GuestLineModDtoImpl instance,
) => <String, dynamic>{'label': instance.label};

_$GuestOrderLineDtoImpl _$$GuestOrderLineDtoImplFromJson(
  Map<String, dynamic> json,
) => _$GuestOrderLineDtoImpl(
  id: json['id'] as String,
  itemId: json['itemId'] as String,
  name: json['name'] as String,
  variantName: json['variantName'] as String? ?? '',
  qty: (json['qty'] as num?)?.toInt() ?? 1,
  note: json['note'] as String?,
  unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
  modifiers:
      (json['modifiers'] as List<dynamic>?)
          ?.map((e) => GuestLineModDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$GuestOrderLineDtoImplToJson(
  _$GuestOrderLineDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'itemId': instance.itemId,
  'name': instance.name,
  'variantName': instance.variantName,
  'qty': instance.qty,
  'note': instance.note,
  'unitPrice': instance.unitPrice,
  'modifiers': instance.modifiers,
};

_$GuestOrderDtoImpl _$$GuestOrderDtoImplFromJson(Map<String, dynamic> json) =>
    _$GuestOrderDtoImpl(
      id: json['id'] as String,
      tableId: json['tableId'] as String,
      tableLabel: json['tableLabel'] as String?,
      status: json['status'] as String? ?? 'pending',
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      decidedAt: json['decidedAt'] == null
          ? null
          : DateTime.parse(json['decidedAt'] as String),
      rejectReasonCode: json['rejectReasonCode'] as String?,
      decidedBy: json['decidedBy'] as String?,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      lines:
          (json['lines'] as List<dynamic>?)
              ?.map(
                (e) => GuestOrderLineDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$GuestOrderDtoImplToJson(_$GuestOrderDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tableId': instance.tableId,
      'tableLabel': instance.tableLabel,
      'status': instance.status,
      'submittedAt': instance.submittedAt.toIso8601String(),
      'decidedAt': instance.decidedAt?.toIso8601String(),
      'rejectReasonCode': instance.rejectReasonCode,
      'decidedBy': instance.decidedBy,
      'subtotal': instance.subtotal,
      'lines': instance.lines,
    };

_$GuestTableDtoImpl _$$GuestTableDtoImplFromJson(Map<String, dynamic> json) =>
    _$GuestTableDtoImpl(
      id: json['id'] as String,
      label: json['label'] as String?,
      zoneId: json['zoneId'] as String? ?? '',
      zoneName: json['zoneName'] as String? ?? '',
      seats: (json['seats'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$$GuestTableDtoImplToJson(_$GuestTableDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'zoneId': instance.zoneId,
      'zoneName': instance.zoneName,
      'seats': instance.seats,
      'code': instance.code,
      'enabled': instance.enabled,
    };

_$GuestMenuItemDtoImpl _$$GuestMenuItemDtoImplFromJson(
  Map<String, dynamic> json,
) => _$GuestMenuItemDtoImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  categoryId: json['categoryId'] as String? ?? '',
  description: json['description'] as String? ?? '',
  basePrice: (json['basePrice'] as num?)?.toInt() ?? 0,
  featured: json['featured'] as bool? ?? false,
  visible: json['visible'] as bool? ?? true,
  soldOut: json['soldOut'] as bool? ?? false,
  alcohol: json['alcohol'] as bool? ?? false,
  stockOverride: json['stockOverride'] as String? ?? 'auto',
);

Map<String, dynamic> _$$GuestMenuItemDtoImplToJson(
  _$GuestMenuItemDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'categoryId': instance.categoryId,
  'description': instance.description,
  'basePrice': instance.basePrice,
  'featured': instance.featured,
  'visible': instance.visible,
  'soldOut': instance.soldOut,
  'alcohol': instance.alcohol,
  'stockOverride': instance.stockOverride,
};

_$GuestStatsDtoImpl _$$GuestStatsDtoImplFromJson(Map<String, dynamic> json) =>
    _$GuestStatsDtoImpl(
      total: (json['total'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      accepted: (json['accepted'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
      value: (json['value'] as num?)?.toInt() ?? 0,
      medianWaitSecs: (json['medianWaitSecs'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$GuestStatsDtoImplToJson(_$GuestStatsDtoImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'pending': instance.pending,
      'accepted': instance.accepted,
      'rejected': instance.rejected,
      'value': instance.value,
      'medianWaitSecs': instance.medianWaitSecs,
    };
