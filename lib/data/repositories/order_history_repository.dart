import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/data/services/api_client.dart';

/// Read-only feed behind the order-list export (ADR-0030). One-shot fetch of
/// CLOSED visits + their line items for a chosen window, grouped by visit. The
/// live order board never touches this — only the export sheet does. Plain
/// hand-rolled models (no codegen): the shapes are export-local.

class OrderHistoryLine {
  final DateTime sentAt;
  final String name;
  final String variantName;
  final String course;
  final int qty;
  final int price;
  final int lineTotal;
  final String status;
  final List<String> modifiers;
  final DateTime? readyAt;
  final DateTime? servedAt;
  final String? voidReasonCode;

  const OrderHistoryLine({
    required this.sentAt,
    required this.name,
    required this.variantName,
    required this.course,
    required this.qty,
    required this.price,
    required this.lineTotal,
    required this.status,
    required this.modifiers,
    this.readyAt,
    this.servedAt,
    this.voidReasonCode,
  });

  bool get isVoided => status == 'voided';

  static OrderHistoryLine fromJson(Map<String, dynamic> j) => OrderHistoryLine(
    sentAt: DateTime.parse(j['sentAt'] as String),
    name: j['name'] as String? ?? '',
    variantName: j['variantName'] as String? ?? '',
    course: j['course'] as String? ?? '',
    qty: (j['qty'] as num?)?.toInt() ?? 1,
    price: (j['price'] as num?)?.toInt() ?? 0,
    lineTotal: (j['lineTotal'] as num?)?.toInt() ?? 0,
    status: j['status'] as String? ?? '',
    modifiers: [
      for (final m in (j['modifiers'] as List? ?? const [])) m as String,
    ],
    readyAt: j['readyAt'] == null
        ? null
        : DateTime.parse(j['readyAt'] as String),
    servedAt: j['servedAt'] == null
        ? null
        : DateTime.parse(j['servedAt'] as String),
    voidReasonCode: j['voidReasonCode'] as String?,
  );
}

/// One tender recorded against a receipt (ADR-0031). `cashierName` is resolved
/// server-side. `hasPhoto` flags a non-cash proof; the bytes are fetched on
/// demand by `paymentId` (ADR-0025), never carried in this feed.
class OrderHistoryPayment {
  final String paymentId;
  final String method;
  final int amount;
  final bool isRefund;
  final String? cashierName;
  final DateTime at;
  final bool hasPhoto;

  const OrderHistoryPayment({
    required this.paymentId,
    required this.method,
    required this.amount,
    required this.isRefund,
    required this.cashierName,
    required this.at,
    required this.hasPhoto,
  });

  static OrderHistoryPayment fromJson(Map<String, dynamic> j) =>
      OrderHistoryPayment(
        paymentId: j['paymentId'] as String? ?? '',
        method: j['method'] as String? ?? '',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        isRefund: j['isRefund'] as bool? ?? false,
        cashierName: j['cashierName'] as String?,
        at: DateTime.parse(j['at'] as String),
        hasPhoto: j['hasPhoto'] as bool? ?? false,
      );
}

/// One receipt's settlement snapshot — totals breakdown + the payments tendered
/// against it (ADR-0031). A split bill yields several of these per visit.
class OrderHistoryReceipt {
  final String receiptId;
  final String label;
  final String mode;
  final int subtotal;

  /// Total give-back on this receipt (line + whole-order). ADR-0037.
  final int discountAmount;
  final int serviceAmount;
  final int taxAmount;
  final int total;
  final String status;
  final List<OrderHistoryPayment> payments;

  const OrderHistoryReceipt({
    required this.receiptId,
    required this.label,
    required this.mode,
    required this.subtotal,
    required this.discountAmount,
    required this.serviceAmount,
    required this.taxAmount,
    required this.total,
    required this.status,
    required this.payments,
  });

