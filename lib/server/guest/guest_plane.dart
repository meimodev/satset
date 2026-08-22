import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/guest/guest_routes.dart';
import 'package:satset/server/ws_hub.dart';

/// The default guest port. Cleartext, and a different number from the staff
/// API's 7443 so the two can never be confused by a firewall rule or a person.
const guestPlanePort = 8080;

/// The second listener: **cleartext HTTP, guest routes only** (ADR-0105).
///
/// Cleartext because a phone that has never met this venue cannot be taught to
/// trust its self-signed certificate, and an interstitial browser warning in
/// front of a menu is a feature nobody uses. What crosses it is a menu, a table
/// code and an order — no credential, no token, no money.
///
/// The plane **binds only while `venue_settings.guest_ordering_enabled` is on**.
/// Off means the socket does not exist, rather than existing and answering 403:
/// a venue that never opted in has no second attack surface at all. Toggling the
/// flag goes through the ordinary server restart, because the router is built
/// once at boot.
class GuestPlane {
  final AppDatabase db;
  final WsHub hub;
  final int port;
  HttpServer? _http;

  GuestPlane({required this.db, required this.hub, this.port = guestPlanePort});

  bool get running => _http != null;

  /// The LAN URL a printed QR points at, or null while the plane is down.
  String? urlFor(String code, String host) =>
      _http == null ? null : 'http://$host:$port/t/$code';

  Future<void> start() async {
    if (_http != null) return;
    final handler = const Pipeline()
        .addMiddleware(_guestOnly())
        .addMiddleware(_stampCaller())
        .addHandler(guestRoutes(db, hub).call);
    _http = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    SatLog.srv('guest plane listening on :$port (cleartext)');
  }

  Future<void> stop() async {
    await _http?.close(force: true);
    _http = null;
  }
}

/// The IPv4 address a phone on the venue Wi-Fi can actually reach, or null
/// when this machine has no LAN address at all.
///
/// The **server** answers this, never the client: on the server device the
/// client half is paired to itself over loopback, so building the QR from the
/// paired host prints `http://127.0.0.1:8080/...` — a URL that resolves, on
/// the guest's phone, to the guest's phone. Every laminated card in the venue
/// would be dead on arrival.
Future<String?> guestLanHost() async {
  final ifaces = await NetworkInterface.list(
    includeLoopback: false,
    includeLinkLocal: false,
    type: InternetAddressType.IPv4,
  );
  for (final i in ifaces) {
    for (final a in i.addresses) {
      // ponytail: first non-loopback IPv4 wins; a venue with two LANs is a
      // problem we have not met, and the fix then is a setting, not a guess.
      if (!a.isLoopback) return a.address;
    }
  }
  return null;
}

/// CORS for the page itself and nothing else. The staff API is not reachable
/// from this handler at all — it is a different [Router] on a different socket
/// — so this middleware is about browsers, not about authorisation.
Middleware _guestOnly() =>
    (inner) => (req) async {
      if (req.method == 'OPTIONS') {
        return Response.ok('', headers: _cors);
      }
      final res = await inner(req);
      return res.change(headers: {...res.headers, ..._cors});
    };

/// Puts the caller's address in the request context as `guest.ip`, which is
/// what the router's rate buckets key on.
///
/// It lives here rather than in the router because the address is a property
/// of the *socket*, and the router is deliberately socket-agnostic — a route
/// test builds a [Request] by hand and there is no connection behind it. An
/// absent stamp is read as "nothing to key on", never as a shared key.
///
/// No `x-forwarded-for` is consulted. There is no proxy on a LAN, and honouring
/// a header the caller writes would hand every bucket a free reset.
Middleware _stampCaller() =>
    (inner) => (req) {
      final info =
          req.context['shelf.io.connection_info'] as HttpConnectionInfo?;
      final ip = info?.remoteAddress.address;
      return inner(ip == null ? req : req.change(context: {'guest.ip': ip}));
    };

const _cors = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, DELETE, OPTIONS',
  'access-control-allow-headers': 'content-type, x-guest-session',
};
