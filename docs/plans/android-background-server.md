# Keep the SatSet host available in the background

Research date: 2026-09-09. Updated: 2026-09-23.

Status: live-process background hosting is implemented: foreground service,
retained engine, CPU lock, battery setup and bounded startup cleanup.
Process-death recovery and device soak testing remain pending; see
[implementation scope and device checks](../testing/android-background-server.md).

## Recommendation

Complete the existing native foreground service and retain one Flutter engine outside the Activity lifecycle. The service provides Android foreground execution, the ongoing notification, power management and recovery; an application-scoped engine owner keeps the current Dart runtime and provider container alive. MainActivity attaches to that engine when visible. Use `connectedDevice` for the LAN host, explicit hosting intent for recovery, and a server-only battery setup flow.

A separate server engine remains an option if measurements or plugin constraints justify it. It is not required merely because the screen backgrounds. This revises the earlier recommendation to immediately split the backend into a second engine.

The intended outcome is availability through Home, app switching, screen lock and Activity recreation on supported host tablets. Process death can cause an interruption followed by recovery; force-stop, Android's active-app Stop action, device shutdown and loss of LAN are different conditions and cannot be covered by a promise of continuous service.

## What the repository actually does

CodeGraph tools were unavailable in this session, so this audit used targeted file reads and literal searches. The supplied project overview is older than the code: this app already has Shelf, Drift, TLS, WebSockets, Firebase eligibility, guest ordering and offline client queues.

| Evidence | Consequence |
|---|---|
| [SatSetServerService.kt](/Users/edotanod/IdeaProjects/satset/android/app/src/main/kotlin/id/activid/satset/SatSetServerService.kt) creates an ongoing notification, calls `startForeground`, and returns `START_STICKY`. | A useful scaffold, but it contains no engine, runtime recovery, readiness acknowledgement or wake-lock acquisition. |
| Repository-wide searches for `startServerService`, `stopServerService`, `SatSetServerService` and `startForegroundService` found only the Android declarations/handlers. | Neither Dart startup path invokes the service. The earlier statement that SatSet already starts this notification was unsupported; the code to do so exists but is unwired. |
| [Manifest](/Users/edotanod/IdeaProjects/satset/android/app/src/main/AndroidManifest.xml) declares `dataSync`, `WAKE_LOCK`, `POST_NOTIFICATIONS` and multicast permission; [Gradle](/Users/edotanod/IdeaProjects/satset/android/app/build.gradle.kts) targets/compiles API 36. | Fixing only the missing invocation would expose the data-sync timeout. Permission declarations alone do not acquire locks or request notification consent. |
| [MainActivity](/Users/edotanod/IdeaProjects/satset/android/app/src/main/kotlin/id/activid/satset/MainActivity.kt) uses default FlutterActivity engine ownership and installs the server channel beside the CSV picker. | Engine lifetime and server control currently depend on an Activity. The screen-on flag is window-scoped. |
| [main.dart](/Users/edotanod/IdeaProjects/satset/lib/main.dart) boots before `runApp`; [ModeSelectViewModel](/Users/edotanod/IdeaProjects/satset/lib/ui/features/onboarding/view_models/mode_select_view_model.dart) separately boots on admission. | Unify both paths. The cold path does not pass the venue ID, unlike the admission path; recovery must preserve venue identity. |
| `_ServerLifecycle.dispose()` shuts down only the runtime passed at initial boot. | Widget disposal is an unsuitable host shutdown authority, and that captured reference misses later-started runtimes. |
| [AuthRepository](/Users/edotanod/IdeaProjects/satset/lib/data/repositories/auth_repository.dart) directly provisions users/mints sessions through `rt.auth`, owns eligibility listeners and tears down the runtime. [ReleaseGateRepository](/Users/edotanod/IdeaProjects/satset/lib/data/repositories/release_gate_repository.dart) directly publishes into it. | Moving Shelf alone to a second isolate/engine would break these control paths. “Everything already uses localhost” is incomplete. |
| [ServerRuntime](/Users/edotanod/IdeaProjects/satset/lib/server/server.dart) owns TLS :7443, optional guest HTTP :8080, discovery, database and timers. [Guest routes](/Users/edotanod/IdeaProjects/satset/lib/server/guest/guest_routes.dart) read `rootBundle`. | Keep all these working during detached startup, not just a health endpoint. |
| [AlertHost](/Users/edotanod/IdeaProjects/satset/lib/ui/core/widgets/alert_host.dart) activates audio from widget build. | Cold recovery without a view must explicitly initialize essential host subscriptions; a listening socket alone does not restore kitchen behavior. |
| [WsClient](/Users/edotanod/IdeaProjects/satset/lib/data/services/ws_client.dart) already has jittered retry, an eight-second handshake budget and discovery after repeated failures; repositories resync after reconnect. | Reuse recovery behavior. Do not promise the stale ADR's approximately one-second reconnect. |

