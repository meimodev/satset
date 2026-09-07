import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/models/member_dto.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/members_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/admin/members_screen.dart';

final _member = MemberDto.fromJson({
  'id': 'm1',
  'name': 'Alexandra Pelanggan Langganan Keluarga',
  'phone': '08123456789012',
  'code': 'MEMBER-2026-001234',
  'points': 123456,
  'debt': 123456789,
  'visitCount': 123,
  'punchTarget': 10,
  'punchProgress': 8,
  'note': 'Catatan pelanggan yang panjang dan harus tetap bisa dibaca.',
  'address': {'text': 'Jalan Sam Ratulangi Nomor 123, dekat pasar'},
});

class _Members extends MembersRepository {
  _Members(super.ref) {
    state = MembersState(members: [_member]);
  }
  @override
  Future<void> refresh() async {}
  @override
  Future<void> search(String q, {bool lookupOnly = false}) async {
    state = state.copyWith(query: q);
  }

  @override
  Future<MemberDetail> detail(String id) async => MemberDetail(
    member: _member,
    ledger: [
      MemberLedgerEntry(
        MemberPointEntry(
          id: 'p1',
          memberId: id,
          kind: MemberPointKind.adjust,
          delta: 123456,
          at: DateTime(2026, 9, 7),
          note: 'Koreksi poin untuk kunjungan keluarga sebelumnya',
        ),
      ),
    ],
  );
  @override
  Future<MemberDebt> debt(String id) async => MemberDebt(
    balance: 123456789,
    limit: 200000000,
    entries: [
      MemberDebtEntry(
        id: 'd1',
        memberId: id,
        kind: MemberDebtKind.charge,
        delta: 123456789,
        at: DateTime(2026, 9, 7),
        billLabel: 'Tagihan meja keluarga besar',
      ),
    ],
  );
  @override
  Future<List<MemberVisitDto>> visits(String id, {int limit = 30}) async => [
    MemberVisitDto.fromJson({
      'visitId': 'v1',
      'closedAt': '2026-09-07T12:00:00',
      'tableLabel': 'Meja keluarga besar',
      'settledTotal': 123456789,
      'discountAmount': 123456,
      'lossAmount': 1000,
    }),
  ];
}

class _Settings extends VenueSettingsRepository {
  _Settings({required super.ref}) {
    state = const VenueSettingsDto(
      memberPointsEnabled: true,
      memberDebtEnabled: true,
    );
  }
}

void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1280, 800),
  ]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('directory and detail fit $size at $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              wsClientProvider.overrideWith(
                (ref) => WsClient(
                  config: ApiConfig(
                    baseUri: Uri.parse('https://127.0.0.1:8443'),
                    trustedFingerprint: '',
                  ),
                  storage: SecureStorageService(),
                ),
              ),
              membersProvider.overrideWith(_Members.new),
              venueSettingsProvider.overrideWith((ref) => _Settings(ref: ref)),
            ],
            child: MaterialApp(
              locale: const Locale('id'),
              localizationsDelegates: AppL10n.localizationsDelegates,
              supportedLocales: AppL10n.supportedLocales,
              theme: satTheme(SatTheme.neonTerang),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const Scaffold(body: MembersScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text(_member.name),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text(_member.name));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(_member.member.code), findsOneWidget);
        final scroll = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          find.text('Meja keluarga besar'),
          250,
          scrollable: scroll,
        );
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.close).hitTestable(), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
      });
    }
  }
}
