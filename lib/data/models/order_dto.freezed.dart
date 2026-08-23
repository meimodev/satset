// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CartModifierDto {

 String get groupId; String get optionId; String get label; int get priceDelta;
/// Create a copy of CartModifierDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartModifierDtoCopyWith<CartModifierDto> get copyWith => _$CartModifierDtoCopyWithImpl<CartModifierDto>(this as CartModifierDto, _$identity);

  /// Serializes this CartModifierDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartModifierDto&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.optionId, optionId) || other.optionId == optionId)&&(identical(other.label, label) || other.label == label)&&(identical(other.priceDelta, priceDelta) || other.priceDelta == priceDelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupId,optionId,label,priceDelta);

@override
String toString() {
  return 'CartModifierDto(groupId: $groupId, optionId: $optionId, label: $label, priceDelta: $priceDelta)';
}


}

/// @nodoc
abstract mixin class $CartModifierDtoCopyWith<$Res>  {
  factory $CartModifierDtoCopyWith(CartModifierDto value, $Res Function(CartModifierDto) _then) = _$CartModifierDtoCopyWithImpl;
@useResult
$Res call({
 String groupId, String optionId, String label, int priceDelta
});




}
/// @nodoc
class _$CartModifierDtoCopyWithImpl<$Res>
    implements $CartModifierDtoCopyWith<$Res> {
  _$CartModifierDtoCopyWithImpl(this._self, this._then);

  final CartModifierDto _self;
  final $Res Function(CartModifierDto) _then;

/// Create a copy of CartModifierDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? optionId = null,Object? label = null,Object? priceDelta = null,}) {
  return _then(_self.copyWith(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,optionId: null == optionId ? _self.optionId : optionId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,priceDelta: null == priceDelta ? _self.priceDelta : priceDelta // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CartModifierDto].
extension CartModifierDtoPatterns on CartModifierDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartModifierDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartModifierDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartModifierDto value)  $default,){
final _that = this;
switch (_that) {
case _CartModifierDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartModifierDto value)?  $default,){
final _that = this;
switch (_that) {
case _CartModifierDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String groupId,  String optionId,  String label,  int priceDelta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartModifierDto() when $default != null:
return $default(_that.groupId,_that.optionId,_that.label,_that.priceDelta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String groupId,  String optionId,  String label,  int priceDelta)  $default,) {final _that = this;
switch (_that) {
case _CartModifierDto():
return $default(_that.groupId,_that.optionId,_that.label,_that.priceDelta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String groupId,  String optionId,  String label,  int priceDelta)?  $default,) {final _that = this;
switch (_that) {
case _CartModifierDto() when $default != null:
return $default(_that.groupId,_that.optionId,_that.label,_that.priceDelta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CartModifierDto implements CartModifierDto {
  const _CartModifierDto({required this.groupId, required this.optionId, required this.label, required this.priceDelta});
  factory _CartModifierDto.fromJson(Map<String, dynamic> json) => _$CartModifierDtoFromJson(json);

@override final  String groupId;
@override final  String optionId;
@override final  String label;
@override final  int priceDelta;

/// Create a copy of CartModifierDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartModifierDtoCopyWith<_CartModifierDto> get copyWith => __$CartModifierDtoCopyWithImpl<_CartModifierDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CartModifierDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartModifierDto&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.optionId, optionId) || other.optionId == optionId)&&(identical(other.label, label) || other.label == label)&&(identical(other.priceDelta, priceDelta) || other.priceDelta == priceDelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupId,optionId,label,priceDelta);

@override
String toString() {
  return 'CartModifierDto(groupId: $groupId, optionId: $optionId, label: $label, priceDelta: $priceDelta)';
}


}

/// @nodoc
abstract mixin class _$CartModifierDtoCopyWith<$Res> implements $CartModifierDtoCopyWith<$Res> {
  factory _$CartModifierDtoCopyWith(_CartModifierDto value, $Res Function(_CartModifierDto) _then) = __$CartModifierDtoCopyWithImpl;
@override @useResult
$Res call({
 String groupId, String optionId, String label, int priceDelta
});




}
/// @nodoc
class __$CartModifierDtoCopyWithImpl<$Res>
    implements _$CartModifierDtoCopyWith<$Res> {
  __$CartModifierDtoCopyWithImpl(this._self, this._then);

  final _CartModifierDto _self;
  final $Res Function(_CartModifierDto) _then;

/// Create a copy of CartModifierDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? optionId = null,Object? label = null,Object? priceDelta = null,}) {
  return _then(_CartModifierDto(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,optionId: null == optionId ? _self.optionId : optionId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,priceDelta: null == priceDelta ? _self.priceDelta : priceDelta // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CartLineDto {

 String get itemId; String get name; String get variantId; String get variantName; List<CartModifierDto> get modifiers; String? get note; String get course; int get qty; int get unitPrice;
/// Create a copy of CartLineDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartLineDtoCopyWith<CartLineDto> get copyWith => _$CartLineDtoCopyWithImpl<CartLineDto>(this as CartLineDto, _$identity);

  /// Serializes this CartLineDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartLineDto&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.variantId, variantId) || other.variantId == variantId)&&(identical(other.variantName, variantName) || other.variantName == variantName)&&const DeepCollectionEquality().equals(other.modifiers, modifiers)&&(identical(other.note, note) || other.note == note)&&(identical(other.course, course) || other.course == course)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,name,variantId,variantName,const DeepCollectionEquality().hash(modifiers),note,course,qty,unitPrice);

@override
String toString() {
  return 'CartLineDto(itemId: $itemId, name: $name, variantId: $variantId, variantName: $variantName, modifiers: $modifiers, note: $note, course: $course, qty: $qty, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class $CartLineDtoCopyWith<$Res>  {
  factory $CartLineDtoCopyWith(CartLineDto value, $Res Function(CartLineDto) _then) = _$CartLineDtoCopyWithImpl;
@useResult
$Res call({
 String itemId, String name, String variantId, String variantName, List<CartModifierDto> modifiers, String? note, String course, int qty, int unitPrice
});




}
/// @nodoc
class _$CartLineDtoCopyWithImpl<$Res>
    implements $CartLineDtoCopyWith<$Res> {
  _$CartLineDtoCopyWithImpl(this._self, this._then);

  final CartLineDto _self;
  final $Res Function(CartLineDto) _then;

/// Create a copy of CartLineDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? name = null,Object? variantId = null,Object? variantName = null,Object? modifiers = null,Object? note = freezed,Object? course = null,Object? qty = null,Object? unitPrice = null,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variantId: null == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String,variantName: null == variantName ? _self.variantName : variantName // ignore: cast_nullable_to_non_nullable
as String,modifiers: null == modifiers ? _self.modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as List<CartModifierDto>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CartLineDto].
extension CartLineDtoPatterns on CartLineDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartLineDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartLineDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartLineDto value)  $default,){
final _that = this;
switch (_that) {
case _CartLineDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartLineDto value)?  $default,){
final _that = this;
switch (_that) {
case _CartLineDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  String name,  String variantId,  String variantName,  List<CartModifierDto> modifiers,  String? note,  String course,  int qty,  int unitPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartLineDto() when $default != null:
return $default(_that.itemId,_that.name,_that.variantId,_that.variantName,_that.modifiers,_that.note,_that.course,_that.qty,_that.unitPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  String name,  String variantId,  String variantName,  List<CartModifierDto> modifiers,  String? note,  String course,  int qty,  int unitPrice)  $default,) {final _that = this;
switch (_that) {
case _CartLineDto():
return $default(_that.itemId,_that.name,_that.variantId,_that.variantName,_that.modifiers,_that.note,_that.course,_that.qty,_that.unitPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  String name,  String variantId,  String variantName,  List<CartModifierDto> modifiers,  String? note,  String course,  int qty,  int unitPrice)?  $default,) {final _that = this;
switch (_that) {
case _CartLineDto() when $default != null:
return $default(_that.itemId,_that.name,_that.variantId,_that.variantName,_that.modifiers,_that.note,_that.course,_that.qty,_that.unitPrice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CartLineDto implements CartLineDto {
  const _CartLineDto({required this.itemId, required this.name, required this.variantId, required this.variantName, required final  List<CartModifierDto> modifiers, required this.note, required this.course, required this.qty, required this.unitPrice}): _modifiers = modifiers;
  factory _CartLineDto.fromJson(Map<String, dynamic> json) => _$CartLineDtoFromJson(json);

@override final  String itemId;
@override final  String name;
@override final  String variantId;
@override final  String variantName;
 final  List<CartModifierDto> _modifiers;
@override List<CartModifierDto> get modifiers {
  if (_modifiers is EqualUnmodifiableListView) return _modifiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modifiers);
}

@override final  String? note;
@override final  String course;
@override final  int qty;
@override final  int unitPrice;

/// Create a copy of CartLineDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartLineDtoCopyWith<_CartLineDto> get copyWith => __$CartLineDtoCopyWithImpl<_CartLineDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CartLineDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartLineDto&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.variantId, variantId) || other.variantId == variantId)&&(identical(other.variantName, variantName) || other.variantName == variantName)&&const DeepCollectionEquality().equals(other._modifiers, _modifiers)&&(identical(other.note, note) || other.note == note)&&(identical(other.course, course) || other.course == course)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,name,variantId,variantName,const DeepCollectionEquality().hash(_modifiers),note,course,qty,unitPrice);

@override
String toString() {
  return 'CartLineDto(itemId: $itemId, name: $name, variantId: $variantId, variantName: $variantName, modifiers: $modifiers, note: $note, course: $course, qty: $qty, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class _$CartLineDtoCopyWith<$Res> implements $CartLineDtoCopyWith<$Res> {
  factory _$CartLineDtoCopyWith(_CartLineDto value, $Res Function(_CartLineDto) _then) = __$CartLineDtoCopyWithImpl;
@override @useResult
$Res call({
 String itemId, String name, String variantId, String variantName, List<CartModifierDto> modifiers, String? note, String course, int qty, int unitPrice
});




}
/// @nodoc
class __$CartLineDtoCopyWithImpl<$Res>
    implements _$CartLineDtoCopyWith<$Res> {
  __$CartLineDtoCopyWithImpl(this._self, this._then);

  final _CartLineDto _self;
  final $Res Function(_CartLineDto) _then;

/// Create a copy of CartLineDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? name = null,Object? variantId = null,Object? variantName = null,Object? modifiers = null,Object? note = freezed,Object? course = null,Object? qty = null,Object? unitPrice = null,}) {
  return _then(_CartLineDto(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variantId: null == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String,variantName: null == variantName ? _self.variantName : variantName // ignore: cast_nullable_to_non_nullable
as String,modifiers: null == modifiers ? _self._modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as List<CartModifierDto>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SubmitOrderRequestDto {

 String get tableId; String get idempotencyKey; List<CartLineDto> get lines; String? get actorId;
/// Create a copy of SubmitOrderRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmitOrderRequestDtoCopyWith<SubmitOrderRequestDto> get copyWith => _$SubmitOrderRequestDtoCopyWithImpl<SubmitOrderRequestDto>(this as SubmitOrderRequestDto, _$identity);

  /// Serializes this SubmitOrderRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmitOrderRequestDto&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&const DeepCollectionEquality().equals(other.lines, lines)&&(identical(other.actorId, actorId) || other.actorId == actorId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tableId,idempotencyKey,const DeepCollectionEquality().hash(lines),actorId);

@override
String toString() {
  return 'SubmitOrderRequestDto(tableId: $tableId, idempotencyKey: $idempotencyKey, lines: $lines, actorId: $actorId)';
}


}

/// @nodoc
abstract mixin class $SubmitOrderRequestDtoCopyWith<$Res>  {
  factory $SubmitOrderRequestDtoCopyWith(SubmitOrderRequestDto value, $Res Function(SubmitOrderRequestDto) _then) = _$SubmitOrderRequestDtoCopyWithImpl;
@useResult
$Res call({
 String tableId, String idempotencyKey, List<CartLineDto> lines, String? actorId
});




}
/// @nodoc
class _$SubmitOrderRequestDtoCopyWithImpl<$Res>
    implements $SubmitOrderRequestDtoCopyWith<$Res> {
  _$SubmitOrderRequestDtoCopyWithImpl(this._self, this._then);

  final SubmitOrderRequestDto _self;
  final $Res Function(SubmitOrderRequestDto) _then;

/// Create a copy of SubmitOrderRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tableId = null,Object? idempotencyKey = null,Object? lines = null,Object? actorId = freezed,}) {
  return _then(_self.copyWith(
tableId: null == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<CartLineDto>,actorId: freezed == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubmitOrderRequestDto].
extension SubmitOrderRequestDtoPatterns on SubmitOrderRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubmitOrderRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubmitOrderRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubmitOrderRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _SubmitOrderRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubmitOrderRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _SubmitOrderRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tableId,  String idempotencyKey,  List<CartLineDto> lines,  String? actorId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubmitOrderRequestDto() when $default != null:
return $default(_that.tableId,_that.idempotencyKey,_that.lines,_that.actorId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tableId,  String idempotencyKey,  List<CartLineDto> lines,  String? actorId)  $default,) {final _that = this;
switch (_that) {
case _SubmitOrderRequestDto():
return $default(_that.tableId,_that.idempotencyKey,_that.lines,_that.actorId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tableId,  String idempotencyKey,  List<CartLineDto> lines,  String? actorId)?  $default,) {final _that = this;
switch (_that) {
case _SubmitOrderRequestDto() when $default != null:
return $default(_that.tableId,_that.idempotencyKey,_that.lines,_that.actorId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubmitOrderRequestDto implements SubmitOrderRequestDto {
  const _SubmitOrderRequestDto({required this.tableId, required this.idempotencyKey, required final  List<CartLineDto> lines, this.actorId}): _lines = lines;
  factory _SubmitOrderRequestDto.fromJson(Map<String, dynamic> json) => _$SubmitOrderRequestDtoFromJson(json);

@override final  String tableId;
@override final  String idempotencyKey;
 final  List<CartLineDto> _lines;
@override List<CartLineDto> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override final  String? actorId;

/// Create a copy of SubmitOrderRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubmitOrderRequestDtoCopyWith<_SubmitOrderRequestDto> get copyWith => __$SubmitOrderRequestDtoCopyWithImpl<_SubmitOrderRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubmitOrderRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubmitOrderRequestDto&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.actorId, actorId) || other.actorId == actorId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tableId,idempotencyKey,const DeepCollectionEquality().hash(_lines),actorId);

@override
String toString() {
  return 'SubmitOrderRequestDto(tableId: $tableId, idempotencyKey: $idempotencyKey, lines: $lines, actorId: $actorId)';
}


}

/// @nodoc
abstract mixin class _$SubmitOrderRequestDtoCopyWith<$Res> implements $SubmitOrderRequestDtoCopyWith<$Res> {
  factory _$SubmitOrderRequestDtoCopyWith(_SubmitOrderRequestDto value, $Res Function(_SubmitOrderRequestDto) _then) = __$SubmitOrderRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String tableId, String idempotencyKey, List<CartLineDto> lines, String? actorId
});




}
/// @nodoc
class __$SubmitOrderRequestDtoCopyWithImpl<$Res>
    implements _$SubmitOrderRequestDtoCopyWith<$Res> {
  __$SubmitOrderRequestDtoCopyWithImpl(this._self, this._then);

  final _SubmitOrderRequestDto _self;
  final $Res Function(_SubmitOrderRequestDto) _then;

/// Create a copy of SubmitOrderRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tableId = null,Object? idempotencyKey = null,Object? lines = null,Object? actorId = freezed,}) {
  return _then(_SubmitOrderRequestDto(
tableId: null == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<CartLineDto>,actorId: freezed == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SubmitOrderResponseDto {

 List<String> get ticketIds;/// The visit the lines were filed under. Lets the sending device seed the
/// table's currentVisitId immediately, before the tableUpdated echo lands,
/// so its lines resolve without a flash of empty. See ADR-0034.
 String? get visitId;/// Lines the server refused for want of ingredients (ADR-0041). Only the
/// offending lines are dropped — the rest of the order still lands — so
/// this must be surfaced, or lines vanish silently.
 List<RejectedLineDto> get rejected;
/// Create a copy of SubmitOrderResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmitOrderResponseDtoCopyWith<SubmitOrderResponseDto> get copyWith => _$SubmitOrderResponseDtoCopyWithImpl<SubmitOrderResponseDto>(this as SubmitOrderResponseDto, _$identity);

  /// Serializes this SubmitOrderResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmitOrderResponseDto&&const DeepCollectionEquality().equals(other.ticketIds, ticketIds)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&const DeepCollectionEquality().equals(other.rejected, rejected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(ticketIds),visitId,const DeepCollectionEquality().hash(rejected));

@override
String toString() {
  return 'SubmitOrderResponseDto(ticketIds: $ticketIds, visitId: $visitId, rejected: $rejected)';
}


}

/// @nodoc
abstract mixin class $SubmitOrderResponseDtoCopyWith<$Res>  {
  factory $SubmitOrderResponseDtoCopyWith(SubmitOrderResponseDto value, $Res Function(SubmitOrderResponseDto) _then) = _$SubmitOrderResponseDtoCopyWithImpl;
@useResult
$Res call({
 List<String> ticketIds, String? visitId, List<RejectedLineDto> rejected
});




}
/// @nodoc
class _$SubmitOrderResponseDtoCopyWithImpl<$Res>
    implements $SubmitOrderResponseDtoCopyWith<$Res> {
  _$SubmitOrderResponseDtoCopyWithImpl(this._self, this._then);

  final SubmitOrderResponseDto _self;
  final $Res Function(SubmitOrderResponseDto) _then;

/// Create a copy of SubmitOrderResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ticketIds = null,Object? visitId = freezed,Object? rejected = null,}) {
  return _then(_self.copyWith(
ticketIds: null == ticketIds ? _self.ticketIds : ticketIds // ignore: cast_nullable_to_non_nullable
as List<String>,visitId: freezed == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String?,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as List<RejectedLineDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubmitOrderResponseDto].
extension SubmitOrderResponseDtoPatterns on SubmitOrderResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubmitOrderResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubmitOrderResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubmitOrderResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _SubmitOrderResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubmitOrderResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _SubmitOrderResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> ticketIds,  String? visitId,  List<RejectedLineDto> rejected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubmitOrderResponseDto() when $default != null:
return $default(_that.ticketIds,_that.visitId,_that.rejected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> ticketIds,  String? visitId,  List<RejectedLineDto> rejected)  $default,) {final _that = this;
switch (_that) {
case _SubmitOrderResponseDto():
return $default(_that.ticketIds,_that.visitId,_that.rejected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> ticketIds,  String? visitId,  List<RejectedLineDto> rejected)?  $default,) {final _that = this;
switch (_that) {
case _SubmitOrderResponseDto() when $default != null:
return $default(_that.ticketIds,_that.visitId,_that.rejected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubmitOrderResponseDto implements SubmitOrderResponseDto {
  const _SubmitOrderResponseDto({required final  List<String> ticketIds, this.visitId, final  List<RejectedLineDto> rejected = const <RejectedLineDto>[]}): _ticketIds = ticketIds,_rejected = rejected;
  factory _SubmitOrderResponseDto.fromJson(Map<String, dynamic> json) => _$SubmitOrderResponseDtoFromJson(json);

 final  List<String> _ticketIds;
@override List<String> get ticketIds {
  if (_ticketIds is EqualUnmodifiableListView) return _ticketIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ticketIds);
}

/// The visit the lines were filed under. Lets the sending device seed the
/// table's currentVisitId immediately, before the tableUpdated echo lands,
/// so its lines resolve without a flash of empty. See ADR-0034.
@override final  String? visitId;
/// Lines the server refused for want of ingredients (ADR-0041). Only the
/// offending lines are dropped — the rest of the order still lands — so
/// this must be surfaced, or lines vanish silently.
 final  List<RejectedLineDto> _rejected;
/// Lines the server refused for want of ingredients (ADR-0041). Only the
/// offending lines are dropped — the rest of the order still lands — so
/// this must be surfaced, or lines vanish silently.
@override@JsonKey() List<RejectedLineDto> get rejected {
  if (_rejected is EqualUnmodifiableListView) return _rejected;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rejected);
}


/// Create a copy of SubmitOrderResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubmitOrderResponseDtoCopyWith<_SubmitOrderResponseDto> get copyWith => __$SubmitOrderResponseDtoCopyWithImpl<_SubmitOrderResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubmitOrderResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubmitOrderResponseDto&&const DeepCollectionEquality().equals(other._ticketIds, _ticketIds)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&const DeepCollectionEquality().equals(other._rejected, _rejected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_ticketIds),visitId,const DeepCollectionEquality().hash(_rejected));

@override
String toString() {
  return 'SubmitOrderResponseDto(ticketIds: $ticketIds, visitId: $visitId, rejected: $rejected)';
}


}

/// @nodoc
abstract mixin class _$SubmitOrderResponseDtoCopyWith<$Res> implements $SubmitOrderResponseDtoCopyWith<$Res> {
  factory _$SubmitOrderResponseDtoCopyWith(_SubmitOrderResponseDto value, $Res Function(_SubmitOrderResponseDto) _then) = __$SubmitOrderResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 List<String> ticketIds, String? visitId, List<RejectedLineDto> rejected
});




}
/// @nodoc
class __$SubmitOrderResponseDtoCopyWithImpl<$Res>
    implements _$SubmitOrderResponseDtoCopyWith<$Res> {
  __$SubmitOrderResponseDtoCopyWithImpl(this._self, this._then);

  final _SubmitOrderResponseDto _self;
  final $Res Function(_SubmitOrderResponseDto) _then;

/// Create a copy of SubmitOrderResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticketIds = null,Object? visitId = freezed,Object? rejected = null,}) {
  return _then(_SubmitOrderResponseDto(
ticketIds: null == ticketIds ? _self._ticketIds : ticketIds // ignore: cast_nullable_to_non_nullable
as List<String>,visitId: freezed == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String?,rejected: null == rejected ? _self._rejected : rejected // ignore: cast_nullable_to_non_nullable
as List<RejectedLineDto>,
  ));
}


}


/// @nodoc
mixin _$RejectedLineDto {

 String get itemId; String get name; String get variantName;/// Names of the bahan that fell short — so the waiter is told *what* ran
/// out rather than just "no".
 List<String> get ingredients;
/// Create a copy of RejectedLineDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RejectedLineDtoCopyWith<RejectedLineDto> get copyWith => _$RejectedLineDtoCopyWithImpl<RejectedLineDto>(this as RejectedLineDto, _$identity);

  /// Serializes this RejectedLineDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RejectedLineDto&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.variantName, variantName) || other.variantName == variantName)&&const DeepCollectionEquality().equals(other.ingredients, ingredients));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,name,variantName,const DeepCollectionEquality().hash(ingredients));

@override
String toString() {
  return 'RejectedLineDto(itemId: $itemId, name: $name, variantName: $variantName, ingredients: $ingredients)';
}


}

/// @nodoc
abstract mixin class $RejectedLineDtoCopyWith<$Res>  {
  factory $RejectedLineDtoCopyWith(RejectedLineDto value, $Res Function(RejectedLineDto) _then) = _$RejectedLineDtoCopyWithImpl;
@useResult
$Res call({
 String itemId, String name, String variantName, List<String> ingredients
});




}
/// @nodoc
class _$RejectedLineDtoCopyWithImpl<$Res>
    implements $RejectedLineDtoCopyWith<$Res> {
  _$RejectedLineDtoCopyWithImpl(this._self, this._then);

  final RejectedLineDto _self;
  final $Res Function(RejectedLineDto) _then;

/// Create a copy of RejectedLineDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? name = null,Object? variantName = null,Object? ingredients = null,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variantName: null == variantName ? _self.variantName : variantName // ignore: cast_nullable_to_non_nullable
as String,ingredients: null == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [RejectedLineDto].
extension RejectedLineDtoPatterns on RejectedLineDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RejectedLineDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RejectedLineDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RejectedLineDto value)  $default,){
final _that = this;
switch (_that) {
case _RejectedLineDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RejectedLineDto value)?  $default,){
final _that = this;
switch (_that) {
case _RejectedLineDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  String name,  String variantName,  List<String> ingredients)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RejectedLineDto() when $default != null:
return $default(_that.itemId,_that.name,_that.variantName,_that.ingredients);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  String name,  String variantName,  List<String> ingredients)  $default,) {final _that = this;
switch (_that) {
case _RejectedLineDto():
return $default(_that.itemId,_that.name,_that.variantName,_that.ingredients);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  String name,  String variantName,  List<String> ingredients)?  $default,) {final _that = this;
switch (_that) {
case _RejectedLineDto() when $default != null:
return $default(_that.itemId,_that.name,_that.variantName,_that.ingredients);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RejectedLineDto implements RejectedLineDto {
  const _RejectedLineDto({required this.itemId, this.name = '', this.variantName = '', final  List<String> ingredients = const <String>[]}): _ingredients = ingredients;
  factory _RejectedLineDto.fromJson(Map<String, dynamic> json) => _$RejectedLineDtoFromJson(json);

@override final  String itemId;
@override@JsonKey() final  String name;
@override@JsonKey() final  String variantName;
/// Names of the bahan that fell short — so the waiter is told *what* ran
/// out rather than just "no".
 final  List<String> _ingredients;
/// Names of the bahan that fell short — so the waiter is told *what* ran
/// out rather than just "no".
@override@JsonKey() List<String> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}


/// Create a copy of RejectedLineDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RejectedLineDtoCopyWith<_RejectedLineDto> get copyWith => __$RejectedLineDtoCopyWithImpl<_RejectedLineDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RejectedLineDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RejectedLineDto&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.variantName, variantName) || other.variantName == variantName)&&const DeepCollectionEquality().equals(other._ingredients, _ingredients));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,name,variantName,const DeepCollectionEquality().hash(_ingredients));

@override
String toString() {
  return 'RejectedLineDto(itemId: $itemId, name: $name, variantName: $variantName, ingredients: $ingredients)';
}


}

/// @nodoc
abstract mixin class _$RejectedLineDtoCopyWith<$Res> implements $RejectedLineDtoCopyWith<$Res> {
  factory _$RejectedLineDtoCopyWith(_RejectedLineDto value, $Res Function(_RejectedLineDto) _then) = __$RejectedLineDtoCopyWithImpl;
@override @useResult
$Res call({
 String itemId, String name, String variantName, List<String> ingredients
});




}
/// @nodoc
class __$RejectedLineDtoCopyWithImpl<$Res>
    implements _$RejectedLineDtoCopyWith<$Res> {
  __$RejectedLineDtoCopyWithImpl(this._self, this._then);

  final _RejectedLineDto _self;
  final $Res Function(_RejectedLineDto) _then;

/// Create a copy of RejectedLineDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? name = null,Object? variantName = null,Object? ingredients = null,}) {
  return _then(_RejectedLineDto(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variantName: null == variantName ? _self.variantName : variantName // ignore: cast_nullable_to_non_nullable
as String,ingredients: null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
