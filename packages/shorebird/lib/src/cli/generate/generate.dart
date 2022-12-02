import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

import 'types.dart';

String importPrefix = '../..';

extension EndpointGeneration on FunctionDefinition {
  String get importUrl {
    var fileName = p.basename(path);
    return "$importPrefix/$fileName";
  }
}

Library generateHandlers(List<FunctionDefinition> endpoints) {
  var library = LibraryBuilder();
  final shorebirdUrl = 'package:shorebird/shorebird.dart';

  for (var endpointDef in endpoints) {
    library.body.add(Class((endpoint) {
      endpoint.name = endpointDef.handlerName;
      endpoint.extend = refer('ShorebirdHandler', shorebirdUrl);

      endpoint.fields.add(Field((field) {
        field.name = 'endpoint';
        field.modifier = FieldModifier.final$;
        field.type = refer(endpointDef.name, endpointDef.importUrl);
      }));

      endpoint.constructors.add(Constructor((c) {
        c.requiredParameters.add(Parameter((p) {
          p.name = 'endpoint';
          p.toThis = true;
        }));
      }));

      endpoint.methods.add(Method((m) {
        m.annotations.add(refer('override'));
        m.name = 'collectRoutes';
        m.returns = refer('void');
        m.requiredParameters.add(Parameter((p) {
          p.name = 'router';
          p.type = refer('Router', shorebirdUrl);
        }));
        m.body = Code('''
          router.addRoute(
            Route(
              method: HttpMethod.post,
              path: '/send_message',
              handler: sendMessage,
            ),
          );
          router.addRoute(
            Route(
              method: HttpMethod.get,
              path: '/new_messages',
              handler: newMessages,
            ),
          );
        ''');
      }));
    }));
  }
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
  var formatter = DartFormatter();
  var output = formatter.format('${library.accept(emitter)}');
  File(path).writeAsStringSync(output);
}
