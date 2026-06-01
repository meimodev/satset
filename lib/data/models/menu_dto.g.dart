// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MenuSnapshotDtoImpl _$$MenuSnapshotDtoImplFromJson(
  Map<String, dynamic> json,
) => _$MenuSnapshotDtoImpl(
  version: (json['version'] as num).toInt(),
  categories: (json['categories'] as List<dynamic>)
      .map((e) => MenuCategoryDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  items: (json['items'] as List<dynamic>)
      .map((e) => MenuItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => MenuTagDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MenuTagDto>[],
);

Map<String, dynamic> _$$MenuSnapshotDtoImplToJson(
  _$MenuSnapshotDtoImpl instance,
) => <String, dynamic>{
  'version': instance.version,
  'categories': instance.categories,
  'items': instance.items,
  'tags': instance.tags,
};

_$MenuCategoryDtoImpl _$$MenuCategoryDtoImplFromJson(
  Map<String, dynamic> json,
) => _$MenuCategoryDtoImpl(
  id: json['id'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$$MenuCategoryDtoImplToJson(
  _$MenuCategoryDtoImpl instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

_$VariantDtoImpl _$$VariantDtoImplFromJson(Map<String, dynamic> json) =>
    _$VariantDtoImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toInt(),
    );

Map<String, dynamic> _$$VariantDtoImplToJson(_$VariantDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
    };

_$MenuItemDtoImpl _$$MenuItemDtoImplFromJson(
  Map<String, dynamic> json,
) => _$MenuItemDtoImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  categoryId: json['categoryId'] as String,
  description: json['description'] as String? ?? '',
  basePrice: (json['basePrice'] as num).toInt(),
  cost: (json['cost'] as num?)?.toInt() ?? 0,
  prepTime: (json['prepTime'] as num?)?.toInt() ?? 5,
  variants:
      (json['variants'] as List<dynamic>?)
          ?.map((e) => VariantDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <VariantDto>[],
  modifierGroups:
      (json['modifierGroups'] as List<dynamic>?)
          ?.map((e) => ModifierGroupDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ModifierGroupDto>[],
  allergens:
      (json['allergens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  dietary:
      (json['dietary'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  unavailable: json['unavailable'] as bool? ?? false,
  photoRev: (json['photoRev'] as num?)?.toInt() ?? 0,
  stockCount: (json['stockCount'] as num?)?.toInt(),
  autoSoldOutAtZero: json['autoSoldOutAtZero'] as bool? ?? false,
);

Map<String, dynamic> _$$MenuItemDtoImplToJson(_$MenuItemDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'categoryId': instance.categoryId,
      'description': instance.description,
      'basePrice': instance.basePrice,
      'cost': instance.cost,
      'prepTime': instance.prepTime,
      'variants': instance.variants,
      'modifierGroups': instance.modifierGroups,
      'allergens': instance.allergens,
      'dietary': instance.dietary,
      'unavailable': instance.unavailable,
      'photoRev': instance.photoRev,
      'stockCount': instance.stockCount,
      'autoSoldOutAtZero': instance.autoSoldOutAtZero,
    };

_$MenuTagDtoImpl _$$MenuTagDtoImplFromJson(Map<String, dynamic> json) =>
    _$MenuTagDtoImpl(
      id: json['id'] as String,
      kind: json['kind'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$MenuTagDtoImplToJson(_$MenuTagDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'name': instance.name,
      'code': instance.code,
      'sortOrder': instance.sortOrder,
    };

_$ModifierOptionDtoImpl _$$ModifierOptionDtoImplFromJson(
  Map<String, dynamic> json,
) => _$ModifierOptionDtoImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  priceDelta: (json['priceDelta'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$ModifierOptionDtoImplToJson(
  _$ModifierOptionDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'priceDelta': instance.priceDelta,
};

_$ModifierGroupDtoImpl _$$ModifierGroupDtoImplFromJson(
  Map<String, dynamic> json,
) => _$ModifierGroupDtoImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  required: json['required'] as bool? ?? false,
  multi: json['multi'] as bool? ?? false,
  options:
      (json['options'] as List<dynamic>?)
          ?.map((e) => ModifierOptionDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ModifierOptionDto>[],
);

Map<String, dynamic> _$$ModifierGroupDtoImplToJson(
  _$ModifierGroupDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'required': instance.required,
  'multi': instance.multi,
  'options': instance.options,
};
