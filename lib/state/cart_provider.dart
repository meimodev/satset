import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []);

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

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());
