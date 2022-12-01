import 'package:args/command_runner.dart';

import 'generate.dart';

void main(List<String> args) async {
  var runner =
      CommandRunner("shorebird", "Command line interface for Shorebird.")
        ..addCommand(GenerateCommand());
  await runner.run(args);
}
