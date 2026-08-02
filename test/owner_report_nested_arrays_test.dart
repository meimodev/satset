// The owner report survives Firestore's ban on arrays-inside-arrays.
//
// `/reports/snapshot` carries a 7×12 peak-hour heatmap as List<List<double>>.
// Writing that to Firestore throws `Invalid data. Nested arrays are not
// supported` and fails the *whole* document set — the off-site owner saw no
// report at all, not merely a missing chart. The publisher wraps nested lists
// on the way out and the reader unwraps them on the way in, so the shared
// ReportSectionsView still parses the payload it already knows.
//
// See docs/adr/0036-owner-cloud-reports.md.
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/services/owner_report_service.dart';

void main() {
  // The real shape, trimmed: a heatmap row grid nested two deep inside maps.
  Map<String, dynamic> snapshot() => {
    'sales': {
      'kpis': [
        {'label': 'Net', 'value': 'Rp 1.000'},
      ],
    },
    'ops': {
      'heatmap': [
        [0.0, 0.5],
        [1.0, 0.25],
      ],
      'stations': [
        {'station': 'kitchen', 'qty': 12},
      ],
    },
  };

  test('a nested array is wrapped so no list is ever a list element', () {
    final encoded = encodeNestedForFirestore(snapshot()) as Map;
    final heatmap = (encoded['ops'] as Map)['heatmap'] as List;
    // Every element of the outer list must be a map, not a list — that is
    // exactly the condition Firestore enforces.
    expect(heatmap, everyElement(isA<Map>()));
    expect(heatmap, isNot(anyElement(isA<List>())));
  });

  test('round-trip restores the original structure', () {
    final original = snapshot();
    final restored = decodeNestedFromFirestore(
      encodeNestedForFirestore(original),
    );
    expect(restored, original);
  });

  test('a flat list is left alone', () {
    // Arrays of scalars and arrays of maps are legal in Firestore; wrapping
    // them would bloat the doc and break older readers for nothing.
    final encoded = encodeNestedForFirestore({
      'flat': [1, 2, 3],
      'maps': [
        {'a': 1},
      ],
    });
    expect(encoded, {
      'flat': [1, 2, 3],
      'maps': [
        {'a': 1},
      ],
    });
  });

  test('decoding tolerates a doc written before the wrapping existed', () {
    // Old docs hold no wrapper keys (and no heatmap — the write had failed),
    // so decode must be a no-op on them rather than a parse error.
    final legacy = {
      'sales': {
        'kpis': [
          {'label': 'Net'},
        ],
      },
    };
    expect(decodeNestedFromFirestore(legacy), legacy);
  });

  test('deeper nesting survives too', () {
    // Three levels: the middle list is both an element and a container.
    final deep = {
      'grid': [
        [
          [1, 2],
          [3],
        ],
        [
          [4],
        ],
      ],
    };
    expect(decodeNestedFromFirestore(encodeNestedForFirestore(deep)), deep);
  });
}
