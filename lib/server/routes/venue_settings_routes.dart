import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:satset/domain/models/capability.dart';

const _singletonId = 'default';

Future<Response?> _requireCap(
  Request req,
  AppDatabase db,
  ServerAuth? auth,
  Capability needed,
) async {
  if (auth == null) return null;
  final token = req.headers['authorization']
      ?.replaceFirst(RegExp(r'^[Bb]earer\s+'), '');
  final user = await auth.resolveBearer(token);
  if (user == null) return Response(401);
  final role = await (db.select(db.roles)
        ..where((r) => r.id.equals(user.roleId)))
      .getSingleOrNull();
  final caps = role == null
      ? const <String>[]
      : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
  if (!caps.contains(needed.name)) {
    return Response(403,
        body: jsonEncode({
          'code': 'forbidden',
          'message': 'missing capability ${needed.name}',
        }),
        headers: {'content-type': 'application/json'});
  }
  return null;
}

Router venueSettingsRoutes(AppDatabase db, WsHub hub, [ServerAuth? auth]) {
  final r = Router();

  r.get('/venue/settings', (Request req) async {
    final row = await _readOrSeed(db);
    return Response.ok(jsonEncode(_toJson(row)),
        headers: {'content-type': 'application/json'});
  });

  r.patch('/venue/settings', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    await _readOrSeed(db);
    await (db.update(db.venueSettings)
          ..where((t) => t.id.equals(_singletonId)))
        .write(
      VenueSettingsCompanion(
        displayName: body.containsKey('displayName')
            ? Value((body['displayName'] as String).trim())
            : const Value.absent(),
        legalName: body.containsKey('legalName')
            ? Value((body['legalName'] as String).trim())
            : const Value.absent(),
        address: body.containsKey('address')
            ? Value((body['address'] as String).trim())
            : const Value.absent(),
        phone: body.containsKey('phone')
            ? Value((body['phone'] as String).trim())
            : const Value.absent(),
        receiptHeader: body.containsKey('receiptHeader')
            ? Value((body['receiptHeader'] as String).trim())
            : const Value.absent(),
        receiptFooter: body.containsKey('receiptFooter')
            ? Value((body['receiptFooter'] as String).trim())
            : const Value.absent(),
        receiptTagline: body.containsKey('receiptTagline')
            ? Value((body['receiptTagline'] as String).trim())
            : const Value.absent(),
        receiptSocial: body.containsKey('receiptSocial')
            ? Value((body['receiptSocial'] as String).trim())
            : const Value.absent(),
        receiptThankYou: body.containsKey('receiptThankYou')
            ? Value((body['receiptThankYou'] as String).trim())
            : const Value.absent(),
        receiptQrUrl: body.containsKey('receiptQrUrl')
            ? Value((body['receiptQrUrl'] as String).trim())
            : const Value.absent(),
        receiptQrCaption: body.containsKey('receiptQrCaption')
            ? Value((body['receiptQrCaption'] as String).trim())
            : const Value.absent(),
        taxEnabled: body.containsKey('taxEnabled')
            ? Value(body['taxEnabled'] as bool)
            : const Value.absent(),
        taxRateBps: body.containsKey('taxRateBps')
            ? Value((body['taxRateBps'] as num).toInt())
            : const Value.absent(),
        serviceEnabled: body.containsKey('serviceEnabled')
            ? Value(body['serviceEnabled'] as bool)
            : const Value.absent(),
        serviceMode: body.containsKey('serviceMode')
            ? Value(_validMode(body['serviceMode'] as String))
            : const Value.absent(),
        serviceRateBps: body.containsKey('serviceRateBps')
            ? Value((body['serviceRateBps'] as num).toInt())
            : const Value.absent(),
        serviceFixedAmount: body.containsKey('serviceFixedAmount')
            ? Value((body['serviceFixedAmount'] as num).toInt())
            : const Value.absent(),
        // ADR-0038. Flipping this changes future totals only — settled history
        // is snapshotted and never recomputed.
        taxAfterDiscount: body.containsKey('taxAfterDiscount')
            ? Value(body['taxAfterDiscount'] as bool)
            : const Value.absent(),
        businessDayStartHour: body.containsKey('businessDayStartHour')
            ? Value(((body['businessDayStartHour'] as num).toInt()).clamp(0, 23))
            : const Value.absent(),
        prepTargetMins: body.containsKey('prepTargetMins')
            ? Value(((body['prepTargetMins'] as num).toInt()).clamp(1, 120))
            : const Value.absent(),
        // Service timings (ADR-0043/0044). Clamped server-side so a bad client
        // can't disable a cue by writing 0 — "off" is the explicit
        // `*AlertEnabled` flag, never a degenerate threshold.
        pickupTargetMins: body.containsKey('pickupTargetMins')
            ? Value(((body['pickupTargetMins'] as num).toInt()).clamp(1, 60))
            : const Value.absent(),
        ungreetedMins: body.containsKey('ungreetedMins')
            ? Value(((body['ungreetedMins'] as num).toInt()).clamp(1, 60))
            : const Value.absent(),
        ungreetedEscalateMins: body.containsKey('ungreetedEscalateMins')
            ? Value(
                ((body['ungreetedEscalateMins'] as num).toInt()).clamp(1, 60))
            : const Value.absent(),
        longStayMins: body.containsKey('longStayMins')
            ? Value(((body['longStayMins'] as num).toInt()).clamp(15, 480))
            : const Value.absent(),
        idleTableMins: body.containsKey('idleTableMins')
            ? Value(((body['idleTableMins'] as num).toInt()).clamp(5, 240))
            : const Value.absent(),
        reservationGraceMins: body.containsKey('reservationGraceMins')
            ? Value(
                ((body['reservationGraceMins'] as num).toInt()).clamp(0, 240))
            : const Value.absent(),
        pendingReviewMins: body.containsKey('pendingReviewMins')
            ? Value(((body['pendingReviewMins'] as num).toInt()).clamp(1, 120))
            : const Value.absent(),
        ungreetedAlertEnabled: body.containsKey('ungreetedAlertEnabled')
            ? Value(body['ungreetedAlertEnabled'] == true)
            : const Value.absent(),
        pickupAlertEnabled: body.containsKey('pickupAlertEnabled')
            ? Value(body['pickupAlertEnabled'] == true)
            : const Value.absent(),
        guestOrderingEnabled: body.containsKey('guestOrderingEnabled')
            ? Value(body['guestOrderingEnabled'] == true)
            : const Value.absent(),
        soundNewOrder: body.containsKey('soundNewOrder')
            ? Value((body['soundNewOrder'] as String).trim())
            : const Value.absent(),
        soundReady: body.containsKey('soundReady')
            ? Value((body['soundReady'] as String).trim())
            : const Value.absent(),
        soundVoid: body.containsKey('soundVoid')
            ? Value((body['soundVoid'] as String).trim())
            : const Value.absent(),
        soundOverdue: body.containsKey('soundOverdue')
            ? Value((body['soundOverdue'] as String).trim())
            : const Value.absent(),
        soundUngreeted: body.containsKey('soundUngreeted')
            ? Value((body['soundUngreeted'] as String).trim())
            : const Value.absent(),
        soundPickup: body.containsKey('soundPickup')
            ? Value((body['soundPickup'] as String).trim())
            : const Value.absent(),
      ),
    );
    final row = await _readOrSeed(db);
    final payload = _toJson(row);
    hub.broadcast(WsEventTypes.venueSettingsUpdated, payload);
    return Response.ok(jsonEncode(payload),
        headers: {'content-type': 'application/json'});
  });

  // ---------- logo (binary side-endpoints, ADR-0033 / mirrors ADR-0014) ----------
  // Bytes stay OUT of the settings JSON; the snapshot carries only logoRev.

  // Stream the JPEG bytes. Ungated, matching the open GET /venue/settings.
  r.get('/venue/logo', (Request req) async {
    final row = await _readOrSeed(db);
    if (row.logo == null) return Response.notFound('no logo');
    return Response.ok(row.logo, headers: {
      'content-type': 'image/jpeg',
      'cache-control': 'no-cache',
    });
  });

  // Replace the logo. Body = raw JPEG bytes. Bumps logoRev, broadcasts.
  r.put('/venue/logo', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final row = await _readOrSeed(db);
    final builder = await req
        .read()
        .fold<BytesBuilder>(BytesBuilder(), (b, chunk) => b..add(chunk));
    final bytes = builder.takeBytes();
    if (bytes.isEmpty) return Response(400, body: 'empty body');
    await (db.update(db.venueSettings)..where((t) => t.id.equals(_singletonId)))
        .write(VenueSettingsCompanion(
      logo: Value(bytes),
      logoRev: Value(row.logoRev + 1),
    ));
    final updated = await _readOrSeed(db);
    final payload = _toJson(updated);
    hub.broadcast(WsEventTypes.venueSettingsUpdated, payload);
    return Response.ok(jsonEncode(payload),
        headers: {'content-type': 'application/json'});
  });

  // Clear the logo (back to a text-only header). Bumps logoRev, broadcasts.
  r.delete('/venue/logo', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final row = await _readOrSeed(db);
    await (db.update(db.venueSettings)..where((t) => t.id.equals(_singletonId)))
        .write(VenueSettingsCompanion(
      logo: const Value(null),
      logoRev: Value(row.logoRev + 1),
    ));
    final updated = await _readOrSeed(db);
    final payload = _toJson(updated);
    hub.broadcast(WsEventTypes.venueSettingsUpdated, payload);
    return Response.ok(jsonEncode(payload),
        headers: {'content-type': 'application/json'});
  });

  // Guest plane network info — the LAN IPv4 the server is reachable at, the
  // cleartext guest port (ADR-0027), and the base URL guests load by scanning a
  // table QR. Used by the admin Floor screen to render per-table QR codes and
  // by the master toggle card to surface the address. Staff-gated.
  r.get('/venue/guest-net', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final ip = await _lanIpv4();
    const port = 8080; // SatServer.guestPort — kept literal to avoid an import cycle.
    return Response.ok(
        jsonEncode({
          'lanIp': ip,
          'guestPort': port,
          'guestBaseUrl': ip == null ? null : 'http://$ip:$port',
        }),
        headers: {'content-type': 'application/json'});
  });

  return r;
}

