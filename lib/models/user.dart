class AppUser {
  final String id;
  final String name;
  final String initials;
  final String role;
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
