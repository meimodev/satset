# SatSet

Android restaurant ordering for staff on a local network. One APK runs as the venue host or a staff client. The host serves the LAN API and stores venue data locally; clients pair over Wi-Fi and keep offline work for replay. The app also has owner and fleet cloud features.

## Development

Use Flutter 3.41.9 and an Android SDK. Then run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The golden tests are separate from the normal suite because pixel output depends on the renderer:

```bash
flutter test test/control_golden_test.dart --tags golden --run-skipped
```

Generated Dart models and database code are committed. Run `tool/codegen.sh` after changing their sources; run `flutter gen-l10n` after changing `lib/l10n/*.arb`. See [CLAUDE.md](CLAUDE.md) for the architecture and [PRODUCT.md](PRODUCT.md) for product and design rules.

## Release

GitHub Actions runs analysis, tests, goldens, and a release APK build on pushes and pull requests. A `v*` tag triggers [Codemagic](codemagic.yaml) to build and sign the APK, publish a GitHub Release, distribute it to testers, then update the fleet release gate. A `-breaking` tag makes the new version mandatory for older clients; see [ADR-0130](docs/adr/0130-the-update-gate.md).

Before deploying to a venue, complete the [offline order and settlement device checks](docs/plans/offline-order-bill-device-test-checklist.md) and [background hosting checks](docs/testing/android-background-server.md) on the target hardware.
