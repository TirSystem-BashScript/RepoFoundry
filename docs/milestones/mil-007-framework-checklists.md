# MIL-007 Framework Checklists and Usage

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-007 |
| CrossReference | [BC-001], [US-001], [UC-001], [UC-002] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | Added UC-002 and US-002 (global command); tasks 2 and 3 trace to UC-002 | [1cd27f7] |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | Task 4 renamed so its issue title is unique (the sync matches issues by title) | pending |

---

## Purpose

Decide whether a new project holds the whole framework, including the `qc` checklists that the framework keeps in its own submodule, and whether a Maintainer can start the script from the folder where the project is to be created, through a global command, with the README saying exactly how.

## Deliverable

1. `create-project.sh` that, after adding the `framework` submodule (and when `framework` already exists as that submodule), runs `git submodule update --init --recursive` in the new project, so `framework/qc/` holds the checklists.
2. `create-project.sh` that finds its own files when started through a symlink, so a link in a folder on `PATH` works from any directory.
3. A README usage section that says: run the script from the folder in which the project is to be created (the default directory is `./<name>` relative to where it is started), keep `config.env` and `.env` in the checkout and point to them with `--config` and `--env` or place them where the script reads them, and make the script global with a worked example (a symlink in a `PATH` folder, with the check that it works), for Linux, macOS and Git Bash on Windows.

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | After a run, `framework/qc/` in the new project holds the checklist files and `git submodule status --recursive` shows no entry starting with `-` | Tests pass | An empty `qc` |
| 2 | A second run on a project whose `qc` is empty fills it and changes nothing else; on a complete project it changes nothing | Tests pass | Anything else changed |
| 3 | A failed nested fetch stops the step, reports what exists, names `git submodule update --init --recursive` as the command to run by hand and shows no credential | Tests pass | A credential shown, or the failure not reported |
| 4 | A framework without a submodule of its own does not make the step fail | Tests pass | Step fails |
| 5 | Started through a symlink in another folder, `create-project.sh --help` works and a run creates the project under the current folder | Tests pass | Files not found, or the project created elsewhere |
| 6 | The README example for the global command was run once as written and its check passed | Verified | An example that was not run |
| 7 | The README states the folder to start from and where the new project lands, with an example from a folder that is not the checkout | Reviewed by S02 | Missing or unclear |
| 8 | All acceptance criteria of US-001.07 and US-002 in [US-001] are met | Verified | Any unmet |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-003] | The framework step and the README already exist |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| User stories US-001.07 and US-002 | [US-001] |
| Objective 5 (the framework submodule) | [BC-001] |
| Objective 11 (global command) and success criterion 11 | [BC-001] |
| Objective 7 (documentation) | [BC-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S01 |
| Approving reviewer | S02 |

## Target Date

2026-12-11 — proposed; the Business Case sets no deadline.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Fetch the framework's own submodules | After `git submodule add` of the framework, and on the "already a submodule" path, run `git submodule update --init --recursive` in the new project. A failure stops the step, reports what exists and names the command to run by hand, without a credential. Step 9 and extension 9e of [UC-001]. | Yes | [UC-001] |
| 2 | Start through a command link | Resolve `BASH_SOURCE` through links (without requiring `readlink -f`, which macOS lacks) so `SCRIPT_DIR` and `PROJECT_ROOT` point into the checkout, and keep the current folder as the base of the default directory. Errors name the folder or path looked in. Steps 3 to 6 and extensions 4a and 4b of [UC-002]. | Yes | [UC-002] |
| 3 | Document the usage | Step 1 and extensions 1a and 3a of [UC-002]. README usage section: start from the folder where the project is to be created, where `config.env` and `.env` are read from, `--config` and `--env`, and the global command with a worked example and its check, for Linux, macOS and Git Bash on Windows. | Yes | [UC-002] |
| 4 | Test the qc fetch and the command link | `qc` filled after a run and after a rerun, nested fetch failure, framework without a submodule, start through a symlink from another folder. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[UC-001]: ../uc-001/uc.md
[UC-002]: ../uc-002/uc.md
[MIL-003]: ./mil-003-scaffold-and-release.md
[1cd27f7]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/1cd27f77ed844773a969210a11de0d8bb98ac98f
