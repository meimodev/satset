import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/time/business_day.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/error_bus_service.dart';
import 'package:satset/data/services/prefs_service.dart';

const _uuid = Uuid();

/// What a queued intent asks the host to do. Deliberately short: these are the
/// only two acts a terputus handset may capture (ADR-0090). Editing or voiding
/// a line that has not been delivered yet never becomes an intent — it rewrites
/// the queued [SendIntent] in place, because the host has never heard of it.
enum SendIntentKind { seatTable, submitOrder }

/// One act a waiter performed while their handset could not reach the host.
///
/// An intent is a *request*, not a row: it holds what was asked for and the key
/// it will be replayed under, never the ticket ids, visit or stock decisions
/// that only the host may mint.
class SendIntent {
  /// Also the idempotency key. Stable across every retry, which is what makes
  /// a replay that times out after the host committed harmless — the second
  /// attempt reads the stored response instead of ordering the food twice.
  final String id;
  final SendIntentKind kind;
  final String tableId;

  /// The visit the table was on when this was captured, if the handset knew
  /// one. Sent as `expectedVisitId` so the host refuses rather than attaching
  /// to whoever is sitting there now. Null when the table had no open visit —
  /// then the host mints one as it always does.
  final String? expectedVisitId;

  final DateTime capturedAt;

  /// The waiter who performed the act. Survives a handset handover and stays
  /// the line's author — ADR-0056 never backfills authorship.
  final String actorId;

  /// `submitOrder`: `{'lines': [...]}`. `seatTable`: `{'pax': n}`.
  final Map<String, dynamic> payload;

  const SendIntent({
    required this.id,
    required this.kind,
    required this.tableId,
    required this.capturedAt,
    required this.actorId,
    required this.payload,
    this.expectedVisitId,
  });

  SendIntent copyWith({Map<String, dynamic>? payload}) => SendIntent(
    id: id,
    kind: kind,
    tableId: tableId,
    capturedAt: capturedAt,
    actorId: actorId,
    payload: payload ?? this.payload,
    expectedVisitId: expectedVisitId,
  );

  /// The lines of a `submitOrder`, or empty for any other kind.
  List<Map<String, dynamic>> get lines => [
    for (final l in (payload['lines'] as List? ?? const []))
      (l as Map).cast<String, dynamic>(),
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'tableId': tableId,
    'expectedVisitId': expectedVisitId,
    'capturedAt': capturedAt.toIso8601String(),
    'actorId': actorId,
    'payload': payload,
  };

  static SendIntent? fromJson(Map<String, dynamic> j) {
    final kind = SendIntentKind.values
        .where((k) => k.name == j['kind'])
        .firstOrNull;
    final capturedAt = DateTime.tryParse((j['capturedAt'] as String?) ?? '');
    if (kind == null || capturedAt == null) return null;
    return SendIntent(
      id: j['id'] as String,
      kind: kind,
      tableId: (j['tableId'] as String?) ?? '',
      expectedVisitId: j['expectedVisitId'] as String?,
      capturedAt: capturedAt,
      actorId: (j['actorId'] as String?) ?? '',
      payload: ((j['payload'] as Map?) ?? const {}).cast<String, dynamic>(),
    );
  }
}

/// How the host answered one intent.
enum SendOutcomeKind {
  /// Accepted. Some lines may still have been refused for stock — those ride
  /// in [SendOutcome.rejectedLines], exactly as an online send reports them.
  delivered,

  /// The host said no: the visit changed guests, the bill had closed, the
  /// line was frozen. The waiter has to do something about it.
  refused,

  /// Never offered. It outlived the business day it was captured in, and a
  /// day that has closed its books cannot absorb it.
  expired,
}

class SendOutcome {
  final SendIntent intent;
  final SendOutcomeKind kind;

  /// The host's machine-readable `code` for a refusal (`visit_changed`,
  /// `bill_closed`, …). A code crosses the layer; the words are composed at
  /// read time (ADR-0085).
  final String? code;

  /// Per-line stock refusals on an otherwise delivered order (ADR-0041).
  final List<Map<String, dynamic>> rejectedLines;

  /// The visit the host filed this order under — the one on a refusal too, so
  /// the caller can say *which* guest the table now holds.
  final String? visitId;

  const SendOutcome({
    required this.intent,
    required this.kind,
    this.code,
    this.rejectedLines = const [],
    this.visitId,
  });

  bool get needsAttention =>
      kind != SendOutcomeKind.delivered || rejectedLines.isNotEmpty;
}

