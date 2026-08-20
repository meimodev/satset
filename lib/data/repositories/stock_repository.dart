import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/domain/models/ingredient.dart';
import 'package:satset/domain/models/stock_count.dart';

/// Client access to ingredient stock.
///
/// Deliberately **fetch-on-demand**, not a live-synced cache: only derived
/// habis flags ride the broadcast menu snapshot. Bahan detail is needed by one
/// screen, opened occasionally, by one or two people — caching it would buy
/// nothing and reintroduce the mid-service broadcast storm the flip-only rule
/// exists to prevent (ADR-0040).
class StockApi {
  StockApi(this.ref);
  final Ref ref;

  ApiClient get _api => ref.read(apiClientProvider);
  bool get _paired => ref.read(apiConfigProvider) != null;

  Future<List<Ingredient>> ingredients() async {
    if (!_paired) return const [];
    final raw = await _api.getJson('/stock/ingredients');
    return [
      for (final i in (raw as List))
        Ingredient.fromJson((i as Map).cast<String, dynamic>()),
    ];
  }

  Future<Ingredient> save(Ingredient ing, {int openingStock = 0}) async {
    SatLog.repo('stock.save ${ing.name}');
    final raw = await _api.postJson('/stock/ingredients', {
      ...ing.toJson(),
      if (openingStock != 0) 'stockOnHand': openingStock,
    });
    return Ingredient.fromJson((raw as Map).cast<String, dynamic>());
  }

  Future<void> archive(String id) async {
    SatLog.repo('stock.archive $id');
    await _api.deleteJson('/stock/ingredients/$id');
  }

  Future<List<StockMovement>> movements(String id, {int limit = 100}) async {
    if (!_paired) return const [];
    final raw = await _api.getJson(
      '/stock/ingredients/$id/movements?limit=$limit',
    );
    return [
      for (final m in (raw as List))
        StockMovement.fromJson((m as Map).cast<String, dynamic>()),
    ];
  }

  /// [unitPrice] is money per *display* unit (rupiah per kg); omit to receive
  /// without re-pricing the moving average.
  Future<void> receive({
    required String ingredientId,
    required int qty,
    int? unitPrice,
    String? supplier,
    String? note,
  }) async {
    SatLog.repo('stock.receive $ingredientId +$qty');
    await _api.postJson('/stock/receive', {
      'ingredientId': ingredientId,
      'qty': qty,
      'unitPrice': ?unitPrice,
      'supplier': ?supplier,
      'note': ?note,
    });
  }

  /// "Buang" — bin a bahan directly, or one portion of a menu item by
  /// exploding its resep. Returns the money value destroyed.
  Future<int> waste({
    String? ingredientId,
    String? itemId,
    String? variantId,
    required int qty,
    String? note,
  }) async {
    SatLog.repo('stock.waste ${ingredientId ?? itemId} x$qty');
    final raw = await _api.postJson('/stock/waste', {
      'ingredientId': ?ingredientId,
      'itemId': ?itemId,
      'variantId': ?variantId,
      'qty': qty,
      'note': ?note,
    });
    return ((raw as Map)['value'] as num?)?.toInt() ?? 0;
  }

  // ------------------------------------------------------------ stok opname
  //
  // A session, not a burst of adjustments (ADR-0096). Counts are **absolute**
  // at every step — the server derives the variance and freezes the
  // expectation at the moment a line is entered.

  /// The archive plus whatever session is open right now.
  Future<({List<StockCount> counts, StockCount? open})> counts({
    DateTime? from,
    DateTime? to,
  }) async {
    if (!_paired) return (counts: const <StockCount>[], open: null);
    final q = <String>[
      if (from != null) 'from=${from.toIso8601String()}',
      if (to != null) 'to=${to.toIso8601String()}',
    ].join('&');
    final raw =
        await _api.getJson('/stock/counts${q.isEmpty ? '' : '?$q'}') as Map;
    final open = raw['open'];
    return (
      counts: [
        for (final c in (raw['counts'] as List? ?? const []))
          StockCount.fromJson((c as Map).cast<String, dynamic>()),
      ],
      open: open == null
          ? null
          : StockCount.fromJson((open as Map).cast<String, dynamic>()),
    );
  }

