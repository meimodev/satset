import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/staff_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/takeaway_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/services/settlement_journal.dart';
import 'package:satset/data/services/settlement_sync.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/settlement_event.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/models/zone.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/note_line.dart';
import 'package:satset/ui/features/orders/orders_screen.dart';

import '_tickers.dart';

final _events = StateProvider<List<SettlementEvent>>((_) => []);
final _hostTickets = Provider<_Tickets>((_) => _Tickets({}));
final _captureTime = DateTime(2026, 10, 6, 18, 2);
const _note =
    'Tanpa saus. Alergi kacang; gunakan alat masak terpisah '
    'dan jangan tambahkan sambal atau hiasan yang mengandung kacang.';

SettlementEvent _order({String? note = _note}) => SettlementEvent(
  id: 'order',
  visitId: 'v',
  tableId: 't',
  seq: 0,
  kind: SettlementEventKind.submitOrder,
  capturedAt: _captureTime.toUtc(),
  payload: {
    'lines': [
      {
        'ticketId': 'line',
        'itemId': 'i',
        'name': 'Ayam panggang',
        'course': 'mains',
        'unitPrice': 95000,
        'note': note,
      },
    ],
  },
);

Ticket _delivered({TicketStatus status = TicketStatus.sent}) => Ticket(
  id: 'line',
  visitId: 'v',
  tableId: 't',
  itemId: 'i',
  name: 'Ayam panggang',
  course: CourseId.mains,
  price: 95000,
  status: status,
  sentAt: '18:22',
  sentAtTime: _captureTime.add(const Duration(minutes: 20)),
  capturedAtTime: _captureTime,
  note: _note,
);

