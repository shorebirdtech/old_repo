// This file wil be generated.
import 'package:shorebird/handler.dart';

import '../endpoints.dart';
import '../model.dart';

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

final allHandlers = [
  Handler.simpleCall(
    'sendMessage',
    (context, body) async {
      var args = SendMessageArgs.fromJson(body);
      await sendMessage(context, args.message, args.stampColor);
    },
  ),
  Handler.stream(
    'newMessages',
    (context) => newMessages(context).asyncMap((element) => element.toJson()),
  )
];
