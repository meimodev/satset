import 'package:flutter/material.dart';
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

const Curve _kEase = Curves.easeOutQuart;
const Duration _kStatusXfade = Duration(milliseconds: 280);
const Duration _kChipMorph = Duration(milliseconds: 220);
const Duration _kBlockEnter = Duration(milliseconds: 360);

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
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedOpacity(
        opacity: isVoided ? 0.5 : 1,
        duration: reduced ? Duration.zero : _kStatusXfade,
        curve: _kEase,
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, child) {
            final glowT = (isReady && !reduced) ? _glow.value : 0.0;
            return AnimatedContainer(
              duration: reduced ? Duration.zero : _kStatusXfade,
              curve: _kEase,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
                boxShadow: glowT > 0
                    ? [
                        BoxShadow(
                          color: sc.success
                              .withValues(alpha: 0.10 + 0.14 * glowT),
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
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: readOnly ? null : onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text('×${ticket.qty}',
                          style: SatType.mono(
                            size: 13,
                            weight: FontWeight.w600,
                            color: sc.textMd,
                            letterSpacing: 0,
                          )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.name +
                                (ticket.variantName.isEmpty
                                    ? ''
                                    : ' · ${ticket.variantName}'),
                            style: SatType.sans(
                              size: 14,
                              weight: FontWeight.w500,
                              letterSpacing: -0.14,
                              height: 1.25,
                              color: isVoided ? sc.textLo : sc.textHi,
                            ).copyWith(
                                decoration: isVoided
                                    ? TextDecoration.lineThrough
                                    : null),
                          ),
                          if (!isVoided) MenuTagBadges(itemId: ticket.itemId),
                          if (ticket.modifiers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                  ticket.modifiers
                                      .map((m) => m.display)
                                      .join(' · '),
                                  style: SatType.sans(
                                      size: 12,
                                      color: sc.textMd,
                                      height: 1.4)),
                            ),
                          if (ticket.note != null &&
                              ticket.note!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: NoteLine(
                                label: 'Instruksi khusus',
                                text: ticket.note!,
                              ),
                            ),
                          if (ticket.voidReason != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                'Dibatalkan · ${ticket.voidReason} · disetujui oleh ${ticket.voidApprovedBy ?? ''}',
                                style: SatType.sans(
                                    size: 12, color: sc.urgent, height: 1.4),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _StatusChip(status: ticket.status),
                              const SizedBox(width: 8),
                              ElapsedPill(
                                sentAtTime: ticket.sentAtTime,
                                sentAtClock: ticket.sentAt,
                                terminal: isVoided ||
                                    ticket.status == TicketStatus.served,
                              ),
                              if (orderer != null) ...[
                                const SizedBox(width: 8),
                                StaffAvatar(actor: orderer, size: 18),
                              ],
                              const Spacer(),
                              Text(formatIDR(ticket.price * ticket.qty),
                                  style: SatType.mono(
                                    size: 12,
                                    weight: FontWeight.w500,
                                    color: sc.textMd,
                                    letterSpacing: 0,
                                  )),
                            ],
                          ),
                          if (isReady && !readOnly)
                            _EntranceFade(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
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

class _StatusChip extends StatelessWidget {
  final TicketStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    Color bg;
    Color fg;
    switch (status) {
      case TicketStatus.draft:
      case TicketStatus.acknowledged:
      case TicketStatus.sent:
        bg = sc.infoSoft;
        fg = sc.info;
        break;
      case TicketStatus.prep:
        bg = sc.warnSoft;
        fg = sc.warn;
        break;
      case TicketStatus.cooked:
        bg = sc.accentSoft;
        fg = sc.accent;
        break;
      case TicketStatus.ready:
        bg = sc.successSoft;
        fg = sc.success;
        break;
      case TicketStatus.served:
        bg = sc.bg3;
        fg = sc.textLo;
        break;
      case TicketStatus.held:
        bg = sc.violetSoft;
        fg = sc.violet;
        break;
      case TicketStatus.voided:
        bg = sc.urgentSoft;
        fg = sc.urgent;
        break;
    }
    final reduced = _animationsDisabled(context);
    final label = ticketStatusLabel(status).toUpperCase();
    return AnimatedContainer(
      duration: reduced ? Duration.zero : _kChipMorph,
      curve: _kEase,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: AnimatedSwitcher(
        duration: reduced ? Duration.zero : _kChipMorph,
        switchInCurve: _kEase,
        switchOutCurve: _kEase,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.0).animate(anim), child: child),
        ),
        child: Text(
          label,
          key: ValueKey(label),
          style: SatType.mono(
            size: 10,
            weight: FontWeight.w600,
            letterSpacing: 1.0,
            color: fg,
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
  const _SmallSuccessButton(
      {required this.label, required this.icon, required this.onTap});

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
          side: BorderSide(color: sc.success.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, size: 14, color: sc.success),
        label: Text(label.toUpperCase(),
            style: SatType.sans(
              size: 12,
              weight: FontWeight.w600,
              letterSpacing: 0.48,
              color: sc.success,
            )),
      ),
    );
  }
}

class _EntranceFade extends StatefulWidget {
  final Widget child;
  const _EntranceFade({required this.child});

  @override
  State<_EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<_EntranceFade> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_animationsDisabled(context)) return widget.child;
    return AnimatedSlide(
      offset: _shown ? Offset.zero : const Offset(0, 0.05),
      duration: _kBlockEnter,
      curve: _kEase,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: _kBlockEnter,
        curve: _kEase,
        child: widget.child,
      ),
    );
  }
}
