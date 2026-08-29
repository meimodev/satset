// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reports_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReportsSnapshotDto {

 String get generatedAt; String get rangeFrom; String get rangeTo; String get range; FilterOptionsDto get filterOptions; SalesSectionDto get sales; StaffSectionDto get staff; MenuSectionDto get menu; OpsSectionDto get ops;/// Money-shaped audit rows for the off-site owner (ADR-0086), who has
/// no route to the venue log. Empty on the admin's own snapshot, which
/// reads the live log instead.
 MoneyAuditSectionDto get moneyAudit;/// The petty cash box over the same window (§Kas kecil). Its own section
/// because none of it is revenue (ADR-0089) — no figure here appears in
/// [sales], and no figure in [sales] is net of it.
 KasSectionDto get kas;/// [[Keanggotaan (membership)]] over the same window. Its own section for
/// the mirror-image reason [kas] is: points are a claim on future takings,
/// not a channel — folding a give-away into [sales] would let it read as
/// revenue (ADR-0095).
 MembersSectionDto get members;/// [[Piutang]] over the same window (ADR-0098). Its own section again: a
/// collection is not revenue — the sale was booked the night it was eaten —
/// so nothing here may be added to [sales]. The exception runs the other
/// way: [PiutangSectionDto.writtenOff] is republished as
/// [SalesSectionDto.badDebt], because a loss belongs beside what it was
/// lost against.
 PiutangSectionDto get piutang;/// Attendance over the same window. Deliberately not part of [staff]: that
/// section is what someone sold, this one is whether they were here, and a
/// slow Tuesday must not read as a slack one.
 JamKerjaSectionDto get jamKerja;
/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportsSnapshotDtoCopyWith<ReportsSnapshotDto> get copyWith => _$ReportsSnapshotDtoCopyWithImpl<ReportsSnapshotDto>(this as ReportsSnapshotDto, _$identity);

  /// Serializes this ReportsSnapshotDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportsSnapshotDto&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.rangeFrom, rangeFrom) || other.rangeFrom == rangeFrom)&&(identical(other.rangeTo, rangeTo) || other.rangeTo == rangeTo)&&(identical(other.range, range) || other.range == range)&&(identical(other.filterOptions, filterOptions) || other.filterOptions == filterOptions)&&(identical(other.sales, sales) || other.sales == sales)&&(identical(other.staff, staff) || other.staff == staff)&&(identical(other.menu, menu) || other.menu == menu)&&(identical(other.ops, ops) || other.ops == ops)&&(identical(other.moneyAudit, moneyAudit) || other.moneyAudit == moneyAudit)&&(identical(other.kas, kas) || other.kas == kas)&&(identical(other.members, members) || other.members == members)&&(identical(other.piutang, piutang) || other.piutang == piutang)&&(identical(other.jamKerja, jamKerja) || other.jamKerja == jamKerja));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generatedAt,rangeFrom,rangeTo,range,filterOptions,sales,staff,menu,ops,moneyAudit,kas,members,piutang,jamKerja);

@override
String toString() {
  return 'ReportsSnapshotDto(generatedAt: $generatedAt, rangeFrom: $rangeFrom, rangeTo: $rangeTo, range: $range, filterOptions: $filterOptions, sales: $sales, staff: $staff, menu: $menu, ops: $ops, moneyAudit: $moneyAudit, kas: $kas, members: $members, piutang: $piutang, jamKerja: $jamKerja)';
}


}

