import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_state.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../models/audit_entry.dart';
import '../../models/dummy_data.dart';
import '../../models/venue_table.dart';
import '../../state/audit_provider.dart';
import '../../state/tables_provider.dart';
import '../../state/theme_provider.dart';
import '../../state/tickets_provider.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 56, 0, 130),
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
