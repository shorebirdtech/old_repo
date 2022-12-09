import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../shared/config.dart';
import '../shared/process.dart';

class ClientConfig {
  final String path;
  final bool isFlutter;

  ClientConfig.flutter(this.path) : isFlutter = true;
  ClientConfig.dart(this.path) : isFlutter = false;
}

class RunCommand extends Command {
  RunCommand();

  @override
  final name = 'run';

  @override
  final description = 'Run the app, including server, client and datastore.';

  late final JobRunner _jobRunner;

  ClientConfig _handleArgs() {
    if (argResults!.rest.length > 1) {
      throw UsageException('`run` only takes at most one argument', usage);
    }
    if (argResults!.rest.isEmpty) {
      return ClientConfig.flutter('lib/main.dart');
    }
    return ClientConfig.dart(argResults!.rest.first);
  }

  @override
  Future<void> run() async {
    var client = _handleArgs();
    if (!File(client.path).existsSync()) {
      throw UsageException(
          'Client path (${client.path}) does not exist', usage);
    }

    var pidFile = await PidFile.load();
    pidFile.killStaleProcesses();
    _jobRunner = JobRunner.local(pidFile);

    // Build if needed
    if (client.isFlutter) {
      await _jobRunner.run(['flutter', 'build']);
    }

    // Run server (or tee logs from remote server?)
    await _jobRunner.start(['dart', 'run', config.localServerPath], 'server');

    // Wait until server is ready?
    // Run client
    if (client.isFlutter) {
      await _jobRunner.start(['flutter', 'run'], 'client');
    } else {
      await _jobRunner.start(['dart', 'run', client.path], 'client');
    }

    // Wait for exit
    await _jobRunner.waitAnyExit();
  }
}
