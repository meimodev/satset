import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In id, this message translates to:
  /// **'Tersimpan'**
  String get saved;

  /// No description provided for @delete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get edit;

  /// No description provided for @back.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get back;

  /// No description provided for @close.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In id, this message translates to:
  /// **'Memuat…'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In id, this message translates to:
  /// **'Gagal'**
  String get error;

  /// No description provided for @active.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get inactive;

  /// No description provided for @warning.
  ///
  /// In id, this message translates to:
  /// **'Peringatan'**
  String get warning;

  /// No description provided for @confirm.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In id, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @discardCartTitle.
  ///
  /// In id, this message translates to:
  /// **'Batalkan pesanan ini?'**
  String get discardCartTitle;

  /// Leaving the menu with an unsent cart. ADR-0061.
  ///
  /// In id, this message translates to:
  /// **'{items, plural, =1{1 item belum terkirim akan dihapus.} other{{items} item belum terkirim akan dihapus.}}'**
  String discardCartBody(int items);

  /// No description provided for @discardCartConfirm.
  ///
  /// In id, this message translates to:
  /// **'Ya, batalkan'**
  String get discardCartConfirm;

  /// No description provided for @stepperIncrease.
  ///
  /// In id, this message translates to:
  /// **'Tambah satu'**
  String get stepperIncrease;

  /// No description provided for @stepperDecrease.
  ///
  /// In id, this message translates to:
  /// **'Kurangi satu'**
  String get stepperDecrease;

  /// No description provided for @venueHubTitle.
  ///
  /// In id, this message translates to:
  /// **'Venue'**
  String get venueHubTitle;

  /// No description provided for @venueHubSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi · zona · menu · sistem · staf'**
  String get venueHubSubtitle;

  /// No description provided for @venueHubSectionZona.
  ///
  /// In id, this message translates to:
  /// **'Zona'**
  String get venueHubSectionZona;

  /// No description provided for @venueHubSectionZonaSub.
  ///
  /// In id, this message translates to:
  /// **'Atur zona, meja, dan kapasitas ruangan'**
  String get venueHubSectionZonaSub;

  /// No description provided for @venueHubSectionMenu.
  ///
  /// In id, this message translates to:
  /// **'Menu'**
  String get venueHubSectionMenu;

  /// No description provided for @venueHubSectionMenuSub.
  ///
  /// In id, this message translates to:
  /// **'Kategori, item, modifier, dan harga'**
  String get venueHubSectionMenuSub;

  /// No description provided for @venueHubSectionVenue.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan Venue'**
  String get venueHubSectionVenue;

  /// No description provided for @venueHubSectionVenueSub.
  ///
  /// In id, this message translates to:
  /// **'Profil, lokal, pajak, dan branding struk'**
  String get venueHubSectionVenueSub;

  /// No description provided for @venueHubSectionSystem.
  ///
  /// In id, this message translates to:
  /// **'Sistem'**
  String get venueHubSectionSystem;

  /// No description provided for @venueHubSectionSystemSub.
  ///
  /// In id, this message translates to:
  /// **'Server, jaringan, printer, perangkat'**
  String get venueHubSectionSystemSub;

  /// No description provided for @venueHubSectionStaff.
  ///
  /// In id, this message translates to:
  /// **'Staf'**
  String get venueHubSectionStaff;

  /// No description provided for @venueHubSectionStaffSub.
  ///
  /// In id, this message translates to:
  /// **'Akun, peran, dan PIN tim'**
  String get venueHubSectionStaffSub;

  /// No description provided for @venueHubSectionStock.
  ///
  /// In id, this message translates to:
  /// **'Stok'**
  String get venueHubSectionStock;

  /// No description provided for @venueHubSectionStockSub.
  ///
  /// In id, this message translates to:
  /// **'Bahan, terima barang, opname, dan produksi'**
  String get venueHubSectionStockSub;

  /// No description provided for @venueHubSectionReports.
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get venueHubSectionReports;

  /// No description provided for @venueHubSectionReportsSub.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan shift, penjualan, dan ekspor'**
  String get venueHubSectionReportsSub;

  /// No description provided for @venueHubSectionAlerts.
  ///
  /// In id, this message translates to:
  /// **'Peringatan'**
  String get venueHubSectionAlerts;

  /// No description provided for @venueHubSectionAlertsSub.
  ///
  /// In id, this message translates to:
  /// **'Ambang waktu, suara, dan senyap perangkat'**
  String get venueHubSectionAlertsSub;

  /// No description provided for @venueHubSectionAudit.
  ///
  /// In id, this message translates to:
  /// **'Audit'**
  String get venueHubSectionAudit;

  /// No description provided for @venueHubSectionAuditSub.
  ///
  /// In id, this message translates to:
  /// **'Batal, gratis, diskon, dan ubah pesanan'**
  String get venueHubSectionAuditSub;

  /// No description provided for @auditTitle.
  ///
  /// In id, this message translates to:
  /// **'Catatan audit'**
  String get auditTitle;

  /// No description provided for @auditSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Semua kejadian · jejak lengkap'**
  String get auditSubtitle;

  /// No description provided for @auditTabletOnly.
  ///
  /// In id, this message translates to:
  /// **'Butuh layar tablet'**
  String get auditTabletOnly;

  /// No description provided for @auditTabletOnlyBody.
  ///
  /// In id, this message translates to:
  /// **'Catatan audit menampilkan enam kolom sekaligus supaya bisa dibaca sekilas. Buka dari tablet.'**
  String get auditTabletOnlyBody;

  /// No description provided for @auditTabletOnlyBadge.
  ///
  /// In id, this message translates to:
  /// **'Tablet saja'**
  String get auditTabletOnlyBadge;

  /// No description provided for @auditEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kejadian'**
  String get auditEmpty;

  /// No description provided for @auditEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Pembatalan, gratisan, diskon, refund, dan perubahan pesanan akan tampil di sini.'**
  String get auditEmptyBody;

  /// No description provided for @auditExport.
  ///
  /// In id, this message translates to:
  /// **'Ekspor'**
  String get auditExport;

  /// No description provided for @auditColTime.
  ///
  /// In id, this message translates to:
  /// **'Waktu'**
  String get auditColTime;

  /// No description provided for @auditColType.
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get auditColType;

  /// No description provided for @auditColUser.
  ///
  /// In id, this message translates to:
  /// **'Pengguna'**
  String get auditColUser;

  /// No description provided for @auditColEvent.
  ///
  /// In id, this message translates to:
  /// **'Kejadian'**
  String get auditColEvent;

  /// No description provided for @auditColAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get auditColAmount;

  /// No description provided for @auditColReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan'**
  String get auditColReason;

  /// No description provided for @auditSystemActor.
  ///
  /// In id, this message translates to:
  /// **'Sistem'**
  String get auditSystemActor;

  /// No description provided for @auditWindowToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get auditWindowToday;

  /// No description provided for @auditWindowYesterday.
  ///
  /// In id, this message translates to:
  /// **'Kemarin'**
  String get auditWindowYesterday;

  /// No description provided for @auditWindowWeek.
  ///
  /// In id, this message translates to:
  /// **'7 hari'**
  String get auditWindowWeek;

  /// No description provided for @auditWindowAll.
  ///
  /// In id, this message translates to:
  /// **'Semua waktu'**
  String get auditWindowAll;

  /// No description provided for @auditTypeAll.
  ///
  /// In id, this message translates to:
  /// **'Semua jenis'**
  String get auditTypeAll;

  /// No description provided for @auditTileVoid.
  ///
  /// In id, this message translates to:
  /// **'Pembatalan'**
  String get auditTileVoid;

  /// No description provided for @auditTileComp.
  ///
  /// In id, this message translates to:
  /// **'Gratisan'**
  String get auditTileComp;

  /// No description provided for @auditTileDiscount.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get auditTileDiscount;

  /// No description provided for @auditTileRefund.
  ///
  /// In id, this message translates to:
  /// **'Refund'**
  String get auditTileRefund;

  /// No description provided for @auditTileKilled.
  ///
  /// In id, this message translates to:
  /// **'Stop jual'**
  String get auditTileKilled;

  /// No description provided for @auditTileModify.
  ///
  /// In id, this message translates to:
  /// **'Ubah pesanan'**
  String get auditTileModify;

  /// No description provided for @auditEventCount.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, =1{1 kejadian} other{{n} kejadian}}'**
  String auditEventCount(int n);

  /// No description provided for @auditNewRows.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, =1{1 baru} other{{n} baru}}'**
  String auditNewRows(int n);

  /// No description provided for @auditTypeFire.
  ///
  /// In id, this message translates to:
  /// **'Kirim'**
  String get auditTypeFire;

  /// No description provided for @auditTypeModify.
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get auditTypeModify;

  /// No description provided for @auditTypeVoidItem.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get auditTypeVoidItem;

  /// No description provided for @auditTypeComp.
  ///
  /// In id, this message translates to:
  /// **'Gratis'**
  String get auditTypeComp;

  /// No description provided for @auditTypeTableMoved.
  ///
  /// In id, this message translates to:
  /// **'Pindah'**
  String get auditTypeTableMoved;

  /// No description provided for @auditTypePaymentRecorded.
  ///
  /// In id, this message translates to:
  /// **'Bayar'**
  String get auditTypePaymentRecorded;

  /// No description provided for @auditTypeRefund.
  ///
  /// In id, this message translates to:
  /// **'Refund'**
  String get auditTypeRefund;

  /// No description provided for @auditTypeDiscountApplied.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get auditTypeDiscountApplied;

  /// No description provided for @auditTypeDiscountRemoved.
  ///
  /// In id, this message translates to:
  /// **'Diskon−'**
  String get auditTypeDiscountRemoved;

  /// No description provided for @auditTypeBillReopened.
  ///
  /// In id, this message translates to:
  /// **'Buka'**
  String get auditTypeBillReopened;

  /// No description provided for @auditTypeBillClosed.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get auditTypeBillClosed;

  /// No description provided for @auditTypeCashMovement.
  ///
  /// In id, this message translates to:
  /// **'Kas'**
  String get auditTypeCashMovement;

  /// No description provided for @auditTypeMemberChanged.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get auditTypeMemberChanged;

  /// No description provided for @auditTypeStockCounted.
  ///
  /// In id, this message translates to:
  /// **'Opname'**
  String get auditTypeStockCounted;

  /// No description provided for @auditTypeMenuKilled.
  ///
  /// In id, this message translates to:
  /// **'Stop jual'**
  String get auditTypeMenuKilled;

  /// No description provided for @auditTypeMenuRestored.
  ///
  /// In id, this message translates to:
  /// **'Jual lagi'**
  String get auditTypeMenuRestored;

  /// No description provided for @auditTypeStaffCreated.
  ///
  /// In id, this message translates to:
  /// **'Staf +'**
  String get auditTypeStaffCreated;

  /// No description provided for @auditTypeStaffDeleted.
  ///
  /// In id, this message translates to:
  /// **'Staf −'**
  String get auditTypeStaffDeleted;

  /// No description provided for @auditTypeStaffDisabled.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get auditTypeStaffDisabled;

  /// No description provided for @auditTypeStaffEnabled.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get auditTypeStaffEnabled;

  /// No description provided for @auditTypeStaffRoleChanged.
  ///
  /// In id, this message translates to:
  /// **'Peran'**
  String get auditTypeStaffRoleChanged;

  /// No description provided for @auditTypeStaffPinSet.
  ///
  /// In id, this message translates to:
  /// **'PIN'**
  String get auditTypeStaffPinSet;

  /// No description provided for @auditTypeStaffPinReset.
  ///
  /// In id, this message translates to:
  /// **'PIN reset'**
  String get auditTypeStaffPinReset;

  /// No description provided for @auditTypeRoleCreated.
  ///
  /// In id, this message translates to:
  /// **'Peran +'**
  String get auditTypeRoleCreated;

  /// No description provided for @auditTypeRoleRenamed.
  ///
  /// In id, this message translates to:
  /// **'Peran ubah'**
  String get auditTypeRoleRenamed;

  /// No description provided for @auditTypeRoleDeleted.
  ///
  /// In id, this message translates to:
  /// **'Peran −'**
  String get auditTypeRoleDeleted;

  /// No description provided for @auditTypeRoleColorChanged.
  ///
  /// In id, this message translates to:
  /// **'Peran warna'**
  String get auditTypeRoleColorChanged;

  /// No description provided for @auditTypeRoleCapabilityChanged.
  ///
  /// In id, this message translates to:
  /// **'Hak akses'**
  String get auditTypeRoleCapabilityChanged;

  /// No description provided for @killReasonTitle.
  ///
  /// In id, this message translates to:
  /// **'Stop jual'**
  String get killReasonTitle;

  /// No description provided for @killReasonHint.
  ///
  /// In id, this message translates to:
  /// **'Alasan lain (opsional)'**
  String get killReasonHint;

  /// No description provided for @killReasonSkip.
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get killReasonSkip;

  /// No description provided for @killReasonConfirm.
  ///
  /// In id, this message translates to:
  /// **'Stop jual'**
  String get killReasonConfirm;

  /// No description provided for @killReasonBody.
  ///
  /// In id, this message translates to:
  /// **'{item} tidak bisa dipesan sampai diaktifkan lagi. Alasannya masuk catatan audit.'**
  String killReasonBody(String item);

  /// No description provided for @venueHubSeedTitle.
  ///
  /// In id, this message translates to:
  /// **'Mulai cepat'**
  String get venueHubSeedTitle;

  /// No description provided for @venueHubSeedBody.
  ///
  /// In id, this message translates to:
  /// **'Muat contoh data restoran umum: 4 zona dengan 20 meja, menu lengkap, 4 staf (2 pelayan & 2 dapur), dan sebulan riwayat penjualan supaya laporan dan catatan audit langsung terbaca. Semua bisa diubah atau dihapus kapan saja.'**
  String get venueHubSeedBody;

  /// No description provided for @venueHubSeedBodyRunning.
  ///
  /// In id, this message translates to:
  /// **'Menyusun sebulan riwayat lewat jalur pesanan sungguhan. Biarkan aplikasi terbuka sampai selesai.'**
  String get venueHubSeedBodyRunning;

  /// No description provided for @venueHubSeedBodyDone.
  ///
  /// In id, this message translates to:
  /// **'Contoh data siap. Laporan, catatan audit dan riwayat stok sudah terisi.'**
  String get venueHubSeedBodyDone;

  /// No description provided for @venueHubSeedBodyIncomplete.
  ///
  /// In id, this message translates to:
  /// **'Pemuatan contoh data terhenti sebelum selesai. Data yang ada tidak utuh — hapus dulu sebelum memuat ulang.'**
  String get venueHubSeedBodyIncomplete;

  /// No description provided for @venueHubSeedBodyFailed.
  ///
  /// In id, this message translates to:
  /// **'Pemuatan contoh data gagal. Data yang sempat masuk tidak utuh — hapus dulu sebelum mencoba lagi.'**
  String get venueHubSeedBodyFailed;

  /// No description provided for @venueHubSeedBodyLoaded.
  ///
  /// In id, this message translates to:
  /// **'Venue ini memakai contoh data. Hapus untuk membuang riwayat penjualan buatan; zona, meja, menu dan staf tetap ada.'**
  String get venueHubSeedBodyLoaded;

  /// No description provided for @venueHubSeedBtnLoad.
  ///
  /// In id, this message translates to:
  /// **'Muat contoh data'**
  String get venueHubSeedBtnLoad;

  /// No description provided for @venueHubSeedBtnSkip.
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get venueHubSeedBtnSkip;

  /// No description provided for @venueHubSeedBtnClear.
  ///
  /// In id, this message translates to:
  /// **'Hapus contoh data'**
  String get venueHubSeedBtnClear;

  /// No description provided for @venueHubSeedBtnClearRetry.
  ///
  /// In id, this message translates to:
  /// **'Hapus & muat ulang'**
  String get venueHubSeedBtnClearRetry;

  /// No description provided for @venueHubSeedBtnDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get venueHubSeedBtnDone;

  /// No description provided for @venueHubSeedError.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat contoh data'**
  String get venueHubSeedError;

  /// No description provided for @venueHubSeedProgress.
  ///
  /// In id, this message translates to:
  /// **'Menyusun contoh data'**
  String get venueHubSeedProgress;

  /// No description provided for @venueHubSeedDays.
  ///
  /// In id, this message translates to:
  /// **'hari {done}/{total}'**
  String venueHubSeedDays(int done, int total);

  /// No description provided for @settingsSeedTitle.
  ///
  /// In id, this message translates to:
  /// **'Contoh data'**
  String get settingsSeedTitle;

  /// No description provided for @venueSettingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan Venue'**
  String get venueSettingsTitle;

  /// No description provided for @venueSettingsSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Profil, lokal, pajak, struk'**
  String get venueSettingsSubtitle;

  /// No description provided for @venueSettingsSectionIdentity.
  ///
  /// In id, this message translates to:
  /// **'Profil & alamat'**
  String get venueSettingsSectionIdentity;

  /// No description provided for @venueSettingsSectionIdentityTag.
  ///
  /// In id, this message translates to:
  /// **'WAJIB'**
  String get venueSettingsSectionIdentityTag;

  /// No description provided for @venueSettingsDisplayName.
  ///
  /// In id, this message translates to:
  /// **'Nama tampilan'**
  String get venueSettingsDisplayName;

  /// No description provided for @venueSettingsLegalName.
  ///
  /// In id, this message translates to:
  /// **'Nama legal'**
  String get venueSettingsLegalName;

  /// No description provided for @venueSettingsAddress.
  ///
  /// In id, this message translates to:
  /// **'Alamat'**
  String get venueSettingsAddress;

  /// No description provided for @venueSettingsPhone.
  ///
  /// In id, this message translates to:
  /// **'Telepon'**
  String get venueSettingsPhone;

  /// No description provided for @venueSettingsManagedBySuperAdmin.
  ///
  /// In id, this message translates to:
  /// **'Dikelola pengelola'**
  String get venueSettingsManagedBySuperAdmin;

  /// No description provided for @venueSettingsSectionReceipt.
  ///
  /// In id, this message translates to:
  /// **'Branding struk'**
  String get venueSettingsSectionReceipt;

  /// No description provided for @venueSettingsSectionReceiptTag.
  ///
  /// In id, this message translates to:
  /// **'CETAK'**
  String get venueSettingsSectionReceiptTag;

  /// No description provided for @venueSettingsLogo.
  ///
  /// In id, this message translates to:
  /// **'Logo'**
  String get venueSettingsLogo;

  /// No description provided for @venueSettingsLogoAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get venueSettingsLogoAdd;

  /// No description provided for @venueSettingsLogoChange.
  ///
  /// In id, this message translates to:
  /// **'Ganti'**
  String get venueSettingsLogoChange;

  /// No description provided for @venueSettingsLogoDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get venueSettingsLogoDelete;

  /// No description provided for @venueSettingsTagline.
  ///
  /// In id, this message translates to:
  /// **'Tagline'**
  String get venueSettingsTagline;

  /// No description provided for @venueSettingsHeader.
  ///
  /// In id, this message translates to:
  /// **'Header'**
  String get venueSettingsHeader;

  /// No description provided for @venueSettingsSocial.
  ///
  /// In id, this message translates to:
  /// **'Sosial'**
  String get venueSettingsSocial;

  /// No description provided for @venueSettingsFooter.
  ///
  /// In id, this message translates to:
  /// **'Footer'**
  String get venueSettingsFooter;

  /// No description provided for @venueSettingsThankYou.
  ///
  /// In id, this message translates to:
  /// **'Ucapan terima kasih'**
  String get venueSettingsThankYou;

  /// No description provided for @venueSettingsQrUrl.
  ///
  /// In id, this message translates to:
  /// **'QR (URL)'**
  String get venueSettingsQrUrl;

  /// No description provided for @venueSettingsQrCaption.
  ///
  /// In id, this message translates to:
  /// **'QR (keterangan)'**
  String get venueSettingsQrCaption;

  /// No description provided for @venueSettingsSectionTax.
  ///
  /// In id, this message translates to:
  /// **'Pajak & layanan'**
  String get venueSettingsSectionTax;

  /// No description provided for @venueSettingsSectionReports.
  ///
  /// In id, this message translates to:
  /// **'Laporan & shift'**
  String get venueSettingsSectionReports;

  /// No description provided for @venueSettingsSectionSound.
  ///
  /// In id, this message translates to:
  /// **'Suara'**
  String get venueSettingsSectionSound;

  /// No description provided for @venueSettingsSoundNewOrder.
  ///
  /// In id, this message translates to:
  /// **'Pesanan baru'**
  String get venueSettingsSoundNewOrder;

  /// No description provided for @venueSettingsSoundReady.
  ///
  /// In id, this message translates to:
  /// **'Pesanan siap'**
  String get venueSettingsSoundReady;

  /// No description provided for @venueSettingsSoundVoid.
  ///
  /// In id, this message translates to:
  /// **'Void'**
  String get venueSettingsSoundVoid;

  /// No description provided for @venueSettingsSoundOverdue.
  ///
  /// In id, this message translates to:
  /// **'Lewat waktu'**
  String get venueSettingsSoundOverdue;

  /// No description provided for @venueSettingsSoundUngreeted.
  ///
  /// In id, this message translates to:
  /// **'Belum dilayani'**
  String get venueSettingsSoundUngreeted;

  /// No description provided for @venueSettingsSoundPickup.
  ///
  /// In id, this message translates to:
  /// **'Menunggu diantar'**
  String get venueSettingsSoundPickup;

  /// No description provided for @venueSettingsSoundPreview.
  ///
  /// In id, this message translates to:
  /// **'Dengar'**
  String get venueSettingsSoundPreview;

  /// No description provided for @venueSettingsTimingPrepTarget.
  ///
  /// In id, this message translates to:
  /// **'Target siap (default semua menu)'**
  String get venueSettingsTimingPrepTarget;

  /// No description provided for @venueSettingsTimingPrepTargetHint.
  ///
  /// In id, this message translates to:
  /// **'Menu tanpa \"Waktu siap\" sendiri ikut angka ini.'**
  String get venueSettingsTimingPrepTargetHint;

  /// No description provided for @venueSettingsTimingPickup.
  ///
  /// In id, this message translates to:
  /// **'Menunggu diantar'**
  String get venueSettingsTimingPickup;

  /// No description provided for @venueSettingsTimingPickupHint.
  ///
  /// In id, this message translates to:
  /// **'Makanan siap tapi belum diantar selama ini. Saklar mematikan bunyinya saja — tanda di kartu meja tetap jalan.'**
  String get venueSettingsTimingPickupHint;

  /// No description provided for @venueSettingsTimingUngreeted.
  ///
  /// In id, this message translates to:
  /// **'Belum dilayani'**
  String get venueSettingsTimingUngreeted;

  /// No description provided for @venueSettingsTimingUngreetedHint.
  ///
  /// In id, this message translates to:
  /// **'Meja terisi tapi belum ada pesanan terkirim. Saklar mematikan bunyinya saja — tanda di kartu meja tetap jalan.'**
  String get venueSettingsTimingUngreetedHint;

  /// No description provided for @venueSettingsTimingUngreetedEscalate.
  ///
  /// In id, this message translates to:
  /// **'Naik ke semua waiter setelah'**
  String get venueSettingsTimingUngreetedEscalate;

  /// No description provided for @venueSettingsTimingUngreetedEscalateHint.
  ///
  /// In id, this message translates to:
  /// **'Awalnya hanya waiter yang mendudukkan tamu.'**
  String get venueSettingsTimingUngreetedEscalateHint;

  /// No description provided for @venueSettingsTimingLongStay.
  ///
  /// In id, this message translates to:
  /// **'Meja lama'**
  String get venueSettingsTimingLongStay;

  /// No description provided for @venueSettingsTimingLongStayHint.
  ///
  /// In id, this message translates to:
  /// **'Tanda visual di lantai. Tanpa suara.'**
  String get venueSettingsTimingLongStayHint;

  /// No description provided for @venueSettingsTimingIdle.
  ///
  /// In id, this message translates to:
  /// **'Meja selesai makan'**
  String get venueSettingsTimingIdle;

  /// No description provided for @venueSettingsTimingIdleHint.
  ///
  /// In id, this message translates to:
  /// **'Semua terhidang dan tidak ada aktivitas. Tanpa suara.'**
  String get venueSettingsTimingIdleHint;

  /// No description provided for @venueSettingsTimingReservationGrace.
  ///
  /// In id, this message translates to:
  /// **'Toleransi reservasi'**
  String get venueSettingsTimingReservationGrace;

  /// No description provided for @venueSettingsTimingReservationGraceHint.
  ///
  /// In id, this message translates to:
  /// **'Lewat ini chip reservasi ditandai terlambat. Status tidak berubah.'**
  String get venueSettingsTimingReservationGraceHint;

  /// No description provided for @venueSettingsTimingMuteTitle.
  ///
  /// In id, this message translates to:
  /// **'Senyapkan di alat ini'**
  String get venueSettingsTimingMuteTitle;

  /// No description provided for @venueSettingsTimingMuteHint.
  ///
  /// In id, this message translates to:
  /// **'Hanya untuk alat ini. Pilihan nada tetap milik venue.'**
  String get venueSettingsTimingMuteHint;

  /// No description provided for @alertsTitle.
  ///
  /// In id, this message translates to:
  /// **'Peringatan'**
  String get alertsTitle;

  /// No description provided for @alertsSectionThresholds.
  ///
  /// In id, this message translates to:
  /// **'Ambang waktu'**
  String get alertsSectionThresholds;

  /// No description provided for @alertsScopeVenue.
  ///
  /// In id, this message translates to:
  /// **'Semua perangkat'**
  String get alertsScopeVenue;

  /// No description provided for @alertsScopeDevice.
  ///
  /// In id, this message translates to:
  /// **'Hanya perangkat ini'**
  String get alertsScopeDevice;

  /// No description provided for @tableStateUngreeted.
  ///
  /// In id, this message translates to:
  /// **'Belum dilayani'**
  String get tableStateUngreeted;

  /// No description provided for @tableStateIdle.
  ///
  /// In id, this message translates to:
  /// **'Selesai makan'**
  String get tableStateIdle;

  /// No description provided for @reservationLate.
  ///
  /// In id, this message translates to:
  /// **'Terlambat'**
  String get reservationLate;

  /// No description provided for @staleReadyUncollected.
  ///
  /// In id, this message translates to:
  /// **'Siap {mins} mnt — belum diambil'**
  String staleReadyUncollected(int mins);

  /// No description provided for @staleReservationLate.
  ///
  /// In id, this message translates to:
  /// **'Tamu telat {mins} mnt — lepas meja?'**
  String staleReservationLate(int mins);

  /// No description provided for @staleUngreeted.
  ///
  /// In id, this message translates to:
  /// **'Belum disapa {mins} mnt'**
  String staleUngreeted(int mins);

  /// No description provided for @staleIdle.
  ///
  /// In id, this message translates to:
  /// **'Selesai makan {mins} mnt — tawarkan lagi'**
  String staleIdle(int mins);

  /// No description provided for @staleLongStay.
  ///
  /// In id, this message translates to:
  /// **'Duduk {elapsed} — cek penutupan'**
  String staleLongStay(String elapsed);

  /// No description provided for @tableOwnerMine.
  ///
  /// In id, this message translates to:
  /// **'Punya saya'**
  String get tableOwnerMine;

  /// No description provided for @tablePaidFull.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get tablePaidFull;

  /// No description provided for @tablePaidPartial.
  ///
  /// In id, this message translates to:
  /// **'Sebagian'**
  String get tablePaidPartial;

  /// No description provided for @tableNoReservationTable.
  ///
  /// In id, this message translates to:
  /// **'Belum ada meja'**
  String get tableNoReservationTable;

  /// No description provided for @floorReservations.
  ///
  /// In id, this message translates to:
  /// **'Reservasi'**
  String get floorReservations;

  /// No description provided for @floorTakeaway.
  ///
  /// In id, this message translates to:
  /// **'Bawa pulang'**
  String get floorTakeaway;

  /// No description provided for @floorReservationsBook.
  ///
  /// In id, this message translates to:
  /// **'Buku reservasi'**
  String get floorReservationsBook;

  /// No description provided for @floorReservationsLateCount.
  ///
  /// In id, this message translates to:
  /// **'telat'**
  String get floorReservationsLateCount;

  /// No description provided for @reservationFilterWaiting.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get reservationFilterWaiting;

  /// No description provided for @reservationFilterLate.
  ///
  /// In id, this message translates to:
  /// **'Terlambat'**
  String get reservationFilterLate;

  /// No description provided for @reservationFilterSeated.
  ///
  /// In id, this message translates to:
  /// **'Duduk'**
  String get reservationFilterSeated;

  /// No description provided for @reservationFilterNoShow.
  ///
  /// In id, this message translates to:
  /// **'No-show'**
  String get reservationFilterNoShow;

  /// No description provided for @reservationFilterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get reservationFilterAll;

  /// No description provided for @reservationEmptyFilter.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada reservasi di filter ini.'**
  String get reservationEmptyFilter;

  /// No description provided for @reservationActionSeat.
  ///
  /// In id, this message translates to:
  /// **'Dudukkan'**
  String get reservationActionSeat;

  /// No description provided for @reservationActionLate.
  ///
  /// In id, this message translates to:
  /// **'Telat'**
  String get reservationActionLate;

  /// No description provided for @reservationActionNoShow.
  ///
  /// In id, this message translates to:
  /// **'No-show'**
  String get reservationActionNoShow;

  /// No description provided for @reservationActionRestore.
  ///
  /// In id, this message translates to:
  /// **'Pulihkan'**
  String get reservationActionRestore;

  /// No description provided for @takeawayEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pesanan bawa pulang.'**
  String get takeawayEmpty;

  /// No description provided for @zoneAdminTitle.
  ///
  /// In id, this message translates to:
  /// **'Atur Zona'**
  String get zoneAdminTitle;

  /// No description provided for @tablesEmptyZoneAddTableHint.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan meja lewat Manajer › Zona'**
  String get tablesEmptyZoneAddTableHint;

  /// No description provided for @zoneAdminZonePill.
  ///
  /// In id, this message translates to:
  /// **'Zona'**
  String get zoneAdminZonePill;

  /// No description provided for @zoneAdminAddTable.
  ///
  /// In id, this message translates to:
  /// **'Tambah meja'**
  String get zoneAdminAddTable;

  /// No description provided for @zoneAdminAddZone.
  ///
  /// In id, this message translates to:
  /// **'Tambah zona'**
  String get zoneAdminAddZone;

  /// No description provided for @zoneAdminEmptyZone.
  ///
  /// In id, this message translates to:
  /// **'Belum ada meja di'**
  String get zoneAdminEmptyZone;

  /// No description provided for @zoneAdminNoZones.
  ///
  /// In id, this message translates to:
  /// **'Belum ada zona'**
  String get zoneAdminNoZones;

  /// No description provided for @zoneAdminNoZonesCreate.
  ///
  /// In id, this message translates to:
  /// **'Buat zona dulu untuk menata meja.'**
  String get zoneAdminNoZonesCreate;

  /// No description provided for @zoneAdminNoZonesCreateRequest.
  ///
  /// In id, this message translates to:
  /// **'Minta admin untuk membuat zona.'**
  String get zoneAdminNoZonesCreateRequest;

  /// No description provided for @zoneAdminEditTable.
  ///
  /// In id, this message translates to:
  /// **'Atur'**
  String get zoneAdminEditTable;

  /// No description provided for @zoneAdminNewTable.
  ///
  /// In id, this message translates to:
  /// **'Meja baru'**
  String get zoneAdminNewTable;

  /// No description provided for @zoneAdminTableName.
  ///
  /// In id, this message translates to:
  /// **'Nama meja'**
  String get zoneAdminTableName;

  /// No description provided for @zoneAdminMaxCapacity.
  ///
  /// In id, this message translates to:
  /// **'Kapasitas tamu maks'**
  String get zoneAdminMaxCapacity;

  /// No description provided for @zoneAdminTableActive.
  ///
  /// In id, this message translates to:
  /// **'Meja aktif'**
  String get zoneAdminTableActive;

  /// No description provided for @zoneAdminTableActiveSub.
  ///
  /// In id, this message translates to:
  /// **'Matikan untuk perbaikan tanpa menghapus.'**
  String get zoneAdminTableActiveSub;

  /// No description provided for @zoneAdminDeleteTableConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus meja?'**
  String get zoneAdminDeleteTableConfirmTitle;

  /// No description provided for @zoneAdminDeleteTableConfirmSub.
  ///
  /// In id, this message translates to:
  /// **'akan dihapus permanen dari zona.'**
  String get zoneAdminDeleteTableConfirmSub;

  /// No description provided for @tabMeja.
  ///
  /// In id, this message translates to:
  /// **'Meja'**
  String get tabMeja;

  /// No description provided for @tabPesanan.
  ///
  /// In id, this message translates to:
  /// **'Pesanan'**
  String get tabPesanan;

  /// No description provided for @tabAntrian.
  ///
  /// In id, this message translates to:
  /// **'Antrian'**
  String get tabAntrian;

  /// No description provided for @tabKasir.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get tabKasir;

  /// No description provided for @tabVenue.
  ///
  /// In id, this message translates to:
  /// **'Venue'**
  String get tabVenue;

  /// No description provided for @tabSaya.
  ///
  /// In id, this message translates to:
  /// **'Saya'**
  String get tabSaya;

  /// No description provided for @shiftLabel.
  ///
  /// In id, this message translates to:
  /// **'SHIFT'**
  String get shiftLabel;

  /// No description provided for @kasirRiwayatBatas.
  ///
  /// In id, this message translates to:
  /// **'Menampilkan tagihan terbaru. Tagihan lebih lama ada di Laporan.'**
  String get kasirRiwayatBatas;

  /// No description provided for @kitchenQueueTitle.
  ///
  /// In id, this message translates to:
  /// **'Antrian Persiapan'**
  String get kitchenQueueTitle;

  /// No description provided for @hapusPencarian.
  ///
  /// In id, this message translates to:
  /// **'Hapus pencarian'**
  String get hapusPencarian;

  /// No description provided for @takAdaItemCocok.
  ///
  /// In id, this message translates to:
  /// **'Tak ada item cocok'**
  String get takAdaItemCocok;

  /// No description provided for @crumbTambahItem.
  ///
  /// In id, this message translates to:
  /// **'Tambah item'**
  String get crumbTambahItem;

  /// No description provided for @crumbTinjau.
  ///
  /// In id, this message translates to:
  /// **'Tinjau'**
  String get crumbTinjau;

  /// No description provided for @crumbBawaPulang.
  ///
  /// In id, this message translates to:
  /// **'Bawa pulang'**
  String get crumbBawaPulang;

  /// No description provided for @crumbPesananBaru.
  ///
  /// In id, this message translates to:
  /// **'Pesanan baru'**
  String get crumbPesananBaru;

  /// No description provided for @crumbDiskon.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get crumbDiskon;

  /// No description provided for @crumbMenuAdmin.
  ///
  /// In id, this message translates to:
  /// **'Menu admin'**
  String get crumbMenuAdmin;

  /// No description provided for @crumbStafAkun.
  ///
  /// In id, this message translates to:
  /// **'Staf & akun'**
  String get crumbStafAkun;

  /// No description provided for @crumbLaporanShift.
  ///
  /// In id, this message translates to:
  /// **'Laporan shift'**
  String get crumbLaporanShift;

  /// No description provided for @crumbKonfigurasi.
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi'**
  String get crumbKonfigurasi;

  /// No description provided for @themeSheetTitle.
  ///
  /// In id, this message translates to:
  /// **'Tema'**
  String get themeSheetTitle;

  /// No description provided for @themeSheetSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Berlaku untuk perangkat ini saja'**
  String get themeSheetSubtitle;

  /// ADR-0083. Sits beside the theme sheet on /me; same device-local scope.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get localeSheetTitle;

  /// No description provided for @localeSheetSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Berlaku untuk perangkat ini saja'**
  String get localeSheetSubtitle;

  /// No description provided for @localeIndonesian.
  ///
  /// In id, this message translates to:
  /// **'Bahasa Indonesia'**
  String get localeIndonesian;

  /// No description provided for @localeEnglish.
  ///
  /// In id, this message translates to:
  /// **'English'**
  String get localeEnglish;

  /// No description provided for @a11yPickLocale.
  ///
  /// In id, this message translates to:
  /// **'Pilih bahasa'**
  String get a11yPickLocale;

  /// No description provided for @a11yGuestDecrease.
  ///
  /// In id, this message translates to:
  /// **'Kurangi jumlah tamu'**
  String get a11yGuestDecrease;

  /// No description provided for @a11yGuestIncrease.
  ///
  /// In id, this message translates to:
  /// **'Tambah jumlah tamu'**
  String get a11yGuestIncrease;

  /// No description provided for @a11yEdit.
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get a11yEdit;

  /// No description provided for @zoneAdminIcon.
  ///
  /// In id, this message translates to:
  /// **'Ikon zona'**
  String get zoneAdminIcon;

  /// No description provided for @tableGuests.
  ///
  /// In id, this message translates to:
  /// **'Tamu'**
  String get tableGuests;

  /// No description provided for @quantity.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get quantity;

  /// No description provided for @a11yRename.
  ///
  /// In id, this message translates to:
  /// **'Ganti nama'**
  String get a11yRename;

  /// No description provided for @a11yClear.
  ///
  /// In id, this message translates to:
  /// **'Bersihkan'**
  String get a11yClear;

  /// No description provided for @a11yRefresh.
  ///
  /// In id, this message translates to:
  /// **'Muat ulang'**
  String get a11yRefresh;

  /// No description provided for @a11yShowPassword.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan kata sandi'**
  String get a11yShowPassword;

  /// No description provided for @a11yHidePassword.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan kata sandi'**
  String get a11yHidePassword;

  /// No description provided for @a11ySoundPreview.
  ///
  /// In id, this message translates to:
  /// **'Dengar nada'**
  String get a11ySoundPreview;

  /// No description provided for @a11ySoundSilent.
  ///
  /// In id, this message translates to:
  /// **'Tanpa nada'**
  String get a11ySoundSilent;

  /// No description provided for @a11yPickTheme.
  ///
  /// In id, this message translates to:
  /// **'Pilih tema'**
  String get a11yPickTheme;

  /// No description provided for @a11yViewPhoto.
  ///
  /// In id, this message translates to:
  /// **'Lihat foto bukti bayar'**
  String get a11yViewPhoto;

  /// No description provided for @a11yPickColor.
  ///
  /// In id, this message translates to:
  /// **'Pilih warna'**
  String get a11yPickColor;

  /// No description provided for @a11yAddItem.
  ///
  /// In id, this message translates to:
  /// **'Tambah item'**
  String get a11yAddItem;

  /// No description provided for @a11yTableLocked.
  ///
  /// In id, this message translates to:
  /// **'Meja terkunci'**
  String get a11yTableLocked;

  /// Prefilled WhatsApp body. ADR-0059.
  ///
  /// In id, this message translates to:
  /// **'Halo, saya lupa password admin SatSet.\nEmail: {email}\nMohon dibantu reset.'**
  String resetRequestMessage(String email);

  /// No description provided for @resetRequestFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal membuka WhatsApp.'**
  String get resetRequestFailed;

  /// No description provided for @billingRequestMessage.
  ///
  /// In id, this message translates to:
  /// **'Halo, saya mau perpanjang langganan SatSet.\nVenue: {venueName}\nID: {venueId}\nMohon dibantu.'**
  String billingRequestMessage(String venueName, String venueId);

  /// Today is never '0 hari lagi' — zero reads as already past.
  ///
  /// In id, this message translates to:
  /// **'{days, plural, =0{Langganan berakhir hari ini.} =1{Langganan berakhir 1 hari lagi.} other{Langganan berakhir {days} hari lagi.}}'**
  String billingEndsIn(int days);

  /// No description provided for @billingLapsed.
  ///
  /// In id, this message translates to:
  /// **'Masa langganan sudah lewat.'**
  String get billingLapsed;

  /// date is pre-formatted by formatShortDateId — a date, so it localises (ADR-0084).
  ///
  /// In id, this message translates to:
  /// **'Venue berhenti melayani {date}.'**
  String billingStopsOn(String date);

  /// No description provided for @billingCta.
  ///
  /// In id, this message translates to:
  /// **'Ketuk untuk perpanjang lewat WhatsApp.'**
  String get billingCta;

  /// Shell banner on the Main Device only (ADR-0087). Version numbers only — no release notes.
  ///
  /// In id, this message translates to:
  /// **'Versi {latest} tersedia. Perangkat ini di {installed}.'**
  String updateAvailable(String latest, String installed);

  /// No description provided for @updateAction.
  ///
  /// In id, this message translates to:
  /// **'Perbarui'**
  String get updateAction;

  /// No description provided for @updateBlockedTitle.
  ///
  /// In id, this message translates to:
  /// **'Versi ini tidak didukung lagi'**
  String get updateBlockedTitle;

  /// No description provided for @updateBlockedBody.
  ///
  /// In id, this message translates to:
  /// **'Perangkat ini menjalankan versi {installed}. Versi minimum sekarang {min}.'**
  String updateBlockedBody(String installed, String min);

  /// No description provided for @updateBlockedAskAdmin.
  ///
  /// In id, this message translates to:
  /// **'Minta admin memperbarui perangkat ini.'**
  String get updateBlockedAskAdmin;

  /// No description provided for @updateDownloading.
  ///
  /// In id, this message translates to:
  /// **'Mengunduh {percent}%'**
  String updateDownloading(int percent);

  /// No description provided for @updateInstalling.
  ///
  /// In id, this message translates to:
  /// **'Membuka pemasang...'**
  String get updateInstalling;

  /// No description provided for @updateFailed.
  ///
  /// In id, this message translates to:
  /// **'Unduhan gagal. Periksa koneksi lalu coba lagi.'**
  String get updateFailed;

  /// No description provided for @updateRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get updateRetry;

  /// No description provided for @updatePermissionNeeded.
  ///
  /// In id, this message translates to:
  /// **'Izinkan pemasangan aplikasi dari SatSet, lalu coba lagi.'**
  String get updatePermissionNeeded;

  /// No description provided for @fltReleaseGate.
  ///
  /// In id, this message translates to:
  /// **'Gerbang versi'**
  String get fltReleaseGate;

  /// No description provided for @fltReleaseGateHint.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan untuk menghapus batas.'**
  String get fltReleaseGateHint;

  /// No description provided for @fltReleaseGateMin.
  ///
  /// In id, this message translates to:
  /// **'Minimum (wajib)'**
  String get fltReleaseGateMin;

  /// No description provided for @fltReleaseGateRecommended.
  ///
  /// In id, this message translates to:
  /// **'Disarankan'**
  String get fltReleaseGateRecommended;

  /// No description provided for @fltReleaseGateLatest.
  ///
  /// In id, this message translates to:
  /// **'Terbaru'**
  String get fltReleaseGateLatest;

  /// No description provided for @fltReleaseGateInvalid.
  ///
  /// In id, this message translates to:
  /// **'Format harus 1.2.3, dan min <= disarankan <= terbaru.'**
  String get fltReleaseGateInvalid;

  /// No description provided for @bootBlockStale.
  ///
  /// In id, this message translates to:
  /// **'Perlu koneksi internet untuk verifikasi admin. Sambungkan internet lalu masuk lagi.'**
  String get bootBlockStale;

  /// No description provided for @bootBlockIneligible.
  ///
  /// In id, this message translates to:
  /// **'Akses admin dicabut. Hubungi pengelola.'**
  String get bootBlockIneligible;

  /// No description provided for @tempPasswordTitle.
  ///
  /// In id, this message translates to:
  /// **'Ganti sandi'**
  String get tempPasswordTitle;

  /// No description provided for @logout.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get logout;

  /// No description provided for @tempPasswordReason.
  ///
  /// In id, this message translates to:
  /// **'Anda masuk dengan sandi sementara. Buat sandi baru untuk melanjutkan.'**
  String get tempPasswordReason;

  /// No description provided for @tempPasswordNew.
  ///
  /// In id, this message translates to:
  /// **'Sandi baru'**
  String get tempPasswordNew;

  /// No description provided for @tempPasswordConfirm.
  ///
  /// In id, this message translates to:
  /// **'Ulangi sandi baru'**
  String get tempPasswordConfirm;

  /// No description provided for @tempPasswordTooShort.
  ///
  /// In id, this message translates to:
  /// **'{min, plural, =1{Minimal 1 karakter.} other{Minimal {min} karakter.}}'**
  String tempPasswordTooShort(int min);

  /// No description provided for @tempPasswordMismatch.
  ///
  /// In id, this message translates to:
  /// **'Sandi tidak sama.'**
  String get tempPasswordMismatch;

  /// No description provided for @tempPasswordReused.
  ///
  /// In id, this message translates to:
  /// **'Sandi baru tidak boleh sama dengan sandi sementara.'**
  String get tempPasswordReused;

  /// No description provided for @tempPasswordExpired.
  ///
  /// In id, this message translates to:
  /// **'Sandi sementara sudah kadaluarsa. Minta yang baru ke pengelola.'**
  String get tempPasswordExpired;

  /// No description provided for @tempPasswordPending.
  ///
  /// In id, this message translates to:
  /// **'Sandi akun ini baru direset. Masuk dengan sandi sementara untuk menggantinya.'**
  String get tempPasswordPending;

  /// No description provided for @tempPasswordIssuedTitle.
  ///
  /// In id, this message translates to:
  /// **'Sandi sementara'**
  String get tempPasswordIssuedTitle;

  /// No description provided for @tempPasswordIssuedHint.
  ///
  /// In id, this message translates to:
  /// **'Berlaku 24 jam. Sebutkan ke admin venue — mereka wajib mengganti sandi saat masuk.'**
  String get tempPasswordIssuedHint;

  /// No description provided for @tempPasswordIssuedOnce.
  ///
  /// In id, this message translates to:
  /// **'Kode ini hanya muncul sekali.'**
  String get tempPasswordIssuedOnce;

  /// No description provided for @tempPasswordShareMessage.
  ///
  /// In id, this message translates to:
  /// **'Sandi sementara SatSet Anda: {code}\nBerlaku 24 jam. Anda akan diminta membuat sandi baru saat masuk.'**
  String tempPasswordShareMessage(String code);

  /// No description provided for @staffTitle.
  ///
  /// In id, this message translates to:
  /// **'Staf & akun'**
  String get staffTitle;

  /// No description provided for @staffTabPeople.
  ///
  /// In id, this message translates to:
  /// **'Orang'**
  String get staffTabPeople;

  /// No description provided for @staffTabRoles.
  ///
  /// In id, this message translates to:
  /// **'Peran'**
  String get staffTabRoles;

  /// No description provided for @staffSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama'**
  String get staffSearchHint;

  /// No description provided for @staffFilterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get staffFilterAll;

  /// No description provided for @staffAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah staf'**
  String get staffAdd;

  /// No description provided for @staffAddPill.
  ///
  /// In id, this message translates to:
  /// **'+ Tambah staf'**
  String get staffAddPill;

  /// No description provided for @staffEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada staf yang cocok dengan filter ini'**
  String get staffEmpty;

  /// No description provided for @staffNewRolePill.
  ///
  /// In id, this message translates to:
  /// **'+ Peran baru'**
  String get staffNewRolePill;

  /// No description provided for @staffRoleBadgeAdmin.
  ///
  /// In id, this message translates to:
  /// **'ADMIN'**
  String get staffRoleBadgeAdmin;

  /// No description provided for @staffRoleManagedByOperator.
  ///
  /// In id, this message translates to:
  /// **'Dikelola pengelola'**
  String get staffRoleManagedByOperator;

  /// No description provided for @staffRoleColor.
  ///
  /// In id, this message translates to:
  /// **'Warna peran'**
  String get staffRoleColor;

  /// No description provided for @staffColor.
  ///
  /// In id, this message translates to:
  /// **'Warna'**
  String get staffColor;

  /// No description provided for @staffAvatarColor.
  ///
  /// In id, this message translates to:
  /// **'Warna avatar'**
  String get staffAvatarColor;

  /// No description provided for @staffRolePermsHint.
  ///
  /// In id, this message translates to:
  /// **'Ketuk peran untuk mengatur izinnya.'**
  String get staffRolePermsHint;

  /// No description provided for @staffRoleLockedBanner.
  ///
  /// In id, this message translates to:
  /// **'Peran admin dikelola pengelola. Izinnya bisa dilihat, tidak bisa diubah.'**
  String get staffRoleLockedBanner;

  /// No description provided for @staffCapAdminOnly.
  ///
  /// In id, this message translates to:
  /// **'Hanya bisa diberikan lewat pengelola, bukan dari layar ini.'**
  String get staffCapAdminOnly;

  /// No description provided for @staffRole.
  ///
  /// In id, this message translates to:
  /// **'Peran'**
  String get staffRole;

  /// No description provided for @staffNoRole.
  ///
  /// In id, this message translates to:
  /// **'Tanpa peran'**
  String get staffNoRole;

  /// No description provided for @staffName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get staffName;

  /// No description provided for @staffFullName.
  ///
  /// In id, this message translates to:
  /// **'Nama lengkap'**
  String get staffFullName;

  /// No description provided for @staffPinField.
  ///
  /// In id, this message translates to:
  /// **'PIN (6 digit, unik)'**
  String get staffPinField;

  /// No description provided for @staffPinReset.
  ///
  /// In id, this message translates to:
  /// **'Atur ulang'**
  String get staffPinReset;

  /// No description provided for @staffPinUpdated.
  ///
  /// In id, this message translates to:
  /// **'PIN diperbarui'**
  String get staffPinUpdated;

  /// No description provided for @staffSaveChanges.
  ///
  /// In id, this message translates to:
  /// **'Simpan perubahan'**
  String get staffSaveChanges;

  /// No description provided for @staffNewRoleName.
  ///
  /// In id, this message translates to:
  /// **'Nama peran baru'**
  String get staffNewRoleName;

  /// No description provided for @staffRenameRole.
  ///
  /// In id, this message translates to:
  /// **'Ganti nama peran'**
  String get staffRenameRole;

  /// No description provided for @staffDisable.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan'**
  String get staffDisable;

  /// No description provided for @staffErrNameEmpty.
  ///
  /// In id, this message translates to:
  /// **'Nama tidak boleh kosong'**
  String get staffErrNameEmpty;

  /// No description provided for @staffErrAdminBySuperOnly.
  ///
  /// In id, this message translates to:
  /// **'Peran admin hanya bisa dibuat oleh super admin'**
  String get staffErrAdminBySuperOnly;

  /// No description provided for @staffErrAdminPromoteBlocked.
  ///
  /// In id, this message translates to:
  /// **'Menaikkan ke peran admin tidak bisa dari sini'**
  String get staffErrAdminPromoteBlocked;

  /// No description provided for @staffErrNeedNonAdminRole.
  ///
  /// In id, this message translates to:
  /// **'Buat peran non-admin dulu'**
  String get staffErrNeedNonAdminRole;

  /// No description provided for @staffErrColorTaken.
  ///
  /// In id, this message translates to:
  /// **'Warna avatar sudah dipakai akun lain'**
  String get staffErrColorTaken;

  /// No description provided for @staffErrColorTakenShort.
  ///
  /// In id, this message translates to:
  /// **'Warna juga dipakai akun lain'**
  String get staffErrColorTakenShort;

  /// No description provided for @staffChangeRoleTitle.
  ///
  /// In id, this message translates to:
  /// **'Ganti peran?'**
  String get staffChangeRoleTitle;

  /// No description provided for @staffDisableBody.
  ///
  /// In id, this message translates to:
  /// **'Pengguna tidak bisa masuk lagi. Bisa diaktifkan kembali nanti.'**
  String get staffDisableBody;

  /// No description provided for @staffDeleteBody.
  ///
  /// In id, this message translates to:
  /// **'Akun dihapus permanen. Catatan audit lama tetap ada.'**
  String get staffDeleteBody;

  /// No description provided for @staffDeleteRoleBody.
  ///
  /// In id, this message translates to:
  /// **'Izin yang melekat pada peran ini akan hilang.'**
  String get staffDeleteRoleBody;

  /// No description provided for @staffSubtitle.
  ///
  /// In id, this message translates to:
  /// **'{members, plural, other{{members} anggota}} · {admins, plural, other{{admins} admin}}'**
  String staffSubtitle(int members, int admins);

  /// No description provided for @staffRolesCount.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} peran khusus}}'**
  String staffRolesCount(int n);

  /// No description provided for @staffCapsCount.
  ///
  /// In id, this message translates to:
  /// **'{held}/{total, plural, other{{total} izin}}'**
  String staffCapsCount(int held, int total);

  /// No description provided for @capGrpCount.
  ///
  /// In id, this message translates to:
  /// **'{on}/{total}'**
  String capGrpCount(int on, int total);

  /// No description provided for @staffMembersCount.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} anggota}}'**
  String staffMembersCount(int n);

  /// No description provided for @staffCreated.
  ///
  /// In id, this message translates to:
  /// **'{name} dibuat. PIN: {pin}'**
  String staffCreated(String name, String pin);

  /// No description provided for @staffNewPin.
  ///
  /// In id, this message translates to:
  /// **'PIN baru: {pin}'**
  String staffNewPin(String pin);

  /// No description provided for @staffRoleAdminSuffix.
  ///
  /// In id, this message translates to:
  /// **'{name} (admin)'**
  String staffRoleAdminSuffix(String name);

  /// No description provided for @staffDeleteRoleTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus peran “{name}”?'**
  String staffDeleteRoleTitle(String name);

  /// No description provided for @staffChangeRoleBody.
  ///
  /// In id, this message translates to:
  /// **'Pindahkan {name} ke peran lain. Izin berubah seketika.'**
  String staffChangeRoleBody(String name);

  /// No description provided for @staffDisableTitle.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan {name}?'**
  String staffDisableTitle(String name);

  /// No description provided for @staffDeleteTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus {name}?'**
  String staffDeleteTitle(String name);

  /// No description provided for @payMethodCash.
  ///
  /// In id, this message translates to:
  /// **'Tunai'**
  String get payMethodCash;

  /// No description provided for @payMethodCard.
  ///
  /// In id, this message translates to:
  /// **'Kartu'**
  String get payMethodCard;

  /// No description provided for @payMethodQris.
  ///
  /// In id, this message translates to:
  /// **'QRIS'**
  String get payMethodQris;

  /// No description provided for @payMethodTransfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get payMethodTransfer;

  /// No description provided for @payMethodOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get payMethodOther;

  /// No description provided for @rangeToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get rangeToday;

  /// No description provided for @rangeYesterday.
  ///
  /// In id, this message translates to:
  /// **'Kemarin'**
  String get rangeYesterday;

  /// No description provided for @rangeD7.
  ///
  /// In id, this message translates to:
  /// **'7 hari'**
  String get rangeD7;

  /// No description provided for @rangeD30.
  ///
  /// In id, this message translates to:
  /// **'30 hari'**
  String get rangeD30;

  /// No description provided for @rangeMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan ini'**
  String get rangeMonth;

  /// No description provided for @rangeCustom.
  ///
  /// In id, this message translates to:
  /// **'Khusus'**
  String get rangeCustom;

  /// No description provided for @expPeriod.
  ///
  /// In id, this message translates to:
  /// **'Periode'**
  String get expPeriod;

  /// No description provided for @expRange.
  ///
  /// In id, this message translates to:
  /// **'Rentang'**
  String get expRange;

  /// No description provided for @expGenerated.
  ///
  /// In id, this message translates to:
  /// **'Dibuat'**
  String get expGenerated;

  /// No description provided for @expNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get expNote;

  /// No description provided for @expMetaRange.
  ///
  /// In id, this message translates to:
  /// **'Rentang: {value}'**
  String expMetaRange(String value);

  /// No description provided for @expMetaGenerated.
  ///
  /// In id, this message translates to:
  /// **'Dibuat: {value}'**
  String expMetaGenerated(String value);

  /// Empty state inside a PDF export table.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada data.'**
  String get expNoData;

  /// No description provided for @expPageOf.
  ///
  /// In id, this message translates to:
  /// **'SatSet · Halaman {page}/{total}'**
  String expPageOf(int page, int total);

  /// No description provided for @expAccountingCsvTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan Akuntansi SatSet'**
  String get expAccountingCsvTitle;

  /// No description provided for @expAccountingTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan Akuntansi'**
  String get expAccountingTitle;

  /// No description provided for @expAccountingHeader.
  ///
  /// In id, this message translates to:
  /// **'Laporan Akuntansi · {range}'**
  String expAccountingHeader(String range);

  /// Footnote under the accounting revenue summary. ADR-0032.
  ///
  /// In id, this message translates to:
  /// **'Pajak & service = nilai riil dari sesi terselesaikan (bukan estimasi 18% di layar). Rentang mengikuti aturan yang sama dengan laporan di layar (ADR-0032).'**
  String get expAccountingNote;

  /// No description provided for @expSessionCount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah sesi'**
  String get expSessionCount;

  /// No description provided for @expMetaSessionCount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah sesi: {n}'**
  String expMetaSessionCount(int n);

  /// No description provided for @expRevenueSummary.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan Pendapatan'**
  String get expRevenueSummary;

  /// Left column of a two-column key/value table.
  ///
  /// In id, this message translates to:
  /// **'Pos'**
  String get expColEntry;

  /// No description provided for @expColValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai'**
  String get expColValue;

  /// No description provided for @expGrossSubtotal.
  ///
  /// In id, this message translates to:
  /// **'Bruto (subtotal)'**
  String get expGrossSubtotal;

  /// No description provided for @expVoidCorrection.
  ///
  /// In id, this message translates to:
  /// **'Void / koreksi'**
  String get expVoidCorrection;

  /// No description provided for @expDiscount.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get expDiscount;

  /// No description provided for @expNet.
  ///
  /// In id, this message translates to:
  /// **'Net'**
  String get expNet;

  /// No description provided for @expService.
  ///
  /// In id, this message translates to:
  /// **'Service'**
  String get expService;

  /// No description provided for @expTax.
  ///
  /// In id, this message translates to:
  /// **'Pajak'**
  String get expTax;

  /// No description provided for @expCollectedBilled.
  ///
  /// In id, this message translates to:
  /// **'Terkumpul (tagihan)'**
  String get expCollectedBilled;

  /// No description provided for @expRefund.
  ///
  /// In id, this message translates to:
  /// **'Refund'**
  String get expRefund;

  /// No description provided for @expMethodBreakdown.
  ///
  /// In id, this message translates to:
  /// **'Rincian Metode Bayar'**
  String get expMethodBreakdown;

  /// No description provided for @expColMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode'**
  String get expColMethod;

  /// No description provided for @expColAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get expColAmount;

  /// No description provided for @expColTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get expColTransactions;

  /// No description provided for @expColRefundCount.
  ///
  /// In id, this message translates to:
  /// **'Refund (n)'**
  String get expColRefundCount;

  /// No description provided for @expWriteOffs.
  ///
  /// In id, this message translates to:
  /// **'Void & Refund (write-off)'**
  String get expWriteOffs;

  /// No description provided for @expColReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan'**
  String get expColReason;

  /// No description provided for @expColItem.
  ///
  /// In id, this message translates to:
  /// **'Item'**
  String get expColItem;

  /// No description provided for @expColLost.
  ///
  /// In id, this message translates to:
  /// **'Rugi'**
  String get expColLost;

  /// No description provided for @expDiscountByPreset.
  ///
  /// In id, this message translates to:
  /// **'Diskon per Preset'**
  String get expDiscountByPreset;

  /// No description provided for @expColScope.
  ///
  /// In id, this message translates to:
  /// **'Cakupan'**
  String get expColScope;

  /// No description provided for @expColUsed.
  ///
  /// In id, this message translates to:
  /// **'Dipakai'**
  String get expColUsed;

  /// Discount scope: applies to one bill line. CONTEXT: Diskon (discount).
  ///
  /// In id, this message translates to:
  /// **'Per item'**
  String get expScopeLine;

  /// Discount scope: applies to one receipt. CONTEXT: Diskon (discount).
  ///
  /// In id, this message translates to:
  /// **'Per pesanan'**
  String get expScopeOrder;

  /// No description provided for @expDailyBreakdown.
  ///
  /// In id, this message translates to:
  /// **'Rincian Harian'**
  String get expDailyBreakdown;

  /// No description provided for @expColDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get expColDate;

  /// No description provided for @expColGross.
  ///
  /// In id, this message translates to:
  /// **'Bruto'**
  String get expColGross;

  /// No description provided for @expColVoid.
  ///
  /// In id, this message translates to:
  /// **'Void'**
  String get expColVoid;

  /// No description provided for @expColCollected.
  ///
  /// In id, this message translates to:
  /// **'Terkumpul'**
  String get expColCollected;

  /// No description provided for @expReportCsvTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan SatSet'**
  String get expReportCsvTitle;

  /// No description provided for @expReportHeader.
  ///
  /// In id, this message translates to:
  /// **'Laporan SatSet · {range}'**
  String expReportHeader(String range);

  /// No description provided for @expSummary.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan'**
  String get expSummary;

  /// No description provided for @expColMetric.
  ///
  /// In id, this message translates to:
  /// **'Metrik'**
  String get expColMetric;

  /// No description provided for @expColCaption.
  ///
  /// In id, this message translates to:
  /// **'Keterangan'**
  String get expColCaption;

  /// No description provided for @expStaffPerformance.
  ///
  /// In id, this message translates to:
  /// **'Kinerja Staf'**
  String get expStaffPerformance;

  /// No description provided for @expColName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get expColName;

  /// A single seated guest. Stays "Cover" in both languages — CONTEXT: Cover.
  ///
  /// In id, this message translates to:
  /// **'Cover'**
  String get expColCover;

  /// No description provided for @expColAvgBill.
  ///
  /// In id, this message translates to:
  /// **'Rata tagihan'**
  String get expColAvgBill;

  /// No description provided for @expColVoidPct.
  ///
  /// In id, this message translates to:
  /// **'Void %'**
  String get expColVoidPct;

  /// No description provided for @expColSessions.
  ///
  /// In id, this message translates to:
  /// **'Sesi'**
  String get expColSessions;

  /// No description provided for @expTopMenu.
  ///
  /// In id, this message translates to:
  /// **'Menu Terlaris'**
  String get expTopMenu;

  /// No description provided for @expSlowMenu.
  ///
  /// In id, this message translates to:
  /// **'Menu Lambat'**
  String get expSlowMenu;

  /// No description provided for @expColQty.
  ///
  /// In id, this message translates to:
  /// **'Qty'**
  String get expColQty;

  /// No description provided for @expColRevenue.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan'**
  String get expColRevenue;

  /// No description provided for @expColMarginPct.
  ///
  /// In id, this message translates to:
  /// **'Margin %'**
  String get expColMarginPct;

  /// No description provided for @expColMargin.
  ///
  /// In id, this message translates to:
  /// **'Margin'**
  String get expColMargin;

  /// No description provided for @expCategoryMix.
  ///
  /// In id, this message translates to:
  /// **'Komposisi Kategori'**
  String get expCategoryMix;

  /// No description provided for @expColCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get expColCategory;

  /// No description provided for @expColShareThisWeek.
  ///
  /// In id, this message translates to:
  /// **'Porsi minggu ini'**
  String get expColShareThisWeek;

  /// No description provided for @expColShareLastWeek.
  ///
  /// In id, this message translates to:
  /// **'Porsi minggu lalu'**
  String get expColShareLastWeek;

  /// No description provided for @expColThisWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu ini'**
  String get expColThisWeek;

  /// No description provided for @expColLastWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu lalu'**
  String get expColLastWeek;

  /// No description provided for @expHourlySales.
  ///
  /// In id, this message translates to:
  /// **'Penjualan per Jam'**
  String get expHourlySales;

  /// No description provided for @expColHour.
  ///
  /// In id, this message translates to:
  /// **'Jam'**
  String get expColHour;

  /// No description provided for @expDineInVsTakeaway.
  ///
  /// In id, this message translates to:
  /// **'Dine-in vs Bawa Pulang'**
  String get expDineInVsTakeaway;

  /// No description provided for @expDineIn.
  ///
  /// In id, this message translates to:
  /// **'Makan di tempat'**
  String get expDineIn;

  /// CONTEXT: Bawa pulang (Takeaway) — never "Takeout" or "To go".
  ///
  /// In id, this message translates to:
  /// **'Bawa pulang'**
  String get expTakeaway;

  /// No description provided for @expStaffCsvTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan Staf SatSet'**
  String get expStaffCsvTitle;

  /// No description provided for @expStaffTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan Staf'**
  String get expStaffTitle;

  /// No description provided for @expStaffHeader.
  ///
  /// In id, this message translates to:
  /// **'Laporan Staf · {range}'**
  String expStaffHeader(String range);

  /// No description provided for @expColUpsellPct.
  ///
  /// In id, this message translates to:
  /// **'Upsell %'**
  String get expColUpsellPct;

  /// No description provided for @expColVoidCount.
  ///
  /// In id, this message translates to:
  /// **'Void'**
  String get expColVoidCount;

  /// No description provided for @expColLostVoid.
  ///
  /// In id, this message translates to:
  /// **'Lost (void)'**
  String get expColLostVoid;

  /// No description provided for @expColTopReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan teratas'**
  String get expColTopReason;

  /// No description provided for @expTotalRow.
  ///
  /// In id, this message translates to:
  /// **'TOTAL'**
  String get expTotalRow;

  /// No description provided for @expStaffSortNote.
  ///
  /// In id, this message translates to:
  /// **'Diurutkan menurut Net (tertinggi dahulu).'**
  String get expStaffSortNote;

  /// No description provided for @expOrdersCsvTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Pesanan SatSet'**
  String get expOrdersCsvTitle;

  /// No description provided for @expOrdersTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Pesanan'**
  String get expOrdersTitle;

  /// No description provided for @expOrdersHeader.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Pesanan · {range}'**
  String expOrdersHeader(String range);

  /// No description provided for @expVisitCount.
  ///
  /// In id, this message translates to:
  /// **'Total kunjungan'**
  String get expVisitCount;

  /// No description provided for @expLineCount.
  ///
  /// In id, this message translates to:
  /// **'Total baris'**
  String get expLineCount;

  /// No description provided for @expVisitSection.
  ///
  /// In id, this message translates to:
  /// **'KUNJUNGAN'**
  String get expVisitSection;

  /// CONTEXT: Party / partySize — "Pax" in both languages.
  ///
  /// In id, this message translates to:
  /// **'Pax'**
  String get expColPax;

  /// No description provided for @expColWaiter.
  ///
  /// In id, this message translates to:
  /// **'Pelayan'**
  String get expColWaiter;

  /// No description provided for @expColClosed.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get expColClosed;

  /// No description provided for @expColTime.
  ///
  /// In id, this message translates to:
  /// **'Jam'**
  String get expColTime;

  /// No description provided for @expColVariant.
  ///
  /// In id, this message translates to:
  /// **'Varian'**
  String get expColVariant;

  /// No description provided for @expColModifier.
  ///
  /// In id, this message translates to:
  /// **'Modifier'**
  String get expColModifier;

  /// No description provided for @expColCourse.
  ///
  /// In id, this message translates to:
  /// **'Course'**
  String get expColCourse;

  /// No description provided for @expColPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga'**
  String get expColPrice;

  /// No description provided for @expColTotal.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get expColTotal;

  /// No description provided for @expColSubtotal.
  ///
  /// In id, this message translates to:
  /// **'Subtotal'**
  String get expColSubtotal;

  /// No description provided for @expColStatus.
  ///
  /// In id, this message translates to:
  /// **'Status'**
  String get expColStatus;

  /// No description provided for @expColVoidReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan void'**
  String get expColVoidReason;

  /// CONTEXT: Tagihan / Struk pembayaran — pre-payment document.
  ///
  /// In id, this message translates to:
  /// **'TAGIHAN'**
  String get expBillSection;

  /// No description provided for @expColCashier.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get expColCashier;

  /// No description provided for @expColProofPhoto.
  ///
  /// In id, this message translates to:
  /// **'Bukti foto'**
  String get expColProofPhoto;

  /// No description provided for @expYes.
  ///
  /// In id, this message translates to:
  /// **'Ya'**
  String get expYes;

  /// No description provided for @expPresent.
  ///
  /// In id, this message translates to:
  /// **'Ada'**
  String get expPresent;

  /// No description provided for @expTakeawayVisit.
  ///
  /// In id, this message translates to:
  /// **'{label} · Bawa pulang'**
  String expTakeawayVisit(String label);

  /// No description provided for @expTableVisit.
  ///
  /// In id, this message translates to:
  /// **'Meja {label}'**
  String expTableVisit(String label);

  /// CONTEXT: Void (item) — English must say Void, never Cancel.
  ///
  /// In id, this message translates to:
  /// **'Dibatalkan'**
  String get expStatusVoided;

  /// No description provided for @expStatusServed.
  ///
  /// In id, this message translates to:
  /// **'Disajikan'**
  String get expStatusServed;

  /// No description provided for @expStatusReady.
  ///
  /// In id, this message translates to:
  /// **'Siap'**
  String get expStatusReady;

  /// No description provided for @expStatusCooked.
  ///
  /// In id, this message translates to:
  /// **'Dimasak'**
  String get expStatusCooked;

  /// No description provided for @expStatusSent.
  ///
  /// In id, this message translates to:
  /// **'Dikirim'**
  String get expStatusSent;

  /// No description provided for @expStatusHeld.
  ///
  /// In id, this message translates to:
  /// **'Ditahan'**
  String get expStatusHeld;

  /// No description provided for @expVoidedWithReason.
  ///
  /// In id, this message translates to:
  /// **'Batal · {reason}'**
  String expVoidedWithReason(String reason);

  /// No description provided for @expNoVisits.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada kunjungan pada rentang ini.'**
  String get expNoVisits;

  /// No description provided for @expNoPayments.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pembayaran tercatat.'**
  String get expNoPayments;

  /// No description provided for @expBillHeading.
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get expBillHeading;

  /// No description provided for @expMetaVisitLines.
  ///
  /// In id, this message translates to:
  /// **'Kunjungan: {visits}  ·  Baris: {lines}  ·  Net: {net}'**
  String expMetaVisitLines(int visits, int lines, String net);

  /// No description provided for @expVisitMeta.
  ///
  /// In id, this message translates to:
  /// **'Pax {pax}  ·  {waiter}  ·  {closed}'**
  String expVisitMeta(int pax, String waiter, String closed);

  /// The {discount} slot is either empty or the pre-rendered expReceiptDiscountPart.
  ///
  /// In id, this message translates to:
  /// **'Subtotal {subtotal}{discount}  ·  Service {service}  ·  Pajak {tax}  ·  Total {total}'**
  String expReceiptTotals(
    String subtotal,
    String discount,
    String service,
    String tax,
    String total,
  );

  /// No description provided for @expReceiptDiscountPart.
  ///
  /// In id, this message translates to:
  /// **'  ·  Diskon {amount}'**
  String expReceiptDiscountPart(String amount);

  /// The {refund} slot is either empty or expPaymentRefundPart.
  ///
  /// In id, this message translates to:
  /// **'{method}  ·  {cashier}{refund}'**
  String expPaymentActor(String method, String cashier, String refund);

  /// No description provided for @expPaymentRefundPart.
  ///
  /// In id, this message translates to:
  /// **'  ·  Refund'**
  String get expPaymentRefundPart;

  /// No description provided for @expProofCaption.
  ///
  /// In id, this message translates to:
  /// **'Bukti · {method}  ·  {amount}'**
  String expProofCaption(String method, String amount);

  /// No description provided for @expProofMissing.
  ///
  /// In id, this message translates to:
  /// **'Bukti tidak termuat'**
  String get expProofMissing;

  /// Share-sheet subject for the venue audit CSV. ADR-0072.
  ///
  /// In id, this message translates to:
  /// **'Catatan audit'**
  String get expAuditSubject;

  /// One CSV header row, comma-separated. Rendered server-side (ADR-0072).
  ///
  /// In id, this message translates to:
  /// **'Waktu,Jenis,Pengguna,Peran,Kejadian,Meja,Jumlah,Alasan,Disetujui'**
  String get expAuditCsvHeader;

  /// No description provided for @strukTableLine.
  ///
  /// In id, this message translates to:
  /// **'Meja {label}  ·  {pax} org  ·  {time}'**
  String strukTableLine(String label, int pax, String time);

  /// No description provided for @strukGuest.
  ///
  /// In id, this message translates to:
  /// **'Tamu: {name}'**
  String strukGuest(String name);

  /// No description provided for @strukMember.
  ///
  /// In id, this message translates to:
  /// **'Member: {name}'**
  String strukMember(String name);

  /// No description provided for @strukMemberPoints.
  ///
  /// In id, this message translates to:
  /// **'Saldo poin: {points}'**
  String strukMemberPoints(int points);

  /// No description provided for @strukMemberPunch.
  ///
  /// In id, this message translates to:
  /// **'Kartu stempel: {progress}'**
  String strukMemberPunch(String progress);

  /// No description provided for @strukNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan: {note}'**
  String strukNote(String note);

  /// CONTEXT: Struk (cetak struk meja).
  ///
  /// In id, this message translates to:
  /// **'Verifikasi pesanan Anda'**
  String get strukVerify;

  /// Fallback sign-off when the venue has not set its own thank-you line.
  ///
  /// In id, this message translates to:
  /// **'Terima kasih'**
  String get strukThanks;

  /// No description provided for @strukTestTitle.
  ///
  /// In id, this message translates to:
  /// **'TES PRINTER'**
  String get strukTestTitle;

  /// No description provided for @strukTestOk.
  ///
  /// In id, this message translates to:
  /// **'Terhubung OK'**
  String get strukTestOk;

  /// No description provided for @strukBillTitle.
  ///
  /// In id, this message translates to:
  /// **'TAGIHAN'**
  String get strukBillTitle;

  /// No description provided for @strukReceiptTitle.
  ///
  /// In id, this message translates to:
  /// **'STRUK PEMBAYARAN'**
  String get strukReceiptTitle;

  /// No description provided for @strukEvenHeading.
  ///
  /// In id, this message translates to:
  /// **'Patungan meja:'**
  String get strukEvenHeading;

  /// No description provided for @strukBillTotal.
  ///
  /// In id, this message translates to:
  /// **'Total tagihan'**
  String get strukBillTotal;

  /// CONTEXT: Amount receipt.
  ///
  /// In id, this message translates to:
  /// **'Bagian'**
  String get strukPart;

  /// No description provided for @strukSubtotal.
  ///
  /// In id, this message translates to:
  /// **'Subtotal'**
  String get strukSubtotal;

  /// Fallback row label when the applied discount snapshot carries no name.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get strukDiscount;

  /// No description provided for @strukService.
  ///
  /// In id, this message translates to:
  /// **'Layanan'**
  String get strukService;

  /// No description provided for @strukTax.
  ///
  /// In id, this message translates to:
  /// **'Pajak'**
  String get strukTax;

  /// No description provided for @strukTotal.
  ///
  /// In id, this message translates to:
  /// **'TOTAL'**
  String get strukTotal;

  /// No description provided for @strukPaid.
  ///
  /// In id, this message translates to:
  /// **'Bayar {method}'**
  String strukPaid(String method);

  /// No description provided for @strukRefunded.
  ///
  /// In id, this message translates to:
  /// **'Refund {method}'**
  String strukRefunded(String method);

  /// No description provided for @strukCashReceived.
  ///
  /// In id, this message translates to:
  /// **'Tunai diterima'**
  String get strukCashReceived;

  /// No description provided for @strukChange.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get strukChange;

  /// No description provided for @strukOutstanding.
  ///
  /// In id, this message translates to:
  /// **'SISA'**
  String get strukOutstanding;

  /// No description provided for @strukSettled.
  ///
  /// In id, this message translates to:
  /// **'LUNAS'**
  String get strukSettled;

  /// No description provided for @exportKindReport.
  ///
  /// In id, this message translates to:
  /// **'Umum'**
  String get exportKindReport;

  /// No description provided for @exportKindOrders.
  ///
  /// In id, this message translates to:
  /// **'Pesanan'**
  String get exportKindOrders;

  /// No description provided for @exportKindStaff.
  ///
  /// In id, this message translates to:
  /// **'Staf'**
  String get exportKindStaff;

  /// No description provided for @exportKindAccounting.
  ///
  /// In id, this message translates to:
  /// **'Akuntansi'**
  String get exportKindAccounting;

  /// No description provided for @exportTitleReport.
  ///
  /// In id, this message translates to:
  /// **'Ekspor laporan'**
  String get exportTitleReport;

  /// No description provided for @exportTitleOrders.
  ///
  /// In id, this message translates to:
  /// **'Ekspor pesanan'**
  String get exportTitleOrders;

  /// No description provided for @exportTitleStaff.
  ///
  /// In id, this message translates to:
  /// **'Ekspor staf'**
  String get exportTitleStaff;

  /// No description provided for @exportTitleAccounting.
  ///
  /// In id, this message translates to:
  /// **'Ekspor akuntansi'**
  String get exportTitleAccounting;

  /// No description provided for @exportFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengekspor. Coba lagi.'**
  String get exportFailed;

  /// No description provided for @exportKindField.
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get exportKindField;

  /// No description provided for @exportFormatField.
  ///
  /// In id, this message translates to:
  /// **'Format'**
  String get exportFormatField;

  /// No description provided for @exportNoSnapshot.
  ///
  /// In id, this message translates to:
  /// **'Laporan belum siap — buka laporan dulu agar bisa diekspor.'**
  String get exportNoSnapshot;

  /// No description provided for @exportPreparing.
  ///
  /// In id, this message translates to:
  /// **'Menyiapkan…'**
  String get exportPreparing;

  /// No description provided for @exportAction.
  ///
  /// In id, this message translates to:
  /// **'Ekspor {format}'**
  String exportAction(String format);

  /// CONTEXT: Struk (cetak struk meja) — an order slip, never a receipt.
  ///
  /// In id, this message translates to:
  /// **'Cetak struk meja {label}'**
  String printJobOrderSlip(String label);

  /// Post-payment money document. CONTEXT: Tagihan / Struk pembayaran.
  ///
  /// In id, this message translates to:
  /// **'Cetak struk · {who}'**
  String printJobReceiptDoc(String who);

  /// Pre-payment money document. CONTEXT: Tagihan / Struk pembayaran.
  ///
  /// In id, this message translates to:
  /// **'Cetak tagihan · {who}'**
  String printJobBillDoc(String who);

  /// Fallback for "who" when a split receipt carries no letter.
  ///
  /// In id, this message translates to:
  /// **'struk'**
  String get printWhoReceipt;

  /// Course name. Mirrors Courses.drinksNow.
  ///
  /// In id, this message translates to:
  /// **'Minum dulu'**
  String get courseDrinksNow;

  /// No description provided for @courseStarters.
  ///
  /// In id, this message translates to:
  /// **'Pembuka'**
  String get courseStarters;

  /// No description provided for @courseMains.
  ///
  /// In id, this message translates to:
  /// **'Utama'**
  String get courseMains;

  /// Sides plate WITH the mains — never "Sides", which reads as a separate course and is exactly what ADR-0043 says it is not.
  ///
  /// In id, this message translates to:
  /// **'Bersama Utama'**
  String get courseSides;

  /// No description provided for @courseDesserts.
  ///
  /// In id, this message translates to:
  /// **'Penutup'**
  String get courseDesserts;

  /// No description provided for @courseFireNow.
  ///
  /// In id, this message translates to:
  /// **'Langsung'**
  String get courseFireNow;

  /// Audit row: a held course was fired. ADR-0085.
  ///
  /// In id, this message translates to:
  /// **'Course {course} dibakar untuk Meja {table}'**
  String auditFire(String course, String table);

  /// No description provided for @auditModify.
  ///
  /// In id, this message translates to:
  /// **'Ubah {name}'**
  String auditModify(String name);

  /// No description provided for @auditModifyQty.
  ///
  /// In id, this message translates to:
  /// **'Ubah ×{oldQty} → ×{newQty} {name}'**
  String auditModifyQty(String oldQty, String newQty, String name);

  /// No description provided for @auditModifyAtTable.
  ///
  /// In id, this message translates to:
  /// **'{name} diubah di Meja {table}'**
  String auditModifyAtTable(String name, String table);

  /// Void, never "Cancel" — CONTEXT reserves cancel for reservations. {amount} is pre-formatted rupiah (ADR-0084).
  ///
  /// In id, this message translates to:
  /// **'Dibatalkan ×{qty} {name} · {amount}'**
  String auditVoidItem(String qty, String name, String amount);

  /// No description provided for @auditVoidItemAtTable.
  ///
  /// In id, this message translates to:
  /// **'{name} dibatalkan di Meja {table}'**
  String auditVoidItemAtTable(String name, String table);

  /// Comp — a write-off with an approver, never "Free".
  ///
  /// In id, this message translates to:
  /// **'Digratiskan ×{qty} {name} · {amount}'**
  String auditComp(String qty, String name, String amount);

  /// No description provided for @auditTableMoved.
  ///
  /// In id, this message translates to:
  /// **'Pindah meja {src} → {tgt}'**
  String auditTableMoved(String src, String tgt);

  /// {method} arrives already rendered through paymentMethodLabel.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran {amount} ({method}) {label}'**
  String auditPaymentRecorded(String amount, String method, String label);

  /// No description provided for @auditPaymentAtTable.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran {method} Meja {table}'**
  String auditPaymentAtTable(String method, String table);

  /// No description provided for @auditRefund.
  ///
  /// In id, this message translates to:
  /// **'Refund {amount} ({method}) {label}'**
  String auditRefund(String amount, String method, String label);

  /// {name} is the preset's own name — venue content, never translated.
  ///
  /// In id, this message translates to:
  /// **'Diskon {name}'**
  String auditDiscountApplied(String name);

  /// No description provided for @auditDiscountAppliedLine.
  ///
  /// In id, this message translates to:
  /// **'Diskon {name} (item)'**
  String auditDiscountAppliedLine(String name);

  /// No description provided for @auditDiscountRemoved.
  ///
  /// In id, this message translates to:
  /// **'Hapus diskon {name}'**
  String auditDiscountRemoved(String name);

  /// No description provided for @auditDiscountBillApplied.
  ///
  /// In id, this message translates to:
  /// **'Diskon tagihan {name}'**
  String auditDiscountBillApplied(String name);

  /// No description provided for @auditDiscountBillRemoved.
  ///
  /// In id, this message translates to:
  /// **'Hapus diskon tagihan {name}'**
  String auditDiscountBillRemoved(String name);

  /// No description provided for @auditDiscountAtTable.
  ///
  /// In id, this message translates to:
  /// **'Diskon {percent}% di Meja {table}'**
  String auditDiscountAtTable(String percent, String table);

  /// No description provided for @auditBillReopenedReceipt.
  ///
  /// In id, this message translates to:
  /// **'Buka ulang {label}'**
  String auditBillReopenedReceipt(String label);

  /// No description provided for @auditBillReopened.
  ///
  /// In id, this message translates to:
  /// **'Buka ulang tagihan {table}'**
  String auditBillReopened(String table);

  /// No description provided for @auditBillClosed.
  ///
  /// In id, this message translates to:
  /// **'Tutup tagihan {table}'**
  String auditBillClosed(String table);

  /// Tak tertagih · Written off. Never "Cancelled" — the books record a loss.
  ///
  /// In id, this message translates to:
  /// **'Tagihan tak tertagih {amount} {table}'**
  String auditBillWrittenOff(String amount, String table);

  /// No description provided for @auditCashToppedUp.
  ///
  /// In id, this message translates to:
  /// **'Isi kas kecil {amount}'**
  String auditCashToppedUp(String amount);

  /// No description provided for @auditCashSpent.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran kas {amount} — {category}'**
  String auditCashSpent(String amount, String category);

  /// No description provided for @auditCashCounted.
  ///
  /// In id, this message translates to:
  /// **'Opname kas {counted} (selisih {variance})'**
  String auditCashCounted(String counted, String variance);

  /// No description provided for @auditCashReversed.
  ///
  /// In id, this message translates to:
  /// **'Batalkan mutasi kas {amount}'**
  String auditCashReversed(String amount);

  /// No description provided for @auditStockCountClosed.
  ///
  /// In id, this message translates to:
  /// **'Tutup stok opname — {lines, plural, other{{lines} bahan}}, selisih {variance}'**
  String auditStockCountClosed(num lines, String variance);

  /// No description provided for @auditMemberCreated.
  ///
  /// In id, this message translates to:
  /// **'Daftar pelanggan {name}'**
  String auditMemberCreated(String name);

  /// No description provided for @auditMemberDeleted.
  ///
  /// In id, this message translates to:
  /// **'Hapus pelanggan {name}'**
  String auditMemberDeleted(String name);

  /// No description provided for @auditMemberMerged.
  ///
  /// In id, this message translates to:
  /// **'Gabung pelanggan {from} ke {to}'**
  String auditMemberMerged(String from, String to);

  /// No description provided for @auditMemberPointsAdjusted.
  ///
  /// In id, this message translates to:
  /// **'Koreksi poin {name} {points}'**
  String auditMemberPointsAdjusted(String name, String points);

  /// No description provided for @auditMemberPointsRedeemed.
  ///
  /// In id, this message translates to:
  /// **'Tukar {points} poin {name} — {amount}'**
  String auditMemberPointsRedeemed(String name, String points, String amount);

  /// No description provided for @auditMenuKilled.
  ///
  /// In id, this message translates to:
  /// **'Stop jual {name}'**
  String auditMenuKilled(String name);

  /// No description provided for @auditMenuRestored.
  ///
  /// In id, this message translates to:
  /// **'Jual lagi {name}'**
  String auditMenuRestored(String name);

  /// No description provided for @auditStaffCreated.
  ///
  /// In id, this message translates to:
  /// **'{name} dibuat'**
  String auditStaffCreated(String name);

  /// No description provided for @auditStaffDisabled.
  ///
  /// In id, this message translates to:
  /// **'{name} dinonaktifkan'**
  String auditStaffDisabled(String name);

  /// No description provided for @auditStaffEnabled.
  ///
  /// In id, this message translates to:
  /// **'{name} diaktifkan'**
  String auditStaffEnabled(String name);

  /// No description provided for @auditStaffPinSet.
  ///
  /// In id, this message translates to:
  /// **'PIN {name} diubah'**
  String auditStaffPinSet(String name);

  /// No description provided for @auditStaffPinReset.
  ///
  /// In id, this message translates to:
  /// **'PIN {name} direset'**
  String auditStaffPinReset(String name);

  /// No description provided for @auditStaffRoleChanged.
  ///
  /// In id, this message translates to:
  /// **'{name}: {from} → {to}'**
  String auditStaffRoleChanged(String name, String from, String to);

  /// No description provided for @auditRoleCreated.
  ///
  /// In id, this message translates to:
  /// **'Peran {name} dibuat'**
  String auditRoleCreated(String name);

  /// No description provided for @auditRoleDeleted.
  ///
  /// In id, this message translates to:
  /// **'Peran {name} dihapus'**
  String auditRoleDeleted(String name);

  /// No description provided for @auditRoleColorChanged.
  ///
  /// In id, this message translates to:
  /// **'Warna {name} diubah'**
  String auditRoleColorChanged(String name);

  /// No description provided for @auditRoleRenamed.
  ///
  /// In id, this message translates to:
  /// **'Peran: {from} → {to}'**
  String auditRoleRenamed(String from, String to);

  /// {changes} is a +cap,-cap diff of capability identifiers — code, not copy, in both languages.
  ///
  /// In id, this message translates to:
  /// **'{name}: {changes}'**
  String auditRoleCapabilityChanged(String name, String changes);

  /// A receipt with no label of its own.
  ///
  /// In id, this message translates to:
  /// **'Struk'**
  String get receiptDefault;

  /// No description provided for @receiptGuest.
  ///
  /// In id, this message translates to:
  /// **'Tamu {letter}'**
  String receiptGuest(String letter);

  /// An even share (ADR-0068). Composed at read time from the stored "i/n" — never a stored sentence (ADR-0085).
  ///
  /// In id, this message translates to:
  /// **'Bagian {index}/{count}'**
  String receiptPart(String index, String count);

  /// No description provided for @auditStaffDeleted.
  ///
  /// In id, this message translates to:
  /// **'{name} dihapus'**
  String auditStaffDeleted(String name);

  /// Audit row for the ADR-0073 seed. No parameters — the act names itself.
  ///
  /// In id, this message translates to:
  /// **'Memuat contoh data restoran'**
  String get auditSampleDataLoaded;

  /// No description provided for @cshCrumbCashier.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get cshCrumbCashier;

  /// No description provided for @cshCrumbBill.
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get cshCrumbBill;

  /// No description provided for @cshBillTableCrumb.
  ///
  /// In id, this message translates to:
  /// **'Tagihan · Meja {table}'**
  String cshBillTableCrumb(String table);

  /// No description provided for @cshReceiptTableCrumb.
  ///
  /// In id, this message translates to:
  /// **'Struk · Meja {table}'**
  String cshReceiptTableCrumb(String table);

  /// No description provided for @cshLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat tagihan.'**
  String get cshLoadFailed;

  /// No description provided for @cshReceiptLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat struk.'**
  String get cshReceiptLoadFailed;

  /// No description provided for @cshCloseBill.
  ///
  /// In id, this message translates to:
  /// **'Tutup tagihan'**
  String get cshCloseBill;

  /// No description provided for @cshCloseBillBody.
  ///
  /// In id, this message translates to:
  /// **'Kunci tagihan Meja {table} sebagai lunas? Tindakan ini mengakhiri tagihan.'**
  String cshCloseBillBody(String table);

  /// Written off (tak tertagih) — the guest never paid. Not a void and not a discount; see CONTEXT.md.
  ///
  /// In id, this message translates to:
  /// **'Tutup tagihan — tak tertagih'**
  String get cshWriteOffTitle;

  /// No description provided for @cshWriteOffBody.
  ///
  /// In id, this message translates to:
  /// **'Sisa {amount} akan dicatat sebagai kerugian (tak tertagih). Perlu persetujuan manajer.'**
  String cshWriteOffBody(String amount);

  /// No description provided for @cshWriteOffReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan (wajib)'**
  String get cshWriteOffReason;

  /// No description provided for @cshWriteOffReasonHint.
  ///
  /// In id, this message translates to:
  /// **'mis. tamu pergi tanpa bayar'**
  String get cshWriteOffReasonHint;

  /// No description provided for @cshWriteOffConfirm.
  ///
  /// In id, this message translates to:
  /// **'Catat kerugian'**
  String get cshWriteOffConfirm;

  /// No description provided for @cshErrOverAssign.
  ///
  /// In id, this message translates to:
  /// **'Unit melebihi yang tersedia.'**
  String get cshErrOverAssign;

  /// No description provided for @cshErrReceiptPaid.
  ///
  /// In id, this message translates to:
  /// **'Buka ulang struk sebelum mengubahnya.'**
  String get cshErrReceiptPaid;

  /// No description provided for @cshErrNotSettled.
  ///
  /// In id, this message translates to:
  /// **'Tagihan belum lunas.'**
  String get cshErrNotSettled;

  /// No description provided for @cshErrBillLocked.
  ///
  /// In id, this message translates to:
  /// **'Tagihan sudah ditutup — buka ulang dulu.'**
  String get cshErrBillLocked;

  /// No description provided for @cshErrForbidden.
  ///
  /// In id, this message translates to:
  /// **'Perlu persetujuan manajer (tak tertagih).'**
  String get cshErrForbidden;

  /// No description provided for @cshErrReasonRequired.
  ///
  /// In id, this message translates to:
  /// **'Alasan tak tertagih wajib diisi.'**
  String get cshErrReasonRequired;

  /// No description provided for @cshErrNoLines.
  ///
  /// In id, this message translates to:
  /// **'Meja tidak punya pesanan.'**
  String get cshErrNoLines;

  /// No description provided for @cshErrGeneric.
  ///
  /// In id, this message translates to:
  /// **'Operasi gagal ({code}).'**
  String cshErrGeneric(String code);

  /// Section header over the list of receipts on a bill.
  ///
  /// In id, this message translates to:
  /// **'Struk'**
  String get cshReceipts;

  /// No description provided for @cshUnassignedCount.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} item belum diatur ke struk}}'**
  String cshUnassignedCount(int n);

  /// No description provided for @cshSubtotal.
  ///
  /// In id, this message translates to:
  /// **'Subtotal'**
  String get cshSubtotal;

  /// No description provided for @cshDiscount.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get cshDiscount;

  /// No description provided for @cshService.
  ///
  /// In id, this message translates to:
  /// **'Layanan'**
  String get cshService;

  /// No description provided for @cshTax.
  ///
  /// In id, this message translates to:
  /// **'Pajak'**
  String get cshTax;

  /// No description provided for @cshTotal.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get cshTotal;

  /// No description provided for @cshPaidAmount.
  ///
  /// In id, this message translates to:
  /// **'Terbayar'**
  String get cshPaidAmount;

  /// No description provided for @cshOutstanding.
  ///
  /// In id, this message translates to:
  /// **'Sisa'**
  String get cshOutstanding;

  /// No description provided for @cshBatch.
  ///
  /// In id, this message translates to:
  /// **'PESANAN {batch} · {time}'**
  String cshBatch(String batch, String time);

  /// No description provided for @cshOrderItems.
  ///
  /// In id, this message translates to:
  /// **'Item pesanan'**
  String get cshOrderItems;

  /// No description provided for @cshNotAllAssigned.
  ///
  /// In id, this message translates to:
  /// **'Belum semua diatur'**
  String get cshNotAllAssigned;

  /// No description provided for @cshNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan: {note}'**
  String cshNote(String note);

  /// No description provided for @cshUnitDec.
  ///
  /// In id, this message translates to:
  /// **'Kurangi unit'**
  String get cshUnitDec;

  /// No description provided for @cshUnitInc.
  ///
  /// In id, this message translates to:
  /// **'Tambah unit'**
  String get cshUnitInc;

  /// No description provided for @cshPickedOf.
  ///
  /// In id, this message translates to:
  /// **'{picked} dari {free}'**
  String cshPickedOf(int picked, int free);

  /// No description provided for @cshAssign.
  ///
  /// In id, this message translates to:
  /// **'Atur'**
  String get cshAssign;

  /// No description provided for @cshAssignTitle.
  ///
  /// In id, this message translates to:
  /// **'Atur \"{name}\"'**
  String cshAssignTitle(String name);

  /// No description provided for @cshAssignSub.
  ///
  /// In id, this message translates to:
  /// **'{qty, plural, other{{qty} unit}} total · {unassigned} belum diatur'**
  String cshAssignSub(int qty, int unassigned);

  /// No description provided for @cshSettled.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get cshSettled;

  /// No description provided for @cshUnpaid.
  ///
  /// In id, this message translates to:
  /// **'Belum bayar'**
  String get cshUnpaid;

  /// Lower-case, used inside a screen-reader sentence.
  ///
  /// In id, this message translates to:
  /// **'lunas'**
  String get cshStatusSettled;

  /// Lower-case, used inside a screen-reader sentence.
  ///
  /// In id, this message translates to:
  /// **'belum bayar'**
  String get cshStatusUnpaid;

  /// No description provided for @cshPay.
  ///
  /// In id, this message translates to:
  /// **'Bayar'**
  String get cshPay;

  /// No description provided for @cshRefund.
  ///
  /// In id, this message translates to:
  /// **'Refund'**
  String get cshRefund;

  /// No description provided for @cshReopen.
  ///
  /// In id, this message translates to:
  /// **'Buka ulang'**
  String get cshReopen;

  /// No description provided for @cshReopenTitle.
  ///
  /// In id, this message translates to:
  /// **'Buka ulang struk'**
  String get cshReopenTitle;

  /// No description provided for @cshReopenBody.
  ///
  /// In id, this message translates to:
  /// **'Batalkan status lunas \"{receipt}\" agar bisa diubah? Pembayaran tercatat tetap ada.'**
  String cshReopenBody(String receipt);

  /// No description provided for @cshReopenConfirm.
  ///
  /// In id, this message translates to:
  /// **'Ya, buka ulang'**
  String get cshReopenConfirm;

  /// No description provided for @cshRemoveDiscount.
  ///
  /// In id, this message translates to:
  /// **'Hapus diskon'**
  String get cshRemoveDiscount;

  /// No description provided for @cshRemoveDiscountBody.
  ///
  /// In id, this message translates to:
  /// **'Hapus \"{label}\" ({amount}) dari struk ini?'**
  String cshRemoveDiscountBody(String label, String amount);

  /// No description provided for @cshConfirmDelete.
  ///
  /// In id, this message translates to:
  /// **'Ya, hapus'**
  String get cshConfirmDelete;

  /// No description provided for @cshPrintBill.
  ///
  /// In id, this message translates to:
  /// **'Cetak tagihan'**
  String get cshPrintBill;

  /// No description provided for @cshPrintReceipt.
  ///
  /// In id, this message translates to:
  /// **'Cetak struk'**
  String get cshPrintReceipt;

  /// No description provided for @cshDeleteReceiptTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus struk'**
  String get cshDeleteReceiptTitle;

  /// No description provided for @cshDeleteReceiptBody.
  ///
  /// In id, this message translates to:
  /// **'Hapus \"{receipt}\"? Item yang sudah diatur ke struk ini akan kembali belum diatur.'**
  String cshDeleteReceiptBody(String receipt);

  /// No description provided for @cshPhotoFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengambil foto: {error}'**
  String cshPhotoFailed(String error);

  /// No description provided for @cshRefundTitle.
  ///
  /// In id, this message translates to:
  /// **'Refund {receipt}'**
  String cshRefundTitle(String receipt);

  /// No description provided for @cshPayTitle.
  ///
  /// In id, this message translates to:
  /// **'Bayar {receipt}'**
  String cshPayTitle(String receipt);

  /// No description provided for @cshTendered.
  ///
  /// In id, this message translates to:
  /// **'Uang diterima'**
  String get cshTendered;

  /// No description provided for @cshChangeDue.
  ///
  /// In id, this message translates to:
  /// **'Kembalian {amount}'**
  String cshChangeDue(String amount);

  /// No description provided for @cshShortBy.
  ///
  /// In id, this message translates to:
  /// **'Kurang {amount}'**
  String cshShortBy(String amount);

  /// No description provided for @cshProofPhoto.
  ///
  /// In id, this message translates to:
  /// **'Foto bukti (wajib)'**
  String get cshProofPhoto;

  /// No description provided for @cshTakePhoto.
  ///
  /// In id, this message translates to:
  /// **'Ambil foto'**
  String get cshTakePhoto;

  /// No description provided for @cshRetakePhoto.
  ///
  /// In id, this message translates to:
  /// **'Ambil ulang'**
  String get cshRetakePhoto;

  /// No description provided for @cshRecordRefund.
  ///
  /// In id, this message translates to:
  /// **'Catat refund'**
  String get cshRecordRefund;

  /// No description provided for @cshRecordPayment.
  ///
  /// In id, this message translates to:
  /// **'Catat pembayaran'**
  String get cshRecordPayment;

  /// No description provided for @cshEvenSplit.
  ///
  /// In id, this message translates to:
  /// **'Split rata · {count, plural, other{{count} bagian}}'**
  String cshEvenSplit(int count);

  /// No description provided for @cshPerHead.
  ///
  /// In id, this message translates to:
  /// **'{amount} / orang'**
  String cshPerHead(String amount);

  /// No description provided for @cshPaidCount.
  ///
  /// In id, this message translates to:
  /// **'{paid} dari {total} lunas'**
  String cshPaidCount(int paid, int total);

  /// No description provided for @cshPayPart.
  ///
  /// In id, this message translates to:
  /// **'Bayar bagian {index}'**
  String cshPayPart(int index);

  /// No description provided for @cshShareSemantic.
  ///
  /// In id, this message translates to:
  /// **'{receipt}, {status}'**
  String cshShareSemantic(String receipt, String status);

  /// No description provided for @cshPartSemantic.
  ///
  /// In id, this message translates to:
  /// **'Bagian {index}, {status}'**
  String cshPartSemantic(int index, String status);

  /// No description provided for @cshItemCount.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} item}}'**
  String cshItemCount(int n);

  /// No description provided for @cshItemFallback.
  ///
  /// In id, this message translates to:
  /// **'Item'**
  String get cshItemFallback;

  /// No description provided for @cshRemoveLineDiscountTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus diskon item'**
  String get cshRemoveLineDiscountTitle;

  /// No description provided for @cshRemoveLineDiscountBody.
  ///
  /// In id, this message translates to:
  /// **'Hapus \"{label}\" ({amount}) dari {name}?'**
  String cshRemoveLineDiscountBody(String label, String amount, String name);

  /// No description provided for @cshAddReceipt.
  ///
  /// In id, this message translates to:
  /// **'Tambah struk'**
  String get cshAddReceipt;

  /// No description provided for @cshBillWrittenOff.
  ///
  /// In id, this message translates to:
  /// **'Tagihan tak tertagih'**
  String get cshBillWrittenOff;

  /// No description provided for @cshBillSettled.
  ///
  /// In id, this message translates to:
  /// **'Tagihan lunas'**
  String get cshBillSettled;

  /// No description provided for @cshWrittenOffBody.
  ///
  /// In id, this message translates to:
  /// **'{amount} dicatat sebagai kerugian.'**
  String cshWrittenOffBody(String amount);

  /// No description provided for @cshSettledFull.
  ///
  /// In id, this message translates to:
  /// **'{amount} diterima penuh.'**
  String cshSettledFull(String amount);

  /// No description provided for @cshSettledParts.
  ///
  /// In id, this message translates to:
  /// **'{amount} diterima penuh dalam {parts, plural, other{{parts} bagian.}}'**
  String cshSettledParts(String amount, int parts);

  /// No description provided for @cshPrintSettledReceipt.
  ///
  /// In id, this message translates to:
  /// **'Cetak struk lunas'**
  String get cshPrintSettledReceipt;

  /// No description provided for @cshPrintTableReceipt.
  ///
  /// In id, this message translates to:
  /// **'Cetak struk meja'**
  String get cshPrintTableReceipt;

  /// No description provided for @cshPrintTableBill.
  ///
  /// In id, this message translates to:
  /// **'Cetak tagihan meja'**
  String get cshPrintTableBill;

  /// No description provided for @cshWholeBill.
  ///
  /// In id, this message translates to:
  /// **'Seluruh tagihan'**
  String get cshWholeBill;

  /// No description provided for @cshRemoveBillDiscountTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus diskon tagihan'**
  String get cshRemoveBillDiscountTitle;

  /// No description provided for @cshRemoveBillDiscountBody.
  ///
  /// In id, this message translates to:
  /// **'Hapus \"{label}\" ({amount}) dari seluruh tagihan?'**
  String cshRemoveBillDiscountBody(String label, String amount);

  /// No description provided for @cshTableClosedUnpaid.
  ///
  /// In id, this message translates to:
  /// **'Meja sudah ditutup waiter — tagihan belum lunas'**
  String get cshTableClosedUnpaid;

  /// A money amount on the payment sheet — not a count.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get cshAmount;

  /// No description provided for @rptSecSales.
  ///
  /// In id, this message translates to:
  /// **'Penjualan'**
  String get rptSecSales;

  /// No description provided for @rptSecStaff.
  ///
  /// In id, this message translates to:
  /// **'Staf'**
  String get rptSecStaff;

  /// No description provided for @rptSecMenu.
  ///
  /// In id, this message translates to:
  /// **'Menu'**
  String get rptSecMenu;

  /// CONTEXT.md: bahan · Ingredient.
  ///
  /// In id, this message translates to:
  /// **'Bahan'**
  String get rptSecBahan;

  /// No description provided for @rptSecOps.
  ///
  /// In id, this message translates to:
  /// **'Operasi'**
  String get rptSecOps;

  /// No description provided for @rptSecPayments.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get rptSecPayments;

  /// No description provided for @rptUpdating.
  ///
  /// In id, this message translates to:
  /// **'Memperbarui…'**
  String get rptUpdating;

  /// No description provided for @rptStockTitle.
  ///
  /// In id, this message translates to:
  /// **'Bahan & stok'**
  String get rptStockTitle;

  /// CONTEXT.md: opname · Stocktake.
  ///
  /// In id, this message translates to:
  /// **'Pemakaian, terbuang, nilai stok, dan selisih opname'**
  String get rptStockSub;

  /// No description provided for @rptNonCash.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran non-tunai'**
  String get rptNonCash;

  /// No description provided for @rptNonCashSub.
  ///
  /// In id, this message translates to:
  /// **'bukti foto wajib'**
  String get rptNonCashSub;

  /// No description provided for @rptNonCashEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pembayaran non-tunai pada rentang ini.'**
  String get rptNonCashEmpty;

  /// No description provided for @rptTotalOf.
  ///
  /// In id, this message translates to:
  /// **'total {amount}'**
  String rptTotalOf(String amount);

  /// No description provided for @rptProofOnVenue.
  ///
  /// In id, this message translates to:
  /// **'Bukti foto tersedia di perangkat venue.'**
  String get rptProofOnVenue;

  /// No description provided for @rptMethodCount.
  ///
  /// In id, this message translates to:
  /// **'{method} · {count}× · {amount}'**
  String rptMethodCount(String method, int count, String amount);

  /// No description provided for @rptMethodTable.
  ///
  /// In id, this message translates to:
  /// **'{method} · Meja {table}'**
  String rptMethodTable(String method, String table);

  /// No description provided for @rptDineVsTakeaway.
  ///
  /// In id, this message translates to:
  /// **'Dine-in vs Bawa pulang'**
  String get rptDineVsTakeaway;

  /// No description provided for @rptDineIn.
  ///
  /// In id, this message translates to:
  /// **'Dine-in'**
  String get rptDineIn;

  /// No description provided for @rptTakeaway.
  ///
  /// In id, this message translates to:
  /// **'Bawa pulang'**
  String get rptTakeaway;

  /// No description provided for @rptTxCount.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} transaksi}}'**
  String rptTxCount(int n);

  /// No description provided for @rptKpiNet.
  ///
  /// In id, this message translates to:
  /// **'Net'**
  String get rptKpiNet;

  /// No description provided for @rptKpiGross.
  ///
  /// In id, this message translates to:
  /// **'Gross'**
  String get rptKpiGross;

  /// No description provided for @rptKpiTaxService.
  ///
  /// In id, this message translates to:
  /// **'Pajak + Service'**
  String get rptKpiTaxService;

  /// No description provided for @rptKpiVoid.
  ///
  /// In id, this message translates to:
  /// **'Void'**
  String get rptKpiVoid;

  /// No description provided for @rptNoData.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data'**
  String get rptNoData;

  /// No description provided for @rptNoDataDot.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data.'**
  String get rptNoDataDot;

  /// Lower-case, sits under a KPI value.
  ///
  /// In id, this message translates to:
  /// **'belum ada data'**
  String get rptNoDataLower;

  /// No description provided for @rptGuestTrend.
  ///
  /// In id, this message translates to:
  /// **'Tren tamu vs minggu lalu'**
  String get rptGuestTrend;

  /// No description provided for @rptGuestTrendSub.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} tamu}} · {delta}% WoW'**
  String rptGuestTrendSub(int count, String delta);

  /// No description provided for @rptThisWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu ini'**
  String get rptThisWeek;

  /// No description provided for @rptLastWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu lalu'**
  String get rptLastWeek;

  /// No description provided for @rptRevenuePerHour.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan per jam'**
  String get rptRevenuePerHour;

  /// No description provided for @rptPeakHour.
  ///
  /// In id, this message translates to:
  /// **'Puncak {from}:00 — {to}:00'**
  String rptPeakHour(String from, String to);

  /// No description provided for @rptWaiterPerf.
  ///
  /// In id, this message translates to:
  /// **'Performa pelayan'**
  String get rptWaiterPerf;

  /// No description provided for @rptWaiterPerfSub.
  ///
  /// In id, this message translates to:
  /// **'{n} staf · sortir aktif'**
  String rptWaiterPerfSub(int n);

  /// No description provided for @rptNoClosedSessions.
  ///
  /// In id, this message translates to:
  /// **'Belum ada sesi tutup di rentang ini.'**
  String get rptNoClosedSessions;

  /// No description provided for @rptSort.
  ///
  /// In id, this message translates to:
  /// **'Sortir'**
  String get rptSort;

  /// No description provided for @rptSortCovers.
  ///
  /// In id, this message translates to:
  /// **'Meja'**
  String get rptSortCovers;

  /// No description provided for @rptSortVoidPct.
  ///
  /// In id, this message translates to:
  /// **'Void %'**
  String get rptSortVoidPct;

  /// No description provided for @rptSortAvg.
  ///
  /// In id, this message translates to:
  /// **'Avg'**
  String get rptSortAvg;

  /// No description provided for @rptSortNetDesc.
  ///
  /// In id, this message translates to:
  /// **'Net tertinggi'**
  String get rptSortNetDesc;

  /// No description provided for @rptSortMostTables.
  ///
  /// In id, this message translates to:
  /// **'Paling banyak meja'**
  String get rptSortMostTables;

  /// No description provided for @rptSortMostVoids.
  ///
  /// In id, this message translates to:
  /// **'Void terbanyak'**
  String get rptSortMostVoids;

  /// No description provided for @rptSortAvgTicket.
  ///
  /// In id, this message translates to:
  /// **'Avg ticket'**
  String get rptSortAvgTicket;

  /// No description provided for @rptColWaiter.
  ///
  /// In id, this message translates to:
  /// **'PELAYAN'**
  String get rptColWaiter;

  /// No description provided for @rptColTables.
  ///
  /// In id, this message translates to:
  /// **'MEJA'**
  String get rptColTables;

  /// No description provided for @rptColItems.
  ///
  /// In id, this message translates to:
  /// **'ITEM'**
  String get rptColItems;

  /// No description provided for @rptColAvgTicket.
  ///
  /// In id, this message translates to:
  /// **'AVG TICKET'**
  String get rptColAvgTicket;

  /// No description provided for @rptColVoidPct.
  ///
  /// In id, this message translates to:
  /// **'VOID%'**
  String get rptColVoidPct;

  /// No description provided for @rptColNet.
  ///
  /// In id, this message translates to:
  /// **'NET'**
  String get rptColNet;

  /// No description provided for @rptUpsell.
  ///
  /// In id, this message translates to:
  /// **'Indeks upsell pelayan'**
  String get rptUpsell;

  /// No description provided for @rptUpsellSub.
  ///
  /// In id, this message translates to:
  /// **'% sesi dgn starter & main · avg {avg}%'**
  String rptUpsellSub(int avg);

  /// No description provided for @rptTopSellers.
  ///
  /// In id, this message translates to:
  /// **'Top sellers'**
  String get rptTopSellers;

  /// No description provided for @rptSlowMovers.
  ///
  /// In id, this message translates to:
  /// **'Slow movers'**
  String get rptSlowMovers;

  /// No description provided for @rptMenuHighMargin.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} item}} · margin tinggi'**
  String rptMenuHighMargin(int n);

  /// No description provided for @rptMenuSlowStock.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} item}} · stok mengendap'**
  String rptMenuSlowStock(int n);

  /// No description provided for @rptQtyMargin.
  ///
  /// In id, this message translates to:
  /// **'×{qty} · margin {margin}%'**
  String rptQtyMargin(int qty, int margin);

  /// No description provided for @rptAttachRate.
  ///
  /// In id, this message translates to:
  /// **'Attach rate modifier'**
  String get rptAttachRate;

  /// No description provided for @rptAttachRateSub.
  ///
  /// In id, this message translates to:
  /// **'% order pakai modifier'**
  String get rptAttachRateSub;

  /// No description provided for @rptBucketStar.
  ///
  /// In id, this message translates to:
  /// **'LAKU & UNTUNG'**
  String get rptBucketStar;

  /// No description provided for @rptBucketStarAction.
  ///
  /// In id, this message translates to:
  /// **'jaga & sorot'**
  String get rptBucketStarAction;

  /// No description provided for @rptBucketPlow.
  ///
  /// In id, this message translates to:
  /// **'LAKU TAPI TIPIS'**
  String get rptBucketPlow;

  /// No description provided for @rptBucketPlowAction.
  ///
  /// In id, this message translates to:
  /// **'reprice / kurangi porsi'**
  String get rptBucketPlowAction;

  /// No description provided for @rptBucketPuzzle.
  ///
  /// In id, this message translates to:
  /// **'UNTUNG TAPI SEPI'**
  String get rptBucketPuzzle;

  /// No description provided for @rptBucketPuzzleAction.
  ///
  /// In id, this message translates to:
  /// **'promosikan'**
  String get rptBucketPuzzleAction;

  /// No description provided for @rptBucketDog.
  ///
  /// In id, this message translates to:
  /// **'SEPI & TIPIS'**
  String get rptBucketDog;

  /// No description provided for @rptBucketDogAction.
  ///
  /// In id, this message translates to:
  /// **'kandidat dipangkas'**
  String get rptBucketDogAction;

  /// No description provided for @rptMenuClass.
  ///
  /// In id, this message translates to:
  /// **'Klasifikasi menu'**
  String get rptMenuClass;

  /// No description provided for @rptMenuClassSub.
  ///
  /// In id, this message translates to:
  /// **'Populer × margin'**
  String get rptMenuClassSub;

  /// No description provided for @rptBucketAction.
  ///
  /// In id, this message translates to:
  /// **'· {action}'**
  String rptBucketAction(String action);

  /// No description provided for @rptNoItems.
  ///
  /// In id, this message translates to:
  /// **'tidak ada item'**
  String get rptNoItems;

  /// No description provided for @rptPopMargin.
  ///
  /// In id, this message translates to:
  /// **'pop {pop} · margin {margin}%'**
  String rptPopMargin(int pop, int margin);

  /// No description provided for @rptMoreItems.
  ///
  /// In id, this message translates to:
  /// **'+{n} lainnya'**
  String rptMoreItems(int n);

  /// No description provided for @rptCategoryMix.
  ///
  /// In id, this message translates to:
  /// **'Bauran kategori (WoW)'**
  String get rptCategoryMix;

  /// No description provided for @rptCategoryMixSub.
  ///
  /// In id, this message translates to:
  /// **'Bagian pendapatan vs minggu lalu'**
  String get rptCategoryMixSub;

  /// No description provided for @rptColThisWeek.
  ///
  /// In id, this message translates to:
  /// **'MINGGU INI'**
  String get rptColThisWeek;

  /// No description provided for @rptColLastWeek.
  ///
  /// In id, this message translates to:
  /// **'MINGGU LALU'**
  String get rptColLastWeek;

  /// No description provided for @rptBasketPairs.
  ///
  /// In id, this message translates to:
  /// **'Pasangan keranjang'**
  String get rptBasketPairs;

  /// No description provided for @rptBasketPairsSub.
  ///
  /// In id, this message translates to:
  /// **'Item paling sering dipesan bersama'**
  String get rptBasketPairsSub;

  /// No description provided for @rptPairCount.
  ///
  /// In id, this message translates to:
  /// **'{n}× di rentang ini'**
  String rptPairCount(int n);

  /// No description provided for @rptKpiTurnTime.
  ///
  /// In id, this message translates to:
  /// **'Avg turn time'**
  String get rptKpiTurnTime;

  /// No description provided for @rptKpiPrep.
  ///
  /// In id, this message translates to:
  /// **'Prep dapur'**
  String get rptKpiPrep;

  /// No description provided for @rptKpiPickup.
  ///
  /// In id, this message translates to:
  /// **'Tunggu antar'**
  String get rptKpiPickup;

  /// No description provided for @rptKpiReservations.
  ///
  /// In id, this message translates to:
  /// **'Reservasi'**
  String get rptKpiReservations;

  /// No description provided for @rptServiceSpeed.
  ///
  /// In id, this message translates to:
  /// **'Kecepatan layanan'**
  String get rptServiceSpeed;

  /// No description provided for @rptServiceSpeedEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada item siap/disajikan'**
  String get rptServiceSpeedEmpty;

  /// No description provided for @rptServiceSpeedSub.
  ///
  /// In id, this message translates to:
  /// **'Median prep {prep}m · antar {pickup}m · {n, plural, other{{n} item}}'**
  String rptServiceSpeedSub(int prep, int pickup, int n);

  /// No description provided for @rptSlaCourses.
  ///
  /// In id, this message translates to:
  /// **'kursus siap di bawah target masing-masing'**
  String get rptSlaCourses;

  /// No description provided for @rptPickupSla.
  ///
  /// In id, this message translates to:
  /// **'Diantar < {mins}m'**
  String rptPickupSla(int mins);

  /// No description provided for @rptMedianMins.
  ///
  /// In id, this message translates to:
  /// **'median {mins}m'**
  String rptMedianMins(int mins);

  /// No description provided for @rptGreetBreach.
  ///
  /// In id, this message translates to:
  /// **'Telat dilayani > {mins}m'**
  String rptGreetBreach(int mins);

  /// No description provided for @rptGreetSub.
  ///
  /// In id, this message translates to:
  /// **'median {median}m · {n, plural, other{{n} kunjungan}}'**
  String rptGreetSub(int median, int n);

  /// No description provided for @rptSlowestMenu.
  ///
  /// In id, this message translates to:
  /// **'Menu paling lambat (rata-rata prep)'**
  String get rptSlowestMenu;

  /// No description provided for @rptHeatmap.
  ///
  /// In id, this message translates to:
  /// **'Peak-hour heatmap'**
  String get rptHeatmap;

  /// No description provided for @rptHeatmapSub.
  ///
  /// In id, this message translates to:
  /// **'7 hari · jam 11—22'**
  String get rptHeatmapSub;

  /// No description provided for @rptHeatQuiet.
  ///
  /// In id, this message translates to:
  /// **'SEPI'**
  String get rptHeatQuiet;

  /// No description provided for @rptHeatBusy.
  ///
  /// In id, this message translates to:
  /// **'PADAT'**
  String get rptHeatBusy;

  /// No description provided for @rptReservationConv.
  ///
  /// In id, this message translates to:
  /// **'Konversi reservasi'**
  String get rptReservationConv;

  /// No description provided for @rptReservationNoModule.
  ///
  /// In id, this message translates to:
  /// **'Belum ada modul reservasi'**
  String get rptReservationNoModule;

  /// No description provided for @rptReservationNoModuleBody.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan modul reservasi (P3) untuk melihat konversi.'**
  String get rptReservationNoModuleBody;

  /// No description provided for @rptReservationSub.
  ///
  /// In id, this message translates to:
  /// **'{booked} dipesan · {seated} duduk · {noShow} no-show'**
  String rptReservationSub(int booked, int seated, int noShow);

  /// No description provided for @rptSeated.
  ///
  /// In id, this message translates to:
  /// **'Duduk'**
  String get rptSeated;

  /// No description provided for @rptNoShow.
  ///
  /// In id, this message translates to:
  /// **'No-show'**
  String get rptNoShow;

  /// No description provided for @rptCancelled.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get rptCancelled;

  /// No description provided for @rptVoidReasons.
  ///
  /// In id, this message translates to:
  /// **'Alasan void & comp'**
  String get rptVoidReasons;

  /// No description provided for @rptNoVoids.
  ///
  /// In id, this message translates to:
  /// **'Belum ada void'**
  String get rptNoVoids;

  /// No description provided for @rptVoidSub.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} kejadian}} · {amount} hilang'**
  String rptVoidSub(int count, String amount);

  /// No description provided for @rptVoidPerWaiter.
  ///
  /// In id, this message translates to:
  /// **'Void per pelayan'**
  String get rptVoidPerWaiter;

  /// No description provided for @rptTopReason.
  ///
  /// In id, this message translates to:
  /// **'alasan: {reason}'**
  String rptTopReason(String reason);

  /// No description provided for @rptNoSection.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada bagian aktif'**
  String get rptNoSection;

  /// No description provided for @rptNoSectionBody.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan minimal satu tab di atas'**
  String get rptNoSectionBody;

  /// No description provided for @stkDimMass.
  ///
  /// In id, this message translates to:
  /// **'Berat'**
  String get stkDimMass;

  /// No description provided for @stkDimVolume.
  ///
  /// In id, this message translates to:
  /// **'Volume'**
  String get stkDimVolume;

  /// No description provided for @stkDimCount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get stkDimCount;

  /// No description provided for @stkTitle.
  ///
  /// In id, this message translates to:
  /// **'Stok'**
  String get stkTitle;

  /// No description provided for @stkSubOpname.
  ///
  /// In id, this message translates to:
  /// **'Stok opname — hitung fisik'**
  String get stkSubOpname;

  /// No description provided for @stkSub.
  ///
  /// In id, this message translates to:
  /// **'Bahan, penerimaan & mutasi'**
  String get stkSub;

  /// No description provided for @stkAddIngredient.
  ///
  /// In id, this message translates to:
  /// **'Tambah bahan'**
  String get stkAddIngredient;

  /// CONTEXT.md: opname · Stocktake.
  ///
  /// In id, this message translates to:
  /// **'Opname'**
  String get stkOpname;

  /// No description provided for @stkSaveCount.
  ///
  /// In id, this message translates to:
  /// **'Simpan ({n})'**
  String stkSaveCount(int n);

  /// No description provided for @stkLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat stok: {error}'**
  String stkLoadFailed(String error);

  /// No description provided for @stkEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum Ada Bahan'**
  String get stkEmptyTitle;

  /// No description provided for @stkEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan bahan pertama Anda, lalu susun resepnya di editor menu agar stok berkurang otomatis saat pesanan dikirim.'**
  String get stkEmptyBody;

  /// No description provided for @stkNoMatch.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada bahan yang cocok dengan pencarian / filter.'**
  String get stkNoMatch;

  /// No description provided for @stkKpiLow.
  ///
  /// In id, this message translates to:
  /// **'MENIPIS'**
  String get stkKpiLow;

  /// No description provided for @stkCountIngredients.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} Bahan}}'**
  String stkCountIngredients(int n);

  /// No description provided for @stkNeedReorder.
  ///
  /// In id, this message translates to:
  /// **'Perlu reorder'**
  String get stkNeedReorder;

  /// No description provided for @stkStockOk.
  ///
  /// In id, this message translates to:
  /// **'Stok aman'**
  String get stkStockOk;

  /// No description provided for @stkKpiNegative.
  ///
  /// In id, this message translates to:
  /// **'STOK MINUS'**
  String get stkKpiNegative;

  /// No description provided for @stkNeedOpname.
  ///
  /// In id, this message translates to:
  /// **'Perlu opname segera'**
  String get stkNeedOpname;

  /// No description provided for @stkKpiProduced.
  ///
  /// In id, this message translates to:
  /// **'PRODUKSI MANDIRI'**
  String get stkKpiProduced;

  /// No description provided for @stkOfRegistered.
  ///
  /// In id, this message translates to:
  /// **'dari {n, plural, other{{n} bahan terdaftar}}'**
  String stkOfRegistered(int n);

  /// No description provided for @stkCounted.
  ///
  /// In id, this message translates to:
  /// **'Terhitung'**
  String get stkCounted;

  /// No description provided for @stkOpnameStartTitle.
  ///
  /// In id, this message translates to:
  /// **'Mulai stok opname'**
  String get stkOpnameStartTitle;

  /// No description provided for @stkOpnameStartSub.
  ///
  /// In id, this message translates to:
  /// **'Sesi ini akan tersimpan, jadi hitungan Anda tidak hilang kalau layar mati.'**
  String get stkOpnameStartSub;

  /// No description provided for @stkOpnameStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get stkOpnameStart;

  /// No description provided for @stkOpnameScope.
  ///
  /// In id, this message translates to:
  /// **'Cakupan'**
  String get stkOpnameScope;

  /// No description provided for @stkOpnameScopeFull.
  ///
  /// In id, this message translates to:
  /// **'Menyeluruh'**
  String get stkOpnameScopeFull;

  /// No description provided for @stkOpnameScopePartial.
  ///
  /// In id, this message translates to:
  /// **'Sebagian'**
  String get stkOpnameScopePartial;

  /// No description provided for @stkOpnameBlind.
  ///
  /// In id, this message translates to:
  /// **'Hitung buta'**
  String get stkOpnameBlind;

  /// No description provided for @stkOpnameBlindHint.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan stok tercatat selama menghitung. Selisih muncul setelah opname ditutup.'**
  String get stkOpnameBlindHint;

  /// No description provided for @stkOpnameDiscardTitle.
  ///
  /// In id, this message translates to:
  /// **'Buang opname ini?'**
  String get stkOpnameDiscardTitle;

  /// No description provided for @stkOpnameDiscardBody.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} bahan}} yang sudah dihitung akan ikut terbuang. Opname yang belum ditutup tidak mengubah stok.'**
  String stkOpnameDiscardBody(num n);

  /// No description provided for @stkOpnameDiscard.
  ///
  /// In id, this message translates to:
  /// **'Buang'**
  String get stkOpnameDiscard;

  /// No description provided for @stkOpnameIncompleteTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum semua bahan dihitung'**
  String get stkOpnameIncompleteTitle;

  /// No description provided for @stkOpnameIncompleteBody.
  ///
  /// In id, this message translates to:
  /// **'Opname menyeluruh, tapi {n, plural, other{{n} bahan}} belum dihitung. Tutup tetap sebagai menyeluruh?'**
  String stkOpnameIncompleteBody(num n);

  /// No description provided for @stkOpnameCloseAnyway.
  ///
  /// In id, this message translates to:
  /// **'Tutup tetap'**
  String get stkOpnameCloseAnyway;

  /// No description provided for @opnTitle.
  ///
  /// In id, this message translates to:
  /// **'Opname'**
  String get opnTitle;

  /// No description provided for @opnSub.
  ///
  /// In id, this message translates to:
  /// **'Riwayat stok opname — siapa menghitung, kapan, dan setiap barisnya'**
  String get opnSub;

  /// No description provided for @opnRangeDays.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} hari}}'**
  String opnRangeDays(num n);

  /// No description provided for @opnEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada opname'**
  String get opnEmptyTitle;

  /// No description provided for @opnEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Opname dimulai dari layar Stok. Setelah ditutup, dokumennya muncul di sini.'**
  String get opnEmptyBody;

  /// No description provided for @opnPickTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih satu opname'**
  String get opnPickTitle;

  /// No description provided for @opnPickBody.
  ///
  /// In id, this message translates to:
  /// **'Dokumen lengkapnya muncul di sini.'**
  String get opnPickBody;

  /// No description provided for @opnOpenTitle.
  ///
  /// In id, this message translates to:
  /// **'Opname sedang berjalan'**
  String get opnOpenTitle;

  /// No description provided for @opnOpenBody.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} bahan}} sudah dihitung. Belum ada stok yang bergerak sampai ditutup.'**
  String opnOpenBody(num n);

  /// No description provided for @opnTagBlind.
  ///
  /// In id, this message translates to:
  /// **'Buta'**
  String get opnTagBlind;

  /// No description provided for @opnTagSighted.
  ///
  /// In id, this message translates to:
  /// **'Terbuka'**
  String get opnTagSighted;

  /// No description provided for @opnLineCount.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} baris}}'**
  String opnLineCount(num n);

  /// No description provided for @opnDocSub.
  ///
  /// In id, this message translates to:
  /// **'{scope} · {blind}'**
  String opnDocSub(Object scope, Object blind);

  /// No description provided for @opnKpiLines.
  ///
  /// In id, this message translates to:
  /// **'Baris'**
  String get opnKpiLines;

  /// No description provided for @opnKpiExact.
  ///
  /// In id, this message translates to:
  /// **'Cocok'**
  String get opnKpiExact;

  /// No description provided for @opnKpiVariance.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get opnKpiVariance;

  /// No description provided for @opnColItem.
  ///
  /// In id, this message translates to:
  /// **'Bahan'**
  String get opnColItem;

  /// No description provided for @opnColExpected.
  ///
  /// In id, this message translates to:
  /// **'Tercatat'**
  String get opnColExpected;

  /// No description provided for @opnColCounted.
  ///
  /// In id, this message translates to:
  /// **'Dihitung'**
  String get opnColCounted;

  /// No description provided for @opnColVariance.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get opnColVariance;

  /// No description provided for @opnColValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai'**
  String get opnColValue;

  /// No description provided for @opnExact.
  ///
  /// In id, this message translates to:
  /// **'Cocok'**
  String get opnExact;

  /// No description provided for @opnPhoneOnly.
  ///
  /// In id, this message translates to:
  /// **'Dokumen opname dibaca dengan membandingkan barisnya. Buka di tablet.'**
  String get opnPhoneOnly;

  /// No description provided for @opnHubSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat opname dan selisihnya'**
  String get opnHubSubtitle;

  /// No description provided for @opnCsvTitle.
  ///
  /// In id, this message translates to:
  /// **'Stok opname'**
  String get opnCsvTitle;

  /// No description provided for @opnCsvStarted.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get opnCsvStarted;

  /// No description provided for @opnCsvClosed.
  ///
  /// In id, this message translates to:
  /// **'Ditutup'**
  String get opnCsvClosed;

  /// No description provided for @opnCsvMode.
  ///
  /// In id, this message translates to:
  /// **'Cara hitung'**
  String get opnCsvMode;

  /// No description provided for @opnCsvNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get opnCsvNote;

  /// No description provided for @opnPdfHeader.
  ///
  /// In id, this message translates to:
  /// **'Opname {stamp}'**
  String opnPdfHeader(Object stamp);

  /// No description provided for @opnPdfLines.
  ///
  /// In id, this message translates to:
  /// **'Rincian per bahan'**
  String get opnPdfLines;

  /// No description provided for @opnMetaStarted.
  ///
  /// In id, this message translates to:
  /// **'Mulai: {stamp}'**
  String opnMetaStarted(Object stamp);

  /// No description provided for @opnMetaClosed.
  ///
  /// In id, this message translates to:
  /// **'Ditutup: {stamp}'**
  String opnMetaClosed(Object stamp);

  /// No description provided for @opnMetaTally.
  ///
  /// In id, this message translates to:
  /// **'{lines, plural, other{{lines} baris}}, {exact} cocok'**
  String opnMetaTally(num lines, num exact);

  /// No description provided for @opnMetaVariance.
  ///
  /// In id, this message translates to:
  /// **'Selisih: {value}'**
  String opnMetaVariance(Object value);

  /// No description provided for @opnExport.
  ///
  /// In id, this message translates to:
  /// **'Ekspor'**
  String get opnExport;

  /// No description provided for @opnExportSubject.
  ///
  /// In id, this message translates to:
  /// **'Stok opname SatSet'**
  String get opnExportSubject;

  /// No description provided for @stkOpnameMode.
  ///
  /// In id, this message translates to:
  /// **'MODE STOK OPNAME'**
  String get stkOpnameMode;

  /// No description provided for @stkOpnameHint.
  ///
  /// In id, this message translates to:
  /// **'Ketik jumlah fisik di gudang saat ini. Selisih akan otomatis dihitung sebagai penyesuaian mutasi.'**
  String get stkOpnameHint;

  /// No description provided for @stkFilled.
  ///
  /// In id, this message translates to:
  /// **'{n} diisi'**
  String stkFilled(int n);

  /// No description provided for @stkSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama bahan...'**
  String get stkSearchHint;

  /// No description provided for @stkFilterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua ({n})'**
  String stkFilterAll(int n);

  /// No description provided for @stkFilterLow.
  ///
  /// In id, this message translates to:
  /// **'Menipis ({n})'**
  String stkFilterLow(int n);

  /// No description provided for @stkFilterNegative.
  ///
  /// In id, this message translates to:
  /// **'Minus ({n})'**
  String stkFilterNegative(int n);

  /// No description provided for @stkFilterProduced.
  ///
  /// In id, this message translates to:
  /// **'Produksi ({n})'**
  String stkFilterProduced(int n);

  /// No description provided for @stkBadgeProduced.
  ///
  /// In id, this message translates to:
  /// **'PRODUKSI'**
  String get stkBadgeProduced;

  /// No description provided for @stkBadgeLow.
  ///
  /// In id, this message translates to:
  /// **'MENIPIS'**
  String get stkBadgeLow;

  /// No description provided for @stkBadgeNegative.
  ///
  /// In id, this message translates to:
  /// **'MINUS'**
  String get stkBadgeNegative;

  /// No description provided for @stkColOnHand.
  ///
  /// In id, this message translates to:
  /// **'STOK SAAT INI'**
  String get stkColOnHand;

  /// No description provided for @stkColPricePer.
  ///
  /// In id, this message translates to:
  /// **'HARGA / {unit}'**
  String stkColPricePer(String unit);

  /// No description provided for @stkColLastReceived.
  ///
  /// In id, this message translates to:
  /// **'TERAKHIR TERIMA'**
  String get stkColLastReceived;

  /// No description provided for @stkReceive.
  ///
  /// In id, this message translates to:
  /// **'Terima'**
  String get stkReceive;

  /// No description provided for @stkMenuReceive.
  ///
  /// In id, this message translates to:
  /// **'Terima barang'**
  String get stkMenuReceive;

  /// No description provided for @stkMenuProduce.
  ///
  /// In id, this message translates to:
  /// **'Produksi batch'**
  String get stkMenuProduce;

  /// No description provided for @stkMenuLedger.
  ///
  /// In id, this message translates to:
  /// **'Riwayat mutasi'**
  String get stkMenuLedger;

  /// No description provided for @stkMenuEdit.
  ///
  /// In id, this message translates to:
  /// **'Ubah bahan'**
  String get stkMenuEdit;

  /// No description provided for @stkMenuArchive.
  ///
  /// In id, this message translates to:
  /// **'Arsipkan'**
  String get stkMenuArchive;

  /// No description provided for @stkMinThreshold.
  ///
  /// In id, this message translates to:
  /// **'Batas min: {qty}'**
  String stkMinThreshold(String qty);

  /// No description provided for @stkVarianceExact.
  ///
  /// In id, this message translates to:
  /// **'Pas'**
  String get stkVarianceExact;

  /// No description provided for @stkOpnameDoneNoVariance.
  ///
  /// In id, this message translates to:
  /// **'Opname selesai — tidak ada selisih'**
  String get stkOpnameDoneNoVariance;

  /// No description provided for @stkOpnameDone.
  ///
  /// In id, this message translates to:
  /// **'Opname selesai — {n, plural, other{{n} bahan}} disesuaikan'**
  String stkOpnameDone(int n);

  /// No description provided for @stkSaveFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan: {error}'**
  String stkSaveFailed(String error);

  /// No description provided for @stkFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal: {error}'**
  String stkFailed(String error);

  /// No description provided for @stkReceiveTitle.
  ///
  /// In id, this message translates to:
  /// **'Terima {name}'**
  String stkReceiveTitle(String name);

  /// No description provided for @stkReceiveSub.
  ///
  /// In id, this message translates to:
  /// **'Catat penambahan stok dan harga beli terbaru.'**
  String get stkReceiveSub;

  /// No description provided for @stkPricePer.
  ///
  /// In id, this message translates to:
  /// **'Harga per {unit} (opsional)'**
  String stkPricePer(String unit);

  /// No description provided for @stkPriceHelper.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan jika tidak mengubah harga rata-rata'**
  String get stkPriceHelper;

  /// No description provided for @stkSupplier.
  ///
  /// In id, this message translates to:
  /// **'Pemasok (opsional)'**
  String get stkSupplier;

  /// No description provided for @stkReceiveOk.
  ///
  /// In id, this message translates to:
  /// **'Stok berhasil ditambahkan'**
  String get stkReceiveOk;

  /// No description provided for @stkProduceTitle.
  ///
  /// In id, this message translates to:
  /// **'Produksi {name}'**
  String stkProduceTitle(String name);

  /// No description provided for @stkProduceSub.
  ///
  /// In id, this message translates to:
  /// **'1 batch = {qty}. Bahan baku penyusun akan berkurang otomatis.'**
  String stkProduceSub(String qty);

  /// No description provided for @stkBatchCount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah batch'**
  String get stkBatchCount;

  /// No description provided for @stkProduceOk.
  ///
  /// In id, this message translates to:
  /// **'Produksi berhasil dicatat'**
  String get stkProduceOk;

  /// No description provided for @stkArchived.
  ///
  /// In id, this message translates to:
  /// **'{name} diarsipkan'**
  String stkArchived(String name);

  /// No description provided for @stkNewIngredient.
  ///
  /// In id, this message translates to:
  /// **'Bahan Baru'**
  String get stkNewIngredient;

  /// No description provided for @stkEditIngredient.
  ///
  /// In id, this message translates to:
  /// **'Ubah {name}'**
  String stkEditIngredient(String name);

  /// No description provided for @stkEditorSub.
  ///
  /// In id, this message translates to:
  /// **'Atur nama, satuan unit, dan batas reorder.'**
  String get stkEditorSub;

  /// No description provided for @stkName.
  ///
  /// In id, this message translates to:
  /// **'Nama bahan'**
  String get stkName;

  /// No description provided for @stkUnit.
  ///
  /// In id, this message translates to:
  /// **'Satuan'**
  String get stkUnit;

  /// No description provided for @stkUnitOption.
  ///
  /// In id, this message translates to:
  /// **'{unit} · {dimension}'**
  String stkUnitOption(String unit, String dimension);

  /// No description provided for @stkOpening.
  ///
  /// In id, this message translates to:
  /// **'Stok awal ({unit})'**
  String stkOpening(String unit);

  /// No description provided for @stkOpeningHelper.
  ///
  /// In id, this message translates to:
  /// **'Dicatat sebagai mutasi awal'**
  String get stkOpeningHelper;

  /// No description provided for @stkLowAt.
  ///
  /// In id, this message translates to:
  /// **'Batas menipis ({unit}, opsional)'**
  String stkLowAt(String unit);

  /// No description provided for @stkLowAtHelper.
  ///
  /// In id, this message translates to:
  /// **'Munculkan peringatan saat stok di bawah angka ini'**
  String get stkLowAtHelper;

  /// No description provided for @stkBatchYield.
  ///
  /// In id, this message translates to:
  /// **'Hasil 1 batch ({unit}, opsional)'**
  String stkBatchYield(String unit);

  /// CONTEXT.md: resep · Recipe.
  ///
  /// In id, this message translates to:
  /// **'Isi bila bahan ini hasil racikan internal, lalu susun resepnya'**
  String get stkBatchYieldHelper;

  /// No description provided for @stkSaveOk.
  ///
  /// In id, this message translates to:
  /// **'Bahan berhasil disimpan'**
  String get stkSaveOk;

  /// No description provided for @stkLedgerTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Mutasi'**
  String get stkLedgerTitle;

  /// No description provided for @stkLedgerLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat: {error}'**
  String stkLedgerLoadFailed(String error);

  /// No description provided for @stkLedgerEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada riwayat mutasi untuk bahan ini.'**
  String get stkLedgerEmpty;

  /// No description provided for @stkAddFirst.
  ///
  /// In id, this message translates to:
  /// **'Tambah Bahan Pertama'**
  String get stkAddFirst;

  /// No description provided for @stkUnused.
  ///
  /// In id, this message translates to:
  /// **'belum dipakai'**
  String get stkUnused;

  /// Compact duration units. Indonesian: thn=tahun, bl=bulan, h=hari, j=jam, m=menit, d=detik. Note h and d do NOT mean hour and day here.
  ///
  /// In id, this message translates to:
  /// **'{n}thn'**
  String durYears(int n);

  /// No description provided for @durMonths.
  ///
  /// In id, this message translates to:
  /// **'{n}bl'**
  String durMonths(int n);

  /// No description provided for @durDays.
  ///
  /// In id, this message translates to:
  /// **'{n}h'**
  String durDays(int n);

  /// No description provided for @durHours.
  ///
  /// In id, this message translates to:
  /// **'{n}j'**
  String durHours(int n);

  /// No description provided for @durMins.
  ///
  /// In id, this message translates to:
  /// **'{n}m'**
  String durMins(int n);

  /// No description provided for @durSecs.
  ///
  /// In id, this message translates to:
  /// **'{n}d'**
  String durSecs(int n);

  /// No description provided for @durDh.
  ///
  /// In id, this message translates to:
  /// **'{d}h {h}j'**
  String durDh(int d, int h);

  /// No description provided for @durHm.
  ///
  /// In id, this message translates to:
  /// **'{h}j {m}m'**
  String durHm(int h, int m);

  /// No description provided for @durMs.
  ///
  /// In id, this message translates to:
  /// **'{m}m {s}d'**
  String durMs(int m, int s);

  /// No description provided for @durHms.
  ///
  /// In id, this message translates to:
  /// **'{h}j {m}m {s}d'**
  String durHms(int h, int m, int s);

  /// No description provided for @relAgo.
  ///
  /// In id, this message translates to:
  /// **'{value} lalu'**
  String relAgo(String value);

  /// No description provided for @relIn.
  ///
  /// In id, this message translates to:
  /// **'{value} lagi'**
  String relIn(String value);

  /// No description provided for @elapsedYesterday.
  ///
  /// In id, this message translates to:
  /// **'kemarin'**
  String get elapsedYesterday;

  /// No description provided for @elapsedDaysAgo.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} hari}} lalu'**
  String elapsedDaysAgo(int n);

  /// No description provided for @sysTitle.
  ///
  /// In id, this message translates to:
  /// **'Sistem'**
  String get sysTitle;

  /// No description provided for @sysVenueFallback.
  ///
  /// In id, this message translates to:
  /// **'Venue'**
  String get sysVenueFallback;

  /// No description provided for @sysHeaderSub.
  ///
  /// In id, this message translates to:
  /// **'{venue} · v2.0'**
  String sysHeaderSub(String venue);

  /// No description provided for @sysDegraded.
  ///
  /// In id, this message translates to:
  /// **'Mode degraded'**
  String get sysDegraded;

  /// No description provided for @sysLanOnline.
  ///
  /// In id, this message translates to:
  /// **'LAN online'**
  String get sysLanOnline;

  /// No description provided for @sysKdsOnline.
  ///
  /// In id, this message translates to:
  /// **'KDS Online'**
  String get sysKdsOnline;

  /// No description provided for @sysNoStations.
  ///
  /// In id, this message translates to:
  /// **'Belum ada stasiun'**
  String get sysNoStations;

  /// No description provided for @sysStationsActive.
  ///
  /// In id, this message translates to:
  /// **'Stasiun aktif'**
  String get sysStationsActive;

  /// No description provided for @sysTabletPair.
  ///
  /// In id, this message translates to:
  /// **'Tablet Pair'**
  String get sysTabletPair;

  /// No description provided for @sysNoDevices.
  ///
  /// In id, this message translates to:
  /// **'Belum ada perangkat'**
  String get sysNoDevices;

  /// No description provided for @sysDevicesActive.
  ///
  /// In id, this message translates to:
  /// **'Perangkat aktif'**
  String get sysDevicesActive;

  /// No description provided for @sysQueue.
  ///
  /// In id, this message translates to:
  /// **'Antrian'**
  String get sysQueue;

  /// No description provided for @sysNoPendingJobs.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada job tertunda'**
  String get sysNoPendingJobs;

  /// No description provided for @sysTicketsWaiting.
  ///
  /// In id, this message translates to:
  /// **'Tiket menunggu'**
  String get sysTicketsWaiting;

  /// No description provided for @sysServerLan.
  ///
  /// In id, this message translates to:
  /// **'Server LAN'**
  String get sysServerLan;

  /// No description provided for @sysTagBooting.
  ///
  /// In id, this message translates to:
  /// **'BOOTING'**
  String get sysTagBooting;

  /// No description provided for @sysTagPrimary.
  ///
  /// In id, this message translates to:
  /// **'PRIMARY'**
  String get sysTagPrimary;

  /// No description provided for @sysAddress.
  ///
  /// In id, this message translates to:
  /// **'Alamat'**
  String get sysAddress;

  /// No description provided for @sysUptime.
  ///
  /// In id, this message translates to:
  /// **'Uptime'**
  String get sysUptime;

  /// No description provided for @sysCertificate.
  ///
  /// In id, this message translates to:
  /// **'Sertifikat'**
  String get sysCertificate;

  /// No description provided for @sysPingLan.
  ///
  /// In id, this message translates to:
  /// **'Ping LAN'**
  String get sysPingLan;

  /// No description provided for @sysPingValue.
  ///
  /// In id, this message translates to:
  /// **'p50 {p50} ms · last {last} ms'**
  String sysPingValue(int p50, int last);

  /// No description provided for @sysP95.
  ///
  /// In id, this message translates to:
  /// **'p95 latensi'**
  String get sysP95;

  /// No description provided for @sysP95Value.
  ///
  /// In id, this message translates to:
  /// **'{ms} ms · {count} req'**
  String sysP95Value(int ms, int count);

  /// No description provided for @sysFingerprint.
  ///
  /// In id, this message translates to:
  /// **'Fingerprint'**
  String get sysFingerprint;

  /// No description provided for @sysCopy.
  ///
  /// In id, this message translates to:
  /// **'Salin'**
  String get sysCopy;

  /// No description provided for @sysFingerprintCopied.
  ///
  /// In id, this message translates to:
  /// **'Fingerprint disalin'**
  String get sysFingerprintCopied;

  /// No description provided for @sysNoneYet.
  ///
  /// In id, this message translates to:
  /// **'Belum ada'**
  String get sysNoneYet;

  /// No description provided for @sysAddPrinterOrStation.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan printer atau stasiun'**
  String get sysAddPrinterOrStation;

  /// No description provided for @sysPrintersKds.
  ///
  /// In id, this message translates to:
  /// **'Printer & KDS'**
  String get sysPrintersKds;

  /// No description provided for @sysTagStations.
  ///
  /// In id, this message translates to:
  /// **'{n} STASIUN'**
  String sysTagStations(int n);

  /// No description provided for @sysDiscover.
  ///
  /// In id, this message translates to:
  /// **'Cari'**
  String get sysDiscover;

  /// No description provided for @sysAddPrinterBtn.
  ///
  /// In id, this message translates to:
  /// **'+ Printer'**
  String get sysAddPrinterBtn;

  /// No description provided for @sysPrinterTest.
  ///
  /// In id, this message translates to:
  /// **'Test'**
  String get sysPrinterTest;

  /// No description provided for @sysTestPrinted.
  ///
  /// In id, this message translates to:
  /// **'Tes tercetak'**
  String get sysTestPrinted;

  /// No description provided for @sysOnline.
  ///
  /// In id, this message translates to:
  /// **'Online'**
  String get sysOnline;

  /// No description provided for @sysOffline.
  ///
  /// In id, this message translates to:
  /// **'Offline'**
  String get sysOffline;

  /// No description provided for @sysStationLoad.
  ///
  /// In id, this message translates to:
  /// **'{staff} staf · {tickets, plural, other{{tickets} tiket}}'**
  String sysStationLoad(int staff, int tickets);

  /// No description provided for @sysStationQuiet.
  ///
  /// In id, this message translates to:
  /// **'Sepi'**
  String get sysStationQuiet;

  /// No description provided for @sysStationBusy.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get sysStationBusy;

  /// No description provided for @sysDevicesTitle.
  ///
  /// In id, this message translates to:
  /// **'Perangkat aktif'**
  String get sysDevicesTitle;

  /// No description provided for @sysTagPair.
  ///
  /// In id, this message translates to:
  /// **'{n} PAIR'**
  String sysTagPair(int n);

  /// No description provided for @sysNoDevicesPaired.
  ///
  /// In id, this message translates to:
  /// **'Belum ada perangkat dipasangkan'**
  String get sysNoDevicesPaired;

  /// No description provided for @sysNeverSignedIn.
  ///
  /// In id, this message translates to:
  /// **'belum sign-in'**
  String get sysNeverSignedIn;

  /// No description provided for @sysLastSession.
  ///
  /// In id, this message translates to:
  /// **'sesi {when}'**
  String sysLastSession(String when);

  /// No description provided for @sysRevoked.
  ///
  /// In id, this message translates to:
  /// **'Revoked'**
  String get sysRevoked;

  /// No description provided for @sysDeviceActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get sysDeviceActive;

  /// No description provided for @sysDeviceIdle.
  ///
  /// In id, this message translates to:
  /// **'Idle'**
  String get sysDeviceIdle;

  /// No description provided for @sysRevoke.
  ///
  /// In id, this message translates to:
  /// **'Revoke'**
  String get sysRevoke;

  /// No description provided for @sysOperational.
  ///
  /// In id, this message translates to:
  /// **'Operasional'**
  String get sysOperational;

  /// No description provided for @sysTagRuntime.
  ///
  /// In id, this message translates to:
  /// **'RUNTIME'**
  String get sysTagRuntime;

  /// No description provided for @sysActions.
  ///
  /// In id, this message translates to:
  /// **'Tindakan'**
  String get sysActions;

  /// No description provided for @sysRestartServer.
  ///
  /// In id, this message translates to:
  /// **'Mulai ulang server'**
  String get sysRestartServer;

  /// No description provided for @sysWaitingProbe.
  ///
  /// In id, this message translates to:
  /// **'tunggu probe…'**
  String get sysWaitingProbe;

  /// No description provided for @sysOfflineLower.
  ///
  /// In id, this message translates to:
  /// **'offline'**
  String get sysOfflineLower;

  /// No description provided for @sysPingWs.
  ///
  /// In id, this message translates to:
  /// **'{ms} ms · {state}'**
  String sysPingWs(int ms, String state);

  /// No description provided for @sysPhoneSub.
  ///
  /// In id, this message translates to:
  /// **'Server, jaringan, printer, perangkat'**
  String get sysPhoneSub;

  /// No description provided for @sysPrinterStationCount.
  ///
  /// In id, this message translates to:
  /// **'{printers, plural, other{{printers} printer}} · {stations, plural, other{{stations} stasiun}}'**
  String sysPrinterStationCount(int printers, int stations);

  /// No description provided for @sysDevices.
  ///
  /// In id, this message translates to:
  /// **'Perangkat'**
  String get sysDevices;

  /// No description provided for @sysPairActiveCount.
  ///
  /// In id, this message translates to:
  /// **'{paired} pair · {active} aktif'**
  String sysPairActiveCount(int paired, int active);

  /// No description provided for @sysNoManageStaff.
  ///
  /// In id, this message translates to:
  /// **'Tidak punya izin manageStaff'**
  String get sysNoManageStaff;

  /// No description provided for @sysRestarting.
  ///
  /// In id, this message translates to:
  /// **'Server restart… menyambung ulang'**
  String get sysRestarting;

  /// No description provided for @sysRestartFailed.
  ///
  /// In id, this message translates to:
  /// **'Restart gagal: {code}'**
  String sysRestartFailed(String code);

  /// No description provided for @sysRevokeTitle.
  ///
  /// In id, this message translates to:
  /// **'Revoke perangkat?'**
  String get sysRevokeTitle;

  /// No description provided for @sysRevokeBody.
  ///
  /// In id, this message translates to:
  /// **'{label} akan kehilangan sesi.'**
  String sysRevokeBody(String label);

  /// No description provided for @sysSearchingPrinters.
  ///
  /// In id, this message translates to:
  /// **'Mencari printer…'**
  String get sysSearchingPrinters;

  /// No description provided for @sysNoPrintersFound.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada printer ditemukan'**
  String get sysNoPrintersFound;

  /// No description provided for @sysPrintersFound.
  ///
  /// In id, this message translates to:
  /// **'Printer ditemukan'**
  String get sysPrintersFound;

  /// No description provided for @sysHostPort.
  ///
  /// In id, this message translates to:
  /// **'{host}:{port}'**
  String sysHostPort(String host, int port);

  /// No description provided for @sysPrinterAdded.
  ///
  /// In id, this message translates to:
  /// **'Printer \"{name}\" ditambahkan'**
  String sysPrinterAdded(String name);

  /// No description provided for @sysAddPrinterTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah printer'**
  String get sysAddPrinterTitle;

  /// No description provided for @sysPrinterLabel.
  ///
  /// In id, this message translates to:
  /// **'Label'**
  String get sysPrinterLabel;

  /// No description provided for @sysPrinterHost.
  ///
  /// In id, this message translates to:
  /// **'Host (IP)'**
  String get sysPrinterHost;

  /// No description provided for @sysPrinterPort.
  ///
  /// In id, this message translates to:
  /// **'Port'**
  String get sysPrinterPort;

  /// No description provided for @sysPrinterKind.
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get sysPrinterKind;

  /// No description provided for @sysHeroWarnDesc.
  ///
  /// In id, this message translates to:
  /// **'WS {ws} · reach={reach} · {fails} gagal'**
  String sysHeroWarnDesc(String ws, String reach, int fails);

  /// No description provided for @sysHeroOkDesc.
  ///
  /// In id, this message translates to:
  /// **'{sessions, plural, other{{sessions} sesi aktif}} · {devices, plural, other{{devices} perangkat}} · WS {ws}'**
  String sysHeroOkDesc(int sessions, int devices, String ws);

  /// No description provided for @sysReachOk.
  ///
  /// In id, this message translates to:
  /// **'ok'**
  String get sysReachOk;

  /// No description provided for @sysReachOff.
  ///
  /// In id, this message translates to:
  /// **'off'**
  String get sysReachOff;

  /// No description provided for @sysServerLanOk.
  ///
  /// In id, this message translates to:
  /// **'Server LAN OK'**
  String get sysServerLanOk;

  /// No description provided for @sysRestartTitle.
  ///
  /// In id, this message translates to:
  /// **'Mulai ulang server?'**
  String get sysRestartTitle;

  /// No description provided for @sysRestartBody.
  ///
  /// In id, this message translates to:
  /// **'WS clients akan disconnect ~1-3 detik. Masukkan PIN untuk konfirmasi.'**
  String get sysRestartBody;

  /// No description provided for @sysPin.
  ///
  /// In id, this message translates to:
  /// **'PIN'**
  String get sysPin;

  /// No description provided for @sysConfirm.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi'**
  String get sysConfirm;

  /// No description provided for @sysWrongPin.
  ///
  /// In id, this message translates to:
  /// **'PIN salah'**
  String get sysWrongPin;

  /// No description provided for @retry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get retry;

  /// No description provided for @tblOtherUser.
  ///
  /// In id, this message translates to:
  /// **'pengguna lain'**
  String get tblOtherUser;

  /// No description provided for @tblTakenBy.
  ///
  /// In id, this message translates to:
  /// **'Meja diambil oleh {holder}'**
  String tblTakenBy(String holder);

  /// No description provided for @tblAlreadySeated.
  ///
  /// In id, this message translates to:
  /// **'Meja sudah diisi oleh {holder}'**
  String tblAlreadySeated(String holder);

  /// No description provided for @tblSeatFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mulai layani: {error}'**
  String tblSeatFailed(String error);

  /// No description provided for @tblReleaseTable.
  ///
  /// In id, this message translates to:
  /// **'Lepaskan Meja'**
  String get tblReleaseTable;

  /// No description provided for @tblFinishService.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan Layanan'**
  String get tblFinishService;

  /// No description provided for @tblLoadingMenu.
  ///
  /// In id, this message translates to:
  /// **'Memuat menu…'**
  String get tblLoadingMenu;

  /// No description provided for @tblMenuLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat menu meja'**
  String get tblMenuLoadFailed;

  /// No description provided for @tblReleaseTableQ.
  ///
  /// In id, this message translates to:
  /// **'Lepaskan Meja?'**
  String get tblReleaseTableQ;

  /// No description provided for @tblFinishServiceQ.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan Layanan?'**
  String get tblFinishServiceQ;

  /// No description provided for @tblReleaseBody.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pesanan. Kosongkan meja {table}?'**
  String tblReleaseBody(String table);

  /// No description provided for @tblFinishBody.
  ///
  /// In id, this message translates to:
  /// **'Semua tiket telah selesai. Kosongkan meja {table} untuk tamu berikutnya? Tagihan tetap di kasir sampai dibayar.'**
  String tblFinishBody(String table);

  /// No description provided for @tblCloseFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menutup meja: {error}'**
  String tblCloseFailed(String error);

  /// No description provided for @tblEmptyPhone.
  ///
  /// In id, this message translates to:
  /// **'Belum ada item — ketuk \"Tambah ke pesanan\" untuk mulai.'**
  String get tblEmptyPhone;

  /// No description provided for @tblContextTitle.
  ///
  /// In id, this message translates to:
  /// **'Konteks meja'**
  String get tblContextTitle;

  /// No description provided for @tblSeatedFor.
  ///
  /// In id, this message translates to:
  /// **'DUDUK {elapsed} · {pax} TAMU'**
  String tblSeatedFor(String elapsed, int pax);

  /// No description provided for @tblItemCount.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} item}}'**
  String tblItemCount(int n);

  /// No description provided for @tblItemCountHeld.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} item}} · ditahan'**
  String tblItemCountHeld(int n);

  /// No description provided for @tblFireCourse.
  ///
  /// In id, this message translates to:
  /// **'Bakar {course}'**
  String tblFireCourse(String course);

  /// No description provided for @tblKosong.
  ///
  /// In id, this message translates to:
  /// **'Meja {table} kosong'**
  String tblKosong(String table);

  /// No description provided for @tblKosongHint.
  ///
  /// In id, this message translates to:
  /// **'Tap untuk mulai melayani tamu'**
  String get tblKosongHint;

  /// No description provided for @tblStartService.
  ///
  /// In id, this message translates to:
  /// **'Mulai layani meja'**
  String get tblStartService;

  /// No description provided for @tblLockedBy.
  ///
  /// In id, this message translates to:
  /// **'Terkunci oleh {holder}{since} · hanya lihat'**
  String tblLockedBy(String holder, String since);

  /// No description provided for @tblLockedSince.
  ///
  /// In id, this message translates to:
  /// **' · sejak {time}'**
  String tblLockedSince(String time);

  /// No description provided for @tblReadyToCollect.
  ///
  /// In id, this message translates to:
  /// **'{n} siap diambil'**
  String tblReadyToCollect(int n);

  /// No description provided for @tblViewOnly.
  ///
  /// In id, this message translates to:
  /// **'Hanya lihat'**
  String get tblViewOnly;

  /// No description provided for @tblCreateOrder.
  ///
  /// In id, this message translates to:
  /// **'Buat pesanan'**
  String get tblCreateOrder;

  /// No description provided for @tblAddOrder.
  ///
  /// In id, this message translates to:
  /// **'Tambah pesanan'**
  String get tblAddOrder;

  /// No description provided for @tblStatTotal.
  ///
  /// In id, this message translates to:
  /// **'Total item'**
  String get tblStatTotal;

  /// No description provided for @tblStatInProgress.
  ///
  /// In id, this message translates to:
  /// **'Dalam proses'**
  String get tblStatInProgress;

  /// No description provided for @tblStatServed.
  ///
  /// In id, this message translates to:
  /// **'Disajikan'**
  String get tblStatServed;

  /// No description provided for @tblGuestNotes.
  ///
  /// In id, this message translates to:
  /// **'CATATAN TAMU'**
  String get tblGuestNotes;

  /// No description provided for @tblNoGuestNotes.
  ///
  /// In id, this message translates to:
  /// **'Belum ada catatan khusus.'**
  String get tblNoGuestNotes;

  /// No description provided for @tblSpecialInstruction.
  ///
  /// In id, this message translates to:
  /// **'Instruksi khusus'**
  String get tblSpecialInstruction;

  /// No description provided for @tblAllergensInOrder.
  ///
  /// In id, this message translates to:
  /// **'ALERGEN DI PESANAN'**
  String get tblAllergensInOrder;

  /// No description provided for @tblNoAllergens.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada.'**
  String get tblNoAllergens;

  /// No description provided for @tblQuickActions.
  ///
  /// In id, this message translates to:
  /// **'AKSI CEPAT'**
  String get tblQuickActions;

  /// No description provided for @tblPrintTableReceipt.
  ///
  /// In id, this message translates to:
  /// **'Cetak struk meja'**
  String get tblPrintTableReceipt;

  /// No description provided for @tblMoveTable.
  ///
  /// In id, this message translates to:
  /// **'Pindahkan meja'**
  String get tblMoveTable;

  /// No description provided for @mieBlankNames.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi nama yang masih kosong'**
  String get mieBlankNames;

  /// No description provided for @mieSaveFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan: {error}'**
  String mieSaveFailed(String error);

  /// No description provided for @mieItemAdded.
  ///
  /// In id, this message translates to:
  /// **'Item ditambahkan'**
  String get mieItemAdded;

  /// No description provided for @mieChangesSaved.
  ///
  /// In id, this message translates to:
  /// **'Perubahan tersimpan'**
  String get mieChangesSaved;

  /// No description provided for @mieDeleteTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus item?'**
  String get mieDeleteTitle;

  /// No description provided for @mieDeleteBody.
  ///
  /// In id, this message translates to:
  /// **'Item \"{name}\" akan dihapus dari menu.'**
  String mieDeleteBody(String name);

  /// No description provided for @mieNewItem.
  ///
  /// In id, this message translates to:
  /// **'Item baru'**
  String get mieNewItem;

  /// No description provided for @mieReadOnlySub.
  ///
  /// In id, this message translates to:
  /// **'Hanya admin yang bisa edit'**
  String get mieReadOnlySub;

  /// No description provided for @mieIdentity.
  ///
  /// In id, this message translates to:
  /// **'Identitas'**
  String get mieIdentity;

  /// No description provided for @mieItemName.
  ///
  /// In id, this message translates to:
  /// **'Nama item'**
  String get mieItemName;

  /// No description provided for @mieShortDesc.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi singkat'**
  String get mieShortDesc;

  /// No description provided for @mieCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get mieCategory;

  /// No description provided for @miePhotoChange.
  ///
  /// In id, this message translates to:
  /// **'UBAH'**
  String get miePhotoChange;

  /// No description provided for @miePhotoAdd.
  ///
  /// In id, this message translates to:
  /// **'FOTO'**
  String get miePhotoAdd;

  /// No description provided for @miePickGallery.
  ///
  /// In id, this message translates to:
  /// **'Pilih dari galeri'**
  String get miePickGallery;

  /// No description provided for @mieTakePhoto.
  ///
  /// In id, this message translates to:
  /// **'Ambil foto'**
  String get mieTakePhoto;

  /// No description provided for @mieDeletePhoto.
  ///
  /// In id, this message translates to:
  /// **'Hapus foto'**
  String get mieDeletePhoto;

  /// No description provided for @miePhotoLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat foto: {error}'**
  String miePhotoLoadFailed(String error);

  /// No description provided for @miePhotoSaveFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan foto'**
  String get miePhotoSaveFailed;

  /// No description provided for @miePricing.
  ///
  /// In id, this message translates to:
  /// **'Harga'**
  String get miePricing;

  /// No description provided for @mieBasePrice.
  ///
  /// In id, this message translates to:
  /// **'Harga dasar'**
  String get mieBasePrice;

  /// No description provided for @mieFollowVenue.
  ///
  /// In id, this message translates to:
  /// **'Ikut venue ({mins}m)'**
  String mieFollowVenue(int mins);

  /// No description provided for @miePrepTime.
  ///
  /// In id, this message translates to:
  /// **'Waktu siap (menit)'**
  String get miePrepTime;

  /// CONTEXT.md: HPP · COGS — the per-item cost of goods sold.
  ///
  /// In id, this message translates to:
  /// **'HPP'**
  String get mieCost;

  /// No description provided for @mieVariants.
  ///
  /// In id, this message translates to:
  /// **'Varian ukuran'**
  String get mieVariants;

  /// No description provided for @mieAddVariant.
  ///
  /// In id, this message translates to:
  /// **'+ Varian'**
  String get mieAddVariant;

  /// No description provided for @mieNoVariants.
  ///
  /// In id, this message translates to:
  /// **'Belum ada varian. Hanya pakai harga dasar.'**
  String get mieNoVariants;

  /// No description provided for @mieVariantNameHint.
  ///
  /// In id, this message translates to:
  /// **'Nama (mis. Besar)'**
  String get mieVariantNameHint;

  /// No description provided for @miePrice.
  ///
  /// In id, this message translates to:
  /// **'Harga'**
  String get miePrice;

  /// No description provided for @mieModifierGroups.
  ///
  /// In id, this message translates to:
  /// **'Grup modifier'**
  String get mieModifierGroups;

  /// No description provided for @mieAddGroup.
  ///
  /// In id, this message translates to:
  /// **'+ Grup'**
  String get mieAddGroup;

  /// No description provided for @mieNoModifiers.
  ///
  /// In id, this message translates to:
  /// **'Belum ada grup modifier (mis. tingkat pedas, pilih protein).'**
  String get mieNoModifiers;

  /// No description provided for @mieGroupName.
  ///
  /// In id, this message translates to:
  /// **'Nama grup'**
  String get mieGroupName;

  /// No description provided for @mieRequired.
  ///
  /// In id, this message translates to:
  /// **'Wajib'**
  String get mieRequired;

  /// No description provided for @mieMulti.
  ///
  /// In id, this message translates to:
  /// **'Pilih banyak'**
  String get mieMulti;

  /// No description provided for @mieAddOption.
  ///
  /// In id, this message translates to:
  /// **'+ Opsi'**
  String get mieAddOption;

  /// No description provided for @mieOptionName.
  ///
  /// In id, this message translates to:
  /// **'Nama opsi'**
  String get mieOptionName;

  /// CONTEXT.md: resep · Recipe.
  ///
  /// In id, this message translates to:
  /// **'Resep'**
  String get mieRecipe;

  /// No description provided for @mieIngredientsLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat bahan: {error}'**
  String mieIngredientsLoadFailed(String error);

  /// No description provided for @mieNoIngredients.
  ///
  /// In id, this message translates to:
  /// **'Belum ada bahan. Tambahkan di menu Stok sebelum menyusun resep.'**
  String get mieNoIngredients;

  /// No description provided for @mieScopeBase.
  ///
  /// In id, this message translates to:
  /// **'Dasar'**
  String get mieScopeBase;

  /// No description provided for @mieScopeOption.
  ///
  /// In id, this message translates to:
  /// **'{group}: {option}'**
  String mieScopeOption(String group, String option);

  /// No description provided for @mieScopeFilled.
  ///
  /// In id, this message translates to:
  /// **'{label} ·'**
  String mieScopeFilled(String label);

  /// No description provided for @mieRecipeVariantHint.
  ///
  /// In id, this message translates to:
  /// **'Resep varian menggantikan resep dasar sepenuhnya. Kosong = ikut resep dasar.'**
  String get mieRecipeVariantHint;

  /// No description provided for @mieRecipeOptionHint.
  ///
  /// In id, this message translates to:
  /// **'Resep modifier ditambahkan di atas resep yang berlaku.'**
  String get mieRecipeOptionHint;

  /// No description provided for @mieRecipeBaseHint.
  ///
  /// In id, this message translates to:
  /// **'Dipakai saat item tidak punya varian, atau varian belum punya resep sendiri.'**
  String get mieRecipeBaseHint;

  /// No description provided for @mieRecipeEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada bahan pada resep ini.'**
  String get mieRecipeEmpty;

  /// No description provided for @mieAddIngredient.
  ///
  /// In id, this message translates to:
  /// **'Tambah bahan'**
  String get mieAddIngredient;

  /// CONTEXT.md: bahan · Ingredient.
  ///
  /// In id, this message translates to:
  /// **'Bahan'**
  String get mieIngredient;

  /// No description provided for @mieIngredientOption.
  ///
  /// In id, this message translates to:
  /// **'{name} ({unit})'**
  String mieIngredientOption(String name, String unit);

  /// No description provided for @mieQty.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get mieQty;

  /// No description provided for @mieTags.
  ///
  /// In id, this message translates to:
  /// **'Tag'**
  String get mieTags;

  /// No description provided for @mieAllergens.
  ///
  /// In id, this message translates to:
  /// **'Alergen'**
  String get mieAllergens;

  /// No description provided for @mieDiet.
  ///
  /// In id, this message translates to:
  /// **'Diet'**
  String get mieDiet;

  /// No description provided for @mieAvailability.
  ///
  /// In id, this message translates to:
  /// **'Ketersediaan'**
  String get mieAvailability;

  /// No description provided for @mieAutoSoldOut.
  ///
  /// In id, this message translates to:
  /// **'Tidak tersedia (stok 0)'**
  String get mieAutoSoldOut;

  /// No description provided for @mieManualSoldOut.
  ///
  /// In id, this message translates to:
  /// **'Tidak tersedia (manual)'**
  String get mieManualSoldOut;

  /// No description provided for @mieActiveForSale.
  ///
  /// In id, this message translates to:
  /// **'Aktif untuk dijual'**
  String get mieActiveForSale;

  /// No description provided for @mieActivate.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan'**
  String get mieActivate;

  /// No description provided for @mieMarkUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Tandai tidak tersedia'**
  String get mieMarkUnavailable;

  /// No description provided for @mieUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Tidak tersedia'**
  String get mieUnavailable;

  /// No description provided for @mieActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get mieActive;

  /// No description provided for @mieDerivedCost.
  ///
  /// In id, this message translates to:
  /// **'≈ {amount} dari resep dasar'**
  String mieDerivedCost(String amount);

  /// No description provided for @mieRequiredField.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi'**
  String get mieRequiredField;

  /// No description provided for @mieMargin.
  ///
  /// In id, this message translates to:
  /// **'MARGIN'**
  String get mieMargin;

  /// No description provided for @mieMarginNoPrice.
  ///
  /// In id, this message translates to:
  /// **'Isi harga dasar dulu'**
  String get mieMarginNoPrice;

  /// No description provided for @mieMarginHealthy.
  ///
  /// In id, this message translates to:
  /// **'Margin sehat'**
  String get mieMarginHealthy;

  /// No description provided for @mieMarginThin.
  ///
  /// In id, this message translates to:
  /// **'Margin tipis'**
  String get mieMarginThin;

  /// No description provided for @mieMarginCritical.
  ///
  /// In id, this message translates to:
  /// **'Margin kritis'**
  String get mieMarginCritical;

  /// Rupiah never localises (ADR-0084) — only the hint half swaps language.
  ///
  /// In id, this message translates to:
  /// **'Rp {amount} · {hint}'**
  String mieMarginValue(int amount, String hint);

  /// No description provided for @mnaTitle.
  ///
  /// In id, this message translates to:
  /// **'Menu'**
  String get mnaTitle;

  /// No description provided for @mnaHeaderSub.
  ///
  /// In id, this message translates to:
  /// **'{total, plural, other{{total} item}} · {cats, plural, other{{cats} kategori}} · {out} tidak tersedia'**
  String mnaHeaderSub(int total, int cats, int out);

  /// No description provided for @mnaPhoneSub.
  ///
  /// In id, this message translates to:
  /// **'{total, plural, other{{total} item}} · {out} tidak tersedia'**
  String mnaPhoneSub(int total, int out);

  /// No description provided for @mnaAddItem.
  ///
  /// In id, this message translates to:
  /// **'+ Tambah item'**
  String get mnaAddItem;

  /// No description provided for @mnaPickStaff.
  ///
  /// In id, this message translates to:
  /// **'Pilih item untuk lihat detail'**
  String get mnaPickStaff;

  /// No description provided for @mnaPickAdmin.
  ///
  /// In id, this message translates to:
  /// **'Pilih item atau tambah baru'**
  String get mnaPickAdmin;

  /// No description provided for @mnaPickStaffSub.
  ///
  /// In id, this message translates to:
  /// **'Mode staf: hanya tandai habis. Edit penuh hanya admin.'**
  String get mnaPickStaffSub;

  /// No description provided for @mnaPickAdminSub.
  ///
  /// In id, this message translates to:
  /// **'Kelola harga, modifier, stok, dan ketersediaan.'**
  String get mnaPickAdminSub;

  /// No description provided for @mnaSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari item, deskripsi…'**
  String get mnaSearchHint;

  /// No description provided for @mnaAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get mnaAll;

  /// No description provided for @mnaNoMatch.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada item cocok.'**
  String get mnaNoMatch;

  /// No description provided for @mnaIngredientsOut.
  ///
  /// In id, this message translates to:
  /// **'Bahan habis'**
  String get mnaIngredientsOut;

  /// No description provided for @mnaVariantsOut.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} varian}} habis'**
  String mnaVariantsOut(int n);

  /// No description provided for @mnaAutoOut.
  ///
  /// In id, this message translates to:
  /// **'AUTO HABIS'**
  String get mnaAutoOut;

  /// No description provided for @mnaOut.
  ///
  /// In id, this message translates to:
  /// **'HABIS'**
  String get mnaOut;

  /// No description provided for @mnaOn.
  ///
  /// In id, this message translates to:
  /// **'AKTIF'**
  String get mnaOn;

  /// No description provided for @mnaTabItems.
  ///
  /// In id, this message translates to:
  /// **'Item'**
  String get mnaTabItems;

  /// No description provided for @mnaTabCategories.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get mnaTabCategories;

  /// No description provided for @mnaTabTags.
  ///
  /// In id, this message translates to:
  /// **'Tag'**
  String get mnaTabTags;

  /// No description provided for @mnaNewCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori baru'**
  String get mnaNewCategory;

  /// No description provided for @mnaRenameCategory.
  ///
  /// In id, this message translates to:
  /// **'Ubah nama kategori'**
  String get mnaRenameCategory;

  /// No description provided for @mnaMoveItemsFirst.
  ///
  /// In id, this message translates to:
  /// **'Pindahkan {count, plural, other{{count} item}} dulu sebelum hapus \"{name}\"'**
  String mnaMoveItemsFirst(int count, String name);

  /// No description provided for @mnaCategoryInUse.
  ///
  /// In id, this message translates to:
  /// **'Gagal hapus kategori — masih dipakai item'**
  String get mnaCategoryInUse;

  /// No description provided for @mnaCategoryNameHint.
  ///
  /// In id, this message translates to:
  /// **'Nama kategori'**
  String get mnaCategoryNameHint;

  /// No description provided for @mnaDeleteTagTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus \"{name}\"?'**
  String mnaDeleteTagTitle(String name);

  /// No description provided for @mnaDeleteTagBody.
  ///
  /// In id, this message translates to:
  /// **'Tag ini akan dilepas dari semua item yang memakainya.'**
  String get mnaDeleteTagBody;

  /// No description provided for @mnaTagDeleted.
  ///
  /// In id, this message translates to:
  /// **'\"{name}\" dihapus'**
  String mnaTagDeleted(String name);

  /// No description provided for @mnaNewTag.
  ///
  /// In id, this message translates to:
  /// **'Tag baru'**
  String get mnaNewTag;

  /// No description provided for @mnaEditTag.
  ///
  /// In id, this message translates to:
  /// **'Ubah tag'**
  String get mnaEditTag;

  /// No description provided for @mnaTagName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get mnaTagName;

  /// No description provided for @mnaTagCode.
  ///
  /// In id, this message translates to:
  /// **'Kode badge'**
  String get mnaTagCode;

  /// No description provided for @mnaRoleAdmin.
  ///
  /// In id, this message translates to:
  /// **'ADMIN'**
  String get mnaRoleAdmin;

  /// No description provided for @mnaRoleStaff.
  ///
  /// In id, this message translates to:
  /// **'STAF · TANDAI HABIS'**
  String get mnaRoleStaff;

  /// No description provided for @mnuLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat menu'**
  String get mnuLoadFailed;

  /// No description provided for @mnuAddToTakeaway.
  ///
  /// In id, this message translates to:
  /// **'Tambah ke Bawa pulang'**
  String get mnuAddToTakeaway;

  /// No description provided for @mnuNewOrder.
  ///
  /// In id, this message translates to:
  /// **'Pesanan baru'**
  String get mnuNewOrder;

  /// No description provided for @mnuAddToTable.
  ///
  /// In id, this message translates to:
  /// **'Tambah ke Meja {table}'**
  String mnuAddToTable(String table);

  /// No description provided for @mnuTakeawayNoTable.
  ///
  /// In id, this message translates to:
  /// **'BAWA PULANG · TANPA MEJA'**
  String get mnuTakeawayNoTable;

  /// No description provided for @mnuNoTablePickLater.
  ///
  /// In id, this message translates to:
  /// **'TANPA MEJA · PILIH MEJA SAAT KIRIM'**
  String get mnuNoTablePickLater;

  /// No description provided for @mnuZonePax.
  ///
  /// In id, this message translates to:
  /// **'{zone} · {pax} TAMU'**
  String mnuZonePax(String zone, int pax);

  /// No description provided for @mnuAddItem.
  ///
  /// In id, this message translates to:
  /// **'Tambah item'**
  String get mnuAddItem;

  /// No description provided for @mnuAddItemHint.
  ///
  /// In id, this message translates to:
  /// **'KETUK UNTUK ATUR · TEKAN LAMA UNTUK TAMBAH DEFAULT'**
  String get mnuAddItemHint;

  /// No description provided for @mnuPending.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} item}} pending'**
  String mnuPending(int n);

  /// No description provided for @mnuServicePct.
  ///
  /// In id, this message translates to:
  /// **'Layanan · {pct}'**
  String mnuServicePct(String pct);

  /// No description provided for @mnuTaxPct.
  ///
  /// In id, this message translates to:
  /// **'Pajak · {pct}'**
  String mnuTaxPct(String pct);

  /// No description provided for @mnuHeadTakeaway.
  ///
  /// In id, this message translates to:
  /// **'BAWA PULANG · TANPA MEJA'**
  String get mnuHeadTakeaway;

  /// No description provided for @mnuHeadTableless.
  ///
  /// In id, this message translates to:
  /// **'PESANAN BARU · TANPA MEJA'**
  String get mnuHeadTableless;

  /// No description provided for @mnuHeadTable.
  ///
  /// In id, this message translates to:
  /// **'PESANAN BARU · MEJA {table}'**
  String mnuHeadTable(String table);

  /// No description provided for @mnuCartEmpty.
  ///
  /// In id, this message translates to:
  /// **'Keranjang kosong'**
  String get mnuCartEmpty;

  /// No description provided for @mnuCartReady.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} item}} siap kirim'**
  String mnuCartReady(int n);

  /// No description provided for @mnuKitchenCount.
  ///
  /// In id, this message translates to:
  /// **'Dapur × {n}'**
  String mnuKitchenCount(int n);

  /// No description provided for @mnuBarCount.
  ///
  /// In id, this message translates to:
  /// **'Bar × {n}'**
  String mnuBarCount(int n);

  /// No description provided for @mnuCartEmptyHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada item di keranjang. Pilih dari menu di kiri.'**
  String get mnuCartEmptyHint;

  /// No description provided for @mnuEstimate.
  ///
  /// In id, this message translates to:
  /// **'Estimasi'**
  String get mnuEstimate;

  /// No description provided for @mnuReviewSendTo.
  ///
  /// In id, this message translates to:
  /// **'Tinjau & kirim ke {target}'**
  String mnuReviewSendTo(String target);

  /// No description provided for @mnuTargetKitchenBar.
  ///
  /// In id, this message translates to:
  /// **'dapur + bar'**
  String get mnuTargetKitchenBar;

  /// No description provided for @mnuTargetKitchen.
  ///
  /// In id, this message translates to:
  /// **'dapur'**
  String get mnuTargetKitchen;

  /// No description provided for @mnuTargetBar.
  ///
  /// In id, this message translates to:
  /// **'bar'**
  String get mnuTargetBar;

  /// No description provided for @dscNewPreset.
  ///
  /// In id, this message translates to:
  /// **'Preset baru'**
  String get dscNewPreset;

  /// No description provided for @dscEditPreset.
  ///
  /// In id, this message translates to:
  /// **'Ubah preset'**
  String get dscEditPreset;

  /// No description provided for @dscEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada preset diskon'**
  String get dscEmptyTitle;

  /// No description provided for @dscEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Buat preset agar kasir bisa memberi diskon tanpa mengetik angka sendiri.'**
  String get dscEmptyBody;

  /// No description provided for @dscIntro.
  ///
  /// In id, this message translates to:
  /// **'Kasir memilih dari daftar ini — mereka tidak bisa mengetik angka diskon sendiri.'**
  String get dscIntro;

  /// No description provided for @dscScopeOrder.
  ///
  /// In id, this message translates to:
  /// **'Seluruh pesanan'**
  String get dscScopeOrder;

  /// No description provided for @dscScopeLine.
  ///
  /// In id, this message translates to:
  /// **'Per item'**
  String get dscScopeLine;

  /// No description provided for @dscInactive.
  ///
  /// In id, this message translates to:
  /// **'nonaktif'**
  String get dscInactive;

  /// No description provided for @dscDeleteTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus preset'**
  String get dscDeleteTitle;

  /// No description provided for @dscDeleteBody.
  ///
  /// In id, this message translates to:
  /// **'Hapus \"{name}\"? Diskon yang sudah dipakai di tagihan lama tidak berubah — nilainya sudah tersimpan di sana.'**
  String dscDeleteBody(String name);

  /// No description provided for @dscNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama (tampil di struk)'**
  String get dscNameLabel;

  /// No description provided for @dscNameHint.
  ///
  /// In id, this message translates to:
  /// **'Diskon Member'**
  String get dscNameHint;

  /// No description provided for @dscKindPercent.
  ///
  /// In id, this message translates to:
  /// **'Persen'**
  String get dscKindPercent;

  /// No description provided for @dscKindFixed.
  ///
  /// In id, this message translates to:
  /// **'Nominal'**
  String get dscKindFixed;

  /// No description provided for @dscValuePercent.
  ///
  /// In id, this message translates to:
  /// **'Persen (%)'**
  String get dscValuePercent;

  /// No description provided for @dscValueFixed.
  ///
  /// In id, this message translates to:
  /// **'Nominal (Rp)'**
  String get dscValueFixed;

  /// No description provided for @dscActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get dscActive;

  /// No description provided for @dscActiveHint.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif menyembunyikan preset dari kasir'**
  String get dscActiveHint;

  /// No description provided for @dscErrName.
  ///
  /// In id, this message translates to:
  /// **'Nama wajib diisi'**
  String get dscErrName;

  /// No description provided for @dscErrValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai harus lebih dari 0'**
  String get dscErrValue;

  /// No description provided for @dscErrMax.
  ///
  /// In id, this message translates to:
  /// **'Maksimal 100%'**
  String get dscErrMax;

  /// No description provided for @revSendFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal kirim: {error}'**
  String revSendFailed(String error);

  /// No description provided for @revTitle.
  ///
  /// In id, this message translates to:
  /// **'Tinjau pesanan'**
  String get revTitle;

  /// No description provided for @revHeadTakeaway.
  ///
  /// In id, this message translates to:
  /// **'BAWA PULANG · {n} ITEM'**
  String revHeadTakeaway(int n);

  /// No description provided for @revHeadTableless.
  ///
  /// In id, this message translates to:
  /// **'TANPA MEJA · {n} ITEM · PILIH MEJA SAAT KIRIM'**
  String revHeadTableless(int n);

  /// No description provided for @revHeadTable.
  ///
  /// In id, this message translates to:
  /// **'MEJA {table} · {pax} TAMU · {n} ITEM'**
  String revHeadTable(String table, int pax, int n);

  /// No description provided for @revEstimatedTotal.
  ///
  /// In id, this message translates to:
  /// **'Total perkiraan'**
  String get revEstimatedTotal;

  /// No description provided for @revPaymentNote.
  ///
  /// In id, this message translates to:
  /// **'PEMBAYARAN DITANGANI DI LUAR SATSET · BILL DICETAK DARI POS SAAT DISAJIKAN'**
  String get revPaymentNote;

  /// No description provided for @revSending.
  ///
  /// In id, this message translates to:
  /// **'Mengirim…'**
  String get revSending;

  /// No description provided for @revAddToOrder.
  ///
  /// In id, this message translates to:
  /// **'Tambah ke pesanan'**
  String get revAddToOrder;

  /// No description provided for @revSendOrder.
  ///
  /// In id, this message translates to:
  /// **'Kirim pesanan'**
  String get revSendOrder;

  /// No description provided for @revSendTo.
  ///
  /// In id, this message translates to:
  /// **'Kirim ke {target}'**
  String revSendTo(String target);

  /// No description provided for @revTableTaken.
  ///
  /// In id, this message translates to:
  /// **'Meja keburu terisi. Pilih meja lain.'**
  String get revTableTaken;

  /// No description provided for @revSeatFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menempati meja: {error}'**
  String revSeatFailed(String error);

  /// No description provided for @revCommitTitle.
  ///
  /// In id, this message translates to:
  /// **'Kirim pesanan ke'**
  String get revCommitTitle;

  /// No description provided for @revCommitDineIn.
  ///
  /// In id, this message translates to:
  /// **'Meja (dine-in)'**
  String get revCommitDineIn;

  /// No description provided for @revCommitDineInSub.
  ///
  /// In id, this message translates to:
  /// **'Tetapkan ke meja kosong'**
  String get revCommitDineInSub;

  /// No description provided for @revCommitTakeaway.
  ///
  /// In id, this message translates to:
  /// **'Bawa pulang'**
  String get revCommitTakeaway;

  /// No description provided for @revCommitTakeawaySub.
  ///
  /// In id, this message translates to:
  /// **'Takeaway tanpa meja'**
  String get revCommitTakeawaySub;

  /// No description provided for @revChannel.
  ///
  /// In id, this message translates to:
  /// **'Kanal'**
  String get revChannel;

  /// No description provided for @revGuestOrCourier.
  ///
  /// In id, this message translates to:
  /// **'Nama tamu / kurir'**
  String get revGuestOrCourier;

  /// No description provided for @revGuestHint.
  ///
  /// In id, this message translates to:
  /// **'mis. Budi · atau Rizal (kurir)'**
  String get revGuestHint;

  /// No description provided for @revPrepaid.
  ///
  /// In id, this message translates to:
  /// **'Sudah dibayar aplikasi'**
  String get revPrepaid;

  /// No description provided for @revContinue.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get revContinue;

  /// No description provided for @revAutoFire.
  ///
  /// In id, this message translates to:
  /// **'auto-bakar'**
  String get revAutoFire;

  /// No description provided for @revHeldUntilFired.
  ///
  /// In id, this message translates to:
  /// **'ditahan sampai dibakar'**
  String get revHeldUntilFired;

  /// No description provided for @pinErrEmailEmpty.
  ///
  /// In id, this message translates to:
  /// **'Email belum diisi.'**
  String get pinErrEmailEmpty;

  /// No description provided for @pinErrEmailInvalid.
  ///
  /// In id, this message translates to:
  /// **'Email tidak valid.'**
  String get pinErrEmailInvalid;

  /// No description provided for @pinErrPasswordEmpty.
  ///
  /// In id, this message translates to:
  /// **'Password belum diisi.'**
  String get pinErrPasswordEmpty;

  /// No description provided for @pinErrPasswordShort.
  ///
  /// In id, this message translates to:
  /// **'Minimal 6 karakter.'**
  String get pinErrPasswordShort;

  /// No description provided for @pinEnterPin.
  ///
  /// In id, this message translates to:
  /// **'Masukkan PIN'**
  String get pinEnterPin;

  /// No description provided for @pinConnectedTo.
  ///
  /// In id, this message translates to:
  /// **'Tersambung ke {server}'**
  String pinConnectedTo(String server);

  /// No description provided for @pinWidgetBook.
  ///
  /// In id, this message translates to:
  /// **'Widget book'**
  String get pinWidgetBook;

  /// No description provided for @pinEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get pinEmail;

  /// No description provided for @pinEmailHint.
  ///
  /// In id, this message translates to:
  /// **'admin@warung.id'**
  String get pinEmailHint;

  /// No description provided for @pinPassword.
  ///
  /// In id, this message translates to:
  /// **'PASSWORD'**
  String get pinPassword;

  /// No description provided for @pinForgotPassword.
  ///
  /// In id, this message translates to:
  /// **'Lupa password?'**
  String get pinForgotPassword;

  /// No description provided for @pinModeAdmin.
  ///
  /// In id, this message translates to:
  /// **'Admin'**
  String get pinModeAdmin;

  /// No description provided for @pinModeStaff.
  ///
  /// In id, this message translates to:
  /// **'Staff'**
  String get pinModeStaff;

  /// No description provided for @pinSearchingServers.
  ///
  /// In id, this message translates to:
  /// **'Mencari server di jaringan… pastikan tablet server menyala dan berada di Wi-Fi yang sama.'**
  String get pinSearchingServers;

  /// No description provided for @pinHostTakenTitle.
  ///
  /// In id, this message translates to:
  /// **'Venue ini sudah punya perangkat utama'**
  String get pinHostTakenTitle;

  /// No description provided for @pinHostTakenBody.
  ///
  /// In id, this message translates to:
  /// **'Satu venue berjalan di satu perangkat. Tutup aplikasi di perangkat itu, lalu coba lagi di sini.'**
  String get pinHostTakenBody;

  /// No description provided for @pinHostTakenNote.
  ///
  /// In id, this message translates to:
  /// **'Kalau perangkat itu memang yang dipakai, akun ini bukan admin utama venue — hubungi operator.'**
  String get pinHostTakenNote;

  /// No description provided for @pinSignOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get pinSignOut;

  /// No description provided for @pinCheckingSession.
  ///
  /// In id, this message translates to:
  /// **'Memeriksa sesi…'**
  String get pinCheckingSession;

  /// No description provided for @pinReachConnected.
  ///
  /// In id, this message translates to:
  /// **'Tersambung'**
  String get pinReachConnected;

  /// No description provided for @pinReachConnectedMs.
  ///
  /// In id, this message translates to:
  /// **'Tersambung · {ms}ms'**
  String pinReachConnectedMs(int ms);

  /// No description provided for @pinReachUnreachable.
  ///
  /// In id, this message translates to:
  /// **'Server tidak terjangkau'**
  String get pinReachUnreachable;

  /// No description provided for @pinReachChecking.
  ///
  /// In id, this message translates to:
  /// **'Memeriksa sambungan…'**
  String get pinReachChecking;

  /// No description provided for @pinServerConnected.
  ///
  /// In id, this message translates to:
  /// **'SERVER TERSAMBUNG'**
  String get pinServerConnected;

  /// No description provided for @pinChangeServer.
  ///
  /// In id, this message translates to:
  /// **'Ubah server'**
  String get pinChangeServer;

  /// No description provided for @stlModePenuh.
  ///
  /// In id, this message translates to:
  /// **'Penuh'**
  String get stlModePenuh;

  /// No description provided for @stlModePerItem.
  ///
  /// In id, this message translates to:
  /// **'Per item'**
  String get stlModePerItem;

  /// No description provided for @stlModeBagiRata.
  ///
  /// In id, this message translates to:
  /// **'Bagi rata'**
  String get stlModeBagiRata;

  /// No description provided for @stlPayTunai.
  ///
  /// In id, this message translates to:
  /// **'Tunai'**
  String get stlPayTunai;

  /// No description provided for @stlPayQris.
  ///
  /// In id, this message translates to:
  /// **'QRIS'**
  String get stlPayQris;

  /// No description provided for @stlPayKartu.
  ///
  /// In id, this message translates to:
  /// **'Kartu'**
  String get stlPayKartu;

  /// No description provided for @stlPayTransfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get stlPayTransfer;

  /// No description provided for @stlPayLainnya.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get stlPayLainnya;

  /// No description provided for @stlProofTunai.
  ///
  /// In id, this message translates to:
  /// **'Hitung uang tamu di papan pecahan'**
  String get stlProofTunai;

  /// No description provided for @stlProofQris.
  ///
  /// In id, this message translates to:
  /// **'Screenshot konfirmasi QRIS wajib dilampirkan'**
  String get stlProofQris;

  /// No description provided for @stlProofKartu.
  ///
  /// In id, this message translates to:
  /// **'Foto slip EDC — approval code terlihat'**
  String get stlProofKartu;

  /// No description provided for @stlProofTransfer.
  ///
  /// In id, this message translates to:
  /// **'Foto bukti transfer + nama pengirim'**
  String get stlProofTransfer;

  /// No description provided for @stlProofLainnya.
  ///
  /// In id, this message translates to:
  /// **'Foto bukti pembayaran'**
  String get stlProofLainnya;

  /// No description provided for @stlBlkNoLines.
  ///
  /// In id, this message translates to:
  /// **'Tagihan belum punya item'**
  String get stlBlkNoLines;

  /// No description provided for @stlBlkNothingLeft.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada sisa untuk ditagih'**
  String get stlBlkNothingLeft;

  /// No description provided for @stlBlkPickItems.
  ///
  /// In id, this message translates to:
  /// **'Pilih item dari daftar'**
  String get stlBlkPickItems;

  /// No description provided for @stlBlkNothingToCharge.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada yang bisa ditagih'**
  String get stlBlkNothingToCharge;

  /// No description provided for @stlBlkTapCash.
  ///
  /// In id, this message translates to:
  /// **'Ketuk pecahan uang yang diterima'**
  String get stlBlkTapCash;

  /// No description provided for @stlBlkAttachProof.
  ///
  /// In id, this message translates to:
  /// **'Lampirkan foto bukti bayar dulu'**
  String get stlBlkAttachProof;

  /// No description provided for @stlPhotoFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengambil foto: {error}'**
  String stlPhotoFailed(String error);

  /// No description provided for @stlTitle.
  ///
  /// In id, this message translates to:
  /// **'Penyelesaian'**
  String get stlTitle;

  /// No description provided for @stlOutstandingHint.
  ///
  /// In id, this message translates to:
  /// **'sisa yang harus ditagih'**
  String get stlOutstandingHint;

  /// No description provided for @stlRowTotal.
  ///
  /// In id, this message translates to:
  /// **'Total tagihan'**
  String get stlRowTotal;

  /// No description provided for @stlRowAlreadyPaid.
  ///
  /// In id, this message translates to:
  /// **'Sudah diterima'**
  String get stlRowAlreadyPaid;

  /// No description provided for @stlRowReceivingNow.
  ///
  /// In id, this message translates to:
  /// **'Diterima sekarang'**
  String get stlRowReceivingNow;

  /// No description provided for @stlPerItemEmpty.
  ///
  /// In id, this message translates to:
  /// **'Ketuk item yang dibayar tamu ini. Item yang sudah lunas terkunci.'**
  String get stlPerItemEmpty;

  /// No description provided for @stlRowNItems.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} item}}'**
  String stlRowNItems(int count);

  /// No description provided for @stlRowServiceTax.
  ///
  /// In id, this message translates to:
  /// **'Layanan + pajak'**
  String get stlRowServiceTax;

  /// No description provided for @stlRowPayingNow.
  ///
  /// In id, this message translates to:
  /// **'Dibayar sekarang'**
  String get stlRowPayingNow;

  /// No description provided for @stlRowRemainderAfter.
  ///
  /// In id, this message translates to:
  /// **'Sisa setelah ini'**
  String get stlRowRemainderAfter;

  /// No description provided for @stlRowPerHead.
  ///
  /// In id, this message translates to:
  /// **'Per orang (bulat 100)'**
  String get stlRowPerHead;

  /// No description provided for @stlRowOpenShares.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} bagian belum bayar}}'**
  String stlRowOpenShares(int count);

  /// No description provided for @stlRowChargeNow.
  ///
  /// In id, this message translates to:
  /// **'Tagih sekarang'**
  String get stlRowChargeNow;

  /// No description provided for @stlSplitFor.
  ///
  /// In id, this message translates to:
  /// **'Bagi untuk'**
  String get stlSplitFor;

  /// No description provided for @stlMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode'**
  String get stlMethod;

  /// No description provided for @stlLockedTo.
  ///
  /// In id, this message translates to:
  /// **'Terkunci — pembayaran sebelumnya {method}'**
  String stlLockedTo(String method);

  /// No description provided for @stlProofAttached.
  ///
  /// In id, this message translates to:
  /// **'Bukti terlampir'**
  String get stlProofAttached;

  /// No description provided for @stlRetakePhoto.
  ///
  /// In id, this message translates to:
  /// **'Ambil ulang'**
  String get stlRetakePhoto;

  /// No description provided for @stlTakePhoto.
  ///
  /// In id, this message translates to:
  /// **'Ambil foto bukti bayar'**
  String get stlTakePhoto;

  /// No description provided for @stlConfirmItems.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{Terima {count} item · {amount}}}'**
  String stlConfirmItems(int count, String amount);

  /// No description provided for @stlConfirmShare.
  ///
  /// In id, this message translates to:
  /// **'Terima bagian · {amount}'**
  String stlConfirmShare(String amount);

  /// No description provided for @stlConfirmFull.
  ///
  /// In id, this message translates to:
  /// **'Terima {amount}'**
  String stlConfirmFull(String amount);

  /// No description provided for @stlAutoPrintHint.
  ///
  /// In id, this message translates to:
  /// **'Struk tercetak otomatis setelah dikonfirmasi'**
  String get stlAutoPrintHint;

  /// No description provided for @zoneAdminTableNameHint.
  ///
  /// In id, this message translates to:
  /// **'mis. T7, Booth A'**
  String get zoneAdminTableNameHint;

  /// No description provided for @zoneAdminManageZones.
  ///
  /// In id, this message translates to:
  /// **'Kelola Zona'**
  String get zoneAdminManageZones;

  /// No description provided for @zoneAdminSummary.
  ///
  /// In id, this message translates to:
  /// **'{zones, plural, other{{zones} zona}} · {tables, plural, other{{tables} meja}} · {seats, plural, other{{seats} kursi}}'**
  String zoneAdminSummary(int zones, int tables, int seats);

  /// No description provided for @zoneAdminEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada zona. Tambah zona pertama.'**
  String get zoneAdminEmpty;

  /// No description provided for @zoneAdminMoveTablesFirst.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{Pindahkan {count} meja dulu sebelum hapus zona.}}'**
  String zoneAdminMoveTablesFirst(int count);

  /// No description provided for @zoneAdminDeleteZoneTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus zona?'**
  String get zoneAdminDeleteZoneTitle;

  /// No description provided for @zoneAdminDeleteZoneBody.
  ///
  /// In id, this message translates to:
  /// **'Zona \"{name}\" akan dihapus.'**
  String zoneAdminDeleteZoneBody(String name);

  /// No description provided for @zoneAdminNewZone.
  ///
  /// In id, this message translates to:
  /// **'Zona baru'**
  String get zoneAdminNewZone;

  /// No description provided for @zoneAdminEditZone.
  ///
  /// In id, this message translates to:
  /// **'Atur {name}'**
  String zoneAdminEditZone(String name);

  /// No description provided for @zoneAdminZoneName.
  ///
  /// In id, this message translates to:
  /// **'Nama zona'**
  String get zoneAdminZoneName;

  /// No description provided for @zoneAdminZoneNameHint.
  ///
  /// In id, this message translates to:
  /// **'mis. Teras, Bar'**
  String get zoneAdminZoneNameHint;

  /// No description provided for @zoneAdminColor.
  ///
  /// In id, this message translates to:
  /// **'Warna'**
  String get zoneAdminColor;

  /// No description provided for @zoneAdminPreview.
  ///
  /// In id, this message translates to:
  /// **'PRATINJAU'**
  String get zoneAdminPreview;

  /// No description provided for @zoneAdminNoTablesHere.
  ///
  /// In id, this message translates to:
  /// **'Belum ada meja di zona ini.'**
  String get zoneAdminNoTablesHere;

  /// No description provided for @zoneAdminTablesHere.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} meja saat ini ada di zona ini.}}'**
  String zoneAdminTablesHere(int count);

  /// No description provided for @vstIdentityHead.
  ///
  /// In id, this message translates to:
  /// **'IDENTITAS RESTORAN'**
  String get vstIdentityHead;

  /// No description provided for @vstNoLegalName.
  ///
  /// In id, this message translates to:
  /// **'Belum ada nama legal'**
  String get vstNoLegalName;

  /// No description provided for @vstNoAddress.
  ///
  /// In id, this message translates to:
  /// **'Belum ada alamat'**
  String get vstNoAddress;

  /// No description provided for @vstLegalNameHint.
  ///
  /// In id, this message translates to:
  /// **'PT …'**
  String get vstLegalNameHint;

  /// No description provided for @vstPhoneHint.
  ///
  /// In id, this message translates to:
  /// **'+62 …'**
  String get vstPhoneHint;

  /// No description provided for @vstTaglineHint.
  ///
  /// In id, this message translates to:
  /// **'mis. Kopi & Dapur'**
  String get vstTaglineHint;

  /// No description provided for @vstHeaderHint.
  ///
  /// In id, this message translates to:
  /// **'Tampil di atas struk'**
  String get vstHeaderHint;

  /// No description provided for @vstSocialHint.
  ///
  /// In id, this message translates to:
  /// **'@instagram · wa.me/…'**
  String get vstSocialHint;

  /// No description provided for @vstFooterHint.
  ///
  /// In id, this message translates to:
  /// **'Tampil di bawah struk'**
  String get vstFooterHint;

  /// No description provided for @vstThankYouHint.
  ///
  /// In id, this message translates to:
  /// **'Terima kasih'**
  String get vstThankYouHint;

  /// No description provided for @vstQrUrlHint.
  ///
  /// In id, this message translates to:
  /// **'https://… (hanya struk uang)'**
  String get vstQrUrlHint;

  /// No description provided for @vstQrCaptionHint.
  ///
  /// In id, this message translates to:
  /// **'mis. Ulas kami di Google'**
  String get vstQrCaptionHint;

  /// No description provided for @vstNotSet.
  ///
  /// In id, this message translates to:
  /// **'Belum diisi'**
  String get vstNotSet;

  /// No description provided for @vstReportsStartAt.
  ///
  /// In id, this message translates to:
  /// **'Mulai {hour}:00'**
  String vstReportsStartAt(String hour);

  /// No description provided for @vstTaxOn.
  ///
  /// In id, this message translates to:
  /// **'{pct} PPN'**
  String vstTaxOn(String pct);

  /// No description provided for @vstTaxOff.
  ///
  /// In id, this message translates to:
  /// **'PPN off'**
  String get vstTaxOff;

  /// No description provided for @vstServiceOff.
  ///
  /// In id, this message translates to:
  /// **'Layanan off'**
  String get vstServiceOff;

  /// No description provided for @vstServiceValue.
  ///
  /// In id, this message translates to:
  /// **'Layanan {value}'**
  String vstServiceValue(String value);

  /// No description provided for @vstFeesTag.
  ///
  /// In id, this message translates to:
  /// **'BIAYA'**
  String get vstFeesTag;

  /// No description provided for @vstEnableTax.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan PPN'**
  String get vstEnableTax;

  /// No description provided for @vstTaxRate.
  ///
  /// In id, this message translates to:
  /// **'Tarif PPN'**
  String get vstTaxRate;

  /// No description provided for @vstEnableService.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan layanan'**
  String get vstEnableService;

  /// No description provided for @vstServiceRate.
  ///
  /// In id, this message translates to:
  /// **'Tarif layanan'**
  String get vstServiceRate;

  /// No description provided for @vstServiceAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah layanan'**
  String get vstServiceAmount;

  /// No description provided for @vstTaxAfterDiscount.
  ///
  /// In id, this message translates to:
  /// **'Pajak dihitung setelah diskon'**
  String get vstTaxAfterDiscount;

  /// No description provided for @vstTaxAfterDiscountOn.
  ///
  /// In id, this message translates to:
  /// **'Diskon mengurangi dasar pengenaan — pajak & layanan dihitung dari jumlah setelah diskon.'**
  String get vstTaxAfterDiscountOn;

  /// No description provided for @vstTaxAfterDiscountOff.
  ///
  /// In id, this message translates to:
  /// **'Pajak & layanan dihitung dari subtotal kotor, diskon dipotong dari total akhir.'**
  String get vstTaxAfterDiscountOff;

  /// No description provided for @vstItemDiscountNote.
  ///
  /// In id, this message translates to:
  /// **'Diskon per item selalu dihitung sebelum pajak.'**
  String get vstItemDiscountNote;

  /// No description provided for @vstDiscountPresets.
  ///
  /// In id, this message translates to:
  /// **'Preset diskon'**
  String get vstDiscountPresets;

  /// No description provided for @vstFeeType.
  ///
  /// In id, this message translates to:
  /// **'Tipe biaya'**
  String get vstFeeType;

  /// No description provided for @vstFeePercent.
  ///
  /// In id, this message translates to:
  /// **'Persen'**
  String get vstFeePercent;

  /// No description provided for @vstFeeFixed.
  ///
  /// In id, this message translates to:
  /// **'Tetap'**
  String get vstFeeFixed;

  /// No description provided for @vstReportsTag.
  ///
  /// In id, this message translates to:
  /// **'LAPORAN'**
  String get vstReportsTag;

  /// No description provided for @vstBusinessDayStart.
  ///
  /// In id, this message translates to:
  /// **'Jam mulai hari kerja'**
  String get vstBusinessDayStart;

  /// No description provided for @vstBusinessDayStartHint.
  ///
  /// In id, this message translates to:
  /// **'Pengelompokan laporan \"Hari ini\"'**
  String get vstBusinessDayStartHint;

  /// No description provided for @tkwFallbackLabel.
  ///
  /// In id, this message translates to:
  /// **'Bawa pulang'**
  String get tkwFallbackLabel;

  /// No description provided for @tkwItemCount.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} ITEM}}'**
  String tkwItemCount(int count);

  /// No description provided for @tkwHandedOverTag.
  ///
  /// In id, this message translates to:
  /// **'SUDAH DISERAHKAN'**
  String get tkwHandedOverTag;

  /// No description provided for @tkwEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada item.'**
  String get tkwEmpty;

  /// No description provided for @tkwServeFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal sajikan: {error}'**
  String tkwServeFailed(String error);

  /// No description provided for @tkwBillLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat tagihan: {error}'**
  String tkwBillLoadFailed(String error);

  /// No description provided for @tkwErrNotTerminal.
  ///
  /// In id, this message translates to:
  /// **'Masih ada item yang dimasak — tunggu siap dulu.'**
  String get tkwErrNotTerminal;

  /// No description provided for @tkwErrNoTickets.
  ///
  /// In id, this message translates to:
  /// **'Belum ada item untuk diserahkan.'**
  String get tkwErrNoTickets;

  /// No description provided for @tkwHandoverFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyerahkan: {error}'**
  String tkwHandoverFailed(String error);

  /// No description provided for @tkwHandover.
  ///
  /// In id, this message translates to:
  /// **'Serahkan'**
  String get tkwHandover;

  /// No description provided for @tkwHandoverBlocked.
  ///
  /// In id, this message translates to:
  /// **'Bisa diserahkan setelah semua item siap/disajikan.'**
  String get tkwHandoverBlocked;

  /// No description provided for @tkwHandedOver.
  ///
  /// In id, this message translates to:
  /// **'Sudah diserahkan ke tamu.'**
  String get tkwHandedOver;

  /// No description provided for @mvtTitle.
  ///
  /// In id, this message translates to:
  /// **'Pindahkan meja {table}'**
  String mvtTitle(String table);

  /// No description provided for @mvtSubtitle.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{Pilih meja kosong tujuan · {count} tamu}}'**
  String mvtSubtitle(int count);

  /// No description provided for @mvtNoTargets.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada meja kosong untuk dituju.'**
  String get mvtNoTargets;

  /// No description provided for @tblCapacityOf.
  ///
  /// In id, this message translates to:
  /// **'kapasitas {count}'**
  String tblCapacityOf(int count);

  /// No description provided for @mvtConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Pindahkan meja {table}?'**
  String mvtConfirmTitle(String table);

  /// No description provided for @mvtConfirmOver.
  ///
  /// In id, this message translates to:
  /// **'Tujuan: meja {table} (kapasitas {capacity}). {pax, plural, other{{pax} tamu}} melebihi kapasitas — lanjutkan?'**
  String mvtConfirmOver(String table, int capacity, int pax);

  /// No description provided for @mvtConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'Seluruh pesanan dan tamu pindah ke meja {table}.'**
  String mvtConfirmBody(String table);

  /// No description provided for @mvtConfirmAction.
  ///
  /// In id, this message translates to:
  /// **'Pindahkan'**
  String get mvtConfirmAction;

  /// No description provided for @mvtFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memindahkan meja: {error}'**
  String mvtFailed(String error);

  /// No description provided for @asgTitle.
  ///
  /// In id, this message translates to:
  /// **'Tetapkan ke meja'**
  String get asgTitle;

  /// No description provided for @asgSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Atur tamu lalu pilih meja kosong'**
  String get asgSubtitle;

  /// No description provided for @asgGuestNameHint.
  ///
  /// In id, this message translates to:
  /// **'Nama tamu (opsional)'**
  String get asgGuestNameHint;

  /// No description provided for @asgNoTargets.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada meja kosong.'**
  String get asgNoTargets;

  /// No description provided for @gstTableLabel.
  ///
  /// In id, this message translates to:
  /// **'Meja {table}'**
  String gstTableLabel(String table);

  /// No description provided for @gstTitle.
  ///
  /// In id, this message translates to:
  /// **'Atur jumlah tamu'**
  String get gstTitle;

  /// No description provided for @gstWaiterOnly.
  ///
  /// In id, this message translates to:
  /// **'Hanya pelayan yang bisa mengubah jumlah tamu.'**
  String get gstWaiterOnly;

  /// No description provided for @kitQueueSub.
  ///
  /// In id, this message translates to:
  /// **'{orders} ORDER · {items} ITEM DI ANTRIAN PERSIAPAN'**
  String kitQueueSub(int orders, int items);

  /// No description provided for @kitShowDone.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan order selesai'**
  String get kitShowDone;

  /// No description provided for @kitSentAt.
  ///
  /// In id, this message translates to:
  /// **'masuk {time}'**
  String kitSentAt(String time);

  /// No description provided for @kitAllReady.
  ///
  /// In id, this message translates to:
  /// **'Semua siap'**
  String get kitAllReady;

  /// No description provided for @kitReadyOf.
  ///
  /// In id, this message translates to:
  /// **'{done}/{total} siap'**
  String kitReadyOf(int done, int total);

  /// No description provided for @kitHoldToFinish.
  ///
  /// In id, this message translates to:
  /// **'Tahan untuk tandai selesai'**
  String get kitHoldToFinish;

  /// No description provided for @kitEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Antrian masak kosong'**
  String get kitEmptyTitle;

  /// No description provided for @kitEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Semua pesanan dapur sudah selesai dimasak.'**
  String get kitEmptyBody;

  /// No description provided for @liaTableAt.
  ///
  /// In id, this message translates to:
  /// **'MEJA {table} · {time}'**
  String liaTableAt(String table, String time);

  /// No description provided for @liaTapOutside.
  ///
  /// In id, this message translates to:
  /// **'Tap luar sheet untuk batal.'**
  String get liaTapOutside;

  /// No description provided for @liaVoidWarning.
  ///
  /// In id, this message translates to:
  /// **'Pembatalan dicatat dengan sign-in kamu dan alasannya — terlihat di laporan dan catatan audit.'**
  String get liaVoidWarning;

  /// No description provided for @liaVoided.
  ///
  /// In id, this message translates to:
  /// **'Item dibatalkan'**
  String get liaVoided;

  /// No description provided for @liaVoidedNote.
  ///
  /// In id, this message translates to:
  /// **'Tercatat: ×{qty} {name} · atas nama kamu · terlihat di laporan'**
  String liaVoidedNote(int qty, String name);

  /// No description provided for @resDaySummary.
  ///
  /// In id, this message translates to:
  /// **'{day} · {bookings, plural, other{{bookings} booking}} · {covers, plural, other{{covers} tamu}}'**
  String resDaySummary(String day, int bookings, int covers);

  /// No description provided for @resNoTableForParty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada meja kapasitas ≥ {size} di zona ini.'**
  String resNoTableForParty(int size);

  /// No description provided for @resAlreadySeated.
  ///
  /// In id, this message translates to:
  /// **'Meja sudah diisi tamu lain'**
  String get resAlreadySeated;

  /// No description provided for @resSeatFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal duduk: {error}'**
  String resSeatFailed(String error);

  /// No description provided for @resNewBooking.
  ///
  /// In id, this message translates to:
  /// **'Reservasi baru'**
  String get resNewBooking;

  /// No description provided for @resGuestName.
  ///
  /// In id, this message translates to:
  /// **'Nama tamu'**
  String get resGuestName;

  /// No description provided for @resPhone.
  ///
  /// In id, this message translates to:
  /// **'No. HP'**
  String get resPhone;

  /// No description provided for @resOptional.
  ///
  /// In id, this message translates to:
  /// **'opsional'**
  String get resOptional;

  /// No description provided for @resPartySize.
  ///
  /// In id, this message translates to:
  /// **'Jumlah tamu'**
  String get resPartySize;

  /// No description provided for @resSaveFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal simpan: {error}'**
  String resSaveFailed(String error);

  /// No description provided for @prnPick.
  ///
  /// In id, this message translates to:
  /// **'Pilih printer'**
  String get prnPick;

  /// No description provided for @prnNoneOnline.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada printer online. Tambah manual, atau pair printer Bluetooth di Pengaturan dulu.'**
  String get prnNoneOnline;

  /// No description provided for @prnAddWifi.
  ///
  /// In id, this message translates to:
  /// **'Tambah printer Wi-Fi'**
  String get prnAddWifi;

  /// No description provided for @prnLabel.
  ///
  /// In id, this message translates to:
  /// **'Label'**
  String get prnLabel;

  /// No description provided for @prnHost.
  ///
  /// In id, this message translates to:
  /// **'Host (IP)'**
  String get prnHost;

  /// No description provided for @prnPort.
  ///
  /// In id, this message translates to:
  /// **'Port'**
  String get prnPort;

  /// No description provided for @prnScopeVenue.
  ///
  /// In id, this message translates to:
  /// **'Venue'**
  String get prnScopeVenue;

  /// No description provided for @prnScopeDevice.
  ///
  /// In id, this message translates to:
  /// **'Alat ini'**
  String get prnScopeDevice;

  /// No description provided for @dscNoPresetsTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada preset diskon'**
  String get dscNoPresetsTitle;

  /// No description provided for @dscNoPresetsLine.
  ///
  /// In id, this message translates to:
  /// **'Belum ada preset diskon per item. Tambahkan di Pengaturan venue › Diskon.'**
  String get dscNoPresetsLine;

  /// No description provided for @dscNoPresetsBill.
  ///
  /// In id, this message translates to:
  /// **'Belum ada preset diskon tagihan. Tambahkan di Pengaturan venue › Diskon.'**
  String get dscNoPresetsBill;

  /// No description provided for @dscNoPresetsReceipt.
  ///
  /// In id, this message translates to:
  /// **'Belum ada preset diskon per pesanan. Tambahkan di Pengaturan venue › Diskon.'**
  String get dscNoPresetsReceipt;

  /// No description provided for @dscSheetTitle.
  ///
  /// In id, this message translates to:
  /// **'Diskon · {target}'**
  String dscSheetTitle(String target);

  /// No description provided for @dscApproverTitle.
  ///
  /// In id, this message translates to:
  /// **'Persetujuan manajer'**
  String get dscApproverTitle;

  /// No description provided for @dscApproverBody.
  ///
  /// In id, this message translates to:
  /// **'Diskon perlu disetujui manajer. Minta manajer memasukkan PIN.'**
  String get dscApproverBody;

  /// No description provided for @dscAppliesLine.
  ///
  /// In id, this message translates to:
  /// **'Berlaku untuk item ini'**
  String get dscAppliesLine;

  /// No description provided for @dscAppliesBill.
  ///
  /// In id, this message translates to:
  /// **'Berlaku seluruh tagihan · semua struk'**
  String get dscAppliesBill;

  /// No description provided for @dscAppliesReceipt.
  ///
  /// In id, this message translates to:
  /// **'Berlaku seluruh struk'**
  String get dscAppliesReceipt;

  /// No description provided for @ordServeFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal sajikan: {error}'**
  String ordServeFailed(String error);

  /// No description provided for @ordSummary.
  ///
  /// In id, this message translates to:
  /// **'{active} berjalan · {ready} siap diambil'**
  String ordSummary(int active, int ready);

  /// No description provided for @ordUnderMin.
  ///
  /// In id, this message translates to:
  /// **'<1m'**
  String get ordUnderMin;

  /// No description provided for @ordSince.
  ///
  /// In id, this message translates to:
  /// **'sejak {time}'**
  String ordSince(String time);

  /// No description provided for @cshTitle.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get cshTitle;

  /// No description provided for @cshSummary.
  ///
  /// In id, this message translates to:
  /// **'{running, plural, other{{running} tagihan}} berjalan · {takeaway} tanpa meja · {settled} lunas'**
  String cshSummary(int running, int takeaway, int settled);

  /// No description provided for @cshUnbilled.
  ///
  /// In id, this message translates to:
  /// **'Belum tertagih'**
  String get cshUnbilled;

  /// No description provided for @rtoReadyAtPass.
  ///
  /// In id, this message translates to:
  /// **'Siap di pass · {what}'**
  String rtoReadyAtPass(String what);

  /// No description provided for @rtoPickUp.
  ///
  /// In id, this message translates to:
  /// **'Ambil'**
  String get rtoPickUp;

  /// No description provided for @crsTitle.
  ///
  /// In id, this message translates to:
  /// **'RENTANG KHUSUS'**
  String get crsTitle;

  /// No description provided for @crsFrom.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get crsFrom;

  /// No description provided for @crsTo.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get crsTo;

  /// No description provided for @crsApply.
  ///
  /// In id, this message translates to:
  /// **'Terapkan'**
  String get crsApply;

  /// No description provided for @exitAgainToQuit.
  ///
  /// In id, this message translates to:
  /// **'Tekan kembali lagi untuk keluar'**
  String get exitAgainToQuit;

  /// No description provided for @olcVoidedBy.
  ///
  /// In id, this message translates to:
  /// **'Dibatalkan · {reason} · disetujui oleh {approver}'**
  String olcVoidedBy(String reason, String approver);

  /// No description provided for @rdyBannerText.
  ///
  /// In id, this message translates to:
  /// **'Item siap diambil di pass — tandai disajikan di bawah'**
  String get rdyBannerText;

  /// No description provided for @ppfTitle.
  ///
  /// In id, this message translates to:
  /// **'Bukti pembayaran'**
  String get ppfTitle;

  /// No description provided for @ppfUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Foto bukti tidak bisa dimuat'**
  String get ppfUnavailable;

  /// No description provided for @cpdTitle.
  ///
  /// In id, this message translates to:
  /// **'Uang tamu · ketuk pecahan'**
  String get cpdTitle;

  /// No description provided for @blcPaidPct.
  ///
  /// In id, this message translates to:
  /// **'{amount} masuk · {pct}%'**
  String blcPaidPct(String amount, String pct);

  /// No description provided for @tblDetailEmptyLines.
  ///
  /// In id, this message translates to:
  /// **'Belum ada item — ketuk Tambah pesanan di kanan untuk mulai.'**
  String get tblDetailEmptyLines;

  /// No description provided for @tblNoTablesInZone.
  ///
  /// In id, this message translates to:
  /// **'Belum ada meja di {zone}'**
  String tblNoTablesInZone(String zone);

  /// No description provided for @ownMoneyAuditTitle.
  ///
  /// In id, this message translates to:
  /// **'Catatan uang'**
  String get ownMoneyAuditTitle;

  /// No description provided for @ownMoneyAuditEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada aktivitas yang menyentuh uang pada rentang ini.'**
  String get ownMoneyAuditEmpty;

  /// No description provided for @ownMoneyAuditTruncated.
  ///
  /// In id, this message translates to:
  /// **'Menampilkan {count} terbaru — catatan lengkap ada di perangkat venue'**
  String ownMoneyAuditTruncated(int count);

  /// No description provided for @ownReportTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan Venue'**
  String get ownReportTitle;

  /// No description provided for @altMinutes.
  ///
  /// In id, this message translates to:
  /// **'{value} min'**
  String altMinutes(int value);

  /// No description provided for @vhbSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get vhbSettings;

  /// No description provided for @mnaItemCount.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} item}}'**
  String mnaItemCount(int count);

  /// No description provided for @cmnStationsLive.
  ///
  /// In id, this message translates to:
  /// **'STATIONS · LIVE'**
  String get cmnStationsLive;

  /// No description provided for @modSpecialCounter.
  ///
  /// In id, this message translates to:
  /// **'{used} / 80 · tampil ke dapur'**
  String modSpecialCounter(int used);

  /// No description provided for @zonSeatsCount.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} kursi}}'**
  String zonSeatsCount(int count);

  /// No description provided for @zonTablesCount.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} meja}}'**
  String zonTablesCount(int count);

  /// No description provided for @stfPinIs.
  ///
  /// In id, this message translates to:
  /// **'PIN {pin}'**
  String stfPinIs(String pin);

  /// No description provided for @onbPickMode.
  ///
  /// In id, this message translates to:
  /// **'Pilih mode'**
  String get onbPickMode;

  /// No description provided for @onbPickModeSub.
  ///
  /// In id, this message translates to:
  /// **'Tablet ini akan jadi server atau klien?'**
  String get onbPickModeSub;

  /// No description provided for @fbdNoAccess.
  ///
  /// In id, this message translates to:
  /// **'Akses tidak diizinkan'**
  String get fbdNoAccess;

  /// No description provided for @rptLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat laporan'**
  String get rptLoadFailed;

  /// No description provided for @rptStockFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat laporan bahan: {error}'**
  String rptStockFailed(String error);

  /// No description provided for @rptStockEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada aktivitas bahan pada rentang ini.'**
  String get rptStockEmpty;

  /// No description provided for @fltLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat fleet'**
  String get fltLoadFailed;

  /// No description provided for @fltNewVenue.
  ///
  /// In id, this message translates to:
  /// **'Venue baru'**
  String get fltNewVenue;

  /// No description provided for @fltOfflineNote.
  ///
  /// In id, this message translates to:
  /// **'Tidak terhubung — data tersimpan, bisa sudah berubah. Perubahan dinonaktifkan sampai tersambung.'**
  String get fltOfflineNote;

  /// No description provided for @sntTitle.
  ///
  /// In id, this message translates to:
  /// **'Terkirim'**
  String get sntTitle;

  /// No description provided for @sntBody.
  ///
  /// In id, this message translates to:
  /// **'Pesanan Meja {table} sudah live di display dapur dan bar.'**
  String sntBody(String table);

  /// No description provided for @sntLatency.
  ///
  /// In id, this message translates to:
  /// **'LAN P50 {ms}MS · CLOUD QUEUED'**
  String sntLatency(String ms);

  /// No description provided for @meShiftLine.
  ///
  /// In id, this message translates to:
  /// **'MULAI {start} · {elapsed} BERJALAN'**
  String meShiftLine(String start, String elapsed);

  /// No description provided for @meNoShift.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada shift berjalan'**
  String get meNoShift;

  /// No description provided for @meAuditEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada entri audit. Pembatalan, comp, dan perubahan pasca-kirim muncul di sini.'**
  String get meAuditEmpty;

  /// No description provided for @meAuditCount.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} entri}}'**
  String meAuditCount(int count);

  /// No description provided for @meRecentActivity.
  ///
  /// In id, this message translates to:
  /// **'Aktivitas terkini'**
  String get meRecentActivity;

  /// No description provided for @pinDebugSeeded.
  ///
  /// In id, this message translates to:
  /// **'DEBUG · SEEDED PINS'**
  String get pinDebugSeeded;

  /// No description provided for @pinCopied.
  ///
  /// In id, this message translates to:
  /// **'Disalin: {label}'**
  String pinCopied(String label);

  /// No description provided for @fveLapsedNote.
  ///
  /// In id, this message translates to:
  /// **'Langganan sudah lewat batas. Perpanjang dulu di bawah sebelum venue bisa diaktifkan.'**
  String get fveLapsedNote;

  /// No description provided for @fveManyAdmins.
  ///
  /// In id, this message translates to:
  /// **'Venue ini punya {count, plural, other{{count} admin aktif}}. Satu venue kini hanya boleh punya satu admin aktif — tangguhkan yang lain, sisakan akun di perangkat yang memegang data venue. Admin yang tersisa aktif tidak akan bisa masuk.'**
  String fveManyAdmins(int count);

  /// No description provided for @fveLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat: {error}'**
  String fveLoadFailed(String error);

  /// No description provided for @fveAtCapNote.
  ///
  /// In id, this message translates to:
  /// **'Satu venue, satu admin aktif. Untuk mengganti admin: tangguhkan yang lama dulu, lalu tambah yang baru.'**
  String get fveAtCapNote;

  /// No description provided for @fveDangerZone.
  ///
  /// In id, this message translates to:
  /// **'ZONA BAHAYA'**
  String get fveDangerZone;

  /// No description provided for @fveDeleteBlocked.
  ///
  /// In id, this message translates to:
  /// **'Hapus semua akun venue ini dulu sebelum menghapus venue. Untuk sekadar memutus akses, pakai Tangguhkan di atas.'**
  String get fveDeleteBlocked;

  /// No description provided for @fveDeleteWarning.
  ///
  /// In id, this message translates to:
  /// **'Menghapus venue tidak dapat dibatalkan. Untuk sekadar memutus akses, pakai Tangguhkan di atas.'**
  String get fveDeleteWarning;

  /// No description provided for @fveAnnual.
  ///
  /// In id, this message translates to:
  /// **'Bayar tahunan'**
  String get fveAnnual;

  /// No description provided for @fveAnnualNoPrice.
  ///
  /// In id, this message translates to:
  /// **'Hemat 2 bulan — isi harga bulanan dulu.'**
  String get fveAnnualNoPrice;

  /// No description provided for @fveAnnualPrice.
  ///
  /// In id, this message translates to:
  /// **'{amount} per tahun — hemat 2 bulan.'**
  String fveAnnualPrice(String amount);

  /// No description provided for @fveNoCutoff.
  ///
  /// In id, this message translates to:
  /// **'Tanpa tanggal, langganan tidak pernah habis dan venue tidak ditangguhkan otomatis.'**
  String get fveNoCutoff;

  /// No description provided for @fveAddPrincipal.
  ///
  /// In id, this message translates to:
  /// **'Tambah {role} · {venue}'**
  String fveAddPrincipal(String role, String venue);

  /// No description provided for @rtoNow.
  ///
  /// In id, this message translates to:
  /// **'SEKARANG'**
  String get rtoNow;

  /// No description provided for @rtoTableNow.
  ///
  /// In id, this message translates to:
  /// **'MEJA {table} · {zone} · SEKARANG'**
  String rtoTableNow(String table, String zone);

  /// No description provided for @olcMarkServed.
  ///
  /// In id, this message translates to:
  /// **'Tandai disajikan'**
  String get olcMarkServed;

  /// No description provided for @dscManagerPin.
  ///
  /// In id, this message translates to:
  /// **'PIN manajer'**
  String get dscManagerPin;

  /// No description provided for @dscApprove.
  ///
  /// In id, this message translates to:
  /// **'Setujui'**
  String get dscApprove;

  /// No description provided for @cpdExact.
  ///
  /// In id, this message translates to:
  /// **'Pas'**
  String get cpdExact;

  /// No description provided for @cpdClear.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan'**
  String get cpdClear;

  /// No description provided for @cpdNoteSemantics.
  ///
  /// In id, this message translates to:
  /// **'{label}, {count, plural, other{{count} lembar}}'**
  String cpdNoteSemantics(String label, int count);

  /// No description provided for @cpdReceived.
  ///
  /// In id, this message translates to:
  /// **'Diterima'**
  String get cpdReceived;

  /// No description provided for @cpdShort.
  ///
  /// In id, this message translates to:
  /// **'Masih kurang'**
  String get cpdShort;

  /// No description provided for @cpdChange.
  ///
  /// In id, this message translates to:
  /// **'Kembalian'**
  String get cpdChange;

  /// No description provided for @blcNoName.
  ///
  /// In id, this message translates to:
  /// **'Tanpa nama'**
  String get blcNoName;

  /// No description provided for @blcPaxCount.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} tamu}}'**
  String blcPaxCount(int count);

  /// No description provided for @blcCaptionPaid.
  ///
  /// In id, this message translates to:
  /// **'total dibayar'**
  String get blcCaptionPaid;

  /// No description provided for @blcCaptionOutstanding.
  ///
  /// In id, this message translates to:
  /// **'sisa tagihan'**
  String get blcCaptionOutstanding;

  /// No description provided for @blcCaptionWriteOff.
  ///
  /// In id, this message translates to:
  /// **'tak tertagih'**
  String get blcCaptionWriteOff;

  /// No description provided for @blcVerbIn.
  ///
  /// In id, this message translates to:
  /// **'masuk'**
  String get blcVerbIn;

  /// No description provided for @blcVerbSeated.
  ///
  /// In id, this message translates to:
  /// **'duduk'**
  String get blcVerbSeated;

  /// No description provided for @blcVerbClosed.
  ///
  /// In id, this message translates to:
  /// **'tutup'**
  String get blcVerbClosed;

  /// No description provided for @blcSeeReceipt.
  ///
  /// In id, this message translates to:
  /// **'Lihat struk'**
  String get blcSeeReceipt;

  /// No description provided for @blcCharge.
  ///
  /// In id, this message translates to:
  /// **'Tagih'**
  String get blcCharge;

  /// No description provided for @blcPillSettled.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get blcPillSettled;

  /// No description provided for @blcPillPartial.
  ///
  /// In id, this message translates to:
  /// **'Sebagian'**
  String get blcPillPartial;

  /// No description provided for @blcPillWriteOff.
  ///
  /// In id, this message translates to:
  /// **'Tak tertagih'**
  String get blcPillWriteOff;

  /// No description provided for @blcPillUnpaid.
  ///
  /// In id, this message translates to:
  /// **'belum bayar'**
  String get blcPillUnpaid;

  /// No description provided for @blcSemantics.
  ///
  /// In id, this message translates to:
  /// **'{label}, {state}, {amount}'**
  String blcSemantics(String label, String state, String amount);

  /// No description provided for @blcSinceChip.
  ///
  /// In id, this message translates to:
  /// **'{verb} {elapsed}'**
  String blcSinceChip(String verb, String elapsed);

  /// No description provided for @blcTableClosed.
  ///
  /// In id, this message translates to:
  /// **'Meja ditutup'**
  String get blcTableClosed;

  /// No description provided for @blcEvenSplit.
  ///
  /// In id, this message translates to:
  /// **'Bagi {shares} · {paid} bayar'**
  String blcEvenSplit(int shares, int paid);

  /// No description provided for @blcPrepaid.
  ///
  /// In id, this message translates to:
  /// **'Prabayar aplikasi'**
  String get blcPrepaid;

  /// No description provided for @cshLoadFailedTitle.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat tagihan'**
  String get cshLoadFailedTitle;

  /// No description provided for @cshPullToRetry.
  ///
  /// In id, this message translates to:
  /// **'Tarik untuk coba lagi.'**
  String get cshPullToRetry;

  /// No description provided for @cshEmptyDetached.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada meja tertutup yang belum lunas'**
  String get cshEmptyDetached;

  /// No description provided for @cshEmptyOpen.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada tagihan terbuka'**
  String get cshEmptyOpen;

  /// No description provided for @cshEmptySettledToday.
  ///
  /// In id, this message translates to:
  /// **'Belum ada tagihan lunas hari ini'**
  String get cshEmptySettledToday;

  /// No description provided for @cshEmptySettled7d.
  ///
  /// In id, this message translates to:
  /// **'Belum ada tagihan lunas 7 hari terakhir'**
  String get cshEmptySettled7d;

  /// No description provided for @cshEmptyAll.
  ///
  /// In id, this message translates to:
  /// **'Belum ada tagihan'**
  String get cshEmptyAll;

  /// No description provided for @cshStatUnpaid.
  ///
  /// In id, this message translates to:
  /// **'Belum bayar'**
  String get cshStatUnpaid;

  /// No description provided for @cshStatPartial.
  ///
  /// In id, this message translates to:
  /// **'Sebagian'**
  String get cshStatPartial;

  /// No description provided for @cshStatReceived.
  ///
  /// In id, this message translates to:
  /// **'Sudah diterima'**
  String get cshStatReceived;

  /// No description provided for @cshStatClosed.
  ///
  /// In id, this message translates to:
  /// **'Meja ditutup'**
  String get cshStatClosed;

  /// No description provided for @cshSegNeedCharge.
  ///
  /// In id, this message translates to:
  /// **'Perlu ditagih'**
  String get cshSegNeedCharge;

  /// No description provided for @cshSegSettled.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get cshSegSettled;

  /// No description provided for @cshSegAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get cshSegAll;

  /// No description provided for @cshRangeToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get cshRangeToday;

  /// No description provided for @cshRange7d.
  ///
  /// In id, this message translates to:
  /// **'7 hari'**
  String get cshRange7d;

  /// No description provided for @fltActive.
  ///
  /// In id, this message translates to:
  /// **'AKTIF'**
  String get fltActive;

  /// No description provided for @fltSuspended.
  ///
  /// In id, this message translates to:
  /// **'TANGGUH'**
  String get fltSuspended;

  /// No description provided for @fltConsoleTitle.
  ///
  /// In id, this message translates to:
  /// **'Fleet'**
  String get fltConsoleTitle;

  /// No description provided for @fltSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau alamat'**
  String get fltSearchHint;

  /// No description provided for @fltEmptyNoVenue.
  ///
  /// In id, this message translates to:
  /// **'Belum ada venue'**
  String get fltEmptyNoVenue;

  /// No description provided for @fltEmptyNoMatch.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada yang cocok'**
  String get fltEmptyNoMatch;

  /// No description provided for @fltVenueActions.
  ///
  /// In id, this message translates to:
  /// **'Tindakan venue'**
  String get fltVenueActions;

  /// No description provided for @fltVenueName.
  ///
  /// In id, this message translates to:
  /// **'Nama venue'**
  String get fltVenueName;

  /// No description provided for @fltVenueAdmin.
  ///
  /// In id, this message translates to:
  /// **'Admin venue'**
  String get fltVenueAdmin;

  /// No description provided for @fltOwner.
  ///
  /// In id, this message translates to:
  /// **'Pemilik'**
  String get fltOwner;

  /// No description provided for @fltVenueAccess.
  ///
  /// In id, this message translates to:
  /// **'Akses venue'**
  String get fltVenueAccess;

  /// No description provided for @fltSuspend.
  ///
  /// In id, this message translates to:
  /// **'Tangguhkan'**
  String get fltSuspend;

  /// No description provided for @fltSubscription.
  ///
  /// In id, this message translates to:
  /// **'Langganan'**
  String get fltSubscription;

  /// No description provided for @fltStartTrial.
  ///
  /// In id, this message translates to:
  /// **'Mulai coba'**
  String get fltStartTrial;

  /// No description provided for @fltPricePerMonth.
  ///
  /// In id, this message translates to:
  /// **'Harga per bulan'**
  String get fltPricePerMonth;

  /// No description provided for @fltAccountActions.
  ///
  /// In id, this message translates to:
  /// **'Tindakan akun'**
  String get fltAccountActions;

  /// No description provided for @fltSendWa.
  ///
  /// In id, this message translates to:
  /// **'Kirim WA'**
  String get fltSendWa;

  /// No description provided for @fltDeleteVenue.
  ///
  /// In id, this message translates to:
  /// **'Hapus venue'**
  String get fltDeleteVenue;

  /// No description provided for @fltClearDate.
  ///
  /// In id, this message translates to:
  /// **'Hapus tanggal'**
  String get fltClearDate;

  /// No description provided for @fltPickDate.
  ///
  /// In id, this message translates to:
  /// **'Pilih'**
  String get fltPickDate;

  /// No description provided for @fltInitialPassword.
  ///
  /// In id, this message translates to:
  /// **'Password awal'**
  String get fltInitialPassword;

  /// No description provided for @ordReadyForPickup.
  ///
  /// In id, this message translates to:
  /// **'Siap diambil'**
  String get ordReadyForPickup;

  /// No description provided for @ordPreparing.
  ///
  /// In id, this message translates to:
  /// **'Disiapkan'**
  String get ordPreparing;

  /// No description provided for @ordDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get ordDone;

  /// No description provided for @ordTabMine.
  ///
  /// In id, this message translates to:
  /// **'Milik saya'**
  String get ordTabMine;

  /// No description provided for @ordServe.
  ///
  /// In id, this message translates to:
  /// **'Sajikan'**
  String get ordServe;

  /// No description provided for @meKpiOpenTickets.
  ///
  /// In id, this message translates to:
  /// **'Tiket terbuka'**
  String get meKpiOpenTickets;

  /// No description provided for @meKpiCovers.
  ///
  /// In id, this message translates to:
  /// **'Cover dilayani'**
  String get meKpiCovers;

  /// No description provided for @meSignOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get meSignOut;

  /// No description provided for @liaFireNow.
  ///
  /// In id, this message translates to:
  /// **'Bakar sekarang'**
  String get liaFireNow;

  /// No description provided for @liaEditItem.
  ///
  /// In id, this message translates to:
  /// **'Ubah item'**
  String get liaEditItem;

  /// No description provided for @liaUnserve.
  ///
  /// In id, this message translates to:
  /// **'Batalkan sajian'**
  String get liaUnserve;

  /// No description provided for @liaVoidItem.
  ///
  /// In id, this message translates to:
  /// **'Batalkan item'**
  String get liaVoidItem;

  /// No description provided for @liaVoidReasonHint.
  ///
  /// In id, this message translates to:
  /// **'Wajib — jelaskan alasan pembatalan'**
  String get liaVoidReasonHint;

  /// No description provided for @fltEmptyNoVenueBody.
  ///
  /// In id, this message translates to:
  /// **'Buat venue pertama dengan \"Venue baru\", lalu tambahkan admin-nya dari dalam venue itu.'**
  String get fltEmptyNoVenueBody;

  /// No description provided for @fltEmptyLensBody.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada venue di lensa \"{lens}\".'**
  String fltEmptyLensBody(String lens);

  /// No description provided for @fltEmptyQueryBody.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada venue cocok \"{query}\".'**
  String fltEmptyQueryBody(String query);

  /// No description provided for @fltEmptyQueryLensBody.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada venue cocok \"{query}\" di lensa \"{lens}\".'**
  String fltEmptyQueryLensBody(String query, String lens);

  /// No description provided for @fltLensTrouble.
  ///
  /// In id, this message translates to:
  /// **'Perlu tindakan'**
  String get fltLensTrouble;

  /// No description provided for @fltLensBilling.
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get fltLensBilling;

  /// No description provided for @fltLensOff.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get fltLensOff;

  /// No description provided for @fltKicker.
  ///
  /// In id, this message translates to:
  /// **'FLEET'**
  String get fltKicker;

  /// No description provided for @fltOnlineOf.
  ///
  /// In id, this message translates to:
  /// **'{live} DARI {total} ONLINE'**
  String fltOnlineOf(int live, int total);

  /// No description provided for @resSaveBooking.
  ///
  /// In id, this message translates to:
  /// **'Simpan reservasi'**
  String get resSaveBooking;

  /// No description provided for @resMemberEnrol.
  ///
  /// In id, this message translates to:
  /// **'Daftarkan sebagai pelanggan'**
  String get resMemberEnrol;

  /// No description provided for @resMemberEnrolFailed.
  ///
  /// In id, this message translates to:
  /// **'Reservasi tersimpan, pelanggan tidak dibuat'**
  String get resMemberEnrolFailed;

  /// No description provided for @resMemberNoMatch.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada yang cocok'**
  String get resMemberNoMatch;

  /// No description provided for @resMemberTakenTitle.
  ///
  /// In id, this message translates to:
  /// **'Nomor sudah terdaftar'**
  String get resMemberTakenTitle;

  /// No description provided for @resMemberTakenBody.
  ///
  /// In id, this message translates to:
  /// **'Nomor ini milik {name}. Pakai data pelanggan itu untuk reservasi ini?'**
  String resMemberTakenBody(String name);

  /// No description provided for @resMemberUse.
  ///
  /// In id, this message translates to:
  /// **'Pakai'**
  String get resMemberUse;

  /// No description provided for @stfRoleActive.
  ///
  /// In id, this message translates to:
  /// **'aktif'**
  String get stfRoleActive;

  /// No description provided for @stfRoleLockedSemantics.
  ///
  /// In id, this message translates to:
  /// **'{role}, {cap}, {state}, terkunci'**
  String stfRoleLockedSemantics(String role, String cap, String state);

  /// No description provided for @stfRoleSemantics.
  ///
  /// In id, this message translates to:
  /// **'{role}, {cap}'**
  String stfRoleSemantics(String role, String cap);

  /// No description provided for @mnaAddItemShort.
  ///
  /// In id, this message translates to:
  /// **'+ Item'**
  String get mnaAddItemShort;

  /// No description provided for @mnaAddCategory.
  ///
  /// In id, this message translates to:
  /// **'+ Tambah kategori'**
  String get mnaAddCategory;

  /// No description provided for @mnaAddThing.
  ///
  /// In id, this message translates to:
  /// **'+ Tambah {thing}'**
  String mnaAddThing(String thing);

  /// No description provided for @zonAdminSub.
  ///
  /// In id, this message translates to:
  /// **'{tables, plural, other{{tables} meja}} · {zones, plural, other{{zones} zona}} · {seats, plural, other{{seats} kursi}}'**
  String zonAdminSub(int tables, int zones, int seats);

  /// No description provided for @venueHubTablesZones.
  ///
  /// In id, this message translates to:
  /// **'{tables, plural, other{{tables} meja}} ({zones, plural, other{{zones} zona)}}'**
  String venueHubTablesZones(int tables, int zones);

  /// No description provided for @venueHubMenuItems.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} item menu}}'**
  String venueHubMenuItems(int count);

  /// No description provided for @venueHubStaffCount.
  ///
  /// In id, this message translates to:
  /// **'{count} staf'**
  String venueHubStaffCount(int count);

  /// No description provided for @onbModeServer.
  ///
  /// In id, this message translates to:
  /// **'Server'**
  String get onbModeServer;

  /// No description provided for @onbModeServerSub.
  ///
  /// In id, this message translates to:
  /// **'Tablet ini host venue. Database lokal di sini.'**
  String get onbModeServerSub;

  /// No description provided for @onbModeClient.
  ///
  /// In id, this message translates to:
  /// **'Klien'**
  String get onbModeClient;

  /// No description provided for @onbModeClientSub.
  ///
  /// In id, this message translates to:
  /// **'Tablet ini ambil order, terhubung ke server lewat LAN.'**
  String get onbModeClientSub;

  /// No description provided for @modSize.
  ///
  /// In id, this message translates to:
  /// **'Ukuran'**
  String get modSize;

  /// No description provided for @modNoteHint.
  ///
  /// In id, this message translates to:
  /// **'mis. alergi belum tertera, catatan plating…'**
  String get modNoteHint;

  /// No description provided for @venueHubStock.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} bahan}}'**
  String venueHubStock(int count);

  /// No description provided for @venueHubStockLow.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} bahan}} ({low} low)'**
  String venueHubStockLow(int count, int low);

  /// No description provided for @alertsSoundHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih nada untuk tiap kejadian. Pilihan ini berlaku untuk semua perangkat di venue.'**
  String get alertsSoundHint;

  /// No description provided for @kitchenQueueSub.
  ///
  /// In id, this message translates to:
  /// **'{orders, plural, other{{orders} order aktif}} · {items, plural, other{{items} item}} · tahan untuk tandai selesai'**
  String kitchenQueueSub(int orders, int items);

  /// No description provided for @modDietaryLine.
  ///
  /// In id, this message translates to:
  /// **'Cocok untuk {tags}'**
  String modDietaryLine(String tags);

  /// No description provided for @modAllergenLine.
  ///
  /// In id, this message translates to:
  /// **'Mengandung {tags} — konfirmasi ke tamu'**
  String modAllergenLine(String tags);

  /// No description provided for @rptSubNet.
  ///
  /// In id, this message translates to:
  /// **'{sessions, plural, other{{sessions} sesi}} · {covers, plural, other{{covers} tamu}}'**
  String rptSubNet(int sessions, int covers);

  /// No description provided for @rptSubGross.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} transaksi}}'**
  String rptSubGross(int count);

  /// No description provided for @rptSubTaxService.
  ///
  /// In id, this message translates to:
  /// **'PB1 11% · Svc 7% (est)'**
  String get rptSubTaxService;

  /// No description provided for @rptSubVoid.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} item void}}'**
  String rptSubVoid(int count);

  /// No description provided for @rptSubTurnTime.
  ///
  /// In id, this message translates to:
  /// **'Lama tamu duduk'**
  String get rptSubTurnTime;

  /// No description provided for @rptSubPrep.
  ///
  /// In id, this message translates to:
  /// **'Median kirim → siap'**
  String get rptSubPrep;

  /// No description provided for @rptSubPickup.
  ///
  /// In id, this message translates to:
  /// **'Median siap → disajikan'**
  String get rptSubPickup;

  /// No description provided for @rptSubReservations.
  ///
  /// In id, this message translates to:
  /// **'{noShow} no-show · {cancelled} batal'**
  String rptSubReservations(int noShow, int cancelled);

  /// No description provided for @rptStationKitchen.
  ///
  /// In id, this message translates to:
  /// **'Dapur Utama'**
  String get rptStationKitchen;

  /// No description provided for @rptUnknownStaff.
  ///
  /// In id, this message translates to:
  /// **'Tidak diketahui'**
  String get rptUnknownStaff;

  /// No description provided for @vrsWrongOrder.
  ///
  /// In id, this message translates to:
  /// **'Terkirim salah'**
  String get vrsWrongOrder;

  /// No description provided for @vrsWrongOrderDesc.
  ///
  /// In id, this message translates to:
  /// **'Salah meja, tap ganda, salah ring'**
  String get vrsWrongOrderDesc;

  /// No description provided for @vrsCustomerChange.
  ///
  /// In id, this message translates to:
  /// **'Tamu berubah pikiran'**
  String get vrsCustomerChange;

  /// No description provided for @vrsCustomerChangeDesc.
  ///
  /// In id, this message translates to:
  /// **'Tamu batalkan permintaan'**
  String get vrsCustomerChangeDesc;

  /// No description provided for @vrsOutOfStock.
  ///
  /// In id, this message translates to:
  /// **'Stok habis'**
  String get vrsOutOfStock;

  /// No description provided for @vrsOutOfStockDesc.
  ///
  /// In id, this message translates to:
  /// **'Item habis di stasiun'**
  String get vrsOutOfStockDesc;

  /// No description provided for @vrsKitchenError.
  ///
  /// In id, this message translates to:
  /// **'Komplain / kualitas dapur'**
  String get vrsKitchenError;

  /// No description provided for @vrsKitchenErrorDesc.
  ///
  /// In id, this message translates to:
  /// **'Masalah kualitas — item ditarik dari tagihan'**
  String get vrsKitchenErrorDesc;

  /// No description provided for @vrsComp.
  ///
  /// In id, this message translates to:
  /// **'Kompensasi manajer'**
  String get vrsComp;

  /// No description provided for @vrsOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get vrsOther;

  /// No description provided for @vrsOtherDesc.
  ///
  /// In id, this message translates to:
  /// **'Alasan bebas wajib diisi'**
  String get vrsOtherDesc;

  /// No description provided for @modGroupSpice.
  ///
  /// In id, this message translates to:
  /// **'Tingkat pedas'**
  String get modGroupSpice;

  /// No description provided for @modGroupExtras.
  ///
  /// In id, this message translates to:
  /// **'Tambahan'**
  String get modGroupExtras;

  /// No description provided for @modGroupSauce.
  ///
  /// In id, this message translates to:
  /// **'Saus'**
  String get modGroupSauce;

  /// No description provided for @modGroupProtein.
  ///
  /// In id, this message translates to:
  /// **'Pilih protein'**
  String get modGroupProtein;

  /// No description provided for @vrsCompDesc.
  ///
  /// In id, this message translates to:
  /// **'Digratiskan untuk tamu · tercatat terpisah dari pembatalan'**
  String get vrsCompDesc;

  /// No description provided for @authServerTrouble.
  ///
  /// In id, this message translates to:
  /// **'Server lagi bermasalah. Coba lagi sebentar.'**
  String get authServerTrouble;

  /// No description provided for @authWrongPin.
  ///
  /// In id, this message translates to:
  /// **'PIN salah. Coba lagi.'**
  String get authWrongPin;

  /// No description provided for @authWrongCredentials.
  ///
  /// In id, this message translates to:
  /// **'Email atau password salah.'**
  String get authWrongCredentials;

  /// No description provided for @authNoConnection.
  ///
  /// In id, this message translates to:
  /// **'Gagal terhubung ke server. Cek Wi-Fi lalu coba lagi.'**
  String get authNoConnection;

  /// No description provided for @authInvalidEmail.
  ///
  /// In id, this message translates to:
  /// **'Email tidak valid.'**
  String get authInvalidEmail;

  /// No description provided for @authAccountDisabled.
  ///
  /// In id, this message translates to:
  /// **'Akun admin dinonaktifkan.'**
  String get authAccountDisabled;

  /// No description provided for @authTooManyAttempts.
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak percobaan. Coba lagi nanti.'**
  String get authTooManyAttempts;

  /// No description provided for @authFirstLoginNeedsInternet.
  ///
  /// In id, this message translates to:
  /// **'Gagal terhubung. Login admin pertama butuh internet.'**
  String get authFirstLoginNeedsInternet;

  /// No description provided for @authAdminLoginFailed.
  ///
  /// In id, this message translates to:
  /// **'Login admin gagal. Coba lagi.'**
  String get authAdminLoginFailed;

  /// No description provided for @prnErrNoLines.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pesanan untuk dicetak'**
  String get prnErrNoLines;

  /// No description provided for @prnErrNotConnected.
  ///
  /// In id, this message translates to:
  /// **'Printer tak terhubung'**
  String get prnErrNotConnected;

  /// No description provided for @prnErrNoPrinter.
  ///
  /// In id, this message translates to:
  /// **'Printer tidak ditemukan'**
  String get prnErrNoPrinter;

  /// No description provided for @prnErrFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mencetak'**
  String get prnErrFailed;

  /// No description provided for @prnErrFailedCode.
  ///
  /// In id, this message translates to:
  /// **'Gagal mencetak ({code}).'**
  String prnErrFailedCode(String code);

  /// No description provided for @authServerNotReadyWait.
  ///
  /// In id, this message translates to:
  /// **'Server belum siap. Tunggu sebentar lalu coba lagi.'**
  String get authServerNotReadyWait;

  /// No description provided for @authServerNotReady.
  ///
  /// In id, this message translates to:
  /// **'Server belum siap. Coba lagi.'**
  String get authServerNotReady;

  /// No description provided for @authAdminNotRegistered.
  ///
  /// In id, this message translates to:
  /// **'Akun admin belum terdaftar. Hubungi pengelola.'**
  String get authAdminNotRegistered;

  /// No description provided for @authAdminSuspended.
  ///
  /// In id, this message translates to:
  /// **'Akun admin ditangguhkan. Hubungi pengelola.'**
  String get authAdminSuspended;

  /// No description provided for @authAdminInactive.
  ///
  /// In id, this message translates to:
  /// **'Akun admin tidak aktif.'**
  String get authAdminInactive;

  /// No description provided for @authNoVenueAssigned.
  ///
  /// In id, this message translates to:
  /// **'Akun belum ditugaskan ke venue. Hubungi pengelola.'**
  String get authNoVenueAssigned;

  /// No description provided for @authVenueNotFound.
  ///
  /// In id, this message translates to:
  /// **'Venue tidak ditemukan. Hubungi pengelola.'**
  String get authVenueNotFound;

  /// No description provided for @authVenueSuspended.
  ///
  /// In id, this message translates to:
  /// **'Venue ditangguhkan. Hubungi pengelola.'**
  String get authVenueSuspended;

  /// No description provided for @authVenueInactive.
  ///
  /// In id, this message translates to:
  /// **'Venue tidak aktif.'**
  String get authVenueInactive;

  /// No description provided for @sendQueueFull.
  ///
  /// In id, this message translates to:
  /// **'Antrean kirim penuh — sambungkan dulu ke server sebelum pesan lagi'**
  String get sendQueueFull;

  /// No description provided for @sendQueuePending.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} pesanan menunggu terkirim}}'**
  String sendQueuePending(int count);

  /// No description provided for @sendQueueTertunda.
  ///
  /// In id, this message translates to:
  /// **'Tertunda'**
  String get sendQueueTertunda;

  /// No description provided for @sendQueueCapturedAt.
  ///
  /// In id, this message translates to:
  /// **'Diambil {time}'**
  String sendQueueCapturedAt(String time);

  /// No description provided for @sendResultTitle.
  ///
  /// In id, this message translates to:
  /// **'Hasil pengiriman'**
  String get sendResultTitle;

  /// No description provided for @sendResultAllOk.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} pesanan terkirim}}'**
  String sendResultAllOk(int count);

  /// No description provided for @sendResultAcknowledge.
  ///
  /// In id, this message translates to:
  /// **'Mengerti'**
  String get sendResultAcknowledge;

  /// No description provided for @sendResultFailedHeading.
  ///
  /// In id, this message translates to:
  /// **'Gagal terkirim'**
  String get sendResultFailedHeading;

  /// No description provided for @sendFailVisitChanged.
  ///
  /// In id, this message translates to:
  /// **'Meja sudah ganti tamu — pesanan tidak dipasang'**
  String get sendFailVisitChanged;

  /// No description provided for @sendFailBillClosed.
  ///
  /// In id, this message translates to:
  /// **'Tagihan sudah ditutup'**
  String get sendFailBillClosed;

  /// No description provided for @sendFailExpired.
  ///
  /// In id, this message translates to:
  /// **'Lewat hari — pesanan tidak dikirim'**
  String get sendFailExpired;

  /// No description provided for @sendFailBlocked.
  ///
  /// In id, this message translates to:
  /// **'Akun ini tidak boleh mengirim pesanan — masuk sebagai pengambil pesanan'**
  String get sendFailBlocked;

  /// No description provided for @sendFailOther.
  ///
  /// In id, this message translates to:
  /// **'Ditolak server'**
  String get sendFailOther;

  /// No description provided for @sendQueueBlockEndShift.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{Masih ada {count} pesanan yang belum terkirim. Sambungkan ke server dulu, atau buang pesanan itu.}}'**
  String sendQueueBlockEndShift(int count);

  /// No description provided for @sendQueueDiscardAll.
  ///
  /// In id, this message translates to:
  /// **'Buang pesanan tertunda'**
  String get sendQueueDiscardAll;

  /// No description provided for @tktOutOfStock.
  ///
  /// In id, this message translates to:
  /// **'bahan habis'**
  String get tktOutOfStock;

  /// No description provided for @tktOutOfStockNamed.
  ///
  /// In id, this message translates to:
  /// **'bahan habis: {names}'**
  String tktOutOfStockNamed(String names);

  /// No description provided for @tktNotSent.
  ///
  /// In id, this message translates to:
  /// **'{what} tidak dikirim — {why}'**
  String tktNotSent(String what, String why);

  /// No description provided for @auditLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat audit'**
  String get auditLoadFailed;

  /// No description provided for @capTakeOrder.
  ///
  /// In id, this message translates to:
  /// **'Ambil pesanan'**
  String get capTakeOrder;

  /// No description provided for @capModifyOrder.
  ///
  /// In id, this message translates to:
  /// **'Ubah pesanan'**
  String get capModifyOrder;

  /// No description provided for @capVoidItem.
  ///
  /// In id, this message translates to:
  /// **'Batalkan item'**
  String get capVoidItem;

  /// No description provided for @capCompItem.
  ///
  /// In id, this message translates to:
  /// **'Gratiskan item'**
  String get capCompItem;

  /// No description provided for @capViewKds.
  ///
  /// In id, this message translates to:
  /// **'Lihat KDS'**
  String get capViewKds;

  /// No description provided for @capOpenDrawer.
  ///
  /// In id, this message translates to:
  /// **'Buka laci'**
  String get capOpenDrawer;

  /// No description provided for @capApplyDiscount.
  ///
  /// In id, this message translates to:
  /// **'Beri diskon'**
  String get capApplyDiscount;

  /// No description provided for @capSettleBill.
  ///
  /// In id, this message translates to:
  /// **'Tutup tagihan'**
  String get capSettleBill;

  /// No description provided for @capRefund.
  ///
  /// In id, this message translates to:
  /// **'Refund'**
  String get capRefund;

  /// No description provided for @capManageCash.
  ///
  /// In id, this message translates to:
  /// **'Kelola kas kecil'**
  String get capManageCash;

  /// No description provided for @cashCatIngredients.
  ///
  /// In id, this message translates to:
  /// **'Belanja bahan'**
  String get cashCatIngredients;

  /// No description provided for @cashCatOperations.
  ///
  /// In id, this message translates to:
  /// **'Operasional'**
  String get cashCatOperations;

  /// No description provided for @cashCatTransport.
  ///
  /// In id, this message translates to:
  /// **'Transport'**
  String get cashCatTransport;

  /// No description provided for @cashCatDailyWage.
  ///
  /// In id, this message translates to:
  /// **'Upah harian'**
  String get cashCatDailyWage;

  /// No description provided for @cashCatOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get cashCatOther;

  /// No description provided for @cashKindTopUp.
  ///
  /// In id, this message translates to:
  /// **'Isi kas'**
  String get cashKindTopUp;

  /// No description provided for @cashKindExpense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get cashKindExpense;

  /// No description provided for @cashKindCount.
  ///
  /// In id, this message translates to:
  /// **'Opname'**
  String get cashKindCount;

  /// No description provided for @cashKindReversal.
  ///
  /// In id, this message translates to:
  /// **'Pembatalan'**
  String get cashKindReversal;

  /// No description provided for @kasTitle.
  ///
  /// In id, this message translates to:
  /// **'Kas kecil'**
  String get kasTitle;

  /// No description provided for @kasHubSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Saldo, pengeluaran, opname'**
  String get kasHubSubtitle;

  /// No description provided for @kasBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo kas'**
  String get kasBalance;

  /// No description provided for @kasLastCount.
  ///
  /// In id, this message translates to:
  /// **'Opname terakhir {when}'**
  String kasLastCount(String when);

  /// No description provided for @kasNeverCounted.
  ///
  /// In id, this message translates to:
  /// **'Belum pernah diopname'**
  String get kasNeverCounted;

  /// No description provided for @kasEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Kas kecil masih kosong'**
  String get kasEmptyTitle;

  /// No description provided for @kasEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Isi kas dulu, baru pengeluaran bisa dicatat.'**
  String get kasEmptyBody;

  /// No description provided for @kasActionTopUp.
  ///
  /// In id, this message translates to:
  /// **'Isi kas'**
  String get kasActionTopUp;

  /// No description provided for @kasActionExpense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get kasActionExpense;

  /// No description provided for @kasActionCount.
  ///
  /// In id, this message translates to:
  /// **'Opname'**
  String get kasActionCount;

  /// No description provided for @kasSheetTopUpTitle.
  ///
  /// In id, this message translates to:
  /// **'Isi kas kecil'**
  String get kasSheetTopUpTitle;

  /// No description provided for @kasSheetExpenseTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran kas'**
  String get kasSheetExpenseTitle;

  /// No description provided for @kasSheetCountTitle.
  ///
  /// In id, this message translates to:
  /// **'Opname kas'**
  String get kasSheetCountTitle;

  /// No description provided for @kasFieldAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get kasFieldAmount;

  /// No description provided for @kasFieldCounted.
  ///
  /// In id, this message translates to:
  /// **'Uang yang ada di kotak'**
  String get kasFieldCounted;

  /// No description provided for @kasFieldNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get kasFieldNote;

  /// No description provided for @kasFieldReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan'**
  String get kasFieldReason;

  /// No description provided for @kasFieldCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get kasFieldCategory;

  /// No description provided for @kasPhotoAdd.
  ///
  /// In id, this message translates to:
  /// **'Foto nota'**
  String get kasPhotoAdd;

  /// No description provided for @kasLedgerSays.
  ///
  /// In id, this message translates to:
  /// **'Catatan kas: {amount}'**
  String kasLedgerSays(String amount);

  /// No description provided for @kasVariance.
  ///
  /// In id, this message translates to:
  /// **'Selisih {amount}'**
  String kasVariance(String amount);

  /// No description provided for @kasDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Mutasi kas'**
  String get kasDetailTitle;

  /// No description provided for @kasCounted.
  ///
  /// In id, this message translates to:
  /// **'Terhitung {amount}'**
  String kasCounted(String amount);

  /// No description provided for @kasReverse.
  ///
  /// In id, this message translates to:
  /// **'Batalkan mutasi'**
  String get kasReverse;

  /// No description provided for @kasReverseTitle.
  ///
  /// In id, this message translates to:
  /// **'Batalkan mutasi kas'**
  String get kasReverseTitle;

  /// No description provided for @kasReverseBody.
  ///
  /// In id, this message translates to:
  /// **'Baris ini tetap ada; pembatalan dicatat sebagai mutasi baru.'**
  String get kasReverseBody;

  /// No description provided for @kasReversed.
  ///
  /// In id, this message translates to:
  /// **'Sudah dibatalkan'**
  String get kasReversed;

  /// No description provided for @kasIsReversal.
  ///
  /// In id, this message translates to:
  /// **'Membatalkan mutasi sebelumnya'**
  String get kasIsReversal;

  /// No description provided for @kasActorUnknown.
  ///
  /// In id, this message translates to:
  /// **'Sistem'**
  String get kasActorUnknown;

  /// No description provided for @kasBy.
  ///
  /// In id, this message translates to:
  /// **'oleh {name}'**
  String kasBy(String name);

  /// No description provided for @kasErrInsufficient.
  ///
  /// In id, this message translates to:
  /// **'Saldo kas cuma {amount}'**
  String kasErrInsufficient(String amount);

  /// No description provided for @kasErrReasonRequired.
  ///
  /// In id, this message translates to:
  /// **'Alasan wajib diisi'**
  String get kasErrReasonRequired;

  /// No description provided for @kasErrAlreadyReversed.
  ///
  /// In id, this message translates to:
  /// **'Mutasi ini sudah dibatalkan'**
  String get kasErrAlreadyReversed;

  /// No description provided for @kasErrNotReversible.
  ///
  /// In id, this message translates to:
  /// **'Pembatalan tidak bisa dibatalkan lagi'**
  String get kasErrNotReversible;

  /// No description provided for @kasErrInvalidAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah tidak sah'**
  String get kasErrInvalidAmount;

  /// No description provided for @kasErrFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan ({code})'**
  String kasErrFailed(String code);

  /// No description provided for @kasPhoneOnly.
  ///
  /// In id, this message translates to:
  /// **'Kas kecil dibaca di tablet.'**
  String get kasPhoneOnly;

  /// No description provided for @rptSecKas.
  ///
  /// In id, this message translates to:
  /// **'Kas kecil'**
  String get rptSecKas;

  /// No description provided for @rptSecMembers.
  ///
  /// In id, this message translates to:
  /// **'Keanggotaan'**
  String get rptSecMembers;

  /// No description provided for @rptMembersSub.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan terdaftar di rentang ini'**
  String get rptMembersSub;

  /// No description provided for @rptMembersEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pelanggan terdaftar di rentang ini.'**
  String get rptMembersEmpty;

  /// No description provided for @rptMembersEnrolled.
  ///
  /// In id, this message translates to:
  /// **'Daftar baru'**
  String get rptMembersEnrolled;

  /// No description provided for @rptMembersActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get rptMembersActive;

  /// No description provided for @rptMembersBills.
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get rptMembersBills;

  /// No description provided for @rptMembersAvgBill.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata pelanggan'**
  String get rptMembersAvgBill;

  /// No description provided for @rptMembersAvgGuest.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata tamu biasa'**
  String get rptMembersAvgGuest;

  /// No description provided for @rptMembersLift.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get rptMembersLift;

  /// No description provided for @rptMembersPoints.
  ///
  /// In id, this message translates to:
  /// **'Poin'**
  String get rptMembersPoints;

  /// No description provided for @rptMembersEarned.
  ///
  /// In id, this message translates to:
  /// **'Terkumpul'**
  String get rptMembersEarned;

  /// No description provided for @rptMembersRedeemed.
  ///
  /// In id, this message translates to:
  /// **'Ditukar'**
  String get rptMembersRedeemed;

  /// No description provided for @rptMembersOutstanding.
  ///
  /// In id, this message translates to:
  /// **'Beredar'**
  String get rptMembersOutstanding;

  /// No description provided for @rptMembersLiability.
  ///
  /// In id, this message translates to:
  /// **'Nilai poin beredar'**
  String get rptMembersLiability;

  /// No description provided for @rptMembersTop.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan teratas'**
  String get rptMembersTop;

  /// No description provided for @rptMembersGone.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan dihapus'**
  String get rptMembersGone;

  /// No description provided for @rptMembersVisits.
  ///
  /// In id, this message translates to:
  /// **'Kunjungan: {count}'**
  String rptMembersVisits(int count);

  /// No description provided for @rptKasOpening.
  ///
  /// In id, this message translates to:
  /// **'Saldo awal'**
  String get rptKasOpening;

  /// No description provided for @rptKasIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get rptKasIn;

  /// No description provided for @rptKasOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get rptKasOut;

  /// No description provided for @rptKasVariance.
  ///
  /// In id, this message translates to:
  /// **'Selisih opname'**
  String get rptKasVariance;

  /// No description provided for @rptKasClosing.
  ///
  /// In id, this message translates to:
  /// **'Saldo akhir'**
  String get rptKasClosing;

  /// No description provided for @rptKasByCategory.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran per kategori'**
  String get rptKasByCategory;

  /// No description provided for @rptKasEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada mutasi kas di rentang ini.'**
  String get rptKasEmpty;

  /// No description provided for @capCloseShift.
  ///
  /// In id, this message translates to:
  /// **'Tutup shift'**
  String get capCloseShift;

  /// No description provided for @capEditMenu.
  ///
  /// In id, this message translates to:
  /// **'Ubah menu'**
  String get capEditMenu;

  /// No description provided for @capMarkSoldOut.
  ///
  /// In id, this message translates to:
  /// **'Tandai habis'**
  String get capMarkSoldOut;

  /// No description provided for @capAdjustStock.
  ///
  /// In id, this message translates to:
  /// **'Sesuaikan stok'**
  String get capAdjustStock;

  /// No description provided for @capManageIngredients.
  ///
  /// In id, this message translates to:
  /// **'Kelola bahan'**
  String get capManageIngredients;

  /// No description provided for @capOverrideStock.
  ///
  /// In id, this message translates to:
  /// **'Jual saat stok habis'**
  String get capOverrideStock;

  /// No description provided for @capManageMembers.
  ///
  /// In id, this message translates to:
  /// **'Kelola pelanggan'**
  String get capManageMembers;

  /// No description provided for @capManageMembersDesc.
  ///
  /// In id, this message translates to:
  /// **'Ubah, gabung, dan hapus data pelanggan, serta koreksi poin secara manual. Kasir tidak perlu ini untuk mendaftarkan atau menukar poin.'**
  String get capManageMembersDesc;

  /// No description provided for @capManageStaff.
  ///
  /// In id, this message translates to:
  /// **'Kelola staf'**
  String get capManageStaff;

  /// No description provided for @capManageRoles.
  ///
  /// In id, this message translates to:
  /// **'Kelola peran'**
  String get capManageRoles;

  /// No description provided for @capViewReports.
  ///
  /// In id, this message translates to:
  /// **'Lihat laporan'**
  String get capViewReports;

  /// No description provided for @capEditSettings.
  ///
  /// In id, this message translates to:
  /// **'Ubah pengaturan'**
  String get capEditSettings;

  /// No description provided for @capTakeOrderDesc.
  ///
  /// In id, this message translates to:
  /// **'Buat pesanan baru dan kirim ke dapur.'**
  String get capTakeOrderDesc;

  /// No description provided for @capModifyOrderDesc.
  ///
  /// In id, this message translates to:
  /// **'Ubah jumlah atau catatan pada pesanan yang belum dimasak.'**
  String get capModifyOrderDesc;

  /// No description provided for @capVoidItemDesc.
  ///
  /// In id, this message translates to:
  /// **'Hapus item terkirim sebelum disajikan.'**
  String get capVoidItemDesc;

  /// No description provided for @capCompItemDesc.
  ///
  /// In id, this message translates to:
  /// **'Nolkan harga item yang sudah disajikan.'**
  String get capCompItemDesc;

  /// No description provided for @capViewKdsDesc.
  ///
  /// In id, this message translates to:
  /// **'Buka antrian persiapan dapur.'**
  String get capViewKdsDesc;

  /// No description provided for @capOpenDrawerDesc.
  ///
  /// In id, this message translates to:
  /// **'Buka laci kas tanpa transaksi.'**
  String get capOpenDrawerDesc;

  /// No description provided for @capApplyDiscountDesc.
  ///
  /// In id, this message translates to:
  /// **'Potong harga pada tagihan.'**
  String get capApplyDiscountDesc;

  /// No description provided for @capSettleBillDesc.
  ///
  /// In id, this message translates to:
  /// **'Terima pembayaran dan tutup tagihan.'**
  String get capSettleBillDesc;

  /// No description provided for @capRefundDesc.
  ///
  /// In id, this message translates to:
  /// **'Kembalikan uang atas tagihan yang sudah dibayar.'**
  String get capRefundDesc;

  /// No description provided for @capCloseShiftDesc.
  ///
  /// In id, this message translates to:
  /// **'Akhiri shift dan hitung kas.'**
  String get capCloseShiftDesc;

  /// No description provided for @capManageCashDesc.
  ///
  /// In id, this message translates to:
  /// **'Catat pengeluaran dari kas kecil. Mengisi dan mengopname kas butuh izin pengaturan.'**
  String get capManageCashDesc;

  /// No description provided for @capEditMenuDesc.
  ///
  /// In id, this message translates to:
  /// **'Tambah, ubah, dan hapus item serta kategori menu.'**
  String get capEditMenuDesc;

  /// No description provided for @capMarkSoldOutDesc.
  ///
  /// In id, this message translates to:
  /// **'Tandai item habis tanpa mengubah stok bahan.'**
  String get capMarkSoldOutDesc;

  /// No description provided for @capAdjustStockDesc.
  ///
  /// In id, this message translates to:
  /// **'Catat opname, terima barang, dan buang bahan.'**
  String get capAdjustStockDesc;

  /// No description provided for @capManageIngredientsDesc.
  ///
  /// In id, this message translates to:
  /// **'Tambah dan ubah bahan beserta resepnya.'**
  String get capManageIngredientsDesc;

  /// No description provided for @capOverrideStockDesc.
  ///
  /// In id, this message translates to:
  /// **'Kirim pesanan meski bahan tercatat habis.'**
  String get capOverrideStockDesc;

  /// No description provided for @capManageStaffDesc.
  ///
  /// In id, this message translates to:
  /// **'Tambah staf, atur peran, dan setel ulang PIN.'**
  String get capManageStaffDesc;

  /// No description provided for @capManageRolesDesc.
  ///
  /// In id, this message translates to:
  /// **'Buat peran dan atur izin yang dibawanya.'**
  String get capManageRolesDesc;

  /// No description provided for @capViewReportsDesc.
  ///
  /// In id, this message translates to:
  /// **'Buka laporan penjualan dan jejak audit.'**
  String get capViewReportsDesc;

  /// No description provided for @capEditSettingsDesc.
  ///
  /// In id, this message translates to:
  /// **'Ubah pengaturan venue, waktu, dan peringatan.'**
  String get capEditSettingsDesc;

  /// No description provided for @capGrpOrders.
  ///
  /// In id, this message translates to:
  /// **'Pesanan'**
  String get capGrpOrders;

  /// No description provided for @capGrpMoney.
  ///
  /// In id, this message translates to:
  /// **'Uang'**
  String get capGrpMoney;

  /// No description provided for @capGrpInventory.
  ///
  /// In id, this message translates to:
  /// **'Menu & stok'**
  String get capGrpInventory;

  /// No description provided for @capGrpAdmin.
  ///
  /// In id, this message translates to:
  /// **'Admin'**
  String get capGrpAdmin;

  /// No description provided for @capGrpKitchen.
  ///
  /// In id, this message translates to:
  /// **'Dapur'**
  String get capGrpKitchen;

  /// No description provided for @agbLockedOnRestart.
  ///
  /// In id, this message translates to:
  /// **'Server akan terkunci saat aplikasi dimulai ulang — sambungkan internet sekarang untuk verifikasi admin.'**
  String get agbLockedOnRestart;

  /// No description provided for @agbLockedInHours.
  ///
  /// In id, this message translates to:
  /// **'Tanpa internet, server terkunci dalam {hours, plural, other{{hours} jam.}} Segera sambungkan.'**
  String agbLockedInHours(int hours);

  /// No description provided for @agbLockedInDays.
  ///
  /// In id, this message translates to:
  /// **'Tanpa internet, server terkunci dalam {days, plural, other{{days} hari.}} Sambungkan untuk verifikasi admin.'**
  String agbLockedInDays(int days);

  /// No description provided for @crsStartBeforeEnd.
  ///
  /// In id, this message translates to:
  /// **'Tanggal mulai harus sebelum tanggal selesai.'**
  String get crsStartBeforeEnd;

  /// No description provided for @crsMaxSpan.
  ///
  /// In id, this message translates to:
  /// **'Rentang maksimal {days, plural, other{{days} hari.}}'**
  String crsMaxSpan(int days);

  /// No description provided for @pinPickServerFirst.
  ///
  /// In id, this message translates to:
  /// **'Pilih server dulu.'**
  String get pinPickServerFirst;

  /// No description provided for @pinDeviceNotPaired.
  ///
  /// In id, this message translates to:
  /// **'HP belum tersambung. Scan QR lagi untuk pasangkan.'**
  String get pinDeviceNotPaired;

  /// No description provided for @pinSetupFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyiapkan aplikasi. Coba lagi.'**
  String get pinSetupFailed;

  /// No description provided for @pinServerBootFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menjalankan server di HP ini. Coba lagi.'**
  String get pinServerBootFailed;

  /// No description provided for @pinAutoClaimFailed.
  ///
  /// In id, this message translates to:
  /// **'Sambung otomatis gagal: {error}'**
  String pinAutoClaimFailed(String error);

  /// No description provided for @prnNothingToPrint.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pesanan untuk dicetak'**
  String get prnNothingToPrint;

  /// No description provided for @prnThisDevice.
  ///
  /// In id, this message translates to:
  /// **'Alat ini'**
  String get prnThisDevice;

  /// No description provided for @prnEnableBluetooth.
  ///
  /// In id, this message translates to:
  /// **'Nyalakan Bluetooth di Pengaturan lalu coba lagi'**
  String get prnEnableBluetooth;

  /// No description provided for @prnReceiptPrinted.
  ///
  /// In id, this message translates to:
  /// **'Struk tercetak'**
  String get prnReceiptPrinted;

  /// No description provided for @rptStockValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai stok'**
  String get rptStockValue;

  /// No description provided for @rptStockValueNow.
  ///
  /// In id, this message translates to:
  /// **'Nilai stok saat ini'**
  String get rptStockValueNow;

  /// No description provided for @rptNoStocktake.
  ///
  /// In id, this message translates to:
  /// **'Belum ada opname pada rentang ini.'**
  String get rptNoStocktake;

  /// No description provided for @rptAllWaiters.
  ///
  /// In id, this message translates to:
  /// **'Semua pelayan'**
  String get rptAllWaiters;

  /// No description provided for @rptAllZones.
  ///
  /// In id, this message translates to:
  /// **'Semua zona'**
  String get rptAllZones;

  /// No description provided for @rptAllCategories.
  ///
  /// In id, this message translates to:
  /// **'Semua kategori'**
  String get rptAllCategories;

  /// No description provided for @alertsThresholdLine.
  ///
  /// In id, this message translates to:
  /// **'Siap {prep}m · belum dilayani {ungreeted}m'**
  String alertsThresholdLine(int prep, int ungreeted);

  /// No description provided for @venueHubShiftReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan shift'**
  String get venueHubShiftReport;

  /// No description provided for @auditExportFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengekspor audit'**
  String get auditExportFailed;

  /// No description provided for @killReasonOutOfStock.
  ///
  /// In id, this message translates to:
  /// **'Bahan habis'**
  String get killReasonOutOfStock;

  /// No description provided for @killReasonQuality.
  ///
  /// In id, this message translates to:
  /// **'Kualitas tidak layak'**
  String get killReasonQuality;

  /// No description provided for @rcpVenueNamePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'NAMA VENUE'**
  String get rcpVenueNamePlaceholder;

  /// No description provided for @rcpSplitReceipt.
  ///
  /// In id, this message translates to:
  /// **'STRUK BAGIAN'**
  String get rcpSplitReceipt;

  /// No description provided for @ordEmptyPass.
  ///
  /// In id, this message translates to:
  /// **'Belum ada yang siap di pass.'**
  String get ordEmptyPass;

  /// No description provided for @ordEmptyPreparingAll.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada item yang sedang disiapkan.'**
  String get ordEmptyPreparingAll;

  /// No description provided for @ordEmptyPreparingMine.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada item Anda yang sedang disiapkan.\nPilih Semua untuk melihat seluruh venue.'**
  String get ordEmptyPreparingMine;

  /// No description provided for @ordEmptyDoneAll.
  ///
  /// In id, this message translates to:
  /// **'Belum ada item yang selesai pada sesi ini.'**
  String get ordEmptyDoneAll;

  /// No description provided for @ordEmptyDoneMine.
  ///
  /// In id, this message translates to:
  /// **'Belum ada item Anda yang selesai pada sesi ini.\nPilih Semua untuk melihat seluruh venue.'**
  String get ordEmptyDoneMine;

  /// No description provided for @rptStockWaste.
  ///
  /// In id, this message translates to:
  /// **'Terbuang'**
  String get rptStockWaste;

  /// No description provided for @rptStockVariance.
  ///
  /// In id, this message translates to:
  /// **'Selisih opname'**
  String get rptStockVariance;

  /// No description provided for @rptStockUsage.
  ///
  /// In id, this message translates to:
  /// **'Pemakaian'**
  String get rptStockUsage;

  /// No description provided for @prnEnableBluetoothTitle.
  ///
  /// In id, this message translates to:
  /// **'Nyalakan Bluetooth'**
  String get prnEnableBluetoothTitle;

  /// Kill-switch reason: the equipment needed for this item is broken.
  ///
  /// In id, this message translates to:
  /// **'Alat rusak'**
  String get killReasonBrokenEquipment;

  /// Kill-switch reason: the item takes too long to prepare right now.
  ///
  /// In id, this message translates to:
  /// **'Terlalu lama'**
  String get killReasonTooSlow;

  /// Zone header: how many tables of the zone are occupied.
  ///
  /// In id, this message translates to:
  /// **'{occupied} dari {total} terisi'**
  String tblOccupiedOf(int occupied, int total);

  /// Zone header: total money open across the zone. Amount is preformatted rupiah.
  ///
  /// In id, this message translates to:
  /// **'tab {amount}'**
  String tblOpenTab(String amount);

  /// Table card status: the table is held by a reservation.
  ///
  /// In id, this message translates to:
  /// **'Dipesan'**
  String get tcStatusReserved;

  /// Table card status: nobody seated.
  ///
  /// In id, this message translates to:
  /// **'Kosong'**
  String get tcStatusAvailable;

  /// Table card status: guests seated, order sent.
  ///
  /// In id, this message translates to:
  /// **'Terisi'**
  String get tcStatusOccupied;

  /// Table card status: an order has been taken but not yet fired.
  ///
  /// In id, this message translates to:
  /// **'Pesanan masuk'**
  String get tcStatusPending;

  /// Table card status: n items waiting at the pass for this table.
  ///
  /// In id, this message translates to:
  /// **'Siap ×{n}'**
  String tcStatusReady(int n);

  /// Move-table error: the destination table already has guests.
  ///
  /// In id, this message translates to:
  /// **'Meja tujuan sudah terisi.'**
  String get mvtTargetOccupied;

  /// Move-table error: another device holds the table lock.
  ///
  /// In id, this message translates to:
  /// **'Meja sedang dipakai pengguna lain.'**
  String get mvtTableLocked;

  /// Move-table error: the source table was released meanwhile.
  ///
  /// In id, this message translates to:
  /// **'Meja asal sudah kosong.'**
  String get mvtSourceEmpty;

  /// Modifier group tag: a choice must be made.
  ///
  /// In id, this message translates to:
  /// **'WAJIB'**
  String get modTagRequired;

  /// Modifier group tag: any number of options may be picked.
  ///
  /// In id, this message translates to:
  /// **'BEBAS PILIH'**
  String get modTagFree;

  /// Modifier group tag: the group may be skipped.
  ///
  /// In id, this message translates to:
  /// **'OPSIONAL'**
  String get modTagOptional;

  /// Add button label while a required modifier group is unanswered.
  ///
  /// In id, this message translates to:
  /// **'Pilih wajib'**
  String get modPickRequired;

  /// Action sheet subtitle for firing a course.
  ///
  /// In id, this message translates to:
  /// **'Kirim course ke line langsung'**
  String get liaFireDesc;

  /// Action sheet subtitle for editing a line before it is fired.
  ///
  /// In id, this message translates to:
  /// **'Jumlah, catatan, dan pilihan · sebelum masuk dapur'**
  String get liaEditDesc;

  /// Action sheet subtitle for marking an item served.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi diambil & diantar ke meja'**
  String get liaServeDesc;

  /// Action sheet subtitle for undoing a served mark.
  ///
  /// In id, this message translates to:
  /// **'Kembalikan status jika ditandai terlalu cepat'**
  String get liaUnserveDesc;

  /// Action sheet subtitle for voiding a line.
  ///
  /// In id, this message translates to:
  /// **'Hapus dari pesanan · tercatat atas nama kamu'**
  String get liaVoidDesc;

  /// Dialog title when the admin on the server device signs out.
  ///
  /// In id, this message translates to:
  /// **'Akhiri sesi admin?'**
  String get meEndAdminTitle;

  /// Sign-out warning on the server device while tables are still live.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} meja}} masih aktif. Keluar akan mematikan server — semua staff terputus dan tidak bisa menyambung sampai admin masuk lagi.'**
  String meEndServerBodyLive(int n);

  /// Sign-out warning on the server device with no live tables.
  ///
  /// In id, this message translates to:
  /// **'Keluar akan mematikan server. Staff tidak bisa menyambung sampai admin masuk lagi.'**
  String get meEndServerBody;

  /// Confirm button: sign out and stop the embedded server.
  ///
  /// In id, this message translates to:
  /// **'Keluar & matikan'**
  String get meEndAndShutdown;

  /// Shift summary when nothing is in flight.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada tiket terbuka'**
  String get meNoOpenTickets;

  /// Printed heading for a per-item receipt.
  ///
  /// In id, this message translates to:
  /// **'STRUK'**
  String get rcpItemizedReceipt;

  /// Payment line on a receipt when the payment was refunded.
  ///
  /// In id, this message translates to:
  /// **'{method} (refund)'**
  String rcpRefundLine(String method);

  /// Receipt line naming the table when the guest is anonymous.
  ///
  /// In id, this message translates to:
  /// **'Meja {label}'**
  String tableNamed(String label);

  /// Receipt line with the cover count.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} tamu}}'**
  String rcpPaxCount(int n);

  /// Staff role name: waiter.
  ///
  /// In id, this message translates to:
  /// **'Pelayan'**
  String get roleWaiter;

  /// Staff role name: kitchen.
  ///
  /// In id, this message translates to:
  /// **'Dapur'**
  String get roleKitchen;

  /// Staff role name: admin.
  ///
  /// In id, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// Ticket status: not sent yet.
  ///
  /// In id, this message translates to:
  /// **'Draf'**
  String get tstatDraft;

  /// Ticket status: the kitchen has seen it.
  ///
  /// In id, this message translates to:
  /// **'Diterima'**
  String get tstatAcknowledged;

  /// Ticket status: sent to the kitchen.
  ///
  /// In id, this message translates to:
  /// **'Terkirim'**
  String get tstatSent;

  /// Ticket status: being prepared.
  ///
  /// In id, this message translates to:
  /// **'Disiapkan'**
  String get tstatPrep;

  /// Ticket status: cooking finished.
  ///
  /// In id, this message translates to:
  /// **'Selesai dimasak'**
  String get tstatCooked;

  /// Ticket status: waiting at the pass.
  ///
  /// In id, this message translates to:
  /// **'Siap diambil'**
  String get tstatReady;

  /// Ticket status: delivered to the table.
  ///
  /// In id, this message translates to:
  /// **'Disajikan'**
  String get tstatServed;

  /// Ticket status: held back on purpose.
  ///
  /// In id, this message translates to:
  /// **'Ditahan'**
  String get tstatHeld;

  /// Ticket status: voided.
  ///
  /// In id, this message translates to:
  /// **'Dibatalkan'**
  String get tstatVoided;

  /// Reservation status: booked, not arrived.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get resStatPending;

  /// Reservation status: the party is seated.
  ///
  /// In id, this message translates to:
  /// **'Duduk'**
  String get resStatSeated;

  /// Reservation status: the party never arrived.
  ///
  /// In id, this message translates to:
  /// **'No-show'**
  String get resStatNoShow;

  /// Reservation status: cancelled.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get resStatCancelled;

  /// Stock movement reason: consumed by a sale.
  ///
  /// In id, this message translates to:
  /// **'Terjual'**
  String get stkReasonSale;

  /// Stock movement reason: returned to stock after a void.
  ///
  /// In id, this message translates to:
  /// **'Batal — kembali'**
  String get stkReasonVoidReturn;

  /// Stock movement reason: wasted.
  ///
  /// In id, this message translates to:
  /// **'Terbuang'**
  String get stkReasonWaste;

  /// Stock movement reason: goods received.
  ///
  /// In id, this message translates to:
  /// **'Terima barang'**
  String get stkReasonReceive;

  /// Stock movement reason: manual adjustment or stocktake.
  ///
  /// In id, this message translates to:
  /// **'Penyesuaian'**
  String get stkReasonAdjust;

  /// Stock movement reason: produced from a recipe.
  ///
  /// In id, this message translates to:
  /// **'Produksi'**
  String get stkReasonProduce;

  /// Default heading above a guest or kitchen note.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get noteLabel;

  /// Zone chip counter: items ready at the pass in this zone.
  ///
  /// In id, this message translates to:
  /// **'{n} siap'**
  String tblZoneReadyCount(int n);

  /// Takeaway status: handed to the guest.
  ///
  /// In id, this message translates to:
  /// **'Diserahkan'**
  String get tkwStatusHandedOver;

  /// Takeaway status: ready for pickup.
  ///
  /// In id, this message translates to:
  /// **'Siap'**
  String get tkwStatusReady;

  /// Takeaway status: being prepared.
  ///
  /// In id, this message translates to:
  /// **'Diproses'**
  String get tkwStatusInProgress;

  /// Takeaway status: finished.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get tkwStatusDone;

  /// Button on the PIN screen that opens the admin email sign-in.
  ///
  /// In id, this message translates to:
  /// **'Masuk sebagai admin'**
  String get pinSignInAsAdmin;

  /// Button: type a printer address by hand instead of discovering it.
  ///
  /// In id, this message translates to:
  /// **'Tambah manual'**
  String get prnAddManual;

  /// Subtitle while the report is still being fetched.
  ///
  /// In id, this message translates to:
  /// **'Memuat laporan…'**
  String get rptLoading;

  /// Report freshness: figures update as the shift runs.
  ///
  /// In id, this message translates to:
  /// **'Live'**
  String get rptFreshLive;

  /// Report freshness: figures are a closed period.
  ///
  /// In id, this message translates to:
  /// **'Snapshot'**
  String get rptFreshSnapshot;

  /// Modifier option that is out of stock.
  ///
  /// In id, this message translates to:
  /// **'{name} · habis'**
  String modOptionSoldOut(String name);

  /// Venue hub badge under the floor plan tile.
  ///
  /// In id, this message translates to:
  /// **'{tables, plural, other{{tables} meja}} · {zones, plural, other{{zones} zona}}'**
  String venueHubBadgeFloor(int tables, int zones);

  /// Venue hub badge under the staff tile.
  ///
  /// In id, this message translates to:
  /// **'{n} staf'**
  String venueHubBadgeStaff(int n);

  /// Shown in place of the address when the venue has a legal name but no address on file.
  ///
  /// In id, this message translates to:
  /// **'Mode Operasional'**
  String get venueHubOperationalMode;

  /// Orders screen heading with the venue name.
  ///
  /// In id, this message translates to:
  /// **'Pesanan {venue}'**
  String ordTitleVenue(String venue);

  /// Orders tab: items ready at the pass.
  ///
  /// In id, this message translates to:
  /// **'Siap'**
  String get ordTabReady;

  /// Fake table line in the receipt layout preview. Not real data.
  ///
  /// In id, this message translates to:
  /// **'Meja 4 · Contoh'**
  String get rcpSampleTable;

  /// Table name on an audit row in the shift log.
  ///
  /// In id, this message translates to:
  /// **'Meja {table}'**
  String meAuditTable(String table);

  /// Header above the table picker in the seat-a-reservation sheet. {action} is the seat action label.
  ///
  /// In id, this message translates to:
  /// **'{action} ke meja:'**
  String resvSeatToTable(String action);

  /// Header above the optional zone/table picker when creating a reservation.
  ///
  /// In id, this message translates to:
  /// **'Zona & meja (opsional)'**
  String get resvZoneTableOptional;

  /// Relative time: less than a minute ago.
  ///
  /// In id, this message translates to:
  /// **'baru saja'**
  String get elapsedJustNow;

  /// Relative time in minutes.
  ///
  /// In id, this message translates to:
  /// **'{n} menit lalu'**
  String elapsedMinutesAgo(int n);

  /// Relative time in hours.
  ///
  /// In id, this message translates to:
  /// **'{n} jam lalu'**
  String elapsedHoursAgo(int n);

  /// Owner report: the cloud fetch failed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat laporan.'**
  String get ownRptLoadFailed;

  /// Owner report: the venue has never uploaded a snapshot.
  ///
  /// In id, this message translates to:
  /// **'Belum ada laporan dari venue ini.'**
  String get ownRptNoneYet;

  /// Owner report: the stored snapshot does not parse — usually an older or newer venue build.
  ///
  /// In id, this message translates to:
  /// **'Format laporan tidak dikenal.'**
  String get ownRptUnknownFormat;

  /// Owner report freshness line while a refresh is in flight and nothing has ever arrived.
  ///
  /// In id, this message translates to:
  /// **'Meminta laporan…'**
  String get ownRptRequesting;

  /// Owner report freshness line when no snapshot exists.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data'**
  String get ownRptNoData;

  /// Owner report freshness line while waiting for a fresher snapshot.
  ///
  /// In id, this message translates to:
  /// **'Diperbarui {ago} · menunggu venue (mungkin offline)'**
  String ownRptUpdatedPending(String ago);

  /// Owner report freshness line.
  ///
  /// In id, this message translates to:
  /// **'Diperbarui {ago}'**
  String ownRptUpdated(String ago);

  /// Toast when a fleet edit is attempted with no cloud connection.
  ///
  /// In id, this message translates to:
  /// **'Tidak terhubung — perubahan tidak dikirim.'**
  String get fltNotConnected;

  /// Confirm dialog title for signing out of the fleet console.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari Fleet?'**
  String get fltSignOutTitle;

  /// Confirm dialog body: signing back in needs the credentials.
  ///
  /// In id, this message translates to:
  /// **'Perlu email & password lagi untuk masuk.'**
  String get fltSignOutBody;

  /// Confirm button: sign out of the fleet console.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get fltSignOut;

  /// Fleet list band heading: venues needing action.
  ///
  /// In id, this message translates to:
  /// **'PERLU TINDAKAN'**
  String get fltBandTrouble;

  /// Fleet list band heading: subscriptions about to lapse.
  ///
  /// In id, this message translates to:
  /// **'LANGGANAN AKAN BERAKHIR'**
  String get fltBandEnding;

  /// Fleet list band heading: venues whose server is not running.
  ///
  /// In id, this message translates to:
  /// **'TIDAK BERJALAN'**
  String get fltBandIdle;

  /// Fleet list band heading: healthy venues.
  ///
  /// In id, this message translates to:
  /// **'BERJALAN'**
  String get fltBandRunning;

  /// Placeholder for a venue or account with no name set.
  ///
  /// In id, this message translates to:
  /// **'(tanpa nama)'**
  String get fltUnnamed;

  /// Pill: the subscription ends at this point. {when} is a already-rendered relative phrase.
  ///
  /// In id, this message translates to:
  /// **'Berakhir {when}'**
  String fltEndsIn(String when);

  /// Menu action: bring a suspended venue back up.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan'**
  String get fltActivate;

  /// Menu action: suspend a venue, killing its server immediately.
  ///
  /// In id, this message translates to:
  /// **'Tangguhkan (kill)'**
  String get fltSuspendKill;

  /// Meta line: paid through this date.
  ///
  /// In id, this message translates to:
  /// **'s/d {date}'**
  String fltPaidUntil(String date);

  /// Pill: the term has lapsed and no cutoff date is known.
  ///
  /// In id, this message translates to:
  /// **'Tagihan lewat'**
  String get fltBillingOverdue;

  /// Pill: the venue was suspended on this date.
  ///
  /// In id, this message translates to:
  /// **'Ditangguhkan {date}'**
  String fltSuspendedOn(String date);

  /// Pill: overdue, and the sweep suspends it on this date.
  ///
  /// In id, this message translates to:
  /// **'Lewat — mati {date}'**
  String fltOverdueDiesOn(String date);

  /// Relative phrase: n days from now.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} hari}} lagi'**
  String fltDaysLeft(int n);

  /// Relative phrase: it happens today.
  ///
  /// In id, this message translates to:
  /// **'hari ini'**
  String get fltToday;

  /// Toast after activating a venue.
  ///
  /// In id, this message translates to:
  /// **'{name} diaktifkan'**
  String fltVenueActivated(String name);

  /// Confirm dialog title for suspending a venue.
  ///
  /// In id, this message translates to:
  /// **'Tangguhkan {name}?'**
  String fltSuspendTitle(String name);

  /// Confirm dialog body for suspending a venue.
  ///
  /// In id, this message translates to:
  /// **'Server venue mati sekarang juga dan semua staf terputus — termasuk di tengah jam ramai.'**
  String get fltSuspendBody;

  /// Toast after suspending a venue.
  ///
  /// In id, this message translates to:
  /// **'{name} ditangguhkan'**
  String fltVenueSuspended(String name);

  /// Toast after creating a venue.
  ///
  /// In id, this message translates to:
  /// **'Venue dibuat'**
  String get fltVenueCreated;

  /// Pill: the venue has exceeded its offline grace and will block on restart.
  ///
  /// In id, this message translates to:
  /// **'Lewat batas offline — akan terkunci saat restart'**
  String get fltLockoutPast;

  /// Pill: hours of offline grace left.
  ///
  /// In id, this message translates to:
  /// **'Mendekati batas offline {hours}j'**
  String fltLockoutNear(int hours);

  /// Meta: the venue has never checked in.
  ///
  /// In id, this message translates to:
  /// **'Belum online'**
  String get fltNeverOnline;

  /// Meta: the venue checked in within the last 90 seconds.
  ///
  /// In id, this message translates to:
  /// **'Online'**
  String get fltOnline;

  /// Meta: minutes since the venue last checked in.
  ///
  /// In id, this message translates to:
  /// **'Offline {n}m'**
  String fltOfflineMinutes(int n);

  /// Meta: hours since the venue last checked in.
  ///
  /// In id, this message translates to:
  /// **'Offline {n}j'**
  String fltOfflineHours(int n);

  /// Meta: days since the venue last checked in.
  ///
  /// In id, this message translates to:
  /// **'Offline {n}h'**
  String fltOfflineDays(int n);

  /// Card tag over the venue-admin accounts block.
  ///
  /// In id, this message translates to:
  /// **'AKUN'**
  String get fltTagAccount;

  /// Card tag over the owner (report-only) accounts block.
  ///
  /// In id, this message translates to:
  /// **'LAPORAN'**
  String get fltTagReports;

  /// Card tag over the venue identity fields.
  ///
  /// In id, this message translates to:
  /// **'DATA'**
  String get fltTagData;

  /// Card tag over the venue access / kill-switch block.
  ///
  /// In id, this message translates to:
  /// **'KENDALI'**
  String get fltTagControl;

  /// Card tag over the subscription block.
  ///
  /// In id, this message translates to:
  /// **'TAGIHAN'**
  String get fltTagBilling;

  /// Button: add a venue admin account.
  ///
  /// In id, this message translates to:
  /// **'Tambah admin'**
  String get fltAddAdmin;

  /// Button: add an owner (report-only) account.
  ///
  /// In id, this message translates to:
  /// **'Tambah pemilik'**
  String get fltAddOwner;

  /// Empty state for the venue-admin list.
  ///
  /// In id, this message translates to:
  /// **'Belum ada admin untuk venue ini.'**
  String get fltNoAdmins;

  /// Empty state for the owner list, spelling out what an owner is.
  ///
  /// In id, this message translates to:
  /// **'Belum ada akun pemilik — akses baca laporan dari luar venue, bukan peran staf.'**
  String get fltNoOwners;

  /// Validation: the venue name cannot be blank.
  ///
  /// In id, this message translates to:
  /// **'Nama wajib diisi'**
  String get fltNameRequired;

  /// What an active venue status means in practice.
  ///
  /// In id, this message translates to:
  /// **'Server venue berjalan dan staf bisa masuk seperti biasa.'**
  String get fltAccessActive;

  /// What a suspended venue status means in practice.
  ///
  /// In id, this message translates to:
  /// **'Server venue mati. Staf tidak bisa masuk sampai diaktifkan lagi.'**
  String get fltAccessSuspended;

  /// What an unrecognised venue status means in practice.
  ///
  /// In id, this message translates to:
  /// **'Status tidak dikenali di cloud. Venue tetap tidak bisa melayani. Setel ulang dengan tombol di bawah.'**
  String get fltAccessUnknown;

  /// Placeholder inside a date row when no date is set.
  ///
  /// In id, this message translates to:
  /// **'belum diatur'**
  String get fltNotSetLower;

  /// Placeholder for an unset paid-through date.
  ///
  /// In id, this message translates to:
  /// **'Belum diatur'**
  String get fltNotSet;

  /// Menu action: mint a temporary password for an account.
  ///
  /// In id, this message translates to:
  /// **'Reset password'**
  String get fltResetPassword;

  /// Toast after activating an account.
  ///
  /// In id, this message translates to:
  /// **'{name} diaktifkan'**
  String fltAdminActivated(String name);

  /// Toast after suspending an account.
  ///
  /// In id, this message translates to:
  /// **'{name} ditangguhkan'**
  String fltAdminSuspended(String name);

  /// Toast after deleting an account or venue.
  ///
  /// In id, this message translates to:
  /// **'{name} dihapus'**
  String fltAdminDeleted(String name);

  /// Confirm dialog title for deleting an account.
  ///
  /// In id, this message translates to:
  /// **'Hapus {name}?'**
  String fltDeleteAdminTitle(String name);

  /// Confirm dialog body for deleting an account. {who} is the email or uid.
  ///
  /// In id, this message translates to:
  /// **'Akun login & datanya dihapus permanen. {who} tidak bisa masuk lagi.'**
  String fltDeleteAdminBody(String who);

  /// Toast after copying the temporary password.
  ///
  /// In id, this message translates to:
  /// **'Kode disalin'**
  String get fltCodeCopied;

  /// Confirm dialog title for deleting a venue.
  ///
  /// In id, this message translates to:
  /// **'Hapus {name}?'**
  String fltDeleteVenueTitle(String name);

  /// Confirm dialog body for deleting a venue.
  ///
  /// In id, this message translates to:
  /// **'Venue dihapus permanen dari fleet. Tidak bisa dibatalkan.'**
  String get fltDeleteVenueBody;

  /// Note beside a paid-through date already in the past.
  ///
  /// In id, this message translates to:
  /// **'Sudah lewat'**
  String get fltAlreadyPassed;

  /// Date row label on a trial plan.
  ///
  /// In id, this message translates to:
  /// **'Selesai coba'**
  String get fltTrialEnds;

  /// Date row label on a paid plan.
  ///
  /// In id, this message translates to:
  /// **'Berlaku sampai'**
  String get fltValidUntil;

  /// Explains the automatic suspend date on a trial.
  ///
  /// In id, this message translates to:
  /// **'Venue ditangguhkan otomatis {date}, tepat saat masa coba habis.'**
  String fltCutoffTrial(String date);

  /// Explains the automatic suspend date on a paid plan.
  ///
  /// In id, this message translates to:
  /// **'Venue ditangguhkan otomatis {date} — 7 hari tenggang setelah jatuh tempo.'**
  String fltCutoffPaid(String date);

  /// Validation: the email does not parse.
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid'**
  String get fltEmailInvalid;

  /// Validation: the initial password is too short.
  ///
  /// In id, this message translates to:
  /// **'Minimal 6 karakter'**
  String get fltPasswordMin;

  /// Staff error: no free PIN could be minted.
  ///
  /// In id, this message translates to:
  /// **'Semua PIN 6 digit sudah terpakai.'**
  String get staffErrPinPoolExhausted;

  /// Staff error: the PIN is not six digits.
  ///
  /// In id, this message translates to:
  /// **'PIN harus 6 digit.'**
  String get staffErrPinLength;

  /// Staff error: another user already has this PIN.
  ///
  /// In id, this message translates to:
  /// **'PIN sudah dipakai staf lain.'**
  String get staffErrPinInUse;

  /// Staff error: the server rejected the PIN change. {status} is the HTTP status.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengubah PIN ({status}).'**
  String staffErrPinUpdateFailed(String status);

  /// Staff error: the change would leave the venue with nobody who can manage staff.
  ///
  /// In id, this message translates to:
  /// **'Harus ada minimal satu pengguna aktif dengan kapabilitas “Kelola staf”.'**
  String get staffErrLastAdmin;

  /// Alert sound preset: no sound.
  ///
  /// In id, this message translates to:
  /// **'Senyap'**
  String get sndSilent;

  /// Alert sound preset: a bell.
  ///
  /// In id, this message translates to:
  /// **'Bel'**
  String get sndBell;

  /// Alert sound preset: a click.
  ///
  /// In id, this message translates to:
  /// **'Klik'**
  String get sndClick;

  /// Alert sound preset: an urgent alarm.
  ///
  /// In id, this message translates to:
  /// **'Alarm Kritis'**
  String get sndCriticalAlarm;

  /// Alert sound preset: a doorbell.
  ///
  /// In id, this message translates to:
  /// **'Bel Pintu'**
  String get sndDoorbell;

  /// Alert sound preset: a facility alarm.
  ///
  /// In id, this message translates to:
  /// **'Alarm Fasilitas'**
  String get sndFacilityAlarm;

  /// Alert sound preset: an arcade-style alarm.
  ///
  /// In id, this message translates to:
  /// **'Alarm Game'**
  String get sndGameAlarm;

  /// Alert sound preset: a cheerful bell.
  ///
  /// In id, this message translates to:
  /// **'Lonceng Ceria'**
  String get sndHappyBell;

  /// Alert sound preset: a harp.
  ///
  /// In id, this message translates to:
  /// **'Harpa'**
  String get sndHarp;

  /// Alert sound preset: a delete/undo blip.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get sndRemove;

  /// Alert sound preset: a short alarm.
  ///
  /// In id, this message translates to:
  /// **'Alarm Pendek'**
  String get sndShortAlarm;

  /// Alert sound preset: a start cue.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get sndStart;

  /// Shift summary word, joined as "3 ditahan". Lower case on purpose — it sits mid-sentence.
  ///
  /// In id, this message translates to:
  /// **'ditahan'**
  String get meShiftHeld;

  /// Shift summary word, joined as "3 terkirim".
  ///
  /// In id, this message translates to:
  /// **'terkirim'**
  String get meShiftSent;

  /// Shift summary word, joined as "3 disiapkan".
  ///
  /// In id, this message translates to:
  /// **'disiapkan'**
  String get meShiftPrep;

  /// Shift summary word, joined as "3 matang".
  ///
  /// In id, this message translates to:
  /// **'matang'**
  String get meShiftCooked;

  /// Shift summary word, joined as "3 siap".
  ///
  /// In id, this message translates to:
  /// **'siap'**
  String get meShiftReady;

  /// Menu card badge on the venue hub
  ///
  /// In id, this message translates to:
  /// **'{items, plural, other{{items} item}} · {cats, plural, other{{cats} kategori}}'**
  String venueHubBadgeMenu(int items, int cats);

  /// Stock card badge when ingredients are low
  ///
  /// In id, this message translates to:
  /// **'{n} perhatian'**
  String venueHubBadgeStockLow(int n);

  /// Stock card badge when nothing is low
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} bahan}}'**
  String venueHubBadgeStockOk(int n);

  /// Venue settings card badge: tax and service rates
  ///
  /// In id, this message translates to:
  /// **'Pajak {tax}% · Service {svc}%'**
  String venueHubBadgeVenue(String tax, String svc);

  /// Venue header chip when the LAN server is reachable
  ///
  /// In id, this message translates to:
  /// **'LAN AKTIF'**
  String get venueHubLanActive;

  /// Venue header chip when running without a LAN server
  ///
  /// In id, this message translates to:
  /// **'LOKAL'**
  String get venueHubLanLocal;

  /// Compact rupiah in the millions on a report tile. Only the magnitude word translates; the digits and Rp stay id_ID (ADR-0084).
  ///
  /// In id, this message translates to:
  /// **'Rp {v}jt'**
  String moneyCompactJt(String v);

  /// Compact rupiah in the thousands on a report tile.
  ///
  /// In id, this message translates to:
  /// **'Rp {v}rb'**
  String moneyCompactRb(String v);

  /// Compact rupiah under a thousand — nothing to abbreviate.
  ///
  /// In id, this message translates to:
  /// **'Rp {v}'**
  String moneyCompactPlain(String v);

  /// No description provided for @memTitle.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get memTitle;

  /// No description provided for @memCount.
  ///
  /// In id, this message translates to:
  /// **'{count} terdaftar'**
  String memCount(int count);

  /// No description provided for @memSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau nomor'**
  String get memSearchHint;

  /// No description provided for @memActionAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get memActionAdd;

  /// No description provided for @memBirthdayFilter.
  ///
  /// In id, this message translates to:
  /// **'Ulang tahun bulan ini'**
  String get memBirthdayFilter;

  /// No description provided for @memEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pelanggan'**
  String get memEmptyTitle;

  /// No description provided for @memEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Daftarkan tamu langganan lewat tombol Tambah, atau dari layar tagihan saat mereka bayar.'**
  String get memEmptyBody;

  /// No description provided for @memOffTitle.
  ///
  /// In id, this message translates to:
  /// **'Keanggotaan tidak aktif'**
  String get memOffTitle;

  /// No description provided for @memOffBody.
  ///
  /// In id, this message translates to:
  /// **'Nyalakan di Pengaturan venue → Keanggotaan. Poin dan stempel yang sudah tercatat tetap utuh.'**
  String get memOffBody;

  /// No description provided for @memPhoneOnly.
  ///
  /// In id, this message translates to:
  /// **'Buka di tablet. Daftar pelanggan dibaca baris per baris, dan layar telepon cuma muat satu.'**
  String get memPhoneOnly;

  /// No description provided for @memPoints.
  ///
  /// In id, this message translates to:
  /// **'{points} poin'**
  String memPoints(int points);

  /// No description provided for @memPunch.
  ///
  /// In id, this message translates to:
  /// **'Stempel {progress}/{target}'**
  String memPunch(int progress, int target);

  /// No description provided for @memRewardDue.
  ///
  /// In id, this message translates to:
  /// **'Hadiah siap'**
  String get memRewardDue;

  /// No description provided for @memVisits.
  ///
  /// In id, this message translates to:
  /// **'{count} kunjungan'**
  String memVisits(int count);

  /// No description provided for @memColPoints.
  ///
  /// In id, this message translates to:
  /// **'Poin'**
  String get memColPoints;

  /// No description provided for @memColPunch.
  ///
  /// In id, this message translates to:
  /// **'Stempel'**
  String get memColPunch;

  /// No description provided for @memColVisits.
  ///
  /// In id, this message translates to:
  /// **'Kunjungan'**
  String get memColVisits;

  /// No description provided for @memColLifetime.
  ///
  /// In id, this message translates to:
  /// **'Total belanja'**
  String get memColLifetime;

  /// No description provided for @memColJoined.
  ///
  /// In id, this message translates to:
  /// **'Bergabung'**
  String get memColJoined;

  /// No description provided for @memLedgerTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat poin'**
  String get memLedgerTitle;

  /// No description provided for @memLedgerLoading.
  ///
  /// In id, this message translates to:
  /// **'Memuat riwayat…'**
  String get memLedgerLoading;

  /// No description provided for @memLedgerEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada gerakan poin.'**
  String get memLedgerEmpty;

  /// No description provided for @memSheetAddTitle.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan baru'**
  String get memSheetAddTitle;

  /// No description provided for @memSheetEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah pelanggan'**
  String get memSheetEditTitle;

  /// No description provided for @memFieldName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get memFieldName;

  /// No description provided for @memFieldPhone.
  ///
  /// In id, this message translates to:
  /// **'Nomor HP'**
  String get memFieldPhone;

  /// No description provided for @memPhoneHelp.
  ///
  /// In id, this message translates to:
  /// **'Nomor HP adalah identitasnya. 0812…, +62812… dan 62812… dianggap satu orang.'**
  String get memPhoneHelp;

  /// No description provided for @memFieldNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get memFieldNote;

  /// No description provided for @memFieldBirthday.
  ///
  /// In id, this message translates to:
  /// **'Ulang tahun'**
  String get memFieldBirthday;

  /// No description provided for @memPickBirthday.
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal lahir'**
  String get memPickBirthday;

  /// No description provided for @memSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get memSave;

  /// No description provided for @memActionEdit.
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get memActionEdit;

  /// No description provided for @memActionAdjust.
  ///
  /// In id, this message translates to:
  /// **'Koreksi poin'**
  String get memActionAdjust;

  /// No description provided for @memActionMerge.
  ///
  /// In id, this message translates to:
  /// **'Gabungkan'**
  String get memActionMerge;

  /// No description provided for @memActionDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get memActionDelete;

  /// No description provided for @memAdjustTitle.
  ///
  /// In id, this message translates to:
  /// **'Koreksi poin'**
  String get memAdjustTitle;

  /// No description provided for @memAdjustAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get memAdjustAdd;

  /// No description provided for @memAdjustSubtract.
  ///
  /// In id, this message translates to:
  /// **'Kurangi'**
  String get memAdjustSubtract;

  /// No description provided for @memFieldDelta.
  ///
  /// In id, this message translates to:
  /// **'Jumlah poin'**
  String get memFieldDelta;

  /// No description provided for @memFieldReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan'**
  String get memFieldReason;

  /// No description provided for @memMergeTitle.
  ///
  /// In id, this message translates to:
  /// **'Gabungkan pelanggan'**
  String get memMergeTitle;

  /// No description provided for @memMergeBody.
  ///
  /// In id, this message translates to:
  /// **'{name} akan dilebur ke pelanggan yang dipilih. Poin dan riwayatnya ikut pindah, lalu catatannya dihapus.'**
  String memMergeBody(String name);

  /// No description provided for @memDeleteTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus pelanggan?'**
  String get memDeleteTitle;

  /// No description provided for @memDeleteBody.
  ///
  /// In id, this message translates to:
  /// **'{name} dan riwayat poinnya hilang permanen. Transaksi yang pernah dibuat tetap terhitung di laporan.'**
  String memDeleteBody(String name);

  /// No description provided for @memErrNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama wajib diisi.'**
  String get memErrNameRequired;

  /// No description provided for @memErrPhoneRequired.
  ///
  /// In id, this message translates to:
  /// **'Nomor HP wajib diisi.'**
  String get memErrPhoneRequired;

  /// No description provided for @memErrPhoneTaken.
  ///
  /// In id, this message translates to:
  /// **'Nomor ini sudah dipakai pelanggan lain.'**
  String get memErrPhoneTaken;

  /// No description provided for @memErrNotFound.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan tidak ditemukan.'**
  String get memErrNotFound;

  /// No description provided for @memErrSameMember.
  ///
  /// In id, this message translates to:
  /// **'Pilih pelanggan yang berbeda.'**
  String get memErrSameMember;

  /// No description provided for @memErrReasonRequired.
  ///
  /// In id, this message translates to:
  /// **'Alasan wajib diisi.'**
  String get memErrReasonRequired;

  /// No description provided for @memErrInvalidAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah tidak sah.'**
  String get memErrInvalidAmount;

  /// No description provided for @memErrPointsOff.
  ///
  /// In id, this message translates to:
  /// **'Poin sedang dibekukan.'**
  String get memErrPointsOff;

  /// No description provided for @memErrBelowMin.
  ///
  /// In id, this message translates to:
  /// **'Penukaran minimal {points} poin.'**
  String memErrBelowMin(int points);

  /// No description provided for @memErrInsufficient.
  ///
  /// In id, this message translates to:
  /// **'Poin tersedia cuma {points}.'**
  String memErrInsufficient(int points);

  /// No description provided for @memErrExceedsBill.
  ///
  /// In id, this message translates to:
  /// **'Maksimal {points} poin untuk tagihan ini.'**
  String memErrExceedsBill(int points);

  /// No description provided for @memErrRedeemExists.
  ///
  /// In id, this message translates to:
  /// **'Sudah ada penukaran poin di tagihan ini.'**
  String get memErrRedeemExists;

  /// No description provided for @memErrFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal: {code}'**
  String memErrFailed(String code);

  /// No description provided for @memPointKindEarn.
  ///
  /// In id, this message translates to:
  /// **'Dapat'**
  String get memPointKindEarn;

  /// No description provided for @memPointKindRedeem.
  ///
  /// In id, this message translates to:
  /// **'Tukar'**
  String get memPointKindRedeem;

  /// No description provided for @memPointKindAdjust.
  ///
  /// In id, this message translates to:
  /// **'Koreksi'**
  String get memPointKindAdjust;

  /// No description provided for @memPointKindReversal.
  ///
  /// In id, this message translates to:
  /// **'Balik'**
  String get memPointKindReversal;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Poin, stempel, dan daftar tamu langganan'**
  String get memHubSubtitle;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get memHubBadgeOn;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get memHubBadgeOff;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Keanggotaan'**
  String get vstSectionMembers;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Program'**
  String get vstMembersTag;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan keanggotaan'**
  String get vstMembersEnable;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Daftar pelanggan, poin, dan stempel. Venue tanpa program langganan biarkan mati.'**
  String get vstMembersEnableHint;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Poin'**
  String get vstMembersPoints;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Dimatikan berarti poin dibekukan, bukan dihapus — saldo tamu tetap utuh.'**
  String get vstMembersPointsHint;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Poin per Rp 1.000'**
  String get vstMembersEarnRate;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Dihitung dari tagihan bersih, sebelum layanan dan pajak.'**
  String get vstMembersEarnRateHint;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Nilai 1 poin'**
  String get vstMembersPointValue;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Berapa rupiah potongan untuk satu poin yang ditukar.'**
  String get vstMembersPointValueHint;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Tukar minimal'**
  String get vstMembersRedeemMin;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Batas bawah sekali penukaran.'**
  String get vstMembersRedeemMinHint;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Kartu stempel'**
  String get vstMembersPunch;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Beli sekian, gratis satu. Hadiahnya dibukukan sebagai komplimen.'**
  String get vstMembersPunchHint;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Menu yang distempel'**
  String get vstMembersPunchItem;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Belum dipilih'**
  String get vstMembersPunchItemNone;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Stempel per hadiah'**
  String get vstMembersPunchTarget;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Berapa porsi dibeli sebelum yang berikutnya gratis.'**
  String get vstMembersPunchTargetHint;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Diskon anggota'**
  String get vstMembersPreset;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Tanpa diskon tetap'**
  String get vstMembersPresetNone;

  /// Membership settings and hub copy.
  ///
  /// In id, this message translates to:
  /// **'Preset diskon tagihan yang otomatis dipasang begitu pelanggan dikaitkan ke tagihan.'**
  String get vstMembersPresetHint;

  /// The member row on a live bill.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pelanggan'**
  String get cshMemberNone;

  /// The member row on a live bill.
  ///
  /// In id, this message translates to:
  /// **'Cari pelanggan'**
  String get cshMemberFind;

  /// The member row on a live bill.
  ///
  /// In id, this message translates to:
  /// **'Daftar baru'**
  String get cshMemberEnrol;

  /// The member row on a live bill.
  ///
  /// In id, this message translates to:
  /// **'Lepas'**
  String get cshMemberDetach;

  /// The member row on a live bill.
  ///
  /// In id, this message translates to:
  /// **'Tukar poin'**
  String get cshMemberRedeem;

  /// The member row on a live bill.
  ///
  /// In id, this message translates to:
  /// **'Batal tukar ({amount})'**
  String cshMemberRedeemUndo(String amount);

  /// The member row on a live bill.
  ///
  /// In id, this message translates to:
  /// **'Maksimal {points} poin untuk tagihan ini.'**
  String cshMemberRedeemMax(int points);

  /// The member row on a live bill.
  ///
  /// In id, this message translates to:
  /// **'Potongan {amount}'**
  String cshMemberRedeemWorth(String amount);

  /// The member row on a live bill.
  ///
  /// In id, this message translates to:
  /// **'Tukar semua'**
  String get cshMemberRedeemAll;

  /// No description provided for @pinManualConnectBtn.
  ///
  /// In id, this message translates to:
  /// **'Hubungkan manual'**
  String get pinManualConnectBtn;

  /// No description provided for @pinManualEntryTitle.
  ///
  /// In id, this message translates to:
  /// **'Hubungkan Manual'**
  String get pinManualEntryTitle;

  /// No description provided for @pinManualEntryDescription.
  ///
  /// In id, this message translates to:
  /// **'Masukkan alamat IP dan port server untuk terhubung secara manual jika tidak terdeteksi otomatis.'**
  String get pinManualEntryDescription;

  /// No description provided for @pinManualEntryLabel.
  ///
  /// In id, this message translates to:
  /// **'ALAMAT IP SERVER'**
  String get pinManualEntryLabel;

  /// No description provided for @pinManualEntryEmpty.
  ///
  /// In id, this message translates to:
  /// **'Alamat IP tidak boleh kosong'**
  String get pinManualEntryEmpty;

  /// No description provided for @pinManualEntryNotFound.
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat terhubung ke server. Periksa alamat IP dan Wi-Fi.'**
  String get pinManualEntryNotFound;

  /// Report section title: staff attendance hours.
  ///
  /// In id, this message translates to:
  /// **'Jam kerja'**
  String get rptSecJamKerja;

  /// Subtitle: how many staff, and that hours come only from closed shifts.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} staf}} · dari shift yang ditutup'**
  String rptJamKerjaSub(int n);

  /// Empty state when no shift was recorded in the range.
  ///
  /// In id, this message translates to:
  /// **'Belum ada shift tercatat di rentang ini.'**
  String get rptJamEmpty;

  /// Worked time, hours and minutes.
  ///
  /// In id, this message translates to:
  /// **'{h}j {m}m'**
  String rptJamHours(int h, int m);

  /// Days worked and shift count for one staff member.
  ///
  /// In id, this message translates to:
  /// **'{d, plural, other{{d} hari}} · {s, plural, other{{s} shift}}'**
  String rptJamDaysShifts(int d, int s);

  /// Median clock-in time for one staff member.
  ///
  /// In id, this message translates to:
  /// **'masuk ±{clock}'**
  String rptJamFirstIn(String clock);

  /// Badge: shifts the rollover had to close.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, other{{n} shift tak ditutup}}'**
  String rptJamUnclosed(int n);

  /// When an unclosed shift last did something auditable.
  ///
  /// In id, this message translates to:
  /// **'aktivitas terakhir {clock}'**
  String rptJamLastSeen(String clock);

  /// Caveat under the section title when unclosed shifts exist.
  ///
  /// In id, this message translates to:
  /// **'Shift yang tak ditutup tidak dihitung sebagai jam kerja.'**
  String get rptJamUnclosedNote;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'id':
      return AppL10nId();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
