import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/domain/models/ticket.dart';

/// Whether a line is **outstanding** — sent to the kitchen and not yet done.
///
/// Exactly the union of the Pesanan board's **Disiapkan** and **Siap** buckets,
/// named once so the "Saya" tab counts the same lines the board shows. The board
/// itself keeps those two buckets apart and so still enumerates them separately;
/// this is the combined question, which only the shift summary asks.
///
/// Excluded, deliberately:
/// - `draft` — composed but never sent; not the kitchen's problem yet.
/// - `served`, `voided` — done, one way or the other.
bool isOutstandingTicket(TicketStatus s) => switch (s) {
  TicketStatus.sent ||
  TicketStatus.prep ||
  TicketStatus.cooked ||
  TicketStatus.held ||
  TicketStatus.ready => true,
  TicketStatus.draft ||
  TicketStatus.acknowledged ||
  TicketStatus.served ||
  TicketStatus.voided => false,
};

/// Whether a Pesanan board row belongs to the signed-in user (ADR-0056).
///
/// Three ways to own a row, in the order they matter:
///
/// 1. **You handle the table** — `lastActorId`. The primary rule: the board
///    follows the section you are working, not the lines you happened to type.
/// 2. **You authored the line** — `createdBy`. Catches table-less
///    (takeaway) rows, which have no table row to handle, and keeps your
///    outstanding food on screen after a table legitimately moves on.
/// 3. **Nobody owns it** — both null. An unowned live line is exactly the one
///    at risk of being forgotten, so it shows to everyone rather than to
///    no one. Reachable via legacy / offline lines and via `release` /
///    `close`, which null `lastActorId` while lines can still be live.
///
/// With no signed-in user there is nothing to scope against, so everything
/// is "mine" — the board degrades to its old venue-wide self rather than
/// going blank.
bool ownsOrderRow({
  required String? meId,
  required String? createdBy,
  required String? tableActorId,
}) {
  if (meId == null || meId.isEmpty) return true;
  if (tableActorId == meId) return true;
  if (createdBy == meId) return true;
  return createdBy == null && tableActorId == null;
}

/// "Milik saya / Semua" scope for the Pesanan board's Aktif and Selesai
/// buckets. The Siap bucket ignores this — a plate under the lamp is
/// everyone's problem. See ADR-0056.
///
/// Session-scoped rather than device-local: the handsets are shared, so the
/// choice follows the signed-in user and snaps back to mine-only on every PIN
/// sign-in. Deliberately not `autoDispose` — leaving the tab mid-shift should
/// not silently reset a scope you chose on purpose.
class OrdersScopeNotifier extends StateNotifier<bool> {
  OrdersScopeNotifier(this.ref) : super(false) {
    _userId = ref.read(authStateProvider).user?.id;
    ref.listen<String?>(authStateProvider.select((s) => s.user?.id), (_, next) {
      if (next == _userId) return;
      _userId = next;
      state = false;
    });
  }

  final Ref ref;
  String? _userId;

  void set(bool showAll) => state = showAll;
}

/// True when the board is showing the whole venue instead of just your rows.
final ordersShowAllProvider =
    StateNotifierProvider<OrdersScopeNotifier, bool>((ref) {
      return OrdersScopeNotifier(ref);
    });
