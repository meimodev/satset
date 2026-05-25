import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';

void safePop(BuildContext context, {String fallback = '/tables'}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(fallback);
  }
}

class SatsetTopBar extends ConsumerWidget {
  final Widget? leading;

  const SatsetTopBar({super.key, this.leading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final state = ref.watch(wsConnStateProvider).value;
    final (dotColor, softColor, label) = switch (state) {
      WsConnState.open => (sc.success, sc.successSoft, 'LIVE · LAN'),
      WsConnState.connecting => (sc.warn, sc.warnSoft, 'MENGHUBUNGKAN…'),
      WsConnState.closed => (sc.urgent, sc.urgentSoft, 'OFFLINE'),
    };
    final l = context.layout;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, l.topInset, 16, 10),
      child: Row(
        children: [
          const LoginClock(),
          if (leading != null) ...[
            const SizedBox(width: 10),
            leading!,
          ],
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
          const _Avatar(),
        ],
      ),
    );
  }
}

class _Avatar extends ConsumerWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final initials = (user?.initials.isNotEmpty ?? false) ? user!.initials : '—';
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
          width: 32,
          height: 32,
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
              size: 12,
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

class LoginClock extends ConsumerStatefulWidget {
  const LoginClock({super.key});

  @override
  ConsumerState<LoginClock> createState() => _LoginClockState();
}

class _LoginClockState extends ConsumerState<LoginClock> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String _clock(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

  String _elapsed(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h == 0) return '${m}m ${_two(s)}s';
    return '${h}j ${_two(m)}m ${_two(s)}s';
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final startedRaw = ref.watch(authStateProvider.select((s) => s.user?.shiftStartedAt));
    final started = startedRaw == null ? null : DateTime.tryParse(startedRaw);
    final label = started == null
        ? _clock(_now)
        : '${_clock(_now)} · ${_elapsed(_now.difference(started))}';
    return Text(
      label,
      style: SatType.mono(
        size: 11,
        weight: FontWeight.w500,
        letterSpacing: 0.44,
        color: sc.textMd,
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
