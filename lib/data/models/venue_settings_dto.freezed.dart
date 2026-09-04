// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue_settings_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VenueSettingsDto {

 String get id; String get displayName; String get legalName; String get address; String get phone; String get receiptHeader; String get receiptFooter;// Receipt branding block (ADR-0033). Logo bytes are NOT carried here — they
// ride the side-endpoint /venue/logo, cache-busted by logoRev.
 String get receiptTagline; String get receiptSocial; String get receiptThankYou; String get receiptQrUrl; String get receiptQrCaption; int get logoRev; bool get taxEnabled; int get taxRateBps; bool get serviceEnabled; String get serviceMode; int get serviceRateBps; int get serviceFixedAmount;/// Where a whole-order discount sits in the stack (ADR-0038). Default true
/// = DPP-correct (the discount reduces the base service and tax compute
/// from). Line discounts are always pre-tax and ignore this.
 bool get taxAfterDiscount; int get businessDayStartHour; int get prepTargetMins;// Service timings (ADR-0043/0044). `prepTargetMins` above is now the
// venue *default* every item with a null `prepTime` inherits.
 int get pickupTargetMins; int get ungreetedMins; int get ungreetedEscalateMins; int get longStayMins; int get idleTableMins; int get reservationGraceMins; bool get ungreetedAlertEnabled; bool get pickupAlertEnabled;// Per-event alert sound choice (ADR-0035). Each holds a preset id from
// `alertSoundPresets` ('none' = silent). Defaults reproduce ADR-0007's
// original fixed cues exactly.
 String get soundNewOrder; String get soundReady; String get soundVoid; String get soundOverdue; String get soundUngreeted; String get soundPickup;// Membership (ADR-0091). Off by default — a venue opts in, and until it
// does the member row, the directory and the receipt lines do not exist.
 bool get membersEnabled;/// Whether the [[Salinan pelanggan]] mirrors to this device (ADR-0129).
/// Defaults **true**, unlike every other flag on this DTO: it is the one
/// switch whose safe answer is on, because the feature it gates is what a
/// device falls back to when it can ask nobody anything.
 bool get memberMirrorEnabled; bool get memberPointsEnabled; bool get memberPunchEnabled;/// The [[Preset diskon]] nominated as the standing member discount, or null
/// for a venue running membership on points and stempel alone (ADR-0094).
 String? get memberPresetId; int get memberEarnPerThousand; int get memberPointValue; int get memberRedeemMin; String? get memberPunchItemId; int get memberPunchTarget;// Piutang (ADR-0098). Nested under [membersEnabled] — a venue that keeps no
// guest directory cannot run tabs against guests it does not keep.
 bool get memberDebtEnabled;/// The venue-wide credit limit a member falls back to when they have none
/// of their own. **0 is the shipped default and means "no tab"** — turning
/// the feature on trusts nobody until an owner names a number.
 int get memberDebtLimit;/// How long a tab may stand before the report calls it overdue. A credit
/// policy, not a fact, which is why it is a setting.
 int get memberDebtOverdueDays;// [[Pesan mandiri]] (ADR-0105). Off by default — a venue opts in, and until
// it does the cleartext guest listener does not bind at all.
 bool get guestOrderingEnabled; bool get guestNoteEnabled;/// The service window, in minutes from midnight. **Equal values mean no
/// window** (the default): a guest may order whenever the server is up.
 int get guestHoursStartMin; int get guestHoursEndMin; int get guestMaxItems; int get guestSessionHours; String get soundGuestPending;/// Whether a [[Waiter|pelayan]] may record a [[Pengeluaran kunjungan]]
/// against the visit they are serving (ADR-0130). Off by default — a venue
/// opts in, and the [[Modul|mode key]] `tableExpense` has to be held on top.
 bool get tableExpenseEnabled;/// The [[Modul]] set the venue holds (ADR-0107). Cloud-owned and mirrored
/// down; no screen writes it.
///
/// **Null means never mirrored** and reads as entitled to everything — an
/// empty list is the different, real answer "holds no module". A client that
/// draws a locked tile must check for null first, or an upgraded venue sees
/// padlocks on features it pays for.
 List<String>? get modules;/// The [[Kedai]] mode switches that are on (ADR-0109). Cloud-owned and
/// mirrored down beside [modules]; no screen writes it.
///
/// **Null and empty mean the same thing** here, unlike [modules]: a mode
/// fails closed, so a venue that has never mirrored is a restaurant. Read
/// through [counterOn], which also ANDs the mode key itself — a switch
/// without the mode is half a shape.
 List<String>? get counterConfig;
/// Create a copy of VenueSettingsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VenueSettingsDtoCopyWith<VenueSettingsDto> get copyWith => _$VenueSettingsDtoCopyWithImpl<VenueSettingsDto>(this as VenueSettingsDto, _$identity);

  /// Serializes this VenueSettingsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VenueSettingsDto&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.legalName, legalName) || other.legalName == legalName)&&(identical(other.address, address) || other.address == address)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.receiptHeader, receiptHeader) || other.receiptHeader == receiptHeader)&&(identical(other.receiptFooter, receiptFooter) || other.receiptFooter == receiptFooter)&&(identical(other.receiptTagline, receiptTagline) || other.receiptTagline == receiptTagline)&&(identical(other.receiptSocial, receiptSocial) || other.receiptSocial == receiptSocial)&&(identical(other.receiptThankYou, receiptThankYou) || other.receiptThankYou == receiptThankYou)&&(identical(other.receiptQrUrl, receiptQrUrl) || other.receiptQrUrl == receiptQrUrl)&&(identical(other.receiptQrCaption, receiptQrCaption) || other.receiptQrCaption == receiptQrCaption)&&(identical(other.logoRev, logoRev) || other.logoRev == logoRev)&&(identical(other.taxEnabled, taxEnabled) || other.taxEnabled == taxEnabled)&&(identical(other.taxRateBps, taxRateBps) || other.taxRateBps == taxRateBps)&&(identical(other.serviceEnabled, serviceEnabled) || other.serviceEnabled == serviceEnabled)&&(identical(other.serviceMode, serviceMode) || other.serviceMode == serviceMode)&&(identical(other.serviceRateBps, serviceRateBps) || other.serviceRateBps == serviceRateBps)&&(identical(other.serviceFixedAmount, serviceFixedAmount) || other.serviceFixedAmount == serviceFixedAmount)&&(identical(other.taxAfterDiscount, taxAfterDiscount) || other.taxAfterDiscount == taxAfterDiscount)&&(identical(other.businessDayStartHour, businessDayStartHour) || other.businessDayStartHour == businessDayStartHour)&&(identical(other.prepTargetMins, prepTargetMins) || other.prepTargetMins == prepTargetMins)&&(identical(other.pickupTargetMins, pickupTargetMins) || other.pickupTargetMins == pickupTargetMins)&&(identical(other.ungreetedMins, ungreetedMins) || other.ungreetedMins == ungreetedMins)&&(identical(other.ungreetedEscalateMins, ungreetedEscalateMins) || other.ungreetedEscalateMins == ungreetedEscalateMins)&&(identical(other.longStayMins, longStayMins) || other.longStayMins == longStayMins)&&(identical(other.idleTableMins, idleTableMins) || other.idleTableMins == idleTableMins)&&(identical(other.reservationGraceMins, reservationGraceMins) || other.reservationGraceMins == reservationGraceMins)&&(identical(other.ungreetedAlertEnabled, ungreetedAlertEnabled) || other.ungreetedAlertEnabled == ungreetedAlertEnabled)&&(identical(other.pickupAlertEnabled, pickupAlertEnabled) || other.pickupAlertEnabled == pickupAlertEnabled)&&(identical(other.soundNewOrder, soundNewOrder) || other.soundNewOrder == soundNewOrder)&&(identical(other.soundReady, soundReady) || other.soundReady == soundReady)&&(identical(other.soundVoid, soundVoid) || other.soundVoid == soundVoid)&&(identical(other.soundOverdue, soundOverdue) || other.soundOverdue == soundOverdue)&&(identical(other.soundUngreeted, soundUngreeted) || other.soundUngreeted == soundUngreeted)&&(identical(other.soundPickup, soundPickup) || other.soundPickup == soundPickup)&&(identical(other.membersEnabled, membersEnabled) || other.membersEnabled == membersEnabled)&&(identical(other.memberMirrorEnabled, memberMirrorEnabled) || other.memberMirrorEnabled == memberMirrorEnabled)&&(identical(other.memberPointsEnabled, memberPointsEnabled) || other.memberPointsEnabled == memberPointsEnabled)&&(identical(other.memberPunchEnabled, memberPunchEnabled) || other.memberPunchEnabled == memberPunchEnabled)&&(identical(other.memberPresetId, memberPresetId) || other.memberPresetId == memberPresetId)&&(identical(other.memberEarnPerThousand, memberEarnPerThousand) || other.memberEarnPerThousand == memberEarnPerThousand)&&(identical(other.memberPointValue, memberPointValue) || other.memberPointValue == memberPointValue)&&(identical(other.memberRedeemMin, memberRedeemMin) || other.memberRedeemMin == memberRedeemMin)&&(identical(other.memberPunchItemId, memberPunchItemId) || other.memberPunchItemId == memberPunchItemId)&&(identical(other.memberPunchTarget, memberPunchTarget) || other.memberPunchTarget == memberPunchTarget)&&(identical(other.memberDebtEnabled, memberDebtEnabled) || other.memberDebtEnabled == memberDebtEnabled)&&(identical(other.memberDebtLimit, memberDebtLimit) || other.memberDebtLimit == memberDebtLimit)&&(identical(other.memberDebtOverdueDays, memberDebtOverdueDays) || other.memberDebtOverdueDays == memberDebtOverdueDays)&&(identical(other.guestOrderingEnabled, guestOrderingEnabled) || other.guestOrderingEnabled == guestOrderingEnabled)&&(identical(other.guestNoteEnabled, guestNoteEnabled) || other.guestNoteEnabled == guestNoteEnabled)&&(identical(other.guestHoursStartMin, guestHoursStartMin) || other.guestHoursStartMin == guestHoursStartMin)&&(identical(other.guestHoursEndMin, guestHoursEndMin) || other.guestHoursEndMin == guestHoursEndMin)&&(identical(other.guestMaxItems, guestMaxItems) || other.guestMaxItems == guestMaxItems)&&(identical(other.guestSessionHours, guestSessionHours) || other.guestSessionHours == guestSessionHours)&&(identical(other.soundGuestPending, soundGuestPending) || other.soundGuestPending == soundGuestPending)&&(identical(other.tableExpenseEnabled, tableExpenseEnabled) || other.tableExpenseEnabled == tableExpenseEnabled)&&const DeepCollectionEquality().equals(other.modules, modules)&&const DeepCollectionEquality().equals(other.counterConfig, counterConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,legalName,address,phone,receiptHeader,receiptFooter,receiptTagline,receiptSocial,receiptThankYou,receiptQrUrl,receiptQrCaption,logoRev,taxEnabled,taxRateBps,serviceEnabled,serviceMode,serviceRateBps,serviceFixedAmount,taxAfterDiscount,businessDayStartHour,prepTargetMins,pickupTargetMins,ungreetedMins,ungreetedEscalateMins,longStayMins,idleTableMins,reservationGraceMins,ungreetedAlertEnabled,pickupAlertEnabled,soundNewOrder,soundReady,soundVoid,soundOverdue,soundUngreeted,soundPickup,membersEnabled,memberMirrorEnabled,memberPointsEnabled,memberPunchEnabled,memberPresetId,memberEarnPerThousand,memberPointValue,memberRedeemMin,memberPunchItemId,memberPunchTarget,memberDebtEnabled,memberDebtLimit,memberDebtOverdueDays,guestOrderingEnabled,guestNoteEnabled,guestHoursStartMin,guestHoursEndMin,guestMaxItems,guestSessionHours,soundGuestPending,tableExpenseEnabled,const DeepCollectionEquality().hash(modules),const DeepCollectionEquality().hash(counterConfig)]);

