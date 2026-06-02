import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/services/secure_storage_service.dart';

/// Holds the LAN connection parameters the ApiClient needs.
class ApiConfig {
  final Uri baseUri;

  /// SHA-256 fingerprint of the server's TLS certificate (lowercase hex).
  /// Empty in server-mode loopback where the runtime trusts its own cert.
  final String trustedFingerprint;

  const ApiConfig({required this.baseUri, required this.trustedFingerprint});

  /// Value equality so re-publishing an identical config (e.g. mDNS re-selects
  /// the same paired server on the PIN screen after a sign-out) can be treated
  /// as a no-op. Without this, every re-select churns `apiConfigProvider` and
  /// rebuilds every repository keyed on it — re-running their one-shot
  /// `_bootstrap` while still unauthenticated, which 401s and strands the
  /// list empty until app restart.
  @override
  bool operator ==(Object other) =>
      other is ApiConfig &&
      other.baseUri == baseUri &&
      other.trustedFingerprint == trustedFingerprint;

  @override
  int get hashCode => Object.hash(baseUri, trustedFingerprint);
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  final String? code;
  const ApiException(this.statusCode, this.body, [this.code]);

  @override
  String toString() => 'ApiException($statusCode${code != null ? ' $code' : ''}): $body';
}

/// REST client with bearer auth, device ID header and TLS fingerprint
/// pinning. Stateless — repositories own the lifecycle of cached responses.
class ApiClient {
  /// Per-request ceiling. Without it a dead/stale server host blocks on the
  /// OS connect timeout (~110s, errno 110) — long enough that the PIN screen
  /// freezes on "verifying". Fail fast so the error surfaces and the user can
  /// re-pick a reachable server.
  static const Duration requestTimeout = Duration(seconds: 8);

  ApiClient({
    required ApiConfig config,
    required SecureStorageService storage,
  })  : _config = config,
        _storage = storage,
        _inner = _buildClient(config);

  final ApiConfig _config;
  final SecureStorageService _storage;
  final http.Client _inner;

  static http.Client _buildClient(ApiConfig cfg) {
    final pinned = cfg.trustedFingerprint.toLowerCase();
    final host = cfg.baseUri.host;
    final loopback = isLoopbackHost(host);
    if (!loopback && pinned.isEmpty) {
      throw StateError(
          'ApiConfig.trustedFingerprint required for non-loopback host');
    }
    final io = buildPinnedHttpClient(pinned, isLoopback: loopback);
    return http_io.IOClient(io);
  }

  /// True for hosts where TLS pinning may be relaxed for local server-mode
  /// development (the runtime trusts its own self-signed cert on loopback).
  static bool isLoopbackHost(String host) =>
      host == '127.0.0.1' || host == 'localhost' || host == '::1';

  /// Build an [HttpClient] whose `badCertificateCallback` accepts only a
  /// certificate whose SHA-256 matches [pinned], with a single loopback
  /// escape hatch when [pinned] is empty and [isLoopback] is true.
  ///
  /// Shared with [WsClient] so REST and WebSocket pinning cannot diverge.
  static HttpClient buildPinnedHttpClient(
    String pinned, {
    required bool isLoopback,
  }) {
    final p = pinned.toLowerCase().replaceAll(':', '').replaceAll(' ', '');
    if (!isLoopback && p.isEmpty) {
      throw StateError(
          'trustedFingerprint required for non-loopback host');
    }
    return HttpClient()
      ..badCertificateCallback = (cert, h, port) {
        if (isLoopback) return true;
        final got = sha256.convert(cert.der).toString().toLowerCase();
        final match = got == p;
        SatLog.http('TLS verify: got=$got expected=$p match=$match host=$h port=$port');
        return match;
      };
  }

  Future<Map<String, String>> _headers({Map<String, String>? extra}) async {
    final token = await _storage.readToken();
    final deviceId = await _storage.readDeviceId();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (deviceId != null && deviceId.isNotEmpty) 'X-Device-Id': deviceId,
      ...?extra,
    };
  }

  Future<dynamic> getJson(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> postJson(String path, Object body) =>
      _send('POST', path, body: body);

  Future<dynamic> patchJson(String path, Object body) =>
      _send('PATCH', path, body: body);

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<dynamic> deleteJson(String path) => _send('DELETE', path);

  /// Fetch raw bytes over the pinned client (e.g. a menu photo). Plain
  /// `Image.network` cannot be used — it bypasses TLS pinning and fails the
  /// self-signed cert. See docs/adr/0014-menu-photo-blob-and-pinned-byte-fetch.md.
  Future<Uint8List> getBytes(String path) async {
    final uri = _config.baseUri.resolve(path);
    final headers = await _headers();
    final r = await _inner.get(uri, headers: headers);
    if (r.statusCode >= 200 && r.statusCode < 300) return r.bodyBytes;
    throw ApiException(r.statusCode, r.body);
  }

  /// PUT raw bytes (e.g. a menu photo upload). Body is sent verbatim.
  Future<dynamic> putBytes(
    String path,
    List<int> bytes, {
    String contentType = 'image/jpeg',
  }) async {
    final uri = _config.baseUri.resolve(path);
    final headers = await _headers(extra: {'Content-Type': contentType});
    final r = await _inner.put(uri, headers: headers, body: bytes);
    return _decode(r);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = _config.baseUri.resolve(path).replace(queryParameters: query);
    final headers = await _headers();
    final encoded = body == null ? null : jsonEncode(body);
    final sw = Stopwatch()..start();
    try {
      final r = await (switch (method) {
        'GET' => _inner.get(uri, headers: headers),
        'POST' => _inner.post(uri, headers: headers, body: encoded),
        'PATCH' => _inner.patch(uri, headers: headers, body: encoded),
        'DELETE' => _inner.delete(uri, headers: headers),
        _ => throw StateError('Unsupported method $method'),
      })
          .timeout(requestTimeout);
      SatLog.http('$method $path → ${r.statusCode} ${sw.elapsedMilliseconds}ms');
      return _decode(r);
    } on ApiException catch (e) {
      SatLog.http(
          '$method $path ✗ ${e.statusCode} ${e.code ?? "-"} ${sw.elapsedMilliseconds}ms');
      rethrow;
    } catch (e, st) {
      SatLog.err('http $method $path', e, st);
      rethrow;
    }
  }

  dynamic _decode(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return null;
      return jsonDecode(r.body);
    }
    String? code;
    try {
      final j = jsonDecode(r.body);
      if (j is Map && j['code'] is String) code = j['code'] as String;
    } catch (_) {}
    throw ApiException(r.statusCode, r.body, code);
  }

  void close() => _inner.close();
}

/// Lazily-constructed; replaced when mode or pairing changes.
final apiConfigProvider = StateProvider<ApiConfig?>((ref) => null);

/// True iff [apiConfigProvider] is populated. Drives the router pair-gate
/// and is the single signal repositories use to decide whether `_bootstrap`
/// is allowed to hit the network.
final pairedProvider = Provider<bool>(
    (ref) => ref.watch(apiConfigProvider) != null);

final apiClientProvider = Provider<ApiClient>((ref) {
  final cfg = ref.watch(apiConfigProvider);
  if (cfg == null) {
    throw StateError('ApiConfig not initialised. Boot mode/pair first.');
  }
  final storage = ref.watch(secureStorageServiceProvider);
  final client = ApiClient(config: cfg, storage: storage);
  ref.onDispose(client.close);
  return client;
});
