import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

import 'types.dart';

String importPrefix = '../..';

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

  Reference get reference => refer(name, url);
}

extension ParamaterGeneration on ParameterDefinition {
  Reference get typeReference => refer(type.name, type.url);
}

// Spec _generateArgsClass(FunctionDefinition endpoint) {
//   var args = endpoint.serializedArgs;
//   if (args.isEmpty) {
//     return Code('');
//   }
//   var argsClass = ClassBuilder();
//   argsClass.name = endpoint.argsClassName;
//   argsClass.fields.addAll(args.map((arg) {
//     return Field((b) => b
//       ..name = arg.name
//       ..type = arg.typeReference
//       ..modifier = FieldModifier.final$);
//   }));
//   argsClass.constructors.add(Constructor((b) => b
//     ..requiredParameters.addAll(args.map((arg) {
//       return Parameter((b) => b
//         ..name = arg.name
//         ..toThis = true);
//     }))));
//   argsClass.constructors.add(Constructor((b) => b
//     ..name = 'fromJson'
//     ..requiredParameters.add(Parameter((b) => b
//       ..name = 'json'
//       ..type = refer('Map<String, dynamic>')))
//     ..initializers.addAll(args.map((arg) {
//       return Code('''${arg.name} = json['${arg.name}'] as ${arg.type.name}''');
//     }))));

//   argsClass.methods.add(Method((b) => b
//     ..name = 'toJson'
//     ..returns = refer('Map<String, dynamic>')
//     ..body = Code('''
//         return {
//           ${args.map((arg) => "'${arg.name}': ${arg.name}").join(',\n')}
//         };
//       ''')));
//   return argsClass.build();
// }

Expression _extractTypedArgFromJson(String jsonName, ParameterDefinition arg) {
  if (arg.type.isPrimitive) {
    return refer(jsonName)
        .index(literalString(arg.name))
        .asA(arg.typeReference);
  } else {
    return arg.typeReference.property('fromJson').call([
      refer(jsonName)
          .index(literalString(arg.name))
          .asA(refer('Map<String, dynamic>'))
    ]);
  }
}

Code _handlerForEndpoint(FunctionDefinition endpoint) {
  // The only two differences between these two calls
  // is awaiting the future and the constructor name.
  if (endpoint.returnType.dartType.isDartAsyncStream) {
    return refer('Handler.stream').call([
      literalString(endpoint.name),
      Method((f) {
        f.requiredParameters
          ..add(Parameter((p) => p.name = 'context'))
          ..add(Parameter((p) => p.name = 'json'));
        f.body = endpoint.reference
            .call([
              refer('context'),
              ...endpoint.serializedArgs
                  .map((arg) => _extractTypedArgFromJson('json', arg)),
            ])
            .property('asyncMap')
            .call([
              Method((c) {
                c.requiredParameters.add(Parameter((p) => p.name = 'element'));
                c.body = refer('element').property('toJson').call([]).code;
              }).closure
            ])
            .code;
      }).closure
    ]).code;
  } else {
    return refer('Handler.simpleCall').call([
      literalString(endpoint.name),
      Method((f) {
        f.requiredParameters
          ..add(Parameter((p) => p.name = 'context'))
          ..add(Parameter((p) => p.name = 'json'));
        f.modifier = MethodModifier.async;
        f.body = endpoint.reference
            .call([
              refer('context'),
              ...endpoint.serializedArgs
                  .map((arg) => _extractTypedArgFromJson('json', arg)),
            ])
            .awaited
            .code;
      }).closure
    ]).code;
  }
}

Library generateHandlers(List<FunctionDefinition> endpoints) {
  var library = LibraryBuilder();
  final handlerUrl = 'package:shorebird/handler.dart';

  // And the Handler in the allHandlers array.
  library.body.add(
    Field(
      (b) => b
        ..name = 'allHandlers'
        ..type = refer('List<Handler>', handlerUrl)
        ..assignment = literalList(
          endpoints.map(_handlerForEndpoint),
          refer('Handler', handlerUrl),
        ).code,
    ),
  );
  return library.build();
}

void writeLibrary(String path, Library library) {
  var emitter = DartEmitter(
    // The default is Allocator.none which does not collect imports.
    // Allocator() will collect imports and print them at the top of the file.
    allocator: Allocator(),
    orderDirectives: true, // Sort the imports.
    useNullSafetySyntax: true, // Use modern Dart.
  );
  var output = library.accept(emitter).toString();
  if (false) {
    output = DartFormatter().format(output);
  }
  File(path).writeAsStringSync(output);
}
