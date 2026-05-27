import 'dart:convert';

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
    final now = DateTime.now();
    final stations = await db
        .customSelect(
            'SELECT DISTINCT station FROM menu_items WHERE station IS NOT NULL AND station != "" ORDER BY station')
        .get();
    final staffOnlineCount = await db.customSelect(
      'SELECT COUNT(*) AS c FROM sessions WHERE expires_at > ?',
      variables: [Variable.withDateTime(now)],
    ).getSingle();
    final placeholders = List.filled(_pendingStatuses.length, '?').join(',');
    final result = <Map<String, dynamic>>[];
    for (final row in stations) {
      final name = row.read<String>('station');
      final pending = await db.customSelect(
        'SELECT COUNT(*) AS c FROM tickets WHERE station = ? AND status IN ($placeholders)',
        variables: [
          Variable.withString(name),
          ..._pendingStatuses.map(Variable.withString),
        ],
      ).getSingle();
      result.add({
        'station': name,
        'pendingTickets': pending.read<int>('c'),
        'staffOnline': staffOnlineCount.read<int>('c'),
      });
    }
    return Response.ok(
      jsonEncode(result),
      headers: {'content-type': 'application/json'},
    );
  });

  /// Aggregate pending-ticket counts across the whole venue, plus per-station
  /// breakdown. Drives the "Antrian" tile on the System screen.
  r.get('/queue/depth', (Request req) async {
    final placeholders = List.filled(_pendingStatuses.length, '?').join(',');
    final total = await db.customSelect(
      'SELECT COUNT(*) AS c FROM tickets WHERE status IN ($placeholders)',
      variables: _pendingStatuses.map(Variable.withString).toList(),
    ).getSingle();
    final byStation = await db.customSelect(
      'SELECT station, COUNT(*) AS c FROM tickets WHERE status IN ($placeholders) GROUP BY station',
      variables: _pendingStatuses.map(Variable.withString).toList(),
    ).get();
    final map = <String, int>{
      for (final row in byStation)
        row.read<String>('station'): row.read<int>('c'),
    };
    return Response.ok(
      jsonEncode({
        'total': total.read<int>('c'),
        'byStation': map,
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  return r;
}
