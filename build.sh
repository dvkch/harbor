#!/bin/bash

set -e

OUTPUT_PATH="$PWD/build/macos"

swift build #-c release

mkdir -p $OUTPUT_PATH
rsync -ar .build/arm64-apple-macosx/debug/harbor $OUTPUT_PATH
rsync -ar .build/arm64-apple-macosx/debug/Harbor_Harbor.bundle $OUTPUT_PATH

if [[ ! $PATH == *"${OUTPUT_PATH}"* ]]; then
    echo "Don't forget to add $OUTPUT_PATH to your PATH"
fi

echo ""
