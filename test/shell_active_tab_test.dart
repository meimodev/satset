import 'package:flutter_test/flutter_test.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/features/shell/app_shell.dart';

/// The rail item and the crumb trail come from one mapping (ADR-0058). These
/// rows are the contract: every shell route resolves to the destination that
/// actually owns it, names it with the same constant the rail button renders,
/// and an unmapped hub path degrades to the bare `[Venue]` trail instead of
/// borrowing a sibling screen's label.
///
/// Trails here are venue-less on purpose — `SatAppBar` prepends the venue name
/// to every trail in the app, so it is not this function's business. What
/// renders is `<venue> › <trail>`.
void main() {
  const hub = AppStrings.tabVenue;
  const me = 'Maya Anjani';

  const cases = <String, (String, List<String>)>{
    // The bug: hub children absent from both old switches lit up Meja and
    // claimed the "Konfigurasi" crumb.
    '/stock': ('venue', [hub, AppStrings.venueHubSectionStock]),
    '/alerts': ('venue', [hub, AppStrings.alertsTitle]),
    // "Konfigurasi" was only ever true for this one.
    '/venue-settings': ('venue', [hub, AppStrings.crumbKonfigurasi]),
    // The hub root is not its own settings child.
    '/venue': ('venue', [hub]),
    // Prefix collision: /menuadm must not answer to /me.
    '/menuadm': ('venue', [hub, AppStrings.crumbMenuAdmin]),
    '/zone-admin': ('venue', [hub, AppStrings.zoneAdminTitle]),
    '/system': ('venue', [hub, AppStrings.venueHubSectionSystem]),
    '/staff': ('venue', [hub, AppStrings.crumbStafAkun]),
    '/reports': ('venue', [hub, AppStrings.crumbLaporanShift]),
    // Top-level destinations are named by the rail's own label, one segment.
    '/tables': ('tables', [AppStrings.tabMeja]),
    '/orders': ('orders', [AppStrings.tabPesanan]),
    '/guestorders': ('guest', [AppStrings.tabMandiri]),
    '/kitchen': ('kitchen', [AppStrings.tabAntrian]),
    '/kasir': ('kasir', [AppStrings.tabKasir]),
    // The one dynamic tail: who is logged in, not the label "Saya".
    '/me': ('me', [me]),
  };

  cases.forEach((loc, expected) {
    final (tab, crumbs) = expected;
    test('$loc → rail "$tab", crumbs $crumbs', () {
      expect(activeTabFor(loc), tab);
      expect(crumbsFor(loc, me), crumbs);
    });
  });

  test('an unmapped hub path fails short, never mislabelled', () {
    expect(activeTabFor('/some-future-hub-child'), 'venue');
    expect(crumbsFor('/some-future-hub-child', me), [hub]);
  });

  test('a subpath resolves to its parent destination', () {
    expect(activeTabFor('/menuadm/42'), 'venue');
    expect(crumbsFor('/menuadm/42', me), [hub, AppStrings.crumbMenuAdmin]);
  });

  test('an unnamed user falls back to the rail label on /me', () {
    expect(crumbsFor('/me', ''), [AppStrings.tabSaya]);
  });
}
