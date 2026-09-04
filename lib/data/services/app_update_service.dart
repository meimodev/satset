import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/repositories/release_gate_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/domain/models/release_gate.dart';

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
/// (ADR-0130, ADR-0131).
///
/// **Every device may drive this** (ADR-0131, reversing ADR-0130's Main-Device
/// rule). Who is *offered* it is decided by the UI: ungated on the block screen,
/// because a device below `min` is out of service and unblocking it is never
/// the wrong act, and `editSettings` on the version line, because a
/// discretionary 60 MB pull and a process restart on a live handset is a
/// manager's call.
///
/// **The host first, GitHub second.** A client asks its own host for the
/// [[Salinan APK]] over the LAN it is already paired to, and falls back to the
/// GitHub Release when the host holds a different version or cannot answer. The
/// mirror is what lets a venue with a dead uplink still update six handsets;
/// the fallback is what stops a host that has not prefetched yet from
/// stranding a device with perfectly good internet.
///
/// No signature check of our own: HTTPS on the way in, and Android refuses an
/// APK signed by a different key over an installed package. That last rule is
/// the actual protection, and it is the reason proxying the bytes through a
/// venue tablet costs nothing — a tampered file cannot replace SatSet, it can
/// only fail to install.
class AppUpdateService extends StateNotifier<UpdateInstall> {
  AppUpdateService(this.ref) : super(const UpdateIdle()) {
    _life = AppLifecycleListener(onResume: _onResume);
  }

  final Ref ref;
  late final AppLifecycleListener _life;

  /// Coming back to the foreground while still alive means the install did not
  /// happen — a successful one replaces this process, so there is nobody here
  /// to resume. The platform installer reports nothing back (see
  /// [downloadAndInstall]), so a declined permission, a tapped Cancel or
  /// Android's own refusal all land here, and without this the retry guard
  /// leaves the button dead until the app is restarted.
  void _onResume() {
    if (mounted && state is UpdateOpening) state = const UpdateIdle();
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

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

      final file = await _download(ref.read(releaseGateProvider).latest);
      state = const UpdateOpening();
      final res = await OpenFilex.open(file.path, type: _apkMime);
      if (res.type != ResultType.done) {
        SatLog.err('update install ${res.type} ${res.message}');
        state = const UpdateFailed();
        return;
      }
      // Left at "opening": from here the platform installer owns the screen,
      // and success means this process is replaced. `done` only says the intent
      // launched — Android never tells us whether the install took — so the
      // way back out is [_onResume], not a result code.
    } catch (e, st) {
      SatLog.err('update download', e, st);
      state = const UpdateFailed();
    }
  }

  void reset() => state = const UpdateIdle();

  static const _apkMime = 'application/vnd.android.package-archive';

  /// Host first when we know which version to ask for, GitHub otherwise and on
  /// any host failure. A host miss is expected traffic, not an error — it 404s
  /// whenever it holds a different release — so it is logged and stepped over.
  Future<File> _download(String? version) async {
    if (version != null && parseVersion(version) != null) {
      final host = _hostSource(version);
      if (host != null) {
        try {
          return await _pull(host.$1, host.$2);
        } catch (e) {
          SatLog.http('update mirror miss ($version): $e');
        }
      }
    }
    return _pull(http.Client(), Uri.parse(satsetApkUrl));
  }

  /// The pinned client and URI for this device's own host, or null when it has
  /// none — an unpaired device, or the host itself, which has no mirror of its
  /// own to ask.
  ///
  /// The pinning is [ApiClient]'s, not a second copy: a self-signed certificate
  /// this device already trusts is exactly what makes a plain `http.Client`
  /// wrong here.
  (http.Client, Uri)? _hostSource(String version) {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return null;
    try {
      final io = ApiClient.buildPinnedHttpClient(
        cfg.trustedFingerprint.toLowerCase(),
        isLoopback: ApiClient.isLoopbackHost(cfg.baseUri.host),
      );
      final uri = cfg.baseUri.replace(
        path: '/update/apk',
        queryParameters: {'v': version},
      );
      return (http_io.IOClient(io), uri);
    } catch (e) {
      // A config with no fingerprint on a non-loopback host throws rather than
      // downgrading the trust. GitHub is the answer, not an unpinned socket.
      SatLog.http('update mirror unusable: $e');
      return null;
    }
  }

  Future<File> _pull(http.Client client, Uri uri) async {
    // Cache dir, not app support: the APK is throwaway the moment the installer
    // has it, and open_filex's bundled FileProvider already exposes cache-path.
    // The host's own [[Salinan APK]] is the opposite case and lives in app
    // support — see `UpdateMirror`.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/satset-update.apk');

    try {
      final res = await client.send(http.Request('GET', uri));
      if (res.statusCode != 200) {
        throw HttpException('APK ${res.statusCode} from ${uri.host}');
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
      AppUpdateService.new,
    );
