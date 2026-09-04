import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/domain/models/release_gate.dart';

/// The **[[Salinan APK]]** — the host's cached copy of the release APK, served
/// to the LAN so a client with no internet can still update (ADR-0131).
///
/// **Prefetched, not fetched on demand.** The entire reason to mirror is a
/// venue whose uplink is down; a cache that only fills when somebody asks is
/// empty in exactly that case. [ensure] runs whenever the gate's `latest`
/// passes this host's own version.
///
/// **Application support, not the cache directory.** The client's own
/// download-and-install-now file is throwaway the instant the installer has it
/// and correctly lives in the cache. This one has to still be there weeks
/// later, and Android evicts cache dirs under storage pressure without asking
/// — on the tablet whose venue is already in trouble.
///
/// The version it holds is **the filename**, so a restart re-derives it with no
/// metadata file to keep in step. One release at a time: every other mirror is
/// deleted on each successful pull.
class UpdateMirror {
  /// [directory] overrides the app support dir — the tests hand it a temp dir
  /// so the route and the filename-is-the-version rule can be exercised
  /// without a platform channel.
  UpdateMirror({Directory? directory}) : _dir = directory;

  static const _prefix = 'satset-mirror-';
  static const _suffix = '.apk';
  static const apkMime = 'application/vnd.android.package-archive';

  Directory? _dir;
  String? _held;
  bool _busy = false;

  /// The version on disk, or null. Null until [load] has run.
  String? get heldVersion => _held;

  /// Re-derive what survived the last process. Cheap; called once at boot.
  Future<void> load() async {
    try {
      final dir = await _directory();
      String? found;
      await for (final e in dir.list()) {
        final v = _versionOf(e);
        if (v != null) found = v;
      }
      _held = found;
      if (found != null) SatLog.srv('update mirror holds $found');
    } catch (e, st) {
      SatLog.err('update mirror load', e, st);
    }
  }

  /// Pull [latest] if this host is behind it and does not already hold it.
  ///
  /// Best-effort and silent: the mirror is a convenience for the LAN, and a
  /// venue with no internet must not see an error about a file it was never
  /// going to get. Re-entrant calls are dropped rather than queued — the gate
  /// listener re-fires on unrelated document metadata.
  Future<void> ensure(String? latest, String installed) async {
    if (_busy) return;
    if (latest == null || parseVersion(latest) == null) return;
    // Nothing to mirror for a build this host is already at or past. The
    // comparison is against the *host's* version deliberately: the mirror
    // exists for clients, but a host that is current is a host whose venue has
    // already updated, and holding 60 MB for nobody is not a service.
    if (compareVersions(installed, latest) >= 0) return;
    if (_held == latest && await _fileFor(latest).exists()) return;

    _busy = true;
    try {
      final file = await _pull(latest);
      _held = latest;
      await _sweepExcept(file);
      SatLog.srv('update mirror ← $latest (${await file.length()} bytes)');
    } catch (e, st) {
      SatLog.err('update mirror pull $latest', e, st);
    } finally {
      _busy = false;
    }
  }

  /// The mirrored file for [version], or null when this host holds a different
  /// one. The route 404s on null and the client falls back to GitHub.
  Future<File?> fileFor(String version) async {
    if (_held != version) return null;
    final f = _fileFor(version);
    return await f.exists() ? f : null;
  }

  Future<Directory> _directory() async =>
      _dir ??= await getApplicationSupportDirectory();

  File _fileFor(String version) =>
      File('${_dir!.path}/$_prefix$version$_suffix');

  static String? _versionOf(FileSystemEntity e) {
    final name = e.uri.pathSegments.last;
    if (!name.startsWith(_prefix) || !name.endsWith(_suffix)) return null;
    final v = name.substring(_prefix.length, name.length - _suffix.length);
    return parseVersion(v) == null ? null : v;
  }

  /// Download to `.part` and rename on completion, so the route can never hand
  /// a client half a file. A rename inside one directory is atomic.
  Future<File> _pull(String version) async {
    await _directory();
    final target = _fileFor(version);
    final part = File('${target.path}.part');
    if (await part.exists()) await part.delete();

    final client = http.Client();
    try {
      final res = await client.send(http.Request('GET', Uri.parse(satsetApkUrl)));
      if (res.statusCode != 200) throw HttpException('APK ${res.statusCode}');
      final sink = part.openWrite();
      try {
        await res.stream.pipe(sink);
      } finally {
        await sink.close();
      }
      return part.rename(target.path);
    } finally {
      client.close();
    }
  }

  /// One release at a time. Also sweeps stranded `.part` files from a pull that
  /// died with the process.
  Future<void> _sweepExcept(File keep) async {
    final dir = await _directory();
    await for (final e in dir.list()) {
      if (e.path == keep.path) continue;
      final name = e.uri.pathSegments.last;
      if (!name.startsWith(_prefix)) continue;
      try {
        await e.delete();
      } catch (_) {
        // A file we cannot delete costs disk, not correctness.
      }
    }
  }
}
