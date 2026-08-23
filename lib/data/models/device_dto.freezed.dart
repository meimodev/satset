// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceDto {

 String get id; String get label; DateTime get pairedAt; bool get revoked; DateTime? get lastSessionAt; String? get lastSessionUserId; bool get sessionActive;
/// Create a copy of DeviceDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceDtoCopyWith<DeviceDto> get copyWith => _$DeviceDtoCopyWithImpl<DeviceDto>(this as DeviceDto, _$identity);

  /// Serializes this DeviceDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.pairedAt, pairedAt) || other.pairedAt == pairedAt)&&(identical(other.revoked, revoked) || other.revoked == revoked)&&(identical(other.lastSessionAt, lastSessionAt) || other.lastSessionAt == lastSessionAt)&&(identical(other.lastSessionUserId, lastSessionUserId) || other.lastSessionUserId == lastSessionUserId)&&(identical(other.sessionActive, sessionActive) || other.sessionActive == sessionActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,pairedAt,revoked,lastSessionAt,lastSessionUserId,sessionActive);

@override
String toString() {
  return 'DeviceDto(id: $id, label: $label, pairedAt: $pairedAt, revoked: $revoked, lastSessionAt: $lastSessionAt, lastSessionUserId: $lastSessionUserId, sessionActive: $sessionActive)';
}


}

/// @nodoc
abstract mixin class $DeviceDtoCopyWith<$Res>  {
  factory $DeviceDtoCopyWith(DeviceDto value, $Res Function(DeviceDto) _then) = _$DeviceDtoCopyWithImpl;
@useResult
$Res call({
 String id, String label, DateTime pairedAt, bool revoked, DateTime? lastSessionAt, String? lastSessionUserId, bool sessionActive
});




}
/// @nodoc
class _$DeviceDtoCopyWithImpl<$Res>
    implements $DeviceDtoCopyWith<$Res> {
  _$DeviceDtoCopyWithImpl(this._self, this._then);

  final DeviceDto _self;
  final $Res Function(DeviceDto) _then;

/// Create a copy of DeviceDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? pairedAt = null,Object? revoked = null,Object? lastSessionAt = freezed,Object? lastSessionUserId = freezed,Object? sessionActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,pairedAt: null == pairedAt ? _self.pairedAt : pairedAt // ignore: cast_nullable_to_non_nullable
as DateTime,revoked: null == revoked ? _self.revoked : revoked // ignore: cast_nullable_to_non_nullable
as bool,lastSessionAt: freezed == lastSessionAt ? _self.lastSessionAt : lastSessionAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSessionUserId: freezed == lastSessionUserId ? _self.lastSessionUserId : lastSessionUserId // ignore: cast_nullable_to_non_nullable
as String?,sessionActive: null == sessionActive ? _self.sessionActive : sessionActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceDto].
extension DeviceDtoPatterns on DeviceDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceDto value)  $default,){
final _that = this;
switch (_that) {
case _DeviceDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceDto value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  DateTime pairedAt,  bool revoked,  DateTime? lastSessionAt,  String? lastSessionUserId,  bool sessionActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceDto() when $default != null:
return $default(_that.id,_that.label,_that.pairedAt,_that.revoked,_that.lastSessionAt,_that.lastSessionUserId,_that.sessionActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  DateTime pairedAt,  bool revoked,  DateTime? lastSessionAt,  String? lastSessionUserId,  bool sessionActive)  $default,) {final _that = this;
switch (_that) {
case _DeviceDto():
return $default(_that.id,_that.label,_that.pairedAt,_that.revoked,_that.lastSessionAt,_that.lastSessionUserId,_that.sessionActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  DateTime pairedAt,  bool revoked,  DateTime? lastSessionAt,  String? lastSessionUserId,  bool sessionActive)?  $default,) {final _that = this;
switch (_that) {
case _DeviceDto() when $default != null:
return $default(_that.id,_that.label,_that.pairedAt,_that.revoked,_that.lastSessionAt,_that.lastSessionUserId,_that.sessionActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceDto implements DeviceDto {
  const _DeviceDto({required this.id, required this.label, required this.pairedAt, this.revoked = false, this.lastSessionAt, this.lastSessionUserId, this.sessionActive = false});
  factory _DeviceDto.fromJson(Map<String, dynamic> json) => _$DeviceDtoFromJson(json);

@override final  String id;
@override final  String label;
@override final  DateTime pairedAt;
@override@JsonKey() final  bool revoked;
@override final  DateTime? lastSessionAt;
@override final  String? lastSessionUserId;
@override@JsonKey() final  bool sessionActive;

/// Create a copy of DeviceDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceDtoCopyWith<_DeviceDto> get copyWith => __$DeviceDtoCopyWithImpl<_DeviceDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.pairedAt, pairedAt) || other.pairedAt == pairedAt)&&(identical(other.revoked, revoked) || other.revoked == revoked)&&(identical(other.lastSessionAt, lastSessionAt) || other.lastSessionAt == lastSessionAt)&&(identical(other.lastSessionUserId, lastSessionUserId) || other.lastSessionUserId == lastSessionUserId)&&(identical(other.sessionActive, sessionActive) || other.sessionActive == sessionActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,pairedAt,revoked,lastSessionAt,lastSessionUserId,sessionActive);

@override
String toString() {
  return 'DeviceDto(id: $id, label: $label, pairedAt: $pairedAt, revoked: $revoked, lastSessionAt: $lastSessionAt, lastSessionUserId: $lastSessionUserId, sessionActive: $sessionActive)';
}


}

/// @nodoc
abstract mixin class _$DeviceDtoCopyWith<$Res> implements $DeviceDtoCopyWith<$Res> {
  factory _$DeviceDtoCopyWith(_DeviceDto value, $Res Function(_DeviceDto) _then) = __$DeviceDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, DateTime pairedAt, bool revoked, DateTime? lastSessionAt, String? lastSessionUserId, bool sessionActive
});




}
/// @nodoc
class __$DeviceDtoCopyWithImpl<$Res>
    implements _$DeviceDtoCopyWith<$Res> {
  __$DeviceDtoCopyWithImpl(this._self, this._then);

  final _DeviceDto _self;
  final $Res Function(_DeviceDto) _then;

/// Create a copy of DeviceDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? pairedAt = null,Object? revoked = null,Object? lastSessionAt = freezed,Object? lastSessionUserId = freezed,Object? sessionActive = null,}) {
  return _then(_DeviceDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,pairedAt: null == pairedAt ? _self.pairedAt : pairedAt // ignore: cast_nullable_to_non_nullable
as DateTime,revoked: null == revoked ? _self.revoked : revoked // ignore: cast_nullable_to_non_nullable
as bool,lastSessionAt: freezed == lastSessionAt ? _self.lastSessionAt : lastSessionAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSessionUserId: freezed == lastSessionUserId ? _self.lastSessionUserId : lastSessionUserId // ignore: cast_nullable_to_non_nullable
as String?,sessionActive: null == sessionActive ? _self.sessionActive : sessionActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
