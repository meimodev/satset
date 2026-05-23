import 'package:freezed_annotation/freezed_annotation.dart';

part 'zone.freezed.dart';

/// Domain model for floor zones. Visual concerns (Color/IconData and the
/// admin-picker presets) live in `lib/ui/core/design/zone_visuals.dart`.
/// This layer carries no Flutter imports.
@freezed
class Zone with _$Zone {
  const factory Zone({
    required String id,
    required String name,
    required String short,

    /// 0xAARRGGBB hex. UI wraps this in `Color(...)`.
    @Default(0xFFFF9233) int colorHex,

    /// Stable key (e.g. `tableRestaurant`). UI maps it to an `IconData`.
    @Default('tableRestaurant') String iconKey,
  }) = _Zone;
}

/// Primitive presets the UI helpers map to Color/IconData.
class ZonePresets {
  ZonePresets._();

  static const colorHexes = <int>[
    0xFFFF9233,
    0xFF4DD487,
    0xFF6DB5FF,
    0xFFC08AFF,
    0xFFFFC04D,
    0xFFFF5C5C,
    0xFF7ED6C4,
    0xFFE48BB7,
  ];

  static const iconKeys = <String>[
    'tableRestaurant',
    'deck',
    'park',
    'localBar',
    'weekend',
    'balcony',
    'roofing',
    'eventSeat',
    'window',
    'umbrella',
    'celebration',
    'storefront',
  ];
}
