import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/floor_cache.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/venue_table.dart';

/// A waiter's handset that cold-boots away from its host must still know what
/// the floor *is* (ADR-0133).
///
/// The repositories are app-lifetime notifiers, so a handset that loses the
/// host while running keeps its floor in RAM. The failure this pins is the one
/// after the process dies — which on a phone in an apron pocket is routine.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cfg = ApiConfig(
    baseUri: Uri.parse('https://127.0.0.1:45678/'),
    trustedFingerprint: 'AA:BB',
  );

  const tablesJson = '''
[{"id":"t1","zoneId":"z1","label":"5","pax":4,"capacity":4,
  "status":"occupied","guestName":"Bu Sri","currentVisitId":"v1"}]''';
  const zonesJson =
      '[{"id":"z1","name":"Teras","short":"TR","colorHex":"#FF4DD487"}]';
  const ticketsJson = '''
{"v1":[{"id":"k1","tableId":"t1","visitId":"v1","itemId":"i1",
  "name":"Nasi Goreng","course":"mains","qty":2,"price":25000,
  "status":"sent","sentAt":"2026-09-04T12:30:00.000Z"}]}''';
  const menuJson = '''
{"version":7,
 "categories":[{"id":"c1","name":"Makanan"}],
 "items":[{"id":"i1","categoryId":"c1","name":"Nasi Goreng",
   "basePrice":25000,"unavailable":true}]}''';

  Map<String, Object> seededFloor({String? fingerprint = 'AA:BB'}) => {
    'satset.app_mode': 'client',
    'satset.floor.tables': tablesJson,
    'satset.floor.zones': zonesJson,
    'satset.floor.tickets': ticketsJson,
    'satset.floor.menu': menuJson,
    'satset.floor.at': DateTime(2026, 9, 4, 8, 14).millisecondsSinceEpoch,
    'satset.venue_cache_fp': ?fingerprint,
  };

  Future<PrefsService> freshPrefs(Map<String, Object> seed) async {
    SharedPreferences.setMockInitialValues(seed);
    return PrefsService(await SharedPreferences.getInstance());
  }

  /// Paired at nothing: the shape of a cold boot with no host. The
  /// repositories paint their copy and never get to fetch.
  Future<ProviderContainer> offlineContainer(PrefsService prefs) async {
    final container = ProviderContainer(
      overrides: [
        prefsServiceProvider.overrideWith((_) async => prefs),
        apiConfigProvider.overrideWith((_) => null),
        wsClientProvider.overrideWithValue(
          WsClient(config: cfg, storage: SecureStorageService()),
        ),
      ],
    );
    addTearDown(container.dispose);
    // The repositories read prefs synchronously off `valueOrNull`, so the
    // future has to have landed before the first watch.
    await container.read(prefsServiceProvider.future);
    return container;
  }

  test('the floor survives an offline cold boot', () async {
    final container = await offlineContainer(await freshPrefs(seededFloor()));

    // Read once, with nothing pumped. This is the first frame — the frame the
    // floor used to be empty on.
    final tables = container.read(tablesProvider);
    final zones = container.read(zonesProvider);
    final tickets = container.read(ticketsProvider);
    final menu = container.read(menuRepositoryProvider);

    expect(tables, hasLength(1), reason: 'the floor must survive');
    expect(tables.single.status, TableStatus.occupied);
    expect(
      tables.single.guestName,
      'Bu Sri',
      reason: 'the guest name is the label a waiter finds the party by',
    );
    expect(zones.single.name, 'Teras');
    expect(zones.single.colorHex, 0xFF4DD487, reason: 'colour round-trips');

    expect(
      tickets['v1'],
      hasLength(1),
      reason: 'lines the host acknowledged must come back with the table',
    );
    expect(tickets['v1']!.single.name, 'Nasi Goreng');
    expect(tickets['v1']!.single.qty, 2);

    expect(
      menu.items,
      hasLength(1),
      reason: 'a floor a waiter cannot order from dead-ends one screen later',
    );
    expect(
      menu.items.single.isSoldOut,
      isTrue,
      reason: 'the sold-out flag freezes with the copy and ships as-is — it '
          'was true when written and usually still is (ADR-0133 §Q8)',
    );
  });

  test('a restored floor says so, stamped with when it was written', () async {
    final container = await offlineContainer(await freshPrefs(seededFloor()));
    container.read(tablesProvider);

    expect(
      container.read(floorCacheProvider).restoredAt.value,
      DateTime(2026, 9, 4, 8, 14),
      reason: 'the banner needs the stamp, not just the fact',
    );
  });

  test('a foreign certificate wipes the copy', () async {
    // The venue cache dies with the certificate, never with the address: a
    // DHCP turnover must not destroy the floor of the venue it belongs to
    // (ADR-0080, ADR-0128).
    final prefs = await freshPrefs(seededFloor());
    await prefs.clearVenueCache();

    final container = await offlineContainer(prefs);
    expect(container.read(tablesProvider), isEmpty);
    expect(container.read(zonesProvider), isEmpty);
    expect(container.read(ticketsProvider), isEmpty);
    expect(container.read(menuRepositoryProvider).items, isEmpty);
    expect(container.read(floorCacheProvider).restoredAt.value, isNull);
  });

  test('the host does not keep a copy of its own floor', () async {
    // Server mode talks HTTP to a server in its own process. A cache whose
    // invalidation story is "the paired certificate changed" is nonsense on
    // the device holding that certificate (ADR-0133 §Q15).
    final seed = seededFloor()..['satset.app_mode'] = 'server';
    final container = await offlineContainer(await freshPrefs(seed));

    expect(container.read(tablesProvider), isEmpty);
    expect(container.read(floorCacheProvider).restoredAt.value, isNull);
  });

  test('a copy this device cannot decode does not take the floor down', () async {
    final seed = seededFloor()..['satset.floor.tables'] = '{ not json';
    final container = await offlineContainer(await freshPrefs(seed));

    expect(container.read(tablesProvider), isEmpty);
    expect(
      container.read(zonesProvider),
      hasLength(1),
      reason: 'four keys, not one blob: one bad payload keeps the other three',
    );
  });

  test('the copy is written from state, so an offline seat survives', () async {
    // The seat that matters has no refetch behind it: `seat` mutates state
    // optimistically and parks the intent on the send queue. A copy written
    // only on refetch cold-boots to a free table with a queued order under it.
    final prefs = await freshPrefs(seededFloor());
    final container = await offlineContainer(prefs);
    final repo = container.read(tablesProvider.notifier);
    container.read(tablesProvider);

    repo.markPending('t1');
    // The write is debounced (ADR-0133 §Q5) — a busy floor is dozens of frames
    // a minute and each one is a `state =`.
    await Future<void>.delayed(const Duration(seconds: 3));

    final written = jsonDecode(prefs.floorJson('tables')!) as List;
    expect(
      (written.single as Map)['status'],
      'pending',
      reason: 'the local mutation, not just the last thing the host said',
    );
  });
}
