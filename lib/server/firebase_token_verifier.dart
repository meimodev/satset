import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

import 'package:satset/core/log/sat_log.dart';

/// A Firebase admin proven by a verified ID token. Carries only the fields the
/// host needs to admit an [[Admin-client]]: the uid (for the local user row),
/// the fleet [role] and [venueId] custom claims, and a display [name].
class VerifiedFirebaseAdmin {
  final String uid;
  final String role;
  final String venueId;
  final String name;
  const VerifiedFirebaseAdmin({
    required this.uid,
    required this.role,
    required this.venueId,
    required this.name,
  });
}

/// Verifies Firebase Authentication **ID tokens** offline so the [[Main Device]]
/// host can admit admin-clients without its own Firebase Admin SDK (ADR-0017).
///
/// Trust chain: Google signs each ID token (RS256) with a rotating private key;
/// the matching X.509 public certs are published at a well-known endpoint with
/// a `Cache-Control: max-age`. We fetch + cache them, pick the cert by the
/// token's `kid` header, verify the signature, then check `iss`/`aud`/`exp`.
/// The cache means verification keeps working offline until the certs expire
/// (~a few hours) — and we fall back to stale certs if a refresh fails while
/// offline, so a brief outage doesn't lock out admin-clients.
class FirebaseTokenVerifier {
  FirebaseTokenVerifier({required this.projectId, http.Client? client})
    : _http = client ?? http.Client();

  /// Firebase project id (matches `android/app/google-services.json`). Both the
  /// `aud` and the `iss` suffix of a valid ID token must equal this.
  final String projectId;
  final http.Client _http;

  static const _certsUrl =
      'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

  Map<String, String> _certs = const {};
  DateTime _certsExpiry = DateTime.fromMillisecondsSinceEpoch(0);

  Future<Map<String, String>> _certsFor() async {
    if (_certs.isNotEmpty && DateTime.now().isBefore(_certsExpiry)) {
      return _certs;
    }
    try {
      final res = await _http.get(Uri.parse(_certsUrl));
      if (res.statusCode != 200) {
        if (_certs.isNotEmpty) return _certs; // stale-while-offline
        throw StateError('certs http ${res.statusCode}');
      }
      final body = (jsonDecode(res.body) as Map).cast<String, dynamic>();
      _certs = {for (final e in body.entries) e.key: e.value as String};
      final cc = res.headers['cache-control'] ?? '';
      final m = RegExp(r'max-age=(\d+)').firstMatch(cc);
      final maxAge = m != null ? int.parse(m.group(1)!) : 3600;
      _certsExpiry = DateTime.now().add(Duration(seconds: maxAge));
      return _certs;
    } catch (e) {
      if (_certs.isNotEmpty) return _certs; // offline: keep using cached certs
      rethrow;
    }
  }

  /// Verify [idToken] and return the admin it proves, or null if the token is
  /// malformed, mis-signed, expired, or issued for a different project. Never
  /// throws on an invalid token — only on an unrecoverable certs fetch.
  Future<VerifiedFirebaseAdmin?> verify(String idToken) async {
    final parts = idToken.split('.');
    if (parts.length != 3) return null;

    final String? kid;
    try {
      final header =
          (jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
              )
              as Map);
      kid = header['kid'] as String?;
    } catch (_) {
      return null;
    }
    if (kid == null) return null;

    final certs = await _certsFor();
    final certPem = certs[kid];
    if (certPem == null) return null;

    try {
      final jwt = JWT.verify(idToken, RSAPublicKey.cert(certPem));
      final p = (jwt.payload as Map).cast<String, dynamic>();
      if (p['aud'] != projectId) return null;
      if (p['iss'] != 'https://securetoken.google.com/$projectId') return null;
      final exp = (p['exp'] as num?)?.toInt() ?? 0;
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowSec >= exp) return null;
      final sub = (p['sub'] as String?)?.trim() ?? '';
      if (sub.isEmpty) return null;
      return VerifiedFirebaseAdmin(
        uid: sub,
        role: (p['role'] as String?)?.trim() ?? '',
        venueId: (p['venueId'] as String?)?.trim() ?? '',
        name: (p['name'] as String?)?.trim() ?? '',
      );
    } catch (e) {
      SatLog.srv('fbtoken verify reject $e');
      return null;
    }
  }
}
