// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Ticket {

 String get id;/// The [[Visit]] this line belongs to — used to resolve a table-less
/// (takeaway) line's label via the visit. See ADR-0024 / ADR-0026.
 String? get visitId; String? get memberId;/// The table this line was fired from (empty for takeaway). The live-ticket
/// cache keys groups by [[visitId]], so map-flattening consumers read the
/// table id here rather than from the (now visit-keyed) map key. ADR-0034.
 String get tableId; String get itemId; String get name; String get variantName; CourseId get course; int get qty; List<TicketModifier> get modifiers; String? get note; int get price; TicketStatus get status; String get sentAt; DateTime get sentAtTime;/// When the kitchen started owning this line — stamped on the `held → sent`
/// fire, null on a normal send. The prep clock runs from
/// `firedAtTime ?? sentAtTime`, so a held course is not born overdue.
/// See [kitchenClockStart]. ADR-0043.
 DateTime? get firedAtTime;/// First entry into `ready` — the pass clock starts here (ADR-0013).
 DateTime? get readyAtTime;/// Most recent entry into `served`.
 DateTime? get servedAtTime; String? get voidReason; String? get voidReasonCode; String? get voidApprovedBy; String? get createdBy; String? get voidedBy;
/// Create a copy of Ticket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketCopyWith<Ticket> get copyWith => _$TicketCopyWithImpl<Ticket>(this as Ticket, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ticket&&(identical(other.id, id) || other.id == id)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.variantName, variantName) || other.variantName == variantName)&&(identical(other.course, course) || other.course == course)&&(identical(other.qty, qty) || other.qty == qty)&&const DeepCollectionEquality().equals(other.modifiers, modifiers)&&(identical(other.note, note) || other.note == note)&&(identical(other.price, price) || other.price == price)&&(identical(other.status, status) || other.status == status)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.sentAtTime, sentAtTime) || other.sentAtTime == sentAtTime)&&(identical(other.firedAtTime, firedAtTime) || other.firedAtTime == firedAtTime)&&(identical(other.readyAtTime, readyAtTime) || other.readyAtTime == readyAtTime)&&(identical(other.servedAtTime, servedAtTime) || other.servedAtTime == servedAtTime)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason)&&(identical(other.voidReasonCode, voidReasonCode) || other.voidReasonCode == voidReasonCode)&&(identical(other.voidApprovedBy, voidApprovedBy) || other.voidApprovedBy == voidApprovedBy)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.voidedBy, voidedBy) || other.voidedBy == voidedBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,visitId,memberId,tableId,itemId,name,variantName,course,qty,const DeepCollectionEquality().hash(modifiers),note,price,status,sentAt,sentAtTime,firedAtTime,readyAtTime,servedAtTime,voidReason,voidReasonCode,voidApprovedBy,createdBy,voidedBy]);

@override
String toString() {
  return 'Ticket(id: $id, visitId: $visitId, memberId: $memberId, tableId: $tableId, itemId: $itemId, name: $name, variantName: $variantName, course: $course, qty: $qty, modifiers: $modifiers, note: $note, price: $price, status: $status, sentAt: $sentAt, sentAtTime: $sentAtTime, firedAtTime: $firedAtTime, readyAtTime: $readyAtTime, servedAtTime: $servedAtTime, voidReason: $voidReason, voidReasonCode: $voidReasonCode, voidApprovedBy: $voidApprovedBy, createdBy: $createdBy, voidedBy: $voidedBy)';
}


}

