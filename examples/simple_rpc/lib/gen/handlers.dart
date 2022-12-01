import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shorebird/shorebird.dart';

import '../endpoints.dart';
import '../model.dart';

var allHandlers = <ShorebirdHandler>[
  MessageHandler(MessageEndpoint()),
];

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

    router.addRoute(
        '/newMessages',
        eventSourceHandler(
            createJsonStream: () =>
                endpoint.newMessages().asyncMap((element) => element.toJson())),
        method: 'GET');
  }
}
