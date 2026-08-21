#!/bin/sh
set -eu

# Seed the golden register through the front door. This script files
# requests and publishes proofs; it never writes an index file, so "the
# pipeline is the only writer" holds from commit zero. Run forge-register
# apply afterwards to answer the requests.
#
# The package list mirrors the workspace factory's dependency pins. No
# versions are named: admission picks the newest release passing the floor,
# which is the point of having a register.

WHO="${1:-seed}"

req() {
    forge-register add --requester "$WHO" --reason "seeded from the workspace factory pins" "$1"
}

# go
req go:github.com/stretchr/testify
req go:github.com/modelcontextprotocol/go-sdk
req go:github.com/oapi-codegen/runtime
req go:sigs.k8s.io/yaml

# rust
for crate in anyhow axum base64 chrono mockall reqwest serde serde_json thiserror tokio uuid; do
    req "rust:$crate"
done

# python
for pkg in fastapi httpx uvicorn datamodel-code-generator openapi-python-client pytest pytest-cov pytest-mock ruff; do
    req "python:$pkg"
done

# typescript
for pkg in fastify neverthrow "@eslint/js" "@hey-api/openapi-ts" "@types/node" \
    "@vitest/coverage-v8" eslint prettier tsx typescript typescript-eslint \
    vitest vitest-mock-extended; do
    req "typescript:$pkg"
done

# Internal packages enter by proof: the version each repo's tag names, with
# the checkout's HEAD as provenance. In the full loop the pipeline publishes
# these on green with the minted revision id.
publish() {
    repo="$1"; version="$2"

    sha=$(git -C "../$repo" rev-parse --short=12 HEAD)
    forge-register publish --provenance "$sha" \
        --source "git@github.com:alexandremahdhaoui/$repo.git" \
        "internal:github.com/alexandremahdhaoui/$repo" "$version"
}

publish golden-spec v0.2.0
publish forge-ci-spec v0.2.0
publish forge-revision-spec v0.3.0
publish forge-register-spec v0.1.0
publish forge v0.43.0

echo "seeded. run: forge-register apply"
