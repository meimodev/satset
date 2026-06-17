/// Transport-agnostic description of the venue's MONEY document — the
/// [[Tagihan / Struk pembayaran]]. Built identically on the server (from the
/// settlement bill map) and on a client (from the typed `Bill`), then handed to
/// the shared [BillStrukRenderer] so the printed bytes match whoever transmits.
/// See docs/adr/0023-two-phase-settlement-and-split-bills.md and ADR-0020.
///
/// Unlike [StrukData] (a no-money order-confirmation slip), this CARRIES money:
/// priced lines, tax/service, totals and — once paid — a payment block. The
/// SAME shape renders two states, picked purely from [payments]:
///   • empty   → **Tagihan** (no payment block)
///   • present → **Struk pembayaran** (+ method / tendered / change / sisa)
library;

/// Which granularity / shape of money document this is.
enum BillDocKind {
  /// The whole table's tab — every sent line, the grand total.
  wholeBill,

  /// One itemized split receipt — only the lines assigned to it.
  itemizedReceipt,

  /// One even-split share — a flat amount plus a compact reference list of the
  /// whole bill's items (the share owns no specific items). See ADR-0023.
  evenReceipt,
}

/// One priced line on a money document. Carries the chosen [modifiers] (signed
/// display labels, frozen at order time) and the guest's [note] (Instruksi
/// khusus) so the bill doubles as an order check — the guest can verify exactly
/// what was ordered, not just the totals. Especially load-bearing for takeaway,
/// whose only printout is this money doc. See ADR-0026.
class BillStrukLine {
  final int qty;
  final String name;
  final String variant; // '' when none
  final int lineTotal;
  final bool showPrice; // false for even-split reference lines
  final List<String> modifiers; // signed display labels, e.g. '+ Pedas'
  final String note; // item note (Instruksi khusus); '' when none

  const BillStrukLine({
    required this.qty,
    required this.name,
    this.variant = '',
    this.lineTotal = 0,
    this.showPrice = true,
    this.modifiers = const [],
    this.note = '',
  });
}

/// One recorded payment, rendered in the payment block. [amount] is negative
/// for a refund.
class BillStrukPayment {
  final String methodLabel;
  final int amount;
  final int? tendered; // cash given, when known
  final bool isRefund;

  const BillStrukPayment({
    required this.methodLabel,
    required this.amount,
    this.tendered,
    this.isRefund = false,
  });
}

class BillStrukData {
  // ── venue header / branding (ADR-0033) ──
  final String venueName;
  final String header; // receiptHeader, may be ''
  final String footer; // receiptFooter, may be ''
  final String tagline; // short slogan under the venue name, may be ''
  final String social; // website / social handle line, may be ''
  final String thankYou; // closing sign-off; '' ⇒ "Terima kasih"
  final String address;
  final String phone;
  final List<int>? logoBytes; // optional logo, raw JPEG; centred + monochrome
  // Footer QR — money docs only. Empty url ⇒ no QR.
  final String qrUrl;
  final String qrCaption;

  // ── identity ──
  final String tableLabel;
  final int pax;
  final String guestName; // '' when none
  final DateTime at;
  final BillDocKind kind;
  final String docLabel; // receipt label ('Tamu 1' / 'Bagian 1/3'); '' for whole

  // ── body ──
  final List<BillStrukLine> lines;

  // ── money ──
  final int subtotal;
  final int serviceAmount;
  final int taxAmount;
  final int total; // what THIS document owes (receipt share or whole bill)
  final int billTotal; // whole-bill total — shown as reference on even shares

  // ── payment block (empty ⇒ Tagihan) ──
  final List<BillStrukPayment> payments;
  final int paidNet; // sum of payments, net of refunds
  final int? tenderedTotal; // cash tendered across cash payments, when any
  final int outstanding;

  const BillStrukData({
    required this.venueName,
    this.header = '',
    this.footer = '',
    this.tagline = '',
    this.social = '',
    this.thankYou = '',
    this.address = '',
    this.phone = '',
    this.logoBytes,
    this.qrUrl = '',
    this.qrCaption = '',
    required this.tableLabel,
    required this.pax,
    this.guestName = '',
    required this.at,
    required this.kind,
    this.docLabel = '',
    required this.lines,
    required this.subtotal,
    required this.serviceAmount,
    required this.taxAmount,
    required this.total,
    required this.billTotal,
    this.payments = const [],
    this.paidNet = 0,
    this.tenderedTotal,
    this.outstanding = 0,
  });

  /// Tagihan (pre-payment) when no payment has been recorded yet.
  bool get isTagihan => payments.isEmpty;
  bool get isEven => kind == BillDocKind.evenReceipt;
}