  /// One session as a document — every line, including the ones found correct.
  Future<StockCount> count(String id) async {
    final raw = await _api.getJson('/stock/counts/$id');
    return StockCount.fromJson((raw as Map).cast<String, dynamic>());
  }

  Future<StockCount> openCount({
    StockCountScopeKind scope = StockCountScopeKind.partial,
    bool blind = true,
    String? note,
  }) async {
    SatLog.repo('stock.opname.open ${scope.name}${blind ? ' blind' : ''}');
    final raw = await _api.postJson('/stock/counts', {
      'scope': scope.name,
      'blind': blind,
      'note': ?note,
    });
    return StockCount.fromJson((raw as Map).cast<String, dynamic>());
  }

  Future<StockCountLine> countLine(
    String countId, {
    required String ingredientId,
    required int counted,
    String? note,
  }) async {
    final raw = await _api.putJson('/stock/counts/$countId/lines', {
      'ingredientId': ingredientId,
      'counted': counted,
      'note': ?note,
    });
    return StockCountLine.fromJson((raw as Map).cast<String, dynamic>());
  }

  Future<void> removeCountLine(String countId, String ingredientId) =>
      _api.deleteJson('/stock/counts/$countId/lines/$ingredientId');

  /// Abandon an open walk. Leaves no document — an unfinished count is not
  /// evidence of anything.
  Future<void> discardCount(String countId) async {
    SatLog.repo('stock.opname.discard $countId');
    await _api.deleteJson('/stock/counts/$countId');
  }

  Future<StockCount> closeCount(String countId) async {
    SatLog.repo('stock.opname.close $countId');
    final raw = await _api.postJson('/stock/counts/$countId/close', const {});
    return StockCount.fromJson((raw as Map).cast<String, dynamic>());
  }

  Future<void> produce(String ingredientId, int batches, {String? note}) async {
    SatLog.repo('stock.produce $ingredientId ×$batches');
    await _api.postJson('/stock/produce', {
      'ingredientId': ingredientId,
      'batches': batches,
      'note': ?note,
    });
  }

  Future<ItemRecipes> recipes(String itemId, {String kind = 'item'}) async {
    if (!_paired) return const ItemRecipes();
    final raw = await _api.getJson('/stock/recipes/$itemId?kind=$kind');
    return ItemRecipes.fromJson((raw as Map).cast<String, dynamic>());
  }

  Future<void> saveRecipes(
    String itemId,
    ItemRecipes recipes, {
    String kind = 'item',
  }) async {
    SatLog.repo('stock.recipes.save $itemId');
    await _api.putJson('/stock/recipes/$itemId?kind=$kind', recipes.toJson());
  }

  Future<Map<String, dynamic>> report({DateTime? from, DateTime? to}) async {
    if (!_paired) return const {};
    final q = <String>[
      if (from != null) 'from=${from.toIso8601String()}',
      if (to != null) 'to=${to.toIso8601String()}',
    ].join('&');
    final raw = await _api.getJson('/stock/report${q.isEmpty ? '' : '?$q'}');
    return (raw as Map).cast<String, dynamic>();
  }
}

final stockApiProvider = Provider<StockApi>(StockApi.new);

/// The bahan list, re-fetched whenever the stock screen is opened.
final ingredientsProvider = FutureProvider.autoDispose<List<Ingredient>>(
  (ref) => ref.read(stockApiProvider).ingredients(),
);

/// One item's recipes, for the menu item editor.
final itemRecipesProvider = FutureProvider.autoDispose
    .family<ItemRecipes, String>(
      (ref, itemId) => ref.read(stockApiProvider).recipes(itemId),
    );

final stockMovementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, String>(
      (ref, id) => ref.read(stockApiProvider).movements(id),
    );

/// The opname archive, keyed by the screen's ISO range so it re-fetches with
/// the range chip rather than carrying a second, drifting picker — the shape
/// `stockReportProvider` already uses.
final stockCountsProvider = FutureProvider.autoDispose
    .family<({List<StockCount> counts, StockCount? open}), (String, String)>(
      (ref, range) => ref
          .read(stockApiProvider)
          .counts(
            from: DateTime.tryParse(range.$1),
            to: DateTime.tryParse(range.$2),
          ),
    );

/// One session's document.
final stockCountProvider = FutureProvider.autoDispose.family<StockCount, String>(
  (ref, id) => ref.read(stockApiProvider).count(id),
);