/// @nodoc
abstract mixin class $TicketCopyWith<$Res>  {
  factory $TicketCopyWith(Ticket value, $Res Function(Ticket) _then) = _$TicketCopyWithImpl;
@useResult
$Res call({
 String id, String? visitId, String? memberId, String tableId, String itemId, String name, String variantName, CourseId course, int qty, List<TicketModifier> modifiers, String? note, int price, TicketStatus status, String sentAt, DateTime sentAtTime, DateTime? firedAtTime, DateTime? readyAtTime, DateTime? servedAtTime, String? voidReason, String? voidReasonCode, String? voidApprovedBy, String? createdBy, String? voidedBy
});




}
/// @nodoc
class _$TicketCopyWithImpl<$Res>
    implements $TicketCopyWith<$Res> {
  _$TicketCopyWithImpl(this._self, this._then);

  final Ticket _self;
  final $Res Function(Ticket) _then;

/// Create a copy of Ticket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? visitId = freezed,Object? memberId = freezed,Object? tableId = null,Object? itemId = null,Object? name = null,Object? variantName = null,Object? course = null,Object? qty = null,Object? modifiers = null,Object? note = freezed,Object? price = null,Object? status = null,Object? sentAt = null,Object? sentAtTime = null,Object? firedAtTime = freezed,Object? readyAtTime = freezed,Object? servedAtTime = freezed,Object? voidReason = freezed,Object? voidReasonCode = freezed,Object? voidApprovedBy = freezed,Object? createdBy = freezed,Object? voidedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitId: freezed == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,tableId: null == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variantName: null == variantName ? _self.variantName : variantName // ignore: cast_nullable_to_non_nullable
as String,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as CourseId,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,modifiers: null == modifiers ? _self.modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as List<TicketModifier>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TicketStatus,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as String,sentAtTime: null == sentAtTime ? _self.sentAtTime : sentAtTime // ignore: cast_nullable_to_non_nullable
as DateTime,firedAtTime: freezed == firedAtTime ? _self.firedAtTime : firedAtTime // ignore: cast_nullable_to_non_nullable
as DateTime?,readyAtTime: freezed == readyAtTime ? _self.readyAtTime : readyAtTime // ignore: cast_nullable_to_non_nullable
as DateTime?,servedAtTime: freezed == servedAtTime ? _self.servedAtTime : servedAtTime // ignore: cast_nullable_to_non_nullable
as DateTime?,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,voidReasonCode: freezed == voidReasonCode ? _self.voidReasonCode : voidReasonCode // ignore: cast_nullable_to_non_nullable
as String?,voidApprovedBy: freezed == voidApprovedBy ? _self.voidApprovedBy : voidApprovedBy // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,voidedBy: freezed == voidedBy ? _self.voidedBy : voidedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Ticket].
extension TicketPatterns on Ticket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ticket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ticket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ticket value)  $default,){
final _that = this;
switch (_that) {
case _Ticket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ticket value)?  $default,){
final _that = this;
switch (_that) {
case _Ticket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? visitId,  String? memberId,  String tableId,  String itemId,  String name,  String variantName,  CourseId course,  int qty,  List<TicketModifier> modifiers,  String? note,  int price,  TicketStatus status,  String sentAt,  DateTime sentAtTime,  DateTime? firedAtTime,  DateTime? readyAtTime,  DateTime? servedAtTime,  String? voidReason,  String? voidReasonCode,  String? voidApprovedBy,  String? createdBy,  String? voidedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ticket() when $default != null:
return $default(_that.id,_that.visitId,_that.memberId,_that.tableId,_that.itemId,_that.name,_that.variantName,_that.course,_that.qty,_that.modifiers,_that.note,_that.price,_that.status,_that.sentAt,_that.sentAtTime,_that.firedAtTime,_that.readyAtTime,_that.servedAtTime,_that.voidReason,_that.voidReasonCode,_that.voidApprovedBy,_that.createdBy,_that.voidedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? visitId,  String? memberId,  String tableId,  String itemId,  String name,  String variantName,  CourseId course,  int qty,  List<TicketModifier> modifiers,  String? note,  int price,  TicketStatus status,  String sentAt,  DateTime sentAtTime,  DateTime? firedAtTime,  DateTime? readyAtTime,  DateTime? servedAtTime,  String? voidReason,  String? voidReasonCode,  String? voidApprovedBy,  String? createdBy,  String? voidedBy)  $default,) {final _that = this;
switch (_that) {
case _Ticket():
return $default(_that.id,_that.visitId,_that.memberId,_that.tableId,_that.itemId,_that.name,_that.variantName,_that.course,_that.qty,_that.modifiers,_that.note,_that.price,_that.status,_that.sentAt,_that.sentAtTime,_that.firedAtTime,_that.readyAtTime,_that.servedAtTime,_that.voidReason,_that.voidReasonCode,_that.voidApprovedBy,_that.createdBy,_that.voidedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? visitId,  String? memberId,  String tableId,  String itemId,  String name,  String variantName,  CourseId course,  int qty,  List<TicketModifier> modifiers,  String? note,  int price,  TicketStatus status,  String sentAt,  DateTime sentAtTime,  DateTime? firedAtTime,  DateTime? readyAtTime,  DateTime? servedAtTime,  String? voidReason,  String? voidReasonCode,  String? voidApprovedBy,  String? createdBy,  String? voidedBy)?  $default,) {final _that = this;
switch (_that) {
case _Ticket() when $default != null:
return $default(_that.id,_that.visitId,_that.memberId,_that.tableId,_that.itemId,_that.name,_that.variantName,_that.course,_that.qty,_that.modifiers,_that.note,_that.price,_that.status,_that.sentAt,_that.sentAtTime,_that.firedAtTime,_that.readyAtTime,_that.servedAtTime,_that.voidReason,_that.voidReasonCode,_that.voidApprovedBy,_that.createdBy,_that.voidedBy);case _:
  return null;

}
}

}

/// @nodoc


class _Ticket extends Ticket {
  const _Ticket({required this.id, this.visitId, this.memberId, this.tableId = '', required this.itemId, required this.name, this.variantName = '', required this.course, this.qty = 1, final  List<TicketModifier> modifiers = const <TicketModifier>[], this.note, required this.price, required this.status, required this.sentAt, required this.sentAtTime, this.firedAtTime, this.readyAtTime, this.servedAtTime, this.voidReason, this.voidReasonCode, this.voidApprovedBy, this.createdBy, this.voidedBy}): _modifiers = modifiers,super._();
  

@override final  String id;
/// The [[Visit]] this line belongs to — used to resolve a table-less
/// (takeaway) line's label via the visit. See ADR-0024 / ADR-0026.
@override final  String? visitId;
@override final  String? memberId;
/// The table this line was fired from (empty for takeaway). The live-ticket
/// cache keys groups by [[visitId]], so map-flattening consumers read the
/// table id here rather than from the (now visit-keyed) map key. ADR-0034.
@override@JsonKey() final  String tableId;
@override final  String itemId;
@override final  String name;
@override@JsonKey() final  String variantName;
@override final  CourseId course;
@override@JsonKey() final  int qty;
 final  List<TicketModifier> _modifiers;
@override@JsonKey() List<TicketModifier> get modifiers {
  if (_modifiers is EqualUnmodifiableListView) return _modifiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modifiers);
}

@override final  String? note;
@override final  int price;
@override final  TicketStatus status;
@override final  String sentAt;
@override final  DateTime sentAtTime;
/// When the kitchen started owning this line — stamped on the `held → sent`
/// fire, null on a normal send. The prep clock runs from
/// `firedAtTime ?? sentAtTime`, so a held course is not born overdue.
/// See [kitchenClockStart]. ADR-0043.
@override final  DateTime? firedAtTime;
/// First entry into `ready` — the pass clock starts here (ADR-0013).
@override final  DateTime? readyAtTime;
/// Most recent entry into `served`.
@override final  DateTime? servedAtTime;
@override final  String? voidReason;
@override final  String? voidReasonCode;
@override final  String? voidApprovedBy;
@override final  String? createdBy;
@override final  String? voidedBy;

/// Create a copy of Ticket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketCopyWith<_Ticket> get copyWith => __$TicketCopyWithImpl<_Ticket>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ticket&&(identical(other.id, id) || other.id == id)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.variantName, variantName) || other.variantName == variantName)&&(identical(other.course, course) || other.course == course)&&(identical(other.qty, qty) || other.qty == qty)&&const DeepCollectionEquality().equals(other._modifiers, _modifiers)&&(identical(other.note, note) || other.note == note)&&(identical(other.price, price) || other.price == price)&&(identical(other.status, status) || other.status == status)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.sentAtTime, sentAtTime) || other.sentAtTime == sentAtTime)&&(identical(other.firedAtTime, firedAtTime) || other.firedAtTime == firedAtTime)&&(identical(other.readyAtTime, readyAtTime) || other.readyAtTime == readyAtTime)&&(identical(other.servedAtTime, servedAtTime) || other.servedAtTime == servedAtTime)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason)&&(identical(other.voidReasonCode, voidReasonCode) || other.voidReasonCode == voidReasonCode)&&(identical(other.voidApprovedBy, voidApprovedBy) || other.voidApprovedBy == voidApprovedBy)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.voidedBy, voidedBy) || other.voidedBy == voidedBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,visitId,memberId,tableId,itemId,name,variantName,course,qty,const DeepCollectionEquality().hash(_modifiers),note,price,status,sentAt,sentAtTime,firedAtTime,readyAtTime,servedAtTime,voidReason,voidReasonCode,voidApprovedBy,createdBy,voidedBy]);

@override
String toString() {
  return 'Ticket(id: $id, visitId: $visitId, memberId: $memberId, tableId: $tableId, itemId: $itemId, name: $name, variantName: $variantName, course: $course, qty: $qty, modifiers: $modifiers, note: $note, price: $price, status: $status, sentAt: $sentAt, sentAtTime: $sentAtTime, firedAtTime: $firedAtTime, readyAtTime: $readyAtTime, servedAtTime: $servedAtTime, voidReason: $voidReason, voidReasonCode: $voidReasonCode, voidApprovedBy: $voidApprovedBy, createdBy: $createdBy, voidedBy: $voidedBy)';
}


}

