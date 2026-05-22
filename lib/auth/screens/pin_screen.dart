import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/colors.dart';
import '../../design/layout.dart';
import '../../design/typography.dart';
import '../../models/dummy_data.dart';
import '../auth_state.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  static const _max = 4;

  void _press(String d) {
    if (d == 'del') {
      setState(() => _pin = _pin.isEmpty ? _pin : _pin.substring(0, _pin.length - 1));
      return;
    }
    if (_pin.length >= _max) return;
    setState(() => _pin = _pin + d);
    if (_pin.length == _max) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        ref.read(authStateProvider.notifier).signIn();
        context.go('/tables');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    final user = DummyData.maya;

    if (l.useTabletShell) {
      return Scaffold(
        backgroundColor: sc.bg0,
        body: Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: sc.bg1,
                padding: const EdgeInsets.fromLTRB(56, 56, 56, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TabletBrand(),
                    const SizedBox(height: 80),
                    Text('Selamat sore',
                        style: SatType.mono(
                          size: 13,
                          color: sc.textMd,
                          letterSpacing: 1.3,
                        )),
                    const SizedBox(height: 6),
                    Text('${user.name},\nmasukkan PIN',
                        style: SatType.sans(
                          size: 54,
                          weight: FontWeight.w600,
                          letterSpacing: -1.35,
                          height: 1.05,
                          color: sc.textHi,
                        )),
                    const SizedBox(height: 12),
                    Text('Pelayan · Zona Teras · mulai 17:30',
                        style: SatType.sans(size: 16, color: sc.textMd)),
                    const Spacer(),
                    Text('WARUNG SEBELAH\nBERAWA, BALI\n\nPIN BERAKHIR DI AKHIR SHIFT · BYOD · v2.0',
                        style: SatType.mono(
                          size: 11,
                          color: sc.textLo,
                          letterSpacing: 0.66,
                          height: 1.6,
                        )),
                  ],
                ),
              ),
            ),
            Container(
              width: 480,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: sc.border0)),
              ),
              padding: const EdgeInsets.fromLTRB(48, 56, 48, 32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _max,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < _pin.length ? sc.accent : sc.bg3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    _Pad(onPress: _press, tablet: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final brand = _Brand();
    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selamat sore',
            style: SatType.mono(
              size: 13,
              color: sc.textMd,
              letterSpacing: 1.04,
            )),
        const SizedBox(height: 4),
        Text('${user.name},\nPIN shift',
            style: SatType.sans(
              size: l.isCompact ? 38 : 44,
              weight: FontWeight.w600,
              letterSpacing: -0.76,
              height: 1.05,
              color: sc.textHi,
            )),
        const SizedBox(height: 6),
        Text('Pelayan · Zona Teras · mulai 17:30',
            style: SatType.sans(size: 14, color: sc.textMd)),
      ],
    );
    final dots = Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _max,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length ? sc.accent : sc.bg3,
              ),
            ),
          ),
        ),
      ),
    );
    final pad = _Pad(onPress: _press, tablet: false);
    final footer = Center(
      child: Text(
        'PIN BERAKHIR DI AKHIR SHIFT · BYOD',
        style: SatType.mono(size: 12, color: sc.textLo, letterSpacing: 0.5),
      ),
    );

    final twoCol = l.isLandscape && l.size.width >= 720;

    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: twoCol ? 980 : 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
              child: twoCol
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              brand,
                              const SizedBox(height: 52),
                              greeting,
                              const SizedBox(height: 36),
                              dots,
                              const SizedBox(height: 24),
                              footer,
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                        Expanded(child: pad),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        brand,
                        const SizedBox(height: 52),
                        greeting,
                        const SizedBox(height: 36),
                        dots,
                        const SizedBox(height: 32),
                        pad,
                        const SizedBox(height: 18),
                        footer,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: sc.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            'S',
            style: SatType.mono(
              size: 16,
              weight: FontWeight.w700,
              letterSpacing: -0.64,
              color: sc.accentInk,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('satset',
            style: SatType.sans(
              size: 18,
              weight: FontWeight.w600,
              letterSpacing: -0.18,
              color: sc.textHi,
            )),
        const Spacer(),
        Text(
          'WARUNG SEBELAH\nBERAWA, BALI',
          textAlign: TextAlign.right,
          style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.8, height: 1.4),
        ),
      ],
    );
  }
}

class _TabletBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: sc.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            'S',
            style: SatType.mono(
              size: 22,
              weight: FontWeight.w700,
              letterSpacing: -0.88,
              color: sc.accentInk,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('satset',
            style: SatType.sans(
              size: 22,
              weight: FontWeight.w600,
              letterSpacing: -0.22,
              color: sc.textHi,
            )),
      ],
    );
  }
}

class _Pad extends StatelessWidget {
  final void Function(String) onPress;
  final bool tablet;
  const _Pad({required this.onPress, required this.tablet});

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: tablet ? 12 : 10,
      crossAxisSpacing: tablet ? 12 : 10,
      childAspectRatio: tablet ? 1.6 : 1.4,
      children: [
        for (final k in keys)
          if (k == '')
            const SizedBox.shrink()
          else
            _PinKey(label: k, tablet: tablet, onTap: () => onPress(k)),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final bool tablet;
  final VoidCallback onTap;
  const _PinKey({required this.label, required this.tablet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final muted = label == 'del';
    return Material(
      color: muted ? Colors.transparent : sc.bg2,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          alignment: Alignment.center,
          child: muted
              ? Icon(Icons.backspace_outlined, color: sc.textMd, size: tablet ? 26 : 22)
              : Text(label,
                  style: SatType.mono(
                    size: tablet ? 32 : 26,
                    weight: FontWeight.w500,
                    letterSpacing: 0,
                    color: sc.textHi,
                  )),
        ),
      ),
    );
  }
}
