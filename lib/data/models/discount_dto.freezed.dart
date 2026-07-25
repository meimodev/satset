// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discount_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DiscountPresetDto _$DiscountPresetDtoFromJson(Map<String, dynamic> json) {
  return _DiscountPresetDto.fromJson(json);
}

/// @nodoc
mixin _$DiscountPresetDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// `order` (whole receipt) | `line` (one bill line). The picker only offers
  /// presets valid for what the cashier tapped — this is what stops a fixed
  /// whole-bill amount landing on a single cheap line.
  String get scope => throw _privateConstructorUsedError;

  /// `percent` (value in basis points) | `fixed` (value in rupiah).
  String get kind => throw _privateConstructorUsedError;
  int get value => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this DiscountPresetDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiscountPresetDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiscountPresetDtoCopyWith<DiscountPresetDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiscountPresetDtoCopyWith<$Res> {
  factory $DiscountPresetDtoCopyWith(
    DiscountPresetDto value,
    $Res Function(DiscountPresetDto) then,
  ) = _$DiscountPresetDtoCopyWithImpl<$Res, DiscountPresetDto>;
  @useResult
  $Res call({
    String id,
    String name,
    String scope,
    String kind,
    int value,
    bool active,
    int sortOrder,
  });
}

/// @nodoc
class _$DiscountPresetDtoCopyWithImpl<$Res, $Val extends DiscountPresetDto>
    implements $DiscountPresetDtoCopyWith<$Res> {
  _$DiscountPresetDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiscountPresetDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? scope = null,
    Object? kind = null,
    Object? value = null,
    Object? active = null,
    Object? sortOrder = null,
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
            scope: null == scope
                ? _value.scope
                : scope // ignore: cast_nullable_to_non_nullable
                      as String,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as int,
            active: null == active
                ? _value.active
                : active // ignore: cast_nullable_to_non_nullable
                      as bool,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DiscountPresetDtoImplCopyWith<$Res>
    implements $DiscountPresetDtoCopyWith<$Res> {
  factory _$$DiscountPresetDtoImplCopyWith(
    _$DiscountPresetDtoImpl value,
    $Res Function(_$DiscountPresetDtoImpl) then,
  ) = __$$DiscountPresetDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String scope,
    String kind,
    int value,
    bool active,
    int sortOrder,
  });
}

