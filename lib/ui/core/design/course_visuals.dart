import 'package:flutter/material.dart';

import 'package:satset/domain/models/course.dart';
import 'package:satset/ui/core/design/colors.dart';

/// Visual mapping for [Course] / [CourseId]. Lives in the UI layer so the
/// domain model carries no Flutter imports.
extension CourseVisuals on Course {
  Color color(SatColors sc) => courseColor(id, sc);
}

Color courseColor(CourseId id, SatColors sc) => switch (id) {
      CourseId.drinksNow => sc.cDrinks,
      CourseId.starters => sc.cStarters,
      CourseId.mains => sc.cMains,
      CourseId.sides => sc.cMains,
      CourseId.desserts => sc.cDesserts,
      CourseId.fireNow => sc.cFire,
    };
