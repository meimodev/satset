import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'guest_stepper.dart';

Future<void> showGuestStepperSheet({
  required BuildContext context,
  required String tableId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: context.sat.bg1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _GuestStepperSheet(tableId: tableId),
  );
}

class _GuestStepperSheet extends ConsumerWidget {
  final String tableId;
  const _GuestStepperSheet({required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final tables = ref.watch(tablesProvider);
    final table = tables.firstWhere(
      (t) => t.id == tableId,
      orElse: () => VenueTable(id: tableId, zoneId: ''),
    );
    final user = ref.watch(authStateProvider).user;
    final canEdit = user?.role == UserRole.waiter;
    final actorId = user?.id;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            Row(
              children: [
                Text(
                  'Meja ${table.id}',
                  style: SatType.mono(
                    size: 22,
                    weight: FontWeight.w600,
                    letterSpacing: -0.44,
                    color: sc.textHi,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Atur jumlah tamu',
                  style: SatType.sans(size: 13, color: sc.textMd),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: GuestStepper(
                pax: table.pax,
                max: table.capacity,
                enabled: canEdit,
                size: 48,
                onMinus: () => ref
                    .read(tablesProvider.notifier)
                    .decrementPax(table.id, userId: actorId),
                onPlus: () => ref
                    .read(tablesProvider.notifier)
                    .incrementPax(table.id, userId: actorId),
              ),
            ),
            const SizedBox(height: 14),
            if (!canEdit)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Hanya pelayan yang bisa mengubah jumlah tamu.',
                  textAlign: TextAlign.center,
                  style: SatType.mono(
                    size: 11,
                    color: sc.textLo,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: sc.textHi,
                  side: BorderSide(color: sc.border2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Tutup',
                  style: SatType.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: sc.textHi,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
