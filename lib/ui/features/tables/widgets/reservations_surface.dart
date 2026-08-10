import 'dart:async';

import 'package:satset/core/localization/labels.dart';
import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/member_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/members_repository.dart';
import 'package:satset/data/repositories/reservations_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/domain/models/reservation.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';

/// The booking book (ADR-0048). One content widget, two containers: a right-side
/// drawer on tablet — the source design's idiom for a surface you read *against*
/// the floor grid — and a tall bottom sheet on a phone, where a 460px side panel
/// would be the whole screen anyway.
Future<void> openReservationsSurface(
  BuildContext context, {
  required bool tablet,
}) {
  final sc = context.sat;
  if (!tablet) {
    return showSatSheet<void>(
      context,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: Sp.s2h),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: sc.border1,
                  borderRadius: SatR.a(2),
                ),
              ),
              const Expanded(child: ReservationsBook()),
            ],
          ),
        ),
      ),
    );
  }
  return showSatDrawer<void>(
    context,
    builder: (ctx) => Material(
      color: sc.bg1,
      child: Container(
        // Wide enough that all five filters fit without the last one hanging
        // off the edge — measured, not chosen.
        width: 520,
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border(left: SatB.side(color: sc.border1)),
        ),
        child: const SafeArea(child: ReservationsBook()),
      ),
    ),
  );
}

enum _RvFilter { waiting, late, seated, noShow, all }

/// Today's bookings, filtered, with the seat / no-show / restore actions.
///
/// There is no "Telat" action, unlike the source design: lateness here is a
/// derived display state (ADR-0044) — a clock must not decide a no-show — so
/// there is no status to set. A late booking is already marked as such.
class ReservationsBook extends ConsumerStatefulWidget {
  const ReservationsBook({super.key});

  @override
  ConsumerState<ReservationsBook> createState() => _ReservationsBookState();
}

class _ReservationsBookState extends ConsumerState<ReservationsBook> {
  _RvFilter _filter = _RvFilter.waiting;

  bool _isLate(Reservation r, int graceMins, DateTime now) =>
      r.status == ReservationStatus.pending &&
      now.difference(r.expectedAt) > Duration(minutes: graceMins);

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final now = SatClock.now();
    final grace = ref.watch(venueSettingsProvider).reservationGraceMins;
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final today =
        ref
            .watch(reservationsRepositoryProvider)
            .where(
              (r) =>
                  r.expectedAt.isAfter(
                    start.subtract(const Duration(minutes: 1)),
                  ) &&
                  r.expectedAt.isBefore(end),
            )
            .toList()
          ..sort((a, b) => a.expectedAt.compareTo(b.expectedAt));

    List<Reservation> pick(_RvFilter f) => switch (f) {
      _RvFilter.waiting =>
        today.where((r) => r.status == ReservationStatus.pending).toList(),
      _RvFilter.late => today.where((r) => _isLate(r, grace, now)).toList(),
      _RvFilter.seated =>
        today.where((r) => r.status == ReservationStatus.seated).toList(),
      _RvFilter.noShow =>
        today
            .where(
              (r) =>
                  r.status == ReservationStatus.noShow ||
                  r.status == ReservationStatus.cancelled,
            )
            .toList(),
      _RvFilter.all => today,
    };

