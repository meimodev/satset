import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/state/tickers.dart';
import 'package:satset/ui/core/widgets/staff_avatar.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart' show SatBackButton;
import 'package:satset/core/localization/locale_view_model.dart';

/// Single responsive app bar used everywhere chrome is needed.
///
/// Tablet: 64h slab, crumb trail on the left, a status cluster on the right —
/// sync, shift elapsed, wall clock. No avatar; the side rail owns that.
/// Phone: status bar + a 56h row, two slots. Left is the shift cluster *or* a
/// back button, never both; right is sync and the current user's avatar.
/// Crumbs are dropped here: at 402px the trail truncates to its last segment
/// anyway, and the parent is one back-tap away. See ADR-0062 for why the phone
/// row is this spare — it is budgeted against a 360dp handset, not a 411dp one.
class SatAppBar extends ConsumerWidget {
  final VoidCallback? onBack;

  /// Path to the current screen *below the venue*, coarsest first:
  /// `['Meja 5', 'Teras']`. The venue's own name is prepended here rather than
  /// at the call site — see [_venuePrefixed]. Tablet only.
  final List<String> crumbs;

  /// Extra status chips, rendered ahead of the sync indicator on both layouts.
  final List<Widget> trailingPills;

  /// Off on tablet, where [TabletSideRail] carries the avatar instead.
  final bool showAvatar;
  final Color? backgroundColor;

  const SatAppBar({
    super.key,
    this.onBack,
    this.crumbs = const [],
    this.trailingPills = const [],
    this.showAvatar = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.layout;
    // Only the tablet branch renders crumbs, so the venue name is only read
    // there — a phone bar must not subscribe to venue settings for nothing.
    if (!l.useTabletShell) return _phone(context);
    return _tablet(
      context,
      _venuePrefixed(
        ref.watch(venueSettingsProvider.select((s) => s.displayName)),
      ),
    );
  }

  /// Every trail in the app leads with the venue's name, prepended in one place
  /// so no screen can forget it and none has to plumb the setting (ADR-0058).
  /// An unnamed venue drops the segment rather than printing a placeholder that
  /// would read as the Venue *hub* — the trail fails short, never confident.
  List<String> _venuePrefixed(String venueName) => [
    if (venueName.isNotEmpty) venueName,
    ...crumbs,
  ];

  Color _resolveBg(SatColors sc) {
    if (backgroundColor != null) return backgroundColor!;
    return switch (SatShape.skin) {
      SatSkin.brutal => SatShape.brutalPaper ? sc.accent : sc.bg1,
      // Glow's chrome is a surface panel over the page, not the page itself —
      // the bar has to read as a separate slab from the content under it.
      SatSkin.glow => sc.bg1,
      SatSkin.lembut => sc.bg0,
    };
  }

  /// The rule under a top bar. Fat ink under brutal; a palette hairline under
  /// both others — Glow's `border0` is the α0.05 the design calls `--hair`.
  static BorderSide _rule(SatColors sc) => SatB.side(
    color: SatShape.brutal ? SatShape.ink : sc.border0,
    width: switch (SatShape.skin) {
      SatSkin.brutal => SatShape.brutalBorder,
      SatSkin.lembut || SatSkin.glow => 1,
    },
  );

  Widget _phone(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;

    return Container(
      decoration: SatBox.d(
        color: _resolveBg(sc),
        border: Border(bottom: _rule(sc)),
      ),
      // The status bar and nothing else. `l.topInset` adds another 24 on top of
      // it, which is breathing room for screens that render *bare* — this bar
      // is the chrome those screens don't have, so paying it here just made the
      // phone bar 30dp taller than it reads. Height comes from the row.
      padding: EdgeInsets.fromLTRB(Sp.s4, l.padding.top, Sp.s4, 0),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button and shift cluster are exclusive. The cluster is shell
            // chrome — a glance at your own shift — and a screen you can back
            // out of is a task, not the shell. It is also the only way the row
            // fits a 360dp phone: cluster + back + sync + avatar overruns by
            // ~60dp there, and by ~8dp even on a 411dp handset (ADR-0062).
            if (onBack != null)
              SatBackButton(onTap: onBack!)
            else
              const _ShiftCluster(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final pill in trailingPills) ...[
                  pill,
                  const SizedBox(width: Sp.s2),
                ],
                // Bare dot rather than the tablet's pill: the phone row has no
                // width to spend on an enclosure, and none to spend narrating
                // a healthy link either — see [_SyncStatus].
                const _SyncStatus(bare: true),
                if (showAvatar) ...[
                  const SizedBox(width: Sp.s3),
                  const _BarAvatar(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tablet(BuildContext context, List<String> trail) {
    final sc = context.sat;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: Sp.s6),
      decoration: SatBox.d(
        color: _resolveBg(sc),
        border: Border(bottom: _rule(sc)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            SatBackButton(onTap: onBack!),
            const SizedBox(width: Sp.s2h),
          ],
          Expanded(child: _Crumbs(trail)),
          const SizedBox(width: Sp.s4),
          for (final pill in trailingPills) ...[
            pill,
            const SizedBox(width: Sp.s3h),
          ],
          const _SyncStatus(),
          const SizedBox(width: Sp.s3h),
          const _ShiftCluster(),
          if (showAvatar) ...[
            const SizedBox(width: Sp.s3h),
            const _BarAvatar(),
          ],
        ],
      ),
    );
  }
}

/// `Warung Sebelah › Meja 5 › Teras` — the trail, coarsest first, current
/// segment brightest.
///
/// Ellipsizes as one line rather than wrapping: the bar is a fixed 64h and a
/// second crumb line would push the rule off the slab.
class _Crumbs extends StatelessWidget {
  final List<String> items;
  const _Crumbs(this.items);

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    if (items.isEmpty) return const SizedBox.shrink();

    final hi = SatShape.brutal && SatShape.brutalPaper
        ? SatShape.ink
        : sc.textHi;

    final spans = <InlineSpan>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        spans.add(
          TextSpan(
            text: '  ›  ',
            style: SatType.monoS(color: sc.textLo),
          ),
        );
      }
      final last = i == items.length - 1;
      spans.add(
        TextSpan(
          text: items[i],
          style: last
              ? SatType.monoM(color: hi)
              : SatType.monoS(color: sc.textMd),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }
}

/// Live LAN link state. [bare] is the phone form: no pill enclosure, and no
/// label at all while the link is healthy.
///
/// The dot alone carries `open`. "LIVE · LAN" costs ~72dp to narrate the case
/// nobody acts on, and the phone bar needs that width for the shift cluster at
/// 360dp. `connecting` and `offline` keep their words — those are the states
/// that change what a waiter does next, and the design's promise is to degrade
/// loudly. The tablet is wide enough to say all three out loud.
class _SyncStatus extends ConsumerWidget {
  final bool bare;
  const _SyncStatus({this.bare = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final state = ref.watch(wsConnStateProvider);
    final isAdmin = ref.watch(authStateProvider).user?.role == UserRole.admin;
    final (dotColor, softColor, label) = switch (state) {
      WsConnState.open => (
        sc.success,
        sc.successSoft,
        isAdmin ? 'LIVE · LAN' : 'LIVE',
      ),
      WsConnState.connecting => (sc.warn, sc.warnSoft, 'MENGHUBUNGKAN…'),
      _ => (sc.urgent, sc.urgentSoft, 'OFFLINE'),
    };
    final fg = bare
        ? sc.textMd
        : (SatShape.brutal && SatShape.brutalPaper ? SatShape.ink : sc.textHi);

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: SatBox.d(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: softColor, blurRadius: 0, spreadRadius: 3),
            ],
          ),
        ),
        if (!bare || state != WsConnState.open) ...[
          const SizedBox(width: Sp.s2),
          Text(label, style: SatType.caption(color: fg)),
        ],
      ],
    );

    if (bare) return row;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: Sp.s2h),
      decoration: SatBox.d(
        color: SatShape.brutal
            ? (SatShape.brutalPaper ? sc.bg1 : sc.bg2)
            : sc.bg2,
        border: SatB.all(color: SatShape.brutal ? SatShape.ink : sc.border1),
        borderRadius: SatR.a(999),
      ),
      child: row,
    );
  }
}

