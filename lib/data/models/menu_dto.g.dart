// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MenuSnapshotDto _$MenuSnapshotDtoFromJson(Map<String, dynamic> json) =>
    _MenuSnapshotDto(
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

Map<String, dynamic> _$MenuSnapshotDtoToJson(_MenuSnapshotDto instance) =>
    <String, dynamic>{
      'version': instance.version,
      'categories': instance.categories,
      'items': instance.items,
      'tags': instance.tags,
    };

_MenuCategoryDto _$MenuCategoryDtoFromJson(Map<String, dynamic> json) =>
    _MenuCategoryDto(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$MenuCategoryDtoToJson(_MenuCategoryDto instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_VariantDto _$VariantDtoFromJson(Map<String, dynamic> json) => _VariantDto(
  id: json['id'] as String,
  name: json['name'] as String,
  price: (json['price'] as num).toInt(),
);

Map<String, dynamic> _$VariantDtoToJson(_VariantDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
    };

_MenuItemDto _$MenuItemDtoFromJson(Map<String, dynamic> json) => _MenuItemDto(
  id: json['id'] as String,
  name: json['name'] as String,
  categoryId: json['categoryId'] as String,
  description: json['description'] as String? ?? '',
  basePrice: (json['basePrice'] as num).toInt(),
  cost: (json['cost'] as num?)?.toInt() ?? 0,
  prepTime: (json['prepTime'] as num?)?.toInt(),
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
  autoSoldOut: json['autoSoldOut'] as bool? ?? false,
  soldOutVariantIds:
      (json['soldOutVariantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  soldOutOptionIds:
      (json['soldOutOptionIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$MenuItemDtoToJson(_MenuItemDto instance) =>
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
      'autoSoldOut': instance.autoSoldOut,
      'soldOutVariantIds': instance.soldOutVariantIds,
      'soldOutOptionIds': instance.soldOutOptionIds,
    };

_MenuTagDto _$MenuTagDtoFromJson(Map<String, dynamic> json) => _MenuTagDto(
  id: json['id'] as String,
  kind: json['kind'] as String,
  name: json['name'] as String,
  code: json['code'] as String? ?? '',
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$MenuTagDtoToJson(_MenuTagDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'name': instance.name,
      'code': instance.code,
      'sortOrder': instance.sortOrder,
    };

_ModifierOptionDto _$ModifierOptionDtoFromJson(Map<String, dynamic> json) =>
    _ModifierOptionDto(
      id: json['id'] as String,
      name: json['name'] as String,
      priceDelta: (json['priceDelta'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ModifierOptionDtoToJson(_ModifierOptionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'priceDelta': instance.priceDelta,
    };

_ModifierGroupDto _$ModifierGroupDtoFromJson(Map<String, dynamic> json) =>
    _ModifierGroupDto(
      id: json['id'] as String,
      name: json['name'] as String,
      required: json['required'] as bool? ?? false,
      multi: json['multi'] as bool? ?? false,
      options:
          (json['options'] as List<dynamic>?)
              ?.map(
                (e) => ModifierOptionDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ModifierOptionDto>[],
    );

Map<String, dynamic> _$ModifierGroupDtoToJson(_ModifierGroupDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'required': instance.required,
      'multi': instance.multi,
      'options': instance.options,
    };