/// @nodoc
abstract mixin class _$TicketCopyWith<$Res> implements $TicketCopyWith<$Res> {
  factory _$TicketCopyWith(_Ticket value, $Res Function(_Ticket) _then) = __$TicketCopyWithImpl;
@override @useResult
$Res call({
 String id, String? visitId, String? memberId, String tableId, String itemId, String name, String variantName, CourseId course, int qty, List<TicketModifier> modifiers, String? note, int price, TicketStatus status, String sentAt, DateTime sentAtTime, DateTime? firedAtTime, DateTime? readyAtTime, DateTime? servedAtTime, String? voidReason, String? voidReasonCode, String? voidApprovedBy, String? createdBy, String? voidedBy
});




}
/// @nodoc
class __$TicketCopyWithImpl<$Res>
    implements _$TicketCopyWith<$Res> {
  __$TicketCopyWithImpl(this._self, this._then);

  final _Ticket _self;
  final $Res Function(_Ticket) _then;

/// Create a copy of Ticket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? visitId = freezed,Object? memberId = freezed,Object? tableId = null,Object? itemId = null,Object? name = null,Object? variantName = null,Object? course = null,Object? qty = null,Object? modifiers = null,Object? note = freezed,Object? price = null,Object? status = null,Object? sentAt = null,Object? sentAtTime = null,Object? firedAtTime = freezed,Object? readyAtTime = freezed,Object? servedAtTime = freezed,Object? voidReason = freezed,Object? voidReasonCode = freezed,Object? voidApprovedBy = freezed,Object? createdBy = freezed,Object? voidedBy = freezed,}) {
  return _then(_Ticket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitId: freezed == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,tableId: null == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variantName: null == variantName ? _self.variantName : variantName // ignore: cast_nullable_to_non_nullable
as String,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as CourseId,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,modifiers: null == modifiers ? _self._modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as List<TicketModifier>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TicketStatus,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as String,sentAtTime: null == sentAtTime ? _self.sentAtTime : sentAtTime // ignore: cast_nullable_to_non_nullable
as DateTime,firedAtTime: freezed == firedAtTime ? _self.firedAtTime : firedAtTime // ignore: cast_nullable_to_non_nullable
as DateTime?,readyAtTime: freezed == readyAtTime ? _self.readyAtTime : readyAtTime // ignore: cast_nullable_to_non_nullable
as DateTime?,servedAtTime: freezed == servedAtTime ? _self.servedAtTime : servedAtTime // ignore: cast_nullable_to_non_nullable
as DateTime?,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,voidReasonCode: freezed == voidReasonCode ? _self.voidReasonCode : voidReasonCode // ignore: cast_nullable_to_non_nullable
as String?,voidApprovedBy: freezed == voidApprovedBy ? _self.voidApprovedBy : voidApprovedBy // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,voidedBy: freezed == voidedBy ? _self.voidedBy : voidedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
