// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ws_event_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WsEventDto {

 int get v; String get type; Map<String, dynamic> get payload; DateTime get ts;
/// Create a copy of WsEventDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WsEventDtoCopyWith<WsEventDto> get copyWith => _$WsEventDtoCopyWithImpl<WsEventDto>(this as WsEventDto, _$identity);

  /// Serializes this WsEventDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WsEventDto&&(identical(other.v, v) || other.v == v)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.ts, ts) || other.ts == ts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,v,type,const DeepCollectionEquality().hash(payload),ts);

@override
String toString() {
  return 'WsEventDto(v: $v, type: $type, payload: $payload, ts: $ts)';
}


}

/// @nodoc
abstract mixin class $WsEventDtoCopyWith<$Res>  {
  factory $WsEventDtoCopyWith(WsEventDto value, $Res Function(WsEventDto) _then) = _$WsEventDtoCopyWithImpl;
@useResult
$Res call({
 int v, String type, Map<String, dynamic> payload, DateTime ts
});




}
/// @nodoc
class _$WsEventDtoCopyWithImpl<$Res>
    implements $WsEventDtoCopyWith<$Res> {
  _$WsEventDtoCopyWithImpl(this._self, this._then);

  final WsEventDto _self;
  final $Res Function(WsEventDto) _then;

/// Create a copy of WsEventDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? v = null,Object? type = null,Object? payload = null,Object? ts = null,}) {
  return _then(_self.copyWith(
v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,ts: null == ts ? _self.ts : ts // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WsEventDto].
extension WsEventDtoPatterns on WsEventDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WsEventDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WsEventDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WsEventDto value)  $default,){
final _that = this;
switch (_that) {
case _WsEventDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WsEventDto value)?  $default,){
final _that = this;
switch (_that) {
case _WsEventDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int v,  String type,  Map<String, dynamic> payload,  DateTime ts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WsEventDto() when $default != null:
return $default(_that.v,_that.type,_that.payload,_that.ts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int v,  String type,  Map<String, dynamic> payload,  DateTime ts)  $default,) {final _that = this;
switch (_that) {
case _WsEventDto():
return $default(_that.v,_that.type,_that.payload,_that.ts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int v,  String type,  Map<String, dynamic> payload,  DateTime ts)?  $default,) {final _that = this;
switch (_that) {
case _WsEventDto() when $default != null:
return $default(_that.v,_that.type,_that.payload,_that.ts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WsEventDto implements WsEventDto {
  const _WsEventDto({this.v = 1, required this.type, final  Map<String, dynamic> payload = const <String, dynamic>{}, required this.ts}): _payload = payload;
  factory _WsEventDto.fromJson(Map<String, dynamic> json) => _$WsEventDtoFromJson(json);

@override@JsonKey() final  int v;
@override final  String type;
 final  Map<String, dynamic> _payload;
@override@JsonKey() Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  DateTime ts;

/// Create a copy of WsEventDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WsEventDtoCopyWith<_WsEventDto> get copyWith => __$WsEventDtoCopyWithImpl<_WsEventDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WsEventDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WsEventDto&&(identical(other.v, v) || other.v == v)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.ts, ts) || other.ts == ts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,v,type,const DeepCollectionEquality().hash(_payload),ts);

@override
String toString() {
  return 'WsEventDto(v: $v, type: $type, payload: $payload, ts: $ts)';
}


}

/// @nodoc
abstract mixin class _$WsEventDtoCopyWith<$Res> implements $WsEventDtoCopyWith<$Res> {
  factory _$WsEventDtoCopyWith(_WsEventDto value, $Res Function(_WsEventDto) _then) = __$WsEventDtoCopyWithImpl;
@override @useResult
$Res call({
 int v, String type, Map<String, dynamic> payload, DateTime ts
});




}
/// @nodoc
class __$WsEventDtoCopyWithImpl<$Res>
    implements _$WsEventDtoCopyWith<$Res> {
  __$WsEventDtoCopyWithImpl(this._self, this._then);

  final _WsEventDto _self;
  final $Res Function(_WsEventDto) _then;

/// Create a copy of WsEventDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? v = null,Object? type = null,Object? payload = null,Object? ts = null,}) {
  return _then(_WsEventDto(
v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,ts: null == ts ? _self.ts : ts // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
