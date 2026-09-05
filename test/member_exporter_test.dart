// The three membership export files (ADR-0137).
//
// A CSV header row is the contract a venue files against — somebody's
// spreadsheet has a formula pointing at column F — and it is exactly the kind
// of thing a careless edit reorders without anything going red. Nothing else
// covers it: the copy bans in `design_tokens_test.dart` scan `Text()` calls in
// `lib/ui`, and a `csvRow` is not one.
//
// What is pinned here is the shape, not the prose: the header rows, the order
// of the directory's importable half, and the two decisions the builders make
// on their own — that money stays Indonesian while the words do not (ADR-0084),
// and that a share is only named on a bill that was actually split.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/core/export/member_exporter.dart';
import 'package:satset/data/models/member_dto.dart';
import 'package:satset/data/models/member_report_dto.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/l10n/app_localizations.dart';

final _id = lookupAppL10n(const Locale('id'));
final _en = lookupAppL10n(const Locale('en'));

MemberDto _member() => MemberDto(
  member: Member(
    id: 'm1',
    name: 'Budi Santoso',
    phone: '081234567890',
    code: 'BS01',
    note: 'Suka pedas',
    birthday: DateTime(1990, 5, 17),
    joinedAt: DateTime(2026, 1, 4),
    address: const MemberAddress(
      kabupaten: 'Kota Manado',
      kecamatan: 'Wenang',
      kelurahan: 'Pinaesaan',
      text: 'Jl. Sam Ratulangi No. 12',
    ),
    points: 1250,
    punchProgress: 3,
    visitCount: 9,
    lifetimeSpend: 4250000,
    lastVisitAt: DateTime(2026, 8, 20),
    debt: 50000,
    debtLimit: 200000,
  ),
  punchTarget: 10,
);

MemberReportDto _report({List<MemberTradeDto> members = const []}) =>
    MemberReportDto(
      enabled: true,
      pointsEnabled: true,
      splitEnabled: true,
      enrolled: 4,
      activeMembers: 12,
      returningMembers: 5,
      enrolledTotal: 30,
      idleMembers: 18,
      memberBills: 20,
      memberNet: 5000000,
      guestBills: 40,
      guestNet: 8000000,
      avgMemberBill: 250000,
      avgGuestBill: 200000,
      splitBills: 3,
      pointsEarned: 500,
      pointsRedeemed: 200,
      pointsAdjusted: 10,
      pointsOutstanding: 310,
      liabilityEstimate: 310000,
      members: members,
      membersTruncated: 0,
      earliestClosedAt: DateTime(2026, 1, 1),
    );

MemberHistoryDto _history({required bool shared}) => MemberHistoryDto(
  memberId: 'm1',
  member: const {'name': 'Budi Santoso', 'phone': '081234567890'},
  bills: [
    MemberBillDto(
      sessionId: 's1',
      closedAt: DateTime(2026, 8, 20, 19, 30),
      tableLabel: 'A1',
      pax: 4,
      kind: 'dineIn',
      billTotal: 400000,
      share: shared ? 100000 : 400000,
      owner: true,
      units: 6,
    ),
  ],
  billsTotal: 1,
  products: [
    MemberProductDto(
      itemId: 'i1',
      name: 'Ayam Rica',
      qty: 6,
      spend: 300000,
      lastAt: DateTime(2026, 8, 20),
    ),
  ],
  visits: 1,
  spend: 400000,
  units: 6,
  avgBill: 400000,
  untrackedSpend: 0,
);

List<String> _rowsOf(String csv) => csv.split('\r\n');

