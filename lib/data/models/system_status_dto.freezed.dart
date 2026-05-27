// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'system_status_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SystemStatusDto _$SystemStatusDtoFromJson(Map<String, dynamic> json) {
  return _SystemStatusDto.fromJson(json);
}

/// @nodoc
mixin _$SystemStatusDto {
  DateTime get startedAt => throw _privateConstructorUsedError;
  int get uptimeMs => throw _privateConstructorUsedError;
  String get listenAddress => throw _privateConstructorUsedError;
  int get port => throw _privateConstructorUsedError;
  DateTime get tlsCertExpiry => throw _privateConstructorUsedError;
  DateTime get tlsCertIssuedAt => throw _privateConstructorUsedError;
  String get tlsFingerprint => throw _privateConstructorUsedError;
  int get activeSessions => throw _privateConstructorUsedError;
  int get pairedDevices => throw _privateConstructorUsedError;
  int get requestCountRecent => throw _privateConstructorUsedError;
  int get p50LatencyMs => throw _privateConstructorUsedError;
  int get p95LatencyMs => throw _privateConstructorUsedError;

  /// Serializes this SystemStatusDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SystemStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SystemStatusDtoCopyWith<SystemStatusDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SystemStatusDtoCopyWith<$Res> {
  factory $SystemStatusDtoCopyWith(
    SystemStatusDto value,
    $Res Function(SystemStatusDto) then,
  ) = _$SystemStatusDtoCopyWithImpl<$Res, SystemStatusDto>;
  @useResult
  $Res call({
    DateTime startedAt,
    int uptimeMs,
    String listenAddress,
    int port,
    DateTime tlsCertExpiry,
    DateTime tlsCertIssuedAt,
    String tlsFingerprint,
    int activeSessions,
    int pairedDevices,
    int requestCountRecent,
    int p50LatencyMs,
    int p95LatencyMs,
  });
}

