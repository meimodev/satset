// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReportsSnapshotDtoImpl _$$ReportsSnapshotDtoImplFromJson(
  Map<String, dynamic> json,
) => _$ReportsSnapshotDtoImpl(
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
  jamKerja: json['jamKerja'] == null
      ? const JamKerjaSectionDto()
      : JamKerjaSectionDto.fromJson(json['jamKerja'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$ReportsSnapshotDtoImplToJson(
  _$ReportsSnapshotDtoImpl instance,
) => <String, dynamic>{
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
  'jamKerja': instance.jamKerja,
};

_$FilterOptionsDtoImpl _$$FilterOptionsDtoImplFromJson(
  Map<String, dynamic> json,
) => _$FilterOptionsDtoImpl(
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

Map<String, dynamic> _$$FilterOptionsDtoImplToJson(
  _$FilterOptionsDtoImpl instance,
) => <String, dynamic>{
  'servers': instance.servers,
  'zones': instance.zones,
  'categories': instance.categories,
};

_$NamedIdDtoImpl _$$NamedIdDtoImplFromJson(Map<String, dynamic> json) =>
    _$NamedIdDtoImpl(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$$NamedIdDtoImplToJson(_$NamedIdDtoImpl instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_$KpiTileDtoImpl _$$KpiTileDtoImplFromJson(Map<String, dynamic> json) =>
    _$KpiTileDtoImpl(
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

Map<String, dynamic> _$$KpiTileDtoImplToJson(_$KpiTileDtoImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'args': instance.args,
      'label': instance.label,
      'rupiah': instance.rupiah,
      'value': instance.value,
      'sub': instance.sub,
    };

_$SalesSectionDtoImpl _$$SalesSectionDtoImplFromJson(
  Map<String, dynamic> json,
) => _$SalesSectionDtoImpl(
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
);

Map<String, dynamic> _$$SalesSectionDtoImplToJson(
  _$SalesSectionDtoImpl instance,
) => <String, dynamic>{
  'kpis': instance.kpis,
  'coverTrend': instance.coverTrend,
  'hourly': instance.hourly,
  'takeaway': instance.takeaway,
};

_$TakeawaySplitDtoImpl _$$TakeawaySplitDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TakeawaySplitDtoImpl(
  count: (json['count'] as num?)?.toInt() ?? 0,
  net: (json['net'] as num?)?.toInt() ?? 0,
  dineInCount: (json['dineInCount'] as num?)?.toInt() ?? 0,
  dineInNet: (json['dineInNet'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$TakeawaySplitDtoImplToJson(
  _$TakeawaySplitDtoImpl instance,
) => <String, dynamic>{
  'count': instance.count,
  'net': instance.net,
  'dineInCount': instance.dineInCount,
  'dineInNet': instance.dineInNet,
};

_$CoverDayDtoImpl _$$CoverDayDtoImplFromJson(Map<String, dynamic> json) =>
    _$CoverDayDtoImpl(
      dow: (json['dow'] as num?)?.toInt() ?? 1,
      thisWeek: (json['thisWeek'] as num).toInt(),
      lastWeek: (json['lastWeek'] as num).toInt(),
    );

Map<String, dynamic> _$$CoverDayDtoImplToJson(_$CoverDayDtoImpl instance) =>
    <String, dynamic>{
      'dow': instance.dow,
      'thisWeek': instance.thisWeek,
      'lastWeek': instance.lastWeek,
    };

_$StaffSectionDtoImpl _$$StaffSectionDtoImplFromJson(
  Map<String, dynamic> json,
) => _$StaffSectionDtoImpl(
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

Map<String, dynamic> _$$StaffSectionDtoImplToJson(
  _$StaffSectionDtoImpl instance,
) => <String, dynamic>{'rows': instance.rows, 'upsell': instance.upsell};

_$StaffRowDtoImpl _$$StaffRowDtoImplFromJson(Map<String, dynamic> json) =>
    _$StaffRowDtoImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      covers: (json['covers'] as num?)?.toInt() ?? 0,
      items: (json['items'] as num?)?.toInt() ?? 0,
      avgTicket: (json['avgTicket'] as num?)?.toInt() ?? 0,
      voidPct: (json['voidPct'] as num?)?.toDouble() ?? 0.0,
      net: (json['net'] as num?)?.toInt() ?? 0,
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$StaffRowDtoImplToJson(_$StaffRowDtoImpl instance) =>
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

_$StaffUpsellDtoImpl _$$StaffUpsellDtoImplFromJson(Map<String, dynamic> json) =>
    _$StaffUpsellDtoImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$StaffUpsellDtoImplToJson(
  _$StaffUpsellDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'rate': instance.rate,
};

_$MenuSectionDtoImpl _$$MenuSectionDtoImplFromJson(Map<String, dynamic> json) =>
    _$MenuSectionDtoImpl(
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

Map<String, dynamic> _$$MenuSectionDtoImplToJson(
  _$MenuSectionDtoImpl instance,
) => <String, dynamic>{
  'top': instance.top,
  'slow': instance.slow,
  'modifierAttach': instance.modifierAttach,
  'categoryMix': instance.categoryMix,
  'matrix': instance.matrix,
  'basketPairs': instance.basketPairs,
};

_$MenuItemRowDtoImpl _$$MenuItemRowDtoImplFromJson(Map<String, dynamic> json) =>
    _$MenuItemRowDtoImpl(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
      marginPct: (json['marginPct'] as num?)?.toInt() ?? 0,
      fill: (json['fill'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$MenuItemRowDtoImplToJson(
  _$MenuItemRowDtoImpl instance,
) => <String, dynamic>{
  'itemId': instance.itemId,
  'name': instance.name,
  'qty': instance.qty,
  'revenue': instance.revenue,
  'marginPct': instance.marginPct,
  'fill': instance.fill,
};

_$ModifierAttachDtoImpl _$$ModifierAttachDtoImplFromJson(
  Map<String, dynamic> json,
) => _$ModifierAttachDtoImpl(
  group: json['group'] as String,
  rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$ModifierAttachDtoImplToJson(
  _$ModifierAttachDtoImpl instance,
) => <String, dynamic>{'group': instance.group, 'rate': instance.rate};

_$CategoryShareDtoImpl _$$CategoryShareDtoImplFromJson(
  Map<String, dynamic> json,
) => _$CategoryShareDtoImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  shareThisWeek: (json['shareThisWeek'] as num?)?.toDouble() ?? 0.0,
  shareLastWeek: (json['shareLastWeek'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$CategoryShareDtoImplToJson(
  _$CategoryShareDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'shareThisWeek': instance.shareThisWeek,
  'shareLastWeek': instance.shareLastWeek,
};

_$MatrixItemDtoImpl _$$MatrixItemDtoImplFromJson(Map<String, dynamic> json) =>
    _$MatrixItemDtoImpl(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      margin: (json['margin'] as num?)?.toDouble() ?? 0.0,
      quadrant: json['quadrant'] as String,
    );

Map<String, dynamic> _$$MatrixItemDtoImplToJson(_$MatrixItemDtoImpl instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'name': instance.name,
      'popularity': instance.popularity,
      'margin': instance.margin,
      'quadrant': instance.quadrant,
    };

_$BasketPairDtoImpl _$$BasketPairDtoImplFromJson(Map<String, dynamic> json) =>
    _$BasketPairDtoImpl(
      itemA: json['itemA'] as String,
      itemB: json['itemB'] as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$BasketPairDtoImplToJson(_$BasketPairDtoImpl instance) =>
    <String, dynamic>{
      'itemA': instance.itemA,
      'itemB': instance.itemB,
      'count': instance.count,
      'rate': instance.rate,
    };

_$OpsSectionDtoImpl _$$OpsSectionDtoImplFromJson(Map<String, dynamic> json) =>
    _$OpsSectionDtoImpl(
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

Map<String, dynamic> _$$OpsSectionDtoImplToJson(_$OpsSectionDtoImpl instance) =>
    <String, dynamic>{
      'kpis': instance.kpis,
      'speed': instance.speed,
      'stations': instance.stations,
      'heatmap': instance.heatmap,
      'reservations': instance.reservations,
      'voidReasons': instance.voidReasons,
      'voidByStaff': instance.voidByStaff,
    };

_$SpeedSectionDtoImpl _$$SpeedSectionDtoImplFromJson(
  Map<String, dynamic> json,
) => _$SpeedSectionDtoImpl(
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

Map<String, dynamic> _$$SpeedSectionDtoImplToJson(
  _$SpeedSectionDtoImpl instance,
) => <String, dynamic>{
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

_$SpeedItemDtoImpl _$$SpeedItemDtoImplFromJson(Map<String, dynamic> json) =>
    _$SpeedItemDtoImpl(
      itemId: json['itemId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avgPrepMin: (json['avgPrepMin'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$SpeedItemDtoImplToJson(_$SpeedItemDtoImpl instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'name': instance.name,
      'avgPrepMin': instance.avgPrepMin,
      'count': instance.count,
    };

_$StationRowDtoImpl _$$StationRowDtoImplFromJson(Map<String, dynamic> json) =>
    _$StationRowDtoImpl(
      station: json['station'] as String,
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      utilization: (json['utilization'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$StationRowDtoImplToJson(_$StationRowDtoImpl instance) =>
    <String, dynamic>{
      'station': instance.station,
      'qty': instance.qty,
      'utilization': instance.utilization,
    };

_$ReservationStatsDtoImpl _$$ReservationStatsDtoImplFromJson(
  Map<String, dynamic> json,
) => _$ReservationStatsDtoImpl(
  booked: (json['booked'] as num?)?.toInt() ?? 0,
  seated: (json['seated'] as num?)?.toInt() ?? 0,
  noShow: (json['noShow'] as num?)?.toInt() ?? 0,
  cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$ReservationStatsDtoImplToJson(
  _$ReservationStatsDtoImpl instance,
) => <String, dynamic>{
  'booked': instance.booked,
  'seated': instance.seated,
  'noShow': instance.noShow,
  'cancelled': instance.cancelled,
};

_$VoidReasonDtoImpl _$$VoidReasonDtoImplFromJson(Map<String, dynamic> json) =>
    _$VoidReasonDtoImpl(
      code: json['code'] as String,
      label: json['label'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      lostRupiah: (json['lostRupiah'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$VoidReasonDtoImplToJson(_$VoidReasonDtoImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'label': instance.label,
      'count': instance.count,
      'lostRupiah': instance.lostRupiah,
    };

_$KasSectionDtoImpl _$$KasSectionDtoImplFromJson(Map<String, dynamic> json) =>
    _$KasSectionDtoImpl(
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

Map<String, dynamic> _$$KasSectionDtoImplToJson(_$KasSectionDtoImpl instance) =>
    <String, dynamic>{
      'opening': instance.opening,
      'inflow': instance.inflow,
      'outflow': instance.outflow,
      'variance': instance.variance,
      'closing': instance.closing,
      'byCategory': instance.byCategory,
      'count': instance.count,
    };

_$JamKerjaSectionDtoImpl _$$JamKerjaSectionDtoImplFromJson(
  Map<String, dynamic> json,
) => _$JamKerjaSectionDtoImpl(
  staff:
      (json['staff'] as List<dynamic>?)
          ?.map((e) => JamKerjaRowDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <JamKerjaRowDto>[],
  dayStartHour: (json['dayStartHour'] as num?)?.toInt() ?? 4,
  unclosed: (json['unclosed'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$JamKerjaSectionDtoImplToJson(
  _$JamKerjaSectionDtoImpl instance,
) => <String, dynamic>{
  'staff': instance.staff,
  'dayStartHour': instance.dayStartHour,
  'unclosed': instance.unclosed,
};

_$JamKerjaRowDtoImpl _$$JamKerjaRowDtoImplFromJson(Map<String, dynamic> json) =>
    _$JamKerjaRowDtoImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      shifts: (json['shifts'] as num?)?.toInt() ?? 0,
      days: (json['days'] as num?)?.toInt() ?? 0,
      unclosed: (json['unclosed'] as num?)?.toInt() ?? 0,
      medianFirstIn: (json['medianFirstIn'] as num?)?.toInt(),
      lastSeen: json['lastSeen'] as String?,
    );

Map<String, dynamic> _$$JamKerjaRowDtoImplToJson(
  _$JamKerjaRowDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'minutes': instance.minutes,
  'shifts': instance.shifts,
  'days': instance.days,
  'unclosed': instance.unclosed,
  'medianFirstIn': instance.medianFirstIn,
  'lastSeen': instance.lastSeen,
};

_$MembersSectionDtoImpl _$$MembersSectionDtoImplFromJson(
  Map<String, dynamic> json,
) => _$MembersSectionDtoImpl(
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

Map<String, dynamic> _$$MembersSectionDtoImplToJson(
  _$MembersSectionDtoImpl instance,
) => <String, dynamic>{
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

_$MemberTopRowDtoImpl _$$MemberTopRowDtoImplFromJson(
  Map<String, dynamic> json,
) => _$MemberTopRowDtoImpl(
  memberId: json['memberId'] as String? ?? '',
  name: json['name'] as String?,
  visits: (json['visits'] as num?)?.toInt() ?? 0,
  spend: (json['spend'] as num?)?.toInt() ?? 0,
  points: (json['points'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$MemberTopRowDtoImplToJson(
  _$MemberTopRowDtoImpl instance,
) => <String, dynamic>{
  'memberId': instance.memberId,
  'name': instance.name,
  'visits': instance.visits,
  'spend': instance.spend,
  'points': instance.points,
};

_$MoneyAuditSectionDtoImpl _$$MoneyAuditSectionDtoImplFromJson(
  Map<String, dynamic> json,
) => _$MoneyAuditSectionDtoImpl(
  rows:
      (json['rows'] as List<dynamic>?)
          ?.map((e) => MoneyAuditRowDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MoneyAuditRowDto>[],
  truncated: json['truncated'] as bool? ?? false,
);

Map<String, dynamic> _$$MoneyAuditSectionDtoImplToJson(
  _$MoneyAuditSectionDtoImpl instance,
) => <String, dynamic>{'rows': instance.rows, 'truncated': instance.truncated};

_$MoneyAuditRowDtoImpl _$$MoneyAuditRowDtoImplFromJson(
  Map<String, dynamic> json,
) => _$MoneyAuditRowDtoImpl(
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

Map<String, dynamic> _$$MoneyAuditRowDtoImplToJson(
  _$MoneyAuditRowDtoImpl instance,
) => <String, dynamic>{
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

_$StaffVoidDtoImpl _$$StaffVoidDtoImplFromJson(Map<String, dynamic> json) =>
    _$StaffVoidDtoImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
      lostRupiah: (json['lostRupiah'] as num?)?.toInt() ?? 0,
      topReasonCode: json['topReasonCode'] as String? ?? 'other',
    );

Map<String, dynamic> _$$StaffVoidDtoImplToJson(_$StaffVoidDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'count': instance.count,
      'lostRupiah': instance.lostRupiah,
      'topReasonCode': instance.topReasonCode,
    };
