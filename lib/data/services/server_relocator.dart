import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/mdns_browser_service.dart';
import 'package:satset/data/services/prefs_service.dart';

/// Re-find a paired host that changed address.
///
/// A handset stores its server as `https://<ip>:<port>` plus the certificate
/// fingerprint it trusts. The fingerprint is the identity (ADR-0080); the
/// address is only where that identity answered last time. When the host's
/// DHCP lease turns over — a router reboot, a venue that power-cycles the
/// modem nightly — the address stops being true and nothing notices: the
/// socket retries the dead IP forever, the app looks offline, and the only
/// way back is for somebody to re-pair a handset that is already paired.
///
/// So after a run of failures the LAN is asked where that certificate lives
/// now. A match is the *same* server, which is exactly what makes this safe
/// to do without a human: an attacker on the LAN cannot answer to a
/// fingerprint they do not hold the key for.
///
/// Nothing here runs in server mode — a loopback config carries no
/// fingerprint, and the host is the device itself.
Future<void> relocateServer(Ref ref) async {
  final cfg = ref.read(apiConfigProvider);
  if (cfg == null || cfg.trustedFingerprint.isEmpty) return;

  final found = await ref
      .read(mdnsBrowserServiceProvider)
      .findFingerprintHost(cfg.trustedFingerprint);
  if (found == null) return;

  final next = ApiConfig(
    baseUri: Uri.parse('https://${found.host}:${found.port}'),
    trustedFingerprint: cfg.trustedFingerprint,
  );
  // Found it exactly where we were already looking: it is down, not moved.
  if (next == cfg) return;

  SatLog.vm('server moved ${cfg.baseUri.host} -> ${found.host}:${found.port}');
  final prefs = await ref.read(prefsServiceProvider.future);
  await prefs.setPairedHost(found.host);
  await prefs.setPairedPort(found.port);
  // Republishing rebuilds every repository keyed on the config, including the
  // socket that asked for this — which is how the new address gets used.
  ref.read(apiConfigProvider.notifier).state = next;
}
