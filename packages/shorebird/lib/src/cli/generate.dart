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

String _handlerName(String endpointName) {
  return "${endpointName.substring(0, endpointName.length - "Endpoint".length)}Handler";
}

Library generateHandlers(List<EndpointDefinition> endpoints) {
  var library = LibraryBuilder();
  final shorebirdUrl = 'package:shorebird/shorebird.dart';

  for (var endpointDef in endpoints) {
    library.body.add(Class((endpoint) {
      endpoint.name = _handlerName(endpointDef.name);
      endpoint.extend = refer('ShorebirdHandler', shorebirdUrl);

      endpoint.fields.add(Field((field) {
        field.name = 'endpoint';
        field.modifier = FieldModifier.final$;
        field.type = refer(endpointDef.name, endpointDef.path);
      }));

      endpoint.constructors.add(Constructor((c) {
        c.requiredParameters.add(Parameter((p) {
          p.name = 'endpoint';
          p.type = refer(endpointDef.name, endpointDef.path);
        }));
      }));
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

void writeLibrary(String path, Library library) {
  var emitter = DartEmitter(useNullSafetySyntax: true);
  var formatter = DartFormatter();
  var output = formatter.format('${library.accept(emitter)}');
  File(path).writeAsStringSync(output);
}
