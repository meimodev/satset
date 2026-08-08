// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reports_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReportsSnapshotDto _$ReportsSnapshotDtoFromJson(Map<String, dynamic> json) {
  return _ReportsSnapshotDto.fromJson(json);
}

/// @nodoc
mixin _$ReportsSnapshotDto {
  String get generatedAt => throw _privateConstructorUsedError;
  String get rangeFrom => throw _privateConstructorUsedError;
  String get rangeTo => throw _privateConstructorUsedError;
  String get range => throw _privateConstructorUsedError;
  FilterOptionsDto get filterOptions => throw _privateConstructorUsedError;
  SalesSectionDto get sales => throw _privateConstructorUsedError;
  StaffSectionDto get staff => throw _privateConstructorUsedError;
  MenuSectionDto get menu => throw _privateConstructorUsedError;
  OpsSectionDto get ops => throw _privateConstructorUsedError;
  PaymentsSectionDto get payments => throw _privateConstructorUsedError;

  /// Serializes this ReportsSnapshotDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReportsSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReportsSnapshotDtoCopyWith<ReportsSnapshotDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportsSnapshotDtoCopyWith<$Res> {
  factory $ReportsSnapshotDtoCopyWith(
    ReportsSnapshotDto value,
    $Res Function(ReportsSnapshotDto) then,
  ) = _$ReportsSnapshotDtoCopyWithImpl<$Res, ReportsSnapshotDto>;
  @useResult
  $Res call({
    String generatedAt,
    String rangeFrom,
    String rangeTo,
    String range,
    FilterOptionsDto filterOptions,
    SalesSectionDto sales,
    StaffSectionDto staff,
    MenuSectionDto menu,
    OpsSectionDto ops,
    PaymentsSectionDto payments,
  });

  $FilterOptionsDtoCopyWith<$Res> get filterOptions;
  $SalesSectionDtoCopyWith<$Res> get sales;
  $StaffSectionDtoCopyWith<$Res> get staff;
  $MenuSectionDtoCopyWith<$Res> get menu;
  $OpsSectionDtoCopyWith<$Res> get ops;
  $PaymentsSectionDtoCopyWith<$Res> get payments;
}

