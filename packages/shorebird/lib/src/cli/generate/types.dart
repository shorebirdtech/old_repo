import 'package:analyzer/dart/element/type.dart';

class TypeDefinition {
  final String name;
  final String? url;
  final DartType dartType;

  // Not sure if this is the correct heuristic.  It's used for deciding
  // if we need to call fromJson or just cast.
  bool get isPrimitive => url == null || url == 'dart:core';

  TypeDefinition.fromDartType(this.dartType)
      : name = dartType.getDisplayString(withNullability: false),
        url = dartType.element?.librarySource?.uri.toString();
}

// Top-level functions used as endpoints.
class FunctionDefinition {
  final String name;
  final String path;
  final TypeDefinition returnType;
  final List<ParameterDefinition> args;

  List<ParameterDefinition> get serializedArgs =>
      args.sublist(1); // Ignore the "context" argument.

  FunctionDefinition({
    required this.name,
    required this.path,
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
