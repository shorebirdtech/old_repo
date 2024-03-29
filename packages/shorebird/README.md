[![Pub package](https://img.shields.io/pub/v/shorebird.svg)](https://pub.dev/packages/shorebird)
[![Discord](https://dcbadge.vercel.app/api/server/9hKJcWGcaB)](https://discord.gg/9hKJcWGcaB)

NOTE: This package is not being actively developed.  It was a fun experiment
and we will likely come back to it, but for now we're working on code push.

If you're excited about this Dart-serverless exploration, hop on Discord and
tell us!  We're here to build things people want to use, so let us know.

# Shorebird

# Installation

```
dart pub global activate shorebird
shorebird generate
shorebird run
```

# Usage

Shorebird uses @Endpoint(), @Storable() and @Transportable() annotations to mark
sections of your code you intend to run on the server, store in a datastore,
transport over the network, etc.

## @Endpoint

@Endpoint() annotations are used to mark functions that should be exposed 
as serverless functions.  The function must return a `Future<T>` or `Stream<T>`.
`shorebird generate` will generate the necessary server and client code
to connect to the function.

```dart
import 'package:shorebird/shorebird.dart';
import 'package:shorebird/annotations.dart';

@Endpoint()
Future<String> hello(RequestContext context) async {
  return 'Hello, world!';
}

import 'src/gen/client.dart'; // Generated by `shorebird generate`.

void main() async {
  var client = Client();
  var result = await client.hello();
  print(result); // Prints 'Hello, world!'
}
```

@Endpoint() annotations can only be used on top level functions. This is part
of the idea that Shorebird is a serverless architecture, your functions
may end up run on differnet instances at different times and should not expect
to keep state long term.  To keep state, use the DataStore or (soon) Session
objects.

## @Storable and @Transportable

@Storable() annotations are used to mark classes that can be stored in a
datastore.
@Transportable() annotations are used to mark classes that can be sent across
the network.  It's often the case that a class is both Storable and
Transportable.  (Currently they're treated interchangably.)

```dart
import 'package:shorebird/annotations.dart';

@Endpoint()
Future<void> addPerson(RequestContext context, Person newPerson) async {
  DataStore.of(context).collection<Person>().add(newPerson);
}

@Endpoint()
Future<Person> getPerson(String name) async {
  return DataStore.of(context).collection<Person>().firstWhere((p) => p.name == name);
}

@Storable()
@Transportable()
class Person {
  String name;
  int age;
}

void main() {
  var client = Client();
  var person = Person()..name = 'Bob'..age = 42;
  await client.addPerson(person);
  var bob = await client.getPerson('Bob');
  print(bob.age); // Prints '42'
}
```

# Deploying into the cloud
- `shorebird deploy` works but requires an API key to use.  If you're
  interested in testing Shorebird, please join us on Discord and ask for
  an API key.
- `shorebird deploy` currently only uses the local database on the instance
  which lost on every deploy.  This is a bug.
- `shorebird deploy` currently does not show any status or progress.  Deploys
  take about 5 minutes to "complete" and then another 5 minutes to fully
  start the instance in the cloud.  This is again a bug.\
- `shorebird deploy` currently only supports a single instance per apiKey
  (for simplicity), this means every time to you deploy you replace the
  current instance.  This will change in the future.

# Known issues
- `shorebird run` does not (yet) call `shorebird generate` before running.
  This means that if you change Endpoints, Storable, or Transportable classes
  you need to run `shorebird generate` manually before running.
- `shorebird` CLI dependencies are currently present in package:shorebird's
  pubspec.yaml.  They will be moved to a separate package soon.
- Don't yet have a nice way to handle error reporting from the server.
  currently Client.post will throw an exception if the server returns
  a non-200 response.  Instead we should have structured error reporting between
  client and server (including possibly stack traces in dev mode?).
- There is no way to specify assets to include alongside your server code.
- There is no way to see logs from a deployed server (local logs work fine).

## Missing support in Endpoint / Transportable / Storable generation
- Endpoints can't take Nullable parameters yet.
- @Storable and @Transportable do not yet generate toJson/fromJson methods.
  Should be easy to fix, for now classes should also use json_serializable.
- No way to generate an Endpoint that takes a File upload.
  maybe https://pub.dev/packages/cross_file? or RandomAccessFile?


# Notes

## TODO for a Demo
* `shorebird create` (could be a whole app, not just counter)
* `shorebird run`
* `shorebird deploy`
  hosted version on the web, and download links
  Also offer a push-to-deploy separate flow.

## Questions
* Does `shorebird deploy` also deploy a database?  Yes it should.
* Does `shorebird deploy` always deploy a *new* database?  No, it should
  by default connect to the existing database?
* Does `shorebird deploy` support channels/flavors/stages?  It must.

## Later
* `shorebird shorebirdify` add shorebird to an existing project.
* Remove 'json_serializable'and 'build_runner' dependencies everywhere.
* Generate should generate an OpenAPI definition for the endpoints.
  This would make it easy to upload to a front end, like AWS API Gateway.

## A note on version-skew boundary.
Commonly applications have the Client/Server boundary also act as the version
boundary.  This is somewhat unnatural for mobile applications, which typically
start from the client and grow "backwards", rather than web applications which
start from being served (an always fresh version) and grow towards the "client"
from the "server".  Mobile applications are installed and updates often
infrequent.  It's common to need to support *many* versions of the app in the
wild for a very long time.  Doing this with a single server API can be quite
difficult and constraining.

Shorebird is considering an approach, where the Client and Server are version
locked, and version skews happen within the Server. With modern cloud, it's easy
to imagine handling versioned servers with dynamically sized clusters depending
on usage.

It's unclear where Shorebird should put the version skew boundary.  Should it
happen between the Server and the DataStore, or if there is another layer?  One
possibility is that the DataStore is versioned too, and data migration between
DataStore versions is explicit (e.g. a naive deploy with a changed DataStore
would start from empty).  A downside of that approach would be that it would be
hard to query across versions. Another approach would be to have the version
skew between the DataStore and the Endpoints by having some stable API the
DataStore exposes to the endpoints but the DataStore itself handles the version
skew.