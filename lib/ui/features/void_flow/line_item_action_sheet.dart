import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/data/repositories/audit_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/use_cases/advance_ticket_status_use_case.dart';

// Canonical reason codes — must match the server taxonomy in
// reports_routes.dart and the void_reason_code DB column (see ADR-0006).
const _voidReasons = <Map<String, String>>[
  {'id': 'wrongOrder', 'label': 'Terkirim salah', 'desc': 'Salah meja, tap ganda, salah ring'},
  {'id': 'customerChange', 'label': 'Tamu berubah pikiran', 'desc': 'Tamu batalkan permintaan'},
  {'id': 'outOfStock', 'label': 'Stok habis', 'desc': 'Item habis di stasiun'},
  {'id': 'kitchenError', 'label': 'Komplain / kualitas dapur', 'desc': 'Masalah kualitas — pertimbangkan refire'},
  {'id': 'other', 'label': 'Lainnya', 'desc': 'Alasan bebas wajib diisi'},
];

void showLineItemActionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String tableId,
  required Ticket ticket,
}) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scroll) => _SheetBody(
        ref: ref,
        tableId: tableId,
        ticket: ticket,
        scrollController: scroll,
      ),
    ),
  );
}

enum _Step { actions, voidReason, confirmed }

class _SheetBody extends StatefulWidget {
  final WidgetRef ref;
  final String tableId;
  final Ticket ticket;
  final ScrollController scrollController;
  const _SheetBody({
    required this.ref,
    required this.tableId,
    required this.ticket,
    required this.scrollController,
  });

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  _Step _step = _Step.actions;
  Map<String, String>? _reason;
  String _reasonText = '';

