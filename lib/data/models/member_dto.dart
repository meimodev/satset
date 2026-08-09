import 'package:satset/domain/models/member.dart';

/// Wire shapes for the [[Pelanggan (member)]] directory.
///
/// Hand-written rather than freezed, like the cash ledger's: the server owns
/// the shape, the client only reads it, and the derived figures (points,
/// punch progress) arrive computed because a client holding one page of the
/// ledger cannot recompute `SUM(delta)` (ADR-0092).
class MemberDto {
  final Member member;

  /// Punch card, carried alongside the member because the bill panel shows the
  /// card and the balance in one glance. Zero target ⇒ no program running.
  final int punchTarget;
  final bool punchRewardDue;

  const MemberDto({
    required this.member,
    this.punchTarget = 0,
    this.punchRewardDue = false,
  });

  String get id => member.id;
  String get name => member.name;
  String get phone => member.phone;
  int get points => member.points;

  factory MemberDto.fromJson(Map<String, dynamic> j) => MemberDto(
    member: Member(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      code: j['code'] as String? ?? '',
      note: j['note'] as String?,
      birthday: DateTime.tryParse(j['birthday'] as String? ?? ''),
      joinedAt:
          DateTime.tryParse(j['joinedAt'] as String? ?? '') ?? DateTime(2000),
      points: _int(j['points']),
      punchProgress: _int(j['punchProgress']),
      visitCount: _int(j['visitCount']),
      lifetimeSpend: _int(j['lifetimeSpend']),
      lastVisitAt: DateTime.tryParse(j['lastVisitAt'] as String? ?? ''),
    ),
    punchTarget: _int((j['punch'] as Map?)?['target'] ?? j['punchTarget']),
    punchRewardDue:
        ((j['punch'] as Map?)?['rewardDue'] ?? j['punchRewardDue']) == true,
  );
}

/// One row of a member's [[Poin]] ledger.
class MemberLedgerEntry {
  final MemberPointEntry entry;
  const MemberLedgerEntry(this.entry);

  factory MemberLedgerEntry.fromJson(Map<String, dynamic> j) =>
      MemberLedgerEntry(
        MemberPointEntry(
          id: j['id'] as String? ?? '',
          memberId: j['memberId'] as String? ?? '',
          kind:
              memberPointKindFromName(j['kind'] as String?) ??
              MemberPointKind.adjust,
          delta: _int(j['delta']),
          visitId: j['visitId'] as String?,
          baseAmount: _int(j['baseAmount']),
          note: j['note'] as String?,
          actorUserId: j['actorUserId'] as String?,
          actorName: j['actorName'] as String?,
          at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime(2000),
        ),
      );
}

/// A member and their ledger, as the detail route returns them together.
class MemberDetail {
  final MemberDto member;
  final List<MemberLedgerEntry> ledger;
  const MemberDetail({required this.member, required this.ledger});

  factory MemberDetail.fromJson(Map<String, dynamic> j) => MemberDetail(
    member: MemberDto.fromJson(j),
    ledger: [
      for (final e in (j['ledger'] as List? ?? const []))
        MemberLedgerEntry.fromJson((e as Map).cast<String, dynamic>()),
    ],
  );
}

int _int(Object? v) => v is int ? v : (v is num ? v.toInt() : 0);
