import 'dart:math' as math;
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';

const int kPinLength = 6;

const _kMicroDur = Duration(milliseconds: 200);
const _kPressDur = Duration(milliseconds: 110);
const _kShakeDur = Duration(milliseconds: 360);

Duration _d(BuildContext c, Duration d) =>
    MediaQuery.disableAnimationsOf(c) ? Duration.zero : d;

/// Callback fired when the user has typed `kPinLength` digits.
/// Return `null` on success — sheet closes with `true`.
/// Return an error string — sheet shakes, clears digits, shows the message.
typedef PinSubmit = Future<String?> Function(String pin);

/// Optional debug-only seeded credentials shown inside the sheet.
class PinDebugCreds {
  final List<({String pin, String name, String role})> entries;
  const PinDebugCreds(this.entries);
}

/// Show a modular PIN entry bottom sheet. Returns `true` when verification
/// succeeded (i.e. [onSubmit] returned `null`); `null` when the user dismissed.
Future<bool?> showPinSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required PinSubmit onSubmit,
  PinDebugCreds? debugCreds,
  Widget? statusSlot,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PinSheet(
      title: title,
      subtitle: subtitle,
      onSubmit: onSubmit,
      debugCreds: debugCreds,
      statusSlot: statusSlot,
    ),
  );
}

class _PinSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final PinSubmit onSubmit;
  final PinDebugCreds? debugCreds;

  /// Optional live widget rendered under the subtitle — used by staff sign-in to
  /// show the paired server's reachability heartbeat. Kept as an injected slot so
  /// this core widget stays Riverpod-agnostic.
  final Widget? statusSlot;
  const _PinSheet({
    required this.title,
    required this.subtitle,
    required this.onSubmit,
    this.debugCreds,
    this.statusSlot,
  });

  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _busy = false;
  String? _error;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: _kShakeDur);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _triggerShake() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _shake.forward(from: 0);
  }

  Future<void> _onDigit(String d) async {
    if (_busy) return;
    if (d == 'del') {
      if (_pin.isEmpty) return;
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = null;
      });
      return;
    }
    if (_pin.length >= kPinLength) return;
    setState(() {
      _pin = _pin + d;
      _error = null;
    });
    if (_pin.length == kPinLength) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      await _trySubmit();
    }
  }

  Future<void> _trySubmit() async {
    setState(() => _busy = true);
    final err = await widget.onSubmit(_pin);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = err;
      _pin = '';
    });
    _triggerShake();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final mq = MediaQuery.of(context);
    final maxW = mq.size.width >= 600 ? 480.0 : double.infinity;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: SatBox.d(
                color: sc.bg1,
                borderRadius: SatR.a(22),
                border: SatB.all(color: sc.border0),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: SatBox.d(
                          color: sc.border2,
                          borderRadius: SatR.a(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: Sp.s4),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: SatType.sans(
                        size: 20,
                        weight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: sc.textHi,
                      ),
                    ),
                    const SizedBox(height: Sp.s1),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: SatType.sans(size: 12, color: sc.textMd),
                    ),
                    if (widget.statusSlot != null) ...[
                      const SizedBox(height: Sp.s2h),
                      Center(child: widget.statusSlot!),
                    ],
                    const SizedBox(height: 22),
                    _PinDots(pin: _pin, shake: _shake),
                    const SizedBox(height: Sp.s3),
                    _PinHelper(
                      pinLength: _pin.length,
                      busy: _busy,
                      error: _error,
                    ),
                    const SizedBox(height: Sp.s4h),
                    _Pad(onPress: _onDigit, enabled: !_busy),
                    if (kDebugMode && widget.debugCreds != null) ...[
                      const SizedBox(height: Sp.s3h),
                      _DebugCredsHint(creds: widget.debugCreds!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final String pin;
  final Animation<double> shake;
  const _PinDots({required this.pin, required this.shake});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    const size = 16.0;
    const pad = 9.0;
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(kPinLength, (i) {
        final filled = i < pin.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: pad),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: filled ? 0 : 1, end: filled ? 1 : 0),
            duration: _d(context, const Duration(milliseconds: 180)),
            curve: Curves.easeOutQuart,
            builder: (context, t, _) {
              final scale = 0.7 + 0.3 * t;
              return Transform.scale(
                scale: filled ? scale : 1.0,
                child: Container(
                  width: size,
                  height: size,
                  decoration: SatBox.d(
                    shape: BoxShape.circle,
                    color: Color.lerp(sc.bg3, sc.accent, t)!,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
    return Center(
      child: AnimatedBuilder(
        animation: shake,
        builder: (context, child) {
          final t = shake.value;
          if (t == 0) return child!;
          final dx = math.sin(t * math.pi * 4) * 8 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: row,
      ),
    );
  }
}

class _PinHelper extends StatelessWidget {
  final int pinLength;
  final bool busy;
  final String? error;
  const _PinHelper({required this.pinLength, required this.busy, this.error});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    if (error != null) {
      return Center(
        child: Text(
          error!,
          style: SatType.mono(
            size: 11,
            weight: FontWeight.w600,
            color: sc.urgent,
            letterSpacing: 0.6,
          ),
        ),
      );
    }
    final empty = pinLength == 0;
    final complete = pinLength >= kPinLength;
    if (empty && !busy && !complete) {
      return const SizedBox(height: Sp.s3h);
    }
    final text = busy || complete
        ? 'Memverifikasi...'
        : '$pinLength / $kPinLength digit';
    final color = (busy || complete) ? sc.accentText : sc.textLo;
    return Center(
      child: Text(
        text,
        style: SatType.mono(size: 11, color: color, letterSpacing: 0.6),
      ),
    );
  }
}

class _Pad extends StatelessWidget {
  final void Function(String) onPress;
  final bool enabled;
  const _Pad({required this.onPress, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        for (final k in keys)
          if (k == '')
            const SizedBox.shrink()
          else
            _PinKey(label: k, onTap: enabled ? () => onPress(k) : null),
      ],
    );
  }
}

class _PinKey extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _PinKey({required this.label, required this.onTap});

  @override
  State<_PinKey> createState() => _PinKeyState();
}

class _PinKeyState extends State<_PinKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final muted = widget.label == 'del';
    final disabled = widget.onTap == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: _d(context, _kPressDur),
        curve: Curves.easeOutQuart,
        child: AnimatedContainer(
          duration: _d(context, _kMicroDur),
          curve: Curves.easeOutQuart,
          decoration: SatBox.d(
            color: muted
                ? Colors.transparent
                : (disabled
                      ? sc.bg2.withValues(alpha: 0.6)
                      : (_pressed ? sc.accentSoft : sc.bg2)),
            borderRadius: SatR.a(22),
          ),
          alignment: Alignment.center,
          child: muted
              ? Icon(
                  Icons.backspace_outlined,
                  color: disabled ? sc.textLo : sc.textMd,
                  size: 26,
                )
              : Text(
                  widget.label,
                  style: SatType.mono(
                    size: 32,
                    weight: FontWeight.w500,
                    letterSpacing: 0,
                    color: disabled ? sc.textLo : sc.textHi,
                  ),
                ),
        ),
      ),
    );
  }
}

