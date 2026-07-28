import 'dart:async';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';

void safePop(BuildContext context, {String fallback = '/tables'}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(fallback);
  }
}

class LoginClock extends ConsumerStatefulWidget {
  final Color? textColor;
  const LoginClock({super.key, this.textColor});

  @override
  ConsumerState<LoginClock> createState() => _LoginClockState();
}

class _LoginClockState extends ConsumerState<LoginClock> {
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

  String _two(int v) => v.toString().padLeft(2, '0');

  String _clock(DateTime d) =>
      '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final fg =
        widget.textColor ??
        (SatShape.brutal && SatShape.brutalPaper ? SatShape.ink : sc.textHi);
    final startedRaw = ref.watch(
      authStateProvider.select((s) => s.user?.shiftStartedAt),
    );
    final started = startedRaw == null ? null : DateTime.tryParse(startedRaw);
    final currentTime = _clock(_now);
    final elapsed = started == null
        ? '00:00:00'
        : formatElapsedId(_now.difference(started));

    final badgeBg = SatShape.brutal
        ? (SatShape.brutalPaper ? sc.bg1 : sc.bg2)
        : sc.bg2;
    final badgeBorder = SatB.all(
      color: SatShape.brutal ? SatShape.ink : sc.border1,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current Time Badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s2h,
            vertical: Sp.s1h,
          ),
          decoration: SatBox.d(
            color: badgeBg,
            border: badgeBorder,
            borderRadius: SatR.a(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time_filled_rounded, size: 13, color: fg),
              const SizedBox(width: Sp.s1h),
              Text(currentTime, style: SatType.monoM(color: fg)),
            ],
          ),
        ),
        const SizedBox(width: Sp.s2),
        // Elapsed Time Badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s2h,
            vertical: Sp.s1h,
          ),
          decoration: SatBox.d(
            color: badgeBg,
            border: badgeBorder,
            borderRadius: SatR.a(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 13, color: fg),
              const SizedBox(width: Sp.s1h),
              Text(elapsed, style: SatType.monoM(color: fg)),
            ],
          ),
        ),
      ],
    );
  }
}

class SatBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  /// Overrides the screen-reader name. Defaults to "Kembali"; pass something
  /// specific when the glyph is not a back arrow.
  final String? semanticLabel;
  const SatBackButton({
    super.key,
    required this.onTap,
    this.icon = Icons.arrow_back,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final fg = SatShape.brutal && SatShape.brutalPaper
        ? SatShape.ink
        : sc.textHi;
    return Semantics(
      button: true,
      label: semanticLabel ?? AppStrings.back,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: SatBox.d(
            color: SatShape.brutal
                ? (SatShape.brutalPaper ? sc.bg1 : sc.bg2)
                : sc.bg2,
            borderRadius: SatR.a(12),
            border: SatB.all(
              color: SatShape.brutal ? SatShape.ink : sc.border0,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: fg),
        ),
      ),
    );
  }
}
