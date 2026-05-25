import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/domain/models/cart_item.dart';

class CartViewModel extends StateNotifier<List<CartItem>> {
  CartViewModel() : super(const []);

  void add(CartItem item) {
    SatLog.vm('Cart add ${item.name} qty=${item.qty} → ${state.length + 1}');
    state = [...state, item];
  }

  void remove(String id) {
    SatLog.vm('Cart remove id=${id.substring(0, id.length.clamp(0, 6))}');
    state = state.where((c) => c.id != id).toList();
  }

  void clear() {
    SatLog.vm('Cart clear was=${state.length}');
    state = const [];
  }
}

/// Cart is scoped per-table so two open tables do not bleed items.
final cartProvider = StateNotifierProvider.family<CartViewModel, List<CartItem>,
    String>((ref, tableId) => CartViewModel());