/// @nodoc
class __$$DiscountPresetDtoImplCopyWithImpl<$Res>
    extends _$DiscountPresetDtoCopyWithImpl<$Res, _$DiscountPresetDtoImpl>
    implements _$$DiscountPresetDtoImplCopyWith<$Res> {
  __$$DiscountPresetDtoImplCopyWithImpl(
    _$DiscountPresetDtoImpl _value,
    $Res Function(_$DiscountPresetDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DiscountPresetDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? scope = null,
    Object? kind = null,
    Object? value = null,
    Object? active = null,
    Object? sortOrder = null,
  }) {
    return _then(
      _$DiscountPresetDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        scope: null == scope
            ? _value.scope
            : scope // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as int,
        active: null == active
            ? _value.active
            : active // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DiscountPresetDtoImpl implements _DiscountPresetDto {
  const _$DiscountPresetDtoImpl({
    required this.id,
    this.name = '',
    this.scope = 'order',
    this.kind = 'percent',
    this.value = 0,
    this.active = true,
    this.sortOrder = 0,
  });

  factory _$DiscountPresetDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiscountPresetDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String name;

  /// `order` (whole receipt) | `line` (one bill line). The picker only offers
  /// presets valid for what the cashier tapped — this is what stops a fixed
  /// whole-bill amount landing on a single cheap line.
  @override
  @JsonKey()
  final String scope;

  /// `percent` (value in basis points) | `fixed` (value in rupiah).
  @override
  @JsonKey()
  final String kind;
  @override
  @JsonKey()
  final int value;
  @override
  @JsonKey()
  final bool active;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'DiscountPresetDto(id: $id, name: $name, scope: $scope, kind: $kind, value: $value, active: $active, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiscountPresetDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, scope, kind, value, active, sortOrder);

  /// Create a copy of DiscountPresetDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiscountPresetDtoImplCopyWith<_$DiscountPresetDtoImpl> get copyWith =>
      __$$DiscountPresetDtoImplCopyWithImpl<_$DiscountPresetDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DiscountPresetDtoImplToJson(this);
  }
}

abstract class _DiscountPresetDto implements DiscountPresetDto {
  const factory _DiscountPresetDto({
    required final String id,
    final String name,
    final String scope,
    final String kind,
    final int value,
    final bool active,
    final int sortOrder,
  }) = _$DiscountPresetDtoImpl;

  factory _DiscountPresetDto.fromJson(Map<String, dynamic> json) =
      _$DiscountPresetDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// `order` (whole receipt) | `line` (one bill line). The picker only offers
  /// presets valid for what the cashier tapped — this is what stops a fixed
  /// whole-bill amount landing on a single cheap line.
  @override
  String get scope;

  /// `percent` (value in basis points) | `fixed` (value in rupiah).
  @override
  String get kind;
  @override
  int get value;
  @override
  bool get active;
  @override
  int get sortOrder;

  /// Create a copy of DiscountPresetDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiscountPresetDtoImplCopyWith<_$DiscountPresetDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppliedDiscountDto _$AppliedDiscountDtoFromJson(Map<String, dynamic> json) {
  return _AppliedDiscountDto.fromJson(json);
}

/// @nodoc
mixin _$AppliedDiscountDto {
  String get id => throw _privateConstructorUsedError;
  String? get ticketId => throw _privateConstructorUsedError;
  String? get presetId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  int get value => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  String? get byUserId => throw _privateConstructorUsedError;
  String? get approvedByUserId => throw _privateConstructorUsedError;

  /// Serializes this AppliedDiscountDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppliedDiscountDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppliedDiscountDtoCopyWith<AppliedDiscountDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppliedDiscountDtoCopyWith<$Res> {
  factory $AppliedDiscountDtoCopyWith(
    AppliedDiscountDto value,
    $Res Function(AppliedDiscountDto) then,
  ) = _$AppliedDiscountDtoCopyWithImpl<$Res, AppliedDiscountDto>;
  @useResult
  $Res call({
    String id,
    String? ticketId,
    String? presetId,
    String name,
    String kind,
    int value,
    int amount,
    String? byUserId,
    String? approvedByUserId,
  });
}

/// @nodoc
class _$AppliedDiscountDtoCopyWithImpl<$Res, $Val extends AppliedDiscountDto>
    implements $AppliedDiscountDtoCopyWith<$Res> {
  _$AppliedDiscountDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppliedDiscountDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ticketId = freezed,
    Object? presetId = freezed,
    Object? name = null,
    Object? kind = null,
    Object? value = null,
    Object? amount = null,
    Object? byUserId = freezed,
    Object? approvedByUserId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            ticketId: freezed == ticketId
                ? _value.ticketId
                : ticketId // ignore: cast_nullable_to_non_nullable
                      as String?,
            presetId: freezed == presetId
                ? _value.presetId
                : presetId // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as int,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as int,
            byUserId: freezed == byUserId
                ? _value.byUserId
                : byUserId // ignore: cast_nullable_to_non_nullable
                      as String?,
            approvedByUserId: freezed == approvedByUserId
                ? _value.approvedByUserId
                : approvedByUserId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppliedDiscountDtoImplCopyWith<$Res>
    implements $AppliedDiscountDtoCopyWith<$Res> {
  factory _$$AppliedDiscountDtoImplCopyWith(
    _$AppliedDiscountDtoImpl value,
    $Res Function(_$AppliedDiscountDtoImpl) then,
  ) = __$$AppliedDiscountDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? ticketId,
    String? presetId,
    String name,
    String kind,
    int value,
    int amount,
    String? byUserId,
    String? approvedByUserId,
  });
}

