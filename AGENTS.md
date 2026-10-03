# SatSet — Agent Instructions

Flutter 3.41.9 Android app for LAN restaurant ordering. A single APK runs as venue host or client. The host has an embedded Shelf server and Drift database; clients pair over mDNS and use local journals for offline work. Firebase handles admin identity and fleet features. The app uses Riverpod, GoRouter, committed codegen output, and Indonesian/English ARB localization.

## Commands

```bash
flutter pub get
flutter analyze              # zero issues required
flutter test
flutter test test/control_golden_test.dart --tags golden --run-skipped
flutter build apk --release
tool/codegen.sh              # after model/schema source changes
flutter gen-l10n             # after ARB changes
```

Read [CLAUDE.md](CLAUDE.md) for the current code layout and architecture, [PRODUCT.md](PRODUCT.md) for product rules, and [CONTEXT.md](CONTEXT.md) for domain terms. [README.md](README.md) covers setup and release flow.

## CodeGraph

Use CodeGraph for structural code questions (definitions, callers, impact, and flow); use `rg` for literal text. Before using CodeGraph, check whether `.codegraph/` exists. If missing or uninitialized, run `codegraph init -i` in the repository root. Initialization is authorized.

## CI/CD

GitHub Actions checks analysis, tests, goldens, and a release APK. A pushed `v*` tag triggers Codemagic to publish the signed APK, then update the fleet release gate. `-breaking` is a mandatory update that blocks older clients. See [codemagic.yaml](codemagic.yaml) and [ADR-0130](docs/adr/0130-the-update-gate.md). Never publish the gate before the APK is available.
