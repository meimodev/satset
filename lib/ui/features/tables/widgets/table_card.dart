import 'package:flutter/material.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/reservations_repository.dart';
import 'package:satset/data/repositories/staff_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/models/reservation.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/motion.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/tables/view_models/floor_signals.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// Ticks once per second to drive live elapsed-time updates on table cards.
/// autoDispose so the stream stops when no card is watching it.
final tableElapsedTickerProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => SatClock.now(),
  ),
);

const Duration _kPressIn = Duration(milliseconds: 90);

/// A table on the floor grid.
///
/// Reads six independent signals — status, money, service state, ownership,
/// bookings and staleness — and lays them out so the worst one is the one a
/// waiter sees first (ADR-0048). Everything below `tt-row2` is conditional, so
/// a quiet table stays a number and a status and nothing else.
class TableCard extends ConsumerStatefulWidget {
  final VenueTable table;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool tablet;
  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
    required this.tablet,
    this.onLongPress,
  });

  @override
  ConsumerState<TableCard> createState() => _TableCardState();
}

class _TableCardState extends ConsumerState<TableCard> {
  bool _pressed = false;

  String _statusLabel(VenueTable table, Reservation? hold) {
    if (hold != null) return 'Dipesan';
    return switch (table.status) {
      TableStatus.available => 'Kosong',
      TableStatus.occupied => 'Terisi',
      TableStatus.pending => 'Pesanan masuk',
      TableStatus.ready =>
        'Siap ×${table.readyCount > 0 ? table.readyCount : 1}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    final tablet = widget.tablet;
    final sc = context.sat;
    final brutal = SatShape.brutal;

    ref.watch(tableElapsedTickerProvider);
    final now = SatClock.now();
    final settings = ref.watch(venueSettingsProvider);
    final visitId = table.currentVisitId;
    final lines = visitId == null
        ? const <Ticket>[]
        : (ref.watch(ticketsProvider)[visitId] ?? const <Ticket>[]);
    final reservations = ref.watch(reservationsRepositoryProvider);

    final hold = reservationHoldFor(
      table,
      reservations,
      now,
      dayStart: businessDayStart(now, settings.businessDayStartHour),
    );
    final next = nextReservationFor(table, reservations, now);
    final service = serviceStateFor(table, lines, settings, now);
    final stale = staleFor(
      table: table,
      lines: lines,
      hold: hold,
      service: service,
      s: settings,
      now: now,
    );

    final isReady = table.status == TableStatus.ready;
    final isOccupied = table.status == TableStatus.occupied;
    final isPending = table.status == TableStatus.pending;
    // `reservationHoldFor` only returns a booking for a free table, so this is
    // exclusive with the three above rather than an overlay on them.
    final isReserved = hold != null;

    // Status fills. Both poster skins paint the semantic *soft* token as the
    // card's ground — brutal because its softs are near-saturation blocks, glow
    // because the source styles all four states that way and separates with
    // slab colour rather than a rule. Lembut's softs are 14% tints meant to sit
    // behind a border, so it keeps the original neutral-ramp mapping. Phrased
    // as "not lembut" per ADR-0051, so a future skin does not inherit bg3.
    final poster = !SatShape.lembut;

    Color bg = sc.bg2;
    Color border = sc.border0;
    Color statusDot = sc.textDim;
    Color statusColor = sc.textMd;
    Color numColor = sc.textHi;

    if (isOccupied) {
      bg = poster ? sc.infoSoft : sc.bg3;
      statusDot = sc.info;
      statusColor = brutal ? sc.textHi : sc.info;
    } else if (isPending) {
      bg = poster ? sc.warnSoft : sc.bg3;
      border = brutal ? sc.border0 : sc.warnSoft;
      statusDot = sc.warn;
      statusColor = brutal ? sc.textHi : sc.warn;
    } else if (isReady) {
      bg = sc.successSoft;
      border = brutal ? sc.border0 : sc.success.withValues(alpha: 0.5);
      statusDot = sc.success;
      // Brutal keeps ink on the slab: the fill already carries the signal, and
      // green-on-green fails contrast (ADR-0047's successInk finding).
      statusColor = brutal ? sc.textHi : sc.success;
      numColor = brutal ? sc.textHi : sc.success;
    } else if (isReserved) {
      // A held table is not an empty one. Without this the card said "Dipesan"
      // in words and rendered identical to a free table — the state was legible
      // only to someone already reading the label.
      bg = poster ? sc.violetSoft : sc.bg3;
      border = brutal ? sc.border0 : sc.violet;
      statusDot = sc.violet;
      statusColor = brutal ? sc.textHi : sc.violet;
    }

    final currentUserId = ref.watch(authStateProvider).user?.id;
    final staff = ref.watch(staffRepositoryProvider);
    final actor = table.lastActorId == null
        ? null
        : staff.where((u) => u.id == table.lastActorId).firstOrNull;
    final isMine = actor != null && actor.id == currentUserId;
    if (isMine && !brutal) border = sc.accentBorder;

    final radius = tablet ? 20.0 : 22.0;
    final padH = tablet ? 18.0 : 14.0;
    final padTop = tablet ? 18.0 : 16.0;
    // The stale banner runs edge to edge across the foot, so the card carries
    // no bottom padding of its own when one is showing.
    final padBottom = stale != null ? 0.0 : (tablet ? 16.0 : 14.0);

    // Built once: this rebuilds every second off the ticker.
    final pills = _pills(table, service, sc);

    final reduced = !motionEnabled(context);
    final xfade = reduced
        ? Duration.zero
        : const Duration(milliseconds: satStatusXfadeMs);
    final pressDur = reduced ? Duration.zero : _kPressIn;

    final body = Padding(
      padding: EdgeInsets.fromLTRB(padH, padTop, padH, tablet ? 4 : 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedDefaultTextStyle(
                    duration: xfade,
                    curve: satEaseOut,
                    // Poster size either way; the FittedBox above scales it
                    // into the phone's smaller slot.
                    style: brutal
                        ? SatType.h1(color: numColor)
                        : SatType.monoDisplay(color: numColor),
                    child: Text(
                      table.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              if (isMine)
                const _OwnerChip.mine()
              else if (actor != null)
                _OwnerChip.other(initials: actor.initials),
            ],
          ),
          if (hold != null) ...[
            const SizedBox(height: Sp.s1),
            Text(
              hold.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (tablet
                  ? SatType.labelM(color: sc.textHi)
                  : SatType.labelS(color: sc.textHi)),
            ),
          ],
          const SizedBox(height: Sp.s1h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.person_outline,
                size: tablet ? 14 : 12,
                color: sc.textMd,
              ),
              const SizedBox(width: Sp.s1),
              Text(
                '${table.pax}/${table.capacity}',
                style: SatType.monoS(color: sc.textMd),
              ),
              if (table.openAmount > 0) ...[
                const SizedBox(width: Sp.s2),
                Expanded(
                  child: Text(
                    formatIDR(table.openAmount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SatType.monoM(color: sc.textHi),
                  ),
                ),
              ],
            ],
          ),
          if (pills.isNotEmpty) ...[
            const SizedBox(height: Sp.s2),
            Wrap(spacing: 5, runSpacing: 5, children: pills),
          ],
          const Spacer(),
          const SizedBox(height: Sp.s2h),
          Row(
            children: [
              AnimatedContainer(
                duration: xfade,
                curve: satEaseOut,
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusDot,
                  // Circles stay circles (ADR-0047), but brutal still rules them.
                  border: brutal
                      ? Border.all(color: SatShape.ink, width: 2)
                      : null,
                ),
              ),
              const SizedBox(width: Sp.s2),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: xfade,
                  curve: satEaseOut,
                  style: SatType.labelS(color: statusColor),
                  child: Text(
                    SatShape.caps(_statusLabel(table, hold)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (table.openedAt != null) ...[
                const SizedBox(width: Sp.s1h),
                Text(
                  formatElapsedId(now.difference(table.openedAt!)),
                  style: SatType.monoS(color: sc.textLo),
                ),
              ] else if (hold != null) ...[
                const SizedBox(width: Sp.s1h),
                Text(
                  _hhmm(hold.expectedAt),
                  style: SatType.monoS(color: sc.textLo),
                ),
              ],
            ],
          ),
          // A stuck card gets one footer, not two. The source hides the
          // booking footnote outright (`.is-stale .tt-resv { display: none }`)
          // — the overrun names what to do now, and "20:30 · Budi" underneath
          // it is the next hour's problem competing for the same glance.
          if (next != null && stale == null) ...[
            const SizedBox(height: Sp.s1h),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 12, color: sc.textLo),
                const SizedBox(width: Sp.s1h),
                Expanded(
                  child: Text(
                    '${_hhmm(next.expectedAt)} · ${next.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SatType.monoS(color: sc.textLo),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: padBottom),
        ],
      ),
    );

    final content = stale == null
        ? body
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(child: body),
              _StaleBanner(stale: stale, tablet: tablet),
            ],
          );

    final decoration = BoxDecoration(
      color: bg,
      borderRadius: SatR.a(radius),
      border: SatB.all(color: border),
      boxShadow: _cardShadow(stale, sc),
    );

    // Brutal presses the card into its own shadow; the other two scale it down
    // — 0.97 is also exactly what Glow specifies for a press.
    final pressOffset = brutal && _pressed ? 3.0 : 0.0;
    final card = AnimatedScale(
      scale: !brutal && _pressed ? 0.97 : 1.0,
      duration: pressDur,
      curve: satEaseOut,
      child: AnimatedContainer(
        duration: pressDur,
        curve: satEaseOut,
        transform: Matrix4.translationValues(pressOffset, pressOffset, 0),
        decoration: brutal && _pressed
            ? decoration.copyWith(boxShadow: const [])
            : decoration,
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () {
              if (_pressed) setState(() => _pressed = false);
            },
            onTapUp: (_) {
              if (_pressed) setState(() => _pressed = false);
            },
            child: content,
          ),
        ),
      ),
    );

    // The card's number, owner chip, pills and stale banner are separate text
    // nodes; without merging, TalkBack reads them as four unrelated stops and a
    // waiter sweeping the grid never hears a whole table. Merged, one swipe
    // announces "Meja 4, terisi, Punya saya" in visual order — and because the
    // label is derived from what is actually painted, it cannot drift.
    return MergeSemantics(child: Semantics(button: true, child: card));
  }

  /// Crit cards sit on a doubled shadow so a screen of lifted cards still has
  /// one that reads as lifted further.
  ///
  /// Brutal stacks a red slab behind the ink one. Glow does the same job with
  /// a hard 2px `urgent` ring under its ordinary lift, which is what the source
  /// design specifies for `.sev-crit` — a blurred red glow would read as
  /// decoration, and `urgent` is too scarce a colour to spend on that.
  List<BoxShadow>? _cardShadow(TableStale? stale, SatColors sc) {
    final crit = stale?.severity == StaleSeverity.crit;
    switch (SatShape.skin) {
      case SatSkin.lembut:
        return null;
      case SatSkin.brutal:
        if (!crit) return SatShape.hardShadow(5);
        return [
          BoxShadow(color: sc.urgent, offset: const Offset(5, 5)),
          BoxShadow(
            color: SatShape.ink,
            offset: const Offset(5, 5),
            spreadRadius: 3,
            blurRadius: 0,
          ),
        ].reversed.toList();
      case SatSkin.glow:
        if (!crit) return SatShape.lift;
        return [
          BoxShadow(color: sc.urgent, spreadRadius: 2, blurRadius: 0),
          ...SatShape.lift,
        ];
    }
  }

  List<Widget> _pills(VenueTable t, ServiceState service, SatColors sc) {
    return [
      if (service == ServiceState.ungreeted)
        _StatePill(
          label: AppStrings.tableStateUngreeted,
          tone: sc.urgent,
          sc: sc,
        ),
      if (service == ServiceState.idle)
        _StatePill(label: AppStrings.tableStateIdle, tone: sc.warn, sc: sc),
      if (t.billClosed || t.moneyState == 'paid')
        _StatePill(label: AppStrings.tablePaidFull, tone: sc.success, sc: sc)
      else if (t.moneyState == 'partial')
        _StatePill(label: AppStrings.tablePaidPartial, tone: sc.info, sc: sc),
    ];
  }
}

