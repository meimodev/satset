// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'self_order_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuestLineModDto {

 String get label;
/// Create a copy of GuestLineModDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuestLineModDtoCopyWith<GuestLineModDto> get copyWith => _$GuestLineModDtoCopyWithImpl<GuestLineModDto>(this as GuestLineModDto, _$identity);

  /// Serializes this GuestLineModDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuestLineModDto&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label);

@override
String toString() {
  return 'GuestLineModDto(label: $label)';
}


}

/// @nodoc
abstract mixin class $GuestLineModDtoCopyWith<$Res>  {
  factory $GuestLineModDtoCopyWith(GuestLineModDto value, $Res Function(GuestLineModDto) _then) = _$GuestLineModDtoCopyWithImpl;
@useResult
$Res call({
 String label
});




}
/// @nodoc
class _$GuestLineModDtoCopyWithImpl<$Res>
    implements $GuestLineModDtoCopyWith<$Res> {
  _$GuestLineModDtoCopyWithImpl(this._self, this._then);

  final GuestLineModDto _self;
  final $Res Function(GuestLineModDto) _then;

/// Create a copy of GuestLineModDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GuestLineModDto].
extension GuestLineModDtoPatterns on GuestLineModDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuestLineModDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuestLineModDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuestLineModDto value)  $default,){
final _that = this;
switch (_that) {
case _GuestLineModDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuestLineModDto value)?  $default,){
final _that = this;
switch (_that) {
case _GuestLineModDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuestLineModDto() when $default != null:
return $default(_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label)  $default,) {final _that = this;
switch (_that) {
case _GuestLineModDto():
return $default(_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label)?  $default,) {final _that = this;
switch (_that) {
case _GuestLineModDto() when $default != null:
return $default(_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuestLineModDto implements GuestLineModDto {
  const _GuestLineModDto({this.label = ''});
  factory _GuestLineModDto.fromJson(Map<String, dynamic> json) => _$GuestLineModDtoFromJson(json);

@override@JsonKey() final  String label;

/// Create a copy of GuestLineModDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuestLineModDtoCopyWith<_GuestLineModDto> get copyWith => __$GuestLineModDtoCopyWithImpl<_GuestLineModDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuestLineModDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuestLineModDto&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label);

@override
String toString() {
  return 'GuestLineModDto(label: $label)';
}


}

/// @nodoc
abstract mixin class _$GuestLineModDtoCopyWith<$Res> implements $GuestLineModDtoCopyWith<$Res> {
  factory _$GuestLineModDtoCopyWith(_GuestLineModDto value, $Res Function(_GuestLineModDto) _then) = __$GuestLineModDtoCopyWithImpl;
@override @useResult
$Res call({
 String label
});




}
/// @nodoc
class __$GuestLineModDtoCopyWithImpl<$Res>
    implements _$GuestLineModDtoCopyWith<$Res> {
  __$GuestLineModDtoCopyWithImpl(this._self, this._then);

  final _GuestLineModDto _self;
  final $Res Function(_GuestLineModDto) _then;

/// Create a copy of GuestLineModDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,}) {
  return _then(_GuestLineModDto(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GuestOrderLineDto {

 String get id; String get itemId; String get name; String get variantName; int get qty; String? get note; int get unitPrice; List<GuestLineModDto> get modifiers;
/// Create a copy of GuestOrderLineDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuestOrderLineDtoCopyWith<GuestOrderLineDto> get copyWith => _$GuestOrderLineDtoCopyWithImpl<GuestOrderLineDto>(this as GuestOrderLineDto, _$identity);

  /// Serializes this GuestOrderLineDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuestOrderLineDto&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.variantName, variantName) || other.variantName == variantName)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.note, note) || other.note == note)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&const DeepCollectionEquality().equals(other.modifiers, modifiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,itemId,name,variantName,qty,note,unitPrice,const DeepCollectionEquality().hash(modifiers));

@override
String toString() {
  return 'GuestOrderLineDto(id: $id, itemId: $itemId, name: $name, variantName: $variantName, qty: $qty, note: $note, unitPrice: $unitPrice, modifiers: $modifiers)';
}


}

/// @nodoc
abstract mixin class $GuestOrderLineDtoCopyWith<$Res>  {
  factory $GuestOrderLineDtoCopyWith(GuestOrderLineDto value, $Res Function(GuestOrderLineDto) _then) = _$GuestOrderLineDtoCopyWithImpl;
@useResult
$Res call({
 String id, String itemId, String name, String variantName, int qty, String? note, int unitPrice, List<GuestLineModDto> modifiers
});




}
/// @nodoc
class _$GuestOrderLineDtoCopyWithImpl<$Res>
    implements $GuestOrderLineDtoCopyWith<$Res> {
  _$GuestOrderLineDtoCopyWithImpl(this._self, this._then);

  final GuestOrderLineDto _self;
  final $Res Function(GuestOrderLineDto) _then;

/// Create a copy of GuestOrderLineDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? itemId = null,Object? name = null,Object? variantName = null,Object? qty = null,Object? note = freezed,Object? unitPrice = null,Object? modifiers = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variantName: null == variantName ? _self.variantName : variantName // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as int,modifiers: null == modifiers ? _self.modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as List<GuestLineModDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [GuestOrderLineDto].
extension GuestOrderLineDtoPatterns on GuestOrderLineDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuestOrderLineDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuestOrderLineDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuestOrderLineDto value)  $default,){
final _that = this;
switch (_that) {
case _GuestOrderLineDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuestOrderLineDto value)?  $default,){
final _that = this;
switch (_that) {
case _GuestOrderLineDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String itemId,  String name,  String variantName,  int qty,  String? note,  int unitPrice,  List<GuestLineModDto> modifiers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuestOrderLineDto() when $default != null:
return $default(_that.id,_that.itemId,_that.name,_that.variantName,_that.qty,_that.note,_that.unitPrice,_that.modifiers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String itemId,  String name,  String variantName,  int qty,  String? note,  int unitPrice,  List<GuestLineModDto> modifiers)  $default,) {final _that = this;
switch (_that) {
case _GuestOrderLineDto():
return $default(_that.id,_that.itemId,_that.name,_that.variantName,_that.qty,_that.note,_that.unitPrice,_that.modifiers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String itemId,  String name,  String variantName,  int qty,  String? note,  int unitPrice,  List<GuestLineModDto> modifiers)?  $default,) {final _that = this;
switch (_that) {
case _GuestOrderLineDto() when $default != null:
return $default(_that.id,_that.itemId,_that.name,_that.variantName,_that.qty,_that.note,_that.unitPrice,_that.modifiers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuestOrderLineDto implements GuestOrderLineDto {
  const _GuestOrderLineDto({required this.id, required this.itemId, required this.name, this.variantName = '', this.qty = 1, this.note, this.unitPrice = 0, final  List<GuestLineModDto> modifiers = const []}): _modifiers = modifiers;
  factory _GuestOrderLineDto.fromJson(Map<String, dynamic> json) => _$GuestOrderLineDtoFromJson(json);

@override final  String id;
@override final  String itemId;
@override final  String name;
@override@JsonKey() final  String variantName;
@override@JsonKey() final  int qty;
@override final  String? note;
@override@JsonKey() final  int unitPrice;
 final  List<GuestLineModDto> _modifiers;
@override@JsonKey() List<GuestLineModDto> get modifiers {
  if (_modifiers is EqualUnmodifiableListView) return _modifiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modifiers);
}


/// Create a copy of GuestOrderLineDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuestOrderLineDtoCopyWith<_GuestOrderLineDto> get copyWith => __$GuestOrderLineDtoCopyWithImpl<_GuestOrderLineDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuestOrderLineDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuestOrderLineDto&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.variantName, variantName) || other.variantName == variantName)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.note, note) || other.note == note)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&const DeepCollectionEquality().equals(other._modifiers, _modifiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,itemId,name,variantName,qty,note,unitPrice,const DeepCollectionEquality().hash(_modifiers));

@override
String toString() {
  return 'GuestOrderLineDto(id: $id, itemId: $itemId, name: $name, variantName: $variantName, qty: $qty, note: $note, unitPrice: $unitPrice, modifiers: $modifiers)';
}


}

/// @nodoc
abstract mixin class _$GuestOrderLineDtoCopyWith<$Res> implements $GuestOrderLineDtoCopyWith<$Res> {
  factory _$GuestOrderLineDtoCopyWith(_GuestOrderLineDto value, $Res Function(_GuestOrderLineDto) _then) = __$GuestOrderLineDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String itemId, String name, String variantName, int qty, String? note, int unitPrice, List<GuestLineModDto> modifiers
});




}
/// @nodoc
class __$GuestOrderLineDtoCopyWithImpl<$Res>
    implements _$GuestOrderLineDtoCopyWith<$Res> {
  __$GuestOrderLineDtoCopyWithImpl(this._self, this._then);

  final _GuestOrderLineDto _self;
  final $Res Function(_GuestOrderLineDto) _then;

/// Create a copy of GuestOrderLineDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? itemId = null,Object? name = null,Object? variantName = null,Object? qty = null,Object? note = freezed,Object? unitPrice = null,Object? modifiers = null,}) {
  return _then(_GuestOrderLineDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variantName: null == variantName ? _self.variantName : variantName // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as int,modifiers: null == modifiers ? _self._modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as List<GuestLineModDto>,
  ));
}


}


/// @nodoc
mixin _$GuestOrderDto {

 String get id; String get tableId; String? get tableLabel;/// A counter order (ADR-0109): no table, its own [[Bawa pulang]] bill once
/// accepted. The queue card spells it, because a blank table label is not
/// a word.
 bool get counter; String get status; DateTime get submittedAt; DateTime? get decidedAt; String? get rejectReasonCode;/// Who accepted or rejected it. Staff-only — the guest page is told what
/// happened, never by whom.
 String? get decidedBy; int get subtotal; List<GuestOrderLineDto> get lines;
/// Create a copy of GuestOrderDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuestOrderDtoCopyWith<GuestOrderDto> get copyWith => _$GuestOrderDtoCopyWithImpl<GuestOrderDto>(this as GuestOrderDto, _$identity);

  /// Serializes this GuestOrderDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuestOrderDto&&(identical(other.id, id) || other.id == id)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.tableLabel, tableLabel) || other.tableLabel == tableLabel)&&(identical(other.counter, counter) || other.counter == counter)&&(identical(other.status, status) || other.status == status)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.rejectReasonCode, rejectReasonCode) || other.rejectReasonCode == rejectReasonCode)&&(identical(other.decidedBy, decidedBy) || other.decidedBy == decidedBy)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&const DeepCollectionEquality().equals(other.lines, lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tableId,tableLabel,counter,status,submittedAt,decidedAt,rejectReasonCode,decidedBy,subtotal,const DeepCollectionEquality().hash(lines));

@override
String toString() {
  return 'GuestOrderDto(id: $id, tableId: $tableId, tableLabel: $tableLabel, counter: $counter, status: $status, submittedAt: $submittedAt, decidedAt: $decidedAt, rejectReasonCode: $rejectReasonCode, decidedBy: $decidedBy, subtotal: $subtotal, lines: $lines)';
}


}

/// @nodoc
abstract mixin class $GuestOrderDtoCopyWith<$Res>  {
  factory $GuestOrderDtoCopyWith(GuestOrderDto value, $Res Function(GuestOrderDto) _then) = _$GuestOrderDtoCopyWithImpl;
@useResult
$Res call({
 String id, String tableId, String? tableLabel, bool counter, String status, DateTime submittedAt, DateTime? decidedAt, String? rejectReasonCode, String? decidedBy, int subtotal, List<GuestOrderLineDto> lines
});




}
/// @nodoc
class _$GuestOrderDtoCopyWithImpl<$Res>
    implements $GuestOrderDtoCopyWith<$Res> {
  _$GuestOrderDtoCopyWithImpl(this._self, this._then);

  final GuestOrderDto _self;
  final $Res Function(GuestOrderDto) _then;

/// Create a copy of GuestOrderDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tableId = null,Object? tableLabel = freezed,Object? counter = null,Object? status = null,Object? submittedAt = null,Object? decidedAt = freezed,Object? rejectReasonCode = freezed,Object? decidedBy = freezed,Object? subtotal = null,Object? lines = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tableId: null == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String,tableLabel: freezed == tableLabel ? _self.tableLabel : tableLabel // ignore: cast_nullable_to_non_nullable
as String?,counter: null == counter ? _self.counter : counter // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectReasonCode: freezed == rejectReasonCode ? _self.rejectReasonCode : rejectReasonCode // ignore: cast_nullable_to_non_nullable
as String?,decidedBy: freezed == decidedBy ? _self.decidedBy : decidedBy // ignore: cast_nullable_to_non_nullable
as String?,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as int,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<GuestOrderLineDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [GuestOrderDto].
extension GuestOrderDtoPatterns on GuestOrderDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuestOrderDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuestOrderDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuestOrderDto value)  $default,){
final _that = this;
switch (_that) {
case _GuestOrderDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuestOrderDto value)?  $default,){
final _that = this;
switch (_that) {
case _GuestOrderDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tableId,  String? tableLabel,  bool counter,  String status,  DateTime submittedAt,  DateTime? decidedAt,  String? rejectReasonCode,  String? decidedBy,  int subtotal,  List<GuestOrderLineDto> lines)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuestOrderDto() when $default != null:
return $default(_that.id,_that.tableId,_that.tableLabel,_that.counter,_that.status,_that.submittedAt,_that.decidedAt,_that.rejectReasonCode,_that.decidedBy,_that.subtotal,_that.lines);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tableId,  String? tableLabel,  bool counter,  String status,  DateTime submittedAt,  DateTime? decidedAt,  String? rejectReasonCode,  String? decidedBy,  int subtotal,  List<GuestOrderLineDto> lines)  $default,) {final _that = this;
switch (_that) {
case _GuestOrderDto():
return $default(_that.id,_that.tableId,_that.tableLabel,_that.counter,_that.status,_that.submittedAt,_that.decidedAt,_that.rejectReasonCode,_that.decidedBy,_that.subtotal,_that.lines);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tableId,  String? tableLabel,  bool counter,  String status,  DateTime submittedAt,  DateTime? decidedAt,  String? rejectReasonCode,  String? decidedBy,  int subtotal,  List<GuestOrderLineDto> lines)?  $default,) {final _that = this;
switch (_that) {
case _GuestOrderDto() when $default != null:
return $default(_that.id,_that.tableId,_that.tableLabel,_that.counter,_that.status,_that.submittedAt,_that.decidedAt,_that.rejectReasonCode,_that.decidedBy,_that.subtotal,_that.lines);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuestOrderDto implements GuestOrderDto {
  const _GuestOrderDto({required this.id, required this.tableId, this.tableLabel, this.counter = false, this.status = 'pending', required this.submittedAt, this.decidedAt, this.rejectReasonCode, this.decidedBy, this.subtotal = 0, final  List<GuestOrderLineDto> lines = const []}): _lines = lines;
  factory _GuestOrderDto.fromJson(Map<String, dynamic> json) => _$GuestOrderDtoFromJson(json);

@override final  String id;
@override final  String tableId;
@override final  String? tableLabel;
/// A counter order (ADR-0109): no table, its own [[Bawa pulang]] bill once
/// accepted. The queue card spells it, because a blank table label is not
/// a word.
@override@JsonKey() final  bool counter;
@override@JsonKey() final  String status;
@override final  DateTime submittedAt;
@override final  DateTime? decidedAt;
@override final  String? rejectReasonCode;
/// Who accepted or rejected it. Staff-only — the guest page is told what
/// happened, never by whom.
@override final  String? decidedBy;
@override@JsonKey() final  int subtotal;
 final  List<GuestOrderLineDto> _lines;
@override@JsonKey() List<GuestOrderLineDto> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}


/// Create a copy of GuestOrderDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuestOrderDtoCopyWith<_GuestOrderDto> get copyWith => __$GuestOrderDtoCopyWithImpl<_GuestOrderDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuestOrderDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuestOrderDto&&(identical(other.id, id) || other.id == id)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.tableLabel, tableLabel) || other.tableLabel == tableLabel)&&(identical(other.counter, counter) || other.counter == counter)&&(identical(other.status, status) || other.status == status)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.rejectReasonCode, rejectReasonCode) || other.rejectReasonCode == rejectReasonCode)&&(identical(other.decidedBy, decidedBy) || other.decidedBy == decidedBy)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&const DeepCollectionEquality().equals(other._lines, _lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tableId,tableLabel,counter,status,submittedAt,decidedAt,rejectReasonCode,decidedBy,subtotal,const DeepCollectionEquality().hash(_lines));

@override
String toString() {
  return 'GuestOrderDto(id: $id, tableId: $tableId, tableLabel: $tableLabel, counter: $counter, status: $status, submittedAt: $submittedAt, decidedAt: $decidedAt, rejectReasonCode: $rejectReasonCode, decidedBy: $decidedBy, subtotal: $subtotal, lines: $lines)';
}


}

/// @nodoc
abstract mixin class _$GuestOrderDtoCopyWith<$Res> implements $GuestOrderDtoCopyWith<$Res> {
  factory _$GuestOrderDtoCopyWith(_GuestOrderDto value, $Res Function(_GuestOrderDto) _then) = __$GuestOrderDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String tableId, String? tableLabel, bool counter, String status, DateTime submittedAt, DateTime? decidedAt, String? rejectReasonCode, String? decidedBy, int subtotal, List<GuestOrderLineDto> lines
});




}
/// @nodoc
class __$GuestOrderDtoCopyWithImpl<$Res>
    implements _$GuestOrderDtoCopyWith<$Res> {
  __$GuestOrderDtoCopyWithImpl(this._self, this._then);

  final _GuestOrderDto _self;
  final $Res Function(_GuestOrderDto) _then;

/// Create a copy of GuestOrderDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tableId = null,Object? tableLabel = freezed,Object? counter = null,Object? status = null,Object? submittedAt = null,Object? decidedAt = freezed,Object? rejectReasonCode = freezed,Object? decidedBy = freezed,Object? subtotal = null,Object? lines = null,}) {
  return _then(_GuestOrderDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tableId: null == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String,tableLabel: freezed == tableLabel ? _self.tableLabel : tableLabel // ignore: cast_nullable_to_non_nullable
as String?,counter: null == counter ? _self.counter : counter // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectReasonCode: freezed == rejectReasonCode ? _self.rejectReasonCode : rejectReasonCode // ignore: cast_nullable_to_non_nullable
as String?,decidedBy: freezed == decidedBy ? _self.decidedBy : decidedBy // ignore: cast_nullable_to_non_nullable
as String?,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as int,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<GuestOrderLineDto>,
  ));
}


}


/// @nodoc
mixin _$GuestTableDto {

 String get id; String? get label; String get zoneId; String get zoneName; int get seats; String get code; bool get enabled;
/// Create a copy of GuestTableDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuestTableDtoCopyWith<GuestTableDto> get copyWith => _$GuestTableDtoCopyWithImpl<GuestTableDto>(this as GuestTableDto, _$identity);

  /// Serializes this GuestTableDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuestTableDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.zoneName, zoneName) || other.zoneName == zoneName)&&(identical(other.seats, seats) || other.seats == seats)&&(identical(other.code, code) || other.code == code)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,zoneId,zoneName,seats,code,enabled);

@override
String toString() {
  return 'GuestTableDto(id: $id, label: $label, zoneId: $zoneId, zoneName: $zoneName, seats: $seats, code: $code, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $GuestTableDtoCopyWith<$Res>  {
  factory $GuestTableDtoCopyWith(GuestTableDto value, $Res Function(GuestTableDto) _then) = _$GuestTableDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? label, String zoneId, String zoneName, int seats, String code, bool enabled
});




}
/// @nodoc
class _$GuestTableDtoCopyWithImpl<$Res>
    implements $GuestTableDtoCopyWith<$Res> {
  _$GuestTableDtoCopyWithImpl(this._self, this._then);

  final GuestTableDto _self;
  final $Res Function(GuestTableDto) _then;

/// Create a copy of GuestTableDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = freezed,Object? zoneId = null,Object? zoneName = null,Object? seats = null,Object? code = null,Object? enabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,zoneId: null == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String,zoneName: null == zoneName ? _self.zoneName : zoneName // ignore: cast_nullable_to_non_nullable
as String,seats: null == seats ? _self.seats : seats // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GuestTableDto].
extension GuestTableDtoPatterns on GuestTableDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuestTableDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuestTableDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuestTableDto value)  $default,){
final _that = this;
switch (_that) {
case _GuestTableDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuestTableDto value)?  $default,){
final _that = this;
switch (_that) {
case _GuestTableDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? label,  String zoneId,  String zoneName,  int seats,  String code,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuestTableDto() when $default != null:
return $default(_that.id,_that.label,_that.zoneId,_that.zoneName,_that.seats,_that.code,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? label,  String zoneId,  String zoneName,  int seats,  String code,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _GuestTableDto():
return $default(_that.id,_that.label,_that.zoneId,_that.zoneName,_that.seats,_that.code,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? label,  String zoneId,  String zoneName,  int seats,  String code,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _GuestTableDto() when $default != null:
return $default(_that.id,_that.label,_that.zoneId,_that.zoneName,_that.seats,_that.code,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuestTableDto implements GuestTableDto {
  const _GuestTableDto({required this.id, this.label, this.zoneId = '', this.zoneName = '', this.seats = 0, this.code = '', this.enabled = true});
  factory _GuestTableDto.fromJson(Map<String, dynamic> json) => _$GuestTableDtoFromJson(json);

@override final  String id;
@override final  String? label;
@override@JsonKey() final  String zoneId;
@override@JsonKey() final  String zoneName;
@override@JsonKey() final  int seats;
@override@JsonKey() final  String code;
@override@JsonKey() final  bool enabled;

/// Create a copy of GuestTableDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuestTableDtoCopyWith<_GuestTableDto> get copyWith => __$GuestTableDtoCopyWithImpl<_GuestTableDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuestTableDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuestTableDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.zoneName, zoneName) || other.zoneName == zoneName)&&(identical(other.seats, seats) || other.seats == seats)&&(identical(other.code, code) || other.code == code)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,zoneId,zoneName,seats,code,enabled);

@override
String toString() {
  return 'GuestTableDto(id: $id, label: $label, zoneId: $zoneId, zoneName: $zoneName, seats: $seats, code: $code, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$GuestTableDtoCopyWith<$Res> implements $GuestTableDtoCopyWith<$Res> {
  factory _$GuestTableDtoCopyWith(_GuestTableDto value, $Res Function(_GuestTableDto) _then) = __$GuestTableDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? label, String zoneId, String zoneName, int seats, String code, bool enabled
});




}
/// @nodoc
class __$GuestTableDtoCopyWithImpl<$Res>
    implements _$GuestTableDtoCopyWith<$Res> {
  __$GuestTableDtoCopyWithImpl(this._self, this._then);

  final _GuestTableDto _self;
  final $Res Function(_GuestTableDto) _then;

/// Create a copy of GuestTableDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = freezed,Object? zoneId = null,Object? zoneName = null,Object? seats = null,Object? code = null,Object? enabled = null,}) {
  return _then(_GuestTableDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,zoneId: null == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String,zoneName: null == zoneName ? _self.zoneName : zoneName // ignore: cast_nullable_to_non_nullable
as String,seats: null == seats ? _self.seats : seats // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$GuestCategoryDto {

 String get id; String get name; int? get fromMin; int? get toMin;
/// Create a copy of GuestCategoryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuestCategoryDtoCopyWith<GuestCategoryDto> get copyWith => _$GuestCategoryDtoCopyWithImpl<GuestCategoryDto>(this as GuestCategoryDto, _$identity);

  /// Serializes this GuestCategoryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuestCategoryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fromMin, fromMin) || other.fromMin == fromMin)&&(identical(other.toMin, toMin) || other.toMin == toMin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,fromMin,toMin);

@override
String toString() {
  return 'GuestCategoryDto(id: $id, name: $name, fromMin: $fromMin, toMin: $toMin)';
}


}

/// @nodoc
abstract mixin class $GuestCategoryDtoCopyWith<$Res>  {
  factory $GuestCategoryDtoCopyWith(GuestCategoryDto value, $Res Function(GuestCategoryDto) _then) = _$GuestCategoryDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, int? fromMin, int? toMin
});




}
/// @nodoc
class _$GuestCategoryDtoCopyWithImpl<$Res>
    implements $GuestCategoryDtoCopyWith<$Res> {
  _$GuestCategoryDtoCopyWithImpl(this._self, this._then);

  final GuestCategoryDto _self;
  final $Res Function(GuestCategoryDto) _then;

/// Create a copy of GuestCategoryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? fromMin = freezed,Object? toMin = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fromMin: freezed == fromMin ? _self.fromMin : fromMin // ignore: cast_nullable_to_non_nullable
as int?,toMin: freezed == toMin ? _self.toMin : toMin // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [GuestCategoryDto].
extension GuestCategoryDtoPatterns on GuestCategoryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuestCategoryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuestCategoryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuestCategoryDto value)  $default,){
final _that = this;
switch (_that) {
case _GuestCategoryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuestCategoryDto value)?  $default,){
final _that = this;
switch (_that) {
case _GuestCategoryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int? fromMin,  int? toMin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuestCategoryDto() when $default != null:
return $default(_that.id,_that.name,_that.fromMin,_that.toMin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int? fromMin,  int? toMin)  $default,) {final _that = this;
switch (_that) {
case _GuestCategoryDto():
return $default(_that.id,_that.name,_that.fromMin,_that.toMin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int? fromMin,  int? toMin)?  $default,) {final _that = this;
switch (_that) {
case _GuestCategoryDto() when $default != null:
return $default(_that.id,_that.name,_that.fromMin,_that.toMin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuestCategoryDto implements GuestCategoryDto {
  const _GuestCategoryDto({required this.id, required this.name, this.fromMin, this.toMin});
  factory _GuestCategoryDto.fromJson(Map<String, dynamic> json) => _$GuestCategoryDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  int? fromMin;
@override final  int? toMin;

/// Create a copy of GuestCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuestCategoryDtoCopyWith<_GuestCategoryDto> get copyWith => __$GuestCategoryDtoCopyWithImpl<_GuestCategoryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuestCategoryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuestCategoryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fromMin, fromMin) || other.fromMin == fromMin)&&(identical(other.toMin, toMin) || other.toMin == toMin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,fromMin,toMin);

@override
String toString() {
  return 'GuestCategoryDto(id: $id, name: $name, fromMin: $fromMin, toMin: $toMin)';
}


}

/// @nodoc
abstract mixin class _$GuestCategoryDtoCopyWith<$Res> implements $GuestCategoryDtoCopyWith<$Res> {
  factory _$GuestCategoryDtoCopyWith(_GuestCategoryDto value, $Res Function(_GuestCategoryDto) _then) = __$GuestCategoryDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int? fromMin, int? toMin
});




}
/// @nodoc
class __$GuestCategoryDtoCopyWithImpl<$Res>
    implements _$GuestCategoryDtoCopyWith<$Res> {
  __$GuestCategoryDtoCopyWithImpl(this._self, this._then);

  final _GuestCategoryDto _self;
  final $Res Function(_GuestCategoryDto) _then;

/// Create a copy of GuestCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? fromMin = freezed,Object? toMin = freezed,}) {
  return _then(_GuestCategoryDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fromMin: freezed == fromMin ? _self.fromMin : fromMin // ignore: cast_nullable_to_non_nullable
as int?,toMin: freezed == toMin ? _self.toMin : toMin // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$GuestMenuItemDto {

 String get id; String get name; String get categoryId; String get description; int get basePrice; bool get featured; bool get visible; bool get soldOut; bool get alcohol;/// `auto` | `forceIn` | `forceOut`, already expired server-side — a force
/// that outlived its business day arrives as `auto`.
 String get stockOverride;
/// Create a copy of GuestMenuItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuestMenuItemDtoCopyWith<GuestMenuItemDto> get copyWith => _$GuestMenuItemDtoCopyWithImpl<GuestMenuItemDto>(this as GuestMenuItemDto, _$identity);

  /// Serializes this GuestMenuItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuestMenuItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.description, description) || other.description == description)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.featured, featured) || other.featured == featured)&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.soldOut, soldOut) || other.soldOut == soldOut)&&(identical(other.alcohol, alcohol) || other.alcohol == alcohol)&&(identical(other.stockOverride, stockOverride) || other.stockOverride == stockOverride));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,categoryId,description,basePrice,featured,visible,soldOut,alcohol,stockOverride);

@override
String toString() {
  return 'GuestMenuItemDto(id: $id, name: $name, categoryId: $categoryId, description: $description, basePrice: $basePrice, featured: $featured, visible: $visible, soldOut: $soldOut, alcohol: $alcohol, stockOverride: $stockOverride)';
}


}

/// @nodoc
abstract mixin class $GuestMenuItemDtoCopyWith<$Res>  {
  factory $GuestMenuItemDtoCopyWith(GuestMenuItemDto value, $Res Function(GuestMenuItemDto) _then) = _$GuestMenuItemDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String categoryId, String description, int basePrice, bool featured, bool visible, bool soldOut, bool alcohol, String stockOverride
});




}
/// @nodoc
class _$GuestMenuItemDtoCopyWithImpl<$Res>
    implements $GuestMenuItemDtoCopyWith<$Res> {
  _$GuestMenuItemDtoCopyWithImpl(this._self, this._then);

  final GuestMenuItemDto _self;
  final $Res Function(GuestMenuItemDto) _then;

/// Create a copy of GuestMenuItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? categoryId = null,Object? description = null,Object? basePrice = null,Object? featured = null,Object? visible = null,Object? soldOut = null,Object? alcohol = null,Object? stockOverride = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as int,featured: null == featured ? _self.featured : featured // ignore: cast_nullable_to_non_nullable
as bool,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,soldOut: null == soldOut ? _self.soldOut : soldOut // ignore: cast_nullable_to_non_nullable
as bool,alcohol: null == alcohol ? _self.alcohol : alcohol // ignore: cast_nullable_to_non_nullable
as bool,stockOverride: null == stockOverride ? _self.stockOverride : stockOverride // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GuestMenuItemDto].
extension GuestMenuItemDtoPatterns on GuestMenuItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuestMenuItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuestMenuItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuestMenuItemDto value)  $default,){
final _that = this;
switch (_that) {
case _GuestMenuItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuestMenuItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _GuestMenuItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String categoryId,  String description,  int basePrice,  bool featured,  bool visible,  bool soldOut,  bool alcohol,  String stockOverride)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuestMenuItemDto() when $default != null:
return $default(_that.id,_that.name,_that.categoryId,_that.description,_that.basePrice,_that.featured,_that.visible,_that.soldOut,_that.alcohol,_that.stockOverride);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String categoryId,  String description,  int basePrice,  bool featured,  bool visible,  bool soldOut,  bool alcohol,  String stockOverride)  $default,) {final _that = this;
switch (_that) {
case _GuestMenuItemDto():
return $default(_that.id,_that.name,_that.categoryId,_that.description,_that.basePrice,_that.featured,_that.visible,_that.soldOut,_that.alcohol,_that.stockOverride);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String categoryId,  String description,  int basePrice,  bool featured,  bool visible,  bool soldOut,  bool alcohol,  String stockOverride)?  $default,) {final _that = this;
switch (_that) {
case _GuestMenuItemDto() when $default != null:
return $default(_that.id,_that.name,_that.categoryId,_that.description,_that.basePrice,_that.featured,_that.visible,_that.soldOut,_that.alcohol,_that.stockOverride);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuestMenuItemDto implements GuestMenuItemDto {
  const _GuestMenuItemDto({required this.id, required this.name, this.categoryId = '', this.description = '', this.basePrice = 0, this.featured = false, this.visible = true, this.soldOut = false, this.alcohol = false, this.stockOverride = 'auto'});
  factory _GuestMenuItemDto.fromJson(Map<String, dynamic> json) => _$GuestMenuItemDtoFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String categoryId;
@override@JsonKey() final  String description;
@override@JsonKey() final  int basePrice;
@override@JsonKey() final  bool featured;
@override@JsonKey() final  bool visible;
@override@JsonKey() final  bool soldOut;
@override@JsonKey() final  bool alcohol;
/// `auto` | `forceIn` | `forceOut`, already expired server-side — a force
/// that outlived its business day arrives as `auto`.
@override@JsonKey() final  String stockOverride;

/// Create a copy of GuestMenuItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuestMenuItemDtoCopyWith<_GuestMenuItemDto> get copyWith => __$GuestMenuItemDtoCopyWithImpl<_GuestMenuItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuestMenuItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuestMenuItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.description, description) || other.description == description)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.featured, featured) || other.featured == featured)&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.soldOut, soldOut) || other.soldOut == soldOut)&&(identical(other.alcohol, alcohol) || other.alcohol == alcohol)&&(identical(other.stockOverride, stockOverride) || other.stockOverride == stockOverride));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,categoryId,description,basePrice,featured,visible,soldOut,alcohol,stockOverride);

@override
String toString() {
  return 'GuestMenuItemDto(id: $id, name: $name, categoryId: $categoryId, description: $description, basePrice: $basePrice, featured: $featured, visible: $visible, soldOut: $soldOut, alcohol: $alcohol, stockOverride: $stockOverride)';
}


}

/// @nodoc
abstract mixin class _$GuestMenuItemDtoCopyWith<$Res> implements $GuestMenuItemDtoCopyWith<$Res> {
  factory _$GuestMenuItemDtoCopyWith(_GuestMenuItemDto value, $Res Function(_GuestMenuItemDto) _then) = __$GuestMenuItemDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String categoryId, String description, int basePrice, bool featured, bool visible, bool soldOut, bool alcohol, String stockOverride
});




}
/// @nodoc
class __$GuestMenuItemDtoCopyWithImpl<$Res>
    implements _$GuestMenuItemDtoCopyWith<$Res> {
  __$GuestMenuItemDtoCopyWithImpl(this._self, this._then);

  final _GuestMenuItemDto _self;
  final $Res Function(_GuestMenuItemDto) _then;

/// Create a copy of GuestMenuItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? categoryId = null,Object? description = null,Object? basePrice = null,Object? featured = null,Object? visible = null,Object? soldOut = null,Object? alcohol = null,Object? stockOverride = null,}) {
  return _then(_GuestMenuItemDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as int,featured: null == featured ? _self.featured : featured // ignore: cast_nullable_to_non_nullable
as bool,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,soldOut: null == soldOut ? _self.soldOut : soldOut // ignore: cast_nullable_to_non_nullable
as bool,alcohol: null == alcohol ? _self.alcohol : alcohol // ignore: cast_nullable_to_non_nullable
as bool,stockOverride: null == stockOverride ? _self.stockOverride : stockOverride // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GuestStatsDto {

 int get total; int get pending; int get accepted; int get rejected; int get value; int get medianWaitSecs;
/// Create a copy of GuestStatsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuestStatsDtoCopyWith<GuestStatsDto> get copyWith => _$GuestStatsDtoCopyWithImpl<GuestStatsDto>(this as GuestStatsDto, _$identity);

  /// Serializes this GuestStatsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuestStatsDto&&(identical(other.total, total) || other.total == total)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.accepted, accepted) || other.accepted == accepted)&&(identical(other.rejected, rejected) || other.rejected == rejected)&&(identical(other.value, value) || other.value == value)&&(identical(other.medianWaitSecs, medianWaitSecs) || other.medianWaitSecs == medianWaitSecs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,pending,accepted,rejected,value,medianWaitSecs);

@override
String toString() {
  return 'GuestStatsDto(total: $total, pending: $pending, accepted: $accepted, rejected: $rejected, value: $value, medianWaitSecs: $medianWaitSecs)';
}


}

/// @nodoc
abstract mixin class $GuestStatsDtoCopyWith<$Res>  {
  factory $GuestStatsDtoCopyWith(GuestStatsDto value, $Res Function(GuestStatsDto) _then) = _$GuestStatsDtoCopyWithImpl;
@useResult
$Res call({
 int total, int pending, int accepted, int rejected, int value, int medianWaitSecs
});




}
/// @nodoc
class _$GuestStatsDtoCopyWithImpl<$Res>
    implements $GuestStatsDtoCopyWith<$Res> {
  _$GuestStatsDtoCopyWithImpl(this._self, this._then);

  final GuestStatsDto _self;
  final $Res Function(GuestStatsDto) _then;

/// Create a copy of GuestStatsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? pending = null,Object? accepted = null,Object? rejected = null,Object? value = null,Object? medianWaitSecs = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,accepted: null == accepted ? _self.accepted : accepted // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,medianWaitSecs: null == medianWaitSecs ? _self.medianWaitSecs : medianWaitSecs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GuestStatsDto].
extension GuestStatsDtoPatterns on GuestStatsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuestStatsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuestStatsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuestStatsDto value)  $default,){
final _that = this;
switch (_that) {
case _GuestStatsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuestStatsDto value)?  $default,){
final _that = this;
switch (_that) {
case _GuestStatsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  int pending,  int accepted,  int rejected,  int value,  int medianWaitSecs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuestStatsDto() when $default != null:
return $default(_that.total,_that.pending,_that.accepted,_that.rejected,_that.value,_that.medianWaitSecs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  int pending,  int accepted,  int rejected,  int value,  int medianWaitSecs)  $default,) {final _that = this;
switch (_that) {
case _GuestStatsDto():
return $default(_that.total,_that.pending,_that.accepted,_that.rejected,_that.value,_that.medianWaitSecs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  int pending,  int accepted,  int rejected,  int value,  int medianWaitSecs)?  $default,) {final _that = this;
switch (_that) {
case _GuestStatsDto() when $default != null:
return $default(_that.total,_that.pending,_that.accepted,_that.rejected,_that.value,_that.medianWaitSecs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuestStatsDto implements GuestStatsDto {
  const _GuestStatsDto({this.total = 0, this.pending = 0, this.accepted = 0, this.rejected = 0, this.value = 0, this.medianWaitSecs = 0});
  factory _GuestStatsDto.fromJson(Map<String, dynamic> json) => _$GuestStatsDtoFromJson(json);

@override@JsonKey() final  int total;
@override@JsonKey() final  int pending;
@override@JsonKey() final  int accepted;
@override@JsonKey() final  int rejected;
@override@JsonKey() final  int value;
@override@JsonKey() final  int medianWaitSecs;

/// Create a copy of GuestStatsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuestStatsDtoCopyWith<_GuestStatsDto> get copyWith => __$GuestStatsDtoCopyWithImpl<_GuestStatsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuestStatsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuestStatsDto&&(identical(other.total, total) || other.total == total)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.accepted, accepted) || other.accepted == accepted)&&(identical(other.rejected, rejected) || other.rejected == rejected)&&(identical(other.value, value) || other.value == value)&&(identical(other.medianWaitSecs, medianWaitSecs) || other.medianWaitSecs == medianWaitSecs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,pending,accepted,rejected,value,medianWaitSecs);

@override
String toString() {
  return 'GuestStatsDto(total: $total, pending: $pending, accepted: $accepted, rejected: $rejected, value: $value, medianWaitSecs: $medianWaitSecs)';
}


}

/// @nodoc
abstract mixin class _$GuestStatsDtoCopyWith<$Res> implements $GuestStatsDtoCopyWith<$Res> {
  factory _$GuestStatsDtoCopyWith(_GuestStatsDto value, $Res Function(_GuestStatsDto) _then) = __$GuestStatsDtoCopyWithImpl;
@override @useResult
$Res call({
 int total, int pending, int accepted, int rejected, int value, int medianWaitSecs
});




}
/// @nodoc
class __$GuestStatsDtoCopyWithImpl<$Res>
    implements _$GuestStatsDtoCopyWith<$Res> {
  __$GuestStatsDtoCopyWithImpl(this._self, this._then);

  final _GuestStatsDto _self;
  final $Res Function(_GuestStatsDto) _then;

/// Create a copy of GuestStatsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? pending = null,Object? accepted = null,Object? rejected = null,Object? value = null,Object? medianWaitSecs = null,}) {
  return _then(_GuestStatsDto(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,accepted: null == accepted ? _self.accepted : accepted // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,medianWaitSecs: null == medianWaitSecs ? _self.medianWaitSecs : medianWaitSecs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