    final list = pick(_filter);
    final covers = today
        .where(
          (r) =>
              r.status != ReservationStatus.noShow &&
              r.status != ReservationStatus.cancelled,
        )
        .fold<int>(0, (s, r) => s + r.partySize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SatShape.caps(context.l10n.floorReservationsBook),
                      style: SatType.h2(color: sc.textHi),
                    ),
                    const SizedBox(height: Sp.s1),
                    Text(
                      context.l10n.resDaySummary(
                        formatBookingDayId(now),
                        today.length,
                        covers,
                      ),
                      style: SatType.monoS(color: sc.textLo),
                    ),
                  ],
                ),
              ),
              // The source puts the primary action in the head, beside what it
              // acts on, rather than at the foot below a scrolling list where
              // it is off screen exactly when the book is busy.
              SatButton.primary(
                label: context.l10n.resNewBooking,
                icon: Icons.add,
                size: SatButtonSize.sm,
                onTap: () => openCreateReservationSheet(context, ref),
              ),
              const SizedBox(width: Sp.s1),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
                tooltip: context.l10n.close,
              ),
            ],
          ),
        ),
        SizedBox(
          height: Sp.s10,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Sp.s5),
            children: [
              for (final f in _RvFilter.values) ...[
                SatChip.select(
                  label: switch (f) {
                    _RvFilter.waiting => context.l10n.reservationFilterWaiting,
                    _RvFilter.late => context.l10n.reservationFilterLate,
                    _RvFilter.seated => context.l10n.reservationFilterSeated,
                    _RvFilter.noShow => context.l10n.reservationFilterNoShow,
                    _RvFilter.all => context.l10n.reservationFilterAll,
                  },
                  count: pick(f).length,
                  selected: _filter == f,
                  onTap: () => setState(() => _filter = f),
                ),
                if (f != _RvFilter.values.last) const SizedBox(width: Sp.s1h),
              ],
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              // The source draws a dashed outline here. `SatEmpty` is the
              // app's one empty state (ADR-0055) and says more with an icon
              // and a title than a dashed box does — forking the vocabulary to
              // match a border was the worse trade.
              ? SatEmpty(
                  icon: Icons.event_busy_outlined,
                  title: context.l10n.reservationEmptyFilter,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Sp.s2),
                  itemBuilder: (_, i) => _ReservationRow(
                    reservation: list[i],
                    late: _isLate(list[i], grace, now),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ReservationRow extends ConsumerWidget {
  final Reservation reservation;
  final bool late;
  const _ReservationRow({required this.reservation, required this.late});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final r = reservation;
    final n = ref.read(reservationsRepositoryProvider.notifier);
    final tableLabel = r.tableId == null
        ? null
        : ref
                  .watch(tablesProvider)
                  .where((t) => t.id == r.tableId)
                  .map((t) => t.displayName)
                  .firstOrNull ??
              r.tableId!;
    final zoneLabel = r.zoneId == null
        ? null
        : ref
              .watch(zonesProvider)
              .where((z) => z.id == r.zoneId)
              .map((z) => z.name)
              .firstOrNull;

    // A booking still waiting is the accent's job, not the info ramp's — the
    // source paints `rv-st-info` with the same rule it paints every other
    // accent pill. "Menunggu" is the one status on this row that is a thing to
    // go and do, so it takes the colour the app spends on actions.
    final (statusLabel, statusTone) = late
        ? (context.l10n.reservationLate, sc.urgent)
        : switch (r.status) {
            ReservationStatus.pending => (
              reservationStatusLabel(context.l10n, r.status),
              sc.accent,
            ),
            ReservationStatus.seated => (
              reservationStatusLabel(context.l10n, r.status),
              sc.success,
            ),
            _ => (reservationStatusLabel(context.l10n, r.status), sc.textLo),
          };

    // Landing inside the next 20 minutes — the window where the host should be
    // watching the door. Already computed for the relative label below; the
    // ground reads it too rather than leaving it to a line of 11pt mono.
    final isSoon =
        !late &&
        r.status == ReservationStatus.pending &&
        r.expectedAt.difference(SatClock.now()).inMinutes <= 20;
    final isDead =
        r.status == ReservationStatus.noShow ||
        r.status == ReservationStatus.cancelled;

    // The row's ground carries its state. A dead booking drops to the recessed
    // step and stops competing; everything else warms toward what it needs.
    final Color fill;
    if (late) {
      fill = Color.alphaBlend(sc.urgent.withValues(alpha: 0.10), sc.bg1);
    } else if (isSoon) {
      fill = Color.alphaBlend(sc.accent.withValues(alpha: 0.18), sc.bg1);
    } else if (r.status == ReservationStatus.seated) {
      fill = Color.alphaBlend(sc.success.withValues(alpha: 0.10), sc.bg1);
    } else if (isDead) {
      fill = sc.bg3;
    } else {
      fill = sc.bg2;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: SatBox.d(
        color: fill,
        borderRadius: SatR.a(14),
        border: SatB.all(color: late ? sc.urgent : sc.border0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hhmm(r.expectedAt),
                      // Both poster skins set the booking hour as display type
                      // — Glow's reservation rows lead on a heavy numeral, and
                      // `display` ignores the weight under brutal anyway.
                      style: SatShape.lembut
                          ? SatType.monoM(color: sc.textHi)
                          : SatType.labelL(color: sc.textHi),
                    ),
                    const SizedBox(height: Sp.sHair),
                    Text(
                      _relative(r, late),
                      style: SatType.monoS(color: late ? sc.urgent : sc.textLo),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Sp.s2h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // A regular is arriving and the till already knows
                        // them. The glyph and nothing else — points or tier
                        // here would be a number the host cannot act on.
                        if (r.memberId != null) ...[
                          Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: sc.accent,
                          ),
                          const SizedBox(width: Sp.s1),
                        ],
                        Flexible(
                          child: Text(
                            r.name,
                            overflow: TextOverflow.ellipsis,
                            style: SatType.labelM(color: sc.textHi),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.s1),
                    Text(
                      [
                        '${r.partySize} tamu',
                        // Where the party is going, not just which table.
                        // A booking with no table yet still has a zone, and
                        // that is what the host seats against.
                        ?zoneLabel,
                        if (tableLabel != null)
                          context.l10n.tableNamed(tableLabel)
                        else
                          context.l10n.tableNoReservationTable,
                        if (r.phone != null && r.phone!.trim().isNotEmpty)
                          r.phone!.trim(),
                      ].join(' · '),
                      style: SatType.monoS(color: sc.textLo),
                    ),
                    if (r.notes != null && r.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: Sp.s1),
                      Text(
                        r.notes!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SatType.bodyS(color: sc.textMd),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Sp.s2),
              _Tag(label: statusLabel, tone: statusTone),
            ],
          ),
          if (r.status == ReservationStatus.pending) ...[
            const SizedBox(height: Sp.s3),
            SeatPicker(reservation: r),
            const SizedBox(height: Sp.s2h),
            Row(
              children: [
                Expanded(
                  // The source tones this one red. It is the only action here
                  // that writes a guest off, and it sits beside a plain cancel
                  // — the two should not look interchangeable.
                  child: SatButton.danger(
                    label: context.l10n.reservationActionNoShow,
                    onTap: () async {
                      await n.updateStatus(r.id, ReservationStatus.noShow);
                    },
                  ),
                ),
                const SizedBox(width: Sp.s2),
                Expanded(
                  child: SatButton.outline(
                    label: context.l10n.cancel,
                    onTap: () async {
                      await n.updateStatus(r.id, ReservationStatus.cancelled);
                    },
                  ),
                ),
              ],
            ),
          ] else if (r.status != ReservationStatus.seated) ...[
            const SizedBox(height: Sp.s2h),
            SatButton.outline(
              label: context.l10n.reservationActionRestore,
              onTap: () async {
                await n.updateStatus(r.id, ReservationStatus.pending);
              },
            ),
          ],
        ],
      ),
    );
  }

  String _relative(Reservation r, bool late) {
    if (r.status == ReservationStatus.seated) return 'duduk';
    final diff = r.expectedAt.difference(SatClock.now());
    if (late) return '+${-diff.inMinutes} mnt';
    if (r.status == ReservationStatus.pending && diff.inMinutes <= 20) {
      return 'dalam ${diff.inMinutes} mnt';
    }
    return '—';
  }
}

