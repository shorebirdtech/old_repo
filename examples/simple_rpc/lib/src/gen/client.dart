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
    final body = SendMessageArgs(
      message,
      stampColor,
    ).toJson();
    return post(
      '/sendMessage',
      body,
    ).then(extractResponse<String>).then((e) {
      return ObjectId.fromHexString(e);
    });
  }

  Future<List<ObjectId>> sendMessages(List<Message> messages) {
    final body = SendMessagesArgs(messages).toJson();
    return post(
      '/sendMessages',
      body,
    ).then(extractResponse<List>).then((e) {
      return e.map<ObjectId>((e) {
        return ObjectId.fromHexString(e);
      }).toList();
    });
  }

  Future<int> addWithOptional(
    int a,
    int b, [
    int c = 0,
  ]) {
    final body = AddWithOptionalArgs(
      a,
      b,
      c,
    ).toJson();
    return post(
      '/addWithOptional',
      body,
    ).then(extractResponse<int>).then((e) {
      return e;
    });
  }

  Future<String> toRadixString(
    int value, {
    int base = 10,
  }) {
    final body = ToRadixStringArgs(
      value,
      base: base,
    ).toJson();
    return post(
      '/toRadixString',
      body,
    ).then(extractResponse<String>).then((e) {
      return e;
    });
  }

  Future<String> getHelloString({required String name}) {
    final body = GetHelloStringArgs(name: name).toJson();
    return post(
      '/getHelloString',
      body,
    ).then(extractResponse<String>).then((e) {
      return e;
    });
  }

  Future<List<Message>> allMessagesSince(DateTime since) {
    final body = AllMessagesSinceArgs(since).toJson();
    return post(
      '/allMessagesSince',
      body,
    ).then(extractResponse<List>).then((e) {
      return e.map<Message>((e) {
        return Message.fromJson(e);
      }).toList();
    });
  }

  Future<void> changeMessageText(
    ObjectId messageId,
    String messageText,
  ) {
    final body = ChangeMessageTextArgs(
      messageId,
      messageText,
    ).toJson();
    return post(
      '/changeMessageText',
      body,
    );
  }

  Stream<Message> newMessages() {
    return watch('/newMessages').map((e) {
      return Message.fromJson(e);
    });
  }
}