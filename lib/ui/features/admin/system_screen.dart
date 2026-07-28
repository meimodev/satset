import 'dart:async';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/device_dto.dart';
import 'package:satset/data/models/printer_dto.dart';
import 'package:satset/data/models/system_status_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/devices_repository.dart';
import 'package:satset/data/repositories/ping_repository.dart';
import 'package:satset/data/repositories/printers_repository.dart';
import 'package:satset/data/services/printer_discovery_service.dart';
import 'package:satset/data/repositories/system_status_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import '_common.dart';
import 'package:satset/ui/core/design/spacing.dart';

class SystemScreen extends ConsumerStatefulWidget {
  const SystemScreen({super.key});
  @override
  ConsumerState<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends ConsumerState<SystemScreen> {
  @override
  Widget build(BuildContext context) {
    if (!context.layout.useTabletShell) return _phone(context);
    return _tablet(context);
  }

  Widget _tablet(BuildContext context) {
    final sc = context.sat;
    final venueName = ref.watch(
      venueSettingsProvider.select((s) => s.displayName),
    );
    final wsState = ref.watch(wsConnStateProvider);
    final ping = ref.watch(pingProvider);
    final degraded = !ping.reachable || wsState != WsConnState.open;
    return AdminPage(
      title: 'Sistem',
      sub: '${venueName.isEmpty ? 'Venue' : venueName} · v2.0',
      topTrailing: SatChip.tag(
        label: degraded ? 'Mode degraded' : 'LAN online',
        size: SatChipSize.sm,
        // Degraded now reads as warn rather than neutral: a LAN that is half
        // up is not the same fact as one that is fine, and the old pill said
        // so only in words.
        hue: degraded ? SatChipHue.warn : SatChipHue.accent,
      ),
      children: _systemBody(context, sc),
    );
  }

  List<Widget> _systemBody(BuildContext context, SatColors sc) {
    final ping = ref.watch(pingProvider);
    final wsState = ref.watch(wsConnStateProvider);
    final status = ref.watch(systemStatusProvider);
    final devices = ref.watch(devicesRepositoryProvider);
    final stationsAsync = ref.watch(kdsStationsProvider);
    final queueAsync = ref.watch(queueDepthProvider);

    final pairedTablets = devices.where((d) => !d.revoked).length;
    final kdsCount = stationsAsync.maybeWhen(
      data: (s) => s.length,
      orElse: () => 0,
    );
    final queueTotal = queueAsync.maybeWhen(
      data: (m) => (m['total'] as num? ?? 0).toInt(),
      orElse: () => 0,
    );

    return [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: _SystemHero(ping: ping, wsState: wsState, status: status),
            ),
            const SizedBox(width: Sp.s3),
            Expanded(
              child: SetTile(
                label: 'KDS Online',
                value: '$kdsCount',
                sub: kdsCount == 0 ? 'Belum ada stasiun' : 'Stasiun aktif',
              ),
            ),
            const SizedBox(width: Sp.s3),
            Expanded(
              child: SetTile(
                label: 'Tablet Pair',
                value: '$pairedTablets',
                sub: pairedTablets == 0
                    ? 'Belum ada perangkat'
                    : 'Perangkat aktif',
              ),
            ),
            const SizedBox(width: Sp.s3),
            Expanded(
              child: SetTile(
                label: 'Antrian',
                value: '$queueTotal',
                sub: queueTotal == 0
                    ? 'Tidak ada job tertunda'
                    : 'Tiket menunggu',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: Sp.s3h),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _serverCard(context, sc)),
          const SizedBox(width: Sp.s3h),
          Expanded(child: _printersCard(context, sc)),
        ],
      ),
      const SizedBox(height: Sp.s3h),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _devicesCard(context, sc)),
          const SizedBox(width: Sp.s3h),
          Expanded(child: _opsCard(context, sc)),
        ],
      ),
    ];
  }

  Widget _serverCard(BuildContext context, SatColors sc) {
    final cfg = ref.watch(apiConfigProvider);
    final status = ref.watch(systemStatusProvider);
    final ping = ref.watch(pingProvider);

    String addr = '—';
    if (cfg != null) {
      addr = '${cfg.baseUri.host}:${status?.port ?? cfg.baseUri.port}';
    }
    final cert = status == null
        ? '—'
        : '${_relTime(status.tlsCertExpiry)} · ${_isoDate(status.tlsCertExpiry)}';
    final pingText = ping.latest == null
        ? '— ms'
        : 'p50 ${ping.p50?.inMilliseconds ?? ping.latest!.inMilliseconds} ms · last ${ping.latest!.inMilliseconds} ms';
    final fp = status?.tlsFingerprint ?? '';
    final fpShort = fp.length >= 12 ? '${fp.substring(0, 12)}…' : fp;

    return _sectionCard(
      context,
      sc,
      title: 'Server LAN',
      tag: status == null ? 'BOOTING' : 'PRIMARY',
      rows: [
        AdminRow(
          label: 'Alamat',
          value: Text(addr, style: SatType.monoM(color: sc.textHi)),
        ),
        AdminRow(
          label: 'Uptime',
          value: Text(
            status == null
                ? '—'
                : _humanDuration(Duration(milliseconds: status.uptimeMs)),
            style: SatType.monoM(color: sc.textHi),
          ),
        ),
        AdminRow(
          label: 'Sertifikat',
          value: Text(cert, style: SatType.bodyM(color: sc.textHi)),
        ),
        AdminRow(
          label: 'Ping LAN',
          value: Text(pingText, style: SatType.monoM(color: sc.textHi)),
        ),
        AdminRow(
          label: 'p95 latensi',
          value: Text(
            status == null
                ? '—'
                : '${status.p95LatencyMs} ms · ${status.requestCountRecent} req',
            style: SatType.monoM(color: sc.textHi),
          ),
        ),
        AdminRow(
          label: 'Fingerprint',
          value: Row(
            children: [
              Expanded(
                child: Text(fpShort, style: SatType.monoM(color: sc.textHi)),
              ),
              SatButton.outline(
                label: 'Salin',
                size: SatButtonSize.sm,
                onTap: fp.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: fp));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fingerprint disalin')),
                        );
                      },
              ),
            ],
          ),
          last: true,
        ),
      ],
    );
  }

  Widget _printersCard(BuildContext context, SatColors sc) {
    final printers = ref.watch(printersRepositoryProvider);
    final stationsAsync = ref.watch(kdsStationsProvider);
    final stations = stationsAsync.maybeWhen(
      data: (s) => s,
      orElse: () => const <Map<String, dynamic>>[],
    );
    final rows = <Widget>[];
    if (printers.isEmpty && stations.isEmpty) {
      rows.add(
        AdminRow(
          label: 'Belum ada',
          value: Text(
            'Tambahkan printer atau stasiun',
            style: SatType.bodyM(color: sc.textMd),
          ),
          last: true,
        ),
      );
    } else {
      for (var i = 0; i < printers.length; i++) {
        rows.add(
          _printerRow(
            context,
            sc,
            printers[i],
            last: i == printers.length - 1 && stations.isEmpty,
          ),
        );
      }
      for (var i = 0; i < stations.length; i++) {
        final s = stations[i];
        rows.add(_stationRow(context, sc, s, last: i == stations.length - 1));
      }
    }
    return _sectionCard(
      context,
      sc,
      title: 'Printer & KDS',
      tag: '${printers.length + stations.length} STASIUN',
      rows: rows,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SatButton.outline(
            label: 'Cari',
            size: SatButtonSize.sm,
            onTap: () => _discoverPrinters(context),
          ),
          const SizedBox(width: Sp.s1h),
          SatButton.outline(
            label: '+ Printer',
            size: SatButtonSize.sm,
            onTap: () => _showAddPrinterSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _printerRow(
    BuildContext context,
    SatColors sc,
    PrinterDto p, {
    bool last = false,
  }) {
    final online =
        p.lastSeenAt != null &&
        SatClock.now().difference(p.lastSeenAt!).inMinutes < 5;
    return AdminRow(
      label: p.label,
      value: Row(
        children: [
          Expanded(
            child: Text(
              '${p.host}:${p.port} · ${p.kind}',
              style: SatType.monoM(color: sc.textHi),
            ),
          ),
          SatButton.outline(
            label: 'Test',
            size: SatButtonSize.sm,
            onTap: () async {
              final err = await ref
                  .read(printersRepositoryProvider.notifier)
                  .testPrint(p.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(err ?? 'Tes tercetak')));
            },
          ),
          const SizedBox(width: Sp.s1h),
          SatChip.tag(
            label: online ? 'Online' : 'Offline',
            size: SatChipSize.sm,
            hue: online ? SatChipHue.accent : SatChipHue.neutral,
          ),
        ],
      ),
      last: last,
    );
  }

  Widget _stationRow(
    BuildContext context,
    SatColors sc,
    Map<String, dynamic> s, {
    bool last = false,
  }) {
    final name = s['station'] as String? ?? '—';
    final pending = (s['pendingTickets'] as num? ?? 0).toInt();
    final staffOnline = (s['staffOnline'] as num? ?? 0).toInt();
    return AdminRow(
      label: name,
      value: Row(
        children: [
          Expanded(
            child: Text(
              '$staffOnline staf · $pending tiket',
              style: SatType.bodyM(color: sc.textHi),
            ),
          ),
          SatChip.tag(
            label: pending == 0 ? 'Sepi' : 'Aktif',
            size: SatChipSize.sm,
            hue: pending > 0 ? SatChipHue.accent : SatChipHue.neutral,
          ),
        ],
      ),
      last: last,
    );
  }

  Widget _devicesCard(BuildContext context, SatColors sc) {
    final devices = ref.watch(devicesRepositoryProvider);
    return _sectionCard(
      context,
      sc,
      title: 'Perangkat aktif',
      tag: '${devices.where((d) => !d.revoked).length} PAIR',
      rows: devices.isEmpty
          ? [
              AdminRow(
                label: 'Belum ada',
                value: Text(
                  'Belum ada perangkat dipasangkan',
                  style: SatType.bodyM(color: sc.textMd),
                ),
                last: true,
              ),
            ]
          : [
              for (var i = 0; i < devices.length; i++)
                _deviceRow(
                  context,
                  sc,
                  devices[i],
                  last: i == devices.length - 1,
                ),
            ],
    );
  }

  Widget _deviceRow(
    BuildContext context,
    SatColors sc,
    DeviceDto d, {
    bool last = false,
  }) {
    final sub = d.lastSessionAt == null
        ? 'belum sign-in'
        : 'sesi ${_relTime(d.lastSessionAt!)}';
    final pillLabel = d.revoked
        ? 'Revoked'
        : d.sessionActive
        ? 'Aktif'
        : 'Idle';
    return AdminRow(
      label: d.label,
      value: Row(
        children: [
          Expanded(
            child: Text(sub, style: SatType.bodyM(color: sc.textHi)),
          ),
          if (!d.revoked)
            SatButton.outline(
              label: 'Revoke',
              size: SatButtonSize.sm,
              onTap: () => _confirmRevoke(d),
            ),
          const SizedBox(width: Sp.s1h),
          SatChip.tag(
            label: pillLabel,
            size: SatChipSize.sm,
            hue: d.sessionActive && !d.revoked
                ? SatChipHue.accent
                : SatChipHue.neutral,
          ),
        ],
      ),
      last: last,
    );
  }

  Widget _opsCard(BuildContext context, SatColors sc) {
    final audio = ref.watch(audioAlertEnabledProvider);
    return _sectionCard(
      context,
      sc,
      title: 'Operasional',
      tag: 'RUNTIME',
      rows: [
        AdminRow(
          label: 'Alert audio',
          value: Row(
            children: [
              const Spacer(),
              SatToggle(
                value: audio,
                semanticLabel: 'Alert audio',
                onChanged: (v) async {
                  final prefs = ref.read(prefsServiceProvider).valueOrNull;
                  if (prefs == null) return;
                  await prefs.setAudioAlertEnabled(v);
                  if (!context.mounted) return;
                  ref.invalidate(prefsServiceProvider);
                },
              ),
            ],
          ),
        ),
        AdminRow(
          label: 'Tindakan',
          value: Row(
            children: [
              SatButton.outline(
                label: 'Mulai ulang server',
                size: SatButtonSize.sm,
                onTap: () => _confirmRestart(),
              ),
            ],
          ),
          last: true,
        ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context,
    SatColors sc, {
    required String title,
    required String tag,
    required List<Widget> rows,
    Widget? trailing,
  }) {
    return SatCard.titled(
      title: title,
      tag: tag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [?trailing, ...rows],
      ),
    );
  }

  // --- Phone view ---

  Widget _phone(BuildContext context) {
    final sc = context.sat;
    final ping = ref.watch(pingProvider);
    final wsState = ref.watch(wsConnStateProvider);
    final devices = ref.watch(devicesRepositoryProvider);
    final printers = ref.watch(printersRepositoryProvider);
    final stationsAsync = ref.watch(kdsStationsProvider);
    final stations = stationsAsync.maybeWhen(
      data: (s) => s,
      orElse: () => const <Map<String, dynamic>>[],
    );

    final pingValue = ping.latest == null
        ? (wsState == WsConnState.open ? 'tunggu probe…' : 'offline')
        : '${ping.latest!.inMilliseconds} ms · ${wsState.name}';

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
            child: Text('Sistem', style: SatType.h1(color: sc.textHi)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Server, jaringan, printer, perangkat',
              style: SatType.bodyM(color: sc.textMd),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              children: [
                _phoneRow(
                  context,
                  sc,
                  label: 'Server LAN',
                  value: pingValue,
                  onTap: () => _openDetail(
                    context,
                    'Server LAN',
                    (c, s) => _serverCard(c, s),
                  ),
                ),
                _phoneRow(
                  context,
                  sc,
                  label: 'Printer & KDS',
                  value:
                      '${printers.length} printer · ${stations.length} stasiun',
                  onTap: () => _openDetail(
                    context,
                    'Printer & KDS',
                    (c, s) => _printersCard(c, s),
                  ),
                ),
                _phoneRow(
                  context,
                  sc,
                  label: 'Perangkat',
                  value:
                      '${devices.where((d) => !d.revoked).length} pair · ${devices.where((d) => d.sessionActive).length} aktif',
                  onTap: () => _openDetail(
                    context,
                    'Perangkat aktif',
                    (c, s) => _devicesCard(c, s),
                  ),
                ),
                _phoneRow(
                  context,
                  sc,
                  label: 'Operasional',
                  value: ref.watch(audioAlertEnabledProvider)
                      ? 'Audio on'
                      : 'Audio off',
                  onTap: () => _openDetail(
                    context,
                    'Operasional',
                    (c, s) => _opsCard(c, s),
                  ),
                  last: true,
                ),
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
        decoration: SatBox.d(
          color: sc.bg2,
          border: SatB.all(color: sc.border0),
          borderRadius: SatR.a(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: SatType.labelM(color: sc.textHi)),
                  const SizedBox(height: Sp.sHair),
                  Text(value, style: SatType.bodyS(color: sc.textMd)),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SystemPhoneDetail(title: title, builder: builder),
      ),
    );
  }

  // --- Dialogs ---

  Future<void> _confirmRestart() async {
    final auth = ref.read(authStateProvider);
    if (!auth.has(Capability.manageStaff)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak punya izin manageStaff')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _RestartPinDialog(),
    );
    if (ok != true || !mounted) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.postJson('/server/restart', const <String, dynamic>{});
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Server restart… menyambung ulang')),
      );
      // Wait for WS to flip back to open, then refresh status.
      final timeout = Timer(const Duration(seconds: 12), () {});
      final wsClient = ref.read(wsClientProvider);
      void listener() {
        if (wsClient.connState.value == WsConnState.open) {
          wsClient.connState.removeListener(listener);
          timeout.cancel();
          if (!mounted) return;
          ref.read(systemStatusProvider.notifier).refresh();
          ref.invalidate(kdsStationsProvider);
          ref.invalidate(queueDepthProvider);
        }
      }

      wsClient.connState.addListener(listener);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restart gagal: ${e.statusCode}')));
    }
  }

  Future<void> _confirmRevoke(DeviceDto d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Revoke device?'),
        content: Text('${d.label} akan kehilangan sesi.'),
        actions: [
          SatButton.ghost(
            label: AppStrings.cancel,
            onTap: () => Navigator.of(context).pop(false),
          ),
          SatButton.primary(
            label: 'Revoke',
            onTap: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(devicesRepositoryProvider.notifier).revoke(d.id);
    }
  }

  Future<void> _discoverPrinters(BuildContext context) async {
    // Non-blocking spinner dialog while discovery runs; popped when done.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: Sp.s6,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: Sp.s4),
            Text('Mencari printer…'),
          ],
        ),
      ),
    );
    final printers = await ref.read(printerDiscoveryServiceProvider).discover();
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (!context.mounted) return;
    if (printers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada printer ditemukan')),
      );
      return;
    }
    final chosen = await showDialog<DiscoveredPrinter>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Printer ditemukan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in printers)
              ListTile(
                leading: const Icon(Icons.print_rounded),
                title: Text(f.name),
                subtitle: Text('${f.host}:${f.port}'),
                onTap: () => Navigator.of(ctx).pop(f),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    await ref
        .read(printersRepositoryProvider.notifier)
        .create(label: chosen.name, host: chosen.host, port: chosen.port);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printer "${chosen.name}" ditambahkan')),
      );
    }
  }

  Future<void> _showAddPrinterSheet(BuildContext context) async {
    final labelCtl = TextEditingController();
    final hostCtl = TextEditingController();
    final portCtl = TextEditingController(text: '9100');
    String kind = 'escpos';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Tambah printer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SatField.text(controller: labelCtl, label: 'Label', hint: ''),
              SatField.text(controller: hostCtl, label: 'Host (IP)', hint: ''),
              SatField.number(controller: portCtl, label: 'Port', hint: ''),
              const SizedBox(height: Sp.s2),
              SatDropdown<String>(
                value: kind,
                label: 'Jenis',
                options: const [
                  SatOption('escpos', 'ESC/POS'),
                  SatOption('kds', 'KDS'),
                ],
                onChanged: (v) => setLocal(() => kind = v ?? 'escpos'),
              ),
            ],
          ),
          actions: [
            SatButton.ghost(
              label: AppStrings.cancel,
              onTap: () => Navigator.of(ctx).pop(false),
            ),
            SatButton.primary(
              label: AppStrings.add,
              onTap: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final label = labelCtl.text.trim();
    final host = hostCtl.text.trim();
    final port = int.tryParse(portCtl.text.trim()) ?? 9100;
    if (label.isEmpty || host.isEmpty) return;
    await ref
        .read(printersRepositoryProvider.notifier)
        .create(label: label, host: host, port: port, kind: kind);
  }
}

