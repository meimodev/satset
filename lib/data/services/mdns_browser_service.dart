import 'dart:async';
import 'package:satset/core/time/sat_clock.dart';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';

/// A SatSet server seen on the LAN via mDNS.
class DiscoveredServer {
  final String
  name; // mDNS service name (unique per LAN after bonsoir suffixing)
  final String host;
  final int port;
  final String fingerprint;
  final String label;
  final String? version;

  /// Cloud venue id this server hosts (TXT `vid`, ADR-0017). Empty for a
  /// legacy server that predates venue-scoping.
  final String venueId;

  const DiscoveredServer({
    required this.name,
    required this.host,
    required this.port,
    required this.fingerprint,
    required this.label,
    this.version,
    this.venueId = '',
  });

  String get key => '$host:$port';

  @override
  bool operator ==(Object other) =>
      other is DiscoveredServer &&
      other.key == key &&
      other.fingerprint == fingerprint;

  @override
  int get hashCode => key.hashCode ^ fingerprint.hashCode;
}

/// Wraps `BonsoirDiscovery` for the `_satset._tcp` service type and emits the
/// current set of resolved servers whenever it changes. Skips entries that
/// are missing required TXT attributes (`fp`, `label`) or that resolve to
/// the local device's own interfaces.
class MdnsBrowserService {
  static const serviceType = '_satset._tcp';

  final _controller = StreamController<List<DiscoveredServer>>.broadcast();
  final Map<String, DiscoveredServer> _byName = {};
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _sub;
  Set<String> _localAddrs = const {};
  int _refCount = 0;

  Stream<List<DiscoveredServer>> get servers => _controller.stream;

  List<DiscoveredServer> get current => _byName.values.toList(growable: false);

  /// Reference-counted start: safe to call from multiple subscribers; the
  /// underlying discovery only spins up once.
  Future<void> start() async {
    _refCount++;
    if (_discovery != null) return;
    try {
      _localAddrs = await _gatherLocalAddrs();
    } catch (e) {
      SatLog.vm('MdnsBrowser localAddrs fail $e');
      _localAddrs = const {};
    }
    final d = BonsoirDiscovery(type: serviceType);
    await d.ready;
    _discovery = d;
    _sub = d.eventStream?.listen(
      _onEvent,
      onError: (Object e, StackTrace st) {
        SatLog.err('mdns discovery stream', e, st);
      },
    );
    await d.start();
    SatLog.vm('MdnsBrowser start $serviceType');
  }

  /// One-shot scan for an already-running server hosting [venueId] (the
  /// Main-Device guard, ADR-0017). Spins discovery up for at most [window],
  /// returning the first matching host or null. Self-contained start/stop.
  Future<DiscoveredServer?> findVenueHost(
    String venueId, {
    Duration window = const Duration(seconds: 3),
  }) async {
    if (venueId.isEmpty) return null;
    await start();
    try {
      final deadline = SatClock.now().add(window);
      while (SatClock.now().isBefore(deadline)) {
        for (final s in current) {
          if (s.venueId == venueId) return s;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      return null;
    } finally {
      await stop();
    }
  }

  Future<void> stop() async {
    if (_refCount > 0) _refCount--;
    if (_refCount > 0) return;
    await _sub?.cancel();
    _sub = null;
    final d = _discovery;
    _discovery = null;
    if (d != null) {
      try {
        await d.stop();
      } catch (_) {}
    }
    _byName.clear();
    _emit();
    SatLog.vm('MdnsBrowser stop');
  }

  Future<void> dispose() async {
    _refCount = 0;
    await _sub?.cancel();
    await _discovery?.stop();
    await _controller.close();
  }

  void _onEvent(BonsoirDiscoveryEvent ev) {
    final svc = ev.service;
    switch (ev.type) {
      case BonsoirDiscoveryEventType.discoveryServiceFound:
        if (svc != null) {
          unawaited(svc.resolve(_discovery!.serviceResolver));
        }
      case BonsoirDiscoveryEventType.discoveryServiceResolved:
        if (svc is ResolvedBonsoirService) _handleResolved(svc);
      case BonsoirDiscoveryEventType.discoveryServiceLost:
        if (svc != null && _byName.remove(svc.name) != null) {
          _emit();
        }
      case BonsoirDiscoveryEventType.discoveryServiceResolveFailed:
      case BonsoirDiscoveryEventType.discoveryStarted:
      case BonsoirDiscoveryEventType.discoveryStopped:
      case BonsoirDiscoveryEventType.unknown:
        break;
    }
  }

  void _handleResolved(ResolvedBonsoirService svc) {
    final host = svc.host;
    if (host == null || host.isEmpty) return;
    if (_isLocalHost(host)) return; // hide own broadcast
    final attrs = svc.attributes;
    final fp = (attrs['fp'] ?? '').trim().toLowerCase();
    final hasExplicitLabel = (attrs['label'] ?? '').trim().isNotEmpty;
    final label = (attrs['label'] ?? svc.name).trim();
    if (fp.isEmpty || label.isEmpty) return;
    final version = attrs['ver'];
    final entry = DiscoveredServer(
      name: svc.name,
      host: host,
      port: svc.port,
      fingerprint: fp,
      label: label,
      version: (version == null || version.isEmpty) ? null : version,
      venueId: (attrs['vid'] ?? '').trim(),
    );
    // Dedup by host:port. mDNS can surface several stale service names
    // pointing at the same endpoint after server restarts. Prefer the entry
    // whose TXT carries an explicit `label` (= our current broadcast).
    final hpKey = '$host:${svc.port}';
    final existingByName = _byName[svc.name];
    if (existingByName != null &&
        existingByName.host == host &&
        existingByName.port == svc.port) {
      _byName[svc.name] = entry;
    } else {
      // Drop any prior entries pointing at the same host:port that lack an
      // explicit label, so newest broadcast (richest TXT) wins.
      _byName.removeWhere((_, v) {
        if ('${v.host}:${v.port}' != hpKey) return false;
        return hasExplicitLabel || v.version == null;
      });
      _byName[svc.name] = entry;
    }
    _emit();
  }

  bool _isLocalHost(String host) {
    if (host == '127.0.0.1' || host == '::1' || host == 'localhost') {
      return true;
    }
    if (_localAddrs.contains(host)) return true;
    // Bonsoir on Android sometimes returns `.local` mDNS names; treat the
    // device's own hostname.local as local too.
    final hn = Platform.localHostname.trim();
    if (hn.isNotEmpty && host == '$hn.local') return true;
    return false;
  }

  void _emit() => _controller.add(current);

  static Future<Set<String>> _gatherLocalAddrs() async {
    final ifaces = await NetworkInterface.list(
      includeLoopback: true,
      includeLinkLocal: true,
    );
    return {
      for (final i in ifaces)
        for (final a in i.addresses) a.address,
    };
  }
}

final mdnsBrowserServiceProvider = Provider<MdnsBrowserService>((ref) {
  final svc = MdnsBrowserService();
  ref.onDispose(() => unawaited(svc.dispose()));
  return svc;
});
