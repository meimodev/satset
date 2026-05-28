// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'table_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TableDto _$TableDtoFromJson(Map<String, dynamic> json) {
  return _TableDto.fromJson(json);
}

/// @nodoc
mixin _$TableDto {
  String get id => throw _privateConstructorUsedError;
  String get zoneId => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;
  int get pax => throw _privateConstructorUsedError;
  int get capacity => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int get openAmount => throw _privateConstructorUsedError;
  int get readyCount => throw _privateConstructorUsedError;
  String? get lastActorId => throw _privateConstructorUsedError;
  String? get lockedBy => throw _privateConstructorUsedError;
  String? get lockedByName => throw _privateConstructorUsedError;
  DateTime? get lockedAt => throw _privateConstructorUsedError;
  DateTime? get lockExpiresAt => throw _privateConstructorUsedError;
  DateTime? get openedAt => throw _privateConstructorUsedError;
  String? get guestName => throw _privateConstructorUsedError;
  String? get guestNotes => throw _privateConstructorUsedError;
  String? get reservationId => throw _privateConstructorUsedError;

  /// Serializes this TableDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TableDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TableDtoCopyWith<TableDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TableDtoCopyWith<$Res> {
  factory $TableDtoCopyWith(TableDto value, $Res Function(TableDto) then) =
      _$TableDtoCopyWithImpl<$Res, TableDto>;
  @useResult
  $Res call({
    String id,
    String zoneId,
    String? label,
    int pax,
    int capacity,
    bool active,
    String status,
    int openAmount,
    int readyCount,
    String? lastActorId,
    String? lockedBy,
    String? lockedByName,
    DateTime? lockedAt,
    DateTime? lockExpiresAt,
    DateTime? openedAt,
    String? guestName,
    String? guestNotes,
    String? reservationId,
  });
}

/// @nodoc
class _$TableDtoCopyWithImpl<$Res, $Val extends TableDto>
    implements $TableDtoCopyWith<$Res> {
  _$TableDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TableDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? zoneId = null,
    Object? label = freezed,
    Object? pax = null,
    Object? capacity = null,
    Object? active = null,
    Object? status = null,
    Object? openAmount = null,
    Object? readyCount = null,
    Object? lastActorId = freezed,
    Object? lockedBy = freezed,
    Object? lockedByName = freezed,
    Object? lockedAt = freezed,
    Object? lockExpiresAt = freezed,
    Object? openedAt = freezed,
    Object? guestName = freezed,
    Object? guestNotes = freezed,
    Object? reservationId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            zoneId: null == zoneId
                ? _value.zoneId
                : zoneId // ignore: cast_nullable_to_non_nullable
                      as String,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
            pax: null == pax
                ? _value.pax
                : pax // ignore: cast_nullable_to_non_nullable
                      as int,
            capacity: null == capacity
                ? _value.capacity
                : capacity // ignore: cast_nullable_to_non_nullable
                      as int,
            active: null == active
                ? _value.active
                : active // ignore: cast_nullable_to_non_nullable
                      as bool,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            openAmount: null == openAmount
                ? _value.openAmount
                : openAmount // ignore: cast_nullable_to_non_nullable
                      as int,
            readyCount: null == readyCount
                ? _value.readyCount
                : readyCount // ignore: cast_nullable_to_non_nullable
                      as int,
            lastActorId: freezed == lastActorId
                ? _value.lastActorId
                : lastActorId // ignore: cast_nullable_to_non_nullable
                      as String?,
            lockedBy: freezed == lockedBy
                ? _value.lockedBy
                : lockedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            lockedByName: freezed == lockedByName
                ? _value.lockedByName
                : lockedByName // ignore: cast_nullable_to_non_nullable
                      as String?,
            lockedAt: freezed == lockedAt
                ? _value.lockedAt
                : lockedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lockExpiresAt: freezed == lockExpiresAt
                ? _value.lockExpiresAt
                : lockExpiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            openedAt: freezed == openedAt
                ? _value.openedAt
                : openedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            guestName: freezed == guestName
                ? _value.guestName
                : guestName // ignore: cast_nullable_to_non_nullable
                      as String?,
            guestNotes: freezed == guestNotes
                ? _value.guestNotes
                : guestNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            reservationId: freezed == reservationId
                ? _value.reservationId
                : reservationId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TableDtoImplCopyWith<$Res>
    implements $TableDtoCopyWith<$Res> {
  factory _$$TableDtoImplCopyWith(
    _$TableDtoImpl value,
    $Res Function(_$TableDtoImpl) then,
  ) = __$$TableDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String zoneId,
    String? label,
    int pax,
    int capacity,
    bool active,
    String status,
    int openAmount,
    int readyCount,
    String? lastActorId,
    String? lockedBy,
    String? lockedByName,
    DateTime? lockedAt,
    DateTime? lockExpiresAt,
    DateTime? openedAt,
    String? guestName,
    String? guestNotes,
    String? reservationId,
  });
}

