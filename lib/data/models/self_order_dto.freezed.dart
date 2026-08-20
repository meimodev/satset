// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'self_order_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GuestLineModDto _$GuestLineModDtoFromJson(Map<String, dynamic> json) {
  return _GuestLineModDto.fromJson(json);
}

/// @nodoc
mixin _$GuestLineModDto {
  String get label => throw _privateConstructorUsedError;

  /// Serializes this GuestLineModDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GuestLineModDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuestLineModDtoCopyWith<GuestLineModDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuestLineModDtoCopyWith<$Res> {
  factory $GuestLineModDtoCopyWith(
    GuestLineModDto value,
    $Res Function(GuestLineModDto) then,
  ) = _$GuestLineModDtoCopyWithImpl<$Res, GuestLineModDto>;
  @useResult
  $Res call({String label});
}

/// @nodoc
class _$GuestLineModDtoCopyWithImpl<$Res, $Val extends GuestLineModDto>
    implements $GuestLineModDtoCopyWith<$Res> {
  _$GuestLineModDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuestLineModDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? label = null}) {
    return _then(
      _value.copyWith(
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuestLineModDtoImplCopyWith<$Res>
    implements $GuestLineModDtoCopyWith<$Res> {
  factory _$$GuestLineModDtoImplCopyWith(
    _$GuestLineModDtoImpl value,
    $Res Function(_$GuestLineModDtoImpl) then,
  ) = __$$GuestLineModDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String label});
}

/// @nodoc
class __$$GuestLineModDtoImplCopyWithImpl<$Res>
    extends _$GuestLineModDtoCopyWithImpl<$Res, _$GuestLineModDtoImpl>
    implements _$$GuestLineModDtoImplCopyWith<$Res> {
  __$$GuestLineModDtoImplCopyWithImpl(
    _$GuestLineModDtoImpl _value,
    $Res Function(_$GuestLineModDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuestLineModDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? label = null}) {
    return _then(
      _$GuestLineModDtoImpl(
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GuestLineModDtoImpl implements _GuestLineModDto {
  const _$GuestLineModDtoImpl({this.label = ''});

  factory _$GuestLineModDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuestLineModDtoImplFromJson(json);

  @override
  @JsonKey()
  final String label;

  @override
  String toString() {
    return 'GuestLineModDto(label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuestLineModDtoImpl &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, label);

  /// Create a copy of GuestLineModDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuestLineModDtoImplCopyWith<_$GuestLineModDtoImpl> get copyWith =>
      __$$GuestLineModDtoImplCopyWithImpl<_$GuestLineModDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GuestLineModDtoImplToJson(this);
  }
}

abstract class _GuestLineModDto implements GuestLineModDto {
  const factory _GuestLineModDto({final String label}) = _$GuestLineModDtoImpl;

  factory _GuestLineModDto.fromJson(Map<String, dynamic> json) =
      _$GuestLineModDtoImpl.fromJson;

  @override
  String get label;

  /// Create a copy of GuestLineModDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuestLineModDtoImplCopyWith<_$GuestLineModDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GuestOrderLineDto _$GuestOrderLineDtoFromJson(Map<String, dynamic> json) {
  return _GuestOrderLineDto.fromJson(json);
}

/// @nodoc
mixin _$GuestOrderLineDto {
  String get id => throw _privateConstructorUsedError;
  String get itemId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get variantName => throw _privateConstructorUsedError;
  int get qty => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  int get unitPrice => throw _privateConstructorUsedError;
  List<GuestLineModDto> get modifiers => throw _privateConstructorUsedError;

  /// Serializes this GuestOrderLineDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GuestOrderLineDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuestOrderLineDtoCopyWith<GuestOrderLineDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuestOrderLineDtoCopyWith<$Res> {
  factory $GuestOrderLineDtoCopyWith(
    GuestOrderLineDto value,
    $Res Function(GuestOrderLineDto) then,
  ) = _$GuestOrderLineDtoCopyWithImpl<$Res, GuestOrderLineDto>;
  @useResult
  $Res call({
    String id,
    String itemId,
    String name,
    String variantName,
    int qty,
    String? note,
    int unitPrice,
    List<GuestLineModDto> modifiers,
  });
}

/// @nodoc
class _$GuestOrderLineDtoCopyWithImpl<$Res, $Val extends GuestOrderLineDto>
    implements $GuestOrderLineDtoCopyWith<$Res> {
  _$GuestOrderLineDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuestOrderLineDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? name = null,
    Object? variantName = null,
    Object? qty = null,
    Object? note = freezed,
    Object? unitPrice = null,
    Object? modifiers = null,
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
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            unitPrice: null == unitPrice
                ? _value.unitPrice
                : unitPrice // ignore: cast_nullable_to_non_nullable
                      as int,
            modifiers: null == modifiers
                ? _value.modifiers
                : modifiers // ignore: cast_nullable_to_non_nullable
                      as List<GuestLineModDto>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuestOrderLineDtoImplCopyWith<$Res>
    implements $GuestOrderLineDtoCopyWith<$Res> {
  factory _$$GuestOrderLineDtoImplCopyWith(
    _$GuestOrderLineDtoImpl value,
    $Res Function(_$GuestOrderLineDtoImpl) then,
  ) = __$$GuestOrderLineDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String itemId,
    String name,
    String variantName,
    int qty,
    String? note,
    int unitPrice,
    List<GuestLineModDto> modifiers,
  });
}

/// @nodoc
class __$$GuestOrderLineDtoImplCopyWithImpl<$Res>
    extends _$GuestOrderLineDtoCopyWithImpl<$Res, _$GuestOrderLineDtoImpl>
    implements _$$GuestOrderLineDtoImplCopyWith<$Res> {
  __$$GuestOrderLineDtoImplCopyWithImpl(
    _$GuestOrderLineDtoImpl _value,
    $Res Function(_$GuestOrderLineDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuestOrderLineDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? name = null,
    Object? variantName = null,
    Object? qty = null,
    Object? note = freezed,
    Object? unitPrice = null,
    Object? modifiers = null,
  }) {
    return _then(
      _$GuestOrderLineDtoImpl(
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
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        unitPrice: null == unitPrice
            ? _value.unitPrice
            : unitPrice // ignore: cast_nullable_to_non_nullable
                  as int,
        modifiers: null == modifiers
            ? _value._modifiers
            : modifiers // ignore: cast_nullable_to_non_nullable
                  as List<GuestLineModDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GuestOrderLineDtoImpl implements _GuestOrderLineDto {
  const _$GuestOrderLineDtoImpl({
    required this.id,
    required this.itemId,
    required this.name,
    this.variantName = '',
    this.qty = 1,
    this.note,
    this.unitPrice = 0,
    final List<GuestLineModDto> modifiers = const [],
  }) : _modifiers = modifiers;

  factory _$GuestOrderLineDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuestOrderLineDtoImplFromJson(json);

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
  @JsonKey()
  final int qty;
  @override
  final String? note;
  @override
  @JsonKey()
  final int unitPrice;
  final List<GuestLineModDto> _modifiers;
  @override
  @JsonKey()
  List<GuestLineModDto> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @override
  String toString() {
    return 'GuestOrderLineDto(id: $id, itemId: $itemId, name: $name, variantName: $variantName, qty: $qty, note: $note, unitPrice: $unitPrice, modifiers: $modifiers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuestOrderLineDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.variantName, variantName) ||
                other.variantName == variantName) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            const DeepCollectionEquality().equals(
              other._modifiers,
              _modifiers,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    itemId,
    name,
    variantName,
    qty,
    note,
    unitPrice,
    const DeepCollectionEquality().hash(_modifiers),
  );

  /// Create a copy of GuestOrderLineDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuestOrderLineDtoImplCopyWith<_$GuestOrderLineDtoImpl> get copyWith =>
      __$$GuestOrderLineDtoImplCopyWithImpl<_$GuestOrderLineDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GuestOrderLineDtoImplToJson(this);
  }
}

abstract class _GuestOrderLineDto implements GuestOrderLineDto {
  const factory _GuestOrderLineDto({
    required final String id,
    required final String itemId,
    required final String name,
    final String variantName,
    final int qty,
    final String? note,
    final int unitPrice,
    final List<GuestLineModDto> modifiers,
  }) = _$GuestOrderLineDtoImpl;

  factory _GuestOrderLineDto.fromJson(Map<String, dynamic> json) =
      _$GuestOrderLineDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get itemId;
  @override
  String get name;
  @override
  String get variantName;
  @override
  int get qty;
  @override
  String? get note;
  @override
  int get unitPrice;
  @override
  List<GuestLineModDto> get modifiers;

  /// Create a copy of GuestOrderLineDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuestOrderLineDtoImplCopyWith<_$GuestOrderLineDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GuestOrderDto _$GuestOrderDtoFromJson(Map<String, dynamic> json) {
  return _GuestOrderDto.fromJson(json);
}

/// @nodoc
mixin _$GuestOrderDto {
  String get id => throw _privateConstructorUsedError;
  String get tableId => throw _privateConstructorUsedError;
  String? get tableLabel => throw _privateConstructorUsedError;

  /// A counter order (ADR-0109): no table, its own [[Bawa pulang]] bill once
  /// accepted. The queue card spells it, because a blank table label is not
  /// a word.
  bool get counter => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get submittedAt => throw _privateConstructorUsedError;
  DateTime? get decidedAt => throw _privateConstructorUsedError;
  String? get rejectReasonCode => throw _privateConstructorUsedError;

  /// Who accepted or rejected it. Staff-only — the guest page is told what
  /// happened, never by whom.
  String? get decidedBy => throw _privateConstructorUsedError;
  int get subtotal => throw _privateConstructorUsedError;
  List<GuestOrderLineDto> get lines => throw _privateConstructorUsedError;

  /// Serializes this GuestOrderDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GuestOrderDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuestOrderDtoCopyWith<GuestOrderDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuestOrderDtoCopyWith<$Res> {
  factory $GuestOrderDtoCopyWith(
    GuestOrderDto value,
    $Res Function(GuestOrderDto) then,
  ) = _$GuestOrderDtoCopyWithImpl<$Res, GuestOrderDto>;
  @useResult
  $Res call({
    String id,
    String tableId,
    String? tableLabel,
    bool counter,
    String status,
    DateTime submittedAt,
    DateTime? decidedAt,
    String? rejectReasonCode,
    String? decidedBy,
    int subtotal,
    List<GuestOrderLineDto> lines,
  });
}

/// @nodoc
class _$GuestOrderDtoCopyWithImpl<$Res, $Val extends GuestOrderDto>
    implements $GuestOrderDtoCopyWith<$Res> {
  _$GuestOrderDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuestOrderDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tableId = null,
    Object? tableLabel = freezed,
    Object? counter = null,
    Object? status = null,
    Object? submittedAt = null,
    Object? decidedAt = freezed,
    Object? rejectReasonCode = freezed,
    Object? decidedBy = freezed,
    Object? subtotal = null,
    Object? lines = null,
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
            tableLabel: freezed == tableLabel
                ? _value.tableLabel
                : tableLabel // ignore: cast_nullable_to_non_nullable
                      as String?,
            counter: null == counter
                ? _value.counter
                : counter // ignore: cast_nullable_to_non_nullable
                      as bool,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            submittedAt: null == submittedAt
                ? _value.submittedAt
                : submittedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            decidedAt: freezed == decidedAt
                ? _value.decidedAt
                : decidedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            rejectReasonCode: freezed == rejectReasonCode
                ? _value.rejectReasonCode
                : rejectReasonCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            decidedBy: freezed == decidedBy
                ? _value.decidedBy
                : decidedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            subtotal: null == subtotal
                ? _value.subtotal
                : subtotal // ignore: cast_nullable_to_non_nullable
                      as int,
            lines: null == lines
                ? _value.lines
                : lines // ignore: cast_nullable_to_non_nullable
                      as List<GuestOrderLineDto>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuestOrderDtoImplCopyWith<$Res>
    implements $GuestOrderDtoCopyWith<$Res> {
  factory _$$GuestOrderDtoImplCopyWith(
    _$GuestOrderDtoImpl value,
    $Res Function(_$GuestOrderDtoImpl) then,
  ) = __$$GuestOrderDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String tableId,
    String? tableLabel,
    bool counter,
    String status,
    DateTime submittedAt,
    DateTime? decidedAt,
    String? rejectReasonCode,
    String? decidedBy,
    int subtotal,
    List<GuestOrderLineDto> lines,
  });
}

/// @nodoc
class __$$GuestOrderDtoImplCopyWithImpl<$Res>
    extends _$GuestOrderDtoCopyWithImpl<$Res, _$GuestOrderDtoImpl>
    implements _$$GuestOrderDtoImplCopyWith<$Res> {
  __$$GuestOrderDtoImplCopyWithImpl(
    _$GuestOrderDtoImpl _value,
    $Res Function(_$GuestOrderDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuestOrderDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tableId = null,
    Object? tableLabel = freezed,
    Object? counter = null,
    Object? status = null,
    Object? submittedAt = null,
    Object? decidedAt = freezed,
    Object? rejectReasonCode = freezed,
    Object? decidedBy = freezed,
    Object? subtotal = null,
    Object? lines = null,
  }) {
    return _then(
      _$GuestOrderDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        tableId: null == tableId
            ? _value.tableId
            : tableId // ignore: cast_nullable_to_non_nullable
                  as String,
        tableLabel: freezed == tableLabel
            ? _value.tableLabel
            : tableLabel // ignore: cast_nullable_to_non_nullable
                  as String?,
        counter: null == counter
            ? _value.counter
            : counter // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        submittedAt: null == submittedAt
            ? _value.submittedAt
            : submittedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        decidedAt: freezed == decidedAt
            ? _value.decidedAt
            : decidedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        rejectReasonCode: freezed == rejectReasonCode
            ? _value.rejectReasonCode
            : rejectReasonCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        decidedBy: freezed == decidedBy
            ? _value.decidedBy
            : decidedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        subtotal: null == subtotal
            ? _value.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as int,
        lines: null == lines
            ? _value._lines
            : lines // ignore: cast_nullable_to_non_nullable
                  as List<GuestOrderLineDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GuestOrderDtoImpl implements _GuestOrderDto {
  const _$GuestOrderDtoImpl({
    required this.id,
    required this.tableId,
    this.tableLabel,
    this.counter = false,
    this.status = 'pending',
    required this.submittedAt,
    this.decidedAt,
    this.rejectReasonCode,
    this.decidedBy,
    this.subtotal = 0,
    final List<GuestOrderLineDto> lines = const [],
  }) : _lines = lines;

  factory _$GuestOrderDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuestOrderDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String tableId;
  @override
  final String? tableLabel;

  /// A counter order (ADR-0109): no table, its own [[Bawa pulang]] bill once
  /// accepted. The queue card spells it, because a blank table label is not
  /// a word.
  @override
  @JsonKey()
  final bool counter;
  @override
  @JsonKey()
  final String status;
  @override
  final DateTime submittedAt;
  @override
  final DateTime? decidedAt;
  @override
  final String? rejectReasonCode;

  /// Who accepted or rejected it. Staff-only — the guest page is told what
  /// happened, never by whom.
  @override
  final String? decidedBy;
  @override
  @JsonKey()
  final int subtotal;
  final List<GuestOrderLineDto> _lines;
  @override
  @JsonKey()
  List<GuestOrderLineDto> get lines {
    if (_lines is EqualUnmodifiableListView) return _lines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lines);
  }

  @override
  String toString() {
    return 'GuestOrderDto(id: $id, tableId: $tableId, tableLabel: $tableLabel, counter: $counter, status: $status, submittedAt: $submittedAt, decidedAt: $decidedAt, rejectReasonCode: $rejectReasonCode, decidedBy: $decidedBy, subtotal: $subtotal, lines: $lines)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuestOrderDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.tableLabel, tableLabel) ||
                other.tableLabel == tableLabel) &&
            (identical(other.counter, counter) || other.counter == counter) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.decidedAt, decidedAt) ||
                other.decidedAt == decidedAt) &&
            (identical(other.rejectReasonCode, rejectReasonCode) ||
                other.rejectReasonCode == rejectReasonCode) &&
            (identical(other.decidedBy, decidedBy) ||
                other.decidedBy == decidedBy) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            const DeepCollectionEquality().equals(other._lines, _lines));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    tableId,
    tableLabel,
    counter,
    status,
    submittedAt,
    decidedAt,
    rejectReasonCode,
    decidedBy,
    subtotal,
    const DeepCollectionEquality().hash(_lines),
  );

  /// Create a copy of GuestOrderDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuestOrderDtoImplCopyWith<_$GuestOrderDtoImpl> get copyWith =>
      __$$GuestOrderDtoImplCopyWithImpl<_$GuestOrderDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GuestOrderDtoImplToJson(this);
  }
}

abstract class _GuestOrderDto implements GuestOrderDto {
  const factory _GuestOrderDto({
    required final String id,
    required final String tableId,
    final String? tableLabel,
    final bool counter,
    final String status,
    required final DateTime submittedAt,
    final DateTime? decidedAt,
    final String? rejectReasonCode,
    final String? decidedBy,
    final int subtotal,
    final List<GuestOrderLineDto> lines,
  }) = _$GuestOrderDtoImpl;

  factory _GuestOrderDto.fromJson(Map<String, dynamic> json) =
      _$GuestOrderDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get tableId;
  @override
  String? get tableLabel;

  /// A counter order (ADR-0109): no table, its own [[Bawa pulang]] bill once
  /// accepted. The queue card spells it, because a blank table label is not
  /// a word.
  @override
  bool get counter;
  @override
  String get status;
  @override
  DateTime get submittedAt;
  @override
  DateTime? get decidedAt;
  @override
  String? get rejectReasonCode;

  /// Who accepted or rejected it. Staff-only — the guest page is told what
  /// happened, never by whom.
  @override
  String? get decidedBy;
  @override
  int get subtotal;
  @override
  List<GuestOrderLineDto> get lines;

  /// Create a copy of GuestOrderDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuestOrderDtoImplCopyWith<_$GuestOrderDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GuestTableDto _$GuestTableDtoFromJson(Map<String, dynamic> json) {
  return _GuestTableDto.fromJson(json);
}

/// @nodoc
mixin _$GuestTableDto {
  String get id => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;
  String get zoneId => throw _privateConstructorUsedError;
  String get zoneName => throw _privateConstructorUsedError;
  int get seats => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;

  /// Serializes this GuestTableDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GuestTableDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuestTableDtoCopyWith<GuestTableDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuestTableDtoCopyWith<$Res> {
  factory $GuestTableDtoCopyWith(
    GuestTableDto value,
    $Res Function(GuestTableDto) then,
  ) = _$GuestTableDtoCopyWithImpl<$Res, GuestTableDto>;
  @useResult
  $Res call({
    String id,
    String? label,
    String zoneId,
    String zoneName,
    int seats,
    String code,
    bool enabled,
  });
}

/// @nodoc
class _$GuestTableDtoCopyWithImpl<$Res, $Val extends GuestTableDto>
    implements $GuestTableDtoCopyWith<$Res> {
  _$GuestTableDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuestTableDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = freezed,
    Object? zoneId = null,
    Object? zoneName = null,
    Object? seats = null,
    Object? code = null,
    Object? enabled = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
            zoneId: null == zoneId
                ? _value.zoneId
                : zoneId // ignore: cast_nullable_to_non_nullable
                      as String,
            zoneName: null == zoneName
                ? _value.zoneName
                : zoneName // ignore: cast_nullable_to_non_nullable
                      as String,
            seats: null == seats
                ? _value.seats
                : seats // ignore: cast_nullable_to_non_nullable
                      as int,
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuestTableDtoImplCopyWith<$Res>
    implements $GuestTableDtoCopyWith<$Res> {
  factory _$$GuestTableDtoImplCopyWith(
    _$GuestTableDtoImpl value,
    $Res Function(_$GuestTableDtoImpl) then,
  ) = __$$GuestTableDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? label,
    String zoneId,
    String zoneName,
    int seats,
    String code,
    bool enabled,
  });
}

/// @nodoc
class __$$GuestTableDtoImplCopyWithImpl<$Res>
    extends _$GuestTableDtoCopyWithImpl<$Res, _$GuestTableDtoImpl>
    implements _$$GuestTableDtoImplCopyWith<$Res> {
  __$$GuestTableDtoImplCopyWithImpl(
    _$GuestTableDtoImpl _value,
    $Res Function(_$GuestTableDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuestTableDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = freezed,
    Object? zoneId = null,
    Object? zoneName = null,
    Object? seats = null,
    Object? code = null,
    Object? enabled = null,
  }) {
    return _then(
      _$GuestTableDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        zoneId: null == zoneId
            ? _value.zoneId
            : zoneId // ignore: cast_nullable_to_non_nullable
                  as String,
        zoneName: null == zoneName
            ? _value.zoneName
            : zoneName // ignore: cast_nullable_to_non_nullable
                  as String,
        seats: null == seats
            ? _value.seats
            : seats // ignore: cast_nullable_to_non_nullable
                  as int,
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GuestTableDtoImpl implements _GuestTableDto {
  const _$GuestTableDtoImpl({
    required this.id,
    this.label,
    this.zoneId = '',
    this.zoneName = '',
    this.seats = 0,
    this.code = '',
    this.enabled = true,
  });

  factory _$GuestTableDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuestTableDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String? label;
  @override
  @JsonKey()
  final String zoneId;
  @override
  @JsonKey()
  final String zoneName;
  @override
  @JsonKey()
  final int seats;
  @override
  @JsonKey()
  final String code;
  @override
  @JsonKey()
  final bool enabled;

  @override
  String toString() {
    return 'GuestTableDto(id: $id, label: $label, zoneId: $zoneId, zoneName: $zoneName, seats: $seats, code: $code, enabled: $enabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuestTableDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.zoneId, zoneId) || other.zoneId == zoneId) &&
            (identical(other.zoneName, zoneName) ||
                other.zoneName == zoneName) &&
            (identical(other.seats, seats) || other.seats == seats) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.enabled, enabled) || other.enabled == enabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    label,
    zoneId,
    zoneName,
    seats,
    code,
    enabled,
  );

  /// Create a copy of GuestTableDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuestTableDtoImplCopyWith<_$GuestTableDtoImpl> get copyWith =>
      __$$GuestTableDtoImplCopyWithImpl<_$GuestTableDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GuestTableDtoImplToJson(this);
  }
}

abstract class _GuestTableDto implements GuestTableDto {
  const factory _GuestTableDto({
    required final String id,
    final String? label,
    final String zoneId,
    final String zoneName,
    final int seats,
    final String code,
    final bool enabled,
  }) = _$GuestTableDtoImpl;

  factory _GuestTableDto.fromJson(Map<String, dynamic> json) =
      _$GuestTableDtoImpl.fromJson;

  @override
  String get id;
  @override
  String? get label;
  @override
  String get zoneId;
  @override
  String get zoneName;
  @override
  int get seats;
  @override
  String get code;
  @override
  bool get enabled;

  /// Create a copy of GuestTableDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuestTableDtoImplCopyWith<_$GuestTableDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GuestCategoryDto _$GuestCategoryDtoFromJson(Map<String, dynamic> json) {
  return _GuestCategoryDto.fromJson(json);
}

/// @nodoc
mixin _$GuestCategoryDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int? get fromMin => throw _privateConstructorUsedError;
  int? get toMin => throw _privateConstructorUsedError;

  /// Serializes this GuestCategoryDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GuestCategoryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuestCategoryDtoCopyWith<GuestCategoryDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuestCategoryDtoCopyWith<$Res> {
  factory $GuestCategoryDtoCopyWith(
    GuestCategoryDto value,
    $Res Function(GuestCategoryDto) then,
  ) = _$GuestCategoryDtoCopyWithImpl<$Res, GuestCategoryDto>;
  @useResult
  $Res call({String id, String name, int? fromMin, int? toMin});
}

/// @nodoc
class _$GuestCategoryDtoCopyWithImpl<$Res, $Val extends GuestCategoryDto>
    implements $GuestCategoryDtoCopyWith<$Res> {
  _$GuestCategoryDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuestCategoryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? fromMin = freezed,
    Object? toMin = freezed,
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
            fromMin: freezed == fromMin
                ? _value.fromMin
                : fromMin // ignore: cast_nullable_to_non_nullable
                      as int?,
            toMin: freezed == toMin
                ? _value.toMin
                : toMin // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuestCategoryDtoImplCopyWith<$Res>
    implements $GuestCategoryDtoCopyWith<$Res> {
  factory _$$GuestCategoryDtoImplCopyWith(
    _$GuestCategoryDtoImpl value,
    $Res Function(_$GuestCategoryDtoImpl) then,
  ) = __$$GuestCategoryDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, int? fromMin, int? toMin});
}

/// @nodoc
class __$$GuestCategoryDtoImplCopyWithImpl<$Res>
    extends _$GuestCategoryDtoCopyWithImpl<$Res, _$GuestCategoryDtoImpl>
    implements _$$GuestCategoryDtoImplCopyWith<$Res> {
  __$$GuestCategoryDtoImplCopyWithImpl(
    _$GuestCategoryDtoImpl _value,
    $Res Function(_$GuestCategoryDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuestCategoryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? fromMin = freezed,
    Object? toMin = freezed,
  }) {
    return _then(
      _$GuestCategoryDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        fromMin: freezed == fromMin
            ? _value.fromMin
            : fromMin // ignore: cast_nullable_to_non_nullable
                  as int?,
        toMin: freezed == toMin
            ? _value.toMin
            : toMin // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GuestCategoryDtoImpl implements _GuestCategoryDto {
  const _$GuestCategoryDtoImpl({
    required this.id,
    required this.name,
    this.fromMin,
    this.toMin,
  });

  factory _$GuestCategoryDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuestCategoryDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final int? fromMin;
  @override
  final int? toMin;

  @override
  String toString() {
    return 'GuestCategoryDto(id: $id, name: $name, fromMin: $fromMin, toMin: $toMin)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuestCategoryDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.fromMin, fromMin) || other.fromMin == fromMin) &&
            (identical(other.toMin, toMin) || other.toMin == toMin));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, fromMin, toMin);

  /// Create a copy of GuestCategoryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuestCategoryDtoImplCopyWith<_$GuestCategoryDtoImpl> get copyWith =>
      __$$GuestCategoryDtoImplCopyWithImpl<_$GuestCategoryDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GuestCategoryDtoImplToJson(this);
  }
}

abstract class _GuestCategoryDto implements GuestCategoryDto {
  const factory _GuestCategoryDto({
    required final String id,
    required final String name,
    final int? fromMin,
    final int? toMin,
  }) = _$GuestCategoryDtoImpl;

  factory _GuestCategoryDto.fromJson(Map<String, dynamic> json) =
      _$GuestCategoryDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int? get fromMin;
  @override
  int? get toMin;

  /// Create a copy of GuestCategoryDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuestCategoryDtoImplCopyWith<_$GuestCategoryDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GuestMenuItemDto _$GuestMenuItemDtoFromJson(Map<String, dynamic> json) {
  return _GuestMenuItemDto.fromJson(json);
}

/// @nodoc
mixin _$GuestMenuItemDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get basePrice => throw _privateConstructorUsedError;
  bool get featured => throw _privateConstructorUsedError;
  bool get visible => throw _privateConstructorUsedError;
  bool get soldOut => throw _privateConstructorUsedError;
  bool get alcohol => throw _privateConstructorUsedError;

  /// `auto` | `forceIn` | `forceOut`, already expired server-side — a force
  /// that outlived its business day arrives as `auto`.
  String get stockOverride => throw _privateConstructorUsedError;

  /// Serializes this GuestMenuItemDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GuestMenuItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuestMenuItemDtoCopyWith<GuestMenuItemDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuestMenuItemDtoCopyWith<$Res> {
  factory $GuestMenuItemDtoCopyWith(
    GuestMenuItemDto value,
    $Res Function(GuestMenuItemDto) then,
  ) = _$GuestMenuItemDtoCopyWithImpl<$Res, GuestMenuItemDto>;
  @useResult
  $Res call({
    String id,
    String name,
    String categoryId,
    String description,
    int basePrice,
    bool featured,
    bool visible,
    bool soldOut,
    bool alcohol,
    String stockOverride,
  });
}

