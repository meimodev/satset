import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/features/admin/widgets/receipt_preview.dart';
import '_common.dart';

class VenueIdentityScreen extends ConsumerStatefulWidget {
  const VenueIdentityScreen({super.key});
  @override
  ConsumerState<VenueIdentityScreen> createState() =>
      _VenueIdentityScreenState();
}

class _VenueIdentityScreenState extends ConsumerState<VenueIdentityScreen> {
  late final TextEditingController _displayName;
  late final TextEditingController _legalName;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _receiptHeader;
  late final TextEditingController _receiptFooter;
  late final TextEditingController _receiptTagline;
  late final TextEditingController _receiptSocial;
  late final TextEditingController _receiptThankYou;
  late final TextEditingController _receiptQrUrl;
  late final TextEditingController _receiptQrCaption;

  final _displayNameFocus = FocusNode();
  final _legalNameFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _receiptHeaderFocus = FocusNode();
  final _receiptFooterFocus = FocusNode();
  final _receiptTaglineFocus = FocusNode();
  final _receiptSocialFocus = FocusNode();
  final _receiptThankYouFocus = FocusNode();
  final _receiptQrUrlFocus = FocusNode();
  final _receiptQrCaptionFocus = FocusNode();

  // Picked-but-not-yet-confirmed logo bytes for the live preview; the saved
  // logo rides venueLogoBytesProvider. Null once a save round-trips or cleared.
  Uint8List? _pickedLogo;
  bool _logoBusy = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(venueSettingsProvider);
    _displayName = TextEditingController(text: s.displayName);
    _legalName = TextEditingController(text: s.legalName);
    _address = TextEditingController(text: s.address);
    _phone = TextEditingController(text: s.phone);
    _receiptHeader = TextEditingController(text: s.receiptHeader);
    _receiptFooter = TextEditingController(text: s.receiptFooter);
    _receiptTagline = TextEditingController(text: s.receiptTagline);
    _receiptSocial = TextEditingController(text: s.receiptSocial);
    _receiptThankYou = TextEditingController(text: s.receiptThankYou);
    _receiptQrUrl = TextEditingController(text: s.receiptQrUrl);
    _receiptQrCaption = TextEditingController(text: s.receiptQrCaption);

    _bindFocusCommit(_displayNameFocus, _displayName,
        (v) => _patch(displayName: v));
    _bindFocusCommit(
        _legalNameFocus, _legalName, (v) => _patch(legalName: v));
    _bindFocusCommit(_addressFocus, _address, (v) => _patch(address: v));
    _bindFocusCommit(_phoneFocus, _phone, (v) => _patch(phone: v));
    _bindFocusCommit(_receiptHeaderFocus, _receiptHeader,
        (v) => _patch(receiptHeader: v));
    _bindFocusCommit(_receiptFooterFocus, _receiptFooter,
        (v) => _patch(receiptFooter: v));
    _bindFocusCommit(_receiptTaglineFocus, _receiptTagline,
        (v) => _patch(receiptTagline: v));
    _bindFocusCommit(_receiptSocialFocus, _receiptSocial,
        (v) => _patch(receiptSocial: v));
    _bindFocusCommit(_receiptThankYouFocus, _receiptThankYou,
        (v) => _patch(receiptThankYou: v));
    _bindFocusCommit(_receiptQrUrlFocus, _receiptQrUrl,
        (v) => _patch(receiptQrUrl: v));
    _bindFocusCommit(_receiptQrCaptionFocus, _receiptQrCaption,
        (v) => _patch(receiptQrCaption: v));

    // Live preview: rebuild as the admin types in any branding field.
    for (final c in [
      _displayName,
      _address,
      _phone,
      _receiptHeader,
      _receiptFooter,
      _receiptTagline,
      _receiptSocial,
      _receiptThankYou,
      _receiptQrUrl,
      _receiptQrCaption,
    ]) {
      c.addListener(_onDraftChanged);
    }
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  void _bindFocusCommit(
    FocusNode node,
    TextEditingController c,
    void Function(String) onCommit,
  ) {
    node.addListener(() {
      if (!node.hasFocus) onCommit(c.text);
    });
  }

