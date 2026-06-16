// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue_settings_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VenueSettingsDto _$VenueSettingsDtoFromJson(Map<String, dynamic> json) {
  return _VenueSettingsDto.fromJson(json);
}

/// @nodoc
mixin _$VenueSettingsDto {
  String get id => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String get legalName => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get receiptHeader => throw _privateConstructorUsedError;
  String get receiptFooter => throw _privateConstructorUsedError;
  bool get taxEnabled => throw _privateConstructorUsedError;
  int get taxRateBps => throw _privateConstructorUsedError;
  bool get serviceEnabled => throw _privateConstructorUsedError;
  String get serviceMode => throw _privateConstructorUsedError;
  int get serviceRateBps => throw _privateConstructorUsedError;
  int get serviceFixedAmount => throw _privateConstructorUsedError;
  int get businessDayStartHour => throw _privateConstructorUsedError;
  int get prepTargetMins => throw _privateConstructorUsedError;
  bool get guestOrderingEnabled => throw _privateConstructorUsedError;

  /// Serializes this VenueSettingsDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VenueSettingsDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VenueSettingsDtoCopyWith<VenueSettingsDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VenueSettingsDtoCopyWith<$Res> {
  factory $VenueSettingsDtoCopyWith(
    VenueSettingsDto value,
    $Res Function(VenueSettingsDto) then,
  ) = _$VenueSettingsDtoCopyWithImpl<$Res, VenueSettingsDto>;
  @useResult
  $Res call({
    String id,
    String displayName,
    String legalName,
    String address,
    String phone,
    String receiptHeader,
    String receiptFooter,
    bool taxEnabled,
    int taxRateBps,
    bool serviceEnabled,
    String serviceMode,
    int serviceRateBps,
    int serviceFixedAmount,
    int businessDayStartHour,
    int prepTargetMins,
    bool guestOrderingEnabled,
  });
}

/// @nodoc
class _$VenueSettingsDtoCopyWithImpl<$Res, $Val extends VenueSettingsDto>
    implements $VenueSettingsDtoCopyWith<$Res> {
  _$VenueSettingsDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VenueSettingsDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? legalName = null,
    Object? address = null,
    Object? phone = null,
    Object? receiptHeader = null,
    Object? receiptFooter = null,
    Object? taxEnabled = null,
    Object? taxRateBps = null,
    Object? serviceEnabled = null,
    Object? serviceMode = null,
    Object? serviceRateBps = null,
    Object? serviceFixedAmount = null,
    Object? businessDayStartHour = null,
    Object? prepTargetMins = null,
    Object? guestOrderingEnabled = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            legalName: null == legalName
                ? _value.legalName
                : legalName // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            receiptHeader: null == receiptHeader
                ? _value.receiptHeader
                : receiptHeader // ignore: cast_nullable_to_non_nullable
                      as String,
            receiptFooter: null == receiptFooter
                ? _value.receiptFooter
                : receiptFooter // ignore: cast_nullable_to_non_nullable
                      as String,
            taxEnabled: null == taxEnabled
                ? _value.taxEnabled
                : taxEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            taxRateBps: null == taxRateBps
                ? _value.taxRateBps
                : taxRateBps // ignore: cast_nullable_to_non_nullable
                      as int,
            serviceEnabled: null == serviceEnabled
                ? _value.serviceEnabled
                : serviceEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            serviceMode: null == serviceMode
                ? _value.serviceMode
                : serviceMode // ignore: cast_nullable_to_non_nullable
                      as String,
            serviceRateBps: null == serviceRateBps
                ? _value.serviceRateBps
                : serviceRateBps // ignore: cast_nullable_to_non_nullable
                      as int,
            serviceFixedAmount: null == serviceFixedAmount
                ? _value.serviceFixedAmount
                : serviceFixedAmount // ignore: cast_nullable_to_non_nullable
                      as int,
            businessDayStartHour: null == businessDayStartHour
                ? _value.businessDayStartHour
                : businessDayStartHour // ignore: cast_nullable_to_non_nullable
                      as int,
            prepTargetMins: null == prepTargetMins
                ? _value.prepTargetMins
                : prepTargetMins // ignore: cast_nullable_to_non_nullable
                      as int,
            guestOrderingEnabled: null == guestOrderingEnabled
                ? _value.guestOrderingEnabled
                : guestOrderingEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VenueSettingsDtoImplCopyWith<$Res>
    implements $VenueSettingsDtoCopyWith<$Res> {
  factory _$$VenueSettingsDtoImplCopyWith(
    _$VenueSettingsDtoImpl value,
    $Res Function(_$VenueSettingsDtoImpl) then,
  ) = __$$VenueSettingsDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String displayName,
    String legalName,
    String address,
    String phone,
    String receiptHeader,
    String receiptFooter,
    bool taxEnabled,
    int taxRateBps,
    bool serviceEnabled,
    String serviceMode,
    int serviceRateBps,
    int serviceFixedAmount,
    int businessDayStartHour,
    int prepTargetMins,
    bool guestOrderingEnabled,
  });
}