String _hhmm(DateTime d) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${pad(d.hour)}:${pad(d.minute)}';
}

/// "Punya saya" on a table this waiter is running, or the other waiter's
/// initials. Squared under brutal per the rail-avatar precedent (ADR-0047):
/// at this size it reads as a nameplate, not a status pip.
class _OwnerChip extends StatelessWidget {
  final String? initials;
  const _OwnerChip.mine() : initials = null;
  const _OwnerChip.other({required String this.initials});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final brutal = SatShape.brutal;
    final glow = SatShape.glow;
    if (initials == null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Sp.s1h,
          vertical: Sp.s1,
        ),
        decoration: BoxDecoration(
          // Glow spends the accent as a fill, not a tint: the source paints
          // "Punya saya" solid lime with obsidian ink. A 34% lime wash on a
          // bone card is not a state anyone notices at arm's length.
          color: brutal || glow ? sc.accent : sc.accentSoft,
          borderRadius: glow ? SatR.pill : SatR.a(6),
          border: glow ? null : SatB.all(color: sc.accentBorder),
          boxShadow: brutal ? SatShape.hardShadow(2) : null,
        ),
        child: Text(
          SatShape.caps(AppStrings.tableOwnerMine),
          style: SatType.labelS(
            color: brutal || glow ? sc.accentInk : sc.accentText,
          ),
        ),
      );
    }
    // Brutal keeps this square (ADR-0047): at 30px it reads as a nameplate,
    // not a status pip. Glow rounds it to a disc instead — its sixth grammar
    // rule is that avatars, dots and icon tiles are circles filled with a soft
    // tint, and this is the only avatar on the card.
    return Container(
      width: brutal ? 30 : 26,
      height: brutal ? 30 : 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: glow ? sc.bg3 : sc.bg1,
        shape: glow ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: glow ? null : SatR.a(6),
        border: glow ? null : SatB.all(color: sc.border1),
      ),
      child: Text(
        initials!,
        style: brutal
            ? SatType.labelS(color: sc.textHi)
            : SatType.caption(color: sc.textMd),
      ),
    );
  }
}

