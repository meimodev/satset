// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'table_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TableDto {

 String get id; String get zoneId; String? get label; int get pax; int get capacity; bool get active; String get status; int get openAmount; int get readyCount; String? get lastActorId; String? get lockedBy; String? get lockedByName; DateTime? get lockedAt; DateTime? get lockExpiresAt; DateTime? get openedAt; String? get guestName; String? get guestNotes; String? get reservationId; String? get currentVisitId; DateTime? get billClosedAt; String? get moneyState;
/// Create a copy of TableDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TableDtoCopyWith<TableDto> get copyWith => _$TableDtoCopyWithImpl<TableDto>(this as TableDto, _$identity);

  /// Serializes this TableDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TableDto&&(identical(other.id, id) || other.id == id)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.label, label) || other.label == label)&&(identical(other.pax, pax) || other.pax == pax)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.active, active) || other.active == active)&&(identical(other.status, status) || other.status == status)&&(identical(other.openAmount, openAmount) || other.openAmount == openAmount)&&(identical(other.readyCount, readyCount) || other.readyCount == readyCount)&&(identical(other.lastActorId, lastActorId) || other.lastActorId == lastActorId)&&(identical(other.lockedBy, lockedBy) || other.lockedBy == lockedBy)&&(identical(other.lockedByName, lockedByName) || other.lockedByName == lockedByName)&&(identical(other.lockedAt, lockedAt) || other.lockedAt == lockedAt)&&(identical(other.lockExpiresAt, lockExpiresAt) || other.lockExpiresAt == lockExpiresAt)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.guestName, guestName) || other.guestName == guestName)&&(identical(other.guestNotes, guestNotes) || other.guestNotes == guestNotes)&&(identical(other.reservationId, reservationId) || other.reservationId == reservationId)&&(identical(other.currentVisitId, currentVisitId) || other.currentVisitId == currentVisitId)&&(identical(other.billClosedAt, billClosedAt) || other.billClosedAt == billClosedAt)&&(identical(other.moneyState, moneyState) || other.moneyState == moneyState));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,zoneId,label,pax,capacity,active,status,openAmount,readyCount,lastActorId,lockedBy,lockedByName,lockedAt,lockExpiresAt,openedAt,guestName,guestNotes,reservationId,currentVisitId,billClosedAt,moneyState]);

@override
String toString() {
  return 'TableDto(id: $id, zoneId: $zoneId, label: $label, pax: $pax, capacity: $capacity, active: $active, status: $status, openAmount: $openAmount, readyCount: $readyCount, lastActorId: $lastActorId, lockedBy: $lockedBy, lockedByName: $lockedByName, lockedAt: $lockedAt, lockExpiresAt: $lockExpiresAt, openedAt: $openedAt, guestName: $guestName, guestNotes: $guestNotes, reservationId: $reservationId, currentVisitId: $currentVisitId, billClosedAt: $billClosedAt, moneyState: $moneyState)';
}


}

