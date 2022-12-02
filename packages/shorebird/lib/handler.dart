import 'package:shelf/shelf.dart' as shelf;
import 'package:shorebird/src/handlers/eventsource_handler.dart';
import 'package:shorebird/src/handlers/simple_call.dart';

import 'shorebird.dart';

// Move to a code-gen internal "handlers.dart" include instead.
class Handler {
  final String name;
  final shelf.Handler onRequest;
  final String method;
  Handler({
    required this.name,
    required this.onRequest,
    this.method = 'POST',
  });

  factory Handler.simpleCall(
      String name,
      Future<void> Function(RequestContext context, Map<String, dynamic>)
          onRequest) {
    return Handler(
      name: name,
      onRequest: simpleCall(onRequest),
    );
  }

  factory Handler.stream(
      String name,
      Stream<Map<String, dynamic>> Function(RequestContext context)
          createJsonStream) {
    return Handler(
      name: name,
      onRequest: eventSourceHandler(createJsonStream: createJsonStream),
    );
  }
}
