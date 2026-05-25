import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/auth_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/user.dart';

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
  final Set<Capability> capabilities;
  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.busy = false,
    this.capabilities = const {},
  });

  AuthState copyWith({
    bool? isAuthenticated,
    AppUser? user,
    String? error,
    bool? busy,
    Set<Capability>? capabilities,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        user: user ?? this.user,
        error: error,
        busy: busy ?? this.busy,
        capabilities: capabilities ?? this.capabilities,
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

  Future<bool> signInWithPin(String pin) async {
    SatLog.repo('auth.signInWithPin');
    state = state.copyWith(busy: true, error: null);
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      state = state.copyWith(busy: false, error: 'Server belum siap');
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
      state = state.copyWith(busy: false, error: e.toString());
      return false;
    }
  }

  /// Admin sign-in via email + password. Requires an [ApiConfig] (the
  /// loopback ApiConfig published by [ModeSelectViewModel] suffices). Posts
  /// to `/auth/admin/login`, persists the returned token, then resolves the
  /// session via `/auth/me` so capabilities reflect the server's view of
  /// the role.
  Future<bool> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    SatLog.repo('auth.signInAsAdmin email=$email');
    state = state.copyWith(busy: true, error: null);
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      SatLog.repo('auth.signInAsAdmin no ApiConfig');
      state = state.copyWith(busy: false, error: 'Server admin tidak siap');
      return false;
    }
    try {
      final api = ref.read(apiClientProvider);
      final deviceId = await storage.readDeviceId() ?? '';
      final raw = await api.postJson(
        '/auth/admin/login',
        AdminLoginRequestDto(
          email: email,
          password: password,
          deviceId: deviceId,
        ).toJson(),
      );
      final session =
          SessionDto.fromJson((raw as Map).cast<String, dynamic>());
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
      SatLog.repo('auth.signInAsAdmin ok user=${me.name} caps=${caps.length}');
      return true;
    } catch (e) {
      SatLog.repo('auth.signInAsAdmin fail $e');
      state = state.copyWith(busy: false, error: e.toString());
      return false;
    }
  }

  /// Restore an existing token by calling `/auth/me`. No-op if no API config
  /// or no stored token.
  Future<void> restoreFromStoredToken() async {
    SatLog.repo('auth.restore');
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    final token = await storage.readToken();
    if (token == null || token.isEmpty) return;
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
    } catch (_) {
      await storage.clearSession();
    }
  }

  Future<void> signOut() async {
    SatLog.repo('auth.signOut');
    final cfg = ref.read(apiConfigProvider);
    if (cfg != null) {
      try {
        await ref.read(apiClientProvider).postJson('/auth/logout', {});
      } catch (_) {}
    }
    await storage.clearSession();
    state = const AuthState();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthRepository, AuthState>((ref) => AuthRepository(
          ref: ref,
          storage: ref.watch(secureStorageServiceProvider),
        ));
