import 'package:satset/core/localization/labels.dart';
import 'package:satset/core/localization/audit_text.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/app_version.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/repositories/audit_repository.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/roles_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/server/server.dart' show serverRuntimeProvider;
import 'package:satset/ui/core/design/audit_visuals.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/shell_inset.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/features/me/widgets/theme_sheet.dart';
import 'package:satset/ui/features/orders/view_models/orders_scope.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/state/theme_view_model.dart';
import 'package:satset/ui/core/state/tickers.dart';
import 'package:satset/ui/core/widgets/staff_avatar.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/features/me/widgets/locale_sheet.dart';
import 'package:satset/data/services/send_queue_service.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';

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

  /// The raw shift start, for the live counter. `shiftStart` is the formatted
  /// clock label; this is what the seconds tick against.
  final DateTime? shiftStartedAt;
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
    required this.shiftStartedAt,
    required this.elapsed,
    required this.openTickets,
    required this.byStatus,
    required this.openCovers,
    required this.openTables,
    required this.voidCount,
  });

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
  required DateTime? shiftStartedAt,
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
    shiftStartedAt: shiftStartedAt,
    elapsed: elapsed,
    openTickets: openTickets,
    byStatus: byStatus,
    openCovers: openCovers,
    openTables: live.length,
    voidCount: voidCount,
  );
}

