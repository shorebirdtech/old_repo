import 'package:analyzer/dart/element/type.dart';

class TypeDefinition {
  TypeDefinition.fromDartType(DartType dartType);
}

// Top-level functions used as endpoints.
class FunctionDefinition {
  final String name;
  final String path;
  final TypeDefinition returnType;
  final List<ParameterDefinition> args;
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
