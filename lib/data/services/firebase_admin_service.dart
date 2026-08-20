import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/release_gate.dart';

/// Eligibility states shared by `admins/{uid}.status` and `venues/{vid}.status`.
/// Only `active` permits operation. See
/// docs/adr/0015-firebase-admin-auth-and-server-kill-switch.md and
/// docs/adr/0016-fleet-superadmin-cloud-control-plane.md.
///
/// Two states, not three: `banned` was removed in ADR-0076 because it did
/// exactly what `suspended` does to a venue, so the pair offered a
/// severity-of-tone choice at the worst possible moment. Docs still carrying it
/// parse to [unknown], which fails [isActive] — they stay blocked, no migration.
enum AdminStatus { active, suspended, unknown }

AdminStatus _parseStatus(String? raw) => switch (raw) {
  'active' => AdminStatus.active,
  'suspended' => AdminStatus.suspended,
  _ => AdminStatus.unknown,
};

/// Fleet role on `admins/{uid}.role`. A `super` admin manages the whole fleet
/// (many venues + their admins) and never runs a local server; a plain `admin`
/// runs one venue; an `owner` is a read-only cloud report viewer for one venue
/// that never pairs or runs a server. See ADR-0016, ADR-0036.
enum AdminRole { admin, superAdmin, owner }

AdminRole _parseRole(String? raw) => switch (raw) {
  'super' => AdminRole.superAdmin,
  'owner' => AdminRole.owner,
  _ => AdminRole.admin,
};

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

  /// Set by `resetAdminPassword` when the super admin mints a temporary password
  /// to dictate. While true the account holds a credential that travelled by
  /// voice, so sign-in stops before eligibility and before any server boots.
  /// See ADR-0075.
  final bool mustChangePassword;

  /// When the temporary password was minted. Paired with [mustChangePassword]
  /// to age it out — a code read aloud over the phone cannot live forever.
  final DateTime? passwordResetAt;
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
    this.mustChangePassword = false,
    this.passwordResetAt,
  });

  bool get isActive => status == AdminStatus.active;
  bool get isSuper => role == AdminRole.superAdmin;

  /// Read-only cloud report viewer (ADR-0036): diverts to `/owner`, never pairs
  /// or boots a server.
  bool get isOwner => role == AdminRole.owner;

  /// True once a temporary password has outlived [FirebaseAdminService.otpTtl].
  ///
  /// The hourly sweep re-randomizes it at Firebase, but the sweep runs on a
  /// schedule and this comparison does not — it closes the window between the
  /// code expiring and the sweep next waking up.
  bool expiredTempPassword(DateTime now) {
    if (!mustChangePassword) return false;
    final at = passwordResetAt;
    // No timestamp on a flagged account means the write half-landed. Treat it as
    // expired: refusing a code the operator can trivially re-mint is the cheaper
    // mistake.
    if (at == null) return true;
    return now.difference(at) > FirebaseAdminService.otpTtl;
  }
}

/// Snapshot of a `venues/{vid}` doc — the fleet-level record many admins share.
/// `status` is the per-venue kill switch. See ADR-0016.
class Venue {
  final String id;
  final AdminStatus status;
  final String name;
  final String address;

  /// `trial` or `partner` (ADR-0076). Kept as a String rather than an enum so a
  /// venue sitting on a pre-0076 plan renders as itself instead of being
  /// silently re-planned by the act of opening an editor.
  final String plan;

  /// When a trial began. Recorded and displayed; enforces nothing — a trial
  /// dated to start next week is active today. The end is [paidUntil].
  final DateTime? trialStartAt;

  /// The subscription term's end, for both plans. Null never lapses, so a venue
  /// created before anyone set a term sits idle instead of being cut off.
  final DateTime? paidUntil;

  /// Agreed monthly rate in whole rupiah. Partner only; a trial has no price.
  final int? priceMonthly;

  /// `monthly` or `yearly`. Yearly is two months off — see [venuePriceTotal].
  final String billingCycle;

  /// The [[Modul]] set the venue holds à la carte, beside — never inside — the
  /// plan (ADR-0107). Persisted strings; see [venueModuleKeys]. Empty means the
  /// venue holds nothing, on every plan alike (ADR-0108); read this through
  /// [hasModule] and never directly.
  final Set<String> addOns;

