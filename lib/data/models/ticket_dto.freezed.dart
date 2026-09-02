// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TicketModifierDto {

 String get groupId; String get optionId; String get label; int get priceDelta;
/// Create a copy of TicketModifierDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketModifierDtoCopyWith<TicketModifierDto> get copyWith => _$TicketModifierDtoCopyWithImpl<TicketModifierDto>(this as TicketModifierDto, _$identity);

  /// Serializes this TicketModifierDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketModifierDto&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.optionId, optionId) || other.optionId == optionId)&&(identical(other.label, label) || other.label == label)&&(identical(other.priceDelta, priceDelta) || other.priceDelta == priceDelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupId,optionId,label,priceDelta);

@override
String toString() {
  return 'TicketModifierDto(groupId: $groupId, optionId: $optionId, label: $label, priceDelta: $priceDelta)';
}


}

/// @nodoc
abstract mixin class $TicketModifierDtoCopyWith<$Res>  {
  factory $TicketModifierDtoCopyWith(TicketModifierDto value, $Res Function(TicketModifierDto) _then) = _$TicketModifierDtoCopyWithImpl;
@useResult
$Res call({
 String groupId, String optionId, String label, int priceDelta
});




}
/// @nodoc
class _$TicketModifierDtoCopyWithImpl<$Res>
    implements $TicketModifierDtoCopyWith<$Res> {
  _$TicketModifierDtoCopyWithImpl(this._self, this._then);

  final TicketModifierDto _self;
  final $Res Function(TicketModifierDto) _then;

/// Create a copy of TicketModifierDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? optionId = null,Object? label = null,Object? priceDelta = null,}) {
  return _then(_self.copyWith(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,optionId: null == optionId ? _self.optionId : optionId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,priceDelta: null == priceDelta ? _self.priceDelta : priceDelta // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TicketModifierDto].
extension TicketModifierDtoPatterns on TicketModifierDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketModifierDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketModifierDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketModifierDto value)  $default,){
final _that = this;
switch (_that) {
case _TicketModifierDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketModifierDto value)?  $default,){
final _that = this;
switch (_that) {
case _TicketModifierDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String groupId,  String optionId,  String label,  int priceDelta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TicketModifierDto() when $default != null:
return $default(_that.groupId,_that.optionId,_that.label,_that.priceDelta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String groupId,  String optionId,  String label,  int priceDelta)  $default,) {final _that = this;
switch (_that) {
case _TicketModifierDto():
return $default(_that.groupId,_that.optionId,_that.label,_that.priceDelta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String groupId,  String optionId,  String label,  int priceDelta)?  $default,) {final _that = this;
switch (_that) {
case _TicketModifierDto() when $default != null:
return $default(_that.groupId,_that.optionId,_that.label,_that.priceDelta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketModifierDto implements TicketModifierDto {
  const _TicketModifierDto({this.groupId = '', this.optionId = '', this.label = '', this.priceDelta = 0});
  factory _TicketModifierDto.fromJson(Map<String, dynamic> json) => _$TicketModifierDtoFromJson(json);

@override@JsonKey() final  String groupId;
@override@JsonKey() final  String optionId;
@override@JsonKey() final  String label;
@override@JsonKey() final  int priceDelta;

/// Create a copy of TicketModifierDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketModifierDtoCopyWith<_TicketModifierDto> get copyWith => __$TicketModifierDtoCopyWithImpl<_TicketModifierDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketModifierDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketModifierDto&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.optionId, optionId) || other.optionId == optionId)&&(identical(other.label, label) || other.label == label)&&(identical(other.priceDelta, priceDelta) || other.priceDelta == priceDelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupId,optionId,label,priceDelta);

@override
String toString() {
  return 'TicketModifierDto(groupId: $groupId, optionId: $optionId, label: $label, priceDelta: $priceDelta)';
}


}

/// @nodoc
abstract mixin class _$TicketModifierDtoCopyWith<$Res> implements $TicketModifierDtoCopyWith<$Res> {
  factory _$TicketModifierDtoCopyWith(_TicketModifierDto value, $Res Function(_TicketModifierDto) _then) = __$TicketModifierDtoCopyWithImpl;
@override @useResult
$Res call({
 String groupId, String optionId, String label, int priceDelta
});




}
/// @nodoc
class __$TicketModifierDtoCopyWithImpl<$Res>
    implements _$TicketModifierDtoCopyWith<$Res> {
  __$TicketModifierDtoCopyWithImpl(this._self, this._then);

  final _TicketModifierDto _self;
  final $Res Function(_TicketModifierDto) _then;

/// Create a copy of TicketModifierDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? optionId = null,Object? label = null,Object? priceDelta = null,}) {
  return _then(_TicketModifierDto(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,optionId: null == optionId ? _self.optionId : optionId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,priceDelta: null == priceDelta ? _self.priceDelta : priceDelta // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TicketDto {

 String get id; String get tableId;/// Stable bill key (ADR-0024). Lets the KDS/board label table-less
/// (takeaway) lines via the visit. Nullable for pre-v29 rows.
 String? get visitId; String? get memberId; String get itemId; String get name; String get variantName; String get course; int get qty; List<TicketModifierDto> get modifiers; String? get note; int get price; String get status; DateTime get sentAt;/// When the waiter keyed the line, when that is not when the host received
/// it. Null on every ordinary send; non-null only for a line delivered off
/// a terputus handset's queue. Never age a line from this — `sentAt` is
/// what the kitchen's clocks mean. See ADR-0090.
 DateTime? get capturedAt;/// Who delivered a backlog someone else captured. ADR-0090.
 String? get replayedByUserId;/// Stamped on the `held → sent` fire. Null on a normal send. ADR-0043.
 DateTime? get firedAt; DateTime? get readyAt; DateTime? get servedAt; String? get voidReason; String? get voidReasonCode; String? get voidApprovedBy; String? get createdByUserId; String? get voidedByUserId;
/// Create a copy of TicketDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketDtoCopyWith<TicketDto> get copyWith => _$TicketDtoCopyWithImpl<TicketDto>(this as TicketDto, _$identity);

  /// Serializes this TicketDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketDto&&(identical(other.id, id) || other.id == id)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.variantName, variantName) || other.variantName == variantName)&&(identical(other.course, course) || other.course == course)&&(identical(other.qty, qty) || other.qty == qty)&&const DeepCollectionEquality().equals(other.modifiers, modifiers)&&(identical(other.note, note) || other.note == note)&&(identical(other.price, price) || other.price == price)&&(identical(other.status, status) || other.status == status)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.replayedByUserId, replayedByUserId) || other.replayedByUserId == replayedByUserId)&&(identical(other.firedAt, firedAt) || other.firedAt == firedAt)&&(identical(other.readyAt, readyAt) || other.readyAt == readyAt)&&(identical(other.servedAt, servedAt) || other.servedAt == servedAt)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason)&&(identical(other.voidReasonCode, voidReasonCode) || other.voidReasonCode == voidReasonCode)&&(identical(other.voidApprovedBy, voidApprovedBy) || other.voidApprovedBy == voidApprovedBy)&&(identical(other.createdByUserId, createdByUserId) || other.createdByUserId == createdByUserId)&&(identical(other.voidedByUserId, voidedByUserId) || other.voidedByUserId == voidedByUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,tableId,visitId,memberId,itemId,name,variantName,course,qty,const DeepCollectionEquality().hash(modifiers),note,price,status,sentAt,capturedAt,replayedByUserId,firedAt,readyAt,servedAt,voidReason,voidReasonCode,voidApprovedBy,createdByUserId,voidedByUserId]);

@override
String toString() {
  return 'TicketDto(id: $id, tableId: $tableId, visitId: $visitId, memberId: $memberId, itemId: $itemId, name: $name, variantName: $variantName, course: $course, qty: $qty, modifiers: $modifiers, note: $note, price: $price, status: $status, sentAt: $sentAt, capturedAt: $capturedAt, replayedByUserId: $replayedByUserId, firedAt: $firedAt, readyAt: $readyAt, servedAt: $servedAt, voidReason: $voidReason, voidReasonCode: $voidReasonCode, voidApprovedBy: $voidApprovedBy, createdByUserId: $createdByUserId, voidedByUserId: $voidedByUserId)';
}


}

/// @nodoc
abstract mixin class $TicketDtoCopyWith<$Res>  {
  factory $TicketDtoCopyWith(TicketDto value, $Res Function(TicketDto) _then) = _$TicketDtoCopyWithImpl;
@useResult
$Res call({
 String id, String tableId, String? visitId, String? memberId, String itemId, String name, String variantName, String course, int qty, List<TicketModifierDto> modifiers, String? note, int price, String status, DateTime sentAt, DateTime? capturedAt, String? replayedByUserId, DateTime? firedAt, DateTime? readyAt, DateTime? servedAt, String? voidReason, String? voidReasonCode, String? voidApprovedBy, String? createdByUserId, String? voidedByUserId
});




}
/// @nodoc
class _$TicketDtoCopyWithImpl<$Res>
    implements $TicketDtoCopyWith<$Res> {
  _$TicketDtoCopyWithImpl(this._self, this._then);

  final TicketDto _self;
  final $Res Function(TicketDto) _then;

/// Create a copy of TicketDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tableId = null,Object? visitId = freezed,Object? memberId = freezed,Object? itemId = null,Object? name = null,Object? variantName = null,Object? course = null,Object? qty = null,Object? modifiers = null,Object? note = freezed,Object? price = null,Object? status = null,Object? sentAt = null,Object? capturedAt = freezed,Object? replayedByUserId = freezed,Object? firedAt = freezed,Object? readyAt = freezed,Object? servedAt = freezed,Object? voidReason = freezed,Object? voidReasonCode = freezed,Object? voidApprovedBy = freezed,Object? createdByUserId = freezed,Object? voidedByUserId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tableId: null == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String,visitId: freezed == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variantName: null == variantName ? _self.variantName : variantName // ignore: cast_nullable_to_non_nullable
as String,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,modifiers: null == modifiers ? _self.modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as List<TicketModifierDto>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,replayedByUserId: freezed == replayedByUserId ? _self.replayedByUserId : replayedByUserId // ignore: cast_nullable_to_non_nullable
as String?,firedAt: freezed == firedAt ? _self.firedAt : firedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readyAt: freezed == readyAt ? _self.readyAt : readyAt // ignore: cast_nullable_to_non_nullable
as DateTime?,servedAt: freezed == servedAt ? _self.servedAt : servedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,voidReasonCode: freezed == voidReasonCode ? _self.voidReasonCode : voidReasonCode // ignore: cast_nullable_to_non_nullable
as String?,voidApprovedBy: freezed == voidApprovedBy ? _self.voidApprovedBy : voidApprovedBy // ignore: cast_nullable_to_non_nullable
as String?,createdByUserId: freezed == createdByUserId ? _self.createdByUserId : createdByUserId // ignore: cast_nullable_to_non_nullable
as String?,voidedByUserId: freezed == voidedByUserId ? _self.voidedByUserId : voidedByUserId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TicketDto].
extension TicketDtoPatterns on TicketDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketDto value)  $default,){
final _that = this;
switch (_that) {
case _TicketDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketDto value)?  $default,){
final _that = this;
switch (_that) {
case _TicketDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tableId,  String? visitId,  String? memberId,  String itemId,  String name,  String variantName,  String course,  int qty,  List<TicketModifierDto> modifiers,  String? note,  int price,  String status,  DateTime sentAt,  DateTime? capturedAt,  String? replayedByUserId,  DateTime? firedAt,  DateTime? readyAt,  DateTime? servedAt,  String? voidReason,  String? voidReasonCode,  String? voidApprovedBy,  String? createdByUserId,  String? voidedByUserId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TicketDto() when $default != null:
return $default(_that.id,_that.tableId,_that.visitId,_that.memberId,_that.itemId,_that.name,_that.variantName,_that.course,_that.qty,_that.modifiers,_that.note,_that.price,_that.status,_that.sentAt,_that.capturedAt,_that.replayedByUserId,_that.firedAt,_that.readyAt,_that.servedAt,_that.voidReason,_that.voidReasonCode,_that.voidApprovedBy,_that.createdByUserId,_that.voidedByUserId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tableId,  String? visitId,  String? memberId,  String itemId,  String name,  String variantName,  String course,  int qty,  List<TicketModifierDto> modifiers,  String? note,  int price,  String status,  DateTime sentAt,  DateTime? capturedAt,  String? replayedByUserId,  DateTime? firedAt,  DateTime? readyAt,  DateTime? servedAt,  String? voidReason,  String? voidReasonCode,  String? voidApprovedBy,  String? createdByUserId,  String? voidedByUserId)  $default,) {final _that = this;
switch (_that) {
case _TicketDto():
return $default(_that.id,_that.tableId,_that.visitId,_that.memberId,_that.itemId,_that.name,_that.variantName,_that.course,_that.qty,_that.modifiers,_that.note,_that.price,_that.status,_that.sentAt,_that.capturedAt,_that.replayedByUserId,_that.firedAt,_that.readyAt,_that.servedAt,_that.voidReason,_that.voidReasonCode,_that.voidApprovedBy,_that.createdByUserId,_that.voidedByUserId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tableId,  String? visitId,  String? memberId,  String itemId,  String name,  String variantName,  String course,  int qty,  List<TicketModifierDto> modifiers,  String? note,  int price,  String status,  DateTime sentAt,  DateTime? capturedAt,  String? replayedByUserId,  DateTime? firedAt,  DateTime? readyAt,  DateTime? servedAt,  String? voidReason,  String? voidReasonCode,  String? voidApprovedBy,  String? createdByUserId,  String? voidedByUserId)?  $default,) {final _that = this;
switch (_that) {
case _TicketDto() when $default != null:
return $default(_that.id,_that.tableId,_that.visitId,_that.memberId,_that.itemId,_that.name,_that.variantName,_that.course,_that.qty,_that.modifiers,_that.note,_that.price,_that.status,_that.sentAt,_that.capturedAt,_that.replayedByUserId,_that.firedAt,_that.readyAt,_that.servedAt,_that.voidReason,_that.voidReasonCode,_that.voidApprovedBy,_that.createdByUserId,_that.voidedByUserId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketDto implements TicketDto {
  const _TicketDto({required this.id, required this.tableId, this.visitId, this.memberId, required this.itemId, required this.name, this.variantName = '', required this.course, this.qty = 1, final  List<TicketModifierDto> modifiers = const <TicketModifierDto>[], this.note, required this.price, required this.status, required this.sentAt, this.capturedAt, this.replayedByUserId, this.firedAt, this.readyAt, this.servedAt, this.voidReason, this.voidReasonCode, this.voidApprovedBy, this.createdByUserId, this.voidedByUserId}): _modifiers = modifiers;
  factory _TicketDto.fromJson(Map<String, dynamic> json) => _$TicketDtoFromJson(json);

@override final  String id;
@override final  String tableId;
/// Stable bill key (ADR-0024). Lets the KDS/board label table-less
/// (takeaway) lines via the visit. Nullable for pre-v29 rows.
@override final  String? visitId;
@override final  String? memberId;
@override final  String itemId;
@override final  String name;
@override@JsonKey() final  String variantName;
@override final  String course;
@override@JsonKey() final  int qty;
 final  List<TicketModifierDto> _modifiers;
@override@JsonKey() List<TicketModifierDto> get modifiers {
  if (_modifiers is EqualUnmodifiableListView) return _modifiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modifiers);
}

@override final  String? note;
@override final  int price;
@override final  String status;
@override final  DateTime sentAt;
/// When the waiter keyed the line, when that is not when the host received
/// it. Null on every ordinary send; non-null only for a line delivered off
/// a terputus handset's queue. Never age a line from this — `sentAt` is
/// what the kitchen's clocks mean. See ADR-0090.
@override final  DateTime? capturedAt;
/// Who delivered a backlog someone else captured. ADR-0090.
@override final  String? replayedByUserId;
/// Stamped on the `held → sent` fire. Null on a normal send. ADR-0043.
@override final  DateTime? firedAt;
@override final  DateTime? readyAt;
@override final  DateTime? servedAt;
@override final  String? voidReason;
@override final  String? voidReasonCode;
@override final  String? voidApprovedBy;
@override final  String? createdByUserId;
@override final  String? voidedByUserId;

/// Create a copy of TicketDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketDtoCopyWith<_TicketDto> get copyWith => __$TicketDtoCopyWithImpl<_TicketDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketDto&&(identical(other.id, id) || other.id == id)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.variantName, variantName) || other.variantName == variantName)&&(identical(other.course, course) || other.course == course)&&(identical(other.qty, qty) || other.qty == qty)&&const DeepCollectionEquality().equals(other._modifiers, _modifiers)&&(identical(other.note, note) || other.note == note)&&(identical(other.price, price) || other.price == price)&&(identical(other.status, status) || other.status == status)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.replayedByUserId, replayedByUserId) || other.replayedByUserId == replayedByUserId)&&(identical(other.firedAt, firedAt) || other.firedAt == firedAt)&&(identical(other.readyAt, readyAt) || other.readyAt == readyAt)&&(identical(other.servedAt, servedAt) || other.servedAt == servedAt)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason)&&(identical(other.voidReasonCode, voidReasonCode) || other.voidReasonCode == voidReasonCode)&&(identical(other.voidApprovedBy, voidApprovedBy) || other.voidApprovedBy == voidApprovedBy)&&(identical(other.createdByUserId, createdByUserId) || other.createdByUserId == createdByUserId)&&(identical(other.voidedByUserId, voidedByUserId) || other.voidedByUserId == voidedByUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,tableId,visitId,memberId,itemId,name,variantName,course,qty,const DeepCollectionEquality().hash(_modifiers),note,price,status,sentAt,capturedAt,replayedByUserId,firedAt,readyAt,servedAt,voidReason,voidReasonCode,voidApprovedBy,createdByUserId,voidedByUserId]);

@override
String toString() {
  return 'TicketDto(id: $id, tableId: $tableId, visitId: $visitId, memberId: $memberId, itemId: $itemId, name: $name, variantName: $variantName, course: $course, qty: $qty, modifiers: $modifiers, note: $note, price: $price, status: $status, sentAt: $sentAt, capturedAt: $capturedAt, replayedByUserId: $replayedByUserId, firedAt: $firedAt, readyAt: $readyAt, servedAt: $servedAt, voidReason: $voidReason, voidReasonCode: $voidReasonCode, voidApprovedBy: $voidApprovedBy, createdByUserId: $createdByUserId, voidedByUserId: $voidedByUserId)';
}


}

/// @nodoc
abstract mixin class _$TicketDtoCopyWith<$Res> implements $TicketDtoCopyWith<$Res> {
  factory _$TicketDtoCopyWith(_TicketDto value, $Res Function(_TicketDto) _then) = __$TicketDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String tableId, String? visitId, String? memberId, String itemId, String name, String variantName, String course, int qty, List<TicketModifierDto> modifiers, String? note, int price, String status, DateTime sentAt, DateTime? capturedAt, String? replayedByUserId, DateTime? firedAt, DateTime? readyAt, DateTime? servedAt, String? voidReason, String? voidReasonCode, String? voidApprovedBy, String? createdByUserId, String? voidedByUserId
});




}
/// @nodoc
class __$TicketDtoCopyWithImpl<$Res>
    implements _$TicketDtoCopyWith<$Res> {
  __$TicketDtoCopyWithImpl(this._self, this._then);

  final _TicketDto _self;
  final $Res Function(_TicketDto) _then;

/// Create a copy of TicketDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tableId = null,Object? visitId = freezed,Object? memberId = freezed,Object? itemId = null,Object? name = null,Object? variantName = null,Object? course = null,Object? qty = null,Object? modifiers = null,Object? note = freezed,Object? price = null,Object? status = null,Object? sentAt = null,Object? capturedAt = freezed,Object? replayedByUserId = freezed,Object? firedAt = freezed,Object? readyAt = freezed,Object? servedAt = freezed,Object? voidReason = freezed,Object? voidReasonCode = freezed,Object? voidApprovedBy = freezed,Object? createdByUserId = freezed,Object? voidedByUserId = freezed,}) {
  return _then(_TicketDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tableId: null == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String,visitId: freezed == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variantName: null == variantName ? _self.variantName : variantName // ignore: cast_nullable_to_non_nullable
as String,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,modifiers: null == modifiers ? _self._modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as List<TicketModifierDto>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,replayedByUserId: freezed == replayedByUserId ? _self.replayedByUserId : replayedByUserId // ignore: cast_nullable_to_non_nullable
as String?,firedAt: freezed == firedAt ? _self.firedAt : firedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readyAt: freezed == readyAt ? _self.readyAt : readyAt // ignore: cast_nullable_to_non_nullable
as DateTime?,servedAt: freezed == servedAt ? _self.servedAt : servedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,voidReasonCode: freezed == voidReasonCode ? _self.voidReasonCode : voidReasonCode // ignore: cast_nullable_to_non_nullable
as String?,voidApprovedBy: freezed == voidApprovedBy ? _self.voidApprovedBy : voidApprovedBy // ignore: cast_nullable_to_non_nullable
as String?,createdByUserId: freezed == createdByUserId ? _self.createdByUserId : createdByUserId // ignore: cast_nullable_to_non_nullable
as String?,voidedByUserId: freezed == voidedByUserId ? _self.voidedByUserId : voidedByUserId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TicketTransitionRequestDto {

 String get status; String? get voidReason; String? get voidReasonCode;
/// Create a copy of TicketTransitionRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketTransitionRequestDtoCopyWith<TicketTransitionRequestDto> get copyWith => _$TicketTransitionRequestDtoCopyWithImpl<TicketTransitionRequestDto>(this as TicketTransitionRequestDto, _$identity);

  /// Serializes this TicketTransitionRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketTransitionRequestDto&&(identical(other.status, status) || other.status == status)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason)&&(identical(other.voidReasonCode, voidReasonCode) || other.voidReasonCode == voidReasonCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,voidReason,voidReasonCode);

@override
String toString() {
  return 'TicketTransitionRequestDto(status: $status, voidReason: $voidReason, voidReasonCode: $voidReasonCode)';
}


}

/// @nodoc
abstract mixin class $TicketTransitionRequestDtoCopyWith<$Res>  {
  factory $TicketTransitionRequestDtoCopyWith(TicketTransitionRequestDto value, $Res Function(TicketTransitionRequestDto) _then) = _$TicketTransitionRequestDtoCopyWithImpl;
@useResult
$Res call({
 String status, String? voidReason, String? voidReasonCode
});




}
/// @nodoc
class _$TicketTransitionRequestDtoCopyWithImpl<$Res>
    implements $TicketTransitionRequestDtoCopyWith<$Res> {
  _$TicketTransitionRequestDtoCopyWithImpl(this._self, this._then);

  final TicketTransitionRequestDto _self;
  final $Res Function(TicketTransitionRequestDto) _then;

/// Create a copy of TicketTransitionRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? voidReason = freezed,Object? voidReasonCode = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,voidReasonCode: freezed == voidReasonCode ? _self.voidReasonCode : voidReasonCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TicketTransitionRequestDto].
extension TicketTransitionRequestDtoPatterns on TicketTransitionRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketTransitionRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketTransitionRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketTransitionRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _TicketTransitionRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketTransitionRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _TicketTransitionRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String? voidReason,  String? voidReasonCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TicketTransitionRequestDto() when $default != null:
return $default(_that.status,_that.voidReason,_that.voidReasonCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String? voidReason,  String? voidReasonCode)  $default,) {final _that = this;
switch (_that) {
case _TicketTransitionRequestDto():
return $default(_that.status,_that.voidReason,_that.voidReasonCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String? voidReason,  String? voidReasonCode)?  $default,) {final _that = this;
switch (_that) {
case _TicketTransitionRequestDto() when $default != null:
return $default(_that.status,_that.voidReason,_that.voidReasonCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketTransitionRequestDto implements TicketTransitionRequestDto {
  const _TicketTransitionRequestDto({required this.status, this.voidReason, this.voidReasonCode});
  factory _TicketTransitionRequestDto.fromJson(Map<String, dynamic> json) => _$TicketTransitionRequestDtoFromJson(json);

@override final  String status;
@override final  String? voidReason;
@override final  String? voidReasonCode;

/// Create a copy of TicketTransitionRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketTransitionRequestDtoCopyWith<_TicketTransitionRequestDto> get copyWith => __$TicketTransitionRequestDtoCopyWithImpl<_TicketTransitionRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketTransitionRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketTransitionRequestDto&&(identical(other.status, status) || other.status == status)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason)&&(identical(other.voidReasonCode, voidReasonCode) || other.voidReasonCode == voidReasonCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,voidReason,voidReasonCode);

@override
String toString() {
  return 'TicketTransitionRequestDto(status: $status, voidReason: $voidReason, voidReasonCode: $voidReasonCode)';
}


}

/// @nodoc
abstract mixin class _$TicketTransitionRequestDtoCopyWith<$Res> implements $TicketTransitionRequestDtoCopyWith<$Res> {
  factory _$TicketTransitionRequestDtoCopyWith(_TicketTransitionRequestDto value, $Res Function(_TicketTransitionRequestDto) _then) = __$TicketTransitionRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String status, String? voidReason, String? voidReasonCode
});




}
/// @nodoc
class __$TicketTransitionRequestDtoCopyWithImpl<$Res>
    implements _$TicketTransitionRequestDtoCopyWith<$Res> {
  __$TicketTransitionRequestDtoCopyWithImpl(this._self, this._then);

  final _TicketTransitionRequestDto _self;
  final $Res Function(_TicketTransitionRequestDto) _then;

/// Create a copy of TicketTransitionRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? voidReason = freezed,Object? voidReasonCode = freezed,}) {
  return _then(_TicketTransitionRequestDto(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,voidReasonCode: freezed == voidReasonCode ? _self.voidReasonCode : voidReasonCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
