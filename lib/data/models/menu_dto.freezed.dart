// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MenuSnapshotDto _$MenuSnapshotDtoFromJson(Map<String, dynamic> json) {
  return _MenuSnapshotDto.fromJson(json);
}

/// @nodoc
mixin _$MenuSnapshotDto {
  int get version => throw _privateConstructorUsedError;
  List<MenuCategoryDto> get categories => throw _privateConstructorUsedError;
  List<MenuItemDto> get items => throw _privateConstructorUsedError;
  List<MenuTagDto> get tags => throw _privateConstructorUsedError;

  /// Serializes this MenuSnapshotDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MenuSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuSnapshotDtoCopyWith<MenuSnapshotDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuSnapshotDtoCopyWith<$Res> {
  factory $MenuSnapshotDtoCopyWith(
    MenuSnapshotDto value,
    $Res Function(MenuSnapshotDto) then,
  ) = _$MenuSnapshotDtoCopyWithImpl<$Res, MenuSnapshotDto>;
  @useResult
  $Res call({
    int version,
    List<MenuCategoryDto> categories,
    List<MenuItemDto> items,
    List<MenuTagDto> tags,
  });
}

/// @nodoc
class _$MenuSnapshotDtoCopyWithImpl<$Res, $Val extends MenuSnapshotDto>
    implements $MenuSnapshotDtoCopyWith<$Res> {
  _$MenuSnapshotDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MenuSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? categories = null,
    Object? items = null,
    Object? tags = null,
  }) {
    return _then(
      _value.copyWith(
            version: null == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as int,
            categories: null == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as List<MenuCategoryDto>,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<MenuItemDto>,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<MenuTagDto>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MenuSnapshotDtoImplCopyWith<$Res>
    implements $MenuSnapshotDtoCopyWith<$Res> {
  factory _$$MenuSnapshotDtoImplCopyWith(
    _$MenuSnapshotDtoImpl value,
    $Res Function(_$MenuSnapshotDtoImpl) then,
  ) = __$$MenuSnapshotDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int version,
    List<MenuCategoryDto> categories,
    List<MenuItemDto> items,
    List<MenuTagDto> tags,
  });
}

/// @nodoc
class __$$MenuSnapshotDtoImplCopyWithImpl<$Res>
    extends _$MenuSnapshotDtoCopyWithImpl<$Res, _$MenuSnapshotDtoImpl>
    implements _$$MenuSnapshotDtoImplCopyWith<$Res> {
  __$$MenuSnapshotDtoImplCopyWithImpl(
    _$MenuSnapshotDtoImpl _value,
    $Res Function(_$MenuSnapshotDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MenuSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? categories = null,
    Object? items = null,
    Object? tags = null,
  }) {
    return _then(
      _$MenuSnapshotDtoImpl(
        version: null == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as int,
        categories: null == categories
            ? _value._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as List<MenuCategoryDto>,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<MenuItemDto>,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<MenuTagDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuSnapshotDtoImpl implements _MenuSnapshotDto {
  const _$MenuSnapshotDtoImpl({
    required this.version,
    required final List<MenuCategoryDto> categories,
    required final List<MenuItemDto> items,
    final List<MenuTagDto> tags = const <MenuTagDto>[],
  }) : _categories = categories,
       _items = items,
       _tags = tags;

  factory _$MenuSnapshotDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuSnapshotDtoImplFromJson(json);

  @override
  final int version;
  final List<MenuCategoryDto> _categories;
  @override
  List<MenuCategoryDto> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  final List<MenuItemDto> _items;
  @override
  List<MenuItemDto> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final List<MenuTagDto> _tags;
  @override
  @JsonKey()
  List<MenuTagDto> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'MenuSnapshotDto(version: $version, categories: $categories, items: $items, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuSnapshotDtoImpl &&
            (identical(other.version, version) || other.version == version) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    version,
    const DeepCollectionEquality().hash(_categories),
    const DeepCollectionEquality().hash(_items),
    const DeepCollectionEquality().hash(_tags),
  );

  /// Create a copy of MenuSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuSnapshotDtoImplCopyWith<_$MenuSnapshotDtoImpl> get copyWith =>
      __$$MenuSnapshotDtoImplCopyWithImpl<_$MenuSnapshotDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuSnapshotDtoImplToJson(this);
  }
}

abstract class _MenuSnapshotDto implements MenuSnapshotDto {
  const factory _MenuSnapshotDto({
    required final int version,
    required final List<MenuCategoryDto> categories,
    required final List<MenuItemDto> items,
    final List<MenuTagDto> tags,
  }) = _$MenuSnapshotDtoImpl;

  factory _MenuSnapshotDto.fromJson(Map<String, dynamic> json) =
      _$MenuSnapshotDtoImpl.fromJson;

  @override
  int get version;
  @override
  List<MenuCategoryDto> get categories;
  @override
  List<MenuItemDto> get items;
  @override
  List<MenuTagDto> get tags;

  /// Create a copy of MenuSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuSnapshotDtoImplCopyWith<_$MenuSnapshotDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MenuCategoryDto _$MenuCategoryDtoFromJson(Map<String, dynamic> json) {
  return _MenuCategoryDto.fromJson(json);
}

/// @nodoc
mixin _$MenuCategoryDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this MenuCategoryDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MenuCategoryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuCategoryDtoCopyWith<MenuCategoryDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuCategoryDtoCopyWith<$Res> {
  factory $MenuCategoryDtoCopyWith(
    MenuCategoryDto value,
    $Res Function(MenuCategoryDto) then,
  ) = _$MenuCategoryDtoCopyWithImpl<$Res, MenuCategoryDto>;
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class _$MenuCategoryDtoCopyWithImpl<$Res, $Val extends MenuCategoryDto>
    implements $MenuCategoryDtoCopyWith<$Res> {
  _$MenuCategoryDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MenuCategoryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MenuCategoryDtoImplCopyWith<$Res>
    implements $MenuCategoryDtoCopyWith<$Res> {
  factory _$$MenuCategoryDtoImplCopyWith(
    _$MenuCategoryDtoImpl value,
    $Res Function(_$MenuCategoryDtoImpl) then,
  ) = __$$MenuCategoryDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class __$$MenuCategoryDtoImplCopyWithImpl<$Res>
    extends _$MenuCategoryDtoCopyWithImpl<$Res, _$MenuCategoryDtoImpl>
    implements _$$MenuCategoryDtoImplCopyWith<$Res> {
  __$$MenuCategoryDtoImplCopyWithImpl(
    _$MenuCategoryDtoImpl _value,
    $Res Function(_$MenuCategoryDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MenuCategoryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null}) {
    return _then(
      _$MenuCategoryDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuCategoryDtoImpl implements _MenuCategoryDto {
  const _$MenuCategoryDtoImpl({required this.id, required this.name});

  factory _$MenuCategoryDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuCategoryDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  @override
  String toString() {
    return 'MenuCategoryDto(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuCategoryDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of MenuCategoryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuCategoryDtoImplCopyWith<_$MenuCategoryDtoImpl> get copyWith =>
      __$$MenuCategoryDtoImplCopyWithImpl<_$MenuCategoryDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuCategoryDtoImplToJson(this);
  }
}

abstract class _MenuCategoryDto implements MenuCategoryDto {
  const factory _MenuCategoryDto({
    required final String id,
    required final String name,
  }) = _$MenuCategoryDtoImpl;

  factory _MenuCategoryDto.fromJson(Map<String, dynamic> json) =
      _$MenuCategoryDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Create a copy of MenuCategoryDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuCategoryDtoImplCopyWith<_$MenuCategoryDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VariantDto _$VariantDtoFromJson(Map<String, dynamic> json) {
  return _VariantDto.fromJson(json);
}

/// @nodoc
mixin _$VariantDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get price => throw _privateConstructorUsedError;

  /// Serializes this VariantDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VariantDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VariantDtoCopyWith<VariantDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VariantDtoCopyWith<$Res> {
  factory $VariantDtoCopyWith(
    VariantDto value,
    $Res Function(VariantDto) then,
  ) = _$VariantDtoCopyWithImpl<$Res, VariantDto>;
  @useResult
  $Res call({String id, String name, int price});
}

/// @nodoc
class _$VariantDtoCopyWithImpl<$Res, $Val extends VariantDto>
    implements $VariantDtoCopyWith<$Res> {
  _$VariantDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VariantDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? price = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VariantDtoImplCopyWith<$Res>
    implements $VariantDtoCopyWith<$Res> {
  factory _$$VariantDtoImplCopyWith(
    _$VariantDtoImpl value,
    $Res Function(_$VariantDtoImpl) then,
  ) = __$$VariantDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, int price});
}

/// @nodoc
class __$$VariantDtoImplCopyWithImpl<$Res>
    extends _$VariantDtoCopyWithImpl<$Res, _$VariantDtoImpl>
    implements _$$VariantDtoImplCopyWith<$Res> {
  __$$VariantDtoImplCopyWithImpl(
    _$VariantDtoImpl _value,
    $Res Function(_$VariantDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VariantDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? price = null}) {
    return _then(
      _$VariantDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VariantDtoImpl implements _VariantDto {
  const _$VariantDtoImpl({
    required this.id,
    required this.name,
    required this.price,
  });

  factory _$VariantDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$VariantDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final int price;

  @override
  String toString() {
    return 'VariantDto(id: $id, name: $name, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VariantDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, price);

  /// Create a copy of VariantDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VariantDtoImplCopyWith<_$VariantDtoImpl> get copyWith =>
      __$$VariantDtoImplCopyWithImpl<_$VariantDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VariantDtoImplToJson(this);
  }
}

abstract class _VariantDto implements VariantDto {
  const factory _VariantDto({
    required final String id,
    required final String name,
    required final int price,
  }) = _$VariantDtoImpl;

  factory _VariantDto.fromJson(Map<String, dynamic> json) =
      _$VariantDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get price;

  /// Create a copy of VariantDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VariantDtoImplCopyWith<_$VariantDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MenuItemDto _$MenuItemDtoFromJson(Map<String, dynamic> json) {
  return _MenuItemDto.fromJson(json);
}

/// @nodoc
mixin _$MenuItemDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get basePrice => throw _privateConstructorUsedError;
  int get cost => throw _privateConstructorUsedError;

  /// Null = inherit the venue default (`prepTargetMins`). ADR-0043.
  int? get prepTime => throw _privateConstructorUsedError;
  List<VariantDto> get variants => throw _privateConstructorUsedError;
  List<ModifierGroupDto> get modifierGroups =>
      throw _privateConstructorUsedError;
  List<String> get allergens => throw _privateConstructorUsedError;
  List<String> get dietary => throw _privateConstructorUsedError;
  bool get unavailable => throw _privateConstructorUsedError;
  int get photoRev =>
      throw _privateConstructorUsedError; // Derived availability — computed server-side from ingredient stock and
  // never stored (ADR-0040). Replaces the former `stockCount` /
  // `autoSoldOutAtZero` pair, which v36 dropped.
  bool get autoSoldOut => throw _privateConstructorUsedError;
  List<String> get soldOutVariantIds => throw _privateConstructorUsedError;
  List<String> get soldOutOptionIds => throw _privateConstructorUsedError;

  /// Serializes this MenuItemDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MenuItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuItemDtoCopyWith<MenuItemDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuItemDtoCopyWith<$Res> {
  factory $MenuItemDtoCopyWith(
    MenuItemDto value,
    $Res Function(MenuItemDto) then,
  ) = _$MenuItemDtoCopyWithImpl<$Res, MenuItemDto>;
  @useResult
  $Res call({
    String id,
    String name,
    String categoryId,
    String description,
    int basePrice,
    int cost,
    int? prepTime,
    List<VariantDto> variants,
    List<ModifierGroupDto> modifierGroups,
    List<String> allergens,
    List<String> dietary,
    bool unavailable,
    int photoRev,
    bool autoSoldOut,
    List<String> soldOutVariantIds,
    List<String> soldOutOptionIds,
  });
}

/// @nodoc
class _$MenuItemDtoCopyWithImpl<$Res, $Val extends MenuItemDto>
    implements $MenuItemDtoCopyWith<$Res> {
  _$MenuItemDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MenuItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? categoryId = null,
    Object? description = null,
    Object? basePrice = null,
    Object? cost = null,
    Object? prepTime = freezed,
    Object? variants = null,
    Object? modifierGroups = null,
    Object? allergens = null,
    Object? dietary = null,
    Object? unavailable = null,
    Object? photoRev = null,
    Object? autoSoldOut = null,
    Object? soldOutVariantIds = null,
    Object? soldOutOptionIds = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            basePrice: null == basePrice
                ? _value.basePrice
                : basePrice // ignore: cast_nullable_to_non_nullable
                      as int,
            cost: null == cost
                ? _value.cost
                : cost // ignore: cast_nullable_to_non_nullable
                      as int,
            prepTime: freezed == prepTime
                ? _value.prepTime
                : prepTime // ignore: cast_nullable_to_non_nullable
                      as int?,
            variants: null == variants
                ? _value.variants
                : variants // ignore: cast_nullable_to_non_nullable
                      as List<VariantDto>,
            modifierGroups: null == modifierGroups
                ? _value.modifierGroups
                : modifierGroups // ignore: cast_nullable_to_non_nullable
                      as List<ModifierGroupDto>,
            allergens: null == allergens
                ? _value.allergens
                : allergens // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            dietary: null == dietary
                ? _value.dietary
                : dietary // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            unavailable: null == unavailable
                ? _value.unavailable
                : unavailable // ignore: cast_nullable_to_non_nullable
                      as bool,
            photoRev: null == photoRev
                ? _value.photoRev
                : photoRev // ignore: cast_nullable_to_non_nullable
                      as int,
            autoSoldOut: null == autoSoldOut
                ? _value.autoSoldOut
                : autoSoldOut // ignore: cast_nullable_to_non_nullable
                      as bool,
            soldOutVariantIds: null == soldOutVariantIds
                ? _value.soldOutVariantIds
                : soldOutVariantIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            soldOutOptionIds: null == soldOutOptionIds
                ? _value.soldOutOptionIds
                : soldOutOptionIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MenuItemDtoImplCopyWith<$Res>
    implements $MenuItemDtoCopyWith<$Res> {
  factory _$$MenuItemDtoImplCopyWith(
    _$MenuItemDtoImpl value,
    $Res Function(_$MenuItemDtoImpl) then,
  ) = __$$MenuItemDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String categoryId,
    String description,
    int basePrice,
    int cost,
    int? prepTime,
    List<VariantDto> variants,
    List<ModifierGroupDto> modifierGroups,
    List<String> allergens,
    List<String> dietary,
    bool unavailable,
    int photoRev,
    bool autoSoldOut,
    List<String> soldOutVariantIds,
    List<String> soldOutOptionIds,
  });
}

/// @nodoc
class __$$MenuItemDtoImplCopyWithImpl<$Res>
    extends _$MenuItemDtoCopyWithImpl<$Res, _$MenuItemDtoImpl>
    implements _$$MenuItemDtoImplCopyWith<$Res> {
  __$$MenuItemDtoImplCopyWithImpl(
    _$MenuItemDtoImpl _value,
    $Res Function(_$MenuItemDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MenuItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? categoryId = null,
    Object? description = null,
    Object? basePrice = null,
    Object? cost = null,
    Object? prepTime = freezed,
    Object? variants = null,
    Object? modifierGroups = null,
    Object? allergens = null,
    Object? dietary = null,
    Object? unavailable = null,
    Object? photoRev = null,
    Object? autoSoldOut = null,
    Object? soldOutVariantIds = null,
    Object? soldOutOptionIds = null,
  }) {
    return _then(
      _$MenuItemDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        basePrice: null == basePrice
            ? _value.basePrice
            : basePrice // ignore: cast_nullable_to_non_nullable
                  as int,
        cost: null == cost
            ? _value.cost
            : cost // ignore: cast_nullable_to_non_nullable
                  as int,
        prepTime: freezed == prepTime
            ? _value.prepTime
            : prepTime // ignore: cast_nullable_to_non_nullable
                  as int?,
        variants: null == variants
            ? _value._variants
            : variants // ignore: cast_nullable_to_non_nullable
                  as List<VariantDto>,
        modifierGroups: null == modifierGroups
            ? _value._modifierGroups
            : modifierGroups // ignore: cast_nullable_to_non_nullable
                  as List<ModifierGroupDto>,
        allergens: null == allergens
            ? _value._allergens
            : allergens // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        dietary: null == dietary
            ? _value._dietary
            : dietary // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        unavailable: null == unavailable
            ? _value.unavailable
            : unavailable // ignore: cast_nullable_to_non_nullable
                  as bool,
        photoRev: null == photoRev
            ? _value.photoRev
            : photoRev // ignore: cast_nullable_to_non_nullable
                  as int,
        autoSoldOut: null == autoSoldOut
            ? _value.autoSoldOut
            : autoSoldOut // ignore: cast_nullable_to_non_nullable
                  as bool,
        soldOutVariantIds: null == soldOutVariantIds
            ? _value._soldOutVariantIds
            : soldOutVariantIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        soldOutOptionIds: null == soldOutOptionIds
            ? _value._soldOutOptionIds
            : soldOutOptionIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuItemDtoImpl implements _MenuItemDto {
  const _$MenuItemDtoImpl({
    required this.id,
    required this.name,
    required this.categoryId,
    this.description = '',
    required this.basePrice,
    this.cost = 0,
    this.prepTime,
    final List<VariantDto> variants = const <VariantDto>[],
    final List<ModifierGroupDto> modifierGroups = const <ModifierGroupDto>[],
    final List<String> allergens = const <String>[],
    final List<String> dietary = const <String>[],
    this.unavailable = false,
    this.photoRev = 0,
    this.autoSoldOut = false,
    final List<String> soldOutVariantIds = const <String>[],
    final List<String> soldOutOptionIds = const <String>[],
  }) : _variants = variants,
       _modifierGroups = modifierGroups,
       _allergens = allergens,
       _dietary = dietary,
       _soldOutVariantIds = soldOutVariantIds,
       _soldOutOptionIds = soldOutOptionIds;

  factory _$MenuItemDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuItemDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String categoryId;
  @override
  @JsonKey()
  final String description;
  @override
  final int basePrice;
  @override
  @JsonKey()
  final int cost;

  /// Null = inherit the venue default (`prepTargetMins`). ADR-0043.
  @override
  final int? prepTime;
  final List<VariantDto> _variants;
  @override
  @JsonKey()
  List<VariantDto> get variants {
    if (_variants is EqualUnmodifiableListView) return _variants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_variants);
  }

  final List<ModifierGroupDto> _modifierGroups;
  @override
  @JsonKey()
  List<ModifierGroupDto> get modifierGroups {
    if (_modifierGroups is EqualUnmodifiableListView) return _modifierGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifierGroups);
  }

  final List<String> _allergens;
  @override
  @JsonKey()
  List<String> get allergens {
    if (_allergens is EqualUnmodifiableListView) return _allergens;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allergens);
  }

  final List<String> _dietary;
  @override
  @JsonKey()
  List<String> get dietary {
    if (_dietary is EqualUnmodifiableListView) return _dietary;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dietary);
  }

  @override
  @JsonKey()
  final bool unavailable;
  @override
  @JsonKey()
  final int photoRev;
  // Derived availability — computed server-side from ingredient stock and
  // never stored (ADR-0040). Replaces the former `stockCount` /
  // `autoSoldOutAtZero` pair, which v36 dropped.
  @override
  @JsonKey()
  final bool autoSoldOut;
  final List<String> _soldOutVariantIds;
  @override
  @JsonKey()
  List<String> get soldOutVariantIds {
    if (_soldOutVariantIds is EqualUnmodifiableListView)
      return _soldOutVariantIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_soldOutVariantIds);
  }

  final List<String> _soldOutOptionIds;
  @override
  @JsonKey()
  List<String> get soldOutOptionIds {
    if (_soldOutOptionIds is EqualUnmodifiableListView)
      return _soldOutOptionIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_soldOutOptionIds);
  }

  @override
  String toString() {
    return 'MenuItemDto(id: $id, name: $name, categoryId: $categoryId, description: $description, basePrice: $basePrice, cost: $cost, prepTime: $prepTime, variants: $variants, modifierGroups: $modifierGroups, allergens: $allergens, dietary: $dietary, unavailable: $unavailable, photoRev: $photoRev, autoSoldOut: $autoSoldOut, soldOutVariantIds: $soldOutVariantIds, soldOutOptionIds: $soldOutOptionIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuItemDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.basePrice, basePrice) ||
                other.basePrice == basePrice) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.prepTime, prepTime) ||
                other.prepTime == prepTime) &&
            const DeepCollectionEquality().equals(other._variants, _variants) &&
            const DeepCollectionEquality().equals(
              other._modifierGroups,
              _modifierGroups,
            ) &&
            const DeepCollectionEquality().equals(
              other._allergens,
              _allergens,
            ) &&
            const DeepCollectionEquality().equals(other._dietary, _dietary) &&
            (identical(other.unavailable, unavailable) ||
                other.unavailable == unavailable) &&
            (identical(other.photoRev, photoRev) ||
                other.photoRev == photoRev) &&
            (identical(other.autoSoldOut, autoSoldOut) ||
                other.autoSoldOut == autoSoldOut) &&
            const DeepCollectionEquality().equals(
              other._soldOutVariantIds,
              _soldOutVariantIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._soldOutOptionIds,
              _soldOutOptionIds,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    categoryId,
    description,
    basePrice,
    cost,
    prepTime,
    const DeepCollectionEquality().hash(_variants),
    const DeepCollectionEquality().hash(_modifierGroups),
    const DeepCollectionEquality().hash(_allergens),
    const DeepCollectionEquality().hash(_dietary),
    unavailable,
    photoRev,
    autoSoldOut,
    const DeepCollectionEquality().hash(_soldOutVariantIds),
    const DeepCollectionEquality().hash(_soldOutOptionIds),
  );

  /// Create a copy of MenuItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuItemDtoImplCopyWith<_$MenuItemDtoImpl> get copyWith =>
      __$$MenuItemDtoImplCopyWithImpl<_$MenuItemDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuItemDtoImplToJson(this);
  }
}

abstract class _MenuItemDto implements MenuItemDto {
  const factory _MenuItemDto({
    required final String id,
    required final String name,
    required final String categoryId,
    final String description,
    required final int basePrice,
    final int cost,
    final int? prepTime,
    final List<VariantDto> variants,
    final List<ModifierGroupDto> modifierGroups,
    final List<String> allergens,
    final List<String> dietary,
    final bool unavailable,
    final int photoRev,
    final bool autoSoldOut,
    final List<String> soldOutVariantIds,
    final List<String> soldOutOptionIds,
  }) = _$MenuItemDtoImpl;

  factory _MenuItemDto.fromJson(Map<String, dynamic> json) =
      _$MenuItemDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get categoryId;
  @override
  String get description;
  @override
  int get basePrice;
  @override
  int get cost;

  /// Null = inherit the venue default (`prepTargetMins`). ADR-0043.
  @override
  int? get prepTime;
  @override
  List<VariantDto> get variants;
  @override
  List<ModifierGroupDto> get modifierGroups;
  @override
  List<String> get allergens;
  @override
  List<String> get dietary;
  @override
  bool get unavailable;
  @override
  int get photoRev; // Derived availability — computed server-side from ingredient stock and
  // never stored (ADR-0040). Replaces the former `stockCount` /
  // `autoSoldOutAtZero` pair, which v36 dropped.
  @override
  bool get autoSoldOut;
  @override
  List<String> get soldOutVariantIds;
  @override
  List<String> get soldOutOptionIds;

  /// Create a copy of MenuItemDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuItemDtoImplCopyWith<_$MenuItemDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MenuTagDto _$MenuTagDtoFromJson(Map<String, dynamic> json) {
  return _MenuTagDto.fromJson(json);
}

/// @nodoc
mixin _$MenuTagDto {
  String get id => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this MenuTagDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MenuTagDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuTagDtoCopyWith<MenuTagDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuTagDtoCopyWith<$Res> {
  factory $MenuTagDtoCopyWith(
    MenuTagDto value,
    $Res Function(MenuTagDto) then,
  ) = _$MenuTagDtoCopyWithImpl<$Res, MenuTagDto>;
  @useResult
  $Res call({String id, String kind, String name, String code, int sortOrder});
}

/// @nodoc
class _$MenuTagDtoCopyWithImpl<$Res, $Val extends MenuTagDto>
    implements $MenuTagDtoCopyWith<$Res> {
  _$MenuTagDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MenuTagDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? name = null,
    Object? code = null,
    Object? sortOrder = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MenuTagDtoImplCopyWith<$Res>
    implements $MenuTagDtoCopyWith<$Res> {
  factory _$$MenuTagDtoImplCopyWith(
    _$MenuTagDtoImpl value,
    $Res Function(_$MenuTagDtoImpl) then,
  ) = __$$MenuTagDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String kind, String name, String code, int sortOrder});
}

/// @nodoc
class __$$MenuTagDtoImplCopyWithImpl<$Res>
    extends _$MenuTagDtoCopyWithImpl<$Res, _$MenuTagDtoImpl>
    implements _$$MenuTagDtoImplCopyWith<$Res> {
  __$$MenuTagDtoImplCopyWithImpl(
    _$MenuTagDtoImpl _value,
    $Res Function(_$MenuTagDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MenuTagDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? name = null,
    Object? code = null,
    Object? sortOrder = null,
  }) {
    return _then(
      _$MenuTagDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuTagDtoImpl implements _MenuTagDto {
  const _$MenuTagDtoImpl({
    required this.id,
    required this.kind,
    required this.name,
    this.code = '',
    this.sortOrder = 0,
  });

  factory _$MenuTagDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuTagDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String kind;
  @override
  final String name;
  @override
  @JsonKey()
  final String code;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'MenuTagDto(id: $id, kind: $kind, name: $name, code: $code, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuTagDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, kind, name, code, sortOrder);

  /// Create a copy of MenuTagDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuTagDtoImplCopyWith<_$MenuTagDtoImpl> get copyWith =>
      __$$MenuTagDtoImplCopyWithImpl<_$MenuTagDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuTagDtoImplToJson(this);
  }
}

abstract class _MenuTagDto implements MenuTagDto {
  const factory _MenuTagDto({
    required final String id,
    required final String kind,
    required final String name,
    final String code,
    final int sortOrder,
  }) = _$MenuTagDtoImpl;

  factory _MenuTagDto.fromJson(Map<String, dynamic> json) =
      _$MenuTagDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get kind;
  @override
  String get name;
  @override
  String get code;
  @override
  int get sortOrder;

  /// Create a copy of MenuTagDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuTagDtoImplCopyWith<_$MenuTagDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModifierOptionDto _$ModifierOptionDtoFromJson(Map<String, dynamic> json) {
  return _ModifierOptionDto.fromJson(json);
}

/// @nodoc
mixin _$ModifierOptionDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get priceDelta => throw _privateConstructorUsedError;

  /// Serializes this ModifierOptionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModifierOptionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModifierOptionDtoCopyWith<ModifierOptionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModifierOptionDtoCopyWith<$Res> {
  factory $ModifierOptionDtoCopyWith(
    ModifierOptionDto value,
    $Res Function(ModifierOptionDto) then,
  ) = _$ModifierOptionDtoCopyWithImpl<$Res, ModifierOptionDto>;
  @useResult
  $Res call({String id, String name, int priceDelta});
}

/// @nodoc
class _$ModifierOptionDtoCopyWithImpl<$Res, $Val extends ModifierOptionDto>
    implements $ModifierOptionDtoCopyWith<$Res> {
  _$ModifierOptionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModifierOptionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? priceDelta = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            priceDelta: null == priceDelta
                ? _value.priceDelta
                : priceDelta // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ModifierOptionDtoImplCopyWith<$Res>
    implements $ModifierOptionDtoCopyWith<$Res> {
  factory _$$ModifierOptionDtoImplCopyWith(
    _$ModifierOptionDtoImpl value,
    $Res Function(_$ModifierOptionDtoImpl) then,
  ) = __$$ModifierOptionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, int priceDelta});
}

/// @nodoc
class __$$ModifierOptionDtoImplCopyWithImpl<$Res>
    extends _$ModifierOptionDtoCopyWithImpl<$Res, _$ModifierOptionDtoImpl>
    implements _$$ModifierOptionDtoImplCopyWith<$Res> {
  __$$ModifierOptionDtoImplCopyWithImpl(
    _$ModifierOptionDtoImpl _value,
    $Res Function(_$ModifierOptionDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ModifierOptionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? priceDelta = null,
  }) {
    return _then(
      _$ModifierOptionDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        priceDelta: null == priceDelta
            ? _value.priceDelta
            : priceDelta // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ModifierOptionDtoImpl implements _ModifierOptionDto {
  const _$ModifierOptionDtoImpl({
    required this.id,
    required this.name,
    this.priceDelta = 0,
  });

  factory _$ModifierOptionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModifierOptionDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final int priceDelta;

  @override
  String toString() {
    return 'ModifierOptionDto(id: $id, name: $name, priceDelta: $priceDelta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModifierOptionDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.priceDelta, priceDelta) ||
                other.priceDelta == priceDelta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, priceDelta);

  /// Create a copy of ModifierOptionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModifierOptionDtoImplCopyWith<_$ModifierOptionDtoImpl> get copyWith =>
      __$$ModifierOptionDtoImplCopyWithImpl<_$ModifierOptionDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ModifierOptionDtoImplToJson(this);
  }
}

abstract class _ModifierOptionDto implements ModifierOptionDto {
  const factory _ModifierOptionDto({
    required final String id,
    required final String name,
    final int priceDelta,
  }) = _$ModifierOptionDtoImpl;

  factory _ModifierOptionDto.fromJson(Map<String, dynamic> json) =
      _$ModifierOptionDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get priceDelta;

  /// Create a copy of ModifierOptionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModifierOptionDtoImplCopyWith<_$ModifierOptionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModifierGroupDto _$ModifierGroupDtoFromJson(Map<String, dynamic> json) {
  return _ModifierGroupDto.fromJson(json);
}

/// @nodoc
mixin _$ModifierGroupDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get required => throw _privateConstructorUsedError;
  bool get multi => throw _privateConstructorUsedError;
  List<ModifierOptionDto> get options => throw _privateConstructorUsedError;

  /// Serializes this ModifierGroupDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModifierGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModifierGroupDtoCopyWith<ModifierGroupDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModifierGroupDtoCopyWith<$Res> {
  factory $ModifierGroupDtoCopyWith(
    ModifierGroupDto value,
    $Res Function(ModifierGroupDto) then,
  ) = _$ModifierGroupDtoCopyWithImpl<$Res, ModifierGroupDto>;
  @useResult
  $Res call({
    String id,
    String name,
    bool required,
    bool multi,
    List<ModifierOptionDto> options,
  });
}

/// @nodoc
class _$ModifierGroupDtoCopyWithImpl<$Res, $Val extends ModifierGroupDto>
    implements $ModifierGroupDtoCopyWith<$Res> {
  _$ModifierGroupDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModifierGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? required = null,
    Object? multi = null,
    Object? options = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            required: null == required
                ? _value.required
                : required // ignore: cast_nullable_to_non_nullable
                      as bool,
            multi: null == multi
                ? _value.multi
                : multi // ignore: cast_nullable_to_non_nullable
                      as bool,
            options: null == options
                ? _value.options
                : options // ignore: cast_nullable_to_non_nullable
                      as List<ModifierOptionDto>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ModifierGroupDtoImplCopyWith<$Res>
    implements $ModifierGroupDtoCopyWith<$Res> {
  factory _$$ModifierGroupDtoImplCopyWith(
    _$ModifierGroupDtoImpl value,
    $Res Function(_$ModifierGroupDtoImpl) then,
  ) = __$$ModifierGroupDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    bool required,
    bool multi,
    List<ModifierOptionDto> options,
  });
}

/// @nodoc
class __$$ModifierGroupDtoImplCopyWithImpl<$Res>
    extends _$ModifierGroupDtoCopyWithImpl<$Res, _$ModifierGroupDtoImpl>
    implements _$$ModifierGroupDtoImplCopyWith<$Res> {
  __$$ModifierGroupDtoImplCopyWithImpl(
    _$ModifierGroupDtoImpl _value,
    $Res Function(_$ModifierGroupDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ModifierGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? required = null,
    Object? multi = null,
    Object? options = null,
  }) {
    return _then(
      _$ModifierGroupDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        required: null == required
            ? _value.required
            : required // ignore: cast_nullable_to_non_nullable
                  as bool,
        multi: null == multi
            ? _value.multi
            : multi // ignore: cast_nullable_to_non_nullable
                  as bool,
        options: null == options
            ? _value._options
            : options // ignore: cast_nullable_to_non_nullable
                  as List<ModifierOptionDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ModifierGroupDtoImpl implements _ModifierGroupDto {
  const _$ModifierGroupDtoImpl({
    required this.id,
    required this.name,
    this.required = false,
    this.multi = false,
    final List<ModifierOptionDto> options = const <ModifierOptionDto>[],
  }) : _options = options;

  factory _$ModifierGroupDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModifierGroupDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final bool required;
  @override
  @JsonKey()
  final bool multi;
  final List<ModifierOptionDto> _options;
  @override
  @JsonKey()
  List<ModifierOptionDto> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  @override
  String toString() {
    return 'ModifierGroupDto(id: $id, name: $name, required: $required, multi: $multi, options: $options)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModifierGroupDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.required, required) ||
                other.required == required) &&
            (identical(other.multi, multi) || other.multi == multi) &&
            const DeepCollectionEquality().equals(other._options, _options));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    required,
    multi,
    const DeepCollectionEquality().hash(_options),
  );

  /// Create a copy of ModifierGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModifierGroupDtoImplCopyWith<_$ModifierGroupDtoImpl> get copyWith =>
      __$$ModifierGroupDtoImplCopyWithImpl<_$ModifierGroupDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ModifierGroupDtoImplToJson(this);
  }
}

abstract class _ModifierGroupDto implements ModifierGroupDto {
  const factory _ModifierGroupDto({
    required final String id,
    required final String name,
    final bool required,
    final bool multi,
    final List<ModifierOptionDto> options,
  }) = _$ModifierGroupDtoImpl;

  factory _ModifierGroupDto.fromJson(Map<String, dynamic> json) =
      _$ModifierGroupDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get required;
  @override
  bool get multi;
  @override
  List<ModifierOptionDto> get options;

  /// Create a copy of ModifierGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModifierGroupDtoImplCopyWith<_$ModifierGroupDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