  /// The **[[Kedai]] mode** switches that are on (ADR-0109). Config, not
  /// entitlement: `addOns` stays a pure answer to "what may this venue have"
  /// and this answers "how is it set up". Meaningless without
  /// [modeCounterService] in [addOns], which is why [counterOn] asks for both.
  final Set<String> counterConfig;
  final DateTime? lastSeenAt;
  final bool fromCache;
  const Venue({
    required this.id,
    required this.status,
    required this.name,
    required this.address,
    required this.plan,
    required this.trialStartAt,
    required this.paidUntil,
    required this.priceMonthly,
    required this.billingCycle,
    required this.addOns,
    this.counterConfig = const {},
    required this.lastSeenAt,
    required this.fromCache,
  });

  bool get isActive => status == AdminStatus.active;
  bool get isTrial => plan == venuePlanTrial;
  bool get isYearly => billingCycle == venueCycleYearly;

  /// Whether the venue may use [key]. **The plan does not enter this answer**
  /// (ADR-0108, superseding ADR-0107 §2): a trial holds exactly what it was
  /// given, same as a partner, so the module set a sales call shapes is the one
  /// the floor renders. Provisioning still branches on the plan — a new trial is
  /// created holding everything — but that is a default, written once, not a read
  /// rule. The rule lives here and nowhere else: every other reader asks this
  /// method.
  bool hasModule(String key) => addOns.contains(key);

  /// Whether the [[Kedai]] switch [key] is on. Both halves, always: a switch
  /// left set on a venue whose mode was unticked must not reshape anything.
  bool counterOn(String key) =>
      hasModule(modeCounterService) && counterConfig.contains(key);
}

const venuePlanTrial = 'trial';
const venuePlanPartner = 'partner';
const venueCycleMonthly = 'monthly';
const venueCycleYearly = 'yearly';


/// Why a cold-boot admin session could not start. `superAdmin` means the cached
/// session belongs to a fleet operator, which never auto-boots a local server;
/// `owner` means a read-only report viewer, which diverts to `/owner` (ADR-0036).
enum AdminBootGate {
  noUser,
  ok,
  ineligible,
  staleOffline,
  superAdmin,
  owner,

  /// A temporary password is outstanding on this account (ADR-0075). The cached
  /// session is signed out rather than booted: the operator reset the credential
  /// for a reason, and a device that reboots into a running server would be the
  /// one place that reset did not reach.
  mustChangePassword,
}

class AdminBootDecision {
  final AdminBootGate gate;
  final AdminProfile? profile;
  const AdminBootDecision(this.gate, [this.profile]);
}

