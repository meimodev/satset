import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_state.dart';
import '../../design/colors.dart';
import '../../design/layout.dart';
import '../../design/typography.dart';
import '../../models/audit_entry.dart';
import '../../models/course.dart';
import '../../models/dummy_data.dart';
import '../../models/ticket.dart';
import '../../models/venue_table.dart';
import '../../state/audit_provider.dart';
import '../../state/ready_alert_provider.dart';
import '../../state/tables_provider.dart';
import '../../state/theme_provider.dart';
import '../../state/tickets_provider.dart';
import '../../widgets/ready_banner.dart';
import '../../widgets/ready_toast.dart';
import '../menu/modifier_sheet.dart';
import '../void_flow/line_item_action_sheet.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l = context.layout;
    final tables = ref.watch(tablesProvider);
    final tickets = ref.watch(ticketsProvider);
    final audit = ref.watch(auditProvider);
    final themeMode = ref.watch(themeModeProvider);

    final myTables = tables.where((t) => t.mine).toList();
    final ticketCount = myTables.fold<int>(
        0, (s, t) => s + (tickets[t.id]?.length ?? 0));
    final voidCount = audit.where((a) => a.type == AuditType.voidItem).length;
    final compCount = audit.where((a) => a.type == AuditType.comp).length;
    final openCovers = myTables.fold<int>(
        0, (s, t) => s + (t.status != TableStatus.available ? t.pax : 0));

    if (l.useTabletShell) {
      return _MeTablet(
        ticketCount: ticketCount,
        openCovers: openCovers,
        voidCount: voidCount,
        compCount: compCount,
        audit: audit,
        themeMode: themeMode,
        onSignOut: () {
          ref.read(authStateProvider.notifier).signOut();
          context.go('/pin');
        },
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
        child: ListView(
      padding: EdgeInsets.fromLTRB(0, l.topInset, 0, l.bottomInset + 40),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: sc.textHi),
              const SizedBox(width: 6),
              Text('Overview shift',
                  style: SatType.sans(size: 14, weight: FontWeight.w500, color: sc.textHi)),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sc.success,
                      boxShadow: [BoxShadow(color: sc.successSoft, spreadRadius: 3)],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('LIVE · LAN',
                      style: SatType.mono(size: 10, color: sc.textMd, letterSpacing: 0.6)),
                ],
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFFF9233), Color(0xFFD96030)]),
                ),
                alignment: Alignment.center,
                child: Text('MA',
                    style: SatType.sans(
                      size: 12,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    )),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFFF9233), Color(0xFFD96030)]),
                ),
                alignment: Alignment.center,
                child: Text('MA',
                    style: SatType.mono(
                      size: 18,
                      weight: FontWeight.w600,
                      letterSpacing: 0.36,
                      color: Colors.white,
                    )),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Maya Anjani',
                        style: SatType.sans(
                          size: 22,
                          weight: FontWeight.w600,
                          letterSpacing: -0.22,
                          color: sc.textHi,
                        )),
                    const SizedBox(height: 2),
                    Text('Floor server · Zona Teras',
                        style: SatType.sans(size: 13, color: sc.textMd)),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Mulai shift ${DummyData.maya.shiftStartedAt} · ',
                            style: SatType.mono(
                              size: 12,
                              color: sc.textLo,
                              letterSpacing: 0.24,
                            ),
                          ),
                          TextSpan(
                            text: '47 menit',
                            style: SatType.mono(
                              size: 12,
                              color: sc.accent,
                              letterSpacing: 0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(child: _Stat(label: 'Tiket terkirim', value: ticketCount)),
              const SizedBox(width: 6),
              Expanded(child: _Stat(label: 'Cover terbuka', value: openCovers)),
              const SizedBox(width: 6),
              Expanded(
                child: _Stat(
                  label: 'Pembatalan',
                  value: voidCount,
                  tone: voidCount > 0 ? _Tone.urgent : _Tone.normal,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Stat(
                  label: 'Comp',
                  value: compCount,
                  tone: compCount > 0 ? _Tone.warn : _Tone.normal,
                ),
              ),
            ],
          ),
        ),
        _SectionLabel(label: 'AKTIVITAS TERBARU', count: '${audit.length} entri'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: sc.bg2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sc.border0),
            ),
            child: audit.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Belum ada entri audit.',
                      style: SatType.sans(size: 13, color: sc.textLo),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0;
                          i < audit.length && i < 5;
                          i++) ...[
                        _AuditRow(entry: audit[i]),
                        if (i < (audit.length - 1).clamp(0, 4))
                          Divider(height: 1, color: sc.border0),
                      ],
                    ],
                  ),
          ),
        ),
        _SectionLabel(label: 'MANAJEMEN'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: sc.bg2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sc.border0),
            ),
            child: Column(
              children: [
                _NavRow(icon: Icons.local_fire_department_outlined, label: 'Dapur · Antrian masak', onTap: () => context.go('/kitchen')),
                Divider(height: 1, color: sc.border0),
                _NavRow(icon: Icons.place_outlined, label: 'Live floor', onTap: () => context.go('/floor')),
                Divider(height: 1, color: sc.border0),
                _NavRow(icon: Icons.menu_rounded, label: 'Menu admin', onTap: () => context.go('/menuadm')),
                Divider(height: 1, color: sc.border0),
                _NavRow(icon: Icons.auto_awesome_outlined, label: 'Laporan shift', onTap: () => context.go('/reports')),
                Divider(height: 1, color: sc.border0),
                _NavRow(icon: Icons.wifi_rounded, label: 'Sistem · Server', onTap: () => context.go('/settings')),
                Divider(height: 1, color: sc.border0),
                _NavRow(icon: Icons.person_outline_rounded, label: 'Staff & akun', onTap: () => context.go('/staff')),
              ],
            ),
          ),
        ),
        _SectionLabel(label: 'PREFERENSI'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: sc.bg2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sc.border0),
            ),
            child: Column(
              children: [
                _PrefRow(
                  icon: Icons.notifications_none,
                  label: 'Alarm audio',
                  value: 'Aktif',
                ),
                Divider(height: 1, color: sc.border0),
                _PrefRow(
                  icon: Icons.vibration,
                  label: 'Umpan balik haptic',
                  value: 'Kuat',
                ),
                Divider(height: 1, color: sc.border0),
                _PrefRow(
                  icon: Icons.wifi,
                  label: 'Koneksi server',
                  value: 'Warung Sebelah',
                  subtle: '192.168.4.21 · cert OK',
                ),
                Divider(height: 1, color: sc.border0),
                _ThemeRow(
                  mode: themeMode,
                  onChange: (m) =>
                      ref.read(themeModeProvider.notifier).state = m,
                ),
              ],
            ),
          ),
        ),
        if (kDebugMode) ...[
          const _SectionLabel(label: 'DEBUG · TRIGGER UI'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _DebugSection(),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                ref.read(authStateProvider.notifier).signOut();
                context.go('/pin');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: sc.textHi,
                side: BorderSide(color: sc.border2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text('Akhiri shift & keluar',
                  style: SatType.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: sc.textHi,
                  )),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              'BYOD · TIDAK ADA DATA PESANAN TERSIMPAN LOKAL · v2.0.0',
              style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.6),
            ),
          ),
        ),
      ],
        ),
      ),
    );
  }
}

