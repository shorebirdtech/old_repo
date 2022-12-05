import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:process/process.dart';

final serverPath = 'lib/gen/local_server.dart';

class RunCommand extends Command {
  RunCommand();

  @override
  final name = 'run';

  @override
  final description = 'Run the app, including server, client and datastore.';

  final processManager = LocalProcessManager();
  final List<Process> _processes = [];

  void _killAll() {
    for (var process in _processes) {
      process.kill();
    }
  }

  void watch(Process process, String tag) {
    _processes.add(process);
    process.stdout.transform(utf8.decoder).listen((event) {
      print("$tag Out: $event");
    });
    process.stderr.transform(utf8.decoder).listen((event) {
      print("$tag Err: $event");
    });
  }

  Future<Process> startProcess(List<String> args, String tag) async {
    var process = await processManager.start(args);
    watch(process, tag);
    return process;
  }

  Future<void> waitAnyExit() async {
    var exit = await Future.any(_processes.map((e) => e.exitCode));
    print("Process exited with code $exit, killing others...");
    _killAll();
  }

  @override
  Future<void> run() async {
    // Build if needed
    await processManager.run(['flutter', 'build']);

    // Run server
    await startProcess(['dart', serverPath], 'server');

    // Wait until server is ready?
    // Run client
    // await startProcess(['flutter', 'run'], 'client');

    await startProcess(['dart', 'bin/simple_rpc.dart'], 'server');

    // Wait for exit
    await waitAnyExit();
  }
}
