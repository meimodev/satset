// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pair_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PairQrPayloadDto _$PairQrPayloadDtoFromJson(Map<String, dynamic> json) {
  return _PairQrPayloadDto.fromJson(json);
}

/// @nodoc
mixin _$PairQrPayloadDto {
  String get host => throw _privateConstructorUsedError;
  int get port => throw _privateConstructorUsedError;
  String get fingerprint => throw _privateConstructorUsedError;
  String get token => throw _privateConstructorUsedError;

  /// Serializes this PairQrPayloadDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PairQrPayloadDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PairQrPayloadDtoCopyWith<PairQrPayloadDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PairQrPayloadDtoCopyWith<$Res> {
  factory $PairQrPayloadDtoCopyWith(
    PairQrPayloadDto value,
    $Res Function(PairQrPayloadDto) then,
  ) = _$PairQrPayloadDtoCopyWithImpl<$Res, PairQrPayloadDto>;
  @useResult
  $Res call({String host, int port, String fingerprint, String token});
}

/// @nodoc
class _$PairQrPayloadDtoCopyWithImpl<$Res, $Val extends PairQrPayloadDto>
    implements $PairQrPayloadDtoCopyWith<$Res> {
  _$PairQrPayloadDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PairQrPayloadDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? host = null,
    Object? port = null,
    Object? fingerprint = null,
    Object? token = null,
  }) {
    return _then(
      _value.copyWith(
            host: null == host
                ? _value.host
                : host // ignore: cast_nullable_to_non_nullable
                      as String,
            port: null == port
                ? _value.port
                : port // ignore: cast_nullable_to_non_nullable
                      as int,
            fingerprint: null == fingerprint
                ? _value.fingerprint
                : fingerprint // ignore: cast_nullable_to_non_nullable
                      as String,
            token: null == token
                ? _value.token
                : token // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PairQrPayloadDtoImplCopyWith<$Res>
    implements $PairQrPayloadDtoCopyWith<$Res> {
  factory _$$PairQrPayloadDtoImplCopyWith(
    _$PairQrPayloadDtoImpl value,
    $Res Function(_$PairQrPayloadDtoImpl) then,
  ) = __$$PairQrPayloadDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String host, int port, String fingerprint, String token});
}

/// @nodoc
class __$$PairQrPayloadDtoImplCopyWithImpl<$Res>
    extends _$PairQrPayloadDtoCopyWithImpl<$Res, _$PairQrPayloadDtoImpl>
    implements _$$PairQrPayloadDtoImplCopyWith<$Res> {
  __$$PairQrPayloadDtoImplCopyWithImpl(
    _$PairQrPayloadDtoImpl _value,
    $Res Function(_$PairQrPayloadDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PairQrPayloadDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? host = null,
    Object? port = null,
    Object? fingerprint = null,
    Object? token = null,
  }) {
    return _then(
      _$PairQrPayloadDtoImpl(
        host: null == host
            ? _value.host
            : host // ignore: cast_nullable_to_non_nullable
                  as String,
        port: null == port
            ? _value.port
            : port // ignore: cast_nullable_to_non_nullable
                  as int,
        fingerprint: null == fingerprint
            ? _value.fingerprint
            : fingerprint // ignore: cast_nullable_to_non_nullable
                  as String,
        token: null == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PairQrPayloadDtoImpl implements _PairQrPayloadDto {
  const _$PairQrPayloadDtoImpl({
    required this.host,
    required this.port,
    required this.fingerprint,
    required this.token,
  });

  factory _$PairQrPayloadDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PairQrPayloadDtoImplFromJson(json);

  @override
  final String host;
  @override
  final int port;
  @override
  final String fingerprint;
  @override
  final String token;

  @override
  String toString() {
    return 'PairQrPayloadDto(host: $host, port: $port, fingerprint: $fingerprint, token: $token)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PairQrPayloadDtoImpl &&
            (identical(other.host, host) || other.host == host) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.fingerprint, fingerprint) ||
                other.fingerprint == fingerprint) &&
            (identical(other.token, token) || other.token == token));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, host, port, fingerprint, token);

  /// Create a copy of PairQrPayloadDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PairQrPayloadDtoImplCopyWith<_$PairQrPayloadDtoImpl> get copyWith =>
      __$$PairQrPayloadDtoImplCopyWithImpl<_$PairQrPayloadDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PairQrPayloadDtoImplToJson(this);
  }
}

abstract class _PairQrPayloadDto implements PairQrPayloadDto {
  const factory _PairQrPayloadDto({
    required final String host,
    required final int port,
    required final String fingerprint,
    required final String token,
  }) = _$PairQrPayloadDtoImpl;

  factory _PairQrPayloadDto.fromJson(Map<String, dynamic> json) =
      _$PairQrPayloadDtoImpl.fromJson;

  @override
  String get host;
  @override
  int get port;
  @override
  String get fingerprint;
  @override
  String get token;

  /// Create a copy of PairQrPayloadDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PairQrPayloadDtoImplCopyWith<_$PairQrPayloadDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PairClaimRequestDto _$PairClaimRequestDtoFromJson(Map<String, dynamic> json) {
  return _PairClaimRequestDto.fromJson(json);
}

/// @nodoc
mixin _$PairClaimRequestDto {
  String get token => throw _privateConstructorUsedError;
  String get deviceId => throw _privateConstructorUsedError;
  String get deviceLabel => throw _privateConstructorUsedError;
  String get publicKey => throw _privateConstructorUsedError;

  /// Serializes this PairClaimRequestDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PairClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PairClaimRequestDtoCopyWith<PairClaimRequestDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PairClaimRequestDtoCopyWith<$Res> {
  factory $PairClaimRequestDtoCopyWith(
    PairClaimRequestDto value,
    $Res Function(PairClaimRequestDto) then,
  ) = _$PairClaimRequestDtoCopyWithImpl<$Res, PairClaimRequestDto>;
  @useResult
  $Res call({
    String token,
    String deviceId,
    String deviceLabel,
    String publicKey,
  });
}

/// @nodoc
class _$PairClaimRequestDtoCopyWithImpl<$Res, $Val extends PairClaimRequestDto>
    implements $PairClaimRequestDtoCopyWith<$Res> {
  _$PairClaimRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PairClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? deviceId = null,
    Object? deviceLabel = null,
    Object? publicKey = null,
  }) {
    return _then(
      _value.copyWith(
            token: null == token
                ? _value.token
                : token // ignore: cast_nullable_to_non_nullable
                      as String,
            deviceId: null == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String,
            deviceLabel: null == deviceLabel
                ? _value.deviceLabel
                : deviceLabel // ignore: cast_nullable_to_non_nullable
                      as String,
            publicKey: null == publicKey
                ? _value.publicKey
                : publicKey // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PairClaimRequestDtoImplCopyWith<$Res>
    implements $PairClaimRequestDtoCopyWith<$Res> {
  factory _$$PairClaimRequestDtoImplCopyWith(
    _$PairClaimRequestDtoImpl value,
    $Res Function(_$PairClaimRequestDtoImpl) then,
  ) = __$$PairClaimRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String token,
    String deviceId,
    String deviceLabel,
    String publicKey,
  });
}

/// @nodoc
class __$$PairClaimRequestDtoImplCopyWithImpl<$Res>
    extends _$PairClaimRequestDtoCopyWithImpl<$Res, _$PairClaimRequestDtoImpl>
    implements _$$PairClaimRequestDtoImplCopyWith<$Res> {
  __$$PairClaimRequestDtoImplCopyWithImpl(
    _$PairClaimRequestDtoImpl _value,
    $Res Function(_$PairClaimRequestDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PairClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? deviceId = null,
    Object? deviceLabel = null,
    Object? publicKey = null,
  }) {
    return _then(
      _$PairClaimRequestDtoImpl(
        token: null == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceLabel: null == deviceLabel
            ? _value.deviceLabel
            : deviceLabel // ignore: cast_nullable_to_non_nullable
                  as String,
        publicKey: null == publicKey
            ? _value.publicKey
            : publicKey // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PairClaimRequestDtoImpl implements _PairClaimRequestDto {
  const _$PairClaimRequestDtoImpl({
    required this.token,
    required this.deviceId,
    required this.deviceLabel,
    required this.publicKey,
  });

  factory _$PairClaimRequestDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PairClaimRequestDtoImplFromJson(json);

  @override
  final String token;
  @override
  final String deviceId;
  @override
  final String deviceLabel;
  @override
  final String publicKey;

  @override
  String toString() {
    return 'PairClaimRequestDto(token: $token, deviceId: $deviceId, deviceLabel: $deviceLabel, publicKey: $publicKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PairClaimRequestDtoImpl &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.deviceLabel, deviceLabel) ||
                other.deviceLabel == deviceLabel) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, token, deviceId, deviceLabel, publicKey);

  /// Create a copy of PairClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PairClaimRequestDtoImplCopyWith<_$PairClaimRequestDtoImpl> get copyWith =>
      __$$PairClaimRequestDtoImplCopyWithImpl<_$PairClaimRequestDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PairClaimRequestDtoImplToJson(this);
  }
}

abstract class _PairClaimRequestDto implements PairClaimRequestDto {
  const factory _PairClaimRequestDto({
    required final String token,
    required final String deviceId,
    required final String deviceLabel,
    required final String publicKey,
  }) = _$PairClaimRequestDtoImpl;

  factory _PairClaimRequestDto.fromJson(Map<String, dynamic> json) =
      _$PairClaimRequestDtoImpl.fromJson;

  @override
  String get token;
  @override
  String get deviceId;
  @override
  String get deviceLabel;
  @override
  String get publicKey;

  /// Create a copy of PairClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PairClaimRequestDtoImplCopyWith<_$PairClaimRequestDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PairClaimResponseDto _$PairClaimResponseDtoFromJson(Map<String, dynamic> json) {
  return _PairClaimResponseDto.fromJson(json);
}

/// @nodoc
mixin _$PairClaimResponseDto {
  String get deviceToken => throw _privateConstructorUsedError;
  String get fingerprint => throw _privateConstructorUsedError;
  String get serverPublicKey => throw _privateConstructorUsedError;

  /// Serializes this PairClaimResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PairClaimResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PairClaimResponseDtoCopyWith<PairClaimResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PairClaimResponseDtoCopyWith<$Res> {
  factory $PairClaimResponseDtoCopyWith(
    PairClaimResponseDto value,
    $Res Function(PairClaimResponseDto) then,
  ) = _$PairClaimResponseDtoCopyWithImpl<$Res, PairClaimResponseDto>;
  @useResult
  $Res call({String deviceToken, String fingerprint, String serverPublicKey});
}

/// @nodoc
class _$PairClaimResponseDtoCopyWithImpl<
  $Res,
  $Val extends PairClaimResponseDto
>
    implements $PairClaimResponseDtoCopyWith<$Res> {
  _$PairClaimResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PairClaimResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceToken = null,
    Object? fingerprint = null,
    Object? serverPublicKey = null,
  }) {
    return _then(
      _value.copyWith(
            deviceToken: null == deviceToken
                ? _value.deviceToken
                : deviceToken // ignore: cast_nullable_to_non_nullable
                      as String,
            fingerprint: null == fingerprint
                ? _value.fingerprint
                : fingerprint // ignore: cast_nullable_to_non_nullable
                      as String,
            serverPublicKey: null == serverPublicKey
                ? _value.serverPublicKey
                : serverPublicKey // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PairClaimResponseDtoImplCopyWith<$Res>
    implements $PairClaimResponseDtoCopyWith<$Res> {
  factory _$$PairClaimResponseDtoImplCopyWith(
    _$PairClaimResponseDtoImpl value,
    $Res Function(_$PairClaimResponseDtoImpl) then,
  ) = __$$PairClaimResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String deviceToken, String fingerprint, String serverPublicKey});
}

/// @nodoc
class __$$PairClaimResponseDtoImplCopyWithImpl<$Res>
    extends _$PairClaimResponseDtoCopyWithImpl<$Res, _$PairClaimResponseDtoImpl>
    implements _$$PairClaimResponseDtoImplCopyWith<$Res> {
  __$$PairClaimResponseDtoImplCopyWithImpl(
    _$PairClaimResponseDtoImpl _value,
    $Res Function(_$PairClaimResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PairClaimResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceToken = null,
    Object? fingerprint = null,
    Object? serverPublicKey = null,
  }) {
    return _then(
      _$PairClaimResponseDtoImpl(
        deviceToken: null == deviceToken
            ? _value.deviceToken
            : deviceToken // ignore: cast_nullable_to_non_nullable
                  as String,
        fingerprint: null == fingerprint
            ? _value.fingerprint
            : fingerprint // ignore: cast_nullable_to_non_nullable
                  as String,
        serverPublicKey: null == serverPublicKey
            ? _value.serverPublicKey
            : serverPublicKey // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PairClaimResponseDtoImpl implements _PairClaimResponseDto {
  const _$PairClaimResponseDtoImpl({
    required this.deviceToken,
    required this.fingerprint,
    required this.serverPublicKey,
  });

  factory _$PairClaimResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PairClaimResponseDtoImplFromJson(json);

  @override
  final String deviceToken;
  @override
  final String fingerprint;
  @override
  final String serverPublicKey;

  @override
  String toString() {
    return 'PairClaimResponseDto(deviceToken: $deviceToken, fingerprint: $fingerprint, serverPublicKey: $serverPublicKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PairClaimResponseDtoImpl &&
            (identical(other.deviceToken, deviceToken) ||
                other.deviceToken == deviceToken) &&
            (identical(other.fingerprint, fingerprint) ||
                other.fingerprint == fingerprint) &&
            (identical(other.serverPublicKey, serverPublicKey) ||
                other.serverPublicKey == serverPublicKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, deviceToken, fingerprint, serverPublicKey);

  /// Create a copy of PairClaimResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PairClaimResponseDtoImplCopyWith<_$PairClaimResponseDtoImpl>
  get copyWith =>
      __$$PairClaimResponseDtoImplCopyWithImpl<_$PairClaimResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PairClaimResponseDtoImplToJson(this);
  }
}

abstract class _PairClaimResponseDto implements PairClaimResponseDto {
  const factory _PairClaimResponseDto({
    required final String deviceToken,
    required final String fingerprint,
    required final String serverPublicKey,
  }) = _$PairClaimResponseDtoImpl;

  factory _PairClaimResponseDto.fromJson(Map<String, dynamic> json) =
      _$PairClaimResponseDtoImpl.fromJson;

  @override
  String get deviceToken;
  @override
  String get fingerprint;
  @override
  String get serverPublicKey;

  /// Create a copy of PairClaimResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PairClaimResponseDtoImplCopyWith<_$PairClaimResponseDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
