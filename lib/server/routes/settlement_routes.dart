import 'dart:convert';
import 'package:satset/server/visit_expenses.dart';
import 'package:satset/data/models/visit_expense_dto.dart';
import 'package:satset/domain/models/visit_expense.dart' as expense;
import 'package:satset/core/time/business_day.dart';
import 'package:satset/core/time/sat_clock.dart';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/printing/bill_struk_builder.dart';
import 'package:satset/core/printing/bill_struk_renderer.dart';
import 'package:satset/core/printing/struk_socket.dart';
import 'package:satset/data/models/bill_dto.dart'
    show historyPageCeiling, historyPageSize;
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/server/audit_log.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/domain/use_cases/bill_recompute.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/debts.dart';
import 'package:satset/server/members.dart';
import 'package:satset/server/routes/tables_routes.dart'
    show snapshotVisitAndDelete, tableJson, syncVisitMoney;
import 'package:satset/server/ws_hub.dart';
import 'package:satset/server/visit_tax_config.dart';

const _uuid = Uuid();

/// `piutang` is a payment method because it *discharges the receipt's claim*,
/// not because money arrived (ADR-0098). It is the one method that carries no
/// tendered/change and no proof photo — there is no slip for a promise — and it
/// is refused at the refund route below, where the shared set would otherwise
/// legalise "refund by piutang".
const _methods = {'tunai', 'kartu', 'qris', 'transfer', 'lainnya', 'piutang'};

