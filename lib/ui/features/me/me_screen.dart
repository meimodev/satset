import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/audit_repository.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/services/dummy_data_seed.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/state/ready_alert_view_model.dart';
import 'package:satset/ui/core/state/theme_view_model.dart';
import 'package:satset/ui/core/widgets/ready_banner.dart';
import 'package:satset/ui/core/widgets/ready_toast.dart';

import '../menu/modifier_sheet.dart';
import '../void_flow/line_item_action_sheet.dart';

class _ShiftMetrics {
  final String name;
  final String roleLabel;
  final String initials;
  final String shiftStart;
  final int elapsedMinutes;
  final int totalSales;
  final int ticketCount;
  final int openCovers;
  final int voidCount;
  final int compCount;
  final int modifyCount;
  final int peakSentInWindow;
  final String peakWindowLabel;

  const _ShiftMetrics({
    required this.name,
    required this.roleLabel,
    required this.initials,
    required this.shiftStart,
    required this.elapsedMinutes,
    required this.totalSales,
    required this.ticketCount,
    required this.openCovers,
    required this.voidCount,
    required this.compCount,
    required this.modifyCount,
    required this.peakSentInWindow,
    required this.peakWindowLabel,
  });

  int get avgTicket => ticketCount == 0 ? 0 : (totalSales / ticketCount).round();
  int get avgPerCover => openCovers == 0 ? 0 : (totalSales / openCovers).round();
  String get elapsedLabel {
    final h = elapsedMinutes ~/ 60;
    final m = elapsedMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}j ${m.toString().padLeft(2, '0')}m';
  }

  double get shiftProgress {
    const targetMin = 8 * 60;
    return (elapsedMinutes / targetMin).clamp(0.0, 1.0);
  }
}

_ShiftMetrics _computeMetrics({
  required List<VenueTable> tables,
  required Map<String, List<Ticket>> tickets,
  required List<AuditEntry> audit,
}) {
  final myTables = tables.where((t) => t.mine).toList();
  int totalSales = 0;
  int ticketCount = 0;
  for (final t in myTables) {
    for (final tk in tickets[t.id] ?? const <Ticket>[]) {
      if (tk.status == TicketStatus.voided) continue;
      totalSales += tk.price * tk.qty;
      ticketCount++;
    }
  }
  final openCovers = myTables.fold<int>(
      0, (s, t) => s + (t.status != TableStatus.available ? t.pax : 0));
  final voidCount = audit.where((a) => a.type == AuditType.voidItem).length;
  final compCount = audit.where((a) => a.type == AuditType.comp).length;
  final modifyCount = audit.where((a) => a.type == AuditType.modify).length;

  return _ShiftMetrics(
    name: DummyData.maya.name,
    roleLabel: 'Pelayan · Zona Teras',
    initials: 'MA',
    shiftStart: DummyData.maya.shiftStartedAt,
    elapsedMinutes: 47,
    totalSales: totalSales,
    ticketCount: ticketCount,
    openCovers: openCovers,
    voidCount: voidCount,
    compCount: compCount,
    modifyCount: modifyCount,
    peakSentInWindow: math.max(ticketCount, 5),
    peakWindowLabel: '18:10 – 18:20',
  );
}

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tablesProvider);
    final tickets = ref.watch(ticketsProvider);
    final audit = ref.watch(auditProvider);
    final themeMode = ref.watch(themeModeProvider);
    final m = _computeMetrics(tables: tables, tickets: tickets, audit: audit);

    void toggleTheme() {
      final next =
          themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      ref.read(themeModeProvider.notifier).state = next;
    }

    void endShift() {
      ref.read(authStateProvider.notifier).signOut();
      context.go('/pin');
    }

    if (context.layout.useTabletShell) {
      return _MeTablet(
        m: m,
        audit: audit,
        themeMode: themeMode,
        onToggleTheme: toggleTheme,
        onEndShift: endShift,
      );
    }
    return _MePhone(
      m: m,
      audit: audit,
      themeMode: themeMode,
      onToggleTheme: toggleTheme,
      onEndShift: endShift,
    );
  }
}

// ────────────────────────────────── PHONE

class _MePhone extends StatelessWidget {
  final _ShiftMetrics m;
  final List<AuditEntry> audit;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onEndShift;

