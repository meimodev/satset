import 'package:flutter/material.dart';

class Zone {
  final String id;
  final String name;
  final String short;
  final Color color;
  final IconData icon;

  const Zone({
    required this.id,
    required this.name,
    required this.short,
    this.color = const Color(0xFFFF9233),
    this.icon = Icons.table_restaurant_outlined,
  });

  Zone copyWith({
    String? name,
    String? short,
    Color? color,
    IconData? icon,
  }) =>
      Zone(
        id: id,
        name: name ?? this.name,
        short: short ?? this.short,
        color: color ?? this.color,
        icon: icon ?? this.icon,
      );
}

class ZonePresets {
  ZonePresets._();

  static const colors = <Color>[
    Color(0xFFFF9233),
    Color(0xFF4DD487),
    Color(0xFF6DB5FF),
    Color(0xFFC08AFF),
    Color(0xFFFFC04D),
    Color(0xFFFF5C5C),
    Color(0xFF7ED6C4),
    Color(0xFFE48BB7),
  ];

  static const icons = <IconData>[
    Icons.table_restaurant_outlined,
    Icons.deck_outlined,
    Icons.park_outlined,
    Icons.local_bar_outlined,
    Icons.weekend_outlined,
    Icons.balcony_outlined,
    Icons.roofing_outlined,
    Icons.event_seat_outlined,
    Icons.window_outlined,
    Icons.umbrella_outlined,
    Icons.celebration_outlined,
    Icons.storefront_outlined,
  ];
}
