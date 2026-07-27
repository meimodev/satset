import 'dart:async';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/audit_repository.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/roles_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/server/server.dart' show serverRuntimeProvider;
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/features/me/widgets/theme_sheet.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/state/theme_view_model.dart';
import 'package:satset/ui/core/widgets/staff_avatar.dart';
import 'package:satset/ui/core/design/spacing.dart';

class _ShiftMetrics {
  final String name;
  final String roleLabel;
  final String initials;
  final int? avatarColorHex;
  final String shiftStart;
  final Duration elapsed;
  final int ticketCount;
  final int openCovers;
  final int voidCount;
  final int compCount;
  final int modifyCount;

  const _ShiftMetrics({
    required this.name,
    required this.roleLabel,
    required this.initials,
    required this.avatarColorHex,
    required this.shiftStart,
    required this.elapsed,
    required this.ticketCount,
    required this.openCovers,
    required this.voidCount,
    required this.compCount,
    required this.modifyCount,
  });

  int get elapsedMinutes => elapsed.inMinutes;
  String get elapsedLabel => formatElapsedId(elapsed);

  double get shiftProgress {
    const targetMin = 8 * 60;
    return (elapsed.inMinutes / targetMin).clamp(0.0, 1.0);
  }
}

_ShiftMetrics _computeMetrics({
  required List<VenueTable> tables,
  required Map<String, List<Ticket>> tickets,
  required List<AuditEntry> audit,
  required String userName,
  required String userInitials,
  required int? userAvatarColorHex,
  required String roleLabel,
  required String shiftStart,
  required Duration elapsed,
}) {
  final myTables = tables.where((t) => t.mine).toList();
  int ticketCount = 0;
  for (final t in myTables) {
    // Lines are keyed by visitId (ADR-0034); resolve through the table's
    // current visit rather than its (reused) id.
    final vid = t.currentVisitId;
    final lines = (vid != null && vid.isNotEmpty)
        ? (tickets[vid] ?? const <Ticket>[])
        : const <Ticket>[];
    for (final tk in lines) {
      if (tk.status == TicketStatus.voided) continue;
      ticketCount++;
    }
  }
  final openCovers = myTables.fold<int>(
    0,
    (s, t) => s + (t.status != TableStatus.available ? t.pax : 0),
  );
  final voidCount = audit.where((a) => a.type == AuditType.voidItem).length;
  final compCount = audit.where((a) => a.type == AuditType.comp).length;
  final modifyCount = audit.where((a) => a.type == AuditType.modify).length;

  return _ShiftMetrics(
    name: userName,
    roleLabel: roleLabel,
    initials: userInitials,
    avatarColorHex: userAvatarColorHex,
    shiftStart: shiftStart,
    elapsed: elapsed,
    ticketCount: ticketCount,
    openCovers: openCovers,
    voidCount: voidCount,
    compCount: compCount,
    modifyCount: modifyCount,
  );
}

class MeScreen extends ConsumerStatefulWidget {
  const MeScreen({super.key});

