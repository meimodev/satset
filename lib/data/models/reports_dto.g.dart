// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReportsSnapshotDto _$ReportsSnapshotDtoFromJson(Map<String, dynamic> json) =>
    _ReportsSnapshotDto(
      generatedAt: json['generatedAt'] as String,
      rangeFrom: json['rangeFrom'] as String,
      rangeTo: json['rangeTo'] as String,
      range: json['range'] as String,
      filterOptions: FilterOptionsDto.fromJson(
        json['filterOptions'] as Map<String, dynamic>,
      ),
      sales: SalesSectionDto.fromJson(json['sales'] as Map<String, dynamic>),
      staff: StaffSectionDto.fromJson(json['staff'] as Map<String, dynamic>),
      menu: MenuSectionDto.fromJson(json['menu'] as Map<String, dynamic>),
      ops: OpsSectionDto.fromJson(json['ops'] as Map<String, dynamic>),
      moneyAudit: json['moneyAudit'] == null
          ? const MoneyAuditSectionDto()
          : MoneyAuditSectionDto.fromJson(
              json['moneyAudit'] as Map<String, dynamic>,
            ),
      kas: json['kas'] == null
          ? const KasSectionDto()
          : KasSectionDto.fromJson(json['kas'] as Map<String, dynamic>),
      members: json['members'] == null
          ? const MembersSectionDto()
          : MembersSectionDto.fromJson(json['members'] as Map<String, dynamic>),
      piutang: json['piutang'] == null
          ? const PiutangSectionDto()
          : PiutangSectionDto.fromJson(json['piutang'] as Map<String, dynamic>),
      jamKerja: json['jamKerja'] == null
          ? const JamKerjaSectionDto()
          : JamKerjaSectionDto.fromJson(
              json['jamKerja'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ReportsSnapshotDtoToJson(_ReportsSnapshotDto instance) =>
    <String, dynamic>{
      'generatedAt': instance.generatedAt,
      'rangeFrom': instance.rangeFrom,
      'rangeTo': instance.rangeTo,
      'range': instance.range,
      'filterOptions': instance.filterOptions,
      'sales': instance.sales,
      'staff': instance.staff,
      'menu': instance.menu,
      'ops': instance.ops,
      'moneyAudit': instance.moneyAudit,
      'kas': instance.kas,
      'members': instance.members,
      'piutang': instance.piutang,
      'jamKerja': instance.jamKerja,
    };

_FilterOptionsDto _$FilterOptionsDtoFromJson(Map<String, dynamic> json) =>
    _FilterOptionsDto(
      servers:
          (json['servers'] as List<dynamic>?)
              ?.map((e) => NamedIdDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <NamedIdDto>[],
      zones:
          (json['zones'] as List<dynamic>?)
              ?.map((e) => NamedIdDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <NamedIdDto>[],
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => NamedIdDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <NamedIdDto>[],
    );

Map<String, dynamic> _$FilterOptionsDtoToJson(_FilterOptionsDto instance) =>
    <String, dynamic>{
      'servers': instance.servers,
      'zones': instance.zones,
      'categories': instance.categories,
    };

_NamedIdDto _$NamedIdDtoFromJson(Map<String, dynamic> json) =>
    _NamedIdDto(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$NamedIdDtoToJson(_NamedIdDto instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_KpiTileDto _$KpiTileDtoFromJson(Map<String, dynamic> json) => _KpiTileDto(
  key: json['key'] as String? ?? '',
  args:
      (json['args'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  label: json['label'] as String? ?? '',
  rupiah: (json['rupiah'] as num?)?.toInt(),
  value: json['value'] as String? ?? '',
  sub: json['sub'] as String? ?? '',
);

Map<String, dynamic> _$KpiTileDtoToJson(_KpiTileDto instance) =>
    <String, dynamic>{
      'key': instance.key,
      'args': instance.args,
      'label': instance.label,
      'rupiah': instance.rupiah,
      'value': instance.value,
      'sub': instance.sub,
    };

_SalesSectionDto _$SalesSectionDtoFromJson(Map<String, dynamic> json) =>
    _SalesSectionDto(
      kpis:
          (json['kpis'] as List<dynamic>?)
              ?.map((e) => KpiTileDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <KpiTileDto>[],
      coverTrend:
          (json['coverTrend'] as List<dynamic>?)
              ?.map((e) => CoverDayDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CoverDayDto>[],
      hourly:
          (json['hourly'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const <double>[],
      takeaway: json['takeaway'] == null
          ? null
          : TakeawaySplitDto.fromJson(json['takeaway'] as Map<String, dynamic>),
      badDebt: (json['badDebt'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SalesSectionDtoToJson(_SalesSectionDto instance) =>
    <String, dynamic>{
      'kpis': instance.kpis,
      'coverTrend': instance.coverTrend,
      'hourly': instance.hourly,
      'takeaway': instance.takeaway,
      'badDebt': instance.badDebt,
    };

_TakeawaySplitDto _$TakeawaySplitDtoFromJson(Map<String, dynamic> json) =>
    _TakeawaySplitDto(
      count: (json['count'] as num?)?.toInt() ?? 0,
      net: (json['net'] as num?)?.toInt() ?? 0,
      dineInCount: (json['dineInCount'] as num?)?.toInt() ?? 0,
      dineInNet: (json['dineInNet'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TakeawaySplitDtoToJson(_TakeawaySplitDto instance) =>
    <String, dynamic>{
      'count': instance.count,
      'net': instance.net,
      'dineInCount': instance.dineInCount,
      'dineInNet': instance.dineInNet,
    };

_CoverDayDto _$CoverDayDtoFromJson(Map<String, dynamic> json) => _CoverDayDto(
  dow: (json['dow'] as num?)?.toInt() ?? 1,
  thisWeek: (json['thisWeek'] as num).toInt(),
  lastWeek: (json['lastWeek'] as num).toInt(),
);

Map<String, dynamic> _$CoverDayDtoToJson(_CoverDayDto instance) =>
    <String, dynamic>{
      'dow': instance.dow,
      'thisWeek': instance.thisWeek,
      'lastWeek': instance.lastWeek,
    };

_StaffSectionDto _$StaffSectionDtoFromJson(Map<String, dynamic> json) =>
    _StaffSectionDto(
      rows:
          (json['rows'] as List<dynamic>?)
              ?.map((e) => StaffRowDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StaffRowDto>[],
      upsell:
          (json['upsell'] as List<dynamic>?)
              ?.map((e) => StaffUpsellDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StaffUpsellDto>[],
    );

Map<String, dynamic> _$StaffSectionDtoToJson(_StaffSectionDto instance) =>
    <String, dynamic>{'rows': instance.rows, 'upsell': instance.upsell};

_StaffRowDto _$StaffRowDtoFromJson(Map<String, dynamic> json) => _StaffRowDto(
  id: json['id'] as String,
  name: json['name'] as String,
  covers: (json['covers'] as num?)?.toInt() ?? 0,
  items: (json['items'] as num?)?.toInt() ?? 0,
  avgTicket: (json['avgTicket'] as num?)?.toInt() ?? 0,
  voidPct: (json['voidPct'] as num?)?.toDouble() ?? 0.0,
  net: (json['net'] as num?)?.toInt() ?? 0,
  sessions: (json['sessions'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$StaffRowDtoToJson(_StaffRowDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'covers': instance.covers,
      'items': instance.items,
      'avgTicket': instance.avgTicket,
      'voidPct': instance.voidPct,
      'net': instance.net,
      'sessions': instance.sessions,
    };

_StaffUpsellDto _$StaffUpsellDtoFromJson(Map<String, dynamic> json) =>
    _StaffUpsellDto(
      id: json['id'] as String,
      name: json['name'] as String,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$StaffUpsellDtoToJson(_StaffUpsellDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'rate': instance.rate,
    };

_MenuSectionDto _$MenuSectionDtoFromJson(Map<String, dynamic> json) =>
    _MenuSectionDto(
      top:
          (json['top'] as List<dynamic>?)
              ?.map((e) => MenuItemRowDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MenuItemRowDto>[],
      slow:
          (json['slow'] as List<dynamic>?)
              ?.map((e) => MenuItemRowDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MenuItemRowDto>[],
      modifierAttach:
          (json['modifierAttach'] as List<dynamic>?)
              ?.map(
                (e) => ModifierAttachDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ModifierAttachDto>[],
      categoryMix:
          (json['categoryMix'] as List<dynamic>?)
              ?.map((e) => CategoryShareDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CategoryShareDto>[],
      matrix:
          (json['matrix'] as List<dynamic>?)
              ?.map((e) => MatrixItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MatrixItemDto>[],
      basketPairs:
          (json['basketPairs'] as List<dynamic>?)
              ?.map((e) => BasketPairDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BasketPairDto>[],
    );

Map<String, dynamic> _$MenuSectionDtoToJson(_MenuSectionDto instance) =>
    <String, dynamic>{
      'top': instance.top,
      'slow': instance.slow,
      'modifierAttach': instance.modifierAttach,
      'categoryMix': instance.categoryMix,
      'matrix': instance.matrix,
      'basketPairs': instance.basketPairs,
    };

_MenuItemRowDto _$MenuItemRowDtoFromJson(Map<String, dynamic> json) =>
    _MenuItemRowDto(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
      marginPct: (json['marginPct'] as num?)?.toInt() ?? 0,
      fill: (json['fill'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$MenuItemRowDtoToJson(_MenuItemRowDto instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'name': instance.name,
      'qty': instance.qty,
      'revenue': instance.revenue,
      'marginPct': instance.marginPct,
      'fill': instance.fill,
    };

_ModifierAttachDto _$ModifierAttachDtoFromJson(Map<String, dynamic> json) =>
    _ModifierAttachDto(
      group: json['group'] as String,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$ModifierAttachDtoToJson(_ModifierAttachDto instance) =>
    <String, dynamic>{'group': instance.group, 'rate': instance.rate};

_CategoryShareDto _$CategoryShareDtoFromJson(Map<String, dynamic> json) =>
    _CategoryShareDto(
      id: json['id'] as String,
      name: json['name'] as String,
      shareThisWeek: (json['shareThisWeek'] as num?)?.toDouble() ?? 0.0,
      shareLastWeek: (json['shareLastWeek'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$CategoryShareDtoToJson(_CategoryShareDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'shareThisWeek': instance.shareThisWeek,
      'shareLastWeek': instance.shareLastWeek,
    };

_MatrixItemDto _$MatrixItemDtoFromJson(Map<String, dynamic> json) =>
    _MatrixItemDto(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      margin: (json['margin'] as num?)?.toDouble() ?? 0.0,
      quadrant: json['quadrant'] as String,
    );

Map<String, dynamic> _$MatrixItemDtoToJson(_MatrixItemDto instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'name': instance.name,
      'popularity': instance.popularity,
      'margin': instance.margin,
      'quadrant': instance.quadrant,
    };

_BasketPairDto _$BasketPairDtoFromJson(Map<String, dynamic> json) =>
    _BasketPairDto(
      itemA: json['itemA'] as String,
      itemB: json['itemB'] as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$BasketPairDtoToJson(_BasketPairDto instance) =>
    <String, dynamic>{
      'itemA': instance.itemA,
      'itemB': instance.itemB,
      'count': instance.count,
      'rate': instance.rate,
    };

_OpsSectionDto _$OpsSectionDtoFromJson(Map<String, dynamic> json) =>
    _OpsSectionDto(
      kpis:
          (json['kpis'] as List<dynamic>?)
              ?.map((e) => KpiTileDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <KpiTileDto>[],
      speed: json['speed'] == null
          ? const SpeedSectionDto()
          : SpeedSectionDto.fromJson(json['speed'] as Map<String, dynamic>),
      stations:
          (json['stations'] as List<dynamic>?)
              ?.map((e) => StationRowDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StationRowDto>[],
      heatmap:
          (json['heatmap'] as List<dynamic>?)
              ?.map(
                (e) => (e as List<dynamic>)
                    .map((e) => (e as num).toDouble())
                    .toList(),
              )
              .toList() ??
          const <List<double>>[],
      reservations: ReservationStatsDto.fromJson(
        json['reservations'] as Map<String, dynamic>,
      ),
      voidReasons:
          (json['voidReasons'] as List<dynamic>?)
              ?.map((e) => VoidReasonDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <VoidReasonDto>[],
      voidByStaff:
          (json['voidByStaff'] as List<dynamic>?)
              ?.map((e) => StaffVoidDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StaffVoidDto>[],
    );

Map<String, dynamic> _$OpsSectionDtoToJson(_OpsSectionDto instance) =>
    <String, dynamic>{
      'kpis': instance.kpis,
      'speed': instance.speed,
      'stations': instance.stations,
      'heatmap': instance.heatmap,
      'reservations': instance.reservations,
      'voidReasons': instance.voidReasons,
      'voidByStaff': instance.voidByStaff,
    };

_SpeedSectionDto _$SpeedSectionDtoFromJson(Map<String, dynamic> json) =>
    _SpeedSectionDto(
      prepMedianMin: (json['prepMedianMin'] as num?)?.toInt() ?? 0,
      pickupMedianMin: (json['pickupMedianMin'] as num?)?.toInt() ?? 0,
      slaPct: (json['slaPct'] as num?)?.toDouble() ?? 0.0,
      prepTargetMins: (json['prepTargetMins'] as num?)?.toInt() ?? 15,
      sampleSize: (json['sampleSize'] as num?)?.toInt() ?? 0,
      slowItems:
          (json['slowItems'] as List<dynamic>?)
              ?.map((e) => SpeedItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SpeedItemDto>[],
      pickupTargetMins: (json['pickupTargetMins'] as num?)?.toInt() ?? 4,
      pickupSlaPct: (json['pickupSlaPct'] as num?)?.toDouble() ?? 0.0,
      courseSampleSize: (json['courseSampleSize'] as num?)?.toInt() ?? 0,
      greetMedianMin: (json['greetMedianMin'] as num?)?.toInt() ?? 0,
      greetBreachPct: (json['greetBreachPct'] as num?)?.toDouble() ?? 0.0,
      ungreetedMins: (json['ungreetedMins'] as num?)?.toInt() ?? 7,
      greetSampleSize: (json['greetSampleSize'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SpeedSectionDtoToJson(_SpeedSectionDto instance) =>
    <String, dynamic>{
      'prepMedianMin': instance.prepMedianMin,
      'pickupMedianMin': instance.pickupMedianMin,
      'slaPct': instance.slaPct,
      'prepTargetMins': instance.prepTargetMins,
      'sampleSize': instance.sampleSize,
      'slowItems': instance.slowItems,
      'pickupTargetMins': instance.pickupTargetMins,
      'pickupSlaPct': instance.pickupSlaPct,
      'courseSampleSize': instance.courseSampleSize,
      'greetMedianMin': instance.greetMedianMin,
      'greetBreachPct': instance.greetBreachPct,
      'ungreetedMins': instance.ungreetedMins,
      'greetSampleSize': instance.greetSampleSize,
    };

_SpeedItemDto _$SpeedItemDtoFromJson(Map<String, dynamic> json) =>
    _SpeedItemDto(
      itemId: json['itemId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avgPrepMin: (json['avgPrepMin'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SpeedItemDtoToJson(_SpeedItemDto instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'name': instance.name,
      'avgPrepMin': instance.avgPrepMin,
      'count': instance.count,
    };

_StationRowDto _$StationRowDtoFromJson(Map<String, dynamic> json) =>
    _StationRowDto(
      station: json['station'] as String,
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      utilization: (json['utilization'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$StationRowDtoToJson(_StationRowDto instance) =>
    <String, dynamic>{
      'station': instance.station,
      'qty': instance.qty,
      'utilization': instance.utilization,
    };

_ReservationStatsDto _$ReservationStatsDtoFromJson(Map<String, dynamic> json) =>
    _ReservationStatsDto(
      booked: (json['booked'] as num?)?.toInt() ?? 0,
      seated: (json['seated'] as num?)?.toInt() ?? 0,
      noShow: (json['noShow'] as num?)?.toInt() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ReservationStatsDtoToJson(
  _ReservationStatsDto instance,
) => <String, dynamic>{
  'booked': instance.booked,
  'seated': instance.seated,
  'noShow': instance.noShow,
  'cancelled': instance.cancelled,
};

_VoidReasonDto _$VoidReasonDtoFromJson(Map<String, dynamic> json) =>
    _VoidReasonDto(
      code: json['code'] as String,
      label: json['label'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      lostRupiah: (json['lostRupiah'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VoidReasonDtoToJson(_VoidReasonDto instance) =>
    <String, dynamic>{
      'code': instance.code,
      'label': instance.label,
      'count': instance.count,
      'lostRupiah': instance.lostRupiah,
    };

_KasSectionDto _$KasSectionDtoFromJson(Map<String, dynamic> json) =>
    _KasSectionDto(
      opening: (json['opening'] as num?)?.toInt() ?? 0,
      inflow: (json['inflow'] as num?)?.toInt() ?? 0,
      outflow: (json['outflow'] as num?)?.toInt() ?? 0,
      variance: (json['variance'] as num?)?.toInt() ?? 0,
      closing: (json['closing'] as num?)?.toInt() ?? 0,
      byCategory:
          (json['byCategory'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
      count: (json['count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$KasSectionDtoToJson(_KasSectionDto instance) =>
    <String, dynamic>{
      'opening': instance.opening,
      'inflow': instance.inflow,
      'outflow': instance.outflow,
      'variance': instance.variance,
      'closing': instance.closing,
      'byCategory': instance.byCategory,
      'count': instance.count,
    };

_JamKerjaSectionDto _$JamKerjaSectionDtoFromJson(Map<String, dynamic> json) =>
    _JamKerjaSectionDto(
      staff:
          (json['staff'] as List<dynamic>?)
              ?.map((e) => JamKerjaRowDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <JamKerjaRowDto>[],
      dayStartHour: (json['dayStartHour'] as num?)?.toInt() ?? 4,
      unclosed: (json['unclosed'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$JamKerjaSectionDtoToJson(_JamKerjaSectionDto instance) =>
    <String, dynamic>{
      'staff': instance.staff,
      'dayStartHour': instance.dayStartHour,
      'unclosed': instance.unclosed,
    };

_JamKerjaRowDto _$JamKerjaRowDtoFromJson(Map<String, dynamic> json) =>
    _JamKerjaRowDto(
      id: json['id'] as String,
      name: json['name'] as String,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      shifts: (json['shifts'] as num?)?.toInt() ?? 0,
      days: (json['days'] as num?)?.toInt() ?? 0,
      unclosed: (json['unclosed'] as num?)?.toInt() ?? 0,
      medianFirstIn: (json['medianFirstIn'] as num?)?.toInt(),
      lastSeen: json['lastSeen'] as String?,
    );

Map<String, dynamic> _$JamKerjaRowDtoToJson(_JamKerjaRowDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'minutes': instance.minutes,
      'shifts': instance.shifts,
      'days': instance.days,
      'unclosed': instance.unclosed,
      'medianFirstIn': instance.medianFirstIn,
      'lastSeen': instance.lastSeen,
    };

_MembersSectionDto _$MembersSectionDtoFromJson(Map<String, dynamic> json) =>
    _MembersSectionDto(
      enabled: json['enabled'] as bool? ?? false,
      pointsEnabled: json['pointsEnabled'] as bool? ?? false,
      enrolled: (json['enrolled'] as num?)?.toInt() ?? 0,
      activeMembers: (json['activeMembers'] as num?)?.toInt() ?? 0,
      memberBills: (json['memberBills'] as num?)?.toInt() ?? 0,
      memberNet: (json['memberNet'] as num?)?.toInt() ?? 0,
      guestBills: (json['guestBills'] as num?)?.toInt() ?? 0,
      guestNet: (json['guestNet'] as num?)?.toInt() ?? 0,
      avgMemberBill: (json['avgMemberBill'] as num?)?.toInt() ?? 0,
      avgGuestBill: (json['avgGuestBill'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      pointsRedeemed: (json['pointsRedeemed'] as num?)?.toInt() ?? 0,
      pointsAdjusted: (json['pointsAdjusted'] as num?)?.toInt() ?? 0,
      pointsOutstanding: (json['pointsOutstanding'] as num?)?.toInt() ?? 0,
      liabilityEstimate: (json['liabilityEstimate'] as num?)?.toInt() ?? 0,
      top:
          (json['top'] as List<dynamic>?)
              ?.map((e) => MemberTopRowDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MemberTopRowDto>[],
      topTruncated: (json['topTruncated'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MembersSectionDtoToJson(_MembersSectionDto instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'pointsEnabled': instance.pointsEnabled,
      'enrolled': instance.enrolled,
      'activeMembers': instance.activeMembers,
      'memberBills': instance.memberBills,
      'memberNet': instance.memberNet,
      'guestBills': instance.guestBills,
      'guestNet': instance.guestNet,
      'avgMemberBill': instance.avgMemberBill,
      'avgGuestBill': instance.avgGuestBill,
      'pointsEarned': instance.pointsEarned,
      'pointsRedeemed': instance.pointsRedeemed,
      'pointsAdjusted': instance.pointsAdjusted,
      'pointsOutstanding': instance.pointsOutstanding,
      'liabilityEstimate': instance.liabilityEstimate,
      'top': instance.top,
      'topTruncated': instance.topTruncated,
    };

_PiutangSectionDto _$PiutangSectionDtoFromJson(Map<String, dynamic> json) =>
    _PiutangSectionDto(
      enabled: json['enabled'] as bool? ?? false,
      opening: (json['opening'] as num?)?.toInt() ?? 0,
      charged: (json['charged'] as num?)?.toInt() ?? 0,
      collected: (json['collected'] as num?)?.toInt() ?? 0,
      writtenOff: (json['writtenOff'] as num?)?.toInt() ?? 0,
      adjusted: (json['adjusted'] as num?)?.toInt() ?? 0,
      closing: (json['closing'] as num?)?.toInt() ?? 0,
      byMethod:
          (json['byMethod'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
      overdueDays: (json['overdueDays'] as num?)?.toInt() ?? 30,
      overdueTotal: (json['overdueTotal'] as num?)?.toInt() ?? 0,
      debtorCount: (json['debtorCount'] as num?)?.toInt() ?? 0,
      debtors:
          (json['debtors'] as List<dynamic>?)
              ?.map((e) => DebtorRowDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DebtorRowDto>[],
      debtorsTruncated: json['debtorsTruncated'] as bool? ?? false,
    );

Map<String, dynamic> _$PiutangSectionDtoToJson(_PiutangSectionDto instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'opening': instance.opening,
      'charged': instance.charged,
      'collected': instance.collected,
      'writtenOff': instance.writtenOff,
      'adjusted': instance.adjusted,
      'closing': instance.closing,
      'byMethod': instance.byMethod,
      'overdueDays': instance.overdueDays,
      'overdueTotal': instance.overdueTotal,
      'debtorCount': instance.debtorCount,
      'debtors': instance.debtors,
      'debtorsTruncated': instance.debtorsTruncated,
    };

_DebtorRowDto _$DebtorRowDtoFromJson(Map<String, dynamic> json) =>
    _DebtorRowDto(
      memberId: json['memberId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      oldestUnpaidAt: json['oldestUnpaidAt'] == null
          ? null
          : DateTime.parse(json['oldestUnpaidAt'] as String),
      lastPaymentAt: json['lastPaymentAt'] == null
          ? null
          : DateTime.parse(json['lastPaymentAt'] as String),
    );

Map<String, dynamic> _$DebtorRowDtoToJson(_DebtorRowDto instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'name': instance.name,
      'phone': instance.phone,
      'balance': instance.balance,
      'oldestUnpaidAt': instance.oldestUnpaidAt?.toIso8601String(),
      'lastPaymentAt': instance.lastPaymentAt?.toIso8601String(),
    };

_MemberTopRowDto _$MemberTopRowDtoFromJson(Map<String, dynamic> json) =>
    _MemberTopRowDto(
      memberId: json['memberId'] as String? ?? '',
      name: json['name'] as String?,
      visits: (json['visits'] as num?)?.toInt() ?? 0,
      spend: (json['spend'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MemberTopRowDtoToJson(_MemberTopRowDto instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'name': instance.name,
      'visits': instance.visits,
      'spend': instance.spend,
      'points': instance.points,
    };

_MoneyAuditSectionDto _$MoneyAuditSectionDtoFromJson(
  Map<String, dynamic> json,
) => _MoneyAuditSectionDto(
  rows:
      (json['rows'] as List<dynamic>?)
          ?.map((e) => MoneyAuditRowDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MoneyAuditRowDto>[],
  truncated: json['truncated'] as bool? ?? false,
);

Map<String, dynamic> _$MoneyAuditSectionDtoToJson(
  _MoneyAuditSectionDto instance,
) => <String, dynamic>{'rows': instance.rows, 'truncated': instance.truncated};

_MoneyAuditRowDto _$MoneyAuditRowDtoFromJson(Map<String, dynamic> json) =>
    _MoneyAuditRowDto(
      id: json['id'] as String,
      type: json['type'] as String,
      at: json['at'] as String? ?? '',
      title: json['title'] as String? ?? '',
      kind: json['kind'] as String?,
      params:
          (json['params'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      actorName: json['actorName'] as String?,
      tableLabel: json['tableLabel'] as String?,
      amountCents: (json['amountCents'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MoneyAuditRowDtoToJson(_MoneyAuditRowDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'at': instance.at,
      'title': instance.title,
      'kind': instance.kind,
      'params': instance.params,
      'actorName': instance.actorName,
      'tableLabel': instance.tableLabel,
      'amountCents': instance.amountCents,
    };

_StaffVoidDto _$StaffVoidDtoFromJson(Map<String, dynamic> json) =>
    _StaffVoidDto(
      id: json['id'] as String,
      name: json['name'] as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
      lostRupiah: (json['lostRupiah'] as num?)?.toInt() ?? 0,
      topReasonCode: json['topReasonCode'] as String? ?? 'other',
    );

Map<String, dynamic> _$StaffVoidDtoToJson(_StaffVoidDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'count': instance.count,
      'lostRupiah': instance.lostRupiah,
      'topReasonCode': instance.topReasonCode,
    };
