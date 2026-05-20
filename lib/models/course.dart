import 'package:flutter/material.dart';
import '../design/colors.dart';

enum CourseId { drinksNow, starters, mains, sides, desserts, fireNow }

class Course {
  final CourseId id;
  final String name;
  final String short;
  const Course({required this.id, required this.name, required this.short});

  String get serialId => switch (id) {
        CourseId.drinksNow => 'drinks-now',
        CourseId.starters => 'starters',
        CourseId.mains => 'mains',
        CourseId.sides => 'sides',
        CourseId.desserts => 'desserts',
        CourseId.fireNow => 'fire-now',
      };

  Color color(SatColors sc) => switch (id) {
        CourseId.drinksNow => sc.cDrinks,
        CourseId.starters => sc.cStarters,
        CourseId.mains => sc.cMains,
        CourseId.sides => sc.cMains,
        CourseId.desserts => sc.cDesserts,
        CourseId.fireNow => sc.cFire,
      };
}

class Courses {
  Courses._();
  static const drinksNow = Course(id: CourseId.drinksNow, name: 'Minum dulu', short: 'Min');
  static const starters = Course(id: CourseId.starters, name: 'Pembuka', short: 'Pem');
  static const mains = Course(id: CourseId.mains, name: 'Utama', short: 'Ut');
  static const sides = Course(id: CourseId.sides, name: 'Bersama Utama', short: 'B/Ut');
  static const desserts = Course(id: CourseId.desserts, name: 'Penutup', short: 'Pnp');
  static const fireNow = Course(id: CourseId.fireNow, name: 'Langsung', short: 'Lgs');

  static const all = [drinksNow, starters, mains, sides, desserts, fireNow];
  static const stationOrder = [drinksNow, starters, mains, sides, desserts];

  static Course byId(CourseId id) => all.firstWhere((c) => c.id == id);

  static CourseId fromCategory(String cat) {
    if (['cocktails', 'wine', 'beer', 'soft'].contains(cat)) return CourseId.drinksNow;
    if (cat == 'starters') return CourseId.starters;
    if (cat == 'mains') return CourseId.mains;
    if (cat == 'desserts') return CourseId.desserts;
    if (cat == 'sides') return CourseId.mains;
    return CourseId.fireNow;
  }
}
