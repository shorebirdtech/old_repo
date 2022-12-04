import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

import 'collect.dart';
import 'generate_client.dart';
import 'generate_handlers.dart';
import 'generate_server.dart';
import 'generate_storable.dart';

class GenerateCommand extends Command {
  GenerateCommand() {
    // Disable formatting during development.
    argParser.addFlag('format', defaultsTo: true);
  }

  @override
  final name = 'generate';

  @override
  final description = 'Generate source code from annotations.';

  @override
  Future<void> run() async {
    print('Analyzing source code...');
    var collection =
        AnalysisContextCollection(includedPaths: [Directory.current.path]);
    var result = await collectAnnotations(collection);
    print(
        'Found ${result.endpoints.length} endpoint(s), generating handlers...');

    var writer = _LibraryWriter('lib/gen/new',
        formatOutput: argResults!['format'] as bool);
    writer.writeLibrary('handlers.dart', generateHandlers(result.endpoints));
    writer.writeLibrary('client.dart', generateClient(result.endpoints));
    writer.writeLibrary('models.dart', generateStorable(result.models));
    writer.writeLibrary('local_server.dart', generateServer());
  }
}

class _LibraryWriter {
  late final Directory genDir;
  final bool formatOutput;

  _LibraryWriter(String genDirPath, {this.formatOutput = true}) {
    genDir = Directory(genDirPath);
    if (!genDir.existsSync()) {
      genDir.createSync();
    }
    // Should this clear the gen directory?
  }

  void writeLibrary(String libraryPath, Library library) {
    var path = p.join(genDir.path, libraryPath);
    var emitter = DartEmitter(
      // The default is Allocator.none which does not collect imports.
      // Allocator() will collect imports and print them at the top of the file.
      allocator: Allocator(),
      orderDirectives: true, // Sort the imports.
      useNullSafetySyntax: true, // Use modern Dart.
    );
    var output = library.accept(emitter).toString();
    output = """// Generated by `dart run shorebird generate`.
$output""";
    if (formatOutput) {
      output = DartFormatter().format(output);
    }
    File(path).writeAsStringSync(output);
  }
}