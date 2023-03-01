import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  final runner = CommandRunner<void>('shorebird', 'Shorebird CLI')
    ..addCommand(Publish());
  await runner.run(args);
}

Future<void> uploadToDeployServer({
  required String path,
  required Uri deployUrl,
}) async {
  var request = http.MultipartRequest('POST', deployUrl);
  var file = await http.MultipartFile.fromPath('file', path);
  request.files.add(file);
  var response = await request.send();
  if (response.statusCode == 200) {
    print('Deploy successful.');
  } else {
    print('Deploy failed: ${response.statusCode} ${response.reasonPhrase}');
  }
  exit(0);
}

class Publish extends Command<void> {
  Publish();

  @override
  final name = 'publish';

  @override
  final description = 'Publish an update.';

  @override
  void run() async {
    if (argResults!.rest.isEmpty) {
      print('No file specified.');
      return;
    }
    // Which file are we sending to the server?
    var path = argResults!.rest[0];

    final deployUri = Uri.parse('http://localhost:8080/deploy');
    await uploadToDeployServer(path: path, deployUrl: deployUri);

    // This exit should not be needed, but otherwise it just hangs forever.
    exit(0);
  }
}
