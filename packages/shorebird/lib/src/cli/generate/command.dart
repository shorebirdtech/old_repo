import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'collect.dart';
import 'generate.dart';

class GenerateCommand extends Command {
  @override
  final name = 'generate';

  @override
  final description = 'Generate source code from annotations.';

  @override
  Future<void> run() async {
    print('Analyzing source code...');
    var endpoints = await collectEndpoints();
    print('Found ${endpoints.length} endpoint(s), generating handlers...');
    var handlers = generateHandlers(endpoints);

    var genDir = Directory('lib/gen/new');
    if (!genDir.existsSync()) {
      genDir.createSync();
    }
    writeLibrary(p.join(genDir.path, 'handlers.dart'), handlers);
  }
}
