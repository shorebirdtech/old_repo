Sketching out what codepush for Flutter could look like.

## Path to an MVP
* An Android app which contains two libapp.so files, but launches using the non-default one.
* An Android app which contains two libapp.so files, and can switch between them.
* Android app which can check for updates and restart itself with the new version.  e.g. the counter app, just with a button to check for updates.

# Design

## Development Side

* Send source to cloud.
  * Could do binary too, but that limits later options for how to do the actual pushing.
* Compile source in cloud
* CodePush is a dependency for the Android app?

## App side

* Checker is a native library which allows you to check if your version is the latest?
* Checker also exposes APIs into Dart to allow checking long after app launch?


* By default, check on launch if a new version is available
Networks can be slow, so do this in concert with launching.
* If can’t check
“Fail open” and Launch normally (probably can’t login anyway)
* If have latest version
Do nothing.
* If newer version exists
By default, offer to restart the app?
* If a newer (incompatible) version exists
By default, offer a “update with store” prompt?

