import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/staff_repository.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/elapsed_pill.dart';
import 'package:satset/ui/core/widgets/note_line.dart';
import 'package:satset/ui/core/widgets/staff_avatar.dart';
import 'package:satset/ui/core/widgets/tag_badge_row.dart';
import 'package:satset/ui/core/widgets/status_chip.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/motion.dart';

/// The canonical order-line card — one sent [Ticket] rendered with its full
/// context: qty, name/variant, allergen/diet badges, modifiers, item note,
/// void reason, a live status chip, the order-elapsed pill, the line's orderer
/// avatar, the line price, and (on a ready line) a "Tandai disajikan" action.
///
/// Shared by the table detail and the Bawa pulang (takeaway) detail so the two
/// never drift. The widget is table-agnostic — it knows nothing of tables or
/// locks; the host supplies [onTap] (open the line action sheet) and
/// [onMarkServed], and gates editing via [readOnly]. See ADR-0026.
class OrderLineCard extends ConsumerStatefulWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  final void Function(String) onMarkServed;
  final bool readOnly;
  const OrderLineCard({
    super.key,
    required this.ticket,
    required this.onTap,
    required this.onMarkServed,
    this.readOnly = false,
  });

  @override
  ConsumerState<OrderLineCard> createState() => _OrderLineCardState();
}

bool _animationsDisabled(BuildContext c) =>
    MediaQuery.maybeOf(c)?.disableAnimations ?? false;

class _OrderLineCardState extends ConsumerState<OrderLineCard>
    with SingleTickerProviderStateMixin {
  // Soft breathing glow on ready items — the one signal a waiter scans for.
  late final AnimationController _glow;

  bool get _isReady => widget.ticket.status == TicketStatus.ready;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (_isReady) _glow.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant OrderLineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isReady && !_glow.isAnimating) {
      _glow.repeat(reverse: true);
    } else if (!_isReady && _glow.isAnimating) {
      _glow.stop();
      _glow.value = 0;
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final readOnly = widget.readOnly;
    final onTap = widget.onTap;
    final onMarkServed = widget.onMarkServed;
    final sc = context.sat;
    // The line's own orderer (createdBy), so everyone sees who sent each item.
    final AppUser? orderer = ticket.createdBy == null
        ? null
        : ref
              .watch(staffRepositoryProvider)
              .where((u) => u.id == ticket.createdBy)
              .firstOrNull;
    final reduced = _animationsDisabled(context);
    final isReady = ticket.status == TicketStatus.ready;
    final isCooked = ticket.status == TicketStatus.cooked;
    final isVoided = ticket.status == TicketStatus.voided;
    final bg = isReady
        ? sc.successSoft
        : (isCooked ? sc.accentSoft : (isVoided ? sc.bg1 : sc.bg2));
    final border = isReady
        ? sc.success.withValues(alpha: 0.3)
        : (isCooked ? sc.accent.withValues(alpha: 0.3) : sc.border0);

    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s1h),
      child: AnimatedOpacity(
        opacity: isVoided ? 0.5 : 1,
        duration: reduced
            ? Duration.zero
            : const Duration(milliseconds: satStatusXfadeMs),
        curve: satEaseOut,
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, child) {
            final glowT = (isReady && !reduced) ? _glow.value : 0.0;
            return AnimatedContainer(
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: satStatusXfadeMs),
              curve: satEaseOut,
              decoration: SatBox.d(
                color: bg,
                borderRadius: SatR.a(14),
                border: SatB.all(color: border),
                boxShadow: glowT > 0
                    ? [
                        BoxShadow(
                          color: sc.success.withValues(
                            alpha: 0.10 + 0.14 * glowT,
                          ),
                          blurRadius: 8 + 8 * glowT,
                          spreadRadius: 0.5 * glowT,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            borderRadius: SatR.a(14),
            child: InkWell(
              onTap: readOnly ? null : onTap,
              borderRadius: SatR.a(14),
              child: Container(
                padding: const EdgeInsets.all(Sp.s3h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: Sp.s6,
                      child: Text(
                        '×${ticket.qty}',
                        style: SatType.monoM(color: sc.textMd),
                      ),
                    ),
                    const SizedBox(width: Sp.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.name +
                                (ticket.variantName.isEmpty
                                    ? ''
                                    : ' · ${ticket.variantName}'),
                            style:
                                SatType.bodyM(
                                  color: isVoided ? sc.textLo : sc.textHi,
                                ).copyWith(
                                  decoration: isVoided
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                          if (!isVoided) MenuTagBadges(itemId: ticket.itemId),
                          if (ticket.modifiers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: Sp.s1),
                              child: Text(
                                ticket.modifiers
                                    .map((m) => m.display)
                                    .join(' · '),
                                style: SatType.bodyS(color: sc.textMd),
                              ),
                            ),
                          if (ticket.note != null &&
                              ticket.note!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: Sp.s1),
                              child: NoteLine(
                                label: 'Instruksi khusus',
                                text: ticket.note!,
                              ),
                            ),
                          if (ticket.voidReason != null)
                            Padding(
                              padding: const EdgeInsets.only(top: Sp.s1),
                              child: Text(
                                'Dibatalkan · ${ticket.voidReason} · disetujui oleh ${ticket.voidApprovedBy ?? ''}',
                                style: SatType.bodyS(color: sc.urgent),
                              ),
                            ),
                          const SizedBox(height: Sp.s2),
                          Row(
                            children: [
                              StatusChip(status: ticket.status),
                              const SizedBox(width: Sp.s2),
                              ElapsedPill(
                                clockStart: ticket.kitchenClockStart,
                                sentAtClock: ticket.sentAt,
                                terminal:
                                    isVoided ||
                                    ticket.status == TicketStatus.served,
                                targetMins: lineTargetMins(ref, ticket.itemId),
                              ),
                              if (orderer != null) ...[
                                const SizedBox(width: Sp.s2),
                                StaffAvatar(actor: orderer, size: 18),
                              ],
                              const Spacer(),
                              Text(
                                formatIDR(ticket.price * ticket.qty),
                                style: SatType.monoM(color: sc.textMd),
                              ),
                            ],
                          ),
                          if (isReady && !readOnly)
                            Reveal(
                              child: Padding(
                                padding: const EdgeInsets.only(top: Sp.s2),
                                child: _SmallSuccessButton(
                                  label: 'Tandai disajikan',
                                  icon: Icons.check,
                                  onTap: () => onMarkServed(ticket.id),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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

class _SmallSuccessButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SmallSuccessButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: sc.successSoft,
          foregroundColor: sc.success,
          side: SatB.side(color: sc.success.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: Sp.s2),
          shape: RoundedRectangleBorder(borderRadius: SatR.a(10)),
        ),
        icon: Icon(icon, size: 14, color: sc.success),
        label: Text(
          label.toUpperCase(),
          style: SatType.labelS(color: sc.success),
        ),
      ),
    );
  }
}
