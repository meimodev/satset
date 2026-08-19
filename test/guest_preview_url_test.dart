import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/self_order_dto.dart';
import 'package:satset/data/repositories/self_order_repository.dart';
import 'package:satset/ui/features/admin/self_order_admin_screen.dart';

/// The guest plane serves `/t/<code>` and `/guest/*` — a bare `/` is a 404 by
/// design, because the table code is the credential. The preview button pointed
/// at that root and showed the owner an error page for a working feature.
SelfOrderState _state(List<GuestTableDto> tables, {String? host = '192.168.1.4'}) =>
    SelfOrderState(host: host, guestPort: 8080, tables: tables);

void main() {
  test('the preview opens a table page, never the plane root', () {
    final url = guestPreviewUrl(
      _state(const [GuestTableDto(id: 'd1', code: 'DR3M9SQE')]),
    );
    expect(url, 'http://192.168.1.4:8080/t/DR3M9SQE');
    expect(url, isNot(endsWith(':8080/')));
  });

  test('a table switched off is not what the owner is shown', () {
    expect(
      guestPreviewUrl(
        _state(const [
          GuestTableDto(id: 'd1', code: 'AAA', enabled: false),
          GuestTableDto(id: 'd2', code: 'BBB'),
        ]),
      ),
      endsWith('/t/BBB'),
    );
  });

  test('nothing to preview reads as null, not a broken link', () {
    // No LAN host: the same condition that renders `soNoHost` on a QR card.
    expect(
      guestPreviewUrl(_state(const [GuestTableDto(id: 'd1', code: 'AAA')], host: null)),
      isNull,
    );
    // A venue whose tables have no codes, and one with no tables at all.
    expect(guestPreviewUrl(_state(const [GuestTableDto(id: 'd1')])), isNull);
    expect(guestPreviewUrl(_state(const [])), isNull);
  });
}
