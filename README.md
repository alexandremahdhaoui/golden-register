# golden-register

The register instance for the playground workspaces: the catalog of adoptable
package versions. Its own forge-ci pipeline is the only writer; consumers
resolve against the checkout (and, once published, against tags).

## Layout

```
index/<ecosystem>/<package>/<prefix>.json   one file per package per track
request/<key>.json                          the only door in
verdict/<key>.json                          every decision, with its inputs
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

# The pipeline, run from the workspace root - pipeline-state's path
# resolves to the sibling golden-state repo there, and nowhere else:
forge-ci apply --config golden-register/forge-ci.yaml --root .
                                                  # process -> evaluate -> canary -> mint
```

The canary syncs the playground workspace against this checkout as it stands
and runs a consumer gate; red means the stage does not advance, nothing
mints, and nothing publishes. Run records land in golden-state.

Policy: a 7-day quarantine (waived for a strictly safer version), an
admission floor of no-critical, deterministic track-opening deny rules, and programmatic
deprecation. Pre-releases are never candidates; only an exact request naming
one admits it. Every knob lives in `forge-register.yaml` and no consumer can
set it.

## The data, today

Nothing in this index has been measured. Every track says
`outcome: unreachable` and says so in words.

They were written while the pipeline pointed at a local stand-in that
answered nothing. Each one recorded a zero vector and
`sha256:e3b0c44298fc1c14`, the sha256 of an empty response - which is also
exactly what a genuinely clean package produces, so the file could not tell
the two apart and recorded the wrong one. Fifty-six packages read as clean
and none of them had been checked.

`outcome` is the field that stops that. A zero vector now travels with a
word saying which of four things happened: a range covers this version, the
feed answered and none did, the feed carries no record for this package, or
the feed could not be reached.

Run the pipeline against the real feed to replace them:

```sh
forge-ci apply --config golden-register/forge-ci.yaml --root ..
```

Rust release dates are absent for the same reason. crates.io answers 403 to
a request with no `User-Agent`, which read as a blocked network; the header
is sent now, so a re-discover against the real API fills them in.
- Tags: v0.1.0 and v0.2.0 exist in the repo, created after green pipeline
  runs; the remote session's git proxy refuses tag pushes, so push them
  from a machine that can (`git push origin v0.1.0 v0.2.0`).
