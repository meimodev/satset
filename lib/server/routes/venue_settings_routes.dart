import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/server/audit_log.dart';
import 'package:satset/domain/models/capability.dart';

const _singletonId = 'default';

Future<Response?> _requireCap(
  Request req,
  AppDatabase db,
  ServerAuth auth,
  Capability needed,
) async {
  final token = req.headers['authorization']?.replaceFirst(
    RegExp(r'^[Bb]earer\s+'),
    '',
  );
  final user = await auth.resolveBearer(token);
  if (user == null) return Response(401);
  final role = await (db.select(
    db.roles,
  )..where((r) => r.id.equals(user.roleId))).getSingleOrNull();
  final caps = role == null
      ? const <String>[]
      : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
  if (!caps.contains(needed.name)) {
    return Response(
      403,
      body: jsonEncode({
        'code': 'forbidden',
        'message': 'missing capability ${needed.name}',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
  return null;
}

Router venueSettingsRoutes(AppDatabase db, WsHub hub, ServerAuth auth) {
  final r = Router();

  r.get('/venue/settings', (Request req) async {
    final row = await _readOrSeed(db);
    return Response.ok(
      jsonEncode(_toJson(row)),
      headers: {'content-type': 'application/json'},
    );
  });

  r.patch('/venue/settings', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final before = await _readOrSeed(db);
    await (db.update(
      db.venueSettings,
    )..where((t) => t.id.equals(_singletonId))).write(
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
            ? Value(
                ((body['businessDayStartHour'] as num).toInt()).clamp(0, 23),
              )
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
                ((body['ungreetedEscalateMins'] as num).toInt()).clamp(1, 60),
              )
            : const Value.absent(),
        longStayMins: body.containsKey('longStayMins')
            ? Value(((body['longStayMins'] as num).toInt()).clamp(15, 480))
            : const Value.absent(),
        idleTableMins: body.containsKey('idleTableMins')
            ? Value(((body['idleTableMins'] as num).toInt()).clamp(5, 240))
            : const Value.absent(),
        reservationGraceMins: body.containsKey('reservationGraceMins')
            ? Value(
                ((body['reservationGraceMins'] as num).toInt()).clamp(0, 240),
              )
            : const Value.absent(),
        ungreetedAlertEnabled: body.containsKey('ungreetedAlertEnabled')
            ? Value(body['ungreetedAlertEnabled'] == true)
            : const Value.absent(),
        pickupAlertEnabled: body.containsKey('pickupAlertEnabled')
            ? Value(body['pickupAlertEnabled'] == true)
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
        // [[Modul]] (ADR-0107). Cloud-owned: the *only* legitimate writer is the
        // host's venue-doc mirror, which patches through this route like any
        // other client. No screen offers it, and a venue cannot buy itself a
        // module by PATCHing one in — the mirror overwrites on the next
        // snapshot, and the cloud doc is function-only.
        modules: body.containsKey('modules')
            ? Value(_modulesText(body['modules']))
            : const Value.absent(),
        // Membership (ADR-0091). Switching the program off leaves every row
        // standing — a balance is a debt to a guest, not a feature flag, so the
        // ledger freezes rather than clears.
        membersEnabled: body.containsKey('membersEnabled')
            ? Value(body['membersEnabled'] == true)
            : const Value.absent(),
        memberPointsEnabled: body.containsKey('memberPointsEnabled')
            ? Value(body['memberPointsEnabled'] == true)
            : const Value.absent(),
        memberPunchEnabled: body.containsKey('memberPunchEnabled')
            ? Value(body['memberPunchEnabled'] == true)
            : const Value.absent(),
        // Pointers, both nullable: a venue may run membership on points alone,
        // or on stempel alone.
        memberPresetId: body.containsKey('memberPresetId')
            ? Value(_idOrNull(body['memberPresetId']))
            : const Value.absent(),
        memberPunchItemId: body.containsKey('memberPunchItemId')
            ? Value(_idOrNull(body['memberPunchItemId']))
            : const Value.absent(),
        // Clamped for the reason the alert thresholds are: "off" is the flag
        // above, never a degenerate rate that silently earns nothing.
        memberEarnPerThousand: body.containsKey('memberEarnPerThousand')
            ? Value(
                ((body['memberEarnPerThousand'] as num).toInt()).clamp(1, 100),
              )
            : const Value.absent(),
        memberPointValue: body.containsKey('memberPointValue')
            ? Value(
                ((body['memberPointValue'] as num).toInt()).clamp(1, 1000000),
              )
            : const Value.absent(),
        memberRedeemMin: body.containsKey('memberRedeemMin')
            ? Value(((body['memberRedeemMin'] as num).toInt()).clamp(1, 100000))
            : const Value.absent(),
        memberPunchTarget: body.containsKey('memberPunchTarget')
            ? Value(((body['memberPunchTarget'] as num).toInt()).clamp(2, 100))
            : const Value.absent(),
        // [[Piutang]] (ADR-0098). The venue limit is deliberately clamped from
        // **0**, unlike the rates above: zero is the meaningful default here —
        // switching tabs on grants nobody one until an owner names a number.
        memberDebtEnabled: body.containsKey('memberDebtEnabled')
            ? Value(body['memberDebtEnabled'] == true)
            : const Value.absent(),
        memberDebtLimit: body.containsKey('memberDebtLimit')
            ? Value(
                ((body['memberDebtLimit'] as num).toInt()).clamp(0, 1000000000),
              )
            : const Value.absent(),
        memberDebtOverdueDays: body.containsKey('memberDebtOverdueDays')
            ? Value(
                ((body['memberDebtOverdueDays'] as num).toInt()).clamp(1, 365),
              )
            : const Value.absent(),
        // [[Pesan mandiri]] (ADR-0105). The master switch decides whether the
        // cleartext guest listener binds at all, which is why flipping it needs
        // a server restart to take effect — the router is built once at boot.
        guestOrderingEnabled: body.containsKey('guestOrderingEnabled')
            ? Value(body['guestOrderingEnabled'] == true)
            : const Value.absent(),
        guestNoteEnabled: body.containsKey('guestNoteEnabled')
            ? Value(body['guestNoteEnabled'] == true)
            : const Value.absent(),
        // Minutes from midnight. Equal values ⇒ no window, the default.
        guestHoursStartMin: body.containsKey('guestHoursStartMin')
            ? Value(((body['guestHoursStartMin'] as num).toInt()).clamp(0, 1439))
            : const Value.absent(),
        guestHoursEndMin: body.containsKey('guestHoursEndMin')
            ? Value(((body['guestHoursEndMin'] as num).toInt()).clamp(0, 1439))
            : const Value.absent(),
        guestMaxItems: body.containsKey('guestMaxItems')
            ? Value(((body['guestMaxItems'] as num).toInt()).clamp(1, 99))
            : const Value.absent(),
        guestSessionHours: body.containsKey('guestSessionHours')
            ? Value(((body['guestSessionHours'] as num).toInt()).clamp(1, 24))
            : const Value.absent(),
        soundGuestPending: body.containsKey('soundGuestPending')
            ? Value(body['soundGuestPending'] as String?)
            : const Value.absent(),
      ),
    );
    final row = await _readOrSeed(db);
    // Audited because it changes what the venue exposes to the street, not
    // merely how a screen looks. Two kinds rather than one with a state param:
    // a log line is composed from a code, and "on" is not a code (ADR-0085).
    if (row.guestOrderingEnabled != before.guestOrderingEnabled) {
      final token = req.headers['authorization']?.replaceFirst(
        RegExp(r'^[Bb]earer\s+'),
        '',
      );
      await writeAudit(
        db,
        type: AuditType.selfOrder,
        kind: row.guestOrderingEnabled
            ? AuditKind.guestOrderingEnabled
            : AuditKind.guestOrderingDisabled,
        actorUserId: (await auth.resolveBearer(token))?.id,
        hub: hub,
      );
    }
    final payload = _toJson(row);
    hub.broadcast(WsEventTypes.venueSettingsUpdated, payload);
    return Response.ok(
      jsonEncode(payload),
      headers: {'content-type': 'application/json'},
    );
  });

  // ---------- logo (binary side-endpoints, ADR-0033 / mirrors ADR-0014) ----------
  // Bytes stay OUT of the settings JSON; the snapshot carries only logoRev.

  // Stream the JPEG bytes. Ungated, matching the open GET /venue/settings.
  r.get('/venue/logo', (Request req) async {
    final row = await _readOrSeed(db);
    if (row.logo == null) return Response.notFound('no logo');
    return Response.ok(
      row.logo,
      headers: {'content-type': 'image/jpeg', 'cache-control': 'no-cache'},
    );
  });

  // Replace the logo. Body = raw JPEG bytes. Bumps logoRev, broadcasts.
  r.put('/venue/logo', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final row = await _readOrSeed(db);
    final builder = await req.read().fold<BytesBuilder>(
      BytesBuilder(),
      (b, chunk) => b..add(chunk),
    );
    final bytes = builder.takeBytes();
    if (bytes.isEmpty) return Response(400, body: 'empty body');
    await (db.update(
      db.venueSettings,
    )..where((t) => t.id.equals(_singletonId))).write(
      VenueSettingsCompanion(
        logo: Value(bytes),
        logoRev: Value(row.logoRev + 1),
      ),
    );
    final updated = await _readOrSeed(db);
    final payload = _toJson(updated);
    hub.broadcast(WsEventTypes.venueSettingsUpdated, payload);
    return Response.ok(
      jsonEncode(payload),
      headers: {'content-type': 'application/json'},
    );
  });

  // Clear the logo (back to a text-only header). Bumps logoRev, broadcasts.
  r.delete('/venue/logo', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final row = await _readOrSeed(db);
    await (db.update(
      db.venueSettings,
    )..where((t) => t.id.equals(_singletonId))).write(
      VenueSettingsCompanion(
        logo: const Value(null),
        logoRev: Value(row.logoRev + 1),
      ),
    );
    final updated = await _readOrSeed(db);
    final payload = _toJson(updated);
    hub.broadcast(WsEventTypes.venueSettingsUpdated, payload);
    return Response.ok(
      jsonEncode(payload),
      headers: {'content-type': 'application/json'},
    );
  });

  return r;
}

