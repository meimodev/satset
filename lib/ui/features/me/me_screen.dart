import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/audit_repository.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/roles_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/server/server.dart' show serverRuntimeProvider;
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/state/ready_alert_view_model.dart';
import 'package:satset/ui/core/state/theme_view_model.dart';
import 'package:satset/ui/core/state/view_mode_view_model.dart';
import 'package:satset/ui/core/widgets/ready_banner.dart';
import 'package:satset/ui/core/widgets/ready_toast.dart';

import '../menu/modifier_sheet.dart';
import '../void_flow/line_item_action_sheet.dart';

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
    for (final tk in tickets[t.id] ?? const <Ticket>[]) {
      if (tk.status == TicketStatus.voided) continue;
      ticketCount++;
    }
  }
  final openCovers = myTables.fold<int>(
      0, (s, t) => s + (t.status != TableStatus.available ? t.pax : 0));
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
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(authStateProvider).user;
    final roles = ref.watch(rolesRepositoryProvider);
    // Hide staff/role admin audit rows from users without `manageStaff`.
    final canManageStaff = user != null &&
        !user.disabled &&
        roles.any((r) => r.id == user.roleId && r.has(Capability.manageStaff));
    final audit = canManageStaff
        ? rawAudit
        : [for (final e in rawAudit) if (!isAdminAuditType(e.type)) e];

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
    final roleLabel = (zone.isEmpty || zone == '—') ? roleName : '$roleName · $zone';

    // Elapsed from login. shiftStartedAt is the login ISO timestamp.
    final shiftIso = user?.shiftStartedAt ?? '';
    final shiftStartedDt = DateTime.tryParse(shiftIso);
    var elapsed = shiftStartedDt == null
        ? Duration.zero
        : DateTime.now().difference(shiftStartedDt);
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

    void toggleTheme() {
      final next =
          themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      ref.read(themeModeProvider.notifier).state = next;
    }

    // Phone/tablet layout toggle — only on the Server-mode host AND only on a
    // tablet device (forcing phone-layout on a real phone is a no-op, so staff
    // client phones never see it). `forcePhone` makes this tablet render the
    // phone layout; the icon flips to offer the way back.
    final l = context.layout;
    final forcePhone = ref.watch(forcePhoneViewProvider);
    final isServerHost = ref.watch(serverRuntimeProvider) != null;
    final showLayoutToggle = isServerHost && l.isTablet;
    void toggleLayout() =>
        ref.read(forcePhoneViewProvider.notifier).state = !forcePhone;

    Future<void> endShift() async {
      // Admin (Server mode): logout kills the embedded server — every staff
      // device disconnects and cannot reconnect until an admin re-signs-in.
      // Confirm first, warning about live tables. See ADR-0015.
      final isServer = ref.read(serverRuntimeProvider) != null;
      if (isServer) {
        final liveCount =
            tables.where((t) => t.status != TableStatus.available).length;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Akhiri sesi admin?'),
            content: Text(liveCount > 0
                ? '$liveCount meja masih aktif. Keluar akan mematikan server — '
                    'semua staff terputus dan tidak bisa menyambung sampai '
                    'admin masuk lagi.'
                : 'Keluar akan mematikan server. Staff tidak bisa menyambung '
                    'sampai admin masuk lagi.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Keluar & matikan'),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
      await ref.read(authStateProvider.notifier).signOut();
      if (context.mounted) context.go('/pin');
    }

    if (l.useTabletShell && !forcePhone) {
      return _MeTablet(
        m: m,
        audit: audit,
        tableNames: tableNames,
        themeMode: themeMode,
        onToggleTheme: toggleTheme,
        onEndShift: endShift,
        showLayoutToggle: showLayoutToggle,
        forcePhone: forcePhone,
        onToggleLayout: toggleLayout,
      );
    }
    return _MePhone(
      m: m,
      audit: audit,
      tableNames: tableNames,
      themeMode: themeMode,
      onToggleTheme: toggleTheme,
      onEndShift: endShift,
      showLayoutToggle: showLayoutToggle,
      forcePhone: forcePhone,
      onToggleLayout: toggleLayout,
    );
  }
}

// ────────────────────────────────── PHONE

class _MePhone extends StatelessWidget {
  final _ShiftMetrics m;
  final List<AuditEntry> audit;
  final Map<String, String> tableNames;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onEndShift;
  final bool showLayoutToggle;
  final bool forcePhone;
  final VoidCallback onToggleLayout;

  const _MePhone({
    required this.m,
    required this.audit,
    required this.tableNames,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onEndShift,
    required this.showLayoutToggle,
    required this.forcePhone,
    required this.onToggleLayout,
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
            _TopBar(
              themeMode: themeMode,
              onToggleTheme: onToggleTheme,
              showLayoutToggle: showLayoutToggle,
              forcePhone: forcePhone,
              onToggleLayout: onToggleLayout,
            ),
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
              child: _ActivityCard(audit: audit, tableNames: tableNames, max: 5),
            ),
            if (kDebugMode) ...[
              const _SectionLabel(label: 'DEBUG · TRIGGER UI'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _DebugSection(),
              ),
            ],
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
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onEndShift;
  final bool showLayoutToggle;
  final bool forcePhone;
  final VoidCallback onToggleLayout;

  const _MeTablet({
    required this.m,
    required this.audit,
    required this.tableNames,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onEndShift,
    required this.showLayoutToggle,
    required this.forcePhone,
    required this.onToggleLayout,
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
                    )),
              ),
              if (showLayoutToggle) ...[
                _LayoutToggleButton(
                    forcePhone: forcePhone, onTap: onToggleLayout),
                const SizedBox(width: 8),
              ],
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
                      _Identity(m: m, big: true, showShiftLine: false),
                      const SizedBox(height: 14),
                      _EndShiftButton(onPressed: onEndShift),
                      const SizedBox(height: 14),
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
                  child: _ActivityCard(
                      audit: audit,
                      tableNames: tableNames,
                      max: 9,
                      padded: true),
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
  final bool showLayoutToggle;
  final bool forcePhone;
  final VoidCallback onToggleLayout;
  const _TopBar({
    required this.themeMode,
    required this.onToggleTheme,
    required this.showLayoutToggle,
    required this.forcePhone,
    required this.onToggleLayout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 0),
      child: Row(
        children: [
          const Spacer(),
          if (showLayoutToggle) ...[
            _LayoutToggleButton(forcePhone: forcePhone, onTap: onToggleLayout),
            const SizedBox(width: 8),
          ],
          _ThemeIconButton(themeMode: themeMode, onTap: onToggleTheme),
        ],
      ),
    );
  }
}

