// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'printer_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PrinterDto {

 String get id; String get label; String get host; int get port; String get kind; bool get enabled; DateTime? get lastSeenAt; DateTime get createdAt;
/// Create a copy of PrinterDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrinterDtoCopyWith<PrinterDto> get copyWith => _$PrinterDtoCopyWithImpl<PrinterDto>(this as PrinterDto, _$identity);

  /// Serializes this PrinterDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrinterDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,host,port,kind,enabled,lastSeenAt,createdAt);

@override
String toString() {
  return 'PrinterDto(id: $id, label: $label, host: $host, port: $port, kind: $kind, enabled: $enabled, lastSeenAt: $lastSeenAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PrinterDtoCopyWith<$Res>  {
  factory $PrinterDtoCopyWith(PrinterDto value, $Res Function(PrinterDto) _then) = _$PrinterDtoCopyWithImpl;
@useResult
$Res call({
 String id, String label, String host, int port, String kind, bool enabled, DateTime? lastSeenAt, DateTime createdAt
});




}
/// @nodoc
class _$PrinterDtoCopyWithImpl<$Res>
    implements $PrinterDtoCopyWith<$Res> {
  _$PrinterDtoCopyWithImpl(this._self, this._then);

  final PrinterDto _self;
  final $Res Function(PrinterDto) _then;

/// Create a copy of PrinterDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? host = null,Object? port = null,Object? kind = null,Object? enabled = null,Object? lastSeenAt = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PrinterDto].
extension PrinterDtoPatterns on PrinterDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrinterDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrinterDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrinterDto value)  $default,){
final _that = this;
switch (_that) {
case _PrinterDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrinterDto value)?  $default,){
final _that = this;
switch (_that) {
case _PrinterDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String host,  int port,  String kind,  bool enabled,  DateTime? lastSeenAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrinterDto() when $default != null:
return $default(_that.id,_that.label,_that.host,_that.port,_that.kind,_that.enabled,_that.lastSeenAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String host,  int port,  String kind,  bool enabled,  DateTime? lastSeenAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _PrinterDto():
return $default(_that.id,_that.label,_that.host,_that.port,_that.kind,_that.enabled,_that.lastSeenAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String host,  int port,  String kind,  bool enabled,  DateTime? lastSeenAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PrinterDto() when $default != null:
return $default(_that.id,_that.label,_that.host,_that.port,_that.kind,_that.enabled,_that.lastSeenAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PrinterDto implements PrinterDto {
  const _PrinterDto({required this.id, required this.label, required this.host, this.port = 9100, this.kind = 'escpos', this.enabled = true, this.lastSeenAt, required this.createdAt});
  factory _PrinterDto.fromJson(Map<String, dynamic> json) => _$PrinterDtoFromJson(json);

@override final  String id;
@override final  String label;
@override final  String host;
@override@JsonKey() final  int port;
@override@JsonKey() final  String kind;
@override@JsonKey() final  bool enabled;
@override final  DateTime? lastSeenAt;
@override final  DateTime createdAt;

/// Create a copy of PrinterDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrinterDtoCopyWith<_PrinterDto> get copyWith => __$PrinterDtoCopyWithImpl<_PrinterDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrinterDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrinterDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,host,port,kind,enabled,lastSeenAt,createdAt);

@override
String toString() {
  return 'PrinterDto(id: $id, label: $label, host: $host, port: $port, kind: $kind, enabled: $enabled, lastSeenAt: $lastSeenAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PrinterDtoCopyWith<$Res> implements $PrinterDtoCopyWith<$Res> {
  factory _$PrinterDtoCopyWith(_PrinterDto value, $Res Function(_PrinterDto) _then) = __$PrinterDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String host, int port, String kind, bool enabled, DateTime? lastSeenAt, DateTime createdAt
});




}
/// @nodoc
class __$PrinterDtoCopyWithImpl<$Res>
    implements _$PrinterDtoCopyWith<$Res> {
  __$PrinterDtoCopyWithImpl(this._self, this._then);

  final _PrinterDto _self;
  final $Res Function(_PrinterDto) _then;

/// Create a copy of PrinterDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? host = null,Object? port = null,Object? kind = null,Object? enabled = null,Object? lastSeenAt = freezed,Object? createdAt = null,}) {
  return _then(_PrinterDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
