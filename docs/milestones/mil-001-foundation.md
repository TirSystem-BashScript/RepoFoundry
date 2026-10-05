# MIL-001 Foundation

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-001 |
| CrossReference | [BC-001], [US-001], [UC-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Deprecated | Jens Tirsvad Nielsen | S02 | Initial version | [424f14f] |
| 2026-10-05 | Accepted | Jens Tirsvad Nielsen | S02 | Optional GitHub; choosing GitHub applies the AGPL license to the Gitea repository<br>Cited US-001.01<br>Target date accepted | [02875ae] |

---

## Purpose

Decide whether the secure base of `create-project.sh` is sound enough to build the host integration on: configuration, credential handling, logging, prompts and tests.

## Deliverable

`create-project.sh` skeleton that parses `config.env` and `.env` safely, validates input, prompts for the repository details and makes no network or filesystem change yet, together with `config.env.example`, `.env.example`, `.gitignore` and a test harness.

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | `shellcheck create-project.sh` reports no errors | Clean | Any error |
| 2 | Neither config file is `source`d; unknown keys and malformed lines are rejected | Tests pass | Any accepted |
| 3 | No token appears in stdout, stderr or a log in any test, including failure paths | None found | Any found |
| 4 | Missing `git` or `curl` stops the script before any change | Stops with a clear message | Continues |
| 5 | `.env` is ignored by git; both example files contain placeholders only | Verified | Real value present |
| 6 | All acceptance criteria of US-001.01 in [US-001] are met | Verified | Any unmet |

## Dependencies

| Depends on | Reason |
| --- | --- |
| None | First phase |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| User story US-001.01 | [US-001] |
| Objective 6 (no credential exposure, no overwrite) | [BC-001] |
| Success criteria 1 and 6 | [BC-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S01 |
| Approving reviewer | S02 |

## Target Date

2026-10-16 — the Business Case sets no deadline, so it does not constrain this date; accepted together with PP-001.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Define project name and configuration files | Keep the working name RepoFoundry in one constant so it is easy to change, and confirm on GitHub that the name is free (the exact name returned 404 on 2026-10-05; only `RepoFoundryAI` by another owner exists). Create `config.env.example` with `GITHUB_API_URL=https://api.github.com`, `GITHUB_WEB_URL=https://github.com`, `GITEA_URL=https://git.tirsystem.com/` and a Gitea API base (`GITEA_API_URL`, default `https://git.tirsystem.com/api/v1`; the request listed `GITEA_URL` twice, the second is treated as the API URL). Create `.env.example` with empty `GITHUB_PAT`, `GITHUB_USER`, `GITEA_TOKEN`. | No | |
| 2 | Script skeleton with strict mode and safe helpers | `set -Eeuo pipefail`, an ERR/EXIT trap, `mktemp` with `umask 077` and cleanup on exit, small single-purpose functions, logging helpers that redact known secret values, and no `rm -rf`. Follow the framework `coding-conventions` Shell rules. | No | |
| 3 | Safe parser for config.env and .env | Read `KEY=VALUE` lines without `source` or `eval`; accept only whitelisted keys, strip optional quotes, reject control characters, and validate that service URLs are well-formed `https` and that credentials are non-empty. Warn when `.env` is readable by other users. | No | |
| 4 | Tool check and HTTP helper | Check `git` and `curl` (and optional `jq`, with a fallback parser for the few JSON fields needed) before any change. Wrap `curl` so tokens go through a private curl config file or stdin rather than the command line (visible in process lists), with `--fail-with-body` handling, timeouts, and error messages that carry the HTTP status but never the credential. | No | |
| 5 | Interactive prompts and input validation | Prompt for repository name, description, visibility, whether to also create a GitHub repository (which also applies the AGPL license to the Gitea repository), and the owner or organization separately for Gitea and (if chosen) GitHub, with defaults taken from configuration. Validate names against both hosts' allowed characters. `GITHUB_USER` is only the authenticating account and is never assumed to be the owner. | Yes | [UC-001] |
| 6 | .gitignore and test harness | Add `.env` and temporary files to `.gitignore`. Add a test harness with stubbed `curl` and `git` that covers parser rejection cases and the no-token-in-output check, run alongside `shellcheck`. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[UC-001]: ../uc-001/uc.md
[424f14f]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/424f14f4f5577bb47fea41c8f3a655dca953e6d8
[02875ae]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/02875aee5f2953473924074eea0056eb31af6b7a
