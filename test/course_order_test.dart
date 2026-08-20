import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/course.dart';

void main() {
  // A screen groups a table's lines by walking `Courses.all`, so a course
  // missing from it is a line that renders nowhere. This is exactly how
  // fire-now lines — every open item is one — went invisible on the table
  // detail screen while the table itself still counted them.
  test('every course is in the list the screens walk', () {
    expect(Courses.all.map((c) => c.id).toSet(), CourseId.values.toSet());
    expect(Courses.all.length, CourseId.values.length);
  });
}
