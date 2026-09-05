import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/repositories/discount_presets_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/ws_client.dart';

final _cfg = ApiConfig(
  baseUri: Uri.parse('https://127.0.0.1:45678/'),
  trustedFingerprint: '',
);

class _Api extends ApiClient {
  _Api() : super(config: _cfg, storage: SecureStorageService());

  Map<String, dynamic> row = {};

  @override
  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) async => {
    'presets': <Object>[],
  };

  @override
  Future<dynamic> postJson(
    String path,
    Object body, {
    Duration? timeout,
    String? idempotencyKey,
  }) async {
    row = {'id': 'p1', ...(body as Map).cast<String, dynamic>()};
    return row;
  }

  @override
  Future<dynamic> patchJson(String path, Object body) async {
    row = {...row, ...(body as Map).cast<String, dynamic>()};
    return row;
  }

  @override
  Future<dynamic> deleteJson(String path, {String? idempotencyKey}) async => {
    'ok': true,
  };
}

void main() {
  test(
    'successful mutations update the local catalogue without a WS echo',
    () async {
      final api = _Api();
      final ws = WsClient(config: _cfg, storage: SecureStorageService());
      final container = ProviderContainer(
        overrides: [
          apiConfigProvider.overrideWith((ref) => _cfg),
          apiClientProvider.overrideWithValue(api),
          wsClientProvider.overrideWithValue(ws),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await ws.dispose();
        api.close();
      });

      final repo = container.read(discountPresetsRepositoryProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await repo.create(
        name: 'Whole bill 10%',
        scope: 'bill',
        kind: 'percent',
        value: 1000,
      );
      expect(
        container.read(discountPresetsRepositoryProvider).single.name,
        'Whole bill 10%',
      );

      await repo.update('p1', name: 'Whole bill 15%', value: 1500);
      expect(
        container.read(discountPresetsRepositoryProvider).single.name,
        'Whole bill 15%',
      );

      await repo.remove('p1');
      expect(container.read(discountPresetsRepositoryProvider), isEmpty);
    },
  );
}
