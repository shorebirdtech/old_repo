import 'package:code_builder/code_builder.dart';

// From the point of view of the developer, there is no server.
// But when we run the code locally we need some main entrypoint with
// which to launch the server process.  Generate one here.
Library generateServer() {
  var library = LibraryBuilder();
  library.body.add(Code('''
import 'dart:io';

import 'package:shorebird/datastore.dart';
import 'package:shorebird/server.dart';

import 'handlers.dart';
import 'storable.dart';

void main() async {
  await DataStore.initSingleton(DataStoreLocal(classInfoMap));

  var server = Server();
  await server.serve(allHandlers);
  // ignore: avoid_print
  print("Serving at http://\${server.address.host}:\${server.port}");
}
'''));
  return library.build();
}
