# shellcheck shell=bash

# Regenerates the README, AppStream and Fastlane screenshots, from
# integration_test/screenshots. Run it from the repo root.

work="$(mktemp -d)"
# shellcheck disable=SC2329 # Run by the trap
cleanup() { rm -rf "$work"; }
trap cleanup EXIT

GOCACHE="$(go env GOCACHE)"
export GOCACHE

XDG_DATA_HOME="$work/data" XDG_CACHE_HOME="$work/cache" \
    dbus-run-session --config-file="$DBUS_SESSION_CONFIG" -- \
    flutter test integration_test/screenshots/screenshots_test.dart -d linux \
    --dart-define="SCREENSHOTS_DIR=$work/out" "$@"

for shot in "$work"/out/*.png; do
    pngquant --quality 65-95 --speed 1 --strip --force --ext .png "$shot"
    oxipng --quiet --opt 4 --strip safe "$shot"
done

install -Dm644 "$work"/out/desktop-*.png -t assets/screenshots

phone=fastlane/metadata/android/en-US/images/phoneScreenshots
install -Dm644 "$work/out/phone-chat-light.png" "$phone/1.png"
install -Dm644 "$work/out/phone-chat-dark.png" "$phone/2.png"
install -Dm644 "$work/out/phone-rooms-light.png" "$phone/3.png"
install -Dm644 "$work/out/phone-rooms-dark.png" "$phone/4.png"
