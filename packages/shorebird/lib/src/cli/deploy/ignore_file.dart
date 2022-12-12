import 'dart:io';

import 'package:path/path.dart' as p;

class IgnoreFile {
  final List<RegExp> patterns;

  IgnoreFile(String path) : patterns = _parseFile(path);

  static List<RegExp> _parseLines(List<String> lines) {
    final patterns = <RegExp>[];
    for (var line in lines) {
      if (line.startsWith('#')) {
        continue;
      }
      if (line.isEmpty) {
        continue;
      }
      patterns.add(RegExp(line));
    }
    return patterns;
  }

  static _parseFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return [];
    }
    final lines = file.readAsLinesSync();
    return _parseLines(lines);
  }

  bool shouldIgnore(String path) {
    // IgnoreFile speaks in unix paths, normalize to unix first.
    // If we didn't do this, patterns like '.dart_tool/' won't match
    // on windows.
    path = p.posix.joinAll(p.split(path));
    for (var pattern in patterns) {
      if (pattern.hasMatch(path)) {
        return true;
      }
    }
    return false;
  }
}
