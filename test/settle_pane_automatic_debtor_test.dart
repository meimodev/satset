import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/features/cashier/member_panel.dart';
import 'package:satset/ui/features/cashier/widgets/pay_method_picker.dart';
import 'package:satset/ui/features/cashier/widgets/settle_pane.dart';

final _config = ApiConfig(
  baseUri: Uri.parse('https://127.0.0.1:8443'),
  trustedFingerprint: '',
);

Map<String, dynamic> _member(String id, {int limit = 100000}) => {
  'id': id,
  'name': {'m1': 'Budi', 'm2': 'Ani', 'm3': 'Dewi'}[id],
  'phone': '0812$id',
  'debtLimit': limit,
  'debt': 0,
};

Bill _bill({String visitId = 'v1'}) => Bill.fromJson({
  'visitId': visitId,
  'tableId': 't1',
  'subtotal': 80000,
  'total': 80000,
  'outstanding': 80000,
  'ticketAttribution': true,
  'splitEnabled': true,
  'lines': [
    for (final (id, owner) in [
      ('tk1', 'm1'),
      ('tk2', 'm1'),
      ('tk3', 'm2'),
      ('tk4', null),
    ])
      {
        'ticketId': id,
        'name': 'Nasi goreng',
        'qty': 1,
        'unitPrice': 20000,
        'lineTotal': 20000,
        'memberId': owner,
        'memberName': owner == null ? null : _member(owner)['name'],
      },
  ],
});

class _Api extends ApiClient {
  _Api() : super(config: _config, storage: SecureStorageService());

  final requests = <String>[];
  Future<dynamic> Function(String id) resolve = (id) async => _member(id);

  @override
  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) async {
    requests.add(path);
    if (path == '/members') return [_member('m3')];
    return resolve(path.split('/').last);
  }
}

class _Settlement extends SettlementRepository {
  _Settlement(Ref ref) : super(ref: ref);

  final payments = <({String? memberId, String method, int amount})>[];
  Completer<void>? mintPending;

  @override
  Future<({String receiptId, Bill bill})> mintReceipt(
    String visitId, {
    String mode = 'itemized',
    String? label,
    bool assignAll = false,
    List<BillReceiptLine> lines = const [],
    String? memberId,
  }) async {
    if (mintPending != null) await mintPending!.future;
    return (receiptId: 'r1', bill: _bill());
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
    payments.add((memberId: memberId, method: method, amount: amount));
    return _bill();
  }
}

typedef _Draft = ({Bill bill, SettleMode mode, Map<String, int> selection});

