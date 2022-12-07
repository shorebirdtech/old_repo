import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shorebird/handler.dart';
import 'package:shorebird/shorebird.dart';

shelf.Handler simpleCall(
    Future<Response> Function(RequestContext context, Map<String, dynamic> body)
        fn) {
  return (request) async {
    final body = jsonDecode(await request.readAsString());
    var result = await fn(RequestContext(), body);
    return shelf.Response.ok(
      jsonEncode(result.responseJson),
      headers: {'Content-Type': 'application/json'},
    );
  };
}
