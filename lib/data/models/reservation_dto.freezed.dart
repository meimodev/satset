// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reservation_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReservationDto {

 String get id; String get name; String? get phone; int get partySize; DateTime get expectedAt; String get status; String? get zoneId; String? get tableId; String? get notes;/// The [[Pelanggan (member)]] the booking was made against, if the phone
/// matched one. [name] and [phone] stay the snapshot of what was booked.
 String? get memberId; DateTime get createdAt; DateTime? get updatedAt;
/// Create a copy of ReservationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReservationDtoCopyWith<ReservationDto> get copyWith => _$ReservationDtoCopyWithImpl<ReservationDto>(this as ReservationDto, _$identity);

  /// Serializes this ReservationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReservationDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.partySize, partySize) || other.partySize == partySize)&&(identical(other.expectedAt, expectedAt) || other.expectedAt == expectedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone,partySize,expectedAt,status,zoneId,tableId,notes,memberId,createdAt,updatedAt);

@override
String toString() {
  return 'ReservationDto(id: $id, name: $name, phone: $phone, partySize: $partySize, expectedAt: $expectedAt, status: $status, zoneId: $zoneId, tableId: $tableId, notes: $notes, memberId: $memberId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ReservationDtoCopyWith<$Res>  {
  factory $ReservationDtoCopyWith(ReservationDto value, $Res Function(ReservationDto) _then) = _$ReservationDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? phone, int partySize, DateTime expectedAt, String status, String? zoneId, String? tableId, String? notes, String? memberId, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$ReservationDtoCopyWithImpl<$Res>
    implements $ReservationDtoCopyWith<$Res> {
  _$ReservationDtoCopyWithImpl(this._self, this._then);

  final ReservationDto _self;
  final $Res Function(ReservationDto) _then;

/// Create a copy of ReservationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? phone = freezed,Object? partySize = null,Object? expectedAt = null,Object? status = null,Object? zoneId = freezed,Object? tableId = freezed,Object? notes = freezed,Object? memberId = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,partySize: null == partySize ? _self.partySize : partySize // ignore: cast_nullable_to_non_nullable
as int,expectedAt: null == expectedAt ? _self.expectedAt : expectedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,zoneId: freezed == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String?,tableId: freezed == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReservationDto].
extension ReservationDtoPatterns on ReservationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReservationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReservationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReservationDto value)  $default,){
final _that = this;
switch (_that) {
case _ReservationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReservationDto value)?  $default,){
final _that = this;
switch (_that) {
case _ReservationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? phone,  int partySize,  DateTime expectedAt,  String status,  String? zoneId,  String? tableId,  String? notes,  String? memberId,  DateTime createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReservationDto() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.partySize,_that.expectedAt,_that.status,_that.zoneId,_that.tableId,_that.notes,_that.memberId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? phone,  int partySize,  DateTime expectedAt,  String status,  String? zoneId,  String? tableId,  String? notes,  String? memberId,  DateTime createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ReservationDto():
return $default(_that.id,_that.name,_that.phone,_that.partySize,_that.expectedAt,_that.status,_that.zoneId,_that.tableId,_that.notes,_that.memberId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? phone,  int partySize,  DateTime expectedAt,  String status,  String? zoneId,  String? tableId,  String? notes,  String? memberId,  DateTime createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ReservationDto() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.partySize,_that.expectedAt,_that.status,_that.zoneId,_that.tableId,_that.notes,_that.memberId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReservationDto implements ReservationDto {
  const _ReservationDto({required this.id, required this.name, this.phone, this.partySize = 1, required this.expectedAt, this.status = 'pending', this.zoneId, this.tableId, this.notes, this.memberId, required this.createdAt, this.updatedAt});
  factory _ReservationDto.fromJson(Map<String, dynamic> json) => _$ReservationDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? phone;
@override@JsonKey() final  int partySize;
@override final  DateTime expectedAt;
@override@JsonKey() final  String status;
@override final  String? zoneId;
@override final  String? tableId;
@override final  String? notes;
/// The [[Pelanggan (member)]] the booking was made against, if the phone
/// matched one. [name] and [phone] stay the snapshot of what was booked.
@override final  String? memberId;
@override final  DateTime createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of ReservationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReservationDtoCopyWith<_ReservationDto> get copyWith => __$ReservationDtoCopyWithImpl<_ReservationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReservationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReservationDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.partySize, partySize) || other.partySize == partySize)&&(identical(other.expectedAt, expectedAt) || other.expectedAt == expectedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone,partySize,expectedAt,status,zoneId,tableId,notes,memberId,createdAt,updatedAt);

@override
String toString() {
  return 'ReservationDto(id: $id, name: $name, phone: $phone, partySize: $partySize, expectedAt: $expectedAt, status: $status, zoneId: $zoneId, tableId: $tableId, notes: $notes, memberId: $memberId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ReservationDtoCopyWith<$Res> implements $ReservationDtoCopyWith<$Res> {
  factory _$ReservationDtoCopyWith(_ReservationDto value, $Res Function(_ReservationDto) _then) = __$ReservationDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? phone, int partySize, DateTime expectedAt, String status, String? zoneId, String? tableId, String? notes, String? memberId, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$ReservationDtoCopyWithImpl<$Res>
    implements _$ReservationDtoCopyWith<$Res> {
  __$ReservationDtoCopyWithImpl(this._self, this._then);

  final _ReservationDto _self;
  final $Res Function(_ReservationDto) _then;

/// Create a copy of ReservationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? phone = freezed,Object? partySize = null,Object? expectedAt = null,Object? status = null,Object? zoneId = freezed,Object? tableId = freezed,Object? notes = freezed,Object? memberId = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_ReservationDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,partySize: null == partySize ? _self.partySize : partySize // ignore: cast_nullable_to_non_nullable
as int,expectedAt: null == expectedAt ? _self.expectedAt : expectedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,zoneId: freezed == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String?,tableId: freezed == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CreateReservationDto {

 String get name; String? get phone; int get partySize; DateTime get expectedAt; String? get zoneId; String? get tableId; String? get notes; String? get memberId;
/// Create a copy of CreateReservationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateReservationDtoCopyWith<CreateReservationDto> get copyWith => _$CreateReservationDtoCopyWithImpl<CreateReservationDto>(this as CreateReservationDto, _$identity);

  /// Serializes this CreateReservationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateReservationDto&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.partySize, partySize) || other.partySize == partySize)&&(identical(other.expectedAt, expectedAt) || other.expectedAt == expectedAt)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.memberId, memberId) || other.memberId == memberId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phone,partySize,expectedAt,zoneId,tableId,notes,memberId);

@override
String toString() {
  return 'CreateReservationDto(name: $name, phone: $phone, partySize: $partySize, expectedAt: $expectedAt, zoneId: $zoneId, tableId: $tableId, notes: $notes, memberId: $memberId)';
}


}

/// @nodoc
abstract mixin class $CreateReservationDtoCopyWith<$Res>  {
  factory $CreateReservationDtoCopyWith(CreateReservationDto value, $Res Function(CreateReservationDto) _then) = _$CreateReservationDtoCopyWithImpl;
@useResult
$Res call({
 String name, String? phone, int partySize, DateTime expectedAt, String? zoneId, String? tableId, String? notes, String? memberId
});




}
/// @nodoc
class _$CreateReservationDtoCopyWithImpl<$Res>
    implements $CreateReservationDtoCopyWith<$Res> {
  _$CreateReservationDtoCopyWithImpl(this._self, this._then);

  final CreateReservationDto _self;
  final $Res Function(CreateReservationDto) _then;

/// Create a copy of CreateReservationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? phone = freezed,Object? partySize = null,Object? expectedAt = null,Object? zoneId = freezed,Object? tableId = freezed,Object? notes = freezed,Object? memberId = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,partySize: null == partySize ? _self.partySize : partySize // ignore: cast_nullable_to_non_nullable
as int,expectedAt: null == expectedAt ? _self.expectedAt : expectedAt // ignore: cast_nullable_to_non_nullable
as DateTime,zoneId: freezed == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String?,tableId: freezed == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateReservationDto].
extension CreateReservationDtoPatterns on CreateReservationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateReservationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateReservationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateReservationDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateReservationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateReservationDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateReservationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? phone,  int partySize,  DateTime expectedAt,  String? zoneId,  String? tableId,  String? notes,  String? memberId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateReservationDto() when $default != null:
return $default(_that.name,_that.phone,_that.partySize,_that.expectedAt,_that.zoneId,_that.tableId,_that.notes,_that.memberId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? phone,  int partySize,  DateTime expectedAt,  String? zoneId,  String? tableId,  String? notes,  String? memberId)  $default,) {final _that = this;
switch (_that) {
case _CreateReservationDto():
return $default(_that.name,_that.phone,_that.partySize,_that.expectedAt,_that.zoneId,_that.tableId,_that.notes,_that.memberId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? phone,  int partySize,  DateTime expectedAt,  String? zoneId,  String? tableId,  String? notes,  String? memberId)?  $default,) {final _that = this;
switch (_that) {
case _CreateReservationDto() when $default != null:
return $default(_that.name,_that.phone,_that.partySize,_that.expectedAt,_that.zoneId,_that.tableId,_that.notes,_that.memberId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateReservationDto implements CreateReservationDto {
  const _CreateReservationDto({required this.name, this.phone, this.partySize = 1, required this.expectedAt, this.zoneId, this.tableId, this.notes, this.memberId});
  factory _CreateReservationDto.fromJson(Map<String, dynamic> json) => _$CreateReservationDtoFromJson(json);

@override final  String name;
@override final  String? phone;
@override@JsonKey() final  int partySize;
@override final  DateTime expectedAt;
@override final  String? zoneId;
@override final  String? tableId;
@override final  String? notes;
@override final  String? memberId;

/// Create a copy of CreateReservationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateReservationDtoCopyWith<_CreateReservationDto> get copyWith => __$CreateReservationDtoCopyWithImpl<_CreateReservationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateReservationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateReservationDto&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.partySize, partySize) || other.partySize == partySize)&&(identical(other.expectedAt, expectedAt) || other.expectedAt == expectedAt)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.memberId, memberId) || other.memberId == memberId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phone,partySize,expectedAt,zoneId,tableId,notes,memberId);

@override
String toString() {
  return 'CreateReservationDto(name: $name, phone: $phone, partySize: $partySize, expectedAt: $expectedAt, zoneId: $zoneId, tableId: $tableId, notes: $notes, memberId: $memberId)';
}


}

/// @nodoc
abstract mixin class _$CreateReservationDtoCopyWith<$Res> implements $CreateReservationDtoCopyWith<$Res> {
  factory _$CreateReservationDtoCopyWith(_CreateReservationDto value, $Res Function(_CreateReservationDto) _then) = __$CreateReservationDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String? phone, int partySize, DateTime expectedAt, String? zoneId, String? tableId, String? notes, String? memberId
});




}
/// @nodoc
class __$CreateReservationDtoCopyWithImpl<$Res>
    implements _$CreateReservationDtoCopyWith<$Res> {
  __$CreateReservationDtoCopyWithImpl(this._self, this._then);

  final _CreateReservationDto _self;
  final $Res Function(_CreateReservationDto) _then;

/// Create a copy of CreateReservationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? phone = freezed,Object? partySize = null,Object? expectedAt = null,Object? zoneId = freezed,Object? tableId = freezed,Object? notes = freezed,Object? memberId = freezed,}) {
  return _then(_CreateReservationDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,partySize: null == partySize ? _self.partySize : partySize // ignore: cast_nullable_to_non_nullable
as int,expectedAt: null == expectedAt ? _self.expectedAt : expectedAt // ignore: cast_nullable_to_non_nullable
as DateTime,zoneId: freezed == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String?,tableId: freezed == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PatchReservationDto {

 String? get name; String? get phone; int? get partySize; DateTime? get expectedAt; String? get status; String? get zoneId; String? get tableId; String? get notes; String? get memberId;
/// Create a copy of PatchReservationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatchReservationDtoCopyWith<PatchReservationDto> get copyWith => _$PatchReservationDtoCopyWithImpl<PatchReservationDto>(this as PatchReservationDto, _$identity);

  /// Serializes this PatchReservationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatchReservationDto&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.partySize, partySize) || other.partySize == partySize)&&(identical(other.expectedAt, expectedAt) || other.expectedAt == expectedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.memberId, memberId) || other.memberId == memberId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phone,partySize,expectedAt,status,zoneId,tableId,notes,memberId);

@override
String toString() {
  return 'PatchReservationDto(name: $name, phone: $phone, partySize: $partySize, expectedAt: $expectedAt, status: $status, zoneId: $zoneId, tableId: $tableId, notes: $notes, memberId: $memberId)';
}


}

/// @nodoc
abstract mixin class $PatchReservationDtoCopyWith<$Res>  {
  factory $PatchReservationDtoCopyWith(PatchReservationDto value, $Res Function(PatchReservationDto) _then) = _$PatchReservationDtoCopyWithImpl;
@useResult
$Res call({
 String? name, String? phone, int? partySize, DateTime? expectedAt, String? status, String? zoneId, String? tableId, String? notes, String? memberId
});




}
/// @nodoc
class _$PatchReservationDtoCopyWithImpl<$Res>
    implements $PatchReservationDtoCopyWith<$Res> {
  _$PatchReservationDtoCopyWithImpl(this._self, this._then);

  final PatchReservationDto _self;
  final $Res Function(PatchReservationDto) _then;

/// Create a copy of PatchReservationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? phone = freezed,Object? partySize = freezed,Object? expectedAt = freezed,Object? status = freezed,Object? zoneId = freezed,Object? tableId = freezed,Object? notes = freezed,Object? memberId = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,partySize: freezed == partySize ? _self.partySize : partySize // ignore: cast_nullable_to_non_nullable
as int?,expectedAt: freezed == expectedAt ? _self.expectedAt : expectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,zoneId: freezed == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String?,tableId: freezed == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PatchReservationDto].
extension PatchReservationDtoPatterns on PatchReservationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatchReservationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatchReservationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatchReservationDto value)  $default,){
final _that = this;
switch (_that) {
case _PatchReservationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatchReservationDto value)?  $default,){
final _that = this;
switch (_that) {
case _PatchReservationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? phone,  int? partySize,  DateTime? expectedAt,  String? status,  String? zoneId,  String? tableId,  String? notes,  String? memberId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatchReservationDto() when $default != null:
return $default(_that.name,_that.phone,_that.partySize,_that.expectedAt,_that.status,_that.zoneId,_that.tableId,_that.notes,_that.memberId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? phone,  int? partySize,  DateTime? expectedAt,  String? status,  String? zoneId,  String? tableId,  String? notes,  String? memberId)  $default,) {final _that = this;
switch (_that) {
case _PatchReservationDto():
return $default(_that.name,_that.phone,_that.partySize,_that.expectedAt,_that.status,_that.zoneId,_that.tableId,_that.notes,_that.memberId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? phone,  int? partySize,  DateTime? expectedAt,  String? status,  String? zoneId,  String? tableId,  String? notes,  String? memberId)?  $default,) {final _that = this;
switch (_that) {
case _PatchReservationDto() when $default != null:
return $default(_that.name,_that.phone,_that.partySize,_that.expectedAt,_that.status,_that.zoneId,_that.tableId,_that.notes,_that.memberId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PatchReservationDto implements PatchReservationDto {
  const _PatchReservationDto({this.name, this.phone, this.partySize, this.expectedAt, this.status, this.zoneId, this.tableId, this.notes, this.memberId});
  factory _PatchReservationDto.fromJson(Map<String, dynamic> json) => _$PatchReservationDtoFromJson(json);

@override final  String? name;
@override final  String? phone;
@override final  int? partySize;
@override final  DateTime? expectedAt;
@override final  String? status;
@override final  String? zoneId;
@override final  String? tableId;
@override final  String? notes;
@override final  String? memberId;

/// Create a copy of PatchReservationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatchReservationDtoCopyWith<_PatchReservationDto> get copyWith => __$PatchReservationDtoCopyWithImpl<_PatchReservationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatchReservationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatchReservationDto&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.partySize, partySize) || other.partySize == partySize)&&(identical(other.expectedAt, expectedAt) || other.expectedAt == expectedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.memberId, memberId) || other.memberId == memberId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phone,partySize,expectedAt,status,zoneId,tableId,notes,memberId);

@override
String toString() {
  return 'PatchReservationDto(name: $name, phone: $phone, partySize: $partySize, expectedAt: $expectedAt, status: $status, zoneId: $zoneId, tableId: $tableId, notes: $notes, memberId: $memberId)';
}


}

/// @nodoc
abstract mixin class _$PatchReservationDtoCopyWith<$Res> implements $PatchReservationDtoCopyWith<$Res> {
  factory _$PatchReservationDtoCopyWith(_PatchReservationDto value, $Res Function(_PatchReservationDto) _then) = __$PatchReservationDtoCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? phone, int? partySize, DateTime? expectedAt, String? status, String? zoneId, String? tableId, String? notes, String? memberId
});




}
/// @nodoc
class __$PatchReservationDtoCopyWithImpl<$Res>
    implements _$PatchReservationDtoCopyWith<$Res> {
  __$PatchReservationDtoCopyWithImpl(this._self, this._then);

  final _PatchReservationDto _self;
  final $Res Function(_PatchReservationDto) _then;

/// Create a copy of PatchReservationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? phone = freezed,Object? partySize = freezed,Object? expectedAt = freezed,Object? status = freezed,Object? zoneId = freezed,Object? tableId = freezed,Object? notes = freezed,Object? memberId = freezed,}) {
  return _then(_PatchReservationDto(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,partySize: freezed == partySize ? _self.partySize : partySize // ignore: cast_nullable_to_non_nullable
as int?,expectedAt: freezed == expectedAt ? _self.expectedAt : expectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,zoneId: freezed == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String?,tableId: freezed == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
