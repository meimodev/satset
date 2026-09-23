import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/server/server.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';

/// Visible only on the device actually hosting. Denied permissions never stop
/// LAN service; the banner explains which screen-off protection is missing.
class ServerPowerSetup extends ConsumerStatefulWidget {
  const ServerPowerSetup({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ServerPowerSetup> createState() => _ServerPowerSetupState();
}

class _ServerPowerSetupState extends ConsumerState<ServerPowerSetup> {
  late final AppLifecycleListener _lifecycle;
  bool? _exempt;
  bool _notifications = true;
  bool _busy = false;
  bool _failed = false;

  bool get _hosting =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      ref.read(serverRuntimeProvider) != null;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    ref.listenManual(serverRuntimeProvider, (_, next) {
      if (next != null) unawaited(_refresh());
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!_hosting) return;
    try {
      final exempt = await Permission.ignoreBatteryOptimizations.isGranted;
      final notifications = await Permission.notification.isGranted;
      if (!mounted) return;
      setState(() {
        _exempt = exempt;
        _notifications = notifications;
        _failed = false;
      });
    } catch (e, st) {
      SatLog.err('server.power', e, st);
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _configure() async {
    setState(() => _busy = true);
    try {
      if (!_hosting) return;
      if (!await Permission.ignoreBatteryOptimizations.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
      if (!mounted || !_hosting) return;
      final notification = await Permission.notification.status;
      if (notification.isPermanentlyDenied) {
        await openAppSettings();
      } else if (!notification.isGranted) {
        await Permission.notification.request();
      }
      await _refresh();
    } catch (e, st) {
      SatLog.err('server.power.setup', e, st);
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(serverRuntimeProvider);
    final show =
        _hosting &&
        (_failed || (_exempt != null && (!_exempt! || !_notifications)));
    final sc = context.sat;
    return Column(
      children: [
        if (show)
          Material(
            color: sc.bg1,
            child: Padding(
              padding: const EdgeInsets.all(Sp.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _failed
                        ? context.l10n.serverPowerFailed
                        : _exempt != true
                        ? context.l10n.serverPowerBody
                        : context.l10n.serverNotificationsBody,
                    style: SatType.bodyM(color: sc.textHi),
                  ),
                  const SizedBox(height: Sp.s2),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: SatButton.outline(
                      label: context.l10n.serverPowerAction,
                      busy: _busy,
                      onTap: _configure,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
