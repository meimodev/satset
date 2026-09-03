// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discount_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DiscountPresetDto {

 String get id; String get name;/// `bill` (whole tab) | `order` (one receipt) | `line` (one bill line).
/// The picker only offers presets valid for what the cashier tapped — this
/// is what stops a fixed whole-bill amount landing on a single cheap line.
 String get scope;/// `percent` (value in basis points) | `fixed` (value in rupiah).
 String get kind; int get value; bool get active; int get sortOrder;
/// Create a copy of DiscountPresetDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscountPresetDtoCopyWith<DiscountPresetDto> get copyWith => _$DiscountPresetDtoCopyWithImpl<DiscountPresetDto>(this as DiscountPresetDto, _$identity);

  /// Serializes this DiscountPresetDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscountPresetDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.value, value) || other.value == value)&&(identical(other.active, active) || other.active == active)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,scope,kind,value,active,sortOrder);

@override
String toString() {
  return 'DiscountPresetDto(id: $id, name: $name, scope: $scope, kind: $kind, value: $value, active: $active, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $DiscountPresetDtoCopyWith<$Res>  {
  factory $DiscountPresetDtoCopyWith(DiscountPresetDto value, $Res Function(DiscountPresetDto) _then) = _$DiscountPresetDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String scope, String kind, int value, bool active, int sortOrder
});




}
/// @nodoc
class _$DiscountPresetDtoCopyWithImpl<$Res>
    implements $DiscountPresetDtoCopyWith<$Res> {
  _$DiscountPresetDtoCopyWithImpl(this._self, this._then);

  final DiscountPresetDto _self;
  final $Res Function(DiscountPresetDto) _then;

/// Create a copy of DiscountPresetDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? scope = null,Object? kind = null,Object? value = null,Object? active = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscountPresetDto].
extension DiscountPresetDtoPatterns on DiscountPresetDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscountPresetDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscountPresetDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscountPresetDto value)  $default,){
final _that = this;
switch (_that) {
case _DiscountPresetDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscountPresetDto value)?  $default,){
final _that = this;
switch (_that) {
case _DiscountPresetDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String scope,  String kind,  int value,  bool active,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscountPresetDto() when $default != null:
return $default(_that.id,_that.name,_that.scope,_that.kind,_that.value,_that.active,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String scope,  String kind,  int value,  bool active,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _DiscountPresetDto():
return $default(_that.id,_that.name,_that.scope,_that.kind,_that.value,_that.active,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String scope,  String kind,  int value,  bool active,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _DiscountPresetDto() when $default != null:
return $default(_that.id,_that.name,_that.scope,_that.kind,_that.value,_that.active,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiscountPresetDto implements DiscountPresetDto {
  const _DiscountPresetDto({required this.id, this.name = '', this.scope = 'order', this.kind = 'percent', this.value = 0, this.active = true, this.sortOrder = 0});
  factory _DiscountPresetDto.fromJson(Map<String, dynamic> json) => _$DiscountPresetDtoFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
/// `bill` (whole tab) | `order` (one receipt) | `line` (one bill line).
/// The picker only offers presets valid for what the cashier tapped — this
/// is what stops a fixed whole-bill amount landing on a single cheap line.
@override@JsonKey() final  String scope;
/// `percent` (value in basis points) | `fixed` (value in rupiah).
@override@JsonKey() final  String kind;
@override@JsonKey() final  int value;
@override@JsonKey() final  bool active;
@override@JsonKey() final  int sortOrder;

/// Create a copy of DiscountPresetDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscountPresetDtoCopyWith<_DiscountPresetDto> get copyWith => __$DiscountPresetDtoCopyWithImpl<_DiscountPresetDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiscountPresetDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscountPresetDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.value, value) || other.value == value)&&(identical(other.active, active) || other.active == active)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,scope,kind,value,active,sortOrder);

@override
String toString() {
  return 'DiscountPresetDto(id: $id, name: $name, scope: $scope, kind: $kind, value: $value, active: $active, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$DiscountPresetDtoCopyWith<$Res> implements $DiscountPresetDtoCopyWith<$Res> {
  factory _$DiscountPresetDtoCopyWith(_DiscountPresetDto value, $Res Function(_DiscountPresetDto) _then) = __$DiscountPresetDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String scope, String kind, int value, bool active, int sortOrder
});




}
/// @nodoc
class __$DiscountPresetDtoCopyWithImpl<$Res>
    implements _$DiscountPresetDtoCopyWith<$Res> {
  __$DiscountPresetDtoCopyWithImpl(this._self, this._then);

  final _DiscountPresetDto _self;
  final $Res Function(_DiscountPresetDto) _then;

/// Create a copy of DiscountPresetDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? scope = null,Object? kind = null,Object? value = null,Object? active = null,Object? sortOrder = null,}) {
  return _then(_DiscountPresetDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AppliedDiscountDto {

 String get id; String? get ticketId; String? get presetId; String get name; String get kind; int get value; int get amount; String? get byUserId; String? get approvedByUserId;
/// Create a copy of AppliedDiscountDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppliedDiscountDtoCopyWith<AppliedDiscountDto> get copyWith => _$AppliedDiscountDtoCopyWithImpl<AppliedDiscountDto>(this as AppliedDiscountDto, _$identity);

  /// Serializes this AppliedDiscountDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppliedDiscountDto&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.presetId, presetId) || other.presetId == presetId)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.value, value) || other.value == value)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.byUserId, byUserId) || other.byUserId == byUserId)&&(identical(other.approvedByUserId, approvedByUserId) || other.approvedByUserId == approvedByUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticketId,presetId,name,kind,value,amount,byUserId,approvedByUserId);

@override
String toString() {
  return 'AppliedDiscountDto(id: $id, ticketId: $ticketId, presetId: $presetId, name: $name, kind: $kind, value: $value, amount: $amount, byUserId: $byUserId, approvedByUserId: $approvedByUserId)';
}


}

/// @nodoc
abstract mixin class $AppliedDiscountDtoCopyWith<$Res>  {
  factory $AppliedDiscountDtoCopyWith(AppliedDiscountDto value, $Res Function(AppliedDiscountDto) _then) = _$AppliedDiscountDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? ticketId, String? presetId, String name, String kind, int value, int amount, String? byUserId, String? approvedByUserId
});




}
/// @nodoc
class _$AppliedDiscountDtoCopyWithImpl<$Res>
    implements $AppliedDiscountDtoCopyWith<$Res> {
  _$AppliedDiscountDtoCopyWithImpl(this._self, this._then);

  final AppliedDiscountDto _self;
  final $Res Function(AppliedDiscountDto) _then;

/// Create a copy of AppliedDiscountDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ticketId = freezed,Object? presetId = freezed,Object? name = null,Object? kind = null,Object? value = null,Object? amount = null,Object? byUserId = freezed,Object? approvedByUserId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticketId: freezed == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String?,presetId: freezed == presetId ? _self.presetId : presetId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,byUserId: freezed == byUserId ? _self.byUserId : byUserId // ignore: cast_nullable_to_non_nullable
as String?,approvedByUserId: freezed == approvedByUserId ? _self.approvedByUserId : approvedByUserId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppliedDiscountDto].
extension AppliedDiscountDtoPatterns on AppliedDiscountDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppliedDiscountDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppliedDiscountDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppliedDiscountDto value)  $default,){
final _that = this;
switch (_that) {
case _AppliedDiscountDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppliedDiscountDto value)?  $default,){
final _that = this;
switch (_that) {
case _AppliedDiscountDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? ticketId,  String? presetId,  String name,  String kind,  int value,  int amount,  String? byUserId,  String? approvedByUserId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppliedDiscountDto() when $default != null:
return $default(_that.id,_that.ticketId,_that.presetId,_that.name,_that.kind,_that.value,_that.amount,_that.byUserId,_that.approvedByUserId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? ticketId,  String? presetId,  String name,  String kind,  int value,  int amount,  String? byUserId,  String? approvedByUserId)  $default,) {final _that = this;
switch (_that) {
case _AppliedDiscountDto():
return $default(_that.id,_that.ticketId,_that.presetId,_that.name,_that.kind,_that.value,_that.amount,_that.byUserId,_that.approvedByUserId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? ticketId,  String? presetId,  String name,  String kind,  int value,  int amount,  String? byUserId,  String? approvedByUserId)?  $default,) {final _that = this;
switch (_that) {
case _AppliedDiscountDto() when $default != null:
return $default(_that.id,_that.ticketId,_that.presetId,_that.name,_that.kind,_that.value,_that.amount,_that.byUserId,_that.approvedByUserId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppliedDiscountDto implements AppliedDiscountDto {
  const _AppliedDiscountDto({required this.id, this.ticketId, this.presetId, this.name = '', this.kind = 'percent', this.value = 0, this.amount = 0, this.byUserId, this.approvedByUserId});
  factory _AppliedDiscountDto.fromJson(Map<String, dynamic> json) => _$AppliedDiscountDtoFromJson(json);

@override final  String id;
@override final  String? ticketId;
@override final  String? presetId;
@override@JsonKey() final  String name;
@override@JsonKey() final  String kind;
@override@JsonKey() final  int value;
@override@JsonKey() final  int amount;
@override final  String? byUserId;
@override final  String? approvedByUserId;

/// Create a copy of AppliedDiscountDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppliedDiscountDtoCopyWith<_AppliedDiscountDto> get copyWith => __$AppliedDiscountDtoCopyWithImpl<_AppliedDiscountDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppliedDiscountDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppliedDiscountDto&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.presetId, presetId) || other.presetId == presetId)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.value, value) || other.value == value)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.byUserId, byUserId) || other.byUserId == byUserId)&&(identical(other.approvedByUserId, approvedByUserId) || other.approvedByUserId == approvedByUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticketId,presetId,name,kind,value,amount,byUserId,approvedByUserId);

@override
String toString() {
  return 'AppliedDiscountDto(id: $id, ticketId: $ticketId, presetId: $presetId, name: $name, kind: $kind, value: $value, amount: $amount, byUserId: $byUserId, approvedByUserId: $approvedByUserId)';
}


}

/// @nodoc
abstract mixin class _$AppliedDiscountDtoCopyWith<$Res> implements $AppliedDiscountDtoCopyWith<$Res> {
  factory _$AppliedDiscountDtoCopyWith(_AppliedDiscountDto value, $Res Function(_AppliedDiscountDto) _then) = __$AppliedDiscountDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? ticketId, String? presetId, String name, String kind, int value, int amount, String? byUserId, String? approvedByUserId
});




}
/// @nodoc
class __$AppliedDiscountDtoCopyWithImpl<$Res>
    implements _$AppliedDiscountDtoCopyWith<$Res> {
  __$AppliedDiscountDtoCopyWithImpl(this._self, this._then);

  final _AppliedDiscountDto _self;
  final $Res Function(_AppliedDiscountDto) _then;

/// Create a copy of AppliedDiscountDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ticketId = freezed,Object? presetId = freezed,Object? name = null,Object? kind = null,Object? value = null,Object? amount = null,Object? byUserId = freezed,Object? approvedByUserId = freezed,}) {
  return _then(_AppliedDiscountDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticketId: freezed == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String?,presetId: freezed == presetId ? _self.presetId : presetId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,byUserId: freezed == byUserId ? _self.byUserId : byUserId // ignore: cast_nullable_to_non_nullable
as String?,approvedByUserId: freezed == approvedByUserId ? _self.approvedByUserId : approvedByUserId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
