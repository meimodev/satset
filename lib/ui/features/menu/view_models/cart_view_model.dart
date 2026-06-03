import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
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
/// For a table-less draft (menu-first / takeaway) the family key is a
/// transient [draftOrderIdProvider] uuid instead of a tableId.
final cartProvider = StateNotifierProvider.family<CartViewModel, List<CartItem>,
    String>((ref, tableId) => CartViewModel());

/// Holds the id of the in-progress table-less draft order so the menu and
/// review screens share one [cartProvider] key. Reset via [startNewDraft]
/// each time the waiter taps "Pesanan baru" so a fresh cart is minted.
final draftOrderIdProvider =
    StateProvider<String>((ref) => const Uuid().v4());

/// Mint a fresh draft id (drops any stale cart bound to the previous id)
/// and return it. Call before pushing into the menu-first / takeaway flow.
String startNewDraft(WidgetRef ref) {
  final id = const Uuid().v4();
  ref.read(draftOrderIdProvider.notifier).state = id;
  return id;
}
