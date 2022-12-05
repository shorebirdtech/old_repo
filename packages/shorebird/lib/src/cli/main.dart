import 'package:args/command_runner.dart';

import 'generate/command.dart';
import 'run/command.dart';

void main(List<String> args) async {
  var runner =
      CommandRunner("shorebird", "Command line interface for Shorebird.")
        ..addCommand(GenerateCommand())
        ..addCommand(RunCommand());
  await runner.run(args);
}