  @override
  ConsumerState<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends ConsumerState<MeScreen> {
  // Drives the live shift counter so elapsed ticks between provider events,
  // matching the other elapsed counters (kitchen, table detail).
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(tablesProvider);
    final tickets = ref.watch(ticketsProvider);
    final rawAudit = ref.watch(auditProvider);
    final theme = ref.watch(satThemeProvider);
    final user = ref.watch(authStateProvider).user;
    final roles = ref.watch(rolesRepositoryProvider);
    // Hide staff/role admin audit rows from users without `manageStaff`.
    final canManageStaff =
        user != null &&
        !user.disabled &&
        roles.any((r) => r.id == user.roleId && r.has(Capability.manageStaff));
    final audit = canManageStaff
        ? rawAudit
        : [
            for (final e in rawAudit)
              if (!isAdminAuditType(e.type)) e,
          ];

    // Role · zone label. Prefer the custom role name; fall back to the generic
    // role label. Drop the zone segment when unassigned ('—' / empty).
    final String roleName;
    if (user == null) {
      roleName = '—';
    } else {
      final match = roles.where((r) => r.id == user.roleId);
      roleName = match.isNotEmpty ? match.first.name : userRoleLabel(user.role);
    }
    final zone = user?.zoneAssigned ?? '';
    final roleLabel = (zone.isEmpty || zone == '—')
        ? roleName
        : '$roleName · $zone';

    // Elapsed from login. shiftStartedAt is the login ISO timestamp.
    final shiftIso = user?.shiftStartedAt ?? '';
    final shiftStartedDt = DateTime.tryParse(shiftIso);
    var elapsed = shiftStartedDt == null
        ? Duration.zero
        : SatClock.now().difference(shiftStartedDt);
    if (elapsed.isNegative) elapsed = Duration.zero;
    final shiftStart = shiftIso.isEmpty ? '—' : formatClockId(shiftIso);

    // tableId → display label for audit rows.
    final tableNames = {for (final t in tables) t.id: t.displayName};

    final m = _computeMetrics(
      tables: tables,
      tickets: tickets,
      audit: audit,
      userName: user?.name ?? '—',
      userInitials: user?.initials ?? '—',
      userAvatarColorHex: user?.avatarColorHex,
      roleLabel: roleLabel,
      shiftStart: shiftStart,
      elapsed: elapsed,
    );

    void pickTheme() => showThemeSheet(context, ref);

    final l = context.layout;

    Future<void> endShift() async {
      // Admin (Server mode): logout kills the embedded server — every staff
      // device disconnects and cannot reconnect until an admin re-signs-in.
      // Confirm first, warning about live tables. See ADR-0015.
      final isServer = ref.read(serverRuntimeProvider) != null;
      if (isServer) {
        final liveCount = tables
            .where((t) => t.status != TableStatus.available)
            .length;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Akhiri sesi admin?'),
            content: Text(
              liveCount > 0
                  ? '$liveCount meja masih aktif. Keluar akan mematikan server — '
                        'semua staff terputus dan tidak bisa menyambung sampai '
                        'admin masuk lagi.'
                  : 'Keluar akan mematikan server. Staff tidak bisa menyambung '
                        'sampai admin masuk lagi.',
            ),
            actions: [
              SatButton.ghost(
                label: AppStrings.cancel,
                onTap: () => Navigator.pop(ctx, false),
              ),
              SatButton.danger(
                label: 'Keluar & matikan',
                onTap: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
      await ref.read(authStateProvider.notifier).signOut();
      if (context.mounted) context.go('/pin');
    }

    if (l.useTabletShell) {
      return _MeTablet(
        m: m,
        audit: audit,
        tableNames: tableNames,
        theme: theme,
        onPickTheme: pickTheme,
        onEndShift: endShift,
      );
    }
    return _MePhone(
      m: m,
      audit: audit,
      tableNames: tableNames,
      theme: theme,
      onPickTheme: pickTheme,
      onEndShift: endShift,
    );
  }
}

// ────────────────────────────────── PHONE

class _MePhone extends StatelessWidget {
  final _ShiftMetrics m;
  final List<AuditEntry> audit;
  final Map<String, String> tableNames;
  final SatTheme theme;
  final VoidCallback onPickTheme;
  final VoidCallback onEndShift;

  const _MePhone({
    required this.m,
    required this.audit,
    required this.tableNames,
    required this.theme,
    required this.onPickTheme,
    required this.onEndShift,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.layout;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(0, l.topInset, 0, l.bottomInset + 40),
          children: [
            _TopBar(theme: theme, onPickTheme: onPickTheme),
            const SizedBox(height: Sp.s2),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: _Identity(m: m),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: _EndShiftButton(onPressed: onEndShift),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.s4),
              child: _KpiGrid(m: m),
            ),
            const SizedBox(height: Sp.s3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.s4),
              child: _PacingCard(m: m),
            ),
            const _SectionLabel(label: 'AKTIVITAS TERBARU'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.s4),
              child: _ActivityCard(
                audit: audit,
                tableNames: tableNames,
                max: 5,
              ),
            ),
            SizedBox(height: l.bottomInset),
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
  final Map<String, String> tableNames;
  final SatTheme theme;
  final VoidCallback onPickTheme;
  final VoidCallback onEndShift;

  const _MeTablet({
    required this.m,
    required this.audit,
    required this.tableNames,
    required this.theme,
    required this.onPickTheme,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'MULAI ${m.shiftStart} · ${m.elapsedLabel} BERJALAN'
                      .toUpperCase(),
                  style: SatType.mono(
                    size: 11,
                    color: sc.textLo,
                    letterSpacing: 0.66,
                  ),
                ),
              ),
              _ThemeIconButton(theme: theme, onTap: onPickTheme),
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
                      _Identity(m: m, big: true, showShiftLine: false),
                      const SizedBox(height: Sp.s3h),
                      _EndShiftButton(onPressed: onEndShift),
                      const SizedBox(height: Sp.s3h),
                      _KpiGrid(m: m, columns: 4),
                      const SizedBox(height: Sp.s3),
                      _PacingCard(m: m, big: true),
                    ],
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  flex: 4,
                  child: _ActivityCard(
                    audit: audit,
                    tableNames: tableNames,
                    max: 9,
                    padded: true,
                  ),
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
  final SatTheme theme;
  final VoidCallback onPickTheme;
  const _TopBar({required this.theme, required this.onPickTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 0),
      child: Row(
        children: [
          const Spacer(),
          _ThemeIconButton(theme: theme, onTap: onPickTheme),
        ],
      ),
    );
  }
}

