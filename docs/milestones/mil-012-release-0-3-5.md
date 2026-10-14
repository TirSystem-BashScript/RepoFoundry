# MIL-012 Release 0.3.5

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-012 |
| CrossReference | [BC-001], [US-001], [MIL-011] |
| Language | en |
| Domain | it |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-14 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [4b4ec59] |

---

## Purpose

Decide whether the work merged since `v0.3.4` is released as version 0.3.5. The last release is `v0.3.4` (2026-10-13); `main` is ahead by the framework pin moves, the wiki move and its publishing workflow, the annotated Gitea pictures and the framework-access note. `CHANGELOG.md` already has the dated `## [0.3.5]` entry (pull request 101), but `VERSION` still says 0.3.4, so a tag `v0.3.5` would ship a script that reports the older version. A release is deliberate: the Release workflow runs only on request, defaults to a dry run, and refuses a version that has no entry in `CHANGELOG.md`.

## Deliverable

Version 0.3.5 of `create-project.sh`, released on Gitea: `VERSION` and the `--version` check say 0.3.5; `CHANGELOG.md` keeps its dated `## [0.3.5]` entry and an empty `## [Unreleased]`; the tag `v0.3.5` and its release page exist, made by the Release workflow from the tip of `main`, and the moving tag `v0` points to it.

The change is a patch release: the only change to the script is its version number. The credentials the script asks for, its host requests and its steps do not change.

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | `create-project.sh --version` prints `RepoFoundry 0.3.5` | Tests pass | Another version |
| 2 | `CHANGELOG.md` has a `## [0.3.5]` entry with its date that matches the changes since `v0.3.4`, and `## [Unreleased]` holds no entry | Reviewed by S02 | An entry missing, or text left under Unreleased |
| 3 | The Quality run on the tip of `main` is green, and no test fails that passed at `v0.3.4` | Tests pass | A new failure |
| 4 | The Release workflow, run with version `0.3.5` and `dry_run` true, checks the version, the tip of `main` and the changelog entry and writes nothing | Dry run passes | The dry run reports an error |
| 5 | After the run with `dry_run` false, the tag `v0.3.5` and its release page exist on Gitea, and the page text is the changelog entry | Verified on Gitea | No tag, no page, or another text |
| 6 | The moving tag `v0` points to the same commit as `v0.3.5` | Verified on Gitea | `v0` elsewhere |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-011] | The release process and the `0.3.4` baseline it follows |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| Release of the script that creates a project repeatably | [BC-001] |
| User story US-001 | [US-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S01 |
| Approving reviewer | S02 |

## Target Date

2027-01-07 — proposed; the Business Case sets no deadline.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Bump the version to 0.3.5 | Set `VERSION` in `src/lib/constants.sh` to 0.3.5 and the `--version` check in `tests/test-security.sh` to match. `CHANGELOG.md` is already written; check that its `## [0.3.5]` entry still lists every change since `v0.3.4` and that `## [Unreleased]` is empty. | No | |
| 2 | Release v0.3.5 | After the pull request of task 1 is merged, run the Release workflow on `main` with version `0.3.5` and `dry_run` true, read its output, then run it again with `dry_run` false. Check that the tag, the release page and the moving tag `v0` are as in criteria 5 and 6. Starting the second run is S01's decision. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[MIL-011]: ./mil-011-release-0-3-4.md
[4b4ec59]: https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/commit/4b4ec5914d18837229296562d3a7d2283e9aa5fb
