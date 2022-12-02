import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;
import 'package:shorebird/shorebird.dart';
import 'package:source_gen/source_gen.dart';

import 'types.dart';

Future<List<FunctionDefinition>> collectEndpoints() async {
  List<FunctionDefinition> endpoints = [];
  var collection =
      AnalysisContextCollection(includedPaths: [Directory.current.path]);

  var endpointAnnotation = TypeChecker.fromRuntime(Endpoint);

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
        if (element is! FunctionElement) {
          continue;
        }
        if (!endpointAnnotation.hasAnnotationOf(element)) {
          continue;
        }
        var args = <ParameterDefinition>[];
        for (var parameter in element.parameters) {
          args.add(ParameterDefinition(
            name: parameter.name,
            type: TypeDefinition.fromDartType(parameter.type),
          ));
        }
        endpoints.add(FunctionDefinition(
          path: filePath,
          name: element.name,
          returnType: TypeDefinition.fromDartType(element.returnType),
          args: args,
        ));
      }
    }
  }
  return endpoints;
}
