import 'package:json_annotation/json_annotation.dart';
import 'package:shorebird/datastore.dart';
import 'package:shorebird/shorebird.dart';

export 'package:mongo_dart/mongo_dart.dart' show ObjectId;
export 'package:shorebird/src/datastore_mongo.dart' show DataStoreRemote;
export 'package:shorebird/src/datastore_sembast.dart' show DataStoreLocal;
export 'package:shorebird/src/selector_builder.dart';

class ObjectIdConverter extends JsonConverter<ObjectId, String> {
  const ObjectIdConverter();

  @override
  ObjectId fromJson(String json) => ObjectId.fromHexString(json);

  @override
  String toJson(ObjectId object) => object.toHexString();
}

class DbJsonConverter {
  static Map<String, dynamic> toDbJson(Map<String, dynamic> json) {
    json['_id'] = ObjectId.fromHexString(json['id']);
    json.remove('id');
    return json;
  }

  static Map<String, dynamic> fromDbJson(Map<String, dynamic> json) {
    json['id'] = json['_id'].toHexString();
    json.remove('_id');
    return json;
  }
}

class ClassInfo<T> {
  final Type type;
  // Cannot be a static on T as far as I know.
  final String tableName;
  // Cannot be a method on T because it's a static.
  final T Function(Map<String, dynamic> dbJson) fromDbJson;
  // Could be a method on T, if we required a baseclass.
  final Map<String, dynamic> Function(T) toDbJson;

  const ClassInfo(this.tableName, this.fromDbJson, this.toDbJson) : type = T;
}

const where = SelectorBuilder();

abstract class DataStore {
  final Map<Type, ClassInfo> classInfoMap;

  DataStore(this.classInfoMap);

  static DataStore? _singleton;
  static DataStore get instance => _singleton!;

  // This is a hack for now.
  factory DataStore.of(AuthenticatedContext context) => _singleton!;

  static Future<void> initSingleton(DataStore dataStore) async {
    _singleton = dataStore;
    await _singleton!.init();
  }

  ClassInfo<T> classInfo<T>() => classInfoMap[T]! as ClassInfo<T>;

  Future<void> init();
  Future<void> close();
  Collection<T> collection<T>();
}

abstract class Collection<T> {
  final ClassInfo<T> classInfo;
  Collection(this.classInfo);

  Future<T?> byId(ObjectId id);

  Future<T?> findOne(SelectorBuilder selector);

  Stream<T> find(SelectorBuilder selector);

  Future<T> create(T object);
}
