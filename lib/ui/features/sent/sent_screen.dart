import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

class SentScreen extends StatefulWidget {
  final String tableId;
  final List<String> stations;
  const SentScreen({super.key, required this.tableId, required this.stations});

  @override
  State<SentScreen> createState() => _SentScreenState();
}

class _SentScreenState extends State<SentScreen> with TickerProviderStateMixin {
  int _progress = 0;
  late final int _latency;

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
      if (mounted) context.go('/tables');
    });
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
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
                'Pesanan Meja ${widget.tableId} sudah live di display dapur dan bar.',
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
                  child: const Icon(Icons.check, size: 11, color: Color(0xFF0A0A0A)),
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
