import 'package:freezed_annotation/freezed_annotation.dart';

part 'course.freezed.dart';

/// Domain model for menu courses. Visual mapping lives in
/// `lib/ui/core/design/course_visuals.dart` so this layer carries no
/// Flutter imports.
///
/// A course has no `name` here: its display name is copy, and lives in the
/// ARB under `courseDrinksNow`… — read it with `courseLabel(l10n, serialId)`
/// from `core/localization/labels.dart`.
enum CourseId { drinksNow, starters, mains, sides, desserts, fireNow }

@freezed
abstract class Course with _$Course {
  const Course._();

  const factory Course({required CourseId id}) = _Course;

  String get serialId => switch (id) {
    CourseId.drinksNow => 'drinks-now',
    CourseId.starters => 'starters',
    CourseId.mains => 'mains',
    CourseId.sides => 'sides',
    CourseId.desserts => 'desserts',
    CourseId.fireNow => 'fire-now',
  };
}

class Courses {
  Courses._();
  static const drinksNow = Course(id: CourseId.drinksNow);
  static const starters = Course(id: CourseId.starters);
  static const mains = Course(id: CourseId.mains);
  static const sides = Course(id: CourseId.sides);
  static const desserts = Course(id: CourseId.desserts);
  static const fireNow = Course(id: CourseId.fireNow);

  /// Every course, in the order a screen renders them. The one list — a
  /// second, shorter one omitted `fireNow` and a table's fire-now lines
  /// rendered nowhere at all.
  static const all = [drinksNow, starters, mains, sides, desserts, fireNow];

  static Course byId(CourseId id) => all.firstWhere((c) => c.id == id);

  static CourseId fromCategory(String cat) {
    if (['cocktails', 'wine', 'beer', 'soft'].contains(cat)) {
      return CourseId.drinksNow;
    }
    if (cat == 'starters') return CourseId.starters;
    if (cat == 'mains') return CourseId.mains;
    if (cat == 'desserts') return CourseId.desserts;
    if (cat == 'sides') return CourseId.mains;
    return CourseId.fireNow;
  }
}