/// Two-phase settlement + split bills, keyed off the [[Visit]] (not the table)
/// so a detached unpaid bill survives the table being freed. See
/// docs/adr/0023-two-phase-settlement-and-split-bills.md, ADR-0024, and
/// CONTEXT.md (Bill / Settlement / Bill close / Split bill / Payment).
Router settlementRoutes(AppDatabase db, WsHub hub, ServerAuth auth) {
  final r = Router();

  Future<User?> resolve(Request req) async {
    final token = req.headers['authorization']?.replaceFirst(
      RegExp(r'^[Bb]earer\s+'),
      '',
    );
    return auth.resolveBearer(token);
  }

  Future<List<String>> capsOf(Request req) async {
    final user = await resolve(req);
    if (user == null) return const [];
    final role = await (db.select(
      db.roles,
    )..where((x) => x.id.equals(user.roleId))).getSingleOrNull();
    final live = role == null
        ? const <String>[]
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
    final captured = await auth.capturedCapabilities(
      req.headers['authorization']?.replaceFirst(RegExp(r'^[Bb]earer\s+'), ''),
      req.headers['x-capture-grant'],
      req.headers['x-idempotency-key'],
    );
    return {...live, ...captured}.toList();
  }

  Future<Response?> requireCap(Request req, Capability needed) async {
    final user = await resolve(req);
    if (user == null) return Response(401);
    if (!(await capsOf(req)).contains(needed.name)) {
      return _err(403, 'forbidden', 'missing capability ${needed.name}');
    }
    return null;
  }

  Future<bool> signedCapture(
    Request req,
    Map<String, dynamic> body,
    Capability needed,
  ) async {
    if (_capturedAt(body) == null) return false;
    final token = req.headers['authorization']?.replaceFirst(
      RegExp(r'^[Bb]earer\s+'),
      '',
    );
    return (await auth.capturedCapabilities(
      token,
      req.headers['x-capture-grant'],
      req.headers['x-idempotency-key'],
    )).contains(needed.name);
  }

  Future<Response?> requireBillRead(Request req) async {
    if (await resolve(req) == null) return Response(401);
    final caps = await capsOf(req);
    if (caps.contains(Capability.settleBill.name) ||
        caps.contains(Capability.takeOrder.name)) {
      return null;
    }
    return _err(403, 'forbidden', 'missing bill read capability');
  }

  Future<void> broadcastBill(String visitId) async {
    final bill = await _buildBill(db, visitId);
    if (bill != null) hub.broadcast(WsEventTypes.billUpdated, bill);
    // Keep the floor money badge (outstanding / Sebagian / Lunas) in sync.
    await syncVisitMoney(db, hub, visitId);
  }

  /// The money-side close: stamp the visit, audit it, then either snapshot
  /// (the table is already freed, so this completes ADR-0024's pair) or mirror
  /// a Lunas pill onto the still-occupied table and let the snapshot defer.
  ///
  /// Shared by the confirmed Lunas close and the manual tak-tertagih
  /// write-off, because they differ only in `loss` and the audit line.
  Future<bool> performBillClose(
    Visit visit, {
    required String? actorId,
    required int loss,
    String? reason,

    /// When the close actually happened, if it was captured on a terputus till
    /// and replayed later (ADR-0123). Null for every online close.
    DateTime? at,
  }) async {
    final visitId = visit.id;
    final now = at ?? SatClock.now().toUtc();
    // A close is one act: the stamp, its audit row, the points it pays out and
    // the snapshot that files it (ADR-0100). Half of it is a bill marked
    // closed that never earned, or an archived visit with no audit line.
    final snapshotted = await db.transaction(() async {
      await (db.update(db.visits)..where((v) => v.id.equals(visitId))).write(
        VisitsCompanion(
          billClosedAt: Value(now),
          billClosedBy: Value(actorId),
          lossAmount: Value(loss),
        ),
      );
      await _audit(
        db,
        AuditType.billClosed,
        loss > 0 ? AuditKind.billWrittenOff : AuditKind.billClosed,
        params: {
          'table': visit.tableLabel ?? '',
          if (loss > 0) 'amount': auditRupiah(loss),
        },
        tableId: visit.tableId,
        actor: actorId,
        reason: reason,
        // Only a write-off moves money; a normal close is bookkeeping, so it
        // carries no amount rather than a zero the venue log would tally.
        amountCents: loss > 0 ? loss : null,
        at: at,
      );
      // [[Poin]] earn at bill close, once per visit (ADR-0095). A write-off pays
      // out nothing — the guest did not pay, so there is no spend to reward — and
      // the base is the bill net of discount, before service and tax, so the
      // points agree with the figure the guest was actually charged for food.
      if (loss <= 0) {
        final bill = await _buildBill(db, visitId);
        if (bill != null) {
          final billBase =
              (bill['total'] as int) -
              (bill['serviceAmount'] as int) -
              (bill['taxAmount'] as int);
          // Under `memberSplit` each [[Pemilik struk]] earns on their own
          // share and the [[Pemilik tagihan]] takes the rest (ADR-0118). The
          // receipts are only read when the mode is on; without it the map
          // collapses to the single owner entry this used to write.
          final cfg = await memberConfig(db);
          final recs = cfg.splitEnabled
              ? await (db.select(
                  db.receipts,
                )..where((x) => x.visitId.equals(visitId))).get()
              : const <Receipt>[];
          final Map<String, int> bases;
          if (cfg.splitEnabled && visit.memberAttributionVersion == 2) {
            final tickets =
                await (db.select(db.tickets)..where(
                      (t) =>
                          t.visitId.equals(visitId) &
                          t.status.equals('voided').not(),
                    ))
                    .get();
            final gross = <String?, int>{};
            for (final ticket in tickets) {
              gross[ticket.memberId] =
                  (gross[ticket.memberId] ?? 0) + ticket.price * ticket.qty;
            }
            final entries = gross.entries.toList();
            final shares = distributeFixed([
              for (final entry in entries) entry.value,
            ], billBase);
            bases = {
              for (var i = 0; i < entries.length; i++)
                if (entries[i].key != null && shares[i] > 0)
                  entries[i].key!: shares[i],
            };
          } else {
            bases = pointsBaseByMember(
              billBase: billBase,
              ownerId: visit.memberId,
              splitEnabled: cfg.splitEnabled,
              receipts: [
                for (final r in recs)
                  (
                    memberId: r.memberId,
                    base: r.total - r.serviceAmount - r.taxAmount,
                  ),
              ],
            );
          }
          // One row per member, never one per receipt: a guest holding two
          // slips ate one meal, and `earnPointsForVisit` is idempotent per
          // (visit, member) besides.
          for (final entry in bases.entries) {
            await earnPointsForVisit(
              db,
              memberId: entry.key,
              visitId: visitId,
              base: entry.value,
              actorUserId: actorId,
              hub: hub,
              // Earned when the bill closed, not when it drained — the close
              // itself already backdates, and a points row filed a day later
              // than the bill that earned it makes the member report disagree
              // with the sales report about the same meal.
              at: now,
            );
          }
        }
      }
      // Every mirror of this bill's members now holds a stale visit count and
      // a stale `lastVisitAt`, whether or not anybody earned a point (ADR-0129).
      await touchVisitMembers(db, visitId, ownerId: visit.memberId, at: now);
      final fresh = await _visit(db, visitId);
      final didSnapshot = fresh != null && fresh.tableFreedAt != null;
      if (didSnapshot) {
        await snapshotVisitAndDelete(
          db,
          hub,
          fresh,
          billClosedBy: actorId,
          lossAmount: loss,
          // The snapshot files the bill under the moment it closed, which for
          // a replayed settlement is when the till took the money, not when
          // the socket came back (ADR-0123). Without this the payment row is
          // backdated correctly and the session it lives in is not, so a bill
          // collected at 23:50 and drained at 00:10 is reported on the wrong
          // day by everything that buckets on `TableSession.closedAt`.
          closedAt: now,
        );
      } else {
        final tbl = await (db.select(
          db.venueTables,
        )..where((t) => t.currentVisitId.equals(visitId))).getSingleOrNull();
        if (tbl != null) {
          await (db.update(db.venueTables)..where((t) => t.id.equals(tbl.id)))
              .write(VenueTablesCompanion(billClosedAt: Value(now)));
          final fresh2 = await (db.select(
            db.venueTables,
          )..where((t) => t.id.equals(tbl.id))).getSingleOrNull();
          if (fresh2 != null) {
            hub.broadcast(WsEventTypes.tableUpdated, tableJson(fresh2));
          }
        }
        hub.broadcast(WsEventTypes.billUpdated, {
          'visitId': visitId,
          'billClosed': true,
        });
      }
      return didSnapshot;
    });
    return snapshotted;
  }

  /// Reject mutations on a bill the cashier already locked (bill-closed but the
  /// table not yet freed — the "lingering" state). Reopen first to correct.
  Future<Response?> lockGuard(String visitId) async {
    final v = await _visit(db, visitId);
    if (v != null && v.billClosedAt != null) {
      return _err(
        409,
        'bill_locked',
        'tagihan sudah ditutup — buka ulang dulu',
      );
    }
    return null;
  }

  /// The mode, the module and the owner's own switch, asked once
  /// (`MemberConfig.splitEnabled`). A venue without it must not be able to
  /// write a `receipts.member_id` by calling a route directly.
  ///
  /// Up here rather than beside the [[Pemilik struk]] routes below because the
  /// mint route needs it too: a struk is born named (ADR-0120 §3), so the gate
  /// has to be reachable from the top of the file.
  Future<(MemberConfig, Response?)> requireSplit(
    Request req,
    Map<String, dynamic> body,
  ) async {
    final cfg = await memberConfig(db);
    final captured = await signedCapture(req, body, Capability.settleBill);
    if (!cfg.enabled && !captured) {
      return (cfg, _err(409, 'members_disabled', 'keanggotaan tidak aktif'));
    }
    if (!cfg.splitEnabled && !captured) {
      return (cfg, _err(409, 'split_disabled', 'pemilik struk tidak aktif'));
    }
    if (captured) {
      final discount = body['memberDiscount'];
      if ((body['memberPresetId'] is String && discount == null) ||
          (discount != null &&
              (discount is! Map ||
                  discount['name'] is! String ||
                  discount['kind'] is! String ||
                  discount['value'] is! int ||
                  (discount['value'] as int) < 0))) {
        return (
          cfg,
          _err(
            409,
            'member_discount_needs_repair',
            'captured member discount needs repair',
          ),
        );
      }
    }
    return (cfg, null);
  }

  /// Write the [[Pemilik struk]] onto a receipt and land their standing
  /// discount on it. Shared by the mint route and the attach route so a struk
  /// born named and a struk named afterwards cannot end up with different
  /// give-backs. Caller supplies the transaction; caller has already resolved
  /// the member and passed [requireSplit].
  Future<void> writeReceiptMember(
    String receiptId,
    String memberId,
    MemberConfig cfg,
    String? actorId, {
    bool captured = false,
    Map? capturedDiscount,
  }) async {
    await (db.update(db.receipts)..where((x) => x.id.equals(receiptId))).write(
      ReceiptsCompanion(memberId: Value(memberId)),
    );
    if (await _receiptDiscountOf(db, receiptId, 'member') != null) return;
    if (captured) {
      if (capturedDiscount == null) return;
      await db
          .into(db.discounts)
          .insert(
            DiscountsCompanion.insert(
              id: _uuid.v4(),
              receiptId: Value(receiptId),
              presetId: Value(capturedDiscount['presetId'] as String?),
              name: capturedDiscount['name'] as String,
              kind: capturedDiscount['kind'] as String,
              value: Value(capturedDiscount['value'] as int),
              source: const Value('member'),
              byUserId: Value(actorId),
              at: SatClock.now().toUtc(),
            ),
          );
      return;
    }
    if (cfg.presetId == null) return;
    final preset = await (db.select(
      db.discountPresets,
    )..where((x) => x.id.equals(cfg.presetId!))).getSingleOrNull();
    // The owner nominates one preset as "the member discount" and its stored
    // scope says where a *cashier* may reach for it. Applied here it always
    // lands at order scope, so a `bill` or `order` preset both work; a `line`
    // one does not, because a tier discount is not a price change on one dish.
    if (preset == null || !preset.active) return;
    if (preset.scope != 'bill' && preset.scope != 'order') return;
    await db
        .into(db.discounts)
        .insert(
          DiscountsCompanion.insert(
            id: _uuid.v4(),
            receiptId: Value(receiptId),
            presetId: Value(preset.id),
            name: preset.name,
            kind: preset.kind,
            value: Value(preset.value),
            source: const Value('member'),
            byUserId: Value(actorId),
            at: SatClock.now().toUtc(),
          ),
        );
  }

  Future<void> syncTicketMemberDiscounts(
    String receiptId,
    MemberConfig cfg,
    String? actorId, {
    bool captured = false,
    Map? capturedDiscount,
  }) async {
    await (db.delete(db.discounts)..where(
          (x) =>
              x.receiptId.equals(receiptId) &
              x.ticketId.isNotNull() &
              x.source.equals('member'),
        ))
        .go();
    String? presetId;
    String name;
    int value;
    if (captured) {
      if (capturedDiscount == null) return;
      presetId = capturedDiscount['presetId'] as String?;
      name = capturedDiscount['name'] as String;
      value = capturedDiscount['value'] as int;
    } else {
      if (cfg.presetId == null) return;
      final preset = await (db.select(
        db.discountPresets,
      )..where((x) => x.id.equals(cfg.presetId!))).getSingleOrNull();
      if (preset == null || !preset.active || preset.kind != 'percent') return;
      presetId = preset.id;
      name = preset.name;
      value = preset.value;
    }
    final lines = await (db.select(
      db.receiptLines,
    )..where((x) => x.receiptId.equals(receiptId))).get();
    final units = <String, int>{};
    for (final line in lines) {
      units[line.ticketId] = (units[line.ticketId] ?? 0) + line.qtyUnits;
    }
    for (final entry in units.entries) {
      final ticket = await (db.select(
        db.tickets,
      )..where((x) => x.id.equals(entry.key))).getSingleOrNull();
      if (ticket?.memberId == null) continue;
      final base = ticket!.price * entry.value;
      await db
          .into(db.discounts)
          .insert(
            DiscountsCompanion.insert(
              id: _uuid.v4(),
              receiptId: Value(receiptId),
              ticketId: Value(ticket.id),
              presetId: Value(presetId),
              name: name,
              kind: 'percent',
              value: Value(value),
              amount: Value(
                resolveDiscountAmount(
                  kind: 'percent',
                  value: value,
                  base: base,
                ),
              ),
              source: const Value('member'),
              byUserId: Value(actorId),
              at: SatClock.now().toUtc(),
            ),
          );
    }
  }

  // List every open, payable visit (≥1 sent line, bill not yet closed). Spans
  // attached (table occupied) AND detached (table freed, bill still open)
  // visits — the detached ones carry `tableFreedAt`/`detached` for the flag.
  r.get('/settlement/payable', (Request req) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final visits = await db.select(db.visits).get();
    final out = <Map<String, dynamic>>[];
    for (final v in visits) {
      if (v.billClosedAt != null) continue; // locked → off the active list
      final bill = await _buildBill(db, v.id);
      if (bill == null) continue; // no sent lines
      out.add(_summarize(bill));
    }
    final liveIds = visits.map((v) => v.id).toSet();
    final archivedDue = await db.customSelect('''
      SELECT s.id FROM table_sessions s
      LEFT JOIN (
        SELECT session_id, SUM(amount) AS paid_net
        FROM table_session_payments GROUP BY session_id
      ) p ON p.session_id = s.id
      WHERE s.settled_total > COALESCE(p.paid_net, 0)
    ''').get();
    for (final row in archivedDue) {
      final sessionId = row.read<String>('id');
      if (liveIds.contains(sessionId)) continue;
      final bill = await _buildSessionBill(db, sessionId);
      if (bill == null) continue;
      out.add(_summarize(bill));
    }
    // Detached-unpaid first (need attention), then by outstanding desc.
    out.sort((a, b) {
      final da = (a['detached'] == true) ? 1 : 0;
      final dbb = (b['detached'] == true) ? 1 : 0;
      if (da != dbb) return dbb.compareTo(da);
      return (b['outstanding'] as int).compareTo(a['outstanding'] as int);
    });
    return _ok(out);
  });

  // Full bill detail for one visit.
  // Snapshot discovery includes empty visits; payable membership does not.
  r.get('/settlement/active-visits', (Request req) async {
    final denied = await requireBillRead(req);
    if (denied != null) return denied;
    final visits = await (db.select(
      db.visits,
    )..where((v) => v.billClosedAt.isNull())).get();
    return _ok([
      for (final v in visits) {'visitId': v.id},
    ]);
  });

  r.get('/settlement/visits/<visitId>/bill', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireBillRead(req);
    if (denied != null) return denied;
    final bill =
        await _buildBill(db, visitId, allowEmpty: true) ??
        await _buildSessionBill(db, visitId);
    if (bill == null) return _err(404, 'no_visit', 'visit not found');
    return _ok(bill);
  });

  // Old parked captures never replay. Report only their money metadata so the
  // host can warn its cashier before anyone collects the same bill again.
  r.post('/settlement/legacy-parked-payments', (Request req) async {
    if (await resolve(req) == null) return Response(401);
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final events = body['events'];
    if (events is! List || events.length > 100) {
      return _err(400, 'bad_events', 'invalid parked payment list');
    }
    final parsed = <LegacyParkedPaymentsCompanion>[];
    for (final item in events) {
      if (item is! Map<String, dynamic>) {
        return _err(400, 'bad_event', 'invalid parked payment');
      }
      final id = item['id'];
      final visitId = item['visitId'];
      final kind = item['kind'];
      final amount = item['amount'];
      final capturedAt = DateTime.tryParse(item['capturedAt'] as String? ?? '');
      if (id is! String ||
          id.isEmpty ||
          visitId is! String ||
          visitId.isEmpty ||
          (kind != 'recordPayment' && kind != 'refund') ||
          amount is! int ||
          amount < 0 ||
          (item['tableId'] != null && item['tableId'] is! String) ||
          capturedAt == null) {
        return _err(400, 'bad_event', 'invalid parked payment');
      }
      parsed.add(
        LegacyParkedPaymentsCompanion.insert(
          eventId: id,
          visitId: visitId,
          tableId: Value(item['tableId'] as String?),
          kind: kind as String,
          amount: amount,
          capturedAt: capturedAt.toUtc(),
        ),
      );
    }
    await db.transaction(() async {
      for (final row in parsed) {
        await db
            .into(db.legacyParkedPayments)
            .insert(row, mode: InsertMode.insertOrIgnore);
      }
    });
    for (final visitId
        in events.map((e) => (e as Map)['visitId'] as String).toSet()) {
      await broadcastBill(visitId);
    }
    return _ok({'reported': events.length});
  });

  // Create a receipt.
  // {mode: itemized|even, label?, assignAll?: bool, lines?: [{ticketId,
  // qtyUnits}]}.
  //
  // `lines` mints and assigns in one transaction — the tap-to-select-and-pay
  // fast path (ADR-0067) selects lines and confirms in a single gesture, and
  // splitting that into create + N assigns would leave a half-built receipt
  // behind on any failure. On the money path that is not a trade worth making.
  r.post('/settlement/visits/<visitId>/receipts', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final captured = await signedCapture(req, body, Capability.settleBill);
    final locked = captured ? null : await lockGuard(visitId);
    if (locked != null) return locked;
    final visit = await _visit(db, visitId);
    if (visit == null && captured) {
      final session = await (db.select(
        db.tableSessions,
      )..where((s) => s.id.equals(visitId))).getSingleOrNull();
      if (session == null) return _err(404, 'no_visit', 'visit not found');
      final id = _mintId(body);
      final prior = await (db.select(
        db.tableSessionReceipts,
      )..where((r) => r.receiptId.equals(id))).getSingleOrNull();
      if (prior != null) {
        if (prior.sessionId != visitId) {
          return _err(409, 'wrong_visit', 'receipt belongs another visit');
        }
        return _ok({
          'receiptId': id,
          'bill': await _buildSessionBill(db, visitId),
        });
      }
      final snapshot = body['receiptSnapshot'];
      if (snapshot is! Map<String, dynamic>) {
        return _err(
          409,
          'receipt_snapshot_missing',
          'captured receipt needs repair',
        );
      }
      final fields = [
        'subtotal',
        'discountAmount',
        'serviceAmount',
        'taxAmount',
        'total',
      ];
      if (fields.any(
            (key) => snapshot[key] is! int || (snapshot[key] as int) < 0,
          ) ||
          snapshot['lines'] is! List) {
        return _err(400, 'bad_receipt_snapshot', 'invalid captured receipt');
      }
      final lines = <({String ticketId, int qty})>[];
      for (final raw in snapshot['lines'] as List) {
        if (raw is! Map ||
            raw['ticketId'] is! String ||
            raw['qtyUnits'] is! int ||
            (raw['qtyUnits'] as int) <= 0) {
          return _err(400, 'bad_receipt_snapshot', 'invalid captured lines');
        }
        lines.add((
          ticketId: raw['ticketId'] as String,
          qty: raw['qtyUnits'] as int,
        ));
      }
      await db.transaction(() async {
        await db
            .into(db.tableSessionReceipts)
            .insert(
              TableSessionReceiptsCompanion.insert(
                id: _uuid.v4(),
                sessionId: visitId,
                receiptId: id,
                mode: Value(
                  (body['mode'] as String?) == 'even' ? 'even' : 'itemized',
                ),
                label: Value((body['label'] as String?)?.trim() ?? ''),
                subtotal: Value(snapshot['subtotal'] as int),
                discountAmount: Value(snapshot['discountAmount'] as int),
                serviceAmount: Value(snapshot['serviceAmount'] as int),
                taxAmount: Value(snapshot['taxAmount'] as int),
                total: Value(snapshot['total'] as int),
                memberId: Value(snapshot['memberId'] as String?),
              ),
            );
        for (final line in lines) {
          await db
              .into(db.tableSessionReceiptLines)
              .insert(
                TableSessionReceiptLinesCompanion.insert(
                  id: _uuid.v4(),
                  sessionId: visitId,
                  receiptId: id,
                  ticketId: line.ticketId,
                  qtyUnits: Value(line.qty),
                ),
              );
        }
      });
      hub.broadcast(WsEventTypes.tableSessionClosed, {
        'tableId': session.tableId,
        'visitId': visitId,
      });
      return _ok({
        'receiptId': id,
        'bill': await _buildSessionBill(db, visitId),
      });
    }
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final mode = (body['mode'] as String?) == 'even' ? 'even' : 'itemized';
    final id = _mintId(body);
    // A struk may be born named (ADR-0120 §3). The settle pane mints at confirm
    // so an abandoned mode leaves nothing behind, which means there is no
    // receipt to attach a member to at the moment the cashier picks one — the
    // member has to ride in with the lines. Resolved before the transaction so
    // a refusal never leaves a half-made receipt standing.
    final wantMember = (body['memberId'] as String?)?.trim();
    MemberConfig? splitCfg;
    String? bornForId;
    if (wantMember != null && wantMember.isNotEmpty) {
      final (cfg, blocked) = await requireSplit(req, body);
      if (blocked != null) return blocked;
      final m = await getMember(db, wantMember);
      if (m == null) return _err(404, 'no_member', 'pelanggan tidak ada');
      bornForId = m.id;
      splitCfg = cfg;
    }
    await db.transaction(() async {
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              id: id,
              tableId: visit.tableId,
              visitId: Value(visitId),
              mode: Value(mode),
              label: Value((body['label'] as String?)?.trim() ?? ''),
              createdAt: SatClock.now().toUtc(),
            ),
          );
      if (body['assignAll'] == true) {
        await _assignAllUnassigned(db, visitId, id);
      }
      for (final l in (body['lines'] as List? ?? const [])) {
        final m = (l as Map).cast<String, dynamic>();
        final ticketId = m['ticketId'] as String?;
        if (ticketId == null || ticketId.isEmpty) continue;
        final want = (m['qtyUnits'] as num?)?.toInt() ?? 0;
        if (want <= 0) continue;
        // Clamp to what is actually free, so two cashiers racing the same line
        // cannot assign it twice.
        final free = await _freeUnits(db, ticketId);
        if (free <= 0) continue;
        await db
            .into(db.receiptLines)
            .insert(
              ReceiptLinesCompanion.insert(
                id: _uuid.v4(),
                receiptId: id,
                ticketId: ticketId,
                qtyUnits: Value(want < free ? want : free),
              ),
            );
      }
      if (bornForId != null) {
        if (visit.memberAttributionVersion == 2) {
          await (db.update(db.receipts)..where((x) => x.id.equals(id))).write(
            ReceiptsCompanion(memberId: Value(bornForId)),
          );
        } else {
          await writeReceiptMember(
            id,
            bornForId,
            splitCfg!,
            (await resolve(req))?.id,
            captured: await signedCapture(req, body, Capability.settleBill),
            capturedDiscount: body['memberDiscount'] as Map?,
          );
        }
      }
      if (visit.memberAttributionVersion == 2) {
        await syncTicketMemberDiscounts(
          id,
          splitCfg ?? await memberConfig(db),
          (await resolve(req))?.id,
        );
      }
      await _recompute(db, visitId);
    });
    await broadcastBill(visitId);
    return _ok({'receiptId': id, 'bill': await _buildBill(db, visitId)});
  });

  // Delete an unpaid receipt; its line assignments are released.
  r.delete('/settlement/receipts/<receiptId>', (
    Request req,
    String receiptId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final rec = await _receipt(db, receiptId);
    if (rec == null) {
      final raw = await req.readAsString();
      final body = raw.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      final captured = await signedCapture(req, body, Capability.settleBill)
          ? _capturedAt(body)
          : null;
      final visitId = body['visitId'] as String? ?? '';
      if (captured == null || visitId.isEmpty) {
        return _err(404, 'no_receipt', 'receipt not found');
      }
      final archived =
          await (db.select(db.tableSessionReceipts)..where(
                (r) =>
                    r.receiptId.equals(receiptId) & r.sessionId.equals(visitId),
              ))
              .getSingleOrNull();
      final session = await (db.select(
        db.tableSessions,
      )..where((s) => s.id.equals(visitId))).getSingleOrNull();
      if (archived == null || session == null) {
        return _err(404, 'no_receipt', 'receipt not found');
      }
      // Keep the printed snapshot. A captured deletion cancels its allocation;
      // any money another cashier took remains credited to the visit.
      await db.transaction(() async {
        final current = await (db.select(
          db.tableSessionReceipts,
        )..where((r) => r.id.equals(archived.id))).getSingle();
        final original = await _originalSessionReceiptJson(db, current);
        await (db.update(
          db.tableSessionReceipts,
        )..where((r) => r.id.equals(archived.id))).write(
          TableSessionReceiptsCompanion(
            status: const Value('cancelled'),
            originalSnapshotJson: Value(original),
          ),
        );
      });
      hub.broadcast(WsEventTypes.tableSessionClosed, {
        'tableId': session.tableId,
        'visitId': visitId,
      });
      return _ok({'bill': await _buildSessionBill(db, visitId)});
    }
    final visitId = rec.visitId ?? rec.tableId;
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    if (rec.status == 'paid') {
      return _err(409, 'receipt_paid', 'reopen before deleting a paid receipt');
    }
    await db.transaction(() async {
      await (db.delete(
        db.receiptLines,
      )..where((x) => x.receiptId.equals(receiptId))).go();
      await (db.delete(
        db.payments,
      )..where((x) => x.receiptId.equals(receiptId))).go();
      await (db.delete(
        db.discounts,
      )..where((x) => x.receiptId.equals(receiptId))).go();
      await (db.delete(db.receipts)..where((x) => x.id.equals(receiptId))).go();
      await _recompute(db, visitId);
    });
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Assign qty units of a sent ticket to a receipt (qty-level). {ticketId, qtyUnits}.
  r.post('/settlement/receipts/<receiptId>/lines', (
    Request req,
    String receiptId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final captured = await signedCapture(req, body, Capability.settleBill);
    final rec = await _receipt(db, receiptId);
    if (rec == null && captured) {
      final visitId = body['visitId'] as String? ?? '';
      final archived =
          await (db.select(db.tableSessionReceipts)..where(
                (r) =>
                    r.receiptId.equals(receiptId) & r.sessionId.equals(visitId),
              ))
              .getSingleOrNull();
      if (archived == null) return _err(404, 'no_receipt', 'receipt not found');
      final snapshot = body['receiptSnapshot'];
      if (snapshot is! Map<String, dynamic> ||
          snapshot['lines'] is! List ||
          [
            'subtotal',
            'discountAmount',
            'serviceAmount',
            'taxAmount',
            'total',
          ].any((key) => snapshot[key] is! int || (snapshot[key] as int) < 0)) {
        return _err(
          409,
          'receipt_snapshot_missing',
          'captured receipt needs repair',
        );
      }
      final ticketId = body['ticketId'] as String? ?? '';
      final qty = body['qtyUnits'] as int? ?? -1;
      final ticket =
          await (db.select(db.tableSessionTickets)..where(
                (t) =>
                    t.ticketId.equals(ticketId) & t.sessionId.equals(visitId),
              ))
              .getSingleOrNull();
      if (ticket == null || qty < 0 || qty > ticket.qty) {
        return _err(409, 'bad_assignment', 'captured line needs repair');
      }
      await db.transaction(() async {
        final current = await (db.select(
          db.tableSessionReceipts,
        )..where((r) => r.id.equals(archived.id))).getSingle();
        final original = await _originalSessionReceiptJson(db, current);
        await (db.delete(db.tableSessionReceiptLines)..where(
              (l) =>
                  l.receiptId.equals(receiptId) & l.ticketId.equals(ticketId),
            ))
            .go();
        if (qty > 0) {
          await db
              .into(db.tableSessionReceiptLines)
              .insert(
                TableSessionReceiptLinesCompanion.insert(
                  id: _uuid.v4(),
                  sessionId: visitId,
                  receiptId: receiptId,
                  ticketId: ticketId,
                  qtyUnits: Value(qty),
                ),
              );
        }
        await (db.update(
          db.tableSessionReceipts,
        )..where((r) => r.id.equals(archived.id))).write(
          TableSessionReceiptsCompanion(
            subtotal: Value(snapshot['subtotal'] as int),
            discountAmount: Value(snapshot['discountAmount'] as int),
            serviceAmount: Value(snapshot['serviceAmount'] as int),
            taxAmount: Value(snapshot['taxAmount'] as int),
            total: Value(snapshot['total'] as int),
            originalSnapshotJson: Value(original),
          ),
        );
      });
      final bill = await _buildSessionBill(db, visitId);
      hub.broadcast(WsEventTypes.tableSessionClosed, {
        'tableId': bill?['tableId'],
        'visitId': visitId,
      });
      return _ok({'bill': bill});
    }
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final visitId = rec.visitId ?? rec.tableId;
    final locked = captured ? null : await lockGuard(visitId);
    if (locked != null) return locked;
    if (rec.status == 'paid' && !captured) {
      return _err(
        409,
        'receipt_paid',
        'reopen the receipt before editing lines',
      );
    }
    final ticketId = body['ticketId'] as String;
    final want = ((body['qtyUnits'] as num?)?.toInt() ?? 1).clamp(0, 1 << 30);
    final ticket = await (db.select(
      db.tickets,
    )..where((x) => x.id.equals(ticketId))).getSingleOrNull();
    if (ticket == null || (ticket.visitId ?? ticket.tableId) != visitId) {
      return _err(404, 'no_ticket', 'ticket not on this bill');
    }
    final assignedElsewhere = await _assignedUnits(
      db,
      ticketId,
      exclude: receiptId,
    );
    final available = ticket.qty - assignedElsewhere;
    if (want > (captured ? ticket.qty : available)) {
      return _err(
        409,
        'over_assign',
        'only $available unit(s) of this line are unassigned',
      );
    }
    await db.transaction(() async {
      await (db.delete(db.receiptLines)..where(
            (x) => x.receiptId.equals(receiptId) & x.ticketId.equals(ticketId),
          ))
          .go();
      if (want > 0) {
        await db
            .into(db.receiptLines)
            .insert(
              ReceiptLinesCompanion.insert(
                id: _uuid.v4(),
                receiptId: receiptId,
                ticketId: ticketId,
                qtyUnits: Value(want),
              ),
            );
      }
      await _recompute(db, visitId);
    });
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Replace all receipts with an even N-way split of the bill total.
  r.post('/settlement/visits/<visitId>/split-even', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final captured = await signedCapture(req, body, Capability.settleBill);
    final locked = captured ? null : await lockGuard(visitId);
    if (locked != null) return locked;
    final visit = await _visit(db, visitId);
    final n = ((body['n'] as num?)?.toInt() ?? 2).clamp(1, 50);
    if (visit == null && captured) {
      final session = await (db.select(
        db.tableSessions,
      )..where((s) => s.id.equals(visitId))).getSingleOrNull();
      if (session == null) return _err(404, 'no_visit', 'visit not found');
      final ids = body['ids'];
      final snapshot = body['receiptSnapshot'];
      final shares = snapshot is Map<String, dynamic>
          ? snapshot['shares']
          : null;
      if (ids is! List ||
          shares is! List ||
          ids.length != n ||
          shares.length != n ||
          ids.toSet().length != n ||
          ids.any((id) => id is! String || id.isEmpty) ||
          shares.any((share) => share is! int || share <= 0)) {
        return _err(
          409,
          'split_snapshot_missing',
          'captured split needs repair',
        );
      }
      final existing = await (db.select(
        db.tableSessionReceipts,
      )..where((r) => r.sessionId.equals(visitId))).get();
      final from = existing.where((r) => r.mode == 'even').length;
      await db.transaction(() async {
        for (var i = 0; i < n; i++) {
          await db
              .into(db.tableSessionReceipts)
              .insert(
                TableSessionReceiptsCompanion.insert(
                  id: _uuid.v4(),
                  sessionId: visitId,
                  receiptId: ids[i] as String,
                  mode: const Value('even'),
                  label: Value('${from + i + 1}/${from + n}'),
                  total: Value(shares[i] as int),
                ),
              );
        }
      });
      hub.broadcast(WsEventTypes.tableSessionClosed, {
        'tableId': session.tableId,
        'visitId': visitId,
      });
      return _ok({'bill': await _buildSessionBill(db, visitId)});
    }
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final bill = await _buildBill(db, visitId);
    if (bill == null) return _err(404, 'no_bill', 'visit has no sent lines');
    // ADR-0068: shares are cut from the **untracked remainder**, not from the
    // whole bill, so an even split can sit beside an itemized receipt without
    // the two claiming the same money. Nothing is wiped, which is what lets
    // the mode be chosen per payment (ADR-0067).
    final existing = await (db.select(
      db.receipts,
    )..where((x) => x.visitId.equals(visitId))).get();
    final claimed = existing.fold<int>(0, (a, r) => a + r.total);
    final remainder = (bill['total'] as int) - claimed;
    final capturedIds = body['ids'];
    final snapshot = body['receiptSnapshot'];
    final capturedShares = snapshot is Map ? snapshot['shares'] : null;
    if (captured &&
        (capturedIds is! List ||
            capturedShares is! List ||
            capturedIds.length != n ||
            capturedShares.length != n ||
            capturedIds.toSet().length != n ||
            capturedIds.any((id) => id is! String || id.isEmpty) ||
            capturedShares.any((share) => share is! int || share <= 0))) {
      return _err(409, 'split_snapshot_missing', 'captured split needs repair');
    }
    if (remainder <= 0 && !captured) {
      return _err(409, 'nothing_left', 'tidak ada sisa untuk dibagi');
    }
    final shares = captured
        ? (capturedShares as List).cast<int>()
        : distributeEvenRounded(remainder, n);
    // Number the new shares after any that already exist, so a second split
    // does not mint a second part 1. Stored as the bare spec (ADR-0085).
    final from = existing.where((r) => r.mode == 'even').length;
    // Ids may be supplied, one per share (ADR-0123): a till that cut the split
    // while terputus has already shown the guest which slip is theirs, and a
    // payment queued behind this names that slip by id.
    final ids = captured
        ? (capturedIds as List).cast<String>()
        : [for (final x in (body['ids'] as List? ?? const [])) x.toString()];
    await db.transaction(() async {
      for (var i = 0; i < n; i++) {
        await db
            .into(db.receipts)
            .insert(
              ReceiptsCompanion.insert(
                id: i < ids.length && ids[i].isNotEmpty ? ids[i] : _uuid.v4(),
                tableId: visit.tableId,
                visitId: Value(visitId),
                mode: const Value('even'),
                label: Value('${from + i + 1}/${from + n}'),
                total: Value(shares[i]),
                createdAt: SatClock.now().toUtc(),
              ),
            );
      }
    });
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  /// Resolve a manager step-up (ADR-0037). The caller lacks `applyDiscount`,
  /// so authority must come from someone who holds it. Verified **server-side**
  /// from the PIN — unlike `voidApprovedBy`, which is only an audit note on an
  /// act the caller was already entitled to perform. Accepting a client-supplied
  /// approver id here would let any cashier self-authorise. Fail-closed:
  /// returns null when the PIN is absent, wrong, or belongs to someone without
  /// the capability.
  Future<String?> resolveStepUp(String? pin) async {
    if (pin == null || pin.isEmpty) return null;
    // Salted hashes cannot be looked up by value, so this verifies rather
    // than matches (ADR-0112). `userForPin` is null on no match *and* on an
    // ambiguous one, which is the fail-closed this step-up already wanted.
    final approver = await auth.userForPin(pin);
    if (approver == null) return null;
    final role = await (db.select(
      db.roles,
    )..where((x) => x.id.equals(approver.roleId))).getSingleOrNull();
    final caps = role == null
        ? const <String>[]
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
    return caps.contains(Capability.applyDiscount.name) ? approver.id : null;
  }

  // Apply a discount to a receipt. {presetId, ticketId?, approverPin?}.
  // `ticketId` null ⇒ whole-order discount; set ⇒ line discount. The cashier
  // picks a preset — never a free-typed rate (ADR-0037).
  r.post('/settlement/receipts/<receiptId>/discounts', (
    Request req,
    String receiptId,
  ) async {
    // settleBill gates the money screen itself; applyDiscount (or a manager
    // step-up) gates this act specifically.
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;

    final capturedManual = await signedCapture(
      req,
      body,
      Capability.applyDiscount,
    );
    final rec = await (db.select(
      db.receipts,
    )..where((x) => x.id.equals(receiptId))).getSingleOrNull();
    if (rec == null) {
      if (!capturedManual) {
        return _err(404, 'no_receipt', 'receipt not found');
      }
      if (!(await capsOf(req)).contains(Capability.applyDiscount.name)) {
        return _err(403, 'approval_required', 'butuh persetujuan manajer');
      }
      final actor = await resolve(req);
      return _capturedArchivedReceiptDiscount(
        db,
        hub,
        receiptId,
        body,
        actor?.id,
        allowStack: capturedManual,
      );
    }
    final visitId = rec.visitId;
    if (visitId == null) return _err(409, 'no_visit', 'receipt has no visit');
    final capturedId = body['id'] as String?;
    if (capturedId != null) {
      final prior = await (db.select(
        db.discounts,
      )..where((d) => d.id.equals(capturedId))).getSingleOrNull();
      if (prior != null) {
        if (prior.visitId != visitId && prior.receiptId != receiptId) {
          return _err(409, 'wrong_visit', 'discount belongs another visit');
        }
        return _ok({'bill': await _buildBill(db, visitId)});
      }
    }
    final locked = capturedManual ? null : await lockGuard(visitId);
    if (locked != null) return locked;
    // Frozen at payment — reopen to correct a mistaken settlement (ADR-0037).
    if (rec.status == 'paid' && !capturedManual) {
      return _err(409, 'receipt_paid', 'buka ulang struk sebelum ubah diskon');
    }

    final actor = await resolve(req);
    String? approvedBy;
    if (!(await capsOf(req)).contains(Capability.applyDiscount.name)) {
      approvedBy = await resolveStepUp(body['approverPin'] as String?);
      if (approvedBy == null) {
        return _err(
          403,
          'approval_required',
          'butuh persetujuan manajer untuk memberi diskon',
        );
      }
    }

    final preset =
        await (db.select(db.discountPresets)
              ..where((x) => x.id.equals(body['presetId'] as String? ?? '')))
            .getSingleOrNull();
    final capturedSnapshot =
        capturedManual &&
        body['name'] is String &&
        body['kind'] is String &&
        body['value'] is num;
    if (preset == null && !capturedSnapshot) {
      return _err(404, 'no_preset', 'preset not found');
    }
    if (preset != null && !preset.active && !capturedManual) {
      return _err(409, 'preset_inactive', 'preset diskon tidak aktif');
    }

    final ticketId = body['ticketId'] as String?;
    final presetScope = preset?.scope ?? (ticketId == null ? 'order' : 'line');
    final discountName = capturedSnapshot
        ? body['name'] as String
        : preset!.name;
    final discountKind = capturedSnapshot
        ? body['kind'] as String
        : preset!.kind;
    final discountValue = capturedSnapshot
        ? (body['value'] as num).toInt()
        : preset!.value;
    final presetId = (body['presetId'] as String?) ?? preset?.id;
    // Missing marker is an older client/journal application: preserve its math.
    final perUnit = ticketId != null && body['perUnit'] == true;
    if (ticketId == null) {
      if (presetScope != 'order') {
        return _err(409, 'scope_mismatch', 'preset ini hanya untuk satu item');
      }
    } else {
      if (presetScope != 'line') {
        return _err(409, 'scope_mismatch', 'preset ini untuk seluruh pesanan');
      }
      // Even receipts own no lines, so a line discount has nothing to attach
      // to — even mode has already abandoned tracking who ordered what.
      if (rec.mode == 'even') {
        return _err(
          409,
          'even_mode',
          'diskon per item hanya untuk struk itemized',
        );
      }
      final t = await (db.select(
        db.tickets,
      )..where((x) => x.id.equals(ticketId))).getSingleOrNull();
      if (t == null) return _err(404, 'no_ticket', 'line not found');
      // A later void removes the captured discount's monetary effect, but
      // the captured action still belongs in the visit's history.
      if ((t.status == 'voided' || t.status == 'draft') &&
          !await signedCapture(req, body, Capability.applyDiscount)) {
        return _err(409, 'line_voided', 'item sudah dibatalkan');
      }
      final owns =
          await (db.select(db.receiptLines)..where(
                (x) =>
                    x.receiptId.equals(receiptId) & x.ticketId.equals(ticketId),
              ))
              .get();
      if (owns.isEmpty) {
        return _err(
          409,
          'line_not_on_receipt',
          'item ini tidak ada di struk tersebut',
        );
      }
    }

    if (perUnit && !capturedManual && await _ticketMemberLocked(db, ticketId)) {
      return _err(409, 'receipt_paid', 'buka ulang struk sebelum ubah diskon');
    }
    if (perUnit) {
      final conflicts =
          await (db.select(db.discounts)..where(
                (d) => d.ticketId.equals(ticketId) & d.source.equals('manual'),
              ))
              .get();
      if (conflicts.isNotEmpty && !capturedManual) {
        return _err(
          409,
          'discount_exists',
          'sudah ada diskon di sana — hapus dulu untuk mengganti',
        );
      }
    }
    // This route only ever writes the `manual` slot, so it may only refuse on
    // one (ADR-0126). Scoping the check to the source is what lets a
    // [[Pemilik tiket]]'s tier row and the cashier's promo share a line — and
    // it is also what stops `getSingleOrNull` throwing the moment two rows of
    // different sources sit on the same ticket, which is now the normal case.
    final existing =
        await (db.select(db.discounts)..where(
              (x) =>
                  (x.receiptId.equals(receiptId) |
                      (ticketId == null
                          ? const Constant(false)
                          : x.visitId.equals(visitId) & x.receiptId.isNull())) &
                  x.source.equals('manual') &
                  (ticketId == null
                      ? x.ticketId.isNull()
                      : x.ticketId.equals(ticketId)),
            ))
            .get();
    if (existing.isNotEmpty && !capturedManual) {
      // Live edits keep one manual row per slot. Captures retain both actions.
      return _err(
        409,
        'discount_exists',
        'sudah ada diskon di sana — hapus dulu untuk mengganti',
      );
    }

    final discountId = _mintId(body);
    await db
        .into(db.discounts)
        .insert(
          DiscountsCompanion.insert(
            // Captured rather than inlined so the audit row below can read the
            // resolved rupiah back off this discount (ADR-0072).
            id: discountId,
            // Nullable since ADR-0070 — a bill-level discount has no receipt.
            receiptId: Value(perUnit ? null : receiptId),
            visitId: Value(perUnit ? visitId : null),
            ticketId: Value(ticketId),
            presetId: Value(presetId),
            captured: Value(capturedManual),
            // Snapshot: a later preset edit or delete must not rewrite this.
            name: discountName,
            kind: discountKind,
            value: Value(discountValue),
            byUserId: Value(actor?.id),
            approvedByUserId: Value(approvedBy),
            at: SatClock.now().toUtc(),
          ),
        );
    // _recompute resolves the rupiah amount against the current base.
    await _recompute(db, visitId);
    // Audit the resolved rupiah, not the preset's rate — a "15%" row tells a
    // manager nothing about how much left the till.
    final applied = await (db.select(
      db.discounts,
    )..where((x) => x.id.equals(discountId))).getSingleOrNull();
    await _audit(
      db,
      AuditType.discountApplied,
      ticketId == null
          ? AuditKind.discountApplied
          : AuditKind.discountAppliedLine,
      params: {'name': discountName},
      tableId: rec.tableId,
      actor: actor?.id,
      amountCents: applied?.amount,
    );
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Remove a discount from a receipt. POST, not DELETE, because removal may
  // need to carry a manager step-up PIN in the body — and a PIN must never
  // ride a query string, where it would land in logs.
  Future<Response> removeDiscount(
    Request req,
    String? receiptId,
    String discountId, {
    String? ticketVisitId,
  }) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final raw = await req.readAsString();
    final body = raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final captured = await signedCapture(req, body, Capability.applyDiscount);
    final rec = receiptId == null
        ? null
        : await (db.select(
            db.receipts,
          )..where((x) => x.id.equals(receiptId))).getSingleOrNull();
    if (rec == null &&
        ticketVisitId == null &&
        (!captured || body['visitId'] is! String)) {
      return _err(404, 'no_receipt', 'receipt not found');
    }
    final visitId = rec?.visitId ?? ticketVisitId ?? body['visitId'] as String?;
    if (visitId == null) return _err(409, 'no_visit', 'receipt has no visit');
    final visit = await _visit(db, visitId);
    if (visit == null && captured) {
      if (!(await capsOf(req)).contains(Capability.applyDiscount.name) &&
          await resolveStepUp(body['approverPin'] as String?) == null) {
        return _err(403, 'approval_required', 'butuh persetujuan manajer');
      }
      final actor = await resolve(req);
      return _removeCapturedArchivedDiscount(
        db,
        hub,
        visitId,
        discountId,
        receiptId,
        body,
        actor?.id,
      );
    }
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final locked = captured ? null : await lockGuard(visitId);
    if (locked != null) return locked;
    if (rec?.status == 'paid' && !captured) {
      return _err(409, 'receipt_paid', 'buka ulang struk sebelum ubah diskon');
    }
    final actor = await resolve(req);
    if (!(await capsOf(req)).contains(Capability.applyDiscount.name)) {
      final pin = body['approverPin'] as String?;
      if (await resolveStepUp(pin) == null) {
        return _err(
          403,
          'approval_required',
          'butuh persetujuan manajer untuk mengubah diskon',
        );
      }
    }
    final row =
        await (db.select(db.discounts)..where(
              (x) =>
                  x.id.equals(discountId) &
                  ((receiptId == null
                          ? const Constant(false)
                          : x.receiptId.equals(receiptId)) |
                      (x.visitId.equals(visitId) &
                          x.ticketId.isNotNull() &
                          x.receiptId.isNull())),
            ))
            .getSingleOrNull();
    if (row == null) return _err(404, 'no_discount', 'diskon tidak ditemukan');
    if (row.receiptId == null &&
        row.ticketId != null &&
        await _ticketMemberLocked(db, row.ticketId!)) {
      return _err(409, 'receipt_paid', 'buka ulang struk sebelum ubah diskon');
    }
    await (db.delete(db.discounts)..where((x) => x.id.equals(discountId))).go();
    await _recompute(db, visitId);
    await _audit(
      db,
      AuditType.discountRemoved,
      AuditKind.discountRemoved,
      params: {'name': row.name},
      tableId: rec?.tableId ?? (await _visit(db, visitId))!.tableId,
      actor: actor?.id,
      amountCents: row.amount,
    );
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  }

  r.post(
    '/settlement/receipts/<receiptId>/discounts/<discountId>/remove',
    (Request req, String receiptId, String discountId) =>
        removeDiscount(req, receiptId, discountId),
  );
  r.post(
    '/settlement/visits/<visitId>/line-discounts/<discountId>/remove',
    (Request req, String visitId, String discountId) =>
        removeDiscount(req, null, discountId, ticketVisitId: visitId),
  );
  // BILL-SCOPE discount (ADR-0070) — a table-wide promo. Attaches to the visit
  // rather than to any receipt, which is what lets it be applied before the
  // first receipt is minted (ADR-0067). {presetId, approverPin?}.
  r.post('/settlement/visits/<visitId>/discounts', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final capturedManual = await signedCapture(
      req,
      body,
      Capability.applyDiscount,
    );
    final visit = await _visit(db, visitId);
    final archived = visit == null && capturedManual
        ? await (db.select(
            db.tableSessions,
          )..where((s) => s.id.equals(visitId))).getSingleOrNull()
        : null;
    if (visit == null && archived == null) {
      return _err(404, 'no_visit', 'visit not found');
    }
    final capturedId = body['id'] as String?;
    if (capturedId != null) {
      if (archived != null) {
        final prior = await (db.select(
          db.tableSessionDiscounts,
        )..where((d) => d.id.equals(capturedId))).getSingleOrNull();
        if (prior != null) {
          if (prior.sessionId != visitId) {
            return _err(409, 'wrong_visit', 'discount belongs another visit');
          }
          return _ok({'bill': await _buildSessionBill(db, visitId)});
        }
      } else {
        final prior = await (db.select(
          db.discounts,
        )..where((d) => d.id.equals(capturedId))).getSingleOrNull();
        if (prior != null) {
          if (prior.visitId != visitId) {
            return _err(409, 'wrong_visit', 'discount belongs another visit');
          }
          return _ok({'bill': await _buildBill(db, visitId)});
        }
      }
    }
    if (visit != null) {
      final locked = capturedManual ? null : await lockGuard(visitId);
      if (locked != null) return locked;
    }

    // A bill discount moves the bill total, and an amount receipt's claim is
    // frozen at mint time (ADR-0068) — so once any money has been taken the
    // quote a guest was given can no longer be revised silently.
    final paid = visit == null
        ? <Receipt>[]
        : await (db.select(db.receipts)..where(
                (x) => x.visitId.equals(visitId) & x.status.equals('paid'),
              ))
              .get();
    if (paid.isNotEmpty && !capturedManual) {
      return _err(
        409,
        'receipt_paid',
        'buka ulang struk yang sudah dibayar sebelum ubah diskon tagihan',
      );
    }

    final actor = await resolve(req);
    String? approvedBy;
    if (!(await capsOf(req)).contains(Capability.applyDiscount.name)) {
      approvedBy = await resolveStepUp(body['approverPin'] as String?);
      if (approvedBy == null) {
        return _err(
          403,
          'approval_required',
          'butuh persetujuan manajer untuk memberi diskon',
        );
      }
    }

    final preset =
        await (db.select(db.discountPresets)
              ..where((x) => x.id.equals(body['presetId'] as String? ?? '')))
            .getSingleOrNull();
    final capturedSnapshot =
        capturedManual &&
        body['name'] is String &&
        body['kind'] is String &&
        body['value'] is num;
    if (preset == null && !capturedSnapshot) {
      return _err(404, 'no_preset', 'preset not found');
    }
    if (preset != null && !preset.active && !capturedManual) {
      return _err(409, 'preset_inactive', 'preset diskon tidak aktif');
    }
    if (preset != null && preset.scope != 'bill') {
      return _err(409, 'scope_mismatch', 'preset ini bukan diskon tagihan');
    }
    final discountName = capturedSnapshot
        ? body['name'] as String
        : preset!.name;
    final discountKind = capturedSnapshot
        ? body['kind'] as String
        : preset!.kind;
    final discountValue = capturedSnapshot
        ? (body['value'] as num).toInt()
        : preset!.value;
    final presetId = (body['presetId'] as String?) ?? preset?.id;
    if (archived != null) {
      final discounts = await (db.select(
        db.tableSessionDiscounts,
      )..where((d) => d.sessionId.equals(visitId))).get();
      if (!capturedManual &&
          discounts.any(
            (d) =>
                d.receiptId == null &&
                d.ticketId == null &&
                d.source == 'manual',
          )) {
        return _err(409, 'discount_exists', 'sudah ada diskon tagihan');
      }
      final tickets =
          await (db.select(db.tableSessionTickets)..where(
                (t) =>
                    t.sessionId.equals(visitId) &
                    t.status.equals('voided').not(),
              ))
              .get();
      final activeIds = tickets.map((t) => t.ticketId).toSet();
      final subtotal = tickets.fold<int>(0, (sum, t) => sum + t.price * t.qty);
      final lineDiscount = discounts
          .where((d) => d.ticketId != null && activeIds.contains(d.ticketId))
          .fold<int>(0, (sum, d) => sum + d.amount);
      final base = subtotal - lineDiscount;
      final amount = resolveDiscountAmount(
        kind: discountKind,
        value: discountValue,
        base: base,
      );
      final orderDiscount = discounts
          .where((d) => d.ticketId == null)
          .fold<int>(0, (sum, d) => sum + d.amount);
      final cfg = await _config(db, visitId);
      final before = computeBreakdown(base, cfg, discount: orderDiscount);
      final after = computeBreakdown(
        base,
        cfg,
        discount: orderDiscount + amount,
      );
      await db.transaction(() async {
        await db
            .into(db.tableSessionDiscounts)
            .insert(
              TableSessionDiscountsCompanion.insert(
                id: _mintId(body),
                sessionId: visitId,
                presetId: Value(presetId),
                name: discountName,
                kind: discountKind,
                value: Value(discountValue),
                amount: Value(amount),
                byUserId: Value(actor?.id),
                approvedByUserId: Value(approvedBy),
                at: _capturedAt(body)!,
              ),
            );
        await (db.update(
          db.tableSessions,
        )..where((s) => s.id.equals(visitId))).write(
          TableSessionsCompanion(
            discountAmount: Value(archived.discountAmount + amount),
            settledTotal: Value(
              archived.settledTotal + after.total - before.total,
            ),
          ),
        );
        await _audit(
          db,
          AuditType.discountApplied,
          AuditKind.discountBillApplied,
          params: {'name': discountName},
          tableId: archived.tableId,
          actor: actor?.id,
          at: _capturedAt(body),
        );
      });
      hub.broadcast(WsEventTypes.tableSessionClosed, {
        'tableId': archived.tableId,
        'visitId': visitId,
      });
      return _ok({'bill': await _buildSessionBill(db, visitId)});
    }
    // Only the cashier's own slot is in the way — a member discount or a
    // redemption sits in a slot of its own and stacks (ADR-0094).
    if (!capturedManual &&
        await _billDiscountOf(db, visitId, 'manual') != null) {
      return _err(
        409,
        'discount_exists',
        'sudah ada diskon tagihan — hapus dulu untuk mengganti',
      );
    }

    await db
        .into(db.discounts)
        .insert(
          DiscountsCompanion.insert(
            id: _mintId(body),
            visitId: Value(visitId),
            presetId: Value(presetId),
            captured: Value(capturedManual),
            // Snapshot, same as every other scope: a later preset edit must
            // not rewrite what was already given away.
            name: discountName,
            kind: discountKind,
            value: Value(discountValue),
            byUserId: Value(actor?.id),
            approvedByUserId: Value(approvedBy),
            at: SatClock.now().toUtc(),
          ),
        );
    // _recompute resolves the rupiah amount against the current base and fans
    // it out across the itemized receipts.
    await _recompute(db, visitId);
    await _audit(
      db,
      AuditType.discountApplied,
      AuditKind.discountBillApplied,
      params: {'name': discountName},
      tableId: visit!.tableId,
      actor: actor?.id,
    );
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Remove the bill-scope discount. POST for the same reason as the receipt
  // one — a step-up PIN must never ride a query string.
  r.post('/settlement/visits/<visitId>/discounts/<discountId>/remove', (
    Request req,
    String visitId,
    String discountId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final raw = await req.readAsString();
    final body = raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final captured = await signedCapture(req, body, Capability.applyDiscount);
    final visit = await _visit(db, visitId);
    if (visit == null && captured) {
      final session = await (db.select(
        db.tableSessions,
      )..where((s) => s.id.equals(visitId))).getSingleOrNull();
      if (session == null) return _err(404, 'no_visit', 'visit not found');
      final row =
          await (db.select(db.tableSessionDiscounts)..where(
                (d) =>
                    d.id.equals(discountId) &
                    d.sessionId.equals(visitId) &
                    d.receiptId.isNull() &
                    d.ticketId.isNull(),
              ))
              .getSingleOrNull();
      if (row == null) {
        return _err(404, 'no_discount', 'diskon tidak ditemukan');
      }
      if (row.source != 'manual') {
        return _err(409, 'discount_not_manual', 'diskon ini dari pelanggan');
      }
      if (!(await capsOf(req)).contains(Capability.applyDiscount.name) &&
          await resolveStepUp(body['approverPin'] as String?) == null) {
        return _err(403, 'approval_required', 'butuh persetujuan manajer');
      }
      final tickets = await (db.select(
        db.tableSessionTickets,
      )..where((t) => t.sessionId.equals(visitId))).get();
      final active = tickets.where((t) => t.status != 'voided').toList();
      final activeIds = active.map((t) => t.ticketId).toSet();
      final subtotal = active.fold<int>(0, (sum, t) => sum + t.price * t.qty);
      final discounts = await (db.select(
        db.tableSessionDiscounts,
      )..where((d) => d.sessionId.equals(visitId))).get();
      final lineDiscount = discounts
          .where((d) => d.ticketId != null && activeIds.contains(d.ticketId))
          .fold<int>(0, (sum, d) => sum + d.amount);
      final orderDiscount = discounts
          .where((d) => d.ticketId == null)
          .fold<int>(0, (sum, d) => sum + d.amount);
      final cfg = await _config(db, visitId);
      final before = computeBreakdown(
        subtotal - lineDiscount,
        cfg,
        discount: orderDiscount,
      );
      final after = computeBreakdown(
        subtotal - lineDiscount,
        cfg,
        discount: orderDiscount - row.amount,
      );
      final actor = await resolve(req);
      await db.transaction(() async {
        await (db.delete(
          db.tableSessionDiscounts,
        )..where((d) => d.id.equals(discountId))).go();
        await (db.update(
          db.tableSessions,
        )..where((s) => s.id.equals(visitId))).write(
          TableSessionsCompanion(
            discountAmount: Value(session.discountAmount - row.amount),
            settledTotal: Value(
              session.settledTotal + after.total - before.total,
            ),
          ),
        );
        await _audit(
          db,
          AuditType.discountRemoved,
          AuditKind.discountBillRemoved,
          params: {'name': row.name},
          tableId: session.tableId,
          actor: actor?.id,
          at: _capturedAt(body),
        );
      });
      hub.broadcast(WsEventTypes.tableSessionClosed, {
        'tableId': session.tableId,
        'visitId': visitId,
      });
      return _ok({'bill': await _buildSessionBill(db, visitId)});
    }
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final locked = captured ? null : await lockGuard(visitId);
    if (locked != null) return locked;
    final paid = await (db.select(
      db.receipts,
    )..where((x) => x.visitId.equals(visitId) & x.status.equals('paid'))).get();
    if (paid.isNotEmpty && !captured) {
      return _err(
        409,
        'receipt_paid',
        'buka ulang struk yang sudah dibayar sebelum ubah diskon tagihan',
      );
    }
    final actor = await resolve(req);
    if (!(await capsOf(req)).contains(Capability.applyDiscount.name)) {
      final pin = body['approverPin'] as String?;
      if (await resolveStepUp(pin) == null) {
        return _err(
          403,
          'approval_required',
          'butuh persetujuan manajer untuk mengubah diskon',
        );
      }
    }
    final row =
        await (db.select(db.discounts)..where(
              (x) =>
                  x.id.equals(discountId) &
                  x.visitId.equals(visitId) &
                  x.receiptId.isNull(),
            ))
            .getSingleOrNull();
    if (row == null) return _err(404, 'no_discount', 'diskon tidak ditemukan');
    // A member discount rides the member and a redemption owes points back, so
    // neither is a row this route may quietly delete (ADR-0094).
    if (row.source != 'manual') {
      return _err(
        409,
        'discount_not_manual',
        'diskon ini dilepas dari panel pelanggan',
      );
    }
    await (db.delete(db.discounts)..where((x) => x.id.equals(discountId))).go();
    await _recompute(db, visitId);
    await _audit(
      db,
      AuditType.discountRemoved,
      AuditKind.discountBillRemoved,
      params: {'name': row.name},
      tableId: visit.tableId,
      actor: actor?.id,
    );
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // ---------------------------------------------------------------------
  // Membership at the till (ADR-0093). Everything below moves a live bill, so
  // it lives here rather than in `members_routes.dart`: attaching a member and
  // redeeming points both change what the guest owes.
  // ---------------------------------------------------------------------

  /// A member discount and a redemption are quotes the guest was already given
  /// once money has been taken, so both are frozen at the first payment — the
  /// same rule ADR-0068 puts on a bill discount.
  Future<Response?> unpaidGuard(String visitId) async {
    final paid = await (db.select(
      db.receipts,
    )..where((x) => x.visitId.equals(visitId) & x.status.equals('paid'))).get();
    if (paid.isNotEmpty) {
      return _err(
        409,
        'receipt_paid',
        'buka ulang struk yang sudah dibayar dulu',
      );
    }
    return null;
  }

  /// Drop the member's two bill-discount slots. Returns the points a live
  /// redemption is worth so the caller can hand them back.
  Future<void> clearMemberDiscounts(String visitId) async {
    await (db.delete(db.discounts)..where(
          (x) =>
              x.visitId.equals(visitId) &
              x.receiptId.isNull() &
              x.source.isIn(['member', 'redeem']),
        ))
        .go();
  }

  Future<Response?> amendArchivedBillMember(
    Request req,
    String visitId,
    Map<String, dynamic> body, {
    required bool detach,
  }) async {
    final captured = await signedCapture(req, body, Capability.settleBill)
        ? _capturedAt(body)
        : null;
    if (captured == null) return null;
    final session = await (db.select(
      db.tableSessions,
    )..where((s) => s.id.equals(visitId))).getSingleOrNull();
    if (session == null) return null;
    final memberId = detach ? null : (body['memberId'] as String?)?.trim();
    if (!detach && (memberId == null || memberId.isEmpty)) {
      return _err(400, 'no_member', 'pelanggan tidak ada');
    }
    final actor = await resolve(req);
    final oldDiscounts =
        await (db.select(db.tableSessionDiscounts)..where(
              (d) =>
                  d.sessionId.equals(visitId) &
                  d.receiptId.isNull() &
                  d.ticketId.isNull() &
                  d.source.isIn(['member', 'redeem']),
            ))
            .get();
    final allDiscounts = await (db.select(
      db.tableSessionDiscounts,
    )..where((d) => d.sessionId.equals(visitId))).get();
    final tickets =
        await (db.select(db.tableSessionTickets)..where(
              (t) =>
                  t.sessionId.equals(visitId) & t.status.equals('voided').not(),
            ))
            .get();
    final activeIds = tickets.map((t) => t.ticketId).toSet();
    final subtotal = tickets.fold<int>(0, (sum, t) => sum + t.price * t.qty);
    final lineDiscount = allDiscounts
        .where((d) => d.ticketId != null && activeIds.contains(d.ticketId))
        .fold<int>(0, (sum, d) => sum + d.amount);
    final base = subtotal - lineDiscount;
    final oldAmount = oldDiscounts.fold<int>(0, (sum, d) => sum + d.amount);
    final orderDiscount = allDiscounts
        .where((d) => d.ticketId == null)
        .fold<int>(0, (sum, d) => sum + d.amount);

    Map<String, dynamic>? preset;
    if (!detach && body['memberSplit'] != true) {
      final raw = body['memberDiscount'];
      if (raw is Map) {
        preset = raw.cast<String, dynamic>();
      } else if (body['memberPresetId'] is String) {
        final row =
            await (db.select(db.discountPresets)
                  ..where((p) => p.id.equals(body['memberPresetId'] as String)))
                .getSingleOrNull();
        if (row != null && row.scope == 'bill') {
          preset = {
            'presetId': row.id,
            'name': row.name,
            'kind': row.kind,
            'value': row.value,
          };
        }
      }
    }
    if (!detach &&
        body['memberSplit'] != true &&
        body['memberPresetId'] is String &&
        preset == null) {
      return _err(
        409,
        'member_discount_needs_repair',
        'captured member discount needs repair',
      );
    }
    if (preset != null &&
        (preset['name'] is! String ||
            preset['kind'] is! String ||
            preset['value'] is! int ||
            (preset['value'] as int) < 0)) {
      return _err(
        409,
        'member_discount_needs_repair',
        'captured member discount needs repair',
      );
    }
    final newAmount = preset == null
        ? 0
        : resolveDiscountAmount(
            kind: preset['kind'] as String,
            value: preset['value'] as int,
            base: base,
          );
    final tax = await _config(db, visitId);
    final before = computeBreakdown(base, tax, discount: orderDiscount);
    final after = computeBreakdown(
      base,
      tax,
      discount: orderDiscount - oldAmount + newAmount,
    );
    await db.transaction(() async {
      for (final discount in oldDiscounts) {
        if (discount.source == 'redeem') {
          await reverseCapturedRedeem(
            db,
            discountId: discount.id,
            visitId: visitId,
            memberId: session.memberId,
            actorUserId: actor?.id,
            hub: hub,
          );
        }
      }
      await (db.delete(
        db.tableSessionDiscounts,
      )..where((d) => d.id.isIn(oldDiscounts.map((d) => d.id)))).go();
      if (preset != null) {
        await db
            .into(db.tableSessionDiscounts)
            .insert(
              TableSessionDiscountsCompanion.insert(
                id: _mintId(body),
                sessionId: visitId,
                presetId: Value(preset['presetId'] as String?),
                name: preset['name'] as String,
                kind: preset['kind'] as String,
                value: Value(preset['value'] as int),
                amount: Value(newAmount),
                source: const Value('member'),
                byUserId: Value(actor?.id),
                at: captured,
              ),
            );
      }
      await (db.update(
        db.tableSessions,
      )..where((s) => s.id.equals(visitId))).write(
        TableSessionsCompanion(
          memberId: Value(memberId),
          discountAmount: Value(session.discountAmount - oldAmount + newAmount),
          settledTotal: Value(
            session.settledTotal + after.total - before.total,
          ),
        ),
      );
      if (memberId != null && await getMember(db, memberId) != null) {
        await touchMember(db, memberId, at: captured);
      }
    });
    hub.broadcast(WsEventTypes.tableSessionClosed, {
      'tableId': session.tableId,
      'visitId': visitId,
    });
    return _ok({'bill': await _buildSessionBill(db, visitId)});
  }

  Future<Response?> amendArchivedReceiptMember(
    Request req,
    String receiptId,
    Map<String, dynamic> body, {
    required bool detach,
  }) async {
    final captured = await signedCapture(req, body, Capability.settleBill)
        ? _capturedAt(body)
        : null;
    final visitId = body['visitId'] as String?;
    if (captured == null || visitId == null) return null;
    final receipt =
        await (db.select(db.tableSessionReceipts)..where(
              (r) =>
                  r.receiptId.equals(receiptId) & r.sessionId.equals(visitId),
            ))
            .getSingleOrNull();
    final session = await (db.select(
      db.tableSessions,
    )..where((s) => s.id.equals(visitId))).getSingleOrNull();
    if (receipt == null || session == null) return null;
    final memberId = detach ? null : (body['memberId'] as String?)?.trim();
    if (!detach && (memberId == null || memberId.isEmpty)) {
      return _err(400, 'no_member', 'pelanggan tidak ada');
    }
    final actor = await resolve(req);
    final discounts =
        await (db.select(db.tableSessionDiscounts)..where(
              (d) =>
                  d.sessionId.equals(visitId) & d.receiptId.equals(receiptId),
            ))
            .get();
    final oldDiscounts = discounts
        .where(
          (d) =>
              d.ticketId == null &&
              const {'member', 'redeem'}.contains(d.source),
        )
        .toList();
    final lineDiscount = discounts
        .where((d) => d.ticketId != null)
        .fold<int>(0, (sum, d) => sum + d.amount);
    final base = receipt.subtotal - lineDiscount;
    final oldAmount = oldDiscounts.fold<int>(0, (sum, d) => sum + d.amount);
    final orderDiscount = discounts
        .where((d) => d.ticketId == null)
        .fold<int>(0, (sum, d) => sum + d.amount);

    Map<String, dynamic>? preset;
    if (!detach) {
      final raw = body['memberDiscount'];
      if (raw is Map) {
        preset = raw.cast<String, dynamic>();
      } else if (body['memberPresetId'] is String) {
        final row =
            await (db.select(db.discountPresets)
                  ..where((p) => p.id.equals(body['memberPresetId'] as String)))
                .getSingleOrNull();
        if (row != null && (row.scope == 'bill' || row.scope == 'order')) {
          preset = {
            'presetId': row.id,
            'name': row.name,
            'kind': row.kind,
            'value': row.value,
          };
        }
      }
    }
    if (!detach && body['memberPresetId'] is String && preset == null) {
      return _err(
        409,
        'member_discount_needs_repair',
        'captured member discount needs repair',
      );
    }
    if (preset != null &&
        (preset['name'] is! String ||
            preset['kind'] is! String ||
            preset['value'] is! int ||
            (preset['value'] as int) < 0)) {
      return _err(
        409,
        'member_discount_needs_repair',
        'captured member discount needs repair',
      );
    }
    final newAmount = preset == null
        ? 0
        : resolveDiscountAmount(
            kind: preset['kind'] as String,
            value: preset['value'] as int,
            base: base,
          );
    final tax = await _config(db, visitId);
    final before = computeBreakdown(base, tax, discount: orderDiscount);
    final after = computeBreakdown(
      base,
      tax,
      discount: orderDiscount - oldAmount + newAmount,
    );
    final original = await _originalSessionReceiptJson(db, receipt);
    await db.transaction(() async {
      for (final discount in oldDiscounts) {
        if (discount.source == 'redeem') {
          await reverseCapturedRedeem(
            db,
            discountId: discount.id,
            visitId: visitId,
            memberId: receipt.memberId,
            actorUserId: actor?.id,
            hub: hub,
          );
        }
      }
      await (db.delete(
        db.tableSessionDiscounts,
      )..where((d) => d.id.isIn(oldDiscounts.map((d) => d.id)))).go();
      if (preset != null) {
        await db
            .into(db.tableSessionDiscounts)
            .insert(
              TableSessionDiscountsCompanion.insert(
                id: _mintId(body),
                sessionId: visitId,
                receiptId: Value(receiptId),
                presetId: Value(preset['presetId'] as String?),
                name: preset['name'] as String,
                kind: preset['kind'] as String,
                value: Value(preset['value'] as int),
                amount: Value(newAmount),
                source: const Value('member'),
                byUserId: Value(actor?.id),
                at: captured,
              ),
            );
      }
      await (db.update(
        db.tableSessionReceipts,
      )..where((r) => r.id.equals(receipt.id))).write(
        TableSessionReceiptsCompanion(
          memberId: Value(memberId),
          discountAmount: Value(receipt.discountAmount - oldAmount + newAmount),
          total: Value(receipt.total + after.total - before.total),
          originalSnapshotJson: Value(original),
        ),
      );
      await (db.update(
        db.tableSessions,
      )..where((s) => s.id.equals(visitId))).write(
        TableSessionsCompanion(
          discountAmount: Value(session.discountAmount - oldAmount + newAmount),
          settledTotal: Value(
            session.settledTotal + after.total - before.total,
          ),
        ),
      );
      if (memberId != null && await getMember(db, memberId) != null) {
        await touchMember(db, memberId, at: captured);
      }
    });
    hub.broadcast(WsEventTypes.tableSessionClosed, {
      'tableId': session.tableId,
      'visitId': visitId,
    });
    return _ok({'bill': await _buildSessionBill(db, visitId)});
  }

  Future<Response?> amendArchivedTicketMembers(
    Request req,
    String visitId,
    Map<String, dynamic> body,
  ) async {
    final captured = await signedCapture(req, body, Capability.settleBill)
        ? _capturedAt(body)
        : null;
    if (captured == null) return null;
    final session = await (db.select(
      db.tableSessions,
    )..where((s) => s.id.equals(visitId))).getSingleOrNull();
    if (session == null) return null;
    final ids = (body['ticketIds'] as List? ?? const [])
        .whereType<String>()
        .toSet();
    if (ids.isEmpty) {
      return _err(400, 'no_tickets', 'pilih sedikitnya satu tiket');
    }
    final memberId = (body['memberId'] as String?)?.trim();
    final tickets = await (db.select(
      db.tableSessionTickets,
    )..where((t) => t.sessionId.equals(visitId) & t.ticketId.isIn(ids))).get();
    if (tickets.length != ids.length) {
      return _err(409, 'ticket_changed', 'captured ticket needs repair');
    }

    Map<String, dynamic>? preset;
    if (memberId != null && memberId.isNotEmpty) {
      final raw = body['memberDiscount'];
      if (raw is Map) {
        preset = raw.cast<String, dynamic>();
      } else if (body['memberPresetId'] is String) {
        final row =
            await (db.select(db.discountPresets)
                  ..where((p) => p.id.equals(body['memberPresetId'] as String)))
                .getSingleOrNull();
        if (row?.kind == 'percent') {
          preset = {
            'presetId': row!.id,
            'name': row.name,
            'kind': row.kind,
            'value': row.value,
          };
        }
      }
    }
    if (preset != null &&
        (preset['name'] is! String ||
            preset['kind'] != 'percent' ||
            preset['value'] is! int ||
            (preset['value'] as int) < 0)) {
      return _err(
        409,
        'member_discount_needs_repair',
        'captured member discount needs repair',
      );
    }
    final assignments = await (db.select(
      db.tableSessionReceiptLines,
    )..where((l) => l.sessionId.equals(visitId) & l.ticketId.isIn(ids))).get();
    final affectedReceipts = assignments.map((l) => l.receiptId).toSet();
    final actor = await resolve(req);
    final tax = await _config(db, visitId);
    var totalDelta = 0;
    var discountDelta = 0;
    await db.transaction(() async {
      await (db.update(db.tableSessionTickets)
            ..where((t) => t.sessionId.equals(visitId) & t.ticketId.isIn(ids)))
          .write(TableSessionTicketsCompanion(memberId: Value(memberId)));
      for (final receiptId in affectedReceipts) {
        final receipt =
            await (db.select(db.tableSessionReceipts)..where(
                  (r) =>
                      r.sessionId.equals(visitId) &
                      r.receiptId.equals(receiptId),
                ))
                .getSingleOrNull();
        if (receipt == null || receipt.status == 'cancelled') continue;
        final original = await _originalSessionReceiptJson(db, receipt);
        final discounts =
            await (db.select(db.tableSessionDiscounts)..where(
                  (d) =>
                      d.sessionId.equals(visitId) &
                      d.receiptId.equals(receiptId),
                ))
                .get();
        final oldMember = discounts
            .where(
              (d) =>
                  d.source == 'member' &&
                  d.ticketId != null &&
                  ids.contains(d.ticketId),
            )
            .toList();
        final oldAmount = oldMember.fold<int>(0, (sum, d) => sum + d.amount);
        final lineDiscount = discounts
            .where((d) => d.ticketId != null)
            .fold<int>(0, (sum, d) => sum + d.amount);
        final orderDiscount = discounts
            .where((d) => d.ticketId == null)
            .fold<int>(0, (sum, d) => sum + d.amount);
        final newRows = <({String ticketId, int amount})>[];
        if (preset != null) {
          for (final ticket in tickets) {
            final qty = assignments
                .where(
                  (l) =>
                      l.receiptId == receiptId && l.ticketId == ticket.ticketId,
                )
                .fold<int>(0, (sum, l) => sum + l.qtyUnits);
            if (qty <= 0) continue;
            newRows.add((
              ticketId: ticket.ticketId,
              amount: resolveDiscountAmount(
                kind: 'percent',
                value: preset['value'] as int,
                base: ticket.price * qty,
              ),
            ));
          }
        }
        final newAmount = newRows.fold<int>(0, (sum, row) => sum + row.amount);
        final before = computeBreakdown(
          receipt.subtotal - lineDiscount,
          tax,
          discount: orderDiscount,
        );
        final after = computeBreakdown(
          receipt.subtotal - lineDiscount + oldAmount - newAmount,
          tax,
          discount: orderDiscount,
        );
        await (db.delete(
          db.tableSessionDiscounts,
        )..where((d) => d.id.isIn(oldMember.map((d) => d.id)))).go();
        for (final row in newRows) {
          await db
              .into(db.tableSessionDiscounts)
              .insert(
                TableSessionDiscountsCompanion.insert(
                  id: '${_mintId(body)}:${row.ticketId}:$receiptId',
                  sessionId: visitId,
                  receiptId: Value(receiptId),
                  ticketId: Value(row.ticketId),
                  presetId: Value(preset!['presetId'] as String?),
                  name: preset['name'] as String,
                  kind: 'percent',
                  value: Value(preset['value'] as int),
                  amount: Value(row.amount),
                  source: const Value('member'),
                  byUserId: Value(actor?.id),
                  at: captured,
                ),
              );
        }
        final delta = after.total - before.total;
        totalDelta += delta;
        discountDelta += newAmount - oldAmount;
        await (db.update(
          db.tableSessionReceipts,
        )..where((r) => r.id.equals(receipt.id))).write(
          TableSessionReceiptsCompanion(
            discountAmount: Value(
              receipt.discountAmount + newAmount - oldAmount,
            ),
            total: Value(receipt.total + delta),
            originalSnapshotJson: Value(original),
          ),
        );
      }
      await (db.update(
        db.tableSessions,
      )..where((s) => s.id.equals(visitId))).write(
        TableSessionsCompanion(
          discountAmount: Value(session.discountAmount + discountDelta),
          settledTotal: Value(session.settledTotal + totalDelta),
        ),
      );
      if (memberId != null &&
          memberId.isNotEmpty &&
          await getMember(db, memberId) != null) {
        await touchMember(db, memberId, at: captured);
      }
    });
    hub.broadcast(WsEventTypes.tableSessionClosed, {
      'tableId': session.tableId,
      'visitId': visitId,
    });
    return _ok({'bill': await _buildSessionBill(db, visitId)});
  }

  r.post('/settlement/visits/<visitId>/ticket-members', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final archived = await amendArchivedTicketMembers(req, visitId, body);
    if (archived != null) return archived;
    final visit = await _visit(db, visitId);
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final cfg = await memberConfig(db);
    final captured = await signedCapture(req, body, Capability.settleBill);
    if ((!cfg.splitEnabled && !captured) ||
        visit.memberAttributionVersion != 2) {
      return _err(
        409,
        'ticket_members_disabled',
        'pelanggan per tiket tidak aktif',
      );
    }
    final capturedDiscount = body['memberDiscount'];
    if (captured &&
        ((body['memberPresetId'] is String && capturedDiscount == null) ||
            (capturedDiscount != null &&
                (capturedDiscount is! Map ||
                    capturedDiscount['name'] is! String ||
                    capturedDiscount['kind'] != 'percent' ||
                    capturedDiscount['value'] is! int ||
                    (capturedDiscount['value'] as int) < 0)))) {
      return _err(
        409,
        'member_discount_needs_repair',
        'captured member discount needs repair',
      );
    }
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    final ticketIds = (body['ticketIds'] as List? ?? const [])
        .whereType<String>()
        .toSet();
    if (ticketIds.isEmpty) {
      return _err(400, 'no_tickets', 'pilih sedikitnya satu tiket');
    }
    final memberId = (body['memberId'] as String?)?.trim();
    final member = memberId?.isNotEmpty == true
        ? await getMember(db, memberId!)
        : null;
    if (memberId?.isNotEmpty == true && member == null) {
      return _err(404, 'no_member', 'pelanggan tidak ada');
    }
    final tickets = await (db.select(
      db.tickets,
    )..where((t) => t.visitId.equals(visitId) & t.id.isIn(ticketIds))).get();
    if (tickets.length != ticketIds.length) {
      return _err(409, 'ticket_changed', 'daftar tiket sudah berubah');
    }
    for (final ticket in tickets) {
      if (await _ticketMemberLocked(db, ticket.id)) {
        return _err(
          409,
          'ticket_member_locked',
          'tiket yang sudah dibayar tidak dapat diubah',
        );
      }
    }
    final actor = await resolve(req);
    final auditId = _uuid.v4();
    await db.transaction(() async {
      await (db.update(db.tickets)
            ..where((t) => t.visitId.equals(visitId) & t.id.isIn(ticketIds)))
          .write(TicketsCompanion(memberId: Value(memberId)));
      final receiptIds = <String>{};
      for (final ticketId in ticketIds) {
        final lines = await (db.select(
          db.receiptLines,
        )..where((x) => x.ticketId.equals(ticketId))).get();
        receiptIds.addAll(lines.map((x) => x.receiptId));
      }
      for (final receiptId in receiptIds) {
        await syncTicketMemberDiscounts(
          receiptId,
          cfg,
          actor?.id,
          captured: captured,
          capturedDiscount: capturedDiscount as Map?,
        );
      }
      await db
          .into(db.auditEntries)
          .insert(
            AuditEntriesCompanion.insert(
              id: auditId,
              type: AuditType.memberChanged.name,
              title:
                  '${ticketIds.length} tiket → ${member?.name ?? 'Tanpa pelanggan'}',
              tableId: Value(visit.tableId),
              at: SatClock.now().toUtc(),
              actorUserId: Value(actor?.id),
              actorName: Value(actor?.name),
            ),
          );
    });
    await _recompute(db, visitId);
    final audit = await (db.select(
      db.auditEntries,
    )..where((x) => x.id.equals(auditId))).getSingle();
    hub.broadcast(WsEventTypes.auditCreated, auditJson(audit));
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Attach a [[Pelanggan (member)]] to a live bill. {memberId}. The member's
  // standing discount lands in its own slot straight away, so a cashier who
  // looked the guest up never has to remember to apply it.
  r.post('/settlement/visits/<visitId>/member', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final archived = await amendArchivedBillMember(
      req,
      visitId,
      body,
      detach: false,
    );
    if (archived != null) return archived;
    final visit = await _visit(db, visitId);
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    final unpaid = await unpaidGuard(visitId);
    if (unpaid != null) return unpaid;
    final cfg = await memberConfig(db);
    if (!cfg.enabled &&
        !await signedCapture(req, body, Capability.settleBill)) {
      return _err(409, 'members_disabled', 'keanggotaan tidak aktif');
    }
    final member = await getMember(db, (body['memberId'] as String?) ?? '');
    if (member == null) return _err(404, 'no_member', 'pelanggan tidak ada');

    final actor = await resolve(req);
    // Swapping one member for another gives the first one's points back before
    // the second takes the slot.
    if (visit.memberId != null && visit.memberId != member.id) {
      // Ledger row and discount row land together or not at all (ADR-0100):
      // half of this is a guest whose points went back but whose discount
      // stayed, or the reverse.
      await db.transaction(() async {
        await reverseRedeemForVisit(
          db,
          visitId: visitId,
          actorUserId: actor?.id,
          hub: hub,
        );
        await clearMemberDiscounts(visitId);
      });
    }
    await (db.update(db.visits)..where((v) => v.id.equals(visitId))).write(
      VisitsCompanion(
        memberId: Value(member.id),
        // Fills an empty guest name, never overwrites one a waiter typed —
        // "Pak Budi, ulang tahun" is knowledge the directory does not hold.
        guestName: (visit.guestName ?? '').trim().isEmpty
            ? Value(member.name)
            : const Value.absent(),
      ),
    );

    // The standing member discount, if the venue configured one.
    //
    // Not under `memberSplit` (ADR-0118): with the mode on the tier discount
    // is applied against the [[Pemilik struk]]'s own receipt, and the owner is
    // just another receipt's member. Auto-applying a bill-scope slot here as
    // well would discount them twice — once on the whole bill, once on their
    // share of it.
    Map<String, dynamic>? preset;
    if (await signedCapture(req, body, Capability.settleBill)) {
      if (body['memberSplit'] != true) {
        final raw = body['memberDiscount'];
        if (raw is Map) {
          try {
            preset = Map<String, dynamic>.from(raw);
          } catch (_) {
            return _err(
              409,
              'member_discount_needs_repair',
              'captured member discount needs repair',
            );
          }
        }
        if (body['memberPresetId'] is String && preset == null) {
          return _err(
            409,
            'member_discount_needs_repair',
            'captured member discount needs repair',
          );
        }
      }
    } else if (!cfg.splitEnabled && cfg.presetId != null) {
      final row = await (db.select(
        db.discountPresets,
      )..where((x) => x.id.equals(cfg.presetId!))).getSingleOrNull();
      if (row != null && row.active && row.scope == 'bill') {
        preset = {
          'presetId': row.id,
          'name': row.name,
          'kind': row.kind,
          'value': row.value,
        };
      }
    }
    if (preset != null &&
        await _billDiscountOf(db, visitId, 'member') == null) {
      if (preset['name'] is! String ||
          preset['kind'] is! String ||
          preset['value'] is! int ||
          (preset['value'] as int) < 0) {
        return _err(
          409,
          'member_discount_needs_repair',
          'captured member discount needs repair',
        );
      }
      await db
          .into(db.discounts)
          .insert(
            DiscountsCompanion.insert(
              id: _uuid.v4(),
              visitId: Value(visitId),
              presetId: Value(preset['presetId'] as String?),
              name: preset['name'] as String,
              kind: preset['kind'] as String,
              value: Value(preset['value'] as int),
              source: const Value('member'),
              byUserId: Value(actor?.id),
              at: SatClock.now().toUtc(),
            ),
          );
    }
    await _recompute(db, visitId);
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Detach the member. Any live redemption is handed back first — the guest
  // spent nothing, so they keep their points.
  r.post('/settlement/visits/<visitId>/member/detach', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final raw = await req.readAsString();
    final body = raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final archived = await amendArchivedBillMember(
      req,
      visitId,
      body,
      detach: true,
    );
    if (archived != null) return archived;
    final visit = await _visit(db, visitId);
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    final unpaid = await unpaidGuard(visitId);
    if (unpaid != null) return unpaid;
    final actor = await resolve(req);
    // The points, the discount and the detachment are one act (ADR-0100).
    await db.transaction(() async {
      await reverseRedeemForVisit(
        db,
        visitId: visitId,
        actorUserId: actor?.id,
        hub: hub,
      );
      await clearMemberDiscounts(visitId);
      await (db.update(db.visits)..where((v) => v.id.equals(visitId))).write(
        const VisitsCompanion(memberId: Value(null)),
      );
    });
    await _recompute(db, visitId);
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Spend points as money off this bill. {points}. The ledger row and the
  // matching `redeem`-slot discount land together or not at all — a balance
  // that moved without the bill moving is a balance somebody spent twice.
  Future<Response?> amendArchivedRedeem(
    Request req,
    String visitId,
    String? receiptId,
    Map<String, dynamic> body, {
    required bool remove,
  }) async {
    if (!await signedCapture(req, body, Capability.settleBill)) return null;
    final session = await (db.select(
      db.tableSessions,
    )..where((s) => s.id.equals(visitId))).getSingleOrNull();
    if (session == null) return null;
    final receipt = receiptId == null
        ? null
        : await (db.select(
            db.tableSessionReceipts,
          )..where((r) => r.receiptId.equals(receiptId))).getSingleOrNull();
    if (receiptId != null &&
        (receipt == null || receipt.sessionId != visitId)) {
      return _err(404, 'no_receipt', 'receipt not found on visit');
    }
    final memberId = receiptId == null ? session.memberId : receipt!.memberId;
    final existing =
        await (db.select(db.tableSessionDiscounts)..where(
              (d) =>
                  d.sessionId.equals(visitId) &
                  (receiptId == null
                      ? d.receiptId.isNull()
                      : d.receiptId.equals(receiptId)) &
                  d.ticketId.isNull() &
                  d.source.equals('redeem'),
            ))
            .getSingleOrNull();
    final actor = await resolve(req);
    if (remove) {
      if (existing == null) {
        return _ok({'bill': await _buildSessionBill(db, visitId)});
      }
      await db.transaction(() async {
        await reverseCapturedRedeem(
          db,
          discountId: existing.id,
          memberId: memberId,
          visitId: visitId,
          actorUserId: actor?.id,
          hub: hub,
        );
        await (db.delete(
          db.tableSessionDiscounts,
        )..where((d) => d.id.equals(existing.id))).go();
        await db.customStatement(
          'UPDATE table_sessions SET discount_amount = discount_amount - ?, '
          'settled_total = settled_total + ? WHERE id = ?',
          [existing.amount, existing.amount, visitId],
        );
      });
    } else {
      if (existing != null) {
        return _err(409, 'redeem_exists', 'sudah ada penukaran poin');
      }
      if (memberId == null) {
        return _err(409, 'no_member', 'tidak ada pelanggan');
      }
      final points = (body['points'] as num?)?.toInt() ?? 0;
      final pointValue =
          (body['pointValue'] as num?)?.toInt() ??
          (await memberConfig(db)).pointValue;
      if (points <= 0 || pointValue <= 0) {
        return _err(400, 'bad_points', 'jumlah poin tidak valid');
      }
      final discountId = _mintId(body);
      try {
        await db.transaction(() async {
          final amount = await spendPoints(
            db,
            memberId: memberId,
            visitId: visitId,
            points: points,
            actorUserId: actor?.id,
            hub: hub,
            at: _capturedAt(body),
            honorCaptured: true,
            capturedPointValue: pointValue,
            idPrefix: '$discountId:',
          );
          await db
              .into(db.tableSessionDiscounts)
              .insert(
                TableSessionDiscountsCompanion.insert(
                  id: discountId,
                  sessionId: visitId,
                  receiptId: Value(receiptId),
                  name: 'Tukar poin',
                  kind: 'fixed',
                  value: Value(amount),
                  amount: Value(amount),
                  source: const Value('redeem'),
                  byUserId: Value(actor?.id),
                  at: _capturedAt(body)!,
                ),
              );
          await db.customStatement(
            'UPDATE table_sessions SET discount_amount = discount_amount + ?, '
            'settled_total = settled_total - ? WHERE id = ?',
            [amount, amount, visitId],
          );
        });
      } on MemberException catch (e) {
        return _err(409, e.code, 'penukaran poin ditolak');
      }
    }
    hub.broadcast(WsEventTypes.tableSessionClosed, {
      'tableId': session.tableId,
      'visitId': visitId,
    });
    return _ok({'bill': await _buildSessionBill(db, visitId)});
  }

  r.post('/settlement/visits/<visitId>/redeem', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final captured = await signedCapture(req, body, Capability.settleBill);
    final visit = await _visit(db, visitId);
    if (visit == null) {
      final archived = await amendArchivedRedeem(
        req,
        visitId,
        null,
        body,
        remove: false,
      );
      if (archived != null) return archived;
    }
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final memberId = visit.memberId;
    if (memberId == null) {
      return _err(409, 'no_member', 'tidak ada pelanggan di tagihan ini');
    }
    final locked = captured ? null : await lockGuard(visitId);
    if (locked != null) return locked;
    if (!captured) {
      final unpaid = await unpaidGuard(visitId);
      if (unpaid != null) return unpaid;
    }
    if (await _billDiscountOf(db, visitId, 'redeem') != null) {
      return _err(409, 'redeem_exists', 'sudah ada penukaran poin di tagihan');
    }
    final points = (body['points'] as num?)?.toInt() ?? 0;
    final cfg = await memberConfig(db);

    // A redemption bigger than the bill would burn points for nothing, so the
    // ceiling is what this bill can actually absorb.
    final bill = await _buildBill(db, visitId);
    if (bill == null) return _err(409, 'no_lines', 'tidak ada pesanan');
    final room =
        (bill['total'] as int) -
        (bill['serviceAmount'] as int) -
        (bill['taxAmount'] as int);
    final pointValue = !captured
        ? cfg.pointValue
        : (body['pointValue'] as num?)?.toInt() ?? cfg.pointValue;
    final maxPoints = pointValue <= 0 ? 0 : room ~/ pointValue;
    if (points > maxPoints) {
      return _err(409, 'exceeds_bill', 'poin melebihi nilai tagihan', {
        'points': maxPoints,
      });
    }

    final actor = await resolve(req);
    try {
      // The ledger row and the discount it pays for are one write (ADR-0100).
      // `spendPoints` deliberately does not create the discount itself, so
      // this is the only place the pair is held together.
      await db.transaction(() async {
        final amount = await spendPoints(
          db,
          memberId: memberId,
          visitId: visitId,
          points: points,
          actorUserId: actor?.id,
          hub: hub,
          // The ledger row and its audit backdate with the money they belong
          // to (ADR-0123 §capturedAt). A redeem captured at 23:50 and drained
          // at 00:10 otherwise files the give-back in the next day's member
          // report while the payment it paid for sits in the previous day's.
          at: captured ? _capturedAt(body) : null,
          honorCaptured: captured,
          capturedPointValue: (body['pointValue'] as num?)?.toInt(),
        );
        await db
            .into(db.discounts)
            .insert(
              DiscountsCompanion.insert(
                id: _uuid.v4(),
                visitId: Value(visitId),
                // No preset behind it — the guest's own points are the
                // authority, and the amount is what the venue's own rate
                // makes them worth.
                name: 'Tukar poin',
                // 'fixed' = rupiah off. `resolveDiscountAmount` reads every
                // OTHER kind as basis points, so a rupiah figure in a
                // mislabelled row clamps to 10000 bps and takes the whole
                // bill.
                kind: 'fixed',
                value: Value(amount),
                amount: Value(amount),
                source: const Value('redeem'),
                byUserId: Value(actor?.id),
                at: SatClock.now().toUtc(),
              ),
            );
      });
    } on MemberException catch (e) {
      return _err(409, e.code, 'penukaran poin ditolak', {
        if (e.points != null) 'points': e.points,
      });
    }
    await _recompute(db, visitId);
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Take the redemption back off an unpaid bill; the points return.
  r.post('/settlement/visits/<visitId>/redeem/remove', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final captured = await signedCapture(req, body, Capability.settleBill);
    final visit = await _visit(db, visitId);
    if (visit == null) {
      final archived = await amendArchivedRedeem(
        req,
        visitId,
        null,
        body,
        remove: true,
      );
      if (archived != null) return archived;
    }
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final locked = captured ? null : await lockGuard(visitId);
    if (locked != null) return locked;
    final unpaid = captured ? null : await unpaidGuard(visitId);
    if (unpaid != null) return unpaid;
    final actor = await resolve(req);
    // Points back and discount off are one act (ADR-0100).
    await db.transaction(() async {
      await reverseRedeemForVisit(
        db,
        visitId: visitId,
        actorUserId: actor?.id,
        hub: hub,
      );
      await (db.delete(db.discounts)..where(
            (x) =>
                x.visitId.equals(visitId) &
                x.receiptId.isNull() &
                x.source.equals('redeem'),
          ))
          .go();
    });
    await _recompute(db, visitId);
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Record a payment against a receipt. {method, amount, tendered?, note?}.
  // -------------------------------------------------------------------
  // [[Pemilik struk]] — membership one level down (ADR-0118). Live only
  // under `memberSplit`; without it these four answer 409 and the bill-scope
  // routes above are the whole of membership at the till, exactly as before.
  // -------------------------------------------------------------------

  /// A receipt freezes at its **first payment**, and its member freezes with
  /// it (ADR-0118 §5) — the tier discount is money collected under that name,
  /// so the name may not move while the money does not. Deliberately stricter
  /// than [unpaidGuard]'s `status == 'paid'`: a part-tendered receipt has
  /// taken money and is no longer anybody's to re-attribute.
  Future<Response?> receiptUnpaidGuard(String receiptId) async {
    final pays = await (db.select(
      db.payments,
    )..where((p) => p.receiptId.equals(receiptId))).get();
    if (pays.isNotEmpty) {
      return _err(409, 'receipt_paid', 'buka ulang struk ini dulu');
    }
    return null;
  }

  // Name a [[Pemilik struk]]. {memberId}. Their standing discount lands on
  // this receipt straight away, the way attaching to a bill has always
  // applied it to the bill.
  r.post('/settlement/receipts/<receiptId>/member', (
    Request req,
    String receiptId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final archived = await amendArchivedReceiptMember(
      req,
      receiptId,
      body,
      detach: false,
    );
    if (archived != null) return archived;
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final visitId = rec.visitId ?? rec.tableId;
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    final paid = await receiptUnpaidGuard(receiptId);
    if (paid != null) return paid;
    final (cfg, blocked) = await requireSplit(req, body);
    if (blocked != null) return blocked;
    final member = await getMember(db, (body['memberId'] as String?) ?? '');
    if (member == null) return _err(404, 'no_member', 'pelanggan tidak ada');

    final actor = await resolve(req);
    await db.transaction(() async {
      // Swapping one guest for another hands the first their points back and
      // takes their discount off, before the second takes the slot — the same
      // act the bill-scope attach performs, scoped to one member so the three
      // sitting beside them are untouched.
      if (rec.memberId != null && rec.memberId != member.id) {
        await reverseRedeemForVisit(
          db,
          visitId: visitId,
          memberId: rec.memberId,
          actorUserId: actor?.id,
          hub: hub,
        );
        await (db.delete(db.discounts)..where(
              (x) =>
                  x.receiptId.equals(receiptId) &
                  x.ticketId.isNull() &
                  x.source.isIn(['member', 'redeem']),
            ))
            .go();
      }
      await writeReceiptMember(
        receiptId,
        member.id,
        cfg,
        actor?.id,
        captured: await signedCapture(req, body, Capability.settleBill),
        capturedDiscount: body['memberDiscount'] as Map?,
      );
    });
    await _recompute(db, visitId);
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Unname it. Any live redemption of *that* member is handed back.
  r.post('/settlement/receipts/<receiptId>/member/detach', (
    Request req,
    String receiptId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final raw = await req.readAsString();
    final body = raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final archived = await amendArchivedReceiptMember(
      req,
      receiptId,
      body,
      detach: true,
    );
    if (archived != null) return archived;
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final visitId = rec.visitId ?? rec.tableId;
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    final paid = await receiptUnpaidGuard(receiptId);
    if (paid != null) return paid;
    final (_, blocked) = await requireSplit(req, body);
    if (blocked != null) return blocked;
    final actor = await resolve(req);
    // Points back, discount off and the name cleared are one act (ADR-0100).
    await db.transaction(() async {
      await reverseRedeemForVisit(
        db,
        visitId: visitId,
        memberId: rec.memberId,
        actorUserId: actor?.id,
        hub: hub,
      );
      await (db.delete(db.discounts)..where(
            (x) =>
                x.receiptId.equals(receiptId) &
                x.ticketId.isNull() &
                x.source.isIn(['member', 'redeem']),
          ))
          .go();
      await (db.update(db.receipts)..where((x) => x.id.equals(receiptId)))
          .write(const ReceiptsCompanion(memberId: Value(null)));
    });
    await _recompute(db, visitId);
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Spend this guest's points against their own share. {points}.
  r.post('/settlement/receipts/<receiptId>/redeem', (
    Request req,
    String receiptId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final captured = await signedCapture(req, body, Capability.settleBill);
    final rec = await _receipt(db, receiptId);
    if (rec == null && body['visitId'] is String) {
      final archived = await amendArchivedRedeem(
        req,
        body['visitId'] as String,
        receiptId,
        body,
        remove: false,
      );
      if (archived != null) return archived;
    }
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final memberId = rec.memberId;
    if (memberId == null) {
      return _err(409, 'no_member', 'struk ini belum punya pelanggan');
    }
    final visitId = rec.visitId ?? rec.tableId;
    final locked = captured ? null : await lockGuard(visitId);
    if (locked != null) return locked;
    if (!captured) {
      final paid = await receiptUnpaidGuard(receiptId);
      if (paid != null) return paid;
    }
    final (cfg, blocked) = await requireSplit(req, body);
    if (blocked != null) return blocked;
    if (await _receiptDiscountOf(db, receiptId, 'redeem') != null) {
      return _err(409, 'redeem_exists', 'sudah ada penukaran poin di struk');
    }
    final points = (body['points'] as num?)?.toInt() ?? 0;

    // The ceiling is what *this share* can absorb, not the whole bill — the
    // guest beside them is not paying for these points.
    final room = rec.total - rec.serviceAmount - rec.taxAmount;
    final pointValue = !captured
        ? cfg.pointValue
        : (body['pointValue'] as num?)?.toInt() ?? cfg.pointValue;
    final maxPoints = pointValue <= 0 ? 0 : room ~/ pointValue;
    if (points > maxPoints) {
      return _err(409, 'exceeds_bill', 'poin melebihi nilai struk', {
        'points': maxPoints,
      });
    }

    final actor = await resolve(req);
    try {
      // Ledger row and the discount it pays for are one write (ADR-0100).
      await db.transaction(() async {
        final amount = await spendPoints(
          db,
          memberId: memberId,
          visitId: visitId,
          points: points,
          actorUserId: actor?.id,
          hub: hub,
          // The ledger row and its audit backdate with the money they belong
          // to (ADR-0123 §capturedAt). A redeem captured at 23:50 and drained
          // at 00:10 otherwise files the give-back in the next day's member
          // report while the payment it paid for sits in the previous day's.
          at: captured ? _capturedAt(body) : null,
          honorCaptured: captured,
          capturedPointValue: (body['pointValue'] as num?)?.toInt(),
        );
        await db
            .into(db.discounts)
            .insert(
              DiscountsCompanion.insert(
                id: _uuid.v4(),
                receiptId: Value(receiptId),
                name: 'Tukar poin',
                // 'fixed' = rupiah off; every other kind reads as basis
                // points and would take the whole share.
                kind: 'fixed',
                value: Value(amount),
                amount: Value(amount),
                source: const Value('redeem'),
                byUserId: Value(actor?.id),
                at: SatClock.now().toUtc(),
              ),
            );
      });
    } on MemberException catch (e) {
      return _err(409, e.code, 'penukaran poin ditolak', {
        if (e.points != null) 'points': e.points,
      });
    }
    await _recompute(db, visitId);
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Take the redemption back off an unpaid share; the points return.
  r.post('/settlement/receipts/<receiptId>/redeem/remove', (
    Request req,
    String receiptId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final captured = await signedCapture(req, body, Capability.settleBill);
    final rec = await _receipt(db, receiptId);
    if (rec == null && body['visitId'] is String) {
      final archived = await amendArchivedRedeem(
        req,
        body['visitId'] as String,
        receiptId,
        body,
        remove: true,
      );
      if (archived != null) return archived;
    }
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final visitId = rec.visitId ?? rec.tableId;
    final locked = captured ? null : await lockGuard(visitId);
    if (locked != null) return locked;
    final paid = captured ? null : await receiptUnpaidGuard(receiptId);
    if (paid != null) return paid;
    final (_, blocked) = await requireSplit(req, body);
    if (blocked != null) return blocked;
    final actor = await resolve(req);
    await db.transaction(() async {
      await reverseRedeemForVisit(
        db,
        visitId: visitId,
        memberId: rec.memberId,
        actorUserId: actor?.id,
        hub: hub,
      );
      await (db.delete(db.discounts)..where(
            (x) =>
                x.receiptId.equals(receiptId) &
                x.ticketId.isNull() &
                x.source.equals('redeem'),
          ))
          .go();
    });
    await _recompute(db, visitId);
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  r.post('/settlement/receipts/<receiptId>/payments', (
    Request req,
    String receiptId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final user = await resolve(req);
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final rec = await _receipt(db, receiptId);
    final captured = await signedCapture(req, body, Capability.settleBill)
        ? _capturedAt(body)
        : null;
    final orphanVisitId = (body['visitId'] as String?)?.trim();
    if (rec != null &&
        orphanVisitId != null &&
        orphanVisitId.isNotEmpty &&
        orphanVisitId != (rec.visitId ?? rec.tableId)) {
      return _err(409, 'wrong_visit', 'receipt belongs to another visit');
    }
    if (rec == null &&
        (captured == null || orphanVisitId == null || orphanVisitId.isEmpty)) {
      return _err(404, 'no_receipt', 'receipt not found');
    }
    if (rec == null) {
      final archivedReceipt = await (db.select(
        db.tableSessionReceipts,
      )..where((r) => r.receiptId.equals(receiptId))).getSingleOrNull();
      if (archivedReceipt != null &&
          archivedReceipt.sessionId != orphanVisitId) {
        return _err(409, 'wrong_visit', 'receipt belongs to another visit');
      }
    }
    var visit = rec == null ? await _visit(db, orphanVisitId!) : null;
    TableSession? archivedSession;
    if (rec == null && visit == null) {
      archivedSession = await (db.select(
        db.tableSessions,
      )..where((s) => s.id.equals(orphanVisitId!))).getSingleOrNull();
      if (archivedSession == null) {
        return _err(404, 'no_visit', 'visit not found');
      }
    }
    final visitId =
        rec?.visitId ?? rec?.tableId ?? visit?.id ?? archivedSession!.id;
    if (captured == null && await _legacyParkedPaymentCount(db, visitId) > 0) {
      return _err(
        409,
        'legacy_parked_payment',
        'pembayaran lama belum diselesaikan',
      );
    }
    final locked = archivedSession == null && captured == null
        ? await lockGuard(visitId)
        : null;
    if (locked != null) return locked;
    final method = (body['method'] as String?) ?? 'tunai';
    if (!_methods.contains(method)) {
      return _err(400, 'bad_method', 'unknown payment method');
    }
    final amount = (body['amount'] as num?)?.toInt() ?? 0;
    if (amount <= 0) return _err(400, 'bad_amount', 'amount must be positive');
    // A struk takes several payments now that the tender lock is gone
    // (ADR-0121), so the amount is the cashier's to type and nothing else caps
    // it. Before, the settle mode computed it and this could not be wrong.
    final left = rec == null ? 0 : rec.total - await _paidNet(db, receiptId);
    if (rec != null && amount > left && captured == null) {
      return _err(409, 'overpayment', 'melebihi sisa struk ini', {
        'outstanding': left,
      });
    }
    final onAccount = method == 'piutang';
    // Mandatory proof photo for any non-cash method (ADR-0025). The bytes ride
    // in this same request (base64), so payment + photo land atomically.
    // `piutang` is exempt: nothing was tendered, so there is nothing to shoot.
    final photo = _decodePhoto(body['photoBase64']);
    if (method != 'tunai' && !onAccount && (photo == null || photo.isEmpty)) {
      return _err(
        400,
        'photo_required',
        'foto bukti wajib untuk pembayaran non-tunai',
      );
    }
    // Everything a tab needs is checked before the row is written, so a refusal
    // never leaves a payment standing with no ledger entry behind it.
    visit ??= await _visit(db, visitId);
    // Debt belongs to the payer explicitly named on this leg, independently
    // of ticket, receipt and visit ownership (ADR-0125).
    final debtorId = (body['memberId'] as String?)?.trim();
    if (onAccount) {
      final cfg = await debtConfig(db);
      if (!cfg.enabled &&
          !await signedCapture(req, body, Capability.settleBill)) {
        return _err(404, 'debt_disabled', 'piutang mati');
      }
      if (debtorId == null) {
        return _err(409, 'no_member', 'pilih pelanggan yang berutang');
      }
      if (await getMember(db, debtorId) == null) {
        return _err(404, 'no_member', 'pelanggan tidak ada');
      }
    }
    // Minted up front so the audit row can point at it (ADR-0086); supplied by
    // the till since ADR-0123, so a queued refund can name this leg.
    final paymentId = _mintId(body);
    final storedPhoto = (method == 'tunai' || onAccount) ? null : photo;
    try {
      await db.transaction(() async {
        if (archivedSession != null) {
          await db
              .into(db.tableSessionPayments)
              .insert(
                TableSessionPaymentsCompanion.insert(
                  id: paymentId,
                  sessionId: visitId,
                  receiptId: receiptId,
                  memberId: Value(onAccount ? debtorId : null),
                  method: method,
                  amount: amount,
                  cashierUserId: Value(user?.id),
                  at: captured!,
                  photo: Value(storedPhoto),
                ),
              );
        } else {
          await db
              .into(db.payments)
              .insert(
                PaymentsCompanion.insert(
                  id: paymentId,
                  receiptId: receiptId,
                  visitId: Value(rec == null ? visitId : null),
                  method: method,
                  amount: amount,
                  memberId: Value(onAccount ? debtorId : null),
                  // A tab tenders nothing, so nothing is stored — a change figure
                  // on a promise is a lie the receipt would print.
                  tenderedAmount: Value(
                    onAccount ? null : (body['tendered'] as num?)?.toInt(),
                  ),
                  cashierUserId: Value(user?.id),
                  note: Value((body['note'] as String?)?.trim()),
                  at: captured ?? SatClock.now().toUtc(),
                  photo: Value(storedPhoto),
                ),
              );
        }
        // Inside the same transaction as the payment it belongs to: a charge
        // without its payment is a debt nobody incurred, and a payment without
        // its charge is money nobody owes.
        if (onAccount) {
          await chargeDebt(
            db,
            memberId: debtorId!,
            amount: amount,
            paymentId: paymentId,
            visitId: visitId,
            // The table, not the receipt: `rec.label` is empty on a bill nobody
            // split, and "which table" is how a tab is recognised weeks later.
            billLabel:
                visit?.tableLabel ??
                archivedSession?.tableLabel ??
                rec?.label ??
                '',
            actorUserId: user?.id,
            hub: hub,
            at: captured,
            honorCaptured: captured != null,
          );
        }
        if (archivedSession == null) await _recompute(db, visitId);
        await _audit(
          db,
          AuditType.paymentRecorded,
          AuditKind.paymentRecorded,
          params: {
            'amount': auditRupiah(amount),
            'method': method,
            'label':
                rec?.label ??
                visit?.tableLabel ??
                archivedSession?.tableLabel ??
                '',
          },
          tableId:
              rec?.tableId ?? visit?.tableId ?? archivedSession?.tableId ?? '',
          actor: user?.id,
          amountCents: amount,
          // Only when there is genuinely an image behind it — a cash tender
          // leaves this null so the venue log shows no indicator to tap.
          paymentId: storedPhoto == null ? null : paymentId,
          // The row backdates (ADR-0123 §capturedAt) and so must the audit:
          // `billClosed` is already stamped at capture, so leaving this at
          // drain time files a bill as closed before the payment that closed
          // it — the venue log then reads as an impossible order of events.
          at: captured,
        );
      });
    } on DebtException catch (e) {
      // 409, not 400: the request is well-formed and the cashier did nothing
      // wrong — the member simply has no room. The numbers ride along so the
      // till can say how much is left instead of just refusing.
      return _err(409, e.code, 'piutang ditolak', {
        'balance': e.balance,
        'limit': e.limit,
      });
    }
    if (archivedSession == null) {
      await broadcastBill(visitId);
    } else {
      hub.broadcast(WsEventTypes.tableSessionClosed, {
        'tableId': archivedSession.tableId,
        'visitId': visitId,
      });
    }
    // A payment collected on a dark till and drained after its own business
    // day closed its books is accepted — the cash is in the drawer, and
    // refusing it would lose the record, not the money. It gets a row of its
    // own so the discrepancy the owner finds in a signed-off day has a name
    // (ADR-0123).
    if (captured != null) {
      final hour = await _dayStartHour(db);
      final now = SatClock.now();
      if (businessDayStart(
        captured.toLocal(),
        hour,
      ).isBefore(businessDayStart(now, hour))) {
        await _audit(
          db,
          AuditType.paymentRecorded,
          AuditKind.settlementArrivedLate,
          params: {
            'table': visit?.tableLabel ?? archivedSession?.tableLabel ?? '',
            'amount': auditRupiah(amount),
            'captured': captured.toLocal().toIso8601String(),
          },
          tableId: visit?.tableId ?? archivedSession?.tableId ?? '',
          actor: user?.id,
          amountCents: amount,
          paymentId: paymentId,
        );
      }
    }
    return _ok({
      'bill': archivedSession == null
          ? await _buildBill(db, visitId)
          : await _buildSessionBill(db, visitId),
    });
  });

  // Proof-photo bytes for a LIVE payment (open bill). Kept OUT of the bill JSON
  // (blob never rides the list path); fetched on demand, pinned. See ADR-0025.
  r.get('/settlement/payments/<id>/photo', (Request req, String id) async {
    final row = await (db.select(
      db.payments,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (row == null || row.photo == null) return Response.notFound('no photo');
    return Response.ok(
      row.photo,
      headers: {'content-type': 'image/jpeg', 'cache-control': 'no-cache'},
    );
  });

  // Proof-photo bytes for a CLOSED (snapshotted) payment — past bills / report.
  r.get('/settlement/history/payments/<id>/photo', (
    Request req,
    String id,
  ) async {
    final row = await (db.select(
      db.tableSessionPayments,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (row == null || row.photo == null) return Response.notFound('no photo');
    return Response.ok(
      row.photo,
      headers: {'content-type': 'image/jpeg', 'cache-control': 'no-cache'},
    );
  });

  // Proof-photo bytes for a payment named by an AUDIT row (ADR-0086). The venue
  // log spans open and closed bills in one scroll and has no idea which side of
  // the close a row fell on — so this looks in both tables rather than making
  // the client guess between the two routes above. The id is stable across the
  // close, so exactly one of them can match.
  r.get('/audit/payments/<id>/photo', (Request req, String id) async {
    final denied = await requireCap(req, Capability.viewReports);
    if (denied != null) return denied;
    final live = await (db.select(
      db.payments,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    final photo =
        live?.photo ??
        (await (db.select(
          db.tableSessionPayments,
        )..where((p) => p.id.equals(id))).getSingleOrNull())?.photo;
    if (photo == null) return Response.notFound('no photo');
    return Response.ok(
      photo,
      headers: {'content-type': 'image/jpeg', 'cache-control': 'no-cache'},
    );
  });

  // Record a refund (negative payment) against a receipt. Needs `refund` cap.
  r.post('/settlement/receipts/<receiptId>/refund', (
    Request req,
    String receiptId,
  ) async {
    final denied = await requireCap(req, Capability.refund);
    if (denied != null) return denied;
    final user = await resolve(req);
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final rec = await _receipt(db, receiptId);
    final captured = await signedCapture(req, body, Capability.refund)
        ? _capturedAt(body)
        : null;
    final suppliedVisitId = (body['visitId'] as String?)?.trim();
    if (rec == null &&
        (captured == null ||
            suppliedVisitId == null ||
            suppliedVisitId.isEmpty)) {
      return _err(404, 'no_receipt', 'receipt not found');
    }
    final visitId = rec?.visitId ?? rec?.tableId ?? suppliedVisitId!;
    if (rec != null &&
        suppliedVisitId != null &&
        suppliedVisitId.isNotEmpty &&
        suppliedVisitId != visitId) {
      return _err(409, 'wrong_visit', 'receipt belongs to another visit');
    }
    final visit = await _visit(db, visitId);
    final archivedSession = visit == null
        ? await (db.select(
            db.tableSessions,
          )..where((s) => s.id.equals(visitId))).getSingleOrNull()
        : null;
    if (visit == null && archivedSession == null) {
      return _err(404, 'no_visit', 'visit not found');
    }
    // A refund names the **leg** it unwinds, never a method (ADR-0121). The
    // method used to identify one, because the bill-wide tender lock left a
    // struk holding exactly one; with the lock gone it identifies nothing —
    // two `tunai` legs on one struk are indistinguishable by method, and a
    // `piutang` leg has no money method to name at all.
    final paymentId = (body['paymentId'] as String?)?.trim() ?? '';
    if (paymentId.isEmpty) {
      return _err(400, 'bad_request', 'paymentId required');
    }
    final leg =
        await (db.select(db.payments)..where(
              (x) => x.id.equals(paymentId) & x.receiptId.equals(receiptId),
            ))
            .getSingleOrNull();
    final archivedLeg = leg == null
        ? await (db.select(db.tableSessionPayments)..where(
                (x) =>
                    x.id.equals(paymentId) &
                    x.receiptId.equals(receiptId) &
                    x.sessionId.equals(visitId),
              ))
              .getSingleOrNull()
        : null;
    if (leg == null && archivedLeg == null) {
      return _err(404, 'no_payment', 'payment not found');
    }
    if (archivedLeg != null && captured == null) {
      return _err(
        409,
        'archived_payment',
        'archived refund requires a capture',
      );
    }
    if (leg != null && rec == null && leg.visitId != visitId) {
      return _err(409, 'wrong_visit', 'payment belongs to another visit');
    }
    if (leg?.isRefund == true || archivedLeg?.isRefund == true) {
      return _err(
        409,
        'not_a_payment',
        'baris ini sendiri sebuah pengembalian',
      );
    }
    final amount = (body['amount'] as num?)?.toInt() ?? 0;
    if (amount <= 0) return _err(400, 'bad_amount', 'amount must be positive');
    // What this leg has left to give back: its own amount, less every refund
    // already written against it. Refund rows are negative and carry the leg
    // they unwind, so they net out by addition.
    final priorRefunds =
        (await (db.select(
          db.payments,
        )..where((x) => x.refundsPaymentId.equals(paymentId))).get()).fold<int>(
          0,
          (a, p) => a + p.amount,
        );
    final refundable = (leg?.amount ?? archivedLeg!.amount) + priorRefunds;
    if (amount > refundable && captured == null) {
      return _err(409, 'over_refund', 'melebihi sisa pada pembayaran ini', {
        'refundable': refundable,
      });
    }
    final method = leg?.method ?? archivedLeg!.method;
    final onAccount = method == 'piutang';
    await db.transaction(() async {
      if (archivedLeg != null || archivedSession != null) {
        await db
            .into(db.tableSessionPayments)
            .insert(
              TableSessionPaymentsCompanion.insert(
                id: _mintId(body),
                sessionId: visitId,
                receiptId: receiptId,
                method: method,
                amount: -amount,
                isRefund: const Value(true),
                cashierUserId: Value(user?.id),
                at: captured!,
              ),
            );
      } else {
        await db
            .into(db.payments)
            .insert(
              PaymentsCompanion.insert(
                id: _mintId(body),
                receiptId: receiptId,
                visitId: Value(rec == null ? visitId : null),
                method: method,
                amount: -amount,
                isRefund: const Value(true),
                refundsPaymentId: Value(paymentId),
                cashierUserId: Value(user?.id),
                note: Value((body['note'] as String?)?.trim()),
                at: captured ?? SatClock.now().toUtc(),
              ),
            );
      }
      // A tab leg gives nothing back from the drawer — the claim simply stops
      // standing on the member (ADR-0121). Partial, and in the same
      // transaction as the negative payment for the reason the charge was.
      if (onAccount) {
        await reverseChargeForPayment(
          db,
          paymentId: paymentId,
          amount: amount,
          actorUserId: user?.id,
          hub: hub,
        );
      }
      if (visit != null) await _recompute(db, visitId);
      await _audit(
        db,
        AuditType.refund,
        AuditKind.refund,
        params: {
          'amount': auditRupiah(amount),
          'method': method,
          'label':
              rec?.label ??
              visit?.tableLabel ??
              archivedSession?.tableLabel ??
              '',
        },
        tableId:
            rec?.tableId ?? visit?.tableId ?? archivedSession?.tableId ?? '',
        actor: user?.id,
        reason: (body['note'] as String?)?.trim(),
        // The payment row stores this negative; the audit column is a
        // magnitude, so the sign is dropped here deliberately.
        amountCents: amount,
        // Backdated with its row, for the reason the payment audit is.
        at: captured,
      );
    });
    if (visit != null) {
      await broadcastBill(visitId);
    } else {
      hub.broadcast(WsEventTypes.tableSessionClosed, {
        'tableId': archivedSession!.tableId,
        'visitId': visitId,
      });
    }
    return _ok({
      'bill': visit == null
          ? await _buildSessionBill(db, visitId)
          : await _buildBill(db, visitId),
    });
  });

  // Render + send the MONEY document to a VENUE printer (server-rendered).
  Future<Response> printDoc(
    Map<String, dynamic> bill,
    String? receiptId,
    String? printerId,
  ) async {
    if (printerId == null || printerId.isEmpty) {
      return _err(400, 'bad_request', 'printerId required');
    }
    final printer = await (db.select(
      db.printers,
    )..where((p) => p.id.equals(printerId))).getSingleOrNull();
    if (printer == null) return _err(404, 'no_printer', 'printer not found');
    final v = await (db.select(
      db.venueSettings,
    )..where((x) => x.id.equals('default'))).getSingleOrNull();
    final expenses = receiptId == null && await visitExpenseEnabled(db)
        ? await visitExpenses(db, bill['visitId'] as String)
        : const <expense.VisitExpense>[];
    final data = BillStrukBuilder.fromServerMap(
      expenses: VisitExpenseSummaryDto(
        expenses: [
          for (final e in expenses)
            VisitExpenseDto.fromJson(visitExpenseJson(e)),
        ],
        total: expenses.fold<int>(0, (sum, e) => sum + e.amount),
      ),
      l: satL10n,
      bill: bill,
      receiptId: receiptId,
      venueName: v?.displayName ?? 'SatSet',
      header: v?.receiptHeader ?? '',
      footer: v?.receiptFooter ?? '',
      tagline: v?.receiptTagline ?? '',
      social: v?.receiptSocial ?? '',
      thankYou: v?.receiptThankYou ?? '',
      address: v?.address ?? '',
      phone: v?.phone ?? '',
      logoBytes: v?.logo,
      qrUrl: v?.receiptQrUrl ?? '',
      qrCaption: v?.receiptQrCaption ?? '',
    );
    try {
      final bytes = await BillStrukRenderer.render(satL10n, data);
      await StrukSocket.send(printer.host, printer.port, bytes);
    } catch (e) {
      SatLog.srv(
        'bill print fail printer=$printerId '
        '${printer.host}:${printer.port} $e',
      );
      return _err(502, 'print_failed', 'printer tak terhubung');
    }
    final now = SatClock.now();
    await (db.update(db.printers)..where((p) => p.id.equals(printerId))).write(
      PrintersCompanion(lastSeenAt: Value(now)),
    );
    final updated = await (db.select(
      db.printers,
    )..where((p) => p.id.equals(printerId))).getSingleOrNull();
    if (updated != null) {
      hub.broadcast(WsEventTypes.printerUpdated, {
        'id': updated.id,
        'label': updated.label,
        'host': updated.host,
        'port': updated.port,
        'kind': updated.kind,
        'enabled': updated.enabled,
        'lastSeenAt': updated.lastSeenAt?.toIso8601String(),
        'createdAt': updated.createdAt.toIso8601String(),
      });
    }
    return _ok({'status': 'printed'});
  }

  // Print the whole-bill Tagihan / Struk pembayaran. {printerId}.
  r.post('/settlement/visits/<visitId>/bill/print', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final bill = await _buildBill(db, visitId);
    if (bill == null) return _err(409, 'no_lines', 'tidak ada pesanan');
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    return printDoc(bill, null, body['printerId'] as String?);
  });

  // Print one receipt's Tagihan / Struk pembayaran. {printerId}.
  r.post('/settlement/receipts/<receiptId>/print', (
    Request req,
    String receiptId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final bill = await _buildBill(db, rec.visitId ?? rec.tableId);
    if (bill == null) return _err(409, 'no_lines', 'tidak ada pesanan');
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    return printDoc(bill, receiptId, body['printerId'] as String?);
  });

  // Reopen (un-pay) a receipt: clears its payments. Audited.
  r.post('/settlement/receipts/<receiptId>/reopen', (
    Request req,
    String receiptId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final user = await resolve(req);
    final raw = await req.readAsString();
    final body = raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final captured = await signedCapture(req, body, Capability.settleBill)
        ? _capturedAt(body)
        : null;
    final rec = await _receipt(db, receiptId);
    if (rec == null) {
      final visitId = body['visitId'] as String? ?? '';
      if (captured == null || visitId.isEmpty) {
        return _err(404, 'no_receipt', 'receipt not found');
      }
      final archived =
          await (db.select(db.tableSessionReceipts)..where(
                (r) =>
                    r.receiptId.equals(receiptId) & r.sessionId.equals(visitId),
              ))
              .getSingleOrNull();
      final session = await (db.select(
        db.tableSessions,
      )..where((s) => s.id.equals(visitId))).getSingleOrNull();
      if (archived == null || session == null) {
        return _err(404, 'no_receipt', 'receipt not found');
      }
      // Reopening permits a later captured edit. Keep every archived tender:
      // money already taken remains a visit credit even if it is retaken.
      await _audit(
        db,
        AuditType.billReopened,
        AuditKind.billReopenedReceipt,
        params: {'label': archived.label},
        tableId: session.tableId,
        actor: user?.id,
        at: captured,
      );
      return _ok({'bill': await _buildSessionBill(db, visitId)});
    }
    final visitId = rec.visitId ?? rec.tableId;
    if (captured != null) {
      if (body['visitId'] is String && body['visitId'] != visitId) {
        return _err(409, 'wrong_visit', 'receipt belongs to another visit');
      }
      // Later signed edits can amend this receipt without deleting real tender.
      await _audit(
        db,
        AuditType.billReopened,
        AuditKind.billReopenedReceipt,
        params: {'label': rec.label},
        tableId: rec.tableId,
        actor: user?.id,
        at: captured,
      );
      return _ok({'bill': await _buildBill(db, visitId)});
    }
    // Read the piutang payments BEFORE the delete: this route clears them in
    // bulk and there is no per-payment removal route to hang a hook on, so the
    // reversals have to fan out over whatever is about to disappear. A receipt
    // can carry more than one, so this is a loop, not a lookup.
    final onAccount =
        await (db.select(db.payments)..where(
              (x) => x.receiptId.equals(receiptId) & x.method.equals('piutang'),
            ))
            .get();
    await db.transaction(() async {
      await (db.delete(
        db.payments,
      )..where((x) => x.receiptId.equals(receiptId))).go();
      for (final p in onAccount) {
        await reverseChargeForPayment(
          db,
          paymentId: p.id,
          actorUserId: user?.id,
          hub: hub,
        );
      }
      await _recompute(db, visitId);
      await _audit(
        db,
        AuditType.billReopened,
        AuditKind.billReopenedReceipt,
        params: {'label': rec.label},
        tableId: rec.tableId,
        actor: user?.id,
      );
    });
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // BILL CLOSE (cashier): lock the bill + (when the table is already freed)
  // snapshot the visit into history. {writeOff?: bool, reason?}. Lunas requires
  // outstanding == 0; tak-tertagih (write-off) needs the `refund` cap + reason
  // and records lossAmount = outstanding. See ADR-0024.
  r.post('/settlement/visits/<visitId>/bill-close', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final user = await resolve(req);
    final visit = await _visit(db, visitId);
    final raw = await req.readAsString();
    final body = raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final captured = await signedCapture(req, body, Capability.settleBill)
        ? _capturedAt(body)
        : null;
    if (visit == null) {
      if (captured == null) {
        return _err(404, 'no_visit', 'visit not found');
      }
      final session = await (db.select(
        db.tableSessions,
      )..where((s) => s.id.equals(visitId))).getSingleOrNull();
      if (session == null) return _err(404, 'no_visit', 'visit not found');
      final writeOff = body['writeOff'] == true;
      final loss = body['capturedLoss'];
      final reason = (body['reason'] as String?)?.trim() ?? '';
      if (writeOff) {
        if (!(await capsOf(req)).contains(Capability.refund.name)) {
          return _err(
            403,
            'forbidden',
            'tak tertagih perlu persetujuan manajer',
          );
        }
        if (loss is! int || loss < 0 || reason.isEmpty) {
          return _err(
            409,
            'captured_close_needs_repair',
            'captured write-off needs repair',
          );
        }
      }
      await db.transaction(() async {
        if (writeOff) {
          await (db.update(
            db.tableSessions,
          )..where((s) => s.id.equals(visitId))).write(
            TableSessionsCompanion(
              lossAmount: Value(session.lossAmount + (loss as int)),
            ),
          );
        }
        await _audit(
          db,
          AuditType.billClosed,
          writeOff ? AuditKind.billWrittenOff : AuditKind.billClosed,
          params: {
            'table': session.tableLabel ?? '',
            if (writeOff) 'amount': auditRupiah(loss as int),
          },
          tableId: session.tableId,
          actor: user?.id,
          reason: writeOff ? reason : null,
          amountCents: writeOff ? loss as int : null,
          at: captured,
        );
      });
      return _ok({'closed': true, 'snapshotted': true});
    }
    if (visit.billClosedAt != null) {
      return _err(409, 'already_closed', 'tagihan sudah ditutup');
    }
    final bill = await _buildBill(db, visitId);
    if (bill == null) return _err(409, 'no_lines', 'tidak ada pesanan');
    if (captured == null && await _legacyParkedPaymentCount(db, visitId) > 0) {
      return _err(
        409,
        'legacy_parked_payment',
        'pembayaran lama belum diselesaikan',
      );
    }
    final writeOff = body['writeOff'] == true;
    final outstanding = bill['outstanding'] as int;
    final fullyAssigned = bill['fullyAssigned'] == true;
    if (!writeOff) {
      // Recording the final payment leaves the bill open. Only the cashier
      // confirming this explicit action locks it and earns member points.
      if (outstanding > 0 || !fullyAssigned) {
        return _err(
          409,
          'not_settled',
          'tagihan belum lunas — gunakan tak tertagih untuk menutup',
        );
      }
    } else {
      // Write-off is a recorded loss → manager-approved (refund authority).
      if (!(await capsOf(req)).contains(Capability.refund.name)) {
        return _err(403, 'forbidden', 'tak tertagih perlu persetujuan manajer');
      }
      final reason = (body['reason'] as String?)?.trim() ?? '';
      if (reason.isEmpty) {
        return _err(400, 'reason_required', 'alasan tak tertagih wajib diisi');
      }
    }
    final loss = writeOff ? outstanding : 0;
    final snapshotted = await performBillClose(
      visit,
      actorId: user?.id,
      loss: loss,
      reason: writeOff ? (body['reason'] as String?)?.trim() : null,
      at: captured,
    );
    return _ok({'closed': true, 'snapshotted': snapshotted});
  });

  // Reopen (unlock) a bill-closed-but-not-yet-snapshotted bill, to correct it.
  r.post('/settlement/visits/<visitId>/reopen', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final user = await resolve(req);
    final visit = await _visit(db, visitId);
    if (visit == null) {
      final raw = await req.readAsString();
      final body = raw.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      final captured = await signedCapture(req, body, Capability.settleBill)
          ? _capturedAt(body)
          : null;
      if (captured == null) return _err(404, 'no_visit', 'visit not found');
      final session = await (db.select(
        db.tableSessions,
      )..where((s) => s.id.equals(visitId))).getSingleOrNull();
      if (session == null) return _err(404, 'no_visit', 'visit not found');
      await db.transaction(() async {
        await (db.update(
          db.tableSessions,
        )..where((s) => s.id.equals(visitId))).write(
          const TableSessionsCompanion(
            lossAmount: Value(0),
            billClosedBy: Value(null),
          ),
        );
        await _audit(
          db,
          AuditType.billReopened,
          AuditKind.billReopened,
          params: {'table': session.tableLabel ?? ''},
          tableId: session.tableId,
          actor: user?.id,
          at: captured,
        );
      });
      return _ok({'bill': await _buildSessionBill(db, visitId)});
    }
    await (db.update(db.visits)..where((v) => v.id.equals(visitId))).write(
      const VisitsCompanion(
        billClosedAt: Value(null),
        billClosedBy: Value(null),
        lossAmount: Value(0),
      ),
    );
    // Clear the floor Lunas mirror if the table is still attached.
    final tbl = await (db.select(
      db.venueTables,
    )..where((t) => t.currentVisitId.equals(visitId))).getSingleOrNull();
    if (tbl != null) {
      await (db.update(db.venueTables)..where((t) => t.id.equals(tbl.id)))
          .write(const VenueTablesCompanion(billClosedAt: Value(null)));
      final fresh = await (db.select(
        db.venueTables,
      )..where((t) => t.id.equals(tbl.id))).getSingleOrNull();
      if (fresh != null) {
        hub.broadcast(WsEventTypes.tableUpdated, tableJson(fresh));
      }
    }
    // The earn this close already paid out is taken back; a later re-close
    // earns afresh against whatever the corrected bill turns out to be. The
    // ledger corrects forwards (ADR-0095), exactly as the cash box does.
    await reverseEarnForVisit(
      db,
      visitId: visitId,
      actorUserId: user?.id,
      hub: hub,
    );
    await _audit(
      db,
      AuditType.billReopened,
      AuditKind.billReopened,
      params: {'table': visit.tableLabel ?? ''},
      tableId: visit.tableId,
      actor: user?.id,
    );
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // PAST BILLS (cashier history): closed bills across the venue, newest-first,
  // bounded on **two** axes — the last `days` (default 7) and the newest
  // `limit` rows within it (default 60, ceiling [historyPageCeiling]). An
  // optional ?tableId scopes to one physical table (the bill-screen Riwayat
  // shortcut); absent ⇒ venue-wide (the cashier's Riwayat tab). Sourced from
  // snapshotted TableSessions. Neither cap is a retention limit — sessions
  // persist longer for reports.
  //
  // Returns `{rows, total}`, not a bare list: `total` counts the whole window,
  // so the Lunas chip reads 300 on a venue that settled 300 while only 60 rows
  // are on the wire. Counting the rows instead is the bug ADR-0072 already
  // documented for the audit log. See ADR-0079.
  r.get('/settlement/history', (Request req) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final days = int.tryParse(req.url.queryParameters['days'] ?? '7') ?? 7;
    final limit =
        (int.tryParse(req.url.queryParameters['limit'] ?? '') ??
                historyPageSize)
            .clamp(1, historyPageCeiling);
    final tableId = req.url.queryParameters['tableId'];
    final scoped = tableId != null && tableId.isNotEmpty;
    // Only the bills that went out on trust (ADR-0098). A filter, not a
    // segment: a tab-paid bill is Lunas like any other, it just needs chasing.
    final onAccount = req.url.queryParameters['onAccount'] == '1';
    final cutoff = SatClock.now().toUtc().subtract(Duration(days: days));

    // Net `piutang` per closed session across the whole window — one query
    // answering three questions: which sessions the filter keeps, what each
    // row's pill says, and the window total the chip carries. Net, because a
    // refunded tab leg is stored as a negative payment that unwinds the charge
    // (ADR-0121), so a fully reversed tab must not read as one.
    final piutangSum = db.tableSessionPayments.amount.sum();
    final pq =
        db.selectOnly(db.tableSessionPayments).join([
            innerJoin(
              db.tableSessions,
              db.tableSessions.id.equalsExp(db.tableSessionPayments.sessionId),
            ),
          ])
          ..addColumns([db.tableSessionPayments.sessionId, piutangSum])
          ..where(
            db.tableSessionPayments.method.equals('piutang') &
                db.tableSessions.closedAt.isBiggerThanValue(cutoff),
          )
          ..groupBy([db.tableSessionPayments.sessionId]);
    if (scoped) pq.where(db.tableSessions.tableId.equals(tableId));
    final piutang = <String, int>{};
    for (final row in await pq.get()) {
      final amount = row.read(piutangSum) ?? 0;
      if (amount > 0) {
        piutang[row.read(db.tableSessionPayments.sessionId)!] = amount;
      }
    }
    final piutangTotal = piutang.values.fold<int>(0, (a, b) => a + b);
    final onAccountIds = piutang.keys.toList();

    final q = db.select(db.tableSessions)
      ..where((s) => s.closedAt.isBiggerThanValue(cutoff))
      ..orderBy([(s) => OrderingTerm.desc(s.closedAt)])
      ..limit(limit);
    if (scoped) q.where((s) => s.tableId.equals(tableId));
    if (onAccount) q.where((s) => s.id.isIn(onAccountIds));
    final sessions = await q.get();

    // Same WHERE, no limit. Counted rather than derived from `sessions`, which
    // is exactly `limit` long once the window is fuller than a page.
    final countCol = db.tableSessions.id.count();
    final cq = db.selectOnly(db.tableSessions)..addColumns([countCol]);
    cq.where(db.tableSessions.closedAt.isBiggerThanValue(cutoff));
    if (scoped) cq.where(db.tableSessions.tableId.equals(tableId));
    if (onAccount) cq.where(db.tableSessions.id.isIn(onAccountIds));
    final total = (await cq.getSingle()).read(countCol) ?? 0;

    return _ok({
      'total': total,
      // The window's tab total, unaffected by [onAccount] — it is the number
      // the filter chip carries, so it must not change when the filter is on.
      'piutangTotal': piutangTotal,
      'rows': [
        for (final s in sessions)
          {
            'sessionId': s.id,
            'tableId': s.tableId,
            'tableLabel': s.tableLabel,
            'kind': s.kind,
            // Frozen at snapshot so the Lunas segment renders the same card a
            // live bill does, channel pill and all. ADR-0066.
            'channel': s.channel,
            'prepaid': s.prepaid,
            'pax': s.pax,
            'closedAt': s.closedAt.toIso8601String(),
            'subtotal': s.subtotal,
            'serviceAmount': s.serviceAmount,
            'taxAmount': s.taxAmount,
            'netTotal': s.netTotal,
            'discountAmount': s.discountAmount,
            'settledTotal': s.settledTotal,
            'lossAmount': s.lossAmount,
            'billClosedBy': s.billClosedBy,
            'ticketCount': s.ticketCount,
            // How much of this closed bill went onto a member's tab. 0 on the
            // overwhelming majority; > 0 is what the card's Piutang pill reads.
            'piutangAmount': piutang[s.id] ?? 0,
          },
      ],
    });
  });

  // One past bill's detail (Struk pembayaran view) reconstructed from the
  // session snapshot tables.
  r.get('/settlement/sessions/<sessionId>/bill', (
    Request req,
    String sessionId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final bill = await _buildSessionBill(db, sessionId);
    if (bill == null) return _err(404, 'no_session', 'session not found');
    return _ok(bill);
  });

  return r;
}

// ───────────────────────── helpers ─────────────────────────

/// A row id the caller may mint (ADR-0123).
///
/// Receipt, payment, discount and refund ids come from the client — **online
/// too**, not only on the [[Antrean setelmen]] path. Minting only offline would
/// give one row two provenances and leave the offline branch exercised only
/// offline. It also lets a queued refund name the payment leg it unwinds before
/// that payment has ever reached the host.
///
/// Falls back to a server uuid so an older client keeps working unchanged.
String _mintId(Map<String, dynamic> body, [String key = 'id']) {
  final given = (body[key] as String?)?.trim() ?? '';
  // Length-bounded rather than uuid-shaped: the id is opaque here, and the
  // primary key is what actually enforces uniqueness.
  if (given.isNotEmpty && given.length <= 64) return given;
  return _uuid.v4();
}

/// When the act actually happened, if the caller was there and the host was
/// not (ADR-0123).
///
/// A payment taken at 23:50 on a dark handset and drained at 00:10 belongs to
/// the shift that collected it; stamping it at drain time makes the closing
/// shift short and the opening one over in the same stroke. A handset clock
/// ahead of the host is clamped to host time so its action still syncs without
/// booking money into tomorrow.
DateTime? _capturedAt(Map<String, dynamic> body) {
  final raw = body['capturedAt'] as String?;
  if (raw == null) return null;
  final t = DateTime.tryParse(raw)?.toUtc();
  if (t == null) return null;
  final now = SatClock.now().toUtc();
  return t.isAfter(now) ? now : t;
}

Future<Receipt?> _receipt(AppDatabase db, String id) =>
    (db.select(db.receipts)..where((x) => x.id.equals(id))).getSingleOrNull();

Future<Response> _capturedArchivedReceiptDiscount(
  AppDatabase db,
  WsHub hub,
  String receiptId,
  Map<String, dynamic> body,
  String? actorId, {
  required bool allowStack,
}) async {
  final visitId = (body['visitId'] as String?)?.trim();
  if (visitId == null || visitId.isEmpty || _capturedAt(body) == null) {
    return _err(404, 'no_receipt', 'receipt not found');
  }
  final session = await (db.select(
    db.tableSessions,
  )..where((s) => s.id.equals(visitId))).getSingleOrNull();
  final receipt =
      await (db.select(db.tableSessionReceipts)..where(
            (r) => r.receiptId.equals(receiptId) & r.sessionId.equals(visitId),
          ))
          .getSingleOrNull();
  if (session == null || receipt == null) {
    return _err(404, 'no_receipt', 'receipt not found');
  }
  final capturedId = body['id'] as String?;
  if (capturedId != null) {
    final prior = await (db.select(
      db.tableSessionDiscounts,
    )..where((d) => d.id.equals(capturedId))).getSingleOrNull();
    if (prior != null) {
      if (prior.sessionId != visitId) {
        return _err(409, 'wrong_visit', 'discount belongs another visit');
      }
      return _ok({'bill': await _buildSessionBill(db, visitId)});
    }
  }
  final preset =
      await (db.select(db.discountPresets)
            ..where((p) => p.id.equals(body['presetId'] as String? ?? '')))
          .getSingleOrNull();
  final snapshot =
      body['name'] is String && body['kind'] is String && body['value'] is num;
  if (preset == null && !snapshot) {
    return _err(404, 'no_preset', 'preset not found');
  }
  final name = snapshot ? body['name'] as String : preset!.name;
  final kind = snapshot ? body['kind'] as String : preset!.kind;
  final value = snapshot ? (body['value'] as num).toInt() : preset!.value;
  final ticketId = body['ticketId'] as String?;
  final perUnit = ticketId != null && body['perUnit'] == true;
  final scope = preset?.scope ?? (ticketId == null ? 'order' : 'line');
  if (scope != (ticketId == null ? 'order' : 'line')) {
    return _err(409, 'scope_mismatch', 'preset scope does not match target');
  }
  final discounts = await (db.select(
    db.tableSessionDiscounts,
  )..where((d) => d.sessionId.equals(visitId))).get();
  if (!allowStack &&
      discounts.any(
        (d) =>
            d.source == 'manual' &&
            d.receiptId == (perUnit ? null : receiptId) &&
            d.ticketId == ticketId,
      )) {
    return _err(409, 'discount_exists', 'diskon sudah ada');
  }
  final tickets = await (db.select(
    db.tableSessionTickets,
  )..where((t) => t.sessionId.equals(visitId))).get();
  final active = tickets.where((t) => t.status != 'voided').toList();
  final activeIds = active.map((t) => t.ticketId).toSet();
  final subtotal = active.fold<int>(0, (sum, t) => sum + t.price * t.qty);
  final lineDiscount = discounts
      .where((d) => d.ticketId != null && activeIds.contains(d.ticketId))
      .fold<int>(0, (sum, d) => sum + d.amount);
  final orderDiscount = discounts
      .where((d) => d.ticketId == null)
      .fold<int>(0, (sum, d) => sum + d.amount);
  int base;
  int units = 1;
  if (ticketId == null) {
    final receiptLineDiscount = discounts
        .where((d) => d.receiptId == receiptId && d.ticketId != null)
        .fold<int>(0, (sum, d) => sum + d.amount);
    base = receipt.subtotal - receiptLineDiscount;
  } else {
    final ticket = tickets.where((t) => t.ticketId == ticketId).firstOrNull;
    final assigned =
        await (db.select(db.tableSessionReceiptLines)..where(
              (l) =>
                  l.receiptId.equals(receiptId) &
                  l.sessionId.equals(visitId) &
                  l.ticketId.equals(ticketId),
            ))
            .get();
    if (ticket == null || assigned.isEmpty || receipt.mode == 'even') {
      return _err(409, 'line_not_on_receipt', 'item ini tidak ada di struk');
    }
    units = assigned.fold<int>(0, (sum, l) => sum + l.qtyUnits);
    base = ticket.price * units;
  }
  final amount = resolveDiscountAmount(
    kind: kind,
    value: value,
    base: base,
    units: perUnit ? units : 1,
  );
  final cfg = await _config(db, visitId);
  final before = computeBreakdown(
    subtotal - lineDiscount,
    cfg,
    discount: orderDiscount,
  );
  final after = computeBreakdown(
    subtotal -
        lineDiscount -
        (ticketId == null || !activeIds.contains(ticketId) ? 0 : amount),
    cfg,
    discount: orderDiscount + (ticketId == null ? amount : 0),
  );
  await db.transaction(() async {
    await db
        .into(db.tableSessionDiscounts)
        .insert(
          TableSessionDiscountsCompanion.insert(
            id: _mintId(body),
            sessionId: visitId,
            receiptId: Value(perUnit ? null : receiptId),
            ticketId: Value(ticketId),
            presetId: Value(body['presetId'] as String?),
            name: name,
            kind: kind,
            value: Value(value),
            amount: Value(amount),
            byUserId: Value(actorId),
            at: _capturedAt(body)!,
          ),
        );
    await (db.update(
      db.tableSessions,
    )..where((s) => s.id.equals(visitId))).write(
      TableSessionsCompanion(
        discountAmount: Value(session.discountAmount + amount),
        settledTotal: Value(session.settledTotal + after.total - before.total),
      ),
    );
    await _audit(
      db,
      AuditType.discountApplied,
      ticketId == null
          ? AuditKind.discountApplied
          : AuditKind.discountAppliedLine,
      params: {'name': name},
      tableId: session.tableId,
      actor: actorId,
      amountCents: amount,
      at: _capturedAt(body),
    );
  });
  hub.broadcast(WsEventTypes.tableSessionClosed, {
    'tableId': session.tableId,
    'visitId': visitId,
  });
  return _ok({'bill': await _buildSessionBill(db, visitId)});
}

Future<Response> _removeCapturedArchivedDiscount(
  AppDatabase db,
  WsHub hub,
  String visitId,
  String discountId,
  String? receiptId,
  Map<String, dynamic> body,
  String? actorId,
) async {
  final session = await (db.select(
    db.tableSessions,
  )..where((s) => s.id.equals(visitId))).getSingleOrNull();
  final row =
      await (db.select(db.tableSessionDiscounts)..where(
            (d) => d.id.equals(discountId) & d.sessionId.equals(visitId),
          ))
          .getSingleOrNull();
  if (session == null ||
      row == null ||
      (receiptId == null
          ? row.ticketId == null || row.receiptId != null
          : row.receiptId != receiptId)) {
    return _err(404, 'no_discount', 'diskon tidak ditemukan');
  }
  if (row.source != 'manual') {
    return _err(409, 'discount_not_manual', 'diskon ini dari pelanggan');
  }
  final tickets = await (db.select(
    db.tableSessionTickets,
  )..where((t) => t.sessionId.equals(visitId))).get();
  final active = tickets.where((t) => t.status != 'voided').toList();
  final activeIds = active.map((t) => t.ticketId).toSet();
  final subtotal = active.fold<int>(0, (sum, t) => sum + t.price * t.qty);
  final discounts = await (db.select(
    db.tableSessionDiscounts,
  )..where((d) => d.sessionId.equals(visitId))).get();
  final lineDiscount = discounts
      .where((d) => d.ticketId != null && activeIds.contains(d.ticketId))
      .fold<int>(0, (sum, d) => sum + d.amount);
  final orderDiscount = discounts
      .where((d) => d.ticketId == null)
      .fold<int>(0, (sum, d) => sum + d.amount);
  final removeLine = row.ticketId != null && activeIds.contains(row.ticketId);
  final cfg = await _config(db, visitId);
  final before = computeBreakdown(
    subtotal - lineDiscount,
    cfg,
    discount: orderDiscount,
  );
  final after = computeBreakdown(
    subtotal - lineDiscount + (removeLine ? row.amount : 0),
    cfg,
    discount: orderDiscount - (row.ticketId == null ? row.amount : 0),
  );
  await db.transaction(() async {
    await (db.delete(
      db.tableSessionDiscounts,
    )..where((d) => d.id.equals(discountId))).go();
    await (db.update(
      db.tableSessions,
    )..where((s) => s.id.equals(visitId))).write(
      TableSessionsCompanion(
        discountAmount: Value(session.discountAmount - row.amount),
        settledTotal: Value(session.settledTotal + after.total - before.total),
      ),
    );
    await _audit(
      db,
      AuditType.discountRemoved,
      AuditKind.discountRemoved,
      params: {'name': row.name},
      tableId: session.tableId,
      actor: actorId,
      at: _capturedAt(body),
    );
  });
  hub.broadcast(WsEventTypes.tableSessionClosed, {
    'tableId': session.tableId,
    'visitId': visitId,
  });
  return _ok({'bill': await _buildSessionBill(db, visitId)});
}

Future<Visit?> _visit(AppDatabase db, String id) =>
    (db.select(db.visits)..where((x) => x.id.equals(id))).getSingleOrNull();

Future<int> _assignedUnits(
  AppDatabase db,
  String ticketId, {
  String? exclude,
}) async {
  final rows = await (db.select(
    db.receiptLines,
  )..where((x) => x.ticketId.equals(ticketId))).get();
  var sum = 0;
  for (final l in rows) {
    if (exclude != null && l.receiptId == exclude) continue;
    sum += l.qtyUnits;
  }
  return sum;
}

Future<bool> _ticketMemberLocked(AppDatabase db, String ticketId) async {
  final lines = await (db.select(
    db.receiptLines,
  )..where((x) => x.ticketId.equals(ticketId))).get();
  if (lines.isEmpty) return false;
  final receiptIds = lines.map((x) => x.receiptId).toSet();
  return (await (db.select(db.payments)..where(
            (p) => p.receiptId.isIn(receiptIds) & p.isRefund.equals(false),
          ))
          .get())
      .isNotEmpty;
}

/// Units of a line no receipt has claimed yet.
Future<int> _freeUnits(AppDatabase db, String ticketId) async {
  final t = await (db.select(
    db.tickets,
  )..where((x) => x.id.equals(ticketId))).getSingleOrNull();
  if (t == null) return 0;
  final free = t.qty - await _assignedUnits(db, ticketId);
  return free < 0 ? 0 : free;
}

Future<void> _assignAllUnassigned(
  AppDatabase db,
  String visitId,
  String receiptId,
) async {
  final tickets = await _sentTickets(db, visitId);
  for (final t in tickets) {
    final assigned = await _assignedUnits(db, t.id);
    final free = t.qty - assigned;
    if (free > 0) {
      await db
          .into(db.receiptLines)
          .insert(
            ReceiptLinesCompanion.insert(
              id: _uuid.v4(),
              receiptId: receiptId,
              ticketId: t.id,
              qtyUnits: Value(free),
            ),
          );
    }
  }
}

// `_clearReceipts` is gone with ADR-0067. Its only caller was `split-even`,
// which used to replace every receipt on the visit; shares are now cut from the
// untracked remainder instead, so nothing is torn down. Deleting one receipt
// still goes through the delete route, which cascades its own rows.

Future<List<Ticket>> _sentTickets(AppDatabase db, String visitId) async {
  final rows = await (db.select(
    db.tickets,
  )..where((x) => x.visitId.equals(visitId))).get();
  return rows
      .where((t) => t.status != 'voided' && t.status != 'draft')
      .toList();
}

Future<int> _dayStartHour(AppDatabase db) async {
  final s = await (db.select(
    db.venueSettings,
  )..where((x) => x.id.equals('default'))).getSingleOrNull();
  return s?.businessDayStartHour ?? 4;
}

Future<TaxServiceConfig> _config(AppDatabase db, String visitId) =>
    visitTaxConfig(db, visitId);

/// Every discount row on a visit's receipts, grouped by receipt id.
Future<Map<String, List<Discount>>> _discountsByReceipt(
  AppDatabase db,
  Iterable<String> receiptIds,
) async {
  final ids = receiptIds.toList();
  if (ids.isEmpty) return const {};
  final rows = await (db.select(
    db.discounts,
  )..where((x) => x.receiptId.isIn(ids))).get();
  final out = <String, List<Discount>>{};
  for (final d in rows) {
    // Non-null by the `receiptId.isIn` filter above — a bill discount
    // (receiptId null) never reaches here. ADR-0070.
    (out[d.receiptId!] ??= <Discount>[]).add(d);
  }
  return out;
}

/// Gather everything [recomputeBill] needs for one visit, as plain records.
///
/// The Drift→records step is the whole cost of ADR-0123's shared rule: the
/// arithmetic itself lives in `domain/` and is run verbatim by a terputus
/// [[Cashier|kasir]] over its cached bill and [[Antrean setelmen]].
Future<
  ({
    List<RcLine> lines,
    List<RcReceipt> receipts,
    List<RcAssign> assigns,
    List<RcDiscount> discounts,
    Map<String, int> paid,
    TaxServiceConfig cfg,
  })
>
_rcInputs(AppDatabase db, String visitId) async {
  final cfg = await _config(db, visitId);
  final tickets = await _sentTickets(db, visitId);
  final recs = await (db.select(
    db.receipts,
  )..where((x) => x.visitId.equals(visitId))).get();
  final ids = [for (final r in recs) r.id];
  final assignRows = ids.isEmpty
      ? const <ReceiptLine>[]
      : await (db.select(
          db.receiptLines,
        )..where((x) => x.receiptId.isIn(ids))).get();
  // Both scopes in one list — `recomputeBill` tells them apart by a null
  // `receiptId`, exactly as the schema does (ADR-0070).
  final discRows = [
    ...(ids.isEmpty
        ? const <Discount>[]
        : await (db.select(
            db.discounts,
          )..where((x) => x.receiptId.isIn(ids))).get()),
    ...await _billDiscounts(db, visitId),
    ...await _lineDiscounts(db, visitId),
  ];
  final paid = <String, int>{};
  for (final r in recs) {
    paid[r.id] = await _paidNet(db, r.id);
  }
  return (
    lines: [
      for (final t in tickets)
        RcLine(ticketId: t.id, unitPrice: t.price, qty: t.qty),
    ],
    receipts: [
      for (final r in recs)
        RcReceipt(id: r.id, mode: r.mode, amountTotal: r.total),
    ],
    assigns: [
      for (final l in assignRows)
        RcAssign(
          receiptId: l.receiptId,
          ticketId: l.ticketId,
          qtyUnits: l.qtyUnits,
        ),
    ],
    discounts: [
      for (final d in discRows)
        RcDiscount(
          id: d.id,
          receiptId: d.receiptId,
          ticketId: d.ticketId,
          kind: d.kind,
          value: d.value,
        ),
    ],
    paid: paid,
    cfg: cfg,
  );
}

/// Recompute every itemized receipt's money + paid status for a visit, and
/// re-resolve every live [[Diskon (discount)]] row's rupiah against its current
/// base (ADR-0037 freezes `kind`/`value`, never the derived `amount`).
///
/// The arithmetic is [recomputeBill]; this function is only the persistence
/// half. Nothing here may compute money — a second rule is the drift ADR-0123
/// exists to prevent.
Future<void> _recompute(AppDatabase db, String visitId) async {
  final input = await _rcInputs(db, visitId);
  final res = recomputeBill(
    lines: input.lines,
    receipts: input.receipts,
    assigns: input.assigns,
    discounts: input.discounts,
    paidByReceipt: input.paid,
    cfg: input.cfg,
  );

  for (final d in input.discounts) {
    final amount = res.discountAmounts[d.id] ?? 0;
    await (db.update(db.discounts)..where((x) => x.id.equals(d.id))).write(
      DiscountsCompanion(amount: Value(amount)),
    );
  }
  for (final rec in input.receipts) {
    final m = res.receipts[rec.id];
    if (m == null) {
      // An amount receipt keeps its frozen claim; only its status moves.
      await (db.update(db.receipts)..where((x) => x.id.equals(rec.id))).write(
        ReceiptsCompanion(status: Value(res.statuses[rec.id] ?? 'unpaid')),
      );
      continue;
    }
    await (db.update(db.receipts)..where((x) => x.id.equals(rec.id))).write(
      ReceiptsCompanion(
        subtotal: Value(m.subtotal),
        discountAmount: Value(m.discountAmount),
        serviceAmount: Value(m.serviceAmount),
        taxAmount: Value(m.taxAmount),
        total: Value(m.total),
        status: Value(m.status),
      ),
    );
  }
}

/// Decode a base64 JPEG payload sent inline with a payment, or null if absent.
Uint8List? _decodePhoto(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    return base64Decode(raw);
  } catch (_) {
    return null;
  }
}

Map<String, dynamic> _discountJson(Discount d) => {
  'id': d.id,
  'ticketId': d.ticketId, // null ⇒ whole-order discount
  'presetId': d.presetId,
  'name': d.name,
  'kind': d.kind,
  'value': d.value,
  'amount': d.amount,
  'perUnit': d.receiptId == null && d.ticketId != null,
  // Which slot this fills (ADR-0094). Without it every row reads as `manual`
  // on the client: the member panel loses its undo and the printed Diskon
  // label can name a redemption the cashier never applied.
  'source': d.source,
  'byUserId': d.byUserId,
  'approvedByUserId': d.approvedByUserId,
  'at': d.at.toIso8601String(),
};

Future<int> _paidNet(AppDatabase db, String receiptId) async {
  // Sum amount only — never load the proof-photo blob into the fold (ADR-0025).
  final rows =
      await (db.selectOnly(db.payments)
            ..addColumns([db.payments.amount])
            ..where(db.payments.receiptId.equals(receiptId)))
          .get();
  return rows.fold<int>(0, (a, r) => a + (r.read(db.payments.amount) ?? 0));
}

Future<void> _audit(
  AppDatabase db,
  AuditType type,
  AuditKind kind, {
  Map<String, String> params = const {},
  required String tableId,
  String? actor,
  String? reason,
  int? amountCents,
  String? paymentId,
  DateTime? at,
}) => writeAudit(
  db,
  type: type,
  kind: kind,
  params: params,
  tableId: tableId,
  actorUserId: actor,
  reason: reason,
  amountCents: amountCents,
  paymentId: paymentId,
  at: at,
);

Future<int> _legacyParkedPaymentCount(AppDatabase db, String visitId) async {
  final rows = await (db.select(
    db.legacyParkedPayments,
  )..where((p) => p.visitId.equals(visitId))).get();
  return rows.length;
}

/// Build the full bill JSON for one visit, or null if it has no sent lines.
Future<Map<String, dynamic>?> _buildBill(
  AppDatabase db,
  String visitId, {
  bool allowEmpty = false,
}) async {
  final visit = await _visit(db, visitId);
  if (visit == null) return null;
  final tickets = await _sentTickets(db, visitId);
  if (tickets.isEmpty && !allowEmpty) return null;
  final cfg = await _config(db, visitId);

  final recs = await (db.select(
    db.receipts,
  )..where((x) => x.visitId.equals(visitId))).get();
  // A bill can hold both kinds at once since ADR-0067, so this is a
  // description, not a setting. `mixed` is a real answer.
  final anyAmount = recs.any((r) => r.mode == 'even');
  final anyItemized = recs.any((r) => r.mode != 'even');
  final mode = anyAmount && anyItemized
      ? 'mixed'
      : anyAmount
      ? 'even'
      : 'itemized';

  // Aggregate the receipts' discounts up to bill level. Without this the bill
  // total stays undiscounted while the receipts shrink, so `outstanding` never
  // reaches zero and a fully-paid discounted bill never shows Lunas.
  final byReceipt = await _discountsByReceipt(db, recs.map((r) => r.id));
  final linePresets = await _lineDiscounts(db, visitId);
  final input = await _rcInputs(db, visitId);
  final money = recomputeBill(
    lines: input.lines,
    receipts: input.receipts,
    assigns: input.assigns,
    discounts: input.discounts,
    paidByReceipt: input.paid,
    cfg: input.cfg,
  );
  final billLineDiscount = money.billLineDiscount;
  // The bill-scope discount (ADR-0070) belongs to the visit, not to any
  // receipt, so it is fetched separately and lands in the same slot an order
  // discount does — same position in the ADR-0038 stack, different owner.
  final billDiscs = await _billDiscounts(db, visitId);
  final billBreak = money.billBreak;

  final orphanPhoto = db.payments.photo.isNotNull();
  final orphanPays =
      await (db.selectOnly(db.payments)
            ..addColumns([
              db.payments.id,
              db.payments.method,
              db.payments.amount,
              db.payments.isRefund,
              db.payments.refundsPaymentId,
              db.payments.tenderedAmount,
              db.payments.cashierUserId,
              db.payments.note,
              db.payments.at,
              orphanPhoto,
            ])
            ..where(db.payments.visitId.equals(visitId)))
          .get();
  final orphanPaid = orphanPays.fold<int>(
    0,
    (sum, payment) => sum + payment.read(db.payments.amount)!,
  );
  var paidNet = orphanPaid;
  var carriedBalance = 0;
  if (visit.tableFreedAt != null) {
    final prior = await (db.select(
      db.tableSessions,
    )..where((s) => s.id.equals(visitId))).getSingleOrNull();
    if (prior != null) {
      final pastPayments =
          await (db.selectOnly(db.tableSessionPayments)
                ..addColumns([db.tableSessionPayments.amount])
                ..where(db.tableSessionPayments.sessionId.equals(visitId)))
              .get();
      final pastPaid = pastPayments.fold<int>(
        0,
        (sum, payment) => sum + payment.read(db.tableSessionPayments.amount)!,
      );
      carriedBalance = pastPaid - prior.settledTotal;
      paidNet += carriedBalance;
    }
  }
  // [[Kartu stempel (punch card)]] per named [[Pemilik struk]], memoised.
  final recPunch = <String, PunchStatus>{};
  final receiptsJson = <Map<String, dynamic>>[];
  for (final rec in recs) {
    final lines = await (db.select(
      db.receiptLines,
    )..where((x) => x.receiptId.equals(rec.id))).get();
    // Project every payment column EXCEPT the blob; expose only `hasPhoto`.
    // Bytes are fetched on demand via the photo route (ADR-0025/0014).
    final payPhoto = db.payments.photo.isNotNull();
    final pays =
        await (db.selectOnly(db.payments)
              ..addColumns([
                db.payments.id,
                db.payments.method,
                db.payments.amount,
                db.payments.isRefund,
                db.payments.refundsPaymentId,
                db.payments.tenderedAmount,
                db.payments.cashierUserId,
                db.payments.note,
                db.payments.at,
                payPhoto,
              ])
              ..where(
                db.payments.receiptId.equals(rec.id) &
                    db.payments.visitId.isNull(),
              ))
            .get();
    final recPaid = pays.fold<int>(
      0,
      (a, p) => a + p.read(db.payments.amount)!,
    );
    paidNet += recPaid;
    // Null when the named member has since been deleted — the receipt was
    // theirs and history does not rewrite (ADR-0092), so the id stays and the
    // client renders its own placeholder.
    final recMember = rec.memberId == null
        ? null
        : await getMember(db, rec.memberId!);
    if (recMember != null && !recPunch.containsKey(recMember.id)) {
      // Once per member, not once per share: a guest with two slips has one
      // card, and the walk is short enough that a map beats a join.
      recPunch[recMember.id] = await punchStatus(db, recMember.id);
    }
    receiptsJson.add({
      'id': rec.id,
      'mode': rec.mode,
      'label': rec.label,
      'subtotal': rec.subtotal,
      'discountAmount': rec.discountAmount,
      'serviceAmount': rec.serviceAmount,
      'taxAmount': rec.taxAmount,
      'total': rec.total,
      'status': rec.status,
      'paidNet': recPaid,
      // The [[Pemilik struk]] (ADR-0118) — who this share is *for*, a
      // different question from who pays it. Null at a venue without the mode
      // and on any share nobody named, whose money is the
      // [[Pemilik tagihan]]'s. Carried whole, like the bill's own member, so
      // the split step can show a balance without a second round trip.
      'memberId': rec.memberId,
      // With the punch fields the bill's own member carries: the slip a guest
      // takes home is the one reminder of what they are banking, and a share
      // that names them must say the same thing the whole-bill doc would.
      'member': recMember == null
          ? null
          : () {
              final p = recPunch[recMember.id];
              return {
                ...memberJson(recMember),
                'punchTarget': p?.target ?? 0,
                'punchRewardDue': p?.rewardDue ?? false,
              };
            }(),
      // Individual rows, not just the total — the money doc prints a NAMED
      // "Diskon <preset>" and line discounts render under their item.
      'discounts': [
        for (final d in (byReceipt[rec.id] ?? const <Discount>[]))
          _discountJson(d),
        for (final d in linePresets)
          if (lines.any((l) => l.ticketId == d.ticketId))
            {
              ..._discountJson(d),
              'amount': money.receiptDiscountAmounts[rec.id]?[d.id] ?? 0,
            },
      ],
      'lines': [
        for (final l in lines) {'ticketId': l.ticketId, 'qtyUnits': l.qtyUnits},
      ],
      'payments': [
        for (final p in pays)
          {
            'id': p.read(db.payments.id)!,
            'method': p.read(db.payments.method)!,
            'amount': p.read(db.payments.amount)!,
            'isRefund': p.read(db.payments.isRefund)!,
            // Which leg this refund unwinds (ADR-0121). The till derives each
            // leg's remaining refundable from these rather than the server
            // sending a fourth money figure per payment.
            'refundsPaymentId': p.read(db.payments.refundsPaymentId),
            'tendered': p.read(db.payments.tenderedAmount),
            'cashierUserId': p.read(db.payments.cashierUserId),
            'note': p.read(db.payments.note),
            'at': p.read(db.payments.at)!.toIso8601String(),
            'hasPhoto': p.read(payPhoto) ?? false,
          },
      ],
    });
  }

  final linesJson = <Map<String, dynamic>>[];
  for (final t in tickets) {
    final ticketMember = t.memberId == null
        ? null
        : await getMember(db, t.memberId!);
    linesJson.add({
      'ticketId': t.id,
      'itemId': t.itemId,
      'name': t.name,
      'variantName': t.variantName,
      'qty': t.qty,
      'unitPrice': t.price,
      'lineTotal': t.price * t.qty,
      'assignedUnits': await _assignedUnits(db, t.id),
      'note': t.note,
      'status': t.status,
      'memberId': t.memberId,
      'memberName': ticketMember?.name,
      'memberLocked': await _ticketMemberLocked(db, t.id),
      'modifiersJson': t.modifiersJson,
      'sentAt': t.sentAt.toIso8601String(),
    });
  }
  final allUnitsAssigned = linesJson.every(
    (l) => (l['assignedUnits'] as int) >= (l['qty'] as int),
  );
  // Gates whether the bill is eligible for confirmed close, so it lives in
  // `bill_math` as a named pure function with its own test rather than as an
  // expression here. See [isFullyAssigned].
  final fullyAssigned = isFullyAssigned(
    hasReceipts: recs.isNotEmpty,
    allUnitsAssigned: allUnitsAssigned,
    receiptsClaim: recs.fold<int>(0, (a, r) => a + r.total),
    billTotal: billBreak.total,
  );
  // Empty or fully discounted receipts stay editable (`unpaid`), but owe
  // nothing. Their status must not suppress the close-bill confirmation.
  final allReceiptsPaid =
      receiptsJson.isNotEmpty &&
      receiptsJson.every((r) => (r['paidNet'] as int) >= (r['total'] as int));
  final outstanding = (billBreak.total - paidNet).clamp(0, 1 << 31);
  final detached = visit.tableFreedAt != null;
  final member = visit.memberId == null
      ? null
      : await getMember(db, visit.memberId!);
  final punch = member == null ? null : await punchStatus(db, member.id);
  final mcfg = await memberConfig(db);

  return {
    'visitId': visit.id,
    'legacyParkedPaymentCount': await _legacyParkedPaymentCount(db, visit.id),
    'tableId': visit.tableId,
    'tableLabel': visit.tableLabel,
    // dineIn | takeaway — lets the cashier branch its copy ("Bawa pulang"
    // vs a detached walkout). See ADR-0026.
    'kind': visit.kind,
    // How a takeaway reached us, and whether an aggregator already settled it.
    // The channel pill is a takeaway's stand-in for a dine-in's zone. ADR-0066.
    'channel': visit.channel,
    'prepaid': visit.prepaid,
    'status': detached ? 'detached' : 'occupied',
    'detached': detached,
    'tableFreedAt': visit.tableFreedAt?.toIso8601String(),
    'billClosedAt': visit.billClosedAt?.toIso8601String(),
    'pax': visit.pax,
    'guestName': visit.guestName,
    // The card leads with zone (dine-in) or channel (takeaway), and states how
    // long the party has been sitting — both facts the old row tile dropped.
    'zoneId': visit.zoneId,
    'openedAt': visit.openedAt?.toIso8601String(),
    'mode': mode,
    'subtotal': billBreak.subtotal,
    // Total give-back on this bill (line + whole-order). Reporting/display
    // figure; the printed rows come off each receipt's `discounts`.
    'discountAmount': billLineDiscount + billBreak.discountAmount,
    'serviceAmount': billBreak.serviceAmount,
    'taxAmount': billBreak.taxAmount,
    'taxAfterDiscount': cfg.taxAfterDiscount,
    'taxConfig': cfg.toJson(),
    'total': billBreak.total,
    'paidAmount': paidNet,
    'outstanding': outstanding,
    'fullyAssigned': fullyAssigned,
    'fullySettled':
        fullyAssigned &&
        outstanding == 0 &&
        (allReceiptsPaid || orphanPaid + carriedBalance > 0),
    // The bill-scope discount rows, so the totals ladder and the printed slip
    // can name each one. Receipt-scoped rows still ride on their receipt.
    // ADR-0070; a list rather than a row since ADR-0094.
    'billDiscounts': [for (final d in billDiscs) _discountJson(d)],
    'lineDiscounts': [for (final d in linePresets) _discountJson(d)],
    // The [[Pelanggan (member)]] on this bill, if one is attached — carried
    // whole so the cashier panel can show the balance and the punch card
    // without a second round trip mid-settlement.
    'memberId': visit.memberId,
    'member': member == null
        ? null
        : {
            ...memberJson(member),
            'punchTarget': punch?.target ?? 0,
            'punchRewardDue': punch?.rewardDue ?? false,
          },
    // Whether this venue may name a [[Pemilik struk]] per receipt (ADR-0118).
    // Composed server-side in `MemberConfig` — the client gates its step on
    // this and never re-derives it from a module list, the rule ADR-0107
    // already puts on `membersOn`.
    'splitEnabled': mcfg.splitEnabled,
    'ticketAttribution':
        mcfg.splitEnabled && visit.memberAttributionVersion == 2,
    'lines': linesJson,
    'receipts': receiptsJson,
    'unallocatedPayments': [
      for (final p in orphanPays)
        {
          'id': p.read(db.payments.id)!,
          'method': p.read(db.payments.method)!,
          'amount': p.read(db.payments.amount)!,
          'isRefund': p.read(db.payments.isRefund)!,
          'refundsPaymentId': p.read(db.payments.refundsPaymentId),
          'tendered': p.read(db.payments.tenderedAmount),
          'cashierUserId': p.read(db.payments.cashierUserId),
          'note': p.read(db.payments.note),
          'at': p.read(db.payments.at)!.toIso8601String(),
          'hasPhoto': p.read(orphanPhoto) ?? false,
        },
    ],
  };
}

/// Every bill-scope [[Diskon (discount)]] on a visit — at most one **per
/// [[Sumber diskon (discount source)|source]]**, by the
/// `idx_discounts_bill_source_uniq` partial index. ADR-0070, amended by
/// ADR-0094: a cashier's promo, a member's standing discount and a points
/// redemption each hold their own slot and stack by design.
Future<List<Discount>> _billDiscounts(AppDatabase db, String visitId) =>
    (db.select(db.discounts)..where(
          (x) =>
              x.visitId.equals(visitId) &
              x.receiptId.isNull() &
              x.ticketId.isNull(),
        ))
        .get();

Future<List<Discount>> _lineDiscounts(AppDatabase db, String visitId) =>
    (db.select(db.discounts)..where(
          (x) =>
              x.visitId.equals(visitId) &
              x.receiptId.isNull() &
              x.ticketId.isNotNull(),
        ))
        .get();

/// A bill discount occupying this source, or null if that slot is free.
Future<Discount?> _billDiscountOf(
  AppDatabase db,
  String visitId,
  String source,
) async =>
    (await (db.select(db.discounts)..where(
              (x) =>
                  x.visitId.equals(visitId) &
                  x.receiptId.isNull() &
                  x.ticketId.isNull() &
                  x.source.equals(source),
            ))
            .get())
        .firstOrNull;

/// The order-scope discount on [receiptId] from one authority (ADR-0118).
/// `getSingleOrNull` is safe because `idx_discounts_order_uniq` covers
/// `(receipt_id, source)` — one slot each for a cashier's promo, the member's
/// tier discount and a redemption, which is the widening this ADR made.
Future<Discount?> _receiptDiscountOf(
  AppDatabase db,
  String receiptId,
  String source,
) =>
    (db.select(db.discounts)..where(
          (x) =>
              x.receiptId.equals(receiptId) &
              x.ticketId.isNull() &
              x.source.equals(source),
        ))
        .getSingleOrNull();

/// Reconstruct a bill-shaped map for a CLOSED session (past bill), from the
/// snapshot tables — for the Struk pembayaran detail view.
Future<String> _originalSessionReceiptJson(
  AppDatabase db,
  TableSessionReceipt receipt,
) async {
  if (receipt.originalSnapshotJson != null) {
    return receipt.originalSnapshotJson!;
  }
  final lines =
      await (db.select(db.tableSessionReceiptLines)..where(
            (l) =>
                l.sessionId.equals(receipt.sessionId) &
                l.receiptId.equals(receipt.receiptId),
          ))
          .get();
  final amount = db.tableSessionPayments.amount;
  final payments =
      await (db.selectOnly(db.tableSessionPayments)
            ..addColumns([amount])
            ..where(
              db.tableSessionPayments.sessionId.equals(receipt.sessionId) &
                  db.tableSessionPayments.receiptId.equals(receipt.receiptId),
            ))
          .get();
  return jsonEncode({
    'mode': receipt.mode,
    'label': receipt.label,
    'subtotal': receipt.subtotal,
    'discountAmount': receipt.discountAmount,
    'serviceAmount': receipt.serviceAmount,
    'taxAmount': receipt.taxAmount,
    'total': receipt.total,
    'status': receipt.status,
    'paidNet': payments.fold<int>(
      0,
      (sum, payment) => sum + payment.read(amount)!,
    ),
    'memberId': receipt.memberId,
    'lines': [
      for (final line in lines)
        {'ticketId': line.ticketId, 'qtyUnits': line.qtyUnits},
    ],
  });
}

Future<Map<String, dynamic>?> _buildSessionBill(
  AppDatabase db,
  String sessionId,
) async {
  final s = await (db.select(
    db.tableSessions,
  )..where((x) => x.id.equals(sessionId))).getSingleOrNull();
  if (s == null) return null;
  final stk = await (db.select(
    db.tableSessionTickets,
  )..where((x) => x.sessionId.equals(sessionId))).get();
  final srec = await (db.select(
    db.tableSessionReceipts,
  )..where((x) => x.sessionId.equals(sessionId))).get();
  // Snapshot payments without the blob; `paymentId` keys the history photo
  // route, `hasPhoto` flags whether to show a thumbnail (ADR-0025).
  final spayPhoto = db.tableSessionPayments.photo.isNotNull();
  final spay =
      await (db.selectOnly(db.tableSessionPayments)
            ..addColumns([
              db.tableSessionPayments.id,
              db.tableSessionPayments.receiptId,
              db.tableSessionPayments.method,
              db.tableSessionPayments.amount,
              db.tableSessionPayments.isRefund,
              db.tableSessionPayments.cashierUserId,
              db.tableSessionPayments.at,
              spayPhoto,
            ])
            ..where(db.tableSessionPayments.sessionId.equals(sessionId)))
          .get();
  // A captured payment can outlive the receipt it named. Its archived row
  // still credits the visit even when no receipt can display it.
  final paidNet = spay.fold<int>(
    0,
    (sum, payment) => sum + payment.read(db.tableSessionPayments.amount)!,
  );
  final outstanding = (s.settledTotal - paidNet).clamp(0, 1 << 31);
  final discounts = await (db.select(
    db.tableSessionDiscounts,
  )..where((d) => d.sessionId.equals(sessionId))).get();
  final assignments = await (db.select(
    db.tableSessionReceiptLines,
  )..where((line) => line.sessionId.equals(sessionId))).get();
  final assignedUnits = <String, int>{};
  for (final line in assignments) {
    assignedUnits.update(
      line.ticketId,
      (qty) => qty + line.qtyUnits,
      ifAbsent: () => line.qtyUnits,
    );
  }
  final fullyAssigned = stk
      .where((ticket) => ticket.status != 'voided')
      .every((ticket) => (assignedUnits[ticket.ticketId] ?? 0) >= ticket.qty);
  final member = s.memberId == null ? null : await getMember(db, s.memberId!);
  final receiptIds = {
    for (final receipt in srec)
      if (receipt.status != 'cancelled') receipt.receiptId,
  };
  final receiptsJson = <Map<String, dynamic>>[];
  for (final rec in srec) {
    if (rec.originalSnapshotJson != null) {
      final original = (jsonDecode(rec.originalSnapshotJson!) as Map)
          .cast<String, dynamic>();
      receiptsJson.add({
        ...original,
        'id': '${rec.receiptId}:original',
        'mode': 'original',
        'paidNet': original['paidNet'] ?? 0,
        'payments': const [],
        'discounts': const [],
      });
    }
    final pays = rec.status == 'cancelled'
        ? <TypedResult>[]
        : spay
              .where(
                (p) =>
                    p.read(db.tableSessionPayments.receiptId) == rec.receiptId,
              )
              .toList();
    final recPaid = pays.fold<int>(
      0,
      (a, p) => a + p.read(db.tableSessionPayments.amount)!,
    );
    final recMember = rec.memberId == null
        ? null
        : await getMember(db, rec.memberId!);
    receiptsJson.add({
      'id': rec.receiptId,
      'mode': rec.originalSnapshotJson == null ? rec.mode : 'amendment',
      'label': rec.label,
      'subtotal': rec.subtotal,
      'discountAmount': rec.discountAmount,
      'serviceAmount': rec.serviceAmount,
      'taxAmount': rec.taxAmount,
      'total': rec.total,
      'status': rec.status == 'cancelled'
          ? 'cancelled'
          : rec.total > 0 && recPaid >= rec.total
          ? 'paid'
          : 'unpaid',
      'paidNet': recPaid,
      // Frozen at snapshot (ADR-0118), so a reprinted past slip still names
      // the guest it was handed to.
      'memberId': rec.memberId,
      'member': recMember == null ? null : memberJson(recMember),
      'lines': [
        for (final line in assignments)
          if (line.receiptId == rec.receiptId)
            {'ticketId': line.ticketId, 'qtyUnits': line.qtyUnits},
      ],
      'discounts': [
        for (final d in discounts)
          if (d.receiptId == rec.receiptId)
            {
              'id': d.id,
              'ticketId': d.ticketId,
              'presetId': d.presetId,
              'name': d.name,
              'kind': d.kind,
              'value': d.value,
              'amount': d.amount,
              'source': d.source,
            },
      ],
      'payments': [
        for (final p in pays)
          {
            'paymentId': p.read(db.tableSessionPayments.id)!,
            'method': p.read(db.tableSessionPayments.method)!,
            'amount': p.read(db.tableSessionPayments.amount)!,
            'isRefund': p.read(db.tableSessionPayments.isRefund)!,
            'cashierUserId': p.read(db.tableSessionPayments.cashierUserId),
            'at': p.read(db.tableSessionPayments.at)!.toIso8601String(),
            'hasPhoto': p.read(spayPhoto) ?? false,
          },
      ],
    });
  }
  final linesJson = [
    for (final t in stk.where((t) => t.status != 'voided'))
      {
        'ticketId': t.ticketId,
        'itemId': t.itemId,
        'name': t.name,
        'variantName': t.variantName,
        'qty': t.qty,
        'unitPrice': t.price,
        'lineTotal': t.price * t.qty,
        'assignedUnits': assignedUnits[t.ticketId] ?? 0,
        'note': t.note,
        'status': t.status,
        'modifiersJson': t.modifiersJson,
        'sentAt': t.sentAt.toIso8601String(),
      },
  ];
  return {
    'sessionId': s.id,
    'legacyParkedPaymentCount': await _legacyParkedPaymentCount(db, s.id),
    'visitId': s.id,
    'tableId': s.tableId,
    'tableLabel': s.tableLabel,
    'kind': s.kind,
    'channel': s.channel,
    'prepaid': s.prepaid,
    'status': outstanding > 0 ? 'detached' : 'closed',
    'detached': true,
    'tableFreedAt': s.closedAt.toIso8601String(),
    'billClosedAt': outstanding > 0 ? null : s.closedAt.toIso8601String(),
    'zoneId': s.zoneId,
    'openedAt': s.openedAt?.toIso8601String(),
    'guestName': null,
    'closedAt': s.closedAt.toIso8601String(),
    'pax': s.pax,
    'mode': srec.any((r) => r.mode == 'even') ? 'even' : 'itemized',
    'subtotal': s.subtotal,
    'discountAmount': s.discountAmount,
    'billDiscounts': [
      for (final d in discounts)
        if (d.receiptId == null && d.ticketId == null)
          {
            'id': d.id,
            'name': d.name,
            'kind': d.kind,
            'value': d.value,
            'amount': d.amount,
            'source': d.source,
            'presetId': d.presetId,
          },
    ],
    'member': member == null ? null : memberJson(member),
    'serviceAmount': s.serviceAmount,
    'taxAmount': s.taxAmount,
    'taxConfig': (await visitTaxConfig(db, s.id)).toJson(),
    'total': s.settledTotal,
    'paidAmount': paidNet,
    'outstanding': outstanding,
    'fullyAssigned': fullyAssigned,
    'fullySettled': fullyAssigned && outstanding == 0,
    'lossAmount': s.lossAmount,
    'lines': linesJson,
    'receipts': receiptsJson,
    'unallocatedPayments': [
      for (final payment in spay)
        if (!receiptIds.contains(
          payment.read(db.tableSessionPayments.receiptId),
        ))
          {
            'paymentId': payment.read(db.tableSessionPayments.id)!,
            'method': payment.read(db.tableSessionPayments.method)!,
            'amount': payment.read(db.tableSessionPayments.amount)!,
            'isRefund': payment.read(db.tableSessionPayments.isRefund)!,
            'cashierUserId': payment.read(
              db.tableSessionPayments.cashierUserId,
            ),
            'at': payment.read(db.tableSessionPayments.at)!.toIso8601String(),
            'hasPhoto': payment.read(spayPhoto) ?? false,
          },
    ],
  };
}

Map<String, dynamic> _summarize(Map<String, dynamic> bill) => {
  'visitId': bill['visitId'],
  'tableId': bill['tableId'],
  'tableLabel': bill['tableLabel'],
  'kind': bill['kind'],
  'status': bill['status'],
  'detached': bill['detached'],
  'tableFreedAt': bill['tableFreedAt'],
  'pax': bill['pax'],
  'guestName': bill['guestName'],
  'zoneId': bill['zoneId'],
  'openedAt': bill['openedAt'],
  'channel': bill['channel'],
  'prepaid': bill['prepaid'],
  'total': bill['total'],
  'paidAmount': bill['paidAmount'],
  'outstanding': bill['outstanding'],
  'receiptCount': (bill['receipts'] as List).length,
  'lineCount': (bill['lines'] as List).length,
  // The card's pill row states the discount by name, so the label has to reach
  // the list payload — the amount alone would render as an unexplained cut.
  // The cashier's own slot is the one named; a member discount is implied by
  // the member pill sitting beside it (ADR-0094).
  'billDiscountLabel': (bill['billDiscounts'] as List)
      .cast<Map<String, dynamic>>()
      .where((d) => d['source'] == 'manual')
      .map((d) => d['name'])
      .firstOrNull,
  // The member on the bill, so the payable card can show a pill without
  // fetching each bill in full.
  'memberName': (bill['member'] as Map?)?['name'],
  // How much of this bill has already gone onto a tab (ADR-0098). Live too,
  // not only in history: a split bill whose struk B was settled on account is
  // still open at struk A, and that is precisely the case a cashier misses.
  // Summed net of refunds, which ride the same list as negative amounts.
  'piutangAmount': (bill['receipts'] as List)
      .cast<Map<String, dynamic>>()
      .expand((r) => (r['payments'] as List? ?? const []))
      .cast<Map<String, dynamic>>()
      .where((p) => p['method'] == 'piutang')
      .fold<int>(0, (a, p) => a + ((p['amount'] as num?)?.toInt() ?? 0))
      .clamp(0, 1 << 31),
  // Just the letter and its paid-ness — enough for the /kasir tile's progress
  // strip, without shipping every line and payment into a list payload. See
  // ADR-0063.
  'receipts': [
    for (final r in (bill['receipts'] as List).cast<Map<String, dynamic>>())
      {'label': r['label'], 'paid': r['status'] == 'paid'},
  ],
  'mode': bill['mode'],
  'fullySettled': bill['fullySettled'],
};

Response _ok(Object body) => Response.ok(
  jsonEncode(body),
  headers: {'content-type': 'application/json'},
);

Response _err(
  int status,
  String code,
  String message, [
  Map<String, Object?> extra = const {},
]) => Response(
  status,
  body: jsonEncode({'code': code, 'message': message, ...extra}),
  headers: {'content-type': 'application/json'},
);
