import 'dart:async';

import 'package:simple_rpc/gen/client.dart';
import 'package:simple_rpc/model.dart';

// This should be able to make an RPC call to the server
// With auto-generated client and transport code.

void main(List<String> arguments) {
  var client = Client();

  // Subscribe to a stream from the server for messages.
  client.newMessages().listen((message) {
    print('Received message: ${message.message} at ${message.time}');
  });

  // Post a message to the server every N seconds.
  Timer.periodic(
    Duration(seconds: 1),
    (Timer t) {
      client.sendMessage(
        Message('Hello, ${t.tick}!', DateTime.now()),
      );
      if (t.tick >= 5) {
        t.cancel();
      }
    },
  );
}