/// @nodoc
class _$GuestMenuItemDtoCopyWithImpl<$Res, $Val extends GuestMenuItemDto>
    implements $GuestMenuItemDtoCopyWith<$Res> {
  _$GuestMenuItemDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuestMenuItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? categoryId = null,
    Object? description = null,
    Object? basePrice = null,
    Object? featured = null,
    Object? visible = null,
    Object? soldOut = null,
    Object? alcohol = null,
    Object? stockOverride = null,
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
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            basePrice: null == basePrice
                ? _value.basePrice
                : basePrice // ignore: cast_nullable_to_non_nullable
                      as int,
            featured: null == featured
                ? _value.featured
                : featured // ignore: cast_nullable_to_non_nullable
                      as bool,
            visible: null == visible
                ? _value.visible
                : visible // ignore: cast_nullable_to_non_nullable
                      as bool,
            soldOut: null == soldOut
                ? _value.soldOut
                : soldOut // ignore: cast_nullable_to_non_nullable
                      as bool,
            alcohol: null == alcohol
                ? _value.alcohol
                : alcohol // ignore: cast_nullable_to_non_nullable
                      as bool,
            stockOverride: null == stockOverride
                ? _value.stockOverride
                : stockOverride // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuestMenuItemDtoImplCopyWith<$Res>
    implements $GuestMenuItemDtoCopyWith<$Res> {
  factory _$$GuestMenuItemDtoImplCopyWith(
    _$GuestMenuItemDtoImpl value,
    $Res Function(_$GuestMenuItemDtoImpl) then,
  ) = __$$GuestMenuItemDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String categoryId,
    String description,
    int basePrice,
    bool featured,
    bool visible,
    bool soldOut,
    bool alcohol,
    String stockOverride,
  });
}