/// Opens the theme sheet. Shows the active theme's accent as the affordance —
/// the palette is the thing being chosen, so the swatch is a truer preview than
/// a sun/moon glyph (two of the four themes share a brightness).
class _ThemeIconButton extends StatelessWidget {
  final SatTheme theme;
  final VoidCallback onTap;
  const _ThemeIconButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final inner = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: SatBox.d(
            shape: BoxShape.circle,
            border: SatB.all(color: sc.border1),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 14,
            height: 14,
            decoration: SatBox.d(
              shape: BoxShape.circle,
              color: theme.colors.accent,
              border: SatB.all(color: sc.border2),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: AppStrings.a11yPickTheme,
      child: inner,
    );
  }
}

class _Identity extends StatelessWidget {
  final _ShiftMetrics m;
  final bool big;
  final bool showShiftLine;
  const _Identity({
    required this.m,
    this.big = false,
    this.showShiftLine = true,
  });

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
                valueColor: AlwaysStoppedAnimation<Color>(sc.accentText),
              ),
            ),
            StaffAvatar.raw(
              initials: m.initials,
              colorHex: m.avatarColorHex,
              size: size,
            ),
          ],
        ),
        const SizedBox(width: Sp.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.name,
                style: SatType.sans(
                  size: big ? 24 : 22,
                  weight: FontWeight.w600,
                  letterSpacing: -0.32,
                  color: sc.textHi,
                ),
              ),
              const SizedBox(height: Sp.sHair),
              Text(
                m.roleLabel,
                style: SatType.sans(size: 13, color: sc.textMd),
              ),
              if (showShiftLine) ...[
                const SizedBox(height: Sp.s1h),
                Text(
                  'MULAI ${m.shiftStart} · ${m.elapsedLabel.toUpperCase()} BERJALAN',
                  style: SatType.mono(
                    size: 11,
                    color: sc.textLo,
                    letterSpacing: 0.44,
                  ),
                ),
              ],
            ],
          ),
        ),
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
      _Kpi(label: 'Tiket dikirim', value: '${m.ticketCount}'),
      _Kpi(label: 'Cover dilayani', value: '${m.openCovers}'),
      _Kpi(
        label: 'Pembatalan',
        value: '${m.voidCount}',
        tone: m.voidCount > 0 ? _Tone.urgent : _Tone.normal,
      ),
      _Kpi(
        label: 'Comp / modif',
        value: '${m.compCount + m.modifyCount}',
        tone: m.compCount > 0 ? _Tone.warn : _Tone.normal,
      ),
    ];

    if (columns >= 4) {
      return Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _KpiBox(kpi: items[i])),
            if (i != items.length - 1) const SizedBox(width: Sp.s2),
          ],
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _KpiBox(kpi: items[0])),
            const SizedBox(width: Sp.s2),
            Expanded(child: _KpiBox(kpi: items[1])),
          ],
        ),
        const SizedBox(height: Sp.s2),
        Row(
          children: [
            Expanded(child: _KpiBox(kpi: items[2])),
            const SizedBox(width: Sp.s2),
            Expanded(child: _KpiBox(kpi: items[3])),
          ],
        ),
      ],
    );
  }
}

