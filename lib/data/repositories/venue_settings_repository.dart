import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';

final venueSettingsStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

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
      final dto = VenueSettingsDto.fromJson(
        (raw as Map).cast<String, dynamic>(),
      );
      state = dto;
      ref.read(venueSettingsStatusProvider.notifier).state =
          const AsyncValue.data(null);
    } catch (e, st) {
      SatLog.repo('venueSettings.bootstrap fail $e');
      ref.read(venueSettingsStatusProvider.notifier).state = AsyncValue.error(
        e,
        st,
      );
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
    String? receiptTagline,
    String? receiptSocial,
    String? receiptThankYou,
    String? receiptQrUrl,
    String? receiptQrCaption,
    bool? taxEnabled,
    int? taxRateBps,
    bool? serviceEnabled,
    String? serviceMode,
    int? serviceRateBps,
    int? serviceFixedAmount,
    bool? taxAfterDiscount,
    int? businessDayStartHour,
    int? prepTargetMins,
    int? pickupTargetMins,
    int? ungreetedMins,
    int? ungreetedEscalateMins,
    int? longStayMins,
    int? idleTableMins,
    int? reservationGraceMins,
    int? pendingReviewMins,
    bool? ungreetedAlertEnabled,
    bool? pickupAlertEnabled,
    bool? guestOrderingEnabled,
    String? soundNewOrder,
    String? soundReady,
    String? soundVoid,
    String? soundOverdue,
    String? soundUngreeted,
    String? soundPickup,
  }) async {
    final prev = state;
    state = state.copyWith(
      displayName: displayName ?? state.displayName,
      legalName: legalName ?? state.legalName,
      address: address ?? state.address,
      phone: phone ?? state.phone,
      receiptHeader: receiptHeader ?? state.receiptHeader,
      receiptFooter: receiptFooter ?? state.receiptFooter,
      receiptTagline: receiptTagline ?? state.receiptTagline,
      receiptSocial: receiptSocial ?? state.receiptSocial,
      receiptThankYou: receiptThankYou ?? state.receiptThankYou,
      receiptQrUrl: receiptQrUrl ?? state.receiptQrUrl,
      receiptQrCaption: receiptQrCaption ?? state.receiptQrCaption,
      taxEnabled: taxEnabled ?? state.taxEnabled,
      taxRateBps: taxRateBps ?? state.taxRateBps,
      serviceEnabled: serviceEnabled ?? state.serviceEnabled,
      serviceMode: serviceMode ?? state.serviceMode,
      serviceRateBps: serviceRateBps ?? state.serviceRateBps,
      serviceFixedAmount: serviceFixedAmount ?? state.serviceFixedAmount,
      taxAfterDiscount: taxAfterDiscount ?? state.taxAfterDiscount,
      businessDayStartHour: businessDayStartHour ?? state.businessDayStartHour,
      prepTargetMins: prepTargetMins ?? state.prepTargetMins,
      pickupTargetMins: pickupTargetMins ?? state.pickupTargetMins,
      ungreetedMins: ungreetedMins ?? state.ungreetedMins,
      ungreetedEscalateMins:
          ungreetedEscalateMins ?? state.ungreetedEscalateMins,
      longStayMins: longStayMins ?? state.longStayMins,
      idleTableMins: idleTableMins ?? state.idleTableMins,
      reservationGraceMins: reservationGraceMins ?? state.reservationGraceMins,
      pendingReviewMins: pendingReviewMins ?? state.pendingReviewMins,
      ungreetedAlertEnabled:
          ungreetedAlertEnabled ?? state.ungreetedAlertEnabled,
      pickupAlertEnabled: pickupAlertEnabled ?? state.pickupAlertEnabled,
      guestOrderingEnabled: guestOrderingEnabled ?? state.guestOrderingEnabled,
      soundNewOrder: soundNewOrder ?? state.soundNewOrder,
      soundReady: soundReady ?? state.soundReady,
      soundVoid: soundVoid ?? state.soundVoid,
      soundOverdue: soundOverdue ?? state.soundOverdue,
      soundUngreeted: soundUngreeted ?? state.soundUngreeted,
      soundPickup: soundPickup ?? state.soundPickup,
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
        'receiptTagline': ?receiptTagline,
        'receiptSocial': ?receiptSocial,
        'receiptThankYou': ?receiptThankYou,
        'receiptQrUrl': ?receiptQrUrl,
        'receiptQrCaption': ?receiptQrCaption,
        'taxEnabled': ?taxEnabled,
        'taxRateBps': ?taxRateBps,
        'serviceEnabled': ?serviceEnabled,
        'serviceMode': ?serviceMode,
        'serviceRateBps': ?serviceRateBps,
        'serviceFixedAmount': ?serviceFixedAmount,
        'taxAfterDiscount': ?taxAfterDiscount,
        'businessDayStartHour': ?businessDayStartHour,
        'prepTargetMins': ?prepTargetMins,
        'pickupTargetMins': ?pickupTargetMins,
        'ungreetedMins': ?ungreetedMins,
        'ungreetedEscalateMins': ?ungreetedEscalateMins,
        'longStayMins': ?longStayMins,
        'idleTableMins': ?idleTableMins,
        'reservationGraceMins': ?reservationGraceMins,
        'pendingReviewMins': ?pendingReviewMins,
        'ungreetedAlertEnabled': ?ungreetedAlertEnabled,
        'pickupAlertEnabled': ?pickupAlertEnabled,
        'guestOrderingEnabled': ?guestOrderingEnabled,
        'soundNewOrder': ?soundNewOrder,
        'soundReady': ?soundReady,
        'soundVoid': ?soundVoid,
        'soundOverdue': ?soundOverdue,
        'soundUngreeted': ?soundUngreeted,
        'soundPickup': ?soundPickup,
      };
      final raw = await ref
          .read(apiClientProvider)
          .patchJson('/venue/settings', body);
      state = VenueSettingsDto.fromJson((raw as Map).cast<String, dynamic>());
    } catch (e) {
      SatLog.repo('venueSettings.patch fail $e');
      state = prev;
      rethrow;
    }
  }

  /// Replace the venue logo (ADR-0033). [jpeg] is the raw, already-downscaled
  /// JPEG bytes. The server bumps logoRev and broadcasts the new settings, so
  /// state refreshes from the returned payload (and clients refetch by rev).
  Future<void> uploadLogo(List<int> jpeg) async {
    final raw = await ref.read(apiClientProvider).putBytes('/venue/logo', jpeg);
    state = VenueSettingsDto.fromJson((raw as Map).cast<String, dynamic>());
  }

  /// Clear the venue logo (back to a text-only header).
  Future<void> clearLogo() async {
    final raw = await ref.read(apiClientProvider).deleteJson('/venue/logo');
    state = VenueSettingsDto.fromJson((raw as Map).cast<String, dynamic>());
  }
}

