/// This file is used by Shorebird codegen to generate the server code.
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart' as shelf_router;

import 'handler.dart';

/// Used by Shorebird codegen handle centralized server logic.
class Server {
  late final HttpServer server;

  // FIXME: These are kinda hacky, they can't be called until serve is
  // called and only if serve was awaited.

  /// The port the server is listening on.
  /// It is only valid to call this after calling [serve].
  int get port => server.port;

  /// The address the server is listening on.
  /// It is only valid to call this after calling [serve].
  InternetAddress get address => server.address;

  /// Starts the server.
  Future<void> serve(List<Handler> handlers) async {
    final router = shelf_router.Router();
    for (var handler in handlers) {
      router.add(handler.method, handler.path, handler.onRequest);
    }

    final port =
        int.tryParse(Platform.environment['SHOREBIRD_PORT'] ?? '') ?? 3000;

    final handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addMiddleware(corsHeaders())
        .addHandler(router);
    server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

    // Enable content compression
    server.autoCompress = true;
  }
}
