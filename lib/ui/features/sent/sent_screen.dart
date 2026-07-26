import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/printing/printer_picker.dart';

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
    return Scaffold(
      backgroundColor: sc.bg0,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sc.successSoft,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.check, size: 46, color: sc.success, weight: 800),
              ),
              const SizedBox(height: 24),
              Text('Terkirim',
                  style: SatType.sans(
                    size: 30,
                    weight: FontWeight.w600,
                    letterSpacing: -0.6,
                    color: sc.textHi,
                  )),
              const SizedBox(height: 8),
              Text(
                'Pesanan Meja $name sudah live di display dapur dan bar.',
                textAlign: TextAlign.center,
                style: SatType.sans(size: 14, color: sc.textMd),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < widget.stations.length; i++)
                    _StationChip(name: widget.stations[i], done: _progress > i),
                ],
              ),
              const SizedBox(height: 16),
              Text('LAN P50 ${_latency}MS · CLOUD QUEUED',
                  style: SatType.mono(
                    size: 10,
                    color: sc.textLo,
                    letterSpacing: 1.0,
                  )),
              if (table != null) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Cetak struk'),
                  onPressed: () {
                    setState(() => _engaged = true);
                    printTableStruk(
                      context: context,
                      ref: ref,
                      table: table,
                      tickets: ref.read(ticketsForTableProvider(widget.tableId)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: sc.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sc.border0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          done
              ? Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sc.success,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.check, size: 11, color: sc.successInk),
                )
              : SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: sc.accent,
                    backgroundColor: sc.border2,
                  ),
                ),
          const SizedBox(width: 8),
          Text(name,
              style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textHi)),
        ],
      ),
    );
  }
}