// ---- Hero widget ----

class _SystemHero extends StatelessWidget {
  final PingState ping;
  final WsConnState? wsState;
  final SystemStatusDto? status;
  const _SystemHero({
    required this.ping,
    required this.wsState,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final wsOpen = wsState == WsConnState.open;
    final reachable = ping.reachable;
    final warn = !reachable || !wsOpen;
    final pingMs = ping.latest?.inMilliseconds;
    final activeSessions = status?.activeSessions ?? 0;
    final paired = status?.pairedDevices ?? 0;
    final desc = warn
        ? 'WS ${wsState?.name ?? "—"} · reach=${reachable ? "ok" : "off"} · ${ping.consecutiveFailures} gagal'
        : '$activeSessions sesi aktif · $paired perangkat · WS ${wsState?.name ?? "—"}';
    return SetHero(
      label: warn ? 'Mode degraded' : 'Server LAN OK',
      value: pingMs == null ? '—' : '$pingMs ms',
      desc: desc,
      warn: warn,
      meter: [
        wsOpen,
        reachable,
        activeSessions > 0,
        paired > 0,
        status != null,
        (status?.p95LatencyMs ?? 0) < 500,
      ],
    );
  }
}

// ---- Restart confirm dialog ----

class _RestartPinDialog extends ConsumerStatefulWidget {
  const _RestartPinDialog();
  @override
  ConsumerState<_RestartPinDialog> createState() => _RestartPinDialogState();
}

class _RestartPinDialogState extends ConsumerState<_RestartPinDialog> {
  final _ctl = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mulai ulang server?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WS clients akan disconnect ~1-3 detik. Masukkan PIN untuk konfirmasi.',
          ),
          const SizedBox(height: Sp.s2h),
          SatField.pin(
            controller: _ctl,
            label: 'PIN',
            hint: '',
            errorText: _err,
          ),
        ],
      ),
      actions: [
        SatButton.ghost(
          label: AppStrings.cancel,
          onTap: _busy ? null : () => Navigator.of(context).pop(false),
        ),
        SatButton.primary(
          label: 'Konfirmasi',
          onTap: _busy
              ? null
              : () async {
                  final nav = Navigator.of(context);
                  setState(() => _busy = true);
                  final ok = await ref
                      .read(authStateProvider.notifier)
                      .signInWithPin(_ctl.text.trim());
                  if (!mounted) return;
                  if (ok) {
                    nav.pop(true);
                  } else {
                    setState(() {
                      _busy = false;
                      _err = 'PIN salah';
                    });
                  }
                },
        ),
      ],
    );
  }
}