/// "MULAI 09:00 · 3J 12M 20D BERJALAN".
///
/// The shift counter carries seconds, and it is the only thing on this screen
/// that does — so it is the only thing that watches the seconds ticker. The
/// screen used to setState around all of this once a second, rebuilding the
/// table list, the ticket map and the audit feed to move that last digit.
/// See ADR-0081.
class _ShiftLine extends ConsumerWidget {
  final String shiftStart;
  final DateTime? startedAt;
  const _ShiftLine({required this.shiftStart, required this.startedAt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(secondTickerProvider);
    final started = startedAt;
    // "MULAI — · 0J 0M BERJALAN" reads as a shift that began at an unknown
    // time and is running; the truth is that none is (ADR-0097). Say that.
    if (started == null) {
      return Text(
        context.l10n.meNoShift.toUpperCase(),
        style: SatType.monoS(color: context.sat.textLo),
      );
    }
    var elapsed = SatClock.now().difference(started);
    if (elapsed.isNegative) elapsed = Duration.zero;
    return Text(
      context.l10n
          .meShiftLine(shiftStart, formatElapsed(context.l10n, elapsed))
          .toUpperCase(),
      style: SatType.monoS(color: context.sat.textLo),
    );
  }
}

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The shift ring below is a whole-minute fraction of an 8h target, so the
    // body follows the minute ticker; _ShiftLine owns the seconds.
    ref.watch(minuteTickerProvider);
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
      roleName = match.isNotEmpty
          ? match.first.name
          : userRoleLabel(context.l10n, user.role);
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
      shiftStartedAt: shiftStartedDt,
      elapsed: elapsed,
    );

    void pickTheme() => showThemeSheet(context, ref);

    final l = context.layout;

    // A Server-mode admin's sign-out kills the embedded server too (ADR-0015),
    // which is why they alone still confirm: for that one user this is the most
    // destructive action in the app, and it takes the venue offline with it.
    final isServer = ref.read(serverRuntimeProvider) != null;

    // The one exit: close the shift *and* sign out (ADR-0097).
    //
    // No `context.go` afterwards: `signOut` clears the auth state (and, for an
    // admin, `apiConfigProvider`), each of which bumps the router's refresh
    // listener, and the redirect sends `/me` → `/pin` on its own. An explicit
    // go here raced those two async redirects. See ADR-0078.
    Future<void> endShift() async {
      // A shift cannot close over undelivered orders: the guest ordered, the
      // kitchen never heard, and signing out is the moment that backlog stops
      // having an owner. Either reconnect, or say out loud that they are gone.
      final pending = ref.read(sendQueueProvider);
      if (pending.isNotEmpty) {
        final drop = await showSatDialog<bool>(
          context,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.sendQueueTertunda),
            content: Text(context.l10n.sendQueueBlockEndShift(pending.length)),
            actions: [
              SatButton.ghost(
                label: context.l10n.cancel,
                onTap: () => Navigator.pop(ctx, false),
              ),
              SatButton.danger(
                label: context.l10n.sendQueueDiscardAll,
                onTap: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        );
        if (drop != true) return;
        // ponytail: local-only. The audit writer lives on the host and the
        // host is exactly what is missing here; a queued audit intent would be
        // a second thing to lose. The discard is logged on the device.
        SatLog.repo('sendQueue.discardAll n=${pending.length} at end-shift');
        await ref.read(sendQueueProvider.notifier).discardAll();
        if (!context.mounted) return;
      }
      // Staff sign out without a confirm. It is the frequent action now that
      // handing a handset over goes through it, and the thing it costs — the
      // shift — is recoverable by signing back in. The admin's is not: it takes
      // the venue's server down with it.
      if (isServer) {
        final liveCount = tables
            .where((t) => t.status != TableStatus.available)
            .length;
        final ok = await showSatDialog<bool>(
          context,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.meEndAdminTitle),
            content: Text(
              liveCount > 0
                  ? context.l10n.meEndServerBodyLive(liveCount)
                  : context.l10n.meEndServerBody,
            ),
            actions: [
              SatButton.ghost(
                label: context.l10n.cancel,
                onTap: () => Navigator.pop(ctx, false),
              ),
              SatButton.danger(
                label: context.l10n.meEndAndShutdown,
                onTap: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
      // The redirect owns the navigation. See ADR-0078.
      await ref.read(authStateProvider.notifier).signOut();
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

  /// Null for a Server-mode admin, who has no shift-preserving exit.

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
          // Not `l.topInset` — that token clears a status bar for screens with
          // no chrome above them, and this one always renders under SatAppBar.
          padding: EdgeInsets.fromLTRB(0, Sp.s6, 0, context.shellInset),
          children: [
            _TopBar(theme: theme, onPickTheme: onPickTheme),
            const SizedBox(height: Sp.s2),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: _Identity(m: m),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Column(
                children: [
                  _EndShiftButton(onPressed: onEndShift),
                  const SizedBox(height: Sp.s2),
                  const _VersionLine(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.s4),
              child: _MyPendingCard(tableNames: tableNames),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 22, 32, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _ShiftLine(
                  shiftStart: m.shiftStart,
                  startedAt: m.shiftStartedAt,
                ),
              ),
              const _LocaleButton(),
              const SizedBox(width: Sp.s2),
              _ThemeButton(theme: theme, onTap: onPickTheme),
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
                      const SizedBox(height: Sp.s2),
                      const _VersionLine(),
                      const SizedBox(height: Sp.s3h),
                      _MyPendingCard(tableNames: tableNames),
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

/// What this handset is still holding, on the screen the waiter checks before
/// walking away from a shift.
///
/// Device-wide, not per-user: the queue belongs to the handset (ADR-0065 lets a
/// shift move between them), so showing only "mine" would hide a backlog from
/// the one person looking at it. Absent entirely when there is nothing pending.
class _MyPendingCard extends ConsumerWidget {
  const _MyPendingCard({required this.tableNames});

  final Map<String, String> tableNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(sendQueueProvider);
    if (pending.isEmpty) return const SizedBox.shrink();
    final sc = context.sat;
    final l = context.l10n;

    return SatCard.section(
      header: l.sendQueueTertunda,
      headerTrailing: SatChip.tag(
        label: l.sendQueuePending(pending.length),
        hue: SatChipHue.warn,
        size: SatChipSize.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final i in pending)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tableNames[i.tableId] ?? i.tableId,
                      style: SatType.bodyM(color: sc.textHi),
                    ),
                  ),
                  Text(
                    l.sendQueueCapturedAt(
                      formatClockId(i.capturedAt.toIso8601String()),
                    ),
                    style: SatType.bodyS(color: sc.textDim),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

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
          const _LocaleButton(),
          const SizedBox(width: Sp.s2),
          _ThemeButton(theme: theme, onTap: onPickTheme),
        ],
      ),
    );
  }
}

/// Opens the language sheet, and names the language it would change.
///
/// Self-contained rather than taking an `onTap` the way [_ThemeButton] does:
/// a `ConsumerWidget` already holds the `ref` the sheet needs, so threading a
/// callback through four widgets to reach the same place would be ceremony.
/// The label is the language **tag**, not its name — `Bahasa Indonesia` does
/// not fit a phone top bar next to a theme name, and the two-letter code is
/// what a bilingual user is scanning for anyway.
class _LocaleButton extends ConsumerWidget {
  const _LocaleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(satLocaleProvider);
    final tag = locale.languageCode.toUpperCase();
    void open() => showLocaleSheet(context, ref);

    // Same reasoning as [_ThemeButton]: SatButton would name itself "ID,
    // button", which says nothing about what the tap does.
    return Semantics(
      button: true,
      label: '${context.l10n.a11yPickLocale}, $tag',
      excludeSemantics: true,
      onTap: open,
      child: SatButton.outline(
        label: tag,
        icon: Icons.translate_rounded,
        onTap: open,
      ),
    );
  }
}

/// Opens the theme sheet, and names the theme it would change.
///
/// This was a 32px ring holding a dot of the active accent — a truer preview
/// than a sun/moon glyph (the six themes are three brightness pairs), but it
/// read as a status light rather than a control, and it sat under the 44px
/// target every other tap target on this screen clears. The label carries the
/// identity now; the palette preview lives in the sheet, where the swatches
/// are judged side by side anyway.
class _ThemeButton extends StatelessWidget {
  final SatTheme theme;
  final VoidCallback onTap;
  const _ThemeButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // `excludeSemantics` because SatButton names itself after its label, which
    // here is a theme name — "Neon Terang, button" says nothing about what the
    // tap does. `onTap` is re-declared on the node it replaces, or the exclusion
    // takes the activation with it.
    return Semantics(
      button: true,
      label: '${context.l10n.a11yPickTheme}, ${theme.label}',
      excludeSemantics: true,
      onTap: onTap,
      child: SatButton.outline(
        label: theme.label,
        icon: Icons.palette_outlined,
        onTap: onTap,
      ),
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
              // Not a busy spinner and deliberately not `SatSpinner`: this
              // ring is **determinate**, and the arc is the datum — how far
              // through their shift the person is. `SatSpinner` carries one
              // bit (something is happening); this carries a number.
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
                _ShiftLine(
                  shiftStart: m.shiftStart,
                  startedAt: m.shiftStartedAt,
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
      _Kpi(label: context.l10n.meKpiOpenTickets, value: '${m.openTickets}'),
      _Kpi(label: context.l10n.meKpiCovers, value: '${m.openCovers}'),
      _Kpi(
        label: context.l10n.auditTileVoid,
        value: '${m.voidCount}',
        tone: m.voidCount > 0 ? _Tone.urgent : _Tone.normal,
      ),
      // Replaces a "Comp / modif" box that could only ever read zero:
      // `AuditType.comp` and `.modify` are emitted nowhere, because a comp is a
      // void carrying reason `comp` and lands in Pembatalan above.
      _Kpi(label: context.l10n.zoneAdminTableActive, value: '${m.openTables}'),
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
    final order = [
      (TicketStatus.held, context.l10n.meShiftHeld),
      (TicketStatus.sent, context.l10n.meShiftSent),
      (TicketStatus.prep, context.l10n.meShiftPrep),
      (TicketStatus.cooked, context.l10n.meShiftCooked),
      (TicketStatus.ready, context.l10n.meShiftReady),
    ];
    final parts = <String>[
      for (final (s, label) in order)
        if ((m.byStatus[s] ?? 0) > 0) '${m.byStatus[s]} $label',
    ];
    final hasAny = parts.isNotEmpty;
    // A lull is the common case mid-shift, and three zeros would read as
    // broken. Say the state in words instead.
    final text = hasAny ? parts.join(' · ') : context.l10n.meNoOpenTickets;
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
              style: SatType.labelL(color: hasAny ? sc.textHi : sc.textLo),
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
              context.l10n.meAuditEmpty,
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
        header: context.l10n.meRecentActivity,
        headerTrailing: Text(
          context.l10n.meAuditCount(audit.length),
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
        context.l10n.meAuditTable(tableNames[entry.tableId] ?? entry.tableId),
      formatClockId(entry.when),
      if (entry.approvedBy != null) 'disetujui ${entry.approvedBy}',
      if (entry.reason != null) entry.reason!,
    ].join(' · ');
    final (:icon, :bg, :fg) = auditTone(entry.type, sc);
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
                  auditText(context.l10n, entry),
                  style: SatType.bodyM(color: sc.textHi),
                ),
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

/// Which build this is. Read from the installed package rather than a constant
/// (see [AppVersion]) — a number kept in step with `pubspec.yaml` by hand is a
/// number that says 1.0.0 forever. Empty on a platform that cannot answer, and
/// the line is then absent rather than showing an empty bracket.
class _VersionLine extends StatelessWidget {
  const _VersionLine();

  @override
  Widget build(BuildContext context) {
    if (AppVersion.value.isEmpty) return const SizedBox.shrink();
    return Text(
      context.l10n.meVersion(AppVersion.value, AppVersion.build),
      textAlign: TextAlign.center,
      style: SatType.monoS(color: context.sat.textDim),
    );
  }
}

/// The shift's one exit (ADR-0097).
///
/// There were two until handing a shared handset over stopped being free: the
/// prominent control dropped the session and left the shift running, and the
/// quieter one ended it. Now every sign-out ends the shift, so there is one
/// control. It is labelled plainly "Keluar": there is no longer another exit to
/// tell it apart from, and the elapsed shift clock sits directly above it.
class _EndShiftButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _EndShiftButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SatButton.outline(
        label: context.l10n.meSignOut,
        icon: Icons.logout_rounded,
        size: SatButtonSize.lg,
        onTap: onPressed,
      ),
    );
  }
}
