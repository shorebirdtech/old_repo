// This eventually moves to its own package.
import 'dart:ffi' as ffi;
import 'dart:io' show Directory;

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

class Updater {
  final String clientId;
  final String cacheDir;

  Updater(this.clientId, this.cacheDir);

  static UpdaterBindings? bindings;

  static loadLibrary() {
    bindings = UpdaterBindings();
  }

  bool checkForUpdate() {
    var bindings = Updater.bindings;
    if (bindings == null) {
      throw Exception('Must call loadLibrary() first.');
    }
    // I'm not sure if this pattern is correct, it might leak if
    // the second toNativeUtf8 throws an exception.
    var clientId = this.clientId.toNativeUtf8();
    var cacheDir = this.cacheDir.toNativeUtf8();
    try {
      return bindings.checkForUpdate(clientId, cacheDir);
    } finally {
      calloc.free(clientId);
      calloc.free(cacheDir);
    }
  }
}

typedef _CheckForUpdateFunc = ffi.Bool Function(
    ffi.Pointer<Utf8> clientId, ffi.Pointer<Utf8> cacheDir);
typedef CheckForUpdate = bool Function(
    ffi.Pointer<Utf8> clientId, ffi.Pointer<Utf8> cacheDir);

class UpdaterBindings {
  final ffi.DynamicLibrary _updater;

  late CheckForUpdate checkForUpdate;

  UpdaterBindings()
      : _updater = ffi.DynamicLibrary.open(path.join(
            Directory.current.path, 'target', 'debug', 'updater.dll')) {
    checkForUpdate =
        _updater.lookupFunction<_CheckForUpdateFunc, CheckForUpdate>(
            'check_for_update');
  }
}