  static OrderHistoryReceipt fromJson(Map<String, dynamic> j) =>
      OrderHistoryReceipt(
        receiptId: j['receiptId'] as String? ?? '',
        label: j['label'] as String? ?? '',
        mode: j['mode'] as String? ?? 'itemized',
        subtotal: (j['subtotal'] as num?)?.toInt() ?? 0,
        discountAmount: (j['discountAmount'] as num?)?.toInt() ?? 0,
        serviceAmount: (j['serviceAmount'] as num?)?.toInt() ?? 0,
        taxAmount: (j['taxAmount'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        status: j['status'] as String? ?? '',
        payments: [
          for (final p in (j['payments'] as List? ?? const []))
            OrderHistoryPayment.fromJson((p as Map).cast<String, dynamic>()),
        ],
      );
}

class OrderHistoryVisit {
  final String sessionId;
  final String tableLabel;
  final String kind;
  final int pax;
  final DateTime closedAt;
  final String? waiterName;
  final int subtotal;
  final int voidAmount;
  final int net;
  final List<OrderHistoryLine> lines;
  final List<OrderHistoryReceipt> receipts;

  const OrderHistoryVisit({
    required this.sessionId,
    required this.tableLabel,
    required this.kind,
    required this.pax,
    required this.closedAt,
    required this.waiterName,
    required this.subtotal,
    required this.voidAmount,
    required this.net,
    required this.lines,
    required this.receipts,
  });

  bool get isTakeaway => kind == 'takeaway';

  /// Every tender across all receipts, flattened (for non-split rendering).
  Iterable<OrderHistoryPayment> get allPayments =>
      receipts.expand((r) => r.payments);

  static OrderHistoryVisit fromJson(Map<String, dynamic> j) =>
      OrderHistoryVisit(
        sessionId: j['sessionId'] as String? ?? '',
        tableLabel: j['tableLabel'] as String? ?? '—',
        kind: j['kind'] as String? ?? 'dineIn',
        pax: (j['pax'] as num?)?.toInt() ?? 0,
        closedAt: DateTime.parse(j['closedAt'] as String),
        waiterName: j['waiterName'] as String?,
        subtotal: (j['subtotal'] as num?)?.toInt() ?? 0,
        voidAmount: (j['voidAmount'] as num?)?.toInt() ?? 0,
        net: (j['net'] as num?)?.toInt() ?? 0,
        lines: [
          for (final l in (j['lines'] as List? ?? const []))
            OrderHistoryLine.fromJson((l as Map).cast<String, dynamic>()),
        ],
        receipts: [
          for (final r in (j['receipts'] as List? ?? const []))
            OrderHistoryReceipt.fromJson((r as Map).cast<String, dynamic>()),
        ],
      );
}

class OrderHistory {
  final DateTime generatedAt;
  final DateTime rangeFrom;
  final DateTime rangeTo;
  final ReportRange range;
  final List<OrderHistoryVisit> visits;
  final int visitCount;
  final int lineCount;
  final int net;

  const OrderHistory({
    required this.generatedAt,
    required this.rangeFrom,
    required this.rangeTo,
    required this.range,
    required this.visits,
    required this.visitCount,
    required this.lineCount,
    required this.net,
  });

  bool get isEmpty => visits.isEmpty;

  static OrderHistory fromJson(Map<String, dynamic> j, ReportRange range) {
    final totals = (j['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    return OrderHistory(
      generatedAt: DateTime.parse(j['generatedAt'] as String),
      rangeFrom: DateTime.parse(j['rangeFrom'] as String),
      rangeTo: DateTime.parse(j['rangeTo'] as String),
      range: range,
      visits: [
        for (final v in (j['visits'] as List? ?? const []))
          OrderHistoryVisit.fromJson((v as Map).cast<String, dynamic>()),
      ],
      visitCount: (totals['visitCount'] as num?)?.toInt() ?? 0,
      lineCount: (totals['lineCount'] as num?)?.toInt() ?? 0,
      net: (totals['net'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One-shot fetcher for the export sheet. Throws on transport/HTTP error so the
/// caller can surface it; the order board stays oblivious either way.
final orderHistoryFetcherProvider =
    Provider<Future<OrderHistory> Function(ReportsQuery)>(
      (ref) => (ReportsQuery query) async {
        final api = ref.read(apiClientProvider);
        final raw = await api.getJson(
          '/orders/history',
          // Reuse the report query's range encoding (incl. custom from/to) so the
          // order export always matches the active timeline chip (ADR-0031).
          query: query.toQueryParams()
            ..remove('server')
            ..remove('zone')
            ..remove('category'),
        );
        return OrderHistory.fromJson(
          (raw as Map).cast<String, dynamic>(),
          query.range,
        );
      },
    );

/// Fetches proof-photo bytes for every non-cash payment in a history window,
/// keyed by `paymentId` (ADR-0031). Used only by the PDF export. Bounded
/// concurrency keeps the LAN fetch civil; a failed fetch is skipped so that
/// payment row still renders text-only. The blob is fetched on demand here,
/// never carried in the history JSON (ADR-0025).
final orderHistoryPhotosFetcherProvider =
    Provider<Future<Map<String, Uint8List>> Function(OrderHistory)>(
      (ref) => (OrderHistory history) async {
        final api = ref.read(apiClientProvider);
        final ids = [
          for (final v in history.visits)
            for (final p in v.allPayments)
              if (p.hasPhoto && p.paymentId.isNotEmpty) p.paymentId,
        ];
        final out = <String, Uint8List>{};
        const concurrency = 4;
        for (var i = 0; i < ids.length; i += concurrency) {
          final batch = ids.skip(i).take(concurrency).toList();
          final results = await Future.wait([
            for (final id in batch)
              api
                  .getBytes('/settlement/history/payments/$id/photo')
                  .then<Uint8List?>((b) => b)
                  .catchError((_) => null),
          ]);
          for (var k = 0; k < batch.length; k++) {
            final b = results[k];
            if (b != null) out[batch[k]] = b;
          }
        }
        return out;
      },
    );
