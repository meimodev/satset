import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/server/db/database.dart';

Router menuRoutes(AppDatabase db) {
  final r = Router();

  r.get('/menu', (Request req) async {
    final cats = await db.select(db.menuCategories).get();
    final items = await db.select(db.menuItems).get();
    final mods = await db.select(db.modifierGroups).get();
    return Response.ok(
      jsonEncode({
        'version': 1,
        'categories': [
          for (final c in cats) {'id': c.id, 'name': c.name}
        ],
        'items': [
          for (final it in items)
            {
              'id': it.id,
              'name': it.name,
              'categoryId': it.categoryId,
              'station': it.station,
              'description': it.description,
              'basePrice': it.basePrice,
              'prepTime': it.prepTime,
              'variants': jsonDecode(it.variantsJson),
              'modifierGroupIds': jsonDecode(it.modifierGroupIdsJson),
              'allergens': jsonDecode(it.allergensJson),
              'dietary': jsonDecode(it.dietaryJson),
              'unavailable': it.unavailable,
              'stockCount': it.stockCount,
              'autoEightySixAtZero': it.autoEightySixAtZero,
            }
        ],
        'modifierGroups': [
          for (final m in mods)
            {
              'id': m.id,
              'name': m.name,
              'required': m.required,
              'multi': m.multi,
              'options': jsonDecode(m.optionsJson),
            }
        ],
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  return r;
}
