# MIL-006 Project License

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-006 |
| CrossReference | [BC-001], [US-001], [UC-001], [DCD-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | AGPL-3.0 default only when GitHub is chosen and the project is public (purpose, resolution order, criterion 3, tasks 1 and 4) | [1cd27f7] |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | Task 4 renamed so its issue title is unique (the sync matches issues by title) | pending |

---

## Purpose

Decide whether the project's license can be set in `config.env` without weakening the existing behaviour: a license that is set applies with or without GitHub, `none` means no license, an absent key gives AGPL-3.0 only when GitHub is chosen and the project is public, and a license the Gitea server does not offer stops the run before anything is created.

## Deliverable

`create-project.sh` that reads one more optional key from `config.env`, `PROJECT_LICENSE`, checks it, resolves the license that applies, checks that Gitea offers it, creates the Gitea repository with it and shows it in the plan and summary. `config.env.example` and the README document the key. The tests cover every case.

The key (present counts as set, as for the other project details of [MIL-004]; an empty value is refused):

| Key | Detail | Accepted value |
| --- | --- | --- |
| `PROJECT_LICENSE` | the license of the project | a Gitea license key (letters, digits, `.`, `+`, `-`, at most 64 characters), such as `AGPL-3.0` or `MIT`, or `none` |

The license that applies is resolved in this order: `PROJECT_LICENSE` when set (`none` means no license), otherwise AGPL-3.0 when GitHub is chosen and the project is public, otherwise none. A private project with GitHub therefore gets no license by default. It is never asked: the key is an optional project detail in `config.env`, not a prompt.

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | With `PROJECT_LICENSE` set to a license the server offers, the Gitea repository is created with that license, with GitHub and without it, and the plan and summary show it as coming from `config.env` | Tests pass | Another license, none, or no marker |
| 2 | `PROJECT_LICENSE=none`: the Gitea repository has no license, also when GitHub is chosen | Tests pass | Any license applied |
| 3 | `PROJECT_LICENSE` absent: AGPL-3.0 when GitHub is chosen and the project is public; none for a private project with GitHub, and none without GitHub; the plan and summary say which rule applied | Tests pass | AGPL-3.0 on a private project, or no AGPL-3.0 on a public project with GitHub |
| 4 | An empty or invalid value stops the run before any request to a host, names the key and never falls back to asking | Tests pass | A request made or a prompt shown |
| 5 | A license the Gitea server does not offer stops the run before anything is created and names the license | Tests pass | Anything created |
| 6 | The license is never asked, with the key set, absent or invalid | Tests pass | Any prompt for it |
| 7 | The mirror, the local history and the other steps are unchanged: with GitHub chosen the license file reaches the local project through the Gitea history, as before | Tests pass | Any other step changed |
| 8 | All acceptance criteria of US-001.06 in [US-001] are met | Verified | Any unmet |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-004] | The key is one more project detail read, validated and marked by the code of the configurable details |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| User story US-001.06 | [US-001] |
| Objective 10 (project license in `config.env`) and the amended objective 2 | [BC-001] |
| Success criterion 10 | [BC-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S01 |
| Approving reviewer | S02 |

## Target Date

2026-12-04 — proposed; the Business Case sets no deadline.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Read and validate `PROJECT_LICENSE` | Add the key to the `config.env` parser and its validator (a license key or `none`; empty refused; errors name the key). Resolve the license that applies into the project request (key set, else AGPL-3.0 with GitHub and a public project, else none) and mark it `(from config.env)` in the summary. Never asked. Extensions of step 3 of [UC-001]. | Yes | [UC-001] |
| 2 | Apply the license on Gitea, independent of GitHub | Generalize the preflight check from the fixed AGPL-3.0 to the license that applies (checked only when one applies); create the repository with it; the plan, the summary and the reuse warning name the license that applies instead of AGPL-3.0; GitHub receives the file through the mirror as before. Extension 4c and step 6 of [UC-001]. | Yes | [UC-001] |
| 3 | Document the key | Commented example in `config.env.example`, a row in the README table of project details, and the rule for the license that applies, including `none` and the default. | No | |
| 4 | Test every license case | Key set (with and without GitHub), `none`, absent (public and private, with and without GitHub), empty, invalid and not offered by the server; never asked; the summary marker; the existing tests changed only where a private project with GitHub no longer gets AGPL-3.0. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[UC-001]: ../uc-001/uc.md
[DCD-001]: ../uc-001/dcd.md
[MIL-004]: ./mil-004-configurable-details.md
[1cd27f7]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/1cd27f77ed844773a969210a11de0d8bb98ac98f
