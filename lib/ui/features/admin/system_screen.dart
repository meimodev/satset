import 'dart:async';
import 'package:satset/ui/core/design/shell_inset.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/repositories/generic_seed.dart';
import 'package:satset/ui/features/admin/widgets/seed_data_dialog.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:satset/l10n/app_localizations.dart';
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
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import '_common.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/localization/report_copy.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';

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
      title: context.l10n.sysTitle,
      sub: context.l10n.sysHeaderSub(
        venueName.isEmpty ? context.l10n.sysVenueFallback : venueName,
      ),
      topTrailing: SatChip.tag(
        label: degraded ? context.l10n.sysDegraded : context.l10n.sysLanOnline,
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
                label: context.l10n.sysKdsOnline,
                value: '$kdsCount',
                sub: kdsCount == 0
                    ? context.l10n.sysNoStations
                    : context.l10n.sysStationsActive,
              ),
            ),
            const SizedBox(width: Sp.s3),
            Expanded(
              child: SetTile(
                label: context.l10n.sysTabletPair,
                value: '$pairedTablets',
                sub: pairedTablets == 0
                    ? context.l10n.sysNoDevices
                    : context.l10n.sysDevicesActive,
              ),
            ),
            const SizedBox(width: Sp.s3),
            Expanded(
              child: SetTile(
                label: context.l10n.sysQueue,
                value: '$queueTotal',
                sub: queueTotal == 0
                    ? context.l10n.sysNoPendingJobs
                    : context.l10n.sysTicketsWaiting,
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
        : '${_relTime(context.l10n, status.tlsCertExpiry)} · ${_isoDate(status.tlsCertExpiry)}';
    final pingText = ping.latest == null
        ? '— ms'
        : context.l10n.sysPingValue(
            ping.p50?.inMilliseconds ?? ping.latest!.inMilliseconds,
            ping.latest!.inMilliseconds,
          );
    final fp = status?.tlsFingerprint ?? '';
    final fpShort = fp.length >= 12 ? '${fp.substring(0, 12)}…' : fp;

    return _sectionCard(
      context,
      sc,
      title: context.l10n.sysServerLan,
      tag: status == null
          ? context.l10n.sysTagBooting
          : context.l10n.sysTagPrimary,
      rows: [
        AdminRow(
          label: context.l10n.sysAddress,
          value: Text(addr, style: SatType.monoM(color: sc.textHi)),
        ),
        AdminRow(
          label: context.l10n.sysUptime,
          value: Text(
            status == null
                ? '—'
                : _humanDuration(
                    context.l10n,
                    Duration(milliseconds: status.uptimeMs),
                  ),
            style: SatType.monoM(color: sc.textHi),
          ),
        ),
        AdminRow(
          label: context.l10n.sysCertificate,
          value: Text(cert, style: SatType.bodyM(color: sc.textHi)),
        ),
        AdminRow(
          label: context.l10n.sysPingLan,
          value: Text(pingText, style: SatType.monoM(color: sc.textHi)),
        ),
        AdminRow(
          label: context.l10n.sysP95,
          value: Text(
            status == null
                ? '—'
                : context.l10n.sysP95Value(
                    status.p95LatencyMs,
                    status.requestCountRecent,
                  ),
            style: SatType.monoM(color: sc.textHi),
          ),
        ),
        AdminRow(
          label: context.l10n.sysFingerprint,
          value: Row(
            children: [
              Expanded(
                child: Text(fpShort, style: SatType.monoM(color: sc.textHi)),
              ),
              SatButton.outline(
                label: context.l10n.sysCopy,
                size: SatButtonSize.sm,
                onTap: fp.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: fp));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.sysFingerprintCopied),
                          ),
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
          label: context.l10n.sysNoneYet,
          value: Text(
            context.l10n.sysAddPrinterOrStation,
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
      title: context.l10n.sysPrintersKds,
      tag: context.l10n.sysTagStations(printers.length + stations.length),
      rows: rows,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SatButton.outline(
            label: context.l10n.sysDiscover,
            size: SatButtonSize.sm,
            onTap: () => _discoverPrinters(context),
          ),
          const SizedBox(width: Sp.s1h),
          SatButton.outline(
            label: context.l10n.sysAddPrinterBtn,
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
            label: context.l10n.sysPrinterTest,
            size: SatButtonSize.sm,
            onTap: () async {
              final err = await ref
                  .read(printersRepositoryProvider.notifier)
                  .testPrint(p.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(err ?? context.l10n.sysTestPrinted)),
              );
            },
          ),
          const SizedBox(width: Sp.s1h),
          SatChip.tag(
            label: online ? context.l10n.sysOnline : context.l10n.sysOffline,
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
    // The server sends the station code (`kitchen`), not its name — resolve it
    // the same way the reports do, or the row reads as a wire value.
    final name = stationLabel(context.l10n, s['station'] as String? ?? '—');
    final pending = (s['pendingTickets'] as num? ?? 0).toInt();
    final staffOnline = (s['staffOnline'] as num? ?? 0).toInt();
    return AdminRow(
      label: name,
      value: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.sysStationLoad(staffOnline, pending),
              style: SatType.bodyM(color: sc.textHi),
            ),
          ),
          SatChip.tag(
            label: pending == 0
                ? context.l10n.sysStationQuiet
                : context.l10n.sysStationBusy,
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
      title: context.l10n.sysDevicesTitle,
      tag: context.l10n.sysTagPair(devices.where((d) => !d.revoked).length),
      rows: devices.isEmpty
          ? [
              AdminRow(
                label: context.l10n.sysNoneYet,
                value: Text(
                  context.l10n.sysNoDevicesPaired,
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
        ? context.l10n.sysNeverSignedIn
        : context.l10n.sysLastSession(_relTime(context.l10n, d.lastSessionAt!));
    final pillLabel = d.revoked
        ? context.l10n.sysRevoked
        : d.sessionActive
        ? context.l10n.sysDeviceActive
        : context.l10n.sysDeviceIdle;
    return AdminRow(
      label: d.label,
      value: Row(
        children: [
          Expanded(
            child: Text(sub, style: SatType.bodyM(color: sc.textHi)),
          ),
          if (!d.revoked)
            SatButton.outline(
              label: context.l10n.sysRevoke,
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

  // Audio lives entirely on /alerts (ADR-0044): a device-wide "Alert audio"
  // switch here silently overrode the per-event mute list two screens away, so
  // an operator who muted one cue there could not tell why nothing sounded.
  Widget _opsCard(BuildContext context, SatColors sc) {
    return _sectionCard(
      context,
      sc,
      title: context.l10n.sysOperational,
      tag: context.l10n.sysTagRuntime,
      rows: [
        AdminRow(
          label: context.l10n.sysActions,
          value: Row(
            children: [
              SatButton.outline(
                label: context.l10n.sysRestartServer,
                size: SatButtonSize.sm,
                onTap: () => _confirmRestart(),
              ),
            ],
          ),
        ),
        // The permanent way back in after the first-run prompt was skipped
        // (ADR-0073). Without this a single tap on "Lewati" would put the
        // sample data permanently out of reach.
        AdminRow(
          label: context.l10n.settingsSeedTitle,
          value: SatButton.outline(
            label: ref.watch(genericSeedProvider).hasSampleData
                ? context.l10n.venueHubSeedBtnClear
                : context.l10n.venueHubSeedBtnLoad,
            size: SatButtonSize.sm,
            onTap: () => showSeedDataDialog(context),
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
        ? (wsState == WsConnState.open
              ? context.l10n.sysWaitingProbe
              : context.l10n.sysOfflineLower)
        : context.l10n.sysPingWs(ping.latest!.inMilliseconds, wsState.name);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
            child: Text(
              context.l10n.sysTitle,
              style: SatType.h1(color: sc.textHi),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              context.l10n.sysPhoneSub,
              style: SatType.bodyM(color: sc.textMd),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, Sp.s6 + context.shellInset),
              children: [
                _phoneRow(
                  context,
                  sc,
                  label: context.l10n.sysServerLan,
                  value: pingValue,
                  onTap: () => _openDetail(
                    context,
                    context.l10n.sysServerLan,
                    (c, s) => _serverCard(c, s),
                  ),
                ),
                _phoneRow(
                  context,
                  sc,
                  label: context.l10n.sysPrintersKds,
                  value: context.l10n.sysPrinterStationCount(
                    printers.length,
                    stations.length,
                  ),
                  onTap: () => _openDetail(
                    context,
                    context.l10n.sysPrintersKds,
                    (c, s) => _printersCard(c, s),
                  ),
                ),
                _phoneRow(
                  context,
                  sc,
                  label: context.l10n.sysDevices,
                  value: context.l10n.sysPairActiveCount(
                    devices.where((d) => !d.revoked).length,
                    devices.where((d) => d.sessionActive).length,
                  ),
                  onTap: () => _openDetail(
                    context,
                    context.l10n.sysDevicesTitle,
                    (c, s) => _devicesCard(c, s),
                  ),
                ),
                _phoneRow(
                  context,
                  sc,
                  label: context.l10n.sysOperational,
                  value: context.l10n.sysRestartServer,
                  onTap: () => _openDetail(
                    context,
                    context.l10n.sysOperational,
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
    // A pushed task page owns its chrome: on the root navigator the
    // shell bar is gone, so this page's own title row is the only one.
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => _SystemPhoneDetail(title: title, builder: builder),
      ),
    );
  }

  // --- Dialogs ---

  Future<void> _confirmRestart() async {
    final auth = ref.read(authStateProvider);
    if (!auth.has(Capability.manageStaff)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.sysNoManageStaff)));
      return;
    }
    final ok = await showSatDialog<bool>(
      context,
      builder: (_) => const _RestartPinDialog(),
    );
    if (ok != true || !mounted) return;
    final l10n = context.l10n;
    final api = ref.read(apiClientProvider);
    try {
      await api.postJson('/server/restart', const <String, dynamic>{});
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text(l10n.sysRestarting)));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sysRestartFailed('${e.statusCode}'))),
      );
    }
  }

  Future<void> _confirmRevoke(DeviceDto d) async {
    final ok = await showSatDialog<bool>(
      context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.sysRevokeTitle),
        content: Text(context.l10n.sysRevokeBody(d.label)),
        actions: [
          SatButton.ghost(
            label: context.l10n.cancel,
            onTap: () => Navigator.of(context).pop(false),
          ),
          SatButton.primary(
            label: context.l10n.sysRevoke,
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
    showSatDialog<void>(
      context,
      dismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(width: Sp.s6, height: 22, child: SatSpinner()),
            const SizedBox(width: Sp.s4),
            Text(context.l10n.sysSearchingPrinters),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.sysNoPrintersFound)));
      return;
    }
    final chosen = await showSatDialog<DiscoveredPrinter>(
      context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.sysPrintersFound),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in printers)
              ListTile(
                leading: const Icon(Icons.print_rounded),
                title: Text(f.name),
                subtitle: Text(context.l10n.sysHostPort(f.host, f.port)),
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
        SnackBar(content: Text(context.l10n.sysPrinterAdded(chosen.name))),
      );
    }
  }

  Future<void> _showAddPrinterSheet(BuildContext context) async {
    final labelCtl = TextEditingController();
    final hostCtl = TextEditingController();
    final portCtl = TextEditingController(text: '9100');
    String kind = 'escpos';
    final ok = await showSatDialog<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(context.l10n.sysAddPrinterTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SatField.text(
                controller: labelCtl,
                label: context.l10n.sysPrinterLabel,
                hint: '',
              ),
              SatField.text(
                controller: hostCtl,
                label: context.l10n.sysPrinterHost,
                hint: '',
              ),
              SatField.number(
                controller: portCtl,
                label: context.l10n.sysPrinterPort,
                hint: '',
              ),
              const SizedBox(height: Sp.s2),
              SatDropdown<String>(
                value: kind,
                label: context.l10n.sysPrinterKind,
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
              label: context.l10n.cancel,
              onTap: () => Navigator.of(ctx).pop(false),
            ),
            SatButton.primary(
              label: context.l10n.add,
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
        ? context.l10n.sysHeroWarnDesc(
            wsState?.name ?? '—',
            reachable ? context.l10n.sysReachOk : context.l10n.sysReachOff,
            ping.consecutiveFailures,
          )
        : context.l10n.sysHeroOkDesc(
            activeSessions,
            paired,
            wsState?.name ?? '—',
          );
    return SetHero(
      label: warn ? context.l10n.sysDegraded : context.l10n.sysServerLanOk,
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
      title: Text(context.l10n.sysRestartTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.sysRestartBody),
          const SizedBox(height: Sp.s2h),
          SatField.pin(
            controller: _ctl,
            label: context.l10n.sysPin,
            hint: '',
            errorText: _err,
          ),
        ],
      ),
      actions: [
        SatButton.ghost(
          label: context.l10n.cancel,
          onTap: _busy ? null : () => Navigator.of(context).pop(false),
        ),
        SatButton.primary(
          label: context.l10n.sysConfirm,
          onTap: _busy
              ? null
              : () async {
                  final nav = Navigator.of(context);
                  final l10n = context.l10n;
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
                      _err = l10n.sysWrongPin;
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
                    tooltip: context.l10n.back,
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

String _humanDuration(AppL10n l10n, Duration d) {
  if (d.inDays > 0) return l10n.durDh(d.inDays, d.inHours % 24);
  if (d.inHours > 0) return l10n.durHm(d.inHours, d.inMinutes % 60);
  if (d.inMinutes > 0) return l10n.durMs(d.inMinutes, d.inSeconds % 60);
  return l10n.durSecs(d.inSeconds);
}

String _relTime(AppL10n l10n, DateTime t) {
  final now = SatClock.now();
  final future = t.isAfter(now);
  final diff = future ? t.difference(now) : now.difference(t);
  final v = switch (diff) {
    _ when diff.inDays > 365 => l10n.durYears(diff.inDays ~/ 365),
    _ when diff.inDays > 30 => l10n.durMonths(diff.inDays ~/ 30),
    _ when diff.inDays > 0 => l10n.durDays(diff.inDays),
    _ when diff.inHours > 0 => l10n.durHours(diff.inHours),
    _ when diff.inMinutes > 0 => l10n.durMins(diff.inMinutes),
    _ => l10n.durSecs(diff.inSeconds),
  };
  // English needs the marker in front ("in 3h"), Indonesian behind ("3j lagi"),
  // so the whole phrase is the string, not a suffix glued on.
  return future ? l10n.relIn(v) : l10n.relAgo(v);
}

String _isoDate(DateTime t) {
  final y = t.year.toString().padLeft(4, '0');
  final m = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