/// @nodoc
class __$$VenueSettingsDtoImplCopyWithImpl<$Res>
    extends _$VenueSettingsDtoCopyWithImpl<$Res, _$VenueSettingsDtoImpl>
    implements _$$VenueSettingsDtoImplCopyWith<$Res> {
  __$$VenueSettingsDtoImplCopyWithImpl(
    _$VenueSettingsDtoImpl _value,
    $Res Function(_$VenueSettingsDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VenueSettingsDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? legalName = null,
    Object? address = null,
    Object? phone = null,
    Object? receiptHeader = null,
    Object? receiptFooter = null,
    Object? taxEnabled = null,
    Object? taxRateBps = null,
    Object? serviceEnabled = null,
    Object? serviceMode = null,
    Object? serviceRateBps = null,
    Object? serviceFixedAmount = null,
    Object? businessDayStartHour = null,
    Object? prepTargetMins = null,
    Object? guestOrderingEnabled = null,
  }) {
    return _then(
      _$VenueSettingsDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        legalName: null == legalName
            ? _value.legalName
            : legalName // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        receiptHeader: null == receiptHeader
            ? _value.receiptHeader
            : receiptHeader // ignore: cast_nullable_to_non_nullable
                  as String,
        receiptFooter: null == receiptFooter
            ? _value.receiptFooter
            : receiptFooter // ignore: cast_nullable_to_non_nullable
                  as String,
        taxEnabled: null == taxEnabled
            ? _value.taxEnabled
            : taxEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        taxRateBps: null == taxRateBps
            ? _value.taxRateBps
            : taxRateBps // ignore: cast_nullable_to_non_nullable
                  as int,
        serviceEnabled: null == serviceEnabled
            ? _value.serviceEnabled
            : serviceEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        serviceMode: null == serviceMode
            ? _value.serviceMode
            : serviceMode // ignore: cast_nullable_to_non_nullable
                  as String,
        serviceRateBps: null == serviceRateBps
            ? _value.serviceRateBps
            : serviceRateBps // ignore: cast_nullable_to_non_nullable
                  as int,
        serviceFixedAmount: null == serviceFixedAmount
            ? _value.serviceFixedAmount
            : serviceFixedAmount // ignore: cast_nullable_to_non_nullable
                  as int,
        businessDayStartHour: null == businessDayStartHour
            ? _value.businessDayStartHour
            : businessDayStartHour // ignore: cast_nullable_to_non_nullable
                  as int,
        prepTargetMins: null == prepTargetMins
            ? _value.prepTargetMins
            : prepTargetMins // ignore: cast_nullable_to_non_nullable
                  as int,
        guestOrderingEnabled: null == guestOrderingEnabled
            ? _value.guestOrderingEnabled
            : guestOrderingEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VenueSettingsDtoImpl implements _VenueSettingsDto {
  const _$VenueSettingsDtoImpl({
    this.id = 'default',
    this.displayName = 'Warung Sebelah',
    this.legalName = '',
    this.address = '',
    this.phone = '',
    this.receiptHeader = '',
    this.receiptFooter = '',
    this.taxEnabled = false,
    this.taxRateBps = 1100,
    this.serviceEnabled = false,
    this.serviceMode = 'percent',
    this.serviceRateBps = 500,
    this.serviceFixedAmount = 0,
    this.businessDayStartHour = 4,
    this.prepTargetMins = 15,
    this.guestOrderingEnabled = false,
  });

  factory _$VenueSettingsDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$VenueSettingsDtoImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final String displayName;
  @override
  @JsonKey()
  final String legalName;
  @override
  @JsonKey()
  final String address;
  @override
  @JsonKey()
  final String phone;
  @override
  @JsonKey()
  final String receiptHeader;
  @override
  @JsonKey()
  final String receiptFooter;
  @override
  @JsonKey()
  final bool taxEnabled;
  @override
  @JsonKey()
  final int taxRateBps;
  @override
  @JsonKey()
  final bool serviceEnabled;
  @override
  @JsonKey()
  final String serviceMode;
  @override
  @JsonKey()
  final int serviceRateBps;
  @override
  @JsonKey()
  final int serviceFixedAmount;
  @override
  @JsonKey()
  final int businessDayStartHour;
  @override
  @JsonKey()
  final int prepTargetMins;
  @override
  @JsonKey()
  final bool guestOrderingEnabled;

  @override
  String toString() {
    return 'VenueSettingsDto(id: $id, displayName: $displayName, legalName: $legalName, address: $address, phone: $phone, receiptHeader: $receiptHeader, receiptFooter: $receiptFooter, taxEnabled: $taxEnabled, taxRateBps: $taxRateBps, serviceEnabled: $serviceEnabled, serviceMode: $serviceMode, serviceRateBps: $serviceRateBps, serviceFixedAmount: $serviceFixedAmount, businessDayStartHour: $businessDayStartHour, prepTargetMins: $prepTargetMins, guestOrderingEnabled: $guestOrderingEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VenueSettingsDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.legalName, legalName) ||
                other.legalName == legalName) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.receiptHeader, receiptHeader) ||
                other.receiptHeader == receiptHeader) &&
            (identical(other.receiptFooter, receiptFooter) ||
                other.receiptFooter == receiptFooter) &&
            (identical(other.taxEnabled, taxEnabled) ||
                other.taxEnabled == taxEnabled) &&
            (identical(other.taxRateBps, taxRateBps) ||
                other.taxRateBps == taxRateBps) &&
            (identical(other.serviceEnabled, serviceEnabled) ||
                other.serviceEnabled == serviceEnabled) &&
            (identical(other.serviceMode, serviceMode) ||
                other.serviceMode == serviceMode) &&
            (identical(other.serviceRateBps, serviceRateBps) ||
                other.serviceRateBps == serviceRateBps) &&
            (identical(other.serviceFixedAmount, serviceFixedAmount) ||
                other.serviceFixedAmount == serviceFixedAmount) &&
            (identical(other.businessDayStartHour, businessDayStartHour) ||
                other.businessDayStartHour == businessDayStartHour) &&
            (identical(other.prepTargetMins, prepTargetMins) ||
                other.prepTargetMins == prepTargetMins) &&
            (identical(other.guestOrderingEnabled, guestOrderingEnabled) ||
                other.guestOrderingEnabled == guestOrderingEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    displayName,
    legalName,
    address,
    phone,
    receiptHeader,
    receiptFooter,
    taxEnabled,
    taxRateBps,
    serviceEnabled,
    serviceMode,
    serviceRateBps,
    serviceFixedAmount,
    businessDayStartHour,
    prepTargetMins,
    guestOrderingEnabled,
  );

  /// Create a copy of VenueSettingsDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VenueSettingsDtoImplCopyWith<_$VenueSettingsDtoImpl> get copyWith =>
      __$$VenueSettingsDtoImplCopyWithImpl<_$VenueSettingsDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VenueSettingsDtoImplToJson(this);
  }
}