enum _Tone { normal, urgent, warn }

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final _Tone tone;
  const _Stat({required this.label, required this.value, this.tone = _Tone.normal});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    Color bg = sc.bg2;
    Color border = sc.border0;
    Color valColor = sc.textHi;
    switch (tone) {
      case _Tone.urgent:
        bg = sc.urgentSoft;
        border = sc.urgent.withValues(alpha: 0.25);
        valColor = sc.urgent;
        break;
      case _Tone.warn:
        bg = sc.warnSoft;
        border = sc.warn.withValues(alpha: 0.25);
        valColor = sc.warn;
        break;
      case _Tone.normal:
        break;
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text('$value',
              style: SatType.mono(
                size: 22,
                weight: FontWeight.w600,
                letterSpacing: -0.44,
                color: valColor,
              )),
          const SizedBox(height: 6),
          Text(label.toUpperCase(),
              textAlign: TextAlign.center,
              style: SatType.mono(
                size: 9,
                weight: FontWeight.w500,
                letterSpacing: 0.72,
                color: sc.textLo,
                height: 1.2,
              )),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? count;
  const _SectionLabel({required this.label, this.count});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: SatType.mono(
                  size: 10,
                  weight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: sc.textLo,
                )),
          ),
          if (count != null)
            Text(count!,
                style: SatType.mono(size: 10, color: sc.textDim, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final AuditEntry entry;
  const _AuditRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final (icon, bg, fg) = switch (entry.type) {
      AuditType.voidItem => (Icons.delete_outline, sc.urgentSoft, sc.urgent),
      AuditType.comp => (Icons.auto_awesome, sc.warnSoft, sc.warn),
      AuditType.modify => (Icons.edit, sc.infoSoft, sc.info),
      AuditType.fire => (Icons.local_fire_department, sc.accentSoft, sc.accent),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title,
                    style: SatType.sans(
                      size: 13,
                      weight: FontWeight.w500,
                      letterSpacing: -0.13,
                      color: sc.textHi,
                      height: 1.25,
                    )),
                const SizedBox(height: 3),
                Text(
                  'Meja ${entry.tableId} · ${entry.when}'
                  '${entry.approvedBy != null ? ' · disetujui ${entry.approvedBy}' : ''}'
                  '${entry.reason != null ? ' · ${entry.reason}' : ''}',
                  style: SatType.mono(
                    size: 10,
                    color: sc.textLo,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtle;
  const _PrefRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtle,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: sc.bg3,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: sc.textMd),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: SatType.sans(
                      size: 14,
                      weight: FontWeight.w500,
                      color: sc.textHi,
                    )),
                if (subtle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtle!,
                        style: SatType.mono(
                          size: 10,
                          color: sc.textLo,
                          letterSpacing: 0.4,
                        )),
                  ),
              ],
            ),
          ),
          Text(value,
              style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textMd)),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, size: 14, color: sc.textLo),
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChange;
  const _ThemeRow({required this.mode, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final isDark = mode == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: sc.bg3,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              size: 16,
              color: sc.textMd,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tema',
                    style: SatType.sans(
                      size: 14,
                      weight: FontWeight.w500,
                      color: sc.textHi,
                    )),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(isDark ? 'Gelap' : 'Terang',
                      style: SatType.mono(
                        size: 10,
                        color: sc.textLo,
                        letterSpacing: 0.4,
                      )),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (v) => onChange(v ? ThemeMode.dark : ThemeMode.light),
            activeThumbColor: sc.accent,
          ),
        ],
      ),
    );
  }
}

