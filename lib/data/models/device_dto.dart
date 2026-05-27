import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_dto.freezed.dart';
part 'device_dto.g.dart';

@freezed
class DeviceDto with _$DeviceDto {
  const factory DeviceDto({
    required String id,
    required String label,
    required DateTime pairedAt,
    @Default(false) bool revoked,
    DateTime? lastSessionAt,
    String? lastSessionUserId,
    @Default(false) bool sessionActive,
  }) = _DeviceDto;

  factory DeviceDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceDtoFromJson(json);
}
