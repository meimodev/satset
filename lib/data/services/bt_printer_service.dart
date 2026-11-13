import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:satset/core/log/sat_log.dart';

/// A Bluetooth printer the OS has already bonded with. We never air-scan for
/// unpaired devices (ADR-0022) — pairing happens once in Android settings.
class PairedBtPrinter {
  final String name;
  final String mac;
  const PairedBtPrinter({required this.name, required this.mac});
}

/// Why the Bluetooth section can't list anything — drives the picker affordance.
enum BtUnavailableReason { none, permission, adapterOff }

class BtPairedResult {
  final List<PairedBtPrinter> printers;
  final BtUnavailableReason reason;
  const BtPairedResult(this.printers, this.reason);
}

/// Bluetooth Classic (SPP) transport + paired-device enumeration for thermal
/// printers, over the app's own `satset/bt` channel (`BtPrinter.kt`), which
/// keeps every blocking socket call off the UI thread. Device-scope only: the
/// bond lives on this one phone's radio. The shared [StrukRenderer] still
/// produces the bytes; only this transport differs from [StrukSocket]. See
/// ADR-0022.
class BtPrinterService {
  static const _channel = MethodChannel('satset/bt');

  /// Requests BLUETOOTH_CONNECT lazily (Android 12+; resolves granted on ≤30).
  /// Returns true if usable.
  Future<bool> ensurePermission() async {
    try {
      final status = await Permission.bluetoothConnect.request();
      return status.isGranted;
    } catch (e) {
      SatLog.repo('bt permission $e');
      return false;
    }
  }

  Future<bool> adapterOn() async {
    try {
      return await _channel.invokeMethod<bool>('enabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Lists OS-paired printers, or the reason none can be shown.
  Future<BtPairedResult> pairedPrinters() async {
    if (!await ensurePermission()) {
      return const BtPairedResult([], BtUnavailableReason.permission);
    }
    if (!await adapterOn()) {
      return const BtPairedResult([], BtUnavailableReason.adapterOff);
    }
    try {
      final list = await _channel.invokeListMethod<Map>('paired') ?? const [];
      return BtPairedResult([
        for (final b in list)
          PairedBtPrinter(name: b['name'] as String, mac: b['mac'] as String),
      ], BtUnavailableReason.none);
    } catch (e) {
      SatLog.repo('bt paired $e');
      return const BtPairedResult([], BtUnavailableReason.none);
    }
  }

  /// Connect-only reachability probe for the heartbeat. Connects, then drops.
  Future<bool> probe(String mac) async {
    try {
      await _channel.invokeMethod<void>('probe', {'mac': mac});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Renders elsewhere; here we connect, push bytes and disconnect in one
  /// native call. Throws on failure so the caller surfaces "printer tak
  /// terhubung". The native side gives up after 30s rather than hanging.
  Future<void> send(String mac, List<int> bytes) => _channel.invokeMethod<void>(
    'send',
    {'mac': mac, 'bytes': Uint8List.fromList(bytes)},
  );
}

final btPrinterServiceProvider = Provider<BtPrinterService>(
  (_) => BtPrinterService(),
);