/// @nodoc
class __$$GuestMenuItemDtoImplCopyWithImpl<$Res>
    extends _$GuestMenuItemDtoCopyWithImpl<$Res, _$GuestMenuItemDtoImpl>
    implements _$$GuestMenuItemDtoImplCopyWith<$Res> {
  __$$GuestMenuItemDtoImplCopyWithImpl(
    _$GuestMenuItemDtoImpl _value,
    $Res Function(_$GuestMenuItemDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuestMenuItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? categoryId = null,
    Object? description = null,
    Object? basePrice = null,
    Object? featured = null,
    Object? visible = null,
    Object? soldOut = null,
    Object? alcohol = null,
    Object? stockOverride = null,
  }) {
    return _then(
      _$GuestMenuItemDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        basePrice: null == basePrice
            ? _value.basePrice
            : basePrice // ignore: cast_nullable_to_non_nullable
                  as int,
        featured: null == featured
            ? _value.featured
            : featured // ignore: cast_nullable_to_non_nullable
                  as bool,
        visible: null == visible
            ? _value.visible
            : visible // ignore: cast_nullable_to_non_nullable
                  as bool,
        soldOut: null == soldOut
            ? _value.soldOut
            : soldOut // ignore: cast_nullable_to_non_nullable
                  as bool,
        alcohol: null == alcohol
            ? _value.alcohol
            : alcohol // ignore: cast_nullable_to_non_nullable
                  as bool,
        stockOverride: null == stockOverride
            ? _value.stockOverride
            : stockOverride // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GuestMenuItemDtoImpl implements _GuestMenuItemDto {
  const _$GuestMenuItemDtoImpl({
    required this.id,
    required this.name,
    this.categoryId = '',
    this.description = '',
    this.basePrice = 0,
    this.featured = false,
    this.visible = true,
    this.soldOut = false,
    this.alcohol = false,
    this.stockOverride = 'auto',
  });

  factory _$GuestMenuItemDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuestMenuItemDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String categoryId;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey()
  final int basePrice;
  @override
  @JsonKey()
  final bool featured;
  @override
  @JsonKey()
  final bool visible;
  @override
  @JsonKey()
  final bool soldOut;
  @override
  @JsonKey()
  final bool alcohol;

  /// `auto` | `forceIn` | `forceOut`, already expired server-side — a force
  /// that outlived its business day arrives as `auto`.
  @override
  @JsonKey()
  final String stockOverride;

  @override
  String toString() {
    return 'GuestMenuItemDto(id: $id, name: $name, categoryId: $categoryId, description: $description, basePrice: $basePrice, featured: $featured, visible: $visible, soldOut: $soldOut, alcohol: $alcohol, stockOverride: $stockOverride)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuestMenuItemDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.basePrice, basePrice) ||
                other.basePrice == basePrice) &&
            (identical(other.featured, featured) ||
                other.featured == featured) &&
            (identical(other.visible, visible) || other.visible == visible) &&
            (identical(other.soldOut, soldOut) || other.soldOut == soldOut) &&
            (identical(other.alcohol, alcohol) || other.alcohol == alcohol) &&
            (identical(other.stockOverride, stockOverride) ||
                other.stockOverride == stockOverride));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    categoryId,
    description,
    basePrice,
    featured,
    visible,
    soldOut,
    alcohol,
    stockOverride,
  );

  /// Create a copy of GuestMenuItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuestMenuItemDtoImplCopyWith<_$GuestMenuItemDtoImpl> get copyWith =>
      __$$GuestMenuItemDtoImplCopyWithImpl<_$GuestMenuItemDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GuestMenuItemDtoImplToJson(this);
  }
}

