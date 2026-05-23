import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:uuid/uuid.dart';

import 'package:satset/data/models/pair_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';

class PairState {
  final bool busy;
  final String? error;
  final bool paired;
  const PairState({this.busy = false, this.error, this.paired = false});

  PairState copyWith({bool? busy, String? error, bool? paired}) => PairState(
        busy: busy ?? this.busy,
        error: error,
        paired: paired ?? this.paired,
      );
}

class PairViewModel extends StateNotifier<PairState> {
  PairViewModel({
    required this.ref,
    required SecureStorageService storage,
    required PrefsService prefs,
  })  : _storage = storage,
        _prefs = prefs,
        super(const PairState());

  final Ref ref;
  final SecureStorageService _storage;
  final PrefsService _prefs;

  /// Claim a pairing token. [qrJson] is the JSON payload encoded in the QR.
  /// The QR/manual fingerprint MUST be present; the HTTP client only trusts
  /// the server cert when its SHA-256 matches that fingerprint.
  ///
  /// On success, also publishes a fresh [ApiConfig] into [apiConfigProvider]
  /// and kicks an auth-restore so the post-pair `/pin` flow always reaches
  /// the LAN server instead of the dummy fallback.
  Future<void> claim(String qrJson) async {
    state = state.copyWith(busy: true, error: null);
    try {
      final payload =
          PairQrPayloadDto.fromJson(jsonDecode(qrJson) as Map<String, dynamic>);
      final expectedFp = payload.fingerprint.trim().toLowerCase();
      if (expectedFp.isEmpty) {
        throw StateError('fingerprint required for pairing');
      }
      final deviceId = await _storage.readDeviceId() ?? const Uuid().v4();
      await _storage.writeDeviceId(deviceId);

      final req = PairClaimRequestDto(
        token: payload.token,
        deviceId: deviceId,
        deviceLabel: 'satset-client',
        publicKey: '',
      );
      final uri = Uri(
        scheme: 'https',
        host: payload.host,
        port: payload.port,
        path: '/pair/claim',
      );
      final client = _pinnedClient(expectedFp, payload.host);
      final r = await client.post(uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode(req.toJson()));
      client.close();
      if (r.statusCode >= 400) {
        throw StateError('pair failed ${r.statusCode}');
      }
      final res = PairClaimResponseDto.fromJson(
          jsonDecode(r.body) as Map<String, dynamic>);

      // Server-returned fingerprint must match what was scanned/typed.
      if (res.fingerprint.toLowerCase() != expectedFp) {
        throw StateError('fingerprint mismatch — refuse to trust server');
      }

      await _storage.writeServerFingerprint(expectedFp);
      await _storage.writeServerCert(res.serverPublicKey);
      await _prefs.setPairedHost(payload.host);
      await _prefs.setPairedPort(payload.port);

      // Activate the LAN connection immediately so subsequent screens
      // (notably PinScreen) call the server, not the dummy fallback.
      ref.read(apiConfigProvider.notifier).state = ApiConfig(
        baseUri: Uri.parse('https://${payload.host}:${payload.port}'),
        trustedFingerprint: expectedFp,
      );
      // If a token from a previous session is still in storage, restore it
      // through the live API so the auth state reflects server-issued caps.
      await ref.read(authStateProvider.notifier).restoreFromStoredToken();

      state = state.copyWith(busy: false, paired: true);
    } catch (e) {
      state = state.copyWith(busy: false, error: e.toString());
    }
  }

  http.Client _pinnedClient(String pinnedFp, String host) {
    final io = ApiClient.buildPinnedHttpClient(
      pinnedFp,
      isLoopback: ApiClient.isLoopbackHost(host),
    );
    return http_io.IOClient(io);
  }
}

final pairViewModelProvider =
    StateNotifierProvider.autoDispose<PairViewModel, PairState>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final prefs = ref.watch(prefsServiceProvider).requireValue;
  return PairViewModel(ref: ref, storage: storage, prefs: prefs);
});
