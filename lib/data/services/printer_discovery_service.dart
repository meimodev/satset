import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';

/// A network printer found on the LAN via mDNS.
class DiscoveredPrinter {
  final String name;
  final String host;
  final int port;
  const DiscoveredPrinter({
    required this.name,
    required this.host,
    required this.port,
  });

  String get key => '$host:$port';
}

/// One-shot mDNS browse for raw-9100 ESC/POS printers. Runs client-side from
/// the print picker; the chosen printer is then written to the server DB (venue
/// scope) or device prefs (device scope). Both Main Device and client share the
/// LAN, so a client-discovered IP is reachable by the server. See ADR-0020.
class PrinterDiscoveryService {
  /// Standard service types thermal/JetDirect printers advertise.
  static const _types = ['_pdl-datastream._tcp', '_printer._tcp'];

  /// One-shot batch browse (kept for callers that want the full set at once).
  Future<List<DiscoveredPrinter>> discover({
    Duration window = const Duration(seconds: 4),
  }) async {
    final found = <String, DiscoveredPrinter>{};
    await for (final p in stream(window: window)) {
      found[p.key] = p;
    }
    return found.values.toList(growable: false);
  }

  /// Streaming browse: emits each newly-resolved printer as mDNS resolves it
  /// (deduped by host:port), then closes when [window] elapses. The picker
  /// watches this so rows pop in instead of freezing for the whole window.
  /// See ADR-0022.
  Stream<DiscoveredPrinter> stream({
    Duration window = const Duration(seconds: 4),
  }) {
    final controller = StreamController<DiscoveredPrinter>();
    final seen = <String>{};
    final discoveries = <BonsoirDiscovery>[];
    final subs = <StreamSubscription<BonsoirDiscoveryEvent>>[];
    Timer? closer;

    Future<void> teardown() async {
      closer?.cancel();
      for (final s in subs) {
        await s.cancel();
      }
      for (final d in discoveries) {
        try {
          await d.stop();
        } catch (_) {}
      }
      if (!controller.isClosed) await controller.close();
    }

    Future<void> begin() async {
      try {
        for (final type in _types) {
          final d = BonsoirDiscovery(type: type);
          await d.initialize();
          discoveries.add(d);
          final sub = d.eventStream?.listen(
            (ev) {
              // bonsoir 7: an event is a sealed class, and a resolved service
              // carries `hostAddresses` (a list) instead of one nullable
              // `host`. A printer that answers on several addresses is fine —
              // take the first non-empty one and let dedup by host:port sort
              // out the rest.
              switch (ev) {
                case BonsoirDiscoveryServiceFoundEvent():
                  unawaited(ev.service.resolve(d.serviceResolver));
                case BonsoirDiscoveryServiceResolvedEvent():
                  final svc = ev.service;
                  final host = svc.hostAddresses.firstWhere(
                    (a) => a.isNotEmpty,
                    orElse: () => '',
                  );
                  if (host.isEmpty) return;
                  final port = svc.port == 0 ? 9100 : svc.port;
                  final p = DiscoveredPrinter(
                    name: svc.name.trim().isEmpty ? host : svc.name.trim(),
                    host: host,
                    port: port,
                  );
                  if (seen.add(p.key) && !controller.isClosed) {
                    controller.add(p);
                  }
                default:
                  break;
              }
            },
            onError: (Object e, StackTrace st) {
              SatLog.err('printer discovery stream', e, st);
            },
          );
          if (sub != null) subs.add(sub);
          await d.start();
        }
        closer = Timer(window, teardown);
      } catch (e, st) {
        SatLog.err('printer discovery', e, st);
        await teardown();
      }
    }

    controller.onListen = begin;
    controller.onCancel = teardown;
    return controller.stream;
  }
}

final printerDiscoveryServiceProvider = Provider<PrinterDiscoveryService>(
  (_) => PrinterDiscoveryService(),
);
