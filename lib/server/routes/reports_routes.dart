import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/domain/models/menu_item.dart' show openItemId;
import 'package:satset/server/auth.dart';
import 'package:satset/server/cash.dart';
import 'package:satset/server/debts.dart';
import 'package:satset/server/members.dart';
import 'package:satset/server/shift.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/service_timing.dart';

/// Default business-day start hour when VenueSettings is unreachable.
const _defaultBusinessDayStartHour = 4;

/// Permission gate copied from tickets_routes._requireCap. Inlined to avoid
/// cross-file coupling; if a third route needs this, extract to a shared
/// helper.
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

/// Max span of a custom window, in inclusive days. Mirrors the client cap
/// ([kCustomRangeMaxDays]); enforced here too so a hand-crafted request can't
/// pull an unbounded window.
const int _customRangeMaxDays = 92;

/// How many money-audit rows the snapshot publishes per range (ADR-0086).
///
/// The snapshot is a single Firestore document with a 1 MiB ceiling, and going
/// over does not drop the audit rows — it fails the whole write, taking sales,
/// staff and menu down with it. So the cap is enforced here, and the payload
/// says when it bit rather than showing a quietly short list.
const int _moneyAuditCap = 500;

(DateTime, DateTime) _windowFor(
  String range,
  DateTime now,
  int hour, {
  String? fromStr,
  String? toStr,
}) {
  DateTime bod(DateTime d) => DateTime(d.year, d.month, d.day, hour);
  // "Today" is the business day *containing* now, which before the rollover is
  // yesterday's. Anchoring on the calendar date instead opened a window three
  // hours in the future at 01:00 — last night's trade read as "Kemarin" and
  // everything since midnight belonged to no range at all. `bod` keeps the
  // calendar reading for `custom`, whose dates arrive at midnight already
  // meaning "that day's service".
  final today = businessDayStart(now, hour);
  final tomorrow = today.add(const Duration(days: 1));
  switch (range) {
    case 'yesterday':
      return (today.subtract(const Duration(days: 1)), today);
    case 'd7':
      return (tomorrow.subtract(const Duration(days: 7)), tomorrow);
    case 'd30':
      return (tomorrow.subtract(const Duration(days: 30)), tomorrow);
    case 'month':
      return (DateTime(now.year, now.month, 1, hour), tomorrow);
    case 'custom':
      final f = DateTime.tryParse(fromStr ?? '');
      final t = DateTime.tryParse(toStr ?? '');
      if (f == null || t == null) return (today, tomorrow); // malformed → today
      var start = bod(f);
      // `to` is an inclusive calendar date — the window ends at the next
      // business-day boundary after it (exclusive), like every other range.
      var end = bod(t).add(const Duration(days: 1));
      if (end.isBefore(start)) {
        final tmp = start;
        start = end;
        end = tmp;
      }
      // `end` is exclusive, so the ceiling for N inclusive days is start + N.
      final cap = start.add(const Duration(days: _customRangeMaxDays));
      if (end.isAfter(cap)) end = cap;
      return (start, end);
    case 'today':
    default:
      return (today, tomorrow);
  }
}

