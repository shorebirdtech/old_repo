/// Used for exposing Shorebird configuration to the command line tool.
/// Currently hard coded, but eventually this will be read from a yaml file.
class ShorebirdConfig {
  String genFileDirectory = 'lib/src/gen';

  String get localServerPath => '$genFileDirectory/local_server.dart';

  String get deployServerUrl => 'https://shorebird.app/deploy';

  String get discordUrl => 'https://discord.gg/9hKJcWGcaB';
}

const pidFilePath = '.dart_tool/shorebird/pids.json';
const authFilePath = '.dart_tool/shorebird/auth.json';

final config = ShorebirdConfig();
