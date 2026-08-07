import 'package:satset/data/services/api_client.dart';
import 'package:satset/l10n/app_localizations.dart';

/// Maps a sign-in failure to plain, casual copy shown to staff.
///
/// Takes [l] rather than reaching for a `BuildContext`: this runs inside a
/// repository, below the widget tree (ADR-0083).
///
/// Never leaks raw exception text (`e.toString()`) to the user. [pin] selects
/// PIN vs email+password wording for the wrong-credential (401) case; the
/// message stays generic so it never reveals which field was wrong.
String authErrorMessage(AppL10n l, Object error, {required bool pin}) {
  if (error is ApiException) {
    if (error.statusCode >= 500) return l.authServerTrouble;
    // 401 (and any other 4xx on a login call) means the credentials were
    // rejected. Stay generic — don't confirm which field was valid.
    return pin ? l.authWrongPin : l.authWrongCredentials;
  }
  // SocketException, HandshakeException, TimeoutException, or anything else
  // non-HTTP: we never reached / understood the server.
  return l.authNoConnection;
}
