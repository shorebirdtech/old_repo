// This should be generated or provided by shorebird.

import 'dart:io';

import 'package:shorebird/datastore.dart';
import 'package:shorebird/shorebird.dart';
import 'package:simple_rpc/gen/handlers.dart';
import 'package:simple_rpc/gen/storable.dart';

void main() async {
  // This should just be a `shorebird run --local` command option?
  await DataStore.initSingleton(DataStoreLocal(classInfoMap, 'db.json'));

  var server = Server();
  await server.serve(allHandlers, InternetAddress.anyIPv4, 3000);
  // ignore: avoid_print
  print('Serving at http://${server.address.host}:${server.port}');
}
