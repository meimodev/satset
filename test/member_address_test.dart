// The [[Alamat pelanggan]]'s four optional fields, against an in-memory
// database and the real writers in `lib/server/members.dart`.
//
// What is actually being pinned:
//
//   - an address is optional in every direction: absent on enrol, and any
//     *prefix* of the chain saves (kabupaten alone is a legal answer);
//   - `updateMember` replaces it **wholesale** — a value overwrites all four
//     fields, and null leaves the stored one alone. This is the whole reason
//     there is one nullable object rather than four `clearX` flags, and it is
//     the arm that breaks first if someone "helpfully" merges the two;
//   - a level is stored as the *name* it was picked as, so nothing here has to
//     agree with the bundled vocabulary for the record to survive;
//   - a merge keeps the surviving member's address, like every other field.
//
// See CONTEXT.md § Alamat pelanggan.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/members.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            membersEnabled: const Value(true),
          ),
        );
  });
  tearDown(() => db.close());

  Future<Member> enrol({
    String name = 'Budi',
    String phone = '081337002244',
    MemberAddress address = const MemberAddress(),
  }) => createMember(db, name: name, phone: phone, address: address);

  test('enrolling without an address leaves all four fields empty', () async {
    final m = await enrol();
    expect(m.address.isEmpty, isTrue);
    expect(m.address.oneLine, '');
  });

  test('any prefix of the chain saves', () async {
    final m = await enrol(
      address: const MemberAddress(kabupaten: 'Kota Manado'),
    );
    expect(m.address.kabupaten, 'Kota Manado');
    expect(m.address.kecamatan, isNull);
    expect(m.address.isNotEmpty, isTrue);
  });

  test('a level is stored as the name it was picked as', () async {
    final m = await enrol(
      address: const MemberAddress(
        kabupaten: 'Kota Manado',
        kecamatan: 'Wanea',
        kelurahan: 'Teling Atas',
        text: 'Jl. Sam Ratulangi No. 12',
      ),
    );
    final read = (await getMember(db, m.id))!;
    expect(read.address.kelurahan, 'Teling Atas');
    // Street first, then outward — the envelope order.
    expect(
      read.address.oneLine,
      'Jl. Sam Ratulangi No. 12, Kel. Teling Atas, Kec. Wanea, Kota Manado',
    );
  });

  test('an absent address on update leaves the stored one alone', () async {
    final m = await enrol(
      address: const MemberAddress(kabupaten: 'Kota Manado', kecamatan: 'Wanea'),
    );
    final after = await updateMember(db, id: m.id, name: 'Budi Santoso');
    expect(after.name, 'Budi Santoso');
    expect(after.address.kabupaten, 'Kota Manado');
    expect(after.address.kecamatan, 'Wanea');
  });

  test('a value on update replaces all four fields, not just the ones set', () async {
    final m = await enrol(
      address: const MemberAddress(
        kabupaten: 'Kota Manado',
        kecamatan: 'Wanea',
        kelurahan: 'Teling Atas',
        text: 'Jl. Sam Ratulangi No. 12',
      ),
    );
    // Moved to another regency. The kecamatan and kelurahan below the old one
    // must not survive the move — a stale child is the failure this replaces
    // four clear-flags to avoid.
    final after = await updateMember(
      db,
      id: m.id,
      address: const MemberAddress(kabupaten: 'Kabupaten Minahasa'),
    );
    expect(after.address.kabupaten, 'Kabupaten Minahasa');
    expect(after.address.kecamatan, isNull);
    expect(after.address.kelurahan, isNull);
    expect(after.address.text, isNull);
  });

  test('an empty address on update clears the stored one', () async {
    final m = await enrol(
      address: const MemberAddress(kabupaten: 'Kota Manado'),
    );
    final after = await updateMember(
      db,
      id: m.id,
      address: const MemberAddress(),
    );
    expect(after.address.isEmpty, isTrue);
  });

  test('memberJson carries the address, always as an object', () async {
    final m = await enrol(
      address: const MemberAddress(kabupaten: 'Kota Manado'),
    );
    final json = memberJson(m);
    expect(json['address'], isA<Map<String, dynamic>>());
    expect((json['address'] as Map)['kabupaten'], 'Kota Manado');
    // Round-trips through the client's parser unchanged.
    final back = MemberAddress.fromJson(
      (json['address'] as Map).cast<String, dynamic>(),
    );
    expect(back.kabupaten, 'Kota Manado');
    expect(back.kecamatan, isNull);

    final blank = memberJson(await enrol(phone: '081200000000'));
    expect(blank['address'], isA<Map<String, dynamic>>());
    expect((blank['address'] as Map)['kabupaten'], isNull);
  });

  test('a merge keeps the surviving member address', () async {
    final keep = await enrol(
      address: const MemberAddress(kabupaten: 'Kota Manado'),
    );
    final fold = await enrol(
      name: 'Budi (dup)',
      phone: '081200000000',
      address: const MemberAddress(kabupaten: 'Kabupaten Minahasa'),
    );
    final merged = await mergeMembers(db, fromId: fold.id, toId: keep.id);
    expect(merged.address.kabupaten, 'Kota Manado');
  });
}
