/// Hand-written parse models for the settlement (`/settlement/*`) API. Plain
/// Dart — no codegen — since the bill shape is read-mostly and assembled
/// server-side. See ADR-0023 and CONTEXT.md (Bill / Split bill / Payment).
library;

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// Lighter row for the cashier's payable-table list.
class BillSummary {
  final String tableId;
  final String? tableLabel;
  final String status;
  final int pax;
  final String? guestName;
  final int total;
  final int paidAmount;
  final int outstanding;
  final int receiptCount;
  final String mode;
  final bool fullySettled;

  const BillSummary({
    required this.tableId,
    required this.tableLabel,
    required this.status,
    required this.pax,
    required this.guestName,
    required this.total,
    required this.paidAmount,
    required this.outstanding,
    required this.receiptCount,
    required this.mode,
    required this.fullySettled,
  });

  factory BillSummary.fromJson(Map<String, dynamic> j) => BillSummary(
        tableId: j['tableId'] as String,
        tableLabel: j['tableLabel'] as String?,
        status: j['status'] as String? ?? 'occupied',
        pax: _int(j['pax']),
        guestName: j['guestName'] as String?,
        total: _int(j['total']),
        paidAmount: _int(j['paidAmount']),
        outstanding: _int(j['outstanding']),
        receiptCount: _int(j['receiptCount']),
        mode: j['mode'] as String? ?? 'itemized',
        fullySettled: j['fullySettled'] as bool? ?? false,
      );
}

class BillLine {
  final String ticketId;
  final String itemId;
  final String name;
  final String variantName;
  final int qty;
  final int unitPrice;
  final int lineTotal;
  final int assignedUnits;
  final String? note;
  final String status;

  const BillLine({
    required this.ticketId,
    required this.itemId,
    required this.name,
    required this.variantName,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.assignedUnits,
    required this.note,
    required this.status,
  });

  int get unassignedUnits => (qty - assignedUnits).clamp(0, qty);

  factory BillLine.fromJson(Map<String, dynamic> j) => BillLine(
        ticketId: j['ticketId'] as String,
        itemId: j['itemId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        variantName: j['variantName'] as String? ?? '',
        qty: _int(j['qty']),
        unitPrice: _int(j['unitPrice']),
        lineTotal: _int(j['lineTotal']),
        assignedUnits: _int(j['assignedUnits']),
        note: j['note'] as String?,
        status: j['status'] as String? ?? 'sent',
      );
}

class BillPayment {
  final String id;
  final String method;
  final int amount;
  final bool isRefund;
  final int? tendered;
  final String? note;
  final DateTime at;

  const BillPayment({
    required this.id,
    required this.method,
    required this.amount,
    required this.isRefund,
    required this.tendered,
    required this.note,
    required this.at,
  });

  factory BillPayment.fromJson(Map<String, dynamic> j) => BillPayment(
        id: j['id'] as String,
        method: j['method'] as String? ?? 'tunai',
        amount: _int(j['amount']),
        isRefund: j['isRefund'] as bool? ?? false,
        tendered: (j['tendered'] as num?)?.toInt(),
        note: j['note'] as String?,
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
      );
}

class BillReceiptLine {
  final String ticketId;
  final int qtyUnits;
  const BillReceiptLine(this.ticketId, this.qtyUnits);
}

class BillReceipt {
  final String id;
  final String mode;
  final String label;
  final int subtotal;
  final int serviceAmount;
  final int taxAmount;
  final int total;
  final String status;
  final int paidNet;
  final List<BillReceiptLine> lines;
  final List<BillPayment> payments;

  const BillReceipt({
    required this.id,
    required this.mode,
    required this.label,
    required this.subtotal,
    required this.serviceAmount,
    required this.taxAmount,
    required this.total,
    required this.status,
    required this.paidNet,
    required this.lines,
    required this.payments,
  });

  bool get isPaid => status == 'paid';
  int get outstanding => (total - paidNet).clamp(0, 1 << 31);

  factory BillReceipt.fromJson(Map<String, dynamic> j) => BillReceipt(
        id: j['id'] as String,
        mode: j['mode'] as String? ?? 'itemized',
        label: j['label'] as String? ?? '',
        subtotal: _int(j['subtotal']),
        serviceAmount: _int(j['serviceAmount']),
        taxAmount: _int(j['taxAmount']),
        total: _int(j['total']),
        status: j['status'] as String? ?? 'unpaid',
        paidNet: _int(j['paidNet']),
        lines: [
          for (final l in (j['lines'] as List? ?? const []))
            BillReceiptLine((l as Map)['ticketId'] as String,
                _int((l)['qtyUnits'])),
        ],
        payments: [
          for (final p in (j['payments'] as List? ?? const []))
            BillPayment.fromJson((p as Map).cast<String, dynamic>()),
        ],
      );
}

class Bill {
  final String tableId;
  final String? tableLabel;
  final String status;
  final int pax;
  final String? guestName;
  final String mode;
  final int subtotal;
  final int serviceAmount;
  final int taxAmount;
  final int total;
  final int paidAmount;
  final int outstanding;
  final bool fullyAssigned;
  final bool fullySettled;
  final List<BillLine> lines;
  final List<BillReceipt> receipts;

  const Bill({
    required this.tableId,
    required this.tableLabel,
    required this.status,
    required this.pax,
    required this.guestName,
    required this.mode,
    required this.subtotal,
    required this.serviceAmount,
    required this.taxAmount,
    required this.total,
    required this.paidAmount,
    required this.outstanding,
    required this.fullyAssigned,
    required this.fullySettled,
    required this.lines,
    required this.receipts,
  });

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
        tableId: j['tableId'] as String,
        tableLabel: j['tableLabel'] as String?,
        status: j['status'] as String? ?? 'occupied',
        pax: _int(j['pax']),
        guestName: j['guestName'] as String?,
        mode: j['mode'] as String? ?? 'itemized',
        subtotal: _int(j['subtotal']),
        serviceAmount: _int(j['serviceAmount']),
        taxAmount: _int(j['taxAmount']),
        total: _int(j['total']),
        paidAmount: _int(j['paidAmount']),
        outstanding: _int(j['outstanding']),
        fullyAssigned: j['fullyAssigned'] as bool? ?? false,
        fullySettled: j['fullySettled'] as bool? ?? false,
        lines: [
          for (final l in (j['lines'] as List? ?? const []))
            BillLine.fromJson((l as Map).cast<String, dynamic>()),
        ],
        receipts: [
          for (final r in (j['receipts'] as List? ?? const []))
            BillReceipt.fromJson((r as Map).cast<String, dynamic>()),
        ],
      );
}
