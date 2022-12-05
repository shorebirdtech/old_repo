import 'package:code_builder/code_builder.dart';

import 'types.dart';

Method _clientMethodForEndpoint(FunctionDefinition endpoint) {
  var body = endpoint.serializedArgs.isEmpty
      ? Code('')
      : declareFinal('body')
          .assign(endpoint.argsTypeReference
              .call(endpoint.serializedArgs.map((arg) => refer(arg.name)))
              .property('toJson')
              .call([]))
          .statement;

  var method = MethodBuilder();
  method.name = endpoint.name;
  method.returns = endpoint.returnTypeReference;
  method.requiredParameters.addAll(endpoint.serializedArgs.map((arg) {
    return Parameter((b) => b
      ..name = arg.name
      ..type = arg.typeReference);
  }));
  if (endpoint.returnsStream) {
    method.body = Block.of([
      body,
      refer('watch')
          .call([
            literalString(endpoint.handlerPath),
            if (endpoint.serializedArgs.isNotEmpty) refer('body'),
          ])
          .property('map')
          .call([endpoint.innserReturnTypeReference.property('fromJson')])
          .returned
          .statement,
    ]);
  } else {
    method.body = Block.of([
      body,
      refer('post')
          .call([
            literalString(endpoint.handlerPath),
            if (endpoint.serializedArgs.isNotEmpty) refer('body'),
          ])
          .returned
          .statement,
    ]);
  }
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
