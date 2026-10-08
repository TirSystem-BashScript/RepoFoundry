# User Story

## Metadata
| Key | Value |
| --- | --- |
| ID | US-001 |
| CrossReference | [BC-001], [UCD-001], [UC-002], [MIL-001], [MIL-002], [MIL-003], [MIL-004], [MIL-005], [MIL-006], [MIL-007], [MIL-008], [MIL-009] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-08 | Deprecated | Jens Tirsvad Nielsen | S02 | US-001.03: one remote, origin; no github remote (MIL-008) | [039a28c] |
| 2026-10-08 | Accepted | Jens Tirsvad Nielsen | S02 | US-001.03: `.claude`, `.agents` and `AGENTS.md` are excluded from git; MIL-009 added to CrossReference | [08cb484] |

---

## Purpose and Scope

One epic: "Create a new project" ([UC-001]), setting up a new project on Gitea, optionally on GitHub, with the SQA-QC-Framework in place. The actor is the Maintainer, as in [UCD-001] (S01 or S02; for now one person holds both roles).

The epic is split into seven stories, one per milestone (US-001.01 to US-001.07). Each story fits one two-week phase and can be shown working at the end of it.

## Story List

### US-001.01 — Create a new project: check and collect

**As a** Maintainer, **I want** the script to check my configuration, credentials and tools and ask for the project details before it changes anything, **so that** a mistake or a missing prerequisite is caught early and no token is ever exposed.

**Acceptance Criteria**

- Given `config.env` and `.env`, when the Maintainer starts the script, then the values are read and validated without being executed, and no token appears in any output.
- Given a missing tool, or a missing or malformed value, when the script starts, then it stops before any change and names the problem without showing a credential.
- Given valid configuration, when the script asks for the details, then the Maintainer can give the repository name, description, visibility, the Gitea owner, whether to also use GitHub (and its owner), the local directory and whether to enable the plan gate.

| Traces to | Size | INVEST exceptions |
| --- | --- | --- |
| [UC-001] steps 1 to 3, [MIL-001] | fits one phase | none |

### US-001.02 — Create a new project: repositories and mirror

**As a** Maintainer, **I want** the script to create the Gitea repository and, if I chose GitHub, an empty GitHub repository with a mirror from Gitea, **so that** the project starts with its repositories in place under the owners I chose.

**Acceptance Criteria**

- Given valid tokens and owners, when the script runs, then a Gitea repository exists under the chosen owner: empty, or holding the license that applies (the one set in `PROJECT_LICENSE`, or AGPL-3.0 when GitHub was chosen and the project is public).
- Given GitHub was chosen, when the script runs, then an empty GitHub repository exists under its chosen owner (not assumed to be `GITHUB_USER`) and Gitea mirrors to it, and no credential is stored in any address.
- Given a step fails, when the script stops, then it reports what was created and how to continue.

| Traces to | Size | INVEST exceptions |
| --- | --- | --- |
| [UC-001] steps 4 to 7, [MIL-002] | fits one phase | Independent: needs the checked input of US-001.01 |

### US-001.03 — Create a new project: local project

**As a** Maintainer, **I want** the script to create the local project with its remotes and the SQA-QC-Framework, **so that** I can start work in a ready project.

**Acceptance Criteria**

- Given the repositories exist, when the script finishes, then the project directory has one remote, `origin` (Gitea), with or without GitHub, containing no credential; there is no `github` remote, because a push to `origin` reaches GitHub through the mirror.
- Given the project directory, when the script finishes, then the framework, its skills and git hooks (and the plan gate if chosen) and the copied templates are in place.
- Given the framework steps ran, when the script finishes, then git ignores `.claude`, `.agents` and `AGENTS.md` in the project through `.git/info/exclude`: no `.gitignore` or tracked file is changed, nothing is committed, and a path git already tracks stays tracked and is named in the summary.
- Given a directory or file already exists, when the script would replace it, then it asks first.

| Traces to | Size | INVEST exceptions |
| --- | --- | --- |
| [UC-001] steps 8 to 10, [MIL-003], [MIL-009] | fits one phase | Independent: needs the repositories of US-001.02 |

### US-001.04 — Create a new project: preset the details

**As a** Maintainer, **I want** to set project details in `config.env`, **so that** the script does not ask for the same answers every time I create a project.

**Acceptance Criteria**

- Given a detail is set in `config.env`, when the script collects the details, then it does not ask for it, and the summary shows the value as coming from the configuration.
- Given a detail is not set in `config.env`, when the script collects the details, then it asks for it as before.
- Given a configured value is invalid, when the script starts, then it stops before any request to a host and names the key; it does not ask for the value instead.
- Given every detail is set, when the script runs, then the only questions left are the confirmations: create now, reuse of an existing repository, directory, hooks path or file.

| Traces to | Size | INVEST exceptions |
| --- | --- | --- |
| [UC-001] step 3, [MIL-004] | fits one phase | Independent: needs the prompts of US-001.01 |

### US-001.05 — Create a new project: ask for the credentials and keep them in the project

**As a** Maintainer, **I want** the script to ask for a credential that `.env` does not provide and to create a `.env` file in the new project, **so that** I can start without a prepared `.env` and the new project has the credentials its tools need.

**Acceptance Criteria**