  Future<void> _patch({
    String? displayName,
    String? legalName,
    String? address,
    String? phone,
    String? receiptHeader,
    String? receiptFooter,
    String? receiptTagline,
    String? receiptSocial,
    String? receiptThankYou,
    String? receiptQrUrl,
    String? receiptQrCaption,
  }) async {
    final s = ref.read(venueSettingsProvider);
    String? norm(String? v, String prev) {
      if (v == null) return null;
      final t = v.trim();
      return t == prev ? null : t;
    }
    final dn = norm(displayName, s.displayName);
    final ln = norm(legalName, s.legalName);
    final ad = norm(address, s.address);
    final ph = norm(phone, s.phone);
    final rh = norm(receiptHeader, s.receiptHeader);
    final rf = norm(receiptFooter, s.receiptFooter);
    final rt = norm(receiptTagline, s.receiptTagline);
    final rs = norm(receiptSocial, s.receiptSocial);
    final rty = norm(receiptThankYou, s.receiptThankYou);
    final rq = norm(receiptQrUrl, s.receiptQrUrl);
    final rqc = norm(receiptQrCaption, s.receiptQrCaption);
    if (dn == null &&
        ln == null &&
        ad == null &&
        ph == null &&
        rh == null &&
        rf == null &&
        rt == null &&
        rs == null &&
        rty == null &&
        rq == null &&
        rqc == null) {
      return;
    }
    try {
      await ref.read(venueSettingsProvider.notifier).patch(
            displayName: dn,
            legalName: ln,
            address: ad,
            phone: ph,
            receiptHeader: rh,
            receiptFooter: rf,
            receiptTagline: rt,
            receiptSocial: rs,
            receiptThankYou: rty,
            receiptQrUrl: rq,
            receiptQrCaption: rqc,
          );
    } catch (_) {
      // Repo reverts state; controllers will resync via ref.listen below.
    }
  }

