import 'dart:async';
import 'package:satset/core/time/sat_clock.dart';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/printing/struk_socket.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/release_gate.dart';
import 'auth.dart';
import 'db/database.dart';
import 'db/seed.dart';
import 'mdns.dart';
import 'routes/auth_routes.dart';
import 'routes/devices_routes.dart';
import 'routes/discount_preset_routes.dart';
import 'routes/health_routes.dart';
import 'routes/kds_routes.dart';
import 'routes/menu_routes.dart';
import 'routes/stock_routes.dart';
import 'routes/printers_routes.dart';
import 'routes/reference_routes.dart';
import 'routes/reports_routes.dart';
import 'routes/reservations_routes.dart';
import 'routes/server_routes.dart';
import 'routes/cash_routes.dart';
import 'routes/members_routes.dart';
import 'routes/self_order_routes.dart';
import 'routes/settlement_routes.dart';
import 'routes/tables_routes.dart';
import 'routes/tickets_routes.dart';
import 'routes/venue_day_routes.dart';
import 'routes/venue_settings_routes.dart';
import 'guest/guest_plane.dart';
import 'self_order.dart' show guestRules;
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
    required this.advertiser,
    required this.port,
    required this.label,
    required this.version,
    required this.venueId,
  });

  final String? label;
  final String version;

  /// The cloud venue this host serves (ADR-0017). Advertised in the mDNS TXT
  /// record so a second device about to enter Server mode for the same venue
  /// can detect the collision and join as a client instead of splitting the
  /// data. Empty for a legacy/un-gated server-mode boot.
  final String venueId;

  final AppDatabase db;
  final ServerAuth auth;
  final ServerTls tls;
  final WsHub hub;
  final SatSetAdvertiser advertiser;
  final int port;

  /// The release gate this host last saw in the cloud, relayed to every client
  /// over the LAN (ADR-0087).
  ///
  /// Held on the runtime rather than fetched per request because only the host
  /// has Firebase — a client learns the floor from `/healthz` and from the
  /// `releaseGate` broadcast, and neither can wait on a network the client
  /// cannot reach. [ReleaseGate.unknown] until the listener delivers, which
  /// fails every device open.
  ReleaseGate releaseGate = ReleaseGate.unknown;

  /// Stores the gate and, when it actually changed, tells the floor.
  ///
  /// Idempotent on purpose: the Firestore listener re-fires on unrelated
  /// document metadata, and a broadcast per re-fire would be a WS message every
  /// time the cache blinks.
  void publishReleaseGate(ReleaseGate next) {
    if (next == releaseGate) return;
    releaseGate = next;
    SatLog.srv('release gate → $next');
    hub.broadcast(WsEventTypes.releaseGate, next.toJson());
  }
  HttpServer? _http;

  /// The cleartext [[Pesan mandiri]] listener (ADR-0105). Bound only while the
  /// venue flag is on, torn down and rebuilt by [restart] like the staff one.
  GuestPlane? _guest;
  Timer? _statusTicker;
  Timer? _printerHeartbeat;
  bool _restarting = false;

  /// Reset on every successful bind. Restart() updates this.
  DateTime startedAt = SatClock.now();

  /// Rolling window of last 100 request durations in ms. Used for p50/p95.
  final Queue<int> _latencySamples = Queue<int>();
  static const _latencyWindow = 100;
  int _requestCountSinceLastRead = 0;

  Duration get uptime => SatClock.now().difference(startedAt);

  LatencyStats get latencyStats {
    final samples = List<int>.from(_latencySamples)..sort();
    final count = _requestCountSinceLastRead;
    _requestCountSinceLastRead = 0;
    if (samples.isEmpty) {
      return LatencyStats(p50: 0, p95: 0, requestCountRecent: count);
    }
    final p50 =
        samples[(samples.length * 0.5).floor().clamp(0, samples.length - 1)];
    final p95 =
        samples[(samples.length * 0.95).floor().clamp(0, samples.length - 1)];
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
    String venueId = '',
  }) async {
    final db = await AppDatabase.open();
    await seedInfra(db);
    final tls = await ServerTls.loadOrCreate();
    final hub = WsHub();
    final auth = ServerAuth(db, secret: await ServerAuth.loadOrCreateSecret());
    final advertiser = SatSetAdvertiser();

    final rt = ServerRuntime._(
      db: db,
      auth: auth,
      tls: tls,
      hub: hub,
      advertiser: advertiser,
      port: port,
      label: label,
      version: version,
      venueId: venueId,
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
      venueId: venueId,
    );
    await rt._syncGuestPlane();
    rt._startStatusTicker();
    rt._startPrinterHeartbeat();
    return rt;
  }

  /// Probes every enabled venue printer (connect-only, in parallel) on a 15s
  /// tick, stamps `lastSeenAt` on the ones that answer, and broadcasts so
  /// clients refresh their online dots without a refetch. A printer that
  /// doesn't answer simply isn't stamped and ages past the client's 30s online
  /// window. See ADR-0022.
  void _startPrinterHeartbeat() {
    _printerHeartbeat?.cancel();
    _printerHeartbeat = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final rows = await (db.select(
          db.printers,
        )..where((p) => p.enabled.equals(true))).get();
        if (rows.isEmpty) return;
        await Future.wait(
          rows.map((p) async {
            if (!await StrukSocket.probe(p.host, p.port)) return;
            await (db.update(db.printers)..where((x) => x.id.equals(p.id)))
                .write(PrintersCompanion(lastSeenAt: Value(SatClock.now())));
            final updated = await (db.select(
              db.printers,
            )..where((x) => x.id.equals(p.id))).getSingleOrNull();
            if (updated != null) {
              hub.broadcast(WsEventTypes.printerUpdated, printerJson(updated));
            }
          }),
        );
      } catch (e) {
        SatLog.srv('printer heartbeat $e');
      }
    });
  }

  void _startStatusTicker() {
    _statusTicker?.cancel();
    _statusTicker = Timer.periodic(const Duration(seconds: 10), (_) async {
      // Sweep expired sessions; emit session.expired for each one so clients
      // can flush their device-online state without a refetch.
      final now = SatClock.now();
      final all = await db.select(db.sessions).get();
      final expired = all.where((s) => s.expiresAt.isBefore(now)).toList();
      if (expired.isNotEmpty) {
        for (final s in expired) {
          await (db.delete(
            db.sessions,
          )..where((row) => row.token.equals(s.token))).go();
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
      return RestartResult(
        fingerprint: tls.fingerprint,
        alreadyInProgress: true,
      );
    }
    _restarting = true;
    SatLog.srv('restart begin');
    try {
      _statusTicker?.cancel();
      _printerHeartbeat?.cancel();
      // Drain WS clients.
      await hub.dispose();
      await _guest?.stop();
      _guest = null;
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
        venueId: venueId,
      );
      await _syncGuestPlane();
      startedAt = SatClock.now();
      _resetLatency();
      _startStatusTicker();
      _startPrinterHeartbeat();
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
    r.mount('/', healthRoutes(() => releaseGate).call);
    r.mount('/', authRoutes(auth).call);
    r.mount('/', menuRoutes(db, hub, auth).call);
    r.mount('/', stockRoutes(db, hub, auth).call);
    r.mount('/', tablesRoutes(db, hub, auth).call);
    r.mount('/', ticketsRoutes(db, hub, auth).call);
    r.mount('/', referenceRoutes(db, hub, auth).call);
    r.mount('/', venueSettingsRoutes(db, hub, auth).call);
    r.mount('/', discountPresetRoutes(db, hub, auth).call);
    r.mount('/', serverRoutes(this).call);
    r.mount('/', printersRoutes(db, hub, auth).call);
    r.mount('/', devicesRoutes(db, hub, auth).call);
    r.mount('/', kdsRoutes(db, auth).call);
    r.mount('/', reportsRoutes(db, auth).call);
    r.mount('/', reservationsRoutes(db, hub, auth).call);
    r.mount('/', settlementRoutes(db, hub, auth).call);
    r.mount('/', cashRoutes(db, hub, auth).call);
    r.mount('/', venueDayRoutes(db, hub, auth).call);
    r.mount('/', membersRoutes(db, hub, auth).call);
    r.mount('/', selfOrderRoutes(db, hub, auth).call);

    // LAN-trusted auto-claim: the client reached this server via mDNS and
    // verified its TLS fingerprint end-to-end, so reaching this handler at all
    // is the proof of LAN presence. The device row is written directly — there
    // is no out-of-band token to exchange. PIN auth still gates anything useful
    // after pairing (ADR-0004).
    r.post('/pair/auto-claim', (Request req) async {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final deviceId = (body['deviceId'] as String?) ?? '';
      if (deviceId.isEmpty) return Response(409, body: 'auto-claim failed');
      // A revoked device does not get to re-pair its way back in. The upsert
      // below leaves `revoked` alone — the companion never names the column —
      // so without this the row stayed revoked while the handler answered 200
      // and the client believed it was paired, which is the worst of both.
      final prior = await (db.select(
        db.devices,
      )..where((d) => d.id.equals(deviceId))).getSingleOrNull();
      if (prior != null && prior.revoked) {
        return Response(
          403,
          body: jsonEncode({
            'code': 'device_revoked',
            'message': 'device revoked',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
      await db
          .into(db.devices)
          .insertOnConflictUpdate(
            DevicesCompanion.insert(
              id: deviceId,
              label: (body['deviceLabel'] as String?) ?? 'satset-client',
              publicKeyPem: (body['publicKey'] as String?) ?? '',
              pairedAt: SatClock.now(),
            ),
          );
      final dev = await (db.select(
        db.devices,
      )..where((d) => d.id.equals(deviceId))).getSingleOrNull();
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

  /// Bind or unbind the guest plane to match `venue_settings`. Off means the
  /// socket does not exist — not that it exists and 403s — so a venue that
  /// never opted in has no second surface at all.
  Future<void> _syncGuestPlane() async {
    final on = (await guestRules(db)).enabled;
    if (on && _guest == null) {
      final plane = GuestPlane(db: db, hub: hub);
      await plane.start();
      _guest = plane;
    } else if (!on && _guest != null) {
      await _guest!.stop();
      _guest = null;
    }
  }

  /// Whether a guest phone can reach this server right now.
  bool get guestPlaneRunning => _guest?.running ?? false;

  Future<void> shutdown() async {
    _statusTicker?.cancel();
    _printerHeartbeat?.cancel();
    await _http?.close(force: true);
    await _guest?.stop();
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
        final Response res;
        try {
          res = await inner(req);
        } catch (e, st) {
          // Shelf turns an uncaught throw into a bare 500 and drops the reason
          // on the floor, so a route that breaks is invisible in the log —
          // every other request keeps succeeding and nothing says why this one
          // did not. Log it and rethrow; the response shelf sends is unchanged.
          SatLog.err('${req.method} /${req.url.path} threw', e, st);
          rethrow;
        }
        final ms = sw.elapsedMilliseconds;
        // Skip /ws upgrades and /healthz from latency stats: ws never returns,
        // healthz is the client ping itself (would create a feedback loop).
        final path = '/${req.url.path}';
        if (path != '/ws' && path != '/healthz') {
          _recordLatency(ms);
        }
        SatLog.srv('${req.method} $path → ${res.statusCode} ${ms}ms');
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
  const skip = {'/healthz', '/auth/login', '/pair/auto-claim'};
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
