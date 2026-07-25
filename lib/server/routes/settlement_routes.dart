import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/printing/bill_struk_builder.dart';
import 'package:satset/core/printing/bill_struk_renderer.dart';
import 'package:satset/core/printing/struk_socket.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
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
    final token = req.headers['authorization']
        ?.replaceFirst(RegExp(r'^[Bb]earer\s+'), '');
    return auth.resolveBearer(token);
  }

  Future<List<String>> capsOf(Request req) async {
    if (auth == null) return const [];
    final user = await resolve(req);
    if (user == null) return const [];
    final role = await (db.select(db.roles)
          ..where((x) => x.id.equals(user.roleId)))
        .getSingleOrNull();
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

  /// Reject mutations on a bill the cashier already locked (bill-closed but the
  /// table not yet freed — the "lingering" state). Reopen first to correct.
  Future<Response?> lockGuard(String visitId) async {
    final v = await _visit(db, visitId);
    if (v != null && v.billClosedAt != null) {
      return _err(409, 'bill_locked', 'tagihan sudah ditutup — buka ulang dulu');
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
  r.get('/settlement/visits/<visitId>/bill', (Request req, String visitId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final bill = await _buildBill(db, visitId);
    if (bill == null) return _err(404, 'no_bill', 'visit has no sent lines');
    return _ok(bill);
  });

  // Create a receipt. {mode: itemized|even, label?, assignAll?: bool}.
  r.post('/settlement/visits/<visitId>/receipts',
      (Request req, String visitId) async {
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
      await db.into(db.receipts).insert(ReceiptsCompanion.insert(
            id: id,
            tableId: visit.tableId,
            visitId: Value(visitId),
            mode: Value(mode),
            label: Value((body['label'] as String?)?.trim() ?? ''),
            createdAt: DateTime.now().toUtc(),
          ));
      if (body['assignAll'] == true) {
        await _assignAllUnassigned(db, visitId, id);
      }
      await _recompute(db, visitId);
    });
    await broadcastBill(visitId);
    return _ok({'receiptId': id, 'bill': await _buildBill(db, visitId)});
  });

  // Delete an unpaid receipt; its line assignments are released.
  r.delete('/settlement/receipts/<receiptId>',
      (Request req, String receiptId) async {
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
      await (db.delete(db.receiptLines)
            ..where((x) => x.receiptId.equals(receiptId)))
          .go();
      await (db.delete(db.payments)..where((x) => x.receiptId.equals(receiptId)))
          .go();
      await (db.delete(db.discounts)
            ..where((x) => x.receiptId.equals(receiptId)))
          .go();
      await (db.delete(db.receipts)..where((x) => x.id.equals(receiptId))).go();
      await _recompute(db, visitId);
    });
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Assign qty units of a sent ticket to a receipt (qty-level). {ticketId, qtyUnits}.
  r.post('/settlement/receipts/<receiptId>/lines',
      (Request req, String receiptId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final visitId = rec.visitId ?? rec.tableId;
    final locked = await lockGuard(visitId);
    if (locked != null) return locked;
    if (rec.status == 'paid') {
      return _err(409, 'receipt_paid', 'reopen the receipt before editing lines');
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final ticketId = body['ticketId'] as String;
    final want = ((body['qtyUnits'] as num?)?.toInt() ?? 1).clamp(0, 1 << 30);
    final ticket = await (db.select(db.tickets)
          ..where((x) => x.id.equals(ticketId)))
        .getSingleOrNull();
    if (ticket == null || (ticket.visitId ?? ticket.tableId) != visitId) {
      return _err(404, 'no_ticket', 'ticket not on this bill');
    }
    final assignedElsewhere = await _assignedUnits(db, ticketId, exclude: receiptId);
    final available = ticket.qty - assignedElsewhere;
    if (want > available) {
      return _err(409, 'over_assign',
          'only $available unit(s) of this line are unassigned');
    }
    await db.transaction(() async {
      await (db.delete(db.receiptLines)
            ..where((x) =>
                x.receiptId.equals(receiptId) & x.ticketId.equals(ticketId)))
          .go();
      if (want > 0) {
        await db.into(db.receiptLines).insert(ReceiptLinesCompanion.insert(
              id: _uuid.v4(),
              receiptId: receiptId,
              ticketId: ticketId,
              qtyUnits: Value(want),
            ));
      }
      await _recompute(db, visitId);
    });
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Replace all receipts with an even N-way split of the bill total.
  r.post('/settlement/visits/<visitId>/split-even',
      (Request req, String visitId) async {
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
    final paid = await (db.select(db.receipts)
          ..where((x) => x.visitId.equals(visitId) & x.status.equals('paid')))
        .get();
    if (paid.isNotEmpty) {
      return _err(409, 'receipt_paid', 'reopen paid receipts before re-splitting');
    }
    final total = bill['total'] as int;
    final shares = distributeEven(total, n);
    await db.transaction(() async {
      await _clearReceipts(db, visitId);
      for (var i = 0; i < n; i++) {
        await db.into(db.receipts).insert(ReceiptsCompanion.insert(
              id: _uuid.v4(),
              tableId: visit.tableId,
              visitId: Value(visitId),
              mode: const Value('even'),
              label: Value('Bagian ${i + 1}/$n'),
              total: Value(shares[i]),
              createdAt: DateTime.now().toUtc(),
            ));
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
    if (auth == null || pin == null || pin.isEmpty) return null;
    final approver = await (db.select(db.users)
          ..where((u) =>
              u.pinHash.equals(auth.hashPin(pin)) &
              u.disabled.equals(false) &
              u.pinHash.equals('').not()))
        .getSingleOrNull();
    if (approver == null) return null;
    final role = await (db.select(db.roles)
          ..where((x) => x.id.equals(approver.roleId)))
        .getSingleOrNull();
    final caps = role == null
        ? const <String>[]
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
    return caps.contains(Capability.applyDiscount.name) ? approver.id : null;
  }

  // Apply a discount to a receipt. {presetId, ticketId?, approverPin?}.
  // `ticketId` null ⇒ whole-order discount; set ⇒ line discount. The cashier
  // picks a preset — never a free-typed rate (ADR-0037).
  r.post('/settlement/receipts/<receiptId>/discounts',
      (Request req, String receiptId) async {
    // settleBill gates the money screen itself; applyDiscount (or a manager
    // step-up) gates this act specifically.
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;

    final rec = await (db.select(db.receipts)
          ..where((x) => x.id.equals(receiptId)))
        .getSingleOrNull();
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
        return _err(403, 'approval_required',
            'butuh persetujuan manajer untuk memberi diskon');
      }
    }

    final preset = await (db.select(db.discountPresets)
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
        return _err(
            409, 'scope_mismatch', 'preset ini untuk seluruh pesanan');
      }
      // Even receipts own no lines, so a line discount has nothing to attach
      // to — even mode has already abandoned tracking who ordered what.
      if (rec.mode == 'even') {
        return _err(409, 'even_mode',
            'diskon per item hanya untuk struk itemized');
      }
      final t = await (db.select(db.tickets)
            ..where((x) => x.id.equals(ticketId)))
          .getSingleOrNull();
      if (t == null) return _err(404, 'no_ticket', 'line not found');
      // A voided/comped line is not in the subtotal, so it has no base to
      // discount — and counting it in both figures would double-count the
      // give-away (ADR-0037).
      if (t.status == 'voided' || t.status == 'draft') {
        return _err(409, 'line_voided', 'item sudah dibatalkan');
      }
      final owns = await (db.select(db.receiptLines)
            ..where((x) =>
                x.receiptId.equals(receiptId) & x.ticketId.equals(ticketId)))
          .get();
      if (owns.isEmpty) {
        return _err(409, 'line_not_on_receipt',
            'item ini tidak ada di struk tersebut');
      }
    }

    final existing = await (db.select(db.discounts)
          ..where((x) => ticketId == null
              ? x.receiptId.equals(receiptId) & x.ticketId.isNull()
              : x.receiptId.equals(receiptId) &
                  x.ticketId.equals(ticketId)))
        .getSingleOrNull();
    if (existing != null) {
      // No stacking (ADR-0037) — swap by removing first.
      return _err(409, 'discount_exists',
          'sudah ada diskon di sana — hapus dulu untuk mengganti');
    }

    await db.into(db.discounts).insert(DiscountsCompanion.insert(
          id: _uuid.v4(),
          receiptId: receiptId,
          ticketId: Value(ticketId),
          presetId: Value(preset.id),
          // Snapshot: a later preset edit or delete must not rewrite this.
          name: preset.name,
          kind: preset.kind,
          value: Value(preset.value),
          byUserId: Value(actor?.id),
          approvedByUserId: Value(approvedBy),
          at: DateTime.now().toUtc(),
        ));
    // _recompute resolves the rupiah amount against the current base.
    await _recompute(db, visitId);
    await _audit(db, AuditType.discountApplied,
        'Diskon ${preset.name}${ticketId == null ? '' : ' (item)'}',
        tableId: rec.tableId, actor: actor?.id);
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Remove a discount from a receipt. POST, not DELETE, because removal may
  // need to carry a manager step-up PIN in the body — and a PIN must never
  // ride a query string, where it would land in logs.
  r.post('/settlement/receipts/<receiptId>/discounts/<discountId>/remove',
      (Request req, String receiptId, String discountId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final rec = await (db.select(db.receipts)
          ..where((x) => x.id.equals(receiptId)))
        .getSingleOrNull();
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
        return _err(403, 'approval_required',
            'butuh persetujuan manajer untuk mengubah diskon');
      }
    }
    final row = await (db.select(db.discounts)
          ..where((x) => x.id.equals(discountId) &
              x.receiptId.equals(receiptId)))
        .getSingleOrNull();
    if (row == null) return _err(404, 'no_discount', 'diskon tidak ditemukan');
    await (db.delete(db.discounts)..where((x) => x.id.equals(discountId))).go();
    await _recompute(db, visitId);
    await _audit(db, AuditType.discountRemoved, 'Hapus diskon ${row.name}',
        tableId: rec.tableId, actor: actor?.id);
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Record a payment against a receipt. {method, amount, tendered?, note?}.
  r.post('/settlement/receipts/<receiptId>/payments',
      (Request req, String receiptId) async {
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
      return _err(400, 'photo_required',
          'foto bukti wajib untuk pembayaran non-tunai');
    }
    await db.transaction(() async {
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            id: _uuid.v4(),
            receiptId: receiptId,
            method: method,
            amount: amount,
            tenderedAmount: Value((body['tendered'] as num?)?.toInt()),
            cashierUserId: Value(user?.id),
            note: Value((body['note'] as String?)?.trim()),
            at: DateTime.now().toUtc(),
            photo: Value(method == 'tunai' ? null : photo),
          ));
      await _recompute(db, visitId);
      await _audit(db, AuditType.paymentRecorded,
          'Pembayaran ${_rupiah(amount)} ($method) ${rec.label}',
          tableId: rec.tableId, actor: user?.id);
    });
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Proof-photo bytes for a LIVE payment (open bill). Kept OUT of the bill JSON
  // (blob never rides the list path); fetched on demand, pinned. See ADR-0025.
  r.get('/settlement/payments/<id>/photo', (Request req, String id) async {
    final row = await (db.select(db.payments)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    if (row == null || row.photo == null) return Response.notFound('no photo');
    return Response.ok(row.photo, headers: {
      'content-type': 'image/jpeg',
      'cache-control': 'no-cache',
    });
  });

  // Proof-photo bytes for a CLOSED (snapshotted) payment — past bills / report.
  r.get('/settlement/history/payments/<id>/photo',
      (Request req, String id) async {
    final row = await (db.select(db.tableSessionPayments)
          ..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    if (row == null || row.photo == null) return Response.notFound('no photo');
    return Response.ok(row.photo, headers: {
      'content-type': 'image/jpeg',
      'cache-control': 'no-cache',
    });
  });

  // Record a refund (negative payment) against a receipt. Needs `refund` cap.
  r.post('/settlement/receipts/<receiptId>/refund',
      (Request req, String receiptId) async {
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
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            id: _uuid.v4(),
            receiptId: receiptId,
            method: method,
            amount: -amount,
            isRefund: const Value(true),
            cashierUserId: Value(user?.id),
            note: Value((body['note'] as String?)?.trim()),
            at: DateTime.now().toUtc(),
          ));
      await _recompute(db, visitId);
      await _audit(db, AuditType.refund,
          'Refund ${_rupiah(amount)} ($method) ${rec.label}',
          tableId: rec.tableId, actor: user?.id,
          reason: (body['note'] as String?)?.trim());
    });
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // Render + send the MONEY document to a VENUE printer (server-rendered).
  Future<Response> printDoc(
      Map<String, dynamic> bill, String? receiptId, String? printerId) async {
    if (printerId == null || printerId.isEmpty) {
      return _err(400, 'bad_request', 'printerId required');
    }
    final printer = await (db.select(db.printers)
          ..where((p) => p.id.equals(printerId)))
        .getSingleOrNull();
    if (printer == null) return _err(404, 'no_printer', 'printer not found');
    final v = await (db.select(db.venueSettings)
          ..where((x) => x.id.equals('default')))
        .getSingleOrNull();
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
      SatLog.srv('bill print fail printer=$printerId '
          '${printer.host}:${printer.port} $e');
      return _err(502, 'print_failed', 'printer tak terhubung');
    }
    final now = DateTime.now();
    await (db.update(db.printers)..where((p) => p.id.equals(printerId)))
        .write(PrintersCompanion(lastSeenAt: Value(now)));
    final updated = await (db.select(db.printers)
          ..where((p) => p.id.equals(printerId)))
        .getSingleOrNull();
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
  r.post('/settlement/visits/<visitId>/bill/print',
      (Request req, String visitId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final bill = await _buildBill(db, visitId);
    if (bill == null) return _err(409, 'no_lines', 'tidak ada pesanan');
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    return printDoc(bill, null, body['printerId'] as String?);
  });

  // Print one receipt's Tagihan / Struk pembayaran. {printerId}.
  r.post('/settlement/receipts/<receiptId>/print',
      (Request req, String receiptId) async {
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
  r.post('/settlement/receipts/<receiptId>/reopen',
      (Request req, String receiptId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final user = await resolve(req);
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final visitId = rec.visitId ?? rec.tableId;
    await db.transaction(() async {
      await (db.delete(db.payments)..where((x) => x.receiptId.equals(receiptId)))
          .go();
      await _recompute(db, visitId);
      await _audit(db, AuditType.billReopened, 'Buka ulang ${rec.label}',
          tableId: rec.tableId, actor: user?.id);
    });
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // BILL CLOSE (cashier): lock the bill + (when the table is already freed)
  // snapshot the visit into history. {writeOff?: bool, reason?}. Lunas requires
  // outstanding == 0; tak-tertagih (write-off) needs the `refund` cap + reason
  // and records lossAmount = outstanding. See ADR-0024.
  r.post('/settlement/visits/<visitId>/bill-close',
      (Request req, String visitId) async {
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
      if (outstanding > 0 || !fullyAssigned) {
        return _err(409, 'not_settled',
            'tagihan belum lunas — gunakan tak tertagih untuk menutup');
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
    final now = DateTime.now().toUtc();
    await (db.update(db.visits)..where((v) => v.id.equals(visitId))).write(
      VisitsCompanion(
        billClosedAt: Value(now),
        billClosedBy: Value(user?.id),
        lossAmount: Value(loss),
      ),
    );
    await _audit(
        db,
        AuditType.billClosed,
        writeOff
            ? 'Tagihan tak tertagih ${_rupiah(loss)} ${visit.tableLabel ?? ''}'
            : 'Tutup tagihan ${visit.tableLabel ?? ''}',
        tableId: visit.tableId,
        actor: user?.id,
        reason: writeOff ? (body['reason'] as String?)?.trim() : null);
    // Second axis? If the table was already freed, this completes the visit.
    final fresh = await _visit(db, visitId);
    if (fresh != null && fresh.tableFreedAt != null) {
      await snapshotVisitAndDelete(db, hub, fresh,
          billClosedBy: user?.id, lossAmount: loss);
    } else {
      // Locked while the table is still occupied — mirror onto the table row
      // so the floor shows a Lunas pill. Snapshot defers to table-close.
      final tbl = await (db.select(db.venueTables)
            ..where((t) => t.currentVisitId.equals(visitId)))
          .getSingleOrNull();
      if (tbl != null) {
        await (db.update(db.venueTables)..where((t) => t.id.equals(tbl.id)))
            .write(VenueTablesCompanion(billClosedAt: Value(now)));
        final fresh2 = await (db.select(db.venueTables)
              ..where((t) => t.id.equals(tbl.id)))
            .getSingleOrNull();
        if (fresh2 != null) {
          hub.broadcast(WsEventTypes.tableUpdated, tableJson(fresh2));
        }
      }
      hub.broadcast(
          WsEventTypes.billUpdated, {'visitId': visitId, 'billClosed': true});
    }
    return _ok({'closed': true, 'snapshotted': fresh?.tableFreedAt != null});
  });

  // Reopen (unlock) a bill-closed-but-not-yet-snapshotted bill, to correct it.
  r.post('/settlement/visits/<visitId>/reopen',
      (Request req, String visitId) async {
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
    final tbl = await (db.select(db.venueTables)
          ..where((t) => t.currentVisitId.equals(visitId)))
        .getSingleOrNull();
    if (tbl != null) {
      await (db.update(db.venueTables)..where((t) => t.id.equals(tbl.id)))
          .write(const VenueTablesCompanion(billClosedAt: Value(null)));
      final fresh = await (db.select(db.venueTables)
            ..where((t) => t.id.equals(tbl.id)))
          .getSingleOrNull();
      if (fresh != null) hub.broadcast(WsEventTypes.tableUpdated, tableJson(fresh));
    }
    await _audit(db, AuditType.billReopened,
        'Buka ulang tagihan ${visit.tableLabel ?? ''}',
        tableId: visit.tableId, actor: user?.id);
    await broadcastBill(visitId);
    return _ok({'bill': await _buildBill(db, visitId)});
  });

  // PAST BILLS (cashier history): closed bills across the venue, capped to the
  // last `days` (default 7), newest-first. An optional ?tableId scopes to one
  // physical table (the bill-screen Riwayat shortcut); absent ⇒ venue-wide (the
  // cashier's Riwayat tab). Sourced from snapshotted TableSessions. The 7-day
  // cap is only this view's window — sessions persist longer for reports.
  r.get('/settlement/history', (Request req) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final days = int.tryParse(req.url.queryParameters['days'] ?? '7') ?? 7;
    final tableId = req.url.queryParameters['tableId'];
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: days));
    final q = db.select(db.tableSessions)
      ..where((s) => s.closedAt.isBiggerThanValue(cutoff))
      ..orderBy([(s) => OrderingTerm.desc(s.closedAt)]);
    if (tableId != null && tableId.isNotEmpty) {
      q.where((s) => s.tableId.equals(tableId));
    }
    final sessions = await q.get();
    return _ok([
      for (final s in sessions)
        {
          'sessionId': s.id,
          'tableId': s.tableId,
          'tableLabel': s.tableLabel,
          'kind': s.kind,
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
        }
    ]);
  });

  // One past bill's detail (Struk pembayaran view) reconstructed from the
  // session snapshot tables.
  r.get('/settlement/sessions/<sessionId>/bill',
      (Request req, String sessionId) async {
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

Future<int> _assignedUnits(AppDatabase db, String ticketId,
    {String? exclude}) async {
  final rows = await (db.select(db.receiptLines)
        ..where((x) => x.ticketId.equals(ticketId)))
      .get();
  var sum = 0;
  for (final l in rows) {
    if (exclude != null && l.receiptId == exclude) continue;
    sum += l.qtyUnits;
  }
  return sum;
}

Future<void> _assignAllUnassigned(
    AppDatabase db, String visitId, String receiptId) async {
  final tickets = await _sentTickets(db, visitId);
  for (final t in tickets) {
    final assigned = await _assignedUnits(db, t.id);
    final free = t.qty - assigned;
    if (free > 0) {
      await db.into(db.receiptLines).insert(ReceiptLinesCompanion.insert(
            id: _uuid.v4(),
            receiptId: receiptId,
            ticketId: t.id,
            qtyUnits: Value(free),
          ));
    }
  }
}

/// Tear down every receipt on a visit — used when re-splitting. Discount rows
/// go with their receipt: this is how switching to an even split disposes of
/// line discounts, which even receipts cannot carry (ADR-0037). The cashier is
/// warned before this runs.
Future<void> _clearReceipts(AppDatabase db, String visitId) async {
  final recs = await (db.select(db.receipts)
        ..where((x) => x.visitId.equals(visitId)))
      .get();
  for (final rec in recs) {
    await (db.delete(db.receiptLines)..where((x) => x.receiptId.equals(rec.id)))
        .go();
    await (db.delete(db.payments)..where((x) => x.receiptId.equals(rec.id)))
        .go();
    await (db.delete(db.discounts)..where((x) => x.receiptId.equals(rec.id)))
        .go();
  }
  await (db.delete(db.receipts)..where((x) => x.visitId.equals(visitId))).go();
}

Future<List<Ticket>> _sentTickets(AppDatabase db, String visitId) async {
  final rows = await (db.select(db.tickets)
        ..where((x) => x.visitId.equals(visitId)))
      .get();
  return rows
      .where((t) => t.status != 'voided' && t.status != 'draft')
      .toList();
}

Future<TaxServiceConfig> _config(AppDatabase db) async {
  final s = await (db.select(db.venueSettings)
        ..where((x) => x.id.equals('default')))
      .getSingleOrNull();
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
Future<int> _resolveDiscountRow(
    AppDatabase db, Discount d, int base) async {
  final amount =
      resolveDiscountAmount(kind: d.kind, value: d.value, base: base);
  if (amount != d.amount) {
    await (db.update(db.discounts)..where((x) => x.id.equals(d.id)))
        .write(DiscountsCompanion(amount: Value(amount)));
  }
  return amount;
}

/// Every discount row on a visit's receipts, grouped by receipt id.
Future<Map<String, List<Discount>>> _discountsByReceipt(
    AppDatabase db, Iterable<String> receiptIds) async {
  final ids = receiptIds.toList();
  if (ids.isEmpty) return const {};
  final rows = await (db.select(db.discounts)
        ..where((x) => x.receiptId.isIn(ids)))
      .get();
  final out = <String, List<Discount>>{};
  for (final d in rows) {
    (out[d.receiptId] ??= <Discount>[]).add(d);
  }
  return out;
}

/// Recompute every itemized receipt's money + paid status for a visit.
Future<void> _recompute(AppDatabase db, String visitId) async {
  final cfg = await _config(db);
  final recs = await (db.select(db.receipts)
        ..where((x) => x.visitId.equals(visitId)))
      .get();
  final tickets = {for (final t in await _sentTickets(db, visitId)) t.id: t};

  final byReceipt = await _discountsByReceipt(db, recs.map((r) => r.id));

  final itemized = recs.where((r) => r.mode != 'even').toList();
  final subtotals = <int>[]; // net of line discounts (ADR-0038)
  final lineDiscounts = <int>[];
  final orderDiscounts = <int>[];
  for (final rec in itemized) {
    final lines = await (db.select(db.receiptLines)
          ..where((x) => x.receiptId.equals(rec.id)))
        .get();
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
  final fullyAssigned = await _fullyAssigned(db, tickets.values);
  final billTotal = fullyAssigned
      ? computeBreakdown(billSub - _sum(lineDiscounts), cfg,
              discount: _sum(orderDiscounts))
          .total
      : null;
  final breakdowns = splitItemized(subtotals, cfg,
      billTotalTarget: (assignedSub == billSub) ? billTotal : null,
      discounts: orderDiscounts);

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
  final rows = await (db.selectOnly(db.payments)
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

Future<void> _audit(AppDatabase db, AuditType type, String title,
    {required String tableId, String? actor, String? reason}) async {
  await db.into(db.auditEntries).insert(AuditEntriesCompanion.insert(
        id: _uuid.v4(),
        type: type.name,
        title: title,
        tableId: Value(tableId),
        at: DateTime.now().toUtc(),
        actorUserId: Value(actor),
        reason: Value(reason),
      ));
}

/// Build the full bill JSON for one visit, or null if it has no sent lines.
Future<Map<String, dynamic>?> _buildBill(AppDatabase db, String visitId) async {
  final visit = await _visit(db, visitId);
  if (visit == null) return null;
  final tickets = await _sentTickets(db, visitId);
  if (tickets.isEmpty) return null;
  final cfg = await _config(db);
  final billSub = tickets.fold<int>(0, (a, t) => a + t.price * t.qty);

  final recs = await (db.select(db.receipts)
        ..where((x) => x.visitId.equals(visitId)))
      .get();
  final mode = recs.any((r) => r.mode == 'even') ? 'even' : 'itemized';

  // Aggregate the receipts' discounts up to bill level. Without this the bill
  // total stays undiscounted while the receipts shrink, so `outstanding` never
  // reaches zero and a fully-paid discounted bill never shows Lunas.
  final byReceipt = await _discountsByReceipt(db, recs.map((r) => r.id));
  final allDiscounts = byReceipt.values.expand((x) => x);
  final billLineDiscount =
      _sum(allDiscounts.where((d) => d.ticketId != null).map((d) => d.amount));
  final billOrderDiscount =
      _sum(allDiscounts.where((d) => d.ticketId == null).map((d) => d.amount));
  final billBreak = computeBreakdown(billSub - billLineDiscount, cfg,
      discount: billOrderDiscount);

  var paidNet = 0;
  final receiptsJson = <Map<String, dynamic>>[];
  for (final rec in recs) {
    final lines = await (db.select(db.receiptLines)
          ..where((x) => x.receiptId.equals(rec.id)))
        .get();
    // Project every payment column EXCEPT the blob; expose only `hasPhoto`.
    // Bytes are fetched on demand via the photo route (ADR-0025/0014).
    final payPhoto = db.payments.photo.isNotNull();
    final pays = await (db.selectOnly(db.payments)
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
    final recPaid =
        pays.fold<int>(0, (a, p) => a + p.read(db.payments.amount)!);
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
          _discountJson(d)
      ],
      'lines': [
        for (final l in lines) {'ticketId': l.ticketId, 'qtyUnits': l.qtyUnits}
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
          }
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
  final fullyAssigned =
      linesJson.every((l) => (l['assignedUnits'] as int) >= (l['qty'] as int));
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
    'status': detached ? 'detached' : 'occupied',
    'detached': detached,
    'tableFreedAt': visit.tableFreedAt?.toIso8601String(),
    'billClosedAt': visit.billClosedAt?.toIso8601String(),
    'pax': visit.pax,
    'guestName': visit.guestName,
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
    'lines': linesJson,
    'receipts': receiptsJson,
  };
}

/// Reconstruct a bill-shaped map for a CLOSED session (past bill), from the
/// snapshot tables — for the Struk pembayaran detail view.
Future<Map<String, dynamic>?> _buildSessionBill(
    AppDatabase db, String sessionId) async {
  final s = await (db.select(db.tableSessions)
        ..where((x) => x.id.equals(sessionId)))
      .getSingleOrNull();
  if (s == null) return null;
  final stk = await (db.select(db.tableSessionTickets)
        ..where((x) => x.sessionId.equals(sessionId)))
      .get();
  final srec = await (db.select(db.tableSessionReceipts)
        ..where((x) => x.sessionId.equals(sessionId)))
      .get();
  // Snapshot payments without the blob; `paymentId` keys the history photo
  // route, `hasPhoto` flags whether to show a thumbnail (ADR-0025).
  final spayPhoto = db.tableSessionPayments.photo.isNotNull();
  final spay = await (db.selectOnly(db.tableSessionPayments)
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
        .where((p) =>
            p.read(db.tableSessionPayments.receiptId) == rec.receiptId)
        .toList();
    final recPaid =
        pays.fold<int>(0, (a, p) => a + p.read(db.tableSessionPayments.amount)!);
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
          }
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
      }
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
      'total': bill['total'],
      'paidAmount': bill['paidAmount'],
      'outstanding': bill['outstanding'],
      'receiptCount': (bill['receipts'] as List).length,
      'mode': bill['mode'],
      'fullySettled': bill['fullySettled'],
    };

String _rupiah(int n) => 'Rp${n.toString()}';

Response _ok(Object body) =>
    Response.ok(jsonEncode(body), headers: {'content-type': 'application/json'});

Response _err(int status, String code, String message) => Response(status,
    body: jsonEncode({'code': code, 'message': message}),
    headers: {'content-type': 'application/json'});
