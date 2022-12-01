import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

// This is a minimal (partial) implementation of:
// https://html.spec.whatwg.org/multipage/server-sent-events.html

// I looked for others, but:
// https://pub.dev/packages/eventsource looks abandoned, I have a message out ot the author..
// https://pub.dev/packages/sse doesn't seem designed for this?

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
