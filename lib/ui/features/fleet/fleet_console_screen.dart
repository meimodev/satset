import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/fleet_service.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/features/fleet/_fleet_widgets.dart';
import 'package:satset/ui/features/fleet/venue_edit_screen.dart';

/// The super admin's cloud control plane. Reads venues live from Firestore;
/// every mutation goes through a Cloud Function. Lives outside the app shell (a
/// super admin never pairs / runs a local server). See ADR-0016.
///
/// A flat, urgency-sorted list of venue tiles. Tapping a tile opens the
/// [VenueEditScreen] (identity, billing, admins, delete). The only mutation
/// kept on the tile is the kill switch (`⋮` quick-action), to preserve its
/// destructive mid-service friction. There is no admin tab — admins are managed
/// per-venue inside the editor (see CONTEXT.md "Fleet console").
class FleetConsoleScreen extends ConsumerStatefulWidget {
  const FleetConsoleScreen({super.key});

  @override
  ConsumerState<FleetConsoleScreen> createState() => _FleetConsoleScreenState();
}

class _FleetConsoleScreenState extends ConsumerState<FleetConsoleScreen> {
  bool _busy = false;

  FleetService get _svc => ref.read(fleetServiceProvider);

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

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final venues = ref.watch(fleetVenuesProvider);

    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: FleetHeader(
                kicker: 'FLEET',
                title: 'Fleet',
                trailing: IconButton(
                  tooltip: 'Keluar',
                  icon: Icon(Icons.logout, color: sc.textLo),
                  onPressed: () =>
                      ref.read(authStateProvider.notifier).signOut(),
                ),
              ),
            ),
            if (_busy)
              LinearProgressIndicator(minHeight: 2, color: sc.accentText)
            else
              const SizedBox(height: 2),
            Expanded(child: _venueList(sc, venues)),
          ],
        ),
      ),
    );
  }

  Widget _venueList(SatColors sc, AsyncValue<List<Venue>> venues) {
    return venues.when(
      loading: () => Center(child: CircularProgressIndicator(color: sc.accentText)),
      error: (e, _) => _errorBox(sc, e),
      data: (list) {
        // Surface venues nearing the offline-grace lockout first — the SA's job
        // is catching the few in trouble among many; most-urgent (smallest
        // remaining) on top, then the rest alphabetically.
        final sorted = [...list]..sort((a, b) {
            final ra = _lockoutRisk(a), rb = _lockoutRisk(b);
            if ((ra == null) != (rb == null)) return ra != null ? -1 : 1;
            if (ra != null && rb != null && ra != rb) return ra.compareTo(rb);
            return a.name.compareTo(b.name);
          });
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Reveal(
              index: 0,
              child: FleetPrimaryButton(
                label: 'Venue baru',
                icon: Icons.add,
                onTap: _busy ? null : _createVenueDialog,
              ),
            ),
            const SizedBox(height: 14),
            if (sorted.isEmpty)
              _empty(sc, 'Belum ada venue.')
            else
              for (var i = 0; i < sorted.length; i++) ...[
                Reveal(
                  index: i + 1,
                  animKey: sorted[i].id,
                  child: _venueTile(sc, sorted[i]),
                ),
                if (i != sorted.length - 1) const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }

  Widget _venueTile(SatColors sc, Venue v) {
    final vis = fleetStatusVisual(sc, v.status);
    return FleetTile(
      icon: Icons.storefront_outlined,
      tint: vis.tint,
      title: v.name.isEmpty ? '(tanpa nama)' : v.name,
      sub: v.address.isEmpty ? null : v.address,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => VenueEditScreen(venue: v),
      )),
      pills: [
        if (v.status != AdminStatus.active)
          fleetPill(sc, vis.label, vis.tint, vis.soft),
        fleetPill(sc, 'Paket: ${v.plan}', sc.info, sc.infoSoft),
        fleetPill(
            sc,
            'Tagihan: ${v.billingStatus}',
            v.billingStatus == 'overdue' ? sc.urgent : sc.textMd,
            v.billingStatus == 'overdue' ? sc.urgentSoft : sc.bg3),
        fleetPill(sc, _offlineText(v), _offlineColor(sc, v), sc.bg3),
        if (_lockoutRisk(v) case final risk?)
          fleetPill(
            sc,
            _lockoutText(risk),
            risk <= Duration.zero ? sc.urgent : sc.warn,
            risk <= Duration.zero ? sc.urgentSoft : sc.warnSoft,
          ),
      ],
      trailing: fleetMenu(
        sc,
        enabled: !_busy,
        items: {
          if (v.status != AdminStatus.active) 'activate': 'Aktifkan',
          if (v.status != AdminStatus.suspended) 'suspend': 'Tangguhkan (kill)',
          if (v.status != AdminStatus.banned) 'ban': 'Blokir',
        },
        dangerKeys: const {'ban'},
        onSelected: (k) => _onVenueAction(v, k),
      ),
    );
  }

  void _onVenueAction(Venue v, String k) {
    switch (k) {
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
    }
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  Future<void> _createVenueDialog() async {
    final name = TextEditingController();
    final addr = TextEditingController();
    final sc = context.sat;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sc.bg1,
        title: Text('Venue baru',
            style: SatType.sans(size: 17, color: sc.textHi)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama venue')),
            const SizedBox(height: 12),
            TextField(
                controller: addr,
                decoration:
                    const InputDecoration(labelText: 'Alamat (opsional)')),
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
    if (ok != true || name.text.trim().isEmpty) return;
    await _run(() => _svc.createVenue(name: name.text, address: addr.text),
        'Venue dibuat');
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

  // ── Small pieces ───────────────────────────────────────────────────────────

  Widget _empty(SatColors sc, String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(msg, style: SatType.sans(size: 14, color: sc.textLo)),
        ),
      );

  Widget _errorBox(SatColors sc, Object e) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Gagal memuat fleet:\n${fleetErrText(e)}',
              textAlign: TextAlign.center,
              style: SatType.sans(size: 13, color: sc.urgent)),
        ),
      );

  /// The fleet console only flags a venue once it nears the lockout, to avoid
  /// alarming on routine nightly closure.
  static const _fleetLockoutWarn = Duration(hours: 48);

  /// Remaining offline-grace before this venue's next cold boot would be blocked
  /// by the staleness guard. Derived from `lastSeenAt` as a cloud proxy for the
  /// device-local `adminConfirmedAt` (both ride the same heartbeat, so they
  /// freeze together when the venue goes dark). Reuses the same
  /// [FirebaseAdminService.staleAfter] the venue boot gate enforces. Returns
  /// null unless within [_fleetLockoutWarn] of the limit. See CONTEXT.md
  /// "Venue offline duration".
  Duration? _lockoutRisk(Venue v) {
    final last = v.lastSeenAt;
    if (last == null) return null;
    final remaining =
        FirebaseAdminService.staleAfter - DateTime.now().difference(last);
    return remaining <= _fleetLockoutWarn ? remaining : null;
  }

  /// Risk-framed copy: from the cloud the SA cannot tell a venue that closed its
  /// app (will block on restart) from one whose server stayed up but lost
  /// internet (still serving) — so never assert "locked", only the risk.
  String _lockoutText(Duration rem) => rem <= Duration.zero
      ? 'Lewat batas offline — akan terkunci saat restart'
      : 'Mendekati batas offline ${rem.inHours}j';

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