@override
String toString() {
  return 'VenueSettingsDto(id: $id, displayName: $displayName, legalName: $legalName, address: $address, phone: $phone, receiptHeader: $receiptHeader, receiptFooter: $receiptFooter, receiptTagline: $receiptTagline, receiptSocial: $receiptSocial, receiptThankYou: $receiptThankYou, receiptQrUrl: $receiptQrUrl, receiptQrCaption: $receiptQrCaption, logoRev: $logoRev, taxEnabled: $taxEnabled, taxRateBps: $taxRateBps, serviceEnabled: $serviceEnabled, serviceMode: $serviceMode, serviceRateBps: $serviceRateBps, serviceFixedAmount: $serviceFixedAmount, taxAfterDiscount: $taxAfterDiscount, businessDayStartHour: $businessDayStartHour, prepTargetMins: $prepTargetMins, pickupTargetMins: $pickupTargetMins, ungreetedMins: $ungreetedMins, ungreetedEscalateMins: $ungreetedEscalateMins, longStayMins: $longStayMins, idleTableMins: $idleTableMins, reservationGraceMins: $reservationGraceMins, ungreetedAlertEnabled: $ungreetedAlertEnabled, pickupAlertEnabled: $pickupAlertEnabled, soundNewOrder: $soundNewOrder, soundReady: $soundReady, soundVoid: $soundVoid, soundOverdue: $soundOverdue, soundUngreeted: $soundUngreeted, soundPickup: $soundPickup, membersEnabled: $membersEnabled, memberMirrorEnabled: $memberMirrorEnabled, memberPointsEnabled: $memberPointsEnabled, memberPunchEnabled: $memberPunchEnabled, memberPresetId: $memberPresetId, memberEarnPerThousand: $memberEarnPerThousand, memberPointValue: $memberPointValue, memberRedeemMin: $memberRedeemMin, memberPunchItemId: $memberPunchItemId, memberPunchTarget: $memberPunchTarget, memberDebtEnabled: $memberDebtEnabled, memberDebtLimit: $memberDebtLimit, memberDebtOverdueDays: $memberDebtOverdueDays, guestOrderingEnabled: $guestOrderingEnabled, guestNoteEnabled: $guestNoteEnabled, guestHoursStartMin: $guestHoursStartMin, guestHoursEndMin: $guestHoursEndMin, guestMaxItems: $guestMaxItems, guestSessionHours: $guestSessionHours, soundGuestPending: $soundGuestPending, tableExpenseEnabled: $tableExpenseEnabled, modules: $modules, counterConfig: $counterConfig)';
}


}

