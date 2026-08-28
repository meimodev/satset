// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PinLoginRequestDto {

 String get pin; String get deviceId;
/// Create a copy of PinLoginRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PinLoginRequestDtoCopyWith<PinLoginRequestDto> get copyWith => _$PinLoginRequestDtoCopyWithImpl<PinLoginRequestDto>(this as PinLoginRequestDto, _$identity);

  /// Serializes this PinLoginRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinLoginRequestDto&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pin,deviceId);

@override
String toString() {
  return 'PinLoginRequestDto(pin: $pin, deviceId: $deviceId)';
}


}

/// @nodoc
abstract mixin class $PinLoginRequestDtoCopyWith<$Res>  {
  factory $PinLoginRequestDtoCopyWith(PinLoginRequestDto value, $Res Function(PinLoginRequestDto) _then) = _$PinLoginRequestDtoCopyWithImpl;
@useResult
$Res call({
 String pin, String deviceId
});




}
/// @nodoc
class _$PinLoginRequestDtoCopyWithImpl<$Res>
    implements $PinLoginRequestDtoCopyWith<$Res> {
  _$PinLoginRequestDtoCopyWithImpl(this._self, this._then);

  final PinLoginRequestDto _self;
  final $Res Function(PinLoginRequestDto) _then;

/// Create a copy of PinLoginRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pin = null,Object? deviceId = null,}) {
  return _then(_self.copyWith(
pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PinLoginRequestDto].
extension PinLoginRequestDtoPatterns on PinLoginRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PinLoginRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PinLoginRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PinLoginRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _PinLoginRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PinLoginRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _PinLoginRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String pin,  String deviceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PinLoginRequestDto() when $default != null:
return $default(_that.pin,_that.deviceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String pin,  String deviceId)  $default,) {final _that = this;
switch (_that) {
case _PinLoginRequestDto():
return $default(_that.pin,_that.deviceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String pin,  String deviceId)?  $default,) {final _that = this;
switch (_that) {
case _PinLoginRequestDto() when $default != null:
return $default(_that.pin,_that.deviceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PinLoginRequestDto implements PinLoginRequestDto {
  const _PinLoginRequestDto({required this.pin, required this.deviceId});
  factory _PinLoginRequestDto.fromJson(Map<String, dynamic> json) => _$PinLoginRequestDtoFromJson(json);

@override final  String pin;
@override final  String deviceId;

/// Create a copy of PinLoginRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PinLoginRequestDtoCopyWith<_PinLoginRequestDto> get copyWith => __$PinLoginRequestDtoCopyWithImpl<_PinLoginRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PinLoginRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PinLoginRequestDto&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pin,deviceId);

@override
String toString() {
  return 'PinLoginRequestDto(pin: $pin, deviceId: $deviceId)';
}


}

/// @nodoc
abstract mixin class _$PinLoginRequestDtoCopyWith<$Res> implements $PinLoginRequestDtoCopyWith<$Res> {
  factory _$PinLoginRequestDtoCopyWith(_PinLoginRequestDto value, $Res Function(_PinLoginRequestDto) _then) = __$PinLoginRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String pin, String deviceId
});




}
/// @nodoc
class __$PinLoginRequestDtoCopyWithImpl<$Res>
    implements _$PinLoginRequestDtoCopyWith<$Res> {
  __$PinLoginRequestDtoCopyWithImpl(this._self, this._then);

  final _PinLoginRequestDto _self;
  final $Res Function(_PinLoginRequestDto) _then;

/// Create a copy of PinLoginRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pin = null,Object? deviceId = null,}) {
  return _then(_PinLoginRequestDto(
pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AdminLoginRequestDto {

 String get email; String get password; String get deviceId;
/// Create a copy of AdminLoginRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminLoginRequestDtoCopyWith<AdminLoginRequestDto> get copyWith => _$AdminLoginRequestDtoCopyWithImpl<AdminLoginRequestDto>(this as AdminLoginRequestDto, _$identity);

  /// Serializes this AdminLoginRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminLoginRequestDto&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password,deviceId);

@override
String toString() {
  return 'AdminLoginRequestDto(email: $email, password: $password, deviceId: $deviceId)';
}


}

/// @nodoc
abstract mixin class $AdminLoginRequestDtoCopyWith<$Res>  {
  factory $AdminLoginRequestDtoCopyWith(AdminLoginRequestDto value, $Res Function(AdminLoginRequestDto) _then) = _$AdminLoginRequestDtoCopyWithImpl;
@useResult
$Res call({
 String email, String password, String deviceId
});




}
/// @nodoc
class _$AdminLoginRequestDtoCopyWithImpl<$Res>
    implements $AdminLoginRequestDtoCopyWith<$Res> {
  _$AdminLoginRequestDtoCopyWithImpl(this._self, this._then);

  final AdminLoginRequestDto _self;
  final $Res Function(AdminLoginRequestDto) _then;

/// Create a copy of AdminLoginRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? password = null,Object? deviceId = null,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminLoginRequestDto].
extension AdminLoginRequestDtoPatterns on AdminLoginRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminLoginRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminLoginRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminLoginRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _AdminLoginRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminLoginRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _AdminLoginRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String password,  String deviceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminLoginRequestDto() when $default != null:
return $default(_that.email,_that.password,_that.deviceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String password,  String deviceId)  $default,) {final _that = this;
switch (_that) {
case _AdminLoginRequestDto():
return $default(_that.email,_that.password,_that.deviceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String password,  String deviceId)?  $default,) {final _that = this;
switch (_that) {
case _AdminLoginRequestDto() when $default != null:
return $default(_that.email,_that.password,_that.deviceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminLoginRequestDto implements AdminLoginRequestDto {
  const _AdminLoginRequestDto({required this.email, required this.password, required this.deviceId});
  factory _AdminLoginRequestDto.fromJson(Map<String, dynamic> json) => _$AdminLoginRequestDtoFromJson(json);

@override final  String email;
@override final  String password;
@override final  String deviceId;

/// Create a copy of AdminLoginRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminLoginRequestDtoCopyWith<_AdminLoginRequestDto> get copyWith => __$AdminLoginRequestDtoCopyWithImpl<_AdminLoginRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminLoginRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminLoginRequestDto&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password,deviceId);

@override
String toString() {
  return 'AdminLoginRequestDto(email: $email, password: $password, deviceId: $deviceId)';
}


}

/// @nodoc
abstract mixin class _$AdminLoginRequestDtoCopyWith<$Res> implements $AdminLoginRequestDtoCopyWith<$Res> {
  factory _$AdminLoginRequestDtoCopyWith(_AdminLoginRequestDto value, $Res Function(_AdminLoginRequestDto) _then) = __$AdminLoginRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String email, String password, String deviceId
});




}
/// @nodoc
class __$AdminLoginRequestDtoCopyWithImpl<$Res>
    implements _$AdminLoginRequestDtoCopyWith<$Res> {
  __$AdminLoginRequestDtoCopyWithImpl(this._self, this._then);

  final _AdminLoginRequestDto _self;
  final $Res Function(_AdminLoginRequestDto) _then;

/// Create a copy of AdminLoginRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,Object? deviceId = null,}) {
  return _then(_AdminLoginRequestDto(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SessionDto {

 String get token; String get userId; String get roleId; List<String> get capabilities; DateTime get expiresAt;
/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionDtoCopyWith<SessionDto> get copyWith => _$SessionDtoCopyWithImpl<SessionDto>(this as SessionDto, _$identity);

  /// Serializes this SessionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionDto&&(identical(other.token, token) || other.token == token)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&const DeepCollectionEquality().equals(other.capabilities, capabilities)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,userId,roleId,const DeepCollectionEquality().hash(capabilities),expiresAt);

@override
String toString() {
  return 'SessionDto(token: $token, userId: $userId, roleId: $roleId, capabilities: $capabilities, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $SessionDtoCopyWith<$Res>  {
  factory $SessionDtoCopyWith(SessionDto value, $Res Function(SessionDto) _then) = _$SessionDtoCopyWithImpl;
@useResult
$Res call({
 String token, String userId, String roleId, List<String> capabilities, DateTime expiresAt
});




}
/// @nodoc
class _$SessionDtoCopyWithImpl<$Res>
    implements $SessionDtoCopyWith<$Res> {
  _$SessionDtoCopyWithImpl(this._self, this._then);

  final SessionDto _self;
  final $Res Function(SessionDto) _then;

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? userId = null,Object? roleId = null,Object? capabilities = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as String,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<String>,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionDto].
extension SessionDtoPatterns on SessionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionDto value)  $default,){
final _that = this;
switch (_that) {
case _SessionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionDto value)?  $default,){
final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  String userId,  String roleId,  List<String> capabilities,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
return $default(_that.token,_that.userId,_that.roleId,_that.capabilities,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  String userId,  String roleId,  List<String> capabilities,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _SessionDto():
return $default(_that.token,_that.userId,_that.roleId,_that.capabilities,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  String userId,  String roleId,  List<String> capabilities,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
return $default(_that.token,_that.userId,_that.roleId,_that.capabilities,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionDto implements SessionDto {
  const _SessionDto({required this.token, required this.userId, required this.roleId, required final  List<String> capabilities, required this.expiresAt}): _capabilities = capabilities;
  factory _SessionDto.fromJson(Map<String, dynamic> json) => _$SessionDtoFromJson(json);

@override final  String token;
@override final  String userId;
@override final  String roleId;
 final  List<String> _capabilities;
@override List<String> get capabilities {
  if (_capabilities is EqualUnmodifiableListView) return _capabilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_capabilities);
}

@override final  DateTime expiresAt;

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionDtoCopyWith<_SessionDto> get copyWith => __$SessionDtoCopyWithImpl<_SessionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionDto&&(identical(other.token, token) || other.token == token)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&const DeepCollectionEquality().equals(other._capabilities, _capabilities)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,userId,roleId,const DeepCollectionEquality().hash(_capabilities),expiresAt);

@override
String toString() {
  return 'SessionDto(token: $token, userId: $userId, roleId: $roleId, capabilities: $capabilities, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$SessionDtoCopyWith<$Res> implements $SessionDtoCopyWith<$Res> {
  factory _$SessionDtoCopyWith(_SessionDto value, $Res Function(_SessionDto) _then) = __$SessionDtoCopyWithImpl;
@override @useResult
$Res call({
 String token, String userId, String roleId, List<String> capabilities, DateTime expiresAt
});




}
/// @nodoc
class __$SessionDtoCopyWithImpl<$Res>
    implements _$SessionDtoCopyWith<$Res> {
  __$SessionDtoCopyWithImpl(this._self, this._then);

  final _SessionDto _self;
  final $Res Function(_SessionDto) _then;

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? userId = null,Object? roleId = null,Object? capabilities = null,Object? expiresAt = null,}) {
  return _then(_SessionDto(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as String,capabilities: null == capabilities ? _self._capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<String>,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$MeDto {

 String get userId; String get name; String get initials; String get roleId; String? get zoneAssigned; List<String> get capabilities; int? get avatarColorHex;/// Start of the caller's open shift, server-authoritative (ADR-0097). Null
/// when they have no open shift — after signing out, or once the
/// business-day boundary has retired a forgotten one.
 String? get shiftStartedAt;/// Whether this host records shifts at all, which is the only thing that
/// makes a null [shiftStartedAt] readable. A host that keeps shifts sends
/// true and its null means *no open shift*; a legacy host omits the field
/// and its null means *no opinion*, so the client falls back to its own
/// `loginAt`. Without the distinction the fallback fires on a retired
/// shift and the app bar counts up against a row the server has closed.
 bool get shiftTracked;
/// Create a copy of MeDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeDtoCopyWith<MeDto> get copyWith => _$MeDtoCopyWithImpl<MeDto>(this as MeDto, _$identity);

  /// Serializes this MeDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.initials, initials) || other.initials == initials)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.zoneAssigned, zoneAssigned) || other.zoneAssigned == zoneAssigned)&&const DeepCollectionEquality().equals(other.capabilities, capabilities)&&(identical(other.avatarColorHex, avatarColorHex) || other.avatarColorHex == avatarColorHex)&&(identical(other.shiftStartedAt, shiftStartedAt) || other.shiftStartedAt == shiftStartedAt)&&(identical(other.shiftTracked, shiftTracked) || other.shiftTracked == shiftTracked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,name,initials,roleId,zoneAssigned,const DeepCollectionEquality().hash(capabilities),avatarColorHex,shiftStartedAt,shiftTracked);

@override
String toString() {
  return 'MeDto(userId: $userId, name: $name, initials: $initials, roleId: $roleId, zoneAssigned: $zoneAssigned, capabilities: $capabilities, avatarColorHex: $avatarColorHex, shiftStartedAt: $shiftStartedAt, shiftTracked: $shiftTracked)';
}


}

/// @nodoc
abstract mixin class $MeDtoCopyWith<$Res>  {
  factory $MeDtoCopyWith(MeDto value, $Res Function(MeDto) _then) = _$MeDtoCopyWithImpl;
@useResult
$Res call({
 String userId, String name, String initials, String roleId, String? zoneAssigned, List<String> capabilities, int? avatarColorHex, String? shiftStartedAt, bool shiftTracked
});




}
/// @nodoc
class _$MeDtoCopyWithImpl<$Res>
    implements $MeDtoCopyWith<$Res> {
  _$MeDtoCopyWithImpl(this._self, this._then);

  final MeDto _self;
  final $Res Function(MeDto) _then;

/// Create a copy of MeDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? name = null,Object? initials = null,Object? roleId = null,Object? zoneAssigned = freezed,Object? capabilities = null,Object? avatarColorHex = freezed,Object? shiftStartedAt = freezed,Object? shiftTracked = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initials: null == initials ? _self.initials : initials // ignore: cast_nullable_to_non_nullable
as String,roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as String,zoneAssigned: freezed == zoneAssigned ? _self.zoneAssigned : zoneAssigned // ignore: cast_nullable_to_non_nullable
as String?,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<String>,avatarColorHex: freezed == avatarColorHex ? _self.avatarColorHex : avatarColorHex // ignore: cast_nullable_to_non_nullable
as int?,shiftStartedAt: freezed == shiftStartedAt ? _self.shiftStartedAt : shiftStartedAt // ignore: cast_nullable_to_non_nullable
as String?,shiftTracked: null == shiftTracked ? _self.shiftTracked : shiftTracked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MeDto].
extension MeDtoPatterns on MeDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeDto value)  $default,){
final _that = this;
switch (_that) {
case _MeDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeDto value)?  $default,){
final _that = this;
switch (_that) {
case _MeDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String name,  String initials,  String roleId,  String? zoneAssigned,  List<String> capabilities,  int? avatarColorHex,  String? shiftStartedAt,  bool shiftTracked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeDto() when $default != null:
return $default(_that.userId,_that.name,_that.initials,_that.roleId,_that.zoneAssigned,_that.capabilities,_that.avatarColorHex,_that.shiftStartedAt,_that.shiftTracked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String name,  String initials,  String roleId,  String? zoneAssigned,  List<String> capabilities,  int? avatarColorHex,  String? shiftStartedAt,  bool shiftTracked)  $default,) {final _that = this;
switch (_that) {
case _MeDto():
return $default(_that.userId,_that.name,_that.initials,_that.roleId,_that.zoneAssigned,_that.capabilities,_that.avatarColorHex,_that.shiftStartedAt,_that.shiftTracked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String name,  String initials,  String roleId,  String? zoneAssigned,  List<String> capabilities,  int? avatarColorHex,  String? shiftStartedAt,  bool shiftTracked)?  $default,) {final _that = this;
switch (_that) {
case _MeDto() when $default != null:
return $default(_that.userId,_that.name,_that.initials,_that.roleId,_that.zoneAssigned,_that.capabilities,_that.avatarColorHex,_that.shiftStartedAt,_that.shiftTracked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeDto implements MeDto {
  const _MeDto({required this.userId, required this.name, required this.initials, required this.roleId, required this.zoneAssigned, required final  List<String> capabilities, this.avatarColorHex, this.shiftStartedAt, this.shiftTracked = false}): _capabilities = capabilities;
  factory _MeDto.fromJson(Map<String, dynamic> json) => _$MeDtoFromJson(json);

@override final  String userId;
@override final  String name;
@override final  String initials;
@override final  String roleId;
@override final  String? zoneAssigned;
 final  List<String> _capabilities;
@override List<String> get capabilities {
  if (_capabilities is EqualUnmodifiableListView) return _capabilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_capabilities);
}

@override final  int? avatarColorHex;
/// Start of the caller's open shift, server-authoritative (ADR-0097). Null
/// when they have no open shift — after signing out, or once the
/// business-day boundary has retired a forgotten one.
@override final  String? shiftStartedAt;
/// Whether this host records shifts at all, which is the only thing that
/// makes a null [shiftStartedAt] readable. A host that keeps shifts sends
/// true and its null means *no open shift*; a legacy host omits the field
/// and its null means *no opinion*, so the client falls back to its own
/// `loginAt`. Without the distinction the fallback fires on a retired
/// shift and the app bar counts up against a row the server has closed.
@override@JsonKey() final  bool shiftTracked;

/// Create a copy of MeDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeDtoCopyWith<_MeDto> get copyWith => __$MeDtoCopyWithImpl<_MeDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.initials, initials) || other.initials == initials)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.zoneAssigned, zoneAssigned) || other.zoneAssigned == zoneAssigned)&&const DeepCollectionEquality().equals(other._capabilities, _capabilities)&&(identical(other.avatarColorHex, avatarColorHex) || other.avatarColorHex == avatarColorHex)&&(identical(other.shiftStartedAt, shiftStartedAt) || other.shiftStartedAt == shiftStartedAt)&&(identical(other.shiftTracked, shiftTracked) || other.shiftTracked == shiftTracked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,name,initials,roleId,zoneAssigned,const DeepCollectionEquality().hash(_capabilities),avatarColorHex,shiftStartedAt,shiftTracked);

@override
String toString() {
  return 'MeDto(userId: $userId, name: $name, initials: $initials, roleId: $roleId, zoneAssigned: $zoneAssigned, capabilities: $capabilities, avatarColorHex: $avatarColorHex, shiftStartedAt: $shiftStartedAt, shiftTracked: $shiftTracked)';
}


}

/// @nodoc
abstract mixin class _$MeDtoCopyWith<$Res> implements $MeDtoCopyWith<$Res> {
  factory _$MeDtoCopyWith(_MeDto value, $Res Function(_MeDto) _then) = __$MeDtoCopyWithImpl;
@override @useResult
$Res call({
 String userId, String name, String initials, String roleId, String? zoneAssigned, List<String> capabilities, int? avatarColorHex, String? shiftStartedAt, bool shiftTracked
});




}
/// @nodoc
class __$MeDtoCopyWithImpl<$Res>
    implements _$MeDtoCopyWith<$Res> {
  __$MeDtoCopyWithImpl(this._self, this._then);

  final _MeDto _self;
  final $Res Function(_MeDto) _then;

/// Create a copy of MeDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? name = null,Object? initials = null,Object? roleId = null,Object? zoneAssigned = freezed,Object? capabilities = null,Object? avatarColorHex = freezed,Object? shiftStartedAt = freezed,Object? shiftTracked = null,}) {
  return _then(_MeDto(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initials: null == initials ? _self.initials : initials // ignore: cast_nullable_to_non_nullable
as String,roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as String,zoneAssigned: freezed == zoneAssigned ? _self.zoneAssigned : zoneAssigned // ignore: cast_nullable_to_non_nullable
as String?,capabilities: null == capabilities ? _self._capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<String>,avatarColorHex: freezed == avatarColorHex ? _self.avatarColorHex : avatarColorHex // ignore: cast_nullable_to_non_nullable
as int?,shiftStartedAt: freezed == shiftStartedAt ? _self.shiftStartedAt : shiftStartedAt // ignore: cast_nullable_to_non_nullable
as String?,shiftTracked: null == shiftTracked ? _self.shiftTracked : shiftTracked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
