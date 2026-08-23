// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'system_status_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SystemStatusDto {

 DateTime get startedAt; int get uptimeMs; String get listenAddress; int get port; DateTime get tlsCertExpiry; DateTime get tlsCertIssuedAt; String get tlsFingerprint; int get activeSessions; int get pairedDevices; int get requestCountRecent; int get p50LatencyMs; int get p95LatencyMs;
/// Create a copy of SystemStatusDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemStatusDtoCopyWith<SystemStatusDto> get copyWith => _$SystemStatusDtoCopyWithImpl<SystemStatusDto>(this as SystemStatusDto, _$identity);

  /// Serializes this SystemStatusDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemStatusDto&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.uptimeMs, uptimeMs) || other.uptimeMs == uptimeMs)&&(identical(other.listenAddress, listenAddress) || other.listenAddress == listenAddress)&&(identical(other.port, port) || other.port == port)&&(identical(other.tlsCertExpiry, tlsCertExpiry) || other.tlsCertExpiry == tlsCertExpiry)&&(identical(other.tlsCertIssuedAt, tlsCertIssuedAt) || other.tlsCertIssuedAt == tlsCertIssuedAt)&&(identical(other.tlsFingerprint, tlsFingerprint) || other.tlsFingerprint == tlsFingerprint)&&(identical(other.activeSessions, activeSessions) || other.activeSessions == activeSessions)&&(identical(other.pairedDevices, pairedDevices) || other.pairedDevices == pairedDevices)&&(identical(other.requestCountRecent, requestCountRecent) || other.requestCountRecent == requestCountRecent)&&(identical(other.p50LatencyMs, p50LatencyMs) || other.p50LatencyMs == p50LatencyMs)&&(identical(other.p95LatencyMs, p95LatencyMs) || other.p95LatencyMs == p95LatencyMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startedAt,uptimeMs,listenAddress,port,tlsCertExpiry,tlsCertIssuedAt,tlsFingerprint,activeSessions,pairedDevices,requestCountRecent,p50LatencyMs,p95LatencyMs);

@override
String toString() {
  return 'SystemStatusDto(startedAt: $startedAt, uptimeMs: $uptimeMs, listenAddress: $listenAddress, port: $port, tlsCertExpiry: $tlsCertExpiry, tlsCertIssuedAt: $tlsCertIssuedAt, tlsFingerprint: $tlsFingerprint, activeSessions: $activeSessions, pairedDevices: $pairedDevices, requestCountRecent: $requestCountRecent, p50LatencyMs: $p50LatencyMs, p95LatencyMs: $p95LatencyMs)';
}


}

