class AppStrings {
  // Global & Common Buttons/Labels
  static const String appName = 'SatSet';
  static const String cancel = 'Batal';
  static const String save = 'Simpan';
  static const String saved = 'Tersimpan';
  static const String delete = 'Hapus';
  static const String add = 'Tambah';
  static const String edit = 'Ubah';
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

  // Leaving the menu with an unsent cart. Nothing outside the menu and review
  // screens renders that cart, so walking out discards it — say so. ADR-0061.
  static const String discardCartTitle = 'Batalkan pesanan ini?';
  static String discardCartBody(int items) =>
      '$items item belum terkirim akan dihapus.';
  static const String discardCartConfirm = 'Ya, batalkan';

  // Screen-reader names for the quantity stepper's two taps. Icon-only
  // targets, so nothing else names them.
  static const String stepperIncrease = 'Tambah satu';
  static const String stepperDecrease = 'Kurangi satu';

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
  static const String venueHubSectionAudit = 'Audit';
  static const String venueHubSectionAuditSub =
      'Batal, gratis, diskon, dan ubah pesanan';

  // ---- Audit log (venue-wide) ----
  static const String auditTitle = 'Catatan audit';
  static const String auditSubtitle = 'Semua kejadian · jejak lengkap';
  static const String auditTabletOnly = 'Butuh layar tablet';
  static const String auditTabletOnlyBody =
      'Catatan audit menampilkan enam kolom sekaligus supaya bisa dibaca '
      'sekilas. Buka dari tablet.';
  static const String auditTabletOnlyBadge = 'Tablet saja';
  static const String auditEmpty = 'Belum ada kejadian';
  static const String auditEmptyBody =
      'Pembatalan, gratisan, diskon, refund, dan perubahan pesanan akan '
      'tampil di sini.';
  static const String auditExport = 'Ekspor';
  static const String auditColTime = 'Waktu';
  static const String auditColType = 'Jenis';
  static const String auditColUser = 'Pengguna';
  static const String auditColEvent = 'Kejadian';
  static const String auditColAmount = 'Jumlah';
  static const String auditColReason = 'Alasan';
  static const String auditSystemActor = 'Sistem';
  static const String auditLoadMore = 'Muat lagi';
  static const String auditWindowToday = 'Hari ini';
  static const String auditWindowYesterday = 'Kemarin';
  static const String auditWindowWeek = '7 hari';
  static const String auditWindowAll = 'Semua waktu';
  static const String auditTypeAll = 'Semua jenis';
  static const String auditTileVoid = 'Pembatalan';
  static const String auditTileComp = 'Gratisan';
  static const String auditTileDiscount = 'Diskon';
  static const String auditTileRefund = 'Refund';
  static const String auditTileKilled = 'Stop jual';
  static const String auditTileModify = 'Ubah pesanan';
  static const String killReasonTitle = 'Stop jual';
  static const String killReasonHint = 'Alasan lain (opsional)';
  static const String killReasonSkip = 'Lewati';
  static const String killReasonConfirm = 'Stop jual';
  static String killReasonBody(String item) =>
      '$item tidak bisa dipesan sampai diaktifkan lagi. Alasannya masuk '
      'catatan audit.';
  static String auditEventCount(int n) => '$n kejadian';
  static String auditNewRows(int n) => '$n baru';
  // Sample data — one seed, one prompt (ADR-0073).
  static const String venueHubSeedTitle = 'Mulai cepat';
  static const String venueHubSeedBody =
      'Muat contoh data restoran umum: 4 zona dengan 20 meja, menu lengkap, '
      '2 staf (pelayan & dapur), dan sebulan riwayat penjualan supaya laporan '
      'dan catatan audit langsung terbaca. Semua bisa diubah atau dihapus '
      'kapan saja.';
  static const String venueHubSeedBodyRunning =
      'Menyusun sebulan riwayat lewat jalur pesanan sungguhan. Biarkan '
      'aplikasi terbuka sampai selesai.';
  static const String venueHubSeedBodyDone =
      'Contoh data siap. Laporan, catatan audit dan riwayat stok sudah terisi.';
  static const String venueHubSeedBodyIncomplete =
      'Pemuatan contoh data terhenti sebelum selesai. Data yang ada tidak utuh '
      '— hapus dulu sebelum memuat ulang.';
  static const String venueHubSeedBodyFailed =
      'Pemuatan contoh data gagal. Data yang sempat masuk tidak utuh — hapus '
      'dulu sebelum mencoba lagi.';
  static const String venueHubSeedBodyLoaded =
      'Venue ini memakai contoh data. Hapus untuk membuang riwayat penjualan '
      'buatan; zona, meja, menu dan staf tetap ada.';
  static const String venueHubSeedBtnLoad = 'Muat contoh data';
  static const String venueHubSeedBtnSkip = 'Lewati';
  static const String venueHubSeedBtnClear = 'Hapus contoh data';
  static const String venueHubSeedBtnClearRetry = 'Hapus & muat ulang';
  static const String venueHubSeedBtnDone = 'Selesai';
  static const String venueHubSeedError = 'Gagal memuat contoh data';
  static const String venueHubSeedRefused =
      'Venue sudah punya riwayat pesanan. Contoh data tidak dimuat.';
  static const String venueHubSeedProgress = 'Menyusun contoh data';
  static String venueHubSeedDays(int done, int total) => 'hari $done/$total';
  static const String settingsSeedTitle = 'Contoh data';
  static const String settingsSeedSubtitle =
      'Muat atau hapus data contoh restoran';

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

