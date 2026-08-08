import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/audit_entry.dart';

final auditStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

/// The signed-in user's own audit rows for their current shift — the feed and
/// the integrity counters behind the "Saya" tab. Scoped by the **server** from
/// the bearer (ADR-0065); the client never asks for a particular user's log.
///
/// Because the cache is per-user, it is dropped and refetched whenever the
/// signed-in user changes. Handsets are shared, so without that the next person
/// to PIN in would inherit the previous waiter's voids.
class AuditRepository extends StateNotifier<List<AuditEntry>> {
  AuditRepository(this._ref) : super(const <AuditEntry>[]) {
    Future.microtask(_bootstrap);
    _ref.listen<String?>(authStateProvider.select((s) => s.user?.id), (
      prev,
      next,
    ) {
      if (prev == next) return;
      state = const <AuditEntry>[];
      Future.microtask(_bootstrap);
    });
  }

  final Ref _ref;
  StreamSubscription? _wsSub;

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final cfg = _ref.read(apiConfigProvider);
    if (cfg == null) {
      _ref.read(auditStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
      return;
    }
    _ref.read(auditStatusProvider.notifier).state = const AsyncValue.loading();
    try {
      final raw = await _ref.read(apiClientProvider).getJson('/audit') as List;
      state = [
        for (final e in raw) _fromJson((e as Map).cast<String, dynamic>()),
      ];
      SatLog.repo('audit.loaded n=${state.length}');
      _ref.read(auditStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
      _wireWs();
    } catch (e, st) {
      SatLog.repo('audit.bootstrap fail $e');
      _ref.read(auditStatusProvider.notifier).state = AsyncValue.error(e, st);
    }
  }

  void _wireWs() {
    if (_wsSub != null) return;
    _wsSub = _ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type != WsEventTypes.auditCreated) return;
      final e = _fromJson(ev.payload);
      // `GET /audit` hands us only our own rows, but the WS fan-out is
      // venue-wide — without this filter the first colleague to void an item
      // would land in our feed and inflate our integrity counters.
      final meId = _ref.read(authStateProvider).user?.id;
      if (meId == null || e.actorUserId != meId) return;
      if (state.any((x) => x.id == e.id)) return;
      state = [e, ...state];
    });
  }

  AuditEntry _fromJson(Map<String, dynamic> j) => auditEntryFromJson(j);
}

/// One decoder for both audit feeds — the personal one here and the venue log
/// in [VenueAuditRepository]. They read the same wire shape, and a screen that
/// decoded `amountCents` differently from the one beside it would show two
/// different rupiah for the same void.
AuditEntry auditEntryFromJson(Map<String, dynamic> j) => AuditEntry(
  id: j['id'] as String,
  type: AuditType.values.firstWhere(
    (t) => t.name == (j['type'] as String? ?? ''),
    orElse: () => AuditType.modify,
  ),
  title: (j['title'] as String?) ?? '',
  tableId: (j['tableId'] as String?) ?? '',
  when: (j['at'] as String?) ?? '',
  approvedBy: j['approvedBy'] as String?,
  reason: j['reason'] as String?,
  actorUserId: j['actorUserId'] as String?,
  amountCents: (j['amountCents'] as num?)?.toInt(),
  actorName: j['actorName'] as String?,
  actorRoleName: j['actorRoleName'] as String?,
  kind: j['kind'] as String?,
  params: switch (j['params']) {
    final Map<String, dynamic> m => {
      for (final e in m.entries) e.key: '${e.value}',
    },
    _ => const {},
  },
);

final auditProvider = StateNotifierProvider<AuditRepository, List<AuditEntry>>(
  (ref) => AuditRepository(ref),
);
