import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_dto.freezed.dart';
part 'menu_dto.g.dart';

@freezed
class MenuSnapshotDto with _$MenuSnapshotDto {
  const factory MenuSnapshotDto({
    required int version,
    required List<MenuCategoryDto> categories,
    required List<MenuItemDto> items,
  }) = _MenuSnapshotDto;

  factory MenuSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$MenuSnapshotDtoFromJson(json);
}

@freezed
class MenuCategoryDto with _$MenuCategoryDto {
  const factory MenuCategoryDto({
    required String id,
    required String name,
  }) = _MenuCategoryDto;

  factory MenuCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$MenuCategoryDtoFromJson(json);
}

@freezed
class VariantDto with _$VariantDto {
  const factory VariantDto({
    required String id,
    required String name,
    required int price,
  }) = _VariantDto;

  factory VariantDto.fromJson(Map<String, dynamic> json) =>
      _$VariantDtoFromJson(json);
}

@freezed
class MenuItemDto with _$MenuItemDto {
  const factory MenuItemDto({
    required String id,
    required String name,
    required String categoryId,
    @Default('') String description,
    required int basePrice,
    @Default(0) int cost,
    @Default(5) int prepTime,
    @Default(<VariantDto>[]) List<VariantDto> variants,
    @Default(<ModifierGroupDto>[]) List<ModifierGroupDto> modifierGroups,
    @Default(<String>[]) List<String> allergens,
    @Default(<String>[]) List<String> dietary,
    @Default(false) bool unavailable,
    int? stockCount,
    @Default(false) bool autoEightySixAtZero,
  }) = _MenuItemDto;

  factory MenuItemDto.fromJson(Map<String, dynamic> json) =>
      _$MenuItemDtoFromJson(json);
}

@freezed
class ModifierOptionDto with _$ModifierOptionDto {
  const factory ModifierOptionDto({
    required String id,
    required String name,
    @Default(0) int priceDelta,
  }) = _ModifierOptionDto;

  factory ModifierOptionDto.fromJson(Map<String, dynamic> json) =>
      _$ModifierOptionDtoFromJson(json);
}

@freezed
class ModifierGroupDto with _$ModifierGroupDto {
  const factory ModifierGroupDto({
    required String id,
    required String name,
    @Default(false) bool required,
    @Default(false) bool multi,
    @Default(<ModifierOptionDto>[]) List<ModifierOptionDto> options,
  }) = _ModifierGroupDto;

  factory ModifierGroupDto.fromJson(Map<String, dynamic> json) =>
      _$ModifierGroupDtoFromJson(json);
}
