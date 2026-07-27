import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/reservations_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/domain/models/reservation.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/motion.dart';

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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: sc.bg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: SatR.c(24)),
      ),
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
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: AppStrings.close,
    // Not `sc.scrim` — that token is an *opaque* base for translucent surfaces
    // to blend against, so using it here paints the floor out entirely. The
    // barrier dims, and it dims dark on every palette (neo.css §9 does the same
    // on both its light and dark skins).
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => Align(
      alignment: Alignment.centerRight,
      child: Material(
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
    ),
    transitionBuilder: (ctx, anim, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: satEaseOut)),
      child: child,
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
                      SatShape.caps(AppStrings.floorReservationsBook),
                      style: SatType.display(
                        size: 22,
                        weight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: sc.textHi,
                      ),
                    ),
                    const SizedBox(height: Sp.s1),
                    Text(
                      '${today.length} booking · $covers tamu',
                      style: SatType.mono(
                        size: 11,
                        color: sc.textLo,
                        letterSpacing: 0.66,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
                tooltip: AppStrings.close,
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
                _FilterChip(
                  label: switch (f) {
                    _RvFilter.waiting => AppStrings.reservationFilterWaiting,
                    _RvFilter.late => AppStrings.reservationFilterLate,
                    _RvFilter.seated => AppStrings.reservationFilterSeated,
                    _RvFilter.noShow => AppStrings.reservationFilterNoShow,
                    _RvFilter.all => AppStrings.reservationFilterAll,
                  },
                  count: pick(f).length,
                  active: _filter == f,
                  onTap: () => setState(() => _filter = f),
                ),
                if (f != _RvFilter.values.last) const SizedBox(width: Sp.s1h),
              ],
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Sp.s6),
                    child: Text(
                      AppStrings.reservationEmptyFilter,
                      textAlign: TextAlign.center,
                      style: SatType.sans(size: 13, color: sc.textMd),
                    ),
                  ),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SatButton.primary(
            label: 'Reservasi baru',
            icon: Icons.add,
            onTap: () => openCreateReservationSheet(context, ref),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final brutal = SatShape.brutal;
    // Brutal fills the selected chip with the accent; lembut inverts to textHi.
    final fill = active ? (brutal ? sc.accent : sc.textHi) : sc.bg2;
    final fg = active ? (brutal ? sc.accentInk : sc.bg0) : sc.textMd;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Tight: five of these have to fit the drawer's 480px without the last
        // one hanging half off the edge.
        padding: const EdgeInsets.symmetric(horizontal: Sp.s2h, vertical: 9),
        decoration: SatBox.d(
          color: fill,
          borderRadius: SatR.a(999),
          border: SatB.all(color: active && !brutal ? sc.textHi : sc.border0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              SatShape.caps(label),
              style: SatType.sans(
                size: 11.5,
                weight: brutal ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: SatType.mono(
                size: 11,
                color: active ? fg : sc.textLo,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
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

    final (statusLabel, statusTone) = late
        ? (AppStrings.reservationLate, sc.urgent)
        : switch (r.status) {
            ReservationStatus.pending => (
              reservationStatusLabel(r.status),
              sc.info,
            ),
            ReservationStatus.seated => (
              reservationStatusLabel(r.status),
              sc.success,
            ),
            _ => (reservationStatusLabel(r.status), sc.textLo),
          };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: SatBox.d(
        color: sc.bg2,
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
                          ? SatType.mono(
                              size: 15,
                              weight: FontWeight.w600,
                              color: sc.textHi,
                            )
                          : SatType.display(
                              size: 16,
                              weight: FontWeight.w800,
                              color: sc.textHi,
                            ),
                    ),
                    const SizedBox(height: Sp.sHair),
                    Text(
                      _relative(r, late),
                      style: SatType.mono(
                        size: 10,
                        color: late ? sc.urgent : sc.textLo,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Sp.s2h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: SatType.sans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: sc.textHi,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        '${r.partySize} tamu',
                        if (tableLabel != null)
                          'Meja $tableLabel'
                        else
                          AppStrings.tableNoReservationTable,
                        if (r.phone != null && r.phone!.trim().isNotEmpty)
                          r.phone!.trim(),
                      ].join(' · '),
                      style: SatType.mono(
                        size: 10,
                        color: sc.textLo,
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (r.notes != null && r.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: Sp.s1),
                      Text(
                        r.notes!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SatType.sans(size: 12, color: sc.textMd),
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
                  child: SatButton.outline(
                    label: AppStrings.reservationActionNoShow,
                    onTap: () async {
                      await n.updateStatus(r.id, ReservationStatus.noShow);
                    },
                  ),
                ),
                const SizedBox(width: Sp.s2),
                Expanded(
                  child: SatButton.outline(
                    label: AppStrings.cancel,
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
              label: AppStrings.reservationActionRestore,
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

class _Tag extends StatelessWidget {
  final String label;
  final Color tone;
  const _Tag({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final brutal = SatShape.brutal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s1h, vertical: 3),
      decoration: BoxDecoration(
        color: brutal ? tone : tone.withValues(alpha: 0.15),
        borderRadius: SatR.a(6),
        border: brutal ? Border.all(color: SatShape.ink, width: 2) : null,
      ),
      child: Text(
        SatShape.caps(label),
        style: SatType.sans(
          size: 9,
          weight: brutal ? FontWeight.w800 : FontWeight.w700,
          letterSpacing: brutal ? 1.0 : 0.2,
          color: brutal ? onFill(tone) : tone,
        ),
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
          SatShape.caps('${AppStrings.reservationActionSeat} ke meja:'),
          style: SatType.mono(
            size: 10,
            weight: FontWeight.w600,
            letterSpacing: 1.0,
            color: sc.textLo,
          ),
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
                      style: SatType.sans(
                        size: 11,
                        weight: FontWeight.w600,
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
            'Tidak ada meja kapasitas ≥ ${r.partySize} di zona ini.',
            style: SatType.sans(size: 12, color: sc.textMd),
          )
        else
          SizedBox(
            height: 36,
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
                          style: SatType.mono(
                            size: 12,
                            weight: FontWeight.w600,
                            color: sc.textHi,
                          ),
                        ),
                        const SizedBox(width: Sp.s1h),
                        Icon(Icons.person_outline, size: 11, color: sc.textLo),
                        Text(
                          '${t.capacity}',
                          style: SatType.mono(size: 10, color: sc.textLo),
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
            ? 'Meja sudah diisi tamu lain'
            : 'Gagal duduk: ${e.code ?? e.statusCode}';
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text('Gagal duduk: $e')));
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

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: sc.bg1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: SatR.c(24)),
    ),
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
                    SatShape.caps('Reservasi baru'),
                    style: SatType.display(
                      size: 18,
                      weight: FontWeight.w700,
                      color: sc.textHi,
                    ),
                  ),
                  const SizedBox(height: Sp.s4),
                  TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(labelText: 'Nama tamu'),
                  ),
                  const SizedBox(height: Sp.s2h),
                  TextField(
                    controller: phoneCtl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'No. HP (opsional)',
                    ),
                  ),
                  const SizedBox(height: Sp.s2h),
                  Row(
                    children: [
                      Text(
                        'Jumlah tamu',
                        style: SatType.sans(size: 13, color: sc.textHi),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: AppStrings.a11yGuestDecrease,
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
                            style: SatType.sans(
                              size: 16,
                              weight: FontWeight.w600,
                              color: sc.textHi,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: AppStrings.a11yGuestIncrease,
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
                  TextField(
                    controller: notesCtl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                    ),
                  ),
                  const SizedBox(height: Sp.s4h),
                  SatButton.primary(
                    label: 'Simpan reservasi',
                    onTap: () async {
                      final name = nameCtl.text.trim();
                      if (name.isEmpty) return;
                      try {
                        await ref
                            .read(reservationsRepositoryProvider.notifier)
                            .create(
                              name: name,
                              phone: phoneCtl.text.trim().isEmpty
                                  ? null
                                  : phoneCtl.text.trim(),
                              partySize: party,
                              expectedAt: expected,
                              zoneId: zoneId,
                              tableId: tableId,
                              notes: notesCtl.text.trim().isEmpty
                                  ? null
                                  : notesCtl.text.trim(),
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Gagal simpan: $e')),
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

    Widget chip(String label, bool active, VoidCallback onTap) =>
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: 7),
            decoration: SatBox.d(
              color: active
                  ? (SatShape.lembut ? sc.textHi : sc.accent)
                  : sc.bg2,
              border: SatB.all(color: sc.border0),
              borderRadius: SatR.a(999),
            ),
            child: Text(
              SatShape.caps(label),
              style: SatType.sans(
                size: 11.5,
                weight: FontWeight.w600,
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
          SatShape.caps('Zona & meja (opsional)'),
          style: SatType.mono(
            size: 10,
            weight: FontWeight.w600,
            letterSpacing: 1.0,
            color: sc.textLo,
          ),
        ),
        const SizedBox(height: Sp.s2),
        if (zones.length > 1)
          SizedBox(
            height: 34,
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
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: free.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: Sp.s1h),
            itemBuilder: (_, i) {
              if (i == 0) {
                return chip(
                  AppStrings.tableNoReservationTable,
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
