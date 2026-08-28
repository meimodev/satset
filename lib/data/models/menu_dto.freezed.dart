// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MenuSnapshotDto {

 int get version; List<MenuCategoryDto> get categories; List<MenuItemDto> get items; List<MenuTagDto> get tags;
/// Create a copy of MenuSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuSnapshotDtoCopyWith<MenuSnapshotDto> get copyWith => _$MenuSnapshotDtoCopyWithImpl<MenuSnapshotDto>(this as MenuSnapshotDto, _$identity);

  /// Serializes this MenuSnapshotDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuSnapshotDto&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.tags, tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'MenuSnapshotDto(version: $version, categories: $categories, items: $items, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $MenuSnapshotDtoCopyWith<$Res>  {
  factory $MenuSnapshotDtoCopyWith(MenuSnapshotDto value, $Res Function(MenuSnapshotDto) _then) = _$MenuSnapshotDtoCopyWithImpl;
@useResult
$Res call({
 int version, List<MenuCategoryDto> categories, List<MenuItemDto> items, List<MenuTagDto> tags
});




}
/// @nodoc
class _$MenuSnapshotDtoCopyWithImpl<$Res>
    implements $MenuSnapshotDtoCopyWith<$Res> {
  _$MenuSnapshotDtoCopyWithImpl(this._self, this._then);

  final MenuSnapshotDto _self;
  final $Res Function(MenuSnapshotDto) _then;

/// Create a copy of MenuSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? categories = null,Object? items = null,Object? tags = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<MenuCategoryDto>,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MenuItemDto>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<MenuTagDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuSnapshotDto].
extension MenuSnapshotDtoPatterns on MenuSnapshotDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuSnapshotDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuSnapshotDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuSnapshotDto value)  $default,){
final _that = this;
switch (_that) {
case _MenuSnapshotDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuSnapshotDto value)?  $default,){
final _that = this;
switch (_that) {
case _MenuSnapshotDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  List<MenuCategoryDto> categories,  List<MenuItemDto> items,  List<MenuTagDto> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuSnapshotDto() when $default != null:
return $default(_that.version,_that.categories,_that.items,_that.tags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  List<MenuCategoryDto> categories,  List<MenuItemDto> items,  List<MenuTagDto> tags)  $default,) {final _that = this;
switch (_that) {
case _MenuSnapshotDto():
return $default(_that.version,_that.categories,_that.items,_that.tags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  List<MenuCategoryDto> categories,  List<MenuItemDto> items,  List<MenuTagDto> tags)?  $default,) {final _that = this;
switch (_that) {
case _MenuSnapshotDto() when $default != null:
return $default(_that.version,_that.categories,_that.items,_that.tags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuSnapshotDto implements MenuSnapshotDto {
  const _MenuSnapshotDto({required this.version, required final  List<MenuCategoryDto> categories, required final  List<MenuItemDto> items, final  List<MenuTagDto> tags = const <MenuTagDto>[]}): _categories = categories,_items = items,_tags = tags;
  factory _MenuSnapshotDto.fromJson(Map<String, dynamic> json) => _$MenuSnapshotDtoFromJson(json);

@override final  int version;
 final  List<MenuCategoryDto> _categories;
@override List<MenuCategoryDto> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<MenuItemDto> _items;
@override List<MenuItemDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  List<MenuTagDto> _tags;
@override@JsonKey() List<MenuTagDto> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of MenuSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuSnapshotDtoCopyWith<_MenuSnapshotDto> get copyWith => __$MenuSnapshotDtoCopyWithImpl<_MenuSnapshotDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuSnapshotDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuSnapshotDto&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._tags, _tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'MenuSnapshotDto(version: $version, categories: $categories, items: $items, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$MenuSnapshotDtoCopyWith<$Res> implements $MenuSnapshotDtoCopyWith<$Res> {
  factory _$MenuSnapshotDtoCopyWith(_MenuSnapshotDto value, $Res Function(_MenuSnapshotDto) _then) = __$MenuSnapshotDtoCopyWithImpl;
@override @useResult
$Res call({
 int version, List<MenuCategoryDto> categories, List<MenuItemDto> items, List<MenuTagDto> tags
});




}
/// @nodoc
class __$MenuSnapshotDtoCopyWithImpl<$Res>
    implements _$MenuSnapshotDtoCopyWith<$Res> {
  __$MenuSnapshotDtoCopyWithImpl(this._self, this._then);

  final _MenuSnapshotDto _self;
  final $Res Function(_MenuSnapshotDto) _then;

/// Create a copy of MenuSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? categories = null,Object? items = null,Object? tags = null,}) {
  return _then(_MenuSnapshotDto(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<MenuCategoryDto>,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MenuItemDto>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<MenuTagDto>,
  ));
}


}


/// @nodoc
mixin _$MenuCategoryDto {

 String get id; String get name;
/// Create a copy of MenuCategoryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuCategoryDtoCopyWith<MenuCategoryDto> get copyWith => _$MenuCategoryDtoCopyWithImpl<MenuCategoryDto>(this as MenuCategoryDto, _$identity);

  /// Serializes this MenuCategoryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuCategoryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'MenuCategoryDto(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $MenuCategoryDtoCopyWith<$Res>  {
  factory $MenuCategoryDtoCopyWith(MenuCategoryDto value, $Res Function(MenuCategoryDto) _then) = _$MenuCategoryDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$MenuCategoryDtoCopyWithImpl<$Res>
    implements $MenuCategoryDtoCopyWith<$Res> {
  _$MenuCategoryDtoCopyWithImpl(this._self, this._then);

  final MenuCategoryDto _self;
  final $Res Function(MenuCategoryDto) _then;

/// Create a copy of MenuCategoryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuCategoryDto].
extension MenuCategoryDtoPatterns on MenuCategoryDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuCategoryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuCategoryDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuCategoryDto value)  $default,){
final _that = this;
switch (_that) {
case _MenuCategoryDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuCategoryDto value)?  $default,){
final _that = this;
switch (_that) {
case _MenuCategoryDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuCategoryDto() when $default != null:
return $default(_that.id,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _MenuCategoryDto():
return $default(_that.id,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _MenuCategoryDto() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuCategoryDto implements MenuCategoryDto {
  const _MenuCategoryDto({required this.id, required this.name});
  factory _MenuCategoryDto.fromJson(Map<String, dynamic> json) => _$MenuCategoryDtoFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of MenuCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuCategoryDtoCopyWith<_MenuCategoryDto> get copyWith => __$MenuCategoryDtoCopyWithImpl<_MenuCategoryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuCategoryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuCategoryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'MenuCategoryDto(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$MenuCategoryDtoCopyWith<$Res> implements $MenuCategoryDtoCopyWith<$Res> {
  factory _$MenuCategoryDtoCopyWith(_MenuCategoryDto value, $Res Function(_MenuCategoryDto) _then) = __$MenuCategoryDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$MenuCategoryDtoCopyWithImpl<$Res>
    implements _$MenuCategoryDtoCopyWith<$Res> {
  __$MenuCategoryDtoCopyWithImpl(this._self, this._then);

  final _MenuCategoryDto _self;
  final $Res Function(_MenuCategoryDto) _then;

/// Create a copy of MenuCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_MenuCategoryDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$VariantDto {

 String get id; String get name; int get price;
/// Create a copy of VariantDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VariantDtoCopyWith<VariantDto> get copyWith => _$VariantDtoCopyWithImpl<VariantDto>(this as VariantDto, _$identity);

  /// Serializes this VariantDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VariantDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,price);

@override
String toString() {
  return 'VariantDto(id: $id, name: $name, price: $price)';
}


}

/// @nodoc
abstract mixin class $VariantDtoCopyWith<$Res>  {
  factory $VariantDtoCopyWith(VariantDto value, $Res Function(VariantDto) _then) = _$VariantDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, int price
});




}
/// @nodoc
class _$VariantDtoCopyWithImpl<$Res>
    implements $VariantDtoCopyWith<$Res> {
  _$VariantDtoCopyWithImpl(this._self, this._then);

  final VariantDto _self;
  final $Res Function(VariantDto) _then;

/// Create a copy of VariantDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? price = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VariantDto].
extension VariantDtoPatterns on VariantDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VariantDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VariantDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VariantDto value)  $default,){
final _that = this;
switch (_that) {
case _VariantDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VariantDto value)?  $default,){
final _that = this;
switch (_that) {
case _VariantDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int price)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VariantDto() when $default != null:
return $default(_that.id,_that.name,_that.price);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int price)  $default,) {final _that = this;
switch (_that) {
case _VariantDto():
return $default(_that.id,_that.name,_that.price);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int price)?  $default,) {final _that = this;
switch (_that) {
case _VariantDto() when $default != null:
return $default(_that.id,_that.name,_that.price);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VariantDto implements VariantDto {
  const _VariantDto({required this.id, required this.name, required this.price});
  factory _VariantDto.fromJson(Map<String, dynamic> json) => _$VariantDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  int price;

/// Create a copy of VariantDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VariantDtoCopyWith<_VariantDto> get copyWith => __$VariantDtoCopyWithImpl<_VariantDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VariantDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VariantDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,price);

@override
String toString() {
  return 'VariantDto(id: $id, name: $name, price: $price)';
}


}

/// @nodoc
abstract mixin class _$VariantDtoCopyWith<$Res> implements $VariantDtoCopyWith<$Res> {
  factory _$VariantDtoCopyWith(_VariantDto value, $Res Function(_VariantDto) _then) = __$VariantDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int price
});




}
/// @nodoc
class __$VariantDtoCopyWithImpl<$Res>
    implements _$VariantDtoCopyWith<$Res> {
  __$VariantDtoCopyWithImpl(this._self, this._then);

  final _VariantDto _self;
  final $Res Function(_VariantDto) _then;

/// Create a copy of VariantDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? price = null,}) {
  return _then(_VariantDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MenuItemDto {

 String get id; String get name; String get categoryId; String get description; int get basePrice; int get cost;/// Null = inherit the venue default (`prepTargetMins`). ADR-0043.
 int? get prepTime; List<VariantDto> get variants; List<ModifierGroupDto> get modifierGroups; List<String> get allergens; List<String> get dietary; bool get unavailable; int get photoRev;// Derived availability — computed server-side from ingredient stock and
// never stored (ADR-0040). Replaces the former `stockCount` /
// `autoSoldOutAtZero` pair, which v36 dropped.
 bool get autoSoldOut; List<String> get soldOutVariantIds; List<String> get soldOutOptionIds;
/// Create a copy of MenuItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuItemDtoCopyWith<MenuItemDto> get copyWith => _$MenuItemDtoCopyWithImpl<MenuItemDto>(this as MenuItemDto, _$identity);

  /// Serializes this MenuItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.description, description) || other.description == description)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.prepTime, prepTime) || other.prepTime == prepTime)&&const DeepCollectionEquality().equals(other.variants, variants)&&const DeepCollectionEquality().equals(other.modifierGroups, modifierGroups)&&const DeepCollectionEquality().equals(other.allergens, allergens)&&const DeepCollectionEquality().equals(other.dietary, dietary)&&(identical(other.unavailable, unavailable) || other.unavailable == unavailable)&&(identical(other.photoRev, photoRev) || other.photoRev == photoRev)&&(identical(other.autoSoldOut, autoSoldOut) || other.autoSoldOut == autoSoldOut)&&const DeepCollectionEquality().equals(other.soldOutVariantIds, soldOutVariantIds)&&const DeepCollectionEquality().equals(other.soldOutOptionIds, soldOutOptionIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,categoryId,description,basePrice,cost,prepTime,const DeepCollectionEquality().hash(variants),const DeepCollectionEquality().hash(modifierGroups),const DeepCollectionEquality().hash(allergens),const DeepCollectionEquality().hash(dietary),unavailable,photoRev,autoSoldOut,const DeepCollectionEquality().hash(soldOutVariantIds),const DeepCollectionEquality().hash(soldOutOptionIds));

@override
String toString() {
  return 'MenuItemDto(id: $id, name: $name, categoryId: $categoryId, description: $description, basePrice: $basePrice, cost: $cost, prepTime: $prepTime, variants: $variants, modifierGroups: $modifierGroups, allergens: $allergens, dietary: $dietary, unavailable: $unavailable, photoRev: $photoRev, autoSoldOut: $autoSoldOut, soldOutVariantIds: $soldOutVariantIds, soldOutOptionIds: $soldOutOptionIds)';
}


}

/// @nodoc
abstract mixin class $MenuItemDtoCopyWith<$Res>  {
  factory $MenuItemDtoCopyWith(MenuItemDto value, $Res Function(MenuItemDto) _then) = _$MenuItemDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String categoryId, String description, int basePrice, int cost, int? prepTime, List<VariantDto> variants, List<ModifierGroupDto> modifierGroups, List<String> allergens, List<String> dietary, bool unavailable, int photoRev, bool autoSoldOut, List<String> soldOutVariantIds, List<String> soldOutOptionIds
});




}
/// @nodoc
class _$MenuItemDtoCopyWithImpl<$Res>
    implements $MenuItemDtoCopyWith<$Res> {
  _$MenuItemDtoCopyWithImpl(this._self, this._then);

  final MenuItemDto _self;
  final $Res Function(MenuItemDto) _then;

/// Create a copy of MenuItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? categoryId = null,Object? description = null,Object? basePrice = null,Object? cost = null,Object? prepTime = freezed,Object? variants = null,Object? modifierGroups = null,Object? allergens = null,Object? dietary = null,Object? unavailable = null,Object? photoRev = null,Object? autoSoldOut = null,Object? soldOutVariantIds = null,Object? soldOutOptionIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as int,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int,prepTime: freezed == prepTime ? _self.prepTime : prepTime // ignore: cast_nullable_to_non_nullable
as int?,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<VariantDto>,modifierGroups: null == modifierGroups ? _self.modifierGroups : modifierGroups // ignore: cast_nullable_to_non_nullable
as List<ModifierGroupDto>,allergens: null == allergens ? _self.allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,dietary: null == dietary ? _self.dietary : dietary // ignore: cast_nullable_to_non_nullable
as List<String>,unavailable: null == unavailable ? _self.unavailable : unavailable // ignore: cast_nullable_to_non_nullable
as bool,photoRev: null == photoRev ? _self.photoRev : photoRev // ignore: cast_nullable_to_non_nullable
as int,autoSoldOut: null == autoSoldOut ? _self.autoSoldOut : autoSoldOut // ignore: cast_nullable_to_non_nullable
as bool,soldOutVariantIds: null == soldOutVariantIds ? _self.soldOutVariantIds : soldOutVariantIds // ignore: cast_nullable_to_non_nullable
as List<String>,soldOutOptionIds: null == soldOutOptionIds ? _self.soldOutOptionIds : soldOutOptionIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuItemDto].
extension MenuItemDtoPatterns on MenuItemDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuItemDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuItemDto value)  $default,){
final _that = this;
switch (_that) {
case _MenuItemDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _MenuItemDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String categoryId,  String description,  int basePrice,  int cost,  int? prepTime,  List<VariantDto> variants,  List<ModifierGroupDto> modifierGroups,  List<String> allergens,  List<String> dietary,  bool unavailable,  int photoRev,  bool autoSoldOut,  List<String> soldOutVariantIds,  List<String> soldOutOptionIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuItemDto() when $default != null:
return $default(_that.id,_that.name,_that.categoryId,_that.description,_that.basePrice,_that.cost,_that.prepTime,_that.variants,_that.modifierGroups,_that.allergens,_that.dietary,_that.unavailable,_that.photoRev,_that.autoSoldOut,_that.soldOutVariantIds,_that.soldOutOptionIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String categoryId,  String description,  int basePrice,  int cost,  int? prepTime,  List<VariantDto> variants,  List<ModifierGroupDto> modifierGroups,  List<String> allergens,  List<String> dietary,  bool unavailable,  int photoRev,  bool autoSoldOut,  List<String> soldOutVariantIds,  List<String> soldOutOptionIds)  $default,) {final _that = this;
switch (_that) {
case _MenuItemDto():
return $default(_that.id,_that.name,_that.categoryId,_that.description,_that.basePrice,_that.cost,_that.prepTime,_that.variants,_that.modifierGroups,_that.allergens,_that.dietary,_that.unavailable,_that.photoRev,_that.autoSoldOut,_that.soldOutVariantIds,_that.soldOutOptionIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String categoryId,  String description,  int basePrice,  int cost,  int? prepTime,  List<VariantDto> variants,  List<ModifierGroupDto> modifierGroups,  List<String> allergens,  List<String> dietary,  bool unavailable,  int photoRev,  bool autoSoldOut,  List<String> soldOutVariantIds,  List<String> soldOutOptionIds)?  $default,) {final _that = this;
switch (_that) {
case _MenuItemDto() when $default != null:
return $default(_that.id,_that.name,_that.categoryId,_that.description,_that.basePrice,_that.cost,_that.prepTime,_that.variants,_that.modifierGroups,_that.allergens,_that.dietary,_that.unavailable,_that.photoRev,_that.autoSoldOut,_that.soldOutVariantIds,_that.soldOutOptionIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuItemDto implements MenuItemDto {
  const _MenuItemDto({required this.id, required this.name, required this.categoryId, this.description = '', required this.basePrice, this.cost = 0, this.prepTime, final  List<VariantDto> variants = const <VariantDto>[], final  List<ModifierGroupDto> modifierGroups = const <ModifierGroupDto>[], final  List<String> allergens = const <String>[], final  List<String> dietary = const <String>[], this.unavailable = false, this.photoRev = 0, this.autoSoldOut = false, final  List<String> soldOutVariantIds = const <String>[], final  List<String> soldOutOptionIds = const <String>[]}): _variants = variants,_modifierGroups = modifierGroups,_allergens = allergens,_dietary = dietary,_soldOutVariantIds = soldOutVariantIds,_soldOutOptionIds = soldOutOptionIds;
  factory _MenuItemDto.fromJson(Map<String, dynamic> json) => _$MenuItemDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String categoryId;
@override@JsonKey() final  String description;
@override final  int basePrice;
@override@JsonKey() final  int cost;
/// Null = inherit the venue default (`prepTargetMins`). ADR-0043.
@override final  int? prepTime;
 final  List<VariantDto> _variants;
@override@JsonKey() List<VariantDto> get variants {
  if (_variants is EqualUnmodifiableListView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variants);
}

 final  List<ModifierGroupDto> _modifierGroups;
@override@JsonKey() List<ModifierGroupDto> get modifierGroups {
  if (_modifierGroups is EqualUnmodifiableListView) return _modifierGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modifierGroups);
}

 final  List<String> _allergens;
@override@JsonKey() List<String> get allergens {
  if (_allergens is EqualUnmodifiableListView) return _allergens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allergens);
}

 final  List<String> _dietary;
@override@JsonKey() List<String> get dietary {
  if (_dietary is EqualUnmodifiableListView) return _dietary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietary);
}

@override@JsonKey() final  bool unavailable;
@override@JsonKey() final  int photoRev;
// Derived availability — computed server-side from ingredient stock and
// never stored (ADR-0040). Replaces the former `stockCount` /
// `autoSoldOutAtZero` pair, which v36 dropped.
@override@JsonKey() final  bool autoSoldOut;
 final  List<String> _soldOutVariantIds;
@override@JsonKey() List<String> get soldOutVariantIds {
  if (_soldOutVariantIds is EqualUnmodifiableListView) return _soldOutVariantIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_soldOutVariantIds);
}

 final  List<String> _soldOutOptionIds;
@override@JsonKey() List<String> get soldOutOptionIds {
  if (_soldOutOptionIds is EqualUnmodifiableListView) return _soldOutOptionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_soldOutOptionIds);
}


/// Create a copy of MenuItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuItemDtoCopyWith<_MenuItemDto> get copyWith => __$MenuItemDtoCopyWithImpl<_MenuItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.description, description) || other.description == description)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.prepTime, prepTime) || other.prepTime == prepTime)&&const DeepCollectionEquality().equals(other._variants, _variants)&&const DeepCollectionEquality().equals(other._modifierGroups, _modifierGroups)&&const DeepCollectionEquality().equals(other._allergens, _allergens)&&const DeepCollectionEquality().equals(other._dietary, _dietary)&&(identical(other.unavailable, unavailable) || other.unavailable == unavailable)&&(identical(other.photoRev, photoRev) || other.photoRev == photoRev)&&(identical(other.autoSoldOut, autoSoldOut) || other.autoSoldOut == autoSoldOut)&&const DeepCollectionEquality().equals(other._soldOutVariantIds, _soldOutVariantIds)&&const DeepCollectionEquality().equals(other._soldOutOptionIds, _soldOutOptionIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,categoryId,description,basePrice,cost,prepTime,const DeepCollectionEquality().hash(_variants),const DeepCollectionEquality().hash(_modifierGroups),const DeepCollectionEquality().hash(_allergens),const DeepCollectionEquality().hash(_dietary),unavailable,photoRev,autoSoldOut,const DeepCollectionEquality().hash(_soldOutVariantIds),const DeepCollectionEquality().hash(_soldOutOptionIds));

@override
String toString() {
  return 'MenuItemDto(id: $id, name: $name, categoryId: $categoryId, description: $description, basePrice: $basePrice, cost: $cost, prepTime: $prepTime, variants: $variants, modifierGroups: $modifierGroups, allergens: $allergens, dietary: $dietary, unavailable: $unavailable, photoRev: $photoRev, autoSoldOut: $autoSoldOut, soldOutVariantIds: $soldOutVariantIds, soldOutOptionIds: $soldOutOptionIds)';
}


}

/// @nodoc
abstract mixin class _$MenuItemDtoCopyWith<$Res> implements $MenuItemDtoCopyWith<$Res> {
  factory _$MenuItemDtoCopyWith(_MenuItemDto value, $Res Function(_MenuItemDto) _then) = __$MenuItemDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String categoryId, String description, int basePrice, int cost, int? prepTime, List<VariantDto> variants, List<ModifierGroupDto> modifierGroups, List<String> allergens, List<String> dietary, bool unavailable, int photoRev, bool autoSoldOut, List<String> soldOutVariantIds, List<String> soldOutOptionIds
});




}
/// @nodoc
class __$MenuItemDtoCopyWithImpl<$Res>
    implements _$MenuItemDtoCopyWith<$Res> {
  __$MenuItemDtoCopyWithImpl(this._self, this._then);

  final _MenuItemDto _self;
  final $Res Function(_MenuItemDto) _then;

/// Create a copy of MenuItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? categoryId = null,Object? description = null,Object? basePrice = null,Object? cost = null,Object? prepTime = freezed,Object? variants = null,Object? modifierGroups = null,Object? allergens = null,Object? dietary = null,Object? unavailable = null,Object? photoRev = null,Object? autoSoldOut = null,Object? soldOutVariantIds = null,Object? soldOutOptionIds = null,}) {
  return _then(_MenuItemDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as int,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int,prepTime: freezed == prepTime ? _self.prepTime : prepTime // ignore: cast_nullable_to_non_nullable
as int?,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<VariantDto>,modifierGroups: null == modifierGroups ? _self._modifierGroups : modifierGroups // ignore: cast_nullable_to_non_nullable
as List<ModifierGroupDto>,allergens: null == allergens ? _self._allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,dietary: null == dietary ? _self._dietary : dietary // ignore: cast_nullable_to_non_nullable
as List<String>,unavailable: null == unavailable ? _self.unavailable : unavailable // ignore: cast_nullable_to_non_nullable
as bool,photoRev: null == photoRev ? _self.photoRev : photoRev // ignore: cast_nullable_to_non_nullable
as int,autoSoldOut: null == autoSoldOut ? _self.autoSoldOut : autoSoldOut // ignore: cast_nullable_to_non_nullable
as bool,soldOutVariantIds: null == soldOutVariantIds ? _self._soldOutVariantIds : soldOutVariantIds // ignore: cast_nullable_to_non_nullable
as List<String>,soldOutOptionIds: null == soldOutOptionIds ? _self._soldOutOptionIds : soldOutOptionIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$MenuTagDto {

 String get id; String get kind; String get name; String get code; int get sortOrder;
/// Create a copy of MenuTagDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuTagDtoCopyWith<MenuTagDto> get copyWith => _$MenuTagDtoCopyWithImpl<MenuTagDto>(this as MenuTagDto, _$identity);

  /// Serializes this MenuTagDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuTagDto&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,name,code,sortOrder);

@override
String toString() {
  return 'MenuTagDto(id: $id, kind: $kind, name: $name, code: $code, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $MenuTagDtoCopyWith<$Res>  {
  factory $MenuTagDtoCopyWith(MenuTagDto value, $Res Function(MenuTagDto) _then) = _$MenuTagDtoCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String name, String code, int sortOrder
});




}
/// @nodoc
class _$MenuTagDtoCopyWithImpl<$Res>
    implements $MenuTagDtoCopyWith<$Res> {
  _$MenuTagDtoCopyWithImpl(this._self, this._then);

  final MenuTagDto _self;
  final $Res Function(MenuTagDto) _then;

/// Create a copy of MenuTagDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? name = null,Object? code = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuTagDto].
extension MenuTagDtoPatterns on MenuTagDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuTagDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuTagDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuTagDto value)  $default,){
final _that = this;
switch (_that) {
case _MenuTagDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuTagDto value)?  $default,){
final _that = this;
switch (_that) {
case _MenuTagDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String name,  String code,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuTagDto() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.code,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String name,  String code,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _MenuTagDto():
return $default(_that.id,_that.kind,_that.name,_that.code,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String name,  String code,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _MenuTagDto() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.code,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuTagDto implements MenuTagDto {
  const _MenuTagDto({required this.id, required this.kind, required this.name, this.code = '', this.sortOrder = 0});
  factory _MenuTagDto.fromJson(Map<String, dynamic> json) => _$MenuTagDtoFromJson(json);

@override final  String id;
@override final  String kind;
@override final  String name;
@override@JsonKey() final  String code;
@override@JsonKey() final  int sortOrder;

/// Create a copy of MenuTagDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuTagDtoCopyWith<_MenuTagDto> get copyWith => __$MenuTagDtoCopyWithImpl<_MenuTagDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuTagDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuTagDto&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,name,code,sortOrder);

@override
String toString() {
  return 'MenuTagDto(id: $id, kind: $kind, name: $name, code: $code, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$MenuTagDtoCopyWith<$Res> implements $MenuTagDtoCopyWith<$Res> {
  factory _$MenuTagDtoCopyWith(_MenuTagDto value, $Res Function(_MenuTagDto) _then) = __$MenuTagDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String name, String code, int sortOrder
});




}
/// @nodoc
class __$MenuTagDtoCopyWithImpl<$Res>
    implements _$MenuTagDtoCopyWith<$Res> {
  __$MenuTagDtoCopyWithImpl(this._self, this._then);

  final _MenuTagDto _self;
  final $Res Function(_MenuTagDto) _then;

/// Create a copy of MenuTagDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? name = null,Object? code = null,Object? sortOrder = null,}) {
  return _then(_MenuTagDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ModifierOptionDto {

 String get id; String get name; int get priceDelta;
/// Create a copy of ModifierOptionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModifierOptionDtoCopyWith<ModifierOptionDto> get copyWith => _$ModifierOptionDtoCopyWithImpl<ModifierOptionDto>(this as ModifierOptionDto, _$identity);

  /// Serializes this ModifierOptionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModifierOptionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.priceDelta, priceDelta) || other.priceDelta == priceDelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,priceDelta);

@override
String toString() {
  return 'ModifierOptionDto(id: $id, name: $name, priceDelta: $priceDelta)';
}


}

/// @nodoc
abstract mixin class $ModifierOptionDtoCopyWith<$Res>  {
  factory $ModifierOptionDtoCopyWith(ModifierOptionDto value, $Res Function(ModifierOptionDto) _then) = _$ModifierOptionDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, int priceDelta
});




}
/// @nodoc
class _$ModifierOptionDtoCopyWithImpl<$Res>
    implements $ModifierOptionDtoCopyWith<$Res> {
  _$ModifierOptionDtoCopyWithImpl(this._self, this._then);

  final ModifierOptionDto _self;
  final $Res Function(ModifierOptionDto) _then;

/// Create a copy of ModifierOptionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? priceDelta = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,priceDelta: null == priceDelta ? _self.priceDelta : priceDelta // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ModifierOptionDto].
extension ModifierOptionDtoPatterns on ModifierOptionDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModifierOptionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModifierOptionDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModifierOptionDto value)  $default,){
final _that = this;
switch (_that) {
case _ModifierOptionDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModifierOptionDto value)?  $default,){
final _that = this;
switch (_that) {
case _ModifierOptionDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int priceDelta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModifierOptionDto() when $default != null:
return $default(_that.id,_that.name,_that.priceDelta);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int priceDelta)  $default,) {final _that = this;
switch (_that) {
case _ModifierOptionDto():
return $default(_that.id,_that.name,_that.priceDelta);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int priceDelta)?  $default,) {final _that = this;
switch (_that) {
case _ModifierOptionDto() when $default != null:
return $default(_that.id,_that.name,_that.priceDelta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModifierOptionDto implements ModifierOptionDto {
  const _ModifierOptionDto({required this.id, required this.name, this.priceDelta = 0});
  factory _ModifierOptionDto.fromJson(Map<String, dynamic> json) => _$ModifierOptionDtoFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  int priceDelta;

/// Create a copy of ModifierOptionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModifierOptionDtoCopyWith<_ModifierOptionDto> get copyWith => __$ModifierOptionDtoCopyWithImpl<_ModifierOptionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModifierOptionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModifierOptionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.priceDelta, priceDelta) || other.priceDelta == priceDelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,priceDelta);

@override
String toString() {
  return 'ModifierOptionDto(id: $id, name: $name, priceDelta: $priceDelta)';
}


}

/// @nodoc
abstract mixin class _$ModifierOptionDtoCopyWith<$Res> implements $ModifierOptionDtoCopyWith<$Res> {
  factory _$ModifierOptionDtoCopyWith(_ModifierOptionDto value, $Res Function(_ModifierOptionDto) _then) = __$ModifierOptionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int priceDelta
});




}
/// @nodoc
class __$ModifierOptionDtoCopyWithImpl<$Res>
    implements _$ModifierOptionDtoCopyWith<$Res> {
  __$ModifierOptionDtoCopyWithImpl(this._self, this._then);

  final _ModifierOptionDto _self;
  final $Res Function(_ModifierOptionDto) _then;

/// Create a copy of ModifierOptionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? priceDelta = null,}) {
  return _then(_ModifierOptionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,priceDelta: null == priceDelta ? _self.priceDelta : priceDelta // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ModifierGroupDto {

 String get id; String get name; bool get required; bool get multi; List<ModifierOptionDto> get options;
/// Create a copy of ModifierGroupDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModifierGroupDtoCopyWith<ModifierGroupDto> get copyWith => _$ModifierGroupDtoCopyWithImpl<ModifierGroupDto>(this as ModifierGroupDto, _$identity);

  /// Serializes this ModifierGroupDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModifierGroupDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.required, required) || other.required == required)&&(identical(other.multi, multi) || other.multi == multi)&&const DeepCollectionEquality().equals(other.options, options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,required,multi,const DeepCollectionEquality().hash(options));

@override
String toString() {
  return 'ModifierGroupDto(id: $id, name: $name, required: $required, multi: $multi, options: $options)';
}


}

/// @nodoc
abstract mixin class $ModifierGroupDtoCopyWith<$Res>  {
  factory $ModifierGroupDtoCopyWith(ModifierGroupDto value, $Res Function(ModifierGroupDto) _then) = _$ModifierGroupDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool required, bool multi, List<ModifierOptionDto> options
});




}
/// @nodoc
class _$ModifierGroupDtoCopyWithImpl<$Res>
    implements $ModifierGroupDtoCopyWith<$Res> {
  _$ModifierGroupDtoCopyWithImpl(this._self, this._then);

  final ModifierGroupDto _self;
  final $Res Function(ModifierGroupDto) _then;

/// Create a copy of ModifierGroupDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? required = null,Object? multi = null,Object? options = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,multi: null == multi ? _self.multi : multi // ignore: cast_nullable_to_non_nullable
as bool,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<ModifierOptionDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [ModifierGroupDto].
extension ModifierGroupDtoPatterns on ModifierGroupDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModifierGroupDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModifierGroupDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModifierGroupDto value)  $default,){
final _that = this;
switch (_that) {
case _ModifierGroupDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModifierGroupDto value)?  $default,){
final _that = this;
switch (_that) {
case _ModifierGroupDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool required,  bool multi,  List<ModifierOptionDto> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModifierGroupDto() when $default != null:
return $default(_that.id,_that.name,_that.required,_that.multi,_that.options);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool required,  bool multi,  List<ModifierOptionDto> options)  $default,) {final _that = this;
switch (_that) {
case _ModifierGroupDto():
return $default(_that.id,_that.name,_that.required,_that.multi,_that.options);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool required,  bool multi,  List<ModifierOptionDto> options)?  $default,) {final _that = this;
switch (_that) {
case _ModifierGroupDto() when $default != null:
return $default(_that.id,_that.name,_that.required,_that.multi,_that.options);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModifierGroupDto implements ModifierGroupDto {
  const _ModifierGroupDto({required this.id, required this.name, this.required = false, this.multi = false, final  List<ModifierOptionDto> options = const <ModifierOptionDto>[]}): _options = options;
  factory _ModifierGroupDto.fromJson(Map<String, dynamic> json) => _$ModifierGroupDtoFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  bool required;
@override@JsonKey() final  bool multi;
 final  List<ModifierOptionDto> _options;
@override@JsonKey() List<ModifierOptionDto> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of ModifierGroupDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModifierGroupDtoCopyWith<_ModifierGroupDto> get copyWith => __$ModifierGroupDtoCopyWithImpl<_ModifierGroupDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModifierGroupDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModifierGroupDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.required, required) || other.required == required)&&(identical(other.multi, multi) || other.multi == multi)&&const DeepCollectionEquality().equals(other._options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,required,multi,const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'ModifierGroupDto(id: $id, name: $name, required: $required, multi: $multi, options: $options)';
}


}

/// @nodoc
abstract mixin class _$ModifierGroupDtoCopyWith<$Res> implements $ModifierGroupDtoCopyWith<$Res> {
  factory _$ModifierGroupDtoCopyWith(_ModifierGroupDto value, $Res Function(_ModifierGroupDto) _then) = __$ModifierGroupDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool required, bool multi, List<ModifierOptionDto> options
});




}
/// @nodoc
class __$ModifierGroupDtoCopyWithImpl<$Res>
    implements _$ModifierGroupDtoCopyWith<$Res> {
  __$ModifierGroupDtoCopyWithImpl(this._self, this._then);

  final _ModifierGroupDto _self;
  final $Res Function(_ModifierGroupDto) _then;

/// Create a copy of ModifierGroupDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? required = null,Object? multi = null,Object? options = null,}) {
  return _then(_ModifierGroupDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,multi: null == multi ? _self.multi : multi // ignore: cast_nullable_to_non_nullable
as bool,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<ModifierOptionDto>,
  ));
}


}

// dart format on
