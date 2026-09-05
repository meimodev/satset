// Accepting a guest order can be refused — the stock rollback is the tidy
// case — and the queue used to swallow it whole.
//
// `_act` did not catch, so an `ApiException` from `/selforder/orders/<id>/
// accept` became an unhandled async error: no snackbar, no log, and the
// `refresh()` behind it never ran, so the row stayed drawn as pending. From
// the floor that is indistinguishable from a button that does nothing.
//
// The code crosses the layer and the sentence is composed here (ADR-0085),
// and it reaches the user through the one error bus (ADR-0103).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/core/localization/report_copy.dart';
import 'package:satset/data/repositories/self_order_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/error_bus_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/l10n/app_localizations.dart';

final _cfg = ApiConfig(
  baseUri: Uri.parse('https://127.0.0.1:9'),
  trustedFingerprint: '',
);

/// An [ApiClient] that refuses every write with one code and answers every
/// read with nothing. The transport is never exercised — only the branch the
/// repository takes when the host says no.
class _RefusingClient extends ApiClient {
  _RefusingClient(this.code)
    : super(config: _cfg, storage: SecureStorageService());

  final String code;

  @override
  Future<dynamic> postJson(
    String path,
    Object body, {
    Duration? timeout,
    String? idempotencyKey,
  }) => throw ApiException(409, '{"code":"$code"}', code);

  @override
  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) async =>
      <String, dynamic>{};
}

void main() {
  ProviderContainer containerFor(String code) => ProviderContainer(
    overrides: [
      apiConfigProvider.overrideWith((ref) => _cfg),
      apiClientProvider.overrideWithValue(_RefusingClient(code)),
      // Never started, so it never emits — the repository only needs a stream
      // to subscribe to.
      wsClientProvider.overrideWithValue(
        WsClient(config: _cfg, storage: SecureStorageService()),
      ),
    ],
  );

  test('a refused accept reaches the error bus with its code', () async {
    final container = containerFor('accept_rejected_by_stock');
    addTearDown(container.dispose);

    final seen = <AppError>[];
    container.read(errorBusServiceProvider).stream.listen(seen.add);

    await container.read(selfOrderProvider.notifier).accept('go-1');
    await Future<void>.delayed(Duration.zero);

    expect(seen, hasLength(1), reason: 'the refusal has to surface somewhere');
    expect(seen.single.code, 'accept_rejected_by_stock');
    expect(
      seen.single.message,
      lookupAppL10n(const Locale('id')).soFailStock,
      reason: 'a code crosses the layer, a sentence is composed here',
    );
  });

  test('a refusal does not take the repository down with it', () async {
    final container = containerFor('already_decided');
    addTearDown(container.dispose);

    // The bar is low and it is the one that was failing: the call completes,
    // the notifier is still alive, and the reload behind it ran.
    await container.read(selfOrderProvider.notifier).reject('go-1', 'other');
    expect(container.read(selfOrderProvider).loading, isFalse);
  });

  group('every code the decide routes can send has words', () {
    final l = lookupAppL10n(const Locale('id'));
    for (final code in [
      'accept_rejected_by_stock',
      'already_decided',
      'not_found',
    ]) {
      test(code, () {
        expect(guestDecisionFailureText(l, code), isNot(l.soFailOther));
      });
    }

    test('and an unknown one still renders a sentence, not a code', () {
      expect(
        guestDecisionFailureText(l, 'a_code_from_a_newer_server'),
        l.soFailOther,
      );
      expect(guestDecisionFailureText(l, null), l.soFailOther);
    });
  });
}
