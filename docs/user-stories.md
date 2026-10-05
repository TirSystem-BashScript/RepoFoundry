# User Story

## Metadata
| Key | Value |
| --- | --- |
| ID | US-001 |
| CrossReference | [BC-001], [UCD-001], [MIL-001], [MIL-002], [MIL-003] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Deprecated | Jens Tirsvad Nielsen | S02 | Initial version | [424f14f] |
| 2026-10-05 | Accepted | Jens Tirsvad Nielsen | S02 | Optional GitHub; choosing GitHub applies the AGPL license to the Gitea repository<br>Cited UCD-001<br>Split the epic into three stories, one per milestone | [02875ae] |

---

## Purpose and Scope

One epic: "Create a new project" ([UC-001]), setting up a new project on Gitea, optionally on GitHub, with the SQA-QC-Framework in place. The actor is the Maintainer, as in [UCD-001] (S01 or S02; for now one person holds both roles).

The epic is split into three stories, one per milestone. Each story fits one two-week phase and can be shown working at the end of it.

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

- Given valid tokens and owners, when the script runs, then a Gitea repository exists under the chosen owner: empty, or holding the AGPL license when GitHub was chosen.
- Given GitHub was chosen, when the script runs, then an empty GitHub repository exists under its chosen owner (not assumed to be `GITHUB_USER`) and Gitea mirrors to it, and no credential is stored in any address.
- Given a step fails, when the script stops, then it reports what was created and how to continue.

| Traces to | Size | INVEST exceptions |
| --- | --- | --- |
| [UC-001] steps 4 to 7, [MIL-002] | fits one phase | Independent: needs the checked input of US-001.01 |

### US-001.03 — Create a new project: local project

**As a** Maintainer, **I want** the script to create the local project with its remotes and the SQA-QC-Framework, **so that** I can start work in a ready project.

**Acceptance Criteria**

- Given the repositories exist, when the script finishes, then the project directory has an `origin` remote and, if GitHub was chosen, a `github` remote, neither containing a credential.
- Given the project directory, when the script finishes, then the framework, its skills and git hooks (and the plan gate if chosen) and the copied templates are in place.
- Given a directory or file already exists, when the script would replace it, then it asks first.

| Traces to | Size | INVEST exceptions |
| --- | --- | --- |
| [UC-001] steps 8 to 10, [MIL-003] | fits one phase | Independent: needs the repositories of US-001.02 |

## INVEST Check

Valuable, Negotiable, Estimable, Small and Testable hold for each story. Independent holds only in part: the stories are ordered, each using what the one before it delivers, which follows the milestone order in [PP-001]. This is flagged as an exception on US-001.02 and US-001.03.

---

[BC-001]: ./business-case.md
[UCD-001]: ./use-case-diagram.md
[UC-001]: ./uc-001/uc.md
[MIL-001]: ./milestones/mil-001-foundation.md
[MIL-002]: ./milestones/mil-002-repositories-and-mirror.md
[MIL-003]: ./milestones/mil-003-scaffold-and-release.md
[PP-001]: ./project-plan.md
[424f14f]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/424f14f4f5577bb47fea41c8f3a655dca953e6d8
[02875ae]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/02875aee5f2953473924074eea0056eb31af6b7a
