import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/member_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';

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
    this.loading = false,
    this.error,
    this.enabled = true,
  });

  MembersState copyWith({
    List<MemberDto>? members,
    String? query,
    int? birthdayMonth,
    bool clearBirthdayMonth = false,
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

  Future<MemberDto> enrol({
    required String name,
    required String phone,
    String? note,
    DateTime? birthday,
  }) => _write(
    () async =>
        await _ref.read(apiClientProvider).postJson('/members', {
              'name': name,
              'phone': phone,
              'note': note,
              'birthday': birthday?.toIso8601String(),
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
  }) => _write(
    () async =>
        await _ref.read(apiClientProvider).patchJson('/members/$id', {
              'name': ?name,
              'phone': ?phone,
              'note': ?note,
              // An explicit null clears the date; an absent key leaves it be.
              if (clearBirthday || birthday != null)
                'birthday': birthday?.toIso8601String(),
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
    if (state.query.trim().isEmpty && state.birthdayMonth == null) {
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
