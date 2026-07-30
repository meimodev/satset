import 'package:flutter_test/flutter_test.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/features/shell/app_shell.dart';

/// The rail item and the crumb trail come from one mapping (ADR-0058). These
/// rows are the contract: every shell route resolves to the destination that
/// actually owns it, and an unmapped hub path degrades to the bare `[Venue]`
/// trail instead of borrowing a sibling screen's label.
void main() {
  const venue = AppStrings.venueHubTitle;

  const cases = <String, (String, List<String>)>{
    // The bug: hub children absent from both old switches lit up Meja and
    // claimed the "Konfigurasi" crumb.
    '/stock': ('venue', [venue, AppStrings.venueHubSectionStock]),
    '/alerts': ('venue', [venue, AppStrings.alertsTitle]),
    // "Konfigurasi" was only ever true for this one.
    '/venue-settings': ('venue', [venue, AppStrings.crumbKonfigurasi]),
    // The hub root is not its own settings child.
    '/venue': ('venue', [venue]),
    // Prefix collision: /menuadm must not answer to /me.
    '/menuadm': ('venue', [venue, AppStrings.crumbMenuAdmin]),
    '/me': ('me', ['Maya Anjani', AppStrings.crumbRingkasanShift]),
    '/zone-admin': ('venue', [venue, AppStrings.zoneAdminTitle]),
    '/system': ('venue', [venue, AppStrings.venueHubSectionSystem]),
    '/staff': ('venue', [venue, AppStrings.crumbStafAkun]),
    '/reports': ('venue', [venue, AppStrings.crumbLaporanShift]),
    // Had no case at all, so it fell to the venue/zone trail.
    '/kasir': ('kasir', [AppStrings.tabKasir]),
    '/orders': ('orders', [AppStrings.crumbTeras, AppStrings.crumbPesananSaya]),
    '/guestorders': (
      'guest',
      [AppStrings.crumbTeras, AppStrings.crumbPesananMandiri],
    ),
    '/kitchen': ('kitchen', ['Stasiun', AppStrings.crumbAntrianPersiapan]),
    // The only path the venue/zone trail was written for.
    '/tables': ('tables', ['Warung Sate', 'Dalam']),
  };

  cases.forEach((loc, expected) {
    final (tab, crumbs) = expected;
    test('$loc → rail "$tab", crumbs $crumbs', () {
      expect(activeTabFor(loc), tab);
      expect(crumbsFor(loc, tab, 'Dalam', 'Warung Sate'), crumbs);
    });
  });

  test('an unmapped hub path fails short, never mislabelled', () {
    expect(activeTabFor('/some-future-hub-child'), 'venue');
    expect(
      crumbsFor('/some-future-hub-child', 'venue', 'Dalam', 'Warung Sate'),
      [venue],
    );
  });

  test('a subpath resolves to its parent destination', () {
    expect(activeTabFor('/menuadm/42'), 'venue');
    expect(crumbsFor('/menuadm/42', 'venue', 'Dalam', 'Warung Sate'), [
      venue,
      AppStrings.crumbMenuAdmin,
    ]);
  });

  test(
    'an empty venue name falls back to the hub title on the tables trail',
    () {
      expect(crumbsFor('/tables', 'tables', 'Dalam', ''), [venue, 'Dalam']);
    },
  );
}
