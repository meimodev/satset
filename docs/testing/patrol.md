# Patrol — native UI / integration testing

Patrol is the testing tool for SatSet end-to-end and native-interaction flows.
It wraps `integration_test` but can also drive native UI (permission dialogs,
notifications, system back, WebViews) that plain widget tests can't reach.

**Use Patrol for**: full-app flows that boot `main()` and exercise real
navigation, pairing, native permissions, or multi-screen journeys on a device.
**Keep `package:flutter_test` widget tests** (`test/`) for isolated widgets and
pure-Dart unit logic — they run on the host VM, are far faster, and need no
device. Don't port those to Patrol.

## Layout

- Tests live in **`patrol_test/`** (patrol_cli's default target dir), named
  `*_test.dart`. NOT `integration_test/`.
- Each test uses `patrolTest(...)` with the `$` PatrolIntegrationTester.
- `patrol_test/test_bundle.dart` is generated on every run — gitignored.

## Native harness (already wired)

- `pubspec.yaml` — `patrol` dev dep + `patrol:` config block (app_name,
  android.package_name `id.satset.satset`).
- `android/app/build.gradle.kts` — `testInstrumentationRunner =
  "pl.leancode.patrol.PatrolJUnitRunner"`, `clearPackageData` arg,
  `testOptions { execution = "ANDROIDX_TEST_ORCHESTRATOR" }`, and
  `androidTestUtil("androidx.test:orchestrator:1.5.1")`.
- `android/app/src/androidTest/java/id/satset/satset/MainActivityTest.java` —
  the JUnit `@RunWith(Parameterized.class)` bridge that enumerates Dart tests
  via `listDartTests()` and runs each on-device. Boots `MainActivity`.

## Running

`patrol` CLI is installed globally (`dart pub global activate patrol_cli`).
It needs Android SDK tools on PATH:

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH:$HOME/.pub-cache/bin"

patrol test                                   # all tests in patrol_test/
patrol test --target patrol_test/app_boot_test.dart
patrol test -d <adb-serial>                   # pick device (adb devices)
patrol doctor                                 # diagnose setup
```

Persist the env exports in your shell profile (`~/.zshrc`) so `adb` /
`ANDROID_HOME` are always visible to patrol_cli.

## Version pairing (important)

`patrol_cli` and the `patrol` package must be compatible (see
<https://patrol.leancode.co/compatibility-table>). A skew silently produces a
broken `test_bundle.dart`. Current setup: patrol pkg `4.6.1` + patrol_cli
`4.4.0`. After bumping one, bump the other and re-check the table.
