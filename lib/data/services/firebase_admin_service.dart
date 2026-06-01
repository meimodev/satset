import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/services/secure_storage_service.dart';

/// Eligibility states shared by `admins/{uid}.status` and `venues/{vid}.status`.
/// Only `active` permits operation. See
/// docs/adr/0015-firebase-admin-auth-and-server-kill-switch.md and
/// docs/adr/0016-fleet-superadmin-cloud-control-plane.md.
enum AdminStatus { active, suspended, banned, unknown }

AdminStatus _parseStatus(String? raw) => switch (raw) {
      'active' => AdminStatus.active,
      'suspended' => AdminStatus.suspended,
      'banned' => AdminStatus.banned,
      _ => AdminStatus.unknown,
    };

/// Fleet role on `admins/{uid}.role`. A `super` admin manages the whole fleet
/// (many venues + their admins) and never runs a local server; a plain `admin`
/// runs one venue. See ADR-0016.
enum AdminRole { admin, superAdmin }

AdminRole _parseRole(String? raw) =>
    raw == 'super' ? AdminRole.superAdmin : AdminRole.admin;

/// Snapshot of an admin's `admins/{uid}` doc. `fromCache` distinguishes a
/// server-confirmed read from a locally-cached one (drives the staleness guard).
class AdminProfile {
  final String uid;
  final AdminStatus status;
  final AdminRole role;
  final String name;

  /// The venue this admin belongs to (one venue → many admins). Empty for a
  /// super admin, who has no venue of its own.
  final String venueId;
  final int? avatarColorHex;

  /// Only populated by the fleet console read (`admins/{uid}.email`); null on
  /// the self-eligibility read, which doesn't need it.
  final String? email;
  final bool fromCache;
  const AdminProfile({
    required this.uid,
    required this.status,
    required this.role,
    required this.name,
    required this.venueId,
    required this.avatarColorHex,
    required this.fromCache,
    this.email,
  });

  bool get isActive => status == AdminStatus.active;
  bool get isSuper => role == AdminRole.superAdmin;
}

/// Snapshot of a `venues/{vid}` doc — the fleet-level record many admins share.
/// `status` is the per-venue kill switch. See ADR-0016.
class Venue {
  final String id;
  final AdminStatus status;
  final String name;
  final String address;
  final String plan;
  final String billingStatus;
  final DateTime? paidUntil;
  final DateTime? lastSeenAt;
  final bool fromCache;
  const Venue({
    required this.id,
    required this.status,
    required this.name,
    required this.address,
    required this.plan,
    required this.billingStatus,
    required this.paidUntil,
    required this.lastSeenAt,
    required this.fromCache,
  });

  bool get isActive => status == AdminStatus.active;
}

/// Why a cold-boot admin session could not start. `superAdmin` means the cached
/// session belongs to a fleet operator, which never auto-boots a local server.
enum AdminBootGate { noUser, ok, ineligible, staleOffline, superAdmin }

class AdminBootDecision {
  final AdminBootGate gate;
  final AdminProfile? profile;
  const AdminBootDecision(this.gate, [this.profile]);
}

/// Wraps Firebase Authentication (admin email/password) and the Firestore
/// admin registry. Firebase gates *entry + eligibility*; the embedded server
/// stays the capability authority. Android-only; only exercised in Server mode.
class FirebaseAdminService {
  FirebaseAdminService({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _fs = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _fs;

  /// Hard block: if the listener has not confirmed `active` from the server
  /// within this window while offline, the server refuses to start.
  static const staleAfter = Duration(days: 7);

  fb.User? get currentUser => _auth.currentUser;

  Future<fb.UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _fs.collection('admins').doc(uid);

  DocumentReference<Map<String, dynamic>> _venueDoc(String vid) =>
      _fs.collection('venues').doc(vid);

  AdminProfile? _fromSnap(
      String uid, DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists) return null;
    final d = snap.data() ?? const {};
    return AdminProfile(
      uid: uid,
      status: _parseStatus(d['status'] as String?),
      role: _parseRole(d['role'] as String?),
      name: (d['name'] as String?)?.trim() ?? '',
      venueId: (d['venueId'] as String?)?.trim() ?? '',
      avatarColorHex: (d['avatarColorHex'] as num?)?.toInt(),
      fromCache: snap.metadata.isFromCache,
    );
  }

  Venue? _venueFromSnap(
      String vid, DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists) return null;
    final d = snap.data() ?? const {};
    return Venue(
      id: vid,
      status: _parseStatus(d['status'] as String?),
      name: (d['name'] as String?)?.trim() ?? '',
      address: (d['address'] as String?)?.trim() ?? '',
      plan: (d['plan'] as String?)?.trim() ?? 'free',
      billingStatus: (d['billingStatus'] as String?)?.trim() ?? 'trial',
      paidUntil: (d['paidUntil'] as Timestamp?)?.toDate(),
      lastSeenAt: (d['lastSeenAt'] as Timestamp?)?.toDate(),
      fromCache: snap.metadata.isFromCache,
    );
  }

