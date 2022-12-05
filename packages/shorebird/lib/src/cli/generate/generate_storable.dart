import 'package:code_builder/code_builder.dart';

import 'types.dart';

// final classInfoMap = <Type, ClassInfo>{
//   Message: ClassInfo<Message>(
//     tableName: 'messages',
//     toJson: (value) => value.toJson(),
//     fromJson: (value) => Message.fromJson(value),
//   ),
// };

Library generateStorable(List<ClassDefinition> models) {
  final classInfoUrl = 'package:shorebird/datastore.dart';
  var library = LibraryBuilder();

  var typeToClassInfo = <Reference, Expression>{};
  for (var model in models) {
    var classType = model.type.typeReference;
    var tableName = model.name.toLowerCase();
    // Too verbose: https://github.com/dart-lang/code_builder/issues/382
    // var toJson = Method((m) => m
    //   ..requiredParameters.add(Parameter((p) => p.name = 'value'))
    //   ..body = refer('value').property('toJson').call([]).code).closure;
    var classInfo =
        refer('ClassInfo<${model.type.name}>', classInfoUrl).call([], {
      'tableName': literalString(tableName),
      'toJson': CodeExpression(Code('(value) => value.toJson()')),
      'fromJson':
          CodeExpression(Code('(value) => ${model.type.name}.fromJson(value)')),
    });
    typeToClassInfo[classType] = classInfo;
  }

  library.body.add(
    Field((f) {
      f.name = 'classInfoMap';
      f.type = refer('Map<Type, ClassInfo>', classInfoUrl);
      f.assignment = literalMap(typeToClassInfo).code;
      f.modifier = FieldModifier.final$;
    }),
  );
  return library.build();
}
