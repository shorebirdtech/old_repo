import 'package:shorebird/datastore.dart';

import '../model.dart';

final classInfoMap = <Type, ClassInfo>{
  Message: ClassInfo<Message>(
    tableName: 'messages',
    toJson: (value) => value.toJson(),
    fromJson: (value) => Message.fromJson(value),
  ),
};
