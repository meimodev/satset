// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CartModifierDto _$CartModifierDtoFromJson(Map<String, dynamic> json) {
  return _CartModifierDto.fromJson(json);
}

/// @nodoc
mixin _$CartModifierDto {
  String get groupId => throw _privateConstructorUsedError;
  String get optionId => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  int get priceDelta => throw _privateConstructorUsedError;

  /// Serializes this CartModifierDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CartModifierDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CartModifierDtoCopyWith<CartModifierDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CartModifierDtoCopyWith<$Res> {
  factory $CartModifierDtoCopyWith(
    CartModifierDto value,
    $Res Function(CartModifierDto) then,
  ) = _$CartModifierDtoCopyWithImpl<$Res, CartModifierDto>;
  @useResult
  $Res call({String groupId, String optionId, String label, int priceDelta});
}

/// @nodoc
class _$CartModifierDtoCopyWithImpl<$Res, $Val extends CartModifierDto>
    implements $CartModifierDtoCopyWith<$Res> {
  _$CartModifierDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CartModifierDto
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
abstract class _$$CartModifierDtoImplCopyWith<$Res>
    implements $CartModifierDtoCopyWith<$Res> {
  factory _$$CartModifierDtoImplCopyWith(
    _$CartModifierDtoImpl value,
    $Res Function(_$CartModifierDtoImpl) then,
  ) = __$$CartModifierDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String groupId, String optionId, String label, int priceDelta});
}