## Research findings that determine the design

### Android platform

See the [platform research](/Users/edotanod/IdeaProjects/satset/docs/android-background-host-platform-research.md) for detailed references, version distinctions and operational limits.

- `connectedDevice` covers interaction with external devices over a network. Applying that category to SatSet's ongoing LAN ordering is our use-case assessment, not an explicit Android restaurant example. Use `FOREGROUND_SERVICE_CONNECTED_DEVICE`; existing `CHANGE_WIFI_MULTICAST_STATE` satisfies a documented prerequisite. Avoid combining the host with `dataSync` or using `specialUse` to evade a better-fitting type. [Service types](https://developer.android.com/develop/background-work/services/fgs/service-types).
- For this target, Android 15+ imposes a six-hour background allowance on `dataSync`; user foreground interaction resets its timer. Sideloader distribution does not remove OS restrictions. [Timeout rules](https://developer.android.com/develop/background-work/services/fgs/timeout).
- Start the service from an eligible visible/user-triggered state and promote it immediately with a starting notification. Never wait for Firebase, migrations, TLS or discovery before promotion. Handle startup exceptions as an explicit unavailable state. [Launching an FGS](https://developer.android.com/develop/background-work/services/fgs/launch).
- An ongoing notification is a required user-visible companion to the service, not its execution mechanism. Notification permission denial does not prohibit foreground services; Android 14+ also permits dismissal of most ongoing notifications. Do not interpret notification dismissal as shutdown or force it back through a repost loop. [Notification permission](https://developer.android.com/develop/ui/views/notifications/notification-permission), [Android 14 behavior](https://developer.android.com/about/versions/14/behavior-changes-all#non-dismissable-notifications).
- A foreground service does not exempt sockets from Doze. A partial CPU wake lock plus verified battery-optimization exemption is the proposed screen-off host policy. Keep the host powered during service, and release the lock on every terminal hosting outcome. [Doze](https://developer.android.com/training/monitoring-device-state/doze-standby).

### Flutter and plugin compatibility

Flutter officially supports a cached engine outliving its Activity, including background networking. Retaining the current engine preserves the existing runtime references and provider container. It does not keep a killed Android process alive or reconstruct one automatically. [Cached engines](https://docs.flutter.dev/add-to-app/android/add-flutter-screen).

Default FlutterActivity destroys an engine it created; a supplied cached engine normally survives. Register application-scoped channels once, use the cached/provided-engine APIs, and clean up Activity references on detach. Do not keep the old CSV picker closure capturing a destroyed Activity. [FlutterActivity API](https://api.flutter.dev/javadoc/io/flutter/embedding/android/FlutterActivity.html).

Flutter's paused lifecycle stops frame callbacks; it does not require moving all networking to another isolate. Host initialization and timers must not depend on drawing frames. [Lifecycle API](https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html).

A plain `Isolate.spawn` is not a drop-in backend host: background isolates cannot access `rootBundle` or receive unsolicited platform messages such as Firestore listener events. A second Flutter engine has its own root isolate and is a different design; it can support those facilities but requires plugin validation and explicit inter-engine communication. [Isolate limitations](https://docs.flutter.dev/perf/isolates), [FlutterEngine API](https://api.flutter.dev/javadoc/io/flutter/embedding/engine/FlutterEngine.html).

Installed-source checks support testing the retained-engine approach: bonsoir_android 7.1.2 initializes with application context and creates a multicast lock; flutter_secure_storage 10.3.1 uses application context; cloud_firestore 5.6.12 removes listeners at engine detach, while Activity detach clears its Activity reference. These are source observations, not proof that every plugin operation works without a view. Verify actual pinned packages on hardware.

### Alternatives considered

| Approach | Decision for SatSet |
|---|---|
| Complete native service + retained single engine | Recommended first implementation. Already Android-only; preserves current host/auth integration and avoids another service implementation. |
| Native service + separate server engine | Defer. Useful if UI work causes measured host latency or plugin/lifecycle isolation needs it. Requires moving admin provisioning, eligibility, release gates, audio and database ownership behind an explicit control boundary. Two engines in one process do not isolate process crashes. |
| `flutter_background` | Provides FGS, partial wake lock and battery handling, but does not by itself establish SatSet's recovery and ownership contract. [Maintainer documentation](https://pub.dev/packages/flutter_background). |
| `flutter_foreground_task` | Viable maintained FGS/task abstraction with callbacks and messages. Adopting it still requires the server separation and boot/stop work; do not copy its example alarm and auto-boot permissions without a product need. [Maintainer documentation](https://pub.dev/packages/flutter_foreground_task). |
| `flutter_background_service` | Viable service abstraction, but its isolated service cannot share live Dart references with UI. That is material for this codebase. [Maintainer documentation](https://pub.dev/packages/flutter_background_service). |
| WorkManager / periodic polling | Not the continuous LAN listener. Long-running workers themselves use FGS and can exhaust job quota on Android 16. [Android guidance](https://developer.android.com/develop/background-work/background-tasks/persistent/how-to/long-running). |
| FCM, exact-alarm keepalive, fake media/VPN, repeated self-restarts | Do not use as the host's survival mechanism. They do not supply an offline LAN server with the required lifecycle and introduce unrelated capabilities. |
| Managed dedicated tablet | Optional deployment improvement for venues needing kiosk control; a distinct provisioning/operations choice, not a prerequisite for ordinary background hosting. [Dedicated devices](https://developer.android.com/work/dpc/dedicated-devices). |

## Implementation sequence

### 1. Wire the foreground service and hosting state together

Add a small platform-facing host lifecycle controller shared by cold boot and admin admission. Suggested states: stopped, starting, serving, waiting for LAN, stopping, failed, needs sign-in. Distinguish Android service started from Dart backend ready.

Use `connectedDevice` explicitly in the manifest and promotion call. Start the service before expensive backend work, while visible when initiating a new session. Add a ready/failure acknowledgement rather than treating MethodChannel dispatch success as server readiness. Failures must roll back partial startup; closing a partially bound server, database and discovery resources needs to be safe even when boot never returns a ServerRuntime.

Keep the existing low-importance channel and notification ID. Add a proper app notification icon, `onlyAlertOnce`, an immutable content PendingIntent opening SatSet, and localized state text. Start with “Starting server”; advertise serving only after backend readiness. Do not label a loopback-only health response as proof of remote LAN reachability. A device count is optional and must come from real connection/session state. Put the host off-switch inside the existing authenticated app flow to preserve its shift/logout semantics.

Request notification permission contextually when configuring a host. If denied or the channel is disabled, report reduced notification visibility without falsely claiming that Android prohibits hosting. Check again after returning from settings.

Exit criterion: both startup paths activate exactly one service; rejection/failure is visible; client, owner and super-admin modes acquire no host service or wake lock; logout and revocation remove them.

### 2. Retain one engine and make initialization independent of the screen

Introduce an application-scoped engine owner used by both MainActivity and SatSetServerService. It lazily creates/registers/starts one engine and hands the same engine to the Activity. Execute the Dart entry point once. The service can recreate this owner and engine after process death, without opening an Activity.

Move server channel registration out of Activity-only configuration. Separate CSV picking and permission/settings UI from service operations; only the former need an attached Activity. Preserve normal plugin Activity attachment while the screen exists and release those references on detach.

Give one Dart controller ownership of ServerRuntime and the provider container. Remove widget disposal as the server off-switch. Initialize host eligibility, release-gate delivery and required kitchen subscriptions without relying on a first rendered frame. Reattaching UI must reuse state, listeners and ports, rather than boot a second host.

Preserve direct admin session provisioning in this first version. Pass the current verified/cached venue identity consistently at cold boot and admission. Preserve the existing database, signing secret and TLS certificate; recovery must never require clients to re-pair.

When hosting ends and no view remains, release the retained engine cleanly. If the login screen remains visible, retain the UI engine while releasing server resources. Do not add a second Android process in this scope.

Exit criterion: Home, Back/Activity destruction and Recents removal leave remote orders working; reopening restores UI with one runtime and no leaked Activity; cold service creation runs required plugins and host controls without rendering.

### 3. Make recovery honor the operator's intent

Persist a native-owned desired-hosting flag through the platform controller. It is restart intent, never authorization. Set it only for an admitted host; clear it before explicit stop, admin logout, role change, or eligibility shutdown, so a crash during teardown cannot resurrect hosting. Serialize overlapping start/stop commands and invalidate late boot completions.

On sticky recreation, including a null Intent, check intent, immediately publish starting/recovering state, and run the same Dart eligibility and startup controller. When authorization is unavailable or invalid, stop hosting and report that sign-in is needed. Keep the existing offline eligibility policy; do not silently broaden it to improve uptime.

Do not equate mode=server with authorization to restart. Avoid reading cached Dart preferences after native mutation: keep the desired-hosting field owned by native code, accessed through its channel. Multiple engines/isolate or native writes can make legacy SharedPreferences caches stale. [Package guidance](https://pub.dev/packages/shared_preferences).

Use `START_STICKY` as Android recovery assistance, not a fixed restart-time guarantee. Record process/service start, Dart readiness, stop reason and available OS exit reason. Avoid alarm watchdogs or unbounded crash loops. Cap retries of recoverable startup failures; require attention for persistent configuration/auth/database failures. Ensure the server cannot report healthy while only the notification has recovered.

Automatic reboot/APK-replacement recovery is a later, explicit host setting. If added, recheck allowed service types, first-unlock/credential storage, desired state and eligibility. Do not add direct-boot storage migrations for this task. User force-stop and active-app Stop remain intentional interruptions. [Android Service lifecycle](https://developer.android.com/reference/android/app/Service), [user stop](https://developer.android.com/develop/background-work/services/fgs/handle-user-stopping).

Exit criterion: controlled process death can restore orders and discovery without UI; logout/revocation never restarts; repeated start/stop and startup failure leave no duplicate resources.

### 4. Add server power setup and LAN recovery

Acquire a partial CPU wake lock only while starting/hosting/recovering. Use explicit release in normal stop, boot failure and teardown, with a bounded startup deadline so failed boot cannot retain power indefinitely. Measure the intentional all-shift hold on the actual tablet; do not add a short lock timeout that silently expires mid-service.

Explain battery exemption when enabling the host: this device receives orders even while its screen is off. Verify the actual exemption with the OS API after returning from settings. Prefer the standard settings route; direct exemption requests, if selected for this core function, need the corresponding permission and documented rationale. Manufacturer “unrestricted”/autostart controls must be verified on supported models rather than assumed equivalent to AOSP exemption. Keep the host powered and offer actionable battery/network status.

Do not add high-performance or low-latency Wi-Fi locks as a blanket screen-off fix. Review current API behavior in the platform note. Bonsoir already manages multicast; avoid a redundant permanent multicast lock. A multicast lock is not a CPU lock or a Doze bypass. [Current Wi-Fi lock behavior](https://developer.android.com/reference/android/net/wifi/WifiManager#WIFI_MODE_FULL_HIGH_PERF).

Observe relevant Wi-Fi/Ethernet availability and link changes with network callbacks. A LAN without internet is valid: do not require internet validation or rely only on the cellular/default network. On interface recovery, refresh discovery and listeners only when needed. Preserve TLS identity, database and state; avoid restarting on every callback. Keep local serving health separate from WAN eligibility refresh and remote-client reachability. [Network-state APIs](https://developer.android.com/develop/connectivity/network-ops/reading-network-state).

Exit criterion: the screen-off host serves on an internet-free LAN, works with the verified power configuration, recovers after router/DHCP changes, and releases resources on stop.

### 5. Compatibility, validation and rollout

Keep target/compile 36 for this change. Test on Android 17 as well; plan ACCESS_LOCAL_NETWORK migration when deliberately moving to target 37. Permission affects receiving LAN connections and discovery as well as client connections; it is not a replacement for foreground execution. Current official guidance says not to declare/request it below target 37. [Local-network permission](https://developer.android.com/privacy-and-security/local-network-permission).

Run `flutter analyze` with zero issues, focused lifecycle/controller tests, and debug/release Android builds after implementation. Verify the merged release manifest. Do not assume the old Patrol guide is runnable: this checkout lacks `patrol_test/` and the current pubspec does not declare Patrol, despite older documentation and native harness references. Use a verified native/device harness plus an independent LAN client for the lifecycle tests.

| Scenario | Required evidence |
|---|---|
| First host admission and cached cold boot | Exactly one FGS, engine, runtime, database owner, staff listener and eligible guest listener. |
| Home/app switch/lock for 12 hours | Remote authenticated orders and WebSocket updates throughout, no missing acknowledged writes, no duplication on retries, recorded latency and battery/thermal behavior. |
| Screen off, unplugged, forced Doze | Compare exemption denied and granted; verify real remote TCP and fresh discovery, not only existing connections or localhost. Restore all device test settings afterward. |
| Activity destroyed, Recents swipe, repeated reopen | Server continues, UI reconnects, plugin channels still work, no duplicate listeners or stale Activity. |
| OS-style process death | Log actual recovery delay; restore certificate/venue/DB, eligibility subscriptions, guest assets and kitchen alerts without opening UI. Force-stop is a separate test, not a stand-in for low-memory death. |
| Notification denied/channel blocked/dismissed | Correct hosting state; no repost fight, shutdown or fake healthy assumption tied to notification visibility. |
| Admin logout/revocation/expired eligibility | Stop flag persists before teardown; runtime and locks stop; service cannot revive the host. |
| Router reboot, DHCP change, no internet, Wi-Fi with cellular enabled | Restore discovery and client resync with unchanged pinned identity; retain valid LAN service without WAN validation. |
| Bound-port/DB/mDNS failure, duplicate commands | Bounded error handling, released partial resources, no false serving notification. |
| Native picker, permissions, audio after reattach | No Activity leaks, lost callbacks or broken essential plugin behavior. |
| Android active-app Stop, Settings force-stop, reboot, APK replacement | Document actual expected interruption/relaunch behavior; no unauthorized resurrection. |
| Client/owner/super-admin mode | No host service, host CPU lock or host battery prompts. |

Minimum device coverage: API 29 baseline, 31 background-start boundary, 33 notification permission, 34 ongoing-dismissal/type checks, 35 timeout behavior, 36 shipping target and 37 forward compatibility. Use an AOSP/Pixel reference plus each restaurant host model/OS actually supported; emulator success alone is insufficient.

Roll out first to a test venue with logs and an explicit recovery procedure. The release gate is a full shift passing on supported hardware. Backend/UI latency under load, OEM kills and detached plugin behavior remain empirical questions. If the retained-engine version fails those tests because of shared UI execution or ownership constraints, advance to the separate-engine design with evidence and an explicit migration of the host control paths.
