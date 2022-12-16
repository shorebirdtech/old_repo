import 'package:shorebird/datastore.dart';

// If/When dart gets unions, this should use one.
// Or maybe just used package: freezed?
// These are public to be shared between implementations (remote/local)
// but not exported to users.

/// Baseclass for all selectors.  Never instantiated directly.
/// Selectors are never built directly, but instead through [SelectorBuilder].
class Selector {}

/// Selector for looking up by id.
class IdSelector extends Selector {
  final ObjectId id;

  IdSelector(this.id);
}

/// Selector for testing a field for a specific value.
class EqSelector extends Selector {
  final String field;
  final dynamic value;

  EqSelector(this.field, this.value);
}

/// Selector for limiting the number of results.
class LimitSelector extends Selector {
  final int limit;

  LimitSelector(this.limit);
}

/// Selector for sorting results.
class SortBySelector extends Selector {
  final String field;
  final bool descending;

  SortBySelector(this.field, {this.descending = false});
}

/// Selector for testing a field for a value greater than or equal to.
class GteSelector extends Selector {
  final String field;
  final dynamic value;

  GteSelector(this.field, this.value);
}

/// Selector for testing a field for a value less than or equal to.
class LteSelector extends Selector {
  final String field;
  final dynamic value;

  LteSelector(this.field, this.value);
}

// Modeled after mongo_dart_query:
// https://pub.dev/documentation/mongo_dart_query/latest/mongo_dart_query/SelectorBuilder-class.html
// Suggestions welcome for something better. :)
/// The main interface through which Selectors are built.
/// This is modeled after mongo_dart_query, however unlike mongo_dart_query
/// this is immutable.
/// Typically used via the global [where] variable.
/// e.g. where.eq('name', 'Bob').gt('age', 18).limit(10)
class SelectorBuilder {
  final List<Selector> selectors;
  const SelectorBuilder([this.selectors = const []]);

  /// Add an id selector to the query.
  SelectorBuilder id(ObjectId id) =>
      SelectorBuilder([...selectors, IdSelector(id)]);

  /// Add an equality selector to the query.
  SelectorBuilder eq(String field, Object value) =>
      SelectorBuilder([...selectors, EqSelector(field, value)]);

  /// Add a greater than or equal to selector to the query.
  SelectorBuilder gte(String field, Object value) =>
      SelectorBuilder([...selectors, GteSelector(field, value)]);

  /// Add a less than or equal to selector to the query.
  SelectorBuilder lte(String field, Object value) =>
      SelectorBuilder([...selectors, LteSelector(field, value)]);

  /// Add a limit selector to the query.
  SelectorBuilder limit(int limit) =>
      SelectorBuilder([...selectors, LimitSelector(limit)]);

  /// Add a sort selector to the query.
  SelectorBuilder sortBy(String field, {bool descending = false}) =>
      SelectorBuilder(
          [...selectors, SortBySelector(field, descending: descending)]);
}