- Given `GITEA_TOKEN` is not provided in `.env`, when the script starts, then it asks for it without showing what is typed and does not stop with an error; the same holds for `GITHUB_PAT` and `GITHUB_USER` when GitHub is chosen.
- Given an entered credential is not valid, when the script checks it, then it asks again and never shows the value.
- Given the project exists, when the Maintainer agrees, then the new project has a `.env` that holds only the credentials the project needs, is readable by its owner only and is ignored by git.
- Given the Maintainer declines, or `.env` already exists in the project and the Maintainer declines replacing it, then no `.env` is written or replaced and the summary says so.
- Given any run, then no credential appears in output, remotes, tracked files or the summary.

| Traces to | Size | INVEST exceptions |
| --- | --- | --- |
| [UC-001] steps 2 and 9, [MIL-005] | fits one phase | Independent: needs the local project of US-001.03 |

### US-001.06 — Create a new project: choose the license in `config.env`

**As a** Maintainer, **I want** to set the project's license in `config.env`, **so that** a project is not forced to AGPL-3.0 by the GitHub choice, a private project is never given it by default, and no question is needed for it.

**Acceptance Criteria**

- Given `PROJECT_LICENSE` is set to a license the Gitea server offers, when the script creates the Gitea repository, then it holds that license, with or without GitHub, and the license is not asked.
- Given `PROJECT_LICENSE=none`, then the repository has no license even when GitHub is chosen.
- Given `PROJECT_LICENSE` is absent, then the license is AGPL-3.0 when GitHub is chosen and the project is public, and none otherwise (a private project with GitHub gets none).
- Given the value is empty or invalid, or the server does not offer it, when the script starts or checks the hosts, then it stops before anything is created and names the key or the license.
- Given GitHub is chosen, then the license reaches the GitHub repository through the mirror, as before.

| Traces to | Size | INVEST exceptions |
| --- | --- | --- |
| [UC-001] steps 3, 4 and 6, [MIL-006] | fits one phase | Independent: needs the configurable details of US-001.04 |

### US-001.07 — Create a new project: the framework's own submodules are fetched

**As a** Maintainer, **I want** the new project to hold the framework together with its own submodules, **so that** the `qc` checklists are present without a manual step.

**Acceptance Criteria**

- Given the framework is added to the new project, when the step finishes, then `git submodule update --init --recursive` has run in the project and the framework's `qc` directory holds the checklists.
- Given `framework` already exists as the framework submodule, when the script runs again, then the same command runs, so an empty `qc` is filled and nothing else changes.
- Given the nested fetch fails, then the script stops that step, reports what exists, names the command to run by hand and does not show a credential.
- Given the framework has no submodule of its own, then the step changes nothing and does not fail.

| Traces to | Size | INVEST exceptions |
| --- | --- | --- |
| [UC-001] step 9, [MIL-007] | fits one phase | Independent: needs the framework step of US-001.03 |

## Epic: Start the script as a global command

One further epic, "Start the script as a global command" ([UC-002]), with one story. The actor is the Maintainer.

### US-002 — Start the script by name from the folder where the project is to be created

**As a** Maintainer, **I want** to start the script by a name from any folder and have the project created in the folder I stand in, **so that** I do not have to enter the checkout or type its path each time.

**Acceptance Criteria**

- Given a command link in a folder on `PATH` that leads to the script, when the Maintainer starts it by name from another folder, then the script runs and finds its own files.
- Given the Maintainer stands in a folder, when the project directory is not preset, then its default is `./<name>` under that folder, never under the checkout.
- Given `--config` and `--env` name files, then those are read. Given they are not named, then `./config.env` and `./.env` in the folder the Maintainer stands in are read, each one that exists, and the checkout's file stands in for one that does not.
- Given a file comes from the folder the Maintainer stands in, then the script names it and the Gitea address it holds and asks for a yes, default no, before any request; every file used is named in the output.
- Given `config.env` is named nowhere and is in neither folder, or a link is broken, then the script stops before any change and names both places it looked in.
- Given `.env` is named nowhere and is in neither folder, then the script goes on and asks for the credentials it needs, as in US-001.05.
- Given the README, then it shows the command that makes the link, the check that it works and a run from a folder that is not the checkout.

| Traces to | Size | INVEST exceptions |
| --- | --- | --- |
| [UC-002], [MIL-007] | fits one phase | Independent: needs the script of [UC-001] |

## INVEST Check

Valuable, Negotiable, Estimable, Small and Testable hold for each story. Independent holds only in part: the stories are ordered, each using what the one before it delivers, which follows the milestone order in [PP-001]. This is flagged as an exception on US-001.02 to US-001.07 and on US-002.

---

[BC-001]: ./business-case.md
[UCD-001]: ./use-case-diagram.md
[UC-001]: ./uc-001/uc.md
[UC-002]: ./uc-002/uc.md
[MIL-001]: ./milestones/mil-001-foundation.md
[MIL-002]: ./milestones/mil-002-repositories-and-mirror.md
[MIL-003]: ./milestones/mil-003-scaffold-and-release.md
[MIL-004]: ./milestones/mil-004-configurable-details.md
[MIL-005]: ./milestones/mil-005-credentials.md
[MIL-006]: ./milestones/mil-006-project-license.md
[MIL-007]: ./milestones/mil-007-framework-checklists.md
[MIL-008]: ./milestones/mil-008-gitea-only-remote.md
[MIL-009]: ./milestones/mil-009-exclude-framework-files.md
[PP-001]: ./project-plan.md
[039a28c]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/039a28c01b56f8cf0af73f55d1a604b43d67ba03
[08cb484]: https://git.tirsystem.com/TirSystem-BashScript/RepoFoundry/commit/08cb484498bab3d9480decda9df89e9564438185
