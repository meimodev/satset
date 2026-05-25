import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/auth_repository.dart';
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

  const SatAppBar({
    super.key,
    this.onBack,
    this.title,
    this.crumbs = const [],
    this.trailingPills = const [],
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.layout;
    return l.useTabletShell ? _tablet(context) : _phone(context);
  }

  Widget _phone(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, l.topInset, 16, 10),
      child: Row(
        children: [
          if (onBack != null) ...[
            SatBackButton(onTap: onBack!),
            const SizedBox(width: 10),
          ],
          const LoginClock(),
          if (title != null) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title!,
                overflow: TextOverflow.ellipsis,
                style: SatType.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: sc.textHi,
                ),
              ),
            ),
          ],
          const Spacer(),
          for (final p in trailingPills) ...[p, const SizedBox(width: 8)],
          const _NetworkPill(),
          if (showAvatar) ...[
            const SizedBox(width: 10),
            const _AvatarBtn(size: 32),
          ],
        ],
      ),
    );
  }

  Widget _tablet(BuildContext context) {
    final sc = context.sat;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: sc.border0)),
      ),
      child: Row(
        children: [
          const LoginClock(),
          const SizedBox(width: 14),
          if (onBack != null) ...[
            SatBackButton(onTap: onBack!),
            const SizedBox(width: 10),
          ],
          if (crumbs.isNotEmpty)
            Flexible(child: _Crumbs(items: crumbs))
          else if (title != null)
            Flexible(
              child: Text(
                title!,
                overflow: TextOverflow.ellipsis,
                style: SatType.sans(
                  size: 14,
                  weight: FontWeight.w600,
                  color: sc.textHi,
                ),
              ),
            ),
          const Spacer(),
          for (final p in trailingPills) ...[p, const SizedBox(width: 8)],
          const _NetworkPill(),
          if (showAvatar) ...[
            const SizedBox(width: 10),
            const _AvatarBtn(size: 36),
          ],
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
    final state = ref.watch(wsConnStateProvider).value;
    final (dotColor, softColor, label) = switch (state) {
      WsConnState.open => (sc.success, sc.successSoft, 'LIVE · LAN'),
      WsConnState.connecting => (sc.warn, sc.warnSoft, 'MENGHUBUNGKAN…'),
      _ => (sc.urgent, sc.urgentSoft, 'OFFLINE'),
    };
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: softColor, blurRadius: 0, spreadRadius: 3)
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: SatType.mono(
              size: 10,
              weight: FontWeight.w500,
              letterSpacing: 0.6,
              color: sc.textMd,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBtn extends ConsumerWidget {
  final double size;
  const _AvatarBtn({required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final initials =
        (user?.initials.isNotEmpty ?? false) ? user!.initials : '—';
    final base = Color(user?.avatarColorHex ?? 0xFFFF9233);
    final dark = Color.alphaBlend(Colors.black.withValues(alpha: 0.32), base);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.go('/me'),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, dark],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: SatType.sans(
              size: size <= 32 ? 12 : 14,
              weight: FontWeight.w600,
              letterSpacing: 0.24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _Crumbs extends StatelessWidget {
  final List<String> items;
  const _Crumbs({required this.items});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('›', style: SatType.mono(size: 12, color: sc.textDim)),
        ));
      }
      children.add(Text(
        items[i],
        overflow: TextOverflow.ellipsis,
        style: SatType.mono(
          size: 12,
          weight: i == items.length - 1 ? FontWeight.w500 : FontWeight.w400,
          letterSpacing: 0.48,
          color: i == items.length - 1 ? sc.textHi : sc.textMd,
        ),
      ));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
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
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border1),
        borderRadius: BorderRadius.circular(999),
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
