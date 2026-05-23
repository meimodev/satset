import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/domain/models/cart_item.dart';

class CartViewModel extends StateNotifier<List<CartItem>> {
  CartViewModel() : super(const []);

  void add(CartItem item) {
    state = [...state, item];
  }

  void remove(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void clear() {
    state = const [];
  }
}

/// Cart is scoped per-table so two open tables do not bleed items.
final cartProvider = StateNotifierProvider.family<CartViewModel, List<CartItem>,
    String>((ref, tableId) => CartViewModel());
