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
  // Record the message in the datastore.
  var serverMessage =
      await DataStore.of(context).collection<Message>().create(message);
  return serverMessage.id;
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
    return message.copyWith(message: messageText);
  });
}

// An example returning a stream.
@Endpoint()
Stream<Message> newMessages(AuthenticatedContext context) {
  // Return a stream of messages from the datastore.
  return DataStore.of(context).collection<Message>().watchAdditions();
}
