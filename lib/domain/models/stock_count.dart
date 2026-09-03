/// A stok opname — the counting session an inventory manager files, and the
/// lines inside it. See §Opname (Stocktake) in CONTEXT.md and ADR-0096.
///
/// Plain Dart and hand-rolled JSON, like [[Ingredient]] beside it: these cross
/// the wire from the venue's own server, not from an API anyone else defines.
library;

/// Whether a session claims to have seen *every* active bahan.
///
/// Persisted in `stock_counts.scope` — **never rename a value**, same rule as
/// `AuditKind` and `CashEntryKind`.
enum StockCountScopeKind { full, partial }

StockCountScopeKind stockCountScopeFrom(String? key) =>
    StockCountScopeKind.values.firstWhere(
      (s) => s.name == key,
      orElse: () => StockCountScopeKind.partial,
    );

class StockCountLine {
  final String id;
  final String ingredientId;

  /// Frozen on the line, so a document renders after the bahan is archived.
  final String? name;
  final String? unit;

  /// What the shelf claimed **when this line was entered**, not at close.
  final int expectedQty;
  final int countedQty;

  /// Signed, in milli-base units. Zero is a real answer, not a missing one.
  final int variance;

  /// Unit cost frozen at entry, and the variance valued at it.
  final int costMicro;
  final int value;
  final String? note;
  final DateTime at;

  const StockCountLine({
    required this.id,
    required this.ingredientId,
    this.name,
    this.unit,
    required this.expectedQty,
    required this.countedQty,
    required this.variance,
    required this.costMicro,
    required this.value,
    this.note,
    required this.at,
  });

  static int _int(Object? v) => (v as num?)?.toInt() ?? 0;

  factory StockCountLine.fromJson(Map<String, dynamic> j) => StockCountLine(
    id: j['id'] as String,
    ingredientId: j['ingredientId'] as String,
    name: j['name'] as String?,
    unit: j['unit'] as String?,
    expectedQty: _int(j['expectedQty']),
    countedQty: _int(j['countedQty']),
    variance: _int(j['variance']),
    costMicro: _int(j['costMicro']),
    value: _int(j['value']),
    note: j['note'] as String?,
    at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
  );
}

class StockCount {
  final String id;
  final String? userId;
  final String? closedBy;

  /// Who walked it and who filed it, by name. Frozen server-side at write, so
  /// a document renders after a rename — the same reason a line carries the
  /// bahan's [StockCountLine.name]. Null on a session opened before v70.
  final String? userName;
  final String? closedByName;
  final StockCountScopeKind scope;

  /// Whether the expected number was hidden while counting. Rendered on the
  /// document because it decides how much the variance is worth.
  final bool blind;
  final String? note;
  final DateTime startedAt;

  /// Null while the session is open.
  final DateTime? closedAt;

  /// Empty on a list row that was fetched without them.
  final List<StockCountLine> lines;
  final int lineCount;
  final int varianceValue;

  const StockCount({
    required this.id,
    this.userId,
    this.closedBy,
    this.userName,
    this.closedByName,
    required this.scope,
    required this.blind,
    this.note,
    required this.startedAt,
    this.closedAt,
    this.lines = const [],
    this.lineCount = 0,
    this.varianceValue = 0,
  });

  bool get isOpen => closedAt == null;

  /// A line the counter has already entered, if any — what the walk UI checks
  /// to know whether a bahan is done.
  StockCountLine? lineFor(String ingredientId) {
    for (final l in lines) {
      if (l.ingredientId == ingredientId) return l;
    }
    return null;
  }

  factory StockCount.fromJson(Map<String, dynamic> j) {
    final lines = [
      for (final l in (j['lines'] as List? ?? const []))
        StockCountLine.fromJson((l as Map).cast<String, dynamic>()),
    ];
    return StockCount(
      id: j['id'] as String,
      userId: j['userId'] as String?,
      closedBy: j['closedBy'] as String?,
      userName: j['userName'] as String?,
      closedByName: j['closedByName'] as String?,
      scope: stockCountScopeFrom(j['scope'] as String?),
      blind: j['blind'] as bool? ?? true,
      note: j['note'] as String?,
      startedAt:
          DateTime.tryParse(j['startedAt'] as String? ?? '') ?? DateTime.now(),
      closedAt: DateTime.tryParse(j['closedAt'] as String? ?? ''),
      lines: lines,
      lineCount: (j['lineCount'] as num?)?.toInt() ?? lines.length,
      varianceValue: (j['varianceValue'] as num?)?.toInt() ?? 0,
    );
  }
}
