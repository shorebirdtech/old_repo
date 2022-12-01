Main package for Shorebird

# Notes

## Generation
- Find/collect all endpoints (@secure?) in the code.
- Generate handlers for each endpoint.
- Generate allHandlers.
- Generate client stubs for each endpoint.
- Generate a server.dart (uses allHandlers).
- Generate ClassInfo for all @Storable classes and classInfoMap.
- Generate toJson for all @Transportable classes.