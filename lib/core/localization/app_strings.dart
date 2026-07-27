class AppStrings {
  // Global & Common Buttons/Labels
  static const String appName = 'SatSet';
  static const String cancel = 'Batal';
  static const String save = 'Simpan';
  static const String delete = 'Hapus';
  static const String add = 'Tambah';
  static const String back = 'Kembali';
  static const String close = 'Tutup';
  static const String loading = 'Memuat…';
  static const String error = 'Gagal';
  static const String active = 'Aktif';
  static const String inactive = 'Nonaktif';
  static const String warning = 'Peringatan';
  static const String confirm = 'Konfirmasi';
  static const String ok = 'OK';
  static const String yes = 'Ya';
  static const String no = 'Tidak';

  // Venue Hub Screen
  static const String venueHubTitle = 'Venue';
  static const String venueHubSubtitle =
      'Konfigurasi · zona · menu · sistem · staf';
  static const String venueHubSectionZona = 'Zona';
  static const String venueHubSectionZonaSub =
      'Atur zona, meja, dan kapasitas ruangan';
  static const String venueHubSectionMenu = 'Menu';
  static const String venueHubSectionMenuSub =
      'Kategori, item, modifier, dan harga';
  static const String venueHubSectionVenue = 'Pengaturan Venue';
  static const String venueHubSectionVenueSub =
      'Profil, lokal, pajak, dan branding struk';
  static const String venueHubSectionSystem = 'Sistem';
  static const String venueHubSectionSystemSub =
      'Server, jaringan, printer, perangkat';
  static const String venueHubSectionStaff = 'Staf';
  static const String venueHubSectionStaffSub = 'Akun, peran, dan PIN tim';
  static const String venueHubSectionStock = 'Stok';
  static const String venueHubSectionStockSub =
      'Bahan, terima barang, opname, dan produksi';
  static const String venueHubSectionReports = 'Laporan';
  static const String venueHubSectionReportsSub =
      'Ringkasan shift, penjualan, dan ekspor';
  static const String venueHubSectionAlerts = 'Peringatan';
  static const String venueHubSectionAlertsSub =
      'Ambang waktu, suara, dan senyap perangkat';
  static const String venueHubSeedTitle = 'Mulai cepat';
  static const String venueHubSeedBody =
      'Muat contoh data restoran umum: 2 zona (Dalam & Luar) dengan meja, menu lengkap, dan 2 staf (pelayan & dapur). Bisa diubah kapan saja.';
  static const String venueHubSeedBtnLoad = 'Muat contoh data';
  static const String venueHubSeedBtnLater = 'Nanti';
  static const String venueHubSeedError = 'Gagal memuat contoh data';

  // Venue Settings Screen (formerly Venue Identity Screen)
  static const String venueSettingsTitle = 'Pengaturan Venue';
  static const String venueSettingsSubtitle = 'Profil, lokal, pajak, struk';
  static const String venueSettingsSectionIdentity = 'Profil & alamat';
  static const String venueSettingsSectionIdentityTag = 'WAJIB';
  static const String venueSettingsDisplayName = 'Nama tampilan';
  static const String venueSettingsLegalName = 'Nama legal';
  static const String venueSettingsAddress = 'Alamat';
  static const String venueSettingsPhone = 'Telepon';
  static const String venueSettingsManagedBySuperAdmin = 'Dikelola pengelola';

  static const String venueSettingsSectionReceipt = 'Branding struk';
  static const String venueSettingsSectionReceiptTag = 'CETAK';
  static const String venueSettingsLogo = 'Logo';
  static const String venueSettingsLogoAdd = 'Tambah';
  static const String venueSettingsLogoChange = 'Ganti';
  static const String venueSettingsLogoDelete = 'Hapus';
  static const String venueSettingsTagline = 'Tagline';
  static const String venueSettingsHeader = 'Header';
  static const String venueSettingsSocial = 'Sosial';
  static const String venueSettingsFooter = 'Footer';
  static const String venueSettingsThankYou = 'Ucapan terima kasih';
  static const String venueSettingsQrUrl = 'QR (URL)';
  static const String venueSettingsQrCaption = 'QR (keterangan)';

  static const String venueSettingsSectionTax = 'Pajak & layanan';
  static const String venueSettingsSectionGuestOrdering = 'Pesanan mandiri';
  static const String venueSettingsSectionReports = 'Laporan & shift';
  static const String venueSettingsSectionSound = 'Suara';
  static const String venueSettingsSectionSoundTag = 'Nada notifikasi';
  static const String venueSettingsSoundNewOrder = 'Pesanan baru';
  static const String venueSettingsSoundReady = 'Pesanan siap';
  static const String venueSettingsSoundVoid = 'Void';
  static const String venueSettingsSoundOverdue = 'Lewat waktu';
  static const String venueSettingsSoundUngreeted = 'Belum dilayani';
  static const String venueSettingsSoundPickup = 'Menunggu diantar';

  // Waktu & Peringatan (ADR-0043/0044). Every service threshold lives in one
  // named section — an owner chasing "why does the floor beep" looks for
  // alerts, not for "Laporan".
  static const String venueSettingsSectionTiming = 'Waktu & Peringatan';
  static const String venueSettingsTimingPrepTarget =
      'Target siap (default semua menu)';
  static const String venueSettingsTimingPrepTargetHint =
      'Menu tanpa "Waktu siap" sendiri ikut angka ini.';
  static const String venueSettingsTimingPickup = 'Menunggu diantar';
  static const String venueSettingsTimingPickupHint =
      'Makanan siap tapi belum diantar selama ini.';
  static const String venueSettingsTimingUngreeted = 'Belum dilayani';
  static const String venueSettingsTimingUngreetedHint =
      'Meja terisi tapi belum ada pesanan terkirim.';
  static const String venueSettingsTimingUngreetedEscalate =
      'Naik ke semua waiter setelah';
  static const String venueSettingsTimingUngreetedEscalateHint =
      'Awalnya hanya waiter yang mendudukkan tamu.';
  static const String venueSettingsTimingLongStay = 'Meja lama';
  static const String venueSettingsTimingLongStayHint =
      'Tanda visual di lantai. Tanpa suara.';
  static const String venueSettingsTimingIdle = 'Meja selesai makan';
  static const String venueSettingsTimingIdleHint =
      'Semua terhidang dan tidak ada aktivitas. Tanpa suara.';
  static const String venueSettingsTimingReservationGrace =
      'Toleransi reservasi';
  static const String venueSettingsTimingReservationGraceHint =
      'Lewat ini chip reservasi ditandai terlambat. Status tidak berubah.';
  static const String venueSettingsTimingPendingReview = 'Belum ditinjau';
  static const String venueSettingsTimingPendingReviewHint =
      'Pesanan tamu menunggu ditinjau waiter. Tanpa suara.';
  static const String venueSettingsTimingAlertsOn = 'Bunyikan peringatan';
  static const String venueSettingsTimingMuteTitle = 'Senyapkan di alat ini';
  static const String venueSettingsTimingMuteHint =
      'Hanya untuk alat ini. Pilihan nada tetap milik venue.';

  // Layar Peringatan (/alerts). Dikelompokkan per cakupan, karena cakupan
  // yang paling sering salah dibaca: ambang & nada milik venue, senyap milik
  // satu perangkat.
  static const String alertsTitle = 'Peringatan';
  static const String alertsSectionThresholds = 'Ambang waktu';
  static const String alertsScopeVenue = 'Semua perangkat';
  static const String alertsScopeDevice = 'Hanya perangkat ini';

  // Silent floor states (ADR-0044) — visual markers, never cues.
  static const String tableStateUngreeted = 'Belum dilayani';
  static const String tableStateIdle = 'Selesai makan';
  static const String reservationLate = 'Terlambat';

  // Floor staleness (ADR-0048) — the banner across the foot of a table card.
  // Interpolated because every one of them names how long it has been stuck;
  // a bare label ("Belum disapa") is the standing state, this is the overrun.
  static String staleReadyUncollected(int mins) =>
      'Siap $mins mnt — belum diambil';
  static String staleReservationLate(int mins) =>
      'Tamu telat $mins mnt — lepas meja?';
  static String staleUngreeted(int mins) => 'Belum disapa $mins mnt';
  static String stalePendingReview(int mins) => 'Belum ditinjau $mins mnt';
  static String staleIdle(int mins) =>
      'Selesai makan $mins mnt — tawarkan lagi';
  static String staleLongStay(String elapsed) =>
      'Duduk $elapsed — cek penutupan';

  // Floor card chips.
  static const String tableOwnerMine = 'Punya saya';
  static const String tablePaidFull = 'Lunas';
  static const String tablePaidPartial = 'Sebagian';
  static const String tableNoReservationTable = 'Belum ada meja';

  // Floor head triggers + the surfaces behind them (ADR-0048).
  static const String floorReservations = 'Reservasi';
  static const String floorTakeaway = 'Bawa pulang';
  static const String floorReservationsBook = 'Buku reservasi';
  static const String floorReservationsLateCount = 'telat';
  static const String reservationFilterWaiting = 'Menunggu';
  static const String reservationFilterLate = 'Terlambat';
  static const String reservationFilterSeated = 'Duduk';
  static const String reservationFilterNoShow = 'No-show';
  static const String reservationFilterAll = 'Semua';
  static const String reservationEmptyFilter =
      'Tidak ada reservasi di filter ini.';
  static const String reservationActionSeat = 'Dudukkan';
  static const String reservationActionLate = 'Telat';
  static const String reservationActionNoShow = 'No-show';
  static const String reservationActionRestore = 'Pulihkan';
  static const String takeawayEmpty = 'Belum ada pesanan bawa pulang.';
  static const String venueSettingsSoundPreview = 'Dengar';

  // Zone Admin Screen (formerly Floor Screen)
  static const String zoneAdminTitle = 'Atur Zona';
  static const String tablesEmptyZoneAddTableHint =
      'Tambahkan meja lewat Manajer › Zona';
  static const String zoneAdminZonePill = 'Zona';
  static const String zoneAdminAddTable = 'Tambah meja';
  static const String zoneAdminAddZone = 'Tambah zona';
  static const String zoneAdminEmptyZone = 'Belum ada meja di';
  static const String zoneAdminNoZones = 'Belum ada zona';
  static const String zoneAdminNoZonesCreate =
      'Buat zona dulu untuk menata meja.';
  static const String zoneAdminNoZonesCreateRequest =
      'Minta admin untuk membuat zona.';
  static const String zoneAdminEditTable = 'Atur';
  static const String zoneAdminNewTable = 'Meja baru';
  static const String zoneAdminTableName = 'Nama meja';
  static const String zoneAdminMaxCapacity = 'Kapasitas tamu maks';
  static const String zoneAdminTableActive = 'Meja aktif';
  static const String zoneAdminTableActiveSub =
      'Matikan untuk perbaikan tanpa menghapus.';
  static const String zoneAdminGuestOrdering = 'Pesanan mandiri';
  static const String zoneAdminGuestOrderingSub =
      'Tamu pindai QR meja untuk pesan sendiri.';
  static const String zoneAdminShowQr = 'Tampilkan QR meja';
  static const String zoneAdminDeleteTableConfirmTitle = 'Hapus meja?';
  static const String zoneAdminDeleteTableConfirmSub =
      'akan dihapus permanen dari zona.';

  // App Shell Tabs
  static const String tabMeja = 'Meja';
  static const String tabPesanan = 'Pesanan';
  static const String tabMandiri = 'Mandiri';
  static const String tabKasir = 'Kasir';
  static const String tabSaya = 'Saya';

  // Breadcrumbs
  static const String crumbTeras = 'Teras';
  static const String crumbPesananSaya = 'Pesanan saya';
  static const String crumbPesananMandiri = 'Pesanan mandiri';
  static const String crumbRingkasanShift = 'Ringkasan shift';
  static const String crumbAntrianPersiapan = 'Antrian Persiapan';
  static const String crumbMenuAdmin = 'Menu admin';
  static const String crumbStafAkun = 'Staf & akun';
  static const String crumbLaporanShift = 'Laporan shift';
  static const String crumbKonfigurasi = 'Konfigurasi';

  // Theme picker (ADR-0045)
  static const String themeSheetTitle = 'Tema';
  static const String themeSheetSubtitle = 'Berlaku untuk perangkat ini saja';
  static const String themeAmberGelap = 'Amber Gelap';
  static const String themeAmberTerang = 'Amber Terang';
  static const String themeNeonHijau = 'Neon Hijau';
  static const String themeIndigoTerang = 'Indigo Terang';
  static const String themeNeoKertas = 'Neo Kertas';
  static const String themeNeoMidnight = 'Neo Tengah Malam';

  // Label aksesibilitas — dipakai sebagai `tooltip:` pada tombol yang hanya
  // berisi ikon, dan sebagai `Semantics(label:)` pada area sentuh tanpa teks.
  // Tanpa ini TalkBack hanya membacakan "tombol", jadi kontrol ikon-saja tidak
  // bisa dikenali sama sekali. Kalimat perintah singkat, sama seperti label
  // tombol biasa — pembaca layar membacakannya utuh.
  static const String a11yDecrease = 'Kurangi';
  static const String a11yIncrease = 'Tambah';
  static const String a11yGuestDecrease = 'Kurangi jumlah tamu';
  static const String a11yGuestIncrease = 'Tambah jumlah tamu';
  static const String a11yEdit = 'Ubah';
  static const String a11yRename = 'Ganti nama';
  static const String a11yClear = 'Bersihkan';
  static const String a11yRefresh = 'Muat ulang';
  static const String a11yShowPassword = 'Tampilkan kata sandi';
  static const String a11yHidePassword = 'Sembunyikan kata sandi';
  static const String a11ySoundPreview = 'Dengar nada';
  static const String a11ySoundSilent = 'Tanpa nada';
  static const String a11yPickTheme = 'Pilih tema';
  static const String a11yToggleLayout = 'Ganti tata letak';
  static const String a11yViewPhoto = 'Lihat foto bukti bayar';
  static const String a11yPickColor = 'Pilih warna';
  static const String a11yAddItem = 'Tambah item';
  static const String a11yTableLocked = 'Meja terkunci';
}