/// @nodoc
class _$SystemStatusDtoCopyWithImpl<$Res, $Val extends SystemStatusDto>
    implements $SystemStatusDtoCopyWith<$Res> {
  _$SystemStatusDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SystemStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startedAt = null,
    Object? uptimeMs = null,
    Object? listenAddress = null,
    Object? port = null,
    Object? tlsCertExpiry = null,
    Object? tlsCertIssuedAt = null,
    Object? tlsFingerprint = null,
    Object? activeSessions = null,
    Object? pairedDevices = null,
    Object? requestCountRecent = null,
    Object? p50LatencyMs = null,
    Object? p95LatencyMs = null,
  }) {
    return _then(
      _value.copyWith(
            startedAt: null == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            uptimeMs: null == uptimeMs
                ? _value.uptimeMs
                : uptimeMs // ignore: cast_nullable_to_non_nullable
                      as int,
            listenAddress: null == listenAddress
                ? _value.listenAddress
                : listenAddress // ignore: cast_nullable_to_non_nullable
                      as String,
            port: null == port
                ? _value.port
                : port // ignore: cast_nullable_to_non_nullable
                      as int,
            tlsCertExpiry: null == tlsCertExpiry
                ? _value.tlsCertExpiry
                : tlsCertExpiry // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            tlsCertIssuedAt: null == tlsCertIssuedAt
                ? _value.tlsCertIssuedAt
                : tlsCertIssuedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            tlsFingerprint: null == tlsFingerprint
                ? _value.tlsFingerprint
                : tlsFingerprint // ignore: cast_nullable_to_non_nullable
                      as String,
            activeSessions: null == activeSessions
                ? _value.activeSessions
                : activeSessions // ignore: cast_nullable_to_non_nullable
                      as int,
            pairedDevices: null == pairedDevices
                ? _value.pairedDevices
                : pairedDevices // ignore: cast_nullable_to_non_nullable
                      as int,
            requestCountRecent: null == requestCountRecent
                ? _value.requestCountRecent
                : requestCountRecent // ignore: cast_nullable_to_non_nullable
                      as int,
            p50LatencyMs: null == p50LatencyMs
                ? _value.p50LatencyMs
                : p50LatencyMs // ignore: cast_nullable_to_non_nullable
                      as int,
            p95LatencyMs: null == p95LatencyMs
                ? _value.p95LatencyMs
                : p95LatencyMs // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SystemStatusDtoImplCopyWith<$Res>
    implements $SystemStatusDtoCopyWith<$Res> {
  factory _$$SystemStatusDtoImplCopyWith(
    _$SystemStatusDtoImpl value,
    $Res Function(_$SystemStatusDtoImpl) then,
  ) = __$$SystemStatusDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DateTime startedAt,
    int uptimeMs,
    String listenAddress,
    int port,
    DateTime tlsCertExpiry,
    DateTime tlsCertIssuedAt,
    String tlsFingerprint,
    int activeSessions,
    int pairedDevices,
    int requestCountRecent,
    int p50LatencyMs,
    int p95LatencyMs,
  });
}

/// @nodoc
class __$$SystemStatusDtoImplCopyWithImpl<$Res>
    extends _$SystemStatusDtoCopyWithImpl<$Res, _$SystemStatusDtoImpl>
    implements _$$SystemStatusDtoImplCopyWith<$Res> {
  __$$SystemStatusDtoImplCopyWithImpl(
    _$SystemStatusDtoImpl _value,
    $Res Function(_$SystemStatusDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SystemStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startedAt = null,
    Object? uptimeMs = null,
    Object? listenAddress = null,
    Object? port = null,
    Object? tlsCertExpiry = null,
    Object? tlsCertIssuedAt = null,
    Object? tlsFingerprint = null,
    Object? activeSessions = null,
    Object? pairedDevices = null,
    Object? requestCountRecent = null,
    Object? p50LatencyMs = null,
    Object? p95LatencyMs = null,
  }) {
    return _then(
      _$SystemStatusDtoImpl(
        startedAt: null == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        uptimeMs: null == uptimeMs
            ? _value.uptimeMs
            : uptimeMs // ignore: cast_nullable_to_non_nullable
                  as int,
        listenAddress: null == listenAddress
            ? _value.listenAddress
            : listenAddress // ignore: cast_nullable_to_non_nullable
                  as String,
        port: null == port
            ? _value.port
            : port // ignore: cast_nullable_to_non_nullable
                  as int,
        tlsCertExpiry: null == tlsCertExpiry
            ? _value.tlsCertExpiry
            : tlsCertExpiry // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        tlsCertIssuedAt: null == tlsCertIssuedAt
            ? _value.tlsCertIssuedAt
            : tlsCertIssuedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        tlsFingerprint: null == tlsFingerprint
            ? _value.tlsFingerprint
            : tlsFingerprint // ignore: cast_nullable_to_non_nullable
                  as String,
        activeSessions: null == activeSessions
            ? _value.activeSessions
            : activeSessions // ignore: cast_nullable_to_non_nullable
                  as int,
        pairedDevices: null == pairedDevices
            ? _value.pairedDevices
            : pairedDevices // ignore: cast_nullable_to_non_nullable
                  as int,
        requestCountRecent: null == requestCountRecent
            ? _value.requestCountRecent
            : requestCountRecent // ignore: cast_nullable_to_non_nullable
                  as int,
        p50LatencyMs: null == p50LatencyMs
            ? _value.p50LatencyMs
            : p50LatencyMs // ignore: cast_nullable_to_non_nullable
                  as int,
        p95LatencyMs: null == p95LatencyMs
            ? _value.p95LatencyMs
            : p95LatencyMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SystemStatusDtoImpl implements _SystemStatusDto {
  const _$SystemStatusDtoImpl({
    required this.startedAt,
    this.uptimeMs = 0,
    this.listenAddress = '0.0.0.0',
    this.port = 7443,
    required this.tlsCertExpiry,
    required this.tlsCertIssuedAt,
    this.tlsFingerprint = '',
    this.activeSessions = 0,
    this.pairedDevices = 0,
    this.requestCountRecent = 0,
    this.p50LatencyMs = 0,
    this.p95LatencyMs = 0,
  });

  factory _$SystemStatusDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SystemStatusDtoImplFromJson(json);

  @override
  final DateTime startedAt;
  @override
  @JsonKey()
  final int uptimeMs;
  @override
  @JsonKey()
  final String listenAddress;
  @override
  @JsonKey()
  final int port;
  @override
  final DateTime tlsCertExpiry;
  @override
  final DateTime tlsCertIssuedAt;
  @override
  @JsonKey()
  final String tlsFingerprint;
  @override
  @JsonKey()
  final int activeSessions;
  @override
  @JsonKey()
  final int pairedDevices;
  @override
  @JsonKey()
  final int requestCountRecent;
  @override
  @JsonKey()
  final int p50LatencyMs;
  @override
  @JsonKey()
  final int p95LatencyMs;

  @override
  String toString() {
    return 'SystemStatusDto(startedAt: $startedAt, uptimeMs: $uptimeMs, listenAddress: $listenAddress, port: $port, tlsCertExpiry: $tlsCertExpiry, tlsCertIssuedAt: $tlsCertIssuedAt, tlsFingerprint: $tlsFingerprint, activeSessions: $activeSessions, pairedDevices: $pairedDevices, requestCountRecent: $requestCountRecent, p50LatencyMs: $p50LatencyMs, p95LatencyMs: $p95LatencyMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SystemStatusDtoImpl &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.uptimeMs, uptimeMs) ||
                other.uptimeMs == uptimeMs) &&
            (identical(other.listenAddress, listenAddress) ||
                other.listenAddress == listenAddress) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.tlsCertExpiry, tlsCertExpiry) ||
                other.tlsCertExpiry == tlsCertExpiry) &&
            (identical(other.tlsCertIssuedAt, tlsCertIssuedAt) ||
                other.tlsCertIssuedAt == tlsCertIssuedAt) &&
            (identical(other.tlsFingerprint, tlsFingerprint) ||
                other.tlsFingerprint == tlsFingerprint) &&
            (identical(other.activeSessions, activeSessions) ||
                other.activeSessions == activeSessions) &&
            (identical(other.pairedDevices, pairedDevices) ||
                other.pairedDevices == pairedDevices) &&
            (identical(other.requestCountRecent, requestCountRecent) ||
                other.requestCountRecent == requestCountRecent) &&
            (identical(other.p50LatencyMs, p50LatencyMs) ||
                other.p50LatencyMs == p50LatencyMs) &&
            (identical(other.p95LatencyMs, p95LatencyMs) ||
                other.p95LatencyMs == p95LatencyMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    startedAt,
    uptimeMs,
    listenAddress,
    port,
    tlsCertExpiry,
    tlsCertIssuedAt,
    tlsFingerprint,
    activeSessions,
    pairedDevices,
    requestCountRecent,
    p50LatencyMs,
    p95LatencyMs,
  );

  /// Create a copy of SystemStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SystemStatusDtoImplCopyWith<_$SystemStatusDtoImpl> get copyWith =>
      __$$SystemStatusDtoImplCopyWithImpl<_$SystemStatusDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SystemStatusDtoImplToJson(this);
  }
}

abstract class _SystemStatusDto implements SystemStatusDto {
  const factory _SystemStatusDto({
    required final DateTime startedAt,
    final int uptimeMs,
    final String listenAddress,
    final int port,
    required final DateTime tlsCertExpiry,
    required final DateTime tlsCertIssuedAt,
    final String tlsFingerprint,
    final int activeSessions,
    final int pairedDevices,
    final int requestCountRecent,
    final int p50LatencyMs,
    final int p95LatencyMs,
  }) = _$SystemStatusDtoImpl;

  factory _SystemStatusDto.fromJson(Map<String, dynamic> json) =
      _$SystemStatusDtoImpl.fromJson;

  @override
  DateTime get startedAt;
  @override
  int get uptimeMs;
  @override
  String get listenAddress;
  @override
  int get port;
  @override
  DateTime get tlsCertExpiry;
  @override
  DateTime get tlsCertIssuedAt;
  @override
  String get tlsFingerprint;
  @override
  int get activeSessions;
  @override
  int get pairedDevices;
  @override
  int get requestCountRecent;
  @override
  int get p50LatencyMs;
  @override
  int get p95LatencyMs;

  /// Create a copy of SystemStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SystemStatusDtoImplCopyWith<_$SystemStatusDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

KdsStationDto _$KdsStationDtoFromJson(Map<String, dynamic> json) {
  return _KdsStationDto.fromJson(json);
}

/// @nodoc
mixin _$KdsStationDto {
  String get station => throw _privateConstructorUsedError;
  int get pendingTickets => throw _privateConstructorUsedError;
  int get staffOnline => throw _privateConstructorUsedError;

  /// Serializes this KdsStationDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KdsStationDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KdsStationDtoCopyWith<KdsStationDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KdsStationDtoCopyWith<$Res> {
  factory $KdsStationDtoCopyWith(
    KdsStationDto value,
    $Res Function(KdsStationDto) then,
  ) = _$KdsStationDtoCopyWithImpl<$Res, KdsStationDto>;
  @useResult
  $Res call({String station, int pendingTickets, int staffOnline});
}

/// @nodoc
class _$KdsStationDtoCopyWithImpl<$Res, $Val extends KdsStationDto>
    implements $KdsStationDtoCopyWith<$Res> {
  _$KdsStationDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KdsStationDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? station = null,
    Object? pendingTickets = null,
    Object? staffOnline = null,
  }) {
    return _then(
      _value.copyWith(
            station: null == station
                ? _value.station
                : station // ignore: cast_nullable_to_non_nullable
                      as String,
            pendingTickets: null == pendingTickets
                ? _value.pendingTickets
                : pendingTickets // ignore: cast_nullable_to_non_nullable
                      as int,
            staffOnline: null == staffOnline
                ? _value.staffOnline
                : staffOnline // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$KdsStationDtoImplCopyWith<$Res>
    implements $KdsStationDtoCopyWith<$Res> {
  factory _$$KdsStationDtoImplCopyWith(
    _$KdsStationDtoImpl value,
    $Res Function(_$KdsStationDtoImpl) then,
  ) = __$$KdsStationDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String station, int pendingTickets, int staffOnline});
}

/// @nodoc
class __$$KdsStationDtoImplCopyWithImpl<$Res>
    extends _$KdsStationDtoCopyWithImpl<$Res, _$KdsStationDtoImpl>
    implements _$$KdsStationDtoImplCopyWith<$Res> {
  __$$KdsStationDtoImplCopyWithImpl(
    _$KdsStationDtoImpl _value,
    $Res Function(_$KdsStationDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of KdsStationDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? station = null,
    Object? pendingTickets = null,
    Object? staffOnline = null,
  }) {
    return _then(
      _$KdsStationDtoImpl(
        station: null == station
            ? _value.station
            : station // ignore: cast_nullable_to_non_nullable
                  as String,
        pendingTickets: null == pendingTickets
            ? _value.pendingTickets
            : pendingTickets // ignore: cast_nullable_to_non_nullable
                  as int,
        staffOnline: null == staffOnline
            ? _value.staffOnline
            : staffOnline // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$KdsStationDtoImpl implements _KdsStationDto {
  const _$KdsStationDtoImpl({
    required this.station,
    this.pendingTickets = 0,
    this.staffOnline = 0,
  });

  factory _$KdsStationDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$KdsStationDtoImplFromJson(json);

  @override
  final String station;
  @override
  @JsonKey()
  final int pendingTickets;
  @override
  @JsonKey()
  final int staffOnline;

  @override
  String toString() {
    return 'KdsStationDto(station: $station, pendingTickets: $pendingTickets, staffOnline: $staffOnline)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KdsStationDtoImpl &&
            (identical(other.station, station) || other.station == station) &&
            (identical(other.pendingTickets, pendingTickets) ||
                other.pendingTickets == pendingTickets) &&
            (identical(other.staffOnline, staffOnline) ||
                other.staffOnline == staffOnline));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, station, pendingTickets, staffOnline);

  /// Create a copy of KdsStationDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KdsStationDtoImplCopyWith<_$KdsStationDtoImpl> get copyWith =>
      __$$KdsStationDtoImplCopyWithImpl<_$KdsStationDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KdsStationDtoImplToJson(this);
  }
}

abstract class _KdsStationDto implements KdsStationDto {
  const factory _KdsStationDto({
    required final String station,
    final int pendingTickets,
    final int staffOnline,
  }) = _$KdsStationDtoImpl;

  factory _KdsStationDto.fromJson(Map<String, dynamic> json) =
      _$KdsStationDtoImpl.fromJson;

  @override
  String get station;
  @override
  int get pendingTickets;
  @override
  int get staffOnline;

  /// Create a copy of KdsStationDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KdsStationDtoImplCopyWith<_$KdsStationDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QueueDepthDto _$QueueDepthDtoFromJson(Map<String, dynamic> json) {
  return _QueueDepthDto.fromJson(json);
}

/// @nodoc
mixin _$QueueDepthDto {
  int get total => throw _privateConstructorUsedError;
  Map<String, int> get byStation => throw _privateConstructorUsedError;

  /// Serializes this QueueDepthDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QueueDepthDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QueueDepthDtoCopyWith<QueueDepthDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QueueDepthDtoCopyWith<$Res> {
  factory $QueueDepthDtoCopyWith(
    QueueDepthDto value,
    $Res Function(QueueDepthDto) then,
  ) = _$QueueDepthDtoCopyWithImpl<$Res, QueueDepthDto>;
  @useResult
  $Res call({int total, Map<String, int> byStation});
}

/// @nodoc
class _$QueueDepthDtoCopyWithImpl<$Res, $Val extends QueueDepthDto>
    implements $QueueDepthDtoCopyWith<$Res> {
  _$QueueDepthDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QueueDepthDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? total = null, Object? byStation = null}) {
    return _then(
      _value.copyWith(
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            byStation: null == byStation
                ? _value.byStation
                : byStation // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QueueDepthDtoImplCopyWith<$Res>
    implements $QueueDepthDtoCopyWith<$Res> {
  factory _$$QueueDepthDtoImplCopyWith(
    _$QueueDepthDtoImpl value,
    $Res Function(_$QueueDepthDtoImpl) then,
  ) = __$$QueueDepthDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int total, Map<String, int> byStation});
}

/// @nodoc
class __$$QueueDepthDtoImplCopyWithImpl<$Res>
    extends _$QueueDepthDtoCopyWithImpl<$Res, _$QueueDepthDtoImpl>
    implements _$$QueueDepthDtoImplCopyWith<$Res> {
  __$$QueueDepthDtoImplCopyWithImpl(
    _$QueueDepthDtoImpl _value,
    $Res Function(_$QueueDepthDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QueueDepthDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? total = null, Object? byStation = null}) {
    return _then(
      _$QueueDepthDtoImpl(
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        byStation: null == byStation
            ? _value._byStation
            : byStation // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$QueueDepthDtoImpl implements _QueueDepthDto {
  const _$QueueDepthDtoImpl({
    this.total = 0,
    final Map<String, int> byStation = const <String, int>{},
  }) : _byStation = byStation;

  factory _$QueueDepthDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$QueueDepthDtoImplFromJson(json);

  @override
  @JsonKey()
  final int total;
  final Map<String, int> _byStation;
  @override
  @JsonKey()
  Map<String, int> get byStation {
    if (_byStation is EqualUnmodifiableMapView) return _byStation;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_byStation);
  }

  @override
  String toString() {
    return 'QueueDepthDto(total: $total, byStation: $byStation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QueueDepthDtoImpl &&
            (identical(other.total, total) || other.total == total) &&
            const DeepCollectionEquality().equals(
              other._byStation,
              _byStation,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    total,
    const DeepCollectionEquality().hash(_byStation),
  );

  /// Create a copy of QueueDepthDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QueueDepthDtoImplCopyWith<_$QueueDepthDtoImpl> get copyWith =>
      __$$QueueDepthDtoImplCopyWithImpl<_$QueueDepthDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QueueDepthDtoImplToJson(this);
  }
}

abstract class _QueueDepthDto implements QueueDepthDto {
  const factory _QueueDepthDto({
    final int total,
    final Map<String, int> byStation,
  }) = _$QueueDepthDtoImpl;

  factory _QueueDepthDto.fromJson(Map<String, dynamic> json) =
      _$QueueDepthDtoImpl.fromJson;

  @override
  int get total;
  @override
  Map<String, int> get byStation;

  /// Create a copy of QueueDepthDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QueueDepthDtoImplCopyWith<_$QueueDepthDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