/// Everything one drain produced, plus whether the queue emptied.
class SendReport {
  final List<SendOutcome> outcomes;

  /// True when the drain stopped early — the host stopped answering, or
  /// refused the bearer. Whatever is left is still queued.
  final bool interrupted;

  const SendReport({required this.outcomes, this.interrupted = false});

  List<SendOutcome> get failures => [
    for (final o in outcomes)
      if (o.needsAttention) o,
  ];

  bool get isEmpty => outcomes.isEmpty;
}

/// Raised when a handset has captured more than it can be trusted to hold.
class SendQueueFull implements Exception {
  const SendQueueFull();
}

/// Delivers one intent to the host. Injected so the drain can be tested
/// without HTTP, and so the queue never learns what an `ApiClient` is.
typedef IntentSender = Future<Map<String, dynamic>> Function(SendIntent intent);

/// The device-local **Antrean kirim**: a FIFO of intents a terputus handset
/// captured, replayed through the ordinary routes when the host comes back.
///
/// The queue belongs to the **device**, not the session — handsets are shared
/// and a backlog must survive the handover that ADR-0065 exists to allow. It
/// persists as JSON in prefs because a shift's backlog is tens of intents; if
/// it ever needs querying rather than draining, that is the moment for a
/// client-side database and not before. See ADR-0090.
class SendQueue extends StateNotifier<List<SendIntent>> {
  /// [prefs] may be the service or a future for it. The future form exists
  /// because prefs resolve a few frames into boot, and the queue must **not**
  /// be rebuilt when they land — a rebuilt notifier is a disposed one, and an
  /// order captured in those frames would die with it. So it starts empty,
  /// hydrates when the future completes, and never watches prefs again.
  SendQueue({
    FutureOr<PrefsService>? prefs,
    required this.send,
    this.businessDayStartHour = 4,
    this.onCorrupt,
  }) : _prefs = prefs is PrefsService ? prefs : null,
       super(const []) {
    // Loading in the body rather than the initialiser list, so `_load` can
    // reach `onCorrupt` and `_prefs`. Nothing can be listening yet, so the
    // assignment is indistinguishable from having started at that value.
    if (prefs is PrefsService) {
      state = _load(prefs);
    } else if (prefs is Future<PrefsService>) {
      unawaited(_hydrate(prefs));
    }
  }

  /// Told when a stored backlog could not be parsed.
  /// Wired to the error bus by the provider: orders were captured
  /// and cannot be replayed, and the person holding the handset is the only
  /// one who can do anything about that.
  final void Function()? onCorrupt;

  /// Adopt the stored backlog once prefs resolve.
  Future<void> _hydrate(Future<PrefsService> pending) async {
    final p = await pending;
    if (!mounted) return;
    _prefs = p;
    final stored = _load(p);
    // Anything captured while prefs were resolving is newer than what was on
    // disk, and FIFO is the whole contract — stored intents go in front. They
    // cannot be duplicates: with no prefs to write to, `_persist` was a no-op.
    if (stored.isNotEmpty) state = [...stored, ...state];
    await _persist();
  }

  PrefsService? _prefs;
  final IntentSender send;

  /// The rollover intents expire on. Read from the venue's cached settings;
  /// 04:00 is the same default the server falls back to.
  final int businessDayStartHour;

  /// A real shift never approaches this. Reaching it means the drain is broken
  /// or the handset has been in a dead zone all night, and in both cases
  /// refusing the next order out loud beats swallowing it silently.
  static const maxIntents = 200;

  bool _draining = false;

