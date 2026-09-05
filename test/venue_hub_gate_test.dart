import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/router/app_router.dart';
import 'package:satset/ui/features/admin/venue_hub_screen.dart';
import 'package:satset/ui/features/shell/app_shell.dart';

AuthState _auth(Set<Capability> caps) =>
    AuthState(isAuthenticated: true, capabilities: caps);

void main() {
  group('the hub is a catalogue, not an authority (ADR-0133)', () {
    test('every tile is gated by something', () {
      // A tile whose route resolves to nothing renders for everyone — which is
      // how a screen ends up offered to a person the server will refuse. The
      // runtime reads null as "open", exactly as `redirect` does; this test is
      // what keeps null from ever occurring on a hub route.
      for (final route in venueHubRoutes) {
        expect(
          capabilitiesFor(route),
          isNotNull,
          reason: '$route is a hub tile with no capability behind it',
        );
      }
    });

    test('the hub gate is the union of its children, and nothing more', () {
      final union = <Capability>{
        for (final r in venueHubRoutes) ...?capabilitiesFor(r),
      };
      expect(venueHubCapabilities.toSet(), union);
      // The bug this ADR fixes: the hub used to cost `manageStaff`, so the
      // stock authorities could not open the only door to `/stock`.
      expect(venueHubCapabilities, contains(Capability.manageIngredients));
      expect(venueHubCapabilities, contains(Capability.adjustStock));
    });

    test('a stock-only holder opens the hub, and sees only stock tiles', () {
      final auth = _auth({Capability.adjustStock});
      expect(venueHubCapabilities.any(auth.has), isTrue);
      final visible = venueHubRoutes.where((r) => canOpenRoute(auth, r));
      expect(visible, containsAll(['/stock', '/opname']));
      expect(visible, isNot(contains('/staff')));
      expect(visible, isNot(contains('/kas')));
    });

    test('a waiter opens nothing on the hub', () {
      final auth = _auth({Capability.takeOrder});
      expect(venueHubCapabilities.any(auth.has), isFalse);
      expect(venueHubRoutes.where((r) => canOpenRoute(auth, r)), isEmpty);
    });

    test('canOpenRoute reads an ungated route as open, like redirect', () {
      expect(canOpenRoute(_auth(const {}), '/me'), isTrue);
      expect(capabilitiesFor('/me'), isNull);
    });
  });

  group('the hub subtitle names only what is drawn (ADR-0133)', () {
    final l10n = lookupAppL10n(const Locale('id'));

    test('a stock-only holder is not promised rooms they cannot enter', () {
      final line = hubSectionLine(l10n, _auth({Capability.adjustStock}));
      // The fixed line this replaced said "Konfigurasi · zona · menu · sistem
      // · staf" to everyone, including this person, who holds none of them.
      expect(line, isNot(contains('taf')));
      expect(line, isNot(contains('istem')));
      expect(line, isNot(contains('ona')));
      expect(line, contains(l10n.venueHubSectionStock));
    });

    test('it is a sample, not an index: at most five', () {
      final all = hubSectionLine(l10n, _auth(Capability.values.toSet()));
      expect(' · '.allMatches(all).length, lessThanOrEqualTo(4));
      expect(all, isNotEmpty);
    });

    test('someone who opens nothing gets an empty line, not a promise', () {
      expect(hubSectionLine(l10n, _auth({Capability.takeOrder})), isEmpty);
    });
  });

  group('where a sign-in lands (ADR-0133)', () {
    test('server mode lands on the hub when it opens', () {
      expect(
        landingFor(mode: AppMode.server, hubOpens: true, counterHome: false),
        '/venue',
      );
    });

    test('server mode falls through when the hub opens to nothing', () {
      // The bug: a waiter signing in on the host tablet landed on `/venue`
      // and was bounced straight to `/forbidden`.
      expect(
        landingFor(mode: AppMode.server, hubOpens: false, counterHome: false),
        '/tables',
      );
      expect(
        landingFor(mode: AppMode.server, hubOpens: false, counterHome: true),
        '/counter',
      );
    });

    test('a client never lands on the hub, however much it holds', () {
      expect(
        landingFor(mode: AppMode.client, hubOpens: true, counterHome: false),
        '/tables',
      );
    });
  });

  group('Stok is a nav destination (ADR-0133)', () {
    test('either stock authority shows the slot', () {
      expect(
        showStock(canManageIngredients: true, canAdjustStock: false),
        isTrue,
      );
      expect(
        showStock(canManageIngredients: false, canAdjustStock: true),
        isTrue,
      );
      expect(
        showStock(canManageIngredients: false, canAdjustStock: false),
        isFalse,
      );
    });

    test('the slot lights up and stops being a hub child', () {
      expect(activeTabFor('/stock'), 'stock');
      expect(venueHubCrumb(lookupAppL10n(const Locale('id')), '/stock'), isNull);
    });
  });
}