enum _Tone { normal, urgent, warn }

class _Kpi {
  final String label;
  final String value;
  final _Tone tone;
  const _Kpi({
    required this.label,
    required this.value,
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
      decoration: SatBox.d(
        color: bg,
        borderRadius: SatR.a(16),
        border: SatB.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kpi.label.toUpperCase(),
            style: SatType.mono(
              size: 9,
              weight: FontWeight.w500,
              letterSpacing: 0.72,
              color: subColor,
            ),
          ),
          const SizedBox(height: Sp.s2h),
          Text(
            kpi.value,
            style: SatType.mono(
              size: 26,
              weight: FontWeight.w600,
              letterSpacing: -0.52,
              height: 1,
              color: valColor,
            ),
          ),
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
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: SatBox.d(
              color: sc.accentSoft,
              borderRadius: SatR.a(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.show_chart_rounded,
              size: 18,
              color: sc.accentText,
            ),
          ),
          const SizedBox(width: Sp.s3h),
          Expanded(
            child: Text(
              '$perHour tiket / jam',
              style: SatType.sans(
                size: 15,
                weight: FontWeight.w600,
                letterSpacing: -0.15,
                color: sc.textHi,
              ),
            ),
          ),
          Text(
            m.elapsedLabel,
            style: SatType.mono(
              size: 16,
              weight: FontWeight.w600,
              letterSpacing: -0.2,
              color: sc.textHi,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final List<AuditEntry> audit;
  final Map<String, String> tableNames;
  final int max;
  final bool padded;
  const _ActivityCard({
    required this.audit,
    required this.tableNames,
    required this.max,
    this.padded = false,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final inner = audit.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(Sp.s5),
            child: Text(
              'Belum ada entri audit. Pembatalan, comp, dan perubahan pasca-kirim muncul di sini.',
              style: SatType.sans(size: 13, color: sc.textLo, height: 1.5),
            ),
          )
        : Column(
            children: [
              for (var i = 0; i < audit.length && i < max; i++) ...[
                _AuditRow(entry: audit[i], tableNames: tableNames),
                if (i < (audit.length - 1).clamp(0, max - 1))
                  Divider(height: 1, color: sc.border0),
              ],
            ],
          );

    if (padded) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        decoration: SatBox.d(
          color: sc.bg2,
          border: SatB.all(color: sc.border0),
          borderRadius: SatR.a(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AKTIVITAS TERKINI',
                    style: SatType.mono(
                      size: 10,
                      weight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: sc.textLo,
                    ),
                  ),
                ),
                Text(
                  '${audit.length} entri',
                  style: SatType.mono(
                    size: 10,
                    color: sc.textDim,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sp.s2),
            inner,
          ],
        ),
      );
    }

    return Container(
      decoration: SatBox.d(
        color: sc.bg2,
        borderRadius: SatR.a(16),
        border: SatB.all(color: sc.border0),
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
      child: Text(
        label,
        style: SatType.mono(
          size: 10,
          weight: FontWeight.w500,
          letterSpacing: 1.2,
          color: sc.textLo,
        ),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final AuditEntry entry;
  final Map<String, String> tableNames;
  const _AuditRow({required this.entry, required this.tableNames});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final meta = <String>[
      if (entry.tableId.isNotEmpty)
        'Meja ${tableNames[entry.tableId] ?? entry.tableId}',
      formatClockId(entry.when),
      if (entry.approvedBy != null) 'disetujui ${entry.approvedBy}',
      if (entry.reason != null) entry.reason!,
    ].join(' · ');
    final (icon, bg, fg) = switch (entry.type) {
      AuditType.voidItem => (Icons.delete_outline, sc.urgentSoft, sc.urgent),
      AuditType.comp => (Icons.card_giftcard_rounded, sc.warnSoft, sc.warn),
      AuditType.modify => (Icons.edit_outlined, sc.infoSoft, sc.info),
      AuditType.fire => (
        Icons.local_fire_department,
        sc.accentSoft,
        sc.accentText,
      ),
      AuditType.tableMoved => (Icons.swap_horiz_rounded, sc.infoSoft, sc.info),
      AuditType.paymentRecorded => (
        Icons.payments_outlined,
        sc.successSoft,
        sc.success,
      ),
      AuditType.refund => (Icons.undo_rounded, sc.warnSoft, sc.warn),
      AuditType.discountApplied => (Icons.sell_outlined, sc.warnSoft, sc.warn),
      AuditType.discountRemoved => (Icons.sell_outlined, sc.infoSoft, sc.info),
      AuditType.billReopened => (
        Icons.lock_open_outlined,
        sc.infoSoft,
        sc.info,
      ),
      AuditType.billClosed => (
        Icons.receipt_long_outlined,
        sc.successSoft,
        sc.success,
      ),
      AuditType.staffCreated => (
        Icons.person_add_alt_1,
        sc.successSoft,
        sc.success,
      ),
      AuditType.staffDeleted => (Icons.person_remove, sc.urgentSoft, sc.urgent),
      AuditType.staffDisabled => (Icons.block, sc.urgentSoft, sc.urgent),
      AuditType.staffEnabled => (
        Icons.check_circle_outline,
        sc.successSoft,
        sc.success,
      ),
      AuditType.staffRoleChanged => (
        Icons.badge_outlined,
        sc.infoSoft,
        sc.info,
      ),
      AuditType.staffPinSet => (Icons.lock_reset, sc.infoSoft, sc.info),
      AuditType.staffPinReset => (Icons.lock_reset, sc.warnSoft, sc.warn),
      AuditType.roleCreated => (
        Icons.shield_outlined,
        sc.successSoft,
        sc.success,
      ),
      AuditType.roleRenamed => (Icons.edit_outlined, sc.infoSoft, sc.info),
      AuditType.roleDeleted => (
        Icons.shield_outlined,
        sc.urgentSoft,
        sc.urgent,
      ),
      AuditType.roleColorChanged => (
        Icons.palette_outlined,
        sc.infoSoft,
        sc.info,
      ),
      AuditType.roleCapabilityChanged => (
        Icons.key_outlined,
        sc.infoSoft,
        sc.info,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3h, vertical: Sp.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: SatBox.d(color: bg, borderRadius: SatR.a(8)),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: fg),
          ),
          const SizedBox(width: Sp.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: SatType.sans(
                    size: 13,
                    weight: FontWeight.w500,
                    letterSpacing: -0.13,
                    color: sc.textHi,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
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

class _EndShiftButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _EndShiftButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SatButton.outline(
        label: 'Akhiri shift & keluar',
        icon: Icons.logout_rounded,
        size: SatButtonSize.lg,
        onTap: onPressed,
      ),
    );
  }
}
