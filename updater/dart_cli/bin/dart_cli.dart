import 'dart:ffi' as ffi;
import 'dart:io' show Directory;

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

// FFI signature of the hello_world C function
typedef HelloWorldFunc = ffi.Void Function();
// Dart type definition for calling the C foreign function
typedef HelloWorld = void Function();

typedef CheckForUpdateFunc = ffi.Uint8 Function(
    ffi.Pointer<Utf8> clientId, ffi.Pointer<Utf8> cacheDir);
typedef CheckForUpdate = int Function(
    ffi.Pointer<Utf8> clientId, ffi.Pointer<Utf8> cacheDir);

void main() {
  var libraryPath =
      path.join(Directory.current.path, 'target', 'debug', 'updater.dll');

  final dylib = ffi.DynamicLibrary.open(libraryPath);

  final HelloWorld hello = dylib
      .lookup<ffi.NativeFunction<HelloWorldFunc>>('hello_world')
      .asFunction();
  // Call the function
  hello();

  final CheckForUpdate checkForUpdate = dylib
      .lookup<ffi.NativeFunction<CheckForUpdateFunc>>('check_for_update')
      .asFunction();
  // Call the function
  var clientId = 'test-client-id'.toNativeUtf8();
  var cacheDir =
      path.join(Directory.current.path, 'update_server').toNativeUtf8();
  var result = checkForUpdate(clientId, cacheDir);
  calloc.free(clientId);
  calloc.free(cacheDir);
  if (result == 0) {
    print('Update available');
  } else {
    print('No update available');
  }
}
