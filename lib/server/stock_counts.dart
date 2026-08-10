/// **The** stok opname writer — third of the family that holds `writeAudit`,
/// `cash.dart` and `members.dart`, and here for the same reason: hand-roll the
/// insert and a new rule reaches three call sites out of four.
///
/// The invariants, all from ADR-0096:
///
/// - An opname is a **session**, not a burst of `adjust` rows. It opens, it is
///   walked, it closes, and only the close writes movements.
/// - A line **freezes what it was told when it was entered** — expected
///   quantity and unit cost. Sales keep deducting while the pantry is walked;
///   folding those into the variance would blame the counter for them.
/// - **Every counted bahan gets a line, including one found correct.** Only a
///   non-zero variance also writes a movement: the count is the evidence, the
///   movement is the consequence, and only the count always exists.
/// - A closed session is **never reopened** — its movements are already in the
///   ledger, and a second close would double them.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/ingredient.dart' show StockReason;
import 'package:satset/domain/models/stock_unit.dart' show valueOf;
import 'package:satset/server/audit_log.dart';
import 'package:satset/server/stock.dart';
import 'package:satset/server/ws_hub.dart';

import 'db/database.dart';

const _uuid = Uuid();

/// Open a session. Returns its id.
///
/// [blind] hides the expected number from the counter until close; it is the
/// default because a stocktake shown the answer tends to agree with it. Both
/// this and [scope] are recorded on the header, because a variance figure that
/// cannot say how it was produced cannot be argued with.
Future<String> openCount(
  AppDatabase db, {
  String? userId,
  StockCountScope scope = StockCountScope.partial,
  bool blind = true,
  String? note,
  DateTime? at,
  String? idPrefix,
}) async {
  final id = '${idPrefix ?? ''}${_uuid.v4()}';
  await db
      .into(db.stockCounts)
      .insert(
        StockCountsCompanion.insert(
          id: id,
          userId: Value(userId),
          scope: Value(scope.name),
          blind: Value(blind),
          note: Value(note),
          startedAt: at ?? SatClock.now(),
        ),
      );
  return id;
}

/// Enter (or re-enter) one counted bahan.
///
/// Freezes `expectedQty` and `costMicro` **now**, which is the whole reason
/// this table exists. Re-counting the same bahan in one session replaces the
/// line rather than adding a second — two expectations for one shelf disagree
/// by definition, and the unique index says so.
///
/// Returns null when the session is closed or the bahan is unknown.
Future<StockCountLineRow?> recordCountLine(
  AppDatabase db, {
  required String countId,
  required String ingredientId,
  required int counted,
  String? note,
  DateTime? at,
}) async {
  // In a transaction because the read and the write are one decision: the
  // Stok field commits on Enter *and* on losing focus, so two requests for the
  // same shelf land together, both read no existing line, both mint an id, and
  // the second trips the unique index — a 500 in the counter's face during an
  // ordinary keyboard flow.
  return db.transaction(() async {
    final session = await countById(db, countId);
    if (session == null || session.closedAt != null) return null;
    final ing = await (db.select(
      db.ingredients,
    )..where((i) => i.id.equals(ingredientId))).getSingleOrNull();
    if (ing == null) return null;

    final existing =
        await (db.select(db.stockCountLines)..where(
              (l) => l.countId.equals(countId) & l.ingredientId.equals(
                ingredientId,
              ),
            ))
            .getSingleOrNull();

    final line = StockCountLinesCompanion.insert(
      id: existing?.id ?? _uuid.v4(),
      countId: countId,
      ingredientId: ingredientId,
      // Re-entering a line keeps the **first** expectation. The counter is
      // correcting what they typed, not asking to be measured against a shelf
      // that has since sold three portions.
      expectedQty: existing?.expectedQty ?? ing.stockOnHand,
      countedQty: counted,
      costMicro: Value(existing?.costMicro ?? ing.costMicro),
      note: Value(note ?? existing?.note),
      at: at ?? SatClock.now(),
    );
    await db.into(db.stockCountLines).insertOnConflictUpdate(line);
    return (db.select(db.stockCountLines)
          ..where((l) => l.id.equals(line.id.value)))
        .getSingleOrNull();
  });
}

/// Drop a line from an open session — the counter counted the wrong shelf.
Future<void> removeCountLine(
  AppDatabase db, {
  required String countId,
  required String ingredientId,
}) async {
  final session = await countById(db, countId);
  if (session == null || session.closedAt != null) return;
  await (db.delete(db.stockCountLines)..where(
        (l) => l.countId.equals(countId) & l.ingredientId.equals(ingredientId),
      ))
      .go();
}

/// Abandon an open session and everything in it. A walk that was never
/// finished is not evidence of anything, so it leaves no document — unlike a
/// close, which is permanent.
Future<void> discardCount(AppDatabase db, String countId) async {
  final session = await countById(db, countId);
  if (session == null || session.closedAt != null) return;
  await (db.delete(
    db.stockCountLines,
  )..where((l) => l.countId.equals(countId))).go();
  await (db.delete(db.stockCounts)..where((c) => c.id.equals(countId))).go();
}

/// The result of closing: what moved, and what it was worth.
typedef CloseCountResult = ({
  int lines,
  int movements,
  int varianceValue,
  Map<String, int> deltas,
});

