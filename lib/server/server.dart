import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'auth.dart';
import 'db/database.dart';
import 'db/seed.dart';
import 'mdns.dart';
import 'pairing.dart';
import 'routes/auth_routes.dart';
import 'routes/health_routes.dart';
import 'routes/menu_routes.dart';
import 'routes/reference_routes.dart';
import 'routes/tables_routes.dart';
import 'routes/tickets_routes.dart';
import 'tls.dart';
import 'ws_hub.dart';

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
  });

  final AppDatabase db;
  final ServerAuth auth;
  final ServerTls tls;
  final WsHub hub;
  final PairingService pairing;
  final SatSetAdvertiser advertiser;
  final int port;
  HttpServer? _http;

  static const defaultPort = 7443;

  static Future<ServerRuntime> boot({int port = defaultPort}) async {
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
    );

    final handler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_authMiddleware(auth))
        .addHandler(rt._buildRouter().call);

    rt._http = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      port,
      securityContext: tls.context,
    );

    await advertiser.start(port: port, fingerprint: tls.fingerprint);
    return rt;
  }

  Router _buildRouter() {
    final r = Router();
    r.mount('/', healthRoutes().call);
    r.mount('/', authRoutes(auth).call);
    r.mount('/', menuRoutes(db).call);
    r.mount('/', tablesRoutes(db, hub, auth).call);
    r.mount('/', ticketsRoutes(db, hub, auth).call);
    r.mount('/', referenceRoutes(db).call);

    r.post('/pair/claim', (Request req) async {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final dev = await pairing.claim(
        token: body['token'] as String,
        deviceId: body['deviceId'] as String,
        deviceLabel: body['deviceLabel'] as String,
        publicKeyPem: body['publicKey'] as String,
      );
      if (dev == null) return Response(409, body: 'pair token invalid');
      return Response.ok(
        jsonEncode({
          'deviceToken': dev.id,
          'fingerprint': tls.fingerprint,
          'serverPublicKey': '',
        }),
        headers: {'content-type': 'application/json'},
      );
    });

    r.get('/ws', webSocketHandler((webSocket, _) {
      // Auth handled in middleware. Register without specific user yet.
      hub.register(webSocket, 'anonymous', 'unknown');
    }) as Function);

    return r;
  }

  Future<void> shutdown() async {
    await _http?.close(force: true);
    await advertiser.stop();
    await hub.dispose();
    await db.close();
  }
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
