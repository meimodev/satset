import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The phone shell floats its tab bar **over** the page, so a scroll view on a
/// shell route has to end above it or its last row is unreachable under a
/// translucent slab. `ShellInset` publishes that clearance (see
/// `lib/ui/core/design/shell_inset.dart`); this is what stops a new screen
/// shipping without asking for it.
///
/// Two assertions, because either alone rots:
///
/// 1. The file list below matches what `app_router.dart` actually mounts
///    inside `ShellRoute`. A hand list drifts the day someone adds a route;
///    parsing the router alone is one clever regex away from silently
///    scanning nothing (the `/counter` entry is a `Consumer` builder, not
///    `=> const XScreen()`, so a naive pattern already misses it). Both, and
///    a new route fails loudly until it is listed.
/// 2. Every listed file that builds a vertical scroll view mentions
///    `shellInset`.
///
/// Deliberately **file-granular**, not site-granular. A regex cannot see
/// nesting, and these files hold more than their page scroll — a sheet's list
/// covers the bar rather than hiding under it, and a chip row scrolls
/// sideways. Flagging every site would need per-site exemption markers, which
/// become noise nobody reads. One mention per file catches what actually
/// happens: a whole new screen shipping with none.
///
/// A screen whose only scroll views are in sheets opts out with a
/// `// no-shell-inset:` comment naming the reason.
const _shellRouteScreens = <String>[
  'lib/ui/features/tables/tables_screen.dart',
  'lib/ui/features/menu/menu_screen.dart',
  'lib/ui/features/orders/orders_screen.dart',
  'lib/ui/features/admin/kitchen_screen.dart',
  'lib/ui/features/cashier/cashier_screen.dart',
  'lib/ui/features/admin/venue_hub_screen.dart',
  'lib/ui/features/admin/venue_settings_screen.dart',
  'lib/ui/features/admin/alerts_screen.dart',
  'lib/ui/features/admin/zone_admin_screen.dart',
  'lib/ui/features/admin/menu_admin_screen.dart',
  'lib/ui/features/admin/stock_screen.dart',
  'lib/ui/features/admin/reports_screen.dart',
  'lib/ui/features/admin/audit_screen.dart',
  'lib/ui/features/admin/kas_screen.dart',
  'lib/ui/features/admin/venue_day_screen.dart',
  'lib/ui/features/admin/self_order_screen.dart',
  'lib/ui/features/admin/self_order_admin_screen.dart',
  'lib/ui/features/admin/members_screen.dart',
  'lib/ui/features/admin/opname_screen.dart',
  'lib/ui/features/admin/system_screen.dart',
  'lib/ui/features/admin/staff_screen.dart',
  'lib/ui/features/me/me_screen.dart',
];

/// Screen classes the router mounts inside the shell that deliberately have no
/// file of their own to scan — none today. Kept so a shared screen can be
/// excused with a reason rather than by quietly widening the regex.
const _classesWithoutOwnFile = <String>{};

final _scrollView = RegExp(
  r'\b(ListView|GridView|CustomScrollView|SingleChildScrollView|'
  r'ReorderableListView)(?:\.\w+)?\(',
);

/// A scroll view is horizontal if it says so within the arguments that follow
/// it. 200 chars covers `scrollDirection:` in every call site we have; a
/// horizontal list that declares it later reads as vertical, which fails
/// *safe* — it asks for padding it does not need rather than skipping padding
/// it does.
bool _isVertical(String src, int start) {
  final end = (start + 200).clamp(0, src.length);
  return !src.substring(start, end).contains('Axis.horizontal');
}

/// The `ShellRoute(...)` argument list, matched by counting parentheses.
String _shellRouteBlock(String routerSrc) {
  final open = routerSrc.indexOf('ShellRoute(');
  expect(open, isNot(-1), reason: 'no ShellRoute in app_router.dart');
  var depth = 0;
  for (var i = routerSrc.indexOf('(', open); i < routerSrc.length; i++) {
    if (routerSrc[i] == '(') depth++;
    if (routerSrc[i] == ')') {
      depth--;
      if (depth == 0) return routerSrc.substring(open, i + 1);
    }
  }
  fail('unbalanced parentheses after ShellRoute(');
}

void main() {
  test('the shell-route file list matches the router', () {
    final src = File('lib/router/app_router.dart').readAsStringSync();
    final mounted = RegExp(r'\b([A-Z]\w*Screen)\b')
        .allMatches(_shellRouteBlock(src))
        .map((m) => m.group(1)!)
        .toSet()
        .difference(_classesWithoutOwnFile);

    final declared = <String>{};
    for (final path in _shellRouteScreens) {
      final file = File(path);
      expect(
        file.existsSync(),
        isTrue,
        reason: '$path is listed in shell_inset_test but does not exist',
      );
      for (final m in RegExp(
        r'^class (\w+) ',
        multiLine: true,
      ).allMatches(file.readAsStringSync())) {
        declared.add(m.group(1)!);
      }
    }

    final unlisted = mounted.difference(declared);
    expect(
      unlisted,
      isEmpty,
      reason:
          'These screens are mounted inside ShellRoute but no file in\n'
          '_shellRouteScreens declares them: $unlisted\n'
          'Add the file to that list — a shell route floats the phone tab bar\n'
          'over its page, and the list is what makes the next test see it.',
    );
  });

  test('every shell-route screen that scrolls asks for the tab-bar clearance', () {
    final offenders = <String>[];
    for (final path in _shellRouteScreens) {
      final src = File(path).readAsStringSync();
      if (src.contains('shellInset') || src.contains('// no-shell-inset:')) {
        continue;
      }
      final vertical = _scrollView
          .allMatches(src)
          .where((m) => _isVertical(src, m.start))
          .length;
      if (vertical > 0) offenders.add('$path ($vertical vertical scroll views)');
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A shell route scrolls under the floating phone tab bar. Add\n'
          '`context.shellInset` to the page scroll view\'s bottom padding\n'
          '(or a trailing `SliverToBoxAdapter` for a CustomScrollView):\n'
          '${offenders.join('\n')}\n\n'
          'If every scroll view in the file is inside a sheet or dialog — which\n'
          'covers the bar rather than hiding under it — put a\n'
          '`// no-shell-inset: <reason>` comment at the top of the file instead.',
    );
  });
}
