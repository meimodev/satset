import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/discount_dto.dart';
import 'package:satset/data/repositories/discount_presets_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/features/cashier/cashier_bill_screen.dart';
import 'package:satset/l10n/app_localizations.dart';

/// What the bill's lines pane shows while the cashier is picking items.
///
/// On a phone the pane collapses to the picker: a 360dp sheet already gives the
/// settle pane 420dp, and the totals card, the action row and the Struk list
/// push the items being tapped below the fold. On a tablet the same pane is a
/// column of its own beside the settle pane, so nothing is cut.
///
/// The cut is three `if`s that read as tidy-uppable, and the thing they protect
/// — the item the cashier is reaching for being on screen — is invisible in a
/// diff. Hence this file.
///
/// It also pins that every payment method stays available after a payment has
/// landed, so a receipt can use more than one tender (ADR-0121).
/// Points nowhere on purpose: the preset repository bootstraps off a socket,
/// and this file stubs its state rather than serving it.
final _cfg = ApiConfig(
  baseUri: Uri.parse('https://127.0.0.1:45678/'),
  trustedFingerprint: '',
);

void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  const cashier = AppUser(
    id: 'u1',
    name: 'Maya Anjani',
    initials: 'MA',
    role: UserRole.admin,
    shiftStartedAt: '2026-07-29T09:00:00.000',
    zoneAssigned: 'Teras',
  );

  /// One itemized bill with two lines, nothing assigned, nothing paid — the
  /// state a cashier is in when they reach for Per item.
  const billJson = <String, dynamic>{
    'visitId': 'v1',
    'tableId': 't1',
    'tableLabel': '12',
    'mode': 'itemized',
    'subtotal': 100000,
    'serviceAmount': 5000,
    'taxAmount': 11550,
    'total': 116550,
    'outstanding': 116550,
    'lines': [
      {
        'ticketId': 'tk1',
        'itemId': 'i1',
        'name': 'Nasi Goreng',
        'qty': 2,
        'unitPrice': 35000,
        'lineTotal': 70000,
        'assignedUnits': 0,
        'sentAt': '2026-07-29T12:00:00.000',
      },
      {
        'ticketId': 'tk2',
        'itemId': 'i2',
        'name': 'Es Teh',
        'qty': 2,
        'unitPrice': 15000,
        'lineTotal': 30000,
        'assignedUnits': 0,
        'sentAt': '2026-07-29T12:00:00.000',
      },
    ],
    'receipts': [
      {
        'id': 'r1',
        'label': 'A',
        'kind': 'itemized',
        'total': 0,
        'paidAmount': 0,
        'items': [],
        'payments': [],
      },
    ],
  };
  final bill = Bill.fromJson(billJson);

  /// The same bill after a guest has paid one receipt by QRIS. Two receipts:
  /// one settled, one still open — the state a cashier is in when the second
  /// guest reaches for their wallet.
  final partPaid = Bill.fromJson({
    ...billJson,
    'paidAmount': 40000,
    'outstanding': 76550,
    'receipts': [
      {
        'id': 'r1',
        'label': 'A',
        'kind': 'itemized',
        'mode': 'itemized',
        'total': 40000,
        'paidNet': 40000,
        'status': 'paid',
        'items': [],
        'payments': [
          {
            'id': 'p1',
            'method': 'qris',
            'amount': 40000,
            'at': '2026-07-29T12:30:00.000',
          },
          // A refund is a method too, and a later one. It must not win the
          // lock — giving money back doesn't decide the next tender.
          {
            'id': 'p2',
            'method': 'tunai',
            'amount': 5000,
            'isRefund': true,
            'at': '2026-07-29T12:40:00.000',
          },
        ],
      },
      {
        'id': 'r2',
        'label': 'B',
        'kind': 'itemized',
        'mode': 'itemized',
        'total': 0,
        'paidNet': 0,
        'items': [],
        'payments': [],
      },
    ],
  });

  /// `Reveal` staggers each section behind a one-shot timer (`anim.dart`), so a
  /// single pump leaves them pending and the harness complains. Drain them.
  Future<void> drain(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> pumpBill(
    WidgetTester tester, {
    required bool tablet,
    Bill? fixture,
    bool viaEntryPoint = false,
    void Function(_StubSettlement)? onSettlement,
  }) async {
    // 800dp shortest side is the tablet branch; 360dp is the phone floor.
    tester.view.physicalSize = tablet
        ? const Size(1280, 800)
        : const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wsConnStateProvider.overrideWithValue(WsConnState.open),
          wsClientProvider.overrideWith((ref) {
            final ws = WsClient(config: _cfg, storage: SecureStorageService());
            ref.onDispose(ws.dispose);
            return ws;
          }),
          authStateProvider.overrideWith(
            (ref) => _StubAuth(
              ref: ref,
              storage: ref.watch(secureStorageServiceProvider),
              seed: const AuthState(
                isAuthenticated: true,
                user: cashier,
                // Holds the capability outright, so the picker never detours
                // through the manager step-up.
                capabilities: {Capability.settleBill, Capability.applyDiscount},
              ),
            ),
          ),
          discountPresetsRepositoryProvider.overrideWith(_PresetRepo.new),
          settlementProvider.overrideWith((ref) {
            final settlement = _StubSettlement(ref: ref, bill: fixture ?? bill);
            onSettlement?.call(settlement);
            return settlement;
          }),
          billDetailProvider('v1').overrideWith(
            (ref) async =>
                (ref.read(settlementProvider.notifier) as _StubSettlement).bill,
          ),
        ],
        child: MaterialApp(
          // Pinned, exactly as the app pins it (ADR-0083). Without this the
          // test resolves against the host's locale and reads English.
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: viaEntryPoint
              ? Builder(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () =>
                            openCashierBill(context, visitId: 'v1'),
                        child: const Text('Open bill'),
                      ),
                    ),
                  ),
                )
              : const Scaffold(body: CashierBillView(visitId: 'v1')),
        ),
      ),
    );
    await drain(tester);
    if (viaEntryPoint) {
      await tester.tap(find.text('Open bill'));
      await drain(tester);
      tester.takeException();
    }
    // The test font draws every glyph as a square of the font size, so rows
    // budgeted against real metrics overrun here. Structure is what this file
    // asserts; the width arithmetic lives in ADR-0062 and on hardware.
    tester.takeException();
  }

  /// Tap the settle pane's mode row. The row is always on screen — that is what
  /// makes the cut reversible in one tap.
  Future<void> pickMode(WidgetTester tester, String label) async {
    await tester.tap(
      find.byWidgetPredicate((w) => w is DropdownButtonFormField).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await drain(tester);
    tester.takeException();
  }

  // `SatCard.section` upper-cases its header, so the two card finders match the
  // rendered caps rather than the string the call site passes.
  Finder totals() => find.text('Subtotal', skipOffstage: false);
  Finder actions() => find.textContaining('Cetak tagihan', skipOffstage: false);
  Finder lines() => find.text('ITEM PESANAN', skipOffstage: false);

  testWidgets('tablet · per item pays with the selected method', (
    tester,
  ) async {
    late _StubSettlement settlement;
    final originalPicker = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = _StubImagePicker(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    addTearDown(() => ImagePickerPlatform.instance = originalPicker);

    await pumpBill(
      tester,
      tablet: true,
      onSettlement: (value) => settlement = value,
    );
    expect(totals(), findsOneWidget);
    expect(lines(), findsOneWidget);

    await pickMode(tester, 'Per item');

    expect(lines(), findsOneWidget, reason: 'the picker is the whole point');

    await tester.tap(find.text('Nasi Goreng'));
    await drain(tester);
    tester.takeException();

    final methodDropdown = find
        .byWidgetPredicate(
          (w) => w is DropdownButtonFormField,
          skipOffstage: false,
        )
        .last;
    await tester.ensureVisible(methodDropdown);
    await tester.tap(methodDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('QRIS').last);
    await drain(tester);

    final takeProof = find.text('Ambil foto bukti bayar');
    await tester.ensureVisible(takeProof);
    await tester.tap(takeProof);
    await drain(tester);
    expect(find.text('Bukti terlampir'), findsOneWidget);

    final confirm = find.textContaining('Terima 1 item');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await drain(tester);

    expect(settlement.paymentMethod, 'qris');
    expect(settlement.paymentPhoto, isNotNull);
    expect(settlement.mintedLines, hasLength(1));
    expect(settlement.mintedLines.single.ticketId, 'tk1');
    expect(settlement.mintedLines.single.qtyUnits, 2);
  });

  testWidgets('phone · leaving per item brings everything back', (
    tester,
  ) async {
    await pumpBill(tester, tablet: false);
    await pickMode(tester, 'Per item');
    expect(totals(), findsNothing);

    await pickMode(tester, 'Penuh');

    expect(totals(), findsOneWidget);
    expect(actions(), findsOneWidget);
    expect(lines(), findsOneWidget);
  });

  testWidgets('phone · bill entry pushes one page header', (tester) async {
    await pumpBill(tester, tablet: false, viaEntryPoint: true);

    expect(find.byType(CashierBillPage), findsOneWidget);
    expect(find.byType(SatAppBar), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Tagihan · Meja 12'), findsOneWidget);
  });

  testWidgets('tablet · per item cuts nothing from the left pane', (
    tester,
  ) async {
    await pumpBill(tester, tablet: true);
    await pickMode(tester, 'Per item');

    expect(lines(), findsOneWidget);
    expect(totals(), findsOneWidget);
    expect(actions(), findsOneWidget);
  });

  testWidgets('per item hangs a line discount on the struk it mints', (
    tester,
  ) async {
    // ADR-0126: there is no "Tinjau struk" detour any more. The cashier taps a
    // line, taps a give-back on it, and confirms — mint, discount and payment
    // are one gesture, chained on ids this side already holds (ADR-0123).
    late _StubSettlement settlement;
    await pumpBill(
      tester,
      tablet: true,
      onSettlement: (value) => settlement = value,
    );
    await pickMode(tester, 'Per item');

    // Tap the first line into the selection.
    await tester.tap(find.text('Nasi Goreng').first);
    await drain(tester);
    tester.takeException();

    // The chip that was only reachable through the receipt sheet before.
    final chip = find.byKey(const ValueKey('line-discount-tk1'));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Promo item').last);
    await drain(tester);
    tester.takeException();

    // Held, not written: nothing has been minted for it to hang on yet.
    expect(settlement.applied, isEmpty);

    // The quote already carries the give-back: 70.000 − 7.000, grown by the
    // bill's own service and tax rate.
    expect(find.text('-Rp. 7.000', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('Terima 1 item · Rp. 73.427'), findsOneWidget);

    // Tender the exact amount, or the confirm button stays blocked.
    final exact = find.text('Pas');
    await tester.ensureVisible(exact);
    await tester.tap(exact);
    await drain(tester);

    final confirm = find.textContaining('Terima 1 item');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await drain(tester);

    // Minted first, then the give-back, then the money — in that order and
    // naming the receipt this side minted.
    expect(settlement.mintedLines.single.ticketId, 'tk1');
    expect(settlement.applied, hasLength(1));
    expect(settlement.applied.single.receiptId, 'r2');
    expect(settlement.applied.single.ticketId, 'tk1');
    expect(settlement.applied.single.presetId, 'line-10');
    expect(settlement.paymentMethod, 'tunai');
  });

  final paidOpenJson = <String, dynamic>{
    ...billJson,
    'lines': [
      for (final line in billJson['lines'] as List)
        {...line as Map<String, dynamic>, 'assignedUnits': line['qty']},
    ],
    'paidAmount': 116550,
    'outstanding': 0,
    'fullyAssigned': true,
    'fullySettled': true,
    'receipts': [
      {
        'id': 'r2',
        'label': 'A',
        'total': 116550,
        'paidNet': 116550,
        'status': 'paid',
        'payments': [
          {
            'id': 'paid-final',
            'method': 'tunai',
            'amount': 116550,
            'at': '2026-07-29T12:30:00.000',
          },
        ],
      },
    ],
  };
  final paidOpen = Bill.fromJson(paidOpenJson);

  Future<void> payItems(WidgetTester tester, {bool all = true}) async {
    await pickMode(tester, 'Per item');
    await tester.tap(find.text('Nasi Goreng').first);
    await drain(tester);
    if (all) {
      await tester.tap(find.text('Es Teh').first);
      await drain(tester);
    }
    final exact = find.text('Pas');
    await tester.ensureVisible(exact);
    await tester.tap(exact);
    await drain(tester);
    final confirm = find.textContaining('Terima ${all ? 2 : 1} item');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await drain(tester);
  }

  Finder closeDialogAction() => find
      .descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Tutup tagihan'),
      )
      .last;

  testWidgets('final payment asks before closing and Keep open preserves it', (
    tester,
  ) async {
    late _StubSettlement settlement;
    await pumpBill(
      tester,
      tablet: true,
      onSettlement: (value) {
        settlement = value;
        value.paymentResult = paidOpen;
      },
    );
    await payItems(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(settlement.closeCount, 0);
    await tester.tap(find.text('Biarkan terbuka'));
    await drain(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(settlement.closeCount, 0);
    expect(settlement.bill.billClosedAt, isNull);
    expect(settlement.bill.receipts.single.payments.single.amount, 116550);
    expect(find.text('Tutup tagihan'), findsWidgets);
  });

  testWidgets('confirming final payment dialog explicitly closes the bill', (
    tester,
  ) async {
    late _StubSettlement settlement;
    await pumpBill(
      tester,
      tablet: true,
      viaEntryPoint: true,
      onSettlement: (value) {
        settlement = value;
        value.paymentResult = paidOpen;
      },
    );
    await payItems(tester);
    expect(settlement.closeCount, 0);
    await tester.tap(closeDialogAction());
    await drain(tester);

    expect(settlement.closeCount, 1);
    expect(settlement.closedVisitId, 'v1');
    expect(settlement.closedWithWriteOff, false);
    expect(find.byType(CashierBillView), findsNothing);
  });

  testWidgets('partial payment leaves bill open without a close dialog', (
    tester,
  ) async {
    late _StubSettlement settlement;
    await pumpBill(
      tester,
      tablet: true,
      onSettlement: (value) {
        settlement = value;
        value.paymentResult = partPaid;
      },
    );
    await payItems(tester, all: false);

    expect(settlement.paidAmount, isPositive);
    expect(settlement.bill.fullySettled, false);
    expect(find.byType(AlertDialog), findsNothing);
    expect(settlement.closeCount, 0);
  });

  testWidgets('paid open bill can be closed later with confirmation', (
    tester,
  ) async {
    late _StubSettlement settlement;
    await pumpBill(
      tester,
      tablet: true,
      fixture: paidOpen,
      viaEntryPoint: true,
      onSettlement: (value) => settlement = value,
    );
    expect(find.byType(AlertDialog), findsNothing);
    final close = find.text('Tutup tagihan').last;
    await tester.ensureVisible(close);
    await tester.tap(close);
    await drain(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(settlement.closeCount, 0);
    await tester.tap(closeDialogAction());
    await drain(tester);
    expect(settlement.closeCount, 1);
    expect(settlement.closedWithWriteOff, false);
  });

  for (final tablet in [false, true]) {
    testWidgets(
      '${tablet ? 'tablet' : 'phone'} · reopen restores controls and keeps payments',
      (tester) async {
        late _StubSettlement settlement;
        await pumpBill(
          tester,
          tablet: tablet,
          fixture: Bill.fromJson({
            ...paidOpenJson,
            'billClosedAt': '2026-07-29T12:35:00.000',
          }),
          onSettlement: (value) {
            settlement = value;
            value.reopenResult = paidOpen;
          },
        );
        expect(
          find.byWidgetPredicate((w) => w is DropdownButtonFormField),
          findsNothing,
        );
        final reopen = find.text('Buka ulang');
        await tester.ensureVisible(reopen);
        await tester.tap(reopen);
        await drain(tester);

        expect(settlement.reopenedVisitId, 'v1');
        expect(settlement.bill.billClosedAt, isNull);
        expect(settlement.bill.fullySettled, isTrue);
        expect(
          settlement.bill.receipts.single.payments.single.id,
          'paid-final',
        );
        expect(settlement.bill.receipts.single.payments.single.amount, 116550);
        expect(find.text('Buka ulang'), findsNothing);
        expect(find.text('Tutup tagihan'), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Tidak ada sisa untuk ditagih'), findsOneWidget);
        await pickMode(tester, 'Per item');
        expect(lines(), findsOneWidget);
        expect(
          settlement.paidAmount,
          isNull,
          reason: 'reopening must not collect payment again',
        );
      },
    );
  }

  testWidgets('unpaid bill offers every payment method', (tester) async {
    await pumpBill(tester, tablet: true);

    for (final label in ['Tunai', 'QRIS', 'Kartu', 'Transfer', 'Lainnya']) {
      expect(find.text(label, skipOffstage: false), findsOneWidget);
    }
  });

  testWidgets('a part-paid bill still offers every method', (tester) async {
    await pumpBill(tester, tablet: true, fixture: partPaid);

    // QRIS paid the first receipt. It used to collapse the row to itself for
    // the rest of the bill; `CONTEXT.md` has always described a struk taking
    // part Tunai part Kartu, so the lock was drift and is gone (ADR-0121).
    for (final label in ['Tunai', 'QRIS', 'Kartu', 'Transfer', 'Lainnya']) {
      expect(find.text(label, skipOffstage: false), findsOneWidget);
    }
    expect(find.textContaining('Terkunci', skipOffstage: false), findsNothing);
  });
}

class _StubAuth extends AuthRepository {
  _StubAuth({
    required super.ref,
    required super.storage,
    required AuthState seed,
  }) {
    state = seed;
  }
}

class _StubSettlement extends SettlementRepository {
  _StubSettlement({required super.ref, required this.bill});

  Bill bill;
  Bill? paymentResult;
  Bill? reopenResult;
  String? reopenedVisitId;
  int closeCount = 0;
  String? closedVisitId;
  bool? closedWithWriteOff;
  String? paymentMethod;
  String? paymentPhoto;
  int? paidAmount;
  List<BillReceiptLine> mintedLines = const [];

  /// Every line discount the pane hung on the receipt it just minted, in the
  /// order it did — the chain ADR-0126 replaced "Tinjau struk" with.
  final List<({String receiptId, String? ticketId, String presetId})> applied =
      [];

  @override
  Future<({String receiptId, Bill bill})> mintReceipt(
    String visitId, {
    String mode = 'itemized',
    String? label,
    bool assignAll = false,
    List<BillReceiptLine> lines = const [],
    String? memberId,
  }) async {
    mintedLines = lines;
    return (receiptId: 'r2', bill: bill);
  }

  @override
  Future<Bill> applyDiscount(
    String receiptId, {
    required String presetId,
    String? ticketId,
    String? approverPin,
  }) async {
    applied.add((receiptId: receiptId, ticketId: ticketId, presetId: presetId));
    return bill;
  }

  @override
  Future<Bill> recordPayment(
    String receiptId, {
    required String method,
    required int amount,
    int? tendered,
    String? note,
    String? photoBase64,
    String? memberId,
  }) async {
    paymentMethod = method;
    paymentPhoto = photoBase64;
    paidAmount = amount;
    bill = paymentResult ?? bill;
    return bill;
  }

  @override
  Future<Bill> reopenBill(String visitId) async {
    reopenedVisitId = visitId;
    bill = reopenResult!;
    return bill;
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> closeBill(
    String visitId, {
    bool writeOff = false,
    String? reason,
  }) async {
    closeCount++;
    closedVisitId = visitId;
    closedWithWriteOff = writeOff;
  }
}

class _PresetRepo extends DiscountPresetsRepository {
  _PresetRepo(Ref ref) : super(ref: ref) {
    state = const [
      DiscountPresetDto(
        id: 'line-10',
        name: 'Promo item',
        scope: 'line',
        value: 1000, // 10%
      ),
    ];
  }
}

class _StubImagePicker extends ImagePickerPlatform {
  _StubImagePicker(this.bytes);

  final Uint8List bytes;

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async => XFile.fromData(bytes, mimeType: 'image/png', name: 'proof.png');
}
