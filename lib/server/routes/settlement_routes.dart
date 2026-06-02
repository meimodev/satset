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
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();
const _methods = {'tunai', 'kartu', 'qris', 'transfer', 'lainnya'};

/// Two-phase settlement + split bills. See
/// docs/adr/0023-two-phase-settlement-and-split-bills.md and CONTEXT.md
/// (Bill / Settlement / Split bill / Payment / Tax & service charge).
Router settlementRoutes(AppDatabase db, WsHub hub, [ServerAuth? auth]) {
  final r = Router();

  Future<User?> resolve(Request req) async {
    if (auth == null) return null;
    final token = req.headers['authorization']
        ?.replaceFirst(RegExp(r'^[Bb]earer\s+'), '');
    return auth.resolveBearer(token);
  }

  Future<Response?> requireCap(Request req, Capability needed) async {
    if (auth == null) return null;
    final user = await resolve(req);
    if (user == null) return Response(401);
    final role = await (db.select(db.roles)
          ..where((x) => x.id.equals(user.roleId)))
        .getSingleOrNull();
    final caps = role == null
        ? const <String>[]
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
    if (!caps.contains(needed.name)) {
      return _err(403, 'forbidden', 'missing capability ${needed.name}');
    }
    return null;
  }

  Future<void> broadcastBill(String tableId) async {
    final bill = await _buildBill(db, tableId);
    if (bill != null) hub.broadcast(WsEventTypes.billUpdated, bill);
  }

  // List every payable table (occupied + ≥1 sent line) with a bill summary.
  r.get('/settlement/payable', (Request req) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final tables = await db.select(db.venueTables).get();
    final out = <Map<String, dynamic>>[];
    for (final t in tables) {
      if (t.status == 'available') continue;
      final bill = await _buildBill(db, t.id);
      if (bill == null) continue; // no sent lines
      out.add(_summarize(bill));
    }
    out.sort((a, b) => (b['outstanding'] as int).compareTo(a['outstanding'] as int));
    return _ok(out);
  });

  // Full bill detail for one table.
  r.get('/settlement/tables/<tableId>/bill', (Request req, String tableId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final bill = await _buildBill(db, tableId);
    if (bill == null) return _err(404, 'no_bill', 'table has no sent lines');
    return _ok(bill);
  });

  // Create a receipt. {mode: itemized|even, label?, assignAll?: bool}.
  // assignAll grabs every currently-unassigned sent line unit (the "pay full"
  // shortcut). Switching the bill to/from even mode is done via /split-even.
  r.post('/settlement/tables/<tableId>/receipts',
      (Request req, String tableId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final mode = (body['mode'] as String?) == 'even' ? 'even' : 'itemized';
    final id = _uuid.v4();
    await db.transaction(() async {
      await db.into(db.receipts).insert(ReceiptsCompanion.insert(
            id: id,
            tableId: tableId,
            mode: Value(mode),
            label: Value((body['label'] as String?)?.trim() ?? ''),
            createdAt: DateTime.now().toUtc(),
          ));
      if (body['assignAll'] == true) {
        await _assignAllUnassigned(db, tableId, id);
      }
      await _recompute(db, tableId);
    });
    await broadcastBill(tableId);
    final bill = await _buildBill(db, tableId);
    return _ok({'receiptId': id, 'bill': bill});
  });

  // Delete an unpaid receipt; its line assignments are released.
  r.delete('/settlement/receipts/<receiptId>',
      (Request req, String receiptId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    if (rec.status == 'paid') {
      return _err(409, 'receipt_paid', 'reopen before deleting a paid receipt');
    }
    await db.transaction(() async {
      await (db.delete(db.receiptLines)
            ..where((x) => x.receiptId.equals(receiptId)))
          .go();
      await (db.delete(db.payments)..where((x) => x.receiptId.equals(receiptId)))
          .go();
      await (db.delete(db.receipts)..where((x) => x.id.equals(receiptId))).go();
      await _recompute(db, rec.tableId);
    });
    await broadcastBill(rec.tableId);
    return _ok({'bill': await _buildBill(db, rec.tableId)});
  });

  // Assign qty units of a sent ticket to a receipt (qty-level). {ticketId, qtyUnits}.
  r.post('/settlement/receipts/<receiptId>/lines',
      (Request req, String receiptId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    if (rec.status == 'paid') {
      return _err(409, 'receipt_paid', 'reopen the receipt before editing lines');
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final ticketId = body['ticketId'] as String;
    final want = ((body['qtyUnits'] as num?)?.toInt() ?? 1).clamp(0, 1 << 30);
    final ticket = await (db.select(db.tickets)
          ..where((x) => x.id.equals(ticketId)))
        .getSingleOrNull();
    if (ticket == null || ticket.tableId != rec.tableId) {
      return _err(404, 'no_ticket', 'ticket not on this table');
    }
    // Units already assigned to OTHER receipts for this ticket.
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
      await _recompute(db, rec.tableId);
    });
    await broadcastBill(rec.tableId);
    return _ok({'bill': await _buildBill(db, rec.tableId)});
  });

  // Replace all receipts with an even N-way split of the bill total.
  r.post('/settlement/tables/<tableId>/split-even',
      (Request req, String tableId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final n = ((body['n'] as num?)?.toInt() ?? 2).clamp(1, 50);
    final bill = await _buildBill(db, tableId);
    if (bill == null) return _err(404, 'no_bill', 'table has no sent lines');
    // Cannot blow away a receipt that already took money.
    final paid = await (db.select(db.receipts)
          ..where((x) => x.tableId.equals(tableId) & x.status.equals('paid')))
        .get();
    if (paid.isNotEmpty) {
      return _err(409, 'receipt_paid', 'reopen paid receipts before re-splitting');
    }
    final total = bill['total'] as int;
    final shares = distributeEven(total, n);
    await db.transaction(() async {
      await _clearReceipts(db, tableId);
      for (var i = 0; i < n; i++) {
        await db.into(db.receipts).insert(ReceiptsCompanion.insert(
              id: _uuid.v4(),
              tableId: tableId,
              mode: const Value('even'),
              label: Value('Bagian ${i + 1}/$n'),
              total: Value(shares[i]),
              createdAt: DateTime.now().toUtc(),
            ));
      }
    });
    await broadcastBill(tableId);
    return _ok({'bill': await _buildBill(db, tableId)});
  });

  // Record a payment against a receipt. {method, amount, tendered?, note?}.
  r.post('/settlement/receipts/<receiptId>/payments',
      (Request req, String receiptId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final user = await resolve(req);
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final method = (body['method'] as String?) ?? 'tunai';
    if (!_methods.contains(method)) {
      return _err(400, 'bad_method', 'unknown payment method');
    }
    final amount = (body['amount'] as num?)?.toInt() ?? 0;
    if (amount <= 0) return _err(400, 'bad_amount', 'amount must be positive');
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
          ));
      await _recompute(db, rec.tableId);
      await _audit(db, AuditType.paymentRecorded,
          'Pembayaran ${_rupiah(amount)} ($method) ${rec.label}',
          tableId: rec.tableId, actor: user?.id);
    });
    await broadcastBill(rec.tableId);
    return _ok({'bill': await _buildBill(db, rec.tableId)});
  });

  // Record a refund (negative payment) against a receipt. Needs `refund` cap.
  r.post('/settlement/receipts/<receiptId>/refund',
      (Request req, String receiptId) async {
    final denied = await requireCap(req, Capability.refund);
    if (denied != null) return denied;
    final user = await resolve(req);
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
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
      await _recompute(db, rec.tableId);
      await _audit(db, AuditType.refund,
          'Refund ${_rupiah(amount)} ($method) ${rec.label}',
          tableId: rec.tableId, actor: user?.id,
          reason: (body['note'] as String?)?.trim());
    });
    await broadcastBill(rec.tableId);
    return _ok({'bill': await _buildBill(db, rec.tableId)});
  });

  // Render + send the MONEY document to a VENUE printer (server-rendered,
  // mirroring /tables/:id/print). Whole bill or one receipt; the renderer picks
  // Tagihan vs Struk pembayaran from whether payments exist. See ADR-0023/0020.
  Future<Response> printDoc(
      String tableId, Map<String, dynamic> bill, String? receiptId,
      String? printerId) async {
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
      address: v?.address ?? '',
      phone: v?.phone ?? '',
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
  r.post('/settlement/tables/<tableId>/bill/print',
      (Request req, String tableId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final bill = await _buildBill(db, tableId);
    if (bill == null) return _err(409, 'no_lines', 'tidak ada pesanan');
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    return printDoc(tableId, bill, null, body['printerId'] as String?);
  });

  // Print one receipt's Tagihan / Struk pembayaran. {printerId}.
  r.post('/settlement/receipts/<receiptId>/print',
      (Request req, String receiptId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    final bill = await _buildBill(db, rec.tableId);
    if (bill == null) return _err(409, 'no_lines', 'tidak ada pesanan');
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    return printDoc(rec.tableId, bill, receiptId, body['printerId'] as String?);
  });

  // Reopen (un-pay) a receipt: clears its payments. Audited.
  r.post('/settlement/receipts/<receiptId>/reopen',
      (Request req, String receiptId) async {
    final denied = await requireCap(req, Capability.settleBill);
    if (denied != null) return denied;
    final user = await resolve(req);
    final rec = await _receipt(db, receiptId);
    if (rec == null) return _err(404, 'no_receipt', 'receipt not found');
    await db.transaction(() async {
      await (db.delete(db.payments)..where((x) => x.receiptId.equals(receiptId)))
          .go();
      await _recompute(db, rec.tableId);
      await _audit(db, AuditType.billReopened, 'Buka ulang ${rec.label}',
          tableId: rec.tableId, actor: user?.id);
    });
    await broadcastBill(rec.tableId);
    return _ok({'bill': await _buildBill(db, rec.tableId)});
  });

  return r;
}

