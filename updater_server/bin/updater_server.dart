import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

void main() async {
// Should take a request to /updater and return a response with the latest version information.
// e.g. input: {"version": "1.0.0", "hash": "abc", "platform": "windows", "arch": "x64", "client_id": "123"}
// response: {"needs_update": true, "version": "1.0.1", "hash": "xyz", "url": "http://localhost:8080/releases/1.0.0.txt"}

  var router = Router();
  router.post('/updater', (Request request) {
    if (request.url.queryParameters['version'] != '1.0.1') {
      return Response.ok(jsonEncode(<String, dynamic>{
        "needs_update": true,
        "version": "1.0.1",
        "hash": "xyz",
        "url": "http://localhost:8080/releases/1.0.1.txt"
      }));
    }
    return Response.ok(jsonEncode(<String, dynamic>{
      "needs_update": false,
    }));
  });
  router.get('/releases/<version>', (Request request, String version) {
    return Response.ok(version, headers: {'Content-Type': 'text/plain'});
  });

  var handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  var server = await shelf_io.serve(handler, 'localhost', 8080);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
}
