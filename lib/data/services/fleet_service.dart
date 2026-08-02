import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/services/firebase_admin_service.dart';

/// Cloud control plane for the super admin. READS go straight to Firestore
/// (gated by the `isSuper()` security rule); MUTATIONS go through Cloud
/// Functions callables (Admin SDK, server-enforced authz). The client never
/// writes admins/venues directly. See ADR-0016.
class FleetService {
  FleetService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _fs = firestore ?? FirebaseFirestore.instance,
      _fn = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _fs;
  final FirebaseFunctions _fn;

  // ── Reads (live) ───────────────────────────────────────────────────────────

  /// `includeMetadataChanges` is load-bearing, not a tuning knob. Firestore
  /// persistence is on by default on Android, so the listener delivers the
  /// cached snapshot first (`isFromCache: true`) and the server's answer
  /// second — and when the documents are unchanged that second delivery is a
  /// *metadata-only* change, which the default listener suppresses. `fromCache`
  /// then stays true forever, [fleetOfflineProvider] latches, and every
  /// mutation on both fleet screens is disabled for the life of the session.
  Stream<List<Venue>> watchVenues() => _fs
      .collection('venues')
      .snapshots(includeMetadataChanges: true)
      .map((q) => [for (final d in q.docs) _venue(d)]);

  Stream<List<AdminProfile>> watchAdmins() => _fs
      .collection('admins')
      .snapshots(includeMetadataChanges: true)
      .map((q) => [for (final d in q.docs) _admin(d)]);

  Venue _venue(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Venue(
      id: d.id,
      status: _status(m['status'] as String?),
      name: (m['name'] as String?)?.trim() ?? '',
      address: (m['address'] as String?)?.trim() ?? '',
      plan: (m['plan'] as String?)?.trim() ?? venuePlanTrial,
      trialStartAt: (m['trialStartAt'] as Timestamp?)?.toDate(),
      paidUntil: (m['paidUntil'] as Timestamp?)?.toDate(),
      priceMonthly: (m['priceMonthly'] as num?)?.toInt(),
      billingCycle:
          (m['billingCycle'] as String?)?.trim() ?? venueCycleMonthly,
      lastSeenAt: (m['lastSeenAt'] as Timestamp?)?.toDate(),
      fromCache: d.metadata.isFromCache,
    );
  }

  AdminProfile _admin(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return AdminProfile(
      uid: d.id,
      status: _status(m['status'] as String?),
      role: switch (m['role'] as String?) {
        'super' => AdminRole.superAdmin,
        'owner' => AdminRole.owner,
        _ => AdminRole.admin,
      },
      name: (m['name'] as String?)?.trim() ?? '',
      venueId: (m['venueId'] as String?)?.trim() ?? '',
      avatarColorHex: (m['avatarColorHex'] as num?)?.toInt(),
      email: (m['email'] as String?)?.trim(),
      fromCache: d.metadata.isFromCache,
    );
  }

  static AdminStatus _status(String? raw) => switch (raw) {
    'active' => AdminStatus.active,
    'suspended' => AdminStatus.suspended,
    _ => AdminStatus.unknown,
  };

  // ── Mutations (callables) ───────────────────────────────────────────────────

  /// Creates a venue with a plan and nothing else. Term and price are the
  /// editor's job (ADR-0076) — two places that can set a term are two places
  /// that will drift. A `trial` is stamped `trialStartAt` server-side.
  Future<String> createVenue({
    required String name,
    String address = '',
    String plan = venuePlanTrial,
  }) async {
    final r = await _call('createVenue', {
      'name': name,
      'address': address,
      'plan': plan,
    });
    return (r['vid'] as String?) ?? '';
  }

  Future<void> updateVenue(String vid, {String? name, String? address}) =>
      _call('updateVenue', {'vid': vid, 'name': ?name, 'address': ?address});

  /// The kill switch.
  Future<void> setVenueStatus(String vid, AdminStatus status) =>
      _call('setVenueStatus', {'vid': vid, 'status': _statusKey(status)});

