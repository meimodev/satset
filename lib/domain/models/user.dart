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
  final bool disabled;

  /// Per-account avatar background color (0xAARRGGBB). Soft-unique across
  /// the venue: clients warn on collision but server accepts duplicates.
  /// Nullable for legacy rows pre-backfill — UI falls back to role color.
  final int? avatarColorHex;

  const AppUser({
    required this.id,
    required this.name,
    required this.initials,
    required this.role,
    required this.shiftStartedAt,
    required this.zoneAssigned,
    this.roleId,
    this.pin = '000000',
    this.disabled = false,
    this.avatarColorHex,
  });

  AppUser copyWith({
    String? name,
    String? initials,
    UserRole? role,
    String? shiftStartedAt,
    String? zoneAssigned,
    String? roleId,
    String? pin,
    bool? disabled,
    int? avatarColorHex,
  }) => AppUser(
    id: id,
    name: name ?? this.name,
    initials: initials ?? this.initials,
    role: role ?? this.role,
    shiftStartedAt: shiftStartedAt ?? this.shiftStartedAt,
    zoneAssigned: zoneAssigned ?? this.zoneAssigned,
    roleId: roleId ?? this.roleId,
    pin: pin ?? this.pin,
    disabled: disabled ?? this.disabled,
    avatarColorHex: avatarColorHex ?? this.avatarColorHex,
  );
}

/// Fixed 12-swatch palette for per-account avatar background colors.
/// Index alignment matters: backfill migration assigns by index, seed users
/// reference these constants by index, so reordering changes assignments
/// across upgrades. Append to the end if extending.
const List<int> avatarColorPalette = <int>[
  0xFFC08AFF, // violet
  0xFF6DB5FF, // sky
  0xFF4DD487, // mint
  0xFFFF9233, // orange
  0xFFFFC04D, // amber
  0xFFFF5C5C, // coral
  0xFF7ED6C4, // teal
  0xFFE48BB7, // rose
  0xFFA1D26A, // lime
  0xFF8D9DFF, // periwinkle
  0xFFD4A373, // tan
  0xFF9F5BFF, // grape
];

String userRoleLabel(UserRole r) => switch (r) {
  UserRole.waiter => 'Pelayan',
  UserRole.kitchen => 'Dapur',
  UserRole.admin => 'Admin',
};
