import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/printing/bill_struk_builder.dart';
import 'package:satset/core/printing/bill_struk_renderer.dart';
import 'package:satset/core/printing/struk_socket.dart';
import 'package:satset/data/models/bill_dto.dart'
    show historyPageCeiling, historyPageSize;
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/server/audit_log.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/tables_routes.dart'
    show snapshotVisitAndDelete, tableJson, syncVisitMoney;
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();
const _methods = {'tunai', 'kartu', 'qris', 'transfer', 'lainnya'};

/// Two-phase settlement + split bills, keyed off the [[Visit]] (not the table)
/// so a detached unpaid bill survives the table being freed. See
/// docs/adr/0023-two-phase-settlement-and-split-bills.md, ADR-0024, and
/// CONTEXT.md (Bill / Settlement / Bill close / Split bill / Payment).
Router settlementRoutes(AppDatabase db, WsHub hub, [ServerAuth? auth]) {
  final r = Router();

  Future<User?> resolve(Request req) async {
    if (auth == null) return null;
    final token = req.headers['authorization']?.replaceFirst(
      RegExp(r'^[Bb]earer\s+'),
      '',
    );
    return auth.resolveBearer(token);
  }

  Future<List<String>> capsOf(Request req) async {
    if (auth == null) return const [];
    final user = await resolve(req);
    if (user == null) return const [];
    final role = await (db.select(
      db.roles,
    )..where((x) => x.id.equals(user.roleId))).getSingleOrNull();
    return role == null
        ? const <String>[]
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
  }

  Future<Response?> requireCap(Request req, Capability needed) async {
    if (auth == null) return null;
    final user = await resolve(req);
    if (user == null) return Response(401);
    if (!(await capsOf(req)).contains(needed.name)) {
      return _err(403, 'forbidden', 'missing capability ${needed.name}');
    }
    return null;
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
  /// Shared by the automatic Lunas close (ADR-0069) and the manual tak-tertagih
  /// write-off, because they differ only in `loss` and the audit line.
  Future<bool> performBillClose(
    Visit visit, {
    required String? actorId,
    required int loss,
    String? reason,
  }) async {
    final visitId = visit.id;
    final now = SatClock.now().toUtc();
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
      loss > 0
          ? 'Tagihan tak tertagih ${_rupiah(loss)} ${visit.tableLabel ?? ''}'
          : 'Tutup tagihan ${visit.tableLabel ?? ''}',
      tableId: visit.tableId,
      actor: actorId,
      reason: reason,
      // Only a write-off moves money; a normal close is bookkeeping, so it
      // carries no amount rather than a zero the venue log would tally.
      amountCents: loss > 0 ? loss : null,
    );
    final fresh = await _visit(db, visitId);
    final snapshotted = fresh != null && fresh.tableFreedAt != null;
    if (snapshotted) {
      await snapshotVisitAndDelete(
        db,
        hub,
        fresh,
        billClosedBy: actorId,
        lossAmount: loss,
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
    return snapshotted;
  }

  /// ADR-0069 — a bill closes itself the moment it settles. Only ever the Lunas
  /// path: a write-off has `outstanding > 0` by definition, so it can never
  /// reach here. Returns true when it closed (and therefore already broadcast).
  Future<bool> autoCloseIfSettled(String visitId, String? actorId) async {
    final v = await _visit(db, visitId);
    if (v == null || v.billClosedAt != null) return false;
    final bill = await _buildBill(db, visitId);
    if (bill == null || bill['fullySettled'] != true) return false;
    await performBillClose(v, actorId: actorId, loss: 0);
    return true;
  }

  /// Every mutation that can move a bill *towards* settled goes through this
  /// rather than [broadcastBill] — payment, assignment, split, discount. The
  /// ones that can only move it away (refund, reopen, deleting a receipt) keep
  /// the plain broadcast, so a reopen is not undone a millisecond later.
  Future<void> settleOrBroadcast(String visitId, String? actorId) async {
    if (await autoCloseIfSettled(visitId, actorId)) return;
    await broadcastBill(visitId);
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
  r.get('/settlement/visits/<visitId>/bill', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final bill = await _buildBill(db, visitId);
    if (bill == null) return _err(404, 'no_bill', 'visit has no sent lines');
    return _ok(bill);
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
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    final visit = await _visit(db, visitId);
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final mode = (body['mode'] as String?) == 'even' ? 'even' : 'itemized';
    final id = _uuid.v4();
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
      await _recompute(db, visitId);
    });
    await settleOrBroadcast(visitId, (await resolve(req))?.id);
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
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
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
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final visitId = rec.visitId ?? rec.tableId;
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    if (rec.status == 'paid') {
      return _err(
        409,
        'receipt_paid',
        'reopen the receipt before editing lines',
      );
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
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
    if (want > available) {
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
    await settleOrBroadcast(visitId, (await resolve(req))?.id);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Replace all receipts with an even N-way split of the bill total.
  r.post('/settlement/visits/<visitId>/split-even', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    final visit = await _visit(db, visitId);
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final n = ((body['n'] as num?)?.toInt() ?? 2).clamp(1, 50);
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
    if (remainder <= 0) {
      return _err(409, 'nothing_left', 'tidak ada sisa untuk dibagi');
    }
    final shares = distributeEvenRounded(remainder, n);
    // Number the new shares after any that already exist, so a second split
    // does not mint a second "Bagian 1".
    final from = existing.where((r) => r.mode == 'even').length;
    await db.transaction(() async {
      for (var i = 0; i < n; i++) {
        await db
            .into(db.receipts)
            .insert(
              ReceiptsCompanion.insert(
                id: _uuid.v4(),
                tableId: visit.tableId,
                visitId: Value(visitId),
                mode: const Value('even'),
                label: Value('Bagian ${from + i + 1}/${from + n}'),
                total: Value(shares[i]),
                createdAt: SatClock.now().toUtc(),
              ),
            );
      }
    });
    await settleOrBroadcast(visitId, (await resolve(req))?.id);
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
    if (auth == null || pin == null || pin.isEmpty) return null;
    final approver =
        await (db.select(db.users)..where(
              (u) =>
                  u.pinHash.equals(auth.hashPin(pin)) &
                  u.disabled.equals(false) &
                  u.pinHash.equals('').not(),
            ))
            .getSingleOrNull();
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

    final rec = await (db.select(
      db.receipts,
    )..where((x) => x.id.equals(receiptId))).getSingleOrNull();
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final visitId = rec.visitId;
    if (visitId == null) return _err(409, 'no_visit', 'receipt has no visit');
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    // Frozen at payment — reopen to correct a mistaken settlement (ADR-0037).
    if (rec.status == 'paid') {
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
    if (preset == null) return _err(404, 'no_preset', 'preset not found');
    if (!preset.active) {
      return _err(409, 'preset_inactive', 'preset diskon tidak aktif');
    }

    final ticketId = body['ticketId'] as String?;
    if (ticketId == null) {
      if (preset.scope != 'order') {
        return _err(409, 'scope_mismatch', 'preset ini hanya untuk satu item');
      }
    } else {
      if (preset.scope != 'line') {
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
      // A voided/comped line is not in the subtotal, so it has no base to
      // discount — and counting it in both figures would double-count the
      // give-away (ADR-0037).
      if (t.status == 'voided' || t.status == 'draft') {
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

    final existing =
        await (db.select(db.discounts)..where(
              (x) => ticketId == null
                  ? x.receiptId.equals(receiptId) & x.ticketId.isNull()
                  : x.receiptId.equals(receiptId) & x.ticketId.equals(ticketId),
            ))
            .getSingleOrNull();
    if (existing != null) {
      // No stacking (ADR-0037) — swap by removing first.
      return _err(
        409,
        'discount_exists',
        'sudah ada diskon di sana — hapus dulu untuk mengganti',
      );
    }

    final discountId = _uuid.v4();
    await db
        .into(db.discounts)
        .insert(
          DiscountsCompanion.insert(
            // Captured rather than inlined so the audit row below can read the
            // resolved rupiah back off this discount (ADR-0072).
            id: discountId,
            // Nullable since ADR-0070 — a bill-level discount has no receipt.
            receiptId: Value(receiptId),
            ticketId: Value(ticketId),
            presetId: Value(preset.id),
            // Snapshot: a later preset edit or delete must not rewrite this.
            name: preset.name,
            kind: preset.kind,
            value: Value(preset.value),
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
      'Diskon ${preset.name}${ticketId == null ? '' : ' (item)'}',
      tableId: rec.tableId,
      actor: actor?.id,
      amountCents: applied?.amount,
    );
    await settleOrBroadcast(visitId, actor?.id);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Remove a discount from a receipt. POST, not DELETE, because removal may
  // need to carry a manager step-up PIN in the body — and a PIN must never
  // ride a query string, where it would land in logs.
  r.post('/settlement/receipts/<receiptId>/discounts/<discountId>/remove', (
    Request req,
    String receiptId,
    String discountId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final rec = await (db.select(
      db.receipts,
    )..where((x) => x.id.equals(receiptId))).getSingleOrNull();
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final visitId = rec.visitId;
    if (visitId == null) return _err(409, 'no_visit', 'receipt has no visit');
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    if (rec.status == 'paid') {
      return _err(409, 'receipt_paid', 'buka ulang struk sebelum ubah diskon');
    }
    final actor = await resolve(req);
    if (!(await capsOf(req)).contains(Capability.applyDiscount.name)) {
      final body = await req.readAsString();
      final pin = body.isEmpty
          ? null
          : (jsonDecode(body) as Map<String, dynamic>)['approverPin']
                as String?;
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
              (x) => x.id.equals(discountId) & x.receiptId.equals(receiptId),
            ))
            .getSingleOrNull();
    if (row == null) return _err(404, 'no_discount', 'diskon tidak ditemukan');
    await (db.delete(db.discounts)..where((x) => x.id.equals(discountId))).go();
    await _recompute(db, visitId);
    await _audit(
      db,
      AuditType.discountRemoved,
      'Hapus diskon ${row.name}',
      tableId: rec.tableId,
      actor: actor?.id,
      amountCents: row.amount,
    );
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // BILL-SCOPE discount (ADR-0070) — a table-wide promo. Attaches to the visit
  // rather than to any receipt, which is what lets it be applied before the
  // first receipt is minted (ADR-0067). {presetId, approverPin?}.
  r.post('/settlement/visits/<visitId>/discounts', (
    Request req,
    String visitId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final visit = await _visit(db, visitId);
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;

    // A bill discount moves the bill total, and an amount receipt's claim is
    // frozen at mint time (ADR-0068) — so once any money has been taken the
    // quote a guest was given can no longer be revised silently.
    final paid = await (db.select(
      db.receipts,
    )..where((x) => x.visitId.equals(visitId) & x.status.equals('paid'))).get();
    if (paid.isNotEmpty) {
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
    if (preset == null) return _err(404, 'no_preset', 'preset not found');
    if (!preset.active) {
      return _err(409, 'preset_inactive', 'preset diskon tidak aktif');
    }
    if (preset.scope != 'bill') {
      return _err(409, 'scope_mismatch', 'preset ini bukan diskon tagihan');
    }
    if (await _billDiscount(db, visitId) != null) {
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
            id: _uuid.v4(),
            visitId: Value(visitId),
            presetId: Value(preset.id),
            // Snapshot, same as every other scope: a later preset edit must
            // not rewrite what was already given away.
            name: preset.name,
            kind: preset.kind,
            value: Value(preset.value),
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
      'Diskon tagihan ${preset.name}',
      tableId: visit.tableId,
      actor: actor?.id,
    );
    await settleOrBroadcast(visitId, actor?.id);
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
    final visit = await _visit(db, visitId);
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    final paid = await (db.select(
      db.receipts,
    )..where((x) => x.visitId.equals(visitId) & x.status.equals('paid'))).get();
    if (paid.isNotEmpty) {
      return _err(
        409,
        'receipt_paid',
        'buka ulang struk yang sudah dibayar sebelum ubah diskon tagihan',
      );
    }
    final actor = await resolve(req);
    if (!(await capsOf(req)).contains(Capability.applyDiscount.name)) {
      final raw = await req.readAsString();
      final pin = raw.isEmpty
          ? null
          : (jsonDecode(raw) as Map<String, dynamic>)['approverPin'] as String?;
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
    await (db.delete(db.discounts)..where((x) => x.id.equals(discountId))).go();
    await _recompute(db, visitId);
    await _audit(
      db,
      AuditType.discountRemoved,
      'Hapus diskon tagihan ${row.name}',
      tableId: visit.tableId,
      actor: actor?.id,
    );
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Record a payment against a receipt. {method, amount, tendered?, note?}.
  r.post('/settlement/receipts/<receiptId>/payments', (
    Request req,
    String receiptId,
  ) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final user = await resolve(req);
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final visitId = rec.visitId ?? rec.tableId;
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final method = (body['method'] as String?) ?? 'tunai';
    if (!_methods.contains(method)) {
      return _err(400, 'bad_method', 'unknown payment method');
    }
    final amount = (body['amount'] as num?)?.toInt() ?? 0;
    if (amount <= 0) return _err(400, 'bad_amount', 'amount must be positive');
    // Mandatory proof photo for any non-cash method (ADR-0025). The bytes ride
    // in this same request (base64), so payment + photo land atomically.
    final photo = _decodePhoto(body['photoBase64']);
    if (method != 'tunai' && (photo == null || photo.isEmpty)) {
      return _err(
        400,
        'photo_required',
        'foto bukti wajib untuk pembayaran non-tunai',
      );
    }
    await db.transaction(() async {
      await db
          .into(db.payments)
          .insert(
            PaymentsCompanion.insert(
              id: _uuid.v4(),
              receiptId: receiptId,
              method: method,
              amount: amount,
              tenderedAmount: Value((body['tendered'] as num?)?.toInt()),
              cashierUserId: Value(user?.id),
              note: Value((body['note'] as String?)?.trim()),
              at: SatClock.now().toUtc(),
              photo: Value(method == 'tunai' ? null : photo),
            ),
          );
      await _recompute(db, visitId);
      await _audit(
        db,
        AuditType.paymentRecorded,
        'Pembayaran ${_rupiah(amount)} ($method) ${rec.label}',
        tableId: rec.tableId,
        actor: user?.id,
        amountCents: amount,
      );
    });
    await settleOrBroadcast(visitId, user?.id);
    return _ok({'bill': await _buildBill(db, visitId)});
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

  // Record a refund (negative payment) against a receipt. Needs `refund` cap.
  r.post('/settlement/receipts/<receiptId>/refund', (
    Request req,
    String receiptId,
  ) async {
    final denied = await requireCap(req, Capability.refund);
    if (denied != null) return denied;
    final user = await resolve(req);
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final visitId = rec.visitId ?? rec.tableId;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final method = (body['method'] as String?) ?? 'tunai';
    if (!_methods.contains(method)) {
      return _err(400, 'bad_method', 'unknown refund method');
    }
    final amount = (body['amount'] as num?)?.toInt() ?? 0;
    if (amount <= 0) return _err(400, 'bad_amount', 'amount must be positive');
    await db.transaction(() async {
      await db
          .into(db.payments)
          .insert(
            PaymentsCompanion.insert(
              id: _uuid.v4(),
              receiptId: receiptId,
              method: method,
              amount: -amount,
              isRefund: const Value(true),
              cashierUserId: Value(user?.id),
              note: Value((body['note'] as String?)?.trim()),
              at: SatClock.now().toUtc(),
            ),
          );
      await _recompute(db, visitId);
      await _audit(
        db,
        AuditType.refund,
        'Refund ${_rupiah(amount)} ($method) ${rec.label}',
        tableId: rec.tableId,
        actor: user?.id,
        reason: (body['note'] as String?)?.trim(),
        // The payment row stores this negative; the audit column is a
        // magnitude, so the sign is dropped here deliberately.
        amountCents: amount,
      );
    });
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
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
    final data = BillStrukBuilder.fromServerMap(
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
      final bytes = await BillStrukRenderer.render(data);
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
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final visitId = rec.visitId ?? rec.tableId;
    await db.transaction(() async {
      await (db.delete(
        db.payments,
      )..where((x) => x.receiptId.equals(receiptId))).go();
      await _recompute(db, visitId);
      await _audit(
        db,
        AuditType.billReopened,
        'Buka ulang ${rec.label}',
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
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
    if (visit.billClosedAt != null) {
      return _err(409, 'already_closed', 'tagihan sudah ditutup');
    }
    final bill = await _buildBill(db, visitId);
    if (bill == null) return _err(409, 'no_lines', 'tidak ada pesanan');
    final raw = await req.readAsString();
    final body = raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final writeOff = body['writeOff'] == true;
    final outstanding = bill['outstanding'] as int;
    final fullyAssigned = bill['fullyAssigned'] == true;
    if (!writeOff) {
      // Since ADR-0069 a settled bill has already closed itself, so reaching
      // here on the Lunas path means it is not settled. Kept as a route for
      // the client that races the auto-close, not as a step in the flow.
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
    if (visit == null) return _err(404, 'no_visit', 'visit not found');
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
    await _audit(
      db,
      AuditType.billReopened,
      'Buka ulang tagihan ${visit.tableLabel ?? ''}',
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
    final cutoff = SatClock.now().toUtc().subtract(Duration(days: days));

    final q = db.select(db.tableSessions)
      ..where((s) => s.closedAt.isBiggerThanValue(cutoff))
      ..orderBy([(s) => OrderingTerm.desc(s.closedAt)])
      ..limit(limit);
    if (scoped) q.where((s) => s.tableId.equals(tableId));
    final sessions = await q.get();

    // Same WHERE, no limit. Counted rather than derived from `sessions`, which
    // is exactly `limit` long once the window is fuller than a page.
    final countCol = db.tableSessions.id.count();
    final cq = db.selectOnly(db.tableSessions)..addColumns([countCol]);
    cq.where(db.tableSessions.closedAt.isBiggerThanValue(cutoff));
    if (scoped) cq.where(db.tableSessions.tableId.equals(tableId));
    final total = (await cq.getSingle()).read(countCol) ?? 0;

    return _ok({
      'total': total,
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

Future<Receipt?> _receipt(AppDatabase db, String id) =>
    (db.select(db.receipts)..where((x) => x.id.equals(id))).getSingleOrNull();

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

Future<TaxServiceConfig> _config(AppDatabase db) async {
  final s = await (db.select(
    db.venueSettings,
  )..where((x) => x.id.equals('default'))).getSingleOrNull();
  return TaxServiceConfig(
    taxEnabled: s?.taxEnabled ?? false,
    taxRateBps: s?.taxRateBps ?? 1100,
    serviceEnabled: s?.serviceEnabled ?? false,
    serviceMode: s?.serviceMode ?? 'percent',
    serviceRateBps: s?.serviceRateBps ?? 500,
    serviceFixedAmount: s?.serviceFixedAmount ?? 0,
    taxAfterDiscount: s?.taxAfterDiscount ?? true,
  );
}

/// Re-resolve a live [[Diskon (discount)]] row's rupiah [amount] from its
/// snapshotted `kind`/`value` against the CURRENT [base], persisting the
/// result. The snapshot rule (ADR-0037) freezes `name`/`kind`/`value` so a
/// preset edit never rewrites history — but `amount` is *derived*, and while a
/// receipt is still live its base moves as lines are assigned and reassigned.
/// Leaving a stale amount would silently turn a 10% discount into 20% when a
/// line moves away. Frozen for good at bill close, into `tableSessionDiscounts`.
Future<int> _resolveDiscountRow(AppDatabase db, Discount d, int base) async {
  final amount = resolveDiscountAmount(
    kind: d.kind,
    value: d.value,
    base: base,
  );
  if (amount != d.amount) {
    await (db.update(db.discounts)..where((x) => x.id.equals(d.id))).write(
      DiscountsCompanion(amount: Value(amount)),
    );
  }
  return amount;
}

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

/// Recompute every itemized receipt's money + paid status for a visit.
Future<void> _recompute(AppDatabase db, String visitId) async {
  final cfg = await _config(db);
  final recs = await (db.select(
    db.receipts,
  )..where((x) => x.visitId.equals(visitId))).get();
  final tickets = {for (final t in await _sentTickets(db, visitId)) t.id: t};

  final byReceipt = await _discountsByReceipt(db, recs.map((r) => r.id));

  final itemized = recs.where((r) => r.mode != 'even').toList();
  final subtotals = <int>[]; // net of line discounts (ADR-0038)
  final lineDiscounts = <int>[];
  final orderDiscounts = <int>[];
  for (final rec in itemized) {
    final lines = await (db.select(
      db.receiptLines,
    )..where((x) => x.receiptId.equals(rec.id))).get();
    final units = <String, int>{};
    var gross = 0;
    for (final l in lines) {
      final t = tickets[l.ticketId];
      if (t != null) {
        gross += t.price * l.qtyUnits;
        units[l.ticketId] = (units[l.ticketId] ?? 0) + l.qtyUnits;
      }
    }
    final ds = byReceipt[rec.id] ?? const <Discount>[];
    // A line discount's base is the value of the units THIS receipt owns.
    var lineDisc = 0;
    for (final d in ds.where((d) => d.ticketId != null)) {
      final t = tickets[d.ticketId];
      final base = t == null ? 0 : t.price * (units[d.ticketId] ?? 0);
      lineDisc += await _resolveDiscountRow(db, d, base);
    }
    final net = gross - lineDisc;
    // The order discount's base is the subtotal already net of line discounts
    // — line-then-order (ADR-0038).
    var orderDisc = 0;
    for (final d in ds.where((d) => d.ticketId == null)) {
      orderDisc += await _resolveDiscountRow(db, d, net);
    }
    subtotals.add(net);
    lineDiscounts.add(lineDisc);
    orderDiscounts.add(orderDisc);
  }
  final billSub = tickets.values.fold<int>(0, (a, t) => a + t.price * t.qty);
  final assignedSub =
      subtotals.fold<int>(0, (a, b) => a + b) + _sum(lineDiscounts);
  final allUnitsAssigned = await _fullyAssigned(db, tickets.values);
  // A bill-scope discount belongs to the visit, so it has to be fanned out
  // across the itemized receipts before they can each be totalled — same job
  // `distributeFixed` does for a fixed service charge. Amount receipts are
  // excluded on purpose: their claim was frozen at mint time (ADR-0068), and a
  // discount applied afterwards must not silently re-quote a guest.
  final billDiscRow = await _billDiscount(db, visitId);
  final billDiscAmount = billDiscRow == null
      ? 0
      : await _resolveDiscountRow(
          db,
          billDiscRow,
          billSub - _sum(lineDiscounts),
        );
  if (billDiscAmount > 0 && itemized.isNotEmpty) {
    final fanned = distributeFixed(subtotals, billDiscAmount);
    for (var i = 0; i < itemized.length; i++) {
      orderDiscounts[i] += fanned[i];
    }
  }
  // Whatever the amount receipts already claim is not the itemized side's to
  // account for, so it comes off the target they have to hit.
  final amountClaim = recs
      .where((r) => r.mode == 'even')
      .fold<int>(0, (a, r) => a + r.total);
  final billTotal = allUnitsAssigned
      ? computeBreakdown(
              billSub - _sum(lineDiscounts),
              cfg,
              discount: _sum(orderDiscounts),
            ).total -
            amountClaim
      : null;
  final breakdowns = splitItemized(
    subtotals,
    cfg,
    billTotalTarget: (assignedSub == billSub) ? billTotal : null,
    discounts: orderDiscounts,
  );

  for (var i = 0; i < itemized.length; i++) {
    final rec = itemized[i];
    final b = breakdowns[i];
    final paid = await _paidNet(db, rec.id);
    await (db.update(db.receipts)..where((x) => x.id.equals(rec.id))).write(
      ReceiptsCompanion(
        subtotal: Value(b.subtotal),
        // Reporting figure: line discounts (already inside subtotal) plus the
        // whole-order one actually applied after clamping.
        discountAmount: Value(lineDiscounts[i] + b.discountAmount),
        serviceAmount: Value(b.serviceAmount),
        taxAmount: Value(b.taxAmount),
        total: Value(b.total),
        status: Value(b.total > 0 && paid >= b.total ? 'paid' : 'unpaid'),
      ),
    );
  }
  for (final rec in recs.where((r) => r.mode == 'even')) {
    final paid = await _paidNet(db, rec.id);
    await (db.update(db.receipts)..where((x) => x.id.equals(rec.id))).write(
      ReceiptsCompanion(
        status: Value(rec.total > 0 && paid >= rec.total ? 'paid' : 'unpaid'),
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

int _sum(Iterable<int> xs) => xs.fold<int>(0, (a, b) => a + b);

Map<String, dynamic> _discountJson(Discount d) => {
  'id': d.id,
  'ticketId': d.ticketId, // null ⇒ whole-order discount
  'presetId': d.presetId,
  'name': d.name,
  'kind': d.kind,
  'value': d.value,
  'amount': d.amount,
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

Future<bool> _fullyAssigned(AppDatabase db, Iterable<Ticket> tickets) async {
  for (final t in tickets) {
    if (await _assignedUnits(db, t.id) < t.qty) return false;
  }
  return true;
}

Future<void> _audit(
  AppDatabase db,
  AuditType type,
  String title, {
  required String tableId,
  String? actor,
  String? reason,
  int? amountCents,
}) => writeAudit(
  db,
  type: type,
  title: title,
  tableId: tableId,
  actorUserId: actor,
  reason: reason,
  amountCents: amountCents,
);

/// Build the full bill JSON for one visit, or null if it has no sent lines.
Future<Map<String, dynamic>?> _buildBill(AppDatabase db, String visitId) async {
  final visit = await _visit(db, visitId);
  if (visit == null) return null;
  final tickets = await _sentTickets(db, visitId);
  if (tickets.isEmpty) return null;
  final cfg = await _config(db);
  final billSub = tickets.fold<int>(0, (a, t) => a + t.price * t.qty);

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
  final allDiscounts = byReceipt.values.expand((x) => x);
  final billLineDiscount = _sum(
    allDiscounts.where((d) => d.ticketId != null).map((d) => d.amount),
  );
  final billOrderDiscount = _sum(
    allDiscounts.where((d) => d.ticketId == null).map((d) => d.amount),
  );
  // The bill-scope discount (ADR-0070) belongs to the visit, not to any
  // receipt, so it is fetched separately and lands in the same slot an order
  // discount does — same position in the ADR-0038 stack, different owner.
  final billDisc = await _billDiscount(db, visitId);
  final billBreak = computeBreakdown(
    billSub - billLineDiscount,
    cfg,
    discount: billOrderDiscount + (billDisc?.amount ?? 0),
  );

  var paidNet = 0;
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
                db.payments.tenderedAmount,
                db.payments.cashierUserId,
                db.payments.note,
                db.payments.at,
                payPhoto,
              ])
              ..where(db.payments.receiptId.equals(rec.id)))
            .get();
    final recPaid = pays.fold<int>(
      0,
      (a, p) => a + p.read(db.payments.amount)!,
    );
    paidNet += recPaid;
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
      // Individual rows, not just the total — the money doc prints a NAMED
      // "Diskon <preset>" and line discounts render under their item.
      'discounts': [
        for (final d in (byReceipt[rec.id] ?? const <Discount>[]))
          _discountJson(d),
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
      'modifiersJson': t.modifiersJson,
      'sentAt': t.sentAt.toIso8601String(),
    });
  }
  final allUnitsAssigned = linesJson.every(
    (l) => (l['assignedUnits'] as int) >= (l['qty'] as int),
  );
  // Gates whether the bill closes itself (ADR-0069), so it lives in
  // `bill_math` as a named pure function with its own test rather than as an
  // expression here. See [isFullyAssigned].
  final fullyAssigned = isFullyAssigned(
    hasReceipts: recs.isNotEmpty,
    allUnitsAssigned: allUnitsAssigned,
    receiptsClaim: recs.fold<int>(0, (a, r) => a + r.total),
    billTotal: billBreak.total,
  );
  final allReceiptsPaid =
      recs.isNotEmpty && recs.every((r) => r.status == 'paid');
  final outstanding = (billBreak.total - paidNet).clamp(0, 1 << 31);
  final detached = visit.tableFreedAt != null;

  return {
    'visitId': visit.id,
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
    'total': billBreak.total,
    'paidAmount': paidNet,
    'outstanding': outstanding,
    'fullyAssigned': fullyAssigned,
    'fullySettled': fullyAssigned && allReceiptsPaid,
    // The bill-scope discount row, so the totals ladder and the printed slip
    // can name it. Receipt-scoped rows still ride on their receipt. ADR-0070.
    'billDiscount': billDisc == null ? null : _discountJson(billDisc),
    'lines': linesJson,
    'receipts': receiptsJson,
  };
}

/// The one bill-scope [[Diskon (discount)]] on a visit, or null. At most one by
/// the `idx_discounts_bill_uniq` partial index. ADR-0070.
Future<Discount?> _billDiscount(AppDatabase db, String visitId) =>
    (db.select(db.discounts)..where(
          (x) => x.visitId.equals(visitId) & x.receiptId.isNull(),
        ))
        .getSingleOrNull();

/// Reconstruct a bill-shaped map for a CLOSED session (past bill), from the
/// snapshot tables — for the Struk pembayaran detail view.
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
  var paidNet = 0;
  final receiptsJson = <Map<String, dynamic>>[];
  for (final rec in srec) {
    final pays = spay
        .where(
          (p) => p.read(db.tableSessionPayments.receiptId) == rec.receiptId,
        )
        .toList();
    final recPaid = pays.fold<int>(
      0,
      (a, p) => a + p.read(db.tableSessionPayments.amount)!,
    );
    paidNet += recPaid;
    receiptsJson.add({
      'id': rec.receiptId,
      'mode': rec.mode,
      'label': rec.label,
      'subtotal': rec.subtotal,
      'serviceAmount': rec.serviceAmount,
      'taxAmount': rec.taxAmount,
      'total': rec.total,
      'status': rec.status,
      'paidNet': recPaid,
      'lines': const [],
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
        'assignedUnits': t.qty,
        'note': t.note,
        'status': t.status,
        'modifiersJson': t.modifiersJson,
        'sentAt': t.sentAt.toIso8601String(),
      },
  ];
  return {
    'sessionId': s.id,
    'tableId': s.tableId,
    'tableLabel': s.tableLabel,
    'status': 'closed',
    'closedAt': s.closedAt.toIso8601String(),
    'pax': s.pax,
    'mode': srec.any((r) => r.mode == 'even') ? 'even' : 'itemized',
    'subtotal': s.subtotal,
    'serviceAmount': s.serviceAmount,
    'taxAmount': s.taxAmount,
    'total': s.settledTotal,
    'paidAmount': paidNet,
    'outstanding': (s.settledTotal - paidNet).clamp(0, 1 << 31),
    'lossAmount': s.lossAmount,
    'lines': linesJson,
    'receipts': receiptsJson,
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
  'billDiscountLabel': (bill['billDiscount'] as Map?)?['name'],
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

String _rupiah(int n) => 'Rp${n.toString()}';

Response _ok(Object body) => Response.ok(
  jsonEncode(body),
  headers: {'content-type': 'application/json'},
);

Response _err(int status, String code, String message) => Response(
  status,
  body: jsonEncode({'code': code, 'message': message}),
  headers: {'content-type': 'application/json'},
);