/// @nodoc
abstract mixin class $SystemStatusDtoCopyWith<$Res>  {
  factory $SystemStatusDtoCopyWith(SystemStatusDto value, $Res Function(SystemStatusDto) _then) = _$SystemStatusDtoCopyWithImpl;
@useResult
$Res call({
 DateTime startedAt, int uptimeMs, String listenAddress, int port, DateTime tlsCertExpiry, DateTime tlsCertIssuedAt, String tlsFingerprint, int activeSessions, int pairedDevices, int requestCountRecent, int p50LatencyMs, int p95LatencyMs
});




}
/// @nodoc
class _$SystemStatusDtoCopyWithImpl<$Res>
    implements $SystemStatusDtoCopyWith<$Res> {
  _$SystemStatusDtoCopyWithImpl(this._self, this._then);

  final SystemStatusDto _self;
  final $Res Function(SystemStatusDto) _then;

/// Create a copy of SystemStatusDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startedAt = null,Object? uptimeMs = null,Object? listenAddress = null,Object? port = null,Object? tlsCertExpiry = null,Object? tlsCertIssuedAt = null,Object? tlsFingerprint = null,Object? activeSessions = null,Object? pairedDevices = null,Object? requestCountRecent = null,Object? p50LatencyMs = null,Object? p95LatencyMs = null,}) {
  return _then(_self.copyWith(
startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,uptimeMs: null == uptimeMs ? _self.uptimeMs : uptimeMs // ignore: cast_nullable_to_non_nullable
as int,listenAddress: null == listenAddress ? _self.listenAddress : listenAddress // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,tlsCertExpiry: null == tlsCertExpiry ? _self.tlsCertExpiry : tlsCertExpiry // ignore: cast_nullable_to_non_nullable
as DateTime,tlsCertIssuedAt: null == tlsCertIssuedAt ? _self.tlsCertIssuedAt : tlsCertIssuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,tlsFingerprint: null == tlsFingerprint ? _self.tlsFingerprint : tlsFingerprint // ignore: cast_nullable_to_non_nullable
as String,activeSessions: null == activeSessions ? _self.activeSessions : activeSessions // ignore: cast_nullable_to_non_nullable
as int,pairedDevices: null == pairedDevices ? _self.pairedDevices : pairedDevices // ignore: cast_nullable_to_non_nullable
as int,requestCountRecent: null == requestCountRecent ? _self.requestCountRecent : requestCountRecent // ignore: cast_nullable_to_non_nullable
as int,p50LatencyMs: null == p50LatencyMs ? _self.p50LatencyMs : p50LatencyMs // ignore: cast_nullable_to_non_nullable
as int,p95LatencyMs: null == p95LatencyMs ? _self.p95LatencyMs : p95LatencyMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SystemStatusDto].
extension SystemStatusDtoPatterns on SystemStatusDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SystemStatusDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SystemStatusDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SystemStatusDto value)  $default,){
final _that = this;
switch (_that) {
case _SystemStatusDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SystemStatusDto value)?  $default,){
final _that = this;
switch (_that) {
case _SystemStatusDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime startedAt,  int uptimeMs,  String listenAddress,  int port,  DateTime tlsCertExpiry,  DateTime tlsCertIssuedAt,  String tlsFingerprint,  int activeSessions,  int pairedDevices,  int requestCountRecent,  int p50LatencyMs,  int p95LatencyMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SystemStatusDto() when $default != null:
return $default(_that.startedAt,_that.uptimeMs,_that.listenAddress,_that.port,_that.tlsCertExpiry,_that.tlsCertIssuedAt,_that.tlsFingerprint,_that.activeSessions,_that.pairedDevices,_that.requestCountRecent,_that.p50LatencyMs,_that.p95LatencyMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime startedAt,  int uptimeMs,  String listenAddress,  int port,  DateTime tlsCertExpiry,  DateTime tlsCertIssuedAt,  String tlsFingerprint,  int activeSessions,  int pairedDevices,  int requestCountRecent,  int p50LatencyMs,  int p95LatencyMs)  $default,) {final _that = this;
switch (_that) {
case _SystemStatusDto():
return $default(_that.startedAt,_that.uptimeMs,_that.listenAddress,_that.port,_that.tlsCertExpiry,_that.tlsCertIssuedAt,_that.tlsFingerprint,_that.activeSessions,_that.pairedDevices,_that.requestCountRecent,_that.p50LatencyMs,_that.p95LatencyMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime startedAt,  int uptimeMs,  String listenAddress,  int port,  DateTime tlsCertExpiry,  DateTime tlsCertIssuedAt,  String tlsFingerprint,  int activeSessions,  int pairedDevices,  int requestCountRecent,  int p50LatencyMs,  int p95LatencyMs)?  $default,) {final _that = this;
switch (_that) {
case _SystemStatusDto() when $default != null:
return $default(_that.startedAt,_that.uptimeMs,_that.listenAddress,_that.port,_that.tlsCertExpiry,_that.tlsCertIssuedAt,_that.tlsFingerprint,_that.activeSessions,_that.pairedDevices,_that.requestCountRecent,_that.p50LatencyMs,_that.p95LatencyMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SystemStatusDto implements SystemStatusDto {
  const _SystemStatusDto({required this.startedAt, this.uptimeMs = 0, this.listenAddress = '0.0.0.0', this.port = 7443, required this.tlsCertExpiry, required this.tlsCertIssuedAt, this.tlsFingerprint = '', this.activeSessions = 0, this.pairedDevices = 0, this.requestCountRecent = 0, this.p50LatencyMs = 0, this.p95LatencyMs = 0});
  factory _SystemStatusDto.fromJson(Map<String, dynamic> json) => _$SystemStatusDtoFromJson(json);

@override final  DateTime startedAt;
@override@JsonKey() final  int uptimeMs;
@override@JsonKey() final  String listenAddress;
@override@JsonKey() final  int port;
@override final  DateTime tlsCertExpiry;
@override final  DateTime tlsCertIssuedAt;
@override@JsonKey() final  String tlsFingerprint;
@override@JsonKey() final  int activeSessions;
@override@JsonKey() final  int pairedDevices;
@override@JsonKey() final  int requestCountRecent;
@override@JsonKey() final  int p50LatencyMs;
@override@JsonKey() final  int p95LatencyMs;

/// Create a copy of SystemStatusDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SystemStatusDtoCopyWith<_SystemStatusDto> get copyWith => __$SystemStatusDtoCopyWithImpl<_SystemStatusDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SystemStatusDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SystemStatusDto&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.uptimeMs, uptimeMs) || other.uptimeMs == uptimeMs)&&(identical(other.listenAddress, listenAddress) || other.listenAddress == listenAddress)&&(identical(other.port, port) || other.port == port)&&(identical(other.tlsCertExpiry, tlsCertExpiry) || other.tlsCertExpiry == tlsCertExpiry)&&(identical(other.tlsCertIssuedAt, tlsCertIssuedAt) || other.tlsCertIssuedAt == tlsCertIssuedAt)&&(identical(other.tlsFingerprint, tlsFingerprint) || other.tlsFingerprint == tlsFingerprint)&&(identical(other.activeSessions, activeSessions) || other.activeSessions == activeSessions)&&(identical(other.pairedDevices, pairedDevices) || other.pairedDevices == pairedDevices)&&(identical(other.requestCountRecent, requestCountRecent) || other.requestCountRecent == requestCountRecent)&&(identical(other.p50LatencyMs, p50LatencyMs) || other.p50LatencyMs == p50LatencyMs)&&(identical(other.p95LatencyMs, p95LatencyMs) || other.p95LatencyMs == p95LatencyMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startedAt,uptimeMs,listenAddress,port,tlsCertExpiry,tlsCertIssuedAt,tlsFingerprint,activeSessions,pairedDevices,requestCountRecent,p50LatencyMs,p95LatencyMs);

@override
String toString() {
  return 'SystemStatusDto(startedAt: $startedAt, uptimeMs: $uptimeMs, listenAddress: $listenAddress, port: $port, tlsCertExpiry: $tlsCertExpiry, tlsCertIssuedAt: $tlsCertIssuedAt, tlsFingerprint: $tlsFingerprint, activeSessions: $activeSessions, pairedDevices: $pairedDevices, requestCountRecent: $requestCountRecent, p50LatencyMs: $p50LatencyMs, p95LatencyMs: $p95LatencyMs)';
}


}

/// @nodoc
abstract mixin class _$SystemStatusDtoCopyWith<$Res> implements $SystemStatusDtoCopyWith<$Res> {
  factory _$SystemStatusDtoCopyWith(_SystemStatusDto value, $Res Function(_SystemStatusDto) _then) = __$SystemStatusDtoCopyWithImpl;
@override @useResult
$Res call({
 DateTime startedAt, int uptimeMs, String listenAddress, int port, DateTime tlsCertExpiry, DateTime tlsCertIssuedAt, String tlsFingerprint, int activeSessions, int pairedDevices, int requestCountRecent, int p50LatencyMs, int p95LatencyMs
});




}
/// @nodoc
class __$SystemStatusDtoCopyWithImpl<$Res>
    implements _$SystemStatusDtoCopyWith<$Res> {
  __$SystemStatusDtoCopyWithImpl(this._self, this._then);

  final _SystemStatusDto _self;
  final $Res Function(_SystemStatusDto) _then;

/// Create a copy of SystemStatusDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startedAt = null,Object? uptimeMs = null,Object? listenAddress = null,Object? port = null,Object? tlsCertExpiry = null,Object? tlsCertIssuedAt = null,Object? tlsFingerprint = null,Object? activeSessions = null,Object? pairedDevices = null,Object? requestCountRecent = null,Object? p50LatencyMs = null,Object? p95LatencyMs = null,}) {
  return _then(_SystemStatusDto(
startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,uptimeMs: null == uptimeMs ? _self.uptimeMs : uptimeMs // ignore: cast_nullable_to_non_nullable
as int,listenAddress: null == listenAddress ? _self.listenAddress : listenAddress // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,tlsCertExpiry: null == tlsCertExpiry ? _self.tlsCertExpiry : tlsCertExpiry // ignore: cast_nullable_to_non_nullable
as DateTime,tlsCertIssuedAt: null == tlsCertIssuedAt ? _self.tlsCertIssuedAt : tlsCertIssuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,tlsFingerprint: null == tlsFingerprint ? _self.tlsFingerprint : tlsFingerprint // ignore: cast_nullable_to_non_nullable
as String,activeSessions: null == activeSessions ? _self.activeSessions : activeSessions // ignore: cast_nullable_to_non_nullable
as int,pairedDevices: null == pairedDevices ? _self.pairedDevices : pairedDevices // ignore: cast_nullable_to_non_nullable
as int,requestCountRecent: null == requestCountRecent ? _self.requestCountRecent : requestCountRecent // ignore: cast_nullable_to_non_nullable
as int,p50LatencyMs: null == p50LatencyMs ? _self.p50LatencyMs : p50LatencyMs // ignore: cast_nullable_to_non_nullable
as int,p95LatencyMs: null == p95LatencyMs ? _self.p95LatencyMs : p95LatencyMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$KdsStationDto {

 String get station; int get pendingTickets; int get staffOnline;
/// Create a copy of KdsStationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdsStationDtoCopyWith<KdsStationDto> get copyWith => _$KdsStationDtoCopyWithImpl<KdsStationDto>(this as KdsStationDto, _$identity);

  /// Serializes this KdsStationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdsStationDto&&(identical(other.station, station) || other.station == station)&&(identical(other.pendingTickets, pendingTickets) || other.pendingTickets == pendingTickets)&&(identical(other.staffOnline, staffOnline) || other.staffOnline == staffOnline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,station,pendingTickets,staffOnline);

@override
String toString() {
  return 'KdsStationDto(station: $station, pendingTickets: $pendingTickets, staffOnline: $staffOnline)';
}


}

/// @nodoc
abstract mixin class $KdsStationDtoCopyWith<$Res>  {
  factory $KdsStationDtoCopyWith(KdsStationDto value, $Res Function(KdsStationDto) _then) = _$KdsStationDtoCopyWithImpl;
@useResult
$Res call({
 String station, int pendingTickets, int staffOnline
});




}
/// @nodoc
class _$KdsStationDtoCopyWithImpl<$Res>
    implements $KdsStationDtoCopyWith<$Res> {
  _$KdsStationDtoCopyWithImpl(this._self, this._then);

  final KdsStationDto _self;
  final $Res Function(KdsStationDto) _then;

/// Create a copy of KdsStationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? station = null,Object? pendingTickets = null,Object? staffOnline = null,}) {
  return _then(_self.copyWith(
station: null == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as String,pendingTickets: null == pendingTickets ? _self.pendingTickets : pendingTickets // ignore: cast_nullable_to_non_nullable
as int,staffOnline: null == staffOnline ? _self.staffOnline : staffOnline // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [KdsStationDto].
extension KdsStationDtoPatterns on KdsStationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KdsStationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KdsStationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KdsStationDto value)  $default,){
final _that = this;
switch (_that) {
case _KdsStationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KdsStationDto value)?  $default,){
final _that = this;
switch (_that) {
case _KdsStationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String station,  int pendingTickets,  int staffOnline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KdsStationDto() when $default != null:
return $default(_that.station,_that.pendingTickets,_that.staffOnline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String station,  int pendingTickets,  int staffOnline)  $default,) {final _that = this;
switch (_that) {
case _KdsStationDto():
return $default(_that.station,_that.pendingTickets,_that.staffOnline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String station,  int pendingTickets,  int staffOnline)?  $default,) {final _that = this;
switch (_that) {
case _KdsStationDto() when $default != null:
return $default(_that.station,_that.pendingTickets,_that.staffOnline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KdsStationDto implements KdsStationDto {
  const _KdsStationDto({required this.station, this.pendingTickets = 0, this.staffOnline = 0});
  factory _KdsStationDto.fromJson(Map<String, dynamic> json) => _$KdsStationDtoFromJson(json);

@override final  String station;
@override@JsonKey() final  int pendingTickets;
@override@JsonKey() final  int staffOnline;

/// Create a copy of KdsStationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KdsStationDtoCopyWith<_KdsStationDto> get copyWith => __$KdsStationDtoCopyWithImpl<_KdsStationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KdsStationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KdsStationDto&&(identical(other.station, station) || other.station == station)&&(identical(other.pendingTickets, pendingTickets) || other.pendingTickets == pendingTickets)&&(identical(other.staffOnline, staffOnline) || other.staffOnline == staffOnline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,station,pendingTickets,staffOnline);

@override
String toString() {
  return 'KdsStationDto(station: $station, pendingTickets: $pendingTickets, staffOnline: $staffOnline)';
}


}

/// @nodoc
abstract mixin class _$KdsStationDtoCopyWith<$Res> implements $KdsStationDtoCopyWith<$Res> {
  factory _$KdsStationDtoCopyWith(_KdsStationDto value, $Res Function(_KdsStationDto) _then) = __$KdsStationDtoCopyWithImpl;
@override @useResult
$Res call({
 String station, int pendingTickets, int staffOnline
});




}
/// @nodoc
class __$KdsStationDtoCopyWithImpl<$Res>
    implements _$KdsStationDtoCopyWith<$Res> {
  __$KdsStationDtoCopyWithImpl(this._self, this._then);

  final _KdsStationDto _self;
  final $Res Function(_KdsStationDto) _then;

/// Create a copy of KdsStationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? station = null,Object? pendingTickets = null,Object? staffOnline = null,}) {
  return _then(_KdsStationDto(
station: null == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as String,pendingTickets: null == pendingTickets ? _self.pendingTickets : pendingTickets // ignore: cast_nullable_to_non_nullable
as int,staffOnline: null == staffOnline ? _self.staffOnline : staffOnline // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$QueueDepthDto {

 int get total; Map<String, int> get byStation;
/// Create a copy of QueueDepthDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueDepthDtoCopyWith<QueueDepthDto> get copyWith => _$QueueDepthDtoCopyWithImpl<QueueDepthDto>(this as QueueDepthDto, _$identity);

  /// Serializes this QueueDepthDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueDepthDto&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.byStation, byStation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,const DeepCollectionEquality().hash(byStation));

@override
String toString() {
  return 'QueueDepthDto(total: $total, byStation: $byStation)';
}


}

/// @nodoc
abstract mixin class $QueueDepthDtoCopyWith<$Res>  {
  factory $QueueDepthDtoCopyWith(QueueDepthDto value, $Res Function(QueueDepthDto) _then) = _$QueueDepthDtoCopyWithImpl;
@useResult
$Res call({
 int total, Map<String, int> byStation
});




}
/// @nodoc
class _$QueueDepthDtoCopyWithImpl<$Res>
    implements $QueueDepthDtoCopyWith<$Res> {
  _$QueueDepthDtoCopyWithImpl(this._self, this._then);

  final QueueDepthDto _self;
  final $Res Function(QueueDepthDto) _then;

/// Create a copy of QueueDepthDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? byStation = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,byStation: null == byStation ? _self.byStation : byStation // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueDepthDto].
extension QueueDepthDtoPatterns on QueueDepthDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueDepthDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueDepthDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueDepthDto value)  $default,){
final _that = this;
switch (_that) {
case _QueueDepthDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueDepthDto value)?  $default,){
final _that = this;
switch (_that) {
case _QueueDepthDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  Map<String, int> byStation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueDepthDto() when $default != null:
return $default(_that.total,_that.byStation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  Map<String, int> byStation)  $default,) {final _that = this;
switch (_that) {
case _QueueDepthDto():
return $default(_that.total,_that.byStation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  Map<String, int> byStation)?  $default,) {final _that = this;
switch (_that) {
case _QueueDepthDto() when $default != null:
return $default(_that.total,_that.byStation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueDepthDto implements QueueDepthDto {
  const _QueueDepthDto({this.total = 0, final  Map<String, int> byStation = const <String, int>{}}): _byStation = byStation;
  factory _QueueDepthDto.fromJson(Map<String, dynamic> json) => _$QueueDepthDtoFromJson(json);

@override@JsonKey() final  int total;
 final  Map<String, int> _byStation;
@override@JsonKey() Map<String, int> get byStation {
  if (_byStation is EqualUnmodifiableMapView) return _byStation;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_byStation);
}


/// Create a copy of QueueDepthDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueDepthDtoCopyWith<_QueueDepthDto> get copyWith => __$QueueDepthDtoCopyWithImpl<_QueueDepthDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueDepthDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueDepthDto&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._byStation, _byStation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,const DeepCollectionEquality().hash(_byStation));

@override
String toString() {
  return 'QueueDepthDto(total: $total, byStation: $byStation)';
}


}

/// @nodoc
abstract mixin class _$QueueDepthDtoCopyWith<$Res> implements $QueueDepthDtoCopyWith<$Res> {
  factory _$QueueDepthDtoCopyWith(_QueueDepthDto value, $Res Function(_QueueDepthDto) _then) = __$QueueDepthDtoCopyWithImpl;
@override @useResult
$Res call({
 int total, Map<String, int> byStation
});




}
/// @nodoc
class __$QueueDepthDtoCopyWithImpl<$Res>
    implements _$QueueDepthDtoCopyWith<$Res> {
  __$QueueDepthDtoCopyWithImpl(this._self, this._then);

  final _QueueDepthDto _self;
  final $Res Function(_QueueDepthDto) _then;

/// Create a copy of QueueDepthDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? byStation = null,}) {
  return _then(_QueueDepthDto(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,byStation: null == byStation ? _self._byStation : byStation // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
