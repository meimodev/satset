import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'app.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/server/server.dart';
import 'package:satset/ui/features/onboarding/view_models/mode_select_view_model.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SatLog.init();
    FlutterError.onError = (details) {
      SatLog.err('flutter', details.exception, details.stack);
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (e, st) {
      SatLog.err('platform', e, st);
      return false;
    };

    final sp = await SharedPreferences.getInstance();
    final prefs = PrefsService(sp);
    final storage = SecureStorageService();
    final mode = prefs.appMode();

    if ((await storage.readDeviceId())?.isEmpty ?? true) {
      await storage.writeDeviceId(const Uuid().v4());
    }

    ServerRuntime? server;
    ApiConfig? apiConfig;

    if (mode == AppMode.server && Platform.isAndroid) {
      server = await ServerRuntime.boot();
      apiConfig = ApiConfig(
        baseUri: Uri.parse('https://127.0.0.1:${server.port}'),
        trustedFingerprint: server.tls.fingerprint,
      );
    } else if (mode == AppMode.client) {
      final host = prefs.pairedHost();
      final port = prefs.pairedPort();
      final fp = await storage.readServerFingerprint();
      if (host != null && port != null && fp != null) {
        apiConfig = ApiConfig(
          baseUri: Uri.parse('https://$host:$port'),
          trustedFingerprint: fp,
        );
      }
    }

    final deviceId = (await storage.readDeviceId()) ?? '';
    SatLog.boot(
        'mode=${mode.name} device=${deviceId.isEmpty ? "?" : deviceId.substring(0, deviceId.length.clamp(0, 8))} '
        'api=${apiConfig?.baseUri ?? "none"}');

    final container = ProviderContainer(
      overrides: [
        prefsServiceProvider.overrideWith((_) async => prefs),
        secureStorageServiceProvider.overrideWithValue(storage),
        if (apiConfig != null) apiConfigProvider.overrideWith((_) => apiConfig),
        if (server != null)
          serverRuntimeProvider.overrideWith((_) => server),
      ],
    );

    if (apiConfig != null) {
      // ignore: unawaited_futures
      container.read(authStateProvider.notifier).restoreFromStoredToken();
    }

    runApp(UncontrolledProviderScope(
      container: container,
      child: _ServerLifecycle(server: server, child: const SatSetApp()),
    ));
  }, (e, st) => SatLog.err('zoned', e, st));
}

class _ServerLifecycle extends StatefulWidget {
  final ServerRuntime? server;
  final Widget child;
  const _ServerLifecycle({required this.server, required this.child});

  @override
  State<_ServerLifecycle> createState() => _ServerLifecycleState();
}

class _ServerLifecycleState extends State<_ServerLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.server?.shutdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
