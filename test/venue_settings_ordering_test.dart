import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/ws_client.dart';

final _config = ApiConfig(
  baseUri: Uri.parse('https://127.0.0.1:45678/'),
  trustedFingerprint: '',
);

const _enabled = VenueSettingsDto(
  membersEnabled: true,
  modules: ['members', 'memberSplit', 'counterService'],
  counterConfig: ['settleAfterSend'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fleet mirror cannot appear saved without a host API', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsService(await SharedPreferences.getInstance());
    final container = ProviderContainer(
      overrides: [
        prefsServiceProvider.overrideWith((_) async => prefs),
        apiConfigProvider.overrideWith((_) => null),
      ],
    );
    addTearDown(container.dispose);
    await container.read(prefsServiceProvider.future);
    final repository = container.read(venueSettingsProvider.notifier);
    await pumpEventQueue();

    await expectLater(
      repository.patch(
        modules: _enabled.modules,
        counterConfig: _enabled.counterConfig,
      ),
      throwsA(isA<ApiException>()),
    );
    expect(container.read(venueSettingsProvider).modules, isNull);
    expect(container.read(venueSettingsProvider).counterConfig, isNull);
    expect(prefs.venueSettingsJson(), isNull);
  });

  for (final oldFails in [false, true]) {
    test('late mirror ${oldFails ? 'error' : 'response'} cannot restore '
        'old fleet config', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PrefsService(await SharedPreferences.getInstance());
      final api = _OverlappingPatchApi();
      final ws = _TestWs();
      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWith((_) async => prefs),
          apiConfigProvider.overrideWith((_) => _config),
          apiClientProvider.overrideWithValue(api),
          wsClientProvider.overrideWithValue(ws),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(ws.updates.close);
      await container.read(prefsServiceProvider.future);
      final repository = container.read(venueSettingsProvider.notifier);
      await pumpEventQueue();

      final oldMirror = repository.patch(modules: [], counterConfig: []);
      await api.firstPatchStarted.future;
      final savedMirror = repository.patch(
        modules: _enabled.modules,
        counterConfig: _enabled.counterConfig,
      );
      if (oldFails) {
        api.failOldPatch();
        await expectLater(oldMirror, throwsA(isA<ApiException>()));
      } else {
        api.completeOldPatch();
        await oldMirror;
      }
      await api.secondPatchStarted.future;
      if (!oldFails) {
        ws.updates.add(
          WsEventDto(
            type: WsEventTypes.venueSettingsUpdated,
            payload: const VenueSettingsDto(
              modules: [],
              counterConfig: [],
            ).toJson(),
            ts: DateTime.utc(2026, 9, 23),
          ),
        );
        await pumpEventQueue();
      }
      api.completeSavedPatch();
      await savedMirror;
      await pumpEventQueue();

      final current = container.read(venueSettingsProvider);
      final cached = VenueSettingsDto.fromJson(
        (jsonDecode(prefs.venueSettingsJson()!) as Map).cast<String, dynamic>(),
      );
      expect(current.modules, _enabled.modules);
      expect(current.counterConfig, _enabled.counterConfig);
      expect(cached.modules, _enabled.modules);
      expect(cached.counterConfig, _enabled.counterConfig);
      expect(api.persisted.modules, _enabled.modules);
      expect(api.persisted.counterConfig, _enabled.counterConfig);
    });
  }

  for (final update in ['fleet mirror', 'live settings', 'reconnect']) {
    for (final fetchFails in [false, true]) {
      test('startup ${fetchFails ? 'error' : 'response'} cannot replace '
          '$update', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = PrefsService(await SharedPreferences.getInstance());
        final api = _DelayedApi();
        final ws = _TestWs();
        final container = ProviderContainer(
          overrides: [
            prefsServiceProvider.overrideWith((_) async => prefs),
            apiConfigProvider.overrideWith((_) => _config),
            apiClientProvider.overrideWithValue(api),
            wsClientProvider.overrideWithValue(ws),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(api.close);
        addTearDown(ws.updates.close);
        await container.read(prefsServiceProvider.future);
        final repository = container.read(venueSettingsProvider.notifier);
        await api.started.future;
        if (update == 'reconnect') {
          ws.updates.add(
            WsEventDto(
              type: WsEventTypes.connected,
              ts: DateTime.utc(2026, 9, 23),
            ),
          );
          await pumpEventQueue();
        } else if (update == 'live settings') {
          ws.updates.add(
            WsEventDto(
              type: WsEventTypes.venueSettingsUpdated,
              payload: _enabled.toJson(),
              ts: DateTime.utc(2026, 9, 23),
            ),
          );
          await pumpEventQueue();
        } else {
          await repository.patch(
            modules: _enabled.modules,
            counterConfig: _enabled.counterConfig,
          );
        }
        if (update != 'reconnect') {
          expect(container.read(venueSettingsProvider).memberSplitOn, isTrue);
        }

        // The read began before the mirror wrote the cloud configuration.
        if (fetchFails) {
          api.response.completeError(const ApiException(0, 'unreachable'));
        } else {
          api.response.complete(
            const VenueSettingsDto(membersEnabled: true).toJson(),
          );
        }
        await pumpEventQueue();
        if (update == 'reconnect') {
          expect(container.read(venueSettingsStatusProvider).isLoading, isTrue);
          api.reconnected.complete(_enabled.toJson());
          await pumpEventQueue();
        }
        final current = container.read(venueSettingsProvider);
        final cached = VenueSettingsDto.fromJson(
          (jsonDecode(prefs.venueSettingsJson()!) as Map)
              .cast<String, dynamic>(),
        );
        expect(
          {
            'runtime member attachment': current.memberSplitOn,
            'runtime automatic settlement': current.counterOn(
              'settleAfterSend',
            ),
            'cached member attachment': cached.memberSplitOn,
            'cached automatic settlement': cached.counterOn('settleAfterSend'),
          },
          {
            'runtime member attachment': true,
            'runtime automatic settlement': true,
            'cached member attachment': true,
            'cached automatic settlement': true,
          },
        );
        expect(
          container.read(venueSettingsStatusProvider),
          const AsyncValue<void>.data(null),
        );
      });
    }
  }
}

