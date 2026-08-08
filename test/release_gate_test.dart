import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/release_gate.dart';

/// The gate decides whether a restaurant keeps trading, so the two things worth
/// pinning are the ordering and the fail-open. See ADR-0087.
void main() {
  test('parses only three plain integers', () {
    expect(parseVersion('1.2.3'), [1, 2, 3]);
    expect(parseVersion('v1.2.3'), isNull);
    expect(parseVersion('1.2.3+45'), isNull);
    expect(parseVersion('1.2'), isNull);
    expect(parseVersion(''), isNull);
    expect(parseVersion(null), isNull);
  });

  test('orders numerically, not lexically', () {
    expect(compareVersions('1.10.0', '1.9.0'), 1);
    expect(compareVersions('1.2.3', '1.2.3'), 0);
    expect(compareVersions('0.9.9', '1.0.0'), -1);
  });

  test('an unset or unparseable side compares equal, never lesser', () {
    expect(compareVersions('1.0.0', null), 0);
    expect(compareVersions(null, '1.0.0'), 0);
    expect(compareVersions('1.0.0', 'nonsense'), 0);
  });

  test('verdict: below min blocks, below recommended nags, else nothing', () {
    const g = ReleaseGate(min: '1.2.0', recommended: '1.4.0', latest: '1.5.0');
    expect(g.verdictFor('1.1.9'), UpdateVerdict.blocked);
    expect(g.verdictFor('1.2.0'), UpdateVerdict.recommended);
    expect(g.verdictFor('1.3.9'), UpdateVerdict.recommended);
    expect(g.verdictFor('1.4.0'), UpdateVerdict.none);
    expect(g.verdictFor('2.0.0'), UpdateVerdict.none);
  });

  test('everything unknown fails open', () {
    expect(ReleaseGate.unknown.verdictFor('1.0.0'), UpdateVerdict.none);
    expect(
      const ReleaseGate(min: '9.9.9').verdictFor(''),
      UpdateVerdict.none,
    );
    expect(const ReleaseGate(min: '9.9.9').verdictFor(null), UpdateVerdict.none);
    // A build number on the installed version is not "current enough by luck":
    // it does not parse, so it is not blocked.
    expect(
      const ReleaseGate(min: '9.9.9').verdictFor('1.0.0+42'),
      UpdateVerdict.none,
    );
  });

  test('json round-trips and treats blank as absent', () {
    const g = ReleaseGate(min: '1.0.0', latest: '1.2.0');
    expect(ReleaseGate.fromJson(g.toJson()), g);
    expect(
      ReleaseGate.fromJson({'min': '  ', 'recommended': null}),
      ReleaseGate.unknown,
    );
    expect(ReleaseGate.unknown.isEmpty, isTrue);
  });
}
