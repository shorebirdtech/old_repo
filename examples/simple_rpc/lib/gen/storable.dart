import 'package:shorebird/datastore.dart';

import '../model.dart';

var classInfoMap = <Type, ClassInfo>{
  Message: ClassInfo<Message>(
    tableName: 'messages',
    toJson: (value) => value.toJson(),
    fromJson: (value) => Message.fromJson(value),
  ),
};
