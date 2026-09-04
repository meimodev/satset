import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satset/data/models/discount_dto.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/discount_presets_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/ws_client.dart';

/// A client that cold-boots away from its host must still know what the venue
/// is (ADR-0128). Every switch on `VenueSettingsDto` fails closed through its
/// freezed default, so an uncached boot does not merely look wrong — it looks
/// like a venue that never opted in to anything.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cfg = ApiConfig(
    baseUri: Uri.parse('https://127.0.0.1:45678/'),
    trustedFingerprint: '',
  );

  Future<PrefsService> freshPrefs([Map<String, Object> seed = const {}]) async {
    SharedPreferences.setMockInitialValues(seed);
    return PrefsService(await SharedPreferences.getInstance());
  }

  /// Paired at nothing, which is the shape of a cold boot with no host: the
  /// repositories paint their cache and never get to fetch.
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

  test('a cached venue keeps its programs across an offline cold boot', () async {
    const dto = VenueSettingsDto(
      membersEnabled: true,
      memberPointsEnabled: true,
      memberEarnPerThousand: 3,
      guestOrderingEnabled: true,
      modules: ['members'],
    );
    final prefs = await freshPrefs({
      'satset.venue_settings': jsonEncode(dto.toJson()),
    });
    final container = await offlineContainer(prefs);

    // Read once, with nothing pumped: this is the first frame, which is the
    // frame the member panel disappeared on.
    final booted = container.read(venueSettingsProvider);

    expect(
      booted.membersEnabled,
      isTrue,
      reason: 'the panel gate is what vanished; it is what has to come back',
    );
    expect(booted.membersOn, isTrue);
    expect(
      booted.memberEarnPerThousand,
      3,
      reason: 'a factory earn rate is a wrong number, not a missing one',
    );
    expect(booted.guestOrderingEnabled, isTrue);
  });

  test('an uncached device still fails closed', () async {
    final prefs = await freshPrefs();
    final container = await offlineContainer(prefs);

    expect(
      container.read(venueSettingsProvider).membersOn,
      isFalse,
      reason: 'no cache is no knowledge — that is correct, not a regression',
    );
  });

  test('the pre-0128 shape cache is still honoured once', () async {
    final prefs = await freshPrefs({
      'satset.venue_shape': jsonEncode({
        'modules': <String>[],
        'counterConfig': ['menuHome'],
      }),
    });
    final container = await offlineContainer(prefs);

    final booted = container.read(venueSettingsProvider);
    expect(
      booted.modules,
      isEmpty,
      reason:
          'an upgrade must not re-acquire the ADR-0115 flicker — and [] is '
          '"holds no module", never "never mirrored"',
    );
    expect(booted.counterConfig, ['menuHome']);
  });

  test('discount presets open from cache with no host', () async {
    const preset = DiscountPresetDto(
      id: 'p1',
      name: 'Promo',
      scope: 'bill',
      kind: 'percent',
      value: 1000,
    );
    final prefs = await freshPrefs({
      'satset.discount_presets': jsonEncode([preset.toJson()]),
    });
    final container = await offlineContainer(prefs);

    final presets = container.read(discountPresetsRepositoryProvider);
    expect(presets.map((p) => p.id), ['p1']);
    expect(
      container
          .read(discountPresetsRepositoryProvider.notifier)
          .forScope('bill'),
      isNotEmpty,
      reason: 'the picker asks by scope, and it opens mid-transaction',
    );
  });

  test('the pairing setters no longer touch the cache', () async {
    // They used to. `relocateServer` rewrites the paired host on every DHCP
    // turnover, so clearing there threw a venue's own settings away on a
    // router reboot (ADR-0080: the certificate is the identity, not the
    // address). Provenance is the fingerprint's job now — see the cases below.
    final prefs = await freshPrefs({
      'satset.paired.host': '192.168.1.10',
      'satset.venue_cache_fp': 'FP-A',
      'satset.venue_settings': jsonEncode(
        const VenueSettingsDto(membersEnabled: true).toJson(),
      ),
    });

    await prefs.setPairedHost('192.168.1.99');

    expect(prefs.venueSettingsJson(), isNotNull);
    expect(prefs.venueCacheFingerprint(), 'FP-A');
  });

  /// The certificate is the venue's identity; its address is not (ADR-0080).
  /// `relocateServer` rewrites the paired host on every DHCP turnover, so a
  /// cache keyed on host:port died on a router reboot — at the exact moment
  /// the device could not reach its host and the cache was all it had.
  Future<ProviderContainer> containerAt(
    PrefsService prefs,
    String fingerprint,
    String host,
  ) async {
    final container = ProviderContainer(
      overrides: [
        prefsServiceProvider.overrideWith((_) async => prefs),
        apiConfigProvider.overrideWith(
          (_) => ApiConfig(
            baseUri: Uri.parse('https://$host:7443/'),
            trustedFingerprint: fingerprint,
          ),
        ),
        apiClientProvider.overrideWithValue(_DeadApi()),
        wsClientProvider.overrideWithValue(
          WsClient(config: cfg, storage: SecureStorageService()),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(prefsServiceProvider.future);
    // Construct it: the provider is lazy, and an unread provider runs no
    // bootstrap and therefore no provenance check.
    container.read(venueSettingsProvider);
    return container;
  }

  Future<PrefsService> cachedVenue(String fingerprint) => freshPrefs({
    'satset.venue_cache_fp': fingerprint,
    'satset.venue_settings': jsonEncode(
      const VenueSettingsDto(
        membersEnabled: true,
        modules: ['members'],
      ).toJson(),
    ),
    'satset.discount_presets': jsonEncode([
      const DiscountPresetDto(id: 'p1').toJson(),
    ]),
  });

  test('the same server at a new address keeps its cache', () async {
    final prefs = await cachedVenue('FP-A');
    final container = await containerAt(prefs, 'FP-A', '192.168.1.99');
    await pumpEventQueue();

    expect(
      container.read(venueSettingsProvider).membersOn,
      isTrue,
      reason: 'a DHCP turnover is not a new venue',
    );
    expect(prefs.venueSettingsJson(), isNotNull);
    expect(prefs.discountPresetsJson(), isNotNull);
  });

  test('a different certificate drops the cache and the painted state', () async {
    final prefs = await cachedVenue('FP-A');
    final container = await containerAt(prefs, 'FP-B', '192.168.1.10');
    await pumpEventQueue();

    expect(prefs.venueSettingsJson(), isNull);
    expect(prefs.discountPresetsJson(), isNull);
    expect(prefs.venueCacheFingerprint(), isNull);
    expect(
      container.read(venueSettingsProvider).membersOn,
      isFalse,
      reason:
          'clearing prefs is not enough — the constructor already painted the '
          'foreign venue, so state has to go back to fail-closed too',
    );
  });

  test('a cache stamped before the label existed is kept, not dropped', () async {
    final prefs = await freshPrefs({
      'satset.venue_settings': jsonEncode(
        const VenueSettingsDto(membersEnabled: true, modules: ['members'])
            .toJson(),
      ),
    });
    final container = await containerAt(prefs, 'FP-A', '192.168.1.10');
    await pumpEventQueue();

    expect(
      container.read(venueSettingsProvider).membersOn,
      isTrue,
      reason: 'unknown provenance is not foreign provenance',
    );
  });

  test('a boot that beat the paired address still fetches when it lands', () async {
    // The repository is constructed at app root (the locale notifier reads
    // `serviceTerm`, ADR-0127), which on a real cold launch is before the
    // paired address has been read off prefs. Giving up there is why a device
    // ran for weeks on a shape cached before a module was bought.
    final prefs = await freshPrefs();
    final cfg = StateController<ApiConfig?>(null);
    var fetches = 0;
    final container = ProviderContainer(
      overrides: [
        prefsServiceProvider.overrideWith((_) async => prefs),
        apiConfigProvider.overrideWith((ref) => ref.watch(_cfgProvider)),
        _cfgProvider.overrideWith((_) => cfg),
        apiClientProvider.overrideWithValue(_CountingApi(() => fetches++)),
        wsClientProvider.overrideWithValue(
          WsClient(
            config: ApiConfig(baseUri: Uri.parse('https://x/'), trustedFingerprint: ''),
            storage: SecureStorageService(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(prefsServiceProvider.future);

    container.read(venueSettingsProvider);
    await pumpEventQueue();
    expect(fetches, 0, reason: 'no host yet — there is nothing to ask');

    cfg.state = ApiConfig(
      baseUri: Uri.parse('https://127.0.0.1:45678/'),
      trustedFingerprint: '',
    );
    await pumpEventQueue();
    expect(
      fetches,
      1,
      reason: 'the address landed, so the settings must be asked for',
    );
    expect(container.read(venueSettingsProvider).membersEnabled, isTrue);
  });
}

final _cfgProvider = StateNotifierProvider<StateController<ApiConfig?>, ApiConfig?>(
  (_) => StateController<ApiConfig?>(null),
);

class _CountingApi extends ApiClient {
  _CountingApi(this.onGet)
    : super(
        config: ApiConfig(
          baseUri: Uri.parse('https://127.0.0.1:45678/'),
          trustedFingerprint: '',
        ),
        storage: SecureStorageService(),
      );
  final void Function() onGet;

  @override
  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) async {
    onGet();
    return const VenueSettingsDto(membersEnabled: true).toJson();
  }
}

class _DeadApi extends ApiClient {
  _DeadApi()
    : super(
        config: ApiConfig(
          baseUri: Uri.parse('https://127.0.0.1:45678/'),
          trustedFingerprint: '',
        ),
        storage: SecureStorageService(),
      );

  /// Moved, and still not answering — the relocator case, where the cache is
  /// the only thing the till has.
  @override
  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) async =>
      throw const ApiException(0, 'unreachable');
}