  const _MePhone({
    required this.m,
    required this.audit,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onEndShift,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(0, l.topInset, 0, l.bottomInset + 40),
          children: [
            _TopBar(themeMode: themeMode, onToggleTheme: onToggleTheme),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: _Identity(m: m),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: _EndShiftButton(onPressed: onEndShift),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SalesHero(m: m),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _KpiGrid(m: m),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PacingCard(m: m),
            ),
            const _SectionLabel(label: 'AKTIVITAS TERBARU'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ActivityCard(audit: audit, max: 5),
            ),
            if (kDebugMode) ...[
              const _SectionLabel(label: 'DEBUG · TRIGGER UI'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _DebugSection(),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'BYOD · TIDAK ADA DATA PESANAN TERSIMPAN LOKAL · v2.0.0',
                  style: SatType.mono(
                      size: 10, color: sc.textLo, letterSpacing: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────── TABLET

class _MeTablet extends StatelessWidget {
  final _ShiftMetrics m;
  final List<AuditEntry> audit;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onEndShift;

  const _MeTablet({
    required this.m,
    required this.audit,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onEndShift,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 22, 32, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
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
                    Text(
                        'SABTU, 21 MEI · MULAI ${m.shiftStart} · ${m.elapsedLabel} BERJALAN'
                            .toUpperCase(),
                        style: SatType.mono(
                          size: 11,
                          color: sc.textLo,
                          letterSpacing: 0.66,
                        )),
                  ],
                ),
              ),
              _LivePill(),
              const SizedBox(width: 10),
              _ThemeIconButton(themeMode: themeMode, onTap: onToggleTheme),
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
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Identity(m: m, big: true),
                      const SizedBox(height: 14),
                      _EndShiftButton(onPressed: onEndShift),
                      const SizedBox(height: 14),
                      _SalesHero(m: m, big: true),
                      const SizedBox(height: 12),
                      _KpiGrid(m: m, columns: 4),
                      const SizedBox(height: 12),
                      _PacingCard(m: m, big: true),
                      if (kDebugMode) ...[
                        const SizedBox(height: 16),
                        const _DebugSection(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  flex: 4,
                  child: _ActivityCard(audit: audit, max: 9, padded: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────── PIECES

class _TopBar extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  const _TopBar({required this.themeMode, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 0),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 14, color: sc.textMd),
          const SizedBox(width: 6),
          Text('Ringkasan shift',
              style: SatType.sans(
                  size: 14, weight: FontWeight.w500, color: sc.textHi)),
          const Spacer(),
          _LivePill(),
          const SizedBox(width: 8),
          _ThemeIconButton(themeMode: themeMode, onTap: onToggleTheme),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: sc.successSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: sc.success)),
          const SizedBox(width: 6),
          Text('LIVE · LAN',
              style: SatType.mono(
                  size: 10, color: sc.success, letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

class _ThemeIconButton extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onTap;
  const _ThemeIconButton({required this.themeMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final dark = themeMode == ThemeMode.dark;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: sc.border1),
          ),
          alignment: Alignment.center,
          child: Icon(
            dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            size: 16,
            color: sc.textMd,
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final _ShiftMetrics m;
  final bool big;
  const _Identity({required this.m, this.big = false});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final size = big ? 72.0 : 56.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size + 12,
              height: size + 12,
              child: CircularProgressIndicator(
                value: m.shiftProgress,
                strokeWidth: 3,
                backgroundColor: sc.border0,
                valueColor: AlwaysStoppedAnimation<Color>(sc.accent),
              ),
            ),
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF9233), Color(0xFFD96030)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(m.initials,
                  style: SatType.mono(
                    size: big ? 22 : 18,
                    weight: FontWeight.w600,
                    letterSpacing: 0.36,
                    color: Colors.white,
                  )),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.name,
                  style: SatType.sans(
                    size: big ? 24 : 22,
                    weight: FontWeight.w600,
                    letterSpacing: -0.32,
                    color: sc.textHi,
                  )),
              const SizedBox(height: 2),
              Text(m.roleLabel,
                  style: SatType.sans(size: 13, color: sc.textMd)),
              const SizedBox(height: 6),
              Text(
                'MULAI ${m.shiftStart} · ${m.elapsedLabel.toUpperCase()} BERJALAN',
                style: SatType.mono(
                  size: 11,
                  color: sc.textLo,
                  letterSpacing: 0.44,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SalesHero extends StatelessWidget {
  final _ShiftMetrics m;
  final bool big;
  const _SalesHero({required this.m, this.big = false});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: EdgeInsets.fromLTRB(20, big ? 22 : 18, 20, big ? 22 : 18),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 14, color: sc.textLo),
              const SizedBox(width: 6),
              Text('PENJUALAN SHIFT',
                  style: SatType.mono(
                      size: 10,
                      weight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: sc.textLo)),
              const Spacer(),
              Text('${m.ticketCount} tiket',
                  style: SatType.mono(
                      size: 10, color: sc.textLo, letterSpacing: 0.4)),
            ],
          ),
          const SizedBox(height: 10),
          Text(formatIDR(m.totalSales),
              style: SatType.sans(
                size: big ? 38 : 32,
                weight: FontWeight.w600,
                letterSpacing: -0.96,
                height: 1.0,
                color: sc.textHi,
              )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _heroPair(context, 'Avg / tiket', formatIDR(m.avgTicket)),
              _heroPair(context, 'Avg / cover', formatIDR(m.avgPerCover)),
              _heroPair(context, 'Cover aktif', '${m.openCovers}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPair(BuildContext context, String label, String value) {
    final sc = context.sat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: SatType.mono(
                size: 9, letterSpacing: 0.72, color: sc.textLo)),
        const SizedBox(height: 2),
        Text(value,
            style: SatType.sans(
                size: 14,
                weight: FontWeight.w600,
                letterSpacing: -0.14,
                color: sc.textHi)),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final _ShiftMetrics m;
  final int columns;
  const _KpiGrid({required this.m, this.columns = 2});

  @override
  Widget build(BuildContext context) {
    final items = <_Kpi>[
      _Kpi(label: 'Tiket dikirim', value: '${m.ticketCount}', sub: 'sejak mulai'),
      _Kpi(label: 'Cover dilayani', value: '${m.openCovers}', sub: 'aktif sekarang'),
      _Kpi(
        label: 'Pembatalan',
        value: '${m.voidCount}',
        sub: m.voidCount == 0 ? 'bersih' : 'perlu review',
        tone: m.voidCount > 0 ? _Tone.urgent : _Tone.normal,
      ),
      _Kpi(
        label: 'Comp / modif',
        value: '${m.compCount + m.modifyCount}',
        sub: '${m.compCount} comp · ${m.modifyCount} modif',
        tone: m.compCount > 0 ? _Tone.warn : _Tone.normal,
      ),
    ];

    if (columns >= 4) {
      return Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _KpiBox(kpi: items[i])),
            if (i != items.length - 1) const SizedBox(width: 8),
          ],
        ],
      );
    }
    return Column(
      children: [
        Row(children: [
          Expanded(child: _KpiBox(kpi: items[0])),
          const SizedBox(width: 8),
          Expanded(child: _KpiBox(kpi: items[1])),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _KpiBox(kpi: items[2])),
          const SizedBox(width: 8),
          Expanded(child: _KpiBox(kpi: items[3])),
        ]),
      ],
    );
  }
}

enum _Tone { normal, urgent, warn }

class _Kpi {
  final String label;
  final String value;
  final String sub;
  final _Tone tone;
  const _Kpi({
    required this.label,
    required this.value,
    required this.sub,
    this.tone = _Tone.normal,
  });
}

class _KpiBox extends StatelessWidget {
  final _Kpi kpi;
  const _KpiBox({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    Color bg = sc.bg2;
    Color border = sc.border0;
    Color valColor = sc.textHi;
    Color subColor = sc.textLo;
    switch (kpi.tone) {
      case _Tone.urgent:
        bg = sc.urgentSoft;
        border = sc.urgent.withValues(alpha: 0.25);
        valColor = sc.urgent;
        subColor = sc.urgent.withValues(alpha: 0.8);
        break;
      case _Tone.warn:
        bg = sc.warnSoft;
        border = sc.warn.withValues(alpha: 0.25);
        valColor = sc.warn;
        subColor = sc.warn.withValues(alpha: 0.8);
        break;
      case _Tone.normal:
        break;
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kpi.label.toUpperCase(),
              style: SatType.mono(
                size: 9,
                weight: FontWeight.w500,
                letterSpacing: 0.72,
                color: subColor,
              )),
          const SizedBox(height: 10),
          Text(kpi.value,
              style: SatType.mono(
                size: 26,
                weight: FontWeight.w600,
                letterSpacing: -0.52,
                height: 1,
                color: valColor,
              )),
          const SizedBox(height: 6),
          Text(kpi.sub,
              style: SatType.sans(size: 11, color: subColor, height: 1.2)),
        ],
      ),
    );
  }
}

