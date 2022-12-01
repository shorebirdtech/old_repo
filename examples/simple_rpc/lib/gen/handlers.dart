import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shorebird/shorebird.dart';
import 'package:simple_rpc/gen/storable.dart';

import '../endpoints.dart';
import '../model.dart';

var allHandlers = <ShorebirdHandler>[
  MessageHandler(MessageEndpoint()),
];

class EventSourceEncoder extends Converter<Event, List<int>> {
  @override
  List<int> convert(Event input) {
    String payload = "";
    var value = input.data;
    // multi-line values need the field prefix on every line
    value = value.replaceAll("\n", "\ndata:");
    payload += "data: $value\n";
    payload += "\n";

    List<int> bytes = utf8.encode(payload);
    // bytes = gzip.encode(bytes);
    return bytes;
  }
}

shelf.Handler eventSourceHandler<T>(
    {required Stream<T> Function() createStream}) {
  var stream = createStream();

  return (shelf.Request request) {
    request.hijack((channel) {
      // FIXME: There must be a better way to write these headers?
      var sink = utf8.encoder.startChunkedConversion(channel.sink);
      sink.add("HTTP/1.1 200 OK\r\n");
      sink.add("Content-Type: text/event-stream; charset=utf-8\r\n");
      sink.add("Cache-Control: no-cache, no-store, must-revalidate\r\n");
      sink.add("Connection: keep-alive\r\n");
      // sink.add("Content-Encoding: gzip\r\n");
      sink.add("\r\n");

      // create encoder for this connection
      var eventSink = EventSourceEncoder().startChunkedConversion(channel.sink);

      stream.listen((value) {
        var toJson = classInfoMap[T]!.toJson;
        eventSink.add(Event(jsonEncode(toJson(value))));
      });
    });
  };
}

class MessageHandler extends ShorebirdHandler {
  MessageHandler(this.endpoint);

  final MessageEndpoint endpoint;

  @override
  void collectRoutes(Router router) {
    router.addRoute('/sendMessage', (shelf.Request request) async {
      var message = Message.fromJson(jsonDecode(await request.readAsString()));
      await endpoint.sendMessage(message);
      return shelf.Response.ok('OK');
    });

    router.addRoute('/messages',
        eventSourceHandler(createStream: () => endpoint.newMessages()));
  }
}
