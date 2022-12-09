// Eventually some of this may be read from a yaml file, for now
// just putting it all in one location.
class ShorebirdConfig {
  String genFileDirectory = 'lib/src/gen';

  String get localServerPath => '$genFileDirectory/local_server.dart';
}

final config = ShorebirdConfig();
