import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:args/command_runner.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;

import '../shared/config.dart';
import 'ignore_file.dart';

class DeployCommand extends Command {
  DeployCommand() {
    argParser.addOption('deploy-url', help: 'The URL of the deploy server.');
  }

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
    // Bundle the project into a zip file.
    var encoder = ZipFileEncoder();
    encoder.create(zipPath);
    for (var file in files) {
      var relativePath = p.relative(file, from: Directory.current.path);
      // print(file);
      // By default package:archive only includes the file name, we want
      // to use the relative path intead.
      encoder.addFile(File(file), relativePath);
    }
    encoder.close();
  }

  Future<void> uploadToDeployServer(
      {required String zipPath,
      required String productName,
      required Uri deployUrl}) async {
    var request = MultipartRequest('POST', deployUrl);
    var file = await MultipartFile.fromPath('file', zipPath);
    request.files.add(file);
    request.fields['productName'] = productName;
    var response = await request.send();
    if (response.statusCode == 200) {
      print('Deploy queued successfully.');
    } else {
      print('Deploy failed: ${response.statusCode} ${response.reasonPhrase}');
    }
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
    final productName = 'my-product';
    final deployServerString =
        argResults!['deploy-url'] ?? config.deployServerUrl;
    final deployUrl = Uri.parse(deployServerString);
    // Upload the zip to shorebird.
    print("Uploading $zipPath to $deployUrl");
    await uploadToDeployServer(
        zipPath: zipPath, productName: productName, deployUrl: deployUrl);
    // Give the user a link to get status on the deployment.
    // Give the user the link to the final location of the deployment.
    // Some sort of "wait" option which waits until the deploy is complete?
    exit(0); // Should this return intead?
  }
}
