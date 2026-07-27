import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// Sweeps a soft highlight across its child while content loads. Collapses to a
/// static block under reduced-motion.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final sc = context.sat;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Colors.transparent,
            sc.bg4.withValues(alpha: 0.55),
            Colors.transparent,
          ],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlideGradient(_c.value * 3 - 1.5),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double slide;
  const _SlideGradient(this.slide);
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}

/// Solid rounded block tinted to the surface used inside skeletons.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      width: width,
      height: height,
      decoration: SatBox.d(color: sc.bg3, borderRadius: SatR.a(radius)),
    );
  }
}

/// Placeholder card — flat block while the section paints. Now shimmered.
class SkeletonCard extends StatelessWidget {
  final double height;
  final EdgeInsets? margin;
  const SkeletonCard({super.key, this.height = 120, this.margin});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      height: height,
      margin: margin,
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(16),
      ),
      child: Shimmer(
        child: Padding(
          padding: const EdgeInsets.all(Sp.s4h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 140, height: 14),
              SizedBox(height: Sp.s2),
              SkeletonBox(width: 90, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Layout-shaped loading state for the reports screen: a KPI tile row plus two
/// chart cards, so the skeleton echoes what is about to appear.
class ReportsSkeleton extends StatelessWidget {
  const ReportsSkeleton({super.key});

  Widget _card(BuildContext context, {required Widget child}) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.all(Sp.s4h),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(16),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    Widget tile() => Expanded(
      child: Container(
        padding: const EdgeInsets.all(Sp.s4),
        decoration: SatBox.d(
          color: sc.bg2,
          border: SatB.all(color: sc.border0),
          borderRadius: SatR.a(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 44, height: 9),
            SizedBox(height: Sp.s3),
            SkeletonBox(width: 70, height: 20),
            SizedBox(height: Sp.s2),
            SkeletonBox(width: 54, height: 9),
          ],
        ),
      ),
    );

    Widget chart() => _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 160, height: 14),
          const SizedBox(height: Sp.s2),
          const SkeletonBox(width: 100, height: 10),
          const SizedBox(height: Sp.s4h),
          SizedBox(
            height: Sp.s12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 9; i++) ...[
                  Expanded(
                    child: SkeletonBox(height: 30.0 + (i % 4) * 22, radius: 3),
                  ),
                  if (i != 8) const SizedBox(width: Sp.s1h),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              tile(),
              const SizedBox(width: Sp.s3),
              tile(),
              const SizedBox(width: Sp.s3),
              tile(),
              const SizedBox(width: Sp.s3),
              tile(),
            ],
          ),
          const SizedBox(height: Sp.s3h),
          chart(),
          const SizedBox(height: Sp.s3h),
          chart(),
        ],
      ),
    );
  }
}