/// @nodoc
class _$ReportsSnapshotDtoCopyWithImpl<$Res, $Val extends ReportsSnapshotDto>
    implements $ReportsSnapshotDtoCopyWith<$Res> {
  _$ReportsSnapshotDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReportsSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? generatedAt = null,
    Object? rangeFrom = null,
    Object? rangeTo = null,
    Object? range = null,
    Object? filterOptions = null,
    Object? sales = null,
    Object? staff = null,
    Object? menu = null,
    Object? ops = null,
    Object? payments = null,
  }) {
    return _then(
      _value.copyWith(
            generatedAt: null == generatedAt
                ? _value.generatedAt
                : generatedAt // ignore: cast_nullable_to_non_nullable
                      as String,
            rangeFrom: null == rangeFrom
                ? _value.rangeFrom
                : rangeFrom // ignore: cast_nullable_to_non_nullable
                      as String,
            rangeTo: null == rangeTo
                ? _value.rangeTo
                : rangeTo // ignore: cast_nullable_to_non_nullable
                      as String,
            range: null == range
                ? _value.range
                : range // ignore: cast_nullable_to_non_nullable
                      as String,
            filterOptions: null == filterOptions
                ? _value.filterOptions
                : filterOptions // ignore: cast_nullable_to_non_nullable
                      as FilterOptionsDto,
            sales: null == sales
                ? _value.sales
                : sales // ignore: cast_nullable_to_non_nullable
                      as SalesSectionDto,
            staff: null == staff
                ? _value.staff
                : staff // ignore: cast_nullable_to_non_nullable
                      as StaffSectionDto,
            menu: null == menu
                ? _value.menu
                : menu // ignore: cast_nullable_to_non_nullable
                      as MenuSectionDto,
            ops: null == ops
                ? _value.ops
                : ops // ignore: cast_nullable_to_non_nullable
                      as OpsSectionDto,
            payments: null == payments
                ? _value.payments
                : payments // ignore: cast_nullable_to_non_nullable
                      as PaymentsSectionDto,
          )
          as $Val,
    );
  }

  /// Create a copy of ReportsSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FilterOptionsDtoCopyWith<$Res> get filterOptions {
    return $FilterOptionsDtoCopyWith<$Res>(_value.filterOptions, (value) {
      return _then(_value.copyWith(filterOptions: value) as $Val);
    });
  }

  /// Create a copy of ReportsSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SalesSectionDtoCopyWith<$Res> get sales {
    return $SalesSectionDtoCopyWith<$Res>(_value.sales, (value) {
      return _then(_value.copyWith(sales: value) as $Val);
    });
  }

  /// Create a copy of ReportsSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StaffSectionDtoCopyWith<$Res> get staff {
    return $StaffSectionDtoCopyWith<$Res>(_value.staff, (value) {
      return _then(_value.copyWith(staff: value) as $Val);
    });
  }

  /// Create a copy of ReportsSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MenuSectionDtoCopyWith<$Res> get menu {
    return $MenuSectionDtoCopyWith<$Res>(_value.menu, (value) {
      return _then(_value.copyWith(menu: value) as $Val);
    });
  }

  /// Create a copy of ReportsSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OpsSectionDtoCopyWith<$Res> get ops {
    return $OpsSectionDtoCopyWith<$Res>(_value.ops, (value) {
      return _then(_value.copyWith(ops: value) as $Val);
    });
  }

  /// Create a copy of ReportsSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PaymentsSectionDtoCopyWith<$Res> get payments {
    return $PaymentsSectionDtoCopyWith<$Res>(_value.payments, (value) {
      return _then(_value.copyWith(payments: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ReportsSnapshotDtoImplCopyWith<$Res>
    implements $ReportsSnapshotDtoCopyWith<$Res> {
  factory _$$ReportsSnapshotDtoImplCopyWith(
    _$ReportsSnapshotDtoImpl value,
    $Res Function(_$ReportsSnapshotDtoImpl) then,
  ) = __$$ReportsSnapshotDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String generatedAt,
    String rangeFrom,
    String rangeTo,
    String range,
    FilterOptionsDto filterOptions,
    SalesSectionDto sales,
    StaffSectionDto staff,
    MenuSectionDto menu,
    OpsSectionDto ops,
    PaymentsSectionDto payments,
  });

  @override
  $FilterOptionsDtoCopyWith<$Res> get filterOptions;
  @override
  $SalesSectionDtoCopyWith<$Res> get sales;
  @override
  $StaffSectionDtoCopyWith<$Res> get staff;
  @override
  $MenuSectionDtoCopyWith<$Res> get menu;
  @override
  $OpsSectionDtoCopyWith<$Res> get ops;
  @override
  $PaymentsSectionDtoCopyWith<$Res> get payments;
}

/// @nodoc
class __$$ReportsSnapshotDtoImplCopyWithImpl<$Res>
    extends _$ReportsSnapshotDtoCopyWithImpl<$Res, _$ReportsSnapshotDtoImpl>
    implements _$$ReportsSnapshotDtoImplCopyWith<$Res> {
  __$$ReportsSnapshotDtoImplCopyWithImpl(
    _$ReportsSnapshotDtoImpl _value,
    $Res Function(_$ReportsSnapshotDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReportsSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? generatedAt = null,
    Object? rangeFrom = null,
    Object? rangeTo = null,
    Object? range = null,
    Object? filterOptions = null,
    Object? sales = null,
    Object? staff = null,
    Object? menu = null,
    Object? ops = null,
    Object? payments = null,
  }) {
    return _then(
      _$ReportsSnapshotDtoImpl(
        generatedAt: null == generatedAt
            ? _value.generatedAt
            : generatedAt // ignore: cast_nullable_to_non_nullable
                  as String,
        rangeFrom: null == rangeFrom
            ? _value.rangeFrom
            : rangeFrom // ignore: cast_nullable_to_non_nullable
                  as String,
        rangeTo: null == rangeTo
            ? _value.rangeTo
            : rangeTo // ignore: cast_nullable_to_non_nullable
                  as String,
        range: null == range
            ? _value.range
            : range // ignore: cast_nullable_to_non_nullable
                  as String,
        filterOptions: null == filterOptions
            ? _value.filterOptions
            : filterOptions // ignore: cast_nullable_to_non_nullable
                  as FilterOptionsDto,
        sales: null == sales
            ? _value.sales
            : sales // ignore: cast_nullable_to_non_nullable
                  as SalesSectionDto,
        staff: null == staff
            ? _value.staff
            : staff // ignore: cast_nullable_to_non_nullable
                  as StaffSectionDto,
        menu: null == menu
            ? _value.menu
            : menu // ignore: cast_nullable_to_non_nullable
                  as MenuSectionDto,
        ops: null == ops
            ? _value.ops
            : ops // ignore: cast_nullable_to_non_nullable
                  as OpsSectionDto,
        payments: null == payments
            ? _value.payments
            : payments // ignore: cast_nullable_to_non_nullable
                  as PaymentsSectionDto,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReportsSnapshotDtoImpl implements _ReportsSnapshotDto {
  const _$ReportsSnapshotDtoImpl({
    required this.generatedAt,
    required this.rangeFrom,
    required this.rangeTo,
    required this.range,
    required this.filterOptions,
    required this.sales,
    required this.staff,
    required this.menu,
    required this.ops,
    this.payments = const PaymentsSectionDto(),
  });

  factory _$ReportsSnapshotDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReportsSnapshotDtoImplFromJson(json);

  @override
  final String generatedAt;
  @override
  final String rangeFrom;
  @override
  final String rangeTo;
  @override
  final String range;
  @override
  final FilterOptionsDto filterOptions;
  @override
  final SalesSectionDto sales;
  @override
  final StaffSectionDto staff;
  @override
  final MenuSectionDto menu;
  @override
  final OpsSectionDto ops;
  @override
  @JsonKey()
  final PaymentsSectionDto payments;

  @override
  String toString() {
    return 'ReportsSnapshotDto(generatedAt: $generatedAt, rangeFrom: $rangeFrom, rangeTo: $rangeTo, range: $range, filterOptions: $filterOptions, sales: $sales, staff: $staff, menu: $menu, ops: $ops, payments: $payments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportsSnapshotDtoImpl &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt) &&
            (identical(other.rangeFrom, rangeFrom) ||
                other.rangeFrom == rangeFrom) &&
            (identical(other.rangeTo, rangeTo) || other.rangeTo == rangeTo) &&
            (identical(other.range, range) || other.range == range) &&
            (identical(other.filterOptions, filterOptions) ||
                other.filterOptions == filterOptions) &&
            (identical(other.sales, sales) || other.sales == sales) &&
            (identical(other.staff, staff) || other.staff == staff) &&
            (identical(other.menu, menu) || other.menu == menu) &&
            (identical(other.ops, ops) || other.ops == ops) &&
            (identical(other.payments, payments) ||
                other.payments == payments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    generatedAt,
    rangeFrom,
    rangeTo,
    range,
    filterOptions,
    sales,
    staff,
    menu,
    ops,
    payments,
  );

  /// Create a copy of ReportsSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportsSnapshotDtoImplCopyWith<_$ReportsSnapshotDtoImpl> get copyWith =>
      __$$ReportsSnapshotDtoImplCopyWithImpl<_$ReportsSnapshotDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReportsSnapshotDtoImplToJson(this);
  }
}

abstract class _ReportsSnapshotDto implements ReportsSnapshotDto {
  const factory _ReportsSnapshotDto({
    required final String generatedAt,
    required final String rangeFrom,
    required final String rangeTo,
    required final String range,
    required final FilterOptionsDto filterOptions,
    required final SalesSectionDto sales,
    required final StaffSectionDto staff,
    required final MenuSectionDto menu,
    required final OpsSectionDto ops,
    final PaymentsSectionDto payments,
  }) = _$ReportsSnapshotDtoImpl;

  factory _ReportsSnapshotDto.fromJson(Map<String, dynamic> json) =
      _$ReportsSnapshotDtoImpl.fromJson;

  @override
  String get generatedAt;
  @override
  String get rangeFrom;
  @override
  String get rangeTo;
  @override
  String get range;
  @override
  FilterOptionsDto get filterOptions;
  @override
  SalesSectionDto get sales;
  @override
  StaffSectionDto get staff;
  @override
  MenuSectionDto get menu;
  @override
  OpsSectionDto get ops;
  @override
  PaymentsSectionDto get payments;

  /// Create a copy of ReportsSnapshotDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReportsSnapshotDtoImplCopyWith<_$ReportsSnapshotDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FilterOptionsDto _$FilterOptionsDtoFromJson(Map<String, dynamic> json) {
  return _FilterOptionsDto.fromJson(json);
}

/// @nodoc
mixin _$FilterOptionsDto {
  List<NamedIdDto> get servers => throw _privateConstructorUsedError;
  List<NamedIdDto> get zones => throw _privateConstructorUsedError;
  List<NamedIdDto> get categories => throw _privateConstructorUsedError;

  /// Serializes this FilterOptionsDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FilterOptionsDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FilterOptionsDtoCopyWith<FilterOptionsDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterOptionsDtoCopyWith<$Res> {
  factory $FilterOptionsDtoCopyWith(
    FilterOptionsDto value,
    $Res Function(FilterOptionsDto) then,
  ) = _$FilterOptionsDtoCopyWithImpl<$Res, FilterOptionsDto>;
  @useResult
  $Res call({
    List<NamedIdDto> servers,
    List<NamedIdDto> zones,
    List<NamedIdDto> categories,
  });
}

/// @nodoc
class _$FilterOptionsDtoCopyWithImpl<$Res, $Val extends FilterOptionsDto>
    implements $FilterOptionsDtoCopyWith<$Res> {
  _$FilterOptionsDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FilterOptionsDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? servers = null,
    Object? zones = null,
    Object? categories = null,
  }) {
    return _then(
      _value.copyWith(
            servers: null == servers
                ? _value.servers
                : servers // ignore: cast_nullable_to_non_nullable
                      as List<NamedIdDto>,
            zones: null == zones
                ? _value.zones
                : zones // ignore: cast_nullable_to_non_nullable
                      as List<NamedIdDto>,
            categories: null == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as List<NamedIdDto>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FilterOptionsDtoImplCopyWith<$Res>
    implements $FilterOptionsDtoCopyWith<$Res> {
  factory _$$FilterOptionsDtoImplCopyWith(
    _$FilterOptionsDtoImpl value,
    $Res Function(_$FilterOptionsDtoImpl) then,
  ) = __$$FilterOptionsDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<NamedIdDto> servers,
    List<NamedIdDto> zones,
    List<NamedIdDto> categories,
  });
}

/// @nodoc
class __$$FilterOptionsDtoImplCopyWithImpl<$Res>
    extends _$FilterOptionsDtoCopyWithImpl<$Res, _$FilterOptionsDtoImpl>
    implements _$$FilterOptionsDtoImplCopyWith<$Res> {
  __$$FilterOptionsDtoImplCopyWithImpl(
    _$FilterOptionsDtoImpl _value,
    $Res Function(_$FilterOptionsDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FilterOptionsDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? servers = null,
    Object? zones = null,
    Object? categories = null,
  }) {
    return _then(
      _$FilterOptionsDtoImpl(
        servers: null == servers
            ? _value._servers
            : servers // ignore: cast_nullable_to_non_nullable
                  as List<NamedIdDto>,
        zones: null == zones
            ? _value._zones
            : zones // ignore: cast_nullable_to_non_nullable
                  as List<NamedIdDto>,
        categories: null == categories
            ? _value._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as List<NamedIdDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FilterOptionsDtoImpl implements _FilterOptionsDto {
  const _$FilterOptionsDtoImpl({
    final List<NamedIdDto> servers = const <NamedIdDto>[],
    final List<NamedIdDto> zones = const <NamedIdDto>[],
    final List<NamedIdDto> categories = const <NamedIdDto>[],
  }) : _servers = servers,
       _zones = zones,
       _categories = categories;

  factory _$FilterOptionsDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FilterOptionsDtoImplFromJson(json);

  final List<NamedIdDto> _servers;
  @override
  @JsonKey()
  List<NamedIdDto> get servers {
    if (_servers is EqualUnmodifiableListView) return _servers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_servers);
  }

  final List<NamedIdDto> _zones;
  @override
  @JsonKey()
  List<NamedIdDto> get zones {
    if (_zones is EqualUnmodifiableListView) return _zones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_zones);
  }

  final List<NamedIdDto> _categories;
  @override
  @JsonKey()
  List<NamedIdDto> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  String toString() {
    return 'FilterOptionsDto(servers: $servers, zones: $zones, categories: $categories)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FilterOptionsDtoImpl &&
            const DeepCollectionEquality().equals(other._servers, _servers) &&
            const DeepCollectionEquality().equals(other._zones, _zones) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_servers),
    const DeepCollectionEquality().hash(_zones),
    const DeepCollectionEquality().hash(_categories),
  );

  /// Create a copy of FilterOptionsDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FilterOptionsDtoImplCopyWith<_$FilterOptionsDtoImpl> get copyWith =>
      __$$FilterOptionsDtoImplCopyWithImpl<_$FilterOptionsDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FilterOptionsDtoImplToJson(this);
  }
}

abstract class _FilterOptionsDto implements FilterOptionsDto {
  const factory _FilterOptionsDto({
    final List<NamedIdDto> servers,
    final List<NamedIdDto> zones,
    final List<NamedIdDto> categories,
  }) = _$FilterOptionsDtoImpl;

  factory _FilterOptionsDto.fromJson(Map<String, dynamic> json) =
      _$FilterOptionsDtoImpl.fromJson;

  @override
  List<NamedIdDto> get servers;
  @override
  List<NamedIdDto> get zones;
  @override
  List<NamedIdDto> get categories;

  /// Create a copy of FilterOptionsDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FilterOptionsDtoImplCopyWith<_$FilterOptionsDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NamedIdDto _$NamedIdDtoFromJson(Map<String, dynamic> json) {
  return _NamedIdDto.fromJson(json);
}

/// @nodoc
mixin _$NamedIdDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this NamedIdDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NamedIdDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NamedIdDtoCopyWith<NamedIdDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NamedIdDtoCopyWith<$Res> {
  factory $NamedIdDtoCopyWith(
    NamedIdDto value,
    $Res Function(NamedIdDto) then,
  ) = _$NamedIdDtoCopyWithImpl<$Res, NamedIdDto>;
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class _$NamedIdDtoCopyWithImpl<$Res, $Val extends NamedIdDto>
    implements $NamedIdDtoCopyWith<$Res> {
  _$NamedIdDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NamedIdDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NamedIdDtoImplCopyWith<$Res>
    implements $NamedIdDtoCopyWith<$Res> {
  factory _$$NamedIdDtoImplCopyWith(
    _$NamedIdDtoImpl value,
    $Res Function(_$NamedIdDtoImpl) then,
  ) = __$$NamedIdDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class __$$NamedIdDtoImplCopyWithImpl<$Res>
    extends _$NamedIdDtoCopyWithImpl<$Res, _$NamedIdDtoImpl>
    implements _$$NamedIdDtoImplCopyWith<$Res> {
  __$$NamedIdDtoImplCopyWithImpl(
    _$NamedIdDtoImpl _value,
    $Res Function(_$NamedIdDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NamedIdDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null}) {
    return _then(
      _$NamedIdDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NamedIdDtoImpl implements _NamedIdDto {
  const _$NamedIdDtoImpl({required this.id, required this.name});

  factory _$NamedIdDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$NamedIdDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  @override
  String toString() {
    return 'NamedIdDto(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NamedIdDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of NamedIdDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NamedIdDtoImplCopyWith<_$NamedIdDtoImpl> get copyWith =>
      __$$NamedIdDtoImplCopyWithImpl<_$NamedIdDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NamedIdDtoImplToJson(this);
  }
}

abstract class _NamedIdDto implements NamedIdDto {
  const factory _NamedIdDto({
    required final String id,
    required final String name,
  }) = _$NamedIdDtoImpl;

  factory _NamedIdDto.fromJson(Map<String, dynamic> json) =
      _$NamedIdDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Create a copy of NamedIdDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NamedIdDtoImplCopyWith<_$NamedIdDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

KpiTileDto _$KpiTileDtoFromJson(Map<String, dynamic> json) {
  return _KpiTileDto.fromJson(json);
}

/// @nodoc
mixin _$KpiTileDto {
  /// Stable id for the tile, rendered by `kpiLabel`/`kpiSub` at read time
  /// (ADR-0085). [label] and [sub] survive only as the fallback for a code
  /// this build does not know.
  String get key => throw _privateConstructorUsedError;

  /// The caption's counts, in the order its message declares them.
  List<int> get args => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;

  /// Money tiles ship the amount, not its rendering — `jt` and `rb` are
  /// Indonesian words and the reader picks its own (`kpiValue`). Tiles that
  /// are not money (a duration, a ratio) keep using [value].
  int? get rupiah => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  String get sub => throw _privateConstructorUsedError;

  /// Serializes this KpiTileDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KpiTileDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KpiTileDtoCopyWith<KpiTileDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KpiTileDtoCopyWith<$Res> {
  factory $KpiTileDtoCopyWith(
    KpiTileDto value,
    $Res Function(KpiTileDto) then,
  ) = _$KpiTileDtoCopyWithImpl<$Res, KpiTileDto>;
  @useResult
  $Res call({
    String key,
    List<int> args,
    String label,
    int? rupiah,
    String value,
    String sub,
  });
}

/// @nodoc
class _$KpiTileDtoCopyWithImpl<$Res, $Val extends KpiTileDto>
    implements $KpiTileDtoCopyWith<$Res> {
  _$KpiTileDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KpiTileDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? args = null,
    Object? label = null,
    Object? rupiah = freezed,
    Object? value = null,
    Object? sub = null,
  }) {
    return _then(
      _value.copyWith(
            key: null == key
                ? _value.key
                : key // ignore: cast_nullable_to_non_nullable
                      as String,
            args: null == args
                ? _value.args
                : args // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            rupiah: freezed == rupiah
                ? _value.rupiah
                : rupiah // ignore: cast_nullable_to_non_nullable
                      as int?,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
            sub: null == sub
                ? _value.sub
                : sub // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$KpiTileDtoImplCopyWith<$Res>
    implements $KpiTileDtoCopyWith<$Res> {
  factory _$$KpiTileDtoImplCopyWith(
    _$KpiTileDtoImpl value,
    $Res Function(_$KpiTileDtoImpl) then,
  ) = __$$KpiTileDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String key,
    List<int> args,
    String label,
    int? rupiah,
    String value,
    String sub,
  });
}

/// @nodoc
class __$$KpiTileDtoImplCopyWithImpl<$Res>
    extends _$KpiTileDtoCopyWithImpl<$Res, _$KpiTileDtoImpl>
    implements _$$KpiTileDtoImplCopyWith<$Res> {
  __$$KpiTileDtoImplCopyWithImpl(
    _$KpiTileDtoImpl _value,
    $Res Function(_$KpiTileDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of KpiTileDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? args = null,
    Object? label = null,
    Object? rupiah = freezed,
    Object? value = null,
    Object? sub = null,
  }) {
    return _then(
      _$KpiTileDtoImpl(
        key: null == key
            ? _value.key
            : key // ignore: cast_nullable_to_non_nullable
                  as String,
        args: null == args
            ? _value._args
            : args // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        rupiah: freezed == rupiah
            ? _value.rupiah
            : rupiah // ignore: cast_nullable_to_non_nullable
                  as int?,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        sub: null == sub
            ? _value.sub
            : sub // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$KpiTileDtoImpl implements _KpiTileDto {
  const _$KpiTileDtoImpl({
    this.key = '',
    final List<int> args = const <int>[],
    this.label = '',
    this.rupiah,
    this.value = '',
    this.sub = '',
  }) : _args = args;

  factory _$KpiTileDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$KpiTileDtoImplFromJson(json);

  /// Stable id for the tile, rendered by `kpiLabel`/`kpiSub` at read time
  /// (ADR-0085). [label] and [sub] survive only as the fallback for a code
  /// this build does not know.
  @override
  @JsonKey()
  final String key;

  /// The caption's counts, in the order its message declares them.
  final List<int> _args;

  /// The caption's counts, in the order its message declares them.
  @override
  @JsonKey()
  List<int> get args {
    if (_args is EqualUnmodifiableListView) return _args;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_args);
  }

  @override
  @JsonKey()
  final String label;

  /// Money tiles ship the amount, not its rendering — `jt` and `rb` are
  /// Indonesian words and the reader picks its own (`kpiValue`). Tiles that
  /// are not money (a duration, a ratio) keep using [value].
  @override
  final int? rupiah;
  @override
  @JsonKey()
  final String value;
  @override
  @JsonKey()
  final String sub;

  @override
  String toString() {
    return 'KpiTileDto(key: $key, args: $args, label: $label, rupiah: $rupiah, value: $value, sub: $sub)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KpiTileDtoImpl &&
            (identical(other.key, key) || other.key == key) &&
            const DeepCollectionEquality().equals(other._args, _args) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.rupiah, rupiah) || other.rupiah == rupiah) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.sub, sub) || other.sub == sub));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    key,
    const DeepCollectionEquality().hash(_args),
    label,
    rupiah,
    value,
    sub,
  );

  /// Create a copy of KpiTileDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KpiTileDtoImplCopyWith<_$KpiTileDtoImpl> get copyWith =>
      __$$KpiTileDtoImplCopyWithImpl<_$KpiTileDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KpiTileDtoImplToJson(this);
  }
}

abstract class _KpiTileDto implements KpiTileDto {
  const factory _KpiTileDto({
    final String key,
    final List<int> args,
    final String label,
    final int? rupiah,
    final String value,
    final String sub,
  }) = _$KpiTileDtoImpl;

  factory _KpiTileDto.fromJson(Map<String, dynamic> json) =
      _$KpiTileDtoImpl.fromJson;

  /// Stable id for the tile, rendered by `kpiLabel`/`kpiSub` at read time
  /// (ADR-0085). [label] and [sub] survive only as the fallback for a code
  /// this build does not know.
  @override
  String get key;

  /// The caption's counts, in the order its message declares them.
  @override
  List<int> get args;
  @override
  String get label;

  /// Money tiles ship the amount, not its rendering — `jt` and `rb` are
  /// Indonesian words and the reader picks its own (`kpiValue`). Tiles that
  /// are not money (a duration, a ratio) keep using [value].
  @override
  int? get rupiah;
  @override
  String get value;
  @override
  String get sub;

  /// Create a copy of KpiTileDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KpiTileDtoImplCopyWith<_$KpiTileDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SalesSectionDto _$SalesSectionDtoFromJson(Map<String, dynamic> json) {
  return _SalesSectionDto.fromJson(json);
}

/// @nodoc
mixin _$SalesSectionDto {
  List<KpiTileDto> get kpis => throw _privateConstructorUsedError;
  List<CoverDayDto> get coverTrend => throw _privateConstructorUsedError;
  List<double> get hourly => throw _privateConstructorUsedError;
  TakeawaySplitDto? get takeaway => throw _privateConstructorUsedError;

  /// Serializes this SalesSectionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SalesSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SalesSectionDtoCopyWith<SalesSectionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SalesSectionDtoCopyWith<$Res> {
  factory $SalesSectionDtoCopyWith(
    SalesSectionDto value,
    $Res Function(SalesSectionDto) then,
  ) = _$SalesSectionDtoCopyWithImpl<$Res, SalesSectionDto>;
  @useResult
  $Res call({
    List<KpiTileDto> kpis,
    List<CoverDayDto> coverTrend,
    List<double> hourly,
    TakeawaySplitDto? takeaway,
  });

  $TakeawaySplitDtoCopyWith<$Res>? get takeaway;
}

/// @nodoc
class _$SalesSectionDtoCopyWithImpl<$Res, $Val extends SalesSectionDto>
    implements $SalesSectionDtoCopyWith<$Res> {
  _$SalesSectionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SalesSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kpis = null,
    Object? coverTrend = null,
    Object? hourly = null,
    Object? takeaway = freezed,
  }) {
    return _then(
      _value.copyWith(
            kpis: null == kpis
                ? _value.kpis
                : kpis // ignore: cast_nullable_to_non_nullable
                      as List<KpiTileDto>,
            coverTrend: null == coverTrend
                ? _value.coverTrend
                : coverTrend // ignore: cast_nullable_to_non_nullable
                      as List<CoverDayDto>,
            hourly: null == hourly
                ? _value.hourly
                : hourly // ignore: cast_nullable_to_non_nullable
                      as List<double>,
            takeaway: freezed == takeaway
                ? _value.takeaway
                : takeaway // ignore: cast_nullable_to_non_nullable
                      as TakeawaySplitDto?,
          )
          as $Val,
    );
  }

  /// Create a copy of SalesSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TakeawaySplitDtoCopyWith<$Res>? get takeaway {
    if (_value.takeaway == null) {
      return null;
    }

    return $TakeawaySplitDtoCopyWith<$Res>(_value.takeaway!, (value) {
      return _then(_value.copyWith(takeaway: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SalesSectionDtoImplCopyWith<$Res>
    implements $SalesSectionDtoCopyWith<$Res> {
  factory _$$SalesSectionDtoImplCopyWith(
    _$SalesSectionDtoImpl value,
    $Res Function(_$SalesSectionDtoImpl) then,
  ) = __$$SalesSectionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<KpiTileDto> kpis,
    List<CoverDayDto> coverTrend,
    List<double> hourly,
    TakeawaySplitDto? takeaway,
  });

  @override
  $TakeawaySplitDtoCopyWith<$Res>? get takeaway;
}

/// @nodoc
class __$$SalesSectionDtoImplCopyWithImpl<$Res>
    extends _$SalesSectionDtoCopyWithImpl<$Res, _$SalesSectionDtoImpl>
    implements _$$SalesSectionDtoImplCopyWith<$Res> {
  __$$SalesSectionDtoImplCopyWithImpl(
    _$SalesSectionDtoImpl _value,
    $Res Function(_$SalesSectionDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SalesSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kpis = null,
    Object? coverTrend = null,
    Object? hourly = null,
    Object? takeaway = freezed,
  }) {
    return _then(
      _$SalesSectionDtoImpl(
        kpis: null == kpis
            ? _value._kpis
            : kpis // ignore: cast_nullable_to_non_nullable
                  as List<KpiTileDto>,
        coverTrend: null == coverTrend
            ? _value._coverTrend
            : coverTrend // ignore: cast_nullable_to_non_nullable
                  as List<CoverDayDto>,
        hourly: null == hourly
            ? _value._hourly
            : hourly // ignore: cast_nullable_to_non_nullable
                  as List<double>,
        takeaway: freezed == takeaway
            ? _value.takeaway
            : takeaway // ignore: cast_nullable_to_non_nullable
                  as TakeawaySplitDto?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SalesSectionDtoImpl implements _SalesSectionDto {
  const _$SalesSectionDtoImpl({
    final List<KpiTileDto> kpis = const <KpiTileDto>[],
    final List<CoverDayDto> coverTrend = const <CoverDayDto>[],
    final List<double> hourly = const <double>[],
    this.takeaway,
  }) : _kpis = kpis,
       _coverTrend = coverTrend,
       _hourly = hourly;

  factory _$SalesSectionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SalesSectionDtoImplFromJson(json);

  final List<KpiTileDto> _kpis;
  @override
  @JsonKey()
  List<KpiTileDto> get kpis {
    if (_kpis is EqualUnmodifiableListView) return _kpis;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_kpis);
  }

  final List<CoverDayDto> _coverTrend;
  @override
  @JsonKey()
  List<CoverDayDto> get coverTrend {
    if (_coverTrend is EqualUnmodifiableListView) return _coverTrend;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_coverTrend);
  }

  final List<double> _hourly;
  @override
  @JsonKey()
  List<double> get hourly {
    if (_hourly is EqualUnmodifiableListView) return _hourly;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hourly);
  }

  @override
  final TakeawaySplitDto? takeaway;

  @override
  String toString() {
    return 'SalesSectionDto(kpis: $kpis, coverTrend: $coverTrend, hourly: $hourly, takeaway: $takeaway)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SalesSectionDtoImpl &&
            const DeepCollectionEquality().equals(other._kpis, _kpis) &&
            const DeepCollectionEquality().equals(
              other._coverTrend,
              _coverTrend,
            ) &&
            const DeepCollectionEquality().equals(other._hourly, _hourly) &&
            (identical(other.takeaway, takeaway) ||
                other.takeaway == takeaway));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_kpis),
    const DeepCollectionEquality().hash(_coverTrend),
    const DeepCollectionEquality().hash(_hourly),
    takeaway,
  );

  /// Create a copy of SalesSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SalesSectionDtoImplCopyWith<_$SalesSectionDtoImpl> get copyWith =>
      __$$SalesSectionDtoImplCopyWithImpl<_$SalesSectionDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SalesSectionDtoImplToJson(this);
  }
}

abstract class _SalesSectionDto implements SalesSectionDto {
  const factory _SalesSectionDto({
    final List<KpiTileDto> kpis,
    final List<CoverDayDto> coverTrend,
    final List<double> hourly,
    final TakeawaySplitDto? takeaway,
  }) = _$SalesSectionDtoImpl;

  factory _SalesSectionDto.fromJson(Map<String, dynamic> json) =
      _$SalesSectionDtoImpl.fromJson;

  @override
  List<KpiTileDto> get kpis;
  @override
  List<CoverDayDto> get coverTrend;
  @override
  List<double> get hourly;
  @override
  TakeawaySplitDto? get takeaway;

  /// Create a copy of SalesSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SalesSectionDtoImplCopyWith<_$SalesSectionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TakeawaySplitDto _$TakeawaySplitDtoFromJson(Map<String, dynamic> json) {
  return _TakeawaySplitDto.fromJson(json);
}

/// @nodoc
mixin _$TakeawaySplitDto {
  int get count => throw _privateConstructorUsedError;
  int get net => throw _privateConstructorUsedError;
  int get dineInCount => throw _privateConstructorUsedError;
  int get dineInNet => throw _privateConstructorUsedError;

  /// Serializes this TakeawaySplitDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TakeawaySplitDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TakeawaySplitDtoCopyWith<TakeawaySplitDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TakeawaySplitDtoCopyWith<$Res> {
  factory $TakeawaySplitDtoCopyWith(
    TakeawaySplitDto value,
    $Res Function(TakeawaySplitDto) then,
  ) = _$TakeawaySplitDtoCopyWithImpl<$Res, TakeawaySplitDto>;
  @useResult
  $Res call({int count, int net, int dineInCount, int dineInNet});
}

/// @nodoc
class _$TakeawaySplitDtoCopyWithImpl<$Res, $Val extends TakeawaySplitDto>
    implements $TakeawaySplitDtoCopyWith<$Res> {
  _$TakeawaySplitDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TakeawaySplitDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? net = null,
    Object? dineInCount = null,
    Object? dineInNet = null,
  }) {
    return _then(
      _value.copyWith(
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
            net: null == net
                ? _value.net
                : net // ignore: cast_nullable_to_non_nullable
                      as int,
            dineInCount: null == dineInCount
                ? _value.dineInCount
                : dineInCount // ignore: cast_nullable_to_non_nullable
                      as int,
            dineInNet: null == dineInNet
                ? _value.dineInNet
                : dineInNet // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TakeawaySplitDtoImplCopyWith<$Res>
    implements $TakeawaySplitDtoCopyWith<$Res> {
  factory _$$TakeawaySplitDtoImplCopyWith(
    _$TakeawaySplitDtoImpl value,
    $Res Function(_$TakeawaySplitDtoImpl) then,
  ) = __$$TakeawaySplitDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int count, int net, int dineInCount, int dineInNet});
}

/// @nodoc
class __$$TakeawaySplitDtoImplCopyWithImpl<$Res>
    extends _$TakeawaySplitDtoCopyWithImpl<$Res, _$TakeawaySplitDtoImpl>
    implements _$$TakeawaySplitDtoImplCopyWith<$Res> {
  __$$TakeawaySplitDtoImplCopyWithImpl(
    _$TakeawaySplitDtoImpl _value,
    $Res Function(_$TakeawaySplitDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TakeawaySplitDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? net = null,
    Object? dineInCount = null,
    Object? dineInNet = null,
  }) {
    return _then(
      _$TakeawaySplitDtoImpl(
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        net: null == net
            ? _value.net
            : net // ignore: cast_nullable_to_non_nullable
                  as int,
        dineInCount: null == dineInCount
            ? _value.dineInCount
            : dineInCount // ignore: cast_nullable_to_non_nullable
                  as int,
        dineInNet: null == dineInNet
            ? _value.dineInNet
            : dineInNet // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TakeawaySplitDtoImpl implements _TakeawaySplitDto {
  const _$TakeawaySplitDtoImpl({
    this.count = 0,
    this.net = 0,
    this.dineInCount = 0,
    this.dineInNet = 0,
  });

  factory _$TakeawaySplitDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TakeawaySplitDtoImplFromJson(json);

  @override
  @JsonKey()
  final int count;
  @override
  @JsonKey()
  final int net;
  @override
  @JsonKey()
  final int dineInCount;
  @override
  @JsonKey()
  final int dineInNet;

  @override
  String toString() {
    return 'TakeawaySplitDto(count: $count, net: $net, dineInCount: $dineInCount, dineInNet: $dineInNet)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TakeawaySplitDtoImpl &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.net, net) || other.net == net) &&
            (identical(other.dineInCount, dineInCount) ||
                other.dineInCount == dineInCount) &&
            (identical(other.dineInNet, dineInNet) ||
                other.dineInNet == dineInNet));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, count, net, dineInCount, dineInNet);

  /// Create a copy of TakeawaySplitDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TakeawaySplitDtoImplCopyWith<_$TakeawaySplitDtoImpl> get copyWith =>
      __$$TakeawaySplitDtoImplCopyWithImpl<_$TakeawaySplitDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TakeawaySplitDtoImplToJson(this);
  }
}

abstract class _TakeawaySplitDto implements TakeawaySplitDto {
  const factory _TakeawaySplitDto({
    final int count,
    final int net,
    final int dineInCount,
    final int dineInNet,
  }) = _$TakeawaySplitDtoImpl;

  factory _TakeawaySplitDto.fromJson(Map<String, dynamic> json) =
      _$TakeawaySplitDtoImpl.fromJson;

  @override
  int get count;
  @override
  int get net;
  @override
  int get dineInCount;
  @override
  int get dineInNet;

  /// Create a copy of TakeawaySplitDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TakeawaySplitDtoImplCopyWith<_$TakeawaySplitDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CoverDayDto _$CoverDayDtoFromJson(Map<String, dynamic> json) {
  return _CoverDayDto.fromJson(json);
}

/// @nodoc
mixin _$CoverDayDto {
  /// ISO weekday, 1 = Monday. Spelled by [formatWeekdayShort] at read time.
  int get dow => throw _privateConstructorUsedError;
  int get thisWeek => throw _privateConstructorUsedError;
  int get lastWeek => throw _privateConstructorUsedError;

  /// Serializes this CoverDayDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CoverDayDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoverDayDtoCopyWith<CoverDayDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoverDayDtoCopyWith<$Res> {
  factory $CoverDayDtoCopyWith(
    CoverDayDto value,
    $Res Function(CoverDayDto) then,
  ) = _$CoverDayDtoCopyWithImpl<$Res, CoverDayDto>;
  @useResult
  $Res call({int dow, int thisWeek, int lastWeek});
}

/// @nodoc
class _$CoverDayDtoCopyWithImpl<$Res, $Val extends CoverDayDto>
    implements $CoverDayDtoCopyWith<$Res> {
  _$CoverDayDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoverDayDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dow = null,
    Object? thisWeek = null,
    Object? lastWeek = null,
  }) {
    return _then(
      _value.copyWith(
            dow: null == dow
                ? _value.dow
                : dow // ignore: cast_nullable_to_non_nullable
                      as int,
            thisWeek: null == thisWeek
                ? _value.thisWeek
                : thisWeek // ignore: cast_nullable_to_non_nullable
                      as int,
            lastWeek: null == lastWeek
                ? _value.lastWeek
                : lastWeek // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CoverDayDtoImplCopyWith<$Res>
    implements $CoverDayDtoCopyWith<$Res> {
  factory _$$CoverDayDtoImplCopyWith(
    _$CoverDayDtoImpl value,
    $Res Function(_$CoverDayDtoImpl) then,
  ) = __$$CoverDayDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int dow, int thisWeek, int lastWeek});
}

/// @nodoc
class __$$CoverDayDtoImplCopyWithImpl<$Res>
    extends _$CoverDayDtoCopyWithImpl<$Res, _$CoverDayDtoImpl>
    implements _$$CoverDayDtoImplCopyWith<$Res> {
  __$$CoverDayDtoImplCopyWithImpl(
    _$CoverDayDtoImpl _value,
    $Res Function(_$CoverDayDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CoverDayDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dow = null,
    Object? thisWeek = null,
    Object? lastWeek = null,
  }) {
    return _then(
      _$CoverDayDtoImpl(
        dow: null == dow
            ? _value.dow
            : dow // ignore: cast_nullable_to_non_nullable
                  as int,
        thisWeek: null == thisWeek
            ? _value.thisWeek
            : thisWeek // ignore: cast_nullable_to_non_nullable
                  as int,
        lastWeek: null == lastWeek
            ? _value.lastWeek
            : lastWeek // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CoverDayDtoImpl implements _CoverDayDto {
  const _$CoverDayDtoImpl({
    this.dow = 1,
    required this.thisWeek,
    required this.lastWeek,
  });

  factory _$CoverDayDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoverDayDtoImplFromJson(json);

  /// ISO weekday, 1 = Monday. Spelled by [formatWeekdayShort] at read time.
  @override
  @JsonKey()
  final int dow;
  @override
  final int thisWeek;
  @override
  final int lastWeek;

  @override
  String toString() {
    return 'CoverDayDto(dow: $dow, thisWeek: $thisWeek, lastWeek: $lastWeek)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoverDayDtoImpl &&
            (identical(other.dow, dow) || other.dow == dow) &&
            (identical(other.thisWeek, thisWeek) ||
                other.thisWeek == thisWeek) &&
            (identical(other.lastWeek, lastWeek) ||
                other.lastWeek == lastWeek));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, dow, thisWeek, lastWeek);

  /// Create a copy of CoverDayDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoverDayDtoImplCopyWith<_$CoverDayDtoImpl> get copyWith =>
      __$$CoverDayDtoImplCopyWithImpl<_$CoverDayDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CoverDayDtoImplToJson(this);
  }
}

abstract class _CoverDayDto implements CoverDayDto {
  const factory _CoverDayDto({
    final int dow,
    required final int thisWeek,
    required final int lastWeek,
  }) = _$CoverDayDtoImpl;

  factory _CoverDayDto.fromJson(Map<String, dynamic> json) =
      _$CoverDayDtoImpl.fromJson;

  /// ISO weekday, 1 = Monday. Spelled by [formatWeekdayShort] at read time.
  @override
  int get dow;
  @override
  int get thisWeek;
  @override
  int get lastWeek;

  /// Create a copy of CoverDayDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoverDayDtoImplCopyWith<_$CoverDayDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StaffSectionDto _$StaffSectionDtoFromJson(Map<String, dynamic> json) {
  return _StaffSectionDto.fromJson(json);
}

/// @nodoc
mixin _$StaffSectionDto {
  List<StaffRowDto> get rows => throw _privateConstructorUsedError;
  List<StaffUpsellDto> get upsell => throw _privateConstructorUsedError;

  /// Serializes this StaffSectionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StaffSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StaffSectionDtoCopyWith<StaffSectionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StaffSectionDtoCopyWith<$Res> {
  factory $StaffSectionDtoCopyWith(
    StaffSectionDto value,
    $Res Function(StaffSectionDto) then,
  ) = _$StaffSectionDtoCopyWithImpl<$Res, StaffSectionDto>;
  @useResult
  $Res call({List<StaffRowDto> rows, List<StaffUpsellDto> upsell});
}

/// @nodoc
class _$StaffSectionDtoCopyWithImpl<$Res, $Val extends StaffSectionDto>
    implements $StaffSectionDtoCopyWith<$Res> {
  _$StaffSectionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StaffSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? rows = null, Object? upsell = null}) {
    return _then(
      _value.copyWith(
            rows: null == rows
                ? _value.rows
                : rows // ignore: cast_nullable_to_non_nullable
                      as List<StaffRowDto>,
            upsell: null == upsell
                ? _value.upsell
                : upsell // ignore: cast_nullable_to_non_nullable
                      as List<StaffUpsellDto>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StaffSectionDtoImplCopyWith<$Res>
    implements $StaffSectionDtoCopyWith<$Res> {
  factory _$$StaffSectionDtoImplCopyWith(
    _$StaffSectionDtoImpl value,
    $Res Function(_$StaffSectionDtoImpl) then,
  ) = __$$StaffSectionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<StaffRowDto> rows, List<StaffUpsellDto> upsell});
}

/// @nodoc
class __$$StaffSectionDtoImplCopyWithImpl<$Res>
    extends _$StaffSectionDtoCopyWithImpl<$Res, _$StaffSectionDtoImpl>
    implements _$$StaffSectionDtoImplCopyWith<$Res> {
  __$$StaffSectionDtoImplCopyWithImpl(
    _$StaffSectionDtoImpl _value,
    $Res Function(_$StaffSectionDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StaffSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? rows = null, Object? upsell = null}) {
    return _then(
      _$StaffSectionDtoImpl(
        rows: null == rows
            ? _value._rows
            : rows // ignore: cast_nullable_to_non_nullable
                  as List<StaffRowDto>,
        upsell: null == upsell
            ? _value._upsell
            : upsell // ignore: cast_nullable_to_non_nullable
                  as List<StaffUpsellDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StaffSectionDtoImpl implements _StaffSectionDto {
  const _$StaffSectionDtoImpl({
    final List<StaffRowDto> rows = const <StaffRowDto>[],
    final List<StaffUpsellDto> upsell = const <StaffUpsellDto>[],
  }) : _rows = rows,
       _upsell = upsell;

  factory _$StaffSectionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StaffSectionDtoImplFromJson(json);

  final List<StaffRowDto> _rows;
  @override
  @JsonKey()
  List<StaffRowDto> get rows {
    if (_rows is EqualUnmodifiableListView) return _rows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rows);
  }

  final List<StaffUpsellDto> _upsell;
  @override
  @JsonKey()
  List<StaffUpsellDto> get upsell {
    if (_upsell is EqualUnmodifiableListView) return _upsell;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_upsell);
  }

  @override
  String toString() {
    return 'StaffSectionDto(rows: $rows, upsell: $upsell)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StaffSectionDtoImpl &&
            const DeepCollectionEquality().equals(other._rows, _rows) &&
            const DeepCollectionEquality().equals(other._upsell, _upsell));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_rows),
    const DeepCollectionEquality().hash(_upsell),
  );

  /// Create a copy of StaffSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StaffSectionDtoImplCopyWith<_$StaffSectionDtoImpl> get copyWith =>
      __$$StaffSectionDtoImplCopyWithImpl<_$StaffSectionDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StaffSectionDtoImplToJson(this);
  }
}

abstract class _StaffSectionDto implements StaffSectionDto {
  const factory _StaffSectionDto({
    final List<StaffRowDto> rows,
    final List<StaffUpsellDto> upsell,
  }) = _$StaffSectionDtoImpl;

  factory _StaffSectionDto.fromJson(Map<String, dynamic> json) =
      _$StaffSectionDtoImpl.fromJson;

  @override
  List<StaffRowDto> get rows;
  @override
  List<StaffUpsellDto> get upsell;

  /// Create a copy of StaffSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StaffSectionDtoImplCopyWith<_$StaffSectionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StaffRowDto _$StaffRowDtoFromJson(Map<String, dynamic> json) {
  return _StaffRowDto.fromJson(json);
}

/// @nodoc
mixin _$StaffRowDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get covers => throw _privateConstructorUsedError;
  int get items => throw _privateConstructorUsedError;
  int get avgTicket => throw _privateConstructorUsedError;
  double get voidPct => throw _privateConstructorUsedError;
  int get net => throw _privateConstructorUsedError;
  int get sessions => throw _privateConstructorUsedError;

  /// Serializes this StaffRowDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StaffRowDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StaffRowDtoCopyWith<StaffRowDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StaffRowDtoCopyWith<$Res> {
  factory $StaffRowDtoCopyWith(
    StaffRowDto value,
    $Res Function(StaffRowDto) then,
  ) = _$StaffRowDtoCopyWithImpl<$Res, StaffRowDto>;
  @useResult
  $Res call({
    String id,
    String name,
    int covers,
    int items,
    int avgTicket,
    double voidPct,
    int net,
    int sessions,
  });
}

/// @nodoc
class _$StaffRowDtoCopyWithImpl<$Res, $Val extends StaffRowDto>
    implements $StaffRowDtoCopyWith<$Res> {
  _$StaffRowDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StaffRowDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? covers = null,
    Object? items = null,
    Object? avgTicket = null,
    Object? voidPct = null,
    Object? net = null,
    Object? sessions = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            covers: null == covers
                ? _value.covers
                : covers // ignore: cast_nullable_to_non_nullable
                      as int,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as int,
            avgTicket: null == avgTicket
                ? _value.avgTicket
                : avgTicket // ignore: cast_nullable_to_non_nullable
                      as int,
            voidPct: null == voidPct
                ? _value.voidPct
                : voidPct // ignore: cast_nullable_to_non_nullable
                      as double,
            net: null == net
                ? _value.net
                : net // ignore: cast_nullable_to_non_nullable
                      as int,
            sessions: null == sessions
                ? _value.sessions
                : sessions // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StaffRowDtoImplCopyWith<$Res>
    implements $StaffRowDtoCopyWith<$Res> {
  factory _$$StaffRowDtoImplCopyWith(
    _$StaffRowDtoImpl value,
    $Res Function(_$StaffRowDtoImpl) then,
  ) = __$$StaffRowDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int covers,
    int items,
    int avgTicket,
    double voidPct,
    int net,
    int sessions,
  });
}

/// @nodoc
class __$$StaffRowDtoImplCopyWithImpl<$Res>
    extends _$StaffRowDtoCopyWithImpl<$Res, _$StaffRowDtoImpl>
    implements _$$StaffRowDtoImplCopyWith<$Res> {
  __$$StaffRowDtoImplCopyWithImpl(
    _$StaffRowDtoImpl _value,
    $Res Function(_$StaffRowDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StaffRowDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? covers = null,
    Object? items = null,
    Object? avgTicket = null,
    Object? voidPct = null,
    Object? net = null,
    Object? sessions = null,
  }) {
    return _then(
      _$StaffRowDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        covers: null == covers
            ? _value.covers
            : covers // ignore: cast_nullable_to_non_nullable
                  as int,
        items: null == items
            ? _value.items
            : items // ignore: cast_nullable_to_non_nullable
                  as int,
        avgTicket: null == avgTicket
            ? _value.avgTicket
            : avgTicket // ignore: cast_nullable_to_non_nullable
                  as int,
        voidPct: null == voidPct
            ? _value.voidPct
            : voidPct // ignore: cast_nullable_to_non_nullable
                  as double,
        net: null == net
            ? _value.net
            : net // ignore: cast_nullable_to_non_nullable
                  as int,
        sessions: null == sessions
            ? _value.sessions
            : sessions // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StaffRowDtoImpl implements _StaffRowDto {
  const _$StaffRowDtoImpl({
    required this.id,
    required this.name,
    this.covers = 0,
    this.items = 0,
    this.avgTicket = 0,
    this.voidPct = 0.0,
    this.net = 0,
    this.sessions = 0,
  });

  factory _$StaffRowDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StaffRowDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final int covers;
  @override
  @JsonKey()
  final int items;
  @override
  @JsonKey()
  final int avgTicket;
  @override
  @JsonKey()
  final double voidPct;
  @override
  @JsonKey()
  final int net;
  @override
  @JsonKey()
  final int sessions;

  @override
  String toString() {
    return 'StaffRowDto(id: $id, name: $name, covers: $covers, items: $items, avgTicket: $avgTicket, voidPct: $voidPct, net: $net, sessions: $sessions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StaffRowDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.covers, covers) || other.covers == covers) &&
            (identical(other.items, items) || other.items == items) &&
            (identical(other.avgTicket, avgTicket) ||
                other.avgTicket == avgTicket) &&
            (identical(other.voidPct, voidPct) || other.voidPct == voidPct) &&
            (identical(other.net, net) || other.net == net) &&
            (identical(other.sessions, sessions) ||
                other.sessions == sessions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    covers,
    items,
    avgTicket,
    voidPct,
    net,
    sessions,
  );

  /// Create a copy of StaffRowDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StaffRowDtoImplCopyWith<_$StaffRowDtoImpl> get copyWith =>
      __$$StaffRowDtoImplCopyWithImpl<_$StaffRowDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StaffRowDtoImplToJson(this);
  }
}

abstract class _StaffRowDto implements StaffRowDto {
  const factory _StaffRowDto({
    required final String id,
    required final String name,
    final int covers,
    final int items,
    final int avgTicket,
    final double voidPct,
    final int net,
    final int sessions,
  }) = _$StaffRowDtoImpl;

  factory _StaffRowDto.fromJson(Map<String, dynamic> json) =
      _$StaffRowDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get covers;
  @override
  int get items;
  @override
  int get avgTicket;
  @override
  double get voidPct;
  @override
  int get net;
  @override
  int get sessions;

  /// Create a copy of StaffRowDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StaffRowDtoImplCopyWith<_$StaffRowDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StaffUpsellDto _$StaffUpsellDtoFromJson(Map<String, dynamic> json) {
  return _StaffUpsellDto.fromJson(json);
}

/// @nodoc
mixin _$StaffUpsellDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get rate => throw _privateConstructorUsedError;

  /// Serializes this StaffUpsellDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StaffUpsellDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StaffUpsellDtoCopyWith<StaffUpsellDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StaffUpsellDtoCopyWith<$Res> {
  factory $StaffUpsellDtoCopyWith(
    StaffUpsellDto value,
    $Res Function(StaffUpsellDto) then,
  ) = _$StaffUpsellDtoCopyWithImpl<$Res, StaffUpsellDto>;
  @useResult
  $Res call({String id, String name, double rate});
}

/// @nodoc
class _$StaffUpsellDtoCopyWithImpl<$Res, $Val extends StaffUpsellDto>
    implements $StaffUpsellDtoCopyWith<$Res> {
  _$StaffUpsellDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StaffUpsellDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? rate = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            rate: null == rate
                ? _value.rate
                : rate // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StaffUpsellDtoImplCopyWith<$Res>
    implements $StaffUpsellDtoCopyWith<$Res> {
  factory _$$StaffUpsellDtoImplCopyWith(
    _$StaffUpsellDtoImpl value,
    $Res Function(_$StaffUpsellDtoImpl) then,
  ) = __$$StaffUpsellDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, double rate});
}

/// @nodoc
class __$$StaffUpsellDtoImplCopyWithImpl<$Res>
    extends _$StaffUpsellDtoCopyWithImpl<$Res, _$StaffUpsellDtoImpl>
    implements _$$StaffUpsellDtoImplCopyWith<$Res> {
  __$$StaffUpsellDtoImplCopyWithImpl(
    _$StaffUpsellDtoImpl _value,
    $Res Function(_$StaffUpsellDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StaffUpsellDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? rate = null}) {
    return _then(
      _$StaffUpsellDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        rate: null == rate
            ? _value.rate
            : rate // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StaffUpsellDtoImpl implements _StaffUpsellDto {
  const _$StaffUpsellDtoImpl({
    required this.id,
    required this.name,
    this.rate = 0.0,
  });

  factory _$StaffUpsellDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StaffUpsellDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final double rate;

  @override
  String toString() {
    return 'StaffUpsellDto(id: $id, name: $name, rate: $rate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StaffUpsellDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.rate, rate) || other.rate == rate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, rate);

  /// Create a copy of StaffUpsellDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StaffUpsellDtoImplCopyWith<_$StaffUpsellDtoImpl> get copyWith =>
      __$$StaffUpsellDtoImplCopyWithImpl<_$StaffUpsellDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StaffUpsellDtoImplToJson(this);
  }
}

abstract class _StaffUpsellDto implements StaffUpsellDto {
  const factory _StaffUpsellDto({
    required final String id,
    required final String name,
    final double rate,
  }) = _$StaffUpsellDtoImpl;

  factory _StaffUpsellDto.fromJson(Map<String, dynamic> json) =
      _$StaffUpsellDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get rate;

  /// Create a copy of StaffUpsellDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StaffUpsellDtoImplCopyWith<_$StaffUpsellDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MenuSectionDto _$MenuSectionDtoFromJson(Map<String, dynamic> json) {
  return _MenuSectionDto.fromJson(json);
}

/// @nodoc
mixin _$MenuSectionDto {
  List<MenuItemRowDto> get top => throw _privateConstructorUsedError;
  List<MenuItemRowDto> get slow => throw _privateConstructorUsedError;
  List<ModifierAttachDto> get modifierAttach =>
      throw _privateConstructorUsedError;
  List<CategoryShareDto> get categoryMix => throw _privateConstructorUsedError;
  List<MatrixItemDto> get matrix => throw _privateConstructorUsedError;
  List<BasketPairDto> get basketPairs => throw _privateConstructorUsedError;

  /// Serializes this MenuSectionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MenuSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuSectionDtoCopyWith<MenuSectionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuSectionDtoCopyWith<$Res> {
  factory $MenuSectionDtoCopyWith(
    MenuSectionDto value,
    $Res Function(MenuSectionDto) then,
  ) = _$MenuSectionDtoCopyWithImpl<$Res, MenuSectionDto>;
  @useResult
  $Res call({
    List<MenuItemRowDto> top,
    List<MenuItemRowDto> slow,
    List<ModifierAttachDto> modifierAttach,
    List<CategoryShareDto> categoryMix,
    List<MatrixItemDto> matrix,
    List<BasketPairDto> basketPairs,
  });
}

/// @nodoc
class _$MenuSectionDtoCopyWithImpl<$Res, $Val extends MenuSectionDto>
    implements $MenuSectionDtoCopyWith<$Res> {
  _$MenuSectionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MenuSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? top = null,
    Object? slow = null,
    Object? modifierAttach = null,
    Object? categoryMix = null,
    Object? matrix = null,
    Object? basketPairs = null,
  }) {
    return _then(
      _value.copyWith(
            top: null == top
                ? _value.top
                : top // ignore: cast_nullable_to_non_nullable
                      as List<MenuItemRowDto>,
            slow: null == slow
                ? _value.slow
                : slow // ignore: cast_nullable_to_non_nullable
                      as List<MenuItemRowDto>,
            modifierAttach: null == modifierAttach
                ? _value.modifierAttach
                : modifierAttach // ignore: cast_nullable_to_non_nullable
                      as List<ModifierAttachDto>,
            categoryMix: null == categoryMix
                ? _value.categoryMix
                : categoryMix // ignore: cast_nullable_to_non_nullable
                      as List<CategoryShareDto>,
            matrix: null == matrix
                ? _value.matrix
                : matrix // ignore: cast_nullable_to_non_nullable
                      as List<MatrixItemDto>,
            basketPairs: null == basketPairs
                ? _value.basketPairs
                : basketPairs // ignore: cast_nullable_to_non_nullable
                      as List<BasketPairDto>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MenuSectionDtoImplCopyWith<$Res>
    implements $MenuSectionDtoCopyWith<$Res> {
  factory _$$MenuSectionDtoImplCopyWith(
    _$MenuSectionDtoImpl value,
    $Res Function(_$MenuSectionDtoImpl) then,
  ) = __$$MenuSectionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<MenuItemRowDto> top,
    List<MenuItemRowDto> slow,
    List<ModifierAttachDto> modifierAttach,
    List<CategoryShareDto> categoryMix,
    List<MatrixItemDto> matrix,
    List<BasketPairDto> basketPairs,
  });
}

/// @nodoc
class __$$MenuSectionDtoImplCopyWithImpl<$Res>
    extends _$MenuSectionDtoCopyWithImpl<$Res, _$MenuSectionDtoImpl>
    implements _$$MenuSectionDtoImplCopyWith<$Res> {
  __$$MenuSectionDtoImplCopyWithImpl(
    _$MenuSectionDtoImpl _value,
    $Res Function(_$MenuSectionDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MenuSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? top = null,
    Object? slow = null,
    Object? modifierAttach = null,
    Object? categoryMix = null,
    Object? matrix = null,
    Object? basketPairs = null,
  }) {
    return _then(
      _$MenuSectionDtoImpl(
        top: null == top
            ? _value._top
            : top // ignore: cast_nullable_to_non_nullable
                  as List<MenuItemRowDto>,
        slow: null == slow
            ? _value._slow
            : slow // ignore: cast_nullable_to_non_nullable
                  as List<MenuItemRowDto>,
        modifierAttach: null == modifierAttach
            ? _value._modifierAttach
            : modifierAttach // ignore: cast_nullable_to_non_nullable
                  as List<ModifierAttachDto>,
        categoryMix: null == categoryMix
            ? _value._categoryMix
            : categoryMix // ignore: cast_nullable_to_non_nullable
                  as List<CategoryShareDto>,
        matrix: null == matrix
            ? _value._matrix
            : matrix // ignore: cast_nullable_to_non_nullable
                  as List<MatrixItemDto>,
        basketPairs: null == basketPairs
            ? _value._basketPairs
            : basketPairs // ignore: cast_nullable_to_non_nullable
                  as List<BasketPairDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuSectionDtoImpl implements _MenuSectionDto {
  const _$MenuSectionDtoImpl({
    final List<MenuItemRowDto> top = const <MenuItemRowDto>[],
    final List<MenuItemRowDto> slow = const <MenuItemRowDto>[],
    final List<ModifierAttachDto> modifierAttach = const <ModifierAttachDto>[],
    final List<CategoryShareDto> categoryMix = const <CategoryShareDto>[],
    final List<MatrixItemDto> matrix = const <MatrixItemDto>[],
    final List<BasketPairDto> basketPairs = const <BasketPairDto>[],
  }) : _top = top,
       _slow = slow,
       _modifierAttach = modifierAttach,
       _categoryMix = categoryMix,
       _matrix = matrix,
       _basketPairs = basketPairs;

  factory _$MenuSectionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuSectionDtoImplFromJson(json);

  final List<MenuItemRowDto> _top;
  @override
  @JsonKey()
  List<MenuItemRowDto> get top {
    if (_top is EqualUnmodifiableListView) return _top;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_top);
  }

  final List<MenuItemRowDto> _slow;
  @override
  @JsonKey()
  List<MenuItemRowDto> get slow {
    if (_slow is EqualUnmodifiableListView) return _slow;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_slow);
  }

  final List<ModifierAttachDto> _modifierAttach;
  @override
  @JsonKey()
  List<ModifierAttachDto> get modifierAttach {
    if (_modifierAttach is EqualUnmodifiableListView) return _modifierAttach;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifierAttach);
  }

  final List<CategoryShareDto> _categoryMix;
  @override
  @JsonKey()
  List<CategoryShareDto> get categoryMix {
    if (_categoryMix is EqualUnmodifiableListView) return _categoryMix;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categoryMix);
  }

  final List<MatrixItemDto> _matrix;
  @override
  @JsonKey()
  List<MatrixItemDto> get matrix {
    if (_matrix is EqualUnmodifiableListView) return _matrix;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_matrix);
  }

  final List<BasketPairDto> _basketPairs;
  @override
  @JsonKey()
  List<BasketPairDto> get basketPairs {
    if (_basketPairs is EqualUnmodifiableListView) return _basketPairs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_basketPairs);
  }

  @override
  String toString() {
    return 'MenuSectionDto(top: $top, slow: $slow, modifierAttach: $modifierAttach, categoryMix: $categoryMix, matrix: $matrix, basketPairs: $basketPairs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuSectionDtoImpl &&
            const DeepCollectionEquality().equals(other._top, _top) &&
            const DeepCollectionEquality().equals(other._slow, _slow) &&
            const DeepCollectionEquality().equals(
              other._modifierAttach,
              _modifierAttach,
            ) &&
            const DeepCollectionEquality().equals(
              other._categoryMix,
              _categoryMix,
            ) &&
            const DeepCollectionEquality().equals(other._matrix, _matrix) &&
            const DeepCollectionEquality().equals(
              other._basketPairs,
              _basketPairs,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_top),
    const DeepCollectionEquality().hash(_slow),
    const DeepCollectionEquality().hash(_modifierAttach),
    const DeepCollectionEquality().hash(_categoryMix),
    const DeepCollectionEquality().hash(_matrix),
    const DeepCollectionEquality().hash(_basketPairs),
  );

  /// Create a copy of MenuSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuSectionDtoImplCopyWith<_$MenuSectionDtoImpl> get copyWith =>
      __$$MenuSectionDtoImplCopyWithImpl<_$MenuSectionDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuSectionDtoImplToJson(this);
  }
}

abstract class _MenuSectionDto implements MenuSectionDto {
  const factory _MenuSectionDto({
    final List<MenuItemRowDto> top,
    final List<MenuItemRowDto> slow,
    final List<ModifierAttachDto> modifierAttach,
    final List<CategoryShareDto> categoryMix,
    final List<MatrixItemDto> matrix,
    final List<BasketPairDto> basketPairs,
  }) = _$MenuSectionDtoImpl;

  factory _MenuSectionDto.fromJson(Map<String, dynamic> json) =
      _$MenuSectionDtoImpl.fromJson;

  @override
  List<MenuItemRowDto> get top;
  @override
  List<MenuItemRowDto> get slow;
  @override
  List<ModifierAttachDto> get modifierAttach;
  @override
  List<CategoryShareDto> get categoryMix;
  @override
  List<MatrixItemDto> get matrix;
  @override
  List<BasketPairDto> get basketPairs;

  /// Create a copy of MenuSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuSectionDtoImplCopyWith<_$MenuSectionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MenuItemRowDto _$MenuItemRowDtoFromJson(Map<String, dynamic> json) {
  return _MenuItemRowDto.fromJson(json);
}

/// @nodoc
mixin _$MenuItemRowDto {
  String get itemId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get qty => throw _privateConstructorUsedError;
  int get revenue => throw _privateConstructorUsedError;
  int get marginPct => throw _privateConstructorUsedError;
  double get fill => throw _privateConstructorUsedError;

  /// Serializes this MenuItemRowDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MenuItemRowDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuItemRowDtoCopyWith<MenuItemRowDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuItemRowDtoCopyWith<$Res> {
  factory $MenuItemRowDtoCopyWith(
    MenuItemRowDto value,
    $Res Function(MenuItemRowDto) then,
  ) = _$MenuItemRowDtoCopyWithImpl<$Res, MenuItemRowDto>;
  @useResult
  $Res call({
    String itemId,
    String name,
    int qty,
    int revenue,
    int marginPct,
    double fill,
  });
}

/// @nodoc
class _$MenuItemRowDtoCopyWithImpl<$Res, $Val extends MenuItemRowDto>
    implements $MenuItemRowDtoCopyWith<$Res> {
  _$MenuItemRowDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MenuItemRowDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? name = null,
    Object? qty = null,
    Object? revenue = null,
    Object? marginPct = null,
    Object? fill = null,
  }) {
    return _then(
      _value.copyWith(
            itemId: null == itemId
                ? _value.itemId
                : itemId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
            revenue: null == revenue
                ? _value.revenue
                : revenue // ignore: cast_nullable_to_non_nullable
                      as int,
            marginPct: null == marginPct
                ? _value.marginPct
                : marginPct // ignore: cast_nullable_to_non_nullable
                      as int,
            fill: null == fill
                ? _value.fill
                : fill // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MenuItemRowDtoImplCopyWith<$Res>
    implements $MenuItemRowDtoCopyWith<$Res> {
  factory _$$MenuItemRowDtoImplCopyWith(
    _$MenuItemRowDtoImpl value,
    $Res Function(_$MenuItemRowDtoImpl) then,
  ) = __$$MenuItemRowDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String itemId,
    String name,
    int qty,
    int revenue,
    int marginPct,
    double fill,
  });
}

/// @nodoc
class __$$MenuItemRowDtoImplCopyWithImpl<$Res>
    extends _$MenuItemRowDtoCopyWithImpl<$Res, _$MenuItemRowDtoImpl>
    implements _$$MenuItemRowDtoImplCopyWith<$Res> {
  __$$MenuItemRowDtoImplCopyWithImpl(
    _$MenuItemRowDtoImpl _value,
    $Res Function(_$MenuItemRowDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MenuItemRowDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? name = null,
    Object? qty = null,
    Object? revenue = null,
    Object? marginPct = null,
    Object? fill = null,
  }) {
    return _then(
      _$MenuItemRowDtoImpl(
        itemId: null == itemId
            ? _value.itemId
            : itemId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
        revenue: null == revenue
            ? _value.revenue
            : revenue // ignore: cast_nullable_to_non_nullable
                  as int,
        marginPct: null == marginPct
            ? _value.marginPct
            : marginPct // ignore: cast_nullable_to_non_nullable
                  as int,
        fill: null == fill
            ? _value.fill
            : fill // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuItemRowDtoImpl implements _MenuItemRowDto {
  const _$MenuItemRowDtoImpl({
    required this.itemId,
    required this.name,
    this.qty = 0,
    this.revenue = 0,
    this.marginPct = 0,
    this.fill = 0.0,
  });

  factory _$MenuItemRowDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuItemRowDtoImplFromJson(json);

  @override
  final String itemId;
  @override
  final String name;
  @override
  @JsonKey()
  final int qty;
  @override
  @JsonKey()
  final int revenue;
  @override
  @JsonKey()
  final int marginPct;
  @override
  @JsonKey()
  final double fill;

  @override
  String toString() {
    return 'MenuItemRowDto(itemId: $itemId, name: $name, qty: $qty, revenue: $revenue, marginPct: $marginPct, fill: $fill)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuItemRowDtoImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.revenue, revenue) || other.revenue == revenue) &&
            (identical(other.marginPct, marginPct) ||
                other.marginPct == marginPct) &&
            (identical(other.fill, fill) || other.fill == fill));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, itemId, name, qty, revenue, marginPct, fill);

  /// Create a copy of MenuItemRowDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuItemRowDtoImplCopyWith<_$MenuItemRowDtoImpl> get copyWith =>
      __$$MenuItemRowDtoImplCopyWithImpl<_$MenuItemRowDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuItemRowDtoImplToJson(this);
  }
}

abstract class _MenuItemRowDto implements MenuItemRowDto {
  const factory _MenuItemRowDto({
    required final String itemId,
    required final String name,
    final int qty,
    final int revenue,
    final int marginPct,
    final double fill,
  }) = _$MenuItemRowDtoImpl;

  factory _MenuItemRowDto.fromJson(Map<String, dynamic> json) =
      _$MenuItemRowDtoImpl.fromJson;

  @override
  String get itemId;
  @override
  String get name;
  @override
  int get qty;
  @override
  int get revenue;
  @override
  int get marginPct;
  @override
  double get fill;

  /// Create a copy of MenuItemRowDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuItemRowDtoImplCopyWith<_$MenuItemRowDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModifierAttachDto _$ModifierAttachDtoFromJson(Map<String, dynamic> json) {
  return _ModifierAttachDto.fromJson(json);
}

/// @nodoc
mixin _$ModifierAttachDto {
  String get group => throw _privateConstructorUsedError;
  double get rate => throw _privateConstructorUsedError;

  /// Serializes this ModifierAttachDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModifierAttachDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModifierAttachDtoCopyWith<ModifierAttachDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModifierAttachDtoCopyWith<$Res> {
  factory $ModifierAttachDtoCopyWith(
    ModifierAttachDto value,
    $Res Function(ModifierAttachDto) then,
  ) = _$ModifierAttachDtoCopyWithImpl<$Res, ModifierAttachDto>;
  @useResult
  $Res call({String group, double rate});
}

/// @nodoc
class _$ModifierAttachDtoCopyWithImpl<$Res, $Val extends ModifierAttachDto>
    implements $ModifierAttachDtoCopyWith<$Res> {
  _$ModifierAttachDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModifierAttachDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? group = null, Object? rate = null}) {
    return _then(
      _value.copyWith(
            group: null == group
                ? _value.group
                : group // ignore: cast_nullable_to_non_nullable
                      as String,
            rate: null == rate
                ? _value.rate
                : rate // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ModifierAttachDtoImplCopyWith<$Res>
    implements $ModifierAttachDtoCopyWith<$Res> {
  factory _$$ModifierAttachDtoImplCopyWith(
    _$ModifierAttachDtoImpl value,
    $Res Function(_$ModifierAttachDtoImpl) then,
  ) = __$$ModifierAttachDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String group, double rate});
}

/// @nodoc
class __$$ModifierAttachDtoImplCopyWithImpl<$Res>
    extends _$ModifierAttachDtoCopyWithImpl<$Res, _$ModifierAttachDtoImpl>
    implements _$$ModifierAttachDtoImplCopyWith<$Res> {
  __$$ModifierAttachDtoImplCopyWithImpl(
    _$ModifierAttachDtoImpl _value,
    $Res Function(_$ModifierAttachDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ModifierAttachDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? group = null, Object? rate = null}) {
    return _then(
      _$ModifierAttachDtoImpl(
        group: null == group
            ? _value.group
            : group // ignore: cast_nullable_to_non_nullable
                  as String,
        rate: null == rate
            ? _value.rate
            : rate // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ModifierAttachDtoImpl implements _ModifierAttachDto {
  const _$ModifierAttachDtoImpl({required this.group, this.rate = 0.0});

  factory _$ModifierAttachDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModifierAttachDtoImplFromJson(json);

  @override
  final String group;
  @override
  @JsonKey()
  final double rate;

  @override
  String toString() {
    return 'ModifierAttachDto(group: $group, rate: $rate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModifierAttachDtoImpl &&
            (identical(other.group, group) || other.group == group) &&
            (identical(other.rate, rate) || other.rate == rate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, group, rate);

  /// Create a copy of ModifierAttachDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModifierAttachDtoImplCopyWith<_$ModifierAttachDtoImpl> get copyWith =>
      __$$ModifierAttachDtoImplCopyWithImpl<_$ModifierAttachDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ModifierAttachDtoImplToJson(this);
  }
}

abstract class _ModifierAttachDto implements ModifierAttachDto {
  const factory _ModifierAttachDto({
    required final String group,
    final double rate,
  }) = _$ModifierAttachDtoImpl;

  factory _ModifierAttachDto.fromJson(Map<String, dynamic> json) =
      _$ModifierAttachDtoImpl.fromJson;

  @override
  String get group;
  @override
  double get rate;

  /// Create a copy of ModifierAttachDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModifierAttachDtoImplCopyWith<_$ModifierAttachDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CategoryShareDto _$CategoryShareDtoFromJson(Map<String, dynamic> json) {
  return _CategoryShareDto.fromJson(json);
}

/// @nodoc
mixin _$CategoryShareDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get shareThisWeek => throw _privateConstructorUsedError;
  double get shareLastWeek => throw _privateConstructorUsedError;

  /// Serializes this CategoryShareDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CategoryShareDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryShareDtoCopyWith<CategoryShareDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryShareDtoCopyWith<$Res> {
  factory $CategoryShareDtoCopyWith(
    CategoryShareDto value,
    $Res Function(CategoryShareDto) then,
  ) = _$CategoryShareDtoCopyWithImpl<$Res, CategoryShareDto>;
  @useResult
  $Res call({
    String id,
    String name,
    double shareThisWeek,
    double shareLastWeek,
  });
}

/// @nodoc
class _$CategoryShareDtoCopyWithImpl<$Res, $Val extends CategoryShareDto>
    implements $CategoryShareDtoCopyWith<$Res> {
  _$CategoryShareDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CategoryShareDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? shareThisWeek = null,
    Object? shareLastWeek = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            shareThisWeek: null == shareThisWeek
                ? _value.shareThisWeek
                : shareThisWeek // ignore: cast_nullable_to_non_nullable
                      as double,
            shareLastWeek: null == shareLastWeek
                ? _value.shareLastWeek
                : shareLastWeek // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CategoryShareDtoImplCopyWith<$Res>
    implements $CategoryShareDtoCopyWith<$Res> {
  factory _$$CategoryShareDtoImplCopyWith(
    _$CategoryShareDtoImpl value,
    $Res Function(_$CategoryShareDtoImpl) then,
  ) = __$$CategoryShareDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    double shareThisWeek,
    double shareLastWeek,
  });
}

/// @nodoc
class __$$CategoryShareDtoImplCopyWithImpl<$Res>
    extends _$CategoryShareDtoCopyWithImpl<$Res, _$CategoryShareDtoImpl>
    implements _$$CategoryShareDtoImplCopyWith<$Res> {
  __$$CategoryShareDtoImplCopyWithImpl(
    _$CategoryShareDtoImpl _value,
    $Res Function(_$CategoryShareDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CategoryShareDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? shareThisWeek = null,
    Object? shareLastWeek = null,
  }) {
    return _then(
      _$CategoryShareDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        shareThisWeek: null == shareThisWeek
            ? _value.shareThisWeek
            : shareThisWeek // ignore: cast_nullable_to_non_nullable
                  as double,
        shareLastWeek: null == shareLastWeek
            ? _value.shareLastWeek
            : shareLastWeek // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryShareDtoImpl implements _CategoryShareDto {
  const _$CategoryShareDtoImpl({
    required this.id,
    required this.name,
    this.shareThisWeek = 0.0,
    this.shareLastWeek = 0.0,
  });

  factory _$CategoryShareDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryShareDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final double shareThisWeek;
  @override
  @JsonKey()
  final double shareLastWeek;

  @override
  String toString() {
    return 'CategoryShareDto(id: $id, name: $name, shareThisWeek: $shareThisWeek, shareLastWeek: $shareLastWeek)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryShareDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.shareThisWeek, shareThisWeek) ||
                other.shareThisWeek == shareThisWeek) &&
            (identical(other.shareLastWeek, shareLastWeek) ||
                other.shareLastWeek == shareLastWeek));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, shareThisWeek, shareLastWeek);

  /// Create a copy of CategoryShareDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryShareDtoImplCopyWith<_$CategoryShareDtoImpl> get copyWith =>
      __$$CategoryShareDtoImplCopyWithImpl<_$CategoryShareDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryShareDtoImplToJson(this);
  }
}

abstract class _CategoryShareDto implements CategoryShareDto {
  const factory _CategoryShareDto({
    required final String id,
    required final String name,
    final double shareThisWeek,
    final double shareLastWeek,
  }) = _$CategoryShareDtoImpl;

  factory _CategoryShareDto.fromJson(Map<String, dynamic> json) =
      _$CategoryShareDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get shareThisWeek;
  @override
  double get shareLastWeek;

  /// Create a copy of CategoryShareDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryShareDtoImplCopyWith<_$CategoryShareDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MatrixItemDto _$MatrixItemDtoFromJson(Map<String, dynamic> json) {
  return _MatrixItemDto.fromJson(json);
}

/// @nodoc
mixin _$MatrixItemDto {
  String get itemId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get popularity => throw _privateConstructorUsedError;
  double get margin => throw _privateConstructorUsedError;
  String get quadrant => throw _privateConstructorUsedError;

  /// Serializes this MatrixItemDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MatrixItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatrixItemDtoCopyWith<MatrixItemDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatrixItemDtoCopyWith<$Res> {
  factory $MatrixItemDtoCopyWith(
    MatrixItemDto value,
    $Res Function(MatrixItemDto) then,
  ) = _$MatrixItemDtoCopyWithImpl<$Res, MatrixItemDto>;
  @useResult
  $Res call({
    String itemId,
    String name,
    double popularity,
    double margin,
    String quadrant,
  });
}

/// @nodoc
class _$MatrixItemDtoCopyWithImpl<$Res, $Val extends MatrixItemDto>
    implements $MatrixItemDtoCopyWith<$Res> {
  _$MatrixItemDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MatrixItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? name = null,
    Object? popularity = null,
    Object? margin = null,
    Object? quadrant = null,
  }) {
    return _then(
      _value.copyWith(
            itemId: null == itemId
                ? _value.itemId
                : itemId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            popularity: null == popularity
                ? _value.popularity
                : popularity // ignore: cast_nullable_to_non_nullable
                      as double,
            margin: null == margin
                ? _value.margin
                : margin // ignore: cast_nullable_to_non_nullable
                      as double,
            quadrant: null == quadrant
                ? _value.quadrant
                : quadrant // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MatrixItemDtoImplCopyWith<$Res>
    implements $MatrixItemDtoCopyWith<$Res> {
  factory _$$MatrixItemDtoImplCopyWith(
    _$MatrixItemDtoImpl value,
    $Res Function(_$MatrixItemDtoImpl) then,
  ) = __$$MatrixItemDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String itemId,
    String name,
    double popularity,
    double margin,
    String quadrant,
  });
}

/// @nodoc
class __$$MatrixItemDtoImplCopyWithImpl<$Res>
    extends _$MatrixItemDtoCopyWithImpl<$Res, _$MatrixItemDtoImpl>
    implements _$$MatrixItemDtoImplCopyWith<$Res> {
  __$$MatrixItemDtoImplCopyWithImpl(
    _$MatrixItemDtoImpl _value,
    $Res Function(_$MatrixItemDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MatrixItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? name = null,
    Object? popularity = null,
    Object? margin = null,
    Object? quadrant = null,
  }) {
    return _then(
      _$MatrixItemDtoImpl(
        itemId: null == itemId
            ? _value.itemId
            : itemId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        popularity: null == popularity
            ? _value.popularity
            : popularity // ignore: cast_nullable_to_non_nullable
                  as double,
        margin: null == margin
            ? _value.margin
            : margin // ignore: cast_nullable_to_non_nullable
                  as double,
        quadrant: null == quadrant
            ? _value.quadrant
            : quadrant // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MatrixItemDtoImpl implements _MatrixItemDto {
  const _$MatrixItemDtoImpl({
    required this.itemId,
    required this.name,
    this.popularity = 0.0,
    this.margin = 0.0,
    required this.quadrant,
  });

  factory _$MatrixItemDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatrixItemDtoImplFromJson(json);

  @override
  final String itemId;
  @override
  final String name;
  @override
  @JsonKey()
  final double popularity;
  @override
  @JsonKey()
  final double margin;
  @override
  final String quadrant;

  @override
  String toString() {
    return 'MatrixItemDto(itemId: $itemId, name: $name, popularity: $popularity, margin: $margin, quadrant: $quadrant)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatrixItemDtoImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.popularity, popularity) ||
                other.popularity == popularity) &&
            (identical(other.margin, margin) || other.margin == margin) &&
            (identical(other.quadrant, quadrant) ||
                other.quadrant == quadrant));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, itemId, name, popularity, margin, quadrant);

  /// Create a copy of MatrixItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatrixItemDtoImplCopyWith<_$MatrixItemDtoImpl> get copyWith =>
      __$$MatrixItemDtoImplCopyWithImpl<_$MatrixItemDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatrixItemDtoImplToJson(this);
  }
}

abstract class _MatrixItemDto implements MatrixItemDto {
  const factory _MatrixItemDto({
    required final String itemId,
    required final String name,
    final double popularity,
    final double margin,
    required final String quadrant,
  }) = _$MatrixItemDtoImpl;

  factory _MatrixItemDto.fromJson(Map<String, dynamic> json) =
      _$MatrixItemDtoImpl.fromJson;

  @override
  String get itemId;
  @override
  String get name;
  @override
  double get popularity;
  @override
  double get margin;
  @override
  String get quadrant;

  /// Create a copy of MatrixItemDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatrixItemDtoImplCopyWith<_$MatrixItemDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BasketPairDto _$BasketPairDtoFromJson(Map<String, dynamic> json) {
  return _BasketPairDto.fromJson(json);
}

/// @nodoc
mixin _$BasketPairDto {
  String get itemA => throw _privateConstructorUsedError;
  String get itemB => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  double get rate => throw _privateConstructorUsedError;

  /// Serializes this BasketPairDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BasketPairDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BasketPairDtoCopyWith<BasketPairDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BasketPairDtoCopyWith<$Res> {
  factory $BasketPairDtoCopyWith(
    BasketPairDto value,
    $Res Function(BasketPairDto) then,
  ) = _$BasketPairDtoCopyWithImpl<$Res, BasketPairDto>;
  @useResult
  $Res call({String itemA, String itemB, int count, double rate});
}

/// @nodoc
class _$BasketPairDtoCopyWithImpl<$Res, $Val extends BasketPairDto>
    implements $BasketPairDtoCopyWith<$Res> {
  _$BasketPairDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BasketPairDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemA = null,
    Object? itemB = null,
    Object? count = null,
    Object? rate = null,
  }) {
    return _then(
      _value.copyWith(
            itemA: null == itemA
                ? _value.itemA
                : itemA // ignore: cast_nullable_to_non_nullable
                      as String,
            itemB: null == itemB
                ? _value.itemB
                : itemB // ignore: cast_nullable_to_non_nullable
                      as String,
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
            rate: null == rate
                ? _value.rate
                : rate // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BasketPairDtoImplCopyWith<$Res>
    implements $BasketPairDtoCopyWith<$Res> {
  factory _$$BasketPairDtoImplCopyWith(
    _$BasketPairDtoImpl value,
    $Res Function(_$BasketPairDtoImpl) then,
  ) = __$$BasketPairDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String itemA, String itemB, int count, double rate});
}

/// @nodoc
class __$$BasketPairDtoImplCopyWithImpl<$Res>
    extends _$BasketPairDtoCopyWithImpl<$Res, _$BasketPairDtoImpl>
    implements _$$BasketPairDtoImplCopyWith<$Res> {
  __$$BasketPairDtoImplCopyWithImpl(
    _$BasketPairDtoImpl _value,
    $Res Function(_$BasketPairDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BasketPairDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemA = null,
    Object? itemB = null,
    Object? count = null,
    Object? rate = null,
  }) {
    return _then(
      _$BasketPairDtoImpl(
        itemA: null == itemA
            ? _value.itemA
            : itemA // ignore: cast_nullable_to_non_nullable
                  as String,
        itemB: null == itemB
            ? _value.itemB
            : itemB // ignore: cast_nullable_to_non_nullable
                  as String,
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        rate: null == rate
            ? _value.rate
            : rate // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BasketPairDtoImpl implements _BasketPairDto {
  const _$BasketPairDtoImpl({
    required this.itemA,
    required this.itemB,
    this.count = 0,
    this.rate = 0.0,
  });

  factory _$BasketPairDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$BasketPairDtoImplFromJson(json);

  @override
  final String itemA;
  @override
  final String itemB;
  @override
  @JsonKey()
  final int count;
  @override
  @JsonKey()
  final double rate;

  @override
  String toString() {
    return 'BasketPairDto(itemA: $itemA, itemB: $itemB, count: $count, rate: $rate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BasketPairDtoImpl &&
            (identical(other.itemA, itemA) || other.itemA == itemA) &&
            (identical(other.itemB, itemB) || other.itemB == itemB) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.rate, rate) || other.rate == rate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, itemA, itemB, count, rate);

  /// Create a copy of BasketPairDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BasketPairDtoImplCopyWith<_$BasketPairDtoImpl> get copyWith =>
      __$$BasketPairDtoImplCopyWithImpl<_$BasketPairDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BasketPairDtoImplToJson(this);
  }
}

abstract class _BasketPairDto implements BasketPairDto {
  const factory _BasketPairDto({
    required final String itemA,
    required final String itemB,
    final int count,
    final double rate,
  }) = _$BasketPairDtoImpl;

  factory _BasketPairDto.fromJson(Map<String, dynamic> json) =
      _$BasketPairDtoImpl.fromJson;

  @override
  String get itemA;
  @override
  String get itemB;
  @override
  int get count;
  @override
  double get rate;

  /// Create a copy of BasketPairDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BasketPairDtoImplCopyWith<_$BasketPairDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OpsSectionDto _$OpsSectionDtoFromJson(Map<String, dynamic> json) {
  return _OpsSectionDto.fromJson(json);
}

/// @nodoc
mixin _$OpsSectionDto {
  List<KpiTileDto> get kpis => throw _privateConstructorUsedError;
  SpeedSectionDto get speed => throw _privateConstructorUsedError;
  List<StationRowDto> get stations => throw _privateConstructorUsedError;
  List<List<double>> get heatmap => throw _privateConstructorUsedError;
  ReservationStatsDto get reservations => throw _privateConstructorUsedError;
  List<VoidReasonDto> get voidReasons => throw _privateConstructorUsedError;
  List<StaffVoidDto> get voidByStaff => throw _privateConstructorUsedError;

  /// Serializes this OpsSectionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OpsSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OpsSectionDtoCopyWith<OpsSectionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpsSectionDtoCopyWith<$Res> {
  factory $OpsSectionDtoCopyWith(
    OpsSectionDto value,
    $Res Function(OpsSectionDto) then,
  ) = _$OpsSectionDtoCopyWithImpl<$Res, OpsSectionDto>;
  @useResult
  $Res call({
    List<KpiTileDto> kpis,
    SpeedSectionDto speed,
    List<StationRowDto> stations,
    List<List<double>> heatmap,
    ReservationStatsDto reservations,
    List<VoidReasonDto> voidReasons,
    List<StaffVoidDto> voidByStaff,
  });

  $SpeedSectionDtoCopyWith<$Res> get speed;
  $ReservationStatsDtoCopyWith<$Res> get reservations;
}

/// @nodoc
class _$OpsSectionDtoCopyWithImpl<$Res, $Val extends OpsSectionDto>
    implements $OpsSectionDtoCopyWith<$Res> {
  _$OpsSectionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OpsSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kpis = null,
    Object? speed = null,
    Object? stations = null,
    Object? heatmap = null,
    Object? reservations = null,
    Object? voidReasons = null,
    Object? voidByStaff = null,
  }) {
    return _then(
      _value.copyWith(
            kpis: null == kpis
                ? _value.kpis
                : kpis // ignore: cast_nullable_to_non_nullable
                      as List<KpiTileDto>,
            speed: null == speed
                ? _value.speed
                : speed // ignore: cast_nullable_to_non_nullable
                      as SpeedSectionDto,
            stations: null == stations
                ? _value.stations
                : stations // ignore: cast_nullable_to_non_nullable
                      as List<StationRowDto>,
            heatmap: null == heatmap
                ? _value.heatmap
                : heatmap // ignore: cast_nullable_to_non_nullable
                      as List<List<double>>,
            reservations: null == reservations
                ? _value.reservations
                : reservations // ignore: cast_nullable_to_non_nullable
                      as ReservationStatsDto,
            voidReasons: null == voidReasons
                ? _value.voidReasons
                : voidReasons // ignore: cast_nullable_to_non_nullable
                      as List<VoidReasonDto>,
            voidByStaff: null == voidByStaff
                ? _value.voidByStaff
                : voidByStaff // ignore: cast_nullable_to_non_nullable
                      as List<StaffVoidDto>,
          )
          as $Val,
    );
  }

  /// Create a copy of OpsSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SpeedSectionDtoCopyWith<$Res> get speed {
    return $SpeedSectionDtoCopyWith<$Res>(_value.speed, (value) {
      return _then(_value.copyWith(speed: value) as $Val);
    });
  }

  /// Create a copy of OpsSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReservationStatsDtoCopyWith<$Res> get reservations {
    return $ReservationStatsDtoCopyWith<$Res>(_value.reservations, (value) {
      return _then(_value.copyWith(reservations: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OpsSectionDtoImplCopyWith<$Res>
    implements $OpsSectionDtoCopyWith<$Res> {
  factory _$$OpsSectionDtoImplCopyWith(
    _$OpsSectionDtoImpl value,
    $Res Function(_$OpsSectionDtoImpl) then,
  ) = __$$OpsSectionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<KpiTileDto> kpis,
    SpeedSectionDto speed,
    List<StationRowDto> stations,
    List<List<double>> heatmap,
    ReservationStatsDto reservations,
    List<VoidReasonDto> voidReasons,
    List<StaffVoidDto> voidByStaff,
  });

  @override
  $SpeedSectionDtoCopyWith<$Res> get speed;
  @override
  $ReservationStatsDtoCopyWith<$Res> get reservations;
}

/// @nodoc
class __$$OpsSectionDtoImplCopyWithImpl<$Res>
    extends _$OpsSectionDtoCopyWithImpl<$Res, _$OpsSectionDtoImpl>
    implements _$$OpsSectionDtoImplCopyWith<$Res> {
  __$$OpsSectionDtoImplCopyWithImpl(
    _$OpsSectionDtoImpl _value,
    $Res Function(_$OpsSectionDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OpsSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kpis = null,
    Object? speed = null,
    Object? stations = null,
    Object? heatmap = null,
    Object? reservations = null,
    Object? voidReasons = null,
    Object? voidByStaff = null,
  }) {
    return _then(
      _$OpsSectionDtoImpl(
        kpis: null == kpis
            ? _value._kpis
            : kpis // ignore: cast_nullable_to_non_nullable
                  as List<KpiTileDto>,
        speed: null == speed
            ? _value.speed
            : speed // ignore: cast_nullable_to_non_nullable
                  as SpeedSectionDto,
        stations: null == stations
            ? _value._stations
            : stations // ignore: cast_nullable_to_non_nullable
                  as List<StationRowDto>,
        heatmap: null == heatmap
            ? _value._heatmap
            : heatmap // ignore: cast_nullable_to_non_nullable
                  as List<List<double>>,
        reservations: null == reservations
            ? _value.reservations
            : reservations // ignore: cast_nullable_to_non_nullable
                  as ReservationStatsDto,
        voidReasons: null == voidReasons
            ? _value._voidReasons
            : voidReasons // ignore: cast_nullable_to_non_nullable
                  as List<VoidReasonDto>,
        voidByStaff: null == voidByStaff
            ? _value._voidByStaff
            : voidByStaff // ignore: cast_nullable_to_non_nullable
                  as List<StaffVoidDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OpsSectionDtoImpl implements _OpsSectionDto {
  const _$OpsSectionDtoImpl({
    final List<KpiTileDto> kpis = const <KpiTileDto>[],
    this.speed = const SpeedSectionDto(),
    final List<StationRowDto> stations = const <StationRowDto>[],
    final List<List<double>> heatmap = const <List<double>>[],
    required this.reservations,
    final List<VoidReasonDto> voidReasons = const <VoidReasonDto>[],
    final List<StaffVoidDto> voidByStaff = const <StaffVoidDto>[],
  }) : _kpis = kpis,
       _stations = stations,
       _heatmap = heatmap,
       _voidReasons = voidReasons,
       _voidByStaff = voidByStaff;

  factory _$OpsSectionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$OpsSectionDtoImplFromJson(json);

  final List<KpiTileDto> _kpis;
  @override
  @JsonKey()
  List<KpiTileDto> get kpis {
    if (_kpis is EqualUnmodifiableListView) return _kpis;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_kpis);
  }

  @override
  @JsonKey()
  final SpeedSectionDto speed;
  final List<StationRowDto> _stations;
  @override
  @JsonKey()
  List<StationRowDto> get stations {
    if (_stations is EqualUnmodifiableListView) return _stations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stations);
  }

  final List<List<double>> _heatmap;
  @override
  @JsonKey()
  List<List<double>> get heatmap {
    if (_heatmap is EqualUnmodifiableListView) return _heatmap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_heatmap);
  }

  @override
  final ReservationStatsDto reservations;
  final List<VoidReasonDto> _voidReasons;
  @override
  @JsonKey()
  List<VoidReasonDto> get voidReasons {
    if (_voidReasons is EqualUnmodifiableListView) return _voidReasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_voidReasons);
  }

  final List<StaffVoidDto> _voidByStaff;
  @override
  @JsonKey()
  List<StaffVoidDto> get voidByStaff {
    if (_voidByStaff is EqualUnmodifiableListView) return _voidByStaff;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_voidByStaff);
  }

  @override
  String toString() {
    return 'OpsSectionDto(kpis: $kpis, speed: $speed, stations: $stations, heatmap: $heatmap, reservations: $reservations, voidReasons: $voidReasons, voidByStaff: $voidByStaff)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpsSectionDtoImpl &&
            const DeepCollectionEquality().equals(other._kpis, _kpis) &&
            (identical(other.speed, speed) || other.speed == speed) &&
            const DeepCollectionEquality().equals(other._stations, _stations) &&
            const DeepCollectionEquality().equals(other._heatmap, _heatmap) &&
            (identical(other.reservations, reservations) ||
                other.reservations == reservations) &&
            const DeepCollectionEquality().equals(
              other._voidReasons,
              _voidReasons,
            ) &&
            const DeepCollectionEquality().equals(
              other._voidByStaff,
              _voidByStaff,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_kpis),
    speed,
    const DeepCollectionEquality().hash(_stations),
    const DeepCollectionEquality().hash(_heatmap),
    reservations,
    const DeepCollectionEquality().hash(_voidReasons),
    const DeepCollectionEquality().hash(_voidByStaff),
  );

  /// Create a copy of OpsSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OpsSectionDtoImplCopyWith<_$OpsSectionDtoImpl> get copyWith =>
      __$$OpsSectionDtoImplCopyWithImpl<_$OpsSectionDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OpsSectionDtoImplToJson(this);
  }
}

abstract class _OpsSectionDto implements OpsSectionDto {
  const factory _OpsSectionDto({
    final List<KpiTileDto> kpis,
    final SpeedSectionDto speed,
    final List<StationRowDto> stations,
    final List<List<double>> heatmap,
    required final ReservationStatsDto reservations,
    final List<VoidReasonDto> voidReasons,
    final List<StaffVoidDto> voidByStaff,
  }) = _$OpsSectionDtoImpl;

  factory _OpsSectionDto.fromJson(Map<String, dynamic> json) =
      _$OpsSectionDtoImpl.fromJson;

  @override
  List<KpiTileDto> get kpis;
  @override
  SpeedSectionDto get speed;
  @override
  List<StationRowDto> get stations;
  @override
  List<List<double>> get heatmap;
  @override
  ReservationStatsDto get reservations;
  @override
  List<VoidReasonDto> get voidReasons;
  @override
  List<StaffVoidDto> get voidByStaff;

  /// Create a copy of OpsSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OpsSectionDtoImplCopyWith<_$OpsSectionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpeedSectionDto _$SpeedSectionDtoFromJson(Map<String, dynamic> json) {
  return _SpeedSectionDto.fromJson(json);
}

/// @nodoc
mixin _$SpeedSectionDto {
  int get prepMedianMin => throw _privateConstructorUsedError;
  int get pickupMedianMin => throw _privateConstructorUsedError;
  double get slaPct => throw _privateConstructorUsedError;

  /// The venue *default* target — no longer the only target in play.
  int get prepTargetMins => throw _privateConstructorUsedError;
  int get sampleSize => throw _privateConstructorUsedError;
  List<SpeedItemDto> get slowItems =>
      throw _privateConstructorUsedError; // ADR-0044 additions.
  int get pickupTargetMins => throw _privateConstructorUsedError;
  double get pickupSlaPct => throw _privateConstructorUsedError;
  int get courseSampleSize => throw _privateConstructorUsedError;
  int get greetMedianMin => throw _privateConstructorUsedError;
  double get greetBreachPct => throw _privateConstructorUsedError;
  int get ungreetedMins => throw _privateConstructorUsedError;
  int get greetSampleSize => throw _privateConstructorUsedError;

  /// Serializes this SpeedSectionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpeedSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpeedSectionDtoCopyWith<SpeedSectionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpeedSectionDtoCopyWith<$Res> {
  factory $SpeedSectionDtoCopyWith(
    SpeedSectionDto value,
    $Res Function(SpeedSectionDto) then,
  ) = _$SpeedSectionDtoCopyWithImpl<$Res, SpeedSectionDto>;
  @useResult
  $Res call({
    int prepMedianMin,
    int pickupMedianMin,
    double slaPct,
    int prepTargetMins,
    int sampleSize,
    List<SpeedItemDto> slowItems,
    int pickupTargetMins,
    double pickupSlaPct,
    int courseSampleSize,
    int greetMedianMin,
    double greetBreachPct,
    int ungreetedMins,
    int greetSampleSize,
  });
}

/// @nodoc
class _$SpeedSectionDtoCopyWithImpl<$Res, $Val extends SpeedSectionDto>
    implements $SpeedSectionDtoCopyWith<$Res> {
  _$SpeedSectionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpeedSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prepMedianMin = null,
    Object? pickupMedianMin = null,
    Object? slaPct = null,
    Object? prepTargetMins = null,
    Object? sampleSize = null,
    Object? slowItems = null,
    Object? pickupTargetMins = null,
    Object? pickupSlaPct = null,
    Object? courseSampleSize = null,
    Object? greetMedianMin = null,
    Object? greetBreachPct = null,
    Object? ungreetedMins = null,
    Object? greetSampleSize = null,
  }) {
    return _then(
      _value.copyWith(
            prepMedianMin: null == prepMedianMin
                ? _value.prepMedianMin
                : prepMedianMin // ignore: cast_nullable_to_non_nullable
                      as int,
            pickupMedianMin: null == pickupMedianMin
                ? _value.pickupMedianMin
                : pickupMedianMin // ignore: cast_nullable_to_non_nullable
                      as int,
            slaPct: null == slaPct
                ? _value.slaPct
                : slaPct // ignore: cast_nullable_to_non_nullable
                      as double,
            prepTargetMins: null == prepTargetMins
                ? _value.prepTargetMins
                : prepTargetMins // ignore: cast_nullable_to_non_nullable
                      as int,
            sampleSize: null == sampleSize
                ? _value.sampleSize
                : sampleSize // ignore: cast_nullable_to_non_nullable
                      as int,
            slowItems: null == slowItems
                ? _value.slowItems
                : slowItems // ignore: cast_nullable_to_non_nullable
                      as List<SpeedItemDto>,
            pickupTargetMins: null == pickupTargetMins
                ? _value.pickupTargetMins
                : pickupTargetMins // ignore: cast_nullable_to_non_nullable
                      as int,
            pickupSlaPct: null == pickupSlaPct
                ? _value.pickupSlaPct
                : pickupSlaPct // ignore: cast_nullable_to_non_nullable
                      as double,
            courseSampleSize: null == courseSampleSize
                ? _value.courseSampleSize
                : courseSampleSize // ignore: cast_nullable_to_non_nullable
                      as int,
            greetMedianMin: null == greetMedianMin
                ? _value.greetMedianMin
                : greetMedianMin // ignore: cast_nullable_to_non_nullable
                      as int,
            greetBreachPct: null == greetBreachPct
                ? _value.greetBreachPct
                : greetBreachPct // ignore: cast_nullable_to_non_nullable
                      as double,
            ungreetedMins: null == ungreetedMins
                ? _value.ungreetedMins
                : ungreetedMins // ignore: cast_nullable_to_non_nullable
                      as int,
            greetSampleSize: null == greetSampleSize
                ? _value.greetSampleSize
                : greetSampleSize // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpeedSectionDtoImplCopyWith<$Res>
    implements $SpeedSectionDtoCopyWith<$Res> {
  factory _$$SpeedSectionDtoImplCopyWith(
    _$SpeedSectionDtoImpl value,
    $Res Function(_$SpeedSectionDtoImpl) then,
  ) = __$$SpeedSectionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int prepMedianMin,
    int pickupMedianMin,
    double slaPct,
    int prepTargetMins,
    int sampleSize,
    List<SpeedItemDto> slowItems,
    int pickupTargetMins,
    double pickupSlaPct,
    int courseSampleSize,
    int greetMedianMin,
    double greetBreachPct,
    int ungreetedMins,
    int greetSampleSize,
  });
}

/// @nodoc
class __$$SpeedSectionDtoImplCopyWithImpl<$Res>
    extends _$SpeedSectionDtoCopyWithImpl<$Res, _$SpeedSectionDtoImpl>
    implements _$$SpeedSectionDtoImplCopyWith<$Res> {
  __$$SpeedSectionDtoImplCopyWithImpl(
    _$SpeedSectionDtoImpl _value,
    $Res Function(_$SpeedSectionDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpeedSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prepMedianMin = null,
    Object? pickupMedianMin = null,
    Object? slaPct = null,
    Object? prepTargetMins = null,
    Object? sampleSize = null,
    Object? slowItems = null,
    Object? pickupTargetMins = null,
    Object? pickupSlaPct = null,
    Object? courseSampleSize = null,
    Object? greetMedianMin = null,
    Object? greetBreachPct = null,
    Object? ungreetedMins = null,
    Object? greetSampleSize = null,
  }) {
    return _then(
      _$SpeedSectionDtoImpl(
        prepMedianMin: null == prepMedianMin
            ? _value.prepMedianMin
            : prepMedianMin // ignore: cast_nullable_to_non_nullable
                  as int,
        pickupMedianMin: null == pickupMedianMin
            ? _value.pickupMedianMin
            : pickupMedianMin // ignore: cast_nullable_to_non_nullable
                  as int,
        slaPct: null == slaPct
            ? _value.slaPct
            : slaPct // ignore: cast_nullable_to_non_nullable
                  as double,
        prepTargetMins: null == prepTargetMins
            ? _value.prepTargetMins
            : prepTargetMins // ignore: cast_nullable_to_non_nullable
                  as int,
        sampleSize: null == sampleSize
            ? _value.sampleSize
            : sampleSize // ignore: cast_nullable_to_non_nullable
                  as int,
        slowItems: null == slowItems
            ? _value._slowItems
            : slowItems // ignore: cast_nullable_to_non_nullable
                  as List<SpeedItemDto>,
        pickupTargetMins: null == pickupTargetMins
            ? _value.pickupTargetMins
            : pickupTargetMins // ignore: cast_nullable_to_non_nullable
                  as int,
        pickupSlaPct: null == pickupSlaPct
            ? _value.pickupSlaPct
            : pickupSlaPct // ignore: cast_nullable_to_non_nullable
                  as double,
        courseSampleSize: null == courseSampleSize
            ? _value.courseSampleSize
            : courseSampleSize // ignore: cast_nullable_to_non_nullable
                  as int,
        greetMedianMin: null == greetMedianMin
            ? _value.greetMedianMin
            : greetMedianMin // ignore: cast_nullable_to_non_nullable
                  as int,
        greetBreachPct: null == greetBreachPct
            ? _value.greetBreachPct
            : greetBreachPct // ignore: cast_nullable_to_non_nullable
                  as double,
        ungreetedMins: null == ungreetedMins
            ? _value.ungreetedMins
            : ungreetedMins // ignore: cast_nullable_to_non_nullable
                  as int,
        greetSampleSize: null == greetSampleSize
            ? _value.greetSampleSize
            : greetSampleSize // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpeedSectionDtoImpl implements _SpeedSectionDto {
  const _$SpeedSectionDtoImpl({
    this.prepMedianMin = 0,
    this.pickupMedianMin = 0,
    this.slaPct = 0.0,
    this.prepTargetMins = 15,
    this.sampleSize = 0,
    final List<SpeedItemDto> slowItems = const <SpeedItemDto>[],
    this.pickupTargetMins = 4,
    this.pickupSlaPct = 0.0,
    this.courseSampleSize = 0,
    this.greetMedianMin = 0,
    this.greetBreachPct = 0.0,
    this.ungreetedMins = 7,
    this.greetSampleSize = 0,
  }) : _slowItems = slowItems;

  factory _$SpeedSectionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpeedSectionDtoImplFromJson(json);

  @override
  @JsonKey()
  final int prepMedianMin;
  @override
  @JsonKey()
  final int pickupMedianMin;
  @override
  @JsonKey()
  final double slaPct;

  /// The venue *default* target — no longer the only target in play.
  @override
  @JsonKey()
  final int prepTargetMins;
  @override
  @JsonKey()
  final int sampleSize;
  final List<SpeedItemDto> _slowItems;
  @override
  @JsonKey()
  List<SpeedItemDto> get slowItems {
    if (_slowItems is EqualUnmodifiableListView) return _slowItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_slowItems);
  }

  // ADR-0044 additions.
  @override
  @JsonKey()
  final int pickupTargetMins;
  @override
  @JsonKey()
  final double pickupSlaPct;
  @override
  @JsonKey()
  final int courseSampleSize;
  @override
  @JsonKey()
  final int greetMedianMin;
  @override
  @JsonKey()
  final double greetBreachPct;
  @override
  @JsonKey()
  final int ungreetedMins;
  @override
  @JsonKey()
  final int greetSampleSize;

  @override
  String toString() {
    return 'SpeedSectionDto(prepMedianMin: $prepMedianMin, pickupMedianMin: $pickupMedianMin, slaPct: $slaPct, prepTargetMins: $prepTargetMins, sampleSize: $sampleSize, slowItems: $slowItems, pickupTargetMins: $pickupTargetMins, pickupSlaPct: $pickupSlaPct, courseSampleSize: $courseSampleSize, greetMedianMin: $greetMedianMin, greetBreachPct: $greetBreachPct, ungreetedMins: $ungreetedMins, greetSampleSize: $greetSampleSize)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpeedSectionDtoImpl &&
            (identical(other.prepMedianMin, prepMedianMin) ||
                other.prepMedianMin == prepMedianMin) &&
            (identical(other.pickupMedianMin, pickupMedianMin) ||
                other.pickupMedianMin == pickupMedianMin) &&
            (identical(other.slaPct, slaPct) || other.slaPct == slaPct) &&
            (identical(other.prepTargetMins, prepTargetMins) ||
                other.prepTargetMins == prepTargetMins) &&
            (identical(other.sampleSize, sampleSize) ||
                other.sampleSize == sampleSize) &&
            const DeepCollectionEquality().equals(
              other._slowItems,
              _slowItems,
            ) &&
            (identical(other.pickupTargetMins, pickupTargetMins) ||
                other.pickupTargetMins == pickupTargetMins) &&
            (identical(other.pickupSlaPct, pickupSlaPct) ||
                other.pickupSlaPct == pickupSlaPct) &&
            (identical(other.courseSampleSize, courseSampleSize) ||
                other.courseSampleSize == courseSampleSize) &&
            (identical(other.greetMedianMin, greetMedianMin) ||
                other.greetMedianMin == greetMedianMin) &&
            (identical(other.greetBreachPct, greetBreachPct) ||
                other.greetBreachPct == greetBreachPct) &&
            (identical(other.ungreetedMins, ungreetedMins) ||
                other.ungreetedMins == ungreetedMins) &&
            (identical(other.greetSampleSize, greetSampleSize) ||
                other.greetSampleSize == greetSampleSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    prepMedianMin,
    pickupMedianMin,
    slaPct,
    prepTargetMins,
    sampleSize,
    const DeepCollectionEquality().hash(_slowItems),
    pickupTargetMins,
    pickupSlaPct,
    courseSampleSize,
    greetMedianMin,
    greetBreachPct,
    ungreetedMins,
    greetSampleSize,
  );

  /// Create a copy of SpeedSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpeedSectionDtoImplCopyWith<_$SpeedSectionDtoImpl> get copyWith =>
      __$$SpeedSectionDtoImplCopyWithImpl<_$SpeedSectionDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SpeedSectionDtoImplToJson(this);
  }
}

abstract class _SpeedSectionDto implements SpeedSectionDto {
  const factory _SpeedSectionDto({
    final int prepMedianMin,
    final int pickupMedianMin,
    final double slaPct,
    final int prepTargetMins,
    final int sampleSize,
    final List<SpeedItemDto> slowItems,
    final int pickupTargetMins,
    final double pickupSlaPct,
    final int courseSampleSize,
    final int greetMedianMin,
    final double greetBreachPct,
    final int ungreetedMins,
    final int greetSampleSize,
  }) = _$SpeedSectionDtoImpl;

  factory _SpeedSectionDto.fromJson(Map<String, dynamic> json) =
      _$SpeedSectionDtoImpl.fromJson;

  @override
  int get prepMedianMin;
  @override
  int get pickupMedianMin;
  @override
  double get slaPct;

  /// The venue *default* target — no longer the only target in play.
  @override
  int get prepTargetMins;
  @override
  int get sampleSize;
  @override
  List<SpeedItemDto> get slowItems; // ADR-0044 additions.
  @override
  int get pickupTargetMins;
  @override
  double get pickupSlaPct;
  @override
  int get courseSampleSize;
  @override
  int get greetMedianMin;
  @override
  double get greetBreachPct;
  @override
  int get ungreetedMins;
  @override
  int get greetSampleSize;

  /// Create a copy of SpeedSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpeedSectionDtoImplCopyWith<_$SpeedSectionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpeedItemDto _$SpeedItemDtoFromJson(Map<String, dynamic> json) {
  return _SpeedItemDto.fromJson(json);
}

/// @nodoc
mixin _$SpeedItemDto {
  String get itemId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get avgPrepMin => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;

  /// Serializes this SpeedItemDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpeedItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpeedItemDtoCopyWith<SpeedItemDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpeedItemDtoCopyWith<$Res> {
  factory $SpeedItemDtoCopyWith(
    SpeedItemDto value,
    $Res Function(SpeedItemDto) then,
  ) = _$SpeedItemDtoCopyWithImpl<$Res, SpeedItemDto>;
  @useResult
  $Res call({String itemId, String name, double avgPrepMin, int count});
}

/// @nodoc
class _$SpeedItemDtoCopyWithImpl<$Res, $Val extends SpeedItemDto>
    implements $SpeedItemDtoCopyWith<$Res> {
  _$SpeedItemDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpeedItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? name = null,
    Object? avgPrepMin = null,
    Object? count = null,
  }) {
    return _then(
      _value.copyWith(
            itemId: null == itemId
                ? _value.itemId
                : itemId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            avgPrepMin: null == avgPrepMin
                ? _value.avgPrepMin
                : avgPrepMin // ignore: cast_nullable_to_non_nullable
                      as double,
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpeedItemDtoImplCopyWith<$Res>
    implements $SpeedItemDtoCopyWith<$Res> {
  factory _$$SpeedItemDtoImplCopyWith(
    _$SpeedItemDtoImpl value,
    $Res Function(_$SpeedItemDtoImpl) then,
  ) = __$$SpeedItemDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String itemId, String name, double avgPrepMin, int count});
}

/// @nodoc
class __$$SpeedItemDtoImplCopyWithImpl<$Res>
    extends _$SpeedItemDtoCopyWithImpl<$Res, _$SpeedItemDtoImpl>
    implements _$$SpeedItemDtoImplCopyWith<$Res> {
  __$$SpeedItemDtoImplCopyWithImpl(
    _$SpeedItemDtoImpl _value,
    $Res Function(_$SpeedItemDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpeedItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? name = null,
    Object? avgPrepMin = null,
    Object? count = null,
  }) {
    return _then(
      _$SpeedItemDtoImpl(
        itemId: null == itemId
            ? _value.itemId
            : itemId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        avgPrepMin: null == avgPrepMin
            ? _value.avgPrepMin
            : avgPrepMin // ignore: cast_nullable_to_non_nullable
                  as double,
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpeedItemDtoImpl implements _SpeedItemDto {
  const _$SpeedItemDtoImpl({
    this.itemId = '',
    this.name = '',
    this.avgPrepMin = 0.0,
    this.count = 0,
  });

  factory _$SpeedItemDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpeedItemDtoImplFromJson(json);

  @override
  @JsonKey()
  final String itemId;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final double avgPrepMin;
  @override
  @JsonKey()
  final int count;

  @override
  String toString() {
    return 'SpeedItemDto(itemId: $itemId, name: $name, avgPrepMin: $avgPrepMin, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpeedItemDtoImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avgPrepMin, avgPrepMin) ||
                other.avgPrepMin == avgPrepMin) &&
            (identical(other.count, count) || other.count == count));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, itemId, name, avgPrepMin, count);

  /// Create a copy of SpeedItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpeedItemDtoImplCopyWith<_$SpeedItemDtoImpl> get copyWith =>
      __$$SpeedItemDtoImplCopyWithImpl<_$SpeedItemDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpeedItemDtoImplToJson(this);
  }
}

abstract class _SpeedItemDto implements SpeedItemDto {
  const factory _SpeedItemDto({
    final String itemId,
    final String name,
    final double avgPrepMin,
    final int count,
  }) = _$SpeedItemDtoImpl;

  factory _SpeedItemDto.fromJson(Map<String, dynamic> json) =
      _$SpeedItemDtoImpl.fromJson;

  @override
  String get itemId;
  @override
  String get name;
  @override
  double get avgPrepMin;
  @override
  int get count;

  /// Create a copy of SpeedItemDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpeedItemDtoImplCopyWith<_$SpeedItemDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StationRowDto _$StationRowDtoFromJson(Map<String, dynamic> json) {
  return _StationRowDto.fromJson(json);
}

/// @nodoc
mixin _$StationRowDto {
  // The station code only — its words come from `stationLabel` at read time
  // (ADR-0085). The server stopped sending a `label` and this stayed
  // required, which failed the whole snapshot's parse.
  String get station => throw _privateConstructorUsedError;
  int get qty => throw _privateConstructorUsedError;
  double get utilization => throw _privateConstructorUsedError;

  /// Serializes this StationRowDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StationRowDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StationRowDtoCopyWith<StationRowDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StationRowDtoCopyWith<$Res> {
  factory $StationRowDtoCopyWith(
    StationRowDto value,
    $Res Function(StationRowDto) then,
  ) = _$StationRowDtoCopyWithImpl<$Res, StationRowDto>;
  @useResult
  $Res call({String station, int qty, double utilization});
}

/// @nodoc
class _$StationRowDtoCopyWithImpl<$Res, $Val extends StationRowDto>
    implements $StationRowDtoCopyWith<$Res> {
  _$StationRowDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StationRowDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? station = null,
    Object? qty = null,
    Object? utilization = null,
  }) {
    return _then(
      _value.copyWith(
            station: null == station
                ? _value.station
                : station // ignore: cast_nullable_to_non_nullable
                      as String,
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
            utilization: null == utilization
                ? _value.utilization
                : utilization // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StationRowDtoImplCopyWith<$Res>
    implements $StationRowDtoCopyWith<$Res> {
  factory _$$StationRowDtoImplCopyWith(
    _$StationRowDtoImpl value,
    $Res Function(_$StationRowDtoImpl) then,
  ) = __$$StationRowDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String station, int qty, double utilization});
}

/// @nodoc
class __$$StationRowDtoImplCopyWithImpl<$Res>
    extends _$StationRowDtoCopyWithImpl<$Res, _$StationRowDtoImpl>
    implements _$$StationRowDtoImplCopyWith<$Res> {
  __$$StationRowDtoImplCopyWithImpl(
    _$StationRowDtoImpl _value,
    $Res Function(_$StationRowDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StationRowDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? station = null,
    Object? qty = null,
    Object? utilization = null,
  }) {
    return _then(
      _$StationRowDtoImpl(
        station: null == station
            ? _value.station
            : station // ignore: cast_nullable_to_non_nullable
                  as String,
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
        utilization: null == utilization
            ? _value.utilization
            : utilization // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StationRowDtoImpl implements _StationRowDto {
  const _$StationRowDtoImpl({
    required this.station,
    this.qty = 0,
    this.utilization = 0.0,
  });

  factory _$StationRowDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StationRowDtoImplFromJson(json);

  // The station code only — its words come from `stationLabel` at read time
  // (ADR-0085). The server stopped sending a `label` and this stayed
  // required, which failed the whole snapshot's parse.
  @override
  final String station;
  @override
  @JsonKey()
  final int qty;
  @override
  @JsonKey()
  final double utilization;

  @override
  String toString() {
    return 'StationRowDto(station: $station, qty: $qty, utilization: $utilization)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StationRowDtoImpl &&
            (identical(other.station, station) || other.station == station) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.utilization, utilization) ||
                other.utilization == utilization));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, station, qty, utilization);

  /// Create a copy of StationRowDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StationRowDtoImplCopyWith<_$StationRowDtoImpl> get copyWith =>
      __$$StationRowDtoImplCopyWithImpl<_$StationRowDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StationRowDtoImplToJson(this);
  }
}

abstract class _StationRowDto implements StationRowDto {
  const factory _StationRowDto({
    required final String station,
    final int qty,
    final double utilization,
  }) = _$StationRowDtoImpl;

  factory _StationRowDto.fromJson(Map<String, dynamic> json) =
      _$StationRowDtoImpl.fromJson;

  // The station code only — its words come from `stationLabel` at read time
  // (ADR-0085). The server stopped sending a `label` and this stayed
  // required, which failed the whole snapshot's parse.
  @override
  String get station;
  @override
  int get qty;
  @override
  double get utilization;

  /// Create a copy of StationRowDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StationRowDtoImplCopyWith<_$StationRowDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReservationStatsDto _$ReservationStatsDtoFromJson(Map<String, dynamic> json) {
  return _ReservationStatsDto.fromJson(json);
}

/// @nodoc
mixin _$ReservationStatsDto {
  int get booked => throw _privateConstructorUsedError;
  int get seated => throw _privateConstructorUsedError;
  int get noShow => throw _privateConstructorUsedError;
  int get cancelled => throw _privateConstructorUsedError;

  /// Serializes this ReservationStatsDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReservationStatsDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReservationStatsDtoCopyWith<ReservationStatsDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReservationStatsDtoCopyWith<$Res> {
  factory $ReservationStatsDtoCopyWith(
    ReservationStatsDto value,
    $Res Function(ReservationStatsDto) then,
  ) = _$ReservationStatsDtoCopyWithImpl<$Res, ReservationStatsDto>;
  @useResult
  $Res call({int booked, int seated, int noShow, int cancelled});
}

/// @nodoc
class _$ReservationStatsDtoCopyWithImpl<$Res, $Val extends ReservationStatsDto>
    implements $ReservationStatsDtoCopyWith<$Res> {
  _$ReservationStatsDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReservationStatsDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? booked = null,
    Object? seated = null,
    Object? noShow = null,
    Object? cancelled = null,
  }) {
    return _then(
      _value.copyWith(
            booked: null == booked
                ? _value.booked
                : booked // ignore: cast_nullable_to_non_nullable
                      as int,
            seated: null == seated
                ? _value.seated
                : seated // ignore: cast_nullable_to_non_nullable
                      as int,
            noShow: null == noShow
                ? _value.noShow
                : noShow // ignore: cast_nullable_to_non_nullable
                      as int,
            cancelled: null == cancelled
                ? _value.cancelled
                : cancelled // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReservationStatsDtoImplCopyWith<$Res>
    implements $ReservationStatsDtoCopyWith<$Res> {
  factory _$$ReservationStatsDtoImplCopyWith(
    _$ReservationStatsDtoImpl value,
    $Res Function(_$ReservationStatsDtoImpl) then,
  ) = __$$ReservationStatsDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int booked, int seated, int noShow, int cancelled});
}

/// @nodoc
class __$$ReservationStatsDtoImplCopyWithImpl<$Res>
    extends _$ReservationStatsDtoCopyWithImpl<$Res, _$ReservationStatsDtoImpl>
    implements _$$ReservationStatsDtoImplCopyWith<$Res> {
  __$$ReservationStatsDtoImplCopyWithImpl(
    _$ReservationStatsDtoImpl _value,
    $Res Function(_$ReservationStatsDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReservationStatsDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? booked = null,
    Object? seated = null,
    Object? noShow = null,
    Object? cancelled = null,
  }) {
    return _then(
      _$ReservationStatsDtoImpl(
        booked: null == booked
            ? _value.booked
            : booked // ignore: cast_nullable_to_non_nullable
                  as int,
        seated: null == seated
            ? _value.seated
            : seated // ignore: cast_nullable_to_non_nullable
                  as int,
        noShow: null == noShow
            ? _value.noShow
            : noShow // ignore: cast_nullable_to_non_nullable
                  as int,
        cancelled: null == cancelled
            ? _value.cancelled
            : cancelled // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReservationStatsDtoImpl implements _ReservationStatsDto {
  const _$ReservationStatsDtoImpl({
    this.booked = 0,
    this.seated = 0,
    this.noShow = 0,
    this.cancelled = 0,
  });

  factory _$ReservationStatsDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReservationStatsDtoImplFromJson(json);

  @override
  @JsonKey()
  final int booked;
  @override
  @JsonKey()
  final int seated;
  @override
  @JsonKey()
  final int noShow;
  @override
  @JsonKey()
  final int cancelled;

  @override
  String toString() {
    return 'ReservationStatsDto(booked: $booked, seated: $seated, noShow: $noShow, cancelled: $cancelled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReservationStatsDtoImpl &&
            (identical(other.booked, booked) || other.booked == booked) &&
            (identical(other.seated, seated) || other.seated == seated) &&
            (identical(other.noShow, noShow) || other.noShow == noShow) &&
            (identical(other.cancelled, cancelled) ||
                other.cancelled == cancelled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, booked, seated, noShow, cancelled);

  /// Create a copy of ReservationStatsDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReservationStatsDtoImplCopyWith<_$ReservationStatsDtoImpl> get copyWith =>
      __$$ReservationStatsDtoImplCopyWithImpl<_$ReservationStatsDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReservationStatsDtoImplToJson(this);
  }
}

abstract class _ReservationStatsDto implements ReservationStatsDto {
  const factory _ReservationStatsDto({
    final int booked,
    final int seated,
    final int noShow,
    final int cancelled,
  }) = _$ReservationStatsDtoImpl;

  factory _ReservationStatsDto.fromJson(Map<String, dynamic> json) =
      _$ReservationStatsDtoImpl.fromJson;

  @override
  int get booked;
  @override
  int get seated;
  @override
  int get noShow;
  @override
  int get cancelled;

  /// Create a copy of ReservationStatsDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReservationStatsDtoImplCopyWith<_$ReservationStatsDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VoidReasonDto _$VoidReasonDtoFromJson(Map<String, dynamic> json) {
  return _VoidReasonDto.fromJson(json);
}

/// @nodoc
mixin _$VoidReasonDto {
  String get code => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  int get lostRupiah => throw _privateConstructorUsedError;

  /// Serializes this VoidReasonDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VoidReasonDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VoidReasonDtoCopyWith<VoidReasonDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoidReasonDtoCopyWith<$Res> {
  factory $VoidReasonDtoCopyWith(
    VoidReasonDto value,
    $Res Function(VoidReasonDto) then,
  ) = _$VoidReasonDtoCopyWithImpl<$Res, VoidReasonDto>;
  @useResult
  $Res call({String code, String label, int count, int lostRupiah});
}

/// @nodoc
class _$VoidReasonDtoCopyWithImpl<$Res, $Val extends VoidReasonDto>
    implements $VoidReasonDtoCopyWith<$Res> {
  _$VoidReasonDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VoidReasonDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? label = null,
    Object? count = null,
    Object? lostRupiah = null,
  }) {
    return _then(
      _value.copyWith(
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
            lostRupiah: null == lostRupiah
                ? _value.lostRupiah
                : lostRupiah // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VoidReasonDtoImplCopyWith<$Res>
    implements $VoidReasonDtoCopyWith<$Res> {
  factory _$$VoidReasonDtoImplCopyWith(
    _$VoidReasonDtoImpl value,
    $Res Function(_$VoidReasonDtoImpl) then,
  ) = __$$VoidReasonDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String code, String label, int count, int lostRupiah});
}

/// @nodoc
class __$$VoidReasonDtoImplCopyWithImpl<$Res>
    extends _$VoidReasonDtoCopyWithImpl<$Res, _$VoidReasonDtoImpl>
    implements _$$VoidReasonDtoImplCopyWith<$Res> {
  __$$VoidReasonDtoImplCopyWithImpl(
    _$VoidReasonDtoImpl _value,
    $Res Function(_$VoidReasonDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VoidReasonDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? label = null,
    Object? count = null,
    Object? lostRupiah = null,
  }) {
    return _then(
      _$VoidReasonDtoImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        lostRupiah: null == lostRupiah
            ? _value.lostRupiah
            : lostRupiah // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VoidReasonDtoImpl implements _VoidReasonDto {
  const _$VoidReasonDtoImpl({
    required this.code,
    this.label = '',
    this.count = 0,
    this.lostRupiah = 0,
  });

  factory _$VoidReasonDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoidReasonDtoImplFromJson(json);

  @override
  final String code;
  @override
  @JsonKey()
  final String label;
  @override
  @JsonKey()
  final int count;
  @override
  @JsonKey()
  final int lostRupiah;

  @override
  String toString() {
    return 'VoidReasonDto(code: $code, label: $label, count: $count, lostRupiah: $lostRupiah)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoidReasonDtoImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.lostRupiah, lostRupiah) ||
                other.lostRupiah == lostRupiah));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, label, count, lostRupiah);

  /// Create a copy of VoidReasonDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoidReasonDtoImplCopyWith<_$VoidReasonDtoImpl> get copyWith =>
      __$$VoidReasonDtoImplCopyWithImpl<_$VoidReasonDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VoidReasonDtoImplToJson(this);
  }
}

abstract class _VoidReasonDto implements VoidReasonDto {
  const factory _VoidReasonDto({
    required final String code,
    final String label,
    final int count,
    final int lostRupiah,
  }) = _$VoidReasonDtoImpl;

  factory _VoidReasonDto.fromJson(Map<String, dynamic> json) =
      _$VoidReasonDtoImpl.fromJson;

  @override
  String get code;
  @override
  String get label;
  @override
  int get count;
  @override
  int get lostRupiah;

  /// Create a copy of VoidReasonDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoidReasonDtoImplCopyWith<_$VoidReasonDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PaymentsSectionDto _$PaymentsSectionDtoFromJson(Map<String, dynamic> json) {
  return _PaymentsSectionDto.fromJson(json);
}

/// @nodoc
mixin _$PaymentsSectionDto {
  int get nonCashTotal => throw _privateConstructorUsedError;
  List<PaymentMethodTotalDto> get methodTotals =>
      throw _privateConstructorUsedError;
  List<NonCashPaymentDto> get rows => throw _privateConstructorUsedError;

  /// Serializes this PaymentsSectionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaymentsSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentsSectionDtoCopyWith<PaymentsSectionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentsSectionDtoCopyWith<$Res> {
  factory $PaymentsSectionDtoCopyWith(
    PaymentsSectionDto value,
    $Res Function(PaymentsSectionDto) then,
  ) = _$PaymentsSectionDtoCopyWithImpl<$Res, PaymentsSectionDto>;
  @useResult
  $Res call({
    int nonCashTotal,
    List<PaymentMethodTotalDto> methodTotals,
    List<NonCashPaymentDto> rows,
  });
}

/// @nodoc
class _$PaymentsSectionDtoCopyWithImpl<$Res, $Val extends PaymentsSectionDto>
    implements $PaymentsSectionDtoCopyWith<$Res> {
  _$PaymentsSectionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentsSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nonCashTotal = null,
    Object? methodTotals = null,
    Object? rows = null,
  }) {
    return _then(
      _value.copyWith(
            nonCashTotal: null == nonCashTotal
                ? _value.nonCashTotal
                : nonCashTotal // ignore: cast_nullable_to_non_nullable
                      as int,
            methodTotals: null == methodTotals
                ? _value.methodTotals
                : methodTotals // ignore: cast_nullable_to_non_nullable
                      as List<PaymentMethodTotalDto>,
            rows: null == rows
                ? _value.rows
                : rows // ignore: cast_nullable_to_non_nullable
                      as List<NonCashPaymentDto>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaymentsSectionDtoImplCopyWith<$Res>
    implements $PaymentsSectionDtoCopyWith<$Res> {
  factory _$$PaymentsSectionDtoImplCopyWith(
    _$PaymentsSectionDtoImpl value,
    $Res Function(_$PaymentsSectionDtoImpl) then,
  ) = __$$PaymentsSectionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int nonCashTotal,
    List<PaymentMethodTotalDto> methodTotals,
    List<NonCashPaymentDto> rows,
  });
}

/// @nodoc
class __$$PaymentsSectionDtoImplCopyWithImpl<$Res>
    extends _$PaymentsSectionDtoCopyWithImpl<$Res, _$PaymentsSectionDtoImpl>
    implements _$$PaymentsSectionDtoImplCopyWith<$Res> {
  __$$PaymentsSectionDtoImplCopyWithImpl(
    _$PaymentsSectionDtoImpl _value,
    $Res Function(_$PaymentsSectionDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaymentsSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nonCashTotal = null,
    Object? methodTotals = null,
    Object? rows = null,
  }) {
    return _then(
      _$PaymentsSectionDtoImpl(
        nonCashTotal: null == nonCashTotal
            ? _value.nonCashTotal
            : nonCashTotal // ignore: cast_nullable_to_non_nullable
                  as int,
        methodTotals: null == methodTotals
            ? _value._methodTotals
            : methodTotals // ignore: cast_nullable_to_non_nullable
                  as List<PaymentMethodTotalDto>,
        rows: null == rows
            ? _value._rows
            : rows // ignore: cast_nullable_to_non_nullable
                  as List<NonCashPaymentDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentsSectionDtoImpl implements _PaymentsSectionDto {
  const _$PaymentsSectionDtoImpl({
    this.nonCashTotal = 0,
    final List<PaymentMethodTotalDto> methodTotals =
        const <PaymentMethodTotalDto>[],
    final List<NonCashPaymentDto> rows = const <NonCashPaymentDto>[],
  }) : _methodTotals = methodTotals,
       _rows = rows;

  factory _$PaymentsSectionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentsSectionDtoImplFromJson(json);

  @override
  @JsonKey()
  final int nonCashTotal;
  final List<PaymentMethodTotalDto> _methodTotals;
  @override
  @JsonKey()
  List<PaymentMethodTotalDto> get methodTotals {
    if (_methodTotals is EqualUnmodifiableListView) return _methodTotals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_methodTotals);
  }

  final List<NonCashPaymentDto> _rows;
  @override
  @JsonKey()
  List<NonCashPaymentDto> get rows {
    if (_rows is EqualUnmodifiableListView) return _rows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rows);
  }

  @override
  String toString() {
    return 'PaymentsSectionDto(nonCashTotal: $nonCashTotal, methodTotals: $methodTotals, rows: $rows)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentsSectionDtoImpl &&
            (identical(other.nonCashTotal, nonCashTotal) ||
                other.nonCashTotal == nonCashTotal) &&
            const DeepCollectionEquality().equals(
              other._methodTotals,
              _methodTotals,
            ) &&
            const DeepCollectionEquality().equals(other._rows, _rows));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    nonCashTotal,
    const DeepCollectionEquality().hash(_methodTotals),
    const DeepCollectionEquality().hash(_rows),
  );

  /// Create a copy of PaymentsSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentsSectionDtoImplCopyWith<_$PaymentsSectionDtoImpl> get copyWith =>
      __$$PaymentsSectionDtoImplCopyWithImpl<_$PaymentsSectionDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentsSectionDtoImplToJson(this);
  }
}

abstract class _PaymentsSectionDto implements PaymentsSectionDto {
  const factory _PaymentsSectionDto({
    final int nonCashTotal,
    final List<PaymentMethodTotalDto> methodTotals,
    final List<NonCashPaymentDto> rows,
  }) = _$PaymentsSectionDtoImpl;

  factory _PaymentsSectionDto.fromJson(Map<String, dynamic> json) =
      _$PaymentsSectionDtoImpl.fromJson;

  @override
  int get nonCashTotal;
  @override
  List<PaymentMethodTotalDto> get methodTotals;
  @override
  List<NonCashPaymentDto> get rows;

  /// Create a copy of PaymentsSectionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentsSectionDtoImplCopyWith<_$PaymentsSectionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PaymentMethodTotalDto _$PaymentMethodTotalDtoFromJson(
  Map<String, dynamic> json,
) {
  return _PaymentMethodTotalDto.fromJson(json);
}

/// @nodoc
mixin _$PaymentMethodTotalDto {
  String get method => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;

  /// Serializes this PaymentMethodTotalDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaymentMethodTotalDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentMethodTotalDtoCopyWith<PaymentMethodTotalDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentMethodTotalDtoCopyWith<$Res> {
  factory $PaymentMethodTotalDtoCopyWith(
    PaymentMethodTotalDto value,
    $Res Function(PaymentMethodTotalDto) then,
  ) = _$PaymentMethodTotalDtoCopyWithImpl<$Res, PaymentMethodTotalDto>;
  @useResult
  $Res call({String method, int amount, int count});
}

/// @nodoc
class _$PaymentMethodTotalDtoCopyWithImpl<
  $Res,
  $Val extends PaymentMethodTotalDto
>
    implements $PaymentMethodTotalDtoCopyWith<$Res> {
  _$PaymentMethodTotalDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentMethodTotalDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? method = null,
    Object? amount = null,
    Object? count = null,
  }) {
    return _then(
      _value.copyWith(
            method: null == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as int,
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaymentMethodTotalDtoImplCopyWith<$Res>
    implements $PaymentMethodTotalDtoCopyWith<$Res> {
  factory _$$PaymentMethodTotalDtoImplCopyWith(
    _$PaymentMethodTotalDtoImpl value,
    $Res Function(_$PaymentMethodTotalDtoImpl) then,
  ) = __$$PaymentMethodTotalDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String method, int amount, int count});
}

/// @nodoc
class __$$PaymentMethodTotalDtoImplCopyWithImpl<$Res>
    extends
        _$PaymentMethodTotalDtoCopyWithImpl<$Res, _$PaymentMethodTotalDtoImpl>
    implements _$$PaymentMethodTotalDtoImplCopyWith<$Res> {
  __$$PaymentMethodTotalDtoImplCopyWithImpl(
    _$PaymentMethodTotalDtoImpl _value,
    $Res Function(_$PaymentMethodTotalDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaymentMethodTotalDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? method = null,
    Object? amount = null,
    Object? count = null,
  }) {
    return _then(
      _$PaymentMethodTotalDtoImpl(
        method: null == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentMethodTotalDtoImpl implements _PaymentMethodTotalDto {
  const _$PaymentMethodTotalDtoImpl({
    required this.method,
    this.amount = 0,
    this.count = 0,
  });

  factory _$PaymentMethodTotalDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentMethodTotalDtoImplFromJson(json);

  @override
  final String method;
  @override
  @JsonKey()
  final int amount;
  @override
  @JsonKey()
  final int count;

  @override
  String toString() {
    return 'PaymentMethodTotalDto(method: $method, amount: $amount, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentMethodTotalDtoImpl &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.count, count) || other.count == count));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, method, amount, count);

  /// Create a copy of PaymentMethodTotalDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentMethodTotalDtoImplCopyWith<_$PaymentMethodTotalDtoImpl>
  get copyWith =>
      __$$PaymentMethodTotalDtoImplCopyWithImpl<_$PaymentMethodTotalDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentMethodTotalDtoImplToJson(this);
  }
}

abstract class _PaymentMethodTotalDto implements PaymentMethodTotalDto {
  const factory _PaymentMethodTotalDto({
    required final String method,
    final int amount,
    final int count,
  }) = _$PaymentMethodTotalDtoImpl;

  factory _PaymentMethodTotalDto.fromJson(Map<String, dynamic> json) =
      _$PaymentMethodTotalDtoImpl.fromJson;

  @override
  String get method;
  @override
  int get amount;
  @override
  int get count;

  /// Create a copy of PaymentMethodTotalDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentMethodTotalDtoImplCopyWith<_$PaymentMethodTotalDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}

NonCashPaymentDto _$NonCashPaymentDtoFromJson(Map<String, dynamic> json) {
  return _NonCashPaymentDto.fromJson(json);
}

/// @nodoc
mixin _$NonCashPaymentDto {
  String get paymentId => throw _privateConstructorUsedError;
  String get method => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  String get at => throw _privateConstructorUsedError;
  String? get tableLabel => throw _privateConstructorUsedError;
  String? get cashierName => throw _privateConstructorUsedError;
  bool get hasPhoto => throw _privateConstructorUsedError;

  /// Serializes this NonCashPaymentDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NonCashPaymentDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NonCashPaymentDtoCopyWith<NonCashPaymentDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NonCashPaymentDtoCopyWith<$Res> {
  factory $NonCashPaymentDtoCopyWith(
    NonCashPaymentDto value,
    $Res Function(NonCashPaymentDto) then,
  ) = _$NonCashPaymentDtoCopyWithImpl<$Res, NonCashPaymentDto>;
  @useResult
  $Res call({
    String paymentId,
    String method,
    int amount,
    String at,
    String? tableLabel,
    String? cashierName,
    bool hasPhoto,
  });
}

/// @nodoc
class _$NonCashPaymentDtoCopyWithImpl<$Res, $Val extends NonCashPaymentDto>
    implements $NonCashPaymentDtoCopyWith<$Res> {
  _$NonCashPaymentDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NonCashPaymentDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? paymentId = null,
    Object? method = null,
    Object? amount = null,
    Object? at = null,
    Object? tableLabel = freezed,
    Object? cashierName = freezed,
    Object? hasPhoto = null,
  }) {
    return _then(
      _value.copyWith(
            paymentId: null == paymentId
                ? _value.paymentId
                : paymentId // ignore: cast_nullable_to_non_nullable
                      as String,
            method: null == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as int,
            at: null == at
                ? _value.at
                : at // ignore: cast_nullable_to_non_nullable
                      as String,
            tableLabel: freezed == tableLabel
                ? _value.tableLabel
                : tableLabel // ignore: cast_nullable_to_non_nullable
                      as String?,
            cashierName: freezed == cashierName
                ? _value.cashierName
                : cashierName // ignore: cast_nullable_to_non_nullable
                      as String?,
            hasPhoto: null == hasPhoto
                ? _value.hasPhoto
                : hasPhoto // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NonCashPaymentDtoImplCopyWith<$Res>
    implements $NonCashPaymentDtoCopyWith<$Res> {
  factory _$$NonCashPaymentDtoImplCopyWith(
    _$NonCashPaymentDtoImpl value,
    $Res Function(_$NonCashPaymentDtoImpl) then,
  ) = __$$NonCashPaymentDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String paymentId,
    String method,
    int amount,
    String at,
    String? tableLabel,
    String? cashierName,
    bool hasPhoto,
  });
}

/// @nodoc
class __$$NonCashPaymentDtoImplCopyWithImpl<$Res>
    extends _$NonCashPaymentDtoCopyWithImpl<$Res, _$NonCashPaymentDtoImpl>
    implements _$$NonCashPaymentDtoImplCopyWith<$Res> {
  __$$NonCashPaymentDtoImplCopyWithImpl(
    _$NonCashPaymentDtoImpl _value,
    $Res Function(_$NonCashPaymentDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NonCashPaymentDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? paymentId = null,
    Object? method = null,
    Object? amount = null,
    Object? at = null,
    Object? tableLabel = freezed,
    Object? cashierName = freezed,
    Object? hasPhoto = null,
  }) {
    return _then(
      _$NonCashPaymentDtoImpl(
        paymentId: null == paymentId
            ? _value.paymentId
            : paymentId // ignore: cast_nullable_to_non_nullable
                  as String,
        method: null == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        at: null == at
            ? _value.at
            : at // ignore: cast_nullable_to_non_nullable
                  as String,
        tableLabel: freezed == tableLabel
            ? _value.tableLabel
            : tableLabel // ignore: cast_nullable_to_non_nullable
                  as String?,
        cashierName: freezed == cashierName
            ? _value.cashierName
            : cashierName // ignore: cast_nullable_to_non_nullable
                  as String?,
        hasPhoto: null == hasPhoto
            ? _value.hasPhoto
            : hasPhoto // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NonCashPaymentDtoImpl implements _NonCashPaymentDto {
  const _$NonCashPaymentDtoImpl({
    required this.paymentId,
    required this.method,
    this.amount = 0,
    this.at = '',
    this.tableLabel,
    this.cashierName,
    this.hasPhoto = false,
  });

  factory _$NonCashPaymentDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$NonCashPaymentDtoImplFromJson(json);

  @override
  final String paymentId;
  @override
  final String method;
  @override
  @JsonKey()
  final int amount;
  @override
  @JsonKey()
  final String at;
  @override
  final String? tableLabel;
  @override
  final String? cashierName;
  @override
  @JsonKey()
  final bool hasPhoto;

  @override
  String toString() {
    return 'NonCashPaymentDto(paymentId: $paymentId, method: $method, amount: $amount, at: $at, tableLabel: $tableLabel, cashierName: $cashierName, hasPhoto: $hasPhoto)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NonCashPaymentDtoImpl &&
            (identical(other.paymentId, paymentId) ||
                other.paymentId == paymentId) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.at, at) || other.at == at) &&
            (identical(other.tableLabel, tableLabel) ||
                other.tableLabel == tableLabel) &&
            (identical(other.cashierName, cashierName) ||
                other.cashierName == cashierName) &&
            (identical(other.hasPhoto, hasPhoto) ||
                other.hasPhoto == hasPhoto));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    paymentId,
    method,
    amount,
    at,
    tableLabel,
    cashierName,
    hasPhoto,
  );

  /// Create a copy of NonCashPaymentDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NonCashPaymentDtoImplCopyWith<_$NonCashPaymentDtoImpl> get copyWith =>
      __$$NonCashPaymentDtoImplCopyWithImpl<_$NonCashPaymentDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NonCashPaymentDtoImplToJson(this);
  }
}

abstract class _NonCashPaymentDto implements NonCashPaymentDto {
  const factory _NonCashPaymentDto({
    required final String paymentId,
    required final String method,
    final int amount,
    final String at,
    final String? tableLabel,
    final String? cashierName,
    final bool hasPhoto,
  }) = _$NonCashPaymentDtoImpl;

  factory _NonCashPaymentDto.fromJson(Map<String, dynamic> json) =
      _$NonCashPaymentDtoImpl.fromJson;

  @override
  String get paymentId;
  @override
  String get method;
  @override
  int get amount;
  @override
  String get at;
  @override
  String? get tableLabel;
  @override
  String? get cashierName;
  @override
  bool get hasPhoto;

  /// Create a copy of NonCashPaymentDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NonCashPaymentDtoImplCopyWith<_$NonCashPaymentDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StaffVoidDto _$StaffVoidDtoFromJson(Map<String, dynamic> json) {
  return _StaffVoidDto.fromJson(json);
}

/// @nodoc
mixin _$StaffVoidDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  int get lostRupiah => throw _privateConstructorUsedError;
  String get topReasonCode => throw _privateConstructorUsedError;

  /// Serializes this StaffVoidDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StaffVoidDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StaffVoidDtoCopyWith<StaffVoidDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StaffVoidDtoCopyWith<$Res> {
  factory $StaffVoidDtoCopyWith(
    StaffVoidDto value,
    $Res Function(StaffVoidDto) then,
  ) = _$StaffVoidDtoCopyWithImpl<$Res, StaffVoidDto>;
  @useResult
  $Res call({
    String id,
    String name,
    int count,
    int lostRupiah,
    String topReasonCode,
  });
}

/// @nodoc
class _$StaffVoidDtoCopyWithImpl<$Res, $Val extends StaffVoidDto>
    implements $StaffVoidDtoCopyWith<$Res> {
  _$StaffVoidDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StaffVoidDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? count = null,
    Object? lostRupiah = null,
    Object? topReasonCode = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
            lostRupiah: null == lostRupiah
                ? _value.lostRupiah
                : lostRupiah // ignore: cast_nullable_to_non_nullable
                      as int,
            topReasonCode: null == topReasonCode
                ? _value.topReasonCode
                : topReasonCode // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StaffVoidDtoImplCopyWith<$Res>
    implements $StaffVoidDtoCopyWith<$Res> {
  factory _$$StaffVoidDtoImplCopyWith(
    _$StaffVoidDtoImpl value,
    $Res Function(_$StaffVoidDtoImpl) then,
  ) = __$$StaffVoidDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int count,
    int lostRupiah,
    String topReasonCode,
  });
}

/// @nodoc
class __$$StaffVoidDtoImplCopyWithImpl<$Res>
    extends _$StaffVoidDtoCopyWithImpl<$Res, _$StaffVoidDtoImpl>
    implements _$$StaffVoidDtoImplCopyWith<$Res> {
  __$$StaffVoidDtoImplCopyWithImpl(
    _$StaffVoidDtoImpl _value,
    $Res Function(_$StaffVoidDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StaffVoidDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? count = null,
    Object? lostRupiah = null,
    Object? topReasonCode = null,
  }) {
    return _then(
      _$StaffVoidDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        lostRupiah: null == lostRupiah
            ? _value.lostRupiah
            : lostRupiah // ignore: cast_nullable_to_non_nullable
                  as int,
        topReasonCode: null == topReasonCode
            ? _value.topReasonCode
            : topReasonCode // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StaffVoidDtoImpl implements _StaffVoidDto {
  const _$StaffVoidDtoImpl({
    required this.id,
    required this.name,
    this.count = 0,
    this.lostRupiah = 0,
    this.topReasonCode = 'other',
  });

  factory _$StaffVoidDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StaffVoidDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final int count;
  @override
  @JsonKey()
  final int lostRupiah;
  @override
  @JsonKey()
  final String topReasonCode;

  @override
  String toString() {
    return 'StaffVoidDto(id: $id, name: $name, count: $count, lostRupiah: $lostRupiah, topReasonCode: $topReasonCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StaffVoidDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.lostRupiah, lostRupiah) ||
                other.lostRupiah == lostRupiah) &&
            (identical(other.topReasonCode, topReasonCode) ||
                other.topReasonCode == topReasonCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, count, lostRupiah, topReasonCode);

  /// Create a copy of StaffVoidDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StaffVoidDtoImplCopyWith<_$StaffVoidDtoImpl> get copyWith =>
      __$$StaffVoidDtoImplCopyWithImpl<_$StaffVoidDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StaffVoidDtoImplToJson(this);
  }
}

abstract class _StaffVoidDto implements StaffVoidDto {
  const factory _StaffVoidDto({
    required final String id,
    required final String name,
    final int count,
    final int lostRupiah,
    final String topReasonCode,
  }) = _$StaffVoidDtoImpl;

  factory _StaffVoidDto.fromJson(Map<String, dynamic> json) =
      _$StaffVoidDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get count;
  @override
  int get lostRupiah;
  @override
  String get topReasonCode;

  /// Create a copy of StaffVoidDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StaffVoidDtoImplCopyWith<_$StaffVoidDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
