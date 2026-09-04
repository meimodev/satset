import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/visit_expense_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/send_queue_service.dart';
import 'package:satset/data/services/settlement_sync.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/ws_client.dart';

/// The [[Pengeluaran kunjungan]] category catalogue (ADR-0130), cached on every
/// paired device.
///
/// Cached and **warmed at `AppShell`** for the reason ADR-0128 records against
/// the [[Preset diskon]] catalogue: a lazy repository's first watch is the
/// waiter opening the sheet, and on a dark handset that fetch fails and the
/// sheet says the venue authored no categories — on the one screen the feature
/// exists for. The bug already shipped once; this is the same shape, so it
/// takes the same treatment.
const _uuid = Uuid();

/// Minted client-side, online too, and doubling as the idempotency key — the
/// [[Antrean kirim]] replays under it, so a request that timed out after the
/// server committed reads back the stored response rather than posting the
/// photo twice (ADR-0123's rule, ADR-0130's use of it).
String newExpenseId() => _uuid.v4();

final expenseCategoriesStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

class ExpenseCategoriesRepository
    extends StateNotifier<List<VisitExpenseCategoryDto>> {
  ExpenseCategoriesRepository({required this.ref})
    : super(const <VisitExpenseCategoryDto>[]) {
    // Synchronously, not in the microtask: a widget's first build reads state
    // before any microtask runs, and the first frame is the one that was wrong.
    _paintCache();
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;

  void _paintCache() {
    final raw = ref
        .read(prefsServiceProvider)
        .valueOrNull
        ?.expenseCategoriesJson();
    if (raw == null) return;
    try {
      _adopt(jsonDecode(raw), persist: false);
    } catch (e) {
      SatLog.repo('expenseCategories cache decode fail $e');
    }
  }

  void _persist() {
    final prefs = ref.read(prefsServiceProvider).valueOrNull;
    if (prefs == null) return;
    unawaited(
      prefs.setExpenseCategoriesJson(
        jsonEncode([for (final c in state) c.toJson()]),
        // Stamped with the certificate it came from, so the cache dies with the
        // certificate and not with the address (ADR-0080, ADR-0128).
        fingerprint: ref.read(apiConfigProvider)?.trustedFingerprint,
      ),
    );
  }

  Future<void> _bootstrap() async {
    // Again, for the cold launch where prefs was still resolving in the
    // constructor — `prefsServiceProvider` is a `FutureProvider`.
    if (state.isEmpty) _paintCache();
    await refresh();
    if (!mounted) return;
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      switch (ev.type) {
        case WsEventTypes.expenseCategoriesUpdated:
          _adopt(ev.payload['categories']);
        // Refetch on reconnect rather than trusting the cache (ADR-0021): a
        // category renamed while this device was dark is otherwise missed, and
        // the edit broadcast is not a resync.
        // And on a settings change, because the mode key is what makes the
        // route exist at all (ADR-0130): a device that warmed its catalogue
        // while `tableExpense` was off cached the 404's empty list, and would
        // otherwise keep showing "no categories" on the very screen the module
        // was just bought for, until the socket happened to drop. Found on a
        // device — the fleet toggle landed and the sheet stayed empty.
        case WsEventTypes.connected:
        case WsEventTypes.venueSettingsUpdated:
          refresh();
      }
    });
  }

  void _adopt(Object? raw, {bool persist = true}) {
    if (raw is! List) return;
    try {
      state = [
        for (final e in raw)
          VisitExpenseCategoryDto.fromJson((e as Map).cast<String, dynamic>()),
      ];
      if (persist) _persist();
    } catch (e) {
      SatLog.repo('expenseCategories decode fail $e');
    }
  }

  Future<void> refresh() async {
    if (ref.read(apiConfigProvider) == null) {
      ref.read(expenseCategoriesStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    ref.read(expenseCategoriesStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      final raw =
          await ref.read(apiClientProvider).getJson('/expense-categories')
              as Map;
      _adopt(raw['categories']);
      ref.read(expenseCategoriesStatusProvider.notifier).state =
          const AsyncValue.data(null);
    } catch (e, st) {
      // A 404 here is the venue not doing this at all, which is not an error —
      // the affordance is already hidden by `tableExpenseOn`, and the cache
      // stays as it was rather than being wiped by a feature being switched off
      // mid-shift.
      SatLog.repo('expenseCategories.refresh fail $e');
      ref.read(expenseCategoriesStatusProvider.notifier).state =
          AsyncValue.error(e, st);
    }
  }

  Future<void> save({
    String? id,
    required String name,
    bool? active,
    int? sortOrder,
  }) async {
    final api = ref.read(apiClientProvider);
    final body = {
      'name': name,
      'active': ?active,
      'sortOrder': ?sortOrder,
    };
    // POST mints, PATCH edits — the shape the preset catalogue uses, so the
    // server can tell "a new category called Tisu" from "rename this one".
    final raw = id == null
        ? await api.postJson('/expense-categories', body)
        : await api.patchJson('/expense-categories/$id', body);
    if (raw is! Map) return;
    final c = VisitExpenseCategoryDto.fromJson(raw.cast<String, dynamic>());
    state = [
      for (final x in state)
        if (x.id != c.id) x,
      c,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _persist();
  }

  /// What a picker may offer: active only, in the owner's order.
  List<VisitExpenseCategoryDto> get pickable =>
      [for (final c in state) if (c.active) c]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}

final expenseCategoriesRepositoryProvider =
    StateNotifierProvider<
      ExpenseCategoriesRepository,
      List<VisitExpenseCategoryDto>
    >((ref) => ExpenseCategoriesRepository(ref: ref));

/// One visit's expenses, fetched when a sheet opens and not held venue-wide.
///
/// Deliberately **not** a `StateNotifier`: this is per-visit and short-lived,
/// and a cached venue-wide list of every visit's expenses would be a second
/// place for the cap's two numbers to be wrong. The cap and the running total
/// come back with the list, from the one place that computes them.
///
/// Falls back to the device when the host cannot be reached: the cap comes from
/// the **cached bill** (ADR-0123's prefetch) and the running total counts what
/// this handset has queued. If there is no cached bill this **throws**, and the
/// sheet refuses the capture — an uncapped offline capture is a cap you defeat
/// by turning off Wi-Fi, which is the one thing a fraud control cannot survive
/// (ADR-0130).
final visitExpensesProvider =
    FutureProvider.family<VisitExpenseSummaryDto, String>((ref, visitId) async {
      try {
        final raw =
            await ref
                    .read(apiClientProvider)
                    .getJson('/visits/$visitId/expenses')
                as Map;
        return VisitExpenseSummaryDto.fromJson(raw.cast<String, dynamic>());
      } catch (_) {
        return offlineVisitExpenseSummary(ref, visitId);
      }
    });

/// What this device can say about a visit's expenses with no host.
///
/// Throws [NoCachedBill] when the bill was never cached — the refusal the sheet
/// renders, rather than a zero cap that would read as "nothing may be spent"
/// or, worse, a missing cap that reads as "anything may be".
Future<VisitExpenseSummaryDto> offlineVisitExpenseSummary(
  Ref ref,
  String visitId,
) async {
  final journal = ref.read(settlementJournalProvider.notifier);
  final bill = await journal.cachedBill(visitId);
  final cap = (bill?['subtotal'] as num?)?.toInt();
  if (cap == null) throw const NoCachedBill();
  final queued = ref
      .read(sendQueueProvider)
      .where(
        (i) =>
            i.kind == SendIntentKind.tableExpense &&
            i.payload['visitId'] == visitId,
      );
  var total = 0;
  for (final i in queued) {
    total += (i.payload['amount'] as num?)?.toInt() ?? 0;
  }
  return VisitExpenseSummaryDto(cap: cap, total: total, offline: true);
}

/// The device has never seen this visit's bill, so it cannot work out a cap.
class NoCachedBill implements Exception {
  const NoCachedBill();
  @override
  String toString() => 'NoCachedBill';
}
