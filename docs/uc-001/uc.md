# Create a new project

## Metadata
| Key | Value |
| --- | --- |
| ID | UC-001 |
| CrossReference | [UCD-001], [US-001], [SA-001], [DM-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-06 | Accepted | Jens Tirsvad Nielsen | S02 | Credentials not in .env are asked (step 2, extension 2b); the project .env is created with consent (step 9, extensions 9c, 9d) | [ded26a6] |
| 2026-10-06 | Proposed | Jens Tirsvad Nielsen | S02 | The license comes from PROJECT_LICENSE (step 6, extension 4c); AGPL-3.0 is only the default when GitHub is chosen | [d773fa9] |

---

**Format:** Fully Dressed

## Fully Dressed

- **Scope:** RepoFoundry (`create-project.sh`)
- **Level:** user-goal
- **Primary Actor:** Maintainer (S01 or S02; one person holds both roles for now)
- **Stakeholders and Interests:**
  - S01 — new projects start from one repeatable, correct setup
  - S02 — credentials are never exposed and nothing is overwritten silently
  - S03 — the published procedure is documented and reusable
- **Preconditions:**
  - `config.env` exists and is valid. `.env` may be missing or hold only some credentials; a credential it does not provide is asked.
  - `config.env` may preset any of the project details of step 3, and may set the project license (`PROJECT_LICENSE`).
  - `git` and `curl` are installed.
  - The Maintainer has a Gitea token, a GitHub PAT and a GitHub account name (only when GitHub is chosen) and SSH access to Gitea on port 10022.
- **Postconditions (success guarantee):**
  - A repository exists on Gitea under the chosen owner. It is empty, or it holds the license file that applies: the license set in `config.env`, or AGPL-3.0 when the Maintainer chose GitHub and set none.
  - When the Maintainer chose to create a GitHub repository, an empty repository exists on GitHub under the chosen owner, the Gitea repository is a push mirror to it, and the license file, if any, reaches GitHub through the mirror.
  - A local project directory exists with credential-free remotes `origin` (Gitea) and, when GitHub was chosen, `github`, the `framework` submodule, installed skills and hooks, and the copied templates.
  - When the Maintainer agreed, the local project has a `.env` that holds only the credentials the project needs, is readable by its owner only and is ignored by git.
  - The Maintainer has a summary of what was created.

### Main Success Scenario

1. The Maintainer starts the project creation.
2. The system loads and validates the configuration and credentials and checks that the required tools exist. A credential that `.env` does not provide is asked, without echo; the GitHub credentials are asked once GitHub is chosen.
3. The Maintainer provides the repository name, description, visibility, the Gitea owner, whether to also create a GitHub repository (and if so its owner), the local directory, and whether to enable the plan gate. A detail that is set in `config.env` is not asked.
4. The system checks that the tokens needed for the chosen hosts work, that the owners accept new repositories, that the name is free on those hosts, that Gitea offers the license that applies (if any), and whether SSH to Gitea works.
5. Optional: if the Maintainer chose GitHub, the system creates the empty GitHub repository.
6. The system creates the Gitea repository. If a license applies, the repository is created with its license file and so is not empty; otherwise it is empty. The license that applies is the one set in `config.env` (`PROJECT_LICENSE`; `none` means no license); when none is set it is AGPL-3.0 if the Maintainer chose GitHub, and none otherwise. The license is never asked.
7. Optional: if GitHub was chosen, the system configures the Gitea repository as a push mirror to GitHub and verifies it. A license file in the Gitea repository is pushed to GitHub by the mirror.
8. The system creates the local project with the `origin` remote and, if GitHub was chosen, the `github` remote.
9. The system adds the framework submodule, installs its skills and hooks (and the plan gate if chosen) and copies the templates. If the Maintainer agrees, it also creates the project's own `.env` with the credentials the project needs.
10. The system reports a summary of what was created.

### Extensions (Alternative / Exception Flows)

- 2a. A required tool is missing, or a configuration value is missing or malformed:
  1. The system stops before any change and names the problem without showing a credential.
- 2b. A credential is not provided in `.env`:
  1. The system asks for it without showing what is typed. An invalid value is refused and asked again; when input ends the system stops before any change and names the key.
- 3a. A project detail is set in `config.env`:
  1. The system uses it and does not ask for it; the summary says it came from the configuration.
- 3b. A configured project detail is invalid:
  1. The system stops before any request and names the key; it does not ask for the value instead.
- 4a. A token is invalid, an owner does not accept the repository, or the name is taken:
  1. The system stops before creating anything and says which check failed. The GitHub token is only checked when GitHub was chosen.
- 4c. A license applies and the Gitea server does not offer it:
  1. The system stops before creating anything and names the missing license.
- 4b. SSH to Gitea does not work:
  1. The system uses HTTPS for `origin` and warns that the framework submodule step will fail until SSH is configured.
- 5a, 6a, 7a. A step fails after an earlier one succeeded:
  1. The system stops and reports what exists, what failed and how to continue.
- 8a, 9a. The target directory or a target file already exists:
  1. The system asks the Maintainer before replacing it; on no, it skips that item and reports it.
- 9b. A different git hooks setup is already configured in the project:
  1. The system asks before replacing it.
- 9c. The Maintainer declines creating the project's `.env`:
  1. The system creates none and says so in the summary.
- 9d. A `.env` already exists in the project:
  1. The system asks before replacing it; on no, it keeps it and reports it.

### Special Requirements / Business Rules

| Step | Rule |
| --- | --- |
| 2, 4 | A token never appears in output, logs, command lines, remote URLs or temporary files left behind |
| 2 | A credential that is asked is read without echo, validated like one read from `.env`, and held in memory for the run |
| 9 | The project's `.env` is the only place a token is written. It is created only after a yes (default no), holds only the keys the project needs (`GITEA_TOKEN`; `GITHUB_PAT` and `GITHUB_USER` when GitHub was chosen), is readable by its owner only, is excluded from git without changing a tracked file, and is never replaced without a yes |
| 3 | The GitHub owner and the Gitea owner are chosen separately; `GITHUB_USER` is only the authenticating account |
| 3 | A project detail set in `config.env` (the key is present, even if empty where an empty value is allowed) is not asked; only the confirmations stay interactive |
| 3, 5, 7 | GitHub is optional; without it no GitHub repository, mirror or `github` remote is created and the GitHub credentials are not required |
| 6 | The license that applies is added to the Gitea repository when it is created, so that repository is not empty: `PROJECT_LICENSE` if set (a Gitea license key such as `MIT`, or `none`), otherwise AGPL-3.0 when GitHub is chosen, otherwise none. It is independent of the GitHub choice when set, and it is never asked |
| 7 | The mirror direction is Gitea to GitHub; the GitHub repository stays empty and receives its content from the mirror |
| 8 | `origin` uses HTTPS derived from `GITEA_URL`, or SSH when the SSH test in step 4 passed; when the Gitea repository is not empty (GitHub chosen) the local project is created by fetching it, not by an unrelated `git init` history |
| 8, 9 | Nothing is overwritten or deleted without consent, and no commit is made |

### Open Issues

- The exact SSH `origin` URL form (port 10022) is settled in MIL-003.

---

[UCD-001]: ../use-case-diagram.md
[US-001]: ../user-stories.md
[SA-001]: ../stakeholder-analysis.md
[DM-001]: ./dm.md
[ded26a6]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/ded26a658c666bf29d84093cb352e3635e07719b
[d773fa9]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/d773fa91df5a54090254e12e074880fb6526a9ff
