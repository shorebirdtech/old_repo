import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:path/path.dart' as p;

class TypeDefinition {
  final String name;
  final String? url;
  final DartType dartType;

  // Not sure if this is the correct heuristic.  It's used for deciding
  // if we need to call fromJson or just cast.
  bool get isPrimitive => url == null || url == 'dart:core';
  bool get isVoid => dartType.isVoid;

  TypeDefinition.fromDartType(this.dartType)
      : name = dartType.getDisplayString(withNullability: false),
        url = urlFromDartType(dartType);

  static String? urlFromDartType(DartType dartType) {
    // There must be a better way to implement this hack.
    // I want the library which *exported* the type, not where it was defined.
    if (dartType.element?.name == 'ObjectId') {
      return 'package:shorebird/datastore.dart';
    }
    return dartType.element?.librarySource?.uri.toString();
  }
}

class ClassDefinition {
  final String name;
  final TypeDefinition type;
  final List<FieldDefinition> fields;

  ClassDefinition({
    required this.name,
    required this.type,
    required this.fields,
  });
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

class FieldDefinition {
  final String name;
  final TypeDefinition type;

  FieldDefinition({
    required this.name,
    required this.type,
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

// Generation helpers (is this a separate file?)

final importPrefix = '..'; // Assume imports are relative to the gen diretory.
final handlerUrl = 'package:shorebird/handler.dart';
final shorebirdUrl = 'package:shorebird/shorebird.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

extension EndpointGeneration on FunctionDefinition {
  String get url {
    var fileName = p.basename(path);
    return "$importPrefix/$fileName";
  }

  String get argsClassName {
    return '${name.capitalize()}Args';
  }

  String get handlerPath => '/$name';

  Reference get argsTypeReference => refer(argsClassName, 'handlers.dart');

  bool get returnsStream => returnType.dartType.isDartAsyncStream;

  TypeDefinition get innerReturnType => TypeDefinition.fromDartType(
      (returnType.dartType as ParameterizedType).typeArguments.first);

  Reference get innerReturnTypeReference => innerReturnType.typeReference;
  Reference get reference => refer(name, url);
  Reference get returnTypeReference => returnType.typeReference;
}

extension TypeGeneration on TypeDefinition {
  Reference get typeReference {
    if (url == null) {
      return refer(name);
    } else {
      return refer(name, url);
    }
  }

  Expression get fromJsonMethod {
    // This is hard-coded until we have some sort of JsonKey support.
    if (name == 'ObjectId') {
      return typeReference.property('fromHexString');
    }
    return typeReference.property('fromJson');
  }

  // Hack for ObjectId having a toJson but not returning a Map.
  bool get isPrimitiveNetworkType {
    return isPrimitive || name == 'ObjectId';
  }

  Reference get networkTypeReference {
    if (name == 'ObjectId') {
      return refer('String');
    }
    if (isPrimitive) {
      return typeReference;
    }
    return refer('Map<String, dynamic>');
  }
}

extension ParamaterGeneration on ParameterDefinition {
  Reference get typeReference => type.typeReference;
}