  // Turning the venue master switch off is blocked while the review queue
  // still holds pending guest orders — switching off hides the Mandiri tab
  // venue-wide, which would leave those orders with no staff surface.
  static const String guestOrderingBlockTitle = 'Antrian mandiri belum kosong';
  static String guestOrderingBlockBody(int n) =>
      '$n pesanan mandiri masih menunggu ditinjau. Setujui atau tolak dulu '
      'sebelum mematikan pesanan mandiri.';
  static const String guestOrderingBlockAction = 'Lihat antrian';
  static const String venueSettingsSectionReports = 'Laporan & shift';
  static const String venueSettingsSectionSound = 'Suara';
  static const String venueSettingsSectionSoundTag = 'Nada notifikasi';
  static const String venueSettingsSoundNewOrder = 'Pesanan baru';
  static const String venueSettingsSoundReady = 'Pesanan siap';
  static const String venueSettingsSoundVoid = 'Void';
  static const String venueSettingsSoundOverdue = 'Lewat waktu';
  static const String venueSettingsSoundUngreeted = 'Belum dilayani';
  static const String venueSettingsSoundPickup = 'Menunggu diantar';
  static const String venueSettingsSoundGuestPending = 'Pesanan tamu masuk';

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
      'Makanan siap tapi belum diantar selama ini. '
      'Saklar mematikan bunyinya saja — tanda di kartu meja tetap jalan.';
  static const String venueSettingsTimingUngreeted = 'Belum dilayani';
  static const String venueSettingsTimingUngreetedHint =
      'Meja terisi tapi belum ada pesanan terkirim. '
      'Saklar mematikan bunyinya saja — tanda di kartu meja tetap jalan.';
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

  // App Shell Tabs. Each of these is read twice — by the side rail button and
  // by the crumb trail that names the same destination (ADR-0058). One constant
  // per destination is what keeps the two saying the same word.
  static const String tabMeja = 'Meja';
  static const String tabPesanan = 'Pesanan';
  static const String tabMandiri = 'Mandiri';
  static const String tabAntrian = 'Antrian';
  static const String tabKasir = 'Kasir';
  static const String tabVenue = 'Venue';
  static const String tabSaya = 'Saya';

  /// Caps label ahead of the running shift timer in the tablet top bar.
  static const String shiftLabel = 'SHIFT';

