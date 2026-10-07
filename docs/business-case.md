# Business Case

## Metadata
| Key | Value |
| --- | --- |
| ID | BC-001 |
| CrossReference | [SA-001], [UCD-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-07 | Deprecated | Jens Tirsvad Nielsen | S02 | Added objective 11 (global command, project created in the current folder), a scope item and success criterion 11 | [1cd27f7] |
| 2026-10-07 | Accepted | Jens Tirsvad Nielsen | S02 | Objective 11, scope item and criterion 11: the configuration files default to the working folder's, then the checkout's | [0ab5006] |

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

1. Optionally create an empty GitHub repository under a chosen user or organization.
2. Create a Gitea repository under a chosen user or organization, empty, or with a license: the one set in `config.env` (`PROJECT_LICENSE`), or AGPL-3.0 when GitHub is chosen, the project is public and none is set.
3. When GitHub was chosen, configure the Gitea repository as a push mirror to GitHub (direction Gitea to GitHub).
4. Create the local project directory with an `origin` (Gitea) remote and, when GitHub was chosen, a `github` remote, neither containing credentials.
5. Add the SQA-QC-Framework as the `framework` submodule with its own submodules (the `qc` checklists) fetched, install its skills and git hooks, and copy its templates, optionally enabling the plan gate.
6. Never print a token or put one in a URL, a remote or a log, write one to disk only in the new project's own `.env` and only after the Maintainer agrees, and never overwrite existing files or directories without consent.
7. Document installation, configuration, usage, security decisions and error handling in clear English for GitHub readers.
8. Let the Maintainer preset the project details in `config.env`, so that a detail that is set there is not asked again.
9. Ask for a credential that is not provided in `.env` (`GITEA_TOKEN`, `GITHUB_PAT`, `GITHUB_USER`) and, when the Maintainer agrees, create a `.env` file with the credentials the new project needs.
10. Let the Maintainer set the project's license in `config.env` (`PROJECT_LICENSE`), independent of the GitHub choice, or set `none` for no license.
11. Let the Maintainer start the script by name from the folder where the project is to be created, through a command link in a folder on `PATH`, using the `config.env` and `.env` in that folder, or the checkout's when it has none.

## Scope

### In Scope

- `create-project.sh`, `config.env.example`, `.env.example`, `.gitignore` and `README.md`.
- Safe parsing and validation of `config.env` and `.env` (never `source`d).
- Prompts for name, description, visibility and owner on each chosen host, and whether to use GitHub (which also applies the AGPL license when the project is public). Each of these details may be set in `config.env` instead and is then not asked.
- Checks for required tools (`git`, `curl`, optional `jq`) before any change.
- A check that the project name is not already taken on GitHub.
- Asking for a credential that `.env` does not provide, and creating the new project's own `.env` (owner-only, ignored by git, never overwritten without a yes).
- A project license set in `config.env` (`PROJECT_LICENSE`, optional, never asked), checked against the licenses the Gitea server offers.
- Partial-failure reporting with a documented way to continue.
- Starting through a command link: the script finds its own files from the link, the new project lands in the folder it was started in, and `./config.env` and `./.env` there are read before the checkout's (confirmed before the first request).
- Fetching the framework's own submodules (`git submodule update --init --recursive`), so the `qc` checklists are present.
- Documentation of the SSH prerequisite for the submodule (Gitea SSH on port `10022`).

### Out of Scope

- Deleting or rolling back repositories (no destructive commands; cleanup is manual and documented).
- Managing repositories after creation (branch protection, webhooks, teams, CI).
- Hosts other than GitHub and the configured Gitea instance.
- Creating or rotating tokens and SSH keys.
- Storing a credential anywhere but the new project's `.env` (no password manager, keychain or encryption).
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
| 1 | Credential exposure | 0 occurrences of a token in output, saved remote URLs, tracked files, config files or leftover temp files; a token is written only to the new project's `.env` (owner-only, ignored by git) and only after a yes | Test run with log review; `git config --get-regexp remote` inspected; every file of the new project searched for the tokens |
| 2 | Repository ownership | Each repository created is under the owner chosen at the prompt for that host, never silently under `GITHUB_USER` | Test run with a user owner and with an organization owner |
| 3 | Mirror direction | When GitHub is chosen, Gitea is the source and GitHub the target; a push to `origin` appears on GitHub | Push a test commit and compare |
| 4 | Partial failure | When one host fails, the output lists what was created and the command to continue | Forced failure test (invalid token for one host) |
| 5 | No overwrite | An existing directory or file is never replaced without a yes | Run twice in the same location |
| 6 | Lint | `shellcheck` reports no errors on `create-project.sh` | `shellcheck create-project.sh` |
| 7 | Documentation | `README.md` covers installation, configuration, usage, security decisions, error handling and stakeholders | Review by S02 against MIL-003 Go/No-Go criterion 6 |
| 8 | Preset details | A project detail set in `config.env` is never asked; an invalid one stops the run before any request and names the key | Tests with each key set, absent, empty and invalid |
| 9 | Credentials asked and kept | A credential missing from `.env` is asked (not echoed) instead of stopping the run; the new project's `.env` is created only after a yes, owner-only, ignored by git, holding only the keys the project needs, and an existing `.env` is never replaced without a yes | Tests: each credential present and missing, `.env` written, declined, existing, file mode, git exclusion, no token in output |
| 10 | Project license | `PROJECT_LICENSE` set: that license is on the Gitea repository with and without GitHub; `none`: no license; absent: AGPL-3.0 only when GitHub is chosen and the project is public; a license the server does not offer stops the run before anything is created | Tests with a license set, `none`, absent and not offered |
| 11 | Global command | Started through a command link in a `PATH` folder from another folder, the script runs, reads `./config.env` and `./.env` of that folder, else the checkout's, names them before any request, and creates the project under that folder | Test run through a link with files in the folder, in the checkout and in neither; the README example run once |

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Gitea ignores `sync_on_commit` when a push mirror is created through the API (known upstream issue) | Mirror only syncs on its interval | Set an interval, trigger a first sync through the API and report the effective setting |
| GitHub PAT lacks permission to create repositories or to push | Creation or mirroring fails | Document the required scopes; check with a read-only API call first and stop with a clear message |
| Gitea stores the mirror credentials server-side | A Gitea admin could access the GitHub token | Document it; recommend a fine-grained PAT limited to the one repository where possible |
| SSH to Gitea port `10022` is not configured | Submodule add fails after repositories already exist | Check SSH reachability before creating anything; document the prerequisite |
| A token written to the new project's `.env` is plain text on disk and could be committed or copied by mistake | A leaked token gives access to the hosts | Ask first (default no), write only the keys the project needs, mode owner-only, exclude the file from git through `.git/info/exclude`, never overwrite an existing `.env` without a yes, never print the value, document the risk |
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
- A token on disk only in the new project's `.env`, created by the script with the Maintainer's consent.
- The framework under `framework/` is not edited from this project.

## Cost–Benefit Assessment

| Costs | Benefits |
| --- | --- |
| Three planned phases of maintainer time; ongoing maintenance when the GitHub or Gitea API changes | Repeatable secure setup for every future project; fewer setup mistakes; reusable by GitHub readers |

The assessment is qualitative on purpose: this is internal tooling with no revenue, and there is no measurement of how long the manual setup takes today to compare against. The cost is maintainer time.

## Stakeholders

| Stakeholder ID (SA) | Interest in this project |
| --- | --- |
| S01 | Sets the scope and accepts the result |
| S02 | Reviews credential handling and the git host integration |
| S03 | Reads and may reuse the published project on GitHub |

## Recommendation

Proceed — the procedure is small, well bounded and removes a repeated, security-sensitive manual task.

---

[SA-001]: ./stakeholder-analysis.md
[UCD-001]: ./use-case-diagram.md
[1cd27f7]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/1cd27f77ed844773a969210a11de0d8bb98ac98f
[0ab5006]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/0ab50068bf9e5be82a801af9dbe5b763eeaf7f31
