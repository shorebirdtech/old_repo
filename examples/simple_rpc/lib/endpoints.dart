import 'package:shorebird/datastore.dart';
import 'package:shorebird/shorebird.dart';

import 'model.dart';

class MessageEndpoint extends Endpoint {
  // Shouldn't these take a request context?
  Future<void> sendMessage(Message message) async {
    // Record the message in the datastore.
    await DataStore.instance.collection<Message>().create(message);
  }

  Stream<Message> newMessages() {
    // Return a stream of messages from the datastore.
    return DataStore.instance.collection<Message>().watchAdditions();
  }
}
