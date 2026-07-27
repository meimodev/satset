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
  String get receiptFooter =>
      throw _privateConstructorUsedError; // Receipt branding block (ADR-0033). Logo bytes are NOT carried here — they
  // ride the side-endpoint /venue/logo, cache-busted by logoRev.
  String get receiptTagline => throw _privateConstructorUsedError;
  String get receiptSocial => throw _privateConstructorUsedError;
  String get receiptThankYou => throw _privateConstructorUsedError;
  String get receiptQrUrl => throw _privateConstructorUsedError;
  String get receiptQrCaption => throw _privateConstructorUsedError;
  int get logoRev => throw _privateConstructorUsedError;
  bool get taxEnabled => throw _privateConstructorUsedError;
  int get taxRateBps => throw _privateConstructorUsedError;
  bool get serviceEnabled => throw _privateConstructorUsedError;
  String get serviceMode => throw _privateConstructorUsedError;
  int get serviceRateBps => throw _privateConstructorUsedError;
  int get serviceFixedAmount => throw _privateConstructorUsedError;

  /// Where a whole-order discount sits in the stack (ADR-0038). Default true
  /// = DPP-correct (the discount reduces the base service and tax compute
  /// from). Line discounts are always pre-tax and ignore this.
  bool get taxAfterDiscount => throw _privateConstructorUsedError;
  int get businessDayStartHour => throw _privateConstructorUsedError;
  int get prepTargetMins =>
      throw _privateConstructorUsedError; // Service timings (ADR-0043/0044). `prepTargetMins` above is now the
  // venue *default* every item with a null `prepTime` inherits.
  int get pickupTargetMins => throw _privateConstructorUsedError;
  int get ungreetedMins => throw _privateConstructorUsedError;
  int get ungreetedEscalateMins => throw _privateConstructorUsedError;
  int get longStayMins => throw _privateConstructorUsedError;
  int get idleTableMins => throw _privateConstructorUsedError;
  int get reservationGraceMins => throw _privateConstructorUsedError;

  /// "Belum ditinjau" — how long a guest-sent order (ADR-0028) may sit
  /// unreviewed before the floor card goes critical. Visual only, never a cue.
  int get pendingReviewMins => throw _privateConstructorUsedError;
  bool get ungreetedAlertEnabled => throw _privateConstructorUsedError;
  bool get pickupAlertEnabled => throw _privateConstructorUsedError;
  bool get guestOrderingEnabled =>
      throw _privateConstructorUsedError; // Per-event alert sound choice (ADR-0035). Each holds a preset id from
  // `alertSoundPresets` ('none' = silent). Defaults reproduce ADR-0007's
  // original fixed cues exactly.
  String get soundNewOrder => throw _privateConstructorUsedError;
  String get soundReady => throw _privateConstructorUsedError;
  String get soundVoid => throw _privateConstructorUsedError;
  String get soundOverdue => throw _privateConstructorUsedError;
  String get soundUngreeted => throw _privateConstructorUsedError;
  String get soundPickup => throw _privateConstructorUsedError;

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
    String receiptTagline,
    String receiptSocial,
    String receiptThankYou,
    String receiptQrUrl,
    String receiptQrCaption,
    int logoRev,
    bool taxEnabled,
    int taxRateBps,
    bool serviceEnabled,
    String serviceMode,
    int serviceRateBps,
    int serviceFixedAmount,
    bool taxAfterDiscount,
    int businessDayStartHour,
    int prepTargetMins,
    int pickupTargetMins,
    int ungreetedMins,
    int ungreetedEscalateMins,
    int longStayMins,
    int idleTableMins,
    int reservationGraceMins,
    int pendingReviewMins,
    bool ungreetedAlertEnabled,
    bool pickupAlertEnabled,
    bool guestOrderingEnabled,
    String soundNewOrder,
    String soundReady,
    String soundVoid,
    String soundOverdue,
    String soundUngreeted,
    String soundPickup,
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
    Object? receiptTagline = null,
    Object? receiptSocial = null,
    Object? receiptThankYou = null,
    Object? receiptQrUrl = null,
    Object? receiptQrCaption = null,
    Object? logoRev = null,
    Object? taxEnabled = null,
    Object? taxRateBps = null,
    Object? serviceEnabled = null,
    Object? serviceMode = null,
    Object? serviceRateBps = null,
    Object? serviceFixedAmount = null,
    Object? taxAfterDiscount = null,
    Object? businessDayStartHour = null,
    Object? prepTargetMins = null,
    Object? pickupTargetMins = null,
    Object? ungreetedMins = null,
    Object? ungreetedEscalateMins = null,
    Object? longStayMins = null,
    Object? idleTableMins = null,
    Object? reservationGraceMins = null,
    Object? pendingReviewMins = null,
    Object? ungreetedAlertEnabled = null,
    Object? pickupAlertEnabled = null,
    Object? guestOrderingEnabled = null,
    Object? soundNewOrder = null,
    Object? soundReady = null,
    Object? soundVoid = null,
    Object? soundOverdue = null,
    Object? soundUngreeted = null,
    Object? soundPickup = null,
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
            receiptTagline: null == receiptTagline
                ? _value.receiptTagline
                : receiptTagline // ignore: cast_nullable_to_non_nullable
                      as String,
            receiptSocial: null == receiptSocial
                ? _value.receiptSocial
                : receiptSocial // ignore: cast_nullable_to_non_nullable
                      as String,
            receiptThankYou: null == receiptThankYou
                ? _value.receiptThankYou
                : receiptThankYou // ignore: cast_nullable_to_non_nullable
                      as String,
            receiptQrUrl: null == receiptQrUrl
                ? _value.receiptQrUrl
                : receiptQrUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            receiptQrCaption: null == receiptQrCaption
                ? _value.receiptQrCaption
                : receiptQrCaption // ignore: cast_nullable_to_non_nullable
                      as String,
            logoRev: null == logoRev
                ? _value.logoRev
                : logoRev // ignore: cast_nullable_to_non_nullable
                      as int,
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
            taxAfterDiscount: null == taxAfterDiscount
                ? _value.taxAfterDiscount
                : taxAfterDiscount // ignore: cast_nullable_to_non_nullable
                      as bool,
            businessDayStartHour: null == businessDayStartHour
                ? _value.businessDayStartHour
                : businessDayStartHour // ignore: cast_nullable_to_non_nullable
                      as int,
            prepTargetMins: null == prepTargetMins
                ? _value.prepTargetMins
                : prepTargetMins // ignore: cast_nullable_to_non_nullable
                      as int,
            pickupTargetMins: null == pickupTargetMins
                ? _value.pickupTargetMins
                : pickupTargetMins // ignore: cast_nullable_to_non_nullable
                      as int,
            ungreetedMins: null == ungreetedMins
                ? _value.ungreetedMins
                : ungreetedMins // ignore: cast_nullable_to_non_nullable
                      as int,
            ungreetedEscalateMins: null == ungreetedEscalateMins
                ? _value.ungreetedEscalateMins
                : ungreetedEscalateMins // ignore: cast_nullable_to_non_nullable
                      as int,
            longStayMins: null == longStayMins
                ? _value.longStayMins
                : longStayMins // ignore: cast_nullable_to_non_nullable
                      as int,
            idleTableMins: null == idleTableMins
                ? _value.idleTableMins
                : idleTableMins // ignore: cast_nullable_to_non_nullable
                      as int,
            reservationGraceMins: null == reservationGraceMins
                ? _value.reservationGraceMins
                : reservationGraceMins // ignore: cast_nullable_to_non_nullable
                      as int,
            pendingReviewMins: null == pendingReviewMins
                ? _value.pendingReviewMins
                : pendingReviewMins // ignore: cast_nullable_to_non_nullable
                      as int,
            ungreetedAlertEnabled: null == ungreetedAlertEnabled
                ? _value.ungreetedAlertEnabled
                : ungreetedAlertEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            pickupAlertEnabled: null == pickupAlertEnabled
                ? _value.pickupAlertEnabled
                : pickupAlertEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            guestOrderingEnabled: null == guestOrderingEnabled
                ? _value.guestOrderingEnabled
                : guestOrderingEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            soundNewOrder: null == soundNewOrder
                ? _value.soundNewOrder
                : soundNewOrder // ignore: cast_nullable_to_non_nullable
                      as String,
            soundReady: null == soundReady
                ? _value.soundReady
                : soundReady // ignore: cast_nullable_to_non_nullable
                      as String,
            soundVoid: null == soundVoid
                ? _value.soundVoid
                : soundVoid // ignore: cast_nullable_to_non_nullable
                      as String,
            soundOverdue: null == soundOverdue
                ? _value.soundOverdue
                : soundOverdue // ignore: cast_nullable_to_non_nullable
                      as String,
            soundUngreeted: null == soundUngreeted
                ? _value.soundUngreeted
                : soundUngreeted // ignore: cast_nullable_to_non_nullable
                      as String,
            soundPickup: null == soundPickup
                ? _value.soundPickup
                : soundPickup // ignore: cast_nullable_to_non_nullable
                      as String,
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
    String receiptTagline,
    String receiptSocial,
    String receiptThankYou,
    String receiptQrUrl,
    String receiptQrCaption,
    int logoRev,
    bool taxEnabled,
    int taxRateBps,
    bool serviceEnabled,
    String serviceMode,
    int serviceRateBps,
    int serviceFixedAmount,
    bool taxAfterDiscount,
    int businessDayStartHour,
    int prepTargetMins,
    int pickupTargetMins,
    int ungreetedMins,
    int ungreetedEscalateMins,
    int longStayMins,
    int idleTableMins,
    int reservationGraceMins,
    int pendingReviewMins,
    bool ungreetedAlertEnabled,
    bool pickupAlertEnabled,
    bool guestOrderingEnabled,
    String soundNewOrder,
    String soundReady,
    String soundVoid,
    String soundOverdue,
    String soundUngreeted,
    String soundPickup,
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
    Object? receiptTagline = null,
    Object? receiptSocial = null,
    Object? receiptThankYou = null,
    Object? receiptQrUrl = null,
    Object? receiptQrCaption = null,
    Object? logoRev = null,
    Object? taxEnabled = null,
    Object? taxRateBps = null,
    Object? serviceEnabled = null,
    Object? serviceMode = null,
    Object? serviceRateBps = null,
    Object? serviceFixedAmount = null,
    Object? taxAfterDiscount = null,
    Object? businessDayStartHour = null,
    Object? prepTargetMins = null,
    Object? pickupTargetMins = null,
    Object? ungreetedMins = null,
    Object? ungreetedEscalateMins = null,
    Object? longStayMins = null,
    Object? idleTableMins = null,
    Object? reservationGraceMins = null,
    Object? pendingReviewMins = null,
    Object? ungreetedAlertEnabled = null,
    Object? pickupAlertEnabled = null,
    Object? guestOrderingEnabled = null,
    Object? soundNewOrder = null,
    Object? soundReady = null,
    Object? soundVoid = null,
    Object? soundOverdue = null,
    Object? soundUngreeted = null,
    Object? soundPickup = null,
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
        receiptTagline: null == receiptTagline
            ? _value.receiptTagline
            : receiptTagline // ignore: cast_nullable_to_non_nullable
                  as String,
        receiptSocial: null == receiptSocial
            ? _value.receiptSocial
            : receiptSocial // ignore: cast_nullable_to_non_nullable
                  as String,
        receiptThankYou: null == receiptThankYou
            ? _value.receiptThankYou
            : receiptThankYou // ignore: cast_nullable_to_non_nullable
                  as String,
        receiptQrUrl: null == receiptQrUrl
            ? _value.receiptQrUrl
            : receiptQrUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        receiptQrCaption: null == receiptQrCaption
            ? _value.receiptQrCaption
            : receiptQrCaption // ignore: cast_nullable_to_non_nullable
                  as String,
        logoRev: null == logoRev
            ? _value.logoRev
            : logoRev // ignore: cast_nullable_to_non_nullable
                  as int,
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
        taxAfterDiscount: null == taxAfterDiscount
            ? _value.taxAfterDiscount
            : taxAfterDiscount // ignore: cast_nullable_to_non_nullable
                  as bool,
        businessDayStartHour: null == businessDayStartHour
            ? _value.businessDayStartHour
            : businessDayStartHour // ignore: cast_nullable_to_non_nullable
                  as int,
        prepTargetMins: null == prepTargetMins
            ? _value.prepTargetMins
            : prepTargetMins // ignore: cast_nullable_to_non_nullable
                  as int,
        pickupTargetMins: null == pickupTargetMins
            ? _value.pickupTargetMins
            : pickupTargetMins // ignore: cast_nullable_to_non_nullable
                  as int,
        ungreetedMins: null == ungreetedMins
            ? _value.ungreetedMins
            : ungreetedMins // ignore: cast_nullable_to_non_nullable
                  as int,
        ungreetedEscalateMins: null == ungreetedEscalateMins
            ? _value.ungreetedEscalateMins
            : ungreetedEscalateMins // ignore: cast_nullable_to_non_nullable
                  as int,
        longStayMins: null == longStayMins
            ? _value.longStayMins
            : longStayMins // ignore: cast_nullable_to_non_nullable
                  as int,
        idleTableMins: null == idleTableMins
            ? _value.idleTableMins
            : idleTableMins // ignore: cast_nullable_to_non_nullable
                  as int,
        reservationGraceMins: null == reservationGraceMins
            ? _value.reservationGraceMins
            : reservationGraceMins // ignore: cast_nullable_to_non_nullable
                  as int,
        pendingReviewMins: null == pendingReviewMins
            ? _value.pendingReviewMins
            : pendingReviewMins // ignore: cast_nullable_to_non_nullable
                  as int,
        ungreetedAlertEnabled: null == ungreetedAlertEnabled
            ? _value.ungreetedAlertEnabled
            : ungreetedAlertEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        pickupAlertEnabled: null == pickupAlertEnabled
            ? _value.pickupAlertEnabled
            : pickupAlertEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        guestOrderingEnabled: null == guestOrderingEnabled
            ? _value.guestOrderingEnabled
            : guestOrderingEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        soundNewOrder: null == soundNewOrder
            ? _value.soundNewOrder
            : soundNewOrder // ignore: cast_nullable_to_non_nullable
                  as String,
        soundReady: null == soundReady
            ? _value.soundReady
            : soundReady // ignore: cast_nullable_to_non_nullable
                  as String,
        soundVoid: null == soundVoid
            ? _value.soundVoid
            : soundVoid // ignore: cast_nullable_to_non_nullable
                  as String,
        soundOverdue: null == soundOverdue
            ? _value.soundOverdue
            : soundOverdue // ignore: cast_nullable_to_non_nullable
                  as String,
        soundUngreeted: null == soundUngreeted
            ? _value.soundUngreeted
            : soundUngreeted // ignore: cast_nullable_to_non_nullable
                  as String,
        soundPickup: null == soundPickup
            ? _value.soundPickup
            : soundPickup // ignore: cast_nullable_to_non_nullable
                  as String,
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
    this.receiptTagline = '',
    this.receiptSocial = '',
    this.receiptThankYou = '',
    this.receiptQrUrl = '',
    this.receiptQrCaption = '',
    this.logoRev = 0,
    this.taxEnabled = false,
    this.taxRateBps = 1100,
    this.serviceEnabled = false,
    this.serviceMode = 'percent',
    this.serviceRateBps = 500,
    this.serviceFixedAmount = 0,
    this.taxAfterDiscount = true,
    this.businessDayStartHour = 4,
    this.prepTargetMins = 15,
    this.pickupTargetMins = 4,
    this.ungreetedMins = 7,
    this.ungreetedEscalateMins = 5,
    this.longStayMins = 90,
    this.idleTableMins = 20,
    this.reservationGraceMins = 15,
    this.pendingReviewMins = 6,
    this.ungreetedAlertEnabled = true,
    this.pickupAlertEnabled = true,
    this.guestOrderingEnabled = false,
    this.soundNewOrder = 'alert',
    this.soundReady = 'chime',
    this.soundVoid = 'alert',
    this.soundOverdue = 'alert',
    this.soundUngreeted = 'chime',
    this.soundPickup = 'chime',
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
  // Receipt branding block (ADR-0033). Logo bytes are NOT carried here — they
  // ride the side-endpoint /venue/logo, cache-busted by logoRev.
  @override
  @JsonKey()
  final String receiptTagline;
  @override
  @JsonKey()
  final String receiptSocial;
  @override
  @JsonKey()
  final String receiptThankYou;
  @override
  @JsonKey()
  final String receiptQrUrl;
  @override
  @JsonKey()
  final String receiptQrCaption;
  @override
  @JsonKey()
  final int logoRev;
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

  /// Where a whole-order discount sits in the stack (ADR-0038). Default true
  /// = DPP-correct (the discount reduces the base service and tax compute
  /// from). Line discounts are always pre-tax and ignore this.
  @override
  @JsonKey()
  final bool taxAfterDiscount;
  @override
  @JsonKey()
  final int businessDayStartHour;
  @override
  @JsonKey()
  final int prepTargetMins;
  // Service timings (ADR-0043/0044). `prepTargetMins` above is now the
  // venue *default* every item with a null `prepTime` inherits.
  @override
  @JsonKey()
  final int pickupTargetMins;
  @override
  @JsonKey()
  final int ungreetedMins;
  @override
  @JsonKey()
  final int ungreetedEscalateMins;
  @override
  @JsonKey()
  final int longStayMins;
  @override
  @JsonKey()
  final int idleTableMins;
  @override
  @JsonKey()
  final int reservationGraceMins;

  /// "Belum ditinjau" — how long a guest-sent order (ADR-0028) may sit
  /// unreviewed before the floor card goes critical. Visual only, never a cue.
  @override
  @JsonKey()
  final int pendingReviewMins;
  @override
  @JsonKey()
  final bool ungreetedAlertEnabled;
  @override
  @JsonKey()
  final bool pickupAlertEnabled;
  @override
  @JsonKey()
  final bool guestOrderingEnabled;
  // Per-event alert sound choice (ADR-0035). Each holds a preset id from
  // `alertSoundPresets` ('none' = silent). Defaults reproduce ADR-0007's
  // original fixed cues exactly.
  @override
  @JsonKey()
  final String soundNewOrder;
  @override
  @JsonKey()
  final String soundReady;
  @override
  @JsonKey()
  final String soundVoid;
  @override
  @JsonKey()
  final String soundOverdue;
  @override
  @JsonKey()
  final String soundUngreeted;
  @override
  @JsonKey()
  final String soundPickup;

  @override
  String toString() {
    return 'VenueSettingsDto(id: $id, displayName: $displayName, legalName: $legalName, address: $address, phone: $phone, receiptHeader: $receiptHeader, receiptFooter: $receiptFooter, receiptTagline: $receiptTagline, receiptSocial: $receiptSocial, receiptThankYou: $receiptThankYou, receiptQrUrl: $receiptQrUrl, receiptQrCaption: $receiptQrCaption, logoRev: $logoRev, taxEnabled: $taxEnabled, taxRateBps: $taxRateBps, serviceEnabled: $serviceEnabled, serviceMode: $serviceMode, serviceRateBps: $serviceRateBps, serviceFixedAmount: $serviceFixedAmount, taxAfterDiscount: $taxAfterDiscount, businessDayStartHour: $businessDayStartHour, prepTargetMins: $prepTargetMins, pickupTargetMins: $pickupTargetMins, ungreetedMins: $ungreetedMins, ungreetedEscalateMins: $ungreetedEscalateMins, longStayMins: $longStayMins, idleTableMins: $idleTableMins, reservationGraceMins: $reservationGraceMins, pendingReviewMins: $pendingReviewMins, ungreetedAlertEnabled: $ungreetedAlertEnabled, pickupAlertEnabled: $pickupAlertEnabled, guestOrderingEnabled: $guestOrderingEnabled, soundNewOrder: $soundNewOrder, soundReady: $soundReady, soundVoid: $soundVoid, soundOverdue: $soundOverdue, soundUngreeted: $soundUngreeted, soundPickup: $soundPickup)';
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
            (identical(other.receiptTagline, receiptTagline) ||
                other.receiptTagline == receiptTagline) &&
            (identical(other.receiptSocial, receiptSocial) ||
                other.receiptSocial == receiptSocial) &&
            (identical(other.receiptThankYou, receiptThankYou) ||
                other.receiptThankYou == receiptThankYou) &&
            (identical(other.receiptQrUrl, receiptQrUrl) ||
                other.receiptQrUrl == receiptQrUrl) &&
            (identical(other.receiptQrCaption, receiptQrCaption) ||
                other.receiptQrCaption == receiptQrCaption) &&
            (identical(other.logoRev, logoRev) || other.logoRev == logoRev) &&
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
            (identical(other.taxAfterDiscount, taxAfterDiscount) ||
                other.taxAfterDiscount == taxAfterDiscount) &&
            (identical(other.businessDayStartHour, businessDayStartHour) ||
                other.businessDayStartHour == businessDayStartHour) &&
            (identical(other.prepTargetMins, prepTargetMins) ||
                other.prepTargetMins == prepTargetMins) &&
            (identical(other.pickupTargetMins, pickupTargetMins) ||
                other.pickupTargetMins == pickupTargetMins) &&
            (identical(other.ungreetedMins, ungreetedMins) ||
                other.ungreetedMins == ungreetedMins) &&
            (identical(other.ungreetedEscalateMins, ungreetedEscalateMins) ||
                other.ungreetedEscalateMins == ungreetedEscalateMins) &&
            (identical(other.longStayMins, longStayMins) ||
                other.longStayMins == longStayMins) &&
            (identical(other.idleTableMins, idleTableMins) ||
                other.idleTableMins == idleTableMins) &&
            (identical(other.reservationGraceMins, reservationGraceMins) ||
                other.reservationGraceMins == reservationGraceMins) &&
            (identical(other.pendingReviewMins, pendingReviewMins) ||
                other.pendingReviewMins == pendingReviewMins) &&
            (identical(other.ungreetedAlertEnabled, ungreetedAlertEnabled) ||
                other.ungreetedAlertEnabled == ungreetedAlertEnabled) &&
            (identical(other.pickupAlertEnabled, pickupAlertEnabled) ||
                other.pickupAlertEnabled == pickupAlertEnabled) &&
            (identical(other.guestOrderingEnabled, guestOrderingEnabled) ||
                other.guestOrderingEnabled == guestOrderingEnabled) &&
            (identical(other.soundNewOrder, soundNewOrder) ||
                other.soundNewOrder == soundNewOrder) &&
            (identical(other.soundReady, soundReady) ||
                other.soundReady == soundReady) &&
            (identical(other.soundVoid, soundVoid) ||
                other.soundVoid == soundVoid) &&
            (identical(other.soundOverdue, soundOverdue) ||
                other.soundOverdue == soundOverdue) &&
            (identical(other.soundUngreeted, soundUngreeted) ||
                other.soundUngreeted == soundUngreeted) &&
            (identical(other.soundPickup, soundPickup) ||
                other.soundPickup == soundPickup));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    displayName,
    legalName,
    address,
    phone,
    receiptHeader,
    receiptFooter,
    receiptTagline,
    receiptSocial,
    receiptThankYou,
    receiptQrUrl,
    receiptQrCaption,
    logoRev,
    taxEnabled,
    taxRateBps,
    serviceEnabled,
    serviceMode,
    serviceRateBps,
    serviceFixedAmount,
    taxAfterDiscount,
    businessDayStartHour,
    prepTargetMins,
    pickupTargetMins,
    ungreetedMins,
    ungreetedEscalateMins,
    longStayMins,
    idleTableMins,
    reservationGraceMins,
    pendingReviewMins,
    ungreetedAlertEnabled,
    pickupAlertEnabled,
    guestOrderingEnabled,
    soundNewOrder,
    soundReady,
    soundVoid,
    soundOverdue,
    soundUngreeted,
    soundPickup,
  ]);

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
    final String receiptTagline,
    final String receiptSocial,
    final String receiptThankYou,
    final String receiptQrUrl,
    final String receiptQrCaption,
    final int logoRev,
    final bool taxEnabled,
    final int taxRateBps,
    final bool serviceEnabled,
    final String serviceMode,
    final int serviceRateBps,
    final int serviceFixedAmount,
    final bool taxAfterDiscount,
    final int businessDayStartHour,
    final int prepTargetMins,
    final int pickupTargetMins,
    final int ungreetedMins,
    final int ungreetedEscalateMins,
    final int longStayMins,
    final int idleTableMins,
    final int reservationGraceMins,
    final int pendingReviewMins,
    final bool ungreetedAlertEnabled,
    final bool pickupAlertEnabled,
    final bool guestOrderingEnabled,
    final String soundNewOrder,
    final String soundReady,
    final String soundVoid,
    final String soundOverdue,
    final String soundUngreeted,
    final String soundPickup,
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
  String get receiptFooter; // Receipt branding block (ADR-0033). Logo bytes are NOT carried here — they
  // ride the side-endpoint /venue/logo, cache-busted by logoRev.
  @override
  String get receiptTagline;
  @override
  String get receiptSocial;
  @override
  String get receiptThankYou;
  @override
  String get receiptQrUrl;
  @override
  String get receiptQrCaption;
  @override
  int get logoRev;
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

  /// Where a whole-order discount sits in the stack (ADR-0038). Default true
  /// = DPP-correct (the discount reduces the base service and tax compute
  /// from). Line discounts are always pre-tax and ignore this.
  @override
  bool get taxAfterDiscount;
  @override
  int get businessDayStartHour;
  @override
  int get prepTargetMins; // Service timings (ADR-0043/0044). `prepTargetMins` above is now the
  // venue *default* every item with a null `prepTime` inherits.
  @override
  int get pickupTargetMins;
  @override
  int get ungreetedMins;
  @override
  int get ungreetedEscalateMins;
  @override
  int get longStayMins;
  @override
  int get idleTableMins;
  @override
  int get reservationGraceMins;

  /// "Belum ditinjau" — how long a guest-sent order (ADR-0028) may sit
  /// unreviewed before the floor card goes critical. Visual only, never a cue.
  @override
  int get pendingReviewMins;
  @override
  bool get ungreetedAlertEnabled;
  @override
  bool get pickupAlertEnabled;
  @override
  bool get guestOrderingEnabled; // Per-event alert sound choice (ADR-0035). Each holds a preset id from
  // `alertSoundPresets` ('none' = silent). Defaults reproduce ADR-0007's
  // original fixed cues exactly.
  @override
  String get soundNewOrder;
  @override
  String get soundReady;
  @override
  String get soundVoid;
  @override
  String get soundOverdue;
  @override
  String get soundUngreeted;
  @override
  String get soundPickup;

  /// Create a copy of VenueSettingsDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VenueSettingsDtoImplCopyWith<_$VenueSettingsDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
