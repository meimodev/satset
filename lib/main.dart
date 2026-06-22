import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'app.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/server/server.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // id_ID date symbols for exports (DateFormat with explicit locale).
    await initializeDateFormatting('id_ID');
    SatLog.init();
    FlutterError.onError = (details) {
      SatLog.err('flutter', details.exception, details.stack);
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (e, st) {
      SatLog.err('platform', e, st);
      return false;
    };

    await Firebase.initializeApp();

    final sp = await SharedPreferences.getInstance();
    final prefs = PrefsService(sp);
    final storage = SecureStorageService();
    final mode = prefs.appMode();

    if ((await storage.readDeviceId())?.isEmpty ?? true) {
      await storage.writeDeviceId(const Uuid().v4());
    }

    ServerRuntime? server;
    ApiConfig? apiConfig;
    // Set when a cached admin session was blocked at boot ('stale' |
    // 'ineligible') so the PIN screen can explain why. See ADR-0015.
    String? adminBootBlock;

    if (mode == AppMode.server && Platform.isAndroid) {
      // The embedded server is bound to a valid admin session: gate its start
      // on the Firebase eligibility snapshot (with a 7-day offline staleness
      // guard). No cached/eligible admin ⇒ stay on the sign-in screen.
      final fbAdmin = FirebaseAdminService();
      final decision = await fbAdmin.evaluateForBoot(storage);
      switch (decision.gate) {
        case AdminBootGate.ok:
          server = await ServerRuntime.boot();
          apiConfig = ApiConfig(
            baseUri: Uri.parse('https://127.0.0.1:${server.port}'),
            trustedFingerprint: server.tls.fingerprint,
          );
        case AdminBootGate.ineligible:
          await fbAdmin.signOut();
          adminBootBlock = 'ineligible';
        case AdminBootGate.staleOffline:
          adminBootBlock = 'stale';
        case AdminBootGate.superAdmin:
          // A fleet operator has no local server; sign out the cached session
          // so the PIN screen shows the admin form and the super re-signs in to
          // reach the Fleet console. See ADR-0016.
          await fbAdmin.signOut();
        case AdminBootGate.owner:
          // A report owner has no local server; sign out so the PIN screen
          // shows the admin form and the owner re-signs in to reach /owner.
          // See ADR-0036.
          await fbAdmin.signOut();
        case AdminBootGate.noUser:
          break;
      }
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
        if (adminBootBlock != null)
          adminBootBlockProvider.overrideWith((_) => adminBootBlock),
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
