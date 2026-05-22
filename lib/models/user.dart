enum UserRole { waiter, kitchen, admin }

class AppUser {
  final String id;
  final String name;
  final String initials;
  final UserRole role;
  final String shiftStartedAt;
  final String zoneAssigned;
  const AppUser({
    required this.id,
    required this.name,
    required this.initials,
    required this.role,
    required this.shiftStartedAt,
    required this.zoneAssigned,
  });
}

String userRoleLabel(UserRole r) => switch (r) {
      UserRole.waiter => 'Pelayan',
      UserRole.kitchen => 'Dapur',
      UserRole.admin => 'Admin',
    };
