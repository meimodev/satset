import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/repositories/release_gate_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/services/app_update_service.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

/// The one way into [AppUpdateService.downloadAndInstall] from the UI.
///
/// Three surfaces start an update — the shell banner, the block screen and the
/// `/me` version line (ADR-0130, ADR-0131) — and exactly one of them must not
/// be able to forget the warning, so none of them calls the service directly.
///
/// **A host install takes the venue down.** Installing replaces the process:
/// the embedded server stops and every client loses its host mid-service. This
/// mirrors the admin sign-out of ADR-0015 — warn, naming the live table count,
/// then proceed. Refusing while tables are live would leave a venue that never
/// closes one unable to comply with a floor, which is the case a floor exists
/// for. A client install takes down only itself and warns about nothing.
Future<void> startUpdate(BuildContext context, WidgetRef ref) async {
  if (ref.read(isHostDeviceProvider)) {
    final live = ref
        .read(tablesProvider)
        .where((t) => t.status != TableStatus.available)
        .length;
    final ok = await showSatDialog<bool>(
      context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.updateHostWarnTitle),
        content: Text(
          live > 0
              ? context.l10n.updateHostWarnBodyLive(live)
              : context.l10n.updateHostWarnBody,
        ),
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
