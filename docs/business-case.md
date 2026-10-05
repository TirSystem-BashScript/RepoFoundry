# Business Case

## Metadata
| Key | Value |
| --- | --- |
| ID | BC-001 |
| CrossReference | [SA-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [424f14f] |

---

## Executive Summary

Starting a new project at TirSystem currently means several manual, error-prone steps across two git hosts: create a repository on GitHub, create a matching one on the self-hosted Gitea instance, wire a push mirror between them, then set up a local clone with the SQA-QC-Framework. RepoFoundry is a single Bash script (`create-project.sh`) that performs these steps from prompts and two small configuration files, handles credentials without ever exposing them, and reports exactly what succeeded when a step fails.

## Methodological and Standards Foundation

The project follows the SQA and QC framework mounted at `framework/` (plan-first gate, artifact catalog, QC checklists). Quality criteria are tagged with ISO/IEC 25010:2023 characteristics; security is the primary one (confidentiality of tokens), followed by reliability (partial-failure recovery) and maintainability. Code follows the framework's `coding-conventions` skill for Shell.

## Problem Statement

- Repository setup is repeated by hand for every new project and is easy to get subtly wrong (wrong owner, mirror in the wrong direction, tokens left in remote URLs).
- A half-finished setup (one host created, the other not) leaves no record of what exists.
- The framework submodule, skills, hooks and templates are installed inconsistently between projects.

## Business Opportunity

One repeatable, reviewed procedure gives every new project the same secure baseline: Gitea as the source of truth, GitHub as a mirror, and the SQA-QC-Framework in place from the first commit.

## Objectives

1. Create an empty GitHub repository under a chosen user or organization.
2. Create a matching empty Gitea repository under a chosen user or organization.
3. Configure the Gitea repository as a push mirror to GitHub (direction Gitea to GitHub).
4. Create the local project directory with `origin` (Gitea) and `github` remotes that contain no credentials.
5. Add the SQA-QC-Framework as the `framework` submodule, install its skills and git hooks, and copy its templates, optionally enabling the plan gate.
6. Never print or persist a token, and never overwrite existing files or directories without consent.

## Scope

### In Scope

- `create-project.sh`, `config.env.example`, `.env.example`, `.gitignore` and `README.md`.
- Safe parsing and validation of `config.env` and `.env` (never `source`d).
- Prompts for name, description, visibility and owner on both hosts.
- Checks for required tools (`git`, `curl`, optional `jq`) before any change.
- A check that the project name is not already taken on GitHub.
- Partial-failure reporting with a documented way to continue.
- Documentation of the SSH prerequisite for the submodule (Gitea SSH on port `10022`).

### Out of Scope

- Deleting or rolling back repositories (no destructive commands; cleanup is manual and documented).
- Managing repositories after creation (branch protection, webhooks, teams, CI).
- Hosts other than GitHub and the configured Gitea instance.
- Creating or rotating tokens and SSH keys.
- Making the first commit or opening a pull request.

## Expected Benefits

### Tangible Benefits

- Setup of a new project drops from several manual steps to one command.
- Every project starts with the same remotes, mirror direction and framework installation.

### Intangible Benefits

- Lower risk of credential leaks.
- A documented, reviewable setup procedure that GitHub readers can reuse.

## Strategic Alignment

Supports developing on self-hosted Gitea while publishing to GitHub, and adopting the SQA-QC-Framework as the standard process for new projects.

## Success Criteria

| # | Criterion | Target | Measure |
| --- | --- | --- | --- |
| 1 | Credential exposure | 0 occurrences of a token in output, saved remote URLs, config files or leftover temp files | Test run with log review; `git config --get-regexp remote` inspected |
| 2 | Repository ownership | Both repositories are created under the owner chosen at the prompt, never silently under `GITHUB_USER` | Test run with a user owner and with an organization owner |
| 3 | Mirror direction | Gitea is the source, GitHub the target; a push to `origin` appears on GitHub | Push a test commit and compare |
| 4 | Partial failure | When one host fails, the output lists what was created and the command to continue | Forced failure test (invalid token for one host) |
| 5 | No overwrite | An existing directory or file is never replaced without a yes | Run twice in the same location |
| 6 | Lint | `shellcheck` reports no errors on `create-project.sh` | `shellcheck create-project.sh` |

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Gitea ignores `sync_on_commit` when a push mirror is created through the API (known upstream issue) | Mirror only syncs on its interval | Set an interval, trigger a first sync through the API and report the effective setting |
| GitHub PAT lacks permission to create repositories or to push | Creation or mirroring fails | Document the required scopes; check with a read-only API call first and stop with a clear message |
| Gitea stores the mirror credentials server-side | A Gitea admin could access the GitHub token | Document it; recommend a fine-grained PAT limited to the one repository where possible |
| SSH to Gitea port `10022` is not configured | Submodule add fails after repositories already exist | Check SSH reachability before creating anything; document the prerequisite |
| Framework hook installer changes `core.hooksPath` | An existing hook setup is silently replaced | Inspect the current value first and ask for consent |
| Repository name conflicts on a host | Creation fails midway | Check availability on both hosts before creating either |

## Assumptions

- The Gitea instance exposes the v1 REST API including `push_mirrors` (confirmed on version 1.27.3 at `https://git.tirsystem.com`).
- The user has working SSH access to `git.tirsystem.com` on port `10022`.
- The GitHub PAT may be used both for API calls and as the push-mirror credential.

## Constraints

- Bash only, with `git` and `curl` required and `jq` optional.
- `config.env` and `.env` are parsed, never `source`d.
- No `rm -rf`, and no token in any URL, log or remote.
- The framework under `framework/` is not edited from this project.

## Cost–Benefit Assessment

| Costs | Benefits |
| --- | --- |
| Three planned phases of maintainer time; ongoing maintenance when the GitHub or Gitea API changes | Repeatable secure setup for every future project; fewer setup mistakes; reusable by GitHub readers |

## Stakeholders

| Stakeholder ID (SA) | Interest in this project |
| --- | --- |
| S01 | Product Owner and maintainer; sets scope and accepts the result |
| S02 | DevOps, cybersecurity and maintainer; reviews credential handling and git host integration |
| S03 | Reads and may reuse the published project on GitHub |

## Recommendation

Proceed — the procedure is small, well bounded and removes a repeated, security-sensitive manual task.

---

[SA-001]: ./stakeholder-analysis.md
[424f14f]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/424f14f4f5577bb47fea41c8f3a655dca953e6d8
