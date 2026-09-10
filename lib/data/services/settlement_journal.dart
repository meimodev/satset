import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/db/client_db.dart';
import 'package:satset/domain/models/settlement_event.dart';
import 'package:satset/domain/use_cases/settlement_projection.dart';

const _uuid = Uuid();

/// Raised when one visit — or the device — has captured more settlement than it
/// can be trusted to hold.
class SettlementJournalFull implements Exception {
  /// True when the cap that tripped was this visit's, not the device's.
  final bool perVisit;
  const SettlementJournalFull({this.perVisit = true});
}

/// How the host answered one replayed chain.
class ChainOutcome {
  final String visitId;

  /// Events the host took, oldest first.
  final List<SettlementEvent> delivered;

  /// The one event the host refused, if any. Everything after it in the chain
  /// is [parked] — untried, not failed.
  final SettlementEvent? refused;
  final String? code;
  final List<SettlementEvent> parked;

  /// Rupiah the till collected on this visit that the host has not taken.
  final int strandedAmount;

  const ChainOutcome({
    required this.visitId,
    this.delivered = const [],
    this.refused,
    this.code,
    this.parked = const [],
    this.strandedAmount = 0,
  });

  bool get needsAttention => refused != null;
}

/// Everything one journal drain produced.
class SettlementReport {
  final List<ChainOutcome> chains;

  /// True when the drain stopped early — the host stopped answering, or refused
  /// the bearer. Whatever is left is still journalled.
  final bool interrupted;

  const SettlementReport({required this.chains, this.interrupted = false});

  List<ChainOutcome> get failures => [
    for (final c in chains)
      if (c.needsAttention) c,
  ];

  bool get isEmpty => chains.isEmpty;
}

/// What the UI needs to know without querying: which visits are
/// [[Kunjungan otoritatif-lokal|local-authoritative]], and whether a chain is
/// parked on a refusal.
class JournalState {
  /// Visit ids with at least one undelivered event.
  final Set<String> pendingVisits;

  /// Visit ids whose chain halted on a refusal and is waiting on a human.
  final Set<String> parkedVisits;

  /// True while a drain is in flight — what the `/kasir` header pulses on.
  final bool draining;

  final List<SettlementEvent> events;

  const JournalState({
    this.pendingVisits = const {},
    this.parkedVisits = const {},
    this.draining = false,
    this.events = const [],
  });

  bool isLocal(String visitId) => pendingVisits.contains(visitId);

  JournalState copyWith({
    Set<String>? pendingVisits,
    Set<String>? parkedVisits,
    bool? draining,
    List<SettlementEvent>? events,
  }) => JournalState(
    pendingVisits: pendingVisits ?? this.pendingVisits,
    parkedVisits: parkedVisits ?? this.parkedVisits,
    draining: draining ?? this.draining,
    events: events ?? this.events,
  );
}

/// Delivers one event to the host. Injected so the journal can be tested
/// without HTTP, and so it never learns what an `ApiClient` is.
///
/// Throws to refuse; returns normally to accept.
typedef EventSender = Future<void> Function(SettlementEvent event);
typedef BillCheckpoint =
    Future<Map<String, dynamic>> Function(
      String visitId,
      List<SettlementEvent> acknowledged,
    );

class SettlementVisitReadOnly implements Exception {
  final String visitId;
  const SettlementVisitReadOnly(this.visitId);
  @override
  String toString() => 'SettlementVisitReadOnly($visitId)';
}

/// The device-local **[[Antrean setelmen]]** (ADR-0123).
///
/// Append-only, ordered per [[Visit]], replayed through the ordinary routes.
/// Unlike the [[Antrean kirim]] it is **read** as well as drained — the cashier
/// needs a total for the guest at the counter — which is why it lives in the
/// client database (ADR-0124) rather than a prefs blob.
class SettlementJournal extends StateNotifier<JournalState> {
  SettlementJournal({required this.db, required this.send, this.loadBill})
    : super(const JournalState()) {
    unawaited(_refreshState());
  }

  final ClientDb db;
  final EventSender send;
  final BillCheckpoint? loadBill;
  Future<void> _writes = Future.value();
  Future<SettlementReport>? _drainFuture;

