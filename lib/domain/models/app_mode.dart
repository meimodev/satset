/// Operating mode of this APK. Persisted in prefs and decided on first launch.
enum AppMode {
  /// First-boot state before user picks Server or Client.
  unset,

  /// This device hosts the in-app shelf server and Drift database for the
  /// venue. Client connections are loopback in this mode.
  server,

  /// This device connects over LAN to a paired server tablet.
  client,
}

String appModeKey(AppMode m) => switch (m) {
  AppMode.unset => 'unset',
  AppMode.server => 'server',
  AppMode.client => 'client',
};

AppMode appModeFromKey(String? raw) => switch (raw) {
  'server' => AppMode.server,
  'client' => AppMode.client,
  _ => AppMode.unset,
};
