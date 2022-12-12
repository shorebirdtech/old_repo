import 'package:args/command_runner.dart';

import 'generate/command.dart';
import 'run/command.dart';
import 'serve/command.dart';
import 'deploy/command.dart';
import 'login/command.dart';

void main(List<String> args) async {
  final commands = [
    GenerateCommand(),
    ServeCommand(),
    RunCommand(),
    DeployCommand(),
    LoginCommand(),
  ];
  final runner =
      CommandRunner("shorebird", "Command line interface for Shorebird.");
  for (var command in commands) {
    runner.addCommand(command);
  }
  await runner.run(args);
}
