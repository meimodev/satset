import 'dart:convert';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/members.dart';
import 'package:satset/server/ws_hub.dart';

const memberImportMaxBytes = 5 * 1024 * 1024;
const memberImportMaxRows = 10000;

const _headers = <String>{
  'nama',
  'telepon',
  'tanggal_lahir',
  'catatan',
  'kabupaten_kota',
  'kecamatan',
  'kelurahan_desa',
  'alamat',
  'batas_kredit',
};

class MemberImportException implements Exception {
  final String code;
  final int? row;
  const MemberImportException(this.code, {this.row});
}

enum MemberImportStatus { create, skip, invalid }

class MemberImportRow {
  final int row;
  final String name;
  final String phone;
  final String? note;
  final DateTime? birthday;
  final MemberAddress address;
  final int? debtLimit;
  final MemberImportStatus status;
  final List<String> errors;

  const MemberImportRow({
    required this.row,
    required this.name,
    required this.phone,
    required this.note,
    required this.birthday,
    required this.address,
    required this.debtLimit,
    required this.status,
    this.errors = const [],
  });

  MemberImportRow copyWith({
    MemberImportStatus? status,
    List<String>? errors,
  }) => MemberImportRow(
    row: row,
    name: name,
    phone: phone,
    note: note,
    birthday: birthday,
    address: address,
    debtLimit: debtLimit,
    status: status ?? this.status,
    errors: errors ?? this.errors,
  );

  Map<String, dynamic> toJson() => {
    'row': row,
    'name': name,
    'phone': phone,
    'status': status.name,
    'errors': errors,
  };
}

class MemberImportPreview {
  final List<MemberImportRow> rows;
  const MemberImportPreview(this.rows);

  int get createCount =>
      rows.where((r) => r.status == MemberImportStatus.create).length;
  int get skipCount =>
      rows.where((r) => r.status == MemberImportStatus.skip).length;
  int get invalidCount =>
      rows.where((r) => r.status == MemberImportStatus.invalid).length;

  Map<String, dynamic> toJson() => {
    'new': createCount,
    'skipped': skipCount,
    'invalid': invalidCount,
    'rows': [for (final row in rows) row.toJson()],
  };
}

Future<MemberImportPreview> previewMemberImport(
  AppDatabase db,
  List<int> bytes,
) async {
  if (bytes.length > memberImportMaxBytes) {
    throw const MemberImportException('file_too_large');
  }
  late String text;
  try {
    text = const Utf8Decoder(allowMalformed: false).convert(bytes);
  } on FormatException {
    throw const MemberImportException('invalid_utf8');
  }
  if (text.startsWith('\ufeff')) text = text.substring(1);

  final records = _parseCsv(text);
  if (records.isEmpty) throw const MemberImportException('missing_header');
  final header = records.first.values;
  final duplicates = <String>{};
  final seen = <String>{};
  for (final value in header) {
    if (!seen.add(value)) duplicates.add(value);
  }
  if (duplicates.isNotEmpty) {
    throw const MemberImportException('duplicate_header');
  }
  if (header.any((h) => !_headers.contains(h))) {
    throw const MemberImportException('unknown_header');
  }
  if (!header.contains('nama') || !header.contains('telepon')) {
    throw const MemberImportException('missing_header');
  }

  final data = records.skip(1).where((r) => !r.isBlank).toList();
  if (data.length > memberImportMaxRows) {
    throw const MemberImportException('too_many_rows');
  }
  final indexes = {for (var i = 0; i < header.length; i++) header[i]: i};
  final parsed = <MemberImportRow>[];
  for (final record in data) {
    final errors = <String>[];
    if (record.values.length != header.length) errors.add('column_count');
    String value(String name) {
      final i = indexes[name];
      return i == null || i >= record.values.length
          ? ''
          : record.values[i].trim();
    }

    final name = value('nama');
    final phone = normalizePhone(value('telepon'));
    if (name.isEmpty) errors.add('name_required');
    if (phone.length < 6) errors.add('phone_required');

    DateTime? birthday;
    final birthdayText = value('tanggal_lahir');
    if (birthdayText.isNotEmpty) {
      birthday = _date(birthdayText);
      if (birthday == null) errors.add('invalid_birthday');
    }
    int? debtLimit;
    final limitText = value('batas_kredit');
    if (limitText.isNotEmpty) {
      debtLimit = RegExp(r'^\d+$').hasMatch(limitText)
          ? int.tryParse(limitText)
          : null;
      if (debtLimit == null) errors.add('invalid_credit_limit');
    }
    parsed.add(
      MemberImportRow(
        row: record.row,
        name: name,
        phone: phone,
        note: _nullable(value('catatan')),
        birthday: birthday,
        address: MemberAddress(
          kabupaten: _nullable(value('kabupaten_kota')),
          kecamatan: _nullable(value('kecamatan')),
          kelurahan: _nullable(value('kelurahan_desa')),
          text: _nullable(value('alamat')),
        ),
        debtLimit: debtLimit,
        status: errors.isEmpty
            ? MemberImportStatus.create
            : MemberImportStatus.invalid,
        errors: errors,
      ),
    );
  }

  final phoneCounts = <String, int>{};
  for (final row in parsed) {
    if (row.phone.isNotEmpty) {
      phoneCounts[row.phone] = (phoneCounts[row.phone] ?? 0) + 1;
    }
  }
  final existingPhones = {
    for (final row in await db.select(db.members).get()) row.phone,
  };
  return MemberImportPreview([
    for (final row in parsed)
      if ((phoneCounts[row.phone] ?? 0) > 1)
        row.copyWith(
          status: MemberImportStatus.invalid,
          errors: {...row.errors, 'duplicate_phone'}.toList(),
        )
      else if (row.status == MemberImportStatus.create &&
          existingPhones.contains(row.phone))
        row.copyWith(status: MemberImportStatus.skip)
      else
        row,
  ]);
}