/// @nodoc
abstract mixin class $VenueSettingsDtoCopyWith<$Res>  {
  factory $VenueSettingsDtoCopyWith(VenueSettingsDto value, $Res Function(VenueSettingsDto) _then) = _$VenueSettingsDtoCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String legalName, String address, String phone, String receiptHeader, String receiptFooter, String receiptTagline, String receiptSocial, String receiptThankYou, String receiptQrUrl, String receiptQrCaption, int logoRev, bool taxEnabled, int taxRateBps, bool serviceEnabled, String serviceMode, int serviceRateBps, int serviceFixedAmount, bool taxAfterDiscount, int businessDayStartHour, int prepTargetMins, int pickupTargetMins, int ungreetedMins, int ungreetedEscalateMins, int longStayMins, int idleTableMins, int reservationGraceMins, bool ungreetedAlertEnabled, bool pickupAlertEnabled, String soundNewOrder, String soundReady, String soundVoid, String soundOverdue, String soundUngreeted, String soundPickup, bool membersEnabled, bool memberMirrorEnabled, bool memberPointsEnabled, bool memberPunchEnabled, String? memberPresetId, int memberEarnPerThousand, int memberPointValue, int memberRedeemMin, String? memberPunchItemId, int memberPunchTarget, bool memberDebtEnabled, int memberDebtLimit, int memberDebtOverdueDays, bool guestOrderingEnabled, bool guestNoteEnabled, int guestHoursStartMin, int guestHoursEndMin, int guestMaxItems, int guestSessionHours, String soundGuestPending, bool tableExpenseEnabled, List<String>? modules, List<String>? counterConfig
});




}
/// @nodoc
class _$VenueSettingsDtoCopyWithImpl<$Res>
    implements $VenueSettingsDtoCopyWith<$Res> {
  _$VenueSettingsDtoCopyWithImpl(this._self, this._then);

  final VenueSettingsDto _self;
  final $Res Function(VenueSettingsDto) _then;

/// Create a copy of VenueSettingsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? legalName = null,Object? address = null,Object? phone = null,Object? receiptHeader = null,Object? receiptFooter = null,Object? receiptTagline = null,Object? receiptSocial = null,Object? receiptThankYou = null,Object? receiptQrUrl = null,Object? receiptQrCaption = null,Object? logoRev = null,Object? taxEnabled = null,Object? taxRateBps = null,Object? serviceEnabled = null,Object? serviceMode = null,Object? serviceRateBps = null,Object? serviceFixedAmount = null,Object? taxAfterDiscount = null,Object? businessDayStartHour = null,Object? prepTargetMins = null,Object? pickupTargetMins = null,Object? ungreetedMins = null,Object? ungreetedEscalateMins = null,Object? longStayMins = null,Object? idleTableMins = null,Object? reservationGraceMins = null,Object? ungreetedAlertEnabled = null,Object? pickupAlertEnabled = null,Object? soundNewOrder = null,Object? soundReady = null,Object? soundVoid = null,Object? soundOverdue = null,Object? soundUngreeted = null,Object? soundPickup = null,Object? membersEnabled = null,Object? memberMirrorEnabled = null,Object? memberPointsEnabled = null,Object? memberPunchEnabled = null,Object? memberPresetId = freezed,Object? memberEarnPerThousand = null,Object? memberPointValue = null,Object? memberRedeemMin = null,Object? memberPunchItemId = freezed,Object? memberPunchTarget = null,Object? memberDebtEnabled = null,Object? memberDebtLimit = null,Object? memberDebtOverdueDays = null,Object? guestOrderingEnabled = null,Object? guestNoteEnabled = null,Object? guestHoursStartMin = null,Object? guestHoursEndMin = null,Object? guestMaxItems = null,Object? guestSessionHours = null,Object? soundGuestPending = null,Object? tableExpenseEnabled = null,Object? modules = freezed,Object? counterConfig = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,legalName: null == legalName ? _self.legalName : legalName // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,receiptHeader: null == receiptHeader ? _self.receiptHeader : receiptHeader // ignore: cast_nullable_to_non_nullable
as String,receiptFooter: null == receiptFooter ? _self.receiptFooter : receiptFooter // ignore: cast_nullable_to_non_nullable
as String,receiptTagline: null == receiptTagline ? _self.receiptTagline : receiptTagline // ignore: cast_nullable_to_non_nullable
as String,receiptSocial: null == receiptSocial ? _self.receiptSocial : receiptSocial // ignore: cast_nullable_to_non_nullable
as String,receiptThankYou: null == receiptThankYou ? _self.receiptThankYou : receiptThankYou // ignore: cast_nullable_to_non_nullable
as String,receiptQrUrl: null == receiptQrUrl ? _self.receiptQrUrl : receiptQrUrl // ignore: cast_nullable_to_non_nullable
as String,receiptQrCaption: null == receiptQrCaption ? _self.receiptQrCaption : receiptQrCaption // ignore: cast_nullable_to_non_nullable
as String,logoRev: null == logoRev ? _self.logoRev : logoRev // ignore: cast_nullable_to_non_nullable
as int,taxEnabled: null == taxEnabled ? _self.taxEnabled : taxEnabled // ignore: cast_nullable_to_non_nullable
as bool,taxRateBps: null == taxRateBps ? _self.taxRateBps : taxRateBps // ignore: cast_nullable_to_non_nullable
as int,serviceEnabled: null == serviceEnabled ? _self.serviceEnabled : serviceEnabled // ignore: cast_nullable_to_non_nullable
as bool,serviceMode: null == serviceMode ? _self.serviceMode : serviceMode // ignore: cast_nullable_to_non_nullable
as String,serviceRateBps: null == serviceRateBps ? _self.serviceRateBps : serviceRateBps // ignore: cast_nullable_to_non_nullable
as int,serviceFixedAmount: null == serviceFixedAmount ? _self.serviceFixedAmount : serviceFixedAmount // ignore: cast_nullable_to_non_nullable
as int,taxAfterDiscount: null == taxAfterDiscount ? _self.taxAfterDiscount : taxAfterDiscount // ignore: cast_nullable_to_non_nullable
as bool,businessDayStartHour: null == businessDayStartHour ? _self.businessDayStartHour : businessDayStartHour // ignore: cast_nullable_to_non_nullable
as int,prepTargetMins: null == prepTargetMins ? _self.prepTargetMins : prepTargetMins // ignore: cast_nullable_to_non_nullable
as int,pickupTargetMins: null == pickupTargetMins ? _self.pickupTargetMins : pickupTargetMins // ignore: cast_nullable_to_non_nullable
as int,ungreetedMins: null == ungreetedMins ? _self.ungreetedMins : ungreetedMins // ignore: cast_nullable_to_non_nullable
as int,ungreetedEscalateMins: null == ungreetedEscalateMins ? _self.ungreetedEscalateMins : ungreetedEscalateMins // ignore: cast_nullable_to_non_nullable
as int,longStayMins: null == longStayMins ? _self.longStayMins : longStayMins // ignore: cast_nullable_to_non_nullable
as int,idleTableMins: null == idleTableMins ? _self.idleTableMins : idleTableMins // ignore: cast_nullable_to_non_nullable
as int,reservationGraceMins: null == reservationGraceMins ? _self.reservationGraceMins : reservationGraceMins // ignore: cast_nullable_to_non_nullable
as int,ungreetedAlertEnabled: null == ungreetedAlertEnabled ? _self.ungreetedAlertEnabled : ungreetedAlertEnabled // ignore: cast_nullable_to_non_nullable
as bool,pickupAlertEnabled: null == pickupAlertEnabled ? _self.pickupAlertEnabled : pickupAlertEnabled // ignore: cast_nullable_to_non_nullable
as bool,soundNewOrder: null == soundNewOrder ? _self.soundNewOrder : soundNewOrder // ignore: cast_nullable_to_non_nullable
as String,soundReady: null == soundReady ? _self.soundReady : soundReady // ignore: cast_nullable_to_non_nullable
as String,soundVoid: null == soundVoid ? _self.soundVoid : soundVoid // ignore: cast_nullable_to_non_nullable
as String,soundOverdue: null == soundOverdue ? _self.soundOverdue : soundOverdue // ignore: cast_nullable_to_non_nullable
as String,soundUngreeted: null == soundUngreeted ? _self.soundUngreeted : soundUngreeted // ignore: cast_nullable_to_non_nullable
as String,soundPickup: null == soundPickup ? _self.soundPickup : soundPickup // ignore: cast_nullable_to_non_nullable
as String,membersEnabled: null == membersEnabled ? _self.membersEnabled : membersEnabled // ignore: cast_nullable_to_non_nullable
as bool,memberMirrorEnabled: null == memberMirrorEnabled ? _self.memberMirrorEnabled : memberMirrorEnabled // ignore: cast_nullable_to_non_nullable
as bool,memberPointsEnabled: null == memberPointsEnabled ? _self.memberPointsEnabled : memberPointsEnabled // ignore: cast_nullable_to_non_nullable
as bool,memberPunchEnabled: null == memberPunchEnabled ? _self.memberPunchEnabled : memberPunchEnabled // ignore: cast_nullable_to_non_nullable
as bool,memberPresetId: freezed == memberPresetId ? _self.memberPresetId : memberPresetId // ignore: cast_nullable_to_non_nullable
as String?,memberEarnPerThousand: null == memberEarnPerThousand ? _self.memberEarnPerThousand : memberEarnPerThousand // ignore: cast_nullable_to_non_nullable
as int,memberPointValue: null == memberPointValue ? _self.memberPointValue : memberPointValue // ignore: cast_nullable_to_non_nullable
as int,memberRedeemMin: null == memberRedeemMin ? _self.memberRedeemMin : memberRedeemMin // ignore: cast_nullable_to_non_nullable
as int,memberPunchItemId: freezed == memberPunchItemId ? _self.memberPunchItemId : memberPunchItemId // ignore: cast_nullable_to_non_nullable
as String?,memberPunchTarget: null == memberPunchTarget ? _self.memberPunchTarget : memberPunchTarget // ignore: cast_nullable_to_non_nullable
as int,memberDebtEnabled: null == memberDebtEnabled ? _self.memberDebtEnabled : memberDebtEnabled // ignore: cast_nullable_to_non_nullable
as bool,memberDebtLimit: null == memberDebtLimit ? _self.memberDebtLimit : memberDebtLimit // ignore: cast_nullable_to_non_nullable
as int,memberDebtOverdueDays: null == memberDebtOverdueDays ? _self.memberDebtOverdueDays : memberDebtOverdueDays // ignore: cast_nullable_to_non_nullable
as int,guestOrderingEnabled: null == guestOrderingEnabled ? _self.guestOrderingEnabled : guestOrderingEnabled // ignore: cast_nullable_to_non_nullable
as bool,guestNoteEnabled: null == guestNoteEnabled ? _self.guestNoteEnabled : guestNoteEnabled // ignore: cast_nullable_to_non_nullable
as bool,guestHoursStartMin: null == guestHoursStartMin ? _self.guestHoursStartMin : guestHoursStartMin // ignore: cast_nullable_to_non_nullable
as int,guestHoursEndMin: null == guestHoursEndMin ? _self.guestHoursEndMin : guestHoursEndMin // ignore: cast_nullable_to_non_nullable
as int,guestMaxItems: null == guestMaxItems ? _self.guestMaxItems : guestMaxItems // ignore: cast_nullable_to_non_nullable
as int,guestSessionHours: null == guestSessionHours ? _self.guestSessionHours : guestSessionHours // ignore: cast_nullable_to_non_nullable
as int,soundGuestPending: null == soundGuestPending ? _self.soundGuestPending : soundGuestPending // ignore: cast_nullable_to_non_nullable
as String,tableExpenseEnabled: null == tableExpenseEnabled ? _self.tableExpenseEnabled : tableExpenseEnabled // ignore: cast_nullable_to_non_nullable
as bool,modules: freezed == modules ? _self.modules : modules // ignore: cast_nullable_to_non_nullable
as List<String>?,counterConfig: freezed == counterConfig ? _self.counterConfig : counterConfig // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [VenueSettingsDto].
extension VenueSettingsDtoPatterns on VenueSettingsDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VenueSettingsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VenueSettingsDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VenueSettingsDto value)  $default,){
final _that = this;
switch (_that) {
case _VenueSettingsDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VenueSettingsDto value)?  $default,){
final _that = this;
switch (_that) {
case _VenueSettingsDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String legalName,  String address,  String phone,  String receiptHeader,  String receiptFooter,  String receiptTagline,  String receiptSocial,  String receiptThankYou,  String receiptQrUrl,  String receiptQrCaption,  int logoRev,  bool taxEnabled,  int taxRateBps,  bool serviceEnabled,  String serviceMode,  int serviceRateBps,  int serviceFixedAmount,  bool taxAfterDiscount,  int businessDayStartHour,  int prepTargetMins,  int pickupTargetMins,  int ungreetedMins,  int ungreetedEscalateMins,  int longStayMins,  int idleTableMins,  int reservationGraceMins,  bool ungreetedAlertEnabled,  bool pickupAlertEnabled,  String soundNewOrder,  String soundReady,  String soundVoid,  String soundOverdue,  String soundUngreeted,  String soundPickup,  bool membersEnabled,  bool memberMirrorEnabled,  bool memberPointsEnabled,  bool memberPunchEnabled,  String? memberPresetId,  int memberEarnPerThousand,  int memberPointValue,  int memberRedeemMin,  String? memberPunchItemId,  int memberPunchTarget,  bool memberDebtEnabled,  int memberDebtLimit,  int memberDebtOverdueDays,  bool guestOrderingEnabled,  bool guestNoteEnabled,  int guestHoursStartMin,  int guestHoursEndMin,  int guestMaxItems,  int guestSessionHours,  String soundGuestPending,  bool tableExpenseEnabled,  List<String>? modules,  List<String>? counterConfig)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VenueSettingsDto() when $default != null:
return $default(_that.id,_that.displayName,_that.legalName,_that.address,_that.phone,_that.receiptHeader,_that.receiptFooter,_that.receiptTagline,_that.receiptSocial,_that.receiptThankYou,_that.receiptQrUrl,_that.receiptQrCaption,_that.logoRev,_that.taxEnabled,_that.taxRateBps,_that.serviceEnabled,_that.serviceMode,_that.serviceRateBps,_that.serviceFixedAmount,_that.taxAfterDiscount,_that.businessDayStartHour,_that.prepTargetMins,_that.pickupTargetMins,_that.ungreetedMins,_that.ungreetedEscalateMins,_that.longStayMins,_that.idleTableMins,_that.reservationGraceMins,_that.ungreetedAlertEnabled,_that.pickupAlertEnabled,_that.soundNewOrder,_that.soundReady,_that.soundVoid,_that.soundOverdue,_that.soundUngreeted,_that.soundPickup,_that.membersEnabled,_that.memberMirrorEnabled,_that.memberPointsEnabled,_that.memberPunchEnabled,_that.memberPresetId,_that.memberEarnPerThousand,_that.memberPointValue,_that.memberRedeemMin,_that.memberPunchItemId,_that.memberPunchTarget,_that.memberDebtEnabled,_that.memberDebtLimit,_that.memberDebtOverdueDays,_that.guestOrderingEnabled,_that.guestNoteEnabled,_that.guestHoursStartMin,_that.guestHoursEndMin,_that.guestMaxItems,_that.guestSessionHours,_that.soundGuestPending,_that.tableExpenseEnabled,_that.modules,_that.counterConfig);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String legalName,  String address,  String phone,  String receiptHeader,  String receiptFooter,  String receiptTagline,  String receiptSocial,  String receiptThankYou,  String receiptQrUrl,  String receiptQrCaption,  int logoRev,  bool taxEnabled,  int taxRateBps,  bool serviceEnabled,  String serviceMode,  int serviceRateBps,  int serviceFixedAmount,  bool taxAfterDiscount,  int businessDayStartHour,  int prepTargetMins,  int pickupTargetMins,  int ungreetedMins,  int ungreetedEscalateMins,  int longStayMins,  int idleTableMins,  int reservationGraceMins,  bool ungreetedAlertEnabled,  bool pickupAlertEnabled,  String soundNewOrder,  String soundReady,  String soundVoid,  String soundOverdue,  String soundUngreeted,  String soundPickup,  bool membersEnabled,  bool memberMirrorEnabled,  bool memberPointsEnabled,  bool memberPunchEnabled,  String? memberPresetId,  int memberEarnPerThousand,  int memberPointValue,  int memberRedeemMin,  String? memberPunchItemId,  int memberPunchTarget,  bool memberDebtEnabled,  int memberDebtLimit,  int memberDebtOverdueDays,  bool guestOrderingEnabled,  bool guestNoteEnabled,  int guestHoursStartMin,  int guestHoursEndMin,  int guestMaxItems,  int guestSessionHours,  String soundGuestPending,  bool tableExpenseEnabled,  List<String>? modules,  List<String>? counterConfig)  $default,) {final _that = this;
switch (_that) {
case _VenueSettingsDto():
return $default(_that.id,_that.displayName,_that.legalName,_that.address,_that.phone,_that.receiptHeader,_that.receiptFooter,_that.receiptTagline,_that.receiptSocial,_that.receiptThankYou,_that.receiptQrUrl,_that.receiptQrCaption,_that.logoRev,_that.taxEnabled,_that.taxRateBps,_that.serviceEnabled,_that.serviceMode,_that.serviceRateBps,_that.serviceFixedAmount,_that.taxAfterDiscount,_that.businessDayStartHour,_that.prepTargetMins,_that.pickupTargetMins,_that.ungreetedMins,_that.ungreetedEscalateMins,_that.longStayMins,_that.idleTableMins,_that.reservationGraceMins,_that.ungreetedAlertEnabled,_that.pickupAlertEnabled,_that.soundNewOrder,_that.soundReady,_that.soundVoid,_that.soundOverdue,_that.soundUngreeted,_that.soundPickup,_that.membersEnabled,_that.memberMirrorEnabled,_that.memberPointsEnabled,_that.memberPunchEnabled,_that.memberPresetId,_that.memberEarnPerThousand,_that.memberPointValue,_that.memberRedeemMin,_that.memberPunchItemId,_that.memberPunchTarget,_that.memberDebtEnabled,_that.memberDebtLimit,_that.memberDebtOverdueDays,_that.guestOrderingEnabled,_that.guestNoteEnabled,_that.guestHoursStartMin,_that.guestHoursEndMin,_that.guestMaxItems,_that.guestSessionHours,_that.soundGuestPending,_that.tableExpenseEnabled,_that.modules,_that.counterConfig);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String legalName,  String address,  String phone,  String receiptHeader,  String receiptFooter,  String receiptTagline,  String receiptSocial,  String receiptThankYou,  String receiptQrUrl,  String receiptQrCaption,  int logoRev,  bool taxEnabled,  int taxRateBps,  bool serviceEnabled,  String serviceMode,  int serviceRateBps,  int serviceFixedAmount,  bool taxAfterDiscount,  int businessDayStartHour,  int prepTargetMins,  int pickupTargetMins,  int ungreetedMins,  int ungreetedEscalateMins,  int longStayMins,  int idleTableMins,  int reservationGraceMins,  bool ungreetedAlertEnabled,  bool pickupAlertEnabled,  String soundNewOrder,  String soundReady,  String soundVoid,  String soundOverdue,  String soundUngreeted,  String soundPickup,  bool membersEnabled,  bool memberMirrorEnabled,  bool memberPointsEnabled,  bool memberPunchEnabled,  String? memberPresetId,  int memberEarnPerThousand,  int memberPointValue,  int memberRedeemMin,  String? memberPunchItemId,  int memberPunchTarget,  bool memberDebtEnabled,  int memberDebtLimit,  int memberDebtOverdueDays,  bool guestOrderingEnabled,  bool guestNoteEnabled,  int guestHoursStartMin,  int guestHoursEndMin,  int guestMaxItems,  int guestSessionHours,  String soundGuestPending,  bool tableExpenseEnabled,  List<String>? modules,  List<String>? counterConfig)?  $default,) {final _that = this;
switch (_that) {
case _VenueSettingsDto() when $default != null:
return $default(_that.id,_that.displayName,_that.legalName,_that.address,_that.phone,_that.receiptHeader,_that.receiptFooter,_that.receiptTagline,_that.receiptSocial,_that.receiptThankYou,_that.receiptQrUrl,_that.receiptQrCaption,_that.logoRev,_that.taxEnabled,_that.taxRateBps,_that.serviceEnabled,_that.serviceMode,_that.serviceRateBps,_that.serviceFixedAmount,_that.taxAfterDiscount,_that.businessDayStartHour,_that.prepTargetMins,_that.pickupTargetMins,_that.ungreetedMins,_that.ungreetedEscalateMins,_that.longStayMins,_that.idleTableMins,_that.reservationGraceMins,_that.ungreetedAlertEnabled,_that.pickupAlertEnabled,_that.soundNewOrder,_that.soundReady,_that.soundVoid,_that.soundOverdue,_that.soundUngreeted,_that.soundPickup,_that.membersEnabled,_that.memberMirrorEnabled,_that.memberPointsEnabled,_that.memberPunchEnabled,_that.memberPresetId,_that.memberEarnPerThousand,_that.memberPointValue,_that.memberRedeemMin,_that.memberPunchItemId,_that.memberPunchTarget,_that.memberDebtEnabled,_that.memberDebtLimit,_that.memberDebtOverdueDays,_that.guestOrderingEnabled,_that.guestNoteEnabled,_that.guestHoursStartMin,_that.guestHoursEndMin,_that.guestMaxItems,_that.guestSessionHours,_that.soundGuestPending,_that.tableExpenseEnabled,_that.modules,_that.counterConfig);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VenueSettingsDto implements VenueSettingsDto {
  const _VenueSettingsDto({this.id = 'default', this.displayName = 'Warung Sebelah', this.legalName = '', this.address = '', this.phone = '', this.receiptHeader = '', this.receiptFooter = '', this.receiptTagline = '', this.receiptSocial = '', this.receiptThankYou = '', this.receiptQrUrl = '', this.receiptQrCaption = '', this.logoRev = 0, this.taxEnabled = false, this.taxRateBps = 1100, this.serviceEnabled = false, this.serviceMode = 'percent', this.serviceRateBps = 500, this.serviceFixedAmount = 0, this.taxAfterDiscount = true, this.businessDayStartHour = 4, this.prepTargetMins = 15, this.pickupTargetMins = 4, this.ungreetedMins = 7, this.ungreetedEscalateMins = 5, this.longStayMins = 90, this.idleTableMins = 20, this.reservationGraceMins = 15, this.ungreetedAlertEnabled = true, this.pickupAlertEnabled = true, this.soundNewOrder = 'alert', this.soundReady = 'chime', this.soundVoid = 'alert', this.soundOverdue = 'alert', this.soundUngreeted = 'chime', this.soundPickup = 'chime', this.membersEnabled = false, this.memberMirrorEnabled = true, this.memberPointsEnabled = false, this.memberPunchEnabled = false, this.memberPresetId, this.memberEarnPerThousand = 1, this.memberPointValue = 1000, this.memberRedeemMin = 10, this.memberPunchItemId, this.memberPunchTarget = 10, this.memberDebtEnabled = false, this.memberDebtLimit = 0, this.memberDebtOverdueDays = 30, this.guestOrderingEnabled = false, this.guestNoteEnabled = true, this.guestHoursStartMin = 0, this.guestHoursEndMin = 0, this.guestMaxItems = 20, this.guestSessionHours = 4, this.soundGuestPending = 'chime', this.tableExpenseEnabled = false, final  List<String>? modules, final  List<String>? counterConfig}): _modules = modules,_counterConfig = counterConfig;
  factory _VenueSettingsDto.fromJson(Map<String, dynamic> json) => _$VenueSettingsDtoFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String displayName;
@override@JsonKey() final  String legalName;
@override@JsonKey() final  String address;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String receiptHeader;
@override@JsonKey() final  String receiptFooter;
// Receipt branding block (ADR-0033). Logo bytes are NOT carried here — they
// ride the side-endpoint /venue/logo, cache-busted by logoRev.
@override@JsonKey() final  String receiptTagline;
@override@JsonKey() final  String receiptSocial;
@override@JsonKey() final  String receiptThankYou;
@override@JsonKey() final  String receiptQrUrl;
@override@JsonKey() final  String receiptQrCaption;
@override@JsonKey() final  int logoRev;
@override@JsonKey() final  bool taxEnabled;
@override@JsonKey() final  int taxRateBps;
@override@JsonKey() final  bool serviceEnabled;
@override@JsonKey() final  String serviceMode;
@override@JsonKey() final  int serviceRateBps;
@override@JsonKey() final  int serviceFixedAmount;
/// Where a whole-order discount sits in the stack (ADR-0038). Default true
/// = DPP-correct (the discount reduces the base service and tax compute
/// from). Line discounts are always pre-tax and ignore this.
@override@JsonKey() final  bool taxAfterDiscount;
@override@JsonKey() final  int businessDayStartHour;
@override@JsonKey() final  int prepTargetMins;
// Service timings (ADR-0043/0044). `prepTargetMins` above is now the
// venue *default* every item with a null `prepTime` inherits.
@override@JsonKey() final  int pickupTargetMins;
@override@JsonKey() final  int ungreetedMins;
@override@JsonKey() final  int ungreetedEscalateMins;
@override@JsonKey() final  int longStayMins;
@override@JsonKey() final  int idleTableMins;
@override@JsonKey() final  int reservationGraceMins;
@override@JsonKey() final  bool ungreetedAlertEnabled;
@override@JsonKey() final  bool pickupAlertEnabled;
// Per-event alert sound choice (ADR-0035). Each holds a preset id from
// `alertSoundPresets` ('none' = silent). Defaults reproduce ADR-0007's
// original fixed cues exactly.
@override@JsonKey() final  String soundNewOrder;
@override@JsonKey() final  String soundReady;
@override@JsonKey() final  String soundVoid;
@override@JsonKey() final  String soundOverdue;
@override@JsonKey() final  String soundUngreeted;
@override@JsonKey() final  String soundPickup;
// Membership (ADR-0091). Off by default — a venue opts in, and until it
// does the member row, the directory and the receipt lines do not exist.
@override@JsonKey() final  bool membersEnabled;
/// Whether the [[Salinan pelanggan]] mirrors to this device (ADR-0129).
/// Defaults **true**, unlike every other flag on this DTO: it is the one
/// switch whose safe answer is on, because the feature it gates is what a
/// device falls back to when it can ask nobody anything.
@override@JsonKey() final  bool memberMirrorEnabled;
@override@JsonKey() final  bool memberPointsEnabled;
@override@JsonKey() final  bool memberPunchEnabled;
/// The [[Preset diskon]] nominated as the standing member discount, or null
/// for a venue running membership on points and stempel alone (ADR-0094).
@override final  String? memberPresetId;
@override@JsonKey() final  int memberEarnPerThousand;
@override@JsonKey() final  int memberPointValue;
@override@JsonKey() final  int memberRedeemMin;
@override final  String? memberPunchItemId;
@override@JsonKey() final  int memberPunchTarget;
// Piutang (ADR-0098). Nested under [membersEnabled] — a venue that keeps no
// guest directory cannot run tabs against guests it does not keep.
@override@JsonKey() final  bool memberDebtEnabled;
/// The venue-wide credit limit a member falls back to when they have none
/// of their own. **0 is the shipped default and means "no tab"** — turning
/// the feature on trusts nobody until an owner names a number.
@override@JsonKey() final  int memberDebtLimit;
/// How long a tab may stand before the report calls it overdue. A credit
/// policy, not a fact, which is why it is a setting.
@override@JsonKey() final  int memberDebtOverdueDays;
// [[Pesan mandiri]] (ADR-0105). Off by default — a venue opts in, and until
// it does the cleartext guest listener does not bind at all.
@override@JsonKey() final  bool guestOrderingEnabled;
@override@JsonKey() final  bool guestNoteEnabled;
/// The service window, in minutes from midnight. **Equal values mean no
/// window** (the default): a guest may order whenever the server is up.
@override@JsonKey() final  int guestHoursStartMin;
@override@JsonKey() final  int guestHoursEndMin;
@override@JsonKey() final  int guestMaxItems;
@override@JsonKey() final  int guestSessionHours;
@override@JsonKey() final  String soundGuestPending;
/// Whether a [[Waiter|pelayan]] may record a [[Pengeluaran kunjungan]]
/// against the visit they are serving (ADR-0130). Off by default — a venue
/// opts in, and the [[Modul|mode key]] `tableExpense` has to be held on top.
@override@JsonKey() final  bool tableExpenseEnabled;
/// The [[Modul]] set the venue holds (ADR-0107). Cloud-owned and mirrored
/// down; no screen writes it.
///
/// **Null means never mirrored** and reads as entitled to everything — an
/// empty list is the different, real answer "holds no module". A client that
/// draws a locked tile must check for null first, or an upgraded venue sees
/// padlocks on features it pays for.
 final  List<String>? _modules;
/// The [[Modul]] set the venue holds (ADR-0107). Cloud-owned and mirrored
/// down; no screen writes it.
///
/// **Null means never mirrored** and reads as entitled to everything — an
/// empty list is the different, real answer "holds no module". A client that
/// draws a locked tile must check for null first, or an upgraded venue sees
/// padlocks on features it pays for.
@override List<String>? get modules {
  final value = _modules;
  if (value == null) return null;
  if (_modules is EqualUnmodifiableListView) return _modules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// The [[Kedai]] mode switches that are on (ADR-0109). Cloud-owned and
/// mirrored down beside [modules]; no screen writes it.
///
/// **Null and empty mean the same thing** here, unlike [modules]: a mode
/// fails closed, so a venue that has never mirrored is a restaurant. Read
/// through [counterOn], which also ANDs the mode key itself — a switch
/// without the mode is half a shape.
 final  List<String>? _counterConfig;
/// The [[Kedai]] mode switches that are on (ADR-0109). Cloud-owned and
/// mirrored down beside [modules]; no screen writes it.
///
/// **Null and empty mean the same thing** here, unlike [modules]: a mode
/// fails closed, so a venue that has never mirrored is a restaurant. Read
/// through [counterOn], which also ANDs the mode key itself — a switch
/// without the mode is half a shape.
@override List<String>? get counterConfig {
  final value = _counterConfig;
  if (value == null) return null;
  if (_counterConfig is EqualUnmodifiableListView) return _counterConfig;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of VenueSettingsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VenueSettingsDtoCopyWith<_VenueSettingsDto> get copyWith => __$VenueSettingsDtoCopyWithImpl<_VenueSettingsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VenueSettingsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VenueSettingsDto&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.legalName, legalName) || other.legalName == legalName)&&(identical(other.address, address) || other.address == address)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.receiptHeader, receiptHeader) || other.receiptHeader == receiptHeader)&&(identical(other.receiptFooter, receiptFooter) || other.receiptFooter == receiptFooter)&&(identical(other.receiptTagline, receiptTagline) || other.receiptTagline == receiptTagline)&&(identical(other.receiptSocial, receiptSocial) || other.receiptSocial == receiptSocial)&&(identical(other.receiptThankYou, receiptThankYou) || other.receiptThankYou == receiptThankYou)&&(identical(other.receiptQrUrl, receiptQrUrl) || other.receiptQrUrl == receiptQrUrl)&&(identical(other.receiptQrCaption, receiptQrCaption) || other.receiptQrCaption == receiptQrCaption)&&(identical(other.logoRev, logoRev) || other.logoRev == logoRev)&&(identical(other.taxEnabled, taxEnabled) || other.taxEnabled == taxEnabled)&&(identical(other.taxRateBps, taxRateBps) || other.taxRateBps == taxRateBps)&&(identical(other.serviceEnabled, serviceEnabled) || other.serviceEnabled == serviceEnabled)&&(identical(other.serviceMode, serviceMode) || other.serviceMode == serviceMode)&&(identical(other.serviceRateBps, serviceRateBps) || other.serviceRateBps == serviceRateBps)&&(identical(other.serviceFixedAmount, serviceFixedAmount) || other.serviceFixedAmount == serviceFixedAmount)&&(identical(other.taxAfterDiscount, taxAfterDiscount) || other.taxAfterDiscount == taxAfterDiscount)&&(identical(other.businessDayStartHour, businessDayStartHour) || other.businessDayStartHour == businessDayStartHour)&&(identical(other.prepTargetMins, prepTargetMins) || other.prepTargetMins == prepTargetMins)&&(identical(other.pickupTargetMins, pickupTargetMins) || other.pickupTargetMins == pickupTargetMins)&&(identical(other.ungreetedMins, ungreetedMins) || other.ungreetedMins == ungreetedMins)&&(identical(other.ungreetedEscalateMins, ungreetedEscalateMins) || other.ungreetedEscalateMins == ungreetedEscalateMins)&&(identical(other.longStayMins, longStayMins) || other.longStayMins == longStayMins)&&(identical(other.idleTableMins, idleTableMins) || other.idleTableMins == idleTableMins)&&(identical(other.reservationGraceMins, reservationGraceMins) || other.reservationGraceMins == reservationGraceMins)&&(identical(other.ungreetedAlertEnabled, ungreetedAlertEnabled) || other.ungreetedAlertEnabled == ungreetedAlertEnabled)&&(identical(other.pickupAlertEnabled, pickupAlertEnabled) || other.pickupAlertEnabled == pickupAlertEnabled)&&(identical(other.soundNewOrder, soundNewOrder) || other.soundNewOrder == soundNewOrder)&&(identical(other.soundReady, soundReady) || other.soundReady == soundReady)&&(identical(other.soundVoid, soundVoid) || other.soundVoid == soundVoid)&&(identical(other.soundOverdue, soundOverdue) || other.soundOverdue == soundOverdue)&&(identical(other.soundUngreeted, soundUngreeted) || other.soundUngreeted == soundUngreeted)&&(identical(other.soundPickup, soundPickup) || other.soundPickup == soundPickup)&&(identical(other.membersEnabled, membersEnabled) || other.membersEnabled == membersEnabled)&&(identical(other.memberMirrorEnabled, memberMirrorEnabled) || other.memberMirrorEnabled == memberMirrorEnabled)&&(identical(other.memberPointsEnabled, memberPointsEnabled) || other.memberPointsEnabled == memberPointsEnabled)&&(identical(other.memberPunchEnabled, memberPunchEnabled) || other.memberPunchEnabled == memberPunchEnabled)&&(identical(other.memberPresetId, memberPresetId) || other.memberPresetId == memberPresetId)&&(identical(other.memberEarnPerThousand, memberEarnPerThousand) || other.memberEarnPerThousand == memberEarnPerThousand)&&(identical(other.memberPointValue, memberPointValue) || other.memberPointValue == memberPointValue)&&(identical(other.memberRedeemMin, memberRedeemMin) || other.memberRedeemMin == memberRedeemMin)&&(identical(other.memberPunchItemId, memberPunchItemId) || other.memberPunchItemId == memberPunchItemId)&&(identical(other.memberPunchTarget, memberPunchTarget) || other.memberPunchTarget == memberPunchTarget)&&(identical(other.memberDebtEnabled, memberDebtEnabled) || other.memberDebtEnabled == memberDebtEnabled)&&(identical(other.memberDebtLimit, memberDebtLimit) || other.memberDebtLimit == memberDebtLimit)&&(identical(other.memberDebtOverdueDays, memberDebtOverdueDays) || other.memberDebtOverdueDays == memberDebtOverdueDays)&&(identical(other.guestOrderingEnabled, guestOrderingEnabled) || other.guestOrderingEnabled == guestOrderingEnabled)&&(identical(other.guestNoteEnabled, guestNoteEnabled) || other.guestNoteEnabled == guestNoteEnabled)&&(identical(other.guestHoursStartMin, guestHoursStartMin) || other.guestHoursStartMin == guestHoursStartMin)&&(identical(other.guestHoursEndMin, guestHoursEndMin) || other.guestHoursEndMin == guestHoursEndMin)&&(identical(other.guestMaxItems, guestMaxItems) || other.guestMaxItems == guestMaxItems)&&(identical(other.guestSessionHours, guestSessionHours) || other.guestSessionHours == guestSessionHours)&&(identical(other.soundGuestPending, soundGuestPending) || other.soundGuestPending == soundGuestPending)&&(identical(other.tableExpenseEnabled, tableExpenseEnabled) || other.tableExpenseEnabled == tableExpenseEnabled)&&const DeepCollectionEquality().equals(other._modules, _modules)&&const DeepCollectionEquality().equals(other._counterConfig, _counterConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,legalName,address,phone,receiptHeader,receiptFooter,receiptTagline,receiptSocial,receiptThankYou,receiptQrUrl,receiptQrCaption,logoRev,taxEnabled,taxRateBps,serviceEnabled,serviceMode,serviceRateBps,serviceFixedAmount,taxAfterDiscount,businessDayStartHour,prepTargetMins,pickupTargetMins,ungreetedMins,ungreetedEscalateMins,longStayMins,idleTableMins,reservationGraceMins,ungreetedAlertEnabled,pickupAlertEnabled,soundNewOrder,soundReady,soundVoid,soundOverdue,soundUngreeted,soundPickup,membersEnabled,memberMirrorEnabled,memberPointsEnabled,memberPunchEnabled,memberPresetId,memberEarnPerThousand,memberPointValue,memberRedeemMin,memberPunchItemId,memberPunchTarget,memberDebtEnabled,memberDebtLimit,memberDebtOverdueDays,guestOrderingEnabled,guestNoteEnabled,guestHoursStartMin,guestHoursEndMin,guestMaxItems,guestSessionHours,soundGuestPending,tableExpenseEnabled,const DeepCollectionEquality().hash(_modules),const DeepCollectionEquality().hash(_counterConfig)]);

