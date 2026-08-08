// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppL10nId extends AppL10n {
  AppL10nId([String locale = 'id']) : super(locale);

  @override
  String get cancel => 'Batal';

  @override
  String get save => 'Simpan';

  @override
  String get saved => 'Tersimpan';

  @override
  String get delete => 'Hapus';

  @override
  String get add => 'Tambah';

  @override
  String get edit => 'Ubah';

  @override
  String get back => 'Kembali';

  @override
  String get close => 'Tutup';

  @override
  String get loading => 'Memuat…';

  @override
  String get error => 'Gagal';

  @override
  String get active => 'Aktif';

  @override
  String get inactive => 'Nonaktif';

  @override
  String get warning => 'Peringatan';

  @override
  String get confirm => 'Konfirmasi';

  @override
  String get ok => 'OK';

  @override
  String get discardCartTitle => 'Batalkan pesanan ini?';

  @override
  String discardCartBody(int items) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items item belum terkirim akan dihapus.',
      one: '1 item belum terkirim akan dihapus.',
    );
    return '$_temp0';
  }

  @override
  String get discardCartConfirm => 'Ya, batalkan';

  @override
  String get stepperIncrease => 'Tambah satu';

  @override
  String get stepperDecrease => 'Kurangi satu';

  @override
  String get venueHubTitle => 'Venue';

  @override
  String get venueHubSubtitle => 'Konfigurasi · zona · menu · sistem · staf';

  @override
  String get venueHubSectionZona => 'Zona';

  @override
  String get venueHubSectionZonaSub => 'Atur zona, meja, dan kapasitas ruangan';

  @override
  String get venueHubSectionMenu => 'Menu';

  @override
  String get venueHubSectionMenuSub => 'Kategori, item, modifier, dan harga';

  @override
  String get venueHubSectionVenue => 'Pengaturan Venue';

  @override
  String get venueHubSectionVenueSub =>
      'Profil, lokal, pajak, dan branding struk';

  @override
  String get venueHubSectionSystem => 'Sistem';

  @override
  String get venueHubSectionSystemSub => 'Server, jaringan, printer, perangkat';

  @override
  String get venueHubSectionStaff => 'Staf';

  @override
  String get venueHubSectionStaffSub => 'Akun, peran, dan PIN tim';

  @override
  String get venueHubSectionStock => 'Stok';

  @override
  String get venueHubSectionStockSub =>
      'Bahan, terima barang, opname, dan produksi';

  @override
  String get venueHubSectionReports => 'Laporan';

  @override
  String get venueHubSectionReportsSub =>
      'Ringkasan shift, penjualan, dan ekspor';

  @override
  String get venueHubSectionAlerts => 'Peringatan';

  @override
  String get venueHubSectionAlertsSub =>
      'Ambang waktu, suara, dan senyap perangkat';

  @override
  String get venueHubSectionAudit => 'Audit';

  @override
  String get venueHubSectionAuditSub =>
      'Batal, gratis, diskon, dan ubah pesanan';

  @override
  String get auditTitle => 'Catatan audit';

  @override
  String get auditSubtitle => 'Semua kejadian · jejak lengkap';

  @override
  String get auditTabletOnly => 'Butuh layar tablet';

  @override
  String get auditTabletOnlyBody =>
      'Catatan audit menampilkan enam kolom sekaligus supaya bisa dibaca sekilas. Buka dari tablet.';

  @override
  String get auditTabletOnlyBadge => 'Tablet saja';

  @override
  String get auditEmpty => 'Belum ada kejadian';

  @override
  String get auditEmptyBody =>
      'Pembatalan, gratisan, diskon, refund, dan perubahan pesanan akan tampil di sini.';

  @override
  String get auditExport => 'Ekspor';

  @override
  String get auditColTime => 'Waktu';

  @override
  String get auditColType => 'Jenis';

  @override
  String get auditColUser => 'Pengguna';

  @override
  String get auditColEvent => 'Kejadian';

  @override
  String get auditColAmount => 'Jumlah';

  @override
  String get auditColReason => 'Alasan';

  @override
  String get auditSystemActor => 'Sistem';

  @override
  String get auditWindowToday => 'Hari ini';

  @override
  String get auditWindowYesterday => 'Kemarin';

  @override
  String get auditWindowWeek => '7 hari';

  @override
  String get auditWindowAll => 'Semua waktu';

  @override
  String get auditTypeAll => 'Semua jenis';

  @override
  String get auditTileVoid => 'Pembatalan';

  @override
  String get auditTileComp => 'Gratisan';

  @override
  String get auditTileDiscount => 'Diskon';

  @override
  String get auditTileRefund => 'Refund';

  @override
  String get auditTileKilled => 'Stop jual';

  @override
  String get auditTileModify => 'Ubah pesanan';

  @override
  String auditEventCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kejadian',
      one: '1 kejadian',
    );
    return '$_temp0';
  }

  @override
  String auditNewRows(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n baru',
      one: '1 baru',
    );
    return '$_temp0';
  }

  @override
  String get auditTypeFire => 'Kirim';

  @override
  String get auditTypeModify => 'Ubah';

  @override
  String get auditTypeVoidItem => 'Batal';

  @override
  String get auditTypeComp => 'Gratis';

  @override
  String get auditTypeTableMoved => 'Pindah';

  @override
  String get auditTypePaymentRecorded => 'Bayar';

  @override
  String get auditTypeRefund => 'Refund';

  @override
  String get auditTypeDiscountApplied => 'Diskon';

  @override
  String get auditTypeDiscountRemoved => 'Diskon−';

  @override
  String get auditTypeBillReopened => 'Buka';

  @override
  String get auditTypeBillClosed => 'Tutup';

  @override
  String get auditTypeCashMovement => 'Kas';

  @override
  String get auditTypeMenuKilled => 'Stop jual';

  @override
  String get auditTypeMenuRestored => 'Jual lagi';

  @override
  String get auditTypeStaffCreated => 'Staf +';

  @override
  String get auditTypeStaffDeleted => 'Staf −';

  @override
  String get auditTypeStaffDisabled => 'Nonaktif';

  @override
  String get auditTypeStaffEnabled => 'Aktif';

  @override
  String get auditTypeStaffRoleChanged => 'Peran';

  @override
  String get auditTypeStaffPinSet => 'PIN';

  @override
  String get auditTypeStaffPinReset => 'PIN reset';

  @override
  String get auditTypeRoleCreated => 'Peran +';

  @override
  String get auditTypeRoleRenamed => 'Peran ubah';

  @override
  String get auditTypeRoleDeleted => 'Peran −';

  @override
  String get auditTypeRoleColorChanged => 'Peran warna';

  @override
  String get auditTypeRoleCapabilityChanged => 'Hak akses';

  @override
  String get killReasonTitle => 'Stop jual';

  @override
  String get killReasonHint => 'Alasan lain (opsional)';

  @override
  String get killReasonSkip => 'Lewati';

  @override
  String get killReasonConfirm => 'Stop jual';

  @override
  String killReasonBody(String item) {
    return '$item tidak bisa dipesan sampai diaktifkan lagi. Alasannya masuk catatan audit.';
  }

  @override
  String get venueHubSeedTitle => 'Mulai cepat';

  @override
  String get venueHubSeedBody =>
      'Muat contoh data restoran umum: 4 zona dengan 20 meja, menu lengkap, 4 staf (2 pelayan & 2 dapur), dan sebulan riwayat penjualan supaya laporan dan catatan audit langsung terbaca. Semua bisa diubah atau dihapus kapan saja.';

  @override
  String get venueHubSeedBodyRunning =>
      'Menyusun sebulan riwayat lewat jalur pesanan sungguhan. Biarkan aplikasi terbuka sampai selesai.';

  @override
  String get venueHubSeedBodyDone =>
      'Contoh data siap. Laporan, catatan audit dan riwayat stok sudah terisi.';

  @override
  String get venueHubSeedBodyIncomplete =>
      'Pemuatan contoh data terhenti sebelum selesai. Data yang ada tidak utuh — hapus dulu sebelum memuat ulang.';

  @override
  String get venueHubSeedBodyFailed =>
      'Pemuatan contoh data gagal. Data yang sempat masuk tidak utuh — hapus dulu sebelum mencoba lagi.';

  @override
  String get venueHubSeedBodyLoaded =>
      'Venue ini memakai contoh data. Hapus untuk membuang riwayat penjualan buatan; zona, meja, menu dan staf tetap ada.';

  @override
  String get venueHubSeedBtnLoad => 'Muat contoh data';

  @override
  String get venueHubSeedBtnSkip => 'Lewati';

  @override
  String get venueHubSeedBtnClear => 'Hapus contoh data';

  @override
  String get venueHubSeedBtnClearRetry => 'Hapus & muat ulang';

  @override
  String get venueHubSeedBtnDone => 'Selesai';

  @override
  String get venueHubSeedError => 'Gagal memuat contoh data';

  @override
  String get venueHubSeedProgress => 'Menyusun contoh data';

  @override
  String venueHubSeedDays(int done, int total) {
    return 'hari $done/$total';
  }

  @override
  String get settingsSeedTitle => 'Contoh data';

  @override
  String get venueSettingsTitle => 'Pengaturan Venue';

  @override
  String get venueSettingsSubtitle => 'Profil, lokal, pajak, struk';

  @override
  String get venueSettingsSectionIdentity => 'Profil & alamat';

  @override
  String get venueSettingsSectionIdentityTag => 'WAJIB';

  @override
  String get venueSettingsDisplayName => 'Nama tampilan';

  @override
  String get venueSettingsLegalName => 'Nama legal';

  @override
  String get venueSettingsAddress => 'Alamat';

  @override
  String get venueSettingsPhone => 'Telepon';

  @override
  String get venueSettingsManagedBySuperAdmin => 'Dikelola pengelola';

  @override
  String get venueSettingsSectionReceipt => 'Branding struk';

  @override
  String get venueSettingsSectionReceiptTag => 'CETAK';

  @override
  String get venueSettingsLogo => 'Logo';

  @override
  String get venueSettingsLogoAdd => 'Tambah';

  @override
  String get venueSettingsLogoChange => 'Ganti';

  @override
  String get venueSettingsLogoDelete => 'Hapus';

  @override
  String get venueSettingsTagline => 'Tagline';

  @override
  String get venueSettingsHeader => 'Header';

  @override
  String get venueSettingsSocial => 'Sosial';

  @override
  String get venueSettingsFooter => 'Footer';

  @override
  String get venueSettingsThankYou => 'Ucapan terima kasih';

  @override
  String get venueSettingsQrUrl => 'QR (URL)';

  @override
  String get venueSettingsQrCaption => 'QR (keterangan)';

  @override
  String get venueSettingsSectionTax => 'Pajak & layanan';

  @override
  String get venueSettingsSectionReports => 'Laporan & shift';

  @override
  String get venueSettingsSectionSound => 'Suara';

  @override
  String get venueSettingsSoundNewOrder => 'Pesanan baru';

  @override
  String get venueSettingsSoundReady => 'Pesanan siap';

  @override
  String get venueSettingsSoundVoid => 'Void';

  @override
  String get venueSettingsSoundOverdue => 'Lewat waktu';

  @override
  String get venueSettingsSoundUngreeted => 'Belum dilayani';

  @override
  String get venueSettingsSoundPickup => 'Menunggu diantar';

  @override
  String get venueSettingsSoundPreview => 'Dengar';

  @override
  String get venueSettingsTimingPrepTarget =>
      'Target siap (default semua menu)';

  @override
  String get venueSettingsTimingPrepTargetHint =>
      'Menu tanpa \"Waktu siap\" sendiri ikut angka ini.';

  @override
  String get venueSettingsTimingPickup => 'Menunggu diantar';

  @override
  String get venueSettingsTimingPickupHint =>
      'Makanan siap tapi belum diantar selama ini. Saklar mematikan bunyinya saja — tanda di kartu meja tetap jalan.';

  @override
  String get venueSettingsTimingUngreeted => 'Belum dilayani';

  @override
  String get venueSettingsTimingUngreetedHint =>
      'Meja terisi tapi belum ada pesanan terkirim. Saklar mematikan bunyinya saja — tanda di kartu meja tetap jalan.';

  @override
  String get venueSettingsTimingUngreetedEscalate =>
      'Naik ke semua waiter setelah';

  @override
  String get venueSettingsTimingUngreetedEscalateHint =>
      'Awalnya hanya waiter yang mendudukkan tamu.';

  @override
  String get venueSettingsTimingLongStay => 'Meja lama';

  @override
  String get venueSettingsTimingLongStayHint =>
      'Tanda visual di lantai. Tanpa suara.';

  @override
  String get venueSettingsTimingIdle => 'Meja selesai makan';

  @override
  String get venueSettingsTimingIdleHint =>
      'Semua terhidang dan tidak ada aktivitas. Tanpa suara.';

  @override
  String get venueSettingsTimingReservationGrace => 'Toleransi reservasi';

  @override
  String get venueSettingsTimingReservationGraceHint =>
      'Lewat ini chip reservasi ditandai terlambat. Status tidak berubah.';

  @override
  String get venueSettingsTimingMuteTitle => 'Senyapkan di alat ini';

  @override
  String get venueSettingsTimingMuteHint =>
      'Hanya untuk alat ini. Pilihan nada tetap milik venue.';

  @override
  String get alertsTitle => 'Peringatan';

  @override
  String get alertsSectionThresholds => 'Ambang waktu';

  @override
  String get alertsScopeVenue => 'Semua perangkat';

  @override
  String get alertsScopeDevice => 'Hanya perangkat ini';

  @override
  String get tableStateUngreeted => 'Belum dilayani';

  @override
  String get tableStateIdle => 'Selesai makan';

  @override
  String get reservationLate => 'Terlambat';

  @override
  String staleReadyUncollected(int mins) {
    return 'Siap $mins mnt — belum diambil';
  }

  @override
  String staleReservationLate(int mins) {
    return 'Tamu telat $mins mnt — lepas meja?';
  }

  @override
  String staleUngreeted(int mins) {
    return 'Belum disapa $mins mnt';
  }

  @override
  String staleIdle(int mins) {
    return 'Selesai makan $mins mnt — tawarkan lagi';
  }

  @override
  String staleLongStay(String elapsed) {
    return 'Duduk $elapsed — cek penutupan';
  }

  @override
  String get tableOwnerMine => 'Punya saya';

  @override
  String get tablePaidFull => 'Lunas';

  @override
  String get tablePaidPartial => 'Sebagian';

  @override
  String get tableNoReservationTable => 'Belum ada meja';

  @override
  String get floorReservations => 'Reservasi';

  @override
  String get floorTakeaway => 'Bawa pulang';

  @override
  String get floorReservationsBook => 'Buku reservasi';

  @override
  String get floorReservationsLateCount => 'telat';

  @override
  String get reservationFilterWaiting => 'Menunggu';

  @override
  String get reservationFilterLate => 'Terlambat';

  @override
  String get reservationFilterSeated => 'Duduk';

  @override
  String get reservationFilterNoShow => 'No-show';

  @override
  String get reservationFilterAll => 'Semua';

  @override
  String get reservationEmptyFilter => 'Tidak ada reservasi di filter ini.';

  @override
  String get reservationActionSeat => 'Dudukkan';

  @override
  String get reservationActionLate => 'Telat';

  @override
  String get reservationActionNoShow => 'No-show';

  @override
  String get reservationActionRestore => 'Pulihkan';

  @override
  String get takeawayEmpty => 'Belum ada pesanan bawa pulang.';

  @override
  String get zoneAdminTitle => 'Atur Zona';

  @override
  String get tablesEmptyZoneAddTableHint =>
      'Tambahkan meja lewat Manajer › Zona';

  @override
  String get zoneAdminZonePill => 'Zona';

  @override
  String get zoneAdminAddTable => 'Tambah meja';

  @override
  String get zoneAdminAddZone => 'Tambah zona';

  @override
  String get zoneAdminEmptyZone => 'Belum ada meja di';

  @override
  String get zoneAdminNoZones => 'Belum ada zona';

  @override
  String get zoneAdminNoZonesCreate => 'Buat zona dulu untuk menata meja.';

  @override
  String get zoneAdminNoZonesCreateRequest => 'Minta admin untuk membuat zona.';

  @override
  String get zoneAdminEditTable => 'Atur';

  @override
  String get zoneAdminNewTable => 'Meja baru';

  @override
  String get zoneAdminTableName => 'Nama meja';

  @override
  String get zoneAdminMaxCapacity => 'Kapasitas tamu maks';

  @override
  String get zoneAdminTableActive => 'Meja aktif';

  @override
  String get zoneAdminTableActiveSub =>
      'Matikan untuk perbaikan tanpa menghapus.';

  @override
  String get zoneAdminDeleteTableConfirmTitle => 'Hapus meja?';

  @override
  String get zoneAdminDeleteTableConfirmSub =>
      'akan dihapus permanen dari zona.';

  @override
  String get tabMeja => 'Meja';

  @override
  String get tabPesanan => 'Pesanan';

  @override
  String get tabAntrian => 'Antrian';

  @override
  String get tabKasir => 'Kasir';

  @override
  String get tabVenue => 'Venue';

  @override
  String get tabSaya => 'Saya';

  @override
  String get shiftLabel => 'SHIFT';

  @override
  String get kasirRiwayatBatas =>
      'Menampilkan tagihan terbaru. Tagihan lebih lama ada di Laporan.';

  @override
  String get kitchenQueueTitle => 'Antrian Persiapan';

  @override
  String get hapusPencarian => 'Hapus pencarian';

  @override
  String get takAdaItemCocok => 'Tak ada item cocok';

  @override
  String get crumbTambahItem => 'Tambah item';

  @override
  String get crumbTinjau => 'Tinjau';

  @override
  String get crumbBawaPulang => 'Bawa pulang';

  @override
  String get crumbPesananBaru => 'Pesanan baru';

  @override
  String get crumbDiskon => 'Diskon';

  @override
  String get crumbMenuAdmin => 'Menu admin';

  @override
  String get crumbStafAkun => 'Staf & akun';

  @override
  String get crumbLaporanShift => 'Laporan shift';

  @override
  String get crumbKonfigurasi => 'Konfigurasi';

  @override
  String get themeSheetTitle => 'Tema';

  @override
  String get themeSheetSubtitle => 'Berlaku untuk perangkat ini saja';

  @override
  String get localeSheetTitle => 'Bahasa';

  @override
  String get localeSheetSubtitle => 'Berlaku untuk perangkat ini saja';

  @override
  String get localeIndonesian => 'Bahasa Indonesia';

  @override
  String get localeEnglish => 'English';

  @override
  String get a11yPickLocale => 'Pilih bahasa';

  @override
  String get a11yGuestDecrease => 'Kurangi jumlah tamu';

  @override
  String get a11yGuestIncrease => 'Tambah jumlah tamu';

  @override
  String get a11yEdit => 'Ubah';

  @override
  String get zoneAdminIcon => 'Ikon zona';

  @override
  String get tableGuests => 'Tamu';

  @override
  String get quantity => 'Jumlah';

  @override
  String get a11yRename => 'Ganti nama';

  @override
  String get a11yClear => 'Bersihkan';

  @override
  String get a11yRefresh => 'Muat ulang';

  @override
  String get a11yShowPassword => 'Tampilkan kata sandi';

  @override
  String get a11yHidePassword => 'Sembunyikan kata sandi';

  @override
  String get a11ySoundPreview => 'Dengar nada';

  @override
  String get a11ySoundSilent => 'Tanpa nada';

  @override
  String get a11yPickTheme => 'Pilih tema';

  @override
  String get a11yViewPhoto => 'Lihat foto bukti bayar';

  @override
  String get a11yPickColor => 'Pilih warna';

  @override
  String get a11yAddItem => 'Tambah item';

  @override
  String get a11yTableLocked => 'Meja terkunci';

  @override
  String resetRequestMessage(String email) {
    return 'Halo, saya lupa password admin SatSet.\nEmail: $email\nMohon dibantu reset.';
  }

  @override
  String get resetRequestFailed => 'Gagal membuka WhatsApp.';

  @override
  String billingRequestMessage(String venueName, String venueId) {
    return 'Halo, saya mau perpanjang langganan SatSet.\nVenue: $venueName\nID: $venueId\nMohon dibantu.';
  }

  @override
  String billingEndsIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Langganan berakhir $days hari lagi.',
      one: 'Langganan berakhir 1 hari lagi.',
      zero: 'Langganan berakhir hari ini.',
    );
    return '$_temp0';
  }

  @override
  String get billingLapsed => 'Masa langganan sudah lewat.';

  @override
  String billingStopsOn(String date) {
    return 'Venue berhenti melayani $date.';
  }

  @override
  String get billingCta => 'Ketuk untuk perpanjang lewat WhatsApp.';

  @override
  String updateAvailable(String latest, String installed) {
    return 'Versi $latest tersedia. Perangkat ini di $installed.';
  }

  @override
  String get updateAction => 'Perbarui';

  @override
  String get updateBlockedTitle => 'Versi ini tidak didukung lagi';

  @override
  String updateBlockedBody(String installed, String min) {
    return 'Perangkat ini menjalankan versi $installed. Versi minimum sekarang $min.';
  }

  @override
  String get updateBlockedAskAdmin => 'Minta admin memperbarui perangkat ini.';

  @override
  String updateDownloading(int percent) {
    return 'Mengunduh $percent%';
  }

  @override
  String get updateInstalling => 'Membuka pemasang...';

  @override
  String get updateFailed => 'Unduhan gagal. Periksa koneksi lalu coba lagi.';

  @override
  String get updateRetry => 'Coba lagi';

  @override
  String get updatePermissionNeeded =>
      'Izinkan pemasangan aplikasi dari SatSet, lalu coba lagi.';

  @override
  String get fltReleaseGate => 'Gerbang versi';

  @override
  String get fltReleaseGateHint => 'Kosongkan untuk menghapus batas.';

  @override
  String get fltReleaseGateMin => 'Minimum (wajib)';

  @override
  String get fltReleaseGateRecommended => 'Disarankan';

  @override
  String get fltReleaseGateLatest => 'Terbaru';

  @override
  String get fltReleaseGateInvalid =>
      'Format harus 1.2.3, dan min <= disarankan <= terbaru.';

  @override
  String get bootBlockStale =>
      'Perlu koneksi internet untuk verifikasi admin. Sambungkan internet lalu masuk lagi.';

  @override
  String get bootBlockIneligible => 'Akses admin dicabut. Hubungi pengelola.';

  @override
  String get tempPasswordTitle => 'Ganti sandi';

  @override
  String get logout => 'Keluar';

  @override
  String get tempPasswordReason =>
      'Anda masuk dengan sandi sementara. Buat sandi baru untuk melanjutkan.';

  @override
  String get tempPasswordNew => 'Sandi baru';

  @override
  String get tempPasswordConfirm => 'Ulangi sandi baru';

  @override
  String tempPasswordTooShort(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Minimal $min karakter.',
      one: 'Minimal 1 karakter.',
    );
    return '$_temp0';
  }

  @override
  String get tempPasswordMismatch => 'Sandi tidak sama.';

  @override
  String get tempPasswordReused =>
      'Sandi baru tidak boleh sama dengan sandi sementara.';

  @override
  String get tempPasswordExpired =>
      'Sandi sementara sudah kadaluarsa. Minta yang baru ke pengelola.';

  @override
  String get tempPasswordPending =>
      'Sandi akun ini baru direset. Masuk dengan sandi sementara untuk menggantinya.';

  @override
  String get tempPasswordIssuedTitle => 'Sandi sementara';

  @override
  String get tempPasswordIssuedHint =>
      'Berlaku 24 jam. Sebutkan ke admin venue — mereka wajib mengganti sandi saat masuk.';

  @override
  String get tempPasswordIssuedOnce => 'Kode ini hanya muncul sekali.';

  @override
  String tempPasswordShareMessage(String code) {
    return 'Sandi sementara SatSet Anda: $code\nBerlaku 24 jam. Anda akan diminta membuat sandi baru saat masuk.';
  }

  @override
  String get staffTitle => 'Staf & akun';

  @override
  String get staffTabPeople => 'Orang';

  @override
  String get staffTabRoles => 'Peran';

  @override
  String get staffSearchHint => 'Cari nama';

  @override
  String get staffFilterAll => 'Semua';

  @override
  String get staffAdd => 'Tambah staf';

  @override
  String get staffAddPill => '+ Tambah staf';

  @override
  String get staffEmpty => 'Tidak ada staf yang cocok dengan filter ini';

  @override
  String get staffNewRolePill => '+ Peran baru';

  @override
  String get staffRoleBadgeAdmin => 'ADMIN';

  @override
  String get staffRoleManagedByOperator => 'Dikelola pengelola';

  @override
  String get staffRoleColor => 'Warna peran';

  @override
  String get staffColor => 'Warna';

  @override
  String get staffAvatarColor => 'Warna avatar';

  @override
  String get staffRolePermsHint => 'Ketuk peran untuk mengatur izinnya.';

  @override
  String get staffRoleLockedBanner =>
      'Peran admin dikelola pengelola. Izinnya bisa dilihat, tidak bisa diubah.';

  @override
  String get staffCapAdminOnly =>
      'Hanya bisa diberikan lewat pengelola, bukan dari layar ini.';

  @override
  String get staffRole => 'Peran';

  @override
  String get staffNoRole => 'Tanpa peran';

  @override
  String get staffName => 'Nama';

  @override
  String get staffFullName => 'Nama lengkap';

  @override
  String get staffPinField => 'PIN (6 digit, unik)';

  @override
  String get staffPinReset => 'Atur ulang';

  @override
  String get staffPinUpdated => 'PIN diperbarui';

  @override
  String get staffSaveChanges => 'Simpan perubahan';

  @override
  String get staffNewRoleName => 'Nama peran baru';

  @override
  String get staffRenameRole => 'Ganti nama peran';

  @override
  String get staffDisable => 'Nonaktifkan';

  @override
  String get staffErrNameEmpty => 'Nama tidak boleh kosong';

  @override
  String get staffErrAdminBySuperOnly =>
      'Peran admin hanya bisa dibuat oleh super admin';

  @override
  String get staffErrAdminPromoteBlocked =>
      'Menaikkan ke peran admin tidak bisa dari sini';

  @override
  String get staffErrNeedNonAdminRole => 'Buat peran non-admin dulu';

  @override
  String get staffErrColorTaken => 'Warna avatar sudah dipakai akun lain';

  @override
  String get staffErrColorTakenShort => 'Warna juga dipakai akun lain';

  @override
  String get staffChangeRoleTitle => 'Ganti peran?';

  @override
  String get staffDisableBody =>
      'Pengguna tidak bisa masuk lagi. Bisa diaktifkan kembali nanti.';

  @override
  String get staffDeleteBody =>
      'Akun dihapus permanen. Catatan audit lama tetap ada.';

  @override
  String get staffDeleteRoleBody =>
      'Izin yang melekat pada peran ini akan hilang.';

  @override
  String staffSubtitle(int members, int admins) {
    String _temp0 = intl.Intl.pluralLogic(
      members,
      locale: localeName,
      other: '$members anggota',
    );
    String _temp1 = intl.Intl.pluralLogic(
      admins,
      locale: localeName,
      other: '$admins admin',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String staffRolesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n peran khusus',
    );
    return '$_temp0';
  }

  @override
  String staffCapsCount(int held, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total izin',
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
      other: '$n anggota',
    );
    return '$_temp0';
  }

  @override
  String staffCreated(String name, String pin) {
    return '$name dibuat. PIN: $pin';
  }

  @override
  String staffNewPin(String pin) {
    return 'PIN baru: $pin';
  }

  @override
  String staffRoleAdminSuffix(String name) {
    return '$name (admin)';
  }

  @override
  String staffDeleteRoleTitle(String name) {
    return 'Hapus peran “$name”?';
  }

  @override
  String staffChangeRoleBody(String name) {
    return 'Pindahkan $name ke peran lain. Izin berubah seketika.';
  }

  @override
  String staffDisableTitle(String name) {
    return 'Nonaktifkan $name?';
  }

  @override
  String staffDeleteTitle(String name) {
    return 'Hapus $name?';
  }

  @override
  String get payMethodCash => 'Tunai';

  @override
  String get payMethodCard => 'Kartu';

  @override
  String get payMethodQris => 'QRIS';

  @override
  String get payMethodTransfer => 'Transfer';

  @override
  String get payMethodOther => 'Lainnya';

  @override
  String get rangeToday => 'Hari ini';

  @override
  String get rangeYesterday => 'Kemarin';

  @override
  String get rangeD7 => '7 hari';

  @override
  String get rangeD30 => '30 hari';

  @override
  String get rangeMonth => 'Bulan ini';

  @override
  String get rangeCustom => 'Khusus';

  @override
  String get expPeriod => 'Periode';

  @override
  String get expRange => 'Rentang';

  @override
  String get expGenerated => 'Dibuat';

  @override
  String get expNote => 'Catatan';

  @override
  String expMetaRange(String value) {
    return 'Rentang: $value';
  }

  @override
  String expMetaGenerated(String value) {
    return 'Dibuat: $value';
  }

  @override
  String get expNoData => 'Tidak ada data.';

  @override
  String expPageOf(int page, int total) {
    return 'SatSet · Halaman $page/$total';
  }

  @override
  String get expAccountingCsvTitle => 'Laporan Akuntansi SatSet';

  @override
  String get expAccountingTitle => 'Laporan Akuntansi';

  @override
  String expAccountingHeader(String range) {
    return 'Laporan Akuntansi · $range';
  }

  @override
  String get expAccountingNote =>
      'Pajak & service = nilai riil dari sesi terselesaikan (bukan estimasi 18% di layar). Rentang mengikuti aturan yang sama dengan laporan di layar (ADR-0032).';

  @override
  String get expSessionCount => 'Jumlah sesi';

  @override
  String expMetaSessionCount(int n) {
    return 'Jumlah sesi: $n';
  }

  @override
  String get expRevenueSummary => 'Ringkasan Pendapatan';

  @override
  String get expColEntry => 'Pos';

  @override
  String get expColValue => 'Nilai';

  @override
  String get expGrossSubtotal => 'Bruto (subtotal)';

  @override
  String get expVoidCorrection => 'Void / koreksi';

  @override
  String get expDiscount => 'Diskon';

  @override
  String get expNet => 'Net';

  @override
  String get expService => 'Service';

  @override
  String get expTax => 'Pajak';

  @override
  String get expCollectedBilled => 'Terkumpul (tagihan)';

  @override
  String get expRefund => 'Refund';

  @override
  String get expMethodBreakdown => 'Rincian Metode Bayar';

  @override
  String get expColMethod => 'Metode';

  @override
  String get expColAmount => 'Jumlah';

  @override
  String get expColTransactions => 'Transaksi';

  @override
  String get expColRefundCount => 'Refund (n)';

  @override
  String get expWriteOffs => 'Void & Refund (write-off)';

  @override
  String get expColReason => 'Alasan';

  @override
  String get expColItem => 'Item';

  @override
  String get expColLost => 'Rugi';

  @override
  String get expDiscountByPreset => 'Diskon per Preset';

  @override
  String get expColScope => 'Cakupan';

  @override
  String get expColUsed => 'Dipakai';

  @override
  String get expScopeLine => 'Per item';

  @override
  String get expScopeOrder => 'Per pesanan';

  @override
  String get expDailyBreakdown => 'Rincian Harian';

  @override
  String get expColDate => 'Tanggal';

  @override
  String get expColGross => 'Bruto';

  @override
  String get expColVoid => 'Void';

  @override
  String get expColCollected => 'Terkumpul';

  @override
  String get expReportCsvTitle => 'Laporan SatSet';

  @override
  String expReportHeader(String range) {
    return 'Laporan SatSet · $range';
  }

  @override
  String get expSummary => 'Ringkasan';

  @override
  String get expColMetric => 'Metrik';

  @override
  String get expColCaption => 'Keterangan';

  @override
  String get expStaffPerformance => 'Kinerja Staf';

  @override
  String get expColName => 'Nama';

  @override
  String get expColCover => 'Cover';

  @override
  String get expColAvgBill => 'Rata tagihan';

  @override
  String get expColVoidPct => 'Void %';

  @override
  String get expColSessions => 'Sesi';

  @override
  String get expTopMenu => 'Menu Terlaris';

  @override
  String get expSlowMenu => 'Menu Lambat';

  @override
  String get expColQty => 'Qty';

  @override
  String get expColRevenue => 'Pendapatan';

  @override
  String get expColMarginPct => 'Margin %';

  @override
  String get expColMargin => 'Margin';

  @override
  String get expCategoryMix => 'Komposisi Kategori';

  @override
  String get expColCategory => 'Kategori';

  @override
  String get expColShareThisWeek => 'Porsi minggu ini';

  @override
  String get expColShareLastWeek => 'Porsi minggu lalu';

  @override
  String get expColThisWeek => 'Minggu ini';

  @override
  String get expColLastWeek => 'Minggu lalu';

  @override
  String get expHourlySales => 'Penjualan per Jam';

  @override
  String get expColHour => 'Jam';

  @override
  String get expDineInVsTakeaway => 'Dine-in vs Bawa Pulang';

  @override
  String get expDineIn => 'Makan di tempat';

  @override
  String get expTakeaway => 'Bawa pulang';

  @override
  String get expStaffCsvTitle => 'Laporan Staf SatSet';

  @override
  String get expStaffTitle => 'Laporan Staf';

  @override
  String expStaffHeader(String range) {
    return 'Laporan Staf · $range';
  }

  @override
  String get expColUpsellPct => 'Upsell %';

  @override
  String get expColVoidCount => 'Void';

  @override
  String get expColLostVoid => 'Lost (void)';

  @override
  String get expColTopReason => 'Alasan teratas';

  @override
  String get expTotalRow => 'TOTAL';

  @override
  String get expStaffSortNote => 'Diurutkan menurut Net (tertinggi dahulu).';

  @override
  String get expOrdersCsvTitle => 'Riwayat Pesanan SatSet';

  @override
  String get expOrdersTitle => 'Riwayat Pesanan';

  @override
  String expOrdersHeader(String range) {
    return 'Riwayat Pesanan · $range';
  }

  @override
  String get expVisitCount => 'Total kunjungan';

  @override
  String get expLineCount => 'Total baris';

  @override
  String get expVisitSection => 'KUNJUNGAN';

  @override
  String get expColPax => 'Pax';

  @override
  String get expColWaiter => 'Pelayan';

  @override
  String get expColClosed => 'Tutup';

  @override
  String get expColTime => 'Jam';

  @override
  String get expColVariant => 'Varian';

  @override
  String get expColModifier => 'Modifier';

  @override
  String get expColCourse => 'Course';

  @override
  String get expColPrice => 'Harga';

  @override
  String get expColTotal => 'Total';

  @override
  String get expColSubtotal => 'Subtotal';

  @override
  String get expColStatus => 'Status';

  @override
  String get expColVoidReason => 'Alasan void';

  @override
  String get expBillSection => 'TAGIHAN';

  @override
  String get expColCashier => 'Kasir';

  @override
  String get expColProofPhoto => 'Bukti foto';

  @override
  String get expYes => 'Ya';

  @override
  String get expPresent => 'Ada';

  @override
  String expTakeawayVisit(String label) {
    return '$label · Bawa pulang';
  }

  @override
  String expTableVisit(String label) {
    return 'Meja $label';
  }

  @override
  String get expStatusVoided => 'Dibatalkan';

  @override
  String get expStatusServed => 'Disajikan';

  @override
  String get expStatusReady => 'Siap';

  @override
  String get expStatusCooked => 'Dimasak';

  @override
  String get expStatusSent => 'Dikirim';

  @override
  String get expStatusHeld => 'Ditahan';

  @override
  String expVoidedWithReason(String reason) {
    return 'Batal · $reason';
  }

  @override
  String get expNoVisits => 'Tidak ada kunjungan pada rentang ini.';

  @override
  String get expNoPayments => 'Belum ada pembayaran tercatat.';

  @override
  String get expBillHeading => 'Tagihan';

  @override
  String expMetaVisitLines(int visits, int lines, String net) {
    return 'Kunjungan: $visits  ·  Baris: $lines  ·  Net: $net';
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
    return 'Subtotal $subtotal$discount  ·  Service $service  ·  Pajak $tax  ·  Total $total';
  }

  @override
  String expReceiptDiscountPart(String amount) {
    return '  ·  Diskon $amount';
  }

  @override
  String expPaymentActor(String method, String cashier, String refund) {
    return '$method  ·  $cashier$refund';
  }

  @override
  String get expPaymentRefundPart => '  ·  Refund';

  @override
  String expProofCaption(String method, String amount) {
    return 'Bukti · $method  ·  $amount';
  }

  @override
  String get expProofMissing => 'Bukti tidak termuat';

  @override
  String get expAuditSubject => 'Catatan audit';

  @override
  String get expAuditCsvHeader =>
      'Waktu,Jenis,Pengguna,Peran,Kejadian,Meja,Jumlah,Alasan,Disetujui';

  @override
  String strukTableLine(String label, int pax, String time) {
    return 'Meja $label  ·  $pax org  ·  $time';
  }

  @override
  String strukGuest(String name) {
    return 'Tamu: $name';
  }

  @override
  String strukNote(String note) {
    return 'Catatan: $note';
  }

  @override
  String get strukVerify => 'Verifikasi pesanan Anda';

  @override
  String get strukThanks => 'Terima kasih';

  @override
  String get strukTestTitle => 'TES PRINTER';

  @override
  String get strukTestOk => 'Terhubung OK';

  @override
  String get strukBillTitle => 'TAGIHAN';

  @override
  String get strukReceiptTitle => 'STRUK PEMBAYARAN';

  @override
  String get strukEvenHeading => 'Patungan meja:';

  @override
  String get strukBillTotal => 'Total tagihan';

  @override
  String get strukPart => 'Bagian';

  @override
  String get strukSubtotal => 'Subtotal';

  @override
  String get strukDiscount => 'Diskon';

  @override
  String get strukService => 'Layanan';

  @override
  String get strukTax => 'Pajak';

  @override
  String get strukTotal => 'TOTAL';

  @override
  String strukPaid(String method) {
    return 'Bayar $method';
  }

  @override
  String strukRefunded(String method) {
    return 'Refund $method';
  }

  @override
  String get strukCashReceived => 'Tunai diterima';

  @override
  String get strukChange => 'Kembali';

  @override
  String get strukOutstanding => 'SISA';

  @override
  String get strukSettled => 'LUNAS';

  @override
  String get exportKindReport => 'Umum';

  @override
  String get exportKindOrders => 'Pesanan';

  @override
  String get exportKindStaff => 'Staf';

  @override
  String get exportKindAccounting => 'Akuntansi';

  @override
  String get exportTitleReport => 'Ekspor laporan';

  @override
  String get exportTitleOrders => 'Ekspor pesanan';

  @override
  String get exportTitleStaff => 'Ekspor staf';

  @override
  String get exportTitleAccounting => 'Ekspor akuntansi';

  @override
  String get exportFailed => 'Gagal mengekspor. Coba lagi.';

  @override
  String get exportKindField => 'Jenis';

  @override
  String get exportFormatField => 'Format';

  @override
  String get exportNoSnapshot =>
      'Laporan belum siap — buka laporan dulu agar bisa diekspor.';

  @override
  String get exportPreparing => 'Menyiapkan…';

  @override
  String exportAction(String format) {
    return 'Ekspor $format';
  }

  @override
  String printJobOrderSlip(String label) {
    return 'Cetak struk meja $label';
  }

  @override
  String printJobReceiptDoc(String who) {
    return 'Cetak struk · $who';
  }

  @override
  String printJobBillDoc(String who) {
    return 'Cetak tagihan · $who';
  }

  @override
  String get printWhoReceipt => 'struk';

  @override
  String get courseDrinksNow => 'Minum dulu';

  @override
  String get courseStarters => 'Pembuka';

  @override
  String get courseMains => 'Utama';

  @override
  String get courseSides => 'Bersama Utama';

  @override
  String get courseDesserts => 'Penutup';

  @override
  String get courseFireNow => 'Langsung';

  @override
  String auditFire(String course, String table) {
    return 'Course $course dibakar untuk Meja $table';
  }

  @override
  String auditModify(String name) {
    return 'Ubah $name';
  }

  @override
  String auditModifyQty(String oldQty, String newQty, String name) {
    return 'Ubah ×$oldQty → ×$newQty $name';
  }

  @override
  String auditModifyAtTable(String name, String table) {
    return '$name diubah di Meja $table';
  }

  @override
  String auditVoidItem(String qty, String name, String amount) {
    return 'Dibatalkan ×$qty $name · $amount';
  }

  @override
  String auditVoidItemAtTable(String name, String table) {
    return '$name dibatalkan di Meja $table';
  }

  @override
  String auditComp(String qty, String name, String amount) {
    return 'Digratiskan ×$qty $name · $amount';
  }

  @override
  String auditTableMoved(String src, String tgt) {
    return 'Pindah meja $src → $tgt';
  }

  @override
  String auditPaymentRecorded(String amount, String method, String label) {
    return 'Pembayaran $amount ($method) $label';
  }

  @override
  String auditPaymentAtTable(String method, String table) {
    return 'Pembayaran $method Meja $table';
  }

  @override
  String auditRefund(String amount, String method, String label) {
    return 'Refund $amount ($method) $label';
  }

  @override
  String auditDiscountApplied(String name) {
    return 'Diskon $name';
  }

  @override
  String auditDiscountAppliedLine(String name) {
    return 'Diskon $name (item)';
  }

  @override
  String auditDiscountRemoved(String name) {
    return 'Hapus diskon $name';
  }

  @override
  String auditDiscountBillApplied(String name) {
    return 'Diskon tagihan $name';
  }

  @override
  String auditDiscountBillRemoved(String name) {
    return 'Hapus diskon tagihan $name';
  }

  @override
  String auditDiscountAtTable(String percent, String table) {
    return 'Diskon $percent% di Meja $table';
  }

  @override
  String auditBillReopenedReceipt(String label) {
    return 'Buka ulang $label';
  }

  @override
  String auditBillReopened(String table) {
    return 'Buka ulang tagihan $table';
  }

  @override
  String auditBillClosed(String table) {
    return 'Tutup tagihan $table';
  }

  @override
  String auditBillWrittenOff(String amount, String table) {
    return 'Tagihan tak tertagih $amount $table';
  }

  @override
  String auditCashToppedUp(String amount) {
    return 'Isi kas kecil $amount';
  }

  @override
  String auditCashSpent(String amount, String category) {
    return 'Pengeluaran kas $amount — $category';
  }

  @override
  String auditCashCounted(String counted, String variance) {
    return 'Opname kas $counted (selisih $variance)';
  }

  @override
  String auditCashReversed(String amount) {
    return 'Batalkan mutasi kas $amount';
  }

  @override
  String auditMenuKilled(String name) {
    return 'Stop jual $name';
  }

  @override
  String auditMenuRestored(String name) {
    return 'Jual lagi $name';
  }

  @override
  String auditStaffCreated(String name) {
    return '$name dibuat';
  }

  @override
  String auditStaffDisabled(String name) {
    return '$name dinonaktifkan';
  }

  @override
  String auditStaffEnabled(String name) {
    return '$name diaktifkan';
  }

  @override
  String auditStaffPinSet(String name) {
    return 'PIN $name diubah';
  }

  @override
  String auditStaffPinReset(String name) {
    return 'PIN $name direset';
  }

  @override
  String auditStaffRoleChanged(String name, String from, String to) {
    return '$name: $from → $to';
  }

  @override
  String auditRoleCreated(String name) {
    return 'Peran $name dibuat';
  }

  @override
  String auditRoleDeleted(String name) {
    return 'Peran $name dihapus';
  }

  @override
  String auditRoleColorChanged(String name) {
    return 'Warna $name diubah';
  }

  @override
  String auditRoleRenamed(String from, String to) {
    return 'Peran: $from → $to';
  }

  @override
  String auditRoleCapabilityChanged(String name, String changes) {
    return '$name: $changes';
  }

  @override
  String get receiptDefault => 'Struk';

  @override
  String receiptGuest(String letter) {
    return 'Tamu $letter';
  }

  @override
  String receiptPart(String index, String count) {
    return 'Bagian $index/$count';
  }

  @override
  String auditStaffDeleted(String name) {
    return '$name dihapus';
  }

  @override
  String get auditSampleDataLoaded => 'Memuat contoh data restoran';

  @override
  String get cshCrumbCashier => 'Kasir';

  @override
  String get cshCrumbBill => 'Tagihan';

  @override
  String cshBillTableCrumb(String table) {
    return 'Tagihan · Meja $table';
  }

  @override
  String cshReceiptTableCrumb(String table) {
    return 'Struk · Meja $table';
  }

  @override
  String get cshLoadFailed => 'Gagal memuat tagihan.';

  @override
  String get cshReceiptLoadFailed => 'Gagal memuat struk.';

  @override
  String get cshCloseBill => 'Tutup tagihan';

  @override
  String cshCloseBillBody(String table) {
    return 'Kunci tagihan Meja $table sebagai lunas? Tindakan ini mengakhiri tagihan.';
  }

  @override
  String get cshWriteOffTitle => 'Tutup tagihan — tak tertagih';

  @override
  String cshWriteOffBody(String amount) {
    return 'Sisa $amount akan dicatat sebagai kerugian (tak tertagih). Perlu persetujuan manajer.';
  }

  @override
  String get cshWriteOffReason => 'Alasan (wajib)';

  @override
  String get cshWriteOffReasonHint => 'mis. tamu pergi tanpa bayar';

  @override
  String get cshWriteOffConfirm => 'Catat kerugian';

  @override
  String get cshErrOverAssign => 'Unit melebihi yang tersedia.';

  @override
  String get cshErrReceiptPaid => 'Buka ulang struk sebelum mengubahnya.';

  @override
  String get cshErrNotSettled => 'Tagihan belum lunas.';

  @override
  String get cshErrBillLocked => 'Tagihan sudah ditutup — buka ulang dulu.';

  @override
  String get cshErrForbidden => 'Perlu persetujuan manajer (tak tertagih).';

  @override
  String get cshErrReasonRequired => 'Alasan tak tertagih wajib diisi.';

  @override
  String get cshErrNoLines => 'Meja tidak punya pesanan.';

  @override
  String cshErrGeneric(String code) {
    return 'Operasi gagal ($code).';
  }

  @override
  String get cshReceipts => 'Struk';

  @override
  String cshUnassignedCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n item belum diatur ke struk',
    );
    return '$_temp0';
  }

  @override
  String get cshSubtotal => 'Subtotal';

  @override
  String get cshDiscount => 'Diskon';

  @override
  String get cshService => 'Layanan';

  @override
  String get cshTax => 'Pajak';

  @override
  String get cshTotal => 'Total';

  @override
  String get cshPaidAmount => 'Terbayar';

  @override
  String get cshOutstanding => 'Sisa';

  @override
  String cshBatch(String batch, String time) {
    return 'PESANAN $batch · $time';
  }

  @override
  String get cshOrderItems => 'Item pesanan';

  @override
  String get cshNotAllAssigned => 'Belum semua diatur';

  @override
  String cshNote(String note) {
    return 'Catatan: $note';
  }

  @override
  String get cshUnitDec => 'Kurangi unit';

  @override
  String get cshUnitInc => 'Tambah unit';

  @override
  String cshPickedOf(int picked, int free) {
    return '$picked dari $free';
  }

  @override
  String get cshAssign => 'Atur';

  @override
  String cshAssignTitle(String name) {
    return 'Atur \"$name\"';
  }

  @override
  String cshAssignSub(int qty, int unassigned) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: '$qty unit',
    );
    return '$_temp0 total · $unassigned belum diatur';
  }

  @override
  String get cshSettled => 'Lunas';

  @override
  String get cshUnpaid => 'Belum bayar';

  @override
  String get cshStatusSettled => 'lunas';

  @override
  String get cshStatusUnpaid => 'belum bayar';

  @override
  String get cshPay => 'Bayar';

  @override
  String get cshRefund => 'Refund';

  @override
  String get cshReopen => 'Buka ulang';

  @override
  String get cshReopenTitle => 'Buka ulang struk';

  @override
  String cshReopenBody(String receipt) {
    return 'Batalkan status lunas \"$receipt\" agar bisa diubah? Pembayaran tercatat tetap ada.';
  }

  @override
  String get cshReopenConfirm => 'Ya, buka ulang';

  @override
  String get cshRemoveDiscount => 'Hapus diskon';

  @override
  String cshRemoveDiscountBody(String label, String amount) {
    return 'Hapus \"$label\" ($amount) dari struk ini?';
  }

  @override
  String get cshConfirmDelete => 'Ya, hapus';

  @override
  String get cshPrintBill => 'Cetak tagihan';

  @override
  String get cshPrintReceipt => 'Cetak struk';

  @override
  String get cshDeleteReceiptTitle => 'Hapus struk';

  @override
  String cshDeleteReceiptBody(String receipt) {
    return 'Hapus \"$receipt\"? Item yang sudah diatur ke struk ini akan kembali belum diatur.';
  }

  @override
  String cshPhotoFailed(String error) {
    return 'Gagal mengambil foto: $error';
  }

  @override
  String cshRefundTitle(String receipt) {
    return 'Refund $receipt';
  }

  @override
  String cshPayTitle(String receipt) {
    return 'Bayar $receipt';
  }

  @override
  String get cshTendered => 'Uang diterima';

  @override
  String cshChangeDue(String amount) {
    return 'Kembalian $amount';
  }

  @override
  String cshShortBy(String amount) {
    return 'Kurang $amount';
  }

  @override
  String get cshProofPhoto => 'Foto bukti (wajib)';

  @override
  String get cshTakePhoto => 'Ambil foto';

  @override
  String get cshRetakePhoto => 'Ambil ulang';

  @override
  String get cshRecordRefund => 'Catat refund';

  @override
  String get cshRecordPayment => 'Catat pembayaran';

  @override
  String cshEvenSplit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bagian',
    );
    return 'Split rata · $_temp0';
  }

  @override
  String cshPerHead(String amount) {
    return '$amount / orang';
  }

  @override
  String cshPaidCount(int paid, int total) {
    return '$paid dari $total lunas';
  }

  @override
  String cshPayPart(int index) {
    return 'Bayar bagian $index';
  }

  @override
  String cshShareSemantic(String receipt, String status) {
    return '$receipt, $status';
  }

  @override
  String cshPartSemantic(int index, String status) {
    return 'Bagian $index, $status';
  }

  @override
  String cshItemCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n item',
    );
    return '$_temp0';
  }

  @override
  String get cshItemFallback => 'Item';

  @override
  String get cshRemoveLineDiscountTitle => 'Hapus diskon item';

  @override
  String cshRemoveLineDiscountBody(String label, String amount, String name) {
    return 'Hapus \"$label\" ($amount) dari $name?';
  }

  @override
  String get cshAddReceipt => 'Tambah struk';

  @override
  String get cshBillWrittenOff => 'Tagihan tak tertagih';

  @override
  String get cshBillSettled => 'Tagihan lunas';

  @override
  String cshWrittenOffBody(String amount) {
    return '$amount dicatat sebagai kerugian.';
  }

  @override
  String cshSettledFull(String amount) {
    return '$amount diterima penuh.';
  }

  @override
  String cshSettledParts(String amount, int parts) {
    String _temp0 = intl.Intl.pluralLogic(
      parts,
      locale: localeName,
      other: '$parts bagian.',
    );
    return '$amount diterima penuh dalam $_temp0';
  }

  @override
  String get cshPrintSettledReceipt => 'Cetak struk lunas';

  @override
  String get cshPrintTableReceipt => 'Cetak struk meja';

  @override
  String get cshPrintTableBill => 'Cetak tagihan meja';

  @override
  String get cshWholeBill => 'Seluruh tagihan';

  @override
  String get cshRemoveBillDiscountTitle => 'Hapus diskon tagihan';

  @override
  String cshRemoveBillDiscountBody(String label, String amount) {
    return 'Hapus \"$label\" ($amount) dari seluruh tagihan?';
  }

  @override
  String get cshTableClosedUnpaid =>
      'Meja sudah ditutup waiter — tagihan belum lunas';

  @override
  String get cshAmount => 'Jumlah';

  @override
  String get rptSecSales => 'Penjualan';

  @override
  String get rptSecStaff => 'Staf';

  @override
  String get rptSecMenu => 'Menu';

  @override
  String get rptSecBahan => 'Bahan';

  @override
  String get rptSecOps => 'Operasi';

  @override
  String get rptSecPayments => 'Pembayaran';

  @override
  String get rptUpdating => 'Memperbarui…';

  @override
  String get rptStockTitle => 'Bahan & stok';

  @override
  String get rptStockSub =>
      'Pemakaian, terbuang, nilai stok, dan selisih opname';

  @override
  String get rptNonCash => 'Pembayaran non-tunai';

  @override
  String get rptNonCashSub => 'bukti foto wajib';

  @override
  String get rptNonCashEmpty =>
      'Tidak ada pembayaran non-tunai pada rentang ini.';

  @override
  String rptTotalOf(String amount) {
    return 'total $amount';
  }

  @override
  String get rptProofOnVenue => 'Bukti foto tersedia di perangkat venue.';

  @override
  String rptMethodCount(String method, int count, String amount) {
    return '$method · $count× · $amount';
  }

  @override
  String rptMethodTable(String method, String table) {
    return '$method · Meja $table';
  }

  @override
  String get rptDineVsTakeaway => 'Dine-in vs Bawa pulang';

  @override
  String get rptDineIn => 'Dine-in';

  @override
  String get rptTakeaway => 'Bawa pulang';

  @override
  String rptTxCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n transaksi',
    );
    return '$_temp0';
  }

  @override
  String get rptKpiNet => 'Net';

  @override
  String get rptKpiGross => 'Gross';

  @override
  String get rptKpiTaxService => 'Pajak + Service';

  @override
  String get rptKpiVoid => 'Void';

  @override
  String get rptNoData => 'Belum ada data';

  @override
  String get rptNoDataDot => 'Belum ada data.';

  @override
  String get rptNoDataLower => 'belum ada data';

  @override
  String get rptGuestTrend => 'Tren tamu vs minggu lalu';

  @override
  String rptGuestTrendSub(int count, String delta) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tamu',
    );
    return '$_temp0 · $delta% WoW';
  }

  @override
  String get rptThisWeek => 'Minggu ini';

  @override
  String get rptLastWeek => 'Minggu lalu';

  @override
  String get rptRevenuePerHour => 'Pendapatan per jam';

  @override
  String rptPeakHour(String from, String to) {
    return 'Puncak $from:00 — $to:00';
  }

  @override
  String get rptWaiterPerf => 'Performa pelayan';

  @override
  String rptWaiterPerfSub(int n) {
    return '$n staf · sortir aktif';
  }

  @override
  String get rptNoClosedSessions => 'Belum ada sesi tutup di rentang ini.';

  @override
  String get rptSort => 'Sortir';

  @override
  String get rptSortCovers => 'Meja';

  @override
  String get rptSortVoidPct => 'Void %';

  @override
  String get rptSortAvg => 'Avg';

  @override
  String get rptSortNetDesc => 'Net tertinggi';

  @override
  String get rptSortMostTables => 'Paling banyak meja';

  @override
  String get rptSortMostVoids => 'Void terbanyak';

  @override
  String get rptSortAvgTicket => 'Avg ticket';

  @override
  String get rptColWaiter => 'PELAYAN';

  @override
  String get rptColTables => 'MEJA';

  @override
  String get rptColItems => 'ITEM';

  @override
  String get rptColAvgTicket => 'AVG TICKET';

  @override
  String get rptColVoidPct => 'VOID%';

  @override
  String get rptColNet => 'NET';

  @override
  String get rptUpsell => 'Indeks upsell pelayan';

  @override
  String rptUpsellSub(int avg) {
    return '% sesi dgn starter & main · avg $avg%';
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
      other: '$n item',
    );
    return '$_temp0 · margin tinggi';
  }

  @override
  String rptMenuSlowStock(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n item',
    );
    return '$_temp0 · stok mengendap';
  }

  @override
  String rptQtyMargin(int qty, int margin) {
    return '×$qty · margin $margin%';
  }

  @override
  String get rptAttachRate => 'Attach rate modifier';

  @override
  String get rptAttachRateSub => '% order pakai modifier';

  @override
  String get rptBucketStar => 'LAKU & UNTUNG';

  @override
  String get rptBucketStarAction => 'jaga & sorot';

  @override
  String get rptBucketPlow => 'LAKU TAPI TIPIS';

  @override
  String get rptBucketPlowAction => 'reprice / kurangi porsi';

  @override
  String get rptBucketPuzzle => 'UNTUNG TAPI SEPI';

  @override
  String get rptBucketPuzzleAction => 'promosikan';

  @override
  String get rptBucketDog => 'SEPI & TIPIS';

  @override
  String get rptBucketDogAction => 'kandidat dipangkas';

  @override
  String get rptMenuClass => 'Klasifikasi menu';

  @override
  String get rptMenuClassSub => 'Populer × margin';

  @override
  String rptBucketAction(String action) {
    return '· $action';
  }

  @override
  String get rptNoItems => 'tidak ada item';

  @override
  String rptPopMargin(int pop, int margin) {
    return 'pop $pop · margin $margin%';
  }

  @override
  String rptMoreItems(int n) {
    return '+$n lainnya';
  }

  @override
  String get rptCategoryMix => 'Bauran kategori (WoW)';

  @override
  String get rptCategoryMixSub => 'Bagian pendapatan vs minggu lalu';

  @override
  String get rptColThisWeek => 'MINGGU INI';

  @override
  String get rptColLastWeek => 'MINGGU LALU';

  @override
  String get rptBasketPairs => 'Pasangan keranjang';

  @override
  String get rptBasketPairsSub => 'Item paling sering dipesan bersama';

  @override
  String rptPairCount(int n) {
    return '$n× di rentang ini';
  }

  @override
  String get rptKpiTurnTime => 'Avg turn time';

  @override
  String get rptKpiPrep => 'Prep dapur';

  @override
  String get rptKpiPickup => 'Tunggu antar';

  @override
  String get rptKpiReservations => 'Reservasi';

  @override
  String get rptServiceSpeed => 'Kecepatan layanan';

  @override
  String get rptServiceSpeedEmpty => 'Belum ada item siap/disajikan';

  @override
  String rptServiceSpeedSub(int prep, int pickup, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n item',
    );
    return 'Median prep ${prep}m · antar ${pickup}m · $_temp0';
  }

  @override
  String get rptSlaCourses => 'kursus siap di bawah target masing-masing';

  @override
  String rptPickupSla(int mins) {
    return 'Diantar < ${mins}m';
  }

  @override
  String rptMedianMins(int mins) {
    return 'median ${mins}m';
  }

  @override
  String rptGreetBreach(int mins) {
    return 'Telat dilayani > ${mins}m';
  }

  @override
  String rptGreetSub(int median, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kunjungan',
    );
    return 'median ${median}m · $_temp0';
  }

  @override
  String get rptSlowestMenu => 'Menu paling lambat (rata-rata prep)';

  @override
  String get rptHeatmap => 'Peak-hour heatmap';

  @override
  String get rptHeatmapSub => '7 hari · jam 11—22';

  @override
  String get rptHeatQuiet => 'SEPI';

  @override
  String get rptHeatBusy => 'PADAT';

  @override
  String get rptReservationConv => 'Konversi reservasi';

  @override
  String get rptReservationNoModule => 'Belum ada modul reservasi';

  @override
  String get rptReservationNoModuleBody =>
      'Aktifkan modul reservasi (P3) untuk melihat konversi.';

  @override
  String rptReservationSub(int booked, int seated, int noShow) {
    return '$booked dipesan · $seated duduk · $noShow no-show';
  }

  @override
  String get rptSeated => 'Duduk';

  @override
  String get rptNoShow => 'No-show';

  @override
  String get rptCancelled => 'Batal';

  @override
  String get rptVoidReasons => 'Alasan void & comp';

  @override
  String get rptNoVoids => 'Belum ada void';

  @override
  String rptVoidSub(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kejadian',
    );
    return '$_temp0 · $amount hilang';
  }

  @override
  String get rptVoidPerWaiter => 'Void per pelayan';

  @override
  String rptTopReason(String reason) {
    return 'alasan: $reason';
  }

  @override
  String get rptNoSection => 'Tidak ada bagian aktif';

  @override
  String get rptNoSectionBody => 'Aktifkan minimal satu tab di atas';

  @override
  String get stkDimMass => 'Berat';

  @override
  String get stkDimVolume => 'Volume';

  @override
  String get stkDimCount => 'Jumlah';

  @override
  String get stkTitle => 'Stok';

  @override
  String get stkSubOpname => 'Stok opname physical audit';

  @override
  String get stkSub => 'Bahan, penerimaan & mutasi';

  @override
  String get stkAddIngredient => 'Tambah bahan';

  @override
  String get stkOpname => 'Opname';

  @override
  String stkSaveCount(int n) {
    return 'Simpan ($n)';
  }

  @override
  String stkLoadFailed(String error) {
    return 'Gagal memuat stok: $error';
  }

  @override
  String get stkEmptyTitle => 'Belum Ada Bahan';

  @override
  String get stkEmptyBody =>
      'Tambahkan bahan pertama Anda, lalu susun resepnya di editor menu agar stok berkurang otomatis saat pesanan dikirim.';

  @override
  String get stkNoMatch =>
      'Tidak ada bahan yang cocok dengan pencarian / filter.';

  @override
  String get stkKpiLow => 'MENIPIS';

  @override
  String stkCountIngredients(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Bahan',
    );
    return '$_temp0';
  }

  @override
  String get stkNeedReorder => 'Perlu reorder';

  @override
  String get stkStockOk => 'Stok aman';

  @override
  String get stkKpiNegative => 'STOK MINUS';

  @override
  String get stkNeedOpname => 'Perlu opname segera';

  @override
  String get stkKpiProduced => 'PRODUKSI MANDIRI';

  @override
  String stkOfRegistered(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n bahan terdaftar',
    );
    return 'dari $_temp0';
  }

  @override
  String get stkOpnameMode => 'MODE STOK OPNAME';

  @override
  String get stkOpnameHint =>
      'Ketik jumlah fisik di gudang saat ini. Selisih akan otomatis dihitung sebagai penyesuaian mutasi.';

  @override
  String stkFilled(int n) {
    return '$n diisi';
  }

  @override
  String get stkSearchHint => 'Cari nama bahan...';

  @override
  String stkFilterAll(int n) {
    return 'Semua ($n)';
  }

  @override
  String stkFilterLow(int n) {
    return 'Menipis ($n)';
  }

  @override
  String stkFilterNegative(int n) {
    return 'Minus ($n)';
  }

  @override
  String stkFilterProduced(int n) {
    return 'Produksi ($n)';
  }

  @override
  String get stkBadgeProduced => 'PRODUKSI';

  @override
  String get stkBadgeLow => 'MENIPIS';

  @override
  String get stkBadgeNegative => 'MINUS';

  @override
  String get stkColOnHand => 'STOK SAAT INI';

  @override
  String stkColPricePer(String unit) {
    return 'HARGA / $unit';
  }

  @override
  String get stkColLastReceived => 'TERAKHIR TERIMA';

  @override
  String get stkReceive => 'Terima';

  @override
  String get stkMenuReceive => 'Terima barang';

  @override
  String get stkMenuProduce => 'Produksi batch';

  @override
  String get stkMenuLedger => 'Riwayat mutasi';

  @override
  String get stkMenuEdit => 'Ubah bahan';

  @override
  String get stkMenuArchive => 'Arsipkan';

  @override
  String stkMinThreshold(String qty) {
    return 'Batas min: $qty';
  }

  @override
  String get stkVarianceExact => 'Pas';

  @override
  String get stkOpnameDoneNoVariance => 'Opname selesai — tidak ada selisih';

  @override
  String stkOpnameDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n bahan',
    );
    return 'Opname selesai — $_temp0 disesuaikan';
  }

  @override
  String stkSaveFailed(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String stkFailed(String error) {
    return 'Gagal: $error';
  }

  @override
  String stkReceiveTitle(String name) {
    return 'Terima $name';
  }

  @override
  String get stkReceiveSub => 'Catat penambahan stok dan harga beli terbaru.';

  @override
  String stkPricePer(String unit) {
    return 'Harga per $unit (opsional)';
  }

  @override
  String get stkPriceHelper => 'Kosongkan jika tidak mengubah harga rata-rata';

  @override
  String get stkSupplier => 'Pemasok (opsional)';

  @override
  String get stkReceiveOk => 'Stok berhasil ditambahkan';

  @override
  String stkProduceTitle(String name) {
    return 'Produksi $name';
  }

  @override
  String stkProduceSub(String qty) {
    return '1 batch = $qty. Bahan baku penyusun akan berkurang otomatis.';
  }

  @override
  String get stkBatchCount => 'Jumlah batch';

  @override
  String get stkProduceOk => 'Produksi berhasil dicatat';

  @override
  String stkArchived(String name) {
    return '$name diarsipkan';
  }

  @override
  String get stkNewIngredient => 'Bahan Baru';

  @override
  String stkEditIngredient(String name) {
    return 'Ubah $name';
  }

  @override
  String get stkEditorSub => 'Atur nama, satuan unit, dan batas reorder.';

  @override
  String get stkName => 'Nama bahan';

  @override
  String get stkUnit => 'Satuan';

  @override
  String stkUnitOption(String unit, String dimension) {
    return '$unit · $dimension';
  }

  @override
  String stkOpening(String unit) {
    return 'Stok awal ($unit)';
  }

  @override
  String get stkOpeningHelper => 'Dicatat sebagai mutasi awal';

  @override
  String stkLowAt(String unit) {
    return 'Batas menipis ($unit, opsional)';
  }

  @override
  String get stkLowAtHelper =>
      'Munculkan peringatan saat stok di bawah angka ini';

  @override
  String stkBatchYield(String unit) {
    return 'Hasil 1 batch ($unit, opsional)';
  }

  @override
  String get stkBatchYieldHelper =>
      'Isi bila bahan ini hasil racikan internal, lalu susun resepnya';

  @override
  String get stkSaveOk => 'Bahan berhasil disimpan';

  @override
  String get stkLedgerTitle => 'Riwayat Mutasi';

  @override
  String stkLedgerLoadFailed(String error) {
    return 'Gagal memuat: $error';
  }

  @override
  String get stkLedgerEmpty => 'Belum ada riwayat mutasi untuk bahan ini.';

  @override
  String get stkAddFirst => 'Tambah Bahan Pertama';

  @override
  String get stkUnused => 'belum dipakai';

  @override
  String durYears(int n) {
    return '${n}thn';
  }

  @override
  String durMonths(int n) {
    return '${n}bl';
  }

  @override
  String durDays(int n) {
    return '${n}h';
  }

  @override
  String durHours(int n) {
    return '${n}j';
  }

  @override
  String durMins(int n) {
    return '${n}m';
  }

  @override
  String durSecs(int n) {
    return '${n}d';
  }

  @override
  String durDh(int d, int h) {
    return '${d}h ${h}j';
  }

  @override
  String durHm(int h, int m) {
    return '${h}j ${m}m';
  }

  @override
  String durMs(int m, int s) {
    return '${m}m ${s}d';
  }

  @override
  String durHms(int h, int m, int s) {
    return '${h}j ${m}m ${s}d';
  }

  @override
  String relAgo(String value) {
    return '$value lalu';
  }

  @override
  String relIn(String value) {
    return '$value lagi';
  }

  @override
  String get elapsedYesterday => 'kemarin';

  @override
  String elapsedDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hari',
    );
    return '$_temp0 lalu';
  }

  @override
  String get sysTitle => 'Sistem';

  @override
  String get sysVenueFallback => 'Venue';

  @override
  String sysHeaderSub(String venue) {
    return '$venue · v2.0';
  }

  @override
  String get sysDegraded => 'Mode degraded';

  @override
  String get sysLanOnline => 'LAN online';

  @override
  String get sysKdsOnline => 'KDS Online';

  @override
  String get sysNoStations => 'Belum ada stasiun';

  @override
  String get sysStationsActive => 'Stasiun aktif';

  @override
  String get sysTabletPair => 'Tablet Pair';

  @override
  String get sysNoDevices => 'Belum ada perangkat';

  @override
  String get sysDevicesActive => 'Perangkat aktif';

  @override
  String get sysQueue => 'Antrian';

  @override
  String get sysNoPendingJobs => 'Tidak ada job tertunda';

  @override
  String get sysTicketsWaiting => 'Tiket menunggu';

  @override
  String get sysServerLan => 'Server LAN';

  @override
  String get sysTagBooting => 'BOOTING';

  @override
  String get sysTagPrimary => 'PRIMARY';

  @override
  String get sysAddress => 'Alamat';

  @override
  String get sysUptime => 'Uptime';

  @override
  String get sysCertificate => 'Sertifikat';

  @override
  String get sysPingLan => 'Ping LAN';

  @override
  String sysPingValue(int p50, int last) {
    return 'p50 $p50 ms · last $last ms';
  }

  @override
  String get sysP95 => 'p95 latensi';

  @override
  String sysP95Value(int ms, int count) {
    return '$ms ms · $count req';
  }

  @override
  String get sysFingerprint => 'Fingerprint';

  @override
  String get sysCopy => 'Salin';

  @override
  String get sysFingerprintCopied => 'Fingerprint disalin';

  @override
  String get sysNoneYet => 'Belum ada';

  @override
  String get sysAddPrinterOrStation => 'Tambahkan printer atau stasiun';

  @override
  String get sysPrintersKds => 'Printer & KDS';

  @override
  String sysTagStations(int n) {
    return '$n STASIUN';
  }

  @override
  String get sysDiscover => 'Cari';

  @override
  String get sysAddPrinterBtn => '+ Printer';

  @override
  String get sysPrinterTest => 'Test';

  @override
  String get sysTestPrinted => 'Tes tercetak';

  @override
  String get sysOnline => 'Online';

  @override
  String get sysOffline => 'Offline';

  @override
  String sysStationLoad(int staff, int tickets) {
    String _temp0 = intl.Intl.pluralLogic(
      tickets,
      locale: localeName,
      other: '$tickets tiket',
    );
    return '$staff staf · $_temp0';
  }

  @override
  String get sysStationQuiet => 'Sepi';

  @override
  String get sysStationBusy => 'Aktif';

  @override
  String get sysDevicesTitle => 'Perangkat aktif';

  @override
  String sysTagPair(int n) {
    return '$n PAIR';
  }

  @override
  String get sysNoDevicesPaired => 'Belum ada perangkat dipasangkan';

  @override
  String get sysNeverSignedIn => 'belum sign-in';

  @override
  String sysLastSession(String when) {
    return 'sesi $when';
  }

  @override
  String get sysRevoked => 'Revoked';

  @override
  String get sysDeviceActive => 'Aktif';

  @override
  String get sysDeviceIdle => 'Idle';

  @override
  String get sysRevoke => 'Revoke';

  @override
  String get sysOperational => 'Operasional';

  @override
  String get sysTagRuntime => 'RUNTIME';

  @override
  String get sysActions => 'Tindakan';

  @override
  String get sysRestartServer => 'Mulai ulang server';

  @override
  String get sysWaitingProbe => 'tunggu probe…';

  @override
  String get sysOfflineLower => 'offline';

  @override
  String sysPingWs(int ms, String state) {
    return '$ms ms · $state';
  }

  @override
  String get sysPhoneSub => 'Server, jaringan, printer, perangkat';

  @override
  String sysPrinterStationCount(int printers, int stations) {
    String _temp0 = intl.Intl.pluralLogic(
      printers,
      locale: localeName,
      other: '$printers printer',
    );
    String _temp1 = intl.Intl.pluralLogic(
      stations,
      locale: localeName,
      other: '$stations stasiun',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get sysDevices => 'Perangkat';

  @override
  String sysPairActiveCount(int paired, int active) {
    return '$paired pair · $active aktif';
  }

  @override
  String get sysNoManageStaff => 'Tidak punya izin manageStaff';

  @override
  String get sysRestarting => 'Server restart… menyambung ulang';

  @override
  String sysRestartFailed(String code) {
    return 'Restart gagal: $code';
  }

  @override
  String get sysRevokeTitle => 'Revoke perangkat?';

  @override
  String sysRevokeBody(String label) {
    return '$label akan kehilangan sesi.';
  }

  @override
  String get sysSearchingPrinters => 'Mencari printer…';

  @override
  String get sysNoPrintersFound => 'Tidak ada printer ditemukan';

  @override
  String get sysPrintersFound => 'Printer ditemukan';

  @override
  String sysHostPort(String host, int port) {
    return '$host:$port';
  }

  @override
  String sysPrinterAdded(String name) {
    return 'Printer \"$name\" ditambahkan';
  }

  @override
  String get sysAddPrinterTitle => 'Tambah printer';

  @override
  String get sysPrinterLabel => 'Label';

  @override
  String get sysPrinterHost => 'Host (IP)';

  @override
  String get sysPrinterPort => 'Port';

  @override
  String get sysPrinterKind => 'Jenis';

  @override
  String sysHeroWarnDesc(String ws, String reach, int fails) {
    return 'WS $ws · reach=$reach · $fails gagal';
  }

  @override
  String sysHeroOkDesc(int sessions, int devices, String ws) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions sesi aktif',
    );
    String _temp1 = intl.Intl.pluralLogic(
      devices,
      locale: localeName,
      other: '$devices perangkat',
    );
    return '$_temp0 · $_temp1 · WS $ws';
  }

  @override
  String get sysReachOk => 'ok';

  @override
  String get sysReachOff => 'off';

  @override
  String get sysServerLanOk => 'Server LAN OK';

  @override
  String get sysRestartTitle => 'Mulai ulang server?';

  @override
  String get sysRestartBody =>
      'WS clients akan disconnect ~1-3 detik. Masukkan PIN untuk konfirmasi.';

  @override
  String get sysPin => 'PIN';

  @override
  String get sysConfirm => 'Konfirmasi';

  @override
  String get sysWrongPin => 'PIN salah';

  @override
  String get retry => 'Coba lagi';

  @override
  String get tblOtherUser => 'pengguna lain';

  @override
  String tblTakenBy(String holder) {
    return 'Meja diambil oleh $holder';
  }

  @override
  String tblAlreadySeated(String holder) {
    return 'Meja sudah diisi oleh $holder';
  }

  @override
  String tblSeatFailed(String error) {
    return 'Gagal mulai layani: $error';
  }

  @override
  String get tblReleaseTable => 'Lepaskan Meja';

  @override
  String get tblFinishService => 'Selesaikan Layanan';

  @override
  String get tblLoadingMenu => 'Memuat menu…';

  @override
  String get tblMenuLoadFailed => 'Gagal memuat menu meja';

  @override
  String get tblReleaseTableQ => 'Lepaskan Meja?';

  @override
  String get tblFinishServiceQ => 'Selesaikan Layanan?';

  @override
  String tblReleaseBody(String table) {
    return 'Belum ada pesanan. Kosongkan meja $table?';
  }

  @override
  String tblFinishBody(String table) {
    return 'Semua tiket telah selesai. Kosongkan meja $table untuk tamu berikutnya? Tagihan tetap di kasir sampai dibayar.';
  }

  @override
  String tblCloseFailed(String error) {
    return 'Gagal menutup meja: $error';
  }

  @override
  String get tblEmptyPhone =>
      'Belum ada item — ketuk \"Tambah ke pesanan\" untuk mulai.';

  @override
  String get tblContextTitle => 'Konteks meja';

  @override
  String tblSeatedFor(String elapsed, int pax) {
    return 'DUDUK $elapsed · $pax TAMU';
  }

  @override
  String tblItemCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n item',
    );
    return '$_temp0';
  }

  @override
  String tblItemCountHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n item',
    );
    return '$_temp0 · ditahan';
  }

  @override
  String tblFireCourse(String course) {
    return 'Bakar $course';
  }

  @override
  String tblKosong(String table) {
    return 'Meja $table kosong';
  }

  @override
  String get tblKosongHint => 'Tap untuk mulai melayani tamu';

  @override
  String get tblStartService => 'Mulai layani meja';

  @override
  String tblLockedBy(String holder, String since) {
    return 'Terkunci oleh $holder$since · hanya lihat';
  }

  @override
  String tblLockedSince(String time) {
    return ' · sejak $time';
  }

  @override
  String tblReadyToCollect(int n) {
    return '$n siap diambil';
  }

  @override
  String get tblViewOnly => 'Hanya lihat';

  @override
  String get tblCreateOrder => 'Buat pesanan';

  @override
  String get tblAddOrder => 'Tambah pesanan';

  @override
  String get tblStatTotal => 'Total item';

  @override
  String get tblStatInProgress => 'Dalam proses';

  @override
  String get tblStatServed => 'Disajikan';

  @override
  String get tblGuestNotes => 'CATATAN TAMU';

  @override
  String get tblNoGuestNotes => 'Belum ada catatan khusus.';

  @override
  String get tblSpecialInstruction => 'Instruksi khusus';

  @override
  String get tblAllergensInOrder => 'ALERGEN DI PESANAN';

  @override
  String get tblNoAllergens => 'Tidak ada.';

  @override
  String get tblQuickActions => 'AKSI CEPAT';

  @override
  String get tblPrintTableReceipt => 'Cetak struk meja';

  @override
  String get tblMoveTable => 'Pindahkan meja';

  @override
  String get mieBlankNames => 'Lengkapi nama yang masih kosong';

  @override
  String mieSaveFailed(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get mieItemAdded => 'Item ditambahkan';

  @override
  String get mieChangesSaved => 'Perubahan tersimpan';

  @override
  String get mieDeleteTitle => 'Hapus item?';

  @override
  String mieDeleteBody(String name) {
    return 'Item \"$name\" akan dihapus dari menu.';
  }

  @override
  String get mieNewItem => 'Item baru';

  @override
  String get mieReadOnlySub => 'Hanya admin yang bisa edit';

  @override
  String get mieIdentity => 'Identitas';

  @override
  String get mieItemName => 'Nama item';

  @override
  String get mieShortDesc => 'Deskripsi singkat';

  @override
  String get mieCategory => 'Kategori';

  @override
  String get miePhotoChange => 'UBAH';

  @override
  String get miePhotoAdd => 'FOTO';

  @override
  String get miePickGallery => 'Pilih dari galeri';

  @override
  String get mieTakePhoto => 'Ambil foto';

  @override
  String get mieDeletePhoto => 'Hapus foto';

  @override
  String miePhotoLoadFailed(String error) {
    return 'Gagal memuat foto: $error';
  }

  @override
  String get miePhotoSaveFailed => 'Gagal menyimpan foto';

  @override
  String get miePricing => 'Harga';

  @override
  String get mieBasePrice => 'Harga dasar';

  @override
  String mieFollowVenue(int mins) {
    return 'Ikut venue (${mins}m)';
  }

  @override
  String get miePrepTime => 'Waktu siap (menit)';

  @override
  String get mieCost => 'HPP';

  @override
  String get mieVariants => 'Varian ukuran';

  @override
  String get mieAddVariant => '+ Varian';

  @override
  String get mieNoVariants => 'Belum ada varian. Hanya pakai harga dasar.';

  @override
  String get mieVariantNameHint => 'Nama (mis. Besar)';

  @override
  String get miePrice => 'Harga';

  @override
  String get mieModifierGroups => 'Grup modifier';

  @override
  String get mieAddGroup => '+ Grup';

  @override
  String get mieNoModifiers =>
      'Belum ada grup modifier (mis. tingkat pedas, pilih protein).';

  @override
  String get mieGroupName => 'Nama grup';

  @override
  String get mieRequired => 'Wajib';

  @override
  String get mieMulti => 'Pilih banyak';

  @override
  String get mieAddOption => '+ Opsi';

  @override
  String get mieOptionName => 'Nama opsi';

  @override
  String get mieRecipe => 'Resep';

  @override
  String mieIngredientsLoadFailed(String error) {
    return 'Gagal memuat bahan: $error';
  }

  @override
  String get mieNoIngredients =>
      'Belum ada bahan. Tambahkan di menu Stok sebelum menyusun resep.';

  @override
  String get mieScopeBase => 'Dasar';

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
      'Resep varian menggantikan resep dasar sepenuhnya. Kosong = ikut resep dasar.';

  @override
  String get mieRecipeOptionHint =>
      'Resep modifier ditambahkan di atas resep yang berlaku.';

  @override
  String get mieRecipeBaseHint =>
      'Dipakai saat item tidak punya varian, atau varian belum punya resep sendiri.';

  @override
  String get mieRecipeEmpty => 'Belum ada bahan pada resep ini.';

  @override
  String get mieAddIngredient => 'Tambah bahan';

  @override
  String get mieIngredient => 'Bahan';

  @override
  String mieIngredientOption(String name, String unit) {
    return '$name ($unit)';
  }

  @override
  String get mieQty => 'Jumlah';

  @override
  String get mieTags => 'Tag';

  @override
  String get mieAllergens => 'Alergen';

  @override
  String get mieDiet => 'Diet';

  @override
  String get mieAvailability => 'Ketersediaan';

  @override
  String get mieAutoSoldOut => 'Tidak tersedia (stok 0)';

  @override
  String get mieManualSoldOut => 'Tidak tersedia (manual)';

  @override
  String get mieActiveForSale => 'Aktif untuk dijual';

  @override
  String get mieActivate => 'Aktifkan';

  @override
  String get mieMarkUnavailable => 'Tandai tidak tersedia';

  @override
  String get mieUnavailable => 'Tidak tersedia';

  @override
  String get mieActive => 'Aktif';

  @override
  String mieDerivedCost(String amount) {
    return '≈ $amount dari resep dasar';
  }

  @override
  String get mieRequiredField => 'Wajib diisi';

  @override
  String get mieMargin => 'MARGIN';

  @override
  String get mieMarginNoPrice => 'Isi harga dasar dulu';

  @override
  String get mieMarginHealthy => 'Margin sehat';

  @override
  String get mieMarginThin => 'Margin tipis';

  @override
  String get mieMarginCritical => 'Margin kritis';

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
      other: '$total item',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cats,
      locale: localeName,
      other: '$cats kategori',
    );
    return '$_temp0 · $_temp1 · $out tidak tersedia';
  }

  @override
  String mnaPhoneSub(int total, int out) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total item',
    );
    return '$_temp0 · $out tidak tersedia';
  }

  @override
  String get mnaAddItem => '+ Tambah item';

  @override
  String get mnaPickStaff => 'Pilih item untuk lihat detail';

  @override
  String get mnaPickAdmin => 'Pilih item atau tambah baru';

  @override
  String get mnaPickStaffSub =>
      'Mode staf: hanya tandai habis. Edit penuh hanya admin.';

  @override
  String get mnaPickAdminSub =>
      'Kelola harga, modifier, stok, dan ketersediaan.';

  @override
  String get mnaSearchHint => 'Cari item, deskripsi…';

  @override
  String get mnaAll => 'Semua';

  @override
  String get mnaNoMatch => 'Tidak ada item cocok.';

  @override
  String get mnaIngredientsOut => 'Bahan habis';

  @override
  String mnaVariantsOut(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n varian',
    );
    return '$_temp0 habis';
  }

  @override
  String get mnaAutoOut => 'AUTO HABIS';

  @override
  String get mnaOut => 'HABIS';

  @override
  String get mnaOn => 'AKTIF';

  @override
  String get mnaTabItems => 'Item';

  @override
  String get mnaTabCategories => 'Kategori';

  @override
  String get mnaTabTags => 'Tag';

  @override
  String get mnaNewCategory => 'Kategori baru';

  @override
  String get mnaRenameCategory => 'Ubah nama kategori';

  @override
  String mnaMoveItemsFirst(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
    );
    return 'Pindahkan $_temp0 dulu sebelum hapus \"$name\"';
  }

  @override
  String get mnaCategoryInUse => 'Gagal hapus kategori — masih dipakai item';

  @override
  String get mnaCategoryNameHint => 'Nama kategori';

  @override
  String mnaDeleteTagTitle(String name) {
    return 'Hapus \"$name\"?';
  }

  @override
  String get mnaDeleteTagBody =>
      'Tag ini akan dilepas dari semua item yang memakainya.';

  @override
  String mnaTagDeleted(String name) {
    return '\"$name\" dihapus';
  }

  @override
  String get mnaNewTag => 'Tag baru';

  @override
  String get mnaEditTag => 'Ubah tag';

  @override
  String get mnaTagName => 'Nama';

  @override
  String get mnaTagCode => 'Kode badge';

  @override
  String get mnaRoleAdmin => 'ADMIN';

  @override
  String get mnaRoleStaff => 'STAF · TANDAI HABIS';

  @override
  String get mnuLoadFailed => 'Gagal memuat menu';

  @override
  String get mnuAddToTakeaway => 'Tambah ke Bawa pulang';

  @override
  String get mnuNewOrder => 'Pesanan baru';

  @override
  String mnuAddToTable(String table) {
    return 'Tambah ke Meja $table';
  }

  @override
  String get mnuTakeawayNoTable => 'BAWA PULANG · TANPA MEJA';

  @override
  String get mnuNoTablePickLater => 'TANPA MEJA · PILIH MEJA SAAT KIRIM';

  @override
  String mnuZonePax(String zone, int pax) {
    return '$zone · $pax TAMU';
  }

  @override
  String get mnuAddItem => 'Tambah item';

  @override
  String get mnuAddItemHint =>
      'KETUK UNTUK ATUR · TEKAN LAMA UNTUK TAMBAH DEFAULT';

  @override
  String mnuPending(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n item',
    );
    return '$_temp0 pending';
  }

  @override
  String mnuServicePct(String pct) {
    return 'Layanan · $pct';
  }

  @override
  String mnuTaxPct(String pct) {
    return 'Pajak · $pct';
  }

  @override
  String get mnuHeadTakeaway => 'BAWA PULANG · TANPA MEJA';

  @override
  String get mnuHeadTableless => 'PESANAN BARU · TANPA MEJA';

  @override
  String mnuHeadTable(String table) {
    return 'PESANAN BARU · MEJA $table';
  }

  @override
  String get mnuCartEmpty => 'Keranjang kosong';

  @override
  String mnuCartReady(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n item',
    );
    return '$_temp0 siap kirim';
  }

  @override
  String mnuKitchenCount(int n) {
    return 'Dapur × $n';
  }

  @override
  String mnuBarCount(int n) {
    return 'Bar × $n';
  }

  @override
  String get mnuCartEmptyHint =>
      'Belum ada item di keranjang. Pilih dari menu di kiri.';

  @override
  String get mnuEstimate => 'Estimasi';

  @override
  String mnuReviewSendTo(String target) {
    return 'Tinjau & kirim ke $target';
  }

  @override
  String get mnuTargetKitchenBar => 'dapur + bar';

  @override
  String get mnuTargetKitchen => 'dapur';

  @override
  String get mnuTargetBar => 'bar';

  @override
  String get dscNewPreset => 'Preset baru';

  @override
  String get dscEditPreset => 'Ubah preset';

  @override
  String get dscEmptyTitle => 'Belum ada preset diskon';

  @override
  String get dscEmptyBody =>
      'Buat preset agar kasir bisa memberi diskon tanpa mengetik angka sendiri.';

  @override
  String get dscIntro =>
      'Kasir memilih dari daftar ini — mereka tidak bisa mengetik angka diskon sendiri.';

  @override
  String get dscScopeOrder => 'Seluruh pesanan';

  @override
  String get dscScopeLine => 'Per item';

  @override
  String get dscInactive => 'nonaktif';

  @override
  String get dscDeleteTitle => 'Hapus preset';

  @override
  String dscDeleteBody(String name) {
    return 'Hapus \"$name\"? Diskon yang sudah dipakai di tagihan lama tidak berubah — nilainya sudah tersimpan di sana.';
  }

  @override
  String get dscNameLabel => 'Nama (tampil di struk)';

  @override
  String get dscNameHint => 'Diskon Member';

  @override
  String get dscKindPercent => 'Persen';

  @override
  String get dscKindFixed => 'Nominal';

  @override
  String get dscValuePercent => 'Persen (%)';

  @override
  String get dscValueFixed => 'Nominal (Rp)';

  @override
  String get dscActive => 'Aktif';

  @override
  String get dscActiveHint => 'Nonaktif menyembunyikan preset dari kasir';

  @override
  String get dscErrName => 'Nama wajib diisi';

  @override
  String get dscErrValue => 'Nilai harus lebih dari 0';

  @override
  String get dscErrMax => 'Maksimal 100%';

  @override
  String revSendFailed(String error) {
    return 'Gagal kirim: $error';
  }

  @override
  String get revTitle => 'Tinjau pesanan';

  @override
  String revHeadTakeaway(int n) {
    return 'BAWA PULANG · $n ITEM';
  }

  @override
  String revHeadTableless(int n) {
    return 'TANPA MEJA · $n ITEM · PILIH MEJA SAAT KIRIM';
  }

  @override
  String revHeadTable(String table, int pax, int n) {
    return 'MEJA $table · $pax TAMU · $n ITEM';
  }

  @override
  String get revEstimatedTotal => 'Total perkiraan';

  @override
  String get revPaymentNote =>
      'PEMBAYARAN DITANGANI DI LUAR SATSET · BILL DICETAK DARI POS SAAT DISAJIKAN';

  @override
  String get revSending => 'Mengirim…';

  @override
  String get revAddToOrder => 'Tambah ke pesanan';

  @override
  String get revSendOrder => 'Kirim pesanan';

  @override
  String revSendTo(String target) {
    return 'Kirim ke $target';
  }

  @override
  String get revTableTaken => 'Meja keburu terisi. Pilih meja lain.';

  @override
  String revSeatFailed(String error) {
    return 'Gagal menempati meja: $error';
  }

  @override
  String get revCommitTitle => 'Kirim pesanan ke';

  @override
  String get revCommitDineIn => 'Meja (dine-in)';

  @override
  String get revCommitDineInSub => 'Tetapkan ke meja kosong';

  @override
  String get revCommitTakeaway => 'Bawa pulang';

  @override
  String get revCommitTakeawaySub => 'Takeaway tanpa meja';

  @override
  String get revChannel => 'Kanal';

  @override
  String get revGuestOrCourier => 'Nama tamu / kurir';

  @override
  String get revGuestHint => 'mis. Budi · atau Rizal (kurir)';

  @override
  String get revPrepaid => 'Sudah dibayar aplikasi';

  @override
  String get revContinue => 'Lanjut';

  @override
  String get revAutoFire => 'auto-bakar';

  @override
  String get revHeldUntilFired => 'ditahan sampai dibakar';

  @override
  String get pinErrEmailEmpty => 'Email belum diisi.';

  @override
  String get pinErrEmailInvalid => 'Email tidak valid.';

  @override
  String get pinErrPasswordEmpty => 'Password belum diisi.';

  @override
  String get pinErrPasswordShort => 'Minimal 6 karakter.';

  @override
  String get pinEnterPin => 'Masukkan PIN';

  @override
  String pinConnectedTo(String server) {
    return 'Tersambung ke $server';
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
  String get pinForgotPassword => 'Lupa password?';

  @override
  String get pinModeAdmin => 'Admin';

  @override
  String get pinModeStaff => 'Staff';

  @override
  String get pinSearchingServers =>
      'Mencari server di jaringan… pastikan tablet server menyala dan berada di Wi-Fi yang sama.';

  @override
  String get pinHostTakenTitle => 'Venue ini sudah punya perangkat utama';

  @override
  String get pinHostTakenBody =>
      'Satu venue berjalan di satu perangkat. Tutup aplikasi di perangkat itu, lalu coba lagi di sini.';

  @override
  String get pinHostTakenNote =>
      'Kalau perangkat itu memang yang dipakai, akun ini bukan admin utama venue — hubungi operator.';

  @override
  String get pinSignOut => 'Keluar';

  @override
  String get pinCheckingSession => 'Memeriksa sesi…';

  @override
  String get pinReachConnected => 'Tersambung';

  @override
  String pinReachConnectedMs(int ms) {
    return 'Tersambung · ${ms}ms';
  }

  @override
  String get pinReachUnreachable => 'Server tidak terjangkau';

  @override
  String get pinReachChecking => 'Memeriksa sambungan…';

  @override
  String get pinServerConnected => 'SERVER TERSAMBUNG';

  @override
  String get pinChangeServer => 'Ubah server';

  @override
  String get stlModePenuh => 'Penuh';

  @override
  String get stlModePerItem => 'Per item';

  @override
  String get stlModeBagiRata => 'Bagi rata';

  @override
  String get stlPayTunai => 'Tunai';

  @override
  String get stlPayQris => 'QRIS';

  @override
  String get stlPayKartu => 'Kartu';

  @override
  String get stlPayTransfer => 'Transfer';

  @override
  String get stlPayLainnya => 'Lainnya';

  @override
  String get stlProofTunai => 'Hitung uang tamu di papan pecahan';

  @override
  String get stlProofQris => 'Screenshot konfirmasi QRIS wajib dilampirkan';

  @override
  String get stlProofKartu => 'Foto slip EDC — approval code terlihat';

  @override
  String get stlProofTransfer => 'Foto bukti transfer + nama pengirim';

  @override
  String get stlProofLainnya => 'Foto bukti pembayaran';

  @override
  String get stlBlkNoLines => 'Tagihan belum punya item';

  @override
  String get stlBlkNothingLeft => 'Tidak ada sisa untuk ditagih';

  @override
  String get stlBlkPickItems => 'Pilih item dari daftar';

  @override
  String get stlBlkNothingToCharge => 'Tidak ada yang bisa ditagih';

  @override
  String get stlBlkTapCash => 'Ketuk pecahan uang yang diterima';

  @override
  String get stlBlkAttachProof => 'Lampirkan foto bukti bayar dulu';

  @override
  String stlPhotoFailed(String error) {
    return 'Gagal mengambil foto: $error';
  }

  @override
  String get stlTitle => 'Penyelesaian';

  @override
  String get stlOutstandingHint => 'sisa yang harus ditagih';

  @override
  String get stlRowTotal => 'Total tagihan';

  @override
  String get stlRowAlreadyPaid => 'Sudah diterima';

  @override
  String get stlRowReceivingNow => 'Diterima sekarang';

  @override
  String get stlPerItemEmpty =>
      'Ketuk item yang dibayar tamu ini. Item yang sudah lunas terkunci.';

  @override
  String stlRowNItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get stlRowServiceTax => 'Layanan + pajak';

  @override
  String get stlRowPayingNow => 'Dibayar sekarang';

  @override
  String get stlRowRemainderAfter => 'Sisa setelah ini';

  @override
  String get stlRowPerHead => 'Per orang (bulat 100)';

  @override
  String stlRowOpenShares(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bagian belum bayar',
    );
    return '$_temp0';
  }

  @override
  String get stlRowChargeNow => 'Tagih sekarang';

  @override
  String get stlSplitFor => 'Bagi untuk';

  @override
  String get stlMethod => 'Metode';

  @override
  String stlLockedTo(String method) {
    return 'Terkunci — pembayaran sebelumnya $method';
  }

  @override
  String get stlProofAttached => 'Bukti terlampir';

  @override
  String get stlRetakePhoto => 'Ambil ulang';

  @override
  String get stlTakePhoto => 'Ambil foto bukti bayar';

  @override
  String stlConfirmItems(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Terima $count item · $amount',
    );
    return '$_temp0';
  }

  @override
  String stlConfirmShare(String amount) {
    return 'Terima bagian · $amount';
  }

  @override
  String stlConfirmFull(String amount) {
    return 'Terima $amount';
  }

  @override
  String get stlAutoPrintHint => 'Struk tercetak otomatis setelah dikonfirmasi';

  @override
  String get zoneAdminTableNameHint => 'mis. T7, Booth A';

  @override
  String get zoneAdminManageZones => 'Kelola Zona';

  @override
  String zoneAdminSummary(int zones, int tables, int seats) {
    String _temp0 = intl.Intl.pluralLogic(
      zones,
      locale: localeName,
      other: '$zones zona',
    );
    String _temp1 = intl.Intl.pluralLogic(
      tables,
      locale: localeName,
      other: '$tables meja',
    );
    String _temp2 = intl.Intl.pluralLogic(
      seats,
      locale: localeName,
      other: '$seats kursi',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String get zoneAdminEmpty => 'Belum ada zona. Tambah zona pertama.';

  @override
  String zoneAdminMoveTablesFirst(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pindahkan $count meja dulu sebelum hapus zona.',
    );
    return '$_temp0';
  }

  @override
  String get zoneAdminDeleteZoneTitle => 'Hapus zona?';

  @override
  String zoneAdminDeleteZoneBody(String name) {
    return 'Zona \"$name\" akan dihapus.';
  }

  @override
  String get zoneAdminNewZone => 'Zona baru';

  @override
  String zoneAdminEditZone(String name) {
    return 'Atur $name';
  }

  @override
  String get zoneAdminZoneName => 'Nama zona';

  @override
  String get zoneAdminZoneNameHint => 'mis. Teras, Bar';

  @override
  String get zoneAdminColor => 'Warna';

  @override
  String get zoneAdminPreview => 'PRATINJAU';

  @override
  String get zoneAdminNoTablesHere => 'Belum ada meja di zona ini.';

  @override
  String zoneAdminTablesHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meja saat ini ada di zona ini.',
    );
    return '$_temp0';
  }

  @override
  String get vstIdentityHead => 'IDENTITAS RESTORAN';

  @override
  String get vstNoLegalName => 'Belum ada nama legal';

  @override
  String get vstNoAddress => 'Belum ada alamat';

  @override
  String get vstLegalNameHint => 'PT …';

  @override
  String get vstPhoneHint => '+62 …';

  @override
  String get vstTaglineHint => 'mis. Kopi & Dapur';

  @override
  String get vstHeaderHint => 'Tampil di atas struk';

  @override
  String get vstSocialHint => '@instagram · wa.me/…';

  @override
  String get vstFooterHint => 'Tampil di bawah struk';

  @override
  String get vstThankYouHint => 'Terima kasih';

  @override
  String get vstQrUrlHint => 'https://… (hanya struk uang)';

  @override
  String get vstQrCaptionHint => 'mis. Ulas kami di Google';

  @override
  String get vstNotSet => 'Belum diisi';

  @override
  String vstReportsStartAt(String hour) {
    return 'Mulai $hour:00';
  }

  @override
  String vstTaxOn(String pct) {
    return '$pct PPN';
  }

  @override
  String get vstTaxOff => 'PPN off';

  @override
  String get vstServiceOff => 'Layanan off';

  @override
  String vstServiceValue(String value) {
    return 'Layanan $value';
  }

  @override
  String get vstFeesTag => 'BIAYA';

  @override
  String get vstEnableTax => 'Aktifkan PPN';

  @override
  String get vstTaxRate => 'Tarif PPN';

  @override
  String get vstEnableService => 'Aktifkan layanan';

  @override
  String get vstServiceRate => 'Tarif layanan';

  @override
  String get vstServiceAmount => 'Jumlah layanan';

  @override
  String get vstTaxAfterDiscount => 'Pajak dihitung setelah diskon';

  @override
  String get vstTaxAfterDiscountOn =>
      'Diskon mengurangi dasar pengenaan — pajak & layanan dihitung dari jumlah setelah diskon.';

  @override
  String get vstTaxAfterDiscountOff =>
      'Pajak & layanan dihitung dari subtotal kotor, diskon dipotong dari total akhir.';

  @override
  String get vstItemDiscountNote =>
      'Diskon per item selalu dihitung sebelum pajak.';

  @override
  String get vstDiscountPresets => 'Preset diskon';

  @override
  String get vstFeeType => 'Tipe biaya';

  @override
  String get vstFeePercent => 'Persen';

  @override
  String get vstFeeFixed => 'Tetap';

  @override
  String get vstReportsTag => 'LAPORAN';

  @override
  String get vstBusinessDayStart => 'Jam mulai hari kerja';

  @override
  String get vstBusinessDayStartHint => 'Pengelompokan laporan \"Hari ini\"';

  @override
  String get tkwFallbackLabel => 'Bawa pulang';

  @override
  String tkwItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ITEM',
    );
    return '$_temp0';
  }

  @override
  String get tkwHandedOverTag => 'SUDAH DISERAHKAN';

  @override
  String get tkwEmpty => 'Belum ada item.';

  @override
  String tkwServeFailed(String error) {
    return 'Gagal sajikan: $error';
  }

  @override
  String tkwBillLoadFailed(String error) {
    return 'Gagal memuat tagihan: $error';
  }

  @override
  String get tkwErrNotTerminal =>
      'Masih ada item yang dimasak — tunggu siap dulu.';

  @override
  String get tkwErrNoTickets => 'Belum ada item untuk diserahkan.';

  @override
  String tkwHandoverFailed(String error) {
    return 'Gagal menyerahkan: $error';
  }

  @override
  String get tkwHandover => 'Serahkan';

  @override
  String get tkwHandoverBlocked =>
      'Bisa diserahkan setelah semua item siap/disajikan.';

  @override
  String get tkwHandedOver => 'Sudah diserahkan ke tamu.';

  @override
  String mvtTitle(String table) {
    return 'Pindahkan meja $table';
  }

  @override
  String mvtSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pilih meja kosong tujuan · $count tamu',
    );
    return '$_temp0';
  }

  @override
  String get mvtNoTargets => 'Tidak ada meja kosong untuk dituju.';

  @override
  String tblCapacityOf(int count) {
    return 'kapasitas $count';
  }

  @override
  String mvtConfirmTitle(String table) {
    return 'Pindahkan meja $table?';
  }

  @override
  String mvtConfirmOver(String table, int capacity, int pax) {
    String _temp0 = intl.Intl.pluralLogic(
      pax,
      locale: localeName,
      other: '$pax tamu',
    );
    return 'Tujuan: meja $table (kapasitas $capacity). $_temp0 melebihi kapasitas — lanjutkan?';
  }

  @override
  String mvtConfirmBody(String table) {
    return 'Seluruh pesanan dan tamu pindah ke meja $table.';
  }

  @override
  String get mvtConfirmAction => 'Pindahkan';

  @override
  String mvtFailed(String error) {
    return 'Gagal memindahkan meja: $error';
  }

  @override
  String get asgTitle => 'Tetapkan ke meja';

  @override
  String get asgSubtitle => 'Atur tamu lalu pilih meja kosong';

  @override
  String get asgGuestNameHint => 'Nama tamu (opsional)';

  @override
  String get asgNoTargets => 'Tidak ada meja kosong.';

  @override
  String gstTableLabel(String table) {
    return 'Meja $table';
  }

  @override
  String get gstTitle => 'Atur jumlah tamu';

  @override
  String get gstWaiterOnly => 'Hanya pelayan yang bisa mengubah jumlah tamu.';

  @override
  String kitQueueSub(int orders, int items) {
    return '$orders ORDER · $items ITEM DI ANTRIAN PERSIAPAN';
  }

  @override
  String get kitShowDone => 'Tampilkan order selesai';

  @override
  String kitSentAt(String time) {
    return 'masuk $time';
  }

  @override
  String get kitAllReady => 'Semua siap';

  @override
  String kitReadyOf(int done, int total) {
    return '$done/$total siap';
  }

  @override
  String get kitHoldToFinish => 'Tahan untuk tandai selesai';

  @override
  String get kitEmptyTitle => 'Antrian masak kosong';

  @override
  String get kitEmptyBody => 'Semua pesanan dapur sudah selesai dimasak.';

  @override
  String liaTableAt(String table, String time) {
    return 'MEJA $table · $time';
  }

  @override
  String get liaTapOutside => 'Tap luar sheet untuk batal.';

  @override
  String get liaVoidWarning =>
      'Pembatalan dicatat dengan sign-in kamu dan alasannya — terlihat di laporan dan catatan audit.';

  @override
  String get liaVoided => 'Item dibatalkan';

  @override
  String liaVoidedNote(int qty, String name) {
    return 'Tercatat: ×$qty $name · atas nama kamu · terlihat di laporan';
  }

  @override
  String resDaySummary(String day, int bookings, int covers) {
    String _temp0 = intl.Intl.pluralLogic(
      bookings,
      locale: localeName,
      other: '$bookings booking',
    );
    String _temp1 = intl.Intl.pluralLogic(
      covers,
      locale: localeName,
      other: '$covers tamu',
    );
    return '$day · $_temp0 · $_temp1';
  }

  @override
  String resNoTableForParty(int size) {
    return 'Tidak ada meja kapasitas ≥ $size di zona ini.';
  }

  @override
  String get resAlreadySeated => 'Meja sudah diisi tamu lain';

  @override
  String resSeatFailed(String error) {
    return 'Gagal duduk: $error';
  }

  @override
  String get resNewBooking => 'Reservasi baru';

  @override
  String get resGuestName => 'Nama tamu';

  @override
  String get resPhone => 'No. HP';

  @override
  String get resOptional => 'opsional';

  @override
  String get resPartySize => 'Jumlah tamu';

  @override
  String resSaveFailed(String error) {
    return 'Gagal simpan: $error';
  }

  @override
  String get prnPick => 'Pilih printer';

  @override
  String get prnNoneOnline =>
      'Tidak ada printer online. Tambah manual, atau pair printer Bluetooth di Pengaturan dulu.';

  @override
  String get prnAddWifi => 'Tambah printer Wi-Fi';

  @override
  String get prnLabel => 'Label';

  @override
  String get prnHost => 'Host (IP)';

  @override
  String get prnPort => 'Port';

  @override
  String get prnScopeVenue => 'Venue';

  @override
  String get prnScopeDevice => 'Alat ini';

  @override
  String get dscNoPresetsTitle => 'Belum ada preset diskon';

  @override
  String get dscNoPresetsLine =>
      'Belum ada preset diskon per item. Tambahkan di Pengaturan venue › Diskon.';

  @override
  String get dscNoPresetsBill =>
      'Belum ada preset diskon tagihan. Tambahkan di Pengaturan venue › Diskon.';

  @override
  String get dscNoPresetsReceipt =>
      'Belum ada preset diskon per pesanan. Tambahkan di Pengaturan venue › Diskon.';

  @override
  String dscSheetTitle(String target) {
    return 'Diskon · $target';
  }

  @override
  String get dscApproverTitle => 'Persetujuan manajer';

  @override
  String get dscApproverBody =>
      'Diskon perlu disetujui manajer. Minta manajer memasukkan PIN.';

  @override
  String get dscAppliesLine => 'Berlaku untuk item ini';

  @override
  String get dscAppliesBill => 'Berlaku seluruh tagihan · semua struk';

  @override
  String get dscAppliesReceipt => 'Berlaku seluruh struk';

  @override
  String ordServeFailed(String error) {
    return 'Gagal sajikan: $error';
  }

  @override
  String ordSummary(int active, int ready) {
    return '$active berjalan · $ready siap diambil';
  }

  @override
  String get ordUnderMin => '<1m';

  @override
  String ordSince(String time) {
    return 'sejak $time';
  }

  @override
  String get cshTitle => 'Kasir';

  @override
  String cshSummary(int running, int takeaway, int settled) {
    String _temp0 = intl.Intl.pluralLogic(
      running,
      locale: localeName,
      other: '$running tagihan',
    );
    return '$_temp0 berjalan · $takeaway tanpa meja · $settled lunas';
  }

  @override
  String get cshUnbilled => 'Belum tertagih';

  @override
  String rtoReadyAtPass(String what) {
    return 'Siap di pass · $what';
  }

  @override
  String get rtoPickUp => 'Ambil';

  @override
  String get crsTitle => 'RENTANG KHUSUS';

  @override
  String get crsFrom => 'Mulai';

  @override
  String get crsTo => 'Selesai';

  @override
  String get crsApply => 'Terapkan';

  @override
  String get exitAgainToQuit => 'Tekan kembali lagi untuk keluar';

  @override
  String olcVoidedBy(String reason, String approver) {
    return 'Dibatalkan · $reason · disetujui oleh $approver';
  }

  @override
  String get rdyBannerText =>
      'Item siap diambil di pass — tandai disajikan di bawah';

  @override
  String get ppfTitle => 'Bukti pembayaran';

  @override
  String get ppfUnavailable => 'Foto bukti tidak bisa dimuat';

  @override
  String get cpdTitle => 'Uang tamu · ketuk pecahan';

  @override
  String blcPaidPct(String amount, String pct) {
    return '$amount masuk · $pct%';
  }

  @override
  String get tblDetailEmptyLines =>
      'Belum ada item — ketuk Tambah pesanan di kanan untuk mulai.';

  @override
  String tblNoTablesInZone(String zone) {
    return 'Belum ada meja di $zone';
  }

  @override
  String get ownMoneyAuditTitle => 'Catatan uang';

  @override
  String get ownMoneyAuditEmpty =>
      'Tidak ada aktivitas yang menyentuh uang pada rentang ini.';

  @override
  String ownMoneyAuditTruncated(int count) {
    return 'Menampilkan $count terbaru — catatan lengkap ada di perangkat venue';
  }

  @override
  String get ownReportTitle => 'Laporan Venue';

  @override
  String altMinutes(int value) {
    return '$value min';
  }

  @override
  String get vhbSettings => 'Pengaturan';

  @override
  String mnaItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get cmnStationsLive => 'STATIONS · LIVE';

  @override
  String modSpecialCounter(int used) {
    return '$used / 80 · tampil ke dapur';
  }

  @override
  String zonSeatsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kursi',
    );
    return '$_temp0';
  }

  @override
  String zonTablesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meja',
    );
    return '$_temp0';
  }

  @override
  String stfPinIs(String pin) {
    return 'PIN $pin';
  }

  @override
  String get onbPickMode => 'Pilih mode';

  @override
  String get onbPickModeSub => 'Tablet ini akan jadi server atau klien?';

  @override
  String get fbdNoAccess => 'Akses tidak diizinkan';

  @override
  String get rptLoadFailed => 'Gagal memuat laporan';

  @override
  String rptStockFailed(String error) {
    return 'Gagal memuat laporan bahan: $error';
  }

  @override
  String get rptStockEmpty => 'Belum ada aktivitas bahan pada rentang ini.';

  @override
  String get fltLoadFailed => 'Gagal memuat fleet';

  @override
  String get fltNewVenue => 'Venue baru';

  @override
  String get fltOfflineNote =>
      'Tidak terhubung — data tersimpan, bisa sudah berubah. Perubahan dinonaktifkan sampai tersambung.';

  @override
  String get sntTitle => 'Terkirim';

  @override
  String sntBody(String table) {
    return 'Pesanan Meja $table sudah live di display dapur dan bar.';
  }

  @override
  String sntLatency(String ms) {
    return 'LAN P50 ${ms}MS · CLOUD QUEUED';
  }

  @override
  String meShiftLine(String start, String elapsed) {
    return 'MULAI $start · $elapsed BERJALAN';
  }

  @override
  String get meAuditEmpty =>
      'Belum ada entri audit. Pembatalan, comp, dan perubahan pasca-kirim muncul di sini.';

  @override
  String meAuditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entri',
    );
    return '$_temp0';
  }

  @override
  String get meRecentActivity => 'Aktivitas terkini';

  @override
  String get pinDebugSeeded => 'DEBUG · SEEDED PINS';

  @override
  String pinCopied(String label) {
    return 'Disalin: $label';
  }

  @override
  String get fveLapsedNote =>
      'Langganan sudah lewat batas. Perpanjang dulu di bawah sebelum venue bisa diaktifkan.';

  @override
  String fveManyAdmins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count admin aktif',
    );
    return 'Venue ini punya $_temp0. Satu venue kini hanya boleh punya satu admin aktif — tangguhkan yang lain, sisakan akun di perangkat yang memegang data venue. Admin yang tersisa aktif tidak akan bisa masuk.';
  }

  @override
  String fveLoadFailed(String error) {
    return 'Gagal memuat: $error';
  }

  @override
  String get fveAtCapNote =>
      'Satu venue, satu admin aktif. Untuk mengganti admin: tangguhkan yang lama dulu, lalu tambah yang baru.';

  @override
  String get fveDangerZone => 'ZONA BAHAYA';

  @override
  String get fveDeleteBlocked =>
      'Hapus semua akun venue ini dulu sebelum menghapus venue. Untuk sekadar memutus akses, pakai Tangguhkan di atas.';

  @override
  String get fveDeleteWarning =>
      'Menghapus venue tidak dapat dibatalkan. Untuk sekadar memutus akses, pakai Tangguhkan di atas.';

  @override
  String get fveAnnual => 'Bayar tahunan';

  @override
  String get fveAnnualNoPrice => 'Hemat 2 bulan — isi harga bulanan dulu.';

  @override
  String fveAnnualPrice(String amount) {
    return '$amount per tahun — hemat 2 bulan.';
  }

  @override
  String get fveNoCutoff =>
      'Tanpa tanggal, langganan tidak pernah habis dan venue tidak ditangguhkan otomatis.';

  @override
  String fveAddPrincipal(String role, String venue) {
    return 'Tambah $role · $venue';
  }

  @override
  String get rtoNow => 'SEKARANG';

  @override
  String rtoTableNow(String table, String zone) {
    return 'MEJA $table · $zone · SEKARANG';
  }

  @override
  String get olcMarkServed => 'Tandai disajikan';

  @override
  String get dscManagerPin => 'PIN manajer';

  @override
  String get dscApprove => 'Setujui';

  @override
  String get cpdExact => 'Pas';

  @override
  String get cpdClear => 'Kosongkan';

  @override
  String cpdNoteSemantics(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lembar',
    );
    return '$label, $_temp0';
  }

  @override
  String get cpdReceived => 'Diterima';

  @override
  String get cpdShort => 'Masih kurang';

  @override
  String get cpdChange => 'Kembalian';

  @override
  String get blcNoName => 'Tanpa nama';

  @override
  String blcPaxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tamu',
    );
    return '$_temp0';
  }

  @override
  String get blcCaptionPaid => 'total dibayar';

  @override
  String get blcCaptionOutstanding => 'sisa tagihan';

  @override
  String get blcCaptionWriteOff => 'tak tertagih';

  @override
  String get blcVerbIn => 'masuk';

  @override
  String get blcVerbSeated => 'duduk';

  @override
  String get blcVerbClosed => 'tutup';

  @override
  String get blcSeeReceipt => 'Lihat struk';

  @override
  String get blcCharge => 'Tagih';

  @override
  String get blcPillSettled => 'Lunas';

  @override
  String get blcPillPartial => 'Sebagian';

  @override
  String get blcPillWriteOff => 'Tak tertagih';

  @override
  String get blcPillUnpaid => 'belum bayar';

  @override
  String blcSemantics(String label, String state, String amount) {
    return '$label, $state, $amount';
  }

  @override
  String blcSinceChip(String verb, String elapsed) {
    return '$verb $elapsed';
  }

  @override
  String get blcTableClosed => 'Meja ditutup';

  @override
  String blcEvenSplit(int shares, int paid) {
    return 'Bagi $shares · $paid bayar';
  }

  @override
  String get blcPrepaid => 'Prabayar aplikasi';

  @override
  String get cshLoadFailedTitle => 'Gagal memuat tagihan';

  @override
  String get cshPullToRetry => 'Tarik untuk coba lagi.';

  @override
  String get cshEmptyDetached => 'Tidak ada meja tertutup yang belum lunas';

  @override
  String get cshEmptyOpen => 'Tidak ada tagihan terbuka';

  @override
  String get cshEmptySettledToday => 'Belum ada tagihan lunas hari ini';

  @override
  String get cshEmptySettled7d => 'Belum ada tagihan lunas 7 hari terakhir';

  @override
  String get cshEmptyAll => 'Belum ada tagihan';

  @override
  String get cshStatUnpaid => 'Belum bayar';

  @override
  String get cshStatPartial => 'Sebagian';

  @override
  String get cshStatReceived => 'Sudah diterima';

  @override
  String get cshStatClosed => 'Meja ditutup';

  @override
  String get cshSegNeedCharge => 'Perlu ditagih';

  @override
  String get cshSegSettled => 'Lunas';

  @override
  String get cshSegAll => 'Semua';

  @override
  String get cshRangeToday => 'Hari ini';

  @override
  String get cshRange7d => '7 hari';

  @override
  String get fltActive => 'AKTIF';

  @override
  String get fltSuspended => 'TANGGUH';

  @override
  String get fltConsoleTitle => 'Fleet';

  @override
  String get fltSearchHint => 'Cari nama atau alamat';

  @override
  String get fltEmptyNoVenue => 'Belum ada venue';

  @override
  String get fltEmptyNoMatch => 'Tidak ada yang cocok';

  @override
  String get fltVenueActions => 'Tindakan venue';

  @override
  String get fltVenueName => 'Nama venue';

  @override
  String get fltVenueAdmin => 'Admin venue';

  @override
  String get fltOwner => 'Pemilik';

  @override
  String get fltVenueAccess => 'Akses venue';

  @override
  String get fltSuspend => 'Tangguhkan';

  @override
  String get fltSubscription => 'Langganan';

  @override
  String get fltStartTrial => 'Mulai coba';

  @override
  String get fltPricePerMonth => 'Harga per bulan';

  @override
  String get fltAccountActions => 'Tindakan akun';

  @override
  String get fltSendWa => 'Kirim WA';

  @override
  String get fltDeleteVenue => 'Hapus venue';

  @override
  String get fltClearDate => 'Hapus tanggal';

  @override
  String get fltPickDate => 'Pilih';

  @override
  String get fltInitialPassword => 'Password awal';

  @override
  String get ordReadyForPickup => 'Siap diambil';

  @override
  String get ordPreparing => 'Disiapkan';

  @override
  String get ordDone => 'Selesai';

  @override
  String get ordTabMine => 'Milik saya';

  @override
  String get ordServe => 'Sajikan';

  @override
  String get meKpiOpenTickets => 'Tiket terbuka';

  @override
  String get meKpiCovers => 'Cover dilayani';

  @override
  String get meEndShiftAndLogout => 'Akhiri shift & keluar';

  @override
  String get liaFireNow => 'Bakar sekarang';

  @override
  String get liaEditItem => 'Ubah item';

  @override
  String get liaUnserve => 'Batalkan sajian';

  @override
  String get liaVoidItem => 'Batalkan item';

  @override
  String get liaVoidReasonHint => 'Wajib — jelaskan alasan pembatalan';

  @override
  String get fltEmptyNoVenueBody =>
      'Buat venue pertama dengan \"Venue baru\", lalu tambahkan admin-nya dari dalam venue itu.';

  @override
  String fltEmptyLensBody(String lens) {
    return 'Tidak ada venue di lensa \"$lens\".';
  }

  @override
  String fltEmptyQueryBody(String query) {
    return 'Tidak ada venue cocok \"$query\".';
  }

  @override
  String fltEmptyQueryLensBody(String query, String lens) {
    return 'Tidak ada venue cocok \"$query\" di lensa \"$lens\".';
  }

  @override
  String get fltLensTrouble => 'Perlu tindakan';

  @override
  String get fltLensBilling => 'Tagihan';

  @override
  String get fltLensOff => 'Nonaktif';

  @override
  String get fltKicker => 'FLEET';

  @override
  String fltOnlineOf(int live, int total) {
    return '$live DARI $total ONLINE';
  }

  @override
  String get resSaveBooking => 'Simpan reservasi';

  @override
  String get stfRoleActive => 'aktif';

  @override
  String stfRoleLockedSemantics(String role, String cap, String state) {
    return '$role, $cap, $state, terkunci';
  }

  @override
  String stfRoleSemantics(String role, String cap) {
    return '$role, $cap';
  }

  @override
  String get mnaAddItemShort => '+ Item';

  @override
  String get mnaAddCategory => '+ Tambah kategori';

  @override
  String mnaAddThing(String thing) {
    return '+ Tambah $thing';
  }

  @override
  String zonAdminSub(int tables, int zones, int seats) {
    String _temp0 = intl.Intl.pluralLogic(
      tables,
      locale: localeName,
      other: '$tables meja',
    );
    String _temp1 = intl.Intl.pluralLogic(
      zones,
      locale: localeName,
      other: '$zones zona',
    );
    String _temp2 = intl.Intl.pluralLogic(
      seats,
      locale: localeName,
      other: '$seats kursi',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String venueHubTablesZones(int tables, int zones) {
    String _temp0 = intl.Intl.pluralLogic(
      tables,
      locale: localeName,
      other: '$tables meja',
    );
    String _temp1 = intl.Intl.pluralLogic(
      zones,
      locale: localeName,
      other: '$zones zona)',
    );
    return '$_temp0 ($_temp1';
  }

  @override
  String venueHubMenuItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item menu',
    );
    return '$_temp0';
  }

  @override
  String venueHubStaffCount(int count) {
    return '$count staf';
  }

  @override
  String get onbModeServer => 'Server';

  @override
  String get onbModeServerSub =>
      'Tablet ini host venue. Database lokal di sini.';

  @override
  String get onbModeClient => 'Klien';

  @override
  String get onbModeClientSub =>
      'Tablet ini ambil order, terhubung ke server lewat LAN.';

  @override
  String get modSize => 'Ukuran';

  @override
  String get modNoteHint => 'mis. alergi belum tertera, catatan plating…';

  @override
  String venueHubStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bahan',
    );
    return '$_temp0';
  }

  @override
  String venueHubStockLow(int count, int low) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bahan',
    );
    return '$_temp0 ($low low)';
  }

  @override
  String get alertsSoundHint =>
      'Pilih nada untuk tiap kejadian. Pilihan ini berlaku untuk semua perangkat di venue.';

  @override
  String kitchenQueueSub(int orders, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      orders,
      locale: localeName,
      other: '$orders order aktif',
    );
    String _temp1 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items item',
    );
    return '$_temp0 · $_temp1 · tahan untuk tandai selesai';
  }

  @override
  String modDietaryLine(String tags) {
    return 'Cocok untuk $tags';
  }

  @override
  String modAllergenLine(String tags) {
    return 'Mengandung $tags — konfirmasi ke tamu';
  }

  @override
  String rptSubNet(int sessions, int covers) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions sesi',
    );
    String _temp1 = intl.Intl.pluralLogic(
      covers,
      locale: localeName,
      other: '$covers tamu',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String rptSubGross(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transaksi',
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
      other: '$count item void',
    );
    return '$_temp0';
  }

  @override
  String get rptSubTurnTime => 'Lama tamu duduk';

  @override
  String get rptSubPrep => 'Median kirim → siap';

  @override
  String get rptSubPickup => 'Median siap → disajikan';

  @override
  String rptSubReservations(int noShow, int cancelled) {
    return '$noShow no-show · $cancelled batal';
  }

  @override
  String get rptStationKitchen => 'Dapur Utama';

  @override
  String get rptUnknownStaff => 'Tidak diketahui';

  @override
  String get vrsWrongOrder => 'Terkirim salah';

  @override
  String get vrsWrongOrderDesc => 'Salah meja, tap ganda, salah ring';

  @override
  String get vrsCustomerChange => 'Tamu berubah pikiran';

  @override
  String get vrsCustomerChangeDesc => 'Tamu batalkan permintaan';

  @override
  String get vrsOutOfStock => 'Stok habis';

  @override
  String get vrsOutOfStockDesc => 'Item habis di stasiun';

  @override
  String get vrsKitchenError => 'Komplain / kualitas dapur';

  @override
  String get vrsKitchenErrorDesc =>
      'Masalah kualitas — item ditarik dari tagihan';

  @override
  String get vrsComp => 'Kompensasi manajer';

  @override
  String get vrsOther => 'Lainnya';

  @override
  String get vrsOtherDesc => 'Alasan bebas wajib diisi';

  @override
  String get modGroupSpice => 'Tingkat pedas';

  @override
  String get modGroupExtras => 'Tambahan';

  @override
  String get modGroupSauce => 'Saus';

  @override
  String get modGroupProtein => 'Pilih protein';

  @override
  String get vrsCompDesc =>
      'Digratiskan untuk tamu · tercatat terpisah dari pembatalan';

  @override
  String get authServerTrouble => 'Server lagi bermasalah. Coba lagi sebentar.';

  @override
  String get authWrongPin => 'PIN salah. Coba lagi.';

  @override
  String get authWrongCredentials => 'Email atau password salah.';

  @override
  String get authNoConnection =>
      'Gagal terhubung ke server. Cek Wi-Fi lalu coba lagi.';

  @override
  String get authInvalidEmail => 'Email tidak valid.';

  @override
  String get authAccountDisabled => 'Akun admin dinonaktifkan.';

  @override
  String get authTooManyAttempts =>
      'Terlalu banyak percobaan. Coba lagi nanti.';

  @override
  String get authFirstLoginNeedsInternet =>
      'Gagal terhubung. Login admin pertama butuh internet.';

  @override
  String get authAdminLoginFailed => 'Login admin gagal. Coba lagi.';

  @override
  String get prnErrNoLines => 'Tidak ada pesanan untuk dicetak';

  @override
  String get prnErrNotConnected => 'Printer tak terhubung';

  @override
  String get prnErrNoPrinter => 'Printer tidak ditemukan';

  @override
  String get prnErrFailed => 'Gagal mencetak';

  @override
  String prnErrFailedCode(String code) {
    return 'Gagal mencetak ($code).';
  }

  @override
  String get authServerNotReadyWait =>
      'Server belum siap. Tunggu sebentar lalu coba lagi.';

  @override
  String get authServerNotReady => 'Server belum siap. Coba lagi.';

  @override
  String get authAdminNotRegistered =>
      'Akun admin belum terdaftar. Hubungi pengelola.';

  @override
  String get authAdminSuspended =>
      'Akun admin ditangguhkan. Hubungi pengelola.';

  @override
  String get authAdminInactive => 'Akun admin tidak aktif.';

  @override
  String get authNoVenueAssigned =>
      'Akun belum ditugaskan ke venue. Hubungi pengelola.';

  @override
  String get authVenueNotFound => 'Venue tidak ditemukan. Hubungi pengelola.';

  @override
  String get authVenueSuspended => 'Venue ditangguhkan. Hubungi pengelola.';

  @override
  String get authVenueInactive => 'Venue tidak aktif.';

  @override
  String get tktOutOfStock => 'bahan habis';

  @override
  String tktOutOfStockNamed(String names) {
    return 'bahan habis: $names';
  }

  @override
  String tktNotSent(String what, String why) {
    return '$what tidak dikirim — $why';
  }

  @override
  String get auditLoadFailed => 'Gagal memuat audit';

  @override
  String get capTakeOrder => 'Ambil pesanan';

  @override
  String get capModifyOrder => 'Ubah pesanan';

  @override
  String get capVoidItem => 'Batalkan item';

  @override
  String get capCompItem => 'Gratiskan item';

  @override
  String get capViewKds => 'Lihat KDS';

  @override
  String get capOpenDrawer => 'Buka laci';

  @override
  String get capApplyDiscount => 'Beri diskon';

  @override
  String get capSettleBill => 'Tutup tagihan';

  @override
  String get capRefund => 'Refund';

  @override
  String get capManageCash => 'Kelola kas kecil';

  @override
  String get cashCatIngredients => 'Belanja bahan';

  @override
  String get cashCatOperations => 'Operasional';

  @override
  String get cashCatTransport => 'Transport';

  @override
  String get cashCatDailyWage => 'Upah harian';

  @override
  String get cashCatOther => 'Lainnya';

  @override
  String get cashKindTopUp => 'Isi kas';

  @override
  String get cashKindExpense => 'Pengeluaran';

  @override
  String get cashKindCount => 'Opname';

  @override
  String get cashKindReversal => 'Pembatalan';

  @override
  String get kasTitle => 'Kas kecil';

  @override
  String get kasHubSubtitle => 'Saldo, pengeluaran, opname';

  @override
  String get kasBalance => 'Saldo kas';

  @override
  String kasLastCount(String when) {
    return 'Opname terakhir $when';
  }

  @override
  String get kasNeverCounted => 'Belum pernah diopname';

  @override
  String get kasEmptyTitle => 'Kas kecil masih kosong';

  @override
  String get kasEmptyBody => 'Isi kas dulu, baru pengeluaran bisa dicatat.';

  @override
  String get kasActionTopUp => 'Isi kas';

  @override
  String get kasActionExpense => 'Pengeluaran';

  @override
  String get kasActionCount => 'Opname';

  @override
  String get kasSheetTopUpTitle => 'Isi kas kecil';

  @override
  String get kasSheetExpenseTitle => 'Pengeluaran kas';

  @override
  String get kasSheetCountTitle => 'Opname kas';

  @override
  String get kasFieldAmount => 'Jumlah';

  @override
  String get kasFieldCounted => 'Uang yang ada di kotak';

  @override
  String get kasFieldNote => 'Catatan';

  @override
  String get kasFieldReason => 'Alasan';

  @override
  String get kasFieldCategory => 'Kategori';

  @override
  String get kasPhotoAdd => 'Foto nota';

  @override
  String kasLedgerSays(String amount) {
    return 'Catatan kas: $amount';
  }

  @override
  String kasVariance(String amount) {
    return 'Selisih $amount';
  }

  @override
  String get kasDetailTitle => 'Mutasi kas';

  @override
  String kasCounted(String amount) {
    return 'Terhitung $amount';
  }

  @override
  String get kasReverse => 'Batalkan mutasi';

  @override
  String get kasReverseTitle => 'Batalkan mutasi kas';

  @override
  String get kasReverseBody =>
      'Baris ini tetap ada; pembatalan dicatat sebagai mutasi baru.';

  @override
  String get kasReversed => 'Sudah dibatalkan';

  @override
  String get kasIsReversal => 'Membatalkan mutasi sebelumnya';

  @override
  String get kasActorUnknown => 'Sistem';

  @override
  String kasBy(String name) {
    return 'oleh $name';
  }

  @override
  String kasErrInsufficient(String amount) {
    return 'Saldo kas cuma $amount';
  }

  @override
  String get kasErrReasonRequired => 'Alasan wajib diisi';

  @override
  String get kasErrAlreadyReversed => 'Mutasi ini sudah dibatalkan';

  @override
  String get kasErrNotReversible => 'Pembatalan tidak bisa dibatalkan lagi';

  @override
  String get kasErrInvalidAmount => 'Jumlah tidak sah';

  @override
  String kasErrFailed(String code) {
    return 'Gagal menyimpan ($code)';
  }

  @override
  String get kasPhoneOnly => 'Kas kecil dibaca di tablet.';

  @override
  String get rptSecKas => 'Kas kecil';

  @override
  String get rptKasOpening => 'Saldo awal';

  @override
  String get rptKasIn => 'Masuk';

  @override
  String get rptKasOut => 'Keluar';

  @override
  String get rptKasVariance => 'Selisih opname';

  @override
  String get rptKasClosing => 'Saldo akhir';

  @override
  String get rptKasByCategory => 'Pengeluaran per kategori';

  @override
  String get rptKasEmpty => 'Tidak ada mutasi kas di rentang ini.';

  @override
  String get capCloseShift => 'Tutup shift';

  @override
  String get capEditMenu => 'Ubah menu';

  @override
  String get capMarkSoldOut => 'Tandai habis';

  @override
  String get capAdjustStock => 'Sesuaikan stok';

  @override
  String get capManageIngredients => 'Kelola bahan';

  @override
  String get capOverrideStock => 'Jual saat stok habis';

  @override
  String get capManageStaff => 'Kelola staf';

  @override
  String get capManageRoles => 'Kelola peran';

  @override
  String get capViewReports => 'Lihat laporan';

  @override
  String get capEditSettings => 'Ubah pengaturan';

  @override
  String get capTakeOrderDesc => 'Buat pesanan baru dan kirim ke dapur.';

  @override
  String get capModifyOrderDesc =>
      'Ubah jumlah atau catatan pada pesanan yang belum dimasak.';

  @override
  String get capVoidItemDesc => 'Hapus item terkirim sebelum disajikan.';

  @override
  String get capCompItemDesc => 'Nolkan harga item yang sudah disajikan.';

  @override
  String get capViewKdsDesc => 'Buka antrian persiapan dapur.';

  @override
  String get capOpenDrawerDesc => 'Buka laci kas tanpa transaksi.';

  @override
  String get capApplyDiscountDesc => 'Potong harga pada tagihan.';

  @override
  String get capSettleBillDesc => 'Terima pembayaran dan tutup tagihan.';

  @override
  String get capRefundDesc =>
      'Kembalikan uang atas tagihan yang sudah dibayar.';

  @override
  String get capCloseShiftDesc => 'Akhiri shift dan hitung kas.';

  @override
  String get capManageCashDesc =>
      'Catat pengeluaran dari kas kecil. Mengisi dan mengopname kas butuh izin pengaturan.';

  @override
  String get capEditMenuDesc =>
      'Tambah, ubah, dan hapus item serta kategori menu.';

  @override
  String get capMarkSoldOutDesc =>
      'Tandai item habis tanpa mengubah stok bahan.';

  @override
  String get capAdjustStockDesc =>
      'Catat opname, terima barang, dan buang bahan.';

  @override
  String get capManageIngredientsDesc =>
      'Tambah dan ubah bahan beserta resepnya.';

  @override
  String get capOverrideStockDesc =>
      'Kirim pesanan meski bahan tercatat habis.';

  @override
  String get capManageStaffDesc =>
      'Tambah staf, atur peran, dan setel ulang PIN.';

  @override
  String get capManageRolesDesc => 'Buat peran dan atur izin yang dibawanya.';

  @override
  String get capViewReportsDesc => 'Buka laporan penjualan dan jejak audit.';

  @override
  String get capEditSettingsDesc =>
      'Ubah pengaturan venue, waktu, dan peringatan.';

  @override
  String get capGrpOrders => 'Pesanan';

  @override
  String get capGrpMoney => 'Uang';

  @override
  String get capGrpInventory => 'Menu & stok';

  @override
  String get capGrpAdmin => 'Admin';

  @override
  String get capGrpKitchen => 'Dapur';

  @override
  String get agbLockedOnRestart =>
      'Server akan terkunci saat aplikasi dimulai ulang — sambungkan internet sekarang untuk verifikasi admin.';

  @override
  String agbLockedInHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours jam.',
    );
    return 'Tanpa internet, server terkunci dalam $_temp0 Segera sambungkan.';
  }

  @override
  String agbLockedInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days hari.',
    );
    return 'Tanpa internet, server terkunci dalam $_temp0 Sambungkan untuk verifikasi admin.';
  }

  @override
  String get crsStartBeforeEnd =>
      'Tanggal mulai harus sebelum tanggal selesai.';

  @override
  String crsMaxSpan(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days hari.',
    );
    return 'Rentang maksimal $_temp0';
  }

  @override
  String get pinPickServerFirst => 'Pilih server dulu.';

  @override
  String get pinDeviceNotPaired =>
      'HP belum tersambung. Scan QR lagi untuk pasangkan.';

  @override
  String get pinSetupFailed => 'Gagal menyiapkan aplikasi. Coba lagi.';

  @override
  String get pinServerBootFailed =>
      'Gagal menjalankan server di HP ini. Coba lagi.';

  @override
  String pinAutoClaimFailed(String error) {
    return 'Sambung otomatis gagal: $error';
  }

  @override
  String get prnNothingToPrint => 'Tidak ada pesanan untuk dicetak';

  @override
  String get prnThisDevice => 'Alat ini';

  @override
  String get prnEnableBluetooth =>
      'Nyalakan Bluetooth di Pengaturan lalu coba lagi';

  @override
  String get prnReceiptPrinted => 'Struk tercetak';

  @override
  String get rptStockValue => 'Nilai stok';

  @override
  String get rptStockValueNow => 'Nilai stok saat ini';

  @override
  String get rptNoStocktake => 'Belum ada opname pada rentang ini.';

  @override
  String get rptAllWaiters => 'Semua pelayan';

  @override
  String get rptAllZones => 'Semua zona';

  @override
  String get rptAllCategories => 'Semua kategori';

  @override
  String alertsThresholdLine(int prep, int ungreeted) {
    return 'Siap ${prep}m · belum dilayani ${ungreeted}m';
  }

  @override
  String get venueHubShiftReport => 'Laporan shift';

  @override
  String get auditExportFailed => 'Gagal mengekspor audit';

  @override
  String get killReasonOutOfStock => 'Bahan habis';

  @override
  String get killReasonQuality => 'Kualitas tidak layak';

  @override
  String get rcpVenueNamePlaceholder => 'NAMA VENUE';

  @override
  String get rcpSplitReceipt => 'STRUK BAGIAN';

  @override
  String get ordEmptyPass => 'Belum ada yang siap di pass.';

  @override
  String get ordEmptyPreparingAll => 'Tidak ada item yang sedang disiapkan.';

  @override
  String get ordEmptyPreparingMine =>
      'Tidak ada item Anda yang sedang disiapkan.\nPilih Semua untuk melihat seluruh venue.';

  @override
  String get ordEmptyDoneAll => 'Belum ada item yang selesai pada sesi ini.';

  @override
  String get ordEmptyDoneMine =>
      'Belum ada item Anda yang selesai pada sesi ini.\nPilih Semua untuk melihat seluruh venue.';

  @override
  String get rptStockWaste => 'Terbuang';

  @override
  String get rptStockVariance => 'Selisih opname';

  @override
  String get rptStockUsage => 'Pemakaian';

  @override
  String get prnEnableBluetoothTitle => 'Nyalakan Bluetooth';

  @override
  String get killReasonBrokenEquipment => 'Alat rusak';

  @override
  String get killReasonTooSlow => 'Terlalu lama';

  @override
  String tblOccupiedOf(int occupied, int total) {
    return '$occupied dari $total terisi';
  }

  @override
  String tblOpenTab(String amount) {
    return 'tab $amount';
  }

  @override
  String get tcStatusReserved => 'Dipesan';

  @override
  String get tcStatusAvailable => 'Kosong';

  @override
  String get tcStatusOccupied => 'Terisi';

  @override
  String get tcStatusPending => 'Pesanan masuk';

  @override
  String tcStatusReady(int n) {
    return 'Siap ×$n';
  }

  @override
  String get mvtTargetOccupied => 'Meja tujuan sudah terisi.';

  @override
  String get mvtTableLocked => 'Meja sedang dipakai pengguna lain.';

  @override
  String get mvtSourceEmpty => 'Meja asal sudah kosong.';

  @override
  String get modTagRequired => 'WAJIB';

  @override
  String get modTagFree => 'BEBAS PILIH';

  @override
  String get modTagOptional => 'OPSIONAL';

  @override
  String get modPickRequired => 'Pilih wajib';

  @override
  String get liaFireDesc => 'Kirim course ke line langsung';

  @override
  String get liaEditDesc =>
      'Jumlah, catatan, dan pilihan · sebelum masuk dapur';

  @override
  String get liaServeDesc => 'Konfirmasi diambil & diantar ke meja';

  @override
  String get liaUnserveDesc => 'Kembalikan status jika ditandai terlalu cepat';

  @override
  String get liaVoidDesc => 'Hapus dari pesanan · tercatat atas nama kamu';

  @override
  String get meEndAdminTitle => 'Akhiri sesi admin?';

  @override
  String get meEndShiftTitle => 'Akhiri shift?';

  @override
  String meEndServerBodyLive(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n meja',
    );
    return '$_temp0 masih aktif. Keluar akan mematikan server — semua staff terputus dan tidak bisa menyambung sampai admin masuk lagi.';
  }

  @override
  String get meEndServerBody =>
      'Keluar akan mematikan server. Staff tidak bisa menyambung sampai admin masuk lagi.';

  @override
  String get meEndShiftBody =>
      'Shift ditutup dan hitungannya berhenti. Masuk lagi akan memulai shift baru. Untuk menyerahkan perangkat tanpa menutup shift, pakai \"Keluar\".';

  @override
  String get meEndAndShutdown => 'Keluar & matikan';

  @override
  String get meEndShiftConfirm => 'Akhiri shift';

  @override
  String get meNoOpenTickets => 'Tidak ada tiket terbuka';

  @override
  String get rcpItemizedReceipt => 'STRUK';

  @override
  String rcpRefundLine(String method) {
    return '$method (refund)';
  }

  @override
  String tableNamed(String label) {
    return 'Meja $label';
  }

  @override
  String rcpPaxCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tamu',
    );
    return '$_temp0';
  }

  @override
  String get roleWaiter => 'Pelayan';

  @override
  String get roleKitchen => 'Dapur';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get tstatDraft => 'Draf';

  @override
  String get tstatAcknowledged => 'Diterima';

  @override
  String get tstatSent => 'Terkirim';

  @override
  String get tstatPrep => 'Disiapkan';

  @override
  String get tstatCooked => 'Selesai dimasak';

  @override
  String get tstatReady => 'Siap diambil';

  @override
  String get tstatServed => 'Disajikan';

  @override
  String get tstatHeld => 'Ditahan';

  @override
  String get tstatVoided => 'Dibatalkan';

  @override
  String get resStatPending => 'Menunggu';

  @override
  String get resStatSeated => 'Duduk';

  @override
  String get resStatNoShow => 'No-show';

  @override
  String get resStatCancelled => 'Batal';

  @override
  String get stkReasonSale => 'Terjual';

  @override
  String get stkReasonVoidReturn => 'Batal — kembali';

  @override
  String get stkReasonWaste => 'Terbuang';

  @override
  String get stkReasonReceive => 'Terima barang';

  @override
  String get stkReasonAdjust => 'Penyesuaian';

  @override
  String get stkReasonProduce => 'Produksi';

  @override
  String get noteLabel => 'Catatan';

  @override
  String tblZoneReadyCount(int n) {
    return '$n siap';
  }

  @override
  String get tkwStatusHandedOver => 'Diserahkan';

  @override
  String get tkwStatusReady => 'Siap';

  @override
  String get tkwStatusInProgress => 'Diproses';

  @override
  String get tkwStatusDone => 'Selesai';

  @override
  String get pinSignInAsAdmin => 'Masuk sebagai admin';

  @override
  String get prnAddManual => 'Tambah manual';

  @override
  String get rptLoading => 'Memuat laporan…';

  @override
  String get rptFreshLive => 'Live';

  @override
  String get rptFreshSnapshot => 'Snapshot';

  @override
  String modOptionSoldOut(String name) {
    return '$name · habis';
  }

  @override
  String venueHubBadgeFloor(int tables, int zones) {
    String _temp0 = intl.Intl.pluralLogic(
      tables,
      locale: localeName,
      other: '$tables meja',
    );
    String _temp1 = intl.Intl.pluralLogic(
      zones,
      locale: localeName,
      other: '$zones zona',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String venueHubBadgeStaff(int n) {
    return '$n staf';
  }

  @override
  String get venueHubOperationalMode => 'Mode Operasional';

  @override
  String ordTitleVenue(String venue) {
    return 'Pesanan $venue';
  }

  @override
  String get ordTabReady => 'Siap';

  @override
  String get rcpSampleTable => 'Meja 4 · Contoh';

  @override
  String meAuditTable(String table) {
    return 'Meja $table';
  }

  @override
  String resvSeatToTable(String action) {
    return '$action ke meja:';
  }

  @override
  String get resvZoneTableOptional => 'Zona & meja (opsional)';

  @override
  String get elapsedJustNow => 'baru saja';

  @override
  String elapsedMinutesAgo(int n) {
    return '$n menit lalu';
  }

  @override
  String elapsedHoursAgo(int n) {
    return '$n jam lalu';
  }

  @override
  String get ownRptLoadFailed => 'Gagal memuat laporan.';

  @override
  String get ownRptNoneYet => 'Belum ada laporan dari venue ini.';

  @override
  String get ownRptUnknownFormat => 'Format laporan tidak dikenal.';

  @override
  String get ownRptRequesting => 'Meminta laporan…';

  @override
  String get ownRptNoData => 'Belum ada data';

  @override
  String ownRptUpdatedPending(String ago) {
    return 'Diperbarui $ago · menunggu venue (mungkin offline)';
  }

  @override
  String ownRptUpdated(String ago) {
    return 'Diperbarui $ago';
  }

  @override
  String get fltNotConnected => 'Tidak terhubung — perubahan tidak dikirim.';

  @override
  String get fltSignOutTitle => 'Keluar dari Fleet?';

  @override
  String get fltSignOutBody => 'Perlu email & password lagi untuk masuk.';

  @override
  String get fltSignOut => 'Keluar';

  @override
  String get fltBandTrouble => 'PERLU TINDAKAN';

  @override
  String get fltBandEnding => 'LANGGANAN AKAN BERAKHIR';

  @override
  String get fltBandIdle => 'TIDAK BERJALAN';

  @override
  String get fltBandRunning => 'BERJALAN';

  @override
  String get fltUnnamed => '(tanpa nama)';

  @override
  String fltEndsIn(String when) {
    return 'Berakhir $when';
  }

  @override
  String get fltActivate => 'Aktifkan';

  @override
  String get fltSuspendKill => 'Tangguhkan (kill)';

  @override
  String fltPaidUntil(String date) {
    return 's/d $date';
  }

  @override
  String get fltBillingOverdue => 'Tagihan lewat';

  @override
  String fltSuspendedOn(String date) {
    return 'Ditangguhkan $date';
  }

  @override
  String fltOverdueDiesOn(String date) {
    return 'Lewat — mati $date';
  }

  @override
  String fltDaysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hari',
    );
    return '$_temp0 lagi';
  }

  @override
  String get fltToday => 'hari ini';

  @override
  String fltVenueActivated(String name) {
    return '$name diaktifkan';
  }

  @override
  String fltSuspendTitle(String name) {
    return 'Tangguhkan $name?';
  }

  @override
  String get fltSuspendBody =>
      'Server venue mati sekarang juga dan semua staf terputus — termasuk di tengah jam ramai.';

  @override
  String fltVenueSuspended(String name) {
    return '$name ditangguhkan';
  }

  @override
  String get fltVenueCreated => 'Venue dibuat';

  @override
  String get fltLockoutPast =>
      'Lewat batas offline — akan terkunci saat restart';

  @override
  String fltLockoutNear(int hours) {
    return 'Mendekati batas offline ${hours}j';
  }

  @override
  String get fltNeverOnline => 'Belum online';

  @override
  String get fltOnline => 'Online';

  @override
  String fltOfflineMinutes(int n) {
    return 'Offline ${n}m';
  }

  @override
  String fltOfflineHours(int n) {
    return 'Offline ${n}j';
  }

  @override
  String fltOfflineDays(int n) {
    return 'Offline ${n}h';
  }

  @override
  String get fltTagAccount => 'AKUN';

  @override
  String get fltTagReports => 'LAPORAN';

  @override
  String get fltTagData => 'DATA';

  @override
  String get fltTagControl => 'KENDALI';

  @override
  String get fltTagBilling => 'TAGIHAN';

  @override
  String get fltAddAdmin => 'Tambah admin';

  @override
  String get fltAddOwner => 'Tambah pemilik';

  @override
  String get fltNoAdmins => 'Belum ada admin untuk venue ini.';

  @override
  String get fltNoOwners =>
      'Belum ada akun pemilik — akses baca laporan dari luar venue, bukan peran staf.';

  @override
  String get fltNameRequired => 'Nama wajib diisi';

  @override
  String get fltAccessActive =>
      'Server venue berjalan dan staf bisa masuk seperti biasa.';

  @override
  String get fltAccessSuspended =>
      'Server venue mati. Staf tidak bisa masuk sampai diaktifkan lagi.';

  @override
  String get fltAccessUnknown =>
      'Status tidak dikenali di cloud. Venue tetap tidak bisa melayani. Setel ulang dengan tombol di bawah.';

  @override
  String get fltNotSetLower => 'belum diatur';

  @override
  String get fltNotSet => 'Belum diatur';

  @override
  String get fltResetPassword => 'Reset password';

  @override
  String fltAdminActivated(String name) {
    return '$name diaktifkan';
  }

  @override
  String fltAdminSuspended(String name) {
    return '$name ditangguhkan';
  }

  @override
  String fltAdminDeleted(String name) {
    return '$name dihapus';
  }

  @override
  String fltDeleteAdminTitle(String name) {
    return 'Hapus $name?';
  }

  @override
  String fltDeleteAdminBody(String who) {
    return 'Akun login & datanya dihapus permanen. $who tidak bisa masuk lagi.';
  }

  @override
  String get fltCodeCopied => 'Kode disalin';

  @override
  String fltDeleteVenueTitle(String name) {
    return 'Hapus $name?';
  }

  @override
  String get fltDeleteVenueBody =>
      'Venue dihapus permanen dari fleet. Tidak bisa dibatalkan.';

  @override
  String get fltAlreadyPassed => 'Sudah lewat';

  @override
  String get fltTrialEnds => 'Selesai coba';

  @override
  String get fltValidUntil => 'Berlaku sampai';

  @override
  String fltCutoffTrial(String date) {
    return 'Venue ditangguhkan otomatis $date, tepat saat masa coba habis.';
  }

  @override
  String fltCutoffPaid(String date) {
    return 'Venue ditangguhkan otomatis $date — 7 hari tenggang setelah jatuh tempo.';
  }

  @override
  String get fltEmailInvalid => 'Format email tidak valid';

  @override
  String get fltPasswordMin => 'Minimal 6 karakter';

  @override
  String get staffErrPinPoolExhausted => 'Semua PIN 6 digit sudah terpakai.';

  @override
  String get staffErrPinLength => 'PIN harus 6 digit.';

  @override
  String get staffErrPinInUse => 'PIN sudah dipakai staf lain.';

  @override
  String staffErrPinUpdateFailed(String status) {
    return 'Gagal mengubah PIN ($status).';
  }

  @override
  String get staffErrLastAdmin =>
      'Harus ada minimal satu pengguna aktif dengan kapabilitas “Kelola staf”.';

  @override
  String get sndSilent => 'Senyap';

  @override
  String get sndBell => 'Bel';

  @override
  String get sndClick => 'Klik';

  @override
  String get sndCriticalAlarm => 'Alarm Kritis';

  @override
  String get sndDoorbell => 'Bel Pintu';

  @override
  String get sndFacilityAlarm => 'Alarm Fasilitas';

  @override
  String get sndGameAlarm => 'Alarm Game';

  @override
  String get sndHappyBell => 'Lonceng Ceria';

  @override
  String get sndHarp => 'Harpa';

  @override
  String get sndRemove => 'Hapus';

  @override
  String get sndShortAlarm => 'Alarm Pendek';

  @override
  String get sndStart => 'Mulai';

  @override
  String get meShiftHeld => 'ditahan';

  @override
  String get meShiftSent => 'terkirim';

  @override
  String get meShiftPrep => 'disiapkan';

  @override
  String get meShiftCooked => 'matang';

  @override
  String get meShiftReady => 'siap';

  @override
  String venueHubBadgeMenu(int items, int cats) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items item',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cats,
      locale: localeName,
      other: '$cats kategori',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String venueHubBadgeStockLow(int n) {
    return '$n perhatian';
  }

  @override
  String venueHubBadgeStockOk(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n bahan',
    );
    return '$_temp0';
  }

  @override
  String venueHubBadgeVenue(String tax, String svc) {
    return 'Pajak $tax% · Service $svc%';
  }

  @override
  String get venueHubLanActive => 'LAN AKTIF';

  @override
  String get venueHubLanLocal => 'LOKAL';

  @override
  String moneyCompactJt(String v) {
    return 'Rp ${v}jt';
  }

  @override
  String moneyCompactRb(String v) {
    return 'Rp ${v}rb';
  }

  @override
  String moneyCompactPlain(String v) {
    return 'Rp $v';
  }
}
