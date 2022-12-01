import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

class TypeDefinition {
  TypeDefinition.fromDartType(DartType dartType);
}

class EndpointDefinition {
  final String name;
  final String path;
  final List<MethodDefintion> methods;

  EndpointDefinition({
    required this.name,
    required this.path,
    required this.methods,
  });
}

class MethodDefintion {
  final String name;
  final TypeDefinition returnType;
  final List<ParameterDefinition> args;
  MethodDefintion({
    required this.name,
    required this.returnType,
    required this.args,
  });
}

class ParameterDefinition {
  final String name;
  final TypeDefinition type;

  ParameterDefinition({
    required this.name,
    required this.type,
  });
}

class ReturnDefinition {
  final String type;

  ReturnDefinition({
    required this.type,
  });
}

Future<List<EndpointDefinition>> collectEndpoints() async {
  List<EndpointDefinition> endpoints = [];
  var collection =
      AnalysisContextCollection(includedPaths: [Directory.current.path]);

  for (var context in collection.contexts) {
    var analyzedFiles = context.contextRoot.analyzedFiles().toList();
    analyzedFiles.sort();
    for (var filePath in analyzedFiles) {
      if (!filePath.endsWith('.dart')) {
        continue;
      }
      // Ignore files in gen directory.
      var relativePath = p.relative(filePath);
      if (p.split(relativePath).contains('gen')) {
        continue;
      }

      // The first call triggers analysis and may take a long time.
      var library = await context.currentSession.getResolvedLibrary(filePath);
      // Ignore parts and failed loads.
      if (library is! ResolvedLibraryResult) {
        continue;
      }
      var element = library.element;
      var topElements = element.topLevelElements;

      for (var element in topElements) {
        if (element is ClassElement) {
          var className = element.name;
          var superclassName = element.supertype!.element.name;
          if (superclassName == 'Endpoint') {
            var methodDefinitions = <MethodDefintion>[];
            for (var method in element.methods) {
              var args = <ParameterDefinition>[];
              for (var parameter in method.parameters) {
                args.add(ParameterDefinition(
                  name: parameter.name,
                  type: TypeDefinition.fromDartType(parameter.type),
                ));
              }
              methodDefinitions.add(MethodDefintion(
                name: method.name,
                returnType: TypeDefinition.fromDartType(method.returnType),
                args: args,
              ));
            }
            // Collect call names, parameters and return types.
            endpoints.add(EndpointDefinition(
              name: className,
              path: filePath,
              methods: methodDefinitions,
            ));
          }
        }
      }
    }
  }
  return endpoints;
}

Library generateHandlers(List<EndpointDefinition> endpoints) {
  var library = LibraryBuilder();

  for (var endpoint in endpoints) {
    library.body.add(Class((builder) {
      builder.name = endpoint.name;
      builder.extend = refer('ShorebirdHandler');
    }));
  }
  return library.build();
}

class GenerateCommand extends Command {
  @override
  final name = 'generate';

  @override
  final description = 'Generate source code from annotations.';

  @override
  Future<void> run() async {
    print('Generating source code...');
    var endpoints = await collectEndpoints();
    print('Found ${endpoints.length} endpoints:');
    var handlers = generateHandlers(endpoints);
    var emitter = DartEmitter();
    var formatter = DartFormatter();
    var output = formatter.format('${handlers.accept(emitter)}');
    print(output);
  }
}
