import 'dart:async';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/l10n/app_localizations.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'package:satset/core/printing/bill_struk_builder.dart';
import 'package:satset/core/printing/bill_struk_renderer.dart';
import 'package:satset/ui/features/printing/receipt_preview.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/core/printing/struk_builder.dart';
import 'package:satset/core/printing/struk_renderer.dart';
import 'package:satset/core/printing/struk_socket.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/models/device_printer.dart';
import 'package:satset/data/models/printer_dto.dart';
import 'package:satset/data/repositories/printers_repository.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/services/settlement_sync.dart';
import 'package:satset/data/services/bt_printer_service.dart';
import 'package:satset/data/services/printer_discovery_service.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';

const _uuid = Uuid();

/// Window a venue printer counts "online" after its last server heartbeat.
/// Coupled to the 15s server tick (≤2 missed ticks). See ADR-0022.
const _venueOnlineWindow = Duration(seconds: 30);

/// Guest documents load a preview after printer selection. Utility jobs such
/// as QR cards retain direct rendering and sending.
class PrintJob {
  final String subtitle; // shown under "Pilih printer"
  final Future<List<int>> Function()? renderBytes;
  final Future<PreparedReceipt> Function()? preview;
  final bool Function()? offline;

  const PrintJob({
    required this.subtitle,
    this.renderBytes,
    this.preview,
    this.offline,
  });
}

Future<void> _openPicker(BuildContext context, PrintJob job) =>
    showSatSheet<void>(
      context,
      bare: true,
      builder: (_) => _PrinterPickerSheet(job: job),
    );

/// One reusable entry point for "Cetak struk meja" (the no-money order slip).
/// Validates the table has printable lines, then opens the picker, which
/// auto-discovers reachable printers (venue + device, wifi + Bluetooth) and
/// lists only the online ones. See ADR-0020 / ADR-0022.
Future<void> printTableStruk({
  required BuildContext context,
  required WidgetRef ref,
  required VenueTable table,
  required List<Ticket> tickets,
}) async {
  final l = context.l10n;
  final printable = tickets
      .where((t) => t.status != TicketStatus.voided)
      .toList();
  if (printable.isEmpty) {
    _toast(context, l.prnNothingToPrint);
    return;
  }
  final at = SatClock.now();
  var offline = false;
  Future<PreparedReceipt> load() async {
    offline = ref.read(wsConnStateProvider) != WsConnState.open;
    if (!offline) {
      try {
        await ref.read(tablesProvider.notifier).refreshForPrinting();
        await ref.read(ticketsProvider.notifier).refreshForPrinting();
      } catch (_) {
        offline = true;
      }
    }
    final current = ref
        .read(tablesProvider)
        .where((t) => t.id == table.id)
        .firstOrNull;
    if (current == null || current.currentVisitId != table.currentVisitId) {
      throw StateError('The table visit is no longer available');
    }
    final lines = ref
        .read(ticketsForTableProvider(table.id))
        .where((t) => t.status != TicketStatus.voided)
        .toList();
    if (lines.isEmpty) throw StateError('No printable lines');
    final venue = ref.read(venueSettingsProvider);
    final logo = await ref.read(venueLogoBytesProvider(venue.logoRev).future);
    final g = ReceiptPreviewGenerator(
      PaperSize.mm58,
      await CapabilityProfile.load(),
    );
    final bytes = await StrukRenderer.render(
      l,
      StrukBuilder.fromTable(
        venue: venue,
        tableLabel: current.displayName,
        pax: current.pax,
        guestName: current.guestName ?? '',
        guestNote: current.guestNotes ?? '',
        tickets: lines,
        logoBytes: logo,
        at: at,
      ),
      generator: g,
      printedAt: at,
    );
    return PreparedReceipt(bytes, g.children);
  }

  await _openPicker(
    context,
    PrintJob(subtitle: l.printJobOrderSlip(table.displayName), preview: load),
  );
}

