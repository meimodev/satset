import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:satset/domain/models/capability.dart';

part 'role.freezed.dart';

/// Domain model for staff roles. Visual mapping (colorHex → Color) lives
/// in `lib/ui/core/design/role_visuals.dart` so this layer carries no
/// Flutter imports.
@freezed
abstract class Role with _$Role {
  const Role._();

  const factory Role({
    required String id,
    required String name,

    /// 0xAARRGGBB hex. UI wraps in `Color(...)`.
    required int colorHex,
    @Default(<Capability>{}) Set<Capability> capabilities,
  }) = _Role;

  bool has(Capability c) => capabilities.contains(c);
}
