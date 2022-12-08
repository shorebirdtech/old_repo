import 'package:shorebird/datastore.dart';

// If/When dart gets unions, this should use one.
// Or maybe just used package: freezed?
// These are public to be shared between implementations (remote/local)
// but not exported to users.
class Selector {}

class IdSelector extends Selector {
  final ObjectId id;

  IdSelector(this.id);
}

class EqSelector extends Selector {
  final String field;
  final dynamic value;

  EqSelector(this.field, this.value);
}

class LimitSelector extends Selector {
  final int limit;

  LimitSelector(this.limit);
}

class SortBySelector extends Selector {
  final String field;
  final bool descending;

  SortBySelector(this.field, {this.descending = false});
}

class GteSelector extends Selector {
  final String field;
  final dynamic value;

  GteSelector(this.field, this.value);
}

class LteSelector extends Selector {
  final String field;
  final dynamic value;

  LteSelector(this.field, this.value);
}

// Modeled after mongo_dart_query which is the best query builder I've seen.
// Suggestions welcome for something better. :)
// https://pub.dev/documentation/mongo_dart_query/latest/mongo_dart_query/SelectorBuilder-class.html
// Unlike mongo_dart_query, this is immutable.
class SelectorBuilder {
  final List<Selector> selectors;
  const SelectorBuilder([this.selectors = const []]);

  SelectorBuilder id(ObjectId id) =>
      SelectorBuilder([...selectors, IdSelector(id)]);

  SelectorBuilder eq(String field, Object value) =>
      SelectorBuilder([...selectors, EqSelector(field, value)]);

  SelectorBuilder gte(String field, Object value) =>
      SelectorBuilder([...selectors, GteSelector(field, value)]);

  SelectorBuilder lte(String field, Object value) =>
      SelectorBuilder([...selectors, LteSelector(field, value)]);

  SelectorBuilder limit(int limit) =>
      SelectorBuilder([...selectors, LimitSelector(limit)]);

  SelectorBuilder sortBy(String field, {bool descending = false}) =>
      SelectorBuilder(
          [...selectors, SortBySelector(field, descending: descending)]);
}
