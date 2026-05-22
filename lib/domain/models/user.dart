enum UserRole { waiter, kitchen, admin }

class AppUser {
  final String id;
  final String name;
  final String initials;
  final UserRole role;
  final String shiftStartedAt;
  final String zoneAssigned;
  final String? roleId;
  final String pin;
  final bool onDuty;
  final bool disabled;

  const AppUser({
    required this.id,
    required this.name,
    required this.initials,
    required this.role,
    required this.shiftStartedAt,
    required this.zoneAssigned,
    this.roleId,
    this.pin = '000000',
    this.onDuty = true,
    this.disabled = false,
  });

  AppUser copyWith({
    String? name,
    String? initials,
    UserRole? role,
    String? shiftStartedAt,
    String? zoneAssigned,
    String? roleId,
    String? pin,
    bool? onDuty,
    bool? disabled,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        initials: initials ?? this.initials,
        role: role ?? this.role,
        shiftStartedAt: shiftStartedAt ?? this.shiftStartedAt,
        zoneAssigned: zoneAssigned ?? this.zoneAssigned,
        roleId: roleId ?? this.roleId,
        pin: pin ?? this.pin,
        onDuty: onDuty ?? this.onDuty,
        disabled: disabled ?? this.disabled,
      );
}

String userRoleLabel(UserRole r) => switch (r) {
      UserRole.waiter => 'Pelayan',
      UserRole.kitchen => 'Dapur',
      UserRole.admin => 'Admin',
    };