  List<SendIntent> _load(PrefsService? prefs) {
    final raw = prefs?.sendQueueJson();
    if (raw == null || raw.isEmpty) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          ?SendIntent.fromJson((e as Map).cast<String, dynamic>()),
      ];
    } catch (_) {
      // A queue we cannot parse cannot be replayed, and wedging every boot on
      // it helps no one — so it comes out of the way. But it is still the
      // orders somebody took while the handset was cut off, so it moves aside
      // rather than being deleted: quarantined verbatim under its own key,
      // where a support session can read it back off the device.
      //
      // And it is said out loud. Silently dropping a backlog is how a venue
      // finds out at close that a table's food was never ordered.
      SatLog.repo('sendQueue.load corrupt — quarantined ${raw.length}B');
      unawaited(prefs!.setSendQueueQuarantineJson(raw));
      unawaited(prefs.setSendQueueJson(null));
      onCorrupt?.call();
      return const [];
    }
  }

  Future<void> _persist() async {
    await _prefs?.setSendQueueJson(
      state.isEmpty ? null : jsonEncode([for (final i in state) i.toJson()]),
    );
  }

  /// Capture an act the host cannot be told about yet.
  ///
  /// Throws [SendQueueFull] at [maxIntents] — the caller must surface that,
  /// never swallow it.
  Future<SendIntent> enqueue({
    required SendIntentKind kind,
    required String tableId,
    required String actorId,
    required Map<String, dynamic> payload,
    String? expectedVisitId,
  }) async {
    if (state.length >= maxIntents) throw const SendQueueFull();
    final intent = SendIntent(
      id: _uuid.v4(),
      kind: kind,
      tableId: tableId,
      expectedVisitId: expectedVisitId,
      capturedAt: SatClock.now(),
      actorId: actorId,
      payload: payload,
    );
    state = [...state, intent];
    await _persist();
    SatLog.repo('sendQueue.enqueue ${kind.name} depth=${state.length}');
    return intent;
  }

  /// Rewrite a queued order's lines — the waiter changed their mind before the
  /// host ever heard the order. An empty result drops the intent entirely,
  /// which is what voiding the last line means.
  Future<void> rewriteLines(
    String intentId,
    List<Map<String, dynamic>> lines,
  ) async {
    final found = state.where((i) => i.id == intentId).firstOrNull;
    if (found == null) return;
    if (lines.isEmpty) return discard(intentId);
    state = [
      for (final i in state)
        if (i.id == intentId)
          i.copyWith(payload: {...i.payload, 'lines': lines})
        else
          i,
    ];
    await _persist();
  }

  Future<void> discard(String intentId) async {
    state = [
      for (final i in state)
        if (i.id != intentId) i,
    ];
    await _persist();
  }

  /// Drop everything. Used by the explicit "buang" the end-of-shift block
  /// offers. Local-only by necessity: the audit writer lives on the host, and a
  /// host that could take this write would have taken the orders instead.
  Future<void> discardAll() async {
    state = const [];
    await _persist();
  }

  /// The intents captured on this device that belong to [actorId].
  List<SendIntent> forActor(String actorId) => [
    for (final i in state)
      if (i.actorId == actorId) i,
  ];

  /// Everything the queue is holding for a table, in capture order.
  List<SendIntent> forTable(String tableId) => [
    for (final i in state)
      if (i.tableId == tableId) i,
  ];

  bool get isEmpty => state.isEmpty;

  /// Replay the backlog, oldest first, one at a time.
  ///
  /// Strictly sequential and strictly in order: two orders on one table were
  /// taken in an order the guest remembers, and a parallel drain would file
  /// them in whichever finished first. A business refusal is recorded and the
  /// drain **continues** — one out-of-stock order must not strand the nine
  /// behind it. A transport failure or a rejected bearer **stops** it, leaving
  /// everything unsent still queued.
  Future<SendReport> drain() async {
    if (_draining || state.isEmpty) return const SendReport(outcomes: []);
    _draining = true;
    final outcomes = <SendOutcome>[];
    var interrupted = false;
    // Tables whose queued seat the host refused — it was already occupied, and
    // by whom is not knowable from here.
    final seatRefused = <String>{};
    try {
      final dayStart = businessDayStart(SatClock.now(), businessDayStartHour);
      // Snapshot: the list mutates underneath as each intent leaves it.
      for (final intent in [...state]) {
        // An order captured against a seat the host refused has no visit token
        // to check itself against — the visit it expected was never created.
        // Sending it blind would hang a stranger's food on whatever bill the
        // table now holds, which is the one outcome this whole design exists to
        // prevent. Refuse it here instead, with the reason the waiter needs.
        if (intent.kind == SendIntentKind.submitOrder &&
            intent.expectedVisitId == null &&
            seatRefused.contains(intent.tableId)) {
          outcomes.add(
            SendOutcome(
              intent: intent,
              kind: SendOutcomeKind.refused,
              code: 'visit_changed',
            ),
          );
          await discard(intent.id);
          continue;
        }
        if (intent.capturedAt.isBefore(dayStart)) {
          outcomes.add(
            SendOutcome(intent: intent, kind: SendOutcomeKind.expired),
          );
          await discard(intent.id);
          continue;
        }
        try {
          final res = await send(intent);
          outcomes.add(
            SendOutcome(
              intent: intent,
              kind: SendOutcomeKind.delivered,
              visitId: res['visitId'] as String?,
              rejectedLines: [
                for (final r in (res['rejected'] as List? ?? const []))
                  (r as Map).cast<String, dynamic>(),
              ],
            ),
          );
          await discard(intent.id);
        } on ApiException catch (e) {
          if (e.statusCode == 401 || e.statusCode == 403) {
            // The bearer cannot carry this backlog — a role changed, or the
            // handset is now signed in as someone without takeOrder. Stall and
            // say so; never self-authorise, never drop the orders.
            SatLog.repo('sendQueue.drain blocked ${e.statusCode}');
            interrupted = true;
            break;
          }
          if (e.statusCode >= 500) {
            interrupted = true;
            break;
          }
          if (intent.kind == SendIntentKind.seatTable) {
            seatRefused.add(intent.tableId);
          }
          outcomes.add(
            SendOutcome(
              intent: intent,
              kind: SendOutcomeKind.refused,
              code: e.code,
            ),
          );
          await discard(intent.id);
        } catch (_) {
          // Transport. The host was there a moment ago and is not now.
          interrupted = true;
          break;
        }
      }
    } finally {
      _draining = false;
    }
    SatLog.repo(
      'sendQueue.drain sent=${outcomes.length} left=${state.length} '
      'interrupted=$interrupted',
    );
    return SendReport(outcomes: outcomes, interrupted: interrupted);
  }
}

