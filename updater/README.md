# Updater library

Sketching out what the update library could look like.

It's build to be a .so with a C api, loadable by other languages.

Split into two pieces "library" and "cli", but share a cargo workspace.

Cli is just a test tool to exercise the library.  Currently it uses a
Rust ABI to access the library, eventually that will be a C API/ABI.


# Usage

`cargo run` will automatically build the library and cli, and run the cli.
`cargo run check` will check for an version update.
`cargo run current` will print the current version info.

Version checks require the update_server also to be running:
```
cd ../update_server
dart run bin/updater_server.dart
```

# TODO:
* Move to 'anyhow' for error management.


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