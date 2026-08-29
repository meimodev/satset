// **[[Pemilik struk]]** (ADR-0118) — may a share of a split bill name its own
// member, and where does the money go that no share claims.
//
// Two halves, pinned separately because they fail differently. The gate is a
// **mode** key, so it fails closed on a never-mirrored row, and it ANDs with
// the `members` module and the owner's own switch — attribution with no
// membership to attribute to is a picker whose every route answers 404.
//
// The division is a **subtraction**, not a split: each named share takes its
// own base, and whatever is left over is the [[Pemilik tagihan]]'s. Stating it
// that way is what makes the unclaimed remainder impossible to lose, which is
// the failure this arithmetic exists to prevent.
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/server/members.dart';

void main() {
  group('the floor gate', () {
    const settings = VenueSettingsDto(membersEnabled: true);

    test('a never-mirrored row may not name a share', () {
      expect(settings.modules, isNull);
      expect(
        settings.membersOn,
        isTrue,
        reason: 'the sellable half fails open — a cold boot keeps membership',
      );
      expect(
        settings.memberSplitOn,
        isFalse,
        reason: 'the mode half fails closed on the very same null',
      );
    });

    test('the mode without membership names nobody', () {
      final noModule = settings.copyWith(
        membersEnabled: true,
        modules: const [modeMemberSplit],
      );
      expect(noModule.memberSplitOn, isFalse);

      final switchedOff = settings.copyWith(
        membersEnabled: false,
        modules: const [moduleMembers, modeMemberSplit],
      );
      expect(switchedOff.memberSplitOn, isFalse);
    });

    test('all three halves, and only then', () {
      final on = settings.copyWith(
        membersEnabled: true,
        modules: const [moduleMembers, modeMemberSplit],
      );
      expect(on.memberSplitOn, isTrue);
    });

    test('switching the mode off leaves membership standing', () {
      final on = settings.copyWith(
        membersEnabled: true,
        modules: const [moduleMembers, modeMemberSplit],
      );
      final off = on.copyWith(modules: const [moduleMembers]);
      expect(off.memberSplitOn, isFalse);
      expect(
        off.membersOn,
        isTrue,
        reason: 'the mode is the split, not the membership',
      );
    });
  });

  group('the points base per member', () {
    Map<String, int> divide({
      required int billBase,
      String? ownerId,
      List<ReceiptBase> receipts = const [],
      bool splitEnabled = true,
    }) => pointsBaseByMember(
      billBase: billBase,
      ownerId: ownerId,
      receipts: receipts,
      splitEnabled: splitEnabled,
    );

    test('with the mode off the owner takes the whole bill', () {
      expect(
        divide(
          billBase: 300000,
          ownerId: 'm-host',
          receipts: const [
            (memberId: 'm-a', base: 100000),
            (memberId: 'm-b', base: 100000),
          ],
          splitEnabled: false,
        ),
        {'m-host': 300000},
        reason: 'a venue without the mode reports exactly as it did before',
      );
    });

    test('each named share takes its own, the owner takes the rest', () {
      expect(
        divide(
          billBase: 300000,
          ownerId: 'm-host',
          receipts: const [
            (memberId: 'm-a', base: 120000),
            (memberId: 'm-b', base: 80000),
          ],
        ),
        {'m-a': 120000, 'm-b': 80000, 'm-host': 100000},
      );
    });

    test('a share nobody named is the owner\'s', () {
      expect(
        divide(
          billBase: 250000,
          ownerId: 'm-host',
          receipts: const [
            (memberId: 'm-a', base: 90000),
            (memberId: null, base: 60000),
          ],
        ),
        {'m-a': 90000, 'm-host': 160000},
      );
    });

    test('two shares for one guest are one earn, not two', () {
      expect(
        divide(
          billBase: 200000,
          ownerId: null,
          receipts: const [
            (memberId: 'm-a', base: 70000),
            (memberId: 'm-a', base: 30000),
          ],
        ),
        {'m-a': 100000},
        reason: 'a guest with two slips ate one meal',
      );
    });

    test('no owner means the remainder earns for nobody', () {
      expect(
        divide(
          billBase: 300000,
          ownerId: null,
          receipts: const [(memberId: 'm-a', base: 100000)],
        ),
        {'m-a': 100000},
      );
    });

    test('a fully claimed bill leaves the owner nothing, not a zero row', () {
      final out = divide(
        billBase: 200000,
        ownerId: 'm-host',
        receipts: const [
          (memberId: 'm-a', base: 120000),
          (memberId: 'm-b', base: 80000),
        ],
      );
      expect(out, {'m-a': 120000, 'm-b': 80000});
      expect(
        out.containsKey('m-host'),
        isFalse,
        reason: 'an earn of nothing is not an earn',
      );
    });

    test('shares claiming more than the bill never owe the owner points', () {
      // Cannot happen from the till, but the arithmetic is a subtraction and a
      // negative remainder would mint points out of nothing.
      final out = divide(
        billBase: 100000,
        ownerId: 'm-host',
        receipts: const [(memberId: 'm-a', base: 150000)],
      );
      expect(out['m-host'], isNull);
      expect(out['m-a'], 150000);
    });

    test('an unattributed bill is still the owner\'s whole bill', () {
      expect(divide(billBase: 180000, ownerId: 'm-host'), {'m-host': 180000});
    });
  });
}
