# SQA Review Record: End-to-end test and final security review (MIL-003)

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-017 |
| CrossReference | [MIL-003], [MIL-002], [RC-016] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [613a288] |
| 2026-10-06 | Proposed | Jens Tirsvad Nielsen | S02 | Run A repeated with a `write:user` token: passes; criterion 7 now Pass; only the README review remains | [ef87e73] |

---

## Artifact Under Review

- Instance reviewed: the whole flow of `src/create-project.sh` (branch `mil-003-scaffold-and-release` plus the fixes below), run against real GitHub and Gitea repositories; this is task 6 (issue #20) of [MIL-003] and the live evidence for [MIL-002].
- Checklist used: the Go/No-Go criteria of [MIL-003] and the credential, ownership, mirror, submodule and API items named in its task 6. No QC checklist covers an end-to-end run; the code itself was reviewed in [RC-016].
- Review date: 2026-10-05
- Hosts: Gitea 1.27.3 at `git.tirsystem.com` (SSH on port 10022) and GitHub; real tokens from `.env` (a classic GitHub token with `repo` and `admin:org`; a Gitea token with `write:repository`, `write:organization`, `read:user` and other scopes; it lacked `write:user` until run A2, which used a token that has it).

## End-to-end runs

| Run | Owners | Result |
| --- | --- | --- |
| Dry run | `Tirsvad` on both hosts | All preflight checks passed; nothing created. |
| First `--apply` | `Tirsvad` on both hosts | Stopped before creating anything: **a defect** (see finding F1). |
| A, after the fix | user `Tirsvad` on both hosts | GitHub repository created. Gitea refused: `required=[write:user]`, which the token lacks. The script stopped, reported what existed (GitHub created, Gitea FAILED, the rest not attempted) and how to continue, and deleted nothing. |
| A2 | user `Tirsvad` on both hosts, repeated on 2026-10-06 with a `write:user` token; all eight project details came from `config.env` (MIL-004), so only "Create these now" and the reuse of the empty GitHub repository were asked | Everything created: the Gitea repository under the user account, the mirror, the local project, the framework, skills, hooks and templates; the empty GitHub repository left by run A was reused after confirmation. No warning. |
| B | organization `TirSystem-BashScript` on both hosts, plan gate on | Everything created: both repositories, the mirror, the local project, the framework, skills, hooks, plan gate and templates. No warning. |

After run A2 the following was checked independently of the script's own report: Gitea repository private, owner the user `Tirsvad`, default branch `main`, contents `LICENSE` and `README.md`; push mirror to `https://github.com/Tirsvad/repofoundry-e2e-user.git`, interval `10m0s`, `sync_on_commit` true, `last_error` empty; GitHub repository private with `LICENSE`, `README.md` and the one `Initial commit` that arrived through the mirror; local project on `main` with one commit, `origin` over SSH on port 10022 and `github` over HTTPS, neither with a credential, the framework submodule in place, `core.hooksPath` set and nothing committed by the script; neither token found in the project, its `.git` folder or the run output. The checks below were made after run B and still hold:

- **Gitea:** private, owner the organization, default branch `main`, contents `LICENSE` and `README.md`; push mirror to `https://github.com/TirSystem-BashScript/repofoundry-e2e-org.git`, interval `10m0s`, `sync_on_commit` true, `last_error` empty.
- **GitHub:** private, owner the organization, contents `LICENSE` and `README.md`, one commit `Initial commit` (arrived through the mirror).
- **Local project:** on `main` with that one commit as its whole history, tracking `origin`; `origin` is `ssh://git@git.tirsystem.com:10022/TirSystem-BashScript/repofoundry-e2e-org.git` and `github` is `https://github.com/TirSystem-BashScript/repofoundry-e2e-org.git`; the submodule `framework` comes from `ssh://git@git.tirsystem.com:10022/TirSystem/SQA-QC-Framework.git`; `core.hooksPath` is `framework/githooks` and `planGate.enabled` is true; skills are installed for both harnesses; `AGENTS.md` equals the framework template; no commit was made by the script.
- **Hooks and gate, for real:** a commit on `main` was refused ("refusing to commit directly on 'main'"); a `src/` change without a `Task:` trailer on a branch was refused ("plan-first gate"); a documentation-only commit on a branch was accepted.
- **Mirror direction, for real:** that commit was pushed to Gitea over SSH and the branch `work` appeared on GitHub within seconds, without a manual sync.

## Checklist Results (MIL-003 Go/No-Go)

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | `git remote -v` shows `origin` (Gitea) and, when GitHub was chosen, `github`, with no credentials in any URL; with GitHub chosen the local history contains the license commit | Pass | Run B: configured addresses above, credential-free; history is the Gitea license commit. |
| 2 | `framework` is a submodule of `ssh://git@git.tirsystem.com:10022/TirSystem/SQA-QC-Framework.git` and the install scripts have run once, in the documented order | Pass | Run B: `.gitmodules` holds that address; skills, then hooks, then templates; each once. |
| 3 | An existing directory, `AGENTS.md` or `docs/artifact-registry.md` is never overwritten without a yes | Pass | Verified by the automated tests with real git (existing directory, conflicting `LICENSE`, existing templates); not repeated on the real hosts. |
| 4 | With the plan gate enabled, a commit touching `src/` or `tests/` without a `Task: MIL-NNN#N` trailer is refused | Pass | Run B, for real. |
| 5 | An existing `core.hooksPath` is reported and not replaced without consent | Pass | Verified by the automated tests with real git (local and global setting); not repeated on the real hosts. |
| 6 | README covers installation, configuration, usage examples, security decisions, error handling and stakeholders, in clear English | N-A | The sections are written; the review by S02 has not happened yet (action item). |
| 7 | End-to-end run on disposable repositories passes and the final review records no open security finding | Pass | No open security finding. The organization-owner run (B) and the user-owner run (A2, with a `write:user` token) both pass on both hosts. |
| 8 | All acceptance criteria of US-001.03 in [US-001] are met | Pass | Run B: remotes without credentials, framework, skills, hooks, plan gate and templates in place; the "asks first" criterion by the automated tests. |

## Final security review

| Item | Result | Evidence |
| --- | --- | --- |
| Credential handling | No finding | Both tokens were searched for in every file of the new project, including the whole `.git` folder, and in all output of all runs: zero hits. Remote addresses and `.gitmodules` carry no credential. Tokens went to `curl` through a private configuration file and, for an HTTPS fetch, to git through `GIT_ASKPASS` and the environment (covered by tests; the live runs used SSH). |
| Repository ownership | No finding | Created under the owner chosen on both hosts (organization in run B; the user account on both hosts in run A2). `GITHUB_USER` was only a default. |
| Mirror direction | No finding | Gitea is the source: a branch pushed to Gitea reached GitHub on its own. Nothing was pushed from GitHub; that direction was not tested. |
| Submodule setup | No finding | Added over SSH on port 10022 from the configured framework repository; the SSH test and the host key check passed. |
| API limitations | Findings F2 to F4 | `sync_on_commit` was applied on Gitea 1.27.3 (the upstream bug did not occur). Token scopes and the README Gitea adds are covered below. |
| Residual risks | Accepted, documented | The mirror password (the GitHub token) is stored by the Gitea server. The tokens used here are broad (for example `admin:org` on GitHub); tokens limited to what the script needs would reduce the damage of a leak. |

## Findings

| # | Finding | Severity | Status |
| --- | --- | --- | --- |
| F1 | The real `ssh` used for the SSH test reads standard input and swallowed the answers meant for later prompts, so a run that was piped or pasted stopped before creating anything. The test stub did not read stdin, so no test could see it. | Defect (no data lost) | Fixed: stdin is closed for `ssh`, `git`, `curl` and the framework scripts; the test stub now reads stdin like the real tool; a regression test fails without the fix. |
| F2 | Gitea adds a generated `README.md` next to the `LICENSE`. The script, the README and MIL-002 criterion 2 assumed only the license. A repository this script created was therefore counted as "has content" and could not be reused after a partial failure. | Defect | Fixed: `LICENSE` and `LICENSE` + `README.md` count as content created by the script; any other file still counts as content; tests added; README corrected. MIL-002 criterion 2 corrected (new `Proposed` version row, to be accepted). |
| F3 | Creating a repository under one's own Gitea account needs the `write:user` scope, not `write:repository`. | Documentation | Fixed in the README, marked as confirmed by the server. |
| F4 | Documentation had marked two scopes "not confirmed". Result: `write:user` is needed for user-owned Gitea repositories (F3); organization-owned repositories worked with `write:organization`, `write:repository` and `read:user`, and the minimum was not narrowed down; the GitHub membership check worked with `repo` and `admin:org`, `read:org` alone was not tested. | Documentation | README updated with what was observed. |

## Files created and external prerequisites

The script creates, in the new project: `.git`, `.gitmodules`, `framework/` (submodule), `.agents/skills/` and `.claude/skills/`, `AGENTS.md`, `docs/artifact-registry.md`, and (through the Gitea history) `LICENSE` and `README.md`. It never deletes anything.

External prerequisites: bash 4.4 or later, `git`, `curl`, `mktemp`; optional `jq` and `ssh`. An SSH key in the Gitea account and a known host key for `git.tirsystem.com` port 10022 (the script refuses unknown host keys). A GitHub token that can create repositories and push (classic `repo`), only when GitHub is chosen. A Gitea token with `write:repository`, `write:organization` and `read:user`, plus `write:user` for a repository under one's own account. Push mirrors must be enabled on the Gitea server.

## Disposable resources left in place (nothing was deleted)

- Gitea: `TirSystem-BashScript/repofoundry-e2e-org` (private; branches `main` and `work`).
- GitHub: `TirSystem-BashScript/repofoundry-e2e-org` (private; branches `main` and `work`).
- Gitea: `Tirsvad/repofoundry-e2e-user` (private; branch `main`; created by run A2).
- GitHub: `Tirsvad/repofoundry-e2e-user` (private; branch `main`; created by run A, reused by run A2).
- Local temporary directories with the run output and the new projects.

## Overall Verdict

Go-with-conditions — No open security finding, both the organization-owner flow (run B) and the user-owner flow (run A2) work end to end on both hosts, and the two defects the live run found are fixed with regression tests. The one condition left is criterion 6: the README review by S02. Author and reviewer are the same person for now (S01 and S02 are both held by the Maintainer), so the framework independence rule is not met; re-review when a second person takes S02.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| Review the README against criterion 6 | S02 | 2026-10-12 |
| Accept the corrected criterion 2 of [MIL-002] (version row `Proposed`) | S02 | 2026-10-12 |
| Delete the disposable repositories listed above in the web interfaces | S01 | 2026-10-12 |
| Run `tests/run-tests.sh` on Linux and macOS (carried over from [RC-016]) | S02 | 2026-10-30 |
| Consider tokens limited to what the script needs, for the Gitea and GitHub accounts used with it | S02 | 2026-10-30 |

---

[MIL-003]: ../../milestones/mil-003-scaffold-and-release.md
[MIL-002]: ../../milestones/mil-002-repositories-and-mirror.md
[RC-016]: ./rc-016-create-project-sh.md
[US-001]: ../../user-stories.md
[613a288]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/613a288dead4c19c00dee6fbb60d46bc3edf8889
[ef87e73]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/ef87e7395482da9fad854cd5db7f16200bb8c8af
