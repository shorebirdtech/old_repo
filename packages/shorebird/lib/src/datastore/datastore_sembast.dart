import 'dart:async';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

import '../../datastore.dart';

extension SelectorBuilderSembast on SelectorBuilder {
  Finder toSembast() {
    int? limit;
    List<SortOrder> sortOrders = [];
    Filter? filter;

    void setFilter(Filter newFilter) {
      if (filter != null) {
        throw StateError('Filter already set');
      }
      filter = newFilter;
    }

    for (var selector in selectors) {
      if (selector is LimitSelector) {
        if (limit != null) {
          throw StateError('Limit already set');
        }
        limit = selector.limit;
      } else if (selector is SortBySelector) {
        sortOrders.add(SortOrder(selector.field, !selector.descending));
      } else if (selector is IdSelector) {
        setFilter(Filter.byKey(_fromObjectIdToSembastKey(selector.id)));
      } else if (selector is EqSelector) {
        setFilter(Filter.equals(selector.field, selector.value));
      } else if (selector is GteSelector) {
        setFilter(Filter.greaterThanOrEquals(selector.field, selector.value));
      } else if (selector is LteSelector) {
        setFilter(Filter.lessThanOrEquals(selector.field, selector.value));
      } else {
        throw Exception('Unsupported selector: $selector');
      }
    }

    return Finder(
      filter: filter,
      sortOrders: sortOrders,
      limit: limit,
    );
  }
}

class DataStoreLocal extends DataStore {
  late Database db;
  final String path;

  DataStoreLocal(super.classInfoMap, {this.path = 'local_datastore.json'});

  @override
  Future<void> init() async {
    db = await databaseFactoryIo.openDatabase(path);
  }

  @override
  Future<void> close() {
    return db.close();
  }

  @override
  Collection<T> collection<T>() => CollectionSembast<T>(db, classInfo<T>());
}

typedef SembastKey = int;

ObjectId _fromSembastKeyToObjectId(SembastKey key) {
  var paddedHex = key.toRadixString(16).padLeft(24, '0');
  return ObjectId.fromHexString(paddedHex);
}

SembastKey _fromObjectIdToSembastKey(ObjectId id) {
  return int.parse(id.toHexString(), radix: 16);
}

class CollectionSembast<T> extends Collection<T> {
  Database db;
  // Use int keys with sembast to ensure they are smaller than ObjectId keys
  // used by mongo (and currently the Shorebird API).
  final StoreRef<SembastKey, Map<String, dynamic>> store;

  CollectionSembast(this.db, super.classInfo)
      : store = intMapStoreFactory.store(classInfo.tableName);

  T _fromDbJson(Map<String, dynamic> dbJson, SembastKey key) {
    dbJson = Map<String, dynamic>.from(dbJson);
    dbJson['id'] = _fromSembastKeyToObjectId(key).$oid;
    return classInfo.fromJson(dbJson);
  }

  Map<String, dynamic> _toDbJson(T value) {
    var json = classInfo.toJson(value);
    // This ignores the passed id, which is different than what mongo does.
    // https://www.mongodb.com/docs/manual/reference/method/db.collection.insert/
    json.remove('id');
    return json;
  }

  @override
  Future<T?> byId(ObjectId id) async {
    var key = _fromObjectIdToSembastKey(id);
    var dbJson = await store.record(key).get(db);
    if (dbJson == null) return null;
    return _fromDbJson(dbJson, key);
  }

  @override
  Future<T?> findOne(SelectorBuilder selector) async {
    var record = await store.findFirst(db, finder: selector.toSembast());
    if (record == null) return null;
    return _fromDbJson(record.value, record.key);
  }

  @override
  Stream<T> find(SelectorBuilder selector) async* {
    var records = await store.find(db, finder: selector.toSembast());
    for (var record in records) {
      yield _fromDbJson(record.value, record.key);
    }
  }

  @override
  Future<T> create(T object) async {
    // This ignores the passed id, which is different than what mongo does.
    // https://www.mongodb.com/docs/manual/reference/method/db.collection.insert/
    var dbJson = _toDbJson(object); // removes id from json.
    var id = await store.add(db, dbJson);
    return _fromDbJson(dbJson, id);
  }

  @override
  Future<List<T>> createMany(List<T> objects) async {
    var dbJsons = objects.map(_toDbJson).toList();
    var ids = await store.addAll(db, dbJsons);
    return List.generate(
      ids.length,
      (i) => _fromDbJson(dbJsons[i], ids[i]),
    );
  }

  @override
  Future<void> update(ObjectId id, T Function(T) update) {
    return db.transaction((txn) async {
      var key = _fromObjectIdToSembastKey(id);
      var dbJson = await store.record(key).get(txn);
      if (dbJson == null) {
        throw Exception('No record found for id: $id');
      }
      var object = _fromDbJson(dbJson, key);
      var updatedObject = update(object);
      var updatedDbJson = _toDbJson(updatedObject);
      await store.record(key).put(txn, updatedDbJson);
    });
  }

  @override
  Stream<T> watchAdditions() {
    // https://github.com/tekartik/sembast.dart/blob/master/sembast/doc/new_api.md#listen-to-changes
    bool seenFirstUpdate = false;
    Set<SembastKey> seenRecords = {};

    late StreamController<T> controller;

    // This is like stream.expand, except we cancel the inner stream when the
    // outer is canceled.  Maybe there is a better way?
    var subscription = store.query().onSnapshots(db).listen((snapshots) {
      if (!seenFirstUpdate) {
        seenFirstUpdate = true;
        seenRecords = snapshots.map((snapshot) => snapshot.key).toSet();
        return;
      }
      for (var snapshot in snapshots) {
        if (seenRecords.contains(snapshot.key)) continue;
        seenRecords.add(snapshot.key);
        controller.add(_fromDbJson(snapshot.value, snapshot.key));
      }
    });
    controller = StreamController<T>(
      onListen: () {
        subscription.resume();
      },
      onPause: () {
        subscription.pause();
      },
      onCancel: () {
        subscription.cancel();
      },
    );
    return controller.stream;
  }
}
