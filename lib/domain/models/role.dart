import 'package:flutter/material.dart';
import 'package:satset/domain/models/capability.dart';

class Role {
  final String id;
  final String name;
  final Color color;
  final Set<Capability> capabilities;

  const Role({
    required this.id,
    required this.name,
    required this.color,
    this.capabilities = const {},
  });

  Role copyWith({String? name, Color? color, Set<Capability>? capabilities}) =>
      Role(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        capabilities: capabilities ?? this.capabilities,
      );

  bool has(Capability c) => capabilities.contains(c);
}
