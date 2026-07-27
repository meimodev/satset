import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart'
    show LoginClock, SatBackButton;

/// Single responsive app bar used everywhere chrome is needed.
///
/// Phone: padded row with clock, optional back, title, trailing pills,
/// network pill, avatar.
/// Tablet: 64h container with border-bottom; avatar omitted when [showAvatar]
/// is false (side rail provides one).
class SatAppBar extends ConsumerWidget {
  final VoidCallback? onBack;
  final String? title;
  final List<String> crumbs;
  final List<Widget> trailingPills;
  final bool showAvatar;
  final Color? backgroundColor;

  const SatAppBar({
    super.key,
    this.onBack,
    this.title,
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
    if (SatShape.brutal) {
      return SatShape.brutalPaper ? sc.accent : sc.bg1;
    }
    return sc.bg0;
  }

  Widget _phone(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    final bg = _resolveBg(sc);

    return Container(
      decoration: SatBox.d(
        color: bg,
        border: Border(
          bottom: SatB.side(
            color: SatShape.brutal ? SatShape.ink : sc.border0,
            width: SatShape.brutal ? SatShape.brutalBorder : 1,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, l.topInset + 6, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onBack != null) ...[
                SatBackButton(onTap: onBack!),
                const SizedBox(width: 10),
              ],
              const LoginClock(),
            ],
          ),
          const _NetworkPill(),
        ],
      ),
    );
  }

  Widget _tablet(BuildContext context) {
    final sc = context.sat;
    final bg = _resolveBg(sc);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: SatBox.d(
        color: bg,
        border: Border(
          bottom: SatB.side(
            color: SatShape.brutal ? SatShape.ink : sc.border0,
            width: SatShape.brutal ? SatShape.brutalBorder : 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onBack != null) ...[
                SatBackButton(onTap: onBack!),
                const SizedBox(width: 10),
              ],
              const LoginClock(),
            ],
          ),
          const _NetworkPill(),
        ],
      ),
    );
  }
}

class _NetworkPill extends ConsumerWidget {
  const _NetworkPill();

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
    final fg = SatShape.brutal && SatShape.brutalPaper ? SatShape.ink : sc.textHi;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: SatBox.d(
        color: SatShape.brutal ? (SatShape.brutalPaper ? sc.bg1 : sc.bg2) : sc.bg2,
        border: SatB.all(color: SatShape.brutal ? SatShape.ink : sc.border1),
        borderRadius: SatR.a(999),
      ),
      child: Row(
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
          const SizedBox(width: 8),
          Text(
            label,
            style: SatType.mono(
              size: 11,
              weight: FontWeight.w700,
              letterSpacing: 0.6,
              color: fg,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: SatType.mono(
              size: 10,
              weight: FontWeight.w500,
              letterSpacing: 0.6,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
