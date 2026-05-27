import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/layout.dart';
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

  final _displayNameFocus = FocusNode();
  final _legalNameFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _receiptHeaderFocus = FocusNode();
  final _receiptFooterFocus = FocusNode();

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
    if (dn == null &&
        ln == null &&
        ad == null &&
        ph == null &&
        rh == null &&
        rf == null) {
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
  }

  @override
  void dispose() {
    _displayName.dispose();
    _legalName.dispose();
    _address.dispose();
    _phone.dispose();
    _receiptHeader.dispose();
    _receiptFooter.dispose();
    _displayNameFocus.dispose();
    _legalNameFocus.dispose();
    _addressFocus.dispose();
    _phoneFocus.dispose();
    _receiptHeaderFocus.dispose();
    _receiptFooterFocus.dispose();
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
            Expanded(child: _identityCard(context)),
            const SizedBox(width: 14),
            Expanded(child: _receiptCard(context)),
          ],
        ),
        const SizedBox(height: 14),
        _PajakLayananCard(),
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
                    onTap: () => _openDetail(context, 'Branding struk',
                        (c, _) => _receiptCard(c))),
                _phoneRow(context, sc,
                    label: 'Pajak & layanan',
                    value: _pajakLayananSummary(s),
                    onTap: () => _openDetail(context, 'Pajak & layanan',
                        (c, _) => _PajakLayananCard())),
                _phoneRow(context, sc,
                    label: 'Laporan & shift',
                    value:
                        'Hari kerja mulai ${s.businessDayStartHour.toString().padLeft(2, '0')}:00',
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

  Widget _identityCard(BuildContext context) => _sectionCard(
        context,
        title: 'Profil & alamat',
        tag: 'WAJIB',
        rows: [
          AdminRow(
              label: 'Nama tampilan',
              value: _editor(context,
                  controller: _displayName,
                  focus: _displayNameFocus,
                  hint: 'Warung …',
                  onSubmit: (v) => _patch(displayName: v))),
          AdminRow(
              label: 'Nama legal',
              value: _editor(context,
                  controller: _legalName,
                  focus: _legalNameFocus,
                  hint: 'PT …',
                  onSubmit: (v) => _patch(legalName: v))),
          AdminRow(
              label: 'Alamat',
              value: _editor(context,
                  controller: _address,
                  focus: _addressFocus,
                  hint: 'Jalan, kota, kode pos',
                  multiline: true,
                  onSubmit: (v) => _patch(address: v))),
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

  Widget _receiptCard(BuildContext context) => _sectionCard(
        context,
        title: 'Branding struk',
        tag: 'CETAK',
        rows: [
          AdminRow(
              label: 'Header',
              value: _editor(context,
                  controller: _receiptHeader,
                  focus: _receiptHeaderFocus,
                  hint: 'Tampil di atas struk',
                  onSubmit: (v) => _patch(receiptHeader: v))),
          AdminRow(
              label: 'Footer',
              value: _editor(context,
                  controller: _receiptFooter,
                  focus: _receiptFooterFocus,
                  hint: 'Tampil di bawah struk',
                  multiline: true,
                  onSubmit: (v) => _patch(receiptFooter: v)),
              last: true),
        ],
      );

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
