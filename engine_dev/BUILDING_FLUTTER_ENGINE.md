# Building Flutter Engine

https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment
https://github.com/flutter/flutter/wiki/Compiling-the-engine

## Building Remotely

Flutter Engine does not (currently) support cross-compiling to Android from
Windows.  To build Flutter Engine for Android, you must build on a Linux or Mac.
If you either, great.  If not, we suggest using a cloud VM.

You can create a cloud VM with your favorite platform, we're currently using
Google Cloud Platform.

To use the VM you need to connect to it from ssh and VSCode:
https://medium.com/@ivanzhd/vscode-sftp-connection-to-compute-engine-on-google-cloud-platform-gcloud-9312797d56eb

You'll want to separate out your source code from the instance you're building on.  This makes it easier to switch instance sizes later.
https://cloud.google.com/compute/docs/disks/add-persistent-disk

You'll need to add a line to /etc/fstab like:
```UUID="..." /src ext4 discard,defaults,nofail 0 2```

You'll need an ssh config file like:
```
Host <number from GCP>
  HostName <number from GCP>
  User <whatever GCP set up>
  IdentityFile ~/.ssh/google_compute_engine
  ForwardAgent yes
```

