# shellcheck shell=bash

# Opens a PR bumping the libmpv build that the Windows CI downloads, if
# mpv-winbuild-cmake has published a newer one. Run it from the repo root, with
# TOKEN set to a Forgejo token that can push branches and open PRs.

# Checked first, so that nothing is pushed if the PR can't be opened
: "${TOKEN:?needs a Forgejo token}"
: "${GITHUB_SERVER_URL:?is set by Forgejo Actions}"
: "${GITHUB_REPOSITORY:?is set by Forgejo Actions}"
: "${GITHUB_REF_NAME:?is set by Forgejo Actions}"

workflow=.github/workflows/windows.yml
current_url=$(grep -oE 'https://github\.com/shinchiro/mpv-winbuild-cmake/releases/download/[^"]+\.7z' "$workflow")
current_hash=$(grep -oE -- '-ne "[0-9a-f]{64}"' "$workflow" | grep -oE '[0-9a-f]{64}')

release=$(curl -fsSL https://api.github.com/repos/shinchiro/mpv-winbuild-cmake/releases/latest)
tag=$(jq -r .tag_name <<<"$release")
url=$(jq -r '.assets[] | select(.name | test("^mpv-dev-x86_64-[0-9]{8}-git-[0-9a-f]+\\.7z$")) | .browser_download_url' <<<"$release")

if [ -z "$url" ]; then
    echo "Release $tag has no x86_64 libmpv archive" >&2
    exit 1
fi
if [ "$url" = "$current_url" ]; then
    echo "libmpv is up to date ($tag)"
    exit 0
fi

branch="bump-libmpv-$tag"
if git ls-remote --exit-code --heads origin "$branch" >/dev/null; then
    echo "$branch already exists, so its PR should already be open"
    exit 0
fi

archive=$(mktemp)
curl -fsSL "$url" -o "$archive"
hash=$(sha256sum "$archive" | cut -d " " -f 1)
rm "$archive"

sed -i "s|$current_url|$url|; s|$current_hash|$hash|" "$workflow"

git config user.name "Forgejo Actions"
git config user.email "forgejo-actions@noreply.git.federated.nexus"
git switch -c "$branch"
git commit -am "bump libmpv to $tag"
git push origin "$branch"

curl -fsS -X POST "$GITHUB_SERVER_URL/api/v1/repos/$GITHUB_REPOSITORY/pulls" \
    -H "Authorization: token $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
        --arg head "$branch" \
        --arg base "$GITHUB_REF_NAME" \
        --arg title "Bump libmpv to $tag" \
        --arg body "Updates the libmpv build that the Windows CI bundles to [$tag](https://github.com/shinchiro/mpv-winbuild-cmake/releases/tag/$tag)." \
        '{head: $head, base: $base, title: $title, body: $body}')" \
    >/dev/null

echo "Opened a PR bumping libmpv to $tag"
