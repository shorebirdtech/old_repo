import 'package:shelf/shelf.dart' as shelf;
import 'package:shorebird/src/handlers/eventsource_handler.dart';
import 'package:shorebird/src/handlers/simple_call.dart';

import 'shorebird.dart';

// Move to a code-gen internal "handlers.dart" include instead.
class Handler {
  final String path;
  final shelf.Handler onRequest;
  final String method;
  Handler({
    required this.path,
    required this.onRequest,
    this.method = 'POST',
  });

  factory Handler.simpleCall(
      String path,
      Future<void> Function(RequestContext context, Map<String, dynamic> body)
          onRequest) {
    return Handler(
      path: path,
      onRequest: simpleCall(onRequest),
    );
  }

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
