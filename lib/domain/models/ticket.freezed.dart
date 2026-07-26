// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Ticket {
  String get id => throw _privateConstructorUsedError;

  /// The [[Visit]] this line belongs to — used to resolve a table-less
  /// (takeaway) line's label via the visit. See ADR-0024 / ADR-0026.
  String? get visitId => throw _privateConstructorUsedError;

  /// The table this line was fired from (empty for takeaway). The live-ticket
  /// cache keys groups by [[visitId]], so map-flattening consumers read the
  /// table id here rather than from the (now visit-keyed) map key. ADR-0034.
  String get tableId => throw _privateConstructorUsedError;
  String get itemId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get variantName => throw _privateConstructorUsedError;
  CourseId get course => throw _privateConstructorUsedError;
  int get qty => throw _privateConstructorUsedError;
  List<TicketModifier> get modifiers => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  int get price => throw _privateConstructorUsedError;
  TicketStatus get status => throw _privateConstructorUsedError;
  String get sentAt => throw _privateConstructorUsedError;
  DateTime get sentAtTime => throw _privateConstructorUsedError;

  /// When the kitchen started owning this line — stamped on the `held → sent`
  /// fire, null on a normal send. The prep clock runs from
  /// `firedAtTime ?? sentAtTime`, so a held course is not born overdue.
  /// See [kitchenClockStart]. ADR-0043.
  DateTime? get firedAtTime => throw _privateConstructorUsedError;

  /// First entry into `ready` — the pass clock starts here (ADR-0013).
  DateTime? get readyAtTime => throw _privateConstructorUsedError;

  /// Most recent entry into `served`.
  DateTime? get servedAtTime => throw _privateConstructorUsedError;
  String? get voidReason => throw _privateConstructorUsedError;
  String? get voidReasonCode => throw _privateConstructorUsedError;
  String? get voidApprovedBy => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  String? get voidedBy => throw _privateConstructorUsedError;

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TicketCopyWith<Ticket> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TicketCopyWith<$Res> {
  factory $TicketCopyWith(Ticket value, $Res Function(Ticket) then) =
      _$TicketCopyWithImpl<$Res, Ticket>;
  @useResult
  $Res call({
    String id,
    String? visitId,
    String tableId,
    String itemId,
    String name,
    String variantName,
    CourseId course,
    int qty,
    List<TicketModifier> modifiers,
    String? note,
    int price,
    TicketStatus status,
    String sentAt,
    DateTime sentAtTime,
    DateTime? firedAtTime,
    DateTime? readyAtTime,
    DateTime? servedAtTime,
    String? voidReason,
    String? voidReasonCode,
    String? voidApprovedBy,
    String? createdBy,
    String? voidedBy,
  });
}

/// @nodoc
class _$TicketCopyWithImpl<$Res, $Val extends Ticket>
    implements $TicketCopyWith<$Res> {
  _$TicketCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? visitId = freezed,
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
    Object? sentAtTime = null,
    Object? firedAtTime = freezed,
    Object? readyAtTime = freezed,
    Object? servedAtTime = freezed,
    Object? voidReason = freezed,
    Object? voidReasonCode = freezed,
    Object? voidApprovedBy = freezed,
    Object? createdBy = freezed,
    Object? voidedBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            visitId: freezed == visitId
                ? _value.visitId
                : visitId // ignore: cast_nullable_to_non_nullable
                      as String?,
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
                      as CourseId,
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
            modifiers: null == modifiers
                ? _value.modifiers
                : modifiers // ignore: cast_nullable_to_non_nullable
                      as List<TicketModifier>,
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
                      as TicketStatus,
            sentAt: null == sentAt
                ? _value.sentAt
                : sentAt // ignore: cast_nullable_to_non_nullable
                      as String,
            sentAtTime: null == sentAtTime
                ? _value.sentAtTime
                : sentAtTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            firedAtTime: freezed == firedAtTime
                ? _value.firedAtTime
                : firedAtTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            readyAtTime: freezed == readyAtTime
                ? _value.readyAtTime
                : readyAtTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            servedAtTime: freezed == servedAtTime
                ? _value.servedAtTime
                : servedAtTime // ignore: cast_nullable_to_non_nullable
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
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            voidedBy: freezed == voidedBy
                ? _value.voidedBy
                : voidedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TicketImplCopyWith<$Res> implements $TicketCopyWith<$Res> {
  factory _$$TicketImplCopyWith(
    _$TicketImpl value,
    $Res Function(_$TicketImpl) then,
  ) = __$$TicketImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? visitId,
    String tableId,
    String itemId,
    String name,
    String variantName,
    CourseId course,
    int qty,
    List<TicketModifier> modifiers,
    String? note,
    int price,
    TicketStatus status,
    String sentAt,
    DateTime sentAtTime,
    DateTime? firedAtTime,
    DateTime? readyAtTime,
    DateTime? servedAtTime,
    String? voidReason,
    String? voidReasonCode,
    String? voidApprovedBy,
    String? createdBy,
    String? voidedBy,
  });
}

