import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:version/version.dart';

class UpdateRequest {
  final String version;
  final String hash;
  final String platform;
  final String arch;
  final String clientId;

  UpdateRequest(
      this.version, this.hash, this.platform, this.arch, this.clientId);

  factory UpdateRequest.fromJson(Map<String, dynamic> json) {
    return UpdateRequest(
      (json['version'] ?? '') as String,
      (json['hash'] ?? '') as String,
      json['platform'] as String,
      json['arch'] as String,
      json['client_id'] as String,
    );
  }
}

String downloadUrlForVersion(String version) {
  return 'http://localhost:8080/releases/$version.txt';
}

String versionForDownloadUrl(String url) {
  return url.split('/').last.split('.').first;
}

class VersionInfo {
  final String version;
  final String hash;
  final String storagePath;

  VersionInfo(this.version, this.hash, this.storagePath);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'hash': hash,
      'download_url': downloadUrlForVersion(version),
    };
  }
}

class UpdateResponse {
  final bool needsUpdate;
  final VersionInfo? version;

  UpdateResponse(this.needsUpdate, this.version);

  Map<String, dynamic> toJson() {
    if (needsUpdate) {
      return <String, dynamic>{
        'needs_update': true,
        'version': version!.toJson(),
      };
    }
    return <String, dynamic>{
      'needs_update': false,
    };
  }
}

int compareVersions(String aString, String bString) {
  final a = Version.parse(aString);
  final b = Version.parse(bString);
  return a.compareTo(b);
}

class VersionDatastore {
  final Map<String, VersionInfo> _versions = {};

  VersionDatastore() {
    addVersion(VersionInfo('1.0.0', 'abc', '/releases/1.0.0.txt'));
    addVersion(VersionInfo('1.0.1', 'xyz', '/releases/1.0.1.txt'));
  }

  void addVersion(VersionInfo version) {
    _versions[version.version] = version;
  }

  Iterable<VersionInfo> versionsForClientId(String clientId) {
    return _versions.values;
  }

  VersionInfo? latestVersionForClient(UpdateRequest request) {
    final versions = versionsForClientId(request.clientId)
        .where((version) => version.version != request.version)
        .toList();
    versions.sort((a, b) => compareVersions(a.version, b.version));
    if (versions.isNotEmpty) {
      return versions.last;
    }
    return null;
  }

  String filePathForVersion(String version) {
    return _versions[version]!.storagePath;
  }
}

void main() async {
// Should take a request to /updater and return a response with the latest version information.
// e.g. input: {"version": "1.0.0", "hash": "abc", "platform": "windows", "arch": "x64", "client_id": "123"}
// response: {"needs_update": true, "version": "1.0.1", "hash": "xyz", "url": "http://localhost:8080/releases/1.0.0.txt"}

  var datastore = VersionDatastore();

  var router = Router();
  router.post('/updater', (Request request) async {
    final updateRequest =
        UpdateRequest.fromJson(jsonDecode(await request.readAsString()));

    final latestVersion = datastore.latestVersionForClient(updateRequest);
    final updateResponse = UpdateResponse(latestVersion != null, latestVersion);
    return Response.ok(jsonEncode(updateResponse.toJson()));
  });
  router.get('/releases/<version>',
      (Request request, String versionWithExtension) {
    var version = versionWithExtension.split('.').first;
    var path = datastore.filePathForVersion(version);
    var bytes = File(path).openRead();
    return Response.ok(bytes);
  });

  var handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  var server = await shelf_io.serve(handler, 'localhost', 8080);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
}
