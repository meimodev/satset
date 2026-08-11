import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'app.dart';
import 'package:satset/core/app_version.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/server/server.dart';

/// Set once Firebase is up. The zone handler at the bottom of [main] can fire
/// before that — an error thrown during `initializeApp` itself lands there —
/// so it has to tolerate a null.
FirebaseCrashlytics? _crashlytics;

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Symbols for both shipped locales, before the first frame. `format.dart`
      // builds its DateFormats per call against `Intl.defaultLocale`, which the
      // locale provider keeps in step with the picker (ADR-0083/0084). Loading
      // both here is what lets a language switch take effect without a restart.
      await initializeDateFormatting('id_ID');
      await initializeDateFormatting('en_US');
      SatLog.init();
      // Before anything reads it: the mDNS advert carries it, and the release
      // gate compares against it (ADR-0087).
      await AppVersion.load();
      FlutterError.onError = (details) {
        SatLog.err('flutter', details.exception, details.stack);
        FlutterError.presentError(details);
      };
      PlatformDispatcher.instance.onError = (e, st) {
        SatLog.err('platform', e, st);
        return false;
      };

      await Firebase.initializeApp();

      // Crash reporting layers on top of the handlers above rather than replacing
      // them: SatLog stays the on-device record an operator can read on the spot,
      // Crashlytics is the copy that survives the device. Collection is off in
      // debug so a developer's own crashes never reach the console. Reports queue
      // on disk and upload whenever the venue next has a WAN — which, for an app
      // that is expected to run without one, is the only workable shape.
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);
      _crashlytics = crashlytics;
      FlutterError.onError = (details) {
        SatLog.err('flutter', details.exception, details.stack);
        crashlytics.recordFlutterFatalError(details);
        FlutterError.presentError(details);
      };
      PlatformDispatcher.instance.onError = (e, st) {
        SatLog.err('platform', e, st);
        crashlytics.recordError(e, st, fatal: true);
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
            // A boot that never returns is the one failure with no way out: it
            // happens before `runApp`, so there is no frame, no on-screen log
            // and no button — only a force-kill. A held port, a TLS keygen that
            // stalls, a long migration all land here. The deadline does not
            // rescue the server; it rescues the app, which can then say so.
            final booting = ServerRuntime.boot(version: AppVersion.value);
            try {
              server = await booting.timeout(const Duration(seconds: 15));
              apiConfig = ApiConfig(
                baseUri: Uri.parse('https://127.0.0.1:${server.port}'),
                trustedFingerprint: server.tls.fingerprint,
              );
            } catch (e, st) {
              SatLog.err('boot', e, st);
              // Abandoned, not cancelled: a boot that lands after the deadline
              // still holds the port the next attempt needs. Shut it down if it
              // ever arrives.
              unawaited(booting.then((s) => s.shutdown()).catchError((_) {}));
              server = null;
              apiConfig = null;
              adminBootBlock = 'bootfailed';
            }
          case AdminBootGate.ineligible:
            await fbAdmin.signOut();
            adminBootBlock = 'ineligible';
          case AdminBootGate.mustChangePassword:
            // Sign the cached session out so the PIN screen asks for the
            // temporary password, which routes into the change screen. No server
            // boots on a credential the operator has just replaced. See ADR-0075.
            await fbAdmin.signOut();
            adminBootBlock = 'resetpending';
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
      // A crash from a venue fleet is unattributable without these: which tablet,
      // and whether it was the one running the server.
      unawaited(crashlytics.setUserIdentifier(deviceId));
      unawaited(crashlytics.setCustomKey('mode', mode.name));
      SatLog.boot(
        'mode=${mode.name} device=${deviceId.isEmpty ? "?" : deviceId.substring(0, deviceId.length.clamp(0, 8))} '
        'api=${apiConfig?.baseUri ?? "none"}',
      );

      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWith((_) async => prefs),
          secureStorageServiceProvider.overrideWithValue(storage),
          if (apiConfig != null)
            apiConfigProvider.overrideWith((_) => apiConfig),
          if (server != null) serverRuntimeProvider.overrideWith((_) => server),
          if (adminBootBlock != null)
            adminBootBlockProvider.overrideWith((_) => adminBootBlock),
        ],
      );

      if (apiConfig != null) {
        // ignore: unawaited_futures
        container.read(authStateProvider.notifier).restoreFromStoredToken();
      }

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: _ServerLifecycle(server: server, child: const SatSetApp()),
        ),
      );
    },
    (e, st) {
      SatLog.err('zoned', e, st);
      _crashlytics?.recordError(e, st, fatal: true);
    },
  );
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
