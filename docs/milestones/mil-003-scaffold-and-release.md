# MIL-003 Scaffold and Release

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-003 |
| CrossReference | [BC-001], [US-001], [UC-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [9ae0cba] |

---

## Purpose

Decide whether the project is ready to release: the local project is scaffolded with the framework, the documentation is complete and an end-to-end review found no credential, ownership or mirror-direction defect.

## Deliverable

Complete `create-project.sh` (local directory, credential-free remotes, framework submodule, skills, hooks, templates, optional plan gate), `README.md`, and a written final review with the list of external prerequisites.

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | `git remote -v` shows `origin` (Gitea) and `github` with no credentials in either URL | Verified | Any credential |
| 2 | `framework` is a submodule at the configured URL and the install scripts have run once, in the documented order | Verified | Missing or repeated |
| 3 | An existing directory, `AGENTS.md` or `docs/artifact-registry.md` is never overwritten without a yes | Verified by a second run | Overwritten |
| 4 | With the plan gate enabled, a commit touching `src/` or `tests/` without a `Task: MIL-NNN#N` trailer is refused | Verified | Accepted |
| 5 | An existing `core.hooksPath` is reported and not replaced without consent | Verified | Replaced silently |
| 6 | README covers installation, configuration, usage examples, security decisions, error handling and stakeholders, in clear English | Reviewed by S02 | Section missing |
| 7 | End-to-end run on disposable repositories passes and the final review records no open security finding | Recorded in an `RC-*` | Open finding |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-002] | Needs the remote repositories and the mirror |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| Objectives 4, 5 and 6 | [BC-001] |
| Success criteria 1, 5 and 6 | [BC-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S01 |
| Approving reviewer | S02 |

## Target Date

2026-11-13 — proposed.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Create the local project directory and credential-free remotes | After consent, create the directory (refuse to reuse an existing one without a yes), run `git init` on `main`, and add `origin` (Gitea) and `github` using URLs derived from the configured base URLs and the selected owners, with no token in any URL. `origin` uses HTTPS derived from `GITEA_URL`, unless the SSH test from the preflight passed, in which case it uses SSH on port 10022. Do not make a commit. | Yes | [UC-001] |
| 2 | Add the framework submodule | From the project directory run `git submodule add ssh://git@git.tirsystem.com:10022/TirSystem/SQA-QC-Framework.git framework`. Check beforehand that SSH on port 10022 works and stop with an actionable message if not. Document that this SSH access must be configured. | Yes | [UC-001] |
| 3 | Install skills and git hooks, with optional plan gate | Run `framework/scripts/install-skills.sh` and `install-git-hooks.sh`. The hook installer only sets `core.hooksPath` to `framework/githooks` and is safe to rerun, but it would replace a different existing value, so read the current value first and ask. Offer `--enable-plan-gate` as an optional choice, which requires a `Task: MIL-NNN#N` trailer on commits changing `src/` or `tests/`. | Yes | [UC-001] |
| 4 | Copy the framework templates without overwriting | Copy `AGENTS-template.md` to `AGENTS.md` and `artifact-registry-template.md` to `docs/artifact-registry.md` after `mkdir -p docs`, asking before replacing an existing file. | Yes | [UC-001] |
| 5 | Write README.md | Clear English for GitHub readers: installation, configuration (`config.env`, `.env`), usage examples, security decisions, error handling and partial-failure recovery, the SSH prerequisite for port 10022, token permissions, and the stakeholders: Tirsvad (Product Owner and maintainer, https://www.linkedin.com/in/tirsvad74), Michael Kragh (DevOps, cybersecurity and maintainer, https://www.linkedin.com/in/codemikemike/) and GitHub readers. | No | |
| 6 | End-to-end test and final security review | Run the whole flow against disposable repositories for a user owner and an organization owner. Review credential handling, repository ownership, mirror direction, submodule setup and API limitations, record the result in an `RC-*` review, and summarise the files created and the external prerequisites. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[UC-001]: ../uc-001/uc.md
[MIL-002]: ./mil-002-repositories-and-mirror.md
[9ae0cba]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/9ae0cba306577833480f692c67c0ec327ff2e24e
