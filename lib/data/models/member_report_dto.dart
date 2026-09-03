/// Wire shapes for the member report (§Laporan pelanggan).
///
/// Hand-written like `member_dto.dart` and for the same reason: the server owns
/// every figure here. A share of a split bill, a product rollup and a points
/// balance are all derived from rows the client never holds, so nothing below
/// computes — it reads (ADR-0092, ADR-0095, ADR-0118).
library;

/// One member's row in the ranked list.
class MemberTradeDto {
  final String memberId;

  /// Null when the member has since been deleted — the trade stands, the person
  /// does not (ADR-0092). The screen renders its own placeholder.
  final String? name;
  final String? phone;

  /// Bills this member was on in the window — one each, not a share each.
  final int visits;

  /// Their share of those bills, split the ADR-0118 way.
  final int spend;

  /// Points earned in the window, net of reversals.
  final int points;

  final DateTime? lastVisitAt;

  const MemberTradeDto({
    required this.memberId,
    required this.name,
    required this.phone,
    required this.visits,
    required this.spend,
    required this.points,
    required this.lastVisitAt,
  });

  bool get deleted => name == null;

  int get avgBill => visits == 0 ? 0 : spend ~/ visits;

  factory MemberTradeDto.fromJson(Map<String, dynamic> j) => MemberTradeDto(
    memberId: j['memberId'] as String? ?? '',
    name: j['name'] as String?,
    phone: j['phone'] as String?,
    visits: (j['visits'] as num?)?.toInt() ?? 0,
    spend: (j['spend'] as num?)?.toInt() ?? 0,
    points: (j['points'] as num?)?.toInt() ?? 0,
    lastVisitAt: DateTime.tryParse(j['lastVisitAt'] as String? ?? ''),
  );
}

/// The overview numbers plus the ranked list — one read of `/members/report`.
class MemberReportDto {
  /// False when the venue runs no membership program. Every member route answers
  /// 404 then (ADR-0091), so the screen says the feature is off rather than
  /// drawing an empty report.
  final bool enabled;

  /// The points program runs independently of membership itself, so a venue can
  /// hold members and no points. The columns hide rather than showing zeros.
  final bool pointsEnabled;

  /// Whether a bill may name a member per receipt (ADR-0118). What makes
  /// [splitBills] worth reading.
  final bool splitEnabled;

  /// Joined inside the window.
  final int enrolled;

  /// Traded inside the window.
  final int activeMembers;

  /// Traded more than once inside the window — the only question a loyalty
  /// program is really asked.
  final int returningMembers;

  /// Everyone on the books, and how many of them did not come.
  final int enrolledTotal;
  final int idleMembers;

  final int memberBills;
  final int memberNet;
  final int guestBills;
  final int guestNet;
  final int avgMemberBill;
  final int avgGuestBill;

  /// Bills carrying more than one member. Zero at a venue without the mode.
  final int splitBills;

  final int pointsEarned;
  final int pointsRedeemed;
  final int pointsAdjusted;

  /// Never any one window's: points do not expire (ADR-0095), so what the venue
  /// owes is a running total.
  final int pointsOutstanding;

  /// What those points would cost if every one were spent tomorrow, at today's
  /// rate. The rate can move; this is an estimate and is named one.
  final int liabilityEstimate;

  final List<MemberTradeDto> members;

  /// Members who traded but fell off the end of the list.
  final int membersTruncated;

  /// The venue's oldest settled bill inside the window. What an open-ended
  /// range labels its start with, rather than a sentinel year.
  final DateTime? earliestClosedAt;

  const MemberReportDto({
    required this.enabled,
    required this.pointsEnabled,
    required this.splitEnabled,
    required this.enrolled,
    required this.activeMembers,
    required this.returningMembers,
    required this.enrolledTotal,
    required this.idleMembers,
    required this.memberBills,
    required this.memberNet,
    required this.guestBills,
    required this.guestNet,
    required this.avgMemberBill,
    required this.avgGuestBill,
    required this.splitBills,
    required this.pointsEarned,
    required this.pointsRedeemed,
    required this.pointsAdjusted,
    required this.pointsOutstanding,
    required this.liabilityEstimate,
    required this.members,
    required this.membersTruncated,
    required this.earliestClosedAt,
  });

