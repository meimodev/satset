import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/auth_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/dummy_data_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/user.dart';

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
/// [ApiClient]; falls back to dummy seed only when no API config exists
/// (e.g. first boot before onboarding).
class AuthRepository extends StateNotifier<AuthState> {
  AuthRepository({
    required this.ref,
    required this.seed,
    required this.storage,
  }) : super(const AuthState());

  final Ref ref;
  final DummyDataService seed;
  final SecureStorageService storage;

  Future<void> signInWithPin(String pin) async {
    state = state.copyWith(busy: true, error: null);
    final cfg = ref.read(apiConfigProvider);
    try {
      if (cfg == null) {
        // Dummy/offline first-boot path.
        state = AuthState(
          isAuthenticated: true,
          user: seed.defaultSignInUser,
          busy: false,
        );
        return;
      }
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
      state = AuthState(
        isAuthenticated: true,
        user: AppUser(
          id: me.userId,
          name: me.name,
          initials: me.initials,
          role: UserRole.waiter,
          shiftStartedAt: DateTime.now().toIso8601String(),
          zoneAssigned: me.zoneAssigned ?? '',
          roleId: me.roleId,
        ),
        capabilities: caps,
        busy: false,
      );
    } catch (e) {
      state = state.copyWith(busy: false, error: e.toString());
    }
  }

  /// Legacy entry point still used by the existing dummy `PinScreen`.
  void signIn() {
    state = AuthState(isAuthenticated: true, user: seed.defaultSignInUser);
  }

  /// Restore an existing token by calling `/auth/me`. No-op if no API config
  /// or no stored token.
  Future<void> restoreFromStoredToken() async {
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
      state = AuthState(
        isAuthenticated: true,
        user: AppUser(
          id: me.userId,
          name: me.name,
          initials: me.initials,
          role: UserRole.waiter,
          shiftStartedAt: DateTime.now().toIso8601String(),
          zoneAssigned: me.zoneAssigned ?? '',
          roleId: me.roleId,
        ),
        capabilities: caps,
      );
    } catch (_) {
      await storage.clearSession();
    }
  }

  Future<void> signOut() async {
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
          seed: ref.watch(dummyDataServiceProvider),
          storage: ref.watch(secureStorageServiceProvider),
        ));
