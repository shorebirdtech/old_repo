import 'dart:async';

import 'package:simple_rpc/model.dart';
import 'package:simple_rpc/src/gen/client.dart';

/// This example demonstrates making RPC calls to a server via Shorebird.
/// Client is a generated class that implements the RPC interface.
/// All methods on Client are async as they make HTTP calls.
///
/// See lib/src/gen for the generated code.
/// See lib/endpoints.dart for the endpoint definitions.
/// See lib/model.dart for the data model.
void main(List<String> arguments) async {
  var baseUrl = arguments.isNotEmpty ? arguments[0] : 'http://localhost:3000/';
  var client = Client(baseUrl: baseUrl);

  // Subscribe to a stream from the server for messages.
  var subscription = client.newMessages().listen((message) {
    print('Received message: ${message.content} at ${message.time}');
  });

  // Send a message with a class and a primitive that returns a custom type.
  var id = await client.sendMessage(
      Message('Original text.', DateTime.now()), "red");
  await client.changeMessageText(id, "New text!");

  // Send a list of messages and get a list of ids back.
  var ids = await client.sendMessages([
    Message('Message 1', DateTime.now()),
    Message('Message 2', DateTime.now()),
  ]);
  print("Sent two messages, got back: $ids");

  // Send a message with an optional parameter.
  var three = await client.addWithOptional(1, 2);
  print("1 + 2 = $three");
  var six = await client.addWithOptional(1, 2, 3);
  print("1 + 2 + 3 = $six");

  // Send named parameters.
  var decimal = await client.toRadixString(255);
  print("255 in decimal is $decimal");
  var binary = await client.toRadixString(255, base: 2);
  print("255 in binary is $binary");
  var hex = await client.toRadixString(255, base: 16);
  print("255 in hex is $hex");
  var hello = await client.getHelloString(name: "Bob");
  print(hello);

  // Post a message to the server every N seconds.
  Timer.periodic(
    Duration(seconds: 1),
    (Timer t) {
      client.sendMessage(
          Message('Periodic Message #${t.tick}', DateTime.now()), "blue");
      if (t.tick >= 5) {
        t.cancel();
        // Also stop listening for new messages so main can exit.
        subscription.cancel();
      }
    },
  );
  // Does not ever exit, not sure why?  (This is a bug.)
  // Eventually there is an error on the listen stream and the client exits.
}
