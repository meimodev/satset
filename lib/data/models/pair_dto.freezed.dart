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
