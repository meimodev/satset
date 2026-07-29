import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_stepper.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/models/zone.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

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
  return showSatSheet<AssignTableResult>(
    context,
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

    final targets =
        tables
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
          20,
          16,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
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
            const SizedBox(height: Sp.s4h),
            Text('Tetapkan ke meja', style: SatType.h2(color: sc.textHi)),
            const SizedBox(height: Sp.s1),
            Text(
              'Atur tamu lalu pilih meja kosong',
              style: SatType.monoS(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s4),
            Row(
              children: [
                Text('Tamu', style: SatType.bodyM(color: sc.textHi)),
                const Spacer(),
                SatStepper.pill(
                  value: _pax,
                  max: 20,
                  icon: Icons.person_outline,
                  showMax: true,
                  size: SatStepperSize.lg,
                  semanticLabel: 'Tamu',
                  onChanged: (v) => setState(() => _pax = v.clamp(0, 20)),
                ),
              ],
            ),
            const SizedBox(height: Sp.s3h),
            SatField.text(controller: _guestCtrl, hint: 'Nama tamu (opsional)'),
            const SizedBox(height: Sp.s4),
            Flexible(
              child: targets.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: Sp.s8),
                      child: Text(
                        'Tidak ada meja kosong.',
                        textAlign: TextAlign.center,
                        style: SatType.bodyM(color: sc.textLo),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final z in zones) ..._zoneSection(sc, z, targets),
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
          style: SatType.caption(color: sc.textLo),
        ),
      ),
      for (final t in inZone) _targetTile(sc, t),
    ];
  }

  Widget _targetTile(SatColors sc, VenueTable target) {
    final overCapacity = _pax > target.capacity;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s1h),
      child: Material(
        color: sc.bg2,
        borderRadius: SatR.a(12),
        child: InkWell(
          onTap: () {
            final name = _guestCtrl.text.trim();
            Navigator.of(context).pop(
              AssignTableResult(
                tableId: target.id,
                pax: _pax,
                guestName: name.isEmpty ? null : name,
              ),
            );
          },
          borderRadius: SatR.a(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.s3h,
              vertical: Sp.s3,
            ),
            decoration: SatBox.d(
              border: SatB.all(color: sc.border0),
              borderRadius: SatR.a(12),
            ),
            child: Row(
              children: [
                Text(
                  target.displayName,
                  style: SatType.monoL(color: sc.textHi),
                ),
                const SizedBox(width: Sp.s3),
                Text(
                  'kapasitas ${target.capacity}',
                  style: SatType.bodyS(color: sc.textMd),
                ),
                const Spacer(),
                if (overCapacity)
                  Padding(
                    padding: const EdgeInsets.only(right: Sp.s2),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: sc.warn,
                    ),
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
