import 'package:flutter_test/flutter_test.dart';

import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket_modifier.dart';
import 'package:satset/ui/features/menu/view_models/cart_view_model.dart';

/// Builds a line with everything defaulted to "the same dish" so each test
/// only states the field it is varying. See ADR-0060.
CartItem line({
  String id = 'C1',
  String itemId = 'nasgor',
  String variantId = 'reguler',
  List<TicketModifier> mods = const [],
  String note = '',
  CourseId course = CourseId.mains,
  int qty = 1,
  int unitPrice = 28000,
  String? memberId,
}) => CartItem(
  id: id,
  itemId: itemId,
  name: 'Nasi Goreng',
  variantId: variantId,
  variantName: 'Reguler',
  memberId: memberId,
  modifiers: [for (final m in mods) m.display],
  selectedModifiers: mods,
  note: note,
  course: course,
  qty: qty,
  unitPrice: unitPrice,
);

const pedas = TicketModifier(groupId: 'spice', optionId: 'hot', label: 'Pedas');
const noIce = TicketModifier(
  groupId: 'ice',
  optionId: 'none',
  label: 'Tanpa es',
);

void main() {
  group('add stacks identical lines', () {
    test('same dish, same config → one line with summed qty', () {
      final vm = CartViewModel()
        ..add(line(id: 'C1', qty: 2))
        ..add(line(id: 'C2', qty: 3));

      expect(vm.state.length, 1);
      expect(vm.state.single.qty, 5);
      // The older id survives so a stepper bound to it keeps its identity.
      expect(vm.state.single.id, 'C1');
    });

    test('modifier order does not matter', () {
      final vm = CartViewModel()
        ..add(line(id: 'C1', mods: const [pedas, noIce]))
        ..add(line(id: 'C2', mods: const [noIce, pedas]));

      expect(vm.state.length, 1);
      expect(vm.state.single.qty, 2);
    });

    test('a subset of the modifiers is not a match', () {
      final vm = CartViewModel()
        ..add(line(id: 'C1', mods: const [pedas, noIce]))
        ..add(line(id: 'C2', mods: const [pedas]));

      expect(vm.state.length, 2);
    });

    test('a different note keeps the lines apart', () {
      final vm = CartViewModel()
        ..add(line(id: 'C1', note: 'tanpa bawang'))
        ..add(line(id: 'C2', note: 'extra kerupuk'));

      expect(vm.state.length, 2);
    });

    test('whitespace around an otherwise equal note still stacks', () {
      final vm = CartViewModel()
        ..add(line(id: 'C1', note: 'tanpa bawang'))
        ..add(line(id: 'C2', note: '  tanpa bawang  '));

      expect(vm.state.length, 1);
    });

    test('a different course keeps the lines apart', () {
      final vm = CartViewModel()
        ..add(line(id: 'C1', course: CourseId.mains))
        ..add(line(id: 'C2', course: CourseId.fireNow));

      expect(vm.state.length, 2);
    });

    test('a different variant keeps the lines apart', () {
      final vm = CartViewModel()
        ..add(line(id: 'C1', variantId: 'reguler'))
        ..add(line(id: 'C2', variantId: 'jumbo'));

      expect(vm.state.length, 2);
    });

    test('a different member keeps the lines apart', () {
      final vm = CartViewModel()
        ..add(line(id: 'C1', memberId: 'ani'))
        ..add(line(id: 'C2', memberId: 'budi'));

      expect(vm.state.length, 2);
      vm.setMember('C2', 'ani', 'Ani');
      expect(vm.state.single.qty, 2);
      expect(vm.state.single.memberId, 'ani');
    });

    test(
      'stacking clamps at the line ceiling instead of rejecting the add',
      () {
        final vm = CartViewModel()
          ..add(line(id: 'C1', qty: 95))
          ..add(line(id: 'C2', qty: 20));

        expect(vm.state.length, 1);
        expect(vm.state.single.qty, kCartLineMaxQty);
      },
    );
  });

  group('setQty', () {
    test('clamps to 1..max and ignores unknown ids', () {
      final vm = CartViewModel()..add(line(id: 'C1', qty: 4));

      vm.setQty('C1', 0);
      expect(vm.state.single.qty, 1);

      vm.setQty('C1', 500);
      expect(vm.state.single.qty, kCartLineMaxQty);

      vm.setQty('nope', 7);
      expect(vm.state.single.qty, kCartLineMaxQty);
    });
  });

  group('replace', () {
    test('swaps in place and keeps the original id', () {
      final vm = CartViewModel()
        ..add(line(id: 'C1', qty: 2))
        ..add(line(id: 'C2', variantId: 'jumbo'));

      vm.replace('C2', line(id: 'ignored', variantId: 'jumbo', qty: 4));

      expect(vm.state.length, 2);
      expect(vm.state[1].id, 'C2');
      expect(vm.state[1].qty, 4);
    });

    test('an edit that recreates another line merges into it', () {
      final vm = CartViewModel()
        ..add(line(id: 'C1', mods: const [pedas], qty: 2))
        ..add(line(id: 'C2', qty: 1));

      // The waiter reopens the plain line and adds pedas — now a twin of C1.
      vm.replace('C2', line(id: 'C2', mods: const [pedas], qty: 1));

      expect(vm.state.length, 1);
      expect(vm.state.single.id, 'C1');
      expect(vm.state.single.qty, 3);
    });

    test('a merging edit clamps at the ceiling', () {
      final vm = CartViewModel()
        ..add(line(id: 'C1', mods: const [pedas], qty: 90))
        ..add(line(id: 'C2', qty: 30));

      vm.replace('C2', line(id: 'C2', mods: const [pedas], qty: 30));

      expect(vm.state.single.qty, kCartLineMaxQty);
    });

    test('an unknown id is a no-op', () {
      final vm = CartViewModel()..add(line(id: 'C1', qty: 2));
      vm.replace('nope', line(id: 'nope', qty: 9));

      expect(vm.state.length, 1);
      expect(vm.state.single.qty, 2);
    });
  });
}
