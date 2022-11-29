import 'package:json_annotation/json_annotation.dart';
import 'package:shorebird/datastore.dart';

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


// import 'shorebird.dart';

// /// Abstract API to hide details of Database ORM (which will likely change).

// abstract class Collection {
//   String get name;
//   Future<void> init();
//   Future<void> close();
// }

// abstract class Finder {
//   Finder();
// }

// abstract class DataStore {
//   static final DataStore _singleton = DataStore();
//   static DataStore get instance => _singleton;

//   factory DataStore.of(AuthenticatedContext context) => _singleton;

//   Future<void> init();
// }
