import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/domain/models/ingredient.dart';

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

  /// Stok opname. Counts are **absolute** — the server writes the difference,
  /// and that difference is the variance (ADR-0041).
  Future<Map<String, int>> recordCounts(
    Map<String, int> counted, {
    String? note,
  }) async {
    SatLog.repo('stock.opname ${counted.length} bahan');
    final raw = await _api.postJson('/stock/count', {
      'counts': [
        for (final e in counted.entries)
          {'ingredientId': e.key, 'counted': e.value},
      ],
      'note': ?note,
    });
    final deltas = ((raw as Map)['deltas'] as Map).cast<String, dynamic>();
    return {for (final e in deltas.entries) e.key: (e.value as num).toInt()};
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
