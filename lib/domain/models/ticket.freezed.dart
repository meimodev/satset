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
  String get itemId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get variantName => throw _privateConstructorUsedError;
  CourseId get course => throw _privateConstructorUsedError;
  Station get station => throw _privateConstructorUsedError;
  int get qty => throw _privateConstructorUsedError;
  List<String> get modifiers => throw _privateConstructorUsedError;
  String? get specialInstructions => throw _privateConstructorUsedError;
  int get price => throw _privateConstructorUsedError;
  TicketStatus get status => throw _privateConstructorUsedError;
  String get sentAt => throw _privateConstructorUsedError;
  String? get voidReason => throw _privateConstructorUsedError;
  String? get voidApprovedBy => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;

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
    String itemId,
    String name,
    String variantName,
    CourseId course,
    Station station,
    int qty,
    List<String> modifiers,
    String? specialInstructions,
    int price,
    TicketStatus status,
    String sentAt,
    String? voidReason,
    String? voidApprovedBy,
    String? createdBy,
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
    Object? itemId = null,
    Object? name = null,
    Object? variantName = null,
    Object? course = null,
    Object? station = null,
    Object? qty = null,
    Object? modifiers = null,
    Object? specialInstructions = freezed,
    Object? price = null,
    Object? status = null,
    Object? sentAt = null,
    Object? voidReason = freezed,
    Object? voidApprovedBy = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
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
            station: null == station
                ? _value.station
                : station // ignore: cast_nullable_to_non_nullable
                      as Station,
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
            modifiers: null == modifiers
                ? _value.modifiers
                : modifiers // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            specialInstructions: freezed == specialInstructions
                ? _value.specialInstructions
                : specialInstructions // ignore: cast_nullable_to_non_nullable
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
            voidReason: freezed == voidReason
                ? _value.voidReason
                : voidReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            voidApprovedBy: freezed == voidApprovedBy
                ? _value.voidApprovedBy
                : voidApprovedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
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
    String itemId,
    String name,
    String variantName,
    CourseId course,
    Station station,
    int qty,
    List<String> modifiers,
    String? specialInstructions,
    int price,
    TicketStatus status,
    String sentAt,
    String? voidReason,
    String? voidApprovedBy,
    String? createdBy,
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
    Object? itemId = null,
    Object? name = null,
    Object? variantName = null,
    Object? course = null,
    Object? station = null,
    Object? qty = null,
    Object? modifiers = null,
    Object? specialInstructions = freezed,
    Object? price = null,
    Object? status = null,
    Object? sentAt = null,
    Object? voidReason = freezed,
    Object? voidApprovedBy = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(
      _$TicketImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
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
        station: null == station
            ? _value.station
            : station // ignore: cast_nullable_to_non_nullable
                  as Station,
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
        modifiers: null == modifiers
            ? _value._modifiers
            : modifiers // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        specialInstructions: freezed == specialInstructions
            ? _value.specialInstructions
            : specialInstructions // ignore: cast_nullable_to_non_nullable
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
        voidReason: freezed == voidReason
            ? _value.voidReason
            : voidReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        voidApprovedBy: freezed == voidApprovedBy
            ? _value.voidApprovedBy
            : voidApprovedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$TicketImpl implements _Ticket {
  const _$TicketImpl({
    required this.id,
    required this.itemId,
    required this.name,
    this.variantName = '',
    required this.course,
    required this.station,
    this.qty = 1,
    final List<String> modifiers = const <String>[],
    this.specialInstructions,
    required this.price,
    required this.status,
    required this.sentAt,
    this.voidReason,
    this.voidApprovedBy,
    this.createdBy,
  }) : _modifiers = modifiers;

  @override
  final String id;
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
  final Station station;
  @override
  @JsonKey()
  final int qty;
  final List<String> _modifiers;
  @override
  @JsonKey()
  List<String> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @override
  final String? specialInstructions;
  @override
  final int price;
  @override
  final TicketStatus status;
  @override
  final String sentAt;
  @override
  final String? voidReason;
  @override
  final String? voidApprovedBy;
  @override
  final String? createdBy;

  @override
  String toString() {
    return 'Ticket(id: $id, itemId: $itemId, name: $name, variantName: $variantName, course: $course, station: $station, qty: $qty, modifiers: $modifiers, specialInstructions: $specialInstructions, price: $price, status: $status, sentAt: $sentAt, voidReason: $voidReason, voidApprovedBy: $voidApprovedBy, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TicketImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.variantName, variantName) ||
                other.variantName == variantName) &&
            (identical(other.course, course) || other.course == course) &&
            (identical(other.station, station) || other.station == station) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            const DeepCollectionEquality().equals(
              other._modifiers,
              _modifiers,
            ) &&
            (identical(other.specialInstructions, specialInstructions) ||
                other.specialInstructions == specialInstructions) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt) &&
            (identical(other.voidReason, voidReason) ||
                other.voidReason == voidReason) &&
            (identical(other.voidApprovedBy, voidApprovedBy) ||
                other.voidApprovedBy == voidApprovedBy) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    itemId,
    name,
    variantName,
    course,
    station,
    qty,
    const DeepCollectionEquality().hash(_modifiers),
    specialInstructions,
    price,
    status,
    sentAt,
    voidReason,
    voidApprovedBy,
    createdBy,
  );

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TicketImplCopyWith<_$TicketImpl> get copyWith =>
      __$$TicketImplCopyWithImpl<_$TicketImpl>(this, _$identity);
}

abstract class _Ticket implements Ticket {
  const factory _Ticket({
    required final String id,
    required final String itemId,
    required final String name,
    final String variantName,
    required final CourseId course,
    required final Station station,
    final int qty,
    final List<String> modifiers,
    final String? specialInstructions,
    required final int price,
    required final TicketStatus status,
    required final String sentAt,
    final String? voidReason,
    final String? voidApprovedBy,
    final String? createdBy,
  }) = _$TicketImpl;

  @override
  String get id;
  @override
  String get itemId;
  @override
  String get name;
  @override
  String get variantName;
  @override
  CourseId get course;
  @override
  Station get station;
  @override
  int get qty;
  @override
  List<String> get modifiers;
  @override
  String? get specialInstructions;
  @override
  int get price;
  @override
  TicketStatus get status;
  @override
  String get sentAt;
  @override
  String? get voidReason;
  @override
  String? get voidApprovedBy;
  @override
  String? get createdBy;

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TicketImplCopyWith<_$TicketImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
