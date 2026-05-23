import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;

import 'package:satset/data/services/secure_storage_service.dart';

/// Holds the LAN connection parameters the ApiClient needs.
class ApiConfig {
  final Uri baseUri;

  /// SHA-256 fingerprint of the server's TLS certificate (lowercase hex).
  /// Empty in server-mode loopback where the runtime trusts its own cert.
  final String trustedFingerprint;

  const ApiConfig({required this.baseUri, required this.trustedFingerprint});
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
    final p = pinned.toLowerCase();
    if (!isLoopback && p.isEmpty) {
      throw StateError(
          'trustedFingerprint required for non-loopback host');
    }
    return HttpClient()
      ..badCertificateCallback = (cert, h, port) {
        if (isLoopback && p.isEmpty) return true;
        final got = sha256.convert(cert.der).toString().toLowerCase();
        return got == p;
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

  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    final uri = _config.baseUri.resolve(path).replace(queryParameters: query);
    final r = await _inner.get(uri, headers: await _headers());
    return _decode(r);
  }

  Future<dynamic> postJson(String path, Object body) async {
    final uri = _config.baseUri.resolve(path);
    final r = await _inner.post(uri, headers: await _headers(), body: jsonEncode(body));
    return _decode(r);
  }

  Future<dynamic> patchJson(String path, Object body) async {
    final uri = _config.baseUri.resolve(path);
    final r = await _inner.patch(uri, headers: await _headers(), body: jsonEncode(body));
    return _decode(r);
  }

  Future<void> delete(String path) async {
    final uri = _config.baseUri.resolve(path);
    final r = await _inner.delete(uri, headers: await _headers());
    _decode(r);
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