class _PacingCard extends StatelessWidget {
  final _ShiftMetrics m;
  final bool big;
  const _PacingCard({required this.m, this.big = false});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final ratio = (m.ticketCount / math.max(m.elapsedMinutes, 1));
    final perHour = (ratio * 60).toStringAsFixed(1);
    return Container(
      padding: EdgeInsets.fromLTRB(18, big ? 18 : 16, 18, big ? 18 : 16),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: sc.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.show_chart_rounded, size: 18, color: sc.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$perHour tiket / jam',
                  style: SatType.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      letterSpacing: -0.15,
                      color: sc.textHi),
                ),
                const SizedBox(height: 3),
                Text(
                  'Puncak ${m.peakWindowLabel} · ${m.peakSentInWindow} tiket di window 10 menit',
                  style: SatType.mono(
                      size: 10, color: sc.textLo, letterSpacing: 0.36),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(m.elapsedLabel,
                  style: SatType.mono(
                      size: 16,
                      weight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: sc.textHi)),
              Text('TERPAKAI',
                  style: SatType.mono(
                      size: 9, color: sc.textLo, letterSpacing: 0.72)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final List<AuditEntry> audit;
  final int max;
  final bool padded;
  const _ActivityCard(
      {required this.audit, required this.max, this.padded = false});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final inner = audit.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Belum ada entri audit. Pembatalan, comp, dan perubahan pasca-kirim muncul di sini.',
              style: SatType.sans(size: 13, color: sc.textLo, height: 1.5),
            ),
          )
        : Column(
            children: [
              for (var i = 0; i < audit.length && i < max; i++) ...[
                _AuditRow(entry: audit[i]),
                if (i < (audit.length - 1).clamp(0, max - 1))
                  Divider(height: 1, color: sc.border0),
              ],
            ],
          );

    if (padded) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        decoration: BoxDecoration(
          color: sc.bg2,
          border: Border.all(color: sc.border0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('AKTIVITAS TERKINI',
                      style: SatType.mono(
                          size: 10,
                          weight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: sc.textLo)),
                ),
                Text('${audit.length} entri',
                    style: SatType.mono(
                        size: 10, color: sc.textDim, letterSpacing: 0.4)),
              ],
            ),
            const SizedBox(height: 8),
            inner,
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: sc.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sc.border0),
      ),
      child: inner,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Text(label,
          style: SatType.mono(
            size: 10,
            weight: FontWeight.w500,
            letterSpacing: 1.2,
            color: sc.textLo,
          )),
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
      AuditType.comp => (Icons.card_giftcard_rounded, sc.warnSoft, sc.warn),
      AuditType.modify => (Icons.edit_outlined, sc.infoSoft, sc.info),
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
                color: bg, borderRadius: BorderRadius.circular(8)),
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
                      size: 10, color: sc.textLo, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EndShiftButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _EndShiftButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.logout_rounded, size: 18, color: sc.textHi),
        label: Text('Akhiri shift & keluar',
            style: SatType.sans(
                size: 15, weight: FontWeight.w600, color: sc.textHi)),
        style: OutlinedButton.styleFrom(
          foregroundColor: sc.textHi,
          side: BorderSide(color: sc.border2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
    );
  }
}

// ────────────────────────────────── DEBUG (unchanged behavior)

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
                    color: sc.bg3, borderRadius: BorderRadius.circular(8)),
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
                            color: labelColor)),
                    const SizedBox(height: 2),
                    Text(sub,
                        style: SatType.mono(
                            size: 11, color: subColor, letterSpacing: 0.44)),
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
