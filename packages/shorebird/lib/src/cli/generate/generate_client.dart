import 'package:code_builder/code_builder.dart';

import 'types.dart';

Method _clientMethodForEndpoint(FunctionDefinition endpoint) {
  // If the endpoint has args, build an Args class and serialize it.
  var args = endpoint.serializedParameters;
  var assignArgs = args.isEmpty
      ? Code('')
      : declareFinal('body')
          .assign(endpoint.argsTypeReference
              .call(args.positional.map((arg) => refer(arg.name)),
                  {for (var arg in args.named) arg.name: refer(arg.name)})
              .property('toJson')
              .call([]))
          .statement;

  // Call the right client method based on the endpoint's return type.
  var fromJsonClosure = Method((m) => m
        ..requiredParameters.add(Parameter((p) => p.name = 'e'))
        ..body =
            endpoint.innerReturnType.fromJson(refer('e')).returned.statement)
      .closure;
  late Expression call;
  if (endpoint.returnsStream) {
    call = refer('watch')
        .call([
          literalString(endpoint.handlerPath),
          if (args.isNotEmpty) refer('body'),
        ])
        .property('map')
        .call([fromJsonClosure]);
  } else {
    // Returns Future<T>
    call = refer('post').call([
      literalString(endpoint.handlerPath),
      if (args.isNotEmpty) refer('body'),
    ]);
    var resultType = endpoint.innerReturnType;
    if (!resultType.isVoid) {
      call = call
          .property('then')
          .call([
            refer('extractResponse<${resultType.networkTypeReferenceString}>',
                shorebirdUrl)
          ])
          .property('then')
          .call([fromJsonClosure]);
    }
  }
  var method = MethodBuilder();
  method.name = endpoint.name;
  method.returns = endpoint.returnTypeReference;
  method.requiredParameters.addAll(args.buildRequiredParameters());
  method.optionalParameters.addAll(args.buildOptionalParameters());
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
