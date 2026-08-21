# golden-register

The register instance for the playground workspaces: the catalog of adoptable
package versions. Its own forge-ci pipeline is the only writer; consumers
resolve against the checkout (and, once published, against tags).

## Layout

```
index/<ecosystem>/<package>/<prefix>.json   one file per package per track
requests/<key>.json                         the only door in
verdicts/<key>.json                         every decision, with its inputs
forge-register.yaml                         the policy knobs, register-level
forge-ci.yaml                               the pipeline that keeps this honest
```

A **track** is a maintained line named by a semver prefix (`1`, or `1.27`
for a maintained minor line), holding one current version, its adoption
history, and any advisory or deprecation. A **request** (admission, upgrade,
open-track) moves the register only by passing policy; answering it is
writing its **verdict** at the same key. Internal packages live under the
`internal` ecosystem and enter by proof: `publish` records the revision that
proved them.

## Operating it

```sh
forge-register status                             # tracks, advisories, pending
forge-register add rust:serde --reason "..."      # file an admission request
forge-register apply                              # answer requests, evaluate all tracks
forge-register publish internal:<url> <version> --provenance <revision>

forge-ci apply --config forge-ci.yaml --root ..   # the pipeline:
                                                  # process -> evaluate -> canary -> mint
```

The canary syncs the playground workspace against this checkout as it stands
and runs a consumer gate; red means the stage does not advance, nothing
mints, and nothing publishes. Run records land in golden-state.

Policy: quarantine (currently 0 — POC value), an admission floor of
no-critical, deterministic track-opening deny rules, and programmatic
deprecation. Pre-releases are never candidates; only an exact request naming
one admits it. Every knob lives in `forge-register.yaml` and no consumer can
set it.

## The data, today

- Severity vectors are empty: this index was seeded where api.osv.dev is
  unreachable, from a feed answering no vulnerabilities. Every verdict's
  `osvSnapshot` digest says which snapshot it saw. Run `forge-register
  apply` with feed access to backfill.
- Rust release dates are absent: crates.io's API was unreachable and the
  sparse index carries no dates, so quarantine cannot bite for rust entries
  until a re-discover with the real API.
