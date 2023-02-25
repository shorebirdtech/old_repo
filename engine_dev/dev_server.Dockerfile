FROM ubuntu:20.04 as build
# Make apt-get not prompt for "geographic area"
ARG DEBIAN_FRONTEND=noninteractive

# Probably don't need all of these.
RUN apt-get update 
RUN apt-get install -y curl git wget unzip libgconf-2-4 gdb libstdc++6 libglu1-mesa fonts-droid-fallback lib32stdc++6 python3 lbzip2 pkg-config
RUN apt-get clean

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
ENV PATH="/depot_tools:${PATH}"

RUN mkdir /engine
WORKDIR /engine
# Need to add github to allowed ssh hosts before this?
RUN gclient sync

WORKDIR /engine/src/flutter
RUN git remote add upstream git@github.com:flutter/engine.git
RUN git pull upstream main

WORKDIR /engine/src
RUN ./build/install-build-deps-android.sh
RUN ./build/install-build-deps.sh
# RUN ./flutter/build/install-build-deps-linux-desktop.sh



RUN gn gen out/Default
RUN ninja -C out/Default

# Build the dev server
WORKDIR /src/android
RUN gn gen out/Default --args='is_debug=false is_official_build=true is_component_build=false'
RUN ninja -C out/Default chrome_public_apk

# Build the dev server
WORKDIR /src/android
RUN gn gen out/Default --args='is_debug=false is_official_build=true is_component_build=false'
RUN ninja -C out/Default chrome_public_apk