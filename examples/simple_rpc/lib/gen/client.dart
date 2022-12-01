import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shorebird/shorebird.dart';

import '../model.dart';

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

  Future<void> sendMessage(Message message) async {
    await post('sendMessage', message.toJson());
  }

  Stream<Message> newMessages() {
    var source = EventSource('$baseUrl/newMessages');
    return source.stream
        .map((event) => Message.fromJson(jsonDecode(event.data)));
  }
}