/// Posts one intent through the ordinary routes — the same `/orders` and
/// `/tables/:id/seat` an online handset hits. Replay reuses the production
/// path rather than a bulk endpoint of its own: a second way to create an
/// order is a second place for the stock, visit and audit rules to drift
/// (ADR-0090).
IntentSender apiIntentSender(ApiClient api) => (intent) async {
  switch (intent.kind) {
    case SendIntentKind.submitOrder:
      final raw = await api.postJson('/orders', {
        'tableId': intent.tableId,
        'idempotencyKey': intent.id,
        'lines': intent.lines,
        'actorId': intent.actorId,
        'capturedAt': intent.capturedAt.toIso8601String(),
        // Only ever a real server visit. A local key must not cross the wire —
        // the host would read it as "the table changed guests" and refuse an
        // order that is perfectly fine.
        'expectedVisitId': ?intent.expectedVisitId,
      });
      return (raw as Map).cast<String, dynamic>();
    case SendIntentKind.seatTable:
      final raw = await api.postJson('/tables/${intent.tableId}/seat', {
        'pax': (intent.payload['pax'] as num?)?.toInt() ?? 1,
        'actorId': intent.actorId,
        'guestName': ?intent.payload['guestName'] as String?,
        'guestNotes': ?intent.payload['guestNotes'] as String?,
      });
      return (raw as Map).cast<String, dynamic>();
  }
};

/// The device's send queue. Null-safe before prefs resolve: the queue simply
/// starts empty and persists nothing, which is the correct behaviour for the
/// handful of frames before boot completes.
final sendQueueProvider = StateNotifierProvider<SendQueue, List<SendIntent>>((
  ref,
) {
  // The future, not the value: watching `prefsServiceProvider` would
  // rebuild — and dispose — this queue the moment prefs resolve, taking any
  // order captured in the meantime with it.
  final prefs = ref.read(prefsServiceProvider.future);
  // Read, not watch: a settings change must not rebuild the queue and drop
  // an in-flight drain. The hour only matters at expiry, and a venue that
  // moves its rollover mid-shift can wait for the next boot.
  final hour = ref.read(venueSettingsProvider).businessDayStartHour;
  return SendQueue(
    prefs: prefs,
    businessDayStartHour: hour,
    onCorrupt: () => ref
        .read(errorBusServiceProvider)
        .push(ref.read(l10nProvider).sendQueueCorrupt, code: 'queue_corrupt'),
    send: (intent) async {
      // Resolved per call: the ApiClient is replaced whenever pairing
      // changes, and a queue that captured a stale one would post at the
      // old host.
      return apiIntentSender(ref.read(apiClientProvider))(intent);
    },
  );
});

/// The last drain's result, for the surface that has to show it. Null until a
/// drain has run; cleared once the waiter has acknowledged it.
final sendReportProvider = StateProvider<SendReport?>((_) => null);

/// The undelivered orders this device is holding for a table, oldest first.
///
/// A pesanan tertunda is rendered **from the queue**, never faked into the
/// ticket map: it is not a ticket, the kitchen has never seen it, and a bill
/// must not be able to reach it (ADR-0090).
final pendingOrdersForTableProvider = Provider.family<List<SendIntent>, String>(
  (ref, tableId) {
    final queue = ref.watch(sendQueueProvider);
    return [
      for (final i in queue)
        if (i.tableId == tableId && i.kind == SendIntentKind.submitOrder) i,
    ];
  },
);
