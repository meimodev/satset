import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

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
/// printers, wrapping `print_bluetooth_thermal`. Device-scope only: the bond
/// lives on this one phone's radio. The shared [StrukRenderer] still produces
/// the bytes; only this transport differs from [StrukSocket]. See ADR-0022.
class BtPrinterService {
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
      return await PrintBluetoothThermal.bluetoothEnabled;
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
      final list = await PrintBluetoothThermal.pairedBluetooths;
      return BtPairedResult([
        for (final b in list) PairedBtPrinter(name: b.name, mac: b.macAdress),
      ], BtUnavailableReason.none);
    } catch (e) {
      SatLog.repo('bt paired $e');
      return const BtPairedResult([], BtUnavailableReason.none);
    }
  }

  /// Connect-only reachability probe for the heartbeat. Connects, then drops.
  Future<bool> probe(String mac) async {
    try {
      final ok = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (ok) await PrintBluetoothThermal.disconnect;
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Renders elsewhere; here we just connect, push bytes, disconnect. Throws
  /// on failure so the caller surfaces "printer tak terhubung".
  Future<void> send(String mac, List<int> bytes) async {
    final ok = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (!ok) throw StateError('bt connect failed');
    try {
      final wrote = await PrintBluetoothThermal.writeBytes(bytes);
      if (!wrote) throw StateError('bt write failed');
    } finally {
      try {
        await PrintBluetoothThermal.disconnect;
      } catch (_) {}
    }
  }
}

final btPrinterServiceProvider = Provider<BtPrinterService>(
  (_) => BtPrinterService(),
);
