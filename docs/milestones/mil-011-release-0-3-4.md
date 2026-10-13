# MIL-011 Release 0.3.4

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-011 |
| CrossReference | [BC-001], [US-001], [MIL-010] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-13 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version | pending |

---

## Purpose

Decide whether the work merged since `v0.3.3` is released as version 0.3.4. The last release is `v0.3.3` (2026-10-09); `main` is 24 commits ahead, and `VERSION` still says 0.3.3. [MIL-010] added no version bump, so the accepted `TOKEN_FOR_GITEA_WIKI` key and the wiki in three languages are in no release. A release is deliberate: the Release workflow runs only on request, defaults to a dry run, and refuses a version that has no entry in `CHANGELOG.md`.

## Deliverable

Version 0.3.4 of `create-project.sh`, released on Gitea: `VERSION` and the `--version` check say 0.3.4; `CHANGELOG.md` has a dated `## [0.3.4]` entry that lists every change since `v0.3.3` in the order Breaking, Added, Changed, Fixed, with `## [Unreleased]` left empty; the tag `v0.3.4` and its release page exist, made by the Release workflow from the tip of `main`, and the moving tag `v0` points to it.

The change is a patch release: the one change to the script is that a `.env` that holds `TOKEN_FOR_GITEA_WIKI` is accepted ([MIL-010]), and the rest is documentation and the wiki. The credentials the script asks for, its host requests and its steps do not change. The framework pin is not part of this phase.

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | `create-project.sh --version` prints `RepoFoundry 0.3.4` | Tests pass | Another version |
| 2 | `CHANGELOG.md` has a `## [0.3.4]` entry with its date, in the groups Breaking, Added, Changed, Fixed, that names `TOKEN_FOR_GITEA_WIKI`, the wiki in English, Danish and Bahasa Malaysia, and the guide moved from `howto/` to the wiki; `## [Unreleased]` holds no entry | Reviewed by S02 | An entry missing, or text left under Unreleased |
| 3 | The Quality run on the tip of `main` is green, and no test fails that passed at `v0.3.3` | Tests pass | A new failure |
| 4 | The Release workflow, run with version `0.3.4` and `dry_run` true, checks the version, the tip of `main` and the changelog entry and writes nothing | Dry run passes | The dry run reports an error |
| 5 | After the run with `dry_run` false, the tag `v0.3.4` and its release page exist on Gitea, and the page text is the changelog entry | Verified on Gitea | No tag, no page, or another text |
| 6 | The moving tag `v0` points to the same commit as `v0.3.4` | Verified on Gitea | `v0` elsewhere |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-010] | The accepted `.env` key and the wiki pages are what the release ships, and all of it must be merged first |

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

2027-01-05 — proposed; the Business Case sets no deadline.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Bump the version to 0.3.4 and write the changelog entry | Set `VERSION` in `src/lib/constants.sh` to 0.3.4 and the `--version` check in `tests/test-security.sh` to match. In `CHANGELOG.md` move the entries of `## [Unreleased]` under a dated `## [0.3.4]` and add what has merged since `v0.3.3`: `TOKEN_FOR_GITEA_WIKI` accepted in `.env` ([MIL-010]); the wiki in English, Danish and Bahasa Malaysia; the access-token guide moved from `howto/` to the wiki; the credential rules written down (`GITHUB_PAT` and `GITHUB_USER` only when GitHub is chosen). Leave `## [Unreleased]` empty. | No | |
| 2 | Release v0.3.4 | After the pull request of task 1 is merged, run the Release workflow on `main` with version `0.3.4` and `dry_run` true, read its output, then run it again with `dry_run` false. Check that the tag, the release page and the moving tag `v0` are as in criteria 5 and 6. Starting the second run is S01's decision. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[MIL-010]: ./mil-010-wiki-token-and-access-token-guide.md