/// @nodoc
class __$$AppliedDiscountDtoImplCopyWithImpl<$Res>
    extends _$AppliedDiscountDtoCopyWithImpl<$Res, _$AppliedDiscountDtoImpl>
    implements _$$AppliedDiscountDtoImplCopyWith<$Res> {
  __$$AppliedDiscountDtoImplCopyWithImpl(
    _$AppliedDiscountDtoImpl _value,
    $Res Function(_$AppliedDiscountDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppliedDiscountDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ticketId = freezed,
    Object? presetId = freezed,
    Object? name = null,
    Object? kind = null,
    Object? value = null,
    Object? amount = null,
    Object? byUserId = freezed,
    Object? approvedByUserId = freezed,
  }) {
    return _then(
      _$AppliedDiscountDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        ticketId: freezed == ticketId
            ? _value.ticketId
            : ticketId // ignore: cast_nullable_to_non_nullable
                  as String?,
        presetId: freezed == presetId
            ? _value.presetId
            : presetId // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as int,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        byUserId: freezed == byUserId
            ? _value.byUserId
            : byUserId // ignore: cast_nullable_to_non_nullable
                  as String?,
        approvedByUserId: freezed == approvedByUserId
            ? _value.approvedByUserId
            : approvedByUserId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppliedDiscountDtoImpl implements _AppliedDiscountDto {
  const _$AppliedDiscountDtoImpl({
    required this.id,
    this.ticketId,
    this.presetId,
    this.name = '',
    this.kind = 'percent',
    this.value = 0,
    this.amount = 0,
    this.byUserId,
    this.approvedByUserId,
  });

  factory _$AppliedDiscountDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppliedDiscountDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String? ticketId;
  @override
  final String? presetId;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String kind;
  @override
  @JsonKey()
  final int value;
  @override
  @JsonKey()
  final int amount;
  @override
  final String? byUserId;
  @override
  final String? approvedByUserId;

  @override
  String toString() {
    return 'AppliedDiscountDto(id: $id, ticketId: $ticketId, presetId: $presetId, name: $name, kind: $kind, value: $value, amount: $amount, byUserId: $byUserId, approvedByUserId: $approvedByUserId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppliedDiscountDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ticketId, ticketId) ||
                other.ticketId == ticketId) &&
            (identical(other.presetId, presetId) ||
                other.presetId == presetId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.byUserId, byUserId) ||
                other.byUserId == byUserId) &&
            (identical(other.approvedByUserId, approvedByUserId) ||
                other.approvedByUserId == approvedByUserId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    ticketId,
    presetId,
    name,
    kind,
    value,
    amount,
    byUserId,
    approvedByUserId,
  );

  /// Create a copy of AppliedDiscountDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppliedDiscountDtoImplCopyWith<_$AppliedDiscountDtoImpl> get copyWith =>
      __$$AppliedDiscountDtoImplCopyWithImpl<_$AppliedDiscountDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AppliedDiscountDtoImplToJson(this);
  }
}

abstract class _AppliedDiscountDto implements AppliedDiscountDto {
  const factory _AppliedDiscountDto({
    required final String id,
    final String? ticketId,
    final String? presetId,
    final String name,
    final String kind,
    final int value,
    final int amount,
    final String? byUserId,
    final String? approvedByUserId,
  }) = _$AppliedDiscountDtoImpl;

  factory _AppliedDiscountDto.fromJson(Map<String, dynamic> json) =
      _$AppliedDiscountDtoImpl.fromJson;

  @override
  String get id;
  @override
  String? get ticketId;
  @override
  String? get presetId;
  @override
  String get name;
  @override
  String get kind;
  @override
  int get value;
  @override
  int get amount;
  @override
  String? get byUserId;
  @override
  String? get approvedByUserId;

  /// Create a copy of AppliedDiscountDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppliedDiscountDtoImplCopyWith<_$AppliedDiscountDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
