import 'dart:convert';

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
        businessDayStartHour: body.containsKey('businessDayStartHour')
            ? Value(((body['businessDayStartHour'] as num).toInt()).clamp(0, 23))
            : const Value.absent(),
      ),
    );
    final row = await _readOrSeed(db);
    final payload = _toJson(row);
    hub.broadcast(WsEventTypes.venueSettingsUpdated, payload);
    return Response.ok(jsonEncode(payload),
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
      'taxEnabled': s.taxEnabled,
      'taxRateBps': s.taxRateBps,
      'serviceEnabled': s.serviceEnabled,
      'serviceMode': s.serviceMode,
      'serviceRateBps': s.serviceRateBps,
      'serviceFixedAmount': s.serviceFixedAmount,
      'businessDayStartHour': s.businessDayStartHour,
    };
