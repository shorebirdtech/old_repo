import 'package:code_builder/code_builder.dart';

import 'types.dart';

Method _clientMethodForEndpoint(FunctionDefinition endpoint) {
  // If the endpoint has args, build an Args class and serialize it.
  var assignArgs = endpoint.serializedArgs.isEmpty
      ? Code('')
      : declareFinal('body')
          .assign(endpoint.argsTypeReference
              .call(endpoint.serializedArgs.map((arg) => refer(arg.name)))
              .property('toJson')
              .call([]))
          .statement;

  var fromJsonMethod = endpoint.innerReturnType.fromJsonMethod;
  // Call the right client method based on the endpoint's return type.
  late Expression call;
  if (endpoint.returnsStream) {
    call = refer('watch')
        .call([
          literalString(endpoint.handlerPath),
          if (endpoint.serializedArgs.isNotEmpty) refer('body'),
        ])
        .property('map')
        .call([fromJsonMethod]);
  } else {
    // Returns Future<T>
    call = refer('post').call([
      literalString(endpoint.handlerPath),
      if (endpoint.serializedArgs.isNotEmpty) refer('body'),
    ]);
    var resultType = endpoint.innerReturnType;
    if (!resultType.isVoid) {
      call = call
          .property('then')
          .call([
            refer('extractResponse<${resultType.networkTypeReference.symbol}>',
                shorebirdUrl)
          ])
          .property('then')
          .call([fromJsonMethod]);
    }
  }
  var method = MethodBuilder();
  method.name = endpoint.name;
  method.returns = endpoint.returnTypeReference;
  method.requiredParameters.addAll(endpoint.serializedArgs.map((arg) {
    return Parameter((b) => b
      ..name = arg.name
      ..type = arg.typeReference);
  }));
  method.body = Block.of([
    assignArgs,
    call.returned.statement,
  ]);
  return method.build();
}

Library generateClient(List<FunctionDefinition> endpoints) {
  final clientUrl = 'package:shorebird/shorebird.dart';
  var library = LibraryBuilder();

  library.directives.add(Directive.export(clientUrl, show: ['Client']));

  var client = ExtensionBuilder()
    ..name = 'HandlerExtensions'
    ..on = refer('Client', clientUrl)
    ..methods.addAll(endpoints.map(_clientMethodForEndpoint));
  library.body.add(client.build());
  return library.build();
}
