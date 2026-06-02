import 'dart:io';

/// Raw-socket ESC/POS transport (JetDirect / RAW 9100). Opens a TCP socket to
/// the printer, writes the byte stream, flushes and closes. Used by the server
/// for venue printers and by a client for its own device printers — the same
/// renderer feeds both, only this transport differs. See ADR-0020.
class StrukSocket {
  /// Sends [bytes] to [host]:[port]. Throws on connect/write failure so the
  /// caller can surface "printer tak terhubung".
  static Future<void> send(
    String host,
    int port,
    List<int> bytes, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      socket.add(bytes);
      await socket.flush();
      // Give the printer a beat to drain before we tear the socket down.
      await Future<void>.delayed(const Duration(milliseconds: 120));
    } finally {
      socket?.destroy();
    }
  }

  /// Connect-only reachability probe: opens a TCP socket and immediately tears
  /// it down, sending no bytes. Returns true if the printer answered within
  /// [timeout]. Used by the venue/device heartbeat — never spews a struk. See
  /// ADR-0022.
  static Future<bool> probe(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }
}