/// Money and service-state chips. Outlined under lembut, filled under both
/// poster skins — the neo skin has no tints, only blocks, and Glow's source
/// comments the same rule for these pills in as many words: *"solid fills with
/// obsidian/white ink, per the reference — never tint-on-tint"*. It matters
/// here more than anywhere: under Glow the card behind them is already a
/// semantic tint, so a tinted pill is a tint on a tint.
class _StatePill extends StatelessWidget {
  final String label;
  final Color tone;
  final SatColors sc;
  const _StatePill({required this.label, required this.tone, required this.sc});

  @override
  Widget build(BuildContext context) {
    final brutal = SatShape.brutal;
    final solid = !SatShape.lembut;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s1h, vertical: Sp.s1),
      decoration: BoxDecoration(
        color: solid ? tone : tone.withValues(alpha: 0.15),
        // Glow pills are pills. `SatR.a(6)` passes 6 through untouched under
        // that skin — the ramp deliberately leaves sub-8 radii alone — so the
        // shape has to be asked for by name.
        borderRadius: SatShape.glow ? SatR.pill : SatR.a(6),
        border: brutal ? Border.all(color: SatShape.ink, width: 2) : null,
      ),
      child: Text(
        SatShape.caps(label),
        style: SatType.labelS(color: solid ? sc.inkOn(tone) : tone),
      ),
    );
  }
}