/// `SHIFT 6j 42m 7d · 18:14 · Sab` — the time block, both layouts.
///
/// Bare label/value pairs rather than bordered badges: the row already carries
/// a sync indicator (and a crumb trail, on tablet), and enclosing every value
/// turns the bar into a strip of boxes instead of one status line.
///
/// No seconds on the wall clock. The elapsed counter beside it already proves
/// the clock is live, and a digit ticking in permanent chrome that nobody acts
/// on is motion for its own sake — the weekday earns that width instead.
class _ShiftCluster extends ConsumerWidget {
  const _ShiftCluster();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A readout: the shift counter carries seconds and nothing branches on it.
    // This cluster is already the smallest widget that renders them, so the
    // seconds ticker stops here rather than reaching the bar (ADR-0081).
    ref.watch(secondTickerProvider);
    final now = SatClock.now();
    final sc = context.sat;
    final hi = SatShape.brutal && SatShape.brutalPaper
        ? SatShape.ink
        : sc.textHi;

    final startedRaw = ref.watch(
      authStateProvider.select((s) => s.user?.shiftStartedAt),
    );
    // No shift is a state, not a zero. The counter disappears rather than
    // resting at zero, because a clock reading zero beside the word SHIFT is a
    // shift that just started, and this is a shift that has ended — the
    // rollover retired it, or the host never opened one (ADR-0096). An
    // unparseable stamp is a different thing and still shows zero: it means a
    // shift we cannot read, not the absence of one. That zero goes through
    // [formatElapsed] too, so it reads in the counter's own vocabulary ("0d")
    // rather than in a clock shape this pill never otherwise speaks.
    final started = startedRaw == null ? null : DateTime.tryParse(startedRaw);
    final elapsed = formatElapsed(
      context.l10n,
      started == null ? Duration.zero : now.difference(started),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (startedRaw != null) ...[
          Text(
            context.l10n.shiftLabel,
            style: SatType.caption(color: sc.textLo),
          ),
          const SizedBox(width: Sp.s1h),
          Text(elapsed, style: SatType.monoM(color: hi)),
          const SizedBox(width: Sp.s3h),
        ],
        Text(formatBarClockId(now), style: SatType.monoM(color: sc.textMd)),
      ],
    );
  }
}

/// The signed-in user, top right. Taps through to their own shift summary —
/// the only route out of the bar that isn't a crumb.
class _BarAvatar extends ConsumerWidget {
  const _BarAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    if (user == null) return const SizedBox.shrink();

    return Semantics(
      button: true,
      label: context.l10n.tabSaya,
      child: GestureDetector(
        onTap: () => context.go('/me'),
        child: StaffAvatar(actor: user, size: 32, mine: true),
      ),
    );
  }
}

/// Compact pill shown as a trailing slot in [SatAppBar]. Used for things like
/// "T+0:45" on the table detail screen.
class SatAppBarPill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? tint;
  const SatAppBarPill({super.key, this.icon, required this.label, this.tint});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final fg = tint ?? sc.textMd;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: Sp.s2h),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border1),
        borderRadius: SatR.a(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: Sp.s1h),
          ],
          Text(label, style: SatType.monoS(color: fg)),
        ],
      ),
    );
  }
}
