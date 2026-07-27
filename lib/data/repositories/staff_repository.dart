import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/roles_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/role.dart';
import 'package:satset/domain/models/user.dart';
import 'package:uuid/uuid.dart';

class StaffException implements Exception {
  final String message;
  StaffException(this.message);
  @override
  String toString() => message;
}

/// Surfaces bootstrap progress for the staff list. Symmetric with
/// `tablesStatusProvider`.
final staffStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

class StaffRepository extends StateNotifier<List<AppUser>> {
  StaffRepository(this._ref) : super(const <AppUser>[]) {
    Future.microtask(_bootstrap);
  }

  final Ref _ref;
  final _rng = Random();
  StreamSubscription? _wsSub;

  RolesRepository get _roles => _ref.read(rolesRepositoryProvider.notifier);

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final cfg = _ref.read(apiConfigProvider);
    if (cfg == null) {
      _ref.read(staffStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
      return;
    }
    state = const <AppUser>[];
    _ref.read(staffStatusProvider.notifier).state = const AsyncValue.loading();
    try {
      final raw = await _ref.read(apiClientProvider).getJson('/staff') as List;
      state = [
        for (final e in raw) _fromJson((e as Map).cast<String, dynamic>()),
      ];
      SatLog.repo('staff.loaded n=${state.length}');
      _ref.read(staffStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
      _wireWs();
    } catch (e, st) {
      SatLog.repo('staff.bootstrap fail $e');
      _ref.read(staffStatusProvider.notifier).state = AsyncValue.error(e, st);
    }
  }

  void _wireWs() {
    if (_wsSub != null) return;
    _wsSub = _ref.read(wsClientProvider).events.listen((ev) {
      switch (ev.type) {
        case WsEventTypes.staffCreated:
          final u = _fromJson(ev.payload);
          if (state.any((x) => x.id == u.id)) return;
          state = [...state, u];
        case WsEventTypes.staffUpdated:
          final u = _fromJson(ev.payload);
          state = [
            for (final x in state)
              if (x.id == u.id) u.copyWith(pin: x.pin) else x,
          ];
        case WsEventTypes.staffDeleted:
          final id = ev.payload['id'] as String?;
          if (id == null) return;
          state = [
            for (final x in state)
              if (x.id != id) x,
          ];
      }
    });
  }

  AppUser _fromJson(Map<String, dynamic> j) {
    final roleId = j['roleId'] as String?;
    return AppUser(
      id: j['id'] as String,
      name: j['name'] as String,
      initials: j['initials'] as String,
      role: _legacyRoleFor(roleId),
      shiftStartedAt: '—',
      zoneAssigned: (j['zoneAssigned'] as String?) ?? '—',
      roleId: roleId,
      // PIN is server-side hashed; never returned. Display as masked
      // unless this client just set it via setPin/resetPin.
      pin: '••••••',
      disabled: (j['disabled'] as bool?) ?? false,
      avatarColorHex: (j['avatarColorHex'] as num?)?.toInt(),
    );
  }

  UserRole _legacyRoleFor(String? roleId) {
    final id = (roleId ?? '').toLowerCase();
    if (id.contains('admin') ||
        id.contains('manager') ||
        id.contains('owner')) {
      return UserRole.admin;
    }
    if (id.contains('kitchen') || id.contains('dapur') || id.contains('cook')) {
      return UserRole.kitchen;
    }
    return UserRole.waiter;
  }

  AppUser? byId(String id) {
    for (final u in state) {
      if (u.id == id) return u;
    }
    return null;
  }

  bool _pinExists(String pin, {String? exceptId}) =>
      state.any((u) => u.pin == pin && u.id != exceptId);

  String _generateUniquePin() {
    for (var i = 0; i < 64; i++) {
      final p = (_rng.nextInt(900000) + 100000).toString();
      if (!_pinExists(p)) return p;
    }
    throw StaffException('PIN pool exhausted');
  }

  AppUser create({
    required String name,
    required String initials,
    required String roleId,
    required UserRole legacyRole,
    required int avatarColorHex,
    String? zoneAssigned,
  }) {
    final pin = _generateUniquePin();
    final user = AppUser(
      id: const Uuid().v4(),
      name: name,
      initials: initials,
      role: legacyRole,
      shiftStartedAt: '—',
      zoneAssigned: zoneAssigned ?? '—',
      roleId: roleId,
      pin: pin,
      avatarColorHex: avatarColorHex,
    );
    state = [...state, user];
    _postUser(user, pin);
    return user;
  }

  /// True when another active staff already holds [hex]. Soft check —
  /// callers warn but proceed since palette can be exhausted.
  bool avatarColorInUse(int hex, {String? exceptId}) =>
      state.any((u) => u.avatarColorHex == hex && u.id != exceptId);

  /// Returns the first palette color not already taken by another user.
  /// Falls back to the first palette color when every swatch is in use.
  int firstAvailableAvatarColor({String? exceptId}) {
    for (final c in avatarColorPalette) {
      if (!avatarColorInUse(c, exceptId: exceptId)) return c;
    }
    return avatarColorPalette.first;
  }

  void setAvatarColor(String id, int hex) {
    final prev = byId(id);
    if (prev == null || prev.avatarColorHex == hex) return;
    state = [
      for (final u in state) u.id == id ? u.copyWith(avatarColorHex: hex) : u,
    ];
    _patchUser(id, {'avatarColorHex': hex}).catchError((Object _) {
      state = [for (final u in state) u.id == id ? prev : u];
    });
  }

  Future<void> _postUser(AppUser user, String pin) async {
    final cfg = _ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      await _ref.read(apiClientProvider).postJson('/staff', {
        'id': user.id,
        'name': user.name,
        'initials': user.initials,
        'roleId': user.roleId,
        'zoneAssigned': user.zoneAssigned == '—' ? null : user.zoneAssigned,
        'pin': pin,
        'disabled': user.disabled,
        'avatarColorHex': user.avatarColorHex,
      });
    } catch (e) {
      SatLog.repo('staff.create fail $e');
      state = state.where((x) => x.id != user.id).toList();
    }
  }

