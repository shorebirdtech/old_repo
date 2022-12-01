import 'package:shorebird/shorebird.dart';

import '../model.dart';

export 'package:shorebird/shorebird.dart' show Client;

extension SimpleRPCClient on Client {
  Future<void> sendMessage(Message message) async {
    await post('sendMessage', message.toJson());
  }

  Stream<Message> newMessages() {
    return watch('newMessages').map((value) => Message.fromJson(value));
  }
}
