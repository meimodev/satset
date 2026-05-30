import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/domain/models/capability.dart';

/// Default business-day start hour when VenueSettings is unreachable.
const _defaultBusinessDayStartHour = 4;

/// Permission gate copied from tickets_routes._requireCap. Inlined to avoid
/// cross-file coupling; if a third route needs this, extract to a shared
/// helper.
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

(DateTime, DateTime) _windowFor(String range, DateTime now, int hour) {
  DateTime bod(DateTime d) => DateTime(d.year, d.month, d.day, hour);
  final today = bod(now);
  final tomorrow = today.add(const Duration(days: 1));
  switch (range) {
    case 'yesterday':
      return (today.subtract(const Duration(days: 1)), today);
    case 'd7':
      return (tomorrow.subtract(const Duration(days: 7)), tomorrow);
    case 'd30':
      return (tomorrow.subtract(const Duration(days: 30)), tomorrow);
    case 'month':
      return (
        DateTime(now.year, now.month, 1, hour),
        tomorrow,
      );
    case 'today':
    default:
      return (today, tomorrow);
  }
}

Router reportsRoutes(AppDatabase db, [ServerAuth? auth]) {
  final r = Router();

  r.get('/reports/snapshot', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.viewReports);
    if (denied != null) return denied;

    final qp = req.url.queryParameters;
    final range = qp['range'] ?? 'today';
    final serverFilter = qp['server'];
    final zoneFilter = qp['zone'];
    final categoryFilter = qp['category'];

    final now = DateTime.now();
    final settings = await (db.select(db.venueSettings)
          ..where((s) => s.id.equals('default')))
        .getSingleOrNull();
    final hour = settings?.businessDayStartHour ?? _defaultBusinessDayStartHour;
    final (from, to) = _windowFor(range, now, hour);

    // Reference data — small, fetched in full.
    final menu = await db.select(db.menuItems).get();
    final categories = await (db.select(db.menuCategories)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
    final zones = await db.select(db.zones).get();
    final users = await db.select(db.users).get();
    final waiters = users
        .where((u) =>
            u.roleId == 'role-waiter' ||
            u.roleId == 'role-manager' ||
            u.roleId == 'role-admin')
        .toList();
    final itemById = {for (final m in menu) m.id: m};
    final catById = {for (final c in categories) c.id: c};
    final userById = {for (final u in users) u.id: u};

    // Window sessions + tickets.
    var sessionsQuery = db.select(db.tableSessions)
      ..where((s) => s.closedAt.isBetweenValues(from, to));
    if (serverFilter != null && serverFilter.isNotEmpty) {
      sessionsQuery = sessionsQuery
        ..where((s) => s.actorUserId.equals(serverFilter));
    }
    if (zoneFilter != null && zoneFilter.isNotEmpty) {
      sessionsQuery = sessionsQuery..where((s) => s.zoneId.equals(zoneFilter));
    }
    final sessions = await sessionsQuery.get();
    final sessionIds = sessions.map((s) => s.id).toList();

    List<TableSessionTicket> tickets = [];
    if (sessionIds.isNotEmpty) {
      tickets = await (db.select(db.tableSessionTickets)
            ..where((t) => t.sessionId.isIn(sessionIds)))
          .get();
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        tickets = tickets
            .where((t) => itemById[t.itemId]?.categoryId == categoryFilter)
            .toList();
      }
    }

    // Compute previous-week tickets/sessions for WoW comparison.
    final prevFrom = from.subtract(const Duration(days: 7));
    final prevTo = to.subtract(const Duration(days: 7));
    final prevSessions = await (db.select(db.tableSessions)
          ..where((s) => s.closedAt.isBetweenValues(prevFrom, prevTo)))
        .get();
    final prevSessionIds = prevSessions.map((s) => s.id).toList();
    final prevTickets = prevSessionIds.isEmpty
        ? <TableSessionTicket>[]
        : await (db.select(db.tableSessionTickets)
              ..where((t) => t.sessionId.isIn(prevSessionIds)))
            .get();

    // ─── SALES ──────────────────────────────────────────────────
    final gross = sessions.fold<int>(0, (a, s) => a + s.subtotal);
    final voidTotal = sessions.fold<int>(0, (a, s) => a + s.voidAmount);
    final net = sessions.fold<int>(0, (a, s) => a + s.netTotal);
    final covers = sessions.fold<int>(0, (a, s) => a + s.pax);
    final sessionCount = sessions.length;
    final taxService = (net * 0.18).round();
    final salesKpis = [
      {'label': 'Net', 'value': _formatRupiah(net), 'sub': '$sessionCount sesi · $covers tamu'},
      {'label': 'Gross', 'value': _formatRupiah(gross), 'sub': '$sessionCount transaksi'},
      {'label': 'Pajak + Service', 'value': _formatRupiah(taxService), 'sub': 'PB1 11% · Svc 7% (est)'},
      {'label': 'Void', 'value': _formatRupiah(voidTotal), 'sub': '${_voidLineCount(tickets)} item void'},
    ];

    // Cover trend: group sessions by weekday for this/last week (7 days only).
    final coverTrend = <Map<String, dynamic>>[];
    const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    for (var dow = 1; dow <= 7; dow++) {
      final thisWk = sessions
          .where((s) => s.closedAt.weekday == dow)
          .fold<int>(0, (a, s) => a + s.pax);
      final lastWk = prevSessions
          .where((s) => s.closedAt.weekday == dow)
          .fold<int>(0, (a, s) => a + s.pax);
      coverTrend.add({'day': dayLabels[dow - 1], 'thisWeek': thisWk, 'lastWeek': lastWk});
    }

    // Hourly revenue: 12 bars 11..22. Sum qty*price from tickets.
    final hourly = <double>[];
    for (var h = 11; h <= 22; h++) {
      final sum = tickets
          .where((t) => t.sentAt.hour == h && t.status != 'voided')
          .fold<int>(0, (a, t) => a + t.price * t.qty);
      hourly.add(sum.toDouble());
    }
    final hourlyMax = hourly.fold<double>(0, (a, b) => b > a ? b : a);
    final hourlyNorm =
        hourly.map((v) => hourlyMax == 0 ? 0.0 : (v / hourlyMax)).toList();

    // ─── STAFF ──────────────────────────────────────────────────
    final staffRows = <Map<String, dynamic>>[];
    final byStaff = <String, List<TableSession>>{};
    for (final s in sessions) {
      if (s.actorUserId == null) continue;
      byStaff.putIfAbsent(s.actorUserId!, () => []).add(s);
    }
    for (final entry in byStaff.entries) {
      final list = entry.value;
      final user = userById[entry.key];
      final covers = list.fold<int>(0, (a, s) => a + s.pax);
      final items = list.fold<int>(0, (a, s) => a + s.ticketCount);
      final netSum = list.fold<int>(0, (a, s) => a + s.netTotal);
      final grossSum = list.fold<int>(0, (a, s) => a + s.subtotal);
      final voidSum = list.fold<int>(0, (a, s) => a + s.voidAmount);
      final avgTicket = list.isEmpty ? 0 : netSum / list.length;
      final voidPct = grossSum == 0 ? 0.0 : (voidSum / grossSum * 100);
      staffRows.add({
        'id': entry.key,
        'name': user?.name ?? entry.key,
        'covers': covers,
        'items': items,
        'avgTicket': avgTicket.round(),
        'voidPct': voidPct,
        'net': netSum,
        'sessions': list.length,
      });
    }
    staffRows.sort((a, b) => (b['net'] as int).compareTo(a['net'] as int));

    // Upsell index: per staff, % sessions with ≥1 starter AND ≥1 main.
    final ticketsBySession = <String, List<TableSessionTicket>>{};
    for (final t in tickets) {
      ticketsBySession.putIfAbsent(t.sessionId, () => []).add(t);
    }
    final upsell = <Map<String, dynamic>>[];
    for (final entry in byStaff.entries) {
      final list = entry.value;
      var withUpsell = 0;
      for (final s in list) {
        final ts = ticketsBySession[s.id] ?? const <TableSessionTicket>[];
        final cats = ts
            .map((t) => itemById[t.itemId]?.categoryId)
            .whereType<String>()
            .toSet();
        final hasStarter = cats.contains('starters');
        final hasMain = cats.contains('mains');
        if (hasStarter && hasMain) withUpsell++;
      }
      final user = userById[entry.key];
      upsell.add({
        'id': entry.key,
        'name': user?.name ?? entry.key,
        'rate': list.isEmpty ? 0.0 : (withUpsell / list.length),
      });
    }
    upsell.sort((a, b) => (b['rate'] as double).compareTo(a['rate'] as double));

    // ─── MENU ───────────────────────────────────────────────────
    final byItem = <String, _ItemAgg>{};
    for (final t in tickets) {
      if (t.status == 'voided') continue;
      final agg = byItem.putIfAbsent(t.itemId, () => _ItemAgg());
      agg.qty += t.qty;
      agg.revenue += t.price * t.qty;
    }
    final itemList = byItem.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));
    final menuMax = itemList.isEmpty ? 1 : itemList.first.value.revenue;

    List<Map<String, dynamic>> menuRows(Iterable<MapEntry<String, _ItemAgg>> iter) =>
        iter.map((e) {
          final item = itemById[e.key];
          final cost = item?.cost ?? 0;
          final marginPct = item == null || item.basePrice == 0
              ? 0
              : ((item.basePrice - cost) / item.basePrice * 100).round();
          return {
            'itemId': e.key,
            'name': item?.name ?? e.key,
            'qty': e.value.qty,
            'revenue': e.value.revenue,
            'marginPct': marginPct,
            'fill': menuMax == 0 ? 0.0 : (e.value.revenue / menuMax).clamp(0.0, 1.0),
          };
        }).toList();

    final menuTop = menuRows(itemList.take(5));
    final menuSlow = menuRows(itemList.reversed.take(5));

    // Modifier attach: group key before colon.
    final modCounts = <String, int>{};
    final modLabels = {
      'spice': 'Tingkat pedas',
      'extras': 'Tambahan',
      'sauce': 'Saus',
      'protein': 'Pilih protein',
    };
    for (final t in tickets) {
      try {
        final mods = (jsonDecode(t.modifiersJson) as List).cast<String>();
        for (final m in mods) {
          final key = m.split(':').first;
          modCounts[key] = (modCounts[key] ?? 0) + 1;
        }
      } catch (_) {}
    }
    final modifierAttach = modCounts.entries
        .map((e) => {
              'group': modLabels[e.key] ?? e.key,
              'rate': tickets.isEmpty ? 0.0 : e.value / tickets.length,
            })
        .toList()
      ..sort((a, b) => (b['rate'] as double).compareTo(a['rate'] as double));

    // Category mix WoW.
    final catThis = <String, int>{};
    final catLast = <String, int>{};
    for (final t in tickets) {
      if (t.status == 'voided') continue;
      final cid = itemById[t.itemId]?.categoryId;
      if (cid == null) continue;
      catThis[cid] = (catThis[cid] ?? 0) + (t.price * t.qty);
    }
    for (final t in prevTickets) {
      if (t.status == 'voided') continue;
      final cid = itemById[t.itemId]?.categoryId;
      if (cid == null) continue;
      catLast[cid] = (catLast[cid] ?? 0) + (t.price * t.qty);
    }
    final catThisTotal = catThis.values.fold<int>(0, (a, b) => a + b);
    final catLastTotal = catLast.values.fold<int>(0, (a, b) => a + b);
    final categoryMix = catThis.entries.map((e) {
      final share = catThisTotal == 0 ? 0.0 : e.value / catThisTotal;
      final prevShare = catLastTotal == 0 ? 0.0 : (catLast[e.key] ?? 0) / catLastTotal;
      return {
        'id': e.key,
        'name': catById[e.key]?.name ?? e.key,
        'shareThisWeek': share,
        'shareLastWeek': prevShare,
      };
    }).toList()
      ..sort((a, b) => (b['shareThisWeek'] as double)
          .compareTo(a['shareThisWeek'] as double));

    // Menu engineering matrix.
    final qtyMax = itemList.isEmpty
        ? 1
        : itemList.map((e) => e.value.qty).reduce((a, b) => a > b ? a : b);
    final marginVals = itemList.map((e) {
      final m = itemById[e.key];
      if (m == null || m.basePrice == 0) return 0.0;
      return (m.basePrice - m.cost) / m.basePrice;
    }).toList();
    final medianMargin = marginVals.isEmpty ? 0.5 : _median(marginVals);
    final medianPop = itemList.isEmpty ? 0.5 : 0.5; // qtyMax-relative threshold
    final menuMatrix = itemList.map((e) {
      final m = itemById[e.key];
      final pop = qtyMax == 0 ? 0.0 : e.value.qty / qtyMax;
      final margin = m == null || m.basePrice == 0
          ? 0.0
          : (m.basePrice - m.cost) / m.basePrice;
      String q;
      if (pop >= medianPop && margin >= medianMargin) {
        q = 'star';
      } else if (pop >= medianPop && margin < medianMargin) {
        q = 'plow';
      } else if (pop < medianPop && margin >= medianMargin) {
        q = 'puzzle';
      } else {
        q = 'dog';
      }
      return {
        'itemId': e.key,
        'name': m?.name ?? e.key,
        'popularity': pop,
        'margin': margin,
        'quadrant': q,
      };
    }).toList();

    // Basket pairs: within session, generate item pairs.
    final pairCounts = <String, int>{};
    final pairNames = <String, List<String>>{};
    for (final entry in ticketsBySession.entries) {
      final items = entry.value.map((t) => t.itemId).toSet().toList()..sort();
      for (var i = 0; i < items.length; i++) {
        for (var j = i + 1; j < items.length; j++) {
          final key = '${items[i]}|${items[j]}';
          pairCounts[key] = (pairCounts[key] ?? 0) + 1;
          pairNames[key] = [
            itemById[items[i]]?.name ?? items[i],
            itemById[items[j]]?.name ?? items[j],
          ];
        }
      }
    }
    final basketPairs = pairCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final basketTop = basketPairs.take(10).map((e) {
      final names = pairNames[e.key]!;
      final maxN = basketPairs.first.value;
      return {
        'itemA': names[0],
        'itemB': names[1],
        'count': e.value,
        'rate': maxN == 0 ? 0.0 : e.value / maxN,
      };
    }).toList();

    // ─── OPS ────────────────────────────────────────────────────
    final avgTurnSec = sessions.isEmpty
        ? 0
        : sessions.fold<int>(0, (a, s) => a + s.durationSec) ~/ sessions.length;
    final avgTurnMin = avgTurnSec ~/ 60;
    // Time-to-ready proxy: avg (closedAt - earliest sentAt) per session.
    var ttrSecSum = 0;
    var ttrCount = 0;
    for (final s in sessions) {
      final ts = ticketsBySession[s.id];
      if (ts == null || ts.isEmpty) continue;
      final earliest = ts.map((t) => t.sentAt).reduce((a, b) => a.isBefore(b) ? a : b);
      ttrSecSum += s.closedAt.difference(earliest).inSeconds;
      ttrCount++;
    }
    final ttrMin = ttrCount == 0 ? 0 : (ttrSecSum ~/ ttrCount ~/ 60);
    final opsKpis = [
      {'label': 'Avg turn time', 'value': '$avgTurnMin min', 'sub': 'Target 45 min'},
      {'label': 'Time to ready', 'value': '$ttrMin min', 'sub': 'Median order → pass'},
      {'label': 'Ready alerts', 'value': '—', 'sub': 'P2 — perlu event log'},
      {
        'label': 'Reservasi',
        'value': '—',
        'sub': '—', // overwritten below once reservations is computed
      },
    ];

    // Stations: sum qty for the unified station.
    final totalQty = tickets.where((t) => t.status != 'voided').fold<int>(0, (a, t) => a + t.qty);
    final stations = [
      {
        'station': 'kitchen',
        'label': 'Dapur Utama',
        'qty': totalQty,
        'utilization': totalQty == 0 ? 0.0 : 1.0,
      }
    ];

    // Heatmap: 7 weekdays × 12 hours (11..22).
    final heatRaw = List.generate(7, (_) => List.filled(12, 0));
    for (final s in sessions) {
      final dow = s.closedAt.weekday - 1; // 0..6
      final hour = s.closedAt.hour;
      if (hour < 11 || hour > 22) continue;
      heatRaw[dow][hour - 11] += 1;
    }
    final heatMax = heatRaw
        .expand((row) => row)
        .fold<int>(0, (a, b) => b > a ? b : a);
    final heatmap = heatRaw
        .map((row) =>
            row.map((v) => heatMax == 0 ? 0.0 : v / heatMax).toList())
        .toList();

    // Patch ops KPI #4 with real reservation totals (defined below).
    final reservationRows = await (db.select(db.reservations)
          ..where((r) => r.expectedAt.isBetweenValues(from, to)))
        .get();
    final reservations = {
      'booked': reservationRows.length,
      'seated': reservationRows.where((r) => r.status == 'seated').length,
      'noShow': reservationRows.where((r) => r.status == 'noShow').length,
      'cancelled':
          reservationRows.where((r) => r.status == 'cancelled').length,
    };
    if (opsKpis.length >= 4) {
      opsKpis[3] = {
        'label': 'Reservasi',
        'value':
            '${reservations['seated']} / ${reservations['booked']}',
        'sub':
            '${reservations['noShow']} no-show · ${reservations['cancelled']} batal',
      };
    }

    // Void reasons.
    final reasonAgg = <String, _ReasonAgg>{};
    for (final t in tickets) {
      if (t.status != 'voided') continue;
      final code = t.voidReasonCode ?? 'other';
      final agg = reasonAgg.putIfAbsent(code, () => _ReasonAgg());
      agg.count += 1;
      agg.lostRupiah += t.price * t.qty;
    }
    const reasonLabels = {
      'outOfStock': 'Stok habis',
      'wrongOrder': 'Salah input pelayan',
      'customerChange': 'Tamu ganti pesanan',
      'kitchenError': 'Kualitas dapur',
      'comp': 'Kompensasi manajer',
      'other': 'Lainnya',
    };
    final voidReasons = reasonAgg.entries
        .map((e) => {
              'code': e.key,
              'label': reasonLabels[e.key] ?? e.key,
              'count': e.value.count,
              'lostRupiah': e.value.lostRupiah,
            })
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // Void per waiter — who voided, how often, lost rupiah, top reason.
    // Keyed by voidedByUserId (the acting waiter), distinct from the table's
    // session actor. See ADR-0006.
    final voidByStaff = <String, _StaffVoidAgg>{};
    for (final t in tickets) {
      if (t.status != 'voided') continue;
      final who = t.voidedByUserId ?? 'unknown';
      final agg = voidByStaff.putIfAbsent(who, () => _StaffVoidAgg());
      agg.count += 1;
      agg.lostRupiah += t.price * t.qty;
      final code = t.voidReasonCode ?? 'other';
      agg.reasonCounts[code] = (agg.reasonCounts[code] ?? 0) + 1;
    }
    final voidStaff = voidByStaff.entries.map((e) {
      final topReason = e.value.reasonCounts.entries.isEmpty
          ? 'other'
          : (e.value.reasonCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
      return {
        'id': e.key,
        'name': e.key == 'unknown'
            ? 'Tidak diketahui'
            : (userById[e.key]?.name ?? e.key),
        'count': e.value.count,
        'lostRupiah': e.value.lostRupiah,
        'topReasonCode': topReason,
        'topReasonLabel': reasonLabels[topReason] ?? topReason,
      };
    }).toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // Filter options (always full list — UI prepends "Semua X").
    final filterOptions = {
      'servers': [
        for (final u in waiters) {'id': u.id, 'name': u.name},
      ],
      'zones': [
        for (final z in zones) {'id': z.id, 'name': z.name},
      ],
      'categories': [
        for (final c in categories) {'id': c.id, 'name': c.name},
      ],
    };

    final body = {
      'generatedAt': now.toIso8601String(),
      'rangeFrom': from.toIso8601String(),
      'rangeTo': to.toIso8601String(),
      'range': range,
      'filterOptions': filterOptions,
      'sales': {
        'kpis': salesKpis,
        'coverTrend': coverTrend,
        'hourly': hourlyNorm,
      },
      'staff': {'rows': staffRows, 'upsell': upsell},
      'menu': {
        'top': menuTop,
        'slow': menuSlow,
        'modifierAttach': modifierAttach,
        'categoryMix': categoryMix,
        'matrix': menuMatrix,
        'basketPairs': basketTop,
      },
      'ops': {
        'kpis': opsKpis,
        'stations': stations,
        'heatmap': heatmap,
        'reservations': reservations,
        'voidReasons': voidReasons,
        'voidByStaff': voidStaff,
      },
    };

    return Response.ok(jsonEncode(body),
        headers: {'content-type': 'application/json'});
  });

  return r;
}

class _ItemAgg {
  int qty = 0;
  int revenue = 0;
}

class _ReasonAgg {
  int count = 0;
  int lostRupiah = 0;
}

class _StaffVoidAgg {
  int count = 0;
  int lostRupiah = 0;
  final Map<String, int> reasonCounts = {};
}

int _voidLineCount(List<TableSessionTicket> tickets) =>
    tickets.where((t) => t.status == 'voided').length;

double _median(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isEven
      ? (sorted[mid - 1] + sorted[mid]) / 2
      : sorted[mid];
}

String _formatRupiah(int v) {
  if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
  if (v >= 1000) return 'Rp ${(v / 1000).round()}rb';
  return 'Rp $v';
}
