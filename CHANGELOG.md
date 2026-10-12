# Changelog

All notable changes to RepoFoundry. Versions are tags `vMAJOR.MINOR.PATCH`.
The release workflow takes the text of a release page from the entry of its
version, so every release needs an entry here before it is started.

Each release lists its changes in these groups, in this order: **Breaking**,
**Added**, **Changed**, **Fixed**. A release with a Breaking entry has a new
major version.

`python tools/changelog.py check` of `TirSystem/github-action` verifies this
file.

## [Unreleased]

### Added

- Gitea workflows: Quality (shellcheck and shfmt through the shared reusable
  workflow) and Release (tag and release page from this changelog).
- A `wiki/` folder with a `.publish` marker, published to the Gitea wiki by the
  shared Publish wiki workflow.
- `switch_case_indent` for `*.sh` in `.editorconfig`, so `shfmt` accepts the
  existing layout of `case` branches.
