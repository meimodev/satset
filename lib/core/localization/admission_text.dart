import 'package:satset/domain/models/admission.dart';
import 'package:satset/l10n/app_localizations.dart';

/// Composes the words for an [AdmissionOutcome] at read time. The outcome
/// carries a code and its params; a sentence never crosses the layer (ADR-0085).
///
/// `null` means **say nothing** — and that is a real answer, not a gap. Four
/// outcomes have no line: the three admitted ones (the app moves on),
/// [AdmissionCancelled] (the admin knows, they pressed it),
/// [AdmissionNeedsNewPassword] (the change form is the message) and
/// [AdmissionHostOccupied] (its own full screen, which names the other device —
/// a line under the form would invite a retype of a password that was never
/// wrong).
/// [outcome] is nullable because "no attempt yet" is the screen's opening
/// state, and it says nothing for the same reason a cancel does.
String? admissionText(AppL10n l, AdmissionOutcome? outcome) => switch (outcome) {
  null => null,
  AdmittedAsHost() ||
  AdmittedAsSuper() ||
  AdmittedAsOwner() ||
  AdmissionNeedsNewPassword() ||
  AdmissionHostOccupied() ||
  AdmissionCancelled() => null,

  // Firebase's own code. Falls through to the generic line rather than
  // rendering blank, so a code this build has never heard of still says
  // something an operator can act on.
  AdmissionCredentialsRejected(:final code) => switch (code) {
    'invalid-email' => l.authInvalidEmail,
    'user-disabled' => l.authAccountDisabled,
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => l.authWrongCredentials,
    'too-many-requests' => l.authTooManyAttempts,
    'network-request-failed' => l.authFirstLoginNeedsInternet,
    _ => l.authAdminLoginFailed,
  },
  AdmissionTempPasswordExpired() => l.tempPasswordExpired,

  AdmissionNotRegistered() => l.authAdminNotRegistered,
  AdmissionAccountBlocked(:final reason) => switch (reason) {
    AdmissionBlock.suspended => l.authAdminSuspended,
    _ => l.authAdminInactive,
  },
  AdmissionNoVenue() => l.authNoVenueAssigned,
  AdmissionVenueBlocked(:final reason) => switch (reason) {
    AdmissionBlock.notFound => l.authVenueNotFound,
    AdmissionBlock.suspended => l.authVenueSuspended,
    _ => l.authVenueInactive,
  },

  AdmissionServerBootFailed() => l.pinServerBootFailed,
  AdmissionLocalSessionFailed() => l.authServerNotReady,
  // The stage is in the log, not on screen: whichever call died, the admin's
  // next move is the same one.
  AdmissionUnreachable() => l.admissionUnreachable,
};
