/// Includes annotations used by Shorebird.

/// Denotes the function as an entrypoint for serverless execution.
/// e.g.
/// ```
/// import 'package:shorebird/annotations.dart';
/// import 'package:shorebird/shorebird.dart';
/// @Endpoint()
/// Future<String> helloWorld(RequestContext context) {
///  return Future.value('Hello World');
/// }
/// ```
/// `shorebird generate` will generate server and client code for this function.
class Endpoint {
  const Endpoint();
}

/// Denotes the class can be stored in the datastore.
/// Classes with this annotation are expected to have a field named `id` of type
/// `ObjectId` as well as (currently) provide their own toJson/fromJson methods.
///
/// Example:
/// ```
/// import 'package:shorebird/annotations.dart';
/// import 'package:shorebird/shorebird.dart';
///
/// @Storable()
/// class User {
///  ObjectId id;
///  String name;
///  User(this.name);
/// }
/// ```
///
/// `shorebird generate` will generate ClassInfo<T> for this class which
/// include methods for storing and retrieving the class from the datastore.
///
/// `shorebird generate` does not *yet* know how to generate toJson/fromJson
/// methods (but hopefully it will soon), so you will need to implement those
/// yourself or use json_serializable to do so.
///
/// If you use JsonSerializable, you will also need to use the
/// @ObjectIdConverter() annotation on the class.
class Storable {
  const Storable();
}

/// Denotes the class can be sent over the network.
/// `shorebird generate` will generate ClassInfo<T> for this class which
/// include pointers to methods for converting the class to/from json.
///
/// `shorebird generate` does not *yet* know how to generate toJson/fromJson
/// methods (but hopefully it will soon), so you will need to implement those
/// yourself or use json_serializable to do so.
class Transportable {
  const Transportable();
}
