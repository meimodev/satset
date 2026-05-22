import 'package:flutter/material.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/layout.dart';
import '_common.dart';

class _Staff {
  final String initials;
  final String name;
  final String role;
  final String shift;
  final String pin;
  final List<String> tags;
  final bool online;
  final List<Color> grad;
  const _Staff({
    required this.initials,
    required this.name,
    required this.role,
    required this.shift,
    required this.pin,
    required this.tags,
    required this.online,
    required this.grad,
  });
}

const _staff = <_Staff>[
  _Staff(initials: 'AB', name: 'Ari Budi', role: 'Owner', shift: '—', pin: '••••', tags: ['Approver'], online: true, grad: [Color(0xFFC08AFF), Color(0xFF6D3FC4)]),
  _Staff(initials: 'PN', name: 'Pak Nyoman', role: 'Manajer', shift: '17:00 — 02:00', pin: '••••', tags: ['Approver'], online: true, grad: [Color(0xFF6DB5FF), Color(0xFF4060D0)]),
  _Staff(initials: 'BD', name: 'Bu Dewi', role: 'Supervisor', shift: '17:15 — 02:00', pin: '••••', tags: ['Lead', 'Approver'], online: true, grad: [Color(0xFF4DD487), Color(0xFF1F6E3E)]),
  _Staff(initials: 'MA', name: 'Maya Anjani', role: 'Pelayan', shift: '17:30 — 02:00', pin: '••••', tags: ['BYOD'], online: true, grad: [Color(0xFFFF9233), Color(0xFFD96030)]),
  _Staff(initials: 'DW', name: 'Dewi Wira', role: 'Pelayan', shift: '17:30 — 02:00', pin: '••••', tags: ['BYOD'], online: true, grad: [Color(0xFFFF9233), Color(0xFFD96030)]),
  _Staff(initials: 'KT', name: 'Komang T.', role: 'Expediter', shift: '17:30 — 02:00', pin: '••••', tags: [], online: true, grad: [Color(0xFFFFC04D), Color(0xFFB87A1A)]),
  _Staff(initials: 'MD', name: 'Made D.', role: 'Dapur', shift: '16:30 — 02:00', pin: '••••', tags: ['Lead'], online: true, grad: [Color(0xFFFF5C5C), Color(0xFFB03030)]),
  _Staff(initials: 'WY', name: 'Wayan Y.', role: 'Dapur', shift: '16:30 — 02:00', pin: '••••', tags: [], online: true, grad: [Color(0xFFFF5C5C), Color(0xFFB03030)]),
  _Staff(initials: 'KS', name: 'Kadek S.', role: 'Bar', shift: '17:00 — 02:00', pin: '••••', tags: [], online: true, grad: [Color(0xFF4DD487), Color(0xFF1F6E3E)]),
  _Staff(initials: 'NM', name: 'Nyoman M.', role: 'Pelayan', shift: '—', pin: '••••', tags: [], online: false, grad: [Color(0xFFFF9233), Color(0xFFD96030)]),
];

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    if (!context.layout.useTabletShell) {
      return SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 120),
          itemCount: _staff.length,
          itemBuilder: (ctx, i) => _phoneRow(ctx, _staff[i]),
        ),
      );
    }
    return AdminPage(
      title: 'Staff & akun',
      sub: '10 anggota · 8 aktif · 3 approver',
      topTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          adminPill(context, 'Edit peran'),
          const SizedBox(width: 8),
          adminPill(context, 'Tambah staf', on: true),
        ],
      ),
      children: [
        Container(
          decoration: BoxDecoration(
            color: sc.bg2,
            border: Border.all(color: sc.border0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _row(context, head: true),
              for (final s in _staff) _row(context, s: s),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: sc.bg2,
            border: Border.all(color: sc.border0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Matriks izin',
                  style: SatType.sans(size: 15, weight: FontWeight.w600, color: sc.textHi)),
              const SizedBox(height: 14),
              _permRow(context, head: true, cells: const ['Peran', 'Buka meja', 'Kirim order', 'Void', 'Comp', 'Cetak', 'Akun']),
              _permRow(context, cells: const ['Owner', '✓', '✓', '✓', '✓', '✓', '✓']),
              _permRow(context, cells: const ['Manajer', '✓', '✓', '✓', '✓', '✓', '—']),
              _permRow(context, cells: const ['Supervisor', '✓', '✓', '✓', '—', '✓', '—']),
              _permRow(context, cells: const ['Pelayan', '✓', '✓', '—', '—', '✓', '—']),
              _permRow(context, cells: const ['Expediter', '—', '—', '—', '—', '✓', '—']),
              _permRow(context, cells: const ['Dapur / Bar', '—', '—', '—', '—', '—', '—'], last: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _phoneRow(BuildContext context, _Staff s) {
    final sc = context.sat;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _avatar(s, online: s.online, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: SatType.sans(size: 14, weight: FontWeight.w500, color: sc.textHi)),
                const SizedBox(height: 2),
                Text('${s.role} · ${s.shift}', style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.4)),
              ],
            ),
          ),
          if (s.online) Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: sc.success, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, {_Staff? s, bool head = false}) {
    final sc = context.sat;
    if (head) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: sc.border0)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 44),
            const SizedBox(width: 14),
            Expanded(flex: 14, child: _h(context, 'Nama')),
            Expanded(flex: 10, child: _h(context, 'Peran')),
            Expanded(flex: 10, child: _h(context, 'Shift')),
            SizedBox(width: 60, child: _h(context, 'PIN')),
            Expanded(flex: 9, child: _h(context, 'Tag')),
            SizedBox(width: 60, child: _h(context, 'Status')),
            SizedBox(width: 100, child: _h(context, 'Last seen')),
            SizedBox(width: 100, child: _h(context, '')),
          ],
        ),
      );
    }
    final st = s!;
    final isLast = _staff.indexOf(st) == _staff.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: sc.border0),
        ),
      ),
      child: Row(
        children: [
          _avatar(st, online: st.online),
          const SizedBox(width: 14),
          Expanded(
            flex: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(st.name, style: SatType.sans(size: 14, weight: FontWeight.w500, color: sc.textHi, letterSpacing: -0.14)),
                const SizedBox(height: 3),
                Text(st.online ? 'iPad-${_staff.indexOf(st) + 1}' : 'Offline', style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.4)),
              ],
            ),
          ),
          Expanded(flex: 10, child: Text(st.role, style: SatType.sans(size: 13, color: sc.textMd))),
          Expanded(flex: 10, child: Text(st.shift, style: SatType.mono(size: 11, color: sc.textMd, letterSpacing: 0.44))),
          SizedBox(width: 60, child: Text(st.pin, style: SatType.mono(size: 14, color: sc.textMd))),
          Expanded(
            flex: 9,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final t in st.tags) _tag(context, t),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: st.online ? sc.success : sc.textLo, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(st.online ? 'ON' : 'OFF', style: SatType.mono(size: 11, weight: FontWeight.w600, letterSpacing: 0.44, color: st.online ? sc.success : sc.textLo)),
              ],
            ),
          ),
          SizedBox(width: 100, child: Text(st.online ? '— sekarang' : '12 Mei 21:08', style: SatType.mono(size: 11, color: sc.textLo, letterSpacing: 0.44))),
          SizedBox(
            width: 100,
            child: Row(
              children: [
                adminPill(context, 'Edit'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _h(BuildContext context, String t) {
    final sc = context.sat;
    return Text(t.toUpperCase(),
        style: SatType.mono(
          size: 10,
          weight: FontWeight.w600,
          letterSpacing: 1.2,
          color: sc.textLo,
        ));
  }

  Widget _tag(BuildContext context, String t) {
    final sc = context.sat;
    final lead = t == 'Lead';
    final approver = t == 'Approver';
    final byod = t == 'BYOD';
    Color bg = sc.bg3;
    Color fg = sc.textMd;
    if (lead) { bg = sc.accentSoft; fg = sc.accent; }
    if (approver) { bg = sc.violetSoft; fg = sc.violet; }
    if (byod) { bg = sc.infoSoft; fg = sc.info; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(t.toUpperCase(),
          style: SatType.mono(
            size: 9,
            weight: FontWeight.w600,
            letterSpacing: 0.8,
            color: fg,
          )),
    );
  }

  Widget _avatar(_Staff s, {required bool online, double size = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: s.grad,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Text(s.initials,
              style: SatType.mono(
                size: 12,
                weight: FontWeight.w600,
                color: Colors.white,
              )),
          if (online)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF4DD487),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1C1F23), width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _permRow(BuildContext context, {required List<String> cells, bool head = false, bool last = false}) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: last ? BorderSide.none : BorderSide(color: sc.border0),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: i == 0 ? 14 : (i == 5 ? 7 : 10),
              child: head
                  ? _h(context, cells[i])
                  : Text(
                      cells[i],
                      style: i == 0
                          ? SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textHi)
                          : SatType.mono(
                              size: 13,
                              weight: cells[i] == '✓' ? FontWeight.w700 : FontWeight.w400,
                              color: cells[i] == '✓'
                                  ? sc.success
                                  : (cells[i] == '—' ? sc.textDim : sc.textMd),
                            ),
                    ),
            ),
        ],
      ),
    );
  }
}
