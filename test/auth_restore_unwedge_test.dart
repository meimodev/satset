import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/secure_storage_service.dart';

/// `restoring` gates a full-screen spinner with no button on it. Every path out
/// of `restoreFromStoredToken` has to clear it, including the ones that throw
/// before the request is ever made — a secure-storage failure used to leave the
/// flag set for the life of the process, and the only way past the spinner was
/// to kill the app.
class _ThrowingStorage extends SecureStorageService {
  @override
  Future<String?> readToken() async => throw StateError('keystore unavailable');
}

class _EmptyStorage extends SecureStorageService {
  @override
  Future<String?> readToken() async => null;
}

void main() {
  ProviderContainer containerWith(SecureStorageService storage) =>
      ProviderContainer(
        overrides: [
          secureStorageServiceProvider.overrideWithValue(storage),
          // Non-null only so the early `cfg == null` bail is not the thing
          // under test — nothing here ever reaches the wire.
          apiConfigProvider.overrideWith(
            (ref) => ApiConfig(
              baseUri: Uri.parse('https://127.0.0.1:1'),
              trustedFingerprint: '',
            ),
          ),
        ],
      );

  test('restoring clears when the token read itself throws', () async {
    final c = containerWith(_ThrowingStorage());
    addTearDown(c.dispose);
    final repo = c.read(authStateProvider.notifier);

    await repo.restoreFromStoredToken();

    expect(
      c.read(authStateProvider).restoring,
      isFalse,
      reason: 'a throw before the request must not wedge the spinner',
    );
  });

  test('restoring clears on the early return when there is no token', () async {
    final c = containerWith(_EmptyStorage());
    addTearDown(c.dispose);
    final repo = c.read(authStateProvider.notifier);

    await repo.restoreFromStoredToken();

    expect(c.read(authStateProvider).restoring, isFalse);
  });
}
