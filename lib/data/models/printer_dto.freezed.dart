// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'printer_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PrinterDto _$PrinterDtoFromJson(Map<String, dynamic> json) {
  return _PrinterDto.fromJson(json);
}

/// @nodoc
mixin _$PrinterDto {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get host => throw _privateConstructorUsedError;
  int get port => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  DateTime? get lastSeenAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this PrinterDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrinterDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrinterDtoCopyWith<PrinterDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrinterDtoCopyWith<$Res> {
  factory $PrinterDtoCopyWith(
    PrinterDto value,
    $Res Function(PrinterDto) then,
  ) = _$PrinterDtoCopyWithImpl<$Res, PrinterDto>;
  @useResult
  $Res call({
    String id,
    String label,
    String host,
    int port,
    String kind,
    bool enabled,
    DateTime? lastSeenAt,
    DateTime createdAt,
  });
}

/// @nodoc
class _$PrinterDtoCopyWithImpl<$Res, $Val extends PrinterDto>
    implements $PrinterDtoCopyWith<$Res> {
  _$PrinterDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrinterDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? host = null,
    Object? port = null,
    Object? kind = null,
    Object? enabled = null,
    Object? lastSeenAt = freezed,
    Object? createdAt = null,
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
            host: null == host
                ? _value.host
                : host // ignore: cast_nullable_to_non_nullable
                      as String,
            port: null == port
                ? _value.port
                : port // ignore: cast_nullable_to_non_nullable
                      as int,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as String,
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastSeenAt: freezed == lastSeenAt
                ? _value.lastSeenAt
                : lastSeenAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PrinterDtoImplCopyWith<$Res>
    implements $PrinterDtoCopyWith<$Res> {
  factory _$$PrinterDtoImplCopyWith(
    _$PrinterDtoImpl value,
    $Res Function(_$PrinterDtoImpl) then,
  ) = __$$PrinterDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String label,
    String host,
    int port,
    String kind,
    bool enabled,
    DateTime? lastSeenAt,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$PrinterDtoImplCopyWithImpl<$Res>
    extends _$PrinterDtoCopyWithImpl<$Res, _$PrinterDtoImpl>
    implements _$$PrinterDtoImplCopyWith<$Res> {
  __$$PrinterDtoImplCopyWithImpl(
    _$PrinterDtoImpl _value,
    $Res Function(_$PrinterDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PrinterDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? host = null,
    Object? port = null,
    Object? kind = null,
    Object? enabled = null,
    Object? lastSeenAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$PrinterDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        host: null == host
            ? _value.host
            : host // ignore: cast_nullable_to_non_nullable
                  as String,
        port: null == port
            ? _value.port
            : port // ignore: cast_nullable_to_non_nullable
                  as int,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastSeenAt: freezed == lastSeenAt
            ? _value.lastSeenAt
            : lastSeenAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PrinterDtoImpl implements _PrinterDto {
  const _$PrinterDtoImpl({
    required this.id,
    required this.label,
    required this.host,
    this.port = 9100,
    this.kind = 'escpos',
    this.enabled = true,
    this.lastSeenAt,
    required this.createdAt,
  });

  factory _$PrinterDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrinterDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  final String host;
  @override
  @JsonKey()
  final int port;
  @override
  @JsonKey()
  final String kind;
  @override
  @JsonKey()
  final bool enabled;
  @override
  final DateTime? lastSeenAt;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'PrinterDto(id: $id, label: $label, host: $host, port: $port, kind: $kind, enabled: $enabled, lastSeenAt: $lastSeenAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrinterDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.host, host) || other.host == host) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.lastSeenAt, lastSeenAt) ||
                other.lastSeenAt == lastSeenAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    label,
    host,
    port,
    kind,
    enabled,
    lastSeenAt,
    createdAt,
  );

  /// Create a copy of PrinterDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrinterDtoImplCopyWith<_$PrinterDtoImpl> get copyWith =>
      __$$PrinterDtoImplCopyWithImpl<_$PrinterDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PrinterDtoImplToJson(this);
  }
}

abstract class _PrinterDto implements PrinterDto {
  const factory _PrinterDto({
    required final String id,
    required final String label,
    required final String host,
    final int port,
    final String kind,
    final bool enabled,
    final DateTime? lastSeenAt,
    required final DateTime createdAt,
  }) = _$PrinterDtoImpl;

  factory _PrinterDto.fromJson(Map<String, dynamic> json) =
      _$PrinterDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  String get host;
  @override
  int get port;
  @override
  String get kind;
  @override
  bool get enabled;
  @override
  DateTime? get lastSeenAt;
  @override
  DateTime get createdAt;

  /// Create a copy of PrinterDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrinterDtoImplCopyWith<_$PrinterDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
