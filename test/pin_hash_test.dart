// A staff PIN was stored as `sha256('satset.v1::' + pin)` — no salt, no cost,
// and the same six digits produced the same digest in every venue on earth.
// Six digits is a million candidates, so that digest is a table lookup.
//
// ADR-0112: PBKDF2-SHA256 with a per-user salt, a self-describing stored
// string, and a verified scan in place of the lookup — because a salted hash
// cannot be looked up, and the lookup it replaces had a second bug in it.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/pin.dart';

void main() {
  group('hash shape', () {
    test('a hash verifies its own pin and nothing else', () {
      final stored = hashPin('123456');
      expect(verifyPin(stored, '123456'), isTrue);
      expect(verifyPin(stored, '123457'), isFalse);
      expect(verifyPin(stored, ''), isFalse);
    });

    test('the same pin hashes differently every time', () {
      // The whole point of the salt: two people on 123456 must not be
      // visibly identical to anyone reading the users table.
      final a = hashPin('123456');
      final b = hashPin('123456');
      expect(a, isNot(b));
      expect(verifyPin(a, '123456'), isTrue);
      expect(verifyPin(b, '123456'), isTrue);
    });

    test('the stored string says how it was made', () {
      final parts = hashPin('123456').split(r'$');
      expect(parts, hasLength(4));
      expect(parts[0], 'pbkdf2-sha256');
      expect(int.parse(parts[1]), pinIterations);
    });

    test('the cost is carried per row, so it can be raised later', () {
      final cheap = hashPin('123456', iterations: 100);
      expect(int.parse(cheap.split(r'$')[1]), 100);
      expect(
        verifyPin(cheap, '123456'),
        isTrue,
        reason: 'a row written at an older cost still verifies',
      );
    });

    test('an empty hash verifies nothing', () {
      // The host admin holds one: authed by Firebase, never by PIN (ADR-0077).
      expect(verifyPin('', '123456'), isFalse);
      expect(isLegacyPinHash(''), isFalse);
    });

    test('a mangled hash is refused, not thrown on', () {
      for (final bad in [
        'pbkdf2-sha256\$notanumber\$AAAA\$AAAA',
        'pbkdf2-sha256\$10000\$AAAA',
        'pbkdf2-sha256\$0\$AAAA\$AAAA',
        'pbkdf2-sha256\$10000\$!!!!\$AAAA',
      ]) {
        expect(verifyPin(bad, '123456'), isFalse, reason: bad);
      }
    });
  });

  group('legacy rows', () {
    test('the old digest still verifies', () {
      // A venue upgrading mid-service must not lock its whole floor out.
      final old = legacyHashPin('123456');
      expect(isLegacyPinHash(old), isTrue);
      expect(verifyPin(old, '123456'), isTrue);
      expect(verifyPin(old, '999999'), isFalse);
    });

    test('a new hash is not mistaken for a legacy one', () {
      expect(isLegacyPinHash(hashPin('123456')), isFalse);
    });
  });

  group('resolving a pin to a user', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    Future<void> addUser(String id, String storedHash) async {
      await db
          .into(db.roles)
          .insertOnConflictUpdate(
            RolesCompanion.insert(id: 'role-$id', name: id),
          );
      await db
          .into(db.users)
          .insertOnConflictUpdate(
            UsersCompanion.insert(
              id: id,
              name: id,
              initials: id.substring(0, 2).toUpperCase(),
              roleId: 'role-$id',
              pinHash: storedHash,
            ),
          );
    }

    test('finds the one user holding it', () async {
      await addUser('maya', hashPin('111111'));
      await addUser('budi', hashPin('222222'));

      expect((await userForPin(db, '111111'))?.id, 'maya');
      expect((await userForPin(db, '222222'))?.id, 'budi');
      expect(await userForPin(db, '333333'), isNull);
    });

    test('a shared pin resolves to nobody instead of throwing', () async {
      // The old query was `WHERE pin_hash = ?` with `getSingleOrNull`, so two
      // people on one PIN threw `Bad state: Too many elements` and locked both
      // of them out with a 500. Refusing is the fail-closed answer: letting
      // either one in would put the wrong name in the audit log.
      await addUser('maya', hashPin('111111'));
      await addUser('budi', hashPin('111111'));

      expect(await usersForPin(db, '111111'), hasLength(2));
      expect(await userForPin(db, '111111'), isNull);
    });

    test('a user with no pin is never a candidate', () async {
      await addUser('admin', '');
      expect(await usersForPin(db, ''), isEmpty);
      expect(await usersForPin(db, '111111'), isEmpty);
    });

    test('disabled staff are skipped unless asked for', () async {
      await addUser('maya', hashPin('111111'));
      await (db.update(db.users)..where((u) => u.id.equals('maya'))).write(
        const UsersCompanion(disabled: Value(true)),
      );

      expect(await userForPin(db, '111111'), isNull);
      expect(
        (await userForPin(db, '111111', onlyEnabled: false))?.id,
        'maya',
        reason:
            'the Staf sheet still has to see the clash — a disabled '
            "member's PIN is still theirs",
      );
    });

    test('a legacy row upgrades itself on the sign-in that proves it', () async {
      await addUser('maya', legacyHashPin('111111'));

      expect((await userForPin(db, '111111'))?.id, 'maya');

      final row = await (db.select(
        db.users,
      )..where((u) => u.id.equals('maya'))).getSingle();
      expect(
        isLegacyPinHash(row.pinHash),
        isFalse,
        reason: 'rewritten in place — this is the only moment the plaintext '
            'exists',
      );
      expect(verifyPin(row.pinHash, '111111'), isTrue);
      expect(
        (await userForPin(db, '111111'))?.id,
        'maya',
        reason: 'and it still opens the door afterwards',
      );
    });

    test('a wrong pin does not rewrite anything', () async {
      final stored = legacyHashPin('111111');
      await addUser('maya', stored);

      expect(await userForPin(db, '999999'), isNull);

      final row = await (db.select(
        db.users,
      )..where((u) => u.id.equals('maya'))).getSingle();
      expect(row.pinHash, stored);
    });
  });
}
