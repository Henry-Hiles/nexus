#!/usr/bin/env bash
set -euo pipefail

version=${1:?usage: $0 <version>, e.g. 1.2.0 or 1.2.0-beta1}
[[ $version =~ ^([0-9]+)\.([0-9]{1,2})\.([0-9]{1,2})(-[a-z]+([0-9]{1,3}))?$ ]] ||
    { echo "invalid version: $version" >&2; exit 1; }
prerelease=${BASH_REMATCH[5]:-}

code=$((10#${BASH_REMATCH[1]} * 100000000 + 10#${BASH_REMATCH[2]} * 1000000 + 10#${BASH_REMATCH[3]} * 10000 + 10#${prerelease:-999}))

cd "$(dirname "$0")/.."
git diff --quiet HEAD || { echo "commit or stash your changes first" >&2; exit 1; }
! git rev-parse -q --verify "refs/tags/v$version" > /dev/null || { echo "v$version already exists" >&2; exit 1; }

sed -i "s/^version: .*/version: $version+$code/" pubspec.yaml
sed -i "s/^AppVersion=.*/AppVersion=$version/" windows/installer.iss
if [[ $prerelease ]]; then
    release="<release version=\"$version\" date=\"$(date +%F)\" type=\"development\"/>"
else
    release="<release version=\"$version\" date=\"$(date +%F)\"/>"
    sed -i "s|refs/tags/v[^\"]*\"|refs/tags/v$version\"|" README.md
fi
sed -i "s|^\( *\)<releases>|&\n\1  $release|" linux/nexus.federated.nexus.metainfo.xml

git commit -qam "prepare v$version"
git tag "v$version"
echo "Tagged v$version ($code). Push with: git push origin HEAD v$version"
