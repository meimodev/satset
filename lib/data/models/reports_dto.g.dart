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
      label: json['label'] as String,
      value: json['value'] as String,
      sub: json['sub'] as String,
    );

Map<String, dynamic> _$$KpiTileDtoImplToJson(_$KpiTileDtoImpl instance) =>
    <String, dynamic>{
      'label': instance.label,
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
);

Map<String, dynamic> _$$SalesSectionDtoImplToJson(
  _$SalesSectionDtoImpl instance,
) => <String, dynamic>{
  'kpis': instance.kpis,
  'coverTrend': instance.coverTrend,
  'hourly': instance.hourly,
};

_$CoverDayDtoImpl _$$CoverDayDtoImplFromJson(Map<String, dynamic> json) =>
    _$CoverDayDtoImpl(
      day: json['day'] as String,
      thisWeek: (json['thisWeek'] as num).toInt(),
      lastWeek: (json['lastWeek'] as num).toInt(),
    );

Map<String, dynamic> _$$CoverDayDtoImplToJson(_$CoverDayDtoImpl instance) =>
    <String, dynamic>{
      'day': instance.day,
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
      'stations': instance.stations,
      'heatmap': instance.heatmap,
      'reservations': instance.reservations,
      'voidReasons': instance.voidReasons,
      'voidByStaff': instance.voidByStaff,
    };

_$StationRowDtoImpl _$$StationRowDtoImplFromJson(Map<String, dynamic> json) =>
    _$StationRowDtoImpl(
      station: json['station'] as String,
      label: json['label'] as String,
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      utilization: (json['utilization'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$StationRowDtoImplToJson(_$StationRowDtoImpl instance) =>
    <String, dynamic>{
      'station': instance.station,
      'label': instance.label,
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
      label: json['label'] as String,
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

_$StaffVoidDtoImpl _$$StaffVoidDtoImplFromJson(Map<String, dynamic> json) =>
    _$StaffVoidDtoImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
      lostRupiah: (json['lostRupiah'] as num?)?.toInt() ?? 0,
      topReasonCode: json['topReasonCode'] as String? ?? 'other',
      topReasonLabel: json['topReasonLabel'] as String? ?? 'Lainnya',
    );

Map<String, dynamic> _$$StaffVoidDtoImplToJson(_$StaffVoidDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'count': instance.count,
      'lostRupiah': instance.lostRupiah,
      'topReasonCode': instance.topReasonCode,
      'topReasonLabel': instance.topReasonLabel,
    };
