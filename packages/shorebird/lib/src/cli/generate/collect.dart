import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;
import 'package:shorebird/annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'types.dart';

class CollectionResult {
  final List<FunctionDefinition> endpoints;
  final List<ClassDefinition> models;

  const CollectionResult({required this.endpoints, required this.models});
}

FunctionDefinition? _checkForEndpoint(Element element, String filePath) {
  const endpointAnnotation = TypeChecker.fromRuntime(Endpoint);

  if (element is! FunctionElement) {
    return null;
  }
  if (!endpointAnnotation.hasAnnotationOf(element)) {
    return null;
  }
  var args = <ParameterDefinition>[];
  for (var parameter in element.parameters) {
    args.add(ParameterDefinition(
      name: parameter.name,
      type: TypeDefinition.fromDartType(parameter.type),
      isNamed: parameter.isNamed,
      isOptional: parameter.isOptional,
      defaultValueCode: parameter.defaultValueCode,
    ));
  }
  return FunctionDefinition(
    importUrl: element.location!.components.first,
    name: element.name,
    returnType: TypeDefinition.fromDartType(element.returnType),
    parameters: args,
  );
}

ClassDefinition? _checkForModel(Element element, String filePath) {
  const storableAnnotation = TypeChecker.fromRuntime(Storable);
  const transportableAnnotation = TypeChecker.fromRuntime(Transportable);

  if (element is! ClassElement) {
    return null;
  }
  if (!storableAnnotation.hasAnnotationOf(element) &&
      !transportableAnnotation.hasAnnotationOf(element)) {
    return null;
  }
  var fields = <FieldDefinition>[];
  for (var field in element.fields) {
    fields.add(FieldDefinition(
      name: field.name,
      type: TypeDefinition.fromDartType(field.type),
    ));
  }

  // bool hasToJson =
  //     element.lookUpConcreteMethod('toJson', element.library) != null;
  // bool hasFromJson = element.getNamedConstructor('fromJson') != null;
  return ClassDefinition(
    name: element.name,
    type: TypeDefinition.fromDartType(element.thisType),
    fields: fields,
  );
}

Future<CollectionResult> collectAnnotations(
    AnalysisContextCollection collection) async {
  List<FunctionDefinition> endpoints = [];
  List<ClassDefinition> models = [];

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
        var endpoint = _checkForEndpoint(element, filePath);
        if (endpoint != null) {
          // print("Found endpoint in $filePath: ${endpoint.name}");
          endpoints.add(endpoint);
        }
        var model = _checkForModel(element, filePath);
        if (model != null) {
          // print("Found model in $filePath: ${model.name}");
          models.add(model);
        }
      }
    }
  }
  return CollectionResult(endpoints: endpoints, models: models);
}
