import 'dart:async';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/owner_report_service.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/admin/report_sections_view.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// Read-only, off-site report view for an [[Owner]] (ADR-0036). Diverts here at
/// login (`role == 'owner'`), reads the host-published snapshot from
/// `reports/{vid}`, and offers a cloud-mediated manual refresh. No live data,
/// no filters, no mutations — a glanceable summary of the venue's published
/// report. Full analyst parity stays on the on-site Admin → Reports screen.
class OwnerReportScreen extends ConsumerStatefulWidget {
  const OwnerReportScreen({super.key});

  @override
  ConsumerState<OwnerReportScreen> createState() => _OwnerReportScreenState();
}

class _OwnerReportScreenState extends ConsumerState<OwnerReportScreen> {
  String _range = 'today';

  /// When the owner last tapped refresh — debounces the button (~30s) and lets
  /// us show a "pending" state until a newer snapshot lands.
  DateTime? _refreshTappedAt;

  static const _refreshCooldown = Duration(seconds: 30);

  static const _rangeLabel = {'today': 'Hari ini', 'd7': '7 hari'};

  Future<void> _refresh(String vid) async {
    final now = DateTime.now();
    final last = _refreshTappedAt;
    if (last != null && now.difference(last) < _refreshCooldown) return;
    setState(() => _refreshTappedAt = now);
    try {
      await ref.read(ownerReportServiceProvider).requestRefresh(vid);
    } catch (_) {
      // Offline/denied — the stale snapshot + pending hint already convey it.
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final vid = ref.watch(authStateProvider.select((s) => s.ownerVenueId));
    final async = ref.watch(ownerReportProvider(vid));

    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, vid, async.valueOrNull),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _message(
                  context,
                  'Gagal memuat laporan.',
                  Icons.error_outline,
                ),
                data: (report) => _content(context, report),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String vid, OwnerReport? report) {
    final sc = context.sat;
    final pending = _isPending(report);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
      decoration: SatBox.d(
        border: Border(bottom: SatB.side(color: sc.border0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Laporan Venue',
                  style: SatType.sans(
                    size: 22,
                    weight: FontWeight.w600,
                    color: sc.textHi,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: () => _refresh(vid),
                icon: Icon(Icons.refresh, color: sc.textMd, size: 20),
              ),
              IconButton(
                tooltip: 'Keluar',
                onPressed: () => ref.read(authStateProvider.notifier).signOut(),
                icon: Icon(Icons.logout, color: sc.textMd, size: 20),
              ),
            ],
          ),
          const SizedBox(height: Sp.s1),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: SatBox.d(
                  color: pending ? sc.warn : sc.textLo,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  _freshnessLine(report, pending),
                  style: SatType.mono(
                    size: 11,
                    color: sc.textLo,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s3),
          _rangeToggle(context),
        ],
      ),
    );
  }

  Widget _rangeToggle(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.all(Sp.s1),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(12),
      ),
      child: Row(
        children: [
          for (final key in kOwnerReportRanges)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _range = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  margin: const EdgeInsets.symmetric(horizontal: Sp.sHair),
                  alignment: Alignment.center,
                  decoration: SatBox.d(
                    color: _range == key ? sc.bg4 : Colors.transparent,
                    borderRadius: SatR.a(8),
                  ),
                  child: Text(
                    _rangeLabel[key] ?? key,
                    style: SatType.sans(
                      size: 12,
                      weight: FontWeight.w500,
                      color: _range == key ? sc.textHi : sc.textLo,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, OwnerReport? report) {
    final raw = report?.range(_range);
    if (raw == null) {
      return _message(
        context,
        'Belum ada laporan dari venue ini.',
        Icons.hourglass_empty_rounded,
      );
    }
    final ReportsSnapshotDto snap;
    try {
      snap = ReportsSnapshotDto.fromJson(raw);
    } catch (_) {
      return _message(
        context,
        'Format laporan tidak dikenal.',
        Icons.error_outline,
      );
    }
    // Full parity with the on-site Admin → Reports screen — same renderer,
    // sourced from the cloud snapshot. Proof photos are LAN-only (no server
    // off-site), so they fall back to a placeholder. See ADR-0036.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      child: ReportSectionsView(
        snapshot: snap,
        isTab: context.layout.useTabletShell,
        showProofPhotos: false,
        showStock: false,
      ),
    );
  }

  Widget _message(BuildContext context, String text, IconData icon) {
    final sc = context.sat;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: sc.textLo, size: 36),
            const SizedBox(height: Sp.s3),
            Text(
              text,
              textAlign: TextAlign.center,
              style: SatType.sans(size: 14, color: sc.textMd),
            ),
          ],
        ),
      ),
    );
  }

  // ── Freshness / pending ─────────────────────────────────────────────────

  /// A refresh is "pending" when the owner tapped recently but no newer
  /// snapshot has landed — the host may be offline. Derived from generatedAt,
  /// never a hanging spinner. See ADR-0036.
  bool _isPending(OwnerReport? report) {
    final tapped = _refreshTappedAt;
    if (tapped == null) return false;
    if (DateTime.now().difference(tapped) > const Duration(minutes: 2)) {
      return false; // give up the hint after a while
    }
    final gen = report?.generatedAt;
    return gen == null || gen.isBefore(tapped);
  }

  String _freshnessLine(OwnerReport? report, bool pending) {
    final gen = report?.generatedAt;
    if (gen == null) {
      return pending ? 'Meminta laporan…' : 'Belum ada data';
    }
    final ago = _ago(gen);
    if (pending) return 'Diperbarui $ago · menunggu venue (mungkin offline)';
    return 'Diperbarui $ago';
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }
}