  /// One-shot fetch. [serverOnly] forces a network read (throws offline);
  /// otherwise falls back to cache when offline.
  Future<AdminProfile?> fetch(String uid, {bool serverOnly = false}) async {
    final opts = GetOptions(
        source: serverOnly ? Source.server : Source.serverAndCache);
    final snap = await _doc(uid).get(opts);
    return _fromSnap(uid, snap);
  }

  Future<Venue?> fetchVenue(String vid, {bool serverOnly = false}) async {
    final opts = GetOptions(
        source: serverOnly ? Source.server : Source.serverAndCache);
    final snap = await _venueDoc(vid).get(opts);
    return _venueFromSnap(vid, snap);
  }

  /// Live per-operator listener (`admins/{uid}.status`).
  Stream<AdminProfile?> watch(String uid) =>
      _doc(uid).snapshots().map((s) => _fromSnap(uid, s));

  /// Live per-venue kill-switch listener (`venues/{vid}.status`). See ADR-0016.
  Stream<Venue?> watchVenue(String vid) =>
      _venueDoc(vid).snapshots().map((s) => _venueFromSnap(vid, s));

  /// Heartbeat: stamp `venues/{vid}.lastSeenAt` so the fleet console can derive
  /// offline duration. A field-scoped security rule lets a venue's own admin
  /// write ONLY this field. See ADR-0016.
  Future<void> touchVenue(String vid) =>
      _venueDoc(vid).update({'lastSeenAt': FieldValue.serverTimestamp()});

  /// Decide whether a cached Firebase session may boot the server at cold
  /// start (gated on a Firestore snapshot, with a 7-day offline staleness
  /// guard). See ADR-0015.
  Future<AdminBootDecision> evaluateForBoot(SecureStorageService storage) async {
    final u = currentUser;
    if (u == null) return const AdminBootDecision(AdminBootGate.noUser);

    // Try a server-confirmed read first.
    AdminProfile? server;
    try {
      server = await fetch(u.uid, serverOnly: true)
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      server = null; // offline / timeout
    }
    if (server != null) {
      // A fleet operator never auto-boots a local server.
      if (server.isSuper) {
        return AdminBootDecision(AdminBootGate.superAdmin, server);
      }
      if (!server.isActive) {
        return AdminBootDecision(AdminBootGate.ineligible, server);
      }
      // Boot also requires the venue's kill switch to be active (ADR-0016).
      final venue = server.venueId.isEmpty
          ? null
          : await fetchVenue(server.venueId, serverOnly: true)
              .timeout(const Duration(seconds: 8))
              .catchError((_) => null);
      if (venue == null || !venue.isActive) {
        return AdminBootDecision(AdminBootGate.ineligible, server);
      }
      await storage.writeAdminConfirmedAt(DateTime.now());
      return AdminBootDecision(AdminBootGate.ok, server);
    }

    // Offline: fall back to the staleness guard.
    final confirmedAt = await storage.readAdminConfirmedAt();
    final fresh = confirmedAt != null &&
        DateTime.now().difference(confirmedAt) <= staleAfter;
    if (!fresh) {
      SatLog.repo('admin.boot stale/offline → block');
      return const AdminBootDecision(AdminBootGate.staleOffline);
    }
    final cached = await fetch(u.uid).catchError((_) => null);
    if (cached != null && cached.isSuper) {
      return AdminBootDecision(AdminBootGate.superAdmin, cached);
    }
    if (cached != null && !cached.isActive) {
      return AdminBootDecision(AdminBootGate.ineligible, cached);
    }
    return AdminBootDecision(AdminBootGate.ok, cached);
  }
}

final firebaseAdminServiceProvider =
    Provider<FirebaseAdminService>((_) => FirebaseAdminService());

/// Set at cold boot when a cached admin session was blocked (`stale` |
/// `ineligible`). The PIN screen surfaces a banner; null = no block.
final adminBootBlockProvider = StateProvider<String?>((_) => null);