String _validMode(String m) => (m == 'fixed') ? 'fixed' : 'percent';

/// An empty string clears a pointer — the sheets send `''` for "none" rather
/// than omitting the key, which would mean "leave it alone".
/// [[Modul]] on the wire is a list of keys; at rest it is one comma-joined
/// string. Anything else — a string, a null, a stray type — reads as "no
/// modules" rather than throwing: this field arrives from the host's own mirror,
/// and a malformed patch must not take the settings route down with it.
String? _modulesText(Object? raw) => switch (raw) {
  final List l => joinModules(l.whereType<String>()),
  final String s => joinModules(splitModules(s)),
  // An explicit null restores "never mirrored", which is the state a venue is
  // in before its cloud doc lands. Nothing sends it today; refusing it would
  // make the column one-way.
  _ => null,
};

String? _idOrNull(Object? raw) {
  if (raw is! String) return null;
  final t = raw.trim();
  return t.isEmpty ? null : t;
}

Future<VenueSetting> _readOrSeed(AppDatabase db) async {
  final existing = await (db.select(
    db.venueSettings,
  )..where((t) => t.id.equals(_singletonId))).getSingleOrNull();
  if (existing != null) return existing;
  await db
      .into(db.venueSettings)
      .insertOnConflictUpdate(VenueSettingsCompanion.insert(id: _singletonId));
  return (db.select(
    db.venueSettings,
  )..where((t) => t.id.equals(_singletonId))).getSingle();
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
  'ungreetedAlertEnabled': s.ungreetedAlertEnabled,
  'pickupAlertEnabled': s.pickupAlertEnabled,
  'soundNewOrder': s.soundNewOrder,
  'soundReady': s.soundReady,
  'soundVoid': s.soundVoid,
  'soundOverdue': s.soundOverdue,
  'soundUngreeted': s.soundUngreeted,
  'soundPickup': s.soundPickup,
  // Membership (ADR-0091). Readable by anyone, like the rest of this snapshot:
  // the bill overlay needs to know whether the program is running before it can
  // decide whether to offer a member row.
  'membersEnabled': s.membersEnabled,
  'memberPointsEnabled': s.memberPointsEnabled,
  'memberPunchEnabled': s.memberPunchEnabled,
  'memberPresetId': s.memberPresetId,
  'memberEarnPerThousand': s.memberEarnPerThousand,
  'memberPointValue': s.memberPointValue,
  'memberRedeemMin': s.memberRedeemMin,
  'memberPunchItemId': s.memberPunchItemId,
  'memberPunchTarget': s.memberPunchTarget,
  'memberDebtEnabled': s.memberDebtEnabled,
  'memberDebtLimit': s.memberDebtLimit,
  'memberDebtOverdueDays': s.memberDebtOverdueDays,
  // [[Pesan mandiri]] (ADR-0105). Readable like the rest: the client decides
  // whether to draw the hub tile before it has any right to change anything.
  'guestOrderingEnabled': s.guestOrderingEnabled,
  'guestNoteEnabled': s.guestNoteEnabled,
  'guestHoursStartMin': s.guestHoursStartMin,
  'guestHoursEndMin': s.guestHoursEndMin,
  'guestMaxItems': s.guestMaxItems,
  'guestSessionHours': s.guestSessionHours,
  'soundGuestPending': s.soundGuestPending,
  // [[Modul]] (ADR-0107) — a list on the wire, comma-joined at rest. Readable
  // like the rest of this snapshot: a client has to know which modules the venue
  // holds before it can decide whether to draw a locked tile.
  'modules': s.modules == null ? null : splitModules(s.modules).toList(),
};