@override
String toString() {
  return 'VenueSettingsDto(id: $id, displayName: $displayName, legalName: $legalName, address: $address, phone: $phone, receiptHeader: $receiptHeader, receiptFooter: $receiptFooter, receiptTagline: $receiptTagline, receiptSocial: $receiptSocial, receiptThankYou: $receiptThankYou, receiptQrUrl: $receiptQrUrl, receiptQrCaption: $receiptQrCaption, logoRev: $logoRev, taxEnabled: $taxEnabled, taxRateBps: $taxRateBps, serviceEnabled: $serviceEnabled, serviceMode: $serviceMode, serviceRateBps: $serviceRateBps, serviceFixedAmount: $serviceFixedAmount, taxAfterDiscount: $taxAfterDiscount, businessDayStartHour: $businessDayStartHour, prepTargetMins: $prepTargetMins, pickupTargetMins: $pickupTargetMins, ungreetedMins: $ungreetedMins, ungreetedEscalateMins: $ungreetedEscalateMins, longStayMins: $longStayMins, idleTableMins: $idleTableMins, reservationGraceMins: $reservationGraceMins, ungreetedAlertEnabled: $ungreetedAlertEnabled, pickupAlertEnabled: $pickupAlertEnabled, soundNewOrder: $soundNewOrder, soundReady: $soundReady, soundVoid: $soundVoid, soundOverdue: $soundOverdue, soundUngreeted: $soundUngreeted, soundPickup: $soundPickup, membersEnabled: $membersEnabled, memberMirrorEnabled: $memberMirrorEnabled, memberPointsEnabled: $memberPointsEnabled, memberPunchEnabled: $memberPunchEnabled, memberPresetId: $memberPresetId, memberEarnPerThousand: $memberEarnPerThousand, memberPointValue: $memberPointValue, memberRedeemMin: $memberRedeemMin, memberPunchItemId: $memberPunchItemId, memberPunchTarget: $memberPunchTarget, memberDebtEnabled: $memberDebtEnabled, memberDebtLimit: $memberDebtLimit, memberDebtOverdueDays: $memberDebtOverdueDays, guestOrderingEnabled: $guestOrderingEnabled, guestNoteEnabled: $guestNoteEnabled, guestHoursStartMin: $guestHoursStartMin, guestHoursEndMin: $guestHoursEndMin, guestMaxItems: $guestMaxItems, guestSessionHours: $guestSessionHours, soundGuestPending: $soundGuestPending, tableExpenseEnabled: $tableExpenseEnabled, modules: $modules, counterConfig: $counterConfig)';
}


}

