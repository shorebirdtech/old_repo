/// This file is used by Shorebird codegen to generate code used to
/// plumb requests from the network to the [Endpoint]s.
import 'package:shelf/shelf.dart' as shelf;
import 'package:shorebird/src/handlers/eventsource_handler.dart';
import 'package:shorebird/src/handlers/simple_call.dart';

import 'shorebird.dart';

/// Used by Shorebird codgen to return a response from a handler.
class Response {
  Map<String, dynamic> responseJson;

  Response.ok() : responseJson = {};
  Response.primitive(dynamic value) : responseJson = {'result': value};
  Response.json(Map<String, dynamic> json) : responseJson = {'result': json};
}

/// Used by Shorebird codegen to register handlers for endpoints.
class Handler {
  final String path;
  final shelf.Handler onRequest;
  final String method;
  Handler({
    required this.path,
    required this.onRequest,
    this.method = 'POST',
  });

  /// Creates a handler that can be used to handle a request to a
  /// [Future<T>] [Endpoint].
  factory Handler.simpleCall(
      String path,
      Future<Response> Function(
              RequestContext context, Map<String, dynamic> body)
          onRequest) {
    return Handler(
      path: path,
      onRequest: simpleCall(onRequest),
    );
  }

  /// Creates a handler that can be used to handle a request to a
  /// [Stream<T>] [Endpoint]
  factory Handler.stream(
      String path,
      Stream<Map<String, dynamic>> Function(
              RequestContext context, Map<String, dynamic> body)
          createJsonStream) {
    return Handler(
      path: path,
      onRequest: eventSourceHandler(createJsonStream: createJsonStream),
    );
  }
}