  /// What the venue took in the window, both halves. The denominator for the
  /// member share.
  int get venueNet => memberNet + guestNet;

  /// Members with exactly one bill in the window.
  int get onceOnly => activeMembers - returningMembers;

  factory MemberReportDto.fromJson(Map<String, dynamic> j) => MemberReportDto(
    enabled: j['enabled'] as bool? ?? true,
    pointsEnabled: j['pointsEnabled'] as bool? ?? false,
    splitEnabled: j['splitEnabled'] as bool? ?? false,
    enrolled: (j['enrolled'] as num?)?.toInt() ?? 0,
    activeMembers: (j['activeMembers'] as num?)?.toInt() ?? 0,
    returningMembers: (j['returningMembers'] as num?)?.toInt() ?? 0,
    enrolledTotal: (j['enrolledTotal'] as num?)?.toInt() ?? 0,
    idleMembers: (j['idleMembers'] as num?)?.toInt() ?? 0,
    memberBills: (j['memberBills'] as num?)?.toInt() ?? 0,
    memberNet: (j['memberNet'] as num?)?.toInt() ?? 0,
    guestBills: (j['guestBills'] as num?)?.toInt() ?? 0,
    guestNet: (j['guestNet'] as num?)?.toInt() ?? 0,
    avgMemberBill: (j['avgMemberBill'] as num?)?.toInt() ?? 0,
    avgGuestBill: (j['avgGuestBill'] as num?)?.toInt() ?? 0,
    splitBills: (j['splitBills'] as num?)?.toInt() ?? 0,
    pointsEarned: (j['pointsEarned'] as num?)?.toInt() ?? 0,
    pointsRedeemed: (j['pointsRedeemed'] as num?)?.toInt() ?? 0,
    pointsAdjusted: (j['pointsAdjusted'] as num?)?.toInt() ?? 0,
    pointsOutstanding: (j['pointsOutstanding'] as num?)?.toInt() ?? 0,
    liabilityEstimate: (j['liabilityEstimate'] as num?)?.toInt() ?? 0,
    members: [
      for (final m in (j['members'] as List? ?? const []))
        MemberTradeDto.fromJson((m as Map).cast<String, dynamic>()),
    ],
    membersTruncated: (j['membersTruncated'] as num?)?.toInt() ?? 0,
    earliestClosedAt: DateTime.tryParse(j['earliestClosedAt'] as String? ?? ''),
  );
}

/// One settled bill on a member's history, from that member's side of it.
class MemberBillDto {
  final String sessionId;
  final DateTime closedAt;
  final String? tableLabel;
  final int pax;
  final String kind;

  /// What the whole bill settled for.
  final int billTotal;

  /// What this member's share of it was.
  final int share;

  /// True when they held the bill; false when they only named a receipt on
  /// somebody else's (ADR-0118).
  final bool owner;

  /// Units attributed to them on this bill, voids excluded — so a bill they did
  /// settle can legitimately show none.
  final int units;

  const MemberBillDto({
    required this.sessionId,
    required this.closedAt,
    required this.tableLabel,
    required this.pax,
    required this.kind,
    required this.billTotal,
    required this.share,
    required this.owner,
    required this.units,
  });

  /// True when they paid for part of a bill somebody else held, or held one
  /// somebody else paid part of.
  bool get shared => share != billTotal;

  factory MemberBillDto.fromJson(Map<String, dynamic> j) => MemberBillDto(
    sessionId: j['sessionId'] as String? ?? '',
    closedAt: DateTime.tryParse(j['closedAt'] as String? ?? '') ?? DateTime(0),
    tableLabel: j['tableLabel'] as String?,
    pax: (j['pax'] as num?)?.toInt() ?? 0,
    kind: j['kind'] as String? ?? '',
    billTotal: (j['billTotal'] as num?)?.toInt() ?? 0,
    share: (j['share'] as num?)?.toInt() ?? 0,
    owner: j['owner'] as bool? ?? false,
    units: (j['units'] as num?)?.toInt() ?? 0,
  );
}

