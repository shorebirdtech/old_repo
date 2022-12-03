import 'package:code_builder/code_builder.dart';

import 'types.dart';

Spec _generateArgsClass(FunctionDefinition endpoint) {
  var args = endpoint.serializedArgs;
  if (args.isEmpty) {
    return Code('');
  }
  var argsClass = ClassBuilder();
  argsClass.name = endpoint.argsClassName;
  argsClass.fields.addAll(args.map((arg) {
    return Field((b) => b
      ..name = arg.name
      ..type = arg.typeReference
      ..modifier = FieldModifier.final$);
  }));
  argsClass.constructors.add(Constructor((b) => b
    ..requiredParameters.addAll(args.map((arg) {
      return Parameter((b) => b
        ..name = arg.name
        ..toThis = true);
    }))));
  argsClass.constructors.add(Constructor((b) => b
    ..name = 'fromJson'
    ..requiredParameters.add(Parameter((b) => b
      ..name = 'json'
      ..type = refer('Map<String, dynamic>')))
    ..initializers.addAll(args.map((arg) {
      return Code('''${arg.name} = json['${arg.name}'] as ${arg.type.name}''');
    }))));

  argsClass.methods.add(Method((b) => b
    ..name = 'toJson'
    ..returns = refer('Map<String, dynamic>')
    ..body = Code('''
        return {
          ${args.map((arg) => "'${arg.name}': ${arg.name}").join(',\n')}
        };
      ''')));
  return argsClass.build();
}

// This should get folded into _generateArgsClass
// Expression _extractTypedArgFromJson(String jsonName, ParameterDefinition arg) {
//   if (arg.type.isPrimitive) {
//     return refer(jsonName)
//         .index(literalString(arg.name))
//         .asA(arg.typeReference);
//   } else {
//     return arg.typeReference.property('fromJson').call([
//       refer(jsonName)
//           .index(literalString(arg.name))
//           .asA(refer('Map<String, dynamic>'))
//     ]);
//   }
// }

Code _handlerForEndpoint(FunctionDefinition endpoint) {
  // Stream endpoints need to be converted to Stream<Json> and
  // also not awaited, but are otherwise very similar
  // to simpleCall endpoints.

  var argsFromJson = endpoint.serializedArgs.isEmpty
      ? Code('')
      : declareFinal('args')
          .assign(endpoint.argsTypeReference
              .property('fromJson')
              .call([refer('json')]))
          .statement;
  var handlerParameters = [
    Parameter((p) => p.name = 'context'),
    Parameter((p) => p.name = 'json')
  ];
  var endpointArgs = [
    refer('context'),
    ...endpoint.serializedArgs.map((arg) => refer('args').property(arg.name)),
  ];

  if (endpoint.returnsStream) {
    return refer('Handler', handlerUrl).property('stream').call([
      literalString(endpoint.name),
      Method((f) {
        f.requiredParameters.addAll(handlerParameters);
        f.body = Block.of([
          argsFromJson,
          endpoint.reference
              .call(endpointArgs)
              .property('asyncMap')
              .call([
                Method((c) {
                  c.requiredParameters
                      .add(Parameter((p) => p.name = 'element'));
                  c.body = refer('element').property('toJson').call([]).code;
                }).closure
              ])
              .returned
              .statement,
        ]);
      }).closure
    ]).code;
  } else {
    return refer('Handler', handlerUrl).property('simpleCall').call([
      literalString(endpoint.name),
      Method((f) {
        f.requiredParameters.addAll(handlerParameters);
        f.modifier = MethodModifier.async;
        f.body = Block.of([
          argsFromJson,
          endpoint.reference.call(endpointArgs).awaited.returned.statement,
        ]);
      }).closure
    ]).code;
  }
}

Library generateHandlers(List<FunctionDefinition> endpoints) {
  var library = LibraryBuilder();

  library.body.addAll(endpoints.map(_generateArgsClass));

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
