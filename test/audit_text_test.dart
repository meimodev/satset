import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/core/localization/audit_text.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/repositories/audit_repository.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/server/audit_log.dart';
// Hides Drift's own row class of the same name — see audit_log.dart.
import 'package:satset/server/db/database.dart' hide AuditEntry;

/// ADR-0085: an audit row stores what happened, not a sentence about it.
///
/// The property worth defending is that one row, unchanged on disk, reads
/// correctly in either language — and that the rows written before this
/// existed still read at all.

final _id = lookupAppL10n(const Locale('id'));
final _en = lookupAppL10n(const Locale('en'));

AuditEntry _row(AuditKind kind, Map<String, String> params) => AuditEntry(
  id: 'x',
  type: AuditType.voidItem,
  title: 'frozen sentence',
  tableId: 'M4',
  when: '',
  kind: kind.name,
  params: params,
);

void main() {
  test('one row reads in both languages', () {
    final e = _row(AuditKind.voidItem, const {
      'qty': '2',
      'name': 'Nasi Goreng',
      'amount': 'Rp. 50.000',
    });
    expect(auditText(_id, e), 'Dibatalkan ×2 Nasi Goreng · Rp. 50.000');
    expect(auditText(_en, e), 'Voided ×2 Nasi Goreng · Rp. 50.000');
  });

  test('the export row counts its rows, and English agrees at one', () {
    // The one audit param read back as a number: `{rows}` is stored as a
    // string like every other (ADR-0085), but English needs an ICU plural or
    // it renders "1 rows".
    final many = _row(AuditKind.memberDirectoryExported, const {'rows': '40'});
    expect(auditText(_id, many), 'Ekspor daftar pelanggan (40 baris)');
    expect(auditText(_en, many), 'Exported member directory (40 rows)');

    final one = _row(AuditKind.memberDirectoryExported, const {'rows': '1'});
    expect(auditText(_en, one), 'Exported member directory (1 row)');

    // A row written by a newer build with a param this reader cannot parse
    // still renders a sentence rather than throwing.
    final junk = _row(AuditKind.memberDirectoryExported, const {'rows': '?'});
    expect(auditText(_en, junk), contains('0 rows'));
  });

  test('a parameter that is itself a word follows the language too', () {
    // The method and the receipt label are keys, not copy — so they translate
    // with the sentence around them. The money between them never does.
    final e = _row(AuditKind.paymentRecorded, const {
      'amount': 'Rp. 13.986',
      'method': 'tunai',
      'label': 'A',
    });
    expect(auditText(_id, e), 'Pembayaran Rp. 13.986 (Tunai) Tamu A');
    expect(auditText(_en, e), 'Payment Rp. 13.986 (Cash) Guest A');
  });

  test('a pre-ADR-0085 row falls back to its stored sentence', () {
    const legacy = AuditEntry(
      id: 'x',
      type: AuditType.voidItem,
      title: 'Dibatalkan Nasi Goreng',
      tableId: 'M4',
      when: '',
    );
    // Indonesian even for an English reader: that is genuinely what was
    // recorded, and inventing structure for it would be guessing.
    expect(auditText(_en, legacy), 'Dibatalkan Nasi Goreng');
  });

  test('a kind this build does not know falls back rather than throwing', () {
    const future = AuditEntry(
      id: 'x',
      type: AuditType.voidItem,
      title: 'something a newer server wrote',
      tableId: 'M4',
      when: '',
      kind: 'somethingFromTheFuture',
      params: {'a': 'b'},
    );
    expect(auditText(_en, future), 'something a newer server wrote');
  });

  test('a written row survives the round trip through the wire', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await writeAudit(
      db,
      type: AuditType.tableMoved,
      kind: AuditKind.tableMoved,
      params: const {'src': 'M4', 'tgt': 'M9'},
    );
    final rows = await db.select(db.auditEntries).get();
    final decoded = auditEntryFromJson(auditJson(rows.single));

    expect(auditText(_id, decoded), 'Pindah meja M4 → M9');
    expect(auditText(_en, decoded), 'Moved table M4 → M9');
    // The stored title is the frozen fallback, in the writing device's
    // language — never what a screen shows.
    expect(rows.single.title, 'Pindah meja M4 → M9');
    expect(satL10n.localeName, 'id');
  });
}
