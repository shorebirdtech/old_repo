import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/form_data.dart';
import 'package:shelf_multipart/multipart.dart';

import 'config.dart';
import 'version_store.dart';

Future<Response> uploadHandler(Request request) async {
  if (!request.isMultipart) {
    print("Unexpected request: ${request.method} ${request.url}");
    return Response.badRequest(body: 'Expected multipart request');
  }
  if (!request.isMultipartForm) {
    return Response.badRequest(body: 'Expected multipart form request');
  }

  Directory(config.cachePath).createSync(recursive: true);

  var datastore = VersionStore.shared();
  var nextVersion = datastore.getNextVersion();
  var path = datastore.filePathForVersion(nextVersion);

  bool foundFile = false;
  await for (final formData in request.multipartFormData) {
    // 'file' is just the name of the field we used in this form.
    if (formData.name == 'file') {
      if (foundFile) {
        throw "Unexpected form data: ${formData.name}";
      }
      final file = File(path);
      await file.create();
      await file.writeAsBytes(await formData.part.readBytes(), flush: true);
      foundFile = true;
      continue;
    } else {
      throw "Unexpected form data: ${formData.name}";
    }
  }
  if (!foundFile) {
    throw "Missing file";
  }

  return Response.ok("OK");
}
