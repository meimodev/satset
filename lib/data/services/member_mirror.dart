/// The client half of the [[Salinan pelanggan]] (ADR-0129).
///
/// Two jobs, deliberately in one file because they share one invariant — *what
/// is on this device is what the host said, and it knows when it was said*:
///
/// - **the store**: upsert, forget, search, and the timestamp every stale
///   figure renders beside;
/// - **the sync**: drain `/members/sync` from the cursor this device holds
///   until the host says there is no more, on connect and on reconnect.
///
/// It never writes a member. Enrolment, edits and points go where they always
/// went — through `MembersRepository` online, or the [[Antrean setelmen]] when
/// the host is gone. A mirror that could be edited locally would be a second
/// directory, and ADR-0092 allows exactly one.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/db/client_db.dart';
import 'package:satset/data/models/member_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/settlement_sync.dart' show clientDbProvider;
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/member.dart';

/// One mirrored member, and when the host last vouched for it.
///
/// The stamp travels with the row rather than being asked of the store,
/// because a screen renders one member at a time and the caveat belongs beside
/// the number it qualifies (ADR-0129).
typedef MirroredMember = ({MemberDto member, DateTime syncedAt, bool masked});

/// The mask salt, kept out of the sqlite file on purpose.
///
/// A phone number space is small enough to walk end to end, so an unsalted
/// digest is not a mask. Keeping the salt in the platform keystore is what
/// makes a pulled database file insufficient on its own.
const _kSaltKey = 'satset.member_mirror_salt';

class MemberMirror {
  MemberMirror(this._db, this._prefs, this._secure);

  final ClientDb _db;
  final PrefsService _prefs;
  final FlutterSecureStorage _secure;

  String? _salt;

  /// Read once and held: search hashes on every keystroke, and a keystore read
  /// per keystroke is a visible stutter on a cheap handset.
  Future<String?> _saltOnce() async {
    if (_salt != null) return _salt;
    _salt = await _secure.read(key: _kSaltKey);
    return _salt;
  }

  Future<void> _writeSalt(String salt) async {
    _salt = salt;
    await _secure.write(key: _kSaltKey, value: salt);
  }

  /// Where the device resumes. Opaque — minted by the host, never parsed here.
  String? cursor() => _prefs.memberMirrorCursor();

