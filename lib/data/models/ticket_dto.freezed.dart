// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TicketModifierDto _$TicketModifierDtoFromJson(Map<String, dynamic> json) {
  return _TicketModifierDto.fromJson(json);
}

/// @nodoc
mixin _$TicketModifierDto {
  String get groupId => throw _privateConstructorUsedError;
  String get optionId => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  int get priceDelta => throw _privateConstructorUsedError;

  /// Serializes this TicketModifierDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TicketModifierDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TicketModifierDtoCopyWith<TicketModifierDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TicketModifierDtoCopyWith<$Res> {
  factory $TicketModifierDtoCopyWith(
    TicketModifierDto value,
    $Res Function(TicketModifierDto) then,
  ) = _$TicketModifierDtoCopyWithImpl<$Res, TicketModifierDto>;
  @useResult
  $Res call({String groupId, String optionId, String label, int priceDelta});
}

/// @nodoc
class _$TicketModifierDtoCopyWithImpl<$Res, $Val extends TicketModifierDto>
    implements $TicketModifierDtoCopyWith<$Res> {
  _$TicketModifierDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TicketModifierDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? optionId = null,
    Object? label = null,
    Object? priceDelta = null,
  }) {
    return _then(
      _value.copyWith(
            groupId: null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as String,
            optionId: null == optionId
                ? _value.optionId
                : optionId // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            priceDelta: null == priceDelta
                ? _value.priceDelta
                : priceDelta // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TicketModifierDtoImplCopyWith<$Res>
    implements $TicketModifierDtoCopyWith<$Res> {
  factory _$$TicketModifierDtoImplCopyWith(
    _$TicketModifierDtoImpl value,
    $Res Function(_$TicketModifierDtoImpl) then,
  ) = __$$TicketModifierDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String groupId, String optionId, String label, int priceDelta});
}

/// @nodoc
class __$$TicketModifierDtoImplCopyWithImpl<$Res>
    extends _$TicketModifierDtoCopyWithImpl<$Res, _$TicketModifierDtoImpl>
    implements _$$TicketModifierDtoImplCopyWith<$Res> {
  __$$TicketModifierDtoImplCopyWithImpl(
    _$TicketModifierDtoImpl _value,
    $Res Function(_$TicketModifierDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TicketModifierDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? optionId = null,
    Object? label = null,
    Object? priceDelta = null,
  }) {
    return _then(
      _$TicketModifierDtoImpl(
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String,
        optionId: null == optionId
            ? _value.optionId
            : optionId // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        priceDelta: null == priceDelta
            ? _value.priceDelta
            : priceDelta // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TicketModifierDtoImpl implements _TicketModifierDto {
  const _$TicketModifierDtoImpl({
    this.groupId = '',
    this.optionId = '',
    this.label = '',
    this.priceDelta = 0,
  });

  factory _$TicketModifierDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TicketModifierDtoImplFromJson(json);

  @override
  @JsonKey()
  final String groupId;
  @override
  @JsonKey()
  final String optionId;
  @override
  @JsonKey()
  final String label;
  @override
  @JsonKey()
  final int priceDelta;

  @override
  String toString() {
    return 'TicketModifierDto(groupId: $groupId, optionId: $optionId, label: $label, priceDelta: $priceDelta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TicketModifierDtoImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.optionId, optionId) ||
                other.optionId == optionId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.priceDelta, priceDelta) ||
                other.priceDelta == priceDelta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, groupId, optionId, label, priceDelta);

  /// Create a copy of TicketModifierDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TicketModifierDtoImplCopyWith<_$TicketModifierDtoImpl> get copyWith =>
      __$$TicketModifierDtoImplCopyWithImpl<_$TicketModifierDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TicketModifierDtoImplToJson(this);
  }
}

abstract class _TicketModifierDto implements TicketModifierDto {
  const factory _TicketModifierDto({
    final String groupId,
    final String optionId,
    final String label,
    final int priceDelta,
  }) = _$TicketModifierDtoImpl;

  factory _TicketModifierDto.fromJson(Map<String, dynamic> json) =
      _$TicketModifierDtoImpl.fromJson;

  @override
  String get groupId;
  @override
  String get optionId;
  @override
  String get label;
  @override
  int get priceDelta;

  /// Create a copy of TicketModifierDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TicketModifierDtoImplCopyWith<_$TicketModifierDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TicketDto _$TicketDtoFromJson(Map<String, dynamic> json) {
  return _TicketDto.fromJson(json);
}

/// @nodoc
mixin _$TicketDto {
  String get id => throw _privateConstructorUsedError;
  String get tableId => throw _privateConstructorUsedError;
  String get itemId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get variantName => throw _privateConstructorUsedError;
  String get course => throw _privateConstructorUsedError;
  int get qty => throw _privateConstructorUsedError;
  List<TicketModifierDto> get modifiers => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  int get price => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get sentAt => throw _privateConstructorUsedError;
  DateTime? get readyAt => throw _privateConstructorUsedError;
  DateTime? get servedAt => throw _privateConstructorUsedError;
  String? get voidReason => throw _privateConstructorUsedError;
  String? get voidReasonCode => throw _privateConstructorUsedError;
  String? get voidApprovedBy => throw _privateConstructorUsedError;
  String? get createdByUserId => throw _privateConstructorUsedError;
  String? get voidedByUserId => throw _privateConstructorUsedError;

  /// Serializes this TicketDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TicketDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TicketDtoCopyWith<TicketDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TicketDtoCopyWith<$Res> {
  factory $TicketDtoCopyWith(TicketDto value, $Res Function(TicketDto) then) =
      _$TicketDtoCopyWithImpl<$Res, TicketDto>;
  @useResult
  $Res call({
    String id,
    String tableId,
    String itemId,
    String name,
    String variantName,
    String course,
    int qty,
    List<TicketModifierDto> modifiers,
    String? note,
    int price,
    String status,
    DateTime sentAt,
    DateTime? readyAt,
    DateTime? servedAt,
    String? voidReason,
    String? voidReasonCode,
    String? voidApprovedBy,
    String? createdByUserId,
    String? voidedByUserId,
  });
}

/// @nodoc
class _$TicketDtoCopyWithImpl<$Res, $Val extends TicketDto>
    implements $TicketDtoCopyWith<$Res> {
  _$TicketDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TicketDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tableId = null,
    Object? itemId = null,
    Object? name = null,
    Object? variantName = null,
    Object? course = null,
    Object? qty = null,
    Object? modifiers = null,
    Object? note = freezed,
    Object? price = null,
    Object? status = null,
    Object? sentAt = null,
    Object? readyAt = freezed,
    Object? servedAt = freezed,
    Object? voidReason = freezed,
    Object? voidReasonCode = freezed,
    Object? voidApprovedBy = freezed,
    Object? createdByUserId = freezed,
    Object? voidedByUserId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            tableId: null == tableId
                ? _value.tableId
                : tableId // ignore: cast_nullable_to_non_nullable
                      as String,
            itemId: null == itemId
                ? _value.itemId
                : itemId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            variantName: null == variantName
                ? _value.variantName
                : variantName // ignore: cast_nullable_to_non_nullable
                      as String,
            course: null == course
                ? _value.course
                : course // ignore: cast_nullable_to_non_nullable
                      as String,
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
            modifiers: null == modifiers
                ? _value.modifiers
                : modifiers // ignore: cast_nullable_to_non_nullable
                      as List<TicketModifierDto>,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            sentAt: null == sentAt
                ? _value.sentAt
                : sentAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            readyAt: freezed == readyAt
                ? _value.readyAt
                : readyAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            servedAt: freezed == servedAt
                ? _value.servedAt
                : servedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            voidReason: freezed == voidReason
                ? _value.voidReason
                : voidReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            voidReasonCode: freezed == voidReasonCode
                ? _value.voidReasonCode
                : voidReasonCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            voidApprovedBy: freezed == voidApprovedBy
                ? _value.voidApprovedBy
                : voidApprovedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdByUserId: freezed == createdByUserId
                ? _value.createdByUserId
                : createdByUserId // ignore: cast_nullable_to_non_nullable
                      as String?,
            voidedByUserId: freezed == voidedByUserId
                ? _value.voidedByUserId
                : voidedByUserId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TicketDtoImplCopyWith<$Res>
    implements $TicketDtoCopyWith<$Res> {
  factory _$$TicketDtoImplCopyWith(
    _$TicketDtoImpl value,
    $Res Function(_$TicketDtoImpl) then,
  ) = __$$TicketDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String tableId,
    String itemId,
    String name,
    String variantName,
    String course,
    int qty,
    List<TicketModifierDto> modifiers,
    String? note,
    int price,
    String status,
    DateTime sentAt,
    DateTime? readyAt,
    DateTime? servedAt,
    String? voidReason,
    String? voidReasonCode,
    String? voidApprovedBy,
    String? createdByUserId,
    String? voidedByUserId,
  });
}

/// @nodoc
class __$$TicketDtoImplCopyWithImpl<$Res>
    extends _$TicketDtoCopyWithImpl<$Res, _$TicketDtoImpl>
    implements _$$TicketDtoImplCopyWith<$Res> {
  __$$TicketDtoImplCopyWithImpl(
    _$TicketDtoImpl _value,
    $Res Function(_$TicketDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TicketDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tableId = null,
    Object? itemId = null,
    Object? name = null,
    Object? variantName = null,
    Object? course = null,
    Object? qty = null,
    Object? modifiers = null,
    Object? note = freezed,
    Object? price = null,
    Object? status = null,
    Object? sentAt = null,
    Object? readyAt = freezed,
    Object? servedAt = freezed,
    Object? voidReason = freezed,
    Object? voidReasonCode = freezed,
    Object? voidApprovedBy = freezed,
    Object? createdByUserId = freezed,
    Object? voidedByUserId = freezed,
  }) {
    return _then(
      _$TicketDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        tableId: null == tableId
            ? _value.tableId
            : tableId // ignore: cast_nullable_to_non_nullable
                  as String,
        itemId: null == itemId
            ? _value.itemId
            : itemId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        variantName: null == variantName
            ? _value.variantName
            : variantName // ignore: cast_nullable_to_non_nullable
                  as String,
        course: null == course
            ? _value.course
            : course // ignore: cast_nullable_to_non_nullable
                  as String,
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
        modifiers: null == modifiers
            ? _value._modifiers
            : modifiers // ignore: cast_nullable_to_non_nullable
                  as List<TicketModifierDto>,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        sentAt: null == sentAt
            ? _value.sentAt
            : sentAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        readyAt: freezed == readyAt
            ? _value.readyAt
            : readyAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        servedAt: freezed == servedAt
            ? _value.servedAt
            : servedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        voidReason: freezed == voidReason
            ? _value.voidReason
            : voidReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        voidReasonCode: freezed == voidReasonCode
            ? _value.voidReasonCode
            : voidReasonCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        voidApprovedBy: freezed == voidApprovedBy
            ? _value.voidApprovedBy
            : voidApprovedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdByUserId: freezed == createdByUserId
            ? _value.createdByUserId
            : createdByUserId // ignore: cast_nullable_to_non_nullable
                  as String?,
        voidedByUserId: freezed == voidedByUserId
            ? _value.voidedByUserId
            : voidedByUserId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TicketDtoImpl implements _TicketDto {
  const _$TicketDtoImpl({
    required this.id,
    required this.tableId,
    required this.itemId,
    required this.name,
    this.variantName = '',
    required this.course,
    this.qty = 1,
    final List<TicketModifierDto> modifiers = const <TicketModifierDto>[],
    this.note,
    required this.price,
    required this.status,
    required this.sentAt,
    this.readyAt,
    this.servedAt,
    this.voidReason,
    this.voidReasonCode,
    this.voidApprovedBy,
    this.createdByUserId,
    this.voidedByUserId,
  }) : _modifiers = modifiers;

  factory _$TicketDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TicketDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String tableId;
  @override
  final String itemId;
  @override
  final String name;
  @override
  @JsonKey()
  final String variantName;
  @override
  final String course;
  @override
  @JsonKey()
  final int qty;
  final List<TicketModifierDto> _modifiers;
  @override
  @JsonKey()
  List<TicketModifierDto> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @override
  final String? note;
  @override
  final int price;
  @override
  final String status;
  @override
  final DateTime sentAt;
  @override
  final DateTime? readyAt;
  @override
  final DateTime? servedAt;
  @override
  final String? voidReason;
  @override
  final String? voidReasonCode;
  @override
  final String? voidApprovedBy;
  @override
  final String? createdByUserId;
  @override
  final String? voidedByUserId;

  @override
  String toString() {
    return 'TicketDto(id: $id, tableId: $tableId, itemId: $itemId, name: $name, variantName: $variantName, course: $course, qty: $qty, modifiers: $modifiers, note: $note, price: $price, status: $status, sentAt: $sentAt, readyAt: $readyAt, servedAt: $servedAt, voidReason: $voidReason, voidReasonCode: $voidReasonCode, voidApprovedBy: $voidApprovedBy, createdByUserId: $createdByUserId, voidedByUserId: $voidedByUserId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TicketDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.variantName, variantName) ||
                other.variantName == variantName) &&
            (identical(other.course, course) || other.course == course) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            const DeepCollectionEquality().equals(
              other._modifiers,
              _modifiers,
            ) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt) &&
            (identical(other.readyAt, readyAt) || other.readyAt == readyAt) &&
            (identical(other.servedAt, servedAt) ||
                other.servedAt == servedAt) &&
            (identical(other.voidReason, voidReason) ||
                other.voidReason == voidReason) &&
            (identical(other.voidReasonCode, voidReasonCode) ||
                other.voidReasonCode == voidReasonCode) &&
            (identical(other.voidApprovedBy, voidApprovedBy) ||
                other.voidApprovedBy == voidApprovedBy) &&
            (identical(other.createdByUserId, createdByUserId) ||
                other.createdByUserId == createdByUserId) &&
            (identical(other.voidedByUserId, voidedByUserId) ||
                other.voidedByUserId == voidedByUserId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    tableId,
    itemId,
    name,
    variantName,
    course,
    qty,
    const DeepCollectionEquality().hash(_modifiers),
    note,
    price,
    status,
    sentAt,
    readyAt,
    servedAt,
    voidReason,
    voidReasonCode,
    voidApprovedBy,
    createdByUserId,
    voidedByUserId,
  ]);

  /// Create a copy of TicketDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TicketDtoImplCopyWith<_$TicketDtoImpl> get copyWith =>
      __$$TicketDtoImplCopyWithImpl<_$TicketDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TicketDtoImplToJson(this);
  }
}

abstract class _TicketDto implements TicketDto {
  const factory _TicketDto({
    required final String id,
    required final String tableId,
    required final String itemId,
    required final String name,
    final String variantName,
    required final String course,
    final int qty,
    final List<TicketModifierDto> modifiers,
    final String? note,
    required final int price,
    required final String status,
    required final DateTime sentAt,
    final DateTime? readyAt,
    final DateTime? servedAt,
    final String? voidReason,
    final String? voidReasonCode,
    final String? voidApprovedBy,
    final String? createdByUserId,
    final String? voidedByUserId,
  }) = _$TicketDtoImpl;

  factory _TicketDto.fromJson(Map<String, dynamic> json) =
      _$TicketDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get tableId;
  @override
  String get itemId;
  @override
  String get name;
  @override
  String get variantName;
  @override
  String get course;
  @override
  int get qty;
  @override
  List<TicketModifierDto> get modifiers;
  @override
  String? get note;
  @override
  int get price;
  @override
  String get status;
  @override
  DateTime get sentAt;
  @override
  DateTime? get readyAt;
  @override
  DateTime? get servedAt;
  @override
  String? get voidReason;
  @override
  String? get voidReasonCode;
  @override
  String? get voidApprovedBy;
  @override
  String? get createdByUserId;
  @override
  String? get voidedByUserId;

  /// Create a copy of TicketDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TicketDtoImplCopyWith<_$TicketDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TicketTransitionRequestDto _$TicketTransitionRequestDtoFromJson(
  Map<String, dynamic> json,
) {
  return _TicketTransitionRequestDto.fromJson(json);
}

/// @nodoc
mixin _$TicketTransitionRequestDto {
  String get status => throw _privateConstructorUsedError;
  String? get voidReason => throw _privateConstructorUsedError;
  String? get voidReasonCode => throw _privateConstructorUsedError;

  /// Serializes this TicketTransitionRequestDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TicketTransitionRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TicketTransitionRequestDtoCopyWith<TicketTransitionRequestDto>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TicketTransitionRequestDtoCopyWith<$Res> {
  factory $TicketTransitionRequestDtoCopyWith(
    TicketTransitionRequestDto value,
    $Res Function(TicketTransitionRequestDto) then,
  ) =
      _$TicketTransitionRequestDtoCopyWithImpl<
        $Res,
        TicketTransitionRequestDto
      >;
  @useResult
  $Res call({String status, String? voidReason, String? voidReasonCode});
}

/// @nodoc
class _$TicketTransitionRequestDtoCopyWithImpl<
  $Res,
  $Val extends TicketTransitionRequestDto
>
    implements $TicketTransitionRequestDtoCopyWith<$Res> {
  _$TicketTransitionRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TicketTransitionRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? voidReason = freezed,
    Object? voidReasonCode = freezed,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            voidReason: freezed == voidReason
                ? _value.voidReason
                : voidReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            voidReasonCode: freezed == voidReasonCode
                ? _value.voidReasonCode
                : voidReasonCode // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TicketTransitionRequestDtoImplCopyWith<$Res>
    implements $TicketTransitionRequestDtoCopyWith<$Res> {
  factory _$$TicketTransitionRequestDtoImplCopyWith(
    _$TicketTransitionRequestDtoImpl value,
    $Res Function(_$TicketTransitionRequestDtoImpl) then,
  ) = __$$TicketTransitionRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String status, String? voidReason, String? voidReasonCode});
}