/// @nodoc
abstract mixin class _$VenueSettingsDtoCopyWith<$Res> implements $VenueSettingsDtoCopyWith<$Res> {
  factory _$VenueSettingsDtoCopyWith(_VenueSettingsDto value, $Res Function(_VenueSettingsDto) _then) = __$VenueSettingsDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String legalName, String address, String phone, String receiptHeader, String receiptFooter, String receiptTagline, String receiptSocial, String receiptThankYou, String receiptQrUrl, String receiptQrCaption, int logoRev, bool taxEnabled, int taxRateBps, bool serviceEnabled, String serviceMode, int serviceRateBps, int serviceFixedAmount, bool taxAfterDiscount, int businessDayStartHour, int prepTargetMins, int pickupTargetMins, int ungreetedMins, int ungreetedEscalateMins, int longStayMins, int idleTableMins, int reservationGraceMins, bool ungreetedAlertEnabled, bool pickupAlertEnabled, String soundNewOrder, String soundReady, String soundVoid, String soundOverdue, String soundUngreeted, String soundPickup, bool membersEnabled, bool memberMirrorEnabled, bool memberPointsEnabled, bool memberPunchEnabled, String? memberPresetId, int memberEarnPerThousand, int memberPointValue, int memberRedeemMin, String? memberPunchItemId, int memberPunchTarget, bool memberDebtEnabled, int memberDebtLimit, int memberDebtOverdueDays, bool guestOrderingEnabled, bool guestNoteEnabled, int guestHoursStartMin, int guestHoursEndMin, int guestMaxItems, int guestSessionHours, String soundGuestPending, bool tableExpenseEnabled, List<String>? modules, List<String>? counterConfig
});




}
/// @nodoc
class __$VenueSettingsDtoCopyWithImpl<$Res>
    implements _$VenueSettingsDtoCopyWith<$Res> {
  __$VenueSettingsDtoCopyWithImpl(this._self, this._then);

  final _VenueSettingsDto _self;
  final $Res Function(_VenueSettingsDto) _then;

/// Create a copy of VenueSettingsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? legalName = null,Object? address = null,Object? phone = null,Object? receiptHeader = null,Object? receiptFooter = null,Object? receiptTagline = null,Object? receiptSocial = null,Object? receiptThankYou = null,Object? receiptQrUrl = null,Object? receiptQrCaption = null,Object? logoRev = null,Object? taxEnabled = null,Object? taxRateBps = null,Object? serviceEnabled = null,Object? serviceMode = null,Object? serviceRateBps = null,Object? serviceFixedAmount = null,Object? taxAfterDiscount = null,Object? businessDayStartHour = null,Object? prepTargetMins = null,Object? pickupTargetMins = null,Object? ungreetedMins = null,Object? ungreetedEscalateMins = null,Object? longStayMins = null,Object? idleTableMins = null,Object? reservationGraceMins = null,Object? ungreetedAlertEnabled = null,Object? pickupAlertEnabled = null,Object? soundNewOrder = null,Object? soundReady = null,Object? soundVoid = null,Object? soundOverdue = null,Object? soundUngreeted = null,Object? soundPickup = null,Object? membersEnabled = null,Object? memberMirrorEnabled = null,Object? memberPointsEnabled = null,Object? memberPunchEnabled = null,Object? memberPresetId = freezed,Object? memberEarnPerThousand = null,Object? memberPointValue = null,Object? memberRedeemMin = null,Object? memberPunchItemId = freezed,Object? memberPunchTarget = null,Object? memberDebtEnabled = null,Object? memberDebtLimit = null,Object? memberDebtOverdueDays = null,Object? guestOrderingEnabled = null,Object? guestNoteEnabled = null,Object? guestHoursStartMin = null,Object? guestHoursEndMin = null,Object? guestMaxItems = null,Object? guestSessionHours = null,Object? soundGuestPending = null,Object? tableExpenseEnabled = null,Object? modules = freezed,Object? counterConfig = freezed,}) {
  return _then(_VenueSettingsDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,legalName: null == legalName ? _self.legalName : legalName // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,receiptHeader: null == receiptHeader ? _self.receiptHeader : receiptHeader // ignore: cast_nullable_to_non_nullable
as String,receiptFooter: null == receiptFooter ? _self.receiptFooter : receiptFooter // ignore: cast_nullable_to_non_nullable
as String,receiptTagline: null == receiptTagline ? _self.receiptTagline : receiptTagline // ignore: cast_nullable_to_non_nullable
as String,receiptSocial: null == receiptSocial ? _self.receiptSocial : receiptSocial // ignore: cast_nullable_to_non_nullable
as String,receiptThankYou: null == receiptThankYou ? _self.receiptThankYou : receiptThankYou // ignore: cast_nullable_to_non_nullable
as String,receiptQrUrl: null == receiptQrUrl ? _self.receiptQrUrl : receiptQrUrl // ignore: cast_nullable_to_non_nullable
as String,receiptQrCaption: null == receiptQrCaption ? _self.receiptQrCaption : receiptQrCaption // ignore: cast_nullable_to_non_nullable
as String,logoRev: null == logoRev ? _self.logoRev : logoRev // ignore: cast_nullable_to_non_nullable
as int,taxEnabled: null == taxEnabled ? _self.taxEnabled : taxEnabled // ignore: cast_nullable_to_non_nullable
as bool,taxRateBps: null == taxRateBps ? _self.taxRateBps : taxRateBps // ignore: cast_nullable_to_non_nullable
as int,serviceEnabled: null == serviceEnabled ? _self.serviceEnabled : serviceEnabled // ignore: cast_nullable_to_non_nullable
as bool,serviceMode: null == serviceMode ? _self.serviceMode : serviceMode // ignore: cast_nullable_to_non_nullable
as String,serviceRateBps: null == serviceRateBps ? _self.serviceRateBps : serviceRateBps // ignore: cast_nullable_to_non_nullable
as int,serviceFixedAmount: null == serviceFixedAmount ? _self.serviceFixedAmount : serviceFixedAmount // ignore: cast_nullable_to_non_nullable
as int,taxAfterDiscount: null == taxAfterDiscount ? _self.taxAfterDiscount : taxAfterDiscount // ignore: cast_nullable_to_non_nullable
as bool,businessDayStartHour: null == businessDayStartHour ? _self.businessDayStartHour : businessDayStartHour // ignore: cast_nullable_to_non_nullable
as int,prepTargetMins: null == prepTargetMins ? _self.prepTargetMins : prepTargetMins // ignore: cast_nullable_to_non_nullable
as int,pickupTargetMins: null == pickupTargetMins ? _self.pickupTargetMins : pickupTargetMins // ignore: cast_nullable_to_non_nullable
as int,ungreetedMins: null == ungreetedMins ? _self.ungreetedMins : ungreetedMins // ignore: cast_nullable_to_non_nullable
as int,ungreetedEscalateMins: null == ungreetedEscalateMins ? _self.ungreetedEscalateMins : ungreetedEscalateMins // ignore: cast_nullable_to_non_nullable
as int,longStayMins: null == longStayMins ? _self.longStayMins : longStayMins // ignore: cast_nullable_to_non_nullable
as int,idleTableMins: null == idleTableMins ? _self.idleTableMins : idleTableMins // ignore: cast_nullable_to_non_nullable
as int,reservationGraceMins: null == reservationGraceMins ? _self.reservationGraceMins : reservationGraceMins // ignore: cast_nullable_to_non_nullable
as int,ungreetedAlertEnabled: null == ungreetedAlertEnabled ? _self.ungreetedAlertEnabled : ungreetedAlertEnabled // ignore: cast_nullable_to_non_nullable
as bool,pickupAlertEnabled: null == pickupAlertEnabled ? _self.pickupAlertEnabled : pickupAlertEnabled // ignore: cast_nullable_to_non_nullable
as bool,soundNewOrder: null == soundNewOrder ? _self.soundNewOrder : soundNewOrder // ignore: cast_nullable_to_non_nullable
as String,soundReady: null == soundReady ? _self.soundReady : soundReady // ignore: cast_nullable_to_non_nullable
as String,soundVoid: null == soundVoid ? _self.soundVoid : soundVoid // ignore: cast_nullable_to_non_nullable
as String,soundOverdue: null == soundOverdue ? _self.soundOverdue : soundOverdue // ignore: cast_nullable_to_non_nullable
as String,soundUngreeted: null == soundUngreeted ? _self.soundUngreeted : soundUngreeted // ignore: cast_nullable_to_non_nullable
as String,soundPickup: null == soundPickup ? _self.soundPickup : soundPickup // ignore: cast_nullable_to_non_nullable
as String,membersEnabled: null == membersEnabled ? _self.membersEnabled : membersEnabled // ignore: cast_nullable_to_non_nullable
as bool,memberMirrorEnabled: null == memberMirrorEnabled ? _self.memberMirrorEnabled : memberMirrorEnabled // ignore: cast_nullable_to_non_nullable
as bool,memberPointsEnabled: null == memberPointsEnabled ? _self.memberPointsEnabled : memberPointsEnabled // ignore: cast_nullable_to_non_nullable
as bool,memberPunchEnabled: null == memberPunchEnabled ? _self.memberPunchEnabled : memberPunchEnabled // ignore: cast_nullable_to_non_nullable
as bool,memberPresetId: freezed == memberPresetId ? _self.memberPresetId : memberPresetId // ignore: cast_nullable_to_non_nullable
as String?,memberEarnPerThousand: null == memberEarnPerThousand ? _self.memberEarnPerThousand : memberEarnPerThousand // ignore: cast_nullable_to_non_nullable
as int,memberPointValue: null == memberPointValue ? _self.memberPointValue : memberPointValue // ignore: cast_nullable_to_non_nullable
as int,memberRedeemMin: null == memberRedeemMin ? _self.memberRedeemMin : memberRedeemMin // ignore: cast_nullable_to_non_nullable
as int,memberPunchItemId: freezed == memberPunchItemId ? _self.memberPunchItemId : memberPunchItemId // ignore: cast_nullable_to_non_nullable
as String?,memberPunchTarget: null == memberPunchTarget ? _self.memberPunchTarget : memberPunchTarget // ignore: cast_nullable_to_non_nullable
as int,memberDebtEnabled: null == memberDebtEnabled ? _self.memberDebtEnabled : memberDebtEnabled // ignore: cast_nullable_to_non_nullable
as bool,memberDebtLimit: null == memberDebtLimit ? _self.memberDebtLimit : memberDebtLimit // ignore: cast_nullable_to_non_nullable
as int,memberDebtOverdueDays: null == memberDebtOverdueDays ? _self.memberDebtOverdueDays : memberDebtOverdueDays // ignore: cast_nullable_to_non_nullable
as int,guestOrderingEnabled: null == guestOrderingEnabled ? _self.guestOrderingEnabled : guestOrderingEnabled // ignore: cast_nullable_to_non_nullable
as bool,guestNoteEnabled: null == guestNoteEnabled ? _self.guestNoteEnabled : guestNoteEnabled // ignore: cast_nullable_to_non_nullable
as bool,guestHoursStartMin: null == guestHoursStartMin ? _self.guestHoursStartMin : guestHoursStartMin // ignore: cast_nullable_to_non_nullable
as int,guestHoursEndMin: null == guestHoursEndMin ? _self.guestHoursEndMin : guestHoursEndMin // ignore: cast_nullable_to_non_nullable
as int,guestMaxItems: null == guestMaxItems ? _self.guestMaxItems : guestMaxItems // ignore: cast_nullable_to_non_nullable
as int,guestSessionHours: null == guestSessionHours ? _self.guestSessionHours : guestSessionHours // ignore: cast_nullable_to_non_nullable
as int,soundGuestPending: null == soundGuestPending ? _self.soundGuestPending : soundGuestPending // ignore: cast_nullable_to_non_nullable
as String,tableExpenseEnabled: null == tableExpenseEnabled ? _self.tableExpenseEnabled : tableExpenseEnabled // ignore: cast_nullable_to_non_nullable
as bool,modules: freezed == modules ? _self._modules : modules // ignore: cast_nullable_to_non_nullable
as List<String>?,counterConfig: freezed == counterConfig ? _self._counterConfig : counterConfig // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