Router reportsRoutes(AppDatabase db, ServerAuth auth) {
  final r = Router();

  r.get('/reports/snapshot', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.viewReports);
    if (denied != null) return denied;

    final qp = req.url.queryParameters;
    final range = qp['range'] ?? 'today';
    final serverFilter = qp['server'];
    final zoneFilter = qp['zone'];
    final categoryFilter = qp['category'];

    final now = SatClock.now();
    final settings = await (db.select(
      db.venueSettings,
    )..where((s) => s.id.equals('default'))).getSingleOrNull();
    final hour = settings?.businessDayStartHour ?? _defaultBusinessDayStartHour;
    final (from, to) = _windowFor(
      range,
      now,
      hour,
      fromStr: qp['from'],
      toStr: qp['to'],
    );

    // Reference data — small, fetched in full.
    final menu = await db.select(db.menuItems).get();
    final categories = await (db.select(
      db.menuCategories,
    )..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();
    final zones = await db.select(db.zones).get();
    final users = await db.select(db.users).get();
    final waiters = users
        .where(
          (u) =>
              u.roleId == 'role-waiter' ||
              u.roleId == 'role-manager' ||
              u.roleId == 'role-admin',
        )
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
    // Takeaway (Bawa pulang) sessions count toward sales/menu/payments but are
    // excluded from per-cover / turn-time / occupancy metrics — no table was
    // ever held. See ADR-0026.
    final dineInSessions = sessions.where((s) => s.kind != 'takeaway').toList();
    final takeawaySessions = sessions
        .where((s) => s.kind == 'takeaway')
        .toList();

    List<TableSessionTicket> tickets = [];
    if (sessionIds.isNotEmpty) {
      tickets = await (db.select(
        db.tableSessionTickets,
      )..where((t) => t.sessionId.isIn(sessionIds))).get();
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        tickets = tickets
            .where((t) => itemById[t.itemId]?.categoryId == categoryFilter)
            .toList();
      }
    }

    // Compute previous-week tickets/sessions for WoW comparison.
    final prevFrom = from.subtract(const Duration(days: 7));
    final prevTo = to.subtract(const Duration(days: 7));
    final prevSessions = await (db.select(
      db.tableSessions,
    )..where((s) => s.closedAt.isBetweenValues(prevFrom, prevTo))).get();
    final prevSessionIds = prevSessions.map((s) => s.id).toList();
    final prevTickets = prevSessionIds.isEmpty
        ? <TableSessionTicket>[]
        : await (db.select(
            db.tableSessionTickets,
          )..where((t) => t.sessionId.isIn(prevSessionIds))).get();

    // ─── SALES ──────────────────────────────────────────────────
    final gross = sessions.fold<int>(0, (a, s) => a + s.subtotal);
    final voidTotal = sessions.fold<int>(0, (a, s) => a + s.voidAmount);
    final net = sessions.fold<int>(0, (a, s) => a + s.settledTotal);
    final covers = sessions.fold<int>(0, (a, s) => a + s.pax);
    final sessionCount = sessions.length;
    // The real settled figures, not an estimate. `taxAmount` / `serviceAmount`
    // are frozen at settlement by `bill_math.dart` and sit on the very rows
    // this fold already walks, so the cheap-estimate reason ADR-0032 §1 gave
    // for `net * 0.18` never held — and the estimate was unconditional, which
    // billed a venue with both charges switched off for tax it never took.
    final taxService = sessions.fold<int>(
      0,
      (a, s) => a + s.taxAmount + s.serviceAmount,
    );
    // Codes and amounts, not sentences: the reader renders these (ADR-0085).
    // The compact rupiah these used to carry abbreviated *Indonesian* words.
    final salesKpis = [
      {
        'key': 'net',
        'rupiah': net,
        'args': [sessionCount, covers],
      },
      {
        'key': 'gross',
        'rupiah': gross,
        'args': [sessionCount],
      },
      {'key': 'taxService', 'rupiah': taxService, 'args': []},
      {
        'key': 'void',
        'rupiah': voidTotal,
        'args': [_voidLineCount(tickets)],
      },
    ];

    // Cover trend: group sessions by weekday for this/last week (7 days only).
    final coverTrend = <Map<String, dynamic>>[];
    // The weekday number, not its name — the reader spells it in its own
    // language (ADR-0085), the same way every other date on screen is spelled.
    for (var dow = 1; dow <= 7; dow++) {
      final thisWk = sessions
          .where((s) => s.closedAt.weekday == dow)
          .fold<int>(0, (a, s) => a + s.pax);
      final lastWk = prevSessions
          .where((s) => s.closedAt.weekday == dow)
          .fold<int>(0, (a, s) => a + s.pax);
      coverTrend.add({'dow': dow, 'thisWeek': thisWk, 'lastWeek': lastWk});
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
    final hourlyNorm = hourly
        .map((v) => hourlyMax == 0 ? 0.0 : (v / hourlyMax))
        .toList();

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
      final netSum = list.fold<int>(0, (a, s) => a + s.settledTotal);
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
      // An [[Item bebas]] is revenue (Sales counts it above) but not menu
      // engineering: every off-menu line shares one reserved id, so they would
      // pile into a single fictitious "item" with no cost and therefore a 100%
      // margin, at the top of the star list. There is no dish to rank.
      if (t.itemId == openItemId) continue;
      final agg = byItem.putIfAbsent(t.itemId, () => _ItemAgg());
      agg.qty += t.qty;
      agg.revenue += t.price * t.qty;
    }
    final itemList = byItem.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));
    final menuMax = itemList.isEmpty ? 1 : itemList.first.value.revenue;

    List<Map<String, dynamic>> menuRows(
      Iterable<MapEntry<String, _ItemAgg>> iter,
    ) => iter.map((e) {
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
        'fill': menuMax == 0
            ? 0.0
            : (e.value.revenue / menuMax).clamp(0.0, 1.0),
      };
    }).toList();

    final menuTop = menuRows(itemList.take(5));
    final menuSlow = menuRows(itemList.reversed.take(5));

    // Modifier attach: count by the snapshotted groupId (ADR-0011).
    // Tolerant of legacy bare-string rows ("group:option") just in case a
    // pre-v22 row slipped through.
    final modCounts = <String, int>{};
    for (final t in tickets) {
      try {
        final mods = jsonDecode(t.modifiersJson) as List;
        for (final m in mods) {
          final key = m is Map
              ? (m['groupId'] as String? ?? '')
              : m.toString().split(':').first;
          if (key.isEmpty) continue;
          modCounts[key] = (modCounts[key] ?? 0) + 1;
        }
      } catch (_) {}
    }
    final modifierAttach =
        modCounts.entries
            .map(
              (e) => {
                'group': e.key,
                'rate': tickets.isEmpty ? 0.0 : e.value / tickets.length,
              },
            )
            .toList()
          ..sort(
            (a, b) => (b['rate'] as double).compareTo(a['rate'] as double),
          );

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
    final categoryMix =
        catThis.entries.map((e) {
          final share = catThisTotal == 0 ? 0.0 : e.value / catThisTotal;
          final prevShare = catLastTotal == 0
              ? 0.0
              : (catLast[e.key] ?? 0) / catLastTotal;
          return {
            'id': e.key,
            'name': catById[e.key]?.name ?? e.key,
            'shareThisWeek': share,
            'shareLastWeek': prevShare,
          };
        }).toList()..sort(
          (a, b) => (b['shareThisWeek'] as double).compareTo(
            a['shareThisWeek'] as double,
          ),
        );

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
    final avgTurnSec = dineInSessions.isEmpty
        ? 0
        : dineInSessions.fold<int>(0, (a, s) => a + s.durationSec) ~/
              dineInSessions.length;
    final avgTurnMin = avgTurnSec ~/ 60;

    // ─── SPEED OF SERVICE (ADR-0013) ─────────────────────────────
    // Real lifecycle timing off readyAt / servedAt, not a sentAt proxy.
    // Voided lines and lines that never reached ready drop out (NULL stamp).
    final prepTargetMins = settings?.prepTargetMins ?? 15;
    final pickupTargetMins = settings?.pickupTargetMins ?? 4;
    final prepSecs = <double>[]; // kitchen clock → readyAt (per line)
    final pickupSecs = <double>[]; // readyAt → servedAt (food at the pass)
    final prepByItem = <String, _SpeedAgg>{};
    // Course rollup input. The unit of "late" is the course, so the SLA is
    // measured on courses even though per-item medians stay per line.
    final timedLines = <TimedLine>[];
    for (final t in tickets) {
      if (t.status == 'voided' || t.readyAt == null) continue;
      // ADR-0043: the kitchen's clock starts at the fire for a held course.
      final start = t.firedAt ?? t.sentAt;
      final prep = t.readyAt!.difference(start).inSeconds;
      if (prep < 0) continue; // clock skew guard
      prepSecs.add(prep.toDouble());
      final agg = prepByItem.putIfAbsent(t.itemId, () => _SpeedAgg());
      agg.totalSec += prep;
      agg.count += 1;
      timedLines.add(
        TimedLine(
          visitKey: t.sessionId,
          course: t.course,
          start: start,
          readyAt: t.readyAt,
          // Targets live-resolve against the current menu, like allergens
          // (ADR-0012) — history is not re-priced, only re-judged.
          targetMins: resolvePrepMins(
            itemById[t.itemId]?.prepTime,
            prepTargetMins,
          ),
        ),
      );
      if (t.servedAt != null) {
        final lag = t.servedAt!.difference(t.readyAt!).inSeconds;
        if (lag >= 0) pickupSecs.add(lag.toDouble());
      }
    }
    final prepMedianMin = prepSecs.isEmpty ? 0 : (_median(prepSecs) ~/ 60);
    final pickupMedianMin = pickupSecs.isEmpty
        ? 0
        : (_median(pickupSecs) ~/ 60);
    // SLA hit-rate is now "% of *courses* that hit their own target" — a
    // single honest percentage, even though the target it is measured
    // against is no longer a single number (ADR-0043).
    final completedCourses = rollUpCourses(
      timedLines,
    ).where((c) => c.isComplete).toList();
    final slaHits = completedCourses.where((c) => c.onTime).length;
    final slaPct = completedCourses.isEmpty
        ? 0.0
        : (slaHits / completedCourses.length * 100);
    // Pickup SLA closes the loop on the new "Menunggu diantar" threshold.
    final pickupLimitSec = pickupTargetMins * 60;
    final pickupHits = pickupSecs.where((s) => s <= pickupLimitSec).length;
    final pickupSlaPct = pickupSecs.isEmpty
        ? 0.0
        : (pickupHits / pickupSecs.length * 100);
    // Slowest dishes by average prep time (min 1 sample shown, top 5).
    final slowItems =
        prepByItem.entries
            .map(
              (e) => {
                'itemId': e.key,
                'name': itemById[e.key]?.name ?? e.key,
                'avgPrepMin': (e.value.totalSec / e.value.count / 60),
                'count': e.value.count,
              },
            )
            .toList()
          ..sort(
            (a, b) => (b['avgPrepMin'] as double).compareTo(
              a['avgPrepMin'] as double,
            ),
          );
    // ─── TIME TO FIRST ORDER (ADR-0044) ──────────────────────────
    // The KPI that justifies the "Belum dilayani" cue: without it there is no
    // way to tell whether the alert improved anything. Derived from existing
    // timestamps — no alert-event log, so this measures *the service*, not
    // the alerting.
    final ungreetedMins = settings?.ungreetedMins ?? 7;
    final greetSecs = <double>[];
    for (final s in dineInSessions) {
      final openedAt = s.openedAt;
      if (openedAt == null) continue;
      final lines = ticketsBySession[s.id];
      if (lines == null || lines.isEmpty) continue;
      var firstSent = lines.first.sentAt;
      for (final l in lines.skip(1)) {
        if (l.sentAt.isBefore(firstSent)) firstSent = l.sentAt;
      }
      final wait = firstSent.difference(openedAt).inSeconds;
      if (wait < 0) continue; // clock skew guard
      greetSecs.add(wait.toDouble());
    }
    final greetMedianMin = greetSecs.isEmpty ? 0 : (_median(greetSecs) ~/ 60);
    final greetLimitSec = ungreetedMins * 60;
    final greetBreaches = greetSecs.where((s) => s > greetLimitSec).length;
    final greetBreachPct = greetSecs.isEmpty
        ? 0.0
        : (greetBreaches / greetSecs.length * 100);
    final greetStats = {
      'greetMedianMin': greetMedianMin,
      'greetBreachPct': greetBreachPct,
      'ungreetedMins': ungreetedMins,
      'greetSampleSize': greetSecs.length,
    };

    final speed = {
      'prepMedianMin': prepMedianMin,
      'pickupMedianMin': pickupMedianMin,
      'slaPct': slaPct,
      // Retained as the venue *default* — the headline no longer names a
      // number, since targets resolve per item (ADR-0043).
      'prepTargetMins': prepTargetMins,
      'pickupTargetMins': pickupTargetMins,
      'pickupSlaPct': pickupSlaPct,
      'courseSampleSize': completedCourses.length,
      'sampleSize': prepSecs.length,
      'slowItems': slowItems.take(5).toList(),
      ...greetStats,
    };

    final opsKpis = [
      {'key': 'turnTime', 'value': '$avgTurnMin min', 'args': <int>[]},
      {
        'key': 'prep',
        'value': prepSecs.isEmpty ? '—' : '$prepMedianMin min',
        'args': <int>[],
      },
      {
        'key': 'pickup',
        'value': pickupSecs.isEmpty ? '—' : '$pickupMedianMin min',
        'args': <int>[],
      },
      // Overwritten below, once reservations is computed.
      {'key': 'reservations', 'value': '—', 'args': <int>[]},
    ];

    // Stations: sum qty for the unified station.
    final totalQty = tickets
        .where((t) => t.status != 'voided')
        .fold<int>(0, (a, t) => a + t.qty);
    final stations = [
      {
        'station': 'kitchen',
        'qty': totalQty,
        'utilization': totalQty == 0 ? 0.0 : 1.0,
      },
    ];

    // Heatmap: 7 weekdays × 12 hours (11..22).
    final heatRaw = List.generate(7, (_) => List.filled(12, 0));
    for (final s in dineInSessions) {
      final dow = s.closedAt.weekday - 1; // 0..6
      final hour = s.closedAt.hour;
      if (hour < 11 || hour > 22) continue;
      heatRaw[dow][hour - 11] += 1;
    }
    final heatMax = heatRaw
        .expand((row) => row)
        .fold<int>(0, (a, b) => b > a ? b : a);
    final heatmap = heatRaw
        .map((row) => row.map((v) => heatMax == 0 ? 0.0 : v / heatMax).toList())
        .toList();

    // Patch ops KPI #4 with real reservation totals (defined below).
    final reservationRows = await (db.select(
      db.reservations,
    )..where((r) => r.expectedAt.isBetweenValues(from, to))).get();
    // "Terlambat" is a *derived display state*, never a stored status
    // (ADR-0044) — so lateness is recomputed here from the same grace the
    // floor uses, rather than counted off a flag.
    final graceMins = settings?.reservationGraceMins ?? 15;
    final grace = Duration(minutes: graceMins);
    final lateRows = reservationRows.where((r) {
      final seatedAt = r.seatedAt;
      if (seatedAt == null) return false;
      return seatedAt.difference(r.expectedAt) > grace;
    }).length;
    final noShowCount = reservationRows
        .where((r) => r.status == 'noShow')
        .length;
    final reservations = {
      'booked': reservationRows.length,
      'seated': reservationRows.where((r) => r.status == 'seated').length,
      'noShow': noShowCount,
      'cancelled': reservationRows.where((r) => r.status == 'cancelled').length,
      'late': lateRows,
      'graceMins': graceMins,
      'latePct': reservationRows.isEmpty
          ? 0.0
          : (lateRows / reservationRows.length * 100),
      'noShowPct': reservationRows.isEmpty
          ? 0.0
          : (noShowCount / reservationRows.length * 100),
    };
    if (opsKpis.length >= 4) {
      opsKpis[3] = {
        'key': 'reservations',
        'value': '${reservations['seated']} / ${reservations['booked']}',
        'args': [reservations['noShow']!, reservations['cancelled']!],
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
    final voidReasons =
        reasonAgg.entries
            .map(
              (e) => {
                'code': e.key,
                'count': e.value.count,
                'lostRupiah': e.value.lostRupiah,
              },
            )
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
    final voidStaff =
        voidByStaff.entries.map((e) {
            final topReason = e.value.reasonCounts.entries.isEmpty
                ? 'other'
                : (e.value.reasonCounts.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                      .first
                      .key;
            return {
              'id': e.key,
              'name': userById[e.key]?.name ?? e.key,
              'count': e.value.count,
              'lostRupiah': e.value.lostRupiah,
              'topReasonCode': topReason,
            };
          }).toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // ─── MONEY AUDIT (ADR-0086) ──────────────────────────────────
    // The money half of the venue log, for the off-site owner — who has no
    // route to `/audit` and, since the non-cash card was removed, no other way
    // to see an individual tender at all.
    //
    // The filter is `amountCents IS NOT NULL` rather than a list of types on
    // purpose: that column is by definition what a row is worth, so a money
    // type added later is published without anyone remembering to come back
    // here. Rows with no amount (fire, tableMoved, staff and role edits) are
    // not money and stay on the venue device.
    //
    // Structured fields ride along so the owner's device composes the sentence
    // in its own language (ADR-0085). Proof-photo bytes do not (ADR-0036).
    final tableLabelById = {
      for (final t in await db.select(db.venueTables).get()) t.id: t.label,
    };
    final auditRows =
        await (db.select(db.auditEntries)
              ..where((a) => a.amountCents.isNotNull())
              ..where((a) => a.at.isBiggerOrEqualValue(from))
              ..where((a) => a.at.isSmallerThanValue(to))
              ..orderBy([(a) => OrderingTerm.desc(a.at)])
              // One over the cap, purely to learn whether there were more.
              ..limit(_moneyAuditCap + 1))
            .get();
    final auditTruncated = auditRows.length > _moneyAuditCap;
    final moneyAudit = [
      for (final a in auditRows.take(_moneyAuditCap))
        {
          'id': a.id,
          'type': a.type,
          'at': a.at.toIso8601String(),
          'title': a.title,
          'kind': a.kind,
          'params': a.params == null
              ? const <String, dynamic>{}
              : (jsonDecode(a.params!) as Map).cast<String, dynamic>(),
          'actorName': a.actorName,
          'tableLabel': a.tableId == null ? null : tableLabelById[a.tableId],
          'amountCents': a.amountCents,
        },
    ];

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

    // Takeaway vs dine-in split for the sales section (ADR-0026). Both kinds
    // count toward net; the split surfaces takeaway share without polluting
    // per-cover / turn-time metrics.
    final takeawayCount = takeawaySessions.length;
    final takeawayNet = takeawaySessions.fold<int>(
      0,
      (a, s) => a + s.settledTotal,
    );
    final dineInCount = dineInSessions.length;
    final dineInNet = dineInSessions.fold<int>(0, (a, s) => a + s.settledTotal);

    // Computed before the body so `sales` can read one figure back off it.
    final piutang = await debtReportSection(db, from: from, to: to);

    final body = {
      'generatedAt': now.toIso8601String(),
      'rangeFrom': from.toIso8601String(),
      'rangeTo': to.toIso8601String(),
      'range': range,
      'filterOptions': filterOptions,
      // `badDebt` is the one Piutang figure that crosses into Sales (ADR-0098).
      // ADR-0089's isolation is right for the petty cash box — a top-up is not
      // income — but a tab written off weeks after close is a genuine loss
      // against revenue already booked, and hiding it in its own section means
      // an owner reads `net` as money they got. Read-only: nothing here
      // recomputes `net`, which keeps its frozen meaning.
      'sales': {
        'badDebt': piutang['writtenOff'],
        'kpis': salesKpis,
        'coverTrend': coverTrend,
        'hourly': hourlyNorm,
        'takeaway': {
          'count': takeawayCount,
          'net': takeawayNet,
          'dineInCount': dineInCount,
          'dineInNet': dineInNet,
        },
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
        'speed': speed,
        'stations': stations,
        'heatmap': heatmap,
        'reservations': reservations,
        'voidReasons': voidReasons,
        'voidByStaff': voidStaff,
      },
      'moneyAudit': {'rows': moneyAudit, 'truncated': auditTruncated},
      // Its own top-level section, never folded into `sales` (ADR-0089). The box
      // is the venue's money leaving by a door that is not a bill; adding it to
      // takings would overstate revenue and understate cost in one stroke.
      // Shares the business-day window so "today" means the same thing here as
      // it does two sections up.
      'kas': await cashReportSection(db, from: from, to: to),
      // Its own section too, and for the mirror-image reason: membership is
      // not a sales channel, it is a claim on future takings. Reporting it
      // inside `sales` would let a points give-away read as revenue.
      'members': await memberReportSection(db, from: from, to: to),
      // And its own again (ADR-0098). A collection is not revenue — the sale
      // was booked the night it was eaten — so it cannot sit in `sales`. But
      // `opening` and `closing` are venue-wide outstanding rather than window
      // sums, because a receivable does not reset at midnight the way takings
      // do. The one figure that *does* cross over is `writtenOff`, which the
      // Sales block reads back as a loss against revenue already counted.
      'piutang': piutang,
      // Attendance, kept apart from `staff` above on purpose. That block is
      // what someone sold; this one is whether they were here. Fusing them
      // invites reading a slow Tuesday as a slack one.
      'jamKerja': await shiftReportSection(db, from: from, to: to),
    };

    return Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );
  });

  // Order history export feed (ADR-0030). Read-only window of CLOSED visits and
  // their line items, grouped by session, for the order-list export. The live
  // order board never calls this — it only powers the export sheet's chosen
  // range. viewReports-gated: exposes historical financial data.
  r.get('/orders/history', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.viewReports);
    if (denied != null) return denied;

    final qp = req.url.queryParameters;
    final range = qp['range'] ?? 'today';

    final now = SatClock.now();
    final settings = await (db.select(
      db.venueSettings,
    )..where((s) => s.id.equals('default'))).getSingleOrNull();
    final hour = settings?.businessDayStartHour ?? _defaultBusinessDayStartHour;
    final (from, to) = _windowFor(
      range,
      now,
      hour,
      fromStr: qp['from'],
      toStr: qp['to'],
    );

    final users = await db.select(db.users).get();
    final userById = {for (final u in users) u.id: u};

    final sessions =
        await (db.select(db.tableSessions)
              ..where((s) => s.closedAt.isBetweenValues(from, to))
              ..orderBy([(s) => OrderingTerm.asc(s.closedAt)]))
            .get();
    final sessionIds = sessions.map((s) => s.id).toList();

    final lines = sessionIds.isEmpty
        ? <TableSessionTicket>[]
        : await (db.select(db.tableSessionTickets)
                ..where((t) => t.sessionId.isIn(sessionIds))
                ..orderBy([(t) => OrderingTerm.asc(t.sentAt)]))
              .get();
    final linesBySession = <String, List<TableSessionTicket>>{};
    for (final t in lines) {
      linesBySession.putIfAbsent(t.sessionId, () => []).add(t);
    }

    // Bill settlement snapshots (ADR-0031): per-receipt totals + the payments
    // tendered against them. Grouped by session, then by receipt. Proof photo
    // bytes never ride this path — only a hasPhoto flag (ADR-0025); the client
    // fetches each photo on demand for the PDF.
    final receipts = sessionIds.isEmpty
        ? <TableSessionReceipt>[]
        : await (db.select(
            db.tableSessionReceipts,
          )..where((rcp) => rcp.sessionId.isIn(sessionIds))).get();
    final receiptsBySession = <String, List<TableSessionReceipt>>{};
    for (final rcp in receipts) {
      receiptsBySession.putIfAbsent(rcp.sessionId, () => []).add(rcp);
    }

    final pays = sessionIds.isEmpty
        ? <TableSessionPayment>[]
        : await (db.select(db.tableSessionPayments)
                ..where((p) => p.sessionId.isIn(sessionIds))
                ..orderBy([(p) => OrderingTerm.asc(p.at)]))
              .get();
    final paysByReceipt = <String, List<TableSessionPayment>>{};
    final paysBySession = <String, List<TableSessionPayment>>{};
    for (final p in pays) {
      paysByReceipt.putIfAbsent(p.receiptId, () => []).add(p);
      paysBySession.putIfAbsent(p.sessionId, () => []).add(p);
    }

    Map<String, dynamic> payJson(TableSessionPayment p) => {
      'paymentId': p.id,
      'method': p.method,
      'amount': p.amount,
      'isRefund': p.isRefund,
      'cashierName': p.cashierUserId == null
          ? null
          : userById[p.cashierUserId!]?.name,
      'at': p.at.toIso8601String(),
      'hasPhoto': p.photo != null,
    };

    // Receipt + payment tree for one visit. Payments whose receipt snapshot is
    // missing (orphans) are gathered under a synthetic '—' receipt so no tender
    // is dropped from the export.
    List<Map<String, dynamic>> receiptTree(String sessionId) {
      final rcps =
          receiptsBySession[sessionId] ?? const <TableSessionReceipt>[];
      final known = {for (final r in rcps) r.receiptId};
      final out = [
        for (final r in rcps)
          {
            'receiptId': r.receiptId,
            'label': r.label,
            'mode': r.mode,
            'subtotal': r.subtotal,
            'discountAmount': r.discountAmount,
            'serviceAmount': r.serviceAmount,
            'taxAmount': r.taxAmount,
            'total': r.total,
            'status': r.status,
            'payments': [
              for (final p in paysByReceipt[r.receiptId] ?? const [])
                payJson(p),
            ],
          },
      ];
      final orphans = [
        for (final p in paysBySession[sessionId] ?? const [])
          if (!known.contains(p.receiptId)) payJson(p),
      ];
      if (orphans.isNotEmpty) {
        out.add({
          'receiptId': '',
          'label': '—',
          'mode': 'itemized',
          'subtotal': 0,
          'discountAmount': 0,
          'serviceAmount': 0,
          'taxAmount': 0,
          'total': 0,
          'status': '',
          'payments': orphans,
        });
      }
      return out;
    }

    List<String> modLabels(String json) {
      try {
        final mods = jsonDecode(json) as List;
        return [
          for (final m in mods)
            if (m is Map && (m['label'] as String? ?? '').isNotEmpty)
              m['label'] as String,
        ];
      } catch (_) {
        return const [];
      }
    }

    var lineCount = 0;
    var netTotal = 0;
    final visits = <Map<String, dynamic>>[];
    for (final s in sessions) {
      final ls = linesBySession[s.id] ?? const <TableSessionTicket>[];
      lineCount += ls.length;
      netTotal += s.settledTotal;
      visits.add({
        'sessionId': s.id,
        'tableLabel': s.tableLabel ?? '—',
        'kind': s.kind,
        'pax': s.pax,
        'closedAt': s.closedAt.toIso8601String(),
        'waiterName': s.actorUserId == null
            ? null
            : userById[s.actorUserId!]?.name,
        'subtotal': s.subtotal,
        'voidAmount': s.voidAmount,
        'net': s.settledTotal,
        'lines': [
          for (final t in ls)
            {
              'sentAt': t.sentAt.toIso8601String(),
              'name': t.name,
              'variantName': t.variantName,
              'course': t.course,
              'qty': t.qty,
              'price': t.price,
              'lineTotal': t.price * t.qty,
              'status': t.status,
              'modifiers': modLabels(t.modifiersJson),
              'readyAt': t.readyAt?.toIso8601String(),
              'servedAt': t.servedAt?.toIso8601String(),
              'voidReasonCode': t.status == 'voided'
                  ? (t.voidReasonCode ?? 'other')
                  : null,
            },
        ],
        'receipts': receiptTree(s.id),
      });
    }

    final body = {
      'generatedAt': now.toIso8601String(),
      'rangeFrom': from.toIso8601String(),
      'rangeTo': to.toIso8601String(),
      'range': range,
      'visits': visits,
      'totals': {
        'visitCount': visits.length,
        'lineCount': lineCount,
        'net': netTotal,
      },
    };

    return Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );
  });

  // Staff-focus export feed (ADR-0032). One combined row per staff member:
  // productivity + sales + integrity together, for the same window the report
  // screen shows. Reuses the snapshot's window + aggregation; emitted as a flat
  // purpose-built payload the export sheet turns into a wide CSV / landscape PDF.
  // viewReports-gated: exposes per-staff financial + void data.
  r.get('/reports/staff', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.viewReports);
    if (denied != null) return denied;

    final qp = req.url.queryParameters;
    final range = qp['range'] ?? 'today';

    final now = SatClock.now();
    final settings = await (db.select(
      db.venueSettings,
    )..where((s) => s.id.equals('default'))).getSingleOrNull();
    final hour = settings?.businessDayStartHour ?? _defaultBusinessDayStartHour;
    final (from, to) = _windowFor(
      range,
      now,
      hour,
      fromStr: qp['from'],
      toStr: qp['to'],
    );

    final users = await db.select(db.users).get();
    final menu = await db.select(db.menuItems).get();
    final userById = {for (final u in users) u.id: u};
    final itemById = {for (final m in menu) m.id: m};

    final sessions = await (db.select(
      db.tableSessions,
    )..where((s) => s.closedAt.isBetweenValues(from, to))).get();
    final sessionIds = sessions.map((s) => s.id).toList();
    final tickets = sessionIds.isEmpty
        ? <TableSessionTicket>[]
        : await (db.select(
            db.tableSessionTickets,
          )..where((t) => t.sessionId.isIn(sessionIds))).get();

    // Sessions grouped by the acting waiter (session actor).
    final byStaff = <String, List<TableSession>>{};
    for (final s in sessions) {
      if (s.actorUserId == null) continue;
      byStaff.putIfAbsent(s.actorUserId!, () => []).add(s);
    }
    final ticketsBySession = <String, List<TableSessionTicket>>{};
    for (final t in tickets) {
      ticketsBySession.putIfAbsent(t.sessionId, () => []).add(t);
    }

    // Void activity grouped by the waiter who voided (ADR-0006) — a distinct
    // axis from the session actor, joined back per user id below.
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

    // Attendance rides the same row (ADR-0032: one combined row per staff
    // member), so a second export feed never has to be kept in sync with this
    // one.
    final attendance = {
      for (final r
          in (await shiftReportSection(db, from: from, to: to))['staff']
              as List)
        (r as Map)['id'] as String: r,
    };

    // Union of everyone who ran a session, voided a line, OR clocked in — a
    // manager who only voids still shows up, and so does a cook who sold
    // nothing but was here for eight hours.
    final staffIds = <String>{
      ...byStaff.keys,
      ...voidByStaff.keys,
      ...attendance.keys,
    }..removeWhere((id) => id == 'unknown');

    final rows = <Map<String, dynamic>>[];
    for (final id in staffIds) {
      final list = byStaff[id] ?? const <TableSession>[];
      final covers = list.fold<int>(0, (a, s) => a + s.pax);
      final items = list.fold<int>(0, (a, s) => a + s.ticketCount);
      final netSum = list.fold<int>(0, (a, s) => a + s.settledTotal);
      final grossSum = list.fold<int>(0, (a, s) => a + s.subtotal);
      final voidSum = list.fold<int>(0, (a, s) => a + s.voidAmount);
      final avgTicket = list.isEmpty ? 0 : (netSum / list.length).round();
      final voidPct = grossSum == 0 ? 0.0 : (voidSum / grossSum * 100);

      // Upsell index: % of this waiter's sessions with ≥1 starter AND ≥1 main.
      var withUpsell = 0;
      for (final s in list) {
        final ts = ticketsBySession[s.id] ?? const <TableSessionTicket>[];
        final cats = ts
            .map((t) => itemById[t.itemId]?.categoryId)
            .whereType<String>()
            .toSet();
        if (cats.contains('starters') && cats.contains('mains')) withUpsell++;
      }
      final upsellRate = list.isEmpty ? 0.0 : withUpsell / list.length;

      final v = voidByStaff[id];
      final topReason = v == null || v.reasonCounts.isEmpty
          ? null
          : (v.reasonCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .first
                .key;

      rows.add({
        'id': id,
        'name': userById[id]?.name ?? id,
        'sessions': list.length,
        'covers': covers,
        'items': items,
        'net': netSum,
        'avgTicket': avgTicket,
        'upsellRate': upsellRate,
        'voidCount': v?.count ?? 0,
        'voidPct': voidPct,
        'lostRupiah': v?.lostRupiah ?? 0,
        'topReasonCode': topReason,
        'minutes': attendance[id]?['minutes'] ?? 0,
        'daysWorked': attendance[id]?['days'] ?? 0,
        'unclosedShifts': attendance[id]?['unclosed'] ?? 0,
      });
    }
    rows.sort((a, b) => (b['net'] as int).compareTo(a['net'] as int));

    final body = {
      'generatedAt': now.toIso8601String(),
      'rangeFrom': from.toIso8601String(),
      'rangeTo': to.toIso8601String(),
      'range': range,
      'rows': rows,
      'totals': {
        'staffCount': rows.length,
        'net': rows.fold<int>(0, (a, r) => a + (r['net'] as int)),
        'voidCount': rows.fold<int>(0, (a, r) => a + (r['voidCount'] as int)),
        'lostRupiah': rows.fold<int>(0, (a, r) => a + (r['lostRupiah'] as int)),
      },
    };

    return Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );
  });

  // Accounting export feed (ADR-0032). Bookkeeping view of the same window the
  // report screen shows: revenue summary on the real settled figures — session
  // taxAmount / serviceAmount, the same ones the sales KPI now reads —
  // payment-method breakdown incl. cash with refunds on their own line,
  // void/refund write-offs, and a per-calendar-day breakdown for ledger
  // posting. Window uses the same range rule as the snapshot (not closedAt
  // accrual). viewReports-gated.
  r.get('/reports/accounting', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.viewReports);
    if (denied != null) return denied;

    final qp = req.url.queryParameters;
    final range = qp['range'] ?? 'today';

    final now = SatClock.now();
    final settings = await (db.select(
      db.venueSettings,
    )..where((s) => s.id.equals('default'))).getSingleOrNull();
    final hour = settings?.businessDayStartHour ?? _defaultBusinessDayStartHour;
    final (from, to) = _windowFor(
      range,
      now,
      hour,
      fromStr: qp['from'],
      toStr: qp['to'],
    );

    final sessions = await (db.select(
      db.tableSessions,
    )..where((s) => s.closedAt.isBetweenValues(from, to))).get();
    final sessionIds = sessions.map((s) => s.id).toList();

    // Revenue summary — sums straight off the settled session rows.
    final gross = sessions.fold<int>(0, (a, s) => a + s.subtotal);
    final voidAmount = sessions.fold<int>(0, (a, s) => a + s.voidAmount);
    final service = sessions.fold<int>(0, (a, s) => a + s.serviceAmount);
    final tax = sessions.fold<int>(0, (a, s) => a + s.taxAmount);
    final net = sessions.fold<int>(0, (a, s) => a + s.settledTotal);
    // Deliberate revenue give-back, kept visible beside gross/void rather than
    // folded into gross — otherwise the cost of promos hides inside the number
    // the owner judges the business by (ADR-0039).
    final discount = sessions.fold<int>(0, (a, s) => a + s.discountAmount);

    // Payments — every tender (incl. cash); refunds split onto their own line.
    final pays = sessionIds.isEmpty
        ? <TableSessionPayment>[]
        : await (db.select(
            db.tableSessionPayments,
          )..where((p) => p.sessionId.isIn(sessionIds))).get();
    final methodCharged = <String, int>{};
    final methodChargedCount = <String, int>{};
    final methodRefunded = <String, int>{};
    final methodRefundedCount = <String, int>{};
    var collected = 0;
    var refunded = 0;
    for (final p in pays) {
      if (p.isRefund) {
        final amt = p.amount.abs();
        methodRefunded[p.method] = (methodRefunded[p.method] ?? 0) + amt;
        methodRefundedCount[p.method] =
            (methodRefundedCount[p.method] ?? 0) + 1;
        refunded += amt;
      } else {
        methodCharged[p.method] = (methodCharged[p.method] ?? 0) + p.amount;
        methodChargedCount[p.method] = (methodChargedCount[p.method] ?? 0) + 1;
        collected += p.amount;
      }
    }
    final methods = <Map<String, dynamic>>[
      for (final m in {...methodCharged.keys, ...methodRefunded.keys})
        {
          'method': m,
          'charged': methodCharged[m] ?? 0,
          'chargedCount': methodChargedCount[m] ?? 0,
          'refunded': methodRefunded[m] ?? 0,
          'refundedCount': methodRefundedCount[m] ?? 0,
          'net': (methodCharged[m] ?? 0) - (methodRefunded[m] ?? 0),
        },
    ]..sort((a, b) => (b['net'] as int).compareTo(a['net'] as int));

    // Per-preset discount rollup — "which promo is costing me money". This is
    // the payoff for choosing an owner-defined catalogue over ad-hoc entry
    // (ADR-0037): ad-hoc discounts could only ever produce one lump figure.
    // Grouped by the weak `presetId` but LABELLED from the snapshot, so a
    // preset edited or deleted since still reports under the name it carried
    // when it was applied (ADR-0039).
    final discountRows = sessionIds.isEmpty
        ? <TableSessionDiscount>[]
        : await (db.select(
            db.tableSessionDiscounts,
          )..where((d) => d.sessionId.isIn(sessionIds))).get();
    final discountAgg = <String, Map<String, dynamic>>{};
    for (final d in discountRows) {
      final key = d.presetId ?? 'preset:${d.name}';
      final agg = discountAgg.putIfAbsent(
        key,
        () => {
          'presetId': d.presetId,
          'name': d.name,
          'kind': d.kind,
          'value': d.value,
          'scope': d.ticketId == null ? 'order' : 'line',
          'amount': 0,
          'count': 0,
        },
      );
      agg['amount'] = (agg['amount'] as int) + d.amount;
      agg['count'] = (agg['count'] as int) + 1;
    }
    final discountRollup = discountAgg.values.toList()
      ..sort((a, b) => (b['amount'] as int).compareTo(a['amount'] as int));

    // Void write-offs by reason (lost rupiah from voided lines).
    final tickets = sessionIds.isEmpty
        ? <TableSessionTicket>[]
        : await (db.select(
            db.tableSessionTickets,
          )..where((t) => t.sessionId.isIn(sessionIds))).get();
    final voidAgg = <String, _ReasonAgg>{};
    for (final t in tickets) {
      if (t.status != 'voided') continue;
      final code = t.voidReasonCode ?? 'other';
      final agg = voidAgg.putIfAbsent(code, () => _ReasonAgg());
      agg.count += 1;
      agg.lostRupiah += t.price * t.qty;
    }
    final voids =
        voidAgg.entries
            .map(
              (e) => {
                'code': e.key,
                'count': e.value.count,
                'lostRupiah': e.value.lostRupiah,
              },
            )
            .toList()
          ..sort(
            (a, b) =>
                (b['lostRupiah'] as int).compareTo(a['lostRupiah'] as int),
          );

    // Per-calendar-day breakdown for ledger posting. Bucketed by the session's
    // closedAt date; payments attributed to their session's day.
    final dayKey = <String, String>{}; // sessionId → yyyy-MM-dd
    final daily = <String, _AcctDayAgg>{};
    String ymd(DateTime d) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${d.year}-${two(d.month)}-${two(d.day)}';
    }

    for (final s in sessions) {
      final key = ymd(s.closedAt);
      dayKey[s.id] = key;
      final agg = daily.putIfAbsent(key, () => _AcctDayAgg());
      agg.gross += s.subtotal;
      agg.voidAmount += s.voidAmount;
      agg.service += s.serviceAmount;
      agg.tax += s.taxAmount;
      agg.net += s.settledTotal;
      agg.discount += s.discountAmount;
    }
    for (final p in pays) {
      final key = dayKey[p.sessionId];
      if (key == null) continue;
      final agg = daily.putIfAbsent(key, () => _AcctDayAgg());
      if (p.isRefund) {
        agg.refunded += p.amount.abs();
      } else {
        agg.collected += p.amount;
      }
    }
    final dailyRows =
        daily.entries
            .map(
              (e) => {
                'date': e.key,
                'gross': e.value.gross,
                'voidAmount': e.value.voidAmount,
                'service': e.value.service,
                'tax': e.value.tax,
                'discount': e.value.discount,
                'net': e.value.net,
                'collected': e.value.collected,
                'refunded': e.value.refunded,
              },
            )
            .toList()
          ..sort(
            (a, b) => (a['date'] as String).compareTo(b['date'] as String),
          );

    final body = {
      'generatedAt': now.toIso8601String(),
      'rangeFrom': from.toIso8601String(),
      'rangeTo': to.toIso8601String(),
      'range': range,
      'revenue': {
        'gross': gross,
        'voidAmount': voidAmount,
        'service': service,
        'tax': tax,
        'discount': discount,
        'net': net,
        'collected': collected,
        'refunded': refunded,
        'sessionCount': sessions.length,
      },
      'methods': methods,
      'voids': voids,
      'discounts': discountRollup,
      'daily': dailyRows,
    };

    return Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );
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

class _SpeedAgg {
  int totalSec = 0;
  int count = 0;
}

class _StaffVoidAgg {
  int count = 0;
  int lostRupiah = 0;
  final Map<String, int> reasonCounts = {};
}

/// Per-calendar-day accounting rollup (ADR-0032).
class _AcctDayAgg {
  int gross = 0;
  int voidAmount = 0;
  int service = 0;
  int tax = 0;
  int discount = 0;
  int net = 0;
  int collected = 0;
  int refunded = 0;
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
