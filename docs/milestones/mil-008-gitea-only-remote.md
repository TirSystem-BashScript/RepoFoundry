# MIL-008 Gitea Is the Only Remote

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-008 |
| CrossReference | [BC-001], [US-001], [UC-001], [OC-001], [DCD-002] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-08 | Deprecated | Jens Tirsvad Nielsen | S02 | Initial version | [039a28c] |
| 2026-10-08 | Accepted | Jens Tirsvad Nielsen | S02 | Task 4 and criterion 7: the version is raised to 0.3.1 and release v0.3.1 is tagged after the merge | [1056639] |

---

## Purpose

Decide whether the local project can keep a single remote, `origin` (Gitea), with or without GitHub. Gitea pushes to GitHub through the push mirror, so a push to `origin` already reaches GitHub; a second `github` remote adds nothing and invites a push that goes around the mirror, with a token typed by hand. The first version of the documents and of the script added that remote when GitHub was chosen; this phase removes it.

## Deliverable

`create-project.sh` that adds only the `origin` remote to the local project, whether or not GitHub was chosen, and no longer builds a GitHub remote address. The documents agree with it: Business Case objective 4, US-001.03, UC-001 (postcondition and step 8), OC-001 P9, SD-001, DCD-001 and DCD-002, DM-001 and DM-002. `README.md` describes the one remote and says that a push to `origin` reaches GitHub through the mirror. The tests cover both cases. The version is raised to 0.3.1, and release `v0.3.1` is tagged on Gitea after the pull request is merged.

A project that already has a `github` remote, such as one created by an earlier version of the script, keeps it: the script never removes or replaces a remote (it still refuses an `origin` that points elsewhere).

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | With GitHub chosen, `git remote` in the new project lists exactly `origin`; without GitHub it lists exactly `origin` as well | Tests pass | Any other remote |
| 2 | No `remote.github.*` key and no GitHub address is in the new project's `.git/config`, and `origin` keeps its address (SSH if the test passed, else HTTPS) with no credential | Tests pass | A `github` key, a GitHub address or a credential |
| 3 | A project directory that already has a `github` remote keeps it unchanged and the run does not fail because of it; a different `origin` is still refused | Tests pass | The remote removed, replaced or the run stopped |
| 4 | With GitHub chosen the mirror, the license history and the other steps are unchanged | Tests pass | Any other step changed |
| 5 | The README, UC-001, OC-001, SD-001, DCD-001, DCD-002, DM-001 and DM-002 all describe one remote and agree with the code | Reviewed by S02 in [RC-031] | A document still naming a `github` remote |
| 6 | All acceptance criteria of US-001.03 in [US-001] are met | Verified | Any unmet |
| 7 | `create-project.sh --version` prints `RepoFoundry 0.3.1` | Tests pass | Another version |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-002] | The push mirror is what makes a second remote unnecessary |
| [MIL-003] | The step that creates the local project and its remotes is the one that changes |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| User story US-001.03 | [US-001] |
| Objective 4 (the local project with its remotes) | [BC-001] |
| Success criteria 1 (credential exposure: fewer places a token can be typed into an address) and 3 (mirror direction: a push to `origin` appears on GitHub) | [BC-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S01 |
| Approving reviewer | S02 |

## Target Date

2026-12-18 — proposed; the Business Case sets no deadline.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Add only the origin remote | In `create_local_project` (`src/lib/localproject.sh`) stop adding the `github` remote, with or without GitHub, and delete `github_remote_url` (`src/lib/hosts.sh`), which nothing else uses. `origin` is unchanged (SSH on the configured port when the SSH test passed, else HTTPS, no credential). An existing `github` remote is left alone; a different `origin` is still refused. Step 8 of [UC-001] and P9 of [OC-001]. | Yes | [UC-001] |
| 2 | Describe the one remote in the README | Update the overview, the run steps and the "Credential-free remotes" security point: the project has one remote, `origin`, and a push to it reaches GitHub through the Gitea push mirror. Mention that a `github` remote from an earlier version can be removed with `git remote remove github`. | No | |
| 3 | Test the single remote | Replace the `github` remote assertion of `test_local_project_gets_credential_free_remotes_and_the_license_history` with "only `origin`, no GitHub address in `.git/config`", keep the Gitea-only case, add a rerun on a directory that already has a `github` remote (kept, no failure), and drop the `github_remote_url` check from `test_remote_addresses_are_built_from_the_configuration`. | No | |
| 4 | Bump the version to 0.3.1 | Set `VERSION` in `src/lib/constants.sh` to 0.3.1 and the `--version` check in `tests/test-security.sh` to match. Release `v0.3.1` is tagged on Gitea from the merge commit once the pull request is merged. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[UC-001]: ../uc-001/uc.md
[OC-001]: ../uc-001/oc.md
[DCD-002]: ../dcd.md
[MIL-002]: ./mil-002-repositories-and-mirror.md
[MIL-003]: ./mil-003-scaffold-and-release.md
[RC-031]: ../sqa/reviews/rc-031-gitea-only-remote.md
[039a28c]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/039a28c01b56f8cf0af73f55d1a604b43d67ba03
[1056639]: https://git.tirsystem.com/TirSystem-BashScript/RepoFoundry/commit/1056639d5b0f84ce8b591e33e8f5a1e03e99de37
