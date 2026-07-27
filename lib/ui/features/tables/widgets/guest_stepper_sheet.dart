import 'package:flutter/material.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'guest_stepper.dart';
import 'move_table_sheet.dart';
import 'package:satset/ui/core/design/spacing.dart';

Future<void> showGuestStepperSheet({
  required BuildContext context,
  required String tableId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: context.sat.bg1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: SatR.c(24)),
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
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    final canEdit = user?.role == UserRole.waiter;
    final canMove =
        table.status != TableStatus.available && auth.has(Capability.takeOrder);
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
                decoration: SatBox.d(
                  color: sc.border1,
                  borderRadius: SatR.a(2),
                ),
              ),
            ),
            const SizedBox(height: Sp.s4h),
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
                const SizedBox(width: Sp.s2h),
                Text(
                  'Atur jumlah tamu',
                  style: SatType.sans(size: 13, color: sc.textMd),
                ),
              ],
            ),
            const SizedBox(height: Sp.s4),
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
            const SizedBox(height: Sp.s3h),
            if (!canEdit)
              Padding(
                padding: const EdgeInsets.only(top: Sp.s1),
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
            const SizedBox(height: Sp.s4h),
            if (canMove) ...[
              SizedBox(
                height: Sp.s12,
                child: SatButton.primary(
                  label: 'Pindahkan meja',
                  icon: Icons.swap_horiz_rounded,
                  onTap: () async {
                    final targetId = await showMoveTableSheet(
                      context: context,
                      sourceId: table.id,
                    );
                    if (targetId == null || !context.mounted) return;
                    Navigator.of(context).pop(); // close this stepper sheet
                    context.push('/table/$targetId');
                  },
                ),
              ),
              const SizedBox(height: Sp.s2h),
            ],
            SizedBox(
              height: Sp.s12,
              child: SatButton.outline(
                label: AppStrings.close,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
