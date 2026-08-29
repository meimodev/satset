// ADR-0116. The table detail screen used to collapse "somebody else has this
// table" and "nobody could be asked" into one `readOnly` boolean, which
// padlocked the screen in exactly the condition the [[Antrean kirim]] exists
// for — so the offline order of ADR-0090 and the offline void of ADR-0114 were
// both unreachable from the only dine-in door to them.
//
// The first case here fails against the code this replaces, which is the case
// that should have existed all along.
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/ui/features/tables/table_detail_screen.dart';

void main() {
  test('terputus with no lease still orders and voids', () {
    final a = tableAccess(
      lockedByOther: false,
      hasLease: false,
      offline: true,
    );
    expect(a.canQueueWrite, isTrue);
    // Everything without an intent behind it still waits.
    expect(a.readOnly, isTrue);
  });

  test('another waiter holding it blocks both, online or terputus', () {
    for (final offline in [false, true]) {
      final a = tableAccess(
        lockedByOther: true,
        hasLease: false,
        offline: offline,
      );
      expect(a.canQueueWrite, isFalse, reason: 'offline=$offline');
      expect(a.readOnly, isTrue, reason: 'offline=$offline');
    }
  });

  test('online without the lease blocks both — the lease is askable', () {
    final a = tableAccess(
      lockedByOther: false,
      hasLease: false,
      offline: false,
    );
    expect(a.canQueueWrite, isFalse);
    expect(a.readOnly, isTrue);
  });

  test('holding the lease is fully editable, socket or no socket', () {
    for (final offline in [false, true]) {
      final a = tableAccess(
        lockedByOther: false,
        hasLease: true,
        offline: offline,
      );
      expect(a.canQueueWrite, isTrue, reason: 'offline=$offline');
      expect(a.readOnly, isFalse, reason: 'offline=$offline');
    }
  });
}