/// @nodoc
abstract mixin class $TableDtoCopyWith<$Res>  {
  factory $TableDtoCopyWith(TableDto value, $Res Function(TableDto) _then) = _$TableDtoCopyWithImpl;
@useResult
$Res call({
 String id, String zoneId, String? label, int pax, int capacity, bool active, String status, int openAmount, int readyCount, String? lastActorId, String? lockedBy, String? lockedByName, DateTime? lockedAt, DateTime? lockExpiresAt, DateTime? openedAt, String? guestName, String? guestNotes, String? reservationId, String? currentVisitId, DateTime? billClosedAt, String? moneyState
});




}
/// @nodoc
class _$TableDtoCopyWithImpl<$Res>
    implements $TableDtoCopyWith<$Res> {
  _$TableDtoCopyWithImpl(this._self, this._then);

  final TableDto _self;
  final $Res Function(TableDto) _then;

/// Create a copy of TableDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? zoneId = null,Object? label = freezed,Object? pax = null,Object? capacity = null,Object? active = null,Object? status = null,Object? openAmount = null,Object? readyCount = null,Object? lastActorId = freezed,Object? lockedBy = freezed,Object? lockedByName = freezed,Object? lockedAt = freezed,Object? lockExpiresAt = freezed,Object? openedAt = freezed,Object? guestName = freezed,Object? guestNotes = freezed,Object? reservationId = freezed,Object? currentVisitId = freezed,Object? billClosedAt = freezed,Object? moneyState = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,zoneId: null == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,pax: null == pax ? _self.pax : pax // ignore: cast_nullable_to_non_nullable
as int,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,openAmount: null == openAmount ? _self.openAmount : openAmount // ignore: cast_nullable_to_non_nullable
as int,readyCount: null == readyCount ? _self.readyCount : readyCount // ignore: cast_nullable_to_non_nullable
as int,lastActorId: freezed == lastActorId ? _self.lastActorId : lastActorId // ignore: cast_nullable_to_non_nullable
as String?,lockedBy: freezed == lockedBy ? _self.lockedBy : lockedBy // ignore: cast_nullable_to_non_nullable
as String?,lockedByName: freezed == lockedByName ? _self.lockedByName : lockedByName // ignore: cast_nullable_to_non_nullable
as String?,lockedAt: freezed == lockedAt ? _self.lockedAt : lockedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lockExpiresAt: freezed == lockExpiresAt ? _self.lockExpiresAt : lockExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,openedAt: freezed == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,guestName: freezed == guestName ? _self.guestName : guestName // ignore: cast_nullable_to_non_nullable
as String?,guestNotes: freezed == guestNotes ? _self.guestNotes : guestNotes // ignore: cast_nullable_to_non_nullable
as String?,reservationId: freezed == reservationId ? _self.reservationId : reservationId // ignore: cast_nullable_to_non_nullable
as String?,currentVisitId: freezed == currentVisitId ? _self.currentVisitId : currentVisitId // ignore: cast_nullable_to_non_nullable
as String?,billClosedAt: freezed == billClosedAt ? _self.billClosedAt : billClosedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,moneyState: freezed == moneyState ? _self.moneyState : moneyState // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TableDto].
extension TableDtoPatterns on TableDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TableDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TableDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TableDto value)  $default,){
final _that = this;
switch (_that) {
case _TableDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TableDto value)?  $default,){
final _that = this;
switch (_that) {
case _TableDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String zoneId,  String? label,  int pax,  int capacity,  bool active,  String status,  int openAmount,  int readyCount,  String? lastActorId,  String? lockedBy,  String? lockedByName,  DateTime? lockedAt,  DateTime? lockExpiresAt,  DateTime? openedAt,  String? guestName,  String? guestNotes,  String? reservationId,  String? currentVisitId,  DateTime? billClosedAt,  String? moneyState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TableDto() when $default != null:
return $default(_that.id,_that.zoneId,_that.label,_that.pax,_that.capacity,_that.active,_that.status,_that.openAmount,_that.readyCount,_that.lastActorId,_that.lockedBy,_that.lockedByName,_that.lockedAt,_that.lockExpiresAt,_that.openedAt,_that.guestName,_that.guestNotes,_that.reservationId,_that.currentVisitId,_that.billClosedAt,_that.moneyState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String zoneId,  String? label,  int pax,  int capacity,  bool active,  String status,  int openAmount,  int readyCount,  String? lastActorId,  String? lockedBy,  String? lockedByName,  DateTime? lockedAt,  DateTime? lockExpiresAt,  DateTime? openedAt,  String? guestName,  String? guestNotes,  String? reservationId,  String? currentVisitId,  DateTime? billClosedAt,  String? moneyState)  $default,) {final _that = this;
switch (_that) {
case _TableDto():
return $default(_that.id,_that.zoneId,_that.label,_that.pax,_that.capacity,_that.active,_that.status,_that.openAmount,_that.readyCount,_that.lastActorId,_that.lockedBy,_that.lockedByName,_that.lockedAt,_that.lockExpiresAt,_that.openedAt,_that.guestName,_that.guestNotes,_that.reservationId,_that.currentVisitId,_that.billClosedAt,_that.moneyState);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String zoneId,  String? label,  int pax,  int capacity,  bool active,  String status,  int openAmount,  int readyCount,  String? lastActorId,  String? lockedBy,  String? lockedByName,  DateTime? lockedAt,  DateTime? lockExpiresAt,  DateTime? openedAt,  String? guestName,  String? guestNotes,  String? reservationId,  String? currentVisitId,  DateTime? billClosedAt,  String? moneyState)?  $default,) {final _that = this;
switch (_that) {
case _TableDto() when $default != null:
return $default(_that.id,_that.zoneId,_that.label,_that.pax,_that.capacity,_that.active,_that.status,_that.openAmount,_that.readyCount,_that.lastActorId,_that.lockedBy,_that.lockedByName,_that.lockedAt,_that.lockExpiresAt,_that.openedAt,_that.guestName,_that.guestNotes,_that.reservationId,_that.currentVisitId,_that.billClosedAt,_that.moneyState);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TableDto implements TableDto {
  const _TableDto({required this.id, required this.zoneId, required this.label, this.pax = 0, this.capacity = 2, this.active = true, this.status = 'available', this.openAmount = 0, this.readyCount = 0, this.lastActorId, this.lockedBy, this.lockedByName, this.lockedAt, this.lockExpiresAt, this.openedAt, this.guestName, this.guestNotes, this.reservationId, this.currentVisitId, this.billClosedAt, this.moneyState});
  factory _TableDto.fromJson(Map<String, dynamic> json) => _$TableDtoFromJson(json);

@override final  String id;
@override final  String zoneId;
@override final  String? label;
@override@JsonKey() final  int pax;
@override@JsonKey() final  int capacity;
@override@JsonKey() final  bool active;
@override@JsonKey() final  String status;
@override@JsonKey() final  int openAmount;
@override@JsonKey() final  int readyCount;
@override final  String? lastActorId;
@override final  String? lockedBy;
@override final  String? lockedByName;
@override final  DateTime? lockedAt;
@override final  DateTime? lockExpiresAt;
@override final  DateTime? openedAt;
@override final  String? guestName;
@override final  String? guestNotes;
@override final  String? reservationId;
@override final  String? currentVisitId;
@override final  DateTime? billClosedAt;
@override final  String? moneyState;

/// Create a copy of TableDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TableDtoCopyWith<_TableDto> get copyWith => __$TableDtoCopyWithImpl<_TableDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TableDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TableDto&&(identical(other.id, id) || other.id == id)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.label, label) || other.label == label)&&(identical(other.pax, pax) || other.pax == pax)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.active, active) || other.active == active)&&(identical(other.status, status) || other.status == status)&&(identical(other.openAmount, openAmount) || other.openAmount == openAmount)&&(identical(other.readyCount, readyCount) || other.readyCount == readyCount)&&(identical(other.lastActorId, lastActorId) || other.lastActorId == lastActorId)&&(identical(other.lockedBy, lockedBy) || other.lockedBy == lockedBy)&&(identical(other.lockedByName, lockedByName) || other.lockedByName == lockedByName)&&(identical(other.lockedAt, lockedAt) || other.lockedAt == lockedAt)&&(identical(other.lockExpiresAt, lockExpiresAt) || other.lockExpiresAt == lockExpiresAt)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.guestName, guestName) || other.guestName == guestName)&&(identical(other.guestNotes, guestNotes) || other.guestNotes == guestNotes)&&(identical(other.reservationId, reservationId) || other.reservationId == reservationId)&&(identical(other.currentVisitId, currentVisitId) || other.currentVisitId == currentVisitId)&&(identical(other.billClosedAt, billClosedAt) || other.billClosedAt == billClosedAt)&&(identical(other.moneyState, moneyState) || other.moneyState == moneyState));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,zoneId,label,pax,capacity,active,status,openAmount,readyCount,lastActorId,lockedBy,lockedByName,lockedAt,lockExpiresAt,openedAt,guestName,guestNotes,reservationId,currentVisitId,billClosedAt,moneyState]);

@override
String toString() {
  return 'TableDto(id: $id, zoneId: $zoneId, label: $label, pax: $pax, capacity: $capacity, active: $active, status: $status, openAmount: $openAmount, readyCount: $readyCount, lastActorId: $lastActorId, lockedBy: $lockedBy, lockedByName: $lockedByName, lockedAt: $lockedAt, lockExpiresAt: $lockExpiresAt, openedAt: $openedAt, guestName: $guestName, guestNotes: $guestNotes, reservationId: $reservationId, currentVisitId: $currentVisitId, billClosedAt: $billClosedAt, moneyState: $moneyState)';
}


}

/// @nodoc
abstract mixin class _$TableDtoCopyWith<$Res> implements $TableDtoCopyWith<$Res> {
  factory _$TableDtoCopyWith(_TableDto value, $Res Function(_TableDto) _then) = __$TableDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String zoneId, String? label, int pax, int capacity, bool active, String status, int openAmount, int readyCount, String? lastActorId, String? lockedBy, String? lockedByName, DateTime? lockedAt, DateTime? lockExpiresAt, DateTime? openedAt, String? guestName, String? guestNotes, String? reservationId, String? currentVisitId, DateTime? billClosedAt, String? moneyState
});




}
/// @nodoc
class __$TableDtoCopyWithImpl<$Res>
    implements _$TableDtoCopyWith<$Res> {
  __$TableDtoCopyWithImpl(this._self, this._then);

  final _TableDto _self;
  final $Res Function(_TableDto) _then;

/// Create a copy of TableDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? zoneId = null,Object? label = freezed,Object? pax = null,Object? capacity = null,Object? active = null,Object? status = null,Object? openAmount = null,Object? readyCount = null,Object? lastActorId = freezed,Object? lockedBy = freezed,Object? lockedByName = freezed,Object? lockedAt = freezed,Object? lockExpiresAt = freezed,Object? openedAt = freezed,Object? guestName = freezed,Object? guestNotes = freezed,Object? reservationId = freezed,Object? currentVisitId = freezed,Object? billClosedAt = freezed,Object? moneyState = freezed,}) {
  return _then(_TableDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,zoneId: null == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,pax: null == pax ? _self.pax : pax // ignore: cast_nullable_to_non_nullable
as int,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,openAmount: null == openAmount ? _self.openAmount : openAmount // ignore: cast_nullable_to_non_nullable
as int,readyCount: null == readyCount ? _self.readyCount : readyCount // ignore: cast_nullable_to_non_nullable
as int,lastActorId: freezed == lastActorId ? _self.lastActorId : lastActorId // ignore: cast_nullable_to_non_nullable
as String?,lockedBy: freezed == lockedBy ? _self.lockedBy : lockedBy // ignore: cast_nullable_to_non_nullable
as String?,lockedByName: freezed == lockedByName ? _self.lockedByName : lockedByName // ignore: cast_nullable_to_non_nullable
as String?,lockedAt: freezed == lockedAt ? _self.lockedAt : lockedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lockExpiresAt: freezed == lockExpiresAt ? _self.lockExpiresAt : lockExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,openedAt: freezed == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,guestName: freezed == guestName ? _self.guestName : guestName // ignore: cast_nullable_to_non_nullable
as String?,guestNotes: freezed == guestNotes ? _self.guestNotes : guestNotes // ignore: cast_nullable_to_non_nullable
as String?,reservationId: freezed == reservationId ? _self.reservationId : reservationId // ignore: cast_nullable_to_non_nullable
as String?,currentVisitId: freezed == currentVisitId ? _self.currentVisitId : currentVisitId // ignore: cast_nullable_to_non_nullable
as String?,billClosedAt: freezed == billClosedAt ? _self.billClosedAt : billClosedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,moneyState: freezed == moneyState ? _self.moneyState : moneyState // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$UpdateTablePaxDto {

 int get pax;
/// Create a copy of UpdateTablePaxDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateTablePaxDtoCopyWith<UpdateTablePaxDto> get copyWith => _$UpdateTablePaxDtoCopyWithImpl<UpdateTablePaxDto>(this as UpdateTablePaxDto, _$identity);

  /// Serializes this UpdateTablePaxDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateTablePaxDto&&(identical(other.pax, pax) || other.pax == pax));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pax);

@override
String toString() {
  return 'UpdateTablePaxDto(pax: $pax)';
}


}

/// @nodoc
abstract mixin class $UpdateTablePaxDtoCopyWith<$Res>  {
  factory $UpdateTablePaxDtoCopyWith(UpdateTablePaxDto value, $Res Function(UpdateTablePaxDto) _then) = _$UpdateTablePaxDtoCopyWithImpl;
@useResult
$Res call({
 int pax
});




}
/// @nodoc
class _$UpdateTablePaxDtoCopyWithImpl<$Res>
    implements $UpdateTablePaxDtoCopyWith<$Res> {
  _$UpdateTablePaxDtoCopyWithImpl(this._self, this._then);

  final UpdateTablePaxDto _self;
  final $Res Function(UpdateTablePaxDto) _then;

/// Create a copy of UpdateTablePaxDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pax = null,}) {
  return _then(_self.copyWith(
pax: null == pax ? _self.pax : pax // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateTablePaxDto].
extension UpdateTablePaxDtoPatterns on UpdateTablePaxDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateTablePaxDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateTablePaxDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateTablePaxDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateTablePaxDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateTablePaxDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateTablePaxDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int pax)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateTablePaxDto() when $default != null:
return $default(_that.pax);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int pax)  $default,) {final _that = this;
switch (_that) {
case _UpdateTablePaxDto():
return $default(_that.pax);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int pax)?  $default,) {final _that = this;
switch (_that) {
case _UpdateTablePaxDto() when $default != null:
return $default(_that.pax);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateTablePaxDto implements UpdateTablePaxDto {
  const _UpdateTablePaxDto({required this.pax});
  factory _UpdateTablePaxDto.fromJson(Map<String, dynamic> json) => _$UpdateTablePaxDtoFromJson(json);

@override final  int pax;

/// Create a copy of UpdateTablePaxDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateTablePaxDtoCopyWith<_UpdateTablePaxDto> get copyWith => __$UpdateTablePaxDtoCopyWithImpl<_UpdateTablePaxDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateTablePaxDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateTablePaxDto&&(identical(other.pax, pax) || other.pax == pax));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pax);

@override
String toString() {
  return 'UpdateTablePaxDto(pax: $pax)';
}


}

/// @nodoc
abstract mixin class _$UpdateTablePaxDtoCopyWith<$Res> implements $UpdateTablePaxDtoCopyWith<$Res> {
  factory _$UpdateTablePaxDtoCopyWith(_UpdateTablePaxDto value, $Res Function(_UpdateTablePaxDto) _then) = __$UpdateTablePaxDtoCopyWithImpl;
@override @useResult
$Res call({
 int pax
});




}
/// @nodoc
class __$UpdateTablePaxDtoCopyWithImpl<$Res>
    implements _$UpdateTablePaxDtoCopyWith<$Res> {
  __$UpdateTablePaxDtoCopyWithImpl(this._self, this._then);

  final _UpdateTablePaxDto _self;
  final $Res Function(_UpdateTablePaxDto) _then;

/// Create a copy of UpdateTablePaxDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pax = null,}) {
  return _then(_UpdateTablePaxDto(
pax: null == pax ? _self.pax : pax // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$UpdateTableHandlerDto {

 String get userId;
/// Create a copy of UpdateTableHandlerDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateTableHandlerDtoCopyWith<UpdateTableHandlerDto> get copyWith => _$UpdateTableHandlerDtoCopyWithImpl<UpdateTableHandlerDto>(this as UpdateTableHandlerDto, _$identity);

  /// Serializes this UpdateTableHandlerDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateTableHandlerDto&&(identical(other.userId, userId) || other.userId == userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId);

@override
String toString() {
  return 'UpdateTableHandlerDto(userId: $userId)';
}


}

/// @nodoc
abstract mixin class $UpdateTableHandlerDtoCopyWith<$Res>  {
  factory $UpdateTableHandlerDtoCopyWith(UpdateTableHandlerDto value, $Res Function(UpdateTableHandlerDto) _then) = _$UpdateTableHandlerDtoCopyWithImpl;
@useResult
$Res call({
 String userId
});




}
/// @nodoc
class _$UpdateTableHandlerDtoCopyWithImpl<$Res>
    implements $UpdateTableHandlerDtoCopyWith<$Res> {
  _$UpdateTableHandlerDtoCopyWithImpl(this._self, this._then);

  final UpdateTableHandlerDto _self;
  final $Res Function(UpdateTableHandlerDto) _then;

/// Create a copy of UpdateTableHandlerDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateTableHandlerDto].
extension UpdateTableHandlerDtoPatterns on UpdateTableHandlerDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateTableHandlerDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateTableHandlerDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateTableHandlerDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateTableHandlerDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateTableHandlerDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateTableHandlerDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateTableHandlerDto() when $default != null:
return $default(_that.userId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId)  $default,) {final _that = this;
switch (_that) {
case _UpdateTableHandlerDto():
return $default(_that.userId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId)?  $default,) {final _that = this;
switch (_that) {
case _UpdateTableHandlerDto() when $default != null:
return $default(_that.userId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateTableHandlerDto implements UpdateTableHandlerDto {
  const _UpdateTableHandlerDto({required this.userId});
  factory _UpdateTableHandlerDto.fromJson(Map<String, dynamic> json) => _$UpdateTableHandlerDtoFromJson(json);

@override final  String userId;

/// Create a copy of UpdateTableHandlerDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateTableHandlerDtoCopyWith<_UpdateTableHandlerDto> get copyWith => __$UpdateTableHandlerDtoCopyWithImpl<_UpdateTableHandlerDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateTableHandlerDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateTableHandlerDto&&(identical(other.userId, userId) || other.userId == userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId);

@override
String toString() {
  return 'UpdateTableHandlerDto(userId: $userId)';
}


}

/// @nodoc
abstract mixin class _$UpdateTableHandlerDtoCopyWith<$Res> implements $UpdateTableHandlerDtoCopyWith<$Res> {
  factory _$UpdateTableHandlerDtoCopyWith(_UpdateTableHandlerDto value, $Res Function(_UpdateTableHandlerDto) _then) = __$UpdateTableHandlerDtoCopyWithImpl;
@override @useResult
$Res call({
 String userId
});




}
/// @nodoc
class __$UpdateTableHandlerDtoCopyWithImpl<$Res>
    implements _$UpdateTableHandlerDtoCopyWith<$Res> {
  __$UpdateTableHandlerDtoCopyWithImpl(this._self, this._then);

  final _UpdateTableHandlerDto _self;
  final $Res Function(_UpdateTableHandlerDto) _then;

/// Create a copy of UpdateTableHandlerDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,}) {
  return _then(_UpdateTableHandlerDto(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
