import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

// This is a minimal (partial) implementation of:
// https://html.spec.whatwg.org/multipage/server-sent-events.html

// I looked for others, but:
// https://pub.dev/packages/eventsource looks abandoned.
// https://pub.dev/packages/sse doesn't seem designed for this?

// Only implementing part of the event for now:
// https://developer.mozilla.org/en-US/docs/Web/API/EventSource/message_event
class Event {
  final String data;

  const Event(this.data);
}

class EventSource {
  final String url;
  late http.Client _client;
  late StreamController _streamController;
  late Stream stream;

  EventSource(this.url) {
    _connect();
  }

  void _connect() {
    _client = http.Client();
    _streamController = StreamController<Event>();
    var request = http.Request('GET', Uri.parse(url));
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';
    var response = _client.send(request);
    response.asStream().listen((response) {
      response.stream.transform(utf8.decoder).transform(LineSplitter()).listen(
        (line) {
          // A super simple parser since we are only implememting data: above.
          if (line.startsWith('data:')) {
            var data = line.substring(5);
            _streamController.add(Event(data));
          }
        },
      );
    });
    stream = _streamController.stream;
  }
}

// There must be a class that does this in dart:core?
class _ProxySink<T> implements Sink<T> {
  final void Function(T) onAdd;
  final void Function() onClose;
  const _ProxySink({required this.onAdd, required this.onClose});

  @override
  void add(T data) => onAdd(data);
  @override
  void close() => onClose();
}

class EventSourceEncoder extends Converter<Event, List<int>> {
  @override
  List<int> convert(Event input) {
    String payload = convertToString(input);
    List<int> bytes = utf8.encode(payload);
    // bytes = gzip.encode(bytes);
    return bytes;
  }

  String convertToString(Event event) {
    var value = event.data;
    // multi-line values need the field prefix on every line
    value = value.replaceAll("\n", "\ndata:");
    var payload = "data: $value\n";
    payload += "\n";
    return payload;
  }

  @override
  Sink<Event> startChunkedConversion(Sink<List<int>> sink) {
    // inputSink = gzip.encoder.startChunkedConversion(sink);
    var encodedSink = utf8.encoder.startChunkedConversion(sink);
    // There must be a stdlib class to do this?
    // Maybe StreamController?
    return _ProxySink(
      onAdd: (event) => encodedSink.add(convertToString(event)),
      onClose: () => encodedSink.close(),
    );
  }
}
