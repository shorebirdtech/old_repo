// Generated by `dart run shorebird generate`.
import 'dart:async';
import 'dart:core';

import 'package:shorebird/datastore.dart';
import 'package:shorebird/shorebird.dart';
import 'package:simple_rpc/model.dart';

import 'handlers.dart';

export 'package:shorebird/shorebird.dart' show Client;

extension HandlerExtensions on Client {
  Future<ObjectId> sendMessage(
    Message message,
    String stampColor,
  ) {
    final body = SendmessageArgs(
      message,
      stampColor,
    ).toJson();
    return post(
      '/sendMessage',
      body,
    ).then(extractResponse<String>).then(ObjectId.fromHexString);
  }

  Future<void> changeMessageText(
    ObjectId messageId,
    String messageText,
  ) {
    final body = ChangemessagetextArgs(
      messageId,
      messageText,
    ).toJson();
    return post(
      '/changeMessageText',
      body,
    );
  }

  Stream<Message> newMessages() {
    return watch('/newMessages').map(Message.fromJson);
  }
}
