import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/staff_avatar.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart'
    show LoginClock, SatBackButton;

/// Single responsive app bar used everywhere chrome is needed.
///
/// Tablet: 64h slab, crumb trail on the left, a status cluster on the right —
/// sync, shift elapsed, wall clock. No avatar; the side rail owns that.
/// Phone: three slots — back + clock, then the status cluster and the current
/// user's avatar. Crumbs are dropped here: at 402px the trail truncates to its
/// last segment anyway, and the parent is one back-tap away.
class SatAppBar extends ConsumerWidget {
  final VoidCallback? onBack;

  /// Path to the current screen, coarsest first: `['Meja', 'T5', 'Teras']`.
  /// Tablet only.
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
    return l.useTabletShell ? _tablet(context) : _phone(context);
  }

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
      padding: EdgeInsets.fromLTRB(Sp.s4, l.topInset + Sp.s1h, Sp.s4, Sp.s2h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onBack != null) ...[
                SatBackButton(onTap: onBack!),
                const SizedBox(width: Sp.s2h),
              ],
              const LoginClock(),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final pill in trailingPills) ...[
                pill,
                const SizedBox(width: Sp.s2),
              ],
              // Bare dot + label rather than the tablet's pill: the phone row
              // already carries two bordered clock badges, and a third
              // enclosure turns the bar into a strip of boxes.
              const _SyncStatus(bare: true),
              if (showAvatar) ...[
                const SizedBox(width: Sp.s3),
                const _BarAvatar(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _tablet(BuildContext context) {
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
          Expanded(child: _Crumbs(crumbs)),
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

/// `Meja › T5 › Teras` — the trail, coarsest first, current segment brightest.
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
          TextSpan(text: '  ›  ', style: SatType.monoS(color: sc.textLo)),
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

/// Live LAN link state. [bare] drops the pill enclosure down to a dot and a
/// label — the phone form.
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
        : (SatShape.brutal && SatShape.brutalPaper
              ? SatShape.ink
              : sc.textHi);

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
        const SizedBox(width: Sp.s2),
        Text(label, style: SatType.caption(color: fg)),
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

/// `SHIFT 6:42:07 · 18:14 Sab` — the tablet's time block.
///
/// Bare label/value pairs rather than the phone's bordered badges: the tablet
/// bar already carries a crumb trail and a sync pill, and the design drops the
/// enclosures here so the row reads as one status line instead of four chips.
class _ShiftCluster extends ConsumerStatefulWidget {
  const _ShiftCluster();

  @override
  ConsumerState<_ShiftCluster> createState() => _ShiftClusterState();
}

class _ShiftClusterState extends ConsumerState<_ShiftCluster> {
  Timer? _timer;
  DateTime _now = SatClock.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = SatClock.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final hi = SatShape.brutal && SatShape.brutalPaper
        ? SatShape.ink
        : sc.textHi;

    final startedRaw = ref.watch(
      authStateProvider.select((s) => s.user?.shiftStartedAt),
    );
    final started = startedRaw == null ? null : DateTime.tryParse(startedRaw);
    final elapsed = started == null
        ? '00:00:00'
        : formatElapsedId(_now.difference(started));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AppStrings.shiftLabel, style: SatType.caption(color: sc.textLo)),
        const SizedBox(width: Sp.s1h),
        Text(elapsed, style: SatType.monoM(color: hi)),
        const SizedBox(width: Sp.s3h),
        Text(formatBarClockId(_now), style: SatType.monoM(color: sc.textMd)),
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
      label: AppStrings.tabSaya,
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
