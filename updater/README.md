# Updater library

Sketching out what the update library could look like.

It's build to be a .so with a C api, loadable by other languages.

# Parts
* cli: Test the updater library via the Rust API (for development).
* dart_cli: Test ffi wrapping of updater library.
* library: The rust library that does the actual update work.
* publisher: A CLI to publish new versions.
* ../update_server: A simple server that provides update information.

# Development

There are two CLIs for easy testing of the library and the C api.

Both require the library to be built first:
`cargo build` will build the debug version of the library.

Both require a running update_server.  In a separate terminal:
```
cd ../update_server
dart run bin/updater_server.dart
```

# Dart CLI

The Dart CLI uses the C api to load the library and call into it.
It also has a "run" command which assumes the published versions are just
dart scripts.

Example usage:
```
% dart run publisher/bin/publisher.dart publish a.dart
Deployed successful.
% dart run dart_cli/bin/dart_cli.dart run --update    
Running updater_cache/slot_0/libapp.txt
Version A
% dart run publisher/bin/publisher.dart publish b.dart
Deployed successful.
% dart run dart_cli/bin/dart_cli.dart run --update    
Running updater_cache/slot_1/libapp.txt
Version B
```

# Rust CLI

The Rust CLI uses the (internal) Rust API instead of the C API which can
be nice during development of the library itself.

`cargo run` will build the library and rust cli, and run the rust cli.
`cargo run current` will print the current version info.
`cargo run check` will check for an version update.
`cargo run update` will pull the latest version if told to by the server.

`check` and `update` require the update_server also to be running:


# TODO:
* Remove all non-MVP code.
* Clean up `shorebird` command and merge `publisher` into that.
* Add an async API.
* Add support for "channels" (e.g. beta, stable, etc).
* Actually respect "client id" and "platform" and "arch" in the server.
* Wire up dart:ffi package with the C api and build a demo flutter app.
* Write tests for state management.
* Make state management/filesystem management atomic (and tested).
* Move updater values out of the params into post body?
* Support hashing values and check them?
* Add "validate" command to validate state.
* Write a mode that runs the updater first and then launches whatever is downloaded?
* Use cbindgen to generate the C api header file.
  https://github.com/eqrion/cbindgen/blob/master/docs.md


# Rust
We use normal rust idioms (e.g. Result) inside the library and then bridge those
to C via an explicit stable C API (explicit enums, null pointers for optional
arguments, etc).  The reason for this is that it lets the Rust code feel natural
and also gives us maximum flexibility in the future for exposing more in the C
API without having to refactor the internals of the library.

## Notes
* https://github.com/RubberDuckEng/safe_wren has an example of building a rust library and exposing it with a C api.

Config
* Client ID
* URL
* Channel (beta, stable, etc.)


Tiny API
* Do update now
* Is there a new version

State machine
* Checking for update
* Downloading update
* Ready for switch.
* World needs to reboot.

Need some kind of A/B ness of it.
* Run with two slots
* Run on A vs. B slot
* Maybe an R slot, which is factory/recovery slot.
* And fallback behavior.

When booting with B fails, fall back to A and mark B as bad.
If both are marked bad, fall back to R.


Some smarts on the server
Ping server with
ClientID
State (e.g. version)
Allows for 5% rollouts.
ClientIDs let you do this.  You want to get the same answer every time you roll the 5% dice (e.g. using the client id)


Demo user experience
Just run deploy, and replaces all with the new thing. That’s it.

First product is the update engine.
Want to A/B test.
Want to roll-out to x population.


Another use of clientId is giving them to mixpanel, etc.
What data does the update engine expose that feeds into people’s metrics.


References
* https://theupdateframework.io/
* https://fuchsia.dev/fuchsia-src/concepts/packages/software_update_system



# Notes
* Shorebird use web-created accounts for easy set-up of the SDK.
* When you download the SDK it should include your API Key in it (save you a setup step).
