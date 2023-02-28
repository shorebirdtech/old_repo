import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:updater_server/config.dart';
import 'package:updater_server/deploy.dart';
import 'package:updater_server/updater.dart';
import 'package:updater_server/version_store.dart';

void main() async {
// Should take a request to /updater and return a response with the latest version information.
// e.g. input: {"version": "1.0.0", "hash": "abc", "platform": "windows", "arch": "x64", "client_id": "123"}
// response: {"needs_update": true, "version": { version: "1.0.1", "hash": "xyz", "url": "http://localhost:8080/releases/1.0.0.txt"}}

  VersionStore.initShared(config.cachePath);

  var router = Router();
  router.post('/updater', updaterHandler);
  router.get('/releases/<version>',
      (Request request, String versionWithExtension) {
    var version = p.withoutExtension(versionWithExtension);
    var datastore = VersionStore.shared();
    var path = datastore.filePathForVersion(version);
    var bytes = File(path).openRead();
    return Response.ok(bytes);
  });
  router.post('/deploy', uploadHandler);

  var handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  var server = await shelf_io.serve(handler, 'localhost', 8080);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
}
