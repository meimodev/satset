import 'package:flutter/material.dart';

import 'package:satset/domain/models/role.dart';

/// UI mapping for [Role] primitive colorHex metadata.
extension RoleVisuals on Role {
  Color get color => Color(colorHex);
}
