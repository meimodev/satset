import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/ui/features/menu/view_models/cart_view_model.dart';

class AvailableCartLine {
  final int maxQty;
  final String? reason;
  final List<String> ingredients;

  const AvailableCartLine({
    required this.maxQty,
    this.reason,
    this.ingredients = const [],
  });

  bool blocks(CartItem line) =>
      reason == 'sold_out' ||
      reason == 'configuration_changed' ||
      (line.qty > maxQty && line.stockOverrideReason.isEmpty);
}

class CartAvailability {
  final bool stale;
  final Map<String, AvailableCartLine> lines;

  const CartAvailability({this.stale = false, this.lines = const {}});

  bool blocks(List<CartItem> cart) =>
      cart.any((line) => lines[line.id]?.blocks(line) ?? false);
}

/// A small invalidation; menu snapshots still refresh only on a sold-out flip.
class _StockRevision extends StateNotifier<int> {
  _StockRevision(Ref ref) : super(0) {
    _sub = ref.read(wsClientProvider).events.listen((event) {
      if (event.type == WsEventTypes.stockChanged ||
          event.type == WsEventTypes.menuUpdated ||
          event.type == WsEventTypes.connected) {
        state++;
      }
    });
  }

  late final StreamSubscription<WsEventDto> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _stockRevisionProvider = StateNotifierProvider<_StockRevision, int>(
  (ref) => _StockRevision(ref),
);

/// Fetches the host's exact recipe coverage for all lines in cart order.
Future<CartAvailability> fetchCartAvailability(
  ApiClient api,
  List<CartItem> cart,
) async {
  if (cart.isEmpty) return const CartAvailability();
  final raw =
      await api.postJson('/menu/availability', {
            'lines': [
              for (final line in cart)
                {
                  'id': line.id,
                  'itemId': line.itemId,
                  'variantId': line.variantId,
                  'optionIds': [
                    for (final m in line.selectedModifiers) m.optionId,
                  ],
                  'qty': line.qty,
                },
            ],
          })
          as Map<String, dynamic>;
  return CartAvailability(
    lines: {
      for (final value in raw['lines'] as List)
        if (value is Map<String, dynamic>)
          value['id'] as String: AvailableCartLine(
            maxQty: (value['maxQty'] as num).toInt(),
            reason: value['reason'] as String?,
            ingredients: (value['ingredients'] as List? ?? const [])
                .whereType<String>()
                .toList(),
          ),
    },
  );
}

final cartAvailabilityProvider = FutureProvider.autoDispose
    .family<CartAvailability, String>((ref, tableId) async {
      final cart = ref.watch(cartProvider(tableId));
      if (ref.watch(wsConnStateProvider) != WsConnState.open) {
        return const CartAvailability(stale: true);
      }
      ref.watch(_stockRevisionProvider);
      try {
        return await fetchCartAvailability(ref.read(apiClientProvider), cart);
      } catch (_) {
        return const CartAvailability(stale: true);
      }
    });