/// @nodoc
class __$$TicketImplCopyWithImpl<$Res>
    extends _$TicketCopyWithImpl<$Res, _$TicketImpl>
    implements _$$TicketImplCopyWith<$Res> {
  __$$TicketImplCopyWithImpl(
    _$TicketImpl _value,
    $Res Function(_$TicketImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? visitId = freezed,
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
    Object? sentAtTime = null,
    Object? firedAtTime = freezed,
    Object? readyAtTime = freezed,
    Object? servedAtTime = freezed,
    Object? voidReason = freezed,
    Object? voidReasonCode = freezed,
    Object? voidApprovedBy = freezed,
    Object? createdBy = freezed,
    Object? voidedBy = freezed,
  }) {
    return _then(
      _$TicketImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        visitId: freezed == visitId
            ? _value.visitId
            : visitId // ignore: cast_nullable_to_non_nullable
                  as String?,
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
                  as CourseId,
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
        modifiers: null == modifiers
            ? _value._modifiers
            : modifiers // ignore: cast_nullable_to_non_nullable
                  as List<TicketModifier>,
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
                  as TicketStatus,
        sentAt: null == sentAt
            ? _value.sentAt
            : sentAt // ignore: cast_nullable_to_non_nullable
                  as String,
        sentAtTime: null == sentAtTime
            ? _value.sentAtTime
            : sentAtTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        firedAtTime: freezed == firedAtTime
            ? _value.firedAtTime
            : firedAtTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        readyAtTime: freezed == readyAtTime
            ? _value.readyAtTime
            : readyAtTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        servedAtTime: freezed == servedAtTime
            ? _value.servedAtTime
            : servedAtTime // ignore: cast_nullable_to_non_nullable
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
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        voidedBy: freezed == voidedBy
            ? _value.voidedBy
            : voidedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$TicketImpl extends _Ticket {
  const _$TicketImpl({
    required this.id,
    this.visitId,
    this.tableId = '',
    required this.itemId,
    required this.name,
    this.variantName = '',
    required this.course,
    this.qty = 1,
    final List<TicketModifier> modifiers = const <TicketModifier>[],
    this.note,
    required this.price,
    required this.status,
    required this.sentAt,
    required this.sentAtTime,
    this.firedAtTime,
    this.readyAtTime,
    this.servedAtTime,
    this.voidReason,
    this.voidReasonCode,
    this.voidApprovedBy,
    this.createdBy,
    this.voidedBy,
  }) : _modifiers = modifiers,
       super._();

  @override
  final String id;

  /// The [[Visit]] this line belongs to — used to resolve a table-less
  /// (takeaway) line's label via the visit. See ADR-0024 / ADR-0026.
  @override
  final String? visitId;

  /// The table this line was fired from (empty for takeaway). The live-ticket
  /// cache keys groups by [[visitId]], so map-flattening consumers read the
  /// table id here rather than from the (now visit-keyed) map key. ADR-0034.
  @override
  @JsonKey()
  final String tableId;
  @override
  final String itemId;
  @override
  final String name;
  @override
  @JsonKey()
  final String variantName;
  @override
  final CourseId course;
  @override
  @JsonKey()
  final int qty;
  final List<TicketModifier> _modifiers;
  @override
  @JsonKey()
  List<TicketModifier> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @override
  final String? note;
  @override
  final int price;
  @override
  final TicketStatus status;
  @override
  final String sentAt;
  @override
  final DateTime sentAtTime;

  /// When the kitchen started owning this line — stamped on the `held → sent`
  /// fire, null on a normal send. The prep clock runs from
  /// `firedAtTime ?? sentAtTime`, so a held course is not born overdue.
  /// See [kitchenClockStart]. ADR-0043.
  @override
  final DateTime? firedAtTime;

  /// First entry into `ready` — the pass clock starts here (ADR-0013).
  @override
  final DateTime? readyAtTime;

  /// Most recent entry into `served`.
  @override
  final DateTime? servedAtTime;
  @override
  final String? voidReason;
  @override
  final String? voidReasonCode;
  @override
  final String? voidApprovedBy;
  @override
  final String? createdBy;
  @override
  final String? voidedBy;

  @override
  String toString() {
    return 'Ticket(id: $id, visitId: $visitId, tableId: $tableId, itemId: $itemId, name: $name, variantName: $variantName, course: $course, qty: $qty, modifiers: $modifiers, note: $note, price: $price, status: $status, sentAt: $sentAt, sentAtTime: $sentAtTime, firedAtTime: $firedAtTime, readyAtTime: $readyAtTime, servedAtTime: $servedAtTime, voidReason: $voidReason, voidReasonCode: $voidReasonCode, voidApprovedBy: $voidApprovedBy, createdBy: $createdBy, voidedBy: $voidedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TicketImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.visitId, visitId) || other.visitId == visitId) &&
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
            (identical(other.sentAtTime, sentAtTime) ||
                other.sentAtTime == sentAtTime) &&
            (identical(other.firedAtTime, firedAtTime) ||
                other.firedAtTime == firedAtTime) &&
            (identical(other.readyAtTime, readyAtTime) ||
                other.readyAtTime == readyAtTime) &&
            (identical(other.servedAtTime, servedAtTime) ||
                other.servedAtTime == servedAtTime) &&
            (identical(other.voidReason, voidReason) ||
                other.voidReason == voidReason) &&
            (identical(other.voidReasonCode, voidReasonCode) ||
                other.voidReasonCode == voidReasonCode) &&
            (identical(other.voidApprovedBy, voidApprovedBy) ||
                other.voidApprovedBy == voidApprovedBy) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.voidedBy, voidedBy) ||
                other.voidedBy == voidedBy));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    visitId,
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
    sentAtTime,
    firedAtTime,
    readyAtTime,
    servedAtTime,
    voidReason,
    voidReasonCode,
    voidApprovedBy,
    createdBy,
    voidedBy,
  ]);

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TicketImplCopyWith<_$TicketImpl> get copyWith =>
      __$$TicketImplCopyWithImpl<_$TicketImpl>(this, _$identity);
}

