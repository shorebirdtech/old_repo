import 'dart:io';

import 'package:mongo_dart/mongo_dart.dart' as mongo;

import '../datastore.dart';

extension SelectorBuilderMongo on SelectorBuilder {
  mongo.SelectorBuilder toMongo() {
    var mongoSelector = mongo.SelectorBuilder();
    for (var selector in selectors) {
      if (selector is IdSelector) {
        mongoSelector.id(selector.id);
      } else if (selector is EqSelector) {
        mongoSelector.eq(selector.field, selector.value);
      } else if (selector is LimitSelector) {
        mongoSelector.limit(selector.limit);
      } else if (selector is SortBySelector) {
        mongoSelector.sortBy(selector.field, descending: selector.descending);
      } else {
        throw UnsupportedError('Unsupported selector: $selector');
      }
    }
    return mongoSelector;
  }
}

class DataStoreRemote extends DataStore {
  late mongo.Db db;

  DataStoreRemote(super.classInfoMap);

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

  @override
  Collection<T> collection<T>() => CollectionMongo<T>(db, classInfo<T>());
}

class CollectionMongo<T> extends Collection<T> {
  final mongo.DbCollection _collection;
  CollectionMongo(mongo.Db db, super.classInfo)
      : _collection = db.collection(classInfo.tableName);

  @override
  Future<T?> byId(mongo.ObjectId id) async {
    var dbJson = await _collection.findOne(where.id(id).toMongo());
    if (dbJson == null) return null;
    return classInfo.fromDbJson(dbJson);
  }

  @override
  Future<T?> findOne(SelectorBuilder selector) async {
    var mongo = selector.toMongo();
    var dbJson = await _collection.findOne(mongo);
    if (dbJson == null) return null;
    return classInfo.fromDbJson(dbJson);
  }

  @override
  Stream<T> find(SelectorBuilder selector) {
    var mongo = selector.toMongo();
    return _collection.find(mongo).map(classInfo.fromDbJson);
  }

  @override
  Future<T> create(T object) async {
    var dbJson = classInfo.toDbJson(object);
    // Insert modifies dbJson (adds _id).
    await _collection.insert(dbJson);
    return classInfo.fromDbJson(dbJson);
  }

  // Future<void> deleteOne(ObjectId id) async {
  //   await _collection.remove(where.id(id));
  // }

  @override
  Stream<T> watchAdditions() {
    // Untested, from:
    // https://github.com/mongo-dart/mongo_dart/blob/rel-0-8/example/manual/watch/watch_on_collection_insert.dart
    return _collection.watch(<Map<String, Object>>[
      {
        r'$match': {'operationType': 'insert'}
      }
    ]).map((changeEvent) {
      return classInfo.fromDbJson(changeEvent.fullDocument);
    });
  }
}
