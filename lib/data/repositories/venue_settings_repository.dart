import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';

final venueSettingsStatusProvider =
    StateProvider<AsyncValue<void>>((_) => const AsyncValue.data(null));

class VenueSettingsRepository extends StateNotifier<VenueSettingsDto> {
  VenueSettingsRepository({required this.ref})
      : super(const VenueSettingsDto()) {
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(venueSettingsStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    ref.read(venueSettingsStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      final raw = await ref.read(apiClientProvider).getJson('/venue/settings');
      final dto =
          VenueSettingsDto.fromJson((raw as Map).cast<String, dynamic>());
      state = dto;
      ref.read(venueSettingsStatusProvider.notifier).state =
          const AsyncValue.data(null);
    } catch (e, st) {
      SatLog.repo('venueSettings.bootstrap fail $e');
      ref.read(venueSettingsStatusProvider.notifier).state =
          AsyncValue.error(e, st);
    }
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type != WsEventTypes.venueSettingsUpdated) return;
      try {
        state = VenueSettingsDto.fromJson(ev.payload);
        SatLog.repo('venueSettings.ws update');
      } catch (e) {
        SatLog.repo('venueSettings.ws decode fail $e');
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> patch({
    String? displayName,
    String? legalName,
    String? address,
    String? phone,
    String? receiptHeader,
    String? receiptFooter,
    bool? taxEnabled,
    int? taxRateBps,
    bool? serviceEnabled,
    String? serviceMode,
    int? serviceRateBps,
    int? serviceFixedAmount,
  }) async {
    final prev = state;
    state = state.copyWith(
      displayName: displayName ?? state.displayName,
      legalName: legalName ?? state.legalName,
      address: address ?? state.address,
      phone: phone ?? state.phone,
      receiptHeader: receiptHeader ?? state.receiptHeader,
      receiptFooter: receiptFooter ?? state.receiptFooter,
      taxEnabled: taxEnabled ?? state.taxEnabled,
      taxRateBps: taxRateBps ?? state.taxRateBps,
      serviceEnabled: serviceEnabled ?? state.serviceEnabled,
      serviceMode: serviceMode ?? state.serviceMode,
      serviceRateBps: serviceRateBps ?? state.serviceRateBps,
      serviceFixedAmount: serviceFixedAmount ?? state.serviceFixedAmount,
    );
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final body = <String, dynamic>{
        'displayName': ?displayName,
        'legalName': ?legalName,
        'address': ?address,
        'phone': ?phone,
        'receiptHeader': ?receiptHeader,
        'receiptFooter': ?receiptFooter,
        'taxEnabled': ?taxEnabled,
        'taxRateBps': ?taxRateBps,
        'serviceEnabled': ?serviceEnabled,
        'serviceMode': ?serviceMode,
        'serviceRateBps': ?serviceRateBps,
        'serviceFixedAmount': ?serviceFixedAmount,
      };
      final raw = await ref
          .read(apiClientProvider)
          .patchJson('/venue/settings', body);
      state =
          VenueSettingsDto.fromJson((raw as Map).cast<String, dynamic>());
    } catch (e) {
      SatLog.repo('venueSettings.patch fail $e');
      state = prev;
      rethrow;
    }
  }
}

final venueSettingsProvider =
    StateNotifierProvider<VenueSettingsRepository, VenueSettingsDto>(
        (ref) => VenueSettingsRepository(ref: ref));
