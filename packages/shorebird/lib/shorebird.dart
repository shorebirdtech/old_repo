import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:shorebird/src/eventsource.dart';

// @Endpoint annotation.
class Endpoint {
  const Endpoint();
}

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

// Not sure if this is the correct abstraction.
class Client {
  final String baseUrl;

  Client({this.baseUrl = 'http://localhost:3000'});

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
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

  Stream<Map<String, dynamic>> watch(String path) {
    var source = EventSource('$baseUrl/$path');
    return source.stream.map((event) => jsonDecode(event.data));
  }
}