final venueSettingsProvider =
    StateNotifierProvider<VenueSettingsRepository, VenueSettingsDto>(
      (ref) => VenueSettingsRepository(ref: ref),
    );

/// The venue logo's JPEG bytes (ADR-0033), or null when there is none. Keyed by
/// `logoRev` so a new logo (or a clear) cache-busts. Fetched over the pinned
/// client (see ApiClient.getBytes) — mirrors `menuPhotoBytesProvider`.
final venueLogoBytesProvider = FutureProvider.autoDispose
    .family<Uint8List?, int>((ref, rev) async {
      if (rev <= 0) return null;
      if (ref.watch(apiConfigProvider) == null) return null;
      try {
        final bytes = await ref.read(apiClientProvider).getBytes('/venue/logo');
        ref.keepAlive();
        return bytes;
      } catch (_) {
        return null;
      }
    });

/// The server's current LAN address for the guest plane: the base URL guests
/// reach by scanning a table QR (`http://<lan-ip>:8080`), plus the raw IP for
/// drift detection. Null fields mean the server couldn't resolve a LAN IPv4
/// (Wi-Fi down) — the UI must warn rather than render a dead QR. Refetchable so
/// the admin can re-check after a network change.
class GuestNetInfo {
  const GuestNetInfo({this.lanIp, this.guestPort, this.guestBaseUrl});
  final String? lanIp;
  final int? guestPort;
  final String? guestBaseUrl;
}

final guestNetInfoProvider = FutureProvider<GuestNetInfo>((ref) async {
  if (ref.read(apiConfigProvider) == null) return const GuestNetInfo();
  try {
    final raw = await ref.read(apiClientProvider).getJson('/venue/guest-net');
    final m = (raw as Map).cast<String, dynamic>();
    return GuestNetInfo(
      lanIp: m['lanIp'] as String?,
      guestPort: (m['guestPort'] as num?)?.toInt(),
      guestBaseUrl: m['guestBaseUrl'] as String?,
    );
  } catch (e) {
    SatLog.repo('guestNet.fetch fail $e');
    return const GuestNetInfo();
  }
});