/// Phone/tablet layout toggle, styled to match [_ThemeIconButton]. Shown only
/// on the Server-mode host tablet (see `MeScreen.build`). When [forcePhone] is
/// active the tablet is rendering the phone layout, so the icon offers the way
/// back to the tablet layout.
class _LayoutToggleButton extends StatelessWidget {
  final bool forcePhone;
  final VoidCallback onTap;
  const _LayoutToggleButton({required this.forcePhone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
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
            forcePhone ? Icons.tablet_mac_outlined : Icons.smartphone_outlined,
            size: 16,
            color: sc.textMd,
          ),
        ),
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
  final bool showShiftLine;
  const _Identity({required this.m, this.big = false, this.showShiftLine = true});

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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(m.avatarColorHex ?? 0xFFFF9233),
                    Color.alphaBlend(
                        Colors.black.withValues(alpha: 0.36),
                        Color(m.avatarColorHex ?? 0xFFFF9233)),
                  ],
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
              if (showShiftLine) ...[
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
            child: Text(
              '$perHour tiket / jam',
              style: SatType.sans(
                  size: 15,
                  weight: FontWeight.w600,
                  letterSpacing: -0.15,
                  color: sc.textHi),
            ),
          ),
          Text(m.elapsedLabel,
              style: SatType.mono(
                  size: 16,
                  weight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: sc.textHi)),
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
  const _ActivityCard(
      {required this.audit,
      required this.tableNames,
      required this.max,
      this.padded = false});

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
                _AuditRow(entry: audit[i], tableNames: tableNames),
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
      AuditType.fire => (Icons.local_fire_department, sc.accentSoft, sc.accent),
      AuditType.tableMoved => (Icons.swap_horiz_rounded, sc.infoSoft, sc.info),
      AuditType.paymentRecorded => (Icons.payments_outlined, sc.successSoft, sc.success),
      AuditType.refund => (Icons.undo_rounded, sc.warnSoft, sc.warn),
      AuditType.billReopened => (Icons.lock_open_outlined, sc.infoSoft, sc.info),
      AuditType.staffCreated => (Icons.person_add_alt_1, sc.successSoft, sc.success),
      AuditType.staffDeleted => (Icons.person_remove, sc.urgentSoft, sc.urgent),
      AuditType.staffDisabled => (Icons.block, sc.urgentSoft, sc.urgent),
      AuditType.staffEnabled => (Icons.check_circle_outline, sc.successSoft, sc.success),
      AuditType.staffRoleChanged => (Icons.badge_outlined, sc.infoSoft, sc.info),
      AuditType.staffPinSet => (Icons.lock_reset, sc.infoSoft, sc.info),
      AuditType.staffPinReset => (Icons.lock_reset, sc.warnSoft, sc.warn),
      AuditType.roleCreated => (Icons.shield_outlined, sc.successSoft, sc.success),
      AuditType.roleRenamed => (Icons.edit_outlined, sc.infoSoft, sc.info),
      AuditType.roleDeleted => (Icons.shield_outlined, sc.urgentSoft, sc.urgent),
      AuditType.roleColorChanged => (Icons.palette_outlined, sc.infoSoft, sc.info),
      AuditType.roleCapabilityChanged => (Icons.key_outlined, sc.infoSoft, sc.info),
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
                  meta,
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
            onTap: () => _showModifierSheetDebug(context, ref),
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
              tableLabel: 'T2',
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
    useRootNavigator: true,
    backgroundColor: context.sat.bg1,
    builder: (ctx) => const Padding(
      padding: EdgeInsets.fromLTRB(0, 24, 0, 32),
      child: ReadyBanner(),
    ),
  );
}

void _showModifierSheetDebug(BuildContext context, WidgetRef ref) {
  final items = ref.read(menuItemsProvider);
  if (items.isEmpty) return;
  final item = items.firstWhere(
    (i) => i.modifierGroups.isNotEmpty,
    orElse: () => items.first,
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
  ticket ??= _stubTicket(ref);
  showLineItemActionSheet(
    context: context,
    tableId: tableId,
    ticket: ticket,
  );
}

Ticket _stubTicket(WidgetRef ref) {
  final items = ref.read(menuItemsProvider);
  final item = items.isEmpty ? null : items.first;
  return Ticket(
    id: 'debug-${DateTime.now().millisecondsSinceEpoch}',
    itemId: item?.id ?? 'debug-item',
    name: item?.name ?? 'Debug item',
    course: CourseId.mains,
    qty: 1,
    price: item?.basePrice ?? 0,
    status: TicketStatus.sent,
    sentAt: '17:42',
    sentAtTime: DateTime.now(),
  );
}
