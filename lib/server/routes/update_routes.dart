import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/server/update_mirror.dart';

/// Serves the **[[Salinan APK]]** to the LAN (ADR-0131).
///
/// **Unauthenticated, like `/healthz`.** Two reasons, and the second is the one
/// that settles it: a blocked device may be sitting at the PIN screen with no
/// session to present, and the body is a byte-identical copy of a file already
/// published at a public GitHub URL. There is no secret here, and a bearer
/// would only refuse a stranger a download they could fetch from github.com
/// anyway. It is in the middleware's skip set rather than a route that cannot
/// identify its caller — ADR-0102 is untouched — and it is deliberately **not**
/// mounted on the cleartext guest plane (ADR-0105).
///
/// The `v` query is the handshake. A host that holds a different release
/// answers 404 and the client falls back to GitHub, which is why nothing here
/// tries to be helpful about near-misses.
Router updateRoutes(UpdateMirror mirror) {
  final r = Router();

  r.get('/update/apk', (Request req) async {
    final want = req.url.queryParameters['v']?.trim() ?? '';
    if (want.isEmpty) return Response(400, body: 'v required');

    final file = await mirror.fileFor(want);
    if (file == null) return Response.notFound('no mirror for $want');

    final length = await file.length();
    return Response.ok(
      file.openRead(),
      headers: {
        'content-type': UpdateMirror.apkMime,
        'content-length': '$length',
      },
    );
  });

  return r;
}
