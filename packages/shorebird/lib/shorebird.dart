import 'dart:async';
import 'dart:io';

import "package:eventsource/publisher.dart";
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import "package:shelf_eventsource/shelf_eventsource.dart";
import "package:shelf_router/shelf_router.dart";

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

abstract class ShorebirdHandler {
  void addRoutes(Router router) {}
}

class StreamToEventSource<T> extends EventSourcePublisher {
  // Not clear id or cacheCapacity matter for our use cases.
  final int nextId = 0;
  StreamToEventSource(Stream<T> stream) : super(cacheCapacity: 100) {
    stream.listen((T value) {
      add(Event(id: nextId.toString(), data: value.toString()));
    });
  }
}

Handler streamHandler<T>(Stream<T> stream) {
  return eventSourceHandler(StreamToEventSource(stream));
}

class Server {
  late final HttpServer server;

  // FIXME: These are kinda hacky, they can't be called until serve is
  // called and only if serve was awaited.
  int get port => server.port;
  InternetAddress get address => server.address;

  Future<void> serve(
      List<ShorebirdHandler> endpoints, String host, int port) async {
    var router = Router();
    for (var endpoint in endpoints) {
      endpoint.addRoutes(router);
    }

    var handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(router);
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
