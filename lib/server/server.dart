import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'auth.dart';
import 'db/database.dart';
import 'db/seed.dart';
import 'mdns.dart';
import 'pairing.dart';
import 'routes/auth_routes.dart';
import 'routes/devices_routes.dart';
import 'routes/health_routes.dart';
import 'routes/kds_routes.dart';
import 'routes/menu_routes.dart';
import 'routes/printers_routes.dart';
import 'routes/reference_routes.dart';
import 'routes/reports_routes.dart';
import 'routes/reservations_routes.dart';
import 'routes/server_routes.dart';
import 'routes/tables_routes.dart';
import 'routes/tickets_routes.dart';
import 'routes/venue_settings_routes.dart';
import 'tls.dart';
import 'ws_hub.dart';

/// App-level handle to the in-process server. Boot wires this for
/// AppMode.server; the admin auth flow reads it to mint sessions in-process
/// and to tear the server down on admin logout / loss of eligibility.
final serverRuntimeProvider = StateProvider<ServerRuntime?>((_) => null);

/// In-app shelf server runtime. Owns DB, TLS, hub, and lifecycle.
class ServerRuntime {
  ServerRuntime._({
    required this.db,
    required this.auth,
    required this.tls,
    required this.hub,
    required this.pairing,
    required this.advertiser,
    required this.port,
    required this.label,
    required this.version,
  });

  final String? label;
  final String version;

  final AppDatabase db;
  final ServerAuth auth;
  final ServerTls tls;
  final WsHub hub;
  final PairingService pairing;
  final SatSetAdvertiser advertiser;
  final int port;
  HttpServer? _http;
  Timer? _statusTicker;
  bool _restarting = false;

  /// Reset on every successful bind. Restart() updates this.
  DateTime startedAt = DateTime.now();

  /// Rolling window of last 100 request durations in ms. Used for p50/p95.
  final Queue<int> _latencySamples = Queue<int>();
  static const _latencyWindow = 100;
  int _requestCountSinceLastRead = 0;

  Duration get uptime => DateTime.now().difference(startedAt);

  LatencyStats get latencyStats {
    final samples = List<int>.from(_latencySamples)..sort();
    final count = _requestCountSinceLastRead;
    _requestCountSinceLastRead = 0;
    if (samples.isEmpty) {
      return LatencyStats(p50: 0, p95: 0, requestCountRecent: count);
    }
    final p50 = samples[(samples.length * 0.5).floor().clamp(0, samples.length - 1)];
    final p95 = samples[(samples.length * 0.95).floor().clamp(0, samples.length - 1)];
    return LatencyStats(p50: p50, p95: p95, requestCountRecent: count);
  }

  void _recordLatency(int ms) {
    _latencySamples.addLast(ms);
    while (_latencySamples.length > _latencyWindow) {
      _latencySamples.removeFirst();
    }
    _requestCountSinceLastRead++;
  }

  void _resetLatency() {
    _latencySamples.clear();
    _requestCountSinceLastRead = 0;
  }

  static const defaultPort = 7443;
  static const defaultVersion = '1.0.0';

  static Future<ServerRuntime> boot({
    int port = defaultPort,
    String? label,
    String version = defaultVersion,
  }) async {
    final db = await AppDatabase.open();
    await seedIfEmpty(db);
    final tls = await ServerTls.loadOrCreate();
    final hub = WsHub();
    final auth = ServerAuth(db, secret: await ServerAuth.loadOrCreateSecret());
    final pairing = PairingService(db);
    final advertiser = SatSetAdvertiser();

    final rt = ServerRuntime._(
      db: db,
      auth: auth,
      tls: tls,
      hub: hub,
      pairing: pairing,
      advertiser: advertiser,
      port: port,
      label: label,
      version: version,
    );

    final handler = const Pipeline()
        .addMiddleware(rt._latencyAndLoggingMiddleware())
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_authMiddleware(auth))
        .addHandler(rt._buildRouter().call);

