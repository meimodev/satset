import 'dart:io';

import 'package:bonsoir/bonsoir.dart';

/// Advertise the in-app server over mDNS so clients on the same LAN can
/// discover it. Service type: `_satset._tcp`.
///
/// TXT attributes:
///   - `fp`    SHA-256 fingerprint of the TLS cert (pinned by clients)
///   - `label` human-readable device name
///   - `ver`   app version string (informational)
///   - `vid`   cloud venue id this host serves (ADR-0017); a second device
///             entering Server mode for the same `vid` joins as a client
///             instead of starting a rival server. Empty for legacy boots.
class SatSetAdvertiser {
  BonsoirBroadcast? _broadcast;

  Future<void> start({
    required int port,
    required String fingerprint,
    String? label,
    String version = 'unknown',
    String venueId = '',
  }) async {
    final name = (label == null || label.isEmpty) ? _defaultName() : label;
    final service = BonsoirService(
      name: name,
      type: '_satset._tcp',
      port: port,
      attributes: {
        'fp': fingerprint,
        'label': name,
        'ver': version,
        'vid': venueId,
      },
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
  }

  Future<void> stop() async {
    await _broadcast?.stop();
    _broadcast = null;
  }

  static String _defaultName() {
    try {
      final h = Platform.localHostname.trim();
      // Android typically returns "localhost" here — useless as a label.
      if (h.isNotEmpty && h.toLowerCase() != 'localhost') {
        return 'satset @ $h';
      }
    } catch (_) {}
    return 'satset';
  }
}
