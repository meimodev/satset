import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every cache in this app fills on a *fetch*, and a lazy repository's first
/// fetch is whenever a screen first watches it. Do that on a dark handset and
/// the fetch fails and the cache stays empty — which is the one moment the
/// cache existed for.
///
/// The fix is always the same and always in one place: watch it on `AppShell`,
/// which outlives every tab. This has now been the bug four times — the
/// discount presets (ADR-0128), the expense categories (ADR-0130), the menu
/// and the zones (ADR-0133) — so the list is pinned rather than remembered.
void main() {
  final shell = File('lib/ui/features/shell/app_shell.dart').readAsStringSync();

  /// Warmed unconditionally. Each either backs an offline cache or is needed
  /// on a floor whose host may already be gone.
  const required = <String, String>{
    'sendQueueDrainProvider': 'the [[Antrean kirim]] drain has no other holder',
    'discountPresetsRepositoryProvider': 'ADR-0128',
    'expenseCategoriesRepositoryProvider': 'ADR-0130',
    'memberMirrorSyncProvider': 'the [[Salinan pelanggan]], ADR-0129',
    'menuRepositoryProvider': 'the [[Salinan lantai]], ADR-0133',
    'tablesProvider': 'the [[Salinan lantai]], ADR-0133',
    'zonesProvider': 'the [[Salinan lantai]], ADR-0133',
    'ticketsProvider': 'the [[Salinan lantai]], ADR-0133',
    'printersRepositoryProvider': 'a printer list fetched at Cetak is too late',
  };

  for (final e in required.entries) {
    test('AppShell warms ${e.key}', () {
      expect(
        shell.contains('ref.watch(${e.key})'),
        isTrue,
        reason:
            'Removed from AppShell.build — ${e.value}. A lazy repository whose '
            'first watch is a screen fills its cache only if someone opens '
            'that screen before the host goes away.',
      );
    });
  }

  test('tables and tickets are warmed on purpose, not via the tab badges', () {
    // They were warm for months only because `totalReadyCountProvider` and
    // `kitchenNewOrderCountProvider` happen to watch them for the badge
    // counts. Deleting a badge would have silently stopped the floor copy
    // filling, with nothing failing until a device cold-booted offline.
    final build = shell.substring(shell.indexOf('Widget build('));
    final badges = build.indexOf('ref.watch(totalReadyCountProvider)');
    for (final p in ['tablesProvider', 'ticketsProvider']) {
      final warm = build.indexOf('ref.watch($p)');
      expect(warm, greaterThan(-1), reason: '$p is not warmed at all');
      expect(
        warm,
        lessThan(badges),
        reason:
            '$p must be warmed in its own right, above the badge providers '
            'that currently also happen to watch it.',
      );
    }
  });
}
