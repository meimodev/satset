import 'dart:convert';

import 'package:satset/core/printing/bill_struk_data.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/venue_settings_dto.dart';

/// Assembles a [BillStrukData] for the MONEY document from either source — the
/// typed [Bill] on a client, or the raw settlement bill map on the server —
/// producing the SAME shape so the shared [BillStrukRenderer] prints identically
/// (ADR-0023 / ADR-0020).
///
/// `receipt`/`receiptId` null ⇒ the whole-bill document; otherwise a single
/// split receipt. The Tagihan-vs-Struk-pembayaran state is decided downstream
/// purely by whether the assembled doc carries payments.
class BillStrukBuilder {
  static const _methodLabels = {
    'tunai': 'Tunai',
    'kartu': 'Kartu',
    'qris': 'QRIS',
    'transfer': 'Transfer',
    'lainnya': 'Lainnya',
  };

  static String _label(String method) => _methodLabels[method] ?? method;

  // ── client: from the typed Bill ──

  static BillStrukData fromBill({
    required Bill bill,
    BillReceipt? receipt,
    required VenueSettingsDto venue,
    List<int>? logoBytes,
  }) {
    if (receipt == null) {
      // Whole-bill: every sent line, the grand total, aggregate payments.
      final pays = [
        for (final r in bill.receipts) ...r.payments,
      ];
      return BillStrukData(
        venueName: venue.displayName,
        header: venue.receiptHeader,
        footer: venue.receiptFooter,
        tagline: venue.receiptTagline,
        social: venue.receiptSocial,
        thankYou: venue.receiptThankYou,
        address: venue.address,
        phone: venue.phone,
        logoBytes: logoBytes,
        qrUrl: venue.receiptQrUrl,
        qrCaption: venue.receiptQrCaption,
        tableLabel: bill.tableLabel ?? bill.tableId,
        pax: bill.pax,
        guestName: bill.guestName ?? '',
        at: DateTime.now(),
        kind: BillDocKind.wholeBill,
        lines: [
          for (final l in bill.lines)
            if (l.status != 'voided')
              BillStrukLine(
                qty: l.qty,
                name: l.name,
                variant: l.variantName,
                lineTotal: l.lineTotal,
                modifiers: [for (final m in l.modifiers) m.display],
                note: l.note ?? '',
              ),
        ],
        subtotal: bill.subtotal,
        serviceAmount: bill.serviceAmount,
        taxAmount: bill.taxAmount,
        total: bill.total,
        billTotal: bill.total,
        payments: _payments(pays),
        paidNet: bill.paidAmount,
        tenderedTotal: _tendered(pays),
        outstanding: bill.outstanding,
      );
    }

    final even = receipt.mode == 'even';
    final lines = even
        ? [
            for (final l in bill.lines)
              if (l.status != 'voided')
                BillStrukLine(
                  qty: l.qty,
                  name: l.name,
                  showPrice: false,
                  modifiers: [for (final m in l.modifiers) m.display],
                ),
          ]
        : _receiptLines(bill, receipt);
    return BillStrukData(
      venueName: venue.displayName,
      header: venue.receiptHeader,
      footer: venue.receiptFooter,
      tagline: venue.receiptTagline,
      social: venue.receiptSocial,
      thankYou: venue.receiptThankYou,
      address: venue.address,
      phone: venue.phone,
      logoBytes: logoBytes,
      qrUrl: venue.receiptQrUrl,
      qrCaption: venue.receiptQrCaption,
      tableLabel: bill.tableLabel ?? bill.tableId,
      pax: bill.pax,
      guestName: bill.guestName ?? '',
      at: DateTime.now(),
      kind: even ? BillDocKind.evenReceipt : BillDocKind.itemizedReceipt,
      docLabel: receipt.label,
      lines: lines,
      subtotal: receipt.subtotal,
      serviceAmount: receipt.serviceAmount,
      taxAmount: receipt.taxAmount,
      total: receipt.total,
      billTotal: bill.total,
      payments: _payments(receipt.payments),
      paidNet: receipt.paidNet,
      tenderedTotal: _tendered(receipt.payments),
      outstanding: receipt.outstanding,
    );
  }

  static List<BillStrukLine> _receiptLines(Bill bill, BillReceipt receipt) {
    final byTicket = {for (final l in bill.lines) l.ticketId: l};
    final out = <BillStrukLine>[];
    for (final rl in receipt.lines) {
      final l = byTicket[rl.ticketId];
      if (l == null || rl.qtyUnits <= 0) continue;
      out.add(BillStrukLine(
        qty: rl.qtyUnits,
        name: l.name,
        variant: l.variantName,
        lineTotal: l.unitPrice * rl.qtyUnits,
        modifiers: [for (final m in l.modifiers) m.display],
        note: l.note ?? '',
      ));
    }
    return out;
  }

  static List<BillStrukPayment> _payments(List<BillPayment> pays) => [
        for (final p in pays)
          BillStrukPayment(
            methodLabel: _label(p.method),
            amount: p.amount,
            tendered: p.tendered,
            isRefund: p.isRefund,
          ),
      ];

  static int? _tendered(List<BillPayment> pays) {
    var sum = 0;
    for (final p in pays) {
      if (!p.isRefund && p.tendered != null) sum += p.tendered!;
    }
    return sum > 0 ? sum : null;
  }

  /// Parse a line's frozen modifier snapshot (raw `modifiersJson`, a JSON string
  /// or already-decoded list) into signed display labels, matching
  /// [TicketModifier.display] so server- and client-built docs print the same.
  static List<String> _modLabels(Object? raw) {
    final decoded = raw is String
        ? (raw.trim().isEmpty ? const [] : jsonDecode(raw))
        : raw;
    if (decoded is! List) return const [];
    final out = <String>[];
    for (final m in decoded) {
      if (m is! Map) continue;
      final label = (m['label'] as String?) ?? '';
      final delta = (m['priceDelta'] as num?)?.toInt() ?? 0;
      out.add(delta > 0 ? '+ $label' : (delta < 0 ? '− $label' : label));
    }
    return out;
  }