/// Wraps Firebase Authentication (admin email/password) and the Firestore
/// admin registry. Firebase gates *entry + eligibility*; the embedded server
/// stays the capability authority. Android-only; only exercised in Server mode.
class FirebaseAdminService {
  FirebaseAdminService({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? fb.FirebaseAuth.instance,
       _fs = firestore ?? FirebaseFirestore.instance,
       _fn = functions ?? FirebaseFunctions.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _fs;
  final FirebaseFunctions _fn;

  /// Hard block: if the listener has not confirmed `active` from the server
  /// within this window while offline, the server refuses to start.
  static const staleAfter = Duration(days: 7);

  /// How long a dictated temporary password stays usable. Must match
  /// `OTP_TTL_MS` in `functions/index.js` — the sweep kills the credential at
  /// Firebase, this refuses it here, and the two disagreeing would mean a code
  /// that the app accepts and the account no longer has. See ADR-0075.
  static const otpTtl = Duration(hours: 24);

  fb.User? get currentUser => _auth.currentUser;

  /// Current user's Firebase ID token (carries the `{role, venueId}` custom
  /// claims). Presented to a [[Main Device]] host to join as an admin-client
  /// (ADR-0017). [forceRefresh] re-mints it if claims were just updated.
  Future<String?> currentIdToken({bool forceRefresh = false}) async =>
      _auth.currentUser?.getIdToken(forceRefresh);

  Future<fb.UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> signOut() => _auth.signOut();

  /// Sets the signed-in admin's own password and clears the
  /// `mustChangePassword` flag, in one callable.
  ///
  /// Goes through a Cloud Function rather than `User.updatePassword` because the
  /// flag lives on `admins/{uid}`, which `firestore.rules` denies to every
  /// client — and splitting the two would leave a window where the password is
  /// new but the app still demands a change. Not a [FleetService] method: the
  /// caller is the subject, not the fleet operator. See ADR-0075.
  Future<void> changeOwnPassword(String password) async {
    await _fn.httpsCallable('changeOwnPassword').call<dynamic>({
      'password': password,
    });
  }

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _fs.collection('admins').doc(uid);

  DocumentReference<Map<String, dynamic>> _venueDoc(String vid) =>
      _fs.collection('venues').doc(vid);

  AdminProfile? _fromSnap(
    String uid,
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    if (!snap.exists) return null;
    final d = snap.data() ?? const {};
    return AdminProfile(
      uid: uid,
      status: _parseStatus(d['status'] as String?),
      role: _parseRole(d['role'] as String?),
      name: (d['name'] as String?)?.trim() ?? '',
      venueId: (d['venueId'] as String?)?.trim() ?? '',
      avatarColorHex: (d['avatarColorHex'] as num?)?.toInt(),
      mustChangePassword: d['mustChangePassword'] == true,
      passwordResetAt: (d['passwordResetAt'] as Timestamp?)?.toDate(),
      fromCache: snap.metadata.isFromCache,
    );
  }

  Venue? _venueFromSnap(
    String vid,
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    if (!snap.exists) return null;
    final d = snap.data() ?? const {};
    return Venue(
      id: vid,
      status: _parseStatus(d['status'] as String?),
      name: (d['name'] as String?)?.trim() ?? '',
      address: (d['address'] as String?)?.trim() ?? '',
      plan: (d['plan'] as String?)?.trim() ?? venuePlanTrial,
      trialStartAt: (d['trialStartAt'] as Timestamp?)?.toDate(),
      paidUntil: (d['paidUntil'] as Timestamp?)?.toDate(),
      priceMonthly: (d['priceMonthly'] as num?)?.toInt(),
      billingCycle: (d['billingCycle'] as String?)?.trim() ?? venueCycleMonthly,
      // Unknown keys are kept rather than dropped: a console on an older build
      // must not silently strip a module it has not heard of when it saves.
      addOns: {
        for (final m in (d['addOns'] as List<dynamic>? ?? const []))
          if (m is String && m.trim().isNotEmpty) m.trim(),
      },
      // A map on the doc, a set here: the console writes every key with an
      // explicit bool, and only the true ones are worth carrying.
      counterConfig: {
        for (final e in (d['counterConfig'] as Map<String, dynamic>? ?? const {}).entries)
          if (e.value == true) e.key,
      },
      lastSeenAt: (d['lastSeenAt'] as Timestamp?)?.toDate(),
      fromCache: snap.metadata.isFromCache,
    );
  }

  /// One-shot fetch. [serverOnly] forces a network read (throws offline);
  /// otherwise falls back to cache when offline.
  Future<AdminProfile?> fetch(String uid, {bool serverOnly = false}) async {
    final opts = GetOptions(
      source: serverOnly ? Source.server : Source.serverAndCache,
    );
    final snap = await _doc(uid).get(opts);
    return _fromSnap(uid, snap);
  }

  Future<Venue?> fetchVenue(String vid, {bool serverOnly = false}) async {
    final opts = GetOptions(
      source: serverOnly ? Source.server : Source.serverAndCache,
    );
    final snap = await _venueDoc(vid).get(opts);
    return _venueFromSnap(vid, snap);
  }

  /// Live per-operator listener (`admins/{uid}.status`).
  Stream<AdminProfile?> watch(String uid) =>
      _doc(uid).snapshots().map((s) => _fromSnap(uid, s));

  /// Live per-venue kill-switch listener (`venues/{vid}.status`). See ADR-0016.
  Stream<Venue?> watchVenue(String vid) =>
      _venueDoc(vid).snapshots().map((s) => _venueFromSnap(vid, s));

  /// Live release-gate listener (`config/release_gate`). See ADR-0087.
  ///
  /// The one document in this app that belongs to no venue and no admin — it
  /// describes which builds of SatSet the fleet may run, which is a fact about
  /// the software, not about a customer. Every signed-in admin may read it;
  /// nothing on a client writes it. Firestore's cache serves it offline exactly
  /// as it does the kill switch, so a host that has seen the gate once keeps
  /// relaying it to its clients through a WAN outage.
  Stream<ReleaseGate> watchReleaseGate() => _fs
      .collection('config')
      .doc('release_gate')
      .snapshots()
      .map(
        (s) => s.exists
            ? ReleaseGate.fromJson(s.data() ?? const {})
            : ReleaseGate.unknown,
      );

  /// Heartbeat: stamp `venues/{vid}.lastSeenAt` so the fleet console can derive
  /// offline duration. A field-scoped security rule lets a venue's own admin
  /// write ONLY this field. See ADR-0016.
  Future<void> touchVenue(String vid) =>
      _venueDoc(vid).update({'lastSeenAt': FieldValue.serverTimestamp()});

  /// Decide whether a cached Firebase session may boot the server at cold
  /// start (gated on a Firestore snapshot, with a 7-day offline staleness
  /// guard). See ADR-0015.
  Future<AdminBootDecision> evaluateForBoot(
    SecureStorageService storage,
  ) async {
    final u = currentUser;
    if (u == null) return const AdminBootDecision(AdminBootGate.noUser);

    // Try a server-confirmed read first.
    AdminProfile? server;
    try {
      server = await fetch(
        u.uid,
        serverOnly: true,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      server = null; // offline / timeout
    }
    if (server != null) {
      // A fleet operator never auto-boots a local server.
      if (server.isSuper) {
        return AdminBootDecision(AdminBootGate.superAdmin, server);
      }
      // A report owner diverts to /owner, never boots a server (ADR-0036).
      if (server.isOwner) {
        return AdminBootDecision(AdminBootGate.owner, server);
      }
      // Checked before eligibility, matching the sign-in gauntlet: an
      // outstanding temporary password is the operator saying this account's
      // credential is no longer trusted, and a device that cold-boots into a
      // running server is exactly where that would go unnoticed.
      if (server.mustChangePassword) {
        return AdminBootDecision(AdminBootGate.mustChangePassword, server);
      }
      if (!server.isActive) {
        return AdminBootDecision(AdminBootGate.ineligible, server);
      }
      // Boot also requires the venue's kill switch to be active (ADR-0016).
      final venue = server.venueId.isEmpty
          ? null
          : await fetchVenue(
              server.venueId,
              serverOnly: true,
            ).timeout(const Duration(seconds: 8)).catchError((_) => null);
      if (venue == null || !venue.isActive) {
        return AdminBootDecision(AdminBootGate.ineligible, server);
      }
      await storage.writeAdminConfirmedAt(SatClock.now());
      return AdminBootDecision(AdminBootGate.ok, server);
    }

    // Offline: fall back to the staleness guard.
    final confirmedAt = await storage.readAdminConfirmedAt();
    final fresh =
        confirmedAt != null &&
        SatClock.now().difference(confirmedAt) <= staleAfter;
    if (!fresh) {
      SatLog.repo('admin.boot stale/offline → block');
      return const AdminBootDecision(AdminBootGate.staleOffline);
    }
    final cached = await fetch(u.uid).catchError((_) => null);
    if (cached != null && cached.isSuper) {
      return AdminBootDecision(AdminBootGate.superAdmin, cached);
    }
    if (cached != null && cached.isOwner) {
      return AdminBootDecision(AdminBootGate.owner, cached);
    }
    if (cached != null && !cached.isActive) {
      return AdminBootDecision(AdminBootGate.ineligible, cached);
    }
    return AdminBootDecision(AdminBootGate.ok, cached);
  }
}

final firebaseAdminServiceProvider = Provider<FirebaseAdminService>(
  (_) => FirebaseAdminService(),
);

/// Set at cold boot when a cached admin session was blocked (`stale` |
/// `ineligible`). The PIN screen surfaces a banner; null = no block.
final adminBootBlockProvider = StateProvider<String?>((_) => null);
