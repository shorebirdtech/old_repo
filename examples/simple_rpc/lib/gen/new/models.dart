// Generated by `dart run shorebird generate`.
import 'package:shorebird/datastore.dart';
import 'package:simple_rpc/model.dart';

Map<Type, ClassInfo> classInfoMap = {
  Message: ClassInfo<Message>(
    tableName: 'message',
    toJson: (value) => value.toJson(),
    fromJson: (value) => Message.fromJson(value),
  )
};
