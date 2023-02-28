import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'version_store.dart';

class UpdateRequest {
  final String version;
  final String platform;
  final String arch;
  final String clientId;

  UpdateRequest(this.version, this.platform, this.arch, this.clientId);

  factory UpdateRequest.fromJson(Map<String, dynamic> json) {
    return UpdateRequest(
      (json['version'] ?? '') as String,
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

  VersionInfo({required this.version, required this.hash});

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

UpdateResponse responseForVersion(String? version) {
  if (version == null) {
    return UpdateResponse(false, null);
  }
  return UpdateResponse(true, VersionInfo(version: version, hash: ''));
}

Future<Response> updaterHandler(Request request) async {
  final updateRequest =
      UpdateRequest.fromJson(jsonDecode(await request.readAsString()));
  var datastore = VersionStore.shared();

  final latestVersion = datastore.latestVersionForClient(updateRequest.clientId,
      currentVersion: updateRequest.version);
  final updateResponse = responseForVersion(latestVersion);
  return Response.ok(jsonEncode(updateResponse.toJson()));
}
