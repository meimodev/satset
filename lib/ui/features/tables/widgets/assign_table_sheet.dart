import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/models/zone.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'guest_stepper.dart';

/// Result of the menu-first **Pesanan baru → assign to table** commit step.
class AssignTableResult {
  final String tableId;
  final int pax;
  final String? guestName;
  const AssignTableResult({
    required this.tableId,
    required this.pax,
    this.guestName,
  });
}

/// Table picker for committing a table-less draft order to a dine-in table.
/// Lists every empty (`available` + `active`) table grouped by zone; the
/// waiter sets pax / guest name once and taps a table to bind. Returns the
/// chosen [AssignTableResult], or null if dismissed. The caller then seats
/// the table and submits the draft cart (mirrors Pindah meja target rules).
Future<AssignTableResult?> showAssignTableSheet({
  required BuildContext context,
}) {
  return showModalBottomSheet<AssignTableResult>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.sat.bg1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AssignTableSheet(),
  );
}

class _AssignTableSheet extends ConsumerStatefulWidget {
  const _AssignTableSheet();

  @override
  ConsumerState<_AssignTableSheet> createState() => _AssignTableSheetState();
}

class _AssignTableSheetState extends ConsumerState<_AssignTableSheet> {
  int _pax = 2;
  final _guestCtrl = TextEditingController();

  @override
  void dispose() {
    _guestCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final tables = ref.watch(tablesProvider);
    final zones = ref.watch(zonesProvider);

    final targets = tables
        .where((t) => t.active && t.status == TableStatus.available)
        .toList()
      ..sort((a, b) {
        final za = zones.indexWhere((z) => z.id == a.zoneId);
        final zb = zones.indexWhere((z) => z.id == b.zoneId);
        if (za != zb) return za.compareTo(zb);
        return a.displayName.compareTo(b.displayName);
      });

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
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
            const SizedBox(height: 18),
            Text(
              'Tetapkan ke meja',
              style: SatType.sans(
                size: 20,
                weight: FontWeight.w600,
                letterSpacing: -0.4,
                color: sc.textHi,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Atur tamu lalu pilih meja kosong',
              style: SatType.mono(size: 11, color: sc.textLo, letterSpacing: 0.44),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Tamu',
                    style: SatType.sans(
                        size: 14, weight: FontWeight.w500, color: sc.textHi)),
                const Spacer(),
                GuestStepper(
                  pax: _pax,
                  max: 20,
                  enabled: true,
                  size: 40,
                  onMinus: () => setState(() => _pax = (_pax - 1).clamp(0, 20)),
                  onPlus: () => setState(() => _pax = (_pax + 1).clamp(0, 20)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _guestCtrl,
              style: SatType.sans(size: 14, color: sc.textHi),
              decoration: InputDecoration(
                hintText: 'Nama tamu (opsional)',
                hintStyle: SatType.sans(size: 14, color: sc.textLo),
                filled: true,
                fillColor: sc.bg2,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: sc.border0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: sc.border0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: targets.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Tidak ada meja kosong.',
                        textAlign: TextAlign.center,
                        style: SatType.sans(size: 13, color: sc.textLo),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final z in zones)
                          ..._zoneSection(sc, z, targets),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _zoneSection(SatColors sc, Zone zone, List<VenueTable> targets) {
    final inZone = targets.where((t) => t.zoneId == zone.id).toList();
    if (inZone.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
        child: Text(
          zone.name.toUpperCase(),
          style: SatType.mono(
            size: 10,
            weight: FontWeight.w600,
            letterSpacing: 1.2,
            color: sc.textLo,
          ),
        ),
      ),
      for (final t in inZone) _targetTile(sc, t),
    ];
  }

  Widget _targetTile(SatColors sc, VenueTable target) {
    final overCapacity = _pax > target.capacity;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: sc.bg2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            final name = _guestCtrl.text.trim();
            Navigator.of(context).pop(AssignTableResult(
              tableId: target.id,
              pax: _pax,
              guestName: name.isEmpty ? null : name,
            ));
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: sc.border0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  target.displayName,
                  style: SatType.mono(
                    size: 18,
                    weight: FontWeight.w600,
                    color: sc.textHi,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'kapasitas ${target.capacity}',
                  style: SatType.sans(size: 12, color: sc.textMd),
                ),
                const Spacer(),
                if (overCapacity)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 16, color: sc.warn),
                  ),
                Icon(Icons.chevron_right, size: 18, color: sc.textLo),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