  // ── server: from the raw settlement bill map (see _buildBill) ──

  static BillStrukData fromServerMap({
    required Map<String, dynamic> bill,
    String? receiptId,
    required String venueName,
    String header = '',
    String footer = '',
    String tagline = '',
    String social = '',
    String thankYou = '',
    String address = '',
    String phone = '',
    List<int>? logoBytes,
    String qrUrl = '',
    String qrCaption = '',
  }) {
    int n(Object? v) => (v as num?)?.toInt() ?? 0;
    final billLines = (bill['lines'] as List).cast<Map>();
    final receipts = (bill['receipts'] as List).cast<Map>();
    final tableLabel = (bill['tableLabel'] as String?) ?? (bill['tableId'] as String);
    final pax = n(bill['pax']);
    final guestName = (bill['guestName'] as String?) ?? '';
    final billTotal = n(bill['total']);

    List<BillStrukPayment> mapPays(List pays) => [
          for (final p in pays.cast<Map>())
            BillStrukPayment(
              methodLabel: _label((p['method'] as String?) ?? 'tunai'),
              amount: n(p['amount']),
              tendered: (p['tendered'] as num?)?.toInt(),
              isRefund: p['isRefund'] as bool? ?? false,
            ),
        ];
    int? mapTendered(List pays) {
      var sum = 0;
      for (final p in pays.cast<Map>()) {
        if ((p['isRefund'] as bool? ?? false)) continue;
        final t = (p['tendered'] as num?)?.toInt();
        if (t != null) sum += t;
      }
      return sum > 0 ? sum : null;
    }

    if (receiptId == null) {
      final allPays = [for (final r in receipts) ...(r['payments'] as List)];
      return BillStrukData(
        venueName: venueName,
        header: header,
        footer: footer,
        tagline: tagline,
        social: social,
        thankYou: thankYou,
        address: address,
        phone: phone,
        logoBytes: logoBytes,
        qrUrl: qrUrl,
        qrCaption: qrCaption,
        tableLabel: tableLabel,
        pax: pax,
        guestName: guestName,
        at: DateTime.now(),
        kind: BillDocKind.wholeBill,
        lines: [
          for (final l in billLines)
            if ((l['status'] as String?) != 'voided')
              BillStrukLine(
                qty: n(l['qty']),
                name: (l['name'] as String?) ?? '',
                variant: (l['variantName'] as String?) ?? '',
                lineTotal: n(l['lineTotal']),
                modifiers: _modLabels(l['modifiersJson']),
                note: (l['note'] as String?) ?? '',
              ),
        ],
        subtotal: n(bill['subtotal']),
        serviceAmount: n(bill['serviceAmount']),
        taxAmount: n(bill['taxAmount']),
        total: billTotal,
        billTotal: billTotal,
        payments: mapPays(allPays),
        paidNet: n(bill['paidAmount']),
        tenderedTotal: mapTendered(allPays),
        outstanding: n(bill['outstanding']),
      );
    }

    final rec = receipts.firstWhere((r) => r['id'] == receiptId,
        orElse: () => const {});
    final even = (rec['mode'] as String?) == 'even';
    final byTicket = {for (final l in billLines) l['ticketId'] as String: l};
    final lines = even
        ? [
            for (final l in billLines)
              if ((l['status'] as String?) != 'voided')
                BillStrukLine(
                    qty: n(l['qty']),
                    name: (l['name'] as String?) ?? '',
                    showPrice: false,
                    modifiers: _modLabels(l['modifiersJson'])),
          ]
        : [
            for (final rl in (rec['lines'] as List? ?? const []).cast<Map>())
              if (byTicket[rl['ticketId']] != null && n(rl['qtyUnits']) > 0)
                BillStrukLine(
                  qty: n(rl['qtyUnits']),
                  name: (byTicket[rl['ticketId']]!['name'] as String?) ?? '',
                  variant:
                      (byTicket[rl['ticketId']]!['variantName'] as String?) ?? '',
                  lineTotal: n(byTicket[rl['ticketId']]!['unitPrice']) *
                      n(rl['qtyUnits']),
                  modifiers:
                      _modLabels(byTicket[rl['ticketId']]!['modifiersJson']),
                  note: (byTicket[rl['ticketId']]!['note'] as String?) ?? '',
                ),
          ];
    final recTotal = n(rec['total']);
    final recPaid = n(rec['paidNet']);
    final pays = (rec['payments'] as List? ?? const []);
    return BillStrukData(
      venueName: venueName,
      header: header,
      footer: footer,
      tagline: tagline,
      social: social,
      thankYou: thankYou,
      address: address,
      phone: phone,
      logoBytes: logoBytes,
      qrUrl: qrUrl,
      qrCaption: qrCaption,
      tableLabel: tableLabel,
      pax: pax,
      guestName: guestName,
      at: DateTime.now(),
      kind: even ? BillDocKind.evenReceipt : BillDocKind.itemizedReceipt,
      docLabel: (rec['label'] as String?) ?? '',
      lines: lines,
      subtotal: n(rec['subtotal']),
      serviceAmount: n(rec['serviceAmount']),
      taxAmount: n(rec['taxAmount']),
      total: recTotal,
      billTotal: billTotal,
      payments: mapPays(pays),
      paidNet: recPaid,
      tenderedTotal: mapTendered(pays),
      outstanding: (recTotal - recPaid).clamp(0, 1 << 31),
    );
  }
}
