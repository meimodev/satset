/// The physical link to a printer. See CONTEXT.md "Printer transport".
enum PrinterTransport {
  /// Network ESC/POS (raw-9100 on the LAN). Address = host:port.
  wifi,

  /// Bluetooth Classic (RFCOMM/SPP). Address = a paired MAC.
  bluetooth;

  static PrinterTransport fromKey(String? k) => k == 'bt' || k == 'bluetooth'
      ? PrinterTransport.bluetooth
      : PrinterTransport.wifi;

  String get key => this == PrinterTransport.bluetooth ? 'bt' : 'wifi';
}

/// A printer registered to ONE device (not shared). Persisted locally in
/// SharedPreferences; this device renders + sends to it directly, never the
/// server. Contrast the venue [PrinterDto] which lives in the server DB and is
/// sent to by the Main Device. See ADR-0020 / ADR-0022.
///
/// Two transports: **wifi** (carries [host]/[port]) or **bluetooth** (carries
/// [mac]). Bluetooth is device-scope only — a BT printer is bonded to one
/// phone's radio, so the server can never reach it.
class DevicePrinter {
  final String id;
  final String label;
  final PrinterTransport transport;

  /// wifi only.
  final String? host;
  final int port;

  /// bluetooth only — the paired device MAC.
  final String? mac;

  const DevicePrinter({
    required this.id,
    required this.label,
    this.transport = PrinterTransport.wifi,
    this.host,
    this.port = 9100,
    this.mac,
  });

  bool get isBluetooth => transport == PrinterTransport.bluetooth;

  /// Stable identity used for dedup against discovered + registered printers:
  /// host:port for wifi, the MAC for bluetooth.
  String get address => isBluetooth ? (mac ?? '') : '${host ?? ''}:$port';

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'transport': transport.key,
    if (host != null) 'host': host,
    'port': port,
    if (mac != null) 'mac': mac,
  };

  /// Back-compat: entries saved before transport existed default to wifi.
  factory DevicePrinter.fromJson(Map<String, dynamic> j) => DevicePrinter(
    id: j['id'] as String,
    label: j['label'] as String,
    transport: PrinterTransport.fromKey(j['transport'] as String?),
    host: j['host'] as String?,
    port: (j['port'] as num?)?.toInt() ?? 9100,
    mac: j['mac'] as String?,
  );
}
