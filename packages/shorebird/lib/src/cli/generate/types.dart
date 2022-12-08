import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:path/path.dart' as p;

class TypeDefinition {
  final String name;
  final String? url;
  final DartType dartType;

  // Not sure if this is the correct heuristic.  It's used for deciding
  // if we need to call fromJson or just cast.
  bool get isPrimitiveJsonType {
    return name == 'int' ||
        name == 'double' ||
        name == 'String' ||
        name == 'bool';
  }

  bool get isVoid => dartType.isVoid;
  bool get isList => dartType.isDartCoreList;

  bool get hasInnerType => dartType is ParameterizedType;

  // This is used to tell if we need to use map for to/fromJson.
  // Custom types would implement their own to/fromJson instead.
  bool get isIterable =>
      dartType.isDartCoreIterable ||
      dartType.isDartCoreList ||
      dartType.isDartCoreSet;

  TypeDefinition get innerType {
    if (dartType is ParameterizedType) {
      // Why is this cast necessary, doesn't the compiler know already?
      var type = dartType as ParameterizedType;
      return TypeDefinition.fromDartType(type.typeArguments.first);
    }
    throw StateError('Not a parameterized type: $name');
  }

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

  @override
  String toString() => 'TypeDefinition($name)';
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

/// Groups ParameterDefinitions and provides methods to get subgroups
/// based on named, positional, required, optional, etc.
class ParameterList {
  final List<ParameterDefinition> all;

  bool get isEmpty => all.isEmpty;
  bool get isNotEmpty => all.isNotEmpty;

  List<ParameterDefinition> get positional =>
      all.where((p) => p.isPositional).toList();
  List<ParameterDefinition> get named => all.where((p) => p.isNamed).toList();

  // These include both named and positional. They exist for
  // compatability with the code_builder MethodBuilder api.
  List<ParameterDefinition> get codeBuilderRequired =>
      all.where((p) => !p.isOptional && !p.isNamed).toList();
  // All named parameters must be passed as "optional" to generate correctly.
  // https://github.com/dart-lang/code_builder/issues/385
  List<ParameterDefinition> get codeBuidlerOptional =>
      all.where((p) => p.isOptional || p.isNamed).toList();

  ParameterList(this.all);
}

/// Top-level functions used as endpoints.
class FunctionDefinition {
  final String name;
  final String path;
  final TypeDefinition returnType;

  /// This includes all named, optional, and required parameters.
  /// If generating network code, you want the serializedParameters instead.
  final ParameterList parameters;

  FunctionDefinition({
    required this.name,
    required this.path,
    required this.returnType,
    required List<ParameterDefinition> parameters,
  }) : parameters = ParameterList(parameters);
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
  final bool isNamed;
  final bool isOptional;
  final String? defaultValueCode;

  bool get hasDefaultValue => defaultValueCode != null;
  bool get isRequiredPositional => isPositional && !isOptional;
  bool get isRequiredNamed => isNamed && !isOptional;
  bool get isPositional => !isNamed;

  ParameterDefinition({
    required this.name,
    required this.type,
    required this.isNamed,
    required this.isOptional,
    this.defaultValueCode,
  });
}

class ReturnDefinition {
  final String type;

  ReturnDefinition({
    required this.type,
  });
}

// Generation helpers (is this a separate file?)

// FIXME: importPrefix is wrong, we know where we're generating to and
// we have absolute urls to where classes come from, we should just map.
final importPrefix = '..'; // Assume imports are relative to the gen diretory.
final handlerUrl = 'package:shorebird/handler.dart';
final shorebirdUrl = 'package:shorebird/shorebird.dart';

extension EndpointGeneration on FunctionDefinition {
  String get url {
    var fileName = p.basename(path);
    return "$importPrefix/$fileName";
  }

  String get argsClassName {
    var capitalized = "${name[0].toUpperCase()}${name.substring(1)}";
    return '${capitalized}Args';
  }

