// The read paths that assemble a bill, page the venue audit log and reverse a
// void must reach their rows through an index, not a table scan. On a fresh
// venue a scan is invisible; over a season of trading it is the difference
// between a cashier screen that opens and one that hangs.
//
// Assertions are pinned to **index names**, never to the planner's prose:
// SQLite is free to reword "SEARCH ... USING INDEX" between versions, but the
// name in the plan is the one _createLookupIndexes wrote. A plan that reaches
// the rows some other way still fails here, which is the point — the index
// existing is not the same as the query using it.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/server/db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// The chosen index names for one query, as SQLite reports them.
  Future<Set<String>> indexesUsedBy(String sql) async {
    final rows = await db.customSelect('EXPLAIN QUERY PLAN $sql').get();
    final names = <String>{};
    for (final r in rows) {
      final detail = r.data['detail'] as String? ?? '';
      // "SEARCH payments USING INDEX payments_receipt (receipt_id=?)"
      final m = RegExp(r'USING (?:COVERING )?INDEX (\w+)').firstMatch(detail);
      if (m != null) names.add(m.group(1)!);
    }
    return names;
  }

  Future<void> expectsIndex(String name, String sql) async {
    expect(
      await indexesUsedBy(sql),
      contains(name),
      reason:
          'query planned without $name — it will scan the table:\n  $sql\n'
          'plan: ${await indexesUsedBy(sql)}',
    );
  }

  test('live lines resolve through the visit index', () async {
    await expectsIndex(
      'tickets_visit',
      "SELECT * FROM tickets WHERE visit_id = 'v1'",
    );
  });

  test('bill assembly indexes every hop from visit to payment', () async {
    await expectsIndex(
      'receipts_visit',
      "SELECT * FROM receipts WHERE visit_id = 'v1'",
    );
    await expectsIndex(
      'payments_receipt',
      "SELECT * FROM payments WHERE receipt_id = 'r1'",
    );
    await expectsIndex(
      'receipt_lines_receipt',
      "SELECT * FROM receipt_lines WHERE receipt_id = 'r1'",
    );
  });

  test('an ordinary discount lookup does not rely on the partial indexes', () {
    // idx_discounts_order_uniq is partial (WHERE receipt_id IS NOT NULL AND
    // ticket_id IS NULL); SQLite may only use it when the query implies that
    // predicate. This read does not, so it must land on the plain index.
    return expectsIndex(
      'discounts_receipt',
      "SELECT * FROM discounts WHERE receipt_id = 'r1'",
    );
  });

  test('every session snapshot table is indexed by session', () async {
    const tables = [
      'table_session_tickets',
      'table_session_receipts',
      'table_session_payments',
      'table_session_discounts',
      'table_session_courses',
    ];
    for (final t in tables) {
      await expectsIndex(
        '${t}_session',
        "SELECT * FROM $t WHERE session_id = 's1'",
      );
    }
  });

  test(
    'venue audit paging walks the index instead of sorting the log',
    () async {
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM audit_entries '
            'ORDER BY at DESC, id DESC LIMIT 51',
          )
          .get();
      final details = [
        for (final r in plan) r.data['detail'] as String? ?? '',
      ].join('\n');
      expect(details, contains('audit_entries_at_id'));
      // A temp b-tree here means the whole log was sorted to return one page —
      // exactly the cost the composite index exists to remove.
      expect(details, isNot(contains('USE TEMP B-TREE')));
    },
  );

  test('own-shift audit feed filters on the actor index', () async {
    await expectsIndex(
      'audit_entries_actor_at',
      "SELECT * FROM audit_entries WHERE actor_user_id = 'u1' AND at >= 0",
    );
  });

  test('void reversal finds a ticket movement by reason', () async {
    await expectsIndex(
      'stock_movements_ticket_reason',
      "SELECT * FROM stock_movements WHERE ticket_id = 't1' AND reason = 'sale'",
    );
  });
}
