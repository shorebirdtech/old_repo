import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shorebird/shorebird.dart';

shelf.Handler simpleCall(
    Future<void> Function(RequestContext context, Map<String, dynamic> body)
        fn) {
  return (request) async {
    final body = jsonDecode(await request.readAsString());
    await fn(RequestContext(), body);
    return shelf.Response.ok('');
  };
}
