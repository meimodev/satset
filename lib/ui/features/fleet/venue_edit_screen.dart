import 'package:flutter/material.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/fleet_service.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/fleet/_fleet_widgets.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// Per-venue management surface, opened from a Fleet console tile. Owns this
/// venue's identity (name/address, cloud source of truth per ADR-0018),
/// billing (plan/billingStatus/paidUntil), its **admins** (the per-venue admin
/// list — add/status/reset/delete; there is no fleet-wide admin roster), and
/// venue delete. The kill switch (`status`) is deliberately NOT here: it stays a
/// guarded quick-action on the venue tile so its destructive mid-service
/// friction is preserved.
///
/// Identity/billing Save diffs each group and fires only the callables whose
/// fields changed: `updateVenue` for name/address, `setVenueBilling` for
/// billing. Admin actions fire immediately (no Save gate). The admin list is
/// watched live, so additions/removals appear without reopening — and the
/// delete-venue guard re-enables the instant the last admin is removed.
class VenueEditScreen extends ConsumerStatefulWidget {
  const VenueEditScreen({super.key, required this.venue});

  final Venue venue;

  @override
  ConsumerState<VenueEditScreen> createState() => _VenueEditScreenState();
}

class _VenueEditScreenState extends ConsumerState<VenueEditScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.venue.name,
  );
  late final TextEditingController _address = TextEditingController(
    text: widget.venue.address,
  );
  late final TextEditingController _plan = TextEditingController(
    text: widget.venue.plan,
  );

  late String _billingStatus = _normBilling(widget.venue.billingStatus);
  late DateTime? _paidUntil = widget.venue.paidUntil;

  bool _busy = false;

  static String _normBilling(String s) =>
      const {'trial', 'paid', 'overdue'}.contains(s) ? s : 'trial';

  FleetService get _svc => ref.read(fleetServiceProvider);

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _plan.dispose();
    super.dispose();
  }

  String get _nameText => _name.text.trim();
  bool get _nameValid => _nameText.isNotEmpty;

  /// Runs a one-shot admin/venue mutation with the shared busy + toast cycle.
  Future<void> _run(Future<void> Function() action, String okMsg) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) fleetToast(context, okMsg);
    } catch (e) {
      if (mounted) fleetToast(context, fleetErrText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || !_nameValid) return;
    final v = widget.venue;

    final newName = _nameText;
    final newAddress = _address.text.trim();
    final newPlan = _plan.text.trim();

    final nameChanged = newName != v.name;
    final addressChanged = newAddress != v.address;
    final planChanged = newPlan != v.plan;
    final billingStatusChanged =
        _billingStatus != _normBilling(v.billingStatus);
    final paidUntilChanged = _paidUntil != v.paidUntil;

    if (!nameChanged &&
        !addressChanged &&
        !planChanged &&
        !billingStatusChanged &&
        !paidUntilChanged) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _busy = true);
    try {
      if (nameChanged || addressChanged) {
        await _svc.updateVenue(
          v.id,
          name: nameChanged ? newName : null,
          address: addressChanged ? newAddress : null,
        );
      }
      if (planChanged || billingStatusChanged || paidUntilChanged) {
        await _svc.setVenueBilling(
          v.id,
          plan: planChanged ? newPlan : null,
          billingStatus: billingStatusChanged ? _billingStatus : null,
          paidUntil: paidUntilChanged ? _paidUntil : null,
          clearPaidUntil: paidUntilChanged && _paidUntil == null,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      fleetToast(context, fleetErrText(e), error: true);
    }
  }

  Future<void> _pickPaidUntil() async {
    final now = SatClock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidUntil ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _paidUntil = picked);
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final v = widget.venue;
    // Live per-venue admin list — drives both the ADMIN section and the
    // delete-venue guard (delete needs zero admins).
    final admins = ref.watch(fleetAdminsProvider);
    final forVenue = (admins.valueOrNull ?? const <AdminProfile>[])
        .where((a) => a.venueId == v.id)
        .toList();
    final venueAdmins =
        forVenue.where((a) => a.role == AdminRole.admin).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    // Owners (read-only report viewers, ADR-0036) are listed separately and
    // also block venue delete — a venue with anyone attached can't be deleted.
    final venueOwners =
        forVenue.where((a) => a.role == AdminRole.owner).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: sc.bg0,
      appBar: AppBar(
        backgroundColor: sc.bg0,
        elevation: 0,
        iconTheme: IconThemeData(color: sc.textHi),
        title: Text(
          'Edit venue',
          style: SatType.sans(
            size: 18,
            weight: FontWeight.w600,
            color: sc.textHi,
          ),
        ),
        actions: [
          SatButton.ghost(
            label: AppStrings.save,
            onTap: _busy || !_nameValid ? null : _save,
          ),
        ],
        bottom: _busy
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: sc.accentText,
                ),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          _sectionLabel(sc, 'IDENTITAS'),
          const SizedBox(height: Sp.s2h),
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Nama venue',
              errorText: _nameValid ? null : 'Nama wajib diisi',
            ),
          ),
          const SizedBox(height: Sp.s3h),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Alamat (opsional)'),
          ),
          const SizedBox(height: 28),
          _sectionLabel(sc, 'TAGIHAN'),
          const SizedBox(height: Sp.s2h),
          TextField(
            controller: _plan,
            decoration: const InputDecoration(labelText: 'Paket'),
          ),
          const SizedBox(height: Sp.s3h),
          DropdownButtonFormField<String>(
            initialValue: _billingStatus,
            decoration: const InputDecoration(labelText: 'Status tagihan'),
            items: const [
              DropdownMenuItem(value: 'trial', child: Text('trial')),
              DropdownMenuItem(value: 'paid', child: Text('paid')),
              DropdownMenuItem(value: 'overdue', child: Text('overdue')),
            ],
            onChanged: (x) =>
                setState(() => _billingStatus = x ?? _billingStatus),
          ),
          const SizedBox(height: Sp.s3h),
          _paidUntilRow(sc),
          const SizedBox(height: 28),
          _principalSection(
            sc,
            admins,
            venueAdmins,
            role: 'admin',
            label: 'ADMIN',
            addLabel: 'Tambah admin',
            emptyMsg: 'Belum ada admin untuk venue ini.',
          ),
          const SizedBox(height: 28),
          _principalSection(
            sc,
            admins,
            venueOwners,
            role: 'owner',
            label: 'PEMILIK (LAPORAN)',
            addLabel: 'Tambah pemilik',
            emptyMsg: 'Belum ada pemilik untuk venue ini.',
          ),
          const SizedBox(height: Sp.s8),
          _dangerZone(sc, [...venueAdmins, ...venueOwners]),
        ],
      ),
    );
  }

  // ── Admins ───────────────────────────────────────────────────────────────

  Widget _principalSection(
    SatColors sc,
    AsyncValue<List<AdminProfile>> all,
    List<AdminProfile> rows, {
    required String role,
    required String label,
    required String addLabel,
    required String emptyMsg,
  }) {
    final loading = all.isLoading && !all.hasValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(sc, label),
        const SizedBox(height: Sp.s2h),
        FleetPrimaryButton(
          label: addLabel,
          icon: Icons.person_add_alt_1,
          onTap: _busy ? null : () => _createPrincipalDialog(role),
        ),
        const SizedBox(height: Sp.s3),
        if (all.hasError)
          Text(
            'Gagal memuat: ${fleetErrText(all.error!)}',
            style: SatType.sans(size: 12, color: sc.urgent),
          )
        else if (loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Sp.s5),
            child: Center(
              child: CircularProgressIndicator(color: sc.accentText),
            ),
          )
        else if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Sp.s3h),
            child: Text(
              emptyMsg,
              style: SatType.sans(size: 13, color: sc.textLo),
            ),
          )
        else
          for (var i = 0; i < rows.length; i++) ...[
            _adminRow(sc, rows[i]),
            if (i != rows.length - 1) const SizedBox(height: Sp.s2),
          ],
      ],
    );
  }

  Widget _adminRow(SatColors sc, AdminProfile a) {
    final vis = fleetStatusVisual(sc, a.status);
    return FleetTile(
      big: false,
      icon: Icons.person_outline_rounded,
      tint: vis.tint,
      title: a.name.isEmpty ? '(tanpa nama)' : a.name,
      sub: a.email ?? a.uid,
      subMono: true,
      pills: [
        if (a.status != AdminStatus.active)
          fleetPill(sc, vis.label, vis.tint, vis.soft),
      ],
      trailing: fleetMenu(
        sc,
        enabled: !_busy,
        items: {
          if (a.status != AdminStatus.active) 'activate': 'Aktifkan',
          if (a.status != AdminStatus.suspended) 'suspend': 'Tangguhkan',
          if (a.status != AdminStatus.banned) 'ban': 'Blokir',
          if (a.email != null) 'reset': 'Reset password',
          'delete': 'Hapus',
        },
        dangerKeys: const {'ban', 'delete'},
        onSelected: (k) => _onAdminAction(a, k),
      ),
    );
  }

  void _onAdminAction(AdminProfile a, String k) {
    switch (k) {
      case 'activate':
        _run(
          () => _svc.setAdminStatus(a.uid, AdminStatus.active),
          '${a.name} diaktifkan',
        );
      case 'suspend':
        _run(
          () => _svc.setAdminStatus(a.uid, AdminStatus.suspended),
          '${a.name} ditangguhkan',
        );
      case 'ban':
        _run(
          () => _svc.setAdminStatus(a.uid, AdminStatus.banned),
          '${a.name} diblokir',
        );
      case 'reset':
        _run(
          () => _svc.resetAdminPassword(a.email!),
          'Link reset dibuat untuk ${a.email}',
        );
      case 'delete':
        _confirm(
          'Hapus ${a.name}?',
          'Akun login & datanya dihapus permanen.',
          () => _run(() => _svc.deleteAdmin(a.uid), '${a.name} dihapus'),
        );
    }
  }

  Future<void> _createPrincipalDialog(String role) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final pw = TextEditingController();
    final sc = context.sat;
    final roleLabel = role == 'owner' ? 'pemilik' : 'admin';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sc.bg1,
        title: Text(
          'Tambah $roleLabel · ${widget.venue.name}',
          style: SatType.sans(size: 17, color: sc.textHi),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: Sp.s3),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: Sp.s3),
            TextField(
              controller: pw,
              decoration: const InputDecoration(labelText: 'Password awal'),
            ),
          ],
        ),
        actions: [
          SatButton.ghost(
            label: AppStrings.cancel,
            onTap: () => Navigator.pop(ctx, false),
          ),
          SatButton.primary(
            label: AppStrings.save,
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true ||
        name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        pw.text.trim().isEmpty) {
      return;
    }
    await _run(
      () => _svc.createAdmin(
        email: email.text,
        password: pw.text,
        name: name.text,
        venueId: widget.venue.id,
        role: role,
      ),
      '${role == 'owner' ? 'Pemilik' : 'Admin'} dibuat',
    );
  }

  // ── Danger zone ────────────────────────────────────────────────────────────

  Widget _dangerZone(SatColors sc, List<AdminProfile> admins) {
    final blocked = admins.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: SatBox.d(
        color: sc.urgentSoft,
        border: SatB.all(color: sc.urgent),
        borderRadius: SatR.a(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ZONA BAHAYA',
            style: SatType.mono(
              size: 11,
              weight: FontWeight.w700,
              letterSpacing: 2,
              color: sc.urgent,
            ),
          ),
          const SizedBox(height: Sp.s2h),
          Text(
            blocked
                ? 'Hapus semua admin venue ini dulu sebelum menghapus venue.'
                : 'Menghapus venue tidak dapat dibatalkan.',
            style: SatType.sans(size: 13, color: sc.textMd, height: 1.4),
          ),
          const SizedBox(height: Sp.s3h),
          Material(
            color: blocked || _busy ? sc.bg3 : sc.urgent,
            borderRadius: SatR.a(12),
            child: InkWell(
              onTap: blocked || _busy ? null : _confirmDeleteVenue,
              borderRadius: SatR.a(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: Sp.s3),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: blocked || _busy ? sc.textLo : sc.bg0,
                    ),
                    const SizedBox(width: Sp.s2),
                    Text(
                      'Hapus venue',
                      style: SatType.sans(
                        size: 14,
                        weight: FontWeight.w700,
                        color: blocked || _busy ? sc.textLo : sc.bg0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVenue() {
    final v = widget.venue;
    _confirm('Hapus ${v.name}?', 'Venue dihapus permanen.', () async {
      await _run(() => _svc.deleteVenue(v.id), '${v.name} dihapus');
      if (mounted) Navigator.of(context).pop();
    });
  }

  // ── Small pieces ───────────────────────────────────────────────────────────

  void _confirm(String title, String body, VoidCallback onYes) {
    final sc = context.sat;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sc.bg1,
        title: Text(title, style: SatType.sans(size: 17, color: sc.textHi)),
        content: Text(body, style: SatType.sans(size: 14, color: sc.textMd)),
        actions: [
          SatButton.ghost(
            label: AppStrings.cancel,
            onTap: () => Navigator.pop(ctx),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: sc.urgent),
            onPressed: () {
              Navigator.pop(ctx);
              onYes();
            },
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(SatColors sc, String text) => Text(
    text,
    style: SatType.mono(
      size: 11,
      weight: FontWeight.w700,
      letterSpacing: 2,
      color: sc.accentText,
    ),
  );

  Widget _paidUntilRow(SatColors sc) {
    final p = _paidUntil;
    final label = p == null
        ? 'Belum diatur'
        : '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: SatBox.d(
        color: sc.bg1,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Berlaku sampai (paidUntil)',
                  style: SatType.sans(size: 12, color: sc.textMd),
                ),
                const SizedBox(height: Sp.sHair),
                Text(
                  label,
                  style: SatType.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: sc.textHi,
                  ),
                ),
              ],
            ),
          ),
          if (p != null)
            IconButton(
              tooltip: 'Hapus tanggal',
              icon: Icon(Icons.clear, color: sc.textLo, size: 20),
              onPressed: () => setState(() => _paidUntil = null),
            ),
          SatButton.ghost(label: 'Pilih', onTap: _pickPaidUntil),
        ],
      ),
    );
  }
}
