import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/ui/features/menu/view_models/menu_view_model.dart';

MenuItem _item(String id, String cat, String name, String desc) => MenuItem(
  id: id,
  name: name,
  categoryId: cat,
  description: desc,
  basePrice: 20000,
  variants: const [],
);

final _menu = [
  _item('m1', 'mains', 'Nasi Goreng', 'Nasi, telur, ayam suwir'),
  _item('m2', 'mains', 'Mie Goreng', 'Mie kuning, sawi, cabai segar'),
  _item('d1', 'drinks', 'Es Teh Manis', 'Teh melati, gula aren'),
  _item('d2', 'drinks', 'Margarita', 'Tequila, lime, agave, cabai segar'),
];

List<String> _ids(List<MenuItem> items) => items.map((i) => i.id).toList();

void main() {
  group('filterMenuItems', () {
    test('empty query filters by category', () {
      expect(_ids(filterMenuItems(_menu, categoryId: 'drinks', query: '')), [
        'd1',
        'd2',
      ]);
    });

    test("category 'all' with empty query keeps everything", () {
      expect(_ids(filterMenuItems(_menu, categoryId: 'all', query: '')), [
        'm1',
        'm2',
        'd1',
        'd2',
      ]);
    });

    test('query ignores the category and searches the whole menu', () {
      // 'mains' is active, but the hit lives in 'drinks'.
      expect(
        _ids(filterMenuItems(_menu, categoryId: 'mains', query: 'es teh')),
        ['d1'],
      );
    });

    test('matches the description, not just the name', () {
      expect(
        _ids(filterMenuItems(_menu, categoryId: 'mains', query: 'cabai')),
        ['m2', 'd2'],
      );
    });

    test('is case-insensitive and trims', () {
      expect(
        _ids(filterMenuItems(_menu, categoryId: 'mains', query: '  GORENG ')),
        ['m1', 'm2'],
      );
    });

    test('whitespace-only query is treated as empty', () {
      expect(_ids(filterMenuItems(_menu, categoryId: 'drinks', query: '   ')), [
        'd1',
        'd2',
      ]);
    });

    test('no match yields an empty list', () {
      expect(
        filterMenuItems(_menu, categoryId: 'mains', query: 'rendang'),
        isEmpty,
      );
    });
  });

  // [[Menu populer]] (ADR-0113).
  group('filterMenuItems rank', () {
    test('ranked items lead, highest first', () {
      expect(
        _ids(
          filterMenuItems(
            _menu,
            categoryId: 'all',
            query: '',
            rank: const {'d2': 3, 'm2': 40},
          ),
        ),
        ['m2', 'd2', 'd1', 'm1'],
      );
    });

    test('unranked items trail, alphabetically', () {
      // Es Teh · Margarita · Mie Goreng · Nasi Goreng — insertion order had
      // Nasi Goreng first.
      expect(
        _ids(
          filterMenuItems(
            _menu,
            categoryId: 'all',
            query: '',
            rank: const {},
          ),
        ),
        ['d1', 'd2', 'm2', 'm1'],
      );
    });

    test('rank applies inside a category too', () {
      expect(
        _ids(
          filterMenuItems(
            _menu,
            categoryId: 'mains',
            query: '',
            rank: const {'m2': 9},
          ),
        ),
        ['m2', 'm1'],
      );
    });

    test('search results keep server order, unranked', () {
      expect(
        _ids(
          filterMenuItems(
            _menu,
            categoryId: 'all',
            query: 'cabai',
            rank: const {'d2': 99},
          ),
        ),
        ['m2', 'd2'],
      );
    });

    test('no rank leaves the order alone', () {
      expect(_ids(filterMenuItems(_menu, categoryId: 'all', query: '')), [
        'm1',
        'm2',
        'd1',
        'd2',
      ]);
    });
  });
}
