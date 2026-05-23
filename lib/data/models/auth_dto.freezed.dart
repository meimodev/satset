// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PinLoginRequestDto _$PinLoginRequestDtoFromJson(Map<String, dynamic> json) {
  return _PinLoginRequestDto.fromJson(json);
}

/// @nodoc
mixin _$PinLoginRequestDto {
  String get pin => throw _privateConstructorUsedError;
  String get deviceId => throw _privateConstructorUsedError;

  /// Serializes this PinLoginRequestDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PinLoginRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PinLoginRequestDtoCopyWith<PinLoginRequestDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PinLoginRequestDtoCopyWith<$Res> {
  factory $PinLoginRequestDtoCopyWith(
    PinLoginRequestDto value,
    $Res Function(PinLoginRequestDto) then,
  ) = _$PinLoginRequestDtoCopyWithImpl<$Res, PinLoginRequestDto>;
  @useResult
  $Res call({String pin, String deviceId});
}

/// @nodoc
class _$PinLoginRequestDtoCopyWithImpl<$Res, $Val extends PinLoginRequestDto>
    implements $PinLoginRequestDtoCopyWith<$Res> {
  _$PinLoginRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PinLoginRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pin = null, Object? deviceId = null}) {
    return _then(
      _value.copyWith(
            pin: null == pin
                ? _value.pin
                : pin // ignore: cast_nullable_to_non_nullable
                      as String,
            deviceId: null == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PinLoginRequestDtoImplCopyWith<$Res>
    implements $PinLoginRequestDtoCopyWith<$Res> {
  factory _$$PinLoginRequestDtoImplCopyWith(
    _$PinLoginRequestDtoImpl value,
    $Res Function(_$PinLoginRequestDtoImpl) then,
  ) = __$$PinLoginRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String pin, String deviceId});
}

/// @nodoc
class __$$PinLoginRequestDtoImplCopyWithImpl<$Res>
    extends _$PinLoginRequestDtoCopyWithImpl<$Res, _$PinLoginRequestDtoImpl>
    implements _$$PinLoginRequestDtoImplCopyWith<$Res> {
  __$$PinLoginRequestDtoImplCopyWithImpl(
    _$PinLoginRequestDtoImpl _value,
    $Res Function(_$PinLoginRequestDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PinLoginRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pin = null, Object? deviceId = null}) {
    return _then(
      _$PinLoginRequestDtoImpl(
        pin: null == pin
            ? _value.pin
            : pin // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PinLoginRequestDtoImpl implements _PinLoginRequestDto {
  const _$PinLoginRequestDtoImpl({required this.pin, required this.deviceId});

  factory _$PinLoginRequestDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PinLoginRequestDtoImplFromJson(json);

  @override
  final String pin;
  @override
  final String deviceId;

  @override
  String toString() {
    return 'PinLoginRequestDto(pin: $pin, deviceId: $deviceId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PinLoginRequestDtoImpl &&
            (identical(other.pin, pin) || other.pin == pin) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pin, deviceId);

  /// Create a copy of PinLoginRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PinLoginRequestDtoImplCopyWith<_$PinLoginRequestDtoImpl> get copyWith =>
      __$$PinLoginRequestDtoImplCopyWithImpl<_$PinLoginRequestDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PinLoginRequestDtoImplToJson(this);
  }
}

abstract class _PinLoginRequestDto implements PinLoginRequestDto {
  const factory _PinLoginRequestDto({
    required final String pin,
    required final String deviceId,
  }) = _$PinLoginRequestDtoImpl;

  factory _PinLoginRequestDto.fromJson(Map<String, dynamic> json) =
      _$PinLoginRequestDtoImpl.fromJson;

  @override
  String get pin;
  @override
  String get deviceId;

  /// Create a copy of PinLoginRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PinLoginRequestDtoImplCopyWith<_$PinLoginRequestDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SessionDto _$SessionDtoFromJson(Map<String, dynamic> json) {
  return _SessionDto.fromJson(json);
}

/// @nodoc
mixin _$SessionDto {
  String get token => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get roleId => throw _privateConstructorUsedError;
  List<String> get capabilities => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;

  /// Serializes this SessionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SessionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionDtoCopyWith<SessionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionDtoCopyWith<$Res> {
  factory $SessionDtoCopyWith(
    SessionDto value,
    $Res Function(SessionDto) then,
  ) = _$SessionDtoCopyWithImpl<$Res, SessionDto>;
  @useResult
  $Res call({
    String token,
    String userId,
    String roleId,
    List<String> capabilities,
    DateTime expiresAt,
  });
}

/// @nodoc
class _$SessionDtoCopyWithImpl<$Res, $Val extends SessionDto>
    implements $SessionDtoCopyWith<$Res> {
  _$SessionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? userId = null,
    Object? roleId = null,
    Object? capabilities = null,
    Object? expiresAt = null,
  }) {
    return _then(
      _value.copyWith(
            token: null == token
                ? _value.token
                : token // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            roleId: null == roleId
                ? _value.roleId
                : roleId // ignore: cast_nullable_to_non_nullable
                      as String,
            capabilities: null == capabilities
                ? _value.capabilities
                : capabilities // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            expiresAt: null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SessionDtoImplCopyWith<$Res>
    implements $SessionDtoCopyWith<$Res> {
  factory _$$SessionDtoImplCopyWith(
    _$SessionDtoImpl value,
    $Res Function(_$SessionDtoImpl) then,
  ) = __$$SessionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String token,
    String userId,
    String roleId,
    List<String> capabilities,
    DateTime expiresAt,
  });
}

/// @nodoc
class __$$SessionDtoImplCopyWithImpl<$Res>
    extends _$SessionDtoCopyWithImpl<$Res, _$SessionDtoImpl>
    implements _$$SessionDtoImplCopyWith<$Res> {
  __$$SessionDtoImplCopyWithImpl(
    _$SessionDtoImpl _value,
    $Res Function(_$SessionDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SessionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? userId = null,
    Object? roleId = null,
    Object? capabilities = null,
    Object? expiresAt = null,
  }) {
    return _then(
      _$SessionDtoImpl(
        token: null == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        roleId: null == roleId
            ? _value.roleId
            : roleId // ignore: cast_nullable_to_non_nullable
                  as String,
        capabilities: null == capabilities
            ? _value._capabilities
            : capabilities // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        expiresAt: null == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionDtoImpl implements _SessionDto {
  const _$SessionDtoImpl({
    required this.token,
    required this.userId,
    required this.roleId,
    required final List<String> capabilities,
    required this.expiresAt,
  }) : _capabilities = capabilities;

  factory _$SessionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionDtoImplFromJson(json);

  @override
  final String token;
  @override
  final String userId;
  @override
  final String roleId;
  final List<String> _capabilities;
  @override
  List<String> get capabilities {
    if (_capabilities is EqualUnmodifiableListView) return _capabilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_capabilities);
  }

  @override
  final DateTime expiresAt;

  @override
  String toString() {
    return 'SessionDto(token: $token, userId: $userId, roleId: $roleId, capabilities: $capabilities, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionDtoImpl &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.roleId, roleId) || other.roleId == roleId) &&
            const DeepCollectionEquality().equals(
              other._capabilities,
              _capabilities,
            ) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    token,
    userId,
    roleId,
    const DeepCollectionEquality().hash(_capabilities),
    expiresAt,
  );

  /// Create a copy of SessionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionDtoImplCopyWith<_$SessionDtoImpl> get copyWith =>
      __$$SessionDtoImplCopyWithImpl<_$SessionDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionDtoImplToJson(this);
  }
}

abstract class _SessionDto implements SessionDto {
  const factory _SessionDto({
    required final String token,
    required final String userId,
    required final String roleId,
    required final List<String> capabilities,
    required final DateTime expiresAt,
  }) = _$SessionDtoImpl;

  factory _SessionDto.fromJson(Map<String, dynamic> json) =
      _$SessionDtoImpl.fromJson;

  @override
  String get token;
  @override
  String get userId;
  @override
  String get roleId;
  @override
  List<String> get capabilities;
  @override
  DateTime get expiresAt;

  /// Create a copy of SessionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionDtoImplCopyWith<_$SessionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MeDto _$MeDtoFromJson(Map<String, dynamic> json) {
  return _MeDto.fromJson(json);
}

/// @nodoc
mixin _$MeDto {
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get initials => throw _privateConstructorUsedError;
  String get roleId => throw _privateConstructorUsedError;
  String? get zoneAssigned => throw _privateConstructorUsedError;
  List<String> get capabilities => throw _privateConstructorUsedError;

  /// Serializes this MeDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MeDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MeDtoCopyWith<MeDto> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeDtoCopyWith<$Res> {
  factory $MeDtoCopyWith(MeDto value, $Res Function(MeDto) then) =
      _$MeDtoCopyWithImpl<$Res, MeDto>;
  @useResult
  $Res call({
    String userId,
    String name,
    String initials,
    String roleId,
    String? zoneAssigned,
    List<String> capabilities,
  });
}

/// @nodoc
class _$MeDtoCopyWithImpl<$Res, $Val extends MeDto>
    implements $MeDtoCopyWith<$Res> {
  _$MeDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MeDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? name = null,
    Object? initials = null,
    Object? roleId = null,
    Object? zoneAssigned = freezed,
    Object? capabilities = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            initials: null == initials
                ? _value.initials
                : initials // ignore: cast_nullable_to_non_nullable
                      as String,
            roleId: null == roleId
                ? _value.roleId
                : roleId // ignore: cast_nullable_to_non_nullable
                      as String,
            zoneAssigned: freezed == zoneAssigned
                ? _value.zoneAssigned
                : zoneAssigned // ignore: cast_nullable_to_non_nullable
                      as String?,
            capabilities: null == capabilities
                ? _value.capabilities
                : capabilities // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MeDtoImplCopyWith<$Res> implements $MeDtoCopyWith<$Res> {
  factory _$$MeDtoImplCopyWith(
    _$MeDtoImpl value,
    $Res Function(_$MeDtoImpl) then,
  ) = __$$MeDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String name,
    String initials,
    String roleId,
    String? zoneAssigned,
    List<String> capabilities,
  });
}

/// @nodoc
class __$$MeDtoImplCopyWithImpl<$Res>
    extends _$MeDtoCopyWithImpl<$Res, _$MeDtoImpl>
    implements _$$MeDtoImplCopyWith<$Res> {
  __$$MeDtoImplCopyWithImpl(
    _$MeDtoImpl _value,
    $Res Function(_$MeDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MeDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? name = null,
    Object? initials = null,
    Object? roleId = null,
    Object? zoneAssigned = freezed,
    Object? capabilities = null,
  }) {
    return _then(
      _$MeDtoImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        initials: null == initials
            ? _value.initials
            : initials // ignore: cast_nullable_to_non_nullable
                  as String,
        roleId: null == roleId
            ? _value.roleId
            : roleId // ignore: cast_nullable_to_non_nullable
                  as String,
        zoneAssigned: freezed == zoneAssigned
            ? _value.zoneAssigned
            : zoneAssigned // ignore: cast_nullable_to_non_nullable
                  as String?,
        capabilities: null == capabilities
            ? _value._capabilities
            : capabilities // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MeDtoImpl implements _MeDto {
  const _$MeDtoImpl({
    required this.userId,
    required this.name,
    required this.initials,
    required this.roleId,
    required this.zoneAssigned,
    required final List<String> capabilities,
  }) : _capabilities = capabilities;

  factory _$MeDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MeDtoImplFromJson(json);

  @override
  final String userId;
  @override
  final String name;
  @override
  final String initials;
  @override
  final String roleId;
  @override
  final String? zoneAssigned;
  final List<String> _capabilities;
  @override
  List<String> get capabilities {
    if (_capabilities is EqualUnmodifiableListView) return _capabilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_capabilities);
  }

  @override
  String toString() {
    return 'MeDto(userId: $userId, name: $name, initials: $initials, roleId: $roleId, zoneAssigned: $zoneAssigned, capabilities: $capabilities)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeDtoImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.initials, initials) ||
                other.initials == initials) &&
            (identical(other.roleId, roleId) || other.roleId == roleId) &&
            (identical(other.zoneAssigned, zoneAssigned) ||
                other.zoneAssigned == zoneAssigned) &&
            const DeepCollectionEquality().equals(
              other._capabilities,
              _capabilities,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    name,
    initials,
    roleId,
    zoneAssigned,
    const DeepCollectionEquality().hash(_capabilities),
  );

  /// Create a copy of MeDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MeDtoImplCopyWith<_$MeDtoImpl> get copyWith =>
      __$$MeDtoImplCopyWithImpl<_$MeDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MeDtoImplToJson(this);
  }
}

abstract class _MeDto implements MeDto {
  const factory _MeDto({
    required final String userId,
    required final String name,
    required final String initials,
    required final String roleId,
    required final String? zoneAssigned,
    required final List<String> capabilities,
  }) = _$MeDtoImpl;

  factory _MeDto.fromJson(Map<String, dynamic> json) = _$MeDtoImpl.fromJson;

  @override
  String get userId;
  @override
  String get name;
  @override
  String get initials;
  @override
  String get roleId;
  @override
  String? get zoneAssigned;
  @override
  List<String> get capabilities;

  /// Create a copy of MeDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MeDtoImplCopyWith<_$MeDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
