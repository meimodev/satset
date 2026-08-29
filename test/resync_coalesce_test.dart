// A drained [[Antrean kirim]] re-pulls the board (ADR-0090), and for months
// that re-pull did nothing. The reconnect's own resync and the drain hang off
// the same `connected` event, so the drain's `resyncNow()` always arrives while
// the reconnect GET is still in flight — and the stampede guard *dropped* it.
// The in-flight GET had left before the replayed void and the replayed order
// landed, so its response clobbered the WS deltas that had already applied them
// and the waiter's own tablet showed the world as it was a moment before the
// backlog. Found on a tablet emulator, 2026-08-29.
//
// The guard now coalesces: a resync asked for mid-flight re-runs afterwards.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/secure_storage_service.dart';

final _config = ApiConfig(
  baseUri: Uri.parse('https://127.0.0.1:8443'),
  trustedFingerprint: '',
);

/// Answers `/tickets` only when the test lets it, so a second resync can be
/// asked for while the first is genuinely still in flight.
class _GatedApi extends ApiClient {
  _GatedApi() : super(config: _config, storage: SecureStorageService());

  final gates = <Completer<void>>[];
  var calls = 0;
  // What the *next* response carries. Changing it between releases is the
  // server moving on while a GET is in the air.
  var payload = <Map<String, dynamic>>[];

  @override
  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    if (path != '/tickets') return const [];
    calls++;
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    return payload;
  }

  /// Lets the oldest pending GET answer.
  void release() => gates.removeAt(0).complete();
}

Map<String, dynamic> _ticket(String id, String status) => {
  'id': id,
  'tableId': 'meja-7',
  'visitId': 'visit-1',
  'itemId': 'item-1',
  'name': 'Nasi goreng',
  'course': 'mains',
  'qty': 1,
  'price': 40000,
  'status': status,
  'sentAt': '2026-08-29T09:00:00.000Z',
};

/// A few event-loop turns — enough for a completed GET to be parsed and the
/// deferred pass to issue its own.
Future<void> pump([int turns = 5]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('a resync asked for mid-flight runs again, it is not dropped', () async {
    final api = _GatedApi();
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWith((_) => api)],
    );
    addTearDown(container.dispose);

    final repo = container.read(ticketsProvider.notifier);
    // The bootstrap GET fires from the constructor; let it through so the
    // repository is idle before the interesting pair.
    await pump();
    if (api.gates.isNotEmpty) api.release();
    await pump();

    // The reconnect's GET leaves while the server still says `sent`.
    api.payload = [_ticket('t1', 'sent')];
    final first = repo.resyncNow();
    await pump();
    final callsBefore = api.calls;

    // The drain lands its writes, then asks for the re-pull the old guard ate.
    api.payload = [_ticket('t1', 'voided')];
    final second = repo.resyncNow();
    await pump();
    expect(api.calls, callsBefore, reason: 'the second must wait, not stampede');

    api.release(); // the stale response arrives first
    await pump();
    expect(api.calls, callsBefore + 1, reason: 'the deferred resync must run');
    api.release();
    await Future.wait([first, second]);

    expect(container.read(ticketsProvider)['visit-1']!.single.status.name,
        'voided');
  });
}
