# nim-eth3-scenarios

Deterministic test vector snapshots for Nim Eth3 development.

This repository acts as a CI hub:
- pin `vendor/leanspec` to a specific commit,
- generate vectors from LeanSpec (`uv run fill`),
- package vectors into release tarballs,
- publish those tarballs via GitHub Releases.

## Purpose

* Provide reproducible, versioned test snapshots
* Pin artifacts to a specific LeanSpec commit
* Support CI and cross-client testing

## Manual release flow

Run one release per Devnet version from GitHub Actions:
`.github/workflows/manual-vector-release.yml`.

Use these inputs for each run:

1. `lean_spec_ref`: full 40-char commit SHA for the target Devnet version
2. `release_version`: new tag in `vX.Y.Z` format
3. `fork`: `Devnet`
4. `scheme`: `prod` (default)

### Devnet refs

| Devnet | lean_spec_ref |
| --- | --- |
| Devnet 0 | `4b750f2748a3718fe3e1e9cdb3c65e3a7ddabff5` |
| Devnet 1 | `050fa4a18881d54d7dc07601fe59e34eb20b9630` |
| Devnet 2 | `4edcf7bc9271e6a70ded8aff17710d68beac4266` |
| Devnet 3 | `3a34e7fae5ed8cd13acc5881207aee4fb1508cc1` |
