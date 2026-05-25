import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/server/auth.dart';

Router authRoutes(ServerAuth auth) {
  final r = Router();

  r.post('/auth/admin/login', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final email = (body['email'] as String?) ?? '';
    final password = (body['password'] as String?) ?? '';
    final deviceId = (body['deviceId'] as String?) ?? '';
    if (email.isEmpty || password.isEmpty || deviceId.isEmpty) {
      return Response(400,
          body: jsonEncode({
            'code': 'bad_request',
            'message': 'email+password+deviceId required',
          }),
          headers: {'content-type': 'application/json'});
    }
    final session = await auth.signInWithEmailPassword(
      email: email,
      password: password,
      deviceId: deviceId,
    );
    if (session == null) {
      return Response(401,
          body: jsonEncode({
            'code': 'invalid_credentials',
            'message': 'Email atau password salah',
          }),
          headers: {'content-type': 'application/json'});
    }
    final me = await auth.resolveBearer(session.token);
    final role = me == null
        ? null
        : await (auth.db.select(auth.db.roles)
              ..where((r) => r.id.equals(me.roleId)))
            .getSingleOrNull();
    final caps = role == null
        ? const <String>[]
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
    return Response.ok(
      jsonEncode({
        'token': session.token,
        'userId': session.userId,
        'roleId': me?.roleId ?? '',
        'capabilities': caps,
        'expiresAt': session.expiresAt.toIso8601String(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  r.post('/auth/login', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final pin = (body['pin'] as String?) ?? '';
    final deviceId = (body['deviceId'] as String?) ?? '';
    if (pin.isEmpty || deviceId.isEmpty) {
      return Response(400,
          body: jsonEncode({'code': 'bad_request', 'message': 'pin+deviceId required'}),
          headers: {'content-type': 'application/json'});
    }
    final session = await auth.signInWithPin(pin: pin, deviceId: deviceId);
    if (session == null) {
      return Response(401,
          body: jsonEncode({'code': 'invalid_pin', 'message': 'PIN salah'}),
          headers: {'content-type': 'application/json'});
    }
    final me = await auth.resolveBearer(session.token);
    final role = me == null
        ? null
        : await (auth.db.select(auth.db.roles)
              ..where((r) => r.id.equals(me.roleId)))
            .getSingleOrNull();
    final caps = role == null
        ? const <String>[]
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
    return Response.ok(
      jsonEncode({
        'token': session.token,
        'userId': session.userId,
        'roleId': me?.roleId ?? '',
        'capabilities': caps,
        'expiresAt': session.expiresAt.toIso8601String(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  r.post('/auth/logout', (Request req) async {
    final t = _bearer(req);
    if (t != null) await auth.revoke(t);
    return Response(204);
  });

  r.get('/auth/me', (Request req) async {
    final t = _bearer(req);
    final user = await auth.resolveBearer(t);
    if (user == null) {
      return Response(401);
    }
    final role = await (auth.db.select(auth.db.roles)
          ..where((rr) => rr.id.equals(user.roleId)))
        .getSingleOrNull();
    final caps = role == null
        ? const <String>[]
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
    return Response.ok(
      jsonEncode({
        'userId': user.id,
        'name': user.name,
        'initials': user.initials,
        'roleId': user.roleId,
        'zoneAssigned': user.zoneAssigned,
        'capabilities': caps,
        'avatarColorHex': user.avatarColorHex,
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  return r;
}

String? _bearer(Request req) {
  final h = req.headers['authorization'];
  if (h == null) return null;
  if (!h.toLowerCase().startsWith('bearer ')) return null;
  return h.substring(7).trim();
}
