import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/colors.dart';
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
    final user = DummyData.maya;

    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _Brand(),
              const SizedBox(height: 52),
              Text('Selamat sore',
                  style: SatType.mono(
                    size: 13,
                    color: sc.textMd,
                    letterSpacing: 1.04,
                  )),
              const SizedBox(height: 4),
              Text('${user.name},\nPIN shift',
                  style: SatType.sans(
                    size: 38,
                    weight: FontWeight.w600,
                    letterSpacing: -0.76,
                    height: 1.05,
                    color: sc.textHi,
                  )),
              const SizedBox(height: 6),
              Text('Floor Server · Zona Teras · mulai 17:30',
                  style: SatType.sans(size: 14, color: sc.textMd)),
              const SizedBox(height: 36),
              Center(
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
              ),
              const SizedBox(height: 32),
              _Pad(onPress: _press),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'PIN BERAKHIR DI AKHIR SHIFT · BYOD',
                  style: SatType.mono(size: 12, color: sc.textLo, letterSpacing: 0.5),
                ),
              ),
            ],
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

class _Pad extends StatelessWidget {
  final void Function(String) onPress;
  const _Pad({required this.onPress});

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [
        for (final k in keys)
          if (k == '')
            const SizedBox.shrink()
          else
            _PinKey(label: k, onTap: () => onPress(k)),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PinKey({required this.label, required this.onTap});

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
              ? Icon(Icons.backspace_outlined, color: sc.textMd, size: 22)
              : Text(label,
                  style: SatType.mono(
                    size: 26,
                    weight: FontWeight.w500,
                    letterSpacing: 0,
                    color: sc.textHi,
                  )),
        ),
      ),
    );
  }
}
