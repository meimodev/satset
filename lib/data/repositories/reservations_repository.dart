import 'dart:async';
import 'package:satset/core/time/sat_clock.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/reservation_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/reservation.dart';

final reservationsStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

class ReservationsRepository extends StateNotifier<List<Reservation>> {
  ReservationsRepository({required this.ref}) : super(const []) {
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(reservationsStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    ref.read(reservationsStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      // Window: yesterday → +14 days; covers the reservation card on tables
      // screen which only shows today + near future.
      final now = SatClock.now();
      final from = DateTime(now.year, now.month, now.day - 1);
      final to = DateTime(now.year, now.month, now.day + 14);
      final raw = await ref
          .read(apiClientProvider)
          .getJson(
            '/reservations',
            query: {'from': from.toIso8601String(), 'to': to.toIso8601String()},
          );
      final list = (raw as List)
          .cast<Map>()
          .map((m) => ReservationDto.fromJson(m.cast<String, dynamic>()))
          .map(_toDomain)
          .toList();
      state = list;
      ref.read(reservationsStatusProvider.notifier).state =
          const AsyncValue.data(null);
      SatLog.repo('reservations.loaded n=${list.length}');
    } catch (e, st) {
      SatLog.repo('reservations.bootstrap fail $e');
      ref.read(reservationsStatusProvider.notifier).state = AsyncValue.error(
        e,
        st,
      );
    }
    _wsSub ??= ref.read(wsClientProvider).events.listen(_onEvent);
  }

  void _onEvent(WsEventDto ev) {
    switch (ev.type) {
      case WsEventTypes.reservationCreated:
      case WsEventTypes.reservationUpdated:
        final dto = ReservationDto.fromJson(ev.payload);
        final domain = _toDomain(dto);
        final next = [...state];
        final idx = next.indexWhere((r) => r.id == domain.id);
        if (idx == -1) {
          next.add(domain);
        } else {
          next[idx] = domain;
        }
        next.sort((a, b) => a.expectedAt.compareTo(b.expectedAt));
        state = next;
      case WsEventTypes.reservationDeleted:
        final id = ev.payload['id'] as String?;
        if (id == null) return;
        state = [
          for (final r in state)
            if (r.id != id) r,
        ];
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Reservation _toDomain(ReservationDto d) => Reservation(
    id: d.id,
    name: d.name,
    phone: d.phone,
    partySize: d.partySize,
    expectedAt: d.expectedAt,
    status: reservationStatusFromKey(d.status),
    zoneId: d.zoneId,
    tableId: d.tableId,
    notes: d.notes,
    memberId: d.memberId,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  );

  Future<void> create({
    required String name,
    String? phone,
    required int partySize,
    required DateTime expectedAt,
    String? zoneId,
    String? tableId,
    String? notes,
    String? memberId,
  }) async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    final body = <String, dynamic>{
      'name': name,
      'phone': ?phone,
      'partySize': partySize,
      'expectedAt': expectedAt.toIso8601String(),
      'zoneId': ?zoneId,
      'tableId': ?tableId,
      'notes': ?notes,
      'memberId': ?memberId,
    };
    final raw = await ref
        .read(apiClientProvider)
        .postJson('/reservations', body);
    final dto = ReservationDto.fromJson((raw as Map).cast<String, dynamic>());
    final domain = _toDomain(dto);
    state = [
      for (final r in state)
        if (r.id != domain.id) r,
      domain,
    ]..sort((a, b) => a.expectedAt.compareTo(b.expectedAt));
  }

  Future<void> updateStatus(String id, ReservationStatus status) async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    final raw = await ref.read(apiClientProvider).patchJson(
      '/reservations/$id',
      {'status': reservationStatusKey(status)},
    );
    final dto = ReservationDto.fromJson((raw as Map).cast<String, dynamic>());
    final domain = _toDomain(dto);
    state = [for (final r in state) r.id == id ? domain : r];
  }

  Future<void> assignTable(String id, {String? zoneId, String? tableId}) async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    final raw = await ref.read(apiClientProvider).patchJson(
      '/reservations/$id',
      {'zoneId': ?zoneId, 'tableId': ?tableId},
    );
    final dto = ReservationDto.fromJson((raw as Map).cast<String, dynamic>());
    final domain = _toDomain(dto);
    state = [for (final r in state) r.id == id ? domain : r];
  }

  Future<void> delete(String id) async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      await ref.read(apiClientProvider).deleteJson('/reservations/$id');
      state = [
        for (final r in state)
          if (r.id != id) r,
      ];
    } catch (e) {
      SatLog.repo('reservations.delete fail $e');
      rethrow;
    }
  }
}

final reservationsRepositoryProvider =
    StateNotifierProvider<ReservationsRepository, List<Reservation>>(
      (ref) => ReservationsRepository(ref: ref),
    );