/// @nodoc
class __$$TicketTransitionRequestDtoImplCopyWithImpl<$Res>
    extends
        _$TicketTransitionRequestDtoCopyWithImpl<
          $Res,
          _$TicketTransitionRequestDtoImpl
        >
    implements _$$TicketTransitionRequestDtoImplCopyWith<$Res> {
  __$$TicketTransitionRequestDtoImplCopyWithImpl(
    _$TicketTransitionRequestDtoImpl _value,
    $Res Function(_$TicketTransitionRequestDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TicketTransitionRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? voidReason = freezed,
    Object? voidReasonCode = freezed,
  }) {
    return _then(
      _$TicketTransitionRequestDtoImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        voidReason: freezed == voidReason
            ? _value.voidReason
            : voidReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        voidReasonCode: freezed == voidReasonCode
            ? _value.voidReasonCode
            : voidReasonCode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TicketTransitionRequestDtoImpl implements _TicketTransitionRequestDto {
  const _$TicketTransitionRequestDtoImpl({
    required this.status,
    this.voidReason,
    this.voidReasonCode,
  });

  factory _$TicketTransitionRequestDtoImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$TicketTransitionRequestDtoImplFromJson(json);

  @override
  final String status;
  @override
  final String? voidReason;
  @override
  final String? voidReasonCode;

  @override
  String toString() {
    return 'TicketTransitionRequestDto(status: $status, voidReason: $voidReason, voidReasonCode: $voidReasonCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TicketTransitionRequestDtoImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.voidReason, voidReason) ||
                other.voidReason == voidReason) &&
            (identical(other.voidReasonCode, voidReasonCode) ||
                other.voidReasonCode == voidReasonCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, status, voidReason, voidReasonCode);

  /// Create a copy of TicketTransitionRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TicketTransitionRequestDtoImplCopyWith<_$TicketTransitionRequestDtoImpl>
  get copyWith =>
      __$$TicketTransitionRequestDtoImplCopyWithImpl<
        _$TicketTransitionRequestDtoImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TicketTransitionRequestDtoImplToJson(this);
  }
}

abstract class _TicketTransitionRequestDto
    implements TicketTransitionRequestDto {
  const factory _TicketTransitionRequestDto({
    required final String status,
    final String? voidReason,
    final String? voidReasonCode,
  }) = _$TicketTransitionRequestDtoImpl;

  factory _TicketTransitionRequestDto.fromJson(Map<String, dynamic> json) =
      _$TicketTransitionRequestDtoImpl.fromJson;

  @override
  String get status;
  @override
  String? get voidReason;
  @override
  String? get voidReasonCode;

  /// Create a copy of TicketTransitionRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TicketTransitionRequestDtoImplCopyWith<_$TicketTransitionRequestDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
