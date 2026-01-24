#!/usr/bin/env bash
pushd "$(dirname "$(readlink -f "$0")")"/.. || exit

mkdir -p build
touch build/lock
dart scripts/generate.dart
rm build/lock

popd || exit 