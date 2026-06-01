import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/fleet_service.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

/// The super admin's cloud control plane. Reads venues + admins live from
/// Firestore; every mutation goes through a Cloud Function. Lives outside the
/// app shell (a super admin never pairs / runs a local server). See ADR-0016.
class FleetConsoleScreen extends ConsumerStatefulWidget {
  const FleetConsoleScreen({super.key});

  @override
  ConsumerState<FleetConsoleScreen> createState() => _FleetConsoleScreenState();
}

class _FleetConsoleScreenState extends ConsumerState<FleetConsoleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  bool _busy = false;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  FleetService get _svc => ref.read(fleetServiceProvider);

  Future<void> _run(Future<void> Function() action, String okMsg) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      _toast(okMsg);
    } catch (e) {
      _toast(_errText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    final sc = context.sat;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: SatType.sans(size: 13, color: sc.textHi)),
        backgroundColor: error ? sc.urgentSoft : sc.bg3,
      ));
  }

  String _errText(Object e) {
    final s = e.toString();
    return s.contains(']') ? s.split(']').last.trim() : s;
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final venues = ref.watch(fleetVenuesProvider);
    final admins = ref.watch(fleetAdminsProvider);

    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(sc),
            if (_busy) LinearProgressIndicator(minHeight: 2, color: sc.accent),
            TabBar(
              controller: _tabs,
              labelColor: sc.textHi,
              unselectedLabelColor: sc.textLo,
              indicatorColor: sc.accent,
              labelStyle: SatType.sans(size: 13, weight: FontWeight.w600),
              tabs: const [Tab(text: 'Venue'), Tab(text: 'Admin')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _venuesTab(sc, venues),
                  _adminsTab(sc, venues, admins),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(SatColors sc) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FLEET',
                      style: SatType.mono(
                          size: 11,
                          weight: FontWeight.w700,
                          letterSpacing: 2,
                          color: sc.accent)),
                  const SizedBox(height: 2),
                  Text('Kontrol venue & admin',
                      style: SatType.sans(
                          size: 19,
                          weight: FontWeight.w600,
                          color: sc.textHi)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Keluar',
              icon: Icon(Icons.logout, color: sc.textLo),
              onPressed: () =>
                  ref.read(authStateProvider.notifier).signOut(),
            ),
          ],
        ),
      );

  // ── Venues ─────────────────────────────────────────────────────────────────

  Widget _venuesTab(SatColors sc, AsyncValue<List<Venue>> venues) {
    return venues.when(
      loading: () => Center(child: CircularProgressIndicator(color: sc.accent)),
      error: (e, _) => _errorBox(sc, e),
      data: (list) {
        final sorted = [...list]..sort((a, b) => a.name.compareTo(b.name));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: sc.accent),
              onPressed: _busy ? null : _createVenueDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Venue baru'),
            ),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              _empty(sc, 'Belum ada venue.')
            else
              for (final v in sorted) _venueCard(sc, v),
          ],
        );
      },
    );
  }

  Widget _venueCard(SatColors sc, Venue v) {
    return _card(
      sc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(v.name.isEmpty ? '(tanpa nama)' : v.name,
                    style: SatType.sans(
                        size: 16, weight: FontWeight.w600, color: sc.textHi)),
              ),
              _statusChip(sc, v.status),
              _menu(
                sc,
                items: {
                  'billing': 'Kelola billing',
                  if (v.status != AdminStatus.active) 'activate': 'Aktifkan',
                  if (v.status != AdminStatus.suspended)
                    'suspend': 'Tangguhkan (kill)',
                  if (v.status != AdminStatus.banned) 'ban': 'Blokir',
                  'add': 'Tambah admin',
                  'delete': 'Hapus venue',
                },
                onSelected: (k) => _onVenueAction(v, k),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _pill(sc, 'Paket: ${v.plan}', sc.info, sc.infoSoft),
            _pill(sc, 'Tagihan: ${v.billingStatus}',
                v.billingStatus == 'overdue' ? sc.urgent : sc.textMd,
                v.billingStatus == 'overdue' ? sc.urgentSoft : sc.bg3),
            _pill(sc, _offlineText(v), _offlineColor(sc, v), sc.bg3),
          ]),
        ],
      ),
    );
  }

  void _onVenueAction(Venue v, String k) {
    switch (k) {
      case 'billing':
        _billingDialog(v);
      case 'activate':
        _run(() => _svc.setVenueStatus(v.id, AdminStatus.active),
            '${v.name} diaktifkan');
      case 'suspend':
        _confirm('Tangguhkan ${v.name}?',
            'Server venue mati & semua staf terputus.',
            () => _run(() => _svc.setVenueStatus(v.id, AdminStatus.suspended),
                '${v.name} ditangguhkan'));
      case 'ban':
        _confirm('Blokir ${v.name}?', 'Venue diblokir permanen sampai diubah.',
            () => _run(() => _svc.setVenueStatus(v.id, AdminStatus.banned),
                '${v.name} diblokir'));
      case 'add':
        _createAdminDialog(v);
      case 'delete':
        _confirm('Hapus ${v.name}?', 'Venue harus tanpa admin dulu.',
            () => _run(() => _svc.deleteVenue(v.id), '${v.name} dihapus'));
    }
  }

  // ── Admins ─────────────────────────────────────────────────────────────────

  Widget _adminsTab(SatColors sc, AsyncValue<List<Venue>> venues,
      AsyncValue<List<AdminProfile>> admins) {
    return admins.when(
      loading: () => Center(child: CircularProgressIndicator(color: sc.accent)),
      error: (e, _) => _errorBox(sc, e),
      data: (list) {
        final venueName = {
          for (final v in venues.valueOrNull ?? const <Venue>[]) v.id: v.name,
        };
        final ops = [...list.where((a) => a.role == AdminRole.admin)]
          ..sort((a, b) => a.name.compareTo(b.name));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (ops.isEmpty)
              _empty(sc, 'Belum ada admin. Tambah dari kartu venue.')
            else
              for (final a in ops) _adminCard(sc, a, venueName[a.venueId]),
          ],
        );
      },
    );
  }

  Widget _adminCard(SatColors sc, AdminProfile a, String? venueName) {
    return _card(
      sc,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name.isEmpty ? '(tanpa nama)' : a.name,
                    style: SatType.sans(
                        size: 15, weight: FontWeight.w600, color: sc.textHi)),
                const SizedBox(height: 2),
                Text(a.email ?? a.uid,
                    style: SatType.mono(size: 11, color: sc.textLo)),
                const SizedBox(height: 2),
                Text('Venue: ${venueName ?? a.venueId}',
                    style: SatType.sans(size: 12, color: sc.textMd)),
              ],
            ),
          ),
          _statusChip(sc, a.status),
          _menu(
            sc,
            items: {
              if (a.status != AdminStatus.active) 'activate': 'Aktifkan',
              if (a.status != AdminStatus.suspended) 'suspend': 'Tangguhkan',
              if (a.status != AdminStatus.banned) 'ban': 'Blokir',
              if (a.email != null) 'reset': 'Reset password',
              'delete': 'Hapus',
            },
            onSelected: (k) => _onAdminAction(a, k),
          ),
        ],
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
        _run(() async {
          await _svc.resetAdminPassword(a.email!);
        }, 'Link reset dibuat untuk ${a.email}');
      case 'delete':
        _confirm('Hapus ${a.name}?', 'Akun login & datanya dihapus permanen.',
            () => _run(() => _svc.deleteAdmin(a.uid), '${a.name} dihapus'));
    }
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  Future<void> _createVenueDialog() async {
    final name = TextEditingController();
    final addr = TextEditingController();
    final ok = await _formDialog('Venue baru', [
      _field(name, 'Nama venue'),
      _field(addr, 'Alamat (opsional)'),
    ]);
    if (ok != true || name.text.trim().isEmpty) return;
    await _run(() => _svc.createVenue(name: name.text, address: addr.text),
        'Venue dibuat');
  }

  Future<void> _createAdminDialog(Venue v) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final pw = TextEditingController();
    final ok = await _formDialog('Tambah admin · ${v.name}', [
      _field(name, 'Nama'),
      _field(email, 'Email'),
      _field(pw, 'Password awal'),
    ]);
    if (ok != true ||
        name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        pw.text.trim().isEmpty) {
      return;
    }
    await _run(
        () => _svc.createAdmin(
            email: email.text, password: pw.text, name: name.text, venueId: v.id),
        'Admin dibuat');
  }

  Future<void> _billingDialog(Venue v) async {
    final plan = TextEditingController(text: v.plan);
    var status = v.billingStatus;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final sc = ctx.sat;
        return StatefulBuilder(builder: (ctx, setSt) {
          return AlertDialog(
            backgroundColor: sc.bg1,
            title: Text('Billing · ${v.name}',
                style: SatType.sans(size: 17, color: sc.textHi)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(plan, 'Paket'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status tagihan'),
                  items: const [
                    DropdownMenuItem(value: 'trial', child: Text('trial')),
                    DropdownMenuItem(value: 'paid', child: Text('paid')),
                    DropdownMenuItem(value: 'overdue', child: Text('overdue')),
                  ],
                  onChanged: (x) => setSt(() => status = x ?? status),
                ),
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
          );
        });
      },
    );
    if (ok != true) return;
    await _run(
        () => _svc.setVenueBilling(v.id,
            plan: plan.text.trim(), billingStatus: status),
        'Billing diperbarui');
  }

  Future<bool?> _formDialog(String title, List<Widget> fields) {
    final sc = context.sat;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sc.bg1,
        title: Text(title, style: SatType.sans(size: 17, color: sc.textHi)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in fields) ...[f, const SizedBox(height: 12)],
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
  }

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

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
        decoration: InputDecoration(labelText: label),
      );

  // ── Small pieces ───────────────────────────────────────────────────────────

  Widget _card(SatColors sc, {required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: sc.bg1,
          border: Border.all(color: sc.border0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      );

  Widget _statusChip(SatColors sc, AdminStatus s) {
    final (label, fg, bg) = switch (s) {
      AdminStatus.active => ('AKTIF', sc.success, sc.successSoft),
      AdminStatus.suspended => ('TANGGUH', sc.warn, sc.warnSoft),
      AdminStatus.banned => ('BLOKIR', sc.urgent, sc.urgentSoft),
      AdminStatus.unknown => ('?', sc.textLo, sc.bg3),
    };
    return _pill(sc, label, fg, bg);
  }

  Widget _pill(SatColors sc, String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text,
            style: SatType.mono(
                size: 10, weight: FontWeight.w700, color: fg)),
      );

  Widget _menu(SatColors sc,
          {required Map<String, String> items,
          required ValueChanged<String> onSelected}) =>
      PopupMenuButton<String>(
        enabled: !_busy,
        icon: Icon(Icons.more_vert, color: sc.textLo),
        color: sc.bg2,
        onSelected: onSelected,
        itemBuilder: (_) => [
          for (final e in items.entries)
            PopupMenuItem(
              value: e.key,
              child: Text(e.value,
                  style: SatType.sans(
                      size: 13,
                      color: e.key == 'delete' || e.key == 'ban'
                          ? sc.urgent
                          : sc.textHi)),
            ),
        ],
      );

  Widget _empty(SatColors sc, String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(msg, style: SatType.sans(size: 14, color: sc.textLo)),
        ),
      );

  Widget _errorBox(SatColors sc, Object e) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Gagal memuat fleet:\n${_errText(e)}',
              textAlign: TextAlign.center,
              style: SatType.sans(size: 13, color: sc.urgent)),
        ),
      );

  String _offlineText(Venue v) {
    final last = v.lastSeenAt;
    if (last == null) return 'Belum online';
    final d = DateTime.now().difference(last);
    if (d.inSeconds < 90) return 'Online';
    if (d.inMinutes < 60) return 'Offline ${d.inMinutes}m';
    if (d.inHours < 24) return 'Offline ${d.inHours}j';
    return 'Offline ${d.inDays}h';
  }

  Color _offlineColor(SatColors sc, Venue v) {
    final last = v.lastSeenAt;
    if (last == null) return sc.textLo;
    return DateTime.now().difference(last).inSeconds < 90
        ? sc.success
        : sc.warn;
  }
}
