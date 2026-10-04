import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/repositories/release_gate_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/services/app_update_service.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

/// Shared host warning for the route dialog and the blocked screen.
String hostUpdateWarningBody(BuildContext context, WidgetRef ref) {
  final live = ref
      .read(tablesProvider)
      .where((t) => t.status != TableStatus.available)
      .length;
  return live > 0
      ? context.l10n.updateHostWarnBodyLive(live)
      : context.l10n.updateHostWarnBody;
}

/// Starts an update from the shell banner, blocked screen or `/me` version line.
/// A host install stops the embedded server, so the host must confirm first.
/// The blocked screen sits above Navigator and shows that confirmation inline;
/// it passes [hostConfirmed] after the operator accepts the warning.
Future<void> startUpdate(
  BuildContext context,
  WidgetRef ref, {
  bool hostConfirmed = false,
}) async {
  if (ref.read(isHostDeviceProvider) && !hostConfirmed) {
    final ok = await showSatDialog<bool>(
      context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.updateHostWarnTitle),
        content: Text(hostUpdateWarningBody(context, ref)),
        actions: [
          SatButton.ghost(
            label: context.l10n.cancel,
            onTap: () => Navigator.pop(ctx, false),
          ),
          SatButton.primary(
            label: context.l10n.updateAction,
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }
  await ref.read(appUpdateServiceProvider.notifier).downloadAndInstall();
}