// ---- Phone detail wrapper (unchanged behavior) ----

class _SystemPhoneDetail extends StatelessWidget {
  final String title;
  final Widget Function(BuildContext, SatColors) builder;
  const _SystemPhoneDetail({required this.title, required this.builder});

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
                    tooltip: AppStrings.back,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_rounded, color: sc.textHi),
                  ),
                  Expanded(
                    child: Text(title, style: SatType.h2(color: sc.textHi)),
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

// ---- helpers ----

String _humanDuration(Duration d) {
  if (d.inDays > 0) return '${d.inDays}h ${d.inHours % 24}j';
  if (d.inHours > 0) return '${d.inHours}j ${d.inMinutes % 60}m';
  if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
  return '${d.inSeconds}s';
}

String _relTime(DateTime t) {
  final now = SatClock.now();
  final diff = t.isAfter(now) ? t.difference(now) : now.difference(t);
  final suffix = t.isAfter(now) ? ' lagi' : ' lalu';
  if (diff.inDays > 365) return '${diff.inDays ~/ 365}thn$suffix';
  if (diff.inDays > 30) return '${diff.inDays ~/ 30}bl$suffix';
  if (diff.inDays > 0) return '${diff.inDays}h$suffix';
  if (diff.inHours > 0) return '${diff.inHours}j$suffix';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m$suffix';
  return '${diff.inSeconds}s$suffix';
}

String _isoDate(DateTime t) {
  final y = t.year.toString().padLeft(4, '0');
  final m = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