class _TestWs extends WsClient {
  _TestWs() : super(config: _config, storage: SecureStorageService());

  final updates = StreamController<WsEventDto>.broadcast();

  @override
  Stream<WsEventDto> get events => updates.stream;
}

class _DelayedApi extends ApiClient {
  _DelayedApi() : super(config: _config, storage: SecureStorageService());

  final started = Completer<void>();
  final response = Completer<dynamic>();
  final reconnected = Completer<dynamic>();

  @override
  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) {
    if (started.isCompleted) return reconnected.future;
    started.complete();
    return response.future;
  }

  @override
  Future<dynamic> patchJson(String path, Object body) async =>
      _enabled.toJson();
}

class _OverlappingPatchApi extends ApiClient {
  _OverlappingPatchApi()
    : super(config: _config, storage: SecureStorageService());

  final firstPatchStarted = Completer<void>();
  final secondPatchStarted = Completer<void>();
  final _oldPatch = Completer<dynamic>();
  final _savedPatch = Completer<dynamic>();
  int _patches = 0;
  VenueSettingsDto persisted = _enabled;

  @override
  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) async => _enabled.toJson();

  @override
  Future<dynamic> patchJson(String path, Object body) {
    if (_patches++ == 0) {
      firstPatchStarted.complete();
      return _oldPatch.future;
    }
    persisted = _enabled;
    secondPatchStarted.complete();
    return _savedPatch.future;
  }

  void completeOldPatch() {
    persisted = const VenueSettingsDto(modules: [], counterConfig: []);
    _oldPatch.complete(persisted.toJson());
  }

  void failOldPatch() =>
      _oldPatch.completeError(const ApiException(503, 'unreachable'));

  void completeSavedPatch() => _savedPatch.complete(_enabled.toJson());
}
