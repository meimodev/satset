import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/ws_client.dart';

final venueSettingsStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

class VenueSettingsRepository extends StateNotifier<VenueSettingsDto> {
  VenueSettingsRepository({required this.ref})
    : super(const VenueSettingsDto()) {
    // Synchronously, not in the microtask below: a widget's first build reads
    // this state before any microtask runs, and the first frame is exactly the
    // one that used to show a venue with everything switched off (ADR-0128).
    final cached = _cached(ref.read(prefsServiceProvider).valueOrNull);
    if (cached != null) state = cached;
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;
  ProviderSubscription<ApiConfig?>? _cfgSub;

  /// The one way a fetched payload becomes state: adopt it and write it down.
  /// A site that assigns `state` directly leaves the cache a version behind.
  void _adopt(VenueSettingsDto dto) {
    state = dto;
    _remember(dto);
  }

  /// Keep the venue's settings across a cold boot, **whole** (ADR-0128,
  /// amending ADR-0115's two-field rule).
  ///
  /// Every switch on this DTO fails closed through its freezed default, not
  /// just the two mode fields: a handset that boots away from its host used to
  /// draw a venue with membership off, guest ordering off and every threshold
  /// at the factory number. Stale beats absent — a flag the owner flipped
  /// while this device was dark is wrong until reconnect, where before it was
  /// wrong in *every* offline boot and silently so.
  void _remember(VenueSettingsDto dto) {
    final prefs = ref.read(prefsServiceProvider).valueOrNull;
    if (prefs == null) return;
    unawaited(
      prefs.setVenueSettingsJson(
        jsonEncode(dto.toJson()),
        fingerprint: ref.read(apiConfigProvider)?.trustedFingerprint,
      ),
    );
  }

  /// The last settings this device heard, or null if it never heard any.
  ///
  /// Falls back to the pre-0128 shape cache exactly once — a device that
  /// upgrades and cold-boots offline would otherwise re-acquire the flicker
  /// ADR-0115 removed.
  VenueSettingsDto? _cached(PrefsService? prefs) {
    if (prefs == null) return null;
    final raw = prefs.venueSettingsJson();
    if (raw != null) {
      try {
        return VenueSettingsDto.fromJson(
          (jsonDecode(raw) as Map).cast<String, dynamic>(),
        );
      } catch (e) {
        SatLog.repo('venueSettings.cache decode fail $e');
      }
    }
    final shape = prefs.legacyVenueShape();
    if (shape == null) return null;
    return const VenueSettingsDto().copyWith(
      modules: shape.modules,
      counterConfig: shape.counterConfig,
    );
  }

  Future<void> _fetch() async {
    if (ref.read(apiConfigProvider) == null) return;
    ref.read(venueSettingsStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      final raw = await ref.read(apiClientProvider).getJson('/venue/settings');
      // A request is an await gap wide enough for the container to go away —
      // a shell unmounting mid-flight, or a test ending. Reading a disposed
      // ref throws where nobody is listening.
      if (!mounted) return;
      _adopt(VenueSettingsDto.fromJson((raw as Map).cast<String, dynamic>()));
      ref.read(venueSettingsStatusProvider.notifier).state =
          const AsyncValue.data(null);
    } catch (e, st) {
      SatLog.repo('venueSettings.fetch fail $e');
      if (!mounted) return;
      ref.read(venueSettingsStatusProvider.notifier).state = AsyncValue.error(
        e,
        st,
      );
    }
  }

  /// Throw the cache away if it came from a different server.
  ///
  /// The check is here and not on the pairing setters because **the
  /// certificate is the venue's identity and its address is not** (ADR-0080):
  /// `relocateServer` rewrites the paired host on every DHCP turnover, so
  /// clearing on a host change threw a venue's own settings away on a router
  /// reboot. Only a different fingerprint is a different venue.
  ///
  /// It runs the moment a config exists rather than at read time, because the
  /// constructor paints before any fingerprint is knowable — the label lives
  /// in prefs but the trusted one arrives on `ApiConfig`. That is sound
  /// because **a device cannot re-pair while offline**: pairing costs a round
  /// trip, so a cache painted with no host can never be a server this device
  /// has not met.
  ///
  /// Clearing prefs is not enough — the constructor has already painted the
  /// foreign venue, so `state` goes back to the fail-closed default too.
  Future<void> _dropForeignCache(ApiConfig cfg) async {
    final prefs = ref.read(prefsServiceProvider).valueOrNull;
    if (prefs == null) return;
    final stamped = prefs.venueCacheFingerprint();
    // Null is "cached before the label existed", not "foreign" — an upgrade
    // must not throw away a cache it merely cannot vouch for.
    if (stamped == null || stamped.isEmpty) return;
    if (cfg.trustedFingerprint.isEmpty) return;
    if (stamped == cfg.trustedFingerprint) return;
    SatLog.repo('venueSettings.cache foreign — dropping');
    await prefs.clearVenueCache();
    state = const VenueSettingsDto();
  }

  Future<void> _bootstrap() async {
    // The constructor already painted whatever prefs had. Repaint here for the
    // boot where prefs itself was still resolving then — the service is a
    // `FutureProvider`, so a cold launch can construct this repository before
    // the shelf it reads from is open.
    if (state == const VenueSettingsDto()) {
      final cached = _cached(ref.read(prefsServiceProvider).valueOrNull);
      if (cached != null) state = cached;
    }
    final cfg = ref.read(apiConfigProvider);
    if (cfg != null) {
      await _dropForeignCache(cfg);
      // The prefs write is an await gap and a container can be torn down
      // inside it; reading a disposed ref throws where nobody is listening.
      if (!mounted) return;
    }
    if (ref.read(apiConfigProvider) == null) {
      ref.read(venueSettingsStatusProvider.notifier).state =
          const AsyncValue.data(null);
      // No host *yet* — this repository is constructed at app root (the locale
      // notifier reads `serviceTerm`, ADR-0127), which is before the paired
      // address has been read off prefs. Giving up here meant the venue ran
      // the whole session on whatever was cached and never fetched once, which
      // is how a device kept calling a service a meja after the venue renamed
      // it. Wait for the address instead.
      _cfgSub ??= ref.listen<ApiConfig?>(apiConfigProvider, (_, next) {
        if (next == null) return;
        _cfgSub?.close();
        _cfgSub = null;
        unawaited(_bootstrap());
      });
      return;
    }
    await _fetch();
    // Same await-gap rule as above: the request may outlive the container.
    if (!mounted) return;
    _wsSub ??= ref.read(wsClientProvider).events.listen((ev) {
      // Socket came back: refetch, the way every other collection does
      // (ADR-0021). Without it a client that cold-booted away from its host
      // ran on the cache until the owner happened to change a setting — the
      // broadcast below is an *edit*, not a resync.
      if (ev.type == WsEventTypes.connected) {
        unawaited(_fetch());
        return;
      }
      if (ev.type != WsEventTypes.venueSettingsUpdated) return;
      try {
        final dto = VenueSettingsDto.fromJson(ev.payload);
        _adopt(dto);
        SatLog.repo('venueSettings.ws update');
      } catch (e) {
        SatLog.repo('venueSettings.ws decode fail $e');
      }
    });
  }

  @override
  void dispose() {
    _cfgSub?.close();
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
    bool? ungreetedAlertEnabled,
    bool? pickupAlertEnabled,
    String? soundNewOrder,
    String? soundReady,
    String? soundVoid,
    String? soundOverdue,
    String? soundUngreeted,
    String? soundPickup,
    bool? membersEnabled,
    bool? memberPointsEnabled,
    bool? memberPunchEnabled,
    int? memberEarnPerThousand,
    int? memberPointValue,
    int? memberRedeemMin,
    int? memberPunchTarget,
    bool? memberDebtEnabled,
    int? memberDebtLimit,
    int? memberDebtOverdueDays,
    bool? guestOrderingEnabled,
    bool? guestNoteEnabled,
    int? guestHoursStartMin,
    int? guestHoursEndMin,
    int? guestMaxItems,
    int? guestSessionHours,
    String? soundGuestPending,

    /// [[Modul]] (ADR-0107). Written by exactly one caller — the host's
    /// venue-doc mirror in `auth_repository`. No screen offers it.
    List<String>? modules,
    List<String>? counterConfig,

    /// The two membership pointers. `''` clears one, a null leaves it alone —
    /// they are not optimistically applied, because "cleared" and "unchanged"
    /// are the same value in a `copyWith`, and the returned payload settles it
    /// a moment later anyway.
    String? memberPresetId,
    String? memberPunchItemId,
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
      ungreetedAlertEnabled:
          ungreetedAlertEnabled ?? state.ungreetedAlertEnabled,
      pickupAlertEnabled: pickupAlertEnabled ?? state.pickupAlertEnabled,
      soundNewOrder: soundNewOrder ?? state.soundNewOrder,
      soundReady: soundReady ?? state.soundReady,
      soundVoid: soundVoid ?? state.soundVoid,
      soundOverdue: soundOverdue ?? state.soundOverdue,
      soundUngreeted: soundUngreeted ?? state.soundUngreeted,
      soundPickup: soundPickup ?? state.soundPickup,
      membersEnabled: membersEnabled ?? state.membersEnabled,
      memberPointsEnabled: memberPointsEnabled ?? state.memberPointsEnabled,
      memberPunchEnabled: memberPunchEnabled ?? state.memberPunchEnabled,
      memberEarnPerThousand:
          memberEarnPerThousand ?? state.memberEarnPerThousand,
      memberPointValue: memberPointValue ?? state.memberPointValue,
      memberRedeemMin: memberRedeemMin ?? state.memberRedeemMin,
      memberPunchTarget: memberPunchTarget ?? state.memberPunchTarget,
      memberDebtEnabled: memberDebtEnabled ?? state.memberDebtEnabled,
      guestOrderingEnabled: guestOrderingEnabled ?? state.guestOrderingEnabled,
      guestNoteEnabled: guestNoteEnabled ?? state.guestNoteEnabled,
      guestHoursStartMin: guestHoursStartMin ?? state.guestHoursStartMin,
      guestHoursEndMin: guestHoursEndMin ?? state.guestHoursEndMin,
      guestMaxItems: guestMaxItems ?? state.guestMaxItems,
      guestSessionHours: guestSessionHours ?? state.guestSessionHours,
      soundGuestPending: soundGuestPending ?? state.soundGuestPending,
      modules: modules ?? state.modules,
      counterConfig: counterConfig ?? state.counterConfig,
      memberDebtLimit: memberDebtLimit ?? state.memberDebtLimit,
      memberDebtOverdueDays:
          memberDebtOverdueDays ?? state.memberDebtOverdueDays,
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
        'ungreetedAlertEnabled': ?ungreetedAlertEnabled,
        'pickupAlertEnabled': ?pickupAlertEnabled,
        'soundNewOrder': ?soundNewOrder,
        'soundReady': ?soundReady,
        'soundVoid': ?soundVoid,
        'soundOverdue': ?soundOverdue,
        'soundUngreeted': ?soundUngreeted,
        'soundPickup': ?soundPickup,
        'membersEnabled': ?membersEnabled,
        'memberPointsEnabled': ?memberPointsEnabled,
        'memberPunchEnabled': ?memberPunchEnabled,
        'memberEarnPerThousand': ?memberEarnPerThousand,
        'memberPointValue': ?memberPointValue,
        'memberRedeemMin': ?memberRedeemMin,
        'memberPunchTarget': ?memberPunchTarget,
        'memberDebtEnabled': ?memberDebtEnabled,
        'guestOrderingEnabled': ?guestOrderingEnabled,
        'guestNoteEnabled': ?guestNoteEnabled,
        'guestHoursStartMin': ?guestHoursStartMin,
        'guestHoursEndMin': ?guestHoursEndMin,
        'guestMaxItems': ?guestMaxItems,
        'guestSessionHours': ?guestSessionHours,
        'soundGuestPending': ?soundGuestPending,
        'modules': ?modules,
        'counterConfig': ?counterConfig,
        'memberDebtLimit': ?memberDebtLimit,
        'memberDebtOverdueDays': ?memberDebtOverdueDays,
        'memberPresetId': ?memberPresetId,
        'memberPunchItemId': ?memberPunchItemId,
      };
      final raw = await ref
          .read(apiClientProvider)
          .patchJson('/venue/settings', body);
      _adopt(VenueSettingsDto.fromJson((raw as Map).cast<String, dynamic>()));
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
    _adopt(VenueSettingsDto.fromJson((raw as Map).cast<String, dynamic>()));
  }

  /// Clear the venue logo (back to a text-only header).
  Future<void> clearLogo() async {
    final raw = await ref.read(apiClientProvider).deleteJson('/venue/logo');
    _adopt(VenueSettingsDto.fromJson((raw as Map).cast<String, dynamic>()));
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