/// @nodoc
abstract mixin class $ReportsSnapshotDtoCopyWith<$Res>  {
  factory $ReportsSnapshotDtoCopyWith(ReportsSnapshotDto value, $Res Function(ReportsSnapshotDto) _then) = _$ReportsSnapshotDtoCopyWithImpl;
@useResult
$Res call({
 String generatedAt, String rangeFrom, String rangeTo, String range, FilterOptionsDto filterOptions, SalesSectionDto sales, StaffSectionDto staff, MenuSectionDto menu, OpsSectionDto ops, MoneyAuditSectionDto moneyAudit, KasSectionDto kas, MembersSectionDto members, PiutangSectionDto piutang, JamKerjaSectionDto jamKerja
});


$FilterOptionsDtoCopyWith<$Res> get filterOptions;$SalesSectionDtoCopyWith<$Res> get sales;$StaffSectionDtoCopyWith<$Res> get staff;$MenuSectionDtoCopyWith<$Res> get menu;$OpsSectionDtoCopyWith<$Res> get ops;$MoneyAuditSectionDtoCopyWith<$Res> get moneyAudit;$KasSectionDtoCopyWith<$Res> get kas;$MembersSectionDtoCopyWith<$Res> get members;$PiutangSectionDtoCopyWith<$Res> get piutang;$JamKerjaSectionDtoCopyWith<$Res> get jamKerja;

}
/// @nodoc
class _$ReportsSnapshotDtoCopyWithImpl<$Res>
    implements $ReportsSnapshotDtoCopyWith<$Res> {
  _$ReportsSnapshotDtoCopyWithImpl(this._self, this._then);

  final ReportsSnapshotDto _self;
  final $Res Function(ReportsSnapshotDto) _then;

/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? generatedAt = null,Object? rangeFrom = null,Object? rangeTo = null,Object? range = null,Object? filterOptions = null,Object? sales = null,Object? staff = null,Object? menu = null,Object? ops = null,Object? moneyAudit = null,Object? kas = null,Object? members = null,Object? piutang = null,Object? jamKerja = null,}) {
  return _then(_self.copyWith(
generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,rangeFrom: null == rangeFrom ? _self.rangeFrom : rangeFrom // ignore: cast_nullable_to_non_nullable
as String,rangeTo: null == rangeTo ? _self.rangeTo : rangeTo // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as String,filterOptions: null == filterOptions ? _self.filterOptions : filterOptions // ignore: cast_nullable_to_non_nullable
as FilterOptionsDto,sales: null == sales ? _self.sales : sales // ignore: cast_nullable_to_non_nullable
as SalesSectionDto,staff: null == staff ? _self.staff : staff // ignore: cast_nullable_to_non_nullable
as StaffSectionDto,menu: null == menu ? _self.menu : menu // ignore: cast_nullable_to_non_nullable
as MenuSectionDto,ops: null == ops ? _self.ops : ops // ignore: cast_nullable_to_non_nullable
as OpsSectionDto,moneyAudit: null == moneyAudit ? _self.moneyAudit : moneyAudit // ignore: cast_nullable_to_non_nullable
as MoneyAuditSectionDto,kas: null == kas ? _self.kas : kas // ignore: cast_nullable_to_non_nullable
as KasSectionDto,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as MembersSectionDto,piutang: null == piutang ? _self.piutang : piutang // ignore: cast_nullable_to_non_nullable
as PiutangSectionDto,jamKerja: null == jamKerja ? _self.jamKerja : jamKerja // ignore: cast_nullable_to_non_nullable
as JamKerjaSectionDto,
  ));
}
/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FilterOptionsDtoCopyWith<$Res> get filterOptions {
  
  return $FilterOptionsDtoCopyWith<$Res>(_self.filterOptions, (value) {
    return _then(_self.copyWith(filterOptions: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SalesSectionDtoCopyWith<$Res> get sales {
  
  return $SalesSectionDtoCopyWith<$Res>(_self.sales, (value) {
    return _then(_self.copyWith(sales: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StaffSectionDtoCopyWith<$Res> get staff {
  
  return $StaffSectionDtoCopyWith<$Res>(_self.staff, (value) {
    return _then(_self.copyWith(staff: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MenuSectionDtoCopyWith<$Res> get menu {
  
  return $MenuSectionDtoCopyWith<$Res>(_self.menu, (value) {
    return _then(_self.copyWith(menu: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpsSectionDtoCopyWith<$Res> get ops {
  
  return $OpsSectionDtoCopyWith<$Res>(_self.ops, (value) {
    return _then(_self.copyWith(ops: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyAuditSectionDtoCopyWith<$Res> get moneyAudit {
  
  return $MoneyAuditSectionDtoCopyWith<$Res>(_self.moneyAudit, (value) {
    return _then(_self.copyWith(moneyAudit: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KasSectionDtoCopyWith<$Res> get kas {
  
  return $KasSectionDtoCopyWith<$Res>(_self.kas, (value) {
    return _then(_self.copyWith(kas: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MembersSectionDtoCopyWith<$Res> get members {
  
  return $MembersSectionDtoCopyWith<$Res>(_self.members, (value) {
    return _then(_self.copyWith(members: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PiutangSectionDtoCopyWith<$Res> get piutang {
  
  return $PiutangSectionDtoCopyWith<$Res>(_self.piutang, (value) {
    return _then(_self.copyWith(piutang: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JamKerjaSectionDtoCopyWith<$Res> get jamKerja {
  
  return $JamKerjaSectionDtoCopyWith<$Res>(_self.jamKerja, (value) {
    return _then(_self.copyWith(jamKerja: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReportsSnapshotDto].
extension ReportsSnapshotDtoPatterns on ReportsSnapshotDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportsSnapshotDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportsSnapshotDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportsSnapshotDto value)  $default,){
final _that = this;
switch (_that) {
case _ReportsSnapshotDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportsSnapshotDto value)?  $default,){
final _that = this;
switch (_that) {
case _ReportsSnapshotDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String generatedAt,  String rangeFrom,  String rangeTo,  String range,  FilterOptionsDto filterOptions,  SalesSectionDto sales,  StaffSectionDto staff,  MenuSectionDto menu,  OpsSectionDto ops,  MoneyAuditSectionDto moneyAudit,  KasSectionDto kas,  MembersSectionDto members,  PiutangSectionDto piutang,  JamKerjaSectionDto jamKerja)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportsSnapshotDto() when $default != null:
return $default(_that.generatedAt,_that.rangeFrom,_that.rangeTo,_that.range,_that.filterOptions,_that.sales,_that.staff,_that.menu,_that.ops,_that.moneyAudit,_that.kas,_that.members,_that.piutang,_that.jamKerja);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String generatedAt,  String rangeFrom,  String rangeTo,  String range,  FilterOptionsDto filterOptions,  SalesSectionDto sales,  StaffSectionDto staff,  MenuSectionDto menu,  OpsSectionDto ops,  MoneyAuditSectionDto moneyAudit,  KasSectionDto kas,  MembersSectionDto members,  PiutangSectionDto piutang,  JamKerjaSectionDto jamKerja)  $default,) {final _that = this;
switch (_that) {
case _ReportsSnapshotDto():
return $default(_that.generatedAt,_that.rangeFrom,_that.rangeTo,_that.range,_that.filterOptions,_that.sales,_that.staff,_that.menu,_that.ops,_that.moneyAudit,_that.kas,_that.members,_that.piutang,_that.jamKerja);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String generatedAt,  String rangeFrom,  String rangeTo,  String range,  FilterOptionsDto filterOptions,  SalesSectionDto sales,  StaffSectionDto staff,  MenuSectionDto menu,  OpsSectionDto ops,  MoneyAuditSectionDto moneyAudit,  KasSectionDto kas,  MembersSectionDto members,  PiutangSectionDto piutang,  JamKerjaSectionDto jamKerja)?  $default,) {final _that = this;
switch (_that) {
case _ReportsSnapshotDto() when $default != null:
return $default(_that.generatedAt,_that.rangeFrom,_that.rangeTo,_that.range,_that.filterOptions,_that.sales,_that.staff,_that.menu,_that.ops,_that.moneyAudit,_that.kas,_that.members,_that.piutang,_that.jamKerja);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReportsSnapshotDto implements ReportsSnapshotDto {
  const _ReportsSnapshotDto({required this.generatedAt, required this.rangeFrom, required this.rangeTo, required this.range, required this.filterOptions, required this.sales, required this.staff, required this.menu, required this.ops, this.moneyAudit = const MoneyAuditSectionDto(), this.kas = const KasSectionDto(), this.members = const MembersSectionDto(), this.piutang = const PiutangSectionDto(), this.jamKerja = const JamKerjaSectionDto()});
  factory _ReportsSnapshotDto.fromJson(Map<String, dynamic> json) => _$ReportsSnapshotDtoFromJson(json);

@override final  String generatedAt;
@override final  String rangeFrom;
@override final  String rangeTo;
@override final  String range;
@override final  FilterOptionsDto filterOptions;
@override final  SalesSectionDto sales;
@override final  StaffSectionDto staff;
@override final  MenuSectionDto menu;
@override final  OpsSectionDto ops;
/// Money-shaped audit rows for the off-site owner (ADR-0086), who has
/// no route to the venue log. Empty on the admin's own snapshot, which
/// reads the live log instead.
@override@JsonKey() final  MoneyAuditSectionDto moneyAudit;
/// The petty cash box over the same window (§Kas kecil). Its own section
/// because none of it is revenue (ADR-0089) — no figure here appears in
/// [sales], and no figure in [sales] is net of it.
@override@JsonKey() final  KasSectionDto kas;
/// [[Keanggotaan (membership)]] over the same window. Its own section for
/// the mirror-image reason [kas] is: points are a claim on future takings,
/// not a channel — folding a give-away into [sales] would let it read as
/// revenue (ADR-0095).
@override@JsonKey() final  MembersSectionDto members;
/// [[Piutang]] over the same window (ADR-0098). Its own section again: a
/// collection is not revenue — the sale was booked the night it was eaten —
/// so nothing here may be added to [sales]. The exception runs the other
/// way: [PiutangSectionDto.writtenOff] is republished as
/// [SalesSectionDto.badDebt], because a loss belongs beside what it was
/// lost against.
@override@JsonKey() final  PiutangSectionDto piutang;
/// Attendance over the same window. Deliberately not part of [staff]: that
/// section is what someone sold, this one is whether they were here, and a
/// slow Tuesday must not read as a slack one.
@override@JsonKey() final  JamKerjaSectionDto jamKerja;

/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportsSnapshotDtoCopyWith<_ReportsSnapshotDto> get copyWith => __$ReportsSnapshotDtoCopyWithImpl<_ReportsSnapshotDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReportsSnapshotDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportsSnapshotDto&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.rangeFrom, rangeFrom) || other.rangeFrom == rangeFrom)&&(identical(other.rangeTo, rangeTo) || other.rangeTo == rangeTo)&&(identical(other.range, range) || other.range == range)&&(identical(other.filterOptions, filterOptions) || other.filterOptions == filterOptions)&&(identical(other.sales, sales) || other.sales == sales)&&(identical(other.staff, staff) || other.staff == staff)&&(identical(other.menu, menu) || other.menu == menu)&&(identical(other.ops, ops) || other.ops == ops)&&(identical(other.moneyAudit, moneyAudit) || other.moneyAudit == moneyAudit)&&(identical(other.kas, kas) || other.kas == kas)&&(identical(other.members, members) || other.members == members)&&(identical(other.piutang, piutang) || other.piutang == piutang)&&(identical(other.jamKerja, jamKerja) || other.jamKerja == jamKerja));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generatedAt,rangeFrom,rangeTo,range,filterOptions,sales,staff,menu,ops,moneyAudit,kas,members,piutang,jamKerja);

@override
String toString() {
  return 'ReportsSnapshotDto(generatedAt: $generatedAt, rangeFrom: $rangeFrom, rangeTo: $rangeTo, range: $range, filterOptions: $filterOptions, sales: $sales, staff: $staff, menu: $menu, ops: $ops, moneyAudit: $moneyAudit, kas: $kas, members: $members, piutang: $piutang, jamKerja: $jamKerja)';
}


}

/// @nodoc
abstract mixin class _$ReportsSnapshotDtoCopyWith<$Res> implements $ReportsSnapshotDtoCopyWith<$Res> {
  factory _$ReportsSnapshotDtoCopyWith(_ReportsSnapshotDto value, $Res Function(_ReportsSnapshotDto) _then) = __$ReportsSnapshotDtoCopyWithImpl;
@override @useResult
$Res call({
 String generatedAt, String rangeFrom, String rangeTo, String range, FilterOptionsDto filterOptions, SalesSectionDto sales, StaffSectionDto staff, MenuSectionDto menu, OpsSectionDto ops, MoneyAuditSectionDto moneyAudit, KasSectionDto kas, MembersSectionDto members, PiutangSectionDto piutang, JamKerjaSectionDto jamKerja
});


@override $FilterOptionsDtoCopyWith<$Res> get filterOptions;@override $SalesSectionDtoCopyWith<$Res> get sales;@override $StaffSectionDtoCopyWith<$Res> get staff;@override $MenuSectionDtoCopyWith<$Res> get menu;@override $OpsSectionDtoCopyWith<$Res> get ops;@override $MoneyAuditSectionDtoCopyWith<$Res> get moneyAudit;@override $KasSectionDtoCopyWith<$Res> get kas;@override $MembersSectionDtoCopyWith<$Res> get members;@override $PiutangSectionDtoCopyWith<$Res> get piutang;@override $JamKerjaSectionDtoCopyWith<$Res> get jamKerja;

}
/// @nodoc
class __$ReportsSnapshotDtoCopyWithImpl<$Res>
    implements _$ReportsSnapshotDtoCopyWith<$Res> {
  __$ReportsSnapshotDtoCopyWithImpl(this._self, this._then);

  final _ReportsSnapshotDto _self;
  final $Res Function(_ReportsSnapshotDto) _then;

/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? generatedAt = null,Object? rangeFrom = null,Object? rangeTo = null,Object? range = null,Object? filterOptions = null,Object? sales = null,Object? staff = null,Object? menu = null,Object? ops = null,Object? moneyAudit = null,Object? kas = null,Object? members = null,Object? piutang = null,Object? jamKerja = null,}) {
  return _then(_ReportsSnapshotDto(
generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,rangeFrom: null == rangeFrom ? _self.rangeFrom : rangeFrom // ignore: cast_nullable_to_non_nullable
as String,rangeTo: null == rangeTo ? _self.rangeTo : rangeTo // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as String,filterOptions: null == filterOptions ? _self.filterOptions : filterOptions // ignore: cast_nullable_to_non_nullable
as FilterOptionsDto,sales: null == sales ? _self.sales : sales // ignore: cast_nullable_to_non_nullable
as SalesSectionDto,staff: null == staff ? _self.staff : staff // ignore: cast_nullable_to_non_nullable
as StaffSectionDto,menu: null == menu ? _self.menu : menu // ignore: cast_nullable_to_non_nullable
as MenuSectionDto,ops: null == ops ? _self.ops : ops // ignore: cast_nullable_to_non_nullable
as OpsSectionDto,moneyAudit: null == moneyAudit ? _self.moneyAudit : moneyAudit // ignore: cast_nullable_to_non_nullable
as MoneyAuditSectionDto,kas: null == kas ? _self.kas : kas // ignore: cast_nullable_to_non_nullable
as KasSectionDto,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as MembersSectionDto,piutang: null == piutang ? _self.piutang : piutang // ignore: cast_nullable_to_non_nullable
as PiutangSectionDto,jamKerja: null == jamKerja ? _self.jamKerja : jamKerja // ignore: cast_nullable_to_non_nullable
as JamKerjaSectionDto,
  ));
}

/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FilterOptionsDtoCopyWith<$Res> get filterOptions {
  
  return $FilterOptionsDtoCopyWith<$Res>(_self.filterOptions, (value) {
    return _then(_self.copyWith(filterOptions: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SalesSectionDtoCopyWith<$Res> get sales {
  
  return $SalesSectionDtoCopyWith<$Res>(_self.sales, (value) {
    return _then(_self.copyWith(sales: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StaffSectionDtoCopyWith<$Res> get staff {
  
  return $StaffSectionDtoCopyWith<$Res>(_self.staff, (value) {
    return _then(_self.copyWith(staff: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MenuSectionDtoCopyWith<$Res> get menu {
  
  return $MenuSectionDtoCopyWith<$Res>(_self.menu, (value) {
    return _then(_self.copyWith(menu: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpsSectionDtoCopyWith<$Res> get ops {
  
  return $OpsSectionDtoCopyWith<$Res>(_self.ops, (value) {
    return _then(_self.copyWith(ops: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyAuditSectionDtoCopyWith<$Res> get moneyAudit {
  
  return $MoneyAuditSectionDtoCopyWith<$Res>(_self.moneyAudit, (value) {
    return _then(_self.copyWith(moneyAudit: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KasSectionDtoCopyWith<$Res> get kas {
  
  return $KasSectionDtoCopyWith<$Res>(_self.kas, (value) {
    return _then(_self.copyWith(kas: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MembersSectionDtoCopyWith<$Res> get members {
  
  return $MembersSectionDtoCopyWith<$Res>(_self.members, (value) {
    return _then(_self.copyWith(members: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PiutangSectionDtoCopyWith<$Res> get piutang {
  
  return $PiutangSectionDtoCopyWith<$Res>(_self.piutang, (value) {
    return _then(_self.copyWith(piutang: value));
  });
}/// Create a copy of ReportsSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JamKerjaSectionDtoCopyWith<$Res> get jamKerja {
  
  return $JamKerjaSectionDtoCopyWith<$Res>(_self.jamKerja, (value) {
    return _then(_self.copyWith(jamKerja: value));
  });
}
}


/// @nodoc
mixin _$FilterOptionsDto {

 List<NamedIdDto> get servers; List<NamedIdDto> get zones; List<NamedIdDto> get categories;
/// Create a copy of FilterOptionsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilterOptionsDtoCopyWith<FilterOptionsDto> get copyWith => _$FilterOptionsDtoCopyWithImpl<FilterOptionsDto>(this as FilterOptionsDto, _$identity);

  /// Serializes this FilterOptionsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FilterOptionsDto&&const DeepCollectionEquality().equals(other.servers, servers)&&const DeepCollectionEquality().equals(other.zones, zones)&&const DeepCollectionEquality().equals(other.categories, categories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(servers),const DeepCollectionEquality().hash(zones),const DeepCollectionEquality().hash(categories));

@override
String toString() {
  return 'FilterOptionsDto(servers: $servers, zones: $zones, categories: $categories)';
}


}

/// @nodoc
abstract mixin class $FilterOptionsDtoCopyWith<$Res>  {
  factory $FilterOptionsDtoCopyWith(FilterOptionsDto value, $Res Function(FilterOptionsDto) _then) = _$FilterOptionsDtoCopyWithImpl;
@useResult
$Res call({
 List<NamedIdDto> servers, List<NamedIdDto> zones, List<NamedIdDto> categories
});




}
/// @nodoc
class _$FilterOptionsDtoCopyWithImpl<$Res>
    implements $FilterOptionsDtoCopyWith<$Res> {
  _$FilterOptionsDtoCopyWithImpl(this._self, this._then);

  final FilterOptionsDto _self;
  final $Res Function(FilterOptionsDto) _then;

/// Create a copy of FilterOptionsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? servers = null,Object? zones = null,Object? categories = null,}) {
  return _then(_self.copyWith(
servers: null == servers ? _self.servers : servers // ignore: cast_nullable_to_non_nullable
as List<NamedIdDto>,zones: null == zones ? _self.zones : zones // ignore: cast_nullable_to_non_nullable
as List<NamedIdDto>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<NamedIdDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [FilterOptionsDto].
extension FilterOptionsDtoPatterns on FilterOptionsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FilterOptionsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FilterOptionsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FilterOptionsDto value)  $default,){
final _that = this;
switch (_that) {
case _FilterOptionsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FilterOptionsDto value)?  $default,){
final _that = this;
switch (_that) {
case _FilterOptionsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NamedIdDto> servers,  List<NamedIdDto> zones,  List<NamedIdDto> categories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FilterOptionsDto() when $default != null:
return $default(_that.servers,_that.zones,_that.categories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NamedIdDto> servers,  List<NamedIdDto> zones,  List<NamedIdDto> categories)  $default,) {final _that = this;
switch (_that) {
case _FilterOptionsDto():
return $default(_that.servers,_that.zones,_that.categories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NamedIdDto> servers,  List<NamedIdDto> zones,  List<NamedIdDto> categories)?  $default,) {final _that = this;
switch (_that) {
case _FilterOptionsDto() when $default != null:
return $default(_that.servers,_that.zones,_that.categories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FilterOptionsDto implements FilterOptionsDto {
  const _FilterOptionsDto({final  List<NamedIdDto> servers = const <NamedIdDto>[], final  List<NamedIdDto> zones = const <NamedIdDto>[], final  List<NamedIdDto> categories = const <NamedIdDto>[]}): _servers = servers,_zones = zones,_categories = categories;
  factory _FilterOptionsDto.fromJson(Map<String, dynamic> json) => _$FilterOptionsDtoFromJson(json);

 final  List<NamedIdDto> _servers;
@override@JsonKey() List<NamedIdDto> get servers {
  if (_servers is EqualUnmodifiableListView) return _servers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_servers);
}

 final  List<NamedIdDto> _zones;
@override@JsonKey() List<NamedIdDto> get zones {
  if (_zones is EqualUnmodifiableListView) return _zones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_zones);
}

 final  List<NamedIdDto> _categories;
@override@JsonKey() List<NamedIdDto> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}


/// Create a copy of FilterOptionsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FilterOptionsDtoCopyWith<_FilterOptionsDto> get copyWith => __$FilterOptionsDtoCopyWithImpl<_FilterOptionsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FilterOptionsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FilterOptionsDto&&const DeepCollectionEquality().equals(other._servers, _servers)&&const DeepCollectionEquality().equals(other._zones, _zones)&&const DeepCollectionEquality().equals(other._categories, _categories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_servers),const DeepCollectionEquality().hash(_zones),const DeepCollectionEquality().hash(_categories));

@override
String toString() {
  return 'FilterOptionsDto(servers: $servers, zones: $zones, categories: $categories)';
}


}

/// @nodoc
abstract mixin class _$FilterOptionsDtoCopyWith<$Res> implements $FilterOptionsDtoCopyWith<$Res> {
  factory _$FilterOptionsDtoCopyWith(_FilterOptionsDto value, $Res Function(_FilterOptionsDto) _then) = __$FilterOptionsDtoCopyWithImpl;
@override @useResult
$Res call({
 List<NamedIdDto> servers, List<NamedIdDto> zones, List<NamedIdDto> categories
});




}
/// @nodoc
class __$FilterOptionsDtoCopyWithImpl<$Res>
    implements _$FilterOptionsDtoCopyWith<$Res> {
  __$FilterOptionsDtoCopyWithImpl(this._self, this._then);

  final _FilterOptionsDto _self;
  final $Res Function(_FilterOptionsDto) _then;

/// Create a copy of FilterOptionsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? servers = null,Object? zones = null,Object? categories = null,}) {
  return _then(_FilterOptionsDto(
servers: null == servers ? _self._servers : servers // ignore: cast_nullable_to_non_nullable
as List<NamedIdDto>,zones: null == zones ? _self._zones : zones // ignore: cast_nullable_to_non_nullable
as List<NamedIdDto>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<NamedIdDto>,
  ));
}


}


/// @nodoc
mixin _$NamedIdDto {

 String get id; String get name;
/// Create a copy of NamedIdDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NamedIdDtoCopyWith<NamedIdDto> get copyWith => _$NamedIdDtoCopyWithImpl<NamedIdDto>(this as NamedIdDto, _$identity);

  /// Serializes this NamedIdDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NamedIdDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'NamedIdDto(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $NamedIdDtoCopyWith<$Res>  {
  factory $NamedIdDtoCopyWith(NamedIdDto value, $Res Function(NamedIdDto) _then) = _$NamedIdDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$NamedIdDtoCopyWithImpl<$Res>
    implements $NamedIdDtoCopyWith<$Res> {
  _$NamedIdDtoCopyWithImpl(this._self, this._then);

  final NamedIdDto _self;
  final $Res Function(NamedIdDto) _then;

/// Create a copy of NamedIdDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NamedIdDto].
extension NamedIdDtoPatterns on NamedIdDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NamedIdDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NamedIdDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NamedIdDto value)  $default,){
final _that = this;
switch (_that) {
case _NamedIdDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NamedIdDto value)?  $default,){
final _that = this;
switch (_that) {
case _NamedIdDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NamedIdDto() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _NamedIdDto():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _NamedIdDto() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NamedIdDto implements NamedIdDto {
  const _NamedIdDto({required this.id, required this.name});
  factory _NamedIdDto.fromJson(Map<String, dynamic> json) => _$NamedIdDtoFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of NamedIdDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NamedIdDtoCopyWith<_NamedIdDto> get copyWith => __$NamedIdDtoCopyWithImpl<_NamedIdDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NamedIdDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NamedIdDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'NamedIdDto(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$NamedIdDtoCopyWith<$Res> implements $NamedIdDtoCopyWith<$Res> {
  factory _$NamedIdDtoCopyWith(_NamedIdDto value, $Res Function(_NamedIdDto) _then) = __$NamedIdDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$NamedIdDtoCopyWithImpl<$Res>
    implements _$NamedIdDtoCopyWith<$Res> {
  __$NamedIdDtoCopyWithImpl(this._self, this._then);

  final _NamedIdDto _self;
  final $Res Function(_NamedIdDto) _then;

/// Create a copy of NamedIdDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_NamedIdDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$KpiTileDto {

/// Stable id for the tile, rendered by `kpiLabel`/`kpiSub` at read time
/// (ADR-0085). [label] and [sub] survive only as the fallback for a code
/// this build does not know.
 String get key;/// The caption's counts, in the order its message declares them.
 List<int> get args; String get label;/// Money tiles ship the amount, not its rendering — `jt` and `rb` are
/// Indonesian words and the reader picks its own (`kpiValue`). Tiles that
/// are not money (a duration, a ratio) keep using [value].
 int? get rupiah; String get value; String get sub;
/// Create a copy of KpiTileDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KpiTileDtoCopyWith<KpiTileDto> get copyWith => _$KpiTileDtoCopyWithImpl<KpiTileDto>(this as KpiTileDto, _$identity);

  /// Serializes this KpiTileDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KpiTileDto&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other.args, args)&&(identical(other.label, label) || other.label == label)&&(identical(other.rupiah, rupiah) || other.rupiah == rupiah)&&(identical(other.value, value) || other.value == value)&&(identical(other.sub, sub) || other.sub == sub));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,const DeepCollectionEquality().hash(args),label,rupiah,value,sub);

@override
String toString() {
  return 'KpiTileDto(key: $key, args: $args, label: $label, rupiah: $rupiah, value: $value, sub: $sub)';
}


}

/// @nodoc
abstract mixin class $KpiTileDtoCopyWith<$Res>  {
  factory $KpiTileDtoCopyWith(KpiTileDto value, $Res Function(KpiTileDto) _then) = _$KpiTileDtoCopyWithImpl;
@useResult
$Res call({
 String key, List<int> args, String label, int? rupiah, String value, String sub
});




}
/// @nodoc
class _$KpiTileDtoCopyWithImpl<$Res>
    implements $KpiTileDtoCopyWith<$Res> {
  _$KpiTileDtoCopyWithImpl(this._self, this._then);

  final KpiTileDto _self;
  final $Res Function(KpiTileDto) _then;

/// Create a copy of KpiTileDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? args = null,Object? label = null,Object? rupiah = freezed,Object? value = null,Object? sub = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as List<int>,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,rupiah: freezed == rupiah ? _self.rupiah : rupiah // ignore: cast_nullable_to_non_nullable
as int?,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,sub: null == sub ? _self.sub : sub // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [KpiTileDto].
extension KpiTileDtoPatterns on KpiTileDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KpiTileDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KpiTileDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KpiTileDto value)  $default,){
final _that = this;
switch (_that) {
case _KpiTileDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KpiTileDto value)?  $default,){
final _that = this;
switch (_that) {
case _KpiTileDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  List<int> args,  String label,  int? rupiah,  String value,  String sub)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KpiTileDto() when $default != null:
return $default(_that.key,_that.args,_that.label,_that.rupiah,_that.value,_that.sub);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  List<int> args,  String label,  int? rupiah,  String value,  String sub)  $default,) {final _that = this;
switch (_that) {
case _KpiTileDto():
return $default(_that.key,_that.args,_that.label,_that.rupiah,_that.value,_that.sub);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  List<int> args,  String label,  int? rupiah,  String value,  String sub)?  $default,) {final _that = this;
switch (_that) {
case _KpiTileDto() when $default != null:
return $default(_that.key,_that.args,_that.label,_that.rupiah,_that.value,_that.sub);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KpiTileDto implements KpiTileDto {
  const _KpiTileDto({this.key = '', final  List<int> args = const <int>[], this.label = '', this.rupiah, this.value = '', this.sub = ''}): _args = args;
  factory _KpiTileDto.fromJson(Map<String, dynamic> json) => _$KpiTileDtoFromJson(json);

/// Stable id for the tile, rendered by `kpiLabel`/`kpiSub` at read time
/// (ADR-0085). [label] and [sub] survive only as the fallback for a code
/// this build does not know.
@override@JsonKey() final  String key;
/// The caption's counts, in the order its message declares them.
 final  List<int> _args;
/// The caption's counts, in the order its message declares them.
@override@JsonKey() List<int> get args {
  if (_args is EqualUnmodifiableListView) return _args;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_args);
}

@override@JsonKey() final  String label;
/// Money tiles ship the amount, not its rendering — `jt` and `rb` are
/// Indonesian words and the reader picks its own (`kpiValue`). Tiles that
/// are not money (a duration, a ratio) keep using [value].
@override final  int? rupiah;
@override@JsonKey() final  String value;
@override@JsonKey() final  String sub;

/// Create a copy of KpiTileDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KpiTileDtoCopyWith<_KpiTileDto> get copyWith => __$KpiTileDtoCopyWithImpl<_KpiTileDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KpiTileDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KpiTileDto&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other._args, _args)&&(identical(other.label, label) || other.label == label)&&(identical(other.rupiah, rupiah) || other.rupiah == rupiah)&&(identical(other.value, value) || other.value == value)&&(identical(other.sub, sub) || other.sub == sub));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,const DeepCollectionEquality().hash(_args),label,rupiah,value,sub);

@override
String toString() {
  return 'KpiTileDto(key: $key, args: $args, label: $label, rupiah: $rupiah, value: $value, sub: $sub)';
}


}

/// @nodoc
abstract mixin class _$KpiTileDtoCopyWith<$Res> implements $KpiTileDtoCopyWith<$Res> {
  factory _$KpiTileDtoCopyWith(_KpiTileDto value, $Res Function(_KpiTileDto) _then) = __$KpiTileDtoCopyWithImpl;
@override @useResult
$Res call({
 String key, List<int> args, String label, int? rupiah, String value, String sub
});




}
/// @nodoc
class __$KpiTileDtoCopyWithImpl<$Res>
    implements _$KpiTileDtoCopyWith<$Res> {
  __$KpiTileDtoCopyWithImpl(this._self, this._then);

  final _KpiTileDto _self;
  final $Res Function(_KpiTileDto) _then;

/// Create a copy of KpiTileDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? args = null,Object? label = null,Object? rupiah = freezed,Object? value = null,Object? sub = null,}) {
  return _then(_KpiTileDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self._args : args // ignore: cast_nullable_to_non_nullable
as List<int>,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,rupiah: freezed == rupiah ? _self.rupiah : rupiah // ignore: cast_nullable_to_non_nullable
as int?,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,sub: null == sub ? _self.sub : sub // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SalesSectionDto {

 List<KpiTileDto> get kpis; List<CoverDayDto> get coverTrend; List<double> get hourly; TakeawaySplitDto? get takeaway;/// [[Piutang]] given up on in this window — the one figure that crosses in
/// from [ReportsSnapshotDto.piutang] (ADR-0098). A tab written off weeks
/// after close is a real loss against revenue already booked, so it is
/// shown here rather than left in its own section where an owner reading
/// [kpis] would never meet it. Read-only: no KPI is net of it.
 int get badDebt;
/// Create a copy of SalesSectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalesSectionDtoCopyWith<SalesSectionDto> get copyWith => _$SalesSectionDtoCopyWithImpl<SalesSectionDto>(this as SalesSectionDto, _$identity);

  /// Serializes this SalesSectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesSectionDto&&const DeepCollectionEquality().equals(other.kpis, kpis)&&const DeepCollectionEquality().equals(other.coverTrend, coverTrend)&&const DeepCollectionEquality().equals(other.hourly, hourly)&&(identical(other.takeaway, takeaway) || other.takeaway == takeaway)&&(identical(other.badDebt, badDebt) || other.badDebt == badDebt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(kpis),const DeepCollectionEquality().hash(coverTrend),const DeepCollectionEquality().hash(hourly),takeaway,badDebt);

@override
String toString() {
  return 'SalesSectionDto(kpis: $kpis, coverTrend: $coverTrend, hourly: $hourly, takeaway: $takeaway, badDebt: $badDebt)';
}


}

/// @nodoc
abstract mixin class $SalesSectionDtoCopyWith<$Res>  {
  factory $SalesSectionDtoCopyWith(SalesSectionDto value, $Res Function(SalesSectionDto) _then) = _$SalesSectionDtoCopyWithImpl;
@useResult
$Res call({
 List<KpiTileDto> kpis, List<CoverDayDto> coverTrend, List<double> hourly, TakeawaySplitDto? takeaway, int badDebt
});


$TakeawaySplitDtoCopyWith<$Res>? get takeaway;

}
/// @nodoc
class _$SalesSectionDtoCopyWithImpl<$Res>
    implements $SalesSectionDtoCopyWith<$Res> {
  _$SalesSectionDtoCopyWithImpl(this._self, this._then);

  final SalesSectionDto _self;
  final $Res Function(SalesSectionDto) _then;

/// Create a copy of SalesSectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kpis = null,Object? coverTrend = null,Object? hourly = null,Object? takeaway = freezed,Object? badDebt = null,}) {
  return _then(_self.copyWith(
kpis: null == kpis ? _self.kpis : kpis // ignore: cast_nullable_to_non_nullable
as List<KpiTileDto>,coverTrend: null == coverTrend ? _self.coverTrend : coverTrend // ignore: cast_nullable_to_non_nullable
as List<CoverDayDto>,hourly: null == hourly ? _self.hourly : hourly // ignore: cast_nullable_to_non_nullable
as List<double>,takeaway: freezed == takeaway ? _self.takeaway : takeaway // ignore: cast_nullable_to_non_nullable
as TakeawaySplitDto?,badDebt: null == badDebt ? _self.badDebt : badDebt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of SalesSectionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TakeawaySplitDtoCopyWith<$Res>? get takeaway {
    if (_self.takeaway == null) {
    return null;
  }

  return $TakeawaySplitDtoCopyWith<$Res>(_self.takeaway!, (value) {
    return _then(_self.copyWith(takeaway: value));
  });
}
}


/// Adds pattern-matching-related methods to [SalesSectionDto].
extension SalesSectionDtoPatterns on SalesSectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SalesSectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SalesSectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SalesSectionDto value)  $default,){
final _that = this;
switch (_that) {
case _SalesSectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SalesSectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _SalesSectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<KpiTileDto> kpis,  List<CoverDayDto> coverTrend,  List<double> hourly,  TakeawaySplitDto? takeaway,  int badDebt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SalesSectionDto() when $default != null:
return $default(_that.kpis,_that.coverTrend,_that.hourly,_that.takeaway,_that.badDebt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<KpiTileDto> kpis,  List<CoverDayDto> coverTrend,  List<double> hourly,  TakeawaySplitDto? takeaway,  int badDebt)  $default,) {final _that = this;
switch (_that) {
case _SalesSectionDto():
return $default(_that.kpis,_that.coverTrend,_that.hourly,_that.takeaway,_that.badDebt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<KpiTileDto> kpis,  List<CoverDayDto> coverTrend,  List<double> hourly,  TakeawaySplitDto? takeaway,  int badDebt)?  $default,) {final _that = this;
switch (_that) {
case _SalesSectionDto() when $default != null:
return $default(_that.kpis,_that.coverTrend,_that.hourly,_that.takeaway,_that.badDebt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SalesSectionDto implements SalesSectionDto {
  const _SalesSectionDto({final  List<KpiTileDto> kpis = const <KpiTileDto>[], final  List<CoverDayDto> coverTrend = const <CoverDayDto>[], final  List<double> hourly = const <double>[], this.takeaway, this.badDebt = 0}): _kpis = kpis,_coverTrend = coverTrend,_hourly = hourly;
  factory _SalesSectionDto.fromJson(Map<String, dynamic> json) => _$SalesSectionDtoFromJson(json);

 final  List<KpiTileDto> _kpis;
@override@JsonKey() List<KpiTileDto> get kpis {
  if (_kpis is EqualUnmodifiableListView) return _kpis;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_kpis);
}

 final  List<CoverDayDto> _coverTrend;
@override@JsonKey() List<CoverDayDto> get coverTrend {
  if (_coverTrend is EqualUnmodifiableListView) return _coverTrend;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coverTrend);
}

 final  List<double> _hourly;
@override@JsonKey() List<double> get hourly {
  if (_hourly is EqualUnmodifiableListView) return _hourly;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hourly);
}

@override final  TakeawaySplitDto? takeaway;
/// [[Piutang]] given up on in this window — the one figure that crosses in
/// from [ReportsSnapshotDto.piutang] (ADR-0098). A tab written off weeks
/// after close is a real loss against revenue already booked, so it is
/// shown here rather than left in its own section where an owner reading
/// [kpis] would never meet it. Read-only: no KPI is net of it.
@override@JsonKey() final  int badDebt;

/// Create a copy of SalesSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SalesSectionDtoCopyWith<_SalesSectionDto> get copyWith => __$SalesSectionDtoCopyWithImpl<_SalesSectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SalesSectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SalesSectionDto&&const DeepCollectionEquality().equals(other._kpis, _kpis)&&const DeepCollectionEquality().equals(other._coverTrend, _coverTrend)&&const DeepCollectionEquality().equals(other._hourly, _hourly)&&(identical(other.takeaway, takeaway) || other.takeaway == takeaway)&&(identical(other.badDebt, badDebt) || other.badDebt == badDebt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_kpis),const DeepCollectionEquality().hash(_coverTrend),const DeepCollectionEquality().hash(_hourly),takeaway,badDebt);

@override
String toString() {
  return 'SalesSectionDto(kpis: $kpis, coverTrend: $coverTrend, hourly: $hourly, takeaway: $takeaway, badDebt: $badDebt)';
}


}

/// @nodoc
abstract mixin class _$SalesSectionDtoCopyWith<$Res> implements $SalesSectionDtoCopyWith<$Res> {
  factory _$SalesSectionDtoCopyWith(_SalesSectionDto value, $Res Function(_SalesSectionDto) _then) = __$SalesSectionDtoCopyWithImpl;
@override @useResult
$Res call({
 List<KpiTileDto> kpis, List<CoverDayDto> coverTrend, List<double> hourly, TakeawaySplitDto? takeaway, int badDebt
});


@override $TakeawaySplitDtoCopyWith<$Res>? get takeaway;

}
/// @nodoc
class __$SalesSectionDtoCopyWithImpl<$Res>
    implements _$SalesSectionDtoCopyWith<$Res> {
  __$SalesSectionDtoCopyWithImpl(this._self, this._then);

  final _SalesSectionDto _self;
  final $Res Function(_SalesSectionDto) _then;

/// Create a copy of SalesSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kpis = null,Object? coverTrend = null,Object? hourly = null,Object? takeaway = freezed,Object? badDebt = null,}) {
  return _then(_SalesSectionDto(
kpis: null == kpis ? _self._kpis : kpis // ignore: cast_nullable_to_non_nullable
as List<KpiTileDto>,coverTrend: null == coverTrend ? _self._coverTrend : coverTrend // ignore: cast_nullable_to_non_nullable
as List<CoverDayDto>,hourly: null == hourly ? _self._hourly : hourly // ignore: cast_nullable_to_non_nullable
as List<double>,takeaway: freezed == takeaway ? _self.takeaway : takeaway // ignore: cast_nullable_to_non_nullable
as TakeawaySplitDto?,badDebt: null == badDebt ? _self.badDebt : badDebt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of SalesSectionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TakeawaySplitDtoCopyWith<$Res>? get takeaway {
    if (_self.takeaway == null) {
    return null;
  }

  return $TakeawaySplitDtoCopyWith<$Res>(_self.takeaway!, (value) {
    return _then(_self.copyWith(takeaway: value));
  });
}
}


/// @nodoc
mixin _$TakeawaySplitDto {

 int get count; int get net; int get dineInCount; int get dineInNet;
/// Create a copy of TakeawaySplitDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TakeawaySplitDtoCopyWith<TakeawaySplitDto> get copyWith => _$TakeawaySplitDtoCopyWithImpl<TakeawaySplitDto>(this as TakeawaySplitDto, _$identity);

  /// Serializes this TakeawaySplitDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TakeawaySplitDto&&(identical(other.count, count) || other.count == count)&&(identical(other.net, net) || other.net == net)&&(identical(other.dineInCount, dineInCount) || other.dineInCount == dineInCount)&&(identical(other.dineInNet, dineInNet) || other.dineInNet == dineInNet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,count,net,dineInCount,dineInNet);

@override
String toString() {
  return 'TakeawaySplitDto(count: $count, net: $net, dineInCount: $dineInCount, dineInNet: $dineInNet)';
}


}

/// @nodoc
abstract mixin class $TakeawaySplitDtoCopyWith<$Res>  {
  factory $TakeawaySplitDtoCopyWith(TakeawaySplitDto value, $Res Function(TakeawaySplitDto) _then) = _$TakeawaySplitDtoCopyWithImpl;
@useResult
$Res call({
 int count, int net, int dineInCount, int dineInNet
});




}
/// @nodoc
class _$TakeawaySplitDtoCopyWithImpl<$Res>
    implements $TakeawaySplitDtoCopyWith<$Res> {
  _$TakeawaySplitDtoCopyWithImpl(this._self, this._then);

  final TakeawaySplitDto _self;
  final $Res Function(TakeawaySplitDto) _then;

/// Create a copy of TakeawaySplitDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? net = null,Object? dineInCount = null,Object? dineInNet = null,}) {
  return _then(_self.copyWith(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,dineInCount: null == dineInCount ? _self.dineInCount : dineInCount // ignore: cast_nullable_to_non_nullable
as int,dineInNet: null == dineInNet ? _self.dineInNet : dineInNet // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TakeawaySplitDto].
extension TakeawaySplitDtoPatterns on TakeawaySplitDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TakeawaySplitDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TakeawaySplitDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TakeawaySplitDto value)  $default,){
final _that = this;
switch (_that) {
case _TakeawaySplitDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TakeawaySplitDto value)?  $default,){
final _that = this;
switch (_that) {
case _TakeawaySplitDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  int net,  int dineInCount,  int dineInNet)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TakeawaySplitDto() when $default != null:
return $default(_that.count,_that.net,_that.dineInCount,_that.dineInNet);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  int net,  int dineInCount,  int dineInNet)  $default,) {final _that = this;
switch (_that) {
case _TakeawaySplitDto():
return $default(_that.count,_that.net,_that.dineInCount,_that.dineInNet);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  int net,  int dineInCount,  int dineInNet)?  $default,) {final _that = this;
switch (_that) {
case _TakeawaySplitDto() when $default != null:
return $default(_that.count,_that.net,_that.dineInCount,_that.dineInNet);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TakeawaySplitDto implements TakeawaySplitDto {
  const _TakeawaySplitDto({this.count = 0, this.net = 0, this.dineInCount = 0, this.dineInNet = 0});
  factory _TakeawaySplitDto.fromJson(Map<String, dynamic> json) => _$TakeawaySplitDtoFromJson(json);

@override@JsonKey() final  int count;
@override@JsonKey() final  int net;
@override@JsonKey() final  int dineInCount;
@override@JsonKey() final  int dineInNet;

/// Create a copy of TakeawaySplitDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TakeawaySplitDtoCopyWith<_TakeawaySplitDto> get copyWith => __$TakeawaySplitDtoCopyWithImpl<_TakeawaySplitDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TakeawaySplitDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TakeawaySplitDto&&(identical(other.count, count) || other.count == count)&&(identical(other.net, net) || other.net == net)&&(identical(other.dineInCount, dineInCount) || other.dineInCount == dineInCount)&&(identical(other.dineInNet, dineInNet) || other.dineInNet == dineInNet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,count,net,dineInCount,dineInNet);

@override
String toString() {
  return 'TakeawaySplitDto(count: $count, net: $net, dineInCount: $dineInCount, dineInNet: $dineInNet)';
}


}

/// @nodoc
abstract mixin class _$TakeawaySplitDtoCopyWith<$Res> implements $TakeawaySplitDtoCopyWith<$Res> {
  factory _$TakeawaySplitDtoCopyWith(_TakeawaySplitDto value, $Res Function(_TakeawaySplitDto) _then) = __$TakeawaySplitDtoCopyWithImpl;
@override @useResult
$Res call({
 int count, int net, int dineInCount, int dineInNet
});




}
/// @nodoc
class __$TakeawaySplitDtoCopyWithImpl<$Res>
    implements _$TakeawaySplitDtoCopyWith<$Res> {
  __$TakeawaySplitDtoCopyWithImpl(this._self, this._then);

  final _TakeawaySplitDto _self;
  final $Res Function(_TakeawaySplitDto) _then;

/// Create a copy of TakeawaySplitDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? net = null,Object? dineInCount = null,Object? dineInNet = null,}) {
  return _then(_TakeawaySplitDto(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,dineInCount: null == dineInCount ? _self.dineInCount : dineInCount // ignore: cast_nullable_to_non_nullable
as int,dineInNet: null == dineInNet ? _self.dineInNet : dineInNet // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CoverDayDto {

/// ISO weekday, 1 = Monday. Spelled by [formatWeekdayShort] at read time.
 int get dow; int get thisWeek; int get lastWeek;
/// Create a copy of CoverDayDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoverDayDtoCopyWith<CoverDayDto> get copyWith => _$CoverDayDtoCopyWithImpl<CoverDayDto>(this as CoverDayDto, _$identity);

  /// Serializes this CoverDayDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoverDayDto&&(identical(other.dow, dow) || other.dow == dow)&&(identical(other.thisWeek, thisWeek) || other.thisWeek == thisWeek)&&(identical(other.lastWeek, lastWeek) || other.lastWeek == lastWeek));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dow,thisWeek,lastWeek);

@override
String toString() {
  return 'CoverDayDto(dow: $dow, thisWeek: $thisWeek, lastWeek: $lastWeek)';
}


}

/// @nodoc
abstract mixin class $CoverDayDtoCopyWith<$Res>  {
  factory $CoverDayDtoCopyWith(CoverDayDto value, $Res Function(CoverDayDto) _then) = _$CoverDayDtoCopyWithImpl;
@useResult
$Res call({
 int dow, int thisWeek, int lastWeek
});




}
/// @nodoc
class _$CoverDayDtoCopyWithImpl<$Res>
    implements $CoverDayDtoCopyWith<$Res> {
  _$CoverDayDtoCopyWithImpl(this._self, this._then);

  final CoverDayDto _self;
  final $Res Function(CoverDayDto) _then;

/// Create a copy of CoverDayDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dow = null,Object? thisWeek = null,Object? lastWeek = null,}) {
  return _then(_self.copyWith(
dow: null == dow ? _self.dow : dow // ignore: cast_nullable_to_non_nullable
as int,thisWeek: null == thisWeek ? _self.thisWeek : thisWeek // ignore: cast_nullable_to_non_nullable
as int,lastWeek: null == lastWeek ? _self.lastWeek : lastWeek // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CoverDayDto].
extension CoverDayDtoPatterns on CoverDayDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoverDayDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoverDayDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoverDayDto value)  $default,){
final _that = this;
switch (_that) {
case _CoverDayDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoverDayDto value)?  $default,){
final _that = this;
switch (_that) {
case _CoverDayDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int dow,  int thisWeek,  int lastWeek)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoverDayDto() when $default != null:
return $default(_that.dow,_that.thisWeek,_that.lastWeek);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int dow,  int thisWeek,  int lastWeek)  $default,) {final _that = this;
switch (_that) {
case _CoverDayDto():
return $default(_that.dow,_that.thisWeek,_that.lastWeek);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int dow,  int thisWeek,  int lastWeek)?  $default,) {final _that = this;
switch (_that) {
case _CoverDayDto() when $default != null:
return $default(_that.dow,_that.thisWeek,_that.lastWeek);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoverDayDto implements CoverDayDto {
  const _CoverDayDto({this.dow = 1, required this.thisWeek, required this.lastWeek});
  factory _CoverDayDto.fromJson(Map<String, dynamic> json) => _$CoverDayDtoFromJson(json);

/// ISO weekday, 1 = Monday. Spelled by [formatWeekdayShort] at read time.
@override@JsonKey() final  int dow;
@override final  int thisWeek;
@override final  int lastWeek;

/// Create a copy of CoverDayDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoverDayDtoCopyWith<_CoverDayDto> get copyWith => __$CoverDayDtoCopyWithImpl<_CoverDayDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoverDayDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoverDayDto&&(identical(other.dow, dow) || other.dow == dow)&&(identical(other.thisWeek, thisWeek) || other.thisWeek == thisWeek)&&(identical(other.lastWeek, lastWeek) || other.lastWeek == lastWeek));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dow,thisWeek,lastWeek);

@override
String toString() {
  return 'CoverDayDto(dow: $dow, thisWeek: $thisWeek, lastWeek: $lastWeek)';
}


}

/// @nodoc
abstract mixin class _$CoverDayDtoCopyWith<$Res> implements $CoverDayDtoCopyWith<$Res> {
  factory _$CoverDayDtoCopyWith(_CoverDayDto value, $Res Function(_CoverDayDto) _then) = __$CoverDayDtoCopyWithImpl;
@override @useResult
$Res call({
 int dow, int thisWeek, int lastWeek
});




}
/// @nodoc
class __$CoverDayDtoCopyWithImpl<$Res>
    implements _$CoverDayDtoCopyWith<$Res> {
  __$CoverDayDtoCopyWithImpl(this._self, this._then);

  final _CoverDayDto _self;
  final $Res Function(_CoverDayDto) _then;

/// Create a copy of CoverDayDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dow = null,Object? thisWeek = null,Object? lastWeek = null,}) {
  return _then(_CoverDayDto(
dow: null == dow ? _self.dow : dow // ignore: cast_nullable_to_non_nullable
as int,thisWeek: null == thisWeek ? _self.thisWeek : thisWeek // ignore: cast_nullable_to_non_nullable
as int,lastWeek: null == lastWeek ? _self.lastWeek : lastWeek // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StaffSectionDto {

 List<StaffRowDto> get rows; List<StaffUpsellDto> get upsell;
/// Create a copy of StaffSectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffSectionDtoCopyWith<StaffSectionDto> get copyWith => _$StaffSectionDtoCopyWithImpl<StaffSectionDto>(this as StaffSectionDto, _$identity);

  /// Serializes this StaffSectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffSectionDto&&const DeepCollectionEquality().equals(other.rows, rows)&&const DeepCollectionEquality().equals(other.upsell, upsell));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),const DeepCollectionEquality().hash(upsell));

@override
String toString() {
  return 'StaffSectionDto(rows: $rows, upsell: $upsell)';
}


}

/// @nodoc
abstract mixin class $StaffSectionDtoCopyWith<$Res>  {
  factory $StaffSectionDtoCopyWith(StaffSectionDto value, $Res Function(StaffSectionDto) _then) = _$StaffSectionDtoCopyWithImpl;
@useResult
$Res call({
 List<StaffRowDto> rows, List<StaffUpsellDto> upsell
});




}
/// @nodoc
class _$StaffSectionDtoCopyWithImpl<$Res>
    implements $StaffSectionDtoCopyWith<$Res> {
  _$StaffSectionDtoCopyWithImpl(this._self, this._then);

  final StaffSectionDto _self;
  final $Res Function(StaffSectionDto) _then;

/// Create a copy of StaffSectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? upsell = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<StaffRowDto>,upsell: null == upsell ? _self.upsell : upsell // ignore: cast_nullable_to_non_nullable
as List<StaffUpsellDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffSectionDto].
extension StaffSectionDtoPatterns on StaffSectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffSectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffSectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffSectionDto value)  $default,){
final _that = this;
switch (_that) {
case _StaffSectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffSectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _StaffSectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<StaffRowDto> rows,  List<StaffUpsellDto> upsell)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffSectionDto() when $default != null:
return $default(_that.rows,_that.upsell);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<StaffRowDto> rows,  List<StaffUpsellDto> upsell)  $default,) {final _that = this;
switch (_that) {
case _StaffSectionDto():
return $default(_that.rows,_that.upsell);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<StaffRowDto> rows,  List<StaffUpsellDto> upsell)?  $default,) {final _that = this;
switch (_that) {
case _StaffSectionDto() when $default != null:
return $default(_that.rows,_that.upsell);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffSectionDto implements StaffSectionDto {
  const _StaffSectionDto({final  List<StaffRowDto> rows = const <StaffRowDto>[], final  List<StaffUpsellDto> upsell = const <StaffUpsellDto>[]}): _rows = rows,_upsell = upsell;
  factory _StaffSectionDto.fromJson(Map<String, dynamic> json) => _$StaffSectionDtoFromJson(json);

 final  List<StaffRowDto> _rows;
@override@JsonKey() List<StaffRowDto> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

 final  List<StaffUpsellDto> _upsell;
@override@JsonKey() List<StaffUpsellDto> get upsell {
  if (_upsell is EqualUnmodifiableListView) return _upsell;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_upsell);
}


/// Create a copy of StaffSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffSectionDtoCopyWith<_StaffSectionDto> get copyWith => __$StaffSectionDtoCopyWithImpl<_StaffSectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffSectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffSectionDto&&const DeepCollectionEquality().equals(other._rows, _rows)&&const DeepCollectionEquality().equals(other._upsell, _upsell));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),const DeepCollectionEquality().hash(_upsell));

@override
String toString() {
  return 'StaffSectionDto(rows: $rows, upsell: $upsell)';
}


}

/// @nodoc
abstract mixin class _$StaffSectionDtoCopyWith<$Res> implements $StaffSectionDtoCopyWith<$Res> {
  factory _$StaffSectionDtoCopyWith(_StaffSectionDto value, $Res Function(_StaffSectionDto) _then) = __$StaffSectionDtoCopyWithImpl;
@override @useResult
$Res call({
 List<StaffRowDto> rows, List<StaffUpsellDto> upsell
});




}
/// @nodoc
class __$StaffSectionDtoCopyWithImpl<$Res>
    implements _$StaffSectionDtoCopyWith<$Res> {
  __$StaffSectionDtoCopyWithImpl(this._self, this._then);

  final _StaffSectionDto _self;
  final $Res Function(_StaffSectionDto) _then;

/// Create a copy of StaffSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? upsell = null,}) {
  return _then(_StaffSectionDto(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<StaffRowDto>,upsell: null == upsell ? _self._upsell : upsell // ignore: cast_nullable_to_non_nullable
as List<StaffUpsellDto>,
  ));
}


}


/// @nodoc
mixin _$StaffRowDto {

 String get id; String get name; int get covers; int get items; int get avgTicket; double get voidPct; int get net; int get sessions;
/// Create a copy of StaffRowDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffRowDtoCopyWith<StaffRowDto> get copyWith => _$StaffRowDtoCopyWithImpl<StaffRowDto>(this as StaffRowDto, _$identity);

  /// Serializes this StaffRowDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffRowDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.covers, covers) || other.covers == covers)&&(identical(other.items, items) || other.items == items)&&(identical(other.avgTicket, avgTicket) || other.avgTicket == avgTicket)&&(identical(other.voidPct, voidPct) || other.voidPct == voidPct)&&(identical(other.net, net) || other.net == net)&&(identical(other.sessions, sessions) || other.sessions == sessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,covers,items,avgTicket,voidPct,net,sessions);

@override
String toString() {
  return 'StaffRowDto(id: $id, name: $name, covers: $covers, items: $items, avgTicket: $avgTicket, voidPct: $voidPct, net: $net, sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class $StaffRowDtoCopyWith<$Res>  {
  factory $StaffRowDtoCopyWith(StaffRowDto value, $Res Function(StaffRowDto) _then) = _$StaffRowDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, int covers, int items, int avgTicket, double voidPct, int net, int sessions
});




}
/// @nodoc
class _$StaffRowDtoCopyWithImpl<$Res>
    implements $StaffRowDtoCopyWith<$Res> {
  _$StaffRowDtoCopyWithImpl(this._self, this._then);

  final StaffRowDto _self;
  final $Res Function(StaffRowDto) _then;

/// Create a copy of StaffRowDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? covers = null,Object? items = null,Object? avgTicket = null,Object? voidPct = null,Object? net = null,Object? sessions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,covers: null == covers ? _self.covers : covers // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as int,avgTicket: null == avgTicket ? _self.avgTicket : avgTicket // ignore: cast_nullable_to_non_nullable
as int,voidPct: null == voidPct ? _self.voidPct : voidPct // ignore: cast_nullable_to_non_nullable
as double,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffRowDto].
extension StaffRowDtoPatterns on StaffRowDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffRowDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffRowDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffRowDto value)  $default,){
final _that = this;
switch (_that) {
case _StaffRowDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffRowDto value)?  $default,){
final _that = this;
switch (_that) {
case _StaffRowDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int covers,  int items,  int avgTicket,  double voidPct,  int net,  int sessions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffRowDto() when $default != null:
return $default(_that.id,_that.name,_that.covers,_that.items,_that.avgTicket,_that.voidPct,_that.net,_that.sessions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int covers,  int items,  int avgTicket,  double voidPct,  int net,  int sessions)  $default,) {final _that = this;
switch (_that) {
case _StaffRowDto():
return $default(_that.id,_that.name,_that.covers,_that.items,_that.avgTicket,_that.voidPct,_that.net,_that.sessions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int covers,  int items,  int avgTicket,  double voidPct,  int net,  int sessions)?  $default,) {final _that = this;
switch (_that) {
case _StaffRowDto() when $default != null:
return $default(_that.id,_that.name,_that.covers,_that.items,_that.avgTicket,_that.voidPct,_that.net,_that.sessions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffRowDto implements StaffRowDto {
  const _StaffRowDto({required this.id, required this.name, this.covers = 0, this.items = 0, this.avgTicket = 0, this.voidPct = 0.0, this.net = 0, this.sessions = 0});
  factory _StaffRowDto.fromJson(Map<String, dynamic> json) => _$StaffRowDtoFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  int covers;
@override@JsonKey() final  int items;
@override@JsonKey() final  int avgTicket;
@override@JsonKey() final  double voidPct;
@override@JsonKey() final  int net;
@override@JsonKey() final  int sessions;

/// Create a copy of StaffRowDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffRowDtoCopyWith<_StaffRowDto> get copyWith => __$StaffRowDtoCopyWithImpl<_StaffRowDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffRowDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffRowDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.covers, covers) || other.covers == covers)&&(identical(other.items, items) || other.items == items)&&(identical(other.avgTicket, avgTicket) || other.avgTicket == avgTicket)&&(identical(other.voidPct, voidPct) || other.voidPct == voidPct)&&(identical(other.net, net) || other.net == net)&&(identical(other.sessions, sessions) || other.sessions == sessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,covers,items,avgTicket,voidPct,net,sessions);

@override
String toString() {
  return 'StaffRowDto(id: $id, name: $name, covers: $covers, items: $items, avgTicket: $avgTicket, voidPct: $voidPct, net: $net, sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class _$StaffRowDtoCopyWith<$Res> implements $StaffRowDtoCopyWith<$Res> {
  factory _$StaffRowDtoCopyWith(_StaffRowDto value, $Res Function(_StaffRowDto) _then) = __$StaffRowDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int covers, int items, int avgTicket, double voidPct, int net, int sessions
});




}
/// @nodoc
class __$StaffRowDtoCopyWithImpl<$Res>
    implements _$StaffRowDtoCopyWith<$Res> {
  __$StaffRowDtoCopyWithImpl(this._self, this._then);

  final _StaffRowDto _self;
  final $Res Function(_StaffRowDto) _then;

/// Create a copy of StaffRowDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? covers = null,Object? items = null,Object? avgTicket = null,Object? voidPct = null,Object? net = null,Object? sessions = null,}) {
  return _then(_StaffRowDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,covers: null == covers ? _self.covers : covers // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as int,avgTicket: null == avgTicket ? _self.avgTicket : avgTicket // ignore: cast_nullable_to_non_nullable
as int,voidPct: null == voidPct ? _self.voidPct : voidPct // ignore: cast_nullable_to_non_nullable
as double,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StaffUpsellDto {

 String get id; String get name; double get rate;
/// Create a copy of StaffUpsellDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffUpsellDtoCopyWith<StaffUpsellDto> get copyWith => _$StaffUpsellDtoCopyWithImpl<StaffUpsellDto>(this as StaffUpsellDto, _$identity);

  /// Serializes this StaffUpsellDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffUpsellDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.rate, rate) || other.rate == rate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,rate);

@override
String toString() {
  return 'StaffUpsellDto(id: $id, name: $name, rate: $rate)';
}


}

/// @nodoc
abstract mixin class $StaffUpsellDtoCopyWith<$Res>  {
  factory $StaffUpsellDtoCopyWith(StaffUpsellDto value, $Res Function(StaffUpsellDto) _then) = _$StaffUpsellDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, double rate
});




}
/// @nodoc
class _$StaffUpsellDtoCopyWithImpl<$Res>
    implements $StaffUpsellDtoCopyWith<$Res> {
  _$StaffUpsellDtoCopyWithImpl(this._self, this._then);

  final StaffUpsellDto _self;
  final $Res Function(StaffUpsellDto) _then;

/// Create a copy of StaffUpsellDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? rate = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffUpsellDto].
extension StaffUpsellDtoPatterns on StaffUpsellDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffUpsellDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffUpsellDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffUpsellDto value)  $default,){
final _that = this;
switch (_that) {
case _StaffUpsellDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffUpsellDto value)?  $default,){
final _that = this;
switch (_that) {
case _StaffUpsellDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double rate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffUpsellDto() when $default != null:
return $default(_that.id,_that.name,_that.rate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double rate)  $default,) {final _that = this;
switch (_that) {
case _StaffUpsellDto():
return $default(_that.id,_that.name,_that.rate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double rate)?  $default,) {final _that = this;
switch (_that) {
case _StaffUpsellDto() when $default != null:
return $default(_that.id,_that.name,_that.rate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffUpsellDto implements StaffUpsellDto {
  const _StaffUpsellDto({required this.id, required this.name, this.rate = 0.0});
  factory _StaffUpsellDto.fromJson(Map<String, dynamic> json) => _$StaffUpsellDtoFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  double rate;

/// Create a copy of StaffUpsellDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffUpsellDtoCopyWith<_StaffUpsellDto> get copyWith => __$StaffUpsellDtoCopyWithImpl<_StaffUpsellDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffUpsellDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffUpsellDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.rate, rate) || other.rate == rate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,rate);

@override
String toString() {
  return 'StaffUpsellDto(id: $id, name: $name, rate: $rate)';
}


}

/// @nodoc
abstract mixin class _$StaffUpsellDtoCopyWith<$Res> implements $StaffUpsellDtoCopyWith<$Res> {
  factory _$StaffUpsellDtoCopyWith(_StaffUpsellDto value, $Res Function(_StaffUpsellDto) _then) = __$StaffUpsellDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double rate
});




}
/// @nodoc
class __$StaffUpsellDtoCopyWithImpl<$Res>
    implements _$StaffUpsellDtoCopyWith<$Res> {
  __$StaffUpsellDtoCopyWithImpl(this._self, this._then);

  final _StaffUpsellDto _self;
  final $Res Function(_StaffUpsellDto) _then;

/// Create a copy of StaffUpsellDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? rate = null,}) {
  return _then(_StaffUpsellDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$MenuSectionDto {

 List<MenuItemRowDto> get top; List<MenuItemRowDto> get slow; List<ModifierAttachDto> get modifierAttach; List<CategoryShareDto> get categoryMix; List<MatrixItemDto> get matrix; List<BasketPairDto> get basketPairs;
/// Create a copy of MenuSectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuSectionDtoCopyWith<MenuSectionDto> get copyWith => _$MenuSectionDtoCopyWithImpl<MenuSectionDto>(this as MenuSectionDto, _$identity);

  /// Serializes this MenuSectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuSectionDto&&const DeepCollectionEquality().equals(other.top, top)&&const DeepCollectionEquality().equals(other.slow, slow)&&const DeepCollectionEquality().equals(other.modifierAttach, modifierAttach)&&const DeepCollectionEquality().equals(other.categoryMix, categoryMix)&&const DeepCollectionEquality().equals(other.matrix, matrix)&&const DeepCollectionEquality().equals(other.basketPairs, basketPairs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(top),const DeepCollectionEquality().hash(slow),const DeepCollectionEquality().hash(modifierAttach),const DeepCollectionEquality().hash(categoryMix),const DeepCollectionEquality().hash(matrix),const DeepCollectionEquality().hash(basketPairs));

@override
String toString() {
  return 'MenuSectionDto(top: $top, slow: $slow, modifierAttach: $modifierAttach, categoryMix: $categoryMix, matrix: $matrix, basketPairs: $basketPairs)';
}


}

/// @nodoc
abstract mixin class $MenuSectionDtoCopyWith<$Res>  {
  factory $MenuSectionDtoCopyWith(MenuSectionDto value, $Res Function(MenuSectionDto) _then) = _$MenuSectionDtoCopyWithImpl;
@useResult
$Res call({
 List<MenuItemRowDto> top, List<MenuItemRowDto> slow, List<ModifierAttachDto> modifierAttach, List<CategoryShareDto> categoryMix, List<MatrixItemDto> matrix, List<BasketPairDto> basketPairs
});




}
/// @nodoc
class _$MenuSectionDtoCopyWithImpl<$Res>
    implements $MenuSectionDtoCopyWith<$Res> {
  _$MenuSectionDtoCopyWithImpl(this._self, this._then);

  final MenuSectionDto _self;
  final $Res Function(MenuSectionDto) _then;

/// Create a copy of MenuSectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? top = null,Object? slow = null,Object? modifierAttach = null,Object? categoryMix = null,Object? matrix = null,Object? basketPairs = null,}) {
  return _then(_self.copyWith(
top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as List<MenuItemRowDto>,slow: null == slow ? _self.slow : slow // ignore: cast_nullable_to_non_nullable
as List<MenuItemRowDto>,modifierAttach: null == modifierAttach ? _self.modifierAttach : modifierAttach // ignore: cast_nullable_to_non_nullable
as List<ModifierAttachDto>,categoryMix: null == categoryMix ? _self.categoryMix : categoryMix // ignore: cast_nullable_to_non_nullable
as List<CategoryShareDto>,matrix: null == matrix ? _self.matrix : matrix // ignore: cast_nullable_to_non_nullable
as List<MatrixItemDto>,basketPairs: null == basketPairs ? _self.basketPairs : basketPairs // ignore: cast_nullable_to_non_nullable
as List<BasketPairDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuSectionDto].
extension MenuSectionDtoPatterns on MenuSectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuSectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuSectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuSectionDto value)  $default,){
final _that = this;
switch (_that) {
case _MenuSectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuSectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _MenuSectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MenuItemRowDto> top,  List<MenuItemRowDto> slow,  List<ModifierAttachDto> modifierAttach,  List<CategoryShareDto> categoryMix,  List<MatrixItemDto> matrix,  List<BasketPairDto> basketPairs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuSectionDto() when $default != null:
return $default(_that.top,_that.slow,_that.modifierAttach,_that.categoryMix,_that.matrix,_that.basketPairs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MenuItemRowDto> top,  List<MenuItemRowDto> slow,  List<ModifierAttachDto> modifierAttach,  List<CategoryShareDto> categoryMix,  List<MatrixItemDto> matrix,  List<BasketPairDto> basketPairs)  $default,) {final _that = this;
switch (_that) {
case _MenuSectionDto():
return $default(_that.top,_that.slow,_that.modifierAttach,_that.categoryMix,_that.matrix,_that.basketPairs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MenuItemRowDto> top,  List<MenuItemRowDto> slow,  List<ModifierAttachDto> modifierAttach,  List<CategoryShareDto> categoryMix,  List<MatrixItemDto> matrix,  List<BasketPairDto> basketPairs)?  $default,) {final _that = this;
switch (_that) {
case _MenuSectionDto() when $default != null:
return $default(_that.top,_that.slow,_that.modifierAttach,_that.categoryMix,_that.matrix,_that.basketPairs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuSectionDto implements MenuSectionDto {
  const _MenuSectionDto({final  List<MenuItemRowDto> top = const <MenuItemRowDto>[], final  List<MenuItemRowDto> slow = const <MenuItemRowDto>[], final  List<ModifierAttachDto> modifierAttach = const <ModifierAttachDto>[], final  List<CategoryShareDto> categoryMix = const <CategoryShareDto>[], final  List<MatrixItemDto> matrix = const <MatrixItemDto>[], final  List<BasketPairDto> basketPairs = const <BasketPairDto>[]}): _top = top,_slow = slow,_modifierAttach = modifierAttach,_categoryMix = categoryMix,_matrix = matrix,_basketPairs = basketPairs;
  factory _MenuSectionDto.fromJson(Map<String, dynamic> json) => _$MenuSectionDtoFromJson(json);

 final  List<MenuItemRowDto> _top;
@override@JsonKey() List<MenuItemRowDto> get top {
  if (_top is EqualUnmodifiableListView) return _top;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_top);
}

 final  List<MenuItemRowDto> _slow;
@override@JsonKey() List<MenuItemRowDto> get slow {
  if (_slow is EqualUnmodifiableListView) return _slow;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slow);
}

 final  List<ModifierAttachDto> _modifierAttach;
@override@JsonKey() List<ModifierAttachDto> get modifierAttach {
  if (_modifierAttach is EqualUnmodifiableListView) return _modifierAttach;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modifierAttach);
}

 final  List<CategoryShareDto> _categoryMix;
@override@JsonKey() List<CategoryShareDto> get categoryMix {
  if (_categoryMix is EqualUnmodifiableListView) return _categoryMix;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryMix);
}

 final  List<MatrixItemDto> _matrix;
@override@JsonKey() List<MatrixItemDto> get matrix {
  if (_matrix is EqualUnmodifiableListView) return _matrix;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matrix);
}

 final  List<BasketPairDto> _basketPairs;
@override@JsonKey() List<BasketPairDto> get basketPairs {
  if (_basketPairs is EqualUnmodifiableListView) return _basketPairs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_basketPairs);
}


/// Create a copy of MenuSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuSectionDtoCopyWith<_MenuSectionDto> get copyWith => __$MenuSectionDtoCopyWithImpl<_MenuSectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuSectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuSectionDto&&const DeepCollectionEquality().equals(other._top, _top)&&const DeepCollectionEquality().equals(other._slow, _slow)&&const DeepCollectionEquality().equals(other._modifierAttach, _modifierAttach)&&const DeepCollectionEquality().equals(other._categoryMix, _categoryMix)&&const DeepCollectionEquality().equals(other._matrix, _matrix)&&const DeepCollectionEquality().equals(other._basketPairs, _basketPairs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_top),const DeepCollectionEquality().hash(_slow),const DeepCollectionEquality().hash(_modifierAttach),const DeepCollectionEquality().hash(_categoryMix),const DeepCollectionEquality().hash(_matrix),const DeepCollectionEquality().hash(_basketPairs));

@override
String toString() {
  return 'MenuSectionDto(top: $top, slow: $slow, modifierAttach: $modifierAttach, categoryMix: $categoryMix, matrix: $matrix, basketPairs: $basketPairs)';
}


}

/// @nodoc
abstract mixin class _$MenuSectionDtoCopyWith<$Res> implements $MenuSectionDtoCopyWith<$Res> {
  factory _$MenuSectionDtoCopyWith(_MenuSectionDto value, $Res Function(_MenuSectionDto) _then) = __$MenuSectionDtoCopyWithImpl;
@override @useResult
$Res call({
 List<MenuItemRowDto> top, List<MenuItemRowDto> slow, List<ModifierAttachDto> modifierAttach, List<CategoryShareDto> categoryMix, List<MatrixItemDto> matrix, List<BasketPairDto> basketPairs
});




}
/// @nodoc
class __$MenuSectionDtoCopyWithImpl<$Res>
    implements _$MenuSectionDtoCopyWith<$Res> {
  __$MenuSectionDtoCopyWithImpl(this._self, this._then);

  final _MenuSectionDto _self;
  final $Res Function(_MenuSectionDto) _then;

/// Create a copy of MenuSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? top = null,Object? slow = null,Object? modifierAttach = null,Object? categoryMix = null,Object? matrix = null,Object? basketPairs = null,}) {
  return _then(_MenuSectionDto(
top: null == top ? _self._top : top // ignore: cast_nullable_to_non_nullable
as List<MenuItemRowDto>,slow: null == slow ? _self._slow : slow // ignore: cast_nullable_to_non_nullable
as List<MenuItemRowDto>,modifierAttach: null == modifierAttach ? _self._modifierAttach : modifierAttach // ignore: cast_nullable_to_non_nullable
as List<ModifierAttachDto>,categoryMix: null == categoryMix ? _self._categoryMix : categoryMix // ignore: cast_nullable_to_non_nullable
as List<CategoryShareDto>,matrix: null == matrix ? _self._matrix : matrix // ignore: cast_nullable_to_non_nullable
as List<MatrixItemDto>,basketPairs: null == basketPairs ? _self._basketPairs : basketPairs // ignore: cast_nullable_to_non_nullable
as List<BasketPairDto>,
  ));
}


}


/// @nodoc
mixin _$MenuItemRowDto {

 String get itemId; String get name; int get qty; int get revenue; int get marginPct; double get fill;
/// Create a copy of MenuItemRowDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuItemRowDtoCopyWith<MenuItemRowDto> get copyWith => _$MenuItemRowDtoCopyWithImpl<MenuItemRowDto>(this as MenuItemRowDto, _$identity);

  /// Serializes this MenuItemRowDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuItemRowDto&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.marginPct, marginPct) || other.marginPct == marginPct)&&(identical(other.fill, fill) || other.fill == fill));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,name,qty,revenue,marginPct,fill);

@override
String toString() {
  return 'MenuItemRowDto(itemId: $itemId, name: $name, qty: $qty, revenue: $revenue, marginPct: $marginPct, fill: $fill)';
}


}

/// @nodoc
abstract mixin class $MenuItemRowDtoCopyWith<$Res>  {
  factory $MenuItemRowDtoCopyWith(MenuItemRowDto value, $Res Function(MenuItemRowDto) _then) = _$MenuItemRowDtoCopyWithImpl;
@useResult
$Res call({
 String itemId, String name, int qty, int revenue, int marginPct, double fill
});




}
/// @nodoc
class _$MenuItemRowDtoCopyWithImpl<$Res>
    implements $MenuItemRowDtoCopyWith<$Res> {
  _$MenuItemRowDtoCopyWithImpl(this._self, this._then);

  final MenuItemRowDto _self;
  final $Res Function(MenuItemRowDto) _then;

/// Create a copy of MenuItemRowDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? name = null,Object? qty = null,Object? revenue = null,Object? marginPct = null,Object? fill = null,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,marginPct: null == marginPct ? _self.marginPct : marginPct // ignore: cast_nullable_to_non_nullable
as int,fill: null == fill ? _self.fill : fill // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuItemRowDto].
extension MenuItemRowDtoPatterns on MenuItemRowDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuItemRowDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuItemRowDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuItemRowDto value)  $default,){
final _that = this;
switch (_that) {
case _MenuItemRowDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuItemRowDto value)?  $default,){
final _that = this;
switch (_that) {
case _MenuItemRowDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  String name,  int qty,  int revenue,  int marginPct,  double fill)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuItemRowDto() when $default != null:
return $default(_that.itemId,_that.name,_that.qty,_that.revenue,_that.marginPct,_that.fill);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  String name,  int qty,  int revenue,  int marginPct,  double fill)  $default,) {final _that = this;
switch (_that) {
case _MenuItemRowDto():
return $default(_that.itemId,_that.name,_that.qty,_that.revenue,_that.marginPct,_that.fill);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  String name,  int qty,  int revenue,  int marginPct,  double fill)?  $default,) {final _that = this;
switch (_that) {
case _MenuItemRowDto() when $default != null:
return $default(_that.itemId,_that.name,_that.qty,_that.revenue,_that.marginPct,_that.fill);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuItemRowDto implements MenuItemRowDto {
  const _MenuItemRowDto({required this.itemId, required this.name, this.qty = 0, this.revenue = 0, this.marginPct = 0, this.fill = 0.0});
  factory _MenuItemRowDto.fromJson(Map<String, dynamic> json) => _$MenuItemRowDtoFromJson(json);

@override final  String itemId;
@override final  String name;
@override@JsonKey() final  int qty;
@override@JsonKey() final  int revenue;
@override@JsonKey() final  int marginPct;
@override@JsonKey() final  double fill;

/// Create a copy of MenuItemRowDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuItemRowDtoCopyWith<_MenuItemRowDto> get copyWith => __$MenuItemRowDtoCopyWithImpl<_MenuItemRowDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuItemRowDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuItemRowDto&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.marginPct, marginPct) || other.marginPct == marginPct)&&(identical(other.fill, fill) || other.fill == fill));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,name,qty,revenue,marginPct,fill);

@override
String toString() {
  return 'MenuItemRowDto(itemId: $itemId, name: $name, qty: $qty, revenue: $revenue, marginPct: $marginPct, fill: $fill)';
}


}

/// @nodoc
abstract mixin class _$MenuItemRowDtoCopyWith<$Res> implements $MenuItemRowDtoCopyWith<$Res> {
  factory _$MenuItemRowDtoCopyWith(_MenuItemRowDto value, $Res Function(_MenuItemRowDto) _then) = __$MenuItemRowDtoCopyWithImpl;
@override @useResult
$Res call({
 String itemId, String name, int qty, int revenue, int marginPct, double fill
});




}
/// @nodoc
class __$MenuItemRowDtoCopyWithImpl<$Res>
    implements _$MenuItemRowDtoCopyWith<$Res> {
  __$MenuItemRowDtoCopyWithImpl(this._self, this._then);

  final _MenuItemRowDto _self;
  final $Res Function(_MenuItemRowDto) _then;

/// Create a copy of MenuItemRowDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? name = null,Object? qty = null,Object? revenue = null,Object? marginPct = null,Object? fill = null,}) {
  return _then(_MenuItemRowDto(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,marginPct: null == marginPct ? _self.marginPct : marginPct // ignore: cast_nullable_to_non_nullable
as int,fill: null == fill ? _self.fill : fill // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ModifierAttachDto {

 String get group; double get rate;
/// Create a copy of ModifierAttachDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModifierAttachDtoCopyWith<ModifierAttachDto> get copyWith => _$ModifierAttachDtoCopyWithImpl<ModifierAttachDto>(this as ModifierAttachDto, _$identity);

  /// Serializes this ModifierAttachDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModifierAttachDto&&(identical(other.group, group) || other.group == group)&&(identical(other.rate, rate) || other.rate == rate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,group,rate);

@override
String toString() {
  return 'ModifierAttachDto(group: $group, rate: $rate)';
}


}

/// @nodoc
abstract mixin class $ModifierAttachDtoCopyWith<$Res>  {
  factory $ModifierAttachDtoCopyWith(ModifierAttachDto value, $Res Function(ModifierAttachDto) _then) = _$ModifierAttachDtoCopyWithImpl;
@useResult
$Res call({
 String group, double rate
});




}
/// @nodoc
class _$ModifierAttachDtoCopyWithImpl<$Res>
    implements $ModifierAttachDtoCopyWith<$Res> {
  _$ModifierAttachDtoCopyWithImpl(this._self, this._then);

  final ModifierAttachDto _self;
  final $Res Function(ModifierAttachDto) _then;

/// Create a copy of ModifierAttachDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? group = null,Object? rate = null,}) {
  return _then(_self.copyWith(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ModifierAttachDto].
extension ModifierAttachDtoPatterns on ModifierAttachDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModifierAttachDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModifierAttachDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModifierAttachDto value)  $default,){
final _that = this;
switch (_that) {
case _ModifierAttachDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModifierAttachDto value)?  $default,){
final _that = this;
switch (_that) {
case _ModifierAttachDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String group,  double rate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModifierAttachDto() when $default != null:
return $default(_that.group,_that.rate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String group,  double rate)  $default,) {final _that = this;
switch (_that) {
case _ModifierAttachDto():
return $default(_that.group,_that.rate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String group,  double rate)?  $default,) {final _that = this;
switch (_that) {
case _ModifierAttachDto() when $default != null:
return $default(_that.group,_that.rate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModifierAttachDto implements ModifierAttachDto {
  const _ModifierAttachDto({required this.group, this.rate = 0.0});
  factory _ModifierAttachDto.fromJson(Map<String, dynamic> json) => _$ModifierAttachDtoFromJson(json);

@override final  String group;
@override@JsonKey() final  double rate;

/// Create a copy of ModifierAttachDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModifierAttachDtoCopyWith<_ModifierAttachDto> get copyWith => __$ModifierAttachDtoCopyWithImpl<_ModifierAttachDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModifierAttachDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModifierAttachDto&&(identical(other.group, group) || other.group == group)&&(identical(other.rate, rate) || other.rate == rate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,group,rate);

@override
String toString() {
  return 'ModifierAttachDto(group: $group, rate: $rate)';
}


}

/// @nodoc
abstract mixin class _$ModifierAttachDtoCopyWith<$Res> implements $ModifierAttachDtoCopyWith<$Res> {
  factory _$ModifierAttachDtoCopyWith(_ModifierAttachDto value, $Res Function(_ModifierAttachDto) _then) = __$ModifierAttachDtoCopyWithImpl;
@override @useResult
$Res call({
 String group, double rate
});




}
/// @nodoc
class __$ModifierAttachDtoCopyWithImpl<$Res>
    implements _$ModifierAttachDtoCopyWith<$Res> {
  __$ModifierAttachDtoCopyWithImpl(this._self, this._then);

  final _ModifierAttachDto _self;
  final $Res Function(_ModifierAttachDto) _then;

/// Create a copy of ModifierAttachDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? group = null,Object? rate = null,}) {
  return _then(_ModifierAttachDto(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$CategoryShareDto {

 String get id; String get name; double get shareThisWeek; double get shareLastWeek;
/// Create a copy of CategoryShareDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryShareDtoCopyWith<CategoryShareDto> get copyWith => _$CategoryShareDtoCopyWithImpl<CategoryShareDto>(this as CategoryShareDto, _$identity);

  /// Serializes this CategoryShareDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryShareDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.shareThisWeek, shareThisWeek) || other.shareThisWeek == shareThisWeek)&&(identical(other.shareLastWeek, shareLastWeek) || other.shareLastWeek == shareLastWeek));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,shareThisWeek,shareLastWeek);

@override
String toString() {
  return 'CategoryShareDto(id: $id, name: $name, shareThisWeek: $shareThisWeek, shareLastWeek: $shareLastWeek)';
}


}

/// @nodoc
abstract mixin class $CategoryShareDtoCopyWith<$Res>  {
  factory $CategoryShareDtoCopyWith(CategoryShareDto value, $Res Function(CategoryShareDto) _then) = _$CategoryShareDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, double shareThisWeek, double shareLastWeek
});




}
/// @nodoc
class _$CategoryShareDtoCopyWithImpl<$Res>
    implements $CategoryShareDtoCopyWith<$Res> {
  _$CategoryShareDtoCopyWithImpl(this._self, this._then);

  final CategoryShareDto _self;
  final $Res Function(CategoryShareDto) _then;

/// Create a copy of CategoryShareDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? shareThisWeek = null,Object? shareLastWeek = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,shareThisWeek: null == shareThisWeek ? _self.shareThisWeek : shareThisWeek // ignore: cast_nullable_to_non_nullable
as double,shareLastWeek: null == shareLastWeek ? _self.shareLastWeek : shareLastWeek // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryShareDto].
extension CategoryShareDtoPatterns on CategoryShareDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryShareDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryShareDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryShareDto value)  $default,){
final _that = this;
switch (_that) {
case _CategoryShareDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryShareDto value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryShareDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double shareThisWeek,  double shareLastWeek)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryShareDto() when $default != null:
return $default(_that.id,_that.name,_that.shareThisWeek,_that.shareLastWeek);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double shareThisWeek,  double shareLastWeek)  $default,) {final _that = this;
switch (_that) {
case _CategoryShareDto():
return $default(_that.id,_that.name,_that.shareThisWeek,_that.shareLastWeek);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double shareThisWeek,  double shareLastWeek)?  $default,) {final _that = this;
switch (_that) {
case _CategoryShareDto() when $default != null:
return $default(_that.id,_that.name,_that.shareThisWeek,_that.shareLastWeek);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryShareDto implements CategoryShareDto {
  const _CategoryShareDto({required this.id, required this.name, this.shareThisWeek = 0.0, this.shareLastWeek = 0.0});
  factory _CategoryShareDto.fromJson(Map<String, dynamic> json) => _$CategoryShareDtoFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  double shareThisWeek;
@override@JsonKey() final  double shareLastWeek;

/// Create a copy of CategoryShareDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryShareDtoCopyWith<_CategoryShareDto> get copyWith => __$CategoryShareDtoCopyWithImpl<_CategoryShareDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryShareDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryShareDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.shareThisWeek, shareThisWeek) || other.shareThisWeek == shareThisWeek)&&(identical(other.shareLastWeek, shareLastWeek) || other.shareLastWeek == shareLastWeek));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,shareThisWeek,shareLastWeek);

@override
String toString() {
  return 'CategoryShareDto(id: $id, name: $name, shareThisWeek: $shareThisWeek, shareLastWeek: $shareLastWeek)';
}


}

/// @nodoc
abstract mixin class _$CategoryShareDtoCopyWith<$Res> implements $CategoryShareDtoCopyWith<$Res> {
  factory _$CategoryShareDtoCopyWith(_CategoryShareDto value, $Res Function(_CategoryShareDto) _then) = __$CategoryShareDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double shareThisWeek, double shareLastWeek
});




}
/// @nodoc
class __$CategoryShareDtoCopyWithImpl<$Res>
    implements _$CategoryShareDtoCopyWith<$Res> {
  __$CategoryShareDtoCopyWithImpl(this._self, this._then);

  final _CategoryShareDto _self;
  final $Res Function(_CategoryShareDto) _then;

/// Create a copy of CategoryShareDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? shareThisWeek = null,Object? shareLastWeek = null,}) {
  return _then(_CategoryShareDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,shareThisWeek: null == shareThisWeek ? _self.shareThisWeek : shareThisWeek // ignore: cast_nullable_to_non_nullable
as double,shareLastWeek: null == shareLastWeek ? _self.shareLastWeek : shareLastWeek // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$MatrixItemDto {

 String get itemId; String get name; double get popularity; double get margin; String get quadrant;
/// Create a copy of MatrixItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatrixItemDtoCopyWith<MatrixItemDto> get copyWith => _$MatrixItemDtoCopyWithImpl<MatrixItemDto>(this as MatrixItemDto, _$identity);

  /// Serializes this MatrixItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatrixItemDto&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.popularity, popularity) || other.popularity == popularity)&&(identical(other.margin, margin) || other.margin == margin)&&(identical(other.quadrant, quadrant) || other.quadrant == quadrant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,name,popularity,margin,quadrant);

@override
String toString() {
  return 'MatrixItemDto(itemId: $itemId, name: $name, popularity: $popularity, margin: $margin, quadrant: $quadrant)';
}


}

/// @nodoc
abstract mixin class $MatrixItemDtoCopyWith<$Res>  {
  factory $MatrixItemDtoCopyWith(MatrixItemDto value, $Res Function(MatrixItemDto) _then) = _$MatrixItemDtoCopyWithImpl;
@useResult
$Res call({
 String itemId, String name, double popularity, double margin, String quadrant
});




}
/// @nodoc
class _$MatrixItemDtoCopyWithImpl<$Res>
    implements $MatrixItemDtoCopyWith<$Res> {
  _$MatrixItemDtoCopyWithImpl(this._self, this._then);

  final MatrixItemDto _self;
  final $Res Function(MatrixItemDto) _then;

/// Create a copy of MatrixItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? name = null,Object? popularity = null,Object? margin = null,Object? quadrant = null,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,popularity: null == popularity ? _self.popularity : popularity // ignore: cast_nullable_to_non_nullable
as double,margin: null == margin ? _self.margin : margin // ignore: cast_nullable_to_non_nullable
as double,quadrant: null == quadrant ? _self.quadrant : quadrant // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MatrixItemDto].
extension MatrixItemDtoPatterns on MatrixItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatrixItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatrixItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatrixItemDto value)  $default,){
final _that = this;
switch (_that) {
case _MatrixItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatrixItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _MatrixItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  String name,  double popularity,  double margin,  String quadrant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatrixItemDto() when $default != null:
return $default(_that.itemId,_that.name,_that.popularity,_that.margin,_that.quadrant);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  String name,  double popularity,  double margin,  String quadrant)  $default,) {final _that = this;
switch (_that) {
case _MatrixItemDto():
return $default(_that.itemId,_that.name,_that.popularity,_that.margin,_that.quadrant);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  String name,  double popularity,  double margin,  String quadrant)?  $default,) {final _that = this;
switch (_that) {
case _MatrixItemDto() when $default != null:
return $default(_that.itemId,_that.name,_that.popularity,_that.margin,_that.quadrant);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatrixItemDto implements MatrixItemDto {
  const _MatrixItemDto({required this.itemId, required this.name, this.popularity = 0.0, this.margin = 0.0, required this.quadrant});
  factory _MatrixItemDto.fromJson(Map<String, dynamic> json) => _$MatrixItemDtoFromJson(json);

@override final  String itemId;
@override final  String name;
@override@JsonKey() final  double popularity;
@override@JsonKey() final  double margin;
@override final  String quadrant;

/// Create a copy of MatrixItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatrixItemDtoCopyWith<_MatrixItemDto> get copyWith => __$MatrixItemDtoCopyWithImpl<_MatrixItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatrixItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatrixItemDto&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.popularity, popularity) || other.popularity == popularity)&&(identical(other.margin, margin) || other.margin == margin)&&(identical(other.quadrant, quadrant) || other.quadrant == quadrant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,name,popularity,margin,quadrant);

@override
String toString() {
  return 'MatrixItemDto(itemId: $itemId, name: $name, popularity: $popularity, margin: $margin, quadrant: $quadrant)';
}


}

/// @nodoc
abstract mixin class _$MatrixItemDtoCopyWith<$Res> implements $MatrixItemDtoCopyWith<$Res> {
  factory _$MatrixItemDtoCopyWith(_MatrixItemDto value, $Res Function(_MatrixItemDto) _then) = __$MatrixItemDtoCopyWithImpl;
@override @useResult
$Res call({
 String itemId, String name, double popularity, double margin, String quadrant
});




}
/// @nodoc
class __$MatrixItemDtoCopyWithImpl<$Res>
    implements _$MatrixItemDtoCopyWith<$Res> {
  __$MatrixItemDtoCopyWithImpl(this._self, this._then);

  final _MatrixItemDto _self;
  final $Res Function(_MatrixItemDto) _then;

/// Create a copy of MatrixItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? name = null,Object? popularity = null,Object? margin = null,Object? quadrant = null,}) {
  return _then(_MatrixItemDto(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,popularity: null == popularity ? _self.popularity : popularity // ignore: cast_nullable_to_non_nullable
as double,margin: null == margin ? _self.margin : margin // ignore: cast_nullable_to_non_nullable
as double,quadrant: null == quadrant ? _self.quadrant : quadrant // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BasketPairDto {

 String get itemA; String get itemB; int get count; double get rate;
/// Create a copy of BasketPairDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasketPairDtoCopyWith<BasketPairDto> get copyWith => _$BasketPairDtoCopyWithImpl<BasketPairDto>(this as BasketPairDto, _$identity);

  /// Serializes this BasketPairDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketPairDto&&(identical(other.itemA, itemA) || other.itemA == itemA)&&(identical(other.itemB, itemB) || other.itemB == itemB)&&(identical(other.count, count) || other.count == count)&&(identical(other.rate, rate) || other.rate == rate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemA,itemB,count,rate);

@override
String toString() {
  return 'BasketPairDto(itemA: $itemA, itemB: $itemB, count: $count, rate: $rate)';
}


}

/// @nodoc
abstract mixin class $BasketPairDtoCopyWith<$Res>  {
  factory $BasketPairDtoCopyWith(BasketPairDto value, $Res Function(BasketPairDto) _then) = _$BasketPairDtoCopyWithImpl;
@useResult
$Res call({
 String itemA, String itemB, int count, double rate
});




}
/// @nodoc
class _$BasketPairDtoCopyWithImpl<$Res>
    implements $BasketPairDtoCopyWith<$Res> {
  _$BasketPairDtoCopyWithImpl(this._self, this._then);

  final BasketPairDto _self;
  final $Res Function(BasketPairDto) _then;

/// Create a copy of BasketPairDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemA = null,Object? itemB = null,Object? count = null,Object? rate = null,}) {
  return _then(_self.copyWith(
itemA: null == itemA ? _self.itemA : itemA // ignore: cast_nullable_to_non_nullable
as String,itemB: null == itemB ? _self.itemB : itemB // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BasketPairDto].
extension BasketPairDtoPatterns on BasketPairDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BasketPairDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BasketPairDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BasketPairDto value)  $default,){
final _that = this;
switch (_that) {
case _BasketPairDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BasketPairDto value)?  $default,){
final _that = this;
switch (_that) {
case _BasketPairDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemA,  String itemB,  int count,  double rate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BasketPairDto() when $default != null:
return $default(_that.itemA,_that.itemB,_that.count,_that.rate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemA,  String itemB,  int count,  double rate)  $default,) {final _that = this;
switch (_that) {
case _BasketPairDto():
return $default(_that.itemA,_that.itemB,_that.count,_that.rate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemA,  String itemB,  int count,  double rate)?  $default,) {final _that = this;
switch (_that) {
case _BasketPairDto() when $default != null:
return $default(_that.itemA,_that.itemB,_that.count,_that.rate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BasketPairDto implements BasketPairDto {
  const _BasketPairDto({required this.itemA, required this.itemB, this.count = 0, this.rate = 0.0});
  factory _BasketPairDto.fromJson(Map<String, dynamic> json) => _$BasketPairDtoFromJson(json);

@override final  String itemA;
@override final  String itemB;
@override@JsonKey() final  int count;
@override@JsonKey() final  double rate;

/// Create a copy of BasketPairDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BasketPairDtoCopyWith<_BasketPairDto> get copyWith => __$BasketPairDtoCopyWithImpl<_BasketPairDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BasketPairDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BasketPairDto&&(identical(other.itemA, itemA) || other.itemA == itemA)&&(identical(other.itemB, itemB) || other.itemB == itemB)&&(identical(other.count, count) || other.count == count)&&(identical(other.rate, rate) || other.rate == rate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemA,itemB,count,rate);

@override
String toString() {
  return 'BasketPairDto(itemA: $itemA, itemB: $itemB, count: $count, rate: $rate)';
}


}

/// @nodoc
abstract mixin class _$BasketPairDtoCopyWith<$Res> implements $BasketPairDtoCopyWith<$Res> {
  factory _$BasketPairDtoCopyWith(_BasketPairDto value, $Res Function(_BasketPairDto) _then) = __$BasketPairDtoCopyWithImpl;
@override @useResult
$Res call({
 String itemA, String itemB, int count, double rate
});




}
/// @nodoc
class __$BasketPairDtoCopyWithImpl<$Res>
    implements _$BasketPairDtoCopyWith<$Res> {
  __$BasketPairDtoCopyWithImpl(this._self, this._then);

  final _BasketPairDto _self;
  final $Res Function(_BasketPairDto) _then;

/// Create a copy of BasketPairDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemA = null,Object? itemB = null,Object? count = null,Object? rate = null,}) {
  return _then(_BasketPairDto(
itemA: null == itemA ? _self.itemA : itemA // ignore: cast_nullable_to_non_nullable
as String,itemB: null == itemB ? _self.itemB : itemB // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$OpsSectionDto {

 List<KpiTileDto> get kpis; SpeedSectionDto get speed; List<StationRowDto> get stations; List<List<double>> get heatmap; ReservationStatsDto get reservations; List<VoidReasonDto> get voidReasons; List<StaffVoidDto> get voidByStaff;
/// Create a copy of OpsSectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpsSectionDtoCopyWith<OpsSectionDto> get copyWith => _$OpsSectionDtoCopyWithImpl<OpsSectionDto>(this as OpsSectionDto, _$identity);

  /// Serializes this OpsSectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpsSectionDto&&const DeepCollectionEquality().equals(other.kpis, kpis)&&(identical(other.speed, speed) || other.speed == speed)&&const DeepCollectionEquality().equals(other.stations, stations)&&const DeepCollectionEquality().equals(other.heatmap, heatmap)&&(identical(other.reservations, reservations) || other.reservations == reservations)&&const DeepCollectionEquality().equals(other.voidReasons, voidReasons)&&const DeepCollectionEquality().equals(other.voidByStaff, voidByStaff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(kpis),speed,const DeepCollectionEquality().hash(stations),const DeepCollectionEquality().hash(heatmap),reservations,const DeepCollectionEquality().hash(voidReasons),const DeepCollectionEquality().hash(voidByStaff));

@override
String toString() {
  return 'OpsSectionDto(kpis: $kpis, speed: $speed, stations: $stations, heatmap: $heatmap, reservations: $reservations, voidReasons: $voidReasons, voidByStaff: $voidByStaff)';
}


}

/// @nodoc
abstract mixin class $OpsSectionDtoCopyWith<$Res>  {
  factory $OpsSectionDtoCopyWith(OpsSectionDto value, $Res Function(OpsSectionDto) _then) = _$OpsSectionDtoCopyWithImpl;
@useResult
$Res call({
 List<KpiTileDto> kpis, SpeedSectionDto speed, List<StationRowDto> stations, List<List<double>> heatmap, ReservationStatsDto reservations, List<VoidReasonDto> voidReasons, List<StaffVoidDto> voidByStaff
});


$SpeedSectionDtoCopyWith<$Res> get speed;$ReservationStatsDtoCopyWith<$Res> get reservations;

}
/// @nodoc
class _$OpsSectionDtoCopyWithImpl<$Res>
    implements $OpsSectionDtoCopyWith<$Res> {
  _$OpsSectionDtoCopyWithImpl(this._self, this._then);

  final OpsSectionDto _self;
  final $Res Function(OpsSectionDto) _then;

/// Create a copy of OpsSectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kpis = null,Object? speed = null,Object? stations = null,Object? heatmap = null,Object? reservations = null,Object? voidReasons = null,Object? voidByStaff = null,}) {
  return _then(_self.copyWith(
kpis: null == kpis ? _self.kpis : kpis // ignore: cast_nullable_to_non_nullable
as List<KpiTileDto>,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as SpeedSectionDto,stations: null == stations ? _self.stations : stations // ignore: cast_nullable_to_non_nullable
as List<StationRowDto>,heatmap: null == heatmap ? _self.heatmap : heatmap // ignore: cast_nullable_to_non_nullable
as List<List<double>>,reservations: null == reservations ? _self.reservations : reservations // ignore: cast_nullable_to_non_nullable
as ReservationStatsDto,voidReasons: null == voidReasons ? _self.voidReasons : voidReasons // ignore: cast_nullable_to_non_nullable
as List<VoidReasonDto>,voidByStaff: null == voidByStaff ? _self.voidByStaff : voidByStaff // ignore: cast_nullable_to_non_nullable
as List<StaffVoidDto>,
  ));
}
/// Create a copy of OpsSectionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedSectionDtoCopyWith<$Res> get speed {
  
  return $SpeedSectionDtoCopyWith<$Res>(_self.speed, (value) {
    return _then(_self.copyWith(speed: value));
  });
}/// Create a copy of OpsSectionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReservationStatsDtoCopyWith<$Res> get reservations {
  
  return $ReservationStatsDtoCopyWith<$Res>(_self.reservations, (value) {
    return _then(_self.copyWith(reservations: value));
  });
}
}


/// Adds pattern-matching-related methods to [OpsSectionDto].
extension OpsSectionDtoPatterns on OpsSectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpsSectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpsSectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpsSectionDto value)  $default,){
final _that = this;
switch (_that) {
case _OpsSectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpsSectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _OpsSectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<KpiTileDto> kpis,  SpeedSectionDto speed,  List<StationRowDto> stations,  List<List<double>> heatmap,  ReservationStatsDto reservations,  List<VoidReasonDto> voidReasons,  List<StaffVoidDto> voidByStaff)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpsSectionDto() when $default != null:
return $default(_that.kpis,_that.speed,_that.stations,_that.heatmap,_that.reservations,_that.voidReasons,_that.voidByStaff);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<KpiTileDto> kpis,  SpeedSectionDto speed,  List<StationRowDto> stations,  List<List<double>> heatmap,  ReservationStatsDto reservations,  List<VoidReasonDto> voidReasons,  List<StaffVoidDto> voidByStaff)  $default,) {final _that = this;
switch (_that) {
case _OpsSectionDto():
return $default(_that.kpis,_that.speed,_that.stations,_that.heatmap,_that.reservations,_that.voidReasons,_that.voidByStaff);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<KpiTileDto> kpis,  SpeedSectionDto speed,  List<StationRowDto> stations,  List<List<double>> heatmap,  ReservationStatsDto reservations,  List<VoidReasonDto> voidReasons,  List<StaffVoidDto> voidByStaff)?  $default,) {final _that = this;
switch (_that) {
case _OpsSectionDto() when $default != null:
return $default(_that.kpis,_that.speed,_that.stations,_that.heatmap,_that.reservations,_that.voidReasons,_that.voidByStaff);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpsSectionDto implements OpsSectionDto {
  const _OpsSectionDto({final  List<KpiTileDto> kpis = const <KpiTileDto>[], this.speed = const SpeedSectionDto(), final  List<StationRowDto> stations = const <StationRowDto>[], final  List<List<double>> heatmap = const <List<double>>[], required this.reservations, final  List<VoidReasonDto> voidReasons = const <VoidReasonDto>[], final  List<StaffVoidDto> voidByStaff = const <StaffVoidDto>[]}): _kpis = kpis,_stations = stations,_heatmap = heatmap,_voidReasons = voidReasons,_voidByStaff = voidByStaff;
  factory _OpsSectionDto.fromJson(Map<String, dynamic> json) => _$OpsSectionDtoFromJson(json);

 final  List<KpiTileDto> _kpis;
@override@JsonKey() List<KpiTileDto> get kpis {
  if (_kpis is EqualUnmodifiableListView) return _kpis;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_kpis);
}

@override@JsonKey() final  SpeedSectionDto speed;
 final  List<StationRowDto> _stations;
@override@JsonKey() List<StationRowDto> get stations {
  if (_stations is EqualUnmodifiableListView) return _stations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stations);
}

 final  List<List<double>> _heatmap;
@override@JsonKey() List<List<double>> get heatmap {
  if (_heatmap is EqualUnmodifiableListView) return _heatmap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_heatmap);
}

@override final  ReservationStatsDto reservations;
 final  List<VoidReasonDto> _voidReasons;
@override@JsonKey() List<VoidReasonDto> get voidReasons {
  if (_voidReasons is EqualUnmodifiableListView) return _voidReasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_voidReasons);
}

 final  List<StaffVoidDto> _voidByStaff;
@override@JsonKey() List<StaffVoidDto> get voidByStaff {
  if (_voidByStaff is EqualUnmodifiableListView) return _voidByStaff;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_voidByStaff);
}


/// Create a copy of OpsSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpsSectionDtoCopyWith<_OpsSectionDto> get copyWith => __$OpsSectionDtoCopyWithImpl<_OpsSectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpsSectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpsSectionDto&&const DeepCollectionEquality().equals(other._kpis, _kpis)&&(identical(other.speed, speed) || other.speed == speed)&&const DeepCollectionEquality().equals(other._stations, _stations)&&const DeepCollectionEquality().equals(other._heatmap, _heatmap)&&(identical(other.reservations, reservations) || other.reservations == reservations)&&const DeepCollectionEquality().equals(other._voidReasons, _voidReasons)&&const DeepCollectionEquality().equals(other._voidByStaff, _voidByStaff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_kpis),speed,const DeepCollectionEquality().hash(_stations),const DeepCollectionEquality().hash(_heatmap),reservations,const DeepCollectionEquality().hash(_voidReasons),const DeepCollectionEquality().hash(_voidByStaff));

@override
String toString() {
  return 'OpsSectionDto(kpis: $kpis, speed: $speed, stations: $stations, heatmap: $heatmap, reservations: $reservations, voidReasons: $voidReasons, voidByStaff: $voidByStaff)';
}


}

/// @nodoc
abstract mixin class _$OpsSectionDtoCopyWith<$Res> implements $OpsSectionDtoCopyWith<$Res> {
  factory _$OpsSectionDtoCopyWith(_OpsSectionDto value, $Res Function(_OpsSectionDto) _then) = __$OpsSectionDtoCopyWithImpl;
@override @useResult
$Res call({
 List<KpiTileDto> kpis, SpeedSectionDto speed, List<StationRowDto> stations, List<List<double>> heatmap, ReservationStatsDto reservations, List<VoidReasonDto> voidReasons, List<StaffVoidDto> voidByStaff
});


@override $SpeedSectionDtoCopyWith<$Res> get speed;@override $ReservationStatsDtoCopyWith<$Res> get reservations;

}
/// @nodoc
class __$OpsSectionDtoCopyWithImpl<$Res>
    implements _$OpsSectionDtoCopyWith<$Res> {
  __$OpsSectionDtoCopyWithImpl(this._self, this._then);

  final _OpsSectionDto _self;
  final $Res Function(_OpsSectionDto) _then;

/// Create a copy of OpsSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kpis = null,Object? speed = null,Object? stations = null,Object? heatmap = null,Object? reservations = null,Object? voidReasons = null,Object? voidByStaff = null,}) {
  return _then(_OpsSectionDto(
kpis: null == kpis ? _self._kpis : kpis // ignore: cast_nullable_to_non_nullable
as List<KpiTileDto>,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as SpeedSectionDto,stations: null == stations ? _self._stations : stations // ignore: cast_nullable_to_non_nullable
as List<StationRowDto>,heatmap: null == heatmap ? _self._heatmap : heatmap // ignore: cast_nullable_to_non_nullable
as List<List<double>>,reservations: null == reservations ? _self.reservations : reservations // ignore: cast_nullable_to_non_nullable
as ReservationStatsDto,voidReasons: null == voidReasons ? _self._voidReasons : voidReasons // ignore: cast_nullable_to_non_nullable
as List<VoidReasonDto>,voidByStaff: null == voidByStaff ? _self._voidByStaff : voidByStaff // ignore: cast_nullable_to_non_nullable
as List<StaffVoidDto>,
  ));
}

/// Create a copy of OpsSectionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedSectionDtoCopyWith<$Res> get speed {
  
  return $SpeedSectionDtoCopyWith<$Res>(_self.speed, (value) {
    return _then(_self.copyWith(speed: value));
  });
}/// Create a copy of OpsSectionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReservationStatsDtoCopyWith<$Res> get reservations {
  
  return $ReservationStatsDtoCopyWith<$Res>(_self.reservations, (value) {
    return _then(_self.copyWith(reservations: value));
  });
}
}


/// @nodoc
mixin _$SpeedSectionDto {

 int get prepMedianMin; int get pickupMedianMin; double get slaPct;/// The venue *default* target — no longer the only target in play.
 int get prepTargetMins; int get sampleSize; List<SpeedItemDto> get slowItems;// ADR-0044 additions.
 int get pickupTargetMins; double get pickupSlaPct; int get courseSampleSize; int get greetMedianMin; double get greetBreachPct; int get ungreetedMins; int get greetSampleSize;
/// Create a copy of SpeedSectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedSectionDtoCopyWith<SpeedSectionDto> get copyWith => _$SpeedSectionDtoCopyWithImpl<SpeedSectionDto>(this as SpeedSectionDto, _$identity);

  /// Serializes this SpeedSectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedSectionDto&&(identical(other.prepMedianMin, prepMedianMin) || other.prepMedianMin == prepMedianMin)&&(identical(other.pickupMedianMin, pickupMedianMin) || other.pickupMedianMin == pickupMedianMin)&&(identical(other.slaPct, slaPct) || other.slaPct == slaPct)&&(identical(other.prepTargetMins, prepTargetMins) || other.prepTargetMins == prepTargetMins)&&(identical(other.sampleSize, sampleSize) || other.sampleSize == sampleSize)&&const DeepCollectionEquality().equals(other.slowItems, slowItems)&&(identical(other.pickupTargetMins, pickupTargetMins) || other.pickupTargetMins == pickupTargetMins)&&(identical(other.pickupSlaPct, pickupSlaPct) || other.pickupSlaPct == pickupSlaPct)&&(identical(other.courseSampleSize, courseSampleSize) || other.courseSampleSize == courseSampleSize)&&(identical(other.greetMedianMin, greetMedianMin) || other.greetMedianMin == greetMedianMin)&&(identical(other.greetBreachPct, greetBreachPct) || other.greetBreachPct == greetBreachPct)&&(identical(other.ungreetedMins, ungreetedMins) || other.ungreetedMins == ungreetedMins)&&(identical(other.greetSampleSize, greetSampleSize) || other.greetSampleSize == greetSampleSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,prepMedianMin,pickupMedianMin,slaPct,prepTargetMins,sampleSize,const DeepCollectionEquality().hash(slowItems),pickupTargetMins,pickupSlaPct,courseSampleSize,greetMedianMin,greetBreachPct,ungreetedMins,greetSampleSize);

@override
String toString() {
  return 'SpeedSectionDto(prepMedianMin: $prepMedianMin, pickupMedianMin: $pickupMedianMin, slaPct: $slaPct, prepTargetMins: $prepTargetMins, sampleSize: $sampleSize, slowItems: $slowItems, pickupTargetMins: $pickupTargetMins, pickupSlaPct: $pickupSlaPct, courseSampleSize: $courseSampleSize, greetMedianMin: $greetMedianMin, greetBreachPct: $greetBreachPct, ungreetedMins: $ungreetedMins, greetSampleSize: $greetSampleSize)';
}


}

/// @nodoc
abstract mixin class $SpeedSectionDtoCopyWith<$Res>  {
  factory $SpeedSectionDtoCopyWith(SpeedSectionDto value, $Res Function(SpeedSectionDto) _then) = _$SpeedSectionDtoCopyWithImpl;
@useResult
$Res call({
 int prepMedianMin, int pickupMedianMin, double slaPct, int prepTargetMins, int sampleSize, List<SpeedItemDto> slowItems, int pickupTargetMins, double pickupSlaPct, int courseSampleSize, int greetMedianMin, double greetBreachPct, int ungreetedMins, int greetSampleSize
});




}
/// @nodoc
class _$SpeedSectionDtoCopyWithImpl<$Res>
    implements $SpeedSectionDtoCopyWith<$Res> {
  _$SpeedSectionDtoCopyWithImpl(this._self, this._then);

  final SpeedSectionDto _self;
  final $Res Function(SpeedSectionDto) _then;

/// Create a copy of SpeedSectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? prepMedianMin = null,Object? pickupMedianMin = null,Object? slaPct = null,Object? prepTargetMins = null,Object? sampleSize = null,Object? slowItems = null,Object? pickupTargetMins = null,Object? pickupSlaPct = null,Object? courseSampleSize = null,Object? greetMedianMin = null,Object? greetBreachPct = null,Object? ungreetedMins = null,Object? greetSampleSize = null,}) {
  return _then(_self.copyWith(
prepMedianMin: null == prepMedianMin ? _self.prepMedianMin : prepMedianMin // ignore: cast_nullable_to_non_nullable
as int,pickupMedianMin: null == pickupMedianMin ? _self.pickupMedianMin : pickupMedianMin // ignore: cast_nullable_to_non_nullable
as int,slaPct: null == slaPct ? _self.slaPct : slaPct // ignore: cast_nullable_to_non_nullable
as double,prepTargetMins: null == prepTargetMins ? _self.prepTargetMins : prepTargetMins // ignore: cast_nullable_to_non_nullable
as int,sampleSize: null == sampleSize ? _self.sampleSize : sampleSize // ignore: cast_nullable_to_non_nullable
as int,slowItems: null == slowItems ? _self.slowItems : slowItems // ignore: cast_nullable_to_non_nullable
as List<SpeedItemDto>,pickupTargetMins: null == pickupTargetMins ? _self.pickupTargetMins : pickupTargetMins // ignore: cast_nullable_to_non_nullable
as int,pickupSlaPct: null == pickupSlaPct ? _self.pickupSlaPct : pickupSlaPct // ignore: cast_nullable_to_non_nullable
as double,courseSampleSize: null == courseSampleSize ? _self.courseSampleSize : courseSampleSize // ignore: cast_nullable_to_non_nullable
as int,greetMedianMin: null == greetMedianMin ? _self.greetMedianMin : greetMedianMin // ignore: cast_nullable_to_non_nullable
as int,greetBreachPct: null == greetBreachPct ? _self.greetBreachPct : greetBreachPct // ignore: cast_nullable_to_non_nullable
as double,ungreetedMins: null == ungreetedMins ? _self.ungreetedMins : ungreetedMins // ignore: cast_nullable_to_non_nullable
as int,greetSampleSize: null == greetSampleSize ? _self.greetSampleSize : greetSampleSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SpeedSectionDto].
extension SpeedSectionDtoPatterns on SpeedSectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeedSectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeedSectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeedSectionDto value)  $default,){
final _that = this;
switch (_that) {
case _SpeedSectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeedSectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _SpeedSectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int prepMedianMin,  int pickupMedianMin,  double slaPct,  int prepTargetMins,  int sampleSize,  List<SpeedItemDto> slowItems,  int pickupTargetMins,  double pickupSlaPct,  int courseSampleSize,  int greetMedianMin,  double greetBreachPct,  int ungreetedMins,  int greetSampleSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedSectionDto() when $default != null:
return $default(_that.prepMedianMin,_that.pickupMedianMin,_that.slaPct,_that.prepTargetMins,_that.sampleSize,_that.slowItems,_that.pickupTargetMins,_that.pickupSlaPct,_that.courseSampleSize,_that.greetMedianMin,_that.greetBreachPct,_that.ungreetedMins,_that.greetSampleSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int prepMedianMin,  int pickupMedianMin,  double slaPct,  int prepTargetMins,  int sampleSize,  List<SpeedItemDto> slowItems,  int pickupTargetMins,  double pickupSlaPct,  int courseSampleSize,  int greetMedianMin,  double greetBreachPct,  int ungreetedMins,  int greetSampleSize)  $default,) {final _that = this;
switch (_that) {
case _SpeedSectionDto():
return $default(_that.prepMedianMin,_that.pickupMedianMin,_that.slaPct,_that.prepTargetMins,_that.sampleSize,_that.slowItems,_that.pickupTargetMins,_that.pickupSlaPct,_that.courseSampleSize,_that.greetMedianMin,_that.greetBreachPct,_that.ungreetedMins,_that.greetSampleSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int prepMedianMin,  int pickupMedianMin,  double slaPct,  int prepTargetMins,  int sampleSize,  List<SpeedItemDto> slowItems,  int pickupTargetMins,  double pickupSlaPct,  int courseSampleSize,  int greetMedianMin,  double greetBreachPct,  int ungreetedMins,  int greetSampleSize)?  $default,) {final _that = this;
switch (_that) {
case _SpeedSectionDto() when $default != null:
return $default(_that.prepMedianMin,_that.pickupMedianMin,_that.slaPct,_that.prepTargetMins,_that.sampleSize,_that.slowItems,_that.pickupTargetMins,_that.pickupSlaPct,_that.courseSampleSize,_that.greetMedianMin,_that.greetBreachPct,_that.ungreetedMins,_that.greetSampleSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpeedSectionDto implements SpeedSectionDto {
  const _SpeedSectionDto({this.prepMedianMin = 0, this.pickupMedianMin = 0, this.slaPct = 0.0, this.prepTargetMins = 15, this.sampleSize = 0, final  List<SpeedItemDto> slowItems = const <SpeedItemDto>[], this.pickupTargetMins = 4, this.pickupSlaPct = 0.0, this.courseSampleSize = 0, this.greetMedianMin = 0, this.greetBreachPct = 0.0, this.ungreetedMins = 7, this.greetSampleSize = 0}): _slowItems = slowItems;
  factory _SpeedSectionDto.fromJson(Map<String, dynamic> json) => _$SpeedSectionDtoFromJson(json);

@override@JsonKey() final  int prepMedianMin;
@override@JsonKey() final  int pickupMedianMin;
@override@JsonKey() final  double slaPct;
/// The venue *default* target — no longer the only target in play.
@override@JsonKey() final  int prepTargetMins;
@override@JsonKey() final  int sampleSize;
 final  List<SpeedItemDto> _slowItems;
@override@JsonKey() List<SpeedItemDto> get slowItems {
  if (_slowItems is EqualUnmodifiableListView) return _slowItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slowItems);
}

// ADR-0044 additions.
@override@JsonKey() final  int pickupTargetMins;
@override@JsonKey() final  double pickupSlaPct;
@override@JsonKey() final  int courseSampleSize;
@override@JsonKey() final  int greetMedianMin;
@override@JsonKey() final  double greetBreachPct;
@override@JsonKey() final  int ungreetedMins;
@override@JsonKey() final  int greetSampleSize;

/// Create a copy of SpeedSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedSectionDtoCopyWith<_SpeedSectionDto> get copyWith => __$SpeedSectionDtoCopyWithImpl<_SpeedSectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpeedSectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedSectionDto&&(identical(other.prepMedianMin, prepMedianMin) || other.prepMedianMin == prepMedianMin)&&(identical(other.pickupMedianMin, pickupMedianMin) || other.pickupMedianMin == pickupMedianMin)&&(identical(other.slaPct, slaPct) || other.slaPct == slaPct)&&(identical(other.prepTargetMins, prepTargetMins) || other.prepTargetMins == prepTargetMins)&&(identical(other.sampleSize, sampleSize) || other.sampleSize == sampleSize)&&const DeepCollectionEquality().equals(other._slowItems, _slowItems)&&(identical(other.pickupTargetMins, pickupTargetMins) || other.pickupTargetMins == pickupTargetMins)&&(identical(other.pickupSlaPct, pickupSlaPct) || other.pickupSlaPct == pickupSlaPct)&&(identical(other.courseSampleSize, courseSampleSize) || other.courseSampleSize == courseSampleSize)&&(identical(other.greetMedianMin, greetMedianMin) || other.greetMedianMin == greetMedianMin)&&(identical(other.greetBreachPct, greetBreachPct) || other.greetBreachPct == greetBreachPct)&&(identical(other.ungreetedMins, ungreetedMins) || other.ungreetedMins == ungreetedMins)&&(identical(other.greetSampleSize, greetSampleSize) || other.greetSampleSize == greetSampleSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,prepMedianMin,pickupMedianMin,slaPct,prepTargetMins,sampleSize,const DeepCollectionEquality().hash(_slowItems),pickupTargetMins,pickupSlaPct,courseSampleSize,greetMedianMin,greetBreachPct,ungreetedMins,greetSampleSize);

@override
String toString() {
  return 'SpeedSectionDto(prepMedianMin: $prepMedianMin, pickupMedianMin: $pickupMedianMin, slaPct: $slaPct, prepTargetMins: $prepTargetMins, sampleSize: $sampleSize, slowItems: $slowItems, pickupTargetMins: $pickupTargetMins, pickupSlaPct: $pickupSlaPct, courseSampleSize: $courseSampleSize, greetMedianMin: $greetMedianMin, greetBreachPct: $greetBreachPct, ungreetedMins: $ungreetedMins, greetSampleSize: $greetSampleSize)';
}


}

/// @nodoc
abstract mixin class _$SpeedSectionDtoCopyWith<$Res> implements $SpeedSectionDtoCopyWith<$Res> {
  factory _$SpeedSectionDtoCopyWith(_SpeedSectionDto value, $Res Function(_SpeedSectionDto) _then) = __$SpeedSectionDtoCopyWithImpl;
@override @useResult
$Res call({
 int prepMedianMin, int pickupMedianMin, double slaPct, int prepTargetMins, int sampleSize, List<SpeedItemDto> slowItems, int pickupTargetMins, double pickupSlaPct, int courseSampleSize, int greetMedianMin, double greetBreachPct, int ungreetedMins, int greetSampleSize
});




}
/// @nodoc
class __$SpeedSectionDtoCopyWithImpl<$Res>
    implements _$SpeedSectionDtoCopyWith<$Res> {
  __$SpeedSectionDtoCopyWithImpl(this._self, this._then);

  final _SpeedSectionDto _self;
  final $Res Function(_SpeedSectionDto) _then;

/// Create a copy of SpeedSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? prepMedianMin = null,Object? pickupMedianMin = null,Object? slaPct = null,Object? prepTargetMins = null,Object? sampleSize = null,Object? slowItems = null,Object? pickupTargetMins = null,Object? pickupSlaPct = null,Object? courseSampleSize = null,Object? greetMedianMin = null,Object? greetBreachPct = null,Object? ungreetedMins = null,Object? greetSampleSize = null,}) {
  return _then(_SpeedSectionDto(
prepMedianMin: null == prepMedianMin ? _self.prepMedianMin : prepMedianMin // ignore: cast_nullable_to_non_nullable
as int,pickupMedianMin: null == pickupMedianMin ? _self.pickupMedianMin : pickupMedianMin // ignore: cast_nullable_to_non_nullable
as int,slaPct: null == slaPct ? _self.slaPct : slaPct // ignore: cast_nullable_to_non_nullable
as double,prepTargetMins: null == prepTargetMins ? _self.prepTargetMins : prepTargetMins // ignore: cast_nullable_to_non_nullable
as int,sampleSize: null == sampleSize ? _self.sampleSize : sampleSize // ignore: cast_nullable_to_non_nullable
as int,slowItems: null == slowItems ? _self._slowItems : slowItems // ignore: cast_nullable_to_non_nullable
as List<SpeedItemDto>,pickupTargetMins: null == pickupTargetMins ? _self.pickupTargetMins : pickupTargetMins // ignore: cast_nullable_to_non_nullable
as int,pickupSlaPct: null == pickupSlaPct ? _self.pickupSlaPct : pickupSlaPct // ignore: cast_nullable_to_non_nullable
as double,courseSampleSize: null == courseSampleSize ? _self.courseSampleSize : courseSampleSize // ignore: cast_nullable_to_non_nullable
as int,greetMedianMin: null == greetMedianMin ? _self.greetMedianMin : greetMedianMin // ignore: cast_nullable_to_non_nullable
as int,greetBreachPct: null == greetBreachPct ? _self.greetBreachPct : greetBreachPct // ignore: cast_nullable_to_non_nullable
as double,ungreetedMins: null == ungreetedMins ? _self.ungreetedMins : ungreetedMins // ignore: cast_nullable_to_non_nullable
as int,greetSampleSize: null == greetSampleSize ? _self.greetSampleSize : greetSampleSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SpeedItemDto {

 String get itemId; String get name; double get avgPrepMin; int get count;
/// Create a copy of SpeedItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedItemDtoCopyWith<SpeedItemDto> get copyWith => _$SpeedItemDtoCopyWithImpl<SpeedItemDto>(this as SpeedItemDto, _$identity);

  /// Serializes this SpeedItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedItemDto&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.avgPrepMin, avgPrepMin) || other.avgPrepMin == avgPrepMin)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,name,avgPrepMin,count);

@override
String toString() {
  return 'SpeedItemDto(itemId: $itemId, name: $name, avgPrepMin: $avgPrepMin, count: $count)';
}


}

/// @nodoc
abstract mixin class $SpeedItemDtoCopyWith<$Res>  {
  factory $SpeedItemDtoCopyWith(SpeedItemDto value, $Res Function(SpeedItemDto) _then) = _$SpeedItemDtoCopyWithImpl;
@useResult
$Res call({
 String itemId, String name, double avgPrepMin, int count
});




}
/// @nodoc
class _$SpeedItemDtoCopyWithImpl<$Res>
    implements $SpeedItemDtoCopyWith<$Res> {
  _$SpeedItemDtoCopyWithImpl(this._self, this._then);

  final SpeedItemDto _self;
  final $Res Function(SpeedItemDto) _then;

/// Create a copy of SpeedItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? name = null,Object? avgPrepMin = null,Object? count = null,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avgPrepMin: null == avgPrepMin ? _self.avgPrepMin : avgPrepMin // ignore: cast_nullable_to_non_nullable
as double,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SpeedItemDto].
extension SpeedItemDtoPatterns on SpeedItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeedItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeedItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeedItemDto value)  $default,){
final _that = this;
switch (_that) {
case _SpeedItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeedItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _SpeedItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  String name,  double avgPrepMin,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedItemDto() when $default != null:
return $default(_that.itemId,_that.name,_that.avgPrepMin,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  String name,  double avgPrepMin,  int count)  $default,) {final _that = this;
switch (_that) {
case _SpeedItemDto():
return $default(_that.itemId,_that.name,_that.avgPrepMin,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  String name,  double avgPrepMin,  int count)?  $default,) {final _that = this;
switch (_that) {
case _SpeedItemDto() when $default != null:
return $default(_that.itemId,_that.name,_that.avgPrepMin,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpeedItemDto implements SpeedItemDto {
  const _SpeedItemDto({this.itemId = '', this.name = '', this.avgPrepMin = 0.0, this.count = 0});
  factory _SpeedItemDto.fromJson(Map<String, dynamic> json) => _$SpeedItemDtoFromJson(json);

@override@JsonKey() final  String itemId;
@override@JsonKey() final  String name;
@override@JsonKey() final  double avgPrepMin;
@override@JsonKey() final  int count;

/// Create a copy of SpeedItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedItemDtoCopyWith<_SpeedItemDto> get copyWith => __$SpeedItemDtoCopyWithImpl<_SpeedItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpeedItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedItemDto&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.avgPrepMin, avgPrepMin) || other.avgPrepMin == avgPrepMin)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,name,avgPrepMin,count);

@override
String toString() {
  return 'SpeedItemDto(itemId: $itemId, name: $name, avgPrepMin: $avgPrepMin, count: $count)';
}


}

/// @nodoc
abstract mixin class _$SpeedItemDtoCopyWith<$Res> implements $SpeedItemDtoCopyWith<$Res> {
  factory _$SpeedItemDtoCopyWith(_SpeedItemDto value, $Res Function(_SpeedItemDto) _then) = __$SpeedItemDtoCopyWithImpl;
@override @useResult
$Res call({
 String itemId, String name, double avgPrepMin, int count
});




}
/// @nodoc
class __$SpeedItemDtoCopyWithImpl<$Res>
    implements _$SpeedItemDtoCopyWith<$Res> {
  __$SpeedItemDtoCopyWithImpl(this._self, this._then);

  final _SpeedItemDto _self;
  final $Res Function(_SpeedItemDto) _then;

/// Create a copy of SpeedItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? name = null,Object? avgPrepMin = null,Object? count = null,}) {
  return _then(_SpeedItemDto(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avgPrepMin: null == avgPrepMin ? _self.avgPrepMin : avgPrepMin // ignore: cast_nullable_to_non_nullable
as double,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StationRowDto {

// The station code only — its words come from `stationLabel` at read time
// (ADR-0085). The server stopped sending a `label` and this stayed
// required, which failed the whole snapshot's parse.
 String get station; int get qty; double get utilization;
/// Create a copy of StationRowDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StationRowDtoCopyWith<StationRowDto> get copyWith => _$StationRowDtoCopyWithImpl<StationRowDto>(this as StationRowDto, _$identity);

  /// Serializes this StationRowDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StationRowDto&&(identical(other.station, station) || other.station == station)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.utilization, utilization) || other.utilization == utilization));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,station,qty,utilization);

@override
String toString() {
  return 'StationRowDto(station: $station, qty: $qty, utilization: $utilization)';
}


}

/// @nodoc
abstract mixin class $StationRowDtoCopyWith<$Res>  {
  factory $StationRowDtoCopyWith(StationRowDto value, $Res Function(StationRowDto) _then) = _$StationRowDtoCopyWithImpl;
@useResult
$Res call({
 String station, int qty, double utilization
});




}
/// @nodoc
class _$StationRowDtoCopyWithImpl<$Res>
    implements $StationRowDtoCopyWith<$Res> {
  _$StationRowDtoCopyWithImpl(this._self, this._then);

  final StationRowDto _self;
  final $Res Function(StationRowDto) _then;

/// Create a copy of StationRowDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? station = null,Object? qty = null,Object? utilization = null,}) {
  return _then(_self.copyWith(
station: null == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,utilization: null == utilization ? _self.utilization : utilization // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [StationRowDto].
extension StationRowDtoPatterns on StationRowDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StationRowDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StationRowDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StationRowDto value)  $default,){
final _that = this;
switch (_that) {
case _StationRowDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StationRowDto value)?  $default,){
final _that = this;
switch (_that) {
case _StationRowDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String station,  int qty,  double utilization)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StationRowDto() when $default != null:
return $default(_that.station,_that.qty,_that.utilization);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String station,  int qty,  double utilization)  $default,) {final _that = this;
switch (_that) {
case _StationRowDto():
return $default(_that.station,_that.qty,_that.utilization);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String station,  int qty,  double utilization)?  $default,) {final _that = this;
switch (_that) {
case _StationRowDto() when $default != null:
return $default(_that.station,_that.qty,_that.utilization);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StationRowDto implements StationRowDto {
  const _StationRowDto({required this.station, this.qty = 0, this.utilization = 0.0});
  factory _StationRowDto.fromJson(Map<String, dynamic> json) => _$StationRowDtoFromJson(json);

// The station code only — its words come from `stationLabel` at read time
// (ADR-0085). The server stopped sending a `label` and this stayed
// required, which failed the whole snapshot's parse.
@override final  String station;
@override@JsonKey() final  int qty;
@override@JsonKey() final  double utilization;

/// Create a copy of StationRowDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StationRowDtoCopyWith<_StationRowDto> get copyWith => __$StationRowDtoCopyWithImpl<_StationRowDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StationRowDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StationRowDto&&(identical(other.station, station) || other.station == station)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.utilization, utilization) || other.utilization == utilization));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,station,qty,utilization);

@override
String toString() {
  return 'StationRowDto(station: $station, qty: $qty, utilization: $utilization)';
}


}

/// @nodoc
abstract mixin class _$StationRowDtoCopyWith<$Res> implements $StationRowDtoCopyWith<$Res> {
  factory _$StationRowDtoCopyWith(_StationRowDto value, $Res Function(_StationRowDto) _then) = __$StationRowDtoCopyWithImpl;
@override @useResult
$Res call({
 String station, int qty, double utilization
});




}
/// @nodoc
class __$StationRowDtoCopyWithImpl<$Res>
    implements _$StationRowDtoCopyWith<$Res> {
  __$StationRowDtoCopyWithImpl(this._self, this._then);

  final _StationRowDto _self;
  final $Res Function(_StationRowDto) _then;

/// Create a copy of StationRowDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? station = null,Object? qty = null,Object? utilization = null,}) {
  return _then(_StationRowDto(
station: null == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,utilization: null == utilization ? _self.utilization : utilization // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ReservationStatsDto {

 int get booked; int get seated; int get noShow; int get cancelled;
/// Create a copy of ReservationStatsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReservationStatsDtoCopyWith<ReservationStatsDto> get copyWith => _$ReservationStatsDtoCopyWithImpl<ReservationStatsDto>(this as ReservationStatsDto, _$identity);

  /// Serializes this ReservationStatsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReservationStatsDto&&(identical(other.booked, booked) || other.booked == booked)&&(identical(other.seated, seated) || other.seated == seated)&&(identical(other.noShow, noShow) || other.noShow == noShow)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,booked,seated,noShow,cancelled);

@override
String toString() {
  return 'ReservationStatsDto(booked: $booked, seated: $seated, noShow: $noShow, cancelled: $cancelled)';
}


}

/// @nodoc
abstract mixin class $ReservationStatsDtoCopyWith<$Res>  {
  factory $ReservationStatsDtoCopyWith(ReservationStatsDto value, $Res Function(ReservationStatsDto) _then) = _$ReservationStatsDtoCopyWithImpl;
@useResult
$Res call({
 int booked, int seated, int noShow, int cancelled
});




}
/// @nodoc
class _$ReservationStatsDtoCopyWithImpl<$Res>
    implements $ReservationStatsDtoCopyWith<$Res> {
  _$ReservationStatsDtoCopyWithImpl(this._self, this._then);

  final ReservationStatsDto _self;
  final $Res Function(ReservationStatsDto) _then;

/// Create a copy of ReservationStatsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? booked = null,Object? seated = null,Object? noShow = null,Object? cancelled = null,}) {
  return _then(_self.copyWith(
booked: null == booked ? _self.booked : booked // ignore: cast_nullable_to_non_nullable
as int,seated: null == seated ? _self.seated : seated // ignore: cast_nullable_to_non_nullable
as int,noShow: null == noShow ? _self.noShow : noShow // ignore: cast_nullable_to_non_nullable
as int,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReservationStatsDto].
extension ReservationStatsDtoPatterns on ReservationStatsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReservationStatsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReservationStatsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReservationStatsDto value)  $default,){
final _that = this;
switch (_that) {
case _ReservationStatsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReservationStatsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ReservationStatsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int booked,  int seated,  int noShow,  int cancelled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReservationStatsDto() when $default != null:
return $default(_that.booked,_that.seated,_that.noShow,_that.cancelled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int booked,  int seated,  int noShow,  int cancelled)  $default,) {final _that = this;
switch (_that) {
case _ReservationStatsDto():
return $default(_that.booked,_that.seated,_that.noShow,_that.cancelled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int booked,  int seated,  int noShow,  int cancelled)?  $default,) {final _that = this;
switch (_that) {
case _ReservationStatsDto() when $default != null:
return $default(_that.booked,_that.seated,_that.noShow,_that.cancelled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReservationStatsDto implements ReservationStatsDto {
  const _ReservationStatsDto({this.booked = 0, this.seated = 0, this.noShow = 0, this.cancelled = 0});
  factory _ReservationStatsDto.fromJson(Map<String, dynamic> json) => _$ReservationStatsDtoFromJson(json);

@override@JsonKey() final  int booked;
@override@JsonKey() final  int seated;
@override@JsonKey() final  int noShow;
@override@JsonKey() final  int cancelled;

/// Create a copy of ReservationStatsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReservationStatsDtoCopyWith<_ReservationStatsDto> get copyWith => __$ReservationStatsDtoCopyWithImpl<_ReservationStatsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReservationStatsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReservationStatsDto&&(identical(other.booked, booked) || other.booked == booked)&&(identical(other.seated, seated) || other.seated == seated)&&(identical(other.noShow, noShow) || other.noShow == noShow)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,booked,seated,noShow,cancelled);

@override
String toString() {
  return 'ReservationStatsDto(booked: $booked, seated: $seated, noShow: $noShow, cancelled: $cancelled)';
}


}

/// @nodoc
abstract mixin class _$ReservationStatsDtoCopyWith<$Res> implements $ReservationStatsDtoCopyWith<$Res> {
  factory _$ReservationStatsDtoCopyWith(_ReservationStatsDto value, $Res Function(_ReservationStatsDto) _then) = __$ReservationStatsDtoCopyWithImpl;
@override @useResult
$Res call({
 int booked, int seated, int noShow, int cancelled
});




}
/// @nodoc
class __$ReservationStatsDtoCopyWithImpl<$Res>
    implements _$ReservationStatsDtoCopyWith<$Res> {
  __$ReservationStatsDtoCopyWithImpl(this._self, this._then);

  final _ReservationStatsDto _self;
  final $Res Function(_ReservationStatsDto) _then;

/// Create a copy of ReservationStatsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? booked = null,Object? seated = null,Object? noShow = null,Object? cancelled = null,}) {
  return _then(_ReservationStatsDto(
booked: null == booked ? _self.booked : booked // ignore: cast_nullable_to_non_nullable
as int,seated: null == seated ? _self.seated : seated // ignore: cast_nullable_to_non_nullable
as int,noShow: null == noShow ? _self.noShow : noShow // ignore: cast_nullable_to_non_nullable
as int,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$VoidReasonDto {

 String get code; String get label; int get count; int get lostRupiah;
/// Create a copy of VoidReasonDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoidReasonDtoCopyWith<VoidReasonDto> get copyWith => _$VoidReasonDtoCopyWithImpl<VoidReasonDto>(this as VoidReasonDto, _$identity);

  /// Serializes this VoidReasonDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoidReasonDto&&(identical(other.code, code) || other.code == code)&&(identical(other.label, label) || other.label == label)&&(identical(other.count, count) || other.count == count)&&(identical(other.lostRupiah, lostRupiah) || other.lostRupiah == lostRupiah));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,label,count,lostRupiah);

@override
String toString() {
  return 'VoidReasonDto(code: $code, label: $label, count: $count, lostRupiah: $lostRupiah)';
}


}

/// @nodoc
abstract mixin class $VoidReasonDtoCopyWith<$Res>  {
  factory $VoidReasonDtoCopyWith(VoidReasonDto value, $Res Function(VoidReasonDto) _then) = _$VoidReasonDtoCopyWithImpl;
@useResult
$Res call({
 String code, String label, int count, int lostRupiah
});




}
/// @nodoc
class _$VoidReasonDtoCopyWithImpl<$Res>
    implements $VoidReasonDtoCopyWith<$Res> {
  _$VoidReasonDtoCopyWithImpl(this._self, this._then);

  final VoidReasonDto _self;
  final $Res Function(VoidReasonDto) _then;

/// Create a copy of VoidReasonDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? label = null,Object? count = null,Object? lostRupiah = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,lostRupiah: null == lostRupiah ? _self.lostRupiah : lostRupiah // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VoidReasonDto].
extension VoidReasonDtoPatterns on VoidReasonDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoidReasonDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoidReasonDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoidReasonDto value)  $default,){
final _that = this;
switch (_that) {
case _VoidReasonDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoidReasonDto value)?  $default,){
final _that = this;
switch (_that) {
case _VoidReasonDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String label,  int count,  int lostRupiah)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoidReasonDto() when $default != null:
return $default(_that.code,_that.label,_that.count,_that.lostRupiah);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String label,  int count,  int lostRupiah)  $default,) {final _that = this;
switch (_that) {
case _VoidReasonDto():
return $default(_that.code,_that.label,_that.count,_that.lostRupiah);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String label,  int count,  int lostRupiah)?  $default,) {final _that = this;
switch (_that) {
case _VoidReasonDto() when $default != null:
return $default(_that.code,_that.label,_that.count,_that.lostRupiah);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VoidReasonDto implements VoidReasonDto {
  const _VoidReasonDto({required this.code, this.label = '', this.count = 0, this.lostRupiah = 0});
  factory _VoidReasonDto.fromJson(Map<String, dynamic> json) => _$VoidReasonDtoFromJson(json);

@override final  String code;
@override@JsonKey() final  String label;
@override@JsonKey() final  int count;
@override@JsonKey() final  int lostRupiah;

/// Create a copy of VoidReasonDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoidReasonDtoCopyWith<_VoidReasonDto> get copyWith => __$VoidReasonDtoCopyWithImpl<_VoidReasonDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VoidReasonDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoidReasonDto&&(identical(other.code, code) || other.code == code)&&(identical(other.label, label) || other.label == label)&&(identical(other.count, count) || other.count == count)&&(identical(other.lostRupiah, lostRupiah) || other.lostRupiah == lostRupiah));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,label,count,lostRupiah);

@override
String toString() {
  return 'VoidReasonDto(code: $code, label: $label, count: $count, lostRupiah: $lostRupiah)';
}


}

/// @nodoc
abstract mixin class _$VoidReasonDtoCopyWith<$Res> implements $VoidReasonDtoCopyWith<$Res> {
  factory _$VoidReasonDtoCopyWith(_VoidReasonDto value, $Res Function(_VoidReasonDto) _then) = __$VoidReasonDtoCopyWithImpl;
@override @useResult
$Res call({
 String code, String label, int count, int lostRupiah
});




}
/// @nodoc
class __$VoidReasonDtoCopyWithImpl<$Res>
    implements _$VoidReasonDtoCopyWith<$Res> {
  __$VoidReasonDtoCopyWithImpl(this._self, this._then);

  final _VoidReasonDto _self;
  final $Res Function(_VoidReasonDto) _then;

/// Create a copy of VoidReasonDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? label = null,Object? count = null,Object? lostRupiah = null,}) {
  return _then(_VoidReasonDto(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,lostRupiah: null == lostRupiah ? _self.lostRupiah : lostRupiah // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$KasSectionDto {

 int get opening; int get inflow; int get outflow; int get variance; int get closing; Map<String, int> get byCategory;/// Movements in the window. Zero is what the empty line keys off — a box
/// with a balance and no movements is still nothing to report on.
 int get count;
/// Create a copy of KasSectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KasSectionDtoCopyWith<KasSectionDto> get copyWith => _$KasSectionDtoCopyWithImpl<KasSectionDto>(this as KasSectionDto, _$identity);

  /// Serializes this KasSectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KasSectionDto&&(identical(other.opening, opening) || other.opening == opening)&&(identical(other.inflow, inflow) || other.inflow == inflow)&&(identical(other.outflow, outflow) || other.outflow == outflow)&&(identical(other.variance, variance) || other.variance == variance)&&(identical(other.closing, closing) || other.closing == closing)&&const DeepCollectionEquality().equals(other.byCategory, byCategory)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,opening,inflow,outflow,variance,closing,const DeepCollectionEquality().hash(byCategory),count);

@override
String toString() {
  return 'KasSectionDto(opening: $opening, inflow: $inflow, outflow: $outflow, variance: $variance, closing: $closing, byCategory: $byCategory, count: $count)';
}


}

/// @nodoc
abstract mixin class $KasSectionDtoCopyWith<$Res>  {
  factory $KasSectionDtoCopyWith(KasSectionDto value, $Res Function(KasSectionDto) _then) = _$KasSectionDtoCopyWithImpl;
@useResult
$Res call({
 int opening, int inflow, int outflow, int variance, int closing, Map<String, int> byCategory, int count
});




}
/// @nodoc
class _$KasSectionDtoCopyWithImpl<$Res>
    implements $KasSectionDtoCopyWith<$Res> {
  _$KasSectionDtoCopyWithImpl(this._self, this._then);

  final KasSectionDto _self;
  final $Res Function(KasSectionDto) _then;

/// Create a copy of KasSectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? opening = null,Object? inflow = null,Object? outflow = null,Object? variance = null,Object? closing = null,Object? byCategory = null,Object? count = null,}) {
  return _then(_self.copyWith(
opening: null == opening ? _self.opening : opening // ignore: cast_nullable_to_non_nullable
as int,inflow: null == inflow ? _self.inflow : inflow // ignore: cast_nullable_to_non_nullable
as int,outflow: null == outflow ? _self.outflow : outflow // ignore: cast_nullable_to_non_nullable
as int,variance: null == variance ? _self.variance : variance // ignore: cast_nullable_to_non_nullable
as int,closing: null == closing ? _self.closing : closing // ignore: cast_nullable_to_non_nullable
as int,byCategory: null == byCategory ? _self.byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as Map<String, int>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [KasSectionDto].
extension KasSectionDtoPatterns on KasSectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KasSectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KasSectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KasSectionDto value)  $default,){
final _that = this;
switch (_that) {
case _KasSectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KasSectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _KasSectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int opening,  int inflow,  int outflow,  int variance,  int closing,  Map<String, int> byCategory,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KasSectionDto() when $default != null:
return $default(_that.opening,_that.inflow,_that.outflow,_that.variance,_that.closing,_that.byCategory,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int opening,  int inflow,  int outflow,  int variance,  int closing,  Map<String, int> byCategory,  int count)  $default,) {final _that = this;
switch (_that) {
case _KasSectionDto():
return $default(_that.opening,_that.inflow,_that.outflow,_that.variance,_that.closing,_that.byCategory,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int opening,  int inflow,  int outflow,  int variance,  int closing,  Map<String, int> byCategory,  int count)?  $default,) {final _that = this;
switch (_that) {
case _KasSectionDto() when $default != null:
return $default(_that.opening,_that.inflow,_that.outflow,_that.variance,_that.closing,_that.byCategory,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KasSectionDto implements KasSectionDto {
  const _KasSectionDto({this.opening = 0, this.inflow = 0, this.outflow = 0, this.variance = 0, this.closing = 0, final  Map<String, int> byCategory = const <String, int>{}, this.count = 0}): _byCategory = byCategory;
  factory _KasSectionDto.fromJson(Map<String, dynamic> json) => _$KasSectionDtoFromJson(json);

@override@JsonKey() final  int opening;
@override@JsonKey() final  int inflow;
@override@JsonKey() final  int outflow;
@override@JsonKey() final  int variance;
@override@JsonKey() final  int closing;
 final  Map<String, int> _byCategory;
@override@JsonKey() Map<String, int> get byCategory {
  if (_byCategory is EqualUnmodifiableMapView) return _byCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_byCategory);
}

/// Movements in the window. Zero is what the empty line keys off — a box
/// with a balance and no movements is still nothing to report on.
@override@JsonKey() final  int count;

/// Create a copy of KasSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KasSectionDtoCopyWith<_KasSectionDto> get copyWith => __$KasSectionDtoCopyWithImpl<_KasSectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KasSectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KasSectionDto&&(identical(other.opening, opening) || other.opening == opening)&&(identical(other.inflow, inflow) || other.inflow == inflow)&&(identical(other.outflow, outflow) || other.outflow == outflow)&&(identical(other.variance, variance) || other.variance == variance)&&(identical(other.closing, closing) || other.closing == closing)&&const DeepCollectionEquality().equals(other._byCategory, _byCategory)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,opening,inflow,outflow,variance,closing,const DeepCollectionEquality().hash(_byCategory),count);

@override
String toString() {
  return 'KasSectionDto(opening: $opening, inflow: $inflow, outflow: $outflow, variance: $variance, closing: $closing, byCategory: $byCategory, count: $count)';
}


}

/// @nodoc
abstract mixin class _$KasSectionDtoCopyWith<$Res> implements $KasSectionDtoCopyWith<$Res> {
  factory _$KasSectionDtoCopyWith(_KasSectionDto value, $Res Function(_KasSectionDto) _then) = __$KasSectionDtoCopyWithImpl;
@override @useResult
$Res call({
 int opening, int inflow, int outflow, int variance, int closing, Map<String, int> byCategory, int count
});




}
/// @nodoc
class __$KasSectionDtoCopyWithImpl<$Res>
    implements _$KasSectionDtoCopyWith<$Res> {
  __$KasSectionDtoCopyWithImpl(this._self, this._then);

  final _KasSectionDto _self;
  final $Res Function(_KasSectionDto) _then;

/// Create a copy of KasSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? opening = null,Object? inflow = null,Object? outflow = null,Object? variance = null,Object? closing = null,Object? byCategory = null,Object? count = null,}) {
  return _then(_KasSectionDto(
opening: null == opening ? _self.opening : opening // ignore: cast_nullable_to_non_nullable
as int,inflow: null == inflow ? _self.inflow : inflow // ignore: cast_nullable_to_non_nullable
as int,outflow: null == outflow ? _self.outflow : outflow // ignore: cast_nullable_to_non_nullable
as int,variance: null == variance ? _self.variance : variance // ignore: cast_nullable_to_non_nullable
as int,closing: null == closing ? _self.closing : closing // ignore: cast_nullable_to_non_nullable
as int,byCategory: null == byCategory ? _self._byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as Map<String, int>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$JamKerjaSectionDto {

 List<JamKerjaRowDto> get staff;/// The venue's rollover hour, so the screen can turn [
/// JamKerjaRowDto.medianFirstIn] back into a clock time.
 int get dayStartHour;/// Shifts nobody signed out of, across everyone. The section's headline
/// caveat: a venue with a high number here is not reading real hours.
 int get unclosed;
/// Create a copy of JamKerjaSectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JamKerjaSectionDtoCopyWith<JamKerjaSectionDto> get copyWith => _$JamKerjaSectionDtoCopyWithImpl<JamKerjaSectionDto>(this as JamKerjaSectionDto, _$identity);

  /// Serializes this JamKerjaSectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JamKerjaSectionDto&&const DeepCollectionEquality().equals(other.staff, staff)&&(identical(other.dayStartHour, dayStartHour) || other.dayStartHour == dayStartHour)&&(identical(other.unclosed, unclosed) || other.unclosed == unclosed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(staff),dayStartHour,unclosed);

@override
String toString() {
  return 'JamKerjaSectionDto(staff: $staff, dayStartHour: $dayStartHour, unclosed: $unclosed)';
}


}

/// @nodoc
abstract mixin class $JamKerjaSectionDtoCopyWith<$Res>  {
  factory $JamKerjaSectionDtoCopyWith(JamKerjaSectionDto value, $Res Function(JamKerjaSectionDto) _then) = _$JamKerjaSectionDtoCopyWithImpl;
@useResult
$Res call({
 List<JamKerjaRowDto> staff, int dayStartHour, int unclosed
});




}
/// @nodoc
class _$JamKerjaSectionDtoCopyWithImpl<$Res>
    implements $JamKerjaSectionDtoCopyWith<$Res> {
  _$JamKerjaSectionDtoCopyWithImpl(this._self, this._then);

  final JamKerjaSectionDto _self;
  final $Res Function(JamKerjaSectionDto) _then;

/// Create a copy of JamKerjaSectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? staff = null,Object? dayStartHour = null,Object? unclosed = null,}) {
  return _then(_self.copyWith(
staff: null == staff ? _self.staff : staff // ignore: cast_nullable_to_non_nullable
as List<JamKerjaRowDto>,dayStartHour: null == dayStartHour ? _self.dayStartHour : dayStartHour // ignore: cast_nullable_to_non_nullable
as int,unclosed: null == unclosed ? _self.unclosed : unclosed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [JamKerjaSectionDto].
extension JamKerjaSectionDtoPatterns on JamKerjaSectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JamKerjaSectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JamKerjaSectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JamKerjaSectionDto value)  $default,){
final _that = this;
switch (_that) {
case _JamKerjaSectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JamKerjaSectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _JamKerjaSectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<JamKerjaRowDto> staff,  int dayStartHour,  int unclosed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JamKerjaSectionDto() when $default != null:
return $default(_that.staff,_that.dayStartHour,_that.unclosed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<JamKerjaRowDto> staff,  int dayStartHour,  int unclosed)  $default,) {final _that = this;
switch (_that) {
case _JamKerjaSectionDto():
return $default(_that.staff,_that.dayStartHour,_that.unclosed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<JamKerjaRowDto> staff,  int dayStartHour,  int unclosed)?  $default,) {final _that = this;
switch (_that) {
case _JamKerjaSectionDto() when $default != null:
return $default(_that.staff,_that.dayStartHour,_that.unclosed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JamKerjaSectionDto implements JamKerjaSectionDto {
  const _JamKerjaSectionDto({final  List<JamKerjaRowDto> staff = const <JamKerjaRowDto>[], this.dayStartHour = 4, this.unclosed = 0}): _staff = staff;
  factory _JamKerjaSectionDto.fromJson(Map<String, dynamic> json) => _$JamKerjaSectionDtoFromJson(json);

 final  List<JamKerjaRowDto> _staff;
@override@JsonKey() List<JamKerjaRowDto> get staff {
  if (_staff is EqualUnmodifiableListView) return _staff;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_staff);
}

/// The venue's rollover hour, so the screen can turn [
/// JamKerjaRowDto.medianFirstIn] back into a clock time.
@override@JsonKey() final  int dayStartHour;
/// Shifts nobody signed out of, across everyone. The section's headline
/// caveat: a venue with a high number here is not reading real hours.
@override@JsonKey() final  int unclosed;

/// Create a copy of JamKerjaSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JamKerjaSectionDtoCopyWith<_JamKerjaSectionDto> get copyWith => __$JamKerjaSectionDtoCopyWithImpl<_JamKerjaSectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JamKerjaSectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JamKerjaSectionDto&&const DeepCollectionEquality().equals(other._staff, _staff)&&(identical(other.dayStartHour, dayStartHour) || other.dayStartHour == dayStartHour)&&(identical(other.unclosed, unclosed) || other.unclosed == unclosed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_staff),dayStartHour,unclosed);

@override
String toString() {
  return 'JamKerjaSectionDto(staff: $staff, dayStartHour: $dayStartHour, unclosed: $unclosed)';
}


}

/// @nodoc
abstract mixin class _$JamKerjaSectionDtoCopyWith<$Res> implements $JamKerjaSectionDtoCopyWith<$Res> {
  factory _$JamKerjaSectionDtoCopyWith(_JamKerjaSectionDto value, $Res Function(_JamKerjaSectionDto) _then) = __$JamKerjaSectionDtoCopyWithImpl;
@override @useResult
$Res call({
 List<JamKerjaRowDto> staff, int dayStartHour, int unclosed
});




}
/// @nodoc
class __$JamKerjaSectionDtoCopyWithImpl<$Res>
    implements _$JamKerjaSectionDtoCopyWith<$Res> {
  __$JamKerjaSectionDtoCopyWithImpl(this._self, this._then);

  final _JamKerjaSectionDto _self;
  final $Res Function(_JamKerjaSectionDto) _then;

/// Create a copy of JamKerjaSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? staff = null,Object? dayStartHour = null,Object? unclosed = null,}) {
  return _then(_JamKerjaSectionDto(
staff: null == staff ? _self._staff : staff // ignore: cast_nullable_to_non_nullable
as List<JamKerjaRowDto>,dayStartHour: null == dayStartHour ? _self.dayStartHour : dayStartHour // ignore: cast_nullable_to_non_nullable
as int,unclosed: null == unclosed ? _self.unclosed : unclosed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$JamKerjaRowDto {

 String get id; String get name;/// Minutes actually worked — closed shifts only.
 int get minutes; int get shifts;/// Distinct business days with at least one shift. Lower than [shifts]
/// whenever a day was split by a handover.
 int get days; int get unclosed;/// Median minutes **after the venue's rollover** that this person clocked
/// in — not a wall clock, so it compares across venues with different
/// business-day starts. Null when they never clocked in.
 int? get medianFirstIn;/// The last thing an unclosed shift of theirs actually did. The honest
/// answer to "when did they really stop"; null when nothing they did in it
/// was auditable.
 String? get lastSeen;
/// Create a copy of JamKerjaRowDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JamKerjaRowDtoCopyWith<JamKerjaRowDto> get copyWith => _$JamKerjaRowDtoCopyWithImpl<JamKerjaRowDto>(this as JamKerjaRowDto, _$identity);

  /// Serializes this JamKerjaRowDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JamKerjaRowDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.minutes, minutes) || other.minutes == minutes)&&(identical(other.shifts, shifts) || other.shifts == shifts)&&(identical(other.days, days) || other.days == days)&&(identical(other.unclosed, unclosed) || other.unclosed == unclosed)&&(identical(other.medianFirstIn, medianFirstIn) || other.medianFirstIn == medianFirstIn)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,minutes,shifts,days,unclosed,medianFirstIn,lastSeen);

@override
String toString() {
  return 'JamKerjaRowDto(id: $id, name: $name, minutes: $minutes, shifts: $shifts, days: $days, unclosed: $unclosed, medianFirstIn: $medianFirstIn, lastSeen: $lastSeen)';
}


}

/// @nodoc
abstract mixin class $JamKerjaRowDtoCopyWith<$Res>  {
  factory $JamKerjaRowDtoCopyWith(JamKerjaRowDto value, $Res Function(JamKerjaRowDto) _then) = _$JamKerjaRowDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, int minutes, int shifts, int days, int unclosed, int? medianFirstIn, String? lastSeen
});




}
/// @nodoc
class _$JamKerjaRowDtoCopyWithImpl<$Res>
    implements $JamKerjaRowDtoCopyWith<$Res> {
  _$JamKerjaRowDtoCopyWithImpl(this._self, this._then);

  final JamKerjaRowDto _self;
  final $Res Function(JamKerjaRowDto) _then;

/// Create a copy of JamKerjaRowDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? minutes = null,Object? shifts = null,Object? days = null,Object? unclosed = null,Object? medianFirstIn = freezed,Object? lastSeen = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,shifts: null == shifts ? _self.shifts : shifts // ignore: cast_nullable_to_non_nullable
as int,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,unclosed: null == unclosed ? _self.unclosed : unclosed // ignore: cast_nullable_to_non_nullable
as int,medianFirstIn: freezed == medianFirstIn ? _self.medianFirstIn : medianFirstIn // ignore: cast_nullable_to_non_nullable
as int?,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [JamKerjaRowDto].
extension JamKerjaRowDtoPatterns on JamKerjaRowDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JamKerjaRowDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JamKerjaRowDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JamKerjaRowDto value)  $default,){
final _that = this;
switch (_that) {
case _JamKerjaRowDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JamKerjaRowDto value)?  $default,){
final _that = this;
switch (_that) {
case _JamKerjaRowDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int minutes,  int shifts,  int days,  int unclosed,  int? medianFirstIn,  String? lastSeen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JamKerjaRowDto() when $default != null:
return $default(_that.id,_that.name,_that.minutes,_that.shifts,_that.days,_that.unclosed,_that.medianFirstIn,_that.lastSeen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int minutes,  int shifts,  int days,  int unclosed,  int? medianFirstIn,  String? lastSeen)  $default,) {final _that = this;
switch (_that) {
case _JamKerjaRowDto():
return $default(_that.id,_that.name,_that.minutes,_that.shifts,_that.days,_that.unclosed,_that.medianFirstIn,_that.lastSeen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int minutes,  int shifts,  int days,  int unclosed,  int? medianFirstIn,  String? lastSeen)?  $default,) {final _that = this;
switch (_that) {
case _JamKerjaRowDto() when $default != null:
return $default(_that.id,_that.name,_that.minutes,_that.shifts,_that.days,_that.unclosed,_that.medianFirstIn,_that.lastSeen);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JamKerjaRowDto implements JamKerjaRowDto {
  const _JamKerjaRowDto({required this.id, required this.name, this.minutes = 0, this.shifts = 0, this.days = 0, this.unclosed = 0, this.medianFirstIn, this.lastSeen});
  factory _JamKerjaRowDto.fromJson(Map<String, dynamic> json) => _$JamKerjaRowDtoFromJson(json);

@override final  String id;
@override final  String name;
/// Minutes actually worked — closed shifts only.
@override@JsonKey() final  int minutes;
@override@JsonKey() final  int shifts;
/// Distinct business days with at least one shift. Lower than [shifts]
/// whenever a day was split by a handover.
@override@JsonKey() final  int days;
@override@JsonKey() final  int unclosed;
/// Median minutes **after the venue's rollover** that this person clocked
/// in — not a wall clock, so it compares across venues with different
/// business-day starts. Null when they never clocked in.
@override final  int? medianFirstIn;
/// The last thing an unclosed shift of theirs actually did. The honest
/// answer to "when did they really stop"; null when nothing they did in it
/// was auditable.
@override final  String? lastSeen;

/// Create a copy of JamKerjaRowDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JamKerjaRowDtoCopyWith<_JamKerjaRowDto> get copyWith => __$JamKerjaRowDtoCopyWithImpl<_JamKerjaRowDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JamKerjaRowDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JamKerjaRowDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.minutes, minutes) || other.minutes == minutes)&&(identical(other.shifts, shifts) || other.shifts == shifts)&&(identical(other.days, days) || other.days == days)&&(identical(other.unclosed, unclosed) || other.unclosed == unclosed)&&(identical(other.medianFirstIn, medianFirstIn) || other.medianFirstIn == medianFirstIn)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,minutes,shifts,days,unclosed,medianFirstIn,lastSeen);

@override
String toString() {
  return 'JamKerjaRowDto(id: $id, name: $name, minutes: $minutes, shifts: $shifts, days: $days, unclosed: $unclosed, medianFirstIn: $medianFirstIn, lastSeen: $lastSeen)';
}


}

/// @nodoc
abstract mixin class _$JamKerjaRowDtoCopyWith<$Res> implements $JamKerjaRowDtoCopyWith<$Res> {
  factory _$JamKerjaRowDtoCopyWith(_JamKerjaRowDto value, $Res Function(_JamKerjaRowDto) _then) = __$JamKerjaRowDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int minutes, int shifts, int days, int unclosed, int? medianFirstIn, String? lastSeen
});




}
/// @nodoc
class __$JamKerjaRowDtoCopyWithImpl<$Res>
    implements _$JamKerjaRowDtoCopyWith<$Res> {
  __$JamKerjaRowDtoCopyWithImpl(this._self, this._then);

  final _JamKerjaRowDto _self;
  final $Res Function(_JamKerjaRowDto) _then;

/// Create a copy of JamKerjaRowDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? minutes = null,Object? shifts = null,Object? days = null,Object? unclosed = null,Object? medianFirstIn = freezed,Object? lastSeen = freezed,}) {
  return _then(_JamKerjaRowDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,shifts: null == shifts ? _self.shifts : shifts // ignore: cast_nullable_to_non_nullable
as int,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,unclosed: null == unclosed ? _self.unclosed : unclosed // ignore: cast_nullable_to_non_nullable
as int,medianFirstIn: freezed == medianFirstIn ? _self.medianFirstIn : medianFirstIn // ignore: cast_nullable_to_non_nullable
as int?,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MembersSectionDto {

/// False ⇒ the venue does not run a program, and the section is not drawn.
 bool get enabled;/// The points program runs (or not) independently of membership. False ⇒
/// the points figures and the ranked list's points column are **hidden**,
/// not zeroed — a zero says "earned nothing", which is a different and
/// false statement from "this venue does not run points".
 bool get pointsEnabled; int get enrolled; int get activeMembers; int get memberBills;/// Bills in this window that carried more than one member (ADR-0118).
///
/// Zero at a venue that never held the mode, and the marker that lets the
/// section say a window spanning the switch is showing two shapes: before
/// it, a bill counts once for its owner; after it, a share counts for
/// whoever it was for.
 int get splitBills;/// Whether the venue may name a member per share *now*. Independent of
/// [splitBills], which is history: switching the mode off freezes what was
/// attributed rather than deleting it (ADR-0118 §6), so a closed month
/// keeps its numbers and this goes false.
 bool get splitEnabled; int get memberNet; int get guestBills; int get guestNet; int get avgMemberBill; int get avgGuestBill; int get pointsEarned; int get pointsRedeemed; int get pointsAdjusted; int get pointsOutstanding;/// Rupiah the outstanding points would cost at today's rate. An estimate by
/// construction — the rate can move before they are spent.
 int get liabilityEstimate; List<MemberTopRowDto> get top;/// Members who traded in the window beyond the end of [top]. Shown as a
/// tail count, so the hundredth name never reads as the last one.
 int get topTruncated;
/// Create a copy of MembersSectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembersSectionDtoCopyWith<MembersSectionDto> get copyWith => _$MembersSectionDtoCopyWithImpl<MembersSectionDto>(this as MembersSectionDto, _$identity);

  /// Serializes this MembersSectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembersSectionDto&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.pointsEnabled, pointsEnabled) || other.pointsEnabled == pointsEnabled)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.activeMembers, activeMembers) || other.activeMembers == activeMembers)&&(identical(other.memberBills, memberBills) || other.memberBills == memberBills)&&(identical(other.splitBills, splitBills) || other.splitBills == splitBills)&&(identical(other.splitEnabled, splitEnabled) || other.splitEnabled == splitEnabled)&&(identical(other.memberNet, memberNet) || other.memberNet == memberNet)&&(identical(other.guestBills, guestBills) || other.guestBills == guestBills)&&(identical(other.guestNet, guestNet) || other.guestNet == guestNet)&&(identical(other.avgMemberBill, avgMemberBill) || other.avgMemberBill == avgMemberBill)&&(identical(other.avgGuestBill, avgGuestBill) || other.avgGuestBill == avgGuestBill)&&(identical(other.pointsEarned, pointsEarned) || other.pointsEarned == pointsEarned)&&(identical(other.pointsRedeemed, pointsRedeemed) || other.pointsRedeemed == pointsRedeemed)&&(identical(other.pointsAdjusted, pointsAdjusted) || other.pointsAdjusted == pointsAdjusted)&&(identical(other.pointsOutstanding, pointsOutstanding) || other.pointsOutstanding == pointsOutstanding)&&(identical(other.liabilityEstimate, liabilityEstimate) || other.liabilityEstimate == liabilityEstimate)&&const DeepCollectionEquality().equals(other.top, top)&&(identical(other.topTruncated, topTruncated) || other.topTruncated == topTruncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,enabled,pointsEnabled,enrolled,activeMembers,memberBills,splitBills,splitEnabled,memberNet,guestBills,guestNet,avgMemberBill,avgGuestBill,pointsEarned,pointsRedeemed,pointsAdjusted,pointsOutstanding,liabilityEstimate,const DeepCollectionEquality().hash(top),topTruncated]);

@override
String toString() {
  return 'MembersSectionDto(enabled: $enabled, pointsEnabled: $pointsEnabled, enrolled: $enrolled, activeMembers: $activeMembers, memberBills: $memberBills, splitBills: $splitBills, splitEnabled: $splitEnabled, memberNet: $memberNet, guestBills: $guestBills, guestNet: $guestNet, avgMemberBill: $avgMemberBill, avgGuestBill: $avgGuestBill, pointsEarned: $pointsEarned, pointsRedeemed: $pointsRedeemed, pointsAdjusted: $pointsAdjusted, pointsOutstanding: $pointsOutstanding, liabilityEstimate: $liabilityEstimate, top: $top, topTruncated: $topTruncated)';
}


}

/// @nodoc
abstract mixin class $MembersSectionDtoCopyWith<$Res>  {
  factory $MembersSectionDtoCopyWith(MembersSectionDto value, $Res Function(MembersSectionDto) _then) = _$MembersSectionDtoCopyWithImpl;
@useResult
$Res call({
 bool enabled, bool pointsEnabled, int enrolled, int activeMembers, int memberBills, int splitBills, bool splitEnabled, int memberNet, int guestBills, int guestNet, int avgMemberBill, int avgGuestBill, int pointsEarned, int pointsRedeemed, int pointsAdjusted, int pointsOutstanding, int liabilityEstimate, List<MemberTopRowDto> top, int topTruncated
});




}
/// @nodoc
class _$MembersSectionDtoCopyWithImpl<$Res>
    implements $MembersSectionDtoCopyWith<$Res> {
  _$MembersSectionDtoCopyWithImpl(this._self, this._then);

  final MembersSectionDto _self;
  final $Res Function(MembersSectionDto) _then;

/// Create a copy of MembersSectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? pointsEnabled = null,Object? enrolled = null,Object? activeMembers = null,Object? memberBills = null,Object? splitBills = null,Object? splitEnabled = null,Object? memberNet = null,Object? guestBills = null,Object? guestNet = null,Object? avgMemberBill = null,Object? avgGuestBill = null,Object? pointsEarned = null,Object? pointsRedeemed = null,Object? pointsAdjusted = null,Object? pointsOutstanding = null,Object? liabilityEstimate = null,Object? top = null,Object? topTruncated = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,pointsEnabled: null == pointsEnabled ? _self.pointsEnabled : pointsEnabled // ignore: cast_nullable_to_non_nullable
as bool,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,activeMembers: null == activeMembers ? _self.activeMembers : activeMembers // ignore: cast_nullable_to_non_nullable
as int,memberBills: null == memberBills ? _self.memberBills : memberBills // ignore: cast_nullable_to_non_nullable
as int,splitBills: null == splitBills ? _self.splitBills : splitBills // ignore: cast_nullable_to_non_nullable
as int,splitEnabled: null == splitEnabled ? _self.splitEnabled : splitEnabled // ignore: cast_nullable_to_non_nullable
as bool,memberNet: null == memberNet ? _self.memberNet : memberNet // ignore: cast_nullable_to_non_nullable
as int,guestBills: null == guestBills ? _self.guestBills : guestBills // ignore: cast_nullable_to_non_nullable
as int,guestNet: null == guestNet ? _self.guestNet : guestNet // ignore: cast_nullable_to_non_nullable
as int,avgMemberBill: null == avgMemberBill ? _self.avgMemberBill : avgMemberBill // ignore: cast_nullable_to_non_nullable
as int,avgGuestBill: null == avgGuestBill ? _self.avgGuestBill : avgGuestBill // ignore: cast_nullable_to_non_nullable
as int,pointsEarned: null == pointsEarned ? _self.pointsEarned : pointsEarned // ignore: cast_nullable_to_non_nullable
as int,pointsRedeemed: null == pointsRedeemed ? _self.pointsRedeemed : pointsRedeemed // ignore: cast_nullable_to_non_nullable
as int,pointsAdjusted: null == pointsAdjusted ? _self.pointsAdjusted : pointsAdjusted // ignore: cast_nullable_to_non_nullable
as int,pointsOutstanding: null == pointsOutstanding ? _self.pointsOutstanding : pointsOutstanding // ignore: cast_nullable_to_non_nullable
as int,liabilityEstimate: null == liabilityEstimate ? _self.liabilityEstimate : liabilityEstimate // ignore: cast_nullable_to_non_nullable
as int,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as List<MemberTopRowDto>,topTruncated: null == topTruncated ? _self.topTruncated : topTruncated // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MembersSectionDto].
extension MembersSectionDtoPatterns on MembersSectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MembersSectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MembersSectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MembersSectionDto value)  $default,){
final _that = this;
switch (_that) {
case _MembersSectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MembersSectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _MembersSectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  bool pointsEnabled,  int enrolled,  int activeMembers,  int memberBills,  int splitBills,  bool splitEnabled,  int memberNet,  int guestBills,  int guestNet,  int avgMemberBill,  int avgGuestBill,  int pointsEarned,  int pointsRedeemed,  int pointsAdjusted,  int pointsOutstanding,  int liabilityEstimate,  List<MemberTopRowDto> top,  int topTruncated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MembersSectionDto() when $default != null:
return $default(_that.enabled,_that.pointsEnabled,_that.enrolled,_that.activeMembers,_that.memberBills,_that.splitBills,_that.splitEnabled,_that.memberNet,_that.guestBills,_that.guestNet,_that.avgMemberBill,_that.avgGuestBill,_that.pointsEarned,_that.pointsRedeemed,_that.pointsAdjusted,_that.pointsOutstanding,_that.liabilityEstimate,_that.top,_that.topTruncated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  bool pointsEnabled,  int enrolled,  int activeMembers,  int memberBills,  int splitBills,  bool splitEnabled,  int memberNet,  int guestBills,  int guestNet,  int avgMemberBill,  int avgGuestBill,  int pointsEarned,  int pointsRedeemed,  int pointsAdjusted,  int pointsOutstanding,  int liabilityEstimate,  List<MemberTopRowDto> top,  int topTruncated)  $default,) {final _that = this;
switch (_that) {
case _MembersSectionDto():
return $default(_that.enabled,_that.pointsEnabled,_that.enrolled,_that.activeMembers,_that.memberBills,_that.splitBills,_that.splitEnabled,_that.memberNet,_that.guestBills,_that.guestNet,_that.avgMemberBill,_that.avgGuestBill,_that.pointsEarned,_that.pointsRedeemed,_that.pointsAdjusted,_that.pointsOutstanding,_that.liabilityEstimate,_that.top,_that.topTruncated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  bool pointsEnabled,  int enrolled,  int activeMembers,  int memberBills,  int splitBills,  bool splitEnabled,  int memberNet,  int guestBills,  int guestNet,  int avgMemberBill,  int avgGuestBill,  int pointsEarned,  int pointsRedeemed,  int pointsAdjusted,  int pointsOutstanding,  int liabilityEstimate,  List<MemberTopRowDto> top,  int topTruncated)?  $default,) {final _that = this;
switch (_that) {
case _MembersSectionDto() when $default != null:
return $default(_that.enabled,_that.pointsEnabled,_that.enrolled,_that.activeMembers,_that.memberBills,_that.splitBills,_that.splitEnabled,_that.memberNet,_that.guestBills,_that.guestNet,_that.avgMemberBill,_that.avgGuestBill,_that.pointsEarned,_that.pointsRedeemed,_that.pointsAdjusted,_that.pointsOutstanding,_that.liabilityEstimate,_that.top,_that.topTruncated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MembersSectionDto implements MembersSectionDto {
  const _MembersSectionDto({this.enabled = false, this.pointsEnabled = false, this.enrolled = 0, this.activeMembers = 0, this.memberBills = 0, this.splitBills = 0, this.splitEnabled = false, this.memberNet = 0, this.guestBills = 0, this.guestNet = 0, this.avgMemberBill = 0, this.avgGuestBill = 0, this.pointsEarned = 0, this.pointsRedeemed = 0, this.pointsAdjusted = 0, this.pointsOutstanding = 0, this.liabilityEstimate = 0, final  List<MemberTopRowDto> top = const <MemberTopRowDto>[], this.topTruncated = 0}): _top = top;
  factory _MembersSectionDto.fromJson(Map<String, dynamic> json) => _$MembersSectionDtoFromJson(json);

/// False ⇒ the venue does not run a program, and the section is not drawn.
@override@JsonKey() final  bool enabled;
/// The points program runs (or not) independently of membership. False ⇒
/// the points figures and the ranked list's points column are **hidden**,
/// not zeroed — a zero says "earned nothing", which is a different and
/// false statement from "this venue does not run points".
@override@JsonKey() final  bool pointsEnabled;
@override@JsonKey() final  int enrolled;
@override@JsonKey() final  int activeMembers;
@override@JsonKey() final  int memberBills;
/// Bills in this window that carried more than one member (ADR-0118).
///
/// Zero at a venue that never held the mode, and the marker that lets the
/// section say a window spanning the switch is showing two shapes: before
/// it, a bill counts once for its owner; after it, a share counts for
/// whoever it was for.
@override@JsonKey() final  int splitBills;
/// Whether the venue may name a member per share *now*. Independent of
/// [splitBills], which is history: switching the mode off freezes what was
/// attributed rather than deleting it (ADR-0118 §6), so a closed month
/// keeps its numbers and this goes false.
@override@JsonKey() final  bool splitEnabled;
@override@JsonKey() final  int memberNet;
@override@JsonKey() final  int guestBills;
@override@JsonKey() final  int guestNet;
@override@JsonKey() final  int avgMemberBill;
@override@JsonKey() final  int avgGuestBill;
@override@JsonKey() final  int pointsEarned;
@override@JsonKey() final  int pointsRedeemed;
@override@JsonKey() final  int pointsAdjusted;
@override@JsonKey() final  int pointsOutstanding;
/// Rupiah the outstanding points would cost at today's rate. An estimate by
/// construction — the rate can move before they are spent.
@override@JsonKey() final  int liabilityEstimate;
 final  List<MemberTopRowDto> _top;
@override@JsonKey() List<MemberTopRowDto> get top {
  if (_top is EqualUnmodifiableListView) return _top;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_top);
}

/// Members who traded in the window beyond the end of [top]. Shown as a
/// tail count, so the hundredth name never reads as the last one.
@override@JsonKey() final  int topTruncated;

/// Create a copy of MembersSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembersSectionDtoCopyWith<_MembersSectionDto> get copyWith => __$MembersSectionDtoCopyWithImpl<_MembersSectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembersSectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MembersSectionDto&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.pointsEnabled, pointsEnabled) || other.pointsEnabled == pointsEnabled)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.activeMembers, activeMembers) || other.activeMembers == activeMembers)&&(identical(other.memberBills, memberBills) || other.memberBills == memberBills)&&(identical(other.splitBills, splitBills) || other.splitBills == splitBills)&&(identical(other.splitEnabled, splitEnabled) || other.splitEnabled == splitEnabled)&&(identical(other.memberNet, memberNet) || other.memberNet == memberNet)&&(identical(other.guestBills, guestBills) || other.guestBills == guestBills)&&(identical(other.guestNet, guestNet) || other.guestNet == guestNet)&&(identical(other.avgMemberBill, avgMemberBill) || other.avgMemberBill == avgMemberBill)&&(identical(other.avgGuestBill, avgGuestBill) || other.avgGuestBill == avgGuestBill)&&(identical(other.pointsEarned, pointsEarned) || other.pointsEarned == pointsEarned)&&(identical(other.pointsRedeemed, pointsRedeemed) || other.pointsRedeemed == pointsRedeemed)&&(identical(other.pointsAdjusted, pointsAdjusted) || other.pointsAdjusted == pointsAdjusted)&&(identical(other.pointsOutstanding, pointsOutstanding) || other.pointsOutstanding == pointsOutstanding)&&(identical(other.liabilityEstimate, liabilityEstimate) || other.liabilityEstimate == liabilityEstimate)&&const DeepCollectionEquality().equals(other._top, _top)&&(identical(other.topTruncated, topTruncated) || other.topTruncated == topTruncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,enabled,pointsEnabled,enrolled,activeMembers,memberBills,splitBills,splitEnabled,memberNet,guestBills,guestNet,avgMemberBill,avgGuestBill,pointsEarned,pointsRedeemed,pointsAdjusted,pointsOutstanding,liabilityEstimate,const DeepCollectionEquality().hash(_top),topTruncated]);

@override
String toString() {
  return 'MembersSectionDto(enabled: $enabled, pointsEnabled: $pointsEnabled, enrolled: $enrolled, activeMembers: $activeMembers, memberBills: $memberBills, splitBills: $splitBills, splitEnabled: $splitEnabled, memberNet: $memberNet, guestBills: $guestBills, guestNet: $guestNet, avgMemberBill: $avgMemberBill, avgGuestBill: $avgGuestBill, pointsEarned: $pointsEarned, pointsRedeemed: $pointsRedeemed, pointsAdjusted: $pointsAdjusted, pointsOutstanding: $pointsOutstanding, liabilityEstimate: $liabilityEstimate, top: $top, topTruncated: $topTruncated)';
}


}

/// @nodoc
abstract mixin class _$MembersSectionDtoCopyWith<$Res> implements $MembersSectionDtoCopyWith<$Res> {
  factory _$MembersSectionDtoCopyWith(_MembersSectionDto value, $Res Function(_MembersSectionDto) _then) = __$MembersSectionDtoCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, bool pointsEnabled, int enrolled, int activeMembers, int memberBills, int splitBills, bool splitEnabled, int memberNet, int guestBills, int guestNet, int avgMemberBill, int avgGuestBill, int pointsEarned, int pointsRedeemed, int pointsAdjusted, int pointsOutstanding, int liabilityEstimate, List<MemberTopRowDto> top, int topTruncated
});




}
/// @nodoc
class __$MembersSectionDtoCopyWithImpl<$Res>
    implements _$MembersSectionDtoCopyWith<$Res> {
  __$MembersSectionDtoCopyWithImpl(this._self, this._then);

  final _MembersSectionDto _self;
  final $Res Function(_MembersSectionDto) _then;

/// Create a copy of MembersSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? pointsEnabled = null,Object? enrolled = null,Object? activeMembers = null,Object? memberBills = null,Object? splitBills = null,Object? splitEnabled = null,Object? memberNet = null,Object? guestBills = null,Object? guestNet = null,Object? avgMemberBill = null,Object? avgGuestBill = null,Object? pointsEarned = null,Object? pointsRedeemed = null,Object? pointsAdjusted = null,Object? pointsOutstanding = null,Object? liabilityEstimate = null,Object? top = null,Object? topTruncated = null,}) {
  return _then(_MembersSectionDto(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,pointsEnabled: null == pointsEnabled ? _self.pointsEnabled : pointsEnabled // ignore: cast_nullable_to_non_nullable
as bool,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,activeMembers: null == activeMembers ? _self.activeMembers : activeMembers // ignore: cast_nullable_to_non_nullable
as int,memberBills: null == memberBills ? _self.memberBills : memberBills // ignore: cast_nullable_to_non_nullable
as int,splitBills: null == splitBills ? _self.splitBills : splitBills // ignore: cast_nullable_to_non_nullable
as int,splitEnabled: null == splitEnabled ? _self.splitEnabled : splitEnabled // ignore: cast_nullable_to_non_nullable
as bool,memberNet: null == memberNet ? _self.memberNet : memberNet // ignore: cast_nullable_to_non_nullable
as int,guestBills: null == guestBills ? _self.guestBills : guestBills // ignore: cast_nullable_to_non_nullable
as int,guestNet: null == guestNet ? _self.guestNet : guestNet // ignore: cast_nullable_to_non_nullable
as int,avgMemberBill: null == avgMemberBill ? _self.avgMemberBill : avgMemberBill // ignore: cast_nullable_to_non_nullable
as int,avgGuestBill: null == avgGuestBill ? _self.avgGuestBill : avgGuestBill // ignore: cast_nullable_to_non_nullable
as int,pointsEarned: null == pointsEarned ? _self.pointsEarned : pointsEarned // ignore: cast_nullable_to_non_nullable
as int,pointsRedeemed: null == pointsRedeemed ? _self.pointsRedeemed : pointsRedeemed // ignore: cast_nullable_to_non_nullable
as int,pointsAdjusted: null == pointsAdjusted ? _self.pointsAdjusted : pointsAdjusted // ignore: cast_nullable_to_non_nullable
as int,pointsOutstanding: null == pointsOutstanding ? _self.pointsOutstanding : pointsOutstanding // ignore: cast_nullable_to_non_nullable
as int,liabilityEstimate: null == liabilityEstimate ? _self.liabilityEstimate : liabilityEstimate // ignore: cast_nullable_to_non_nullable
as int,top: null == top ? _self._top : top // ignore: cast_nullable_to_non_nullable
as List<MemberTopRowDto>,topTruncated: null == topTruncated ? _self.topTruncated : topTruncated // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PiutangSectionDto {

/// False ⇒ the venue runs no tabs, and the section is not drawn.
 bool get enabled; int get opening; int get charged; int get collected; int get writtenOff;/// Signed: which way a hand correction went is the finding.
 int get adjusted; int get closing; Map<String, int> get byMethod;/// The venue's credit policy, not a fact — what counts as late is a setting.
 int get overdueDays; int get overdueTotal; int get debtorCount; List<DebtorRowDto> get debtors;/// True when [debtors] is a capped page and the full list lives on
/// `/members`. A report is read on a tablet; a hundred-row table is not.
 bool get debtorsTruncated;
/// Create a copy of PiutangSectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PiutangSectionDtoCopyWith<PiutangSectionDto> get copyWith => _$PiutangSectionDtoCopyWithImpl<PiutangSectionDto>(this as PiutangSectionDto, _$identity);

  /// Serializes this PiutangSectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PiutangSectionDto&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.opening, opening) || other.opening == opening)&&(identical(other.charged, charged) || other.charged == charged)&&(identical(other.collected, collected) || other.collected == collected)&&(identical(other.writtenOff, writtenOff) || other.writtenOff == writtenOff)&&(identical(other.adjusted, adjusted) || other.adjusted == adjusted)&&(identical(other.closing, closing) || other.closing == closing)&&const DeepCollectionEquality().equals(other.byMethod, byMethod)&&(identical(other.overdueDays, overdueDays) || other.overdueDays == overdueDays)&&(identical(other.overdueTotal, overdueTotal) || other.overdueTotal == overdueTotal)&&(identical(other.debtorCount, debtorCount) || other.debtorCount == debtorCount)&&const DeepCollectionEquality().equals(other.debtors, debtors)&&(identical(other.debtorsTruncated, debtorsTruncated) || other.debtorsTruncated == debtorsTruncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,opening,charged,collected,writtenOff,adjusted,closing,const DeepCollectionEquality().hash(byMethod),overdueDays,overdueTotal,debtorCount,const DeepCollectionEquality().hash(debtors),debtorsTruncated);

@override
String toString() {
  return 'PiutangSectionDto(enabled: $enabled, opening: $opening, charged: $charged, collected: $collected, writtenOff: $writtenOff, adjusted: $adjusted, closing: $closing, byMethod: $byMethod, overdueDays: $overdueDays, overdueTotal: $overdueTotal, debtorCount: $debtorCount, debtors: $debtors, debtorsTruncated: $debtorsTruncated)';
}


}

/// @nodoc
abstract mixin class $PiutangSectionDtoCopyWith<$Res>  {
  factory $PiutangSectionDtoCopyWith(PiutangSectionDto value, $Res Function(PiutangSectionDto) _then) = _$PiutangSectionDtoCopyWithImpl;
@useResult
$Res call({
 bool enabled, int opening, int charged, int collected, int writtenOff, int adjusted, int closing, Map<String, int> byMethod, int overdueDays, int overdueTotal, int debtorCount, List<DebtorRowDto> debtors, bool debtorsTruncated
});




}
/// @nodoc
class _$PiutangSectionDtoCopyWithImpl<$Res>
    implements $PiutangSectionDtoCopyWith<$Res> {
  _$PiutangSectionDtoCopyWithImpl(this._self, this._then);

  final PiutangSectionDto _self;
  final $Res Function(PiutangSectionDto) _then;

/// Create a copy of PiutangSectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? opening = null,Object? charged = null,Object? collected = null,Object? writtenOff = null,Object? adjusted = null,Object? closing = null,Object? byMethod = null,Object? overdueDays = null,Object? overdueTotal = null,Object? debtorCount = null,Object? debtors = null,Object? debtorsTruncated = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,opening: null == opening ? _self.opening : opening // ignore: cast_nullable_to_non_nullable
as int,charged: null == charged ? _self.charged : charged // ignore: cast_nullable_to_non_nullable
as int,collected: null == collected ? _self.collected : collected // ignore: cast_nullable_to_non_nullable
as int,writtenOff: null == writtenOff ? _self.writtenOff : writtenOff // ignore: cast_nullable_to_non_nullable
as int,adjusted: null == adjusted ? _self.adjusted : adjusted // ignore: cast_nullable_to_non_nullable
as int,closing: null == closing ? _self.closing : closing // ignore: cast_nullable_to_non_nullable
as int,byMethod: null == byMethod ? _self.byMethod : byMethod // ignore: cast_nullable_to_non_nullable
as Map<String, int>,overdueDays: null == overdueDays ? _self.overdueDays : overdueDays // ignore: cast_nullable_to_non_nullable
as int,overdueTotal: null == overdueTotal ? _self.overdueTotal : overdueTotal // ignore: cast_nullable_to_non_nullable
as int,debtorCount: null == debtorCount ? _self.debtorCount : debtorCount // ignore: cast_nullable_to_non_nullable
as int,debtors: null == debtors ? _self.debtors : debtors // ignore: cast_nullable_to_non_nullable
as List<DebtorRowDto>,debtorsTruncated: null == debtorsTruncated ? _self.debtorsTruncated : debtorsTruncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PiutangSectionDto].
extension PiutangSectionDtoPatterns on PiutangSectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PiutangSectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PiutangSectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PiutangSectionDto value)  $default,){
final _that = this;
switch (_that) {
case _PiutangSectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PiutangSectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _PiutangSectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  int opening,  int charged,  int collected,  int writtenOff,  int adjusted,  int closing,  Map<String, int> byMethod,  int overdueDays,  int overdueTotal,  int debtorCount,  List<DebtorRowDto> debtors,  bool debtorsTruncated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PiutangSectionDto() when $default != null:
return $default(_that.enabled,_that.opening,_that.charged,_that.collected,_that.writtenOff,_that.adjusted,_that.closing,_that.byMethod,_that.overdueDays,_that.overdueTotal,_that.debtorCount,_that.debtors,_that.debtorsTruncated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  int opening,  int charged,  int collected,  int writtenOff,  int adjusted,  int closing,  Map<String, int> byMethod,  int overdueDays,  int overdueTotal,  int debtorCount,  List<DebtorRowDto> debtors,  bool debtorsTruncated)  $default,) {final _that = this;
switch (_that) {
case _PiutangSectionDto():
return $default(_that.enabled,_that.opening,_that.charged,_that.collected,_that.writtenOff,_that.adjusted,_that.closing,_that.byMethod,_that.overdueDays,_that.overdueTotal,_that.debtorCount,_that.debtors,_that.debtorsTruncated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  int opening,  int charged,  int collected,  int writtenOff,  int adjusted,  int closing,  Map<String, int> byMethod,  int overdueDays,  int overdueTotal,  int debtorCount,  List<DebtorRowDto> debtors,  bool debtorsTruncated)?  $default,) {final _that = this;
switch (_that) {
case _PiutangSectionDto() when $default != null:
return $default(_that.enabled,_that.opening,_that.charged,_that.collected,_that.writtenOff,_that.adjusted,_that.closing,_that.byMethod,_that.overdueDays,_that.overdueTotal,_that.debtorCount,_that.debtors,_that.debtorsTruncated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PiutangSectionDto implements PiutangSectionDto {
  const _PiutangSectionDto({this.enabled = false, this.opening = 0, this.charged = 0, this.collected = 0, this.writtenOff = 0, this.adjusted = 0, this.closing = 0, final  Map<String, int> byMethod = const <String, int>{}, this.overdueDays = 30, this.overdueTotal = 0, this.debtorCount = 0, final  List<DebtorRowDto> debtors = const <DebtorRowDto>[], this.debtorsTruncated = false}): _byMethod = byMethod,_debtors = debtors;
  factory _PiutangSectionDto.fromJson(Map<String, dynamic> json) => _$PiutangSectionDtoFromJson(json);

/// False ⇒ the venue runs no tabs, and the section is not drawn.
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  int opening;
@override@JsonKey() final  int charged;
@override@JsonKey() final  int collected;
@override@JsonKey() final  int writtenOff;
/// Signed: which way a hand correction went is the finding.
@override@JsonKey() final  int adjusted;
@override@JsonKey() final  int closing;
 final  Map<String, int> _byMethod;
@override@JsonKey() Map<String, int> get byMethod {
  if (_byMethod is EqualUnmodifiableMapView) return _byMethod;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_byMethod);
}

/// The venue's credit policy, not a fact — what counts as late is a setting.
@override@JsonKey() final  int overdueDays;
@override@JsonKey() final  int overdueTotal;
@override@JsonKey() final  int debtorCount;
 final  List<DebtorRowDto> _debtors;
@override@JsonKey() List<DebtorRowDto> get debtors {
  if (_debtors is EqualUnmodifiableListView) return _debtors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_debtors);
}

/// True when [debtors] is a capped page and the full list lives on
/// `/members`. A report is read on a tablet; a hundred-row table is not.
@override@JsonKey() final  bool debtorsTruncated;

/// Create a copy of PiutangSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PiutangSectionDtoCopyWith<_PiutangSectionDto> get copyWith => __$PiutangSectionDtoCopyWithImpl<_PiutangSectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PiutangSectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PiutangSectionDto&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.opening, opening) || other.opening == opening)&&(identical(other.charged, charged) || other.charged == charged)&&(identical(other.collected, collected) || other.collected == collected)&&(identical(other.writtenOff, writtenOff) || other.writtenOff == writtenOff)&&(identical(other.adjusted, adjusted) || other.adjusted == adjusted)&&(identical(other.closing, closing) || other.closing == closing)&&const DeepCollectionEquality().equals(other._byMethod, _byMethod)&&(identical(other.overdueDays, overdueDays) || other.overdueDays == overdueDays)&&(identical(other.overdueTotal, overdueTotal) || other.overdueTotal == overdueTotal)&&(identical(other.debtorCount, debtorCount) || other.debtorCount == debtorCount)&&const DeepCollectionEquality().equals(other._debtors, _debtors)&&(identical(other.debtorsTruncated, debtorsTruncated) || other.debtorsTruncated == debtorsTruncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,opening,charged,collected,writtenOff,adjusted,closing,const DeepCollectionEquality().hash(_byMethod),overdueDays,overdueTotal,debtorCount,const DeepCollectionEquality().hash(_debtors),debtorsTruncated);

@override
String toString() {
  return 'PiutangSectionDto(enabled: $enabled, opening: $opening, charged: $charged, collected: $collected, writtenOff: $writtenOff, adjusted: $adjusted, closing: $closing, byMethod: $byMethod, overdueDays: $overdueDays, overdueTotal: $overdueTotal, debtorCount: $debtorCount, debtors: $debtors, debtorsTruncated: $debtorsTruncated)';
}


}

/// @nodoc
abstract mixin class _$PiutangSectionDtoCopyWith<$Res> implements $PiutangSectionDtoCopyWith<$Res> {
  factory _$PiutangSectionDtoCopyWith(_PiutangSectionDto value, $Res Function(_PiutangSectionDto) _then) = __$PiutangSectionDtoCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, int opening, int charged, int collected, int writtenOff, int adjusted, int closing, Map<String, int> byMethod, int overdueDays, int overdueTotal, int debtorCount, List<DebtorRowDto> debtors, bool debtorsTruncated
});




}
/// @nodoc
class __$PiutangSectionDtoCopyWithImpl<$Res>
    implements _$PiutangSectionDtoCopyWith<$Res> {
  __$PiutangSectionDtoCopyWithImpl(this._self, this._then);

  final _PiutangSectionDto _self;
  final $Res Function(_PiutangSectionDto) _then;

/// Create a copy of PiutangSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? opening = null,Object? charged = null,Object? collected = null,Object? writtenOff = null,Object? adjusted = null,Object? closing = null,Object? byMethod = null,Object? overdueDays = null,Object? overdueTotal = null,Object? debtorCount = null,Object? debtors = null,Object? debtorsTruncated = null,}) {
  return _then(_PiutangSectionDto(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,opening: null == opening ? _self.opening : opening // ignore: cast_nullable_to_non_nullable
as int,charged: null == charged ? _self.charged : charged // ignore: cast_nullable_to_non_nullable
as int,collected: null == collected ? _self.collected : collected // ignore: cast_nullable_to_non_nullable
as int,writtenOff: null == writtenOff ? _self.writtenOff : writtenOff // ignore: cast_nullable_to_non_nullable
as int,adjusted: null == adjusted ? _self.adjusted : adjusted // ignore: cast_nullable_to_non_nullable
as int,closing: null == closing ? _self.closing : closing // ignore: cast_nullable_to_non_nullable
as int,byMethod: null == byMethod ? _self._byMethod : byMethod // ignore: cast_nullable_to_non_nullable
as Map<String, int>,overdueDays: null == overdueDays ? _self.overdueDays : overdueDays // ignore: cast_nullable_to_non_nullable
as int,overdueTotal: null == overdueTotal ? _self.overdueTotal : overdueTotal // ignore: cast_nullable_to_non_nullable
as int,debtorCount: null == debtorCount ? _self.debtorCount : debtorCount // ignore: cast_nullable_to_non_nullable
as int,debtors: null == debtors ? _self._debtors : debtors // ignore: cast_nullable_to_non_nullable
as List<DebtorRowDto>,debtorsTruncated: null == debtorsTruncated ? _self.debtorsTruncated : debtorsTruncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DebtorRowDto {

 String get memberId; String get name; String get phone; int get balance; DateTime? get oldestUnpaidAt; DateTime? get lastPaymentAt;
/// Create a copy of DebtorRowDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebtorRowDtoCopyWith<DebtorRowDto> get copyWith => _$DebtorRowDtoCopyWithImpl<DebtorRowDto>(this as DebtorRowDto, _$identity);

  /// Serializes this DebtorRowDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebtorRowDto&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.oldestUnpaidAt, oldestUnpaidAt) || other.oldestUnpaidAt == oldestUnpaidAt)&&(identical(other.lastPaymentAt, lastPaymentAt) || other.lastPaymentAt == lastPaymentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberId,name,phone,balance,oldestUnpaidAt,lastPaymentAt);

@override
String toString() {
  return 'DebtorRowDto(memberId: $memberId, name: $name, phone: $phone, balance: $balance, oldestUnpaidAt: $oldestUnpaidAt, lastPaymentAt: $lastPaymentAt)';
}


}

/// @nodoc
abstract mixin class $DebtorRowDtoCopyWith<$Res>  {
  factory $DebtorRowDtoCopyWith(DebtorRowDto value, $Res Function(DebtorRowDto) _then) = _$DebtorRowDtoCopyWithImpl;
@useResult
$Res call({
 String memberId, String name, String phone, int balance, DateTime? oldestUnpaidAt, DateTime? lastPaymentAt
});




}
/// @nodoc
class _$DebtorRowDtoCopyWithImpl<$Res>
    implements $DebtorRowDtoCopyWith<$Res> {
  _$DebtorRowDtoCopyWithImpl(this._self, this._then);

  final DebtorRowDto _self;
  final $Res Function(DebtorRowDto) _then;

/// Create a copy of DebtorRowDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memberId = null,Object? name = null,Object? phone = null,Object? balance = null,Object? oldestUnpaidAt = freezed,Object? lastPaymentAt = freezed,}) {
  return _then(_self.copyWith(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as int,oldestUnpaidAt: freezed == oldestUnpaidAt ? _self.oldestUnpaidAt : oldestUnpaidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastPaymentAt: freezed == lastPaymentAt ? _self.lastPaymentAt : lastPaymentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DebtorRowDto].
extension DebtorRowDtoPatterns on DebtorRowDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DebtorRowDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DebtorRowDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DebtorRowDto value)  $default,){
final _that = this;
switch (_that) {
case _DebtorRowDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DebtorRowDto value)?  $default,){
final _that = this;
switch (_that) {
case _DebtorRowDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String memberId,  String name,  String phone,  int balance,  DateTime? oldestUnpaidAt,  DateTime? lastPaymentAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DebtorRowDto() when $default != null:
return $default(_that.memberId,_that.name,_that.phone,_that.balance,_that.oldestUnpaidAt,_that.lastPaymentAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String memberId,  String name,  String phone,  int balance,  DateTime? oldestUnpaidAt,  DateTime? lastPaymentAt)  $default,) {final _that = this;
switch (_that) {
case _DebtorRowDto():
return $default(_that.memberId,_that.name,_that.phone,_that.balance,_that.oldestUnpaidAt,_that.lastPaymentAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String memberId,  String name,  String phone,  int balance,  DateTime? oldestUnpaidAt,  DateTime? lastPaymentAt)?  $default,) {final _that = this;
switch (_that) {
case _DebtorRowDto() when $default != null:
return $default(_that.memberId,_that.name,_that.phone,_that.balance,_that.oldestUnpaidAt,_that.lastPaymentAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DebtorRowDto implements DebtorRowDto {
  const _DebtorRowDto({this.memberId = '', this.name = '', this.phone = '', this.balance = 0, this.oldestUnpaidAt, this.lastPaymentAt});
  factory _DebtorRowDto.fromJson(Map<String, dynamic> json) => _$DebtorRowDtoFromJson(json);

@override@JsonKey() final  String memberId;
@override@JsonKey() final  String name;
@override@JsonKey() final  String phone;
@override@JsonKey() final  int balance;
@override final  DateTime? oldestUnpaidAt;
@override final  DateTime? lastPaymentAt;

/// Create a copy of DebtorRowDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebtorRowDtoCopyWith<_DebtorRowDto> get copyWith => __$DebtorRowDtoCopyWithImpl<_DebtorRowDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebtorRowDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebtorRowDto&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.oldestUnpaidAt, oldestUnpaidAt) || other.oldestUnpaidAt == oldestUnpaidAt)&&(identical(other.lastPaymentAt, lastPaymentAt) || other.lastPaymentAt == lastPaymentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberId,name,phone,balance,oldestUnpaidAt,lastPaymentAt);

@override
String toString() {
  return 'DebtorRowDto(memberId: $memberId, name: $name, phone: $phone, balance: $balance, oldestUnpaidAt: $oldestUnpaidAt, lastPaymentAt: $lastPaymentAt)';
}


}

/// @nodoc
abstract mixin class _$DebtorRowDtoCopyWith<$Res> implements $DebtorRowDtoCopyWith<$Res> {
  factory _$DebtorRowDtoCopyWith(_DebtorRowDto value, $Res Function(_DebtorRowDto) _then) = __$DebtorRowDtoCopyWithImpl;
@override @useResult
$Res call({
 String memberId, String name, String phone, int balance, DateTime? oldestUnpaidAt, DateTime? lastPaymentAt
});




}
/// @nodoc
class __$DebtorRowDtoCopyWithImpl<$Res>
    implements _$DebtorRowDtoCopyWith<$Res> {
  __$DebtorRowDtoCopyWithImpl(this._self, this._then);

  final _DebtorRowDto _self;
  final $Res Function(_DebtorRowDto) _then;

/// Create a copy of DebtorRowDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memberId = null,Object? name = null,Object? phone = null,Object? balance = null,Object? oldestUnpaidAt = freezed,Object? lastPaymentAt = freezed,}) {
  return _then(_DebtorRowDto(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as int,oldestUnpaidAt: freezed == oldestUnpaidAt ? _self.oldestUnpaidAt : oldestUnpaidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastPaymentAt: freezed == lastPaymentAt ? _self.lastPaymentAt : lastPaymentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$MemberTopRowDto {

 String get memberId; String? get name; int get visits; int get spend;/// Points earned in the window. Hidden by the section when the points
/// program is off; see [MembersSectionDto.pointsEnabled].
 int get points;
/// Create a copy of MemberTopRowDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberTopRowDtoCopyWith<MemberTopRowDto> get copyWith => _$MemberTopRowDtoCopyWithImpl<MemberTopRowDto>(this as MemberTopRowDto, _$identity);

  /// Serializes this MemberTopRowDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberTopRowDto&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.name, name) || other.name == name)&&(identical(other.visits, visits) || other.visits == visits)&&(identical(other.spend, spend) || other.spend == spend)&&(identical(other.points, points) || other.points == points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberId,name,visits,spend,points);

@override
String toString() {
  return 'MemberTopRowDto(memberId: $memberId, name: $name, visits: $visits, spend: $spend, points: $points)';
}


}

/// @nodoc
abstract mixin class $MemberTopRowDtoCopyWith<$Res>  {
  factory $MemberTopRowDtoCopyWith(MemberTopRowDto value, $Res Function(MemberTopRowDto) _then) = _$MemberTopRowDtoCopyWithImpl;
@useResult
$Res call({
 String memberId, String? name, int visits, int spend, int points
});




}
/// @nodoc
class _$MemberTopRowDtoCopyWithImpl<$Res>
    implements $MemberTopRowDtoCopyWith<$Res> {
  _$MemberTopRowDtoCopyWithImpl(this._self, this._then);

  final MemberTopRowDto _self;
  final $Res Function(MemberTopRowDto) _then;

/// Create a copy of MemberTopRowDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memberId = null,Object? name = freezed,Object? visits = null,Object? spend = null,Object? points = null,}) {
  return _then(_self.copyWith(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,visits: null == visits ? _self.visits : visits // ignore: cast_nullable_to_non_nullable
as int,spend: null == spend ? _self.spend : spend // ignore: cast_nullable_to_non_nullable
as int,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberTopRowDto].
extension MemberTopRowDtoPatterns on MemberTopRowDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberTopRowDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberTopRowDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberTopRowDto value)  $default,){
final _that = this;
switch (_that) {
case _MemberTopRowDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberTopRowDto value)?  $default,){
final _that = this;
switch (_that) {
case _MemberTopRowDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String memberId,  String? name,  int visits,  int spend,  int points)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberTopRowDto() when $default != null:
return $default(_that.memberId,_that.name,_that.visits,_that.spend,_that.points);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String memberId,  String? name,  int visits,  int spend,  int points)  $default,) {final _that = this;
switch (_that) {
case _MemberTopRowDto():
return $default(_that.memberId,_that.name,_that.visits,_that.spend,_that.points);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String memberId,  String? name,  int visits,  int spend,  int points)?  $default,) {final _that = this;
switch (_that) {
case _MemberTopRowDto() when $default != null:
return $default(_that.memberId,_that.name,_that.visits,_that.spend,_that.points);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberTopRowDto extends MemberTopRowDto {
  const _MemberTopRowDto({this.memberId = '', this.name, this.visits = 0, this.spend = 0, this.points = 0}): super._();
  factory _MemberTopRowDto.fromJson(Map<String, dynamic> json) => _$MemberTopRowDtoFromJson(json);

@override@JsonKey() final  String memberId;
@override final  String? name;
@override@JsonKey() final  int visits;
@override@JsonKey() final  int spend;
/// Points earned in the window. Hidden by the section when the points
/// program is off; see [MembersSectionDto.pointsEnabled].
@override@JsonKey() final  int points;

/// Create a copy of MemberTopRowDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberTopRowDtoCopyWith<_MemberTopRowDto> get copyWith => __$MemberTopRowDtoCopyWithImpl<_MemberTopRowDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberTopRowDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberTopRowDto&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.name, name) || other.name == name)&&(identical(other.visits, visits) || other.visits == visits)&&(identical(other.spend, spend) || other.spend == spend)&&(identical(other.points, points) || other.points == points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberId,name,visits,spend,points);

@override
String toString() {
  return 'MemberTopRowDto(memberId: $memberId, name: $name, visits: $visits, spend: $spend, points: $points)';
}


}

/// @nodoc
abstract mixin class _$MemberTopRowDtoCopyWith<$Res> implements $MemberTopRowDtoCopyWith<$Res> {
  factory _$MemberTopRowDtoCopyWith(_MemberTopRowDto value, $Res Function(_MemberTopRowDto) _then) = __$MemberTopRowDtoCopyWithImpl;
@override @useResult
$Res call({
 String memberId, String? name, int visits, int spend, int points
});




}
/// @nodoc
class __$MemberTopRowDtoCopyWithImpl<$Res>
    implements _$MemberTopRowDtoCopyWith<$Res> {
  __$MemberTopRowDtoCopyWithImpl(this._self, this._then);

  final _MemberTopRowDto _self;
  final $Res Function(_MemberTopRowDto) _then;

/// Create a copy of MemberTopRowDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memberId = null,Object? name = freezed,Object? visits = null,Object? spend = null,Object? points = null,}) {
  return _then(_MemberTopRowDto(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,visits: null == visits ? _self.visits : visits // ignore: cast_nullable_to_non_nullable
as int,spend: null == spend ? _self.spend : spend // ignore: cast_nullable_to_non_nullable
as int,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MoneyAuditSectionDto {

 List<MoneyAuditRowDto> get rows;/// True when the range held more rows than were published. The snapshot is
/// a Firestore document with a hard ceiling, so the cap is real and the
/// owner is told rather than shown a quietly short list.
 bool get truncated;
/// Create a copy of MoneyAuditSectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoneyAuditSectionDtoCopyWith<MoneyAuditSectionDto> get copyWith => _$MoneyAuditSectionDtoCopyWithImpl<MoneyAuditSectionDto>(this as MoneyAuditSectionDto, _$identity);

  /// Serializes this MoneyAuditSectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoneyAuditSectionDto&&const DeepCollectionEquality().equals(other.rows, rows)&&(identical(other.truncated, truncated) || other.truncated == truncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),truncated);

@override
String toString() {
  return 'MoneyAuditSectionDto(rows: $rows, truncated: $truncated)';
}


}

/// @nodoc
abstract mixin class $MoneyAuditSectionDtoCopyWith<$Res>  {
  factory $MoneyAuditSectionDtoCopyWith(MoneyAuditSectionDto value, $Res Function(MoneyAuditSectionDto) _then) = _$MoneyAuditSectionDtoCopyWithImpl;
@useResult
$Res call({
 List<MoneyAuditRowDto> rows, bool truncated
});




}
/// @nodoc
class _$MoneyAuditSectionDtoCopyWithImpl<$Res>
    implements $MoneyAuditSectionDtoCopyWith<$Res> {
  _$MoneyAuditSectionDtoCopyWithImpl(this._self, this._then);

  final MoneyAuditSectionDto _self;
  final $Res Function(MoneyAuditSectionDto) _then;

/// Create a copy of MoneyAuditSectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? truncated = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<MoneyAuditRowDto>,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MoneyAuditSectionDto].
extension MoneyAuditSectionDtoPatterns on MoneyAuditSectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoneyAuditSectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoneyAuditSectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoneyAuditSectionDto value)  $default,){
final _that = this;
switch (_that) {
case _MoneyAuditSectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoneyAuditSectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _MoneyAuditSectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MoneyAuditRowDto> rows,  bool truncated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoneyAuditSectionDto() when $default != null:
return $default(_that.rows,_that.truncated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MoneyAuditRowDto> rows,  bool truncated)  $default,) {final _that = this;
switch (_that) {
case _MoneyAuditSectionDto():
return $default(_that.rows,_that.truncated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MoneyAuditRowDto> rows,  bool truncated)?  $default,) {final _that = this;
switch (_that) {
case _MoneyAuditSectionDto() when $default != null:
return $default(_that.rows,_that.truncated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MoneyAuditSectionDto implements MoneyAuditSectionDto {
  const _MoneyAuditSectionDto({final  List<MoneyAuditRowDto> rows = const <MoneyAuditRowDto>[], this.truncated = false}): _rows = rows;
  factory _MoneyAuditSectionDto.fromJson(Map<String, dynamic> json) => _$MoneyAuditSectionDtoFromJson(json);

 final  List<MoneyAuditRowDto> _rows;
@override@JsonKey() List<MoneyAuditRowDto> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

/// True when the range held more rows than were published. The snapshot is
/// a Firestore document with a hard ceiling, so the cap is real and the
/// owner is told rather than shown a quietly short list.
@override@JsonKey() final  bool truncated;

/// Create a copy of MoneyAuditSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoneyAuditSectionDtoCopyWith<_MoneyAuditSectionDto> get copyWith => __$MoneyAuditSectionDtoCopyWithImpl<_MoneyAuditSectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MoneyAuditSectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoneyAuditSectionDto&&const DeepCollectionEquality().equals(other._rows, _rows)&&(identical(other.truncated, truncated) || other.truncated == truncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),truncated);

@override
String toString() {
  return 'MoneyAuditSectionDto(rows: $rows, truncated: $truncated)';
}


}

/// @nodoc
abstract mixin class _$MoneyAuditSectionDtoCopyWith<$Res> implements $MoneyAuditSectionDtoCopyWith<$Res> {
  factory _$MoneyAuditSectionDtoCopyWith(_MoneyAuditSectionDto value, $Res Function(_MoneyAuditSectionDto) _then) = __$MoneyAuditSectionDtoCopyWithImpl;
@override @useResult
$Res call({
 List<MoneyAuditRowDto> rows, bool truncated
});




}
/// @nodoc
class __$MoneyAuditSectionDtoCopyWithImpl<$Res>
    implements _$MoneyAuditSectionDtoCopyWith<$Res> {
  __$MoneyAuditSectionDtoCopyWithImpl(this._self, this._then);

  final _MoneyAuditSectionDto _self;
  final $Res Function(_MoneyAuditSectionDto) _then;

/// Create a copy of MoneyAuditSectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? truncated = null,}) {
  return _then(_MoneyAuditSectionDto(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<MoneyAuditRowDto>,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MoneyAuditRowDto {

 String get id; String get type; String get at; String get title; String? get kind; Map<String, String> get params; String? get actorName; String? get tableLabel; int? get amountCents;
/// Create a copy of MoneyAuditRowDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoneyAuditRowDtoCopyWith<MoneyAuditRowDto> get copyWith => _$MoneyAuditRowDtoCopyWithImpl<MoneyAuditRowDto>(this as MoneyAuditRowDto, _$identity);

  /// Serializes this MoneyAuditRowDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoneyAuditRowDto&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.at, at) || other.at == at)&&(identical(other.title, title) || other.title == title)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.params, params)&&(identical(other.actorName, actorName) || other.actorName == actorName)&&(identical(other.tableLabel, tableLabel) || other.tableLabel == tableLabel)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,at,title,kind,const DeepCollectionEquality().hash(params),actorName,tableLabel,amountCents);

@override
String toString() {
  return 'MoneyAuditRowDto(id: $id, type: $type, at: $at, title: $title, kind: $kind, params: $params, actorName: $actorName, tableLabel: $tableLabel, amountCents: $amountCents)';
}


}

/// @nodoc
abstract mixin class $MoneyAuditRowDtoCopyWith<$Res>  {
  factory $MoneyAuditRowDtoCopyWith(MoneyAuditRowDto value, $Res Function(MoneyAuditRowDto) _then) = _$MoneyAuditRowDtoCopyWithImpl;
@useResult
$Res call({
 String id, String type, String at, String title, String? kind, Map<String, String> params, String? actorName, String? tableLabel, int? amountCents
});




}
/// @nodoc
class _$MoneyAuditRowDtoCopyWithImpl<$Res>
    implements $MoneyAuditRowDtoCopyWith<$Res> {
  _$MoneyAuditRowDtoCopyWithImpl(this._self, this._then);

  final MoneyAuditRowDto _self;
  final $Res Function(MoneyAuditRowDto) _then;

/// Create a copy of MoneyAuditRowDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? at = null,Object? title = null,Object? kind = freezed,Object? params = null,Object? actorName = freezed,Object? tableLabel = freezed,Object? amountCents = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, String>,actorName: freezed == actorName ? _self.actorName : actorName // ignore: cast_nullable_to_non_nullable
as String?,tableLabel: freezed == tableLabel ? _self.tableLabel : tableLabel // ignore: cast_nullable_to_non_nullable
as String?,amountCents: freezed == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MoneyAuditRowDto].
extension MoneyAuditRowDtoPatterns on MoneyAuditRowDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoneyAuditRowDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoneyAuditRowDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoneyAuditRowDto value)  $default,){
final _that = this;
switch (_that) {
case _MoneyAuditRowDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoneyAuditRowDto value)?  $default,){
final _that = this;
switch (_that) {
case _MoneyAuditRowDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String at,  String title,  String? kind,  Map<String, String> params,  String? actorName,  String? tableLabel,  int? amountCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoneyAuditRowDto() when $default != null:
return $default(_that.id,_that.type,_that.at,_that.title,_that.kind,_that.params,_that.actorName,_that.tableLabel,_that.amountCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String at,  String title,  String? kind,  Map<String, String> params,  String? actorName,  String? tableLabel,  int? amountCents)  $default,) {final _that = this;
switch (_that) {
case _MoneyAuditRowDto():
return $default(_that.id,_that.type,_that.at,_that.title,_that.kind,_that.params,_that.actorName,_that.tableLabel,_that.amountCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String at,  String title,  String? kind,  Map<String, String> params,  String? actorName,  String? tableLabel,  int? amountCents)?  $default,) {final _that = this;
switch (_that) {
case _MoneyAuditRowDto() when $default != null:
return $default(_that.id,_that.type,_that.at,_that.title,_that.kind,_that.params,_that.actorName,_that.tableLabel,_that.amountCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MoneyAuditRowDto implements MoneyAuditRowDto {
  const _MoneyAuditRowDto({required this.id, required this.type, this.at = '', this.title = '', this.kind, final  Map<String, String> params = const <String, String>{}, this.actorName, this.tableLabel, this.amountCents}): _params = params;
  factory _MoneyAuditRowDto.fromJson(Map<String, dynamic> json) => _$MoneyAuditRowDtoFromJson(json);

@override final  String id;
@override final  String type;
@override@JsonKey() final  String at;
@override@JsonKey() final  String title;
@override final  String? kind;
 final  Map<String, String> _params;
@override@JsonKey() Map<String, String> get params {
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_params);
}

@override final  String? actorName;
@override final  String? tableLabel;
@override final  int? amountCents;

/// Create a copy of MoneyAuditRowDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoneyAuditRowDtoCopyWith<_MoneyAuditRowDto> get copyWith => __$MoneyAuditRowDtoCopyWithImpl<_MoneyAuditRowDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MoneyAuditRowDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoneyAuditRowDto&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.at, at) || other.at == at)&&(identical(other.title, title) || other.title == title)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._params, _params)&&(identical(other.actorName, actorName) || other.actorName == actorName)&&(identical(other.tableLabel, tableLabel) || other.tableLabel == tableLabel)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,at,title,kind,const DeepCollectionEquality().hash(_params),actorName,tableLabel,amountCents);

@override
String toString() {
  return 'MoneyAuditRowDto(id: $id, type: $type, at: $at, title: $title, kind: $kind, params: $params, actorName: $actorName, tableLabel: $tableLabel, amountCents: $amountCents)';
}


}

/// @nodoc
abstract mixin class _$MoneyAuditRowDtoCopyWith<$Res> implements $MoneyAuditRowDtoCopyWith<$Res> {
  factory _$MoneyAuditRowDtoCopyWith(_MoneyAuditRowDto value, $Res Function(_MoneyAuditRowDto) _then) = __$MoneyAuditRowDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String at, String title, String? kind, Map<String, String> params, String? actorName, String? tableLabel, int? amountCents
});




}
/// @nodoc
class __$MoneyAuditRowDtoCopyWithImpl<$Res>
    implements _$MoneyAuditRowDtoCopyWith<$Res> {
  __$MoneyAuditRowDtoCopyWithImpl(this._self, this._then);

  final _MoneyAuditRowDto _self;
  final $Res Function(_MoneyAuditRowDto) _then;

/// Create a copy of MoneyAuditRowDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? at = null,Object? title = null,Object? kind = freezed,Object? params = null,Object? actorName = freezed,Object? tableLabel = freezed,Object? amountCents = freezed,}) {
  return _then(_MoneyAuditRowDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,params: null == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, String>,actorName: freezed == actorName ? _self.actorName : actorName // ignore: cast_nullable_to_non_nullable
as String?,tableLabel: freezed == tableLabel ? _self.tableLabel : tableLabel // ignore: cast_nullable_to_non_nullable
as String?,amountCents: freezed == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$StaffVoidDto {

 String get id; String get name; int get count; int get lostRupiah; String get topReasonCode;
/// Create a copy of StaffVoidDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffVoidDtoCopyWith<StaffVoidDto> get copyWith => _$StaffVoidDtoCopyWithImpl<StaffVoidDto>(this as StaffVoidDto, _$identity);

  /// Serializes this StaffVoidDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffVoidDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.count, count) || other.count == count)&&(identical(other.lostRupiah, lostRupiah) || other.lostRupiah == lostRupiah)&&(identical(other.topReasonCode, topReasonCode) || other.topReasonCode == topReasonCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,count,lostRupiah,topReasonCode);

@override
String toString() {
  return 'StaffVoidDto(id: $id, name: $name, count: $count, lostRupiah: $lostRupiah, topReasonCode: $topReasonCode)';
}


}

/// @nodoc
abstract mixin class $StaffVoidDtoCopyWith<$Res>  {
  factory $StaffVoidDtoCopyWith(StaffVoidDto value, $Res Function(StaffVoidDto) _then) = _$StaffVoidDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, int count, int lostRupiah, String topReasonCode
});




}
/// @nodoc
class _$StaffVoidDtoCopyWithImpl<$Res>
    implements $StaffVoidDtoCopyWith<$Res> {
  _$StaffVoidDtoCopyWithImpl(this._self, this._then);

  final StaffVoidDto _self;
  final $Res Function(StaffVoidDto) _then;

/// Create a copy of StaffVoidDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? count = null,Object? lostRupiah = null,Object? topReasonCode = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,lostRupiah: null == lostRupiah ? _self.lostRupiah : lostRupiah // ignore: cast_nullable_to_non_nullable
as int,topReasonCode: null == topReasonCode ? _self.topReasonCode : topReasonCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffVoidDto].
extension StaffVoidDtoPatterns on StaffVoidDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffVoidDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffVoidDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffVoidDto value)  $default,){
final _that = this;
switch (_that) {
case _StaffVoidDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffVoidDto value)?  $default,){
final _that = this;
switch (_that) {
case _StaffVoidDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int count,  int lostRupiah,  String topReasonCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffVoidDto() when $default != null:
return $default(_that.id,_that.name,_that.count,_that.lostRupiah,_that.topReasonCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int count,  int lostRupiah,  String topReasonCode)  $default,) {final _that = this;
switch (_that) {
case _StaffVoidDto():
return $default(_that.id,_that.name,_that.count,_that.lostRupiah,_that.topReasonCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int count,  int lostRupiah,  String topReasonCode)?  $default,) {final _that = this;
switch (_that) {
case _StaffVoidDto() when $default != null:
return $default(_that.id,_that.name,_that.count,_that.lostRupiah,_that.topReasonCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffVoidDto implements StaffVoidDto {
  const _StaffVoidDto({required this.id, required this.name, this.count = 0, this.lostRupiah = 0, this.topReasonCode = 'other'});
  factory _StaffVoidDto.fromJson(Map<String, dynamic> json) => _$StaffVoidDtoFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  int count;
@override@JsonKey() final  int lostRupiah;
@override@JsonKey() final  String topReasonCode;

/// Create a copy of StaffVoidDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffVoidDtoCopyWith<_StaffVoidDto> get copyWith => __$StaffVoidDtoCopyWithImpl<_StaffVoidDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffVoidDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffVoidDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.count, count) || other.count == count)&&(identical(other.lostRupiah, lostRupiah) || other.lostRupiah == lostRupiah)&&(identical(other.topReasonCode, topReasonCode) || other.topReasonCode == topReasonCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,count,lostRupiah,topReasonCode);

@override
String toString() {
  return 'StaffVoidDto(id: $id, name: $name, count: $count, lostRupiah: $lostRupiah, topReasonCode: $topReasonCode)';
}


}

/// @nodoc
abstract mixin class _$StaffVoidDtoCopyWith<$Res> implements $StaffVoidDtoCopyWith<$Res> {
  factory _$StaffVoidDtoCopyWith(_StaffVoidDto value, $Res Function(_StaffVoidDto) _then) = __$StaffVoidDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int count, int lostRupiah, String topReasonCode
});




}
/// @nodoc
class __$StaffVoidDtoCopyWithImpl<$Res>
    implements _$StaffVoidDtoCopyWith<$Res> {
  __$StaffVoidDtoCopyWithImpl(this._self, this._then);

  final _StaffVoidDto _self;
  final $Res Function(_StaffVoidDto) _then;

/// Create a copy of StaffVoidDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? count = null,Object? lostRupiah = null,Object? topReasonCode = null,}) {
  return _then(_StaffVoidDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,lostRupiah: null == lostRupiah ? _self.lostRupiah : lostRupiah // ignore: cast_nullable_to_non_nullable
as int,topReasonCode: null == topReasonCode ? _self.topReasonCode : topReasonCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