// ───────────────────────── helpers ─────────────────────────

Future<Receipt?> _receipt(AppDatabase db, String id) =>
    (db.select(db.receipts)..where((x) => x.id.equals(id))).getSingleOrNull();

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
    AppDatabase db, String tableId, String receiptId) async {
  final tickets = await _sentTickets(db, tableId);
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

Future<void> _clearReceipts(AppDatabase db, String tableId) async {
  final recs = await (db.select(db.receipts)
        ..where((x) => x.tableId.equals(tableId)))
      .get();
  for (final rec in recs) {
    await (db.delete(db.receiptLines)..where((x) => x.receiptId.equals(rec.id)))
        .go();
    await (db.delete(db.payments)..where((x) => x.receiptId.equals(rec.id)))
        .go();
  }
  await (db.delete(db.receipts)..where((x) => x.tableId.equals(tableId))).go();
}

Future<List<Ticket>> _sentTickets(AppDatabase db, String tableId) async {
  final rows = await (db.select(db.tickets)
        ..where((x) => x.tableId.equals(tableId)))
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
  );
}

/// Recompute every itemized receipt's money + paid status for a table.
/// Even receipts keep their fixed share `total`; only their paid status moves.
Future<void> _recompute(AppDatabase db, String tableId) async {
  final cfg = await _config(db);
  final recs = await (db.select(db.receipts)
        ..where((x) => x.tableId.equals(tableId)))
      .get();
  final tickets = {for (final t in await _sentTickets(db, tableId)) t.id: t};

  final itemized = recs.where((r) => r.mode != 'even').toList();
  final subtotals = <int>[];
  for (final rec in itemized) {
    final lines = await (db.select(db.receiptLines)
          ..where((x) => x.receiptId.equals(rec.id)))
        .get();
    var sub = 0;
    for (final l in lines) {
      final t = tickets[l.ticketId];
      if (t != null) sub += t.price * l.qtyUnits;
    }
    subtotals.add(sub);
  }
  // Reconcile to the bill total only when every sent unit is assigned.
  final billSub = tickets.values.fold<int>(0, (a, t) => a + t.price * t.qty);
  final assignedSub = subtotals.fold<int>(0, (a, b) => a + b);
  final fullyAssigned = await _fullyAssigned(db, tableId, tickets.values);
  final billTotal =
      fullyAssigned ? computeBreakdown(billSub, cfg).total : null;
  final breakdowns = splitItemized(subtotals, cfg,
      billTotalTarget: (assignedSub == billSub) ? billTotal : null);

  for (var i = 0; i < itemized.length; i++) {
    final rec = itemized[i];
    final b = breakdowns[i];
    final paid = await _paidNet(db, rec.id);
    await (db.update(db.receipts)..where((x) => x.id.equals(rec.id))).write(
      ReceiptsCompanion(
        subtotal: Value(b.subtotal),
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

Future<int> _paidNet(AppDatabase db, String receiptId) async {
  final rows = await (db.select(db.payments)
        ..where((x) => x.receiptId.equals(receiptId)))
      .get();
  return rows.fold<int>(0, (a, p) => a + p.amount);
}

Future<bool> _fullyAssigned(
    AppDatabase db, String tableId, Iterable<Ticket> tickets) async {
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

/// Build the full bill JSON for one table, or null if it has no sent lines.
Future<Map<String, dynamic>?> _buildBill(AppDatabase db, String tableId) async {
  final table = await (db.select(db.venueTables)
        ..where((x) => x.id.equals(tableId)))
      .getSingleOrNull();
  if (table == null) return null;
  final tickets = await _sentTickets(db, tableId);
  if (tickets.isEmpty) return null;
  final cfg = await _config(db);
  final billSub = tickets.fold<int>(0, (a, t) => a + t.price * t.qty);
  final billBreak = computeBreakdown(billSub, cfg);

  final recs = await (db.select(db.receipts)
        ..where((x) => x.tableId.equals(tableId)))
      .get();
  final mode = recs.any((r) => r.mode == 'even') ? 'even' : 'itemized';

  var paidNet = 0;
  final receiptsJson = <Map<String, dynamic>>[];
  for (final rec in recs) {
    final lines = await (db.select(db.receiptLines)
          ..where((x) => x.receiptId.equals(rec.id)))
        .get();
    final pays = await (db.select(db.payments)
          ..where((x) => x.receiptId.equals(rec.id)))
        .get();
    final recPaid = pays.fold<int>(0, (a, p) => a + p.amount);
    paidNet += recPaid;
    receiptsJson.add({
      'id': rec.id,
      'mode': rec.mode,
      'label': rec.label,
      'subtotal': rec.subtotal,
      'serviceAmount': rec.serviceAmount,
      'taxAmount': rec.taxAmount,
      'total': rec.total,
      'status': rec.status,
      'paidNet': recPaid,
      'lines': [
        for (final l in lines) {'ticketId': l.ticketId, 'qtyUnits': l.qtyUnits}
      ],
      'payments': [
        for (final p in pays)
          {
            'id': p.id,
            'method': p.method,
            'amount': p.amount,
            'isRefund': p.isRefund,
            'tendered': p.tenderedAmount,
            'cashierUserId': p.cashierUserId,
            'note': p.note,
            'at': p.at.toIso8601String(),
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
    });
  }
  final fullyAssigned =
      linesJson.every((l) => (l['assignedUnits'] as int) >= (l['qty'] as int));
  final allReceiptsPaid =
      recs.isNotEmpty && recs.every((r) => r.status == 'paid');
  final outstanding = (billBreak.total - paidNet).clamp(0, 1 << 31);

  return {
    'tableId': table.id,
    'tableLabel': table.label,
    'status': table.status,
    'pax': table.pax,
    'guestName': table.guestName,
    'mode': mode,
    'subtotal': billBreak.subtotal,
    'serviceAmount': billBreak.serviceAmount,
    'taxAmount': billBreak.taxAmount,
    'total': billBreak.total,
    'paidAmount': paidNet,
    'outstanding': outstanding,
    'fullyAssigned': fullyAssigned,
    'fullySettled': fullyAssigned && allReceiptsPaid,
    'lines': linesJson,
    'receipts': receiptsJson,
  };
}

Map<String, dynamic> _summarize(Map<String, dynamic> bill) => {
      'tableId': bill['tableId'],
      'tableLabel': bill['tableLabel'],
      'status': bill['status'],
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
