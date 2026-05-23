import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router healthRoutes() {
  final r = Router();
  r.get('/healthz', (Request req) {
    return Response.ok(
      jsonEncode({'status': 'ok', 'service': 'satset'}),
      headers: {'content-type': 'application/json'},
    );
  });
  return r;
}