class _MeTablet extends StatelessWidget {
  final int ticketCount;
  final int openCovers;
  final int voidCount;
  final int compCount;
  final List<AuditEntry> audit;
  final ThemeMode themeMode;
  final VoidCallback onSignOut;

  const _MeTablet({
    required this.ticketCount,
    required this.openCovers,
    required this.voidCount,
    required this.compCount,
    required this.audit,
    required this.themeMode,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 22, 32, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ringkasan shift',
                  style: SatType.sans(
                    size: 32,
                    weight: FontWeight.w600,
                    letterSpacing: -0.8,
                    height: 1.05,
                    color: sc.textHi,
                  )),
              const SizedBox(height: 6),
              Text('SABTU, 21 MEI · 47 MENIT SEJAK MULAI',
                  style: SatType.mono(
                    size: 11,
                    color: sc.textLo,
                    letterSpacing: 0.66,
                  )),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 10, 32, 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _hero(context, sc),
                      const SizedBox(height: 12),
                      _statsRow(context, sc),
                      const SizedBox(height: 18),
                      _prefsCard(context, sc),
                      if (kDebugMode) ...[
                        const SizedBox(height: 16),
                        const _DebugSection(),
                      ],
                      const SizedBox(height: 16),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onSignOut,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              border: Border.all(color: sc.border2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text('Akhiri shift & keluar',
                                style: SatType.sans(
                                  size: 15,
                                  weight: FontWeight.w600,
                                  color: sc.textHi,
                                )),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(child: _auditCard(context, sc)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero(BuildContext context, SatColors sc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFFF9233), Color(0xFFD96030)],
              ),
            ),
            alignment: Alignment.center,
            child: Text('MA',
                style: SatType.mono(
                  size: 20, weight: FontWeight.w600, color: Colors.white,
                )),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Maya Anjani',
                    style: SatType.sans(size: 24, weight: FontWeight.w600, letterSpacing: -0.48, color: sc.textHi)),
                const SizedBox(height: 3),
                Text('Pelayan · Zona Teras', style: SatType.sans(size: 13, color: sc.textMd)),
                const SizedBox(height: 6),
                Text('PIN MASUK 17:30 · BYOD · iPad-1',
                    style: SatType.mono(size: 11, color: sc.textLo, letterSpacing: 0.44)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context, SatColors sc) {
    return Row(
      children: [
        Expanded(child: _statBox(context, sc, ticketCount.toString(), 'Tiket kirim')),
        const SizedBox(width: 8),
        Expanded(child: _statBox(context, sc, openCovers.toString(), 'Tamu aktif')),
        const SizedBox(width: 8),
        Expanded(child: _statBox(context, sc, voidCount.toString(), 'Pembatalan', urgent: voidCount > 0)),
        const SizedBox(width: 8),
        Expanded(child: _statBox(context, sc, compCount.toString(), 'Gratisan', warn: compCount > 0)),
      ],
    );
  }

  Widget _statBox(BuildContext context, SatColors sc, String value, String label, {bool urgent = false, bool warn = false}) {
    Color bg = sc.bg2;
    Color border = sc.border0;
    Color fg = sc.textHi;
    if (urgent) { bg = sc.urgentSoft; border = sc.urgent.withValues(alpha: 0.25); fg = sc.urgent; }
    if (warn)   { bg = sc.warnSoft;   border = sc.warn.withValues(alpha: 0.25);   fg = sc.warn; }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: SatType.mono(size: 22, weight: FontWeight.w600, letterSpacing: -0.44, height: 1, color: fg)),
          const SizedBox(height: 8),
          Text(label.toUpperCase(),
              style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.6)),
        ],
      ),
    );
  }

  Widget _prefsCard(BuildContext context, SatColors sc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PREFERENSI',
              style: SatType.mono(size: 10, weight: FontWeight.w600, letterSpacing: 1.2, color: sc.textLo)),
          const SizedBox(height: 12),
          _prefRow(context, sc, Icons.notifications_active_rounded, 'Alert audio', 'Nada peringatan + getaran kuat', 'Aktif'),
          _prefRow(context, sc, Icons.wifi_tethering_rounded, 'Server', '192.168.4.21 · sertifikat OK · ping 38ms', 'Warung Sebelah', last: true),
        ],
      ),
    );
  }

  Widget _prefRow(BuildContext context, SatColors sc, IconData icon, String label, String sub, String value, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: last ? BorderSide.none : BorderSide(color: sc.border0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: sc.bg3, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: sc.textMd),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SatType.sans(size: 14, weight: FontWeight.w500, color: sc.textHi, letterSpacing: -0.14)),
                const SizedBox(height: 2),
                Text(sub, style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.3)),
              ],
            ),
          ),
          Text(value, style: SatType.sans(size: 13, color: sc.textMd)),
        ],
      ),
    );
  }

  Widget _auditCard(BuildContext context, SatColors sc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('AKTIVITAS TERKINI',
                    style: SatType.mono(size: 10, weight: FontWeight.w600, letterSpacing: 1.2, color: sc.textLo)),
              ),
              Text('${audit.length} entri', style: SatType.mono(size: 10, color: sc.textDim, letterSpacing: 0.4)),
            ],
          ),
          const SizedBox(height: 14),
          if (audit.isEmpty)
            Text('Belum ada entri audit. Pembatalan, gratisan, dan perubahan setelah kirim akan tampil di sini.',
                style: SatType.sans(size: 13, color: sc.textLo, height: 1.5))
          else
            for (var i = 0; i < audit.length && i < 7; i++) _auditRow(context, sc, audit[i], i == audit.length - 1 || i == 6),
        ],
      ),
    );
  }

  Widget _auditRow(BuildContext context, SatColors sc, AuditEntry e, bool last) {
    Color bg = sc.bg3;
    Color fg = sc.textMd;
    IconData ic = Icons.info_outline;
    switch (e.type) {
      case AuditType.voidItem: bg = sc.urgentSoft; fg = sc.urgent; ic = Icons.delete_outline_rounded; break;
      case AuditType.comp: bg = sc.warnSoft; fg = sc.warn; ic = Icons.card_giftcard_rounded; break;
      case AuditType.modify: bg = sc.infoSoft; fg = sc.info; ic = Icons.edit_outlined; break;
      case AuditType.fire: bg = sc.accentSoft; fg = sc.accent; ic = Icons.local_fire_department_rounded; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: last ? BorderSide.none : BorderSide(color: sc.border0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(ic, size: 14, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textHi, letterSpacing: -0.13, height: 1.25)),
                const SizedBox(height: 3),
                Text(
                  'Meja ${e.tableId} · ${e.when}'
                  '${e.approvedBy != null ? ' · disetujui ${e.approvedBy}' : ''}'
                  '${e.reason != null ? ' · ${e.reason}' : ''}',
                  style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: sc.bg3, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: sc.textMd),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: SatType.sans(
                    size: 14,
                    weight: FontWeight.w500,
                    letterSpacing: -0.14,
                    color: sc.textHi,
                  )),
            ),
            Icon(Icons.chevron_right, size: 18, color: sc.textLo),
          ],
        ),
      ),
    );
  }
}

