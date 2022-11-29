import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shorebird/datastore.dart';
import 'package:shorebird/shorebird.dart';

export 'package:mongo_dart/mongo_dart.dart' show ObjectId;

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

// Modeled after mongo_dart_query which is the best query builder I've seen.
// Suggestions welcome for something better. :)
// https://pub.dev/documentation/mongo_dart_query/latest/mongo_dart_query/SelectorBuilder-class.html
// If we built our own (without depending on mongo) this should be immutable.
class SelectorBuilder {
  final mongo.SelectorBuilder _mongo; // mutable!
  SelectorBuilder._(this._mongo);

  mongo.SelectorBuilder toMongo() => _mongo;

  SelectorBuilder id(mongo.ObjectId id) {
    _mongo.id(id);
    return this;
  }

  SelectorBuilder eq(String field, Object value) {
    _mongo.eq(field, value);
    return this;
  }

  SelectorBuilder limit(int limit) {
    _mongo.limit(limit);
    return this;
  }

  SelectorBuilder sortBy(String field, {bool descending = false}) {
    _mongo.sortBy(field, descending: descending);
    return this;
  }
}

// Bleh.  Mongo's SelectorBuidler mutates itself in place. :/
SelectorBuilder get where => SelectorBuilder._(mongo.where);

class Collection<T> {
  final mongo.DbCollection _collection;
  final ClassInfo<T> _classInfo;
  Collection(mongo.Db db, this._classInfo)
      : _collection = db.collection(_classInfo.tableName);

  Future<T?> byId(mongo.ObjectId id) async {
    var dbJson = await _collection.findOne(where.id(id).toMongo());
    if (dbJson == null) return null;
    return _classInfo.fromDbJson(dbJson);
  }

  Future<T?> findOne(SelectorBuilder selector) async {
    var mongo = selector.toMongo();
    var dbJson = await _collection.findOne(mongo);
    if (dbJson == null) return null;
    return _classInfo.fromDbJson(dbJson);
  }

  Stream<T> find(SelectorBuilder selector) {
    var mongo = selector.toMongo();
    return _collection.find(mongo).map(_classInfo.fromDbJson);
  }

  Future<T> create(T object) async {
    var dbJson = _classInfo.toDbJson(object);
    // Insert modifies dbJson (adds _id).
    await _collection.insert(dbJson);
    return _classInfo.fromDbJson(dbJson);
  }

  // Future<void> deleteOne(ObjectId id) async {
  //   await _collection.remove(where.id(id));
  // }
}

abstract class DataStore {
  static DataStore? _singleton;
  static DataStore get instance => _singleton!;

  DataStore._();

  factory DataStore.of(AuthenticatedContext context) => _singleton!;

  static Future<void> initSingleton(DataStore dataStore) async {
    _singleton = dataStore;
    await _singleton!.init();
  }

  Future<void> init();
  Future<void> close();
  Collection<T> collection<T>();
}

class DataStoreRemote extends DataStore {
  late mongo.Db db;
  final Map<Type, ClassInfo> classInfoMap;

  DataStoreRemote(this.classInfoMap) : super._();

  @override
  Future<void> init() async {
    // Specified in digial ocean's environment settings:
    // https://docs.digitalocean.com/products/app-platform/how-to/use-environment-variables/#define-build-time-environment-variables
    final mongoUrl = Platform.environment['DATABASE_URL'];
    if (mongoUrl == null) {
      throw Exception('DATABASE_URL environment variable is not set.');
    }
    db = await mongo.Db.create(mongoUrl);
    await db.open();
  }

  @override
  Future<void> close() async => await db.close();

  ClassInfo<T> classInfo<T>() => classInfoMap[T]! as ClassInfo<T>;

  @override
  Collection<T> collection<T>() => Collection<T>(db, classInfo<T>());
}