void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);
  tearDown(() {
    SatClock.clear();
    Intl.defaultLocale = 'id_ID';
  });

  Future<ProviderContainer> pumpBoard(
    WidgetTester tester, {
    String language = 'id',
    Size size = const Size(360, 800),
    double textScale = 1,
    List<SettlementEvent>? events,
    List<Ticket> host = const [],
    String? segment,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Intl.defaultLocale = language == 'id' ? 'id_ID' : 'en_US';
    SatClock.adopt(
      _captureTime
          .add(const Duration(minutes: 30, seconds: 30))
          .difference(DateTime.now()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _events.overrideWith((_) => events ?? [_order()]),
          journalViewProvider.overrideWith(
            (ref) => JournalState(events: ref.watch(_events)),
          ),
          _hostTickets.overrideWith((_) => _Tickets({'v': host})),
          ticketsProvider.overrideWith((ref) => ref.watch(_hostTickets)),
          tablesProvider.overrideWith(
            (_) => _Tables([
              VenueTable(id: 't', zoneId: 'z', currentVisitId: 'v'),
            ]),
          ),
          staffRepositoryProvider.overrideWith((_) => _Staff([])),
          zonesProvider.overrideWith((_) => _Zones([])),
          takeawayVisitsProvider.overrideWith((_) => _Takeaways([])),
          authStateProvider.overrideWith((_) => _Auth(const AuthState())),
          venueSettingsProvider.overrideWith(
            (_) => _Settings(const VenueSettingsDto()),
          ),
          prepTimeByItemProvider.overrideWithValue(const {'i': 5}),
          wsConnStateProvider.overrideWithValue(WsConnState.open),
          ...tickerOverrides,
        ],
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const Scaffold(body: OrdersScreen()),
        ),
      ),
    );
    final context = tester.element(find.byType(OrdersScreen));
    final l10n = AppL10n.of(context);
    await tester.tap(find.text(segment ?? l10n.ordPreparing));
    await tester.pump(const Duration(milliseconds: 300));
    return ProviderScope.containerOf(context);
  }

  for (final language in ['id', 'en']) {
    testWidgets('$language: capture survives host echo until acknowledgement', (
      tester,
    ) async {
      final container = await pumpBoard(tester, language: language);
      final context = tester.element(find.byType(OrdersScreen));
      final l10n = AppL10n.of(context);
      final colors = Theme.of(context).extension<SatColors>()!;
      final captureClock = formatClockId(_captureTime.toIso8601String());

      void expectCaptured() {
        expect(find.text(l10n.capturedLine), findsOneWidget);
        expect(find.text(language == 'id' ? 'TERKIRIM' : 'SENT'), findsNothing);
        expect(find.text(l10n.ordSince(captureClock)), findsOneWidget);
        expect(find.textContaining('T18:02'), findsNothing);
        expect(find.textContaining(_note, findRichText: true), findsOneWidget);
        final elapsed = tester.widget<Text>(find.text(l10n.durMins(30)));
        expect(elapsed.style?.color, isNot(colors.urgent));
      }

      expectCaptured();
      container.read(_hostTickets).replace([_delivered()]);
      await tester.pump();
      expectCaptured();
      expect(find.text('Ayam panggang', findRichText: true), findsOneWidget);

      container.read(_events.notifier).state = [];
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n.capturedLine), findsNothing);
      expect(find.text(language == 'id' ? 'TERKIRIM' : 'SENT'), findsOneWidget);
      expect(find.text(l10n.ordSince(captureClock)), findsOneWidget);
      expect(find.text(l10n.ordSince('18:22')), findsNothing);
      final elapsed = tester.widget<Text>(find.text(l10n.durMins(10)));
      expect(elapsed.style?.color, colors.urgent);
      expect(find.textContaining(_note, findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (status, segment, label) in [
    (TicketStatus.ready, 'Siap', 'SIAP DIAMBIL'),
    (TicketStatus.voided, 'Selesai', 'DIBATALKAN'),
  ]) {
    testWidgets('capture retains the $status state', (tester) async {
      await pumpBoard(
        tester,
        host: [_delivered(status: status)],
        segment: segment,
      );
      expect(find.text('Tertangkap'), findsOneWidget);
      expect(find.text(label), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ordinary orders retain their sent clock and hide blank notes', (
    tester,
  ) async {
    await pumpBoard(
      tester,
      events: [],
      host: [_delivered().copyWith(capturedAtTime: null, note: '  ')],
    );
    expect(find.text('sejak 18:22'), findsOneWidget);
    expect(find.text('Tertangkap'), findsNothing);
    expect(find.byType(NoteLine), findsNothing);
  });

  for (final size in [const Size(360, 800), const Size(1280, 800)]) {
    testWidgets('full note wraps at $size with larger text', (tester) async {
      // Exercise row wrapping in Ready, independently of the existing
      // Active/Done scope toggle's width limit at large text scales.
      await pumpBoard(
        tester,
        size: size,
        textScale: 1.5,
        host: [_delivered(status: TicketStatus.ready)],
        segment: size.width >= 1024 ? 'Siap diambil' : 'Siap',
      );
      final note = tester.widget<Text>(
        find.descendant(of: find.byType(NoteLine), matching: find.byType(Text)),
      );
      expect(note.maxLines, isNull);
      expect(note.overflow, isNot(TextOverflow.ellipsis));
      expect(note.textSpan!.toPlainText(), contains(_note));
      expect(tester.takeException(), isNull);
    });
  }
}

// Seeded snapshots exercise the real screen/projection without opening IO.
class _Snapshot<T> extends StateNotifier<T> {
  _Snapshot(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tickets extends _Snapshot<Map<String, List<Ticket>>>
    implements TicketsRepository {
  _Tickets(super.state);
  void replace(List<Ticket> tickets) => state = {'v': tickets};
}

class _Tables extends _Snapshot<List<VenueTable>> implements TablesRepository {
  _Tables(super.state);
}

class _Staff extends _Snapshot<List<AppUser>> implements StaffRepository {
  _Staff(super.state);
}

class _Zones extends _Snapshot<List<Zone>> implements ZonesRepository {
  _Zones(super.state);
}

class _Takeaways extends _Snapshot<List<TakeawayVisit>>
    implements TakeawayRepository {
  _Takeaways(super.state);
}

class _Auth extends _Snapshot<AuthState> implements AuthRepository {
  _Auth(super.state);
}

class _Settings extends _Snapshot<VenueSettingsDto>
    implements VenueSettingsRepository {
  _Settings(super.state);
}
