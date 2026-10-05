# Create a new project

## Metadata
| Key | Value |
| --- | --- |
| ID | UC-001 |
| CrossReference | [UCD-001], [US-001], [SA-001], [DM-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Accepted | Jens Tirsvad Nielsen | S02 | Optional GitHub; choosing GitHub applies the AGPL license to the Gitea repository<br>Cited DM-001 and UCD-001 | [02875ae] |
| 2026-10-05 | Accepted | Jens Tirsvad Nielsen | S02 | Step 3: details set in config.env are not asked (extensions 3a, 3b) | pending |

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
  - `config.env` and `.env` exist and are valid.
  - `config.env` may preset any of the project details of step 3.
  - `git` and `curl` are installed.
  - The Maintainer has a Gitea token, a GitHub PAT (only when GitHub is chosen) and SSH access to Gitea on port 10022.
- **Postconditions (success guarantee):**
  - A repository exists on Gitea under the chosen owner. It is empty, or, when the Maintainer chose GitHub, it holds the AGPL license file.
  - When the Maintainer chose to create a GitHub repository, an empty repository exists on GitHub under the chosen owner, the Gitea repository is a push mirror to it, and the AGPL license file reaches GitHub through the mirror.
  - A local project directory exists with credential-free remotes `origin` (Gitea) and, when GitHub was chosen, `github`, the `framework` submodule, installed skills and hooks, and the copied templates.
  - The Maintainer has a summary of what was created.

### Main Success Scenario

1. The Maintainer starts the project creation.
2. The system loads and validates the configuration and credentials and checks that the required tools exist.
3. The Maintainer provides the repository name, description, visibility, the Gitea owner, whether to also create a GitHub repository (and if so its owner), the local directory, and whether to enable the plan gate. A detail that is set in `config.env` is not asked.
4. The system checks that the tokens needed for the chosen hosts work, that the owners accept new repositories, that the name is free on those hosts, and whether SSH to Gitea works.
5. Optional: if the Maintainer chose GitHub, the system creates the empty GitHub repository.
6. The system creates the Gitea repository. If the Maintainer chose GitHub, the repository is created with the AGPL license file and so is not empty; otherwise it is empty and has no license.
7. Optional: if GitHub was chosen, the system configures the Gitea repository as a push mirror to GitHub and verifies it. A license file in the Gitea repository is pushed to GitHub by the mirror.
8. The system creates the local project with the `origin` remote and, if GitHub was chosen, the `github` remote.
9. The system adds the framework submodule, installs its skills and hooks (and the plan gate if chosen) and copies the templates.
10. The system reports a summary of what was created.

### Extensions (Alternative / Exception Flows)

- 2a. A required tool is missing, or a configuration value is missing or malformed:
  1. The system stops before any change and names the problem without showing a credential.
- 3a. A project detail is set in `config.env`:
  1. The system uses it and does not ask for it; the summary says it came from the configuration.
- 3b. A configured project detail is invalid:
  1. The system stops before any request and names the key; it does not ask for the value instead.
- 4a. A token is invalid, an owner does not accept the repository, or the name is taken:
  1. The system stops before creating anything and says which check failed. The GitHub token is only checked when GitHub was chosen.
- 4c. GitHub was chosen and the Gitea server does not offer the `AGPL-3.0` license:
  1. The system stops before creating anything and names the missing license.
- 4b. SSH to Gitea does not work:
  1. The system uses HTTPS for `origin` and warns that the framework submodule step will fail until SSH is configured.
- 5a, 6a, 7a. A step fails after an earlier one succeeded:
  1. The system stops and reports what exists, what failed and how to continue.
- 8a, 9a. The target directory or a target file already exists:
  1. The system asks the Maintainer before replacing it; on no, it skips that item and reports it.
- 9b. A different git hooks setup is already configured in the project:
  1. The system asks before replacing it.

### Special Requirements / Business Rules

| Step | Rule |
| --- | --- |
| 2, 4 | A token never appears in output, logs, command lines, remote URLs or temporary files left behind |
| 3 | The GitHub owner and the Gitea owner are chosen separately; `GITHUB_USER` is only the authenticating account |
| 3 | A project detail set in `config.env` (the key is present, even if empty where an empty value is allowed) is not asked; only the confirmations stay interactive |
| 3, 5, 7 | GitHub is optional; without it no GitHub repository, mirror or `github` remote is created and the GitHub credentials are not required |
| 6 | Choosing GitHub applies the AGPL license (key `AGPL-3.0`) to the Gitea repository when it is created, so that repository is not empty; without GitHub there is no license and the repository is empty |
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
[02875ae]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/02875aee5f2953473924074eea0056eb31af6b7a
