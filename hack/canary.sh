#!/bin/sh
set -eu

# The canary: sync the playground workspace against the candidate index -
# this checkout, as it stands, tags not required - and run a consumer gate.
# Red here means the candidate never publishes: the stage does not advance,
# nothing mints, no tag appears, and consumers never see the state.
#
# The POC gate is golden-go's unit stage: fast, and it exercises a
# register-resolved dependency. The full bar is every workspace gate plus
# golden-e2e's 16/16 matrix; run that where minutes are cheap.

ROOT="${1:-..}"

cd "$ROOT"
# --register-head: the workspace pins a published register tag, and the
# canary exists to test what that pin would hide - the candidate checkout.
forge-factory sync --config forge-factory.yaml --register-head
cd golden-go
forge test run unit
