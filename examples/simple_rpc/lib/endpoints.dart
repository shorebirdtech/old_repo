import 'package:shorebird/datastore.dart';
import 'package:shorebird/shorebird.dart';

import 'model.dart';

// What are the rules of the road for globals?
// Suggestion: Globals are "local" to a given instance of the server.

// Going to need: a coherent memcache + datastore.

// or @Entrypoint
@Endpoint()
Future<void> sendMessage(
    RequestContext context, Message message, String stampColor) {
  // stampColor is just to have a second argument.
  // Record the message in the datastore.
  return DataStore.of(context).collection<Message>().create(message);
}

@Endpoint()
Stream<Message> newMessages(AuthenticatedContext context) {
  // Return a stream of messages from the datastore.
  return DataStore.of(context).collection<Message>().watchAdditions();
}
