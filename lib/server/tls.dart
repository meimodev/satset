import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:satset/core/time/sat_clock.dart';

/// Self-signed leaf cert and SHA-256 fingerprint for the in-app server.
class ServerTls {
  final String certPem;
  final String keyPem;
  final SecurityContext context;
  final String fingerprint;

  ServerTls({
    required this.certPem,
    required this.keyPem,
    required this.context,
    required this.fingerprint,
  });

  late final X509CertificateData _parsed = X509Utils.x509CertificateFromPem(
    certPem,
  );

  /// Cert NotBefore (issued at). UTC.
  DateTime get certIssuedAt =>
      _parsed.tbsCertificate?.validity.notBefore ?? SatClock.realNow();

  /// Cert NotAfter (expires at). UTC.
  DateTime get certExpiry =>
      _parsed.tbsCertificate?.validity.notAfter ?? SatClock.realNow();

  /// Load existing material or generate a new self-signed pair.
  static Future<ServerTls> loadOrCreate() async {
    final dir = await getApplicationSupportDirectory();
    final certFile = File(p.join(dir.path, 'satset.cert.pem'));
    final keyFile = File(p.join(dir.path, 'satset.key.pem'));

    String certPem;
    String keyPem;
    if (await certFile.exists() && await keyFile.exists()) {
      certPem = await certFile.readAsString();
      keyPem = await keyFile.readAsString();
    } else {
      final pair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
      final csr = X509Utils.generateRsaCsrPem(
        const <String, String>{'CN': 'satset.local'},
        pair.privateKey as RSAPrivateKey,
        pair.publicKey as RSAPublicKey,
      );
      certPem = X509Utils.generateSelfSignedCertificate(
        pair.privateKey,
        csr,
        365 * 5,
      );
      keyPem = CryptoUtils.encodeRSAPrivateKeyToPem(
        pair.privateKey as RSAPrivateKey,
      );
      await certFile.writeAsString(certPem);
      await keyFile.writeAsString(keyPem);
    }

    final ctx = SecurityContext(withTrustedRoots: false)
      ..useCertificateChainBytes(utf8.encode(certPem))
      ..usePrivateKeyBytes(utf8.encode(keyPem));

    final der = _pemToDer(certPem);
    final fp = sha256.convert(der).toString();

    return ServerTls(
      certPem: certPem,
      keyPem: keyPem,
      context: ctx,
      fingerprint: fp,
    );
  }

  static List<int> _pemToDer(String pem) {
    final body = pem
        .replaceAll(RegExp(r'-----BEGIN [^-]+-----'), '')
        .replaceAll(RegExp(r'-----END [^-]+-----'), '')
        .replaceAll(RegExp(r'\s'), '');
    return base64Decode(body);
  }
}