abstract class _GuestMenuItemDto implements GuestMenuItemDto {
  const factory _GuestMenuItemDto({
    required final String id,
    required final String name,
    final String categoryId,
    final String description,
    final int basePrice,
    final bool featured,
    final bool visible,
    final bool soldOut,
    final bool alcohol,
    final String stockOverride,
  }) = _$GuestMenuItemDtoImpl;

  factory _GuestMenuItemDto.fromJson(Map<String, dynamic> json) =
      _$GuestMenuItemDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get categoryId;
  @override
  String get description;
  @override
  int get basePrice;
  @override
  bool get featured;
  @override
  bool get visible;
  @override
  bool get soldOut;
  @override
  bool get alcohol;

  /// `auto` | `forceIn` | `forceOut`, already expired server-side — a force
  /// that outlived its business day arrives as `auto`.
  @override
  String get stockOverride;

  /// Create a copy of GuestMenuItemDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuestMenuItemDtoImplCopyWith<_$GuestMenuItemDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GuestStatsDto _$GuestStatsDtoFromJson(Map<String, dynamic> json) {
  return _GuestStatsDto.fromJson(json);
}

/// @nodoc
mixin _$GuestStatsDto {
  int get total => throw _privateConstructorUsedError;
  int get pending => throw _privateConstructorUsedError;
  int get accepted => throw _privateConstructorUsedError;
  int get rejected => throw _privateConstructorUsedError;
  int get value => throw _privateConstructorUsedError;
  int get medianWaitSecs => throw _privateConstructorUsedError;

  /// Serializes this GuestStatsDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GuestStatsDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuestStatsDtoCopyWith<GuestStatsDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuestStatsDtoCopyWith<$Res> {
  factory $GuestStatsDtoCopyWith(
    GuestStatsDto value,
    $Res Function(GuestStatsDto) then,
  ) = _$GuestStatsDtoCopyWithImpl<$Res, GuestStatsDto>;
  @useResult
  $Res call({
    int total,
    int pending,
    int accepted,
    int rejected,
    int value,
    int medianWaitSecs,
  });
}