/// @nodoc
class __$$TableDtoImplCopyWithImpl<$Res>
    extends _$TableDtoCopyWithImpl<$Res, _$TableDtoImpl>
    implements _$$TableDtoImplCopyWith<$Res> {
  __$$TableDtoImplCopyWithImpl(
    _$TableDtoImpl _value,
    $Res Function(_$TableDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TableDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? zoneId = null,
    Object? label = freezed,
    Object? pax = null,
    Object? capacity = null,
    Object? active = null,
    Object? status = null,
    Object? openAmount = null,
    Object? readyCount = null,
    Object? lastActorId = freezed,
    Object? lockedBy = freezed,
    Object? lockedByName = freezed,
    Object? lockedAt = freezed,
    Object? lockExpiresAt = freezed,
    Object? openedAt = freezed,
    Object? guestName = freezed,
    Object? guestNotes = freezed,
    Object? reservationId = freezed,
  }) {
    return _then(
      _$TableDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        zoneId: null == zoneId
            ? _value.zoneId
            : zoneId // ignore: cast_nullable_to_non_nullable
                  as String,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        pax: null == pax
            ? _value.pax
            : pax // ignore: cast_nullable_to_non_nullable
                  as int,
        capacity: null == capacity
            ? _value.capacity
            : capacity // ignore: cast_nullable_to_non_nullable
                  as int,
        active: null == active
            ? _value.active
            : active // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        openAmount: null == openAmount
            ? _value.openAmount
            : openAmount // ignore: cast_nullable_to_non_nullable
                  as int,
        readyCount: null == readyCount
            ? _value.readyCount
            : readyCount // ignore: cast_nullable_to_non_nullable
                  as int,
        lastActorId: freezed == lastActorId
            ? _value.lastActorId
            : lastActorId // ignore: cast_nullable_to_non_nullable
                  as String?,
        lockedBy: freezed == lockedBy
            ? _value.lockedBy
            : lockedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        lockedByName: freezed == lockedByName
            ? _value.lockedByName
            : lockedByName // ignore: cast_nullable_to_non_nullable
                  as String?,
        lockedAt: freezed == lockedAt
            ? _value.lockedAt
            : lockedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lockExpiresAt: freezed == lockExpiresAt
            ? _value.lockExpiresAt
            : lockExpiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        openedAt: freezed == openedAt
            ? _value.openedAt
            : openedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        guestName: freezed == guestName
            ? _value.guestName
            : guestName // ignore: cast_nullable_to_non_nullable
                  as String?,
        guestNotes: freezed == guestNotes
            ? _value.guestNotes
            : guestNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        reservationId: freezed == reservationId
            ? _value.reservationId
            : reservationId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TableDtoImpl implements _TableDto {
  const _$TableDtoImpl({
    required this.id,
    required this.zoneId,
    required this.label,
    this.pax = 0,
    this.capacity = 2,
    this.active = true,
    this.status = 'available',
    this.openAmount = 0,
    this.readyCount = 0,
    this.lastActorId,
    this.lockedBy,
    this.lockedByName,
    this.lockedAt,
    this.lockExpiresAt,
    this.openedAt,
    this.guestName,
    this.guestNotes,
    this.reservationId,
  });

  factory _$TableDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TableDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String zoneId;
  @override
  final String? label;
  @override
  @JsonKey()
  final int pax;
  @override
  @JsonKey()
  final int capacity;
  @override
  @JsonKey()
  final bool active;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final int openAmount;
  @override
  @JsonKey()
  final int readyCount;
  @override
  final String? lastActorId;
  @override
  final String? lockedBy;
  @override
  final String? lockedByName;
  @override
  final DateTime? lockedAt;
  @override
  final DateTime? lockExpiresAt;
  @override
  final DateTime? openedAt;
  @override
  final String? guestName;
  @override
  final String? guestNotes;
  @override
  final String? reservationId;

  @override
  String toString() {
    return 'TableDto(id: $id, zoneId: $zoneId, label: $label, pax: $pax, capacity: $capacity, active: $active, status: $status, openAmount: $openAmount, readyCount: $readyCount, lastActorId: $lastActorId, lockedBy: $lockedBy, lockedByName: $lockedByName, lockedAt: $lockedAt, lockExpiresAt: $lockExpiresAt, openedAt: $openedAt, guestName: $guestName, guestNotes: $guestNotes, reservationId: $reservationId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TableDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.zoneId, zoneId) || other.zoneId == zoneId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.pax, pax) || other.pax == pax) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.openAmount, openAmount) ||
                other.openAmount == openAmount) &&
            (identical(other.readyCount, readyCount) ||
                other.readyCount == readyCount) &&
            (identical(other.lastActorId, lastActorId) ||
                other.lastActorId == lastActorId) &&
            (identical(other.lockedBy, lockedBy) ||
                other.lockedBy == lockedBy) &&
            (identical(other.lockedByName, lockedByName) ||
                other.lockedByName == lockedByName) &&
            (identical(other.lockedAt, lockedAt) ||
                other.lockedAt == lockedAt) &&
            (identical(other.lockExpiresAt, lockExpiresAt) ||
                other.lockExpiresAt == lockExpiresAt) &&
            (identical(other.openedAt, openedAt) ||
                other.openedAt == openedAt) &&
            (identical(other.guestName, guestName) ||
                other.guestName == guestName) &&
            (identical(other.guestNotes, guestNotes) ||
                other.guestNotes == guestNotes) &&
            (identical(other.reservationId, reservationId) ||
                other.reservationId == reservationId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    zoneId,
    label,
    pax,
    capacity,
    active,
    status,
    openAmount,
    readyCount,
    lastActorId,
    lockedBy,
    lockedByName,
    lockedAt,
    lockExpiresAt,
    openedAt,
    guestName,
    guestNotes,
    reservationId,
  );

  /// Create a copy of TableDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TableDtoImplCopyWith<_$TableDtoImpl> get copyWith =>
      __$$TableDtoImplCopyWithImpl<_$TableDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TableDtoImplToJson(this);
  }
}

abstract class _TableDto implements TableDto {
  const factory _TableDto({
    required final String id,
    required final String zoneId,
    required final String? label,
    final int pax,
    final int capacity,
    final bool active,
    final String status,
    final int openAmount,
    final int readyCount,
    final String? lastActorId,
    final String? lockedBy,
    final String? lockedByName,
    final DateTime? lockedAt,
    final DateTime? lockExpiresAt,
    final DateTime? openedAt,
    final String? guestName,
    final String? guestNotes,
    final String? reservationId,
  }) = _$TableDtoImpl;

  factory _TableDto.fromJson(Map<String, dynamic> json) =
      _$TableDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get zoneId;
  @override
  String? get label;
  @override
  int get pax;
  @override
  int get capacity;
  @override
  bool get active;
  @override
  String get status;
  @override
  int get openAmount;
  @override
  int get readyCount;
  @override
  String? get lastActorId;
  @override
  String? get lockedBy;
  @override
  String? get lockedByName;
  @override
  DateTime? get lockedAt;
  @override
  DateTime? get lockExpiresAt;
  @override
  DateTime? get openedAt;
  @override
  String? get guestName;
  @override
  String? get guestNotes;
  @override
  String? get reservationId;

  /// Create a copy of TableDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TableDtoImplCopyWith<_$TableDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UpdateTablePaxDto _$UpdateTablePaxDtoFromJson(Map<String, dynamic> json) {
  return _UpdateTablePaxDto.fromJson(json);
}

/// @nodoc
mixin _$UpdateTablePaxDto {
  int get pax => throw _privateConstructorUsedError;

  /// Serializes this UpdateTablePaxDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpdateTablePaxDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpdateTablePaxDtoCopyWith<UpdateTablePaxDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateTablePaxDtoCopyWith<$Res> {
  factory $UpdateTablePaxDtoCopyWith(
    UpdateTablePaxDto value,
    $Res Function(UpdateTablePaxDto) then,
  ) = _$UpdateTablePaxDtoCopyWithImpl<$Res, UpdateTablePaxDto>;
  @useResult
  $Res call({int pax});
}

/// @nodoc
class _$UpdateTablePaxDtoCopyWithImpl<$Res, $Val extends UpdateTablePaxDto>
    implements $UpdateTablePaxDtoCopyWith<$Res> {
  _$UpdateTablePaxDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpdateTablePaxDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pax = null}) {
    return _then(
      _value.copyWith(
            pax: null == pax
                ? _value.pax
                : pax // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UpdateTablePaxDtoImplCopyWith<$Res>
    implements $UpdateTablePaxDtoCopyWith<$Res> {
  factory _$$UpdateTablePaxDtoImplCopyWith(
    _$UpdateTablePaxDtoImpl value,
    $Res Function(_$UpdateTablePaxDtoImpl) then,
  ) = __$$UpdateTablePaxDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int pax});
}

/// @nodoc
class __$$UpdateTablePaxDtoImplCopyWithImpl<$Res>
    extends _$UpdateTablePaxDtoCopyWithImpl<$Res, _$UpdateTablePaxDtoImpl>
    implements _$$UpdateTablePaxDtoImplCopyWith<$Res> {
  __$$UpdateTablePaxDtoImplCopyWithImpl(
    _$UpdateTablePaxDtoImpl _value,
    $Res Function(_$UpdateTablePaxDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UpdateTablePaxDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pax = null}) {
    return _then(
      _$UpdateTablePaxDtoImpl(
        pax: null == pax
            ? _value.pax
            : pax // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateTablePaxDtoImpl implements _UpdateTablePaxDto {
  const _$UpdateTablePaxDtoImpl({required this.pax});

  factory _$UpdateTablePaxDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateTablePaxDtoImplFromJson(json);

  @override
  final int pax;

  @override
  String toString() {
    return 'UpdateTablePaxDto(pax: $pax)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateTablePaxDtoImpl &&
            (identical(other.pax, pax) || other.pax == pax));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pax);

  /// Create a copy of UpdateTablePaxDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateTablePaxDtoImplCopyWith<_$UpdateTablePaxDtoImpl> get copyWith =>
      __$$UpdateTablePaxDtoImplCopyWithImpl<_$UpdateTablePaxDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateTablePaxDtoImplToJson(this);
  }
}

abstract class _UpdateTablePaxDto implements UpdateTablePaxDto {
  const factory _UpdateTablePaxDto({required final int pax}) =
      _$UpdateTablePaxDtoImpl;

  factory _UpdateTablePaxDto.fromJson(Map<String, dynamic> json) =
      _$UpdateTablePaxDtoImpl.fromJson;

  @override
  int get pax;

  /// Create a copy of UpdateTablePaxDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateTablePaxDtoImplCopyWith<_$UpdateTablePaxDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UpdateTableHandlerDto _$UpdateTableHandlerDtoFromJson(
  Map<String, dynamic> json,
) {
  return _UpdateTableHandlerDto.fromJson(json);
}

/// @nodoc
mixin _$UpdateTableHandlerDto {
  String get userId => throw _privateConstructorUsedError;

  /// Serializes this UpdateTableHandlerDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpdateTableHandlerDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpdateTableHandlerDtoCopyWith<UpdateTableHandlerDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateTableHandlerDtoCopyWith<$Res> {
  factory $UpdateTableHandlerDtoCopyWith(
    UpdateTableHandlerDto value,
    $Res Function(UpdateTableHandlerDto) then,
  ) = _$UpdateTableHandlerDtoCopyWithImpl<$Res, UpdateTableHandlerDto>;
  @useResult
  $Res call({String userId});
}

/// @nodoc
class _$UpdateTableHandlerDtoCopyWithImpl<
  $Res,
  $Val extends UpdateTableHandlerDto
>
    implements $UpdateTableHandlerDtoCopyWith<$Res> {
  _$UpdateTableHandlerDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpdateTableHandlerDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userId = null}) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UpdateTableHandlerDtoImplCopyWith<$Res>
    implements $UpdateTableHandlerDtoCopyWith<$Res> {
  factory _$$UpdateTableHandlerDtoImplCopyWith(
    _$UpdateTableHandlerDtoImpl value,
    $Res Function(_$UpdateTableHandlerDtoImpl) then,
  ) = __$$UpdateTableHandlerDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String userId});
}

