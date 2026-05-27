import 'package:freezed_annotation/freezed_annotation.dart';

part 'printer_dto.freezed.dart';
part 'printer_dto.g.dart';

@freezed
class PrinterDto with _$PrinterDto {
  const factory PrinterDto({
    required String id,
    required String label,
    required String host,
    @Default(9100) int port,
    @Default('escpos') String kind,
    @Default(true) bool enabled,
    DateTime? lastSeenAt,
    required DateTime createdAt,
  }) = _PrinterDto;

  factory PrinterDto.fromJson(Map<String, dynamic> json) =>
      _$PrinterDtoFromJson(json);
}