/// Entry point for the cashier's MONEY document. `receipt` null prints the
/// whole-bill doc; otherwise one split receipt. Tagihan vs Struk pembayaran is
/// decided by whether payments exist (auto). See ADR-0023.
Future<void> printBillStruk({
  required BuildContext context,
  required WidgetRef ref,
  required Bill bill,
  BillReceipt? receipt,
}) async {
  final l = context.l10n;
  final hasLines = bill.lines.any((x) => x.status != 'voided');
  if (!hasLines) {
    _toast(context, l.prnNothingToPrint);
    return;
  }
  final paid = receipt == null
      ? bill.paidAmount > 0
      : receipt.payments.isNotEmpty;
  final who = receipt == null
      ? l.expTableVisit(bill.tableLabel ?? '').trim()
      : (receipt.label.isEmpty ? l.printWhoReceipt : receipt.label);
  final subtitle = paid ? l.printJobReceiptDoc(who) : l.printJobBillDoc(who);
  final at = SatClock.now();
  var offline = false;
  await _openPicker(
    context,
    PrintJob(
      subtitle: subtitle,
      offline: () => offline,
      preview: () async {
        final fresh = await ref
            .read(settlementProvider.notifier)
            .fetchBillForPrinting(bill.visitId);
        final current = fresh.bill;
        offline = fresh.offline;
        final share = receipt == null
            ? null
            : current.receipts.where((r) => r.id == receipt.id).firstOrNull;
        if ((receipt != null && share == null) ||
            !current.lines.any((x) => x.status != 'voided')) {
          throw StateError('The receipt is no longer available');
        }
        final venue = ref.read(venueSettingsProvider);
        final logo = await ref.read(
          venueLogoBytesProvider(venue.logoRev).future,
        );
        final data = BillStrukBuilder.fromBill(
          l: l,
          bill: current,
          receipt: share,
          venue: venue,
          logoBytes: logo,
          pendingSync: ref
              .read(settlementJournalProvider)
              .isLocal(bill.visitId),
          at: at,
        );
        final g = ReceiptPreviewGenerator(
          PaperSize.mm58,
          await CapabilityProfile.load(),
        );
        final bytes = await BillStrukRenderer.render(
          l,
          data,
          generator: g,
          printedAt: at,
        );
        return PreparedReceipt(bytes, g.children);
      },
    ),
  );
}

/// The **[[Rincian pilihan]]** (ADR-0122) — the Per item selection a cashier
/// has tapped but not yet minted into a receipt, so the guest can check the
/// lines before paying.
///
/// Deliberately NOT a `receipt` argument on [printBillStruk]: that function's
/// contract is "null ⇒ whole bill, else one receipt", and a third meaning
/// inside it is what makes the next reader guess. Printing persists nothing.
Future<void> printBillSelection({
  required BuildContext context,
  required WidgetRef ref,
  required Bill bill,
  required Map<String, int> selection,

  /// The line give-backs the till already has off the quote (ADR-0126), as
  /// `ticketId → (label, amount)`. Printing without them hands the guest a
  /// bigger number than the confirm button shows.
  Map<String, ({String label, int amount})> pending = const {},
}) async {
  final l = context.l10n;
  final at = SatClock.now();
  var offline = false;
  final subtitle = l.printJobSelectionDoc(bill.tableLabel ?? '');
  await _openPicker(
    context,
    PrintJob(
      subtitle: subtitle,
      offline: () => offline,
      preview: () async {
        final fresh = await ref
            .read(settlementProvider.notifier)
            .fetchBillForPrinting(bill.visitId);
        final current = fresh.bill;
        offline = fresh.offline;
        final venue = ref.read(venueSettingsProvider);
        final logo = await ref.read(
          venueLogoBytesProvider(venue.logoRev).future,
        );
        final data = BillStrukBuilder.fromSelection(
          l: l,
          bill: current,
          selection: {
            for (final line in current.lines)
              if ((selection[line.ticketId] ?? 0) > 0)
                line.ticketId: selection[line.ticketId]!.clamp(
                  0,
                  line.unassignedUnits,
                ),
          },
          venue: venue,
          pending: pending,
          logoBytes: logo,
          at: at,
        );
        if (data.lines.isEmpty) throw StateError('No printable lines');
        final g = ReceiptPreviewGenerator(
          PaperSize.mm58,
          await CapabilityProfile.load(),
        );
        final bytes = await BillStrukRenderer.render(
          l,
          data,
          generator: g,
          printedAt: at,
        );
        return PreparedReceipt(bytes, g.children);
      },
    ),
  );
}