/// One menu item in a member's product rollup.
class MemberProductDto {
  final String itemId;

  /// From the newest snapshot line, so a renamed item still reads as itself.
  final String name;
  final int qty;
  final int spend;
  final DateTime lastAt;

  const MemberProductDto({
    required this.itemId,
    required this.name,
    required this.qty,
    required this.spend,
    required this.lastAt,
  });

  factory MemberProductDto.fromJson(Map<String, dynamic> j) => MemberProductDto(
    itemId: j['itemId'] as String? ?? '',
    name: j['name'] as String? ?? '',
    qty: (j['qty'] as num?)?.toInt() ?? 0,
    spend: (j['spend'] as num?)?.toInt() ?? 0,
    lastAt: DateTime.tryParse(j['lastAt'] as String? ?? '') ?? DateTime(0),
  );
}

/// One member's trade in the window: their bills, and everything they bought.
class MemberHistoryDto {
  final String memberId;

  /// The directory record, when there still is one. Null for a member deleted
  /// under ADR-0092 — their bills survive as an orphan id, so the history opens
  /// where `GET /members/<id>` would 404.
  final Map<String, dynamic>? member;

  final List<MemberBillDto> bills;

  /// Bills in the window, including any beyond the returned page.
  final int billsTotal;

  final List<MemberProductDto> products;

  final int visits;
  final int spend;
  final int units;
  final int avgBill;

  /// Money on bills where this member was attributed no line at all — the whole
  /// of an [[Amount receipt]] (ADR-0068), which claims money and owns no items.
  /// Shown, because the spend total and the product rollup are then *supposed*
  /// to disagree and a silent gap reads as a bug.
  final int untrackedSpend;

  const MemberHistoryDto({
    required this.memberId,
    required this.member,
    required this.bills,
    required this.billsTotal,
    required this.products,
    required this.visits,
    required this.spend,
    required this.units,
    required this.avgBill,
    required this.untrackedSpend,
  });

  String? get name => member?['name'] as String?;
  String? get phone => member?['phone'] as String?;
  bool get deleted => member == null;

  /// Lifetime figures, which the directory row carries and the window does not.
  int get lifetimeSpend => (member?['lifetimeSpend'] as num?)?.toInt() ?? 0;
  int get lifetimeVisits => (member?['visitCount'] as num?)?.toInt() ?? 0;
  int get pointsBalance => (member?['points'] as num?)?.toInt() ?? 0;
  DateTime? get joinedAt => DateTime.tryParse(member?['joinedAt'] as String? ?? '');

  /// Distinct menu items bought in the window.
  int get distinctProducts => products.length;

  factory MemberHistoryDto.fromJson(Map<String, dynamic> j) => MemberHistoryDto(
    memberId: j['memberId'] as String? ?? '',
    member: (j['member'] as Map?)?.cast<String, dynamic>(),
    bills: [
      for (final b in (j['bills'] as List? ?? const []))
        MemberBillDto.fromJson((b as Map).cast<String, dynamic>()),
    ],
    billsTotal: (j['billsTotal'] as num?)?.toInt() ?? 0,
    products: [
      for (final p in (j['products'] as List? ?? const []))
        MemberProductDto.fromJson((p as Map).cast<String, dynamic>()),
    ],
    visits: (j['visits'] as num?)?.toInt() ?? 0,
    spend: (j['spend'] as num?)?.toInt() ?? 0,
    units: (j['units'] as num?)?.toInt() ?? 0,
    avgBill: (j['avgBill'] as num?)?.toInt() ?? 0,
    untrackedSpend: (j['untrackedSpend'] as num?)?.toInt() ?? 0,
  );
}
