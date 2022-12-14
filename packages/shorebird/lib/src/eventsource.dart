import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

// This is a minimal (partial) implementation of:
// https://html.spec.whatwg.org/multipage/server-sent-events.html

// I consider others, but:
// https://pub.dev/packages/eventsource looks abandoned.
// https://pub.dev/packages/sse isn't designed for general usage, only to
// to act as a fallback when WebSocket is not available.

// Only implementing part of the event for now:
// https://developer.mozilla.org/en-US/docs/Web/API/EventSource/message_event
class Event {
  final String data;

  const Event(this.data);
}

// It's not clear why this is a class and not just a free function.
// I guess you might want it a class to handle reconnects?
class EventSource {
  final Uri uri;
  late http.Client _client;
  late StreamController<Event> _streamController;
  late Stream<Event> stream;

  EventSource.connect(this.uri,
      [Map<String, dynamic> body = const <String, dynamic>{}]) {
    _client = http.Client();
    _streamController = StreamController<Event>();
    // We would only use GET if we wanted to allow the network layer to cache.
    var request = http.Request('POST', uri);
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';
    request.body = jsonEncode(body);
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
// https://github.com/dart-lang/sdk/issues/50607
class _MappedSink<From, To> implements Sink<From> {
  final To Function(From) _transform;
  final Sink<To> _sink;
  const _MappedSink(this._sink, this._transform);

  @override
  void add(From data) => _sink.add(_transform(data));
  @override
  void close() => _sink.close();
}

extension SinkMap<To> on Sink<To> {
  Sink<From> map<From>(To Function(From) transform) =>
      _MappedSink(this, transform);
}

String _convertToString(Event event) {
  var value = event.data;
  // multi-line values need the field prefix on every line
  value = value.replaceAll("\n", "\ndata:");
  var payload = "data: $value\n";
  payload += "\n";
  return payload;
}

class EventSourceEncoder extends Converter<Event, List<int>> {
  @override
  List<int> convert(Event input) {
    String payload = _convertToString(input);
    List<int> bytes = utf8.encode(payload);
    // bytes = gzip.encode(bytes);
    return bytes;
  }

  @override
  Sink<Event> startChunkedConversion(Sink<List<int>> sink) {
    // Not currently doing gzip, on the assumption that whatever
    // reverse proxy is in front of this will do it.
    // inputSink = gzip.encoder.startChunkedConversion(sink);
    var encodedSink = utf8.encoder.startChunkedConversion(sink);
    return encodedSink.map<Event>(_convertToString);
  }
}