/// Full-bleed banner across the foot of a stuck card. Names the overrun and,
/// where there is one, the action — never just a colour.
class _StaleBanner extends StatelessWidget {
  final TableStale stale;
  final bool tablet;
  const _StaleBanner({required this.stale, required this.tablet});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final brutal = SatShape.brutal;
    final crit = stale.severity == StaleSeverity.crit;
    // Glow puts both tiers on the same obsidian slab — its grammar separates
    // with slab colour, not with hue floods, and a crit foot flooded `urgent`
    // read as "the card turned red", swallowing the order-state tint the card
    // body carries. Crit now spends `urgent` on the bang and on the card's 2px
    // ring (see `_cardShadow`), which is where the scarce colour belongs. The
    // other skins keep amber for the warn tier and red for crit.
    final glow = SatShape.glow;
    final fill = glow
        ? sc.slab.bg0
        : crit
        ? sc.urgent
        : sc.warn;
    // Both other skins pick the foreground by luminance. White on `warn` amber
    // is ~2:1 and fails AA — and this banner is the one thing on the card a
    // waiter has to read at a glance. On the slab the palette names it.
    final fg = glow ? sc.slab.textHi : onFill(fill);
    return Container(
      padding: EdgeInsets.fromLTRB(tablet ? 18 : 14, 7, tablet ? 18 : 14, 7),
      decoration: BoxDecoration(
        color: fill,
        border: brutal
            ? Border(top: BorderSide(color: SatShape.ink, width: 3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 15,
            height: 15,
            alignment: Alignment.center,
            // Glow's bang is a filled disc, not an outlined box — it draws no
            // rules, so a hairline square would be the one border on the card.
            // Crit fills it at full strength: with both tiers on the same slab
            // it is the only thing on the foot that says which tier this is.
            decoration: glow
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: crit ? sc.slab.urgent : fg.withValues(alpha: 0.2),
                  )
                : BoxDecoration(
                    borderRadius: SatR.a(4),
                    border: Border.all(color: fg, width: brutal ? 2 : 1),
                  ),
            child: Text(
              '!',
              style: SatType.labelS(color: glow && crit ? sc.slab.bg0 : fg),
            ),
          ),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: Text(
              SatShape.caps(stale.label),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SatType.labelS(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