Future<MemberImportPreview> importMembers(
  AppDatabase db,
  List<int> bytes, {
  required String actorUserId,
  WsHub? hub,
}) async {
  late MemberImportPreview preview;
  await db.transaction(() async {
    preview = await previewMemberImport(db, bytes);
    if (preview.invalidCount > 0) {
      throw const MemberImportException('invalid_rows');
    }
    final importedAt = SatClock.now();
    for (final row in preview.rows) {
      if (row.status != MemberImportStatus.create) continue;
      await createMember(
        db,
        name: row.name,
        phone: row.phone,
        note: row.note,
        birthday: row.birthday,
        debtLimit: row.debtLimit,
        address: row.address,
        actorUserId: actorUserId,
        at: importedAt,
      );
    }
  });
  hub?.broadcast(WsEventTypes.membersRefresh, {'count': preview.createCount});
  return preview;
}

DateTime? _date(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final date = DateTime.utc(year, month, day);
  return date.year == year && date.month == month && date.day == day
      ? date
      : null;
}

String? _nullable(String value) => value.isEmpty ? null : value;

class _CsvRecord {
  final int row;
  final List<String> values;
  const _CsvRecord(this.row, this.values);
  bool get isBlank => values.every((v) => v.trim().isEmpty);
}

List<_CsvRecord> _parseCsv(String input) {
  final records = <_CsvRecord>[];
  var values = <String>[];
  var field = StringBuffer();
  var row = 1;
  var recordRow = 1;
  var quoted = false;
  var closedQuote = false;

  void finishField() {
    values.add(field.toString());
    field = StringBuffer();
    closedQuote = false;
  }

  void finishRecord() {
    finishField();
    records.add(_CsvRecord(recordRow, values));
    values = <String>[];
    recordRow = row + 1;
  }

  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
          closedQuote = true;
        }
      } else {
        field.write(char);
        if (char == '\n') row++;
      }
      continue;
    }
    if (closedQuote && char != ',' && char != '\r' && char != '\n') {
      throw MemberImportException('invalid_csv', row: recordRow);
    }
    if (char == '"') {
      if (field.isNotEmpty) {
        throw MemberImportException('invalid_csv', row: recordRow);
      }
      quoted = true;
    } else if (char == ',') {
      finishField();
    } else if (char == '\n') {
      finishRecord();
      row++;
    } else if (char == '\r') {
      if (i + 1 >= input.length || input[i + 1] != '\n') {
        throw MemberImportException('invalid_csv', row: recordRow);
      }
    } else {
      field.write(char);
    }
  }
  if (quoted) throw MemberImportException('invalid_csv', row: recordRow);
  if (field.isNotEmpty || values.isNotEmpty || closedQuote) finishRecord();
  return records;
}
