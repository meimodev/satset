import 'package:package_info_plus/package_info_plus.dart';

/// This build's own `versionName`, read once from the installed package.
///
/// A static rather than a provider because the two earliest readers are outside
/// the widget tree: `main()` hands it to `ServerRuntime.boot`, which advertises
/// it as `ver` in the mDNS TXT record before any `ProviderScope` exists. The
/// release gate (ADR-0087) compares against this exact string.
///
/// Read from the package, never from a constant kept in step with
/// `pubspec.yaml`: `ServerRuntime.defaultVersion` was such a constant, and it
/// said `1.0.0` for every release after 1.0.0.
abstract final class AppVersion {
  static String _value = '';
  static String _build = '';

  /// Empty until [load] has run. Empty **fails the gate open** — an
  /// unparseable version is never blocked — which is the right answer for the
  /// sliver of boot before the package is read.
  static String get value => _value;

  /// The `versionCode` this build was installed as — CI overrides the pubspec
  /// `+N` with a timestamp, so it identifies the build the way the semver
  /// cannot. Shown on `/me`; nothing gates on it. Empty until [load].
  static String get build => _build;

  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _value = info.version.trim();
      _build = info.buildNumber.trim();
    } catch (_) {
      // A platform that cannot answer leaves it empty rather than guessing.
      _value = '';
      _build = '';
    }
  }
}
