import 'package:shorebird/datastore.dart';

import '../model.dart';

var classInfoMap = <Type, ClassInfo>{
  Message: ClassInfo<Message>(
    tableName: 'messages',
    fromDbJson: (value) => Message.fromJson(DbJsonConverter.fromDbJson(value)),
    toDbJson: (value) => DbJsonConverter.toDbJson(value.toJson()),
    toJson: (value) => value.toJson(),
    fromJson: (value) => Message.fromJson(value),
  ),
};
