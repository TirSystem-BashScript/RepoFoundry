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

## [0.3.6] - 2026-10-15

### Changed

- A request to a host waits 240 seconds, not 30, before it counts as timed
  out (`HTTP_TIMEOUT_SECONDS`).
- When the request that creates a repository times out, the script asks the
  host whether the repository exists instead of stopping on the timeout. It
  goes on when the repository exists and is empty (Gitea: or holds just the
  license), and stops with a message that says what exists otherwise: nothing
  was created, or it holds content this run did not add and was not touched.
  Another network failure still stops the run at once.
- The five GitHub pictures in the Access tokens wiki page are annotated
  screenshots with numbered markers, in place of the drawn mockups, and the
  page has two more: the Confirm access page and the Generate token button.
  Names, photos and repositories in them are blurred.
- The framework submodule moves from `v0.8.0` to `v0.13.1`, and the use case
  folders move from `docs/uc-NNN/` to `docs/use-cases/uc-NNN/` (framework
  `v0.9.0`). `AGENTS.md` gains the AI prompt log section.

## [0.3.5] - 2026-10-14

### Changed

- The wiki pages move from `wiki/` to `docs/wiki/` and the `.publish` marker
  is removed. The `Publish wiki` workflow (`.gitea/workflows/publish-wiki.yml`,
  from `framework/templates/ci/`) now publishes them on a push to `main`.
- The framework submodule moves from `v0.6.2-2` to `v0.8.0` (through
  `v0.6.3` and `v0.7.0`; `v0.8.0` adds the clean architecture folder
  structure and names per language).
- `AGENTS.md` takes the review gate and the milestone publishing text from the
  framework's template.
- The four Gitea pictures in the Access tokens wiki page are annotated
  screenshots with numbered markers, in place of the drawn mockups. Names,
  photos and repositories in them are blurred. The GitHub pictures are
  unchanged.
- The README and the wiki Home page (English, Danish and Bahasa Malaysia) say
  that the SQA-QC-Framework is copyrighted, that access is not given by
  default, and whom to contact.

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
