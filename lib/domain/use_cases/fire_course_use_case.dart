import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/course.dart';

class FireCourseUseCase {
  FireCourseUseCase(this._tickets);
  final TicketsRepository _tickets;

  Future<void> call(String tableId, CourseId course) =>
      _tickets.fireCourse(tableId, course);
}

final fireCourseUseCaseProvider = Provider<FireCourseUseCase>((ref) {
  return FireCourseUseCase(ref.watch(ticketsProvider.notifier));
});
