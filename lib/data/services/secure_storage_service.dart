import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keychain/Keystore-backed secrets: JWT session token, device id and
/// device-cert material. Repositories must not touch these keys directly.
class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? backend])
    : _s = backend ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  static const _kToken = 'satset.session.jwt';
  static const _kLoginAt = 'satset.session.loginAt';
  static const _kMe = 'satset.session.me';
  static const _kAdminConfirmedAt = 'satset.admin.confirmedAt';
  static const _kDeviceId = 'satset.device.id';
  static const _kDeviceCert = 'satset.device.cert.pem';
  static const _kDeviceKey = 'satset.device.key.pem';
  static const _kServerFingerprint = 'satset.server.fingerprint';
  static const _kServerCert = 'satset.server.cert.pem';

  Future<String?> readToken() => _s.read(key: _kToken);
  Future<void> writeToken(String? v) =>
      v == null ? _s.delete(key: _kToken) : _s.write(key: _kToken, value: v);

  Future<DateTime?> readLoginAt() async {
    final s = await _s.read(key: _kLoginAt);
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  Future<void> writeLoginAt(DateTime? v) => v == null
      ? _s.delete(key: _kLoginAt)
      : _s.write(key: _kLoginAt, value: v.toIso8601String());

  /// Last `/auth/me` payload, verbatim JSON. Restores the session when the
  /// host is unreachable at boot: without it a terputus handset that
  /// restarts has no capabilities and lands on the PIN screen it cannot pass.
  /// Cleared with the token, so it can never outlive the session it describes.
  /// See ADR-0090.
  Future<String?> readMe() => _s.read(key: _kMe);
  Future<void> writeMe(String? v) =>
      v == null ? _s.delete(key: _kMe) : _s.write(key: _kMe, value: v);

  /// Last time the Firebase admin eligibility listener confirmed `active`
  /// *from the server* (not cache). Drives the offline staleness guard.
  Future<DateTime?> readAdminConfirmedAt() async {
    final s = await _s.read(key: _kAdminConfirmedAt);
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  Future<void> writeAdminConfirmedAt(DateTime v) =>
      _s.write(key: _kAdminConfirmedAt, value: v.toIso8601String());

  Future<String?> readDeviceId() => _s.read(key: _kDeviceId);
  Future<void> writeDeviceId(String v) => _s.write(key: _kDeviceId, value: v);

  Future<String?> readServerFingerprint() => _s.read(key: _kServerFingerprint);
  Future<void> writeServerFingerprint(String? v) => v == null
      ? _s.delete(key: _kServerFingerprint)
      : _s.write(key: _kServerFingerprint, value: v);

  Future<String?> readServerCert() => _s.read(key: _kServerCert);
  Future<void> writeServerCert(String? v) => v == null
      ? _s.delete(key: _kServerCert)
      : _s.write(key: _kServerCert, value: v);

  Future<String?> readDeviceCert() => _s.read(key: _kDeviceCert);
  Future<void> writeDeviceCert(String? v) => v == null
      ? _s.delete(key: _kDeviceCert)
      : _s.write(key: _kDeviceCert, value: v);

  Future<String?> readDeviceKey() => _s.read(key: _kDeviceKey);
  Future<void> writeDeviceKey(String? v) => v == null
      ? _s.delete(key: _kDeviceKey)
      : _s.write(key: _kDeviceKey, value: v);

  Future<void> clearSession() async {
    await _s.delete(key: _kToken);
    await _s.delete(key: _kLoginAt);
    await _s.delete(key: _kMe);
  }

  Future<void> clearPairing() async {
    await _s.delete(key: _kToken);
    await _s.delete(key: _kServerFingerprint);
    await _s.delete(key: _kServerCert);
    await _s.delete(key: _kDeviceCert);
    await _s.delete(key: _kDeviceKey);
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);
