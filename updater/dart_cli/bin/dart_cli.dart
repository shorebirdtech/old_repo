import 'package:dart_cli/updater.dart';

void main() {
  // This might pass a path or flavor (debug/release) later.
  Updater.loadLibrary();

  var clientId = 'my-client-id';
  var cacheDir = 'updater_cache';
  var updater = Updater(clientId, cacheDir);
  var result = updater.checkForUpdate();
  if (result) {
    print('Update available');
  } else {
    print('No update available');
  }
}