void main() {
  test('the directory leads with the importable columns, in import order', () {
    final csv = buildMemberDirectoryCsv(
      _id,
      [_member()],
      filterLine: memberFilterLine(_id),
      at: DateTime(2026, 9, 5, 14, 32),
    );
    final rows = _rowsOf(csv);
    // Four header lines, a blank, then the table.
    final header = rows[5].split(',');
    expect(header.take(9).toList(), [
      'Nama',
      'Nomor HP',
      'Ulang tahun',
      'Catatan',
      'Kabupaten/Kota',
      'Kecamatan',
      'Kelurahan/Desa',
      // Quoted: the label carries a comma, which is the whole reason
      // `csvCell` exists.
      '"Alamat (jalan',
      ' no.)"',
    ]);
    expect(
      header.contains('Batas kredit'),
      isTrue,
      reason: 'the ninth import field closes the importable half',
    );
    // Then the derived tail, which the importer has never heard of.
    for (final col in [
      'Kode',
      'Poin',
      'Stempel',
      'Piutang',
      'Kunjungan',
      'Total belanja',
      'Kunjungan terakhir',
      'Bergabung',
    ]) {
      expect(header.contains(col), isTrue, reason: col);
    }
  });

  test('the directory says which members it is', () {
    final all = buildMemberDirectoryCsv(
      _id,
      [_member()],
      filterLine: memberFilterLine(_id),
    );
    expect(_rowsOf(all)[2], contains('Semua pelanggan'));

    final cut = buildMemberDirectoryCsv(
      _id,
      [_member()],
      filterLine: memberFilterLine(_id, lapsedDays: 90, query: 'budi'),
    );
    // A filtered roster that did not say so would read as a shrinking
    // membership to the next person who opened it.
    expect(_rowsOf(cut)[2], contains('90'));
    expect(_rowsOf(cut)[2], contains('budi'));
  });

  test('directory money stays raw so a spreadsheet can add it up', () {
    final csv = buildMemberDirectoryCsv(
      _id,
      [_member()],
      filterLine: memberFilterLine(_id),
    );
    final row = _rowsOf(csv).last;
    expect(row, contains('4250000'));
    expect(
      row,
      isNot(contains('Rp')),
      reason: 'these columns mirror import fields, not printed rupiah',
    );
  });

  test('the words follow the language and the rupiah does not', () {
    final rows = [
      const MemberTradeDto(
        memberId: 'm1',
        name: 'Budi',
        phone: '081234567890',
        visits: 3,
        spend: 1250000,
        points: 40,
        lastVisitAt: null,
      ),
    ];
    final idCsv = buildMemberRankedCsv(
      _id,
      _report(members: rows),
      rows,
      windowLabel: '30 hari',
      sortLabel: 'Belanja',
    );
    final enCsv = buildMemberRankedCsv(
      _en,
      _report(members: rows),
      rows,
      windowLabel: '30 days',
      sortLabel: 'Spend',
    );

    expect(idCsv, contains('Ringkasan'));
    expect(enCsv, contains('Summary'));
    expect(enCsv, isNot(contains('Ringkasan')));
    // ADR-0084: money is `id_ID` in both languages.
    expect(idCsv, contains('Rp. 1.250.000'));
    expect(enCsv, contains('Rp. 1.250.000'));
  });

  test('the ranked file carries the summary before the list', () {
    final csv = buildMemberRankedCsv(
      _id,
      _report(),
      const [],
      windowLabel: '30 hari',
      sortLabel: 'Belanja',
    );
    final rows = _rowsOf(csv);
    expect(rows.first, 'Laporan pelanggan');
    expect(csv.indexOf('Ringkasan'), lessThan(csv.indexOf('Nomor HP')));
    // The sort travels with the file: it is what the reader was looking at.
    expect(rows[2], contains('Belanja'));
  });

  test('a share is named only on a bill that was actually split', () {
    final alone = buildMemberHistoryCsv(
      _id,
      _history(shared: false),
      windowLabel: '30 hari',
    );
    final split = buildMemberHistoryCsv(
      _id,
      _history(shared: true),
      windowLabel: '30 hari',
    );
    // On a bill held alone "pemilik" is a word that says nothing, exactly as
    // the screen decides not to draw the badge — and with no split anywhere in
    // the window the column itself stands down, header included, rather than
    // filling a file with blanks.
    expect(alone, isNot(contains('pemilik')));
    expect(alone, isNot(contains('Peran')));
    expect(split, contains('pemilik'));
    expect(split, contains('Peran'));
  });

  test('a deleted member still gets a file', () {
    final h = MemberHistoryDto(
      memberId: 'gone',
      member: null,
      bills: const [],
      billsTotal: 0,
      products: const [],
      visits: 0,
      spend: 0,
      units: 0,
      avgBill: 0,
      untrackedSpend: 0,
    );
    // ADR-0092: the person is gone, the trade the venue did is not.
    expect(memberHistoryHeading(_id, h), _id.mrpDeleted);
    expect(
      buildMemberHistoryCsv(_id, h, windowLabel: 'Semua'),
      contains('Riwayat pelanggan'),
    );
  });
}