abstract class _VenueSettingsDto implements VenueSettingsDto {
  const factory _VenueSettingsDto({
    final String id,
    final String displayName,
    final String legalName,
    final String address,
    final String phone,
    final String receiptHeader,
    final String receiptFooter,
    final bool taxEnabled,
    final int taxRateBps,
    final bool serviceEnabled,
    final String serviceMode,
    final int serviceRateBps,
    final int serviceFixedAmount,
    final int businessDayStartHour,
    final int prepTargetMins,
    final bool guestOrderingEnabled,
  }) = _$VenueSettingsDtoImpl;

  factory _VenueSettingsDto.fromJson(Map<String, dynamic> json) =
      _$VenueSettingsDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get displayName;
  @override
  String get legalName;
  @override
  String get address;
  @override
  String get phone;
  @override
  String get receiptHeader;
  @override
  String get receiptFooter;
  @override
  bool get taxEnabled;
  @override
  int get taxRateBps;
  @override
  bool get serviceEnabled;
  @override
  String get serviceMode;
  @override
  int get serviceRateBps;
  @override
  int get serviceFixedAmount;
  @override
  int get businessDayStartHour;
  @override
  int get prepTargetMins;
  @override
  bool get guestOrderingEnabled;

  /// Create a copy of VenueSettingsDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VenueSettingsDtoImplCopyWith<_$VenueSettingsDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
