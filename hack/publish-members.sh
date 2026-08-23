#!/bin/sh
set -eu

# Publish every runnable-bearing member into the internal track, with the newest
# minted revision as provenance. The revision record pins each member's
# sha, so a consumer resolves the exact proven tuple with no version typed.
#
# The version label is the member's newest tag, or a dev label carrying the
# proven sha when no tag exists yet. The provenance record is what pins;
# the label is what humans read.

ROOT="${1:-..}"
STATE="$ROOT/golden-state/revisions"

[ -d "$STATE" ] || { echo "publish-members: no revisions at $STATE; run the workspace pipeline first" >&2; exit 1; }

RECORD=$(grep -l '"golden-go"' "$STATE"/*.json 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
[ -n "$RECORD" ] || { echo "publish-members: no revision covers the members; run the workspace pipeline first" >&2; exit 1; }

PROVENANCE=$(basename "$RECORD" .json)
echo "publish-members: provenance $PROVENANCE"

publish() {
    repo="$1"

    version=$(git -C "$ROOT/$repo" describe --tags --abbrev=0 2>/dev/null || true)
    if [ -z "$version" ]; then
        version="v0.1.0-dev.$(git -C "$ROOT/$repo" rev-parse --short=12 HEAD)"
    fi

    forge-register publish --provenance "$PROVENANCE" \
        --source "git@github.com:alexandremahdhaoui/$repo.git" \
        "internal:github.com/alexandremahdhaoui/$repo" "$version"
}

for repo in golden-go golden-rust golden-python golden-typescript \
    golden-configgen golden-e2e; do
    publish "$repo"
done

echo "publish-members: every member is on the internal track at $PROVENANCE"