  /// When the host last vouched for anything here. Null on an empty mirror.
  Future<DateTime?> syncedAt() async {
    final row =
        await (_db.select(_db.cachedMembers)
              ..orderBy([(m) => OrderingTerm.desc(m.syncedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.syncedAt;
  }

  Future<int> count() async {
    final rows = await _db.select(_db.cachedMembers).get();
    return rows.length;
  }

  /// Everything the device knows, newest-synced first, for a directory that
  /// opened with no query.
  Future<List<MirroredMember>> all({int limit = 100}) async {
    final rows =
        await (_db.select(_db.cachedMembers)
              ..orderBy([(m) => OrderingTerm.asc(m.name)])
              ..limit(limit))
            .get();
    return [for (final r in rows) _hydrate(r)];
  }

  /// The offline half of the till's lookup: a name substring, a number prefix,
  /// or — on a masked mirror — the **whole** number, matched by hash.
  ///
  /// A masked device can only answer the whole number, which is the honest
  /// consequence of not holding it: a prefix search over digests is not a
  /// thing. The name search is unaffected, and that is what the sheet leads
  /// with anyway.
  Future<List<MirroredMember>> search(String query, {int limit = 50}) async {
    final q = query.trim();
    if (q.isEmpty) return all(limit: limit);
    final digits = normalizePhone(q);
    final salt = await _saltOnce();
    final hash = (salt == null || digits.length < 6)
        ? null
        : memberPhoneHash(digits, salt);
    final rows =
        await (_db.select(_db.cachedMembers)
              ..where(
                (m) =>
                    m.name.lower().contains(q.toLowerCase()) |
                    (digits.isEmpty
                        ? const Constant(false)
                        : m.phone.like('$digits%')) |
                    (hash == null
                        ? const Constant(false)
                        : m.phoneHash.equals(hash)),
              )
              ..orderBy([(m) => OrderingTerm.asc(m.name)])
              ..limit(limit))
            .get();
    return [for (final r in rows) _hydrate(r)];
  }

  Future<MirroredMember?> byId(String id) async {
    final row = await (_db.select(
      _db.cachedMembers,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    return row == null ? null : _hydrate(row);
  }

  MirroredMember _hydrate(CachedMemberRow r) => (
    member: MemberDto.fromJson(
      (jsonDecode(r.payloadJson) as Map).cast<String, dynamic>(),
    ),
    syncedAt: r.syncedAt,
    masked: r.phone.isEmpty,
  );

  /// Put a member the device just enrolled offline into the mirror, so the
  /// cashier can attach the person standing in front of them (ADR-0129).
  ///
  /// The **one** local write, and it is not an edit: it is the row the host
  /// will send back anyway, written early so the next screen is not empty. It
  /// is stamped `syncedAt` now and therefore renders with a fresh caveat,
  /// which is true — the device does vouch for it, having just been told.
  ///
  /// A drain that folds this into a standing record replaces it: the fold's
  /// winner arrives on the next sync page and the loser arrives as a
  /// tombstone.
  Future<void> insertLocal({
    required String id,
    required String name,
    required String phone,
    String? note,
    DateTime? birthday,
    MemberAddress address = const MemberAddress(),
  }) async {
    final salt = await _saltOnce();
    final digits = normalizePhone(phone);
    // Built here rather than round-tripped through `MemberDto`, because every
    // derived figure is the host's to compute and this row has none yet: a
    // member enrolled thirty seconds ago has no points, no visits and no debt,
    // and those zeroes are true rather than assumed (ADR-0092).
    final payload = <String, dynamic>{
      'id': id,
      'name': name,
      'phone': salt == null ? digits : '',
      'code': digits.length <= 6 ? digits : digits.substring(digits.length - 6),
      'note': note,
      'birthday': birthday?.toIso8601String(),
      'address': address.toJson(),
      'joinedAt': SatClock.now().toIso8601String(),
      'points': 0,
      'punchProgress': 0,
      'visitCount': 0,
      'lifetimeSpend': 0,
      'debt': 0,
      'debtLimit': 0,
    };
    await _db
        .into(_db.cachedMembers)
        .insertOnConflictUpdate(
          CachedMembersCompanion.insert(
            id: id,
            name: name,
            // A masked device stores no number, the same offline as online —
            // enrolling a member is not a way to acquire one.
            phone: Value(salt == null ? digits : ''),
            phoneHash: Value(salt == null ? '' : memberPhoneHash(digits, salt)),
            phoneTail: Value(
              digits.length <= 4 ? digits : digits.substring(digits.length - 4),
            ),
            code: Value(payload['code'] as String),
            payloadJson: jsonEncode(payload),
            syncedAt: SatClock.now(),
          ),
        );
  }

  /// Throw the whole mirror away.
  ///
  /// Called on unpair and when a config names a **different certificate** —
  /// never on sign-out. Shift change is constant, and a mirror that cannot
  /// refill while dark is a feature that deletes itself on the device that
  /// needs it (ADR-0129).
  Future<void> wipe() async {
    await _db.delete(_db.cachedMembers).go();
    await _prefs.clearMemberMirrorMeta();
    await _secure.delete(key: _kSaltKey);
    _salt = null;
    SatLog.repo('memberMirror.wiped');
  }

  /// Drop the mirror if it came from another venue, and stamp it if it has no
  /// label yet. Unstamped reads as *unknown*, never as *foreign* — an upgrade
  /// must not throw away a copy it merely cannot vouch for.
  Future<void> reconcileVenue(String fingerprint) async {
    if (fingerprint.isEmpty) return;
    final stamped = _prefs.memberMirrorFingerprint();
    if (stamped == null || stamped.isEmpty) {
      await _prefs.setMemberMirrorFingerprint(fingerprint);
      return;
    }
    if (stamped == fingerprint) return;
    SatLog.repo('memberMirror.foreign — dropping');
    await wipe();
    await _prefs.setMemberMirrorFingerprint(fingerprint);
  }

  /// Apply one page from `/members/sync`.
  Future<void> applyPage(Map<String, dynamic> page) async {
    final now = SatClock.now();
    final masked = page['masked'] == true;
    if (masked) {
      final salt = page['salt'] as String?;
      if (salt != null && salt.isNotEmpty) await _writeSalt(salt);
    }
    final members = (page['members'] as List? ?? const []);
    final gone = (page['gone'] as List? ?? const []);
    await _db.batch((b) {
      for (final raw in members) {
        final m = (raw as Map).cast<String, dynamic>();
        b.insert(
          _db.cachedMembers,
          CachedMembersCompanion.insert(
            id: m['id'] as String,
            name: (m['name'] as String?) ?? '',
            phone: Value((m['phone'] as String?) ?? ''),
            phoneHash: Value((m['phoneHash'] as String?) ?? ''),
            phoneTail: Value((m['phoneTail'] as String?) ?? ''),
            code: Value((m['code'] as String?) ?? ''),
            payloadJson: jsonEncode(m),
            syncedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
      for (final raw in gone) {
        final t = (raw as Map).cast<String, dynamic>();
        b.deleteWhere(
          _db.cachedMembers,
          ($CachedMembersTable m) => m.id.equals(t['id'] as String),
        );
      }
    });
    await _prefs.setMemberMirrorCursor(page['cursor'] as String?);
  }
}

/// Where a member id points **now**, after a fold or a merge took the one this
/// device was holding (ADR-0129).
///
/// Returned by a drain rather than looked up: the host is the only thing that
/// knows a fold happened, and the device has to rewrite whatever it queued
/// behind the enrolment.
typedef MemberRedirect = ({String from, String to});

final memberMirrorProvider = Provider<MemberMirror?>((ref) {
  final prefs = ref.watch(prefsServiceProvider).valueOrNull;
  if (prefs == null) return null;
  return MemberMirror(
    ref.watch(clientDbProvider),
    prefs,
    const FlutterSecureStorage(),
  );
});

/// Fills the mirror and keeps it filled.
///
/// Subscribed by `AppShell`, beside the send-queue drain — the mirror's whole
/// value is being *already there* when the host goes away, so nothing may wait
/// for a screen to open it (the mistake ADR-0128 fixed for [[Preset diskon]]).
class MemberMirrorSync {
  MemberMirrorSync(this._ref) {
    _wire();
  }

  final Ref _ref;
  bool _syncing = false;

  void _wire() {
    _ref.listen<WsConnState>(wsConnStateProvider, (prev, next) {
      // Refetch on `connected`, not on an edit broadcast: a device that cold
      // booted dark has an old cursor and no edit is coming for the rows it
      // missed (ADR-0128's second hole, same shape).
      if (next == WsConnState.open) sync();
    });
    _ref.listen<ApiConfig?>(apiConfigProvider, (prev, next) {
      if (next != null) sync();
    });
    if (_ref.read(apiConfigProvider) != null) sync();
  }

  /// Drain every waiting page, then stop. Re-entrant calls are dropped rather
  /// than queued: the next `connected` will bring us back, and two overlapping
  /// drains would race on one cursor.
  Future<void> sync() async {
    if (_syncing) return;
    final mirror = _ref.read(memberMirrorProvider);
    final cfg = _ref.read(apiConfigProvider);
    if (mirror == null || cfg == null) return;
    _syncing = true;
    try {
      await mirror.reconcileVenue(cfg.trustedFingerprint);
      var pages = 0;
      while (pages < _kMaxPagesPerRun) {
        final cursor = mirror.cursor();
        final raw =
            await _ref.read(apiClientProvider).getJson(
                  '/members/sync',
                  query: {'since': ?cursor},
                )
                as Map<String, dynamic>;
        await mirror.applyPage(raw);
        pages++;
        if (raw['hasMore'] != true) break;
      }
      SatLog.repo('memberMirror.synced pages=$pages');
    } on ApiException catch (e) {
      // 404 is the venue saying no — membership off, or the owner switched
      // mirroring off. Drop what we hold rather than keeping a copy of a
      // directory this device is no longer meant to have.
      if (e.statusCode == 404) {
        await mirror.wipe();
        return;
      }
      SatLog.repo('memberMirror.sync fail $e');
    } catch (e) {
      SatLog.repo('memberMirror.sync fail $e');
    } finally {
      _syncing = false;
    }
  }
}

/// A first sync of a low-thousands directory is a handful of pages. The cap is
/// a guard against a cursor that stops advancing, not a paging strategy — it
/// resumes on the next `connected` either way.
const _kMaxPagesPerRun = 40;

final memberMirrorSyncProvider = Provider<MemberMirrorSync>(
  (ref) => MemberMirrorSync(ref),
);

/// The searchable stand-in for a number on a masked mirror. Must hash exactly
/// as `lib/server/member_sync.dart` does, or the till types a number and finds
/// nobody.
String memberPhoneHash(String digits, String salt) =>
    sha256.convert(utf8.encode('$salt:${normalizePhone(digits)}')).toString();
