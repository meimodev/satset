import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/audit_entry.dart';

final auditStatusProvider =
    StateProvider<AsyncValue<void>>((_) => const AsyncValue.data(null));

class AuditRepository extends StateNotifier<List<AuditEntry>> {
  AuditRepository(this._ref) : super(const <AuditEntry>[]) {
    Future.microtask(_bootstrap);
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
      _ref.read(auditStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    _ref.read(auditStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      final raw = await _ref.read(apiClientProvider).getJson('/audit') as List;
      state = [
        for (final e in raw) _fromJson((e as Map).cast<String, dynamic>()),
      ];
      SatLog.repo('audit.loaded n=${state.length}');
      _ref.read(auditStatusProvider.notifier).state =
          const AsyncValue.data(null);
      _wireWs();
    } catch (e, st) {
      SatLog.repo('audit.bootstrap fail $e');
      _ref.read(auditStatusProvider.notifier).state =
          AsyncValue.error(e, st);
    }
  }

  void _wireWs() {
    if (_wsSub != null) return;
    _wsSub = _ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type != WsEventTypes.auditCreated) return;
      final e = _fromJson(ev.payload);
      if (state.any((x) => x.id == e.id)) return;
      state = [e, ...state];
    });
  }

  AuditEntry _fromJson(Map<String, dynamic> j) {
    return AuditEntry(
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
    );
  }

  void add(AuditEntry e) {
    // Optimistic insert. Server WS broadcasts to all peers including us,
    // but duplicate guards above swallow our own echo.
    state = [e, ...state];
    final cfg = _ref.read(apiConfigProvider);
    if (cfg == null) return;
    unawaited(() async {
      try {
        await _ref.read(apiClientProvider).postJson('/audit', {
          'id': e.id,
          'type': e.type.name,
          'title': e.title,
          'tableId': e.tableId.isEmpty ? null : e.tableId,
          'at': e.when,
          'approvedBy': e.approvedBy,
          'reason': e.reason,
        });
      } catch (err) {
        SatLog.repo('audit.add fail $err');
        state = state.where((x) => x.id != e.id).toList();
      }
    }());
  }
}

final auditProvider = StateNotifierProvider<AuditRepository, List<AuditEntry>>(
    (ref) => AuditRepository(ref));
