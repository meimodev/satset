import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/db/client_db.dart';
import 'package:satset/domain/models/settlement_event.dart';

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

  const JournalState({
    this.pendingVisits = const {},
    this.parkedVisits = const {},
    this.draining = false,
  });

  bool isLocal(String visitId) => pendingVisits.contains(visitId);

  JournalState copyWith({
    Set<String>? pendingVisits,
    Set<String>? parkedVisits,
    bool? draining,
  }) => JournalState(
    pendingVisits: pendingVisits ?? this.pendingVisits,
    parkedVisits: parkedVisits ?? this.parkedVisits,
    draining: draining ?? this.draining,
  );
}

/// Delivers one event to the host. Injected so the journal can be tested
/// without HTTP, and so it never learns what an `ApiClient` is.
///
/// Throws to refuse; returns normally to accept.
typedef EventSender = Future<void> Function(SettlementEvent event);

/// The device-local **[[Antrean setelmen]]** (ADR-0123).
///
/// Append-only, ordered per [[Visit]], replayed through the ordinary routes.
/// Unlike the [[Antrean kirim]] it is **read** as well as drained — the cashier
/// needs a total for the guest at the counter — which is why it lives in the
/// client database (ADR-0124) rather than a prefs blob.
class SettlementJournal extends StateNotifier<JournalState> {
  SettlementJournal({required this.db, required this.send})
    : super(const JournalState()) {
    unawaited(_refreshState());
  }

  final ClientDb db;
  final EventSender send;

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
    String actorId = '',
    DateTime? capturedAt,
  }) async {
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
            actorId: Value(ev.actorId),
          ),
        );
    await _refreshState();
    return ev;
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
    final rows =
        await (db.select(db.settlementEvents)
              ..orderBy([(e) => OrderingTerm.asc(e.seq)]))
            .get();
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
      await (db.update(db.settlementEvents)..where((e) => e.id.equals(r.id)))
          .write(
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
    await (db.delete(
      db.settlementEvents,
    )..where((e) => e.visitId.equals(visitId))).go();
    await (db.delete(
      db.cachedBills,
    )..where((b) => b.visitId.equals(visitId))).go();
    await _refreshState();
  }

  // ── drain ─────────────────────────────────────────────────────────────────

  /// Replay every chain. Per visit, in capture order, **halting that visit on
  /// its first refusal** — a refund whose payment was refused must never land.
  /// Other visits keep draining.
  Future<SettlementReport> drain() async {
    final visits = await pendingVisitIds();
    if (visits.isEmpty) return const SettlementReport(chains: []);
    state = state.copyWith(draining: true);
    final chains = <ChainOutcome>[];
    var interrupted = false;
    try {
      for (final visitId in visits) {
        final events = [
          for (final e in await eventsFor(visitId))
            if (!e.isParked) e,
        ];
        if (events.isEmpty) continue;
        final delivered = <SettlementEvent>[];
        SettlementEvent? refused;
        String? code;
        for (final ev in events) {
          try {
            await send(ev);
            delivered.add(ev);
            await (db.delete(
              db.settlementEvents,
            )..where((e) => e.id.equals(ev.id))).go();
          } on SettlementRefused catch (e) {
            refused = ev;
            code = e.code;
            break;
          } catch (e, st) {
            // Not a refusal — the host stopped answering mid-chain. Leave
            // everything from here on exactly as it is and try again next
            // reconnect; nothing has been decided.
            SatLog.err('settlement drain', e, st);
            interrupted = true;
            break;
          }
        }
        final left = [
          for (final e in await eventsFor(visitId))
            if (!e.isParked) e,
        ];
        if (refused != null) {
          await _park(visitId, code!);
        }
        chains.add(
          ChainOutcome(
            visitId: visitId,
            delivered: delivered,
            refused: refused,
            code: code,
            parked: refused == null ? const [] : left,
            strandedAmount: refused == null ? 0 : _moneyIn(left),
          ),
        );
        if (interrupted) break;
      }
    } finally {
      state = state.copyWith(draining: false);
      await _refreshState();
    }
    return SettlementReport(chains: chains, interrupted: interrupted);
  }

  /// Mark a visit's whole remaining chain parked, carrying the host's code on
  /// the event that was actually refused (the first one left).
  Future<void> _park(String visitId, String code) async {
    await (db.update(db.settlementEvents)..where(
          (e) => e.visitId.equals(visitId) & e.status.equals('pending'),
        ))
        .write(const SettlementEventsCompanion(status: Value('parked')));
    final first =
        await (db.select(db.settlementEvents)
              ..where((e) => e.visitId.equals(visitId))
              ..orderBy([(e) => OrderingTerm.asc(e.seq)])
              ..limit(1))
            .getSingleOrNull();
    if (first != null) {
      await (db.update(db.settlementEvents)..where(
            (e) => e.id.equals(first.id),
          ))
          .write(SettlementEventsCompanion(failCode: Value(code)));
    }
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
