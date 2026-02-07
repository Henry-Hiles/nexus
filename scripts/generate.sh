#!/usr/bin/env bash
pushd "$(dirname "$(readlink -f "$0")")"/.. > /dev/null || exit

mkdir -p build
touch build/lock
dart scripts/generate.dart
rm build/lock

popd > /dev/null || exit 