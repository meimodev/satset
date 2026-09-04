import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/server/routes/update_routes.dart';
import 'package:satset/server/update_mirror.dart';

/// The [[Salinan APK]] (ADR-0131). Two things are worth pinning: the version is
/// the filename (so nothing has to keep a metadata file in step), and a
/// mismatch answers 404 rather than "an APK" — the client's GitHub fallback
/// hangs off that 404, and a host that quietly served the wrong release would
/// be discovered at install time on the device.
void main() {
  late Directory dir;
  late UpdateMirror mirror;
  late Handler handler;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('satset-mirror-test');
    mirror = UpdateMirror(directory: dir);
    handler = updateRoutes(mirror).call;
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<Response> get(String query) =>
      Future.value(handler(Request('GET', Uri.parse('http://h/update/apk$query'))))
          .then((r) => r);

  test('the filename is the version, and load re-derives it', () async {
    expect(mirror.heldVersion, isNull);
    await File('${dir.path}/satset-mirror-1.0.9.apk').writeAsBytes([1, 2, 3]);
    await mirror.load();
    expect(mirror.heldVersion, '1.0.9');
  });

  test('a half-written .part is not a held version', () async {
    await File('${dir.path}/satset-mirror-1.0.9.apk.part').writeAsBytes([1]);
    await mirror.load();
    expect(mirror.heldVersion, isNull);
  });

  test('serves the release it holds', () async {
    await File('${dir.path}/satset-mirror-1.0.9.apk').writeAsBytes([1, 2, 3, 4]);
    await mirror.load();

    final res = await get('?v=1.0.9');
    expect(res.statusCode, 200);
    expect(res.headers['content-type'], UpdateMirror.apkMime);
    expect(res.headers['content-length'], '4');
    expect(await res.read().expand((c) => c).toList(), [1, 2, 3, 4]);
  });

  test('404s a version it does not hold, so the client falls back', () async {
    await File('${dir.path}/satset-mirror-1.0.9.apk').writeAsBytes([1]);
    await mirror.load();
    expect((await get('?v=1.0.8')).statusCode, 404);
    expect((await get('?v=2.0.0')).statusCode, 404);
  });

  test('404s when it holds nothing at all', () async {
    await mirror.load();
    expect((await get('?v=1.0.9')).statusCode, 404);
  });

  test('a missing v is a bad request, never a guess', () async {
    await File('${dir.path}/satset-mirror-1.0.9.apk').writeAsBytes([1]);
    await mirror.load();
    expect((await get('')).statusCode, 400);
    expect((await get('?v=')).statusCode, 400);
  });

  test('ensure does not pull for a host already at or past latest', () async {
    // No network stub anywhere in this test: if the guard were wrong, the pull
    // would run and this would either hang or leave a file behind.
    await mirror.ensure('1.0.8', '1.0.8');
    await mirror.ensure('1.0.7', '1.0.8');
    await mirror.ensure(null, '1.0.8');
    await mirror.ensure('nonsense', '1.0.8');
    expect(mirror.heldVersion, isNull);
    expect(dir.listSync(), isEmpty);
  });
}
