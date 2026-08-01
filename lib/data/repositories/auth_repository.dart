import 'dart:async';
import 'package:satset/core/time/sat_clock.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/services/owner_report_service.dart';

import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/auth_dto.dart';
import 'package:satset/data/repositories/auth_error.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/venue_subscription.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/mdns_browser_service.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/user.dart';
import 'package:uuid/uuid.dart';
import 'package:satset/server/server.dart' show serverRuntimeProvider;

/// Derive the legacy [UserRole] bucket from the server-authoritative
/// capabilities set. Source of truth is the role row on the server; the
/// legacy enum stays only because UI labels still switch on it.
UserRole _roleFromCapabilities(Set<Capability> caps) {
  if (caps.contains(Capability.manageStaff) ||
      caps.contains(Capability.manageRoles) ||
      caps.contains(Capability.editSettings)) {
    return UserRole.admin;
  }
  if (caps.contains(Capability.viewKds) &&
      !caps.contains(Capability.takeOrder)) {
    return UserRole.kitchen;
  }
  return UserRole.waiter;
}

class AuthState {
  final bool isAuthenticated;
  final AppUser? user;
  final String? error;
  final bool busy;

  /// True while [AuthRepository.restoreFromStoredToken] is checking an existing
  /// session at boot. Used to mask the sign-in form behind a loading screen so
  /// an auto-login admin never sees the form flash before redirecting.
  final bool restoring;
  final Set<Capability> capabilities;

  /// True when the signed-in account is a fleet operator (`admins/{uid}.role ==
  /// 'super'`). Such a session runs no local server and routes to the Fleet
  /// console; the router bypasses its pair gate for it. See ADR-0016.
  final bool isSuperAdmin;

  /// True when the signed-in account is a read-only report owner
  /// (`admins/{uid}.role == 'owner'`). Like a super admin it runs no local
  /// server and bypasses the pair gate, but it routes to `/owner` and reads
  /// only its venue's published report. See ADR-0036.
  final bool isOwner;

  /// The owner's venue id (`admins/{uid}.venueId`), used to read `reports/{vid}`.
  /// Empty unless [isOwner].
  final String ownerVenueId;
  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.busy = false,
    this.restoring = false,
    this.capabilities = const {},
    this.isSuperAdmin = false,
    this.isOwner = false,
    this.ownerVenueId = '',
  });

  AuthState copyWith({
    bool? isAuthenticated,
    AppUser? user,
    String? error,
    bool? busy,
    bool? restoring,
    Set<Capability>? capabilities,
    bool? isSuperAdmin,
    bool? isOwner,
    String? ownerVenueId,
  }) => AuthState(
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    user: user ?? this.user,
    error: error,
    busy: busy ?? this.busy,
    restoring: restoring ?? this.restoring,
    capabilities: capabilities ?? this.capabilities,
    isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
    isOwner: isOwner ?? this.isOwner,
    ownerVenueId: ownerVenueId ?? this.ownerVenueId,
  );

  bool has(Capability c) => capabilities.contains(c);
}

/// LAN-backed auth repository. PIN sign-in talks to the server via
/// [ApiClient]; the router's pair-gate ensures an [ApiConfig] is always
/// populated before this code runs.
class AuthRepository extends StateNotifier<AuthState> {
  AuthRepository({required this.ref, required this.storage})
    : super(const AuthState());

  final Ref ref;
  final SecureStorageService storage;

  /// Live per-operator listener (`admins/{uid}.status`). One half of the kill
  /// switch; tears the server down if this admin is banned.
  StreamSubscription<AdminProfile?>? _eligibilitySub;

  /// Live per-venue kill-switch listener (`venues/{vid}.status`). The other
  /// half — tears the server down if the venue is suspended/banned. ADR-0016.
  StreamSubscription<Venue?>? _venueSub;

  /// ~60s heartbeat stamping `venues/{vid}.lastSeenAt` while the server is live.
  Timer? _heartbeat;

