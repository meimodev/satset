/// The release gate (ADR-0087): which builds of SatSet the fleet may run.
///
/// Three plain `MAJOR.MINOR.PATCH` strings, any of which may be absent. The
/// build number never appears — CI is free to move it and the release tag never
/// carries it, so a gate keyed on it would compare two things that are not the
/// same number.
///
/// Lives in `domain/` because both halves of the app hold one: the host reads
/// it from Firestore, every client receives it over the LAN, and the comparison
/// that turns it into a verdict must be the same code on both sides.
library;

/// What the gate says about one installed version.
enum UpdateVerdict {
  /// Current enough. The overwhelmingly common case, and what every unknown
  /// resolves to.
  none,

  /// At or above [ReleaseGate.min] but below [ReleaseGate.recommended]. The
  /// Main Device nags; nothing else is told (ADR-0087).
  recommended,

  /// Below [ReleaseGate.min]. Non-dismissible block, immediately.
  blocked,
}

class ReleaseGate {
  /// Below this, a device stops. Null means no floor has ever been set.
  final String? min;

  /// Below this, the host nags.
  final String? recommended;

  /// What the GitHub Release currently holds. Shown, never enforced.
  final String? latest;

  const ReleaseGate({this.min, this.recommended, this.latest});

  /// The gate a device holds before it has heard anything. Blocks nobody.
  static const unknown = ReleaseGate();

  bool get isEmpty => min == null && recommended == null && latest == null;

  static String? _str(Object? v) {
    final s = (v as String?)?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  factory ReleaseGate.fromJson(Map<String, dynamic> j) => ReleaseGate(
    min: _str(j['min']),
    recommended: _str(j['recommended']),
    latest: _str(j['latest']),
  );

  Map<String, dynamic> toJson() => {
    if (min != null) 'min': min,
    if (recommended != null) 'recommended': recommended,
    if (latest != null) 'latest': latest,
  };

  /// The verdict for [installed].
  ///
  /// **Everything unknown fails open.** No floor, no installed version, a
  /// version neither side can parse — all of them return [UpdateVerdict.none].
  /// A gate that blocked on its own ignorance would take a venue offline over a
  /// Firestore outage or a malformed string, which is a worse failure than the
  /// one it exists to prevent.
  UpdateVerdict verdictFor(String? installed) {
    if (installed == null || parseVersion(installed) == null) {
      return UpdateVerdict.none;
    }
    if (compareVersions(installed, min) < 0) return UpdateVerdict.blocked;
    if (compareVersions(installed, recommended) < 0) {
      return UpdateVerdict.recommended;
    }
    return UpdateVerdict.none;
  }

  @override
  bool operator ==(Object other) =>
      other is ReleaseGate &&
      other.min == min &&
      other.recommended == recommended &&
      other.latest == latest;

  @override
  int get hashCode => Object.hash(min, recommended, latest);

  @override
  String toString() => 'ReleaseGate(min: $min, rec: $recommended, latest: $latest)';
}

/// `1.2.3` → `[1, 2, 3]`, or null when it is not three integers.
///
/// Anything a release tag would not produce is rejected outright rather than
/// coerced: a coerced version compares as *something*, and the something it
/// compares as decides whether a restaurant keeps trading.
List<int>? parseVersion(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return null;
  final parts = s.split('.');
  if (parts.length != 3) return null;
  final out = <int>[];
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null || n < 0) return null;
    out.add(n);
  }
  return out;
}

/// Orders two versions, treating an unset or unparseable side as **equal**.
///
/// Equal, not lesser: the callers ask "is the installed build below the floor",
/// and a missing floor must answer no. Returning -1 for an absent floor would
/// invert that into "below everything".
int compareVersions(String? a, String? b) {
  final pa = parseVersion(a);
  final pb = parseVersion(b);
  if (pa == null || pb == null) return 0;
  for (var i = 0; i < 3; i++) {
    if (pa[i] != pb[i]) return pa[i] < pb[i] ? -1 : 1;
  }
  return 0;
}
