import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import "package:shelf_router/shelf_router.dart" as shelf_router;

export 'package:shorebird/src/eventsource.dart';
export 'package:shorebird/src/eventsource_handler.dart';

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

abstract class Endpoint {}

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

// Could use https://pub.dev/packages/state_notifier/versions/0.7.0
// But should just be able to use package:flutter/foundation.dart.
class Watchable<T> {
  Watchable(this._value);

  final List<void Function()> _listeners = [];

  T get value => _value;
  T _value;
  set value(T newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    notifyListeners();
  }

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  Stream<T> watch() {
    StreamController<T> controller = StreamController<T>();
    // FIXME: What should this do on pause/resume?
    // https://github.com/dart-lang/sdk/issues/50446
    controller.add(value);

    addListener(() {
      controller.add(value);
    });
    return controller.stream;
  }
}