/// The [[Piutang]] collection slip (ADR-0098). Same pick-then-preview flow as
/// the bill doc, and the same renderer — this is a money document, and the one
/// where the guest holds no other evidence that they paid.
Future<void> printDebtSlip({
  required BuildContext context,
  required WidgetRef ref,
  required String memberName,
  required int amount,
  required String method,
  required int balanceAfter,
}) async {
  final l = context.l10n;
  final venue = ref.read(venueSettingsProvider);
  final logo = await ref.read(venueLogoBytesProvider(venue.logoRev).future);
  final data = BillStrukBuilder.debtCollection(
    l: l,
    venue: venue,
    memberName: memberName,
    amount: amount,
    method: method,
    balanceAfter: balanceAfter,
    cashierName: ref.read(authStateProvider).user?.name ?? '',
    logoBytes: logo,
  );
  if (!context.mounted) return;
  final subtitle = l.strukDebtTitle;
  final at = SatClock.now();
  await _openPicker(
    context,
    PrintJob(
      subtitle: subtitle,
      preview: () async {
        final g = ReceiptPreviewGenerator(
          PaperSize.mm58,
          await CapabilityProfile.load(),
        );
        final bytes = await BillStrukRenderer.render(
          l,
          data,
          generator: g,
          printedAt: at,
        );
        return PreparedReceipt(bytes, g.children);
      },
    ),
  );
}

/// The [[Kode meja]] poster (ADR-0105): venue name, table label, the QR a guest
/// scans, and one line telling them what to do with it.
///
/// Rendered inline rather than through [StrukData], which is a *receipt* shape
/// — header, lines, totals, footer — and has no room for a page that is one
/// glyph and three words. No preview sheet either: what comes out is the QR
/// already on screen behind this button.
Future<void> printTableQr({
  required BuildContext context,
  required WidgetRef ref,
  required String tableLabel,
  required String url,
}) async {
  final l = context.l10n;
  final venue = ref.read(venueSettingsProvider);
  await _openPicker(
    context,
    PrintJob(
      subtitle: l.soQrFor(tableLabel),
      renderBytes: () async {
        final g = Generator(PaperSize.mm58, await CapabilityProfile.load());
        return _qrCardBytes(g, l, venue.displayName, tableLabel, url);
      },
    ),
  );
}

/// One printed table card. Extracted so a single card and a whole floor's
/// worth are the same bytes — a wall of laminated QRs that do not match each
/// other is worse than no wall.
List<int> _qrCardBytes(
  Generator g,
  AppL10n l,
  String venueName,
  String tableLabel,
  String url,
) => [
  ...g.text(
    venueName,
    styles: const PosStyles(align: PosAlign.center, bold: true),
  ),
  ...g.text(
    l.soQrFor(tableLabel),
    styles: const PosStyles(
      align: PosAlign.center,
      bold: true,
      height: PosTextSize.size2,
      width: PosTextSize.size2,
    ),
  ),
  ...g.feed(1),
  ...g.qrcode(url, size: QRSize.size8),
  ...g.feed(1),
  ...g.text(l.soQrHint, styles: const PosStyles(align: PosAlign.center)),
  ...g.feed(3),
  ...g.cut(),
];

/// Every table's card, as **one** job. Deliberately not a loop over
/// [printTableQr]: that would ask which printer twenty times for one act, and
/// the cut between cards already separates them on the roll.
Future<void> printAllTableQr({
  required BuildContext context,
  required WidgetRef ref,
  required List<({String label, String url})> cards,
}) async {
  final l = context.l10n;
  if (cards.isEmpty) {
    _toast(context, l.prnNothingToPrint);
    return;
  }
  final venue = ref.read(venueSettingsProvider);
  await _openPicker(
    context,
    PrintJob(
      subtitle: l.soPrintAll,
      renderBytes: () async {
        final g = Generator(PaperSize.mm58, await CapabilityProfile.load());
        return [
          for (final c in cards)
            ..._qrCardBytes(g, l, venue.displayName, c.label, c.url),
        ];
      },
    ),
  );
}

