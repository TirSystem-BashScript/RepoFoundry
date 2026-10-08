# MIL-009 Framework Files Excluded from Git

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-009 |
| CrossReference | [BC-001], [US-001], [UC-001], [OC-001], [DCD-002] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-08 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | pending |

---

## Purpose

Decide whether the files the framework installs into a new project, `.claude`, `.agents` and `AGENTS.md`, stay out of that project's git history. The skills in `.claude` and `.agents` are copies made by the framework's installer, and `AGENTS.md` is copied from a framework template. Git should not list them as untracked or offer them to a commit. They are excluded the way the project's `.env` already is: in `.git/info/exclude`, which belongs to the clone, is never committed and changes no tracked file.

## Deliverable

`create-project.sh` that, once the framework's skills and the templates are in place, adds `/.claude`, `/.agents` and `/AGENTS.md` to `.git/info/exclude` of the new project, as its own step ("Git excludes") that shows in the dry-run plan and in the summary. The documents agree with it: Business Case objective 5, US-001.03, UC-001 (postcondition, step 9, extension 9f and a rule), OC-001 (P15 and two exceptions), SD-001, DCD-001 and DCD-002, DM-001 and DM-002, and the dictionary. `README.md` says which files are excluded and why, and how to track one anyway. The tests cover the cases below. The version is raised to 0.3.2, and release `v0.3.2` is tagged on Gitea after the pull request is merged.

The exclusion is not applied when the framework steps are skipped (no SSH to Gitea): nothing was installed. A path that git already tracks stays tracked: the script never runs `git rm`, and the summary names the path, because an exclude entry does not apply to a tracked file. `framework`, `.gitmodules` and `docs/artifact-registry.md` are not excluded; the submodule and the registry are part of the project. The files of this repository (RepoFoundry itself) are unchanged.

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | After a run with the framework steps, `git check-ignore` reports `.claude`, `.agents` and `AGENTS.md` as ignored in the new project, and `git status --porcelain` lists none of them although they exist | Tests pass | Any of the three listed or not ignored |
| 2 | The entries are written only to `.git/info/exclude`: no `.gitignore` is created or changed, no tracked file changes and nothing is committed | Tests pass | Any other file changed |
| 3 | A second run writes no entry twice, keeps the existing lines of `.git/info/exclude` each on its own line (also when the file has no final newline), and writes nothing for a path that is already ignored | Tests pass | A duplicate, a merged line or a lost line |
| 4 | A path that git already tracks is neither untracked nor changed, and the summary names it as not ignored | Tests pass | A path untracked, or the summary silent |
| 5 | With the framework steps skipped (no SSH to Gitea) nothing is added to `.git/info/exclude` and the step reports `skipped` | Tests pass | An entry written |
| 6 | `framework`, `.gitmodules` and `docs/artifact-registry.md` are not ignored in the new project | Tests pass | Any of them ignored |
| 7 | The dry run lists the "Git excludes" step with the three entries and changes nothing; the summary reports the step in the same words | Tests pass | A change in a dry run, or the step missing |
| 8 | The `.env` exclusion behaves as before: added only after the yes, once, with the same comment line | Tests pass | A changed result |
| 9 | The README, Business Case, UC-001, OC-001, SD-001, DCD-001, DCD-002, DM-001 and DM-002 describe the exclusion and agree with the code; the documents the model does not change say so | Reviewed by S02 | A document that contradicts the code |
| 10 | All acceptance criteria of US-001.03 in [US-001] are met | Verified | Any unmet |
| 11 | `create-project.sh --version` prints `RepoFoundry 0.3.2` | Tests pass | Another version |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-003] | The framework, skills and templates steps are the ones that install the files |
| [MIL-005] | The `.git/info/exclude` code written for the project's `.env` is reused |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| User story US-001.03 | [US-001] |
| Objective 5 (the framework, its skills and its templates in the new project) | [BC-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S01 |
| Approving reviewer | S02 |

## Target Date

2026-12-23 — proposed; the Business Case sets no deadline.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Update the analysis and design documents | Business Case objective 5 and scope, the acceptance criteria of US-001.03, UC-001 (postcondition, step 9, extension 9f for a tracked path, and a rule), OC-001 (postcondition P15 and two exceptions), SD-001 (`excludeFromGit` inside `install`), DCD-001 and DCD-002 (`FrameworkInstaller.excludeFromGit`, `InstallResult.trackedPaths`), and the definitions of Framework Setup and Template in DM-001, DM-002 and the dictionary. | No | |
| 2 | Add the Git excludes step | Move the work of `exclude_env_file` (`src/lib/envfile.sh`) into a helper that adds a list of entries to `.git/info/exclude`: one comment line, a fresh line first, no entry that `git check-ignore` already reports, a check afterwards. `exclude_env_file` keeps its behavior and uses it. Add a function in `src/lib/framework.sh` that excludes `/.claude`, `/.agents` and `/AGENTS.md`, called from `create_all` (`src/lib/apply.sh`) after `copy_templates`, with its own label in `PLAN_STEPS` (`src/lib/constants.sh`) and a line in the dry-run plan (`src/lib/plan.sh`). It is skipped when `is_framework_skipped` and it names any path git tracks. Step 9 of [UC-001] and P12 of [OC-001]. | Yes | [UC-001] |
| 3 | Describe the excluded files in the README | Add the step to the overview and the numbered run steps, and the new line to the sample plan output. Say which paths are excluded and why (they come from the framework and are made again by `bash framework/scripts/install-skills.sh`), that nothing is committed or changed in a tracked file, that the entries live in `.git/info/exclude` and so are not shared with a clone, and how to track one anyway (remove its line from `.git/info/exclude`). | No | |
| 4 | Test the excludes | In the style of `tests/test-credentials.sh`: the three paths ignored and absent from `git status` after a run; a second run adds nothing; a file without a final newline keeps its lines; a tracked `AGENTS.md` stays tracked and is named; framework steps skipped writes nothing; `framework`, `.gitmodules` and `docs/artifact-registry.md` not ignored; the dry run changes nothing; the existing `.env` exclude tests still pass. | No | |
| 5 | Bump the version to 0.3.2 | Set `VERSION` in `src/lib/constants.sh` to 0.3.2 and the `--version` check in `tests/test-security.sh` to match. Release `v0.3.2` is tagged on Gitea from the merge commit once the pull request is merged. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[UC-001]: ../uc-001/uc.md
[OC-001]: ../uc-001/oc.md
[DCD-002]: ../dcd.md
[MIL-003]: ./mil-003-scaffold-and-release.md
[MIL-005]: ./mil-005-credentials.md