  ParameterList get serializedParameters {
    // Hack to remove RequestContext from the generated code.
    // Should at least use the type instead of name?
    // Aren't yet, because might change RequestContext type name...
    return ParameterList(
        parameters.all.where((p) => p.name != 'context').toList());
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

  Reference get innerTypeReference => innerType.typeReference;

  Expression fromJson(Expression value) {
    // This is hard-coded until we have some sort of JsonKey support.
    if (name == 'ObjectId') {
      return typeReference.property('fromHexString').call([value]);
    }
    if (name == 'DateTime') {
      return typeReference.property('parse').call([value]);
    }
    if (isIterable) {
      return value
          .property('map')
          .call([
            Method((m) => m
                  ..requiredParameters.add(Parameter((p) => p.name = 'e'))
                  ..body = innerType.fromJson(refer('e')).returned.statement)
                .closure
          ], {}, [
            innerTypeReference
          ])
          .property('toList')
          .call([]);
    }
    if (isPrimitiveJsonType) {
      // This produces many "unecessary cast" warnings.
      // return value.asA(typeReference);
      return value;
    }
    return typeReference.property('fromJson').call([value]);
  }

  Expression toJson(Expression value) {
    // This is hard-coded until we have some sort of JsonKey support.
    if (name == 'ObjectId') {
      return value.property('toHexString').call([]);
    }
    if (name == 'DateTime') {
      return value.property('toIso8601String').call([]);
    }
    if (isIterable) {
      return value
          .property('map')
          .call([
            Method((m) => m
              ..requiredParameters.add(Parameter((p) => p.name = 'e'))
              ..body = innerType.toJson(refer('e')).returned.statement).closure
          ])
          .property('toList')
          .call([]);
    }
    if (isPrimitiveJsonType) {
      return value;
    }
    return value.property('toJson').call([]);
  }

  // Would like to implement this, but I don't know how to get
  // TypeDefinitions at runtime.
  // TypeDefinition get networkType {
  //   if (name == 'ObjectId') {
  //     return TypeDefinition('String');
  //   }
  //   if (isPrimitiveJsonType) {
  //     return this;
  //   }
  //   return TypeDefinition('Map<String, dynamic>');
  // }

  bool get networkTypeIsPrimitiveJsonType {
    if (name == 'ObjectId') {
      return true;
    }
    if (name == 'DateTime') {
      return true;
    }
    if (isPrimitiveJsonType) {
      return true;
    }
    return false;
  }

  String get networkTypeReferenceString {
    // Hacks until we have JsonKey support.
    if (name == 'ObjectId') {
      return 'String';
    }
    if (name == 'DateTime') {
      return 'String';
    }

    if (isIterable) {
      // I'm not sure why we can't give full types here.
      // extractResult uses this type.
      return 'List';
      // return 'List<${innerType.networkTypeReferenceString}>';
    }
    if (isPrimitiveJsonType) {
      return name;
    }
    // Non-core types expect toJson to return a Map<String, dynamic>.
    return 'Map<String, dynamic>';
  }

  Reference get networkTypeReference {
    return refer(networkTypeReferenceString);
  }
}

extension ParameterListGeneration on ParameterList {
  // Designed to match the CodeBuilder Method API.
  List<Parameter> buildRequiredParameters({bool toThis = false}) =>
      codeBuilderRequired.map((p) => p.toParameter(toThis: toThis)).toList();

  List<Parameter> buildOptionalParameters({bool toThis = false}) =>
      codeBuidlerOptional.map((p) => p.toParameter(toThis: toThis)).toList();
}

extension ParameterGeneration on ParameterDefinition {
  Reference get typeReference => type.typeReference;

  Parameter toParameter({bool toThis = false}) {
    return Parameter((p) {
      p.name = name;
      if (!toThis) {
        p.type = typeReference;
      }
      p.named = isNamed;
      p.required = isRequiredNamed;
      p.toThis = toThis;
      p.defaultTo = hasDefaultValue ? Code(defaultValueCode!) : null;
    });
  }
}
