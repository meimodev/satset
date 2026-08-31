import 'dart:convert';

import 'package:satset/core/localization/labels.dart';
import 'package:satset/core/printing/bill_struk_data.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/core/time/sat_clock.dart';

/// Assembles a [BillStrukData] for the MONEY document from either source — the
/// typed [Bill] on a client, or the raw settlement bill map on the server —
/// producing the SAME shape so the shared [BillStrukRenderer] prints identically
/// (ADR-0023 / ADR-0020).
///
/// `receipt`/`receiptId` null ⇒ the whole-bill document; otherwise a single
/// split receipt. The Tagihan-vs-Struk-pembayaran state is decided downstream
/// purely by whether the assembled doc carries payments.
class BillStrukBuilder {
  // ── client: from the typed Bill ──

  /// The [[Piutang]] collection slip (ADR-0098). No bill, no lines, no table —
  /// a member walked in and paid down a tab, and this is the only evidence they
  /// leave with. Built here rather than at the call site so the venue identity
  /// block stays one shape across every money document.
  static BillStrukData debtCollection({
    required AppL10n l,
    required VenueSettingsDto venue,
    required String memberName,
    required int amount,
    required String method,
    required int balanceAfter,
    required String cashierName,
    List<int>? logoBytes,
    DateTime? at,
  }) => BillStrukData(
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
    tableLabel: '',
    pax: 0,
    memberName: memberName,
    at: at ?? SatClock.now(),
    kind: BillDocKind.debtCollection,
    lines: const [],
    subtotal: amount,
    serviceAmount: 0,
    taxAmount: 0,
    total: amount,
    billTotal: amount,
    payments: [
      BillStrukPayment(
        methodLabel: paymentMethodLabel(l, method),
        amount: amount,
      ),
    ],
    paidNet: amount,
    debtBalanceAfter: balanceAfter,
    cashierName: cashierName,
  );

  /// [pendingSync] means this slip is being printed off a projection the host
  /// has not taken yet (ADR-0123). The money is the till's own arithmetic and
  /// is correct; the **[[Poin]] and stempel figures are not** — the host
  /// recomputes both at bill close, so printing the last-synced numbers hands
  /// the guest a balance they can photograph and argue from next week. The
  /// block is omitted rather than guessed.
  static BillStrukData fromBill({
    required AppL10n l,
    required Bill bill,
    BillReceipt? receipt,
    required VenueSettingsDto venue,
    List<int>? logoBytes,
    bool pendingSync = false,
  }) {
    if (receipt == null) {
      // Whole-bill: every sent line, the grand total, aggregate payments.
      final pays = [for (final r in bill.receipts) ...r.payments];
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
        memberName: bill.member?.name ?? '',
        memberPoints: pendingSync ? 0 : (bill.member?.points ?? 0),
        memberPunch: (pendingSync || bill.member == null)
            ? ''
            : punchText(
                bill.member!.member.punchProgress,
                bill.member!.punchTarget,
              ),
        at: SatClock.now(),
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
        // Whole-bill doc: the give-back may span several receipts, so it is
        // named only when exactly one order discount exists across the bill.
        receiptOwners: _receiptOwners(bill),
        discountLabel: _wholeBillDiscountLabel(bill),
        discountAmount: bill.discountAmount,
        taxAfterDiscount: bill.taxAfterDiscount,
        serviceAmount: bill.serviceAmount,
        taxAmount: bill.taxAmount,
        total: bill.total,
        billTotal: bill.total,
        payments: _payments(l, pays),
        paidNet: bill.paidAmount,
        tenderedTotal: _tendered(pays),
        outstanding: bill.outstanding,
      );
    }

