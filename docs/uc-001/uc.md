# Create a new project

## Metadata
| Key | Value |
| --- | --- |
| ID | UC-001 |
| CrossReference | [US-001], [SA-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [9ae0cba] |

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
  - `git` and `curl` are installed.
  - The Maintainer has a GitHub PAT, a Gitea token and SSH access to Gitea on port 10022.
- **Postconditions (success guarantee):**
  - An empty repository exists on GitHub and on Gitea under the chosen owners.
  - The Gitea repository is a push mirror to GitHub.
  - A local project directory exists with credential-free remotes `origin` (Gitea) and `github`, the `framework` submodule, installed skills and hooks, and the copied templates.
  - The Maintainer has a summary of what was created.

### Main Success Scenario

1. The Maintainer starts the project creation.
2. The system loads and validates the configuration and credentials and checks that the required tools exist.
3. The Maintainer provides the repository name, description, visibility, the GitHub owner, the Gitea owner, the local directory, and whether to enable the plan gate.
4. The system checks that both tokens work, that the owners accept new repositories, that the name is free on both hosts, and whether SSH to Gitea works.
5. The system creates the empty GitHub repository.
6. The system creates the empty Gitea repository.
7. The system configures the Gitea repository as a push mirror to GitHub and verifies it.
8. The system creates the local project with the `origin` and `github` remotes.
9. The system adds the framework submodule, installs its skills and hooks (and the plan gate if chosen) and copies the templates.
10. The system reports a summary of what was created.

### Extensions (Alternative / Exception Flows)

- 2a. A required tool is missing, or a configuration value is missing or malformed:
  1. The system stops before any change and names the problem without showing a credential.
- 4a. A token is invalid, an owner does not accept the repository, or the name is taken:
  1. The system stops before creating anything and says which check failed.
- 4b. SSH to Gitea does not work:
  1. The system uses HTTPS for `origin` and warns that the framework submodule step will fail until SSH is configured.
- 5a, 6a, 7a. A step fails after an earlier one succeeded:
  1. The system stops and reports what exists, what failed and how to continue.
- 8a, 9a. The target directory or a target file already exists:
  1. The system asks the Maintainer before replacing it; on no, it skips that item and reports it.
- 9b. A different `core.hooksPath` is already set:
  1. The system asks before replacing it.

### Special Requirements / Business Rules

| Step | Rule |
| --- | --- |
| 2, 4 | A token never appears in output, logs, command lines, remote URLs or temporary files left behind |
| 3 | The GitHub owner and the Gitea owner are chosen separately; `GITHUB_USER` is only the authenticating account |
| 7 | The mirror direction is Gitea to GitHub |
| 8 | `origin` uses HTTPS derived from `GITEA_URL`, or SSH when the SSH test in step 4 passed |
| 8, 9 | Nothing is overwritten or deleted without consent, and no commit is made |

### Open Issues

- The exact SSH `origin` URL form (port 10022) is settled in MIL-003.

---

[US-001]: ../user-stories.md
[SA-001]: ../stakeholder-analysis.md
[9ae0cba]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/9ae0cba306577833480f692c67c0ec327ff2e24e
