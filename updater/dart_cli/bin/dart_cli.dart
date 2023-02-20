import 'package:args/command_runner.dart';
import 'package:dart_cli/updater.dart';

void main(List<String> args) async {
  // This might pass a path or flavor (debug/release) later.
  Updater.loadLibrary();

  var clientId = 'my-client-id';
  var cacheDir = 'updater_cache';
  var updater = Updater(clientId, cacheDir);

  final runner = CommandRunner<void>('updater', 'Updater CLI')
    ..addCommand(CheckForUpdate(updater))
    ..addCommand(PrintVersion(updater));
  await runner.run(args);
}

class CheckForUpdate extends Command<void> {
  final Updater updater;
  CheckForUpdate(this.updater);

  @override
  final name = 'check';

  @override
  final description = 'Check for an update.';

  @override
  void run() {
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
}

class PrintVersion extends Command<void> {
  final Updater updater;
  PrintVersion(this.updater);

  @override
  final name = 'version';

  @override
  final description = 'Print current installed version.';

  @override
  void run() {
    print("Current version: ${updater.version()}");
  }
}
