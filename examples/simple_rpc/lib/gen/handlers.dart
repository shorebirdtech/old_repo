import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shorebird/shorebird.dart';

import '../endpoints.dart';
import '../model.dart';

final allHandlers = <ShorebirdHandler>[
  MessageHandler(),
];

// Wholly generated
class SendMessageArgs {
  final Message message;
  final String stampColor;
  SendMessageArgs(this.message, this.stampColor);

  factory SendMessageArgs.fromJson(Map<String, dynamic> json) {
    return SendMessageArgs(
      Message.fromJson(json['message'] as Map<String, dynamic>),
      json['stampColor'] as String,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'message': message.toJson(),
      'stampColor': stampColor,
    };
  }
}

class MessageHandler extends ShorebirdHandler {
  @override
  void collectRoutes(Router router) {
    router.addRoute('/sendMessage', (shelf.Request request) async {
      // Decode as args.
      var args =
          SendMessageArgs.fromJson(jsonDecode(await request.readAsString()));
      // Then send the args to the message.
      await sendMessage(RequestContext(), args.message, args.stampColor);
      // Then reply with the result.
      return shelf.Response.ok('OK');
    });

  // Special case when return type is Stream<T>
    router.addRoute(
        '/newMessages',
        eventSourceHandler(
            createJsonStream: () => newMessages(RequestContext())
                .asyncMap((element) => element.toJson())));
  }
}
