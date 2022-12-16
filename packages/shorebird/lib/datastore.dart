/// This file contains the abstract interfaces for the datastore.
/// Libraries defining [Endpoint]s likely wish to include this library
/// to acccess the [DataStore] interface.
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

/// This is needed to perform the cast from ClassInfo<dynamic> to ClassInfo<T>
/// Since Map<Type, ClassInfo<dynamic>> is intentionally dynamic.
ClassInfo<T> lookupClassInfo<T>(Map<Type, ClassInfo> classInfoMap) {
  var classInfo = classInfoMap[T];
  if (classInfo == null) {
    throw ArgumentError('No ClassInfo for $T');
  }
  return classInfo as ClassInfo<T>;
}

/// Used for building queries for the datastore.
/// e.g. where.eq('name', 'Bob').gt('age', 18).limit(10)
const where = SelectorBuilder();

/// Abstract interface to the datastore.
/// This is currently used as a singleton, and should be initialized with a
/// concrete implementation.
/// e.g. await DataStore.initSingleton(DataStoreRemote());
/// LocalDataStore is used when storing locally in a file.
/// RemoteDataStore is used when connecting to a remote database.
abstract class DataStore {
  final Map<Type, ClassInfo> classInfoMap;

  /// DataStore superclass holds the classInfoMap, which is used to lookup
  /// static information about classes such as toJson/fromJson methods.
  DataStore(this.classInfoMap);

  static DataStore? _singleton;
  static DataStore get instance => _singleton!;

  /// Look up the DataStore for the current request context.
  /// The current implementation is a hack and just returns a singleton.
  factory DataStore.of(AuthenticatedContext context) => _singleton!;

  /// Initialize the singleton DataStore.
  /// This should be called before using the DataStore typically in main().
  /// e.g. await DataStore.initSingleton(DataStoreRemote());
  /// `shorebird generate` will generate a server() which calls this.
  static Future<void> initSingleton(DataStore dataStore) async {
    _singleton = dataStore;
    await _singleton!.init();
  }

  /// The classInfoMap containing the ClassInfo for models which may be
  /// stored in the datastore.
  ClassInfo<T> classInfo<T>() => classInfoMap[T]! as ClassInfo<T>;

  /// Subclasses must implement this to initialize the datastore.
  Future<void> init();

  /// Subclasses must implement this to close the datastore.
  Future<void> close();

  /// Subclasses must implement this to return a collection for the given type.
  /// Collection is the main interace for querying and updating a given
  /// collection/table in the datastore.
  Collection<T> collection<T>();
}

/// Abstract baseclass for Collections of a specific type.
/// DataStore subclasses must implement this to return a Collection
/// which knows how to query and update a given collection/table in the
/// datastore corresponding to a type.
abstract class Collection<T> {
  /// Collection base class hols the classInfo, which is used to lookup
  /// static information about the type such as toJson/fromJson methods.
  final ClassInfo<T> classInfo;

  Collection(this.classInfo);

  /// Subclasses must implement this to return a single object by id.
  Future<T?> byId(ObjectId id);

  /// Subclasses must implement this to return a single object found with the
  /// given selector.
  Future<T?> findOne(SelectorBuilder selector);

  /// Subclasses must implement this to return a stream of objects found with
  /// the given selector.
  Stream<T> find(SelectorBuilder selector);

  /// Subclasses must implement this to create a single object in the datastore.
  Future<T> create(T object);

  /// Subclasses must implement this to create multiple objects in the datastore.
  Future<List<T>> createMany(List<T> objects);

  /// Subclasses must implement this to update a single object by id.
  /// The update function is passed the current object and should return
  /// the updated object.
  Future<void> update(ObjectId id, T Function(T object) update);

  /// Subclasses must implement this to return a stream of objects as they
  /// are added to the collection.
  Stream<T> watchAdditions();
}
