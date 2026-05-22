import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/repositories/roles_repository.dart';
import 'package:satset/data/services/dummy_data_service.dart';
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

class StaffRepository extends StateNotifier<List<AppUser>> {
  StaffRepository(this._ref, DummyDataService seed) : super(seed.users());

  final Ref _ref;
  final _rng = Random();

  RolesRepository get _roles =>
      _ref.read(rolesRepositoryProvider.notifier);

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
      onDuty: false,
    );
    state = [...state, user];
    return user;
  }

  void rename(String id, String name, String initials) {
    state = [
      for (final u in state)
        u.id == id ? u.copyWith(name: name, initials: initials) : u,
    ];
  }

  void setZone(String id, String zone) {
    state = [
      for (final u in state) u.id == id ? u.copyWith(zoneAssigned: zone) : u,
    ];
  }

  void toggleOnDuty(String id) {
    state = [
      for (final u in state) u.id == id ? u.copyWith(onDuty: !u.onDuty) : u,
    ];
  }

  /// Reassign role; throws if it would leave zero active holders of
  /// [Capability.manageStaff] across enabled users.
  void assignRole(String id, String newRoleId) {
    final next = [
      for (final u in state) u.id == id ? u.copyWith(roleId: newRoleId) : u,
    ];
    _guardLastAdminAfter(next);
    state = next;
  }

  String resetPin(String id) {
    final pin = _generateUniquePin();
    state = [
      for (final u in state) u.id == id ? u.copyWith(pin: pin) : u,
    ];
    return pin;
  }

  /// Set explicit PIN (validated 6 digits + unique).
  void setPin(String id, String pin) {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw StaffException('PIN must be 6 digits');
    }
    if (_pinExists(pin, exceptId: id)) {
      throw StaffException('PIN already in use');
    }
    state = [
      for (final u in state) u.id == id ? u.copyWith(pin: pin) : u,
    ];
  }

  void setDisabled(String id, bool disabled) {
    final next = [
      for (final u in state) u.id == id ? u.copyWith(disabled: disabled) : u,
    ];
    if (disabled) _guardLastAdminAfter(next);
    state = next;
  }

  void delete(String id) {
    final next = [
      for (final u in state)
        if (u.id != id) u,
    ];
    _guardLastAdminAfter(next);
    state = next;
  }

  /// Throw if no enabled user remains holding a role with manageStaff.
  void _guardLastAdminAfter(List<AppUser> next) {
    final adminRoleIds = <String>{
      for (final r in _ref.read(rolesRepositoryProvider))
        if (r.has(Capability.manageStaff)) r.id,
    };
    final hasAdmin = next.any((u) =>
        !u.disabled && u.roleId != null && adminRoleIds.contains(u.roleId));
    if (!hasAdmin) {
      throw StaffException(
          'Must keep at least one active user with “Manage staff” capability');
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
    StateNotifierProvider<StaffRepository, List<AppUser>>(
        (ref) => StaffRepository(ref, ref.watch(dummyDataServiceProvider)));
