import 'dart:convert';
import 'dart:io';

import 'package:shorebird/src/cli/shared/config.dart';

class Session {
  final String projectId;
  final String apiKey;

  Session({required this.projectId, required this.apiKey});

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'apiKey': apiKey,
      };

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      projectId: json['projectId'] as String,
      apiKey: json['apiKey'] as String,
    );
  }

  // Should this be async?
  static Session? load() {
    var authFile = File(authFilePath);
    if (!authFile.existsSync()) {
      return null;
    }
    return Session.fromJson(jsonDecode(authFile.readAsStringSync()));
  }

  void save() {
    var authFile = File(authFilePath);
    authFile.createSync(recursive: true);
    authFile.writeAsStringSync(jsonEncode(toJson()));
  }
}