/// @nodoc
class __$$UpdateTableHandlerDtoImplCopyWithImpl<$Res>
    extends
        _$UpdateTableHandlerDtoCopyWithImpl<$Res, _$UpdateTableHandlerDtoImpl>
    implements _$$UpdateTableHandlerDtoImplCopyWith<$Res> {
  __$$UpdateTableHandlerDtoImplCopyWithImpl(
    _$UpdateTableHandlerDtoImpl _value,
    $Res Function(_$UpdateTableHandlerDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UpdateTableHandlerDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userId = null}) {
    return _then(
      _$UpdateTableHandlerDtoImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateTableHandlerDtoImpl implements _UpdateTableHandlerDto {
  const _$UpdateTableHandlerDtoImpl({required this.userId});

  factory _$UpdateTableHandlerDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateTableHandlerDtoImplFromJson(json);

  @override
  final String userId;

  @override
  String toString() {
    return 'UpdateTableHandlerDto(userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateTableHandlerDtoImpl &&
            (identical(other.userId, userId) || other.userId == userId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId);

  /// Create a copy of UpdateTableHandlerDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateTableHandlerDtoImplCopyWith<_$UpdateTableHandlerDtoImpl>
  get copyWith =>
      __$$UpdateTableHandlerDtoImplCopyWithImpl<_$UpdateTableHandlerDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateTableHandlerDtoImplToJson(this);
  }
}

abstract class _UpdateTableHandlerDto implements UpdateTableHandlerDto {
  const factory _UpdateTableHandlerDto({required final String userId}) =
      _$UpdateTableHandlerDtoImpl;

  factory _UpdateTableHandlerDto.fromJson(Map<String, dynamic> json) =
      _$UpdateTableHandlerDtoImpl.fromJson;

  @override
  String get userId;

  /// Create a copy of UpdateTableHandlerDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateTableHandlerDtoImplCopyWith<_$UpdateTableHandlerDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
