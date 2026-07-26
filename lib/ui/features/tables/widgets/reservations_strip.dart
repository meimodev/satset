import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/reservations_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/domain/models/reservation.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

/// Horizontal strip of today's reservations rendered above the zone tabs in
/// `TablesScreen`. Tap a chip → action sheet (seat / no-show / cancel /
/// delete). `+ Reservasi` pill on the right opens a create form.
class ReservationsStrip extends ConsumerWidget {
  final bool tablet;
  const ReservationsStrip({super.key, required this.tablet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final all = ref.watch(reservationsRepositoryProvider);
    final today = _todayWindow();
    final shown = all
        .where((r) =>
            r.expectedAt.isAfter(today.$1.subtract(const Duration(minutes: 1))) &&
            r.expectedAt.isBefore(today.$2) &&
            r.status != ReservationStatus.cancelled &&
            r.status != ReservationStatus.noShow)
        .toList();
    final pendingCount =
        shown.where((r) => r.status == ReservationStatus.pending).length;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: tablet ? 32 : 16, vertical: tablet ? 12 : 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: sc.border0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.event_available, size: 14, color: sc.textLo),
              const SizedBox(width: 6),
              Text(
                'RESERVASI HARI INI',
                style: SatType.mono(
                  size: 10,
                  weight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: sc.textLo,
                ),
              ),
              const SizedBox(width: 8),
              if (pendingCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: sc.warn.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('$pendingCount menunggu',
                      style: SatType.mono(
                          size: 9,
                          weight: FontWeight.w600,
                          color: sc.warn,
                          letterSpacing: 0.6)),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => _openCreateSheet(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sc.accentSoft,
                    border: Border.all(color: sc.accentBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: sc.accent),
                      const SizedBox(width: 4),
                      Text('Reservasi',
                          style: SatType.sans(
                              size: 11,
                              weight: FontWeight.w600,
                              color: sc.accent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('Belum ada reservasi hari ini.',
                  style: SatType.sans(size: 12, color: sc.textMd)),
            )
          else
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: shown.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (c, i) => _ReservationChip(
                  reservation: shown[i],
                  onTap: () => _openActionSheet(context, ref, shown[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  (DateTime, DateTime) _todayWindow() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (start, end);
  }

  Future<void> _openCreateSheet(BuildContext context, WidgetRef ref) async {
    final sc = context.sat;
    final nameCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final notesCtl = TextEditingController();
    var party = 2;
    final now = DateTime.now();
    var expected = DateTime(now.year, now.month, now.day, 19, 0);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: sc.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
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
                    decoration: BoxDecoration(
                      color: sc.border1,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Reservasi baru',
                    style: SatType.sans(
                        size: 18,
                        weight: FontWeight.w600,
                        color: sc.textHi)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Nama tamu'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtl,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'No. HP (opsional)'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Jumlah tamu', style: SatType.sans(size: 13, color: sc.textHi)),
                    const Spacer(),
                    IconButton(
                      onPressed: party > 1 ? () => setLocal(() => party--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(
                      width: 32,
                      child: Center(
                        child: Text('$party',
                            style: SatType.sans(
                                size: 16, weight: FontWeight.w600, color: sc.textHi)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setLocal(() => party++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_fmtDate(expected)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: expected,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 2),
                          );
                          if (picked != null) {
                            setLocal(() => expected = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                expected.hour,
                                expected.minute));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text(_fmtTime(expected)),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay(
                                hour: expected.hour, minute: expected.minute),
                          );
                          if (picked != null) {
                            setLocal(() => expected = DateTime(
                                expected.year,
                                expected.month,
                                expected.day,
                                picked.hour,
                                picked.minute));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Catatan (opsional)'),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () async {
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
                  child: const Text('Simpan reservasi'),
                ),
              ],
            ),
            ),
          );
        });
      },
    );
  }

  Future<void> _openActionSheet(
      BuildContext context, WidgetRef ref, Reservation r) async {
    final sc = context.sat;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: sc.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sc.border1,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(r.name,
                    style: SatType.sans(
                        size: 20,
                        weight: FontWeight.w600,
                        color: sc.textHi)),
                const SizedBox(height: 2),
                Text(
                    '${_fmtTime(r.expectedAt)} · ${r.partySize} tamu · ${reservationStatusLabel(r.status)}',
                    style: SatType.sans(size: 12, color: sc.textMd)),
                if (r.phone != null && r.phone!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 14, color: sc.textLo),
                      const SizedBox(width: 6),
                      Text(r.phone!,
                          style: SatType.mono(
                              size: 12, color: sc.textMd, letterSpacing: 0.2)),
                    ],
                  ),
                ],
                if (r.notes != null && r.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: sc.bg2,
                      border: Border.all(color: sc.border0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sticky_note_2_outlined,
                            size: 14, color: sc.textLo),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(r.notes!,
                              style: SatType.sans(
                                  size: 13, color: sc.textMd, height: 1.3)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (r.status == ReservationStatus.pending) ...[
                  _SeatPicker(reservation: r),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await ref
                                .read(reservationsRepositoryProvider.notifier)
                                .updateStatus(r.id, ReservationStatus.noShow);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                          child: const Text('No-show'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await ref
                                .read(reservationsRepositoryProvider.notifier)
                                .updateStatus(
                                    r.id, ReservationStatus.cancelled);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                          child: const Text('Batal'),
                        ),
                      ),
                    ],
                  ),
                ] else if (r.status == ReservationStatus.seated) ...[
                  Text('Tamu sudah duduk.',
                      style: SatType.sans(size: 13, color: sc.textMd)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(reservationsRepositoryProvider.notifier)
                          .updateStatus(r.id, ReservationStatus.cancelled);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: const Text('Batalkan reservasi'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Hapus'),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(reservationsRepositoryProvider.notifier)
                                  .delete(r.id);
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Gagal hapus: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReservationChip extends ConsumerWidget {
  final Reservation reservation;
  final VoidCallback onTap;
  const _ReservationChip({required this.reservation, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final isSeated = reservation.status == ReservationStatus.seated;
    final tableLabel = reservation.tableId == null
        ? null
        : ref
            .watch(tablesProvider)
            .where((t) => t.id == reservation.tableId)
            .map((t) => t.displayName)
            .firstOrNull ??
            reservation.tableId!;
    // "Terlambat" is a **derived display state**, never a stored status
    // (ADR-0044): a clock must not decide a no-show, and auto-flipping would
    // force `seated` to be reachable from `noShow` for the party that turns
    // up at +46m. Only pending reservations can read as late.
    final graceMins = ref.watch(venueSettingsProvider).reservationGraceMins;
    final isLate = reservation.status == ReservationStatus.pending &&
        DateTime.now().difference(reservation.expectedAt) >
            Duration(minutes: graceMins);
    final bg = isSeated
        ? sc.success.withValues(alpha: 0.1)
        : isLate
            ? sc.warn.withValues(alpha: 0.1)
            : sc.bg2;
    final border = isSeated
        ? sc.success.withValues(alpha: 0.4)
        : isLate
            ? sc.warn.withValues(alpha: 0.45)
            : sc.border1;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_fmtTime(reservation.expectedAt),
                    style: SatType.mono(
                        size: 11,
                        weight: FontWeight.w600,
                        color: isSeated
                            ? sc.success
                            : isLate
                                ? sc.warn
                                : sc.textHi,
                        letterSpacing: 0.4)),
                if (isLate) ...[
                  const SizedBox(width: 5),
                  Text(AppStrings.reservationLate,
                      style: SatType.sans(
                          size: 10,
                          weight: FontWeight.w600,
                          color: sc.warn)),
                ],
                const SizedBox(width: 6),
                Icon(Icons.person, size: 10, color: sc.textLo),
                Text('${reservation.partySize}',
                    style: SatType.mono(size: 10, color: sc.textMd)),
                if (tableLabel != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: sc.bg3,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(tableLabel,
                        style: SatType.mono(
                            size: 9,
                            weight: FontWeight.w600,
                            color: sc.textMd)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(reservation.name,
                style: SatType.sans(
                    size: 12, weight: FontWeight.w500, color: sc.textHi)),
          ],
        ),
      ),
    );
  }
}

class _SeatPicker extends ConsumerStatefulWidget {
  final Reservation reservation;
  const _SeatPicker({required this.reservation});

  @override
  ConsumerState<_SeatPicker> createState() => _SeatPickerState();
}

class _SeatPickerState extends ConsumerState<_SeatPicker> {
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
        .where((t) =>
            t.status == TableStatus.available &&
            t.capacity >= r.partySize &&
            (activeZoneId == null || t.zoneId == activeZoneId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih zona:',
            style: SatType.mono(
                size: 10,
                weight: FontWeight.w600,
                letterSpacing: 1.0,
                color: sc.textLo)),
        const SizedBox(height: 8),
        if (zones.isEmpty)
          Text('Belum ada zona.',
              style: SatType.sans(size: 12, color: sc.textMd))
        else
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: zones.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final z = zones[i];
                final isActive = z.id == activeZoneId;
                return GestureDetector(
                  onTap: () => setState(() => _zoneId = z.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? sc.textHi : sc.bg2,
                      border: Border.all(
                          color: isActive ? sc.textHi : sc.border1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(z.name,
                        style: SatType.sans(
                            size: 12,
                            weight: FontWeight.w500,
                            color: isActive ? sc.bg0 : sc.textMd)),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Text('Dudukkan ke meja:',
            style: SatType.mono(
                size: 10,
                weight: FontWeight.w600,
                letterSpacing: 1.0,
                color: sc.textLo)),
        const SizedBox(height: 8),
        if (available.isEmpty)
          Text(
              'Tidak ada meja kapasitas ≥ ${r.partySize} di zona ini.',
              style: SatType.sans(size: 12, color: sc.textMd))
        else
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: available.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final t = available[i];
                return GestureDetector(
                  onTap: () => _seat(context, t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sc.bg2,
                      border: Border.all(color: sc.border1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.displayName,
                            style: SatType.mono(
                                size: 12,
                                weight: FontWeight.w600,
                                color: sc.textHi)),
                        const SizedBox(width: 6),
                        Icon(Icons.person_outline,
                            size: 11, color: sc.textLo),
                        Text('${t.capacity}',
                            style: SatType.mono(
                                size: 10, color: sc.textLo)),
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
      await ref.read(tablesProvider.notifier).seat(
            t.id,
            pax: r.partySize,
            guestName: r.name,
            guestNotes: r.notes,
            reservationId: r.id,
            userId: user?.id,
            userName: user?.name,
            // Atomically claim the lock so a second device opening the same
            // table after the WS broadcast can't snatch it before the
            // reservation waiter navigates over.
            acquireLock: true,
          );
      await ref
          .read(reservationsRepositoryProvider.notifier)
          .assignTable(r.id, zoneId: t.zoneId, tableId: t.id);
      await ref
          .read(reservationsRepositoryProvider.notifier)
          .updateStatus(r.id, ReservationStatus.seated);
      if (ctx.mounted) Navigator.of(ctx).pop();
    } on ApiException catch (e) {
      if (ctx.mounted) {
        final msg = e.code == 'already_seated'
            ? 'Meja sudah diisi tamu lain'
            : 'Gagal duduk: ${e.code ?? e.statusCode}';
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Gagal duduk: $e')),
        );
      }
    }
  }
}

String _fmtTime(DateTime d) {
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
    'Des'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