class _DebugCredsHint extends StatelessWidget {
  final PinDebugCreds creds;
  const _DebugCredsHint({required this.creds});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: SatBox.d(
        color: sc.warnSoft,
        border: SatB.all(color: sc.warn.withValues(alpha: 0.4)),
        borderRadius: SatR.a(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report_outlined, size: 14, color: sc.warn),
              const SizedBox(width: Sp.s1h),
              Text(
                'DEBUG · SEEDED PINS',
                style: SatType.mono(
                  size: 10,
                  weight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: sc.warn,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s2),
          for (var i = 0; i < creds.entries.length; i++) ...[
            if (i > 0) const SizedBox(height: Sp.s1),
            _DebugCredRow(
              label: creds.entries[i].pin,
              value: '${creds.entries[i].name} · ${creds.entries[i].role}',
            ),
          ],
        ],
      ),
    );
  }
}

class _DebugCredRow extends StatelessWidget {
  final String label;
  final String value;
  const _DebugCredRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: label));
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Disalin: $label'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      },
      borderRadius: SatR.a(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.sHair),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: Text(
                label,
                style: SatType.mono(
                  size: 11,
                  weight: FontWeight.w700,
                  color: sc.textHi,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: SatType.sans(size: 11, color: sc.textMd),
              ),
            ),
            Icon(Icons.copy_rounded, size: 12, color: sc.textLo),
          ],
        ),
      ),
    );
  }
}
