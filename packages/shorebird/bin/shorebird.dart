// Can the cli logic all move to a separate package?
// If we did that would that need to depend on package:shorebird?
// Could package:shorebird then still depend on package:shorebird_cli
// but only as a dev dependency?
import 'package:shorebird/src/cli/main.dart' as cli;

void main(List<String> args) {
  cli.main(args);
}
