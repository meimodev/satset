import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/domain/models/release_gate.dart';

/// Liveness probe, and the one carrier of the release gate that a client can
/// read **before it logs in** (ADR-0087).
///
/// `/healthz` is in the auth middleware's skip set and is already polled by
/// `ping_repository`, which is exactly why the gate rides here rather than on a
/// route of its own: the block has to bite before the PIN screen, and a kitchen
/// tablet parked at PIN for an hour is the device most likely to be stale.
///
/// [gate] is a callback, not a value, because the runtime's gate changes under
/// the router — the router is built once at boot and never rebuilt.
Router healthRoutes(ReleaseGate Function() gate) {
  final r = Router();
  r.get('/healthz', (Request req) {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'service': 'satset',
        // Absent when the host has never seen the cloud. A client reading no
        // gate keeps whatever it cached and blocks nobody new.
        if (!gate().isEmpty) 'releaseGate': gate().toJson(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });
  return r;
}
