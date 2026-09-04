// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_expense_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VisitExpenseDto _$VisitExpenseDtoFromJson(Map<String, dynamic> json) =>
    _VisitExpenseDto(
      id: json['id'] as String,
      visitId: json['visitId'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      note: json['note'] as String? ?? '',
      hasPhoto: json['hasPhoto'] as bool? ?? true,
      actorUserId: json['actorUserId'] as String?,
      actorName: json['actorName'] as String?,
      at: json['at'] == null ? null : DateTime.parse(json['at'] as String),
    );

Map<String, dynamic> _$VisitExpenseDtoToJson(_VisitExpenseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'visitId': instance.visitId,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'amount': instance.amount,
      'note': instance.note,
      'hasPhoto': instance.hasPhoto,
      'actorUserId': instance.actorUserId,
      'actorName': instance.actorName,
      'at': instance.at?.toIso8601String(),
    };

_VisitExpenseCategoryDto _$VisitExpenseCategoryDtoFromJson(
  Map<String, dynamic> json,
) => _VisitExpenseCategoryDto(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  active: json['active'] as bool? ?? true,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$VisitExpenseCategoryDtoToJson(
  _VisitExpenseCategoryDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'active': instance.active,
  'sortOrder': instance.sortOrder,
};

_VisitExpenseSummaryDto _$VisitExpenseSummaryDtoFromJson(
  Map<String, dynamic> json,
) => _VisitExpenseSummaryDto(
  expenses:
      (json['expenses'] as List<dynamic>?)
          ?.map((e) => VisitExpenseDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <VisitExpenseDto>[],
  total: (json['total'] as num?)?.toInt() ?? 0,
  cap: (json['cap'] as num?)?.toInt() ?? 0,
  offline: json['offline'] as bool? ?? false,
);

Map<String, dynamic> _$VisitExpenseSummaryDtoToJson(
  _VisitExpenseSummaryDto instance,
) => <String, dynamic>{
  'expenses': instance.expenses,
  'total': instance.total,
  'cap': instance.cap,
  'offline': instance.offline,
};