    rt._http = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      port,
      securityContext: tls.context,
    );
    SatLog.srv(
      'boot port=$port fp=${tls.fingerprint.substring(0, tls.fingerprint.length.clamp(0, 12))}',
    );

    await advertiser.start(
      port: port,
      fingerprint: tls.fingerprint,
      label: label,
      version: version,
    );
    rt._startStatusTicker();
    return rt;
  }

  void _startStatusTicker() {
    _statusTicker?.cancel();
    _statusTicker = Timer.periodic(const Duration(seconds: 10), (_) async {
      // Sweep expired sessions; emit session.expired for each one so clients
      // can flush their device-online state without a refetch.
      final now = DateTime.now();
      final all = await db.select(db.sessions).get();
      final expired = all.where((s) => s.expiresAt.isBefore(now)).toList();
      if (expired.isNotEmpty) {
        for (final s in expired) {
          await (db.delete(db.sessions)
                ..where((row) => row.token.equals(s.token)))
              .go();
          hub.broadcast(WsEventTypes.sessionExpired, {
            'userId': s.userId,
            'deviceId': s.deviceId,
            'at': now.toIso8601String(),
          });
        }
      }
      await broadcastSystemStatus();
    });
  }

  /// Build status payload + push to every WS client. Called by the ticker
  /// and after lifecycle changes (pair, revoke, restart).
  Future<void> broadcastSystemStatus() async {
    try {
      final body = await buildServerStatusWithCounts(this);
      hub.broadcast(WsEventTypes.systemStatus, body);
    } catch (e) {
      SatLog.srv('status-broadcast-fail $e');
    }
  }

  /// Rebind the HTTP listener and re-advertise mDNS without tearing down DB
  /// or auth state. WS clients are disconnected; their `wsClient` reconnect
  /// backoff brings them back within ~1s. Returns the (unchanged unless cert
  /// was rotated out-of-band) fingerprint.
  Future<RestartResult> restart() async {
    if (_restarting) {
      return RestartResult(fingerprint: tls.fingerprint, alreadyInProgress: true);
    }
    _restarting = true;
    SatLog.srv('restart begin');
    try {
      _statusTicker?.cancel();
      // Drain WS clients.
      await hub.dispose();
      // Close HTTP listener with a short grace period.
      try {
        await _http?.close().timeout(const Duration(seconds: 2));
      } catch (_) {
        await _http?.close(force: true);
      }
      _http = null;
      await advertiser.stop();

      // Rebind on same port and re-advertise. TLS context stays valid; cert
      // rotation is out of scope for the in-app restart.
      final handler = const Pipeline()
          .addMiddleware(_latencyAndLoggingMiddleware())
          .addMiddleware(_corsMiddleware())
          .addMiddleware(_authMiddleware(auth))
          .addHandler(_buildRouter().call);

      _http = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        port,
        securityContext: tls.context,
      );
      await advertiser.start(
        port: port,
        fingerprint: tls.fingerprint,
        label: label,
        version: version,
      );
      startedAt = DateTime.now();
      _resetLatency();
      _startStatusTicker();
      SatLog.srv('restart ok port=$port');
      // Push a fresh status so any client that reconnected sees the new
      // uptime/startedAt without waiting for the next ticker.
      await broadcastSystemStatus();
      return RestartResult(fingerprint: tls.fingerprint);
    } finally {
      _restarting = false;
    }
  }

  Router _buildRouter() {
    final r = Router();
    r.mount('/', healthRoutes().call);
    r.mount('/', authRoutes(auth).call);
    r.mount('/', menuRoutes(db, hub, auth).call);
    r.mount('/', tablesRoutes(db, hub, auth).call);
    r.mount('/', ticketsRoutes(db, hub, auth).call);
    r.mount('/', referenceRoutes(db, hub, auth).call);
    r.mount('/', venueSettingsRoutes(db, hub, auth).call);
    r.mount('/', serverRoutes(this).call);
    r.mount('/', printersRoutes(db, hub, auth).call);
    r.mount('/', devicesRoutes(db, hub, auth).call);
    r.mount('/', kdsRoutes(db, auth).call);
    r.mount('/', reportsRoutes(db, auth).call);
    r.mount('/', reservationsRoutes(db, hub, auth).call);

    r.post('/pair/claim', (Request req) async {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final dev = await pairing.claim(
        token: body['token'] as String,
        deviceId: body['deviceId'] as String,
        deviceLabel: body['deviceLabel'] as String,
        publicKeyPem: body['publicKey'] as String,
      );
      if (dev == null) return Response(409, body: 'pair token invalid');
      hub.broadcast(WsEventTypes.devicePaired, {
        'id': dev.id,
        'label': dev.label,
        'pairedAt': dev.pairedAt.toIso8601String(),
      });
      unawaited(broadcastSystemStatus());
      return Response.ok(
        jsonEncode({
          'deviceToken': dev.id,
          'fingerprint': tls.fingerprint,
          'serverPublicKey': '',
        }),
        headers: {'content-type': 'application/json'},
      );
    });

    // LAN-trusted auto-claim: client reached this server via mDNS+TLS
    // fingerprint pinning, so we issue+consume a one-shot token internally
    // instead of requiring out-of-band token entry. PIN auth still gates
    // anything useful after pairing.
    r.post('/pair/auto-claim', (Request req) async {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final token = await pairing.issue();
      final dev = await pairing.claim(
        token: token.token,
        deviceId: (body['deviceId'] as String?) ?? '',
        deviceLabel: (body['deviceLabel'] as String?) ?? 'satset-client',
        publicKeyPem: (body['publicKey'] as String?) ?? '',
      );
      if (dev == null) return Response(409, body: 'auto-claim failed');
      hub.broadcast(WsEventTypes.devicePaired, {
        'id': dev.id,
        'label': dev.label,
        'pairedAt': dev.pairedAt.toIso8601String(),
      });
      unawaited(broadcastSystemStatus());
      return Response.ok(
        jsonEncode({
          'deviceToken': dev.id,
          'fingerprint': tls.fingerprint,
          'serverPublicKey': '',
        }),
        headers: {'content-type': 'application/json'},
      );
    });

    r.get(
      '/ws',
      webSocketHandler((webSocket, _) {
            // Auth handled in middleware. Register without specific user yet.
            hub.register(webSocket, 'anonymous', 'unknown');
          })
          as Function,
    );

    return r;
  }

  Future<void> shutdown() async {
    _statusTicker?.cancel();
    await _http?.close(force: true);
    await advertiser.stop();
    await hub.dispose();
    await db.close();
  }
}

