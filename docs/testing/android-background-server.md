# Android background hosting

Admin-server startup now acquires a native `connectedDevice` foreground service
before opening the database/listeners. The notification changes from starting to
running only after runtime initialization succeeds. A partial CPU wake lock lasts
for the hosting session. Logout, eligibility shutdown and startup failure release
it. Client, owner and fleet sessions do not start the service.

The Activity reuses the hosting Flutter engine. Home, another app, screen lock,
Activity recreation and reopening SatSet therefore keep the same Dart runtime,
database and TLS identity. CSV picker handlers detach with their Activity.

The host-only setup banner requests battery-optimization exemption and notification
permission after explaining their purpose. It rechecks Android's actual permission
state on resume. Denying notifications does not stop the foreground service.
Without battery exemption, Doze can suspend LAN access despite the CPU lock.
Keep the main device powered during service; verify any vendor-specific battery
restrictions on the deployed tablet.

This change retains a **live process**. It does not implement restart after process
death, force-stop, Android's active-app Stop, reboot or APK replacement. The service
deliberately uses `START_NOT_STICKY`: a notification alone must never revive without
restoring the authorized Dart server. Reopen SatSet to use the existing gated boot.

## Device acceptance check

Use an Android 10+ host and a second device on the same LAN. Repeat on Android 15+
because the app targets API 36. Use actual LAN requests, not adb port forwarding.

1. Sign in as an eligible server admin, allow the battery exemption, and verify
   `adb shell dumpsys activity services id.activid.satset` shows a foreground
   `SatSetServerService`. `adb shell dumpsys power` should show `SatSet:server`.
2. Connect a staff device. Send an order, check its acknowledgement and kitchen
   update. Record the host process ID, TLS fingerprint and order ID.
3. Press Home, open a different app, then turn the host screen off. For each state,
   send fresh orders from the staff device and check acknowledgements and updates.
   Also verify fresh discovery and guest ordering if enabled. Run an overnight
   screen-off soak on the deployment hardware.
4. Swipe away/reopen SatSet and recreate its Activity using Android's developer
   setting. Confirm the same process/runtime identity, no duplicate listeners,
   and working CSV picker and audio after reattachment.
5. Compare exemption granted/denied with the device unplugged and forced Doze
   (`adb shell dumpsys deviceidle force-idle`). Restore with
   `adb shell dumpsys deviceidle unforce`. Verify fresh remote TCP connections,
   not just existing WebSockets. Restore all changed device settings afterward.
6. Deny notifications, then grant them in Settings. Hosting must continue and the
   setup banner must reflect the new state on return.
7. Log out as admin and test eligibility revocation. The service, notification,
   CPU lock and LAN listeners must stop. Client-only and owner sessions must never
   show the host setup banner or acquire the host service.
8. Force-stop and reopen separately: interruption is expected; gated cold boot
   must reuse the database, venue ID and pinned TLS identity.

Automated startup failure/timeout checks: `flutter test test/server_background_test.dart`.
Build verification does not substitute for the device/Doze checks above.

## Verification on 2026-09-23

- `flutter analyze --no-pub`: zero issues.
- Lifecycle, localization parity and design-token checks: 30 tests passed.
- `flutter build apk --debug --no-pub`: passed; APK at
  `build/app/outputs/flutter-apk/app-debug.apk`.
- APK manifest includes the connected-device foreground-service permission,
  CPU wake-lock permission and battery-exemption request permission, targeting API 36.
  The packaged minimum is API 24; native service/channel setup guards API 26 calls.
- No Android device was connected. Background LAN, Activity recreation and Doze
  acceptance checks are documented above but have not been run on hardware.