  Future<T> _write<T>(Future<T> Function() action) {
    final next = _writes.then((_) => db.transaction(action));
    _writes = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> assertWritable(String visitId) async {
    if ((await eventsFor(visitId)).any((e) => e.isParked)) {
      throw SettlementVisitReadOnly(visitId);
    }
  }

  Future<SettlementEvent?> eventById(String id) async {
    final row = await (db.select(
      db.settlementEvents,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Recover a captured seat even if the debounced floor cache was not saved.
  Future<String?> capturedVisitForTable(String tableId) async {
    final seats =
        await (db.select(db.settlementEvents)
              ..where(
                (e) => e.tableId.equals(tableId) & e.kind.equals('seatTable'),
              )
              ..orderBy([(e) => OrderingTerm.desc(e.capturedAt)]))
            .get();
    for (final seat in seats) {
      final events = await eventsFor(seat.visitId);
      if (!events.any(
        (e) => e.kind == SettlementEventKind.closeBill && !e.isParked,
      )) {
        return seat.visitId;
      }
    }
    return null;
  }

  /// A consistent baseline and event list, including during checkpoint commit.
  Future<({Map<String, dynamic>? bill, List<SettlementEvent> events})>
  projectionFor(String visitId) => db.transaction(
    () async =>
        (bill: await cachedBill(visitId), events: await eventsFor(visitId)),
  );

  /// A bill that took this many acts is a bug, not a busy night.
  static const maxPerVisit = 100;

  /// And a device holding this much uncollected money has a bigger problem
  /// than one more receipt.
  static const maxTotal = 1000;

  // ── capture ───────────────────────────────────────────────────────────────

  /// Append one act. Returns the event, whose [SettlementEvent.id] is also the
  /// id of whatever row it mints and the idempotency key of its replay.
  Future<SettlementEvent> append({
    required String visitId,
    required SettlementEventKind kind,
    Map<String, dynamic> payload = const {},
    String? id,
    String? tableId,
    String actorId = '',
    DateTime? capturedAt,
  }) async {
    final event = await _write(
      () => _append(
        visitId: visitId,
        kind: kind,
        payload: payload,
        id: id,
        tableId: tableId,
        actorId: actorId,
        capturedAt: capturedAt,
      ),
    );
    await _refreshState();
    return event;
  }

  Future<SettlementEvent> _append({
    required String visitId,
    required SettlementEventKind kind,
    Map<String, dynamic> payload = const {},
    String? id,
    String? tableId,
    String actorId = '',
    DateTime? capturedAt,
  }) async {
    // The id *is* the idempotency key, so capturing the same one twice is the
    // same claim made twice — a retried tap, or a POST that timed out and was
    // captured under the key it already carried. Return what is already on the
    // chain rather than inserting a second row: one order captured is one
    // order sent, and a primary-key collision here would surface to the waiter
    // as a failed order they in fact placed.
    if (id != null) {
      final existing =
          await (db.select(db.settlementEvents)
                ..where((e) => e.id.equals(id))
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) return _fromRow(existing);
    }
    await assertWritable(visitId);
    final mine = await eventsFor(visitId);
    if (mine.length >= maxPerVisit) {
      throw const SettlementJournalFull();
    }
    final total = await db.settlementEvents.count().getSingle();
    if (total >= maxTotal) {
      throw const SettlementJournalFull(perVisit: false);
    }
    final ev = SettlementEvent(
      id: id ?? _uuid.v4(),
      visitId: visitId,
      seq: mine.isEmpty ? 0 : mine.last.seq + 1,
      kind: kind,
      payload: payload,
      capturedAt: capturedAt ?? SatClock.now().toUtc(),
      tableId: tableId,
      actorId: actorId,
    );
    await db
        .into(db.settlementEvents)
        .insert(
          SettlementEventsCompanion.insert(
            id: ev.id,
            visitId: ev.visitId,
            seq: ev.seq,
            kind: ev.kind.name,
            payloadJson: Value(jsonEncode(ev.payload)),
            capturedAt: ev.capturedAt,
            tableId: Value(ev.tableId),
            actorId: Value(ev.actorId),
          ),
        );
    return ev;
  }

  /// Open a **[[Kunjungan tertangkap]]** for [tableId] and return its id
  /// (ADR-0139).
  ///
  /// Mints the visit id on the device — the thing the old sender refused on
  /// principle — and does the two writes that make it a real visit here rather
  /// than at any call site:
  ///
  /// 1. the `seatTable` event, which is what the host is eventually told, and
  /// 2. a **seed bill** in [CachedBills], because every other bill on this
  ///    device starts life as the host's own JSON and this one has no host to
  ///    get it from. Without the seed the projection has nothing to project
  ///    onto and `/kasir` shows a visit it cannot open.
  ///
  /// Both, or neither: a seat event with no seed is a bill the cashier can see
  /// in the list and cannot settle, which is the failure ADR-0139 exists to
  /// remove, reintroduced one layer down.
  Future<String> openCapturedVisit({
    String? visitId,
    required String tableId,
    required int pax,
    String? tableLabel,
    String? guestName,
    String? guestNotes,
    String actorId = '',
    bool splitEnabled = false,
    bool ticketAttribution = false,
    bool taxAfterDiscount = false,
  }) async {
    final capturedVisitId = visitId ?? _uuid.v4();
    final at = SatClock.now().toUtc();
    await _write(() async {
      await _append(
        visitId: capturedVisitId,
        kind: SettlementEventKind.seatTable,
        tableId: tableId,
        actorId: actorId,
        capturedAt: at,
        payload: {
          'pax': pax,
          'guestName': ?guestName,
          'guestNotes': ?guestNotes,
        },
      );
      await cacheBill(
        capturedVisitId,
        capturedBillSeed(
          visitId: capturedVisitId,
          tableId: tableId,
          tableLabel: tableLabel,
          openedAt: at,
          pax: pax,
          guestName: guestName,
          splitEnabled: splitEnabled,
          ticketAttribution: ticketAttribution,
          taxAfterDiscount: taxAfterDiscount,
        ),
      );
    });
    await _refreshState();
    SatLog.repo('journal.capturedVisit table=$tableId');
    return capturedVisitId;
  }

  /// Every event on one visit, in capture order. Parked ones included — the
  /// projection skips them, the refusal sheet lists them.
  Future<List<SettlementEvent>> eventsFor(String visitId) async {
    final rows =
        await (db.select(db.settlementEvents)
              ..where((e) => e.visitId.equals(visitId))
              ..orderBy([(e) => OrderingTerm.asc(e.seq)]))
            .get();
    return [for (final r in rows) _fromRow(r)];
  }

  /// Visit ids holding anything undelivered, oldest capture first — with the
  /// **venue-scope chain first of all** (ADR-0129).
  ///
  /// An offline enrolment has no visit and everything that names that member
  /// does, so the order is not cosmetic: an attach replayed before its
  /// enrolment names somebody the host has never heard of.
  Future<List<String>> pendingVisitIds() async {
    final rows = await (db.select(
      db.settlementEvents,
    )..orderBy([(e) => OrderingTerm.asc(e.seq)])).get();
    final seen = <String>{};
    for (final r in rows) {
      seen.add(r.visitId);
    }
    final ids = seen.toList();
    if (ids.remove(kVenueScopeVisitId)) ids.insert(0, kVenueScopeVisitId);
    return ids;
  }

  /// Rewrite every queued reference to a member id the host discarded.
  ///
  /// Called when an enrolment drained into a [[Pendaftaran terlipat]]: the
  /// standing record won, so the attach and the redeem queued behind it name
  /// a member that does not exist. Payload-level and blunt on purpose — the id
  /// is a uuid, so a substring match cannot collide with anything else in the
  /// blob (ADR-0129).
  Future<void> rewriteMemberId(String from, String to) async {
    if (from == to) return;
    final rows = await db.select(db.settlementEvents).get();
    for (final r in rows) {
      if (!r.payloadJson.contains(from)) continue;
      await (db.update(
        db.settlementEvents,
      )..where((e) => e.id.equals(r.id))).write(
        SettlementEventsCompanion(
          payloadJson: Value(r.payloadJson.replaceAll(from, to)),
        ),
      );
    }
    SatLog.repo('settlement.rewriteMember $from -> $to');
  }

  // ── the cached bill (ADR-0123 §Q19) ───────────────────────────────────────

  /// Keep the host's own bill JSON for a visit, so it is settleable when the
  /// host goes away. Prefetched for **every** open visit while online — caching
  /// only what the cashier happened to open makes the fallback's availability
  /// depend on where a thumb was five minutes ago.
  Future<void> cacheBill(String visitId, Map<String, dynamic> json) async {
    await db
        .into(db.cachedBills)
        .insertOnConflictUpdate(
          CachedBillsCompanion.insert(
            visitId: visitId,
            billJson: jsonEncode(json),
            fetchedAt: SatClock.now().toUtc(),
          ),
        );
  }

  /// A fetch begun before capture must not overwrite that capture's baseline.
  Future<bool> cacheServerBill(String visitId, Map<String, dynamic> json) =>
      _write(() async {
        if ((await eventsFor(visitId)).any((e) => !e.kind.isMemberScope)) {
          return false;
        }
        await cacheBill(visitId, json);
        return true;
      });

  /// When each visit's cached bill was last pulled, for the prefetch sweep's
  /// per-visit throttle. A **global** throttle cannot express the case that
  /// matters: a visit skipped for being [[Kunjungan otoritatif-lokal]] would
  /// then be locked out by the very sweep that skipped it, and the cache it
  /// kept predates the settlement that just drained.
  Future<Map<String, DateTime>> cacheAges() async {
    return {
      for (final row in await db.select(db.cachedBills).get())
        row.visitId: row.fetchedAt,
    };
  }

  // ── a queued expense's photo (ADR-0130) ──────────────────────────────────

  /// Park the bytes a queued [[Pengeluaran kunjungan]] will post, keyed by the
  /// intent id. The [[Antrean kirim]] is a prefs blob and cannot hold them.
  Future<void> parkExpensePhoto(String intentId, Uint8List bytes) async {
    await db
        .into(db.queuedPhotos)
        .insertOnConflictUpdate(
          QueuedPhotosCompanion.insert(intentId: intentId, bytes: bytes),
        );
  }

  Future<Uint8List?> expensePhoto(String intentId) async {
    final row = await (db.select(
      db.queuedPhotos,
    )..where((q) => q.intentId.equals(intentId))).getSingleOrNull();
    return row?.bytes;
  }

  /// Called once the intent has landed. A row that outlives its intent is an
  /// orphan nothing will ever read.
  Future<void> dropExpensePhoto(String intentId) async {
    await (db.delete(
      db.queuedPhotos,
    )..where((q) => q.intentId.equals(intentId))).go();
  }

  Future<Map<String, dynamic>?> cachedBill(String visitId) async {
    final row = await (db.select(
      db.cachedBills,
    )..where((b) => b.visitId.equals(visitId))).getSingleOrNull();
    if (row == null) return null;
    try {
      return (jsonDecode(row.billJson) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  /// Keep the host's payable list, so a cold boot with no host still has a way
  /// into the bills it cached (ADR-0124). Overwritten whole, never merged: the
  /// host's list is the list, and a bill that left it is settled or gone.
  Future<void> cachePayable(List<dynamic> json) async {
    await db
        .into(db.cachedPayable)
        .insertOnConflictUpdate(
          CachedPayableCompanion.insert(
            id: payableRowId,
            listJson: jsonEncode(json),
            fetchedAt: SatClock.now().toUtc(),
          ),
        );
  }

  Future<List<dynamic>?> cachedPayable() async {
    final row = await (db.select(
      db.cachedPayable,
    )..where((r) => r.id.equals(payableRowId))).getSingleOrNull();
    if (row == null) return null;
    try {
      final decoded = jsonDecode(row.listJson);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Which visit a receipt belongs to.
  ///
  /// Receipt-scoped routes name only the receipt, but the journal is ordered
  /// per visit — a chain is what makes a settlement replayable.
  ///
  /// **The journal is asked first, and that is load-bearing.** The settle pane
  /// mints and pays in one gesture (ADR-0067), so the receipt a captured
  /// payment names was itself captured moments earlier and exists in no cached
  /// bill yet. Looking only at the cache strands the payment behind a receipt
  /// that is right there — the till then falls through to a network call that
  /// cannot succeed, and the guest's cash is nowhere.
  ///
  /// A `mintReceipt` event's id **is** its receipt id (ADR-0123); a
  /// `splitEven` event carries one id per share.
  Future<String?> visitOfReceipt(String receiptId) async {
    for (final r in await db.select(db.settlementEvents).get()) {
      final kind = settlementKindFromName(r.kind);
      if (kind == SettlementEventKind.mintReceipt && r.id == receiptId) {
        return r.visitId;
      }
      if (kind != SettlementEventKind.splitEven) continue;
      try {
        final ids = (jsonDecode(r.payloadJson) as Map)['ids'];
        if (ids is List && ids.contains(receiptId)) return r.visitId;
      } catch (_) {
        continue;
      }
    }
    for (final row in await db.select(db.cachedBills).get()) {
      try {
        final bill = (jsonDecode(row.billJson) as Map).cast<String, dynamic>();
        for (final r in (bill['receipts'] as List? ?? const [])) {
          if ((r as Map)['id'] == receiptId) return row.visitId;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Drop a visit's cache and its (drained) journal. Called when a bill closes
  /// clean — nothing here is authoritative once the host has taken it.
  Future<void> forget(String visitId) async {
    await _write(() async {
      await (db.delete(
        db.settlementEvents,
      )..where((e) => e.visitId.equals(visitId))).go();
      await (db.delete(
        db.cachedBills,
      )..where((b) => b.visitId.equals(visitId))).go();
    });
    await _refreshState();
  }

  // ── drain ─────────────────────────────────────────────────────────────────

  /// Replay every chain. Per visit, in capture order, **halting that visit on
  /// its first refusal** — a refund whose payment was refused must never land.
  /// Other visits keep draining.
  Future<SettlementReport> drain() {
    if (_drainFuture != null) return _drainFuture!;
    return _drainFuture = _drain().whenComplete(() => _drainFuture = null);
  }

  Future<SettlementReport> _drain() async {
    final visits = await pendingVisitIds();
    if (visits.isEmpty) return const SettlementReport(chains: []);
    state = state.copyWith(draining: true);
    final chains = <ChainOutcome>[];
    var interrupted = false;
    try {
      for (final visitId in visits) {
        final events = await eventsFor(visitId);
        // A later append must never drain around a refusal, including legacy rows.
        if (events.isEmpty || events.any((e) => e.isParked)) continue;
        final delivered = <SettlementEvent>[];
        SettlementEvent? refused;
        String? code;
        for (final ev in events) {
          try {
            if (!ev.isAcknowledged) {
              await send(ev);
              await _write(() async {
                await (db.update(
                  db.settlementEvents,
                )..where((e) => e.id.equals(ev.id))).write(
                  const SettlementEventsCompanion(
                    status: Value('acknowledged'),
                  ),
                );
              });
            }
            delivered.add(ev);
          } on SettlementRefused catch (e) {
            refused = ev;
            code = e.code;
            await _write(() => _park(visitId, code!));
            break;
          } catch (e, st) {
            SatLog.err('settlement drain', e, st);
            interrupted = true;
            break;
          }
        }
        if (!interrupted && refused == null) {
          try {
            // Sends stop at this prefix while the snapshot is read. New captures
            // may append, but cannot be sent or deleted by this checkpoint.
            final authority = events.any((e) => !e.kind.isMemberScope);
            final snapshot = authority
                ? await (loadBill ?? _missingCheckpoint)(visitId, delivered)
                : null;
            await _write(() async {
              if (snapshot != null) await cacheBill(visitId, snapshot);
              final ids = delivered.map((e) => e.id).toList();
              await (db.delete(db.settlementEvents)..where(
                    (e) => e.id.isIn(ids) & e.status.equals('acknowledged'),
                  ))
                  .go();
            });
          } catch (e, st) {
            SatLog.err('settlement checkpoint', e, st);
            interrupted = true;
          }
        }
        final left = await eventsFor(visitId);
        chains.add(
          ChainOutcome(
            visitId: visitId,
            delivered: delivered,
            refused: refused,
            code: code,
            parked: refused == null
                ? const []
                : left.where((e) => e.isParked).toList(),
            strandedAmount: refused == null
                ? 0
                : _moneyIn(left.where((e) => e.isParked)),
          ),
        );
        await _refreshState();
        if (interrupted) break;
      }
    } finally {
      state = state.copyWith(draining: false);
      await _refreshState();
    }
    return SettlementReport(chains: chains, interrupted: interrupted);
  }

  Future<Map<String, dynamic>> _missingCheckpoint(
    String visitId,
    List<SettlementEvent> events,
  ) async => throw StateError('No bill checkpoint configured for $visitId');

  /// Mark a visit's whole remaining chain parked, carrying the host's code on
  /// the event that was actually refused (the first one left).
  Future<void> _park(String visitId, String code) async {
    await (db.update(
          db.settlementEvents,
        )..where((e) => e.visitId.equals(visitId) & e.status.equals('pending')))
        .write(const SettlementEventsCompanion(status: Value('parked')));
    final first =
        await (db.select(db.settlementEvents)
              ..where(
                (e) => e.visitId.equals(visitId) & e.status.equals('parked'),
              )
              ..orderBy([(e) => OrderingTerm.asc(e.seq)])
              ..limit(1))
            .getSingleOrNull();
    if (first != null) {
      await (db.update(db.settlementEvents)
            ..where((e) => e.id.equals(first.id)))
          .write(SettlementEventsCompanion(failCode: Value(code)));
    }
  }

  /// The chains a past drain parked, rebuilt from the journal.
  ///
  /// The drain's report is in memory and one-shot, so a refusal that lands
  /// while `/kasir` is not mounted — the bill sheet is a root-navigator push,
  /// the ADR-0103 shape — or that is followed by a restart leaves real cash
  /// parked with nothing to show for it. The refusal surface re-reads this
  /// instead of trusting it saw the drain.
  Future<List<ChainOutcome>> parkedChains() async {
    final rows =
        await (db.select(db.settlementEvents)
              ..where((e) => e.status.equals('parked'))
              ..orderBy([(e) => OrderingTerm.asc(e.seq)]))
            .get();
    final byVisit = <String, List<SettlementEvent>>{};
    final codes = <String, String?>{};
    for (final r in rows) {
      byVisit.putIfAbsent(r.visitId, () => []).add(_fromRow(r));
      codes[r.visitId] ??= r.failCode;
    }
    return [
      for (final e in byVisit.entries)
        ChainOutcome(
          visitId: e.key,
          delivered: (await eventsFor(
            e.key,
          )).where((event) => event.isAcknowledged).toList(),
          refused: e.value.first,
          code: codes[e.key],
          parked: e.value,
          strandedAmount: _moneyIn(e.value),
        ),
    ];
  }

  /// The cashier acknowledged a parked chain (ADR-0123 §refusal surface). The
  /// events go; the money difference is now a human's problem, and the audit
  /// row the host wrote is where it lives.
  Future<void> acknowledge(String visitId) => forget(visitId);

  int _moneyIn(Iterable<SettlementEvent> events) => events
      .where((e) => e.kind == SettlementEventKind.recordPayment)
      .fold<int>(0, (a, e) => a + e.intArg('amount'));

  Future<void> _refreshState() async {
    final rows = await db.select(db.settlementEvents).get();
    state = state.copyWith(
      events: [for (final r in rows) _fromRow(r)],
      // **Money only.** A visit holding nothing but member-scope acts is not
      // [[Kunjungan otoritatif-lokal]] — see `isMemberScope` (ADR-0129). The
      // venue-scope chain hangs off no visit and never appears here at all.
      pendingVisits: {
        for (final r in rows)
          if (r.visitId != kVenueScopeVisitId &&
              !(settlementKindFromName(r.kind)?.isMemberScope ?? false))
            r.visitId,
      },
      parkedVisits: {
        for (final r in rows)
          if (r.status == 'parked') r.visitId,
      },
    );
  }

  SettlementEvent _fromRow(SettlementEventRow r) => SettlementEvent(
    id: r.id,
    visitId: r.visitId,
    seq: r.seq,
    // A row written by a newer build reads as `mintReceipt` nowhere — it is
    // dropped from the projection rather than guessed at.
    kind: settlementKindFromName(r.kind) ?? SettlementEventKind.reopenBill,
    payload: () {
      try {
        return (jsonDecode(r.payloadJson) as Map).cast<String, dynamic>();
      } catch (_) {
        return <String, dynamic>{};
      }
    }(),
    capturedAt: r.capturedAt,
    tableId: r.tableId,
    actorId: r.actorId,
    status: r.status,
    failCode: r.failCode,
  );
}

/// The host said no. Distinct from a transport failure, which leaves the chain
/// untouched — this one parks it (ADR-0123).
class SettlementRefused implements Exception {
  final String code;
  const SettlementRefused(this.code);
  @override
  String toString() => 'SettlementRefused($code)';
}