abstract class _Ticket extends Ticket {
  const factory _Ticket({
    required final String id,
    final String? visitId,
    final String tableId,
    required final String itemId,
    required final String name,
    final String variantName,
    required final CourseId course,
    final int qty,
    final List<TicketModifier> modifiers,
    final String? note,
    required final int price,
    required final TicketStatus status,
    required final String sentAt,
    required final DateTime sentAtTime,
    final DateTime? firedAtTime,
    final DateTime? readyAtTime,
    final DateTime? servedAtTime,
    final String? voidReason,
    final String? voidReasonCode,
    final String? voidApprovedBy,
    final String? createdBy,
    final String? voidedBy,
  }) = _$TicketImpl;
  const _Ticket._() : super._();

  @override
  String get id;

  /// The [[Visit]] this line belongs to — used to resolve a table-less
  /// (takeaway) line's label via the visit. See ADR-0024 / ADR-0026.
  @override
  String? get visitId;

  /// The table this line was fired from (empty for takeaway). The live-ticket
  /// cache keys groups by [[visitId]], so map-flattening consumers read the
  /// table id here rather than from the (now visit-keyed) map key. ADR-0034.
  @override
  String get tableId;
  @override
  String get itemId;
  @override
  String get name;
  @override
  String get variantName;
  @override
  CourseId get course;
  @override
  int get qty;
  @override
  List<TicketModifier> get modifiers;
  @override
  String? get note;
  @override
  int get price;
  @override
  TicketStatus get status;
  @override
  String get sentAt;
  @override
  DateTime get sentAtTime;

  /// When the kitchen started owning this line — stamped on the `held → sent`
  /// fire, null on a normal send. The prep clock runs from
  /// `firedAtTime ?? sentAtTime`, so a held course is not born overdue.
  /// See [kitchenClockStart]. ADR-0043.
  @override
  DateTime? get firedAtTime;

  /// First entry into `ready` — the pass clock starts here (ADR-0013).
  @override
  DateTime? get readyAtTime;

  /// Most recent entry into `served`.
  @override
  DateTime? get servedAtTime;
  @override
  String? get voidReason;
  @override
  String? get voidReasonCode;
  @override
  String? get voidApprovedBy;
  @override
  String? get createdBy;
  @override
  String? get voidedBy;

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TicketImplCopyWith<_$TicketImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
