Main package for Shorebird

# Notes

## Known issues
- `shorebird run` leaks processes on Windows.  The pid of the process it starts
  is not the same as the pid the process itself sees.  I think this happens
  because `dart run` is a wrapper, which exits leaving the child process
  with a differnet pid.

## Generation
- Find/collect all endpoints (@secure?) in the code.
- Generate handlers for each endpoint.
- Generate allHandlers.
- Generate client stubs for each endpoint.
- Generate a server.dart (uses allHandlers).
- Generate ClassInfo for all @Storable classes and classInfoMap.
- Generate toJson for all @Transportable classes.