import 'package:satset/core/localization/report_copy.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/printing/printer_picker.dart';
import 'package:satset/ui/core/design/spacing.dart';

class SentScreen extends ConsumerStatefulWidget {
  final String tableId;
  final List<String> stations;
  const SentScreen({super.key, required this.tableId, required this.stations});

  @override
  ConsumerState<SentScreen> createState() => _SentScreenState();
}

class _SentScreenState extends ConsumerState<SentScreen>
    with TickerProviderStateMixin {
  // Set once the waiter taps "Cetak struk" so the auto-return doesn't yank the
  // screen out from under the printer picker.
  bool _engaged = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted || _engaged) return;
      // Pop back to the original table detail (sent → review → menu → detail)
      // instead of go(), so the still-mounted detail keeps its lock rather
      // than disposing and re-acquiring. Router ref is captured because this
      // screen's context unmounts after the first pop.
      final router = GoRouter.of(context);
      for (var i = 0; i < 3 && router.canPop(); i++) {
        router.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final tables = ref.watch(tablesProvider);
    final table = tables.where((x) => x.id == widget.tableId).firstOrNull;
    final name = table?.displayName ?? widget.tableId;
    // Glow's send confirmation is a full-bleed lime slab — the design's rule 1
    // is slab stacking, and this is the one screen that is nothing but its own
    // confirmation. Ink goes obsidian against it. The other skins keep the
    // page ground and let the green check carry the message.
    final glow = SatShape.glow;
    final ink = glow ? sc.accentInk : sc.textHi;
    return Scaffold(
      backgroundColor: glow ? sc.accent : sc.bg0,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: SatBox.d(
                  shape: BoxShape.circle,
                  color: glow ? sc.accentInk : sc.successSoft,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.check,
                  size: 46,
                  color: glow ? sc.accent : sc.success,
                  weight: 800,
                ),
              ),
              const SizedBox(height: Sp.s6),
              Text(context.l10n.sntTitle, style: SatType.h1(color: ink)),
              const SizedBox(height: Sp.s2),
              Text(
                // There is no display to be live on when the venue has no prep
                // queue (ADR-0115) — the line is already waiting to be run.
                ref.watch(venueSettingsProvider).bypassKds
                    ? context.l10n.sntBodyNoPrep(name)
                    : context.l10n.sntBody(name),
                textAlign: TextAlign.center,
                style: SatType.bodyM(
                  color: glow ? ink.withValues(alpha: 0.7) : sc.textMd,
                ),
              ),
              const SizedBox(height: Sp.s6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  // Every station on this list already has the order: the
                  // POST returned 200 before this screen was pushed. The
                  // chips report that, and nothing else — they used to tick
                  // over on timers, which staged a delivery that had already
                  // happened and invented a latency figure to go with it.
                  // A station chip says the line reached a display. With no
                  // prep queue there is none to reach (ADR-0115).
                  if (!ref.watch(venueSettingsProvider).bypassKds)
                    for (final station in widget.stations)
                      _StationChip(name: station),
                ],
              ),
              if (table != null) ...[
                const SizedBox(height: Sp.s6),
                SatButton.outline(
                  icon: Icons.receipt_long_rounded,
                  label: context.l10n.cshPrintReceipt,
                  onTap: () {
                    setState(() => _engaged = true);
                    printTableStruk(
                      context: context,
                      ref: ref,
                      table: table,
                      tickets: ref.read(
                        ticketsForTableProvider(widget.tableId),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StationChip extends StatelessWidget {
  final String name;
  const _StationChip({required this.name});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3h, vertical: Sp.s2h),
      decoration: SatBox.d(
        color: sc.bg2,
        borderRadius: SatR.a(14),
        border: SatB.all(color: sc.border0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: SatBox.d(shape: BoxShape.circle, color: sc.success),
            alignment: Alignment.center,
            child: Icon(Icons.check, size: 11, color: sc.successInk),
          ),
          const SizedBox(width: Sp.s2),
          Text(
            stationLabel(context.l10n, name),
            style: SatType.bodyM(color: sc.textHi),
          ),
        ],
      ),
    );
  }
}