/// Close the session: write one movement per non-zero variance, stamp the
/// header, and post **one** audit row.
///
/// Assumes it is called inside a `db.transaction` — the movements, the header
/// stamp and the audit row are one act, and a partial close would leave stock
/// moved with nothing saying why.
///
/// Returns null if the session is unknown or already closed. Never reopens: the
/// ledger already has the movements, and closing twice would double them.
Future<CloseCountResult?> closeCount(
  AppDatabase db, {
  required String countId,
  String? closedBy,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  final session = await countById(db, countId);
  if (session == null || session.closedAt != null) return null;

  final lines = await countLines(db, countId);
  final when = at ?? SatClock.now();
  final deltas = <String, int>{};
  var varianceValue = 0;
  var movements = 0;

  for (final line in lines) {
    final delta = line.countedQty - line.expectedQty;
    deltas[line.ingredientId] = delta;
    // Valued at the cost frozen on the line, not today's moving average — a
    // session read a year from now reports the rupiah it reported at close.
    varianceValue += valueOf(delta, line.costMicro);
    // A zero-variance line is a fact somebody established and it stays in
    // [StockCountLines]. It writes no movement, because nothing moved.
    if (delta == 0) continue;
    movements++;
    await writeMovement(
      db,
      ingredientId: line.ingredientId,
      delta: delta,
      reason: StockReason.adjust,
      userId: closedBy ?? session.userId,
      sourceLabel: 'Opname',
      note: line.note ?? session.note,
      countId: countId,
      costMicro: line.costMicro,
      at: when,
      id: idPrefix == null ? null : '$idPrefix${_uuid.v4()}',
    );
  }

  await (db.update(db.stockCounts)..where((c) => c.id.equals(countId))).write(
    StockCountsCompanion(
      closedAt: Value(when),
      closedBy: Value(closedBy ?? session.userId),
    ),
  );

  await writeAudit(
    db,
    type: AuditType.stockCounted,
    kind: AuditKind.stockCountClosed,
    params: {
      'lines': '${lines.length}',
      'variance': auditRupiah(varianceValue),
    },
    actorUserId: closedBy ?? session.userId,
    reason: session.note,
    amountCents: varianceValue,
    hub: hub,
    at: at,
    idPrefix: idPrefix,
  );

  return (
    lines: lines.length,
    movements: movements,
    varianceValue: varianceValue,
    deltas: deltas,
  );
}

// ------------------------------------------------------------------- reads

Future<StockCountRow?> countById(AppDatabase db, String id) => (db.select(
  db.stockCounts,
)..where((c) => c.id.equals(id))).getSingleOrNull();

/// The session someone is in the middle of, if any. At most one is open at a
/// time per venue: two overlapping walks would each freeze expectations the
/// other is moving, and neither figure would mean anything.
Future<StockCountRow?> openCountSession(AppDatabase db) =>
    (db.select(db.stockCounts)
          ..where((c) => c.closedAt.isNull())
          ..orderBy([(c) => OrderingTerm.desc(c.startedAt)])
          ..limit(1))
        .getSingleOrNull();

Future<List<StockCountLineRow>> countLines(AppDatabase db, String countId) =>
    (db.select(db.stockCountLines)
          ..where((l) => l.countId.equals(countId))
          ..orderBy([(l) => OrderingTerm.asc(l.at)]))
        .get();

/// Closed sessions, newest first — the archive `/opname` lists.
Future<List<StockCountRow>> listCounts(
  AppDatabase db, {
  DateTime? from,
  DateTime? to,
  int limit = 100,
}) {
  final q = db.select(db.stockCounts)
    ..where((c) => c.closedAt.isNotNull())
    ..orderBy([(c) => OrderingTerm.desc(c.startedAt)])
    ..limit(limit);
  if (from != null) q.where((c) => c.startedAt.isBiggerOrEqualValue(from));
  if (to != null) q.where((c) => c.startedAt.isSmallerThanValue(to));
  return q.get();
}

// -------------------------------------------------------------- wire shape

/// `full` asserts every active bahan was seen; `partial` claims nothing.
/// Persisted in `stock_counts.scope` — **never rename a value**, same rule as
/// [AuditKind] and `CashEntryKind`.
enum StockCountScope { full, partial }

StockCountScope stockCountScopeFromKey(String? key) => StockCountScope.values
    .firstWhere((s) => s.name == key, orElse: () => StockCountScope.partial);

Map<String, dynamic> countRowToJson(
  StockCountRow c, {
  List<StockCountLineRow>? lines,
  Map<String, String> names = const {},
  Map<String, String> units = const {},
}) => {
  'id': c.id,
  'userId': c.userId,
  'closedBy': c.closedBy,
  'scope': c.scope,
  'blind': c.blind,
  'note': c.note,
  'startedAt': c.startedAt.toIso8601String(),
  'closedAt': c.closedAt?.toIso8601String(),
  if (lines != null) ...{
    'lines': [
      for (final l in lines)
        countLineRowToJson(l, name: names[l.ingredientId], unit: units[l.ingredientId]),
    ],
    'lineCount': lines.length,
    'varianceValue': lines.fold<int>(
      0,
      (a, l) => a + valueOf(l.countedQty - l.expectedQty, l.costMicro),
    ),
  },
};

/// [name] and [unit] ride the line because a document must render without the
/// bahan still existing — the same reason `sourceLabel` is frozen on a movement.
Map<String, dynamic> countLineRowToJson(
  StockCountLineRow l, {
  String? name,
  String? unit,
}) => {
  'id': l.id,
  'ingredientId': l.ingredientId,
  'name': name,
  'unit': unit,
  'expectedQty': l.expectedQty,
  'countedQty': l.countedQty,
  'variance': l.countedQty - l.expectedQty,
  'costMicro': l.costMicro,
  'value': valueOf(l.countedQty - l.expectedQty, l.costMicro),
  'note': l.note,
  'at': l.at.toIso8601String(),
};
