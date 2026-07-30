import 'dart:async';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';

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
import 'package:satset/ui/features/orders/view_models/orders_scope.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/state/theme_view_model.dart';
import 'package:satset/ui/core/widgets/staff_avatar.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

/// What the "Saya" tab shows: a **live snapshot** of the shift you are in, not a
/// cumulative tally of it.
///
/// Every count here describes what you are holding *right now* — outstanding
/// lines, seated covers, tables in hand. Closing a table correctly therefore
/// makes these numbers go **down**, which is intended: this screen answers
/// "what is on my plate", not "what did I do tonight". The cumulative reading
/// (sales, tickets per hour, covers served across the shift) needs closed
/// [[Close (table) / Table session|TableSessions]], which clients never receive
/// — see ADR-0065 for why that endpoint was declined.
///
/// The integrity counts are the exception: they come from the audit feed, which
/// *is* shift-cumulative and scoped server-side to you.
class _ShiftMetrics {
  final String name;
  final String roleLabel;
  final String initials;
  final int? avatarColorHex;
  final String shiftStart;
  final Duration elapsed;

  /// Outstanding lines on the tables you hold — [isOutstandingTicket].
  final int openTickets;

  /// Outstanding lines split by where the food is, for the breakdown card.
  final Map<TicketStatus, int> byStatus;

  final int openCovers;
  final int openTables;

  /// Your voids this shift. Comps are **inside** this number, not beside it: a
  /// comp is a void carrying reason `comp`, never its own audit type.
  final int voidCount;