  void _syncFromState(VenueSettingsDto s) {
    void apply(TextEditingController c, FocusNode f, String next) {
      if (f.hasFocus) return;
      if (c.text == next) return;
      c.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
    apply(_displayName, _displayNameFocus, s.displayName);
    apply(_legalName, _legalNameFocus, s.legalName);
    apply(_address, _addressFocus, s.address);
    apply(_phone, _phoneFocus, s.phone);
    apply(_receiptHeader, _receiptHeaderFocus, s.receiptHeader);
    apply(_receiptFooter, _receiptFooterFocus, s.receiptFooter);
    apply(_receiptTagline, _receiptTaglineFocus, s.receiptTagline);
    apply(_receiptSocial, _receiptSocialFocus, s.receiptSocial);
    apply(_receiptThankYou, _receiptThankYouFocus, s.receiptThankYou);
    apply(_receiptQrUrl, _receiptQrUrlFocus, s.receiptQrUrl);
    apply(_receiptQrCaption, _receiptQrCaptionFocus, s.receiptQrCaption);
  }

  @override
  void dispose() {
    _displayName.dispose();
    _legalName.dispose();
    _address.dispose();
    _phone.dispose();
    _receiptHeader.dispose();
    _receiptFooter.dispose();
    _receiptTagline.dispose();
    _receiptSocial.dispose();
    _receiptThankYou.dispose();
    _receiptQrUrl.dispose();
    _receiptQrCaption.dispose();
    _displayNameFocus.dispose();
    _legalNameFocus.dispose();
    _addressFocus.dispose();
    _phoneFocus.dispose();
    _receiptHeaderFocus.dispose();
    _receiptFooterFocus.dispose();
    _receiptTaglineFocus.dispose();
    _receiptSocialFocus.dispose();
    _receiptThankYouFocus.dispose();
    _receiptQrUrlFocus.dispose();
    _receiptQrCaptionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VenueSettingsDto>(venueSettingsProvider, (_, next) {
      _syncFromState(next);
    });
    if (!context.layout.useTabletShell) return _buildPhone(context);
    return _tablet(context);
  }

  Widget _tablet(BuildContext context) {
    final s = ref.watch(venueSettingsProvider);
    return AdminPage(
      title: 'Identitas venue',
      sub: s.legalName.isEmpty
          ? s.displayName
          : '${s.displayName} · ${s.legalName}',
      children: [
        _venueHero(context, s),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _identityCard(context),
                  const SizedBox(height: 14),
                  _receiptCard(context),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _receiptPreview(context),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _PajakLayananCard(),
        const SizedBox(height: 14),
        _GuestOrderingCard(),
        const SizedBox(height: 14),
        _ReportsHourCard(),
      ],
    );
  }

  Widget _buildPhone(BuildContext context) {
    final sc = context.sat;
    final s = ref.watch(venueSettingsProvider);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
            child: Text('Identitas venue',
                style: SatType.sans(
                  size: 30,
                  weight: FontWeight.w600,
                  letterSpacing: -0.6,
                  color: sc.textHi,
                )),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text('Profil, lokal, pajak, struk',
                style: SatType.sans(size: 13, color: sc.textMd)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              children: [
                _phoneRow(context, sc,
                    label: 'Profil & alamat',
                    value: s.displayName,
                    onTap: () => _openDetail(context, 'Profil & alamat',
                        (c, _) => _identityCard(c))),
                _phoneRow(context, sc,
                    label: 'Branding struk',
                    value: _receiptSummary(s),
                    onTap: () => _openDetail(
                        context,
                        'Branding struk',
                        (c, _) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _receiptCard(c),
                                const SizedBox(height: 20),
                                Center(child: _receiptPreview(c)),
                              ],
                            ))),
                _phoneRow(context, sc,
                    label: 'Pajak & layanan',
                    value: _pajakLayananSummary(s),
                    onTap: () => _openDetail(context, 'Pajak & layanan',
                        (c, _) => _PajakLayananCard())),
                _phoneRow(context, sc,
                    label: 'Pesanan mandiri',
                    value: s.guestOrderingEnabled ? 'Aktif' : 'Nonaktif',
                    onTap: () => _openDetail(context, 'Pesanan mandiri',
                        (c, _) => _GuestOrderingCard())),
                _phoneRow(context, sc,
                    label: 'Laporan & shift',
                    value:
                        'Mulai ${s.businessDayStartHour.toString().padLeft(2, '0')}:00 · target ${s.prepTargetMins}m',
                    onTap: () => _openDetail(context, 'Laporan & shift',
                        (c, _) => _ReportsHourCard()),
                    last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _venueHero(BuildContext context, VenueSettingsDto s) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: sc.textHi,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(_initials(s.displayName),
                style: SatType.sans(
                  size: 22,
                  weight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: sc.bg1,
                )),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IDENTITAS RESTORAN',
                    style: SatType.mono(
                      size: 10,
                      weight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: sc.textLo,
                    )),
                const SizedBox(height: 8),
                Text(s.displayName.isEmpty ? '—' : s.displayName,
                    style: SatType.sans(
                      size: 26,
                      weight: FontWeight.w600,
                      letterSpacing: -0.6,
                      color: sc.textHi,
                    )),
                const SizedBox(height: 4),
                Text(s.legalName.isEmpty ? 'Belum ada nama legal' : s.legalName,
                    style: SatType.sans(size: 12, color: sc.textMd)),
                const SizedBox(height: 10),
                Text(s.address.isEmpty ? 'Belum ada alamat' : s.address,
                    style: SatType.sans(
                        size: 13, color: sc.textMd, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _identityCard(BuildContext context) {
    // Name + address are cloud-owned (ADR-0018): mirrored read-only from the
    // fleet console; only a super admin edits them.
    final s = ref.watch(venueSettingsProvider);
    return _sectionCard(
        context,
        title: 'Profil & alamat',
        tag: 'WAJIB',
        rows: [
          AdminRow(
              label: 'Nama tampilan',
              value: _cloudManaged(context, s.displayName)),
          AdminRow(
              label: 'Nama legal',
              value: _editor(context,
                  controller: _legalName,
                  focus: _legalNameFocus,
                  hint: 'PT …',
                  onSubmit: (v) => _patch(legalName: v))),
          AdminRow(
              label: 'Alamat',
              value: _cloudManaged(context, s.address)),
          AdminRow(
              label: 'Telepon',
              value: _editor(context,
                  controller: _phone,
                  focus: _phoneFocus,
                  hint: '+62 …',
                  mono: true,
                  inputType: TextInputType.phone,
                  onSubmit: (v) => _patch(phone: v)),
              last: true),
        ],
      );
  }

  /// Read-only value for a cloud-owned field (name/address), with a subtle
  /// "managed by the super admin" caption. See ADR-0018.
  Widget _cloudManaged(BuildContext context, String value) {
    final sc = context.sat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value.isEmpty ? '—' : value,
            textAlign: TextAlign.right,
            style: SatType.sans(size: 13, color: sc.textHi, height: 1.4)),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 10, color: sc.textLo),
            const SizedBox(width: 3),
            Text('Dikelola pengelola',
                style: SatType.sans(size: 10, color: sc.textLo)),
          ],
        ),
      ],
    );
  }

  Widget _receiptCard(BuildContext context) => _sectionCard(
        context,
        title: 'Branding struk',
        tag: 'CETAK',
        rows: [
          AdminRow(label: 'Logo', value: _logoTile(context)),
          AdminRow(
              label: 'Tagline',
              value: _editor(context,
                  controller: _receiptTagline,
                  focus: _receiptTaglineFocus,
                  hint: 'mis. Kopi & Dapur',
                  onSubmit: (v) => _patch(receiptTagline: v))),
          AdminRow(
              label: 'Header',
              value: _editor(context,
                  controller: _receiptHeader,
                  focus: _receiptHeaderFocus,
                  hint: 'Tampil di atas struk',
                  onSubmit: (v) => _patch(receiptHeader: v))),
          AdminRow(
              label: 'Sosial',
              value: _editor(context,
                  controller: _receiptSocial,
                  focus: _receiptSocialFocus,
                  hint: '@instagram · wa.me/…',
                  onSubmit: (v) => _patch(receiptSocial: v))),
          AdminRow(
              label: 'Footer',
              value: _editor(context,
                  controller: _receiptFooter,
                  focus: _receiptFooterFocus,
                  hint: 'Tampil di bawah struk',
                  multiline: true,
                  onSubmit: (v) => _patch(receiptFooter: v))),
          AdminRow(
              label: 'Ucapan terima kasih',
              value: _editor(context,
                  controller: _receiptThankYou,
                  focus: _receiptThankYouFocus,
                  hint: 'Terima kasih',
                  onSubmit: (v) => _patch(receiptThankYou: v))),
          AdminRow(
              label: 'QR (URL)',
              value: _editor(context,
                  controller: _receiptQrUrl,
                  focus: _receiptQrUrlFocus,
                  hint: 'https://… (hanya struk uang)',
                  mono: true,
                  inputType: TextInputType.url,
                  onSubmit: (v) => _patch(receiptQrUrl: v))),
          AdminRow(
              label: 'QR (keterangan)',
              value: _editor(context,
                  controller: _receiptQrCaption,
                  focus: _receiptQrCaptionFocus,
                  hint: 'mis. Ulas kami di Google',
                  onSubmit: (v) => _patch(receiptQrCaption: v)),
              last: true),
        ],
      );

  /// Resolves the logo bytes shown in the preview: a fresh unsaved pick wins,
  /// otherwise the saved blob via the cache-busted side-endpoint.
  Uint8List? _previewLogo(VenueSettingsDto s) {
    if (_pickedLogo != null) return _pickedLogo;
    return ref.watch(venueLogoBytesProvider(s.logoRev)).valueOrNull;
  }

  Widget _logoTile(BuildContext context) {
    final sc = context.sat;
    final s = ref.watch(venueSettingsProvider);
    final bytes = _previewLogo(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: sc.bg1,
                border: Border.all(color: sc.border0),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: bytes != null
                  ? Image.memory(bytes,
                      fit: BoxFit.contain, gaplessPlayback: true)
                  : Icon(Icons.storefront_outlined,
                      size: 20, color: sc.textLo),
            ),
            const SizedBox(width: 10),
            if (_logoBusy)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: sc.accent),
              )
            else ...[
              _logoBtn(sc, bytes == null ? 'Tambah' : 'Ganti', _pickLogo),
              if (bytes != null) ...[
                const SizedBox(width: 8),
                _logoBtn(sc, 'Hapus', _clearLogo, danger: true),
              ],
            ],
          ],
        ),
      ],
    );
  }

  Widget _logoBtn(SatColors sc, String label, VoidCallback onTap,
      {bool danger = false}) {
    final c = danger ? sc.urgent : sc.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.10),
          border: Border.all(color: c.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: SatType.sans(
                size: 12, weight: FontWeight.w600, color: c)),
      ),
    );
  }

  Future<void> _pickLogo() async {
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 2048);
      if (x == null) return;
      setState(() => _logoBusy = true);
      final raw = await x.readAsBytes();
      // Downscale + re-encode JPEG (≤1024px wide) before sending. The thermal
      // raster downscales again to 384px; this keeps the stored blob lean.
      final decoded = img.decodeImage(raw);
      if (decoded == null) {
        setState(() => _logoBusy = false);
        return;
      }
      final scaled = decoded.width > 1024
          ? img.copyResize(decoded, width: 1024)
          : decoded;
      final jpeg = Uint8List.fromList(img.encodeJpg(scaled, quality: 85));
      await ref.read(venueSettingsProvider.notifier).uploadLogo(jpeg);
      if (!mounted) return;
      // Bust the cached fetch so the saved-bytes path picks up the new rev.
      ref.invalidate(venueLogoBytesProvider);
      setState(() {
        _pickedLogo = jpeg;
        _logoBusy = false;
      });
    } catch (_) {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  Future<void> _clearLogo() async {
    setState(() => _logoBusy = true);
    try {
      await ref.read(venueSettingsProvider.notifier).clearLogo();
      if (!mounted) return;
      ref.invalidate(venueLogoBytesProvider);
    } catch (_) {
      // ignore; state unchanged on failure
    } finally {
      if (mounted) {
        setState(() {
          _pickedLogo = null;
          _logoBusy = false;
        });
      }
    }
  }

  Widget _receiptPreview(BuildContext context) {
    final s = ref.watch(venueSettingsProvider);
    return ReceiptPreview(
      data: ReceiptPreviewData(
        logoBytes: _previewLogo(s),
        venueName: _displayName.text,
        address: _address.text,
        phone: _phone.text,
        tagline: _receiptTagline.text,
        social: _receiptSocial.text,
        header: _receiptHeader.text,
        footer: _receiptFooter.text,
        thankYou: _receiptThankYou.text,
        qrUrl: _receiptQrUrl.text,
        qrCaption: _receiptQrCaption.text,
      ),
    );
  }

  Widget _editor(
    BuildContext context, {
    required TextEditingController controller,
    required FocusNode focus,
    required String hint,
    required ValueChanged<String> onSubmit,
    bool multiline = false,
    bool mono = false,
    TextInputType? inputType,
  }) {
    final sc = context.sat;
    return TextField(
      controller: controller,
      focusNode: focus,
      maxLines: multiline ? null : 1,
      minLines: multiline ? 1 : 1,
      keyboardType: inputType ??
          (multiline ? TextInputType.multiline : TextInputType.text),
      textInputAction:
          multiline ? TextInputAction.newline : TextInputAction.done,
      textAlign: TextAlign.right,
      onSubmitted: onSubmit,
      onTapOutside: (_) => focus.unfocus(),
      inputFormatters: multiline ? null : [LengthLimitingTextInputFormatter(120)],
      style: mono
          ? SatType.mono(size: 12, color: sc.textHi)
          : SatType.sans(size: 13, color: sc.textHi, height: 1.4),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: SatType.sans(size: 13, color: sc.textLo),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required String tag,
    required List<Widget> rows,
  }) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: SatType.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: sc.textHi,
                    )),
              ),
              Text(tag,
                  style: SatType.mono(
                    size: 9,
                    weight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: sc.textLo,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _phoneRow(
    BuildContext context,
    SatColors sc, {
    required String label,
    required String value,
    required VoidCallback onTap,
    bool last = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: last ? 0 : 8),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: sc.bg2,
          border: Border.all(color: sc.border0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: SatType.sans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: sc.textHi,
                      )),
                  const SizedBox(height: 2),
                  Text(value,
                      style: SatType.sans(size: 12, color: sc.textMd)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 22, color: sc.textLo),
          ],
        ),
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    String title,
    Widget Function(BuildContext, SatColors) builder,
  ) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PhoneDetailScreen(title: title, builder: builder),
    ));
  }

  String _receiptSummary(VenueSettingsDto s) {
    if (s.receiptHeader.isEmpty && s.receiptFooter.isEmpty) {
      return 'Belum diisi';
    }
    final h = s.receiptHeader.isEmpty ? '—' : s.receiptHeader;
    final f = s.receiptFooter.isEmpty ? '—' : s.receiptFooter;
    return '$h · $f';
  }

  String _pajakLayananSummary(VenueSettingsDto s) {
    final tax = s.taxEnabled ? '${_fmtPct(s.taxRateBps)} PPN' : 'PPN off';
    final svc = !s.serviceEnabled
        ? 'Layanan off'
        : s.serviceMode == 'fixed'
            ? 'Layanan ${formatIDR(s.serviceFixedAmount)}'
            : 'Layanan ${_fmtPct(s.serviceRateBps)}';
    return '$tax · $svc';
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '—';
    final parts = trimmed.split(RegExp(r'\s+'));
    final letters = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join();
    return letters.toUpperCase();
  }
}

