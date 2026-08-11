/// The outcome of one **admission** — an admin presenting credentials and the
/// app deciding, in stages, whether to let them in.
///
/// Sealed on purpose. The admission has fifteen outcomes and only two of them
/// are "wrong password"; before this type they travelled through four separate
/// channels (a `bool` return, a nullable error string, a `hostOccupied` field
/// and a provider), which is how a field ended up with a `copyWith` that
/// silently wiped it. One exhaustive `switch` at the call site means the
/// analyzer names the sixteenth outcome the day someone adds it.
///
/// A code and its params, never a sentence — the words are composed at read
/// time by `admission_text.dart` (ADR-0085).
library;

/// Why an account or a venue is not allowed to operate. Carries exactly the
/// distinction the copy makes and nothing more, so this file needs no import
/// from the data layer.
enum AdmissionBlock {
  /// Deliberately switched off — a terms violation, or the subscription sweep.
  suspended,

  /// Any other non-active state, including a status this build cannot parse.
  inactive,

  /// The document is not there at all. Venues only; a missing admin doc is
  /// [AdmissionNotRegistered].
  notFound,
}

sealed class AdmissionOutcome {
  const AdmissionOutcome();
}

// ---------------------------------------------------------------- admitted

/// The venue's own admin, on the device that will host it. The embedded server
/// is up and the local session is minted.
class AdmittedAsHost extends AdmissionOutcome {
  const AdmittedAsHost();
}

/// A fleet operator. No venue, no local server — the Fleet console. ADR-0016.
class AdmittedAsSuper extends AdmissionOutcome {
  const AdmittedAsSuper();
}

/// A report owner. Read-only, no local server. ADR-0036.
class AdmittedAsOwner extends AdmissionOutcome {
  const AdmittedAsOwner();
}

// ------------------------------------------------------------ continuation

/// A dictated temporary password was accepted, and it buys exactly one thing:
/// the right to replace itself (ADR-0075).
///
/// The only outcome that leaves a **live Firebase session** behind it — the
/// change form is authorized by the token this attempt just minted. Every other
/// non-admitted outcome has signed out by the time it is returned.
class AdmissionNeedsNewPassword extends AdmissionOutcome {
  final String uid;
  final String email;
  final String name;
  const AdmissionNeedsNewPassword({
    required this.uid,
    required this.email,
    required this.name,
  });
}

// ------------------------------------------------------ credential rejected

/// Firebase refused the credentials. [code] is its own (`wrong-password`,
/// `invalid-credential`, `too-many-requests`, …) and is resolved to copy at
/// read time; an unrecognised one falls through to a generic line rather than
/// rendering blank.
class AdmissionCredentialsRejected extends AdmissionOutcome {
  final String code;
  const AdmissionCredentialsRejected(this.code);
}

/// The temporary password was real but is past its window. ADR-0075.
class AdmissionTempPasswordExpired extends AdmissionOutcome {
  const AdmissionTempPasswordExpired();
}

// ------------------------------------------------------- refused by policy

/// Authenticated at Firebase, but there is no `admins/{uid}` document. An
/// operator has to create one; the uid is in the log.
class AdmissionNotRegistered extends AdmissionOutcome {
  const AdmissionNotRegistered();
}

/// The operator's own account is not active — one rogue manager disabled
/// without killing the venue.
class AdmissionAccountBlocked extends AdmissionOutcome {
  final AdmissionBlock reason;
  const AdmissionAccountBlocked(this.reason);
}

/// An active account with no venue attached. Nothing to host.
class AdmissionNoVenue extends AdmissionOutcome {
  const AdmissionNoVenue();
}

/// The venue kill switch, flippable mid-service from the fleet console.
/// ADR-0016, ADR-0076.
class AdmissionVenueBlocked extends AdmissionOutcome {
  final AdmissionBlock reason;
  const AdmissionVenueBlocked(this.reason);
}

// -------------------------------------------------- blocked by environment

/// Another device on the LAN already hosts this venue (ADR-0077). The
/// credentials were fine, which is why this is not a rejection: booting a rival
/// server would split the venue's data.
///
/// The Firebase session is left signed in — the condition clears the moment the
/// other device stops hosting, and charging a password re-entry for that would
/// tax the person standing between both devices.
class AdmissionHostOccupied extends AdmissionOutcome {
  final String hostLabel;
  const AdmissionHostOccupied(this.hostLabel);
}

/// Eligible in every way, but the embedded server would not start.
class AdmissionServerBootFailed extends AdmissionOutcome {
  const AdmissionServerBootFailed();
}

/// The server started but would not mint a local session for this admin.
class AdmissionLocalSessionFailed extends AdmissionOutcome {
  const AdmissionLocalSessionFailed();
}

/// A stage ran out of time. The venue's Wi-Fi carries the LAN but not the WAN
/// — a captive portal, an expired plan — which is the normal restaurant
/// failure and used to hang the sign-in button forever.
///
/// [stage] names which call died, for the log and nothing else; the copy is the
/// same either way, because "cannot reach the identity server" is the whole of
/// what the admin can act on.
class AdmissionUnreachable extends AdmissionOutcome {
  final String stage;
  const AdmissionUnreachable(this.stage);
}

// --------------------------------------------------------------- abandoned

/// The admin pressed Batal. Distinct from every failure: nothing is wrong, and
/// the screen must say nothing at all.
class AdmissionCancelled extends AdmissionOutcome {
  const AdmissionCancelled();
}

/// Whether this outcome let somebody in. The one predicate worth sharing —
/// everything else about an outcome is a `switch`.
extension AdmissionOutcomeX on AdmissionOutcome {
  bool get isAdmitted =>
      this is AdmittedAsHost ||
      this is AdmittedAsSuper ||
      this is AdmittedAsOwner;
}
