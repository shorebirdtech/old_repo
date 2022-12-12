import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:args/command_runner.dart';

import 'ignore_file.dart';

class DeployCommand extends Command {
  DeployCommand();

  @override
  final name = 'deploy';

  @override
  final description = 'deploy to Shorebird';

  void _checkInProjectDirectory() {
    if (!File('pubspec.yaml').existsSync()) {
      throw UsageException(
          'This command must be run from the root of a project.', usage);
    }
  }

  void _checkIfLoggedIn() {
    // This should check for some sort of global shorebird session?
    // Or maybe just .dart_tool/shorebird/session.json?
  }

  List<String> _filesToDeploy() {
    final ignoreFile = IgnoreFile('.gitignore');
    final files = <String>[];
    final dir = Directory.current;
    for (var file in dir.listSync(recursive: true)) {
      var path = file.path;
      if (ignoreFile.shouldIgnore(path)) {
        continue;
      }
      if (file is File) {
        files.add(path);
      }
    }
    return files;
  }

  void bundleForDeployment(String zipPath) {
    final files = _filesToDeploy();
    for (var file in files) {
      print(file);
    }
    // Bundle the project into a zip file.
    var encoder = ZipFileEncoder();
    encoder.create(zipPath);
    for (var file in files) {
      encoder.addFile(File(file));
    }
    encoder.close();
  }

  @override
  Future<void> run() async {
    // Check that we're inside a project directory.
    _checkInProjectDirectory();
    // Check if the user is logged in.
    _checkIfLoggedIn();
    // Bundle up the project into a zip.
    // Create a new deployment on shorebird.
    final buildDir = 'build/deploy';
    Directory(buildDir).createSync(recursive: true);
    final zipPath = '$buildDir/deploy.zip';
    print("Bundling project into $zipPath");
    bundleForDeployment(zipPath);
    // Upload the zip to shorebird.
    // Give the user a link to get status on the deployment.
    // Give the user the link to the final location of the deployment.
  }
}