String _fmtPct(int bps) {
  final v = bps / 100.0;
  return '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}%';
}

class _PajakLayananCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final s = ref.watch(venueSettingsProvider);
    final n = ref.read(venueSettingsProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Pajak & layanan',
                    style: SatType.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: sc.textHi,
                    )),
              ),
              Text('BIAYA',
                  style: SatType.mono(
                    size: 9,
                    weight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: sc.textLo,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          _toggleRow(
            context,
            sc,
            label: 'Aktifkan PPN',
            on: s.taxEnabled,
            onToggle: () => n.patch(taxEnabled: !s.taxEnabled),
          ),
          if (s.taxEnabled) ...[
            const SizedBox(height: 10),
            _bpsStepper(
              context,
              sc,
              label: 'Tarif PPN',
              valueBps: s.taxRateBps,
              stepBps: 25,
              minBps: 0,
              maxBps: 5000,
              onChange: (v) => n.patch(taxRateBps: v),
            ),
          ],
          Divider(height: 28, color: sc.border0),
          _toggleRow(
            context,
            sc,
            label: 'Aktifkan layanan',
            on: s.serviceEnabled,
            onToggle: () => n.patch(serviceEnabled: !s.serviceEnabled),
          ),
          if (s.serviceEnabled) ...[
            const SizedBox(height: 10),
            _modeSwitcher(
              context,
              sc,
              mode: s.serviceMode,
              onPick: (m) => n.patch(serviceMode: m),
            ),
            const SizedBox(height: 10),
            if (s.serviceMode == 'percent')
              _bpsStepper(
                context,
                sc,
                label: 'Tarif layanan',
                valueBps: s.serviceRateBps,
                stepBps: 50,
                minBps: 0,
                maxBps: 5000,
                onChange: (v) => n.patch(serviceRateBps: v),
              )
            else
              _amountStepper(
                context,
                sc,
                label: 'Jumlah layanan',
                amount: s.serviceFixedAmount,
                step: 1000,
                min: 0,
                max: 1000000,
                onChange: (v) => n.patch(serviceFixedAmount: v),
              ),
          ],
        ],
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context,
    SatColors sc, {
    required String label,
    required bool on,
    required VoidCallback onToggle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: SatType.sans(size: 13, color: sc.textHi)),
        ),
        GestureDetector(
          onTap: onToggle,
          child: adminToggle(context, on: on),
        ),
      ],
    );
  }

  Widget _modeSwitcher(
    BuildContext context,
    SatColors sc, {
    required String mode,
    required ValueChanged<String> onPick,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text('Tipe biaya',
              style: SatType.sans(size: 13, color: sc.textMd)),
        ),
        Expanded(
          child: Row(
            children: [
              _modeChip(context, sc, 'Persen', 'percent', mode, onPick),
              const SizedBox(width: 8),
              _modeChip(context, sc, 'Tetap', 'fixed', mode, onPick),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeChip(
    BuildContext context,
    SatColors sc,
    String label,
    String value,
    String current,
    ValueChanged<String> onPick,
  ) {
    final on = current == value;
    return GestureDetector(
      onTap: () => onPick(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? sc.accentSoft : sc.bg3,
          border: Border.all(color: on ? sc.accentBorder : sc.border1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: SatType.sans(
              size: 12,
              weight: FontWeight.w600,
              color: on ? sc.accent : sc.textMd,
            )),
      ),
    );
  }

  Widget _bpsStepper(
    BuildContext context,
    SatColors sc, {
    required String label,
    required int valueBps,
    required int stepBps,
    required int minBps,
    required int maxBps,
    required ValueChanged<int> onChange,
  }) {
    final canDown = valueBps > minBps;
    final canUp = valueBps < maxBps;
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(label,
              style: SatType.sans(size: 13, color: sc.textMd)),
        ),
        Expanded(
          child: Row(
            children: [
              _stepBtn(sc, Icons.remove,
                  canDown ? () => onChange((valueBps - stepBps).clamp(minBps, maxBps)) : null),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sc.bg3,
                  border: Border.all(color: sc.border1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_fmtPct(valueBps),
                    style: SatType.mono(
                      size: 13,
                      weight: FontWeight.w600,
                      color: sc.textHi,
                    )),
              ),
              const SizedBox(width: 10),
              _stepBtn(sc, Icons.add,
                  canUp ? () => onChange((valueBps + stepBps).clamp(minBps, maxBps)) : null),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountStepper(
    BuildContext context,
    SatColors sc, {
    required String label,
    required int amount,
    required int step,
    required int min,
    required int max,
    required ValueChanged<int> onChange,
  }) {
    final canDown = amount > min;
    final canUp = amount < max;
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(label,
              style: SatType.sans(size: 13, color: sc.textMd)),
        ),
        Expanded(
          child: Row(
            children: [
              _stepBtn(sc, Icons.remove,
                  canDown ? () => onChange((amount - step).clamp(min, max)) : null),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sc.bg3,
                  border: Border.all(color: sc.border1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(formatIDR(amount),
                    style: SatType.mono(
                      size: 13,
                      weight: FontWeight.w600,
                      color: sc.textHi,
                    )),
              ),
              const SizedBox(width: 10),
              _stepBtn(sc, Icons.add,
                  canUp ? () => onChange((amount + step).clamp(min, max)) : null),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepBtn(SatColors sc, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap == null ? sc.bg2 : sc.bg3,
          border: Border.all(color: sc.border1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap == null ? sc.textDim : sc.textHi),
      ),
    );
  }
}


class _GuestOrderingCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final s = ref.watch(venueSettingsProvider);
    final n = ref.read(venueSettingsProvider.notifier);
    final net = ref.watch(guestNetInfoProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Pesanan mandiri',
                    style: SatType.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: sc.textHi,
                    )),
              ),
              Text('QR TAMU',
                  style: SatType.mono(
                    size: 9,
                    weight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: sc.textLo,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tamu pindai QR di meja, pesan sendiri lewat web. Pesanan masuk '
            'antrian “Mandiri” untuk Anda setujui sebelum ke dapur.',
            style: SatType.sans(size: 12, color: sc.textLo, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text('Aktifkan pesanan mandiri',
                    style: SatType.sans(size: 13, color: sc.textHi)),
              ),
              GestureDetector(
                onTap: () => n.patch(
                    guestOrderingEnabled: !s.guestOrderingEnabled),
                child: adminToggle(context, on: s.guestOrderingEnabled),
              ),
            ],
          ),
          if (s.guestOrderingEnabled) ...[
            const SizedBox(height: 14),
            net.when(
              loading: () => _netRow(sc, 'Mendeteksi alamat…', sc.textLo),
              error: (_, _) =>
                  _driftBanner(sc, 'Gagal mendeteksi alamat jaringan.'),
              data: (info) => info.guestBaseUrl == null
                  ? _driftBanner(
                      sc,
                      'Server tidak terhubung Wi-Fi. QR tamu tidak akan '
                      'berfungsi sampai jaringan aktif.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _netRow(sc, info.guestBaseUrl!, sc.textHi),
                        const SizedBox(height: 8),
                        _driftBanner(
                          sc,
                          'PENTING: alamat ini berubah jika IP server berganti. '
                          'Jika Anda mencetak QR, cetak ulang setiap kali '
                          'alamat di atas berubah — QR lama akan mati.',
                          warn: true,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => ref.invalidate(guestNetInfoProvider),
                icon: Icon(Icons.refresh, size: 16, color: sc.accent),
                label: Text('Cek ulang alamat',
                    style: SatType.sans(size: 12, color: sc.accent)),
              ),
            ),
            Text(
              'Aktifkan per meja dari layar Atur lantai untuk menampilkan QR.',
              style: SatType.sans(size: 11, color: sc.textDim, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _netRow(SatColors sc, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: sc.bg1,
          border: Border.all(color: sc.border0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.link, size: 15, color: sc.textLo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: SatType.mono(size: 12.5, color: color)),
            ),
          ],
        ),
      );

  Widget _driftBanner(SatColors sc, String text, {bool warn = false}) {
    final c = warn ? sc.warn : sc.urgent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(warn ? Icons.warning_amber_rounded : Icons.wifi_off,
              size: 17, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: SatType.sans(
                    size: 12, color: sc.textHi, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _ReportsHourCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final s = ref.watch(venueSettingsProvider);
    final n = ref.read(venueSettingsProvider.notifier);
    final hour = s.businessDayStartHour;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Laporan & shift',
                    style: SatType.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: sc.textHi,
                    )),
              ),
              Text('LAPORAN',
                  style: SatType.mono(
                    size: 9,
                    weight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: sc.textLo,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jam mulai hari kerja',
                        style: SatType.sans(size: 13, color: sc.textMd)),
                    const SizedBox(height: 2),
                    Text('Pengelompokan laporan "Hari ini"',
                        style: SatType.sans(size: 11, color: sc.textLo)),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    _stepBtn(
                      sc,
                      Icons.remove,
                      hour > 0
                          ? () => n.patch(businessDayStartHour: hour - 1)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sc.bg3,
                        border: Border.all(color: sc.border1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${hour.toString().padLeft(2, '0')}:00',
                          style: SatType.mono(
                            size: 13,
                            weight: FontWeight.w600,
                            color: sc.textHi,
                          )),
                    ),
                    const SizedBox(width: 10),
                    _stepBtn(
                      sc,
                      Icons.add,
                      hour < 23
                          ? () => n.patch(businessDayStartHour: hour + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: sc.border0),
          const SizedBox(height: 16),
          // Service target (ADR-0013): one threshold for the overdue alert
          // AND the speed-of-service SLA hit-rate in reports.
          Row(
            children: [
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target kecepatan dapur',
                        style: SatType.sans(size: 13, color: sc.textMd)),
                    const SizedBox(height: 2),
                    Text('Batas "telat" di lantai + SLA laporan',
                        style: SatType.sans(size: 11, color: sc.textLo)),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    _stepBtn(
                      sc,
                      Icons.remove,
                      s.prepTargetMins > 5
                          ? () => n.patch(
                              prepTargetMins: s.prepTargetMins - 5)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sc.bg3,
                        border: Border.all(color: sc.border1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${s.prepTargetMins} min',
                          style: SatType.mono(
                            size: 13,
                            weight: FontWeight.w600,
                            color: sc.textHi,
                          )),
                    ),
                    const SizedBox(width: 10),
                    _stepBtn(
                      sc,
                      Icons.add,
                      s.prepTargetMins < 60
                          ? () => n.patch(
                              prepTargetMins: s.prepTargetMins + 5)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(SatColors sc, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap == null ? sc.bg2 : sc.bg3,
          border: Border.all(color: sc.border1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 16, color: onTap == null ? sc.textDim : sc.textHi),
      ),
    );
  }
}

class _PhoneDetailScreen extends StatelessWidget {
  final String title;
  final Widget Function(BuildContext, SatColors) builder;
  const _PhoneDetailScreen({required this.title, required this.builder});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Scaffold(
      backgroundColor: sc.bg1,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_rounded, color: sc.textHi),
                  ),
                  Expanded(
                    child: Text(title,
                        style: SatType.sans(
                          size: 22,
                          weight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: sc.textHi,
                        )),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [builder(context, sc)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