String _validMode(String m) =>
    (m == 'fixed') ? 'fixed' : 'percent';

Future<VenueSetting> _readOrSeed(AppDatabase db) async {
  final existing = await (db.select(db.venueSettings)
        ..where((t) => t.id.equals(_singletonId)))
      .getSingleOrNull();
  if (existing != null) return existing;
  await db.into(db.venueSettings).insertOnConflictUpdate(
        VenueSettingsCompanion.insert(id: _singletonId),
      );
  return (db.select(db.venueSettings)
        ..where((t) => t.id.equals(_singletonId)))
      .getSingle();
}

Map<String, dynamic> _toJson(VenueSetting s) => {
      'id': s.id,
      'displayName': s.displayName,
      'legalName': s.legalName,
      'address': s.address,
      'phone': s.phone,
      'receiptHeader': s.receiptHeader,
      'receiptFooter': s.receiptFooter,
      'receiptTagline': s.receiptTagline,
      'receiptSocial': s.receiptSocial,
      'receiptThankYou': s.receiptThankYou,
      'receiptQrUrl': s.receiptQrUrl,
      'receiptQrCaption': s.receiptQrCaption,
      'logoRev': s.logoRev,
      'taxEnabled': s.taxEnabled,
      'taxRateBps': s.taxRateBps,
      'serviceEnabled': s.serviceEnabled,
      'serviceMode': s.serviceMode,
      'serviceRateBps': s.serviceRateBps,
      'serviceFixedAmount': s.serviceFixedAmount,
      'taxAfterDiscount': s.taxAfterDiscount,
      'businessDayStartHour': s.businessDayStartHour,
      'prepTargetMins': s.prepTargetMins,
      'pickupTargetMins': s.pickupTargetMins,
      'ungreetedMins': s.ungreetedMins,
      'ungreetedEscalateMins': s.ungreetedEscalateMins,
      'longStayMins': s.longStayMins,
      'idleTableMins': s.idleTableMins,
      'reservationGraceMins': s.reservationGraceMins,
      'pendingReviewMins': s.pendingReviewMins,
      'ungreetedAlertEnabled': s.ungreetedAlertEnabled,
      'pickupAlertEnabled': s.pickupAlertEnabled,
      'guestOrderingEnabled': s.guestOrderingEnabled,
      'soundNewOrder': s.soundNewOrder,
      'soundReady': s.soundReady,
      'soundVoid': s.soundVoid,
      'soundOverdue': s.soundOverdue,
      'soundUngreeted': s.soundUngreeted,
      'soundPickup': s.soundPickup,
    };

/// Best-effort private LAN IPv4 the server is reachable at, for building guest
/// QR URLs. Prefers a 192.168/10/172.16-31 address on a non-loopback interface;
/// returns null if none (e.g. Wi-Fi down) so the UI can warn instead of baking a
/// dead URL into a QR.
Future<String?> _lanIpv4() async {
  try {
    final ifaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    String? fallback;
    for (final iface in ifaces) {
      for (final addr in iface.addresses) {
        final ip = addr.address;
        fallback ??= ip;
        if (ip.startsWith('192.168.') ||
            ip.startsWith('10.') ||
            _is172Private(ip)) {
          return ip;
        }
      }
    }
    return fallback;
  } catch (_) {
    return null;
  }
}

bool _is172Private(String ip) {
  if (!ip.startsWith('172.')) return false;
  final parts = ip.split('.');
  if (parts.length < 2) return false;
  final second = int.tryParse(parts[1]) ?? 0;
  return second >= 16 && second <= 31;
}
