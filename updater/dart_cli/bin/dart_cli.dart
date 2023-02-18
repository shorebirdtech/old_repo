import 'dart:ffi' as ffi;
import 'dart:io' show Directory;

import 'package:path/path.dart' as path;

// FFI signature of the hello_world C function
typedef HelloWorldFunc = ffi.Void Function();
// Dart type definition for calling the C foreign function
typedef HelloWorld = void Function();

void main() {
  var libraryPath =
      path.join(Directory.current.path, '..', 'target', 'debug', 'updater.dll');

  final dylib = ffi.DynamicLibrary.open(libraryPath);

  // Look up the C function 'hello_world'
  final HelloWorld hello = dylib
      .lookup<ffi.NativeFunction<HelloWorldFunc>>('hello_world')
      .asFunction();
  // Call the function
  hello();
}