  String _nowStamp() {
    final d = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(d.hour)}:${pad(d.minute)}';
  }

  Future<void> _pickAction(String id) async {
    final t = widget.ticket;
    final notifier = widget.ref.read(ticketsProvider.notifier);
    final useCase = widget.ref.read(advanceTicketStatusUseCaseProvider);
    final audit = widget.ref.read(auditProvider.notifier);
    switch (id) {
      case 'modify':
      case 'request-modify':
        audit.add(AuditEntry(
          id: 'A${DateTime.now().millisecondsSinceEpoch}',
          type: AuditType.modify,
          title: 'Modifikasi ×${t.qty} ${t.name}',
          tableId: widget.tableId,
          when: _nowStamp(),
          reason: id == 'request-modify' ? 'Menunggu konfirmasi stasiun' : 'Edit pra-prep',
        ));
        if (mounted) Navigator.of(context).pop();
        break;
      case 'fire':
        await notifier.fireCourse(widget.tableId, t.course);
        if (mounted) Navigator.of(context).pop();
        break;
      case 'serve':
        await useCase.call(widget.tableId, t.id, TicketStatus.served);
        if (mounted) Navigator.of(context).pop();
        break;
      case 'unserve':
        // served → ready is the canonical undo path (see _allowedTransitions
        // in lib/server/routes/tickets_routes.dart).
        await useCase.call(widget.tableId, t.id, TicketStatus.ready);
        if (mounted) Navigator.of(context).pop();
        break;
      case 'void':
        setState(() => _step = _Step.voidReason);
        break;
    }
  }

  Future<void> _commitVoid() async {
    final t = widget.ticket;
    final reason = _reason!;
    // Free-text rides only for `other`; fixed reasons store their label so the
    // audit row + reports read cleanly. The server stamps the acting waiter.
    final reasonStr = _reasonText.isNotEmpty ? _reasonText : reason['label']!;
    await widget.ref.read(advanceTicketStatusUseCaseProvider).call(
          widget.tableId,
          t.id,
          TicketStatus.voided,
          voidReason: reasonStr,
          voidReasonCode: reason['id']!,
        );
    setState(() => _step = _Step.confirmed);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      decoration: BoxDecoration(
        color: sc.bg1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
            child: Container(
              width: 38,
              height: 4,
              decoration:
                  BoxDecoration(color: sc.textDim, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          _Head(ticket: widget.ticket, tableId: widget.tableId, onClose: () => Navigator.of(context).pop()),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: switch (_step) {
                _Step.actions => _ActionList(ticket: widget.ticket, onPick: _pickAction),
                _Step.voidReason => _VoidReasonList(
                    onPick: (r, text) {
                      _reason = r;
                      _reasonText = text;
                      _commitVoid();
                    },
                  ),
                _Step.confirmed => _ConfirmedView(ticket: widget.ticket),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Head extends StatelessWidget {
  final Ticket ticket;
  final String tableId;
  final VoidCallback onClose;
  const _Head({required this.ticket, required this.tableId, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusChip(status: ticket.status),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'MEJA $tableId · ${ticket.sentAt}',
                        style: SatType.mono(
                          size: 10,
                          color: sc.textLo,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '×${ticket.qty} ${ticket.name}${ticket.variantName.isEmpty ? '' : ' · ${ticket.variantName}'}',
                  style: SatType.sans(
                    size: 17,
                    weight: FontWeight.w600,
                    letterSpacing: -0.17,
                    height: 1.2,
                    color: sc.textHi,
                  ),
                ),
                if (ticket.modifiers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(ticket.modifiers.join(' · '),
                        style: SatType.sans(
                          size: 12,
                          color: sc.textMd,
                          height: 1.35,
                        )),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, size: 18, color: sc.textMd),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TicketStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    Color bg;
    Color fg;
    switch (status) {
      case TicketStatus.draft:
      case TicketStatus.acknowledged:
      case TicketStatus.sent:
        bg = sc.infoSoft;
        fg = sc.info;
        break;
      case TicketStatus.prep:
        bg = sc.warnSoft;
        fg = sc.warn;
        break;
      case TicketStatus.cooked:
        bg = sc.accentSoft;
        fg = sc.accent;
        break;
      case TicketStatus.ready:
        bg = sc.successSoft;
        fg = sc.success;
        break;
      case TicketStatus.served:
        bg = sc.bg3;
        fg = sc.textLo;
        break;
      case TicketStatus.held:
        bg = sc.violetSoft;
        fg = sc.violet;
        break;
      case TicketStatus.voided:
        bg = sc.urgentSoft;
        fg = sc.urgent;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        ticketStatusLabel(status).toUpperCase(),
        style: SatType.mono(
          size: 10,
          weight: FontWeight.w600,
          letterSpacing: 1.0,
          color: fg,
        ),
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  final Ticket ticket;
  final ValueChanged<String> onPick;
  const _ActionList({required this.ticket, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final rows = <_ActionItem>[];
    if (ticket.status == TicketStatus.sent || ticket.status == TicketStatus.held) {
      rows.add(_ActionItem(
        id: 'modify',
        icon: Icons.edit,
        title: 'Modifikasi item',
        desc: 'Edit opsi & catatan — tanpa approval',
        tone: _Tone.normal,
      ));
    }
    if (ticket.status == TicketStatus.held) {
      rows.add(_ActionItem(
        id: 'fire',
        icon: Icons.local_fire_department,
        title: 'Bakar sekarang',
        desc: 'Kirim course ke line langsung',
        tone: _Tone.accent,
      ));
    }
    if (ticket.status == TicketStatus.prep) {
      rows.add(_ActionItem(
        id: 'request-modify',
        icon: Icons.edit,
        title: 'Minta perubahan',
        desc: 'Stasiun harus konfirmasi — "masih bisa" / "terlambat"',
        tone: _Tone.warn,
      ));
    }
    if (ticket.status == TicketStatus.ready) {
      rows.add(_ActionItem(
        id: 'serve',
        icon: Icons.check,
        title: 'Tandai disajikan',
        desc: 'Konfirmasi diambil & diantar ke meja',
        tone: _Tone.success,
      ));
    }
    if (ticket.status == TicketStatus.served) {
      rows.add(_ActionItem(
        id: 'unserve',
        icon: Icons.undo,
        title: 'Batalkan sajian',
        desc: 'Kembalikan status jika ditandai terlalu cepat',
        tone: _Tone.normal,
      ));
    }
    if (ticket.status != TicketStatus.voided) {
      rows.add(_ActionItem(
        id: 'void',
        icon: Icons.delete_outline,
        title: 'Batalkan item',
        desc: 'Hapus dari pesanan · tercatat atas nama kamu',
        tone: _Tone.danger,
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        children: [
          for (final r in rows) ...[
            _ActionRow(
              item: r,
              onTap: () => onPick(r.id),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 60),
          Text(
            'Tap luar sheet untuk batal.',
            style: SatType.sans(size: 11, color: sc.textLo),
          ),
        ],
      ),
    );
  }
}

enum _Tone { normal, accent, warn, success, danger }

class _ActionItem {
  final String id;
  final IconData icon;
  final String title;
  final String desc;
  final _Tone tone;
  _ActionItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.desc,
    required this.tone,
  });
}

class _ActionRow extends StatelessWidget {
  final _ActionItem item;
  final VoidCallback onTap;
  const _ActionRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    Color border = sc.border0;
    Color iconBg = sc.bg3;
    Color iconFg = sc.textMd;
    Color titleColor = sc.textHi;
    switch (item.tone) {
      case _Tone.danger:
        border = sc.urgent.withValues(alpha: 0.2);
        iconBg = sc.urgentSoft;
        iconFg = sc.urgent;
        titleColor = sc.urgent;
        break;
      case _Tone.accent:
        border = sc.accentBorder;
        iconBg = sc.accentSoft;
        iconFg = sc.accent;
        break;
      case _Tone.warn:
        border = sc.warn.withValues(alpha: 0.25);
        iconBg = sc.warnSoft;
        iconFg = sc.warn;
        break;
      case _Tone.success:
        border = sc.success.withValues(alpha: 0.25);
        iconBg = sc.successSoft;
        iconFg = sc.success;
        break;
      case _Tone.normal:
        break;
    }
    return Material(
      color: sc.bg2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, size: 18, color: iconFg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: SatType.sans(
                          size: 14,
                          weight: FontWeight.w600,
                          letterSpacing: -0.14,
                          color: titleColor,
                        )),
                    const SizedBox(height: 2),
                    Text(item.desc,
                        style: SatType.sans(
                          size: 11,
                          color: sc.textMd,
                          height: 1.35,
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: sc.textLo),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoidReasonList extends StatefulWidget {
  final void Function(Map<String, String> reason, String text) onPick;
  const _VoidReasonList({required this.onPick});

  @override
  State<_VoidReasonList> createState() => _VoidReasonListState();
}

class _VoidReasonListState extends State<_VoidReasonList> {
  String? _pickedId;
  String _other = '';

  bool get _canContinue =>
      _pickedId != null && (_pickedId != 'other' || _other.trim().length >= 3);

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: sc.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sc.border0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: sc.warn),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pembatalan dicatat dengan sign-in kamu dan alasannya — terlihat di laporan. Refire mungkin lebih cocok untuk isu kualitas.',
                    style: SatType.sans(size: 12, color: sc.textMd, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          for (final r in _voidReasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: _pickedId == r['id'] ? sc.accentSoft : sc.bg2,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => setState(() => _pickedId = r['id']),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _pickedId == r['id'] ? sc.accentBorder : sc.border0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _pickedId == r['id'] ? sc.accent : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _pickedId == r['id'] ? sc.accent : sc.border2,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: _pickedId == r['id']
                              ? Icon(Icons.check, size: 14, color: sc.accentInk)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['label']!,
                                  style: SatType.sans(
                                      size: 14, weight: FontWeight.w500, color: sc.textHi)),
                              const SizedBox(height: 2),
                              Text(r['desc']!,
                                  style: SatType.sans(size: 11, color: sc.textMd)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_pickedId == 'other')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextField(
                maxLength: 120,
                onChanged: (v) => setState(() => _other = v),
                decoration: InputDecoration(
                  hintText: 'Wajib — jelaskan alasan pembatalan',
                  filled: true,
                  fillColor: sc.bg2,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: sc.urgent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: sc.urgent),
                  ),
                  counterText: '',
                  hintStyle: SatType.sans(size: 13, color: sc.textLo),
                ),
                style: SatType.sans(size: 13, color: sc.textHi),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _canContinue
                  ? () {
                      final r = _voidReasons.firstWhere((x) => x['id'] == _pickedId);
                      widget.onPick(r, _pickedId == 'other' ? _other.trim() : '');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: sc.accent,
                disabledBackgroundColor: sc.accent.withValues(alpha: 0.45),
                foregroundColor: sc.accentInk,
                elevation: 0,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Batalkan item',
                      style: SatType.sans(
                        size: 15,
                        weight: FontWeight.w600,
                        color: sc.accentInk,
                      )),
                  const SizedBox(width: 6),
                  Icon(Icons.delete_outline, size: 14, color: sc.accentInk),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmedView extends StatelessWidget {
  final Ticket ticket;
  const _ConfirmedView({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sc.urgent.withValues(alpha: 0.16),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.delete_outline, size: 46, color: sc.urgent),
          ),
          const SizedBox(height: 16),
          Text('Item dibatalkan',
              style: SatType.sans(
                size: 22,
                weight: FontWeight.w600,
                letterSpacing: -0.22,
                color: sc.textHi,
              )),
          const SizedBox(height: 8),
          Text(
            'Tercatat: ×${ticket.qty} ${ticket.name} · atas nama kamu · terlihat di laporan',
            textAlign: TextAlign.center,
            style: SatType.sans(size: 13, color: sc.textMd, height: 1.45),
          ),
        ],
      ),
    );
  }
}
