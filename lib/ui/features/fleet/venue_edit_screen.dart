import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/fleet_service.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/fleet/_fleet_widgets.dart';

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
  late final TextEditingController _name =
      TextEditingController(text: widget.venue.name);
  late final TextEditingController _address =
      TextEditingController(text: widget.venue.address);
  late final TextEditingController _plan =
      TextEditingController(text: widget.venue.plan);

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
    final billingStatusChanged = _billingStatus != _normBilling(v.billingStatus);
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
    final now = DateTime.now();
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
    final venueAdmins = (admins.valueOrNull ?? const <AdminProfile>[])
        .where((a) => a.venueId == v.id && a.role == AdminRole.admin)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: sc.bg0,
      appBar: AppBar(
        backgroundColor: sc.bg0,
        elevation: 0,
        iconTheme: IconThemeData(color: sc.textHi),
        title: Text('Edit venue',
            style: SatType.sans(
                size: 18, weight: FontWeight.w600, color: sc.textHi)),
        actions: [
          TextButton(
            onPressed: _busy || !_nameValid ? null : _save,
            child: Text('Simpan',
                style: SatType.sans(
                    size: 14,
                    weight: FontWeight.w700,
                    color: _busy || !_nameValid ? sc.textLo : sc.accent)),
          ),
        ],
        bottom: _busy
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2, color: sc.accent),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          _sectionLabel(sc, 'IDENTITAS'),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Nama venue',
              errorText: _nameValid ? null : 'Nama wajib diisi',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Alamat (opsional)'),
          ),
          const SizedBox(height: 28),
          _sectionLabel(sc, 'TAGIHAN'),
          const SizedBox(height: 10),
          TextField(
            controller: _plan,
            decoration: const InputDecoration(labelText: 'Paket'),
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          _paidUntilRow(sc),
          const SizedBox(height: 28),
          _adminSection(sc, admins, venueAdmins),
          const SizedBox(height: 32),
          _dangerZone(sc, venueAdmins),
        ],
      ),
    );
  }

  // ── Admins ───────────────────────────────────────────────────────────────

  Widget _adminSection(SatColors sc, AsyncValue<List<AdminProfile>> all,
      List<AdminProfile> admins) {
    final loading = all.isLoading && !all.hasValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(sc, 'ADMIN'),
        const SizedBox(height: 10),
        FleetPrimaryButton(
          label: 'Tambah admin',
          icon: Icons.person_add_alt_1,
          onTap: _busy ? null : _createAdminDialog,
        ),
        const SizedBox(height: 12),
        if (all.hasError)
          Text('Gagal memuat admin: ${fleetErrText(all.error!)}',
              style: SatType.sans(size: 12, color: sc.urgent))
        else if (loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
                child: CircularProgressIndicator(color: sc.accent)),
          )
        else if (admins.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text('Belum ada admin untuk venue ini.',
                style: SatType.sans(size: 13, color: sc.textLo)),
          )
        else
          for (var i = 0; i < admins.length; i++) ...[
            _adminRow(sc, admins[i]),
            if (i != admins.length - 1) const SizedBox(height: 8),
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
        _run(() => _svc.setAdminStatus(a.uid, AdminStatus.active),
            '${a.name} diaktifkan');
      case 'suspend':
        _run(() => _svc.setAdminStatus(a.uid, AdminStatus.suspended),
            '${a.name} ditangguhkan');
      case 'ban':
        _run(() => _svc.setAdminStatus(a.uid, AdminStatus.banned),
            '${a.name} diblokir');
      case 'reset':
        _run(() => _svc.resetAdminPassword(a.email!),
            'Link reset dibuat untuk ${a.email}');
      case 'delete':
        _confirm('Hapus ${a.name}?', 'Akun login & datanya dihapus permanen.',
            () => _run(() => _svc.deleteAdmin(a.uid), '${a.name} dihapus'));
    }
  }

  Future<void> _createAdminDialog() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final pw = TextEditingController();
    final sc = context.sat;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sc.bg1,
        title: Text('Tambah admin · ${widget.venue.name}',
            style: SatType.sans(size: 17, color: sc.textHi)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama')),
            const SizedBox(height: 12),
            TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(
                controller: pw,
                decoration:
                    const InputDecoration(labelText: 'Password awal')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan')),
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
            venueId: widget.venue.id),
        'Admin dibuat');
  }

  // ── Danger zone ────────────────────────────────────────────────────────────

  Widget _dangerZone(SatColors sc, List<AdminProfile> admins) {
    final blocked = admins.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: sc.urgentSoft,
        border: Border.all(color: sc.urgent),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ZONA BAHAYA',
              style: SatType.mono(
                  size: 11,
                  weight: FontWeight.w700,
                  letterSpacing: 2,
                  color: sc.urgent)),
          const SizedBox(height: 10),
          Text(
            blocked
                ? 'Hapus semua admin venue ini dulu sebelum menghapus venue.'
                : 'Menghapus venue tidak dapat dibatalkan.',
            style: SatType.sans(size: 13, color: sc.textMd, height: 1.4),
          ),
          const SizedBox(height: 14),
          Material(
            color: blocked || _busy ? sc.bg3 : sc.urgent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: blocked || _busy ? null : _confirmDeleteVenue,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18,
                        color: blocked || _busy ? sc.textLo : sc.bg0),
                    const SizedBox(width: 8),
                    Text('Hapus venue',
                        style: SatType.sans(
                            size: 14,
                            weight: FontWeight.w700,
                            color: blocked || _busy ? sc.textLo : sc.bg0)),
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
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
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

  Widget _sectionLabel(SatColors sc, String text) => Text(text,
      style: SatType.mono(
          size: 11, weight: FontWeight.w700, letterSpacing: 2, color: sc.accent));

  Widget _paidUntilRow(SatColors sc) {
    final p = _paidUntil;
    final label = p == null
        ? 'Belum diatur'
        : '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: sc.bg1,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Berlaku sampai (paidUntil)',
                    style: SatType.sans(size: 12, color: sc.textMd)),
                const SizedBox(height: 2),
                Text(label,
                    style: SatType.sans(
                        size: 15, weight: FontWeight.w600, color: sc.textHi)),
              ],
            ),
          ),
          if (p != null)
            IconButton(
              tooltip: 'Hapus tanggal',
              icon: Icon(Icons.clear, color: sc.textLo, size: 20),
              onPressed: () => setState(() => _paidUntil = null),
            ),
          TextButton(
            onPressed: _pickPaidUntil,
            child: Text('Pilih',
                style: SatType.sans(
                    size: 14, weight: FontWeight.w600, color: sc.accent)),
          ),
        ],
      ),
    );
  }
}
