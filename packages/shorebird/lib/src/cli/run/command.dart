import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:process/process.dart';
import 'package:shorebird/server.dart';

const serverPath = 'lib/gen/local_server.dart';
const pidFilePath = '.dart_tool/shorebird/pids.json';

// int? pidHoldingPortWindows(int port) {
//   var result = Process.runSync('netstat', ['-ano', '-p', 'tcp']);
//   if (result.exitCode != 0) {
//     throw StateError('Failed to run netstat: ${result.stderr}');
//   }
//   var lines = result.stdout.toString().split('\r\n');
//   var header = lines.first;
//   var headerParts = header.split(RegExp(r'\s+'));
//   var pidIndex = headerParts.indexOf('PID');
//   var portIndex = headerParts.indexOf('Local Address');
//   if (pidIndex == -1 || portIndex == -1) {
//     throw StateError('Failed to parse netstat output: $header');
//   }
//   for (var line in lines.skip(1)) {
//     var parts = line.split(RegExp(r'\s+'));
//     if (parts.length < 2) {
//       continue;
//     }
//     var pid = int.tryParse(parts[pidIndex]);
//     var portString = parts[portIndex];
//     var portParts = portString.split(':');
//     if (portParts.length < 2) {
//       continue;
//     }
//     var port = int.tryParse(portParts.last);
//     if (port == null) {
//       continue;
//     }
//     if (port == port) {
//       return pid;
//     }
//   }
//   return null;
// }

class PidFile {
  Map<String, int> pids;
  PidFile.emtpy() : pids = {};
  PidFile.fromJson(Map<String, dynamic> json) : pids = json.cast<String, int>();

  List<String> get tags => pids.keys.toList();

  static Future<PidFile> load([String path = pidFilePath]) async {
    var file = File(path);
    if (!file.existsSync()) {
      return PidFile.emtpy();
    }
    var contents = await file.readAsString();
    return PidFile.fromJson(jsonDecode(contents));
  }

  Future<void> save([String path = pidFilePath]) async {
    var file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(pids));
  }

  void add(String tag, int pid) {
    var existing = pids[tag];
    if (existing != null) {
      throw StateError('Job "$tag" already tracked in pid file.');
    }
    pids[tag] = pid;
    save();
  }

  void remove(String tag) {
    pids.remove(tag);
    save();
  }

  // This should not exist:
  // https://github.com/dart-lang/sdk/issues/50654
  void replacePid(String tag, int pid) {
    var existing = pids[tag];
    if (existing == null) {
      throw StateError('Job "$tag" is not in pid file.');
    }
    pids[tag] = pid;
    save();
  }

  void removeAll() {
    pids.clear();
    save();
  }

  void killAll() {
    for (var pid in pids.values) {
      Process.killPid(pid);
    }
    removeAll();
  }

  void kill(String tag) {
    var pid = pids[tag];
    if (pid != null) {
      Process.killPid(pid);
      remove(tag);
    }
  }
}

class _Job {
  final String tag;
  final Process process;

  _Job(this.tag, this.process);
}

class _JobExit {
  final String tag;
  final int exitCode;

  _JobExit(this.tag, this.exitCode);
}

// This should just sign up for all exit codes and call some "exited"
// callback which then the caller can turn around into a killAll command?
class JobTracker {
  final PidFile pidFile;
  final Map<String, _Job> _jobs = {};

  JobTracker(this.pidFile);

  void track(Process process, String tag) {
    var existing = _jobs[tag];
    if (existing != null) {
      throw StateError('Job "$tag" already running');
    }
    _jobs[tag] = _Job(tag, process);
    pidFile.add(tag, process.pid);
  }

  void killAll() {
    pidFile.killAll();
    _jobs.clear();
  }

  Future<void> waitAnyExit() async {
    var completer = Completer<_JobExit>.sync();
    void onValue(value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    void onError(Object error, StackTrace stack) {
      if (!completer.isCompleted) completer.completeError(error, stack);
    }

    for (var job in _jobs.values) {
      unawaited(job.process.exitCode.then(
          (exitCode) => onValue(_JobExit(job.tag, exitCode)),
          onError: onError));
    }
    var jobExit = await completer.future;
    _jobs.remove(jobExit.tag);
    print(
        "${jobExit.tag} exited with code ${jobExit.exitCode}, killing others...");
    killAll();
    exit(jobExit.exitCode);
  }
}

void _killStaleProcesses(PidFile pidFile) {
  for (var tag in pidFile.tags) {
    print("Warning: killing stale $tag process (pid ${pidFile.pids[tag]})");
    pidFile.kill(tag);
  }
}

class RunCommand extends Command {
  RunCommand();

  @override
  final name = 'run';

  @override
  final description = 'Run the app, including server, client and datastore.';

  final processManager = LocalProcessManager();
  late final JobTracker _jobTracker;

  Future<Process> startProcess(List<String> args, String tag) async {
    // Record the pid for the tag.
    var process = await processManager.start(args);
    _jobTracker.track(process, tag);
    process.stdout
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen((line) {
      if (line.startsWith(hackAroundDartBug50654Prefix)) {
        var processId =
            int.parse(line.substring(hackAroundDartBug50654Prefix.length));
        _jobTracker.pidFile.replacePid(tag, processId);
        return; // Hide the line.
      }
      print("$tag: $line");
    });
    process.stderr
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen((line) {
      print("$tag Error: $line");
    });
    return process;
  }

  @override
  Future<void> run() async {
    // Kill any stale processes.
    var pidFile = await PidFile.load();
    _killStaleProcesses(pidFile);
    _jobTracker = JobTracker(pidFile);

    // Build if needed
    await processManager.run(['flutter', 'build']);

    // Run server
    await startProcess(['dart', 'run', serverPath], 'server');

    // Wait until server is ready?
    // Run client
    // await startProcess(['flutter', 'run'], 'client');

    await startProcess(['dart', 'run', 'bin/simple_rpc.dart'], 'client');

    // Wait for exit
    await _jobTracker.waitAnyExit();
  }
}
