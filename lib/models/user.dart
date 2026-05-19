import 'package:flutter/material.dart';

enum UserRole { waiter, chef, manager, admin }

class User {
  final String id;
  final String username;
  final String displayName;
  final UserRole role;

  const User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
  });

  IconData get roleIcon {
    switch (role) {
      case UserRole.waiter:
        return Icons.room_service;
      case UserRole.chef:
        return Icons.restaurant;
      case UserRole.manager:
        return Icons.insights;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  String get initials => displayName
      .split(' ')
      .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
      .take(2)
      .join();
}
