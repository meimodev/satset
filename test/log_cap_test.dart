import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/repositories/cash_repository.dart';
import 'package:satset/data/repositories/venue_audit_repository.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/cash_entry.dart';

/// Two paged logs grew without a ceiling. The venue audit log accumulates every
/// page a manager scrolls past — rows and their widgets, on a tablet — and the
/// petty cash ledger is worse in a different way: ADR-0079 pages it by a
/// *growing limit*, so the tenth `loadMore` re-transfers five hundred rows in
/// order to append fifty.
///
/// Neither can drop rows off the head to make room. A manager mid-read must not
/// have the row under their finger move — the same reason live audit rows are
/// held in `pending` instead of being spliced in. So the cap has to be "stop
/// fetching", and the thing that makes stopping honest is saying so: `capped`
/// and `hasMore` must not be the same question, because "the list ended" and
/// "this screen stopped looking" mean opposite things about the venue.
void main() {
  AuditEntry entry(int i) => AuditEntry(
    id: 'a$i',
    type: AuditType.voidItem,
    title: 'x',
    tableId: 't1',
    when: '2026-08-22T10:00:00',
  );

  VenueAuditState audit({required int rows, String? cursor}) => VenueAuditState(
    items: [for (var i = 0; i < rows; i++) entry(i)],
    nextCursor: cursor,
  );

  group('venue audit', () {
    test('below the cap it pages normally', () {
      final s = audit(rows: kAuditMaxLoaded - 1, cursor: 'c');
      expect(s.hasMore, isTrue);
      expect(s.capped, isFalse);
    });

    test('at the cap it stops asking and says why', () {
      final s = audit(rows: kAuditMaxLoaded, cursor: 'c');
      expect(s.capped, isTrue);
      expect(
        s.hasMore,
        isFalse,
        reason: 'the scroll listener drives loadMore off hasMore',
      );
    });

    test('a log that genuinely ended is not reported as capped', () {
      // No cursor: the server said there is nothing behind this page. Showing
      // "narrow the range" here would claim the venue did more than it did.
      final s = audit(rows: kAuditMaxLoaded);
      expect(s.capped, isFalse);
      expect(s.hasMore, isFalse);
    });
  });

  group('petty cash', () {
    CashState cash(int rows) => CashState(
      entries: [
        for (var i = 0; i < rows; i++)
          CashEntry(
            id: 'c$i',
            boxId: 'box-main',
            kind: CashEntryKind.expense,
            categoryId: 'other',
            delta: -1000,
            at: DateTime(2026, 8, 22),
          ),
      ],
    );

    test('a short ledger is never capped', () {
      expect(cash(kCashMaxLoaded - 1).capped, isFalse);
    });

    test('the growing limit stops growing', () {
      expect(cash(kCashMaxLoaded).capped, isTrue);
    });
  });

  test('the two caps are both smaller than the page count that hurts', () {
    // Guarding the numbers themselves, loosely: the point of the caps is that
    // neither list reaches thousands of rows on a tablet.
    expect(kAuditMaxLoaded, lessThanOrEqualTo(2000));
    expect(kCashMaxLoaded, lessThanOrEqualTo(2000));
  });
}
