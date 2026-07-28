import 'package:flutter/material.dart';

import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/motion.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// The ticket-status pill. One vocabulary of colour per [TicketStatus], used
/// on the line card, the orders board and the void sheet — a waiter learns
/// "amber = prep" once and it holds everywhere.
///
/// The label cross-fades and the pill morphs its fill when the status changes
/// under a live WebSocket push, so a status moving underneath your thumb is
/// visible rather than a silent swap. Snaps instantly under reduced motion.
class StatusChip extends StatelessWidget {
  final TicketStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final (bg, fg) = _tone(sc, status);
    final animate = motionEnabled(context);
    final label = ticketStatusLabel(status).toUpperCase();
    return AnimatedContainer(
      duration: animate ? _morph : Duration.zero,
      curve: satEaseOut,
      padding: const EdgeInsets.symmetric(horizontal: Sp.s2, vertical: Sp.s1),
      decoration: SatBox.d(color: bg, borderRadius: SatR.a(6)),
      child: AnimatedSwitcher(
        duration: animate ? _morph : Duration.zero,
        switchInCurve: satEaseOut,
        switchOutCurve: satEaseOut,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        child: Text(
          label,
          key: ValueKey(label),
          style: SatType.caption(color: fg),
        ),
      ),
    );
  }
}

const Duration _morph = Duration(milliseconds: 220);

/// (fill, ink) for a status. Kept separate from `build` so a caller that needs
/// the same hue on a non-chip surface can reach it without rebuilding the map.
(Color, Color) _tone(SatColors sc, TicketStatus status) => switch (status) {
  TicketStatus.draft ||
  TicketStatus.acknowledged ||
  TicketStatus.sent => (sc.infoSoft, sc.info),
  TicketStatus.prep => (sc.warnSoft, sc.warn),
  TicketStatus.cooked => (sc.accentSoft, sc.accentText),
  TicketStatus.ready => (sc.successSoft, sc.success),
  TicketStatus.served => (sc.bg3, sc.textLo),
  TicketStatus.pendingReview || TicketStatus.held => (sc.violetSoft, sc.violet),
  TicketStatus.voided => (sc.urgentSoft, sc.urgent),
};