  /// Foot of the cashier's Lunas grid once it has scrolled to the paging
  /// ceiling (ADR-0079) and the window still holds older bills. Names where
  /// they *are* rather than apologising for where they are not.
  static const String kasirRiwayatBatas =
      'Menampilkan tagihan terbaru. Tagihan lebih lama ada di Laporan.';

  /// Heading of the kitchen queue screen (`/kitchen`), whose crumb tail is the
  /// shorter [tabAntrian].
  static const String kitchenQueueTitle = 'Antrian Persiapan';

  // Menu search (order flow).
  static const String hapusPencarian = 'Hapus pencarian';
  static const String takAdaItemCocok = 'Tak ada item cocok';

  // Breadcrumbs. Trail tails only — the venue name and the destination segment
  // are prepended by SatAppBar and the tab* constants above.
  static const String crumbTambahItem = 'Tambah item';
  static const String crumbTinjau = 'Tinjau';
  static const String crumbBawaPulang = 'Bawa pulang';
  static const String crumbPesananBaru = 'Pesanan baru';
  static const String crumbDiskon = 'Diskon';
  static const String crumbMenuAdmin = 'Menu admin';
  static const String crumbStafAkun = 'Staf & akun';
  static const String crumbLaporanShift = 'Laporan shift';
  static const String crumbKonfigurasi = 'Konfigurasi';

  // Theme picker (ADR-0045)
  static const String themeSheetTitle = 'Tema';
  static const String themeSheetSubtitle = 'Berlaku untuk perangkat ini saja';
  static const String themeAmberGelap = 'Amber Gelap';
  static const String themeAmberTerang = 'Amber Terang';
  static const String themeNeonGelap = 'Neon Gelap';
  static const String themeNeonTerang = 'Neon Terang';
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
  static const String zoneAdminIcon = 'Ikon zona';
  static const String tableGuests = 'Tamu';
  static const String quantity = 'Jumlah';
  static const String a11yRename = 'Ganti nama';
  static const String a11yClear = 'Bersihkan';
  static const String a11yRefresh = 'Muat ulang';
  static const String a11yShowPassword = 'Tampilkan kata sandi';
  static const String a11yHidePassword = 'Sembunyikan kata sandi';
  static const String a11ySoundPreview = 'Dengar nada';
  static const String a11ySoundSilent = 'Tanpa nada';
  static const String a11yPickTheme = 'Pilih tema';
  static const String a11yViewPhoto = 'Lihat foto bukti bayar';
  static const String a11yPickColor = 'Pilih warna';
  static const String a11yAddItem = 'Tambah item';
  static const String a11yTableLocked = 'Meja terkunci';

  // Pemulihan password admin (ADR-0059). Tidak ada reset otomatis: tombol
  // "Lupa password?" membuka WhatsApp developer dengan pesan yang sudah diisi.

  /// WhatsApp developer, E.164 tanpa `+`, untuk tautan `wa.me`. Ditanam di
  /// aplikasi karena tombol ini ditekan justru saat perangkat belum terpasang
  /// atau tanpa internet — nomor yang harus diambil dari jaringan tidak ada
  /// gunanya di saat itu.
  static const String devWhatsApp = '6289525699078';

  static String resetRequestMessage(String email) =>
      'Halo, saya lupa password admin SatSet.\n'
      'Email: $email\n'
      'Mohon dibantu reset.';

  static const String resetRequestFailed = 'Gagal membuka WhatsApp.';

  // Langganan venue (ADR-0074). Tidak ada payment gateway: banner langganan
  // membuka WhatsApp yang sama seperti "Lupa password?", dengan nama dan id
  // venue sudah terisi supaya super admin langsung menemukan venue-nya.

  static String billingRequestMessage(String venueName, String venueId) =>
      'Halo, saya mau perpanjang langganan SatSet.\n'
      'Venue: $venueName\n'
      'ID: $venueId\n'
      'Mohon dibantu.';

