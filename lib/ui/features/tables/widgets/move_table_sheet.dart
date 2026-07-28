import 'package:flutter/material.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/models/zone.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// Target picker for **Pindah meja** (move table, ADR-0019). Lists every empty
/// (`available` + `active`) table grouped by zone; tapping one transfers the
/// whole session from [sourceId] onto it. Returns the chosen target id on a
/// successful move, or null if the user dismissed without moving.
Future<String?> showMoveTableSheet({
  required BuildContext context,
  required String sourceId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.sat.bg1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: SatR.c(24)),
    ),
    builder: (_) => _MoveTableSheet(sourceId: sourceId),
  );
}

class _MoveTableSheet extends ConsumerStatefulWidget {
  final String sourceId;
  const _MoveTableSheet({required this.sourceId});

  @override
  ConsumerState<_MoveTableSheet> createState() => _MoveTableSheetState();
}

class _MoveTableSheetState extends ConsumerState<_MoveTableSheet> {
  bool _moving = false;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final tables = ref.watch(tablesProvider);
    final zones = ref.watch(zonesProvider);
    final source = tables.firstWhere(
      (t) => t.id == widget.sourceId,
      orElse: () => VenueTable(id: widget.sourceId, zoneId: ''),
    );

    final targets =
        tables
            .where(
              (t) =>
                  t.id != widget.sourceId &&
                  t.active &&
                  t.status == TableStatus.available,
            )
            .toList()
          ..sort((a, b) {
            final za = zones.indexWhere((z) => z.id == a.zoneId);
            final zb = zones.indexWhere((z) => z.id == b.zoneId);
            if (za != zb) return za.compareTo(zb);
            return a.displayName.compareTo(b.displayName);
          });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
            Text(
              'Pindahkan meja ${source.displayName}',
              style: SatType.h2(color: sc.textHi),
            ),
            const SizedBox(height: Sp.s1),
            Text(
              'Pilih meja kosong tujuan · ${source.pax} tamu',
              style: SatType.monoS(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s4),
            Flexible(
              child: targets.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: Sp.s8),
                      child: Text(
                        'Tidak ada meja kosong untuk dituju.',
                        textAlign: TextAlign.center,
                        style: SatType.bodyM(color: sc.textLo),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final z in zones)
                          ..._zoneSection(sc, z, targets, source),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _zoneSection(
    SatColors sc,
    Zone zone,
    List<VenueTable> targets,
    VenueTable source,
  ) {
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
      for (final t in inZone) _targetTile(sc, t, source),
    ];
  }

  Widget _targetTile(SatColors sc, VenueTable target, VenueTable source) {
    final overCapacity = source.pax > target.capacity;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s1h),
      child: Material(
        color: sc.bg2,
        borderRadius: SatR.a(12),
        child: InkWell(
          onTap: _moving ? null : () => _confirmAndMove(target, source),
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

  Future<void> _confirmAndMove(VenueTable target, VenueTable source) async {
    final sc = context.sat;
    final overCapacity = source.pax > target.capacity;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pindahkan meja ${source.displayName}?'),
        content: Text(
          overCapacity
              ? 'Tujuan: meja ${target.displayName} (kapasitas ${target.capacity}). '
                    '${source.pax} tamu melebihi kapasitas — lanjutkan?'
              : 'Seluruh pesanan dan tamu pindah ke meja ${target.displayName}.',
        ),
        actions: [
          SatButton.ghost(
            label: AppStrings.cancel,
            onTap: () => Navigator.of(ctx).pop(false),
          ),
          SatButton.primary(
            label: 'Pindahkan',
            onTap: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _moving = true);
    final user = ref.read(authStateProvider).user;
    try {
      await ref
          .read(tablesProvider.notifier)
          .moveTable(
            source.id,
            targetId: target.id,
            actorId: user?.id,
            actorName: user?.name,
          );
      if (mounted) Navigator.of(context).pop(target.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _moving = false);
      final msg = switch (e.code) {
        'target_unavailable' => 'Meja tujuan sudah terisi.',
        'table_locked' => 'Meja sedang dipakai pengguna lain.',
        'source_not_occupied' => 'Meja asal sudah kosong.',
        _ => 'Gagal memindahkan meja: ${e.code ?? e.statusCode}',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: SatType.bodyM(color: sc.textHi)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _moving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memindahkan meja: $e')));
    }
  }
}
