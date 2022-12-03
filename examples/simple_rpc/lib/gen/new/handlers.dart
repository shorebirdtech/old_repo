import 'dart:core';

import 'package:shorebird/handler.dart';
import 'package:simple_rpc/model.dart';

import '../../endpoints.dart';

List<Handler> allHandlers = <Handler>[
  Handler.simpleCall(
    'sendMessage',
    (
      context,
      json,
    ) async =>
        await sendMessage(
      context,
      Message.fromJson((json['message'] as Map<String, dynamic>)),
      (json['stampColor'] as String),
    ),
  ),
  Handler.stream(
    'newMessages',
    (
      context,
      json,
    ) =>
        newMessages(context).asyncMap((element) => element.toJson()),
  ),
];