  Future<void> _patchUser(String id, Map<String, dynamic> body) async {
    final cfg = _ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      await _ref.read(apiClientProvider).patchJson('/staff/$id', body);
    } catch (e) {
      SatLog.repo('staff.patch fail $e');
      rethrow;
    }
  }

  void rename(String id, String name, String initials) {
    final prev = byId(id);
    state = [
      for (final u in state)
        u.id == id ? u.copyWith(name: name, initials: initials) : u,
    ];
    _patchUser(id, {'name': name, 'initials': initials}).catchError((Object _) {
      if (prev != null) {
        state = [for (final u in state) u.id == id ? prev : u];
      }
    });
  }

  void setZone(String id, String zone) {
    final prev = byId(id);
    state = [
      for (final u in state) u.id == id ? u.copyWith(zoneAssigned: zone) : u,
    ];
    _patchUser(id, {'zoneAssigned': zone == '—' ? null : zone}).catchError((
      Object _,
    ) {
      if (prev != null) {
        state = [for (final u in state) u.id == id ? prev : u];
      }
    });
  }

  /// Reassign role; throws if it would leave zero active holders of
  /// [Capability.manageStaff] across enabled users.
  void assignRole(String id, String newRoleId) {
    final prev = byId(id);
    final next = [
      for (final u in state) u.id == id ? u.copyWith(roleId: newRoleId) : u,
    ];
    _guardLastAdminAfter(next);
    state = next;
    _patchUser(id, {'roleId': newRoleId}).catchError((Object _) {
      if (prev != null) {
        state = [for (final u in state) u.id == id ? prev : u];
      }
    });
  }

  Future<String> resetPin(String id) async {
    final pin = _generateUniquePin();
    final prev = byId(id);
    state = [for (final u in state) u.id == id ? u.copyWith(pin: pin) : u];
    try {
      // {reset: true} marker lets the server emit staffPinReset instead of
      // staffPinSet so audit trail distinguishes admin-reset from owner-set.
      await _patchUser(id, {'pin': pin, 'reset': true});
    } catch (e) {
      if (prev != null) {
        state = [for (final u in state) u.id == id ? prev : u];
      }
      throw _mapPinError(e);
    }
    return pin;
  }

  /// Set explicit PIN (validated 6 digits + unique across the venue).
  /// Local mask `••••••` never collides with a 6-digit candidate, so the
  /// server enforces the authoritative uniqueness check; we surface the
  /// 409 [`pin_in_use`] code as a [StaffException].
  Future<void> setPin(String id, String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw StaffException('PIN must be 6 digits');
    }
    if (_pinExists(pin, exceptId: id)) {
      throw StaffException('PIN already in use');
    }
    final prev = byId(id);
    state = [for (final u in state) u.id == id ? u.copyWith(pin: pin) : u];
    try {
      await _patchUser(id, {'pin': pin});
    } catch (e) {
      if (prev != null) {
        state = [for (final u in state) u.id == id ? prev : u];
      }
      throw _mapPinError(e);
    }
  }

  StaffException _mapPinError(Object e) {
    final s = e.toString();
    if (s.contains('pin_in_use')) {
      return StaffException('PIN already in use');
    }
    return StaffException('Failed to update PIN: $s');
  }

  void setDisabled(String id, bool disabled) {
    final prev = byId(id);
    final next = [
      for (final u in state) u.id == id ? u.copyWith(disabled: disabled) : u,
    ];
    if (disabled) _guardLastAdminAfter(next);
    state = next;
    _patchUser(id, {'disabled': disabled}).catchError((Object _) {
      if (prev != null) {
        state = [for (final u in state) u.id == id ? prev : u];
      }
    });
  }

  void delete(String id) {
    final next = [
      for (final u in state)
        if (u.id != id) u,
    ];
    _guardLastAdminAfter(next);
    final prev = state;
    state = next;
    final cfg = _ref.read(apiConfigProvider);
    if (cfg == null) return;
    unawaited(() async {
      try {
        await _ref.read(apiClientProvider).deleteJson('/staff/$id');
      } catch (e) {
        SatLog.repo('staff.delete fail $e');
        state = prev;
      }
    }());
  }

  /// Throw if no enabled user remains holding a role with manageStaff.
  void _guardLastAdminAfter(List<AppUser> next) {
    final adminRoleIds = <String>{
      for (final r in _ref.read(rolesRepositoryProvider))
        if (r.has(Capability.manageStaff)) r.id,
    };
    final hasAdmin = next.any(
      (u) => !u.disabled && u.roleId != null && adminRoleIds.contains(u.roleId),
    );
    if (!hasAdmin) {
      throw StaffException(
        'Must keep at least one active user with “Manage staff” capability',
      );
    }
  }

  /// Can [user] perform [c]?
  bool can(AppUser user, Capability c) {
    if (user.disabled) return false;
    final Role? r = _roles.byId(user.roleId);
    return r?.has(c) ?? false;
  }
}

final staffRepositoryProvider =
    StateNotifierProvider<StaffRepository, List<AppUser>>((ref) {
      ref.watch(apiConfigProvider);
      return StaffRepository(ref);
    });