  /// Nulls are "leave alone", so clearing a nullable field needs its own flag —
  /// the alternative is a patch that cannot distinguish "no opinion" from
  /// "remove this", which on `paidUntil` is the difference between leaving a
  /// term standing and handing a venue an unlimited one.
  Future<void> setVenueBilling(
    String vid, {
    String? plan,
    DateTime? trialStartAt,
    bool clearTrialStartAt = false,
    DateTime? paidUntil,
    bool clearPaidUntil = false,
    int? priceMonthly,
    bool clearPriceMonthly = false,
    String? billingCycle,
  }) => _call('setVenueBilling', {
    'vid': vid,
    'plan': ?plan,
    'billingCycle': ?billingCycle,
    if (clearTrialStartAt)
      'trialStartAt': null
    else if (trialStartAt != null)
      'trialStartAt': trialStartAt.millisecondsSinceEpoch,
    if (clearPaidUntil)
      'paidUntil': null
    else if (paidUntil != null)
      'paidUntil': paidUntil.millisecondsSinceEpoch,
    if (clearPriceMonthly) 'priceMonthly': null else 'priceMonthly': ?priceMonthly,
  });

  Future<void> deleteVenue(String vid) => _call('deleteVenue', {'vid': vid});

  /// Creates a venue principal. [role] is `admin` (default) or `owner` — the
  /// read-only cloud report viewer (ADR-0036). `super` is seeded by hand.
  Future<String> createAdmin({
    required String email,
    required String password,
    required String name,
    required String venueId,
    String role = 'admin',
  }) async {
    final r = await _call('createAdmin', {
      'email': email,
      'password': password,
      'name': name,
      'venueId': venueId,
      'role': role,
    });
    return (r['uid'] as String?) ?? '';
  }

  Future<void> setAdminStatus(String uid, AdminStatus status) =>
      _call('setAdminStatus', {'uid': uid, 'status': _statusKey(status)});

  Future<void> deleteAdmin(String uid) => _call('deleteAdmin', {'uid': uid});

  /// Mints a temporary password for [uid] and returns the digits for the
  /// operator to dictate. Shown once and never retrievable again — the callable
  /// stores only a hash-free flag, and the audit row records the email and not
  /// the code. See ADR-0075.
  ///
  /// Keyed on `uid` rather than the email it used to take: the email is a field
  /// on the doc that this callable has to read anyway, and identifying an
  /// account to reset by a mutable, non-unique-by-construction string was one
  /// typo away from resetting the wrong venue's admin.
  Future<String?> resetAdminPassword(String uid) async {
    final r = await _call('resetAdminPassword', {'uid': uid});
    return r['otp'] as String?;
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> args,
  ) async {
    final res = await _fn.httpsCallable(name).call<dynamic>(args);
    final data = res.data;
    return data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
  }

  static String _statusKey(AdminStatus s) => switch (s) {
    AdminStatus.active => 'active',
    AdminStatus.suspended || AdminStatus.unknown => 'suspended',
  };
}

final fleetServiceProvider = Provider<FleetService>((_) => FleetService());

/// Live fleet venues for the console.
final fleetVenuesProvider = StreamProvider<List<Venue>>(
  (ref) => ref.watch(fleetServiceProvider).watchVenues(),
);

/// Live fleet admins for the console.
final fleetAdminsProvider = StreamProvider<List<AdminProfile>>(
  (ref) => ref.watch(fleetServiceProvider).watchAdmins(),
);

/// Wall-clock tick driving the console's offline / lockout readouts.
///
/// Those are `now − lastSeenAt`, computed during build — and the venue that has
/// gone dark is exactly the one that stops writing, so Firestore pushes no
/// snapshot and nothing rebuilds. Without this the tile of a venue that just
/// died keeps reading "Online" for as long as the screen stays open, and the
/// urgency sort freezes with it.
final fleetTickProvider = StreamProvider<DateTime>(
  (ref) => Stream<DateTime>.periodic(
    const Duration(seconds: 30),
    (_) => SatClock.now(),
  ),
);

/// True while the fleet is being served from Firestore's local cache rather
/// than the server. The super admin is online-only (ADR-0016): there is no
/// local server behind this screen, so cached venues are a picture of the past
/// and every mutation would fail. Drives the banner + the mutation lock.
final fleetOfflineProvider = Provider<bool>((ref) {
  final venues = ref.watch(fleetVenuesProvider).valueOrNull;
  return venues != null && venues.any((v) => v.fromCache);
});
