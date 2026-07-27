import 'dart:math';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/tables_repository.dart';
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
  int _progress = 0;
  late final int _latency;
  // Set once the waiter taps "Cetak struk" so the auto-return doesn't yank the
  // screen out from under the printer picker.
  bool _engaged = false;

  @override
  void initState() {
    super.initState();
    _latency = 120 + Random().nextInt(180);
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _progress = 1);
    });
    Future.delayed(const Duration(milliseconds: 620), () {
      if (mounted) setState(() => _progress = 2);
    });
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
              Text('Terkirim', style: SatType.h1(color: ink)),
              const SizedBox(height: Sp.s2),
              Text(
                'Pesanan Meja $name sudah live di display dapur dan bar.',
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
                  for (var i = 0; i < widget.stations.length; i++)
                    _StationChip(name: widget.stations[i], done: _progress > i),
                ],
              ),
              const SizedBox(height: Sp.s4),
              Text(
                'LAN P50 ${_latency}MS · CLOUD QUEUED',
                style: SatType.monoS(
                  color: glow ? ink.withValues(alpha: 0.55) : sc.textLo,
                ),
              ),
              if (table != null) ...[
                const SizedBox(height: Sp.s6),
                SatButton.outline(
                  icon: Icons.receipt_long_rounded,
                  label: 'Cetak struk',
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
  final bool done;
  const _StationChip({required this.name, required this.done});

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
          done
              ? Container(
                  width: 18,
                  height: 18,
                  decoration: SatBox.d(
                    shape: BoxShape.circle,
                    color: sc.success,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.check, size: 11, color: sc.successInk),
                )
              : SizedBox(
                  width: Sp.s4h,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: sc.accentText,
                    backgroundColor: sc.border2,
                  ),
                ),
          const SizedBox(width: Sp.s2),
          Text(name, style: SatType.bodyM(color: sc.textHi)),
        ],
      ),
    );
  }
}
