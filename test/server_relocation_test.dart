// A paired handset must survive its host changing address.
//
// The config stores `https://<ip>:<port>` plus the fingerprint it trusts. When
// the venue's router hands the host tablet a new DHCP lease, the address stops
// being true: the socket retries the dead IP forever, every screen reads
// offline, and the documented way out is re-pairing a device that is already
// paired.
//
// The certificate is the identity (ADR-0080), so the LAN can be asked where
// that certificate lives now — and a match is provably the same server, which
// is what makes doing it without a human safe.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/mdns_browser_service.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/server_relocator.dart';
import 'package:satset/data/services/ws_client.dart';

/// Answers with whatever the LAN is pretending to hold. Never starts bonsoir.
class _FakeBrowser extends MdnsBrowserService {
  _FakeBrowser(this.onLan);

  final List<DiscoveredServer> onLan;
  var scans = 0;

  @override
  Future<DiscoveredServer?> findFingerprintHost(
    String fingerprint, {
    Duration window = const Duration(seconds: 3),
  }) async {
    scans++;
    final want = fingerprint.toLowerCase();
    for (final s in onLan) {
      if (s.fingerprint.toLowerCase() == want) return s;
    }
    return null;
  }
}

DiscoveredServer _server(String host, String fp) => DiscoveredServer(
  name: 'satset',
  host: host,
  port: 8443,
  fingerprint: fp,
  label: 'Warung',
);

void main() {
  const fp = 'AA:BB:CC';
  final paired = ApiConfig(
    baseUri: Uri.parse('https://192.168.1.50:8443'),
    trustedFingerprint: fp,
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer containerWith(_FakeBrowser browser, {ApiConfig? config}) =>
      ProviderContainer(
        overrides: [
          mdnsBrowserServiceProvider.overrideWithValue(browser),
          apiConfigProvider.overrideWith((ref) => config ?? paired),
        ],
      );

  test('the same certificate at a new address is followed', () async {
    final browser = _FakeBrowser([_server('192.168.1.77', fp)]);
    final container = containerWith(browser);
    addTearDown(container.dispose);

    await relocateServer(container.read(Provider((ref) => ref)));

    expect(
      container.read(apiConfigProvider)?.baseUri.host,
      '192.168.1.77',
      reason: 'the fingerprint is the identity; the address is just where',
    );
    expect(
      container.read(apiConfigProvider)?.trustedFingerprint,
      fp,
      reason: 'and following an address never loosens the pin',
    );

    final prefs = await container.read(prefsServiceProvider.future);
    expect(
      prefs.pairedHost(),
      '192.168.1.77',
      reason: 'it has to survive the next boot too',
    );
    expect(prefs.pairedPort(), 8443);
  });

  test('a different certificate on the LAN is ignored', () async {
    final browser = _FakeBrowser([_server('192.168.1.99', 'DE:AD:BE:EF')]);
    final container = containerWith(browser);
    addTearDown(container.dispose);

    await relocateServer(container.read(Provider((ref) => ref)));

    expect(
      container.read(apiConfigProvider)?.baseUri.host,
      '192.168.1.50',
      reason: 'somebody else advertising is not our server moving',
    );
  });

  test('finding it where we already were is not a move', () async {
    final browser = _FakeBrowser([_server('192.168.1.50', fp)]);
    final container = containerWith(browser);
    addTearDown(container.dispose);

    await relocateServer(container.read(Provider((ref) => ref)));

    final prefs = await container.read(prefsServiceProvider.future);
    expect(
      prefs.pairedHost(),
      isNull,
      reason: 'the host is down, not moved — nothing to rewrite',
    );
  });

  test('server mode never goes looking', () async {
    final browser = _FakeBrowser([_server('192.168.1.77', '')]);
    final container = containerWith(
      browser,
      config: ApiConfig(
        baseUri: Uri.parse('https://127.0.0.1:8443'),
        trustedFingerprint: '',
      ),
    );
    addTearDown(container.dispose);

    await relocateServer(container.read(Provider((ref) => ref)));

    expect(
      browser.scans,
      0,
      reason: 'a loopback config has no fingerprint to match on',
    );
  });

  group('when the socket decides the host has moved', () {
    test('after a run of failures, and then every run after', () {
      // Not on the first drop — that is an ordinary blip — and not only once,
      // because the host may still have been re-advertising the first time.
      expect(WsClient.shouldRelocate(0), isFalse);
      expect(WsClient.shouldRelocate(1), isFalse);
      expect(WsClient.shouldRelocate(WsClient.relocateAfter - 1), isFalse);
      expect(WsClient.shouldRelocate(WsClient.relocateAfter), isTrue);
      expect(WsClient.shouldRelocate(WsClient.relocateAfter * 2), isTrue);
      expect(WsClient.shouldRelocate(WsClient.relocateAfter * 2 - 1), isFalse);
    });
  });
}