  /// Sisa masa langganan, dibulatkan ke hari. Hari ini bukan "0 hari lagi" —
  /// nol hari terbaca seperti "sudah lewat", padahal venue masih jalan.
  static String billingEndsIn(int days) =>
      days >= 1 ? 'Langganan berakhir $days hari lagi.' : 'Langganan berakhir hari ini.';

  static const String billingLapsed = 'Masa langganan sudah lewat.';

  /// Tanggal venue benar-benar berhenti melayani (ADR-0076). Sejak sweep
  /// otomatis ada, banner boleh menyebut tanggalnya — dan harus: venue yang
  /// dimatikan tanpa pernah diberi tahu tanggalnya persis kegagalan yang mau
  /// dicegah ADR-0074, cuma datang dari arah sebaliknya.
  static String billingStopsOn(String date) =>
      'Venue berhenti melayani $date.';

  static const String billingCta = 'Ketuk untuk perpanjang lewat WhatsApp.';

  // Sandi sementara (ADR-0075). Super admin membuat kode 8 angka, menyebutkannya
  // ke admin venue lewat telepon, dan admin wajib menggantinya saat masuk.

  static const String tempPasswordTitle = 'Ganti sandi';

  /// Jalan keluar dari layar ganti sandi. Bukan "Batal" — tidak ada yang
  /// dibatalkan; sesi Firebase-nya ditutup dan admin kembali ke layar masuk.
  static const String logout = 'Keluar';

  /// Alasan layar ini muncul, ditulis sebagai fakta bukan peringatan — admin
  /// venue tidak melakukan kesalahan apa pun, sandinya memang baru direset.
  static const String tempPasswordReason =
      'Anda masuk dengan sandi sementara. Buat sandi baru untuk melanjutkan.';

  static const String tempPasswordNew = 'Sandi baru';
  static const String tempPasswordConfirm = 'Ulangi sandi baru';

  static String tempPasswordTooShort(int min) => 'Minimal $min karakter.';

  static const String tempPasswordMismatch = 'Sandi tidak sama.';

  /// Menolak sandi baru yang sama dengan kode yang barusan disebutkan lewat
  /// telepon — kode itu sudah didengar orang lain, jadi menyimpannya sama saja
  /// dengan tidak mengganti apa pun.
  static const String tempPasswordReused =
      'Sandi baru tidak boleh sama dengan sandi sementara.';

  static const String tempPasswordSaved = 'Sandi berhasil diganti.';

  static const String tempPasswordExpired =
      'Sandi sementara sudah kadaluarsa. Minta yang baru ke pengelola.';

  static const String tempPasswordPending =
      'Sandi akun ini baru direset. Masuk dengan sandi sementara untuk '
      'menggantinya.';

  // Sisi super admin: dialog yang menampilkan kode sekali saja.

  static const String tempPasswordIssuedTitle = 'Sandi sementara';

  static const String tempPasswordIssuedHint =
      'Berlaku 24 jam. Sebutkan ke admin venue — mereka wajib mengganti sandi '
      'saat masuk.';

  /// Ditampilkan sekali dan tidak bisa dibuka lagi; kalau operator menutup
  /// dialog sebelum menyebutkannya, jalan keluarnya adalah reset ulang.
  static const String tempPasswordIssuedOnce =
      'Kode ini hanya muncul sekali.';

  static String tempPasswordShareMessage(String code) =>
      'Sandi sementara SatSet Anda: $code\n'
      'Berlaku 24 jam. Anda akan diminta membuat sandi baru saat masuk.';