void main() {
  late _Api api;
  late _Settlement repo;
  late ValueNotifier<_Draft> draft;
  late AppL10n l10n;

  setUp(() async {
    api = _Api();
    draft = ValueNotifier((
      bill: _bill(),
      mode: SettleMode.perItem,
      selection: {'tk1': 1, 'tk2': 1},
    ));
    l10n = await AppL10n.delegate.load(const Locale('id'));
  });
  tearDown(() => draft.dispose());

  void select(Map<String, int> selection) => draft.value = (
    bill: draft.value.bill,
    mode: draft.value.mode,
    selection: selection,
  );

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWith((_) => api),
          wsClientProvider.overrideWith(
            (_) => WsClient(config: _config, storage: SecureStorageService()),
          ),
          wsConnStateProvider.overrideWith((_) => WsConnState.open),
          settlementProvider.overrideWith((ref) => repo = _Settlement(ref)),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ValueListenableBuilder<_Draft>(
                valueListenable: draft,
                builder: (context, value, _) => SettlePane(
                  bill: value.bill,
                  repo: ref.read(settlementProvider.notifier),
                  run: (action) async {
                    await action();
                  },
                  selection: value.selection,
                  mode: value.mode,
                  onMode: (mode) => draft.value = (
                    bill: value.bill,
                    mode: mode,
                    selection: value.selection,
                  ),
                  onClearSelection: () => select({}),
                  pendingDiscounts: const {},
                  onClearPending: () {},
                  onPrintSelection: () {},
                  debtEnabled: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder payFinder() => find.byWidgetPredicate(
    (w) => w is SatButton && w.icon == Icons.check_rounded,
  );
  SatButton pay(WidgetTester tester) => tester.widget<SatButton>(payFinder());

  Future<void> choosePiutang(WidgetTester tester) async {
    await tester.tap(find.byType(SatDropdown<PayMethod>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.payMethodOnAccount).last);
    await tester.pumpAndSettle();
  }

  testWidgets('shared owner pays without opening the debtor picker', (
    tester,
  ) async {
    await pump(tester);
    await choosePiutang(tester);
    expect(api.requests, ['/members/m1']);
    expect(find.text('Budi'), findsOneWidget);
    expect(find.byType(MemberLookupSheet), findsNothing);
    expect(pay(tester).onTap, isNotNull);
    await tester.tap(payFinder());
    await tester.pumpAndSettle();
    expect(repo.payments, [(memberId: 'm1', method: 'piutang', amount: 40000)]);
    expect(pay(tester).onTap, isNull);
    // A second payment resolves credit again, even for the same member.
    select({'tk1': 1});
    await tester.pumpAndSettle();
    expect(api.requests, ['/members/m1', '/members/m1']);
  });

  testWidgets(
    'automatic debtor follows owners and clears for ambiguous selection',
    (tester) async {
      await pump(tester);
      await choosePiutang(tester);
      select({'tk3': 1});
      await tester.pumpAndSettle();
      expect(find.text('Ani'), findsOneWidget);
      expect(pay(tester).onTap, isNotNull);
      for (final selection in [
        {'tk1': 1, 'tk3': 1},
        {'tk1': 1, 'tk4': 1},
        <String, int>{},
      ]) {
        select(selection);
        await tester.pumpAndSettle();
        expect(pay(tester).onTap, isNull);
        expect(find.text(l10n.stlDebtorUnset), findsOneWidget);
      }
    },
  );

  testWidgets(
    'insufficient credit still blocks the automatically selected member',
    (tester) async {
      api.resolve = (id) async => _member(id, limit: 30000);
      await pump(tester);
      await choosePiutang(tester);
      expect(find.text('Budi'), findsOneWidget);
      expect(find.text(l10n.stlBlkOverCredit), findsOneWidget);
      expect(pay(tester).onTap, isNull);
      select({'tk1': 1});
      await tester.pumpAndSettle();
      expect(pay(tester).onTap, isNotNull);
    },
  );

  testWidgets('failed lookup leaves the picker available and Pay disabled', (
    tester,
  ) async {
    api.resolve = (_) async => throw StateError('member unavailable');
    await pump(tester);
    await choosePiutang(tester);
    expect(pay(tester).onTap, isNull);
    expect(find.text(l10n.cshMemberFind), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late lookup cannot replace a newer automatic debtor', (
    tester,
  ) async {
    final pending = Completer<dynamic>();
    api.resolve = (id) async => id == 'm1' ? pending.future : _member(id);
    await pump(tester);
    await choosePiutang(tester);
    expect(pay(tester).onTap, isNull);
    select({'tk3': 1});
    await tester.pumpAndSettle();
    pending.complete(_member('m1'));
    await tester.pumpAndSettle();
    expect(find.text('Ani'), findsOneWidget);
    expect(find.text('Budi'), findsNothing);
    await tester.tap(payFinder());
    await tester.pumpAndSettle();
    expect(repo.payments.single.memberId, 'm2');
  });

  testWidgets(
    'manual override wins over pending lookup and selection changes',
    (tester) async {
      final pending = Completer<dynamic>();
      api.resolve = (_) => pending.future;
      await pump(tester);
      await choosePiutang(tester);
      await tester.tap(find.text(l10n.cshMemberFind));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dewi · 0812m3'));
      await tester.pumpAndSettle();
      pending.complete(_member('m1'));
      select({'tk1': 1, 'tk3': 1});
      await tester.pumpAndSettle();
      expect(find.text('Dewi'), findsOneWidget);
      expect(pay(tester).onTap, isNotNull);
      await tester.tap(payFinder());
      await tester.pumpAndSettle();
      expect(repo.payments.single.memberId, 'm3');
    },
  );

  testWidgets('changing mode cancels a pending automatic assignment', (
    tester,
  ) async {
    final pending = Completer<dynamic>();
    api.resolve = (_) => pending.future;
    await pump(tester);
    await choosePiutang(tester);
    draft.value = (
      bill: draft.value.bill,
      mode: SettleMode.penuh,
      selection: {},
    );
    await tester.pumpAndSettle();
    pending.complete(_member('m1'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.stlDebtorUnset), findsOneWidget);
    expect(pay(tester).onTap, isNull);
  });

  testWidgets(
    'payment retains the confirmed debtor through an asynchronous mint',
    (tester) async {
      await pump(tester);
      await choosePiutang(tester);
      repo.mintPending = Completer<void>();
      await tester.tap(payFinder());
      await tester.pump();
      select({'tk3': 1});
      await tester.pump();
      repo.mintPending!.complete();
      await tester.pumpAndSettle();
      expect(repo.payments.single.memberId, 'm1');
      expect(repo.payments.single.amount, 40000);
    },
  );
}
