import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

import '../datastore.dart';

class IdSelector extends Selector {
  final ObjectId id;

  IdSelector(this.id);
}

class EqSelector extends Selector {
  final String field;
  final dynamic value;

  EqSelector(this.field, this.value);
}

extension SelectorBuilderSembast on SelectorBuilder {
  Finder toSembast() {
    int? limit;
    List<SortOrder> sortOrders = [];
    Filter? filter;

    for (var selector in selectors) {
      if (selector is LimitSelector) {
        if (limit != null) {
          throw StateError('Limit already set');
        }
        limit = selector.limit;
      } else if (selector is SortBySelector) {
        sortOrders.add(SortOrder(selector.field, !selector.descending));
      } else if (selector is IdSelector) {
        if (filter != null) {
          throw StateError('Filter already set');
        }
        filter = Filter.byKey(selector.id.id);
      } else if (selector is EqSelector) {
        if (filter != null) {
          throw StateError('Filter already set');
        }
        filter = Filter.equals(selector.field, selector.value);
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
  final String dbPath;

  DataStoreLocal(super.classInfoMap, this.dbPath);

  @override
  Future<void> init() async {
    db = await databaseFactoryIo.openDatabase(dbPath);
  }

  @override
  Future<void> close() {
    return db.close();
  }

  @override
  Collection<T> collection<T>() => CollectionSembast<T>(db, classInfo<T>());
}

class CollectionSembast<T> extends Collection<T> {
  Database db;
  final StoreRef<String, Map<String, dynamic>> store;

  CollectionSembast(this.db, super.classInfo)
      : store = stringMapStoreFactory.store(classInfo.tableName);

  @override
  Future<T?> byId(ObjectId id) {
    return store.record(id.$oid).get(db).then((dbJson) {
      if (dbJson == null) return null;
      return classInfo.fromDbJson(dbJson);
    });
  }

  @override
  Future<T?> findOne(SelectorBuilder selector) {
    return store.find(db, finder: selector.toSembast()).then((records) {
      if (records.isEmpty) return null;
      return classInfo.fromDbJson(records.first.value);
    });
  }

  @override
  Stream<T> find(SelectorBuilder selector) async* {
    var records = await store.find(db, finder: selector.toSembast());
    for (var record in records) {
      yield classInfo.fromDbJson(record.value);
    }
  }

  @override
  Future<T> create(T object) {
    var dbJson = classInfo.toDbJson(object);
    return store.add(db, dbJson).then((id) {
      dbJson['_id'] = id;
      return classInfo.fromDbJson(dbJson);
    });
  }
}
