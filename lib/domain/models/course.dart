import 'package:freezed_annotation/freezed_annotation.dart';

part 'course.freezed.dart';

/// Domain model for menu courses. Visual mapping lives in
/// `lib/ui/core/design/course_visuals.dart` so this layer carries no
/// Flutter imports.
enum CourseId { drinksNow, starters, mains, sides, desserts, fireNow }

@freezed
class Course with _$Course {
  const Course._();

  const factory Course({
    required CourseId id,
    required String name,
    required String short,
  }) = _Course;

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
  static const drinksNow = Course(
    id: CourseId.drinksNow,
    name: 'Minum dulu',
    short: 'Min',
  );
  static const starters = Course(
    id: CourseId.starters,
    name: 'Pembuka',
    short: 'Pem',
  );
  static const mains = Course(id: CourseId.mains, name: 'Utama', short: 'Ut');
  static const sides = Course(
    id: CourseId.sides,
    name: 'Bersama Utama',
    short: 'B/Ut',
  );
  static const desserts = Course(
    id: CourseId.desserts,
    name: 'Penutup',
    short: 'Pnp',
  );
  static const fireNow = Course(
    id: CourseId.fireNow,
    name: 'Langsung',
    short: 'Lgs',
  );

  static const all = [drinksNow, starters, mains, sides, desserts, fireNow];
  static const stationOrder = [drinksNow, starters, mains, sides, desserts];

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
