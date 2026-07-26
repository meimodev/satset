import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/service_timing.dart';

TimedLine _line({
  String visit = 'v1',
  String course = 'mains',
  required DateTime start,
  DateTime? readyAt,
  required int targetMins,
}) =>
    TimedLine(
      visitKey: visit,
      course: course,
      start: start,
      readyAt: readyAt,
      targetMins: targetMins,
    );

void main() {
  final t1900 = DateTime(2026, 7, 26, 19);

  group('resolvePrepMins', () {
    test('null inherits the venue default', () {
      expect(resolvePrepMins(null, 15), 15);
    });
    test('a value overrides it', () {
      expect(resolvePrepMins(25, 15), 25);
    });
    test('inherit is live — a new default moves the unset item', () {
      expect(resolvePrepMins(null, 20), 20);
    });
  });

  group('course rollup', () {
    test('the slowest dish paces the course', () {
      final c = rollUpCourses([
        _line(start: t1900, targetMins: 6), // kentang
        _line(start: t1900, targetMins: 25), // steak
      ]).single;
      expect(c.targetMins, 25);
      expect(c.lineCount, 2);
    });

    test('sides are not late for waiting on their mains', () {
      // Kentang (6m target) ready at +22m. Judged alone it blew its target;
      // judged as part of a 25m course it is on time. This is the whole point
      // of course-as-unit (ADR-0043).
      final c = rollUpCourses([
        _line(
          start: t1900,
          readyAt: t1900.add(const Duration(minutes: 22)),
          targetMins: 6,
        ),
        _line(
          start: t1900,
          readyAt: t1900.add(const Duration(minutes: 20)),
          targetMins: 25,
        ),
      ]).single;
      expect(c.prep, const Duration(minutes: 22));
      expect(c.onTime, isTrue);
      expect(c.missedTarget, isFalse);
    });

    test('a course is ready only when its last line is ready', () {
      final c = rollUpCourses([
        _line(
          start: t1900,
          readyAt: t1900.add(const Duration(minutes: 5)),
          targetMins: 10,
        ),
        _line(start: t1900, readyAt: null, targetMins: 10),
      ]).single;
      expect(c.isComplete, isFalse);
      expect(c.prep, isNull);
      expect(c.onTime, isFalse);
    });

    test('a completed course past its target missed it', () {
      final c = rollUpCourses([
        _line(
          start: t1900,
          readyAt: t1900.add(const Duration(minutes: 31)),
          targetMins: 25,
        ),
      ]).single;
      expect(c.missedTarget, isTrue);
      expect(c.onTime, isFalse);
    });

    test('still cooking past target is the live overdue condition', () {
      final c = rollUpCourses([
        _line(start: t1900, readyAt: null, targetMins: 25),
      ]).single;
      expect(c.isOverdueAt(t1900.add(const Duration(minutes: 24))), isFalse);
      expect(c.isOverdueAt(t1900.add(const Duration(minutes: 26))), isTrue);
    });

    test('a held course fired late is not born overdue', () {
      // Ordered 19:00, held, fired 19:40. `start` is the fire, so at 19:45 it
      // is 5 minutes old, not 45. Without firedAt this course would alarm the
      // instant the kitchen first saw it.
      final firedAt = t1900.add(const Duration(minutes: 40));
      final c = rollUpCourses([
        _line(start: firedAt, readyAt: null, targetMins: 25),
      ]).single;
      expect(c.firedAt, firedAt);
      expect(c.isOverdueAt(firedAt.add(const Duration(minutes: 5))), isFalse);
    });

    test('drinks and mains sent together are separate courses', () {
      final courses = rollUpCourses([
        _line(course: 'drinks-now', start: t1900, targetMins: 2),
        _line(course: 'mains', start: t1900, targetMins: 25),
      ]);
      expect(courses.length, 2);
      expect(
        courses.map((c) => c.targetMins).toSet(),
        {2, 25},
      );
    });

    test('lines ordered apart but fired together group as one course', () {
      // Both held, both fired in one server op ⇒ identical `start`.
      final firedAt = t1900.add(const Duration(minutes: 40));
      final courses = rollUpCourses([
        _line(start: firedAt, targetMins: 12),
        _line(start: firedAt, targetMins: 25),
      ]);
      expect(courses.length, 1);
      expect(courses.single.targetMins, 25);
    });

    test('separate visits never share a course', () {
      final courses = rollUpCourses([
        _line(visit: 'v1', start: t1900, targetMins: 10),
        _line(visit: 'v2', start: t1900, targetMins: 10),
      ]);
      expect(courses.length, 2);
    });
  });
}
