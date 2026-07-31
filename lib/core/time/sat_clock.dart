/// The app's clock seam.
///
/// Every **domain** timestamp — when a line was sent, fired, ready, served,
/// when a bill closed, when a payment landed, when an audit row was written —
/// and every elapsed-time computation in the UI reads [now] instead of
/// `DateTime.now()`.
///
/// In shipped builds the offset is **always zero**: ADR-0073 removed the demo
/// clock along with the live snapshot it existed to hold, so a seeded venue
/// runs on real time and the sample seed backdates by passing each row's
/// instant explicitly into the write path instead. The seam stays because it
/// is what lets a test travel in time without every call site knowing, and
/// because reinstating a shifted clock would otherwise mean touching 120 call
/// sites again.
///
/// **Security never reads this.** JWT issuance and validation, session expiry,
/// the pairing-token window and TLS certificate validity call [realNow]: a
/// rewound auth clock keeps tokens alive past their stated lifetime, which is
/// an authentication defect that outlives whatever shifted the clock.
class SatClock {
  SatClock._();

  static Duration _offset = Duration.zero;

  /// App time minus real time. Zero everywhere outside a test.
  static Duration get offset => _offset;

  /// The app's current time. Still *runs*: the offset is a fixed shift, so
  /// timers tick, lateness climbs and alerts escalate normally. Never a frozen
  /// clock.
  static DateTime now() => DateTime.now().add(_offset);

  /// Wall-clock time, ignoring any offset. For auth, pairing, TLS and anything
  /// else where being wrong is a security bug rather than a cosmetic one.
  static DateTime realNow() => DateTime.now();

  /// Apply an offset. A test seam — production code never calls this.
  static void adopt(Duration value) => _offset = value;

  /// Return to real time.
  static void clear() => _offset = Duration.zero;
}