  /// Host-only: publishes the venue report snapshot to `reports/{vid}` and
  /// fulfils owner refresh requests while this device is the server. ADR-0036.
  OwnerReportPublisher? _reportPublisher;

  Future<bool> signInWithPin(String pin) async {
    SatLog.repo('auth.signInWithPin');
    state = state.copyWith(busy: true, error: null);
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      state = state.copyWith(
        busy: false,
        error: 'Server belum siap. Tunggu sebentar lalu coba lagi.',
      );
      return false;
    }
    try {
      final api = ref.read(apiClientProvider);
      final deviceId = await storage.readDeviceId() ?? '';
      final raw = await api.postJson(
        '/auth/login',
        PinLoginRequestDto(pin: pin, deviceId: deviceId).toJson(),
      );
      final session = SessionDto.fromJson((raw as Map).cast<String, dynamic>());
      await storage.writeToken(session.token);
      final me = MeDto.fromJson(
        (await api.getJson('/auth/me') as Map).cast<String, dynamic>(),
      );
      final caps = <Capability>{
        for (final k in me.capabilities)
          if (capabilityFromKey(k) != null) capabilityFromKey(k)!,
      };
      final loginAt = SatClock.now();
      await storage.writeLoginAt(loginAt);
      // The server opens/resumes the shift and is authoritative (ADR-0065) —
      // that is what lets a shift survive onto a different handset. The local
      // stamp stays as the fallback for a legacy host with no such field.
      final shiftStartedAt = me.shiftStartedAt ?? loginAt.toIso8601String();
      state = AuthState(
        isAuthenticated: true,
        user: AppUser(
          id: me.userId,
          name: me.name,
          initials: me.initials,
          role: _roleFromCapabilities(caps),
          shiftStartedAt: shiftStartedAt,
          zoneAssigned: me.zoneAssigned ?? '',
          roleId: me.roleId,
          avatarColorHex: me.avatarColorHex,
        ),
        capabilities: caps,
        busy: false,
      );
      SatLog.repo('auth.signIn ok user=${me.name} caps=${caps.length}');
      return true;
    } catch (e) {
      SatLog.repo('auth.signIn fail ${e.toString()}');
      state = state.copyWith(
        busy: false,
        error: authErrorMessage(e, pin: true),
      );
      return false;
    }
  }

  /// Admin sign-in via Firebase Authentication (email + password). Firebase
  /// gates identity + eligibility (`admins/{uid}.status == active`); only on a
  /// pass does [bootServer] start the embedded server, after which the local
  /// admin session is minted **in-process** (no HTTP, no token round-trip).
  /// Starts the live eligibility kill switch on success. See ADR-0015.
  Future<bool> signInAsAdmin({
    required String email,
    required String password,
    required Future<void> Function(String venueId) bootServer,
  }) async {
    SatLog.repo('auth.signInAsAdmin email=$email');
    state = state.copyWith(busy: true, error: null);
    final fb = ref.read(firebaseAdminServiceProvider);
    try {
      final cred = await fb.signIn(email: email, password: password);
      final uid = cred.user?.uid;
      if (uid == null) {
        state = state.copyWith(busy: false, error: 'Login admin gagal.');
        return false;
      }
      final profile = await fb.fetch(uid);
      if (profile == null) {
        // Auth user exists but has no `admins/{uid}` doc. Log the uid so an
        // operator can create the doc / record (doc id == uid).
        SatLog.repo('auth.signInAsAdmin blocked uid=$uid status=no-doc');
        await fb.signOut();
        state = state.copyWith(busy: false, error: _eligibilityMessage(null));
        return false;
      }

      // A dictated temporary password, checked before every divert and long
      // before `bootServer`. The account holds a credential that travelled by
      // voice over WhatsApp, so it buys exactly one thing: the right to replace
      // itself. No eligibility read, no mDNS lookup, no server. See ADR-0075.
      if (profile.mustChangePassword) {
        final expired = profile.expiredTempPassword(SatClock.now());
        SatLog.repo(
          'auth.signInAsAdmin temp-password uid=$uid expired=$expired',
        );
        if (expired) {
          await fb.signOut();
          state = state.copyWith(
            busy: false,
            error: AppStrings.tempPasswordExpired,
          );
          return false;
        }
        // Not signed out, unlike every other rejection here. This one is a
        // continuation rather than a refusal: `changeOwnPassword` is authorized
        // by the token this sign-in just minted, and dropping it would leave the
        // change form with no way to prove who is asking. The session buys
        // nothing else — no local JWT, no server, and Firestore rules give a
        // plain admin only its own doc and one heartbeat field.
        ref.read(pendingPasswordChangeProvider.notifier).state =
            PendingPasswordChange(uid: uid, email: email, name: profile.name);
        state = state.copyWith(busy: false, error: null);
        return false;
      }

      // Fleet operator: no venue, no local server — divert to the Fleet console.
      if (profile.isSuper) {
        _establishSuperSession(profile, email);
        SatLog.repo('auth.signInAsAdmin super uid=$uid');
        return true;
      }

      // Report owner: read-only, no local server — divert to /owner. Requires
      // its own account to be active; NOT gated on the venue kill switch (the
      // owner only views stale reports, never operates). See ADR-0036.
      if (profile.isOwner) {
        if (!profile.isActive) {
          SatLog.repo(
            'auth.signInAsAdmin blocked owner uid=$uid status=${profile.status.name}',
          );
          await fb.signOut();
          state = state.copyWith(
            busy: false,
            error: _eligibilityMessage(profile),
          );
          return false;
        }
        if (profile.venueId.isEmpty) {
          SatLog.repo('auth.signInAsAdmin blocked owner uid=$uid no-venue');
          await fb.signOut();
          state = state.copyWith(busy: false, error: _noVenueMessage);
          return false;
        }
        _establishOwnerSession(profile, email);
        SatLog.repo(
          'auth.signInAsAdmin owner uid=$uid venue=${profile.venueId}',
        );
        return true;
      }

      if (!profile.isActive) {
        SatLog.repo(
          'auth.signInAsAdmin blocked uid=$uid status=${profile.status.name}',
        );
        await fb.signOut();
        state = state.copyWith(
          busy: false,
          error: _eligibilityMessage(profile),
        );
        return false;
      }

      // Venue-level kill switch: the venue this admin belongs to must be active
      // too (one venue → many admins). See ADR-0016.
      if (profile.venueId.isEmpty) {
        SatLog.repo('auth.signInAsAdmin blocked uid=$uid no-venue');
        await fb.signOut();
        state = state.copyWith(busy: false, error: _noVenueMessage);
        return false;
      }
      final venue = await fb.fetchVenue(profile.venueId);
      if (venue == null || !venue.isActive) {
        SatLog.repo(
          'auth.signInAsAdmin blocked venue=${profile.venueId} status=${venue?.status.name ?? "no-doc"}',
        );
        await fb.signOut();
        state = state.copyWith(busy: false, error: _venueMessage(venue));
        return false;
      }

      await storage.writeAdminConfirmedAt(SatClock.now());

      // Main-Device model (ADR-0017): if another device already hosts this
      // venue on the LAN, join it as an admin-client instead of booting a
      // rival server (which would split the data). Otherwise become the host.
      final host = await ref
          .read(mdnsBrowserServiceProvider)
          .findVenueHost(profile.venueId);
      if (host != null) {
        final joined = await _establishAdminClientSession(
          host: host,
          uid: uid,
          profile: profile,
        );
        if (!joined) {
          await fb.signOut();
          state = state.copyWith(
            busy: false,
            error: 'Gagal bergabung ke server venue. Coba lagi.',
          );
          return false;
        }
        SatLog.repo(
          'auth.signInAsAdmin joined-as-client host=${host.label} '
          'venue=${profile.venueId}',
        );
        return true;
      }

      // Eligible + no existing host — boot the embedded server (scoped to this
      // admin's venue so it advertises `vid` for the guard), then mint the
      // session locally.
      await bootServer(profile.venueId);
      final ok = await _establishAdminSession(uid: uid, profile: profile);
      if (!ok) {
        state = state.copyWith(
          busy: false,
          error: 'Server belum siap. Coba lagi.',
        );
        return false;
      }
      _startEligibilityWatch(uid, profile.venueId);
      SatLog.repo(
        'auth.signInAsAdmin ok host uid=$uid venue=${profile.venueId}',
      );
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      SatLog.repo('auth.signInAsAdmin fb-fail ${e.code}');
      state = state.copyWith(busy: false, error: _firebaseAuthMessage(e));
      return false;
    } catch (e) {
      SatLog.repo('auth.signInAsAdmin fail $e');
      state = state.copyWith(
        busy: false,
        error: authErrorMessage(e, pin: false),
      );
      return false;
    }
  }

  /// Provision the local admin user for [uid], mint a session in-process, then
  /// resolve `/auth/me` so capabilities reflect the local role authority.
  Future<bool> _establishAdminSession({
    required String uid,
    required AdminProfile profile,
  }) async {
    final rt = ref.read(serverRuntimeProvider);
    if (rt == null) return false;
    final api = ref.read(apiClientProvider);
    final deviceId = await storage.readDeviceId() ?? '';
    final userId = await rt.auth.provisionAdminUser(
      firebaseUid: uid,
      name: profile.name,
      avatarColorHex: profile.avatarColorHex,
    );
    final session = await rt.auth.mintSession(
      userId: userId,
      deviceId: deviceId,
    );
    await storage.writeToken(session.token);
    final me = MeDto.fromJson(
      (await api.getJson('/auth/me') as Map).cast<String, dynamic>(),
    );
    final caps = <Capability>{
      for (final k in me.capabilities)
        if (capabilityFromKey(k) != null) capabilityFromKey(k)!,
    };
    final loginAt = SatClock.now();
    await storage.writeLoginAt(loginAt);
    // Server-authoritative shift; local stamp is the legacy-host fallback.
    final shiftStartedAt = me.shiftStartedAt ?? loginAt.toIso8601String();
    state = AuthState(
      isAuthenticated: true,
      user: AppUser(
        id: me.userId,
        name: me.name,
        initials: me.initials,
        role: _roleFromCapabilities(caps),
        shiftStartedAt: shiftStartedAt,
        zoneAssigned: me.zoneAssigned ?? '',
        roleId: me.roleId,
        avatarColorHex: me.avatarColorHex,
      ),
      capabilities: caps,
      busy: false,
    );
    return true;
  }

  /// Join an existing venue [[Main Device]] host as an **admin-client** over
  /// the LAN (ADR-0017): point at the host (we already hold its TLS
  /// fingerprint from mDNS, so no QR pairing is needed), present this admin's
  /// Firebase ID token to `/auth/admin`, and adopt the local admin JWT the host
  /// issues. This device runs as a **client** — it hosts no server/DB.
  Future<bool> _establishAdminClientSession({
    required DiscoveredServer host,
    required String uid,
    required AdminProfile profile,
  }) async {
    ref.read(apiConfigProvider.notifier).state = ApiConfig(
      baseUri: Uri.parse('https://${host.host}:${host.port}'),
      trustedFingerprint: host.fingerprint,
    );
    try {
      final prefs = await ref.read(prefsServiceProvider.future);
      await prefs.setAppMode(AppMode.client);
    } catch (_) {
      // Mode persistence is best-effort; the live apiConfig already routes us.
    }
    // forceRefresh so freshly-set {role, venueId} claims are present.
    final idToken = await ref
        .read(firebaseAdminServiceProvider)
        .currentIdToken(forceRefresh: true);
    if (idToken == null || idToken.isEmpty) return false;
    var deviceId = await storage.readDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await storage.writeDeviceId(deviceId);
    }
    try {
      final api = ref.read(apiClientProvider);
      final res =
          (await api.postJson('/auth/admin', {
                    'idToken': idToken,
                    'deviceId': deviceId,
                  })
                  as Map)
              .cast<String, dynamic>();
      final token = res['token'] as String?;
      if (token == null || token.isEmpty) return false;
      await storage.writeToken(token);
      final me = MeDto.fromJson(
        (await api.getJson('/auth/me') as Map).cast<String, dynamic>(),
      );
      final caps = <Capability>{
        for (final k in me.capabilities)
          if (capabilityFromKey(k) != null) capabilityFromKey(k)!,
      };
      final loginAt = SatClock.now();
      await storage.writeLoginAt(loginAt);
      // The server opens/resumes the shift and is authoritative (ADR-0065) —
      // that is what lets a shift survive onto a different handset. The local
      // stamp stays as the fallback for a legacy host with no such field.
      final shiftStartedAt = me.shiftStartedAt ?? loginAt.toIso8601String();
      state = AuthState(
        isAuthenticated: true,
        user: AppUser(
          id: me.userId,
          name: me.name,
          initials: me.initials,
          role: _roleFromCapabilities(caps),
          shiftStartedAt: shiftStartedAt,
          zoneAssigned: me.zoneAssigned ?? '',
          roleId: me.roleId,
          avatarColorHex: me.avatarColorHex,
        ),
        capabilities: caps,
        busy: false,
      );
      return true;
    } catch (e) {
      SatLog.repo('auth.adminClient join fail $e');
      return false;
    }
  }

  /// Establish a fleet-operator session: no local server, no Drift, no venue.
  /// The router sees `isSuperAdmin` and routes to `/fleet`, bypassing the pair
  /// gate. See ADR-0016.
  void _establishSuperSession(AdminProfile profile, String email) {
    state = AuthState(
      isAuthenticated: true,
      isSuperAdmin: true,
      user: AppUser(
        id: profile.uid,
        name: profile.name.isEmpty ? email : profile.name,
        initials: _initials(profile.name.isEmpty ? email : profile.name),
        role: UserRole.admin,
        shiftStartedAt: SatClock.now().toIso8601String(),
        zoneAssigned: '',
        roleId: 'super',
        avatarColorHex: profile.avatarColorHex,
      ),
      busy: false,
    );
  }

  /// Establish a read-only owner session: no local server, no Drift, no pairing.
  /// The router sees `isOwner` and routes to `/owner`, bypassing the pair gate.
  /// The owner screen reads `reports/{ownerVenueId}`. See ADR-0036.
  void _establishOwnerSession(AdminProfile profile, String email) {
    state = AuthState(
      isAuthenticated: true,
      isOwner: true,
      ownerVenueId: profile.venueId,
      user: AppUser(
        id: profile.uid,
        name: profile.name.isEmpty ? email : profile.name,
        initials: _initials(profile.name.isEmpty ? email : profile.name),
        role: UserRole.admin,
        shiftStartedAt: SatClock.now().toIso8601String(),
        zoneAssigned: '',
        roleId: 'owner',
        avatarColorHex: profile.avatarColorHex,
      ),
      busy: false,
    );
  }

  static String _initials(String s) {
    final parts = s
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Arm the two-sided kill switch and the offline heartbeat for a live admin
  /// session: watch `admins/{uid}.status` (per-operator ban) AND
  /// `venues/{vid}.status` (per-venue kill); either leaving `active` tears the
  /// server down. While live, stamp `venues/{vid}.lastSeenAt` every ~60s so the
  /// fleet console can show offline duration. See ADR-0016.
  void _startEligibilityWatch(String uid, String venueId) {
    _eligibilitySub?.cancel();
    _venueSub?.cancel();
    _heartbeat?.cancel();
    final fb = ref.read(firebaseAdminServiceProvider);

    _eligibilitySub = fb.watch(uid).listen((profile) async {
      if (profile == null || !profile.isActive) {
        SatLog.repo('auth.eligibility revoked (admin) → kill server');
        await _killAdminSession();
      } else if (!profile.fromCache) {
        await storage.writeAdminConfirmedAt(SatClock.now());
      }
    });

    _venueSub = fb.watchVenue(venueId).listen((venue) async {
      if (venue == null || !venue.isActive) {
        SatLog.repo('auth.eligibility revoked (venue) → kill server');
        await _killAdminSession();
        return;
      }
      // Publish the whole document, not just the fields this listener acts on.
      // The subscription fields were always arriving here and being dropped,
      // which is why the venue paying the bill was the one party in the system
      // that could not see its own billing state. See [venueCloudDocProvider].
      ref.read(venueCloudDocProvider.notifier).state = venue;
      // Cloud owns venue identity (ADR-0018): mirror name/address into the
      // local VenueSettings. The 60s heartbeat rewrites `lastSeenAt`, which
      // re-fires this snapshot, so a diff-guard keeps it a no-op when nothing
      // changed.
      await _mirrorVenueIdentity(venue);
    });

    // Each beat does two online-only writes that must freeze together when the
    // venue goes dark: (1) stamp `venues/{vid}.lastSeenAt` so the fleet console
    // can derive offline + lockout-risk; (2) refresh the local
    // `adminConfirmedAt` floor via a server-confirmed read, resetting the
    // offline-grace clock that the shell banner counts down. Keeping both on the
    // same beat lets the cloud `lastSeenAt` proxy the device-local grace. See
    // ADR-0015 staleness guard.
    Future<void> beat() async {
      unawaited(fb.touchVenue(venueId).catchError((_) {}));
      try {
        final p = await fb.fetch(uid, serverOnly: true);
        if (p != null && p.isActive) {
          await storage.writeAdminConfirmedAt(SatClock.now());
        }
      } catch (_) {
        // Offline — let the grace clock tick; the boot gate enforces the limit.
      }
    }

    unawaited(beat()); // immediate, so the venue shows online without waiting
    _heartbeat = Timer.periodic(
      const Duration(seconds: 60),
      (_) => unawaited(beat()),
    );

    _startReportPublisher(venueId);
  }

  /// Host-only: begin publishing the venue report snapshot to `reports/{vid}`
  /// (ADR-0036). Only the device running the embedded server holds the Drift DB
  /// to compute it, so this is a no-op on an admin-client. The snapshot is
  /// fetched over loopback from the same `/reports/snapshot` the admin screen
  /// uses, so the owner sees identical numbers.
  void _startReportPublisher(String venueId) {
    _reportPublisher?.stop();
    _reportPublisher = null;
    if (ref.read(serverRuntimeProvider) == null) return; // admin-client: skip
    final api = ref.read(apiClientProvider);
    _reportPublisher = OwnerReportPublisher(
      firestore: FirebaseFirestore.instance,
      vid: venueId,
      fetchSnapshot: (range) async {
        try {
          final raw = await api.getJson(
            '/reports/snapshot',
            query: {'range': range},
          );
          return (raw as Map).cast<String, dynamic>();
        } catch (e) {
          SatLog.repo('ownerReport.fetch range=$range fail $e');
          return null;
        }
      },
    )..start();
  }

  /// Push the cloud venue's name/address into the local VenueSettings so the
  /// in-app name + receipts track the fleet-console value (ADR-0018). Only
  /// non-empty cloud values overwrite local, and only when they actually
  /// differ — so the heartbeat-driven snapshot churn doesn't spam patches.
  Future<void> _mirrorVenueIdentity(Venue v) async {
    final settings = ref.read(venueSettingsProvider);
    final nextName = v.name.trim();
    final nextAddr = v.address.trim();
    final needName = nextName.isNotEmpty && nextName != settings.displayName;
    final needAddr = nextAddr.isNotEmpty && nextAddr != settings.address;
    if (!needName && !needAddr) return;
    try {
      await ref
          .read(venueSettingsProvider.notifier)
          .patch(
            displayName: needName ? nextName : null,
            address: needAddr ? nextAddr : null,
          );
      SatLog.repo('venueIdentity.mirrored name=$needName addr=$needAddr');
    } catch (_) {
      // Server not up yet / offline — retried on the next venue snapshot.
    }
  }

  /// Tear down the admin session AND the embedded server. Connected staff are
  /// disconnected and cannot reconnect until an admin re-signs-in. Shared by
  /// explicit admin logout and the eligibility kill switch. See ADR-0015.
  Future<void> _killAdminSession() async {
    await _eligibilitySub?.cancel();
    _eligibilitySub = null;
    await _venueSub?.cancel();
    _venueSub = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _reportPublisher?.stop();
    _reportPublisher = null;
    // Drop the cached venue doc with the listener that fed it. Left standing,
    // the next admin to sign in on this device sees the previous venue's
    // subscription state until their own first snapshot lands.
    ref.read(venueCloudDocProvider.notifier).state = null;
    try {
      await ref.read(firebaseAdminServiceProvider).signOut();
    } catch (_) {}
    final rt = ref.read(serverRuntimeProvider);
    if (rt != null) {
      try {
        await rt.shutdown();
      } catch (_) {}
      ref.read(serverRuntimeProvider.notifier).state = null;
    }
    ref.read(apiConfigProvider.notifier).state = null;
    await storage.clearSession();
    state = const AuthState();
  }

  String _eligibilityMessage(AdminProfile? p) {
    if (p == null) return 'Akun admin belum terdaftar. Hubungi pengelola.';
    return switch (p.status) {
      AdminStatus.suspended => 'Akun admin ditangguhkan. Hubungi pengelola.',
      _ => 'Akun admin tidak aktif.',
    };
  }

  static const _noVenueMessage =
      'Akun belum ditugaskan ke venue. Hubungi pengelola.';

  String _venueMessage(Venue? v) {
    if (v == null) return 'Venue tidak ditemukan. Hubungi pengelola.';
    return switch (v.status) {
      AdminStatus.suspended => 'Venue ditangguhkan. Hubungi pengelola.',
      // Also where a pre-ADR-0076 `banned` document lands: it parses to
      // `unknown`, fails `isActive`, and stops the venue exactly as before.
      _ => 'Venue tidak aktif.',
    };
  }

  String _firebaseAuthMessage(fb_auth.FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'Email tidak valid.',
      'user-disabled' => 'Akun admin dinonaktifkan.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email atau password salah.',
      'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
      'network-request-failed' =>
        'Gagal terhubung. Login admin pertama butuh internet.',
      _ => 'Login admin gagal. Coba lagi.',
    };
  }

  /// Restore an existing token by calling `/auth/me`. No-op if no API config
  /// or no stored token.
  Future<void> restoreFromStoredToken() async {
    SatLog.repo('auth.restore');
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    state = state.copyWith(restoring: true);
    final token = await storage.readToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(restoring: false);
      return;
    }
    try {
      final api = ref.read(apiClientProvider);
      final me = MeDto.fromJson(
        (await api.getJson('/auth/me') as Map).cast<String, dynamic>(),
      );
      final caps = <Capability>{
        for (final k in me.capabilities)
          if (capabilityFromKey(k) != null) capabilityFromKey(k)!,
      };
      var loginAt = await storage.readLoginAt();
      if (loginAt == null) {
        loginAt = SatClock.now();
        await storage.writeLoginAt(loginAt);
      }
      // A restore must not resurrect a retired shift: `/auth/me` reports the
      // shift read-only and returns null once the business-day boundary has
      // passed, so a token that survives overnight no longer hands us
      // yesterday's clock. Falling back to the local stamp only when the host
      // has no opinion at all.
      final shiftStartedAt = me.shiftStartedAt ?? loginAt.toIso8601String();
      state = AuthState(
        isAuthenticated: true,
        user: AppUser(
          id: me.userId,
          name: me.name,
          initials: me.initials,
          role: _roleFromCapabilities(caps),
          shiftStartedAt: shiftStartedAt,
          zoneAssigned: me.zoneAssigned ?? '',
          roleId: me.roleId,
          avatarColorHex: me.avatarColorHex,
        ),
        capabilities: caps,
      );
      // Admin auto-login: re-arm the two-sided kill switch + heartbeat for the
      // cached Firebase session so a console/fleet flip still tears the server
      // down. Resolve the venueId off the admin doc (cache-tolerant).
      final fb = ref.read(firebaseAdminServiceProvider);
      final fbUid = fb.currentUser?.uid;
      if (fbUid != null) {
        final profile = await fb.fetch(fbUid).catchError((_) => null);
        if (profile != null && profile.venueId.isNotEmpty) {
          _startEligibilityWatch(fbUid, profile.venueId);
        }
      }
    } catch (_) {
      await storage.clearSession();
      state = state.copyWith(restoring: false);
    }
  }

  /// Drops the staff session. [endShift] additionally closes the shift — the
  /// difference between "Keluar" (hand the handset over; your shift keeps
  /// running and the next sign-in resumes it) and "Akhiri shift & keluar".
  /// See ADR-0065.
  ///
  /// Server-mode admins only ever reach this with [endShift] true: their
  /// sign-out kills the venue's server either way (ADR-0015), so a
  /// shift-preserving exit would be a lie.
  Future<void> signOut({bool endShift = false}) async {
    SatLog.repo('auth.signOut endShift=$endShift');
    // Fleet operator / report owner: no local server, just drop the Firebase
    // session. See ADR-0016, ADR-0036.
    if (state.isSuperAdmin || state.isOwner) {
      try {
        await ref.read(firebaseAdminServiceProvider).signOut();
      } catch (_) {}
      state = const AuthState();
      return;
    }
    final rt = ref.read(serverRuntimeProvider);
    if (rt != null) {
      // Admin / Server mode: killing the server is the venue's off switch.
      // Connected staff drop and cannot reconnect until an admin re-signs-in.
      //
      // Close the shift first, over loopback while our own server is still up —
      // a Server-mode admin has no shift-preserving exit (ADR-0065 §admin), so
      // leaving the stamp set would silently resume this shift on the next
      // sign-in. Best-effort: a failure here must not block the teardown, and
      // the business-day boundary retires the stamp regardless.
      if (ref.read(apiConfigProvider) != null) {
        try {
          await ref.read(apiClientProvider).postJson('/auth/logout', {
            'endShift': true,
          });
        } catch (_) {}
      }
      await _killAdminSession();
      return;
    }
    // Staff / Client mode: drop the session but keep the pairing.
    final cfg = ref.read(apiConfigProvider);
    if (cfg != null) {
      try {
        await ref.read(apiClientProvider).postJson('/auth/logout', {
          'endShift': endShift,
        });
      } catch (_) {}
    }
    await storage.clearSession();
    state = const AuthState();
  }

  @override
  void dispose() {
    unawaited(_eligibilitySub?.cancel());
    unawaited(_venueSub?.cancel());
    _heartbeat?.cancel();
    _reportPublisher?.stop();
    super.dispose();
  }
}

final authStateProvider = StateNotifierProvider<AuthRepository, AuthState>(
  (ref) => AuthRepository(
    ref: ref,
    storage: ref.watch(secureStorageServiceProvider),
  ),
);

/// An admin who just signed in with a temporary password and has not replaced
/// it yet. See ADR-0075.
class PendingPasswordChange {
  final String uid;
  final String email;
  final String name;
  const PendingPasswordChange({
    required this.uid,
    required this.email,
    required this.name,
  });
}

/// Set by [AuthRepository.signInAsAdmin] when a temporary password is presented,
/// consumed by the PIN screen to open the change form. Deliberately *not* a
/// route redirect: the sign-in is already abandoned (Firebase is signed out
/// again) so there is no session for a redirect guard to reason about, and
/// backing out of the form lands where it should — the PIN screen, signed out.
final pendingPasswordChangeProvider = StateProvider<PendingPasswordChange?>(
  (_) => null,
);
