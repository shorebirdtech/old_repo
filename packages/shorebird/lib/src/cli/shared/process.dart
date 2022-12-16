import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:process/process.dart';

import 'config.dart';

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

/// Used to track the pids of running jobs.
/// Written to disk as a json file at the given path.
/// This is used to ensure we don't leak processes (particularly on Windows).
class PidFile {
  Map<String, int> pids;
  PidFile.emtpy() : pids = {};
  PidFile.fromJson(Map<String, dynamic> json) : pids = json.cast<String, int>();

  List<String> get tags => pids.keys.toList();

  /// Loads the pid file from disk.
  static Future<PidFile> load([String path = pidFilePath]) async {
    var file = File(path);
    if (!file.existsSync()) {
      return PidFile.emtpy();
    }
    var contents = await file.readAsString();
    return PidFile.fromJson(jsonDecode(contents));
  }

  /// Saves the pid file to disk.
  Future<void> save([String path = pidFilePath]) async {
    var file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(pids));
  }

  /// Adds the given pid to the pid file under the given tag.
  void add(String tag, int pid) {
    var existing = pids[tag];
    if (existing != null) {
      throw StateError('Job "$tag" already tracked in pid file.');
    }
    pids[tag] = pid;
    save();
  }

  /// Removes the entry for the given tag from the pid file (does not kill it).
  void remove(String tag) {
    pids.remove(tag);
    save();
  }

  /// Removes all entries from the pid file (does not kill them).
  void removeAll() {
    pids.clear();
    save();
  }

  /// Kills all processes tracked by this pid file.
  void killAll() {
    for (var pid in pids.values) {
      Process.killPid(pid);
    }
    removeAll();
  }

  /// Kills the process with the given tag, if it exists.
  void kill(String tag) {
    var pid = pids[tag];
    if (pid != null) {
      Process.killPid(pid);
      remove(tag);
    }
    save();
  }

  /// A logging version of killAll which prints a warning for each process
  /// on the assumption that it was stale from an earlier run.
  void killStaleProcesses() {
    for (var tag in tags) {
      print("Warning: killing stale $tag process (pid ${pids[tag]})");
      kill(tag);
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
/// Wrapper around a [ProcessManager] which tracks the pids of running jobs.
class JobRunner {
  final ProcessManager processManager;
  final PidFile pidFile;
  final Map<String, _Job> _jobs = {};

  JobRunner(this.processManager, this.pidFile);
  JobRunner.local(this.pidFile) : processManager = const LocalProcessManager();

  /// Tracks the given process under the given tag.
  void track(Process process, String tag) {
    var existing = _jobs[tag];
    if (existing != null) {
      throw StateError('Job "$tag" already running');
    }
    _jobs[tag] = _Job(tag, process);
    pidFile.add(tag, process.pid);
  }

  /// Kills all running jobs.
  void killAll() {
    pidFile.killAll();
    _jobs.clear();
  }

  /// Wait until any tracked job exits, then kill all other jobs.
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

  /// Starts the given process and tracks it under the given tag.
  Future<Process> start(List<String> args, String tag) async {
    if (args.isEmpty) {
      throw ArgumentError('args must not be empty');
    }
    // Work around https://github.com/dart-lang/sdk/issues/50654
    if (args.first == 'dart') {
      args = [Platform.executable, ...args.skip(1)];
    }
    // Record the pid for the tag.
    var process = await processManager.start(args);
    track(process, tag);
    process.stdout
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen((line) {
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

  /// Run the given command (is not tracked in the pid file).
  Future<ProcessResult> run(List<String> command) =>
      processManager.run(command);
}
