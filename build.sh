#!/bin/bash

set -e

if [ "x$1" = "xrelease" ]; then
    # cleanup
    rm -rf .build/ build/

    # build for macOS
    echo ""
    echo "----------------------------------------"
    echo "Building for macOS..."
    swift build --arch arm64 --arch x86_64 -c release
    mkdir -p "build/macOS"
    rsync -ar ".build/apple/Products/Release/harbor"               "build/macOS"
    rsync -ar ".build/apple/Products/Release/Harbor_Harbor.bundle" "build/macOS"
    tar -C build/macOS -czf build/macOS.tar.gz .

    # build for linux
    if ! command -v docker &> /dev/null; then
        echo "Couldn't build for linux, docker isn't available"
        exit -1
    fi

    BUILD_CMD="swift build -c release -Xswiftc -O -Xswiftc -static-stdlib"
    
    echo ""
    echo "----------------------------------------"
    echo "Building for Linux ARM64..."
    docker container rm -f harbor-linux > /dev/null
    docker run -it --name harbor-linux --platform linux/arm64/v8 -v $(pwd):/harbor swift:latest /bin/bash -c "cd harbor && $BUILD_CMD"
    mkdir -p "build/linux-arm64"
    rsync -ar ".build/aarch64-unknown-linux-gnu/release/harbor"                  "build/linux-arm64"
    rsync -ar ".build/aarch64-unknown-linux-gnu/release/Harbor_Harbor.resources" "build/linux-arm64"
    tar -C build/linux-arm64 -czf build/linux-arm64.tar.gz .

    echo ""
    echo "----------------------------------------"
    echo "Building for Linux x64..."
    docker container rm -f harbor-linux > /dev/null
    docker run -it --name harbor-linux --platform linux/amd64    -v $(pwd):/harbor swift:latest /bin/bash -c "cd harbor && $BUILD_CMD"
    mkdir -p "build/linux-amd64"
    rsync -ar ".build/x86_64-unknown-linux-gnu/release/harbor"                   "build/linux-amd64"
    rsync -ar ".build/x86_64-unknown-linux-gnu/release/Harbor_Harbor.resources"  "build/linux-amd64"
    tar -C build/linux-amd64 -czf build/linux-amd64.tar.gz .

else
    swift build --arch arm64 --arch x86_64 -c debug
    mkdir -p "build/macOS"
    rsync -ar ".build/apple/Products/Debug/harbor"               "build/macOS"
    rsync -ar ".build/apple/Products/Debug/Harbor_Harbor.bundle" "build/macOS"
fi

echo "All good!"
