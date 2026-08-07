import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_icon_button.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/core/localization/locale_view_model.dart';

class VenueSettingsScreen extends ConsumerStatefulWidget {
  const VenueSettingsScreen({super.key});
  @override
  ConsumerState<VenueSettingsScreen> createState() =>
      _VenueSettingsScreenState();
}

class _VenueSettingsScreenState extends ConsumerState<VenueSettingsScreen> {
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

    _bindFocusCommit(
      _displayNameFocus,
      _displayName,
      (v) => _patch(displayName: v),
    );
    _bindFocusCommit(_legalNameFocus, _legalName, (v) => _patch(legalName: v));
    _bindFocusCommit(_addressFocus, _address, (v) => _patch(address: v));
    _bindFocusCommit(_phoneFocus, _phone, (v) => _patch(phone: v));
    _bindFocusCommit(
      _receiptHeaderFocus,
      _receiptHeader,
      (v) => _patch(receiptHeader: v),
    );
    _bindFocusCommit(
      _receiptFooterFocus,
      _receiptFooter,
      (v) => _patch(receiptFooter: v),
    );
    _bindFocusCommit(
      _receiptTaglineFocus,
      _receiptTagline,
      (v) => _patch(receiptTagline: v),
    );
    _bindFocusCommit(
      _receiptSocialFocus,
      _receiptSocial,
      (v) => _patch(receiptSocial: v),
    );
    _bindFocusCommit(
      _receiptThankYouFocus,
      _receiptThankYou,
      (v) => _patch(receiptThankYou: v),
    );
    _bindFocusCommit(
      _receiptQrUrlFocus,
      _receiptQrUrl,
      (v) => _patch(receiptQrUrl: v),
    );
    _bindFocusCommit(
      _receiptQrCaptionFocus,
      _receiptQrCaption,
      (v) => _patch(receiptQrCaption: v),
    );

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
      await ref
          .read(venueSettingsProvider.notifier)
          .patch(
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
      title: context.l10n.venueSettingsTitle,
      sub: s.legalName.isEmpty
          ? s.displayName
          : '${s.displayName} · ${s.legalName}',
      children: [
        _venueHero(context, s),
        const SizedBox(height: Sp.s3h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _identityCard(context),
                  const SizedBox(height: Sp.s3h),
                  _receiptCard(context),
                ],
              ),
            ),
            const SizedBox(width: Sp.s3h),
            Padding(
              padding: const EdgeInsets.only(top: Sp.s1),
              child: _receiptPreview(context),
            ),
          ],
        ),
        const SizedBox(height: Sp.s3h),
        _PajakLayananCard(),
        const SizedBox(height: Sp.s3h),
        const SizedBox(height: Sp.s3h),
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
            child: Text(
              context.l10n.venueSettingsTitle,
              style: SatType.h1(color: sc.textHi),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              context.l10n.venueSettingsSubtitle,
              style: SatType.bodyM(color: sc.textMd),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              children: [
                _phoneRow(
                  context,
                  sc,
                  label: context.l10n.venueSettingsSectionIdentity,
                  value: s.displayName,
                  onTap: () => _openDetail(
                    context,
                    context.l10n.venueSettingsSectionIdentity,
                    (c, _) => _identityCard(c),
                  ),
                ),
                _phoneRow(
                  context,
                  sc,
                  label: context.l10n.venueSettingsSectionReceipt,
                  value: _receiptSummary(s),
                  onTap: () => _openDetail(
                    context,
                    context.l10n.venueSettingsSectionReceipt,
                    (c, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _receiptCard(c),
                        const SizedBox(height: Sp.s5),
                        Center(child: _receiptPreview(c)),
                      ],
                    ),
                  ),
                ),
                _phoneRow(
                  context,
                  sc,
                  label: context.l10n.venueSettingsSectionTax,
                  value: _pajakLayananSummary(s),
                  onTap: () => _openDetail(
                    context,
                    context.l10n.venueSettingsSectionTax,
                    (c, _) => _PajakLayananCard(),
                  ),
                ),
                _phoneRow(
                  context,
                  sc,
                  label: context.l10n.venueSettingsSectionReports,
                  value: context.l10n.vstReportsStartAt(
                    s.businessDayStartHour.toString().padLeft(2, '0'),
                  ),
                  onTap: () => _openDetail(
                    context,
                    context.l10n.venueSettingsSectionReports,
                    (c, _) => _ReportsHourCard(),
                  ),
                  last: true,
                ),
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
      padding: const EdgeInsets.all(Sp.s5),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: SatBox.d(color: sc.textHi, borderRadius: SatR.a(14)),
            alignment: Alignment.center,
            child: Text(
              _initials(s.displayName),
              style: SatType.h2(color: sc.bg1),
            ),
          ),
          const SizedBox(width: Sp.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.vstIdentityHead,
                  style: SatType.caption(color: sc.textLo),
                ),
                const SizedBox(height: Sp.s2),
                Text(
                  s.displayName.isEmpty ? '—' : s.displayName,
                  style: SatType.h2(color: sc.textHi),
                ),
                const SizedBox(height: Sp.s1),
                Text(
                  s.legalName.isEmpty
                      ? context.l10n.vstNoLegalName
                      : s.legalName,
                  style: SatType.bodyS(color: sc.textMd),
                ),
                const SizedBox(height: Sp.s2h),
                Text(
                  s.address.isEmpty ? context.l10n.vstNoAddress : s.address,
                  style: SatType.bodyM(color: sc.textMd),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _identityCard(BuildContext context) {
    final s = ref.watch(venueSettingsProvider);
    return _sectionCard(
      context,
      title: context.l10n.venueSettingsSectionIdentity,
      tag: context.l10n.venueSettingsSectionIdentityTag,
      rows: [
        AdminRow(
          label: context.l10n.venueSettingsDisplayName,
          value: _cloudManaged(context, s.displayName),
        ),
        AdminRow(
          label: context.l10n.venueSettingsLegalName,
          value: _editor(
            context,
            controller: _legalName,
            focus: _legalNameFocus,
            hint: context.l10n.vstLegalNameHint,
            onSubmit: (v) => _patch(legalName: v),
          ),
        ),
        AdminRow(
          label: context.l10n.venueSettingsAddress,
          value: _cloudManaged(context, s.address),
        ),
        AdminRow(
          label: context.l10n.venueSettingsPhone,
          value: _editor(
            context,
            controller: _phone,
            focus: _phoneFocus,
            hint: context.l10n.vstPhoneHint,
            mono: true,
            inputType: TextInputType.phone,
            onSubmit: (v) => _patch(phone: v),
          ),
          last: true,
        ),
      ],
    );
  }

  Widget _cloudManaged(BuildContext context, String value) {
    final sc = context.sat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.isEmpty ? '—' : value,
          textAlign: TextAlign.right,
          style: SatType.bodyM(color: sc.textHi),
        ),
        const SizedBox(height: Sp.s1),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 10, color: sc.textLo),
            const SizedBox(width: Sp.s1),
            Text(
              context.l10n.venueSettingsManagedBySuperAdmin,
              style: SatType.bodyS(color: sc.textLo),
            ),
          ],
        ),
      ],
    );
  }

  Widget _receiptCard(BuildContext context) => _sectionCard(
    context,
    title: context.l10n.venueSettingsSectionReceipt,
    tag: context.l10n.venueSettingsSectionReceiptTag,
    rows: [
      AdminRow(
        label: context.l10n.venueSettingsLogo,
        value: _logoTile(context),
      ),
      AdminRow(
        label: context.l10n.venueSettingsTagline,
        value: _editor(
          context,
          controller: _receiptTagline,
          focus: _receiptTaglineFocus,
          hint: context.l10n.vstTaglineHint,
          onSubmit: (v) => _patch(receiptTagline: v),
        ),
      ),
      AdminRow(
        label: context.l10n.venueSettingsHeader,
        value: _editor(
          context,
          controller: _receiptHeader,
          focus: _receiptHeaderFocus,
          hint: context.l10n.vstHeaderHint,
          onSubmit: (v) => _patch(receiptHeader: v),
        ),
      ),
      AdminRow(
        label: context.l10n.venueSettingsSocial,
        value: _editor(
          context,
          controller: _receiptSocial,
          focus: _receiptSocialFocus,
          hint: context.l10n.vstSocialHint,
          onSubmit: (v) => _patch(receiptSocial: v),
        ),
      ),
      AdminRow(
        label: context.l10n.venueSettingsFooter,
        value: _editor(
          context,
          controller: _receiptFooter,
          focus: _receiptFooterFocus,
          hint: context.l10n.vstFooterHint,
          multiline: true,
          onSubmit: (v) => _patch(receiptFooter: v),
        ),
      ),
      AdminRow(
        label: context.l10n.venueSettingsThankYou,
        value: _editor(
          context,
          controller: _receiptThankYou,
          focus: _receiptThankYouFocus,
          hint: context.l10n.vstThankYouHint,
          onSubmit: (v) => _patch(receiptThankYou: v),
        ),
      ),
      AdminRow(
        label: context.l10n.venueSettingsQrUrl,
        value: _editor(
          context,
          controller: _receiptQrUrl,
          focus: _receiptQrUrlFocus,
          hint: context.l10n.vstQrUrlHint,
          mono: true,
          inputType: TextInputType.url,
          onSubmit: (v) => _patch(receiptQrUrl: v),
        ),
      ),
      AdminRow(
        label: context.l10n.venueSettingsQrCaption,
        value: _editor(
          context,
          controller: _receiptQrCaption,
          focus: _receiptQrCaptionFocus,
          hint: context.l10n.vstQrCaptionHint,
          onSubmit: (v) => _patch(receiptQrCaption: v),
        ),
        last: true,
      ),
    ],
  );

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
              decoration: SatBox.d(
                color: sc.bg1,
                border: SatB.all(color: sc.border0),
                borderRadius: SatR.a(8),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: bytes != null
                  ? Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    )
                  : Icon(Icons.storefront_outlined, size: 20, color: sc.textLo),
            ),
            const SizedBox(width: Sp.s2h),
            if (_logoBusy)
              SizedBox(
                width: Sp.s4h,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: sc.accentText,
                ),
              )
            else ...[
              _logoBtn(
                sc,
                bytes == null
                    ? context.l10n.venueSettingsLogoAdd
                    : context.l10n.venueSettingsLogoChange,
                _pickLogo,
              ),
              if (bytes != null) ...[
                const SizedBox(width: Sp.s2),
                _logoBtn(
                  sc,
                  context.l10n.venueSettingsLogoDelete,
                  _clearLogo,
                  danger: true,
                ),
              ],
            ],
          ],
        ),
      ],
    );
  }

  Widget _logoBtn(
    SatColors sc,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final c = danger ? sc.urgent : sc.accentText;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2),
        decoration: SatBox.d(
          color: c.withValues(alpha: 0.10),
          border: SatB.all(color: c.withValues(alpha: 0.4)),
          borderRadius: SatR.a(8),
        ),
        child: Text(label, style: SatType.labelS(color: c)),
      ),
    );
  }

  Future<void> _pickLogo() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
      );
      if (x == null) return;
      setState(() => _logoBusy = true);
      final raw = await x.readAsBytes();
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
      // ignore
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
    return SatField.inline(
      controller: controller,
      focusNode: focus,
      hint: hint,
      multiline: multiline,
      mono: mono,
      keyboard: inputType,
      onSubmitted: onSubmit,
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required String tag,
    required List<Widget> rows,
  }) {
    return SatCard.titled(
      title: title,
      tag: tag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...rows],
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
        decoration: SatBox.d(
          color: sc.bg2,
          border: SatB.all(color: sc.border0),
          borderRadius: SatR.a(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: SatType.labelM(color: sc.textHi)),
                  const SizedBox(height: Sp.sHair),
                  Text(value, style: SatType.bodyS(color: sc.textMd)),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _VenueSettingsPhoneDetail(title: title, builder: builder),
      ),
    );
  }

  String _receiptSummary(VenueSettingsDto s) {
    if (s.receiptHeader.isEmpty && s.receiptFooter.isEmpty) {
      return context.l10n.vstNotSet;
    }
    final h = s.receiptHeader.isEmpty ? '—' : s.receiptHeader;
    final f = s.receiptFooter.isEmpty ? '—' : s.receiptFooter;
    return '$h · $f';
  }

  String _pajakLayananSummary(VenueSettingsDto s) {
    final l10n = context.l10n;
    final tax = s.taxEnabled
        ? l10n.vstTaxOn(_fmtPct(s.taxRateBps))
        : l10n.vstTaxOff;
    final svc = !s.serviceEnabled
        ? l10n.vstServiceOff
        : s.serviceMode == 'fixed'
        ? l10n.vstServiceValue(formatIDR(s.serviceFixedAmount))
        : l10n.vstServiceValue(_fmtPct(s.serviceRateBps));
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
      padding: const EdgeInsets.all(Sp.s5),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.venueSettingsSectionTax,
                  style: SatType.labelL(color: sc.textHi),
                ),
              ),
              Text(
                context.l10n.vstFeesTag,
                style: SatType.caption(color: sc.textLo),
              ),
            ],
          ),
          const SizedBox(height: Sp.s3h),
          _toggleRow(
            context,
            sc,
            label: context.l10n.vstEnableTax,
            on: s.taxEnabled,
            onToggle: () => n.patch(taxEnabled: !s.taxEnabled),
          ),
          if (s.taxEnabled) ...[
            const SizedBox(height: Sp.s2h),
            _bpsStepper(
              context,
              sc,
              label: context.l10n.vstTaxRate,
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
            label: context.l10n.vstEnableService,
            on: s.serviceEnabled,
            onToggle: () => n.patch(serviceEnabled: !s.serviceEnabled),
          ),
          if (s.serviceEnabled) ...[
            const SizedBox(height: Sp.s2h),
            _modeSwitcher(
              context,
              sc,
              mode: s.serviceMode,
              onPick: (m) => n.patch(serviceMode: m),
            ),
            const SizedBox(height: Sp.s2h),
            if (s.serviceMode == 'percent')
              _bpsStepper(
                context,
                sc,
                label: context.l10n.vstServiceRate,
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
                label: context.l10n.vstServiceAmount,
                amount: s.serviceFixedAmount,
                step: 1000,
                min: 0,
                max: 1000000,
                onChange: (v) => n.patch(serviceFixedAmount: v),
              ),
          ],
          Divider(height: 28, color: sc.border0),
          // ADR-0038. Only meaningful once tax or service is on — with both
          // off, both pipelines produce the same total.
          _toggleRow(
            context,
            sc,
            label: context.l10n.vstTaxAfterDiscount,
            on: s.taxAfterDiscount,
            onToggle: () => n.patch(taxAfterDiscount: !s.taxAfterDiscount),
          ),
          const SizedBox(height: Sp.s1h),
          Text(
            s.taxAfterDiscount
                ? context.l10n.vstTaxAfterDiscountOn
                : context.l10n.vstTaxAfterDiscountOff,
            style: SatType.bodyS(color: sc.textLo),
          ),
          const SizedBox(height: Sp.s1),
          Text(
            context.l10n.vstItemDiscountNote,
            style: SatType.bodyS(color: sc.textLo),
          ),
          const SizedBox(height: Sp.s2h),
          // The catalogue itself lives on its own screen — it is list-shaped
          // and edited rarely, so it does not belong inline in settings.
          InkWell(
            onTap: () => context.push('/venue/diskon'),
            borderRadius: SatR.a(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.s2h),
              child: Row(
                children: [
                  Icon(Icons.sell_outlined, size: 18, color: sc.textHi),
                  const SizedBox(width: Sp.s2h),
                  Expanded(
                    child: Text(
                      context.l10n.vstDiscountPresets,
                      style: SatType.bodyM(color: sc.textHi),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: sc.textLo),
                ],
              ),
            ),
          ),
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
          child: Text(label, style: SatType.bodyM(color: sc.textHi)),
        ),
        SatToggle(
          value: on,
          semanticLabel: label,
          onChanged: (_) => onToggle(),
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
          child: Text(
            context.l10n.vstFeeType,
            style: SatType.bodyM(color: sc.textMd),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _modeChip(
                context,
                sc,
                context.l10n.vstFeePercent,
                'percent',
                mode,
                onPick,
              ),
              const SizedBox(width: Sp.s2),
              _modeChip(
                context,
                sc,
                context.l10n.vstFeeFixed,
                'fixed',
                mode,
                onPick,
              ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: Sp.s3h,
          vertical: Sp.s2,
        ),
        decoration: SatBox.d(
          color: on ? sc.accentSoft : sc.bg3,
          border: SatB.all(color: on ? sc.accentBorder : sc.border1),
          borderRadius: SatR.a(999),
        ),
        child: Text(
          label,
          style: SatType.labelS(color: on ? sc.accentText : sc.textMd),
        ),
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
          child: Text(label, style: SatType.bodyM(color: sc.textMd)),
        ),
        Expanded(
          child: Row(
            children: [
              _stepBtn(
                context,
                sc,
                Icons.remove,
                canDown
                    ? () => onChange((valueBps - stepBps).clamp(minBps, maxBps))
                    : null,
              ),
              const SizedBox(width: Sp.s2h),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.s3h,
                  vertical: Sp.s2,
                ),
                decoration: SatBox.d(
                  color: sc.bg3,
                  border: SatB.all(color: sc.border1),
                  borderRadius: SatR.a(10),
                ),
                child: Text(
                  _fmtPct(valueBps),
                  style: SatType.monoM(color: sc.textHi),
                ),
              ),
              const SizedBox(width: Sp.s2h),
              _stepBtn(
                context,
                sc,
                Icons.add,
                canUp
                    ? () => onChange((valueBps + stepBps).clamp(minBps, maxBps))
                    : null,
              ),
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
          child: Text(label, style: SatType.bodyM(color: sc.textMd)),
        ),
        Expanded(
          child: Row(
            children: [
              _stepBtn(
                context,
                sc,
                Icons.remove,
                canDown
                    ? () => onChange((amount - step).clamp(min, max))
                    : null,
              ),
              const SizedBox(width: Sp.s2h),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.s3h,
                  vertical: Sp.s2,
                ),
                decoration: SatBox.d(
                  color: sc.bg3,
                  border: SatB.all(color: sc.border1),
                  borderRadius: SatR.a(10),
                ),
                child: Text(
                  formatIDR(amount),
                  style: SatType.monoM(color: sc.textHi),
                ),
              ),
              const SizedBox(width: Sp.s2h),
              _stepBtn(
                context,
                sc,
                Icons.add,
                canUp ? () => onChange((amount + step).clamp(min, max)) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Delegates to [SatIconButton]: an icon-only target needs a tooltip, and
  /// deriving it from the glyph is how every one of these gets named without
  /// the call sites repeating it.
  Widget _stepBtn(
    BuildContext context,
    SatColors sc,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return SatIconButton.outline(
      icon: icon,
      tooltip: icon == Icons.add
          ? context.l10n.stepperIncrease
          : context.l10n.stepperDecrease,
      size: 36,
      onTap: onTap,
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
    return SatCard.titled(
      title: context.l10n.venueSettingsSectionReports,
      tag: context.l10n.vstReportsTag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Sp.s3h),
          Row(
            children: [
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.vstBusinessDayStart,
                      style: SatType.bodyM(color: sc.textMd),
                    ),
                    const SizedBox(height: Sp.sHair),
                    Text(
                      context.l10n.vstBusinessDayStartHint,
                      style: SatType.bodyS(color: sc.textLo),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    _stepBtn(
                      context,
                      sc,
                      Icons.remove,
                      hour > 0
                          ? () => n.patch(businessDayStartHour: hour - 1)
                          : null,
                    ),
                    const SizedBox(width: Sp.s2h),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sp.s3h,
                        vertical: Sp.s2,
                      ),
                      decoration: SatBox.d(
                        color: sc.bg3,
                        border: SatB.all(color: sc.border1),
                        borderRadius: SatR.a(10),
                      ),
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: SatType.monoM(color: sc.textHi),
                      ),
                    ),
                    const SizedBox(width: Sp.s2h),
                    _stepBtn(
                      context,
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
          // The kitchen target moved to "Waktu & Peringatan" (ADR-0043) — it
          // drives live alerting, not just reporting, and filing it under
          // Laporan hid it from anyone chasing a noise complaint.
        ],
      ),
    );
  }

  /// Delegates to [SatIconButton]: an icon-only target needs a tooltip, and
  /// deriving it from the glyph is how every one of these gets named without
  /// the call sites repeating it.
  Widget _stepBtn(
    BuildContext context,
    SatColors sc,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return SatIconButton.outline(
      icon: icon,
      tooltip: icon == Icons.add
          ? context.l10n.stepperIncrease
          : context.l10n.stepperDecrease,
      size: 36,
      onTap: onTap,
    );
  }
}

class _VenueSettingsPhoneDetail extends StatelessWidget {
  final String title;
  final Widget Function(BuildContext, SatColors) builder;
  const _VenueSettingsPhoneDetail({required this.title, required this.builder});

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
                    tooltip: context.l10n.back,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_rounded, color: sc.textHi),
                  ),
                  Expanded(
                    child: Text(title, style: SatType.h2(color: sc.textHi)),
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
