import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/skin.dart';

/// Icon-only tap target (ADR-0055).
///
/// Its own widget rather than a `label`-less [SatButton] because the
/// accessibility contract is different: with no text child, Flutter derives no
/// semantics, so [tooltip] is **required** — it is both the screen-reader name
/// and the long-press hint. That requirement is why `IconButton` is a hard ban
/// in `test/design_tokens_test.dart` rather than a baseline.
class SatIconButton extends StatelessWidget {
  final IconData icon;

  /// Required. Names the control for screen readers and on long-press.
  final String tooltip;
  final VoidCallback? onTap;
  final double size;
  final _IconKind _kind;

  /// Chrome and toolbars — no fill, no border.
  const SatIconButton.plain({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 40,
  }) : _kind = _IconKind.plain;

  /// Sits on a card or a row it must stay distinct from.
  const SatIconButton.outline({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 40,
  }) : _kind = _IconKind.outline;

  /// The affirmative action reduced to its glyph — rare, but the KDS bump and
  /// the stepper's siblings need it.
  const SatIconButton.primary({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 40,
  }) : _kind = _IconKind.primary;

  /// Void, write-off, remove.
  const SatIconButton.danger({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 40,
  }) : _kind = _IconKind.danger;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final on = onTap != null;

    final (Color? fill, Color ink, Color? border) = switch (_kind) {
      _IconKind.plain => (null, on ? sc.textMd : sc.textDim, null),
      _IconKind.outline => (
        sc.bg2,
        on ? sc.textHi : sc.textDim,
        on ? sc.border1 : sc.border0,
      ),
      _IconKind.primary => (
        on ? sc.accent : sc.bg3,
        on ? sc.accentInk : sc.textDim,
        null,
      ),
      _IconKind.danger => (
        null,
        on ? sc.urgent : sc.textDim,
        on ? sc.urgent.withValues(alpha: 0.5) : sc.border0,
      ),
    };

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: on,
        label: tooltip,
        child: Material(
          color: fill ?? Colors.transparent,
          borderRadius: SatR.sm,
          child: InkWell(
            onTap: onTap,
            borderRadius: SatR.sm,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: border == null
                  ? null
                  : SatBox.d(
                      border: SatB.all(color: border),
                      borderRadius: SatR.sm,
                    ),
              child: Icon(icon, size: size * 0.45, color: ink),
            ),
          ),
        ),
      ),
    );
  }
}

enum _IconKind { plain, outline, primary, danger }
