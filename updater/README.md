# Updater library

Sketching out what the update library could look like.

It's build to be a .so with a C api, loadable by other languages.

# Parts
* cli: A command line application to test ffi wrapping of updater library.
* library: The rust library that does the actual update work.
* update_server: A simple server that provides update information.
* dart_cli: A command line application to test ffi wrapping of updater library.

# Usage

`cargo run` will automatically build the library and cli, and run the rust cli.
`cargo run current` will print the current version info.
`cargo run check` will check for an version update.
`cargo run update` will pull the latest version if told to by the server.

`check` and `update` require the update_server also to be running:
```
cd ../update_server
dart run bin/updater_server.dart
```

# TODO:
* Remove all non-MVP code.
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

## MVP

updater check
-- says yes / no for update
updater path
-- tells which the current path to use it.
updater update
-- does synchronous update, polling for status regularly?

API
- check if there is an update
- tell us which .so to load
- start an update
- give status on the update in progress
- cancel an update
- 


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
