/// The app's clock seam.
///
/// Every **domain** timestamp — when a line was sent, fired, ready, served,
/// when a bill closed, when a payment landed, when an audit row was written —
/// and every elapsed-time computation in the UI reads [now] instead of
/// `DateTime.now()`, so a venue holding demo data can run on a shifted clock
/// and every screen agrees about what time it is (ADR-0053).
///
/// **Security never reads this.** JWT issuance and validation, session expiry,
/// the pairing-token window and TLS certificate validity call [realNow]: a
/// rewound auth clock keeps tokens alive past their stated lifetime, which is
/// an authentication defect that outlives the demo.
///
/// On a venue with no demo data [offset] is zero and [now] == [realNow].
class SatClock {
  SatClock._();

  static Duration _offset = Duration.zero;

  /// Demo time minus real time. Set from the host's `/auth/me` bootstrap and
  /// its `demo.clock` broadcast; zero on any venue without demo data.
  static Duration get offset => _offset;

  /// Whether the app is currently running on a shifted clock.
  static bool get isShifted => _offset != Duration.zero;

  /// The app's current time — real time plus the demo offset.
  ///
  /// Note this still *runs*: the offset is a fixed shift re-anchored when the
  /// host boots, so timers tick, lateness climbs and alerts escalate normally
  /// during a session (ADR-0053 §1). It is not a frozen clock.
  static DateTime now() => DateTime.now().add(_offset);

  /// Wall-clock time, ignoring any demo offset. For auth, pairing, TLS and
  /// anything else where being wrong is a security bug rather than a cosmetic
  /// one.
  static DateTime realNow() => DateTime.now();

  /// Apply an offset. Called on the host when it boots against demo data, and
  /// on every client from the host's bootstrap/broadcast.
  static void adopt(Duration value) => _offset = value;

  /// Return to real time — the venue no longer holds demo data.
  static void clear() => _offset = Duration.zero;

  /// Re-anchor so that [now] reads [anchor], then run forward from there.
  ///
  /// This is what the host does at boot: the demo snapshot was authored to be
  /// read at [anchor], so pinning the clock back to it makes every seeded
  /// state read at the age it was written for, however long ago that was.
  static void anchorTo(DateTime anchor) =>
      _offset = anchor.difference(DateTime.now());
}
