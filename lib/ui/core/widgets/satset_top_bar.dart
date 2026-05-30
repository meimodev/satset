import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';

void safePop(BuildContext context, {String fallback = '/tables'}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(fallback);
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

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final startedRaw = ref.watch(authStateProvider.select((s) => s.user?.shiftStartedAt));
    final started = startedRaw == null ? null : DateTime.tryParse(startedRaw);
    final label = started == null
        ? _clock(_now)
        : '${_clock(_now)} · ${formatElapsedId(_now.difference(started))}';
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
