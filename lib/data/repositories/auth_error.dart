import 'package:satset/data/services/api_client.dart';

/// Maps a sign-in failure to plain, casual Bahasa Indonesia shown to staff.
///
/// Never leaks raw exception text (`e.toString()`) to the user. [pin] selects
/// PIN vs email+password wording for the wrong-credential (401) case; the
/// message stays generic so it never reveals which field was wrong.
String authErrorMessage(Object error, {required bool pin}) {
  if (error is ApiException) {
    if (error.statusCode >= 500) {
      return 'Server lagi bermasalah. Coba lagi sebentar.';
    }
    // 401 (and any other 4xx on a login call) means the credentials were
    // rejected. Stay generic — don't confirm which field was valid.
    return pin ? 'PIN salah. Coba lagi.' : 'Email atau password salah.';
  }
  // SocketException, HandshakeException, TimeoutException, or anything else
  // non-HTTP: we never reached / understood the server.
  return 'Gagal terhubung ke server. Cek Wi-Fi lalu coba lagi.';
}
