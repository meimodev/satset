import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/server/db/database.dart';

/// The header a replayed write carries. Already allowed through CORS in
/// `server.dart`.
const idempotencyHeader = 'x-idempotency-key';

/// Make every mutating request under [inner] replay-safe when it carries an
/// [idempotencyHeader] (ADR-0123).
///
/// The [[Antrean setelmen]] replays a *sequence* of acts, and most of them are
/// not naturally idempotent — replaying `split-even 4` twice is eight receipts,
/// replaying an assign doubles the units. Rather than hand-hardening a dozen
/// routes, the key rides the whole settlement surface and the first successful
/// response is stored and returned verbatim on any repeat. Same `Idempotency`
/// table `POST /orders` and `POST /tables/<id>/seat` already use — ADR-0090 made
/// the mechanism, this only widens who reaches it.
///
/// **Only 2xx is stored.** A refusal must stay a refusal the caller can act on,
/// and a chain halts on one anyway (ADR-0123) rather than retrying it.
Handler idempotent(AppDatabase db, Handler inner) {
  return (Request req) async {
    final key = req.headers[idempotencyHeader]?.trim() ?? '';
    final mutating =
        req.method == 'POST' ||
        req.method == 'PATCH' ||
        req.method == 'DELETE' ||
        req.method == 'PUT';
    if (key.isEmpty || !mutating) return inner(req);

    final prior = await (db.select(
      db.idempotency,
    )..where((k) => k.key.equals(key))).getSingleOrNull();
    if (prior != null) {
      // Says what the first attempt said and touches nothing — no second
      // broadcast, because nothing changed.
      return Response.ok(
        prior.responseJson,
        headers: {'content-type': 'application/json'},
      );
    }

    final resp = await inner(req);
    if (resp.statusCode < 200 || resp.statusCode >= 300) return resp;
    final body = await resp.readAsString();
    await db
        .into(db.idempotency)
        .insert(
          IdempotencyCompanion.insert(
            key: key,
            responseJson: body,
            createdAt: SatClock.now(),
          ),
          // A racing double-send claims the key once; the loser reads it back
          // on its next attempt rather than failing the write it just did.
          mode: InsertMode.insertOrIgnore,
        );
    return Response(
      resp.statusCode,
      body: body,
      headers: {'content-type': 'application/json'},
    );
  };
}
