# MIL-004 Configurable Details

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-004 |
| CrossReference | [BC-001], [US-001], [UC-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version | pending |

---

## Purpose

Decide whether the project details can be preset in `config.env` without weakening the safety questions: a detail that is set there is not asked, an invalid one stops the run, and the confirmations stay interactive.

## Deliverable

`create-project.sh` that reads eight optional keys from `config.env`, checks them with the same rules as the prompts, skips the prompt for each key that is set and marks that value as coming from the configuration in the summary. `config.env.example` and the README document the keys. The tests cover every key.

The keys (a key that is present counts as set, even when empty, but only the description may be empty):

| Key | Detail | Accepted value |
| --- | --- | --- |
| `PROJECT_NAME` | repository name | the repository name rules of the prompt |
| `PROJECT_DESCRIPTION` | description | up to 350 characters, no control characters; may be empty |
| `PROJECT_VISIBILITY` | visibility | `private` or `public` |
| `GITEA_OWNER` | Gitea owner (user or organization) | the Gitea owner rules of the prompt |
| `USE_GITHUB` | also create a GitHub repository | `yes` or `no` |
| `GITHUB_OWNER` | GitHub owner (user or organization) | the GitHub owner rules; used only when GitHub is used |
| `PROJECT_DIRECTORY` | local directory | the directory rules of the prompt |
| `ENABLE_PLAN_GATE` | enable the plan gate | `yes` or `no` |

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | For each of the eight keys: when it is present its prompt is not shown and its value is used and shown in the summary as coming from `config.env` | Tests pass | Any prompt shown or value ignored |
| 2 | A key that is absent is asked as before; asked and preset details can be mixed | Tests pass | Any asked wrongly |
| 3 | A present but empty value is accepted for `PROJECT_DESCRIPTION` and refused, naming the key, for the other seven | Tests pass | Any other result |
| 4 | An invalid value stops the run before any request to a host, names the key, and never falls back to asking | Tests pass | A request made or a prompt shown |
| 5 | `USE_GITHUB=no` skips the GitHub owner and the GitHub steps; a `GITHUB_OWNER` set while GitHub is not used is ignored with a warning | Tests pass | Any GitHub call or owner prompt |
| 6 | With all eight keys set, the only questions left are the confirmations: create now, reuse of an existing repository, directory, hooks path or file, each still defaulting to no | Tests pass | A confirmation skipped |
| 7 | The new keys are rejected in `.env`, and credentials are still rejected in `config.env` | Tests pass | Any accepted |
| 8 | All acceptance criteria of US-001.04 in [US-001] are met | Verified | Any unmet |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-003] | Needs the complete prompt and apply flow to change |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| User story US-001.04 | [US-001] |
| Objective 8 (details preset in `config.env`) | [BC-001] |
| Success criterion 8 | [BC-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S01 |
| Approving reviewer | S02 |

## Target Date

2026-11-20 — proposed; the Business Case sets no deadline.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Read and validate the eight optional config keys | Add `PROJECT_NAME`, `PROJECT_DESCRIPTION`, `PROJECT_VISIBILITY`, `GITEA_OWNER`, `USE_GITHUB`, `GITHUB_OWNER`, `PROJECT_DIRECTORY` and `ENABLE_PLAN_GATE` to the `config.env` parser, checked with the validators the prompts use. A present key counts as set; only the description may be empty. Errors name the key. The new keys are rejected in `.env`; credentials stay rejected in `config.env`. | Yes | [UC-001] |
| 2 | Use configured details instead of asking, and show their source | In the step that collects the details, take each configured value instead of asking and mark it `(from config.env)` in the summary. `USE_GITHUB=no` skips the GitHub owner; a `GITHUB_OWNER` set while GitHub is not used is ignored with a warning. Extension 3a of UC-001. | Yes | [UC-001] |
| 3 | Keep the confirmations interactive | Create now, reuse of an existing repository, directory, hooks path and template files stay questions that default to no, even when every detail is configured. Add tests that prove no run creates or replaces anything without them, because this is where a configurable run could weaken the rule never to overwrite without a yes. | No | |
| 4 | Document the keys | Add commented examples to `config.env.example` and a table of the keys to the README, with an example of a run in which only the confirmations are asked, and a note that a key that is present but empty counts as set. | No | |
| 5 | Test every key and case | Each key set, absent, empty and invalid; mixed asked and preset details; the `USE_GITHUB` interplay; the source marking in the summary; no prompt text shown for a preset detail; the existing tests unchanged. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[UC-001]: ../uc-001/uc.md
[MIL-003]: ./mil-003-scaffold-and-release.md
