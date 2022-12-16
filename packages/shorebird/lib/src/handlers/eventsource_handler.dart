import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shorebird/shorebird.dart';

import '../eventsource.dart';

/// Creates a handler that can be used to handle a request to a
/// [Stream<T>] [Endpoint]
/// The [createJsonStream] function is called to create the stream.
/// The [RequestContext] is passed to the function so that it can be used
/// to look up the current session, etc.
/// This intentionally uses EventSource (e.g. Server-Sent Events) instead of
/// WebSockets because it is simpler and more widely supported at the
/// network layer.
shelf.Handler eventSourceHandler({
  required Stream<Map<String, dynamic>> Function(
          RequestContext context, Map<String, dynamic> body)
      createJsonStream,
}) {
  return (shelf.Request request) async {
    Stream stream = createJsonStream(
        RequestContext(), jsonDecode(await request.readAsString()));

    request.hijack((channel) {
      // Is there a better way to write these headers?
      var sink = utf8.encoder.startChunkedConversion(channel.sink);
      sink.add("HTTP/1.1 200 OK\r\n");
      sink.add("Content-Type: text/event-stream; charset=utf-8\r\n");
      sink.add("Cache-Control: no-cache, no-store, must-revalidate\r\n");
      sink.add("Connection: keep-alive\r\n");
      // sink.add("Content-Encoding: gzip\r\n");
      sink.add("\r\n");

      var eventSink = EventSourceEncoder().startChunkedConversion(channel.sink);
      // Unclear if the onDone and onError callbacks are necessary?
      stream.listen((json) {
        eventSink.add(Event(jsonEncode(json)));
      }, onDone: () {
        eventSink.close();
      }, onError: (error) {
        eventSink.close();
      });
    });
  };
}
