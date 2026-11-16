#!/usr/bin/env bash
set -euo pipefail

cd "${PUB_CACHE:-$HOME/.pub-cache}"/hosted/pub.dev/avif_native-*

bash tool/native/build_unix.sh android-arm64 decode-dav1d

library=dist/android-arm64/decode-dav1d/libavif_native.so
jq --arg path "../$library" --arg hash "$(sha256sum "$library" | cut -d " " -f 1)" \
    '.artifacts["android-arm64-decode-dav1d"] |= {path: $path, librarySha256: $hash, fileName}' \
    native/manifest.json > manifest.json
mv manifest.json native/manifest.json
