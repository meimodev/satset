import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/members.dart';
import 'package:satset/server/self_order.dart';
import 'package:satset/server/ws_hub.dart';

/// A fixed-window counter, in memory, keyed by whatever the caller hands it.
///
/// Same lifetime argument as the per-session punch cap this sits beside: the
/// router is built once at boot, the socket *is* the process, and a rate limit
/// nobody ever reads back is not worth a column. A restart forgives everyone,
/// which is the right trade for a server that is a tablet somebody unplugs at
/// closing time.
///
/// Fixed window rather than sliding, because the cost of the seam — twice the
/// allowance across a window boundary — is a number this small does not care
/// about, and the sliding version needs a list per key.
class GuestWindow {
  GuestWindow({required this.limit, required this.span});

  /// Hits allowed per [span] before [trip] starts saying yes.
  final int limit;
  final Duration span;

  final Map<String, ({DateTime start, int hits})> _by = {};

  /// Counts this hit and reports whether [key] has now gone over.
  ///
  /// An empty key is never tripped: it means there was nothing to key on, and
  /// the *other* bucket is what holds in that case. Inventing a shared key for
  /// "unknown" would put every anonymous caller in one bucket and let the
  /// first of them lock out the rest.
  bool trip(String key) {
    if (key.isEmpty) return false;
    // realNow, not now: a rate limit is a security control, and SatClock's own
    // rule is that security never reads the shiftable clock.
    final now = SatClock.realNow();
    // Only once it has grown enough to be worth walking. Phone numbers are
    // attacker-chosen, so the key space is unbounded and something has to
    // sweep; nothing reads these back, so dropping an expired one is free.
    if (_by.length > 512) {
      _by.removeWhere((_, w) => now.difference(w.start) >= span);
    }
    final w = _by[key];
    if (w == null || now.difference(w.start) >= span) {
      _by[key] = (start: now, hits: 1);
      return false;
    }
    final hits = w.hits + 1;
    _by[key] = (start: w.start, hits: hits);
    return hits > limit;
  }
}

