// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'visit_expense_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VisitExpenseDto {

 String get id; String get visitId; String get categoryId;/// The venue's own word, resolved server-side. Venue-authored content, so
/// it is ARB-exempt — like a menu item's name.
 String get categoryName; int get amount; String get note; bool get hasPhoto; String? get actorUserId; String? get actorName; DateTime? get at;
/// Create a copy of VisitExpenseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisitExpenseDtoCopyWith<VisitExpenseDto> get copyWith => _$VisitExpenseDtoCopyWithImpl<VisitExpenseDto>(this as VisitExpenseDto, _$identity);

  /// Serializes this VisitExpenseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VisitExpenseDto&&(identical(other.id, id) || other.id == id)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.hasPhoto, hasPhoto) || other.hasPhoto == hasPhoto)&&(identical(other.actorUserId, actorUserId) || other.actorUserId == actorUserId)&&(identical(other.actorName, actorName) || other.actorName == actorName)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,visitId,categoryId,categoryName,amount,note,hasPhoto,actorUserId,actorName,at);

@override
String toString() {
  return 'VisitExpenseDto(id: $id, visitId: $visitId, categoryId: $categoryId, categoryName: $categoryName, amount: $amount, note: $note, hasPhoto: $hasPhoto, actorUserId: $actorUserId, actorName: $actorName, at: $at)';
}


}