class RestartResult {
  final String fingerprint;
  final bool alreadyInProgress;
  const RestartResult({
    required this.fingerprint,
    this.alreadyInProgress = false,
  });
}

extension on ServerRuntime {
  Middleware _latencyAndLoggingMiddleware() {
    return (Handler inner) {
      return (Request req) async {
        final sw = Stopwatch()..start();
        final res = await inner(req);
        final ms = sw.elapsedMilliseconds;
        // Skip /ws upgrades and /healthz from latency stats: ws never returns,
        // healthz is the client ping itself (would create a feedback loop).
        final path = '/${req.url.path}';
        if (path != '/ws' && path != '/healthz') {
          _recordLatency(ms);
        }
        SatLog.srv(
          '${req.method} $path → ${res.statusCode} ${ms}ms',
        );
        return res;
      };
    };
  }
}

class LatencyStats {
  final int p50;
  final int p95;
  final int requestCountRecent;
  const LatencyStats({
    required this.p50,
    required this.p95,
    required this.requestCountRecent,
  });
}

Middleware _corsMiddleware() {
  return (Handler inner) {
    return (Request req) async {
      if (req.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final res = await inner(req);
      return res.change(headers: {...res.headers, ..._corsHeaders});
    };
  };
}

const _corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, PATCH, DELETE, OPTIONS',
  'access-control-allow-headers':
      'authorization, content-type, x-device-id, x-idempotency-key',
};

Middleware _authMiddleware(ServerAuth auth) {
  const skip = {
    '/healthz',
    '/auth/login',
    '/pair/claim',
    '/pair/auto-claim',
  };
  return (Handler inner) {
    return (Request req) async {
      final path = '/${req.url.path}';
      if (skip.contains(path)) return inner(req);
      // /ws is special: auth via token query param.
      if (path == '/ws') {
        final t = req.url.queryParameters['token'];
        final u = await auth.resolveBearer(t);
        if (u == null) return Response.forbidden('ws auth required');
        return inner(req);
      }
      final h = req.headers['authorization'];
      if (h == null || !h.toLowerCase().startsWith('bearer ')) {
        return Response(401, body: 'auth required');
      }
      final user = await auth.resolveBearer(h.substring(7).trim());
      if (user == null) return Response(401, body: 'auth expired');
      return inner(req);
    };
  };
}
