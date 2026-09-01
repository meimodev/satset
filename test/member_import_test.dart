import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/member_import.dart';
import 'package:satset/server/members.dart';
import 'package:satset/server/routes/members_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

class _RecordingHub extends WsHub {
  final events = <(String, Map<String, dynamic>)>[];

  @override
  void broadcast(String type, Map<String, dynamic> payload) {
    events.add((type, payload));
  }
}

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

  test('parses BOM, CRLF, LF inside quotes, and escaped quotes', () async {
    final csv =
        '\ufeffnama,telepon,catatan,alamat\r\n'
        '"Budi, Jr",+62 812-3456-7890,"suka ""kopi""","Jl. A\nBlok 2"\r\n';

    final preview = await previewMemberImport(db, utf8.encode(csv));

    expect(preview.createCount, 1);
    final row = preview.rows.single;
    expect(row.row, 2);
    expect(row.name, 'Budi, Jr');
    expect(row.phone, '081234567890');
    expect(row.note, 'suka "kopi"');
    expect(row.address.text, 'Jl. A\nBlok 2');
  });

  test(
    'classifies file duplicates as invalid and existing phones as skips',
    () async {
      await createMember(db, name: 'Ada', phone: '081200000001');
      final preview = await previewMemberImport(
        db,
        utf8.encode(
          'nama,telepon\n'
          'Ada lagi,+62 812-0000-0001\n'
          'Budi,081200000002\n'
          'Budi lagi,+62 812-0000-0002\n',
        ),
      );

      expect(preview.skipCount, 1);
      expect(preview.invalidCount, 2);
      expect(
        preview.rows.where((r) => r.status == MemberImportStatus.invalid),
        everyElement(
          isA<MemberImportRow>().having(
            (r) => r.errors,
            'errors',
            contains('duplicate_phone'),
          ),
        ),
      );
    },
  );

  test('import transaction rolls back profiles and audits together', () async {
    await db.customStatement('''
      CREATE TRIGGER fail_second_import
      BEFORE INSERT ON members
      WHEN NEW.phone = '081200000002'
      BEGIN SELECT RAISE(ABORT, 'boom'); END
    ''');
    final csv = utf8.encode(
      'nama,telepon\nBudi,081200000001\nSari,081200000002\n',
    );

    await expectLater(
      importMembers(db, csv, actorUserId: 'admin'),
      throwsA(anything),
    );
    expect(await db.select(db.members).get(), isEmpty);
    expect(await db.select(db.auditEntries).get(), isEmpty);
  });

  test('import routes require manageMembers', () async {
    final denied = await signInForTest(
      db,
      caps: {Capability.takeOrder},
      userId: 'waiter',
    );
    final allowed = await signInForTest(
      db,
      caps: {Capability.manageMembers},
      userId: 'keeper',
    );
    final csv = utf8.encode('nama,telepon\nBudi,081200000001\n');

    Future<int> preview(TestCaller caller) async {
      final response = await membersRoutes(db, WsHub(), caller.auth).call(
        Request(
          'POST',
          Uri.parse('http://x/members/import/preview'),
          headers: caller.headers,
          body: csv,
        ),
      );
      return response.statusCode;
    }

    expect(await preview(denied), 403);
    expect(await preview(allowed), 200);
  });

  test(
    'imports profiles, audits each member, and refreshes clients once',
    () async {
      await createMember(db, name: 'Ada', phone: '081200000001');
      final caller = await signInForTest(
        db,
        caps: {Capability.manageMembers},
        userId: 'admin',
      );
      final hub = _RecordingHub();
      final before = DateTime.now();
      final csv = utf8.encode(
        'nama,telepon,tanggal_lahir,catatan,kabupaten_kota,kecamatan,'
        'kelurahan_desa,alamat,batas_kredit\n'
        'Ada lagi,081200000001,,,,,,,\n'
        'Budi,081200000002,1990-02-03,VIP,Minahasa,Tondano,Tataaran,'
        'Jl. Danau,250000\n'
        'Sari,081200000003,,,,,,,0\n',
      );
      final response = await membersRoutes(db, hub, caller.auth).call(
        Request(
          'POST',
          Uri.parse('http://x/members/import'),
          headers: caller.headers,
          body: csv,
        ),
      );
      final body = jsonDecode(await response.readAsString()) as Map;

      expect(response.statusCode, 200);
      expect(body['new'], 2);
      expect(body['skipped'], 1);
      final members = await db.select(db.members).get();
      expect(members, hasLength(3));
      final budi = members.singleWhere((m) => m.phone == '081200000002');
      expect(budi.name, 'Budi');
      expect(
        (budi.birthday!.year, budi.birthday!.month, budi.birthday!.day),
        (1990, 2, 3),
      );
      expect(budi.debtLimit, 250000);
      expect(
        budi.joinedAt.difference(before).abs(),
        lessThan(const Duration(minutes: 1)),
      );

      final audits = await db.select(db.auditEntries).get();
      final importedAudits = audits
          .where((a) => a.kind == AuditKind.memberCreated.name)
          .where((a) => a.actorUserId == caller.userId)
          .toList();
      expect(importedAudits, hasLength(2));
    expect(hub.events, hasLength(1));
    expect(hub.events.single.$1, WsEventTypes.membersRefresh);
    expect(hub.events.single.$2['count'], 2);
    },
  );
}