/// @nodoc
class __$$CartModifierDtoImplCopyWithImpl<$Res>
    extends _$CartModifierDtoCopyWithImpl<$Res, _$CartModifierDtoImpl>
    implements _$$CartModifierDtoImplCopyWith<$Res> {
  __$$CartModifierDtoImplCopyWithImpl(
    _$CartModifierDtoImpl _value,
    $Res Function(_$CartModifierDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CartModifierDto
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
      _$CartModifierDtoImpl(
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
class _$CartModifierDtoImpl implements _CartModifierDto {
  const _$CartModifierDtoImpl({
    required this.groupId,
    required this.optionId,
    required this.label,
    required this.priceDelta,
  });

  factory _$CartModifierDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CartModifierDtoImplFromJson(json);

  @override
  final String groupId;
  @override
  final String optionId;
  @override
  final String label;
  @override
  final int priceDelta;

  @override
  String toString() {
    return 'CartModifierDto(groupId: $groupId, optionId: $optionId, label: $label, priceDelta: $priceDelta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CartModifierDtoImpl &&
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

  /// Create a copy of CartModifierDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CartModifierDtoImplCopyWith<_$CartModifierDtoImpl> get copyWith =>
      __$$CartModifierDtoImplCopyWithImpl<_$CartModifierDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CartModifierDtoImplToJson(this);
  }
}

abstract class _CartModifierDto implements CartModifierDto {
  const factory _CartModifierDto({
    required final String groupId,
    required final String optionId,
    required final String label,
    required final int priceDelta,
  }) = _$CartModifierDtoImpl;

  factory _CartModifierDto.fromJson(Map<String, dynamic> json) =
      _$CartModifierDtoImpl.fromJson;

  @override
  String get groupId;
  @override
  String get optionId;
  @override
  String get label;
  @override
  int get priceDelta;

  /// Create a copy of CartModifierDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CartModifierDtoImplCopyWith<_$CartModifierDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CartLineDto _$CartLineDtoFromJson(Map<String, dynamic> json) {
  return _CartLineDto.fromJson(json);
}

/// @nodoc
mixin _$CartLineDto {
  String get itemId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get variantId => throw _privateConstructorUsedError;
  String get variantName => throw _privateConstructorUsedError;
  List<CartModifierDto> get modifiers => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  String get course => throw _privateConstructorUsedError;
  int get qty => throw _privateConstructorUsedError;
  int get unitPrice => throw _privateConstructorUsedError;

  /// Serializes this CartLineDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CartLineDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CartLineDtoCopyWith<CartLineDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CartLineDtoCopyWith<$Res> {
  factory $CartLineDtoCopyWith(
    CartLineDto value,
    $Res Function(CartLineDto) then,
  ) = _$CartLineDtoCopyWithImpl<$Res, CartLineDto>;
  @useResult
  $Res call({
    String itemId,
    String name,
    String variantId,
    String variantName,
    List<CartModifierDto> modifiers,
    String? note,
    String course,
    int qty,
    int unitPrice,
  });
}

/// @nodoc
class _$CartLineDtoCopyWithImpl<$Res, $Val extends CartLineDto>
    implements $CartLineDtoCopyWith<$Res> {
  _$CartLineDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CartLineDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? name = null,
    Object? variantId = null,
    Object? variantName = null,
    Object? modifiers = null,
    Object? note = freezed,
    Object? course = null,
    Object? qty = null,
    Object? unitPrice = null,
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
            variantId: null == variantId
                ? _value.variantId
                : variantId // ignore: cast_nullable_to_non_nullable
                      as String,
            variantName: null == variantName
                ? _value.variantName
                : variantName // ignore: cast_nullable_to_non_nullable
                      as String,
            modifiers: null == modifiers
                ? _value.modifiers
                : modifiers // ignore: cast_nullable_to_non_nullable
                      as List<CartModifierDto>,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            course: null == course
                ? _value.course
                : course // ignore: cast_nullable_to_non_nullable
                      as String,
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
            unitPrice: null == unitPrice
                ? _value.unitPrice
                : unitPrice // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CartLineDtoImplCopyWith<$Res>
    implements $CartLineDtoCopyWith<$Res> {
  factory _$$CartLineDtoImplCopyWith(
    _$CartLineDtoImpl value,
    $Res Function(_$CartLineDtoImpl) then,
  ) = __$$CartLineDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String itemId,
    String name,
    String variantId,
    String variantName,
    List<CartModifierDto> modifiers,
    String? note,
    String course,
    int qty,
    int unitPrice,
  });
}

/// @nodoc
class __$$CartLineDtoImplCopyWithImpl<$Res>
    extends _$CartLineDtoCopyWithImpl<$Res, _$CartLineDtoImpl>
    implements _$$CartLineDtoImplCopyWith<$Res> {
  __$$CartLineDtoImplCopyWithImpl(
    _$CartLineDtoImpl _value,
    $Res Function(_$CartLineDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CartLineDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? name = null,
    Object? variantId = null,
    Object? variantName = null,
    Object? modifiers = null,
    Object? note = freezed,
    Object? course = null,
    Object? qty = null,
    Object? unitPrice = null,
  }) {
    return _then(
      _$CartLineDtoImpl(
        itemId: null == itemId
            ? _value.itemId
            : itemId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        variantId: null == variantId
            ? _value.variantId
            : variantId // ignore: cast_nullable_to_non_nullable
                  as String,
        variantName: null == variantName
            ? _value.variantName
            : variantName // ignore: cast_nullable_to_non_nullable
                  as String,
        modifiers: null == modifiers
            ? _value._modifiers
            : modifiers // ignore: cast_nullable_to_non_nullable
                  as List<CartModifierDto>,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        course: null == course
            ? _value.course
            : course // ignore: cast_nullable_to_non_nullable
                  as String,
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
        unitPrice: null == unitPrice
            ? _value.unitPrice
            : unitPrice // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CartLineDtoImpl implements _CartLineDto {
  const _$CartLineDtoImpl({
    required this.itemId,
    required this.name,
    required this.variantId,
    required this.variantName,
    required final List<CartModifierDto> modifiers,
    required this.note,
    required this.course,
    required this.qty,
    required this.unitPrice,
  }) : _modifiers = modifiers;

  factory _$CartLineDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CartLineDtoImplFromJson(json);

  @override
  final String itemId;
  @override
  final String name;
  @override
  final String variantId;
  @override
  final String variantName;
  final List<CartModifierDto> _modifiers;
  @override
  List<CartModifierDto> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @override
  final String? note;
  @override
  final String course;
  @override
  final int qty;
  @override
  final int unitPrice;

  @override
  String toString() {
    return 'CartLineDto(itemId: $itemId, name: $name, variantId: $variantId, variantName: $variantName, modifiers: $modifiers, note: $note, course: $course, qty: $qty, unitPrice: $unitPrice)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CartLineDtoImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.variantId, variantId) ||
                other.variantId == variantId) &&
            (identical(other.variantName, variantName) ||
                other.variantName == variantName) &&
            const DeepCollectionEquality().equals(
              other._modifiers,
              _modifiers,
            ) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.course, course) || other.course == course) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    itemId,
    name,
    variantId,
    variantName,
    const DeepCollectionEquality().hash(_modifiers),
    note,
    course,
    qty,
    unitPrice,
  );

  /// Create a copy of CartLineDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CartLineDtoImplCopyWith<_$CartLineDtoImpl> get copyWith =>
      __$$CartLineDtoImplCopyWithImpl<_$CartLineDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CartLineDtoImplToJson(this);
  }
}

abstract class _CartLineDto implements CartLineDto {
  const factory _CartLineDto({
    required final String itemId,
    required final String name,
    required final String variantId,
    required final String variantName,
    required final List<CartModifierDto> modifiers,
    required final String? note,
    required final String course,
    required final int qty,
    required final int unitPrice,
  }) = _$CartLineDtoImpl;

  factory _CartLineDto.fromJson(Map<String, dynamic> json) =
      _$CartLineDtoImpl.fromJson;

  @override
  String get itemId;
  @override
  String get name;
  @override
  String get variantId;
  @override
  String get variantName;
  @override
  List<CartModifierDto> get modifiers;
  @override
  String? get note;
  @override
  String get course;
  @override
  int get qty;
  @override
  int get unitPrice;

  /// Create a copy of CartLineDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CartLineDtoImplCopyWith<_$CartLineDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SubmitOrderRequestDto _$SubmitOrderRequestDtoFromJson(
  Map<String, dynamic> json,
) {
  return _SubmitOrderRequestDto.fromJson(json);
}

/// @nodoc
mixin _$SubmitOrderRequestDto {
  String get tableId => throw _privateConstructorUsedError;
  String get idempotencyKey => throw _privateConstructorUsedError;
  List<CartLineDto> get lines => throw _privateConstructorUsedError;
  String? get actorId => throw _privateConstructorUsedError;

  /// Serializes this SubmitOrderRequestDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubmitOrderRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubmitOrderRequestDtoCopyWith<SubmitOrderRequestDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubmitOrderRequestDtoCopyWith<$Res> {
  factory $SubmitOrderRequestDtoCopyWith(
    SubmitOrderRequestDto value,
    $Res Function(SubmitOrderRequestDto) then,
  ) = _$SubmitOrderRequestDtoCopyWithImpl<$Res, SubmitOrderRequestDto>;
  @useResult
  $Res call({
    String tableId,
    String idempotencyKey,
    List<CartLineDto> lines,
    String? actorId,
  });
}

/// @nodoc
class _$SubmitOrderRequestDtoCopyWithImpl<
  $Res,
  $Val extends SubmitOrderRequestDto
>
    implements $SubmitOrderRequestDtoCopyWith<$Res> {
  _$SubmitOrderRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubmitOrderRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tableId = null,
    Object? idempotencyKey = null,
    Object? lines = null,
    Object? actorId = freezed,
  }) {
    return _then(
      _value.copyWith(
            tableId: null == tableId
                ? _value.tableId
                : tableId // ignore: cast_nullable_to_non_nullable
                      as String,
            idempotencyKey: null == idempotencyKey
                ? _value.idempotencyKey
                : idempotencyKey // ignore: cast_nullable_to_non_nullable
                      as String,
            lines: null == lines
                ? _value.lines
                : lines // ignore: cast_nullable_to_non_nullable
                      as List<CartLineDto>,
            actorId: freezed == actorId
                ? _value.actorId
                : actorId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SubmitOrderRequestDtoImplCopyWith<$Res>
    implements $SubmitOrderRequestDtoCopyWith<$Res> {
  factory _$$SubmitOrderRequestDtoImplCopyWith(
    _$SubmitOrderRequestDtoImpl value,
    $Res Function(_$SubmitOrderRequestDtoImpl) then,
  ) = __$$SubmitOrderRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String tableId,
    String idempotencyKey,
    List<CartLineDto> lines,
    String? actorId,
  });
}

/// @nodoc
class __$$SubmitOrderRequestDtoImplCopyWithImpl<$Res>
    extends
        _$SubmitOrderRequestDtoCopyWithImpl<$Res, _$SubmitOrderRequestDtoImpl>
    implements _$$SubmitOrderRequestDtoImplCopyWith<$Res> {
  __$$SubmitOrderRequestDtoImplCopyWithImpl(
    _$SubmitOrderRequestDtoImpl _value,
    $Res Function(_$SubmitOrderRequestDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SubmitOrderRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tableId = null,
    Object? idempotencyKey = null,
    Object? lines = null,
    Object? actorId = freezed,
  }) {
    return _then(
      _$SubmitOrderRequestDtoImpl(
        tableId: null == tableId
            ? _value.tableId
            : tableId // ignore: cast_nullable_to_non_nullable
                  as String,
        idempotencyKey: null == idempotencyKey
            ? _value.idempotencyKey
            : idempotencyKey // ignore: cast_nullable_to_non_nullable
                  as String,
        lines: null == lines
            ? _value._lines
            : lines // ignore: cast_nullable_to_non_nullable
                  as List<CartLineDto>,
        actorId: freezed == actorId
            ? _value.actorId
            : actorId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubmitOrderRequestDtoImpl implements _SubmitOrderRequestDto {
  const _$SubmitOrderRequestDtoImpl({
    required this.tableId,
    required this.idempotencyKey,
    required final List<CartLineDto> lines,
    this.actorId,
  }) : _lines = lines;

  factory _$SubmitOrderRequestDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubmitOrderRequestDtoImplFromJson(json);

  @override
  final String tableId;
  @override
  final String idempotencyKey;
  final List<CartLineDto> _lines;
  @override
  List<CartLineDto> get lines {
    if (_lines is EqualUnmodifiableListView) return _lines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lines);
  }

  @override
  final String? actorId;

  @override
  String toString() {
    return 'SubmitOrderRequestDto(tableId: $tableId, idempotencyKey: $idempotencyKey, lines: $lines, actorId: $actorId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubmitOrderRequestDtoImpl &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.idempotencyKey, idempotencyKey) ||
                other.idempotencyKey == idempotencyKey) &&
            const DeepCollectionEquality().equals(other._lines, _lines) &&
            (identical(other.actorId, actorId) || other.actorId == actorId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    tableId,
    idempotencyKey,
    const DeepCollectionEquality().hash(_lines),
    actorId,
  );

  /// Create a copy of SubmitOrderRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubmitOrderRequestDtoImplCopyWith<_$SubmitOrderRequestDtoImpl>
  get copyWith =>
      __$$SubmitOrderRequestDtoImplCopyWithImpl<_$SubmitOrderRequestDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SubmitOrderRequestDtoImplToJson(this);
  }
}

abstract class _SubmitOrderRequestDto implements SubmitOrderRequestDto {
  const factory _SubmitOrderRequestDto({
    required final String tableId,
    required final String idempotencyKey,
    required final List<CartLineDto> lines,
    final String? actorId,
  }) = _$SubmitOrderRequestDtoImpl;

  factory _SubmitOrderRequestDto.fromJson(Map<String, dynamic> json) =
      _$SubmitOrderRequestDtoImpl.fromJson;

  @override
  String get tableId;
  @override
  String get idempotencyKey;
  @override
  List<CartLineDto> get lines;
  @override
  String? get actorId;

  /// Create a copy of SubmitOrderRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubmitOrderRequestDtoImplCopyWith<_$SubmitOrderRequestDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}

SubmitOrderResponseDto _$SubmitOrderResponseDtoFromJson(
  Map<String, dynamic> json,
) {
  return _SubmitOrderResponseDto.fromJson(json);
}

/// @nodoc
mixin _$SubmitOrderResponseDto {
  List<String> get ticketIds => throw _privateConstructorUsedError;

  /// The visit the lines were filed under. Lets the sending device seed the
  /// table's currentVisitId immediately, before the tableUpdated echo lands,
  /// so its lines resolve without a flash of empty. See ADR-0034.
  String? get visitId => throw _privateConstructorUsedError;

  /// Lines the server refused for want of ingredients (ADR-0038). Only the
  /// offending lines are dropped — the rest of the order still lands — so
  /// this must be surfaced, or lines vanish silently.
  List<RejectedLineDto> get rejected => throw _privateConstructorUsedError;

  /// Serializes this SubmitOrderResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubmitOrderResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubmitOrderResponseDtoCopyWith<SubmitOrderResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubmitOrderResponseDtoCopyWith<$Res> {
  factory $SubmitOrderResponseDtoCopyWith(
    SubmitOrderResponseDto value,
    $Res Function(SubmitOrderResponseDto) then,
  ) = _$SubmitOrderResponseDtoCopyWithImpl<$Res, SubmitOrderResponseDto>;
  @useResult
  $Res call({
    List<String> ticketIds,
    String? visitId,
    List<RejectedLineDto> rejected,
  });
}

/// @nodoc
class _$SubmitOrderResponseDtoCopyWithImpl<
  $Res,
  $Val extends SubmitOrderResponseDto
>
    implements $SubmitOrderResponseDtoCopyWith<$Res> {
  _$SubmitOrderResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubmitOrderResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ticketIds = null,
    Object? visitId = freezed,
    Object? rejected = null,
  }) {
    return _then(
      _value.copyWith(
            ticketIds: null == ticketIds
                ? _value.ticketIds
                : ticketIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            visitId: freezed == visitId
                ? _value.visitId
                : visitId // ignore: cast_nullable_to_non_nullable
                      as String?,
            rejected: null == rejected
                ? _value.rejected
                : rejected // ignore: cast_nullable_to_non_nullable
                      as List<RejectedLineDto>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SubmitOrderResponseDtoImplCopyWith<$Res>
    implements $SubmitOrderResponseDtoCopyWith<$Res> {
  factory _$$SubmitOrderResponseDtoImplCopyWith(
    _$SubmitOrderResponseDtoImpl value,
    $Res Function(_$SubmitOrderResponseDtoImpl) then,
  ) = __$$SubmitOrderResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<String> ticketIds,
    String? visitId,
    List<RejectedLineDto> rejected,
  });
}

/// @nodoc
class __$$SubmitOrderResponseDtoImplCopyWithImpl<$Res>
    extends
        _$SubmitOrderResponseDtoCopyWithImpl<$Res, _$SubmitOrderResponseDtoImpl>
    implements _$$SubmitOrderResponseDtoImplCopyWith<$Res> {
  __$$SubmitOrderResponseDtoImplCopyWithImpl(
    _$SubmitOrderResponseDtoImpl _value,
    $Res Function(_$SubmitOrderResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SubmitOrderResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ticketIds = null,
    Object? visitId = freezed,
    Object? rejected = null,
  }) {
    return _then(
      _$SubmitOrderResponseDtoImpl(
        ticketIds: null == ticketIds
            ? _value._ticketIds
            : ticketIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        visitId: freezed == visitId
            ? _value.visitId
            : visitId // ignore: cast_nullable_to_non_nullable
                  as String?,
        rejected: null == rejected
            ? _value._rejected
            : rejected // ignore: cast_nullable_to_non_nullable
                  as List<RejectedLineDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubmitOrderResponseDtoImpl implements _SubmitOrderResponseDto {
  const _$SubmitOrderResponseDtoImpl({
    required final List<String> ticketIds,
    this.visitId,
    final List<RejectedLineDto> rejected = const <RejectedLineDto>[],
  }) : _ticketIds = ticketIds,
       _rejected = rejected;

  factory _$SubmitOrderResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubmitOrderResponseDtoImplFromJson(json);

  final List<String> _ticketIds;
  @override
  List<String> get ticketIds {
    if (_ticketIds is EqualUnmodifiableListView) return _ticketIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ticketIds);
  }

  /// The visit the lines were filed under. Lets the sending device seed the
  /// table's currentVisitId immediately, before the tableUpdated echo lands,
  /// so its lines resolve without a flash of empty. See ADR-0034.
  @override
  final String? visitId;

  /// Lines the server refused for want of ingredients (ADR-0038). Only the
  /// offending lines are dropped — the rest of the order still lands — so
  /// this must be surfaced, or lines vanish silently.
  final List<RejectedLineDto> _rejected;

  /// Lines the server refused for want of ingredients (ADR-0038). Only the
  /// offending lines are dropped — the rest of the order still lands — so
  /// this must be surfaced, or lines vanish silently.
  @override
  @JsonKey()
  List<RejectedLineDto> get rejected {
    if (_rejected is EqualUnmodifiableListView) return _rejected;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rejected);
  }

  @override
  String toString() {
    return 'SubmitOrderResponseDto(ticketIds: $ticketIds, visitId: $visitId, rejected: $rejected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubmitOrderResponseDtoImpl &&
            const DeepCollectionEquality().equals(
              other._ticketIds,
              _ticketIds,
            ) &&
            (identical(other.visitId, visitId) || other.visitId == visitId) &&
            const DeepCollectionEquality().equals(other._rejected, _rejected));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_ticketIds),
    visitId,
    const DeepCollectionEquality().hash(_rejected),
  );

  /// Create a copy of SubmitOrderResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubmitOrderResponseDtoImplCopyWith<_$SubmitOrderResponseDtoImpl>
  get copyWith =>
      __$$SubmitOrderResponseDtoImplCopyWithImpl<_$SubmitOrderResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SubmitOrderResponseDtoImplToJson(this);
  }
}

abstract class _SubmitOrderResponseDto implements SubmitOrderResponseDto {
  const factory _SubmitOrderResponseDto({
    required final List<String> ticketIds,
    final String? visitId,
    final List<RejectedLineDto> rejected,
  }) = _$SubmitOrderResponseDtoImpl;

  factory _SubmitOrderResponseDto.fromJson(Map<String, dynamic> json) =
      _$SubmitOrderResponseDtoImpl.fromJson;

  @override
  List<String> get ticketIds;

  /// The visit the lines were filed under. Lets the sending device seed the
  /// table's currentVisitId immediately, before the tableUpdated echo lands,
  /// so its lines resolve without a flash of empty. See ADR-0034.
  @override
  String? get visitId;

  /// Lines the server refused for want of ingredients (ADR-0038). Only the
  /// offending lines are dropped — the rest of the order still lands — so
  /// this must be surfaced, or lines vanish silently.
  @override
  List<RejectedLineDto> get rejected;

  /// Create a copy of SubmitOrderResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubmitOrderResponseDtoImplCopyWith<_$SubmitOrderResponseDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}

RejectedLineDto _$RejectedLineDtoFromJson(Map<String, dynamic> json) {
  return _RejectedLineDto.fromJson(json);
}

/// @nodoc
mixin _$RejectedLineDto {
  String get itemId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get variantName => throw _privateConstructorUsedError;

  /// Names of the bahan that fell short — so the waiter is told *what* ran
  /// out rather than just "no".
  List<String> get ingredients => throw _privateConstructorUsedError;

  /// Serializes this RejectedLineDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RejectedLineDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RejectedLineDtoCopyWith<RejectedLineDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RejectedLineDtoCopyWith<$Res> {
  factory $RejectedLineDtoCopyWith(
    RejectedLineDto value,
    $Res Function(RejectedLineDto) then,
  ) = _$RejectedLineDtoCopyWithImpl<$Res, RejectedLineDto>;
  @useResult
  $Res call({
    String itemId,
    String name,
    String variantName,
    List<String> ingredients,
  });
}

/// @nodoc
class _$RejectedLineDtoCopyWithImpl<$Res, $Val extends RejectedLineDto>
    implements $RejectedLineDtoCopyWith<$Res> {
  _$RejectedLineDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RejectedLineDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? name = null,
    Object? variantName = null,
    Object? ingredients = null,
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
            variantName: null == variantName
                ? _value.variantName
                : variantName // ignore: cast_nullable_to_non_nullable
                      as String,
            ingredients: null == ingredients
                ? _value.ingredients
                : ingredients // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RejectedLineDtoImplCopyWith<$Res>
    implements $RejectedLineDtoCopyWith<$Res> {
  factory _$$RejectedLineDtoImplCopyWith(
    _$RejectedLineDtoImpl value,
    $Res Function(_$RejectedLineDtoImpl) then,
  ) = __$$RejectedLineDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String itemId,
    String name,
    String variantName,
    List<String> ingredients,
  });
}

/// @nodoc
class __$$RejectedLineDtoImplCopyWithImpl<$Res>
    extends _$RejectedLineDtoCopyWithImpl<$Res, _$RejectedLineDtoImpl>
    implements _$$RejectedLineDtoImplCopyWith<$Res> {
  __$$RejectedLineDtoImplCopyWithImpl(
    _$RejectedLineDtoImpl _value,
    $Res Function(_$RejectedLineDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RejectedLineDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? name = null,
    Object? variantName = null,
    Object? ingredients = null,
  }) {
    return _then(
      _$RejectedLineDtoImpl(
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
        ingredients: null == ingredients
            ? _value._ingredients
            : ingredients // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RejectedLineDtoImpl implements _RejectedLineDto {
  const _$RejectedLineDtoImpl({
    required this.itemId,
    this.name = '',
    this.variantName = '',
    final List<String> ingredients = const <String>[],
  }) : _ingredients = ingredients;

  factory _$RejectedLineDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$RejectedLineDtoImplFromJson(json);

  @override
  final String itemId;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String variantName;

  /// Names of the bahan that fell short — so the waiter is told *what* ran
  /// out rather than just "no".
  final List<String> _ingredients;

  /// Names of the bahan that fell short — so the waiter is told *what* ran
  /// out rather than just "no".
  @override
  @JsonKey()
  List<String> get ingredients {
    if (_ingredients is EqualUnmodifiableListView) return _ingredients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ingredients);
  }

  @override
  String toString() {
    return 'RejectedLineDto(itemId: $itemId, name: $name, variantName: $variantName, ingredients: $ingredients)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RejectedLineDtoImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.variantName, variantName) ||
                other.variantName == variantName) &&
            const DeepCollectionEquality().equals(
              other._ingredients,
              _ingredients,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    itemId,
    name,
    variantName,
    const DeepCollectionEquality().hash(_ingredients),
  );

  /// Create a copy of RejectedLineDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RejectedLineDtoImplCopyWith<_$RejectedLineDtoImpl> get copyWith =>
      __$$RejectedLineDtoImplCopyWithImpl<_$RejectedLineDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RejectedLineDtoImplToJson(this);
  }
}

abstract class _RejectedLineDto implements RejectedLineDto {
  const factory _RejectedLineDto({
    required final String itemId,
    final String name,
    final String variantName,
    final List<String> ingredients,
  }) = _$RejectedLineDtoImpl;

  factory _RejectedLineDto.fromJson(Map<String, dynamic> json) =
      _$RejectedLineDtoImpl.fromJson;

  @override
  String get itemId;
  @override
  String get name;
  @override
  String get variantName;

  /// Names of the bahan that fell short — so the waiter is told *what* ran
  /// out rather than just "no".
  @override
  List<String> get ingredients;

  /// Create a copy of RejectedLineDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RejectedLineDtoImplCopyWith<_$RejectedLineDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
