// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pair_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PairClaimResponseDto {

 String get deviceToken; String get fingerprint; String get serverPublicKey;
/// Create a copy of PairClaimResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PairClaimResponseDtoCopyWith<PairClaimResponseDto> get copyWith => _$PairClaimResponseDtoCopyWithImpl<PairClaimResponseDto>(this as PairClaimResponseDto, _$identity);

  /// Serializes this PairClaimResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PairClaimResponseDto&&(identical(other.deviceToken, deviceToken) || other.deviceToken == deviceToken)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&(identical(other.serverPublicKey, serverPublicKey) || other.serverPublicKey == serverPublicKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceToken,fingerprint,serverPublicKey);

@override
String toString() {
  return 'PairClaimResponseDto(deviceToken: $deviceToken, fingerprint: $fingerprint, serverPublicKey: $serverPublicKey)';
}


}

/// @nodoc
abstract mixin class $PairClaimResponseDtoCopyWith<$Res>  {
  factory $PairClaimResponseDtoCopyWith(PairClaimResponseDto value, $Res Function(PairClaimResponseDto) _then) = _$PairClaimResponseDtoCopyWithImpl;
@useResult
$Res call({
 String deviceToken, String fingerprint, String serverPublicKey
});




}
/// @nodoc
class _$PairClaimResponseDtoCopyWithImpl<$Res>
    implements $PairClaimResponseDtoCopyWith<$Res> {
  _$PairClaimResponseDtoCopyWithImpl(this._self, this._then);

  final PairClaimResponseDto _self;
  final $Res Function(PairClaimResponseDto) _then;

/// Create a copy of PairClaimResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceToken = null,Object? fingerprint = null,Object? serverPublicKey = null,}) {
  return _then(_self.copyWith(
deviceToken: null == deviceToken ? _self.deviceToken : deviceToken // ignore: cast_nullable_to_non_nullable
as String,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String,serverPublicKey: null == serverPublicKey ? _self.serverPublicKey : serverPublicKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PairClaimResponseDto].
extension PairClaimResponseDtoPatterns on PairClaimResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PairClaimResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PairClaimResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PairClaimResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _PairClaimResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PairClaimResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _PairClaimResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceToken,  String fingerprint,  String serverPublicKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PairClaimResponseDto() when $default != null:
return $default(_that.deviceToken,_that.fingerprint,_that.serverPublicKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceToken,  String fingerprint,  String serverPublicKey)  $default,) {final _that = this;
switch (_that) {
case _PairClaimResponseDto():
return $default(_that.deviceToken,_that.fingerprint,_that.serverPublicKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceToken,  String fingerprint,  String serverPublicKey)?  $default,) {final _that = this;
switch (_that) {
case _PairClaimResponseDto() when $default != null:
return $default(_that.deviceToken,_that.fingerprint,_that.serverPublicKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PairClaimResponseDto implements PairClaimResponseDto {
  const _PairClaimResponseDto({required this.deviceToken, required this.fingerprint, required this.serverPublicKey});
  factory _PairClaimResponseDto.fromJson(Map<String, dynamic> json) => _$PairClaimResponseDtoFromJson(json);

@override final  String deviceToken;
@override final  String fingerprint;
@override final  String serverPublicKey;

/// Create a copy of PairClaimResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PairClaimResponseDtoCopyWith<_PairClaimResponseDto> get copyWith => __$PairClaimResponseDtoCopyWithImpl<_PairClaimResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PairClaimResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PairClaimResponseDto&&(identical(other.deviceToken, deviceToken) || other.deviceToken == deviceToken)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&(identical(other.serverPublicKey, serverPublicKey) || other.serverPublicKey == serverPublicKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceToken,fingerprint,serverPublicKey);

@override
String toString() {
  return 'PairClaimResponseDto(deviceToken: $deviceToken, fingerprint: $fingerprint, serverPublicKey: $serverPublicKey)';
}


}

/// @nodoc
abstract mixin class _$PairClaimResponseDtoCopyWith<$Res> implements $PairClaimResponseDtoCopyWith<$Res> {
  factory _$PairClaimResponseDtoCopyWith(_PairClaimResponseDto value, $Res Function(_PairClaimResponseDto) _then) = __$PairClaimResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String deviceToken, String fingerprint, String serverPublicKey
});




}
/// @nodoc
class __$PairClaimResponseDtoCopyWithImpl<$Res>
    implements _$PairClaimResponseDtoCopyWith<$Res> {
  __$PairClaimResponseDtoCopyWithImpl(this._self, this._then);

  final _PairClaimResponseDto _self;
  final $Res Function(_PairClaimResponseDto) _then;

/// Create a copy of PairClaimResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceToken = null,Object? fingerprint = null,Object? serverPublicKey = null,}) {
  return _then(_PairClaimResponseDto(
deviceToken: null == deviceToken ? _self.deviceToken : deviceToken // ignore: cast_nullable_to_non_nullable
as String,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String,serverPublicKey: null == serverPublicKey ? _self.serverPublicKey : serverPublicKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
