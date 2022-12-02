import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import "package:shelf_router/shelf_router.dart" as shelf_router;
import 'package:shorebird/src/eventsource.dart';

export 'package:shorebird/src/eventsource.dart';
export 'package:shorebird/src/handlers/eventsource_handler.dart';

// @Endpoint annotation.
class Endpoint {
  const Endpoint();
}

class RequestContext {}

// HACK: Make AuthenticatedContext a separate type.
typedef AuthenticatedContext = RequestContext;

// devs will want to store arbitrary data on the session?
class Session {
  factory Session.of(RequestContext context) {
    return Session();
  }

  Session();
}

class Router {
  final shelf_router.Router _router = shelf_router.Router();
  void addRoute(String path, Handler handler, {String method = 'POST'}) {
    _router.add(method, path, handler);
  }

  shelf_router.Router shelfHandler() => _router;
}

abstract class ShorebirdHandler {
  void collectRoutes(Router router);
}

class Server {
  late final HttpServer server;

  // FIXME: These are kinda hacky, they can't be called until serve is
  // called and only if serve was awaited.
  int get port => server.port;
  InternetAddress get address => server.address;

  Future<void> serve(
      List<ShorebirdHandler> endpoints, Object host, int port) async {
    var router = Router();
    for (var endpoint in endpoints) {
      endpoint.collectRoutes(router);
    }

    var handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsHeaders())
        .addHandler(router.shelfHandler());
    server = await shelf_io.serve(handler, host, port);

    // Enable content compression
    server.autoCompress = true;
  }
}

// Not sure if this is the correct abstraction.
class Client {
  final String baseUrl;

  Client({this.baseUrl = 'http://localhost:3000'});

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    var url = Uri.parse('$baseUrl/$path');
    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    var response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('Error: ${response.statusCode} $path ${response.body}');
    }
    return response;
  }

  Stream<Map<String, dynamic>> watch(String path) {
    var source = EventSource('$baseUrl/$path');
    return source.stream.map((event) => jsonDecode(event.data));
  }
}
