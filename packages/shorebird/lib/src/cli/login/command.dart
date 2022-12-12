import 'dart:async';

import 'package:args/command_runner.dart';

class LoginCommand extends Command {
  LoginCommand();

  @override
  final name = 'login';

  @override
  final description = 'login to Shorebird';

  @override
  Future<void> run() async {
    print("Successfully logged in as alice@example.com");
  }
}
