/// Used for exposing Shorebird configuration to the command line tool.
/// Currently hard coded, but eventually this will be read from a yaml file.
class ShorebirdConfig {
  String genFileDirectory = 'lib/src/gen';

  String get localServerPath => '$genFileDirectory/local_server.dart';

  String get deployServerUrl => 'https://shorebird.app/deploy';
}

const pidFilePath = '.dart_tool/shorebird/pids.json';

final config = ShorebirdConfig();
