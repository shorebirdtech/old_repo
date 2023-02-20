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

  String version() {
    var bindings = Updater.bindings;
    if (bindings == null) {
      throw Exception('Must call loadLibrary() first.');
    }
    // I'm not sure if this pattern is correct, it might leak if
    // the second toNativeUtf8 throws an exception.
    var clientId = this.clientId.toNativeUtf8();
    var cacheDir = this.cacheDir.toNativeUtf8();
    ffi.Pointer<Utf8> cVersion = ffi.Pointer<Utf8>.fromAddress(0);
    try {
      cVersion = bindings.version(clientId, cacheDir);
      return cVersion.toDartString();
    } finally {
      calloc.free(clientId);
      calloc.free(cacheDir);
      bindings.freeString(cVersion);
    }
  }
}

typedef _CheckForUpdateFunc = ffi.Bool Function(
    ffi.Pointer<Utf8> clientId, ffi.Pointer<Utf8> cacheDir);
typedef CheckForUpdate = bool Function(
    ffi.Pointer<Utf8> clientId, ffi.Pointer<Utf8> cacheDir);

typedef _VersionFunc = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8> clientId, ffi.Pointer<Utf8> cacheDir);
typedef VersionFunc = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8> clientId, ffi.Pointer<Utf8> cacheDir);

typedef _FreeStringFunc = ffi.Void Function(ffi.Pointer<Utf8> str);
typedef FreeStringFunc = void Function(ffi.Pointer<Utf8> str);

class UpdaterBindings {
  final ffi.DynamicLibrary _updater;

  late CheckForUpdate checkForUpdate;
  late VersionFunc version;
  late FreeStringFunc freeString;

  UpdaterBindings()
      : _updater = ffi.DynamicLibrary.open(path.join(
            Directory.current.path, 'target', 'debug', 'updater.dll')) {
    checkForUpdate =
        _updater.lookupFunction<_CheckForUpdateFunc, CheckForUpdate>(
            'check_for_update');
    version =
        _updater.lookupFunction<_VersionFunc, VersionFunc>('current_version');
    freeString =
        _updater.lookupFunction<_FreeStringFunc, FreeStringFunc>('free_string');
  }
}
