import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/layout.dart';
import '_common.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _offline = false;
  bool _byod = true;
  bool _audio = true;
  bool _autosync = true;

  @override
  Widget build(BuildContext context) {
    if (!context.layout.useTabletShell) return _phone(context);
    return _tablet(context);
  }

  Widget _tablet(BuildContext context) {
    final sc = context.sat;
    final venueName = ref.watch(
        venueSettingsProvider.select((s) => s.displayName));
    return AdminPage(
      title: 'Server & konfigurasi',
      sub: '${venueName.isEmpty ? 'Venue' : venueName} · v2.0',
      topTrailing: adminPill(
        context,
        _offline ? 'Mode LAN' : 'LAN + Cloud',
        on: !_offline,
      ),
      children: _systemBody(context, sc),
    );
  }

  List<Widget> _systemBody(BuildContext context, SatColors sc) {
    return [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: SetHero(
                label: _offline ? 'LAN saja · cloud tunggu' : 'Server LAN OK',
                value: _offline ? '128 ms' : '38 ms',
                desc: _offline
                    ? 'Cloud sync ditunda — pesanan tetap masuk antrian lokal. Mengirim ulang otomatis.'
                    : 'Semua stasiun online. Sinkron cloud last ${_offline ? '—' : '4s yang lalu'}.',
                warn: _offline,
                meter: _offline
                    ? [true, true, false, true, false, false]
                    : [true, true, true, true, true, true],
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
                child: SetTile(
                    label: 'KDS Online',
                    value: '3 / 3',
                    sub: 'Dapur · Bar · Pass')),
            const SizedBox(width: 12),
            const Expanded(
                child: SetTile(
                    label: 'Tablet Pair',
                    value: '6',
                    sub: 'BYOD 4 · Toko 2')),
            const SizedBox(width: 12),
            const Expanded(
                child: SetTile(
                    label: 'Antrian',
                    value: '0',
                    sub: 'Tidak ada job tertunda')),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _serverCard(context, sc)),
          const SizedBox(width: 14),
          Expanded(child: _printersCard(context, sc)),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _devicesCard(context, sc)),
          const SizedBox(width: 14),
          Expanded(child: _opsCard(context, sc)),
        ],
      ),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: sc.bg2,
          border: Border.all(color: sc.border0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'PIN sesi berakhir pukul 03:00. Buat sesi cadangan jika shift berlanjut.',
                style:
                    SatType.sans(size: 13, color: sc.textMd, height: 1.4),
              ),
            ),
            const SizedBox(width: 12),
            adminPill(context, 'Buat sesi cadangan'),
          ],
        ),
      ),
    ];
  }

  Widget _serverCard(BuildContext context, SatColors sc) {
    return _sectionCard(
      context,
      sc,
      title: 'Server LAN',
      tag: 'PRIMARY',
      rows: [
        AdminRow(
            label: 'Alamat',
            value: Text('192.168.4.21',
                style: SatType.mono(size: 12, color: sc.textHi))),
        AdminRow(
            label: 'Sertifikat',
            value: Text("Valid · Let's Encrypt · 64 hari",
                style: SatType.sans(size: 13, color: sc.textHi))),
        AdminRow(
            label: 'Ping LAN',
            value: Text('38 ms p50 · 62 ms p95',
                style: SatType.mono(size: 12, color: sc.textHi))),
        AdminRow(
            label: 'Cloud sync',
            value: Row(children: [
              Text(_offline ? 'Ditunda' : 'Aktif',
                  style: SatType.sans(size: 13, color: sc.textHi)),
              const Spacer(),
              GestureDetector(
                  onTap: () => setState(() => _offline = !_offline),
                  child: adminToggle(context, on: !_offline)),
            ])),
        AdminRow(
            label: 'Auto-resync',
            value: Row(children: [
              const Spacer(),
              GestureDetector(
                  onTap: () => setState(() => _autosync = !_autosync),
                  child: adminToggle(context, on: _autosync)),
            ]),
            last: true),
      ],
    );
  }

  Widget _printersCard(BuildContext context, SatColors sc) {
    return _sectionCard(
      context,
      sc,
      title: 'Printer & KDS',
      tag: '3 STASIUN',
      rows: [
        AdminRow(
            label: 'Dapur Utama',
            value: Row(children: [
              Text('192.168.4.51 · ESC/POS',
                  style: SatType.mono(size: 12, color: sc.textHi)),
              const Spacer(),
              adminPill(context, 'OK', on: true),
            ])),
        AdminRow(
            label: 'Bar',
            value: Row(children: [
              Text('192.168.4.52 · ESC/POS',
                  style: SatType.mono(size: 12, color: sc.textHi)),
              const Spacer(),
              adminPill(context, 'OK', on: true),
            ])),
        AdminRow(
            label: 'Pass / Expo',
            value: Row(children: [
              Text('192.168.4.53 · KDS',
                  style: SatType.mono(size: 12, color: sc.textHi)),
              const Spacer(),
              adminPill(context, 'OK', on: true),
            ])),
        AdminRow(
            label: 'Struk tamu',
            value: Row(children: [
              Text('192.168.4.55 · 58mm',
                  style: SatType.mono(size: 12, color: sc.textHi)),
              const Spacer(),
              adminPill(context, 'Test cetak'),
            ]),
            last: true),
      ],
    );
  }

  Widget _devicesCard(BuildContext context, SatColors sc) {
    return _sectionCard(
      context,
      sc,
      title: 'Perangkat aktif',
      tag: '4 PAIR',
      rows: [
        AdminRow(
            label: 'iPad-1 · Maya',
            value: Row(children: [
              Text('BYOD · 17:30',
                  style: SatType.sans(size: 13, color: sc.textHi)),
              const Spacer(),
              adminPill(context, 'Aktif', on: true),
            ])),
        AdminRow(
            label: 'iPad-2 · Dewi',
            value: Row(children: [
              Text('BYOD · 17:32',
                  style: SatType.sans(size: 13, color: sc.textHi)),
              const Spacer(),
              adminPill(context, 'Aktif', on: true),
            ])),
        AdminRow(
            label: 'Tablet-3 · Pass',
            value: Row(children: [
              Text('Toko · stasioner',
                  style: SatType.sans(size: 13, color: sc.textHi)),
              const Spacer(),
              adminPill(context, 'Aktif', on: true),
            ])),
        AdminRow(
            label: 'Tablet-4',
            value: Row(children: [
              Text('Tidak dipasangkan',
                  style: SatType.sans(size: 13, color: sc.textLo)),
              const Spacer(),
              adminPill(context, 'Pair device'),
            ]),
            last: true),
      ],
    );
  }

  Widget _opsCard(BuildContext context, SatColors sc) {
    return _sectionCard(
      context,
      sc,
      title: 'Operasional',
      tag: 'RUNTIME',
      rows: [
        AdminRow(
            label: 'BYOD',
            value: Row(children: [
              const Spacer(),
              GestureDetector(
                  onTap: () => setState(() => _byod = !_byod),
                  child: adminToggle(context, on: _byod)),
            ])),
        AdminRow(
            label: 'Alert audio',
            value: Row(children: [
              const Spacer(),
              GestureDetector(
                  onTap: () => setState(() => _audio = !_audio),
                  child: adminToggle(context, on: _audio)),
            ])),
        AdminRow(
            label: 'Mode demo',
            value: Row(children: [
              const Spacer(),
              adminToggle(context, on: false),
            ])),
        AdminRow(
            label: 'Tindakan',
            value: Row(children: [
              adminPill(context, 'Mulai ulang server'),
              const SizedBox(width: 8),
              adminPill(context, 'Stop semua', danger: true),
            ]),
            last: true),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context,
    SatColors sc, {
    required String title,
    required String tag,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: SatType.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: sc.textHi,
                    )),
              ),
              Text(tag,
                  style: SatType.mono(
                    size: 9,
                    weight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: sc.textLo,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _phone(BuildContext context) {
    final sc = context.sat;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
            child: Text('Server & konfigurasi',
                style: SatType.sans(
                  size: 30,
                  weight: FontWeight.w600,
                  letterSpacing: -0.6,
                  color: sc.textHi,
                )),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text('Server, printer, perangkat, operasional',
                style: SatType.sans(size: 13, color: sc.textMd)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              children: [
                _phoneRow(context, sc,
                    label: 'Server LAN',
                    value: _offline ? '128 ms · LAN' : '38 ms · OK',
                    onTap: () => _openDetail(context, 'Server LAN',
                        (c, s) => _serverCard(c, s))),
                _phoneRow(context, sc,
                    label: 'Printer & KDS',
                    value: '3 stasiun aktif',
                    onTap: () => _openDetail(context, 'Printer & KDS',
                        (c, s) => _printersCard(c, s))),
                _phoneRow(context, sc,
                    label: 'Perangkat',
                    value: '4 pair · 2 BYOD',
                    onTap: () => _openDetail(context, 'Perangkat aktif',
                        (c, s) => _devicesCard(c, s))),
                _phoneRow(context, sc,
                    label: 'Operasional',
                    value: _byod ? 'BYOD on' : 'BYOD off',
                    onTap: () => _openDetail(context, 'Operasional',
                        (c, s) => _opsCard(c, s)),
                    last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneRow(
    BuildContext context,
    SatColors sc, {
    required String label,
    required String value,
    required VoidCallback onTap,
    bool last = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: last ? 0 : 8),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: sc.bg2,
          border: Border.all(color: sc.border0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: SatType.sans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: sc.textHi,
                      )),
                  const SizedBox(height: 2),
                  Text(value,
                      style: SatType.sans(size: 12, color: sc.textMd)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 22, color: sc.textLo),
          ],
        ),
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    String title,
    Widget Function(BuildContext, SatColors) builder,
  ) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PhoneDetailScreen(title: title, builder: builder),
    ));
  }
}

class _PhoneDetailScreen extends StatelessWidget {
  final String title;
  final Widget Function(BuildContext, SatColors) builder;
  const _PhoneDetailScreen({required this.title, required this.builder});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Scaffold(
      backgroundColor: sc.bg1,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_rounded, color: sc.textHi),
                  ),
                  Expanded(
                    child: Text(title,
                        style: SatType.sans(
                          size: 22,
                          weight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: sc.textHi,
                        )),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [builder(context, sc)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
