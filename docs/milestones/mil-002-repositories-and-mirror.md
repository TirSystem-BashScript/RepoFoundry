# MIL-002 Repositories and Mirror

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-002 |
| CrossReference | [BC-001], [US-001], [UC-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Accepted | Jens Tirsvad Nielsen | S02 | Optional GitHub; choosing GitHub applies the AGPL license to the Gitea repository<br>Cited US-001.02<br>Purpose and criterion 1 reworded for optional GitHub<br>Target date accepted | [02875ae] |
| 2026-10-05 | Proposed | Jens Tirsvad Nielsen | S02 | Criterion 2 corrected after the live run: Gitea also adds a README.md with the license | [613a288] |

---

## Purpose

Decide whether the script creates the Gitea repository and, if GitHub is chosen, the GitHub repository under the correct owners, and configures the Gitea to GitHub push mirror reliably, including when something fails halfway.

## Deliverable

`create-project.sh` creating a Gitea repository (with the AGPL license when GitHub is chosen, otherwise empty) and, if chosen, an empty GitHub repository, configuring the push mirror, verifying it, and printing a summary of what exists, with documented token permissions.

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | Repositories are created under the owner chosen at the prompt, for a user owner and for an organization owner, on each host used | Both verified | Any under the wrong owner |
| 2 | The GitHub repository is created empty. The Gitea repository holds only the AGPL license file and the `README.md` that Gitea generates for it when GitHub is chosen, otherwise it is empty. Neither has a `.gitignore` | Verified | Any other file present |
| 3 | When GitHub is chosen, a commit pushed to Gitea (including the license file) appears on GitHub; nothing flows the other way. When GitHub is not chosen, no GitHub call is made | Verified | Wrong direction, no sync, or a GitHub call without the choice |
| 4 | Mirror credentials are never part of a remote URL, log or output | None found | Any found |
| 5 | With an invalid token on one host, the script stops before creating anything or reports exactly what was created and how to continue | Verified | Silent or misleading |
| 6 | Required token scopes and the `sync_on_commit` limitation are documented | Present in README draft | Missing |
| 7 | All acceptance criteria of US-001.02 in [US-001] are met | Verified | Any unmet |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-001] | Needs the parser, HTTP helper and prompts |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| User story US-001.02 | [US-001] |
| Objectives 1, 2 and 3 | [BC-001] |
| Success criteria 2, 3 and 4 | [BC-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S02 |
| Approving reviewer | S01 |

## Target Date

2026-10-30 — the Business Case sets no deadline, so it does not constrain this date; accepted together with PP-001.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Preflight checks before any creation | With read-only calls, verify the tokens needed for the chosen hosts (`GET /user`; GitHub only when chosen), that the owner exists and the token may create repositories there, and that the name is free on both hosts, so one host is not created and the other refused. Also test SSH to `git.tirsystem.com` on port 10022 (needed for the submodule); its result decides whether `origin` later uses SSH (test passed) or HTTPS (default). | Yes | [UC-001] |
| 2 | Create the empty GitHub repository (optional) | Only when the Maintainer chose GitHub. `POST /user/repos` when the owner is the authenticated user, otherwise `POST /orgs/{org}/repos`, with `auto_init` false. Use the visibility from the prompt. Report the HTTP status and a hint on failure, without exposing the token. | Yes | [UC-001] |
| 3 | Create the Gitea repository, with AGPL license when GitHub is chosen | `POST /user/repos` or `POST /orgs/{org}/repos` on the Gitea API base, with no template, readme or gitignore. When GitHub is chosen, send `license` `AGPL-3.0` (listed by `GET /licenses`; check it exists first) with `auto_init` true so the license file is committed and the repository is not empty; otherwise `auto_init` false and the repository stays empty. Derive the clone URL from `GITEA_URL` and the selected owner. | Yes | [UC-001] |
| 4 | Configure the Gitea to GitHub push mirror (when GitHub is chosen) | Skip this step when GitHub was not chosen. Otherwise call `POST /repos/{owner}/{repo}/push_mirrors` with `remote_address` (the GitHub HTTPS URL built from `GITHUB_WEB_URL` and the GitHub owner, without credentials), `remote_username` (`GITHUB_USER`), `remote_password` (`GITHUB_PAT`), an interval and `sync_on_commit`. Gitea has a known issue where `sync_on_commit` can be ignored on API creation, so read the result back, trigger `push_mirrors-sync`, and report the effective setting. The PAT needs push access to the target repository (classic `repo` scope, or a fine-grained token with Contents write). Stop with a clear error if it is missing. Confirm the mirror feature is enabled on the Gitea server. | Yes | [UC-001] |
| 5 | Partial-failure reporting and resume | Track each step (GitHub repo, Gitea repo, mirror) in a state summary. When a step fails, print what succeeded, what did not, and the exact way to continue. When rerun and the repository already exists and is empty, offer to reuse it instead of failing. Never delete anything automatically. | No | |
| 6 | Document token permissions and API limitations | Draft the README sections on required GitHub PAT permissions (create in user or org, push), Gitea token scopes (repository write, organization write for org repos), the fact that Gitea stores the mirror password server-side, and the `sync_on_commit` limitation. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[UC-001]: ../uc-001/uc.md
[MIL-001]: ./mil-001-foundation.md
[02875ae]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/02875aee5f2953473924074eea0056eb31af6b7a
[613a288]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/613a288dead4c19c00dee6fbb60d46bc3edf8889
