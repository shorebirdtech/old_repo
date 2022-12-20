/// This file is used by Shorebird codegen to generate the server code.
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart' as shelf_router;

import 'handler.dart';

/// An exception that can be thrown by the user's code and will be caught by the
/// exception handler middleware.  Subclass this to create your own exceptions.
/// All other exceptions will be caught and a generic 500 will be returned.
class ShorebirdException implements Exception {
  final String message;
  final int status;

  const ShorebirdException(this.message, {this.status = 500});

  @override
  String toString() => 'ShorebirdException: $message';
}

// Eventually this needs to be more dynamic and detect based on the request
// type what sort of response to return.
// Shorebird of course can be opinionated, as this is a detail that the
// developers won't see.
shelf.Middleware exceptionHandler() {
  return (shelf.Handler handler) {
    return (shelf.Request request) {
      return Future.sync(() => handler(request))
          .then((response) => response)
          .catchError((Object error, StackTrace stackTrace) {
        print("Error: $error, $stackTrace");
        // Make sure this is an exception which is OK to expose to the user.
        // If it is not, return something generic, like a 500.
        // If it is, return the error message formatted in a way
        // that the client can understand (ideally based on request headers).
        if (error is! ShorebirdException) {
          return shelf.Response.internalServerError(
              body: 'Internal Server Error');
        }
        return shelf.Response(
          error.status,
          body: {'message': error.message},
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        );
      },
              // test is important to avoid catching HijackExceptions
              // which are used by Shelf for control flow.
              test: (error) =>
                  error is Exception && error is! shelf.HijackException);
    };
  };
}

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

    // I'm not sure if the exceptionHandler is working? the
    // logRequests might be swallowing the errors instead?
    final handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addMiddleware(corsHeaders())
        .addMiddleware(exceptionHandler())
        .addHandler(router);
    server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

    // Enable content compression
    server.autoCompress = true;
  }
}