/// @nodoc
class _$GuestStatsDtoCopyWithImpl<$Res, $Val extends GuestStatsDto>
    implements $GuestStatsDtoCopyWith<$Res> {
  _$GuestStatsDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuestStatsDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? pending = null,
    Object? accepted = null,
    Object? rejected = null,
    Object? value = null,
    Object? medianWaitSecs = null,
  }) {
    return _then(
      _value.copyWith(
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            pending: null == pending
                ? _value.pending
                : pending // ignore: cast_nullable_to_non_nullable
                      as int,
            accepted: null == accepted
                ? _value.accepted
                : accepted // ignore: cast_nullable_to_non_nullable
                      as int,
            rejected: null == rejected
                ? _value.rejected
                : rejected // ignore: cast_nullable_to_non_nullable
                      as int,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as int,
            medianWaitSecs: null == medianWaitSecs
                ? _value.medianWaitSecs
                : medianWaitSecs // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuestStatsDtoImplCopyWith<$Res>
    implements $GuestStatsDtoCopyWith<$Res> {
  factory _$$GuestStatsDtoImplCopyWith(
    _$GuestStatsDtoImpl value,
    $Res Function(_$GuestStatsDtoImpl) then,
  ) = __$$GuestStatsDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int total,
    int pending,
    int accepted,
    int rejected,
    int value,
    int medianWaitSecs,
  });
}

/// @nodoc
class __$$GuestStatsDtoImplCopyWithImpl<$Res>
    extends _$GuestStatsDtoCopyWithImpl<$Res, _$GuestStatsDtoImpl>
    implements _$$GuestStatsDtoImplCopyWith<$Res> {
  __$$GuestStatsDtoImplCopyWithImpl(
    _$GuestStatsDtoImpl _value,
    $Res Function(_$GuestStatsDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuestStatsDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? pending = null,
    Object? accepted = null,
    Object? rejected = null,
    Object? value = null,
    Object? medianWaitSecs = null,
  }) {
    return _then(
      _$GuestStatsDtoImpl(
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        pending: null == pending
            ? _value.pending
            : pending // ignore: cast_nullable_to_non_nullable
                  as int,
        accepted: null == accepted
            ? _value.accepted
            : accepted // ignore: cast_nullable_to_non_nullable
                  as int,
        rejected: null == rejected
            ? _value.rejected
            : rejected // ignore: cast_nullable_to_non_nullable
                  as int,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as int,
        medianWaitSecs: null == medianWaitSecs
            ? _value.medianWaitSecs
            : medianWaitSecs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GuestStatsDtoImpl implements _GuestStatsDto {
  const _$GuestStatsDtoImpl({
    this.total = 0,
    this.pending = 0,
    this.accepted = 0,
    this.rejected = 0,
    this.value = 0,
    this.medianWaitSecs = 0,
  });

  factory _$GuestStatsDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuestStatsDtoImplFromJson(json);

  @override
  @JsonKey()
  final int total;
  @override
  @JsonKey()
  final int pending;
  @override
  @JsonKey()
  final int accepted;
  @override
  @JsonKey()
  final int rejected;
  @override
  @JsonKey()
  final int value;
  @override
  @JsonKey()
  final int medianWaitSecs;

  @override
  String toString() {
    return 'GuestStatsDto(total: $total, pending: $pending, accepted: $accepted, rejected: $rejected, value: $value, medianWaitSecs: $medianWaitSecs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuestStatsDtoImpl &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.pending, pending) || other.pending == pending) &&
            (identical(other.accepted, accepted) ||
                other.accepted == accepted) &&
            (identical(other.rejected, rejected) ||
                other.rejected == rejected) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.medianWaitSecs, medianWaitSecs) ||
                other.medianWaitSecs == medianWaitSecs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    total,
    pending,
    accepted,
    rejected,
    value,
    medianWaitSecs,
  );

  /// Create a copy of GuestStatsDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuestStatsDtoImplCopyWith<_$GuestStatsDtoImpl> get copyWith =>
      __$$GuestStatsDtoImplCopyWithImpl<_$GuestStatsDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GuestStatsDtoImplToJson(this);
  }
}

abstract class _GuestStatsDto implements GuestStatsDto {
  const factory _GuestStatsDto({
    final int total,
    final int pending,
    final int accepted,
    final int rejected,
    final int value,
    final int medianWaitSecs,
  }) = _$GuestStatsDtoImpl;

  factory _GuestStatsDto.fromJson(Map<String, dynamic> json) =
      _$GuestStatsDtoImpl.fromJson;

  @override
  int get total;
  @override
  int get pending;
  @override
  int get accepted;
  @override
  int get rejected;
  @override
  int get value;
  @override
  int get medianWaitSecs;

  /// Create a copy of GuestStatsDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuestStatsDtoImplCopyWith<_$GuestStatsDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
