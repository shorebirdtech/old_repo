import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../shared/auth.dart';
import '../shared/config.dart';

class LoginCommand extends Command {
  LoginCommand();

  @override
  final name = 'login';

  @override
  final description = 'login to Shorebird';

  String ask(String prompt) {
    String? answer;
    while (answer == null) {
      stdout.write("$prompt: ");
      answer = stdin.readLineSync()!;
      if (answer == '') {
        answer = null;
      }
    }
    return answer;
  }

  @override
  Future<void> run() async {
    stdout.write(
        "Shorebird is currently in early alpha.  If you'd like to try it, please join our Discord server at ${config.discordUrl} and ask for an API key.\n\n");

    var projectId = ask("Project ID");
    var apiKey = ask('API Key');
    Session(apiKey: apiKey, projectId: projectId).save();
    stdout.writeln("Session saved to $authFilePath.");
  }
}