    final who = receipt.member ?? bill.member;
    final orderDiscounts = [
      for (final d in receipt.discounts)
        if (!d.isLine) d,
    ];
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
      // The [[Pemilik struk]] when this share names one, the [[Pemilik tagihan]]
      // otherwise (ADR-0118). The slip is the one artefact a guest takes home,
      // so it must carry *their* standing, not the party host's.
      memberName: who?.name ?? '',
      memberPoints: pendingSync ? 0 : (who?.points ?? 0),
      memberPunch: who == null
          ? ''
          : (pendingSync
                ? ''
                : punchText(who.member.punchProgress, who.punchTarget)),
      at: SatClock.now(),
      kind: even ? BillDocKind.evenReceipt : BillDocKind.itemizedReceipt,
      // "Tamu A", not a bare "A" — the guest reads this line to know the slip
      // in their hand is theirs. A part spec reads as "Bagian 1/3"; anything
      // else passes through.
      docLabel: receiptTitle(l, receipt.label),
      lines: lines,
      subtotal: receipt.subtotal,
      // Every order-scope give-back, not just the cashier's: since ADR-0118 a
      // share can carry a manual discount, the member's tier discount and a
      // redemption at once, and printing only the first is a slip whose
      // arithmetic does not reach its own total. Named only when there is one,
      // for the reason `_wholeBillDiscountLabel` gives.
      discountLabel: orderDiscounts.length == 1
          ? orderDiscounts.first.label
          : '',
      discountAmount: orderDiscounts.fold(0, (a, d) => a + d.amount),
      taxAfterDiscount: bill.taxAfterDiscount,
      serviceAmount: receipt.serviceAmount,
      taxAmount: receipt.taxAmount,
      total: receipt.total,
      billTotal: bill.total,
      payments: _payments(l, receipt.payments),
      paidNet: receipt.paidNet,
      tenderedTotal: _tendered(receipt.payments),
      outstanding: receipt.outstanding,
    );
  }

  /// The **[[Rincian pilihan]]** — the tapped-but-not-yet-minted Per item
  /// selection, printed so the guest can check "these are mine" before any
  /// money moves (ADR-0122).
  ///
  /// Ephemeral: nothing is minted, so the doc carries no payments and therefore
  /// renders as a Tagihan by the ordinary rule. It reuses
  /// [BillDocKind.itemizedReceipt] because that is exactly its shape — only the
  /// [docLabel] says it is provisional, which is the one thing a reader must
  /// not mistake.
  ///
  /// [selection] is `ticketId → units`, the map the settle pane holds.
  static BillStrukData fromSelection({
    required AppL10n l,
    required Bill bill,
    required Map<String, int> selection,
    required VenueSettingsDto venue,
    List<int>? logoBytes,
  }) {
    final lines = <BillStrukLine>[];
    var subtotal = 0;
    for (final line in bill.lines) {
      if (line.status == 'voided') continue;
      final units = selection[line.ticketId] ?? 0;
      if (units <= 0) continue;
      final lineTotal = line.unitPrice * units;
      subtotal += lineTotal;
      lines.add(
        BillStrukLine(
          qty: units,
          name: line.name,
          variant: line.variantName,
          lineTotal: lineTotal,
          modifiers: [for (final m in line.modifiers) m.display],
          note: line.note ?? '',
        ),
      );
    }

    // The total is the bill's own prorate — the same call the confirm button
    // makes — and service/tax are then split so the three rows add up to it.
    // Prorating all three independently would print arithmetic off by a rupiah.
    final total = bill.prorate(subtotal);
    var service = _shareOf(bill.serviceAmount, subtotal, bill.subtotal);
    var tax = _shareOf(bill.taxAmount, subtotal, bill.subtotal);
    final residual = total - subtotal - service - tax;
    if (tax > 0) {
      tax += residual;
    } else if (service > 0) {
      service += residual;
    }

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
      memberName: bill.member?.name ?? '',
      memberPoints: bill.member?.points ?? 0,
      memberPunch: bill.member == null
          ? ''
          : punchText(
              bill.member!.member.punchProgress,
              bill.member!.punchTarget,
            ),
      at: SatClock.now(),
      kind: BillDocKind.itemizedReceipt,
      docLabel: l.printSelectionDocLabel,
      lines: lines,
      subtotal: subtotal,
      // No receipt exists yet, so no give-back can be attached to one. A bill
      // discount applied later only makes the guest's share smaller than this
      // quote, which is the harmless direction.
      taxAfterDiscount: bill.taxAfterDiscount,
      serviceAmount: service,
      taxAmount: tax,
      total: total,
      billTotal: bill.total,
      outstanding: total,
    );
  }

  /// `part / whole` of [amount], rounded — 0 when the bill has no subtotal to
  /// divide by.
  static int _shareOf(int amount, int part, int whole) {
    if (amount <= 0 || part <= 0 || whole <= 0) return 0;
    return (amount * part / whole).round();
  }

  static List<BillStrukLine> _receiptLines(Bill bill, BillReceipt receipt) {
    final byTicket = {for (final l in bill.lines) l.ticketId: l};
    final out = <BillStrukLine>[];
    for (final rl in receipt.lines) {
      final l = byTicket[rl.ticketId];
      if (l == null || rl.qtyUnits <= 0) continue;
      final ld = receipt.lineDiscount(rl.ticketId);
      out.add(
        BillStrukLine(
          qty: rl.qtyUnits,
          name: l.name,
          variant: l.variantName,
          lineTotal: l.unitPrice * rl.qtyUnits,
          modifiers: [for (final m in l.modifiers) m.display],
          note: l.note ?? '',
          discountLabel: ld?.label ?? '',
          discountAmount: ld?.amount ?? 0,
        ),
      );
    }
    return out;
  }

  /// One composed line per share on a split the [[Pemilik struk]] mode named —
  /// `'A · Budi'` — and an empty list otherwise, which is every bill at a venue
  /// that never held the mode.
  ///
  /// A share nobody named is skipped rather than printed blank: its money is
  /// the bill owner's, and the header already says who that is.
  static List<String> _receiptOwners(Bill bill) {
    if (!bill.splitEnabled) return const [];
    return [
      for (final r in bill.receipts)
        if (r.member != null) '${r.label} · ${r.member!.name}',
    ];
  }

  /// Name the whole-bill Diskon row only when the bill carries exactly one
  /// order discount. With several receipts discounted differently there is no
  /// single honest label, so it falls back to a plain "Diskon" total.
  static String _wholeBillDiscountLabel(Bill bill) {
    final named = [
      for (final r in bill.receipts)
        if (r.orderDiscount != null) r.orderDiscount!,
    ];
    return named.length == 1 ? named.first.label : '';
  }

  static List<BillStrukPayment> _payments(AppL10n l, List<BillPayment> pays) =>
      [
        for (final p in pays)
          BillStrukPayment(
            methodLabel: paymentMethodLabel(l, p.method),
            amount: p.amount,
            tendered: p.tendered,
            isRefund: p.isRefund,
          ),
      ];

  /// Punch progress as the card reads it — `'3/10'`, or '' when the venue runs
  /// no punch program. Built once here so the client and the server print the
  /// same string rather than each inventing a separator.
  static String punchText(int progress, int target) =>
      target <= 0 ? '' : '$progress/$target';

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
    required AppL10n l,
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
    final tableLabel =
        (bill['tableLabel'] as String?) ?? (bill['tableId'] as String);
    final pax = n(bill['pax']);
    final guestName = (bill['guestName'] as String?) ?? '';
    final billTotal = n(bill['total']);
    final member = bill['member'] as Map?;
    final memberName = (member?['name'] as String?) ?? '';
    final memberPoints = n(member?['points']);
    final memberPunch = member == null
        ? ''
        : punchText(n(member['punchProgress']), n(member['punchTarget']));

    List<BillStrukPayment> mapPays(List pays) => [
      for (final p in pays.cast<Map>())
        BillStrukPayment(
          methodLabel: paymentMethodLabel(
            l,
            (p['method'] as String?) ?? 'tunai',
          ),
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

    // Discount rows carried on a receipt map. Rendered from the SNAPSHOTTED
    // name/kind/value, never the live preset (ADR-0037).
    List<Map> discountsOf(Map r) =>
        (r['discounts'] as List? ?? const []).cast<Map>();
    String discountLabel(Map d) {
      final name = (d['name'] as String?) ?? l.strukDiscount;
      if ((d['kind'] as String?) != 'percent') return name;
      return '$name ${(n(d['value']) / 100).toStringAsFixed(0)}%';
    }

    List<Map> orderDiscountsOf(Map r) => [
      for (final d in discountsOf(r))
        if (d['ticketId'] == null) d,
    ];

    /// The cashier's own, for the whole-bill label — since ADR-0118 the other
    /// two slots belong to the member, and naming a bill after someone's tier
    /// discount reads as the venue's promotion.
    Map? manualDiscountOf(Map r) {
      for (final d in orderDiscountsOf(r)) {
        if (((d['source'] as String?) ?? 'manual') == 'manual') return d;
      }
      return null;
    }

    Map? lineDiscountOf(Map r, Object? ticketId) {
      for (final d in discountsOf(r)) {
        if (d['ticketId'] == ticketId) return d;
      }
      return null;
    }

    final taxAfterDiscount = (bill['taxAfterDiscount'] as bool?) ?? true;

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
        memberName: memberName,
        memberPoints: memberPoints,
        memberPunch: memberPunch,
        receiptOwners: (bill['splitEnabled'] as bool?) != true
            ? const []
            : [
                for (final r in receipts)
                  if ((r['member'] as Map?)?['name'] != null)
                    '${(r['label'] as String?) ?? ''} · '
                        '${(r['member'] as Map)['name']}',
              ],
        at: SatClock.now(),
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
        // Named only when the whole bill carries exactly one order discount —
        // several differently-discounted receipts have no single honest label.
        discountLabel: () {
          final named = [
            for (final r in receipts)
              if (manualDiscountOf(r) != null) manualDiscountOf(r)!,
          ];
          return named.length == 1 ? discountLabel(named.first) : '';
        }(),
        discountAmount: n(bill['discountAmount']),
        taxAfterDiscount: taxAfterDiscount,
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

    final rec = receipts.firstWhere(
      (r) => r['id'] == receiptId,
      orElse: () => const {},
    );
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
                  modifiers: _modLabels(l['modifiersJson']),
                ),
          ]
        : [
            for (final rl in (rec['lines'] as List? ?? const []).cast<Map>())
              if (byTicket[rl['ticketId']] != null && n(rl['qtyUnits']) > 0)
                BillStrukLine(
                  qty: n(rl['qtyUnits']),
                  name: (byTicket[rl['ticketId']]!['name'] as String?) ?? '',
                  variant:
                      (byTicket[rl['ticketId']]!['variantName'] as String?) ??
                      '',
                  lineTotal:
                      n(byTicket[rl['ticketId']]!['unitPrice']) *
                      n(rl['qtyUnits']),
                  modifiers: _modLabels(
                    byTicket[rl['ticketId']]!['modifiersJson'],
                  ),
                  note: (byTicket[rl['ticketId']]!['note'] as String?) ?? '',
                  discountLabel: lineDiscountOf(rec, rl['ticketId']) == null
                      ? ''
                      : discountLabel(lineDiscountOf(rec, rl['ticketId'])!),
                  discountAmount: n(
                    lineDiscountOf(rec, rl['ticketId'])?['amount'],
                  ),
                ),
          ];
    final recTotal = n(rec['total']);
    final recPaid = n(rec['paidNet']);
    final pays = (rec['payments'] as List? ?? const []);
    // The [[Pemilik struk]] when this share names one, the bill's owner
    // otherwise (ADR-0118) — the slip carries the standing of whoever it is
    // for, not the party host's.
    final recMember = (rec['member'] as Map?) ?? member;
    final recOrderDiscounts = orderDiscountsOf(rec);
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
      memberName: (recMember?['name'] as String?) ?? '',
      memberPoints: n(recMember?['points']),
      memberPunch: recMember == null
          ? ''
          : punchText(
              n(recMember['punchProgress']),
              n(recMember['punchTarget']),
            ),
      at: SatClock.now(),
      kind: even ? BillDocKind.evenReceipt : BillDocKind.itemizedReceipt,
      docLabel: receiptTitle(l, (rec['label'] as String?) ?? ''),
      lines: lines,
      subtotal: n(rec['subtotal']),
      // Every order-scope give-back, not just the first: a share can carry a
      // manual discount, a member's tier discount and a redemption at once
      // (ADR-0118), and printing one of three is a slip that does not add up.
      discountLabel: recOrderDiscounts.length == 1
          ? discountLabel(recOrderDiscounts.first)
          : '',
      discountAmount: recOrderDiscounts.fold<int>(
        0,
        (a, d) => a + n(d['amount']),
      ),
      taxAfterDiscount: taxAfterDiscount,
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
