// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DeviceDto _$DeviceDtoFromJson(Map<String, dynamic> json) {
  return _DeviceDto.fromJson(json);
}

/// @nodoc
mixin _$DeviceDto {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  DateTime get pairedAt => throw _privateConstructorUsedError;
  bool get revoked => throw _privateConstructorUsedError;
  DateTime? get lastSessionAt => throw _privateConstructorUsedError;
  String? get lastSessionUserId => throw _privateConstructorUsedError;
  bool get sessionActive => throw _privateConstructorUsedError;

  /// Serializes this DeviceDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeviceDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceDtoCopyWith<DeviceDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceDtoCopyWith<$Res> {
  factory $DeviceDtoCopyWith(DeviceDto value, $Res Function(DeviceDto) then) =
      _$DeviceDtoCopyWithImpl<$Res, DeviceDto>;
  @useResult
  $Res call({
    String id,
    String label,
    DateTime pairedAt,
    bool revoked,
    DateTime? lastSessionAt,
    String? lastSessionUserId,
    bool sessionActive,
  });
}

/// @nodoc
class _$DeviceDtoCopyWithImpl<$Res, $Val extends DeviceDto>
    implements $DeviceDtoCopyWith<$Res> {
  _$DeviceDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeviceDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? pairedAt = null,
    Object? revoked = null,
    Object? lastSessionAt = freezed,
    Object? lastSessionUserId = freezed,
    Object? sessionActive = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            pairedAt: null == pairedAt
                ? _value.pairedAt
                : pairedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            revoked: null == revoked
                ? _value.revoked
                : revoked // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastSessionAt: freezed == lastSessionAt
                ? _value.lastSessionAt
                : lastSessionAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastSessionUserId: freezed == lastSessionUserId
                ? _value.lastSessionUserId
                : lastSessionUserId // ignore: cast_nullable_to_non_nullable
                      as String?,
            sessionActive: null == sessionActive
                ? _value.sessionActive
                : sessionActive // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeviceDtoImplCopyWith<$Res>
    implements $DeviceDtoCopyWith<$Res> {
  factory _$$DeviceDtoImplCopyWith(
    _$DeviceDtoImpl value,
    $Res Function(_$DeviceDtoImpl) then,
  ) = __$$DeviceDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String label,
    DateTime pairedAt,
    bool revoked,
    DateTime? lastSessionAt,
    String? lastSessionUserId,
    bool sessionActive,
  });
}

/// @nodoc
class __$$DeviceDtoImplCopyWithImpl<$Res>
    extends _$DeviceDtoCopyWithImpl<$Res, _$DeviceDtoImpl>
    implements _$$DeviceDtoImplCopyWith<$Res> {
  __$$DeviceDtoImplCopyWithImpl(
    _$DeviceDtoImpl _value,
    $Res Function(_$DeviceDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeviceDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? pairedAt = null,
    Object? revoked = null,
    Object? lastSessionAt = freezed,
    Object? lastSessionUserId = freezed,
    Object? sessionActive = null,
  }) {
    return _then(
      _$DeviceDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        pairedAt: null == pairedAt
            ? _value.pairedAt
            : pairedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        revoked: null == revoked
            ? _value.revoked
            : revoked // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastSessionAt: freezed == lastSessionAt
            ? _value.lastSessionAt
            : lastSessionAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastSessionUserId: freezed == lastSessionUserId
            ? _value.lastSessionUserId
            : lastSessionUserId // ignore: cast_nullable_to_non_nullable
                  as String?,
        sessionActive: null == sessionActive
            ? _value.sessionActive
            : sessionActive // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceDtoImpl implements _DeviceDto {
  const _$DeviceDtoImpl({
    required this.id,
    required this.label,
    required this.pairedAt,
    this.revoked = false,
    this.lastSessionAt,
    this.lastSessionUserId,
    this.sessionActive = false,
  });

  factory _$DeviceDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  final DateTime pairedAt;
  @override
  @JsonKey()
  final bool revoked;
  @override
  final DateTime? lastSessionAt;
  @override
  final String? lastSessionUserId;
  @override
  @JsonKey()
  final bool sessionActive;

  @override
  String toString() {
    return 'DeviceDto(id: $id, label: $label, pairedAt: $pairedAt, revoked: $revoked, lastSessionAt: $lastSessionAt, lastSessionUserId: $lastSessionUserId, sessionActive: $sessionActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.pairedAt, pairedAt) ||
                other.pairedAt == pairedAt) &&
            (identical(other.revoked, revoked) || other.revoked == revoked) &&
            (identical(other.lastSessionAt, lastSessionAt) ||
                other.lastSessionAt == lastSessionAt) &&
            (identical(other.lastSessionUserId, lastSessionUserId) ||
                other.lastSessionUserId == lastSessionUserId) &&
            (identical(other.sessionActive, sessionActive) ||
                other.sessionActive == sessionActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    label,
    pairedAt,
    revoked,
    lastSessionAt,
    lastSessionUserId,
    sessionActive,
  );

  /// Create a copy of DeviceDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceDtoImplCopyWith<_$DeviceDtoImpl> get copyWith =>
      __$$DeviceDtoImplCopyWithImpl<_$DeviceDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceDtoImplToJson(this);
  }
}

abstract class _DeviceDto implements DeviceDto {
  const factory _DeviceDto({
    required final String id,
    required final String label,
    required final DateTime pairedAt,
    final bool revoked,
    final DateTime? lastSessionAt,
    final String? lastSessionUserId,
    final bool sessionActive,
  }) = _$DeviceDtoImpl;

  factory _DeviceDto.fromJson(Map<String, dynamic> json) =
      _$DeviceDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  DateTime get pairedAt;
  @override
  bool get revoked;
  @override
  DateTime? get lastSessionAt;
  @override
  String? get lastSessionUserId;
  @override
  bool get sessionActive;

  /// Create a copy of DeviceDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceDtoImplCopyWith<_$DeviceDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
