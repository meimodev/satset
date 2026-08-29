import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/member_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/member.dart';

/// How many members one read carries. The directory is a venue's regulars, not
/// a mailing list — a single page covers most, and the till reaches the rest by
/// typing a name or a number.
const _kMembersPage = 100;

class MembersState {
  final List<MemberDto> members;

  /// What the list is currently filtered by, kept in state so a WS arrival can
  /// tell "a member changed" from "a member changed that this view is showing".
  final String query;
  final int? birthdayMonth;

  /// The "belum kembali" cut, in days. Null ⇒ off. Derived server-side off
  /// `lastVisitAt` on every read — there is no lapsed *status* to go stale.
  final int? lapsedDays;

  final bool loading;
  final Object? error;

  /// False when the venue has the program switched off — every route answers
  /// 404 then, and the entry points should say the feature is off rather than
  /// show an empty directory (ADR-0091).
  final bool enabled;

  const MembersState({
    this.members = const [],
    this.query = '',
    this.birthdayMonth,
    this.lapsedDays,
    this.loading = false,
    this.error,
    this.enabled = true,
  });

  MembersState copyWith({
    List<MemberDto>? members,
    String? query,
    int? birthdayMonth,
    bool clearBirthdayMonth = false,
    int? lapsedDays,
    bool clearLapsedDays = false,
    bool? loading,
    Object? error,
    bool clearError = false,
    bool? enabled,
  }) => MembersState(
    members: members ?? this.members,
    query: query ?? this.query,
    birthdayMonth: clearBirthdayMonth
        ? null
        : (birthdayMonth ?? this.birthdayMonth),
    lapsedDays: clearLapsedDays ? null : (lapsedDays ?? this.lapsedDays),
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    enabled: enabled ?? this.enabled,
  );
}

/// The [[Pelanggan (member)]] directory, client side.
///
/// Every derived figure — points, visit count, punch progress — arrives
/// computed, for the reason the cash box's balance does: a client holding one
/// page of a ledger cannot sum it (ADR-0092, ADR-0095). Nothing here recomputes
/// a number the server sent.
class MembersRepository extends StateNotifier<MembersState> {
  MembersRepository(this._ref) : super(const MembersState()) {
    _wireWs();
  }

