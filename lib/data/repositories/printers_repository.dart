import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/printer_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';

final printersStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

class PrintersRepository extends StateNotifier<List<PrinterDto>> {
  PrintersRepository({required this.ref}) : super(const <PrinterDto>[]) {
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(printersStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
      return;
    }
    ref.read(printersStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      final raw =
          await ref.read(apiClientProvider).getJson('/printers') as List;
      state = [
        for (final e in raw)
          PrinterDto.fromJson((e as Map).cast<String, dynamic>()),
      ];
      ref.read(printersStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
    } catch (e, st) {
      ref.read(printersStatusProvider.notifier).state = AsyncValue.error(e, st);
    }
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type == WsEventTypes.printerCreated ||
          ev.type == WsEventTypes.printerUpdated) {
        final p = PrinterDto.fromJson(ev.payload);
        final exists = state.any((x) => x.id == p.id);
        state = exists
            ? [
                for (final x in state)
                  if (x.id == p.id) p else x,
              ]
            : [...state, p];
      } else if (ev.type == WsEventTypes.printerDeleted) {
        final id = ev.payload['id'] as String?;
        if (id == null) return;
        state = state.where((x) => x.id != id).toList();
      }
    });
  }

  Future<PrinterDto?> create({
    required String label,
    required String host,
    int port = 9100,
    String kind = 'escpos',
  }) async {
    try {
      final raw = await ref.read(apiClientProvider).postJson('/printers', {
        'label': label,
        'host': host,
        'port': port,
        'kind': kind,
      });
      final p = PrinterDto.fromJson((raw as Map).cast<String, dynamic>());
      return p;
    } catch (e) {
      SatLog.repo('printers.create fail $e');
      return null;
    }
  }

  Future<void> update(
    String id, {
    String? label,
    String? host,
    int? port,
    bool? enabled,
  }) async {
    try {
      await ref.read(apiClientProvider).patchJson('/printers/$id', {
        'label': ?label,
        'host': ?host,
        'port': ?port,
        'enabled': ?enabled,
      });
    } catch (e) {
      SatLog.repo('printers.update fail $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await ref.read(apiClientProvider).deleteJson('/printers/$id');
    } catch (e) {
      SatLog.repo('printers.delete fail $e');
    }
  }

  /// Fires a real test slip on a VENUE printer. Returns null on success or a
  /// human message on failure.
  Future<String?> testPrint(String id) async {
    try {
      await ref
          .read(apiClientProvider)
          .postJson('/printers/$id/test', const <String, dynamic>{});
      return null;
    } on ApiException catch (e) {
      SatLog.repo('printers.test fail $e');
      return _friendly(e);
    } catch (e) {
      SatLog.repo('printers.test fail $e');
      return 'Gagal mencetak';
    }
  }

  /// Prints a table's struk to a VENUE printer (server renders + sends).
  /// Returns null on success or a human message on failure.
  Future<String?> printTable(String tableId, String printerId) async {
    try {
      await ref.read(apiClientProvider).postJson('/tables/$tableId/print', {
        'printerId': printerId,
      });
      return null;
    } on ApiException catch (e) {
      SatLog.repo('printers.printTable fail $e');
      return _friendly(e);
    } catch (e) {
      SatLog.repo('printers.printTable fail $e');
      return 'Gagal mencetak';
    }
  }

  String _friendly(ApiException e) {
    try {
      final j = jsonDecode(e.body);
      if (j is Map && j['message'] is String) return j['message'] as String;
    } catch (_) {}
    return switch (e.code) {
      'no_lines' => 'Tidak ada pesanan untuk dicetak',
      'print_failed' => 'Printer tak terhubung',
      _ => 'Gagal mencetak',
    };
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}

final printersRepositoryProvider =
    StateNotifierProvider<PrintersRepository, List<PrinterDto>>(
      (ref) => PrintersRepository(ref: ref),
    );