/// Status tag on a booking row. Kept in step with `_StatePill` on the table
/// card — same rule, same reason: both poster skins fill solid, and under Glow
/// the row behind this tag is itself a semantic wash, so a tinted tag would be
/// a tint on a tint.
// ponytail: still two copies of this, one here and one in `table_card.dart`.
// They agree today. Fold both into `SatChip` if a third appears — one caller
// each does not yet pay for a parameter on the shared widget.
class _Tag extends StatelessWidget {
  final String label;
  final Color tone;
  const _Tag({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final brutal = SatShape.brutal;
    final solid = !SatShape.lembut;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s1h, vertical: Sp.s1),
      decoration: BoxDecoration(
        color: solid ? tone : tone.withValues(alpha: 0.15),
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

/// Zone tabs + free tables of a sufficient capacity. Seating claims the table
/// lock atomically so a second device that sees the WS broadcast cannot snatch
/// it before the reservation waiter walks over.
class SeatPicker extends ConsumerStatefulWidget {
  final Reservation reservation;
  const SeatPicker({super.key, required this.reservation});

  @override
  ConsumerState<SeatPicker> createState() => _SeatPickerState();
}

class _SeatPickerState extends ConsumerState<SeatPicker> {
  String? _zoneId;

  @override
  void initState() {
    super.initState();
    _zoneId = widget.reservation.zoneId;
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final zones = ref.watch(zonesProvider);
    final tables = ref.watch(tablesProvider);
    final activeZoneId = _zoneId ?? (zones.isNotEmpty ? zones.first.id : null);
    final r = widget.reservation;
    final available = tables
        .where(
          (t) =>
              t.status == TableStatus.available &&
              t.capacity >= r.partySize &&
              (activeZoneId == null || t.zoneId == activeZoneId),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SatShape.caps(
            context.l10n.resvSeatToTable(context.l10n.reservationActionSeat),
          ),
          style: SatType.caption(color: sc.textLo),
        ),
        const SizedBox(height: Sp.s2),
        if (zones.length > 1)
          SizedBox(
            height: Sp.s8,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: zones.length,
              separatorBuilder: (_, _) => const SizedBox(width: Sp.s1h),
              itemBuilder: (_, i) {
                final z = zones[i];
                final isActive = z.id == activeZoneId;
                return GestureDetector(
                  onTap: () => setState(() => _zoneId = z.id),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: Sp.s3),
                    decoration: SatBox.d(
                      color: isActive
                          ? (SatShape.lembut ? sc.textHi : sc.accent)
                          : sc.bg3,
                      border: SatB.all(color: sc.border0),
                      borderRadius: SatR.a(999),
                    ),
                    child: Text(
                      z.name,
                      style: SatType.labelS(
                        color: isActive
                            ? (SatShape.lembut ? sc.bg0 : sc.accentInk)
                            : sc.textMd,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: Sp.s2),
        if (available.isEmpty)
          Text(
            context.l10n.resNoTableForParty(r.partySize),
            style: SatType.bodyS(color: sc.textMd),
          )
        else
          SizedBox(
            height: Sp.s9,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: available.length,
              separatorBuilder: (_, _) => const SizedBox(width: Sp.s1h),
              itemBuilder: (_, i) {
                final t = available[i];
                return GestureDetector(
                  onTap: () => _seat(context, t),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: Sp.s3),
                    decoration: SatBox.d(
                      color: sc.bg3,
                      border: SatB.all(color: sc.border1),
                      borderRadius: SatR.a(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.displayName,
                          style: SatType.monoM(color: sc.textHi),
                        ),
                        const SizedBox(width: Sp.s1h),
                        Icon(Icons.person_outline, size: 11, color: sc.textLo),
                        Text(
                          '${t.capacity}',
                          style: SatType.monoS(color: sc.textLo),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _seat(BuildContext ctx, VenueTable t) async {
    final r = widget.reservation;
    final user = ref.read(authStateProvider).user;
    try {
      await ref
          .read(tablesProvider.notifier)
          .seat(
            t.id,
            pax: r.partySize,
            guestName: r.name,
            guestNotes: r.notes,
            reservationId: r.id,
            userId: user?.id,
            userName: user?.name,
            acquireLock: true,
          );
      await ref
          .read(reservationsRepositoryProvider.notifier)
          .assignTable(r.id, zoneId: t.zoneId, tableId: t.id);
      await ref
          .read(reservationsRepositoryProvider.notifier)
          .updateStatus(r.id, ReservationStatus.seated);
    } on ApiException catch (e) {
      if (ctx.mounted) {
        final msg = e.code == 'already_seated'
            ? ctx.l10n.resAlreadySeated
            : ctx.l10n.resSeatFailed('${e.code ?? e.statusCode}');
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text(ctx.l10n.resSeatFailed('$e'))));
      }
    }
  }
}

/// Create form. Stays a sheet on both form factors — it is a keyboard-driven
/// task, and a keyboard makes a side drawer as narrow as a sheet anyway.
Future<void> openCreateReservationSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final sc = context.sat;
  final nameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final notesCtl = TextEditingController();
  var party = 2;
  final now = SatClock.now();
  var expected = DateTime(now.year, now.month, now.day, 19, 0);
  String? zoneId;
  String? tableId;
  // The [[Pelanggan (member)]] this booking is for, if the host found one.
  // Finding beats typing: a regular booked by hand for the fourth time is a
  // fourth record, and the directory is keyed on a phone number nobody
  // re-reads carefully at 19:00.
  MemberDto? linked;
  var enrol = true;

  await showSatSheet<void>(
    context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return Padding(
            padding: EdgeInsets.only(
              left: Sp.s5,
              right: Sp.s5,
              top: Sp.s4,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: SatBox.d(
                        color: sc.border1,
                        borderRadius: SatR.a(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: Sp.s3h),
                  Text(
                    SatShape.caps(ctx.l10n.resNewBooking),
                    style: SatType.h3(color: sc.textHi),
                  ),
                  const SizedBox(height: Sp.s4),
                  _MemberPicker(
                    linked: linked,
                    onPick: (m) => setLocal(() {
                      linked = m;
                      // Pre-fill, do not lock: the two fields below are the
                      // snapshot of what was booked, and a booking under
                      // "Budi (istri)" against Budi's record is legitimate.
                      nameCtl.text = m.name;
                      phoneCtl.text = m.phone;
                    }),
                    onClear: () => setLocal(() => linked = null),
                  ),
                  SatField.text(
                    controller: nameCtl,
                    label: ctx.l10n.resGuestName,
                    hint: '',
                  ),
                  const SizedBox(height: Sp.s2h),
                  SatField.number(
                    controller: phoneCtl,
                    label: ctx.l10n.resPhone,
                    hint: ctx.l10n.resOptional,
                  ),
                  if (linked == null &&
                      ref.watch(membersProvider).enabled) ...[
                    const SizedBox(height: Sp.s1),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ctx.l10n.resMemberEnrol,
                            style: SatType.bodyM(color: sc.textMd),
                          ),
                        ),
                        SatToggle(
                          value: enrol,
                          semanticLabel: ctx.l10n.resMemberEnrol,
                          onChanged: (v) => setLocal(() => enrol = v),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: Sp.s2h),
                  Row(
                    children: [
                      Text(
                        ctx.l10n.resPartySize,
                        style: SatType.bodyM(color: sc.textHi),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: context.l10n.a11yGuestDecrease,
                        onPressed: party > 1
                            ? () => setLocal(() => party--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      SizedBox(
                        width: Sp.s8,
                        child: Center(
                          child: Text(
                            '$party',
                            style: SatType.labelL(color: sc.textHi),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.a11yGuestIncrease,
                        onPressed: () => setLocal(() => party++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.s2),
                  Row(
                    children: [
                      Expanded(
                        child: SatButton.outline(
                          label: _fmtDate(expected),
                          icon: Icons.calendar_today,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: expected,
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 2),
                            );
                            if (picked != null) {
                              setLocal(
                                () => expected = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  expected.hour,
                                  expected.minute,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: Sp.s2),
                      Expanded(
                        child: SatButton.outline(
                          label: _hhmm(expected),
                          icon: Icons.schedule,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay(
                                hour: expected.hour,
                                minute: expected.minute,
                              ),
                            );
                            if (picked != null) {
                              setLocal(
                                () => expected = DateTime(
                                  expected.year,
                                  expected.month,
                                  expected.day,
                                  picked.hour,
                                  picked.minute,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.s3h),
                  // Pre-assigning a table is what makes the floor card read
                  // "Dipesan" before the guest arrives — without it a booking is
                  // invisible on the grid until someone seats it (ADR-0048).
                  _TablePicker(
                    ref: ref,
                    zoneId: zoneId,
                    tableId: tableId,
                    partySize: party,
                    onPick: (z, t) => setLocal(() {
                      zoneId = z;
                      tableId = t;
                    }),
                  ),
                  const SizedBox(height: Sp.s2h),
                  SatField.text(
                    controller: notesCtl,
                    label: context.l10n.expNote,
                    hint: context.l10n.resOptional,
                    maxLines: 2,
                  ),
                  const SizedBox(height: Sp.s4h),
                  SatButton.primary(
                    label: context.l10n.resSaveBooking,
                    onTap: () async {
                      final name = nameCtl.text.trim();
                      if (name.isEmpty) return;
                      final phone = phoneCtl.text.trim();
                      // Best effort, and deliberately so: a booking is what
                      // the guest is waiting on, the directory row is
                      // bookkeeping. Losing a table because a number was six
                      // digits is the worst trade on this screen.
                      final (memberId, enrolFailed) = await _resolveMember(
                        ctx,
                        ref,
                        linked: linked,
                        enrol: enrol,
                        name: name,
                        phone: phone,
                      );
                      try {
                        await ref
                            .read(reservationsRepositoryProvider.notifier)
                            .create(
                              name: name,
                              phone: phone.isEmpty ? null : phone,
                              partySize: party,
                              expectedAt: expected,
                              zoneId: zoneId,
                              tableId: tableId,
                              notes: notesCtl.text.trim().isEmpty
                                  ? null
                                  : notesCtl.text.trim(),
                              memberId: memberId,
                            );
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          if (enrolFailed) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.resMemberEnrolFailed),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(ctx.l10n.resSaveFailed('$e')),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Settle who this booking belongs to, before the reservation is written.
///
/// Returns the member id to link and whether an enrolment was attempted and
/// failed — never throws, because the booking must save either way. A number
/// that already belongs to someone comes back from the server as `phone_taken`
/// carrying its owner, and the host is asked rather than silently attached: the
/// whole point of this flow is that they can see whose record they just joined.
Future<(String?, bool)> _resolveMember(
  BuildContext ctx,
  WidgetRef ref, {
  required MemberDto? linked,
  required bool enrol,
  required String name,
  required String phone,
}) async {
  if (linked != null) return (linked.id, false);
  if (!enrol || phone.isEmpty) return (null, false);
  if (!ref.read(membersProvider).enabled) return (null, false);
  final members = ref.read(membersProvider.notifier);
  try {
    final made = await members.enrol(name: name, phone: phone);
    return (made.id, false);
  } catch (e) {
    final err = memberErrorOf(e);
    final ownerId = err?.code == 'phone_taken' ? err?.memberId : null;
    if (ownerId == null) return (null, true);
    try {
      final owner = await members.detail(ownerId);
      if (!ctx.mounted) return (null, false);
      final use = await showSatSheet<bool>(
        ctx,
        builder: (c) => _ConfirmUseMember(name: owner.member.name),
      );
      return (use == true ? ownerId : null, false);
    } catch (_) {
      // Could not read the owner — linking to a name nobody saw is exactly
      // what this confirmation exists to prevent.
      return (null, true);
    }
  }
}

/// "This number belongs to X — use them?" Two buttons, no third option: the
/// host either joins the existing record or books a plain guest.
class _ConfirmUseMember extends StatelessWidget {
  final String name;
  const _ConfirmUseMember({required this.name});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.s5, Sp.s3, Sp.s5, Sp.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.resMemberTakenTitle,
              style: SatType.labelL(color: sc.textHi),
            ),
            const SizedBox(height: Sp.s2),
            Text(
              context.l10n.resMemberTakenBody(name),
              style: SatType.bodyM(color: sc.textMd),
            ),
            const SizedBox(height: Sp.s4h),
            Row(
              children: [
                Expanded(
                  child: SatButton.outline(
                    label: context.l10n.cancel,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: Sp.s2h),
                Expanded(
                  child: SatButton.primary(
                    label: context.l10n.resMemberUse,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Find the guest in the directory before typing them in again. Renders
/// nothing at all when the venue never switched membership on (ADR-0091) — a
/// booking form is not where a venue should learn the feature exists.
class _MemberPicker extends ConsumerStatefulWidget {
  final MemberDto? linked;
  final ValueChanged<MemberDto> onPick;
  final VoidCallback onClear;
  const _MemberPicker({
    required this.linked,
    required this.onPick,
    required this.onClear,
  });

  @override
  ConsumerState<_MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends ConsumerState<_MemberPicker> {
  final _q = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) ref.read(membersProvider.notifier).search(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final state = ref.watch(membersProvider);
    if (!state.enabled) return const SizedBox.shrink();

    final picked = widget.linked;
    if (picked != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Sp.s2h),
        child: Row(
          children: [
            Icon(Icons.person_rounded, size: 18, color: sc.accent),
            const SizedBox(width: Sp.s1h),
            Expanded(
              child: Text(
                '${picked.name} · ${picked.phone}',
                overflow: TextOverflow.ellipsis,
                style: SatType.labelM(color: sc.textHi),
              ),
            ),
            SatButton.outline(
              label: context.l10n.cshMemberDetach,
              onTap: () {
                _q.clear();
                widget.onClear();
              },
            ),
          ],
        ),
      );
    }

    final q = _q.text.trim();
    final results = q.isEmpty
        ? const <MemberDto>[]
        : state.members.take(4).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s2h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SatField.search(
            controller: _q,
            hint: context.l10n.memSearchHint,
            onChanged: _onQuery,
          ),
          if (q.isNotEmpty) ...[
            const SizedBox(height: Sp.s1h),
            if (results.isEmpty)
              Text(
                context.l10n.resMemberNoMatch,
                style: SatType.bodyS(color: sc.textLo),
              )
            else
              for (final m in results)
                Padding(
                  padding: const EdgeInsets.only(bottom: Sp.s1),
                  child: SatButton.outline(
                    label: '${m.name} · ${m.phone}',
                    onTap: () {
                      _q.clear();
                      widget.onPick(m);
                    },
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

/// Optional zone + table for a booking. "Tanpa meja" is the default and stays
/// valid: plenty of venues take a name and a time and sort the table out on the
/// night.
class _TablePicker extends StatelessWidget {
  final WidgetRef ref;
  final String? zoneId;
  final String? tableId;
  final int partySize;
  final void Function(String? zoneId, String? tableId) onPick;
  const _TablePicker({
    required this.ref,
    required this.zoneId,
    required this.tableId,
    required this.partySize,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final zones = ref.watch(zonesProvider);
    final activeZone = zoneId ?? (zones.isNotEmpty ? zones.first.id : null);
    final free = ref
        .watch(tablesProvider)
        .where(
          (t) =>
              t.active &&
              t.status == TableStatus.available &&
              t.capacity >= partySize &&
              (activeZone == null || t.zoneId == activeZone),
        )
        .toList();

    Widget chip(
      String label,
      bool active,
      VoidCallback onTap,
    ) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2),
        decoration: SatBox.d(
          color: active ? (SatShape.lembut ? sc.textHi : sc.accent) : sc.bg2,
          border: SatB.all(color: sc.border0),
          borderRadius: SatR.a(999),
        ),
        child: Text(
          SatShape.caps(label),
          style: SatType.labelS(
            color: active
                ? (SatShape.lembut ? sc.bg0 : sc.accentInk)
                : sc.textMd,
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SatShape.caps(context.l10n.resvZoneTableOptional),
          style: SatType.caption(color: sc.textLo),
        ),
        const SizedBox(height: Sp.s2),
        if (zones.length > 1)
          SizedBox(
            height: Sp.s9,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: zones.length,
              separatorBuilder: (_, _) => const SizedBox(width: Sp.s1h),
              itemBuilder: (_, i) => chip(
                zones[i].name,
                zones[i].id == activeZone,
                () => onPick(zones[i].id, null),
              ),
            ),
          ),
        const SizedBox(height: Sp.s1h),
        SizedBox(
          height: Sp.s9,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: free.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: Sp.s1h),
            itemBuilder: (_, i) {
              if (i == 0) {
                return chip(
                  context.l10n.tableNoReservationTable,
                  tableId == null,
                  () => onPick(activeZone, null),
                );
              }
              final t = free[i - 1];
              return chip(
                '${t.displayName} · ${t.capacity}p',
                tableId == t.id,
                () => onPick(t.zoneId, t.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _hhmm(DateTime d) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${pad(d.hour)}:${pad(d.minute)}';
}

String _fmtDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
