import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:version/version.dart';

int compareVersions(String aString, String bString) {
  final a = Version.parse(aString);
  final b = Version.parse(bString);
  return a.compareTo(b);
}

// Dumbest possible datastore. It just stores the files in a directory.
class VersionStore {
  final String cachePath;

  VersionStore(this.cachePath);

  static VersionStore? _shared;

  static initShared(String cachePath) {
    _shared = VersionStore(cachePath);
  }

  static VersionStore shared() {
    if (_shared == null) {
      throw Exception('VersionStore.initShared() must be called first.');
    }
    return _shared!;
  }

  // Should take an api key/product name, etc.
  String getNextVersion() {
    final latest = latestVersionForClient('client') ?? '0.0.0';
    final next = Version.parse(latest).incrementPatch().toString();
    return next;
  }

  void addVersion(String version, List<int> bytes) {
    Directory(cachePath).createSync(recursive: true);
    final path = filePathForVersion(version);
    File(path).writeAsBytesSync(bytes);
  }

  Iterable<String> versionsForClientId(String clientId) {
    // This should use the clientId to get a productId and look up the versions
    // based on productId/architecture, etc.
    try {
      final dir = Directory(cachePath);
      final files = dir.listSync();
      return files.map((e) => p.basenameWithoutExtension(e.path));
    } catch (e) {
      return [];
    }
  }

  String? latestVersionForClient(String clientId, {String? currentVersion}) {
    final versions = versionsForClientId(clientId).toList();
    versions.sort(compareVersions);
    print(versions);
    if (versions.isEmpty) {
      return null;
    }
    if (versions.last == currentVersion) {
      return null;
    }
    return versions.last;
  }

  String filePathForVersion(String version) => '$cachePath/$version.txt';
}
