import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:satset/core/log/sat_log.dart';

/// The download the website already links to. Stable by construction — GitHub
/// resolves `/latest/` to whatever the newest release holds — so the app never
/// has to be told a URL and a rolled-back release fixes every device at once.
const satsetApkUrl =
    'https://github.com/meimodev/satset/releases/latest/download/satset.apk';

/// Where the install flow has got to. One value, because the UI shows one line.
sealed class UpdateInstall {
  const UpdateInstall();
}

class UpdateIdle extends UpdateInstall {
  const UpdateIdle();
}

class UpdateDownloading extends UpdateInstall {
  /// 0–100, or null while the server is not reporting a content length.
  final int? percent;
  const UpdateDownloading(this.percent);
}

class UpdateOpening extends UpdateInstall {
  const UpdateOpening();
}

class UpdateFailed extends UpdateInstall {
  const UpdateFailed();
}

/// Android refused `REQUEST_INSTALL_PACKAGES`. Distinct from [UpdateFailed]
/// because the fix is a settings toggle, not a retry.
class UpdateNeedsPermission extends UpdateInstall {
  const UpdateNeedsPermission();
}

/// Downloads the release APK and hands it to Android's package installer
/// (ADR-0087).
///
/// **Only ever driven from the Main Device.** SatSet is distributed by hand, so
/// updating a device means a person holding it; a staff phone that could
/// install would need "install unknown apps" on every handset in the venue to
/// serve a case that is rare by construction.
///
/// No signature check of our own: the download is HTTPS from GitHub and Android
/// verifies the APK signature at install. A second check here would be
/// ceremony, and one we could not do better than the platform.
class AppUpdateService extends StateNotifier<UpdateInstall> {
  AppUpdateService() : super(const UpdateIdle());

  Future<void> downloadAndInstall() async {
    if (state is UpdateDownloading || state is UpdateOpening) return;
    state = const UpdateDownloading(null);
    try {
      // Asked before the download, not after: a 60 MB pull that ends at a
      // permission dialog the operator declines is 60 MB wasted, and they are
      // holding the device right now.
      final granted = await Permission.requestInstallPackages.request();
      if (!granted.isGranted) {
        state = const UpdateNeedsPermission();
        return;
      }

      final file = await _download();
      state = const UpdateOpening();
      final res = await OpenFilex.open(file.path, type: _apkMime);
      if (res.type != ResultType.done) {
        SatLog.err('update install ${res.type} ${res.message}');
        state = const UpdateFailed();
        return;
      }
      // Left at "opening": from here the platform installer owns the screen,
      // and success means this process is replaced.
    } catch (e, st) {
      SatLog.err('update download', e, st);
      state = const UpdateFailed();
    }
  }

  void reset() => state = const UpdateIdle();

  static const _apkMime = 'application/vnd.android.package-archive';

  Future<File> _download() async {
    // Cache dir, not app support: the APK is throwaway the moment the installer
    // has it, and open_filex's bundled FileProvider already exposes cache-path.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/satset-update.apk');

    final client = http.Client();
    try {
      final res = await client.send(http.Request('GET', Uri.parse(satsetApkUrl)));
      if (res.statusCode != 200) {
        throw HttpException('APK ${res.statusCode}');
      }
      final total = res.contentLength;
      var received = 0;
      var lastPct = -1;
      final sink = file.openWrite();
      try {
        await for (final chunk in res.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total == null || total == 0) continue;
          final pct = (received * 100 ~/ total).clamp(0, 100);
          // Only on a whole percent: a setState per 8 KB chunk is a rebuild
          // storm behind a progress bar nobody can read that fast.
          if (pct != lastPct) {
            lastPct = pct;
            state = UpdateDownloading(pct);
          }
        }
      } finally {
        await sink.close();
      }
      return file;
    } finally {
      client.close();
    }
  }
}

final appUpdateServiceProvider =
    StateNotifierProvider<AppUpdateService, UpdateInstall>(
      (_) => AppUpdateService(),
    );