void _toast(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

/// What kind of thing a picker row points at — decides icon, tag, send path.
enum _Kind { venue, device, discoveredWifi, pairedBt }

/// A single flattened, deduped row in the live merged list.
class _Entry {
  final String address; // host:port or MAC — the dedup key
  final String label;
  final PrinterTransport transport;
  final _Kind kind;
  final bool online;
  final PrinterDto? venue; // kind == venue
  final DevicePrinter? device; // kind == device
  final DiscoveredPrinter? wifi; // kind == discoveredWifi
  final PairedBtPrinter? bt; // kind == pairedBt

  const _Entry({
    required this.address,
    required this.label,
    required this.transport,
    required this.kind,
    required this.online,
    this.venue,
    this.device,
    this.wifi,
    this.bt,
  });

  String scopeTag(AppL10n l) =>
      kind == _Kind.venue ? l.prnScopeVenue : l.prnThisDevice;
}

class _PrinterPickerSheet extends ConsumerStatefulWidget {
  final PrintJob job;
  const _PrinterPickerSheet({required this.job});

  @override
  ConsumerState<_PrinterPickerSheet> createState() =>
      _PrinterPickerSheetState();
}

class _PrinterPickerSheetState extends ConsumerState<_PrinterPickerSheet> {
  bool _busy = false;
  bool _scanning = true;

  StreamSubscription<DiscoveredPrinter>? _discSub;
  Timer? _probeTimer;

  // Live-discovered, deduped by host:port.
  final Map<String, DiscoveredPrinter> _discovered = {};
  // OS-paired Bluetooth printers + why none show.
  List<PairedBtPrinter> _paired = const [];
  BtUnavailableReason _btReason = BtUnavailableReason.none;

  // Heartbeat result for everything this phone probes itself (device + wifi
  // discovered + Bluetooth), keyed by address. Venue online comes off WS.
  final Map<String, bool> _online = {};

  @override
  void initState() {
    super.initState();
    _startDiscovery();
    _loadPaired();
    // Immediate probe, then every 10s while the sheet is open (ADR-0022).
    _probe();
    _probeTimer = Timer.periodic(const Duration(seconds: 10), (_) => _probe());
  }

  @override
  void dispose() {
    _discSub?.cancel();
    _probeTimer?.cancel();
    super.dispose();
  }

  void _startDiscovery() {
    _discSub = ref
        .read(printerDiscoveryServiceProvider)
        .stream()
        .listen(
          (p) {
            if (!mounted) return;
            setState(() => _discovered[p.key] = p);
            unawaited(_probeWifi(p.host, p.port));
          },
          onDone: () {
            if (mounted) setState(() => _scanning = false);
          },
        );
  }

  Future<void> _loadPaired() async {
    final res = await ref.read(btPrinterServiceProvider).pairedPrinters();
    if (!mounted) return;
    setState(() {
      _paired = res.printers;
      _btReason = res.reason;
    });
    for (final b in res.printers) {
      unawaited(_probeBt(b.mac));
    }
  }

  // --- heartbeat ---

  Future<void> _probe() async {
    final devices = ref.read(devicePrintersProvider);
    for (final d in devices) {
      if (d.isBluetooth) {
        if (d.mac != null) unawaited(_probeBt(d.mac!));
      } else if (d.host != null) {
        unawaited(_probeWifi(d.host!, d.port));
      }
    }
    for (final w in _discovered.values) {
      unawaited(_probeWifi(w.host, w.port));
    }
    for (final b in _paired) {
      unawaited(_probeBt(b.mac));
    }
  }

  Future<void> _probeWifi(String host, int port) async {
    final ok = await StrukSocket.probe(host, port);
    if (!mounted) return;
    setState(() => _online['$host:$port'] = ok);
  }

  Future<void> _probeBt(String mac) async {
    final ok = await ref.read(btPrinterServiceProvider).probe(mac);
    if (!mounted) return;
    setState(() => _online[mac] = ok);
  }

  bool _venueOnline(PrinterDto p) {
    final last = p.lastSeenAt;
    if (last == null) return false;
    return SatClock.now().difference(last) < _venueOnlineWindow;
  }

  // --- merge + dedup ---

  List<_Entry> _entries() {
    final venue = ref.watch(printersRepositoryProvider);
    final device = ref.watch(devicePrintersProvider);
    final seen = <String>{};
    final out = <_Entry>[];

    // 1. Venue printers (wifi only) — skip disabled entirely (ADR-0022).
    for (final p in venue) {
      if (!p.enabled) continue;
      final addr = '${p.host}:${p.port}';
      // When the host is offline, a saved local connection to the same
      // printer must remain selectable instead of being hidden by deduping.
      if (widget.job.preview != null &&
          ref.watch(wsConnStateProvider) != WsConnState.open &&
          device.any((d) => d.address == addr)) {
        continue;
      }
      seen.add(addr);
      out.add(
        _Entry(
          address: addr,
          label: p.label,
          transport: PrinterTransport.wifi,
          kind: _Kind.venue,
          online: _venueOnline(p),
          venue: p,
        ),
      );
    }

    // 2. Registered device printers (wifi or BT).
    for (final d in device) {
      if (seen.contains(d.address)) continue;
      seen.add(d.address);
      out.add(
        _Entry(
          address: d.address,
          label: d.label,
          transport: d.transport,
          kind: _Kind.device,
          online: _online[d.address] ?? false,
          device: d,
        ),
      );
    }

    // 3. Freshly discovered wifi printers not already registered.
    for (final w in _discovered.values) {
      if (seen.contains(w.key)) continue;
      seen.add(w.key);
      out.add(
        _Entry(
          address: w.key,
          label: w.name,
          transport: PrinterTransport.wifi,
          kind: _Kind.discoveredWifi,
          online: _online[w.key] ?? false,
          wifi: w,
        ),
      );
    }

    // 4. Paired Bluetooth printers not already registered.
    for (final b in _paired) {
      if (seen.contains(b.mac)) continue;
      seen.add(b.mac);
      out.add(
        _Entry(
          address: b.mac,
          label: b.name,
          transport: PrinterTransport.bluetooth,
          kind: _Kind.pairedBt,
          online: _online[b.mac] ?? false,
          bt: b,
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final entries = _entries();
    final onlineEntries = entries.where((e) => e.online).toList();
    final offlineEntries = entries.where((e) => !e.online).toList();

    return Container(
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: BorderRadius.vertical(top: SatR.c(22)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: SatBox.d(
                  color: sc.border2,
                  borderRadius: SatR.a(2),
                ),
              ),
            ),
            const SizedBox(height: Sp.s3h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.prnPick,
                        style: SatType.h3(color: sc.textHi),
                      ),
                      const SizedBox(height: Sp.s1),
                      Text(
                        widget.job.subtitle,
                        style: SatType.bodyM(color: sc.textLo),
                      ),
                    ],
                  ),
                ),
                if (_scanning) SatSpinner(size: SatSpinnerSize.xs),
              ],
            ),
            const SizedBox(height: Sp.s3h),

            if (onlineEntries.isEmpty && offlineEntries.isEmpty && !_scanning)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Sp.s4h),
                child: Text(
                  context.l10n.prnNoneOnline,
                  textAlign: TextAlign.center,
                  style: SatType.bodyM(color: sc.textLo),
                ),
              ),

            for (final e in onlineEntries) _row(sc, e),

            if (offlineEntries.isNotEmpty) ...[
              const SizedBox(height: Sp.s1),
              _divider(sc, 'Offline'),
              const SizedBox(height: Sp.s2),
              for (final e in offlineEntries) _row(sc, e),
            ],

            if (_btReason != BtUnavailableReason.none) ...[
              const SizedBox(height: Sp.s1h),
              _btAffordance(sc),
            ],

            const SizedBox(height: Sp.s3),
            _ghostBtn(
              sc,
              Icons.add_rounded,
              context.l10n.prnAddManual,
              _busy ? null : () => _addManual(),
            ),

            if (_busy) ...[
              const SizedBox(height: Sp.s3h),
              const Center(child: SatSpinner()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _divider(SatColors sc, String label) {
    return Row(
      children: [
        Expanded(child: Divider(color: sc.border0)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.s2h),
          child: Text(label, style: SatType.labelS(color: sc.textLo)),
        ),
        Expanded(child: Divider(color: sc.border0)),
      ],
    );
  }

  Widget _row(SatColors sc, _Entry e) {
    final icon = e.transport == PrinterTransport.bluetooth
        ? Icons.bluetooth_rounded
        : Icons.wifi_rounded;
    final tappable = e.online && !_busy;
    return Opacity(
      opacity: e.online ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Sp.s2),
        child: Material(
          color: sc.bg2,
          borderRadius: SatR.a(14),
          child: InkWell(
            onTap: tappable ? () => _print(e) : null,
            borderRadius: SatR.a(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.s3h,
                vertical: Sp.s3h,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: sc.textMd),
                  const SizedBox(width: Sp.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.label, style: SatType.labelM(color: sc.textHi)),
                        Text(e.address, style: SatType.monoS(color: sc.textLo)),
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: SatBox.d(
                      shape: BoxShape.circle,
                      color: e.online ? sc.success : sc.border2,
                    ),
                  ),
                  const SizedBox(width: Sp.s2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sp.s2,
                      vertical: Sp.s1,
                    ),
                    decoration: SatBox.d(
                      color: sc.bg1,
                      borderRadius: SatR.a(999),
                      border: SatB.all(color: sc.border0),
                    ),
                    child: Text(
                      e.scopeTag(context.l10n),
                      style: SatType.labelS(color: sc.textMd),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _btAffordance(SatColors sc) {
    final (label, icon, onTap) = switch (_btReason) {
      BtUnavailableReason.permission => (
        'Izinkan Bluetooth',
        Icons.bluetooth_disabled_rounded,
        () => _loadPaired(),
      ),
      BtUnavailableReason.adapterOff => (
        context.l10n.prnEnableBluetoothTitle,
        Icons.bluetooth_disabled_rounded,
        () {
          _toast(context, context.l10n.prnEnableBluetooth);
          _loadPaired();
        },
      ),
      BtUnavailableReason.none => ('', Icons.bluetooth_rounded, () {}),
    };
    return _ghostBtn(sc, icon, label, _busy ? null : onTap);
  }

  Widget _ghostBtn(
    SatColors sc,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return Material(
      color: sc.bg2,
      borderRadius: SatR.a(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: SatR.a(14),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: sc.textMd),
              const SizedBox(width: Sp.s2),
              Text(label, style: SatType.labelM(color: sc.textHi)),
            ],
          ),
        ),
      ),
    );
  }

  // --- print dispatch ---

  Future<void> _print(_Entry e) async {
    if (_busy) return;
    final load = widget.job.preview;
    if (load != null) {
      setState(() => _busy = true);
      final ok = await showSatSheet<bool>(
        context,
        dismissible: false,
        builder: (_) => ReceiptPreviewSheet(
          title:
              '${widget.job.subtitle}\n${context.l10n.prnPreviewPrinter(e.label)}',
          load: load,
          offline: () =>
              (widget.job.offline?.call() ?? false) ||
              ref.read(wsConnStateProvider) != WsConnState.open,
          send: (bytes) => _sendReviewed(e, bytes),
        ),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (ok == true) {
        _toast(context, context.l10n.prnReceiptPrinted);
        Navigator.of(context).pop();
      }
      return;
    }
    switch (e.kind) {
      case _Kind.venue:
        await _printVenue(e.venue!);
      case _Kind.device:
        await _printDevice(e.device!);
      case _Kind.discoveredWifi:
        // Print immediately, then lazily persist as a device printer.
        final d = DevicePrinter(
          id: _uuid.v4(),
          label: e.wifi!.name,
          transport: PrinterTransport.wifi,
          host: e.wifi!.host,
          port: e.wifi!.port,
        );
        await _printDevice(d, persist: true);
      case _Kind.pairedBt:
        final d = DevicePrinter(
          id: _uuid.v4(),
          label: e.bt!.name,
          transport: PrinterTransport.bluetooth,
          mac: e.bt!.mac,
        );
        await _printDevice(d, persist: true);
    }
  }

  Future<String?> _sendReviewed(_Entry e, List<int> bytes) async {
    if (e.kind == _Kind.venue) {
      return ref
          .read(printersRepositoryProvider.notifier)
          .printBytes(e.venue!.id, bytes);
    }
    final device =
        e.device ??
        DevicePrinter(
          id: _uuid.v4(),
          label: e.label,
          transport: e.transport,
          host: e.wifi?.host,
          port: e.wifi?.port ?? 9100,
          mac: e.bt?.mac,
        );
    try {
      if (device.isBluetooth) {
        await ref.read(btPrinterServiceProvider).send(device.mac!, bytes);
      } else {
        await StrukSocket.send(device.host!, device.port, bytes);
      }
    } catch (_) {
      return ref.read(l10nProvider).prnErrNotConnected;
    }
    // A preference failure must not offer a retry of a successful print.
    if (e.device == null) {
      try {
        await ref.read(devicePrintersProvider.notifier).add(device);
      } catch (_) {
        /* Printing already succeeded. */
      }
    }
    return null;
  }

  Future<void> _printVenue(PrinterDto p) async {
    await _printDevice(
      DevicePrinter(
        id: _uuid.v4(),
        label: p.label,
        transport: PrinterTransport.wifi,
        host: p.host,
        port: p.port,
      ),
    );
  }

  Future<void> _printDevice(DevicePrinter d, {bool persist = false}) async {
    setState(() => _busy = true);
    final l = context.l10n;
    String? err;
    try {
      final bytes = await widget.job.renderBytes!();
      if (d.isBluetooth) {
        await ref.read(btPrinterServiceProvider).send(d.mac!, bytes);
      } else {
        await StrukSocket.send(d.host!, d.port, bytes);
      }
      if (persist) {
        await ref.read(devicePrintersProvider.notifier).add(d);
      }
    } catch (_) {
      err = l.prnErrNotConnected;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    _toast(context, err ?? l.prnReceiptPrinted);
  }

  // --- manual add (wifi only; Bluetooth is added by pairing in Settings) ---

  Future<void> _addManual() async {
    final labelCtl = TextEditingController();
    final hostCtl = TextEditingController();
    final portCtl = TextEditingController(text: '9100');
    var scope = 'venue'; // venue | device

    final ok = await showSatDialog<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final sc = ctx.sat;
          return AlertDialog(
            backgroundColor: sc.bg1,
            title: Text(ctx.l10n.prnAddWifi, style: SatType.labelL()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SatField.text(
                  controller: labelCtl,
                  label: ctx.l10n.prnLabel,
                  hint: '',
                ),
                SatField.text(
                  controller: hostCtl,
                  label: ctx.l10n.prnHost,
                  hint: '',
                ),
                SatField.number(
                  controller: portCtl,
                  label: ctx.l10n.prnPort,
                  hint: '',
                ),
                const SizedBox(height: Sp.s3),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'venue',
                      label: Text(ctx.l10n.prnScopeVenue),
                    ),
                    ButtonSegment(
                      value: 'device',
                      label: Text(ctx.l10n.prnScopeDevice),
                    ),
                  ],
                  selected: {scope},
                  onSelectionChanged: (s) => setLocal(() => scope = s.first),
                ),
              ],
            ),
            actions: [
              SatButton.ghost(
                label: context.l10n.cancel,
                onTap: () => Navigator.of(ctx).pop(false),
              ),
              SatButton.primary(
                label: context.l10n.add,
                onTap: () => Navigator.of(ctx).pop(true),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !mounted) return;
    final label = labelCtl.text.trim();
    final host = hostCtl.text.trim();
    final port = int.tryParse(portCtl.text.trim()) ?? 9100;
    if (label.isEmpty || host.isEmpty) return;
    if (scope == 'device') {
      await ref
          .read(devicePrintersProvider.notifier)
          .add(
            DevicePrinter(
              id: _uuid.v4(),
              label: label,
              transport: PrinterTransport.wifi,
              host: host,
              port: port,
            ),
          );
    } else {
      await ref
          .read(printersRepositoryProvider.notifier)
          .create(label: label, host: host, port: port);
    }
    if (mounted) _toast(context, 'Printer "$label" ditambahkan');
  }
}