  // Staf & akun (staff_screen). Layar ini sebelumnya ditulis penuh dalam bahasa
  // Inggris — satu-satunya layar yang begitu. Istilah yang tetap dipakai apa
  // adanya: PIN, admin, avatar. Itu sudah jadi kata pinjaman di dapur, dan
  // menerjemahkannya justru bikin staf ragu.
  static const String staffTitle = 'Staf & akun';
  static const String staffTabPeople = 'Orang';
  static const String staffTabRoles = 'Peran';
  static const String staffTabPermissions = 'Izin';
  static const String staffSearchHint = 'Cari nama';
  static const String staffFilterAll = 'Semua';
  static const String staffAdd = 'Tambah staf';
  static const String staffAddPill = '+ Tambah staf';
  static const String staffEmpty =
      'Tidak ada staf yang cocok dengan filter ini';
  static const String staffNewRolePill = '+ Peran baru';
  static const String staffRoleBadgeAdmin = 'ADMIN';

  /// Stands in for the edit/rename/delete controls on the admin role row. The
  /// role is created and held by the fleet operator, not by this screen.
  static const String staffRoleManagedByOperator = 'Dikelola pengelola';
  static const String staffRoleColor = 'Warna peran';
  static const String staffColor = 'Warna';
  static const String staffAvatarColor = 'Warna avatar';
  static const String staffMatrixTitle = 'Matriks peran × izin';
  static const String staffMatrixHint =
      'Ketuk sel untuk mengubah. Baris peran admin dikunci — dikelola '
      'pengelola, bukan dari layar ini.';
  static const String staffRole = 'Peran';
  static const String staffNoRole = 'Tanpa peran';
  static const String staffName = 'Nama';
  static const String staffFullName = 'Nama lengkap';
  static const String staffPinField = 'PIN (6 digit, unik)';
  static const String staffPinReset = 'Atur ulang';
  static const String staffPinUpdated = 'PIN diperbarui';
  static const String staffSaveChanges = 'Simpan perubahan';
  static const String staffNewRoleName = 'Nama peran baru';
  static const String staffRenameRole = 'Ganti nama peran';
  static const String staffDisable = 'Nonaktifkan';

  // Penolakan. Menyebut apa yang menghalangi, bukan minta maaf — pengelola
  // sedang di tengah shift dan butuh tahu langkah berikutnya.
  static const String staffErrNameEmpty = 'Nama tidak boleh kosong';
  static const String staffErrAdminBySuperOnly =
      'Peran admin hanya bisa dibuat oleh super admin';
  static const String staffErrAdminPromoteBlocked =
      'Menaikkan ke peran admin tidak bisa dari sini';
  static const String staffErrNeedNonAdminRole = 'Buat peran non-admin dulu';
  static const String staffErrColorTaken =
      'Warna avatar sudah dipakai akun lain';
  static const String staffErrColorTakenShort = 'Warna juga dipakai akun lain';

  // Konfirmasi. Judul menyebut sasaran, badan menyebut akibatnya — sebuah akun
  // yang salah dihapus tidak bisa dibatalkan.
  static const String staffChangeRoleTitle = 'Ganti peran?';
  static const String staffDisableBody =
      'Pengguna tidak bisa masuk lagi. Bisa diaktifkan kembali nanti.';
  static const String staffDeleteBody =
      'Akun dihapus permanen. Catatan audit lama tetap ada.';
  static const String staffDeleteRoleBody =
      'Izin yang melekat pada peran ini akan hilang.';

  static String staffSubtitle(int members, int admins) =>
      '$members anggota · $admins admin';
  static String staffRolesCount(int n) => '$n peran khusus';
  static String staffCapsCount(int held, int total) => '$held/$total izin';
  static String staffMembersCount(int n) => '$n anggota';
  static String staffCreated(String name, String pin) =>
      '$name dibuat. PIN: $pin';
  static String staffNewPin(String pin) => 'PIN baru: $pin';
  static String staffRoleAdminSuffix(String name) => '$name (admin)';
  static String staffDeleteRoleTitle(String name) => 'Hapus peran “$name”?';
  static String staffChangeRoleBody(String name) =>
      'Pindahkan $name ke peran lain. Izin berubah seketika.';
  static String staffDisableTitle(String name) => 'Nonaktifkan $name?';
  static String staffDeleteTitle(String name) => 'Hapus $name?';
}
