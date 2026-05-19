import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const card = BoxShadow(
    color: Color(0x264A3728),
    blurRadius: 16,
    offset: Offset(0, 4),
    spreadRadius: -4,
  );

  static const elevated = BoxShadow(
    color: Color(0x1A4A3728),
    blurRadius: 24,
    offset: Offset(0, 8),
    spreadRadius: -6,
  );
}
