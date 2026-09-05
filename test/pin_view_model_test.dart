import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/mdns_browser_service.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/ui/features/auth/view_models/pin_view_model.dart';

class FakeMdnsBrowserService extends MdnsBrowserService {
  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Stream<List<DiscoveredServer>> get servers => Stream.value([]);

  @override
  List<DiscoveredServer> get current => [];
}

class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<String?> readServerFingerprint() async => _data['satset.server.fingerprint'];

  @override
  Future<void> writeServerFingerprint(String? v) async {
    if (v == null) {
      _data.remove('satset.server.fingerprint');
    } else {
      _data['satset.server.fingerprint'] = v;
    }
  }

  @override
  Future<String?> readDeviceId() async => _data['satset.device.id'] ?? 'mock-device-id';

  @override
  Future<void> writeDeviceId(String v) async {
    _data['satset.device.id'] = v;
  }

  @override
  Future<void> writeServerCert(String? v) async {
    if (v == null) {
      _data.remove('satset.server.cert.pem');
    } else {
      _data['satset.server.cert.pem'] = v;
    }
  }

  @override
  Future<void> clearSession() async {
    _data.remove('satset.server.fingerprint');
    _data.remove('satset.server.cert.pem');
  }
}

class FakeX509Certificate implements X509Certificate {
  @override
  Uint8List get der => Uint8List.fromList([1, 2, 3, 4]);

  @override
  Uint8List get sha1 => Uint8List.fromList([1, 2, 3]);

  @override
  String get subject => 'CN=localhost';

  @override
  String get issuer => 'CN=localhost';

  @override
  DateTime get startValidity => DateTime.now();

  @override
  DateTime get endValidity => DateTime.now();

  @override
  String get pem => 'PEM';
}

class FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name.toLowerCase()] = [value.toString()];
  }

  @override
  List<String>? operator [](String name) => _headers[name.toLowerCase()];

  @override
  String? value(String name) => _headers[name.toLowerCase()]?.first;

  @override
  void clear() {
    _headers.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final String body;

  FakeHttpClientResponse({required this.statusCode, required this.body});

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(utf8.encode(body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  final HttpHeaders headers = FakeHttpHeaders();

  @override
  int get contentLength => body.length;

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  List<Cookie> get cookies => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpClientRequest implements HttpClientRequest {
  final FakeHttpClientResponse response;
  FakeHttpClientRequest({required this.response});

  @override
  final HttpHeaders headers = FakeHttpHeaders();

  @override
  void add(List<int> data) {}

  @override
  void write(Object? obj) {}

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {
    await stream.drain();
  }

  @override
  Future<HttpClientResponse> get done => Future.value(response);

  @override
  Future<HttpClientResponse> close() async {
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpClient implements HttpClient {
  @override
  late bool Function(X509Certificate cert, String host, int port)? badCertificateCallback;

  @override
  Duration? connectionTimeout;

  final List<String> requests = [];
  bool failFingerprint = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requests.add('GET $url');
    if (failFingerprint) {
      throw const SocketException('Connection failed');
    }
    final cert = FakeX509Certificate();
    badCertificateCallback?.call(cert, url.host, url.port);
    return FakeHttpClientRequest(
      response: FakeHttpClientResponse(
        statusCode: 200,
        body: 'ok',
      ),
    );
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    requests.add('POST $url');
    final certFingerprint = sha256.convert([1, 2, 3, 4]).toString().toLowerCase();
    final responseJson = jsonEncode({
      'deviceToken': 'mock-token',
      'fingerprint': certFingerprint,
      'serverPublicKey': 'mock-public-key',
    });
    return FakeHttpClientRequest(
      response: FakeHttpClientResponse(
        statusCode: 200,
        body: responseJson,
      ),
    );
  }

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    if (method.toUpperCase() == 'POST') {
      return postUrl(url);
    } else {
      return getUrl(url);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MyHttpOverrides extends HttpOverrides {
  final HttpClient client;
  MyHttpOverrides(this.client);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return client;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late PrefsService prefs;
  late FakeSecureStorageService fakeStorage;
  late FakeMdnsBrowserService fakeMdns;
  late FakeHttpClient fakeHttpClient;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PrefsService(await SharedPreferences.getInstance());
    fakeStorage = FakeSecureStorageService();
    fakeMdns = FakeMdnsBrowserService();
    fakeHttpClient = FakeHttpClient();

    container = ProviderContainer(
      overrides: [
        prefsServiceProvider.overrideWith((_) => prefs),
        secureStorageServiceProvider.overrideWith((_) => fakeStorage),
        mdnsBrowserServiceProvider.overrideWith((_) => fakeMdns),
      ],
    );
    addTearDown(container.dispose);
  });

  /// A device that is already paired, its pad opened and then dismissed.
  ///
  /// These pin the trap described on [StaffStage]: before this, dismissing the
  /// pad dropped a still-paired device into the picker, where re-tapping its
  /// own server changed nothing — leaving "reset pairing" or an app kill as the
  /// only ways back to a PIN prompt.
  group('re-entering the PIN pad', () {
    /// Seeds a paired server and settles the view-model on it.
    Future<PinViewModel> pairedVm() async {
      await prefs.setPairedHost('192.168.1.8');
      await prefs.setPairedPort(7443);
      await fakeStorage.writeServerFingerprint('deadbeef');
      final vm = container.read(pinViewModelProvider.notifier);
      await vm.refreshPairedServers();
      return vm;
    }

    test('dismissing the pad lands on the connected card, not the picker', () async {
      final vm = await pairedVm();
      expect(container.read(pinViewModelProvider).stage, StaffStage.connected);

      vm.setStage(StaffStage.enteringPin);
      vm.dismissPinPad();

      expect(container.read(pinViewModelProvider).stage, StaffStage.connected);
    });

    test('dismissing with no paired selection falls back to the picker', () async {
      final vm = container.read(pinViewModelProvider.notifier);
      await vm.refreshPairedServers();
      expect(container.read(pinViewModelProvider).selectedServer, isNull);

      vm.setStage(StaffStage.enteringPin);
      vm.dismissPinPad();

      expect(container.read(pinViewModelProvider).stage, StaffStage.pickingServer);
    });

    test('re-picking the server already selected promotes back to connected', () async {
      final vm = await pairedVm();
      final key = container.read(pinViewModelProvider).selectedServerKey;
      expect(key, isNotNull);

      // "ganti server", then changing your mind and tapping the same row.
      vm.setStage(StaffStage.pickingServer);
      vm.selectServer(key!);

      expect(container.read(pinViewModelProvider).stage, StaffStage.connected);
    });
  });

  group('Manual connection address parsing', () {
    test('dot notation (5 segments: IP.PORT)', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final vm = container.read(pinViewModelProvider.notifier);
        
        final success = await vm.connectManualAddress('192.168.1.8.7443');
        expect(success, isTrue);

        final apiConfig = container.read(apiConfigProvider);
        expect(apiConfig, isNotNull);
        expect(apiConfig!.baseUri.host, '192.168.1.8');
        expect(apiConfig.baseUri.port, 7443);
      }, MyHttpOverrides(fakeHttpClient));
    });

    test('colon notation (IP:PORT)', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final vm = container.read(pinViewModelProvider.notifier);
        
        final success = await vm.connectManualAddress('192.168.1.8:7443');
        expect(success, isTrue);

        final apiConfig = container.read(apiConfigProvider);
        expect(apiConfig, isNotNull);
        expect(apiConfig!.baseUri.host, '192.168.1.8');
        expect(apiConfig.baseUri.port, 7443);
      }, MyHttpOverrides(fakeHttpClient));
    });

    test('IP only (defaults port to 7443)', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final vm = container.read(pinViewModelProvider.notifier);
        
        final success = await vm.connectManualAddress('192.168.1.8');
        expect(success, isTrue);

        final apiConfig = container.read(apiConfigProvider);
        expect(apiConfig, isNotNull);
        expect(apiConfig!.baseUri.host, '192.168.1.8');
        expect(apiConfig.baseUri.port, 7443);
      }, MyHttpOverrides(fakeHttpClient));
    });

    test('hostname with custom port (host:port)', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final vm = container.read(pinViewModelProvider.notifier);
        
        final success = await vm.connectManualAddress('my-restaurant.local:8080');
        expect(success, isTrue);

        final apiConfig = container.read(apiConfigProvider);
        expect(apiConfig, isNotNull);
        expect(apiConfig!.baseUri.host, 'my-restaurant.local');
        expect(apiConfig.baseUri.port, 8080);
      }, MyHttpOverrides(fakeHttpClient));
    });

    test('hostname only (defaults port to 7443)', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final vm = container.read(pinViewModelProvider.notifier);
        
        final success = await vm.connectManualAddress('my-restaurant.local');
        expect(success, isTrue);

        final apiConfig = container.read(apiConfigProvider);
        expect(apiConfig, isNotNull);
        expect(apiConfig!.baseUri.host, 'my-restaurant.local');
        expect(apiConfig.baseUri.port, 7443);
      }, MyHttpOverrides(fakeHttpClient));
    });

    test('trim leading/trailing whitespace', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final vm = container.read(pinViewModelProvider.notifier);
        
        final success = await vm.connectManualAddress('  192.168.1.8.7443  ');
        expect(success, isTrue);

        final apiConfig = container.read(apiConfigProvider);
        expect(apiConfig, isNotNull);
        expect(apiConfig!.baseUri.host, '192.168.1.8');
        expect(apiConfig.baseUri.port, 7443);
      }, MyHttpOverrides(fakeHttpClient));
    });

    test('empty string input fails validation', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final vm = container.read(pinViewModelProvider.notifier);
        
        final success = await vm.connectManualAddress('   ');
        expect(success, isFalse);
        expect(vm.state.pairingError, isNotNull);
        expect(vm.state.pairingError, contains('kosong'));
      }, MyHttpOverrides(fakeHttpClient));
    });

    test('empty string input fails validation in English', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        await container.read(satLocaleProvider.notifier).select(const Locale('en'));

        final vm = container.read(pinViewModelProvider.notifier);
        
        final success = await vm.connectManualAddress('   ');
        expect(success, isFalse);
        expect(vm.state.pairingError, isNotNull);
        expect(vm.state.pairingError, contains('cannot be empty'));
      }, MyHttpOverrides(fakeHttpClient));
    });

    test('connection failure / server fingerprint not found', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        fakeHttpClient.failFingerprint = true;
        final vm = container.read(pinViewModelProvider.notifier);
        
        final success = await vm.connectManualAddress('192.168.1.99');
        expect(success, isFalse);
        expect(vm.state.pairingError, isNotNull);
        expect(vm.state.pairingError, contains('Tidak dapat terhubung'));
      }, MyHttpOverrides(fakeHttpClient));
    });
  });
}
