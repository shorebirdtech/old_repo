import 'dart:async';

import 'package:args/command_runner.dart';

import '../shared/config.dart';
import '../shared/process.dart';

class ServeCommand extends Command {
  ServeCommand();

  @override
  final name = 'serve';

  @override
  final description = 'Run a local copy of the server and datastore.';

  late final JobRunner _jobRunner;

  @override
  Future<void> run() async {
    var pidFile = await PidFile.load();
    pidFile.killStaleProcesses();
    _jobRunner = JobRunner.local(pidFile);

    // Build if needed
    await _jobRunner.run(['flutter', 'build']);

    // Run server
    await _jobRunner.start(['dart', 'run', config.localServerPath], 'server');

    // Wait for exit
    await _jobRunner.waitAnyExit();
  }
}
