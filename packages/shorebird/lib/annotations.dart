/// Denotes the function as an entrypoint for serverless execution.
/// `shorebird generate` will generate server and client code for this function.
class Endpoint {
  const Endpoint();
}

/// Denotes the class can be stored in the datastore.
/// `shorebird generate` will generate to/from json methods for the class.
class Storable {
  const Storable();
}

/// Denotes the class can be sent over the network.
/// `shorebird generate` will generate to/from json methods for the class.
class Transportable {
  const Transportable();
}
