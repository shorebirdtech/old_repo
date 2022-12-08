import 'package:shorebird/annotations.dart';
import 'package:shorebird/datastore.dart';
import 'package:shorebird/shorebird.dart';

import 'model.dart';

// What are the rules of the road for globals?
// Suggestion: Globals are "local" to a given instance of the server.

// Going to need: a coherent memcache + datastore.

// Two arguments, one custom object, one primitive and returns a complex type.
@Endpoint()
Future<ObjectId> sendMessage(
    RequestContext context, Message message, String stampColor) async {
  // stampColor is just to have a second argument.
  // sealed is just to test named arguments.
  // Record the message in the datastore.
  var serverMessage =
      await DataStore.of(context).collection<Message>().create(message);
  return serverMessage.id;
}

// Test sending an receiveing a list.
@Endpoint()
Future<List<ObjectId>> sendMessages(
    RequestContext context, List<Message> messages) async {
  var serverMessages =
      await DataStore.of(context).collection<Message>().createMany(messages);
  return serverMessages.map((m) => m.id).toList();
}

// Test optional parameters.
@Endpoint()
Future<int> addWithOptional(RequestContext context, int a, int b,
    [int c = 0]) async {
  return a + b + c;
}

// Test named parameters.
@Endpoint()
Future<String> toRadixString(RequestContext context, int value,
    {int base = 10}) async {
  return value.toRadixString(base);
}

// Test required parameters.
@Endpoint()
Future<String> getHelloString(RequestContext context,
    {required String name}) async {
  return 'Hello, $name!';
}

// Test returning a list and serializing DateTime.
@Endpoint()
Future<List<Message>> allMessagesSince(
    RequestContext context, DateTime since) async {
  return DataStore.of(context)
      .collection<Message>()
      .find(where.gte('time', since))
      .toList();
}

// An example returning void.
@Endpoint()
Future<void> changeMessageText(
    RequestContext context, ObjectId messageId, String messageText) async {
  return DataStore.of(context).collection<Message>().update(messageId,
      (message) {
    if (message == null) {
      throw ArgumentError('No message with id $messageId');
    }
    return message.copyWith(content: messageText);
  });
}

// An example returning a stream.
@Endpoint()
Stream<Message> newMessages(AuthenticatedContext context) {
  // Return a stream of messages from the datastore.
  return DataStore.of(context).collection<Message>().watchAdditions();
}
