import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/services/dummy_data_seed.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/role.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/models/zone.dart';

/// Stateless wrapper around the in-memory seed.
/// Repositories consume this, never the seed class directly.
class DummyDataService {
  const DummyDataService();

  List<AppUser> users() => DummyData.users;
  AppUser? userById(String? id) => DummyData.userById(id);
  AppUser get defaultSignInUser => DummyData.maya;
  List<Role> initialRoles() => DummyData.initialRoles();

  List<Zone> initialZones() => List.of(DummyData.zones);
  List<VenueTable> initialTables() => List.of(DummyData.tables);
  Map<String, List<Ticket>> initialTicketsByTable() =>
      DummyData.initialTicketsByTable();
  List<AuditEntry> initialAudit() => DummyData.initialAudit();

  List<MenuCategory> categories() => DummyData.categories;
  List<MenuItem> items() => DummyData.items;
  MenuItem itemById(String id) => DummyData.itemById(id);

  String get venueName => Venue.name;
  String get venueAddress => Venue.address;
}

final dummyDataServiceProvider =
    Provider<DummyDataService>((ref) => const DummyDataService());
