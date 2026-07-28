import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/data/models/pair_dto.dart';
import 'package:satset/ui/features/onboarding/view_models/pair_view_model.dart';
import 'package:satset/ui/core/design/spacing.dart';

class PairScreen extends ConsumerStatefulWidget {
  const PairScreen({super.key});

  @override
  ConsumerState<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends ConsumerState<PairScreen> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '7443');
  final _token = TextEditingController();
  final _fp = TextEditingController();

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _token.dispose();
    _fp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(pairViewModelProvider);
    final vm = ref.read(pairViewModelProvider.notifier);

    if (s.paired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/pin');
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pairing')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Sp.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Scan QR dari server tablet, atau isi manual jika multicast diblokir di WiFi:',
              ),
              const SizedBox(height: Sp.s4),
              SatField.text(controller: _host, label: 'Host (IP)', hint: ''),
              SatField.number(controller: _port, label: 'Port', hint: ''),
              SatField.text(
                controller: _token,
                label: 'Pair token',
                hint: 'sekali pakai',
              ),
              SatField.text(
                controller: _fp,
                label: 'Cert fingerprint (SHA-256)',
                hint: '',
              ),
              const SizedBox(height: Sp.s4),
              SatButton.primary(
                label: s.busy ? 'Memasangkan…' : 'Pasangkan',
                busy: s.busy,
                onTap: () {
                  final qr = PairQrPayloadDto(
                    host: _host.text.trim(),
                    port: int.tryParse(_port.text.trim()) ?? 7443,
                    fingerprint: _fp.text.trim(),
                    token: _token.text.trim(),
                  );
                  vm.claim(jsonEncode(qr.toJson()));
                },
              ),
              if (s.error != null) ...[
                const SizedBox(height: Sp.s3),
                Text(
                  s.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