/// The **guest** half of [[Pesan mandiri]] (ADR-0105). Everything reachable
/// from a stranger's phone lives in this one folder, so the boundary is a
/// directory rather than a convention.
///
/// This router takes **no [ServerAuth]** and that is deliberate — ADR-0102's
/// "every route factory takes a non-null ServerAuth" is a rule about the staff
/// API, and the way to keep a guest out of it is to give the guest a router
/// that has never heard of it. The credential here is the code in the URL plus
/// an opaque session id; there is no guest JWT and no guest auth scope, which
/// is one of the two costs ADR-0080 named and this design removes.
Router guestRoutes(AppDatabase db, WsHub hub) {
  final r = Router();

  Response json(Object body) => Response.ok(
    jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );

  Response err(int status, String code) => Response(
    status,
    body: jsonEncode({'code': code}),
    headers: {'content-type': 'application/json'},
  );

  /// The code rides the query string on reads and the body on writes. A code
  /// that resolves to nothing is a 404 either way — an unknown code, a
  /// deactivated table and a table opted out of self-order must be
  /// indistinguishable, or the QR becomes a way to enumerate the floor plan.
  String codeOf(Request req, [Map<String, dynamic>? body]) =>
      (body?['code'] as String?) ?? req.url.queryParameters['code'] ?? '';

  /// Where a code points. A table, or the **counter** (ADR-0109) — which is a
  /// place to stand rather than a row, and so carries an empty `tableId`, the
  /// same convention a [[Bawa pulang]] visit has always used for "no table".
  ///
  /// One resolver for both so no route can accidentally serve one kind and not
  /// the other, and a miss stays a single indistinguishable 404.
  Future<({String tableId, String label, bool counter})?> point(
    Request req, [
    Map<String, dynamic>? body,
  ]) async {
    final code = codeOf(req, body);
    final t = await tableForGuestCode(db, code);
    if (t != null) {
      return (tableId: t.id, label: t.label ?? t.id, counter: false);
    }
    if (await isCounterGuestCode(db, code)) {
      // No label: the page spells the counter in its own copy, because this
      // plane sends codes and never sentences (ADR-0085).
      return (tableId: '', label: '', counter: true);
    }
    return null;
  }

  /// Stempel lookups already spent, per session (ADR-0110 §2). Held in memory
  /// on purpose: this router is built once at boot, the cap is per *session*
  /// rather than per day, and a counter nobody ever reads back is not worth a
  /// column. It dies with the socket, which is the right lifetime for it.
  final punchTries = <String, int>{};

  /// Two buckets, because there are two things to protect and they are not the
  /// same thing. ADR-0105 puts this plane on a cleartext socket with no
  /// credential but the code in the URL, so a stranger on the venue Wi-Fi is
  /// the threat model rather than a hypothetical one.
  ///
  /// The tight one is keyed on the **phone number being asked about**: a
  /// [[Stempel]] lookup answers a question about a number the caller typed,
  /// and a session is free to mint, so the per-session cap above stops a loop
  /// and nothing else. Keying on the number caps how often *any* number can be
  /// probed, however many sessions do the asking.
  ///
  /// The loose one is keyed on the caller's address and covers the sweep — the
  /// pattern the phone bucket cannot see, because a sweep asks each number
  /// once. It is deliberately generous: on a LAN one address is one phone, and
  /// a real table ordering four times in an hour must never meet it.
  final punchPhone = GuestWindow(limit: 5, span: const Duration(hours: 1));
  final callerIp = GuestWindow(limit: 40, span: const Duration(hours: 1));

  /// Who is asking, as far as the socket knows. Set by the guest plane's
  /// middleware; empty when nothing set it, which [GuestWindow.trip] reads as
  /// "do not bucket" rather than as a key.
  String ipOf(Request req) => (req.context['guest.ip'] as String?) ?? '';

  Future<GuestSession?> session(Request req) async {
    final id = req.headers['x-guest-session'];
    return id == null ? null : liveGuestSession(db, id);
  }

  /// The app shell. Served for any `/t/<code>` — the page reads the code back
  /// out of `location.pathname`, so nothing is templated into the HTML and the
  /// file stays a static asset.
  r.get('/t/<code>', (Request req, String code) async {
    final rules = await guestRules(db);
    if (!rules.enabled) return Response.notFound('not found');
    return Response.ok(
      await rootBundle.loadString('assets/guest_web/index.html'),
      headers: {
        'content-type': 'text/html; charset=utf-8',
        'cache-control': 'no-cache',
      },
    );
  });

  /// Who the guest is looking at: the venue's name and their own table. Also
  /// the liveness check the page runs before it draws anything.
  r.get('/guest/venue', (Request req) async {
    final t = await point(req);
    if (t == null) return err(404, 'not_found');
    final s = await (db.select(
      db.venueSettings,
    )..where((x) => x.id.equals('default'))).getSingleOrNull();
    final rules = await guestRules(db);
    return json({
      'venue': s?.displayName ?? '',
      'tableId': t.tableId,
      'tableLabel': t.label,
      'counter': t.counter,
      'open': withinServiceHours(rules, DateTime.now()),
      'noteEnabled': rules.noteEnabled,
      'maxItems': rules.maxItems,
      // Whether the stempel box is worth drawing at all (ADR-0110). A
      // venue-level fact, not a member one — it says a card exists here, never
      // that anyone holds it.
      'punch': (await memberConfig(db)).punchRunning,
    });
  });

  r.get('/guest/menu', (Request req) async {
    if (await point(req) == null) return err(404, 'not_found');
    return json(await guestMenuJson(db));
  });

  /// The item photo, unauthenticated on purpose: it is the same JPEG the menu
  /// card shows a walk-in guest on paper.
  r.get('/guest/photo/<id>', (Request req, String id) async {
    final row = await (db.select(
      db.menuItems,
    )..where((i) => i.id.equals(id))).getSingleOrNull();
    if (row == null || row.photo == null || !row.guestVisible) {
      return Response.notFound('no photo');
    }
    return Response.ok(
      row.photo,
      headers: {'content-type': 'image/jpeg', 'cache-control': 'max-age=300'},
    );
  });

  r.post('/guest/session', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final t = await point(req, body);
    if (t == null) return err(404, 'not_found');
    final rules = await guestRules(db);
    if (!rules.enabled) return err(404, 'not_found');
    final s = await openGuestSession(
      db,
      tableId: t.tableId,
      ttlHours: rules.sessionHours,
    );
    return json({
      'sessionId': s.id,
      'expiresAt': s.expiresAt.toIso8601String(),
    });
  });

  r.post('/guest/orders', (Request req) async {
    final s = await session(req);
    if (s == null) return err(401, 'session_expired');
    // Nothing else caps this. A session is free, an order writes rows and fans
    // out to every KDS in the venue, and the only credential involved is a
    // code printed on a card anyone in the room can read.
    if (callerIp.trip(ipOf(req))) return err(429, 'too_many');
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final t = await point(req, body);
    if (t == null || t.tableId != s.tableId) return err(404, 'not_found');
    try {
      final o = await submitGuestOrder(
        db,
        session: s,
        tableId: t.tableId,
        lines: ((body['lines'] as List?) ?? const [])
            .cast<Map<String, dynamic>>(),
        hub: hub,
      );
      return json(await guestOrderJson(db, o));
    } on SelfOrderException catch (e) {
      return err(409, e.code);
    }
  });

  /// "Pesanan saya" — polled every few seconds by the phone. There is no
  /// second WebSocket hub for guests: a handful of phones asking a LAN server
  /// for a small JSON list is cheaper than a second fan-out to keep correct.
  r.get('/guest/orders', (Request req) async {
    final s = await session(req);
    if (s == null) return err(401, 'session_expired');
    return json({'orders': await guestOrdersJson(db, sessionId: s.id)});
  });

  /// The **only** member fact on this plane (ADR-0110). Two integers out — how
  /// far into the card, how long a card is — for a phone the caller already
  /// had, and the same two whether that number is enrolled or not.
  ///
  /// It is not a member route: it takes no [ServerAuth] like everything else
  /// here, reads through `members.dart` rather than the tables, and 404s on a
  /// venue without the program exactly as an authenticated member route would
  /// (ADR-0091). Read-only — the reward itself is redeemed at the till.
  r.post('/guest/punch', (Request req) async {
    final s = await session(req);
    if (s == null) return err(401, 'session_expired');
    // Counted before the answer, so a rejected try still costs a try. A punch
    // check is a once-per-visit act; anything shaped like a sweep is not this
    // feature.
    final tries = (punchTries[s.id] ?? 0) + 1;
    punchTries[s.id] = tries;
    if (tries > 5) return err(429, 'too_many');
    if (callerIp.trip(ipOf(req))) return err(429, 'too_many');
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final phone = ((body['phone'] as String?) ?? '').trim();
    if (phone.isEmpty) return err(400, 'bad_request');
    // After the empty check, so a blank body cannot burn a real number's
    // allowance, and before the lookup, so a miss costs the same as a hit — a
    // 404 that is cheaper than a 200 is itself an oracle.
    if (punchPhone.trip(phone)) return err(429, 'too_many');
    final st = await guestPunchStatus(db, phone);
    if (st == null) return err(404, 'not_found');
    return json({'progress': st.progress, 'target': st.target});
  });

  r.delete('/guest/orders/<id>', (Request req, String id) async {
    final s = await session(req);
    if (s == null) return err(401, 'session_expired');
    try {
      final o = await cancelGuestOrder(
        db,
        orderId: id,
        sessionId: s.id,
        hub: hub,
      );
      return json(await guestOrderJson(db, o));
    } on SelfOrderException catch (e) {
      return err(e.code == 'not_found' ? 404 : 409, e.code);
    }
  });

  return r;
}
