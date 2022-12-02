import 'package:shorebird/shorebird.dart';
import 'package:simple_rpc/gen/handlers.dart';

import '../model.dart';

export 'package:shorebird/shorebird.dart' show Client;

extension SimpleRPCClient on Client {
  Future<void> sendMessage(Message message, String stampColor) {
    return post('sendMessage', SendMessageArgs(message, stampColor).toJson());
  }

  Stream<Message> newMessages() {
    return watch('newMessages').map((value) => Message.fromJson(value));
  }
}
