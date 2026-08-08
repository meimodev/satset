import 'package:flutter/material.dart';

import 'package:satset/core/localization/audit_text.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/ui/core/design/audit_visuals.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/features/admin/audit_labels.dart';

/// The money half of the venue log, for the off-site owner (ADR-0086).
///
/// This is the owner's replacement for the non-cash payments card that used to
/// sit in the report. It is deliberately **not** the admin's audit table: that
/// screen is six fixed columns and tablet-only, and this one has to survive a
/// phone, so each row stacks instead — type and amount on top, the sentence
/// under it, actor and time beneath that.
///
/// No proof photos and no tap target. Blobs never leave the LAN (ADR-0036), and
/// an indicator that opens nothing is worse than no indicator at all.
class OwnerMoneyAuditBlock extends StatelessWidget {
  final MoneyAuditSectionDto section;
  const OwnerMoneyAuditBlock({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    if (section.rows.isEmpty) {
      return SatCard.section(
        header: context.l10n.ownMoneyAuditTitle,
        child: Text(
          context.l10n.ownMoneyAuditEmpty,
          style: SatType.bodyM(color: sc.textLo),
        ),
      );
    }
    return SatCard.section(
      header: context.l10n.ownMoneyAuditTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (section.truncated) ...[
            Text(
              context.l10n.ownMoneyAuditTruncated(section.rows.length),
              style: SatType.bodyS(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s3),
          ],
          for (final r in section.rows) _MoneyAuditRow(row: r),
        ],
      ),
    );
  }
}

class _MoneyAuditRow extends StatelessWidget {
  final MoneyAuditRowDto row;
  const _MoneyAuditRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final type = _type(row.type);
    final tone = auditTone(type, sc);
    // Composed here, in the reader's language, from the structured fields the
    // snapshot carried — never the venue device's frozen `title`, which is
    // whatever language that tablet happened to be set to (ADR-0085). `title`
    // rides only as the fallback for rows written before that existed.
    final entry = AuditEntry(
      id: row.id,
      type: type,
      title: row.title,
      tableId: row.tableLabel ?? '',
      when: row.at,
      kind: row.kind,
      params: row.params,
      amountCents: row.amountCents,
      actorName: row.actorName,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: SatBox.d(color: tone.bg, borderRadius: SatR.a(6)),
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.s2,
                  vertical: Sp.sHair,
                ),
                child: Text(
                  auditTypeLabel(context.l10n, type),
                  style: SatType.labelS(color: tone.fg),
                ),
              ),
              const SizedBox(width: Sp.s2),
              Expanded(
                child: Text(
                  row.tableLabel ?? '—',
                  style: SatType.bodyS(color: sc.textLo),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Sp.s2),
              Text(
                row.amountCents == null ? '—' : formatIDR(row.amountCents!),
                style: SatType.monoM(color: sc.textHi),
              ),
            ],
          ),
          const SizedBox(height: Sp.s1h),
          Text(
            auditText(context.l10n, entry),
            style: SatType.bodyS(color: sc.textHi),
          ),
          const SizedBox(height: Sp.sHair),
          Text(
            '${formatClockId(row.at)} · ${row.actorName ?? context.l10n.auditSystemActor}',
            style: SatType.bodyS(color: sc.textLo),
          ),
        ],
      ),
    );
  }

  /// A snapshot published by a newer server can name a type this build has no
  /// value for. Such a row still shows its sentence, amount and actor — the
  /// pill just falls back rather than the row vanishing.
  AuditType _type(String name) => AuditType.values.firstWhere(
    (t) => t.name == name,
    orElse: () => AuditType.modify,
  );
}