/// @nodoc
abstract mixin class $VisitExpenseDtoCopyWith<$Res>  {
  factory $VisitExpenseDtoCopyWith(VisitExpenseDto value, $Res Function(VisitExpenseDto) _then) = _$VisitExpenseDtoCopyWithImpl;
@useResult
$Res call({
 String id, String visitId, String categoryId, String categoryName, int amount, String note, bool hasPhoto, String? actorUserId, String? actorName, DateTime? at
});




}
/// @nodoc
class _$VisitExpenseDtoCopyWithImpl<$Res>
    implements $VisitExpenseDtoCopyWith<$Res> {
  _$VisitExpenseDtoCopyWithImpl(this._self, this._then);

  final VisitExpenseDto _self;
  final $Res Function(VisitExpenseDto) _then;

/// Create a copy of VisitExpenseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? visitId = null,Object? categoryId = null,Object? categoryName = null,Object? amount = null,Object? note = null,Object? hasPhoto = null,Object? actorUserId = freezed,Object? actorName = freezed,Object? at = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,hasPhoto: null == hasPhoto ? _self.hasPhoto : hasPhoto // ignore: cast_nullable_to_non_nullable
as bool,actorUserId: freezed == actorUserId ? _self.actorUserId : actorUserId // ignore: cast_nullable_to_non_nullable
as String?,actorName: freezed == actorName ? _self.actorName : actorName // ignore: cast_nullable_to_non_nullable
as String?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [VisitExpenseDto].
extension VisitExpenseDtoPatterns on VisitExpenseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VisitExpenseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VisitExpenseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VisitExpenseDto value)  $default,){
final _that = this;
switch (_that) {
case _VisitExpenseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VisitExpenseDto value)?  $default,){
final _that = this;
switch (_that) {
case _VisitExpenseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String visitId,  String categoryId,  String categoryName,  int amount,  String note,  bool hasPhoto,  String? actorUserId,  String? actorName,  DateTime? at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VisitExpenseDto() when $default != null:
return $default(_that.id,_that.visitId,_that.categoryId,_that.categoryName,_that.amount,_that.note,_that.hasPhoto,_that.actorUserId,_that.actorName,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String visitId,  String categoryId,  String categoryName,  int amount,  String note,  bool hasPhoto,  String? actorUserId,  String? actorName,  DateTime? at)  $default,) {final _that = this;
switch (_that) {
case _VisitExpenseDto():
return $default(_that.id,_that.visitId,_that.categoryId,_that.categoryName,_that.amount,_that.note,_that.hasPhoto,_that.actorUserId,_that.actorName,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String visitId,  String categoryId,  String categoryName,  int amount,  String note,  bool hasPhoto,  String? actorUserId,  String? actorName,  DateTime? at)?  $default,) {final _that = this;
switch (_that) {
case _VisitExpenseDto() when $default != null:
return $default(_that.id,_that.visitId,_that.categoryId,_that.categoryName,_that.amount,_that.note,_that.hasPhoto,_that.actorUserId,_that.actorName,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VisitExpenseDto implements VisitExpenseDto {
  const _VisitExpenseDto({required this.id, this.visitId = '', this.categoryId = '', this.categoryName = '', this.amount = 0, this.note = '', this.hasPhoto = true, this.actorUserId, this.actorName, this.at});
  factory _VisitExpenseDto.fromJson(Map<String, dynamic> json) => _$VisitExpenseDtoFromJson(json);

@override final  String id;
@override@JsonKey() final  String visitId;
@override@JsonKey() final  String categoryId;
/// The venue's own word, resolved server-side. Venue-authored content, so
/// it is ARB-exempt — like a menu item's name.
@override@JsonKey() final  String categoryName;
@override@JsonKey() final  int amount;
@override@JsonKey() final  String note;
@override@JsonKey() final  bool hasPhoto;
@override final  String? actorUserId;
@override final  String? actorName;
@override final  DateTime? at;

/// Create a copy of VisitExpenseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VisitExpenseDtoCopyWith<_VisitExpenseDto> get copyWith => __$VisitExpenseDtoCopyWithImpl<_VisitExpenseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VisitExpenseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VisitExpenseDto&&(identical(other.id, id) || other.id == id)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.hasPhoto, hasPhoto) || other.hasPhoto == hasPhoto)&&(identical(other.actorUserId, actorUserId) || other.actorUserId == actorUserId)&&(identical(other.actorName, actorName) || other.actorName == actorName)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,visitId,categoryId,categoryName,amount,note,hasPhoto,actorUserId,actorName,at);

@override
String toString() {
  return 'VisitExpenseDto(id: $id, visitId: $visitId, categoryId: $categoryId, categoryName: $categoryName, amount: $amount, note: $note, hasPhoto: $hasPhoto, actorUserId: $actorUserId, actorName: $actorName, at: $at)';
}


}

/// @nodoc
abstract mixin class _$VisitExpenseDtoCopyWith<$Res> implements $VisitExpenseDtoCopyWith<$Res> {
  factory _$VisitExpenseDtoCopyWith(_VisitExpenseDto value, $Res Function(_VisitExpenseDto) _then) = __$VisitExpenseDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String visitId, String categoryId, String categoryName, int amount, String note, bool hasPhoto, String? actorUserId, String? actorName, DateTime? at
});




}
/// @nodoc
class __$VisitExpenseDtoCopyWithImpl<$Res>
    implements _$VisitExpenseDtoCopyWith<$Res> {
  __$VisitExpenseDtoCopyWithImpl(this._self, this._then);

  final _VisitExpenseDto _self;
  final $Res Function(_VisitExpenseDto) _then;

/// Create a copy of VisitExpenseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? visitId = null,Object? categoryId = null,Object? categoryName = null,Object? amount = null,Object? note = null,Object? hasPhoto = null,Object? actorUserId = freezed,Object? actorName = freezed,Object? at = freezed,}) {
  return _then(_VisitExpenseDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,hasPhoto: null == hasPhoto ? _self.hasPhoto : hasPhoto // ignore: cast_nullable_to_non_nullable
as bool,actorUserId: freezed == actorUserId ? _self.actorUserId : actorUserId // ignore: cast_nullable_to_non_nullable
as String?,actorName: freezed == actorName ? _self.actorName : actorName // ignore: cast_nullable_to_non_nullable
as String?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$VisitExpenseCategoryDto {

 String get id; String get name; bool get active; int get sortOrder;
/// Create a copy of VisitExpenseCategoryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisitExpenseCategoryDtoCopyWith<VisitExpenseCategoryDto> get copyWith => _$VisitExpenseCategoryDtoCopyWithImpl<VisitExpenseCategoryDto>(this as VisitExpenseCategoryDto, _$identity);

  /// Serializes this VisitExpenseCategoryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VisitExpenseCategoryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.active, active) || other.active == active)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,active,sortOrder);

@override
String toString() {
  return 'VisitExpenseCategoryDto(id: $id, name: $name, active: $active, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $VisitExpenseCategoryDtoCopyWith<$Res>  {
  factory $VisitExpenseCategoryDtoCopyWith(VisitExpenseCategoryDto value, $Res Function(VisitExpenseCategoryDto) _then) = _$VisitExpenseCategoryDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool active, int sortOrder
});




}
/// @nodoc
class _$VisitExpenseCategoryDtoCopyWithImpl<$Res>
    implements $VisitExpenseCategoryDtoCopyWith<$Res> {
  _$VisitExpenseCategoryDtoCopyWithImpl(this._self, this._then);

  final VisitExpenseCategoryDto _self;
  final $Res Function(VisitExpenseCategoryDto) _then;

/// Create a copy of VisitExpenseCategoryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? active = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VisitExpenseCategoryDto].
extension VisitExpenseCategoryDtoPatterns on VisitExpenseCategoryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VisitExpenseCategoryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VisitExpenseCategoryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VisitExpenseCategoryDto value)  $default,){
final _that = this;
switch (_that) {
case _VisitExpenseCategoryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VisitExpenseCategoryDto value)?  $default,){
final _that = this;
switch (_that) {
case _VisitExpenseCategoryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool active,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VisitExpenseCategoryDto() when $default != null:
return $default(_that.id,_that.name,_that.active,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool active,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _VisitExpenseCategoryDto():
return $default(_that.id,_that.name,_that.active,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool active,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _VisitExpenseCategoryDto() when $default != null:
return $default(_that.id,_that.name,_that.active,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VisitExpenseCategoryDto implements VisitExpenseCategoryDto {
  const _VisitExpenseCategoryDto({required this.id, this.name = '', this.active = true, this.sortOrder = 0});
  factory _VisitExpenseCategoryDto.fromJson(Map<String, dynamic> json) => _$VisitExpenseCategoryDtoFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  bool active;
@override@JsonKey() final  int sortOrder;

/// Create a copy of VisitExpenseCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VisitExpenseCategoryDtoCopyWith<_VisitExpenseCategoryDto> get copyWith => __$VisitExpenseCategoryDtoCopyWithImpl<_VisitExpenseCategoryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VisitExpenseCategoryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VisitExpenseCategoryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.active, active) || other.active == active)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,active,sortOrder);

@override
String toString() {
  return 'VisitExpenseCategoryDto(id: $id, name: $name, active: $active, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$VisitExpenseCategoryDtoCopyWith<$Res> implements $VisitExpenseCategoryDtoCopyWith<$Res> {
  factory _$VisitExpenseCategoryDtoCopyWith(_VisitExpenseCategoryDto value, $Res Function(_VisitExpenseCategoryDto) _then) = __$VisitExpenseCategoryDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool active, int sortOrder
});




}
/// @nodoc
class __$VisitExpenseCategoryDtoCopyWithImpl<$Res>
    implements _$VisitExpenseCategoryDtoCopyWith<$Res> {
  __$VisitExpenseCategoryDtoCopyWithImpl(this._self, this._then);

  final _VisitExpenseCategoryDto _self;
  final $Res Function(_VisitExpenseCategoryDto) _then;

/// Create a copy of VisitExpenseCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? active = null,Object? sortOrder = null,}) {
  return _then(_VisitExpenseCategoryDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$VisitExpenseSummaryDto {

 List<VisitExpenseDto> get expenses; int get total;/// The visit's subtotal of sent, non-voided lines — pre-tax, pre-discount.
 int get cap;/// True when this was assembled on the device rather than answered by the
/// host — the cap came from the cached bill and [total] counts only what
/// this handset has queued (ADR-0130).
///
/// It is **advisory**: an expense another device already synced is not in
/// it, so the number can read generously. The server re-checks the cap
/// inside its transaction at drain, which is where the guard actually
/// lives; this flag exists so the sheet can say the figure is provisional
/// rather than quietly implying it is not.
 bool get offline;
/// Create a copy of VisitExpenseSummaryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisitExpenseSummaryDtoCopyWith<VisitExpenseSummaryDto> get copyWith => _$VisitExpenseSummaryDtoCopyWithImpl<VisitExpenseSummaryDto>(this as VisitExpenseSummaryDto, _$identity);

  /// Serializes this VisitExpenseSummaryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VisitExpenseSummaryDto&&const DeepCollectionEquality().equals(other.expenses, expenses)&&(identical(other.total, total) || other.total == total)&&(identical(other.cap, cap) || other.cap == cap)&&(identical(other.offline, offline) || other.offline == offline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(expenses),total,cap,offline);

@override
String toString() {
  return 'VisitExpenseSummaryDto(expenses: $expenses, total: $total, cap: $cap, offline: $offline)';
}


}

/// @nodoc
abstract mixin class $VisitExpenseSummaryDtoCopyWith<$Res>  {
  factory $VisitExpenseSummaryDtoCopyWith(VisitExpenseSummaryDto value, $Res Function(VisitExpenseSummaryDto) _then) = _$VisitExpenseSummaryDtoCopyWithImpl;
@useResult
$Res call({
 List<VisitExpenseDto> expenses, int total, int cap, bool offline
});




}
/// @nodoc
class _$VisitExpenseSummaryDtoCopyWithImpl<$Res>
    implements $VisitExpenseSummaryDtoCopyWith<$Res> {
  _$VisitExpenseSummaryDtoCopyWithImpl(this._self, this._then);

  final VisitExpenseSummaryDto _self;
  final $Res Function(VisitExpenseSummaryDto) _then;

/// Create a copy of VisitExpenseSummaryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? expenses = null,Object? total = null,Object? cap = null,Object? offline = null,}) {
  return _then(_self.copyWith(
expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as List<VisitExpenseDto>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,cap: null == cap ? _self.cap : cap // ignore: cast_nullable_to_non_nullable
as int,offline: null == offline ? _self.offline : offline // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [VisitExpenseSummaryDto].
extension VisitExpenseSummaryDtoPatterns on VisitExpenseSummaryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VisitExpenseSummaryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VisitExpenseSummaryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VisitExpenseSummaryDto value)  $default,){
final _that = this;
switch (_that) {
case _VisitExpenseSummaryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VisitExpenseSummaryDto value)?  $default,){
final _that = this;
switch (_that) {
case _VisitExpenseSummaryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<VisitExpenseDto> expenses,  int total,  int cap,  bool offline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VisitExpenseSummaryDto() when $default != null:
return $default(_that.expenses,_that.total,_that.cap,_that.offline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<VisitExpenseDto> expenses,  int total,  int cap,  bool offline)  $default,) {final _that = this;
switch (_that) {
case _VisitExpenseSummaryDto():
return $default(_that.expenses,_that.total,_that.cap,_that.offline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<VisitExpenseDto> expenses,  int total,  int cap,  bool offline)?  $default,) {final _that = this;
switch (_that) {
case _VisitExpenseSummaryDto() when $default != null:
return $default(_that.expenses,_that.total,_that.cap,_that.offline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VisitExpenseSummaryDto implements VisitExpenseSummaryDto {
  const _VisitExpenseSummaryDto({final  List<VisitExpenseDto> expenses = const <VisitExpenseDto>[], this.total = 0, this.cap = 0, this.offline = false}): _expenses = expenses;
  factory _VisitExpenseSummaryDto.fromJson(Map<String, dynamic> json) => _$VisitExpenseSummaryDtoFromJson(json);

 final  List<VisitExpenseDto> _expenses;
@override@JsonKey() List<VisitExpenseDto> get expenses {
  if (_expenses is EqualUnmodifiableListView) return _expenses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expenses);
}

@override@JsonKey() final  int total;
/// The visit's subtotal of sent, non-voided lines — pre-tax, pre-discount.
@override@JsonKey() final  int cap;
/// True when this was assembled on the device rather than answered by the
/// host — the cap came from the cached bill and [total] counts only what
/// this handset has queued (ADR-0130).
///
/// It is **advisory**: an expense another device already synced is not in
/// it, so the number can read generously. The server re-checks the cap
/// inside its transaction at drain, which is where the guard actually
/// lives; this flag exists so the sheet can say the figure is provisional
/// rather than quietly implying it is not.
@override@JsonKey() final  bool offline;

/// Create a copy of VisitExpenseSummaryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VisitExpenseSummaryDtoCopyWith<_VisitExpenseSummaryDto> get copyWith => __$VisitExpenseSummaryDtoCopyWithImpl<_VisitExpenseSummaryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VisitExpenseSummaryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VisitExpenseSummaryDto&&const DeepCollectionEquality().equals(other._expenses, _expenses)&&(identical(other.total, total) || other.total == total)&&(identical(other.cap, cap) || other.cap == cap)&&(identical(other.offline, offline) || other.offline == offline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_expenses),total,cap,offline);

@override
String toString() {
  return 'VisitExpenseSummaryDto(expenses: $expenses, total: $total, cap: $cap, offline: $offline)';
}


}

/// @nodoc
abstract mixin class _$VisitExpenseSummaryDtoCopyWith<$Res> implements $VisitExpenseSummaryDtoCopyWith<$Res> {
  factory _$VisitExpenseSummaryDtoCopyWith(_VisitExpenseSummaryDto value, $Res Function(_VisitExpenseSummaryDto) _then) = __$VisitExpenseSummaryDtoCopyWithImpl;
@override @useResult
$Res call({
 List<VisitExpenseDto> expenses, int total, int cap, bool offline
});




}
/// @nodoc
class __$VisitExpenseSummaryDtoCopyWithImpl<$Res>
    implements _$VisitExpenseSummaryDtoCopyWith<$Res> {
  __$VisitExpenseSummaryDtoCopyWithImpl(this._self, this._then);

  final _VisitExpenseSummaryDto _self;
  final $Res Function(_VisitExpenseSummaryDto) _then;

/// Create a copy of VisitExpenseSummaryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? expenses = null,Object? total = null,Object? cap = null,Object? offline = null,}) {
  return _then(_VisitExpenseSummaryDto(
expenses: null == expenses ? _self._expenses : expenses // ignore: cast_nullable_to_non_nullable
as List<VisitExpenseDto>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,cap: null == cap ? _self.cap : cap // ignore: cast_nullable_to_non_nullable
as int,offline: null == offline ? _self.offline : offline // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
