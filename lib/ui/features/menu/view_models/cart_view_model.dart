import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/domain/models/cart_item.dart';

/// Ceiling for one stacked line. The sheet still caps a single add at 20;
/// this is what repeated adds pile into. See ADR-0060.
const int kCartLineMaxQty = 99;

class CartViewModel extends StateNotifier<List<CartItem>> {
  CartViewModel() : super(const []);

  /// Adds [item], folding it into an identical line when one exists rather
  /// than appending a duplicate row (ADR-0060). The surviving line keeps the
  /// older id so a stepper bound to it does not lose its identity mid-edit.
  void add(CartItem item) {
    final i = state.indexWhere((c) => c.sameLineAs(item));
    if (i < 0) {
      SatLog.vm('Cart add ${item.name} qty=${item.qty} → ${state.length + 1}');
      state = [...state, item];
      return;
    }
    final qty = (state[i].qty + item.qty).clamp(1, kCartLineMaxQty);
    SatLog.vm('Cart stack ${item.name} ${state[i].qty}+${item.qty} → $qty');
    state = [...state]..[i] = state[i].copyWith(qty: qty);
  }

  void setQty(String id, int qty) {
    final i = state.indexWhere((c) => c.id == id);
    if (i < 0) return;
    final q = qty.clamp(1, kCartLineMaxQty);
    if (q == state[i].qty) return;
    SatLog.vm('Cart qty ${state[i].name} → $q');
    state = [...state]..[i] = state[i].copyWith(qty: q);
  }

  /// Swaps the line [id] for [updated] (a re-run of the modifier sheet). If
  /// the edit made it identical to another line, the two merge — the cart can
  /// never hold two rows that read the same, however it was reached.
  void replace(String id, CartItem updated) {
    final i = state.indexWhere((c) => c.id == id);
    if (i < 0) return;
    final twin = state.indexWhere((c) => c.id != id && c.sameLineAs(updated));
    if (twin < 0) {
      SatLog.vm('Cart edit ${updated.name} qty=${updated.qty}');
      state = [...state]..[i] = updated.copyWith(id: id);
      return;
    }
    final qty = (state[twin].qty + updated.qty).clamp(1, kCartLineMaxQty);
    SatLog.vm('Cart edit merged ${updated.name} → $qty');
    state = [
      for (var j = 0; j < state.length; j++)
        if (j != i)
          if (j == twin) state[j].copyWith(qty: qty) else state[j],
    ];
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
final cartProvider =
    StateNotifierProvider.family<CartViewModel, List<CartItem>, String>(
      (ref, tableId) => CartViewModel(),
    );

/// Holds the id of the in-progress table-less draft order so the menu and
/// review screens share one [cartProvider] key. Reset via [startNewDraft]
/// each time the waiter taps "Pesanan baru" so a fresh cart is minted.
final draftOrderIdProvider = StateProvider<String>((ref) => const Uuid().v4());

/// Mint a fresh draft id (drops any stale cart bound to the previous id)
/// and return it. Call before pushing into the menu-first / takeaway flow.
String startNewDraft(WidgetRef ref) {
  final id = const Uuid().v4();
  ref.read(draftOrderIdProvider.notifier).state = id;
  return id;
}
