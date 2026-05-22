import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design/colors.dart';
import '../design/layout.dart';
import '../design/typography.dart';
import '../models/zone.dart';

void safePop(BuildContext context, {String fallback = '/tables'}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(fallback);
  }
}

enum SyncMode { live, offline }

class SatsetTopBar extends StatelessWidget {
  final Zone? zone;
  final VoidCallback? onSwitchZone;
  final SyncMode sync;
  final String? overrideSyncLabel;
  final Widget? leading;
  final String avatarInitials;

  const SatsetTopBar({
    super.key,
    this.zone,
    this.onSwitchZone,
    this.sync = SyncMode.live,
    this.overrideSyncLabel,
    this.leading,
    this.avatarInitials = 'MA',
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final isOffline = sync == SyncMode.offline;
    final dotColor = isOffline ? sc.warn : sc.success;
    final softColor = isOffline ? sc.warnSoft : sc.successSoft;
    final label = overrideSyncLabel ?? (isOffline ? 'LAN ONLY · CLOUD PAUSED' : 'LIVE · LAN');
    final l = context.layout;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, l.topInset, 16, 10),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (zone != null)
            _ZoneSwitchPill(zone: zone!, onTap: onSwitchZone)
          else
            const SizedBox.shrink(),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  boxShadow: [BoxShadow(color: softColor, spreadRadius: 3)],
                ),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: SatType.mono(
                    size: 10,
                    weight: FontWeight.w500,
                    letterSpacing: 0.6,
                    color: sc.textMd,
                  )),
            ],
          ),
          const Spacer(),
          _Avatar(initials: avatarInitials),
        ],
      ),
    );
  }
}

class _ZoneSwitchPill extends StatelessWidget {
  final Zone zone;
  final VoidCallback? onTap;
  const _ZoneSwitchPill({required this.zone, this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 7, 12, 7),
        decoration: BoxDecoration(
          color: sc.bg2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: sc.border1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place_outlined, size: 14, color: sc.textHi),
            const SizedBox(width: 6),
            Text(zone.name,
                style: SatType.sans(size: 14, weight: FontWeight.w500, color: sc.textHi)),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 14, color: sc.textMd.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({this.initials = 'MA'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9233), Color(0xFFD96030)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: SatType.sans(
          size: 12,
          weight: FontWeight.w600,
          letterSpacing: 0.24,
          color: Colors.white,
        ),
      ),
    );
  }
}

class SatBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  const SatBackButton({super.key, required this.onTap, this.icon = Icons.arrow_back});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: sc.bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sc.border0),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: sc.textMd),
      ),
    );
  }
}
