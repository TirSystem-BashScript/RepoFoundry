# User Story

## Metadata
| Key | Value |
| --- | --- |
| ID | US-001 |
| CrossReference | [BC-001], [MIL-001], [MIL-002], [MIL-003] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [424f14f] |

---

## Purpose and Scope

One epic: setting up a new project on GitHub and Gitea with the SQA-QC-Framework in place. The actor is the Maintainer (S01 or S02; for now one person holds both roles). No Use Case Diagram exists yet, so the actor name is defined here and must be reused by the use case.

## Story List

### US-001.01 — Create a new project

**As a** Maintainer, **I want** to create a new project with empty GitHub and Gitea repositories, a Gitea to GitHub push mirror and a local project with the SQA-QC-Framework, **so that** every new project starts from the same secure, repeatable baseline.

**Acceptance Criteria**

- Given valid configuration and credentials, when the Maintainer answers the prompts, then an empty GitHub repository and an empty Gitea repository exist under the chosen owners.
- Given both repositories exist, when the mirror step finishes, then the Gitea repository is a push mirror to GitHub and no credential is stored in any remote URL.
- Given the repositories exist, when the local step finishes, then the project directory has `origin` (Gitea) and `github` remotes, the `framework` submodule, installed skills and hooks, and the copied templates.
- Given a step fails, when the script stops, then it reports what was created and how to continue.
- Given a target directory or file already exists, when the script would replace it, then it asks first.

| Traces to | Size | INVEST exceptions |
| --- | --- | --- |
| [UC-001], [MIL-001], [MIL-002], [MIL-003] | spans three phases; delivered by the tasks of each | Small: the story is split into tasks per phase |

## INVEST Check

Independent, Negotiable, Valuable, Estimable and Testable hold. Small does not: this is an epic-sized story, delivered through the tasks of the three milestones, with an exception recorded above.

---

[BC-001]: ./business-case.md
[UC-001]: ./uc-001/uc.md
[MIL-001]: ./milestones/mil-001-foundation.md
[MIL-002]: ./milestones/mil-002-repositories-and-mirror.md
[MIL-003]: ./milestones/mil-003-scaffold-and-release.md
[424f14f]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/424f14f4f5577bb47fea41c8f3a655dca953e6d8
