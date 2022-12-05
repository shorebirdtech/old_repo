import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shorebird/src/eventsource.dart';

/// Passed to Endpoint functions to allow them to access server resources.
class RequestContext {}

/// Passed to the Endpoint when client has authenticated allowing access to
/// user resources.
// HACK: Make AuthenticatedContext a separate type.
typedef AuthenticatedContext = RequestContext;

// devs will want to store arbitrary data on the session?
class Session {
  factory Session.of(RequestContext context) {
    return Session();
  }

  Session();
}

// Not sure if this is the correct abstraction.
class Client {
  final String baseUrl;

  Client({this.baseUrl = 'http://localhost:3000'});

  /// Post a request to the server.
  Future<http.Response> post(String path,
      [Map<String, dynamic> body = const <String, dynamic>{}]) async {
    var url = Uri.parse('$baseUrl/$path');
    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    var response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('Error: ${response.statusCode} $path ${response.body}');
    }
    return response;
  }

  /// Watch a stream of events from the server.
  Stream<Map<String, dynamic>> watch(String path,
      [Map<String, dynamic> body = const <String, dynamic>{}]) {
    var uri = Uri.parse(baseUrl);
    uri = uri.resolve(path);
    var source = EventSource.connect(uri, body);
    return source.stream.map((event) => jsonDecode(event.data));
  }
}
