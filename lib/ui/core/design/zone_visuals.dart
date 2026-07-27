import 'package:flutter/material.dart';

import 'package:satset/domain/models/zone.dart';

/// UI mapping for [Zone] primitive metadata (colorHex/iconKey).
extension ZoneVisuals on Zone {
  Color get color => Color(colorHex);
  IconData get icon => zoneIconFromKey(iconKey);
}

const _zoneIcons = <String, IconData>{
  'tableRestaurant': Icons.table_restaurant_outlined,
  'deck': Icons.deck_outlined,
  'park': Icons.park_outlined,
  'localBar': Icons.local_bar_outlined,
  'weekend': Icons.weekend_outlined,
  'balcony': Icons.balcony_outlined,
  'roofing': Icons.roofing_outlined,
  'eventSeat': Icons.event_seat_outlined,
  'window': Icons.window_outlined,
  'umbrella': Icons.umbrella_outlined,
  'celebration': Icons.celebration_outlined,
  'storefront': Icons.storefront_outlined,
};

IconData zoneIconFromKey(String key) =>
    _zoneIcons[key] ?? Icons.table_restaurant_outlined;

String zoneIconKeyFromIcon(IconData icon) {
  for (final e in _zoneIcons.entries) {
    if (e.value == icon) return e.key;
  }
  return 'tableRestaurant';
}

/// Convenience for admin pickers — same shape as the old
/// `ZonePresets.colors` / `ZonePresets.icons` lists.
List<Color> get zoneColorPresets => [
  for (final h in ZonePresets.colorHexes) Color(h),
];
List<IconData> get zoneIconPresets => [
  for (final k in ZonePresets.iconKeys) zoneIconFromKey(k),
];
