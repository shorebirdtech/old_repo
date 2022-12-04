import 'package:json_annotation/json_annotation.dart';
import 'package:shorebird/annotations.dart';
import 'package:shorebird/datastore.dart';
import 'package:shorebird/shorebird.dart';

export 'package:mongo_dart/mongo_dart.dart' show ObjectId;
export 'package:shorebird/src/datastore/datastore_mongo.dart'
    show DataStoreRemote;
export 'package:shorebird/src/datastore/datastore_sembast.dart'
    show DataStoreLocal;
export 'package:shorebird/src/datastore/selector_builder.dart';

/// Annotation for json_serializable to generate a fromJson and toJson method
/// for ObjectId
/// Should be removed once [Storable] is implemented.
class ObjectIdConverter extends JsonConverter<ObjectId, String> {
  const ObjectIdConverter();

  @override
  ObjectId fromJson(String json) => ObjectId.fromHexString(json);

  @override
  String toJson(ObjectId object) => object.toHexString();
}

/// Used to lookup type information for a given class.  One will be generated
/// for each class annotated with [Transportable] or [Storable].
class ClassInfo<T> {
  final Type type;
  // Cannot be a static on T as far as I know.
  final String tableName;
  // // Cannot be a method on T because it's a static.
  // final T Function(Map<String, dynamic> dbJson) fromDbJson;
  // // Could be a method on T, if we required a baseclass.
  // final Map<String, dynamic> Function(T) toDbJson;

  // Cannot be a method on T because it's a static.
  final T Function(Map<String, dynamic> json) fromJson;
  // Could be a method on T, if we required a baseclass.
  final Map<String, dynamic> Function(T) toJson;

  const ClassInfo({
    required this.tableName,
    // required this.fromDbJson,
    // required this.toDbJson,
    required this.fromJson,
    required this.toJson,
  }) : type = T;
}

// This is needed to perform the cast from ClassInfo<dynamic> to ClassInfo<T>
// Since Map<Type, ClassInfo<dynamic>> is intentionally dynamic.
ClassInfo<T> lookupClassInfo<T>(Map<Type, ClassInfo> classInfoMap) {
  var classInfo = classInfoMap[T];
  if (classInfo == null) {
    throw ArgumentError('No ClassInfo for $T');
  }
  return classInfo as ClassInfo<T>;
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

  // This should be add?
  Future<T> create(T object);

  Stream<T> watchAdditions();
}