  final Ref _ref;
  StreamSubscription? _wsSub;

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    if (_ref.read(apiConfigProvider) == null) return;
    state = state.copyWith(loading: true, clearError: true);
    await _fetch();
  }

  /// Prefix search, run server-side against both the name and the number. The
  /// caller debounces; this fires the read it is given.
  Future<void> search(String q) async {
    state = state.copyWith(query: q, loading: true, clearError: true);
    await _fetch();
  }

  /// The birthday list — this month's, for the venue that greets them.
  Future<void> filterByBirthdayMonth(int? month) async {
    state = state.copyWith(
      birthdayMonth: month,
      clearBirthdayMonth: month == null,
      loading: true,
      clearError: true,
    );
    await _fetch();
  }

  /// The "belum kembali" cut — regulars who have stopped coming, and enrolments
  /// that never did. Days, not a stored status: a lapsed member who walks in
  /// tomorrow is simply not lapsed on the next read.
  Future<void> filterByLapsedDays(int? days) async {
    state = state.copyWith(
      lapsedDays: days,
      clearLapsedDays: days == null,
      loading: true,
      clearError: true,
    );
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final raw =
          await _ref
                  .read(apiClientProvider)
                  .getJson(
                    '/members',
                    query: {
                      'limit': '$_kMembersPage',
                      if (state.query.trim().isNotEmpty)
                        'q': state.query.trim(),
                      if (state.birthdayMonth != null)
                        'birthdayMonth': '${state.birthdayMonth}',
                      if (state.lapsedDays != null)
                        'lapsedDays': '${state.lapsedDays}',
                    },
                  )
              as List;
      state = state.copyWith(
        members: [
          for (final m in raw)
            MemberDto.fromJson((m as Map).cast<String, dynamic>()),
        ],
        loading: false,
        enabled: true,
      );
      SatLog.repo('members.loaded n=${state.members.length}');
    } on ApiException catch (e) {
      // 404 here is the program being off, not a missing route.
      if (e.statusCode == 404) {
        state = state.copyWith(
          members: const [],
          loading: false,
          enabled: false,
        );
        return;
      }
      SatLog.repo('members.fetch fail $e');
      state = state.copyWith(loading: false, error: e);
    } catch (e) {
      SatLog.repo('members.fetch fail $e');
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// One member with their ledger and punch card. Read on demand — the
  /// directory carries the summary, the sheet carries the history.
  Future<MemberDetail> detail(String id) async {
    final raw =
        await _ref.read(apiClientProvider).getJson('/members/$id')
            as Map<String, dynamic>;
    return MemberDetail.fromJson(raw);
  }

  /// A member's settled bills, newest first, paged by growing [limit] — the
  /// cashier-history pattern (ADR-0079). Lifetime by construction; the report's
  /// window does not reach here.
  Future<List<MemberVisitDto>> visits(String id, {int limit = 30}) async {
    final raw =
        await _ref.read(apiClientProvider).getJson(
              '/members/$id/visits',
              query: {'limit': '$limit'},
            )
            as List;
    return [
      for (final v in raw)
        MemberVisitDto.fromJson((v as Map).cast<String, dynamic>()),
    ];
  }

  Future<MemberDto> enrol({
    required String name,
    required String phone,
    String? note,
    DateTime? birthday,
    MemberAddress address = const MemberAddress(),
  }) => _write(
    () async =>
        await _ref.read(apiClientProvider).postJson('/members', {
              'name': name,
              'phone': phone,
              'note': note,
              'birthday': birthday?.toIso8601String(),
              if (address.isNotEmpty) 'address': address.toJson(),
            })
            as Map<String, dynamic>,
  );

  Future<MemberDto> edit({
    required String id,
    String? name,
    String? phone,
    String? note,
    DateTime? birthday,
    bool clearBirthday = false,
    int? debtLimit,
    bool clearDebtLimit = false,

    /// All four fields or none: absent leaves the stored address alone, a value
    /// replaces it whole. The editor always sends one, because the sheet holds
    /// the whole chain anyway.
    MemberAddress? address,
  }) => _write(
    () async =>
        await _ref.read(apiClientProvider).patchJson('/members/$id', {
              'name': ?name,
              'phone': ?phone,
              'note': ?note,
              // An explicit null clears the date; an absent key leaves it be.
              if (clearBirthday || birthday != null)
                'birthday': birthday?.toIso8601String(),
              // Same shape, and it carries more weight here: a null puts them
              // back on the venue default, which is not the same as a 0 limit.
              if (clearDebtLimit || debtLimit != null) 'debtLimit': debtLimit,
              if (address != null) 'address': address.toJson(),
            })
            as Map<String, dynamic>,
  );

  /// Anonymises rather than erases: the person goes, the trade stays counted.
  Future<void> remove(String id) async {
    await _ref.read(apiClientProvider).delete('/members/$id');
    state = state.copyWith(
      members: [
        for (final m in state.members)
          if (m.id != id) m,
      ],
    );
  }

  /// Folds [id] into [intoId]; the survivor comes back.
  Future<MemberDto> merge({required String id, required String intoId}) async {
    final survivor = await _write(
      () async =>
          await _ref.read(apiClientProvider).postJson('/members/$id/merge', {
                'intoId': intoId,
              })
              as Map<String, dynamic>,
    );
    state = state.copyWith(
      members: [
        for (final m in state.members)
          if (m.id != id) m,
      ],
    );
    return survivor;
  }

  Future<MemberDto> adjustPoints({
    required String id,
    required int delta,
    required String note,
  }) => _write(
    () async =>
        await _ref.read(apiClientProvider).postJson('/members/$id/points', {
              'delta': delta,
              'note': note,
            })
            as Map<String, dynamic>,
  );

  // ---------------------------------------------------------------- piutang
  //
  // Every write here answers with the member's new standing rather than the
  // member, so the caller can render a balance without a second round trip. The
  // socket carries the member itself, which is what keeps the directory row in
  // step — hence no `_upsert` on this side.

  /// One member's [[Piutang]] standing: balance, resolved limit, ledger.
  Future<MemberDebt> debt(String id) async {
    final raw =
        await _ref.read(apiClientProvider).getJson('/members/$id/debt')
            as Map<String, dynamic>;
    return MemberDebt.fromJson(raw);
  }

  /// Everyone who owes, largest first. Read by the directory's Berutang filter
  /// and nothing else — the report builds its own from the same server-side
  /// walk.
  Future<List<Debtor>> debtors() async {
    final raw =
        await _ref.read(apiClientProvider).getJson('/members/debtors') as List;
    return [
      for (final d in raw) Debtor.fromJson((d as Map).cast<String, dynamic>()),
    ];
  }

  /// Collect against a tab. [photoBase64] is mandatory server-side for any
  /// method but `tunai` (ADR-0025).
  Future<MemberDebt> payDebt({
    required String id,
    required int amount,
    required String method,
    String? photoBase64,
    String? note,
  }) async => MemberDebt.fromJson(
    await _ref.read(apiClientProvider).postJson('/members/$id/debt/payments', {
          'amount': amount,
          'method': method,
          'photoBase64': ?photoBase64,
          'note': ?note,
        })
        as Map<String, dynamic>,
  );

  /// Give up collecting. Mandatory reason, always audited.
  Future<MemberDebt> writeOffDebt({
    required String id,
    required int amount,
    required String note,
  }) async => MemberDebt.fromJson(
    await _ref.read(apiClientProvider).postJson('/members/$id/debt/write-off', {
          'amount': amount,
          'note': note,
        })
        as Map<String, dynamic>,
  );

  /// A hand correction, signed. Kept apart from a write-off so the bad-debt
  /// figure stays "money we lost" (ADR-0098).
  Future<MemberDebt> adjustDebt({
    required String id,
    required int delta,
    required String note,
  }) async => MemberDebt.fromJson(
    await _ref.read(apiClientProvider).postJson('/members/$id/debt/adjust', {
          'delta': delta,
          'note': note,
        })
        as Map<String, dynamic>,
  );

  /// Applies the response directly rather than waiting for the socket to loop
  /// back, for the reason the cash box does: the acting device must see its own
  /// write land even if the frame is late. [_upsert] makes the duplicate
  /// harmless when it arrives.
  Future<MemberDto> _write(Future<Map<String, dynamic>> Function() send) async {
    final member = MemberDto.fromJson(await send());
    _upsert(member);
    return member;
  }

  void _wireWs() {
    _wsSub = _ref.read(wsClientProvider).events.listen((ev) {
      switch (ev.type) {
        // Full resync on reconnect (ADR-0021): a member enrolled while the
        // socket was down would otherwise be missing until the next search.
        case WsEventTypes.connected:
          refresh();
        case WsEventTypes.memberUpdated:
          _upsert(MemberDto.fromJson(ev.payload));
        case WsEventTypes.memberDeleted:
          final id = ev.payload['id'] as String?;
          if (id == null) return;
          state = state.copyWith(
            members: [
              for (final m in state.members)
                if (m.id != id) m,
            ],
          );
      }
    });
  }

  void _upsert(MemberDto member) {
    final i = state.members.indexWhere((m) => m.id == member.id);
    if (i >= 0) {
      final next = [...state.members];
      next[i] = member;
      state = state.copyWith(members: next);
      return;
    }
    // ponytail: a stranger only joins the list when nothing is filtering it —
    // deciding whether they match the server's search is the server's job, and
    // guessing here is how a filtered view starts showing rows it excluded.
    if (state.query.trim().isEmpty &&
        state.birthdayMonth == null &&
        state.lapsedDays == null) {
      state = state.copyWith(members: [member, ...state.members]);
    }
  }
}

/// A refusal, as the sheets need it: the server's code plus whichever detail it
/// carried — the member who already owns a number on `phone_taken`, the floor or
/// the balance on a points refusal.
({String code, String? memberId, int? points})? memberErrorOf(Object error) {
  if (error is! ApiException) return null;
  final code = error.code;
  if (code == null) return null;
  String? memberId;
  int? points;
  try {
    final body = jsonDecode(error.body) as Map;
    memberId = body['memberId'] as String?;
    points = (body['points'] as num?)?.toInt();
  } catch (_) {
    // Body was not the JSON we expected; the code alone still says enough.
  }
  return (code: code, memberId: memberId, points: points);
}

final membersProvider = StateNotifierProvider<MembersRepository, MembersState>(
  (ref) => MembersRepository(ref),
);
