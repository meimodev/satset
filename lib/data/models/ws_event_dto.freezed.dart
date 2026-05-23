// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ws_event_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WsEventDto _$WsEventDtoFromJson(Map<String, dynamic> json) {
  return _WsEventDto.fromJson(json);
}

/// @nodoc
mixin _$WsEventDto {
  int get v => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;
  DateTime get ts => throw _privateConstructorUsedError;

  /// Serializes this WsEventDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WsEventDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WsEventDtoCopyWith<WsEventDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WsEventDtoCopyWith<$Res> {
  factory $WsEventDtoCopyWith(
    WsEventDto value,
    $Res Function(WsEventDto) then,
  ) = _$WsEventDtoCopyWithImpl<$Res, WsEventDto>;
  @useResult
  $Res call({int v, String type, Map<String, dynamic> payload, DateTime ts});
}

/// @nodoc
class _$WsEventDtoCopyWithImpl<$Res, $Val extends WsEventDto>
    implements $WsEventDtoCopyWith<$Res> {
  _$WsEventDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WsEventDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? v = null,
    Object? type = null,
    Object? payload = null,
    Object? ts = null,
  }) {
    return _then(
      _value.copyWith(
            v: null == v
                ? _value.v
                : v // ignore: cast_nullable_to_non_nullable
                      as int,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            payload: null == payload
                ? _value.payload
                : payload // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            ts: null == ts
                ? _value.ts
                : ts // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WsEventDtoImplCopyWith<$Res>
    implements $WsEventDtoCopyWith<$Res> {
  factory _$$WsEventDtoImplCopyWith(
    _$WsEventDtoImpl value,
    $Res Function(_$WsEventDtoImpl) then,
  ) = __$$WsEventDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int v, String type, Map<String, dynamic> payload, DateTime ts});
}

/// @nodoc
class __$$WsEventDtoImplCopyWithImpl<$Res>
    extends _$WsEventDtoCopyWithImpl<$Res, _$WsEventDtoImpl>
    implements _$$WsEventDtoImplCopyWith<$Res> {
  __$$WsEventDtoImplCopyWithImpl(
    _$WsEventDtoImpl _value,
    $Res Function(_$WsEventDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WsEventDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? v = null,
    Object? type = null,
    Object? payload = null,
    Object? ts = null,
  }) {
    return _then(
      _$WsEventDtoImpl(
        v: null == v
            ? _value.v
            : v // ignore: cast_nullable_to_non_nullable
                  as int,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        payload: null == payload
            ? _value._payload
            : payload // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        ts: null == ts
            ? _value.ts
            : ts // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WsEventDtoImpl implements _WsEventDto {
  const _$WsEventDtoImpl({
    this.v = 1,
    required this.type,
    final Map<String, dynamic> payload = const <String, dynamic>{},
    required this.ts,
  }) : _payload = payload;

  factory _$WsEventDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$WsEventDtoImplFromJson(json);

  @override
  @JsonKey()
  final int v;
  @override
  final String type;
  final Map<String, dynamic> _payload;
  @override
  @JsonKey()
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  final DateTime ts;

  @override
  String toString() {
    return 'WsEventDto(v: $v, type: $type, payload: $payload, ts: $ts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WsEventDtoImpl &&
            (identical(other.v, v) || other.v == v) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.ts, ts) || other.ts == ts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    v,
    type,
    const DeepCollectionEquality().hash(_payload),
    ts,
  );

  /// Create a copy of WsEventDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WsEventDtoImplCopyWith<_$WsEventDtoImpl> get copyWith =>
      __$$WsEventDtoImplCopyWithImpl<_$WsEventDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WsEventDtoImplToJson(this);
  }
}

abstract class _WsEventDto implements WsEventDto {
  const factory _WsEventDto({
    final int v,
    required final String type,
    final Map<String, dynamic> payload,
    required final DateTime ts,
  }) = _$WsEventDtoImpl;

  factory _WsEventDto.fromJson(Map<String, dynamic> json) =
      _$WsEventDtoImpl.fromJson;

  @override
  int get v;
  @override
  String get type;
  @override
  Map<String, dynamic> get payload;
  @override
  DateTime get ts;

  /// Create a copy of WsEventDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WsEventDtoImplCopyWith<_$WsEventDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
