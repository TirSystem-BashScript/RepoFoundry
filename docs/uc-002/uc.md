# Start the script as a global command

## Metadata
| Key | Value |
| --- | --- |
| ID | UC-002 |
| CrossReference | [UCD-001], [US-001], [SA-001], [BC-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | Default configuration files: --config and --env, else ./config.env and ./.env in the working folder, else the checkout's; the files used are named and a file from the working folder is confirmed (step 4, extensions 4b and 4c, rules) | [0ab5006] |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | .env is optional (as in UC-001 extension 2b): only config.env is required; a .env found nowhere means the token is asked | pending |

---

**Format:** Fully Dressed

## Fully Dressed

- **Scope:** RepoFoundry (`create-project.sh`)
- **Level:** user-goal
- **Primary Actor:** Maintainer (S01 or S02; one person holds both roles for now)
- **Stakeholders and Interests:**
  - S01 — the script is started by name from any folder, and the new project lands where S01 stands
  - S02 — starting through a link never reads or writes outside the checkout and the current folder
  - S03 — the README says exactly how to make the command global
- **Preconditions:**
  - The checkout of RepoFoundry exists. `config.env` exists as described in the README in the working folder or in the checkout, or the Maintainer points to it with `--config`. `.env` may exist in the same places, or be named with `--env`; a credential it does not provide is asked, as in [UC-001].
  - A folder that is on the shell's `PATH` exists and the Maintainer may write to it.
- **Postconditions (success guarantee):**
  - A command link exists in a `PATH` folder and leads to the script in the checkout.
  - The Maintainer started the script by that name from a working folder, and use case [UC-001] ran with that working folder as its base: the default directory of the new project is `./<name>` under it.
  - Nothing was written outside the working folder and the new project.

### Main Success Scenario

1. The Maintainer makes the script reachable by name: creates a command link in a `PATH` folder that leads to `src/create-project.sh` in the checkout (the README gives the command).
2. The Maintainer opens a shell in the folder in which the new project is to be created (the working folder).
3. The Maintainer starts the script by the name of the command link.
4. The system follows the command link to the checkout, loads its own files from there, and chooses `config.env` and `.env`, each one separately: the file named by `--config` or `--env`, otherwise the one in the working folder, otherwise the one in the checkout. It names the files it will use before any request to a host.
5. The system runs [UC-001] (`<<include>>`) with the working folder as the base of the default directory of the new project.
6. The system reports a summary that names the full path of the new project.

### Extensions (Alternative / Exception Flows)

- 1a. The `PATH` folder is not writable, or not on `PATH`:
  1. The README names the other choices (a folder the Maintainer owns and adds to `PATH`, or an alias); the system is not involved.
- 3a. The command link is broken (the checkout was moved or removed):
  1. The shell reports that the command cannot run; the README says how to recreate the link.
- 4a. The checkout's own files cannot be found from the link target:
  1. The system stops before any change and names the folder it looked in.
- 4b. `config.env` is not named, and is in neither the working folder nor the checkout:
  1. The system stops before any change, names both places it looked in and says that `--config` can point elsewhere.
- 4d. `.env` is not named, and is in neither the working folder nor the checkout:
  1. The system names that no credentials file was found and goes on; a credential that is needed is asked without showing what is typed, as in extension 2b of [UC-001].
- 4c. A chosen file comes from the working folder:
  1. The system names the file and the Gitea address it holds and asks the Maintainer to confirm, default no, before any request to a host; on no, the system stops before any request and any change.

### Special Requirements / Business Rules

| Step | Rule |
| --- | --- |
| 1 | The command link is made by the Maintainer with the shell, not by the script; the script never edits `PATH`, a shell profile or a system folder |
| 4 | The system finds its own files by following the command link, however many links lie on the way, on every supported platform |
| 4 | `config.env` and `.env` are chosen one by one in this order: `--config` / `--env`; `./config.env` / `./.env` in the working folder; the checkout's. A project may therefore use its own `.env` with the checkout's `config.env` |
| 4 | A folder can hold a `config.env` that points the Gitea address elsewhere, and so send the token there. A file from the working folder is therefore confirmed before the first request, and every file used is named in the output |
| 5 | The base of the default directory is the working folder, never the checkout |
| 3 to 6 | Behaviour, prompts and summary are the same as when the script is started by its path from the checkout |

### Open Issues

- The README example is tested on Linux, macOS and Git Bash on Windows (MIL-007 criterion 6).

---

[UCD-001]: ../use-case-diagram.md
[US-001]: ../user-stories.md
[SA-001]: ../stakeholder-analysis.md
[BC-001]: ../business-case.md
[0ab5006]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/0ab50068bf9e5be82a801af9dbe5b763eeaf7f31
