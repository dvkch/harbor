#!/bin/bash

set -e

if [ "x$1" = "xrelease" ]; then
    # cleanup
    rm -rf .build

    # build for macOS
    BUILD_PATH=".build/arm64-apple-macosx/release"
    BUNDLE_NAME="Harbor_Harbor.bundle"
    swift build --arch arm64 --arch x86_64 -c release
    mkdir -p "build/macOS"
    rsync -ar ".build/apple/Products/Release/harbor"               "build/macOS"
    rsync -ar ".build/apple/Products/Release/Harbor_Harbor.bundle" "build/macOS"

    # build for linux
    if ! command -v docker &> /dev/null; then
        echo "Couldn't build for linux, docker isn't available"
        exit -1
    fi

    docker container rm -f harbor-linux > /dev/null
    docker run -it --name harbor-linux --platform linux/amd64    -v $(pwd):/harbor swift:latest /bin/bash -c "cd harbor && swift build -c release"
    mkdir -p "build/linux-amd64"
    rsync -ar ".build/x86_64-unknown-linux-gnu/release/harbor"                   "build/linux-amd64"
    rsync -ar ".build/x86_64-unknown-linux-gnu/release/Harbor_Harbor.resources"  "build/linux-amd64"

    docker container rm -f harbor-linux > /dev/null
    docker run -it --name harbor-linux --platform linux/arm64/v8 -v $(pwd):/harbor swift:latest /bin/bash -c "cd harbor && swift build -c release"
    mkdir -p "build/linux-arm64"
    rsync -ar ".build/aarch64-unknown-linux-gnu/release/harbor"                  "build/linux-arm64"
    rsync -ar ".build/aarch64-unknown-linux-gnu/release/Harbor_Harbor.resources" "build/linux-arm64"

else
    BUILD_PATH=".build/arm64-apple-macosx/debug"
    BUNDLE_NAME="Harbor_Harbor.bundle"
    swift build -c debug
fi

echo "All good!"
