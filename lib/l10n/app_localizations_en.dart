// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Loading…';

  @override
  String get error => 'Failed';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get warning => 'Warning';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get discardCartTitle => 'Discard this order?';

  @override
  String discardCartBody(int items) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items unsent items will be discarded.',
      one: '1 unsent item will be discarded.',
    );
    return '$_temp0';
  }

  @override
  String get discardCartConfirm => 'Yes, discard';

  @override
  String get stepperIncrease => 'Add one';

  @override
  String get stepperDecrease => 'Remove one';

  @override
  String get venueHubTitle => 'Venue';

  @override
  String get venueHubSubtitle =>
      'Configuration · zones · menu · system · staff';

  @override
  String get venueHubSectionZona => 'Zones';

  @override
  String get venueHubSectionZonaSub => 'Set up zones, tables and room capacity';

  @override
  String get venueHubSectionMenu => 'Menu';

  @override
  String get venueHubSectionMenuSub =>
      'Categories, items, modifiers and prices';

  @override
  String get venueHubSectionVenue => 'Venue settings';

  @override
  String get venueHubSectionVenueSub =>
      'Profile, locale, tax and receipt branding';

  @override
  String get venueHubSectionSystem => 'System';

  @override
  String get venueHubSectionSystemSub => 'Server, network, printers, devices';

  @override
  String get venueHubSectionStaff => 'Staff';

  @override
  String get venueHubSectionStaffSub => 'Accounts, roles and team PINs';

  @override
  String get venueHubSectionStock => 'Stock';

  @override
  String get venueHubSectionStockSub =>
      'Ingredients, receiving, stocktake and production';

  @override
  String get venueHubSectionReports => 'Reports';

  @override
  String get venueHubSectionReportsSub => 'Shift summary, sales and export';

  @override
  String get venueHubSectionAlerts => 'Alerts';

  @override
  String get venueHubSectionAlertsSub => 'Thresholds, sounds and device mute';

  @override
  String get venueHubSectionAudit => 'Audit';

  @override
  String get venueHubSectionAuditSub =>
      'Voids, comps, discounts and order edits';

  @override
  String get auditTitle => 'Audit log';

  @override
  String get auditSubtitle => 'Every event · full trail';

  @override
  String get auditTabletOnly => 'Needs a tablet screen';

  @override
  String get auditTabletOnlyBody =>
      'The audit log shows six columns at once so it reads at a glance. Open it on a tablet.';

  @override
  String get auditTabletOnlyBadge => 'Tablet only';

  @override
  String get auditEmpty => 'No events yet';

  @override
  String get auditEmptyBody =>
      'Voids, comps, discounts, refunds and order edits will show up here.';

  @override
  String get auditExport => 'Export';

  @override
  String get auditColTime => 'Time';

  @override
  String get auditColType => 'Type';

  @override
  String get auditColUser => 'User';

  @override
  String get auditColEvent => 'Event';

  @override
  String get auditColAmount => 'Amount';

  @override
  String get auditColReason => 'Reason';

  @override
  String get auditSystemActor => 'System';

  @override
  String get auditWindowToday => 'Today';

  @override
  String get auditWindowYesterday => 'Yesterday';

  @override
  String get auditWindowWeek => '7 days';

  @override
  String get auditWindowAll => 'All time';

  @override
  String get auditTypeAll => 'All types';

  @override
  String get auditTileVoid => 'Voids';

  @override
  String get auditTileComp => 'Comps';

  @override
  String get auditTileDiscount => 'Discounts';

  @override
  String get auditTileRefund => 'Refunds';

  @override
  String get auditTileKilled => 'Sold out';

  @override
  String get auditTileModify => 'Order edits';

  @override
  String auditEventCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n events',
      one: '1 event',
    );
    return '$_temp0';
  }

  @override
  String auditNewRows(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n new',
      one: '1 new',
    );
    return '$_temp0';
  }

  @override
  String get auditTypeFire => 'Fire';

  @override
  String get auditTypeModify => 'Edit';

  @override
  String get auditTypeVoidItem => 'Void';

  @override
  String get auditTypeComp => 'Comp';

  @override
  String get auditTypeTableMoved => 'Move';

  @override
  String get auditTypePaymentRecorded => 'Payment';

  @override
  String get auditTypeRefund => 'Refund';

  @override
  String get auditTypeDiscountApplied => 'Discount';

  @override
  String get auditTypeDiscountRemoved => 'Discount−';

  @override
  String get auditTypeBillReopened => 'Reopen';

  @override
  String get auditTypeBillClosed => 'Close';

  @override
  String get auditTypeCashMovement => 'Cash';

  @override
  String get auditTypeMemberChanged => 'Member';

  @override
  String get auditTypeStockCounted => 'Stocktake';

  @override
  String get auditTypeMenuKilled => 'Sold out';

  @override
  String get auditTypeMenuRestored => 'On sale';

  @override
  String get auditTypeStaffCreated => 'Staff +';

  @override
  String get auditTypeStaffDeleted => 'Staff −';

  @override
  String get auditTypeStaffDisabled => 'Disabled';

  @override
  String get auditTypeStaffEnabled => 'Enabled';

  @override
  String get auditTypeStaffRoleChanged => 'Role';

  @override
  String get auditTypeStaffPinSet => 'PIN';

  @override
  String get auditTypeStaffPinReset => 'PIN reset';

  @override
  String get auditTypeRoleCreated => 'Role +';

  @override
  String get auditTypeRoleRenamed => 'Role edit';

  @override
  String get auditTypeRoleDeleted => 'Role −';

  @override
  String get auditTypeRoleColorChanged => 'Role colour';

  @override
  String get auditTypeRoleCapabilityChanged => 'Permissions';

  @override
  String get killReasonTitle => 'Mark sold out';

  @override
  String get killReasonHint => 'Other reason (optional)';

  @override
  String get killReasonSkip => 'Skip';

  @override
  String get killReasonConfirm => 'Mark sold out';

  @override
  String killReasonBody(String item) {
    return '$item cannot be ordered until it is switched back on. The reason goes into the audit log.';
  }

  @override
  String get venueHubSeedTitle => 'Quick start';

  @override
  String get venueHubSeedBody =>
      'Load sample data for a generic restaurant: 4 zones with 20 tables, a full menu, 4 staff (2 waiters & 2 kitchen), and a month of sales history so reports and the audit log read properly from day one. All of it can be edited or cleared at any time.';

  @override
  String get venueHubSeedBodyRunning =>
      'Building a month of history through the real order path. Keep the app open until it finishes.';

  @override
  String get venueHubSeedBodyDone =>
      'Sample data is ready. Reports, audit log and stock history are populated.';

  @override
  String get venueHubSeedBodyIncomplete =>
      'Loading sample data stopped before it finished. What is there is incomplete — clear it before loading again.';

  @override
  String get venueHubSeedBodyFailed =>
      'Loading sample data failed. What made it in is incomplete — clear it before trying again.';

  @override
  String get venueHubSeedBodyLoaded =>
      'This venue is running on sample data. Clear it to drop the invented sales history; zones, tables, menu and staff stay.';

  @override
  String get venueHubSeedBtnLoad => 'Load sample data';

  @override
  String get venueHubSeedBtnSkip => 'Skip';

  @override
  String get venueHubSeedBtnClear => 'Clear sample data';

  @override
  String get venueHubSeedBtnClearRetry => 'Clear & reload';

  @override
  String get venueHubSeedBtnDone => 'Done';

  @override
  String get venueHubSeedError => 'Could not load sample data';

  @override
  String get venueHubSeedProgress => 'Building sample data';

  @override
  String venueHubSeedDays(int done, int total) {
    return 'day $done/$total';
  }

  @override
  String get settingsSeedTitle => 'Sample data';

  @override
  String get venueSettingsTitle => 'Venue settings';

  @override
  String get venueSettingsSubtitle => 'Profile, locale, tax, receipt';

  @override
  String get venueSettingsSectionIdentity => 'Profile & address';

  @override
  String get venueSettingsSectionIdentityTag => 'REQUIRED';

  @override
  String get venueSettingsDisplayName => 'Display name';

  @override
  String get venueSettingsLegalName => 'Legal name';

  @override
  String get venueSettingsAddress => 'Address';

  @override
  String get venueSettingsPhone => 'Phone';

  @override
  String get venueSettingsManagedBySuperAdmin => 'Managed by operator';

  @override
  String get venueSettingsSectionReceipt => 'Receipt branding';

  @override
  String get venueSettingsSectionReceiptTag => 'PRINT';

  @override
  String get venueSettingsLogo => 'Logo';

  @override
  String get venueSettingsLogoAdd => 'Add';

  @override
  String get venueSettingsLogoChange => 'Replace';

  @override
  String get venueSettingsLogoDelete => 'Remove';

  @override
  String get venueSettingsTagline => 'Tagline';

  @override
  String get venueSettingsHeader => 'Header';

  @override
  String get venueSettingsSocial => 'Social';

  @override
  String get venueSettingsFooter => 'Footer';

  @override
  String get venueSettingsThankYou => 'Thank-you line';

  @override
  String get venueSettingsQrUrl => 'QR (URL)';

  @override
  String get venueSettingsQrCaption => 'QR (caption)';

  @override
  String get venueSettingsSectionTax => 'Tax & service';

  @override
  String get venueSettingsSectionReports => 'Reports & shift';

  @override
  String get venueSettingsSectionSound => 'Sound';

  @override
  String get venueSettingsSoundNewOrder => 'New order';

  @override
  String get venueSettingsSoundReady => 'Order ready';

  @override
  String get venueSettingsSoundVoid => 'Void';

  @override
  String get venueSettingsSoundOverdue => 'Overdue';

  @override
  String get venueSettingsSoundUngreeted => 'Not greeted';

  @override
  String get venueSettingsSoundPickup => 'Waiting to run';

  @override
  String get venueSettingsSoundPreview => 'Play';

  @override
  String get venueSettingsTimingPrepTarget => 'Ready target (all menu default)';

  @override
  String get venueSettingsTimingPrepTargetHint =>
      'Menu items with no \"Ready target\" of their own follow this number.';

  @override
  String get venueSettingsTimingPickup => 'Waiting to run';

  @override
  String get venueSettingsTimingPickupHint =>
      'Food ready but not yet run for this long. The switch silences the sound only — the mark on the table card keeps working.';

  @override
  String get venueSettingsTimingUngreeted => 'Not greeted';

  @override
  String get venueSettingsTimingUngreetedHint =>
      'Table seated but nothing sent yet. The switch silences the sound only — the mark on the table card keeps working.';

  @override
  String get venueSettingsTimingUngreetedEscalate =>
      'Escalate to all waiters after';

  @override
  String get venueSettingsTimingUngreetedEscalateHint =>
      'At first only the waiter who seated the guests.';

  @override
  String get venueSettingsTimingLongStay => 'Long stay';

  @override
  String get venueSettingsTimingLongStayHint =>
      'A visual mark on the floor. No sound.';

  @override
  String get venueSettingsTimingIdle => 'Finished eating';

  @override
  String get venueSettingsTimingIdleHint =>
      'Everything served and no activity. No sound.';

  @override
  String get venueSettingsTimingReservationGrace => 'Booking grace';

  @override
  String get venueSettingsTimingReservationGraceHint =>
      'Past this the booking chip is marked late. The status does not change.';

  @override
  String get venueSettingsTimingMuteTitle => 'Mute on this device';

  @override
  String get venueSettingsTimingMuteHint =>
      'This device only. The tone choice stays with the venue.';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertsSectionThresholds => 'Thresholds';

  @override
  String get alertsScopeVenue => 'All devices';

  @override
  String get alertsScopeDevice => 'This device only';

  @override
  String get tableStateUngreeted => 'Not greeted';

  @override
  String get tableStateIdle => 'Finished eating';

  @override
  String get reservationLate => 'Late';

  @override
  String staleReadyUncollected(int mins) {
    return 'Ready $mins min — not collected';
  }

  @override
  String staleReservationLate(int mins) {
    return 'Guest $mins min late — release table?';
  }

  @override
  String staleUngreeted(int mins) {
    return 'Not greeted $mins min';
  }

  @override
  String staleIdle(int mins) {
    return 'Finished eating $mins min — offer again';
  }

  @override
  String staleLongStay(String elapsed) {
    return 'Seated $elapsed — check closing';
  }

  @override
  String get tableOwnerMine => 'Mine';

  @override
  String get tablePaidFull => 'Settled';

  @override
  String get tablePaidPartial => 'Part-paid';

  @override
  String get tableNoReservationTable => 'No table yet';

  @override
  String get floorReservations => 'Bookings';

  @override
  String get floorTakeaway => 'Takeaway';

  @override
  String get floorReservationsBook => 'Booking book';

  @override
  String get floorReservationsLateCount => 'late';

  @override
  String get reservationFilterWaiting => 'Waiting';

  @override
  String get reservationFilterLate => 'Late';

  @override
  String get reservationFilterSeated => 'Seated';

  @override
  String get reservationFilterNoShow => 'No-show';

  @override
  String get reservationFilterAll => 'All';

  @override
  String get reservationEmptyFilter => 'No bookings in this filter.';

  @override
  String get reservationActionSeat => 'Seat';

  @override
  String get reservationActionLate => 'Late';

  @override
  String get reservationActionNoShow => 'No-show';

  @override
  String get reservationActionRestore => 'Restore';

  @override
  String get takeawayEmpty => 'No takeaway orders yet.';

  @override
  String get zoneAdminTitle => 'Zone setup';

  @override
  String get tablesEmptyZoneAddTableHint => 'Add tables via Manager › Zones';

  @override
  String get zoneAdminZonePill => 'Zone';

  @override
  String get zoneAdminAddTable => 'Add table';

  @override
  String get zoneAdminAddZone => 'Add zone';

  @override
  String get zoneAdminEmptyZone => 'No tables yet in';

  @override
  String get zoneAdminNoZones => 'No zones yet';

  @override
  String get zoneAdminNoZonesCreate => 'Create a zone first to lay out tables.';

  @override
  String get zoneAdminNoZonesCreateRequest => 'Ask an admin to create a zone.';

  @override
  String get zoneAdminEditTable => 'Set up';

  @override
  String get zoneAdminNewTable => 'New table';

  @override
  String get zoneAdminTableName => 'Table name';

  @override
  String get zoneAdminMaxCapacity => 'Max guest capacity';

  @override
  String get zoneAdminTableActive => 'Table active';

  @override
  String get zoneAdminTableActiveSub =>
      'Switch off for repairs without deleting.';

  @override
  String get zoneAdminDeleteTableConfirmTitle => 'Delete table?';

  @override
  String get zoneAdminDeleteTableConfirmSub =>
      'will be permanently removed from the zone.';

  @override
  String get tabMeja => 'Floor';

  @override
  String get tabPesanan => 'Orders';

  @override
  String get tabAntrian => 'Queue';

  @override
  String get tabKasir => 'Cashier';

  @override
  String get tabVenue => 'Venue';

  @override
  String get tabSaya => 'Me';

  @override
  String get shiftLabel => 'SHIFT';

  @override
  String get kasirRiwayatBatas =>
      'Showing the most recent bills. Older ones are in Reports.';

  @override
  String get kitchenQueueTitle => 'Prep Queue';

  @override
  String get hapusPencarian => 'Clear search';

  @override
  String get takAdaItemCocok => 'No matching items';

  @override
  String get crumbTambahItem => 'Add item';

  @override
  String get crumbTinjau => 'Review';

  @override
  String get crumbBawaPulang => 'Takeaway';

  @override
  String get crumbPesananBaru => 'New order';

  @override
  String get crumbDiskon => 'Discount';

  @override
  String get crumbMenuAdmin => 'Menu admin';

  @override
  String get crumbStafAkun => 'Staff & accounts';

  @override
  String get crumbLaporanShift => 'Shift report';

  @override
  String get crumbKonfigurasi => 'Configuration';

  @override
  String get themeSheetTitle => 'Theme';

  @override
  String get themeSheetSubtitle => 'Applies to this device only';

  @override
  String get localeSheetTitle => 'Language';

  @override
  String get localeSheetSubtitle => 'Applies to this device only';

  @override
  String get localeIndonesian => 'Bahasa Indonesia';

  @override
  String get localeEnglish => 'English';

  @override
  String get a11yPickLocale => 'Pick a language';

  @override
  String get a11yGuestDecrease => 'Fewer guests';

  @override
  String get a11yGuestIncrease => 'More guests';

  @override
  String get a11yEdit => 'Edit';

  @override
  String get zoneAdminIcon => 'Zone icon';

  @override
  String get tableGuests => 'Guests';

  @override
  String get quantity => 'Quantity';

  @override
  String get a11yRename => 'Rename';

  @override
  String get a11yClear => 'Clear';

  @override
  String get a11yRefresh => 'Reload';

  @override
  String get a11yShowPassword => 'Show password';

  @override
  String get a11yHidePassword => 'Hide password';

  @override
  String get a11ySoundPreview => 'Play tone';

  @override
  String get a11ySoundSilent => 'No tone';

  @override
  String get a11yPickTheme => 'Pick a theme';

  @override
  String get a11yViewPhoto => 'View payment proof photo';

  @override
  String get a11yPickColor => 'Pick a colour';

  @override
  String get a11yAddItem => 'Add item';

  @override
  String get a11yTableLocked => 'Table locked';

  @override
  String resetRequestMessage(String email) {
    return 'Hello, I have forgotten my SatSet admin password.\nEmail: $email\nPlease help me reset it.';
  }

  @override
  String get resetRequestFailed => 'Could not open WhatsApp.';

  @override
  String billingRequestMessage(String venueName, String venueId) {
    return 'Hello, I would like to renew my SatSet subscription.\nVenue: $venueName\nID: $venueId\nPlease help.';
  }

  @override
  String billingEndsIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Subscription ends in $days days.',
      one: 'Subscription ends in 1 day.',
      zero: 'Subscription ends today.',
    );
    return '$_temp0';
  }

  @override
  String get billingLapsed => 'The subscription has lapsed.';

  @override
  String billingStopsOn(String date) {
    return 'The venue stops trading on $date.';
  }

  @override
  String get billingCta => 'Tap to renew over WhatsApp.';

  @override
  String updateAvailable(String latest, String installed) {
    return 'Version $latest is available. This device is on $installed.';
  }

  @override
  String get updateAction => 'Update';

  @override
  String get updateBlockedTitle => 'This version is no longer supported';

  @override
  String updateBlockedBody(String installed, String min) {
    return 'This device is running $installed. The minimum version is now $min.';
  }

  @override
  String get updateBlockedAskAdmin => 'Ask an admin to update this device.';

  @override
  String updateDownloading(int percent) {
    return 'Downloading $percent%';
  }

  @override
  String get updateInstalling => 'Opening the installer...';

  @override
  String get updateFailed =>
      'Download failed. Check the connection and try again.';

  @override
  String get updateRetry => 'Try again';

  @override
  String get updatePermissionNeeded =>
      'Allow app installs from SatSet, then try again.';

  @override
  String get fltReleaseGate => 'Release gate';

  @override
  String get fltReleaseGateHint => 'Leave a field empty to clear that floor.';

  @override
  String get fltReleaseGateMin => 'Minimum (mandatory)';

  @override
  String get fltReleaseGateRecommended => 'Recommended';

  @override
  String get fltReleaseGateLatest => 'Latest';

  @override
  String get fltReleaseGateInvalid =>
      'Must be 1.2.3, and min <= recommended <= latest.';

  @override
  String get bootBlockStale =>
      'Internet is needed to verify the admin. Reconnect, then sign in again.';

  @override
  String get bootBlockIneligible =>
      'Admin access has been revoked. Contact the operator.';

  @override
  String get tempPasswordTitle => 'Change password';

  @override
  String get logout => 'Sign out';

  @override
  String get tempPasswordReason =>
      'You signed in with a temporary password. Create a new one to continue.';

  @override
  String get tempPasswordNew => 'New password';

  @override
  String get tempPasswordConfirm => 'Repeat new password';

  @override
  String tempPasswordTooShort(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'At least $min characters.',
      one: 'At least 1 character.',
    );
    return '$_temp0';
  }

  @override
  String get tempPasswordMismatch => 'The passwords do not match.';

  @override
  String get tempPasswordReused =>
      'The new password cannot be the same as the temporary one.';

  @override
  String get tempPasswordExpired =>
      'The temporary password has expired. Ask the operator for a new one.';

  @override
  String get tempPasswordPending =>
      'This account was just reset. Sign in with the temporary password to change it.';

  @override
  String get tempPasswordIssuedTitle => 'Temporary password';

  @override
  String get tempPasswordIssuedHint =>
      'Valid for 24 hours. Read it out to the venue admin — they must change it when they sign in.';

  @override
  String get tempPasswordIssuedOnce => 'This code is shown only once.';

  @override
  String tempPasswordShareMessage(String code) {
    return 'Your SatSet temporary password: $code\nValid for 24 hours. You will be asked to create a new one when you sign in.';
  }

  @override
  String get staffTitle => 'Staff & accounts';

  @override
  String get staffTabPeople => 'People';

  @override
  String get staffTabRoles => 'Roles';

  @override
  String get staffSearchHint => 'Search by name';

  @override
  String get staffFilterAll => 'All';

  @override
  String get staffAdd => 'Add staff';

  @override
  String get staffAddPill => '+ Add staff';

  @override
  String get staffEmpty => 'No staff match this filter';

  @override
  String get staffNewRolePill => '+ New role';

  @override
  String get staffRoleBadgeAdmin => 'ADMIN';

  @override
  String get staffRoleManagedByOperator => 'Managed by operator';

  @override
  String get staffRoleColor => 'Role colour';

  @override
  String get staffColor => 'Colour';

  @override
  String get staffAvatarColor => 'Avatar colour';

  @override
  String get staffRolePermsHint => 'Tap a role to set its permissions.';

  @override
  String get staffRoleLockedBanner =>
      'The admin role is managed by the operator. Its permissions can be seen, not changed.';

  @override
  String get staffCapAdminOnly =>
      'Granted only through the operator, never from this screen.';

  @override
  String get staffRole => 'Role';

  @override
  String get staffNoRole => 'No role';

  @override
  String get staffName => 'Name';

  @override
  String get staffFullName => 'Full name';

  @override
  String get staffPinField => 'PIN (6 digits, unique)';

  @override
  String get staffPinReset => 'Reset';

  @override
  String get staffPinUpdated => 'PIN updated';

  @override
  String get staffSaveChanges => 'Save changes';

  @override
  String get staffNewRoleName => 'New role name';

  @override
  String get staffRenameRole => 'Rename role';

  @override
  String get staffDisable => 'Disable';

  @override
  String get staffErrNameEmpty => 'Name cannot be empty';

  @override
  String get staffErrAdminBySuperOnly =>
      'The admin role can only be created by a super admin';

  @override
  String get staffErrAdminPromoteBlocked =>
      'Promoting to the admin role is not possible from here';

  @override
  String get staffErrNeedNonAdminRole => 'Create a non-admin role first';

  @override
  String get staffErrColorTaken =>
      'That avatar colour is already used by another account';

  @override
  String get staffErrColorTakenShort => 'Colour also used by another account';

  @override
  String get staffChangeRoleTitle => 'Change role?';

  @override
  String get staffDisableBody =>
      'The user cannot sign in again. Can be re-enabled later.';

  @override
  String get staffDeleteBody =>
      'The account is deleted permanently. Old audit entries stay.';

  @override
  String get staffDeleteRoleBody =>
      'The permissions attached to this role will be lost.';

  @override
  String staffSubtitle(int members, int admins) {
    String _temp0 = intl.Intl.pluralLogic(
      members,
      locale: localeName,
      other: '$members members',
      one: '1 member',
    );
    String _temp1 = intl.Intl.pluralLogic(
      admins,
      locale: localeName,
      other: '$admins admin',
      one: '1 admin',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String staffRolesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n custom roles',
      one: '1 custom role',
    );
    return '$_temp0';
  }

  @override
  String staffCapsCount(int held, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total permissions',
      one: '1 permission',
    );
    return '$held/$_temp0';
  }

  @override
  String capGrpCount(int on, int total) {
    return '$on/$total';
  }

  @override
  String staffMembersCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String staffCreated(String name, String pin) {
    return '$name created. PIN: $pin';
  }

  @override
  String staffNewPin(String pin) {
    return 'New PIN: $pin';
  }

  @override
  String staffRoleAdminSuffix(String name) {
    return '$name (admin)';
  }

  @override
  String staffDeleteRoleTitle(String name) {
    return 'Delete role “$name”?';
  }

  @override
  String staffChangeRoleBody(String name) {
    return 'Move $name to another role. Permissions change immediately.';
  }

  @override
  String staffDisableTitle(String name) {
    return 'Disable $name?';
  }

  @override
  String staffDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get payMethodCash => 'Cash';

  @override
  String get payMethodCard => 'Card';

  @override
  String get payMethodQris => 'QRIS';

  @override
  String get payMethodTransfer => 'Transfer';

  @override
  String get payMethodOther => 'Other';

  @override
  String get rangeToday => 'Today';

  @override
  String get rangeYesterday => 'Yesterday';

  @override
  String get rangeD7 => '7 days';

  @override
  String get rangeD30 => '30 days';

  @override
  String get rangeMonth => 'This month';

  @override
  String get rangeCustom => 'Custom';

  @override
  String get expPeriod => 'Period';

  @override
  String get expRange => 'Range';

  @override
  String get expGenerated => 'Generated';

  @override
  String get expNote => 'Note';

  @override
  String expMetaRange(String value) {
    return 'Range: $value';
  }

  @override
  String expMetaGenerated(String value) {
    return 'Generated: $value';
  }

  @override
  String get expNoData => 'No data.';

  @override
  String expPageOf(int page, int total) {
    return 'SatSet · Page $page/$total';
  }

  @override
  String get expAccountingCsvTitle => 'SatSet Accounting Report';

  @override
  String get expAccountingTitle => 'Accounting Report';

  @override
  String expAccountingHeader(String range) {
    return 'Accounting Report · $range';
  }

  @override
  String get expAccountingNote =>
      'Tax & service are the real figures from settled sessions, not the 18% estimate shown on screen. The range follows the same rule as the on-screen report (ADR-0032).';

  @override
  String get expSessionCount => 'Sessions';

  @override
  String expMetaSessionCount(int n) {
    return 'Sessions: $n';
  }

  @override
  String get expRevenueSummary => 'Revenue Summary';

  @override
  String get expColEntry => 'Entry';

  @override
  String get expColValue => 'Value';

  @override
  String get expGrossSubtotal => 'Gross (subtotal)';

  @override
  String get expVoidCorrection => 'Void / correction';

  @override
  String get expDiscount => 'Discount';

  @override
  String get expNet => 'Net';

  @override
  String get expService => 'Service';

  @override
  String get expTax => 'Tax';

  @override
  String get expCollectedBilled => 'Collected (billed)';

  @override
  String get expRefund => 'Refund';

  @override
  String get expMethodBreakdown => 'Payment Method Breakdown';

  @override
  String get expColMethod => 'Method';

  @override
  String get expColAmount => 'Amount';

  @override
  String get expColTransactions => 'Transactions';

  @override
  String get expColRefundCount => 'Refunds (n)';

  @override
  String get expWriteOffs => 'Voids & Refunds (write-off)';

  @override
  String get expColReason => 'Reason';

  @override
  String get expColItem => 'Item';

  @override
  String get expColLost => 'Lost';

  @override
  String get expDiscountByPreset => 'Discounts by Preset';

  @override
  String get expColScope => 'Scope';

  @override
  String get expColUsed => 'Used';

  @override
  String get expScopeLine => 'Per line';

  @override
  String get expScopeOrder => 'Per receipt';

  @override
  String get expDailyBreakdown => 'Daily Breakdown';

  @override
  String get expColDate => 'Date';

  @override
  String get expColGross => 'Gross';

  @override
  String get expColVoid => 'Void';

  @override
  String get expColCollected => 'Collected';

  @override
  String get expReportCsvTitle => 'SatSet Report';

  @override
  String expReportHeader(String range) {
    return 'SatSet Report · $range';
  }

  @override
  String get expSummary => 'Summary';

  @override
  String get expColMetric => 'Metric';

  @override
  String get expColCaption => 'Note';

  @override
  String get expStaffPerformance => 'Staff Performance';

  @override
  String get expColName => 'Name';

  @override
  String get expColCover => 'Cover';

  @override
  String get expColAvgBill => 'Avg bill';

  @override
  String get expColVoidPct => 'Void %';

  @override
  String get expColSessions => 'Sessions';

  @override
  String get expTopMenu => 'Top Menu Items';

  @override
  String get expSlowMenu => 'Slow Menu Items';

  @override
  String get expColQty => 'Qty';

  @override
  String get expColRevenue => 'Revenue';

  @override
  String get expColMarginPct => 'Margin %';

  @override
  String get expColMargin => 'Margin';

  @override
  String get expCategoryMix => 'Category Mix';

  @override
  String get expColCategory => 'Category';

  @override
  String get expColShareThisWeek => 'Share this week';

  @override
  String get expColShareLastWeek => 'Share last week';

  @override
  String get expColThisWeek => 'This week';

  @override
  String get expColLastWeek => 'Last week';

  @override
  String get expHourlySales => 'Sales by Hour';

  @override
  String get expColHour => 'Hour';

  @override
  String get expDineInVsTakeaway => 'Dine-in vs Takeaway';

  @override
  String get expDineIn => 'Dine-in';

  @override
  String get expTakeaway => 'Takeaway';

  @override
  String get expStaffCsvTitle => 'SatSet Staff Report';

  @override
  String get expStaffTitle => 'Staff Report';

  @override
  String expStaffHeader(String range) {
    return 'Staff Report · $range';
  }

  @override
  String get expColUpsellPct => 'Upsell %';

  @override
  String get expColVoidCount => 'Voids';

  @override
  String get expColLostVoid => 'Lost (void)';

  @override
  String get expColTopReason => 'Top reason';

  @override
  String get expTotalRow => 'TOTAL';

  @override
  String get expStaffSortNote => 'Sorted by Net, highest first.';

  @override
  String get expOrdersCsvTitle => 'SatSet Order History';

  @override
  String get expOrdersTitle => 'Order History';

  @override
  String expOrdersHeader(String range) {
    return 'Order History · $range';
  }

  @override
  String get expVisitCount => 'Total visits';

  @override
  String get expLineCount => 'Total lines';

  @override
  String get expVisitSection => 'VISIT';

  @override
  String get expColPax => 'Pax';

  @override
  String get expColWaiter => 'Waiter';

  @override
  String get expColClosed => 'Closed';

  @override
  String get expColTime => 'Time';

  @override
  String get expColVariant => 'Variant';

  @override
  String get expColModifier => 'Modifier';

  @override
  String get expColCourse => 'Course';

  @override
  String get expColPrice => 'Price';

  @override
  String get expColTotal => 'Total';

  @override
  String get expColSubtotal => 'Subtotal';

  @override
  String get expColStatus => 'Status';

  @override
  String get expColVoidReason => 'Void reason';

  @override
  String get expBillSection => 'BILL';

  @override
  String get expColCashier => 'Cashier';

  @override
  String get expColProofPhoto => 'Proof photo';

  @override
  String get expYes => 'Yes';

  @override
  String get expPresent => 'Present';

  @override
  String expTakeawayVisit(String label) {
    return '$label · Takeaway';
  }

  @override
  String expTableVisit(String label) {
    return 'Table $label';
  }

  @override
  String get expStatusVoided => 'Voided';

  @override
  String get expStatusServed => 'Served';

  @override
  String get expStatusReady => 'Ready';

  @override
  String get expStatusCooked => 'Cooked';

  @override
  String get expStatusSent => 'Sent';

  @override
  String get expStatusHeld => 'Held';

  @override
  String expVoidedWithReason(String reason) {
    return 'Void · $reason';
  }

  @override
  String get expNoVisits => 'No visits in this range.';

  @override
  String get expNoPayments => 'No payments recorded yet.';

  @override
  String get expBillHeading => 'Bill';

  @override
  String expMetaVisitLines(int visits, int lines, String net) {
    return 'Visits: $visits  ·  Lines: $lines  ·  Net: $net';
  }

  @override
  String expVisitMeta(int pax, String waiter, String closed) {
    return 'Pax $pax  ·  $waiter  ·  $closed';
  }

  @override
  String expReceiptTotals(
    String subtotal,
    String discount,
    String service,
    String tax,
    String total,
  ) {
    return 'Subtotal $subtotal$discount  ·  Service $service  ·  Tax $tax  ·  Total $total';
  }

  @override
  String expReceiptDiscountPart(String amount) {
    return '  ·  Discount $amount';
  }

  @override
  String expPaymentActor(String method, String cashier, String refund) {
    return '$method  ·  $cashier$refund';
  }

  @override
  String get expPaymentRefundPart => '  ·  Refund';

  @override
  String expProofCaption(String method, String amount) {
    return 'Proof · $method  ·  $amount';
  }

  @override
  String get expProofMissing => 'Proof failed to load';

  @override
  String get expAuditSubject => 'Audit log';

  @override
  String get expAuditCsvHeader =>
      'Time,Type,User,Role,Event,Table,Amount,Reason,Approved';

  @override
  String strukTableLine(String label, int pax, String time) {
    return 'Table $label  ·  $pax pax  ·  $time';
  }

  @override
  String strukGuest(String name) {
    return 'Guest: $name';
  }

  @override
  String strukMember(String name) {
    return 'Member: $name';
  }

  @override
  String strukMemberPoints(int points) {
    return 'Points balance: $points';
  }

  @override
  String strukMemberPunch(String progress) {
    return 'Stamp card: $progress';
  }

  @override
  String strukNote(String note) {
    return 'Note: $note';
  }

  @override
  String get strukVerify => 'Check your order';

  @override
  String get strukThanks => 'Thank you';

  @override
  String get strukTestTitle => 'PRINTER TEST';

  @override
  String get strukTestOk => 'Connected OK';

  @override
  String get strukBillTitle => 'BILL';

  @override
  String get strukReceiptTitle => 'PAYMENT RECEIPT';

  @override
  String get strukEvenHeading => 'Table split:';

  @override
  String get strukBillTotal => 'Bill total';

  @override
  String get strukPart => 'Part';

  @override
  String get strukSubtotal => 'Subtotal';

  @override
  String get strukDiscount => 'Discount';

  @override
  String get strukService => 'Service';

  @override
  String get strukTax => 'Tax';

  @override
  String get strukTotal => 'TOTAL';

  @override
  String strukPaid(String method) {
    return 'Paid $method';
  }

  @override
  String strukRefunded(String method) {
    return 'Refund $method';
  }

  @override
  String get strukCashReceived => 'Cash received';

  @override
  String get strukChange => 'Change';

  @override
  String get strukOutstanding => 'DUE';

  @override
  String get strukSettled => 'SETTLED';

  @override
  String get exportKindReport => 'General';

  @override
  String get exportKindOrders => 'Orders';

  @override
  String get exportKindStaff => 'Staff';

  @override
  String get exportKindAccounting => 'Accounting';

  @override
  String get exportTitleReport => 'Export report';

  @override
  String get exportTitleOrders => 'Export orders';

  @override
  String get exportTitleStaff => 'Export staff';

  @override
  String get exportTitleAccounting => 'Export accounting';

  @override
  String get exportFailed => 'Export failed. Try again.';

  @override
  String get exportKindField => 'Kind';

  @override
  String get exportFormatField => 'Format';

  @override
  String get exportNoSnapshot =>
      'The report is not ready — open it first so it can be exported.';

  @override
  String get exportPreparing => 'Preparing…';

  @override
  String exportAction(String format) {
    return 'Export $format';
  }

  @override
  String printJobOrderSlip(String label) {
    return 'Print order slip · Table $label';
  }

  @override
  String printJobReceiptDoc(String who) {
    return 'Print receipt · $who';
  }

  @override
  String printJobBillDoc(String who) {
    return 'Print bill · $who';
  }

  @override
  String get printWhoReceipt => 'receipt';

  @override
  String get courseDrinksNow => 'Drinks first';

  @override
  String get courseStarters => 'Starters';

  @override
  String get courseMains => 'Mains';

  @override
  String get courseSides => 'With mains';

  @override
  String get courseDesserts => 'Desserts';

  @override
  String get courseFireNow => 'Fire now';

  @override
  String auditFire(String course, String table) {
    return 'Fired $course for Table $table';
  }

  @override
  String auditModify(String name) {
    return 'Edited $name';
  }

  @override
  String auditModifyQty(String oldQty, String newQty, String name) {
    return 'Edited ×$oldQty → ×$newQty $name';
  }

  @override
  String auditModifyAtTable(String name, String table) {
    return '$name edited at Table $table';
  }

  @override
  String auditVoidItem(String qty, String name, String amount) {
    return 'Voided ×$qty $name · $amount';
  }

  @override
  String auditVoidItemAtTable(String name, String table) {
    return '$name voided at Table $table';
  }

  @override
  String auditComp(String qty, String name, String amount) {
    return 'Comped ×$qty $name · $amount';
  }

  @override
  String auditTableMoved(String src, String tgt) {
    return 'Moved table $src → $tgt';
  }

  @override
  String auditPaymentRecorded(String amount, String method, String label) {
    return 'Payment $amount ($method) $label';
  }

  @override
  String auditPaymentAtTable(String method, String table) {
    return '$method payment at Table $table';
  }

  @override
  String auditRefund(String amount, String method, String label) {
    return 'Refund $amount ($method) $label';
  }

  @override
  String auditDiscountApplied(String name) {
    return 'Discount $name';
  }

  @override
  String auditDiscountAppliedLine(String name) {
    return 'Discount $name (line)';
  }

  @override
  String auditDiscountRemoved(String name) {
    return 'Removed discount $name';
  }

  @override
  String auditDiscountBillApplied(String name) {
    return 'Bill discount $name';
  }

  @override
  String auditDiscountBillRemoved(String name) {
    return 'Removed bill discount $name';
  }

  @override
  String auditDiscountAtTable(String percent, String table) {
    return '$percent% discount at Table $table';
  }

  @override
  String auditBillReopenedReceipt(String label) {
    return 'Reopened $label';
  }

  @override
  String auditBillReopened(String table) {
    return 'Reopened bill $table';
  }

  @override
  String auditBillClosed(String table) {
    return 'Closed bill $table';
  }

  @override
  String auditBillWrittenOff(String amount, String table) {
    return 'Bill written off $amount $table';
  }

  @override
  String auditCashToppedUp(String amount) {
    return 'Topped up petty cash $amount';
  }

  @override
  String auditCashSpent(String amount, String category) {
    return 'Petty cash expense $amount — $category';
  }

  @override
  String auditCashCounted(String counted, String variance) {
    return 'Counted petty cash $counted (variance $variance)';
  }

  @override
  String auditCashReversed(String amount) {
    return 'Reversed cash movement $amount';
  }

  @override
  String auditStockCountClosed(num lines, String variance) {
    final intl.NumberFormat linesNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String linesString = linesNumberFormat.format(lines);

    String _temp0 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: '$linesString ingredients',
      one: '1 ingredient',
    );
    return 'Stocktake closed — $_temp0, variance $variance';
  }

  @override
  String auditMemberCreated(String name) {
    return 'Enrolled member $name';
  }

  @override
  String auditMemberDeleted(String name) {
    return 'Deleted member $name';
  }

  @override
  String auditMemberMerged(String from, String to) {
    return 'Merged member $from into $to';
  }

  @override
  String auditMemberPointsAdjusted(String name, String points) {
    return 'Point correction for $name: $points';
  }

  @override
  String auditMemberPointsRedeemed(String name, String points, String amount) {
    return 'Redemption for $name: $amount off ($points pt)';
  }

  @override
  String auditMenuKilled(String name) {
    return 'Marked $name sold out';
  }

  @override
  String auditMenuRestored(String name) {
    return '$name back on sale';
  }

  @override
  String auditStaffCreated(String name) {
    return 'Created $name';
  }

  @override
  String auditStaffDisabled(String name) {
    return 'Disabled $name';
  }

  @override
  String auditStaffEnabled(String name) {
    return 'Enabled $name';
  }

  @override
  String auditStaffPinSet(String name) {
    return 'PIN changed for $name';
  }

  @override
  String auditStaffPinReset(String name) {
    return 'PIN reset for $name';
  }

  @override
  String auditStaffRoleChanged(String name, String from, String to) {
    return '$name: $from → $to';
  }

  @override
  String auditRoleCreated(String name) {
    return 'Created role $name';
  }

  @override
  String auditRoleDeleted(String name) {
    return 'Deleted role $name';
  }

  @override
  String auditRoleColorChanged(String name) {
    return 'Colour changed for $name';
  }

  @override
  String auditRoleRenamed(String from, String to) {
    return 'Role: $from → $to';
  }

  @override
  String auditRoleCapabilityChanged(String name, String changes) {
    return '$name: $changes';
  }

  @override
  String get receiptDefault => 'Receipt';

  @override
  String receiptGuest(String letter) {
    return 'Guest $letter';
  }

  @override
  String receiptPart(String index, String count) {
    return 'Part $index/$count';
  }

  @override
  String auditStaffDeleted(String name) {
    return 'Deleted $name';
  }

  @override
  String get auditSampleDataLoaded => 'Loaded sample restaurant data';

  @override
  String get cshCrumbCashier => 'Cashier';

  @override
  String get cshCrumbBill => 'Bill';

  @override
  String cshBillTableCrumb(String table) {
    return 'Bill · Table $table';
  }

  @override
  String cshReceiptTableCrumb(String table) {
    return 'Receipt · Table $table';
  }

  @override
  String get cshLoadFailed => 'Couldn\'t load the bill.';

  @override
  String get cshReceiptLoadFailed => 'Couldn\'t load the receipt.';

  @override
  String get cshCloseBill => 'Close bill';

  @override
  String cshCloseBillBody(String table) {
    return 'Lock table $table\'s bill as settled? This ends the bill.';
  }

  @override
  String get cshWriteOffTitle => 'Close bill — written off';

  @override
  String cshWriteOffBody(String amount) {
    return 'The remaining $amount is recorded as a loss (written off). Needs manager approval.';
  }

  @override
  String get cshWriteOffReason => 'Reason (required)';

  @override
  String get cshWriteOffReasonHint => 'e.g. guest left without paying';

  @override
  String get cshWriteOffConfirm => 'Record the loss';

  @override
  String get cshErrOverAssign => 'More units than are available.';

  @override
  String get cshErrReceiptPaid => 'Reopen the receipt before changing it.';

  @override
  String get cshErrNotSettled => 'The bill isn\'t settled.';

  @override
  String get cshErrBillLocked => 'The bill is closed — reopen it first.';

  @override
  String get cshErrForbidden => 'Needs manager approval (write-off).';

  @override
  String get cshErrReasonRequired => 'A write-off reason is required.';

  @override
  String get cshErrNoLines => 'The table has no orders.';

  @override
  String cshErrGeneric(String code) {
    return 'Operation failed ($code).';
  }

  @override
  String get cshReceipts => 'Receipts';

  @override
  String cshUnassignedCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items not assigned to a receipt',
      one: '$n item not assigned to a receipt',
    );
    return '$_temp0';
  }

  @override
  String get cshSubtotal => 'Subtotal';

  @override
  String get cshDiscount => 'Discount';

  @override
  String get cshService => 'Service';

  @override
  String get cshTax => 'Tax';

  @override
  String get cshTotal => 'Total';

  @override
  String get cshPaidAmount => 'Paid';

  @override
  String get cshOutstanding => 'Outstanding';

  @override
  String cshBatch(String batch, String time) {
    return 'ORDER $batch · $time';
  }

  @override
  String get cshOrderItems => 'Order items';

  @override
  String get cshNotAllAssigned => 'Not all assigned';

  @override
  String cshNote(String note) {
    return 'Note: $note';
  }

  @override
  String get cshUnitDec => 'Fewer units';

  @override
  String get cshUnitInc => 'More units';

  @override
  String cshPickedOf(int picked, int free) {
    return '$picked of $free';
  }

  @override
  String get cshAssign => 'Assign';

  @override
  String cshAssignTitle(String name) {
    return 'Assign \"$name\"';
  }

  @override
  String cshAssignSub(int qty, int unassigned) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: '$qty units',
      one: '1 unit',
    );
    return '$_temp0 total · $unassigned unassigned';
  }

  @override
  String get cshSettled => 'Settled';

  @override
  String get cshUnpaid => 'Unpaid';

  @override
  String get cshStatusSettled => 'settled';

  @override
  String get cshStatusUnpaid => 'unpaid';

  @override
  String get cshPay => 'Pay';

  @override
  String get cshRefund => 'Refund';

  @override
  String get cshReopen => 'Reopen';

  @override
  String get cshReopenTitle => 'Reopen receipt';

  @override
  String cshReopenBody(String receipt) {
    return 'Undo \"$receipt\"\'s settled status so it can be changed? Recorded payments stay.';
  }

  @override
  String get cshReopenConfirm => 'Yes, reopen';

  @override
  String get cshRemoveDiscount => 'Remove discount';

  @override
  String cshRemoveDiscountBody(String label, String amount) {
    return 'Remove \"$label\" ($amount) from this receipt?';
  }

  @override
  String get cshConfirmDelete => 'Yes, delete';

  @override
  String get cshPrintBill => 'Print bill';

  @override
  String get cshPrintReceipt => 'Print receipt';

  @override
  String get cshDeleteReceiptTitle => 'Delete receipt';

  @override
  String cshDeleteReceiptBody(String receipt) {
    return 'Delete \"$receipt\"? Items assigned to it go back to unassigned.';
  }

  @override
  String cshPhotoFailed(String error) {
    return 'Couldn\'t take the photo: $error';
  }

  @override
  String cshRefundTitle(String receipt) {
    return 'Refund $receipt';
  }

  @override
  String cshPayTitle(String receipt) {
    return 'Pay $receipt';
  }

  @override
  String get cshTendered => 'Cash received';

  @override
  String cshChangeDue(String amount) {
    return 'Change $amount';
  }

  @override
  String cshShortBy(String amount) {
    return 'Short $amount';
  }

  @override
  String get cshProofPhoto => 'Proof photo (required)';

  @override
  String get cshTakePhoto => 'Take photo';

  @override
  String get cshRetakePhoto => 'Retake';

  @override
  String get cshRecordRefund => 'Record refund';

  @override
  String get cshRecordPayment => 'Record payment';

  @override
  String cshEvenSplit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parts',
      one: '1 part',
    );
    return 'Even split · $_temp0';
  }

  @override
  String cshPerHead(String amount) {
    return '$amount / person';
  }

  @override
  String cshPaidCount(int paid, int total) {
    return '$paid of $total settled';
  }

  @override
  String cshPayPart(int index) {
    return 'Pay part $index';
  }

  @override
  String cshShareSemantic(String receipt, String status) {
    return '$receipt, $status';
  }

  @override
  String cshPartSemantic(int index, String status) {
    return 'Part $index, $status';
  }

  @override
  String cshItemCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '$n item',
    );
    return '$_temp0';
  }

  @override
  String get cshItemFallback => 'Item';

  @override
  String get cshRemoveLineDiscountTitle => 'Remove item discount';

  @override
  String cshRemoveLineDiscountBody(String label, String amount, String name) {
    return 'Remove \"$label\" ($amount) from $name?';
  }

  @override
  String get cshAddReceipt => 'Add receipt';

  @override
  String get cshBillWrittenOff => 'Bill written off';

  @override
  String get cshBillSettled => 'Bill settled';

  @override
  String cshWrittenOffBody(String amount) {
    return '$amount recorded as a loss.';
  }

  @override
  String cshSettledFull(String amount) {
    return '$amount received in full.';
  }

  @override
  String cshSettledParts(String amount, int parts) {
    String _temp0 = intl.Intl.pluralLogic(
      parts,
      locale: localeName,
      other: '$parts parts',
      one: '1 part',
    );
    return '$amount received in full across $_temp0.';
  }

  @override
  String get cshPrintSettledReceipt => 'Print settled receipt';

  @override
  String get cshPrintTableReceipt => 'Print table receipt';

  @override
  String get cshPrintTableBill => 'Print table bill';

  @override
  String get cshWholeBill => 'Whole bill';

  @override
  String get cshRemoveBillDiscountTitle => 'Remove bill discount';

  @override
  String cshRemoveBillDiscountBody(String label, String amount) {
    return 'Remove \"$label\" ($amount) from the whole bill?';
  }

  @override
  String get cshTableClosedUnpaid =>
      'Table closed by the waiter — bill unsettled';

  @override
  String get cshAmount => 'Amount';

  @override
  String get rptSecSales => 'Sales';

  @override
  String get rptSecStaff => 'Staff';

  @override
  String get rptSecMenu => 'Menu';

  @override
  String get rptSecBahan => 'Ingredients';

  @override
  String get rptSecOps => 'Operations';

  @override
  String get rptSecPayments => 'Payments';

  @override
  String get rptUpdating => 'Updating…';

  @override
  String get rptStockTitle => 'Ingredients & stock';

  @override
  String get rptStockSub => 'Usage, waste, stock value and stocktake variance';

  @override
  String get rptNonCash => 'Non-cash payments';

  @override
  String get rptNonCashSub => 'proof photo required';

  @override
  String get rptNonCashEmpty => 'No non-cash payments in this range.';

  @override
  String rptTotalOf(String amount) {
    return 'total $amount';
  }

  @override
  String get rptProofOnVenue => 'Proof photos are on the venue device.';

  @override
  String rptMethodCount(String method, int count, String amount) {
    return '$method · $count× · $amount';
  }

  @override
  String rptMethodTable(String method, String table) {
    return '$method · Table $table';
  }

  @override
  String get rptDineVsTakeaway => 'Dine-in vs takeaway';

  @override
  String get rptDineIn => 'Dine-in';

  @override
  String get rptTakeaway => 'Takeaway';

  @override
  String rptTxCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n transactions',
      one: '$n transaction',
    );
    return '$_temp0';
  }

  @override
  String get rptKpiNet => 'Net';

  @override
  String get rptKpiGross => 'Gross';

  @override
  String get rptKpiTaxService => 'Tax + service';

  @override
  String get rptKpiVoid => 'Void';

  @override
  String get rptNoData => 'No data yet';

  @override
  String get rptNoDataDot => 'No data yet.';

  @override
  String get rptNoDataLower => 'no data yet';

  @override
  String get rptGuestTrend => 'Guest trend vs last week';

  @override
  String rptGuestTrendSub(int count, String delta) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0 · $delta% WoW';
  }

  @override
  String get rptThisWeek => 'This week';

  @override
  String get rptLastWeek => 'Last week';

  @override
  String get rptRevenuePerHour => 'Revenue by hour';

  @override
  String rptPeakHour(String from, String to) {
    return 'Peak $from:00 — $to:00';
  }

  @override
  String get rptWaiterPerf => 'Waiter performance';

  @override
  String rptWaiterPerfSub(int n) {
    return '$n staff · sorted';
  }

  @override
  String get rptNoClosedSessions => 'No closed sessions in this range.';

  @override
  String get rptSort => 'Sort';

  @override
  String get rptSortCovers => 'Tables';

  @override
  String get rptSortVoidPct => 'Void %';

  @override
  String get rptSortAvg => 'Avg';

  @override
  String get rptSortNetDesc => 'Highest net';

  @override
  String get rptSortMostTables => 'Most tables';

  @override
  String get rptSortMostVoids => 'Most voids';

  @override
  String get rptSortAvgTicket => 'Avg ticket';

  @override
  String get rptColWaiter => 'WAITER';

  @override
  String get rptColTables => 'TABLES';

  @override
  String get rptColItems => 'ITEMS';

  @override
  String get rptColAvgTicket => 'AVG TICKET';

  @override
  String get rptColVoidPct => 'VOID%';

  @override
  String get rptColNet => 'NET';

  @override
  String get rptUpsell => 'Waiter upsell index';

  @override
  String rptUpsellSub(int avg) {
    return '% of sessions with a starter & main · avg $avg%';
  }

  @override
  String get rptTopSellers => 'Top sellers';

  @override
  String get rptSlowMovers => 'Slow movers';

  @override
  String rptMenuHighMargin(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$_temp0 · high margin';
  }

  @override
  String rptMenuSlowStock(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$_temp0 · slow stock';
  }

  @override
  String rptQtyMargin(int qty, int margin) {
    return '×$qty · margin $margin%';
  }

  @override
  String get rptAttachRate => 'Modifier attach rate';

  @override
  String get rptAttachRateSub => '% of orders with a modifier';

  @override
  String get rptBucketStar => 'POPULAR & PROFITABLE';

  @override
  String get rptBucketStarAction => 'keep & feature';

  @override
  String get rptBucketPlow => 'POPULAR BUT THIN';

  @override
  String get rptBucketPlowAction => 'reprice / shrink the portion';

  @override
  String get rptBucketPuzzle => 'PROFITABLE BUT QUIET';

  @override
  String get rptBucketPuzzleAction => 'promote it';

  @override
  String get rptBucketDog => 'QUIET & THIN';

  @override
  String get rptBucketDogAction => 'trim candidate';

  @override
  String get rptMenuClass => 'Menu classification';

  @override
  String get rptMenuClassSub => 'Popularity × margin';

  @override
  String rptBucketAction(String action) {
    return '· $action';
  }

  @override
  String get rptNoItems => 'no items';

  @override
  String rptPopMargin(int pop, int margin) {
    return 'pop $pop · margin $margin%';
  }

  @override
  String rptMoreItems(int n) {
    return '+$n more';
  }

  @override
  String get rptCategoryMix => 'Category mix (WoW)';

  @override
  String get rptCategoryMixSub => 'Revenue share vs last week';

  @override
  String get rptColThisWeek => 'THIS WEEK';

  @override
  String get rptColLastWeek => 'LAST WEEK';

  @override
  String get rptBasketPairs => 'Basket pairs';

  @override
  String get rptBasketPairsSub => 'Items most often ordered together';

  @override
  String rptPairCount(int n) {
    return '$n× in this range';
  }

  @override
  String get rptKpiTurnTime => 'Avg turn time';

  @override
  String get rptKpiPrep => 'Kitchen prep';

  @override
  String get rptKpiPickup => 'Runner wait';

  @override
  String get rptKpiReservations => 'Reservations';

  @override
  String get rptServiceSpeed => 'Service speed';

  @override
  String get rptServiceSpeedEmpty => 'Nothing ready or served yet';

  @override
  String rptServiceSpeedSub(int prep, int pickup, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return 'Median prep ${prep}m · runner ${pickup}m · $_temp0';
  }

  @override
  String get rptSlaCourses => 'courses ready under their own target';

  @override
  String rptPickupSla(int mins) {
    return 'Delivered < ${mins}m';
  }

  @override
  String rptMedianMins(int mins) {
    return 'median ${mins}m';
  }

  @override
  String rptGreetBreach(int mins) {
    return 'Greeted late > ${mins}m';
  }

  @override
  String rptGreetSub(int median, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n visits',
      one: '1 visit',
    );
    return 'median ${median}m · $_temp0';
  }

  @override
  String get rptSlowestMenu => 'Slowest menu items (average prep)';

  @override
  String get rptHeatmap => 'Peak-hour heatmap';

  @override
  String get rptHeatmapSub => '7 days · 11:00—22:00';

  @override
  String get rptHeatQuiet => 'QUIET';

  @override
  String get rptHeatBusy => 'BUSY';

  @override
  String get rptReservationConv => 'Reservation conversion';

  @override
  String get rptReservationNoModule => 'No reservation module yet';

  @override
  String get rptReservationNoModuleBody =>
      'Turn on the reservation module (P3) to see conversion.';

  @override
  String rptReservationSub(int booked, int seated, int noShow) {
    return '$booked booked · $seated seated · $noShow no-show';
  }

  @override
  String get rptSeated => 'Seated';

  @override
  String get rptNoShow => 'No-show';

  @override
  String get rptCancelled => 'Cancelled';

  @override
  String get rptVoidReasons => 'Void & comp reasons';

  @override
  String get rptNoVoids => 'No voids yet';

  @override
  String rptVoidSub(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    return '$_temp0 · $amount lost';
  }

  @override
  String get rptVoidPerWaiter => 'Voids per waiter';

  @override
  String rptTopReason(String reason) {
    return 'reason: $reason';
  }

  @override
  String get rptNoSection => 'No section is on';

  @override
  String get rptNoSectionBody => 'Turn on at least one tab above';

  @override
  String get stkDimMass => 'Weight';

  @override
  String get stkDimVolume => 'Volume';

  @override
  String get stkDimCount => 'Count';

  @override
  String get stkTitle => 'Stock';

  @override
  String get stkSubOpname => 'Stocktake — physical audit';

  @override
  String get stkSub => 'Ingredients, receipts & movements';

  @override
  String get stkAddIngredient => 'Add ingredient';

  @override
  String get stkOpname => 'Stocktake';

  @override
  String stkSaveCount(int n) {
    return 'Save ($n)';
  }

  @override
  String stkLoadFailed(String error) {
    return 'Couldn\'t load stock: $error';
  }

  @override
  String get stkEmptyTitle => 'No ingredients yet';

  @override
  String get stkEmptyBody =>
      'Add your first ingredient, then build its recipe in the menu editor so stock drops automatically when an order is sent.';

  @override
  String get stkNoMatch => 'No ingredient matches the search / filter.';

  @override
  String get stkKpiLow => 'RUNNING LOW';

  @override
  String stkCountIngredients(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ingredients',
      one: '1 ingredient',
    );
    return '$_temp0';
  }

  @override
  String get stkNeedReorder => 'Reorder needed';

  @override
  String get stkStockOk => 'Stock is fine';

  @override
  String get stkKpiNegative => 'NEGATIVE STOCK';

  @override
  String get stkNeedOpname => 'Needs a stocktake now';

  @override
  String get stkKpiProduced => 'MADE IN HOUSE';

  @override
  String stkOfRegistered(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n registered ingredients',
      one: '1 registered ingredient',
    );
    return 'of $_temp0';
  }

  @override
  String get stkCounted => 'Counted';

  @override
  String get stkOpnameStartTitle => 'Start stocktake';

  @override
  String get stkOpnameStartSub =>
      'The session is saved as you go, so your counts survive the screen sleeping.';

  @override
  String get stkOpnameStart => 'Start';

  @override
  String get stkOpnameScope => 'Scope';

  @override
  String get stkOpnameScopeFull => 'Full';

  @override
  String get stkOpnameScopePartial => 'Partial';

  @override
  String get stkOpnameBlind => 'Blind count';

  @override
  String get stkOpnameBlindHint =>
      'Hide the recorded stock while counting. Variance appears once the stocktake closes.';

  @override
  String get stkOpnameDiscardTitle => 'Discard this stocktake?';

  @override
  String stkOpnameDiscardBody(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString ingredients',
      one: '1 ingredient',
    );
    return 'The $_temp0 already counted go with it. An unclosed stocktake never moved any stock.';
  }

  @override
  String get stkOpnameDiscard => 'Discard';

  @override
  String get stkOpnameIncompleteTitle => 'Not every ingredient was counted';

  @override
  String stkOpnameIncompleteBody(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString ingredients are',
      one: '1 ingredient is',
    );
    return 'This is a full stocktake, but $_temp0 still uncounted. Close it as full anyway?';
  }

  @override
  String get stkOpnameCloseAnyway => 'Close anyway';

  @override
  String get opnTitle => 'Stocktake';

  @override
  String get opnSub =>
      'The stocktake archive — who counted, when, and every line of it';

  @override
  String opnRangeDays(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get opnEmptyTitle => 'No stocktakes yet';

  @override
  String get opnEmptyBody =>
      'A stocktake starts on the Stock screen. Once closed, its document lands here.';

  @override
  String get opnPickTitle => 'Pick a stocktake';

  @override
  String get opnPickBody => 'Its full document opens here.';

  @override
  String get opnOpenTitle => 'A stocktake is under way';

  @override
  String opnOpenBody(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString ingredients',
      one: '1 ingredient',
    );
    return '$_temp0 counted so far. No stock moves until it closes.';
  }

  @override
  String get opnTagBlind => 'Blind';

  @override
  String get opnTagSighted => 'Sighted';

  @override
  String opnLineCount(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString lines',
      one: '1 line',
    );
    return '$_temp0';
  }

  @override
  String opnDocSub(Object scope, Object blind) {
    return '$scope · $blind';
  }

  @override
  String get opnKpiLines => 'Lines';

  @override
  String get opnKpiExact => 'Exact';

  @override
  String get opnKpiVariance => 'Variance';

  @override
  String get opnColItem => 'Ingredient';

  @override
  String get opnColExpected => 'Expected';

  @override
  String get opnColCounted => 'Counted';

  @override
  String get opnColVariance => 'Variance';

  @override
  String get opnColValue => 'Value';

  @override
  String get opnExact => 'Exact';

  @override
  String get opnPhoneOnly =>
      'A stocktake document is read by comparing its lines. Open it on a tablet.';

  @override
  String get opnHubSubtitle => 'Past stocktakes and what they found';

  @override
  String get opnCsvTitle => 'Stocktake';

  @override
  String get opnCsvStarted => 'Started';

  @override
  String get opnCsvClosed => 'Closed';

  @override
  String get opnCsvMode => 'Method';

  @override
  String get opnCsvNote => 'Note';

  @override
  String opnPdfHeader(Object stamp) {
    return 'Stocktake $stamp';
  }

  @override
  String get opnPdfLines => 'Line by line';

  @override
  String opnMetaStarted(Object stamp) {
    return 'Started: $stamp';
  }

  @override
  String opnMetaClosed(Object stamp) {
    return 'Closed: $stamp';
  }

  @override
  String opnMetaTally(num lines, num exact) {
    final intl.NumberFormat linesNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String linesString = linesNumberFormat.format(lines);
    final intl.NumberFormat exactNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String exactString = exactNumberFormat.format(exact);

    String _temp0 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: '$linesString lines',
      one: '1 line',
    );
    return '$_temp0, $exactString exact';
  }

  @override
  String opnMetaVariance(Object value) {
    return 'Variance: $value';
  }

  @override
  String get opnExport => 'Export';

  @override
  String get opnExportSubject => 'SatSet stocktake';

  @override
  String get stkOpnameMode => 'STOCKTAKE MODE';

  @override
  String get stkOpnameHint =>
      'Type the physical count in the store right now. The variance posts itself as an adjustment movement.';

  @override
  String stkFilled(int n) {
    return '$n filled';
  }

  @override
  String get stkSearchHint => 'Search ingredient names...';

  @override
  String stkFilterAll(int n) {
    return 'All ($n)';
  }

  @override
  String stkFilterLow(int n) {
    return 'Low ($n)';
  }

  @override
  String stkFilterNegative(int n) {
    return 'Negative ($n)';
  }

  @override
  String stkFilterProduced(int n) {
    return 'Made ($n)';
  }

  @override
  String get stkBadgeProduced => 'MADE';

  @override
  String get stkBadgeLow => 'LOW';

  @override
  String get stkBadgeNegative => 'NEGATIVE';

  @override
  String get stkColOnHand => 'ON HAND';

  @override
  String stkColPricePer(String unit) {
    return 'PRICE / $unit';
  }

  @override
  String get stkColLastReceived => 'LAST RECEIVED';

  @override
  String get stkReceive => 'Receive';

  @override
  String get stkMenuReceive => 'Receive goods';

  @override
  String get stkMenuProduce => 'Produce a batch';

  @override
  String get stkMenuLedger => 'Movement history';

  @override
  String get stkMenuEdit => 'Edit ingredient';

  @override
  String get stkMenuArchive => 'Archive';

  @override
  String stkMinThreshold(String qty) {
    return 'Min: $qty';
  }

  @override
  String get stkVarianceExact => 'Exact';

  @override
  String get stkOpnameDoneNoVariance => 'Stocktake done — no variance';

  @override
  String stkOpnameDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ingredients',
      one: '1 ingredient',
    );
    return 'Stocktake done — $_temp0 adjusted';
  }

  @override
  String stkSaveFailed(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String stkFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String stkReceiveTitle(String name) {
    return 'Receive $name';
  }

  @override
  String get stkReceiveSub =>
      'Record the stock added and the latest purchase price.';

  @override
  String stkPricePer(String unit) {
    return 'Price per $unit (optional)';
  }

  @override
  String get stkPriceHelper => 'Leave empty to keep the average price';

  @override
  String get stkSupplier => 'Supplier (optional)';

  @override
  String get stkReceiveOk => 'Stock added';

  @override
  String stkProduceTitle(String name) {
    return 'Produce $name';
  }

  @override
  String stkProduceSub(String qty) {
    return '1 batch = $qty. Its component ingredients drop automatically.';
  }

  @override
  String get stkBatchCount => 'Number of batches';

  @override
  String get stkProduceOk => 'Production recorded';

  @override
  String stkArchived(String name) {
    return '$name archived';
  }

  @override
  String get stkNewIngredient => 'New ingredient';

  @override
  String stkEditIngredient(String name) {
    return 'Edit $name';
  }

  @override
  String get stkEditorSub => 'Set the name, unit and reorder threshold.';

  @override
  String get stkName => 'Ingredient name';

  @override
  String get stkUnit => 'Unit';

  @override
  String stkUnitOption(String unit, String dimension) {
    return '$unit · $dimension';
  }

  @override
  String stkOpening(String unit) {
    return 'Opening stock ($unit)';
  }

  @override
  String get stkOpeningHelper => 'Recorded as the opening movement';

  @override
  String stkLowAt(String unit) {
    return 'Low-stock threshold ($unit, optional)';
  }

  @override
  String get stkLowAtHelper => 'Warn once stock drops below this';

  @override
  String stkBatchYield(String unit) {
    return 'Yield of 1 batch ($unit, optional)';
  }

  @override
  String get stkBatchYieldHelper =>
      'Fill this in if the ingredient is made in house, then build its recipe';

  @override
  String get stkSaveOk => 'Ingredient saved';

  @override
  String get stkLedgerTitle => 'Movement history';

  @override
  String stkLedgerLoadFailed(String error) {
    return 'Couldn\'t load: $error';
  }

  @override
  String get stkLedgerEmpty => 'No movements recorded for this ingredient yet.';

  @override
  String get stkAddFirst => 'Add the first ingredient';

  @override
  String get stkUnused => 'not used yet';

  @override
  String durYears(int n) {
    return '${n}y';
  }

  @override
  String durMonths(int n) {
    return '${n}mo';
  }

  @override
  String durDays(int n) {
    return '${n}d';
  }

  @override
  String durHours(int n) {
    return '${n}h';
  }

  @override
  String durMins(int n) {
    return '${n}m';
  }

  @override
  String durSecs(int n) {
    return '${n}s';
  }

  @override
  String durDh(int d, int h) {
    return '${d}d ${h}h';
  }

  @override
  String durHm(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String durMs(int m, int s) {
    return '${m}m ${s}s';
  }

  @override
  String durHms(int h, int m, int s) {
    return '${h}h ${m}m ${s}s';
  }

  @override
  String relAgo(String value) {
    return '$value ago';
  }

  @override
  String relIn(String value) {
    return 'in $value';
  }

  @override
  String get elapsedYesterday => 'yesterday';

  @override
  String elapsedDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0 ago';
  }

  @override
  String get sysTitle => 'System';

  @override
  String get sysVenueFallback => 'Venue';

  @override
  String sysHeaderSub(String venue) {
    return '$venue · v2.0';
  }

  @override
  String get sysDegraded => 'Degraded mode';

  @override
  String get sysLanOnline => 'LAN online';

  @override
  String get sysKdsOnline => 'KDS online';

  @override
  String get sysNoStations => 'No stations yet';

  @override
  String get sysStationsActive => 'Stations active';

  @override
  String get sysTabletPair => 'Paired tablets';

  @override
  String get sysNoDevices => 'No devices yet';

  @override
  String get sysDevicesActive => 'Devices active';

  @override
  String get sysQueue => 'Queue';

  @override
  String get sysNoPendingJobs => 'No pending jobs';

  @override
  String get sysTicketsWaiting => 'Tickets waiting';

  @override
  String get sysServerLan => 'LAN server';

  @override
  String get sysTagBooting => 'BOOTING';

  @override
  String get sysTagPrimary => 'PRIMARY';

  @override
  String get sysAddress => 'Address';

  @override
  String get sysUptime => 'Uptime';

  @override
  String get sysCertificate => 'Certificate';

  @override
  String get sysPingLan => 'LAN ping';

  @override
  String sysPingValue(int p50, int last) {
    return 'p50 $p50 ms · last $last ms';
  }

  @override
  String get sysP95 => 'p95 latency';

  @override
  String sysP95Value(int ms, int count) {
    return '$ms ms · $count req';
  }

  @override
  String get sysFingerprint => 'Fingerprint';

  @override
  String get sysCopy => 'Copy';

  @override
  String get sysFingerprintCopied => 'Fingerprint copied';

  @override
  String get sysNoneYet => 'None yet';

  @override
  String get sysAddPrinterOrStation => 'Add a printer or a station';

  @override
  String get sysPrintersKds => 'Printers & KDS';

  @override
  String sysTagStations(int n) {
    return '$n STATIONS';
  }

  @override
  String get sysDiscover => 'Discover';

  @override
  String get sysAddPrinterBtn => '+ Printer';

  @override
  String get sysPrinterTest => 'Test';

  @override
  String get sysTestPrinted => 'Test printed';

  @override
  String get sysOnline => 'Online';

  @override
  String get sysOffline => 'Offline';

  @override
  String sysStationLoad(int staff, int tickets) {
    String _temp0 = intl.Intl.pluralLogic(
      tickets,
      locale: localeName,
      other: '$tickets tickets',
      one: '1 ticket',
    );
    return '$staff staff · $_temp0';
  }

  @override
  String get sysStationQuiet => 'Quiet';

  @override
  String get sysStationBusy => 'Busy';

  @override
  String get sysDevicesTitle => 'Active devices';

  @override
  String sysTagPair(int n) {
    return '$n PAIRED';
  }

  @override
  String get sysNoDevicesPaired => 'No devices paired yet';

  @override
  String get sysNeverSignedIn => 'never signed in';

  @override
  String sysLastSession(String when) {
    return 'session $when';
  }

  @override
  String get sysRevoked => 'Revoked';

  @override
  String get sysDeviceActive => 'Active';

  @override
  String get sysDeviceIdle => 'Idle';

  @override
  String get sysRevoke => 'Revoke';

  @override
  String get sysOperational => 'Operations';

  @override
  String get sysTagRuntime => 'RUNTIME';

  @override
  String get sysActions => 'Actions';

  @override
  String get sysRestartServer => 'Restart the server';

  @override
  String get sysWaitingProbe => 'waiting for a probe…';

  @override
  String get sysOfflineLower => 'offline';

  @override
  String sysPingWs(int ms, String state) {
    return '$ms ms · $state';
  }

  @override
  String get sysPhoneSub => 'Server, network, printers, devices';

  @override
  String sysPrinterStationCount(int printers, int stations) {
    String _temp0 = intl.Intl.pluralLogic(
      printers,
      locale: localeName,
      other: '$printers printers',
      one: '1 printer',
    );
    String _temp1 = intl.Intl.pluralLogic(
      stations,
      locale: localeName,
      other: '$stations stations',
      one: '1 station',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get sysDevices => 'Devices';

  @override
  String sysPairActiveCount(int paired, int active) {
    return '$paired paired · $active active';
  }

  @override
  String get sysNoManageStaff => 'You don\'t have manageStaff';

  @override
  String get sysRestarting => 'Server restarting… reconnecting';

  @override
  String sysRestartFailed(String code) {
    return 'Restart failed: $code';
  }

  @override
  String get sysRevokeTitle => 'Revoke device?';

  @override
  String sysRevokeBody(String label) {
    return '$label will lose its session.';
  }

  @override
  String get sysSearchingPrinters => 'Looking for printers…';

  @override
  String get sysNoPrintersFound => 'No printers found';

  @override
  String get sysPrintersFound => 'Printers found';

  @override
  String sysHostPort(String host, int port) {
    return '$host:$port';
  }

  @override
  String sysPrinterAdded(String name) {
    return 'Printer \"$name\" added';
  }

  @override
  String get sysAddPrinterTitle => 'Add a printer';

  @override
  String get sysPrinterLabel => 'Label';

  @override
  String get sysPrinterHost => 'Host (IP)';

  @override
  String get sysPrinterPort => 'Port';

  @override
  String get sysPrinterKind => 'Kind';

  @override
  String sysHeroWarnDesc(String ws, String reach, int fails) {
    return 'WS $ws · reach=$reach · $fails failed';
  }

  @override
  String sysHeroOkDesc(int sessions, int devices, String ws) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions active sessions',
      one: '1 active session',
    );
    String _temp1 = intl.Intl.pluralLogic(
      devices,
      locale: localeName,
      other: '$devices devices',
      one: '1 device',
    );
    return '$_temp0 · $_temp1 · WS $ws';
  }

  @override
  String get sysReachOk => 'ok';

  @override
  String get sysReachOff => 'off';

  @override
  String get sysServerLanOk => 'LAN server OK';

  @override
  String get sysRestartTitle => 'Restart the server?';

  @override
  String get sysRestartBody =>
      'WS clients disconnect for ~1-3 seconds. Enter your PIN to confirm.';

  @override
  String get sysPin => 'PIN';

  @override
  String get sysConfirm => 'Confirm';

  @override
  String get sysWrongPin => 'Wrong PIN';

  @override
  String get retry => 'Try again';

  @override
  String get tblOtherUser => 'someone else';

  @override
  String tblTakenBy(String holder) {
    return 'Table taken by $holder';
  }

  @override
  String tblAlreadySeated(String holder) {
    return 'Table already seated by $holder';
  }

  @override
  String tblSeatFailed(String error) {
    return 'Couldn\'t start service: $error';
  }

  @override
  String get tblReleaseTable => 'Release table';

  @override
  String get tblFinishService => 'Finish service';

  @override
  String get tblLoadingMenu => 'Loading the menu…';

  @override
  String get tblMenuLoadFailed => 'Couldn\'t load the table menu';

  @override
  String get tblReleaseTableQ => 'Release the table?';

  @override
  String get tblFinishServiceQ => 'Finish service?';

  @override
  String tblReleaseBody(String table) {
    return 'Nothing was ordered. Clear table $table?';
  }

  @override
  String tblFinishBody(String table) {
    return 'Every ticket is done. Clear table $table for the next guests? The bill stays with the cashier until it is paid.';
  }

  @override
  String tblCloseFailed(String error) {
    return 'Couldn\'t close the table: $error';
  }

  @override
  String get tblEmptyPhone =>
      'Nothing here yet — tap \"Add to order\" to start.';

  @override
  String get tblContextTitle => 'Table context';

  @override
  String tblSeatedFor(String elapsed, int pax) {
    return 'SEATED $elapsed · $pax GUESTS';
  }

  @override
  String tblItemCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String tblItemCountHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$_temp0 · held';
  }

  @override
  String tblFireCourse(String course) {
    return 'Fire $course';
  }

  @override
  String tblKosong(String table) {
    return 'Table $table is empty';
  }

  @override
  String get tblKosongHint => 'Tap to start serving guests';

  @override
  String get tblStartService => 'Start serving';

  @override
  String tblLockedBy(String holder, String since) {
    return 'Locked by $holder$since · view only';
  }

  @override
  String tblLockedSince(String time) {
    return ' · since $time';
  }

  @override
  String tblReadyToCollect(int n) {
    return '$n ready to collect';
  }

  @override
  String get tblViewOnly => 'View only';

  @override
  String get tblCreateOrder => 'Create order';

  @override
  String get tblAddOrder => 'Add order';

  @override
  String get tblStatTotal => 'Total items';

  @override
  String get tblStatInProgress => 'In progress';

  @override
  String get tblStatServed => 'Served';

  @override
  String get tblGuestNotes => 'GUEST NOTES';

  @override
  String get tblNoGuestNotes => 'No special notes yet.';

  @override
  String get tblSpecialInstruction => 'Special instruction';

  @override
  String get tblAllergensInOrder => 'ALLERGENS IN THIS ORDER';

  @override
  String get tblNoAllergens => 'None.';

  @override
  String get tblQuickActions => 'QUICK ACTIONS';

  @override
  String get tblPrintTableReceipt => 'Print table receipt';

  @override
  String get tblMoveTable => 'Move table';

  @override
  String get mieBlankNames => 'Fill in the names that are still blank';

  @override
  String mieSaveFailed(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String get mieItemAdded => 'Item added';

  @override
  String get mieChangesSaved => 'Changes saved';

  @override
  String get mieDeleteTitle => 'Delete this item?';

  @override
  String mieDeleteBody(String name) {
    return 'Item \"$name\" will be removed from the menu.';
  }

  @override
  String get mieNewItem => 'New item';

  @override
  String get mieReadOnlySub => 'Only an admin can edit this';

  @override
  String get mieIdentity => 'Identity';

  @override
  String get mieItemName => 'Item name';

  @override
  String get mieShortDesc => 'Short description';

  @override
  String get mieCategory => 'Category';

  @override
  String get miePhotoChange => 'CHANGE';

  @override
  String get miePhotoAdd => 'PHOTO';

  @override
  String get miePickGallery => 'Pick from the gallery';

  @override
  String get mieTakePhoto => 'Take a photo';

  @override
  String get mieDeletePhoto => 'Delete the photo';

  @override
  String miePhotoLoadFailed(String error) {
    return 'Couldn\'t load the photo: $error';
  }

  @override
  String get miePhotoSaveFailed => 'Couldn\'t save the photo';

  @override
  String get miePricing => 'Price';

  @override
  String get mieBasePrice => 'Base price';

  @override
  String mieFollowVenue(int mins) {
    return 'Follow the venue (${mins}m)';
  }

  @override
  String get miePrepTime => 'Prep time (minutes)';

  @override
  String get mieCost => 'COGS';

  @override
  String get mieVariants => 'Size variants';

  @override
  String get mieAddVariant => '+ Variant';

  @override
  String get mieNoVariants =>
      'No variants yet. The base price is all there is.';

  @override
  String get mieVariantNameHint => 'Name (e.g. Large)';

  @override
  String get miePrice => 'Price';

  @override
  String get mieModifierGroups => 'Modifier groups';

  @override
  String get mieAddGroup => '+ Group';

  @override
  String get mieNoModifiers =>
      'No modifier groups yet (e.g. spice level, pick a protein).';

  @override
  String get mieGroupName => 'Group name';

  @override
  String get mieRequired => 'Required';

  @override
  String get mieMulti => 'Pick several';

  @override
  String get mieAddOption => '+ Option';

  @override
  String get mieOptionName => 'Option name';

  @override
  String get mieRecipe => 'Recipe';

  @override
  String mieIngredientsLoadFailed(String error) {
    return 'Couldn\'t load ingredients: $error';
  }

  @override
  String get mieNoIngredients =>
      'No ingredients yet. Add them under Stock before building a recipe.';

  @override
  String get mieScopeBase => 'Base';

  @override
  String mieScopeOption(String group, String option) {
    return '$group: $option';
  }

  @override
  String mieScopeFilled(String label) {
    return '$label ·';
  }

  @override
  String get mieRecipeVariantHint =>
      'A variant recipe replaces the base recipe entirely. Leave it empty to follow the base.';

  @override
  String get mieRecipeOptionHint =>
      'A modifier recipe is added on top of whichever recipe applies.';

  @override
  String get mieRecipeBaseHint =>
      'Used when the item has no variants, or a variant has no recipe of its own.';

  @override
  String get mieRecipeEmpty => 'No ingredients on this recipe yet.';

  @override
  String get mieAddIngredient => 'Add ingredient';

  @override
  String get mieIngredient => 'Ingredient';

  @override
  String mieIngredientOption(String name, String unit) {
    return '$name ($unit)';
  }

  @override
  String get mieQty => 'Quantity';

  @override
  String get mieTags => 'Tags';

  @override
  String get mieAllergens => 'Allergens';

  @override
  String get mieDiet => 'Diet';

  @override
  String get mieAvailability => 'Availability';

  @override
  String get mieAutoSoldOut => 'Unavailable (out of stock)';

  @override
  String get mieManualSoldOut => 'Unavailable (manual)';

  @override
  String get mieActiveForSale => 'On sale';

  @override
  String get mieActivate => 'Put on sale';

  @override
  String get mieMarkUnavailable => 'Mark unavailable';

  @override
  String get mieUnavailable => 'Unavailable';

  @override
  String get mieActive => 'On sale';

  @override
  String mieDerivedCost(String amount) {
    return '≈ $amount from the base recipe';
  }

  @override
  String get mieRequiredField => 'Required';

  @override
  String get mieMargin => 'MARGIN';

  @override
  String get mieMarginNoPrice => 'Set a base price first';

  @override
  String get mieMarginHealthy => 'Healthy margin';

  @override
  String get mieMarginThin => 'Thin margin';

  @override
  String get mieMarginCritical => 'Critical margin';

  @override
  String mieMarginValue(int amount, String hint) {
    return 'Rp $amount · $hint';
  }

  @override
  String get mnaTitle => 'Menu';

  @override
  String mnaHeaderSub(int total, int cats, int out) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total items',
      one: '1 item',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cats,
      locale: localeName,
      other: '$cats categories',
      one: '1 category',
    );
    return '$_temp0 · $_temp1 · $out unavailable';
  }

  @override
  String mnaPhoneSub(int total, int out) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total items',
      one: '1 item',
    );
    return '$_temp0 · $out unavailable';
  }

  @override
  String get mnaAddItem => '+ Add item';

  @override
  String get mnaPickStaff => 'Pick an item to see its detail';

  @override
  String get mnaPickAdmin => 'Pick an item, or add a new one';

  @override
  String get mnaPickStaffSub =>
      'Staff mode: you can only mark items sold out. Full editing is admin-only.';

  @override
  String get mnaPickAdminSub =>
      'Manage price, modifiers, stock and availability.';

  @override
  String get mnaSearchHint => 'Search items, descriptions…';

  @override
  String get mnaAll => 'All';

  @override
  String get mnaNoMatch => 'No item matches.';

  @override
  String get mnaIngredientsOut => 'Out of ingredients';

  @override
  String mnaVariantsOut(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n variants',
      one: '1 variant',
    );
    return '$_temp0 sold out';
  }

  @override
  String get mnaAutoOut => 'AUTO SOLD OUT';

  @override
  String get mnaOut => 'SOLD OUT';

  @override
  String get mnaOn => 'ON SALE';

  @override
  String get mnaTabItems => 'Items';

  @override
  String get mnaTabCategories => 'Categories';

  @override
  String get mnaTabTags => 'Tags';

  @override
  String get mnaNewCategory => 'New category';

  @override
  String get mnaRenameCategory => 'Rename the category';

  @override
  String mnaMoveItemsFirst(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Move $_temp0 out before deleting \"$name\"';
  }

  @override
  String get mnaCategoryInUse =>
      'Couldn\'t delete the category — items still use it';

  @override
  String get mnaCategoryNameHint => 'Category name';

  @override
  String mnaDeleteTagTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get mnaDeleteTagBody =>
      'This tag will be removed from every item using it.';

  @override
  String mnaTagDeleted(String name) {
    return '\"$name\" deleted';
  }

  @override
  String get mnaNewTag => 'New tag';

  @override
  String get mnaEditTag => 'Edit tag';

  @override
  String get mnaTagName => 'Name';

  @override
  String get mnaTagCode => 'Badge code';

  @override
  String get mnaRoleAdmin => 'ADMIN';

  @override
  String get mnaRoleStaff => 'STAFF · MARK SOLD OUT';

  @override
  String get mnuLoadFailed => 'Couldn\'t load the menu';

  @override
  String get mnuAddToTakeaway => 'Add to takeaway';

  @override
  String get mnuNewOrder => 'New order';

  @override
  String mnuAddToTable(String table) {
    return 'Add to table $table';
  }

  @override
  String get mnuTakeawayNoTable => 'TAKEAWAY · NO TABLE';

  @override
  String get mnuNoTablePickLater => 'NO TABLE · PICK ONE WHEN SENDING';

  @override
  String mnuZonePax(String zone, int pax) {
    return '$zone · $pax GUESTS';
  }

  @override
  String get mnuAddItem => 'Add item';

  @override
  String get mnuAddItemHint =>
      'TAP TO CONFIGURE · LONG-PRESS TO ADD THE DEFAULT';

  @override
  String mnuPending(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$_temp0 pending';
  }

  @override
  String mnuServicePct(String pct) {
    return 'Service · $pct';
  }

  @override
  String mnuTaxPct(String pct) {
    return 'Tax · $pct';
  }

  @override
  String get mnuHeadTakeaway => 'TAKEAWAY · NO TABLE';

  @override
  String get mnuHeadTableless => 'NEW ORDER · NO TABLE';

  @override
  String mnuHeadTable(String table) {
    return 'NEW ORDER · TABLE $table';
  }

  @override
  String get mnuCartEmpty => 'The cart is empty';

  @override
  String mnuCartReady(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$_temp0 ready to send';
  }

  @override
  String mnuKitchenCount(int n) {
    return 'Kitchen × $n';
  }

  @override
  String mnuBarCount(int n) {
    return 'Bar × $n';
  }

  @override
  String get mnuCartEmptyHint =>
      'Nothing in the cart yet. Pick from the menu on the left.';

  @override
  String get mnuEstimate => 'Estimate';

  @override
  String mnuReviewSendTo(String target) {
    return 'Review & send to $target';
  }

  @override
  String get mnuTargetKitchenBar => 'kitchen + bar';

  @override
  String get mnuTargetKitchen => 'the kitchen';

  @override
  String get mnuTargetBar => 'the bar';

  @override
  String get dscNewPreset => 'New preset';

  @override
  String get dscEditPreset => 'Edit preset';

  @override
  String get dscEmptyTitle => 'No discount presets yet';

  @override
  String get dscEmptyBody =>
      'Create a preset so the cashier can give a discount without typing the number themselves.';

  @override
  String get dscIntro =>
      'The cashier picks from this list — they can\'t type a discount of their own.';

  @override
  String get dscScopeOrder => 'Whole order';

  @override
  String get dscScopeLine => 'Per item';

  @override
  String get dscInactive => 'off';

  @override
  String get dscDeleteTitle => 'Delete preset';

  @override
  String dscDeleteBody(String name) {
    return 'Delete \"$name\"? Discounts already applied to older bills don\'t change — their value is stored there.';
  }

  @override
  String get dscNameLabel => 'Name (shown on the receipt)';

  @override
  String get dscNameHint => 'Member discount';

  @override
  String get dscKindPercent => 'Percent';

  @override
  String get dscKindFixed => 'Amount';

  @override
  String get dscValuePercent => 'Percent (%)';

  @override
  String get dscValueFixed => 'Amount (Rp)';

  @override
  String get dscActive => 'Active';

  @override
  String get dscActiveHint =>
      'Turning it off hides the preset from the cashier';

  @override
  String get dscErrName => 'A name is required';

  @override
  String get dscErrValue => 'The value must be more than 0';

  @override
  String get dscErrMax => '100% at most';

  @override
  String revSendFailed(String error) {
    return 'Couldn\'t send: $error';
  }

  @override
  String get revTitle => 'Review the order';

  @override
  String revHeadTakeaway(int n) {
    return 'TAKEAWAY · $n ITEMS';
  }

  @override
  String revHeadTableless(int n) {
    return 'NO TABLE · $n ITEMS · PICK ONE WHEN SENDING';
  }

  @override
  String revHeadTable(String table, int pax, int n) {
    return 'TABLE $table · $pax GUESTS · $n ITEMS';
  }

  @override
  String get revEstimatedTotal => 'Estimated total';

  @override
  String get revPaymentNote =>
      'PAYMENT IS HANDLED OUTSIDE SATSET · THE BILL PRINTS FROM THE POS ON SERVING';

  @override
  String get revSending => 'Sending…';

  @override
  String get revAddToOrder => 'Add to the order';

  @override
  String get revSendOrder => 'Send the order';

  @override
  String revSendTo(String target) {
    return 'Send to $target';
  }

  @override
  String get revTableTaken => 'The table was taken. Pick another one.';

  @override
  String revSeatFailed(String error) {
    return 'Couldn\'t seat the table: $error';
  }

  @override
  String get revCommitTitle => 'Send the order to';

  @override
  String get revCommitDineIn => 'A table (dine-in)';

  @override
  String get revCommitDineInSub => 'Assign it to an empty table';

  @override
  String get revCommitTakeaway => 'Takeaway';

  @override
  String get revCommitTakeawaySub => 'Takeaway, no table';

  @override
  String get revChannel => 'Channel';

  @override
  String get revGuestOrCourier => 'Guest / courier name';

  @override
  String get revGuestHint => 'e.g. Budi · or Rizal (courier)';

  @override
  String get revPrepaid => 'Already paid in the app';

  @override
  String get revContinue => 'Continue';

  @override
  String get revAutoFire => 'auto-fire';

  @override
  String get revHeldUntilFired => 'held until fired';

  @override
  String get pinErrEmailEmpty => 'Enter an email.';

  @override
  String get pinErrEmailInvalid => 'That email isn\'t valid.';

  @override
  String get pinErrPasswordEmpty => 'Enter a password.';

  @override
  String get pinErrPasswordShort => '6 characters minimum.';

  @override
  String get pinEnterPin => 'Enter your PIN';

  @override
  String pinConnectedTo(String server) {
    return 'Connected to $server';
  }

  @override
  String get pinWidgetBook => 'Widget book';

  @override
  String get pinEmail => 'Email';

  @override
  String get pinEmailHint => 'admin@warung.id';

  @override
  String get pinPassword => 'PASSWORD';

  @override
  String get pinForgotPassword => 'Forgot your password?';

  @override
  String get pinModeAdmin => 'Admin';

  @override
  String get pinModeStaff => 'Staff';

  @override
  String get pinSearchingServers =>
      'Looking for a server on this network… make sure the server tablet is on and joined to the same Wi-Fi.';

  @override
  String get pinHostTakenTitle => 'This venue already has a primary device';

  @override
  String get pinHostTakenBody =>
      'One venue runs on one device. Close the app on that device, then try again here.';

  @override
  String get pinHostTakenNote =>
      'If that device is the one in use, this account isn\'t the venue\'s primary admin — talk to the operator.';

  @override
  String get pinSignOut => 'Sign out';

  @override
  String get pinCheckingSession => 'Checking the session…';

  @override
  String get pinReachConnected => 'Connected';

  @override
  String pinReachConnectedMs(int ms) {
    return 'Connected · ${ms}ms';
  }

  @override
  String get pinReachUnreachable => 'Server unreachable';

  @override
  String get pinReachChecking => 'Checking the connection…';

  @override
  String get pinServerConnected => 'SERVER CONNECTED';

  @override
  String get pinChangeServer => 'Change server';

  @override
  String get stlModePenuh => 'Full';

  @override
  String get stlModePerItem => 'Per item';

  @override
  String get stlModeBagiRata => 'Split evenly';

  @override
  String get stlPayTunai => 'Cash';

  @override
  String get stlPayQris => 'QRIS';

  @override
  String get stlPayKartu => 'Card';

  @override
  String get stlPayTransfer => 'Transfer';

  @override
  String get stlPayLainnya => 'Other';

  @override
  String get stlProofTunai => 'Count the guest\'s cash on the denomination pad';

  @override
  String get stlProofQris =>
      'A screenshot of the QRIS confirmation is required';

  @override
  String get stlProofKartu => 'Photo of the EDC slip — approval code visible';

  @override
  String get stlProofTransfer =>
      'Photo of the transfer receipt + sender\'s name';

  @override
  String get stlProofLainnya => 'Photo of the payment proof';

  @override
  String get stlBlkNoLines => 'This bill has no items yet';

  @override
  String get stlBlkNothingLeft => 'Nothing left to charge';

  @override
  String get stlBlkPickItems => 'Pick items from the list';

  @override
  String get stlBlkNothingToCharge => 'Nothing to charge';

  @override
  String get stlBlkTapCash => 'Tap the notes you were handed';

  @override
  String get stlBlkAttachProof => 'Attach a photo of the payment proof first';

  @override
  String stlPhotoFailed(String error) {
    return 'Couldn\'t take the photo: $error';
  }

  @override
  String get stlTitle => 'Settlement';

  @override
  String get stlOutstandingHint => 'still to be charged';

  @override
  String get stlRowTotal => 'Bill total';

  @override
  String get stlRowAlreadyPaid => 'Already received';

  @override
  String get stlRowReceivingNow => 'Receiving now';

  @override
  String get stlPerItemEmpty =>
      'Tap the items this guest is paying for. Items already settled are locked.';

  @override
  String stlRowNItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get stlRowServiceTax => 'Service + tax';

  @override
  String get stlRowPayingNow => 'Paying now';

  @override
  String get stlRowRemainderAfter => 'Left after this';

  @override
  String get stlRowPerHead => 'Per person (rounded to 100)';

  @override
  String stlRowOpenShares(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shares unpaid',
      one: '1 share unpaid',
    );
    return '$_temp0';
  }

  @override
  String get stlRowChargeNow => 'Charge now';

  @override
  String get stlSplitFor => 'Split between';

  @override
  String get stlMethod => 'Method';

  @override
  String stlLockedTo(String method) {
    return 'Locked — the earlier payment was $method';
  }

  @override
  String get stlProofAttached => 'Proof attached';

  @override
  String get stlRetakePhoto => 'Retake';

  @override
  String get stlTakePhoto => 'Photograph the payment proof';

  @override
  String stlConfirmItems(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Take $count items · $amount',
      one: 'Take 1 item · $amount',
    );
    return '$_temp0';
  }

  @override
  String stlConfirmShare(String amount) {
    return 'Take this share · $amount';
  }

  @override
  String stlConfirmFull(String amount) {
    return 'Take $amount';
  }

  @override
  String get stlAutoPrintHint =>
      'The receipt prints automatically once confirmed';

  @override
  String get zoneAdminTableNameHint => 'e.g. T7, Booth A';

  @override
  String get zoneAdminManageZones => 'Manage zones';

  @override
  String zoneAdminSummary(int zones, int tables, int seats) {
    String _temp0 = intl.Intl.pluralLogic(
      zones,
      locale: localeName,
      other: '$zones zones',
      one: '1 zone',
    );
    String _temp1 = intl.Intl.pluralLogic(
      tables,
      locale: localeName,
      other: '$tables tables',
      one: '1 table',
    );
    String _temp2 = intl.Intl.pluralLogic(
      seats,
      locale: localeName,
      other: '$seats seats',
      one: '1 seat',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String get zoneAdminEmpty => 'No zones yet. Add the first one.';

  @override
  String zoneAdminMoveTablesFirst(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Move $count tables out before deleting this zone.',
      one: 'Move 1 table out before deleting this zone.',
    );
    return '$_temp0';
  }

  @override
  String get zoneAdminDeleteZoneTitle => 'Delete this zone?';

  @override
  String zoneAdminDeleteZoneBody(String name) {
    return 'Zone \"$name\" will be deleted.';
  }

  @override
  String get zoneAdminNewZone => 'New zone';

  @override
  String zoneAdminEditZone(String name) {
    return 'Edit $name';
  }

  @override
  String get zoneAdminZoneName => 'Zone name';

  @override
  String get zoneAdminZoneNameHint => 'e.g. Terrace, Bar';

  @override
  String get zoneAdminColor => 'Colour';

  @override
  String get zoneAdminPreview => 'PREVIEW';

  @override
  String get zoneAdminNoTablesHere => 'No tables in this zone yet.';

  @override
  String zoneAdminTablesHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tables are in this zone.',
      one: '1 table is in this zone.',
    );
    return '$_temp0';
  }

  @override
  String get vstIdentityHead => 'VENUE IDENTITY';

  @override
  String get vstNoLegalName => 'No legal name yet';

  @override
  String get vstNoAddress => 'No address yet';

  @override
  String get vstLegalNameHint => 'PT …';

  @override
  String get vstPhoneHint => '+62 …';

  @override
  String get vstTaglineHint => 'e.g. Coffee & Kitchen';

  @override
  String get vstHeaderHint => 'Prints above the receipt';

  @override
  String get vstSocialHint => '@instagram · wa.me/…';

  @override
  String get vstFooterHint => 'Prints below the receipt';

  @override
  String get vstThankYouHint => 'Thank you';

  @override
  String get vstQrUrlHint => 'https://… (money receipts only)';

  @override
  String get vstQrCaptionHint => 'e.g. Review us on Google';

  @override
  String get vstNotSet => 'Not set';

  @override
  String vstReportsStartAt(String hour) {
    return 'From $hour:00';
  }

  @override
  String vstTaxOn(String pct) {
    return '$pct tax';
  }

  @override
  String get vstTaxOff => 'Tax off';

  @override
  String get vstServiceOff => 'Service off';

  @override
  String vstServiceValue(String value) {
    return 'Service $value';
  }

  @override
  String get vstFeesTag => 'FEES';

  @override
  String get vstEnableTax => 'Charge tax';

  @override
  String get vstTaxRate => 'Tax rate';

  @override
  String get vstEnableService => 'Charge service';

  @override
  String get vstServiceRate => 'Service rate';

  @override
  String get vstServiceAmount => 'Service amount';

  @override
  String get vstTaxAfterDiscount => 'Tax is calculated after the discount';

  @override
  String get vstTaxAfterDiscountOn =>
      'A discount lowers the taxable base — tax and service are calculated on the discounted amount.';

  @override
  String get vstTaxAfterDiscountOff =>
      'Tax and service are calculated on the gross subtotal; the discount comes off the final total.';

  @override
  String get vstItemDiscountNote =>
      'A per-item discount is always applied before tax.';

  @override
  String get vstDiscountPresets => 'Discount presets';

  @override
  String get vstFeeType => 'Fee type';

  @override
  String get vstFeePercent => 'Percent';

  @override
  String get vstFeeFixed => 'Fixed';

  @override
  String get vstReportsTag => 'REPORTS';

  @override
  String get vstBusinessDayStart => 'Business day starts at';

  @override
  String get vstBusinessDayStartHint => 'Groups the \"Today\" report';

  @override
  String get tkwFallbackLabel => 'Takeaway';

  @override
  String tkwItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ITEMS',
      one: '1 ITEM',
    );
    return '$_temp0';
  }

  @override
  String get tkwHandedOverTag => 'HANDED OVER';

  @override
  String get tkwEmpty => 'No items yet.';

  @override
  String tkwServeFailed(String error) {
    return 'Couldn\'t mark it served: $error';
  }

  @override
  String tkwBillLoadFailed(String error) {
    return 'Couldn\'t load the bill: $error';
  }

  @override
  String get tkwErrNotTerminal =>
      'Some items are still cooking — wait until they\'re ready.';

  @override
  String get tkwErrNoTickets => 'No items to hand over yet.';

  @override
  String tkwHandoverFailed(String error) {
    return 'Couldn\'t hand it over: $error';
  }

  @override
  String get tkwHandover => 'Hand over';

  @override
  String get tkwHandoverBlocked =>
      'You can hand over once every item is ready or served.';

  @override
  String get tkwHandedOver => 'Handed over to the guest.';

  @override
  String mvtTitle(String table) {
    return 'Move table $table';
  }

  @override
  String mvtSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pick a free table · $count guests',
      one: 'Pick a free table · 1 guest',
    );
    return '$_temp0';
  }

  @override
  String get mvtNoTargets => 'No free table to move to.';

  @override
  String tblCapacityOf(int count) {
    return 'seats $count';
  }

  @override
  String mvtConfirmTitle(String table) {
    return 'Move table $table?';
  }

  @override
  String mvtConfirmOver(String table, int capacity, int pax) {
    String _temp0 = intl.Intl.pluralLogic(
      pax,
      locale: localeName,
      other: '$pax guests are',
      one: '1 guest is',
    );
    return 'Destination: table $table (seats $capacity). $_temp0 over capacity — go ahead?';
  }

  @override
  String mvtConfirmBody(String table) {
    return 'Every order and guest moves to table $table.';
  }

  @override
  String get mvtConfirmAction => 'Move';

  @override
  String mvtFailed(String error) {
    return 'Couldn\'t move the table: $error';
  }

  @override
  String get asgTitle => 'Assign to a table';

  @override
  String get asgSubtitle => 'Set the guests, then pick a free table';

  @override
  String get asgGuestNameHint => 'Guest name (optional)';

  @override
  String get asgNoTargets => 'No free tables.';

  @override
  String gstTableLabel(String table) {
    return 'Table $table';
  }

  @override
  String get gstTitle => 'Set the guest count';

  @override
  String get gstWaiterOnly => 'Only a waiter can change the guest count.';

  @override
  String kitQueueSub(int orders, int items) {
    return '$orders ORDERS · $items ITEMS IN THE PREP QUEUE';
  }

  @override
  String get kitShowDone => 'Show finished orders';

  @override
  String kitSentAt(String time) {
    return 'in at $time';
  }

  @override
  String get kitAllReady => 'All ready';

  @override
  String kitReadyOf(int done, int total) {
    return '$done/$total ready';
  }

  @override
  String get kitHoldToFinish => 'Hold to mark it done';

  @override
  String get kitEmptyTitle => 'The cook queue is empty';

  @override
  String get kitEmptyBody => 'Every kitchen order has been cooked.';

  @override
  String liaTableAt(String table, String time) {
    return 'TABLE $table · $time';
  }

  @override
  String get liaTapOutside => 'Tap outside the sheet to cancel.';

  @override
  String get liaVoidWarning =>
      'A void is recorded against your sign-in together with its reason — visible in reports and the audit log.';

  @override
  String get liaVoided => 'Item voided';

  @override
  String liaVoidedNote(int qty, String name) {
    return 'Recorded: ×$qty $name · under your name · visible in reports';
  }

  @override
  String resDaySummary(String day, int bookings, int covers) {
    String _temp0 = intl.Intl.pluralLogic(
      bookings,
      locale: localeName,
      other: '$bookings bookings',
      one: '1 booking',
    );
    String _temp1 = intl.Intl.pluralLogic(
      covers,
      locale: localeName,
      other: '$covers guests',
      one: '1 guest',
    );
    return '$day · $_temp0 · $_temp1';
  }

  @override
  String resNoTableForParty(int size) {
    return 'No table in this zone seats $size or more.';
  }

  @override
  String get resAlreadySeated => 'Another party is already at that table';

  @override
  String resSeatFailed(String error) {
    return 'Couldn\'t seat them: $error';
  }

  @override
  String get resNewBooking => 'New booking';

  @override
  String get resGuestName => 'Guest name';

  @override
  String get resPhone => 'Phone';

  @override
  String get resOptional => 'optional';

  @override
  String get resPartySize => 'Party size';

  @override
  String resSaveFailed(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String get prnPick => 'Pick a printer';

  @override
  String get prnNoneOnline =>
      'No printer is online. Add one by hand, or pair the Bluetooth printer in Settings first.';

  @override
  String get prnAddWifi => 'Add a Wi-Fi printer';

  @override
  String get prnLabel => 'Label';

  @override
  String get prnHost => 'Host (IP)';

  @override
  String get prnPort => 'Port';

  @override
  String get prnScopeVenue => 'Venue';

  @override
  String get prnScopeDevice => 'This device';

  @override
  String get dscNoPresetsTitle => 'No discount presets yet';

  @override
  String get dscNoPresetsLine =>
      'No per-item discount presets yet. Add one under Venue settings › Discounts.';

  @override
  String get dscNoPresetsBill =>
      'No bill discount presets yet. Add one under Venue settings › Discounts.';

  @override
  String get dscNoPresetsReceipt =>
      'No per-receipt discount presets yet. Add one under Venue settings › Discounts.';

  @override
  String dscSheetTitle(String target) {
    return 'Discount · $target';
  }

  @override
  String get dscApproverTitle => 'Manager approval';

  @override
  String get dscApproverBody =>
      'This discount needs a manager\'s approval. Ask a manager to enter their PIN.';

  @override
  String get dscAppliesLine => 'Applies to this item';

  @override
  String get dscAppliesBill => 'Applies to the whole bill · every receipt';

  @override
  String get dscAppliesReceipt => 'Applies to this whole receipt';

  @override
  String ordServeFailed(String error) {
    return 'Couldn\'t mark it served: $error';
  }

  @override
  String ordSummary(int active, int ready) {
    return '$active running · $ready ready to run';
  }

  @override
  String get ordUnderMin => '<1m';

  @override
  String ordSince(String time) {
    return 'since $time';
  }

  @override
  String get cshTitle => 'Cashier';

  @override
  String cshSummary(int running, int takeaway, int settled) {
    String _temp0 = intl.Intl.pluralLogic(
      running,
      locale: localeName,
      other: '$running bills',
      one: '1 bill',
    );
    return '$_temp0 running · $takeaway without a table · $settled settled';
  }

  @override
  String get cshUnbilled => 'Outstanding';

  @override
  String rtoReadyAtPass(String what) {
    return 'Ready at the pass · $what';
  }

  @override
  String get rtoPickUp => 'Pick up';

  @override
  String get crsTitle => 'CUSTOM RANGE';

  @override
  String get crsFrom => 'From';

  @override
  String get crsTo => 'To';

  @override
  String get crsApply => 'Apply';

  @override
  String get exitAgainToQuit => 'Press back again to exit';

  @override
  String olcVoidedBy(String reason, String approver) {
    return 'Voided · $reason · approved by $approver';
  }

  @override
  String get rdyBannerText =>
      'Items are ready at the pass — mark them served below';

  @override
  String get ppfTitle => 'Payment proof';

  @override
  String get ppfUnavailable => 'This proof photo could not be loaded';

  @override
  String get cpdTitle => 'Guest\'s cash · tap the notes';

  @override
  String blcPaidPct(String amount, String pct) {
    return '$amount in · $pct%';
  }

  @override
  String get tblDetailEmptyLines =>
      'No items yet — tap Add order on the right to start.';

  @override
  String tblNoTablesInZone(String zone) {
    return 'No tables in $zone yet';
  }

  @override
  String get ownMoneyAuditTitle => 'Money log';

  @override
  String get ownMoneyAuditEmpty => 'No money-affecting activity in this range.';

  @override
  String ownMoneyAuditTruncated(int count) {
    return 'Showing the $count most recent — the full log is on the venue device';
  }

  @override
  String get ownReportTitle => 'Venue report';

  @override
  String altMinutes(int value) {
    return '$value min';
  }

  @override
  String get vhbSettings => 'Settings';

  @override
  String mnaItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get cmnStationsLive => 'STATIONS · LIVE';

  @override
  String modSpecialCounter(int used) {
    return '$used / 80 · shown to the kitchen';
  }

  @override
  String zonSeatsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats',
      one: '1 seat',
    );
    return '$_temp0';
  }

  @override
  String zonTablesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tables',
      one: '1 table',
    );
    return '$_temp0';
  }

  @override
  String stfPinIs(String pin) {
    return 'PIN $pin';
  }

  @override
  String get onbPickMode => 'Pick a mode';

  @override
  String get onbPickModeSub => 'Will this tablet be the server or a client?';

  @override
  String get fbdNoAccess => 'Access not allowed';

  @override
  String get rptLoadFailed => 'Couldn\'t load the report';

  @override
  String rptStockFailed(String error) {
    return 'Couldn\'t load the ingredient report: $error';
  }

  @override
  String get rptStockEmpty => 'No ingredient activity in this range.';

  @override
  String get fltLoadFailed => 'Couldn\'t load the fleet';

  @override
  String get fltNewVenue => 'New venue';

  @override
  String get fltOfflineNote =>
      'Not connected — this data is stored and may already have changed. Editing is disabled until you reconnect.';

  @override
  String get sntTitle => 'Sent';

  @override
  String sntBody(String table) {
    return 'Table $table\'s order is live on the kitchen and bar displays.';
  }

  @override
  String sntLatency(String ms) {
    return 'LAN P50 ${ms}MS · CLOUD QUEUED';
  }

  @override
  String meShiftLine(String start, String elapsed) {
    return 'STARTED $start · $elapsed RUNNING';
  }

  @override
  String get meNoShift => 'No shift running';

  @override
  String get meAuditEmpty =>
      'No audit entries yet. Voids, comps and post-send changes show up here.';

  @override
  String meAuditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get meRecentActivity => 'Recent activity';

  @override
  String get pinDebugSeeded => 'DEBUG · SEEDED PINS';

  @override
  String pinCopied(String label) {
    return 'Copied: $label';
  }

  @override
  String get fveLapsedNote =>
      'The subscription has lapsed. Renew it below before the venue can be reactivated.';

  @override
  String fveManyAdmins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active admins',
      one: '1 active admin',
    );
    return 'This venue has $_temp0. A venue may now have only one — suspend the rest and keep the account on the device that holds the venue\'s data. Any admin left active will not be able to sign in.';
  }

  @override
  String fveLoadFailed(String error) {
    return 'Couldn\'t load: $error';
  }

  @override
  String get fveAtCapNote =>
      'One venue, one active admin. To swap admins: suspend the old one first, then add the new one.';

  @override
  String get fveDangerZone => 'DANGER ZONE';

  @override
  String get fveDeleteBlocked =>
      'Delete every account on this venue before deleting the venue itself. To only cut off access, use Suspend above.';

  @override
  String get fveDeleteWarning =>
      'Deleting a venue can\'t be undone. To only cut off access, use Suspend above.';

  @override
  String get fveAnnual => 'Pay yearly';

  @override
  String get fveAnnualNoPrice => 'Save 2 months — set a monthly price first.';

  @override
  String fveAnnualPrice(String amount) {
    return '$amount a year — 2 months saved.';
  }

  @override
  String get fveNoCutoff =>
      'With no date the subscription never lapses and the venue is never suspended automatically.';

  @override
  String fveAddPrincipal(String role, String venue) {
    return 'Add $role · $venue';
  }

  @override
  String get rtoNow => 'NOW';

  @override
  String rtoTableNow(String table, String zone) {
    return 'TABLE $table · $zone · NOW';
  }

  @override
  String get olcMarkServed => 'Mark served';

  @override
  String get dscManagerPin => 'Manager PIN';

  @override
  String get dscApprove => 'Approve';

  @override
  String get cpdExact => 'Exact';

  @override
  String get cpdClear => 'Clear';

  @override
  String cpdNoteSemantics(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$label, $_temp0';
  }

  @override
  String get cpdReceived => 'Received';

  @override
  String get cpdShort => 'Still short';

  @override
  String get cpdChange => 'Change';

  @override
  String get blcNoName => 'No name';

  @override
  String blcPaxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String get blcCaptionPaid => 'total paid';

  @override
  String get blcCaptionOutstanding => 'still owed';

  @override
  String get blcCaptionWriteOff => 'written off';

  @override
  String get blcVerbIn => 'in';

  @override
  String get blcVerbSeated => 'seated';

  @override
  String get blcVerbClosed => 'closed';

  @override
  String get blcSeeReceipt => 'View receipt';

  @override
  String get blcCharge => 'Charge';

  @override
  String get blcPillSettled => 'Settled';

  @override
  String get blcPillPartial => 'Part-paid';

  @override
  String get blcPillWriteOff => 'Written off';

  @override
  String get blcPillUnpaid => 'unpaid';

  @override
  String blcSemantics(String label, String state, String amount) {
    return '$label, $state, $amount';
  }

  @override
  String blcSinceChip(String verb, String elapsed) {
    return '$verb $elapsed';
  }

  @override
  String get blcTableClosed => 'Table released';

  @override
  String blcEvenSplit(int shares, int paid) {
    return 'Split $shares · $paid paid';
  }

  @override
  String get blcPrepaid => 'Prepaid in-app';

  @override
  String get cshLoadFailedTitle => 'Couldn\'t load the bills';

  @override
  String get cshPullToRetry => 'Pull to try again.';

  @override
  String get cshEmptyDetached => 'No released table is still unpaid';

  @override
  String get cshEmptyOpen => 'No open bills';

  @override
  String get cshEmptySettledToday => 'No bills settled today yet';

  @override
  String get cshEmptySettled7d => 'No bills settled in the last 7 days';

  @override
  String get cshEmptyAll => 'No bills yet';

  @override
  String get cshStatUnpaid => 'Unpaid';

  @override
  String get cshStatPartial => 'Part-paid';

  @override
  String get cshStatReceived => 'Received';

  @override
  String get cshStatClosed => 'Table released';

  @override
  String get cshSegNeedCharge => 'To charge';

  @override
  String get cshSegSettled => 'Settled';

  @override
  String get cshSegAll => 'All';

  @override
  String get cshRangeToday => 'Today';

  @override
  String get cshRange7d => '7 days';

  @override
  String get fltActive => 'ACTIVE';

  @override
  String get fltSuspended => 'SUSPENDED';

  @override
  String get fltConsoleTitle => 'Fleet';

  @override
  String get fltSearchHint => 'Search name or address';

  @override
  String get fltEmptyNoVenue => 'No venues yet';

  @override
  String get fltEmptyNoMatch => 'Nothing matches';

  @override
  String get fltVenueActions => 'Venue actions';

  @override
  String get fltVenueName => 'Venue name';

  @override
  String get fltVenueAdmin => 'Venue admin';

  @override
  String get fltOwner => 'Owner';

  @override
  String get fltVenueAccess => 'Venue access';

  @override
  String get fltSuspend => 'Suspend';

  @override
  String get fltSubscription => 'Subscription';

  @override
  String get fltStartTrial => 'Start trial';

  @override
  String get fltPricePerMonth => 'Price per month';

  @override
  String get fltAccountActions => 'Account actions';

  @override
  String get fltSendWa => 'Send WhatsApp';

  @override
  String get fltDeleteVenue => 'Delete venue';

  @override
  String get fltClearDate => 'Clear date';

  @override
  String get fltPickDate => 'Pick';

  @override
  String get fltInitialPassword => 'Initial password';

  @override
  String get ordReadyForPickup => 'Ready to collect';

  @override
  String get ordPreparing => 'Preparing';

  @override
  String get ordDone => 'Done';

  @override
  String get ordTabMine => 'Mine';

  @override
  String get ordServe => 'Serve';

  @override
  String get meKpiOpenTickets => 'Open tickets';

  @override
  String get meKpiCovers => 'Covers served';

  @override
  String get meSignOut => 'Sign out';

  @override
  String get liaFireNow => 'Fire now';

  @override
  String get liaEditItem => 'Edit item';

  @override
  String get liaUnserve => 'Undo served';

  @override
  String get liaVoidItem => 'Void item';

  @override
  String get liaVoidReasonHint => 'Required — explain the void';

  @override
  String get fltEmptyNoVenueBody =>
      'Create the first venue with \"New venue\", then add its admin from inside that venue.';

  @override
  String fltEmptyLensBody(String lens) {
    return 'No venue in the \"$lens\" lens.';
  }

  @override
  String fltEmptyQueryBody(String query) {
    return 'No venue matches \"$query\".';
  }

  @override
  String fltEmptyQueryLensBody(String query, String lens) {
    return 'No venue matches \"$query\" in the \"$lens\" lens.';
  }

  @override
  String get fltLensTrouble => 'Needs action';

  @override
  String get fltLensBilling => 'Billing';

  @override
  String get fltLensOff => 'Disabled';

  @override
  String get fltKicker => 'FLEET';

  @override
  String fltOnlineOf(int live, int total) {
    return '$live OF $total ONLINE';
  }

  @override
  String get resSaveBooking => 'Save booking';

  @override
  String get resMemberEnrol => 'Enrol as a customer';

  @override
  String get resMemberEnrolFailed => 'Booking saved, customer not created';

  @override
  String get resMemberNoMatch => 'No match';

  @override
  String get resMemberTakenTitle => 'Number already registered';

  @override
  String resMemberTakenBody(String name) {
    return 'This number belongs to $name. Use that customer for this booking?';
  }

  @override
  String get resMemberUse => 'Use';

  @override
  String get stfRoleActive => 'on';

  @override
  String stfRoleLockedSemantics(String role, String cap, String state) {
    return '$role, $cap, $state, locked';
  }

  @override
  String stfRoleSemantics(String role, String cap) {
    return '$role, $cap';
  }

  @override
  String get mnaAddItemShort => '+ Item';

  @override
  String get mnaAddCategory => '+ Add category';

  @override
  String mnaAddThing(String thing) {
    return '+ Add $thing';
  }

  @override
  String zonAdminSub(int tables, int zones, int seats) {
    String _temp0 = intl.Intl.pluralLogic(
      tables,
      locale: localeName,
      other: '$tables tables',
      one: '1 table',
    );
    String _temp1 = intl.Intl.pluralLogic(
      zones,
      locale: localeName,
      other: '$zones zones',
      one: '1 zone',
    );
    String _temp2 = intl.Intl.pluralLogic(
      seats,
      locale: localeName,
      other: '$seats seats',
      one: '1 seat',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String venueHubTablesZones(int tables, int zones) {
    String _temp0 = intl.Intl.pluralLogic(
      tables,
      locale: localeName,
      other: '$tables tables',
      one: '1 table',
    );
    String _temp1 = intl.Intl.pluralLogic(
      zones,
      locale: localeName,
      other: '$zones zones',
      one: '1 zone',
    );
    return '$_temp0 ($_temp1)';
  }

  @override
  String venueHubMenuItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count menu items',
      one: '1 menu item',
    );
    return '$_temp0';
  }

  @override
  String venueHubStaffCount(int count) {
    return '$count staff';
  }

  @override
  String get onbModeServer => 'Server';

  @override
  String get onbModeServerSub =>
      'This tablet hosts the venue. The database lives here.';

  @override
  String get onbModeClient => 'Client';

  @override
  String get onbModeClientSub =>
      'This tablet takes orders and connects to the server over LAN.';

  @override
  String get modSize => 'Size';

  @override
  String get modNoteHint => 'e.g. allergy not listed, plating note…';

  @override
  String venueHubStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredients',
      one: '1 ingredient',
    );
    return '$_temp0';
  }

  @override
  String venueHubStockLow(int count, int low) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredients',
      one: '1 ingredient',
    );
    return '$_temp0 ($low low)';
  }

  @override
  String get alertsSoundHint =>
      'Pick a tone for each event. This choice applies to every device in the venue.';

  @override
  String kitchenQueueSub(int orders, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      orders,
      locale: localeName,
      other: '$orders active orders',
      one: '1 active order',
    );
    String _temp1 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items items',
      one: '1 item',
    );
    return '$_temp0 · $_temp1 · hold to mark done';
  }

  @override
  String modDietaryLine(String tags) {
    return 'Suits $tags';
  }

  @override
  String modAllergenLine(String tags) {
    return 'Contains $tags — confirm with the guest';
  }

  @override
  String rptSubNet(int sessions, int covers) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions sessions',
      one: '1 session',
    );
    String _temp1 = intl.Intl.pluralLogic(
      covers,
      locale: localeName,
      other: '$covers guests',
      one: '1 guest',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String rptSubGross(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get rptSubTaxService => 'PB1 11% · Svc 7% (est)';

  @override
  String rptSubVoid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voided items',
      one: '1 voided item',
    );
    return '$_temp0';
  }

  @override
  String get rptSubTurnTime => 'How long guests sit';

  @override
  String get rptSubPrep => 'Median sent → ready';

  @override
  String get rptSubPickup => 'Median ready → served';

  @override
  String rptSubReservations(int noShow, int cancelled) {
    return '$noShow no-show · $cancelled cancelled';
  }

  @override
  String get rptStationKitchen => 'Main Kitchen';

  @override
  String get rptUnknownStaff => 'Unknown';

  @override
  String get vrsWrongOrder => 'Sent wrong';

  @override
  String get vrsWrongOrderDesc => 'Wrong table, double tap, wrong ring';

  @override
  String get vrsCustomerChange => 'Guest changed their mind';

  @override
  String get vrsCustomerChangeDesc => 'Guest cancelled the request';

  @override
  String get vrsOutOfStock => 'Out of stock';

  @override
  String get vrsOutOfStockDesc => 'Item ran out at the station';

  @override
  String get vrsKitchenError => 'Complaint / kitchen quality';

  @override
  String get vrsKitchenErrorDesc =>
      'Quality problem — item pulled off the bill';

  @override
  String get vrsComp => 'Manager comp';

  @override
  String get vrsOther => 'Other';

  @override
  String get vrsOtherDesc => 'A written reason is required';

  @override
  String get modGroupSpice => 'Spice level';

  @override
  String get modGroupExtras => 'Extras';

  @override
  String get modGroupSauce => 'Sauce';

  @override
  String get modGroupProtein => 'Pick a protein';

  @override
  String get vrsCompDesc => 'Comped for the guest · recorded apart from a void';

  @override
  String get authServerTrouble =>
      'The server is having trouble. Try again in a moment.';

  @override
  String get authWrongPin => 'Wrong PIN. Try again.';

  @override
  String get authWrongCredentials => 'Wrong email or password.';

  @override
  String get authNoConnection =>
      'Couldn\'t reach the server. Check Wi-Fi and try again.';

  @override
  String get authInvalidEmail => 'That email isn\'t valid.';

  @override
  String get authAccountDisabled => 'This admin account is disabled.';

  @override
  String get authTooManyAttempts => 'Too many attempts. Try again later.';

  @override
  String get authFirstLoginNeedsInternet =>
      'Couldn\'t connect. The first admin sign-in needs internet.';

  @override
  String get authAdminLoginFailed => 'Admin sign-in failed. Try again.';

  @override
  String get prnErrNoLines => 'Nothing to print';

  @override
  String get prnErrNotConnected => 'Printer isn\'t connected';

  @override
  String get prnErrNoPrinter => 'Printer not found';

  @override
  String get prnErrFailed => 'Couldn\'t print';

  @override
  String prnErrFailedCode(String code) {
    return 'Couldn\'t print ($code).';
  }

  @override
  String get authServerNotReadyWait =>
      'The server isn\'t ready yet. Wait a moment and try again.';

  @override
  String get authServerNotReady => 'The server isn\'t ready yet. Try again.';

  @override
  String get authAdminNotRegistered =>
      'This admin account isn\'t registered. Contact your operator.';

  @override
  String get authAdminSuspended =>
      'This admin account is suspended. Contact your operator.';

  @override
  String get authAdminInactive => 'This admin account is inactive.';

  @override
  String get authNoVenueAssigned =>
      'This account isn\'t assigned to a venue. Contact your operator.';

  @override
  String get authVenueNotFound => 'Venue not found. Contact your operator.';

  @override
  String get authVenueSuspended =>
      'This venue is suspended. Contact your operator.';

  @override
  String get authVenueInactive => 'This venue is inactive.';

  @override
  String get sendQueueFull =>
      'Send queue is full — reconnect to the server before taking more orders';

  @override
  String sendQueuePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders waiting to send',
      one: '1 order waiting to send',
    );
    return '$_temp0';
  }

  @override
  String get sendQueueTertunda => 'Pending';

  @override
  String sendQueueCapturedAt(String time) {
    return 'Captured $time';
  }

  @override
  String get sendResultTitle => 'Send result';

  @override
  String sendResultAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders sent',
      one: '1 order sent',
    );
    return '$_temp0';
  }

  @override
  String get sendResultAcknowledge => 'Got it';

  @override
  String get sendResultFailedHeading => 'Failed to send';

  @override
  String get sendFailVisitChanged =>
      'Table has changed guests — the order was not attached';

  @override
  String get sendFailBillClosed => 'The bill had already closed';

  @override
  String get sendFailExpired =>
      'Past the business day — the order was not sent';

  @override
  String get sendFailBlocked =>
      'This account may not send orders — sign in as the order taker';

  @override
  String get sendFailOther => 'Refused by the server';

  @override
  String sendQueueBlockEndShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count orders still haven\'t been sent. Reconnect to the server, or discard them.',
      one:
          '1 order still hasn\'t been sent. Reconnect to the server, or discard it.',
    );
    return '$_temp0';
  }

  @override
  String get sendQueueDiscardAll => 'Discard pending orders';

  @override
  String get tktOutOfStock => 'out of stock';

  @override
  String tktOutOfStockNamed(String names) {
    return 'out of stock: $names';
  }

  @override
  String tktNotSent(String what, String why) {
    return '$what wasn\'t sent — $why';
  }

  @override
  String get auditLoadFailed => 'Couldn\'t load the audit log';

  @override
  String get capTakeOrder => 'Take order';

  @override
  String get capModifyOrder => 'Modify order';

  @override
  String get capVoidItem => 'Void item';

  @override
  String get capCompItem => 'Comp item';

  @override
  String get capViewKds => 'View KDS';

  @override
  String get capOpenDrawer => 'Open drawer';

  @override
  String get capApplyDiscount => 'Apply discount';

  @override
  String get capSettleBill => 'Settle bill';

  @override
  String get capRefund => 'Refund';

  @override
  String get capManageCash => 'Manage petty cash';

  @override
  String get cashCatIngredients => 'Ingredients';

  @override
  String get cashCatOperations => 'Operations';

  @override
  String get cashCatTransport => 'Transport';

  @override
  String get cashCatDailyWage => 'Daily wages';

  @override
  String get cashCatOther => 'Other';

  @override
  String get cashKindTopUp => 'Top-up';

  @override
  String get cashKindExpense => 'Expense';

  @override
  String get cashKindCount => 'Count';

  @override
  String get cashKindReversal => 'Reversal';

  @override
  String get kasTitle => 'Petty cash';

  @override
  String get kasHubSubtitle => 'Balance, expenses, counts';

  @override
  String get kasBalance => 'Cash balance';

  @override
  String kasLastCount(String when) {
    return 'Last counted $when';
  }

  @override
  String get kasNeverCounted => 'Never counted';

  @override
  String get kasEmptyTitle => 'The petty cash box is empty';

  @override
  String get kasEmptyBody =>
      'Fund the box first — expenses can only be recorded against cash that is in it.';

  @override
  String get kasActionTopUp => 'Top up';

  @override
  String get kasActionExpense => 'Expense';

  @override
  String get kasActionCount => 'Count';

  @override
  String get kasSheetTopUpTitle => 'Top up petty cash';

  @override
  String get kasSheetExpenseTitle => 'Cash expense';

  @override
  String get kasSheetCountTitle => 'Count the box';

  @override
  String get kasFieldAmount => 'Amount';

  @override
  String get kasFieldCounted => 'Cash in the box';

  @override
  String get kasFieldNote => 'Note';

  @override
  String get kasFieldReason => 'Reason';

  @override
  String get kasFieldCategory => 'Category';

  @override
  String get kasPhotoAdd => 'Receipt photo';

  @override
  String kasLedgerSays(String amount) {
    return 'Ledger says $amount';
  }

  @override
  String kasVariance(String amount) {
    return 'Variance $amount';
  }

  @override
  String get kasDetailTitle => 'Cash movement';

  @override
  String kasCounted(String amount) {
    return 'Counted $amount';
  }

  @override
  String get kasReverse => 'Reverse movement';

  @override
  String get kasReverseTitle => 'Reverse this movement';

  @override
  String get kasReverseBody =>
      'The row stays; the reversal is recorded as a new movement.';

  @override
  String get kasReversed => 'Reversed';

  @override
  String get kasIsReversal => 'Reverses an earlier movement';

  @override
  String get kasActorUnknown => 'System';

  @override
  String kasBy(String name) {
    return 'by $name';
  }

  @override
  String kasErrInsufficient(String amount) {
    return 'The box only holds $amount';
  }

  @override
  String get kasErrReasonRequired => 'A reason is required';

  @override
  String get kasErrAlreadyReversed => 'This movement has already been reversed';

  @override
  String get kasErrNotReversible => 'A reversal cannot itself be reversed';

  @override
  String get kasErrInvalidAmount => 'Not a valid amount';

  @override
  String kasErrFailed(String code) {
    return 'Could not save ($code)';
  }

  @override
  String get kasPhoneOnly => 'Petty cash is read on a tablet.';

  @override
  String get rptSecKas => 'Petty cash';

  @override
  String get rptSecMembers => 'Membership';

  @override
  String get rptMembersSub => 'Members over this range';

  @override
  String get rptMembersEmpty => 'No members enrolled in this range.';

  @override
  String get rptMembersEnrolled => 'New sign-ups';

  @override
  String get rptMembersActive => 'Active';

  @override
  String get rptMembersBills => 'Bills';

  @override
  String get rptMembersAvgBill => 'Member average';

  @override
  String get rptMembersAvgGuest => 'Walk-in average';

  @override
  String get rptMembersLift => 'Lift';

  @override
  String get rptMembersPoints => 'Points';

  @override
  String get rptMembersEarned => 'Earned';

  @override
  String get rptMembersRedeemed => 'Redeemed';

  @override
  String get rptMembersOutstanding => 'Outstanding';

  @override
  String get rptMembersLiability => 'Outstanding value';

  @override
  String get rptMembersTop => 'Top members';

  @override
  String get rptMembersGone => 'Deleted member';

  @override
  String rptMembersVisits(int count) {
    return 'Visits: $count';
  }

  @override
  String get rptKasOpening => 'Opening';

  @override
  String get rptKasIn => 'In';

  @override
  String get rptKasOut => 'Out';

  @override
  String get rptKasVariance => 'Count variance';

  @override
  String get rptKasClosing => 'Closing';

  @override
  String get rptKasByCategory => 'Expenses by category';

  @override
  String get rptKasEmpty => 'No cash movements in this range.';

  @override
  String get capCloseShift => 'Close shift';

  @override
  String get capEditMenu => 'Edit menu';

  @override
  String get capMarkSoldOut => 'Mark sold out';

  @override
  String get capAdjustStock => 'Adjust stock';

  @override
  String get capManageIngredients => 'Manage ingredients';

  @override
  String get capOverrideStock => 'Sell when out of stock';

  @override
  String get capManageMembers => 'Manage members';

  @override
  String get capManageMembersDesc =>
      'Edit, merge and delete member records, and correct points by hand. A cashier does not need this to enrol or redeem.';

  @override
  String get capManageStaff => 'Manage staff';

  @override
  String get capManageRoles => 'Manage roles';

  @override
  String get capViewReports => 'View reports';

  @override
  String get capEditSettings => 'Edit settings';

  @override
  String get capTakeOrderDesc =>
      'Create a new order and send it to the kitchen.';

  @override
  String get capModifyOrderDesc =>
      'Change quantity or notes on an order that isn\'t cooking yet.';

  @override
  String get capVoidItemDesc => 'Remove a sent item before it is served.';

  @override
  String get capCompItemDesc => 'Zero the price of an item already served.';

  @override
  String get capViewKdsDesc => 'Open the kitchen prep queue.';

  @override
  String get capOpenDrawerDesc => 'Open the cash drawer without a transaction.';

  @override
  String get capApplyDiscountDesc => 'Take money off a bill.';

  @override
  String get capSettleBillDesc => 'Take payment and close the bill.';

  @override
  String get capRefundDesc => 'Return money on a bill that is already paid.';

  @override
  String get capCloseShiftDesc => 'End a shift and count the cash.';

  @override
  String get capManageCashDesc =>
      'Record expenses from the petty cash box. Funding and counting it need the settings permission.';

  @override
  String get capEditMenuDesc =>
      'Add, edit and remove menu items and categories.';

  @override
  String get capMarkSoldOutDesc =>
      'Flag an item sold out without touching ingredient stock.';

  @override
  String get capAdjustStockDesc =>
      'Record a stocktake, receive goods and log waste.';

  @override
  String get capManageIngredientsDesc =>
      'Add and edit ingredients and their recipes.';

  @override
  String get capOverrideStockDesc =>
      'Send an order even when an ingredient reads empty.';

  @override
  String get capManageStaffDesc => 'Add staff, assign roles and reset PINs.';

  @override
  String get capManageRolesDesc =>
      'Create roles and set the permissions they carry.';

  @override
  String get capViewReportsDesc => 'Open sales reports and the audit trail.';

  @override
  String get capEditSettingsDesc => 'Change venue, timing and alert settings.';

  @override
  String get capGrpOrders => 'Orders';

  @override
  String get capGrpMoney => 'Money';

  @override
  String get capGrpInventory => 'Menu & stock';

  @override
  String get capGrpAdmin => 'Admin';

  @override
  String get capGrpKitchen => 'Kitchen';

  @override
  String get agbLockedOnRestart =>
      'The server locks the next time the app restarts — connect to the internet now to verify the admin.';

  @override
  String agbLockedInHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return 'Without internet the server locks in $_temp0. Connect soon.';
  }

  @override
  String agbLockedInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Without internet the server locks in $_temp0. Connect to verify the admin.';
  }

  @override
  String get crsStartBeforeEnd =>
      'The start date has to come before the end date.';

  @override
  String crsMaxSpan(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'The range can span at most $_temp0.';
  }

  @override
  String get pinPickServerFirst => 'Pick a server first.';

  @override
  String get pinDeviceNotPaired =>
      'This phone isn\'t paired. Scan the QR again to pair it.';

  @override
  String get pinSetupFailed => 'Couldn\'t set the app up. Try again.';

  @override
  String get pinServerBootFailed =>
      'Couldn\'t start the server on this phone. Try again.';

  @override
  String pinAutoClaimFailed(String error) {
    return 'Auto-connect failed: $error';
  }

  @override
  String get prnNothingToPrint => 'Nothing to print';

  @override
  String get prnThisDevice => 'This device';

  @override
  String get prnEnableBluetooth =>
      'Turn Bluetooth on in Settings, then try again';

  @override
  String get prnReceiptPrinted => 'Receipt printed';

  @override
  String get rptStockValue => 'Stock value';

  @override
  String get rptStockValueNow => 'Stock value now';

  @override
  String get rptNoStocktake => 'No stocktake in this range.';

  @override
  String get rptAllWaiters => 'All waiters';

  @override
  String get rptAllZones => 'All zones';

  @override
  String get rptAllCategories => 'All categories';

  @override
  String alertsThresholdLine(int prep, int ungreeted) {
    return 'Ready ${prep}m · ungreeted ${ungreeted}m';
  }

  @override
  String get venueHubShiftReport => 'Shift report';

  @override
  String get auditExportFailed => 'Couldn\'t export the audit log';

  @override
  String get killReasonOutOfStock => 'Out of ingredients';

  @override
  String get killReasonQuality => 'Not up to standard';

  @override
  String get rcpVenueNamePlaceholder => 'VENUE NAME';

  @override
  String get rcpSplitReceipt => 'SPLIT RECEIPT';

  @override
  String get ordEmptyPass => 'Nothing is ready at the pass yet.';

  @override
  String get ordEmptyPreparingAll => 'Nothing is being prepared.';

  @override
  String get ordEmptyPreparingMine =>
      'None of your items are being prepared.\nPick All to see the whole venue.';

  @override
  String get ordEmptyDoneAll => 'No items finished this session yet.';

  @override
  String get ordEmptyDoneMine =>
      'None of your items finished this session yet.\nPick All to see the whole venue.';

  @override
  String get rptStockWaste => 'Wasted';

  @override
  String get rptStockVariance => 'Stocktake variance';

  @override
  String get rptStockUsage => 'Usage';

  @override
  String get prnEnableBluetoothTitle => 'Turn Bluetooth on';

  @override
  String get killReasonBrokenEquipment => 'Equipment broken';

  @override
  String get killReasonTooSlow => 'Takes too long';

  @override
  String tblOccupiedOf(int occupied, int total) {
    return '$occupied of $total occupied';
  }

  @override
  String tblOpenTab(String amount) {
    return 'tab $amount';
  }

  @override
  String get tcStatusReserved => 'Reserved';

  @override
  String get tcStatusAvailable => 'Free';

  @override
  String get tcStatusOccupied => 'Occupied';

  @override
  String get tcStatusPending => 'Order taken';

  @override
  String tcStatusReady(int n) {
    return 'Ready ×$n';
  }

  @override
  String get mvtTargetOccupied => 'The destination table is already occupied.';

  @override
  String get mvtTableLocked => 'Another device is using this table.';

  @override
  String get mvtSourceEmpty => 'The source table is already empty.';

  @override
  String get modTagRequired => 'REQUIRED';

  @override
  String get modTagFree => 'PICK ANY';

  @override
  String get modTagOptional => 'OPTIONAL';

  @override
  String get modPickRequired => 'Pick required';

  @override
  String get liaFireDesc => 'Send the course straight to the line';

  @override
  String get liaEditDesc =>
      'Quantity, notes and choices · before it reaches the kitchen';

  @override
  String get liaServeDesc => 'Confirm picked up & delivered to the table';

  @override
  String get liaUnserveDesc => 'Undo if it was marked too early';

  @override
  String get liaVoidDesc => 'Remove from the order · logged under your name';

  @override
  String get meEndAdminTitle => 'End admin session?';

  @override
  String meEndServerBodyLive(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tables are',
      one: '1 table is',
    );
    return '$_temp0 still live. Signing out shuts the server down — every staff device disconnects and cannot reconnect until an admin signs in again.';
  }

  @override
  String get meEndServerBody =>
      'Signing out shuts the server down. Staff cannot connect until an admin signs in again.';

  @override
  String get meEndAndShutdown => 'Sign out & shut down';

  @override
  String get meNoOpenTickets => 'No open tickets';

  @override
  String get rcpItemizedReceipt => 'RECEIPT';

  @override
  String rcpRefundLine(String method) {
    return '$method (refund)';
  }

  @override
  String tableNamed(String label) {
    return 'Table $label';
  }

  @override
  String rcpPaxCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String get roleWaiter => 'Waiter';

  @override
  String get roleKitchen => 'Kitchen';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get tstatDraft => 'Draft';

  @override
  String get tstatAcknowledged => 'Acknowledged';

  @override
  String get tstatSent => 'Sent';

  @override
  String get tstatPrep => 'Preparing';

  @override
  String get tstatCooked => 'Cooked';

  @override
  String get tstatReady => 'Ready for pickup';

  @override
  String get tstatServed => 'Served';

  @override
  String get tstatHeld => 'Held';

  @override
  String get tstatVoided => 'Voided';

  @override
  String get resStatPending => 'Pending';

  @override
  String get resStatSeated => 'Seated';

  @override
  String get resStatNoShow => 'No-show';

  @override
  String get resStatCancelled => 'Cancelled';

  @override
  String get stkReasonSale => 'Sold';

  @override
  String get stkReasonVoidReturn => 'Void — returned';

  @override
  String get stkReasonWaste => 'Waste';

  @override
  String get stkReasonReceive => 'Goods received';

  @override
  String get stkReasonAdjust => 'Adjustment';

  @override
  String get stkReasonProduce => 'Production';

  @override
  String get noteLabel => 'Note';

  @override
  String tblZoneReadyCount(int n) {
    return '$n ready';
  }

  @override
  String get tkwStatusHandedOver => 'Handed over';

  @override
  String get tkwStatusReady => 'Ready';

  @override
  String get tkwStatusInProgress => 'In progress';

  @override
  String get tkwStatusDone => 'Done';

  @override
  String get pinSignInAsAdmin => 'Sign in as admin';

  @override
  String get prnAddManual => 'Add manually';

  @override
  String get rptLoading => 'Loading report…';

  @override
  String get rptFreshLive => 'Live';

  @override
  String get rptFreshSnapshot => 'Snapshot';

  @override
  String modOptionSoldOut(String name) {
    return '$name · sold out';
  }

  @override
  String venueHubBadgeFloor(int tables, int zones) {
    String _temp0 = intl.Intl.pluralLogic(
      tables,
      locale: localeName,
      other: '$tables tables',
      one: '1 table',
    );
    String _temp1 = intl.Intl.pluralLogic(
      zones,
      locale: localeName,
      other: '$zones zones',
      one: '1 zone',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String venueHubBadgeStaff(int n) {
    return '$n staff';
  }

  @override
  String get venueHubOperationalMode => 'Operational mode';

  @override
  String ordTitleVenue(String venue) {
    return '$venue orders';
  }

  @override
  String get ordTabReady => 'Ready';

  @override
  String get rcpSampleTable => 'Table 4 · Sample';

  @override
  String meAuditTable(String table) {
    return 'Table $table';
  }

  @override
  String resvSeatToTable(String action) {
    return '$action at table:';
  }

  @override
  String get resvZoneTableOptional => 'Zone & table (optional)';

  @override
  String get elapsedJustNow => 'just now';

  @override
  String elapsedMinutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String elapsedHoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String get ownRptLoadFailed => 'Could not load the report.';

  @override
  String get ownRptNoneYet => 'No report from this venue yet.';

  @override
  String get ownRptUnknownFormat => 'Unrecognised report format.';

  @override
  String get ownRptRequesting => 'Requesting report…';

  @override
  String get ownRptNoData => 'No data yet';

  @override
  String ownRptUpdatedPending(String ago) {
    return 'Updated $ago · waiting for the venue (it may be offline)';
  }

  @override
  String ownRptUpdated(String ago) {
    return 'Updated $ago';
  }

  @override
  String get fltNotConnected => 'Not connected — the change was not sent.';

  @override
  String get fltSignOutTitle => 'Sign out of Fleet?';

  @override
  String get fltSignOutBody => 'Signing back in needs the email & password.';

  @override
  String get fltSignOut => 'Sign out';

  @override
  String get fltBandTrouble => 'NEEDS ACTION';

  @override
  String get fltBandEnding => 'SUBSCRIPTION ENDING';

  @override
  String get fltBandIdle => 'NOT RUNNING';

  @override
  String get fltBandRunning => 'RUNNING';

  @override
  String get fltUnnamed => '(unnamed)';

  @override
  String fltEndsIn(String when) {
    return 'Ends $when';
  }

  @override
  String get fltActivate => 'Activate';

  @override
  String get fltSuspendKill => 'Suspend (kill)';

  @override
  String fltPaidUntil(String date) {
    return 'until $date';
  }

  @override
  String get fltBillingOverdue => 'Payment overdue';

  @override
  String fltSuspendedOn(String date) {
    return 'Suspended $date';
  }

  @override
  String fltOverdueDiesOn(String date) {
    return 'Overdue — dies $date';
  }

  @override
  String fltDaysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return 'in $_temp0';
  }

  @override
  String get fltToday => 'today';

  @override
  String fltVenueActivated(String name) {
    return '$name activated';
  }

  @override
  String fltSuspendTitle(String name) {
    return 'Suspend $name?';
  }

  @override
  String get fltSuspendBody =>
      'The venue server dies immediately and every staff device disconnects — including mid-rush.';

  @override
  String fltVenueSuspended(String name) {
    return '$name suspended';
  }

  @override
  String get fltVenueCreated => 'Venue created';

  @override
  String get fltLockoutPast => 'Past the offline limit — will lock on restart';

  @override
  String fltLockoutNear(int hours) {
    return 'Nearing the offline limit, ${hours}h left';
  }

  @override
  String get fltNeverOnline => 'Never online';

  @override
  String get fltOnline => 'Online';

  @override
  String fltOfflineMinutes(int n) {
    return 'Offline ${n}m';
  }

  @override
  String fltOfflineHours(int n) {
    return 'Offline ${n}h';
  }

  @override
  String fltOfflineDays(int n) {
    return 'Offline ${n}d';
  }

  @override
  String get fltTagAccount => 'ACCOUNTS';

  @override
  String get fltTagReports => 'REPORTS';

  @override
  String get fltTagData => 'DATA';

  @override
  String get fltTagControl => 'CONTROL';

  @override
  String get fltTagBilling => 'BILLING';

  @override
  String get fltAddAdmin => 'Add admin';

  @override
  String get fltAddOwner => 'Add owner';

  @override
  String get fltNoAdmins => 'No admin for this venue yet.';

  @override
  String get fltNoOwners =>
      'No owner account yet — read-only report access from outside the venue, not a staff role.';

  @override
  String get fltNameRequired => 'A name is required';

  @override
  String get fltAccessActive =>
      'The venue server is running and staff can sign in as usual.';

  @override
  String get fltAccessSuspended =>
      'The venue server is down. Staff cannot sign in until it is activated again.';

  @override
  String get fltAccessUnknown =>
      'The cloud does not recognise this status. The venue still cannot serve. Reset it with the button below.';

  @override
  String get fltNotSetLower => 'not set';

  @override
  String get fltNotSet => 'Not set';

  @override
  String get fltResetPassword => 'Reset password';

  @override
  String fltAdminActivated(String name) {
    return '$name activated';
  }

  @override
  String fltAdminSuspended(String name) {
    return '$name suspended';
  }

  @override
  String fltAdminDeleted(String name) {
    return '$name deleted';
  }

  @override
  String fltDeleteAdminTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String fltDeleteAdminBody(String who) {
    return 'The login account and its data are deleted permanently. $who can no longer sign in.';
  }

  @override
  String get fltCodeCopied => 'Code copied';

  @override
  String fltDeleteVenueTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get fltDeleteVenueBody =>
      'The venue is deleted from the fleet permanently. This cannot be undone.';

  @override
  String get fltAlreadyPassed => 'Already passed';

  @override
  String get fltTrialEnds => 'Trial ends';

  @override
  String get fltValidUntil => 'Valid until';

  @override
  String fltCutoffTrial(String date) {
    return 'The venue is suspended automatically on $date, the moment the trial runs out.';
  }

  @override
  String fltCutoffPaid(String date) {
    return 'The venue is suspended automatically on $date — 7 days\' grace after the due date.';
  }

  @override
  String get fltEmailInvalid => 'Invalid email format';

  @override
  String get fltPasswordMin => 'At least 6 characters';

  @override
  String get staffErrPinPoolExhausted => 'Every 6-digit PIN is already taken.';

  @override
  String get staffErrPinLength => 'The PIN must be 6 digits.';

  @override
  String get staffErrPinInUse => 'Another staff member already uses this PIN.';

  @override
  String staffErrPinUpdateFailed(String status) {
    return 'Could not change the PIN ($status).';
  }

  @override
  String get staffErrLastAdmin =>
      'At least one active user must keep the “Manage staff” capability.';

  @override
  String get sndSilent => 'Silent';

  @override
  String get sndBell => 'Bell';

  @override
  String get sndClick => 'Click';

  @override
  String get sndCriticalAlarm => 'Critical alarm';

  @override
  String get sndDoorbell => 'Doorbell';

  @override
  String get sndFacilityAlarm => 'Facility alarm';

  @override
  String get sndGameAlarm => 'Game alarm';

  @override
  String get sndHappyBell => 'Happy bell';

  @override
  String get sndHarp => 'Harp';

  @override
  String get sndRemove => 'Remove';

  @override
  String get sndShortAlarm => 'Short alarm';

  @override
  String get sndStart => 'Start';

  @override
  String get meShiftHeld => 'held';

  @override
  String get meShiftSent => 'sent';

  @override
  String get meShiftPrep => 'preparing';

  @override
  String get meShiftCooked => 'cooked';

  @override
  String get meShiftReady => 'ready';

  @override
  String venueHubBadgeMenu(int items, int cats) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items items',
      one: '1 item',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cats,
      locale: localeName,
      other: '$cats categories',
      one: '1 category',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String venueHubBadgeStockLow(int n) {
    return '$n low';
  }

  @override
  String venueHubBadgeStockOk(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ingredients',
      one: '1 ingredient',
    );
    return '$_temp0';
  }

  @override
  String venueHubBadgeVenue(String tax, String svc) {
    return 'Tax $tax% · Service $svc%';
  }

  @override
  String get venueHubLanActive => 'LAN ACTIVE';

  @override
  String get venueHubLanLocal => 'LOCAL';

  @override
  String moneyCompactJt(String v) {
    return 'Rp ${v}M';
  }

  @override
  String moneyCompactRb(String v) {
    return 'Rp ${v}K';
  }

  @override
  String moneyCompactPlain(String v) {
    return 'Rp $v';
  }

  @override
  String get memTitle => 'Members';

  @override
  String memCount(int count) {
    return 'Enrolled: $count';
  }

  @override
  String get memSearchHint => 'Search name or number';

  @override
  String get memActionAdd => 'Add';

  @override
  String get memBirthdayFilter => 'Birthdays this month';

  @override
  String get memEmptyTitle => 'No members yet';

  @override
  String get memEmptyBody =>
      'Enrol a regular with the Add button, or from the bill screen while they pay.';

  @override
  String get memOffTitle => 'Membership is off';

  @override
  String get memOffBody =>
      'Turn it on in Venue settings → Membership. Points and stamps already recorded stay intact.';

  @override
  String get memPhoneOnly =>
      'Open this on a tablet. A directory is read row against row, and a phone shows one.';

  @override
  String memPoints(int points) {
    return '$points pt';
  }

  @override
  String memPunch(int progress, int target) {
    return 'Stamps $progress/$target';
  }

  @override
  String get memRewardDue => 'Reward due';

  @override
  String memVisits(int count) {
    return 'Visits: $count';
  }

  @override
  String get memColPoints => 'Points';

  @override
  String get memColPunch => 'Stamps';

  @override
  String get memColVisits => 'Visits';

  @override
  String get memColLifetime => 'Lifetime spend';

  @override
  String get memColJoined => 'Joined';

  @override
  String get memLedgerTitle => 'Point history';

  @override
  String get memLedgerLoading => 'Loading history…';

  @override
  String get memLedgerEmpty => 'No point movements yet.';

  @override
  String get memSheetAddTitle => 'New member';

  @override
  String get memSheetEditTitle => 'Edit member';

  @override
  String get memFieldName => 'Name';

  @override
  String get memFieldPhone => 'Phone number';

  @override
  String get memPhoneHelp =>
      'The phone number is the identity. 0812…, +62812… and 62812… are one person.';

  @override
  String get memFieldNote => 'Note';

  @override
  String get memFieldBirthday => 'Birthday';

  @override
  String get memPickBirthday => 'Pick a birth date';

  @override
  String get memSave => 'Save';

  @override
  String get memActionEdit => 'Edit';

  @override
  String get memActionAdjust => 'Correct points';

  @override
  String get memActionMerge => 'Merge';

  @override
  String get memActionDelete => 'Delete';

  @override
  String get memAdjustTitle => 'Correct points';

  @override
  String get memAdjustAdd => 'Add';

  @override
  String get memAdjustSubtract => 'Subtract';

  @override
  String get memFieldDelta => 'Point amount';

  @override
  String get memFieldReason => 'Reason';

  @override
  String get memMergeTitle => 'Merge members';

  @override
  String memMergeBody(String name) {
    return '$name will be folded into the member you pick. Their points and history move across, then their record is dropped.';
  }

  @override
  String get memDeleteTitle => 'Delete member?';

  @override
  String memDeleteBody(String name) {
    return '$name and their point history are gone for good. The trade they did still counts in reports.';
  }

  @override
  String get memErrNameRequired => 'A name is required.';

  @override
  String get memErrPhoneRequired => 'A phone number is required.';

  @override
  String get memErrPhoneTaken => 'Another member already uses this number.';

  @override
  String get memErrNotFound => 'Member not found.';

  @override
  String get memErrSameMember => 'Pick a different member.';

  @override
  String get memErrReasonRequired => 'A reason is required.';

  @override
  String get memErrInvalidAmount => 'Invalid amount.';

  @override
  String get memErrPointsOff => 'Points are frozen.';

  @override
  String memErrBelowMin(int points) {
    return 'Redemption starts at $points.';
  }

  @override
  String memErrInsufficient(int points) {
    return 'Only $points available.';
  }

  @override
  String memErrExceedsBill(int points) {
    return 'This bill takes at most $points pt.';
  }

  @override
  String get memErrRedeemExists => 'This bill already has a redemption.';

  @override
  String memErrFailed(String code) {
    return 'Failed: $code';
  }

  @override
  String get memPointKindEarn => 'Earned';

  @override
  String get memPointKindRedeem => 'Redeemed';

  @override
  String get memPointKindAdjust => 'Correction';

  @override
  String get memPointKindReversal => 'Reversed';

  @override
  String get memHubSubtitle => 'Points, stamps and the regulars list';

  @override
  String get memHubBadgeOn => 'On';

  @override
  String get memHubBadgeOff => 'Off';

  @override
  String get vstSectionMembers => 'Membership';

  @override
  String get vstMembersTag => 'Program';

  @override
  String get vstMembersEnable => 'Enable membership';

  @override
  String get vstMembersEnableHint =>
      'The member directory, points and stamps. Leave off if the venue runs no loyalty program.';

  @override
  String get vstMembersPoints => 'Points';

  @override
  String get vstMembersPointsHint =>
      'Turning this off freezes points rather than clearing them — balances stay intact.';

  @override
  String get vstMembersEarnRate => 'Points per Rp 1,000';

  @override
  String get vstMembersEarnRateHint =>
      'Computed on the net bill, before service and tax.';

  @override
  String get vstMembersPointValue => 'What 1 point is worth';

  @override
  String get vstMembersPointValueHint =>
      'How much comes off the bill for one point redeemed.';

  @override
  String get vstMembersRedeemMin => 'Minimum redemption';

  @override
  String get vstMembersRedeemMinHint => 'The floor on a single redemption.';

  @override
  String get vstMembersPunch => 'Punch card';

  @override
  String get vstMembersPunchHint =>
      'Buy so many, get one free. The reward is booked as a comp.';

  @override
  String get vstMembersPunchItem => 'Item being stamped';

  @override
  String get vstMembersPunchItemNone => 'Not chosen yet';

  @override
  String get vstMembersPunchTarget => 'Stamps per reward';

  @override
  String get vstMembersPunchTargetHint =>
      'How many are bought before the next one is free.';

  @override
  String get vstMembersPreset => 'Member discount';

  @override
  String get vstMembersPresetNone => 'No standing discount';

  @override
  String get vstMembersPresetHint =>
      'The bill discount preset applied automatically the moment a member is attached to a bill.';

  @override
  String get cshMemberNone => 'No member on this bill';

  @override
  String get cshMemberFind => 'Find member';

  @override
  String get cshMemberEnrol => 'Enrol someone new';

  @override
  String get cshMemberDetach => 'Detach';

  @override
  String get cshMemberRedeem => 'Redeem points';

  @override
  String cshMemberRedeemUndo(String amount) {
    return 'Undo redemption ($amount)';
  }

  @override
  String cshMemberRedeemMax(int points) {
    return 'This bill takes at most $points pt.';
  }

  @override
  String cshMemberRedeemWorth(String amount) {
    return 'Takes $amount off';
  }

  @override
  String get cshMemberRedeemAll => 'Redeem the lot';

  @override
  String get pinManualConnectBtn => 'Connect manually';

  @override
  String get pinManualEntryTitle => 'Connect Manually';

  @override
  String get pinManualEntryDescription =>
      'Enter the server\'s IP address and port to connect manually if not auto-detected.';

  @override
  String get pinManualEntryLabel => 'SERVER IP ADDRESS';

  @override
  String get pinManualEntryEmpty => 'IP address cannot be empty';

  @override
  String get pinManualEntryNotFound =>
      'Cannot connect to server. Check IP address and Wi-Fi.';

  @override
  String get rptSecJamKerja => 'Hours';

  @override
  String rptJamKerjaSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n staff',
      one: '1 staff',
    );
    return '$_temp0 · from closed shifts';
  }

  @override
  String get rptJamEmpty => 'No shifts recorded in this range.';

  @override
  String rptJamHours(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String rptJamDaysShifts(int d, int s) {
    String _temp0 = intl.Intl.pluralLogic(
      d,
      locale: localeName,
      other: '$d days',
      one: '1 day',
    );
    String _temp1 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: '$s shifts',
      one: '1 shift',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String rptJamFirstIn(String clock) {
    return 'in ±$clock';
  }

  @override
  String rptJamUnclosed(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n shifts not closed',
      one: '1 shift not closed',
    );
    return '$_temp0';
  }

  @override
  String rptJamLastSeen(String clock) {
    return 'last activity $clock';
  }

  @override
  String get rptJamUnclosedNote => 'Unclosed shifts count no hours.';
}
