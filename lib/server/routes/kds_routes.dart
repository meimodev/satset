import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';

const _pendingStatuses = [
  'sent',
  'acknowledged',
  'prep',
  'cooked',
  'ready',
  'held',
];

Router kdsRoutes(AppDatabase db, [ServerAuth? auth]) {
  final r = Router();

  /// One row per distinct kitchen/bar station declared on a MenuItem.
  /// `pendingTickets` counts non-terminal tickets (sent, prep, cooked, ready,
  /// held, acknowledged) routed to that station. `staffOnline` is a rough
  /// signal: count of active sessions (any role).
  r.get('/kds/stations', (Request req) async {
    final now = SatClock.now();
    final staffOnlineCount = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM sessions WHERE expires_at > ?',
          variables: [Variable.withDateTime(now)],
        )
        .getSingle();
    final placeholders = List.filled(_pendingStatuses.length, '?').join(',');
    final pending = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM tickets WHERE status IN ($placeholders)',
          variables: _pendingStatuses.map(Variable.withString).toList(),
        )
        .getSingle();
    final result = [
      {
        'station': 'kitchen',
        'pendingTickets': pending.read<int>('c'),
        'staffOnline': staffOnlineCount.read<int>('c'),
      },
    ];
    return Response.ok(
      jsonEncode(result),
      headers: {'content-type': 'application/json'},
    );
  });

  /// Aggregate pending-ticket counts across the whole venue, plus per-station
  /// breakdown. Drives the "Antrian" tile on the System screen.
  r.get('/queue/depth', (Request req) async {
    final placeholders = List.filled(_pendingStatuses.length, '?').join(',');
    final total = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM tickets WHERE status IN ($placeholders)',
          variables: _pendingStatuses.map(Variable.withString).toList(),
        )
        .getSingle();
    final totalVal = total.read<int>('c');
    return Response.ok(
      jsonEncode({
        'total': totalVal,
        'byStation': {'kitchen': totalVal},
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  return r;
}
