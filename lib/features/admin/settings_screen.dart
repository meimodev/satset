import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/layout.dart';
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
    final sc = context.sat;
    if (!context.layout.useTabletShell) {
      return _phone(context);
    }
    return AdminPage(
      title: 'Server & konfigurasi',
      sub: 'Warung Sebelah · Berawa, Bali · v2.0',
      topTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          adminPill(context, _offline ? 'Mode LAN' : 'LAN + Cloud', on: !_offline),
          const SizedBox(width: 8),
          adminPill(context, 'Salin diagnostik'),
        ],
      ),
      children: [
        // Top grid: hero + tiles
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
              const Expanded(child: SetTile(label: 'KDS Online', value: '3 / 3', sub: 'Dapur · Bar · Pass')),
              const SizedBox(width: 12),
              const Expanded(child: SetTile(label: 'Tablet Pair', value: '6', sub: 'BYOD 4 · Toko 2')),
              const SizedBox(width: 12),
              const Expanded(child: SetTile(label: 'Antrian', value: '0', sub: 'Tidak ada job tertunda')),
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
                  style: SatType.sans(size: 13, color: sc.textMd, height: 1.4),
                ),
              ),
              const SizedBox(width: 12),
              adminPill(context, 'Buat sesi cadangan'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _serverCard(BuildContext context, SatColors sc) {
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
                child: Text('Server LAN',
                    style: SatType.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: sc.textHi,
                    )),
              ),
              Text('PRIMARY',
                  style: SatType.mono(
                    size: 9,
                    weight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: sc.textLo,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          AdminRow(label: 'Alamat', value: Text('192.168.4.21', style: SatType.mono(size: 12, color: sc.textHi))),
          AdminRow(label: 'Sertifikat', value: Text('Valid · Let\'s Encrypt · 64 hari', style: SatType.sans(size: 13, color: sc.textHi))),
          AdminRow(label: 'Ping LAN', value: Text('38 ms p50 · 62 ms p95', style: SatType.mono(size: 12, color: sc.textHi))),
          AdminRow(label: 'Cloud sync', value: Row(children: [Text(_offline ? 'Ditunda' : 'Aktif', style: SatType.sans(size: 13, color: sc.textHi)), const Spacer(), GestureDetector(onTap: () => setState(() => _offline = !_offline), child: adminToggle(context, on: !_offline))])),
          AdminRow(label: 'Auto-resync', value: Row(children: [const Spacer(), GestureDetector(onTap: () => setState(() => _autosync = !_autosync), child: adminToggle(context, on: _autosync))]), last: true),
        ],
      ),
    );
  }

  Widget _printersCard(BuildContext context, SatColors sc) {
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
                child: Text('Printer & KDS',
                    style: SatType.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: sc.textHi,
                    )),
              ),
              Text('3 STASIUN',
                  style: SatType.mono(
                    size: 9,
                    weight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: sc.textLo,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          AdminRow(label: 'Dapur Utama', value: Row(children: [Text('192.168.4.51 · ESC/POS', style: SatType.mono(size: 12, color: sc.textHi)), const Spacer(), adminPill(context, 'OK', on: true)])),
          AdminRow(label: 'Bar', value: Row(children: [Text('192.168.4.52 · ESC/POS', style: SatType.mono(size: 12, color: sc.textHi)), const Spacer(), adminPill(context, 'OK', on: true)])),
          AdminRow(label: 'Pass / Expo', value: Row(children: [Text('192.168.4.53 · KDS', style: SatType.mono(size: 12, color: sc.textHi)), const Spacer(), adminPill(context, 'OK', on: true)])),
          AdminRow(label: 'Struk tamu', value: Row(children: [Text('192.168.4.55 · 58mm', style: SatType.mono(size: 12, color: sc.textHi)), const Spacer(), adminPill(context, 'Test cetak')]), last: true),
        ],
      ),
    );
  }

  Widget _devicesCard(BuildContext context, SatColors sc) {
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
          Text('Perangkat aktif',
              style: SatType.sans(size: 15, weight: FontWeight.w600, color: sc.textHi)),
          const SizedBox(height: 10),
          AdminRow(label: 'iPad-1 · Maya', value: Row(children: [Text('BYOD · 17:30', style: SatType.sans(size: 13, color: sc.textHi)), const Spacer(), adminPill(context, 'Aktif', on: true)])),
          AdminRow(label: 'iPad-2 · Dewi', value: Row(children: [Text('BYOD · 17:32', style: SatType.sans(size: 13, color: sc.textHi)), const Spacer(), adminPill(context, 'Aktif', on: true)])),
          AdminRow(label: 'Tablet-3 · Pass', value: Row(children: [Text('Toko · stasioner', style: SatType.sans(size: 13, color: sc.textHi)), const Spacer(), adminPill(context, 'Aktif', on: true)])),
          AdminRow(label: 'Tablet-4', value: Row(children: [Text('Tidak dipasangkan', style: SatType.sans(size: 13, color: sc.textLo)), const Spacer(), adminPill(context, 'Pair device')]), last: true),
        ],
      ),
    );
  }

  Widget _opsCard(BuildContext context, SatColors sc) {
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
          Text('Operasional',
              style: SatType.sans(size: 15, weight: FontWeight.w600, color: sc.textHi)),
          const SizedBox(height: 10),
          AdminRow(label: 'BYOD', value: Row(children: [const Spacer(), GestureDetector(onTap: () => setState(() => _byod = !_byod), child: adminToggle(context, on: _byod))])),
          AdminRow(label: 'Alert audio', value: Row(children: [const Spacer(), GestureDetector(onTap: () => setState(() => _audio = !_audio), child: adminToggle(context, on: _audio))])),
          AdminRow(label: 'Mode demo', value: Row(children: [const Spacer(), adminToggle(context, on: false)])),
          AdminRow(label: 'Tindakan', value: Row(children: [adminPill(context, 'Mulai ulang server'), const SizedBox(width: 8), adminPill(context, 'Stop semua', danger: true)]), last: true),
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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text('Sistem',
                style: SatType.sans(
                  size: 30,
                  weight: FontWeight.w600,
                  letterSpacing: -0.6,
                  color: sc.textHi,
                )),
          ),
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            children: [
              SetHero(
                label: _offline ? 'LAN saja' : 'Server OK',
                value: '38 ms',
                desc: 'Sinkron cloud last 4s yang lalu.',
                warn: _offline,
                meter: const [true, true, true, true, true, true],
              ),
              const SizedBox(height: 12),
              const SetTile(label: 'KDS Online', value: '3 / 3', sub: 'Dapur · Bar · Pass'),
              const SizedBox(height: 12),
              const SetTile(label: 'Perangkat', value: '6', sub: 'BYOD 4 · Toko 2'),
              const SizedBox(height: 12),
              _serverCard(context, sc),
            ],
          )),
        ],
      ),
    );
  }
}
