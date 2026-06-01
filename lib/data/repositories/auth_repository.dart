import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/auth_dto.dart';
import 'package:satset/data/repositories/auth_error.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/user.dart';
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
  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.busy = false,
    this.restoring = false,
    this.capabilities = const {},
    this.isSuperAdmin = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    AppUser? user,
    String? error,
    bool? busy,
    bool? restoring,
    Set<Capability>? capabilities,
    bool? isSuperAdmin,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        user: user ?? this.user,
        error: error,
        busy: busy ?? this.busy,
        restoring: restoring ?? this.restoring,
        capabilities: capabilities ?? this.capabilities,
        isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      );

  bool has(Capability c) => capabilities.contains(c);
}

/// LAN-backed auth repository. PIN sign-in talks to the server via
/// [ApiClient]; the router's pair-gate ensures an [ApiConfig] is always
/// populated before this code runs.
class AuthRepository extends StateNotifier<AuthState> {
  AuthRepository({
    required this.ref,
    required this.storage,
  }) : super(const AuthState());

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

  Future<bool> signInWithPin(String pin) async {
    SatLog.repo('auth.signInWithPin');
    state = state.copyWith(busy: true, error: null);
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      state = state.copyWith(
          busy: false,
          error: 'Server belum siap. Tunggu sebentar lalu coba lagi.');
      return false;
    }
    try {
      final api = ref.read(apiClientProvider);
      final deviceId = await storage.readDeviceId() ?? '';
      final raw = await api.postJson('/auth/login',
          PinLoginRequestDto(pin: pin, deviceId: deviceId).toJson());
      final session =
          SessionDto.fromJson((raw as Map).cast<String, dynamic>());
      await storage.writeToken(session.token);
      final me =
          MeDto.fromJson((await api.getJson('/auth/me') as Map).cast<String, dynamic>());
      final caps = <Capability>{
        for (final k in me.capabilities)
          if (capabilityFromKey(k) != null) capabilityFromKey(k)!,
      };
      final loginAt = DateTime.now();
      await storage.writeLoginAt(loginAt);
      state = AuthState(
        isAuthenticated: true,
        user: AppUser(
          id: me.userId,
          name: me.name,
          initials: me.initials,
          role: _roleFromCapabilities(caps),
          shiftStartedAt: loginAt.toIso8601String(),
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
      state = state.copyWith(busy: false, error: authErrorMessage(e, pin: true));
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
    required Future<void> Function() bootServer,
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

      // Fleet operator: no venue, no local server — divert to the Fleet console.
      if (profile.isSuper) {
        _establishSuperSession(profile, email);
        SatLog.repo('auth.signInAsAdmin super uid=$uid');
        return true;
      }

      if (!profile.isActive) {
        SatLog.repo(
            'auth.signInAsAdmin blocked uid=$uid status=${profile.status.name}');
        await fb.signOut();
        state =
            state.copyWith(busy: false, error: _eligibilityMessage(profile));
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
            'auth.signInAsAdmin blocked venue=${profile.venueId} status=${venue?.status.name ?? "no-doc"}');
        await fb.signOut();
        state = state.copyWith(busy: false, error: _venueMessage(venue));
        return false;
      }

      await storage.writeAdminConfirmedAt(DateTime.now());
      // Eligible — boot the embedded server, then mint the session locally.
      await bootServer();
      final ok = await _establishAdminSession(uid: uid, profile: profile);
      if (!ok) {
        state = state.copyWith(
            busy: false, error: 'Server belum siap. Coba lagi.');
        return false;
      }
      _startEligibilityWatch(uid, profile.venueId);
      SatLog.repo('auth.signInAsAdmin ok uid=$uid venue=${profile.venueId}');
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      SatLog.repo('auth.signInAsAdmin fb-fail ${e.code}');
      state = state.copyWith(busy: false, error: _firebaseAuthMessage(e));
      return false;
    } catch (e) {
      SatLog.repo('auth.signInAsAdmin fail $e');
      state =
          state.copyWith(busy: false, error: authErrorMessage(e, pin: false));
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
    final session =
        await rt.auth.mintSession(userId: userId, deviceId: deviceId);
    await storage.writeToken(session.token);
    final me = MeDto.fromJson(
        (await api.getJson('/auth/me') as Map).cast<String, dynamic>());
    final caps = <Capability>{
      for (final k in me.capabilities)
        if (capabilityFromKey(k) != null) capabilityFromKey(k)!,
    };
    final loginAt = DateTime.now();
    await storage.writeLoginAt(loginAt);
    state = AuthState(
      isAuthenticated: true,
      user: AppUser(
        id: me.userId,
        name: me.name,
        initials: me.initials,
        role: _roleFromCapabilities(caps),
        shiftStartedAt: loginAt.toIso8601String(),
        zoneAssigned: me.zoneAssigned ?? '',
        roleId: me.roleId,
        avatarColorHex: me.avatarColorHex,
      ),
      capabilities: caps,
      busy: false,
    );
    return true;
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
        shiftStartedAt: DateTime.now().toIso8601String(),
        zoneAssigned: '',
        roleId: 'super',
        avatarColorHex: profile.avatarColorHex,
      ),
      busy: false,
    );
  }

  static String _initials(String s) {
    final parts =
        s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Trigger a Firebase password-reset email for [email].
  Future<void> sendAdminPasswordReset(String email) =>
      ref.read(firebaseAdminServiceProvider).sendPasswordReset(email);

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
        await storage.writeAdminConfirmedAt(DateTime.now());
      }
    });

    _venueSub = fb.watchVenue(venueId).listen((venue) async {
      if (venue == null || !venue.isActive) {
        SatLog.repo('auth.eligibility revoked (venue) → kill server');
        await _killAdminSession();
      }
    });

    void beat() => unawaited(fb.touchVenue(venueId).catchError((_) {}));
    beat(); // immediate, so the venue shows online without waiting a minute
    _heartbeat = Timer.periodic(const Duration(seconds: 60), (_) => beat());
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
      AdminStatus.banned => 'Akun admin diblokir.',
      _ => 'Akun admin tidak aktif.',
    };
  }

  static const _noVenueMessage =
      'Akun belum ditugaskan ke venue. Hubungi pengelola.';

  String _venueMessage(Venue? v) {
    if (v == null) return 'Venue tidak ditemukan. Hubungi pengelola.';
    return switch (v.status) {
      AdminStatus.suspended => 'Venue ditangguhkan. Hubungi pengelola.',
      AdminStatus.banned => 'Venue diblokir.',
      _ => 'Venue tidak aktif.',
    };
  }

  String _firebaseAuthMessage(fb_auth.FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'Email tidak valid.',
      'user-disabled' => 'Akun admin dinonaktifkan.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'Email atau password salah.',
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
          (await api.getJson('/auth/me') as Map).cast<String, dynamic>());
      final caps = <Capability>{
        for (final k in me.capabilities)
          if (capabilityFromKey(k) != null) capabilityFromKey(k)!,
      };
      var loginAt = await storage.readLoginAt();
      if (loginAt == null) {
        loginAt = DateTime.now();
        await storage.writeLoginAt(loginAt);
      }
      state = AuthState(
        isAuthenticated: true,
        user: AppUser(
          id: me.userId,
          name: me.name,
          initials: me.initials,
          role: _roleFromCapabilities(caps),
          shiftStartedAt: loginAt.toIso8601String(),
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

  Future<void> signOut() async {
    SatLog.repo('auth.signOut');
    // Fleet operator: no local server, just drop the Firebase session.
    if (state.isSuperAdmin) {
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
      await _killAdminSession();
      return;
    }
    // Staff / Client mode: drop the session but keep the pairing.
    final cfg = ref.read(apiConfigProvider);
    if (cfg != null) {
      try {
        await ref.read(apiClientProvider).postJson('/auth/logout', {});
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
    super.dispose();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthRepository, AuthState>((ref) => AuthRepository(
          ref: ref,
          storage: ref.watch(secureStorageServiceProvider),
        ));
