import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/features/shell/app_shell.dart';

/// The rail item and the crumb trail come from one mapping (ADR-0058). These
/// rows are the contract: every shell route resolves to the destination that
/// actually owns it, names it with the same entry the rail button renders,
/// and an unmapped hub path degrades to the bare `[Venue]` trail instead of
/// borrowing a sibling screen's label.
///
/// Trails here are venue-less on purpose — `SatAppBar` prepends the venue name
/// to every trail in the app, so it is not this function's business. What
/// renders is `<venue> › <trail>`.
///
/// Run against **both** locales (ADR-0083). The expected labels are read from
/// the same `AppL10n` the code reads, so this asserts the *routing*, not the
/// wording — but running it twice catches a locale whose ARB is missing a key
/// the trail needs, which would otherwise only show up on a user's screen.
void main() {
  for (final locale in const [Locale('id'), Locale('en')]) {
    final l10n = lookupAppL10n(locale);
    final tag = locale.languageCode;
    final hub = l10n.tabVenue;
    const me = 'Maya Anjani';

    final cases = <String, (String, List<String>)>{
      // The bug: hub children absent from both old switches lit up Meja and
      // claimed the "Konfigurasi" crumb.
      '/stock': ('venue', [hub, l10n.venueHubSectionStock]),
      '/alerts': ('venue', [hub, l10n.alertsTitle]),
      // "Konfigurasi" was only ever true for this one.
      '/venue-settings': ('venue', [hub, l10n.crumbKonfigurasi]),
      // The hub root is not its own settings child.
      '/venue': ('venue', [hub]),
      // Prefix collision: /menuadm must not answer to /me.
      '/menuadm': ('venue', [hub, l10n.crumbMenuAdmin]),
      '/zone-admin': ('venue', [hub, l10n.zoneAdminTitle]),
      '/system': ('venue', [hub, l10n.venueHubSectionSystem]),
      '/staff': ('venue', [hub, l10n.crumbStafAkun]),
      '/reports': ('venue', [hub, l10n.crumbLaporanShift]),
      // Top-level destinations are named by the rail's own label, one segment.
      '/tables': ('tables', [l10n.tabMeja]),
      '/orders': ('orders', [l10n.tabPesanan]),
      '/kitchen': ('kitchen', [l10n.tabAntrian]),
      '/kasir': ('kasir', [l10n.tabKasir]),
      // [[Pesan mandiri]] split in two (ADR-0106): the queue is a destination
      // of its own, its settings stay a hub child. The two paths share a
      // prefix, so this pair is also the guard against `/selforder-admin`
      // being swallowed by `/selforder` the way `/menuadm` once was by `/me`.
      '/selforder': ('tamu', [l10n.tabTamu]),
      '/selforder-admin': ('venue', [hub, l10n.soAdminTitle]),
      // The one dynamic tail: who is logged in, not the label "Saya".
      '/me': ('me', [me]),
    };

    cases.forEach((loc, expected) {
      final (tab, crumbs) = expected;
      test('[$tag] $loc → rail "$tab", crumbs $crumbs', () {
        expect(activeTabFor(loc), tab);
        expect(crumbsFor(l10n, loc, me), crumbs);
      });
    });

    test('[$tag] an unmapped hub path fails short, never mislabelled', () {
      expect(activeTabFor('/some-future-hub-child'), 'venue');
      expect(crumbsFor(l10n, '/some-future-hub-child', me), [hub]);
    });

    test('[$tag] a subpath resolves to its parent destination', () {
      expect(activeTabFor('/menuadm/42'), 'venue');
      expect(crumbsFor(l10n, '/menuadm/42', me), [hub, l10n.crumbMenuAdmin]);
    });

    test('[$tag] an unnamed user falls back to the rail label on /me', () {
      expect(crumbsFor(l10n, '/me', ''), [l10n.tabSaya]);
    });
  }
}
