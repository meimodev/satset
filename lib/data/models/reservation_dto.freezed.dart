// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reservation_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReservationDto _$ReservationDtoFromJson(Map<String, dynamic> json) {
  return _ReservationDto.fromJson(json);
}

/// @nodoc
mixin _$ReservationDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  int get partySize => throw _privateConstructorUsedError;
  DateTime get expectedAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get zoneId => throw _privateConstructorUsedError;
  String? get tableId => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// The [[Pelanggan (member)]] the booking was made against, if the phone
  /// matched one. [name] and [phone] stay the snapshot of what was booked.
  String? get memberId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ReservationDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReservationDtoCopyWith<ReservationDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReservationDtoCopyWith<$Res> {
  factory $ReservationDtoCopyWith(
    ReservationDto value,
    $Res Function(ReservationDto) then,
  ) = _$ReservationDtoCopyWithImpl<$Res, ReservationDto>;
  @useResult
  $Res call({
    String id,
    String name,
    String? phone,
    int partySize,
    DateTime expectedAt,
    String status,
    String? zoneId,
    String? tableId,
    String? notes,
    String? memberId,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$ReservationDtoCopyWithImpl<$Res, $Val extends ReservationDto>
    implements $ReservationDtoCopyWith<$Res> {
  _$ReservationDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone = freezed,
    Object? partySize = null,
    Object? expectedAt = null,
    Object? status = null,
    Object? zoneId = freezed,
    Object? tableId = freezed,
    Object? notes = freezed,
    Object? memberId = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
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
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            partySize: null == partySize
                ? _value.partySize
                : partySize // ignore: cast_nullable_to_non_nullable
                      as int,
            expectedAt: null == expectedAt
                ? _value.expectedAt
                : expectedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            zoneId: freezed == zoneId
                ? _value.zoneId
                : zoneId // ignore: cast_nullable_to_non_nullable
                      as String?,
            tableId: freezed == tableId
                ? _value.tableId
                : tableId // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            memberId: freezed == memberId
                ? _value.memberId
                : memberId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReservationDtoImplCopyWith<$Res>
    implements $ReservationDtoCopyWith<$Res> {
  factory _$$ReservationDtoImplCopyWith(
    _$ReservationDtoImpl value,
    $Res Function(_$ReservationDtoImpl) then,
  ) = __$$ReservationDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? phone,
    int partySize,
    DateTime expectedAt,
    String status,
    String? zoneId,
    String? tableId,
    String? notes,
    String? memberId,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$ReservationDtoImplCopyWithImpl<$Res>
    extends _$ReservationDtoCopyWithImpl<$Res, _$ReservationDtoImpl>
    implements _$$ReservationDtoImplCopyWith<$Res> {
  __$$ReservationDtoImplCopyWithImpl(
    _$ReservationDtoImpl _value,
    $Res Function(_$ReservationDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone = freezed,
    Object? partySize = null,
    Object? expectedAt = null,
    Object? status = null,
    Object? zoneId = freezed,
    Object? tableId = freezed,
    Object? notes = freezed,
    Object? memberId = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$ReservationDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        partySize: null == partySize
            ? _value.partySize
            : partySize // ignore: cast_nullable_to_non_nullable
                  as int,
        expectedAt: null == expectedAt
            ? _value.expectedAt
            : expectedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        zoneId: freezed == zoneId
            ? _value.zoneId
            : zoneId // ignore: cast_nullable_to_non_nullable
                  as String?,
        tableId: freezed == tableId
            ? _value.tableId
            : tableId // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        memberId: freezed == memberId
            ? _value.memberId
            : memberId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReservationDtoImpl implements _ReservationDto {
  const _$ReservationDtoImpl({
    required this.id,
    required this.name,
    this.phone,
    this.partySize = 1,
    required this.expectedAt,
    this.status = 'pending',
    this.zoneId,
    this.tableId,
    this.notes,
    this.memberId,
    required this.createdAt,
    this.updatedAt,
  });

  factory _$ReservationDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReservationDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? phone;
  @override
  @JsonKey()
  final int partySize;
  @override
  final DateTime expectedAt;
  @override
  @JsonKey()
  final String status;
  @override
  final String? zoneId;
  @override
  final String? tableId;
  @override
  final String? notes;

  /// The [[Pelanggan (member)]] the booking was made against, if the phone
  /// matched one. [name] and [phone] stay the snapshot of what was booked.
  @override
  final String? memberId;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ReservationDto(id: $id, name: $name, phone: $phone, partySize: $partySize, expectedAt: $expectedAt, status: $status, zoneId: $zoneId, tableId: $tableId, notes: $notes, memberId: $memberId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReservationDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.partySize, partySize) ||
                other.partySize == partySize) &&
            (identical(other.expectedAt, expectedAt) ||
                other.expectedAt == expectedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.zoneId, zoneId) || other.zoneId == zoneId) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    phone,
    partySize,
    expectedAt,
    status,
    zoneId,
    tableId,
    notes,
    memberId,
    createdAt,
    updatedAt,
  );

  /// Create a copy of ReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReservationDtoImplCopyWith<_$ReservationDtoImpl> get copyWith =>
      __$$ReservationDtoImplCopyWithImpl<_$ReservationDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReservationDtoImplToJson(this);
  }
}

abstract class _ReservationDto implements ReservationDto {
  const factory _ReservationDto({
    required final String id,
    required final String name,
    final String? phone,
    final int partySize,
    required final DateTime expectedAt,
    final String status,
    final String? zoneId,
    final String? tableId,
    final String? notes,
    final String? memberId,
    required final DateTime createdAt,
    final DateTime? updatedAt,
  }) = _$ReservationDtoImpl;

  factory _ReservationDto.fromJson(Map<String, dynamic> json) =
      _$ReservationDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get phone;
  @override
  int get partySize;
  @override
  DateTime get expectedAt;
  @override
  String get status;
  @override
  String? get zoneId;
  @override
  String? get tableId;
  @override
  String? get notes;

  /// The [[Pelanggan (member)]] the booking was made against, if the phone
  /// matched one. [name] and [phone] stay the snapshot of what was booked.
  @override
  String? get memberId;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of ReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReservationDtoImplCopyWith<_$ReservationDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateReservationDto _$CreateReservationDtoFromJson(Map<String, dynamic> json) {
  return _CreateReservationDto.fromJson(json);
}

/// @nodoc
mixin _$CreateReservationDto {
  String get name => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  int get partySize => throw _privateConstructorUsedError;
  DateTime get expectedAt => throw _privateConstructorUsedError;
  String? get zoneId => throw _privateConstructorUsedError;
  String? get tableId => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get memberId => throw _privateConstructorUsedError;

  /// Serializes this CreateReservationDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateReservationDtoCopyWith<CreateReservationDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateReservationDtoCopyWith<$Res> {
  factory $CreateReservationDtoCopyWith(
    CreateReservationDto value,
    $Res Function(CreateReservationDto) then,
  ) = _$CreateReservationDtoCopyWithImpl<$Res, CreateReservationDto>;
  @useResult
  $Res call({
    String name,
    String? phone,
    int partySize,
    DateTime expectedAt,
    String? zoneId,
    String? tableId,
    String? notes,
    String? memberId,
  });
}

/// @nodoc
class _$CreateReservationDtoCopyWithImpl<
  $Res,
  $Val extends CreateReservationDto
>
    implements $CreateReservationDtoCopyWith<$Res> {
  _$CreateReservationDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? phone = freezed,
    Object? partySize = null,
    Object? expectedAt = null,
    Object? zoneId = freezed,
    Object? tableId = freezed,
    Object? notes = freezed,
    Object? memberId = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            partySize: null == partySize
                ? _value.partySize
                : partySize // ignore: cast_nullable_to_non_nullable
                      as int,
            expectedAt: null == expectedAt
                ? _value.expectedAt
                : expectedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            zoneId: freezed == zoneId
                ? _value.zoneId
                : zoneId // ignore: cast_nullable_to_non_nullable
                      as String?,
            tableId: freezed == tableId
                ? _value.tableId
                : tableId // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            memberId: freezed == memberId
                ? _value.memberId
                : memberId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateReservationDtoImplCopyWith<$Res>
    implements $CreateReservationDtoCopyWith<$Res> {
  factory _$$CreateReservationDtoImplCopyWith(
    _$CreateReservationDtoImpl value,
    $Res Function(_$CreateReservationDtoImpl) then,
  ) = __$$CreateReservationDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String? phone,
    int partySize,
    DateTime expectedAt,
    String? zoneId,
    String? tableId,
    String? notes,
    String? memberId,
  });
}

/// @nodoc
class __$$CreateReservationDtoImplCopyWithImpl<$Res>
    extends _$CreateReservationDtoCopyWithImpl<$Res, _$CreateReservationDtoImpl>
    implements _$$CreateReservationDtoImplCopyWith<$Res> {
  __$$CreateReservationDtoImplCopyWithImpl(
    _$CreateReservationDtoImpl _value,
    $Res Function(_$CreateReservationDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? phone = freezed,
    Object? partySize = null,
    Object? expectedAt = null,
    Object? zoneId = freezed,
    Object? tableId = freezed,
    Object? notes = freezed,
    Object? memberId = freezed,
  }) {
    return _then(
      _$CreateReservationDtoImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        partySize: null == partySize
            ? _value.partySize
            : partySize // ignore: cast_nullable_to_non_nullable
                  as int,
        expectedAt: null == expectedAt
            ? _value.expectedAt
            : expectedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        zoneId: freezed == zoneId
            ? _value.zoneId
            : zoneId // ignore: cast_nullable_to_non_nullable
                  as String?,
        tableId: freezed == tableId
            ? _value.tableId
            : tableId // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        memberId: freezed == memberId
            ? _value.memberId
            : memberId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateReservationDtoImpl implements _CreateReservationDto {
  const _$CreateReservationDtoImpl({
    required this.name,
    this.phone,
    this.partySize = 1,
    required this.expectedAt,
    this.zoneId,
    this.tableId,
    this.notes,
    this.memberId,
  });

  factory _$CreateReservationDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateReservationDtoImplFromJson(json);

  @override
  final String name;
  @override
  final String? phone;
  @override
  @JsonKey()
  final int partySize;
  @override
  final DateTime expectedAt;
  @override
  final String? zoneId;
  @override
  final String? tableId;
  @override
  final String? notes;
  @override
  final String? memberId;

  @override
  String toString() {
    return 'CreateReservationDto(name: $name, phone: $phone, partySize: $partySize, expectedAt: $expectedAt, zoneId: $zoneId, tableId: $tableId, notes: $notes, memberId: $memberId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateReservationDtoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.partySize, partySize) ||
                other.partySize == partySize) &&
            (identical(other.expectedAt, expectedAt) ||
                other.expectedAt == expectedAt) &&
            (identical(other.zoneId, zoneId) || other.zoneId == zoneId) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    phone,
    partySize,
    expectedAt,
    zoneId,
    tableId,
    notes,
    memberId,
  );

  /// Create a copy of CreateReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateReservationDtoImplCopyWith<_$CreateReservationDtoImpl>
  get copyWith =>
      __$$CreateReservationDtoImplCopyWithImpl<_$CreateReservationDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateReservationDtoImplToJson(this);
  }
}

abstract class _CreateReservationDto implements CreateReservationDto {
  const factory _CreateReservationDto({
    required final String name,
    final String? phone,
    final int partySize,
    required final DateTime expectedAt,
    final String? zoneId,
    final String? tableId,
    final String? notes,
    final String? memberId,
  }) = _$CreateReservationDtoImpl;

  factory _CreateReservationDto.fromJson(Map<String, dynamic> json) =
      _$CreateReservationDtoImpl.fromJson;

  @override
  String get name;
  @override
  String? get phone;
  @override
  int get partySize;
  @override
  DateTime get expectedAt;
  @override
  String? get zoneId;
  @override
  String? get tableId;
  @override
  String? get notes;
  @override
  String? get memberId;

  /// Create a copy of CreateReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateReservationDtoImplCopyWith<_$CreateReservationDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PatchReservationDto _$PatchReservationDtoFromJson(Map<String, dynamic> json) {
  return _PatchReservationDto.fromJson(json);
}

/// @nodoc
mixin _$PatchReservationDto {
  String? get name => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  int? get partySize => throw _privateConstructorUsedError;
  DateTime? get expectedAt => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  String? get zoneId => throw _privateConstructorUsedError;
  String? get tableId => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get memberId => throw _privateConstructorUsedError;

  /// Serializes this PatchReservationDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PatchReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PatchReservationDtoCopyWith<PatchReservationDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PatchReservationDtoCopyWith<$Res> {
  factory $PatchReservationDtoCopyWith(
    PatchReservationDto value,
    $Res Function(PatchReservationDto) then,
  ) = _$PatchReservationDtoCopyWithImpl<$Res, PatchReservationDto>;
  @useResult
  $Res call({
    String? name,
    String? phone,
    int? partySize,
    DateTime? expectedAt,
    String? status,
    String? zoneId,
    String? tableId,
    String? notes,
    String? memberId,
  });
}

/// @nodoc
class _$PatchReservationDtoCopyWithImpl<$Res, $Val extends PatchReservationDto>
    implements $PatchReservationDtoCopyWith<$Res> {
  _$PatchReservationDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PatchReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? phone = freezed,
    Object? partySize = freezed,
    Object? expectedAt = freezed,
    Object? status = freezed,
    Object? zoneId = freezed,
    Object? tableId = freezed,
    Object? notes = freezed,
    Object? memberId = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            partySize: freezed == partySize
                ? _value.partySize
                : partySize // ignore: cast_nullable_to_non_nullable
                      as int?,
            expectedAt: freezed == expectedAt
                ? _value.expectedAt
                : expectedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String?,
            zoneId: freezed == zoneId
                ? _value.zoneId
                : zoneId // ignore: cast_nullable_to_non_nullable
                      as String?,
            tableId: freezed == tableId
                ? _value.tableId
                : tableId // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            memberId: freezed == memberId
                ? _value.memberId
                : memberId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PatchReservationDtoImplCopyWith<$Res>
    implements $PatchReservationDtoCopyWith<$Res> {
  factory _$$PatchReservationDtoImplCopyWith(
    _$PatchReservationDtoImpl value,
    $Res Function(_$PatchReservationDtoImpl) then,
  ) = __$$PatchReservationDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? name,
    String? phone,
    int? partySize,
    DateTime? expectedAt,
    String? status,
    String? zoneId,
    String? tableId,
    String? notes,
    String? memberId,
  });
}

/// @nodoc
class __$$PatchReservationDtoImplCopyWithImpl<$Res>
    extends _$PatchReservationDtoCopyWithImpl<$Res, _$PatchReservationDtoImpl>
    implements _$$PatchReservationDtoImplCopyWith<$Res> {
  __$$PatchReservationDtoImplCopyWithImpl(
    _$PatchReservationDtoImpl _value,
    $Res Function(_$PatchReservationDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PatchReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? phone = freezed,
    Object? partySize = freezed,
    Object? expectedAt = freezed,
    Object? status = freezed,
    Object? zoneId = freezed,
    Object? tableId = freezed,
    Object? notes = freezed,
    Object? memberId = freezed,
  }) {
    return _then(
      _$PatchReservationDtoImpl(
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        partySize: freezed == partySize
            ? _value.partySize
            : partySize // ignore: cast_nullable_to_non_nullable
                  as int?,
        expectedAt: freezed == expectedAt
            ? _value.expectedAt
            : expectedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String?,
        zoneId: freezed == zoneId
            ? _value.zoneId
            : zoneId // ignore: cast_nullable_to_non_nullable
                  as String?,
        tableId: freezed == tableId
            ? _value.tableId
            : tableId // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        memberId: freezed == memberId
            ? _value.memberId
            : memberId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PatchReservationDtoImpl implements _PatchReservationDto {
  const _$PatchReservationDtoImpl({
    this.name,
    this.phone,
    this.partySize,
    this.expectedAt,
    this.status,
    this.zoneId,
    this.tableId,
    this.notes,
    this.memberId,
  });

  factory _$PatchReservationDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PatchReservationDtoImplFromJson(json);

  @override
  final String? name;
  @override
  final String? phone;
  @override
  final int? partySize;
  @override
  final DateTime? expectedAt;
  @override
  final String? status;
  @override
  final String? zoneId;
  @override
  final String? tableId;
  @override
  final String? notes;
  @override
  final String? memberId;

  @override
  String toString() {
    return 'PatchReservationDto(name: $name, phone: $phone, partySize: $partySize, expectedAt: $expectedAt, status: $status, zoneId: $zoneId, tableId: $tableId, notes: $notes, memberId: $memberId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PatchReservationDtoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.partySize, partySize) ||
                other.partySize == partySize) &&
            (identical(other.expectedAt, expectedAt) ||
                other.expectedAt == expectedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.zoneId, zoneId) || other.zoneId == zoneId) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    phone,
    partySize,
    expectedAt,
    status,
    zoneId,
    tableId,
    notes,
    memberId,
  );

  /// Create a copy of PatchReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PatchReservationDtoImplCopyWith<_$PatchReservationDtoImpl> get copyWith =>
      __$$PatchReservationDtoImplCopyWithImpl<_$PatchReservationDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PatchReservationDtoImplToJson(this);
  }
}

abstract class _PatchReservationDto implements PatchReservationDto {
  const factory _PatchReservationDto({
    final String? name,
    final String? phone,
    final int? partySize,
    final DateTime? expectedAt,
    final String? status,
    final String? zoneId,
    final String? tableId,
    final String? notes,
    final String? memberId,
  }) = _$PatchReservationDtoImpl;

  factory _PatchReservationDto.fromJson(Map<String, dynamic> json) =
      _$PatchReservationDtoImpl.fromJson;

  @override
  String? get name;
  @override
  String? get phone;
  @override
  int? get partySize;
  @override
  DateTime? get expectedAt;
  @override
  String? get status;
  @override
  String? get zoneId;
  @override
  String? get tableId;
  @override
  String? get notes;
  @override
  String? get memberId;

  /// Create a copy of PatchReservationDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PatchReservationDtoImplCopyWith<_$PatchReservationDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