class _DebugSection extends ConsumerWidget {
  const _DebugSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    return Container(
      decoration: BoxDecoration(
        color: sc.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sc.border0),
      ),
      child: Column(
        children: [
          _DebugRow(
            icon: Icons.notifications_active_rounded,
            label: 'ReadyToast',
            sub: 'Notification bar atas',
            onTap: () => _showReadyToast(context),
          ),
          Divider(height: 1, color: sc.border0),
          _DebugRow(
            icon: Icons.campaign_outlined,
            label: 'ReadyBanner',
            sub: 'Banner di dalam layar',
            onTap: () => _showReadyBannerPreview(context),
          ),
          Divider(height: 1, color: sc.border0),
          _DebugRow(
            icon: Icons.tune_rounded,
            label: 'ModifierSheet',
            sub: 'Dialog / bottom sheet menu',
            onTap: () => _showModifierSheetDebug(context),
          ),
          Divider(height: 1, color: sc.border0),
          _DebugRow(
            icon: Icons.receipt_long_outlined,
            label: 'LineItemActionSheet',
            sub: 'Aksi tiket: kirim / sajikan / void',
            onTap: () => _showLineItemSheetDebug(context, ref),
          ),
          Divider(height: 1, color: sc.border0),
          _DebugRow(
            icon: Icons.info_outline,
            label: 'Snackbar',
            sub: 'Belum ada impl custom',
            disabled: true,
          ),
        ],
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback? onTap;
  final bool disabled;
  const _DebugRow({
    required this.icon,
    required this.label,
    required this.sub,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final labelColor = disabled ? sc.textLo : sc.textHi;
    final subColor = disabled ? sc.textDim : sc.textLo;
    final iconBg = disabled ? sc.bg3 : sc.bg3;
    final iconColor = disabled ? sc.textDim : sc.warn;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: SatType.sans(
                          size: 14,
                          weight: FontWeight.w500,
                          color: labelColor,
                        )),
                    const SizedBox(height: 2),
                    Text(sub,
                        style: SatType.mono(
                          size: 11,
                          color: subColor,
                          letterSpacing: 0.44,
                        )),
                  ],
                ),
              ),
              if (!disabled)
                Icon(Icons.play_arrow_rounded, size: 20, color: sc.textMd)
              else
                Text('SKIP',
                    style: SatType.mono(
                      size: 10,
                      weight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: sc.textDim,
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

void _showReadyToast(BuildContext context) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  Timer? autoDismiss;
  void remove() {
    autoDismiss?.cancel();
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: Colors.transparent,
          child: ReadyToast(
            alert: const ReadyAlert(
              tableId: 'T2',
              zone: 'Teras',
              what: '2 item',
            ),
            onView: remove,
            onDismiss: remove,
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  autoDismiss = Timer(const Duration(seconds: 3), remove);
}

void _showReadyBannerPreview(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.sat.bg1,
    builder: (ctx) => const Padding(
      padding: EdgeInsets.fromLTRB(0, 24, 0, 32),
      child: ReadyBanner(),
    ),
  );
}

void _showModifierSheetDebug(BuildContext context) {
  final item = DummyData.items.firstWhere(
    (i) => i.modifierGroups.isNotEmpty,
    orElse: () => DummyData.items.first,
  );
  showModifierSheet(context: context, item: item, onAdd: (_) {});
}

void _showLineItemSheetDebug(BuildContext context, WidgetRef ref) {
  final tickets = ref.read(ticketsProvider);
  String? tableId;
  Ticket? ticket;
  for (final entry in tickets.entries) {
    if (entry.value.isNotEmpty) {
      tableId = entry.key;
      ticket = entry.value.first;
      break;
    }
  }
  tableId ??= 'T2';
  ticket ??= _stubTicket();
  showLineItemActionSheet(
    context: context,
    ref: ref,
    tableId: tableId,
    ticket: ticket,
  );
}

Ticket _stubTicket() {
  final item = DummyData.items.first;
  return Ticket(
    id: 'debug-${DateTime.now().millisecondsSinceEpoch}',
    itemId: item.id,
    name: item.name,
    course: CourseId.mains,
    station: item.station,
    qty: 1,
    price: item.basePrice,
    status: TicketStatus.sent,
    sentAt: '17:42',
  );
}