  const _ShiftMetrics({
    required this.name,
    required this.roleLabel,
    required this.initials,
    required this.avatarColorHex,
    required this.shiftStart,
    required this.elapsed,
    required this.openTickets,
    required this.byStatus,
    required this.openCovers,
    required this.openTables,
    required this.voidCount,
  });

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
  required String? meId,
  required String userName,
  required String userInitials,
  required int? userAvatarColorHex,
  required String roleLabel,
  required String shiftStart,
  required Duration elapsed,
}) {
  // A table is yours when you are its current handler (`lastActorId`) — the
  // same server-authoritative key the Pesanan board scopes on (ADR-0056). The
  // old `VenueTable.mine` flag was set optimistically on seat and never
  // restored from the server, so it silently emptied this screen on every WS
  // update, resync and relaunch.
  final myTables = (meId == null || meId.isEmpty)
      ? const <VenueTable>[]
      : tables.where((t) => t.lastActorId == meId).toList();

  final byStatus = <TicketStatus, int>{};
  for (final t in myTables) {
    // Lines are keyed by visitId (ADR-0034); resolve through the table's
    // current visit rather than its (reused) id.
    final vid = t.currentVisitId;
    final lines = (vid != null && vid.isNotEmpty)
        ? (tickets[vid] ?? const <Ticket>[])
        : const <Ticket>[];
    for (final tk in lines) {
      if (!isOutstandingTicket(tk.status)) continue;
      byStatus[tk.status] = (byStatus[tk.status] ?? 0) + 1;
    }
  }
  final openTickets = byStatus.values.fold<int>(0, (a, b) => a + b);

  final live = myTables
      .where((t) => t.status != TableStatus.available)
      .toList();
  final openCovers = live.fold<int>(0, (s, t) => s + t.pax);

  // `audit` arrives pre-scoped to this user and this shift by the server, so a
  // plain count is already "my voids this shift" (ADR-0065).
  final voidCount = audit.where((a) => a.type == AuditType.voidItem).length;

  return _ShiftMetrics(
    name: userName,
    roleLabel: roleLabel,
    initials: userInitials,
    avatarColorHex: userAvatarColorHex,
    shiftStart: shiftStart,
    elapsed: elapsed,
    openTickets: openTickets,
    byStatus: byStatus,
    openCovers: openCovers,
    openTables: live.length,
    voidCount: voidCount,
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
    // The feed is already scoped to this user and shift server-side, so these
    // are all your own rows. The `manageStaff` filter still applies: a waiter
    // whose PIN was reset by a manager should not read that row on their own
    // shift summary, even though it is filed against them.
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
      meId: user?.id,
      userName: user?.name ?? '—',
      userInitials: user?.initials ?? '—',
      userAvatarColorHex: user?.avatarColorHex,
      roleLabel: roleLabel,
      shiftStart: shiftStart,
      elapsed: elapsed,
    );

    void pickTheme() => showThemeSheet(context, ref);

    final l = context.layout;

    // A Server-mode admin has exactly one exit. Their sign-out kills the
    // embedded server either way (ADR-0015), so an exit promising to preserve
    // their shift while taking the venue offline would be a lie — for this one
    // user the "lightweight" action is the most destructive in the app.
    // Everyone else, admin-clients included, gets both.
    final isServer = ref.read(serverRuntimeProvider) != null;

    // "Keluar" — drop the session, leave the shift running. The next PIN
    // sign-in resumes it, on this handset or another (ADR-0065). No confirm:
    // it is the frequent action and nothing is lost.
    Future<void> switchUser() async {
      await ref.read(authStateProvider.notifier).signOut();
      if (context.mounted) context.go('/pin');
    }

    // "Akhiri shift & keluar" — close the shift *and* sign out.
    Future<void> endShift() async {
      final liveCount = tables
          .where((t) => t.status != TableStatus.available)
          .length;
      final ok = await showSatDialog<bool>(
        context,
        builder: (ctx) => AlertDialog(
          title: Text(isServer ? 'Akhiri sesi admin?' : 'Akhiri shift?'),
          content: Text(
            isServer
                ? (liveCount > 0
                      ? '$liveCount meja masih aktif. Keluar akan mematikan server — '
                            'semua staff terputus dan tidak bisa menyambung sampai '
                            'admin masuk lagi.'
                      : 'Keluar akan mematikan server. Staff tidak bisa menyambung '
                            'sampai admin masuk lagi.')
                // Spell out the one thing that separates this from "Keluar":
                // the shift closes, so signing back in starts a new one.
                : 'Shift ditutup dan hitungannya berhenti. Masuk lagi akan '
                      'memulai shift baru. Untuk menyerahkan perangkat tanpa '
                      'menutup shift, pakai "Keluar".',
          ),
          actions: [
            SatButton.ghost(
              label: AppStrings.cancel,
              onTap: () => Navigator.pop(ctx, false),
            ),
            SatButton.danger(
              label: isServer ? 'Keluar & matikan' : 'Akhiri shift',
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await ref.read(authStateProvider.notifier).signOut(endShift: true);
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
        onSwitchUser: isServer ? null : switchUser,
      );
    }
    return _MePhone(
      m: m,
      audit: audit,
      tableNames: tableNames,
      theme: theme,
      onPickTheme: pickTheme,
      onEndShift: endShift,
      onSwitchUser: isServer ? null : switchUser,
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

  /// Null for a Server-mode admin, who has no shift-preserving exit.
  final VoidCallback? onSwitchUser;

  const _MePhone({
    required this.m,
    required this.audit,
    required this.tableNames,
    required this.theme,
    required this.onPickTheme,
    required this.onEndShift,
    required this.onSwitchUser,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.layout;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
        child: ListView(
          // Not `l.topInset` — that token clears a status bar for screens with
          // no chrome above them, and this one always renders under SatAppBar.
          padding: EdgeInsets.fromLTRB(0, Sp.s6, 0, l.bottomInset + 40),
          children: [
            _TopBar(theme: theme, onPickTheme: onPickTheme),
            const SizedBox(height: Sp.s2),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: _Identity(m: m),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: _EndShiftButton(onPressed: onEndShift, onSwitchUser: onSwitchUser),
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
            const SatSectionLabel(
              'Aktivitas terbaru',
              padding: EdgeInsets.fromLTRB(Sp.s5, Sp.s6, Sp.s5, Sp.s2h),
            ),
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

  /// Null for a Server-mode admin, who has no shift-preserving exit.
  final VoidCallback? onSwitchUser;

  const _MeTablet({
    required this.m,
    required this.audit,
    required this.tableNames,
    required this.theme,
    required this.onPickTheme,
    required this.onEndShift,
    required this.onSwitchUser,
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
                  style: SatType.monoS(color: sc.textLo),
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
                      _EndShiftButton(onPressed: onEndShift, onSwitchUser: onSwitchUser),
                      const SizedBox(height: Sp.s3h),
                      _KpiGrid(m: m, columns: 4),
                      const SizedBox(height: Sp.s3),
                      _PacingCard(m: m, big: true),
                    ],
                  ),
                ),
                const SizedBox(width: Sp.s6),
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
              Text(m.name, style: SatType.h2(color: sc.textHi)),
              const SizedBox(height: Sp.sHair),
              Text(m.roleLabel, style: SatType.bodyM(color: sc.textMd)),
              if (showShiftLine) ...[
                const SizedBox(height: Sp.s1h),
                Text(
                  'MULAI ${m.shiftStart} · ${m.elapsedLabel.toUpperCase()} BERJALAN',
                  style: SatType.monoS(color: sc.textLo),
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
    // Present tense throughout: these are live counts of what you hold now, so
    // past-tense labels ("Tiket dikirim") would promise a shift total the
    // numbers do not carry.
    final items = <_Kpi>[
      _Kpi(label: 'Tiket terbuka', value: '${m.openTickets}'),
      _Kpi(label: 'Cover dilayani', value: '${m.openCovers}'),
      _Kpi(
        label: 'Pembatalan',
        value: '${m.voidCount}',
        tone: m.voidCount > 0 ? _Tone.urgent : _Tone.normal,
      ),
      // Replaces a "Comp / modif" box that could only ever read zero:
      // `AuditType.comp` and `.modify` are emitted nowhere, because a comp is a
      // void carrying reason `comp` and lands in Pembatalan above.
      _Kpi(label: 'Meja aktif', value: '${m.openTables}'),
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
          Text(kpi.label.toUpperCase(), style: SatType.monoS(color: subColor)),
          const SizedBox(height: Sp.s2h),
          Text(kpi.value, style: SatType.monoL(color: valColor)),
        ],
      ),
    );
  }
}

/// Where your outstanding food currently is — the same lines the "Tiket
/// terbuka" box totals, split by status.
///
/// This replaced a "tiket / jam" rate that divided a *live* ticket count by
/// *shift-long* elapsed minutes. That ratio fell as you closed tables, so it
/// read highest when you were furthest behind and reached zero at the end of a
/// well-run shift. An honest rate needs cumulative sent counts, which this
/// screen deliberately does not fetch (ADR-0065).
class _PacingCard extends StatelessWidget {
  final _ShiftMetrics m;
  final bool big;
  const _PacingCard({required this.m, this.big = false});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    // Kitchen order, not enum order: the closer to the guest, the later it
    // reads — so a waiter scans left-to-right toward what to pick up next.
    const order = [
      (TicketStatus.held, 'ditahan'),
      (TicketStatus.sent, 'terkirim'),
      (TicketStatus.prep, 'disiapkan'),
      (TicketStatus.cooked, 'matang'),
      (TicketStatus.ready, 'siap'),
    ];
    final parts = <String>[
      for (final (s, label) in order)
        if ((m.byStatus[s] ?? 0) > 0) '${m.byStatus[s]} $label',
    ];
    final hasAny = parts.isNotEmpty;
    // A lull is the common case mid-shift, and three zeros would read as
    // broken. Say the state in words instead.
    final text = hasAny ? parts.join(' · ') : 'Tidak ada tiket terbuka';
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
              color: hasAny ? sc.accentSoft : sc.bg3,
              borderRadius: SatR.a(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              hasAny
                  ? Icons.receipt_long_outlined
                  : Icons.check_circle_outline_rounded,
              size: 18,
              color: hasAny ? sc.accentText : sc.textLo,
            ),
          ),
          const SizedBox(width: Sp.s3h),
          Expanded(
            child: Text(
              text,
              style: SatType.labelL(
                color: hasAny ? sc.textHi : sc.textLo,
              ),
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
              style: SatType.bodyM(color: sc.textLo),
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
      return SatCard.section(
        header: 'Aktivitas terkini',
        headerTrailing: Text(
          '${audit.length} entri',
          style: SatType.monoS(color: sc.textDim),
        ),
        padding: const EdgeInsets.fromLTRB(Sp.s5, Sp.s4h, Sp.s5, Sp.s1h),
        child: inner,
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
                Text(entry.title, style: SatType.bodyM(color: sc.textHi)),
                const SizedBox(height: Sp.s1),
                Text(meta, style: SatType.monoS(color: sc.textLo)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The shift's two exits (ADR-0065).
///
/// Hierarchy follows frequency, not severity of name: handing a shared handset
/// to a colleague happens many times a service and gets the prominent control,
/// while ending a shift happens once and is deliberately quieter so it takes
/// aim. [onSwitchUser] is null for a Server-mode admin, who has only one exit
/// because their sign-out takes the venue offline regardless (ADR-0015).
class _EndShiftButton extends StatelessWidget {
  final VoidCallback onPressed;
  final VoidCallback? onSwitchUser;
  const _EndShiftButton({required this.onPressed, this.onSwitchUser});

  @override
  Widget build(BuildContext context) {
    final endShift = SizedBox(
      width: double.infinity,
      child: SatButton.ghost(
        label: 'Akhiri shift & keluar',
        icon: Icons.logout_rounded,
        size: SatButtonSize.lg,
        onTap: onPressed,
      ),
    );
    if (onSwitchUser == null) {
      // Sole exit for a Server-mode admin — carries the weight, so it keeps the
      // stronger outline treatment rather than reading as a footnote.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SatButton.outline(
          label: 'Keluar',
          icon: Icons.swap_horiz_rounded,
          size: SatButtonSize.lg,
          onTap: onSwitchUser!,
        ),
        const SizedBox(height: Sp.s2),
        endShift,
      ],
    );
  }
}
