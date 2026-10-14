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

### Changed

- The wiki pages move from `wiki/` to `docs/wiki/` and the `.publish` marker
  is removed. The `Publish wiki` workflow (`.gitea/workflows/publish-wiki.yml`,
  from `framework/templates/ci/`) now publishes them on a push to `main`.

## [0.3.4] - 2026-10-13

### Added

- Gitea workflows: Quality (shellcheck and shfmt through the shared reusable
  workflow) and Release (tag and release page from this changelog).
- A `wiki/` folder with a `.publish` marker, published to the Gitea wiki by the
  shared Publish wiki workflow.
- `switch_case_indent` for `*.sh` in `.editorconfig`, so `shfmt` accepts the
  existing layout of `case` branches.
- `TOKEN_FOR_GITEA_WIKI` is accepted in `.env`: an optional Gitea token with
  the repository write scope only, for publishing the wiki. It is checked like
  the other tokens, kept out of every message and never used or asked for, so
  one `.env` can serve both RepoFoundry and the wiki publishing.
- The wiki in English, Danish and Bahasa Malaysia: Getting started, SSH and
  tokens, Access tokens, Updating the framework and Troubleshooting.

### Changed

- The guide for creating the access tokens moved from `howto/` to the wiki
  page Access tokens, with its pictures and a Danish and a Bahasa Malaysia
  translation.
- The README, the wiki and `.env.example` say which credentials are required:
  `GITEA_TOKEN` always, `GITHUB_PAT` and `GITHUB_USER` only when GitHub is
  chosen, and `TOKEN_FOR_GITEA_WIKI` never.
